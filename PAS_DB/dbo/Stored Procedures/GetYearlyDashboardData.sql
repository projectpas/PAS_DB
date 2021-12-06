﻿/*************************************************************
EXEC [dbo].[GetYearlyDashboardData] 1, 1, 2
**************************************************************/ 
CREATE PROCEDURE [dbo].[GetYearlyDashboardData]
	@MasterCompanyId BIGINT = NULL,
	@ChartType INT = NULL,
	@EmployeeId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN
			DECLARE @MasterLoopID AS INT;
			DECLARE @Month AS INT;
			DECLARE @Year AS INT;

			SET @Month = CASE WHEN MONTH(GETDATE()) = 12 THEN 1 ELSE (MONTH(GETDATE()) + 1) END;
			SET @Year = CASE WHEN MONTH(GETDATE()) = 12 THEN YEAR(GETDATE()) ELSE YEAR(GETDATE()) - 1 END;
			
			DECLARE @SelectedDate DateTime;

			SET @SelectedDate = DATEFROMPARTS(@Year, @Month, 1)

			DECLARE @BacklogStartDt AS DateTime;

			SELECT TOP 1 @BacklogStartDt = BacklogStartDate FROM [dbo].[DashboardSettings] WITH (NOLOCK) 
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

			IF OBJECT_ID(N'tempdb..#tmpMonthlyData') IS NOT NULL
			BEGIN
				DROP TABLE #tmpMonthlyData
			END

			CREATE TABLE #tmpMonthlyData (
				ID bigint NOT NULL IDENTITY,
				DateProcess DateTime NULL,
				ResultData DECIMAL(18, 2) NULL
			)

			SELECT @MasterLoopID = 1;

			WHILE (@MasterLoopID <= 12)
			BEGIN
				SET @Month = MONTH(CONVERT(DATE, @SelectedDate));
				PRINT (@Month)
				SET @Year = YEAR(CONVERT(DATE, @SelectedDate));
				PRINT (@Year)

				IF (@ChartType = 1)
				BEGIN
					DECLARE @Cnts INT = 0;

					;WITH cte(Total, Mnth) AS (
						SELECT SUM(Quantity), @Month FROM DBO.ReceivingCustomerWork RC WITH (NOLOCK)
						INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = RC.ManagementStructureId
						WHERE MONTH(CONVERT(DATE, ReceivedDate)) = @Month AND YEAR(CONVERT(DATE, ReceivedDate)) = @Year
						AND EMS.EmployeeId = @EmployeeId
						AND RC.MasterCompanyId = @MasterCompanyId
					)

					SELECT @Cnts = SUM(Total) FROM cte GROUP BY Mnth

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@Cnts, 0)
				END
				ELSE IF (@ChartType = 2)
				BEGIN
					DECLARE @Amt DECIMAL(18, 2) = 0;

					;WITH cte(Total, Mnth) AS (
						SELECT SUM(WOBI.GrandTotal), @Month Total
						FROM DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) 
						INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = WOBI.ManagementStructureId
						WHERE IsVersionIncrease = 0 
						AND MONTH(CONVERT(DATE, InvoiceDate)) = @Month AND YEAR(CONVERT(DATE, InvoiceDate)) = @Year
						AND EMS.EmployeeId = @EmployeeId
						AND WOBI.MasterCompanyId = @MasterCompanyId
					)

					SELECT @Amt = SUM(Total) FROM cte GROUP BY Mnth

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@Amt, 0)
				END
				ELSE IF (@ChartType = 3)
				BEGIN
					DECLARE @SOAmt DECIMAL(18, 2) = 0;

					;WITH cte(Total, Mnth) AS (
						SELECT SUM(GrandTotal), @Month FROM DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) 
						INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId
						INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = SO.ManagementStructureId
						WHERE 
						MONTH(CONVERT(DATE, InvoiceDate)) = @Month AND YEAR(CONVERT(DATE, InvoiceDate)) = @Year
						AND EMS.EmployeeId = @EmployeeId
						AND SOBI.MasterCompanyId = @MasterCompanyId
					)

					SELECT @SOAmt = SUM(Total) FROM cte GROUP BY Mnth

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@SOAmt, 0)
				END
				
				SELECT @SelectedDate = DATEADD(MONTH, 1, @SelectedDate);

				SET @MasterLoopID = @MasterLoopID + 1;
			END

			SELECT ResultData FROM #tmpMonthlyData
		END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments VARCHAR(150) = 'GetDashboardViewData' 
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