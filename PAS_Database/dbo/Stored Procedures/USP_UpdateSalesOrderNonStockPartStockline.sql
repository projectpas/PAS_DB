
/***************************************************************
 ** File:   [USP_UpdateSalesOrderNonStockPartStockline]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used add or update sales order Non Stock part details
 ** Purpose: [PN-17009] Merge Non-Stock Inventory into Stockline: when a Sales Order line for a
 **          Service + Non-Stock Stockline record gets billed/invoiced, zero out its quantity
 **          fields (Non-Stock/Service items are not tracked for on-hand quantity the way normal
 **          stock is).
 ** Date:   01/08/2026

 ** Change History
 **************************************************************
 ** PR   Date         Author  		 Change Description
 ** --   --------     -------		 --------------------------------
    1    01/08/2026   MOIN BLOCH	   Created
	2    04-Aug-2026   Rajesh Gami    [PN-17009] Ported from BETA into current branch.
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateSalesOrderNonStockPartStockline]
@SalesOrderId BIGINT,
@BillingInvoicingId BIGINT,
@UpdatedBy VARCHAR(256) = ''
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION

			DECLARE @SOModuleId INT = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder')

			IF(@BillingInvoicingId > 0)
			BEGIN
				DECLARE @TotalRecord int = 0;
				DECLARE @MinId BIGINT = 1;

				IF OBJECT_ID(N'tempdb..#tmpSOPartIds') IS NOT NULL
				BEGIN
					DROP TABLE #tmpSOPartIds
				END

				CREATE TABLE #tmpSOPartIds (
					[ID] BIGINT NOT NULL IDENTITY,
					[SubReferenceId] BIGINT
				);

				INSERT INTO #tmpSOPartIds ([SubReferenceId])
						SELECT DISTINCT BIII.[SubReferenceId]
				FROM [dbo].[BillingInvoicing] SOBI WITH(NOLOCK)
				INNER JOIN [dbo].[BillingInvoicingItems] BIII WITH(NOLOCK) ON SOBI.BillingInvoicingId = BIII.BillingInvoicingId
				WHERE SOBI.[BillingInvoicingId]=@BillingInvoicingId AND SOBI.[ModuleId] = @SOModuleId
				 AND ISNULL(SOBI.[IsPerformaInvoice],0) = 0
				 AND ISNULL(SOBI.[IsVersionIncrease],0) = 0
				 AND ISNULL(BIII.[IsPerformaInvoice],0) = 0
				 AND ISNULL(BIII.[IsVersionIncrease],0) = 0

				SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmpSOPartIds

				WHILE @MinId <= @TotalRecord
				BEGIN
					DECLARE @SubReferenceId BIGINT,@ItemMasterId BIGINT,@StockLineId BIGINT
					DECLARE @IsService BIT = 0,@IsNonStock BIT = 0

					SELECT @SubReferenceId = [SubReferenceId] FROM #tmpSOPartIds WHERE [ID] = @MinId

					SELECT @ItemMasterId = SOP.[ItemMasterId],
						   @StockLineId = STK.[StockLineId]
						FROM [dbo].[SalesOrderPartV1] SOP WITH(NOLOCK)
							LEFT JOIN [dbo].[SalesOrderStocklineV1] STK WITH(NOLOCK) ON STK.[SalesOrderPartId] = SOP.[SalesOrderPartId]
							LEFT JOIN [dbo].[ItemMaster] itm WITH(NOLOCK) ON itm.[ItemMasterId] = sop.[ItemMasterId]
						 WHERE SOP.[SalesOrderId] = @SalesOrderId AND SOP.[SalesOrderPartId] = @SubReferenceId

					SELECT @IsService = ISNULL([IsService],0), @IsNonStock = ISNULL([IsNonStock],0) FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [StockLineId] = @StockLineId

					IF(@IsService = 1 AND @IsNonStock = 1 AND ISNULL(@StockLineId, 0) > 0)
					BEGIN
						UPDATE [dbo].[Stockline]
						   SET [QuantityAvailable] = 0,
						       [QuantityOnHand] = 0,
							   [QuantityIssued] = 0,
							   [QuantityReserved] = 0,
							   [UpdatedBy] = @UpdatedBy,
							   [UpdatedDate] = GETUTCDATE()
						 WHERE [StockLineId] = @StockLineId

						DECLARE @StocklineHistoryUnReserveRemoveOnHandActionEnum INT = 0

						SELECT @StocklineHistoryUnReserveRemoveOnHandActionEnum = [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type]='UnReserve-RemoveOnHand';

						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StockLineId,@SOModuleId,@SalesOrderId,NULL,NULL,@StocklineHistoryUnReserveRemoveOnHandActionEnum,0,@UpdatedBy;
					END

					SET @MinId = @MinId + 1
				END
			END

  COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_UpdateSalesOrderNonStockPartStockline',
            @ProcedureParameters varchar(3000) = '@SalesOrderId = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END
