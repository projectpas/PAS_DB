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
  
CREATE         PROCEDURE [dbo].[USP_WIPReportsReconciliation] 	
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
		
        DECLARE @TotalMiscCost DECIMAL(18,2)  = NULL;
        DECLARE @TotalOtherCost DECIMAL(18,2)  = NULL;
        DECLARE @TotalDirectLaborCost DECIMAL(18,2)  = NULL;
        DECLARE @TotalOHCost DECIMAL(18,2)  = NULL;

        IF OBJECT_ID(N'tempdb..#tmpWO') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpWO
		END

        SELECT WO.WorkOrderId
        INTO #tmpWO
        FROM dbo.WorkOrder WO
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
            TotalUnpostedOverheadCost DECIMAL(18,2) NULL
        );
    
        INSERT INTO #tmpWorkOrderPartsCost (WorkOrderId, PartsCost, TotalPartsCost)
        SELECT
            WorkOrderId,
            SUM(PartsCost) AS PartsCost,
            SUM(SUM(PartsCost)) OVER () AS TotalPartsCost
        FROM
        (
            SELECT WO.WorkOrderId,(WOMS.QtyIssued * WOMS.UnitCost) AS PartsCost
            FROM WorkOrderMaterialstockline WOMS JOIN WorkOrderMaterials WOM ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId 
            JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
            JOIN WorkOrderPartNumber WOP ON WOP.ID = WOWF.WorkOrderPartNoId
            --JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
            JOIN #tmpWO WO ON WO.WorkOrderId = WOP.WorkOrderId
            WHERE WOP.MasterCompanyId = @MasterCompanyId 
             AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive, 0) = 1 

            UNION ALL

            SELECT WO.WorkOrderId,(WOMS.QtyIssued * WOMS.UnitCost) AS PartsCost 
            FROM WorkORderMaterialStocklineKit WOMS
                JOIN WorkOrderMaterialsKit WOM ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId
                JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
                JOIN WorkOrderPartNumber WOP ON WOP.ID = WOWF.WorkOrderPartNoId
                --JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
                JOIN #tmpWO WO ON WO.WorkOrderId = WOP.WorkOrderId
            WHERE WOP.MasterCompanyId = @MasterCompanyId AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive, 0) = 1 
        ) A
        GROUP BY WorkOrderId;
 

        SELECT @TotalMiscCost = ISNULL(SUM(WOC.Quantity * WOC.UnitCost), 0)
            FROM WorkOrderCharges WOC  WITH (NOLOCK) 
            JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOC.WorkFlowWorkOrderId
            --JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOWF.WorkOrderId
            JOIN #tmpWO WO ON WO.WorkOrderId = WOWF.WorkOrderId
            WHERE WOC.MasterCompanyId = @MasterCompanyId  AND ISNULL(WOC.IsDeleted, 0) = 0 AND ISNULL(WOC.IsActive, 0) = 1 

        SELECT @TotalOtherCost = ISNULL(SUM(WOF.Amount), 0) FROM WorkOrderFreight WOF WITH (NOLOCK) 
            JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOF.WorkFlowWorkOrderId
            --JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOWF.WorkOrderId
            JOIN #tmpWO WO ON WO.WorkOrderId = WOWF.WorkOrderId
            WHERE WOF.MasterCompanyId = @MasterCompanyId  AND ISNULL(WOF.IsDeleted, 0) = 0 AND ISNULL(WOF.IsActive, 0) = 1 

        SELECT @TotalDirectLaborCost = ISNULL(SUM(WCD.LaborCost), 0),@TotalOHCost = ISNULL(SUM(WCD.OverHeadCost), 0) 
               FROM WorkOrderCostDetails WCD WITH (NOLOCK)
               JOIN #tmpWO WO ON WO.WorkOrderId = WCD.WorkOrderId
               --JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WCD.WorkOrderId
                WHERE WCD.MasterCompanyId = @MasterCompanyId AND ISNULL(WCD.IsDeleted, 0) = 0 AND ISNULL(WCD.IsActive, 0) = 1 


        INSERT INTO #tmpWorkOrderTotalCost (TotalPartsCost,TotalDirectLaborCost, TotalOHCost,TotalMiscCost,TotalOtherCost,TotalWIPCost,TotalUnpostedDirectLaborCost,TotalUnpostedOverheadCost)
        SELECT MAX(TotalPartsCost) AS TotalPartsCost, @TotalDirectLaborCost, @TotalOHCost, @TotalMiscCost AS TotalMiscCost,  @TotalOtherCost AS TotalOtherCost,
            ISNULL(MAX(TotalPartsCost),0)
          + ISNULL(@TotalDirectLaborCost,0)
          + ISNULL(@TotalOHCost,0)
          + ISNULL(@TotalMiscCost,0)
          + ISNULL(@TotalOtherCost,0) AS TotalWIPCost,
          0, 0 FROM #tmpWorkOrderPartsCost;

        SELECT * FROM #tmpWorkOrderTotalCost;


 END TRY      
 BEGIN CATCH  
	
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_CheckAllowReopenWorkOrder'   
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