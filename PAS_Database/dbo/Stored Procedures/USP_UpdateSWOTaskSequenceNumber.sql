/*************************************************************             
 ** File:   [USP_UpdateSWOTaskSequenceNumber]             
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to update Sequence of Sub WO Task
 ** Purpose:           
 ** Date:   04/01/2025
 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
	1    04/01/2025   Ekta Chandegra	Created


-- exec dbo.USP_UpdateSWOTaskSequenceNumber @SubWorkOrderTaskId=17,@SequenceNumber=3,@NewSubWorkOrderTaskId=14,
   @NewSequenceNumber=2,@UpdatedBy=N'EKTA CHANDEGRA'
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_UpdateSWOTaskSequenceNumber]
(
	@SubWorkOrderTaskId BIGINT,
	@NewSubWorkOrderTaskId BIGINT,
	@SequenceNumber BIGINT,
	@NewSequenceNumber BIGINT,
	@UpdatedBy VARCHAR(50)
)
AS
BEGIN 
	BEGIN TRY
	BEGIN	
		UPDATE dbo.SubWorkOrderTask SET 
		SequenceNumber = @NewSequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE SubWorkOrderTaskId = @SubWorkOrderTaskId
		
		UPDATE dbo.SubWorkOrderTask SET 
		SequenceNumber = @SequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE SubWorkOrderTaskId = @NewSubWorkOrderTaskId
	END
	END TRY
	BEGIN CATCH  
	   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()         
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
	   , @AdhocComments     VARCHAR(150)    = 'USP_UpdateSWOTaskSequenceNumber'         
	   , @ProcedureParameters VARCHAR(3000)  = '@SubWorkOrderTaskId = '''+ ISNULL(@SubWorkOrderTaskId, '') + ''        
	   , @ApplicationName VARCHAR(100) = 'PAS'        
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------        
		exec spLogException         
	   @DatabaseName           = @DatabaseName        
	   , @AdhocComments          = @AdhocComments        
	   , @ProcedureParameters = @ProcedureParameters        
	   , @ApplicationName        =  @ApplicationName        
	   , @ErrorLogID             = @ErrorLogID OUTPUT ;        
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)        
		RETURN(1);       
	END CATCH
END