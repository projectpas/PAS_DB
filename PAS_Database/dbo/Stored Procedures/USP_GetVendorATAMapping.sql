/***************************************************************  
 ** File:   [USP_GetVendorATAMapping]             
 ** Author: Ayushi Patel  
 ** Description: Get ATA Mapped contact list for a vendor with time zone conversion  
 ** Purpose: Replaces EF LINQ GetATAMapped method  
 ** Date:  29-May-2025  

 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-05-29		  Ayushi Patel				Created
	exec USP_GetVendorATAMapping 4787 ,229, false
 ***************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetVendorATAMapping]
    @VendorId BIGINT,
    @EmployeeId BIGINT,
    @IsDeleted BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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
            ca.VendorContactATAMappingId,
            ca.VendorId,
            ca.ATAChapterId,
            ata.ATAChapterCode,
            ATAChapterName = ca.Level1 +
                             CASE WHEN ISNULL(ca.Level2, '') <> '' THEN '-' + ca.Level2 ELSE '' END +
                             CASE WHEN ISNULL(ca.Level3, '') <> '' THEN '-' + ca.Level3 ELSE '' END,
            ca.ATASubChapterId,
            ContactId = contt.ContactId,
            FirstName = ISNULL(contt.FirstName + ' ' + contt.LastName, ''),
            ca.CreatedBy,
			(Cast(DBO.ConvertUTCtoLocal(ca.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime)) CreatedDate,
            ca.UpdatedBy,
			(Cast(DBO.ConvertUTCtoLocal(ca.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime)) UpdatedDate,
            ISNULL(ca.IsDeleted,0) AS IsDeleted
        FROM DBO.VendorContactATAMapping ca WITH (NOLOCK)
        INNER JOIN DBO.VendorContact cont WITH (NOLOCK) ON ca.VendorContactId = cont.VendorContactId
        LEFT JOIN DBO.Contact contt WITH (NOLOCK) ON cont.ContactId = contt.ContactId
        LEFT JOIN DBO.ATAChapter ata WITH (NOLOCK) ON ca.ATAChapterId = ata.ATAChapterId
        LEFT JOIN DBO.ATASubChapter atasub WITH (NOLOCK) ON ca.ATASubChapterId = atasub.ATASubChapterId
        WHERE 
            ca.VendorId = @VendorId
            AND ca.IsDeleted = @IsDeleted
            AND ISNULL(cont.IsDeleted, 0) = 0;

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
                @AdhocComments VARCHAR(150) = 'USP_GetVendorATAMapping',
                @ProcedureParameters VARCHAR(3000) = '@VendorId = ' + CAST(ISNULL(@VendorId, 0) AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected error occurred in the database. Please let the support team know of the error number: %d',
            16, 1, @ErrorLogID
        );
        RETURN (1);
    END CATCH
END