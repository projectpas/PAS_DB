﻿/*************************************************************
 ** File:     [RPT_GetManagementStructureDetailsForROReportsHeader]
 ** Author:   Amit Ghediya
 ** Description: 
 ** Purpose:
 ** Date:   05/25/2023
 ** PARAMETERS:         
 @ManagementStructId BIGINT,@MasterCompanyId BIGINT,@PurchaseOrderId BIGINT
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/25/2023   Amit Ghediya  Created

 EXECUTE RPT_GetManagementStructureDetailsForROReportsHeader 1,1,1611
**************************************************************/ 
CREATE   PROCEDURE [dbo].[RPT_GetManagementStructureDetailsForROReportsHeader]    
(    
	@ManagementStructId  BIGINT  = NULL,
	@MasterCompanyId BIGINT  = NULL,
	@RepairOrderId BIGINT = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @ModuleId BIGINT,@IsRequestor BIT, @RequestedBy BIGINT, @Email VARCHAR(100) = NULL;

				SELECT @ModuleId = AttachmentModuleId FROM dbo.AttachmentModule WITH(NOLOCK) WHERE UPPER(Name) = UPPER('LEGALENTITYLOGO');
				SELECT @IsRequestor = IsRequestor  FROM dbo.RepairOrderSettingMaster WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;
				
				IF(@IsRequestor > 0)
				BEGIN 
					SELECT @RequestedBy = RequisitionerId FROM dbo.RepairOrder WITH(NOLOCK) WHERE RepairOrderId = @RepairOrderId;
					SELECT @Email = Email FROM dbo.Employee WITH(NOLOCK) WHERE EmployeeId = @RequestedBy;
				END
				
				SELECT DISTINCT TOP 1
				
					CompanyName = Upper(le.CompanyName),
					le.CompanyCode,
					atd.Link,
					at.ModuleId,
					(Upper(ad.Line1) +'<br/>' +
					CASE WHEN Upper(ad.Line2) is NOT NULL and Upper(ad.Line2) != '' THEN Upper(ad.Line2 )+'<br/>' ELSE '' END +
					CASE WHEN Upper(ad.City) is NOT NULL and Upper(ad.City) != '' THEN Upper(ad.City) ELSE ''END +
					CASE WHEN Upper(ad.StateOrProvince) is NOT NULL and Upper(ad.StateOrProvince) != '' THEN ' '+ Upper(ad.StateOrProvince) ELSE ''END +
					CASE WHEN Upper(ad.PostalCode) is NOT NULL and Upper(ad.PostalCode) != '' THEN ','+ Upper(ad.PostalCode)ELSE ''END +
					CASE WHEN Upper(co.countries_name) is NOT NULL and Upper(co.countries_name) != '' THEN ' '+ Upper(co.countries_name)+'<br/>'ELSE ''END +
					CASE WHEN Upper(le.PhoneNumber) is NOT NULL and Upper(le.PhoneNumber) != '' THEN Upper(le.PhoneNumber)+'<br/>'ELSE ''END +
					CASE WHEN @Email IS NULL THEN UPPER(c.Email) ELSE  UPPER(@Email) END) Address1
					,

					--Address11 = Upper(ad.Line1),
					--Address21 = Upper(ad.Line2),
					--City = Upper(ad.City),
					--StateOrProvince = Upper(ad.StateOrProvince),
					--PostalCode = Upper(ad.PostalCode),
					--Country = Upper(co.countries_name),
					--PhoneNumber = Upper(le.PhoneNumber),
					PhoneExt = Upper(le.PhoneExt),
					LogoName = atd.FileName,
					AttachmentDetailId = atd.AttachmentDetailId,
					Email = CASE WHEN @Email IS NULL THEN UPPER(c.Email) ELSE  UPPER(@Email) END,
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
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetManagementStructureDetailsForROReportsHeader' 
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