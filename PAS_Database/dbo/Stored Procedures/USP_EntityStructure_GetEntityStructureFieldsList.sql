/*************************************************************           
 ** File:   [USP_EntityStructure_GetEntityStructureFieldsList]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used retrieve Entity Structure field name List    
 ** Purpose:         
 ** Date:   05/20/2022
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/20/2022   Moin Bloch    Created
     
 EXECUTE USP_EntityStructure_GetEntityStructureFieldsList 1,1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_EntityStructure_GetEntityStructureFieldsList]
	@MasterCompanyId int,
	@Opr int
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY

    DECLARE @MSLevelCount int
    SET @MSLevelCount = (SELECT [ManagementStructureLevel] FROM [dbo].[MasterCompany] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId);

    IF (@Opr = 1)
    BEGIN
      ;WITH CTE AS (SELECT
        1 AS FieldAlign,
        0 AS FieldAutoId,
        '' AS FieldFormate,
        'level' + CAST(ISNULL(ROW_NUMBER() OVER (ORDER BY (SELECT 1)), '') AS varchar(100)) + 'Desc' AS FieldName,
        ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS FieldSortOrder,
        'string' AS FieldType,
        '180px' AS FieldWidth,
        [Description] AS HeaderName,
        1 AS IsActive,
        1 AS IsMobileView,
        0 AS IsMultiValue,
        4 AS ModuleId
      FROM [dbo].[ManagementStructureType] WITH (NOLOCK)
      WHERE [MasterCompanyId] = @MasterCompanyId
      UNION
      SELECT
        1 AS FieldAlign,
        0 AS FieldAutoId,
        '' AS FieldFormate,
        'organizationTagTypeName' AS FieldName,
        @MSLevelCount + 1 AS FieldSortOrder,
        'string' AS FieldType,
        '175px' AS FieldWidth,
        'Tag Type' AS HeaderName,
        1 AS IsActive,
        1 AS IsMobileView,
        0 AS IsMultiValue,
        4 AS ModuleId
      UNION
      SELECT
        1 AS FieldAlign,
        0 AS FieldAutoId,
        'MM/DD/YYYY h:m a' AS FieldFormate,
        'createdDate' AS FieldName,
        @MSLevelCount + 2 AS FieldSortOrder,
        'date' AS FieldType,
        '140px' AS FieldWidth,
        'Created Date' AS HeaderName,
        1 AS IsActive,
        0 AS IsMobileView,
        0 AS IsMultiValue,
        4 AS ModuleId
      UNION
      SELECT
        1 AS FieldAlign,
        0 AS FieldAutoId,
        '' AS FieldFormate,
        'createdBy' AS FieldName,
        @MSLevelCount + 3 AS FieldSortOrder,
        'string' AS FieldType,
        '120px' AS FieldWidth,
        'Created By' AS HeaderName,
        1 AS IsActive,
        0 AS IsMobileView,
        0 AS IsMultiValue,
        4 AS ModuleId
      UNION
      SELECT
        1 AS FieldAlign,
        0 AS FieldAutoId,
        'MM/DD/YYYY h:m a' AS FieldFormate,
        'updatedDate' AS FieldName,
        @MSLevelCount + 4 AS FieldSortOrder,
        'date' AS FieldType,
        '140px' AS FieldWidth,
        'Updated Date' AS HeaderName,
        1 AS IsActive,
        0 AS IsMobileView,
        0 AS IsMultiValue,
        4 AS ModuleId
      UNION
      SELECT
        1 AS FieldAlign,
        0 AS FieldAutoId,
        '' AS FieldFormate,
        'updatedBy' AS FieldName,
        @MSLevelCount + 5 AS FieldSortOrder,
        'string' AS FieldType,
        '120px' AS FieldWidth,
        'Updated By' AS HeaderName,
        1 AS IsActive,
        0 AS IsMobileView,
        0 AS IsMultiValue,
        4 AS ModuleId)
      SELECT
        FieldAlign,
        FieldAutoId,
        FieldFormate,
        FieldName,
        FieldSortOrder,
        FieldType,
        FieldWidth,
        HeaderName,
        IsActive,
        IsMobileView,
        IsMultiValue,
        ModuleId
      FROM CTE ORDER BY FieldSortOrder;
    END
    ELSE
    BEGIN
      SELECT
        1 AS FieldAlign,
        0 AS FieldAutoId,
        '' AS FieldFormate,
        'isSelected' AS FieldName,
        0 AS FieldSortOrder,
        'bool' AS FieldType,
        '24px' AS FieldWidth,
        '' AS HeaderName,
        1 AS IsActive,
        1 AS IsMobileView,
        0 AS IsMultiValue,
        4 AS ModuleId
      UNION
      SELECT
        1 AS FieldAlign,
        0 AS FieldAutoId,
        '' AS FieldFormate,
        'level' + CAST(ISNULL(ROW_NUMBER() OVER (ORDER BY (SELECT 1)), '') AS varchar(100)) + 'Name' AS FieldName,
        ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS FieldSortOrder,
        'string' AS FieldType,
        '180px' AS FieldWidth,
        [Description] AS HeaderName,
        1 AS IsActive,
        1 AS IsMobileView,
        0 AS IsMultiValue,
        4 AS ModuleId
      FROM [dbo].[ManagementStructureType] WITH (NOLOCK)
      WHERE [MasterCompanyId] = @MasterCompanyId
      ORDER BY FieldSortOrder;
    END
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_EntityStructure_GetEntityStructureFieldsList',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END