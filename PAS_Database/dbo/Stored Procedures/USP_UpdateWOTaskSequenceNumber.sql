/*************************************************************             
 ** File:   [USP_UpdateWOTaskSequenceNumber]             
 ** Author:  Vishal Suthar 
 ** Description: This stored procedure is used to update Sequence of WO Task
 ** Purpose:           
 ** Date:   12/26/2024
 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
	1    12/26/2024   Vishal Suthar		Created

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateWOTaskSequenceNumber]
(
	@WorkOrderTaskId BIGINT,
	@NewWorkOrderTaskId BIGINT,
	@SequenceNumber BIGINT,
	@NewSequenceNumber BIGINT,
	@UpdatedBy VARCHAR(50)
)
AS
BEGIN 
	BEGIN TRY
	BEGIN	
		UPDATE dbo.WorkOrderTask SET 
		SequenceNumber = @NewSequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE WorkOrderTaskId = @WorkOrderTaskId
		
		UPDATE dbo.WorkOrderTask SET 
		SequenceNumber = @SequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE WorkOrderTaskId = @NewWorkOrderTaskId
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
	   , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWOTaskSequenceNumber'         
	   , @ProcedureParameters VARCHAR(3000)  = '@WorkOrderTaskId = '''+ ISNULL(@WorkOrderTaskId, '') + ''        
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