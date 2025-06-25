/*************************************************************           
 ** File:   [GetSalesOrderPrintDataById]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetSalesOrderPrintDataById
 ** Purpose:         
 ** Date:   06/24/2025      
          
 ** PARAMETERS:  @ExchangeSalesOrderPartId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/24/2025   Ekta Chandegra     Created
     
-- EXEC GetSalesOrderPrintDataById @ExchangeSalesOrderPartId=151
************************************************************************/
CREATE   PROCEDURE [dbo].[GetSalesOrderPrintDataById]
    @ExchangeSalesOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @IsVendor BIT;
		DECLARE @ExchangeModuleId INT;

		SELECT @ExchangeModuleId =  ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'ExchangeSalesOrder';

		SELECT @IsVendor = 
			CASE WHEN IsVendor IS NOT NULL THEN CAST(IsVendor AS BIT) ELSE 0 END
		FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
		WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId;

		IF @IsVendor = 1
		BEGIN
			-- Vendor Logic
			SELECT TOP 1
				so.CustomerId,
				ISNULL(v.VendorName, '') AS ClientName,
				ISNULL(v.VendorEmail, '') AS CustEmail,
				so.Notes AS SONotes,
				'' AS PORONum,
				ISNULL(cn.countries_name, '') AS CustCountry,
				ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS SalesPerson,
				a.Line1 AS AddressLine1,
				a.Line2 AS AddressLine2,
				a.City,
				a.StateOrProvince,
				a.PostalCode,
				ISNULL(v.VendorPhone, '') AS PhoneFax,
				'BuyersName' AS BuyersName,
				ct.Name AS CreditTerms,
				ISNULL(cur.DisplayName, '') AS Currency,
				so.ExchangeSalesOrderNumber AS SONum,
				FORMAT(so.OpenDate, 'MM/dd/yyyy') AS OrderDate,
				FORMAT(sop.EstimatedShipDate, 'MM/dd/yyyy') AS ShipDate,
				sos.AirwayBill AS Awb,
				ISNULL(
					CASE 
						WHEN so.IsFreightFlatRate = 1 THEN ISNULL(so.FreightFlatRate, 0)
						ELSE (SELECT SUM(ISNULL(BillingAmount, 0)) 
							  FROM [dbo].[ExchangeSalesOrderFreight] WITH(NOLOCK) 
							  WHERE ExchangeSalesOrderId = so.ExchangeSalesOrderId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0)
					END, 0) AS Freight,
				ISNULL(
					CASE 
						WHEN so.IsChargeFlatRate = 1 THEN ISNULL(so.ChargeFlatRate, 0)
						ELSE (SELECT SUM(ISNULL(BillingAmount, 0)) 
							  FROM [dbo].[ExchangeSalesOrderCharges] WITH(NOLOCK) 
							  WHERE ExchangeSalesOrderId = so.ExchangeSalesOrderId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0)
					END, 0) AS MiscCharges,
				ISNULL(sop.QtyQuoted * sop.ExchangeListPrice / 100, 0) AS Tax,
				0 AS ShippingAndHandling,
				0 AS OtherTax,
				so.ManagementStructureId,
				ISNULL(sv.Name, '') AS ShipVia,
				ISNULL(asv.ShippingAccountNo, '') AS ShipAccNumber,
				ISNULL(asv.ShippingTerms, '') AS ShippingTerms
			FROM [dbo].[ExchangeSalesOrder] so WITH(NOLOCK)
			LEFT JOIN [dbo].[ExchangeSalesOrderPart] sop WITH(NOLOCK) ON so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
			LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON so.CustomerId = v.VendorId
			LEFT JOIN [dbo].[Address] a WITH(NOLOCK) ON v.AddressId = a.AddressId
			LEFT JOIN [dbo].[Countries] cn WITH(NOLOCK) ON a.CountryId = cn.countries_id
			LEFT JOIN [dbo].[Employee] sp WITH(NOLOCK) ON so.SalesPersonId = sp.EmployeeId
			LEFT JOIN [dbo].[CreditTerms] ct WITH(NOLOCK) ON v.CreditTermsId = ct.CreditTermsId
			LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON so.CurrencyId = cur.CurrencyId
			LEFT JOIN [dbo].[ExchangeSalesOrderShipping] sos WITH(NOLOCK) ON so.ExchangeSalesOrderId = sos.ExchangeSalesOrderId
			LEFT JOIN [dbo].[ShippingVia] sv WITH(NOLOCK) ON sos.ShipviaId = sv.ShippingViaId
			LEFT JOIN [dbo].[AllShipVia] asv WITH(NOLOCK) ON so.ExchangeSalesOrderId = asv.ReferenceId AND asv.ModuleId = @ExchangeModuleId
			WHERE so.ExchangeSalesOrderId = @ExchangeSalesOrderId AND ISNULL(so.IsActive,0) = 1 AND ISNULL(so.IsDeleted,0) = 0;

		END
		ELSE
		BEGIN
			-- Customer Logic
			SELECT TOP 1
				so.CustomerId,
				ISNULL(c.Name, '') AS ClientName,
				ISNULL(c.Email, '') AS CustEmail,
				so.Notes AS SONotes,
				'' AS PORONum,
				ISNULL(cn.countries_name, '') AS CustCountry,
				ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS SalesPerson,
				a.Line1 AS AddressLine1,
				a.Line2 AS AddressLine2,
				a.City,
				a.StateOrProvince,
				a.PostalCode,
				ISNULL(c.CustomerPhone, '') AS PhoneFax,
				'BuyersName' AS BuyersName,
				ct.Name AS CreditTerms,
				ISNULL(cur.DisplayName, '') AS Currency,
				so.ExchangeSalesOrderNumber AS SONum,
				FORMAT(so.OpenDate, 'MM/dd/yyyy') AS OrderDate,
				FORMAT(sop.EstimatedShipDate, 'MM/dd/yyyy') AS ShipDate,
				sos.AirwayBill AS Awb,
				ISNULL(
					CASE 
						WHEN so.IsFreightFlatRate = 1 THEN ISNULL(so.FreightFlatRate, 0)
						ELSE (SELECT SUM(ISNULL(BillingAmount, 0)) 
							  FROM [dbo].[ExchangeSalesOrderFreight]  WITH(NOLOCK)  
							  WHERE ExchangeSalesOrderId = so.ExchangeSalesOrderId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0)
					END, 0) AS Freight,
				ISNULL(
					CASE 
						WHEN so.IsChargeFlatRate = 1 THEN ISNULL(so.ChargeFlatRate, 0)
						ELSE (SELECT SUM(ISNULL(BillingAmount, 0)) 
							  FROM [dbo].[ExchangeSalesOrderCharges] WITH(NOLOCK)   
							  WHERE ExchangeSalesOrderId = so.ExchangeSalesOrderId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0)
					END, 0) AS MiscCharges,
				ISNULL(sop.QtyQuoted * sop.ExchangeListPrice / 100, 0) AS Tax,
				0 AS ShippingAndHandling,
				0 AS OtherTax,
				so.ManagementStructureId,
				ISNULL(sv.Name, '') AS ShipVia,
				ISNULL(asv.ShippingAccountNo, '') AS ShipAccNumber,
				ISNULL(asv.ShippingTerms, '') AS ShippingTerms
			FROM [dbo].[ExchangeSalesOrder] so WITH(NOLOCK)  
			LEFT JOIN [dbo].[ExchangeSalesOrderPart] sop WITH(NOLOCK)   ON so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
			LEFT JOIN [dbo].[Customer] c WITH(NOLOCK) ON so.CustomerId = c.CustomerId
			LEFT JOIN [dbo].[Address] a WITH(NOLOCK) ON c.AddressId = a.AddressId
			LEFT JOIN [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON c.CustomerId = cf.CustomerId
			LEFT JOIN [dbo].[Countries] cn WITH(NOLOCK) ON a.CountryId = cn.countries_id
			LEFT JOIN [dbo].[Employee] sp WITH(NOLOCK) ON so.SalesPersonId = sp.EmployeeId
			LEFT JOIN [dbo].[CreditTerms] ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
			LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON so.CurrencyId = cur.CurrencyId
			LEFT JOIN [dbo].[ExchangeSalesOrderShipping] sos WITH(NOLOCK) ON so.ExchangeSalesOrderId = sos.ExchangeSalesOrderId
			LEFT JOIN [dbo].[ShippingVia] sv WITH(NOLOCK) ON sos.ShipviaId = sv.ShippingViaId
			LEFT JOIN [dbo].[AllShipVia] asv WITH(NOLOCK) ON so.ExchangeSalesOrderId = asv.ReferenceId AND asv.ModuleId = @ExchangeModuleId
			WHERE so.ExchangeSalesOrderId = @ExchangeSalesOrderId AND ISNULL(so.IsActive,0) = 1 AND ISNULL(so.IsDeleted,0) = 0;
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderPrintDataById'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderPartId = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS VARCHAR(100))
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