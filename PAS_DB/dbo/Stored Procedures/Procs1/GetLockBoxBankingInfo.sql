
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
    2    12/12/2024		EKTA CHANDEGRA	 Check IsNUll And Add Inline Html  
    3    25/12/2024		EKTA CHANDEGRA	 Check IsPrimary 
	4    16/Jul/2025    Moin Bloch	     Added UPPERCASE
    5    11/09/2025	 RAJESH GAMI	     Add LegalEntityBankingCheque details instead of LegalEntityBankingLockBox table
 EXEC GetLockBoxBankingInfo 1 
************************************************************************/  
CREATE     PROCEDURE [dbo].[GetLockBoxBankingInfo]
    @managementStructId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    SET NOCOUNT ON;
	BEGIN TRY
	SELECT TOP 1
        (
            CASE WHEN lb.AccountTypeId = 1 THEN UPPER(ISNULL(lb.BankName,'')) ELSE UPPER(ISNULL(lb.PayeeName,'')) END +'<br />'+
            (SELECT dbo.ValidatePDFAddress(ad.Line1,NULL,NULL,ad.City,ad.StateOrProvince,ad.PostalCode,co.countries_name,NULL,NULL,NULL))
        ) AS chequeTo
		--SELECT TOP 1
  --      (
  --          CASE
  --              WHEN lockbox.BankName IS NOT NULL THEN
  --                  '<label style="text-transform: uppercase;">' + UPPER(lockbox.BankName) + '</label><br />'
  --              ELSE ''
  --          END +
  --          CASE
  --              WHEN ad.Line1 IS NOT NULL THEN
  --                  '<label style="text-transform: uppercase;">' + UPPER(ad.Line1) + '</label><br />'
  --              ELSE ''
  --          END +
  --          CASE
  --              WHEN ad.City IS NOT NULL THEN
  --                  '<label style="text-transform: uppercase;">' + UPPER(ad.City) + '</label>'
  --              ELSE ''
  --          END +
  --          ',' + '<br />' +
  --          CASE
  --              WHEN ad.StateOrProvince IS NOT NULL THEN
  --                  '<label style="text-transform: uppercase;">' + UPPER(ad.StateOrProvince) + '</label>'
  --              ELSE ''
  --          END +
  --          ',' +
  --          CASE
  --              WHEN ad.PostalCode IS NOT NULL THEN
  --                  UPPER(ad.PostalCode)
  --              ELSE ''
  --          END + '<br/>' +
  --          CASE
  --              WHEN co.countries_name IS NOT NULL THEN
  --                  '<label style="text-transform: uppercase;">' + UPPER(co.countries_name) + '</label>'
  --              ELSE ''
  --          END
  --      ) AS chequeTo

		FROM [dbo].[EntityStructureSetup] ess WITH(NOLOCK)
		LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ess.Level1Id = msl.ID
		LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
		LEFT JOIN dbo.LegalEntityBankingCheque lb WITH(NOLOCK) ON le.LegalEntityId = lb.LegalEntityId AND lb.IsPrimary = 1
		LEFT JOIN [dbo].[Address] ad WITH(NOLOCK) ON lb.AddressId = ad.AddressId
		LEFT JOIN [dbo].[Countries] co WITH(NOLOCK) ON ad.CountryId = co.countries_id
		WHERE ISNULL(ess.IsActive,0) = 1
		AND ISNULL(ess.IsDeleted,0) = 0
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