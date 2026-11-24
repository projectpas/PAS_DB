/*************************************************************
 ** File:   [USP_AddReceivingStocklineTimeCycle]
 ** Description: [PN-18605] PO Receiving - the Time / Cycles entered for the MAIN part on the Receiving PO screen (TimeLifeDraft :
                 Cycles Since New / Since Ovh, Time Since New / Since Ovh, 'HH:MM') are also stored in StocklineTimeCycleHistory and on the Stockline,
                 the same way as for the Sub Component stocklines (USP_CreateSubComponentStocklinesForReceiving) :
                   - one StocklineTimeCycleHistory row (Module = Receiving PO, EntryType 'Receiving', Hours / Minutes / Cycles = Since New entry,
                     TotalTSN / TotalTSNMM / TotalCSN = Since New, TotalTSO / TotalTSOMM / TotalCSO = Since Ovh)
                   - Stockline.TotalTSN / TotalTSNMM / TotalCSN / TotalCSNMM / TotalTSO / TotalTSOMM / TotalCSO are set to the same values
                 Nothing is written when no Time / Cycle value is entered (all 0 / blank). The TimeLife row is created by the caller as before.
                 Caller owns the transaction (called from USP_CreateStocklineForReceivingPO). No result set is returned.
 ** Date:   19-NOV-2026
 ** Author:  Kishor Makwana
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    19-NOV-2026  Kishor Makwana    [PN-18605] Created

-- EXEC [dbo].[USP_AddReceivingStocklineTimeCycle] @StocklineId = 1, @StockLineDraftId = 1, @PurchaseOrderId = 1, @MasterCompanyId = 1, @UpdatedBy = 'admin'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddReceivingStocklineTimeCycle]
	@StocklineId BIGINT,
	@StockLineDraftId BIGINT,
	@PurchaseOrderId BIGINT,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @CsnTxt VARCHAR(20), @CsoTxt VARCHAR(20), @TsnTxt VARCHAR(20), @TsoTxt VARCHAR(20);

	SELECT TOP 1 @CsnTxt = LTRIM(RTRIM(ISNULL([CyclesSinceNew], ''))), @CsoTxt = LTRIM(RTRIM(ISNULL([CyclesSinceOVH], ''))),
				 @TsnTxt = LTRIM(RTRIM(ISNULL([TimeSinceNew], ''))), @TsoTxt = LTRIM(RTRIM(ISNULL([TimeSinceOVH], '')))
	FROM [dbo].[TimeLifeDraft] WITH (NOLOCK)
	WHERE [StockLineDraftId] = @StockLineDraftId
	ORDER BY [TimeLifeDraftCyclesId] DESC;

	IF (@@ROWCOUNT = 0)
		RETURN;

	-- cycles : plain number (thousand separators removed); time : 'HH:MM' (hours may have thousand separators)
	DECLARE @Csn DECIMAL(18, 6) = ISNULL(TRY_CAST(REPLACE(@CsnTxt, ',', '') AS DECIMAL(18, 6)), 0),
			@Cso DECIMAL(18, 6) = ISNULL(TRY_CAST(REPLACE(@CsoTxt, ',', '') AS DECIMAL(18, 6)), 0),
			@TsnH DECIMAL(18, 6) = ISNULL(TRY_CAST(REPLACE(LEFT(@TsnTxt, CHARINDEX(':', @TsnTxt + ':') - 1), ',', '') AS DECIMAL(18, 6)), 0),
			@TsnM DECIMAL(18, 6) = ISNULL(TRY_CAST(SUBSTRING(@TsnTxt, CHARINDEX(':', @TsnTxt + ':') + 1, 10) AS DECIMAL(18, 6)), 0),
			@TsoH DECIMAL(18, 6) = ISNULL(TRY_CAST(REPLACE(LEFT(@TsoTxt, CHARINDEX(':', @TsoTxt + ':') - 1), ',', '') AS DECIMAL(18, 6)), 0),
			@TsoM DECIMAL(18, 6) = ISNULL(TRY_CAST(SUBSTRING(@TsoTxt, CHARINDEX(':', @TsoTxt + ':') + 1, 10) AS DECIMAL(18, 6)), 0);

	-- minutes are kept below 60 (same as Stockline.TotalTSNMM / TotalTSOMM)
	SELECT @TsnH = @TsnH + FLOOR(@TsnM / 60), @TsnM = @TsnM - FLOOR(@TsnM / 60) * 60,
		   @TsoH = @TsoH + FLOOR(@TsoM / 60), @TsoM = @TsoM - FLOOR(@TsoM / 60) * 60;

	IF (@Csn = 0 AND @Cso = 0 AND @TsnH = 0 AND @TsnM = 0 AND @TsoH = 0 AND @TsoM = 0)
		RETURN;

	DECLARE @PONumber VARCHAR(100), @ReceivingPOModuleId BIGINT = 28; -- 28 = Receiving Purchase Order
	SELECT @PONumber = [PurchaseOrderNumber] FROM [dbo].[PurchaseOrder] WITH (NOLOCK) WHERE [PurchaseOrderId] = @PurchaseOrderId;

	INSERT INTO [dbo].[StocklineTimeCycleHistory]
		([StocklineId], [ModuleId], [ReferenceId], [ReferenceNumber], [SubModuleId], [SubReferenceId], [SubReferenceNumber], [EntryType], [EntryDate],
		 [Hours], [Minutes], [Cycles], [TotalTSN], [TotalTSNMM], [TotalCSN], [TotalTSO], [TotalTSOMM], [TotalCSO], [Memo],
		 [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [ParentStocklineId])
	VALUES
		(@StocklineId, @ReceivingPOModuleId, @PurchaseOrderId, @PONumber, NULL, NULL, NULL, 'Receiving', GETUTCDATE(),
		 @TsnH, @TsnM, @Csn, @TsnH, @TsnM, @Csn, @TsoH, @TsoM, @Cso,
		 N'Time / Cycle entered at PO Receiving',
		 @MasterCompanyId, @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0, NULL);

	UPDATE [dbo].[Stockline]
	SET [TotalTSN] = @TsnH, [TotalTSNMM] = @TsnM, [TotalCSN] = @Csn, [TotalCSNMM] = 0, [TotalTSO] = @TsoH, [TotalTSOMM] = @TsoM, [TotalCSO] = @Cso,
		[UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
	WHERE [StockLineId] = @StocklineId;
END
