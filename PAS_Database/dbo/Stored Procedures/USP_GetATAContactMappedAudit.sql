/***********************************************************
** File:   USP_GetATAContactMappedAudit
** Author: Ayushi Patel
** Description: Get audit history of ATA Contact Mappings with associated ATA Chapter and Subchapter info
** Purpose: Fetches audit records for a specific VendorContactATAMappingId with timezone conversion
** Date:   2025-05-21
        
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1	 21-MAY-2025   AYUSHI PATEL 		Created
***************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetATAContactMappedAudit]
    @VendorContactATAMappingId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
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
            ca.AuditVendorContactATAMappingId,
            ca.VendorContactATAMappingId,
            ca.VendorId,
            ca.ATAChapterId,
            ac.ATAChapterCode,
            ca.ATASubChapterId,
            asc1.ATASubChapterCode,
            ATAChapterName = 
                ca.Level1 + 
                CASE WHEN ISNULL(ca.Level2, '') <> '' THEN '-' + ca.Level2 ELSE '' END +
                CASE WHEN ISNULL(ca.Level3, '') <> '' THEN '-' + ca.Level3 ELSE '' END,
            ATASubChapterDescription = asc1.Description,
            ca.CreatedBy,
            ca.UpdatedBy,
            ISNULL(ca.IsActive,0) AS IsActive,
            ISNULL(ca.IsDeleted,0) AS IsDeleted,
			(Cast(DBO.ConvertUTCtoLocal(ca.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime)) CreatedDate,
			(Cast(DBO.ConvertUTCtoLocal(ca.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime)) UpdatedDate,
            ct.FirstName
        FROM dbo.VendorContactATAMappingAudit ca WITH (NOLOCK)
        LEFT JOIN dbo.ATAChapter ac WITH (NOLOCK) ON ca.ATAChapterId = ac.ATAChapterId
        LEFT JOIN dbo.ATASubChapter asc1 WITH (NOLOCK) ON ca.ATASubChapterId = asc1.ATASubChapterId
        INNER JOIN dbo.VendorContact vc WITH (NOLOCK) ON ca.VendorContactId = vc.VendorContactId
        LEFT JOIN dbo.Contact ct WITH (NOLOCK) ON vc.ContactId = ct.ContactId
        WHERE ca.VendorContactATAMappingId = @VendorContactATAMappingId
        ORDER BY ca.AuditVendorContactATAMappingId DESC

    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetATAContactMappedAudit'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH

END