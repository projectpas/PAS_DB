/*************************************************************
 ** File:   [USP_SetAircraftSubComponentLink]
 ** Description: Keeps the Sub Component link of ONE Aircraft / Engine installed component in sync (Installed Components screen).
                 Parent = the stockline of the Aircraft (AircraftRegistryHeader.StockLineId) or of the Engine (EngineRegistryHeader.StockLineId).
                   - @OldStockLineId (row had another stockline before) : unlinked, only when it is linked to this parent
                   - @StockLineId (stockline selected on the row) :
                       Qty >= Qty On Hand (or serialized / qty not given) -> whole stockline is linked (no qty change)
                       Qty <  Qty On Hand                                -> USP_SplitStocklineForSubComponent creates a new stockline with Qty,
                                                                            @StockLineId is returned as the NEW stockline id
                       already linked to this parent                      -> only SubComponentQty is synced
                 When the Aircraft / Engine has no stockline yet (not received) nothing is linked here, the link is created when it is
                 received (usp_SaveTurnInAircraftMaterials -> USP_LinkAircraftInstalledSubComponents).
                 Caller owns the transaction; validation errors are raised with RAISERROR (caller CATCH rolls back).
 ** Date:   10/23/2026
 ** Author:  Kishor Makwana
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/OCT/2026  Kishor Makwana   [PN-18118] Created - Aircraft / Engine installed component = Sub Component of the aircraft / engine stockline
-- DECLARE @StlId BIGINT = 10; EXEC [dbo].[USP_SetAircraftSubComponentLink] @StockLineId = @StlId OUTPUT, @OldStockLineId = 0, @RegistryId = 1, @IsFromAircraft = 1, @Quantity = 1, @MasterCompanyId = 1, @UpdatedBy = 'admin'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_SetAircraftSubComponentLink]
	@StockLineId BIGINT OUTPUT,
	@OldStockLineId BIGINT = NULL,
	@RegistryId BIGINT,
	@IsFromAircraft BIT = 1,
	@Quantity DECIMAL(18, 6) = NULL,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ParentStocklineId BIGINT = NULL, @ModuleId BIGINT = 0,
			@LinkActionId INT = NULL, @UnLinkActionId INT = NULL, @SplitActionId INT = NULL,
			@CurQty DECIMAL(18, 6), @QtyOnHand DECIMAL(18, 6), @QtyAvailable DECIMAL(18, 6), @CurParent BIGINT,
			@IsSerialized BIT, @StockLineNumber VARCHAR(100), @LinkQty DECIMAL(18, 6), @SourceStocklineId BIGINT, @NewStocklineId BIGINT;

	IF (ISNULL(@IsFromAircraft, 0) = 1)
		SELECT @ParentStocklineId = [StockLineId] FROM [dbo].[AircraftRegistryHeader] WITH (NOLOCK)
		WHERE [AircraftRegistryId] = @RegistryId AND [MasterCompanyId] = @MasterCompanyId;
	ELSE
		SELECT @ParentStocklineId = [StockLineId] FROM [dbo].[EngineRegistryHeader] WITH (NOLOCK)
		WHERE [EngineRegistryId] = @RegistryId AND [MasterCompanyId] = @MasterCompanyId;

	-- aircraft / engine is not received yet (no stockline) -> nothing to link now
	IF (ISNULL(@ParentStocklineId, 0) = 0)
		RETURN;

	SELECT @ModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'StockLine';
	SELECT @LinkActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH (NOLOCK) WHERE [Type] = 'SubComponent-Link';
	SELECT @UnLinkActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH (NOLOCK) WHERE [Type] = 'SubComponent-UnLink';
	SELECT @SplitActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH (NOLOCK) WHERE [Type] = 'SubComponent-Split';

	/* ---------- UNLINK the stockline the row had before ---------- */
	IF (ISNULL(@OldStockLineId, 0) > 0 AND @OldStockLineId <> ISNULL(@StockLineId, 0))
	BEGIN
		SELECT @CurQty = ISNULL([SubComponentQty], 0) FROM [dbo].[Stockline] WITH (NOLOCK)
		WHERE [StockLineId] = @OldStockLineId AND [SubComponentParentStocklineId] = @ParentStocklineId;

		UPDATE [dbo].[Stockline]
		SET [SubComponentParentStocklineId] = NULL, [SubComponentQty] = NULL, [IsSubComponent] = 0,
			[UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
		WHERE [StockLineId] = @OldStockLineId AND [SubComponentParentStocklineId] = @ParentStocklineId;

		IF (@@ROWCOUNT > 0 AND @UnLinkActionId IS NOT NULL)
			EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @OldStockLineId, @ModuleId = @ModuleId, @ReferenceId = @ParentStocklineId,
				 @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @UnLinkActionId, @Qty = @CurQty, @UpdatedBy = @UpdatedBy;
	END

	/* ---------- LINK the selected stockline ---------- */
	IF (ISNULL(@StockLineId, 0) > 0)
	BEGIN
		SELECT @StockLineNumber = [StockLineNumber], @QtyOnHand = ISNULL([QuantityOnHand], 0), @QtyAvailable = ISNULL([QuantityAvailable], 0),
			   @CurParent = [SubComponentParentStocklineId], @IsSerialized = ISNULL([isSerialized], 0)
		FROM [dbo].[Stockline] WITH (UPDLOCK, ROWLOCK)
		WHERE [StockLineId] = @StockLineId AND [MasterCompanyId] = @MasterCompanyId;

		IF (@StockLineNumber IS NULL)
			RAISERROR('Stockline not found.', 16, 1);

		IF (@StockLineId = @ParentStocklineId)
			RAISERROR('The aircraft / engine stockline can not be installed as its own component.', 16, 1);

		IF (@CurParent IS NOT NULL AND @CurParent <> @ParentStocklineId)
			RAISERROR('Stockline %s is already a sub-component of another stockline.', 16, 1, @StockLineNumber);

		IF EXISTS (SELECT 1 FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [StockLineId] = @ParentStocklineId AND [SubComponentParentStocklineId] IS NOT NULL)
			RAISERROR('The aircraft / engine stockline is itself a sub-component, so components can not be added to it.', 16, 1);

		IF EXISTS (SELECT 1 FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [SubComponentParentStocklineId] = @StockLineId)
			RAISERROR('Stockline %s has its own sub-components, so it can not be installed as a component.', 16, 1, @StockLineNumber);

		-- qty not given / serialized -> whole stockline
		SET @LinkQty = CASE WHEN ISNULL(@Quantity, 0) <= 0 OR @IsSerialized = 1 THEN @QtyOnHand ELSE @Quantity END;

		IF (@CurParent = @ParentStocklineId)
		BEGIN
			-- already a component of this aircraft / engine : sync the qty only
			UPDATE [dbo].[Stockline]
			SET [SubComponentQty] = CASE WHEN @LinkQty > @QtyOnHand THEN @QtyOnHand ELSE @LinkQty END,
				[IsSubComponent] = 1, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [StockLineId] = @StockLineId AND ISNULL([SubComponentQty], -1) <> CASE WHEN @LinkQty > @QtyOnHand THEN @QtyOnHand ELSE @LinkQty END;
		END
		ELSE IF (@LinkQty >= @QtyOnHand)
		BEGIN
			-- whole stockline becomes the component
			UPDATE [dbo].[Stockline]
			SET [SubComponentParentStocklineId] = @ParentStocklineId, [SubComponentQty] = @QtyOnHand, [IsSubComponent] = 1,
				[UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [StockLineId] = @StockLineId;

			IF (@LinkActionId IS NOT NULL)
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StockLineId, @ModuleId = @ModuleId, @ReferenceId = @ParentStocklineId,
					 @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @LinkActionId, @Qty = @QtyOnHand, @UpdatedBy = @UpdatedBy;
		END
		ELSE
		BEGIN
			-- part of the stockline : split a new stockline and link it
			IF (@LinkQty > @QtyAvailable)
				RAISERROR('Stockline %s : Qty can not be more than Qty Available.', 16, 1, @StockLineNumber);

			SET @SourceStocklineId = @StockLineId;
			SET @NewStocklineId = NULL;
			EXEC [dbo].[USP_SplitStocklineForSubComponent] @StocklineId = @SourceStocklineId, @Qty = @LinkQty,
				 @ParentStocklineId = @ParentStocklineId, @UpdatedBy = @UpdatedBy, @NewStocklineId = @NewStocklineId OUTPUT;

			IF (@SplitActionId IS NOT NULL)
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @SourceStocklineId, @ModuleId = @ModuleId, @ReferenceId = @ParentStocklineId,
					 @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @SplitActionId, @Qty = @LinkQty, @UpdatedBy = @UpdatedBy;
			IF (@LinkActionId IS NOT NULL)
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @NewStocklineId, @ModuleId = @ModuleId, @ReferenceId = @ParentStocklineId,
					 @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @LinkActionId, @Qty = @LinkQty, @UpdatedBy = @UpdatedBy;

			-- the installed row now points to the new (linked) stockline
			SET @StockLineId = @NewStocklineId;
		END
	END
END