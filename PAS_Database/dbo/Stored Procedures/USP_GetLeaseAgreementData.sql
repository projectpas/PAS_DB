/*************************************************************
 ** File:   [USP_GetLeaseAgreementData]
 ** Description: Values of the Lease Agreement that COME FROM THE DATABASE (not typed): lessee (customer), signatory, purchase order,
 **              engine (part number, serial number, manufacturer from the lease stockline / stockline, TSN / CSN from the last record of
 **              StocklineTimeCycleHistory of the stockline), currency and monthly rent of ONE lease stockline.
 **              Returns ONE row; every column name is a tag of the agreement without the ## (LESSEE_LEGAL_NAME fills
 **              ##LESSEE_LEGAL_NAME##); a value the database does not have is '' (the screen then shows a text box for it).
 **              Used by the Lease Agreement screen (blue values) and by the PDF generation (merged with the values returned
 **              by USP_GetLeaseAgreementPDFData). The LESSOR_* values come from the company header (the API uses
 **              MANAGEMENT_STRUCTURE_ID for that).
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    02/11/2026     Rajesh Gami             [PN-18468] Created - database values of the Lease Agreement
    2    02/11/2026     Rajesh Gami             [PN-18468] Engine details from the lease stockline / stockline, TSN / CSN from the last StocklineTimeCycleHistory record, customer address falls back to the customer main address
    3    02/11/2026     Rajesh Gami             [PN-18468] Insured value (QtyOrder x Stockline Quantity), aircraft type / serial number (Stockline AircraftTailNumber / AircraftSN)

exec USP_GetLeaseAgreementData @LeaseHeaderId=1, @LeaseStocklineId=1, @MasterCompanyId=1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseAgreementData]
	@LeaseHeaderId BIGINT,
	@LeaseStocklineId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @CustomerId BIGINT;
		SELECT @CustomerId = LH.[CustomerId]
		FROM [dbo].[LeaseHeader] LH WITH (NOLOCK)
		WHERE LH.[LeaseHeaderId] = @LeaseHeaderId
		  AND LH.[MasterCompanyId] = @MasterCompanyId;

		-- Lessee address = the customer's primary billing address, written on one line
		DECLARE @Line1 VARCHAR(500) = '', @Line2 VARCHAR(500) = '', @City VARCHAR(200) = '', @State VARCHAR(200) = '',
				@PostalCode VARCHAR(100) = '', @Country VARCHAR(200) = '';

		SELECT TOP 1
			@Line1      = LTRIM(RTRIM(ISNULL(A.[Line1], ''))),
			@Line2      = LTRIM(RTRIM(ISNULL(A.[Line2], ''))),
			@City       = LTRIM(RTRIM(ISNULL(A.[City], ''))),
			@State      = LTRIM(RTRIM(ISNULL(A.[StateOrProvince], ''))),
			@PostalCode = LTRIM(RTRIM(ISNULL(A.[PostalCode], ''))),
			@Country    = LTRIM(RTRIM(ISNULL(CN.[countries_name], '')))
		FROM [dbo].[CustomerBillingAddress] B WITH (NOLOCK)
		 LEFT JOIN [dbo].[Address] A WITH (NOLOCK)    ON A.[AddressId] = B.[AddressId]
		 LEFT JOIN [dbo].[Countries] CN WITH (NOLOCK) ON CN.[countries_id] = A.[CountryId]
		WHERE B.[CustomerId] = @CustomerId
		  AND ISNULL(B.[IsDeleted], 0) = 0
		  AND ISNULL(B.[IsActive], 1) = 1
		ORDER BY ISNULL(B.[IsPrimary], 0) DESC, B.[CustomerBillingAddressId] DESC;

		-- no billing address: the main address of the customer
		IF (@Line1 = '' AND @City = '')
		BEGIN
			SELECT TOP 1
				@Line1      = LTRIM(RTRIM(ISNULL(A.[Line1], ''))),
				@Line2      = LTRIM(RTRIM(ISNULL(A.[Line2], ''))),
				@City       = LTRIM(RTRIM(ISNULL(A.[City], ''))),
				@State      = LTRIM(RTRIM(ISNULL(A.[StateOrProvince], ''))),
				@PostalCode = LTRIM(RTRIM(ISNULL(A.[PostalCode], ''))),
				@Country    = LTRIM(RTRIM(ISNULL(CN.[countries_name], '')))
			FROM [dbo].[Customer] CU WITH (NOLOCK)
			 LEFT JOIN [dbo].[Address] A WITH (NOLOCK)    ON A.[AddressId] = CU.[AddressId]
			 LEFT JOIN [dbo].[Countries] CN WITH (NOLOCK) ON CN.[countries_id] = A.[CountryId]
			WHERE CU.[CustomerId] = @CustomerId;
		END

		DECLARE @LesseeAddress VARCHAR(2000) =
			  @Line1
			+ CASE WHEN @Line2 <> '' THEN CASE WHEN @Line1 <> '' THEN ', ' ELSE '' END + @Line2 ELSE '' END
			+ CASE WHEN @City <> '' THEN CASE WHEN @Line1 + @Line2 <> '' THEN ', ' ELSE '' END + @City ELSE '' END
			+ CASE WHEN @State <> '' THEN CASE WHEN @Line1 + @Line2 + @City <> '' THEN ', ' ELSE '' END + @State ELSE '' END
			+ CASE WHEN @PostalCode <> '' THEN ' ' + @PostalCode ELSE '' END
			+ CASE WHEN @Country <> '' THEN CASE WHEN @Line1 + @Line2 + @City + @State + @PostalCode <> '' THEN ', ' ELSE '' END + @Country ELSE '' END;

		SELECT TOP 1
			LH.[ManagementStructureId]                             AS MANAGEMENT_STRUCTURE_ID,
			-- ---- lessee (customer) ----
			ISNULL(CUS.[Name], '')                                 AS LESSEE_LEGAL_NAME,
			@LesseeAddress                                         AS LESSEE_ADDRESS,
			ISNULL(NULLIF(LH.[Email], ''), ISNULL(CUS.[Email], '')) AS LESSEE_NOTICE_EMAIL,
			LTRIM(RTRIM(CONCAT(ISNULL(CONT.[FirstName], ''), ' ', ISNULL(CONT.[LastName], '')))) AS LESSEE_SIGNATORY_NAME,
			ISNULL(LH.[CustomerRef], '')                           AS PURCHASE_ORDER_NUMBER,
			-- ---- leased engine (details of the lease stockline; TSN / CSN = last record of the stockline time / cycle history) ----
			ISNULL(NULLIF(LSL.[PN], ''), ISNULL(SLIVE.[PartNumber], ''))                 AS ENGINE_MODEL_NUMBER,
			ISNULL(NULLIF(LSL.[SN], ''), ISNULL(SLIVE.[SerialNumber], ''))              AS ENGINE_SERIAL_NUMBER,
			ISNULL(NULLIF(SLIVE.[Manufacturer], ''), ISNULL(IM.[ManufacturerName], '')) AS ENGINE_MANUFACTURER,
			CASE WHEN ISNULL(TCH.[TotalTSN], SLIVE.[TotalTSN]) IS NULL THEN '' ELSE FORMAT(ISNULL(TCH.[TotalTSN], SLIVE.[TotalTSN]), 'N1') END AS ENGINE_TSN,
			CASE WHEN ISNULL(TCH.[TotalCSN], SLIVE.[TotalCSN]) IS NULL THEN '' ELSE FORMAT(ISNULL(TCH.[TotalCSN], SLIVE.[TotalCSN]), 'N0') END AS ENGINE_CSN,
			-- ---- insured value = lease stockline quantity ordered x stockline quantity; aircraft = tail number / serial number of the stockline ----
			CASE WHEN NULLIF(CAST(LSL.[QtyOrder] AS DECIMAL(18, 6)) * ISNULL(SLIVE.[Quantity], 0), 0) IS NULL THEN ''
				 ELSE FORMAT(CAST(LSL.[QtyOrder] AS DECIMAL(18, 6)) * SLIVE.[Quantity], 'N2') END AS INSURED_VALUE,
			ISNULL(SLIVE.[AircraftTailNumber], '')                 AS AIRCRAFT_TYPE_MODEL,
			ISNULL(SLIVE.[AircraftSN], '')                         AS AIRCRAFT_SERIAL_NUMBER,
			-- ---- rent / currency ----
			ISNULL(CUR.[Code], '')                                 AS CURRENCY,
			ISNULL(CUR.[Code], '')                                 AS PAYMENT_CURRENCY,
			CASE WHEN LSL.[FlatRate] IS NULL THEN '' ELSE FORMAT(LSL.[FlatRate], 'N2') END AS MONTHLY_RENT_AMOUNT
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK)      ON LH.[LeaseHeaderId] = LSL.[LeaseHeaderId]
		 LEFT JOIN [dbo].[Customer] CUS WITH (NOLOCK)        ON CUS.[CustomerId] = LH.[CustomerId]
		 LEFT JOIN [dbo].[CustomerContact] CC WITH (NOLOCK)  ON CC.[CustomerContactId] = LH.[CustomerContactId]
		 LEFT JOIN [dbo].[Contact] CONT WITH (NOLOCK)        ON CONT.[ContactId] = CC.[ContactId]
		 LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK)     ON SLIVE.[StockLineId] = LSL.[StockLineId]
		 LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK)       ON IM.[ItemMasterId] = LSL.[ItemMasterId]
		OUTER APPLY (SELECT TOP 1 TH.[TotalTSN], TH.[TotalCSN]
					 FROM [dbo].[StocklineTimeCycleHistory] TH WITH (NOLOCK)
					 WHERE TH.[StocklineId] = LSL.[StockLineId]
					   AND ISNULL(TH.[IsDeleted], 0) = 0
					 ORDER BY TH.[UpdatedDate] DESC, TH.[StocklineTimeCycleHistoryId] DESC) TCH
		 LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK)        ON CUR.[CurrencyId] = LH.[LocalCurrencyId]
		WHERE LSL.[LeaseStocklineId] = @LeaseStocklineId
		  AND LSL.[LeaseHeaderId]    = @LeaseHeaderId
		  AND LSL.[IsDeleted]        = 0
		  AND LH.[IsDeleted]         = 0;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeaseAgreementData]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100))
											   + ''', @LeaseStocklineId = ''' + CAST(ISNULL(@LeaseStocklineId, 0) AS VARCHAR(100))
											   + ''', @MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100)),
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

