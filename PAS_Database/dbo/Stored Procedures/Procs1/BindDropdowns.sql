﻿CREATE     PROCEDURE [dbo].[BindDropdowns]    
	@TableName VARCHAR(50) = null,    
	@Parameter1 VARCHAR(50)= null,    
	@Parameter2 VARCHAR(50) = null,    
	@masterCompanyId VARCHAR(50) = null,    
	@Count VARCHAR(10) = null,    
	@Parameter3 VARCHAR(50) = null,    
	@Parameter4 VARCHAR(50) = null    
AS    
 BEGIN    
    
   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
      SET NOCOUNT ON    
    
   BEGIN TRY    
   BEGIN TRANSACTION    
    BEGIN     
     DECLARE @Sql NVARCHAR(MAX);    
    
     IF(@TableName = 'Employee')    
      BEGIN    
       SELECT EmployeeId AS Value, FirstName + ' ' + LastName AS Label    
       FROM dbo.Employee WHERE IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND MasterCompanyId = @masterCompanyId    
       ORDER BY FirstName    
      END    
     ELSE IF @Parameter3 IS NOT NULL  AND @Parameter3 != '' AND  @Parameter4 IS NOT NULL  AND @Parameter4 != ''    
      BEGIN     
       IF(@TableName = 'StocklineAdjustmentDataType')    
       BEGIN    
        SET @Sql = N'SELECT CAST ( ' + @Parameter1 + ' AS BIGINT) As Value,CAST ( ' + @Parameter2 + ' AS VARCHAR) AS Label FROM dbo.' + @TableName +     
           ' WHERE IsActive=1 AND ISNULL(IsDeleted, 0) = 0 AND MasterCompanyId = ' + @masterCompanyId + ' AND CAST ( ' + @Parameter2 + ' AS VARCHAR) !='''' AND CAST ( '+ @Parameter3 +' AS VARCHAR) = ' + @Parameter4+'  ORDER BY SortOrder';    
       END    
       ELSE    
       BEGIN    
        SET @Sql = N'SELECT CAST ( ' + @Parameter1 + ' AS BIGINT) As Value,CAST ( ' + @Parameter2 + ' AS VARCHAR) AS Label FROM dbo.' + @TableName +     
           ' WHERE IsActive=1 AND ISNULL(IsDeleted, 0) = 0 AND MasterCompanyId = ' + @masterCompanyId + ' AND CAST ( ' + @Parameter2 + ' AS VARCHAR) !='''' AND CAST ( '+ @Parameter3 +' AS VARCHAR) IN(' + @Parameter4+')  ORDER BY '+@Parameter2;    
       END    
      END    
     ELSE IF @Count IS NULL OR @Count = '0' AND @Parameter3 IS NOT NULL AND @Parameter3 != ''    
        BEGIN     
       IF(@TableName = 'StocklineAdjustmentDataType')    
       BEGIN    
        SET @Sql = N'SELECT CAST ( '+ @Parameter1 + ' AS BIGINT)  As Value,  CONCAT(CAST ( '+ @Parameter3 +'  AS VARCHAR), ''-'', CAST('+@Parameter2+' as VARCHAR)) AS Label FROM dbo.' + @TableName+       
         ' WHERE IsActive=1 AND ISNULL(IsDeleted, 0) = 0 AND MasterCompanyId = '+ @masterCompanyId +' AND CAST ( '+ @Parameter2+' AS VARCHAR) !='''' AND CAST(' + @Parameter3 + '  AS VARCHAR)!=''''   ORDER BY SortOrder';    
       END    
       ELSE IF(@TableName = 'CommonTeardownType')    
       BEGIN    
        SET @Sql = N'SELECT CAST ( '+ @Parameter1 + ' AS BIGINT)  As Value,  CAST('+@Parameter2+' as VARCHAR) AS Label FROM dbo.' + @TableName+       
         ' WHERE IsActive=1 AND ISNULL(IsDeleted, 0) = 0 AND MasterCompanyId = '+ @masterCompanyId +' AND CAST ( '+ @Parameter2+' AS VARCHAR) !='''' AND CAST(' + @Parameter3 + '  AS VARCHAR)!=''''   ORDER BY ' +@Parameter3;    
       END    
       ELSE    
       BEGIN    
        SET @Sql = N'SELECT CAST ( '+ @Parameter1 + ' AS BIGINT)  As Value,  CONCAT(CAST ( '+ @Parameter3 +'  AS VARCHAR), ''-'', CAST('+@Parameter2+' as VARCHAR)) AS Label FROM dbo.' + @TableName+       
         ' WHERE IsActive=1 AND ISNULL(IsDeleted, 0) = 0 AND MasterCompanyId = '+ @masterCompanyId +' AND CAST ( '+ @Parameter2+' AS VARCHAR) !='''' AND CAST(' + @Parameter3 + '  AS VARCHAR)!=''''   ORDER BY ' + @Parameter2;      
       END    
        END    
     ELSE IF @Count IS NULL OR @Count = '0'    
      BEGIN    
       IF(@TableName = 'StocklineAdjustmentDataType')    
       BEGIN    
        SET @Sql = N'SELECT CAST ( '+@Parameter1+' AS BIGINT) As Value, CAST ( ' + @Parameter2 + ' AS VARCHAR) AS Label FROM dbo.' + @TableName +     
            ' WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 AND MasterCompanyId = ' + @masterCompanyId + ' AND CAST ( ' + @Parameter2 + ' AS VARCHAR) !=''''   ORDER BY SortOrder';    
       END  
	   ELSE IF(@TableName = 'StockLineAdjustmentType')    
       BEGIN    
        SET @Sql = N'SELECT CAST ( '+@Parameter1+' AS BIGINT) As Value, CAST ( ' + @Parameter2 + ' AS VARCHAR) AS Label FROM dbo.' + @TableName +     
            ' WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 AND MasterCompanyId = ' + @masterCompanyId + ' AND CAST ( ' + @Parameter2 + ' AS VARCHAR) !=''''   ORDER BY SortOrder';    
       END
       ELSE    
       BEGIN    
        SET @Sql = N'SELECT CAST ( '+@Parameter1+' AS BIGINT) As Value, CAST ( ' + @Parameter2 + ' AS VARCHAR(50)) AS Label FROM dbo.' + @TableName +     
            ' WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 AND MasterCompanyId = ' + @masterCompanyId + ' AND CAST ( ' + @Parameter2 + ' AS VARCHAR) !=''''   ORDER BY ' + @Parameter2;    
       END    
      END    
     ELSE    
      BEGIN    
       IF(@TableName = 'StocklineAdjustmentDataType')    
       BEGIN    
        SET @Sql = N'SELECT TOP ' +@Count+ ' CAST ( '+ @Parameter1 + ' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR) AS Label FROM dbo.' + @TableName +     
           ' WHERE IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND MasterCompanyId = ' + @masterCompanyId + ' AND CAST ( '+ @Parameter2 + ' AS VARCHAR) != ''''  ORDER BY SortOrder';    
       END    
       ELSE    
       BEGIN    
        SET @Sql = N'SELECT TOP ' +@Count+ ' CAST ( '+ @Parameter1 + ' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR) AS Label FROM dbo.' + @TableName +     
           ' WHERE IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND MasterCompanyId = ' + @masterCompanyId + ' AND CAST ( '+ @Parameter2 + ' AS VARCHAR) != ''''  ORDER BY ' + @Parameter2;    
       END    
      END    
     EXEC sp_executesql @Sql;    
    END    
   COMMIT  TRANSACTION    
  END TRY        
  BEGIN CATCH          
   IF @@trancount > 0    
    PRINT 'ROLLBACK'    
    ROLLBACK TRAN;    
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
              , @AdhocComments     VARCHAR(150)    = 'BindDropdowns'     
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@TableName, '') + ''',    
                @Parameter2 = ' + ISNULL(@Parameter1,'') + ',     
                @Parameter3 = ' + ISNULL(@Parameter2,'') + ',     
                @Parameter4 = ' + ISNULL(@masterCompanyId,'') + ',     
                @Parameter5 = ' + ISNULL(@Count,'') + ',     
                @Parameter6 = ' + ISNULL(@Parameter3,'') + ',     
                @Parameter7 = ' + ISNULL(CAST(@Parameter4 AS VARCHAR(10)) ,'') +''    
              , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
              exec spLogException     
                       @DatabaseName           = @DatabaseName    
                     , @AdhocComments          = @AdhocComments    
                     , @ProcedureParameters = @ProcedureParameters    
                     , @ApplicationName        =  @ApplicationName    
                     , @ErrorLogID             = @ErrorLogID OUTPUT;    
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
              RETURN(1);    
  END CATCH    
 END