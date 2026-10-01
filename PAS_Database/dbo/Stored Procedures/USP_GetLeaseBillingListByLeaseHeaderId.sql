

/*************************************************************
 ** File:   [USP_GetLeaseBillingListByLeaseHeaderId]
 ** Description: Returns the Billing/Invoicing grid rows for a LeaseHeader (PN-17949 /
 **              PN-18072 multi-period follow-up). Two families of rows, both filtered
 **              client-side by BillingStatus (Angular's Pending/Invoiced radio):
 **
 **              PENDING rows (BillingStatus='N') are built per still-unbilled usage
 **              PERIOD, not per stockline. A "period" is one Time and/or Cycle entry
 **              pair in LeaseStocklineUsageHistory, paired by an identical CreatedDate
 **              (the same pairing USP_SaveLeaseStocklineUsage already guarantees for a
 **              single combined Save - see that proc's change #7). Each pending period
 **              produces exactly two rows: 'Flat Rate' (Flat Rate + this period's base
 **              Time/Cycle USAGE only, no overrun) and 'Overrun' (this period's Time/
 **              Cycle OVERRUN only, always emitted alongside Row 1). A stockline with
 **              several unbilled months (invoicing fell behind) gets one such pair per
 **              month, oldest first - "previous month pending" keeps showing instead of
 **              being silently replaced by the latest reading.
 **
 **              Maintenance/Insurance/Taxes/Other/Charges are billed ONCE per stockline,
 **              not per period - they show as their own one-time rows (LineType =
 **              'Maintenance'/'Insurance'/'Taxes'/'Others'/'Charges') as long as
 **              LeaseStockline.IsInvoicePost = 0 (flips to 1 the first time ANY invoice
 **              is created for that stockline - see USP_CreateLeaseBillingInvoice).


 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    17/09/2026     Kishor Makwana          [PN-17949] Created
	2    21/09/2026     Kishor Makwana          [PN-17949] UsageBased now bills the same way as FlatRatePlusOverrun (usage over the Limit x the Overage Rate) instead of always showing NA
	3    22/09/2026     Kishor Makwana          [PN-17949] Fixed Time/Cycle Over, Billing Amount and Total Billing Amount to match the requirements Excel - usage below the Limit now nets a negative (credit) amount instead of being suppressed to NA/0
	4    24/09/2026     Kishor Makwana          [PN-17949 follow-up] Optimized: (a) BillingInvoicingItems join had no IsDeleted filter and no guarantee of a single row per stockline - a stockline with more than one non-deleted
	                                            BillingInvoicingItems row (re-invoiced/revised) would silently duplicate that whole result row, double-counting its Charges/TotalBillingAmount in the grid's footer totals. Replaced
	                                            with an OUTER APPLY that deterministically picks just the most recent one (TOP 1 ORDER BY BillingInvoicingItemId DESC) and filters IsDeleted = 0. (b) Charges moved from a bare scalar
	                                            subquery in the SELECT list to an OUTER APPLY alongside it, same execution shape but clearer and pairs with the new supporting index (see PN-17949_Billing_List_Indexes.sql) that turns
	                                            both per-stockline lookups into index seeks instead of table scans. (c) Removed the redundant "AND BII.ModuleId = 72" repeated on the BillingInvoicing join (already filtered on the BillingInvoicingItems join it depends on).
	5    28/09/2026     Kishor Makwana          [PN-17949 follow-up] Added a FlatRate output column (the raw per-unit rate, gated the same way as FlatRateAmount) alongside the existing FlatRateAmount column - matches the pattern already used in USP_CreateLeaseBillingInvoice -
	                                            so it lines up with the LeaseBillingListItem.FlatRate API model property without touching FlatRateAmount. Previously there was no FlatRate output here at all, so the grid's new "Flat Rate" column always rendered blank.
	6    30/09/2026     Kishor Makwana          [PN-18072 multi-period follow-up] Customer requirement: Pending rows must reflect actual unbilled USAGE PERIODS (LeaseStocklineUsageHistory), not just a live current-reading
	                                            snapshot - a stockline with several months of unbilled usage now shows one row-pair per month instead of only the latest reading. Reworked around two new columns: LeaseStockline.
	                                            IsInvoicePost (gates the one-time Maintenance/Insurance/Taxes/Other/Charges rows - they bill once, ever, per stockline) and LeaseStocklineUsageHistory.IsInvoiced/BillingInvoicingItemId
	                                            (marks which specific Time/Cycle entries a given invoice already covered - see LeaseBilling_MultiPeriod_Schema.sql and the matching USP_CreateLeaseBillingInvoice rewrite). Replaced
	                                            LineDescription with LineType (kept the raw BillingMethod column UNCHANGED, still the stockline's configured FlatRateOnly/FlatRatePlusOverrun/UsageBased value, since
	                                            lease-billing-info.component.ts's isOverageBillingMethod() gates on that exact string - the new per-row label lives in LineType instead, shown in the grid's "Billing Method" column by
	                                            the Angular template, not by overloading the field the gating logic reads). Added FromDate/ToDate (sourced from the usage history entry's own From/To Date, already added to FieldMaster by
	                                            the customer). Base-vs-overrun is now a WATERFALL against the period's PRIOR reading (LAG over CreatedDate) rather than a single live snapshot, so a period that crosses the Maximum
	                                            Times/Cycles cap mid-period only bills the portion beyond it, and the Minimum-usage floor is applied only on a stockline's very first-ever period per type (a one-time opening guarantee,
	                                            not re-applied every period - flagged as an assumption since the customer's requirement did not spell this case out explicitly). Old single-snapshot TimeRecorded/CycleRecorded/
	                                            TimeUsageQty/CycleUsageQty logic (this file's own prior revision, PN-17949 follow-ups 2/3/6) is superseded by this period-aware version. Invoiced-tab rows are unchanged in shape from
	                                            change #6 (still one Flat Rate + Overrun pair per historical invoice item, from LeaseBillingInvoicingItemDetails) - only Pending rows were in scope for this pass.

exec USP_GetLeaseBillingListByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseBillingListByLeaseHeaderId]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		DECLARE @LeaseModuleId INT
		SELECT @LeaseModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Leasing';

		;WITH StocklineBase AS (
			SELECT
				LSL.LeaseStocklineId,
				LSL.PN AS PartNumber,
				LSL.PNDescription AS PartDescription,
				SLIVE.SerialNumber,
				LSL.QtyReserved AS Qty,
				LSL.BillingMethod,
				LSL.BillingInterval AS BillingFrequency,
				LSL.FlatRate,
				LSL.Maintenance,
				LSL.Insurance,
				LSL.Taxes,
				ISNULL(SC_SUM.OtherComponentAmount, 0) AS OtherComponentAmount,
				ISNULL(ChargesAgg.Charges, 0) AS Charges,
				CASE WHEN LSL.MaximumTimes IS NOT NULL THEN LSL.MaximumTimes * 60 ELSE NULL END AS TimeLimit,
				CASE WHEN LSL.MinimumTimes IS NOT NULL THEN LSL.MinimumTimes * 60 ELSE NULL END AS TimeMinimum,
				LSL.UsagePerUnitTimes,
				LSL.OverrunPerUnitTimes,
				LSL.MaximumCycles AS CycleLimit,
				LSL.MinimumCycles AS CycleMinimum,
				LSL.UsagePerUnitCycles,
				LSL.OverrunPerUnitCycles,
				LSL.IsInvoicePost,
				LSL.IsActive,
				LSL.LeaseStatusId,
				CASE WHEN LSL.BillingMethod IN ('FlatRatePlusOverrun', 'UsageBased') THEN 1 ELSE 0 END AS IsOverageBillingMethod,
				CASE WHEN LSL.BillingMethod IN ('FlatRateOnly', 'FlatRatePlusOverrun') THEN 1 ELSE 0 END AS IsFlatRateBillingMethod,
				CASE WHEN EXISTS (
					SELECT 1 FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
					WHERE H.LeaseStocklineId = LSL.LeaseStocklineId AND H.IsActive = 1 AND H.IsDeleted = 0
				) THEN 1 ELSE 0 END AS HasUsageInfo,
				BI.BillingInvoicingId,
				BI.InvoiceNo,
				BI.InvoiceDate
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
			OUTER APPLY (
				SELECT TOP (1) BII.BillingInvoicingId
				FROM [dbo].[BillingInvoicingItems] BII WITH (NOLOCK)
				WHERE BII.SubReferenceId = LSL.LeaseStocklineId AND BII.ModuleId = @LeaseModuleId AND BII.IsDeleted = 0
				ORDER BY BII.BillingInvoicingItemId DESC
			) LatestBII
			LEFT JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK) ON BI.BillingInvoicingId = LatestBII.BillingInvoicingId
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
		TimeSeries AS (
			SELECT
				H.LeaseStocklineId,
				H.LeaseStocklineUsageHistoryId,
				H.CreatedDate AS PeriodKey,
				H.FromDate,
				H.ToDate,
				H.IsInvoiced,
				(ISNULL(H.TSNHours, 0) * 60 + ISNULL(H.TSNMinutes, 0)) AS TimeReadingAbs,
				LAG(ISNULL(H.TSNHours, 0) * 60 + ISNULL(H.TSNMinutes, 0)) OVER (
					PARTITION BY H.LeaseStocklineId ORDER BY H.CreatedDate, H.LeaseStocklineUsageHistoryId
				) AS PriorTimeReadingAbs
			FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
			WHERE H.UsageType = 'T' AND H.IsActive = 1 AND H.IsDeleted = 0
		),
		CycleSeries AS (
			SELECT
				H.LeaseStocklineId,
				H.LeaseStocklineUsageHistoryId,
				H.CreatedDate AS PeriodKey,
				H.FromDate,
				H.ToDate,
				H.IsInvoiced,
				ISNULL(H.CSN, 0) AS CycleReadingAbs,
				LAG(ISNULL(H.CSN, 0)) OVER (
					PARTITION BY H.LeaseStocklineId ORDER BY H.CreatedDate, H.LeaseStocklineUsageHistoryId
				) AS PriorCycleReadingAbs
			FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
			WHERE H.UsageType = 'C' AND H.IsActive = 1 AND H.IsDeleted = 0
		),
		Periods AS (
			SELECT
				COALESCE(T.LeaseStocklineId, C.LeaseStocklineId) AS LeaseStocklineId,
				COALESCE(T.PeriodKey, C.PeriodKey) AS PeriodKey,
				COALESCE(T.FromDate, C.FromDate) AS PeriodFromDate,
				COALESCE(T.ToDate, C.ToDate) AS PeriodToDate,
				CASE WHEN T.PeriodKey IS NOT NULL AND ISNULL(T.IsInvoiced, 0) = 0 THEN 1 ELSE 0 END AS TimePending,
				T.TimeReadingAbs,
				T.PriorTimeReadingAbs,
				CASE WHEN C.PeriodKey IS NOT NULL AND ISNULL(C.IsInvoiced, 0) = 0 THEN 1 ELSE 0 END AS CyclePending,
				C.CycleReadingAbs,
				C.PriorCycleReadingAbs
			FROM TimeSeries T
			FULL OUTER JOIN CycleSeries C
				ON C.LeaseStocklineId = T.LeaseStocklineId AND C.PeriodKey = T.PeriodKey
		),
		PendingPeriodsJoined AS (
			SELECT
				P.LeaseStocklineId,
				P.PeriodKey,
				P.PeriodFromDate,
				P.PeriodToDate,
				P.TimePending,
				P.TimeReadingAbs,
				P.PriorTimeReadingAbs,
				P.CyclePending,
				P.CycleReadingAbs,
				P.PriorCycleReadingAbs,
				S.PartNumber,
				S.PartDescription,
				S.SerialNumber,
				S.Qty,
				S.BillingMethod,
				S.BillingFrequency,
				S.TimeLimit,
				S.TimeMinimum,
				S.UsagePerUnitTimes,
				S.OverrunPerUnitTimes,
				S.CycleLimit,
				S.CycleMinimum,
				S.UsagePerUnitCycles,
				S.OverrunPerUnitCycles,
				S.IsOverageBillingMethod,
				S.IsFlatRateBillingMethod,
				S.FlatRate,
				S.HasUsageInfo,
				S.IsActive,
				S.LeaseStatusId,
				S.BillingInvoicingId,
				S.InvoiceNo,
				S.InvoiceDate,
				ROW_NUMBER() OVER (PARTITION BY P.LeaseStocklineId ORDER BY P.PeriodKey) AS PeriodSeq
			FROM Periods P
			INNER JOIN StocklineBase S ON S.LeaseStocklineId = P.LeaseStocklineId
			WHERE P.TimePending = 1 OR P.CyclePending = 1
		),
		PeriodAmounts AS (
			SELECT
				LeaseStocklineId,
				PeriodKey,
				PeriodFromDate,
				PeriodToDate,
				TimePending,
				TimeReadingAbs,
				PriorTimeReadingAbs,
				CyclePending,
				CycleReadingAbs,
				PriorCycleReadingAbs,
				PartNumber,
				PartDescription,
				SerialNumber,
				Qty,
				BillingMethod,
				BillingFrequency,
				TimeLimit,
				TimeMinimum,
				UsagePerUnitTimes,
				OverrunPerUnitTimes,
				CycleLimit,
				CycleMinimum,
				UsagePerUnitCycles,
				OverrunPerUnitCycles,
				IsOverageBillingMethod,
				IsFlatRateBillingMethod,
				FlatRate,
				HasUsageInfo,
				IsActive,
				LeaseStatusId,
				BillingInvoicingId,
				InvoiceNo,
				InvoiceDate,
				PeriodSeq,
				ISNULL(PriorTimeReadingAbs, 0) AS TimePriorAbs,
				CASE WHEN TimePending = 1 AND PriorTimeReadingAbs IS NULL THEN 1 ELSE 0 END AS TimeIsFirstEver,
				ISNULL(PriorCycleReadingAbs, 0) AS CyclePriorAbs,
				CASE WHEN CyclePending = 1 AND PriorCycleReadingAbs IS NULL THEN 1 ELSE 0 END AS CycleIsFirstEver
			FROM PendingPeriodsJoined
		),

		PeriodAmounts2 AS (
			SELECT
				LeaseStocklineId,
				PeriodKey,
				PeriodFromDate,
				PeriodToDate,
				TimePending,
				TimeReadingAbs,
				PriorTimeReadingAbs,
				CyclePending,
				CycleReadingAbs,
				PriorCycleReadingAbs,
				PartNumber,
				PartDescription,
				SerialNumber,
				Qty,
				BillingMethod,
				BillingFrequency,
				TimeLimit,
				TimeMinimum,
				UsagePerUnitTimes,
				OverrunPerUnitTimes,
				CycleLimit,
				CycleMinimum,
				UsagePerUnitCycles,
				OverrunPerUnitCycles,
				IsOverageBillingMethod,
				IsFlatRateBillingMethod,
				FlatRate,
				HasUsageInfo,
				IsActive,
				LeaseStatusId,
				BillingInvoicingId,
				InvoiceNo,
				InvoiceDate,
				PeriodSeq,
				TimePriorAbs,
				TimeIsFirstEver,
				CyclePriorAbs,
				CycleIsFirstEver,
				CASE
					WHEN TimePending = 0 THEN NULL
					WHEN TimeIsFirstEver = 1 AND TimeReadingAbs < ISNULL(TimeMinimum, 0) THEN ISNULL(TimeMinimum, 0)
					ELSE TimeReadingAbs END AS TimeEffectiveCurrAbs,
				CASE
					WHEN CyclePending = 0 THEN NULL
					WHEN CycleIsFirstEver = 1 AND CycleReadingAbs < ISNULL(CycleMinimum, 0) THEN ISNULL(CycleMinimum, 0)
					ELSE CycleReadingAbs END AS CycleEffectiveCurrAbs,
				CASE
					WHEN TimePending = 0 OR IsOverageBillingMethod = 0 THEN NULL
					WHEN TimeLimit IS NOT NULL AND TimePriorAbs >= TimeLimit THEN TimeReadingAbs - TimePriorAbs
					WHEN TimeLimit IS NOT NULL AND TimeReadingAbs > TimeLimit THEN TimeReadingAbs - TimeLimit
					ELSE 0 END AS TimeOverMinutes,
				CASE
					WHEN CyclePending = 0 OR IsOverageBillingMethod = 0 THEN NULL
					WHEN CycleLimit IS NOT NULL AND CyclePriorAbs >= CycleLimit THEN CycleReadingAbs - CyclePriorAbs
					WHEN CycleLimit IS NOT NULL AND CycleReadingAbs > CycleLimit THEN CycleReadingAbs - CycleLimit
					ELSE 0 END AS CycleOverCount
			FROM PeriodAmounts
		),

		PeriodAmounts3 AS (
			SELECT
				LeaseStocklineId,
				PeriodKey,
				PeriodFromDate,
				PeriodToDate,
				TimePending,
				TimeReadingAbs,
				PriorTimeReadingAbs,
				CyclePending,
				CycleReadingAbs,
				PriorCycleReadingAbs,
				PartNumber,
				PartDescription,
				SerialNumber,
				Qty,
				BillingMethod,
				BillingFrequency,
				TimeLimit,
				TimeMinimum,
				UsagePerUnitTimes,
				OverrunPerUnitTimes,
				CycleLimit,
				CycleMinimum,
				UsagePerUnitCycles,
				OverrunPerUnitCycles,
				IsOverageBillingMethod,
				IsFlatRateBillingMethod,
				FlatRate,
				HasUsageInfo,
				IsActive,
				LeaseStatusId,
				BillingInvoicingId,
				InvoiceNo,
				InvoiceDate,
				PeriodSeq,
				TimePriorAbs,
				TimeIsFirstEver,
				CyclePriorAbs,
				CycleIsFirstEver,
				TimeEffectiveCurrAbs,
				CycleEffectiveCurrAbs,
				TimeOverMinutes,
				CycleOverCount,
				CASE
					WHEN TimePending = 0 OR IsOverageBillingMethod = 0 THEN NULL
					WHEN TimeLimit IS NOT NULL AND TimePriorAbs >= TimeLimit THEN 0
					WHEN TimeLimit IS NOT NULL AND TimeEffectiveCurrAbs > TimeLimit THEN TimeLimit - TimePriorAbs
					ELSE TimeEffectiveCurrAbs - TimePriorAbs END AS TimeUsageQty,
				CASE
					WHEN CyclePending = 0 OR IsOverageBillingMethod = 0 THEN NULL
					WHEN CycleLimit IS NOT NULL AND CyclePriorAbs >= CycleLimit THEN 0
					WHEN CycleLimit IS NOT NULL AND CycleEffectiveCurrAbs > CycleLimit THEN CycleLimit - CyclePriorAbs
					ELSE CycleEffectiveCurrAbs - CyclePriorAbs END AS CycleUsageQty
			FROM PeriodAmounts2
		),
		PeriodLines AS (
			SELECT
				LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				CASE WHEN IsFlatRateBillingMethod = 1 THEN FlatRate ELSE NULL END AS FlatRate,
				'Flat Rate' AS LineType,
				PeriodFromDate AS FromDate, PeriodToDate AS ToDate,
				CASE WHEN IsFlatRateBillingMethod = 1 THEN ISNULL(FlatRate, 0) * Qty ELSE NULL END AS LineAmount,
				TimeUsageQty AS TimeRecorded,
				CASE WHEN TimePending = 1 AND IsOverageBillingMethod = 1 THEN TimeLimit ELSE NULL END AS TimeLimit,
				CAST(NULL AS DECIMAL(18,6)) AS TimeOver,
				CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate,
				CASE WHEN TimePending = 1 AND IsOverageBillingMethod = 1 AND TimeUsageQty IS NOT NULL
					THEN (TimeUsageQty / 60.0) * ISNULL(UsagePerUnitTimes, 0) * Qty ELSE NULL END AS TimeBillingAmount,
				CycleUsageQty AS CycleRecorded,
				CASE WHEN CyclePending = 1 AND IsOverageBillingMethod = 1 THEN CycleLimit ELSE NULL END AS CycleLimit,
				CAST(NULL AS DECIMAL(18,6)) AS CycleOver,
				CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate,
				CASE WHEN CyclePending = 1 AND IsOverageBillingMethod = 1 AND CycleUsageQty IS NOT NULL
					THEN CycleUsageQty * ISNULL(UsagePerUnitCycles, 0) * Qty ELSE NULL END AS CycleBillingAmount,
				BillingInvoicingId, 'N' AS BillingStatus, InvoiceNo AS InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId,
				PeriodSeq, 1 AS LineSortOrder
			FROM PeriodAmounts3

			UNION ALL

			SELECT
				LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				CAST(NULL AS DECIMAL(18,6)) AS FlatRate,
				'Overrun' AS LineType,
				PeriodFromDate AS FromDate, PeriodToDate AS ToDate,
				CAST(NULL AS DECIMAL(18,6)) AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded,
				CAST(NULL AS DECIMAL(18,6)) AS TimeLimit,
				CASE WHEN TimePending = 1 AND IsOverageBillingMethod = 1 THEN TimeOverMinutes ELSE NULL END AS TimeOver,
				CASE WHEN TimePending = 1 AND IsOverageBillingMethod = 1 THEN OverrunPerUnitTimes ELSE NULL END AS TimeOverageRate,
				CASE WHEN TimePending = 1 AND IsOverageBillingMethod = 1 AND TimeOverMinutes IS NOT NULL
					THEN (TimeOverMinutes / 60.0) * ISNULL(OverrunPerUnitTimes, 0) * Qty ELSE NULL END AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded,
				CAST(NULL AS DECIMAL(18,6)) AS CycleLimit,
				CASE WHEN CyclePending = 1 AND IsOverageBillingMethod = 1 THEN CycleOverCount ELSE NULL END AS CycleOver,
				CASE WHEN CyclePending = 1 AND IsOverageBillingMethod = 1 THEN OverrunPerUnitCycles ELSE NULL END AS CycleOverageRate,
				CASE WHEN CyclePending = 1 AND IsOverageBillingMethod = 1 AND CycleOverCount IS NOT NULL
					THEN CycleOverCount * ISNULL(OverrunPerUnitCycles, 0) * Qty ELSE NULL END AS CycleBillingAmount,
				BillingInvoicingId, 'N' AS BillingStatus, InvoiceNo AS InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId,
				PeriodSeq, 2 AS LineSortOrder
			FROM PeriodAmounts3
		),
		OneTimeAnchor AS (
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				Maintenance, Insurance, Taxes, OtherComponentAmount, Charges,
				BillingInvoicingId, InvoiceNo, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId
			FROM StocklineBase
			WHERE IsInvoicePost = 0
		),
		OneTimeLines AS (
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				CAST(NULL AS DECIMAL(18,6)) AS FlatRate,
				'Maintenance' AS LineType,
				CAST(NULL AS DATETIME2(7)) AS FromDate, CAST(NULL AS DATETIME2(7)) AS ToDate,
				Maintenance AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded, CAST(NULL AS DECIMAL(18,6)) AS TimeLimit, CAST(NULL AS DECIMAL(18,6)) AS TimeOver, CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate, CAST(NULL AS DECIMAL(18,6)) AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded, CAST(NULL AS DECIMAL(18,6)) AS CycleLimit, CAST(NULL AS DECIMAL(18,6)) AS CycleOver, CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate, CAST(NULL AS DECIMAL(18,6)) AS CycleBillingAmount,
				BillingInvoicingId, 'N' AS BillingStatus, InvoiceNo AS InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId,
				CAST(0 AS BIGINT) AS PeriodSeq, 6 AS LineSortOrder
			FROM OneTimeAnchor WHERE ISNULL(Maintenance, 0) > 0

			UNION ALL

			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				CAST(NULL AS DECIMAL(18,6)) AS FlatRate,
				'Insurance' AS LineType,
				CAST(NULL AS DATETIME2(7)) AS FromDate, CAST(NULL AS DATETIME2(7)) AS ToDate,
				Insurance AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded, CAST(NULL AS DECIMAL(18,6)) AS TimeLimit, CAST(NULL AS DECIMAL(18,6)) AS TimeOver, CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate, CAST(NULL AS DECIMAL(18,6)) AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded, CAST(NULL AS DECIMAL(18,6)) AS CycleLimit, CAST(NULL AS DECIMAL(18,6)) AS CycleOver, CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate, CAST(NULL AS DECIMAL(18,6)) AS CycleBillingAmount,
				BillingInvoicingId, 'N' AS BillingStatus, InvoiceNo AS InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId,
				CAST(0 AS BIGINT) AS PeriodSeq, 7 AS LineSortOrder
			FROM OneTimeAnchor WHERE ISNULL(Insurance, 0) > 0

			UNION ALL

			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				CAST(NULL AS DECIMAL(18,6)) AS FlatRate,
				'Taxes' AS LineType,
				CAST(NULL AS DATETIME2(7)) AS FromDate, CAST(NULL AS DATETIME2(7)) AS ToDate,
				Taxes AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded, CAST(NULL AS DECIMAL(18,6)) AS TimeLimit, CAST(NULL AS DECIMAL(18,6)) AS TimeOver, CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate, CAST(NULL AS DECIMAL(18,6)) AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded, CAST(NULL AS DECIMAL(18,6)) AS CycleLimit, CAST(NULL AS DECIMAL(18,6)) AS CycleOver, CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate, CAST(NULL AS DECIMAL(18,6)) AS CycleBillingAmount,
				BillingInvoicingId, 'N' AS BillingStatus, InvoiceNo AS InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId,
				CAST(0 AS BIGINT) AS PeriodSeq, 8 AS LineSortOrder
			FROM OneTimeAnchor WHERE ISNULL(Taxes, 0) > 0

			UNION ALL

			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				CAST(NULL AS DECIMAL(18,6)) AS FlatRate,
				'Others' AS LineType,
				CAST(NULL AS DATETIME2(7)) AS FromDate, CAST(NULL AS DATETIME2(7)) AS ToDate,
				OtherComponentAmount AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded, CAST(NULL AS DECIMAL(18,6)) AS TimeLimit, CAST(NULL AS DECIMAL(18,6)) AS TimeOver, CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate, CAST(NULL AS DECIMAL(18,6)) AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded, CAST(NULL AS DECIMAL(18,6)) AS CycleLimit, CAST(NULL AS DECIMAL(18,6)) AS CycleOver, CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate, CAST(NULL AS DECIMAL(18,6)) AS CycleBillingAmount,
				BillingInvoicingId, 'N' AS BillingStatus, InvoiceNo AS InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId,
				CAST(0 AS BIGINT) AS PeriodSeq, 9 AS LineSortOrder
			FROM OneTimeAnchor WHERE ISNULL(OtherComponentAmount, 0) > 0

			UNION ALL

			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				CAST(NULL AS DECIMAL(18,6)) AS FlatRate,
				'Charges' AS LineType,
				CAST(NULL AS DATETIME2(7)) AS FromDate, CAST(NULL AS DATETIME2(7)) AS ToDate,
				Charges AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded, CAST(NULL AS DECIMAL(18,6)) AS TimeLimit, CAST(NULL AS DECIMAL(18,6)) AS TimeOver, CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate, CAST(NULL AS DECIMAL(18,6)) AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded, CAST(NULL AS DECIMAL(18,6)) AS CycleLimit, CAST(NULL AS DECIMAL(18,6)) AS CycleOver, CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate, CAST(NULL AS DECIMAL(18,6)) AS CycleBillingAmount,
				BillingInvoicingId, 'N' AS BillingStatus, InvoiceNo AS InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId,
				CAST(0 AS BIGINT) AS PeriodSeq, 10 AS LineSortOrder
			FROM OneTimeAnchor WHERE ISNULL(Charges, 0) > 0
		),
		FlatRateNoPeriod AS (
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				FlatRate AS FlatRate,
				'Flat Rate' AS LineType,
				CAST(NULL AS DATETIME2(7)) AS FromDate, CAST(NULL AS DATETIME2(7)) AS ToDate,
				ISNULL(FlatRate, 0) * Qty AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded, CAST(NULL AS DECIMAL(18,6)) AS TimeLimit, CAST(NULL AS DECIMAL(18,6)) AS TimeOver, CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate, CAST(NULL AS DECIMAL(18,6)) AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded, CAST(NULL AS DECIMAL(18,6)) AS CycleLimit, CAST(NULL AS DECIMAL(18,6)) AS CycleOver, CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate, CAST(NULL AS DECIMAL(18,6)) AS CycleBillingAmount,
				BillingInvoicingId, 'N' AS BillingStatus, InvoiceNo AS InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId,
				CAST(0 AS BIGINT) AS PeriodSeq, 1 AS LineSortOrder
			FROM StocklineBase SB
			WHERE SB.IsInvoicePost = 0
			  AND SB.IsFlatRateBillingMethod = 1
			  AND NOT EXISTS (SELECT 1 FROM PeriodAmounts3 PA WHERE PA.LeaseStocklineId = SB.LeaseStocklineId)
		),
		GenericFallback AS (
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				CAST(NULL AS DECIMAL(18,6)) AS FlatRate,
				CASE BillingMethod
					WHEN 'FlatRateOnly' THEN 'Flat Rate Only'
					WHEN 'FlatRatePlusOverrun' THEN 'Flat Rate + Overrun'
					WHEN 'UsageBased' THEN 'Usage Based'
					ELSE ISNULL(BillingMethod, '')
				END AS LineType,
				CAST(NULL AS DATETIME2(7)) AS FromDate, CAST(NULL AS DATETIME2(7)) AS ToDate,
				CAST(0 AS DECIMAL(18,2)) AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded, CAST(NULL AS DECIMAL(18,6)) AS TimeLimit, CAST(NULL AS DECIMAL(18,6)) AS TimeOver, CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate, CAST(NULL AS DECIMAL(18,6)) AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded, CAST(NULL AS DECIMAL(18,6)) AS CycleLimit, CAST(NULL AS DECIMAL(18,6)) AS CycleOver, CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate, CAST(NULL AS DECIMAL(18,6)) AS CycleBillingAmount,
				BillingInvoicingId, 'N' AS BillingStatus, InvoiceNo AS InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId,
				CAST(0 AS BIGINT) AS PeriodSeq, 0 AS LineSortOrder
			FROM StocklineBase SB
			WHERE SB.IsInvoicePost = 0
			  AND NOT EXISTS (SELECT 1 FROM PeriodAmounts3 PA WHERE PA.LeaseStocklineId = SB.LeaseStocklineId)
			  AND NOT EXISTS (SELECT 1 FROM FlatRateNoPeriod FR WHERE FR.LeaseStocklineId = SB.LeaseStocklineId)
			  AND NOT EXISTS (SELECT 1 FROM OneTimeLines OT WHERE OT.LeaseStocklineId = SB.LeaseStocklineId)
		),
		InvoicedLines AS (
			SELECT
				LBID.LeaseStocklineId, LSL.PN AS PartNumber, LSL.PNDescription AS PartDescription, SLIVE.SerialNumber,
				LSL.QtyReserved AS Qty, LBID.BillingMethod, LBID.BillingFrequency,
				LBID.FlatRate AS FlatRate,
				'Flat Rate' AS LineType,
				CAST(NULL AS DATETIME2(7)) AS FromDate, CAST(NULL AS DATETIME2(7)) AS ToDate,
				LBID.FlatRateAmount AS LineAmount,
				CASE WHEN LBID.TimeUsageQty IS NOT NULL THEN LBID.TimeUsageQty * 60 ELSE NULL END AS TimeRecorded,
				CASE WHEN LBID.TimeLimit IS NOT NULL THEN LBID.TimeLimit * 60 ELSE NULL END AS TimeLimit,
				CAST(NULL AS DECIMAL(18,6)) AS TimeOver, CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate,
				LBID.TimeUsageAmount AS TimeBillingAmount,
				LBID.CycleUsageQty AS CycleRecorded, LBID.CycleLimit AS CycleLimit,
				CAST(NULL AS DECIMAL(18,6)) AS CycleOver, CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate,
				LBID.CycleUsageAmount AS CycleBillingAmount,
				BI.BillingInvoicingId, 'Y' AS BillingStatus, BI.InvoiceNo AS InvoiceNumber, BI.InvoiceDate,
				CAST(1 AS BIT) AS HasUsageInfo, LSL.IsActive, LSL.LeaseStatusId,
				CAST(0 AS BIGINT) AS PeriodSeq, 1 AS LineSortOrder
			FROM [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH (NOLOCK)
			INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.LeaseStocklineId = LBID.LeaseStocklineId
			LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
			INNER JOIN [dbo].[BillingInvoicingItems] BII WITH (NOLOCK) ON BII.BillingInvoicingItemId = LBID.BillingInvoicingItemId AND BII.IsDeleted = 0
			INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK) ON BI.BillingInvoicingId = BII.BillingInvoicingId
			WHERE LSL.LeaseHeaderId = @LeaseHeaderId AND LSL.IsDeleted = 0 AND ISNULL(LBID.IsDeleted, 0) = 0

			UNION ALL

			SELECT
				LBID.LeaseStocklineId, LSL.PN AS PartNumber, LSL.PNDescription AS PartDescription, SLIVE.SerialNumber,
				LSL.QtyReserved AS Qty, LBID.BillingMethod, LBID.BillingFrequency,
				CAST(NULL AS DECIMAL(18,6)) AS FlatRate,
				'Overrun' AS LineType,
				CAST(NULL AS DATETIME2(7)) AS FromDate, CAST(NULL AS DATETIME2(7)) AS ToDate,
				CAST(NULL AS DECIMAL(18,6)) AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded,
				CAST(NULL AS DECIMAL(18,6)) AS TimeLimit,
				CASE WHEN LBID.TimeOver IS NOT NULL THEN LBID.TimeOver * 60 ELSE NULL END AS TimeOver,
				LBID.TimeOverageRate AS TimeOverageRate,
				CASE WHEN LBID.TimeBillingAmount IS NOT NULL THEN LBID.TimeBillingAmount - ISNULL(LBID.TimeUsageAmount, 0) ELSE NULL END AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded,
				CAST(NULL AS DECIMAL(18,6)) AS CycleLimit,
				LBID.CycleOver AS CycleOver,
				LBID.CycleOverageRate AS CycleOverageRate,
				CASE WHEN LBID.CycleBillingAmount IS NOT NULL THEN LBID.CycleBillingAmount - ISNULL(LBID.CycleUsageAmount, 0) ELSE NULL END AS CycleBillingAmount,
				BI.BillingInvoicingId, 'Y' AS BillingStatus, BI.InvoiceNo AS InvoiceNumber, BI.InvoiceDate,
				CAST(1 AS BIT) AS HasUsageInfo, LSL.IsActive, LSL.LeaseStatusId,
				CAST(0 AS BIGINT) AS PeriodSeq, 2 AS LineSortOrder
			FROM [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH (NOLOCK)
			INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.LeaseStocklineId = LBID.LeaseStocklineId
			LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
			INNER JOIN [dbo].[BillingInvoicingItems] BII WITH (NOLOCK) ON BII.BillingInvoicingItemId = LBID.BillingInvoicingItemId AND BII.IsDeleted = 0
			INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK) ON BI.BillingInvoicingId = BII.BillingInvoicingId
			WHERE LSL.LeaseHeaderId = @LeaseHeaderId AND LSL.IsDeleted = 0 AND ISNULL(LBID.IsDeleted, 0) = 0
		)
		SELECT
			LeaseStocklineId,
			PartNumber,
			PartDescription,
			SerialNumber,
			Qty,
			BillingMethod,
			BillingFrequency,
			FlatRate,
			LineType,
			FromDate,
			ToDate,
			LineAmount,
			TimeRecorded,
			TimeLimit,
			TimeOver,
			TimeOverageRate,
			TimeBillingAmount,
			CycleRecorded,
			CycleLimit,
			CycleOver,
			CycleOverageRate,
			CycleBillingAmount,
			BillingInvoicingId,
			BillingStatus,
			InvoiceNumber,
			InvoiceDate,
			HasUsageInfo,
			IsActive,
			LeaseStatusId
		FROM (
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM PeriodLines
			UNION ALL
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM OneTimeLines
			UNION ALL
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM FlatRateNoPeriod
			UNION ALL
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM GenericFallback
			UNION ALL
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM InvoicedLines
		) AllLines
		ORDER BY LeaseStocklineId, BillingStatus, PeriodSeq, LineSortOrder;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetLeaseBillingListByLeaseHeaderId]',
            @ProcedureParameters varchar(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS varchar(100)),
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
