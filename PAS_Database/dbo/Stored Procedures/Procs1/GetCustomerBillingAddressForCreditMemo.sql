/*************************************************************           
 ** File:   [GetCustomerBillingAddressForCreditMemo]           
 ** Author:  Moin Bloch
 ** Description:Get Address
 ** Purpose:         
 ** Date:   20-april-2022 
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/20/2022   Moin Bloch	Created	
	2	 02/1/2024	  AMIT GHEDIYA	added isperforma Flage for SO

-- EXEC [dbo].[GetCustomerBillingAddressForCreditMemo] 68,1
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetCustomerBillingAddressForCreditMemo]
@InvoiceID bigint = null,
@IsWorkOrder bit = null,
@Type int=null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	     IF(@Type = 1)
		 BEGIN
		 IF(@IsWorkOrder = 1)
		  BEGIN
		    SELECT SiteName = shipping.SoldToName,
            AddressLine1 = shipping.SoldToAddress1,
            AddressLine2 = shipping.SoldToAddress2,
            City = shipping.SoldToCity,
            State = shipping.SoldToState,
            PostalCode = shipping.SoldToZip,
            Country = ca.countries_name 
			FROM WorkOrderBillingInvoicing bi WITH(NOLOCK)
		    INNER JOIN [WorkOrderShipping] shipping WITH(NOLOCK) ON shipping.WorkOrderShippingId=bi.WorkOrderShippingId
			INNER JOIN [Countries] ca WITH(NOLOCK) ON ca.countries_id=shipping.SoldToCountryId
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
			WHERE bi.SOBillingInvoicingId = @InvoiceID AND ISNULL(bi.IsProforma,0) = 0;
		END
	END	 
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