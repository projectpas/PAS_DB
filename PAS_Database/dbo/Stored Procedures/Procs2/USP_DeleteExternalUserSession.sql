/*********************
 ** File:   DELETE EXTERNAL USER SESSION
 ** Author:  Nakul
 ** Description: Ends an External webpage session on logout (ExternalApiController.Logout)
 ** Purpose: Deletes the session row of the access token being logged out (@JwtId). The user's other sessions
 **          (other browsers/devices) are not affected. Returns the number of sessions removed (0 if already gone).
 ** Date:  09/10/2026

 ************************************************************
  ** Change History
 ************************************************************
  ** PR   Date         Author			Change Description
  ** --   --------     -------			--------------------------------
     1    09/10/2026   Nakul            Created for External webpage logout (sessions)

 exec USP_DeleteExternalUserSession @ExternalUserId=1, @JwtId='0f8fad5bd9cb469fa165708f6b1e2c3d'
*************************************************************/
CREATE PROCEDURE [dbo].[USP_DeleteExternalUserSession]
    @ExternalUserId BIGINT,
    @JwtId          VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM [dbo].[ExternalUserSession]
        WHERE [ExternalUserId] = @ExternalUserId AND [JwtId] = @JwtId;

        SELECT @@ROWCOUNT AS SessionsRemoved;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_DeleteExternalUserSession',
                @ProcedureParameters VARCHAR(3000) = '@ExternalUserId = ''' + CAST(ISNULL(@ExternalUserId, '') AS VARCHAR(100)) + '''' +
                                                     ', @JwtId = ''' + ISNULL(@JwtId, '') + '''',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
                @DatabaseName           = @DatabaseName,
                @AdhocComments          = @AdhocComments,
                @ProcedureParameters    = @ProcedureParameters,
                @ApplicationName        = @ApplicationName,
                @ErrorLogID             = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in database procedure USP_DeleteExternalUserSession. Error Log ID: %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END;
GO
