/*************************************************************           
 ** File:   [USP_CreateEmployeeUserRole]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Create EmployeeUserRole List
 ** Purpose:         
 ** Date:   24-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    24-06-2025    Sahdev Saliya       Created  

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_CreateEmployeeUserRole]
   @EmployeeId BIGINT,                           
   @tbl_EmployeeUserRole [dbo].[EmployeeUserRoleType] READONLY  
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        BEGIN TRANSACTION;

		DECLARE @CurrentRowId INT = 1;
		DECLARE @EmpId BIGINT = 0;

		IF OBJECT_ID('tempdb..#Results') IS NOT NULL
			DROP TABLE #Results

		SELECT ROW_NUMBER() over (order by (select null)) RowId,* into #Results from @tbl_EmployeeUserRole;

		IF EXISTS(SELECT 1 FROM #Results)
		BEGIN
			SET @EmpId = (SELECT [EmployeeId] FROM #Results WITH(NOLOCK) WHERE RowId = @CurrentRowId)
		END
		ELSE 
		BEGIN
			SET @EmpId = @EmployeeId
		END

		IF EXISTS(SELECT 1 FROM [dbo].EmployeeUserRole WITH(NOLOCK) WHERE EmployeeId = @EmpId AND ISNULL(IsActive, 0) = 1)
		BEGIN
			DELETE FROM [dbo].EmployeeUserRole WHERE EmployeeId = @EmpId AND ISNULL(IsActive, 0) = 1;
		END

        INSERT INTO [dbo].EmployeeUserRole
        (EmployeeId, RoleId, IsActive, IsDeleted, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate)
        SELECT EmployeeId, RoleId, IsActive, IsDeleted, CreatedBy, UpdatedBy, UpdatedDate, CreatedDate    
        FROM @tbl_EmployeeUserRole;

		SELECT * FROM [dbo].EmployeeUserRole

        COMMIT TRANSACTION;
    END TRY
   BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					ROLLBACK TRAN;  
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_CreateEmployeeUserRole' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EmployeeId, '') 

				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END