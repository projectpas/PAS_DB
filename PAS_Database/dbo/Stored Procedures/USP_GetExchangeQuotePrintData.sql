/*************************************************************           
 ** File:   [USP_GetExchangeQuotePrintData]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeQuotePrintData
 ** Purpose:         
 ** Date:   07/15/2025      
          
 ** PARAMETERS:  @ExchangeQuoteId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/15/2025   Ekta Chandegra     Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
  EXEC USP_GetExchangeQuotePrintData @ExchangeQuoteId = 113
************************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[USP_GetExchangeQuotePrintData]
    @ExchangeQuoteId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT TOP 1
			so.CustomerId,
			ISNULL(cust.Name, '') AS ClientName,
			ISNULL(cust.Email, '') AS CustEmail,
			so.Notes AS SONotes,
			ISNULL(cont.countries_name, '') AS CustCountry,
			ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS SalesPerson,
			custAddress.Line1 AS AddressLine1,
			custAddress.Line2 AS AddressLine2,
			custAddress.City,
			custAddress.StateOrProvince AS State,
			custAddress.PostalCode,
			ISNULL(cust.CustomerPhone, '') AS PhoneFax,
			'BuyersName' AS BuyersName, 
			ISNULL(ct.Name, '') AS CreditTerms,
			so.ExchangeQuoteNumber AS ExchangeQuoteNum,
			FORMAT(so.OpenDate, 'MM/dd/yyyy') AS OrderDate,
			FORMAT(sop.EstimatedShipDate, 'MM/dd/yyyy') AS ShipDate,
			ISNULL((
				SELECT SUM(BillingAmount)
				FROM [dbo].[ExchangeQuoteFreight] WITH(NOLOCK)
				WHERE ExchangeQuoteId = so.ExchangeQuoteId AND ISNULL(IsActive,0) = 1 AND  ISNULL(IsDeleted,0) = 0
			), 0) AS Freight,
			ISNULL((
				SELECT SUM(BillingAmount)
				FROM [dbo].[ExchangeQuoteCharges] WITH(NOLOCK)
				WHERE ExchangeQuoteId = so.ExchangeQuoteId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0
			), 0) AS MiscCharges,
			0 AS TaxRate,
			ISNULL((sop.QtyQuoted * sop.ExchangeListPrice) / 100, 0) AS Tax,
			0 AS ShippingAndHandling,
			0 AS OtherTax,
			so.ManagementStructureId
		FROM [dbo].[ExchangeQuote] so WITH(NOLOCK)
		INNER JOIN [dbo].[Customer] cust WITH(NOLOCK) ON so.CustomerId = cust.CustomerId
		INNER JOIN [dbo].[Address] custAddress WITH(NOLOCK) ON cust.AddressId = custAddress.AddressId
		INNER JOIN [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON cust.CustomerId = cf.CustomerId
		INNER JOIN [dbo].[CreditTerms] ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
		LEFT JOIN [dbo].[ExchangeQuotePart] sop WITH(NOLOCK) ON so.ExchangeQuoteId = sop.ExchangeQuoteId
		LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON sop.ItemMasterId = itemMaster.ItemMasterId
		 AND ISNULL(itemMaster.IsNonStock,0) = 0
		 LEFT JOIN [dbo].[UnitOfMeasure] iu WITH(NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
		LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON sop.ConditionId = cp.ConditionId
		LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON so.EmployeeId = emp.EmployeeId
		LEFT JOIN [dbo].[Employee] sp WITH(NOLOCK) ON so.SalesPersonId = sp.EmployeeId
		LEFT JOIN [dbo].[Countries] cont WITH(NOLOCK) ON custAddress.CountryId = cont.countries_id
		LEFT JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON sop.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
		WHERE so.ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(so.IsActive,0) = 1 AND ISNULL(so.IsDeleted,0) = 0;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuotePrintData'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeQuoteId = ''' + CAST(ISNULL(@ExchangeQuoteId, '') AS VARCHAR(100)) 
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
		RETURN(1);
	END CATCH
END