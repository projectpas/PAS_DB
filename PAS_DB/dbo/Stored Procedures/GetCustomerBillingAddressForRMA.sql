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
			FROM WorkOrderBillingInvoicing bi WITH(NOLOCK)
		     INNER JOIN Customer billToCustomer WITH(NOLOCK) ON bi.SoldToCustomerId=billToCustomer.CustomerId
			 INNER JOIN [CustomerBillingAddress] billToSite WITH(NOLOCK) ON billToSite.CustomerBillingAddressId=bi.SoldToSiteId
			 INNER JOIN [Address] billToAddress WITH(NOLOCK) ON billToAddress.AddressId=billToSite.AddressId
			 INNER JOIN [Countries] ca WITH(NOLOCK) ON ca.countries_id=billToAddress.CountryId
			WHERE bi.BillingInvoicingId = @InvoiceID;
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
			FROM SalesOrderBillingInvoicing bi WITH(NOLOCK)
		     INNER JOIN Customer billToCustomer WITH(NOLOCK) ON bi.BillToCustomerId=billToCustomer.CustomerId
			 INNER JOIN [CustomerBillingAddress] billToSite WITH(NOLOCK) ON billToSite.CustomerBillingAddressId=bi.BillToSiteId
			 INNER JOIN [Address] billToAddress WITH(NOLOCK) ON billToAddress.AddressId=billToSite.AddressId
			 INNER JOIN [Countries] ca WITH(NOLOCK) ON ca.countries_id=billToAddress.CountryId
			WHERE bi.SOBillingInvoicingId = @InvoiceID;
		END
		 end
		 else
		 begin
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
			
		FROM CustomerRMAHeader CRMA  WITH (NOLOCK)
			LEFT JOIN AllAddress RMAA WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAA.ReffranceId AND RMAA.IsShippingAdd = 1 and RMAA.ModuleId = @ModuleID
			LEFT JOIN AllAddress RMAAS WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAAS.ReffranceId AND RMAAS.IsShippingAdd = 0 and RMAAS.ModuleId = @ModuleID
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