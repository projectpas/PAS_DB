/*********************           
 ** File:   [GetMonthlyDashboardData]           
 ** Author:   HEMANT SALIYA
 ** Description: This stored procedure is used get chart data in dashboard
 ** Purpose:         
 ** Date:   22 Nov 2023      
          
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------		     ----------------------------       
    1    22 Nov 2023	HEMANT SALIYA				Use dbo.ConvertUTCtoLocal before comparing dates                                             
    2    19 Jan 2024	Bhargav Saliya				Utc Date Changes                  
	3	 31 jan 2024	Devendra Shekh				added isperforma Flage for WO
	4	 01 jan 2024	AMIT GHEDIYA				added isperforma Flage for SO
	5    14 March 2024	Bhargav Saliya				Resolved Count Issue in Dashboard Graph 
	6    19 March 2024	Bhargav Saliya				Resolved Count Issue in Dashboard Graph 
	7    27 Sept 2024	Abhishek Jirawla			Added @StartDate parameter to SP instead of GETUTCDATE
	8	 30 Oct 2024	HEMANT SALIYA				Verify the count
	9	 18 Mar 2025	RAJESH GAMI					Optimise the timezone related JOIN and code due to timeout
	10	 06 MAY 2025	HEMANT SALIYA				Handle Flat rate case for Multiple MPN WO
	11	 26-June-2025	Devendra Shekh				Billing Table Changes
	12	 30-June-2025	Devendra Shekh				SO Billing Table Changes
	13	 03 NOV 2025	HEMANT SALIYA				Corrected Dashbord Reports Issue for Multiple MPN
	14	 02 JUNE 2026	RAJESH GAMI					Fixed : Amount related issues for the SO
**********************/
/*************************************************************
EXEC [dbo].[GetMonthlyDashboardData] 11, 2, 98, '12-03-2025 00:00:00'
EXEC [dbo].[GetMonthlyDashboardData] 11, 2, 98, '03-12-2025 00:00:00'
EXEC [dbo].[GetMonthlyDashboardData] 1, 2, 2, '2025-06-24 00:00:00'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetMonthlyDashboardData]
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
			DECLARE @Day AS INT;
			DECLARE @RecevingModuleID AS INT =1
			DECLARE @wopartModuleID AS INT =12
			DECLARE @SalesOrderModuleID AS INT =17
			DECLARE @EmployeeRoleID AS VARCHAR(MAX);

			DECLARE @WOModuleId BIGINT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder');
			DECLARE @SubModuleId BIGINT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN');
			DECLARE @SOModuleId INT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder');

			/* --------------START: Get the timzone and UTC offset -------------- */
			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '', @BaseUtcOffsetSec BIGINT = 0;
			SELECT 	@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description] )
								FROM dbo.Employee E WITH (NOLOCK) 
									LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
									LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
									LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
								WHERE E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee		
				
			SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec  
				FROM dbo.TimeZone WITH(NOLOCK)  
				WHERE [Description] = @CurrntEmpTimeZoneDesc
			/* -------------- END: Get the timzone and UTC offset -------------- */
			SET @EmployeeRoleID = STUFF((SELECT DISTINCT ',' + CAST(RoleId AS VARCHAR(100))
							FROM dbo.EmployeeUserRole WITH (NOLOCK) WHERE EmployeeId = @EmployeeId
							FOR XML PATH('')), 1, 1, '')

			IF @StartDate IS NULL
			BEGIN
				SET @StartDate = GETUTCDATE()
			END

			SET @Month = MONTH(@StartDate);
			SET @Day = DAY(@StartDate);
			
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
				SELECT DATEFROMPARTS(YEAR(@StartDate), @Month, 1) AS DayNum
					UNION ALL
				SELECT DATEADD(DAY, 1, DayNum)
				FROM MonthDays_CTE
				WHERE DayNum < EOMONTH(DATEFROMPARTS(YEAR(@StartDate), @Month, 1)) AND DayNum <= DATEADD(DAY, -1, @StartDate)
			) INSERT INTO #tmpDateOfMonth (DateOfMonth) SELECT DayNum FROM MonthDays_CTE ORDER BY DayNum;

			DECLARE @BacklogStartDt AS DateTime;

			SELECT TOP 1 @BacklogStartDt = BacklogStartDate FROM [dbo].[DashboardSettings] WITH (NOLOCK) 
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

			IF OBJECT_ID(N'tempdb..#tmpRCWorkOrderUserRole') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpRCWorkOrderUserRole
			END

			SELECT * INTO #tmpRCWorkOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
			FROM [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK)
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON RMS.EntityStructureId = MSD.EntityMSID 
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
			WHERE MSD.[ModuleID] = @RecevingModuleID AND EUR.[EmployeeId] = @EmployeeId) AS Result

			IF OBJECT_ID(N'tempdb..#tmpWorkOrderUserRole') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpWorkOrderUserRole
			END	

			SELECT * INTO #tmpWorkOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
			FROM [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK)
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON RMS.EntityStructureId = MSD.EntityMSID 
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
			WHERE MSD.[ModuleID] = @WOPartModuleID AND EUR.[EmployeeId] = @EmployeeId) AS Result

			IF OBJECT_ID(N'tempdb..#tmpSalesOrderUserRole') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpSalesOrderUserRole
			END
		
			SELECT * INTO #tmpSalesOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
			FROM [dbo].SalesOrderManagementStructureDetails MSD WITH (NOLOCK)
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.[EntityMsId] = RMS.[EntityStructureId]
				INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
			WHERE MSD.[ModuleID] = @SalesOrderModuleID AND EUR.[EmployeeId] = @EmployeeId) AS SalesOrderUserRole

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
				DECLARE @SelectedDate DATE;
				
				SELECT @SelectedDate = DateOfMonth FROM #tmpDateOfMonth WHERE ID = @MasterLoopID;

				IF (@ChartType = 1)
				BEGIN
					DECLARE @Cnts INT = 0;

					;WITH tmpReceivingCustomerWork as (
						SELECT DISTINCT RC.ReceivingCustomerWorkId 
						FROM DBO.ReceivingCustomerWork RC WITH (NOLOCK)
							INNER JOIN #tmpRCWorkOrderUserRole TMP ON TMP.ReferenceID = RC.ReceivingCustomerWorkId
							AND RC.MasterCompanyId = @MasterCompanyId
							AND ISNULL(RC.IsDeleted,0) = 0 AND ISNULL(RC.IsActive,0) = 1
					)
					SELECT @Cnts = COUNT(ReceivingCustomerWorkId) FROM tmpReceivingCustomerWork

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CAST(@SelectedDate AS DATE) AS DateProcess, ISNULL(@Cnts, 0)
				END
				ELSE IF (@ChartType = 2)
				BEGIN
					DECLARE @Amt DECIMAL(18, 2) = 0;
					;WITH InvoiceResult AS (
					SELECT ISNULL(SUM(wobii.GrandTotal),0) - (ISNULL(SUM(wobii.SalesTax),0) + ISNULL(SUM(wobii.OtherTax),0)) as GrandTotal


					FROM DBO.BillingInvoicing WOBI WITH (NOLOCK)
						LEFT JOIN DBO.BillingInvoicingItems wobii WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId AND ISNULL(wobii.IsVersionIncrease, 0) = 0 AND ISNULL(wobii.IsPerformaInvoice, 0) = 0 AND wobii.SubModuleId = @SubModuleId
						INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) on wop.ID = wobii.SubReferenceId
						INNER JOIN #tmpWorkOrderUserRole TMP ON TMP.ReferenceID = wop.ID
					WHERE ISNULL(WOBI.IsVersionIncrease, 0) = 0 
						AND CAST(DATEADD(SECOND, @BaseUtcOffsetSec, InvoiceDate) as Date) = CAST(@SelectedDate AS DATE)
						AND WOBI.MasterCompanyId = @MasterCompanyId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0 AND WOBI.ModuleId = @WOModuleId AND ISNULL(wop.IsDeleted,0) = 0 AND ISNULL(wop.IsActive,0) = 1
					)
					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CAST(@SelectedDate AS DATE) AS DateProcess,  ISNULL(GrandTotal, 0) FROM InvoiceResult
				END
				ELSE IF (@ChartType = 3)
				BEGIN
					DECLARE @SOAmt DECIMAL(18, 2) = 0;
					
					;WITH InvoiceResult AS (
						SELECT ISNULL(SUM(SOBI.GrandTotal),0) - (ISNULL(SUM(SOBI.SalesTax),0) + ISNULL(SUM(SOBI.OtherTax),0)) as GrandTotal
						FROM DBO.BillingInvoicing SOBI WITH (NOLOCK) 
						INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.ReferenceId
						INNER JOIN #tmpSalesOrderUserRole MSD WITH (NOLOCK) ON MSD.ReferenceID = SO.SalesOrderId
					WHERE 
					ISNULL(SO.IsDeleted,0) = 0 AND ISNULL(SO.IsActive,0) = 1 AND
						CAST(DATEADD(SECOND, @BaseUtcOffsetSec, InvoiceDate) as Date)  = CAST(@SelectedDate AS DATE)
						AND SOBI.MasterCompanyId = @MasterCompanyId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND ISNULL(SOBI.IsVersionIncrease,0) = 0 AND SOBI.ModuleId = @SOModuleId
					)

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CAST(@SelectedDate AS DATE) AS DateProcess,  ISNULL(GrandTotal, 0) FROM InvoiceResult
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
            , @AdhocComments VARCHAR(150) = 'GetMonthlyDashboardData' 
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