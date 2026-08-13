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

		DECLARE @StockLineId BIGINT, @LeasePartId BIGINT, @CurrentQtyOrder INT, @CurrentQtyReserved INT;

		SELECT @StockLineId = StockLineId, @LeasePartId = LeasePartId, @CurrentQtyOrder = QtyOrder, @CurrentQtyReserved = QtyReserved
		FROM [dbo].[LeaseStockline] WITH (UPDLOCK, ROWLOCK)
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