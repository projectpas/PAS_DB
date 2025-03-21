/*************************************************************             
 ** File:   [USP_UpdateSWOTaskInstructionSequenceNumber]             
 ** Author:  Vishal Suthar 
 ** Description: This stored procedure is used to update Sequence of WO Task Instruction
 ** Purpose:           
 ** Date:   03/21/2025
 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
	1    03/21/2025   Vishal Suthar		Created

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateSWOTaskInstructionSequenceNumber]
(
	@SubWorkOrderTaskInstructionId BIGINT,
	@NewSubWorkOrderTaskInstructionId BIGINT,
	@SequenceNumber BIGINT,
	@NewSequenceNumber BIGINT,
	@UpdatedBy VARCHAR(50)
)
AS
BEGIN 
	BEGIN TRY
	BEGIN	
		UPDATE dbo.SubWorkOrderTaskInstruction SET 
		SequenceNumber = @NewSequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE SubWorkOrderTaskInstructionId = @SubWorkOrderTaskInstructionId
		
		UPDATE dbo.SubWorkOrderTaskInstruction SET 
		SequenceNumber = @SequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE SubWorkOrderTaskInstructionId = @NewSubWorkOrderTaskInstructionId
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
	   , @AdhocComments     VARCHAR(150)    = 'USP_UpdateSWOTaskInstructionSequenceNumber'         
	   , @ProcedureParameters VARCHAR(3000)  = '@SubWorkOrderTaskInstructionId = '''+ ISNULL(@SubWorkOrderTaskInstructionId, '') + ''        
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