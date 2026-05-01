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
    2    30/12/2024	 EKTA CHANDEGRA	 Check IsPrimary 
    3    01/09/2025	 RAJESH GAMI	 Add LegalEntityBankingCheque details instead of LegalEntityBankingLockBox table
    4    20/04/2026	 AYUSHI PATEL	 return the BankName based on MasterCompanyCode (lower case for a2z)
    6    01/05/2026  Ayushi Patel    [PN-16030] Added MasterCompanyCode/NULL parameter in ValidatePDFAddress calls.
-- EXEC RPT_GetLockBoxBankingInfo 1
************************************************************************/
CREATE       PROCEDURE [dbo].[RPT_GetLockBoxBankingInfo] 
	@ManagementStructId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

    DECLARE @CompanyCode VARCHAR(100)='' , @MasterCompanyId INT;
	DECLARE @a2z_MasterCompanyIdCode  VARCHAR(100)='a2z';
	SET @MasterCompanyId = (SELECT TOP 1 MasterCompanyId
								FROM [dbo].[EntityStructureSetup] WITH(NOLOCK)
								WHERE EntityStructureId = @ManagementStructId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,0) = 1 );
	SET @CompanyCode = (SELECT TOP 1 MasterCompanyCode FROM dbo.MasterCompany WITH(NOLOCK) WHERE MasterCompanyId=@MasterCompanyId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,0) = 1 )
			

	SELECT TOP 1
		--CASE WHEN lb.AccountTypeId = 1 THEN UPPER(ISNULL(lb.BankName,'')) ELSE UPPER(ISNULL(lb.PayeeName,'')) END AS BankName,
        CASE 
        WHEN lb.AccountTypeId = 1 THEN 
            CASE 
                WHEN @CompanyCode = @a2z_MasterCompanyIdCode 
                    THEN (ISNULL(lb.BankName,'')) 
                ELSE UPPER(ISNULL(lb.BankName,'')) 
            END
        ELSE 
            UPPER(ISNULL(lb.PayeeName,'')) 
        END AS BankName,

		'' AS PoBox,
		MergedAddress = (SELECT dbo.ValidatePDFAddress(ad.Line1,NULL,NULL,ad.City,ad.StateOrProvince,ad.PostalCode,co.countries_name,NULL,NULL,NULL,MS.MasterCompanyCode)),
			
		UPPER(ISNULL(ad.Line1,'')) AS Line1,
		UPPER(ISNULL(ad.City,'')) AS City,
		UPPER(ISNULL(ad.StateOrProvince,'') + ',' + UPPER(ad.PostalCode)) AS StateOrProvince,
		UPPER(ISNULL(co.countries_name,'')) AS countries
	FROM 
        dbo.EntityStructureSetup ess WITH(NOLOCK)
        JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) ON ess.Level1Id = msl.ID
        JOIN dbo.LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
        LEFT JOIN MasterCompany MS WITH(NOLOCK) ON MS.MasterCompanyId = le.MasterCompanyId
        LEFT JOIN dbo.LegalEntityBankingCheque lb WITH(NOLOCK) ON le.LegalEntityId = lb.LegalEntityId AND lb.IsPrimary = 1
        LEFT JOIN dbo.[Address] ad WITH(NOLOCK) ON lb.AddressId = ad.AddressId
        LEFT JOIN dbo.Countries co WITH(NOLOCK) ON ad.CountryId = co.countries_id
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