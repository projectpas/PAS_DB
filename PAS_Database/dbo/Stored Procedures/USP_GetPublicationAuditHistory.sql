/***************************************************************  
 ** File:   [USP_GetPublicationAuditHistory]             
 ** Author: Ayushi Patel  
 ** Description: Get Publication Audit History by PublicationId 
 ** Purpose:   
 ** Date:  30-May-2025  

 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-05-30		  Ayushi Patel				Created
	
 ***************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetPublicationAuditHistory]
    @PublicationId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		SELECT
				@CurrntEmpTimeZoneDesc = COALESCE(
					ETZ.[Description],  -- Prefer Employee's TimeZone description if available
					LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
				)
			FROM
				dbo.Employee E WITH (NOLOCK)
			LEFT JOIN
				dbo.TimeZone ETZ WITH (NOLOCK)
				ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN
				dbo.LegalEntity LE WITH (NOLOCK)
				ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN
				dbo.TimeZone LTZ WITH (NOLOCK)
				ON LE.TimeZoneId = LTZ.TimeZoneId
			WHERE
				E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

        SELECT 
            pa.PublicationAuditId,
            pa.PublicationId,
            pa.Description,
            pt.Name AS PublicationType,
            ISNULL(e.FirstName, '') AS EmployeeName,
            ISNULL(loc.Name, '') AS Location,
            ISNULL(pemp.ModuleName, '') AS PublishedBy,
            ISNULL(pa.IsActive,0) AS IsActive,
            pa.UpdatedBy,
			(Cast(DBO.ConvertUTCtoLocal(pa.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime)) UpdatedDate,
            ISNULL(pa.RevisionNum, '') AS RevisionNum,
            ISNULL(vb.FirstName, '') AS VerifiedBy,
            pa.VerifiedDate,
            ISNULL(pa.IsDeleted,0) AS IsDeleted,
            pa.CreatedBy,
			(Cast(DBO.ConvertUTCtoLocal(pa.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime)) CreatedDate,
            ISNULL(im.PartNumber, '') AS PartNos,
            ISNULL(im.PartDescription, '') AS PnDescription,
            ISNULL(ac.ATAChapterName, '') AS AtaChapterName,
            pa.URL
        FROM DBO.PublicationAudit pa WITH (NOLOCK)
		INNER JOIN DBO.PublicationType pt WITH (NOLOCK) ON pa.PublicationTypeId = pt.PublicationTypeId
        LEFT JOIN DBO.PublicationItemMasterMapping pum WITH (NOLOCK) ON pa.PublicationRecordId = pum.PublicationRecordId
        LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) ON pum.ItemMasterId = im.ItemMasterId
        LEFT JOIN DBO.ItemMasterATAMapping ima WITH (NOLOCK) ON pum.ItemMasterId = ima.ItemMasterId
        LEFT JOIN DBO.ATAChapter ac WITH (NOLOCK) ON ima.ATAChapterId = ac.ATAChapterId
        LEFT JOIN DBO.Employee e WITH (NOLOCK) ON pa.EmployeeId = e.EmployeeId
        LEFT JOIN DBO.Employee vb WITH (NOLOCK) ON pa.VerifiedBy = vb.EmployeeId
        LEFT JOIN DBO.Location loc WITH (NOLOCK) ON pa.LocationId = loc.LocationId
        LEFT JOIN DBO.Module pemp WITH (NOLOCK) ON pa.PublishedById = pemp.ModuleId
        WHERE pa.PublicationRecordId = @PublicationId
        ORDER BY pa.PublicationAuditId DESC
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
                @AdhocComments VARCHAR(150) = 'USP_GetPublicationAuditHistory',
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