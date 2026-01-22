/*************************************************************           
 ** File:   [GetCustomerBillingAddressForRMA]           
 ** Author:   Subhash Saliya
 ** Description: Save Customer Get Rma Address
 ** Purpose:         
 ** Date:   20-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/20/2022   Subhash Saliya Created
	2	 01/02/2024	  AMIT GHEDIYA	 added isperforma Flage for SO
	3    07-07-2025   Moin Bloch     Changed Old To New Billing Table

-- EXEC [dbo].[GetCustomerBillingAddressForRMA] 68,1
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetCustomerBillingAddressForRMA]
@RMAHeaderId bigint = null,
@InvoiceID bigint = null,
@IsWorkOrder bit = null,
@Type int=null,
@ModuleID int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @WOModuleId INT
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

		DECLARE @SOModuleId INT
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

	     IF(@Type = 1)
		 begin
		 IF(@IsWorkOrder = 1)
		  BEGIN

		    SELECT SiteName = billToSite.SiteName,
            AddressLine1 = billToAddress.Line1,
            AddressLine2 = billToAddress.Line2,
            City = billToAddress.City,
            State = billToAddress.StateOrProvince,
            PostalCode = billToAddress.PostalCode,
            Country = ca.countries_name 
			FROM dbo.BillingInvoicing bi WITH(NOLOCK)
			 INNER JOIN dbo.BillingInvoicingDetails bd WITH(NOLOCK) ON bi.BillingInvoicingId =  bd.BillingInvoicingId
		     INNER JOIN dbo.Customer billToCustomer WITH(NOLOCK) ON bd.SoldToCustomerId=billToCustomer.CustomerId
			 INNER JOIN dbo.[CustomerBillingAddress] billToSite WITH(NOLOCK) ON billToSite.CustomerBillingAddressId=bd.SoldToSiteId
			 INNER JOIN dbo.[Address] billToAddress WITH(NOLOCK) ON billToAddress.AddressId=billToSite.AddressId
			 INNER JOIN dbo.[Countries] ca WITH(NOLOCK) ON ca.countries_id=billToAddress.CountryId
			WHERE bi.BillingInvoicingId = @InvoiceID AND bi.[ModuleId] = @WOModuleId

		END
		 IF(@IsWorkOrder = 0)
		 BEGIN
			SELECT SiteName = billToSite.SiteName,
            AddressLine1 = billToAddress.Line1,
            AddressLine2 = billToAddress.Line2,
            City = billToAddress.City,
            State = billToAddress.StateOrProvince,
            PostalCode = billToAddress.PostalCode,
            Country = ca.countries_name 
			FROM dbo.BillingInvoicing bi WITH(NOLOCK)
			INNER JOIN  dbo.BillingInvoicingDetails bd WITH(NOLOCK) ON bi.BillingInvoicingId =  bd.BillingInvoicingId
		     INNER JOIN dbo.Customer billToCustomer WITH(NOLOCK) ON bd.SoldToCustomerId=billToCustomer.CustomerId
			 INNER JOIN dbo.[CustomerBillingAddress] billToSite WITH(NOLOCK) ON billToSite.CustomerBillingAddressId=bd.SoldToSiteId
			 INNER JOIN dbo.[Address] billToAddress WITH(NOLOCK) ON billToAddress.AddressId=billToSite.AddressId
			 INNER JOIN dbo.[Countries] ca WITH(NOLOCK) ON ca.countries_id=billToAddress.CountryId
			WHERE bi.BillingInvoicingId = @InvoiceID AND ISNULL(bi.IsPerformaInvoice,0) = 0 AND bi.[ModuleId] = @SOModuleId
		END
		 END
		 ELSE
		 BEGIN
		   SELECT  
		        
				ISNULL(RMAA.SiteName, '') AS SiteName,
				ISNULL(RMAA.Memo, '') AS ShipToMemo,
				ISNULL(RMAA.Line1, '') AS AddressLine1,
				ISNULL(RMAA.Line2, '') AS AddressLine2,
				ISNULL(RMAA.City, '') AS City,
				ISNULL(RMAA.Country, '') AS Country,
				ISNULL(RMAA.StateOrProvince, '') AS State,
				ISNULL(RMAA.PostalCode, '') AS PostalCode,

			
				ISNULL(RMAAS.SiteName, '') AS BillToSiteName,
				ISNULL(RMAAS.ContactId, 0) AS BillToContactId,
				ISNULL(RMAAS.ContactName, '') AS BillToContactName,			
				ISNULL(RMAAS.Memo, '') AS BillToMemo,
				ISNULL(RMAAS.AddressId, 0) AS BillToAddressId,
				ISNULL(RMAAS.PostalCode, '') AS BillToPostalCode,
				ISNULL(RMAAS.Line1, '') AS BillToAddress1,
				ISNULL(RMAAS.Line2, '') AS BillToAddress2,
				ISNULL(RMAAS.City, '') AS BillToCity,
				ISNULL(RMAAS.CountryId, 0) AS BillToCountryId,
				ISNULL(RMAAS.Country, '') AS BillToCountryName,
				ISNULL(RMAAS.StateOrProvince, '') AS BillToState,
				ISNULL(RMAAS.PostalCode, '') AS BillToPostalCode
			
		FROM dbo.CustomerRMAHeader CRMA  WITH (NOLOCK)
			LEFT JOIN dbo.AllAddress RMAA WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAA.ReffranceId AND RMAA.IsShippingAdd = 1 and RMAA.ModuleId = @ModuleID
			LEFT JOIN dbo.AllAddress RMAAS WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAAS.ReffranceId AND RMAAS.IsShippingAdd = 0 and RMAAS.ModuleId = @ModuleID
		WHERE CRMA.RMAHeaderId = @RMAHeaderId
		 end
	
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetCustomerBillingAddressForRMA' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@InvoiceID AS VARCHAR(10)), '') + ''
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