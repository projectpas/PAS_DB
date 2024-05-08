/*************************************************************************************
 ** File:   [USP_ManagementStructure_GetById]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used retrieve Entity Structure     
 ** Purpose:         
 ** Date:   17/06/2022
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1    17/06/2022   Moin Bloch    Created

-- EXEC USP_ManagementStructure_GetById 'ManagementSite','SiteId', 1, 1     
**************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_ManagementStructure_GetById]
	@TableName varchar(50) = NULL,
	@FieldName varchar(50) = NULL,
	@ReferenceId bigint = NULL,
	@MasterCompanyId int = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
    DECLARE @SQLQuery AS nvarchar(max)
    SET @SQLQuery = 'SELECT ManagementStructureId FROM ' + @TableName + ' WITH (NOLOCK) WHERE MasterCompanyId = ' + CAST(@MasterCompanyId AS varchar(20)) + ' AND ' + @FieldName + ' = ' + CAST(@ReferenceId AS varchar(20)) + '';
    EXECUTE sp_executesql @SQLQuery
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_ManagementStructure_GetById',
            @ProcedureParameters varchar(3000) = '@TableName = ''' + CAST(ISNULL(@TableName, '') AS varchar(100)) +
            ',@ReferenceId = ''' + CAST(ISNULL(@ReferenceId, '') AS varchar(100)),
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