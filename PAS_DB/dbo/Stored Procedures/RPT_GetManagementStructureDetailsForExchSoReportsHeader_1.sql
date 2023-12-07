/*************************************************************
 ** File:     [RPT_GetManagementStructureDetailsForExchSoReportsHeader]
 ** Author:   Ekta Chandegra
 ** Description: 
 ** Purpose:
 ** Date:   12/06/2023
 ** PARAMETERS:         
 @ManagementStructId BIGINT,@MasterCompanyId BIGINT,@ExchangeSalesOrderId BIGINT
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/06/2023   Ekta Chandegra  Created

 EXECUTE RPT_GetManagementStructureDetailsForPOReportsHeader 1,1,210
**************************************************************/ 
CREATE   PROCEDURE [dbo].[RPT_GetManagementStructureDetailsForExchSoReportsHeader]
	@ManagementStructId  BIGINT  = NULL,
	@MasterCompanyId BIGINT  = NULL,
	@ExchangeSalesOrderId BIGINT = NULL
AS
	BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @ModuleId BIGINT,@ExchangeSalesOrder BIGINT, @RequestedBy BIGINT, @Email VARCHAR(100) = NULL;

				SELECT @ModuleId = AttachmentModuleId FROM dbo.AttachmentModule WITH(NOLOCK) WHERE UPPER(Name) = UPPER('LEGALENTITYLOGO');
				
				SELECT DISTINCT TOP 1
					CompanyName = Upper(le.CompanyName),
					le.CompanyCode,
					atd.Link,
					at.ModuleId,
					Address1 = Upper(ad.Line1),
					Address2 = Upper(ad.Line2),
					Address3 = Upper(ad.Line3),
					City = Upper(ad.City),
					StateOrProvince = Upper(ad.StateOrProvince),
					PostalCode = Upper(ad.PostalCode),
					Country = Upper(co.countries_name),
					PhoneNumber = Upper(le.PhoneNumber),
					PhoneExt = Upper(le.PhoneExt),
					LogoName = atd.FileName,
					AttachmentDetailId = atd.AttachmentDetailId,
					Upper(le.FAALicense) as FAALicense,
					Upper(le.EASALicense) as EASALicense,
					Upper(le.CAACLicense) as CAACLicense,
					Upper(le.TCCALicense) as TCCALicense,
					CompanyLogoPath = MS.companylogo
				FROM EntityStructureSetup est
					INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON est.Level1Id = msl.ID
					INNER JOIN LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
					INNER JOIN MasterCompany MS WITH(NOLOCK) ON MS.MasterCompanyId = le.MasterCompanyId
					JOIN dbo.Address ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
					JOIN dbo.Countries co WITH(NOLOCK) ON ad.CountryId = co.countries_id
					LEFT JOIN dbo.Attachment at WITH(NOLOCK) ON le.LegalEntityId = at.ReferenceId AND at.ModuleId = @ModuleId
					LEFT JOIN dbo.AttachmentDetails atd WITH(NOLOCK) ON at.AttachmentId = atd.AttachmentId AND atd.IsActive = 1 AND atd.IsDeleted = 0
					LEFT JOIN dbo.LegalEntityContact lec WITH(NOLOCK) ON le.LegalEntityId = lec.LegalEntityId AND lec.IsDefaultContact = 1
					LEFT JOIN dbo.Contact c WITH(NOLOCK) ON c.ContactId = lec.ContactId 
				WHERE est.EntityStructureId = @ManagementStructId;
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetManagementStructureDetailsForExchSoReportsHeader' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(@ManagementStructId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END