
/*************************************************************
 ** File:   [USP_CreateSubComponentStocklinesForReceiving]
 ** Description: PO Receiving - creates the Sub Component Stocklines of the received main stocklines.
                 Item Master > Sub Assembly > Sub Component rows (dbo.SubComponent) with "Auto Create Stockline" = Yes
                 are used. For every received main stockline (@StockLineIds) and every such sub component:
                   - one linked stockline of the Sub Component part number (SubComponentParentStocklineId = main stockline,
                     SubComponentQty = Qty, IsSubComponent = 1) is created
                   - Qty        = sub component Qty x received qty of the main stockline
                                  (Bearing Qty 2, main stockline Qty 2 -> Bearing stockline Qty 4)
                   - Condition  = sub component Condition, blank -> Condition of the main stockline
                   - serialized sub component part numbers get one stockline (Qty 1) per unit, serial number is entered later
                   - site / warehouse / location / shelf / bin / management structure / vendor are taken from the main stockline,
                     part data (PN, description, manufacturer, GL, UOM, PMA / DER / OEM ...) from the sub component Item Master
                   - cost is 0 and no accounting batch is posted (the cost belongs to the main part), PO / RO / WO / Lot
                     references are not copied (same as USP_SplitStocklineForSubComponent)
                 Stockline / Control / Id number generation follows USP_SplitStocklineForSubComponent.
                 Only Stock stocklines are used (Non-Stock and Asset stocklines are skipped). A main stockline that already has a
                 linked stockline for the same sub component part number + condition is skipped (safe to call again).
                 Caller owns the transaction (called from USP_CreateStocklineForReceivingPO). No result set is returned.
 ** Date:   06-NOV-2026
 ** Author:  Kishor Makwana

 ** RETURN VALUE: none
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    06-NOV-2026  Kishor Makwana    [PN-18498] Created

-- EXEC [dbo].[USP_CreateSubComponentStocklinesForReceiving] @StockLineIds = '101,102', @MasterCompanyId = 1, @UpdatedBy = 'admin'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateSubComponentStocklinesForReceiving]
	@StockLineIds VARCHAR(MAX),
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;

	IF (ISNULL(@StockLineIds, '') = '')
		RETURN;

	DECLARE @StocklineCodeType INT = 0, @ControlNumberCodeType INT = 0, @IdNumberCodeType INT = 0,
			@StlCodePrefixId BIGINT = 0, @StlCodePrefix VARCHAR(50), @StlCodeSufix VARCHAR(50),
			@StlCNCodePrefixId BIGINT = 0, @StlCNCurrentNummber BIGINT = 0, @StlCNStartsFrom BIGINT = 0, @StlCNCodePrefix VARCHAR(50), @StlCNCodeSufix VARCHAR(50),
			@StlIdCodePrefixId BIGINT = 0, @StlIdCodePrefix VARCHAR(50), @StlIdCodeSufix VARCHAR(50),
			@MSModuleID INT = 2, -- 2 = Stockline (management structure module, same as USP_SplitStocklineForSubComponent)
			@StockLineModuleId BIGINT = 0, @LinkActionId INT = NULL;

	/* ---------- main stocklines x sub components (same sub component part + resolved condition is summed) ---------- */
	IF OBJECT_ID(N'tempdb..#SubCompWork') IS NOT NULL DROP TABLE #SubCompWork;
	CREATE TABLE #SubCompWork
	(
		[ID] INT IDENTITY(1, 1) NOT NULL,
		[MainStockLineId] BIGINT NOT NULL,
		[SubItemMasterId] BIGINT NOT NULL,
		[ConditionId] BIGINT NOT NULL,
		[Qty] DECIMAL(18, 6) NOT NULL
	);

	INSERT INTO #SubCompWork ([MainStockLineId], [SubItemMasterId], [ConditionId], [Qty])
	SELECT S.[StockLineId],
		   SC.[MappingItemMasterId],
		   ISNULL(SC.[ConditionId], S.[ConditionId]),
		   SUM(ISNULL(SC.[Quantity], 0) * ISNULL(S.[QuantityOnHand], ISNULL(S.[Quantity], 0)))
	FROM [dbo].[Stockline] S WITH (NOLOCK)
	INNER JOIN [dbo].[SubComponent] SC WITH (NOLOCK) ON SC.[ItemMasterId] = S.[ItemMasterId]
		AND SC.[MasterCompanyId] = @MasterCompanyId AND ISNULL(SC.[IsActive], 0) = 1 AND ISNULL(SC.[IsDeleted], 0) = 0
		AND ISNULL(SC.[IsAutoCreateStockline], 0) = 1 AND ISNULL(SC.[Quantity], 0) > 0
		AND SC.[MappingItemMasterId] <> S.[ItemMasterId]
	INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = SC.[MappingItemMasterId]
		AND ISNULL(IM.[IsActive], 1) = 1 AND ISNULL(IM.[IsDeleted], 0) = 0
	WHERE S.[StockLineId] IN (SELECT TRY_CAST(LTRIM(RTRIM([value])) AS BIGINT) FROM STRING_SPLIT(@StockLineIds, ','))
	  AND S.[MasterCompanyId] = @MasterCompanyId
	  AND ISNULL(S.[isDeleted], 0) = 0
	  AND ISNULL(S.[IsNonStock], 0) = 0
	  AND ISNULL(S.[IsAsset], 0) = 0
	  AND S.[SubComponentParentStocklineId] IS NULL -- a sub component stockline never has its own sub components
	  AND ISNULL(S.[QuantityOnHand], ISNULL(S.[Quantity], 0)) > 0
	GROUP BY S.[StockLineId], SC.[MappingItemMasterId], ISNULL(SC.[ConditionId], S.[ConditionId]);

	-- already created / linked for this main stockline (re-run safe)
	DELETE W FROM #SubCompWork W
	WHERE EXISTS (SELECT 1 FROM [dbo].[Stockline] C WITH (NOLOCK)
				  WHERE C.[SubComponentParentStocklineId] = W.[MainStockLineId] AND C.[ItemMasterId] = W.[SubItemMasterId]
					AND C.[ConditionId] = W.[ConditionId] AND ISNULL(C.[isDeleted], 0) = 0);

	IF NOT EXISTS (SELECT 1 FROM #SubCompWork)
		RETURN;

	/* ---------- code prefixes / history action ---------- */
	SELECT @StocklineCodeType = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Stock Line';
	SELECT @ControlNumberCodeType = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Control Number';
	SELECT @IdNumberCodeType = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Id Number';

	SELECT @StlCodePrefixId = [CodePrefixId], @StlCodePrefix = [CodePrefix], @StlCodeSufix = [CodeSufix]
	FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE [CodeTypeId] = @StocklineCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
	SELECT @StlIdCodePrefixId = [CodePrefixId], @StlIdCodePrefix = [CodePrefix], @StlIdCodeSufix = [CodeSufix]
	FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE [CodeTypeId] = @IdNumberCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
	SELECT @StlCNCodePrefixId = [CodePrefixId] FROM [dbo].[CodePrefixes] WITH (NOLOCK)
	WHERE [CodeTypeId] = @ControlNumberCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;

	IF (ISNULL(@StlCodePrefixId, 0) = 0 OR ISNULL(@StlCNCodePrefixId, 0) = 0 OR ISNULL(@StlIdCodePrefixId, 0) = 0)
	BEGIN
		RAISERROR ('Code Prefix not Available.!', 16, 1);
		RETURN;
	END

	SELECT @StockLineModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'StockLine';
	SELECT @LinkActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH (NOLOCK) WHERE [Type] = 'SubComponent-Link';

	-- every column of the main stockline is copied, then the sub component values are set (new Stockline columns are never missed)
	DECLARE @Cols NVARCHAR(MAX), @Sql NVARCHAR(MAX);
	SELECT @Cols = STRING_AGG(CAST(QUOTENAME(c.[name]) AS NVARCHAR(MAX)), N',') WITHIN GROUP (ORDER BY c.[column_id])
	FROM sys.columns c
	WHERE c.[object_id] = OBJECT_ID(N'dbo.Stockline') AND c.[is_identity] = 0 AND c.[is_computed] = 0 AND c.[system_type_id] <> 189;
	SET @Sql = N'INSERT INTO [dbo].[Stockline] (' + @Cols + N') SELECT ' + @Cols + N' FROM [dbo].[Stockline] WHERE [StockLineId] = @SourceId; SET @NewId = SCOPE_IDENTITY();';

	DECLARE @WorkId INT, @MainStockLineId BIGINT, @SubItemMasterId BIGINT, @ConditionId BIGINT, @WorkQty DECIMAL(18, 6),
			@ManufacturerId BIGINT, @ItemMasterIsSerialized BIT, @UnitCount INT, @UnitNo INT, @RowQty DECIMAL(18, 6),
			@MainManagementStructureId BIGINT, @MainLabel NVARCHAR(500),
			@currentNo BIGINT, @cncurrentNo BIGINT, @StlCNCurrent BIGINT, @StlCNStarts BIGINT,
			@StockLineNumber VARCHAR(100), @ControlNumber VARCHAR(100), @IdNumber VARCHAR(100), @NewStocklineId BIGINT;

	DECLARE WorkCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT [ID], [MainStockLineId], [SubItemMasterId], [ConditionId], [Qty] FROM #SubCompWork ORDER BY [ID];

	OPEN WorkCursor;
	FETCH NEXT FROM WorkCursor INTO @WorkId, @MainStockLineId, @SubItemMasterId, @ConditionId, @WorkQty;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @ManufacturerId = IM.[ManufacturerId], @ItemMasterIsSerialized = ISNULL(IM.[isSerialized], 0)
		FROM [dbo].[ItemMaster] IM WITH (NOLOCK) WHERE IM.[ItemMasterId] = @SubItemMasterId;

		SELECT @MainManagementStructureId = S.[ManagementStructureId],
			   @MainLabel = ISNULL(S.[StockLineNumber], '') + N' (PN: ' + ISNULL(S.[PartNumber], '') + N', CN: ' + ISNULL(S.[ControlNumber], '') + N')'
		FROM [dbo].[Stockline] S WITH (NOLOCK) WHERE S.[StockLineId] = @MainStockLineId;

		-- serialized part number : one stockline (Qty 1) per unit, otherwise one stockline for the whole qty
		SET @UnitCount = CASE WHEN @ItemMasterIsSerialized = 1 THEN CAST(CEILING(@WorkQty) AS INT) ELSE 1 END;
		SET @UnitNo = 1;

		WHILE (@UnitNo <= @UnitCount)
		BEGIN
			SET @RowQty = CASE WHEN @ItemMasterIsSerialized = 1 THEN 1 ELSE @WorkQty END;
			SET @NewStocklineId = NULL;

			/* ----- Stockline number : PN + Manufacturer running number lives on ItemMaster.CurrentStlNo ----- */
			SELECT @currentNo = ISNULL([CurrentStlNo], 0) FROM [dbo].[ItemMaster] WITH (UPDLOCK)
			WHERE [ItemMasterId] = @SubItemMasterId AND [ManufacturerId] = @ManufacturerId;
			SET @currentNo = CASE WHEN @currentNo > 0 THEN @currentNo + 1 ELSE 1 END;
			SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@currentNo AS BIGINT), @StlCodePrefix, @StlCodeSufix));
			-- never reuse a number that already exists for this PN + Manufacturer
			WHILE EXISTS (SELECT 1 FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [ItemMasterId] = @SubItemMasterId AND [ManufacturerId] = @ManufacturerId
						  AND [MasterCompanyId] = @MasterCompanyId AND [StockLineNumber] = @StockLineNumber)
			BEGIN
				SET @currentNo = @currentNo + 1;
				SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@currentNo AS BIGINT), @StlCodePrefix, @StlCodeSufix));
			END

			/* ----- Control number / Id number ----- */
			SELECT @StlCNCurrent = ISNULL([CurrentNummber], 0), @StlCNStarts = ISNULL([StartsFrom], 0), @StlCNCodePrefix = [CodePrefix], @StlCNCodeSufix = [CodeSufix]
			FROM [dbo].[CodePrefixes] WITH (UPDLOCK) WHERE [CodePrefixId] = @StlCNCodePrefixId;
			SET @cncurrentNo = CASE WHEN @StlCNCurrent > 0 THEN @StlCNCurrent + 1 ELSE @StlCNStarts + 1 END;
			SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@cncurrentNo, @StlCNCodePrefix, @StlCNCodeSufix));
			SET @IdNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(1, @StlIdCodePrefix, @StlIdCodeSufix));

			UPDATE [dbo].[ItemMaster] SET [CurrentStlNo] = @currentNo, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [ItemMasterId] = @SubItemMasterId AND [ManufacturerId] = @ManufacturerId;
			UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @currentNo WHERE [CodeTypeId] = @StocklineCodeType AND [MasterCompanyId] = @MasterCompanyId;
			UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @cncurrentNo WHERE [CodePrefixId] = @StlCNCodePrefixId;
			UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = 1 WHERE [CodeTypeId] = @IdNumberCodeType AND [MasterCompanyId] = @MasterCompanyId;

			/* ----- copy the main stockline row, then set the sub component values ----- */
			EXEC sp_executesql @Sql, N'@SourceId BIGINT, @NewId BIGINT OUTPUT', @SourceId = @MainStockLineId, @NewId = @NewStocklineId OUTPUT;

			UPDATE SL
			SET SL.[PartNumber] = IM.[partnumber],
				SL.[PNDescription] = IM.[PartDescription],
				SL.[ItemMasterId] = IM.[ItemMasterId],
				SL.[ManufacturerId] = IM.[ManufacturerId],
				SL.[ConditionId] = @ConditionId,
				SL.[StockLineNumber] = @StockLineNumber,
				SL.[ControlNumber] = @ControlNumber,
				SL.[IdNumber] = @IdNumber,
				SL.[StocklineMatchKey] = NULL,
				SL.[SerialNumber] = NULL,
				SL.[isSerialized] = ISNULL(IM.[isSerialized], 0),
				SL.[GLAccountId] = IM.[GLAccountId],
				SL.[IsHazardousMaterial] = IM.[IsHazardousMaterial],
				SL.[IsPMA] = IM.[IsPma],
				SL.[IsDER] = IM.[IsDER],
				SL.[IsOemPNId] = IM.[IsOemPNId],
				SL.[PurchaseUnitOfMeasureId] = IM.[PurchaseUnitOfMeasureId],
				SL.[StockUnitOfMeasureId] = IM.[StockUnitOfMeasureId],
				SL.[ConsumeUnitOfMeasureId] = IM.[ConsumeUnitOfMeasureId],
				SL.[IsStkTimeLife] = ISNULL(IM.[isTimeLife], 0),
				-- main part details that do not belong to the sub component part
				SL.[ShelfLife] = NULL,
				SL.[ShelfLifeExpirationDate] = NULL,
				SL.[ExpirationDate] = NULL,
				SL.[ManufacturerLotNumber] = NULL,
				SL.[ManufacturingDate] = NULL,
				SL.[ManufacturingBatchNumber] = NULL,
				SL.[PartCertificationNumber] = NULL,
				SL.[TimeLifeCyclesId] = NULL,
				SL.[TimeLifeDetailsNotProvided] = 0,
				SL.[AircraftTailNumber] = NULL,
				SL.[EngineSerialNumber] = NULL,
				SL.[NHAItemMasterId] = NULL,
				SL.[TLAItemMasterId] = NULL,
				SL.[AssetId] = NULL,
				SL.[IsAsset] = 0,
				SL.[IsNonStock] = 0,
				SL.[IntegrationPortal] = NULL,
				-- quantity (same as USP_SplitStocklineForSubComponent)
				SL.[Quantity] = @RowQty,
				SL.[QuantityOnHand] = @RowQty,
				SL.[QuantityReserved] = 0,
				SL.[QuantityAvailable] = @RowQty,
				SL.[QuantityIssued] = 0,
				SL.[QuantityTurnIn] = 0,
				SL.[QuantityOnOrder] = 0,
				SL.[QuantityRejected] = 0,
				SL.[QtyReserved] = 0,
				SL.[QtyIssued] = 0,
				SL.[IsParent] = 1,
				SL.[ParentId] = 0,
				-- link to the main stockline
				SL.[SubComponentParentStocklineId] = @MainStockLineId,
				SL.[SubComponentQty] = @RowQty,
				SL.[IsSubComponent] = 1,
				-- cost belongs to the main part, no accounting entry for the sub component stockline
				SL.[UnitCost] = 0,
				SL.[PurchaseOrderUnitCost] = 0,
				SL.[PurchaseOrderExtendedCost] = 0,
				SL.[InventoryUnitCost] = 0,
				SL.[UnitSalesPrice] = 0,
				SL.[CoreUnitCost] = 0,
				SL.[RepairOrderUnitCost] = 0,
				SL.[RepairOrderExtendedCost] = NULL,
				SL.[WorkOrderExtendedCost] = NULL,
				SL.[POOriginalCost] = NULL,
				SL.[ROOriginalCost] = NULL,
				SL.[OriginalCost] = NULL,
				SL.[LotCost] = 0,
				SL.[PoPartUnitCost] = NULL,
				-- source document references are not copied (otherwise the line shows twice on the PO / RO / WO / SO / Lot screens)
				SL.[OrderDate] = NULL,
				SL.[PurchaseOrderId] = NULL,
				SL.[PurchaseOrderPartRecordId] = NULL,
				SL.[PurchaseOrderNumber] = NULL,
				SL.[QuantityToReceive] = NULL,
				SL.[ReceiverNumber] = NULL,
				SL.[ReconciliationNumber] = NULL,
				SL.[IsFromInitialPO] = 0,
				SL.[RepairOrderId] = NULL,
				SL.[RepairOrderPartRecordId] = NULL,
				SL.[RepairOrderNumber] = NULL,
							SL.[WorkOrderId] = NULL,
				SL.[WorkOrderMaterialsId] = NULL,
				SL.[WorkOrderMaterialsKitId] = NULL,
				SL.[WorkOrderPartNoId] = NULL,
				SL.[WorkOrderNumber] = NULL,
				SL.[SubWorkOrderId] = NULL,
				SL.[SubWOPartNoId] = NULL,
				SL.[SubWorkOrderNumber] = NULL,
				SL.[SubWorkOrderMaterialsId] = NULL,
				SL.[SubWorkOrderMaterialsKitId] = NULL,
				SL.[IsTurnIn] = 0,
				SL.[IsFinishGood] = 0,
				SL.[RRQty] = NULL,
				SL.[SalesOrderPartId] = NULL,
				SL.[ExchangeSalesOrderId] = NULL,
				SL.[IsCustomerRMA] = NULL,
				SL.[RMADeatilsId] = NULL,
				SL.[VendorRMAId] = NULL,
				SL.[VendorRMADetailId] = NULL,
				SL.[LeasePartId] = NULL,
				SL.[LotId] = NULL,
				SL.[IsLotAssigned] = 0,
				SL.[LotNumber] = NULL,
				SL.[LotDescription] = NULL,
				SL.[LOTQty] = NULL,
				SL.[LOTQtyReserve] = NULL,
				SL.[LotMainStocklineId] = NULL,
				SL.[LotSourceId] = NULL,
				SL.[TransferredFromLotId] = NULL,
				SL.[TransferredFromLotNumber] = NULL,
				SL.[AircraftInstalledPartDetailsId] = NULL,
				SL.[AircraftSN] = NULL,
				SL.[QuickBooksReferenceId] = NULL,
				SL.[IsUpdated] = NULL,
				SL.[LastSyncDate] = NULL,
				SL.[Memo] = N'Auto created as Sub Component of STK: ' + ISNULL(@MainLabel, N'') + N' during PO Receiving. Date: ' + FORMAT(GETUTCDATE(), 'dd/MM/yyyy'),
				SL.[CreatedBy] = @UpdatedBy,
				SL.[UpdatedBy] = @UpdatedBy,
				SL.[CreatedDate] = GETUTCDATE(),
				SL.[UpdatedDate] = GETUTCDATE(),
				SL.[EntryDate] = GETUTCDATE()
			FROM [dbo].[Stockline] SL
			INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = @SubItemMasterId
			WHERE SL.[StockLineId] = @NewStocklineId;

			-- management structure, denormalized names (condition, manufacturer, UOM, site, warehouse ...) and history
			EXEC [dbo].[USP_SaveSLMSDetails] @MSModuleID, @NewStocklineId, @MainManagementStructureId, @MasterCompanyId, @UpdatedBy;
			EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId;

			IF (@LinkActionId IS NOT NULL)
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @NewStocklineId, @ModuleId = @StockLineModuleId, @ReferenceId = @MainStockLineId,
					 @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @LinkActionId, @Qty = @RowQty, @UpdatedBy = @UpdatedBy;

			SET @UnitNo = @UnitNo + 1;
		END

		FETCH NEXT FROM WorkCursor INTO @WorkId, @MainStockLineId, @SubItemMasterId, @ConditionId, @WorkQty;
	END
	CLOSE WorkCursor;
	DEALLOCATE WorkCursor;

	DROP TABLE #SubCompWork;
END
