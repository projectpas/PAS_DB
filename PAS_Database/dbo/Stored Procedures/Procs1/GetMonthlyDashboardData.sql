/*********************           
 ** File:   [GetMonthlyDashboardData]           
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
    2    19 Jan 2024   Bhargav Saliya               Utc Date Changes                                             
**********************/
/*************************************************************
EXEC [dbo].[GetMonthlyDashboardData] 1, 1, 2
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetMonthlyDashboardData]
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
			DECLARE @Day AS INT;
			DECLARE @RecevingModuleID AS INT =1
			DECLARE @wopartModuleID AS INT =12
			DECLARE @SalesOrderModuleID AS INT =17

			SET @Month = MONTH(GETDATE());
			SET @Day = DAY(GETDATE());
			
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
				SELECT DATEFROMPARTS(YEAR(GETDATE()), @Month, 1) AS DayNum
					UNION ALL
					SELECT DATEADD(DAY, 1, DayNum)
					FROM MonthDays_CTE
					WHERE DayNum < EOMONTH(DATEFROMPARTS(YEAR(GETDATE()), @Month, 1)) AND DayNum < DATEADD(DAY, -1, GETDATE())
			)
			
			INSERT INTO #tmpDateOfMonth (DateOfMonth) SELECT DayNum FROM MonthDays_CTE ORDER BY DayNum;

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

			SELECT @MasterLoopID = MIN(ID) FROM #tmpDateOfMonth;

			

			WHILE (@MasterLoopID <= @Day)
			BEGIN
				DECLARE @SelectedDate DateTime;
				SELECT @SelectedDate = DateOfMonth FROM #tmpDateOfMonth WHERE ID = @MasterLoopID;

				IF (@ChartType = 1)
				BEGIN
					DECLARE @Cnts INT = 0;
					print 'Bharga'
					print @SelectedDate

					SELECT @Cnts = SUM(Quantity) FROM DBO.ReceivingCustomerWork RC WITH (NOLOCK)
					INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @RecevingModuleID AND MSD.ReferenceID = RC.ReceivingCustomerWorkId
	                INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RC.ManagementStructureId = RMS.EntityStructureId
	                INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
					INNER JOIN dbo.Employee E  WITH (NOLOCK) ON E.EmployeeId = EUR.EmployeeId
					INNER JOIN LegalEntity LE  WITH (NOLOCK) ON LE.LegalEntityId  =  E.LegalEntityId
					INNER JOIN TimeZone TZ  WITH (NOLOCK) ON TZ.TimeZoneId = LE.TimeZoneId
					--WHERE Cast(DBO.ConvertUTCtoLocal(ReceivedDate, TZ.[Description]) as Date) = CONVERT(DATE, @SelectedDate) 
					WHERE Cast(RC.ReceivedDate as Date) = CONVERT(DATE, @SelectedDate) 
					AND RC.MasterCompanyId = @MasterCompanyId
					GROUP BY RC.ReceivedDate

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@Cnts, 0)
				END
				ELSE IF (@ChartType = 2)
				BEGIN
					DECLARE @Amt DECIMAL(18, 2) = 0;

					SELECT @Amt = SUM(GrandTotal)
					FROM DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
					LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId
					INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
					INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = wop.ID
	                INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON WOBI.ManagementStructureId = RMS.EntityStructureId
	                INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
					--INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = WOBI.ManagementStructureId
					INNER JOIN dbo.Employee E  WITH (NOLOCK) ON E.EmployeeId = EUR.EmployeeId
					INNER JOIN LegalEntity LE  WITH (NOLOCK) ON LE.LegalEntityId  =  E.LegalEntityId
					INNER JOIN TimeZone TZ  WITH (NOLOCK) ON TZ.TimeZoneId = LE.TimeZoneId
					WHERE WOBI.IsVersionIncrease = 0 AND Cast(DBO.ConvertUTCtoLocal(InvoiceDate, TZ.[Description]) as Date) = CONVERT(DATE, @SelectedDate) 
					AND WOBI.MasterCompanyId = @MasterCompanyId
					GROUP BY CAST(InvoiceDate AS DATE)

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@Amt, 0)
				END
				ELSE IF (@ChartType = 3)
				BEGIN
					DECLARE @SOAmt DECIMAL(18, 2) = 0;
					
					SELECT @SOAmt = SUM(GrandTotal) FROM DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) 
					INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId
					INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SalesOrderModuleID AND MSD.ReferenceID = SO.SalesOrderId
	                INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
	                INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
					INNER JOIN dbo.Employee E  WITH (NOLOCK) ON E.EmployeeId = EUR.EmployeeId
					INNER JOIN LegalEntity LE  WITH (NOLOCK) ON LE.LegalEntityId  =  E.LegalEntityId
					INNER JOIN TimeZone TZ  WITH (NOLOCK) ON TZ.TimeZoneId = LE.TimeZoneId
					WHERE Cast(DBO.ConvertUTCtoLocal(InvoiceDate, TZ.[Description]) as Date) = CONVERT(DATE, @SelectedDate)
					AND SOBI.MasterCompanyId = @MasterCompanyId
					GROUP BY CAST(InvoiceDate AS DATE)

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@SOAmt, 0)
				END
				
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