/*********************           
 ** File:   [GenerateDashboardDataByMS]        
 ** Author:   JEVIK RAIYANI
 ** Description: This stored procedure is used Display snapshot count in DashBoard
 ** Purpose:         
 ** Date:   22-11-2023      
          
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date             Author			Change Description            
 ** --   --------         -------			----------------------------   
    1    22 Nov 2023	JEVIK RAIYANI		update SQProcessed variable calculation         
	2	 01/31/2024		Devendra Shekh		added isperforma Flage for WO
	3	 01/02/2024	    AMIT GHEDIYA	    added isperforma Flage for SO
	4    03/07/2024     Bhargav Saliya		Fixed duplicate Record Issue
	6    19 March 2024  Bhargav Saliya		Resolved Count Issue(MRO Inputs) in MRO Dashboard 
	7	 28 March 2024  Bhargav Saliya		Resolve Snapshot: MRO Billing amount issue
	8	 28 June 2024   Vishal Suthar		Added login entry in LogInLog table for employee when they login into the system
**********************/

CREATE   PROCEDURE [dbo].[GenerateDashboardDataByMS] 
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
		DECLARE @RecevingModuleID AS INT =1;
		DECLARE @wopartModuleID AS INT =12
		DECLARE @woqModuleID AS INT =15
		DECLARE @SalesOrderModuleID AS INT =17
		DECLARE @SalesOrderQouteModuleID AS INT =18
		DECLARE @SpeedQouteModuleID AS INT =27
		DECLARE @EmployeeRoleID AS VARCHAR(MAX);

		INSERT INTO [dbo].[LogInLog]
           ([EmployeeId],[LogInTime],[LogOutTime],[IPAddress],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate])
        SELECT EmployeeId,GETDATE(),GETDATE(),'0',MasterCompanyId,FirstName + ' ' +LASTNAME,FirstName + ' ' +LASTNAME,GETDATE(),GETDATE()  from dbo.Employee WHERE [EmployeeId]  = @EmployeeId
     
		
		SET @EmployeeRoleID = STUFF((SELECT DISTINCT ',' + CAST(RoleId AS VARCHAR(100))
							FROM dbo.EmployeeUserRole WITH (NOLOCK) WHERE EmployeeId = @EmployeeId
							FOR XML PATH('')), 1, 1, '')
							
		SELECT DISTINCT RC.ReceivingCustomerWorkId 
		INTO #tmpReceivingCustomerWork
		FROM DBO.ReceivingCustomerWork RC WITH (NOLOCK)
		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @RecevingModuleID AND MSD.ReferenceID = RC.ReceivingCustomerWorkId
	    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RC.ManagementStructureId = RMS.EntityStructureId
	    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		WHERE CONVERT(DATE, ReceivedDate) = CONVERT(DATE, @SelectedDate) AND EUR.RoleId IN(SELECT item FROM dbo.SplitString(@EmployeeRoleID, ','))
		AND RC.MasterCompanyId = @MasterCompanyId

		SELECT @Qty = COUNT(ReceivingCustomerWorkId) FROM #tmpReceivingCustomerWork
		SELECT DISTINCT WOBI.GrandTotal
		INTO #tmpWorkOrderBillingInvoicing
		FROM DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) 
		INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId IN (SELECT item FROM dbo.SplitString(@EmployeeRoleID, ',')) AND EUR.EmployeeId = @EmployeeId
		WHERE WOBI.IsVersionIncrease = 0 AND CONVERT(DATE, InvoiceDate) = CONVERT(DATE, @SelectedDate) 
		AND WOBI.MasterCompanyId = @MasterCompanyId

		Select @WOBillingAmt = SUM(GrandTotal) from #tmpWorkOrderBillingInvoicing	

		SELECT @PartsSaleBillingAmt = SUM(GrandTotal) FROM DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) 
		INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId
		INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SalesOrderModuleID AND MSD.ReferenceID = SO.SalesOrderId
	    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
	    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		WHERE CONVERT(DATE, InvoiceDate) = CONVERT(DATE, @SelectedDate)
		AND SOBI.MasterCompanyId = @MasterCompanyId AND ISNULL(SOBI.IsProforma,0) = 0
		GROUP BY CAST(InvoiceDate AS DATE)

		SELECT @MROWorkable = SUM(Quantity) FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK) 
		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = WOP.ID
		INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON WOP.ManagementStructureId = RMS.EntityStructureId
		INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
		WHERE WorkOrderStageId IN (SELECT BacklogMROStage FROM [dbo].[DashboardSettings] WITH (NOLOCK) 
		WHERE MasterCompanyId = @MasterCompanyId 
		AND IsActive = 1 AND IsDeleted = 0)
		AND WOP.IsClosed = 0 AND
		CONVERT(DATE, WOP.CreatedDate) >= CONVERT(DATE, @BacklogStartDt) AND CONVERT(DATE, WOP.CreatedDate) <= CONVERT(DATE, @SelectedDate) AND WOP.MasterCompanyId = @MasterCompanyId

		SELECT @PartsSaleWorkable = SUM(SOM.NetSales) FROM DBO.SalesOrderPart SOM WITH (NOLOCK) 
		INNER JOIN DBO.SalesOrder SO ON SO.SalesOrderId = SOM.SalesOrderId
		INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SalesOrderModuleID AND MSD.ReferenceID = SO.SalesOrderId
	    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
	    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		WHERE SO.StatusId NOT IN (SELECT Id FROM DBO.MasterSalesOrderStatus WITH (NOLOCK) WHERE [Name] = 'Closed')
		AND SOM.SalesOrderPartId NOT IN (SELECT SalesOrderPartId FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
		INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId 
		Where SOS.SalesOrderId = SO.SalesOrderId)
		AND CONVERT(DATE, SO.CreatedDate) >= CONVERT(DATE, @BacklogStartDt) 
		AND CONVERT(DATE, SO.CreatedDate) <= CONVERT(DATE, @SelectedDate)
		AND SO.MasterCompanyId = @MasterCompanyId

		SELECT @WOQProcessed = COUNT(WOQD.WorkOrderQuoteId) FROM DBO.WorkOrderQuote WOQ WITH (NOLOCK) 
		INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
		INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) on WOQD.WorkflowWorkOrderId = WOWF.WorkFlowWorkOrderId
		INNER JOIN DBO.WorkOrderPartNumber WOP WITH (NOLOCK) on WOP.ID = WOWF.WorkOrderPartNoId
		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = WOP.ID
		INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON WOP.ManagementStructureId = RMS.EntityStructureId
		INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
		WHERE WOQ.SentDate IS NOT NULL
		AND CONVERT(DATE, WOQ.OpenDate) = CONVERT(DATE, @SelectedDate) 
		AND WOQ.MasterCompanyId = @MasterCompanyId

		SELECT @SQProcessed = COUNT(SQ.SpeedQuoteId) FROM DBO.SpeedQuote SQ WITH (NOLOCK) 
		--INNER JOIN DBO.SpeedQuotePart SQP WITH (NOLOCK) ON SQ.SpeedQuoteId = SQP.SpeedQuoteId
		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID =@SpeedQouteModuleID AND MSD.ReferenceID = SQ.SpeedQuoteId
	    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SQ.ManagementStructureId = RMS.EntityStructureId
	    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		WHERE SQ.StatusId IN (SELECT Id FROM MasterSpeedQuoteStatus Where [Name] = 'Open' AND IsActive = 1 AND IsDeleted = 0)
		AND CONVERT(DATE, SQ.OpenDate) = CONVERT(DATE, @SelectedDate) AND SQ.MasterCompanyId = @MasterCompanyId

		SELECT @SOQProcessed = SUM(SOQM.NetSales) FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) 
		INNER JOIN DBO.SOQuoteMarginSummary SOQM WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQM.SalesOrderQuoteId
		INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQA.SalesOrderQuoteId
		INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SalesOrderQouteModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
	    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId
	    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		WHERE SOQA.CustomerApprovedDate IS NOT NULL
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