/*************************************************************
 ** File:   [USP_SaveLeasePickTicketItem]
 ** Description: Creates / edits / confirms ONE Lease Pick Ticket line. Mirrors
 **              dbo.sp_savePickTicketItemInterfaceForRO (Repair Order) - Leasing has no part
 **              approval step, so RO (which only gates on QuantityReserved) is the right model,
 **              not Sales Order (which additionally requires SalesOrderApproval).
 **
 **              Three modes, picked by the parameters:
 **                @LeasePickTicketId = 0                     -> new pick transaction
 **                @LeasePickTicketId > 0 AND @IsConfirmed=0  -> edit an unconfirmed pick qty
 **                @LeasePickTicketId > 0 AND @IsConfirmed=1  -> confirm the pick
 **
 **              Validation (Pick Quantity):
 **                - must be greater than zero
 **                - cannot exceed what is still outstanding on the reservation, i.e.
 **                  LeaseStockline.QtyReserved minus everything already picked on that line
 **                - cannot exceed the available quantity. Reserving already moved the qty out
 **                  of Stockline.QuantityAvailable (see USP_ReserveUnReserveLeaseStockLine),
 **                  so the ceiling is QuantityAvailable PLUS this lease line's own
 **                  LeaseStockline.QtyReserved - comparing against QuantityAvailable alone
 **                  would reject every pick. Deliberately NOT Stockline.QuantityReserved,
 **                  which is shared across modules and can carry historic bad values.
 **
 **              Picking does not move stock quantities, exactly like the Sales Order pick
 **              ticket: Reserve/UnReserve owns Stockline.QuantityAvailable/QuantityReserved.
 **
 **              Every line of one pick transaction shares a single Pick Ticket number, which
 **              the caller takes once from USP_GetNextLeasePickTicketNumber.
 **
 **              Confirmation follows RO: LeaseSetting.EnforcePickTicketConfirmation drives it.
 **              When it is 0/NULL (the default, and RO's own norm) a new pick ticket is created
 **              already confirmed against the picker, so there is no extra step to clear. Set it
 **              to 1 on the Component Lease Setting screen to require an explicit Confirm.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    16/09/2026     Bhargav Saliya          [PN-17931] Created - Leasing Pick Ticket

exec USP_SaveLeasePickTicketItem @LeasePickTicketId=0,@LeasePickTicketNumber='PT(LSE)-000001',@LeaseHeaderId=1,@LeaseStocklineId=1,@QtyPicked=1,@PickedById=55,@MasterCompanyId=1,@CreatedBy='Jim Roberts',@UpdatedBy='Jim Roberts'
************************************************************************/
CREATE PROCEDURE [dbo].[USP_SaveLeasePickTicketItem]
	@LeasePickTicketId BIGINT = 0,
	@LeasePickTicketNumber VARCHAR(50) = '',
	@LeaseHeaderId BIGINT = 0,
	@LeaseStocklineId BIGINT = 0,
	@QtyPicked DECIMAL(18, 6) = 0,
	@PickedById BIGINT = 0,
	@ConfirmedById BIGINT = 0,
	@IsConfirmed BIT = 0,
	@Memo NVARCHAR(MAX) = NULL,
	@MasterCompanyId INT = 0,
	@CreatedBy VARCHAR(256) = '',
	@UpdatedBy VARCHAR(256) = ''
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

		DECLARE @StockLineId BIGINT, @ItemMasterId BIGINT, @ConditionId BIGINT;
		DECLARE @QtyReserved DECIMAL(18, 6) = 0, @AlreadyPicked DECIMAL(18, 6) = 0;
		DECLARE @Pickable DECIMAL(18, 6) = 0, @AvailableQty DECIMAL(18, 6) = 0;
		DECLARE @QtyRemaining DECIMAL(18, 6) = 0, @Status INT = 0;
		DECLARE @EnforcePickTicketConfirmation BIT = 0;

		-- ------------------------------------------------------------------
		-- Confirm an existing pick ticket
		-- ------------------------------------------------------------------
		IF (@LeasePickTicketId > 0 AND @IsConfirmed = 1)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM [dbo].[LeasePickTicket] WITH (NOLOCK)
						   WHERE [LeasePickTicketId] = @LeasePickTicketId AND [IsDeleted] = 0)
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 0 AS [Status], 'Pick ticket not found.' AS [Message], @LeasePickTicketId AS LeasePickTicketId, '' AS LeasePickTicketNumber;
				RETURN;
			END

			UPDATE [dbo].[LeasePickTicket]
			SET [ConfirmedById] = @ConfirmedById,
				[IsConfirmed]   = 1,
				[ConfirmedDate] = GETUTCDATE(),
				[UpdatedBy]     = @UpdatedBy,
				[UpdatedDate]   = GETUTCDATE()
			WHERE [LeasePickTicketId] = @LeasePickTicketId;

			COMMIT TRANSACTION;
			SELECT 1 AS [Status], 'Success' AS [Message], @LeasePickTicketId AS LeasePickTicketId,
				   (SELECT [LeasePickTicketNumber] FROM [dbo].[LeasePickTicket] WITH (NOLOCK) WHERE [LeasePickTicketId] = @LeasePickTicketId) AS LeasePickTicketNumber;
			RETURN;
		END

		-- ------------------------------------------------------------------
		-- Create / edit - both need the reservation figures of the lease stockline
		-- ------------------------------------------------------------------
		IF (@LeasePickTicketId > 0 AND ISNULL(@LeaseStocklineId, 0) = 0)
		BEGIN
			SELECT @LeaseStocklineId = [LeaseStocklineId], @LeaseHeaderId = [LeaseHeaderId]
			FROM [dbo].[LeasePickTicket] WITH (NOLOCK)
			WHERE [LeasePickTicketId] = @LeasePickTicketId;
		END

		SELECT @StockLineId  = LSL.[StockLineId],
			   @ItemMasterId = LSL.[ItemMasterId],
			   @ConditionId  = LSL.[ConditionId],
			   @QtyReserved  = CAST(ISNULL(LSL.[QtyReserved], 0) AS DECIMAL(18, 6))
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		WHERE LSL.[LeaseStocklineId] = @LeaseStocklineId
		  AND LSL.[LeaseHeaderId]    = @LeaseHeaderId
		  AND LSL.[IsDeleted]        = 0;

		IF (@StockLineId IS NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 0 AS [Status], 'Lease stock line not found.' AS [Message], 0 AS LeasePickTicketId, '' AS LeasePickTicketNumber;
			RETURN;
		END

		-- Everything already picked on this line, ignoring the row being edited.
		SELECT @AlreadyPicked = ISNULL(SUM(ISNULL([QtyPicked], 0)), 0)
		FROM [dbo].[LeasePickTicket] WITH (NOLOCK)
		WHERE [LeaseStocklineId]  = @LeaseStocklineId
		  AND [IsDeleted]         = 0
		  AND [LeasePickTicketId] <> @LeasePickTicketId;

		SET @Pickable = @QtyReserved - @AlreadyPicked;

		SELECT @AvailableQty = CAST(ISNULL([QuantityAvailable], 0) AS DECIMAL(18, 6)) + @QtyReserved
		FROM [dbo].[Stockline] WITH (NOLOCK)
		WHERE [StockLineId] = @StockLineId;

		IF (ISNULL(@QtyPicked, 0) <= 0)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 0 AS [Status], 'Pick quantity must be greater than zero.' AS [Message], 0 AS LeasePickTicketId, '' AS LeasePickTicketNumber;
			RETURN;
		END

		IF (@QtyPicked > @Pickable)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 0 AS [Status], 'Pick quantity cannot exceed the reserved quantity.' AS [Message], 0 AS LeasePickTicketId, '' AS LeasePickTicketNumber;
			RETURN;
		END

		IF (@QtyPicked > ISNULL(@AvailableQty, 0))
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 0 AS [Status], 'Pick quantity cannot exceed the available quantity.' AS [Message], 0 AS LeasePickTicketId, '' AS LeasePickTicketNumber;
			RETURN;
		END

		SET @QtyRemaining = @Pickable - @QtyPicked;
		SET @Status = CASE WHEN @QtyRemaining <= 0 THEN 2 ELSE 1 END;  -- 2 = Fulfilled, 1 = Fulfilling

		IF (@LeasePickTicketId = 0)
		BEGIN
			INSERT INTO [dbo].[LeasePickTicket]
			(
				[LeasePickTicketNumber], [LeaseHeaderId], [LeaseStocklineId], [StockLineId], [ItemMasterId], [ConditionId],
				[QtyReserved], [QtyPicked], [QtyRemaining], [Status], [PickedById], [PickedDate],
				[ConfirmedById], [IsConfirmed], [Memo], [MasterCompanyId],
				[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
			)
			VALUES
			(
				@LeasePickTicketNumber, @LeaseHeaderId, @LeaseStocklineId, @StockLineId, @ItemMasterId, @ConditionId,
				@QtyReserved, @QtyPicked, @QtyRemaining, @Status, @PickedById, GETUTCDATE(),
				NULLIF(@ConfirmedById, 0), 0, @Memo, @MasterCompanyId,
				@CreatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0
			);

			SET @LeasePickTicketId = SCOPE_IDENTITY();

			-- RO behaviour: unless the company explicitly enforces confirmation, the pick ticket is
			-- confirmed on the spot against whoever picked it, so there is no extra step to clear.
			SELECT @EnforcePickTicketConfirmation = ISNULL([EnforcePickTicketConfirmation], 0)
			FROM [dbo].[LeaseSetting] WITH (NOLOCK)
			WHERE [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0;

			IF (ISNULL(@EnforcePickTicketConfirmation, 0) = 0)
			BEGIN
				UPDATE [dbo].[LeasePickTicket]
				SET [ConfirmedById] = @PickedById,
					[IsConfirmed]   = 1,
					[ConfirmedDate] = GETUTCDATE()
				WHERE [LeasePickTicketId] = @LeasePickTicketId;
			END
		END
		ELSE
		BEGIN
			UPDATE [dbo].[LeasePickTicket]
			SET [QtyPicked]    = @QtyPicked,
				[QtyReserved]  = @QtyReserved,
				[QtyRemaining] = @QtyRemaining,
				[Status]       = @Status,
				[Memo]         = ISNULL(@Memo, [Memo]),
				[UpdatedBy]    = @UpdatedBy,
				[UpdatedDate]  = GETUTCDATE()
			WHERE [LeasePickTicketId] = @LeasePickTicketId;

			SELECT @LeasePickTicketNumber = [LeasePickTicketNumber]
			FROM [dbo].[LeasePickTicket] WITH (NOLOCK)
			WHERE [LeasePickTicketId] = @LeasePickTicketId;
		END

		-- Each row keeps the outstanding qty AS OF ITS OWN PICK (matching the Sales Order pick
		-- ticket), so the history and the printed document stay a faithful record. The live
		-- outstanding figure for the grid is recomputed by USP_GetLeasePickTicketApproveList.

		COMMIT TRANSACTION;

		SELECT 1 AS [Status], 'Success' AS [Message], @LeasePickTicketId AS LeasePickTicketId, @LeasePickTicketNumber AS LeasePickTicketNumber;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_SaveLeasePickTicketItem]',
			@ProcedureParameters VARCHAR(3000) = '@LeasePickTicketId = ''' + CAST(ISNULL(@LeasePickTicketId, 0) AS VARCHAR(100))
											   + ''', @LeaseStocklineId = ''' + CAST(ISNULL(@LeaseStocklineId, 0) AS VARCHAR(100)),
			@ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName,
							@AdhocComments = @AdhocComments,
							@ProcedureParameters = @ProcedureParameters,
							@ApplicationName = @ApplicationName,
							@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END
