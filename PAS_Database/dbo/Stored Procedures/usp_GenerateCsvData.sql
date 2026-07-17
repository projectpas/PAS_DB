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
 ** PR   Date         Author				Change Description
 ** --   ----------   -------				--------------------------------
    1    11/25/2025   Vishal Suthar			Created
	2    26/12/2025   Nakul Chandigra		changed the condition to get @SelectList and @JoinList , used IsUseJoinCondition insted of ParentTableRereneceTypeId 
	3    28/01/2026   Divyesh Kathiriya		Added New Module "Employee"
	4	 02/02/2026   Nakul Chandigra		Added New condition to get @BaseTable AND ADDED ORDER BY FieldSortOrder TO Get @JoinList
	5    04/02/2026   Divyesh Kathiriya		Added New Module "Stockline"
	6	 02/04/2026   Nakul Chandigra       Add condtion for Orderby in final sql for squenceno (PN-15884)
	7	 07/04/2026   Nakul Chandigra       Add condtion for Orderby in final sql (PN-15944)
	8    29/04/2026   Divyesh Kathiriya		Added New Module "ManualJournal" [PN-16139]
	9    11/05/2026   Nakul Chandigra       Added a new function to apply upper or lower case formatting based on the employee and legal entity.(PN-16181)
	10   17/07/2026   Ayushi Patel          [PN-17323]Added a condition to return qty and amount related fields with 2 decimal for all Module
 EXEC usp_GenerateCsvData 20, 1, 2
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GenerateCsvData]
(
    @ModuleId INT,
    @MasterCompanyId INT,
	@EmployeeId BIGINT 
)
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @SelectList NVARCHAR(MAX) = '';
		DECLARE @JoinList NVARCHAR(MAX) = '';
		DECLARE @BaseTable NVARCHAR(200);
		DECLARE @TableName NVARCHAR(200) = 'ManualJournalDetails';
		DECLARE @ModuleName VARCHAR(100);
		DECLARE @LocationModuleId BIGINT;
		DECLARE @ShelfModuleId BIGINT;
		DECLARE @BinModuleId BIGINT;
		DECLARE @SQL NVARCHAR(MAX);
		DECLARE @WhereCondition NVARCHAR(MAX);
		DECLARE @MSModuelId INT; 
		DECLARE @OrderByColumn NVARCHAR(50);
		DECLARE @TextTransformId BIGINT;
		DECLARE @TextTransform VARCHAR(50);
		DECLARE @LegalEntityId BIGINT;
		DECLARE @TransformedSelectList NVARCHAR(MAX);

		DECLARE @EmployeeModule AS INT;
		DECLARE @StocklineModule AS INT;
		DECLARE @ManualJournalModule AS INT;

		SELECT @ModuleName = [ModuleName] FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ImportModuleId] = @ModuleId;

		SET @StocklineModule = (SELECT [ImportModuleId] FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline');
		SET @EmployeeModule = (SELECT [ImportModuleId] FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'Employee');
		SET @LocationModuleId = (SELECT [ImportModuleId] FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName]='Location');
		SET @ShelfModuleId = (SELECT [ImportModuleId] FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName]='Shelf');
		SET @BinModuleId = (SELECT [ImportModuleId] FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName]='Bin');
		SET @ManualJournalModule = (SELECT [ImportModuleId] FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'ManualJournal');

		SET @MSModuelId = (SELECT [ManagementStructureModuleId] FROM [DBO].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline');
		SET @LegalEntityId = (SELECT [LegalEntityId] FROM [DBO].[Employee] WITH(NOLOCK) WHERE EmployeeId = @EmployeeId AND MasterCompanyId = @MasterCompanyId) 

		IF EXISTS (SELECT 1 FROM [DBO].[Employee] WITH(NOLOCK) WHERE EmployeeId = @EmployeeId AND MasterCompanyId = @MasterCompanyId AND TextTransformId IS NOT NULL)
		BEGIN
			SET @TextTransformId = (SELECT TextTransformId FROM [DBO].[Employee] WITH(NOLOCK) WHERE EmployeeId = @EmployeeId AND MasterCompanyId = @MasterCompanyId)
			SET @TextTransform = (SELECT DisplayName FROM [DBO].[TextTransform] WITH(NOLOCK) WHERE @TextTransformId = TextTransformId)
		END 
		ELSE 
		BEGIN 
			SET @TextTransformId = (SELECT TextTransformId FROM [DBO].[LegalEntity]  WITH(NOLOCK) WHERE LegalEntityId = @LegalEntityId AND MasterCompanyId = @MasterCompanyId)
			SET @TextTransform = (SELECT DisplayName FROM [DBO].[TextTransform] WITH(NOLOCK) WHERE TextTransformId = @TextTransformId)
		END 
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
		
		--------------Set @BaseTable Start--------------
		IF (@ModuleId = @ManualJournalModule)
		BEGIN
			SET @BaseTable = @TableName;
		END
		ELSE
		BEGIN
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
		END
		--------------Set @BaseTable END--------------
		IF OBJECT_ID('tempdb..#FieldList') IS NOT NULL
			DROP TABLE #FieldList;

		SELECT 
			fm.HeaderName,
			fm.DisplaySortOrder,
			fm.MultiValueQuery,
			fm.SourceColumnName,
			ResolvedTable = CASE WHEN ISNULL(fm.IsUseJoinCondition,0) = 0 THEN @BaseTable ELSE fm.SourceTableName END,
			IsNumeric = CASE WHEN c.DATA_TYPE IN ('decimal','numeric','money','smallmoney','float','real') THEN 1 ELSE 0 END
		INTO #FieldList
		FROM DBO.ImportModuleFieldMaster fm WITH (NOLOCK)
		LEFT JOIN INFORMATION_SCHEMA.COLUMNS c
			ON c.TABLE_SCHEMA = 'dbo'
			AND c.TABLE_NAME = CASE WHEN ISNULL(fm.IsUseJoinCondition,0) = 0 THEN @BaseTable ELSE fm.SourceTableName END
			AND c.COLUMN_NAME = fm.SourceColumnName
		WHERE fm.ModuleId = @ModuleId AND fm.IsActive = 1 AND fm.IsDeleted = 0;

		SELECT @SelectList = STRING_AGG(
			CASE 
				WHEN MultiValueQuery IS NOT NULL AND MultiValueQuery <> ''
				THEN '(' + MultiValueQuery + ') AS [' + HeaderName + ']'
				WHEN IsNumeric = 1
				THEN CONCAT(
						'CONVERT(VARCHAR(30), CAST(ISNULL(',
						ResolvedTable, '.', SourceColumnName, ', 0) AS DECIMAL(18,2)))',
						' AS [', HeaderName, ']'
					 )
				ELSE CONCAT(ResolvedTable, '.', SourceColumnName, ' AS [', HeaderName, ']')
			END
			, ', '
		) WITHIN GROUP (ORDER BY DisplaySortOrder)
		FROM #FieldList;
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
		
		IF(@ModuleId = @StocklineModule)
		BEGIN

			SET @JoinList  +=  ' INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = Stockline.StockLineId     
								 INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON Stockline.ManagementStructureId = RMS.EntityStructureId
								 INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								 LEFT JOIN DBO.UnitOfMeasure uom WITH (NOLOCK) ON Stockline.StockUnitOfMeasureId = uom.UnitOfMeasureId'

			SET @WhereCondition  = 'AND ISNULL(Stockline.QuantityOnHand, 0) > 0 
									AND ISNULL(Stockline.IsParent, 0) = 1 
									AND ISNULL(Stockline.IsCustomerStock,0) = 0'									
		END
		IF(@ModuleId = @EmployeeModule)
		BEGIN
			SET @WhereCondition  = 'AND AspNetUsers.MasterCompanyId = @MasterCompanyId
									AND Employee.FirstName <> ''TBD''
									AND Employee.EmployeeId Not in  (SELECT E.EmployeeId FROM dbo.Employee E WITH(NOLOCK) 
																			INNER JOIN dbo.EmployeeUserRole EUR WITH(NOLOCK) ON E.EmployeeId = EUR.EmployeeId 
																			INNER JOIN dbo.UserRole RU WITH(NOLOCK)  ON RU.Id = EUR.RoleId AND RU.Name = ''SUPERADMIN'')'									
		END		
		
		IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @BaseTable AND COLUMN_NAME ='SequenceNo')
		BEGIN 
			SET @OrderByColumn = '.SequenceNo ASC;'
		END 
		ELSE 
		BEGIN 
			SET @OrderByColumn = '.CreatedDate DESC;'
		END 

		SET @TransformedSelectList = dbo.fn_TransformSelectList(@SelectList, @TextTransform);

