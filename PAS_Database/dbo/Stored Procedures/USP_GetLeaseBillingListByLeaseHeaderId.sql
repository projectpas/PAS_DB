
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
    7   05/10/2026     Kishor Makwana          [PN-18072 IsVersionIncrease] Invoice items / detail rows are versioned with IsVersionIncrease (1 = superseded by a re-generated draft, 0 = current) instead of being
                                            soft-deleted - every read of BillingInvoicingItems / LeaseBillingInvoicingItemDetails here now keeps only ISNULL(IsVersionIncrease, 0) = 0.
    8    06/10/2026   Kishor Makwana          [PN-17949 shipment billing] A stockline is billable only once it has been SHIPPED (a non-deleted LeaseShippingItem with QtyShipped > 0 on a non-deleted LeaseShipping), unless LeaseHeader.AllowInvoiceBeforeShipping = 1 (default 0) - then reservation alone is enough, as before. Same rule as Sales Order billing.
	9    07/10/2026   Kishor Makwana          [PN-17949 service component by date] Maintenance/Insurance/Taxes/Other service components that have a Start Date and End Date are no longer billed once: for every calendar month inside [Start Date, End Date] a Pending line appears for the CURRENT month only (UTC date), once the month's slice has started - earlier and later months of the range are not listed. Amount = the component's TOTAL for [Start Date, End Date], split across the months of the range in proportion to each month's weight (full calendar month = 1, part month = days in the overlap / 30), the last month taking the rounding remainder. Several rows of one type in the same month are summed; From/To = the overlap of that month. Months already on a posted invoice or an open draft are not shown again. Rows without both dates keep the old one-time billing (billed once while LeaseStockline.IsInvoicePost = 0).
	
