
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
	3	 31 jan 2024   Devendra Shekh				added isperforma Flage for WO
	4	 01 jan 2024   AMIT GHEDIYA					added isperforma Flage for SO
	5    14 March 2024 Bhargav Saliya				Resolved Count Issue in Dashboard Graph 
	6    19 March 2024 Bhargav Saliya				Resolved Count Issue in Dashboard Graph 
	7    27 Sept 2024  Abhishek Jirawla				Added @StartDate parameter to SP instead of GETUTCDATE
**********************/
/*************************************************************
EXEC [dbo].[GetMonthlyDashboardData] 1, 1, 2
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
					WHERE DayNum < EOMONTH(DATEFROMPARTS(YEAR(@StartDate), @Month, 1)) AND DayNum < DATEADD(DAY, -1, @StartDate)
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
					--SELECT @Cnts = SUM(Quantity) 
					;WITH tmpReceivingCustomerWork as (
					SELECT DISTINCT RC.ReceivingCustomerWorkId 
					FROM DBO.ReceivingCustomerWork RC WITH (NOLOCK)
					INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @RecevingModuleID AND MSD.ReferenceID = RC.ReceivingCustomerWorkId
	                INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RC.ManagementStructureId = RMS.EntityStructureId
	                INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
					WHERE Cast(RC.ReceivedDate as Date) = CONVERT(DATE, @SelectedDate) AND EUR.RoleId IN(SELECT item FROM dbo.SplitString(@EmployeeRoleID, ','))
					AND RC.MasterCompanyId = @MasterCompanyId
					)
					SELECT @Cnts = COUNT(ReceivingCustomerWorkId) FROM tmpReceivingCustomerWork

					INSERT INTO #tmpMonthlyData (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@Cnts, 0)
				END
				ELSE IF (@ChartType = 2)
				BEGIN
					DECLARE @Amt DECIMAL(18, 2) = 0;

					SELECT @Amt = SUM(WOBI.GrandTotal)
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
					AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0
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
					AND SOBI.MasterCompanyId = @MasterCompanyId AND ISNULL(SOBI.IsProforma,0) = 0
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