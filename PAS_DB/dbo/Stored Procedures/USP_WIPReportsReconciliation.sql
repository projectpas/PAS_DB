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
	2    24/02/2026   Hemant Saliya       Corrected balance missmatch for WIP
	3    26/02/2026   Priyansh Patel      Added IsAccountByPass condition
	4    30/04/2026   Hemant Saliya       Corrected balance missmatch for WIP Labor

exec USP_WIPReportsReconciliation @mastercompanyid=21,@id='2026-01-01 00:00:00',@id2='2026-04-30 00:00:00',@id3=''

*************************************************************/   
CREATE PROCEDURE [dbo].[USP_WIPReportsReconciliation] 	
    @mastercompanyid INT,
    @id VARCHAR(MAX),
    @id2 VARCHAR(MAX),
    @id3 BIGINT = NULL
AS  
BEGIN  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
    SET NOCOUNT ON;  
    BEGIN TRY

        DECLARE @FromDate   DATETIME = TRY_CAST(@id  AS DATETIME)
        DECLARE @ToDate     DATETIME = TRY_CAST(@id2 AS DATETIME)

        IF @id3 = 0 SET @id3 = NULL

        -- =============================================
        -- Lookup IDs in a single pass per table
        -- =============================================
        DECLARE @WIPMaterialCategoryId    INT,
                @WIPDirectLaborCategoryId INT,
                @WIPOverheadCategoryId    INT,
                @WorkOrderModuleId        INT = 15,
                @InvoiceStatusId          INT = 3,
                @PostedStatusId           INT,
                @OpenStatusId             INT,
                @IsShowReconcile          BIT = 0,
                @TaskStatus               VARCHAR(20) = 'COMPLETED';

        -- Batch single-row lookups together
        SELECT 
            @PostedStatusId = MAX(CASE WHEN [Name] = 'POSTED' THEN Id END),
            @OpenStatusId   = MAX(CASE WHEN [Name] = 'OPEN'   THEN Id END)
        FROM [dbo].[BatchStatus] WITH (NOLOCK)
        WHERE [Name] IN ('POSTED', 'OPEN')
          AND ISNULL(IsDeleted, 0) = 0
          AND ISNULL(IsActive,  0) = 1;

        SELECT 
            @WIPMaterialCategoryId    = MAX(CASE WHEN WIPCategory = 'WIP Material'      THEN WIPCategoryId END),
            @WIPDirectLaborCategoryId = MAX(CASE WHEN WIPCategory = 'WIP Direct Labor'  THEN WIPCategoryId END),
            @WIPOverheadCategoryId    = MAX(CASE WHEN WIPCategory = 'WIP Overhead'      THEN WIPCategoryId END)
        FROM [dbo].[WIPCategory] WITH (NOLOCK)
        WHERE WIPCategory IN ('WIP Material', 'WIP Direct Labor', 'WIP Overhead')
          AND ISNULL(IsDeleted, 0) = 0
          AND ISNULL(IsActive,  0) = 1
          AND MasterCompanyId = @mastercompanyid;

        SELECT @IsShowReconcile = CASE WHEN ISNULL(IsAccountByPass, 0) = 0 THEN 1 ELSE 0 END
        FROM [dbo].[MasterCompany] WITH (NOLOCK)
        WHERE MasterCompanyId = @mastercompanyid
          AND ISNULL(IsActive,  0) = 1
          AND ISNULL(IsDeleted, 0) = 0;

        -- =============================================
        -- Temp table: Eligible Work Orders
        -- =============================================
        IF OBJECT_ID('tempdb..#tmpWO') IS NOT NULL DROP TABLE #tmpWO;

        -- Use NOT EXISTS instead of LEFT JOIN + IS NULL (better performance)
        SELECT DISTINCT WOP.WorkOrderId  -- DISTINCT guards against multiple WOP rows per WO
        INTO #tmpWO
        FROM [dbo].[WorkOrder] WO WITH (NOLOCK)
        JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) 
            ON WOP.WorkOrderId = WO.WorkOrderId
           AND ISNULL(WOP.IsClosed, 0) = 0
        WHERE WO.MasterCompanyId   = @mastercompanyid
          AND ISNULL(WO.IsDeleted, 0) = 0
          AND ISNULL(WO.IsActive,  0) = 1
          AND CAST(WO.OpenDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)
          AND (@id3 IS NULL OR WOP.ItemMasterId = @id3)
          AND NOT EXISTS (                          -- replaces LEFT JOIN … IS NULL
                SELECT 1
                FROM [dbo].[BillingInvoicing] BI WITH (NOLOCK)
                WHERE BI.ReferenceId      = WOP.WorkOrderId
                  AND BI.ModuleId         = @WorkOrderModuleId
                  AND BI.InvoiceStatusId  = @InvoiceStatusId  -- billed/posted rows
          );

        CREATE CLUSTERED INDEX IX_tmpWO ON #tmpWO (WorkOrderId); -- index for downstream joins

        -- =============================================
        -- Parts Cost (materials + kits) – single CTE
        -- =============================================
        IF OBJECT_ID('tempdb..#tmpWorkOrderPartsCost') IS NOT NULL DROP TABLE #tmpWorkOrderPartsCost;

        SELECT WorkOrderId,
               SUM(PartsCost)             AS PartsCost,
               SUM(SUM(PartsCost)) OVER() AS TotalPartsCost
        INTO #tmpWorkOrderPartsCost
        FROM (
            -- Standard materials
            SELECT WO.WorkOrderId, (WOMS.QtyIssued * WOMS.UnitCost) AS PartsCost
            FROM [dbo].[WorkOrderMaterialstockline] WOMS WITH (NOLOCK)
            JOIN [dbo].[WorkOrderMaterials]   WOM  WITH (NOLOCK) ON WOM.WorkOrderMaterialsId  = WOMS.WorkOrderMaterialsId
            JOIN [dbo].[WorkOrderWorkFlow]    WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId  = WOM.WorkFlowWorkOrderId
            JOIN [dbo].[WorkOrderPartNumber]  WOP  WITH (NOLOCK) ON WOP.ID                   = WOWF.WorkOrderPartNoId
            JOIN #tmpWO                       WO                 ON WO.WorkOrderId            = WOP.WorkOrderId
            WHERE WOP.MasterCompanyId      = @mastercompanyid
              AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive,  0) = 1 AND ISNULL(WOP.IsFinishGood, 0) = 0
              AND ISNULL(WOWF.IsDeleted,0) = 0 AND ISNULL(WOWF.IsActive, 0) = 1
              AND ISNULL(WOMS.IsDeleted,0) = 0 AND ISNULL(WOMS.IsActive, 0) = 1
              AND ISNULL(WOM.IsDeleted, 0) = 0 AND ISNULL(WOM.IsActive,  0) = 1

            UNION ALL

            -- Kit materials
            SELECT WO.WorkOrderId, (WOMS.QtyIssued * WOMS.UnitCost) AS PartsCost
            FROM [dbo].[WorkOrderMaterialStocklineKit] WOMS WITH (NOLOCK)
            JOIN [dbo].[WorkOrderMaterialsKit]  WOM  WITH (NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId
            JOIN [dbo].[WorkOrderWorkFlow]      WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId    = WOM.WorkFlowWorkOrderId
            JOIN [dbo].[WorkOrderPartNumber]    WOP  WITH (NOLOCK) ON WOP.ID                     = WOWF.WorkOrderPartNoId
            JOIN #tmpWO                         WO                 ON WO.WorkOrderId              = WOP.WorkOrderId
            WHERE WOP.MasterCompanyId      = @mastercompanyid
              AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive,  0) = 1 AND ISNULL(WOP.IsFinishGood, 0) = 0
              AND ISNULL(WOWF.IsDeleted,0) = 0 AND ISNULL(WOWF.IsActive, 0) = 1
              AND ISNULL(WOMS.IsDeleted,0) = 0 AND ISNULL(WOMS.IsActive, 0) = 1
              AND ISNULL(WOM.IsDeleted, 0) = 0 AND ISNULL(WOM.IsActive,  0) = 1
        ) A
        GROUP BY WorkOrderId;

        -- =============================================
        -- Scalar aggregates – collapsed into one query
        -- each per domain (Charges, Freight, Labor)
        -- =============================================
        DECLARE @TotalOtherCost  DECIMAL(18,2) = 0,
                @TotalMiscCost   DECIMAL(18,2) = 0;

        SELECT 
            @TotalOtherCost = ISNULL(SUM(CASE WHEN src = 'C' THEN Amount ELSE 0 END), 0),
            @TotalMiscCost  = ISNULL(SUM(CASE WHEN src = 'F' THEN Amount ELSE 0 END), 0)
        FROM (
            SELECT 'C' AS src, WOC.Quantity * WOC.UnitCost AS Amount
            FROM [dbo].[WorkOrderCharges]   WOC  WITH (NOLOCK)
            JOIN [dbo].[WorkOrderWorkFlow]  WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOC.WorkFlowWorkOrderId
            JOIN #tmpWO WO ON WO.WorkOrderId = WOWF.WorkOrderId
            WHERE WOC.MasterCompanyId = @mastercompanyid
              AND ISNULL(WOC.IsDeleted,0)  = 0 AND ISNULL(WOC.IsActive,0)  = 1
              AND ISNULL(WOWF.IsDeleted,0) = 0 AND ISNULL(WOWF.IsActive,0) = 1

            UNION ALL

            SELECT 'F', WOF.Amount
            FROM [dbo].[WorkOrderFreight]  WOF  WITH (NOLOCK)
            JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOF.WorkFlowWorkOrderId
            JOIN #tmpWO WO ON WO.WorkOrderId = WOWF.WorkOrderId
            WHERE WOF.MasterCompanyId = @mastercompanyid
              AND ISNULL(WOF.IsDeleted,0)  = 0 AND ISNULL(WOF.IsActive,0)  = 1
              AND ISNULL(WOWF.IsDeleted,0) = 0 AND ISNULL(WOWF.IsActive,0) = 1
        ) X;

        DECLARE @TotalDirectLaborCost DECIMAL(18,2) = 0,
                @TotalOHCost          DECIMAL(18,2) = 0;

        --SELECT 
        --    @TotalDirectLaborCost = ISNULL(SUM(ISNULL(WCD.LaborCost,0) - ISNULL(WCD.OverHeadCost,0)), 0),
        --    @TotalOHCost          = ISNULL(SUM(WCD.OverHeadCost), 0)
        --FROM [dbo].[WorkOrderCostDetails] WCD WITH (NOLOCK)
        --JOIN #tmpWO WO ON WO.WorkOrderId = WCD.WorkOrderId
        --WHERE WCD.MasterCompanyId = @mastercompanyid
        --  AND ISNULL(WCD.IsDeleted,0) = 0
        --  AND ISNULL(WCD.IsActive, 0) = 1;

        -- =============================================
        -- Unposted labor / overhead
        -- =============================================
        DECLARE @TotalUnpostedDirectLaborCost DECIMAL(18,2) = 0,
                @TotalUnpostedOverheadCost    DECIMAL(18,2) = 0;

        SELECT 
            @TotalUnpostedDirectLaborCost = SUM(
                WOL.DirectLaborOHCost * (
                    (CASE WHEN WOL.AdjustedHours < 0 THEN -1 ELSE 1 END
                     * (FLOOR(ABS(WOL.AdjustedHours)) * 60
                        + CONVERT(INT, ROUND((ABS(WOL.AdjustedHours) - FLOOR(ABS(WOL.AdjustedHours))) * 100.0, 0)))
                    ) / 60.0)),
            @TotalUnpostedOverheadCost = SUM(
                WOL.BurdenRateAmount * (
                    (CASE WHEN WOL.AdjustedHours < 0 THEN -1 ELSE 1 END
                     * (FLOOR(ABS(WOL.AdjustedHours)) * 60
                        + CONVERT(INT, ROUND((ABS(WOL.AdjustedHours) - FLOOR(ABS(WOL.AdjustedHours))) * 100.0, 0)))
                    ) / 60.0))
        FROM [dbo].[WorkOrderPartNumber]    WOP  WITH (NOLOCK)
        JOIN #tmpWO                         WO                 ON WO.WorkOrderId              = WOP.WorkOrderId
        JOIN [dbo].[WorkOrderWorkFlow]      WOWF WITH (NOLOCK) ON WOWF.WorkOrderPartNoId      = WOP.ID
                                                               AND ISNULL(WOWF.IsActive,0)    = 1
                                                               AND ISNULL(WOWF.IsDeleted,0)   = 0
        JOIN [dbo].[WorkOrderLaborHeader]   WOLH WITH (NOLOCK) ON WOLH.WorkFlowWorkOrderId    = WOWF.WorkFlowWorkOrderId
                                                               AND ISNULL(WOLH.IsActive,0)    = 1
                                                               AND ISNULL(WOLH.IsDeleted,0)   = 0
        JOIN [dbo].[WorkOrderLabor]         WOL  WITH (NOLOCK) ON WOL.WorkOrderLaborHeaderId  = WOLH.WorkOrderLaborHeaderId
        JOIN [dbo].[TaskStatus]             TS   WITH (NOLOCK) ON TS.TaskStatusId             = WOL.TaskStatusId
                                                               AND (TS.StatusCode IS NULL OR TS.StatusCode <> @TaskStatus)
                                                               AND TS.IsActive  = 1
                                                               AND TS.IsDeleted = 0
        WHERE ISNULL(WOL.IsDeleted,0) = 0
          AND ISNULL(WOL.IsActive, 0) = 1;

        -- =============================================
        -- GL Aggregates – all 6 buckets in ONE query
        -- =============================================
        DECLARE @TotalWIPMaterialWIPPostedGL   DECIMAL(18,2) = 0,
                @TotalWIPMaterialWIPUnpostedGL DECIMAL(18,2) = 0,
                @TotalDirectLaborPostedGL      DECIMAL(18,2) = 0,
                @TotalDirectLaborUnpostedGL    DECIMAL(18,2) = 0,
                @TotalWIPOverheadPostedGL      DECIMAL(18,2) = 0,
                @TotalWIPOverheadUnPostedGL    DECIMAL(18,2) = 0;

        SELECT
            @TotalWIPMaterialWIPPostedGL   = SUM(CASE WHEN BD.StatusId = @PostedStatusId AND WIP.WIPCategoryId = @WIPMaterialCategoryId    THEN ISNULL(CBD.DebitAmount,0) - ISNULL(CBD.CreditAmount,0) ELSE 0 END),
            @TotalWIPMaterialWIPUnpostedGL = SUM(CASE WHEN BD.StatusId = @OpenStatusId   AND WIP.WIPCategoryId = @WIPMaterialCategoryId    THEN ISNULL(CBD.DebitAmount,0) - ISNULL(CBD.CreditAmount,0) ELSE 0 END),
            @TotalDirectLaborPostedGL      = SUM(CASE WHEN BD.StatusId = @PostedStatusId AND WIP.WIPCategoryId = @WIPDirectLaborCategoryId THEN ISNULL(CBD.DebitAmount,0) - ISNULL(CBD.CreditAmount,0) ELSE 0 END),
            @TotalDirectLaborUnpostedGL    = SUM(CASE WHEN BD.StatusId = @OpenStatusId   AND WIP.WIPCategoryId = @WIPDirectLaborCategoryId THEN ISNULL(CBD.DebitAmount,0) - ISNULL(CBD.CreditAmount,0) ELSE 0 END),
            @TotalWIPOverheadPostedGL      = SUM(CASE WHEN BD.StatusId = @PostedStatusId AND WIP.WIPCategoryId = @WIPOverheadCategoryId    THEN ISNULL(CBD.DebitAmount,0) - ISNULL(CBD.CreditAmount,0) ELSE 0 END),
            @TotalWIPOverheadUnPostedGL    = SUM(CASE WHEN BD.StatusId = @OpenStatusId   AND WIP.WIPCategoryId = @WIPOverheadCategoryId    THEN ISNULL(CBD.DebitAmount,0) - ISNULL(CBD.CreditAmount,0) ELSE 0 END)
        FROM [dbo].[CommonBatchDetails]    CBD  WITH (NOLOCK)
        JOIN [dbo].[BatchDetails]          BD   WITH (NOLOCK) ON BD.JournalBatchDetailId		= CBD.JournalBatchDetailId
        JOIN [dbo].[WIPGLAccountSetup]     WIP  WITH (NOLOCK) ON WIP.GlAccountId				= CBD.GlAccountId
        JOIN [dbo].[WIPCategory]           WC   WITH (NOLOCK) ON WC.WIPCategoryId				= WIP.WIPCategoryId
        LEFT JOIN [dbo].[WorkOrderBatchDetails] WBD  WITH (NOLOCK) ON WBD.CommonJournalBatchDetailId = CBD.CommonJournalBatchDetailId
        LEFT JOIN [dbo].[WorkOrderPartNumber]   WOP  WITH (NOLOCK) ON WOP.ID					= WBD.MPNPartId
        WHERE WIP.MasterCompanyId = @mastercompanyid
          AND BD.StatusId   IN (@PostedStatusId, @OpenStatusId)
          AND WIP.WIPCategoryId IN (@WIPMaterialCategoryId, @WIPDirectLaborCategoryId, @WIPOverheadCategoryId)
          AND BD.IsDeleted  = 0
          AND CBD.IsDeleted = 0
          AND CAST(CBD.EntryDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)
          AND (@id3 IS NULL OR WOP.ItemMasterId = @id3);

        -- =============================================
        -- Final result set
        -- =============================================
        SELECT
            ISNULL(MAX(pc.TotalPartsCost), 0)                                        AS TotalPartsCost,
            ISNULL(@TotalDirectLaborCost, 0)                                         AS TotalDirectLaborCost,
            ISNULL(@TotalOHCost, 0)                                                  AS TotalOHCost,
            ISNULL(@TotalMiscCost, 0)                                                AS TotalMiscCost,
            ISNULL(@TotalOtherCost, 0)                                               AS TotalOtherCost,
            ISNULL(MAX(pc.TotalPartsCost), 0)
              + ISNULL(@TotalDirectLaborCost, 0)
              + ISNULL(@TotalOHCost, 0)
              + ISNULL(@TotalMiscCost, 0)
              + ISNULL(@TotalOtherCost, 0)                                           AS TotalWIPCost,
            ISNULL(@TotalUnpostedDirectLaborCost, 0)                                 AS TotalUnpostedDirectLaborCost,
            ISNULL(@TotalUnpostedOverheadCost, 0)                                    AS TotalUnpostedOverheadCost,
            ISNULL(@TotalWIPMaterialWIPPostedGL, 0)                                  AS TotalWIPMaterialWIPPostedGL,
            ISNULL(@TotalWIPMaterialWIPUnpostedGL, 0)                                AS TotalWIPMaterialWIPUnpostedGL,
            ISNULL(@TotalDirectLaborPostedGL, 0)                                     AS TotalDirectLaborPostedGL,
            ISNULL(@TotalDirectLaborUnpostedGL, 0)                                   AS TotalDirectLaborUnpostedGL,
            ISNULL(@TotalWIPOverheadPostedGL, 0)                                     AS TotalWIPOverheadPostedGL,
            ISNULL(@TotalWIPOverheadUnPostedGL, 0)                                   AS TotalWIPOverheadUnPostedGL,
            @IsShowReconcile                                                         AS IsShowReconcile
        FROM #tmpWorkOrderPartsCost pc;

    END TRY      
    BEGIN CATCH  
        DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = DB_NAME()
              , @AdhocComments      VARCHAR(150)  = 'USP_WIPReportsReconciliation'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid,'') AS VARCHAR(100))
              , @ApplicationName    VARCHAR(100)  = 'PAS';

        EXEC spLogException
              @DatabaseName        = @DatabaseName
            , @AdhocComments       = @AdhocComments
            , @ProcedureParameters = @ProcedureParameters
            , @ApplicationName     = @ApplicationName
            , @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH  
END