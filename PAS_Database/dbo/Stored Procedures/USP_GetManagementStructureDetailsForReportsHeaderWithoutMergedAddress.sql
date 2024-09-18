/*********************
 ** File:   [USP_GetManagementStructureDetailsForReportsHeaderWithoutMergedAddress]
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to get management structure details for reports header without the merged address
 ** Purpose:
 ** Date:   09/18/2024
 ** PARAMETERS:         
 @WorkOrderId BIGINT
 @WFWOId BIGINT
 ** RETURN VALUE:
 **********************
  ** Change History
 **********************
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    09/18/2024   Abhishek Jirawla			Created


 EXECUTE USP_GetManagementStructureDetailsForReportsHeaderWithoutMergedAddress 1
**********************/ 
CREATE     PROCEDURE [dbo].[USP_GetManagementStructureDetailsForReportsHeaderWithoutMergedAddress]    
(    
@ManagementStructId  BIGINT  = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		
			BEGIN
				DECLARE @ModuleId BIGINT;
				SELECT @ModuleId = AttachmentModuleId FROM dbo.AttachmentModule WITH(NOLOCK) WHERE UPPER(Name) = UPPER('LEGALENTITYLOGO')
				--DECLARE @MergedAddress NVARCHAR(MAX),@MergedAddressForCOC NVARCHAR(MAX);
				--DECLARE @Address1 NVARCHAR(255),@Address2 NVARCHAR(255),@City NVARCHAR(100),@StateOrProvince NVARCHAR(100),@PostalCode NVARCHAR(20);
				--DECLARE @Country NVARCHAR(100),@PhoneNumber NVARCHAR(50),@PhoneExt NVARCHAR(10),@Email NVARCHAR(255);


				SELECT DISTINCT TOP 1
					CompanyName = Upper(le.CompanyName),
					le.CompanyCode,
					atd.Link,
					att.ModuleId,
					Address1 = Upper(ad.Line1),
					Address2 = Upper(ad.Line2),
					City = Upper(ad.City),
					StateOrProvince = Upper(ad.StateOrProvince),
					PostalCode = Upper(ad.PostalCode),
					Country = Upper(co.countries_name),
					PhoneNumber = Upper(le.PhoneNumber),PhoneExt = Upper(le.PhoneExt),
					LogoName = atd.[FileName],
					AttachmentDetailId = atd.AttachmentDetailId,
					Upper(le.FAALicense) as FAALicense,
					Upper(le.EASALicense) as EASALicense,
					Upper(le.CAACLicense) as CAACLicense,
					Upper(le.TCCALicense) as TCCALicense,
					Upper(c.Email) as Email,
					CompanyLogoPath = MS.companylogo,
					[dbo].[ConvertUTCtoLocal](GETUTCDATE(),tz.[description])  as 'CurrentDateTime'
				FROM [dbo].EntityStructureSetup est WITH(NOLOCK)
					INNER JOIN [dbo].ManagementStructureLevel msl WITH(NOLOCK) ON est.Level1Id = msl.ID
					INNER JOIN [dbo].LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
					INNER JOIN [dbo].MasterCompany MS WITH(NOLOCK) ON MS.MasterCompanyId = le.MasterCompanyId
					JOIN [dbo].[Address] ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
					JOIN [dbo].[Countries] co WITH(NOLOCK) ON ad.CountryId = co.countries_id
					LEFT JOIN [dbo].Attachment att WITH(NOLOCK) ON le.LegalEntityId = att.ReferenceId AND att.ModuleId = @ModuleId
					LEFT JOIN [dbo].AttachmentDetails atd WITH(NOLOCK) ON att.AttachmentId = atd.AttachmentId AND atd.IsActive = 1 AND atd.IsDeleted = 0
					LEFT JOIN [dbo].LegalEntityContact lec WITH(NOLOCK) ON le.LegalEntityId = lec.LegalEntityId AND lec.IsDefaultContact = 1
					LEFT JOIN [dbo].Contact c WITH(NOLOCK) ON c.ContactId = lec.ContactId 
					LEFT JOIN [dbo].TimeZone tz WITH(NOLOCK) ON tz.TimeZoneId = le.TimeZoneId
				WHERE est.EntityStructureId = @ManagementStructId

			END
		
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetManagementStructureDetailsForReportsHeaderWithoutMergedAddress' 
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
	END CATCH
END