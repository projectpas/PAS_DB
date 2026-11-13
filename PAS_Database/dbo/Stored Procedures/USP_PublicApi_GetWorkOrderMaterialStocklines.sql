
/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderMaterialStocklines]
 ** Author: Moin Bloch
 ** Description: 4.16 Stocklines reserved / issued for the materials of the WOs on one page (regular and kit materials).
 **              Quantities and unit cost in the stockline's consume UOM (stored in its stock UOM). ExtendedCost as stored.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorders (parts[].materials[].stocklines)
 ** Date:   12/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    12/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetWorkOrderMaterialStocklines] @MasterCompanyId = 1, @WorkOrderIds = '690'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderMaterialStocklines]
    @MasterCompanyId INT,
    @WorkOrderIds    VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Stock AS
    (
        SELECT CAST(0 AS BIT) AS [IsKit], S.[WorkOrderMaterialsId] AS [MaterialId], S.[WOMStockLineId] AS [RowId], M.[WorkOrderId],
               S.[StockLineId], S.[ConditionId], S.[ProvisionId], S.[Quantity], S.[QtyReserved], S.[QtyIssued], S.[QuantityTurnIn],
               S.[UnitCost], S.[ExtendedCost]
        FROM [dbo].[WorkOrderMaterialStockLine] S WITH (NOLOCK)
        INNER JOIN [dbo].[WorkOrderMaterials] M WITH (NOLOCK) ON M.[WorkOrderMaterialsId] = S.[WorkOrderMaterialsId] AND M.[IsDeleted] = 0
        WHERE M.[WorkOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderIds, ',')) AND S.[IsDeleted] = 0 AND S.[IsActive] = 1
        UNION ALL
        SELECT CAST(1 AS BIT), S.[WorkOrderMaterialsKitId], S.[WorkOrderMaterialStockLineKitId], K.[WorkOrderId],
               S.[StockLineId], S.[ConditionId], S.[ProvisionId], S.[Quantity], S.[QtyReserved], S.[QtyIssued], S.[QuantityTurnIn],
               S.[UnitCost], S.[ExtendedCost]
        FROM [dbo].[WorkOrderMaterialStockLineKit] S WITH (NOLOCK)
        INNER JOIN [dbo].[WorkOrderMaterialsKit] K WITH (NOLOCK) ON K.[WorkOrderMaterialsKitId] = S.[WorkOrderMaterialsKitId] AND K.[IsDeleted] = 0
        WHERE K.[WorkOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderIds, ',')) AND S.[IsDeleted] = 0 AND S.[IsActive] = 1
    )
    SELECT
        -- Ids are used by the API to attach the stockline to its material; not returned to clients.
        S.[IsKit],
        S.[MaterialId],
        SL.[StockLineNumber],
        SL.[ControlNumber],
        SL.[IdNumber],
        SL.[SerialNumber],
        ISNULL(CD.[Description], SL.[Condition]) AS [Condition],
        PR.[Description] AS [Provision],
        U.[ToUOM] AS [UnitOfMeasure],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(S.[Quantity], 0), U.[FromUOM], U.[ToUOM], 0, WO.[MasterCompanyId]) AS [Quantity],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(S.[QtyReserved], 0), U.[FromUOM], U.[ToUOM], 0, WO.[MasterCompanyId]) AS [QuantityReserved],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(S.[QtyIssued], 0), U.[FromUOM], U.[ToUOM], 0, WO.[MasterCompanyId]) AS [QuantityIssued],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(S.[QuantityTurnIn], 0), U.[FromUOM], U.[ToUOM], 0, WO.[MasterCompanyId]) AS [QuantityTurnIn],
        [dbo].[fn_PublicApi_ConvertUOM](S.[UnitCost], U.[FromUOM], U.[ToUOM], 1, WO.[MasterCompanyId]) AS [UnitCost],
        S.[ExtendedCost],
        SL.[ReceiverNumber],
        SL.[Site],
        SL.[Warehouse],
        SL.[Location],
        SL.[Shelf],
        SL.[Bin]
    FROM Stock S
    INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK)
        ON WO.[WorkOrderId] = S.[WorkOrderId] AND WO.[MasterCompanyId] = @MasterCompanyId AND WO.[IsDeleted] = 0
    LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.[StockLineId] = S.[StockLineId]
    LEFT JOIN [dbo].[Condition] CD WITH (NOLOCK) ON CD.[ConditionId] = S.[ConditionId]
    LEFT JOIN [dbo].[Provision] PR WITH (NOLOCK) ON PR.[ProvisionId] = S.[ProvisionId]
    -- Older stocklines have no stock / consume UOM yet; their quantity is in Stockline.UnitOfMeasure.
    CROSS APPLY (SELECT ISNULL(NULLIF(SL.[StockUnitOfMeasure], ''), NULLIF(SL.[UnitOfMeasure], '')) AS [FromUOM]) F
    CROSS APPLY (SELECT F.[FromUOM], ISNULL(NULLIF(SL.[ConsumeUnitOfMeasure], ''), F.[FromUOM]) AS [ToUOM]) U
    ORDER BY S.[IsKit], S.[MaterialId], S.[RowId];
END