/*************************************************************             
 ** File:   [GetLockBoxBankingInfo]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetLockBoxBankingInfo
 ** Purpose:           
 ** Date:  09/12/2024        
            
 ** PARAMETERS: @ManagementStructId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    09/12/2024		EKTA CHANDEGRA	 Created  

 EXEC GetLockBoxBankingInfo 1 
************************************************************************/  
CREATE   PROCEDURE [dbo].[GetLockBoxBankingInfo]
    @managementStructId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT TOP 1
		UPPER(lockbox.BankName) AS BankName,
		UPPER(ad.Line1) AS Line1,
		UPPER(ad.City) AS City,
		UPPER(ad.StateOrProvince) AS StateOrProvince,
		UPPER(ad.PostalCode) AS PostalCode,
		UPPER(co.countries_name) AS countries_name

		FROM [dbo].[EntityStructureSetup] ess WITH(NOLOCK)
		LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ess.Level1Id = msl.ID
		LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
		LEFT JOIN [dbo].[LegalEntityBankingLockBox] lockbox WITH(NOLOCK) ON le.LegalEntityId = lockbox.LegalEntityId
		LEFT JOIN [dbo].[Address] ad WITH(NOLOCK) ON lockbox.AddressId = ad.AddressId
		LEFT JOIN [dbo].[Countries] co WITH(NOLOCK) ON ad.CountryId = co.countries_id
		WHERE ess.IsActive = 1
		AND ess.IsDeleted = 0
		AND ess.EntityStructureId = @managementStructId
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetLockBoxBankingInfo'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@managementStructId, '') + ''
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