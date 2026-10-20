/*************************************************************************************************
 ** File:    [GetTabPermission]
 ** Description: Returns the menus / tabs (with their parents) a role (or comma separated roles)
 **              has permission for. Used by /api/userrolepermission/getUserTabPermissionByRoleId
 **
 ** Change History
 ** S NO   Date            Author          Change Description
 ** 1      16-OCT-2026     RAJESH GAMI     [PN-18034] Performance: role ids are split once into a typed temp table,
 **                                        (module, permission) pairs are de-duplicated BEFORE the parent walk
 **                                        (set based loop instead of a recursive CTE that walked the hierarchy once per
 **                                        RolePermission row), final DISTINCT over wide NVARCHAR columns removed,
 **                                        uses new index IX_RolePermission_UserRoleId. Output columns / rows unchanged.
 *************************************************************************************************/
CREATE PROCEDURE [dbo].[GetTabPermission]
	@RoleId VARCHAR(MAX)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		/* Role ids as typed values (SplitString returns NVARCHAR(MAX), which gives poor estimates / conversions) */
		CREATE TABLE #Roles (RoleId BIGINT NOT NULL PRIMARY KEY);

		INSERT INTO #Roles (RoleId)
		SELECT DISTINCT TRY_CAST(LTRIM(RTRIM(S.Item)) AS BIGINT)
		FROM dbo.SplitString(@RoleId, ',') S
		WHERE TRY_CAST(LTRIM(RTRIM(S.Item)) AS BIGINT) IS NOT NULL;

		/* One row per (module, permission); Lvl = distance from the module the role was granted */
		CREATE TABLE #Tree
		(
			ID           INT NOT NULL,
			PermissionID INT NOT NULL,
			Lvl          INT NOT NULL,
			PRIMARY KEY (ID, PermissionID)
		);

		INSERT INTO #Tree (ID, PermissionID, Lvl)
		SELECT R.ModuleHierarchyMasterId, R.PermissionID, 0
		FROM #Roles RL
		INNER JOIN dbo.RolePermission R WITH (NOLOCK) ON R.UserRoleId = RL.RoleId
		GROUP BY R.ModuleHierarchyMasterId, R.PermissionID;

		/* Add the parent of every new row, level by level, until no new (module, permission) pair appears */
		DECLARE @Lvl INT = 0, @Rows INT = 1;

		WHILE @Rows > 0 AND @Lvl < 50
		BEGIN
			INSERT INTO #Tree (ID, PermissionID, Lvl)
			SELECT M.ParentId, T.PermissionID, @Lvl + 1
			FROM #Tree T
			INNER JOIN dbo.ModuleHierarchyMaster M WITH (NOLOCK) ON M.Id = T.ID
			WHERE T.Lvl = @Lvl
			  AND M.ParentId IS NOT NULL
			  AND NOT EXISTS (SELECT 1 FROM #Tree X WHERE X.ID = M.ParentId AND X.PermissionID = T.PermissionID)
			GROUP BY M.ParentId, T.PermissionID;

			SET @Rows = @@ROWCOUNT;
			SET @Lvl += 1;
		END

		SELECT M.Id           AS ID,
		       M.Name         AS Name,
		       M.ParentId     AS ParentID,
		       M.IsMenu       AS IsMenu,
		       M.ModuleIcon   AS ModuleIcon,
		       M.RouterLink   AS RouterLink,
		       T.PermissionID AS PermissionID,
		       M.DisplayOrder AS DisplayOrder
		FROM #Tree T
		INNER JOIN dbo.ModuleHierarchyMaster M WITH (NOLOCK) ON M.Id = T.ID
		ORDER BY M.DisplayOrder, M.Id, T.PermissionID;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;

		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments       VARCHAR(150)  = 'GetTabPermission'
		, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + ISNULL(@RoleId, '') + ''''
		, @ApplicationName     VARCHAR(100)  = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName         = @DatabaseName
			, @AdhocComments        = @AdhocComments
			, @ProcedureParameters  = @ProcedureParameters
			, @ApplicationName      = @ApplicationName
			, @ErrorLogID           = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END
