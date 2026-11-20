
/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderQuoteMaterials]
 ** Author: Moin Bloch
 ** Description: 4.25 Materials of the quoted parts of the quotes on one page, as on the PAS quote Materials tab
 **              (USP_GetWorkOrderQuoteMaterial): regular materials and one line per kit. Quantity and unit cost in the
 **              consume UOM; extended cost = quantity x unit cost; billing rate / amount = cost + markup %.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorderquotes (MPN[].materials)
 ** Date:   18/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    18/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetWorkOrderQuoteMaterials] @MasterCompanyId = 1, @WorkOrderQuoteIds = '1'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderQuoteMaterials]
    @MasterCompanyId   INT,
    @WorkOrderQuoteIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        ;WITH Materials AS
        (
            SELECT M.[WorkOrderQuoteDetailsId], CAST(0 AS BIT) AS [IsKit], M.[WorkOrderQuoteMaterialId] AS [MaterialId],
                   CAST(NULL AS VARCHAR(100)) AS [KitNumber], CAST(NULL AS VARCHAR(500)) AS [KitDescription],
                   M.[ItemMasterId], M.[ConditionCodeId], M.[ItemClassificationId], M.[TaskId], M.[ProvisionId],
                   M.[MaterialMandatoriesId], M.[IsDefered], M.[Quantity], M.[UnitCost], M.[MarkupPercentageId], M.[BillingMethodId]
            FROM [dbo].[WorkOrderQuoteMaterial] M WITH (NOLOCK)
            INNER JOIN [dbo].[WorkOrderQuoteDetails] D WITH (NOLOCK) ON D.[WorkOrderQuoteDetailsId] = M.[WorkOrderQuoteDetailsId]
            WHERE D.[WorkOrderQuoteId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderQuoteIds, ','))
              AND M.[IsDeleted] = 0
            UNION ALL
            -- Kits belong to the quoted part with the same quote and workflow (as in PAS).
            SELECT D.[WorkOrderQuoteDetailsId], CAST(1 AS BIT), K.[WOQMaterialKitMappingId],
                   K.[KitNumber], KM.[KitDescription],
                   K.[ItemMasterId], NULL, NULL, K.[TaskId], NULL,
                   NULL, CAST(0 AS BIT), K.[Quantity], K.[UnitCost], K.[MarkupPercentageId], K.[BillingMethodId]
            FROM [dbo].[WorkOrderQuoteMaterialKitMapping] K WITH (NOLOCK)
            INNER JOIN [dbo].[WorkOrderQuoteDetails] D WITH (NOLOCK)
                ON D.[WorkOrderQuoteId] = K.[WorkOrderQuoteId] AND D.[WorkflowWorkOrderId] = K.[WorkflowWorkOrderId]
            LEFT JOIN [dbo].[KitMaster] KM WITH (NOLOCK) ON KM.[KitId] = K.[KitId]
            WHERE K.[WorkOrderQuoteId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderQuoteIds, ','))
              AND K.[IsDeleted] = 0
        )
        SELECT
            -- Ids are used by the API to attach the material to its quoted part; not returned to clients.
            M.[WorkOrderQuoteDetailsId],
            M.[IsKit],
            M.[MaterialId],
            M.[KitNumber],
            CASE WHEN M.[IsKit] = 1 THEN M.[KitNumber] ELSE IM.[partnumber] END AS [PartNumber],
            CASE WHEN M.[IsKit] = 1 THEN M.[KitDescription] ELSE IM.[PartDescription] END AS [PartDescription],
            CASE WHEN M.[IsKit] = 1 THEN NULL ELSE IM.[ManufacturerName] END AS [Manufacturer],
            IC.[Description] AS [ItemClassification],
            CD.[Description] AS [Condition],
            CASE WHEN ISNULL(WO.[WorkOrderFormTypeId], 0) = 1
                 THEN CASE WHEN ISNULL(WOT.[SequenceNumber], '') <> '' THEN WOT.[SequenceNumber] + ' - ' + WOT.[TaskName] ELSE WOT.[TaskName] END
                 ELSE T.[Description] END AS [Task],
            PR.[Description] AS [Provision],
            MM.[Name] AS [MandatoryOrSupplemental],
            CASE WHEN M.[IsKit] = 1 THEN NULL
                 WHEN IM.[IsPma] = 1 AND IM.[IsDER] = 1 THEN 'PMA&DER'
                 WHEN IM.[IsPma] = 1 THEN 'PMA'
                 WHEN IM.[IsDER] = 1 THEN 'DER'
                 ELSE 'OEM' END AS [StockType],
            CAST(ISNULL(M.[IsDefered], 0) AS BIT) AS [IsDeferred],
            CASE WHEN M.[IsKit] = 1 THEN NULL ELSE U.[ToUOM] END AS [UnitOfMeasure],
            A.[Quantity],
            A.[UnitCost],
            A.[Quantity] * A.[UnitCost] AS [ExtendedCost],
            PCT.[PercentValue] AS [MarkupPercent],
            REPLACE(BM.[Description], 'Flate Rate', 'Flat Rate') AS [BillingMethod],   -- PAS stores 'Flate Rate'
            A.[UnitCost] + A.[UnitCost] * ISNULL(PCT.[PercentValue], 0) / 100 AS [BillingRate],
            A.[Quantity] * A.[UnitCost] + A.[Quantity] * A.[UnitCost] * ISNULL(PCT.[PercentValue], 0) / 100 AS [BillingAmount]
        FROM Materials M
        INNER JOIN [dbo].[WorkOrderQuoteDetails] D WITH (NOLOCK) ON D.[WorkOrderQuoteDetailsId] = M.[WorkOrderQuoteDetailsId]
        INNER JOIN [dbo].[WorkOrderQuote] Q WITH (NOLOCK)
            ON Q.[WorkOrderQuoteId] = D.[WorkOrderQuoteId] AND Q.[MasterCompanyId] = @MasterCompanyId AND ISNULL(Q.[IsDeleted], 0) = 0
        INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.[WorkOrderId] = Q.[WorkOrderId]
        INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH (NOLOCK) ON WF.[WorkFlowWorkOrderId] = D.[WorkflowWorkOrderId]
        INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOP.[ID] = WF.[WorkOrderPartNoId]
        INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = M.[ItemMasterId]
        LEFT JOIN [dbo].[ItemClassification] IC WITH (NOLOCK)
            ON IC.[ItemClassificationId] = CASE WHEN M.[IsKit] = 1 THEN IM.[ItemClassificationId] ELSE M.[ItemClassificationId] END
        LEFT JOIN [dbo].[Condition] CD WITH (NOLOCK) ON CD.[ConditionId] = M.[ConditionCodeId]
        LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.[TaskId] = M.[TaskId]
        LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.[WorkOrderTaskId] = M.[TaskId]
        LEFT JOIN [dbo].[Provision] PR WITH (NOLOCK)
            ON PR.[ProvisionId] = CASE WHEN M.[IsKit] = 1 THEN IM.[ProvisionId] ELSE M.[ProvisionId] END
        LEFT JOIN [dbo].[MaterialMandatories] MM WITH (NOLOCK) ON MM.[Id] = M.[MaterialMandatoriesId]
        LEFT JOIN [dbo].[Percent] PCT WITH (NOLOCK) ON PCT.[PercentId] = M.[MarkupPercentageId]
        LEFT JOIN [dbo].[BillingMethod] BM WITH (NOLOCK) ON BM.[BillingMethodId] = M.[BillingMethodId]
        -- Same UOMs as the PAS material list: non-stock items use the purchase UOM.
        CROSS APPLY (SELECT CASE WHEN ISNULL(IM.[IsNonStock], 0) = 1 THEN IM.[PurchaseUnitOfMeasure] ELSE IM.[StockUnitOfMeasure] END AS [FromUOM],
                            CASE WHEN ISNULL(IM.[IsNonStock], 0) = 1 THEN IM.[PurchaseUnitOfMeasure] ELSE IM.[ConsumeUnitOfMeasure] END AS [ToUOM]) U
        CROSS APPLY (SELECT [dbo].[fn_PublicApi_ConvertUOM](ISNULL(M.[Quantity], 0), U.[FromUOM], U.[ToUOM], 0, Q.[MasterCompanyId]) AS [Quantity],
                            [dbo].[fn_PublicApi_ConvertUOM](ISNULL(M.[UnitCost], 0), U.[FromUOM], U.[ToUOM], 1, Q.[MasterCompanyId]) AS [UnitCost]) A
        WHERE ISNULL(D.[IsDeleted], 0) = 0 AND ISNULL(D.[IsActive], 1) = 1
        ORDER BY M.[WorkOrderQuoteDetailsId], M.[IsKit], M.[MaterialId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetWorkOrderQuoteMaterials'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderQuoteIds, '') AS VARCHAR(100))
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