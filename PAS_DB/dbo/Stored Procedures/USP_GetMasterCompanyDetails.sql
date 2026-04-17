/*************************************************************           
 ** File:   [USP_GetMasterCompanyDetails]
 ** Author:   Moin Bloch
 ** Description: Get mastercomapny ConnectionString from Xero Accounting
 ** Purpose:         
 ** Date:   11-Nov-2025
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
  ** S NO   Date            Author				Change Description              
 ** --   --------			-------				--------------------------------            
    1    16-04-2026		    Moin Bloch			Created

  EXEC [dbo].[USP_GetMasterCompanyDetails] 1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetMasterCompanyDetails] 
@MasterCompanyId int
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
		SELECT [MasterCompanyId]			  
			  ,[ConnectionString]			  
		  FROM [dbo].[MasterCompany] WITH(NOLOCK)
		 WHERE [MasterCompanyId] = @MasterCompanyId;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_GetMasterCompanyDetails]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS VARCHAR(100)),
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