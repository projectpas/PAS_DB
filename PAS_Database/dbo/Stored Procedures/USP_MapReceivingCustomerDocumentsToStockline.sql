/*********************************************************************************************           
 ** File:   [USP_MapReceivingCustomerDocumentsToStockline]           
 ** Author:  MOIN BLOCH
 ** Description: This stored procedure is used to Map the Receiving Customer Works Documents to StockLine
 ** Date:   10-April-2025     
 *********************************************************************************************           
  ** Change History           
 *********************************************************************************************           
 ** PR   Date					Author					Change Description            
 ** --   --------				-------					--------------------------------          
    1    10-April-2025		 	Devendra Shekh			Created
***********************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_MapReceivingCustomerDocumentsToStockline]
@ReferenceId BIGINT = NULL,
@ModuleId BIGINT = NULL,
@SubModuleId BIGINT = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @StkModuleId INT = 0, @RecModuleId INT = 0;
		DECLARE @SubReferenceId BIGINT = 0;

		SELECT @StkModuleId = [AttachmentModuleId] FROM [dbo].[AttachmentModule] WITH(NOLOCK) WHERE UPPER([Name]) = 'STOCKLINE';
		SELECT @RecModuleId = [AttachmentModuleId] FROM [dbo].[AttachmentModule] WITH(NOLOCK) WHERE UPPER([Name]) = 'RECEIVINGCUSTOMERWORK';

		IF(ISNULL(@ModuleId, 0) = ISNULL(@RecModuleId, 0))
		BEGIN

			SELECT @SubReferenceId = [StockLineId] FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE [ReceivingCustomerWorkId] = @ReferenceId;

			--Mapping Attacments For SubModule
			UPDATE ATC
			SET	ATC.SubReferenceId = @SubReferenceId,
				ATC.SubModuleId = @StkModuleId
			FROM [dbo].[Attachment] ATC WITH(NOLOCK)
			WHERE ATC.ReferenceId = @ReferenceId AND ATC.ModuleId = @ModuleId;

			--Mapping CommonDocuments For SubModule
			UPDATE CDD
			SET	CDD.SubReferenceId = @SubReferenceId,
				CDD.SubModuleId = @StkModuleId
			FROM [dbo].[CommonDocumentDetails] CDD WITH(NOLOCK)
			WHERE CDD.ReferenceId = @ReferenceId AND CDD.ModuleId = @ModuleId;

		END

	END TRY    
	BEGIN CATCH 
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_MapReceivingCustomerDocumentsToStockline'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100))
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