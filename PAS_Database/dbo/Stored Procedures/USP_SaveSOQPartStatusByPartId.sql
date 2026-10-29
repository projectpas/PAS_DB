/*************************************************************
 ** File:   [USP_SaveSOQPartStatusByPartId]
 ** Author: Vishal Suthar
 ** Description: Set the status of a SOQ part and its stocklines (same as SP_SaveSOPartStatusByPartId for SO)
 ** Date:   29/10/2026

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    29/10/2026   Vishal Suthar		Created [PN-18445]

 EXEC [dbo].[USP_SaveSOQPartStatusByPartId] 5828, 2
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveSOQPartStatusByPartId]
	@SalesOrderQuotePartId BIGINT = 0,
	@StatusId INT = 0,
	@PurchaseOrderPartRecordId BIGINT = NULL -- set: only the SOQ stocklines received from this PO part
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION

		IF (ISNULL(@SalesOrderQuotePartId, 0) > 0 AND ISNULL(@StatusId, 0) > 0)
		BEGIN
			DECLARE @StatusName VARCHAR(100) = (SELECT TOP 1 [PartStatus] FROM [dbo].[SOPartStatus] WITH (NOLOCK) WHERE [SOPartStatusId] = @StatusId);

			UPDATE [dbo].[SalesOrderQuotePartV1]
			SET [StatusId] = @StatusId, [StatusName] = @StatusName
			WHERE [SalesOrderQuotePartId] = @SalesOrderQuotePartId;

			UPDATE SQS
			SET SQS.[StatusId] = @StatusId, SQS.[StatusName] = @StatusName
			FROM [dbo].[SalesOrderQuoteStocklineV1] SQS
			LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = SQS.[StockLineId]
			WHERE SQS.[SalesOrderQuotePartId] = @SalesOrderQuotePartId AND SQS.[IsDeleted] = 0
			  AND (@PurchaseOrderPartRecordId IS NULL OR STK.[PurchaseOrderPartRecordId] = @PurchaseOrderPartRecordId);
		END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
		END

		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_SaveSOQPartStatusByPartId'
			, @ProcedureParameters VARCHAR(3000) = '@SalesOrderQuotePartId = ''' + CAST(ISNULL(@SalesOrderQuotePartId, 0) AS VARCHAR(20)) + ''', @StatusId = ''' + CAST(ISNULL(@StatusId, 0) AS VARCHAR(20)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			@DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END
