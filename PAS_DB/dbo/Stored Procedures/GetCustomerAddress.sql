﻿

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
    1    03/05/2021   Moin Bloch    Created
     
 EXEC GetCustomerAddress 11

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[GetCustomerAddress]       
@CustomerId BIGINT
AS    
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	SET NOCOUNT ON  
	BEGIN TRY
		SELECT	ad.AddressId,
				ad.Line1 AS Address1,
				ad.Line2 AS Address2,
				ad.Line3 AS Address3,
				ad.City,
				ad.StateOrProvince,
				ad.PostalCode,
				ad.CountryId,
			    ct.countries_name 'Country',
				c.Name AS 'SiteName'
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