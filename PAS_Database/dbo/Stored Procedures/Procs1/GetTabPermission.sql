
CREATE Procedure [dbo].[GetTabPermission] 
	@RoleId varchar(max)
AS
Begin
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		;WITH MenuSettings1(ID, Name, ParentID, IsMenu,ModuleIcon,RouterLink,PermissionID,DisplayOrder)
		AS
		(
			SELECT M.ID, M.Name as MenuName, M.ParentID, M.IsMenu, M.ModuleIcon, M.RouterLink, R.PermissionID,M.DisplayOrder
			FROM dbo.ModuleHierarchyMaster M WITH (NOLOCK)
			INNER JOIN dbo.RolePermission R WITH (NOLOCK) ON R.ModuleHierarchyMasterId=M.Id
			WHERE R.UserRoleId in (Select * from [dbo].[SplitString](@RoleId, ','))
			UNION ALL 
			SELECT M.ID, M.Name as MenuName, M.ParentID, M.IsMenu, M.ModuleIcon, M.RouterLink, M1.PermissionId, M.DisplayOrder
			FROM dbo.ModuleHierarchyMaster M WITH (NOLOCK)
			INNER JOIN MenuSettings1 M1 ON M1.ParentID=M.ID
		)

		SELECT distinct * FROM MenuSettings1 M
		Order By DisplayOrder
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