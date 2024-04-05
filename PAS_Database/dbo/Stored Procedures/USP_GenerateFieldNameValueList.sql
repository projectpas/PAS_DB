/***************************************************************  
 ** File:   [USP_GenerateFieldNameValueList]             
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to add/update data
 ** Purpose:           
 ** Date:   07/13/2022  
            
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
	1    07/13/2022   Vishal Suthar  Created
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GenerateFieldNameValueList] 
(
	@TableName AS NVARCHAR(100),
	@WhereClause AS NVARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		DECLARE @ExecStr NVARCHAR(MAX)

		DROP TABLE IF EXISTS #tmp_Col2Row

		CREATE TABLE #tmp_Col2Row
		(
			Field_Name NVARCHAR(128) NOT NULL,
			Field_Value NVARCHAR(MAX) NULL
		)

		SET @ExecStr = N' Insert Into #tmp_Col2Row (Field_Name , Field_Value) '
		SELECT @ExecStr += (SELECT N'SELECT ''' + C.name + ''', CONVERT(NVARCHAR(MAX), ' + QUOTENAME(C.name) + ') FROM ' + QUOTENAME(@TableName) + @WhereClause + Char(10) + ' UNION ALL '
				 FROM SYS.COLUMNS AS C
				 WHERE (C.OBJECT_ID = OBJECT_ID(@TableName)) 
				 FOR XML PATH(''))
		SELECT @ExecStr = LEFT(@ExecStr, LEN(@ExecStr) - LEN('Union All'))
	
		EXEC (@ExecStr)

		SELECT * FROM #tmp_Col2Row
	END TRY    
	BEGIN CATCH
		DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GenerateFieldNameValueList'
			,@ProcedureParameters VARCHAR(3000) = '@TableName = ''' + CAST(ISNULL(@TableName, '') AS varchar(100))			 
			 + '@WhereClause = ''' + CAST(ISNULL(@WhereClause , '') as varchar(100))
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
	END CATCH
END