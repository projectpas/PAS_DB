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
	3    28/01/2026   Divyesh Kathiriya		Added New Module "Employee"
	4	 02/02/2026   Nakul Chandigra   Added New condition to get @BaseTable AND ADDED ORDER BY FieldSortOrder TO Get @JoinList 

 EXEC usp_GenerateCsvData  97 , 1
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
		DECLARE @ModuleName VARCHAR(100);
		DECLARE @LocationModuleId BIGINT;
		DECLARE @ShelfModuleId BIGINT;
		DECLARE @BinModuleId BIGINT;
		DECLARE @SQL NVARCHAR(MAX);
		DECLARE @WhereCondition NVARCHAR(MAX);
		DECLARE @EmployeeModule AS BIGINT;

		SELECT @ModuleName = [ModuleName] FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ImportModuleId] = @ModuleId;
		SET @LocationModuleId = (SELECT [ImportModuleId] FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName]='Location')
		SET @ShelfModuleId = (SELECT [ImportModuleId] FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName]='Shelf')
		SET @BinModuleId = (SELECT [ImportModuleId] FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName]='Bin')
		SET @EmployeeModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Employee');

		IF OBJECT_ID('tempdb..#ColumnData') IS NOT NULL
			DROP TABLE #ColumnData

		CREATE TABLE #ColumnData
		(
			[IsUseJoinCondition] BIT,
		);		
		
		INSERT INTO #ColumnData (IsUseJoinCondition)
		SELECT ISNULL(IsUseJoinCondition ,0)
		FROM [dbo].[ImportModuleFieldMaster] WITH(NOLOCK)
		WHERE ModuleId = @ModuleId 
		
		IF EXISTS (SELECT 1	FROM #ColumnData WHERE IsUseJoinCondition = 0)
		BEGIN
			SELECT TOP 1 @BaseTable = SourceTableName
			FROM DBO.ImportModuleFieldMaster WITH (NOLOCK)
			WHERE ModuleId = @ModuleId AND ParentTableRereneceTypeId = 0 AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(IsUseJoinCondition,0) = 0 ;
		END
		ELSE
		BEGIN
			SET @BaseTable = @ModuleName
		END

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
		IF (@ModuleId = @LocationModuleId OR @ModuleId = @ShelfModuleId OR @ModuleId = @BinModuleId)
		BEGIN
			SELECT @JoinList = STRING_AGG(JoinCondition, CHAR(10))
			WITHIN GROUP (ORDER BY FieldSortOrder)
			FROM (
				SELECT DISTINCT JoinCondition,FieldSortOrder
				FROM DBO.ImportModuleFieldMaster WITH (NOLOCK)
				WHERE ModuleId = @ModuleId AND (ISNULL(IsUseJoinCondition ,0) = 1) AND ISNULL(JoinCondition,'') <> ''
			) AS J;
		END 
		ELSE
		BEGIN 
			SELECT @JoinList = STRING_AGG(JoinCondition, CHAR(10))
			FROM (
				SELECT DISTINCT JoinCondition
				FROM DBO.ImportModuleFieldMaster WITH (NOLOCK)
				WHERE ModuleId = @ModuleId AND (ISNULL(IsUseJoinCondition ,0) = 1) AND ISNULL(JoinCondition,'') <> ''
			) AS J;
		END 
		IF(@ModuleId = @EmployeeModule)
		BEGIN
			SET @WhereCondition  = 'AND AspNetUsers.MasterCompanyId = @MasterCompanyId
									AND Employee.FirstName <> ''TBD''
									AND Employee.EmployeeId Not in  (SELECT E.EmployeeId FROM dbo.Employee E WITH(NOLOCK) 
																			INNER JOIN dbo.EmployeeUserRole EUR WITH(NOLOCK) ON E.EmployeeId = EUR.EmployeeId 
																			INNER JOIN dbo.UserRole RU WITH(NOLOCK)  ON RU.Id = EUR.RoleId AND RU.Name = ''SUPERADMIN'')'									
		END

--------------Final SQL Query Start--------------
		IF(@ModuleId = @EmployeeModule)
		BEGIN
			SET @SQL = '
			SELECT ' + @SelectList + '
			FROM ' + @BaseTable + ' WITH(NOLOCK)
			' + ISNULL(@JoinList, '') + '
			WHERE ' + @BaseTable + '.MasterCompanyId = @MasterCompanyId
			AND ' + @BaseTable + '.IsActive = 1
			AND ' + @BaseTable + '.IsDeleted = 0
			' + @WhereCondition + '
			ORDER BY ' + @BaseTable + '.CreatedDate DESC;';
		END
		ELSE
		BEGIN
			SET @SQL  = '
				SELECT ' + @SelectList + '
				FROM ' + @BaseTable + '  WITH(NOLOCK)
				' + ISNULL(@JoinList, '') + '
				WHERE ' + @BaseTable + '.MasterCompanyId = @MasterCompanyId
				AND ' + @BaseTable + '.IsActive = 1
				AND ' + @BaseTable + '.IsDeleted = 0
				ORDER BY ' + @BaseTable + '.CreatedDate DESC;';

		END
--------------Final SQL Query END--------------

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