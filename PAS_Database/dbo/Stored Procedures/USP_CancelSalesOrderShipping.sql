/*************************************************************
 ** File:   [USP_CancelSalesOrderShipping]
 ** Author:  Vishal Suthar
 ** Description: Cancels a Sales Order shipment: returns the shipped qty to the stockline (back to Reserved for the SO),
 **              reverses the shipping accounting entry (SOS) and keeps the shipping record with status CANCELED.
 ** Purpose:  [PN-18475] SO Shipping - Canceled status with reversal
 ** Date:   05-11-2026
 ** PARAMETERS: @SalesOrderShippingId BIGINT, @MasterCompanyId INT, @UpdatedBy VARCHAR(256)
 ** RETURN VALUE: IsSuccess, Message
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    05-11-2026   Vishal Suthar		Created

 EXEC [dbo].[USP_CancelSalesOrderShipping] @SalesOrderShippingId = 1, @MasterCompanyId = 1, @UpdatedBy = 'ADMIN User'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CancelSalesOrderShipping]
	@SalesOrderShippingId BIGINT,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @CanceledStatusId BIGINT = (SELECT TOP 1 [ShippingStatusId] FROM [dbo].[ShippingStatus] WITH(NOLOCK) WHERE [Status] = 'CANCELED');
	DECLARE @SOModuleId INT = (SELECT TOP 1 [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder');
	DECLARE @SOShippingModuleId INT = (SELECT TOP 1 [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrderShipping');
	DECLARE @CancelActionId INT = (SELECT TOP 1 [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type] = 'Shipping-Canceled');
	DECLARE @SOClosedStatusId INT = (SELECT TOP 1 [Id] FROM [dbo].[MasterSalesOrderStatus] WITH(NOLOCK) WHERE [Name] = 'Closed');
	DECLARE @PartReserveStatusId INT = 1; -- PartStatusEnum.Reserve
	DECLARE @SOPartStatusOpen INT = (SELECT TOP 1 [SOPartStatusId] FROM [dbo].[SOPartStatus] WITH(NOLOCK) WHERE [PartStatus] = 'Open');
	DECLARE @SOPartStatusFulfilled INT = (SELECT TOP 1 [SOPartStatusId] FROM [dbo].[SOPartStatus] WITH(NOLOCK) WHERE [PartStatus] = 'Fulfilled');
	DECLARE @SOPartStatusShipped INT = (SELECT TOP 1 [SOPartStatusId] FROM [dbo].[SOPartStatus] WITH(NOLOCK) WHERE [PartStatus] = 'Shipped');
	DECLARE @SalesOrderId BIGINT, @StatusId BIGINT, @SOStatusId INT;

	SELECT @SalesOrderId = SOS.[SalesOrderId], @StatusId = SOS.[SOShippingStatusId], @SOStatusId = SO.[StatusId]
	FROM [dbo].[SalesOrderShipping] SOS WITH(NOLOCK)
	INNER JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON SO.[SalesOrderId] = SOS.[SalesOrderId]
	WHERE SOS.[SalesOrderShippingId] = @SalesOrderShippingId AND SOS.[MasterCompanyId] = @MasterCompanyId AND SOS.[IsDeleted] = 0;

	IF (@SalesOrderId IS NULL)
	BEGIN
		SELECT CAST(0 AS BIT) AS IsSuccess, 'Shipping not found.' AS [Message]; RETURN;
	END
	IF (@CanceledStatusId IS NULL OR @CancelActionId IS NULL)
	BEGIN
		SELECT CAST(0 AS BIT) AS IsSuccess, 'Shipping Canceled status / stockline history action is not set up.' AS [Message]; RETURN;
	END
	IF (@StatusId = @CanceledStatusId)
	BEGIN
		SELECT CAST(0 AS BIT) AS IsSuccess, 'Shipping is already canceled.' AS [Message]; RETURN;
	END
	IF (@SOStatusId = @SOClosedStatusId)
	BEGIN
		SELECT CAST(0 AS BIT) AS IsSuccess, 'Shipping cannot be canceled on a Closed Sales Order.' AS [Message]; RETURN;
	END

	-- Shipped lines with their stockline / UOM
	SELECT SOSI.[SalesOrderShippingItemId], SOSI.[SalesOrderPartId], SOSI.[QtyShipped], SOPT.[SalesOrderPartStocklineId] AS SalesOrderStocklineId,
		STK.[StockLineId], STK.[LotId],
		QtyReserve = CASE WHEN ISNULL(STK.[StockUnitOfMeasure], '') = '' OR ISNULL(STK.[ConsumeUnitOfMeasure], '') = '' OR STK.[StockUnitOfMeasure] = STK.[ConsumeUnitOfMeasure]
						THEN SOSI.[QtyShipped]
						ELSE [dbo].[fn_ConvertUOM](SOSI.[QtyShipped], STK.[StockUnitOfMeasure], STK.[ConsumeUnitOfMeasure], 0, @MasterCompanyId) END
	INTO #CancelItems
	FROM [dbo].[SalesOrderShippingItem] SOSI WITH(NOLOCK)
	INNER JOIN [dbo].[SOPickTicket] SOPT WITH(NOLOCK) ON SOPT.[SOPickTicketId] = SOSI.[SOPickTicketId]
	INNER JOIN [dbo].[SalesOrderStocklineV1] SOSL WITH(NOLOCK) ON SOSL.[SalesOrderStocklineId] = SOPT.[SalesOrderPartStocklineId]
	INNER JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON STK.[StockLineId] = SOSL.[StockLineId]
	WHERE SOSI.[SalesOrderShippingId] = @SalesOrderShippingId AND SOSI.[IsDeleted] = 0 AND ISNULL(SOSI.[QtyShipped], 0) > 0;

	IF NOT EXISTS (SELECT 1 FROM #CancelItems)
	BEGIN
		SELECT CAST(0 AS BIT) AS IsSuccess, 'There is no shipped quantity to cancel.' AS [Message]; RETURN;
	END

	IF EXISTS (SELECT 1 FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
				INNER JOIN [dbo].[BillingInvoicing] BI WITH(NOLOCK) ON BI.[BillingInvoicingId] = BII.[BillingInvoicingId]
				WHERE BII.[ShippingId] = @SalesOrderShippingId AND BII.[ModuleId] = @SOModuleId AND BI.[ModuleId] = @SOModuleId
				AND ISNULL(BI.[IsInvoicePosted], 0) = 1 AND ISNULL(BII.[IsPerformaInvoice], 0) = 0 AND ISNULL(BII.[IsVersionIncrease], 0) = 0
				AND ISNULL(BI.[IsVersionIncrease], 0) = 0 AND ISNULL(BI.[IsDeleted], 0) = 0)
	BEGIN
		SELECT CAST(0 AS BIT) AS IsSuccess, 'Shipping cannot be canceled. An invoice has been posted for this part. Please reverse or credit the invoice first.' AS [Message]; RETURN;
	END

	-- Lot costing is moved to Sold when shipped; reversing it is not supported here
	IF EXISTS (SELECT 1 FROM #CancelItems WHERE ISNULL([LotId], 0) > 0)
	BEGIN
		SELECT CAST(0 AS BIT) AS IsSuccess, 'Shipping cannot be canceled for a stockline that belongs to a Lot.' AS [Message]; RETURN;
	END

	BEGIN TRY
		BEGIN TRANSACTION

			-- Back on hand and reserved for the SO (Available stays the same)
			UPDATE STK SET STK.[Quantity] = ISNULL(STK.[Quantity], 0) + CI.[QtyShipped],
				STK.[QuantityOnHand] = ISNULL(STK.[QuantityOnHand], 0) + CI.[QtyShipped],
				STK.[QuantityReserved] = ISNULL(STK.[QuantityReserved], 0) + CI.[QtyReserve],
				STK.[UpdatedBy] = @UpdatedBy, STK.[UpdatedDate] = GETUTCDATE()
			FROM [dbo].[Stockline] STK
			INNER JOIN (SELECT [StockLineId], SUM([QtyShipped]) AS QtyShipped, SUM([QtyReserve]) AS QtyReserve FROM #CancelItems GROUP BY [StockLineId]) CI ON CI.[StockLineId] = STK.[StockLineId];

			UPDATE SRP SET SRP.[QtyToReserve] = ISNULL(SRP.[QtyToReserve], 0) + CI.[QtyReserve],
				SRP.[TotalReserved] = ISNULL(SRP.[TotalReserved], 0) + CI.[QtyReserve],
				SRP.[PartStatusId] = @PartReserveStatusId, SRP.[UpdatedBy] = @UpdatedBy, SRP.[UpdatedDate] = GETUTCDATE()
			FROM [dbo].[SalesOrderReserveParts] SRP
			INNER JOIN (SELECT [SalesOrderPartId], [StockLineId], SUM([QtyReserve]) AS QtyReserve FROM #CancelItems GROUP BY [SalesOrderPartId], [StockLineId]) CI
				ON CI.[SalesOrderPartId] = SRP.[SalesOrderPartId] AND CI.[StockLineId] = SRP.[StockLineId]
			WHERE SRP.[SalesOrderId] = @SalesOrderId;

			UPDATE SOSL SET SOSL.[QtyReserved] = ISNULL(SOSL.[QtyReserved], 0) + CI.[QtyReserve],
				SOSL.[UpdatedBy] = @UpdatedBy, SOSL.[UpdatedDate] = GETUTCDATE()
			FROM [dbo].[SalesOrderStocklineV1] SOSL
			INNER JOIN (SELECT [SalesOrderStocklineId], SUM([QtyReserve]) AS QtyReserve FROM #CancelItems GROUP BY [SalesOrderStocklineId]) CI ON CI.[SalesOrderStocklineId] = SOSL.[SalesOrderStocklineId];

			-- Keep the shipping lines for audit, but no longer count them as shipped
			UPDATE SOSI SET SOSI.[QtyCanceled] = SOSI.[QtyShipped], SOSI.[QtyShipped] = 0, SOSI.[UpdatedBy] = @UpdatedBy, SOSI.[UpdatedDate] = GETUTCDATE()
			FROM [dbo].[SalesOrderShippingItem] SOSI
			INNER JOIN #CancelItems CI ON CI.[SalesOrderShippingItemId] = SOSI.[SalesOrderShippingItemId];

			UPDATE [dbo].[SalesOrderShipping] SET [SOShippingStatusId] = @CanceledStatusId, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [SalesOrderShippingId] = @SalesOrderShippingId;

			-- Draft (not posted) invoice lines linked to this shipment get linked again on the next shipment
			UPDATE BII SET BII.[ShippingId] = NULL
			FROM [dbo].[BillingInvoicingItems] BII
			INNER JOIN [dbo].[BillingInvoicing] BI WITH(NOLOCK) ON BI.[BillingInvoicingId] = BII.[BillingInvoicingId]
			WHERE BII.[ShippingId] = @SalesOrderShippingId AND BII.[ModuleId] = @SOModuleId
			AND ISNULL(BI.[IsInvoicePosted], 0) = 0 AND ISNULL(BII.[IsPerformaInvoice], 0) = 0;

			-- Reverse the shipping accounting entry (Dr Parts Inventory / Cr Inventory to Bill)
			DECLARE @ReversalMessage VARCHAR(500);
			EXEC [dbo].[USP_ReverseSOInvoiceAccountingEntry] @BillingInvoicingId = @SalesOrderShippingId, @MasterCompanyId = @MasterCompanyId, @UpdatedBy = @UpdatedBy,
				@ReversalMessage = @ReversalMessage OUTPUT, @JournalTypeCode = 'SOS';

			DECLARE @LoopId INT, @StockLineId BIGINT, @Qty DECIMAL(18, 6), @SalesOrderPartId BIGINT, @PartStatusId INT;

			SELECT ROW_NUMBER() OVER (ORDER BY [SalesOrderShippingItemId]) AS RowId, [StockLineId], [QtyShipped] INTO #History FROM #CancelItems;
			SELECT @LoopId = MAX(RowId) FROM #History;
			WHILE (@LoopId > 0)
			BEGIN
				SELECT @StockLineId = [StockLineId], @Qty = [QtyShipped] FROM #History WHERE RowId = @LoopId;
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StockLineId, @ModuleId = @SOModuleId, @ReferenceId = @SalesOrderId,
					@SubModuleId = @SOShippingModuleId, @SubRefferenceId = @SalesOrderShippingId, @ActionId = @CancelActionId, @Qty = @Qty, @UpdatedBy = @UpdatedBy;
				SET @LoopId = @LoopId - 1;
			END

			-- Part status / cost: still Shipped if another shipment exists, else Fulfilled or Open by reserved qty
			SELECT ROW_NUMBER() OVER (ORDER BY [SalesOrderPartId]) AS RowId, [SalesOrderPartId] INTO #Parts FROM (SELECT DISTINCT [SalesOrderPartId] FROM #CancelItems) P;
			SELECT @LoopId = MAX(RowId) FROM #Parts;
			WHILE (@LoopId > 0)
			BEGIN
				SELECT @SalesOrderPartId = [SalesOrderPartId] FROM #Parts WHERE RowId = @LoopId;

				SELECT @PartStatusId = CASE
					WHEN EXISTS (SELECT 1 FROM [dbo].[SalesOrderShippingItem] SOSI WITH(NOLOCK)
								INNER JOIN [dbo].[SalesOrderShipping] SOS WITH(NOLOCK) ON SOS.[SalesOrderShippingId] = SOSI.[SalesOrderShippingId]
								WHERE SOSI.[SalesOrderPartId] = @SalesOrderPartId AND SOSI.[IsDeleted] = 0 AND SOS.[IsDeleted] = 0 AND ISNULL(SOSI.[QtyShipped], 0) > 0) THEN @SOPartStatusShipped
					WHEN ISNULL((SELECT SUM(ISNULL([QtyReserved], 0)) FROM [dbo].[SalesOrderStocklineV1] WITH(NOLOCK) WHERE [SalesOrderPartId] = @SalesOrderPartId AND ISNULL([IsDeleted], 0) = 0), 0)
						>= ISNULL(SOP.[QtyOrder], 0) THEN @SOPartStatusFulfilled
					ELSE @SOPartStatusOpen END
				FROM [dbo].[SalesOrderPartV1] SOP WITH(NOLOCK) WHERE SOP.[SalesOrderPartId] = @SalesOrderPartId;

				EXEC [dbo].[SP_SaveSOPartStatusByPartId] @SalesOrderPartId = @SalesOrderPartId, @StatusId = @PartStatusId;
				EXEC [dbo].[USP_UpdateSOPartCostDetails] @SalesOrderId = @SalesOrderId, @SalesOrderPartId = @SalesOrderPartId, @UpdatedBy = @UpdatedBy,
					@MasterCompanyId = @MasterCompanyId, @IsUnreservedAction = 0, @IsFromShipping = 0, @isReserveOrUnreserve = 1;
				SET @LoopId = @LoopId - 1;
			END

			EXEC [dbo].[GenerateShipmentNumber] @SalesOrderId;
			EXEC [dbo].[USP_AddSOShippingStatusAudit] @SalesOrderShippingId = @SalesOrderShippingId, @UpdatedBy = @UpdatedBy;

		COMMIT TRANSACTION

		SELECT CAST(1 AS BIT) AS IsSuccess, 'Shipping canceled successfully.' AS [Message];
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_CancelSalesOrderShipping'
			, @ProcedureParameters VARCHAR(3000) = '@SalesOrderShippingId = ''' + CAST(ISNULL(@SalesOrderShippingId, '') AS VARCHAR(100))
												 + '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			@DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END
