/***************************************************************  
 ** File:   [USP_ChekDuplicateValueForUpload]             
 ** Author:   Devendra Shekh
 ** Description: This SP is used to return dropdownId based on passed table and values
 ** Date:  11-Dec-2024
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    03-Feb-2025		Devendra Shekh			Created
	2	 24-Feb-2025		Abhishek Jirawla		Modified this SP to check when 1 reference is checked

DECLARE @IsDuplicate BIT;

EXEC [dbo].[USP_ChekDuplicateValueForUpload]
    @ChekDuplticateRef1 = 'ItemMasterId',
    @ChekDuplticateRef2 = 'MappingItemMasterId',
    @DuplicateRefeValue1 = '14',
    @DuplicateRefeValue2 = '102605',
    @ReferenceTable = 'Nha_Tla_Alt_Equ_ItemMapping',
    @MasterCompanyId = 1,
    @ModuleId = 3,
    @IsDuplicate = @IsDuplicate OUTPUT;

SELECT @IsDuplicate AS IsDuplicateResult;

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_ChekDuplicateValueForUpload] 
(
    @ChekDuplticateRef1    AS VARCHAR(150) = NULL,
    @ChekDuplticateRef2    AS VARCHAR(150) = NULL,
    @DuplicateRefeValue1   AS VARCHAR(150) = NULL,
    @DuplicateRefeValue2   AS VARCHAR(150) = NULL,
    @ReferenceTable        AS VARCHAR(150) = NULL,
    @MasterCompanyId       AS INT = NULL,
    @ModuleId              AS BIGINT = NULL,
	@UploadData            AS [UploadModuleDataTableType] READONLY,
	@UploadRecord          AS VARCHAR(MAX) = NULL,
    @IsDuplicate           BIT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;    

	BEGIN TRY    
    SET NOCOUNT ON;

    DECLARE @RefQuery AS NVARCHAR(MAX) = '';
    DECLARE @Params AS NVARCHAR(MAX);
    DECLARE @AlterModule AS BIGINT;
    
	SET @AlterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AlternateItemMaster');
    
	SET @IsDuplicate = 0;

	IF OBJECT_ID('tempdb..#uploadDataResults2') IS NOT NULL
		DROP TABLE #uploadDataResults2

	IF OBJECT_ID('tempdb..#FilteredRecords') IS NOT NULL
		DROP TABLE #FilteredRecords

	CREATE TABLE #uploadDataResults2
	(
		[RecordId] BIGINT IDENTITY(1,1) NOT NULL,
		[ModuleId] BIGINT NULL, 
		[UserName] VARCHAR(100) NULL, 
		[MasterCompanyId] INT NULL,  
		[UploadRecord] VARCHAR(MAX) NULL,
		[OriginalRecordData] VARCHAR(MAX) NULL,
		[IsError] BIT NULL,
		[Status] VARCHAR(MAX) NULL
	);

	-- Temporary table for cleaned JSON values
	CREATE TABLE #FilteredRecords (
		RecordId BIGINT,
		CleanedJSON NVARCHAR(MAX)
	);
		
	INSERT INTO #uploadDataResults2([ModuleId], [UserName], [MasterCompanyId], [UploadRecord], [OriginalRecordData])
	SELECT [ModuleId], [UserName], [MasterCompanyId], [UploadRecord], [UploadRecord] FROM @UploadData;


	IF((ISNULL(@ChekDuplticateRef1, '') != '' AND ISNULL(@ChekDuplticateRef2, '') != ''))  
	BEGIN
		SET @RefQuery = N'
			IF EXISTS (
				SELECT 1 FROM ' + QUOTENAME(@ReferenceTable) + N' WITH(NOLOCK)
				WHERE MasterCompanyId = @MasterCompanyId 
				AND ' + QUOTENAME(@ChekDuplticateRef1) + N' = @DuplicateRefeValue1 
				AND ' + QUOTENAME(@ChekDuplticateRef2) + N' = @DuplicateRefeValue2
			)
			BEGIN
				SET @IsDuplicate = 1;
			END';
    
		SET @Params = N'@MasterCompanyId INT, @DuplicateRefeValue1 VARCHAR(150), @DuplicateRefeValue2 VARCHAR(150), @IsDuplicate BIT OUTPUT';
    
		EXEC sp_executesql @RefQuery, @Params, 
			@MasterCompanyId = @MasterCompanyId, 
			@DuplicateRefeValue1 = @DuplicateRefeValue1, 
			@DuplicateRefeValue2 = @DuplicateRefeValue2, 
			@IsDuplicate = @IsDuplicate OUTPUT;

		IF @ModuleId = @AlterModule
		BEGIN
			IF @IsDuplicate != 1
			BEGIN
				 -- Remove "line" key from JSON data in #uploadDataResults
				INSERT INTO #FilteredRecords (RecordId, CleanedJSON)
				SELECT 
					r.RecordId,
					(
						SELECT [key], value 
						FROM OPENJSON(r.UploadRecord)
						WHERE [key] <> 'line' AND [key] <> 'isError' AND [key] <> 'recordStatus' AND [key] <> 'isEditable'
						FOR JSON PATH
					)
				FROM #uploadDataResults2 r;

				-- Remove "line" key from @UploadRecord for comparison
				DECLARE @FilteredUploadRecord NVARCHAR(MAX);
				SET @FilteredUploadRecord = (
					SELECT [key], value 
					FROM OPENJSON(@UploadRecord)
					WHERE [key] <> 'line' AND [key] <> 'isError' AND [key] <> 'recordStatus' AND [key] <> 'isEditable'
					FOR JSON PATH
				);

				-- Check for duplicates
				IF EXISTS (
					SELECT 1 
					FROM #FilteredRecords
					WHERE LOWER(CleanedJSON) = LOWER(@FilteredUploadRecord)
					GROUP BY CleanedJSON
					HAVING COUNT(*) > 1
				)
				BEGIN
					SET @IsDuplicate = 1;
				END
			END
		END
	END
	ELSE IF((ISNULL(@ChekDuplticateRef1, '') != '' AND ISNULL(@ChekDuplticateRef2, '') = ''))
	BEGIN
		SET @RefQuery = N'
			IF EXISTS (
				SELECT 1 FROM ' + QUOTENAME(@ReferenceTable) + N' WITH(NOLOCK)
				WHERE MasterCompanyId = @MasterCompanyId 
				AND ' + QUOTENAME(@ChekDuplticateRef1) + N' = @DuplicateRefeValue1 
			)
			BEGIN
				SET @IsDuplicate = 1;
			END';
    
		SET @Params = N'@MasterCompanyId INT, @DuplicateRefeValue1 VARCHAR(150),@IsDuplicate BIT OUTPUT';
    
		EXEC sp_executesql @RefQuery, @Params, 
			@MasterCompanyId = @MasterCompanyId, 
			@DuplicateRefeValue1 = @DuplicateRefeValue1,
			@IsDuplicate = @IsDuplicate OUTPUT;

		IF @IsDuplicate != 1
		BEGIN
			DECLARE @JsonKey NVARCHAR(150);
			DECLARE @JsonPath NVARCHAR(200);
			DECLARE @SQL NVARCHAR(MAX);
			DECLARE @Params2 AS NVARCHAR(MAX);
			--DECLARE @CurrentValue NVARCHAR(150);

			SET @JsonKey = @ChekDuplticateRef1;
			
			-- Construct JSON path dynamically
			SET @JsonPath = N'$.' + @JsonKey;  -- Generates '$.accountCode' dynamically

			-- Check for duplicate values in #uploadDataResults
			IF EXISTS (
				SELECT JSON_VALUE(UploadRecord, @JsonPath)
				FROM #uploadDataResults2
				WHERE JSON_VALUE(UploadRecord, @JsonPath) = @DuplicateRefeValue1
				GROUP BY JSON_VALUE(UploadRecord, @JsonPath)
				HAVING COUNT(*) > 1
			)
			BEGIN
				SET @IsDuplicate = 1;
			END
		END
		
	END
	END TRY    
	BEGIN CATCH    
		IF @@trancount > 0
			PRINT 'ROLLBACK'

			DECLARE @ErrorLogID int,    
			@DatabaseName varchar(100) = DB_NAME()    
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
			,@AdhocComments varchar(150) = 'USP_ChekDuplicateValueForUpload',    
			@ProcedureParameters varchar(3000) = '@ModuleId = ''' + CAST(ISNULL(@ModuleId, '') AS varchar(100))    
			+ '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),    
			@ApplicationName varchar(100) = 'PAS'    
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
			EXEC spLogException @DatabaseName = @DatabaseName,    
				@AdhocComments = @AdhocComments,    
				@ProcedureParameters = @ProcedureParameters,    
				@ApplicationName = @ApplicationName,    
				@ErrorLogID = @ErrorLogID OUTPUT;    
			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
	END CATCH
END;