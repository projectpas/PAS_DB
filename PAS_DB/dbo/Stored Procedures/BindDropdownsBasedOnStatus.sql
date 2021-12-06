--EXEC BindDropdownsBasedOnStatus 'Condition','ConditionId','Description',0,IsActive,'',IsDeleted,0
CREATE PROCEDURE [dbo].[BindDropdownsBasedOnStatus]
@TableName VARCHAR(50) = null,
@Parameter1 VARCHAR(50) = null,
@Parameter2 VARCHAR(50) = null,
@Count VARCHAR(10),
@Parameter3 VARCHAR(50) = null,
@Parameter4 VARCHAR(50) = null,
@Parameter5 VARCHAR(50) = null,
@Parameter6 VARCHAR(50) = null

AS
	BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON  
	BEGIN TRY
		DECLARE @Sql NVARCHAR(MAX);

		IF(@Parameter4 = '')
		set @Parameter4 = @Parameter3
		IF(@Parameter6 = '')
		set @Parameter6 = @Parameter5

		IF(@TableName = 'Employee')
			BEGIN
				SELECT EmployeeId AS Value,FirstName + ' ' + LastName AS Label
				FROM dbo.Employee WHERE IsActive = 1 AND ISNULL(IsDeleted, 0) = 0
				ORDER BY FirstName
			END
		ELSE IF @Parameter3 IS NOT NULL  AND @Parameter3 != '' AND  @Parameter4 IS NOT NULL  AND @Parameter4 != '' AND @Parameter5 IS NOT NULL  AND @Parameter5 !='' AND  @Parameter6 IS NOT NULL  AND @Parameter6 !=''
			BEGIN
				SET @Sql = N'SELECT CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( ' + @Parameter2+  ' AS VARCHAR) AS Label FROM dbo.' + @TableName+ 
						' WHERE CAST ( '+@Parameter2+' AS VARCHAR) != '''' AND CAST ( ' + @Parameter3 +' AS VARCHAR) = '+@Parameter4+' AND CAST ( '+ @Parameter5 +' AS VARCHAR) = '+@Parameter6+'  ORDER BY '+@Parameter2;
			END

		ELSE IF @Count IS NULL OR @Count = '0'
			BEGIN
				SET @Sql = N'SELECT CAST ( '+ @Parameter1 +' AS BIGINT) As Value,CAST ( '+ @Parameter2 + ' AS VARCHAR) AS Label FROM dbo.' + @TableName+ 
						' WHERE CAST ( '+ @Parameter2 +' AS VARCHAR) != ''''   ORDER BY '+ @Parameter2;
			END					
		
		ELSE
			BEGIN
				SET @Sql = N'SELECT TOP ' +@Count+ ' CAST ( '+ @Parameter1 +' AS BIGINT) As Value,CAST ( '+ @Parameter2 + ' AS VARCHAR) AS Label FROM dbo.' + @TableName+ 
						' WHERE CAST ( '+ @Parameter2+' AS VARCHAR) != ''''  ORDER BY '+ @Parameter2;
			END
		PRINT @Sql
		EXEC sp_executesql @Sql;
	END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'BindDropdowns' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@TableName, '') + ''',
													   @Parameter2 = ' + ISNULL(@Parameter1,'') + ', 
													   @Parameter3 = ' + ISNULL(@Parameter2,'') + ', 
													   @Parameter4 = ' + ISNULL(@Parameter3,'') + ', 
													   @Parameter5 = ' + ISNULL(@Parameter4,'') + ', 
													   @Parameter6 = ' + ISNULL(@Parameter5,'') + ', 
													   @Parameter7 = ' + ISNULL(@Count,'') + ', 
													   @Parameter8 = ' + ISNULL(CAST(@Parameter6 AS VARCHAR(10)) ,'') +''
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