exec USP_GetLeaseBillingListByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseBillingListByLeaseHeaderId]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		DECLARE @BillingAsOfDate DATE = CAST(GETUTCDATE() AS DATE); -- billing date (UTC): only the CURRENT month's service component line is billable, and only once its slice has started
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
				LSL.RateUnit,
				COALESCE(SC_SUM.MaintenanceAmount, LSL.Maintenance) AS Maintenance,
				COALESCE(SC_SUM.InsuranceAmount, LSL.Insurance) AS Insurance,
				COALESCE(SC_SUM.TaxesAmount, LSL.Taxes) AS Taxes,
				ISNULL(SC_SUM.OtherComponentAmount, 0) AS OtherComponentAmount,
				SC_SUM.MaintenanceFrom, SC_SUM.MaintenanceTo, SC_SUM.InsuranceFrom, SC_SUM.InsuranceTo, SC_SUM.TaxesFrom, SC_SUM.TaxesTo, SC_SUM.OtherFrom, SC_SUM.OtherTo,
				ISNULL(ChargesAgg.Charges, 0) AS Charges,
				CASE WHEN LSL.MaximumTimes IS NOT NULL AND LSL.MaximumTimes > 0 AND ISNULL(LSL.BillingMethod, '') <> 'UsageBased' THEN LSL.MaximumTimes * 60 ELSE NULL END AS TimeLimit,
				CASE WHEN LSL.MinimumTimes IS NOT NULL THEN LSL.MinimumTimes * 60 ELSE NULL END AS TimeMinimum,
				LSL.UsagePerUnitTimes,
				LSL.OverrunPerUnitTimes,
				CASE WHEN LSL.MaximumCycles > 0 AND ISNULL(LSL.BillingMethod, '') <> 'UsageBased' THEN LSL.MaximumCycles ELSE NULL END AS CycleLimit,
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
				WHERE BII.SubReferenceId = LSL.LeaseStocklineId AND BII.ModuleId = @LeaseModuleId AND BII.IsDeleted = 0 AND ISNULL(BII.IsVersionIncrease, 0) = 0
				ORDER BY BII.BillingInvoicingItemId DESC
			) LatestBII
			LEFT JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK) ON BI.BillingInvoicingId = LatestBII.BillingInvoicingId
			OUTER APPLY (
				SELECT SUM(ISNULL(LC.ExtendedCost, 0)) AS Charges
				FROM [dbo].[LeaseCharges] LC WITH (NOLOCK)
				WHERE LC.LeaseStocklineId = LSL.LeaseStocklineId AND LC.IsDeleted = 0
			) ChargesAgg
			LEFT JOIN (
				SELECT LeaseStocklineId,
				SUM(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) = 'MAINTENANCE' THEN (CASE WHEN (StartDate IS NOT NULL AND EndDate IS NOT NULL AND EndDate >= StartDate) THEN 0 ELSE ISNULL(Amount, 0) END) END) AS MaintenanceAmount,
				SUM(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) = 'INSURANCE' THEN (CASE WHEN (StartDate IS NOT NULL AND EndDate IS NOT NULL AND EndDate >= StartDate) THEN 0 ELSE ISNULL(Amount, 0) END) END) AS InsuranceAmount,
				SUM(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) = 'TAXES' THEN (CASE WHEN (StartDate IS NOT NULL AND EndDate IS NOT NULL AND EndDate >= StartDate) THEN 0 ELSE ISNULL(Amount, 0) END) END) AS TaxesAmount,
				SUM(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) IN ('MAINTENANCE', 'INSURANCE', 'TAXES') OR (StartDate IS NOT NULL AND EndDate IS NOT NULL AND EndDate >= StartDate) THEN 0 ELSE ISNULL(Amount, 0) END) AS OtherComponentAmount,
				MIN(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) = 'MAINTENANCE' THEN StartDate END) AS MaintenanceFrom,
				MAX(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) = 'MAINTENANCE' THEN EndDate END) AS MaintenanceTo,
				MIN(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) = 'INSURANCE' THEN StartDate END) AS InsuranceFrom,
				MAX(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) = 'INSURANCE' THEN EndDate END) AS InsuranceTo,
				MIN(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) = 'TAXES' THEN StartDate END) AS TaxesFrom,
				MAX(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) = 'TAXES' THEN EndDate END) AS TaxesTo,
				MIN(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) NOT IN ('MAINTENANCE', 'INSURANCE', 'TAXES') THEN StartDate END) AS OtherFrom,
				MAX(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) NOT IN ('MAINTENANCE', 'INSURANCE', 'TAXES') THEN EndDate END) AS OtherTo
				FROM [dbo].[LeaseStocklineServiceComponent] WITH (NOLOCK)
				WHERE IsDeleted = 0
				GROUP BY LeaseStocklineId
			) SC_SUM ON SC_SUM.LeaseStocklineId = LSL.LeaseStocklineId
			WHERE LSL.LeaseHeaderId = @LeaseHeaderId
			  AND LSL.IsDeleted = 0
			  AND LSL.QtyReserved > 0
			  AND (
					ISNULL((SELECT TOP 1 LHB.[AllowInvoiceBeforeShipping] FROM [dbo].[LeaseHeader] LHB WITH (NOLOCK) WHERE LHB.[LeaseHeaderId] = @LeaseHeaderId), 0) = 1
					OR EXISTS (SELECT 1 FROM [dbo].[LeaseShippingItem] LSI WITH (NOLOCK)
							   INNER JOIN [dbo].[LeaseShipping] LSH WITH (NOLOCK) ON LSH.[LeaseShippingId] = LSI.[LeaseShippingId] AND ISNULL(LSH.[IsDeleted], 0) = 0
							   WHERE LSI.[LeaseStocklineId] = LSL.[LeaseStocklineId] AND ISNULL(LSI.[IsDeleted], 0) = 0 AND ISNULL(LSI.[IsActive], 1) = 1 AND ISNULL(LSI.[QtyShipped], 0) > 0)
				  )
		),
		TimeSeries AS (
			SELECT
				H.LeaseStocklineId,
				DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1) AS PeriodKey,
				MIN(H.FromDate) AS FromDate,
				MAX(H.ToDate) AS ToDate,
				SUM(ISNULL(H.TSNHours, 0) * 60 + ISNULL(H.TSNMinutes, 0)) AS TimeReadingAbs
			FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
			WHERE H.UsageType = 'T' AND H.IsActive = 1 AND H.IsDeleted = 0 AND ISNULL(H.IsInvoiced, 0) = 0 AND H.BillingInvoicingItemId IS NULL
			GROUP BY H.LeaseStocklineId, DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1)
		),
		CycleSeries AS (
			SELECT
				H.LeaseStocklineId,
				DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1) AS PeriodKey,
				MIN(H.FromDate) AS FromDate,
				MAX(H.ToDate) AS ToDate,
				SUM(ISNULL(H.CSN, 0)) AS CycleReadingAbs
			FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
			WHERE H.UsageType = 'C' AND H.IsActive = 1 AND H.IsDeleted = 0 AND ISNULL(H.IsInvoiced, 0) = 0 AND H.BillingInvoicingItemId IS NULL
			GROUP BY H.LeaseStocklineId, DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1)
		),
		TimeFirstMonthEver AS (
			SELECT LeaseStocklineId, MIN(DATEFROMPARTS(YEAR(FromDate), MONTH(FromDate), 1)) AS FirstMonth
			FROM [dbo].[LeaseStocklineUsageHistory] WITH (NOLOCK)
			WHERE UsageType = 'T' AND IsActive = 1 AND IsDeleted = 0
			GROUP BY LeaseStocklineId
		),
		CycleFirstMonthEver AS (
			SELECT LeaseStocklineId, MIN(DATEFROMPARTS(YEAR(FromDate), MONTH(FromDate), 1)) AS FirstMonth
			FROM [dbo].[LeaseStocklineUsageHistory] WITH (NOLOCK)
			WHERE UsageType = 'C' AND IsActive = 1 AND IsDeleted = 0
			GROUP BY LeaseStocklineId
		),
		Periods AS (
			SELECT
				COALESCE(T.LeaseStocklineId, C.LeaseStocklineId) AS LeaseStocklineId,
				COALESCE(T.PeriodKey, C.PeriodKey) AS PeriodKey,
				(SELECT MIN(D) FROM (VALUES (T.FromDate), (C.FromDate)) AS Dates(D)) AS PeriodFromDate,
				(SELECT MAX(D) FROM (VALUES (T.ToDate), (C.ToDate)) AS Dates(D)) AS PeriodToDate,
				CASE WHEN T.PeriodKey IS NOT NULL THEN 1 ELSE 0 END AS TimePending,
				T.TimeReadingAbs,
				CAST(0 AS DECIMAL(18,6)) AS PriorTimeReadingAbs,
				CASE WHEN C.PeriodKey IS NOT NULL THEN 1 ELSE 0 END AS CyclePending,
				C.CycleReadingAbs,
				CAST(0 AS DECIMAL(18,6)) AS PriorCycleReadingAbs,
				CASE WHEN T.PeriodKey IS NOT NULL AND T.PeriodKey = TF.FirstMonth THEN 1 ELSE 0 END AS TimeIsFirstEverMonth,
				CASE WHEN C.PeriodKey IS NOT NULL AND C.PeriodKey = CF.FirstMonth THEN 1 ELSE 0 END AS CycleIsFirstEverMonth
			FROM TimeSeries T
			FULL OUTER JOIN CycleSeries C
				ON C.LeaseStocklineId = T.LeaseStocklineId AND C.PeriodKey = T.PeriodKey
			LEFT JOIN TimeFirstMonthEver TF ON TF.LeaseStocklineId = COALESCE(T.LeaseStocklineId, C.LeaseStocklineId)
			LEFT JOIN CycleFirstMonthEver CF ON CF.LeaseStocklineId = COALESCE(T.LeaseStocklineId, C.LeaseStocklineId)
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
				P.TimeIsFirstEverMonth,
				P.CycleIsFirstEverMonth,
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
				S.RateUnit,
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
				RateUnit,
				HasUsageInfo,
				IsActive,
				LeaseStatusId,
				BillingInvoicingId,
				InvoiceNo,
				InvoiceDate,
				PeriodSeq,
				ISNULL(PriorTimeReadingAbs, 0) AS TimePriorAbs,
				CASE WHEN TimePending = 1 AND TimeIsFirstEverMonth = 1 THEN 1 ELSE 0 END AS TimeIsFirstEver,
				ISNULL(PriorCycleReadingAbs, 0) AS CyclePriorAbs,
				CASE WHEN CyclePending = 1 AND CycleIsFirstEverMonth = 1 THEN 1 ELSE 0 END AS CycleIsFirstEver
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
				RateUnit,
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
					-- Minimum applies once to the FIRST usage month's TOTAL (usage already invoiced + pending). Billed so far = MAX(invoiced, Minimum); this
					-- invoice adds MAX(invoiced + pending, Minimum) - that. Nothing invoiced yet = the usual 'raise the pending usage to the Minimum'.
					WHEN TimeIsFirstEver = 1 AND ISNULL(INV.InvTimeMin, 0) > 0 THEN
						(CASE WHEN INV.InvTimeMin + TimeReadingAbs < ISNULL(TimeMinimum, 0) THEN ISNULL(TimeMinimum, 0) ELSE INV.InvTimeMin + TimeReadingAbs END)
						- (CASE WHEN INV.InvTimeMin < ISNULL(TimeMinimum, 0) THEN ISNULL(TimeMinimum, 0) ELSE INV.InvTimeMin END)
					WHEN TimeIsFirstEver = 1 AND TimeReadingAbs < ISNULL(TimeMinimum, 0) THEN ISNULL(TimeMinimum, 0)
					ELSE TimeReadingAbs END AS TimeEffectiveCurrAbs,
				CASE
					WHEN CyclePending = 0 THEN NULL
					WHEN CycleIsFirstEver = 1 AND ISNULL(INV.InvCycleCnt, 0) > 0 THEN
						(CASE WHEN INV.InvCycleCnt + CycleReadingAbs < ISNULL(CycleMinimum, 0) THEN ISNULL(CycleMinimum, 0) ELSE INV.InvCycleCnt + CycleReadingAbs END)
						- (CASE WHEN INV.InvCycleCnt < ISNULL(CycleMinimum, 0) THEN ISNULL(CycleMinimum, 0) ELSE INV.InvCycleCnt END)
					WHEN CycleIsFirstEver = 1 AND CycleReadingAbs < ISNULL(CycleMinimum, 0) THEN ISNULL(CycleMinimum, 0)
					ELSE CycleReadingAbs END AS CycleEffectiveCurrAbs,
				CASE
					WHEN TimePending = 0 OR IsOverageBillingMethod = 0 THEN NULL
					-- Monthly Maximum is checked against the month's TOTAL (already invoiced + pending); only the overrun not billed yet is returned
					WHEN TimeLimit IS NOT NULL THEN
						(CASE WHEN ISNULL(INV.InvTimeMin, 0) + TimeReadingAbs > TimeLimit THEN ISNULL(INV.InvTimeMin, 0) + TimeReadingAbs - TimeLimit ELSE 0 END)
						- (CASE WHEN ISNULL(INV.InvTimeMin, 0) > TimeLimit THEN ISNULL(INV.InvTimeMin, 0) - TimeLimit ELSE 0 END)
					ELSE 0 END AS TimeOverMinutes,
				CASE
					WHEN CyclePending = 0 OR IsOverageBillingMethod = 0 THEN NULL
					WHEN CycleLimit IS NOT NULL THEN
						(CASE WHEN ISNULL(INV.InvCycleCnt, 0) + CycleReadingAbs > CycleLimit THEN ISNULL(INV.InvCycleCnt, 0) + CycleReadingAbs - CycleLimit ELSE 0 END)
						- (CASE WHEN ISNULL(INV.InvCycleCnt, 0) > CycleLimit THEN ISNULL(INV.InvCycleCnt, 0) - CycleLimit ELSE 0 END)
					ELSE 0 END AS CycleOverCount,
				-- the month's TOTAL usage (already invoiced + pending): shown as Recorded on the Overrun line
				CASE WHEN TimePending = 1 THEN ISNULL(INV.InvTimeMin, 0) + ISNULL(TimeReadingAbs, 0) ELSE NULL END AS TimeMonthTotalAbs,
				CASE WHEN CyclePending = 1 THEN ISNULL(INV.InvCycleCnt, 0) + ISNULL(CycleReadingAbs, 0) ELSE NULL END AS CycleMonthTotalAbs
			FROM PeriodAmounts PA0
			OUTER APPLY (
				-- Usage of THIS period's calendar month that is already on a draft / posted invoice (the pending series above excludes it). Used by the first-month Minimum and by the monthly Maximum (Overrun).
				SELECT
					SUM(CASE WHEN H.UsageType = 'T' THEN ISNULL(H.TSNHours, 0) * 60 + ISNULL(H.TSNMinutes, 0) ELSE 0 END) AS InvTimeMin,
					SUM(CASE WHEN H.UsageType = 'C' THEN ISNULL(H.CSN, 0) ELSE 0 END) AS InvCycleCnt
				FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
				WHERE H.LeaseStocklineId = PA0.LeaseStocklineId AND H.IsActive = 1 AND H.IsDeleted = 0
				  AND (ISNULL(H.IsInvoiced, 0) = 1 OR H.BillingInvoicingItemId IS NOT NULL)
				  AND H.FromDate >= PA0.PeriodKey AND H.FromDate < DATEADD(MONTH, 1, PA0.PeriodKey)
			) INV
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
				RateUnit,
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
				TimeMonthTotalAbs,
				CycleMonthTotalAbs,
				CASE
					WHEN TimePending = 0 THEN NULL
					WHEN IsFlatRateBillingMethod = 1 AND IsOverageBillingMethod = 0 THEN TimeEffectiveCurrAbs - TimePriorAbs
					WHEN IsOverageBillingMethod = 0 THEN NULL
					WHEN TimeLimit IS NOT NULL AND TimePriorAbs >= TimeLimit THEN 0
					WHEN TimeLimit IS NOT NULL AND TimeEffectiveCurrAbs > TimeLimit THEN TimeLimit - TimePriorAbs
					ELSE TimeEffectiveCurrAbs - TimePriorAbs END AS TimeUsageQty,
				CASE
					WHEN CyclePending = 0 THEN NULL
					WHEN IsFlatRateBillingMethod = 1 AND IsOverageBillingMethod = 0 THEN CycleEffectiveCurrAbs - CyclePriorAbs
					WHEN IsOverageBillingMethod = 0 THEN NULL
					WHEN CycleLimit IS NOT NULL AND CyclePriorAbs >= CycleLimit THEN 0
					WHEN CycleLimit IS NOT NULL AND CycleEffectiveCurrAbs > CycleLimit THEN CycleLimit - CyclePriorAbs
					ELSE CycleEffectiveCurrAbs - CyclePriorAbs END AS CycleUsageQty
			FROM PeriodAmounts2
		),
		PostedFlatMonths AS (
			SELECT DISTINCT PL.LeaseStocklineId, DATEFROMPARTS(YEAR(PL.FromDate), MONTH(PL.FromDate), 1) AS MonthKey
			FROM [dbo].[LeaseBillingInvoicingItemDetails] PL WITH (NOLOCK)
			INNER JOIN [dbo].[BillingInvoicingItems] PB WITH (NOLOCK)
				ON PB.BillingInvoicingItemId = PL.BillingInvoicingItemId AND PB.IsDeleted = 0 AND ISNULL(PB.IsVersionIncrease, 0) = 0
			INNER JOIN [dbo].[BillingInvoicing] PI WITH (NOLOCK)
				ON PI.BillingInvoicingId = PB.BillingInvoicingId AND ISNULL(PI.IsInvoicePosted, 0) = 1 AND ISNULL(PI.InvoiceStatus, '') <> 'Voided'
			WHERE PL.LineType = 'Flat Rate' AND PL.FromDate IS NOT NULL AND ISNULL(PL.IsDeleted, 0) = 0
			  AND ISNULL(PL.IsVersionIncrease, 0) = 0 AND ISNULL(PL.FlatRateAmount, 0) > 0
		),
		PeriodLines AS (
			SELECT
				LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				CASE WHEN IsFlatRateBillingMethod = 1 THEN FlatRate ELSE NULL END AS FlatRate,
				'Flat Rate' AS LineType,
				PeriodFromDate AS FromDate, PeriodToDate AS ToDate,
				CASE WHEN IsFlatRateBillingMethod = 1 AND UPPER(LTRIM(RTRIM(ISNULL(RateUnit, '')))) = 'MONTH'
					AND NOT EXISTS (SELECT 1 FROM PostedFlatMonths PM WHERE PM.LeaseStocklineId = PeriodAmounts3.LeaseStocklineId
						AND PM.MonthKey = DATEFROMPARTS(YEAR(PeriodAmounts3.PeriodFromDate), MONTH(PeriodAmounts3.PeriodFromDate), 1))
					THEN ISNULL(FlatRate, 0) * Qty ELSE NULL END AS LineAmount,
				CASE WHEN TimePending = 1 THEN (CASE WHEN TimeReadingAbs < 0 THEN 0 ELSE TimeReadingAbs END) ELSE NULL END AS TimeRecorded,
				CASE WHEN TimePending = 1 AND IsOverageBillingMethod = 1 THEN (CASE WHEN TimeLimit < 0 THEN 0 ELSE TimeLimit END) ELSE NULL END AS TimeLimit,
				CAST(NULL AS DECIMAL(18,6)) AS TimeOver,
				CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate,
				CASE
					WHEN TimePending = 1 AND TimeUsageQty IS NOT NULL AND IsFlatRateBillingMethod = 1
						AND UPPER(LTRIM(RTRIM(ISNULL(RateUnit, '')))) NOT IN ('CYCLE', 'MONTH')
						THEN (TimeUsageQty / 60.0) * ISNULL(FlatRate, 0) * Qty
					WHEN TimePending = 1 AND TimeUsageQty IS NOT NULL AND BillingMethod = 'UsageBased'
						THEN (TimeUsageQty / 60.0) * ISNULL(UsagePerUnitTimes, 0) * Qty
					ELSE NULL
				END AS TimeBillingAmount,
				CASE WHEN CyclePending = 1 THEN (CASE WHEN CycleReadingAbs < 0 THEN 0 ELSE CycleReadingAbs END) ELSE NULL END AS CycleRecorded,
				CASE WHEN CyclePending = 1 AND IsOverageBillingMethod = 1 THEN (CASE WHEN CycleLimit < 0 THEN 0 ELSE CycleLimit END) ELSE NULL END AS CycleLimit,
				CAST(NULL AS DECIMAL(18,6)) AS CycleOver,
				CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate,
				CASE
					WHEN CyclePending = 1 AND CycleUsageQty IS NOT NULL AND IsFlatRateBillingMethod = 1
						AND UPPER(LTRIM(RTRIM(ISNULL(RateUnit, '')))) = 'CYCLE'
						THEN CycleUsageQty * ISNULL(FlatRate, 0) * Qty
					WHEN CyclePending = 1 AND CycleUsageQty IS NOT NULL AND BillingMethod = 'UsageBased'
						THEN CycleUsageQty * ISNULL(UsagePerUnitCycles, 0) * Qty
					ELSE NULL
				END AS CycleBillingAmount,
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
				CASE WHEN TimePending = 1 AND IsOverageBillingMethod = 1 THEN TimeMonthTotalAbs ELSE NULL END AS TimeRecorded,
				CASE WHEN TimePending = 1 AND IsOverageBillingMethod = 1 AND TimeLimit IS NOT NULL THEN TimeLimit ELSE NULL END AS TimeLimit,
				CASE WHEN TimePending = 1 AND IsOverageBillingMethod = 1 THEN (CASE WHEN TimeOverMinutes < 0 THEN 0 ELSE TimeOverMinutes END) ELSE NULL END AS TimeOver,
				CASE WHEN TimePending = 1 AND IsOverageBillingMethod = 1 THEN (CASE WHEN OverrunPerUnitTimes < 0 THEN 0 ELSE OverrunPerUnitTimes END) ELSE NULL END AS TimeOverageRate,
				CASE
					WHEN TimePending = 1 AND IsOverageBillingMethod = 1 AND TimeOverMinutes IS NOT NULL
						THEN (TimeOverMinutes / 60.0) * ISNULL(OverrunPerUnitTimes, 0) * Qty
					ELSE NULL
				END AS TimeBillingAmount,
				CASE WHEN CyclePending = 1 AND IsOverageBillingMethod = 1 THEN CycleMonthTotalAbs ELSE NULL END AS CycleRecorded,
				CASE WHEN CyclePending = 1 AND IsOverageBillingMethod = 1 AND CycleLimit IS NOT NULL THEN CycleLimit ELSE NULL END AS CycleLimit,
				CASE WHEN CyclePending = 1 AND IsOverageBillingMethod = 1 THEN (CASE WHEN CycleOverCount < 0 THEN 0 ELSE CycleOverCount END) ELSE NULL END AS CycleOver,
				CASE WHEN CyclePending = 1 AND IsOverageBillingMethod = 1 THEN (CASE WHEN OverrunPerUnitCycles < 0 THEN 0 ELSE OverrunPerUnitCycles END) ELSE NULL END AS CycleOverageRate,
				CASE
					WHEN CyclePending = 1 AND IsOverageBillingMethod = 1 AND CycleOverCount IS NOT NULL
						THEN CycleOverCount * ISNULL(OverrunPerUnitCycles, 0) * Qty
					ELSE NULL
				END AS CycleBillingAmount,
				BillingInvoicingId, 'N' AS BillingStatus, InvoiceNo AS InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId,
				PeriodSeq, 2 AS LineSortOrder
			FROM PeriodAmounts3
		),
		OneTimeAnchor AS (
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency,
				Maintenance, Insurance, Taxes, OtherComponentAmount, MaintenanceFrom, MaintenanceTo, InsuranceFrom, InsuranceTo, TaxesFrom, TaxesTo, OtherFrom, OtherTo, Charges,
				BillingInvoicingId, InvoiceNo, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId
			FROM StocklineBase
			WHERE IsInvoicePost = 0
		),
		OpenDraftLines AS (
			SELECT DISTINCT LBX.LeaseStocklineId, LBX.LineType, LBX.FromDate
			FROM [dbo].[LeaseBillingInvoicingItemDetails] LBX WITH (NOLOCK)
			INNER JOIN [dbo].[LeaseStockline] LSX WITH (NOLOCK) ON LSX.LeaseStocklineId = LBX.LeaseStocklineId AND LSX.LeaseHeaderId = @LeaseHeaderId
			INNER JOIN [dbo].[BillingInvoicingItems] BX WITH (NOLOCK) ON BX.BillingInvoicingItemId = LBX.BillingInvoicingItemId AND BX.IsDeleted = 0 AND ISNULL(BX.IsVersionIncrease, 0) = 0
			INNER JOIN [dbo].[BillingInvoicing] BIX WITH (NOLOCK) ON BIX.BillingInvoicingId = BX.BillingInvoicingId
				AND ISNULL(BIX.IsInvoicePosted, 0) = 0 AND ISNULL(BIX.InvoiceStatus, '') <> 'Voided'
			WHERE ISNULL(LBX.IsDeleted, 0) = 0 AND ISNULL(LBX.IsVersionIncrease, 0) = 0 AND LBX.LineType IS NOT NULL
		),
		Nums AS (
			SELECT TOP (1200) CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS INT) AS n FROM sys.all_columns
		),
		ComponentSlicesBase AS (
			-- Service component Amount = the TOTAL for [StartDate, EndDate] (Per = Monthly only names the billing cadence). One row per component row per CALENDAR
			-- month it overlaps. Weight: a fully covered calendar month = 1, a part month = (days in the overlap / 30). Component rows without both dates are
			-- not here (they keep the old one-time billing through OneTimeLines).
			SELECT
				SC.LeaseStocklineServiceComponentId AS ComponentId,
				SC.LeaseStocklineId,
				CASE UPPER(LTRIM(RTRIM(SC.ComponentName))) WHEN 'MAINTENANCE' THEN 'Maintenance' WHEN 'INSURANCE' THEN 'Insurance' WHEN 'TAXES' THEN 'Taxes' ELSE 'Others' END AS LineType,
				M.MonthStart,
				SL.SliceFrom,
				SL.SliceTo,
				ISNULL(SC.Amount, 0) AS Amount,
				CASE WHEN SL.SliceFrom = M.MonthStart AND SL.SliceTo = EOMONTH(M.MonthStart) THEN CAST(1 AS DECIMAL(18,6))
					ELSE CAST(DATEDIFF(DAY, SL.SliceFrom, SL.SliceTo) + 1 AS DECIMAL(18,6)) / 30.0 END AS Weight
			FROM [dbo].[LeaseStocklineServiceComponent] SC WITH (NOLOCK)
			INNER JOIN (SELECT DISTINCT LeaseStocklineId FROM StocklineBase) SBX ON SBX.LeaseStocklineId = SC.LeaseStocklineId
			INNER JOIN Nums N ON N.n <= DATEDIFF(MONTH, SC.StartDate, SC.EndDate)
			CROSS APPLY (SELECT DATEADD(MONTH, N.n, DATEFROMPARTS(YEAR(SC.StartDate), MONTH(SC.StartDate), 1)) AS MonthStart) M
			CROSS APPLY (SELECT
					CASE WHEN CAST(SC.StartDate AS DATE) > M.MonthStart THEN CAST(SC.StartDate AS DATE) ELSE M.MonthStart END AS SliceFrom,
					CASE WHEN CAST(SC.EndDate AS DATE) < EOMONTH(M.MonthStart) THEN CAST(SC.EndDate AS DATE) ELSE EOMONTH(M.MonthStart) END AS SliceTo) SL
			WHERE SC.IsDeleted = 0 AND SC.StartDate IS NOT NULL AND SC.EndDate IS NOT NULL AND SC.EndDate >= SC.StartDate AND ISNULL(SC.Amount, 0) <> 0
		),
		ComponentSlicesRounded AS (
			SELECT ComponentId, LeaseStocklineId, LineType, MonthStart, SliceFrom, SliceTo, Amount,
				ROUND(Amount * Weight / NULLIF(SUM(Weight) OVER (PARTITION BY ComponentId), 0), 2) AS ShareRounded
			FROM ComponentSlicesBase
		),
		ComponentSlices AS (
			-- Each month's share of the total; the LAST month takes the rounding remainder so the months always add up to the entered Amount
			SELECT ComponentId, LeaseStocklineId, LineType, MonthStart, SliceFrom, SliceTo,
				CASE WHEN MonthStart = MAX(MonthStart) OVER (PARTITION BY ComponentId)
					THEN Amount - (SUM(ShareRounded) OVER (PARTITION BY ComponentId) - ShareRounded)
					ELSE ShareRounded END AS SliceAmount
			FROM ComponentSlicesRounded
		),
		ComponentMonthLines AS (
			-- Billable now = ONLY the calendar month of the billing date (UTC today) - earlier / later months of the range are not listed - and only once the slice has started. Several rows of the same type in one month are summed.
			SELECT LeaseStocklineId, LineType, MonthStart, MIN(SliceFrom) AS FromDate, MAX(SliceTo) AS ToDate, CAST(ROUND(SUM(SliceAmount), 2) AS DECIMAL(18,6)) AS LineAmount
			FROM ComponentSlices
			WHERE SliceFrom <= @BillingAsOfDate
		  AND MonthStart = DATEFROMPARTS(YEAR(@BillingAsOfDate), MONTH(@BillingAsOfDate), 1)
			GROUP BY LeaseStocklineId, LineType, MonthStart
			HAVING ROUND(SUM(SliceAmount), 2) <> 0
		),
		ComponentBilledMonths AS (
			-- Component months already on a posted invoice or on an open (not voided) draft
			SELECT DISTINCT LBX.LeaseStocklineId, LBX.LineType, DATEFROMPARTS(YEAR(LBX.FromDate), MONTH(LBX.FromDate), 1) AS MonthKey
			FROM [dbo].[LeaseBillingInvoicingItemDetails] LBX WITH (NOLOCK)
			INNER JOIN (SELECT DISTINCT LeaseStocklineId FROM StocklineBase) SBY ON SBY.LeaseStocklineId = LBX.LeaseStocklineId
			INNER JOIN [dbo].[BillingInvoicingItems] BX WITH (NOLOCK) ON BX.BillingInvoicingItemId = LBX.BillingInvoicingItemId AND BX.IsDeleted = 0 AND ISNULL(BX.IsVersionIncrease, 0) = 0
			INNER JOIN [dbo].[BillingInvoicing] BIX WITH (NOLOCK) ON BIX.BillingInvoicingId = BX.BillingInvoicingId AND ISNULL(BIX.InvoiceStatus, '') <> 'Voided'
			WHERE ISNULL(LBX.IsDeleted, 0) = 0 AND ISNULL(LBX.IsVersionIncrease, 0) = 0 AND LBX.FromDate IS NOT NULL
			  AND LBX.LineType IN ('Maintenance', 'Insurance', 'Taxes', 'Others')
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
			FROM OneTimeAnchor WHERE ISNULL(Maintenance, 0) > 0 AND NOT EXISTS (SELECT 1 FROM OpenDraftLines OD WHERE OD.LeaseStocklineId = OneTimeAnchor.LeaseStocklineId AND OD.LineType = 'Maintenance')

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
			FROM OneTimeAnchor WHERE ISNULL(Insurance, 0) > 0 AND NOT EXISTS (SELECT 1 FROM OpenDraftLines OD WHERE OD.LeaseStocklineId = OneTimeAnchor.LeaseStocklineId AND OD.LineType = 'Insurance')

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
			FROM OneTimeAnchor WHERE ISNULL(Taxes, 0) > 0 AND NOT EXISTS (SELECT 1 FROM OpenDraftLines OD WHERE OD.LeaseStocklineId = OneTimeAnchor.LeaseStocklineId AND OD.LineType = 'Taxes')

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
			FROM OneTimeAnchor WHERE ISNULL(OtherComponentAmount, 0) > 0 AND NOT EXISTS (SELECT 1 FROM OpenDraftLines OD WHERE OD.LeaseStocklineId = OneTimeAnchor.LeaseStocklineId AND OD.LineType = 'Others')

			UNION ALL

			-- Service components WITH Start/End dates: one line per type per calendar month inside [StartDate, EndDate]
			SELECT SB.LeaseStocklineId, SB.PartNumber, SB.PartDescription, SB.SerialNumber, SB.Qty, SB.BillingMethod, SB.BillingFrequency,
				CAST(NULL AS DECIMAL(18,6)) AS FlatRate,
				CML.LineType AS LineType,
				CAST(CML.FromDate AS DATETIME2(7)) AS FromDate, CAST(CML.ToDate AS DATETIME2(7)) AS ToDate,
				CML.LineAmount AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded, CAST(NULL AS DECIMAL(18,6)) AS TimeLimit, CAST(NULL AS DECIMAL(18,6)) AS TimeOver, CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate, CAST(NULL AS DECIMAL(18,6)) AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded, CAST(NULL AS DECIMAL(18,6)) AS CycleLimit, CAST(NULL AS DECIMAL(18,6)) AS CycleOver, CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate, CAST(NULL AS DECIMAL(18,6)) AS CycleBillingAmount,
				SB.BillingInvoicingId, 'N' AS BillingStatus, SB.InvoiceNo AS InvoiceNumber, SB.InvoiceDate, SB.HasUsageInfo, SB.IsActive, SB.LeaseStatusId,
				CAST(DATEDIFF(MONTH, '20000101', CML.MonthStart) AS BIGINT) AS PeriodSeq,
				CASE CML.LineType WHEN 'Maintenance' THEN 6 WHEN 'Insurance' THEN 7 WHEN 'Taxes' THEN 8 ELSE 9 END AS LineSortOrder
			FROM ComponentMonthLines CML
			INNER JOIN StocklineBase SB ON SB.LeaseStocklineId = CML.LeaseStocklineId
			WHERE NOT EXISTS (SELECT 1 FROM ComponentBilledMonths CB WHERE CB.LeaseStocklineId = CML.LeaseStocklineId AND CB.LineType = CML.LineType AND CB.MonthKey = CML.MonthStart)
		),
		ChargesByPeriod AS (
			SELECT
				PA.LeaseStocklineId, PA.PartNumber, PA.PartDescription, PA.SerialNumber, PA.Qty, PA.BillingMethod, PA.BillingFrequency,
				CAST(NULL AS DECIMAL(18,6)) AS FlatRate,
				'Charges' AS LineType,
				PA.PeriodFromDate AS FromDate, PA.PeriodToDate AS ToDate,
				SUM(ISNULL(LC.ExtendedCost, 0)) AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded, CAST(NULL AS DECIMAL(18,6)) AS TimeLimit, CAST(NULL AS DECIMAL(18,6)) AS TimeOver, CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate, CAST(NULL AS DECIMAL(18,6)) AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded, CAST(NULL AS DECIMAL(18,6)) AS CycleLimit, CAST(NULL AS DECIMAL(18,6)) AS CycleOver, CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate, CAST(NULL AS DECIMAL(18,6)) AS CycleBillingAmount,
				PA.BillingInvoicingId, 'N' AS BillingStatus, PA.InvoiceNo AS InvoiceNumber, PA.InvoiceDate, PA.HasUsageInfo, PA.IsActive, PA.LeaseStatusId,
				PA.PeriodSeq, 10 AS LineSortOrder
			FROM PeriodAmounts3 PA
			INNER JOIN StocklineBase SB ON SB.LeaseStocklineId = PA.LeaseStocklineId
			INNER JOIN [dbo].[LeaseCharges] LC WITH (NOLOCK)
				ON LC.LeaseStocklineId = PA.LeaseStocklineId AND LC.IsDeleted = 0 AND ISNULL(LC.IsInvoiced, 0) = 0 AND LC.BillingInvoicingItemId IS NULL
				AND CAST(LC.ReportedDate AS DATE) BETWEEN CAST(PA.PeriodFromDate AS DATE) AND CAST(PA.PeriodToDate AS DATE)
			GROUP BY PA.LeaseStocklineId, PA.PartNumber, PA.PartDescription, PA.SerialNumber, PA.Qty, PA.BillingMethod, PA.BillingFrequency,
				PA.PeriodFromDate, PA.PeriodToDate, PA.BillingInvoicingId, PA.InvoiceNo, PA.InvoiceDate, PA.HasUsageInfo, PA.IsActive, PA.LeaseStatusId, PA.PeriodSeq
			HAVING SUM(ISNULL(LC.ExtendedCost, 0)) > 0
		),
		ChargesNoPeriod AS (
			SELECT
				SB.LeaseStocklineId, SB.PartNumber, SB.PartDescription, SB.SerialNumber, SB.Qty, SB.BillingMethod, SB.BillingFrequency,
				CAST(NULL AS DECIMAL(18,6)) AS FlatRate,
				'Charges' AS LineType,
				CAST(NULL AS DATETIME2(7)) AS FromDate, CAST(NULL AS DATETIME2(7)) AS ToDate,
				SUM(ISNULL(LC.ExtendedCost, 0)) AS LineAmount,
				CAST(NULL AS DECIMAL(18,6)) AS TimeRecorded, CAST(NULL AS DECIMAL(18,6)) AS TimeLimit, CAST(NULL AS DECIMAL(18,6)) AS TimeOver, CAST(NULL AS DECIMAL(18,6)) AS TimeOverageRate, CAST(NULL AS DECIMAL(18,6)) AS TimeBillingAmount,
				CAST(NULL AS DECIMAL(18,6)) AS CycleRecorded, CAST(NULL AS DECIMAL(18,6)) AS CycleLimit, CAST(NULL AS DECIMAL(18,6)) AS CycleOver, CAST(NULL AS DECIMAL(18,6)) AS CycleOverageRate, CAST(NULL AS DECIMAL(18,6)) AS CycleBillingAmount,
				SB.BillingInvoicingId, 'N' AS BillingStatus, SB.InvoiceNo AS InvoiceNumber, SB.InvoiceDate, SB.HasUsageInfo, SB.IsActive, SB.LeaseStatusId,
				CAST(0 AS BIGINT) AS PeriodSeq, 10 AS LineSortOrder
			FROM StocklineBase SB
			INNER JOIN [dbo].[LeaseCharges] LC WITH (NOLOCK) ON LC.LeaseStocklineId = SB.LeaseStocklineId AND LC.IsDeleted = 0
			WHERE ISNULL(LC.IsInvoiced, 0) = 0 AND LC.BillingInvoicingItemId IS NULL
			  AND NOT EXISTS (
				SELECT 1 FROM PeriodAmounts3 PA2
				WHERE PA2.LeaseStocklineId = SB.LeaseStocklineId
				  AND CAST(LC.ReportedDate AS DATE) BETWEEN CAST(PA2.PeriodFromDate AS DATE) AND CAST(PA2.PeriodToDate AS DATE)
			  )
			GROUP BY SB.LeaseStocklineId, SB.PartNumber, SB.PartDescription, SB.SerialNumber, SB.Qty, SB.BillingMethod, SB.BillingFrequency,
				SB.BillingInvoicingId, SB.InvoiceNo, SB.InvoiceDate, SB.HasUsageInfo, SB.IsActive, SB.LeaseStatusId
			HAVING SUM(ISNULL(LC.ExtendedCost, 0)) > 0
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
			  AND UPPER(LTRIM(RTRIM(ISNULL(SB.RateUnit, '')))) IN ('MONTH', '')
			  AND NOT EXISTS (SELECT 1 FROM PeriodAmounts3 PA WHERE PA.LeaseStocklineId = SB.LeaseStocklineId)
			  AND NOT EXISTS (SELECT 1 FROM OpenDraftLines OD WHERE OD.LeaseStocklineId = SB.LeaseStocklineId AND OD.LineType = 'Flat Rate')
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
				LBID.LineType AS LineType,
				LBID.FromDate AS FromDate, LBID.ToDate AS ToDate,
				-- Stored LineAmount is the line's FULL total (flat fee + Time/Cycle billing). The grid's Total column adds
				-- LineAmount + TimeBillingAmount + CycleBillingAmount, so hand it only the part not already in those two columns.
				CASE WHEN LBID.LineAmount IS NULL THEN NULL ELSE LBID.LineAmount - ISNULL(LBID.TimeBillingAmount, 0) - ISNULL(LBID.CycleBillingAmount, 0) END AS LineAmount,
				CASE WHEN LBID.TimeRecorded IS NOT NULL THEN (CASE WHEN LBID.TimeRecorded * 60 < 0 THEN 0 ELSE LBID.TimeRecorded * 60 END) ELSE NULL END AS TimeRecorded,
				CASE WHEN LBID.TimeLimit IS NOT NULL THEN (CASE WHEN LBID.TimeLimit * 60 < 0 THEN 0 ELSE LBID.TimeLimit * 60 END) ELSE NULL END AS TimeLimit,
				CASE WHEN LBID.TimeOver IS NOT NULL THEN (CASE WHEN LBID.TimeOver * 60 < 0 THEN 0 ELSE LBID.TimeOver * 60 END) ELSE NULL END AS TimeOver,
				CASE WHEN LBID.TimeOverageRate IS NOT NULL THEN (CASE WHEN LBID.TimeOverageRate < 0 THEN 0 ELSE LBID.TimeOverageRate END) ELSE NULL END AS TimeOverageRate,
				LBID.TimeBillingAmount AS TimeBillingAmount,
				CASE WHEN LBID.CycleRecorded IS NOT NULL THEN (CASE WHEN LBID.CycleRecorded < 0 THEN 0 ELSE LBID.CycleRecorded END) ELSE NULL END AS CycleRecorded,
				CASE WHEN LBID.CycleLimit IS NOT NULL THEN (CASE WHEN LBID.CycleLimit < 0 THEN 0 ELSE LBID.CycleLimit END) ELSE NULL END AS CycleLimit,
				CASE WHEN LBID.CycleOver IS NOT NULL THEN (CASE WHEN LBID.CycleOver < 0 THEN 0 ELSE LBID.CycleOver END) ELSE NULL END AS CycleOver,
				CASE WHEN LBID.CycleOverageRate IS NOT NULL THEN (CASE WHEN LBID.CycleOverageRate < 0 THEN 0 ELSE LBID.CycleOverageRate END) ELSE NULL END AS CycleOverageRate,
				LBID.CycleBillingAmount AS CycleBillingAmount,
				BI.BillingInvoicingId, CASE WHEN ISNULL(BI.IsInvoicePosted, 0) = 1 THEN 'Y' ELSE 'D' END AS BillingStatus, BI.InvoiceNo AS InvoiceNumber, BI.InvoiceDate,
				CAST(1 AS BIT) AS HasUsageInfo, LSL.IsActive, LSL.LeaseStatusId,
				CAST(0 AS BIGINT) AS PeriodSeq,
				CASE LBID.LineType WHEN 'Flat Rate' THEN 1 WHEN 'Overrun' THEN 2 ELSE 3 END AS LineSortOrder
			FROM [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH (NOLOCK)
			INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.LeaseStocklineId = LBID.LeaseStocklineId
			LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
			INNER JOIN [dbo].[BillingInvoicingItems] BII WITH (NOLOCK) ON BII.BillingInvoicingItemId = LBID.BillingInvoicingItemId AND BII.IsDeleted = 0 AND ISNULL(BII.IsVersionIncrease, 0) = 0
			INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK) ON BI.BillingInvoicingId = BII.BillingInvoicingId
			WHERE LSL.LeaseHeaderId = @LeaseHeaderId AND LSL.IsDeleted = 0 AND ISNULL(LBID.IsDeleted, 0) = 0 AND ISNULL(LBID.IsVersionIncrease, 0) = 0
			  AND NOT (LBID.LineType = 'Overrun' AND ISNULL(LBID.LineAmount, 0) = 0)
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
			-- Pending rows have not been invoiced yet: don't show the stockline's previous/draft invoice reference on them
			CASE WHEN BillingStatus = 'N' THEN NULL ELSE BillingInvoicingId END AS BillingInvoicingId,
			BillingStatus,
			CASE WHEN BillingStatus = 'N' THEN NULL ELSE InvoiceNumber END AS InvoiceNumber,
			CASE WHEN BillingStatus = 'N' THEN NULL ELSE InvoiceDate END AS InvoiceDate,
			HasUsageInfo,
			IsActive,
			LeaseStatusId
		FROM (
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM PeriodLines
			UNION ALL
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM OneTimeLines
			UNION ALL
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM ChargesByPeriod
			UNION ALL
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM ChargesNoPeriod
			UNION ALL
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM FlatRateNoPeriod
			UNION ALL
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM GenericFallback
			UNION ALL
			SELECT LeaseStocklineId, PartNumber, PartDescription, SerialNumber, Qty, BillingMethod, BillingFrequency, FlatRate, LineType, FromDate, ToDate, LineAmount, TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount, CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, BillingInvoicingId, BillingStatus, InvoiceNumber, InvoiceDate, HasUsageInfo, IsActive, LeaseStatusId, PeriodSeq, LineSortOrder FROM InvoicedLines
		) AllLines
		ORDER BY LeaseStocklineId, BillingStatus,
			CASE WHEN LineSortOrder >= 6 THEN 1 ELSE 0 END,
			PeriodSeq, LineSortOrder;

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