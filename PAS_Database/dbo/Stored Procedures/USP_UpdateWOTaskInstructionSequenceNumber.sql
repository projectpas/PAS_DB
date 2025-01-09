/*************************************************************             
 ** File:   [USP_UpdateWOTaskInstructionSequenceNumber]             
 ** Author:  Vishal Suthar 
 ** Description: This stored procedure is used to update Sequence of WO Task Instruction
 ** Purpose:           
 ** Date:   01/08/2024
 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
	1    01/08/2024   Vishal Suthar		Created

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateWOTaskInstructionSequenceNumber]
(
	@WorkOrderTaskInstructionId BIGINT,
	@NewWorkOrderTaskInstructionId BIGINT,
	@SequenceNumber BIGINT,
	@NewSequenceNumber BIGINT,
	@UpdatedBy VARCHAR(50)
)
AS
BEGIN 
	BEGIN TRY
	BEGIN	
		UPDATE dbo.WorkOrderTaskInstruction SET 
		SequenceNumber = @NewSequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId
		
		UPDATE dbo.WorkOrderTaskInstruction SET 
		SequenceNumber = @SequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE WorkOrderTaskInstructionId = @NewWorkOrderTaskInstructionId
	END
	END TRY
	BEGIN CATCH
		SELECT        
	   ERROR_NUMBER() AS ErrorNumber,        
	   ERROR_STATE() AS ErrorState,        
	   ERROR_SEVERITY() AS ErrorSeverity,        
	   ERROR_PROCEDURE() AS ErrorProcedure,        
	   ERROR_LINE() AS ErrorLine,        
	   ERROR_MESSAGE() AS ErrorMessage;        
	   IF @@trancount > 0        
	   PRINT 'ROLLBACK'        
	   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()         
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
	   , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWOTaskInstructionSequenceNumber'         
	   , @ProcedureParameters VARCHAR(3000)  = '@WorkOrderTaskInstructionId = '''+ ISNULL(@WorkOrderTaskInstructionId, '') + ''        
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