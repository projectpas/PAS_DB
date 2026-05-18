/*************************************************************           
 ** File:   [RPT_GetCustomerBillingAddressForRMA]           
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
	2    04-09-2024   Ekta Chandegara  Retrieve address using common function
	3    01/05/2026   Ayushi Patel     [PN-16030] Added MasterCompanyCode/NULL parameter in ValidatePDFAddress calls.
	4    12/05/2026   Ayushi Patel     [PN-16030] Added A2Z-specific SiteName casing logic for Company user type.

-- EXEC [dbo].[RPT_GetCustomerBillingAddressForRMA] 5,65,0,1,37
**************************************************************/ 

CREATE     PROCEDURE [dbo].[RPT_GetCustomerBillingAddressForRMA]
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
			DECLARE @CompanyId BIGINT;
			SELECT @CompanyId = ModuleId FROM Module WHERE ModuleName = 'Company';

			DECLARE @A2ZMasterCompanyCode VARCHAR(50);
			SELECT @A2ZMasterCompanyCode = MasterCompanyCode FROM DBO.MasterCompany WITH(NOLOCK) WHERE UPPER(MasterCompanyCode) = UPPER('A2Z');
			  
			  SELECT  		        
					--ISNULL(RMAA.SiteName, '') AS BillSiteName,
					CASE 
						WHEN RMAA.UserType = @CompanyId 
							 AND UPPER(MS.MasterCompanyCode) = UPPER(@A2ZMasterCompanyCode)
						THEN ISNULL(RMAA.SiteName, '')
						ELSE UPPER(ISNULL(RMAA.SiteName, ''))
					END AS BillSiteName,
					ISNULL(RMAA.Memo, '') AS BillShipToMemo,
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
					END  AS 'BillingAddCommon',
					ISNULL(RMAA.City, '') AS BillCity,
					ISNULL(RMAA.Country, '') AS BillCountry,
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
					END  AS 'BillingStatePostalCommon',
					--ISNULL(RMAAS.SiteName, '') AS BillToSiteName,
					--ISNULL(RMAAS.ContactId, 0) AS BillToContactId,
					--ISNULL(RMAAS.ContactName, '') AS BillToContactName,			
					--ISNULL(RMAAS.Memo, '') AS BillToMemo,
					--ISNULL(RMAAS.AddressId, 0) AS BillToAddressId,
					--ISNULL(RMAAS.PostalCode, '') AS BillToPostalCode,
					--ISNULL(RMAAS.Line1, '') AS BillToAddress1,
					--ISNULL(RMAAS.Line2, '') AS BillToAddress2,
					--ISNULL(RMAAS.City, '') AS BillToCity,
					--ISNULL(RMAAS.CountryId, 0) AS BillToCountryId,
					--ISNULL(RMAAS.Country, '') AS BillToCountryName,
					--ISNULL(RMAAS.StateOrProvince, '') AS BillToState,
					--ISNULL(RMAAS.PostalCode, '') AS BillToPostalCode
				MergedAddress = (SELECT dbo.ValidatePDFAddress(RMAA.Line1,RMAA.Line2,NULL,RMAA.City,RMAA.StateOrProvince,RMAA.PostalCode,RMAA.Country,NULL,NULL,NULL,MS.MasterCompanyCode))
			FROM CustomerRMAHeader CRMA  WITH (NOLOCK)
				LEFT JOIN [dbo].[MasterCompany] MS WITH(NOLOCK) ON CRMA.MasterCompanyId = MS.MasterCompanyId
				LEFT JOIN AllAddress RMAA WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAA.ReffranceId AND RMAA.IsShippingAdd = 1 and RMAA.ModuleId = @ModuleId
				LEFT JOIN AllAddress RMAAS WITH (NOLOCK) ON CRMA.RMAHeaderId = RMAAS.ReffranceId AND RMAAS.IsShippingAdd = 0 and RMAAS.ModuleId = @ModuleId
			WHERE CRMA.RMAHeaderId = @RMAHeaderId
	
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'RPT_GetCustomerBillingAddressForRMA' 
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