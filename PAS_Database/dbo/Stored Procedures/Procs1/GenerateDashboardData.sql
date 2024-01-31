/*********************           
 ** File:   [GenerateDashboardData]        
 ** Author:   JEVIK RAIYANI
 ** Description: This stored procedure is used to generateDashboardData
 ** Purpose:         
 ** Date:   22-11-2023      
          
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------		     ----------------------------   
    1             
	2  01/31/2024		Devendra Shekh			added isperforma Flage for WO
**********************/
/*************************************************************
EXEC [dbo].[GenerateDashboardData] 10, 2021
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GenerateDashboardData] 
	@Month INT = NULL,
	@Year INT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN
			DECLARE @MasterCompanyLoopID AS INT;
			DECLARE @MasterLoopID AS INT;
			DECLARE @Qty AS INT;
			DECLARE @WOBillingAmt AS DECIMAL(20, 2);
			DECLARE @PartsSaleBillingAmt AS DECIMAL(20, 2);
			DECLARE @MROWorkable AS INT;
			DECLARE @PartsSaleWorkable AS DECIMAL(20, 2);
			DECLARE @WOQProcessed AS INT;
			DECLARE @SQProcessed AS INT;
			DECLARE @SOQProcessed AS DECIMAL(20, 2);
			DECLARE @BacklogStartDt AS DateTime;

			SELECT @MasterCompanyLoopID = MIN(MasterCompanyId) FROM DBO.MasterCompany WITH (NOLOCK) WHERE IsActive = 1
			
			WHILE (@MasterCompanyLoopID IS NOT NULL)
			BEGIN
				IF OBJECT_ID(N'tempdb..#tmpDateOfMonth') IS NOT NULL
				BEGIN
					DROP TABLE #tmpDateOfMonth
				END

				CREATE TABLE #tmpDateOfMonth (
					ID bigint NOT NULL IDENTITY,
					DateOfMonth DateTime NULL
				)

				;WITH MonthDays_CTE(DayNum) AS
				(
					SELECT DATEFROMPARTS(@Year, @Month, 1) AS DayNum
						UNION ALL
						SELECT DATEADD(DAY, 1, DayNum)
						FROM MonthDays_CTE
						WHERE DayNum < EOMONTH(DATEFROMPARTS(@Year, @Month, 1)) AND DayNum < DATEADD(DAY, -1, GETDATE())
				)
			
				INSERT INTO #tmpDateOfMonth (DateOfMonth) SELECT DayNum FROM MonthDays_CTE ORDER BY DayNum DESC
        
				SELECT @BacklogStartDt = BacklogStartDate FROM [dbo].[DashboardSettings] WITH (NOLOCK) 
				WHERE MasterCompanyId = @MasterCompanyLoopID AND IsActive = 1 AND IsDeleted = 0

				SELECT @MasterLoopID = MAX(ID) FROM #tmpDateOfMonth

				WHILE (@MasterLoopID > 0)
				BEGIN
					DECLARE @SelectedDate DateTime;

					SELECT @SelectedDate = DateOfMonth FROM #tmpDateOfMonth WHERE ID = @MasterLoopID;

					IF NOT EXISTS(SELECT 1 FROM [dbo].[DashboardData] WITH (NOLOCK) WHERE CONVERT(DATE, ExecutionDate) = CONVERT(DATE, @SelectedDate) AND MasterCompanyId = @MasterCompanyLoopID)
					BEGIN
						SET @Qty = 0; SET @WOBillingAmt = 0; SET @PartsSaleBillingAmt = 0; SET @WOQProcessed = 0; SET @SQProcessed = 0; SET @SOQProcessed = 0;

						INSERT INTO [dbo].[DashboardData] (MROInputCount, MROBillingAmount, PartsSaleBillingAmount, ExecutionDate, MasterCompanyId)
						VALUES
						(0, 0, 0, @SelectedDate, @MasterCompanyLoopID)

						SELECT @Qty = SUM(Quantity) FROM DBO.ReceivingCustomerWork WITH (NOLOCK)
						WHERE CONVERT(DATE, ReceivedDate) = CONVERT(DATE, @SelectedDate) AND MasterCompanyId = @MasterCompanyLoopID
						GROUP BY ReceivedDate

						--SELECT SUM(ISNULL(Quantity, 0)), ReceivedDate, @MasterCompanyLoopID 
						--FROM DBO.ReceivingCustomerWork WITH (NOLOCK)
						--WHERE CONVERT(DATE, ReceivedDate) = CONVERT(DATE, @SelectedDate) AND MasterCompanyId = @MasterCompanyLoopID
						--GROUP BY ReceivedDate

						SELECT @WOBillingAmt = SUM(GrandTotal) FROM DBO.WorkOrderBillingInvoicing 
						WHERE IsVersionIncrease = 0 AND CONVERT(DATE, InvoiceDate) = CONVERT(DATE, @SelectedDate) AND MasterCompanyId = @MasterCompanyLoopID AND ISNULL(IsPerformaInvoice, 0) = 0
						GROUP BY CAST(InvoiceDate AS DATE)

						SELECT @PartsSaleBillingAmt = SUM(GrandTotal) FROM DBO.SalesOrderBillingInvoicing
						WHERE CONVERT(DATE, InvoiceDate) = CONVERT(DATE, @SelectedDate) AND MasterCompanyId = @MasterCompanyLoopID
						GROUP BY CAST(InvoiceDate AS DATE)

						SELECT @MROWorkable = SUM(Quantity) FROM DBO.WorkOrderPartNumber
						WHERE WorkOrderStageId IN (SELECT BacklogMROStage FROM [dbo].[DashboardSettings] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyLoopID
						AND IsActive = 1 AND IsDeleted = 0) AND
						CONVERT(DATE, CreatedDate) >= CONVERT(DATE, @BacklogStartDt) AND MasterCompanyId = @MasterCompanyLoopID

						SELECT @PartsSaleWorkable = SUM(SOM.NetSales) FROM DBO.SOMarginSummary SOM INNER JOIN DBO.SalesOrder SO ON SO.SalesOrderId = SOM.SalesOrderId
						WHERE SO.StatusId NOT IN (SELECT Id FROM DBO.MasterSalesOrderStatus WITH (NOLOCK) WHERE [Name] = 'Closed')
						AND CONVERT(DATE, CreatedDate) >= CONVERT(DATE, @BacklogStartDt) AND MasterCompanyId = @MasterCompanyLoopID

						SELECT @WOQProcessed = COUNT(WOQD.WorkOrderQuoteId) FROM DBO.WorkOrderQuote WOQ WITH (NOLOCK) 
						INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
						WHERE WOQ.SentDate IS NOT NULL
						AND CONVERT(DATE, WOQ.OpenDate) = CONVERT(DATE, @SelectedDate) AND WOQ.MasterCompanyId = @MasterCompanyLoopID

						SELECT @SQProcessed = SUM(SQP.QuantityRequested) FROM DBO.SpeedQuote SQ WITH (NOLOCK) INNER JOIN
						DBO.SpeedQuotePart SQP WITH (NOLOCK) ON SQ.SpeedQuoteId = SQP.SpeedQuoteId
						WHERE SQ.StatusId IN (SELECT Id FROM MasterSpeedQuoteStatus Where 
						[Name] = 'Open' AND IsActive = 1 AND IsDeleted = 0)
						AND CONVERT(DATE, SQ.OpenDate) = CONVERT(DATE, @SelectedDate) AND SQ.MasterCompanyId = @MasterCompanyLoopID

						SELECT @SOQProcessed = SUM(SOQM.NetSales) FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) 
						INNER JOIN DBO.SOQuoteMarginSummary SOQM WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQM.SalesOrderQuoteId
						INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQA.SalesOrderQuoteId
						WHERE SOQA.CustomerApprovedDate IS NOT NULL
						AND CONVERT(DATE, SOQ.OpenDate) = CONVERT(DATE, @SelectedDate) AND SOQ.MasterCompanyId = @MasterCompanyLoopID

						UPDATE [dbo].[DashboardData] 
						SET MROInputCount = ISNULL(@Qty, 0), 
						MROBillingAmount = ISNULL(@WOBillingAmt, 0), 
						PartsSaleBillingAmount = ISNULL(@PartsSaleBillingAmt, 0),
						MROWorkableBacklog = ISNULL(@MROWorkable, 0),
						PartsSaleWorkableBacklog = ISNULL(@PartsSaleWorkable, 0),
						WOQProcessed = ISNULL(@WOQProcessed, 0),
						SQProcessed = ISNULL(@SQProcessed, 0),
						SOQProcessed = ISNULL(@SOQProcessed, 0)
						WHERE CONVERT(DATE, ExecutionDate) = CONVERT(DATE, @SelectedDate) AND MasterCompanyId = @MasterCompanyLoopID
					END
					ELSE
					BEGIN
						SET @Qty = 0; SET @WOBillingAmt = 0; SET @PartsSaleBillingAmt = 0; SET @WOQProcessed = 0; SET @SQProcessed = 0; SET @SOQProcessed = 0;
						
						SELECT @Qty = SUM(Quantity) FROM DBO.ReceivingCustomerWork WITH (NOLOCK)
						WHERE CONVERT(DATE, ReceivedDate) = CONVERT(DATE, @SelectedDate) AND MasterCompanyId = @MasterCompanyLoopID
						GROUP BY ReceivedDate

						SELECT @WOBillingAmt = SUM(GrandTotal) FROM DBO.WorkOrderBillingInvoicing 
						WHERE IsVersionIncrease = 0 AND CONVERT(DATE, InvoiceDate) = CONVERT(DATE, @SelectedDate) AND MasterCompanyId = @MasterCompanyLoopID AND ISNULL(IsPerformaInvoice, 0) = 0
						GROUP BY CAST(InvoiceDate AS DATE)

						SELECT @PartsSaleBillingAmt = SUM(GrandTotal) FROM DBO.SalesOrderBillingInvoicing
						WHERE CONVERT(DATE, InvoiceDate) = CONVERT(DATE, @SelectedDate) AND MasterCompanyId = @MasterCompanyLoopID
						GROUP BY CAST(InvoiceDate AS DATE)

						SELECT @MROWorkable = SUM(Quantity) FROM DBO.WorkOrderPartNumber
						WHERE WorkOrderStageId IN (SELECT BacklogMROStage FROM [dbo].[DashboardSettings] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyLoopID
						AND IsActive = 1 AND IsDeleted = 0) AND
						CONVERT(DATE, CreatedDate) >= CONVERT(DATE, @BacklogStartDt) AND MasterCompanyId = @MasterCompanyLoopID

						SELECT @PartsSaleWorkable = SUM(SOM.NetSales) FROM DBO.SOMarginSummary SOM INNER JOIN DBO.SalesOrder SO ON SO.SalesOrderId = SOM.SalesOrderId
						WHERE SO.StatusId NOT IN (SELECT Id FROM DBO.MasterSalesOrderStatus WITH (NOLOCK) WHERE [Name] = 'Closed')
						AND CONVERT(DATE, CreatedDate) >= CONVERT(DATE, @BacklogStartDt) AND MasterCompanyId = @MasterCompanyLoopID

						SELECT @WOQProcessed = COUNT(WOQD.WorkOrderQuoteId) FROM DBO.WorkOrderQuote WOQ WITH (NOLOCK) 
						INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
						WHERE WOQ.SentDate IS NOT NULL
						AND CONVERT(DATE, WOQ.OpenDate) = CONVERT(DATE, @SelectedDate) AND WOQ.MasterCompanyId = @MasterCompanyLoopID

						SELECT @SQProcessed = SUM(SQP.QuantityRequested) FROM DBO.SpeedQuote SQ WITH (NOLOCK) INNER JOIN
						DBO.SpeedQuotePart SQP WITH (NOLOCK) ON SQ.SpeedQuoteId = SQP.SpeedQuoteId
						WHERE SQ.StatusId IN (SELECT Id FROM MasterSpeedQuoteStatus Where 
						[Name] = 'Open' AND IsActive = 1 AND IsDeleted = 0)
						AND CONVERT(DATE, SQ.OpenDate) = CONVERT(DATE, @SelectedDate) AND SQ.MasterCompanyId = @MasterCompanyLoopID

						SELECT @SOQProcessed = SUM(SOQM.NetSales) FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) 
						INNER JOIN DBO.SOQuoteMarginSummary SOQM WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQM.SalesOrderQuoteId
						INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQA.SalesOrderQuoteId
						WHERE SOQA.CustomerApprovedDate IS NOT NULL
						AND CONVERT(DATE, SOQ.OpenDate) = CONVERT(DATE, @SelectedDate) AND SOQ.MasterCompanyId = @MasterCompanyLoopID

						UPDATE [dbo].[DashboardData] 
						SET MROInputCount = ISNULL(@Qty, 0), 
						MROBillingAmount = ISNULL(@WOBillingAmt, 0), 
						PartsSaleBillingAmount = ISNULL(@PartsSaleBillingAmt, 0),
						MROWorkableBacklog = ISNULL(@MROWorkable, 0),
						PartsSaleWorkableBacklog = ISNULL(@PartsSaleWorkable, 0),
						WOQProcessed = ISNULL(@WOQProcessed, 0),
						SQProcessed = ISNULL(@SQProcessed, 0),
						SOQProcessed = ISNULL(@SOQProcessed, 0)
						WHERE CONVERT(DATE, ExecutionDate) = CONVERT(DATE, @SelectedDate) AND MasterCompanyId = @MasterCompanyLoopID
					END

					SET @MasterLoopID = @MasterLoopID - 1;
				END

				SELECT @MasterCompanyLoopID = MIN(MasterCompanyId) FROM DBO.MasterCompany WITH (NOLOCK) WHERE IsActive = 1 AND MasterCompanyId > @MasterCompanyLoopID
			END
		END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GenerateDashboardData' 
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