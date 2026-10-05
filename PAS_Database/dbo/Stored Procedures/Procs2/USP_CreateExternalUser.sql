/*********************
 ** File:   CREATE EXTERNAL USER
 ** Author:  Nakul
 ** Description: Adds an External webpage login (ExternalApiController.CreateUser)
 ** Purpose: @PasswordHash is the ASP.NET Identity hash created by the API - the plain password never reaches the database.
 **          User names are unique (case-insensitive). Returns the new user without the hash.
 ** Date:  30/09/2026

 ************************************************************
  ** Change History
 ************************************************************
  ** PR   Date         Author			Change Description
  ** --   --------     -------			--------------------------------
     1    30/09/2026   Nakul            Created for External webpage user creation

 exec USP_CreateExternalUser @UserName='john.smith', @PasswordHash='AQAAAAIAAYag...', @FullName='John Smith', @Email=NULL, @MasterCompanyId=1, @CreatedBy='ADMIN USER'
*************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateExternalUser]
    @UserName        NVARCHAR(256),
    @PasswordHash    NVARCHAR(MAX),
    @FullName        NVARCHAR(256) = NULL,
    @Email           NVARCHAR(256) = NULL,
    @MasterCompanyId INT,
    @CreatedBy       VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM [dbo].[ExternalUser] WITH(NOLOCK) WHERE [UserName] = @UserName)
    BEGIN
        RAISERROR ('User name already exists.', 16, 1);
        RETURN (1);
    END

    BEGIN TRY
        INSERT INTO [dbo].[ExternalUser] ([UserName], [PasswordHash], [FullName], [Email], [MasterCompanyId], [CreatedBy], [UpdatedBy])
        VALUES (@UserName, @PasswordHash, @FullName, @Email, @MasterCompanyId, @CreatedBy, @CreatedBy);

        SELECT EU.[ExternalUserId],
               EU.[UserName],
               EU.[FullName],
               EU.[Email],
               EU.[MasterCompanyId],
               EU.[IsActive],
               EU.[CreatedBy],
               EU.[CreatedDate]
        FROM [dbo].[ExternalUser] EU WITH(NOLOCK)
        WHERE EU.[ExternalUserId] = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_CreateExternalUser',
                @ProcedureParameters VARCHAR(3000) = '@UserName = ''' + CAST(ISNULL(@UserName, '') AS VARCHAR(256)) + '''' +
                                                     ', @MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + '''',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
                @DatabaseName           = @DatabaseName,
                @AdhocComments          = @AdhocComments,
                @ProcedureParameters    = @ProcedureParameters,
                @ApplicationName        = @ApplicationName,
                @ErrorLogID             = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in database procedure USP_CreateExternalUser. Error Log ID: %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END;
GO
