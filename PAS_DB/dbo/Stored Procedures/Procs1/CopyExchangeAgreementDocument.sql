/*************************************************************             
 ** File:   [CopyExchangeAgreementDocument]             
 ** Author:  
 ** Description:  
 ** Purpose:           
 ** Date:       
            
 ** PARAMETERS:
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------			--------------------------------     
					 Unkown					Created
    1    28/04/2025  Amit Ghediya			Update for insert more column.  
       
-- EXEC CopyExchangeAgreementDocument 1,129,456,502
************************************************************************/  
CREATE    PROCEDURE [dbo].[CopyExchangeAgreementDocument]
@MasterCompanyId int=1,
@ExchangeQuoteId bigint=21,
@ExchangeSalesOrderId bigint=21,
@AttachmentIds bigint=1 OUTPUT
AS
BEGIN
SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
	DECLARE @EXCHANGEQUOTEMODULEID BIGINT=64;
	DECLARE @EXCHANGESALESORDERMODULEID BIGINT=73;
	DECLARE @DocType BIGINT;
	DECLARE @AttachmentId BIGINT;

	SET @DocType=(SELECT [DocumentTypeId] FROM [DBO].[DocumentType] WITH(NOLOCK) WHERE MasterCompanyId=@MasterCompanyId AND [Name]='Exchange Agreement');
	
	SET @AttachmentId = (SELECT TOP 1 AttachmentId FROM [DBO].[CommonDocumentDetails] WITH(NOLOCK) WHERE ModuleId=@EXCHANGEQUOTEMODULEID AND ReferenceId=@ExchangeQuoteId AND DocumentTypeId=@DocType);
	
	INSERT INTO [DBO].[Attachment]([ModuleId],[ReferenceId],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[SubModuleId],[SubReferenceId])
	SELECT @EXCHANGESALESORDERMODULEID,@ExchangeSalesOrderId,@MasterCompanyId,[CreatedBy],GETDATE(),[UpdatedBy],GETDATE(),[IsActive],[IsDeleted],[SubModuleId],[SubReferenceId] 
	FROM [DBO].[Attachment] WITH(NOLOCK) WHERE AttachmentId=@AttachmentId;
	
	INSERT INTO [DBO].[AttachmentDetails]([AttachmentId],[FileName],[Description],[Link],[FileFormat],[FileSize],[FileType],[CreatedDate],[UpdatedDate],[CreatedBy],[UpdatedBy],[IsActive],[IsDeleted],[Name],[Memo],[TypeId])
	SELECT IDENT_CURRENT('Attachment'),[FileName],[Description],[Link],[FileFormat],[FileSize],[FileType],GETDATE(),GETDATE(),[CreatedBy],[UpdatedBy],[IsActive],[IsDeleted],[Name],[Memo],[TypeId]
	FROM [DBO].[AttachmentDetails] WITH(NOLOCK) WHERE AttachmentId=@AttachmentId;
	 
	INSERT INTO [DBO].[CommonDocumentDetails]([ModuleId],[ReferenceId],[AttachmentId],[DocName],[DocMemo],[DocDescription],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[DocumentTypeId],[ExpirationDate],[ReferenceIndex],[ModuleType],[SubModuleId],[SubReferenceId])
	SELECT @EXCHANGESALESORDERMODULEID,@ExchangeSalesOrderId,IDENT_CURRENT('Attachment'),[DocName],[DocMemo],[DocDescription],@MasterCompanyId,[CreatedBy],[UpdatedBy],GETDATE(),GETDATE(),[IsActive],[IsDeleted],[DocumentTypeId],[ExpirationDate],[ReferenceIndex],[ModuleType],[SubModuleId],[SubReferenceId] 
	FROM [DBO].[CommonDocumentDetails] WITH(NOLOCK) WHERE AttachmentId=@AttachmentId;

	SELECT @AttachmentIds = IDENT_CURRENT('Attachment');

	END TRY    
	BEGIN CATCH
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'CopyExchangeAgreementDocument'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ExchangeQuoteId, '') AS varchar(100))
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);           
	END CATCH
END