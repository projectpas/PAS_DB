/*********************             
 ** File:   GET WIP REPORTS DATA          
 ** Author:  HEMANT SALIYA  
 ** Description: This SP Is Used to Get WIP reports Data
 ** Purpose:           
 ** Date:  08-MAY-2024
    
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
		DECLARE @ModuleID INT = 12; -- WO MPN MS Module ID 
		DECLARE @FromDate DATETIME; 
		DECLARE @ToDate DATETIME; 
		DECLARE @ProvisionId INT;
        DECLARE @TotalMiscCost DECIMAL(18,2)  = NULL;
        DECLARE @TotalOtherCost DECIMAL(18,2)  = NULL;

		SELECT @FromDate = ISNULL(TRY_CAST(@id AS DATETIME),NULL) 
		SELECT @ToDate = ISNULL(TRY_CAST(@id2 AS DATETIME),NULL) 

		PRINT @FromDate
		PRINT @ToDate

		SELECT @ProvisionId = ProvisionId FROM dbo.Provision  WHERE StatusCode = 'REPLACE'		

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
            JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
            WHERE WOP.MasterCompanyId = @MasterCompanyId AND ISNULL(WO.IsDeleted, 0) = 0 AND ISNULL(WO.IsActive, 0) = 1 AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive, 0) = 1 AND CAST(WO.OpenDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)

            UNION ALL

            SELECT WO.WorkOrderId,(WOMS.QtyIssued * WOMS.UnitCost) AS PartsCost 
            FROM WorkORderMaterialStocklineKit WOMS
                JOIN WorkOrderMaterialsKit WOM ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId
                JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
                JOIN WorkOrderPartNumber WOP ON WOP.ID = WOWF.WorkOrderPartNoId
                JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
            WHERE WOP.MasterCompanyId = @MasterCompanyId AND ISNULL(WO.IsDeleted, 0) = 0 AND ISNULL(WO.IsActive, 0) = 1 AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive, 0) = 1 AND CAST(WO.OpenDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)
        ) A
        GROUP BY WorkOrderId;
 

        SELECT 
        @TotalMiscCost = ISNULL(SUM(WOC.Quantity * WOC.UnitCost), 0)
            FROM WorkOrderCharges WOC  WITH (NOLOCK) 
            JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOC.WorkFlowWorkOrderId
            JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOWF.WorkOrderId
            WHERE WOC.MasterCompanyId = @MasterCompanyId AND ISNULL(WO.IsDeleted, 0) = 0 AND ISNULL(WO.IsActive, 0) = 1 AND ISNULL(WOC.IsDeleted, 0) = 0 AND ISNULL(WOC.IsActive, 0) = 1 AND CAST(WO.OpenDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)

        SELECT 
            @TotalOtherCost = ISNULL(SUM(WOF.Amount), 0)
            FROM WorkOrderFreight WOF WITH (NOLOCK) 
            JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOF.WorkFlowWorkOrderId
            JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOWF.WorkOrderId
            WHERE WOF.MasterCompanyId = @MasterCompanyId AND ISNULL(WO.IsDeleted, 0) = 0 AND ISNULL(WO.IsActive, 0) = 1 AND ISNULL(WOF.IsDeleted, 0) = 0 AND ISNULL(WOF.IsActive, 0) = 1 AND CAST(WO.OpenDate AS DATE)
            BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)


        INSERT INTO #tmpWorkOrderTotalCost (TotalPartsCost,TotalDirectLaborCost, TotalOHCost,TotalMiscCost,TotalOtherCost,TotalUnpostedDirectLaborCost,TotalUnpostedOverheadCost)
        SELECT MAX(TotalPartsCost) AS TotalPartsCost, 0, 0, @TotalMiscCost AS TotalMiscCost,  @TotalOtherCost AS TotalMiscCost,0, 0 FROM #tmpWorkOrderPartsCost;

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