/***************************************************************  
 ** File:   [USP_GetPublicationViewById]             
 ** Author: Ayushi Patel  
 ** Description: Get detailed view of Publication record   
 ** Purpose:   
 ** Date:  30-May-2025  

 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-05-30		  Ayushi Patel				Created
    2    2025-10-16		  Bhargav Saliya			Added Case For [VerifiedByName]
	3    10/11/2025       Bhargav Saliya            Get Notes which has been newly added
	4    12/11/2025       Bhargav Saliya            Remove Notes
 ***************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetPublicationViewById]  
    @PublicationRecordId BIGINT  
AS  
BEGIN  
    SET NOCOUNT ON; 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY  
		DECLARE @VendorModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName = 'Vendor');
		DECLARE @ManufacturerModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName = 'Manufacturer');
        SELECT  
            pb.PublicationRecordId,
            pb.EntryDate,
            pb.PublicationId,
            pb.Description,
            pbt.Name AS PublicationType,
            pb.ASD,
            pb.Sequence,
            ISNULL(pemp.ModuleName, '') AS Publishby,
            ISNULL(loc.Name, '') AS Location,
            pb.RevisionDate,
            pb.ExpirationDate,
            pb.NextReviewDate,
            pb.VerifiedBy,
            CASE WHEN ISNULL(pb.VerifiedBy,0) = 0 THEN 'NA' ELSE ISNULL(emvb.FirstName, '') + ' ' + ISNULL(emvb.LastName, '') END AS VerifiedByName,
            pb.VerifiedDate,
            ISNULL(em.FirstName, '') + ' ' + ISNULL(em.LastName, '') AS EmployeeName,
            ISNULL(pb.RevisionNum, '') AS RevisionNum,
            pb.PublishedById,
            pb.PublishedByRefId,
            ISNULL(
                CASE 
                    WHEN pb.PublishedById = @VendorModuleId THEN vend.VendorName  
                    WHEN pb.PublishedById = @ManufacturerModuleId THEN manu.Name 
                    ELSE ''
                END, ''
            ) AS PublishedByRefName,
            pb.PublishedByOthers,
            pb.ManagementStructureIds,
            pb.URL,
            pb.Fleet,

            (SELECT TOP 1 pt.EmailBody
             FROM DBO.PublicationTemplate pt
             WHERE pt.PublicationTypeId = pb.PublicationTypeId AND pt.MasterCompanyId = pb.MasterCompanyId) AS PublicationTemplate

        FROM DBO.Publication pb WITH (NOLOCK)

        LEFT JOIN DBO.PublicationType pbt WITH (NOLOCK) ON pb.PublicationTypeId = pbt.PublicationTypeId
        LEFT JOIN DBO.Employee em WITH (NOLOCK) ON pb.EmployeeId = em.EmployeeId
        LEFT JOIN DBO.Employee emvb WITH (NOLOCK) ON pb.VerifiedBy = emvb.EmployeeId
        LEFT JOIN DBO.Location loc WITH (NOLOCK) ON pb.LocationId = loc.LocationId
        LEFT JOIN DBO.Module pemp WITH (NOLOCK) ON pb.PublishedById = pemp.ModuleId
        LEFT JOIN DBO.Vendor vend WITH (NOLOCK) 
            ON pb.PublishedById = @VendorModuleId AND pb.PublishedByRefId = vend.VendorId
        LEFT JOIN DBO.Manufacturer manu WITH (NOLOCK) 
            ON pb.PublishedById = @ManufacturerModuleId AND pb.PublishedByRefId = manu.ManufacturerId

        WHERE pb.PublicationRecordId = @PublicationRecordId

    END TRY  
    BEGIN CATCH
		SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;
        DECLARE @ErrorLogID INT, 
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_GetPublicationViewById',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred. Inform Support with Error Number: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH  
END