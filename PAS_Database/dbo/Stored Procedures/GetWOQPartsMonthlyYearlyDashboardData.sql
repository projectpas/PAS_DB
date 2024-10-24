﻿/*************************************************************           
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
	2    16 OCT 2024	HEMANT SALIYA		UPDATE Open Date Changes   
	3    18 OCT 2024	HEMANT SALIYA		UPDATE For TAT Calculation 

EXEC GetWOQPartsMonthlyYearlyDashboardData 1, 2, '2024-10-18',10,1
************************************************************************/
CREATE   PROCEDURE [dbo].[GetWOQPartsMonthlyYearlyDashboardData]
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

	--SET @StartDate = GETUTCDATE();
		
			BEGIN
				DECLARE @WOQMSModuleID INT = (SELECT ManagementStructureModuleId FROM ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'WorkOrderMPN');
				DECLARE @EmployeeRoleID NVARCHAR(MAX);
				DECLARE @OnTimePerform DECIMAL(9,2)= NULL;
				DECLARE @OnTimePerformCount DECIMAL(9,2)= NULL;
				DECLARE @NOTOnTimePerform DECIMAL(9,2) =NULL;
				DECLARE @NOTOnTimePerformCount DECIMAL(9,2) =NULL;
				DECLARE @TotalTimePerform DECIMAL(9,2) =NULL;
				DECLARE @OverHualScopeId BIGINT = (SELECT WorkScopeId FROM dbo.[WorkScope] WITH (NOLOCK) WHERE WorkScopeCode = 'OVERHAUL' AND MasterCompanyId = @MasterCompanyId);
				DECLARE @RepairScopeId BIGINT = (SELECT WorkScopeId FROM dbo.[WorkScope] WITH (NOLOCK) WHERE WorkScopeCode = 'REPAIR' AND MasterCompanyId = @MasterCompanyId);
				DECLARE @BenChekScopeId BIGINT = (SELECT WorkScopeId FROM dbo.[WorkScope] WITH (NOLOCK) WHERE WorkScopeCode = 'BENCHCHECK' AND MasterCompanyId = @MasterCompanyId);
				SELECT @EmployeeRoleID = STUFF((
						SELECT DISTINCT ',' + CAST(RoleId AS VARCHAR(100))
						FROM dbo.EmployeeUserRole WITH (NOLOCK)
						WHERE EmployeeId = @EmployeeId
						FOR XML PATH('')
					), 1, 1, '');

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
						INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WP.WorkOrderId = WO.WorkOrderId  
						INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON WP.ItemMasterId = IM.ItemMasterId
					WHERE CONVERT(DATE,WO.OpenDate) BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) 
						AND @StartDate AND WP.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted = 0 AND WP.IsDeleted = 0 
						AND WP.ManagementStructureId = @ManagementStructureId
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
					FROM [dbo].[ReceivingCustomerWork] RC WITH (NOLOCK)
					INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RC.CustomerId
					WHERE CONVERT(DATE, RC.ReceivedDate) 
						BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) 
						AND @StartDate AND RC.MasterCompanyId = @MasterCompanyId
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
					INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
					INNER JOIN dbo.Employee E WITH (NOLOCK) ON E.EmployeeId = WOP.TechnicianId
					INNER JOIN dbo.WorkOrderStage WS WITH (NOLOCK) ON WS.WorkOrderStageId = WOP.WorkOrderStageId
					WHERE ISNULL(WS.WorkableBacklog, 0) = 1 AND CONVERT(DATE, WO.OpenDate) 
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
						INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
						INNER JOIN dbo.WorkOrderStage WS WITH (NOLOCK) ON WS.WorkOrderStageId = WOP.WorkOrderStageId AND ISNULL(WS.WorkableBacklog, 0) = 1
					WHERE CONVERT(DATE, WO.OpenDate) 
						BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) 
						AND @StartDate  AND WOP.MasterCompanyId = @MasterCompanyId
					GROUP BY  WS.Stage,WOP.WorkOrderStageId
					)
					INSERT INTO #tmpTop10WOStage (Stage, TotalPartCount)
					SELECT
						UPPER(Name),         
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
						WorkOrderScopeId BIGINT  NULL,
						Scope VARCHAR(100)  NULL,
						DaysCount DECIMAL(18,2) NULL,
						PartsCount INT  NULL,
					)
					;WITH TimeSums AS (
					SELECT 
							SUM(WT.Days) AS TotalDays, 
							SUM(WT.Hours) AS TotalHours, 
							SUM(WT.Mins) AS TotalMinutes,
							WOP.WorkOrderScopeId,
							WOP.WorkScope
					FROM dbo.[WorkOrderPartNumber] WOP WITH(NOLOCK)
						INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
						INNER JOIN dbo.WorkOrderTurnArroundTime WT WITH (NOLOCK) ON WT.WorkOrderPartNoId = WOP.ID 
						LEFT JOIN dbo.WorkOrderStage WS WITH (NOLOCK) ON WS.WorkOrderStageId = WT.OldStageId AND ISNULL(WS.QuoteDays,0) = 1 AND ISNULL(Ws.IncludeInTAT,0) = 1
					WHERE CONVERT(DATE, WO.OpenDate) BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) AND @StartDate
						  AND WOP.WorkOrderScopeId IN( @OverHualScopeId ,@RepairScopeId,@BenChekScopeId) AND WOP.MasterCompanyId = @MasterCompanyId 
						  GROUP BY WOP.WorkOrderScopeId,WOP.WorkScope,WorkOrderScopeId)

					INSERT INTO #tmpTop10TATData (Scope, DaysCount, WorkOrderScopeId)
					SELECT
						WorkScope,
						SUM(TotalDays + (TotalHours / 24.0) + (TotalMinutes / 1440.0)) AS totaldays,
						WorkOrderScopeId
					FROM TimeSums
					GROUP BY WorkScope, WorkOrderScopeId
					ORDER BY totaldays DESC
					
					OFFSET 0 ROWS
					FETCH FIRST @TopNumberDetails ROWS ONLY;
			
					-- END  --

					UPDATE #tmpTop10TATData SET PartsCount = GPParts.PartsCount
					FROM(
							SELECT COUNT(WOP.ID) As PartsCount, WorkOrderScopeId
							FROM dbo.[WorkOrderPartNumber] WOP WITH(NOLOCK)
								INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
							WHERE CONVERT(DATE, WO.OpenDate) BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) AND @StartDate
								  AND WOP.WorkOrderScopeId IN( @OverHualScopeId) AND WOP.MasterCompanyId = @MasterCompanyId 
							GROUP BY WOP.WorkOrderScopeId
						) GPParts WHERE GPParts.WorkOrderScopeId = #tmpTop10TATData.WorkOrderScopeId

						
					UPDATE #tmpTop10TATData SET DaysCount = ROUND(CAST(DaysCount/PartsCount AS DECIMAL(18,2)), 0)

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
						   @NOTOnTimePerform = ((CONVERT(decimal(9,2),Notontime) * 100) / total),
						   @OnTimePerformCount = ontime,
						   @NOTOnTimePerformCount = Notontime,
						   @TotalTimePerform = total
					from tmpOnTimePerfomance
					ORDER BY total DESC
					OFFSET 0 ROWS
					FETCH FIRST @TopNumberDetails ROWS ONLY;
					
					-- END --


					SELECT TotalSalesCount AS col1, PartNumber AS col2 FROM #tmpTop10PartQuoted

					SELECT TotalWorkOrderCount AS col1, Customer AS col2 FROM #tmpTop10CustomerReceivedPart

					SELECT TotalPartCount AS col1, TechName AS col2 FROM #tmpTop10TechnicianPart

					SELECT TotalPartCount AS col1, Stage AS col2 FROM #tmpTop10WOStage

					SELECT DaysCount AS col1,Scope AS col2 FROM #tmpTop10TATData

					SELECT ISNULL(@OnTimePerformCount,0) AS 'OnTime',ISNULL(@NOTOnTimePerformCount,0) AS 'NotOnTime' 

					SELECT ISNULL(@OnTimePerform,0) AS col1 ,  ISNULL(@NOTOnTimePerform,0) AS col2 ,ISNULL(@TotalTimePerform,0) AS col3 

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