
/*************************************************************
 ** File:   [USP_PublicApi_GetPurchaseOrderList]
 ** Author: Moin Bloch
 ** Description: 4.2 GET /api/v1/purchaseorders (headers). Ship Via comes from AllShipVia (one row per PO).
 **              PartsCount / TotalPartsCost count main lines only (split shipment lines repeat the quantity).
 **              @OpenDateFrom / @OpenDateTo: open date range, both inclusive (dates only).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/purchaseorders and /api/v1/receivingpurchaseorders (headers)
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created
    2    18/11/2026   Moin Bloch    Added open date filter (@OpenDateFrom / @OpenDateTo)
    3    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetPurchaseOrderList] @MasterCompanyId = 1, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetPurchaseOrderList]
    @MasterCompanyId     INT,
    @PageNumber          INT,
    @PageSize            INT,
    @PurchaseOrderNumber VARCHAR(50) = NULL,
    @Status              VARCHAR(50) = NULL,
    @OpenDateFrom        DATE = NULL,
    @OpenDateTo          DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @ModuleId BIGINT = (SELECT TOP (1) [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'PurchaseOrder' AND [CodePrefix] = 'PO');

        ;WITH PagedPO AS
        (
            SELECT PO.[PurchaseOrderId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[PurchaseOrder] PO WITH (NOLOCK)
            WHERE PO.[MasterCompanyId] = @MasterCompanyId
              AND PO.[IsDeleted] = 0
              AND (@PurchaseOrderNumber IS NULL OR PO.[PurchaseOrderNumber] = @PurchaseOrderNumber)
              AND (@Status IS NULL OR PO.[Status] = @Status)
              AND (@OpenDateFrom IS NULL OR PO.[OpenDate] >= @OpenDateFrom)
              AND (@OpenDateTo IS NULL OR PO.[OpenDate] < DATEADD(DAY, 1, @OpenDateTo))
            ORDER BY PO.[PurchaseOrderId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            PO.[PurchaseOrderId],   -- used by the API to attach the parts; not returned to clients
            PO.[PurchaseOrderNumber],
            PO.[Status],
            PO.[Priority],
            PO.[OpenDate],
            PO.[NeedByDate],
            PO.[ClosedDate],
            PO.[DateApproved],
            PO.[ApprovedBy],
            PO.[Requisitioner],
            PO.[VendorCode],
            PO.[VendorName],
            PO.[VendorContact],
            PO.[VendorContactPhone],
            PO.[VendorContactEmail],
            PO.[Terms] AS [CreditTerms],
            PO.[CreditLimit],
            FC.[Code] AS [FunctionalCurrency],
            RC.[Code] AS [ReportCurrency],
            CASE WHEN PO.[ForeignExchangeRate] > 0 THEN PO.[ForeignExchangeRate] ELSE NULL END AS [ForeignExchangeRate],
            ISNULL(PP.[PartsCount], 0) AS [PartsCount],
            ISNULL(PP.[TotalPartsCost], 0) AS [TotalPartsCost],
            ISNULL(PO.[TotalFreight], 0) AS [TotalFreight],
            ISNULL(PO.[TotalCharges], 0) AS [TotalCharges],
            SV.[ShipVia],
            SV.[ShippingTerms],
            SV.[ShippingAccountNo],
            PO.[CreatedDate],
            PO.[UpdatedDate],
            P.[TotalRecords]
        FROM PagedPO P
        INNER JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON PO.[PurchaseOrderId] = P.[PurchaseOrderId]
        LEFT JOIN [dbo].[AllShipVia] SV WITH (NOLOCK) ON SV.[ReferenceId] = PO.[PurchaseOrderId] AND SV.[ModuleId] = @ModuleId
        LEFT JOIN [dbo].[Currency] FC WITH (NOLOCK) ON FC.[CurrencyId] = PO.[FunctionalCurrencyId]
        LEFT JOIN [dbo].[Currency] RC WITH (NOLOCK) ON RC.[CurrencyId] = PO.[ReportCurrencyId]
        OUTER APPLY (
            SELECT COUNT(1) AS [PartsCount], SUM(POP.[ExtendedCost]) AS [TotalPartsCost]
            FROM [dbo].[PurchaseOrderPart] POP WITH (NOLOCK)
            WHERE POP.[PurchaseOrderId] = PO.[PurchaseOrderId] AND ISNULL(POP.[IsDeleted], 0) = 0 AND ISNULL(POP.[isParent], 0) = 1
        ) PP
        ORDER BY PO.[PurchaseOrderId]
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetPurchaseOrderList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@PurchaseOrderNumber, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@Status, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@OpenDateFrom, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@OpenDateTo, '') AS VARCHAR(100))
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