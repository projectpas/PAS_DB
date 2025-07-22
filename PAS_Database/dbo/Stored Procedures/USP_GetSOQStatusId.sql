/************************************************************************************           
 ** File:   [USP_GetSOQStatusId]           
 ** Author: 
 ** Description: This stored procedure is used to Get StatusId.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR    Date				 	Author				       Change Description            
 ** --    --------			 -----------				--------------------------------          
	 1    17-July-2025		Bhargav Saliya			        Created

****************************************************************************************/

Create      PROCEDURE [dbo].[USP_GetSOQStatusId]
	@SalesOrderQuoteId BIGINT,
	@MasterCompanyId BIGINT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY

	SELECT StatusId FROM [dbo].[SalesOrderQuote] WITH(NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0
	
  END TRY  
  BEGIN CATCH  
  
   DECLARE @ErrorLogID int,  
           @DatabaseName varchar(100) = DB_NAME(),  
           -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
           @AdhocComments varchar(150) = 'USP_GetSOQStatusId',  
           @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderQuoteId, '') AS varchar(100)) +    
           '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),  
           @ApplicationName varchar(100) = 'PAS'   
   -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
   EXEC Splogexception @DatabaseName = @DatabaseName,  
                       @AdhocComments = @AdhocComments,  
                       @ProcedureParameters = @ProcedureParameters,  
                       @ApplicationName = @ApplicationName,  
                       @ErrorLogID = @ErrorLogID OUTPUT;  
  
   RAISERROR (  
   'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
   , 16, 1, @ErrorLogID)  
  
   RETURN (1);  
  END CATCH
END