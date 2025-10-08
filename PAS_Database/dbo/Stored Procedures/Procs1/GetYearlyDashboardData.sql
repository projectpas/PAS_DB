/*********************           
 ** File:   [GetYearlyDashboardData]           
 ** Author:   HEMANT SALIYA
 ** Description: This stored procedure is used get chart data in dashboard
 ** Purpose:         
 ** Date:   22 Nov 2023      
          
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------				----------------------------       
    1    22 Nov 2023	HEMANT SALIYA				Use dbo.ConvertUTCtoLocal before comparing dates      
	2	 31 JAN 2024	Devendra Shekh				added isperforma Flage for WO 
	3	 01 FEB 2024	AMIT GHEDIYA				added isperforma Flage for SO
	4    27 Sept 2024	Abhishek Jirawla			Added @StartDate parameter to SP instead of GETUTCDATE
	5	 30 Oct 2024	HEMANT SALIYA				Verify the count 
	6	 18 Mar 2025	RAJESH GAMI					Optimise the timezone related JOIN and code due to timeout
	7	 06 MAY 2025	HEMANT SALIYA				Handle Flat rate case for Multiple MPN WO
	8	 26-June-2025	Devendra Shekh				Billing Table Changes
	9	 30-June-2025	Devendra Shekh				SO Billing Table Changes
**********************/
/*************************************************************
EXEC [dbo].[GetYearlyDashboardData] 1, 2, 2, '2025-06-24 00:00:00'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetYearlyDashboardData]
	@MasterCompanyId BIGINT = NULL,
	@ChartType INT = NULL,
	@EmployeeId BIGINT = NULL,
	@StartDate DATETIME = NULL
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
			
			DECLARE @WOModuleId BIGINT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder');
			DECLARE @SubModuleId BIGINT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN');
			DECLARE @SOModuleId INT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder');

			IF @StartDate IS NULL
			BEGIN
				SET @StartDate = GETUTCDATE()
			END

			SET @Month = CASE WHEN MONTH(@StartDate) = 12 THEN 1 ELSE (MONTH(@StartDate) + 1) END;
			SET @Year = CASE WHEN MONTH(@StartDate) = 12 THEN YEAR(@StartDate) ELSE YEAR(@StartDate) - 1 END;
			
			DECLARE @SelectedDate DATETIME;

			SET @SelectedDate = DATEFROMPARTS(@Year, @Month, 1)

			DECLARE @BacklogStartDt AS DATETIME;

			SELECT TOP 1 @BacklogStartDt = BacklogStartDate FROM [dbo].[DashboardSettings] WITH (NOLOCK) 
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

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

			SELECT @MasterLoopID = 1;

			WHILE (@MasterLoopID <= 12)
			BEGIN
				SET @Month = MONTH(CAST(@SelectedDate AS DATE));
				SET @Year = YEAR(CAST(@SelectedDate AS DATE));

				IF (@ChartType = 1)
				BEGIN
					DECLARE @Cnts INT = 0;

					;WITH cte(Total, Mnth) AS (
						SELECT SUM(Quantity), @Month FROM DBO.ReceivingCustomerWork RC WITH (NOLOCK)
							INNER JOIN #tmpRCWorkOrderUserRole TMP ON TMP.ReferenceID = RC.ReceivingCustomerWorkId
							--INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @RecevingModuleID AND MSD.ReferenceID = RC.ReceivingCustomerWorkId
							--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RC.ManagementStructureId = RMS.EntityStructureId
							--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
						WHERE 
							MONTH(Cast(DATEADD(SECOND, @BaseUtcOffsetSec, ReceivedDate) as Date)) = @Month 
							AND YEAR(Cast(DATEADD(SECOND, @BaseUtcOffsetSec, ReceivedDate) as Date)) = @Year
							AND RC.MasterCompanyId = @MasterCompanyId
					)

					SELECT @Cnts = SUM(Total) FROM cte GROUP BY Mnth

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CAST(@SelectedDate AS DATE) AS DateProcess, ISNULL(@Cnts, 0)
				END
				ELSE IF (@ChartType = 2)
				BEGIN
					DECLARE @Amt DECIMAL(18, 2) = 0;

					;WITH cte(Total, Mnth) AS (
						--SELECT CASE WHEN WOBI.CostPlusType = 'Flat Rate' THEN ISNULL(SUM(wobii.UnitPrice),0) ELSE ISNULL(SUM(wobii.GrandTotal),0) END , @Month Total
						SELECT ISNULL(SUM(WOBI.GrandTotal),0) - (ISNULL(SUM(WOBI.SalesTax),0) + ISNULL(SUM(WOBI.OtherTax),0)) AS GrandTotal, @Month Total
						FROM DBO.BillingInvoicing WOBI WITH (NOLOCK) 
							LEFT JOIN DBO.BillingInvoicingItems wobii WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId AND ISNULL(wobii.IsVersionIncrease, 0) = 0 AND ISNULL(wobii.IsPerformaInvoice, 0) = 0 AND wobii.SubModuleId = @SubModuleId
							INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) on wop.ID = wobii.SubReferenceId
							INNER JOIN #tmpWorkOrderUserRole TMP ON TMP.ReferenceID = wop.ID
							--INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = wop.ID
							--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON WOBI.ManagementStructureId = RMS.EntityStructureId
							--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
						WHERE ISNULL(WOBI.IsVersionIncrease, 0) = 0 
							AND MONTH(Cast(DATEADD(SECOND, @BaseUtcOffsetSec,InvoiceDate) as Date)) = @Month AND YEAR(Cast(DATEADD(SECOND, @BaseUtcOffsetSec, InvoiceDate) as Date)) = @Year
							AND WOBI.MasterCompanyId = @MasterCompanyId
							AND ISNULL(wobii.IsPerformaInvoice, 0) = 0
							AND WOBI.ModuleId = @WOModuleId
						GROUP BY WOBI.CostPlusType
					)

					SELECT @Amt = SUM(Total) FROM cte GROUP BY Mnth

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CAST(@SelectedDate AS DATE) AS DateProcess, ISNULL(@Amt, 0)
				END
				ELSE IF (@ChartType = 3)
				BEGIN
					DECLARE @SOAmt DECIMAL(18, 2) = 0;

					;WITH cte(Total, Mnth) AS (
						SELECT ISNULL(SUM(GrandTotal),0) - (ISNULL(SUM(SalesTax),0) + ISNULL(SUM(OtherTax),0)), @Month FROM DBO.BillingInvoicing SOBI WITH (NOLOCK) 
							INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.ReferenceId
							INNER JOIN #tmpSalesOrderUserRole MSD WITH (NOLOCK) ON MSD.ReferenceID = SO.SalesOrderId
							--INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SalesOrderModuleID AND MSD.ReferenceID = SO.SalesOrderId
							--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
							--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
						WHERE 
						MONTH(Cast(DATEADD(SECOND, @BaseUtcOffsetSec, InvoiceDate) as Date)) = @Month AND YEAR(Cast(DATEADD(SECOND, @BaseUtcOffsetSec, InvoiceDate) as Date)) = @Year
							AND SOBI.MasterCompanyId = @MasterCompanyId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND ISNULL(SOBI.IsVersionIncrease,0) = 0 AND SOBI.ModuleId = @SOModuleId
					)

					SELECT @SOAmt = SUM(Total) FROM cte GROUP BY Mnth

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CAST(@SelectedDate AS DATE) AS DateProcess, ISNULL(@SOAmt, 0)
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