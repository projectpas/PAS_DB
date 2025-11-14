/***************************************************************  
 ** File: [USP_GetPublicationDetailsById]            
 ** Author: Ayushi Patel  
 ** Description: Get full Publication details by PublicationRecordId
 ** Purpose:   
 ** Date:  02-JUN-2025  

 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-06-02		  Ayushi Patel				Created
    2    2025-11-10		  Bhargav Saliya			Get Added new field notes
    3    2025-13-10		  Bhargav Saliya			Remove notes
	exec [dbo].[USP_GetPublicationDetailsById] 708
 ***************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetPublicationDetailsById]
    @PublicationRecordId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY
		DECLARE @VendorModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName = 'Vendor');
		DECLARE @ManufacturerModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName = 'Manufacturer');
        SELECT 
            p.PublicationRecordId,
            p.PublicationId,
            p.PublicationTypeId,
            p.ASD,
            p.CreatedBy,
            p.CreatedDate,
            p.Description,
            ISNULL(p.EmployeeId, 0) AS EmployeeId,
            p.EntryDate,
            p.ExpirationDate,
            p.LocationId,
            p.MasterCompanyId,
            p.NextReviewDate,
            p.PublishedById,
            p.RevisionDate,
            ISNULL(p.RevisionNum, '') AS RevisionNum,
            ISNULL(p.RevisionNum, '') AS RevisionNumber,
            p.Sequence,
            p.VerifiedBy,
            p.VerifiedDate,
            p.VerifiedStatus,
            ISNULL(p.IsActive,0) AS IsActive,
            ISNULL(p.IsDeleted,0) AS IsDeleted,
            p.UpdatedBy,
            p.UpdatedDate,
            ISNULL(pemp.ModuleName, '') AS PublishedBy,
            p.PublishedByRefId,
            ISNULL(
                CASE 
                    WHEN p.PublishedById = @VendorModuleId THEN v.VendorName
                    WHEN p.PublishedById = @ManufacturerModuleId THEN m.Name
                    ELSE ''
                END, ''
            ) AS PublishedByRefName,
            ISNULL(p.PublishedByOthers, '') AS PublishedByOthers,
            ISNULL(loc.Name, '') AS Location,
            ISNULL(pt.Name, '') AS PublicationTypeName,
            p.ManagementStructureIds,
            p.URL,
            p.Fleet,
			v.VendorName,
			m.Name,
			p.PublishedByRefId
        FROM dbo.Publication p WITH (NOLOCK)
        LEFT JOIN dbo.PublicationType pt WITH (NOLOCK) ON p.PublicationTypeId = pt.PublicationTypeId
        LEFT JOIN dbo.Location loc WITH (NOLOCK) ON p.LocationId = loc.LocationId
        LEFT JOIN dbo.Module pemp WITH (NOLOCK) ON p.PublishedById = pemp.ModuleId
		LEFT JOIN dbo.Manufacturer m WITH (NOLOCK) 
            ON p.PublishedById = @ManufacturerModuleId AND p.PublishedByRefId = m.ManufacturerId
        LEFT JOIN dbo.Vendor v WITH (NOLOCK) 
            ON p.PublishedById = @VendorModuleId AND p.PublishedByRefId = v.VendorId
       
        WHERE p.PublicationRecordId = @PublicationRecordId AND ISNULL(p.IsDeleted,0) = 0
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
                @AdhocComments VARCHAR(150) = 'USP_GetPublicationDetailsById',
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