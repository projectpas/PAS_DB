
/*************************************************************               
 ** File:   [USP_UpdateStocklineDraftForTimeLifeById]              
 ** Author:   Devendra Shekh    
 ** Description: This stored procedure is used to Update stockline draft for timelife
 ** Purpose:             
 ** Date:   09/22/2023            
              
 ** PARAMETERS:    
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author				Change Description                
 ** --   --------     -------			--------------------------------              
    1    09/22/2023   Devendra Shekh		Created  


	EXEC [USP_UpdateStocklineDraftForTimeLifeById] '25708, 25709', 1
    
**************************************************************/    
CREATE   PROCEDURE [dbo].[USP_UpdateStocklineDraftForTimeLifeById]  
(    
 @ItemMasterId BIGINT NULL,
 @Active bit NULL
)    
AS    
BEGIN    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  SET NOCOUNT ON  
 BEGIN TRY    
    BEGIN TRANSACTION    
	BEGIN

	IF @ItemMasterId > 0
	BEGIN
		UPDATE [dbo].[StocklineDraft]
		SET isStkTimeLife = @Active
		WHERE ItemMasterId = @ItemMasterId AND StockLineId IS NULL AND StockLineNumber IS NULL
	END
		
	END
    COMMIT TRANSACTION    
    
  END TRY    
  BEGIN CATCH    
    IF @@trancount > 0    
   ROLLBACK TRAN; 
    SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
	
   DECLARE @ErrorLogID int    
   ,@DatabaseName varchar(100) = DB_NAME()    
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------    
   ,@AdhocComments varchar(150) = 'USP_UpdateStocklineDraftForTimeLifeById'    
   ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@ItemMasterId, '') + ''    
   ,@ApplicationName varchar(100) = 'PAS'    
   -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
   EXEC spLogException @DatabaseName = @DatabaseName,    
    @AdhocComments = @AdhocComments,    
    @ProcedureParameters = @ProcedureParameters,    
    @ApplicationName = @ApplicationName,    
    @ErrorLogID = @ErrorLogID OUTPUT;    
   RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
   RETURN (1);    
  END CATCH    
END