
/***************************************************************
 ** File:  [USP_GetLeasePackagingLabel]
 ** Author:   Moin Bloch
 ** Description: Get header + line-item data to print a Lease Packing Slip - mirrors
 **              app-work-order-shipping's USP_GetWorkOrderPackagingLabelByWorkOrderId /
 **              GetWOPackagingLabelPrint field-for-field, simplified since LeaseShipping already
 **              stores its own full address snapshot (no need to re-derive from Customer/Address/PO/RO joins).
 **              Header address/ship-via/tracking data is taken from the first shipment record
 **              associated with any of this slip's pick-ticket lines.
 ** Date:  25-Sep-2026
 ** Change History
 *******************************************************************************************
 ** PR   Date				Author  				Change Description
 ** --   --------			-------				--------------------------------
    1    25-Sep-2026		Moin Bloch			Created
    2    25-Sep-2026		Moin Bloch			Added SoldToSiteName and SalesPersonName (LeaseHeader.SalespersonEmployeeId)
                                            for literal WO template parity

*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeasePackagingLabel]
	@PackagingSlipId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		SELECT TOP 1
			PSH.[PackagingSlipId],
			PSH.[PackagingSlipNo],
			PSH.[LeaseHeaderId],
			LH.[LeaseNumber],
			LH.[ManagementStructureId],
			ISNULL(CONCAT(emp.[FirstName], ' ', emp.[LastName]), '') AS SalesPersonName,
			LS.[LeaseShippingId],
			ISNULL(LS.[LeaseShippingNum], '') AS LeaseShippingNum,
			LS.[ShipDate],
			ISNULL(LS.[AirwayBill], '') AS AirwayBill,
			ISNULL(LS.[NoOfContainer], 0) AS NoOfContainer,
			ISNULL(SV.[Name], '') AS ShipViaName,
			LS.[ShippingAccountInfo],
			LS.[SoldToName] AS BillToName,
			LS.[SoldToSiteName] AS BillToSiteName,
			LS.[SoldToAddress1] AS BillToAddress1,
			LS.[SoldToAddress2] AS BillToAddress2,
			LS.[SoldToCity] AS BillToCity,
			LS.[SoldToState] AS BillToState,
			LS.[SoldToZip] AS BillToPostalCode,
			LS.[SoldToCountryName] AS BillToCountry,
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
			PSH.[MasterCompanyId],
			PSH.[CreatedBy],
			PSH.[CreatedDate]
		FROM [dbo].[LeasePackagingSlipHeader] PSH WITH (NOLOCK)
		LEFT JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = PSH.[LeaseHeaderId]
		LEFT JOIN [dbo].[Employee] emp WITH (NOLOCK) ON emp.[EmployeeId] = LH.[SalespersonEmployeeId]
		LEFT JOIN [dbo].[LeasePackagingSlipItem] PSI WITH (NOLOCK) ON PSI.[PackagingSlipId] = PSH.[PackagingSlipId] AND PSI.[IsDeleted] = 0
		LEFT JOIN [dbo].[LeaseShippingItem] LSI WITH (NOLOCK) ON LSI.[LeasePickTicketId] = PSI.[LeasePickTicketId] AND LSI.[IsDeleted] = 0
		LEFT JOIN [dbo].[LeaseShipping] LS WITH (NOLOCK) ON LS.[LeaseShippingId] = LSI.[LeaseShippingId] AND LS.[IsDeleted] = 0
		LEFT JOIN [dbo].[ShippingVia] SV WITH (NOLOCK) ON SV.[ShippingViaId] = LS.[ShipViaId]
		LEFT JOIN [dbo].[Customer] cust WITH (NOLOCK) ON cust.[CustomerId] = LS.[ShipToCustomerId]
		WHERE PSH.[PackagingSlipId] = @PackagingSlipId
		  AND PSH.[IsDeleted] = 0;

		SELECT
			ISNULL(LSL.[PN], '') AS PartNumber,
			ISNULL(LSL.[PNDescription], '') AS PartDescription,
			ISNULL(LSL.[SN], '') AS SerialNumber,
			ISNULL(LSL.[StocklineNumber], '') AS StockLineNumber,
			ISNULL(SL.[Condition], '') AS ConditionDescription,
			ISNULL(SL.[ConsumeUnitOfMeasure], '') AS UOM,
			CAST(ISNULL(LPT.[QtyPicked], 0) AS DECIMAL(18, 6)) AS QtyPicked,
			CAST(ISNULL(LSI.[QtyShipped], 0) AS DECIMAL(18, 6)) AS QtyShipped
		FROM [dbo].[LeasePackagingSlipItem] PSI WITH (NOLOCK)
		LEFT JOIN [dbo].[LeasePickTicket] LPT WITH (NOLOCK) ON LPT.[LeasePickTicketId] = PSI.[LeasePickTicketId]
		LEFT JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.[LeaseStocklineId] = LPT.[LeaseStocklineId]
		LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.[StockLineId] = LSL.[StockLineId]
		LEFT JOIN [dbo].[LeaseShippingItem] LSI WITH (NOLOCK) ON LSI.[LeasePickTicketId] = PSI.[LeasePickTicketId] AND LSI.[IsDeleted] = 0
		WHERE PSI.[PackagingSlipId] = @PackagingSlipId
		  AND PSI.[IsDeleted] = 0
		ORDER BY PSI.[PackagingSlipItemId];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeasePackagingLabel]',
			@ProcedureParameters VARCHAR(3000) = '@PackagingSlipId = ''' + CAST(ISNULL(@PackagingSlipId, 0) AS VARCHAR(100)),
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