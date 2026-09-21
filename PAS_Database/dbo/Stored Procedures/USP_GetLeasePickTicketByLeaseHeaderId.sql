/*************************************************************
 ** File:   [USP_GetLeasePickTicketByLeaseHeaderId]
 ** Description: Header block of the Lease Pick Ticket PDF (company / lease / customer /
 **              picked-by / confirmed-by). Mirrors dbo.GetSalesOrderPickTicketBySalesOrderId.
 **
 **              The Leasing module has no addresses of its own (dbo.AllAddress has no rows for
 **              ModuleId 72 = Leasing), so Bill To and Ship To are taken from the CUSTOMER's
 **              primary billing / primary shipping records 
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    16/09/2026     Bhargav Saliya          [PN-17931] Created - Leasing Pick Ticket
    2    18/09/2026     Bhargav Saliya          [PN-17931] Bill To, Ship To now come from the customer's primary billing or shipping records

exec USP_GetLeasePickTicketByLeaseHeaderId @LeaseHeaderId=1, @LeasePickTicketId=1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeasePickTicketByLeaseHeaderId]
	@LeaseHeaderId BIGINT,
	@LeasePickTicketId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @CustomerId BIGINT;
		SELECT @CustomerId = LH.[CustomerId]
		FROM [dbo].[LeasePickTicket] LPT WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LPT.[LeaseHeaderId]
		WHERE LPT.[LeasePickTicketId] = @LeasePickTicketId;

		DECLARE @BillToSiteName VARCHAR(500) = '', @BillToAttention VARCHAR(500) = '',
				@BillToAddress1 VARCHAR(500) = '', @BillToAddress2 VARCHAR(500) = '',
				@BillToCity VARCHAR(200) = '', @BillToState VARCHAR(200) = '',
				@BillToPostalCode VARCHAR(100) = '', @BillToCountry VARCHAR(200) = '';

		DECLARE @ShipToSiteName VARCHAR(500) = '', @ShipToAttention VARCHAR(500) = '',
				@ShipToAddress1 VARCHAR(500) = '', @ShipToAddress2 VARCHAR(500) = '',
				@ShipToCity VARCHAR(200) = '', @ShipToState VARCHAR(200) = '',
				@ShipToPostalCode VARCHAR(100) = '', @ShipToCountry VARCHAR(200) = '';

		SELECT TOP 1
			@BillToSiteName   = ISNULL(B.[SiteName], ''),
			@BillToAttention  = ISNULL(B.[Attention], ''),
			@BillToAddress1   = ISNULL(A.[Line1], ''),
			@BillToAddress2   = ISNULL(A.[Line2], ''),
			@BillToCity       = ISNULL(A.[City], ''),
			@BillToState      = ISNULL(A.[StateOrProvince], ''),
			@BillToPostalCode = ISNULL(A.[PostalCode], ''),
			@BillToCountry    = ISNULL(CN.[countries_name], '')
		FROM [dbo].[CustomerBillingAddress] B WITH (NOLOCK)
		 LEFT JOIN [dbo].[Address] A WITH (NOLOCK)    ON A.[AddressId] = B.[AddressId]
		 LEFT JOIN [dbo].[Countries] CN WITH (NOLOCK) ON CN.[countries_id] = A.[CountryId]
		WHERE B.[CustomerId] = @CustomerId
		  AND ISNULL(B.[IsDeleted], 0) = 0
		  AND ISNULL(B.[IsActive], 1) = 1
		ORDER BY ISNULL(B.[IsPrimary], 0) DESC, B.[CustomerBillingAddressId] DESC;

		SELECT TOP 1
			@ShipToSiteName   = ISNULL(S.[SiteName], ''),
			@ShipToAttention  = ISNULL(S.[Attention], ''),
			@ShipToAddress1   = ISNULL(A.[Line1], ''),
			@ShipToAddress2   = ISNULL(A.[Line2], ''),
			@ShipToCity       = ISNULL(A.[City], ''),
			@ShipToState      = ISNULL(A.[StateOrProvince], ''),
			@ShipToPostalCode = ISNULL(A.[PostalCode], ''),
			@ShipToCountry    = ISNULL(CN.[countries_name], '')
		FROM [dbo].[CustomerDomensticShipping] S WITH (NOLOCK)
		 LEFT JOIN [dbo].[Address] A WITH (NOLOCK)    ON A.[AddressId] = S.[AddressId]
		 LEFT JOIN [dbo].[Countries] CN WITH (NOLOCK) ON CN.[countries_id] = A.[CountryId]
		WHERE S.[CustomerId] = @CustomerId
		  AND ISNULL(S.[IsDeleted], 0) = 0
		  AND ISNULL(S.[IsActive], 1) = 1
		ORDER BY ISNULL(S.[IsPrimary], 0) DESC, S.[CustomerDomensticShippingId] DESC;

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
			CONCAT(ISNULL(CONT.[FirstName], ''), ' ', ISNULL(CONT.[LastName], '')) AS CustomerContactName,
			CASE WHEN @BillToSiteName <> '' THEN @BillToSiteName ELSE ISNULL(CUS.[Name], '') END AS BillToName,
			@BillToAttention   AS BillToAttention,
			@BillToAddress1    AS BillToAddress1,
			@BillToAddress2    AS BillToAddress2,
			@BillToCity        AS BillToCity,
			@BillToState       AS BillToState,
			@BillToPostalCode  AS BillToPostalCode,
			@BillToCountry     AS BillToCountry,
			CASE WHEN @ShipToSiteName <> '' THEN @ShipToSiteName ELSE ISNULL(CUS.[Name], '') END AS ShipToName,
			@ShipToAttention   AS ShipToAttention,
			@ShipToAddress1    AS ShipToAddress1,
			@ShipToAddress2    AS ShipToAddress2,
			@ShipToCity        AS ShipToCity,
			@ShipToState       AS ShipToState,
			@ShipToPostalCode  AS ShipToPostalCode,
			@ShipToCountry     AS ShipToCountry,
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
		 LEFT JOIN [dbo].[CustomerContact] CC WITH (NOLOCK)  ON CC.[CustomerContactId] = LH.[CustomerContactId]
		 LEFT JOIN [dbo].[Contact] CONT WITH (NOLOCK)        ON CONT.[ContactId] = CC.[ContactId]
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