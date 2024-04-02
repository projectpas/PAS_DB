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
     
-- EXEC UpdatevendorReadyToPayHeader 120,115
**************************************************************/
CREATE    PROCEDURE [dbo].[UpdatevendorReadyToPayHeader]  
	@ReadyToPayId BIGINT,
	@PrintCheck_Wire_Num VARCHAR(100),
	@PrintingId BIGINT,
	@StartNum BIGINT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
	
	DECLARE @PrintingIds BIGINT,
			@StartNums BIGINT,
			@UpdateNums BIGINT;

	IF(@PrintingId > 0)
	BEGIN
		 SELECT @StartNums = StartNum FROM [DBO].[PrintCheckSetup] WITH(NOLOCK) WHERE PrintingId = @PrintingId;
	END

	--Update PrintCheckSetup
	UPDATE [dbo].[PrintCheckSetup] SET StartNum = @StartNums + 1 
	WHERE PrintingId = @PrintingId;

	--update checknumber in VendorReadyToPayHeader table
	UPDATE [dbo].[VendorReadyToPayHeader] SET PrintCheck_Wire_Num = @StartNums 
	WHERE ReadyToPayId = @ReadyToPayId;
  
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