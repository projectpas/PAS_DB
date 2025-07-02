
/*************************************************************           
 ** File:   [dbo].[GetBillingInvoiceByShipping]          
 ** Author:   Deep Patel
 ** Description: Get Billing Data based on Shipping id.
 ** Date:   01-March-2021   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/03/2021   Deep Patel    Created
	2    02/03/2021   Deep Patel    add SO type parameter in query.
	3    06/12/2023   Vishal Suthar Updated the SP to handle invoice before shipping and versioning
	4    01/31/2024   AMIT GHEDIYA	Updated to Added IsPerforma for Billing
	5	 03/29/2024	  Bhargav Saliya Get CreditTerms From SO instead of CreditTerms
	6	 11/04/2024	  Vishal Suthar  Modified to make use of new SO Part tables
	7	 11/08/2024	  AMIT GHEDIYA   Modified to get shipping weight & ShipSize etc in item table.
	8    12/10/2024	  BHARGAV SALIA   Get SalesTotal,Freight,MiscCharges,SubTotal,SalesTax,OtherTax,GrandTotal for the standerd proforma view
	9    01/july/2025 RAJESH GAMI	 Change the table as per new Billing Structure
**************************************************************/ 
CREATE    PROCEDURE [dbo].[GetBillingInvoiceByShipping]
	@SalesOrderShippingId bigint,
	@SalesOrderPartId bigint,
	@SOBillingInvoicingId bigint
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @SOModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')
		IF(@soBillingInvoicingId > 0)
		BEGIN
			SELECT sop.SalesOrderId, sop.SalesOrderPartId, 0 AS SalesOrderShippingId, NULL AS ShipDate, so.SalesOrderNumber, CONCAT(emp.FirstName, ' ', emp.LastName) as EmployeeName,
					so.EmployeeId, so.OpenDate, so.CustomerReference as CustomerRef, so.CustomerId, CONCAT(empsp.FirstName, ' ', empsp.LastName) as SalesPerson,
					so.SalesPersonId, cf.CreditLimit, cf.CreditTermsId, so.[CreditTermName] as CreditTerm, sobi.CurrencyId,
					so.TypeId, sotype.[Name] as RevType, (ISNULL(SOR.QtyToReserve, 0) - ISNULL(sobii.QtyBilled, 0)) as NoofPieces,
					BILLTOCOUNTRY.countries_id  AS OriginCountryId, 
					SHIPTOCOUNTRY.countries_id AS ShipToCountryId, 
					--sobi.HSECCN AS HSECCN,
				  	ime.ExportECCN AS ECCN,
				  	ime.HSCODE AS HSCODE,
				  	ime.ExportWeight AS [Weight], 
				  	ime.ExportSizeLength AS BillSizeLength,
				  	ime.ExportSizeWidth AS BillSizeWidth,
				  	ime.ExportSizeWidth AS BillSizeHeight,
					sobi.EmployeeId AS SignEmpId,
					sobi.CreatedDate AS SignEmpDate,
					sobi.InvoiceNo,
					ISNULL(sobii.PartCost,0) AS SalesTotal,
					ISNULL(sobii.Freight,0) AS Freight,
					ISNULL(sobii.MiscCharges,0) AS MiscCharges,
					ISNULL(sobi.SubTotal,0) AS SubTotal,
					ISNULL(sobi.SalesTax,0) AS SalesTax,
					ISNULL(sobi.OtherTax,0) AS OtherTax,
					ISNULL(sobi.GrandTotal,0) AS GrandTotal
				FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				INNER JOIN DBO.Customer co WITH (NOLOCK) ON co.CustomerId = so.CustomerId
				LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON cf.CustomerId = co.CustomerId
				--INNER JOIN DBO.CreditTerms ct WITH (NOLOCK) ON ct.CreditTermsId = cf.CreditTermsId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON emp.EmployeeId = so.EmployeeId
				LEFT JOIN DBO.Employee empsp WITH (NOLOCK) ON empsp.EmployeeId = so.SalesPersonId
				INNER JOIN DBO.MasterSalesOrderQuoteTypes sotype WITH (NOLOCK) ON sotype.Id = so.TypeId
				LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.SubReferenceId = sop.SalesOrderPartId AND ISNULL(sobii.IsPerformaInvoice,0) = 0 AND sobii.ModuleId = @SOModuleId
				LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobii.BillingInvoicingId = sobi.BillingInvoicingId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.ModuleId = @SOModuleId
				LEFT JOIN [dbo].[BillingInvoicingDetails] BID WITH(NOLOCK) ON sobi.[BillingInvoicingId] = BID.[BillingInvoicingId]

				LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) ON sop.ItemMasterId = im.ItemMasterId
				LEFT JOIN DBO.ItemMasterExportInfo ime WITH (NOLOCK) ON im.ItemMasterId = ime.ItemMasterId

				LEFT JOIN [dbo].[Customer] BILLTOCUSTOMER WITH(NOLOCK) ON BID.[SoldToCustomerId] = BILLTOCUSTOMER.[CustomerId]		
				LEFT JOIN [dbo].[CustomerBillingAddress] BILLTOSITE WITH(NOLOCK) ON BID.[SoldToSiteId] = BILLTOSITE.[CustomerBillingAddressId]
				LEFT JOIN [dbo].[Address] BILLTOADDRESS WITH(NOLOCK) ON BILLTOSITE.[AddressId] = BILLTOADDRESS.[AddressId]
				LEFT JOIN [dbo].[Countries] BILLTOCOUNTRY WITH(NOLOCK) ON BILLTOADDRESS.[CountryId] = BILLTOCOUNTRY.[countries_id]
				
				LEFT JOIN [dbo].[Customer] SHIPTOCUSTOMER WITH(NOLOCK) ON BID.ShipToCustomerId = BILLTOCUSTOMER.[CustomerId]		
				LEFT JOIN [dbo].CustomerDomensticShipping CD WITH(NOLOCK) ON BID.ShipToCustomerId = CD.CustomerId
				LEFT JOIN [dbo].[Address] SHIPTOADDRESS WITH(NOLOCK) ON CD.[AddressId] = SHIPTOADDRESS.[AddressId]
				LEFT JOIN [dbo].[Countries] SHIPTOCOUNTRY WITH(NOLOCK) ON SHIPTOADDRESS.CountryId = SHIPTOCOUNTRY.[countries_id]

				WHERE sop.SalesOrderPartId = @SalesOrderPartId AND sobii.BillingInvoicingId = @SOBillingInvoicingId AND sobi.ModuleId = @SOModuleId;
		END
		ELSE
		BEGIN
			IF (@SalesOrderShippingId != 0)
			BEGIN
				SELECT sop.SalesOrderId, sop.SalesOrderPartId, sos.SalesOrderShippingId, sos.ShipDate, so.SalesOrderNumber, CONCAT(emp.FirstName, ' ', emp.LastName) as EmployeeName,
					so.EmployeeId, so.OpenDate, so.CustomerReference as CustomerRef, so.CustomerId, CONCAT(empsp.FirstName, ' ', empsp.LastName) as SalesPerson,
					so.SalesPersonId, cf.CreditLimit, cf.CreditTermsId, so.[CreditTermName] as CreditTerm, so.FunctionalCurrencyId,
					so.TypeId, sotype.[Name] as RevType, sosi.QtyShipped as NoofPieces,
					sos.OriginCountryId, 
					sos.ShipToCountryId, 
					--imei.ExportECCN + (CASE WHEN ISNULL(imei.HSCode,'') != '' THEN + '/' + imei.HSCode ELSE '' END) AS HSECCN,
					sop.ECCN AS ECCN,
					sop.HSCODE AS HSCODE,
					sop.[Weight], 
					sop.SizeLength AS BillSizeLength,
					sop.SizeWidth AS BillSizeWidth,
					sop.SizeHeight AS BillSizeHeight,
					emp.EmployeeId,
					0 AS InvoiceNo
				FROM DBO.SalesOrderShipping sos WITH (NOLOCK) 
				INNER JOIN DBO.SalesOrderPartV1 sop WITH (NOLOCK) ON sop.SalesOrderId = sos.SalesOrderId
				INNER JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sosi.SalesOrderShippingId = sos.SalesOrderShippingId AND sosi.SalesOrderPartId = sop.SalesOrderPartId
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				INNER JOIN DBO.Customer co WITH (NOLOCK) ON co.CustomerId = so.CustomerId
				INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = sop.ItemMasterId
				LEFT JOIN DBO.ItemMasterExportInfo imei WITH (NOLOCK) ON imei.ItemMasterId = im.ItemMasterId
				LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON cf.CustomerId = co.CustomerId
				--INNER JOIN DBO.CreditTerms ct WITH (NOLOCK) ON ct.CreditTermsId = cf.CreditTermsId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON emp.EmployeeId = so.EmployeeId
				LEFT JOIN DBO.Employee empsp WITH (NOLOCK) ON empsp.EmployeeId = so.SalesPersonId
				INNER JOIN DBO.MasterSalesOrderQuoteTypes sotype WITH (NOLOCK) ON sotype.Id = so.TypeId
				WHERE sos.SalesOrderShippingId = @SalesOrderShippingId;
			END
			ELSE
			BEGIN
				SELECT sop.SalesOrderId, sop.SalesOrderPartId, 0 AS SalesOrderShippingId, NULL AS ShipDate, so.SalesOrderNumber, CONCAT(emp.FirstName, ' ', emp.LastName) as EmployeeName,
					so.EmployeeId, so.OpenDate, so.CustomerReference as CustomerRef, so.CustomerId, CONCAT(empsp.FirstName, ' ', empsp.LastName) as SalesPerson,
					so.SalesPersonId, cf.CreditLimit, cf.CreditTermsId, so.[CreditTermName] as CreditTerm, sobi.CurrencyId,
					so.TypeId, sotype.[Name] as RevType, (ISNULL(SOR.QtyToReserve, 0) - ISNULL(sobii.QtyBilled, 0)) as NoofPieces,
					BILLTOCOUNTRY.countries_id  AS OriginCountryId, 
					SHIPTOCOUNTRY.countries_id AS ShipToCountryId, 
					--sobi.HSECCN AS HSECCN,
					--imei.ExportECCN + (CASE WHEN ISNULL(imei.HSCode,'') != '' THEN + '/' + imei.HSCode ELSE '' END) AS HSECCN,
					sop.ECCN AS ECCN,
					sop.HSCODE AS HSCODE,
					sop.[Weight] AS [Weight], 
					sop.SizeLength AS BillSizeLength,
					sop.SizeWidth AS BillSizeWidth,
					sop.SizeHeight AS BillSizeHeight,
					sobi.EmployeeId AS SignEmpId,
					sobi.CreatedDate AS SignEmpDate,
					sobi.InvoiceNo
				FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				INNER JOIN DBO.Customer co WITH (NOLOCK) ON co.CustomerId = so.CustomerId
				LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK) ON cf.CustomerId = co.CustomerId
				--INNER JOIN DBO.CreditTerms ct WITH (NOLOCK) ON ct.CreditTermsId = cf.CreditTermsId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON emp.EmployeeId = so.EmployeeId
				LEFT JOIN DBO.Employee empsp WITH (NOLOCK) ON empsp.EmployeeId = so.SalesPersonId
				INNER JOIN DBO.MasterSalesOrderQuoteTypes sotype WITH (NOLOCK) ON sotype.Id = so.TypeId
				LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.SubReferenceId = sop.SalesOrderPartId AND ISNULL(sobii.IsPerformaInvoice,0) = 0  AND sobii.ModuleId = @SOModuleId
				LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobii.BillingInvoicingId = sobi.BillingInvoicingId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.ModuleId = @SOModuleId
				LEFT JOIN [dbo].[BillingInvoicingDetails] BID WITH(NOLOCK) ON sobi.[BillingInvoicingId] = BID.[BillingInvoicingId]

				INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = sop.ItemMasterId
				LEFT JOIN DBO.ItemMasterExportInfo imei WITH (NOLOCK) ON imei.ItemMasterId = im.ItemMasterId

				LEFT JOIN [dbo].[Customer] BILLTOCUSTOMER WITH(NOLOCK) ON BID.[SoldToCustomerId] = BILLTOCUSTOMER.[CustomerId]		
				LEFT JOIN [dbo].[CustomerBillingAddress] BILLTOSITE WITH(NOLOCK) ON BID.[SoldToSiteId] = BILLTOSITE.[CustomerBillingAddressId]
				LEFT JOIN [dbo].[Address] BILLTOADDRESS WITH(NOLOCK) ON BILLTOSITE.[AddressId] = BILLTOADDRESS.[AddressId]
				LEFT JOIN [dbo].[Countries] BILLTOCOUNTRY WITH(NOLOCK) ON BILLTOADDRESS.[CountryId] = BILLTOCOUNTRY.[countries_id]
				
				LEFT JOIN [dbo].[Customer] SHIPTOCUSTOMER WITH(NOLOCK) ON BID.ShipToCustomerId = BILLTOCUSTOMER.[CustomerId]		
				LEFT JOIN [dbo].CustomerDomensticShipping CD WITH(NOLOCK) ON BID.ShipToCustomerId = CD.CustomerId
				LEFT JOIN [dbo].[Address] SHIPTOADDRESS WITH(NOLOCK) ON CD.[AddressId] = SHIPTOADDRESS.[AddressId]
				LEFT JOIN [dbo].[Countries] SHIPTOCOUNTRY WITH(NOLOCK) ON SHIPTOADDRESS.CountryId = SHIPTOCOUNTRY.[countries_id]

				WHERE sop.SalesOrderPartId = @SalesOrderPartId;
			END
		END

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'GetBillingInvoiceByShipping' 
			, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderShippingId, '') + ''
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