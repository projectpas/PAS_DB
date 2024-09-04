/*************************************************************           
 ** File:   [RPT_GetCustomerAddressForRMA]           
 ** Author:   Amit Ghediya
 ** Description: Save Customer Get Rma Address for SSRS Report
 ** Purpose:         
 ** Date:   04/21/2023       
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/21/2023   Amit Ghediya    Created
	2	 01/02/2024	  AMIT GHEDIYA	  added isperforma Flage for SO
	3    28-08-2023   Shrey Chandegara  Modify Due to remove (...) From AddCommon and set proper length.
	4    04-09-2024   Ekta Chandegara  Retrieve address using common function
	

-- EXEC [dbo].[RPT_GetCustomerAddressForRMA] 5,65,0,1,37
**************************************************************/ 

CREATE     PROCEDURE [dbo].[RPT_GetCustomerAddressForRMA]
	@RMAHeaderId BIGINT = NULL,
	@InvoiceID BIGINT = NULL,
	@IsWorkOrder BIT = NULL,
	@Type INT = NULL,
	@ModuleId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	     IF(@Type = 1)
		 BEGIN
			 IF(@IsWorkOrder = 1)
			  BEGIN
				SELECT SiteName = billToSite.SiteName,
				--AddressLine1 = billToAddress.Line1,
				--AddressLine2 = billToAddress.Line2,
				CASE
				WHEN billToAddress.Line1 !='' OR billToAddress.Line2 !='' 
				THEN 
					CASE 
						WHEN LEN(ISNULL(billToAddress.Line1,'') +' '+ ISNULL(billToAddress.Line2,'')) <= 29
							THEN ISNULL(billToAddress.Line1,'') +' '+ ISNULL(billToAddress.Line2,'')
						ELSE
							LEFT(ISNULL(billToAddress.Line1,'') +' '+ ISNULL(billToAddress.Line2,''),29) 
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
				Country = ca.countries_name,

				MergedAddress = (SELECT dbo.ValidatePDFAddress(billToAddress.Line1,billToAddress.Line2,NULL,billToAddress.City,billToAddress.StateOrProvince,billToAddress.PostalCode,ca.countries_name,NULL,NULL,NULL))

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
				--AddressLine1 = billToAddress.Line1,
				--AddressLine2 = billToAddress.Line2,
				CASE
				WHEN billToAddress.Line1 !='' OR billToAddress.Line2 !='' 
				THEN 
					CASE 
						WHEN LEN(ISNULL(billToAddress.Line1,'') +' '+ ISNULL(billToAddress.Line2,'')) <= 29
							THEN ISNULL(billToAddress.Line1,'') +' '+ ISNULL(billToAddress.Line2,'')
						ELSE
							LEFT(ISNULL(billToAddress.Line1,'') +' '+ ISNULL(billToAddress.Line2,''),29) 
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
				Country = ca.countries_name,
				
				MergedAddress = (SELECT dbo.ValidatePDFAddress(billToAddress.Line1,billToAddress.Line2,NULL,billToAddress.City,billToAddress.StateOrProvince,billToAddress.PostalCode,ca.countries_name,NULL,NULL,NULL))

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
        , @AdhocComments     VARCHAR(150)    = 'RPT_GetCustomerAddressForRMA' 
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