  /*************************************************************           
 ** File:   [UpdateEmployeePassword]          
 ** Author:    
 ** Description: This stored procedure is used to update password to respected company
 ** Purpose:         
 ** Date:   
          
 ** PARAMETERS:          

 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		-------------------------------- 
    1    25-11-2025    Amit Ghediya       Created 
     
**************************************************************/
CREATE     PROCEDURE [dbo].[UpdateEmployeePassword]  
@EmployeeId  BIGINT = NULL,
@Password VARCHAR(MAX) = NULL,
@MasterCompanyId INT = NULL,
@IsSuperAdmin BIT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 BEGIN TRANSACTION  
  BEGIN  
		DECLARE @Sql NVARCHAR(MAX); 
		DECLARE @paramDefs NVARCHAR(MAX);

		IF(@IsSuperAdmin = 1)
		BEGIN
			DECLARE @ConnectionString NVARCHAR(MAX) = NULL;
			DECLARE @TargetDBName SYSNAME = NULL;

			IF @MasterCompanyId IS NOT NULL
			BEGIN
				SELECT @ConnectionString = [ConnectionString]
				FROM dbo.MasterCompany WITH (NOLOCK)
				WHERE MasterCompanyId = @MasterCompanyId;
			END

			SET @TargetDBName = (SELECT REPLACE(value, 'Initial Catalog=', '') AS InitialCatalogm FROM STRING_SPLIT(@ConnectionString, ';') WHERE value LIKE 'Initial Catalog=%');
			
			--SET @sql = '
			--	UPDATE [' + @TargetDBName + '].dbo.AspNetUsers
			--	SET PasswordHash = '+ @Password +',
			--		IsResetPassword = 1
			--	WHERE EmployeeId = '+ @EmployeeId +'';

			---- Execute dynamic SQL
			--EXEC sp_executesql 
			--	@sql, 
			--	@paramDefs;
			SET @sql = '
				UPDATE [' + @TargetDBName + '].dbo.AspNetUsers
				SET PasswordHash = @Password,
					IsResetPassword = 1
				WHERE EmployeeId = @EmployeeId;
			';

			SET @paramDefs = N'@Password NVARCHAR(MAX), @EmployeeId BIGINT';

			EXEC sp_executesql 
				@sql,
				@paramDefs,
				@Password = @Password,
				@EmployeeId = @EmployeeId;
		END
	   
	    Select  @EmployeeId as [EmployeeId]   

  END  
  COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'UpdateEmployeePassword'   
            , @ProcedureParameters VARCHAR(3000)  = '@EmployeeId = '''+ ISNULL(@EmployeeId, '') + ''  
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