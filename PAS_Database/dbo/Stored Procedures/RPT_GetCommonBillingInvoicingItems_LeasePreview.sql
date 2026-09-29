/*************************************************************
 ** File:   [RPT_GetCommonBillingInvoicingItems_LeasePreview]
 ** Author:  Kishor Makwana
 ** Description: Live PRE-COMMIT preview of the Lease Invoice line-item grid for the
 **              LeaseBilling.rdl report (PN-18072 follow-up: "First we need to allow
 **              to preview the invoice then user will generate the invoice"). 
 ** Date:   25/SEP/2026
 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    25/09/2026   Kishor Makwana	CREATED [PN-18072] pre-commit invoice preview
    2    28/09/2026   Kishor Makwana	[PN-17949 follow-up] Added 'Time Usage'/'Cycle Usage' line items (billed at UsagePerUnitTimes/Cycles, base units = MAX(Minimum, MIN(Recorded, Maximum))) -
										previously only the 'Time Overrun'/'Cycle Overrun' lines existed, so usage inside the Min/Max range never appeared or billed at all. Also tightened the Overrun lines
										to only show when there's an actual overage (> 0, not just IS NOT NULL, which included a lot of pointless zero-value rows), and updated the fallback row's
										exclusion filter to match. Same fix as USP_CreateLeaseBillingInvoice/ USP_GetLeaseBillingListByLeaseHeaderId/RPT_GetCommonBillingInvoicingPdfData_LeasePreview.
    
--   EXEC [dbo].[RPT_GetCommonBillingInvoicingItems_LeasePreview] @LeaseHeaderId = 1, @LeaseStocklineIds = '1,2,3'
********************************************************************************************/
CREATE     PROCEDURE [dbo].[RPT_GetCommonBillingInvoicingItems_LeasePreview]
	@LeaseHeaderId BIGINT = NULL,
	@LeaseStocklineIds VARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		;WITH SelectedIds AS (
			SELECT DISTINCT CAST(Item AS BIGINT) AS LeaseStocklineId
			FROM [dbo].[SplitString](@LeaseStocklineIds, ',')
			WHERE ISNUMERIC(Item) = 1
		),
		Base AS (
			SELECT
				LSL.[LeaseStocklineId],
				LSL.[ItemMasterId],
				UPPER(ISNULL(LSL.[PN], '')) AS PNumber,
				UPPER(ISNULL(LSL.[PNDescription], '')) AS PNDescription,
				UPPER(COALESCE(STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber,
				UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
				LSL.[BillingMethod],
				LSL.[FlatRate],
				UPPER(COALESCE(IM.[ConsumeUnitOfMeasure], IM.[StockUnitOfMeasure], '')) AS UOM,
				LSL.[QtyReserved] AS Qty,
				CASE WHEN U.LeaseStocklineUsageId IS NOT NULL
					 THEN ISNULL(U.CurrentTSNHours, 0) * 60 + ISNULL(U.CurrentTSNMinutes, 0)
					 ELSE NULL END AS TimeRecorded,
				CASE WHEN LSL.MaximumTimes IS NOT NULL THEN LSL.MaximumTimes * 60 ELSE NULL END AS TimeLimit,
				CASE WHEN LSL.MinimumTimes IS NOT NULL THEN LSL.MinimumTimes * 60 ELSE NULL END AS TimeMinimum,
				LSL.UsagePerUnitTimes AS TimeUsageRateRaw,
				LSL.OverrunPerUnitTimes AS TimeOverageRateRaw,
				U.CurrentCSN AS CycleRecorded,
				LSL.MaximumCycles AS CycleLimit,
				LSL.MinimumCycles AS CycleMinimum,
				LSL.UsagePerUnitCycles AS CycleUsageRateRaw,
				LSL.OverrunPerUnitCycles AS CycleOverageRateRaw,
				ISNULL(ChargesAgg.Charges, 0) AS Charges,
				LSL.[Maintenance],
				LSL.[Insurance],
				LSL.[Taxes],
				ISNULL(SC_SUM.OtherComponentAmount, 0) AS OtherComponentAmount
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			INNER JOIN SelectedIds SEL ON SEL.LeaseStocklineId = LSL.LeaseStocklineId
			LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.StockLineId = LSL.StockLineId
			LEFT JOIN [dbo].[LeaseStocklineUsage] U WITH (NOLOCK) ON U.LeaseStocklineId = LSL.LeaseStocklineId AND U.IsDeleted = 0
			LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = LSL.ItemMasterId
			OUTER APPLY (
				SELECT SUM(ISNULL(LC.ExtendedCost, 0)) AS Charges
				FROM [dbo].[LeaseCharges] LC WITH (NOLOCK)
				WHERE LC.LeaseStocklineId = LSL.LeaseStocklineId AND LC.IsDeleted = 0
			) ChargesAgg
			LEFT JOIN (
				SELECT LeaseStocklineId, SUM(ISNULL(Amount, 0)) AS OtherComponentAmount
				FROM [dbo].[LeaseStocklineServiceComponent] WITH (NOLOCK)
				WHERE IsDeleted = 0
				GROUP BY LeaseStocklineId
			) SC_SUM ON SC_SUM.LeaseStocklineId = LSL.LeaseStocklineId
			WHERE LSL.LeaseHeaderId = @LeaseHeaderId
			  AND LSL.IsDeleted = 0
			  AND LSL.QtyReserved > 0
		),
		WithOver AS (
			SELECT *,
				IsOverageBillingMethod = CASE WHEN BillingMethod IN ('FlatRatePlusOverrun', 'UsageBased') THEN 1 ELSE 0 END,
				IsFlatRateBillingMethod = CASE WHEN BillingMethod IN ('FlatRateOnly', 'FlatRatePlusOverrun') THEN 1 ELSE 0 END,
				TimeOverRaw = CASE WHEN TimeRecorded IS NOT NULL THEN
					CASE WHEN TimeLimit IS NOT NULL AND TimeRecorded > TimeLimit THEN TimeRecorded - TimeLimit ELSE 0 END
				ELSE NULL END,
				TimeBilledBaseRaw = CASE WHEN TimeRecorded IS NOT NULL THEN
					CASE WHEN TimeLimit IS NOT NULL AND TimeRecorded > TimeLimit THEN TimeLimit
						 WHEN TimeRecorded < ISNULL(TimeMinimum, 0) THEN ISNULL(TimeMinimum, 0)
						 ELSE TimeRecorded END
				ELSE NULL END,
				CycleOverRaw = CASE WHEN CycleRecorded IS NOT NULL THEN
					CASE WHEN CycleLimit IS NOT NULL AND CycleRecorded > CycleLimit THEN CycleRecorded - CycleLimit ELSE 0 END
				ELSE NULL END,
				CycleBilledBaseRaw = CASE WHEN CycleRecorded IS NOT NULL THEN
					CASE WHEN CycleLimit IS NOT NULL AND CycleRecorded > CycleLimit THEN CycleLimit
						 WHEN CycleRecorded < ISNULL(CycleMinimum, 0) THEN ISNULL(CycleMinimum, 0)
						 ELSE CycleRecorded END
				ELSE NULL END
			FROM Base
		),
		Lines AS (
			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Flat Rate' AS LineBillingMethod,
				CAST(Qty AS DECIMAL(18,6)) AS LineQty,
				ISNULL(FlatRate, 0) AS LineUnitPrice,
				ISNULL(FlatRate, 0) * Qty AS LineTotal,
				1 AS SortOrder
			FROM WithOver WHERE IsFlatRateBillingMethod = 1

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Time Usage' AS LineBillingMethod,
				CAST(TimeBilledBaseRaw / 60.0 AS DECIMAL(18,6)) AS LineQty,
				ISNULL(TimeUsageRateRaw, 0) AS LineUnitPrice,
				(TimeBilledBaseRaw / 60.0) * ISNULL(TimeUsageRateRaw, 0) * Qty AS LineTotal,
				2 AS SortOrder
			FROM WithOver WHERE IsOverageBillingMethod = 1 AND TimeBilledBaseRaw IS NOT NULL AND TimeBilledBaseRaw > 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Time Overrun' AS LineBillingMethod,
				CAST(TimeOverRaw / 60.0 AS DECIMAL(18,6)) AS LineQty,
				ISNULL(TimeOverageRateRaw, 0) AS LineUnitPrice,
				(TimeOverRaw / 60.0) * ISNULL(TimeOverageRateRaw, 0) * Qty AS LineTotal,
				3 AS SortOrder
			FROM WithOver WHERE IsOverageBillingMethod = 1 AND TimeOverRaw IS NOT NULL AND TimeOverRaw > 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Cycle Usage' AS LineBillingMethod,
				CAST(CycleBilledBaseRaw AS DECIMAL(18,6)) AS LineQty,
				ISNULL(CycleUsageRateRaw, 0) AS LineUnitPrice,
				CycleBilledBaseRaw * ISNULL(CycleUsageRateRaw, 0) * Qty AS LineTotal,
				4 AS SortOrder
			FROM WithOver WHERE IsOverageBillingMethod = 1 AND CycleBilledBaseRaw IS NOT NULL AND CycleBilledBaseRaw > 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Cycle Overrun' AS LineBillingMethod,
				CAST(CycleOverRaw AS DECIMAL(18,6)) AS LineQty,
				ISNULL(CycleOverageRateRaw, 0) AS LineUnitPrice,
				CycleOverRaw * ISNULL(CycleOverageRateRaw, 0) * Qty AS LineTotal,
				5 AS SortOrder
			FROM WithOver WHERE IsOverageBillingMethod = 1 AND CycleOverRaw IS NOT NULL AND CycleOverRaw > 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Maintenance' AS LineBillingMethod,
				CAST(1 AS DECIMAL(18,6)) AS LineQty,
				ISNULL(Maintenance, 0) AS LineUnitPrice,
				ISNULL(Maintenance, 0) AS LineTotal,
				6 AS SortOrder
			FROM WithOver WHERE ISNULL(Maintenance, 0) > 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Insurance' AS LineBillingMethod,
				CAST(1 AS DECIMAL(18,6)) AS LineQty,
				ISNULL(Insurance, 0) AS LineUnitPrice,
				ISNULL(Insurance, 0) AS LineTotal,
				7 AS SortOrder
			FROM WithOver WHERE ISNULL(Insurance, 0) > 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Taxes' AS LineBillingMethod,
				CAST(1 AS DECIMAL(18,6)) AS LineQty,
				ISNULL(Taxes, 0) AS LineUnitPrice,
				ISNULL(Taxes, 0) AS LineTotal,
				8 AS SortOrder
			FROM WithOver WHERE ISNULL(Taxes, 0) > 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Other' AS LineBillingMethod,
				CAST(1 AS DECIMAL(18,6)) AS LineQty,
				ISNULL(OtherComponentAmount, 0) AS LineUnitPrice,
				ISNULL(OtherComponentAmount, 0) AS LineTotal,
				9 AS SortOrder
			FROM WithOver WHERE ISNULL(OtherComponentAmount, 0) > 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Charges' AS LineBillingMethod,
				CAST(1 AS DECIMAL(18,6)) AS LineQty,
				ISNULL(Charges, 0) AS LineUnitPrice,
				ISNULL(Charges, 0) AS LineTotal,
				10 AS SortOrder
			FROM WithOver WHERE ISNULL(Charges, 0) > 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				CASE BillingMethod
					WHEN 'FlatRateOnly' THEN 'Flat Rate Only'
					WHEN 'FlatRatePlusOverrun' THEN 'Flat Rate + Overrun'
					WHEN 'UsageBased' THEN 'Usage Based'
					ELSE ISNULL(BillingMethod, '')
				END AS LineBillingMethod,
				CAST(Qty AS DECIMAL(18,6)) AS LineQty,
				CAST(0 AS DECIMAL(18,6)) AS LineUnitPrice,
				CAST(0 AS DECIMAL(18,6)) AS LineTotal,
				0 AS SortOrder
			FROM WithOver
			WHERE IsFlatRateBillingMethod = 0
			  AND NOT (IsOverageBillingMethod = 1 AND TimeBilledBaseRaw IS NOT NULL AND TimeBilledBaseRaw > 0)
			  AND NOT (IsOverageBillingMethod = 1 AND TimeOverRaw IS NOT NULL AND TimeOverRaw > 0)
			  AND NOT (IsOverageBillingMethod = 1 AND CycleBilledBaseRaw IS NOT NULL AND CycleBilledBaseRaw > 0)
			  AND NOT (IsOverageBillingMethod = 1 AND CycleOverRaw IS NOT NULL AND CycleOverRaw > 0)
		)
		SELECT
				ROW_NUMBER() OVER (ORDER BY LeaseStocklineId, SortOrder) AS ItemNo,
				CAST(NULL AS BIGINT) AS [BillingInvoicingItemId],
				CAST(NULL AS BIGINT) AS [BillingInvoicingId],
				LeaseStocklineId AS SubReferenceId,
				ItemMasterId,
				PNumber,
				PNDescription,
				SerialNumber,
				StockLineNumber,
				LineBillingMethod AS BillingMethod,
				UOM,
				LineQty AS Qty,
				LineUnitPrice AS UnitPrice,
				LineTotal AS Total
			FROM Lines
			ORDER BY LeaseStocklineId, SortOrder;

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCommonBillingInvoicingItems_LeasePreview'
			  , @ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH
END