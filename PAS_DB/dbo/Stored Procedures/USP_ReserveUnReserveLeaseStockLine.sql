/*************************************************************
 ** File:   [USP_ReserveUnReserveLeaseStockLine]
 ** Description: Simplified 2-state Reserve/UnReserve for a single Lease Stock Line row.
 **              Reserve moves qty from QtyOrder into QtyReserved; UnReserve moves it back.
 **              Also keeps the shared dbo.Stockline.QuantityAvailable/QuantityReserved in
 **              sync so other modules reserving against the same inventory stay correct.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    10/08/2026     Amit Ghediya            Created

exec USP_ReserveUnReserveLeaseStockLine @LeaseStocklineId=1,@Qty=1,@IsReserve=1,@UpdatedBy=''
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_ReserveUnReserveLeaseStockLine]
	@LeaseStocklineId BIGINT,
	@Qty INT,
	@IsReserve BIT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

		DECLARE @StockLineId BIGINT, @LeasePartId BIGINT, @CurrentQtyOrder INT, 
				@CurrentQtyReserved INT,@ModuleId BIGINT = 0,@ActionId INT = 0,
				@LeaseHeaderId BIGINT = 0;

		SELECT @ModuleId = [ModuleId] FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'Leasing';

		SELECT @StockLineId = LS.StockLineId, @LeasePartId = LS.LeasePartId, 
			   @CurrentQtyOrder = LS.QtyOrder, @CurrentQtyReserved = LS.QtyReserved,
			   @LeaseHeaderId = LP.LeaseHeaderId
		FROM [dbo].[LeaseStockline] LS WITH (NOLOCK)
		JOIN [dbo].[LeasePart] LP WITH (NOLOCK) ON LP.LeasePartId = LS.LeasePartId
		WHERE LeaseStocklineId = @LeaseStocklineId;

		IF (@StockLineId IS NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 0 AS Status, 'Lease stock line not found.' AS Message;
			RETURN;
		END

		IF (@IsReserve = 1)
		BEGIN
			IF (@Qty > @CurrentQtyOrder)
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 0 AS Status, 'Qty to reserve exceeds the available order quantity.' AS Message;
				RETURN;
			END

			UPDATE [dbo].[LeaseStockline]
			SET QtyOrder = QtyOrder - @Qty,
				QtyReserved = QtyReserved + @Qty,
				UpdatedBy = @UpdatedBy,
				UpdatedDate = GETUTCDATE()
			WHERE LeaseStocklineId = @LeaseStocklineId;

			UPDATE [dbo].[Stockline]
			SET QuantityAvailable = QuantityAvailable - @Qty,
				QuantityReserved = QuantityReserved + @Qty
			WHERE StockLineId = @StockLineId;

			UPDATE [dbo].[LeasePart]
			SET QtyReserved = QtyReserved + @Qty,
				UpdatedBy = @UpdatedBy,
				UpdatedDate = GETUTCDATE()
			WHERE LeasePartId = @LeasePartId;

			--FOR STOCK LINE HISTORY	
			SET @ActionId = 2; --For Reserve
			EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @LeaseHeaderId, @SubModuleId = 0, @SubRefferenceId = @ModuleId, @ActionId = @ActionId, @Qty = @Qty, @UpdatedBy = @UpdatedBy;
		END
		ELSE
		BEGIN
			IF (@Qty > @CurrentQtyReserved)
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 0 AS Status, 'Qty to unreserve exceeds the currently reserved quantity.' AS Message;
				RETURN;
			END

			UPDATE [dbo].[LeaseStockline]
			SET QtyReserved = QtyReserved - @Qty,
				QtyOrder = QtyOrder + @Qty,
				UpdatedBy = @UpdatedBy,
				UpdatedDate = GETUTCDATE()
			WHERE LeaseStocklineId = @LeaseStocklineId;

			UPDATE [dbo].[Stockline]
			SET QuantityAvailable = QuantityAvailable + @Qty,
				QuantityReserved = QuantityReserved - @Qty
			WHERE StockLineId = @StockLineId;

			UPDATE [dbo].[LeasePart]
			SET QtyReserved = QtyReserved - @Qty,
				UpdatedBy = @UpdatedBy,
				UpdatedDate = GETUTCDATE()
			WHERE LeasePartId = @LeasePartId;

			--FOR STOCK LINE HISTORY
			EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @LeaseHeaderId, @SubModuleId = 0, @SubRefferenceId = @ModuleId, @ActionId = 3, @Qty = @Qty, @UpdatedBy = @UpdatedBy;
		END

		COMMIT TRANSACTION;
		SELECT 1 AS Status, 'Success' AS Message;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_ReserveUnReserveLeaseStockLine]',
            @ProcedureParameters varchar(3000) = '@LeaseStocklineId = ''' + CAST(ISNULL(@LeaseStocklineId, 0) AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
	END CATCH
END