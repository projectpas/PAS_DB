/*************************************************************           
 ** File:   [RPT_GetCustomerBillingAddressForCreditMemo]           
 ** Author:  Amit Ghediya
 ** Description: Get Address for SSRS Report
 ** Purpose:         
 ** Date:   04/21/2023 
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/21/2023   Amit Ghediya    Created
	2	 01/02/2024	  AMIT GHEDIYA	     added isperforma Flage for SO

-- EXEC [dbo].[RPT_GetCustomerBillingAddressForCreditMemo] 131,0,1
**************************************************************/ 

CREATE   PROCEDURE [dbo].[RPT_GetCustomerBillingAddressForCreditMemo]
	@InvoiceID BIGINT = NULL,
	@IsWorkOrder BIT = NULL,
	@Type INT=NULL
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
            --AddressLine1 = shipping.SoldToAddress1,
            --AddressLine2 = shipping.SoldToAddress2,
			CASE
			WHEN shipping.SoldToAddress1 !='' OR shipping.SoldToAddress2 !='' 
			THEN 
				CASE 
					WHEN LEN(ISNULL(shipping.SoldToAddress1,'') +' '+ ISNULL(shipping.SoldToAddress2,'')) < 25
						THEN ISNULL(shipping.SoldToAddress1,'') +' '+ ISNULL(shipping.SoldToAddress2,'')
					ELSE
						LEFT(ISNULL(shipping.SoldToAddress1,'') +' '+ ISNULL(shipping.SoldToAddress2,''),25) + '....'
					END					
			ELSE
					''
			END  AS 'AddCommon',
            City = shipping.SoldToCity,
            --State = shipping.SoldToState,
            --PostalCode = shipping.SoldToZip,
			CASE
			WHEN shipping.SoldToState !='' OR shipping.SoldToZip != '' 
			THEN 
				CASE WHEN LEN(ISNULL(shipping.SoldToState,'') +', ' + ISNULL(shipping.SoldToZip,'')) < 25
					THEN ISNULL(shipping.SoldToState,'') +', ' + ISNULL(shipping.SoldToZip,'')
				ELSE
					LEFT(ISNULL(shipping.SoldToState,'') +', ' + ISNULL(shipping.SoldToZip,''),25) + '....'
				END
			ELSE
				''
			END  AS 'StatePostalCommon',
            Country = ca.countries_name 
			FROM WorkOrderBillingInvoicing bi WITH(NOLOCK)
		    INNER JOIN [WorkOrderShipping] shipping WITH(NOLOCK) ON shipping.WorkOrderShippingId=bi.WorkOrderShippingId
			INNER JOIN [Countries] ca WITH(NOLOCK) ON ca.countries_id=shipping.SoldToCountryId
			WHERE bi.BillingInvoicingId = @InvoiceID;
		END
		 IF(@IsWorkOrder = 0)
		 BEGIN
			SELECT SiteName = billToSite.SiteName,
            --AddressLine1 = billToAddress.Line1,
            --AddressLine2 = billToAddress.Line2,
			CASE
			WHEN billToAddress.Line1 !='' OR billToAddress.Line2 !='' 
			THEN 
				CASE 
					WHEN LEN(ISNULL(billToAddress.Line1,'') +' '+ ISNULL(billToAddress.Line2,'')) < 25
						THEN ISNULL(billToAddress.Line1,'') +' '+ ISNULL(billToAddress.Line2,'')
					ELSE
						LEFT(ISNULL(billToAddress.Line1,'') +' '+ ISNULL(billToAddress.Line2,''),25) + '....'
					END					
			ELSE
					''
			END  AS 'AddCommon',
            City = billToAddress.City,
            --State = billToAddress.StateOrProvince,
            --PostalCode = billToAddress.PostalCode,
			CASE
			WHEN billToAddress.StateOrProvince !='' OR billToAddress.PostalCode != '' 
			THEN 
				CASE WHEN LEN(ISNULL(billToAddress.StateOrProvince,'') +', ' + ISNULL(billToAddress.PostalCode,'')) < 25
					THEN ISNULL(billToAddress.StateOrProvince,'') +', ' + ISNULL(billToAddress.PostalCode,'')
				ELSE
					LEFT(ISNULL(billToAddress.StateOrProvince,'') +', ' + ISNULL(billToAddress.PostalCode,''),25) + '....'
				END
			ELSE
				''
			END  AS 'StatePostalCommon',
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
        , @AdhocComments     VARCHAR(150)    = 'RPT_GetCustomerBillingAddressForCreditMemo' 
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