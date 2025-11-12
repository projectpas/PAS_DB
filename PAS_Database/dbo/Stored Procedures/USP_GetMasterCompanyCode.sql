/*************************************************************           
 ** File:   [USP_GetMasterCompanyCode]
 ** Author:   Amit Ghediya
 ** Description: Get mastercomapny code from master company
 ** Purpose:         
 ** Date:   11-Nov-2025
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
  ** S NO   Date            Author				Change Description              
 ** --   --------			-------				--------------------------------            
    1    11-Nov-2025		Amit Ghediya			Created

EXECUTE   [dbo].[USP_GetMasterCompanyCode] 1
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetMasterCompanyCode] 
	@mastercompanyid int
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
		SELECT [MasterCompanyCode] FROM [DBO].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @mastercompanyid;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_GetMasterCompanyCode]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
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