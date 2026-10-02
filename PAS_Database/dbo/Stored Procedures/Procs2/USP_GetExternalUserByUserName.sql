/*********************
 ** File:   GET EXTERNAL USER BY USER NAME
 ** Author:  Nakul
 ** Description: Returns the External webpage user for login (ExternalApiController.Login)
 ** Purpose: Password is verified in the API; this only fetches the stored hash and account status
 ** Date:  30/09/2026

 ************************************************************
  ** Change History
 ************************************************************
  ** PR   Date         Author			Change Description
  ** --   --------     -------			--------------------------------
     1    30/09/2026   Nakul            Created for External webpage login

 exec USP_GetExternalUserByUserName @UserName='test.user'
*************************************************************/
CREATE PROCEDURE [dbo].[USP_GetExternalUserByUserName]
    @UserName NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT EU.[ExternalUserId],
               EU.[UserName],
               EU.[PasswordHash],
               EU.[FullName],
               EU.[Email],
               EU.[MasterCompanyId],
               EU.[AccessFailedCount],
               EU.[LockoutEnd],
               EU.[LastLoginDate],
               EU.[IsActive],
               EU.[IsDeleted]
        FROM [dbo].[ExternalUser] EU WITH(NOLOCK)
        WHERE EU.[UserName] = @UserName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetExternalUserByUserName',
                @ProcedureParameters VARCHAR(3000) = '@UserName = ''' + CAST(ISNULL(@UserName, '') AS VARCHAR(256)) + '''',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
                @DatabaseName           = @DatabaseName,
                @AdhocComments          = @AdhocComments,
                @ProcedureParameters    = @ProcedureParameters,
                @ApplicationName        = @ApplicationName,
                @ErrorLogID             = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in database procedure USP_GetExternalUserByUserName. Error Log ID: %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END;
GO
