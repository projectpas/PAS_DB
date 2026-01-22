
/*************************************************************             
 ** File:   [USP_UpdateGLLeafNodeSequenceNumber]             
 ** Author:  Rajesh Gami 
 ** Description: This stored procedure is used to update Sequence of GL Account LeafNode Mapping Table
 ** Purpose:           
 ** Date:   23 Feb 2024
 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author     Change Description              
 ** --   --------     -------    --------------------------------            
	1    23 Feb 2024  Rajesh Gami  Created

************************************************************************/ 

CREATE     PROCEDURE [dbo].[USP_UpdateGLLeafNodeSequenceNumber]
(
	@GlMappingId BIGINT,
	@SequenceNumber BIGINT,
	@NewGlMappingId BIGINT,
	@NewSequenceNumber BIGINT,
	@UpdatedBy VARCHAR(50),
	@LeafNodeId BIGINT
)
AS
BEGIN 
	BEGIN TRY
	BEGIN
		/** Update GLAccountLeafNodeMapping with new sequence number **/
		UPDATE dbo.GLAccountLeafNodeMapping SET 
		SequenceNumber = @NewSequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE GLAccountLeafNodeMappingId = @GlMappingId
		
		UPDATE dbo.GLAccountLeafNodeMapping SET 
		SequenceNumber = @SequenceNumber,
		UpdatedBy = @UpdatedBy,
		UpdatedDate = GETUTCDATE() 
		WHERE GLAccountLeafNodeMappingId = @NewGlMappingId

		SELECT ReportingStructureId from dbo.LeafNode WITH(NOLOCK) WHERE LeafNodeId = @LeafNodeId

	END
	END TRY
	BEGIN CATCH
		SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_STATE() AS ErrorState,ERROR_SEVERITY() AS ErrorSeverity, 
			   ERROR_PROCEDURE() AS ErrorProcedure, ERROR_LINE() AS ErrorLine, ERROR_MESSAGE() AS ErrorMessage;        
	   IF @@trancount > 0        
	   PRINT 'ROLLBACK'        
	   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()         
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
	   , @AdhocComments     VARCHAR(150)    = 'USP_UpdateGLLeafNodeSequenceNumber'         
	   , @ProcedureParameters VARCHAR(3000)  = '@GlMappingId = '''+ ISNULL(@GlMappingId, '') + ''        
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