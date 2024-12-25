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
    @FieldValueId VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RefQuery AS NVARCHAR(MAX) = '';

	IF(ISNULL(@MasterCompanyId, 0) > 0)
    BEGIN
		SET @RefQuery 
		= 'SELECT @FieldValueId = ' + 'COALESCE(@FieldValueId + '','' , '''' ) + CAST(' + @DropdownListId +' AS VARCHAR)' + ' FROM (' +'SELECT '+ @DropdownListId + ' FROM [DBO].[' + @DropdownListTable + '] '+ 'WITH(NOLOCK) CROSS APPLY STRING_SPLIT(' + '''' + @FieldValue + ''''+', '','') ST WHERE '+ @DropdownListValue + ' LIKE ''%'' + ST.value + ''%'' ' + 'AND MasterCompanyId = ' + CAST(@MasterCompanyId AS VARCHAR) + ' ) AS DropDownResult';
    END
    ELSE
    BEGIN
		SET @RefQuery 
		= 'SELECT @FieldValueId = ' + 'COALESCE(@FieldValueId + '','' , '''' ) + CAST(' + @DropdownListId +' AS VARCHAR)' + ' FROM (' +'SELECT '+ @DropdownListId + ' FROM [DBO].[' + @DropdownListTable + '] '+ 'WITH(NOLOCK) CROSS APPLY STRING_SPLIT(' + '''' + @FieldValue + ''''+', '','') ST WHERE '+ @DropdownListValue + ' LIKE ''%'' + ST.value + ''%'' ' + ' ) AS DropDownResult';
    END

    EXEC sp_executesql @RefQuery, N'@FieldValueId VARCHAR(250) OUTPUT', @FieldValueId OUTPUT;

END;