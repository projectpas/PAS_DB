/*************************************************************           
 ** File:   [USP_GetATAContactMapped]      
 ** Author:   Ayushi Patel
 ** Description: Get ATA Contact Mapped
 ** Purpose:         
 ** Date:  21/05/2025 
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1	 21-MAY-2025   AYUSHI PATEL 		Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetATAContactMapped]
    @VendorContactId BIGINT,
    @IsDeleted BIT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            ca.VendorContactATAMappingId,
            ca.VendorId,
            ca.ATAChapterId,
            ataca.ATAChapterCode,
            ATAChapterName = ca.Level1 +
                             CASE 
                                 WHEN ISNULL(ca.Level2, '') <> '' THEN '-' + ca.Level2 
                                 ELSE '' 
                             END +
                             CASE 
                                 WHEN ISNULL(ca.Level3, '') <> '' THEN '-' + ca.Level3 
                                 ELSE '' 
                             END,
            ca.ATASubChapterId,
            atasub.ATASubChapterCode,
            ATASubChapterDescription = atasub.Description,
            ca.CreatedBy,
            ca.UpdatedBy,
            ISNULL(ca.IsActive,0) AS IsActive,
            ISNULL(ca.IsDeleted,0) AS IsDeleted,
            ca.Level1,
            ca.Level2,
            ca.Level3
        FROM dbo.VendorContactATAMapping ca WITH (NOLOCK)
        LEFT JOIN dbo.ATAChapter ataca WITH (NOLOCK) ON ca.ATAChapterId = ataca.ATAChapterId
        LEFT JOIN dbo.ATASubChapter atasub WITH (NOLOCK) ON ca.ATASubChapterId = atasub.ATASubChapterId
        WHERE ca.VendorContactId = @VendorContactId AND ISNULL(ca.IsDeleted,0) = @IsDeleted;
    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetATAContactMapped'
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