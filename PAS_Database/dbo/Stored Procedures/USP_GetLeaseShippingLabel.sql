
/***************************************************************  
 ** File:  [USP_GetLeaseShippingLabel]            
 ** Author:   Moin Bloch
 ** Description: Get data for Lease Shipping Label print
 ** Date:  25-Sep-2026
 ** Change History             
 *******************************************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    24-Sep-2026		Moin Bloch			Created
	
*******************************************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetLeaseShippingLabel]
    @LeaseShippingId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY

        SELECT TOP 1
            LS.[LeaseShippingId],
            LS.[LeaseHeaderId],
            LH.[LeaseNumber],
            LS.[ShipDate],
            ISNULL(LS.[Weight], 0) AS Weight,
            uom.[ShortName] AS UOM,
            uomn.[ShortName] AS UOMDimention,
            ISNULL(LS.[AirwayBill], '') AS AirwayBill,
            LS.[OriginName] AS OriginCompanyName,
            LS.[OriginAddress1] AS OriginAddress1,
            LS.[OriginCity] AS OriginCity,
            LS.[OriginState] AS OriginState,
            LS.[OriginZip] AS OriginPostalCode,
            LS.[OriginCountryName] AS OriginCountry,
            LS.[ShipToName] AS ShipToComanyName,
            LS.[ShipToSiteName] AS ShipToSiteName,
            LS.[ShipAttention] AS ShipToAttention,
            LS.[ShipToAddress1] AS ShipToAddress1,
            LS.[ShipToCity] AS ShipToCity,
            LS.[ShipToState] AS ShipToState,
            LS.[ShipToZip] AS ShipToPostalCode,
            LS.[ShipToCountryName] AS ShipToCountry,
            cust.[CustomerPhone] AS ShipToPhone,
            LS.[ShipSizeLength] AS Length,
            LS.[ShipSizeWidth] AS Width,
            LS.[ShipSizeHeight] AS Height,
            LS.[NoOfContainer] AS NoOfContainer,
            LS.[NoOfItems] AS NoOfPiece,
            LS.[UpdatedDate],
            LS.[MasterCompanyId]
        FROM [dbo].[LeaseShipping] LS WITH (NOLOCK)
        LEFT JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LS.[LeaseHeaderId]
        LEFT JOIN [dbo].[Customer] cust WITH (NOLOCK) ON cust.[CustomerId] = LS.[ShipToCustomerId]
        LEFT JOIN [dbo].[UnitOfMeasure] uom WITH (NOLOCK) ON uom.[UnitOfMeasureId] = LS.[ShipWeightUnit]
        LEFT JOIN [dbo].[UnitOfMeasure] uomn WITH (NOLOCK) ON uomn.[UnitOfMeasureId] = LS.[ShipSizeUnitOfMeasureId]
        WHERE LS.[LeaseShippingId] = @LeaseShippingId
          AND LS.[IsDeleted] = 0;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
            @AdhocComments VARCHAR(150) = '[USP_GetLeaseShippingLabel]',
            @ProcedureParameters VARCHAR(3000) = '@LeaseShippingId = ''' + CAST(ISNULL(@LeaseShippingId, 0) AS VARCHAR(100)),
            @ApplicationName VARCHAR(100) = 'PAS'
        EXEC spLogException @DatabaseName = @DatabaseName,
                            @AdhocComments = @AdhocComments,
                            @ProcedureParameters = @ProcedureParameters,
                            @ApplicationName = @ApplicationName,
                            @ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN (1);
    END CATCH
END