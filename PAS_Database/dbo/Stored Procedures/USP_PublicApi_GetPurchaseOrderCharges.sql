
/*************************************************************
 ** File:   [USP_PublicApi_GetPurchaseOrderCharges]
 ** Author: Bhargav Saliya
 ** Description: Charge lines of the POs on one page (@PurchaseOrderIds: comma separated), in line order.
 **              Same rows as dbo.GetPurchaseOrderChargesList (PAS PO Charges tab). Vendor falls back to the
 **              Vendor table when the stored VendorName is blank.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/purchaseorders (charges)
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetPurchaseOrderCharges] @MasterCompanyId = 1, @PurchaseOrderIds = '18768'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetPurchaseOrderCharges]
    @MasterCompanyId  INT,
    @PurchaseOrderIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            C.[PurchaseOrderId],   -- used by the API to attach the charges; not returned to clients
            C.[LineNum] AS [LineNumber],
            NULLIF(LTRIM(RTRIM(C.[PartNumber])), '') AS [PartNumber],
            NULLIF(LTRIM(RTRIM(C.[Manufacturer])), '') AS [Manufacturer],
            NULLIF(LTRIM(RTRIM(C.[ChargeName])), '') AS [ChargeType],
            NULLIF(LTRIM(RTRIM(C.[Description])), '') AS [Description],
            COALESCE(NULLIF(LTRIM(RTRIM(C.[VendorName])), ''), V.[VendorName]) AS [Vendor],
            NULLIF(LTRIM(RTRIM(C.[RefNum])), '') AS [ReferenceNumber],
            UOM.[ShortName] AS [UnitOfMeasure],
            ISNULL(C.[Quantity], 0) AS [Quantity],
            C.[UnitCost],
            C.[ExtendedCost]
        FROM [dbo].[PurchaseOrderCharges] C WITH (NOLOCK)
        INNER JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON PO.[PurchaseOrderId] = C.[PurchaseOrderId] AND PO.[MasterCompanyId] = @MasterCompanyId
        LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.[VendorId] = C.[VendorId]
        LEFT JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.[UnitOfMeasureId] = C.[UOMId]
        WHERE C.[PurchaseOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@PurchaseOrderIds, ','))
          AND ISNULL(C.[IsDeleted], 0) = 0
        ORDER BY C.[PurchaseOrderId], C.[LineNum], C.[PurchaseOrderChargestId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetPurchaseOrderCharges'
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