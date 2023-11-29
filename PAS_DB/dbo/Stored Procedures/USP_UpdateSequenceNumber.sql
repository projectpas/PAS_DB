/*************************************************************             
 ** File:   [USP_UpdateSequenceNumber]             
 ** Author:  Satish Gohil 
 ** Description: This stored procedure is used to update Sequence of leafnode
 ** Purpose:           
 ** Date:   07/06/2023
 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
	1    07/06/2023  Satish Gohil  Created

************************************************************************/ 

CREATE   PROCEDURE dbo.USP_UpdateSequenceNumber
(
	@LeafNodeId BIGINT,
	@SequenceNumber BIGINT,
	@NewLeafNodeId BIGINT,
	@NewSequenceNumber BIGINT,
	@UpdatedBy VARCHAR(50)
)
AS
BEGIN 
	BEGIN TRY
	BEGIN	
		UPDATE dbo.LeafNode SET 
		SequenceNumber = @NewSequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE LeafNodeId = @LeafNodeId
		
		UPDATE dbo.LeafNode SET 
		SequenceNumber = @SequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE LeafNodeId = @NewLeafNodeId

		SELECT ReportingStructureId from dbo.LeafNode WITH(NOLOCK) WHERE LeafNodeId = @LeafNodeId

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
	   , @AdhocComments     VARCHAR(150)    = 'USP_UpdateSequenceNumber'         
	   , @ProcedureParameters VARCHAR(3000)  = '@LeafNodeId = '''+ ISNULL(@LeafNodeId, '') + ''        
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