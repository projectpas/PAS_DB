
/*************************************************************
 ** File:   [USP_PublicApi_GetPurchaseOrderFreight]
 ** Author: Bhargav Saliya
 ** Description: Freight lines of the POs on one page (@PurchaseOrderIds: comma separated), in line order.
 **              Same rows as dbo.GetPurchaseOrderFreightList (PAS PO Freight tab).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/purchaseorders (freight)
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetPurchaseOrderFreight] @MasterCompanyId = 1, @PurchaseOrderIds = '18768'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetPurchaseOrderFreight]
    @MasterCompanyId  INT,
    @PurchaseOrderIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            F.[PurchaseOrderId],   -- used by the API to attach the freight; not returned to clients
            F.[LineNum] AS [LineNumber],
            NULLIF(LTRIM(RTRIM(F.[PartNumber])), '') AS [PartNumber],
            NULLIF(LTRIM(RTRIM(F.[Manufacturer])), '') AS [Manufacturer],
            NULLIF(LTRIM(RTRIM(F.[ShipViaName])), '') AS [ShipVia],
            NULLIF(NULLIF(LTRIM(RTRIM(F.[Weight])), ''), '0') AS [Weight],
            NULLIF(LTRIM(RTRIM(F.[UOMName])), '') AS [WeightUnit],
            NULLIF(F.[Length], 0) AS [Length],
            NULLIF(F.[Width], 0) AS [Width],
            NULLIF(F.[Height], 0) AS [Height],
            NULLIF(LTRIM(RTRIM(F.[DimensionUOMName])), '') AS [DimensionUnit],
            NULLIF(LTRIM(RTRIM(F.[CurrencyName])), '') AS [Currency],
            ISNULL(F.[Amount], 0) AS [Amount],
            NULLIF(LTRIM(RTRIM(F.[Memo])), '') AS [Memo]
        FROM [dbo].[PurchaseOrderFreight] F WITH (NOLOCK)
        INNER JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON PO.[PurchaseOrderId] = F.[PurchaseOrderId] AND PO.[MasterCompanyId] = @MasterCompanyId
        WHERE F.[PurchaseOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@PurchaseOrderIds, ','))
          AND ISNULL(F.[IsDeleted], 0) = 0
        ORDER BY F.[PurchaseOrderId], F.[LineNum], F.[PurchaseOrderFreightId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetPurchaseOrderFreight'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PurchaseOrderIds, '') AS VARCHAR(100))
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