/*************************************************************           
 ** File:   [GetCustomerBillingAddress]           
 ** Author:  
 ** Description: Get Address
 ** Purpose:         
 ** Date:   
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1								Unknown	
	2	 03/10/2024	  AMIT GHEDIYA	Upper case for address data.

-- EXEC [dbo].[GetCustomerBillingAddress] 68,1
**************************************************************/ 
CREATE PROCEDURE [dbo].[GetCustomerBillingAddress]
@Id bigint = null,
@Type int=null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		IF(@Type = 9)
		BEGIN
			SELECT UPPER(ad.Line1) AS Line1,UPPER(ad.Line2) AS 'Line2',UPPER(ad.Line3) AS 'Line3',UPPER(ad.City) AS 'City',UPPER(ad.StateOrProvince) AS 'StateOrProvince',UPPER(ad.PostalCode) AS 'PostalCode',UPPER(ca.countries_name) AS 'CountryName',UPPER(LEA.SiteName) AS 'SiteName' from LegalEntityBillingAddress LEA WITH(NOLOCK)
			INNER JOIN [Address] ad WITH(NOLOCK) ON ad.AddressId=LEA.AddressId
			INNER JOIN [Countries] ca WITH(NOLOCK) ON ca.countries_id=ad.CountryId
			WHERE LEA.LegalEntityBillingAddressId = @ID;
		END
		IF(@Type = 1)
		BEGIN
			SELECT UPPER(ad.Line1) AS 'Line1',UPPER(ad.Line2) AS 'Line2',UPPER(ad.Line3) AS 'Line3',UPPER(ad.City) AS 'City',UPPER(ad.StateOrProvince) AS 'StateOrProvince',UPPER(ad.PostalCode) AS 'PostalCode',UPPER(ca.countries_name) AS 'CountryName',UPPER(CBA.SiteName) AS 'SiteName' from CustomerBillingAddress CBA WITH(NOLOCK)
			INNER JOIN [Address] ad WITH(NOLOCK) ON ad.AddressId=CBA.AddressId
			INNER JOIN [Countries] ca WITH(NOLOCK) ON ca.countries_id=ad.CountryId
			WHERE CBA.CustomerBillingAddressId = @ID;
		END
		IF(@Type = 2)
		BEGIN
			SELECT UPPER(ad.Line1) AS 'Line1',UPPER(ad.Line2) AS 'Line2',UPPER(ad.Line3) AS 'Line3',UPPER(ad.City) AS 'City',UPPER(ad.StateOrProvince) AS 'StateOrProvince',UPPER(ad.PostalCode) AS 'PostalCode',UPPER(ca.countries_name) AS 'CountryName',UPPER(VBA.SiteName) AS 'SiteName' from VendorBillingAddress VBA WITH(NOLOCK)
			INNER JOIN [Address] ad WITH(NOLOCK) ON ad.AddressId=VBA.AddressId
			INNER JOIN [Countries] ca WITH(NOLOCK) ON ca.countries_id=ad.CountryId
			WHERE VBA.VendorBillingAddressId = @ID;
		END
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetCustomerBillingAddress' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@Id AS VARCHAR(10)), '') + ''
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