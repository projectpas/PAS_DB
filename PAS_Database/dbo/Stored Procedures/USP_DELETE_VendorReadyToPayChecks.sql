/*************************************************************           
 ** File:   [USP_DELETE_VendorReadyToPayChecks]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used USP_DELETE_VendorReadyToPayChecks 
 ** Purpose:         
 ** Date:   11/03/2024    
          
 ** PARAMETERS:           
 @ReadyToPayDetailsId BIGINT,@ReadyToPayId  BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
	1    11/03/2024   AMIT GHEDIYA		Crated
     
-- EXEC USP_DELETE_VendorReadyToPayChecks 133,115 
**************************************************************/
CREATE      PROCEDURE [dbo].[USP_DELETE_VendorReadyToPayChecks]  
@ReadyToPayDetailsId BIGINT = NULL,  
@ReadyToPayId BIGINT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  

	DELETE DBO.VendorReadyToPayDetails WHERE ReadyToPayDetailsId = @ReadyToPayDetailsId AND ReadyToPayId = @ReadyToPayId;

  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_DELETE_VendorReadyToPayChecks'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReadyToPayDetailsId, '') + ''  
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