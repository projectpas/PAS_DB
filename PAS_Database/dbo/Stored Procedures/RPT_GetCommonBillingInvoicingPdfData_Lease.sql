/*************************************************************           
 ** File:   [RPT_GetCommonBillingInvoicingPdfData_Lease]           
 ** Author:  Kishor Makwana 
 ** Description: This stored procedure is used to GET Common Billing Invoicing Pdf Data (Lease)
 ** Purpose:      Report dataset for the Lease Invoice SSRS report (LeaseBilling.rdl), mirroring
 **               RPT_GetCommonBillingInvoicingPdfData_SO's column shape so the existing RDL
 **               layout (header/BillTo/ShipTo/totals/signature) can bind unchanged. Lease has no
 **               Proforma invoicing, no separate Ship-To site, and no Shipping/CreditTerms/AWB
 **               data model - those columns are still returned (so the RDL's field bindings do
 **               not break) but as blank/zero: Ship-To reuses the customer's own Bill-To address,
 **               and CreditTerms/ShippingTerms/ShipVia/Awb/Weight/NoOfContainers/OrderDate/ShipDate
 **               are returned blank. SubTotal/GrandTotal/DepositAmount come straight from
 **               BillingInvoicing (set by USP_CreateLeaseBillingInvoice) - no Proforma math.
 ** Date:   24/SEP/2026
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    24/SEP/2026   Kishor Makwana	CREATED [PN-18072]
    
--  EXEC [dbo].[RPT_GetCommonBillingInvoicingPdfData_Lease] 1,72,55
**************************************************************/
CREATE        PROCEDURE [dbo].[RPT_GetCommonBillingInvoicingPdfData_Lease]
@BillingInvoicingId BIGINT = NULL,
@ModuleId INT = NULL,
@EmployeeId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

	DECLARE @LeaseModuleId INT
	SELECT @LeaseModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Leasing';

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

	DECLARE @MiscCharges DECIMAL(18, 6) = 0;
	SELECT @MiscCharges = ISNULL(SUM(ISNULL(LC.[ExtendedCost], 0)), 0)
	FROM [dbo].[BillingInvoicingItems] BII WITH (NOLOCK)
	INNER JOIN [dbo].[LeaseCharges] LC WITH (NOLOCK) ON LC.[LeaseStocklineId] = BII.[SubReferenceId] AND LC.[IsDeleted] = 0
	WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsDeleted], 0) = 0;

	DECLARE @Tax DECIMAL(18, 6) = 0;
	SELECT @Tax = ISNULL(SUM(ISNULL(LSL.[Maintenance], 0) + ISNULL(LSL.[Insurance], 0) + ISNULL(LSL.[Taxes], 0)), 0)
	FROM [dbo].[BillingInvoicingItems] BII WITH (NOLOCK)
	INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.[LeaseStocklineId] = BII.[SubReferenceId]
	WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsDeleted], 0) = 0;

	DECLARE @OtherTaxAmt DECIMAL(18, 6) = 0;
	SELECT @OtherTaxAmt = ISNULL(SUM(ISNULL(SC.[Amount], 0)), 0)
	FROM [dbo].[BillingInvoicingItems] BII WITH (NOLOCK)
	INNER JOIN [dbo].[LeaseStocklineServiceComponent] SC WITH (NOLOCK) ON SC.[LeaseStocklineId] = BII.[SubReferenceId] AND SC.[IsDeleted] = 0
	WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsDeleted], 0) = 0;

	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) 
	  FROM [dbo].[Employee] E WITH (NOLOCK) 
	       LEFT JOIN [dbo].[TimeZone] ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		   LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		   LEFT JOIN [dbo].[TimeZone] LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; 

		IF(@ModuleId = @LeaseModuleId) /********* START: LEASE ********/
		BEGIN	
			SELECT TOP 1

					1 AS [ItemNo],
					1 as [IsSinglePN],
					BI.[ReferenceId],
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

					-- Lease has no separate Ship-To site - reuse the customer's own (Bill-To) name/address.
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
					BI.[InvoiceNo] [InvoiceNumber],
					CASE WHEN BI.[InvoiceDate] IS NOT NULL THEN FORMAT(BI.[InvoiceDate], 'MM/dd/yyyy h:mm tt') ELSE '' END [DateAndTime],
					'0' [NoOfContainers],
					ISNULL(BUYERCONTACT.[FirstName] + ' ' + BUYERCONTACT.[LastName], '') [BuyersName],
					BI.[CreatedBy] [PreparedBy],
					FORMAT(BI.[PrintDate], 'MM/dd/yyyy h:mm tt') [DatePrinted],
					'0' [Weight],
					'' AS [CreditTerms],
					UPPER(ISNULL(cur.[Code], '')) [Currency],
					'' [OrderDate],
					'' [ShipDate],
					'' AS [ShipVia],
					'' [ShipAccNumber],
					'' [ShippingOrderNumber],
					'' [Awb],
					BI.[InvoiceStatus],
					BI.[ManagementStructureId],
					BI.[InvoiceNo] [Barcode],
					LH.[UpdatedDate],
					NULL [Shipment],
					CUST.[CustomerCode],
					ISNULL(LH.[CustomerRef], '') [CustomerReference],
					CUST.[CustomerPhone] [CustToPhone],
					CASE WHEN BI.[InvoiceDate] IS NOT NULL THEN FORMAT(BI.[InvoiceDate], 'MM/dd/yyyy') ELSE '' END [DueDate],
					case when CAST(BI.[InvoiceDate] as datetime2) = CAST('0001-01-01 00:00:00' as datetime2)then null else (Cast(DBO.ConvertUTCtoLocal(BI.[InvoiceDate], @CurrntEmpTimeZoneDesc) as datetime2))end [NewDateAndTime],
					NULL [NewShipDate],
					case when CAST(BI.[InvoiceDate] as datetime2) = CAST('0001-01-01 00:00:00' as datetime2)then null else (Cast(DBO.ConvertUTCtoLocal(BI.[InvoiceDate], @CurrntEmpTimeZoneDesc) as datetime2))end [NewDueDate],
					ISNULL(BI.[IsPerformaInvoice], 0) [IsProformaInvoice],
					0 [WorkFlowWorkOrderId],
					LH.[MasterCompanyId],
					ISNULL(@Tax, 0) [Tax],
					ISNULL(@OtherTaxAmt, 0) [OtherTax],
					BI.InvoiceTypeId,
					REPLACE(REPLACE(ISNULL(BI.[Notes],''), '<p>', ''),'</p>','<br />') AS [Notes],
					LH.LeaseNumber AS ReferenceNo,
					SignEmpName = ISNULL(emp.FirstName,'') + ' ' + ISNULL(emp.LastName,''),
					SignEmpTitle = ISNULL(jt.Description,''),
					SignEmpDate = bi.CreatedDate,
					ShippingTerms = '',
					ISNULL(BI.[SubTotal], 0) - ISNULL(@MiscCharges, 0) - ISNULL(@Tax, 0) - ISNULL(@OtherTaxAmt, 0) AS [SubTotal],
					ISNULL(BI.[DepositAmount],0) [DepositAmount],
					ISNULL(BI.[GrandTotal], 0) AS [GrandTotal],
					ISNULL(@MiscCharges, 0) AS [MiscCharges],
					ISNULL(BI.[GrandTotal],0) - ISNULL(BI.[DepositAmount],0) [RemainingAmount],
					SHIPTOFULLADDRESS = (SELECT dbo.ValidatePDFAddress(CUSTADDRESS.[Line1],CUSTADDRESS.[Line2],NULL,CUSTADDRESS.[City],CUSTADDRESS.[StateOrProvince],CUSTADDRESS.[PostalCode],CONT.[countries_name],NULL,NULL,NULL,MC.MasterCompanyCode)),
  				    BILLTOFULLADDRESS = (SELECT dbo.ValidatePDFAddress(CUSTADDRESS.[Line1],CUSTADDRESS.[Line2],NULL,CUSTADDRESS.[City],CUSTADDRESS.[StateOrProvince],CUSTADDRESS.[PostalCode],CONT.[countries_name],BUYERCONTACT.[WorkPhone],NULL,BUYERCONTACT.[Email],MC.MasterCompanyCode)),
					case when CAST(GETUTCDATE() as datetime2) = CAST('0001-01-01 00:00:00' as datetime2)then null else (Cast(DBO.ConvertUTCtoLocal(GETUTCDATE(), @CurrntEmpTimeZoneDesc) as datetime2))end [PrintDate],
					UPPER(inv.[Description]) InvoiceType,
					NULL OriginCountry,
					NULL DestinationCountry,
					ISNULL(CUST.ResaleNumber,'') ResaleNumber
				FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK)
				INNER JOIN [dbo].[LeaseHeader] LH WITH(NOLOCK) ON BI.[ReferenceId] = LH.[LeaseHeaderId]
				INNER JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON LH.[CustomerId] = CUST.[CustomerId]
				INNER JOIN [dbo].[Address] CUSTADDRESS WITH(NOLOCK) ON CUST.[AddressId] = CUSTADDRESS.[AddressId]
				LEFT JOIN [dbo].InvoiceType inv WITH(NOLOCK) ON inv.InvoiceTypeId = BI.InvoiceTypeId
				LEFT JOIN [dbo].[CustomerContact] BUYERCUSTCONT WITH(NOLOCK) ON LH.[CustomerContactId] = BUYERCUSTCONT.[CustomerContactId]
				LEFT JOIN [dbo].[Contact] BUYERCONTACT WITH(NOLOCK) ON BUYERCUSTCONT.[ContactId] = BUYERCONTACT.[ContactId]
				LEFT JOIN [dbo].[Employee] SP WITH(NOLOCK) ON LH.[SalespersonEmployeeId] = SP.[EmployeeId]
				LEFT JOIN [dbo].[Countries] CONT WITH(NOLOCK) ON CUSTADDRESS.[CountryId] = CONT.[countries_id]
				LEFT JOIN [dbo].[Currency] CUR WITH(NOLOCK) ON LH.[LocalCurrencyId] = CUR.[CurrencyId]
				LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON bi.EmployeeId = emp.EmployeeId
				LEFT JOIN [dbo].[JobTitle] jt WITH(NOLOCK) ON emp.JobTitleId = jt.JobTitleId
				LEFT JOIN [dbo].[MasterCompany] MC WITH(NOLOCK) ON LH.MasterCompanyId = MC.MasterCompanyId
				WHERE BI.[BillingInvoicingId] = @BillingInvoicingId AND BI.[IsActive] = 1 AND BI.[IsDeleted] = 0 AND ISNULL(BI.[IsVersionIncrease],0) = 0

		END  /*********END: LEASE ********/
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCommonBillingInvoicingPdfData_Lease' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100)) 
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