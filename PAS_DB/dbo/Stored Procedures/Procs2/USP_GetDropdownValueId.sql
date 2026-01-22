/***************************************************************  
 ** File:   [USP_GetDropdownValueId]             
 ** Author:   Devendra Shekh
 ** Description: This SP is used to return dropdownId based on passed table and values
 ** Date:  11-Dec-2024
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    11-Dec-2024		Devendra Shekh			Created
	2    06-Jan-2025		Devendra Shekh			Checking Equal Values instead similar
	3    04-Feb-2025		SHREY CHANDEGARA		Modified due to ALternate part 
	4	 06-Aug-2025		Ayushi Patel			Updated WHERE clause in dynamic SQL to include MasterCompanyId = 0
	5	 31-Oct-2025		Priyansh Patel			Updated the conditions for the MRO price master
	6	 10-Nov-2025		Priyansh Patel			Added Delimiter logic for item master SiteId


DECLARE @FieldValueId VARCHAR(50);

EXEC [dbo].[USP_GetDropdownValueId]
    @DropdownListTable = 'CustomerAffiliation',
    @DropdownListId = 'CustomerAffiliationId',
    @DropdownListValue = 'Description',
    @FieldValue = 'external',
    @MasterCompanyId = 1,
	@ColumnReferenceName = '',
	@IsChekColumnRef = '',
    @FieldValueId = @FieldValueId OUTPUT;

SELECT @FieldValueId AS FieldValueId;
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetDropdownValueId]
(
    @DropdownListTable AS VARCHAR(100),
    @DropdownListId AS VARCHAR(100),
    @DropdownListValue AS VARCHAR(100),
    @FieldValue AS VARCHAR(250),
    @MasterCompanyId INT = NULL,
    @ModuleId BIGINT = NULL,
    @ColumnReferenceId BIGINT = NULL,
	@ColumnReferenceName VARCHAR(150) NULL,
	@IsChekColumnRef BIT NULL,
    @FieldValueId VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	BEGIN TRY    
	
	BEGIN TRANSACTION

    DECLARE @RefQuery AS NVARCHAR(MAX) = '';
	DECLARE @ActiveConditions NVARCHAR(MAX) = N'';

	DECLARE @AlterModule AS BIGINT;
	SET @AlterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AlternateItemMaster');


	DECLARE @MROPriceMasterModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'MROPriceMaster');
	DECLARE @MROPriceMasterListModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'MROPriceMasterList');
	DECLARE @ItemMasterModule AS BIGINT = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'itemMaster');

	DECLARE @Delimiter CHAR(1);

	SET @Delimiter = CASE 
                   WHEN @ModuleId = @ItemMasterModule  AND @DropdownListId = 'SiteId' THEN '|'
                   ELSE ','
                 END;

	IF(@ModuleId = @AlterModule AND @IsChekColumnRef = 1 AND ISNULL(@ColumnReferenceName,'') != '')
		BEGIN

			SET @RefQuery 
			= 'SELECT @FieldValueId = ' + 'COALESCE(@FieldValueId + '','' , '''' ) + CAST(' + @DropdownListId +' AS VARCHAR)' + ' FROM (' +'SELECT '+ @DropdownListId + ' FROM [DBO].[' + @DropdownListTable + '] '+ 'WITH(NOLOCK) CROSS APPLY STRING_SPLIT(' + '''' + @FieldValue + ''''+', '','') ST WHERE '+ @DropdownListValue + ' = '''' + UPPER(TRIM(ST.value)) + '''' ' + 'AND MasterCompanyId = ' + CAST(@MasterCompanyId AS VARCHAR) + 'AND '+ @ColumnReferenceName +' = ' + CAST(@ColumnReferenceId AS VARCHAR) + ') AS DropDownResult';
		END

	ELSE IF(@ModuleId = @MROPriceMasterModule OR @ModuleId = @MROPriceMasterListModule)
		BEGIN

		IF COL_LENGTH(N'[DBO].[' + @DropdownListTable + ']', 'isActive') IS NOT NULL
			SET @ActiveConditions += N' AND isActive = 1';

		IF COL_LENGTH(N'[DBO].[' + @DropdownListTable + ']', 'isDeleted') IS NOT NULL
			SET @ActiveConditions += N' AND isDeleted = 0';

				IF(@DropdownListId = 'CustomerId')
				BEGIN
					SET @RefQuery = 'SELECT @FieldValueId = ' + 'COALESCE(@FieldValueId + '','' , '''') + CAST(' + @DropdownListId + ' AS VARCHAR) ' + 'FROM [' + 'DBO].[' + @DropdownListTable + '] WITH(NOLOCK) ' + 'WHERE ' + @DropdownListValue + ' = ''' + UPPER(LTRIM(RTRIM(@FieldValue))) + ''' ' +'AND (MasterCompanyId = ' + CAST(@MasterCompanyId AS VARCHAR) + ' OR MasterCompanyId = 0) ' + @ActiveConditions;
				END
				ELSE
				BEGIN
					SET @RefQuery 
					= 'SELECT @FieldValueId = ' + 'COALESCE(@FieldValueId + '','' , '''' ) + CAST(' + @DropdownListId +' AS VARCHAR)' + ' FROM (' +'SELECT '+ @DropdownListId + ' FROM [DBO].[' + @DropdownListTable + '] '+ 'WITH(NOLOCK) CROSS APPLY STRING_SPLIT(' + '''' + @FieldValue + ''''+', '','') ST WHERE '+ @DropdownListValue + ' = '''' + UPPER(TRIM(ST.value)) + '''' ' + 'AND (MasterCompanyId = ' + CAST(@MasterCompanyId AS VARCHAR) + ' OR MasterCompanyId = 0)' + @ActiveConditions + ' ) AS DropDownResult';
				END
				
		END
	ELSE
		BEGIN
			IF(ISNULL(@MasterCompanyId, 0) > 0)
			BEGIN
				SET @RefQuery 
				= 'SELECT @FieldValueId = ' + 'COALESCE(@FieldValueId + '','' , '''' ) + CAST(' + @DropdownListId +' AS VARCHAR)' + ' FROM (' +'SELECT '+ @DropdownListId + ' FROM [DBO].[' + @DropdownListTable + '] '+ 'WITH(NOLOCK) CROSS APPLY STRING_SPLIT(' + '''' + @FieldValue + ''''+', ''' + @Delimiter + ''') ST WHERE '+ @DropdownListValue + ' = '''' + UPPER(TRIM(ST.value)) + '''' ' + 'AND (MasterCompanyId = ' + CAST(@MasterCompanyId AS VARCHAR) + ' OR MasterCompanyId = 0)' + ' ) AS DropDownResult';

			END
			ELSE
			BEGIN
				SET @RefQuery 
				= 'SELECT @FieldValueId = ' + 'COALESCE(@FieldValueId + '','' , '''' ) + CAST(' + @DropdownListId +' AS VARCHAR)' + ' FROM (' +'SELECT '+ @DropdownListId + ' FROM [DBO].[' + @DropdownListTable + '] '+ 'WITH(NOLOCK) CROSS APPLY STRING_SPLIT(' + '''' + @FieldValue + ''''+', ''' + @Delimiter + ''') ST WHERE '+ @DropdownListValue + ' = '''' + UPPER(TRIM(ST.value)) + '''' ' + ' ) AS DropDownResult';
			END
		END

    EXEC sp_executesql @RefQuery, N'@FieldValueId VARCHAR(250) OUTPUT', @FieldValueId OUTPUT;
	COMMIT TRANSACTION
	 
	END TRY    
	BEGIN CATCH  
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE @ErrorLogID int,    
			@DatabaseName varchar(100) = DB_NAME()    
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
			,@AdhocComments varchar(150) = 'USP_GetDropdownValueId',    
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