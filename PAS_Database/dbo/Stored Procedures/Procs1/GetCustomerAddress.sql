/*************************************************************           
 ** File: GetCustomerAddress
 ** Author: Moin Bloch
 ** Description: This stored procedure is used  Address of customer
 ** Purpose:         
 ** Date:   10/05/2022        
          
 ** PARAMETERS: @customerId bigint      
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/05/2021   Moin Bloch     Created
    2	 16 Sep 2024  Bhargav Saliya address convert into single string value 
 EXEC GetCustomerAddress 11

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[GetCustomerAddress]       
@CustomerId BIGINT
AS    
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	SET NOCOUNT ON  
	BEGIN TRY
		SELECT	UPPER(ad.AddressId) AS AddressId,
				UPPER(ad.Line1) AS Address1,
				UPPER(ad.Line2) AS Address2,
				UPPER(ad.Line3) AS Address3,
				UPPER(ad.City) AS City,
				UPPER(ad.StateOrProvince) StateOrProvince,
				ad.PostalCode,
				ad.CountryId,
			    UPPER(ct.countries_name) 'Country',
				UPPER(c.Name) AS 'SiteName',
				MergedAddress = (SELECT DBO.ValidatePDFAddress(ad.Line1,ad.Line2,ad.Line3,ad.City,ad.StateOrProvince,ad.PostalCode,ct.countries_name,'','',''))
		  FROM dbo.Customer c WITH (NOLOCK) 
	     INNER JOIN dbo.Address ad WITH (NOLOCK)  ON c.AddressId = ad.AddressId
		 LEFT JOIN dbo.Countries ct WITH (NOLOCK)  ON ct.countries_id = ad.CountryId
		 WHERE c.CustomerId = @CustomerId;
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetCustomerAddress' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@CustomerId AS varchar(MAX)) ,'') +''
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