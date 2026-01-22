/*************************************************************
 ** File:   [usp_GenerateCsvData]
 ** Author:   Vishal Suthar
 ** Description: This SP is used to get data to be downloaded based on moduleId
 ** Purpose:
 ** Date:   11/25/2025

 ** PARAMETERS: @POId varchar(60)

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    11/25/2025   Vishal Suthar		Created
	2    26/12/2025   Nakul Chandigra   changed the condition to get @SelectList and @JoinList , used IsUseJoinCondition insted of ParentTableRereneceTypeId 
	
 EXEC usp_GenerateCsvData 1, 1
**************************************************************/
CREATE   PROCEDURE [dbo].[usp_GenerateCsvData]
(
    @ModuleId INT,
    @MasterCompanyId INT
)
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @SelectList NVARCHAR(MAX) = '';
		DECLARE @JoinList NVARCHAR(MAX) = '';
		DECLARE @BaseTable NVARCHAR(200);

		SELECT TOP 1 @BaseTable = SourceTableName
		FROM DBO.ImportModuleFieldMaster WITH (NOLOCK)
		WHERE ModuleId = @ModuleId AND ParentTableRereneceTypeId = 0 AND IsActive = 1 AND IsDeleted = 0 AND  ISNULL(IsUseJoinCondition ,0)= 0 ;

		SELECT @SelectList = STRING_AGG(
			CASE 
				WHEN MultiValueQuery IS NOT NULL AND MultiValueQuery <> ''
				THEN '(' + MultiValueQuery + ') AS [' + HeaderName + ']'
				ELSE CONCAT(
					CASE 
						WHEN ISNULL(IsUseJoinCondition ,0) = 0
						THEN @BaseTable
						ELSE SourceTableName
					END,

					'.', SourceColumnName,
					' AS [', HeaderName, ']'
					)
			END
			, ', '
		) WITHIN GROUP (ORDER BY DisplaySortOrder)
		FROM DBO.ImportModuleFieldMaster WITH (NOLOCK)
		WHERE ModuleId = @ModuleId AND IsActive = 1 AND IsDeleted = 0;

		SELECT @JoinList = STRING_AGG(JoinCondition, CHAR(10))
		FROM (
			SELECT DISTINCT JoinCondition
			FROM DBO.ImportModuleFieldMaster WITH (NOLOCK)
			WHERE ModuleId = @ModuleId AND (ISNULL(IsUseJoinCondition ,0)= 1 )  AND ISNULL(JoinCondition,'') <> ''
		) AS J;
		DECLARE @SQL NVARCHAR(MAX) = '
			SELECT ' + @SelectList + '
			FROM ' + @BaseTable + ' WITH(NOLOCK)
			' + ISNULL(@JoinList, '') + '
			WHERE ' + @BaseTable + '.MasterCompanyId = @MasterCompanyId
			AND ' + @BaseTable + '.IsActive = 1
			AND ' + @BaseTable + '.IsDeleted = 0
			ORDER BY ' + @BaseTable + '.CreatedDate DESC;';
		EXEC sp_executesql @SQL, N'@MasterCompanyId INT', @MasterCompanyId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_GenerateCsvData'
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ModuleId, '') AS varchar(100))
							+ '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
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
END;