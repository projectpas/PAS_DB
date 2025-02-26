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

DECLARE @FieldValueId VARCHAR(50);

EXEC [dbo].[USP_GetDropdownValueId]
    @DropdownListTable = 'CustomerType',
    @DropdownListId = 'CustomerTypeId',
    @DropdownListValue = 'CustomerTypeName',
    @FieldValue = 'Customer,lead',
    @MasterCompanyId = 1,
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

    DECLARE @RefQuery AS NVARCHAR(MAX) = '';
	DECLARE @AlterModule AS BIGINT;
	SET @AlterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AlternateItemMaster');

	IF(@ModuleId = @AlterModule AND @IsChekColumnRef = 1 AND ISNULL(@ColumnReferenceName,'') != '')
		BEGIN
			SET @RefQuery 
			= 'SELECT @FieldValueId = ' + 'COALESCE(@FieldValueId + '','' , '''' ) + CAST(' + @DropdownListId +' AS VARCHAR)' + ' FROM (' +'SELECT '+ @DropdownListId + ' FROM [DBO].[' + @DropdownListTable + '] '+ 'WITH(NOLOCK) CROSS APPLY STRING_SPLIT(' + '''' + @FieldValue + ''''+', '','') ST WHERE '+ @DropdownListValue + ' = '''' + UPPER(TRIM(ST.value)) + '''' ' + 'AND MasterCompanyId = ' + CAST(@MasterCompanyId AS VARCHAR) + 'AND '+ @ColumnReferenceName +' = ' + CAST(@ColumnReferenceId AS VARCHAR) + ') AS DropDownResult';
		END
	ELSE
		BEGIN
			IF(ISNULL(@MasterCompanyId, 0) > 0)
			BEGIN
				SET @RefQuery 
				= 'SELECT @FieldValueId = ' + 'COALESCE(@FieldValueId + '','' , '''' ) + CAST(' + @DropdownListId +' AS VARCHAR)' + ' FROM (' +'SELECT '+ @DropdownListId + ' FROM [DBO].[' + @DropdownListTable + '] '+ 'WITH(NOLOCK) CROSS APPLY STRING_SPLIT(' + '''' + @FieldValue + ''''+', '','') ST WHERE '+ @DropdownListValue + ' = '''' + UPPER(TRIM(ST.value)) + '''' ' + 'AND MasterCompanyId = ' + CAST(@MasterCompanyId AS VARCHAR) + ' ) AS DropDownResult';
			END
			ELSE
			BEGIN
				SET @RefQuery 
				= 'SELECT @FieldValueId = ' + 'COALESCE(@FieldValueId + '','' , '''' ) + CAST(' + @DropdownListId +' AS VARCHAR)' + ' FROM (' +'SELECT '+ @DropdownListId + ' FROM [DBO].[' + @DropdownListTable + '] '+ 'WITH(NOLOCK) CROSS APPLY STRING_SPLIT(' + '''' + @FieldValue + ''''+', '','') ST WHERE '+ @DropdownListValue + ' = '''' + UPPER(TRIM(ST.value)) + '''' ' + ' ) AS DropDownResult';
			END
		END

    EXEC sp_executesql @RefQuery, N'@FieldValueId VARCHAR(250) OUTPUT', @FieldValueId OUTPUT;

END;