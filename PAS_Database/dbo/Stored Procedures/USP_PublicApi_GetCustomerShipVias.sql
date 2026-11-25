
/*************************************************************
 ** File:   [USP_PublicApi_GetCustomerShipVias]
 ** Author: Bhargav Saliya
 ** Description: Active ship vias of the customers' domestic ship-to addresses (@CustomerIds: comma separated),
 **              primary first. Same rows as dbo.USP_GetCustomerDomesticShippingDetails (PAS Shipping tab).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/customers (shipping address ship vias)
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Bhargav Saliya    Created

  EXEC [dbo].[USP_PublicApi_GetCustomerShipVias] @MasterCompanyId = 1, @CustomerIds = '1,2,3'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetCustomerShipVias]
    @MasterCompanyId INT,
    @CustomerIds     VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            SV.[CustomerDomensticShippingId] AS [ShippingAddressId],   -- used by the API to attach the ship vias; not returned
            V.[Name] AS [ShipVia],
            NULLIF(LTRIM(RTRIM(SV.[ShippingAccountInfo])), '') AS [ShippingAccountInfo],
            ST.[Name] AS [ShippingTerms],
            CAST(ISNULL(SV.[IsPrimary], 0) AS BIT) AS [IsPrimary]
        FROM [dbo].[CustomerDomensticShippingShipVia] SV WITH (NOLOCK)
        INNER JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.[CustomerId] = SV.[CustomerId] AND CU.[MasterCompanyId] = @MasterCompanyId
        INNER JOIN [dbo].[ShippingVia] V WITH (NOLOCK) ON V.[ShippingViaId] = SV.[ShipViaId]
        LEFT JOIN [dbo].[ShippingTerms] ST WITH (NOLOCK) ON ST.[ShippingTermsId] = SV.[ShippingTermsId]
        WHERE SV.[CustomerId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@CustomerIds, ','))
          AND ISNULL(SV.[IsDeleted], 0) = 0
          AND ISNULL(SV.[IsActive], 1) = 1
        ORDER BY SV.[CustomerDomensticShippingId], CAST(ISNULL(SV.[IsPrimary], 0) AS BIT) DESC, SV.[CustomerDomensticShippingShipViaId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetCustomerShipVias'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@CustomerIds, '') AS VARCHAR(100))
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