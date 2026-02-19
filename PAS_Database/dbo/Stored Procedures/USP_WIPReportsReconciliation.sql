/*********************             
 ** File:   GET WIP REPORTS DATA          
 ** Author:  Priyansh Patel  
 ** Description: This SP Is Used to Get WIP reports Data
 ** Purpose:           
 ** Date:  11/02/2026
    
 ************************************************************             
  ** Change History             
 ************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    11/02/2026   Priyansh Patel      Created  for Initial Requirements	

     
exec USP_WIPReportsReconciliation @mastercompanyid=1,@id='2024-01-25 00:00:00',@id2='2024-05-24 00:00:00'

*************************************************************/   
  
CREATE       PROCEDURE [dbo].[USP_WIPReportsReconciliation] 	
@mastercompanyid INT,
@id VARCHAR(MAX),
@id2 VARCHAR(MAX)
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY
		
		DECLARE @FromDate DATETIME = ISNULL(TRY_CAST(@id AS DATETIME),NULL) 
		DECLARE @ToDate DATETIME = ISNULL(TRY_CAST(@id2 AS DATETIME),NULL) 

        DECLARE @WIPMaterialCategoryId INT = 1;
        DECLARE @WIPDirectLaborCategoryId INT = 2;
        DECLARE @WIPOverheadCategoryId INT = 3;
		
        DECLARE @PostedStatus INT = 3;
        DECLARE @UnPostedStatus INT = 1;

        DECLARE @TotalMiscCost DECIMAL(18,2)  = 0;
        DECLARE @TotalOtherCost DECIMAL(18,2)  = 0;
        DECLARE @TotalDirectLaborCost DECIMAL(18,2)  = 0;
        DECLARE @TotalOHCost DECIMAL(18,2)  = 0;
        DECLARE @TaskStatus VARCHAR(20) = 'COMPLETED';
        DECLARE @TotalUnpostedDirectLaborCost DECIMAL(18,2)  = 0;
        DECLARE @TotalUnpostedOverheadCost DECIMAL(18,2)  = 0;
        -- From GL
        DECLARE @TotalWIPMaterialWIPPostedGL DECIMAL(18,2)  = 0;
        DECLARE @TotalWIPMaterialWIPUnpostedGL DECIMAL(18,2)  = 0;
        DECLARE @TotalDirectLaborPostedGL DECIMAL(18,2)  = 0;
        DECLARE @TotalDirectLaborUnpostedGL DECIMAL(18,2)  = 0;
        DECLARE @TotalWIPOverheadPostedGL DECIMAL(18,2)  = 0;
        DECLARE @TotalWIPOverheadUnPostedGL DECIMAL(18,2)  = 0;


        IF OBJECT_ID(N'tempdb..#tmpWO') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpWO
		END

        SELECT WO.WorkOrderId
        INTO #tmpWO
        FROM dbo.WorkOrder WO WITH (NOLOCK)
        WHERE WO.MasterCompanyId = @MasterCompanyId AND WO.IsDeleted = 0 AND WO.IsActive = 1
        AND CAST(WO.OpenDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE);


		IF OBJECT_ID(N'tempdb..#tmpWorkOrderPartsCost') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpWorkOrderPartsCost
		END

        IF OBJECT_ID(N'tempdb..#tmpWorkOrderTotalCost') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpWorkOrderTotalCost
		END

        CREATE TABLE #tmpWorkOrderPartsCost
        (
            WorkOrderId   BIGINT,
            PartsCost    DECIMAL(18,2),
            TotalPartsCost DECIMAL(18,2),
        );

         CREATE TABLE #tmpWorkOrderTotalCost
        (
            TotalPartsCost DECIMAL(18,2),
            TotalDirectLaborCost DECIMAL(18,2) NULL, 
            TotalOHCost DECIMAL(18,2) NULL, 
            TotalMiscCost DECIMAL(18,2) NULL, 
            TotalOtherCost DECIMAL(18,2) NULL,
            TotalWIPCost DECIMAL(18,2) NULL,
            TotalUnpostedDirectLaborCost DECIMAL(18,2) NULL, 
            TotalUnpostedOverheadCost DECIMAL(18,2) NULL,
            TotalWIPMaterialWIPPostedGL DECIMAL(18,2) NULL,
            TotalWIPMaterialWIPUnpostedGL DECIMAL(18,2)  NULL,
            TotalDirectLaborUnpostedGL DECIMAL(18,2)  NULL,
            TotalDirectLaborPostedGL DECIMAL(18,2)  NULL,
            TotalWIPOverheadPostedGL   DECIMAL(18,2) NULL,
            TotalWIPOverheadUnpostedGL DECIMAL(18,2) NULL
        );
    
        INSERT INTO #tmpWorkOrderPartsCost (WorkOrderId, PartsCost, TotalPartsCost)
        SELECT
            WorkOrderId,
            SUM(PartsCost) AS PartsCost,
            SUM(SUM(PartsCost)) OVER () AS TotalPartsCost
        FROM
        (
            SELECT WO.WorkOrderId,(WOMS.QtyIssued * WOMS.UnitCost) AS PartsCost
            FROM WorkOrderMaterialstockline WOMS WITH (NOLOCK) 
            JOIN WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId 
            JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
            JOIN WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.ID = WOWF.WorkOrderPartNoId
            JOIN #tmpWO WO ON WO.WorkOrderId = WOP.WorkOrderId
            WHERE WOP.MasterCompanyId = @MasterCompanyId 
             AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive, 0) = 1 AND ISNULL(WOP.IsFinishGood, 0) = 0 

            UNION ALL

            SELECT WO.WorkOrderId,(WOMS.QtyIssued * WOMS.UnitCost) AS PartsCost 
            FROM WorkORderMaterialStocklineKit WOMS WITH (NOLOCK)
                JOIN WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId
                JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
                JOIN WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.ID = WOWF.WorkOrderPartNoId
                JOIN #tmpWO WO ON WO.WorkOrderId = WOP.WorkOrderId
            WHERE WOP.MasterCompanyId = @MasterCompanyId AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive, 0) = 1 AND ISNULL(WOP.IsFinishGood, 0) = 0
        ) A
        GROUP BY WorkOrderId;
 

        SELECT @TotalOtherCost = ISNULL(SUM(WOC.Quantity * WOC.UnitCost), 0)
            FROM WorkOrderCharges WOC  WITH (NOLOCK) 
            JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOC.WorkFlowWorkOrderId
            JOIN #tmpWO WO ON WO.WorkOrderId = WOWF.WorkOrderId
            WHERE WOC.MasterCompanyId = @MasterCompanyId  AND ISNULL(WOC.IsDeleted, 0) = 0 AND ISNULL(WOC.IsActive, 0) = 1 

        SELECT @TotalMiscCost = ISNULL(SUM(WOF.Amount), 0) FROM WorkOrderFreight WOF WITH (NOLOCK) 
            JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOF.WorkFlowWorkOrderId
            JOIN #tmpWO WO ON WO.WorkOrderId = WOWF.WorkOrderId
            WHERE WOF.MasterCompanyId = @MasterCompanyId  AND ISNULL(WOF.IsDeleted, 0) = 0 AND ISNULL(WOF.IsActive, 0) = 1  

            
        SELECT @TotalDirectLaborCost = ISNULL(SUM(ISNULL(WCD.LaborCost, 0) - ISNULL(WCD.OverHeadCost, 0)), 0),@TotalOHCost = ISNULL(SUM(WCD.OverHeadCost), 0) 
        FROM WorkOrderCostDetails WCD WITH (NOLOCK) 
        JOIN #tmpWO WO ON WO.WorkOrderId = WCD.WorkOrderId
        WHERE WCD.MasterCompanyId = @MasterCompanyId AND ISNULL(WCD.IsDeleted, 0) = 0 AND ISNULL(WCD.IsActive, 0) = 1 

        IF OBJECT_ID('tempdb..#tmpWorkOrderCosts') IS NOT NULL
        BEGIN   
            DROP TABLE #tmpWorkOrderCosts;
        END

        SELECT @TotalUnpostedDirectLaborCost = SUM(WOL.BurdenRateAmount*((CASE WHEN WOL.AdjustedHours<0 THEN -1 ELSE 1 END * 
        (FLOOR(ABS(WOL.AdjustedHours))*60 + CONVERT(INT,ROUND((ABS(WOL.AdjustedHours)-FLOOR(ABS(WOL.AdjustedHours)))*100.0,0))))/60.0)),
        @TotalUnpostedOverheadCost = SUM(WOL.DirectLaborOHCost*((CASE WHEN WOL.AdjustedHours<0 THEN -1 ELSE 1 END * 
        (FLOOR(ABS(WOL.AdjustedHours))*60 + CONVERT(INT,ROUND((ABS(WOL.AdjustedHours)-FLOOR(ABS(WOL.AdjustedHours)))*100.0,0))))/60.0))
        FROM dbo.WorkOrderPartNumber WOP WITH (NOLOCK)
        JOIN #tmpWO WO ON WO.WorkOrderId=WOP.WorkOrderId
        JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderPartNoId=WOP.ID
        JOIN dbo.WorkOrderLaborHeader WOLH WITH (NOLOCK) ON WOLH.WorkFlowWorkOrderId=WOWF.WorkFlowWorkOrderId
        JOIN dbo.WorkOrderLabor WOL WITH (NOLOCK) ON WOL.WorkOrderLaborHeaderId=WOLH.WorkOrderLaborHeaderId
        JOIN dbo.TaskStatus TS WITH (NOLOCK) ON TS.TaskStatusId=WOL.TaskStatusId AND (TS.StatusCode IS NULL OR TS.StatusCode<>@TaskStatus) AND TS.IsActive=1 AND TS.IsDeleted=0
        WHERE ISNULL(WOL.IsDeleted, 0) = 0 AND ISNULL(WOL.IsActive, 0) = 1 

        SELECT @TotalWIPMaterialWIPPostedGL = ISNULL(SUM(CASE 
        WHEN WC.WIPCategoryId = @WIPMaterialCategoryId AND BD.StatusId = @PostedStatus
        THEN CBD.DebitAmount - CBD.CreditAmount END), 0),

        @TotalWIPMaterialWIPUnpostedGL = ISNULL(SUM(CASE 
        WHEN WC.WIPCategoryId = @WIPMaterialCategoryId AND BD.StatusId = @UnPostedStatus
        THEN CBD.DebitAmount - CBD.CreditAmount END), 0),

        @TotalDirectLaborPostedGL = ISNULL(SUM(CASE 
        WHEN WC.WIPCategoryId = @WIPDirectLaborCategoryId AND BD.StatusId = @PostedStatus
        THEN CBD.DebitAmount - CBD.CreditAmount END), 0),

        @TotalDirectLaborUnpostedGL = ISNULL(SUM(CASE 
        WHEN WC.WIPCategoryId = @WIPDirectLaborCategoryId AND BD.StatusId = @UnPostedStatus
        THEN CBD.DebitAmount - CBD.CreditAmount END), 0),

        @TotalWIPOverheadPostedGL = ISNULL(SUM(CASE 
        WHEN WC.WIPCategoryId = @WIPOverheadCategoryId AND BD.StatusId = @PostedStatus
        THEN CBD.DebitAmount - CBD.CreditAmount END), 0),

        @TotalWIPOverheadUnPostedGL = ISNULL(SUM(CASE 
        WHEN WC.WIPCategoryId = @WIPOverheadCategoryId AND BD.StatusId = @UnPostedStatus
        THEN CBD.DebitAmount - CBD.CreditAmount END), 0)

        FROM CommonBatchDetails CBD WITH (NOLOCK)
        JOIN dbo.WIPGLAccountSetup WIP WITH (NOLOCK) ON WIP.GlAccountId = CBD.GlAccountId
        LEFT JOIN dbo.WIPCategory WC WITH (NOLOCK) ON WIP.WIPCategoryId = WC.WIPCategoryId
        JOIN dbo.BatchDetails BD WITH (NOLOCK) ON BD.JournalBatchDetailId = CBD.JournalBatchDetailId
        WHERE WIP.MasterCompanyId = @mastercompanyid AND ISNULL(WIP.IsDeleted, 0) = 0 AND ISNULL(WIP.IsActive, 0) = 1 AND CAST(CBD.EntryDate AS DATE) 
            BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE);


        INSERT INTO #tmpWorkOrderTotalCost (TotalPartsCost,TotalDirectLaborCost, TotalOHCost,TotalMiscCost,TotalOtherCost,TotalWIPCost,TotalUnpostedDirectLaborCost,TotalUnpostedOverheadCost,TotalWIPMaterialWIPPostedGL,TotalWIPMaterialWIPUnpostedGL,TotalDirectLaborPostedGL,TotalDirectLaborUnpostedGL,TotalWIPOverheadPostedGL,TotalWIPOverheadUnpostedGL )
        SELECT ISNULL(MAX(TotalPartsCost),0) AS TotalPartsCost, ISNULL(@TotalDirectLaborCost,0), ISNULL(@TotalOHCost,0), ISNULL(@TotalMiscCost,0) AS TotalMiscCost,  ISNULL(@TotalOtherCost,0) AS TotalOtherCost,
            ISNULL(MAX(TotalPartsCost),0)
          + ISNULL(@TotalDirectLaborCost,0)
          + ISNULL(@TotalOHCost,0)
          + ISNULL(@TotalMiscCost,0)
          + ISNULL(@TotalOtherCost,0) AS TotalWIPCost,
          ISNULL(@TotalUnpostedDirectLaborCost,0), ISNULL(@TotalUnpostedOverheadCost,0),
          @TotalWIPMaterialWIPPostedGL,@TotalWIPMaterialWIPUnpostedGL,@TotalDirectLaborPostedGL, @TotalDirectLaborUnpostedGL,@TotalWIPOverheadPostedGL,@TotalWIPOverheadUnPostedGL
          
          FROM #tmpWorkOrderPartsCost;

        SELECT * FROM #tmpWorkOrderTotalCost;



 END TRY      
 BEGIN CATCH  
	
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_WIPReportsReconciliation'   
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100))   
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
 END CATCH  
END