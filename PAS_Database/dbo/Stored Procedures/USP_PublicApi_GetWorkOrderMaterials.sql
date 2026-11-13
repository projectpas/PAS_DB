
/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderMaterials]
 ** Author: Moin Bloch
 ** Description: 4.15 Materials of the parts of the WOs on one page: regular materials and kit materials (KitNumber set).
 **              Quantities and unit cost in the item's consume UOM (stored in its stock UOM; non-stock items use
 **              the purchase UOM), as on the PAS material list. ExtendedCost is returned as stored.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorders (parts[].materials)
 ** Date:   12/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    12/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetWorkOrderMaterials] @MasterCompanyId = 1, @WorkOrderIds = '690'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderMaterials]
    @MasterCompanyId INT,
    @WorkOrderIds    VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Materials AS
    (
        SELECT CAST(0 AS BIT) AS [IsKit], M.[WorkOrderMaterialsId] AS [MaterialId], NULL AS [KitNumber],
               M.[WorkOrderId], M.[WorkFlowWorkOrderId], M.[ItemMasterId], M.[ConditionCodeId], M.[TaskId], M.[ProvisionId],
               M.[MaterialMandatoriesId], M.[ItemClassificationId], M.[Quantity], M.[QuantityReserved], M.[QuantityIssued],
               M.[UnitCost], M.[ExtendedCost], M.[IsDeferred], M.[IsAltPart], M.[IsEquPart], M.[PONum], M.[QtyOnOrder]
        FROM [dbo].[WorkOrderMaterials] M WITH (NOLOCK)
        WHERE M.[WorkOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderIds, ',')) AND M.[IsDeleted] = 0
        UNION ALL
        SELECT CAST(1 AS BIT), K.[WorkOrderMaterialsKitId], KM.[KitNumber],
               K.[WorkOrderId], K.[WorkFlowWorkOrderId], K.[ItemMasterId], K.[ConditionCodeId], K.[TaskId], K.[ProvisionId],
               K.[MaterialMandatoriesId], K.[ItemClassificationId], K.[Quantity], K.[QuantityReserved], K.[QuantityIssued],
               K.[UnitCost], K.[ExtendedCost], K.[IsDeferred], K.[IsAltPart], K.[IsEquPart], K.[PONum], K.[QtyOnOrder]
        FROM [dbo].[WorkOrderMaterialsKit] K WITH (NOLOCK)
        LEFT JOIN [dbo].[WorkOrderMaterialsKitMapping] KM WITH (NOLOCK) ON KM.[WorkOrderMaterialsKitMappingId] = K.[WorkOrderMaterialsKitMappingId]
        WHERE K.[WorkOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderIds, ',')) AND K.[IsDeleted] = 0
    )
    SELECT
        -- Ids are used by the API to attach materials to their part and stocklines to their material; not returned to clients.
        WF.[WorkOrderPartNoId] AS [WorkOrderPartNumberId],
        M.[IsKit],
        M.[MaterialId],
        M.[KitNumber],
        IM.[partnumber] AS [PartNumber],
        IM.[PartDescription],
        IM.[ManufacturerName] AS [Manufacturer],
        IC.[Description] AS [ItemClassification],
        CD.[Description] AS [Condition],
        CASE WHEN ISNULL(WO.[WorkOrderFormTypeId], 0) = 1 THEN WOT.[TaskName] ELSE T.[Description] END AS [Task],
        PR.[Description] AS [Provision],
        MM.[Name] AS [MandatoryOrSupplemental],
        CAST(ISNULL(M.[IsDeferred], 0) AS BIT) AS [IsDeferred],
        CAST(ISNULL(M.[IsAltPart], 0) AS BIT) AS [IsAltPart],
        CAST(ISNULL(M.[IsEquPart], 0) AS BIT) AS [IsEquPart],
        U.[ToUOM] AS [UnitOfMeasure],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(M.[Quantity], 0), U.[FromUOM], U.[ToUOM], 0, WO.[MasterCompanyId]) AS [QuantityRequired],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(M.[QuantityReserved], 0), U.[FromUOM], U.[ToUOM], 0, WO.[MasterCompanyId]) AS [QuantityReserved],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(M.[QuantityIssued], 0), U.[FromUOM], U.[ToUOM], 0, WO.[MasterCompanyId]) AS [QuantityIssued],
        [dbo].[fn_PublicApi_ConvertUOM](ISNULL(M.[QtyOnOrder], 0), U.[FromUOM], U.[ToUOM], 0, WO.[MasterCompanyId]) AS [QuantityOnOrder],
        [dbo].[fn_PublicApi_ConvertUOM](M.[UnitCost], U.[FromUOM], U.[ToUOM], 1, WO.[MasterCompanyId]) AS [UnitCost],
        M.[ExtendedCost],
        M.[PONum] AS [PurchaseOrderNumber]
    FROM Materials M
    INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK)
        ON WO.[WorkOrderId] = M.[WorkOrderId] AND WO.[MasterCompanyId] = @MasterCompanyId AND WO.[IsDeleted] = 0
    INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH (NOLOCK) ON WF.[WorkFlowWorkOrderId] = M.[WorkFlowWorkOrderId]
    LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = M.[ItemMasterId]
    LEFT JOIN [dbo].[ItemClassification] IC WITH (NOLOCK) ON IC.[ItemClassificationId] = M.[ItemClassificationId]
    LEFT JOIN [dbo].[Condition] CD WITH (NOLOCK) ON CD.[ConditionId] = M.[ConditionCodeId]
    LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.[TaskId] = M.[TaskId]
    LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.[WorkOrderTaskId] = M.[TaskId]
    LEFT JOIN [dbo].[Provision] PR WITH (NOLOCK) ON PR.[ProvisionId] = M.[ProvisionId]
    LEFT JOIN [dbo].[MaterialMandatories] MM WITH (NOLOCK) ON MM.[Id] = M.[MaterialMandatoriesId]
    -- Same UOMs as the PAS material list: non-stock items use the purchase UOM.
    CROSS APPLY (SELECT CASE WHEN ISNULL(IM.[IsNonStock], 0) = 1 THEN IM.[PurchaseUnitOfMeasure] ELSE IM.[StockUnitOfMeasure] END AS [FromUOM],
                        CASE WHEN ISNULL(IM.[IsNonStock], 0) = 1 THEN IM.[PurchaseUnitOfMeasure] ELSE IM.[ConsumeUnitOfMeasure] END AS [ToUOM]) U
    ORDER BY WF.[WorkOrderPartNoId], M.[IsKit], M.[KitNumber], M.[MaterialId];
END