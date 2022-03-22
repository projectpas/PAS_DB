
/*************************************************************           
 ** File:   [USP_Reserve_ReleaseSubWorkOrderStockline]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to Reserve Or Release Stockline for Sub WO   
 ** Purpose:         
 ** Date:   08/12/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/12/2021   Hemant Saliya Created
     
 EXECUTE USP_GetManagementStructureDetailsForReportsHeader 49

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetManagementStructureDetailsForReportsHeader]    
(    
@ManagementStructId  BIGINT  = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @ModuleId BIGINT;
				SELECT @ModuleId = AttachmentModuleId FROM dbo.AttachmentModule WITH(NOLOCK) WHERE UPPER(Name) = UPPER('LEGALENTITYLOGO')

				--SELECT DISTINCT TOP 1
				--	le.CompanyName,
				--	le.CompanyCode,
				--	atd.Link,
				--	at.ModuleId,
				--	Address1 = ad.Line1,
				--	Address2 = ad.Line2,
				--	City = ad.City,
				--	StateOrProvince = ad.StateOrProvince,
				--	PostalCode = ad.PostalCode,
				--	Country = co.countries_name,
				--	PhoneNumber = le.PhoneNumber,
				--	PhoneExt = le.PhoneExt,
				--	LogoName = atd.FileName,
				--	AttachmentDetailId = atd.AttachmentDetailId,
				--	Email = c.Email,
				--	FAALicense = le.FAALicense
				--FROM ManagementStructure ms join LegalEntity le ON ms.LegalEntityId = le.LegalEntityId
				--	JOIN dbo.Address ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
				--	JOIN dbo.Countries co WITH(NOLOCK) ON ad.CountryId = co.countries_id
				--	LEFT JOIN dbo.Attachment at WITH(NOLOCK) ON le.LegalEntityId = at.ReferenceId AND at.ModuleId = @ModuleId
				--	LEFT JOIN dbo.AttachmentDetails atd WITH(NOLOCK) ON at.AttachmentId = atd.AttachmentId AND atd.IsActive = 1 AND atd.IsDeleted = 0
				--	LEFT JOIN dbo.LegalEntityContact lec WITH(NOLOCK) ON ms.LegalEntityId = lec.LegalEntityId AND lec.IsDefaultContact = 1
				--	LEFT JOIN dbo.Contact c WITH(NOLOCK) ON c.ContactId = lec.ContactId 
				--WHERE ms.ManagementStructureId = @ManagementStructId 

				SELECT DISTINCT TOP 1
					le.CompanyName,
					le.CompanyCode,
					atd.Link,
					at.ModuleId,
					Address1 = ad.Line1,
					Address2 = ad.Line2,
					City = ad.City,
					StateOrProvince = ad.StateOrProvince,
					PostalCode = ad.PostalCode,
					Country = co.countries_name,
					PhoneNumber = le.PhoneNumber,
					PhoneExt = le.PhoneExt,
					LogoName = atd.FileName,
					AttachmentDetailId = atd.AttachmentDetailId,
					Email = c.Email,
					FAALicense = le.FAALicense
				FROM ManagementStructureDetails ms 
					join ManagementStructureLevel msl WITH(NOLOCK) ON ms.Level1Id = msl.ID
					join LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
					JOIN dbo.Address ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
					JOIN dbo.Countries co WITH(NOLOCK) ON ad.CountryId = co.countries_id
					LEFT JOIN dbo.Attachment at WITH(NOLOCK) ON le.LegalEntityId = at.ReferenceId AND at.ModuleId = @ModuleId
					LEFT JOIN dbo.AttachmentDetails atd WITH(NOLOCK) ON at.AttachmentId = atd.AttachmentId AND atd.IsActive = 1 AND atd.IsDeleted = 0
					LEFT JOIN dbo.LegalEntityContact lec WITH(NOLOCK) ON le.LegalEntityId = lec.LegalEntityId AND lec.IsDefaultContact = 1
					LEFT JOIN dbo.Contact c WITH(NOLOCK) ON c.ContactId = lec.ContactId 
				WHERE ms.MSDetailsId = @ManagementStructId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetManagementStructureDetailsForReportsHeader' 
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