/*************************************************************           
 ** File:     [USP_UpdateTenderStocklineAttachmentDetail]           
 ** Author:	  Moin Bloch
 ** Description: This SP IS Used update Tendor Stockline Attachment Details
 ** Purpose:         
 ** Date:   02/04/2024	          
 ** PARAMETERS:       
 ** RETURN VALUE:     
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date			Author					Change Description            
 ** --   	--------		-------				--------------------------------     
	1		02/04/2024		Moin Bloch			CREATED

	EXEC [USP_UpdateTenderStocklineAttachmentDetail] 
**************************************************************/ 
CREATE PROCEDURE [dbo].[USP_UpdateTenderStocklineAttachmentDetail]
@StocklineId BIGINT,
@PDFName NVARCHAR(100),
@Path NVARCHAR(MAX),
@FileSize Decimal(18,2),
@UpdatedBy VARCHAR(50),
@AttachmentId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN					
				UPDATE [dbo].[Attachment] 
				   SET [UpdatedBy] = @UpdatedBy,
					   [UpdatedDate] = GETUTCDATE() 					  
				 WHERE [AttachmentId] = @AttachmentId
				   AND [ReferenceId] = @StocklineId;

				UPDATE [dbo].[AttachmentDetails] 
				   SET [FileName] = @PDFName,
					   [FileSize] = @FileSize,
					   [Link] = @Path,
					   [Name] = @PDFName,
				       [UpdatedBy] = @UpdatedBy,
					   [UpdatedDate] = GETUTCDATE() 					  
				 WHERE [AttachmentId] = @AttachmentId;

				UPDATE [dbo].[CommonDocumentDetails] 
				   SET [DocName] = @PDFName,					   
				       [UpdatedBy] = @UpdatedBy,
					   [UpdatedDate] = GETUTCDATE() 					  
				 WHERE [AttachmentId] = @AttachmentId 
				   AND [ReferenceId] = @StocklineId;

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateTenderStocklineAttachmentDetail' 
               ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StocklineId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END