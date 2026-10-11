/*********************
 ** File:   CREATE EXTERNAL USER SESSION
 ** Author:  Nakul
 ** Description: Starts a session for an External webpage login (ExternalApiController.Login)
 ** Purpose: One row per issued access token (@JwtId = the token's jti). A user can have several sessions at once
 **          (one per browser/device). Expired sessions of the same user are removed here so the table stays small.
 ** Date:  09/10/2026

 ************************************************************
  ** Change History
 ************************************************************
  ** PR   Date         Author			Change Description
  ** --   --------     -------			--------------------------------
     1    09/10/2026   Nakul            Created for External webpage logout (sessions)

 exec USP_CreateExternalUserSession @ExternalUserId=1, @JwtId='0f8fad5bd9cb469fa165708f6b1e2c3d', @ExpiresAt='2026-10-09 12:00:00'
*************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateExternalUserSession]
    @ExternalUserId BIGINT,
    @JwtId          VARCHAR(100),
    @ExpiresAt      DATETIME2(7)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM [dbo].[ExternalUserSession]
        WHERE [ExternalUserId] = @ExternalUserId AND [ExpiresAt] <= GETUTCDATE();

        INSERT INTO [dbo].[ExternalUserSession] ([ExternalUserId], [JwtId], [ExpiresAt])
        VALUES (@ExternalUserId, @JwtId, @ExpiresAt);
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_CreateExternalUserSession',
                @ProcedureParameters VARCHAR(3000) = '@ExternalUserId = ''' + CAST(ISNULL(@ExternalUserId, '') AS VARCHAR(100)) + '''' +
                                                     ', @JwtId = ''' + ISNULL(@JwtId, '') + '''',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
                @DatabaseName           = @DatabaseName,
                @AdhocComments          = @AdhocComments,
                @ProcedureParameters    = @ProcedureParameters,
                @ApplicationName        = @ApplicationName,
                @ErrorLogID             = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in database procedure USP_CreateExternalUserSession. Error Log ID: %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END;
GO
