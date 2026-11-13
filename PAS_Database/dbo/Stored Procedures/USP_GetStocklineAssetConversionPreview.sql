/*************************************************************
 ** File:   [USP_GetStocklineAssetConversionPreview]
 ** Description: PN-18535 Convert to Inventory popup (Stockline List > Asset > Actions). One row with the values of the leased asset stockline :
 **              PN, Base Num, PN Type (read-only), Cost (Stockline.AssetTotalCost), AD (Accumulated Depr of the last depreciation run), NBV = Cost - AD,
 **              Transfer Value (defaults to NBV, the user can change it on the screen), the Inventory PN the asset converts to (Item Master
 **              AssetInventoryItemMasterId / stockline value, else the same PN), the accounting period of the conversion date.
 **              IsConvertible = 0 + BlockReason when the conversion is not allowed :
 **                not a lease asset, already converted, no quantity on hand, still on a Draft / Active lease (lease status enum 1 = Draft, 2 = Active, 3 = Closed), accounting period (Asset / Inventory) closed or missing.
 **              The same rules are checked again by USP_ConvertStocklineAssetToInventory.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date            Author          Change Description
 ** --   --------        -------         --------------------------------
    1    12/November/2026 Kishor Makwana  [PN-18535] Created
 -- EXEC [dbo].[USP_GetStocklineAssetConversionPreview] @StockLineId = 1, @MasterCompanyId = 1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetStocklineAssetConversionPreview]
	@StockLineId     BIGINT,
	@MasterCompanyId INT,
	@ConversionDate  DATETIME2(7) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY
		SET @ConversionDate = ISNULL(@ConversionDate, SYSUTCDATETIME());

		DECLARE @LegalEntityId BIGINT, @Found BIT = 0;
		SELECT @Found = 1, @LegalEntityId = STK.[LegalEntityId]
		FROM dbo.Stockline STK WITH (NOLOCK)
		WHERE STK.[StockLineId] = @StockLineId AND STK.[MasterCompanyId] = @MasterCompanyId AND ISNULL(STK.[isDeleted], 0) = 0;

		-- accounting period of the conversion date (Asset and Inventory sub ledgers must be open)
		DECLARE @AccountingCalendarId BIGINT, @AccountingPeriod VARCHAR(100), @IsPeriodOpen BIT = 0;
		SELECT TOP 1 @AccountingCalendarId = AC.[AccountingCalendarId], @AccountingPeriod = AC.[PeriodName],
		       @IsPeriodOpen = CASE WHEN ISNULL(AC.[isassetStatusName], 0) = 1 AND ISNULL(AC.[isinventoryStatusName], 0) = 1 THEN 1 ELSE 0 END
		FROM dbo.AccountingCalendar AC WITH (NOLOCK)
		WHERE AC.[MasterCompanyId] = @MasterCompanyId AND ISNULL(AC.[IsDeleted], 0) = 0 AND AC.[LegalEntityId] = @LegalEntityId
		  AND CAST(@ConversionDate AS DATE) >= AC.[FromDate] AND CAST(@ConversionDate AS DATE) <= AC.[ToDate]
		ORDER BY ISNULL(AC.[IsAdjustPeriod], 0), AC.[AccountingCalendarId];

		SELECT
			STK.[StockLineId],
			STK.[StockLineNumber],
			STK.[PartNumber],
			STK.[PNDescription]												AS [PartDescription],
			CASE WHEN ISNULL(STK.[AssetInventoryNumber], '') <> '' THEN STK.[AssetInventoryNumber] ELSE STK.[StockLineNumber] END AS [BaseNum],
			ITP.[Name]														AS [PNType],
			STK.[ItemMasterId],
			INV.[ItemMasterId]												AS [InventoryItemMasterId],
			INV.[partnumber]												AS [InventoryPartNumber],
			ISNULL(STK.[QuantityOnHand], ISNULL(STK.[Quantity], 0))			AS [Quantity],
			CAST(ISNULL(STK.[AssetTotalCost], 0) AS DECIMAL(18, 2))			AS [Cost],
			CAST(ISNULL(LH.[AccumulatedDepr], 0) AS DECIMAL(18, 2))			AS [AccumulatedDepr],
			CAST(ISNULL(STK.[AssetTotalCost], 0) - ISNULL(LH.[AccumulatedDepr], 0) AS DECIMAL(18, 2)) AS [NetBookValue],
			CAST(ISNULL(STK.[AssetTotalCost], 0) - ISNULL(LH.[AccumulatedDepr], 0) AS DECIMAL(18, 2)) AS [TransferValue],
			CAST(0 AS DECIMAL(18, 2))										AS [ValueOverNBV],
			@ConversionDate													AS [ConversionDate],
			@AccountingCalendarId											AS [AccountingCalendarId],
			@AccountingPeriod												AS [AccountingPeriod],
			CAST(CASE WHEN Chk.[BlockReason] IS NULL THEN 1 ELSE 0 END AS BIT) AS [IsConvertible],
			Chk.[BlockReason]
		FROM dbo.Stockline STK WITH (NOLOCK)
			LEFT JOIN dbo.ItemType ITP WITH (NOLOCK) ON ITP.[ItemTypeId] = STK.[ItemTypeId]
			LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.[ItemMasterId] = STK.[ItemMasterId]
			LEFT JOIN dbo.ItemMaster INV WITH (NOLOCK) ON INV.[ItemMasterId] = COALESCE(NULLIF(STK.[AssetInventoryItemMasterId], 0), NULLIF(IM.[AssetInventoryItemMasterId], 0), STK.[ItemMasterId])
			OUTER APPLY (
				SELECT TOP 1 H.[AccumulatedDepr]
				FROM dbo.StocklineAssetDepreciationHistory H WITH (NOLOCK)
				WHERE H.[StockLineId] = STK.[StockLineId] AND H.[IsDeleted] = 0
				ORDER BY H.[StocklineAssetDepreciationHistoryId] DESC
			) LH
			CROSS APPLY (
				SELECT CASE
					WHEN ISNULL(STK.[IsAsset], 0) = 0 OR ISNULL(STK.[IsLease], 0) = 0 THEN 'Only a leased asset can be converted to inventory.'
					WHEN STK.[ConvertedToStocklineId] IS NOT NULL THEN 'This asset is already converted to inventory.'
					WHEN ISNULL(STK.[QuantityOnHand], ISNULL(STK.[Quantity], 0)) <= 0 THEN 'The asset has no quantity on hand.'
					WHEN EXISTS (SELECT 1 FROM dbo.LeaseStockline LS WITH (NOLOCK)
					             INNER JOIN dbo.LeaseHeader LHD WITH (NOLOCK) ON LHD.[LeaseHeaderId] = LS.[LeaseHeaderId]
					             WHERE LS.[StockLineId] = STK.[StockLineId] AND ISNULL(LS.[IsDeleted], 0) = 0 AND ISNULL(LHD.[IsDeleted], 0) = 0
					               AND ISNULL(LS.[LeaseStatusId], LHD.[LeaseStatusId]) IN (1, 2)) -- Lease status enum : 1 = Draft, 2 = Active, 3 = Closed (no LeaseStatus table)
					     THEN 'The asset is on a Draft / Active lease. Close or remove it from the lease before converting it to inventory.'
					WHEN @AccountingCalendarId IS NULL THEN 'No accounting period found for the conversion date.'
					WHEN @IsPeriodOpen = 0 THEN 'The accounting period (' + ISNULL(@AccountingPeriod, '') + ') is closed for Asset / Inventory.'
					ELSE NULL END AS [BlockReason]
			) Chk
		WHERE STK.[StockLineId] = @StockLineId AND STK.[MasterCompanyId] = @MasterCompanyId AND ISNULL(STK.[isDeleted], 0) = 0;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
		        @AdhocComments VARCHAR(150) = 'USP_GetStocklineAssetConversionPreview',
		        @ProcedureParameters VARCHAR(3000) = '@StockLineId = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100)),
		        @ApplicationName VARCHAR(100) = 'PAS';
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters,
		     @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END