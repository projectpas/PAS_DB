  /*************************************************************           
 ** File:   [USP_CheckLegalEntity_Exist]          
 ** Author:    
 ** Description: This stored procedure is used to Restore Deleted Records
 ** Purpose:         
 ** Date:   
          
 ** PARAMETERS:          

 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		-------------------------------- 
    1   10/08/2023   Bhargav Saliya   UTC Date Changes
	2   25/11/2025   Amit Ghediya     Get Employee data from company db if ther eis role for SuperAdmin.
     
**************************************************************/
CREATE   PROCEDURE [dbo].[UpdateDeletedRecords]  
@TableName VARCHAR(50),  
@Parameter1 VARCHAR(50),  
@Parameter2 VARCHAR(50),
@MasterCompanyId INT = NULL,
@IsSuperAdmin bit = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 BEGIN TRANSACTION  
  BEGIN  
		DECLARE @Sql NVARCHAR(MAX); 
		DECLARE @paramDefs NVARCHAR(MAX);

		IF(@IsSuperAdmin = 1 AND @TableName = 'Employee')
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

			SET @sql = '
				UPDATE [' + @TargetDBName + '].dbo.Employee
				SET IsDeleted = 0,
					UpdatedDate = GETUTCDATE()
				WHERE EmployeeId = '+@Parameter2+'';

			-- Execute dynamic SQL
			EXEC sp_executesql 
				@sql, 
				@paramDefs;
		END
		ELSE
		BEGIN
			 IF @Parameter1 IS NOT NULL  AND @Parameter1 !='' AND  @Parameter2 IS NOT NULL  AND @Parameter2 !=''  
		     BEGIN  
				  SET @Sql = N'UPDATE ' + @TableName+ ' SET IsDeleted = 0, UpdatedDate = GETUTCDATE() WHERE IsDeleted = 1 AND CAST ( '+ @Parameter1 +' AS VARCHAR) = '+@Parameter2+'';  
		     END  
		     --PRINT @Sql  
		     EXEC sp_executesql @Sql;  
		END
	      
	   
	    Select  @Parameter2 as [Value]   

  END  
  COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'UpdateDeletedRecords'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@TableName, '') + ''  
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