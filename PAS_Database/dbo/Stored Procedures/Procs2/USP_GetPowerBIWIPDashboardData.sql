/*********************             
 ** File:   GET POWER BI WIP DASHBOARD DATA          
 ** Author:  Sumit Kumar  
 ** Description: Single Consolidated API Stored Procedure for Power BI WIP Flow Dashboard
 ** Purpose: Fetches all active WIP records into Power BI Import Mode where in-memory slicers filter dynamically
 ** Date:  18/09/2026
    
 ************************************************************             
  ** Change History             
 ************************************************************             
  ** PR   Date         Author			Change Description              
  ** --   --------     -------			--------------------------------            
     1    18/09/2026   Sumit Kumar      Created for Power BI Single API Requirement	

 exec USP_GetPowerBIWIPDashboardData @masterCompanyId=1
*************************************************************/   
CREATE PROCEDURE [dbo].[USP_GetPowerBIWIPDashboardData] 	
    @masterCompanyId INT
AS  
BEGIN  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    SET NOCOUNT ON;  

    BEGIN TRY
        -- SECTION 1: Local Constants & Module Setup
        DECLARE @ModuleID INT = 12; -- WO MPN MS Module ID 
        DECLARE @TaskStatus VARCHAR(20) = 'COMPLETED';

        -- SECTION 2: Extract Active Unposted Work Order Labor & Overhead Records
        IF OBJECT_ID(N'tempdb..#tmpWorkOrderLabor') IS NOT NULL
            DROP TABLE #tmpWorkOrderLabor;

        CREATE TABLE #tmpWorkOrderLabor
        (
            WorkOrderId BIGINT,
            WorkOrderPartNoId BIGINT,
            DirectLaborOHCost DECIMAL(18,2),
            BurdenRateAmount DECIMAL(18,2),
            AdjustedHours DECIMAL(18,2)
        );

        INSERT INTO #tmpWorkOrderLabor
        SELECT
            WO.WorkOrderId,
            WOP.ID AS WorkOrderPartNoId,
            ISNULL(WOL.DirectLaborOHCost, 0),
            ISNULL(WOL.BurdenRateAmount, 0),
            ISNULL(WOL.AdjustedHours, 0)
        FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
        JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
        JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
        JOIN dbo.WorkOrderLaborHeader WOLH WITH(NOLOCK) ON WOLH.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
        JOIN dbo.WorkOrderLabor WOL WITH(NOLOCK) ON WOL.WorkOrderLaborHeaderId = WOLH.WorkOrderLaborHeaderId
        JOIN dbo.TaskStatus TS WITH(NOLOCK) ON TS.TaskStatusId = WOL.TaskStatusId AND (TS.StatusCode IS NULL OR TS.StatusCode <> @TaskStatus) AND TS.IsActive = 1 AND TS.IsDeleted = 0
        WHERE WO.MasterCompanyId = @masterCompanyId 
          AND ISNULL(WO.IsDeleted, 0) = 0 AND ISNULL(WO.IsActive, 0) = 1 
          AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive, 0) = 1
          AND ISNULL(WOP.IsFinishGood, 0) = 0;

        -- SECTION 3: Aggregate Unposted Direct Labor & Overhead Costs by Work Order Part
        IF OBJECT_ID('tempdb..#tmpUnpostedCosts') IS NOT NULL
            DROP TABLE #tmpUnpostedCosts;

        SELECT 
            WorkOrderPartNoId,
            SUM(BurdenRateAmount * (((CASE WHEN AdjustedHours < 0 THEN -1 ELSE 1 END * (FLOOR(ABS(AdjustedHours))*60 + CONVERT(INT, ROUND((ABS(AdjustedHours)-FLOOR(ABS(AdjustedHours)))*100.0,0))))/60.0))) AS UnpostedOverhead,
            SUM(DirectLaborOHCost * (((CASE WHEN AdjustedHours < 0 THEN -1 ELSE 1 END * (FLOOR(ABS(AdjustedHours))*60 + CONVERT(INT, ROUND((ABS(AdjustedHours)-FLOOR(ABS(AdjustedHours)))*100.0,0))))/60.0))) AS UnpostedDirectLabor
        INTO #tmpUnpostedCosts
        FROM #tmpWorkOrderLabor
        GROUP BY WorkOrderPartNoId;

        -- SECTION 4: Consolidated Main Data Selection Output for Power BI Engine
        SELECT 
            WOP.ID AS WorkOrderPartID,
            WO.WorkOrderId AS WorkOrderID,
            WO.WorkOrderNum AS WorkOrderNumber,
            ISNULL(SL.PartNumber, WOP.PartNumber) AS MPNPart,
            UPPER(SL.PNDescription) AS PartDescription,
            CASE WHEN ISNULL(WOP.RevisedSerialNumber, '') != '' THEN WOP.RevisedSerialNumber ELSE SL.SerialNumber END AS SerialNumber,
            UPPER(WO.CustomerName) AS Customer,
            UPPER(MSD.Level3Name) AS Station,
            UPPER(MSD.Level4Name) AS WorkCenter,
            UPPER(WOP.WorkScope) AS Workscope,
            CASE 
                WHEN WOP.IsClosed = 1 OR WOP.IsFinishGood = 1 THEN 'Closed' 
                ELSE 'Open' 
            END AS Status,
            CAST(WO.OpenDate AS DATE) AS Date,
            CAST(WOP.ClosedDate AS DATE) AS ClosedDate,
            CAST(ISNULL(WOP.IsClosed, 0) AS BIT) AS IsClosed,
            ISNULL(WOS.Sequence, 1) AS StageSequence,
            ISNULL(WOS.Stage, 'Induction & Intake') AS Stage,
            ISNULL(WOS.Code, 'Intake') AS StageShort,
            ISNULL(WCD.Revenue, ISNULL(WCD.PartsCost, 0) + ISNULL(WCD.LaborCost, 0) + ISNULL(WCD.FreightCost, 0) + ISNULL(WCD.OtherCost, 0)) AS Revenue,
            ISNULL(WCD.PartsCost, 0) AS PartCost,
            ISNULL(WCD.LaborCost, 0) - ISNULL(WCD.OverHeadCost, 0) AS DirectLabor,
            ISNULL(WCD.OverHeadCost, 0) AS OHCost,
            ISNULL(WCD.FreightCost, 0) AS MiscCost,
            ISNULL(WCD.OtherCost, 0) AS OtherCost,
            ISNULL(UC.UnpostedDirectLabor, 0) AS UnpostedDirectLabor,
            ISNULL(UC.UnpostedOverhead, 0) AS UnpostedOH,
            ISNULL(TAT.Days, DATEDIFF(DAY, ISNULL(WOTAT.StatusChangedDate, WO.OpenDate), GETUTCDATE())) AS StageDwellDays,
            ISNULL(WOS.QuoteDays, 15) AS ThroughputWk,
            DATEDIFF(DAY, WO.OpenDate, GETUTCDATE()) AS JobAgeDays,
            C.[Description] AS Condition,
            P.[Description] AS Priority,
            SL.StockLineNumber,
            SL.ControlNumber,
            LE.[Name] AS LegalEntity
        FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
        JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
        JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
        LEFT JOIN dbo.WorkOrderStage WOS WITH(NOLOCK) ON WOS.WorkOrderStageId = WOP.WorkOrderStageId
        LEFT JOIN dbo.Stockline SL WITH(NOLOCK) ON WOP.StockLineId = SL.StockLineId
        LEFT JOIN dbo.Condition C WITH(NOLOCK) ON WOP.RevisedConditionId = C.ConditionId
        LEFT JOIN dbo.[Priority] P WITH(NOLOCK) ON WOP.WorkOrderPriorityId = P.PriorityId
        LEFT JOIN dbo.WorkOrderMPNCostDetails WCD WITH(NOLOCK) ON WCD.WOPartNoId = WOP.ID
        LEFT JOIN dbo.WorkOrderManagementStructureDetails MSD WITH(NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOP.ID
        LEFT JOIN dbo.ManagementStructureLevel MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
        LEFT JOIN dbo.LegalEntity LE WITH(NOLOCK) ON MSL.LegalEntityId = LE.LegalEntityId
        LEFT JOIN #tmpUnpostedCosts UC ON UC.WorkOrderPartNoId = WOP.ID
        LEFT JOIN (
            SELECT WorkOrderPartNoId, CurrentStageId, StatusChangedDate,
                   ROW_NUMBER() OVER(PARTITION BY WorkOrderPartNoId ORDER BY StatusChangedDate DESC) AS RowNum
            FROM dbo.WorkOrderTurnArroundTime WITH(NOLOCK)
            WHERE StatusChangedEndDate IS NULL
        ) WOTAT ON WOTAT.WorkOrderPartNoId = WOP.ID AND WOTAT.RowNum = 1
        LEFT JOIN dbo.WorkOrderTurnArroundTime TAT WITH(NOLOCK) ON TAT.WorkOrderPartNoId = WOP.ID AND TAT.CurrentStageId = WOP.WorkOrderStageId
        WHERE WO.MasterCompanyId = @masterCompanyId
          AND ISNULL(WO.IsDeleted, 0) = 0 AND ISNULL(WO.IsActive, 0) = 1
          AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive, 0) = 1
          AND ISNULL(WOP.IsFinishGood, 0) = 0
          AND ISNULL(SL.IsNonStock, 0) = 0
        ORDER BY WOS.Sequence ASC, WO.OpenDate DESC;

    END TRY      
    -- SECTION 5: Exception Handling & Centralized Logging
    BEGIN CATCH  
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),   
                @AdhocComments VARCHAR(150) = 'USP_GetPowerBIWIPDashboardData',   
                @ProcedureParameters VARCHAR(3000) = '@masterCompanyId = ''' + CAST(ISNULL(@masterCompanyId, '') AS VARCHAR(100)) + '''',
                @ApplicationName VARCHAR(100) = 'PAS';  

        EXEC spLogException   
                @DatabaseName           = @DatabaseName,  
                @AdhocComments          = @AdhocComments,  
                @ProcedureParameters    = @ProcedureParameters,  
                @ApplicationName        = @ApplicationName,  
                @ErrorLogID             = @ErrorLogID OUTPUT;  

        RAISERROR ('Unexpected Error Occurred in database procedure USP_GetPowerBIWIPDashboardData. Error Log ID: %d', 16, 1, @ErrorLogID);  
        RETURN(1);  
    END CATCH  
END;
GO
