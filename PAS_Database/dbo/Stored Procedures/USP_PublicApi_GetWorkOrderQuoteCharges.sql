
/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderQuoteCharges]
 ** Author: Moin Bloch
 ** Description: 4.27 Charge lines of the quoted parts of the quotes on one page, as on the PAS quote Charges tab
 **              (USP_GetWorkOrderQuoteChargesDetails).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorderquotes (MPN[].charges)
 ** Date:   18/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    18/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetWorkOrderQuoteCharges] @MasterCompanyId = 1, @WorkOrderQuoteIds = '1'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderQuoteCharges]
    @MasterCompanyId   INT,
    @WorkOrderQuoteIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            C.[WorkOrderQuoteDetailsId],   -- used by the API to attach the charge to its quoted part; not returned to clients
            CASE WHEN ISNULL(WO.[WorkOrderFormTypeId], 0) = 1 THEN
                     CASE WHEN ISNULL(DUP.[TaskCount], 0) > 1 AND ISNULL(WOT.[SequenceNumber], '') <> '' THEN WOT.[SequenceNumber] + ' - ' + WOT.[TaskName] ELSE WOT.[TaskName] END
                 ELSE NULLIF(T.[Description], '') END AS [Task],
            CT.[ChargeType],
            NULLIF(LTRIM(RTRIM(C.[Description])), '') AS [Description],
            V.[VendorName] AS [Vendor],
            NULLIF(LTRIM(RTRIM(C.[RefNum])), '') AS [ReferenceNumber],
            UOM.[ShortName] AS [UnitOfMeasure],
            ISNULL(C.[Quantity], 0) AS [Quantity],
            C.[UnitCost],
            C.[ExtendedCost],
            REPLACE(BM.[Description], 'Flate Rate', 'Flat Rate') AS [BillingMethod],   -- PAS stores 'Flate Rate'
            C.[BillingRate],
            C.[BillingAmount]
        FROM [dbo].[WorkOrderQuoteCharges] C WITH (NOLOCK)
        INNER JOIN [dbo].[WorkOrderQuoteDetails] D WITH (NOLOCK) ON D.[WorkOrderQuoteDetailsId] = C.[WorkOrderQuoteDetailsId]
        INNER JOIN [dbo].[WorkOrderQuote] Q WITH (NOLOCK)
            ON Q.[WorkOrderQuoteId] = D.[WorkOrderQuoteId] AND Q.[MasterCompanyId] = @MasterCompanyId AND ISNULL(Q.[IsDeleted], 0) = 0
        INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.[WorkOrderId] = Q.[WorkOrderId]
        INNER JOIN [dbo].[Charge] CT WITH (NOLOCK) ON CT.[ChargeId] = C.[ChargesTypeId]
        LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.[VendorId] = C.[VendorId]
        LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.[TaskId] = C.[TaskId]
        LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.[WorkOrderTaskId] = C.[TaskId]
        -- Same task more than once on the part: prefix the sequence number (as PAS).
        OUTER APPLY (SELECT COUNT(1) AS [TaskCount] FROM [dbo].[WorkOrderTask] X WITH (NOLOCK)
                     WHERE X.[TaskId] = WOT.[TaskId] AND X.[WorkOrderId] = Q.[WorkOrderId] AND X.[WorkOrderPartNumberId] = D.[WOPartNoId]
                       AND X.[IsActive] = 1 AND X.[IsDeleted] = 0) DUP
        LEFT JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.[UnitOfMeasureId] = C.[UOMId]
        LEFT JOIN [dbo].[BillingMethod] BM WITH (NOLOCK) ON BM.[BillingMethodId] = C.[BillingMethodId]
        WHERE D.[WorkOrderQuoteId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderQuoteIds, ','))
          AND ISNULL(D.[IsDeleted], 0) = 0
          AND ISNULL(D.[IsActive], 1) = 1
          AND C.[IsDeleted] = 0
        ORDER BY C.[WorkOrderQuoteDetailsId], C.[WorkOrderQuoteChargesId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetWorkOrderQuoteCharges'
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