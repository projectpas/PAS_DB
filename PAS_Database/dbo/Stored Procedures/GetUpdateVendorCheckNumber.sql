/*************************************************************           
 ** File:   [GetUpdateVendorCheckNumber]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used TO GetUpdateVendorCheckNumber
 ** Purpose:         
 ** Date:   22/03/2024      
          
 ** PARAMETERS: @PrintingId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------		-------------------------------- 
	1    22/03/2024   AMIT GHEDIYA		Created
     
-- EXEC GetUpdateVendorCheckNumber 3,NULL,0
**************************************************************/
CREATE    PROCEDURE [dbo].[GetUpdateVendorCheckNumber]  
	@PrintingId BIGINT,
	@UpdatedNumber VARCHAR(100),
	@IsUpdate BIT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
	
	DECLARE @StartNumber INT;

	IF(@IsUpdate = 1)
	BEGIN
		SELECT @StartNumber = StartNum FROM [dbo].[PrintCheckSetup] WITH(NOLOCK) WHERE PrintingId = @PrintingId;
		IF(@StartNumber != (@UpdatedNumber -1))
		BEGIN
			UPDATE [dbo].[PrintCheckSetup] SET StartNum = @UpdatedNumber - 1
			WHERE PrintingId = @PrintingId;
		END
	END
	ELSE
	BEGIN
		SELECT 
		PCS.PrintingId,
		PCS.StartNum
		FROM [dbo].[PrintCheckSetup] PCS WITH(NOLOCK) WHERE PrintingId = @PrintingId;
	END
 END TRY  
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetUpdateVendorCheckNumber'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PrintingId, '') + ''  
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