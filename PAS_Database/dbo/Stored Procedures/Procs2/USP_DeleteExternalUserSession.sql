/*********************
 ** File:   DELETE EXTERNAL USER SESSION
 ** Author:  Nakul
 ** Description: Ends an External webpage user's sessions on logout (ExternalApiController.Logout)
 ** Purpose: Deletes ALL session rows of @ExternalUserId, so logging out on one browser/device logs that user out on
 **          every device. Sessions of other users are not affected. Returns the number of sessions removed (0 if none).
 ** Date:  09/10/2026

 ************************************************************
  ** Change History
 ************************************************************
  ** PR   Date         Author			Change Description
  ** --   --------     -------			--------------------------------
     1    09/10/2026   Nakul            Created for External webpage logout (sessions)
     2    09/10/2026   Nakul            Logout now ends all sessions of the user (every device), not only the token being logged out - removed @JwtId

 exec USP_DeleteExternalUserSession @ExternalUserId=1
*************************************************************/
CREATE PROCEDURE [dbo].[USP_DeleteExternalUserSession]
    @ExternalUserId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM [dbo].[ExternalUserSession]
        WHERE [ExternalUserId] = @ExternalUserId;

        SELECT @@ROWCOUNT AS SessionsRemoved;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_DeleteExternalUserSession',
                @ProcedureParameters VARCHAR(3000) = '@ExternalUserId = ''' + CAST(ISNULL(@ExternalUserId, '') AS VARCHAR(100)) + '''',
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
