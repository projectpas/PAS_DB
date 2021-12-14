/*************************************************************
EXEC [dbo].[GenerateDashboardDataByMS] 5, 5, '10-27-2021'
**************************************************************/ 
CREATE PROCEDURE [dbo].[GenerateDashboardDataByMS] 
	@EmployeeId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@SelectedDate DATETIME = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN
		DECLARE @Qty AS INT;
		DECLARE @WOBillingAmt AS DECIMAL(20, 2);
		DECLARE @PartsSaleBillingAmt AS DECIMAL(20, 2);
		DECLARE @MROWorkable AS INT;
		DECLARE @PartsSaleWorkable AS DECIMAL(20, 2);
		DECLARE @WOQProcessed AS INT;
		DECLARE @SQProcessed AS INT;
		DECLARE @SOQProcessed AS DECIMAL(20, 2);
		DECLARE @BacklogStartDt AS DateTime;
			
		SELECT TOP 1 @BacklogStartDt = BacklogStartDate FROM [dbo].[DashboardSettings] WITH (NOLOCK) 
		WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0

		SELECT @Qty = SUM(Quantity) FROM DBO.ReceivingCustomerWork RC WITH (NOLOCK)
		INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = RC.ManagementStructureId
		WHERE CONVERT(DATE, ReceivedDate) = CONVERT(DATE, @SelectedDate) 
		AND EMS.EmployeeId = @EmployeeId
		AND RC.MasterCompanyId = @MasterCompanyId
		GROUP BY ReceivedDate

		SELECT @WOBillingAmt = SUM(GrandTotal) FROM DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) 
		INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = WOBI.ManagementStructureId
		WHERE IsVersionIncrease = 0 AND CONVERT(DATE, InvoiceDate) = CONVERT(DATE, @SelectedDate) 
		AND EMS.EmployeeId = @EmployeeId
		AND WOBI.MasterCompanyId = @MasterCompanyId
		GROUP BY CAST(InvoiceDate AS DATE)

		SELECT @PartsSaleBillingAmt = SUM(GrandTotal) FROM DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) 
		INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId
		INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = SO.ManagementStructureId
		WHERE CONVERT(DATE, InvoiceDate) = CONVERT(DATE, @SelectedDate)
		AND EMS.EmployeeId = @EmployeeId
		AND SOBI.MasterCompanyId = @MasterCompanyId
		GROUP BY CAST(InvoiceDate AS DATE)

		SELECT @MROWorkable = SUM(Quantity) FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK) 
		INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = WOP.ManagementStructureId
		WHERE WorkOrderStageId IN (SELECT BacklogMROStage FROM [dbo].[DashboardSettings] WITH (NOLOCK) 
		WHERE MasterCompanyId = @MasterCompanyId
		AND EMS.EmployeeId = @EmployeeId
		AND IsActive = 1 AND IsDeleted = 0)
		AND WOP.IsClosed = 0 AND
		CONVERT(DATE, WOP.CreatedDate) >= CONVERT(DATE, @BacklogStartDt) AND WOP.MasterCompanyId = @MasterCompanyId

		SELECT @PartsSaleWorkable = SUM(SOM.NetSales) FROM DBO.SalesOrderPart SOM WITH (NOLOCK) 
		INNER JOIN DBO.SalesOrder SO ON SO.SalesOrderId = SOM.SalesOrderId
		INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = SO.ManagementStructureId
		WHERE SO.StatusId NOT IN (SELECT Id FROM DBO.MasterSalesOrderStatus WITH (NOLOCK) WHERE [Name] = 'Closed')
		AND SOM.SalesOrderPartId NOT IN (SELECT SalesOrderPartId FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
		INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId 
		Where SOS.SalesOrderId = SO.SalesOrderId)
		AND EMS.EmployeeId = @EmployeeId
		AND CONVERT(DATE, SO.CreatedDate) >= CONVERT(DATE, @BacklogStartDt) AND SO.MasterCompanyId = @MasterCompanyId

		SELECT @WOQProcessed = COUNT(WOQD.WorkOrderQuoteId) FROM DBO.WorkOrderQuote WOQ WITH (NOLOCK) 
		INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
		INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) on WOQD.WorkflowWorkOrderId = WOWF.WorkFlowWorkOrderId
		INNER JOIN DBO.WorkOrderPartNumber WOP WITH (NOLOCK) on WOP.ID = WOWF.WorkOrderPartNoId
		INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = WOP.ManagementStructureId
		WHERE WOQ.SentDate IS NOT NULL
		AND EMS.EmployeeId = @EmployeeId
		AND CONVERT(DATE, WOQ.OpenDate) = CONVERT(DATE, @SelectedDate) 
		AND WOQ.MasterCompanyId = @MasterCompanyId

		SELECT @SQProcessed = SUM(SQP.QuantityRequested) FROM DBO.SpeedQuote SQ WITH (NOLOCK) 
		INNER JOIN DBO.SpeedQuotePart SQP WITH (NOLOCK) ON SQ.SpeedQuoteId = SQP.SpeedQuoteId
		INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = SQ.ManagementStructureId
		WHERE SQ.StatusId IN (SELECT Id FROM MasterSpeedQuoteStatus Where [Name] = 'Open' AND IsActive = 1 AND IsDeleted = 0)
		AND EMS.EmployeeId = @EmployeeId
		AND CONVERT(DATE, SQ.OpenDate) = CONVERT(DATE, @SelectedDate) AND SQ.MasterCompanyId = @MasterCompanyId

		SELECT @SOQProcessed = SUM(SOQM.NetSales) FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) 
		INNER JOIN DBO.SOQuoteMarginSummary SOQM WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQM.SalesOrderQuoteId
		INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQA.SalesOrderQuoteId
		INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = SOQ.ManagementStructureId
		WHERE SOQA.CustomerApprovedDate IS NOT NULL
		AND EMS.EmployeeId = @EmployeeId
		AND CONVERT(DATE, SOQ.OpenDate) = CONVERT(DATE, @SelectedDate) AND SOQ.MasterCompanyId = @MasterCompanyId

		SELECT ISNULL(@Qty, 0) AS 'MROInputCount', ISNULL(@WOBillingAmt, 0) AS 'MROBillingAmount', ISNULL(@PartsSaleBillingAmt, 0) AS 'PartsSaleBillingAmount', 
		ISNULL(@MROWorkable, 0) AS 'MROWorkableBacklog', ISNULL(@PartsSaleWorkable, 0) AS 'PartsSaleWorkableBacklog', ISNULL(@WOQProcessed, 0) AS 'WOQProcessed', 
		ISNULL(@SQProcessed, 0) AS 'SQProcessed', ISNULL(@SOQProcessed, 0) 'SOQProcessed'
	END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GenerateDashboardDataByMS' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH    
END