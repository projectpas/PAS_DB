
---------------------------------------------------------------------------------------------
-- 2.4 Endpoint permission check. Same role -> permission mapping as the PAS login
--     (EmployeeUserRole -> RolePermission -> ModuleHierarchyMaster.PermissionConstant + '.' + PermissionName).
--     @Permissions is ':' separated; allowed when the employee has ANY of them (e.g. 'Customer.View').
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_HasEmployeePermission]
    @EmployeeId  BIGINT,
    @Permissions VARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;

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
END