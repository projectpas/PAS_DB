
/*************************************************************
 ** File:   [USP_PublicApi_GetExplorerUser]
 ** Author: Moin Bloch
 ** Description: 6.3 PAS user for the API Explorer login, by user name (not case sensitive, like the PAS login).
 **              Status flags are returned, not filtered, so the caller always runs the password check.
 **              MustChangePassword: AspNetUsers.IsResetPassword = 0 (temporary password after an admin reset);
 **              PAS makes the user set a new password first.
 ** Purpose: PAS_PUBLIC_API - API Explorer login
 ** Date:   19/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    19/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetExplorerUser] @UserName = 'Demo-ADmin'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetExplorerUser]
    @UserName NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT TOP (1)
            U.[UserName],
            U.[EmployeeId],
            U.[MasterCompanyId],
            U.[PasswordHash],
            U.[SecurityStamp],
            U.[IsEnabled],
            CAST(CASE WHEN U.[LockoutEnabled] = 1 AND U.[LockoutEnd] > SYSDATETIMEOFFSET() THEN 1 ELSE 0 END AS BIT) AS [IsLockedOut],
            CAST(CASE WHEN ISNULL(U.[IsResetPassword], 0) = 0 THEN 1 ELSE 0 END AS BIT) AS [MustChangePassword]
        FROM [dbo].[AspNetUsers] U WITH (NOLOCK)
        WHERE U.[NormalizedUserName] = UPPER(@UserName);
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetExplorerUser'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@UserName, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END