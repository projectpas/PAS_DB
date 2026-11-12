/*************************************************************           
 ** File:   [RPT_GetTSLWorkOrderInvoiceHeader]           
 ** Author: RAJESH GAMI
 ** Description: Work Order Invoice header data for the Turbine Standard Ltd (TSL) invoice format
 **              (WorkOrderBillingSingleMPN_TSL / WorkOrderBillingMultipleMPN_TSL SSRS reports).
 **              Returns one row per billed MPN (BillingInvoicingItems row).
 ** Date:   09-Nov-2026
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author          Change Description            
 ** --   --------      -------         --------------------------------          
    1    09-Nov-2026   RAJESH GAMI     [PN-18514] Created

--   EXEC [dbo].[RPT_GetTSLWorkOrderInvoiceHeader] 9696,15,2
**************************************************************/
CREATE PROCEDURE [dbo].[RPT_GetTSLWorkOrderInvoiceHeader]
@BillingInvoicingId BIGINT = NULL,
@ModuleId INT = NULL,
@EmployeeId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @WOModuleId INT, @ReferenceId BIGINT = NULL;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '', @GeneratedBy VARCHAR(500) = '';
		DECLARE @InvoiceDateTime DATETIME = NULL, @ProformaDepositAmount DECIMAL(18, 2) = 0;

		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

		IF (ISNULL(@ModuleId, 0) <> ISNULL(@WOModuleId, -1))
		BEGIN
			RETURN;
		END

		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
		  FROM [dbo].[Employee] E WITH (NOLOCK)
		       LEFT JOIN [dbo].[TimeZone] ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		       LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		       LEFT JOIN [dbo].[TimeZone] LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		 WHERE E.EmployeeId = @EmployeeId;

		-- Logged-in user who is generating/printing the invoice
		SELECT @GeneratedBy = LTRIM(RTRIM(ISNULL(E.[FirstName], '') + ' ' + ISNULL(E.[LastName], '')))
		  FROM [dbo].[Employee] E WITH (NOLOCK) WHERE E.[EmployeeId] = @EmployeeId;

		SELECT @ReferenceId = [ReferenceId] FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [BillingInvoicingId] = @BillingInvoicingId;

		-- Invoice Date + Invoice Time as entered by the user, fallback to UTC conversion when time is not available
		SELECT @InvoiceDateTime = CASE WHEN TRY_CONVERT(TIME, [InvoiceTime]) IS NOT NULL
		                               THEN CAST(CAST([InvoiceDate] AS DATE) AS DATETIME) + CAST(TRY_CONVERT(TIME, [InvoiceTime]) AS DATETIME)
		                               ELSE CAST(dbo.ConvertUTCtoLocal([InvoiceDate], @CurrntEmpTimeZoneDesc) AS DATETIME) END
		  FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [BillingInvoicingId] = @BillingInvoicingId AND [InvoiceDate] IS NOT NULL;

		-- Payments (deposits) received against this work order
		SELECT @ProformaDepositAmount = SUM(ISNULL(BI.[DepositAmount], 0)) - SUM(ISNULL(BI.[UsedDeposit], 0))
		  FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)
		 WHERE BI.[ReferenceId] = @ReferenceId AND BI.[ModuleId] = @ModuleId AND ISNULL(BI.[IsPerformaInvoice], 0) = 1;

		SELECT BII.[BillingInvoicingItemId],
		       ROW_NUMBER() OVER (ORDER BY WOP.[ID]) AS [ItemNo],
		       BI.[ReferenceId] AS [WorkOrderId],
		       WO.[MasterCompanyId],
		       -- BILL TO (sold to customer / site, falls back to the work order customer)
		       ADDR.[Name] AS [BillToName],
		       ADDR.[Line1] AS [BillToLine1],
		       ADDR.[Line2] AS [BillToLine2],
		       ADDR.[CityStateZip] AS [BillToCityStateZip],
		       ADDR.[Country] AS [BillToCountry],
		       -- ready to print block: name, address lines, city/state/zip, country (blank lines skipped)
		       ADDR.[Name]
		         + CASE WHEN ADDR.[Line1] <> '' THEN CHAR(10) + ADDR.[Line1] ELSE '' END
		         + CASE WHEN ADDR.[Line2] <> '' THEN CHAR(10) + ADDR.[Line2] ELSE '' END
		         + CASE WHEN ADDR.[CityStateZip] <> '' THEN CHAR(10) + ADDR.[CityStateZip] ELSE '' END
		         + CASE WHEN ADDR.[Country] <> '' THEN CHAR(10) + ADDR.[Country] ELSE '' END AS [BillToBlock],
		       -- INVOICE
		       BI.[InvoiceNo] AS [InvoiceNumber],
		       CASE WHEN @InvoiceDateTime IS NOT NULL THEN FORMAT(@InvoiceDateTime, 'MM/dd/yyyy') ELSE '' END AS [InvoiceDate],
		       CASE WHEN ISNULL(WO.[CreditTerms], '') <> '' THEN WO.[CreditTerms]
		            WHEN ISNULL(WO.[NetDays], 0) > 0 THEN 'Net ' + CAST(WO.[NetDays] AS VARCHAR(10))
		            ELSE '' END AS [Terms],
		       -- UNIT
		       ISNULL(WOP.[RevisedPartNumber], '') AS [Model],
		       ISNULL(WOP.[RevisedSerialNumber], '') AS [SerialNumber],
		       ISNULL(WOP.[CustomerReference], '') AS [PONumber],
		       -- WORK PERFORMED NARRATIVE (invoice notes)
		       LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(BI.[Notes], ''), '<p>', ''), '</p>', CHAR(10)), '<br />', CHAR(10)), '<br>', CHAR(10)), '&nbsp;', ' '))) AS [WorkPerformed],
		       -- ENGINE TIME & CYCLES (a label is skipped when its value is blank)
		       LTRIM(RTRIM(
		            CASE WHEN NULLIF(LTRIM(RTRIM(WOP.[TSN])), '')    IS NOT NULL THEN 'TSN: '    + LTRIM(RTRIM(WOP.[TSN]))    + '   ' ELSE '' END
		          + CASE WHEN NULLIF(LTRIM(RTRIM(WOP.[CSN])), '')    IS NOT NULL THEN 'CSN: '    + LTRIM(RTRIM(WOP.[CSN]))    + '   ' ELSE '' END
		          + CASE WHEN NULLIF(LTRIM(RTRIM(WOP.[TSCAM])), '')  IS NOT NULL THEN 'TSCAM: '  + LTRIM(RTRIM(WOP.[TSCAM]))  + '   ' ELSE '' END
		          + CASE WHEN NULLIF(LTRIM(RTRIM(WOP.[CSCAM])), '')  IS NOT NULL THEN 'CSCAM: '  + LTRIM(RTRIM(WOP.[CSCAM]))  + '   ' ELSE '' END
		          + CASE WHEN NULLIF(LTRIM(RTRIM(WOP.[TSHSI])), '')  IS NOT NULL THEN 'TSHSI: '  + LTRIM(RTRIM(WOP.[TSHSI]))  ELSE '' END
		       )) AS [EngineTimeCycles],
		       WOP.[TSN], WOP.[CSN], WOP.[TSCAM], WOP.[CSCAM], WOP.[TSHSI],
		       -- FOOTER
		       ISNULL(NULLIF(@GeneratedBy, ''), ISNULL(BI.[CreatedBy], '')) AS [GeneratedBy],
		       ISNULL(BI.[IsPerformaInvoice], 0) AS [IsProformaInvoice],
		       ISNULL(BI.[SalesTax], 0) AS [Tax],
		       ISNULL(BI.[OtherTax], 0) AS [OtherTax],
		       ISNULL(BI.[GrandTotal], 0) AS [GrandTotal],
		       CASE WHEN ISNULL(BI.[DepositAmount], 0) >= @ProformaDepositAmount AND ISNULL(BI.[IsPerformaInvoice], 0) = 0
		            THEN ISNULL(@ProformaDepositAmount, 0) ELSE ISNULL(BI.[DepositAmount], 0) END AS [DepositAmount]
		  FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
		       INNER JOIN [dbo].[BillingInvoicing] BI WITH(NOLOCK) ON BII.[BillingInvoicingId] = BI.[BillingInvoicingId]
		       INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BI.[ReferenceId] = WO.[WorkOrderId]
		       INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON BII.[SubReferenceId] = WOP.[ID]
		       INNER JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON WO.[CustomerId] = CUST.[CustomerId]
		        LEFT JOIN [dbo].[Address] CADDR WITH(NOLOCK) ON CUST.[AddressId] = CADDR.[AddressId]
		        LEFT JOIN [dbo].[Countries] CCTRY WITH(NOLOCK) ON CADDR.[CountryId] = CCTRY.[countries_id]
		       OUTER APPLY (SELECT TOP 1 D.[SoldToCustomerId], D.[SoldToSiteId]
		                      FROM [dbo].[BillingInvoicingDetails] D WITH(NOLOCK)
		                     WHERE D.[BillingInvoicingId] = BI.[BillingInvoicingId]) BID
		        LEFT JOIN [dbo].[Customer] BCUST WITH(NOLOCK) ON BID.[SoldToCustomerId] = BCUST.[CustomerId]
		        LEFT JOIN [dbo].[CustomerBillingAddress] BSITE WITH(NOLOCK) ON BID.[SoldToSiteId] = BSITE.[CustomerBillingAddressId]
		        LEFT JOIN [dbo].[Address] BADDR WITH(NOLOCK) ON BSITE.[AddressId] = BADDR.[AddressId]
		        LEFT JOIN [dbo].[Countries] BCTRY WITH(NOLOCK) ON BADDR.[CountryId] = BCTRY.[countries_id]
		       CROSS APPLY (SELECT ISNULL(ISNULL(BCUST.[Name], CUST.[Name]), '') AS [Name],
		                           ISNULL(ISNULL(BADDR.[Line1], CADDR.[Line1]), '') AS [Line1],
		                           ISNULL(ISNULL(BADDR.[Line2], CADDR.[Line2]), '') AS [Line2],
		                           LTRIM(RTRIM(ISNULL(ISNULL(BADDR.[City], CADDR.[City]), '')
		                                + CASE WHEN ISNULL(ISNULL(BADDR.[City], CADDR.[City]), '') <> '' AND ISNULL(ISNULL(BADDR.[StateOrProvince], CADDR.[StateOrProvince]), '') <> '' THEN ', ' ELSE '' END
		                                + ISNULL(ISNULL(BADDR.[StateOrProvince], CADDR.[StateOrProvince]), '') + ' '
		                                + ISNULL(ISNULL(BADDR.[PostalCode], CADDR.[PostalCode]), ''))) AS [CityStateZip],
		                           ISNULL(BCTRY.[countries_name], ISNULL(CCTRY.[countries_name], '')) AS [Country]) ADDR
		 WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND BII.[ModuleId] = @WOModuleId
		 ORDER BY [ItemNo];

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'RPT_GetTSLWorkOrderInvoiceHeader'
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
			EXEC spLogException
				@DatabaseName = @DatabaseName
				, @AdhocComments = @AdhocComments
				, @ProcedureParameters = @ProcedureParameters
				, @ApplicationName = @ApplicationName
				, @ErrorLogID = @ErrorLogID OUTPUT;
			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
			RETURN(1);
	END CATCH
END
