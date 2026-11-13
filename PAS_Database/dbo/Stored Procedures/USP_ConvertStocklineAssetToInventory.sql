/*************************************************************
 ** File:   [USP_ConvertStocklineAssetToInventory]
 ** Description: PN-18535 Convert a leased asset (Stockline.IsAsset = 1, IsLease = 1) to inventory - Stockline List > Asset > Actions > Convert to Inventory.
 **              Everything runs in ONE transaction :
 **              1. Validates (USP_GetStocklineAssetConversionPreview rules : lease asset, not already converted, quantity on hand, not on a Draft / Active lease,
 **                 Asset + Inventory accounting period open) and the Transfer Value (not negative). Returns Status 0 + Message when blocked, nothing is written.
 **              2. Cost = AssetTotalCost, AD = Accumulated Depr of the last depreciation run, NBV = Cost - AD, Transfer Value (default NBV),
 **                 Value over NBV = Transfer Value - NBV : positive = Gain on Conversion, negative = Loss on Conversion.
 **              3. Creates a NEW inventory stockline (IsAsset = 0, IsLease = 0) of the Inventory PN (Item Master AssetInventoryItemMasterId, else the same PN)
 **                 with the quantity of the asset and Unit Cost = Transfer Value / Qty. The asset stockline is KEPT : Qty 0, Asset Status 'CONVERTED TO INVENTORY',
 **                 ConvertedToStocklineId = the new stockline, so the depreciation stops. The new stockline points back with ConvertedFromStocklineId.
 **              4. Journal (Batch List, journal type LACV, distribution LEASEASSETCONVERSION) - always balanced :
 **                   Dr Accumulated Depreciation (AD)       GL of the asset stockline (AdDepsGLAccountId)
 **                   Dr Inventory (Transfer Value)          GL of the Inventory PN (Item Master GLAccountId)
 **                   Dr Loss on Conversion (if loss)        GL of the Distribution Setup line LACVLOSSONCONVERSION
 **                   Cr Asset (Cost)                        GL of the asset stockline (AcquiredGLAccountId)
 **                   Cr Gain on Conversion (if gain)        GL of the Distribution Setup line LACVGAINONCONVERSION
 **                 A company with IsAccountByPass = 1 posts no journal.
 **              5. StocklineAssetConversion row (conversion date / value / Gain-Loss / journal reference / audit) + Stockline History (action 'ConvertToInventory'
 **                 when that action exists in StklineHistory_Action).
 ** Returns: one row - Status (1 ok / 0 blocked), Message, NewStockLineId, NewStockLineNumber, ValueOverNBV, GainLossType, BatchName, JournalTypeNumber.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    12/November/2026 Kishor Makwana  [PN-18535] Created
 -- EXEC [dbo].[USP_ConvertStocklineAssetToInventory] @StockLineId = 1, @TransferValue = 95000, @MasterCompanyId = 1, @UpdatedBy = 'ADMIN User'
**************************************************************/
CREATE PROCEDURE [dbo].[USP_ConvertStocklineAssetToInventory]
	@StockLineId     BIGINT,
	@TransferValue   DECIMAL(18, 6) = NULL,
	@MasterCompanyId INT,
	@UpdatedBy       VARCHAR(256),
	@ConversionDate  DATETIME2(7) = NULL,
	@Memo            NVARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SET @ConversionDate = ISNULL(@ConversionDate, SYSUTCDATETIME());

		/* ---------- 1. validate ---------- */
		IF OBJECT_ID(N'tempdb..#Preview') IS NOT NULL DROP TABLE #Preview;
		CREATE TABLE #Preview
		(
			[StockLineId] BIGINT, [StockLineNumber] NVARCHAR(100), [PartNumber] NVARCHAR(250), [PartDescription] NVARCHAR(MAX), [BaseNum] NVARCHAR(100), [PNType] NVARCHAR(100),
			[ItemMasterId] BIGINT, [InventoryItemMasterId] BIGINT, [InventoryPartNumber] NVARCHAR(250), [Quantity] DECIMAL(18, 6),
			[Cost] DECIMAL(18, 2), [AccumulatedDepr] DECIMAL(18, 2), [NetBookValue] DECIMAL(18, 2), [TransferValue] DECIMAL(18, 2), [ValueOverNBV] DECIMAL(18, 2),
			[ConversionDate] DATETIME2(7), [AccountingCalendarId] BIGINT, [AccountingPeriod] VARCHAR(100), [IsConvertible] BIT, [BlockReason] NVARCHAR(500)
		);
		INSERT INTO #Preview EXEC [dbo].[USP_GetStocklineAssetConversionPreview] @StockLineId = @StockLineId, @MasterCompanyId = @MasterCompanyId, @ConversionDate = @ConversionDate;

		DECLARE @Cost DECIMAL(18, 2), @AD DECIMAL(18, 2), @NBV DECIMAL(18, 2), @Transfer DECIMAL(18, 2), @Diff DECIMAL(18, 2), @GainLoss VARCHAR(10),
		        @Qty DECIMAL(18, 6), @InvItemMasterId BIGINT, @AccountingCalendarId BIGINT, @AccountingPeriod VARCHAR(100), @BlockReason NVARCHAR(500),
		        @IsConvertible BIT, @SrcStockLineNumber NVARCHAR(100), @SrcPartNumber NVARCHAR(250), @SrcItemMasterId BIGINT, @BaseNum NVARCHAR(100), @PNType NVARCHAR(100);

		SELECT @Cost = P.[Cost], @AD = P.[AccumulatedDepr], @NBV = P.[NetBookValue], @Qty = P.[Quantity], @InvItemMasterId = P.[InventoryItemMasterId],
		       @AccountingCalendarId = P.[AccountingCalendarId], @AccountingPeriod = P.[AccountingPeriod], @BlockReason = P.[BlockReason], @IsConvertible = P.[IsConvertible],
		       @SrcStockLineNumber = P.[StockLineNumber], @SrcPartNumber = P.[PartNumber], @SrcItemMasterId = P.[ItemMasterId], @BaseNum = P.[BaseNum], @PNType = P.[PNType]
		FROM #Preview P;

		IF @IsConvertible IS NULL
		BEGIN
			SELECT CAST(0 AS INT) AS [Status], 'The asset stockline was not found.' AS [Message], CAST(NULL AS BIGINT) AS [NewStockLineId], CAST(NULL AS VARCHAR(100)) AS [NewStockLineNumber],
			       CAST(0 AS DECIMAL(18, 2)) AS [ValueOverNBV], 'NONE' AS [GainLossType], CAST(NULL AS VARCHAR(100)) AS [BatchName], CAST(NULL AS VARCHAR(100)) AS [JournalTypeNumber];
			RETURN;
		END
		IF @IsConvertible = 0
		BEGIN
			SELECT CAST(0 AS INT) AS [Status], @BlockReason AS [Message], CAST(NULL AS BIGINT) AS [NewStockLineId], CAST(NULL AS VARCHAR(100)) AS [NewStockLineNumber],
			       CAST(0 AS DECIMAL(18, 2)) AS [ValueOverNBV], 'NONE' AS [GainLossType], CAST(NULL AS VARCHAR(100)) AS [BatchName], CAST(NULL AS VARCHAR(100)) AS [JournalTypeNumber];
			RETURN;
		END

		SET @Transfer = ROUND(ISNULL(@TransferValue, @NBV), 2);
		IF @Transfer < 0
		BEGIN
			SELECT CAST(0 AS INT) AS [Status], 'Transfer Value cannot be negative.' AS [Message], CAST(NULL AS BIGINT) AS [NewStockLineId], CAST(NULL AS VARCHAR(100)) AS [NewStockLineNumber],
			       CAST(0 AS DECIMAL(18, 2)) AS [ValueOverNBV], 'NONE' AS [GainLossType], CAST(NULL AS VARCHAR(100)) AS [BatchName], CAST(NULL AS VARCHAR(100)) AS [JournalTypeNumber];
			RETURN;
		END

		-- Accumulated Depr never goes over the Cost, NBV = Cost - AD (all rounded to 2 decimals so the journal balances to the cent)
		IF @AD > @Cost SET @AD = @Cost;
		SET @NBV  = @Cost - @AD;
		SET @Diff = @Transfer - @NBV;
		SET @GainLoss = CASE WHEN @Diff > 0 THEN 'GAIN' WHEN @Diff < 0 THEN 'LOSS' ELSE 'NONE' END;

		/* ---------- journal set up : GL accounts must be available before anything is written ---------- */
		DECLARE @IsAccountByPass BIT = 0, @DistributionMasterId BIGINT, @JournalTypeId BIGINT, @JournalTypeCode VARCHAR(50), @JournalTypeName VARCHAR(200);
		SELECT @IsAccountByPass = ISNULL(MC.[IsAccountByPass], 0) FROM dbo.MasterCompany MC WITH (NOLOCK) WHERE MC.[MasterCompanyId] = @MasterCompanyId;
		SELECT TOP 1 @DistributionMasterId = DM.[ID], @JournalTypeId = DM.[JournalTypeId]
		FROM dbo.DistributionMaster DM WITH (NOLOCK) WHERE UPPER(DM.[DistributionCode]) = 'LEASEASSETCONVERSION' AND ISNULL(DM.[IsDeleted], 0) = 0;
		SELECT @JournalTypeCode = JT.[JournalTypeCode], @JournalTypeName = JT.[JournalTypeName] FROM dbo.JournalType JT WITH (NOLOCK) WHERE JT.[ID] = @JournalTypeId;

		DECLARE @AssetGL BIGINT, @AdGL BIGINT, @InvGL BIGINT, @GainGL BIGINT, @LossGL BIGINT, @ManagementStructureId BIGINT, @LegalEntityId BIGINT;
		SELECT @AssetGL = STK.[AcquiredGLAccountId], @AdGL = STK.[AdDepsGLAccountId], @ManagementStructureId = STK.[ManagementStructureId], @LegalEntityId = STK.[LegalEntityId]
		FROM dbo.Stockline STK WITH (NOLOCK) WHERE STK.[StockLineId] = @StockLineId;
		SELECT @InvGL = IM.[GLAccountId] FROM dbo.ItemMaster IM WITH (NOLOCK) WHERE IM.[ItemMasterId] = @InvItemMasterId;
		SELECT @GainGL = S.[GlAccountId] FROM dbo.DistributionSetup S WITH (NOLOCK)
		WHERE S.[DistributionMasterId] = @DistributionMasterId AND S.[MasterCompanyId] = @MasterCompanyId AND S.[DistributionSetupCode] = 'LACVGAINONCONVERSION' AND ISNULL(S.[IsDeleted], 0) = 0;
		SELECT @LossGL = S.[GlAccountId] FROM dbo.DistributionSetup S WITH (NOLOCK)
		WHERE S.[DistributionMasterId] = @DistributionMasterId AND S.[MasterCompanyId] = @MasterCompanyId AND S.[DistributionSetupCode] = 'LACVLOSSONCONVERSION' AND ISNULL(S.[IsDeleted], 0) = 0;

		DECLARE @Msg NVARCHAR(500) = NULL;
		IF @IsAccountByPass = 0
		BEGIN
			IF @DistributionMasterId IS NULL OR @JournalTypeId IS NULL
				SET @Msg = 'Journal master data for the conversion (LEASEASSETCONVERSION) is not set up. Run the PN-18535 accounting seed script.';
			ELSE IF @Cost > 0 AND ISNULL(@AssetGL, 0) = 0
				SET @Msg = 'The Asset GL account (Acquired GL) is not set on the asset stockline.';
			ELSE IF @AD > 0 AND ISNULL(@AdGL, 0) = 0
				SET @Msg = 'The Accumulated Depreciation GL account is not set on the asset stockline.';
			ELSE IF @Transfer > 0 AND ISNULL(@InvGL, 0) = 0
				SET @Msg = 'The GL account of the Inventory PN (' + ISNULL(@SrcPartNumber, '') + ') is not set in Item Master.';
			ELSE IF @GainLoss = 'GAIN' AND ISNULL(@GainGL, 0) = 0
				SET @Msg = 'Gain on Conversion GL account is not mapped in Distribution Setup (journal LEASEASSETCONVERSION).';
			ELSE IF @GainLoss = 'LOSS' AND ISNULL(@LossGL, 0) = 0
				SET @Msg = 'Loss on Conversion GL account is not mapped in Distribution Setup (journal LEASEASSETCONVERSION).';
		END

		DECLARE @ConvertedStatusId BIGINT, @StockLineModuleId BIGINT, @MSModuleID INT = 2, @AccountMSModuleId INT, @OpenStatusId INT, @OpenStatusName VARCHAR(200),
		        @StocklineCodeType INT, @ControlNumberCodeType INT, @IdNumberCodeType INT, @JeCodeTypeId BIGINT = 74,
		        @StlCodePrefixId BIGINT, @StlCodePrefix VARCHAR(50), @StlCodeSufix VARCHAR(50),
		        @StlCNCodePrefixId BIGINT, @StlIdCodePrefix VARCHAR(50), @StlIdCodeSufix VARCHAR(50);
		SELECT TOP 1 @ConvertedStatusId = S.[AssetStatusId] FROM dbo.AssetStatus S WITH (NOLOCK)
		WHERE S.[MasterCompanyId] = @MasterCompanyId AND ISNULL(S.[IsDeleted], 0) = 0 AND UPPER(S.[Name]) = 'CONVERTED TO INVENTORY';
		SELECT @StocklineCodeType = [CodeTypeId] FROM dbo.CodeTypes WITH (NOLOCK) WHERE [CodeType] = 'Stock Line';
		SELECT @ControlNumberCodeType = [CodeTypeId] FROM dbo.CodeTypes WITH (NOLOCK) WHERE [CodeType] = 'Control Number';
		SELECT @IdNumberCodeType = [CodeTypeId] FROM dbo.CodeTypes WITH (NOLOCK) WHERE [CodeType] = 'Id Number';
		SELECT @StlCodePrefixId = [CodePrefixId], @StlCodePrefix = [CodePrefix], @StlCodeSufix = [CodeSufix]
		FROM dbo.CodePrefixes WITH (NOLOCK) WHERE [CodeTypeId] = @StocklineCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		SELECT @StlIdCodePrefix = [CodePrefix], @StlIdCodeSufix = [CodeSufix]
		FROM dbo.CodePrefixes WITH (NOLOCK) WHERE [CodeTypeId] = @IdNumberCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		SELECT @StlCNCodePrefixId = [CodePrefixId] FROM dbo.CodePrefixes WITH (NOLOCK)
		WHERE [CodeTypeId] = @ControlNumberCodeType AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;

		IF @Msg IS NULL AND @ConvertedStatusId IS NULL
			SET @Msg = 'Asset Status ''CONVERTED TO INVENTORY'' is not set up. Run the PN-18535 schema script.';
		IF @Msg IS NULL AND (ISNULL(@StlCodePrefixId, 0) = 0 OR ISNULL(@StlCNCodePrefixId, 0) = 0 OR ISNULL(@StlIdCodePrefix, '') = '' AND NOT EXISTS (SELECT 1 FROM dbo.CodePrefixes WITH (NOLOCK) WHERE [CodeTypeId] = @IdNumberCodeType AND [MasterCompanyId] = @MasterCompanyId))
			SET @Msg = 'Code Prefix not Available.!';
		IF @Msg IS NULL AND @InvItemMasterId IS NULL
			SET @Msg = 'The Inventory PN of the asset was not found.';

		IF @Msg IS NOT NULL
		BEGIN
			SELECT CAST(0 AS INT) AS [Status], @Msg AS [Message], CAST(NULL AS BIGINT) AS [NewStockLineId], CAST(NULL AS VARCHAR(100)) AS [NewStockLineNumber],
			       @Diff AS [ValueOverNBV], @GainLoss AS [GainLossType], CAST(NULL AS VARCHAR(100)) AS [BatchName], CAST(NULL AS VARCHAR(100)) AS [JournalTypeNumber];
			RETURN;
		END

		BEGIN TRANSACTION;

		-- lock the asset stockline and re-check that nobody converted it meanwhile
		IF EXISTS (SELECT 1 FROM dbo.Stockline S WITH (UPDLOCK, ROWLOCK) WHERE S.[StockLineId] = @StockLineId AND S.[ConvertedToStocklineId] IS NOT NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT CAST(0 AS INT) AS [Status], 'This asset is already converted to inventory.' AS [Message], CAST(NULL AS BIGINT) AS [NewStockLineId], CAST(NULL AS VARCHAR(100)) AS [NewStockLineNumber],
			       @Diff AS [ValueOverNBV], @GainLoss AS [GainLossType], CAST(NULL AS VARCHAR(100)) AS [BatchName], CAST(NULL AS VARCHAR(100)) AS [JournalTypeNumber];
			RETURN;
		END

		/* ---------- 3. new inventory stockline : every column of the asset stockline is copied, then the inventory values are set ---------- */
		DECLARE @Cols NVARCHAR(MAX), @Sql NVARCHAR(MAX), @NewStocklineId BIGINT, @ManufacturerId BIGINT,
		        @currentNo BIGINT, @cncurrentNo BIGINT, @StlCNCurrent BIGINT, @StlCNStarts BIGINT, @StlCNCodePrefix VARCHAR(50), @StlCNCodeSufix VARCHAR(50),
		        @NewStockLineNumber VARCHAR(100), @ControlNumber VARCHAR(100), @IdNumber VARCHAR(100);
		SELECT @Cols = STRING_AGG(CAST(QUOTENAME(c.[name]) AS NVARCHAR(MAX)), N',') WITHIN GROUP (ORDER BY c.[column_id])
		FROM sys.columns c
		WHERE c.[object_id] = OBJECT_ID(N'dbo.Stockline') AND c.[is_identity] = 0 AND c.[is_computed] = 0 AND c.[system_type_id] <> 189;
		SET @Sql = N'INSERT INTO [dbo].[Stockline] (' + @Cols + N') SELECT ' + @Cols + N' FROM [dbo].[Stockline] WHERE [StockLineId] = @SourceId; SET @NewId = SCOPE_IDENTITY();';

		SELECT @ManufacturerId = IM.[ManufacturerId] FROM dbo.ItemMaster IM WITH (NOLOCK) WHERE IM.[ItemMasterId] = @InvItemMasterId;

		-- Stockline number : PN + Manufacturer running number lives on ItemMaster.CurrentStlNo (same as the sub component stockline creation)
		SELECT @currentNo = ISNULL([CurrentStlNo], 0) FROM dbo.ItemMaster WITH (UPDLOCK) WHERE [ItemMasterId] = @InvItemMasterId AND [ManufacturerId] = @ManufacturerId;
		SET @currentNo = CASE WHEN @currentNo > 0 THEN @currentNo + 1 ELSE 1 END;
		SET @NewStockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@currentNo AS BIGINT), @StlCodePrefix, @StlCodeSufix));
		WHILE EXISTS (SELECT 1 FROM dbo.Stockline WITH (NOLOCK) WHERE [ItemMasterId] = @InvItemMasterId AND [ManufacturerId] = @ManufacturerId
		              AND [MasterCompanyId] = @MasterCompanyId AND [StockLineNumber] = @NewStockLineNumber)
		BEGIN
			SET @currentNo = @currentNo + 1;
			SET @NewStockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@currentNo AS BIGINT), @StlCodePrefix, @StlCodeSufix));
		END

		SELECT @StlCNCurrent = ISNULL([CurrentNummber], 0), @StlCNStarts = ISNULL([StartsFrom], 0), @StlCNCodePrefix = [CodePrefix], @StlCNCodeSufix = [CodeSufix]
		FROM dbo.CodePrefixes WITH (UPDLOCK) WHERE [CodePrefixId] = @StlCNCodePrefixId;
		SET @cncurrentNo = CASE WHEN @StlCNCurrent > 0 THEN @StlCNCurrent + 1 ELSE @StlCNStarts + 1 END;
		SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@cncurrentNo, @StlCNCodePrefix, @StlCNCodeSufix));
		SET @IdNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(1, @StlIdCodePrefix, @StlIdCodeSufix));

		UPDATE dbo.ItemMaster SET [CurrentStlNo] = @currentNo, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
		WHERE [ItemMasterId] = @InvItemMasterId AND [ManufacturerId] = @ManufacturerId;
		UPDATE dbo.CodePrefixes SET [CurrentNummber] = @currentNo WHERE [CodeTypeId] = @StocklineCodeType AND [MasterCompanyId] = @MasterCompanyId;
		UPDATE dbo.CodePrefixes SET [CurrentNummber] = @cncurrentNo WHERE [CodePrefixId] = @StlCNCodePrefixId;
		UPDATE dbo.CodePrefixes SET [CurrentNummber] = 1 WHERE [CodeTypeId] = @IdNumberCodeType AND [MasterCompanyId] = @MasterCompanyId;

		EXEC sp_executesql @Sql, N'@SourceId BIGINT, @NewId BIGINT OUTPUT', @SourceId = @StockLineId, @NewId = @NewStocklineId OUTPUT;

		UPDATE SL
		SET SL.[ItemMasterId] = IM.[ItemMasterId],
			SL.[PartNumber] = IM.[partnumber],
			-- description : Inventory PN Item Master, else the description of the asset stockline, else the asset name
			SL.[PNDescription] = COALESCE(NULLIF(LTRIM(RTRIM(IM.[PartDescription])), ''), NULLIF(LTRIM(RTRIM(SRC.[PNDescription])), ''), NULLIF(LTRIM(RTRIM(SRC.[AssetName])), '')),
			SL.[ManufacturerId] = IM.[ManufacturerId],
			SL.[ItemTypeId] = IM.[ItemTypeId],
			SL.[GLAccountId] = IM.[GLAccountId],
			SL.[StockLineNumber] = @NewStockLineNumber,
			SL.[ControlNumber] = @ControlNumber,
			SL.[IdNumber] = @IdNumber,
			SL.[StocklineMatchKey] = NULL,
			-- it is inventory now : no asset / lease / depreciation
			SL.[IsAsset] = 0,
			SL.[IsLease] = 0,
			SL.[IsNonStock] = 0,
			SL.[AssetId] = NULL,
			SL.[AssetIsDepreciable] = 0,
			SL.[AssetTotalCost] = NULL,
			SL.[AssetStatusId] = NULL,
			SL.[AssetLife] = NULL,
			SL.[AssetInventoryItemMasterId] = NULL,
			-- quantity (same as the asset)
			SL.[Quantity] = @Qty,
			SL.[QuantityOnHand] = @Qty,
			SL.[QuantityReserved] = 0,
			SL.[QuantityAvailable] = @Qty,
			SL.[QuantityIssued] = 0,
			SL.[QuantityTurnIn] = 0,
			SL.[QuantityOnOrder] = 0,
			SL.[QuantityRejected] = 0,
			SL.[QtyReserved] = 0,
			SL.[QtyIssued] = 0,
			SL.[IsParent] = 1,
			SL.[ParentId] = 0,
			SL.[SubComponentParentStocklineId] = NULL,
			SL.[SubComponentQty] = NULL,
			SL.[IsSubComponent] = 0,
			SL.[LeasePartId] = NULL,
			-- Unit Cost = Transfer Value
			SL.[UnitCost] = CASE WHEN @Qty > 0 THEN @Transfer / @Qty ELSE @Transfer END,
			SL.[InventoryUnitCost] = CASE WHEN @Qty > 0 THEN @Transfer / @Qty ELSE @Transfer END,
			-- link back to the leased asset
			SL.[ConvertedFromStocklineId] = @StockLineId,
			SL.[ConvertedToStocklineId] = NULL,
			SL.[ConversionDate] = @ConversionDate,
			SL.[Memo] = N'Converted from leased asset STK: ' + ISNULL(@SrcStockLineNumber, N'') + N' (PN: ' + ISNULL(@SrcPartNumber, N'') + N') on ' + FORMAT(@ConversionDate, 'dd/MM/yyyy')
			            + CASE WHEN ISNULL(@Memo, N'') <> N'' THEN N'. ' + @Memo ELSE N'' END,
			SL.[CreatedBy] = @UpdatedBy,
			SL.[UpdatedBy] = @UpdatedBy,
			SL.[CreatedDate] = GETUTCDATE(),
			SL.[UpdatedDate] = GETUTCDATE(),
			SL.[EntryDate] = GETUTCDATE()
		FROM dbo.Stockline SL
		INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.[ItemMasterId] = @InvItemMasterId
		INNER JOIN dbo.Stockline SRC WITH (NOLOCK) ON SRC.[StockLineId] = @StockLineId
		WHERE SL.[StockLineId] = @NewStocklineId;

		EXEC [dbo].[USP_SaveSLMSDetails] @MSModuleID, @NewStocklineId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy;
		EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId;

		/* ---------- the leased asset stockline is kept : Qty 0, Converted to Inventory, depreciation stops ---------- */
		UPDATE dbo.Stockline
		SET [Quantity] = 0, [QuantityOnHand] = 0, [QuantityAvailable] = 0, [QuantityReserved] = 0, [QtyReserved] = 0,
			[AssetStatusId] = @ConvertedStatusId,
			[ConvertedToStocklineId] = @NewStocklineId,
			[ConversionDate] = @ConversionDate,
			[UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
		WHERE [StockLineId] = @StockLineId;

		/* ---------- 4. journal (Batch List) ---------- */
		DECLARE @JournalBatchHeaderId BIGINT = NULL, @JournalBatchDetailId BIGINT = NULL, @JournalTypeNumber VARCHAR(100) = NULL, @BatchName VARCHAR(100) = NULL;

		IF @IsAccountByPass = 0
		BEGIN
			SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM dbo.ManagementStructureModule WITH (NOLOCK) WHERE [ModuleName] = 'Accounting';
			SELECT @OpenStatusId = [Id], @OpenStatusName = [Name] FROM dbo.BatchStatus WITH (NOLOCK) WHERE [Name] = 'Open';

			DECLARE @LastMSLevel VARCHAR(MAX), @AllMSlevels VARCHAR(MAX);
			SELECT @LastMSLevel = MSD.[LastMSLevel], @AllMSlevels = MSD.[AllMSlevels]
			FROM dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) WHERE MSD.[ReferenceID] = @StockLineId AND MSD.[ModuleID] = @MSModuleID;

			-- journal number (Code Prefix type 74)
			DECLARE @JeCurrent BIGINT, @JeStarts BIGINT, @JePrefix VARCHAR(50), @JeSufix VARCHAR(50), @JeNo BIGINT;
			SELECT @JeCurrent = ISNULL([CurrentNummber], 0), @JeStarts = ISNULL([StartsFrom], 0), @JePrefix = [CodePrefix], @JeSufix = [CodeSufix]
			FROM dbo.CodePrefixes WITH (UPDLOCK) WHERE [CodeTypeId] = @JeCodeTypeId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
			IF @JePrefix IS NULL AND @JeSufix IS NULL AND NOT EXISTS (SELECT 1 FROM dbo.CodePrefixes WITH (NOLOCK) WHERE [CodeTypeId] = @JeCodeTypeId AND [MasterCompanyId] = @MasterCompanyId)
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT CAST(0 AS INT) AS [Status], 'Journal number Code Prefix not Available.!' AS [Message], CAST(NULL AS BIGINT) AS [NewStockLineId], CAST(NULL AS VARCHAR(100)) AS [NewStockLineNumber],
				       @Diff AS [ValueOverNBV], @GainLoss AS [GainLossType], CAST(NULL AS VARCHAR(100)) AS [BatchName], CAST(NULL AS VARCHAR(100)) AS [JournalTypeNumber];
				RETURN;
			END
			SET @JeNo = CASE WHEN @JeCurrent > 0 THEN @JeCurrent + 1 ELSE @JeStarts + 1 END;
			SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@JeNo, @JePrefix, @JeSufix));
			UPDATE dbo.CodePrefixes SET [CurrentNummber] = @JeNo WHERE [CodeTypeId] = @JeCodeTypeId AND [MasterCompanyId] = @MasterCompanyId;

			-- open batch of the same journal type + accounting period + day, else a new batch
			SELECT TOP 1 @JournalBatchHeaderId = BH.[JournalBatchHeaderId], @BatchName = BH.[BatchName]
			FROM dbo.BatchHeader BH WITH (UPDLOCK)
			WHERE BH.[JournalTypeId] = @JournalTypeId AND BH.[MasterCompanyId] = @MasterCompanyId AND BH.[StatusId] = @OpenStatusId
			  AND ISNULL(BH.[AccountingPeriodId], 0) = ISNULL(@AccountingCalendarId, 0) AND CAST(BH.[EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND ISNULL(BH.[IsDeleted], 0) = 0
			ORDER BY BH.[JournalBatchHeaderId] DESC;

			IF @JournalBatchHeaderId IS NULL
			BEGIN
				DECLARE @BatchNo BIGINT;
				SELECT TOP 1 @BatchNo = CASE WHEN BH.[CurrentNumber] > 0 THEN CAST(BH.[CurrentNumber] AS BIGINT) + 1 ELSE 1 END FROM dbo.BatchHeader BH WITH (NOLOCK) ORDER BY BH.[JournalBatchHeaderId] DESC;
				SET @BatchNo = ISNULL(@BatchNo, 1);
				SET @BatchName = @JournalTypeCode + ' ' + CASE WHEN @BatchNo > 99 THEN CAST(@BatchNo AS VARCHAR(20)) ELSE RIGHT('000' + CAST(@BatchNo AS VARCHAR(20)), 3) END;

				INSERT INTO dbo.BatchHeader
					([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],[AccountingPeriodId],[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
				VALUES
					(@BatchName, @BatchNo, GETUTCDATE(), @AccountingPeriod, @AccountingCalendarId, @OpenStatusId, @OpenStatusName, @JournalTypeId, @JournalTypeName, 0, 0, 0, @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, 'LEASEASSETCONVERSION');
				SET @JournalBatchHeaderId = SCOPE_IDENTITY();
			END

			DECLARE @LineNo INT;
			SELECT @LineNo = ISNULL(MAX(BD.[LineNumber]), 0) + 1 FROM dbo.BatchDetails BD WITH (NOLOCK) WHERE BD.[JournalBatchHeaderId] = @JournalBatchHeaderId;

			-- journal lines (only the lines with an amount) : IsDebit 1 = Debit, 0 = Credit
			IF OBJECT_ID(N'tempdb..#JeLines') IS NOT NULL DROP TABLE #JeLines;
			CREATE TABLE #JeLines ([Seq] INT, [Code] VARCHAR(100), [GlAccountId] BIGINT, [IsDebit] BIT, [Amount] DECIMAL(18, 2));
			INSERT INTO #JeLines VALUES
				(1, 'LACVACCUMULATEDDEPRECIATION', @AdGL,   1, @AD),
				(2, 'LACVINVENTORY',               @InvGL,  1, @Transfer),
				(3, 'LACVLOSSONCONVERSION',        @LossGL, 1, CASE WHEN @Diff < 0 THEN -@Diff ELSE 0 END),
				(4, 'LACVASSET',                   @AssetGL,0, @Cost),
				(5, 'LACVGAINONCONVERSION',        @GainGL, 0, CASE WHEN @Diff > 0 THEN @Diff ELSE 0 END);
			DELETE FROM #JeLines WHERE [Amount] <= 0;

			DECLARE @TotalDr DECIMAL(18, 2), @TotalCr DECIMAL(18, 2);
			SELECT @TotalDr = ISNULL(SUM(CASE WHEN [IsDebit] = 1 THEN [Amount] END), 0), @TotalCr = ISNULL(SUM(CASE WHEN [IsDebit] = 0 THEN [Amount] END), 0) FROM #JeLines;
			IF @TotalDr <> @TotalCr
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT CAST(0 AS INT) AS [Status], 'The conversion journal is not balanced (Dr ' + CAST(@TotalDr AS VARCHAR(30)) + ' / Cr ' + CAST(@TotalCr AS VARCHAR(30)) + '). Nothing was converted.' AS [Message],
				       CAST(NULL AS BIGINT) AS [NewStockLineId], CAST(NULL AS VARCHAR(100)) AS [NewStockLineNumber], @Diff AS [ValueOverNBV], @GainLoss AS [GainLossType], CAST(NULL AS VARCHAR(100)) AS [BatchName], CAST(NULL AS VARCHAR(100)) AS [JournalTypeNumber];
				RETURN;
			END

			IF EXISTS (SELECT 1 FROM #JeLines)
			BEGIN
				INSERT INTO dbo.BatchDetails
					([JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],[EntryDate],
					 [JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],
					 [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
				SELECT TOP 1 @JournalTypeNumber, @JeNo, S.[ID], S.[Name], @JournalBatchHeaderId, @LineNo, L.[GlAccountId], GL.[AccountCode], GL.[AccountName], @ConversionDate, GETUTCDATE(),
					 @JournalTypeId, @JournalTypeName, L.[IsDebit], 0, 0, @ManagementStructureId, 'LEASEASSETCONVERSION', @LastMSLevel, @AllMSlevels,
					 @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @AccountingCalendarId, @AccountingPeriod
				FROM #JeLines L
					INNER JOIN dbo.DistributionSetup S WITH (NOLOCK) ON S.[DistributionMasterId] = @DistributionMasterId AND S.[MasterCompanyId] = @MasterCompanyId AND S.[DistributionSetupCode] = L.[Code] AND ISNULL(S.[IsDeleted], 0) = 0
					LEFT JOIN dbo.GLAccount GL WITH (NOLOCK) ON GL.[GLAccountId] = L.[GlAccountId]
				ORDER BY L.[Seq];
				SET @JournalBatchDetailId = SCOPE_IDENTITY();

				DECLARE @CommonId BIGINT, @LSeq INT, @LCode VARCHAR(100), @LGl BIGINT, @LDr BIT, @LAmt DECIMAL(18, 2),
				        @InvPartNumber NVARCHAR(250), @SetupId BIGINT, @SetupName VARCHAR(200), @GlNumber VARCHAR(200), @GlName VARCHAR(200), @InvDesc NVARCHAR(500);
				SELECT @InvPartNumber = IM.[partnumber] FROM dbo.ItemMaster IM WITH (NOLOCK) WHERE IM.[ItemMasterId] = @InvItemMasterId; -- all journal lines link to the NEW inventory stockline
				SET @InvDesc = 'Converted leased asset STK-' + ISNULL(@SrcStockLineNumber, '') + ' to inventory STK-' + ISNULL(@NewStockLineNumber, '') + '  PN-' + ISNULL(@SrcPartNumber, '');

				DECLARE JeCursor CURSOR LOCAL FAST_FORWARD FOR SELECT [Seq], [Code], [GlAccountId], [IsDebit], [Amount] FROM #JeLines ORDER BY [Seq];
				OPEN JeCursor;
				FETCH NEXT FROM JeCursor INTO @LSeq, @LCode, @LGl, @LDr, @LAmt;
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SELECT @SetupId = S.[ID], @SetupName = S.[Name] FROM dbo.DistributionSetup S WITH (NOLOCK)
					WHERE S.[DistributionMasterId] = @DistributionMasterId AND S.[MasterCompanyId] = @MasterCompanyId AND S.[DistributionSetupCode] = @LCode AND ISNULL(S.[IsDeleted], 0) = 0;
					SELECT @GlNumber = GL.[AccountCode], @GlName = GL.[AccountName] FROM dbo.GLAccount GL WITH (NOLOCK) WHERE GL.[GLAccountId] = @LGl;

					INSERT INTO dbo.CommonBatchDetails
						([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],[EntryDate],
						 [JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],
						 [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
					VALUES
						(@JournalBatchDetailId, @JournalTypeNumber, @JeNo, @SetupId, @SetupName, @JournalBatchHeaderId, @LineNo, @LGl, @GlNumber, @GlName, @ConversionDate, GETUTCDATE(),
						 @JournalTypeId, @JournalTypeName, @LDr, CASE WHEN @LDr = 1 THEN @LAmt ELSE 0 END, CASE WHEN @LDr = 1 THEN 0 ELSE @LAmt END, @ManagementStructureId, 'LEASEASSETCONVERSION', @LastMSLevel, @AllMSlevels,
						 @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);
					SET @CommonId = SCOPE_IDENTITY();

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy, @AccountMSModuleId, 1;

					INSERT INTO dbo.StocklineBatchDetails
						([JournalBatchDetailId],[JournalBatchHeaderId],[ItemMasterId],[PartNumber],[StocklineId],[StocklineNumber],[Consignment],[Description],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId, @JournalBatchHeaderId, @InvItemMasterId, @InvPartNumber, @NewStocklineId, @NewStockLineNumber, '', @InvDesc, 'STOCK', @CommonId); -- STOCK : management structure of a Stockline (StocklineManagementStructureDetails) is shown in the journal popup

					FETCH NEXT FROM JeCursor INTO @LSeq, @LCode, @LGl, @LDr, @LAmt;
				END
				CLOSE JeCursor;
				DEALLOCATE JeCursor;

				UPDATE BD SET BD.[DebitAmount] = T.[Dr], BD.[CreditAmount] = T.[Cr], BD.[UpdatedDate] = GETUTCDATE(), BD.[UpdatedBy] = @UpdatedBy
				FROM dbo.BatchDetails BD
				CROSS APPLY (SELECT SUM(C.[DebitAmount]) AS [Dr], SUM(C.[CreditAmount]) AS [Cr] FROM dbo.CommonBatchDetails C WITH (NOLOCK) WHERE C.[JournalBatchDetailId] = BD.[JournalBatchDetailId]) T
				WHERE BD.[JournalBatchDetailId] = @JournalBatchDetailId;

				UPDATE BH SET BH.[TotalDebit] = T.[Dr], BH.[TotalCredit] = T.[Cr], BH.[TotalBalance] = T.[Dr] - T.[Cr], BH.[UpdatedDate] = GETUTCDATE(), BH.[UpdatedBy] = @UpdatedBy
				FROM dbo.BatchHeader BH
				CROSS APPLY (SELECT ISNULL(SUM(D.[DebitAmount]), 0) AS [Dr], ISNULL(SUM(D.[CreditAmount]), 0) AS [Cr] FROM dbo.BatchDetails D WITH (NOLOCK) WHERE D.[JournalBatchHeaderId] = BH.[JournalBatchHeaderId] AND ISNULL(D.[IsDeleted], 0) = 0) T
				WHERE BH.[JournalBatchHeaderId] = @JournalBatchHeaderId;
			END
		END

		/* ---------- 5. conversion record + stockline history ---------- */
		INSERT INTO dbo.StocklineAssetConversion
			([SourceStockLineId],[SourceStockLineNumber],[SourceItemMasterId],[SourcePartNumber],[BaseNum],[PNType],[NewStockLineId],[NewStockLineNumber],[NewItemMasterId],[NewPartNumber],
			 [ConversionDate],[AccountingCalendarId],[AccountingPeriod],[Cost],[AccumulatedDepr],[NetBookValue],[TransferValue],[ValueOverNBV],[GainLossType],
			 [JournalBatchHeaderId],[JournalBatchDetailId],[JournalTypeNumber],[Memo],[LegalEntityId],[ManagementStructureId],
			 [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
		SELECT @StockLineId, @SrcStockLineNumber, @SrcItemMasterId, @SrcPartNumber, @BaseNum, @PNType, @NewStocklineId, @NewStockLineNumber, @InvItemMasterId, IM.[partnumber],
			 @ConversionDate, @AccountingCalendarId, @AccountingPeriod, @Cost, @AD, @NBV, @Transfer, @Diff, @GainLoss,
			 @JournalBatchHeaderId, @JournalBatchDetailId, @JournalTypeNumber, @Memo, @LegalEntityId, @ManagementStructureId,
			 @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0
		FROM dbo.ItemMaster IM WITH (NOLOCK) WHERE IM.[ItemMasterId] = @InvItemMasterId;

		DECLARE @HistoryActionId INT = NULL;
		SELECT @StockLineModuleId = [ModuleId] FROM dbo.Module WITH (NOLOCK) WHERE [ModuleName] = 'StockLine';
		SELECT TOP 1 @HistoryActionId = [ActionId] FROM dbo.StklineHistory_Action WITH (NOLOCK) WHERE [Type] = 'ConvertToInventory';
		IF (@HistoryActionId IS NOT NULL)
		BEGIN
			EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StockLineId, @ModuleId = @StockLineModuleId, @ReferenceId = @NewStocklineId,
				 @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @HistoryActionId, @Qty = @Qty, @UpdatedBy = @UpdatedBy;
			EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @NewStocklineId, @ModuleId = @StockLineModuleId, @ReferenceId = @StockLineId,
				 @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @HistoryActionId, @Qty = @Qty, @UpdatedBy = @UpdatedBy;
		END

		COMMIT TRANSACTION;

		SELECT CAST(1 AS INT) AS [Status],
		       'Asset converted to inventory successfully. New stockline ' + ISNULL(@NewStockLineNumber, '') + CASE WHEN @JournalTypeNumber IS NOT NULL THEN ', journal ' + @JournalTypeNumber ELSE '' END + '.' AS [Message],
		       @NewStocklineId AS [NewStockLineId], @NewStockLineNumber AS [NewStockLineNumber], @Diff AS [ValueOverNBV], @GainLoss AS [GainLossType],
		       @BatchName AS [BatchName], @JournalTypeNumber AS [JournalTypeNumber];
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_ConvertStocklineAssetToInventory',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)) + ''', @TransferValue = ''' + CAST(ISNULL(@TransferValue, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END
