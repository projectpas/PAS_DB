
/***************************************************************  
 ** File:  [USP_GetLeaseShippingForEdit]            
 ** Author:   Moin Bloch
 ** Description: Get Lease Shipping details for edit, including customs info and item lines
 ** Date:  25-Sep-2026
 ** Change History             
 *******************************************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    21-Sep-2026		Moin Bloch			Created
	
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseShippingForEdit]
	@LeaseShippingId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		SELECT
			LS.[LeaseShippingId], LS.[LeaseHeaderId], LS.[LeaseShippingNum] AS LeaseShippingNumber,
			LS.[LeaseShippingStatusId], LS.[Shipment], LS.[OpenDate],
			LS.[ShipDate], LS.[ShipViaId], ISNULL(SV.[Name], '') AS ShipViaName,
			LS.[IsCustomerShipping], LS.[ShippingAccountInfo],
			LS.[TrackingNum], LS.[AirwayBill], LS.[HouseAirwayBill],
			LS.[IsManualShipping], LS.[isIgnoreAWB],
			LS.[Weight], LS.[ShipWeightUnit], LS.[ShipSizeLength], LS.[ShipSizeWidth], LS.[ShipSizeHeight], LS.[ShipSizeUnitOfMeasureId],
			LS.[NoOfItems], LS.[NoOfContainer], LS.[ManufactureCountryId], LS.[QtyUOM], LS.[UnitPrice], LS.[UnitPriceCurrencyId],
			LS.[Notes],
			LS.[SoldToName], LS.[SoldToAddress1], LS.[SoldToAddress2], LS.[SoldToCity], LS.[SoldToState], LS.[SoldToZip], LS.[SoldToCountryId], LS.[SoldToCountryName], LS.[SoldAttention],
			LS.[SoldToSiteId], LS.[SoldToSiteName],
			LS.[ShipToName], LS.[ShipToAddress1], LS.[ShipToAddress2], LS.[ShipToCity], LS.[ShipToState], LS.[ShipToZip], LS.[ShipToCountryId], LS.[ShipToCountryName], LS.[ShipAttention],
			LS.[ShipToSiteId], LS.[ShipToSiteName], LS.[ShipToCustomerId],
			LS.[OriginName], LS.[OriginAddress1], LS.[OriginAddress2], LS.[OriginCity], LS.[OriginState], LS.[OriginZip], LS.[OriginCountryId], LS.[OriginCountryName],
			LS.[OriginSiteId],
			ISNULL(LS.[IsSameForShipTo], 0) AS IsSameForShipTo,
			LS.[CreatedBy], LS.[MasterCompanyId],
			LCI.[EntryType], LCI.[EntryNumber], LCI.[CommodityCode], LCI.[EPU], LCI.[UCR], LCI.[MasterUCR], LCI.[MovementRefNo],
			LCI.[CustomsValue], LCI.[CustomCurrencyId], LCI.[NetMass], LCI.[VATValue]
		FROM [dbo].[LeaseShipping] LS WITH (NOLOCK)
		 LEFT JOIN [dbo].[ShippingVia] SV WITH (NOLOCK) ON SV.[ShippingViaId] = LS.[ShipViaId]
		 LEFT JOIN [dbo].[LeaseCustomsInfo] LCI WITH (NOLOCK) ON LCI.[LeaseShippingId] = LS.[LeaseShippingId]
		WHERE LS.[LeaseShippingId] = @LeaseShippingId;

		SELECT
			LSI.[LeaseShippingItemId], LSI.[LeasePickTicketId], LSI.[LeaseStocklineId],
			LSL.[PN] AS PartNumber, LSL.[PNDescription] AS PartDescription,
			ISNULL(SL.[SerialNumber], '') AS SerialNumber, ISNULL(SL.[StockLineNumber], '') AS StockLineNumber,
			CAST(ISNULL(LPT.[QtyPicked], 0) AS DECIMAL(18, 6)) AS QtyPicked,
			CAST(ISNULL(LSI.[QtyShipped], 0) AS DECIMAL(18, 6)) AS QtyShipped,
			CAST(CASE WHEN (ISNULL(LPT.[QtyPicked], 0) - ISNULL(OtherShipped.QtyShipped, 0) - ISNULL(LSI.[QtyShipped], 0)) < 0
					  THEN 0
					  ELSE (ISNULL(LPT.[QtyPicked], 0) - ISNULL(OtherShipped.QtyShipped, 0) - ISNULL(LSI.[QtyShipped], 0))
				 END AS DECIMAL(18, 6)) AS QtyRemaining
		FROM [dbo].[LeaseShippingItem] LSI WITH (NOLOCK)
		 LEFT JOIN [dbo].[LeasePickTicket] LPT WITH (NOLOCK) ON LPT.[LeasePickTicketId] = LSI.[LeasePickTicketId]
		 LEFT JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK)  ON LSL.[LeaseStocklineId] = LSI.[LeaseStocklineId]
		 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK)        ON SL.[StockLineId] = LSI.[StocklineId]
		 OUTER APPLY (
			SELECT SUM(ISNULL(LSI2.[QtyShipped], 0)) AS QtyShipped
			FROM [dbo].[LeaseShippingItem] LSI2 WITH (NOLOCK)
			WHERE LSI2.[LeasePickTicketId] = LSI.[LeasePickTicketId]
			  AND LSI2.[IsDeleted] = 0
			  AND LSI2.[LeaseShippingItemId] <> LSI.[LeaseShippingItemId]
		 ) OtherShipped
		WHERE LSI.[LeaseShippingId] = @LeaseShippingId
		  AND LSI.[IsDeleted] = 0
		ORDER BY LSI.[LeaseShippingItemId];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeaseShippingForEdit]',
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