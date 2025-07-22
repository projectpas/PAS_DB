/*************************************************************           
 ** File:		 [USP_LegalEntityLogoDelete]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Delete Legal Entity Logo.
 ** Purpose:         
 ** Date:   08-July-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    08-July-2025		Divyesh Kathiriya	Created	
    
 -- EXEC [USP_LegalEntityLogoDelete] @AttachmentDetailId=184911
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_LegalEntityLogoDelete]
@AttachmentDetailId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @Result BIT; 

		IF EXISTS (SELECT 1 FROM [DBO].[AttachmentDetails] WITH (NOLOCK) WHERE [AttachmentDetailId] = @AttachmentDetailId)
		BEGIN
			DELETE FROM [DBO].[AttachmentDetails]
			WHERE [AttachmentDetailId] = @AttachmentDetailId;

			SET @Result = 1;
			
		END
		ELSE
		BEGIN
			
			SET @Result = 0;			
		END		
		
		SELECT @Result AS Result;		
		
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityLogoDelete'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END