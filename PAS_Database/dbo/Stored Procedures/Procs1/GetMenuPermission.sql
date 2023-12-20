
CREATE Procedure [dbo].[GetMenuPermission] 
	@RoleId varchar(max),
	@IsPermissionData bit = 0
AS
Begin
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
		BEGIN

			IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
			BEGIN
			DROP TABLE #TempTable
			END

			CREATE TABLE #TempTable
			(
			 ID int null,
			 Name varchar(200) null,
			 ParentID int null,
			 IsMenu bit null,
			 ModuleIcon varchar(200) null,
			 RouterLink varchar(500) null,
			 PermissionID int null,
			 CreateMenu bit null,
			 ModuleId int null,
			 DisplayOrder int null,
			 IsReport bit null,
			)



			If @IsPermissionData=1
			Begin
				--Old Query
				--WITH MenuSettings1(ID, MenuName, ParentID, IsMenu,PermissionName)
				--AS
				--(
				--	SELECT M.ID,M.Name as MenuName, M.ParentID ,M.IsMenu,P.PermissionName
				--	FROM dbo.ModuleHierarchyMaster M 
				--	INNER JOIN dbo.RolePermission R ON R.ModuleHierarchyMasterId=M.Id
				--	Inner Join dbo.PermissionMaster P on R.PermissionID =P.PermissionID
				--	WHERE R.UserRoleId in (Select * from [dbo].[SplitString](@RoleId,','))
				--	UNION ALL 
				--	SELECT  M.ID,M.Name as MenuName, M.ParentID ,M.IsMenu,M1.PermissionName
				--	FROM dbo.ModuleHierarchyMaster M 
				--	INNER JOIN MenuSettings1 M1 ON M1.ParentID=M.ID
				--)

				--SELECT distinct MenuName+'.'+PermissionName as Name,M.IsPage,M.DisplayOrder,M.ModuleCode,M.Id,M.ModuleIcon,M.RouterLink,M.ParentId,M.IsMenu FROM MenuSettings1
				--Inner Join dbo.ModuleHierarchyMaster M on MenuSettings1.ParentID=M.Id and M.ParentId is null
				SELECT distinct M.PermissionConstant + '.' + P.PermissionName as Name, M.IsPage, M.DisplayOrder, M.ModuleCode, M.Id, M.ModuleIcon, M.RouterLink, M.ParentId, M.IsMenu,DisplayOrder,M.IsReport
					FROM dbo.ModuleHierarchyMaster M WITH (NOLOCK)
					INNER JOIN dbo.RolePermission R WITH (NOLOCK) ON R.ModuleHierarchyMasterId = M.Id
					Inner Join dbo.PermissionMaster P WITH (NOLOCK) on R.PermissionID = P.PermissionID
					WHERE R.UserRoleId in (Select * from [dbo].[SplitString](@RoleId, ','))
					Order By M.DisplayOrder
			End
			Else
			Begin
				;WITH MenuSettings1(ID, Name, ParentID, IsMenu, ModuleIcon, RouterLink, PermissionID, CreateMenu, ModuleID, DisplayOrder,IsReport)
				AS
				(
					SELECT M.ID,M.Name as MenuName, M.ParentID, M.IsMenu, M.ModuleIcon, M.RouterLink, R.PermissionID, M.IsCreateMenu, M.Moduleid, M.DisplayOrder,M.IsReport
					FROM dbo.ModuleHierarchyMaster M WITH (NOLOCK)
					INNER JOIN dbo.RolePermission R WITH (NOLOCK) ON R.ModuleHierarchyMasterId = M.Id
					WHERE R.UserRoleId in (Select * from [dbo].[SplitString](@RoleId, ','))
					UNION ALL 
					SELECT M.ID, M.Name as MenuName, M.ParentID, M.IsMenu, M.ModuleIcon, M.RouterLink, M1.PermissionId, M.IsCreateMenu, M.Moduleid, M.DisplayOrder,M.IsReport
					FROM dbo.ModuleHierarchyMaster M WITH (NOLOCK) 
					INNER JOIN MenuSettings1 M1 ON M1.ParentID = M.ID
				)
				INSERT INTO #TempTable
				SELECT distinct * FROM MenuSettings1 M
				--Where IsMenu = 1
				Order By DisplayOrder

				DELETE FROM #TempTable WHERE CreateMenu = 1 AND ID NOT IN (
				SELECT id FROM #TempTable T WHERE CreateMenu = 1  
						 AND (SELECT count(id) FROM #TempTable where ISNULL(ModuleId, 0) = T.ModuleId AND  PermissionID = 1) > 0)

				SELECT ID, Name, ParentID, IsMenu, ModuleIcon, RouterLink, PermissionID,DisplayOrder,IsReport
				FROM  #TempTable Order By DisplayOrder
			End

			IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
			BEGIN
			DROP TABLE #TempTable
			END
		END
		COMMIT  TRANSACTION

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