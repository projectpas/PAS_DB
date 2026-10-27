/*************************************************************
 ** File:   [USP_SplitStocklineForSubComponent]
 ** Description: Splits @Qty from @StocklineId into a NEW stockline that is linked as a sub-component
                 of @ParentStocklineId (Add Sub Component on Stockline).
                   - new stockline : copy of the source (all columns), new Stockline / Control / Id number,
                                     Qty = OH = Available = @Qty, Reserved = 0 (same as Lot split),
                                     SubComponentParentStocklineId = @ParentStocklineId, SubComponentQty = @Qty
                   - source        : Quantity, QuantityOnHand and QuantityAvailable reduced by @Qty,
                                     a Memo line is added ("Split n Qty to STK: new stockline as Sub Component of STK: parent") so the user can review it
                 Number generation follows USP_CreateStockLine. Time life and management structure are copied.
                 Caller owns the transaction (called from USP_SaveStocklineSubComponent).
 ** Date:   10/15/2026
 ** Author:  Kishor Makwana

 ** RETURN VALUE: @NewStocklineId OUTPUT
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    10/15/2026  Kishor Makwana     [PN-18321] Created
    2    10/26/2026  Kishor Makwana     [PN-18321] Memo is added on the source stockline too (split to new stockline)
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_SplitStocklineForSubComponent]
	@StocklineId BIGINT,
	@Qty DECIMAL(18, 6),
	@ParentStocklineId BIGINT,
	@UpdatedBy VARCHAR(256),
	@NewStocklineId BIGINT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @MasterCompanyId INT, @ItemMasterId BIGINT, @ManufacturerId BIGINT, @ManagementStructureId BIGINT,
			@isSerialized BIT, @SourceStkNumber VARCHAR(100), @ParentStkNumber VARCHAR(100),
			@SourceLabel NVARCHAR(500), @ParentLabel NVARCHAR(500), @NewLabel NVARCHAR(500), -- stockline number + part number + control number (stockline number alone is repeated across part numbers)
			@StockLineNumber VARCHAR(100), @ControlNumber VARCHAR(100), @IdNumber VARCHAR(100),
			@StocklineCodeType INT = 0, @ControlNumberCodeType INT = 0, @IdNumberCodeType INT = 0,
			@StlCodePrefixId BIGINT = 0, @StlCodePrefix VARCHAR(50), @StlCodeSufix VARCHAR(50),
			@StlCNCodePrefixId BIGINT = 0, @StlCNCurrentNummber BIGINT = 0, @StlCNStartsFrom BIGINT = 0, @StlCNCodePrefix VARCHAR(50), @StlCNCodeSufix VARCHAR(50),
			@StlIdCodePrefixId BIGINT = 0, @StlIdCodePrefix VARCHAR(50), @StlIdCodeSufix VARCHAR(50),
			@currentNo BIGINT = 0, @cncurrentNo BIGINT = 0,
			@StockLineModuleID INT = 0, @MSModuleID INT = 2; -- 2 = Stockline (management structure module, same as TrasnferStocklineAndCreateBatch)

	SELECT @MasterCompanyId = [MasterCompanyId], @ItemMasterId = [ItemMasterId], @ManufacturerId = [ManufacturerId],
		   @ManagementStructureId = [ManagementStructureId], @isSerialized = ISNULL([isSerialized], 0), @SourceStkNumber = [StockLineNumber]
	FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [StockLineId] = @StocklineId;

	SELECT @ParentStkNumber = [StockLineNumber] FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [StockLineId] = @ParentStocklineId;
	SELECT @SourceLabel = ISNULL([StockLineNumber], '') + N' (PN: ' + ISNULL([PartNumber], '') + N', CN: ' + ISNULL([ControlNumber], '') + N')' FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [StockLineId] = @StocklineId;
	SELECT @ParentLabel = ISNULL([StockLineNumber], '') + N' (PN: ' + ISNULL([PartNumber], '') + N', CN: ' + ISNULL([ControlNumber], '') + N')' FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [StockLineId] = @ParentStocklineId;
	SELECT @StockLineModuleID = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'StockLine';

	/* ---------- Stockline / Control / Id number (same rules as USP_CreateStockLine) ---------- */
	SELECT @StocklineCodeType = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Stock Line';
	SELECT @ControlNumberCodeType = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Control Number';
	SELECT @IdNumberCodeType = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Id Number';

	SELECT @StlCodePrefixId = [CodePrefixId], @StlCodePrefix = [CodePrefix], @StlCodeSufix = [CodeSufix]
	FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE [CodeTypeId] = @StocklineCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
	SELECT @StlCNCodePrefixId = [CodePrefixId], @StlCNCurrentNummber = ISNULL([CurrentNummber], 0), @StlCNStartsFrom = ISNULL([StartsFrom], 0), @StlCNCodePrefix = [CodePrefix], @StlCNCodeSufix = [CodeSufix]
	FROM [dbo].[CodePrefixes] WITH (UPDLOCK) WHERE [CodeTypeId] = @ControlNumberCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
	SELECT @StlIdCodePrefixId = [CodePrefixId], @StlIdCodePrefix = [CodePrefix], @StlIdCodeSufix = [CodeSufix]
	FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE [CodeTypeId] = @IdNumberCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;

	IF (ISNULL(@StlCodePrefixId, 0) = 0 OR ISNULL(@StlCNCodePrefixId, 0) = 0 OR ISNULL(@StlIdCodePrefixId, 0) = 0)
	BEGIN
		RAISERROR ('Code Prefix not Available.!', 16, 1);
		RETURN;
	END

	-- PN + Manufacturer running number lives on ItemMaster.CurrentStlNo (GetPNManufacturerCombinationCreated reads the same value)
	SELECT @currentNo = ISNULL([CurrentStlNo], 0) FROM [dbo].[ItemMaster] WITH (UPDLOCK) WHERE [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId;
	SET @currentNo = CASE WHEN @currentNo > 0 THEN @currentNo + 1 ELSE 1 END;
	-- number = new counter value (no extra +1), so split stocklines do not skip a number
	SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@currentNo AS BIGINT), @StlCodePrefix, @StlCodeSufix));
	-- the counter can be behind the real data (normal create skips a number), so never reuse a number
	-- that already exists for this PN + Manufacturer
	WHILE EXISTS (SELECT 1 FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId
				  AND [MasterCompanyId] = @MasterCompanyId AND [StockLineNumber] = @StockLineNumber)
	BEGIN
		SET @currentNo = @currentNo + 1;
		SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@currentNo AS BIGINT), @StlCodePrefix, @StlCodeSufix));
	END

	SET @cncurrentNo = CASE WHEN @StlCNCurrentNummber > 0 THEN @StlCNCurrentNummber + 1 ELSE @StlCNStartsFrom + 1 END;
	SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@cncurrentNo, @StlCNCodePrefix, @StlCNCodeSufix));

	SET @IdNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(1, @StlIdCodePrefix, @StlIdCodeSufix));

	SET @NewLabel = ISNULL(@StockLineNumber, '') + N' (PN: ' + ISNULL((SELECT [PartNumber] FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [StockLineId] = @StocklineId), '') + N', CN: ' + ISNULL(@ControlNumber, '') + N')';

	UPDATE [dbo].[ItemMaster] SET [CurrentStlNo] = @currentNo, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
	WHERE [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId;
	UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @currentNo WHERE [CodeTypeId] = @StocklineCodeType AND [MasterCompanyId] = @MasterCompanyId;
	UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @cncurrentNo WHERE [CodeTypeId] = @ControlNumberCodeType AND [MasterCompanyId] = @MasterCompanyId;
	UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = 1 WHERE [CodeTypeId] = @IdNumberCodeType AND [MasterCompanyId] = @MasterCompanyId;

	/* ---------- copy the source row (every column, so new Stockline columns are never missed) ---------- */
	DECLARE @Cols NVARCHAR(MAX), @Sql NVARCHAR(MAX);
	SELECT @Cols = STRING_AGG(CAST(QUOTENAME(c.[name]) AS NVARCHAR(MAX)), N',') WITHIN GROUP (ORDER BY c.[column_id])
	FROM sys.columns c
	WHERE c.[object_id] = OBJECT_ID(N'dbo.Stockline') AND c.[is_identity] = 0 AND c.[is_computed] = 0 AND c.[system_type_id] <> 189;

	SET @Sql = N'INSERT INTO [dbo].[Stockline] (' + @Cols + N') SELECT ' + @Cols + N' FROM [dbo].[Stockline] WHERE [StockLineId] = @SourceId; SET @NewId = SCOPE_IDENTITY();';
	EXEC sp_executesql @Sql, N'@SourceId BIGINT, @NewId BIGINT OUTPUT', @SourceId = @StocklineId, @NewId = @NewStocklineId OUTPUT;

	UPDATE [dbo].[Stockline]
	SET [StockLineNumber] = @StockLineNumber,
		[ControlNumber] = @ControlNumber,
		[IdNumber] = @IdNumber,
		[Quantity] = @Qty,
		[QuantityOnHand] = @Qty,
		[QuantityReserved] = 0,
		[QuantityAvailable] = @Qty,
		[QuantityIssued] = 0,
		[QuantityTurnIn] = 0,
		[QuantityOnOrder] = 0,
		[QuantityRejected] = 0,
		[QtyReserved] = 0,
		[QtyIssued] = 0,
		[IsParent] = 1,
		[ParentId] = 0, -- same as other top-level stocklines
		[SubComponentParentStocklineId] = @ParentStocklineId,
		[SubComponentQty] = @Qty,
		[IsSubComponent] = 1,
		-- Source-document references are NOT carried to the new stockline, otherwise the new line
		-- would also show under that PO / RO / WO / SO / RMA / Lot (duplicate lines on those screens).
		-- Purchase Order
		[OrderDate] = NULL,
		[PurchaseOrderId] = NULL,
		[PurchaseOrderPartRecordId] = NULL,
		[PurchaseOrderNumber] = NULL,
		[PurchaseOrderUnitCost] = 0,
		[PurchaseOrderExtendedCost] = 0,
		[POOriginalCost] = NULL,
		[PoPartUnitCost] = NULL,
		[QuantityToReceive] = NULL,
		[ReceiverNumber] = NULL,
		[ReconciliationNumber] = NULL,
		[IsFromInitialPO] = 0,
		-- Repair Order
		[RepairOrderId] = NULL,
		[RepairOrderPartRecordId] = NULL,
		[RepairOrderNumber] = NULL,
		[RepairOrderUnitCost] = 0,
		[RepairOrderExtendedCost] = NULL,
		[ROOriginalCost] = NULL,
		-- Work Order / Sub Work Order
		[WorkOrderId] = NULL,
		[WorkOrderMaterialsId] = NULL,
		[WorkOrderMaterialsKitId] = NULL,
		[WorkOrderPartNoId] = NULL,
		[WorkOrderNumber] = NULL,
		[WorkOrderExtendedCost] = NULL,
		[SubWorkOrderId] = NULL,
		[SubWOPartNoId] = NULL,
		[SubWorkOrderNumber] = NULL,
		[SubWorkOrderMaterialsId] = NULL,
		[SubWorkOrderMaterialsKitId] = NULL,
		[IsTurnIn] = 0,
		[IsFinishGood] = 0,
		[RRQty] = NULL,
		-- Sales Order / Exchange / RMA / Lease
		[SalesOrderPartId] = NULL,
		[ExchangeSalesOrderId] = NULL,
		[IsCustomerRMA] = NULL,
		[RMADeatilsId] = NULL,
		[VendorRMAId] = NULL,
		[VendorRMADetailId] = NULL,
		[LeasePartId] = NULL,
		-- Lot
		[LotId] = NULL,
		[IsLotAssigned] = 0,
		[LotNumber] = NULL,
		[LotDescription] = NULL,
		[LOTQty] = NULL,
		[LOTQtyReserve] = NULL,
		[LotMainStocklineId] = NULL,
		[LotSourceId] = NULL,
		[TransferredFromLotId] = NULL,
		[TransferredFromLotNumber] = NULL,
		-- Aircraft installed part / accounting integration sync
		[AircraftInstalledPartDetailsId] = NULL,
		[AircraftSN] = NULL,
		[QuickBooksReferenceId] = NULL,
		[IsUpdated] = NULL,
		[LastSyncDate] = NULL,
		[Memo] = 'Split ' + CONVERT(VARCHAR(50), CAST(@Qty AS DECIMAL(18, 2))) + ' Qty from STK: ' + ISNULL(@SourceLabel, '') + ' as Sub Component of STK: ' + ISNULL(@ParentLabel, '') + ' Date: ' + FORMAT(GETUTCDATE(), 'dd/MM/yyyy'),
		[CreatedBy] = @UpdatedBy,
		[UpdatedBy] = @UpdatedBy,
		[CreatedDate] = GETUTCDATE(),
		[UpdatedDate] = GETUTCDATE()
	WHERE [StockLineId] = @NewStocklineId;

	/* ---------- source: move the qty out + memo (existing memo is kept, the new line is added below it) ---------- */
	DECLARE @SourceMemo NVARCHAR(MAX) = N'Split ' + CONVERT(VARCHAR(50), CAST(@Qty AS DECIMAL(18, 2))) + N' Qty to STK: ' + ISNULL(@NewLabel, '')
										+ N' as Sub Component of STK: ' + ISNULL(@ParentLabel, '') + N' Date: ' + FORMAT(GETUTCDATE(), 'dd/MM/yyyy');
	UPDATE [dbo].[Stockline]
	SET [Quantity] = ISNULL([Quantity], 0) - @Qty,
		[QuantityOnHand] = ISNULL([QuantityOnHand], 0) - @Qty,
		[QuantityAvailable] = ISNULL([QuantityAvailable], 0) - @Qty,
		[Memo] = CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL([Memo], N''))), N'') IS NULL THEN @SourceMemo ELSE [Memo] + CHAR(13) + CHAR(10) + @SourceMemo END,
		[UpdatedBy] = @UpdatedBy,
		[UpdatedDate] = GETUTCDATE()
	WHERE [StockLineId] = @StocklineId;

	/* ---------- related data for the new stockline ---------- */
	INSERT INTO [dbo].[TimeLife]
		([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair]
		,[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew]
		,[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
		,[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineId],[DetailsNotProvided]
		,[RepairOrderId],[RepairOrderPartRecordId])
	SELECT [CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair]
		,[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew]
		,[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE()
		,[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],@NewStocklineId,[DetailsNotProvided]
		,[RepairOrderId],[RepairOrderPartRecordId]
	FROM [dbo].[TimeLife] TL WITH (NOLOCK) WHERE TL.[StockLineId] = @StocklineId;

	EXEC [dbo].[USP_SaveSLMSDetails] @MSModuleID, @NewStocklineId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy;

	EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId;

	-- child (per unit) stocklines, same calls as TrasnferStocklineAndCreateBatch
	IF (@isSerialized = 0 AND @Qty > 1)
	BEGIN
		EXEC [dbo].[USP_CreateChildStockline] @NewStocklineId, @MasterCompanyId, @StockLineModuleID, @ParentStocklineId, 1, 1, 0, 0, 0, 0, 0;
	END
	ELSE
	BEGIN
		EXEC [dbo].[USP_CreateChildStockline] @NewStocklineId, @MasterCompanyId, @StockLineModuleID, @ParentStocklineId, 0, 0, 0, 0, 1, 0, 0;
	END
	EXEC [dbo].[USP_CreateChildStockline] @StocklineId, @MasterCompanyId, @StockLineModuleID, @ParentStocklineId, 0, 0, 0, 0, 0, 0, 0;

	-- 1 = Create (same as USP_CreateStockLine)
	EXEC [dbo].[USP_AddUpdateStocklineHistory] @NewStocklineId, @StockLineModuleID, @NewStocklineId, NULL, NULL, 1, @Qty, @UpdatedBy;
END