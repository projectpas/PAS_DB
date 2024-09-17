/*********************
 ** File:   [USP_GetManagementStructureDetailsForReportsHeader]
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to Reserve Or Release Stockline for Sub WO
 ** Purpose:
 ** Date:   08/12/2021
 ** PARAMETERS:         
 @WorkOrderId BIGINT
 @WFWOId BIGINT
 ** RETURN VALUE:
 **********************
  ** Change History
 **********************
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    08/12/2021   Hemant Saliya			Created
    2    09/08/2021   Devendra Shekh		added CurrentDateTime field
    3    12/08/2024   Ekta Chandegra		Retrieve Address
    4    13/08/2024   Devendra Shekh		added Email to select
	5    17/09/2024   RAJESH GAMI		    Added the SP for MERGEADDRESS instead of function


 EXECUTE USP_GetManagementStructureDetailsForReportsHeader 1
**********************/ 
CREATE   PROCEDURE [dbo].[USP_GetManagementStructureDetailsForReportsHeader]    
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
				print @ModuleId
				DECLARE @MergedAddress NVARCHAR(MAX),@MergedAddressForCOC NVARCHAR(MAX);
				DECLARE @Address1 NVARCHAR(255),@Address2 NVARCHAR(255),@City NVARCHAR(100),@StateOrProvince NVARCHAR(100),@PostalCode NVARCHAR(20);
				DECLARE @Country NVARCHAR(100),@PhoneNumber NVARCHAR(50),@PhoneExt NVARCHAR(10),@Email NVARCHAR(255);

			
					 SELECT 
						@Address1 = ad.Line1,
						@Address2 = ad.Line2,
						@City = ad.City,
						@StateOrProvince = ad.StateOrProvince,
						@PostalCode = ad.PostalCode,
						@Country = co.countries_name,
						@PhoneNumber = le.PhoneNumber,
						@PhoneExt = le.PhoneExt,
						@Email = c.Email
						FROM EntityStructureSetup est
							INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON est.Level1Id = msl.ID
							INNER JOIN LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
							JOIN dbo.Address ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
							JOIN dbo.Countries co WITH(NOLOCK) ON ad.CountryId = co.countries_id
							LEFT JOIN dbo.LegalEntityContact lec WITH(NOLOCK) ON le.LegalEntityId = lec.LegalEntityId AND lec.IsDefaultContact = 1
							LEFT JOIN dbo.Contact c WITH(NOLOCK) ON c.ContactId = lec.ContactId 
						WHERE est.EntityStructureId = @ManagementStructId
				
				EXEC [dbo].[SP_ValidatePDFAddress] 
                @Address1 = @Address1,
                @Address2 = @Address2,
                @Address3 = NULL,
                @City = @City,
                @StateOrProvince = @StateOrProvince,
                @PostalCode = @PostalCode,
                @Country = @Country,
                @PhoneNumber = @PhoneNumber,
                @PhoneExt = @PhoneExt,
                @Email = @Email,
                @AddressOutput = @MergedAddress OUTPUT;

				EXEC [dbo].[SP_ValidatePDFAddress] 
                @Address1 = @Address1,
                @Address2 = NULL,
                @Address3 = NULL,
                @City = @City,
                @StateOrProvince = @StateOrProvince,
                @PostalCode = @PostalCode,
                @Country = NULL,
                @PhoneNumber = NULL,
                @PhoneExt = NULL,
                @Email = NULL,
                @AddressOutput = @MergedAddressForCOC OUTPUT;
			SELECT *
			INTO #TempDestinationTable
				FROM 

				(SELECT DISTINCT TOP 1
					CompanyName = Upper(le.CompanyName),
					le.CompanyCode,
					atd.Link,
					at.ModuleId,
					MergedAddress = @MergedAddress,
					--MergedAddress = (SELECT dbo.ValidatePDFAddress(ad.Line1,ad.Line2,NULL,ad.City,ad.StateOrProvince,ad.PostalCode,co.countries_name,le.PhoneNumber,le.PhoneExt,c.Email)),
					Address1 = Upper(ad.Line1),
					Address2 = Upper(ad.Line2),
					City = Upper(ad.City),
					StateOrProvince = Upper(ad.StateOrProvince),
					PostalCode = Upper(ad.PostalCode),
					Country = Upper(co.countries_name),
					PhoneNumber = Upper(le.PhoneNumber),
					--MergedAddressForCOC = (SELECT dbo.ValidatePDFAddress(ad.Line1,NULL,NULL,ad.City,ad.StateOrProvince,ad.PostalCode,NULL,NULL,NULL,NULL)),
					MergedAddressForCOC = @MergedAddressForCOC,
					PhoneExt = Upper(le.PhoneExt),
					LogoName = atd.FileName,
					AttachmentDetailId = atd.AttachmentDetailId,
					Upper(le.FAALicense) as FAALicense,
					Upper(le.EASALicense) as EASALicense,
					Upper(le.CAACLicense) as CAACLicense,
					Upper(le.TCCALicense) as TCCALicense,
					Upper(c.Email) as Email,
					CompanyLogoPath = MS.companylogo,
					[dbo].[ConvertUTCtoLocal](GETUTCDATE(),tz.description)  as 'CurrentDateTime'
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
					LEFT JOIN dbo.TimeZone tz WITH(NOLOCK) ON tz.TimeZoneId = le.TimeZoneId
				WHERE est.EntityStructureId = @ManagementStructId) AS Result



				SELECT * FROM #TempDestinationTable
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
	END CATCH
END