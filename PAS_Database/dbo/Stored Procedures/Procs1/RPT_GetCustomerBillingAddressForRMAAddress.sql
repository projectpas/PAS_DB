/*************************************************************           
 ** File:   [RPT_GetCustomerBillingAddressForRMAAddress]           
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
	

-- EXEC [dbo].[RPT_GetCustomerBillingAddressForRMAAddress] 68,0,0,1,0
**************************************************************/ 

CREATE     PROCEDURE [dbo].[RPT_GetCustomerBillingAddressForRMAAddress]
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
	     
			  SELECT  		        
					ISNULL(RMAA.SiteName, '') AS SiteName,
					ISNULL(RMAA.Memo, '') AS ShipToMemo,
					--ISNULL(RMAA.Line1, '') AS AddressLine1,
					--ISNULL(RMAA.Line2, '') AS AddressLine2,
					CASE
					WHEN RMAA.Line1 !='' OR RMAA.Line2 !='' 
					THEN 
						CASE 
							WHEN LEN(ISNULL(RMAA.Line1,'') +' '+ ISNULL(RMAA.Line2,'')) < 25
								THEN ISNULL(RMAA.Line1,'') +' '+ ISNULL(RMAA.Line2,'')
							ELSE
								LEFT(ISNULL(RMAA.Line1,'') +' '+ ISNULL(RMAA.Line2,''),25) + '....'
							END					
					ELSE
						''
					END  AS 'AddCommon',
					ISNULL(RMAA.City, '') AS City,
					ISNULL(RMAA.Country, '') AS Country,
					--ISNULL(RMAA.StateOrProvince, '') AS State,
					--ISNULL(RMAA.PostalCode, '') AS PostalCode,			
					CASE
					WHEN RMAA.StateOrProvince !='' OR RMAA.PostalCode != '' 
					THEN 
						CASE WHEN LEN(ISNULL(RMAA.StateOrProvince,'') +', ' + ISNULL(RMAA.PostalCode,'')) < 25
							THEN ISNULL(RMAA.StateOrProvince,'') +', ' + ISNULL(RMAA.PostalCode,'')
						ELSE
							LEFT(ISNULL(RMAA.StateOrProvince,'') +', ' + ISNULL(RMAA.PostalCode,''),25) + '....'
						END
					ELSE
						''
					END  AS 'StatePostalCommon',
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
				LEFT JOIN AllAddress RMAA WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAA.ReffranceId AND RMAA.IsShippingAdd = 1 and RMAA.ModuleId = @ModuleId
				LEFT JOIN AllAddress RMAAS WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAAS.ReffranceId AND RMAAS.IsShippingAdd = 0 and RMAAS.ModuleId = @ModuleId
			WHERE CRMA.RMAHeaderId = @RMAHeaderId
	
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'RPT_GetCustomerBillingAddressForRMAAddress' 
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