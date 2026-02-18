/*************************************************************           
 ** File:   [UpdatevendorReadyToPayHeader]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used TO update vendorReadyToPayHeader check number
 ** Purpose:         
 ** Date:   21/03/2024      
          
 ** PARAMETERS: @ReadyToPayId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------		-------------------------------- 
	1    21/03/2024   AMIT GHEDIYA		Created
	2    20/12/2024   AMIT GHEDIYA		Update for set @StartNums to start with 0.
	3    16/02/2026   AMIT GHEDIYA		Update for check number duplicate issue (PN-15479)
     
-- EXEC UpdatevendorReadyToPayHeader 120,115
**************************************************************/
CREATE      PROCEDURE [dbo].[UpdatevendorReadyToPayHeader]  
	@ReadyToPayId BIGINT,
	@PrintCheck_Wire_Num VARCHAR(100),
	@PrintingId BIGINT,
	@StartNum BIGINT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  

	--Update PrintCheckSetup
	UPDATE [dbo].[PrintCheckSetup] SET StartNum = @StartNum
	WHERE PrintingId = @PrintingId;
  
 END TRY  
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'UpdatevendorReadyToPayHeader'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReadyToPayId, '') + ''  
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
            exec spLogException   
                    @DatabaseName           = @DatabaseName  
                    , @AdhocComments          = @AdhocComments  
                    , @ProcedureParameters = @ProcedureParameters  
                    , @ApplicationName        =  @ApplicationName  
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
            RETURN(1);  
 END CATCH  
END