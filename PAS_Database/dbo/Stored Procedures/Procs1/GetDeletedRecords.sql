-- EXEC GetDeletedRecords 'Condition','ConditionId','Description'
--EXEC GetDeletedRecords 'StocklineAdjustment'

CREATE PROCEDURE [dbo].[GetDeletedRecords]
@TableName VARCHAR(50) = Null,
@Parameter1 VARCHAR(50) = Null,
@Parameter2 VARCHAR(50) = Null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		DECLARE @Sql NVARCHAR(MAX);		
		IF @Parameter1 IS NOT NULL  AND @Parameter1 !='' 
		BEGIN
		SET @Sql = N'SELECT CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR) AS Label FROM dbo.' + @TableName+ 
						' WHERE IsDeleted=1 AND CAST ( '+@Parameter2+' AS VARCHAR) !=''''   ORDER BY '+@Parameter2;
		END
		PRINT @Sql
		EXEC sp_executesql @Sql;
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetDeletedRecords'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@TableName, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Parameter1, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Parameter2, '') AS varchar(100))
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END