/*************************************************************
 ** File:   [RPT_GetCommonBillingInvoicingPdfData_LeasePreview]
 ** Author:  Kishor Makwana
 ** Description: Live PRE-COMMIT preview of the Lease Invoice PDF header for the LeaseBilling.rdl
 **              report (PN-18072 follow-up: "First we need to allow to preview the invoice then
 **              user will generate the invoice").
 ** Date:   25/SEP/2026
 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    25/SEP/2026   Kishor Makwana	CREATED [PN-18072] pre-commit invoice preview
    
--  EXEC [dbo].[RPT_GetCommonBillingInvoicingPdfData_LeasePreview] @LeaseHeaderId = 1, @LeaseStocklineIds = '1,2,3', @MasterCompanyId = 1
**************************************************************/
CREATE        PROCEDURE [dbo].[RPT_GetCommonBillingInvoicingPdfData_LeasePreview]
@LeaseHeaderId BIGINT = NULL,
@LeaseStocklineIds VARCHAR(MAX) = NULL,
@MasterCompanyId INT = NULL,
@EmployeeId BIGINT = NULL,
@InvoiceTypeId INT = NULL,
@CurrencyId INT = NULL,
@Notes NVARCHAR(MAX) = NULL,
@CreatedBy VARCHAR(256) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

	DECLARE @SalespersonEmployeeId BIGINT, @HeaderEmployeeId BIGINT, @LocalCurrencyId INT, @LeaseMasterCompanyId INT;
	SELECT
		@SalespersonEmployeeId = SalespersonEmployeeId,
		@HeaderEmployeeId = EmployeeId,
		@LocalCurrencyId = LocalCurrencyId,
		@LeaseMasterCompanyId = MasterCompanyId
	FROM [dbo].[LeaseHeader] WITH (NOLOCK)
	WHERE LeaseHeaderId = @LeaseHeaderId AND IsDeleted = 0;

	SET @EmployeeId = ISNULL(@EmployeeId, ISNULL(@SalespersonEmployeeId, @HeaderEmployeeId));
	SET @CurrencyId = ISNULL(@CurrencyId, @LocalCurrencyId);
	SET @MasterCompanyId = ISNULL(@MasterCompanyId, @LeaseMasterCompanyId);

	IF (ISNULL(@InvoiceTypeId, 0) = 0)
	BEGIN
		SELECT TOP 1 @InvoiceTypeId = InvoiceTypeId FROM [dbo].[InvoiceType] WITH (NOLOCK)
		WHERE MasterCompanyId = @MasterCompanyId AND [Description] = 'STANDARD' AND IsActive = 1 AND IsDeleted = 0;
	END

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
	  FROM [dbo].[Employee] E WITH (NOLOCK)
	       LEFT JOIN [dbo].[TimeZone] ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		   LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		   LEFT JOIN [dbo].[TimeZone] LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;

	-- ================= PEEK the next 'LeaseInvoice' number - READ ONLY, no UPDATE ==================
	DECLARE @LeaseInvoiceCodeTypeId INT, @CodePrefix NVARCHAR(50), @CodeSuffix NVARCHAR(50), @CurrentNo INT = 0, @NextInvoiceNo VARCHAR(256);

	SELECT @LeaseInvoiceCodeTypeId = CodeTypeId FROM [dbo].[CodeTypes] WITH (NOLOCK)
	WHERE CodeType = 'LeaseInvoice' AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

	IF (@LeaseInvoiceCodeTypeId IS NOT NULL)
	BEGIN
		SELECT TOP 1 @CodePrefix = CodePrefix, @CodeSuffix = CodeSufix FROM [dbo].[CodePrefixes] WITH (NOLOCK)
		WHERE CodeTypeId = @LeaseInvoiceCodeTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;
	END

	IF (COALESCE(@CodePrefix, '') <> '')
	BEGIN
		SELECT @CurrentNo = ISNULL(CurrentNummber, 0) FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId;
		IF (@CurrentNo > 0)
		BEGIN
			SET @CurrentNo = @CurrentNo + 1;
		END
		ELSE
		BEGIN
			SET @CurrentNo = (SELECT ISNULL(StartsFrom, 0) FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId) + 1;
		END
		-- Intentionally NO 'UPDATE CodePrefixes SET CurrentNummber = ...' here - this is a preview, not a commit.
		SET @NextInvoiceNo = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNo, ISNULL(@CodePrefix, ''), ISNULL(@CodeSuffix, '')));
	END
	ELSE
	BEGIN
		DECLARE @LastInvoiceNo VARCHAR(256);
			DECLARE @LastInvoiceNumber INT,@LeaseModuleId BIGINT;
			SELECT TOP 1 @LeaseModuleId = ModuleId from Module WITH (NOLOCK) WHERE ModuleName ='Leasing';
			SELECT TOP 1 @LastInvoiceNo = InvoiceNo	FROM [dbo].[BillingInvoicing] WITH (UPDLOCK, HOLDLOCK) 	
			WHERE ModuleId = @LeaseModuleId   AND InvoiceNo LIKE 'LSI-%' AND ISNUMERIC(REPLACE(InvoiceNo, 'LSI-', '')) = 1
			ORDER BY BillingInvoicingId DESC;

			-- Get numeric portion
			SET @LastInvoiceNumber =ISNULL(TRY_CAST(REPLACE(@LastInvoiceNo, 'LSI-', '') AS INT),0);

			-- Increment
			SET @LastInvoiceNumber = @LastInvoiceNumber + 1;
			SET @NextInvoiceNo = 'LSI-' + RIGHT('000000' + CAST(@LastInvoiceNumber AS VARCHAR(20)), 6);
		
	END
	-- ================================================================================================

	DECLARE @SubTotal DECIMAL(18, 6) = 0;
	DECLARE @MiscCharges DECIMAL(18, 6) = 0;
	DECLARE @Tax DECIMAL(18, 6) = 0;
	DECLARE @OtherTaxAmt DECIMAL(18, 6) = 0;

	-- ================= Live SubTotal/GrandTotal from the selected stocklines =================
	;WITH SelectedIds AS (
		SELECT DISTINCT CAST(Item AS BIGINT) AS LeaseStocklineId
		FROM [dbo].[SplitString](@LeaseStocklineIds, ',')
		WHERE ISNUMERIC(Item) = 1
	),
	Base AS (
		SELECT
			LSL.[LeaseStocklineId],
			LSL.[QtyReserved] AS Qty,
			LSL.[BillingMethod],
			LSL.[FlatRate],
			CASE WHEN U.LeaseStocklineUsageId IS NOT NULL
				 THEN ISNULL(U.CurrentTSNHours, 0) * 60 + ISNULL(U.CurrentTSNMinutes, 0)
				 ELSE NULL END AS TimeRecorded,
			CASE WHEN LSL.MaximumTimes IS NOT NULL THEN LSL.MaximumTimes * 60 ELSE NULL END AS TimeLimit,
			LSL.OverrunPerUnitTimes AS TimeOverageRateRaw,
			U.CurrentCSN AS CycleRecorded,
			LSL.MaximumCycles AS CycleLimit,
			LSL.OverrunPerUnitCycles AS CycleOverageRateRaw,
			ISNULL(ChargesAgg.Charges, 0) AS Charges,
			LSL.[Maintenance],
			LSL.[Insurance],
			LSL.[Taxes],
			ISNULL(SC_SUM.OtherComponentAmount, 0) AS OtherComponentAmount
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		INNER JOIN SelectedIds SEL ON SEL.LeaseStocklineId = LSL.LeaseStocklineId
		LEFT JOIN [dbo].[LeaseStocklineUsage] U WITH (NOLOCK) ON U.LeaseStocklineId = LSL.LeaseStocklineId AND U.IsDeleted = 0
		OUTER APPLY (
			SELECT SUM(ISNULL(LC.ExtendedCost, 0)) AS Charges
			FROM [dbo].[LeaseCharges] LC WITH (NOLOCK)
			WHERE LC.LeaseStocklineId = LSL.LeaseStocklineId AND LC.IsDeleted = 0
		) ChargesAgg
		LEFT JOIN (
			SELECT LeaseStocklineId, SUM(ISNULL(Amount, 0)) AS OtherComponentAmount
			FROM [dbo].[LeaseStocklineServiceComponent] WITH (NOLOCK)
			WHERE IsDeleted = 0
			GROUP BY LeaseStocklineId
		) SC_SUM ON SC_SUM.LeaseStocklineId = LSL.LeaseStocklineId
		WHERE LSL.LeaseHeaderId = @LeaseHeaderId
		  AND LSL.IsDeleted = 0
		  AND LSL.QtyReserved > 0
	),
	WithOver AS (
		SELECT *,
			IsOverageBillingMethod = CASE WHEN BillingMethod IN ('FlatRatePlusOverrun', 'UsageBased') THEN 1 ELSE 0 END,
			IsFlatRateBillingMethod = CASE WHEN BillingMethod IN ('FlatRateOnly', 'FlatRatePlusOverrun') THEN 1 ELSE 0 END,
			TimeOverRaw = CASE WHEN TimeRecorded IS NOT NULL THEN
				CASE WHEN (TimeRecorded - ISNULL(TimeLimit, 0)) < 0 THEN 0 ELSE (TimeRecorded - ISNULL(TimeLimit, 0)) END
			ELSE NULL END,
			CycleOverRaw = CASE WHEN CycleRecorded IS NOT NULL THEN
				CASE WHEN (CycleRecorded - ISNULL(CycleLimit, 0)) < 0 THEN 0 ELSE (CycleRecorded - ISNULL(CycleLimit, 0)) END
			ELSE NULL END
		FROM Base
	)
	SELECT
		@SubTotal = SUM(
			ISNULL(CASE WHEN IsFlatRateBillingMethod = 1 THEN ISNULL(FlatRate, 0) * Qty ELSE 0 END, 0)
		  + ISNULL(CASE WHEN IsOverageBillingMethod = 1 AND TimeOverRaw IS NOT NULL THEN (TimeOverRaw / 60.0) * ISNULL(TimeOverageRateRaw, 0) * Qty ELSE 0 END, 0)
		  + ISNULL(CASE WHEN IsOverageBillingMethod = 1 AND CycleOverRaw IS NOT NULL THEN CycleOverRaw * ISNULL(CycleOverageRateRaw, 0) * Qty ELSE 0 END, 0)
		),
		@MiscCharges = SUM(ISNULL(Charges, 0)),
		@Tax = SUM(ISNULL(Maintenance, 0) + ISNULL(Insurance, 0) + ISNULL(Taxes, 0)),
		@OtherTaxAmt = SUM(ISNULL(OtherComponentAmount, 0))
	FROM WithOver;
	-- ============================================================================================

	SELECT TOP 1

			1 AS [ItemNo],
			1 as [IsSinglePN],
			LH.[LeaseHeaderId] AS [ReferenceId],
			LH.[CustomerId],
			CUST.[Name]  [ClientName],
			CUST.[Email] [CustEmail],
			ISNULL(CONT.[countries_name], '') [CustCountry],
			ISNULL(SP.[FirstName] + ' ' + SP.[LastName], '') [SalesPerson],

			CUSTADDRESS.[Line1]  [ClientAddressLine1],
			CUSTADDRESS.[Line2]  [ClientAddressLine2],
			CUSTADDRESS.[City]   [ClientCity],
			CUSTADDRESS.[StateOrProvince] [ClientState],
			CUSTADDRESS.[PostalCode] [ClientPostalCode],

			CUST.[CustomerPhone]  [PhoneFax],

			UPPER(ISNULL(CUST.[Name], '')) AS ShipToSiteName,
			CUSTADDRESS.[Line1] [ShipToAddressLine1],
			CUSTADDRESS.[Line2] [ShipToAddressLine2],
			CUSTADDRESS.[City]  [ShipToCity],
			CUSTADDRESS.[StateOrProvince] [ShipToState],
			CUSTADDRESS.[PostalCode] [ShipToPostalCode],
			ISNULL(CONT.[countries_name], '') [ShipToCountry],
			'' [ShipToAttention],

			UPPER(ISNULL(CUST.[Name], '')) AS BillToSiteName,
			CUSTADDRESS.[Line1] [BillToAddressLine1],
			CUSTADDRESS.[Line2] [BillToAddressLine2],
			CUSTADDRESS.[City] [BillToCity],
			CUSTADDRESS.[StateOrProvince] [BillToState],
			CUSTADDRESS.[PostalCode] [BillToPostalCode],
			ISNULL(CONT.[countries_name], '') [BillToCountry],

			CUST.[Name] [BillToNameOfCustomer],
			CUST.Email BillToCustomerEmail,
			@NextInvoiceNo [InvoiceNumber],
			FORMAT(GETUTCDATE(), 'MM/dd/yyyy h:mm tt') [DateAndTime],
			'0' [NoOfContainers],
			ISNULL(BUYERCONTACT.[FirstName] + ' ' + BUYERCONTACT.[LastName], '') [BuyersName],
			ISNULL(@CreatedBy, ISNULL(emp.[FirstName] + ' ' + emp.[LastName], '')) [PreparedBy],
			FORMAT(GETUTCDATE(), 'MM/dd/yyyy h:mm tt') [DatePrinted],
			'0' [Weight],
			'' AS [CreditTerms],
			UPPER(ISNULL(cur.[Code], '')) [Currency],
			'' [OrderDate],
			'' [ShipDate],
			'' AS [ShipVia],
			'' [ShipAccNumber],
			'' [ShippingOrderNumber],
			'' [Awb],
			NULL [InvoiceStatus],
			LH.[ManagementStructureId],
			@NextInvoiceNo [Barcode],
			LH.[UpdatedDate],
			NULL [Shipment],
			CUST.[CustomerCode],
			ISNULL(LH.[CustomerRef], '') [CustomerReference],
			CUST.[CustomerPhone] [CustToPhone],
			FORMAT(GETUTCDATE(), 'MM/dd/yyyy') [DueDate],
			Cast(DBO.ConvertUTCtoLocal(GETUTCDATE(), @CurrntEmpTimeZoneDesc) as datetime2) [NewDateAndTime],
			NULL [NewShipDate],
			Cast(DBO.ConvertUTCtoLocal(GETUTCDATE(), @CurrntEmpTimeZoneDesc) as datetime2) [NewDueDate],
			0 [IsProformaInvoice],
			0 [WorkFlowWorkOrderId],
			LH.[MasterCompanyId],
			ISNULL(@Tax, 0) [Tax],
			ISNULL(@OtherTaxAmt, 0) [OtherTax],
			@InvoiceTypeId AS InvoiceTypeId,
			REPLACE(REPLACE(ISNULL(@Notes,''), '<p>', ''),'</p>','<br />') AS [Notes],
			LH.LeaseNumber AS ReferenceNo,
			SignEmpName = ISNULL(emp.FirstName,'') + ' ' + ISNULL(emp.LastName,''),
			SignEmpTitle = ISNULL(jt.Description,''),
			SignEmpDate = GETUTCDATE(),
			ShippingTerms = '',
			ISNULL(@SubTotal, 0) AS [SubTotal],
			0 [DepositAmount],
			ISNULL(@SubTotal, 0) + ISNULL(@MiscCharges, 0) + ISNULL(@Tax, 0) + ISNULL(@OtherTaxAmt, 0) AS [GrandTotal],
			ISNULL(@MiscCharges, 0) AS [MiscCharges],
			ISNULL(@SubTotal, 0) + ISNULL(@MiscCharges, 0) + ISNULL(@Tax, 0) + ISNULL(@OtherTaxAmt, 0) [RemainingAmount],
			SHIPTOFULLADDRESS = (SELECT dbo.ValidatePDFAddress(CUSTADDRESS.[Line1],CUSTADDRESS.[Line2],NULL,CUSTADDRESS.[City],CUSTADDRESS.[StateOrProvince],CUSTADDRESS.[PostalCode],CONT.[countries_name],NULL,NULL,NULL,MC.MasterCompanyCode)),
  				BILLTOFULLADDRESS = (SELECT dbo.ValidatePDFAddress(CUSTADDRESS.[Line1],CUSTADDRESS.[Line2],NULL,CUSTADDRESS.[City],CUSTADDRESS.[StateOrProvince],CUSTADDRESS.[PostalCode],CONT.[countries_name],BUYERCONTACT.[WorkPhone],NULL,BUYERCONTACT.[Email],MC.MasterCompanyCode)),
			Cast(DBO.ConvertUTCtoLocal(GETUTCDATE(), @CurrntEmpTimeZoneDesc) as datetime2) [PrintDate],
			UPPER(inv.[Description]) InvoiceType,
			NULL OriginCountry,
			NULL DestinationCountry,
			ISNULL(CUST.ResaleNumber,'') ResaleNumber
		FROM [dbo].[LeaseHeader] LH WITH(NOLOCK)
		INNER JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON LH.[CustomerId] = CUST.[CustomerId]
		INNER JOIN [dbo].[Address] CUSTADDRESS WITH(NOLOCK) ON CUST.[AddressId] = CUSTADDRESS.[AddressId]
		LEFT JOIN [dbo].InvoiceType inv WITH(NOLOCK) ON inv.InvoiceTypeId = @InvoiceTypeId
		LEFT JOIN [dbo].[CustomerContact] BUYERCUSTCONT WITH(NOLOCK) ON LH.[CustomerContactId] = BUYERCUSTCONT.[CustomerContactId]
		LEFT JOIN [dbo].[Contact] BUYERCONTACT WITH(NOLOCK) ON BUYERCUSTCONT.[ContactId] = BUYERCONTACT.[ContactId]
		LEFT JOIN [dbo].[Employee] SP WITH(NOLOCK) ON LH.[SalespersonEmployeeId] = SP.[EmployeeId]
		LEFT JOIN [dbo].[Countries] CONT WITH(NOLOCK) ON CUSTADDRESS.[CountryId] = CONT.[countries_id]
		LEFT JOIN [dbo].[Currency] CUR WITH(NOLOCK) ON @CurrencyId = CUR.[CurrencyId]
		LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON @EmployeeId = emp.[EmployeeId]
		LEFT JOIN [dbo].[JobTitle] jt WITH(NOLOCK) ON emp.JobTitleId = jt.JobTitleId
		LEFT JOIN [dbo].[MasterCompany] MC WITH(NOLOCK) ON LH.MasterCompanyId = MC.MasterCompanyId
		WHERE LH.[LeaseHeaderId] = @LeaseHeaderId AND LH.[IsDeleted] = 0

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCommonBillingInvoicingPdfData_LeasePreview' 
			  , @ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100)) 
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