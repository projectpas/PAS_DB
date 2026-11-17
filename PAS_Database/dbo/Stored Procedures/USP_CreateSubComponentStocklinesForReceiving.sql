
/*************************************************************
 ** File:   [USP_CreateSubComponentStocklinesForReceiving]
 ** Description: PO Receiving - creates the Sub Component Stocklines of the received main stocklines.
                 Item Master > Sub Assembly > Sub Component rows (dbo.SubComponent) with "Auto Create Stockline" = Yes
                 are used. For every received main stockline (@StockLineIds) and every such sub component:
                   - one linked stockline of the Sub Component part number (SubComponentParentStocklineId = main stockline,
                     SubComponentQty = Qty, IsSubComponent = 1) is created
                   - Qty        = one stockline (Qty 1) per unit : sub component Qty x received qty of the main stockline
                                  (Bearing Qty 2, main stockline Qty 2 -> 4 Bearing stocklines of Qty 1, Bolt Qty 4 -> 8 Bolt stocklines)
                   - Condition  = sub component Condition, blank -> Condition of the main stockline
                   - serial numbers of serialized sub component part numbers are entered later
                   - site / warehouse / location / shelf / bin / management structure / vendor are taken from the main stockline,
                     part data (PN, description, manufacturer, GL, UOM, PMA / DER / OEM ...) from the sub component Item Master
                   - cost is 0 and no accounting batch is posted (the cost belongs to the main part), RO / WO / Lot references are
                     not copied (same as USP_SplitStocklineForSubComponent). The PO / PO part / PO number / Receiver Number of the main stockline ARE kept
                     [PN-18527], so the stockline shows on the Receiving PO screen, Stockline List, Stock Report and PO View > Receiving tab
                 Stockline / Control / Id number generation follows USP_SplitStocklineForSubComponent.
                 Only Stock stocklines are used (Non-Stock and Asset stocklines are skipped). A main stockline that already has a
                 linked stockline for the same sub component part number + condition is skipped (safe to call again).
                 Time / Cycle entered on the Receiving PO Sub Component grid (@SubComponentTimeCycle, keyed by PO part + sub component part
                 number + condition) is written for every created sub component stockline : one StocklineTimeCycleHistory row
                 (Module = Receiving PO, EntryType 'Receiving', ParentStocklineId = main stockline, TotalTSN / TSO in hours + minutes,
                 TotalCSN / CSO) and Stockline.TotalTSN / TotalTSNMM / TotalCSN are set to the same values.
                 [PN-18526] Condition / Qty Received / Unit Cost entered on the Receiving PO Sub Component grid (@SubComponentDetail, keyed by PO part +
                 sub component part number + original condition) :
                   - Condition  = selected condition (also used for the duplicate check)
                   - Qty        = entered Qty Received for the PO part, shared over the received main stocklines of the PO part in proportion to their qty
                                  (0 = no stockline for that sub component), one Qty 1 stockline per unit as before
                   - Unit Cost  = entered unit cost, kept on the sub component stockline (UnitCost / PurchaseOrderUnitCost / InventoryUnitCost,
                                  PurchaseOrderExtendedCost = Unit Cost x Qty) for inventory / reference only. NO accounting entry is posted for a sub component
                                  stockline (the main part journal already carries the cost) and RRQty stays NULL so the stockline is never picked by the
                                  Receiving Reconciliation, i.e. the cost is not counted twice.
                   - validation : total sub component cost of a PO part (Qty Received x Unit Cost) must not exceed the Main Part Cost
                                  (Unit Cost x Qty of the received main stocklines), otherwise 'Total Sub Component Cost cannot exceed the Main Part Cost.' is raised
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
    3    09-NOV-2026  Kishor Makwana    [PN-18498] One Qty 1 stockline per unit for every sub component (not only serialized ones), as in the story table
    2    09-NOV-2026  Kishor Makwana    [PN-18498] New @SubComponentTimeCycle (Receiving PO Sub Component grid) : Time / Cycle of every created sub component
                                        stockline is stored in StocklineTimeCycleHistory
    4    11-NOV-2026  Kishor Makwana    [PN-18527] Sub component stocklines keep the PO / PO part / PO number / Receiver Number of the main stockline so they show on the Receiving PO
                                        screen, Stockline List, Stock Report and PO View > Receiving tab
    5    12-NOV-2026  Kishor Makwana    [PN-18526] New @SubComponentDetail (Condition / Qty Received / Unit Cost of the Sub Component grid) : entered values are saved on the
                                        sub component stocklines, sub component cost <= main part cost validation, still no accounting entry for sub component stocklines
                                        Stockline TotalTSN / TotalTSNMM / TotalCSN / TotalCSNMM are always set from the entered Time / Cycle (0 when none entered)
    6    13-NOV-2026  Kishor Makwana    [PN-18527] Bug : the sub component stockline took the Item Type of the main stockline (STOCK) - ItemTypeId / itemType are now set from the sub component Item Master
    7    13-NOV-2026  Kishor Makwana    [PN-18527] Bug : PN label (GenerateStocklinePrintPDFContent) failed with SqlNullValueException - Stockline.ShelfLife / QuantityToReceive / RepairOrderExtendedCost / WorkOrderExtendedCost are non nullable in the API model, now saved as 0 instead of NULL
	8    13-NOV-2026  Kishor Makwana    [PN-18527] IsAsset / IsNonStock of the sub component stockline are set from the sub component Item Master (ProcStockList shows Item Type from them)

-- EXEC [dbo].[USP_CreateSubComponentStocklinesForReceiving] @StockLineIds = '101,102', @MasterCompanyId = 1, @UpdatedBy = 'admin'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateSubComponentStocklinesForReceiving]
	@StockLineIds VARCHAR(MAX),
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256),
	@SubComponentTimeCycle POSubComponentTimeCycle READONLY,
	@SubComponentDetail POSubComponentDetail READONLY -- [PN-18526] optional, empty when nothing was edited
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
			@StockLineModuleId BIGINT = 0, @LinkActionId INT = NULL,
			@ReceivingPOModuleId BIGINT = 28; -- 28 = Receiving Purchase Order (same as USP_CreateStocklineForReceivingPO)

	/* ---------- [PN-18526] total sub component cost must not exceed the main part cost (per PO part of this receipt) ---------- */
	IF EXISTS (SELECT 1 FROM @SubComponentDetail)
	BEGIN
		IF EXISTS (
			SELECT 1
			FROM (SELECT D.[PurchaseOrderPartRecordId], SUM(ISNULL(D.[QtyReceived], 0) * ISNULL(D.[UnitCost], 0)) AS [SubCost]
				  FROM @SubComponentDetail D GROUP BY D.[PurchaseOrderPartRecordId]) SD
			INNER JOIN (SELECT S.[PurchaseOrderPartRecordId],
							   SUM(ISNULL(NULLIF(S.[PurchaseOrderUnitCost], 0), ISNULL(S.[UnitCost], 0)) * ISNULL(S.[QuantityOnHand], ISNULL(S.[Quantity], 0))) AS [MainCost]
						FROM [dbo].[Stockline] S WITH (NOLOCK)
						WHERE S.[StockLineId] IN (SELECT TRY_CAST(LTRIM(RTRIM([value])) AS BIGINT) FROM STRING_SPLIT(@StockLineIds, ','))
						  AND S.[MasterCompanyId] = @MasterCompanyId AND ISNULL(S.[isDeleted], 0) = 0 AND S.[SubComponentParentStocklineId] IS NULL
						GROUP BY S.[PurchaseOrderPartRecordId]) MC ON MC.[PurchaseOrderPartRecordId] = SD.[PurchaseOrderPartRecordId]
			WHERE ROUND(SD.[SubCost], 2) > ROUND(MC.[MainCost], 2))
		BEGIN
			RAISERROR ('Total Sub Component Cost cannot exceed the Main Part Cost.', 16, 1);
			RETURN;
		END
	END

	/* ---------- main stocklines x sub components (same sub component part + resolved condition is summed) ---------- */
	IF OBJECT_ID(N'tempdb..#SubCompWork') IS NOT NULL DROP TABLE #SubCompWork;
	CREATE TABLE #SubCompWork
	(
		[ID] INT IDENTITY(1, 1) NOT NULL,
		[MainStockLineId] BIGINT NOT NULL,
		[SubItemMasterId] BIGINT NOT NULL,
		[ConditionId] BIGINT NOT NULL,
		[Qty] DECIMAL(18, 6) NOT NULL,
		[OrigConditionId] BIGINT NULL, -- [PN-18526] condition before the user changed it on the grid (key of the grid row)
		[UnitCost] DECIMAL(18, 6) NULL -- [PN-18526] entered unit cost
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

	UPDATE #SubCompWork SET [OrigConditionId] = [ConditionId];

	/* ---------- [PN-18526] Condition / Qty Received / Unit Cost entered on the grid ---------- */
	IF EXISTS (SELECT 1 FROM @SubComponentDetail)
	BEGIN
		IF OBJECT_ID(N'tempdb..#SubCompAlloc') IS NOT NULL DROP TABLE #SubCompAlloc;

		-- the entered Qty Received of a PO part + sub component + condition is shared over the received main stocklines of the PO part
		-- in proportion to their qty (cumulative rounding, the parts always add up to the entered qty)
		SELECT X.[ID], X.[NewConditionId], X.[UnitCost],
			   ROUND(X.[QtyReceived] * X.[CumQty] / NULLIF(X.[TotQty], 0), X.[Digits])
			 - ROUND(X.[QtyReceived] * (X.[CumQty] - X.[MainQty]) / NULLIF(X.[TotQty], 0), X.[Digits]) AS [AllocQty]
		INTO #SubCompAlloc
		FROM (
			SELECT W.[ID], D.[QtyReceived], D.[ConditionId] AS [NewConditionId], D.[UnitCost], M.[MainQty],
				   CASE WHEN D.[QtyReceived] = FLOOR(D.[QtyReceived]) THEN 0 ELSE 6 END AS [Digits],
				   SUM(M.[MainQty]) OVER (PARTITION BY M.[PoPartId], W.[SubItemMasterId], W.[OrigConditionId] ORDER BY W.[ID] ROWS UNBOUNDED PRECEDING) AS [CumQty],
				   SUM(M.[MainQty]) OVER (PARTITION BY M.[PoPartId], W.[SubItemMasterId], W.[OrigConditionId]) AS [TotQty]
			FROM #SubCompWork W
			CROSS APPLY (SELECT S.[PurchaseOrderPartRecordId] AS [PoPartId], ISNULL(S.[QuantityOnHand], ISNULL(S.[Quantity], 0)) AS [MainQty]
						 FROM [dbo].[Stockline] S WITH (NOLOCK) WHERE S.[StockLineId] = W.[MainStockLineId]) M
			INNER JOIN (SELECT DD.[PurchaseOrderPartRecordId], DD.[SubItemMasterId], DD.[OriginalConditionId],
							   MAX(DD.[ConditionId]) AS [ConditionId],
							   SUM(ISNULL(DD.[QtyReceived], 0)) AS [QtyReceived],
							   CASE WHEN SUM(ISNULL(DD.[QtyReceived], 0)) > 0
									THEN SUM(ISNULL(DD.[QtyReceived], 0) * ISNULL(DD.[UnitCost], 0)) / SUM(ISNULL(DD.[QtyReceived], 0)) ELSE 0 END AS [UnitCost]
						FROM @SubComponentDetail DD
						GROUP BY DD.[PurchaseOrderPartRecordId], DD.[SubItemMasterId], DD.[OriginalConditionId]) D
				ON D.[PurchaseOrderPartRecordId] = M.[PoPartId] AND D.[SubItemMasterId] = W.[SubItemMasterId]
				AND ISNULL(D.[OriginalConditionId], W.[OrigConditionId]) = W.[OrigConditionId]
		) X;

		UPDATE W
		SET W.[ConditionId] = ISNULL(NULLIF(A.[NewConditionId], 0), W.[ConditionId]),
			W.[Qty] = A.[AllocQty],
			W.[UnitCost] = ISNULL(A.[UnitCost], 0)
		FROM #SubCompWork W
		INNER JOIN #SubCompAlloc A ON A.[ID] = W.[ID];

		DROP TABLE #SubCompAlloc;

		-- Qty Received 0 : no stockline for this sub component
		DELETE FROM #SubCompWork WHERE [Qty] <= 0;
	END

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
			@StockLineNumber VARCHAR(100), @ControlNumber VARCHAR(100), @IdNumber VARCHAR(100), @NewStocklineId BIGINT,
			@MainPOPartRecordId BIGINT, @MainPOId BIGINT, @MainPONumber VARCHAR(100), @MainReceiverNumber VARCHAR(100),
			@OrigConditionId BIGINT, @SubUnitCost DECIMAL(18, 6),
			@HasTimeCycle BIT, @TcTsnMin DECIMAL(18, 6), @TcTsoMin DECIMAL(18, 6), @TcCsn DECIMAL(18, 6), @TcCso DECIMAL(18, 6),
			@TcTsnH DECIMAL(18, 6), @TcTsnM DECIMAL(18, 6), @TcTsoH DECIMAL(18, 6), @TcTsoM DECIMAL(18, 6);

	DECLARE WorkCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT [ID], [MainStockLineId], [SubItemMasterId], [ConditionId], [Qty], [OrigConditionId], ISNULL([UnitCost], 0) FROM #SubCompWork ORDER BY [ID];

	OPEN WorkCursor;
	FETCH NEXT FROM WorkCursor INTO @WorkId, @MainStockLineId, @SubItemMasterId, @ConditionId, @WorkQty, @OrigConditionId, @SubUnitCost;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @ManufacturerId = IM.[ManufacturerId], @ItemMasterIsSerialized = ISNULL(IM.[isSerialized], 0)
		FROM [dbo].[ItemMaster] IM WITH (NOLOCK) WHERE IM.[ItemMasterId] = @SubItemMasterId;

		SELECT @MainManagementStructureId = S.[ManagementStructureId],
			   @MainLabel = ISNULL(S.[StockLineNumber], '') + N' (PN: ' + ISNULL(S.[PartNumber], '') + N', CN: ' + ISNULL(S.[ControlNumber], '') + N')',
			   @MainPOPartRecordId = S.[PurchaseOrderPartRecordId], @MainPOId = S.[PurchaseOrderId], @MainPONumber = S.[PurchaseOrderNumber], @MainReceiverNumber = S.[ReceiverNumber]
		FROM [dbo].[Stockline] S WITH (NOLOCK) WHERE S.[StockLineId] = @MainStockLineId;

		-- Time / Cycle entered on the Receiving PO Sub Component grid for this PO part + sub component part + condition
		SELECT @HasTimeCycle = 0, @TcTsnMin = 0, @TcTsoMin = 0, @TcCsn = 0, @TcCso = 0;
		SELECT TOP 1 @HasTimeCycle = 1,
					 @TcTsnMin = ISNULL(TC.[TSNHrs], 0) * 60 + ISNULL(TC.[TSNMin], 0),
					 @TcTsoMin = ISNULL(TC.[TSOHrs], 0) * 60 + ISNULL(TC.[TSOMin], 0),
					 @TcCsn = ISNULL(TC.[CSN], 0), @TcCso = ISNULL(TC.[CSO], 0)
		FROM @SubComponentTimeCycle TC
		WHERE TC.[PurchaseOrderPartRecordId] = @MainPOPartRecordId AND TC.[SubItemMasterId] = @SubItemMasterId
		  AND (ISNULL(TC.[TSNHrs], 0) <> 0 OR ISNULL(TC.[TSNMin], 0) <> 0 OR ISNULL(TC.[CSN], 0) <> 0
			   OR ISNULL(TC.[TSOHrs], 0) <> 0 OR ISNULL(TC.[TSOMin], 0) <> 0 OR ISNULL(TC.[CSO], 0) <> 0)
		-- exact condition first : the grid shows the PO part condition for a blank sub component condition, the main stockline condition can be changed on the receiving screen
		ORDER BY CASE WHEN ISNULL(TC.[ConditionId], 0) = ISNULL(@OrigConditionId, 0) THEN 0 ELSE 1 END;
		SELECT @TcTsnH = FLOOR(@TcTsnMin / 60), @TcTsnM = @TcTsnMin - FLOOR(@TcTsnMin / 60) * 60,
			   @TcTsoH = FLOOR(@TcTsoMin / 60), @TcTsoM = @TcTsoMin - FLOOR(@TcTsoMin / 60) * 60;

		-- one stockline (Qty 1) per unit : Bearing Qty 2 x received main qty 2 = 4 Bearing stocklines (story PN-18498).
		-- Only a fractional quantity (decimal UOM) is kept as one stockline for the whole qty.
		SET @UnitCount = CASE WHEN @WorkQty = FLOOR(@WorkQty) THEN CAST(@WorkQty AS INT) ELSE 1 END;
		SET @UnitNo = 1;

		WHILE (@UnitNo <= @UnitCount)
		BEGIN
			SET @RowQty = CASE WHEN @WorkQty = FLOOR(@WorkQty) THEN 1 ELSE @WorkQty END;
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
				SL.[ShelfLife] = 0,
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
				SL.[IsAsset] = ISNULL(IM.[IsAsset], 0),
				SL.[IsNonStock] = ISNULL(IM.[IsNonStock], 0),
				-- [PN-18527] Item Type of the sub component stockline comes from its own Item Master (the copy of the main stockline carried the main part's Item Type)
				SL.[ItemTypeId] = IM.[ItemTypeId],
				SL.[itemType] = IT.[Description],
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
				-- [PN-18526] entered Unit Cost / total cost are kept on the stockline for inventory / reference only : no accounting entry is posted for a
				-- sub component stockline (the main part journal carries the cost) and RRQty stays NULL (not picked by Receiving Reconciliation)
				SL.[UnitCost] = @SubUnitCost,
				SL.[PurchaseOrderUnitCost] = @SubUnitCost,
				SL.[PurchaseOrderExtendedCost] = @SubUnitCost * @RowQty,
				SL.[InventoryUnitCost] = @SubUnitCost,
				SL.[UnitSalesPrice] = 0,
				SL.[CoreUnitCost] = 0,
				SL.[RepairOrderUnitCost] = 0,
				SL.[RepairOrderExtendedCost] = 0,
				SL.[WorkOrderExtendedCost] = 0,
				SL.[POOriginalCost] = NULL,
				SL.[ROOriginalCost] = NULL,
				SL.[OriginalCost] = NULL,
				SL.[LotCost] = 0,
				SL.[PoPartUnitCost] = NULL,
				-- [PN-18527] the PO / PO part / PO number / Receiver Number of the main stockline are kept : the Receiving PO screen (Stockline created for this PO),
				-- Stockline List, Stock Report and PO View > Receiving tab all find a stockline through them. The other source documents (RO / WO / SO / Lot) are not copied.
				SL.[OrderDate] = NULL,
				SL.[PurchaseOrderId] = @MainPOId,
				SL.[PurchaseOrderPartRecordId] = @MainPOPartRecordId,
				SL.[PurchaseOrderNumber] = @MainPONumber,
				SL.[QuantityToReceive] = 0,
				SL.[ReceiverNumber] = @MainReceiverNumber,
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
			LEFT JOIN [dbo].[ItemType] IT WITH (NOLOCK) ON IT.[ItemTypeId] = IM.[ItemTypeId]
			WHERE SL.[StockLineId] = @NewStocklineId;

			-- management structure, denormalized names (condition, manufacturer, UOM, site, warehouse ...) and history
			EXEC [dbo].[USP_SaveSLMSDetails] @MSModuleID, @NewStocklineId, @MainManagementStructureId, @MasterCompanyId, @UpdatedBy;
			EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId;

			IF (@LinkActionId IS NOT NULL)
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @NewStocklineId, @ModuleId = @StockLineModuleId, @ReferenceId = @MainStockLineId,
					 @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @LinkActionId, @Qty = @RowQty, @UpdatedBy = @UpdatedBy;

			-- Time / Cycle of the Receiving PO Sub Component grid -> StocklineTimeCycleHistory (+ current value on the stockline)
			IF (@HasTimeCycle = 1)
			BEGIN
				INSERT INTO [dbo].[StocklineTimeCycleHistory]
					([StocklineId], [ModuleId], [ReferenceId], [ReferenceNumber], [SubModuleId], [SubReferenceId], [SubReferenceNumber], [EntryType], [EntryDate],
					 [Hours], [Minutes], [Cycles], [TotalTSN], [TotalTSNMM], [TotalCSN], [TotalTSO], [TotalTSOMM], [TotalCSO], [Memo],
					 [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [ParentStocklineId])
				VALUES
					(@NewStocklineId, @ReceivingPOModuleId, @MainPOId, @MainPONumber, NULL, NULL, NULL, 'Receiving', GETUTCDATE(),
					 @TcTsnH, @TcTsnM, @TcCsn, @TcTsnH, @TcTsnM, @TcCsn, @TcTsoH, @TcTsoM, @TcCso,
					 N'Time / Cycle entered at PO Receiving (Sub Component of STK: ' + ISNULL(@MainLabel, N'') + N')',
					 @MasterCompanyId, @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0, @MainStockLineId);
			END

			-- [PN-18526] Stockline time / cycle fields : TotalTSN (hours), TotalTSNMM (minutes), TotalCSN (cycles), TotalCSNMM (cycles have no minute part, 0).
			-- Always set (0 when nothing was entered) so the sub component stockline never keeps the Time / Cycle copied from the main stockline row.
			-- TSO / CSO have no Stockline column, they are kept in StocklineTimeCycleHistory only.
			UPDATE [dbo].[Stockline]
			SET [TotalTSN] = @TcTsnH, [TotalTSNMM] = @TcTsnM, [TotalCSN] = @TcCsn, [TotalCSNMM] = 0, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [StockLineId] = @NewStocklineId;

			SET @UnitNo = @UnitNo + 1;
		END

		FETCH NEXT FROM WorkCursor INTO @WorkId, @MainStockLineId, @SubItemMasterId, @ConditionId, @WorkQty, @OrigConditionId, @SubUnitCost;
	END
	CLOSE WorkCursor;
	DEALLOCATE WorkCursor;

	DROP TABLE #SubCompWork;
END