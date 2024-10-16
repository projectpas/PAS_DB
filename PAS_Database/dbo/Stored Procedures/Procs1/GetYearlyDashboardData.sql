﻿/*********************           
 ** File:   [GetYearlyDashboardData]           
 ** Author:   JEVIK RAIYANI
 ** Description: This stored procedure is used get chart data in dashboard
 ** Purpose:         
 ** Date:   22 Nov 2023      
          
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------		     ----------------------------       
    1    22 Nov 2023   JEVIK RAIYANI               Use dbo.ConvertUTCtoLocal before comparing dates      
	2	 31 JAN 2024    Devendra Shekh			   added isperforma Flage for WO 
	3	 01 FEB 2024	AMIT GHEDIYA	           added isperforma Flage for SO
	4    27 Sept 2024  Abhishek Jirawla				Added @StartDate parameter to SP instead of GETUTCDATE
**********************/
/*************************************************************
EXEC [dbo].[GetYearlyDashboardData] 1, 1, 2, '08/31/2024'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetYearlyDashboardData]
	@MasterCompanyId BIGINT = NULL,
	@ChartType INT = NULL,
	@EmployeeId BIGINT = NULL,
	@StartDate DATETIME2 = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN
			DECLARE @MasterLoopID AS INT;
			DECLARE @Month AS INT;
			DECLARE @Year AS INT;
			DECLARE @RecevingModuleID AS INT =1
			DECLARE @wopartModuleID AS INT =12
			DECLARE @SalesOrderModuleID AS INT =17

			IF @StartDate IS NULL
			BEGIN
				SET @StartDate = GETUTCDATE()
			END

			SET @Month = CASE WHEN MONTH(@StartDate) = 12 THEN 1 ELSE (MONTH(@StartDate) + 1) END;
			SET @Year = CASE WHEN MONTH(@StartDate) = 12 THEN YEAR(@StartDate) ELSE YEAR(@StartDate) - 1 END;
			
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
						INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @RecevingModuleID AND MSD.ReferenceID = RC.ReceivingCustomerWorkId
	                    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RC.ManagementStructureId = RMS.EntityStructureId
	                    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
						INNER JOIN dbo.Employee E  WITH (NOLOCK) ON E.EmployeeId = EUR.EmployeeId
						INNER JOIN LegalEntity LE  WITH (NOLOCK) ON LE.LegalEntityId  =  E.LegalEntityId
						INNER JOIN TimeZone TZ  WITH (NOLOCK) ON TZ.TimeZoneId = LE.TimeZoneId
						WHERE MONTH(Cast(DBO.ConvertUTCtoLocal(ReceivedDate, TZ.[Description]) as Date)) = @Month AND YEAR(Cast(DBO.ConvertUTCtoLocal(ReceivedDate, TZ.[Description]) as Date)) = @Year
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
						LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId
						INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
						INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = wop.ID
						INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON WOBI.ManagementStructureId = RMS.EntityStructureId
						INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
						INNER JOIN dbo.Employee E  WITH (NOLOCK) ON E.EmployeeId = EUR.EmployeeId
						INNER JOIN LegalEntity LE  WITH (NOLOCK) ON LE.LegalEntityId  =  E.LegalEntityId
						INNER JOIN TimeZone TZ  WITH (NOLOCK) ON TZ.TimeZoneId = LE.TimeZoneId
						WHERE WOBI.IsVersionIncrease = 0 
						AND MONTH(Cast(DBO.ConvertUTCtoLocal(InvoiceDate, TZ.[Description]) as Date)) = @Month AND YEAR(Cast(DBO.ConvertUTCtoLocal(InvoiceDate, TZ.[Description]) as Date)) = @Year
						AND WOBI.MasterCompanyId = @MasterCompanyId
						AND ISNULL(wobii.IsPerformaInvoice, 0) = 0
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
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SalesOrderModuleID AND MSD.ReferenceID = SO.SalesOrderId
	                    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
	                    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
						INNER JOIN dbo.Employee E  WITH (NOLOCK) ON E.EmployeeId = EUR.EmployeeId
						INNER JOIN LegalEntity LE  WITH (NOLOCK) ON LE.LegalEntityId  =  E.LegalEntityId
						INNER JOIN TimeZone TZ  WITH (NOLOCK) ON TZ.TimeZoneId = LE.TimeZoneId
						WHERE 
						MONTH(Cast(DBO.ConvertUTCtoLocal(InvoiceDate, TZ.[Description]) as Date)) = @Month AND YEAR(Cast(DBO.ConvertUTCtoLocal(InvoiceDate, TZ.[Description]) as Date)) = @Year
						AND SOBI.MasterCompanyId = @MasterCompanyId AND ISNULL(SOBI.IsProforma,0) = 0
					)

					SELECT @SOAmt = SUM(Total) FROM cte GROUP BY Mnth

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@SOAmt, 0)
				END
				
				SELECT @SelectedDate = DATEADD(MONTH, 1, @SelectedDate);

				SET @MasterLoopID = @MasterLoopID + 1;
			END

			SELECT ResultData FROM #tmpMonthlyData;
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