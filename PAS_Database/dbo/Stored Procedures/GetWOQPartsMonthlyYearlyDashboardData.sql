/*************************************************************           
 ** File:   [GetWOQPartsMonthlyYearlyDashboardData]
 ** Author:   
 ** Description: This stored procedure is used to Get Parts Dashboard details
 ** Purpose:         
 ** Date:    
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description   '2024-07-30'        
 ** --   --------     -------				--------------------------------          
    1    10-04-2024  Shrey Chandegara		Created
EXEC GetWOQPartsMonthlyYearlyDashboardData 1, 2, '2024-10-10',10,1
************************************************************************/
CREATE     PROCEDURE [dbo].[GetWOQPartsMonthlyYearlyDashboardData]
	@MasterCompanyId BIGINT = NULL,
	@EmployeeId BIGINT = NULL,
	@StartDate DATETIME2 = NULL,
	@TopNumberDetails INT = NULL,
	@ManagementStructureId BIGINT = NULL
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY  
		
			BEGIN
				DECLARE @WOQMSModuleID INT = (SELECT ManagementStructureModuleId FROM ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'WorkOrderMPN');
				DECLARE @EmployeeRoleID NVARCHAR(MAX);
				DECLARE @OnTimePerform DECIMAL(9,2)= NULL;
				DECLARE @NOTOnTimePerform DECIMAL(9,2) =NULL;
				DECLARE @OverHualScopeId BIGINT = (SELECT WorkScopeId FROM dbo.[WorkScope] WHERE WorkScopeCode = 'OVERHAUL' AND MasterCompanyId = 1);
				DECLARE @RepairScopeId BIGINT = (SELECT WorkScopeId FROM dbo.[WorkScope] WHERE WorkScopeCode = 'REPAIR' AND MasterCompanyId = 1);
				DECLARE @BenChekScopeId BIGINT = (SELECT WorkScopeId FROM dbo.[WorkScope] WHERE WorkScopeCode = 'BENCHCHECK' AND MasterCompanyId = 1);
				SELECT @EmployeeRoleID = STUFF((
						SELECT DISTINCT ',' + CAST(RoleId AS VARCHAR(100))
						FROM dbo.EmployeeUserRole WITH (NOLOCK)
						WHERE EmployeeId = @EmployeeId
						FOR XML PATH('')
					), 1, 1, '');
				----Top 10 Parts Quoted

				-- START: Top 10 parts by item Group Chart value  (CHART NUM: 1)--

				IF OBJECT_ID(N'tempdb..#tmpTop10PartQuoted') IS NOT NULL
				BEGIN
					DROP TABLE #tmpTop10PartQuoted
				END

				CREATE TABLE #tmpTop10PartQuoted (
					ID bigint NOT NULL IDENTITY,
					PartNumber VARCHAR(100)  NULL,
					TotalSalesCount INT NULL
				)

				;WITH tmpTop10WorkOrderQuotePart as (
					SELECT
						IM.partnumber,
						IM.ItemMasterId,
						COUNT(WP.Quantity) AS TotalSalesCount
					FROM dbo.WorkOrder WO WITH (NOLOCK)
						--INNER JOIN   WITH (NOLOCK) ON WOQD.WorkOrderQuoteId = WOQ.WorkOrderQuoteId
						INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WP.WorkOrderId = WO.WorkOrderId  
						INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON WP.ItemMasterId = IM.ItemMasterId
					WHERE CONVERT(DATE,WO.OpenDate) BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) 
								AND @StartDate 
					AND WP.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted = 0 AND WP.IsDeleted = 0 AND WP.ManagementStructureId = @ManagementStructureId
					GROUP BY 
						IM.partnumber, 
						IM.ItemMasterId
					)
					INSERT INTO #tmpTop10PartQuoted (PartNumber, TotalSalesCount)
					SELECT
						partnumber,         
						TotalSalesCount  -- Number of sales for each part
					FROM tmpTop10WorkOrderQuotePart
					ORDER BY TotalSalesCount DESC
					OFFSET 0 ROWS
					FETCH FIRST @TopNumberDetails ROWS ONLY;

					-- END --


					-- Start : Top 10 Customers Chart value (CHART NUM: 2)--

					IF OBJECT_ID(N'tempdb..#tmpTop10CustomerReceivedPart') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop10CustomerReceivedPart
					END

					CREATE TABLE #tmpTop10CustomerReceivedPart (
						ID bigint NOT NULL IDENTITY,
						Customer VARCHAR(100)  NULL,
						TotalWorkOrderCount INT NULL
					)


					;WITH tmpTop10CustomerReceivedWOPart AS (
					SELECT  
						C.Name, 
						C.CustomerId, 
						COUNT(*) AS CountOfOrders
					FROM dbo.[WorkOrder] WO WITH(NOLOCK)
					INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = WO.CustomerId
					WHERE CONVERT(DATE, WO.CreatedDate) 
						BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) 
						AND @StartDate AND WO.MasterCompanyId = @MasterCompanyId
					GROUP BY C.CustomerId, C.Name
					)
					INSERT INTO #tmpTop10CustomerReceivedPart (Customer, TotalWorkOrderCount)
					SELECT
					Name,         
					CountOfOrders  
					FROM tmpTop10CustomerReceivedWOPart
					ORDER BY CountOfOrders DESC
					OFFSET 0 ROWS
					FETCH FIRST @TopNumberDetails ROWS ONLY;

					-- END --


					-- Start : Assignment by Tech (Workable Backlog) Chart Value (CHART NUM: 3)--

					IF OBJECT_ID(N'tempdb..#tmpTop10TechnicianPart') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop10TechnicianPart
					END

					CREATE TABLE #tmpTop10TechnicianPart (
						ID bigint NOT NULL IDENTITY,
						TechName VARCHAR(100)  NULL,
						TotalPartCount INT NULL
					)

					;WITH tmpTop10Technician AS (
					SELECT  
						E.FirstName + ' ' + E.LastName AS Name, 
						E.EmployeeId, 
						COUNT(WOP.ID) AS CountOfOrders
					FROM dbo.[WorkOrderPartNumber] WOP WITH(NOLOCK)
					INNER JOIN dbo.Employee E WITH (NOLOCK) ON E.EmployeeId = WOP.TechnicianId
					INNER JOIN dbo.WorkOrderStage WS WITH (NOLOCK) ON WS.WorkOrderStageId = WOP.WorkOrderStageId
					WHERE WS.WorkableBacklog = 1 AND CONVERT(DATE, WOP.CreatedDate) 
						BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) 
						AND @StartDate AND WOP.MasterCompanyId = @MasterCompanyId
					GROUP BY E.FirstName, E.LastName,E.EmployeeId
					)
					INSERT INTO #tmpTop10TechnicianPart (TechName, TotalPartCount)
					SELECT
					Name,         
					CountOfOrders  
					FROM tmpTop10Technician
					ORDER BY CountOfOrders DESC
					OFFSET 0 ROWS
					FETCH FIRST @TopNumberDetails ROWS ONLY;

					-- END --


					-- Start: Workable Backlog by Stage Chart Value (CHART NUM: 4)--

					IF OBJECT_ID(N'tempdb..#tmpTop10WOStage') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop10WOStage
					END

					CREATE TABLE #tmpTop10WOStage (
						ID bigint NOT NULL IDENTITY,
						Stage VARCHAR(100)  NULL,
						TotalPartCount INT NULL
					)

					;WITH tmpTop10WorkOrderStage AS (
					SELECT  
						WS.Stage AS Name, 
						WOP.WorkOrderStageId, 
						COUNT(WOP.ID) AS CountOfOrders
					FROM dbo.[WorkOrderPartNumber] WOP WITH(NOLOCK)
					INNER JOIN dbo.WorkOrderStage WS WITH (NOLOCK) ON WS.WorkOrderStageId = WOP.WorkOrderStageId
					WHERE CONVERT(DATE, WOP.CreatedDate) 
						BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) 
						AND @StartDate  AND WOP.MasterCompanyId = @MasterCompanyId
					GROUP BY  WS.Stage,WOP.WorkOrderStageId
					)
					INSERT INTO #tmpTop10WOStage (Stage, TotalPartCount)
					SELECT
					Name,         
					CountOfOrders 
					FROM tmpTop10WorkOrderStage
					ORDER BY CountOfOrders DESC
					OFFSET 0 ROWS
					FETCH FIRST @TopNumberDetails ROWS ONLY;

					-- END--


					-- Start: WorkOrder Turn Around Time Chart value (CHART NUM: 5)--
					
					IF OBJECT_ID(N'tempdb..#tmpTop10TATData') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop10TATData
					END

					CREATE TABLE #tmpTop10TATData (
						ID bigint NOT NULL IDENTITY,
						Scope VARCHAR(100)  NULL,
						DaysCount INT NULL
					)
					;WITH TimeSums AS (
					SELECT 
							SUM(WT.Hours) AS TotalDays, 
							SUM(WT.Hours) AS TotalHours, 
							SUM(WT.Mins) AS TotalMinutes,
							WOP.WorkOrderScopeId,
							WOP.WorkScope
					FROM dbo.[WorkOrderPartNumber] WOP WITH(NOLOCK)
					INNER JOIN dbo.WorkOrderStage WS WITH (NOLOCK) ON WS.WorkOrderStageId = WOP.WorkOrderStageId AND ISNULL(WS.QuoteDays,0) = 1 AND ISNULL(Ws.IncludeInTAT,0) = 1
					INNER JOIN dbo.WorkOrderTurnArroundTime WT WITH (NOLOCK) ON WT.WorkOrderPartNoId = WOP.ID AND WT.OldStageId = WS.WorkOrderStageId
					WHERE CONVERT(DATE, WOP.CreatedDate) BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) AND @StartDate
						  AND WOP.WorkOrderScopeId IN( @OverHualScopeId ,@RepairScopeId,@BenChekScopeId) AND WOP.MasterCompanyId = @MasterCompanyId 
						  GROUP BY WOP.WorkOrderScopeId,WOP.WorkScope
						  )

					INSERT INTO #tmpTop10TATData (Scope, DaysCount)
					SELECT
					WorkScope,
					sum( (TotalDays + (TotalHours / 24) + ((TotalHours % 24) + (TotalMinutes / 60)) + ((TotalMinutes % 60)) )) as totaldays
					FROM TimeSums
					group by WorkScope
					ORDER BY totaldays DESC
					
					OFFSET 0 ROWS
					FETCH FIRST @TopNumberDetails ROWS ONLY;
			
					-- END  --


					--Start: On Time Performance Chart Value (CHART NUM: 6)--

					IF OBJECT_ID(N'tempdb..#tmpTop10OnTimePerfomance') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop10OnTimePerfomance
					END

					CREATE TABLE #tmpTop10OnTimePerfomance (
						ID bigint NOT NULL IDENTITY,
						OnTimePercentage DECIMAL (9,2) NULL,
						NotOnTimePercentage DECIMAL (9,2) NULL,
						Lable VARCHAR(100) NULL
					)
					;WITH tmpOnTimePerfomance AS (
					SELECT  
						count(wop.Id) as total,
						SUM((CASE WHEN FORMAT(WOS.ShipDate,'MM/dd/yyyy') <= FORMAT(WOP.PromisedDate,'MM/dd/yyyy') THEN 1 ELSE 0 END)) AS 'ontime',
						SUM((CASE WHEN FORMAT(WOS.ShipDate,'MM/dd/yyyy') <= FORMAT(WOP.PromisedDate,'MM/dd/yyyy') THEN 0 ELSE 1 END)) AS 'Notontime'					
					FROM dbo.[WorkOrderPartNumber] WOP WITH(NOLOCK)
					INNER JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOP.ID = WOSI.WorkOrderPartNumId  
					INNER JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId 
					WHERE CONVERT(DATE, WOS.ShipDate) 
						BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) AND @StartDate  AND WOP.MasterCompanyId = @MasterCompanyId
					)
					Select @OnTimePerform = ((CONVERT(decimal(9,2),ontime) * 100) / total),
						   @NOTOnTimePerform = ((CONVERT(decimal(9,2),Notontime) * 100) / total)
					from tmpOnTimePerfomance
					ORDER BY total DESC
					OFFSET 0 ROWS
					FETCH FIRST @TopNumberDetails ROWS ONLY;
					
					-- END --


					SELECT TotalSalesCount AS col1, PartNumber AS col2 FROM #tmpTop10PartQuoted

					SELECT TotalWorkOrderCount AS col1, Customer AS col2 FROM #tmpTop10CustomerReceivedPart

					SELECT TotalPartCount AS col1, TechName AS col2 FROM #tmpTop10TechnicianPart

					SELECT TotalPartCount AS col1, Stage AS col2 FROM #tmpTop10WOStage

					SELECT Scope AS col1,DaysCount AS col2 FROM #tmpTop10TATData

					SELECT ISNULL(@OnTimePerform,0) AS 'OnTime',ISNULL(@NOTOnTimePerform,0) AS 'NotOnTime' 

			END
		
	END TRY      
	BEGIN CATCH        
		IF @@trancount > 0  
			PRINT 'ROLLBACK'  
            ROLLBACK TRAN;  
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetWOQPartsMonthlyYearlyDashboardData'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''--+ ISNULL(@MasterCompanyId, '') 
                 
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
            exec spLogException   
                    @DatabaseName   = @DatabaseName  
                    , @AdhocComments   = @AdhocComments  
                    , @ProcedureParameters  = @ProcedureParameters  
                    , @ApplicationName   =  @ApplicationName  
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
        RETURN(1);  
    END CATCH    
END