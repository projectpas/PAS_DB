/*************************************************************           
 ** File:   [USP_GETIntegrationEmailID]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to get IntegrationEmailID
 ** Purpose:         
 ** Date:   18/12/2025      
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    18/12/2025   AMIT GHEDIYA		Created


	EXEC [USP_GETIntegrationEmailID] 1,'<CA+jq2x7n0ASfJEWDXn3Utr4DO6t3XBO8rSwkn_5Hstq6N5KsLg@mail.gmail.com>'
**************************************************************/
CREATE       PROCEDURE [dbo].[USP_GETIntegrationEmailID]  
	@MasterCompanyId   INT,
	@MessaegId         VARCHAR(100) = NULL
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY  

			SELECT [IntegrationEmailID] FROM DBO.IntegrationEmail WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [MessageId] = @MessaegId;

	END TRY      
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GETIntegrationEmailID'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MessaegId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END