--------------Final SQL Query Start--------------
		IF(@ModuleId = @StocklineModule)
		BEGIN
			SET @SQL = '
			SELECT ' + @TransformedSelectList + '
			FROM ' + @BaseTable + ' WITH(NOLOCK)
			' + ISNULL(@JoinList, '') + '
			WHERE ' + @BaseTable + '.MasterCompanyId = @MasterCompanyId			
			AND ' + @BaseTable + '.IsDeleted = 0
			' + @WhereCondition + '
			ORDER BY ' + @BaseTable + '.CreatedDate DESC;';
		END
		ELSE IF(@ModuleId = @EmployeeModule)
		BEGIN
			SET @SQL = '
			SELECT ' + @TransformedSelectList + '
			FROM ' + @BaseTable + ' WITH(NOLOCK)
			' + ISNULL(@JoinList, '') + '
			WHERE ' + @BaseTable + '.MasterCompanyId = @MasterCompanyId
			AND ' + @BaseTable + '.IsActive = 1
			AND ' + @BaseTable + '.IsDeleted = 0
			' + @WhereCondition + '
			ORDER BY ' + @BaseTable + '.CreatedDate DESC;';
		END
		ELSE IF(@ModuleId = @ManualJournalModule)
		BEGIN
			IF OBJECT_ID('tempdb..#EntityList') IS NOT NULL
			BEGIN
				DROP TABLE #EntityList
			END
			
			CREATE TABLE #EntityList (
				EntityStructureId INT,
				MasterCompanyId INT,
				Level1Id INT,
				Level1Name NVARCHAR(255),
				Level2Id INT,
				Level2Name NVARCHAR(255),
				Level3Id INT,
				Level3Name NVARCHAR(255),
				Level4Id INT,
				Level4Name NVARCHAR(255),
				Level5Id INT,
				Level5Name NVARCHAR(255),
				Level6Id INT,
				Level6Name NVARCHAR(255),
				Level7Id INT,
				Level7Name NVARCHAR(255),
				Level8Id INT,
				Level8Name NVARCHAR(255),
				Level9Id INT,
				Level9Name NVARCHAR(255),
				Level10Id INT,
				Level10Name NVARCHAR(255),
				AllMSlevels NVARCHAR(MAX),
				LastMSlevel NVARCHAR(255),
				LegalEntityId BIGINT
			)
			
			INSERT INTO #EntityList
			EXEC dbo.USP_GetAllEntityManagementStructureList 
				@MasterCompanyId = @MasterCompanyId, @EmployeeId = @EmployeeId;

			UPDATE #EntityList
			SET Level1Name = LTRIM(RTRIM(LEFT(Level1Name, CHARINDEX('-', Level1Name) - 1))),
				Level2Name = LTRIM(RTRIM(LEFT(Level2Name, CHARINDEX('-', Level2Name) - 1))),
				Level3Name = LTRIM(RTRIM(LEFT(Level3Name, CHARINDEX('-', Level3Name) - 1))),
				Level4Name = LTRIM(RTRIM(LEFT(Level4Name, CHARINDEX('-', Level4Name) - 1))),
				Level5Name = LTRIM(RTRIM(LEFT(Level5Name, CHARINDEX('-', Level5Name) - 1))),
				Level6Name = LTRIM(RTRIM(LEFT(Level6Name, CHARINDEX('-', Level6Name) - 1))),
				Level7Name = LTRIM(RTRIM(LEFT(Level7Name, CHARINDEX('-', Level7Name) - 1))),
				Level8Name = LTRIM(RTRIM(LEFT(Level8Name, CHARINDEX('-', Level8Name) - 1))),
				Level9Name = LTRIM(RTRIM(LEFT(Level9Name, CHARINDEX('-', Level9Name) - 1))),
				Level10Name = LTRIM(RTRIM(LEFT(Level10Name, CHARINDEX('-', Level10Name) - 1)))  
			FROM #EntityList;


			SET @SQL  = '
				SELECT ' + @TransformedSelectList + '
				FROM ' + @BaseTable + '  WITH(NOLOCK)
				' + ISNULL(@JoinList, '') + '
				WHERE ' + @BaseTable + '.MasterCompanyId = @MasterCompanyId
				AND ' + @BaseTable + '.IsActive = 1
				AND ' + @BaseTable + '.IsDeleted = 0
				ORDER BY '+  @BaseTable +@OrderByColumn;		
		END
		ELSE
		BEGIN
			SET @SQL  = '
				SELECT ' + @TransformedSelectList + '
				FROM ' + @BaseTable + '  WITH(NOLOCK)
				' + ISNULL(@JoinList, '') + '
				WHERE ' + @BaseTable + '.MasterCompanyId = @MasterCompanyId
				AND ' + @BaseTable + '.IsActive = 1
				AND ' + @BaseTable + '.IsDeleted = 0
				ORDER BY '+  @BaseTable +@OrderByColumn;
		
		END
--------------Final SQL Query END--------------
		IF(@ModuleId = @StocklineModule)
		BEGIN		 
			EXEC sp_executesql @SQL, N'@MasterCompanyId INT, @MSModuelId INT, @EmployeeId BIGINT', @MasterCompanyId, @MSModuelId , @EmployeeId;
		END
		ELSE
		BEGIN
			EXEC sp_executesql @SQL, N'@MasterCompanyId INT', @MasterCompanyId;
		END
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