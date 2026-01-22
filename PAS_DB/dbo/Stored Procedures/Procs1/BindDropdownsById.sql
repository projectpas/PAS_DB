
CREATE PROCEDURE [dbo].[BindDropdownsById]
@TableName VARCHAR(50) = Null,
@Parameter1 VARCHAR(50) = Null,
@Parameter2 VARCHAR(50) = Null,
@Parameter3 VARCHAR(50) = Null,
@Parameter4 VARCHAR(50) = Null

AS
	BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @Sql NVARCHAR(MAX);

		IF(@TableName = 'Employee')
			BEGIN
				SELECT TOP 1 EmployeeId AS Value,FirstName + ' ' + LastName AS Label
				FROM dbo.Employee WHERE EmployeeId = @Parameter4
				ORDER BY FirstName
			END
		ELSE IF(@TableName = 'GLAccount')
			BEGIN
				SELECT TOP 1 GLAccountId AS Value, AccountCode + ' - ' + AccountName AS Label
				FROM dbo.GLAccount WHERE GLAccountId = @Parameter4
				ORDER BY AccountName
			END
		ELSE IF @Parameter3 IS NOT NULL  AND @Parameter3 != '' AND  @Parameter4 IS NOT NULL  AND @Parameter4 != ''
			BEGIN
				SET @Sql = N'SELECT TOP 1 CAST ( '+ @Parameter1 +' AS BIGINT) As Value,CAST ( '+ @Parameter2 + ' AS VARCHAR) AS Label FROM dbo.' + @TableName+ 
						' WHERE CAST ( '+ @Parameter2 +' AS VARCHAR) !='''' AND CAST ( '+ @Parameter3 +' AS VARCHAR) = '+ @Parameter4 +'  ORDER BY '+ @Parameter2;
			END		
		ELSE
			BEGIN
				SET @Sql = N'SELECT TOP 1 CAST ( '+ @Parameter1 +' AS BIGINT) As Value,CAST ( '+ @Parameter2 +  ' AS VARCHAR) AS Label FROM dbo.' + @TableName+ 
						' WHERE CAST ( '+ @Parameter2 +' AS VARCHAR) !=''''  ORDER BY '+ @Parameter2;
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
													   @Parameter5 = ' + ISNULL(CAST(@Parameter4 AS VARCHAR(10)) ,'') +''
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