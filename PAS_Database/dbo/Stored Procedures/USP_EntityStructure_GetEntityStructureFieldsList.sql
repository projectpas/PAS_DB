
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
    1    05/10/2024   AMIT GHEDIYA    Created
     
 EXECUTE USP_EntityStructure_GetEntityStructureFieldsList 1,2
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_EntityStructure_GetEntityStructureFieldsList]
	@MasterCompanyId int,
	@Opr int
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY

		DECLARE @ModuleId INT = (SELECT [GridModuleId] FROM [DBO].[GridModule] WITH (NOLOCK) WHERE [ModuleName] = 'SingleScreen');

		SELECT 
			FieldAlign,
			0 AS FieldAutoId,
			'' AS FieldFormate,
			HeaderName AS FieldName,
			FieldSortOrder AS FieldSortOrder,
			FieldType AS FieldType,
			FieldWidth AS FieldWidth,
			FieldName AS HeaderName,
			IsActive AS IsActive,
			1 AS IsMobileView,
			0 AS IsMultiValue,
			@ModuleId AS ModuleId
		FROM [dbo].[FieldMaster] WITH (NOLOCK)
		WHERE [MasterCompanyId] = @MasterCompanyId AND [ModuleId] = @ModuleId;

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