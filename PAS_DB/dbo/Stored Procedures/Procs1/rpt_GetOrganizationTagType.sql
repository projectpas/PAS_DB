/*************************************************************           
 ** File:   [rpt_GetOrganizationTagType]           
 ** Author:    
 ** Description: Get OrganizationTagType Data
 ** Purpose:         
 ** Date:        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  			Change Description            
 ** --   --------		-------				--------------------------------          
	1											Created
	2	28-Nov-2025		Devendra Shekh			Added Changes for blank option

EXEC [dbo].[rpt_GetOrganizationTagType] 11 
******************************/
CREATE   PROCEDURE [dbo].[rpt_GetOrganizationTagType] 
(
	@mastercompanyid INT = NULL
)
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
		SELECT 0 AS OrganizationTagTypeId, '' AS [Name]   -- blank option
		UNION ALL
		SELECT OrganizationTagTypeId, [Name] FROM DBO.OrganizationTagType OTT WITH (NOLOCK) 
		WHERE OTT.MasterCompanyId = @mastercompanyid;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME(),
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        @AdhocComments varchar(150) = '[rpt_GetOrganizationTagType]',
        @ProcedureParameters varchar(3000) = '@Parameter1 = ''',
        @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
        @AdhocComments = @AdhocComments,
        @ProcedureParameters = @ProcedureParameters,
        @ApplicationName = @ApplicationName,
        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END