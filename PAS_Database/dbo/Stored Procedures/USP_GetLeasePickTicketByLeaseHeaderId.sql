/*************************************************************
 ** File:   [USP_GetLeasePickTicketByLeaseHeaderId]
 ** Description: Header block of the Lease Pick Ticket PDF (company / lease / customer /
 **              picked-by / confirmed-by). Mirrors dbo.GetSalesOrderPickTicketBySalesOrderId.
 **
 **              The Leasing module has no Ship To address of its own (dbo.AllAddress has no
 **              rows for ModuleId 72), so the "ship to" block of the print is filled from the
 **              Site / Warehouse the picked stockline physically sits in.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    16/09/2026     Bhargav Saliya          [PN-17931] Created - Leasing Pick Ticket

exec USP_GetLeasePickTicketByLeaseHeaderId @LeaseHeaderId=1, @LeasePickTicketId=1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeasePickTicketByLeaseHeaderId]
	@LeaseHeaderId BIGINT,
	@LeasePickTicketId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		SELECT TOP 1
			LPT.[LeasePickTicketId],
			LPT.[LeasePickTicketNumber],
			LPT.[LeasePickTicketNumber]    AS LeasePickTicketBarcode,
			LH.[LeaseHeaderId],
			LH.[LeaseNumber],
			LH.[LeaseName],
			LH.[ManagementStructureId],
			LH.[CustomerId],
			ISNULL(LH.[CustomerRef], '')   AS CustomerReference,
			ISNULL(CUS.[Name], '')         AS CustomerName,
			ISNULL(CUS.[CustomerCode], '') AS CustomerCode,
			ISNULL(CUAD.[Line1], '')       AS CustToAddress1,
			ISNULL(CUAD.[Line2], '')       AS CustToAddress2,
			ISNULL(CUAD.[City], '')        AS CustToCity,
			ISNULL(CUAD.[StateOrProvince], '') AS CustToState,
			ISNULL(CUAD.[PostalCode], '')  AS CustToPostalCode,
			ISNULL(CNTY.[countries_name], '') AS CustToCountry,
			CONCAT(ISNULL(CONT.[FirstName], ''), ' ', ISNULL(CONT.[LastName], '')) AS CustomerContactName,
			ISNULL(ST.[Name], '')          AS ShipToSiteName,
			ISNULL(WH.[Name], '')          AS ShipToAddress1,
			''                             AS ShipToAddress2,
			''                             AS ShipToCity,
			''                             AS ShipToState,
			''                             AS ShipToPostalCode,
			''                             AS ShipToCountry,
			CONCAT(ISNULL(EMP.[FirstName], ''), ' ', ISNULL(EMP.[LastName], ''))   AS PickedByName,
			ISNULL(LPT.[PickedDate], LPT.[CreatedDate]) AS PickedDate,
			CONCAT(ISNULL(EMPC.[FirstName], ''), ' ', ISNULL(EMPC.[LastName], '')) AS ConfirmedByName,
			LPT.[ConfirmedDate],
			LPT.[CreatedDate]              AS PTCreatedDate,
			LPT.[CreatedBy],
			LPT.[UpdatedBy],
			LPT.[UpdatedDate],
			LPT.[MasterCompanyId]
		FROM [dbo].[LeasePickTicket] LPT WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK)      ON LH.[LeaseHeaderId] = LPT.[LeaseHeaderId]
		 LEFT JOIN [dbo].[Customer] CUS WITH (NOLOCK)        ON CUS.[CustomerId] = LH.[CustomerId]
		 LEFT JOIN [dbo].[Address] CUAD WITH (NOLOCK)        ON CUAD.[AddressId] = CUS.[AddressId]
		 LEFT JOIN [dbo].[Countries] CNTY WITH (NOLOCK)      ON CNTY.[countries_id] = CUAD.[CountryId]
		 LEFT JOIN [dbo].[CustomerContact] CC WITH (NOLOCK)  ON CC.[CustomerContactId] = LH.[CustomerContactId]
		 LEFT JOIN [dbo].[Contact] CONT WITH (NOLOCK)        ON CONT.[ContactId] = CC.[ContactId]
		 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK)        ON SL.[StockLineId] = LPT.[StockLineId]
		 LEFT JOIN [dbo].[Site] ST WITH (NOLOCK)             ON ST.[SiteId] = SL.[SiteId]
		 LEFT JOIN [dbo].[Warehouse] WH WITH (NOLOCK)        ON WH.[WarehouseId] = SL.[WarehouseId]
		 LEFT JOIN [dbo].[Employee] EMP WITH (NOLOCK)        ON EMP.[EmployeeId] = LPT.[PickedById]
		 LEFT JOIN [dbo].[Employee] EMPC WITH (NOLOCK)       ON EMPC.[EmployeeId] = LPT.[ConfirmedById]
		WHERE LPT.[LeaseHeaderId]     = @LeaseHeaderId
		  AND LPT.[LeasePickTicketId] = @LeasePickTicketId
		  AND LPT.[IsDeleted]         = 0;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeasePickTicketByLeaseHeaderId]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100))
											   + ''', @LeasePickTicketId = ''' + CAST(ISNULL(@LeasePickTicketId, 0) AS VARCHAR(100)),
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
