/*********************
 ** File:   UPDATE EXTERNAL USER LOGIN STATUS
 ** Author:  Nakul
 ** Description: Records the result of an External webpage login attempt (ExternalApiController.Login)
 ** Purpose: Success resets the failed-attempt counter and stamps LastLoginDate (and stores a re-hashed password when given).
 **          Failure increments the counter and locks the account for @LockoutMinutes once it reaches @MaxFailedAttempts.
 ** Date:  30/09/2026

 ************************************************************
  ** Change History
 ************************************************************
  ** PR   Date         Author			Change Description
  ** --   --------     -------			--------------------------------
     1    30/09/2026   Nakul            Created for External webpage login

 exec USP_UpdateExternalUserLoginStatus @ExternalUserId=1, @IsLoginSuccess=1, @PasswordHash=NULL, @MaxFailedAttempts=5, @LockoutMinutes=15
*************************************************************/
CREATE PROCEDURE [dbo].[USP_UpdateExternalUserLoginStatus]
    @ExternalUserId    BIGINT,
    @IsLoginSuccess    BIT,
    @PasswordHash      NVARCHAR(MAX) = NULL,
    @MaxFailedAttempts INT,
    @LockoutMinutes    INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF (@IsLoginSuccess = 1)
        BEGIN
            UPDATE [dbo].[ExternalUser]
            SET [AccessFailedCount] = 0,
                [LockoutEnd]        = NULL,
                [LastLoginDate]     = GETUTCDATE(),
                [PasswordHash]      = ISNULL(@PasswordHash, [PasswordHash])
            WHERE [ExternalUserId] = @ExternalUserId;
        END
        ELSE
        BEGIN
            UPDATE [dbo].[ExternalUser]
            SET [AccessFailedCount] = CASE WHEN [AccessFailedCount] + 1 >= @MaxFailedAttempts THEN 0 ELSE [AccessFailedCount] + 1 END,
                [LockoutEnd]        = CASE WHEN [AccessFailedCount] + 1 >= @MaxFailedAttempts THEN DATEADD(MINUTE, @LockoutMinutes, GETUTCDATE()) ELSE [LockoutEnd] END
            WHERE [ExternalUserId] = @ExternalUserId;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_UpdateExternalUserLoginStatus',
                @ProcedureParameters VARCHAR(3000) = '@ExternalUserId = ''' + CAST(ISNULL(@ExternalUserId, '') AS VARCHAR(100)) + '''' +
                                                     ', @IsLoginSuccess = ''' + CAST(ISNULL(@IsLoginSuccess, '') AS VARCHAR(10)) + '''',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
                @DatabaseName           = @DatabaseName,
                @AdhocComments          = @AdhocComments,
                @ProcedureParameters    = @ProcedureParameters,
                @ApplicationName        = @ApplicationName,
                @ErrorLogID             = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in database procedure USP_UpdateExternalUserLoginStatus. Error Log ID: %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END;
GO
