CREATE   PROCEDURE [dbo].[rpt_GetOrganizationTagType] 
(
	@mastercompanyid INT = NULL
)
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
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