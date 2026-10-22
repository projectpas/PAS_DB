/*************************************************************
 ** File:   [GetMenuPermission]
 ** Author:
 ** Description: This stored procedure is used to get role permissions
 ** Purpose:
 ** Date:

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author					Change Description
 ** -----------------------------------------------------------
    1					Unknown					Created
	2    07/11/2024		Devendra Shekh			added ImgClass to select
	3    10/01/2025		Bhargav Saliya			added MobileMenuSequence
	4    20/10/2026		Vishal Suthar			Performance optimization for role permissions

-- EXEC [dbo].[GetMenuPermission] '1'
************************************************************************/
CREATE   Procedure [dbo].[GetMenuPermission]
	@RoleId varchar(max),
	@IsPermissionData bit = 0
AS
Begin
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		-- Roles of the user (comma separated)
		DECLARE @Roles TABLE (UserRoleId BIGINT PRIMARY KEY);
		INSERT INTO @Roles (UserRoleId)
		SELECT DISTINCT TRY_CAST(LTRIM(RTRIM([value])) AS BIGINT)
		FROM STRING_SPLIT(@RoleId, ',')
		WHERE TRY_CAST(LTRIM(RTRIM([value])) AS BIGINT) IS NOT NULL;

		If @IsPermissionData=1
		Begin
			SELECT distinct M.PermissionConstant + '.' + P.PermissionName as Name, M.IsPage, M.DisplayOrder, M.ModuleCode, M.Id, M.ModuleIcon, M.RouterLink, M.ParentId, M.IsMenu,DisplayOrder,M.IsReport,M.ShowAsTopMenu,M.NewModuleIcon,M.NewMenuName,M.ImgClass,M.IsMobileMenu,M.MobileMenuName,ISNULL(M.MobileMenuSequence,0) MobileMenuSequence
				FROM dbo.ModuleHierarchyMaster M WITH (NOLOCK)
				INNER JOIN dbo.RolePermission R WITH (NOLOCK) ON R.ModuleHierarchyMasterId = M.Id
				Inner Join dbo.PermissionMaster P WITH (NOLOCK) on R.PermissionID = P.PermissionID
				WHERE R.UserRoleId in (SELECT UserRoleId FROM @Roles)
				Order By M.DisplayOrder
		End
		Else
		Begin
			-- Distinct (module, permission) of the roles
			SELECT DISTINCT R.[ModuleHierarchyMasterId] AS ModuleId, R.[PermissionID]
			INTO #RolePerm
			FROM [dbo].[RolePermission] R WITH (NOLOCK)
			WHERE R.[UserRoleId] IN (SELECT UserRoleId FROM @Roles);

			-- Each permitted module with all its ancestors (self included); a parent gets the permissions of its children
			;WITH Anc (ModuleId, AncestorId, ParentId) AS
			(
				SELECT M.[Id], M.[Id], M.[ParentId]
				FROM [dbo].[ModuleHierarchyMaster] M WITH (NOLOCK)
				WHERE M.[Id] IN (SELECT ModuleId FROM #RolePerm)
				UNION ALL
				SELECT A.ModuleId, P.[Id], P.[ParentId]
				FROM Anc A
				INNER JOIN [dbo].[ModuleHierarchyMaster] P WITH (NOLOCK) ON P.[Id] = A.ParentId
			)
			SELECT DISTINCT A.AncestorId AS ID, RP.[PermissionID]
			INTO #Menu
			FROM #RolePerm RP
			INNER JOIN Anc A ON A.ModuleId = RP.ModuleId;

			SELECT M.[ID], CAST(M.[Name] AS VARCHAR(200)) AS Name, M.[ParentID], M.[IsMenu], CAST(M.[ModuleIcon] AS VARCHAR(200)) AS ModuleIcon,
				CAST(M.[RouterLink] AS VARCHAR(500)) AS RouterLink, T.[PermissionID], M.[IsCreateMenu] AS CreateMenu, M.[ModuleId], M.[DisplayOrder], M.[IsReport],
				M.[ShowAsTopMenu], CAST(M.[NewModuleIcon] AS VARCHAR(200)) AS NewModuleIcon, CAST(M.[NewMenuName] AS VARCHAR(1000)) AS NewMenuName,
				CAST(M.[ImgClass] AS VARCHAR(1000)) AS ImgClass, M.[IsMobileMenu], CAST(M.[MobileMenuName] AS VARCHAR(250)) AS MobileMenuName,
				ISNULL(M.[MobileMenuSequence], 0) AS MobileMenuSequence
			INTO #TempTable
			FROM #Menu T
			INNER JOIN [dbo].[ModuleHierarchyMaster] M WITH (NOLOCK) ON M.[Id] = T.[ID];

			-- "Create" menus only when the module has View (PermissionID 1)
			DELETE FROM #TempTable WHERE CreateMenu = 1 AND ID NOT IN (
				SELECT T.ID FROM #TempTable T WHERE T.CreateMenu = 1
				  AND EXISTS (SELECT 1 FROM #TempTable X WHERE ISNULL(X.ModuleId, 0) = T.ModuleId AND X.PermissionID = 1));

			SELECT ID, Name, ParentID, IsMenu, ModuleIcon, RouterLink, PermissionID,DisplayOrder,IsReport,ShowAsTopMenu,NewModuleIcon,NewMenuName,ImgClass,IsMobileMenu,MobileMenuName,MobileMenuSequence
			FROM  #TempTable Order By DisplayOrder
		End
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
          , @AdhocComments     VARCHAR(150)    = 'GetMenuPermission'
          , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RoleId, '') + ''''
          , @ApplicationName VARCHAR(100) = 'PAS'
-------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
          exec spLogException
                   @DatabaseName           =  @DatabaseName
                 , @AdhocComments          =  @AdhocComments
                 , @ProcedureParameters	   =  @ProcedureParameters
                 , @ApplicationName        =  @ApplicationName
                 , @ErrorLogID             =  @ErrorLogID OUTPUT ;
          RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
          RETURN(1);
	END CATCH
End
