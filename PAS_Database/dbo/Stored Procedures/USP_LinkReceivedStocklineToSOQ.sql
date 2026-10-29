/*************************************************************
 ** File:   [USP_LinkReceivedStocklineToSOQ]
 ** Author: Vishal Suthar
 ** Description: Quote the stocklines received for a PO (created from an SOQ part) on that SOQ part - same as SOQ "Add Stockline", no reservation
 ** Date:   29/10/2026

 ** PARAMETERS: @StockLineIds - comma separated StockLineIds created by the PO receiving

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    29/10/2026   Vishal Suthar		Created [PN-18444]
    2    29/10/2026   Vishal Suthar		SOQ part / stockline status Order (partial) or Fulfilled (fully received) [PN-18445]

 EXEC [dbo].[USP_LinkReceivedStocklineToSOQ] '214514', 'ADMIN User', 1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_LinkReceivedStocklineToSOQ]
	@StockLineIds VARCHAR(MAX),
	@UpdatedBy VARCHAR(100),
	@MasterCompanyId BIGINT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION

		DECLARE @SOQPartStatusOrder INT = (SELECT TOP 1 [SOPartStatusId] FROM [dbo].[SOPartStatus] WITH (NOLOCK) WHERE [PartStatus] = 'Order');
		DECLARE @SOQPartStatusFulfilled INT = (SELECT TOP 1 [SOPartStatusId] FROM [dbo].[SOPartStatus] WITH (NOLOCK) WHERE [PartStatus] = 'Fulfilled');
		DECLARE @SOQPartStatusOpen INT = (SELECT TOP 1 [SOPartStatusId] FROM [dbo].[SOPartStatus] WITH (NOLOCK) WHERE [PartStatus] = 'Open');

		IF OBJECT_ID(N'tempdb..#SOQReceivedStk') IS NOT NULL
			DROP TABLE #SOQReceivedStk

		CREATE TABLE #SOQReceivedStk
		(
			[ID] INT NOT NULL IDENTITY,
			[StockLineId] BIGINT NULL,
			[SalesOrderQuoteId] BIGINT NULL,
			[SalesOrderQuotePartId] BIGINT NULL,
			[PurchaseOrderPartRecordId] BIGINT NULL
		)

		-- Received stockline -> PO part (or its split parent) created from an SOQ -> open, not converted SOQ part with the same PN + condition
		INSERT INTO #SOQReceivedStk ([StockLineId], [SalesOrderQuoteId], [SalesOrderQuotePartId], [PurchaseOrderPartRecordId])
		SELECT STK.[StockLineId], SQP.[SalesOrderQuoteId], SQP.[SalesOrderQuotePartId], STK.[PurchaseOrderPartRecordId]
			[SalesOrderQuotePartId] BIGINT NULL
		)

		-- Received stockline -> PO part (or its split parent) created from an SOQ -> open, not converted SOQ part with the same PN + condition
		INSERT INTO #SOQReceivedStk ([StockLineId], [SalesOrderQuoteId], [SalesOrderQuotePartId])
		SELECT STK.[StockLineId], SQP.[SalesOrderQuoteId], SQP.[SalesOrderQuotePartId]
		FROM [dbo].[SplitString](@StockLineIds, ',') S
		INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = TRY_CAST(S.[Item] AS BIGINT)
		INNER JOIN [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) ON POP.[PurchaseOrderPartRecordId] = STK.[PurchaseOrderPartRecordId]
		LEFT JOIN [dbo].[PurchaseOrderPart] PPOP WITH (NOLOCK) ON PPOP.[PurchaseOrderPartRecordId] = POP.[ParentId]
		CROSS APPLY (SELECT COALESCE(NULLIF(POP.[SalesOrderQuoteId], 0), NULLIF(PPOP.[SalesOrderQuoteId], 0)) AS [SalesOrderQuoteId]) Q
		INNER JOIN [dbo].[SalesOrderQuote] SOQ WITH (NOLOCK) ON SOQ.[SalesOrderQuoteId] = Q.[SalesOrderQuoteId] AND ISNULL(SOQ.[IsDeleted], 0) = 0
		INNER JOIN [dbo].[MasterSalesOrderQuoteStatus] SOQS WITH (NOLOCK) ON SOQS.[Id] = SOQ.[StatusId] AND SOQS.[Name] IN ('Open', 'Sent', 'Pending', 'Approved', 'Partially Approved')
		CROSS APPLY (SELECT TOP 1 P.[SalesOrderQuoteId], P.[SalesOrderQuotePartId]
		             FROM [dbo].[SalesOrderQuotePartV1] P WITH (NOLOCK)
		             WHERE P.[SalesOrderQuoteId] = SOQ.[SalesOrderQuoteId] AND P.[ItemMasterId] = STK.[ItemMasterId] AND P.[ConditionId] = STK.[ConditionId]
		               AND P.[IsDeleted] = 0 AND ISNULL(P.[IsConvertedToSalesOrder], 0) = 0
		             ORDER BY P.[SalesOrderQuotePartId]) SQP
		WHERE ISNULL(STK.[IsParent], 1) = 1 AND ISNULL(STK.[IsDeleted], 0) = 0;

		DECLARE @LoopID INT = 1, @MaxID INT = (SELECT MAX([ID]) FROM #SOQReceivedStk);

		WHILE (@LoopID <= ISNULL(@MaxID, 0))
		BEGIN
			DECLARE @StockLineId BIGINT, @SalesOrderQuoteId BIGINT, @SalesOrderQuotePartId BIGINT,
			        @QtyToQuote DECIMAL(18, 6), @PartQtyQuoted DECIMAL(18, 6),
			        @UnitSalesPrice DECIMAL(18, 6), @MarkUpPercentage DECIMAL(18, 6), @MarkUpPerUnit DECIMAL(18, 6),
			        @DiscountPercentage DECIMAL(18, 6), @DiscountPerUnit DECIMAL(18, 6), @SOQStocklineId BIGINT,
			        @POPartRecordId BIGINT, @ReceivedStatusId INT;

			SELECT @StockLineId = NULL, @SalesOrderQuoteId = NULL, @SalesOrderQuotePartId = NULL, @QtyToQuote = 0, @PartQtyQuoted = 0,
			       @UnitSalesPrice = 0, @MarkUpPercentage = 0, @MarkUpPerUnit = 0, @DiscountPercentage = 0, @DiscountPerUnit = 0, @SOQStocklineId = NULL,
			       @POPartRecordId = NULL, @ReceivedStatusId = NULL;

			SELECT @StockLineId = [StockLineId], @SalesOrderQuoteId = [SalesOrderQuoteId], @SalesOrderQuotePartId = [SalesOrderQuotePartId], @POPartRecordId = [PurchaseOrderPartRecordId]
			FROM #SOQReceivedStk WHERE [ID] = @LoopID;

			-- Same as SO: Fulfilled once the PO part is fully received, otherwise (partial) Order
			SELECT @ReceivedStatusId = CASE WHEN ISNULL(POP.[QuantityReceived], 0) >= ISNULL(POP.[QuantityOrdered], 0) THEN @SOQPartStatusFulfilled ELSE @SOQPartStatusOrder END
			FROM [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) WHERE POP.[PurchaseOrderPartRecordId] = @POPartRecordId;

			        @DiscountPercentage DECIMAL(18, 6), @DiscountPerUnit DECIMAL(18, 6), @SOQStocklineId BIGINT;

			SELECT @StockLineId = NULL, @SalesOrderQuoteId = NULL, @SalesOrderQuotePartId = NULL, @QtyToQuote = 0, @PartQtyQuoted = 0,
			       @UnitSalesPrice = 0, @MarkUpPercentage = 0, @MarkUpPerUnit = 0, @DiscountPercentage = 0, @DiscountPerUnit = 0, @SOQStocklineId = NULL;

			SELECT @StockLineId = [StockLineId], @SalesOrderQuoteId = [SalesOrderQuoteId], @SalesOrderQuotePartId = [SalesOrderQuotePartId]
			FROM #SOQReceivedStk WHERE [ID] = @LoopID;

			-- Only what the SOQ part still needs, capped at the received (available) qty
			SELECT @QtyToQuote = ISNULL(P.[QtyRequested], 0)
			                   - ISNULL((SELECT SUM(ISNULL(S.[QtyQuoted], 0)) FROM [dbo].[SalesOrderQuoteStocklineV1] S WITH (NOLOCK)
			                             WHERE S.[SalesOrderQuotePartId] = P.[SalesOrderQuotePartId] AND S.[IsDeleted] = 0), 0),
			       @PartQtyQuoted = P.[QtyQuoted]
			FROM [dbo].[SalesOrderQuotePartV1] P WITH (NOLOCK) WHERE P.[SalesOrderQuotePartId] = @SalesOrderQuotePartId;

			SELECT @QtyToQuote = CASE WHEN STK.[QuantityAvailable] < @QtyToQuote THEN STK.[QuantityAvailable] ELSE @QtyToQuote END
			FROM [dbo].[Stockline] STK WITH (NOLOCK) WHERE STK.[StockLineId] = @StockLineId;

			IF (ISNULL(@QtyToQuote, 0) > 0
			    AND NOT EXISTS (SELECT 1 FROM [dbo].[SalesOrderQuoteStocklineV1] WITH (NOLOCK)
			                    WHERE [SalesOrderQuotePartId] = @SalesOrderQuotePartId AND [StockLineId] = @StockLineId AND [IsDeleted] = 0))
			BEGIN
				-- Price / markup / discount of the SOQ part (amounts are stored extended over the part qty)
				SELECT @UnitSalesPrice = ISNULL(PC.[UnitSalesPrice], 0),
				       @MarkUpPercentage = ISNULL(PC.[MarkUpPercentage], 0),
				       @MarkUpPerUnit = ISNULL(PC.[MarkUpAmount], 0) / NULLIF(@PartQtyQuoted, 0),
				       @DiscountPercentage = ISNULL(PC.[DiscountPercentage], 0),
				       @DiscountPerUnit = ISNULL(PC.[DiscountAmount], 0) / NULLIF(@PartQtyQuoted, 0)
				FROM [dbo].[SalesOrderQuotePartCost] PC WITH (NOLOCK) WHERE PC.[SalesOrderQuotePartId] = @SalesOrderQuotePartId;

				INSERT INTO [dbo].[SalesOrderQuoteStocklineV1] ([SalesOrderQuotePartId], [StockLineId], [ConditionId], [QtyQuoted], [QtyAvailable], [QtyOH], [CustomerRequestDate], [PromisedDate], [EstimatedShipDate], [StatusId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
				SELECT P.[SalesOrderQuotePartId], STK.[StockLineId], STK.[ConditionId], @QtyToQuote, STK.[QuantityAvailable], STK.[QuantityOnHand], P.[CustomerRequestDate], P.[PromisedDate], P.[EstimatedShipDate], @ReceivedStatusId, @MasterCompanyId, @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0
				SELECT P.[SalesOrderQuotePartId], STK.[StockLineId], STK.[ConditionId], @QtyToQuote, STK.[QuantityAvailable], STK.[QuantityOnHand], P.[CustomerRequestDate], P.[PromisedDate], P.[EstimatedShipDate], @SOQPartStatusOpen, @MasterCompanyId, @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0
				FROM [dbo].[SalesOrderQuotePartV1] P WITH (NOLOCK)
				INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = @StockLineId
				WHERE P.[SalesOrderQuotePartId] = @SalesOrderQuotePartId;

				SET @SOQStocklineId = SCOPE_IDENTITY();

				-- Extended / net / margin values are recalculated by USP_UpdateSOQPartCostDetails
				INSERT INTO [dbo].[SalesOrderQuoteStockLineCost] ([SalesOrderQuoteId], [SalesOrderQuotePartId], [SalesOrderQuoteStocklineId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [NetSaleAmount], [UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [DiscountPercentage], [DiscountAmount], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [NetSaleAmountPerUnit])
				SELECT @SalesOrderQuoteId, @SalesOrderQuotePartId, @SOQStocklineId, @UnitSalesPrice, @UnitSalesPrice * @QtyToQuote, @MarkUpPercentage, ISNULL(@MarkUpPerUnit, 0) * @QtyToQuote,
				       ((@UnitSalesPrice + ISNULL(@MarkUpPerUnit, 0)) - ISNULL(@DiscountPerUnit, 0)) * @QtyToQuote,
				       ISNULL(STK.[UnitCost], 0), ISNULL(STK.[UnitCost], 0) * @QtyToQuote, 0, 0, @DiscountPercentage, ISNULL(@DiscountPerUnit, 0) * @QtyToQuote,
				       @MasterCompanyId, @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0, (@UnitSalesPrice + ISNULL(@MarkUpPerUnit, 0)) - ISNULL(@DiscountPerUnit, 0)
				FROM [dbo].[Stockline] STK WITH (NOLOCK) WHERE STK.[StockLineId] = @StockLineId;

				EXEC [dbo].[USP_SOQResetApprovalProcess] @SalesOrderQuoteId, @SalesOrderQuotePartId, @MasterCompanyId;
				EXEC [dbo].[USP_UpdateSOQPartCostDetails] @SalesOrderQuoteId, @SalesOrderQuotePartId, @UpdatedBy, @MasterCompanyId;
			END

			EXEC [dbo].[USP_SaveSOQPartStatusByPartId] @SalesOrderQuotePartId, @ReceivedStatusId, @POPartRecordId;

			SET @LoopID = @LoopID + 1;
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
			, @AdhocComments VARCHAR(150) = 'USP_LinkReceivedStocklineToSOQ'
			, @ProcedureParameters VARCHAR(3000) = '@StockLineIds = ''' + ISNULL(LEFT(@StockLineIds, 2900), '') + ''''
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
