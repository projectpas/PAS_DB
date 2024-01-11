/*************************************************************           
 ** File:  [RPT_GetLockBoxBankingInfo]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to Get Print GetLockBoxBankingInfo Data By ManagementStructId
 ** Purpose:         
 ** Date:   01/10/2024      
          
 ** PARAMETERS: @ManagementStructId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/10/2024  Amit Ghediya    Created
     
-- EXEC RPT_GetLockBoxBankingInfo 1
************************************************************************/
CREATE       PROCEDURE [dbo].[RPT_GetLockBoxBankingInfo] 
	@ManagementStructId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	SELECT TOP 1
		UPPER(ISNULL(lb.BankName,'')) AS BankName,
		'' AS PoBox,
		UPPER(ISNULL(ad.Line1,'')) AS Line1,
		UPPER(ISNULL(ad.City,'')) AS City,
		UPPER(ISNULL(ad.StateOrProvince,'') + ',' + UPPER(ad.PostalCode)) AS StateOrProvince,
		UPPER(ISNULL(co.countries_name,'')) AS countries
	FROM 
        EntityStructureSetup ess
        JOIN ManagementStructureLevel msl ON ess.Level1Id = msl.ID
        JOIN LegalEntity le ON msl.LegalEntityId = le.LegalEntityId
        LEFT JOIN LegalEntityBankingLockBox lb ON le.LegalEntityId = lb.LegalEntityId
        LEFT JOIN Address ad ON lb.AddressId = ad.AddressId
        LEFT JOIN Countries co ON ad.CountryId = co.countries_id
    WHERE 
        ess.IsActive = 1 
        AND ess.IsDeleted = 0 
        AND ess.EntityStructureId = @ManagementStructId

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'RPT_GetLockBoxBankingInfo' 
        ,@ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@ManagementStructId, '') AS varchar(100))			   
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