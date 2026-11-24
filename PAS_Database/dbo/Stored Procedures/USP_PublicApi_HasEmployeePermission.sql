
/*************************************************************
 ** File:   [USP_PublicApi_HasEmployeePermission]
 ** Author: Moin Bloch
 ** Description: 2.4 Endpoint permission check. Same role -> permission mapping as the PAS login
 **                  (EmployeeUserRole -> RolePermission -> ModuleHierarchyMaster.PermissionConstant + '.' + PermissionName).
 **                  @Permissions is ':' separated; allowed when the employee has ANY of them (e.g. 'Customer.View').
 ** Purpose: PAS_PUBLIC_API - [RequirePermission] on the data endpoints
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_HasEmployeePermission] @EmployeeId = 2, @Permissions = 'SO_List.View'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_HasEmployeePermission]
    @EmployeeId  BIGINT,
    @Permissions VARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT CAST(CASE WHEN EXISTS (
            SELECT 1
            FROM [dbo].[EmployeeUserRole] EUR WITH (NOLOCK)
            INNER JOIN [dbo].[RolePermission] R WITH (NOLOCK) ON R.[UserRoleId] = EUR.[RoleId]
            INNER JOIN [dbo].[ModuleHierarchyMaster] M WITH (NOLOCK) ON M.[Id] = R.[ModuleHierarchyMasterId]
            INNER JOIN [dbo].[PermissionMaster] P WITH (NOLOCK) ON P.[PermissionID] = R.[PermissionID]
            WHERE EUR.[EmployeeId] = @EmployeeId
              AND EUR.[IsActive] = 1
              AND EUR.[IsDeleted] = 0
              AND M.[PermissionConstant] + '.' + P.[PermissionName] IN (SELECT LTRIM(RTRIM([value])) FROM STRING_SPLIT(@Permissions, ':'))
        ) THEN 1 ELSE 0 END AS BIT) AS [IsAllowed];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_HasEmployeePermission'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@Permissions, '') AS VARCHAR(100))
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