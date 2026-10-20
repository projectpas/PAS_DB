/*************************************************************
 ** File:   [GetTabPermission]
 ** Description: Modules (with their ancestors) and permissions of the given roles - used for tab / route access
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author					Change Description
 ** -----------------------------------------------------------
    1					Unknown					Created
	2    20/10/2026		Vishal Suthar			Performance optimization for role permissions

-- EXEC [dbo].[GetTabPermission] '1'
************************************************************************/
CREATE Procedure [dbo].[GetTabPermission]
	@RoleId varchar(max)
AS
Begin
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		-- Distinct (module, permission) of the roles (comma separated)
		SELECT DISTINCT R.[ModuleHierarchyMasterId] AS ModuleId, R.[PermissionID]
		INTO #RolePerm
		FROM [dbo].[RolePermission] R WITH (NOLOCK)
		WHERE R.[UserRoleId] IN (SELECT TRY_CAST(LTRIM(RTRIM([value])) AS BIGINT) FROM STRING_SPLIT(@RoleId, ','));

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
		SELECT DISTINCT M.[ID], M.[Name], M.[ParentID], M.[IsMenu], M.[ModuleIcon], M.[RouterLink], RP.[PermissionID], M.[DisplayOrder]
		FROM #RolePerm RP
		INNER JOIN Anc A ON A.ModuleId = RP.ModuleId
		INNER JOIN [dbo].[ModuleHierarchyMaster] M WITH (NOLOCK) ON M.[Id] = A.AncestorId
		ORDER BY M.[DisplayOrder];
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetTabPermission'
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RoleId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
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
