/***********************************************************
** File:   [USP_GetATAMapped]
** Author: Ayushi Patel
** Description: Get mapped ATA contact data for vendor with time zone conversion
** Purpose: 
** Date:   2025-05-22
        
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1	 22-MAY-2025   AYUSHI PATEL 		Created
***************************************************************/
CREATE PROCEDURE [dbo].[USP_GetATAMapped]
    @VendorId BIGINT,
    @EmployeeId BIGINT,
    @IsDeleted BIT
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
            ca.VendorContactATAMappingId,
            ca.VendorId,
            ca.ATAChapterId,
            ata.ATAChapterCode,
            ATAChapterName = ca.Level1 +
                             CASE WHEN ISNULL(ca.Level2, '') <> '' THEN '-' + ca.Level2 ELSE '' END +
                             CASE WHEN ISNULL(ca.Level3, '') <> '' THEN '-' + ca.Level3 ELSE '' END,
            ca.ATASubChapterId,
            ContactId = ISNULL(ct.ContactId, 0),
            FirstName = ISNULL(ct.FirstName + ' ' + ct.LastName, ''),
            ca.CreatedBy,
			(Cast(DBO.ConvertUTCtoLocal(ca.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime)) CreatedDate,
            ca.UpdatedBy,
			(Cast(DBO.ConvertUTCtoLocal(ca.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime)) UpdatedDate,
            ISNULL(ca.IsDeleted,0) AS IsDeleted
        FROM VendorContactATAMapping ca WITH (NOLOCK)
        INNER JOIN VendorContact vc WITH (NOLOCK) ON ca.VendorContactId = vc.VendorContactId AND ISNULL(vc.IsDeleted,0) = 0
        LEFT JOIN Contact ct WITH (NOLOCK) ON vc.ContactId = ct.ContactId
        LEFT JOIN ATAChapter ata WITH (NOLOCK) ON ca.ATAChapterId = ata.ATAChapterId
        LEFT JOIN ATASubChapter atasub WITH (NOLOCK) ON ca.ATASubChapterId = atasub.ATASubChapterId
        WHERE ca.VendorId = @VendorId AND ISNULL(ca.IsDeleted,0) = @IsDeleted
        ORDER BY ca.VendorContactATAMappingId DESC;

    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetATAMapped'
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