/*********************
 ** File:   CHECK EXTERNAL USER SESSION
 ** Author:  Nakul
 ** Description: Tells whether an External webpage access token's session is still active (ExternalApiController)
 ** Purpose: Returns IsActive = 1 when the session row for @JwtId exists for this user and has not expired; 0 after
 **          logout (row deleted) or expiry. Every webpage endpoint checks this before doing any work.
 ** Date:  09/10/2026

 ************************************************************
  ** Change History
 ************************************************************
  ** PR   Date         Author			Change Description
  ** --   --------     -------			--------------------------------
     1    09/10/2026   Nakul            Created for External webpage logout (sessions)

 exec USP_CheckExternalUserSession @ExternalUserId=1, @JwtId='0f8fad5bd9cb469fa165708f6b1e2c3d'
*************************************************************/
CREATE PROCEDURE [dbo].[USP_CheckExternalUserSession]
    @ExternalUserId BIGINT,
    @JwtId          VARCHAR(100)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT CASE WHEN EXISTS (
                   SELECT 1 FROM [dbo].[ExternalUserSession] WITH(NOLOCK)
                   WHERE [ExternalUserId] = @ExternalUserId
                     AND [JwtId] = @JwtId
                     AND [ExpiresAt] > GETUTCDATE()
               ) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsActive;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_CheckExternalUserSession',
                @ProcedureParameters VARCHAR(3000) = '@ExternalUserId = ''' + CAST(ISNULL(@ExternalUserId, '') AS VARCHAR(100)) + '''' +
                                                     ', @JwtId = ''' + ISNULL(@JwtId, '') + '''',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
                @DatabaseName           = @DatabaseName,
                @AdhocComments          = @AdhocComments,
                @ProcedureParameters    = @ProcedureParameters,
                @ApplicationName        = @ApplicationName,
                @ErrorLogID             = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in database procedure USP_CheckExternalUserSession. Error Log ID: %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END;
GO
