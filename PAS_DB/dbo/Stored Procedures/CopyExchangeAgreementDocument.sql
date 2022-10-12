CREATE PROCEDURE [dbo].[CopyExchangeAgreementDocument]
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
	DECLARE @DocType bigint;
	SET @DocType=(SELECT DocumentTypeId From DocumentType WHERE MasterCompanyId=@MasterCompanyId AND [Name]='Exchange Agreement');
	--PRINT @DocType;
	DECLARE @AttachmentId bigint;
	SET @AttachmentId = (select TOP 1 AttachmentId from CommonDocumentDetails where ModuleId=@EXCHANGEQUOTEMODULEID and ReferenceId=@ExchangeQuoteId AND DocumentTypeId=@DocType);
	
	INSERT INTO Attachment
	SELECT @EXCHANGESALESORDERMODULEID,@ExchangeSalesOrderId,@MasterCompanyId,CreatedBy,GETDATE(),UpdatedBy,GETDATE(),IsActive,IsDeleted FROM Attachment WHERE AttachmentId=@AttachmentId;
	
	INSERT INTO AttachmentDetails
	SELECT IDENT_CURRENT('Attachment'),FileName,Description,Link,FileFormat,FileSize,FileType,GETDATE(),GETDATE(),CreatedBy,UpdatedBy,IsActive,IsDeleted,[Name],Memo,TypeId FROM AttachmentDetails WHERE AttachmentId=@AttachmentId;
	
	INSERT INTO CommonDocumentDetails
	SELECT @EXCHANGESALESORDERMODULEID,@ExchangeSalesOrderId,IDENT_CURRENT('Attachment'),DocName,DocMemo,DocDescription,@MasterCompanyId,CreatedBy,UpdatedBy,GETDATE(),GETDATE(),IsActive,IsDeleted,DocumentTypeId,NULL,ReferenceIndex,ModuleType FROM CommonDocumentDetails WHERE AttachmentId=@AttachmentId;

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