
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
    2    25-Sep-2026		Moin Bloch			Added carrier-enrichment columns (country ISO codes, phone/contact,
                                            UOM short names, currency codes) for FedEx/UPS integration - mirrors dbo.GetWorkOrderShipping

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
			ISNULL(LS.[isBypassShipping], 0) AS IsBypassShipping,
			LCI.[EntryType], LCI.[EntryNumber], LCI.[CommodityCode], LCI.[EPU], LCI.[UCR], LCI.[MasterUCR], LCI.[MovementRefNo],
			LCI.[CustomsValue], LCI.[CustomCurrencyId], LCI.[NetMass], LCI.[VATValue],
			-- Carrier-enrichment (mirrors dbo.GetWorkOrderShipping) --
			uois.ShortName AS ShipSizeUnitOfMeasure,
			uoi.ShortName AS ShipWeightUnitOfMeasure,
			quoi.ShortName AS QtyUOMVal,
			CASE WHEN ISNULL(LS.[SoldToState], '') = '' THEN '' ELSE LS.[SoldToState] END AS SoldStateCode,
			CASE WHEN ISNULL(LS.[OriginState], '') = '' THEN '' ELSE LS.[OriginState] END AS OriginStateCode,
			CASE WHEN ISNULL(LS.[ShipToState], '') = '' THEN '' ELSE LS.[ShipToState] END AS ShipStateCode,
			ISNULL(soldcon.countries_iso_code, '') AS SoldCountryCode,
			ISNULL(ocon.countries_iso_code, '') AS OriginCountryCode,
			ISNULL(shipcon.countries_iso_code, '') AS ShipCountryCode,
			ISNULL(mocon.countries_iso_code, '') AS ManufactureCountry,
			shipcont.CustomerPhone AS ShipPhoneNumber,
			shipcont.CustomerPhoneExt AS ShipphoneExtension,
			cus.CustomerPhone AS SoldPhoneNumber,
			cus.CustomerPhoneExt AS SoldphoneExtension,
			cont.WorkPhone AS OriginPhoneNumber,
			ISNULL(cont.WorkPhoneExtn, '') AS OrignphoneExtension,
			LS.[ShipToName] AS ShipContactpersonName,
			LS.[SoldToName] AS SoldContactpersonName,
			LS.[OriginName] AS OrignContactpersonName,
			cur.Code AS UnitCurrency,
			ccur.Code AS CustomCurrency
		FROM [dbo].[LeaseShipping] LS WITH (NOLOCK)
		 LEFT JOIN [dbo].[ShippingVia] SV WITH (NOLOCK) ON SV.[ShippingViaId] = LS.[ShipViaId]
		 LEFT JOIN [dbo].[LeaseCustomsInfo] LCI WITH (NOLOCK) ON LCI.[LeaseShippingId] = LS.[LeaseShippingId]
		 LEFT JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LS.[LeaseHeaderId]
		 LEFT JOIN [dbo].[UnitOfMeasure] uoi WITH (NOLOCK) ON LS.[ShipWeightUnit] = uoi.[UnitOfMeasureId]
		 LEFT JOIN [dbo].[UnitOfMeasure] uois WITH (NOLOCK) ON LS.[ShipSizeUnitOfMeasureId] = uois.[UnitOfMeasureId]
		 LEFT JOIN [dbo].[UnitOfMeasure] quoi WITH (NOLOCK) ON LS.[QtyUOM] = quoi.[UnitOfMeasureId]
		 LEFT JOIN [dbo].[Countries] ocon WITH (NOLOCK) ON LS.[OriginCountryId] = ocon.[countries_id]
		 LEFT JOIN [dbo].[Countries] shipcon WITH (NOLOCK) ON LS.[ShipToCountryId] = shipcon.[countries_id]
		 LEFT JOIN [dbo].[Countries] soldcon WITH (NOLOCK) ON LS.[SoldToCountryId] = soldcon.[countries_id]
		 LEFT JOIN [dbo].[Countries] mocon WITH (NOLOCK) ON LS.[ManufactureCountryId] = mocon.[countries_id]
		 LEFT JOIN [dbo].[Customer] cus WITH (NOLOCK) ON LH.[CustomerId] = cus.[CustomerId]
		 LEFT JOIN [dbo].[Customer] shipcont WITH (NOLOCK) ON LS.[ShipToCustomerId] = shipcont.[CustomerId]
		 LEFT JOIN [dbo].[CustomerContact] custcon WITH (NOLOCK) ON LH.[CustomerContactId] = custcon.[CustomerContactId]
		 LEFT JOIN [dbo].[Contact] cont WITH (NOLOCK) ON custcon.[ContactId] = cont.[ContactId]
		 LEFT JOIN [dbo].[Currency] cur WITH (NOLOCK) ON LS.[UnitPriceCurrencyId] = cur.[CurrencyId]
		 LEFT JOIN [dbo].[Currency] ccur WITH (NOLOCK) ON LCI.[CustomCurrencyId] = ccur.[CurrencyId]
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