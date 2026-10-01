

/*************************************************************
 ** File:   [USP_CreateLeaseBillingInvoice]
 ** Description: Creates a Billing Invoice for a set of selected LeaseStockline rows
 **              (the "Create Invoice" button on the Lease Billing/Invoicing grid,
 **              Uses the shared BillingInvoicing (header) / BillingInvoicingItems
 **              (line item) / BillingInvoicingDetails (Bill To/Ship To/Ship Via)
 **              tables with ModuleId/SubModuleId = 72 (AppModuleEnum.Leasing -
 **              confirmed with the requester: 10 = SalesOrder, 15 = WorkOrder,
 **              72 = Leasing), same tables the SalesOrder/WorkOrder "Billing
 **              Invoice" popup writes to. SubReferenceId is the LeaseStocklineId
 **              being billed. LeaseBillingInvoicingItemDetails stores the
 **              Lease-only Time/Cycle snapshot per item (BillingInvoicingItems has
 **              no matching columns - see that table's header comment). It still holds
 **              one row per stockline per invoice (a SUM across whichever periods this
 **              invoice covered), not one row per period - the Invoiced tab on the
 **              Pending/Invoiced grid is not restructured to the new per-period shape
 **              (see USP_GetLeaseBillingListByLeaseHeaderId's header comment).
 **
 **              Invoice numbering follows the same CodeTypes/CodePrefixes
 **              convention as SOInvoice/WOInvoice (USP_AddBillingInvoicingDetails)
 **              - add a 'LeaseInvoice' CodeType + CodePrefix (Admin > Code Prefix
 **              Setup) to get a proper prefixed/sequential number. Until that
 **              master data exists, falls back to an always-unique
 **              'LSE######' number derived from the new invoice's own identity
 **              value, so invoicing isn't blocked on that setup step.
 **
 **              Bill To / Ship To follow the same Customer+Site shape
 **              BillingInvoicingDetails already uses for SO/WO (SoldTo.../
 **              ShipTo...) - the popup defaults both to the lease's own customer
 **              but the user can repoint either to a different customer/site,
 **              same as the SO/WO popup allows.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    18/09/2026     Kishor Makwana          [PN-17949] Created
	2    18/09/2026     Kishor Makwana          [PN-17949] Added the remaining Billing Invoice popup fields (Time/Print Date/Ship Date/Currency, Bill To/Ship To, Ship Via/Shipping Acct Info/Terms) to match the SO/WO popup's full field set.
	3    25/09/2026     Kishor Makwana          [PN-18072 follow-up 5] Added Maintenance/Insurance/Taxes/Other (Add Item tab Service Component amounts, Other = SUM of active dynamic
	                                            LeaseStocklineServiceComponent rows) into TotalBillingAmount, unconditionally like Charges - matches the same addition just made to
	                                            USP_GetLeaseBillingListByLeaseHeaderId so the persisted invoice total reconciles with the Billing/Invoicing grid's Total Billing column. Not
	                                            snapshotted into LeaseBillingInvoicingItemDetails (same treatment as Charges above - live-joined only, folded into TotalBillingAmount/GrandTotal).
	4    28/09/2026     Kishor Makwana          [PN-17949 follow-up] Persist the base-usage breakdown so the finalized invoice PDF's per-line Qty x Rate = Total stays consistent. Added
	                                            TimeUsageQty/TimeUsageRate/TimeUsageAmount and CycleUsageQty/ CycleUsageRate/CycleUsageAmount to LeaseBillingInvoicingItemDetails
	                                            (see table/audit/trigger changes) and now populate them here from TimeBilledBaseRaw/TimeUsageRateRaw and CycleBilledBaseRaw/
	                                            CycleUsageRateRaw, alongside the existing overage-only TimeOver/ TimeOverageRate/CycleOver/CycleOverageRate columns. Without this,
	                                            RPT_GetCommonBillingInvoicingItems_Lease had no way to show separate 'Time Usage'/'Cycle Usage' line items on the finalized invoice - only
	                                            the combined TimeBillingAmount/CycleBillingAmount was available.
	5    30/09/2026     Kishor Makwana          [PN-18072 multi-period follow-up] Customer requirement: reworked Time/Cycle calc to SUM across every currently-pending usage PERIOD
	                                            (LeaseStocklineUsageHistory, IsInvoiced = 0) instead of a single live LeaseStocklineUsage snapshot, so a stockline with several unbilled
	                                            months gets them all rolled into one invoice. Flat Rate now multiplies by the pending period count (or 1 if there were no usage periods at
	                                            all) to match the Pending grid, which shows a Flat Rate line on every period. Maintenance/Insurance/Taxes/Other/Charges are now gated on
	                                            LeaseStockline.IsInvoicePost = 0 (previously Charges/Maintenance/Insurance/Taxes/Other were summed unconditionally every time - a latent
	                                            double-count on a stockline invoiced more than once, now fixed as a side effect of this change). Added the two closing UPDATEs: marks every
	                                            covered LeaseStocklineUsageHistory row IsInvoiced = 1 + this invoice's BillingInvoicingItemId, and sets LeaseStockline.IsInvoicePost = 1 -
	                                            see LeaseBilling_MultiPeriod_Schema.sql for both new columns. Also added a WHERE filter dropping a stockline from this run entirely when it
	                                            has zero pending periods AND IsInvoicePost is already 1 (genuinely nothing left to bill), instead of still inserting a $0 invoice line for it.

DECLARE @Ids dbo.TVP_BigInt;
INSERT INTO @Ids (Value) VALUES (1), (2);
EXEC USP_CreateLeaseBillingInvoice @LeaseHeaderId = 1, @LeaseStocklineIds = @Ids,
    @SoldToCustomerId = 1, @SoldToSiteId = 1, @ShipToCustomerId = 1, @ShipToSiteId = 1,
    @MasterCompanyId = 1, @CreatedBy = 'test'
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_CreateLeaseBillingInvoice]
	@LeaseHeaderId BIGINT,
	@LeaseStocklineIds [dbo].[TVP_BigInt] READONLY,
	@InvoiceTypeId INT = NULL,
	@InvoiceDate DATETIME2(7) = NULL,
	@InvoiceTime VARCHAR(10) = NULL,
	@PrintDate DATETIME2(7) = NULL,
	@ShipDate DATETIME2(7) = NULL,
	@CurrencyId INT = NULL,
	@EmployeeId BIGINT = NULL,
	@Notes NVARCHAR(MAX) = NULL,
	@SoldToCustomerId BIGINT,
	@SoldToSiteId BIGINT,
	@SoldToAttention VARCHAR(256) = NULL,
	@ShipToCustomerId BIGINT,
	@ShipToSiteId BIGINT,
	@ShipToAttention VARCHAR(256) = NULL,
	@ShipViaId BIGINT = NULL,
	@ShipAccountInfo VARCHAR(200) = NULL,
	@ShippingTermsName VARCHAR(256) = NULL,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @CustomerId BIGINT, @ManagementStructureId BIGINT, @SalespersonEmployeeId BIGINT, @HeaderEmployeeId BIGINT, @LocalCurrencyId INT,@LeaseModuleId BIGINT;

		SELECT TOP 1 @LeaseModuleId = ModuleId from Module WITH (NOLOCK) WHERE ModuleName ='Leasing';
		SELECT
			@CustomerId = CustomerId,
			@ManagementStructureId = ManagementStructureId,
			@SalespersonEmployeeId = SalespersonEmployeeId,
			@HeaderEmployeeId = EmployeeId,
			@LocalCurrencyId = LocalCurrencyId
		FROM [dbo].[LeaseHeader] WITH (NOLOCK)
		WHERE LeaseHeaderId = @LeaseHeaderId AND IsDeleted = 0;

		IF (@CustomerId IS NULL)
		BEGIN
			RAISERROR('Lease Header was not found.', 16, 1);
			RETURN (1);
		END

		IF NOT EXISTS (SELECT 1 FROM @LeaseStocklineIds)
		BEGIN
			RAISERROR('At least one lease stockline must be selected for billing.', 16, 1);
			RETURN (1);
		END

		SET @EmployeeId = ISNULL(@EmployeeId, ISNULL(@SalespersonEmployeeId, @HeaderEmployeeId));
		IF (@EmployeeId IS NULL)
		BEGIN
			RAISERROR('An Employee/Sales Person is required to create the invoice.', 16, 1);
			RETURN (1);
		END

		IF (ISNULL(@InvoiceTypeId, 0) = 0)
		BEGIN
			SELECT TOP 1 @InvoiceTypeId = InvoiceTypeId FROM [dbo].[InvoiceType] WITH (NOLOCK)
			WHERE MasterCompanyId = @MasterCompanyId AND [Description] = 'STANDARD' AND IsActive = 1 AND IsDeleted = 0;
		END
		IF (@InvoiceTypeId IS NULL)
		BEGIN
			RAISERROR('No active ''STANDARD'' Invoice Type is configured for this company.', 16, 1);
			RETURN (1);
		END

		IF (ISNULL(@SoldToCustomerId, 0) = 0 OR ISNULL(@SoldToSiteId, 0) = 0)
		BEGIN
			RAISERROR('Bill To Customer and Site are required to create the invoice.', 16, 1);
			RETURN (1);
		END
		IF (ISNULL(@ShipToCustomerId, 0) = 0 OR ISNULL(@ShipToSiteId, 0) = 0)
		BEGIN
			RAISERROR('Ship To Customer and Site are required to create the invoice.', 16, 1);
			RETURN (1);
		END

		SET @InvoiceDate = ISNULL(@InvoiceDate, GETUTCDATE());
		SET @CurrencyId = ISNULL(@CurrencyId, @LocalCurrencyId);

		;WITH StocklineBase AS (
			SELECT
				LSL.LeaseStocklineId,
				LSL.ItemMasterId,
				LSL.StockLineId,
				LSL.ConditionId,
				SLIVE.SerialNumber,
				LSL.QtyReserved AS Qty,
				LSL.BillingMethod,
				LSL.BillingInterval AS BillingFrequency,
				LSL.FlatRate,
				CASE WHEN LSL.MaximumTimes IS NOT NULL THEN LSL.MaximumTimes * 60 ELSE NULL END AS TimeLimit,
				CASE WHEN LSL.MinimumTimes IS NOT NULL THEN LSL.MinimumTimes * 60 ELSE NULL END AS TimeMinimum,
				LSL.UsagePerUnitTimes,
				LSL.OverrunPerUnitTimes,
				LSL.MaximumCycles AS CycleLimit,
				LSL.MinimumCycles AS CycleMinimum,
				LSL.UsagePerUnitCycles,
				LSL.OverrunPerUnitCycles,
				LSL.IsInvoicePost,
				ISNULL(ChargesAgg.Charges, 0) AS Charges,
				LSL.[Maintenance],
				LSL.[Insurance],
				LSL.[Taxes],
				ISNULL(SC_SUM.OtherComponentAmount, 0) AS OtherComponentAmount,
				CASE WHEN LSL.BillingMethod IN ('FlatRatePlusOverrun', 'UsageBased') THEN 1 ELSE 0 END AS IsOverageBillingMethod,
				CASE WHEN LSL.BillingMethod IN ('FlatRateOnly', 'FlatRatePlusOverrun') THEN 1 ELSE 0 END AS IsFlatRateBillingMethod
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			INNER JOIN @LeaseStocklineIds SEL ON SEL.Value = LSL.LeaseStocklineId
			LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
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
				H.IsInvoiced,
				(ISNULL(H.TSNHours, 0) * 60 + ISNULL(H.TSNMinutes, 0)) AS TimeReadingAbs,
				LAG(ISNULL(H.TSNHours, 0) * 60 + ISNULL(H.TSNMinutes, 0)) OVER (
					PARTITION BY H.LeaseStocklineId ORDER BY H.CreatedDate, H.LeaseStocklineUsageHistoryId
				) AS PriorTimeReadingAbs
			FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
			INNER JOIN @LeaseStocklineIds SEL ON SEL.Value = H.LeaseStocklineId
			WHERE H.UsageType = 'T' AND H.IsActive = 1 AND H.IsDeleted = 0
		),
		CycleSeries AS (
			SELECT
				H.LeaseStocklineId,
				H.LeaseStocklineUsageHistoryId,
				H.CreatedDate AS PeriodKey,
				H.IsInvoiced,
				ISNULL(H.CSN, 0) AS CycleReadingAbs,
				LAG(ISNULL(H.CSN, 0)) OVER (
					PARTITION BY H.LeaseStocklineId ORDER BY H.CreatedDate, H.LeaseStocklineUsageHistoryId
				) AS PriorCycleReadingAbs
			FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
			INNER JOIN @LeaseStocklineIds SEL ON SEL.Value = H.LeaseStocklineId
			WHERE H.UsageType = 'C' AND H.IsActive = 1 AND H.IsDeleted = 0
		),
		Periods AS (
			SELECT
				COALESCE(T.LeaseStocklineId, C.LeaseStocklineId) AS LeaseStocklineId,
				COALESCE(T.PeriodKey, C.PeriodKey) AS PeriodKey,
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
				P.TimePending,
				P.TimeReadingAbs,
				P.PriorTimeReadingAbs,
				P.CyclePending,
				P.CycleReadingAbs,
				P.PriorCycleReadingAbs,
				S.Qty,
				S.TimeLimit,
				S.TimeMinimum,
				S.UsagePerUnitTimes,
				S.OverrunPerUnitTimes,
				S.CycleLimit,
				S.CycleMinimum,
				S.UsagePerUnitCycles,
				S.OverrunPerUnitCycles,
				S.IsOverageBillingMethod
			FROM Periods P
			INNER JOIN StocklineBase S ON S.LeaseStocklineId = P.LeaseStocklineId
			WHERE P.TimePending = 1 OR P.CyclePending = 1
		),
		PeriodAmounts AS (
			SELECT
				LeaseStocklineId,
				PeriodKey,
				TimePending,
				TimeReadingAbs,
				PriorTimeReadingAbs,
				CyclePending,
				CycleReadingAbs,
				PriorCycleReadingAbs,
				Qty,
				TimeLimit,
				TimeMinimum,
				UsagePerUnitTimes,
				OverrunPerUnitTimes,
				CycleLimit,
				CycleMinimum,
				UsagePerUnitCycles,
				OverrunPerUnitCycles,
				IsOverageBillingMethod,
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
				TimePending,
				TimeReadingAbs,
				PriorTimeReadingAbs,
				CyclePending,
				CycleReadingAbs,
				PriorCycleReadingAbs,
				Qty,
				TimeLimit,
				TimeMinimum,
				UsagePerUnitTimes,
				OverrunPerUnitTimes,
				CycleLimit,
				CycleMinimum,
				UsagePerUnitCycles,
				OverrunPerUnitCycles,
				IsOverageBillingMethod,
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
				TimePending,
				TimeReadingAbs,
				PriorTimeReadingAbs,
				CyclePending,
				CycleReadingAbs,
				PriorCycleReadingAbs,
				Qty,
				TimeLimit,
				TimeMinimum,
				UsagePerUnitTimes,
				OverrunPerUnitTimes,
				CycleLimit,
				CycleMinimum,
				UsagePerUnitCycles,
				OverrunPerUnitCycles,
				IsOverageBillingMethod,
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
		PeriodCounts AS (
			SELECT LeaseStocklineId, COUNT(*) AS PendingPeriodCount
			FROM PeriodAmounts3
			GROUP BY LeaseStocklineId
		),
		PeriodTotals AS (
			SELECT
				LeaseStocklineId,
				SUM(ISNULL(TimeUsageQty, 0)) AS TimeRecordedTotal,
				SUM(CASE WHEN IsOverageBillingMethod = 1 AND TimeUsageQty IS NOT NULL THEN (TimeUsageQty / 60.0) * ISNULL(UsagePerUnitTimes, 0) * Qty ELSE 0 END) AS TimeUsageAmountTotal,
				SUM(ISNULL(TimeOverMinutes, 0)) AS TimeOverTotal,
				SUM(CASE WHEN IsOverageBillingMethod = 1 AND TimeOverMinutes IS NOT NULL THEN (TimeOverMinutes / 60.0) * ISNULL(OverrunPerUnitTimes, 0) * Qty ELSE 0 END) AS TimeOverageAmountTotal,
				SUM(ISNULL(CycleUsageQty, 0)) AS CycleRecordedTotal,
				SUM(CASE WHEN IsOverageBillingMethod = 1 AND CycleUsageQty IS NOT NULL THEN CycleUsageQty * ISNULL(UsagePerUnitCycles, 0) * Qty ELSE 0 END) AS CycleUsageAmountTotal,
				SUM(ISNULL(CycleOverCount, 0)) AS CycleOverTotal,
				SUM(CASE WHEN IsOverageBillingMethod = 1 AND CycleOverCount IS NOT NULL THEN CycleOverCount * ISNULL(OverrunPerUnitCycles, 0) * Qty ELSE 0 END) AS CycleOverageAmountTotal
			FROM PeriodAmounts3
			GROUP BY LeaseStocklineId
		)
		SELECT
			S.LeaseStocklineId, S.ItemMasterId, S.StockLineId, S.ConditionId, S.SerialNumber, S.Qty,
			S.BillingMethod, S.BillingFrequency,
			FlatRate = CASE WHEN S.IsFlatRateBillingMethod = 1 THEN S.FlatRate ELSE NULL END,
			FlatRateAmount = CASE WHEN S.IsFlatRateBillingMethod = 1 THEN ISNULL(S.FlatRate, 0) * S.Qty * ISNULL(PC.PendingPeriodCount, 1) ELSE NULL END,
			TimeRecorded = CASE WHEN S.IsOverageBillingMethod = 1 THEN PT.TimeRecordedTotal ELSE NULL END,
			TimeLimit = CASE WHEN S.IsOverageBillingMethod = 1 THEN S.TimeLimit ELSE NULL END,
			TimeOver = CASE WHEN S.IsOverageBillingMethod = 1 THEN PT.TimeOverTotal ELSE NULL END,
			TimeOverageRate = CASE WHEN S.IsOverageBillingMethod = 1 THEN S.OverrunPerUnitTimes ELSE NULL END,
			TimeBillingAmount = CASE WHEN S.IsOverageBillingMethod = 1 THEN ISNULL(PT.TimeUsageAmountTotal, 0) + ISNULL(PT.TimeOverageAmountTotal, 0) ELSE NULL END,
			TimeUsageQty = CASE WHEN S.IsOverageBillingMethod = 1 THEN PT.TimeRecordedTotal / 60.0 ELSE NULL END,
			TimeUsageRate = CASE WHEN S.IsOverageBillingMethod = 1 THEN S.UsagePerUnitTimes ELSE NULL END,
			TimeUsageAmount = CASE WHEN S.IsOverageBillingMethod = 1 THEN PT.TimeUsageAmountTotal ELSE NULL END,
			CycleRecorded = CASE WHEN S.IsOverageBillingMethod = 1 THEN PT.CycleRecordedTotal ELSE NULL END,
			CycleLimit = CASE WHEN S.IsOverageBillingMethod = 1 THEN S.CycleLimit ELSE NULL END,
			CycleOver = CASE WHEN S.IsOverageBillingMethod = 1 THEN PT.CycleOverTotal ELSE NULL END,
			CycleOverageRate = CASE WHEN S.IsOverageBillingMethod = 1 THEN S.OverrunPerUnitCycles ELSE NULL END,
			CycleBillingAmount = CASE WHEN S.IsOverageBillingMethod = 1 THEN ISNULL(PT.CycleUsageAmountTotal, 0) + ISNULL(PT.CycleOverageAmountTotal, 0) ELSE NULL END,
			CycleUsageQty = CASE WHEN S.IsOverageBillingMethod = 1 THEN PT.CycleRecordedTotal ELSE NULL END,
			CycleUsageRate = CASE WHEN S.IsOverageBillingMethod = 1 THEN S.UsagePerUnitCycles ELSE NULL END,
			CycleUsageAmount = CASE WHEN S.IsOverageBillingMethod = 1 THEN PT.CycleUsageAmountTotal ELSE NULL END,
			ChargesAmount = S.Charges,
			Maintenance = S.[Maintenance], Insurance = S.[Insurance], Taxes = S.[Taxes], OtherComponentAmount = S.OtherComponentAmount,
			S.IsInvoicePost,
			ISNULL(PC.PendingPeriodCount, 0) AS PendingPeriodCount,
			TotalBillingAmount =
					ISNULL(CASE WHEN S.IsFlatRateBillingMethod = 1 THEN ISNULL(S.FlatRate, 0) * S.Qty * ISNULL(PC.PendingPeriodCount, 1) ELSE 0 END, 0)
				  + ISNULL(CASE WHEN S.IsOverageBillingMethod = 1 THEN ISNULL(PT.TimeUsageAmountTotal, 0) + ISNULL(PT.TimeOverageAmountTotal, 0) ELSE 0 END, 0)
				  + ISNULL(CASE WHEN S.IsOverageBillingMethod = 1 THEN ISNULL(PT.CycleUsageAmountTotal, 0) + ISNULL(PT.CycleOverageAmountTotal, 0) ELSE 0 END, 0)
				  + CASE WHEN S.IsInvoicePost = 0 THEN ISNULL(S.Charges, 0) + ISNULL(S.[Maintenance], 0) + ISNULL(S.[Insurance], 0) + ISNULL(S.[Taxes], 0) + ISNULL(S.OtherComponentAmount, 0) ELSE 0 END
		INTO #LeaseBillingCalc
		FROM StocklineBase S
		LEFT JOIN PeriodCounts PC ON PC.LeaseStocklineId = S.LeaseStocklineId
		LEFT JOIN PeriodTotals PT ON PT.LeaseStocklineId = S.LeaseStocklineId
		WHERE NOT (ISNULL(PC.PendingPeriodCount, 0) = 0 AND S.IsInvoicePost = 1);

		IF NOT EXISTS (SELECT 1 FROM #LeaseBillingCalc)
		BEGIN
			RAISERROR('None of the selected lease stocklines are eligible for billing (inactive, not reserved, or nothing left to bill).', 16, 1);
			RETURN (1);
		END

		BEGIN TRANSACTION

		DECLARE @GrandTotal DECIMAL(18, 6);
		SELECT @GrandTotal = SUM(ISNULL(TotalBillingAmount, 0)) FROM #LeaseBillingCalc;

		-- Placeholder InvoiceNo (InvoiceNo is NOT NULL) - replaced below once we know the new
		-- BillingInvoicingId, in case no 'LeaseInvoice' CodePrefix has been configured yet.
		INSERT INTO [dbo].[BillingInvoicing]
			(ModuleId, ReferenceId, CustomerId, InvoiceTypeId, InvoiceNo, InvoiceDate, InvoiceTime, PrintDate,
			 EmployeeId, CurrencyId, ManagementStructureId, Notes, SubTotal, GrandTotal, MasterCompanyId, CreatedBy, UpdatedBy)
		VALUES
			(@LeaseModuleId, @LeaseHeaderId, @CustomerId, @InvoiceTypeId, 'PENDING', @InvoiceDate, @InvoiceTime, @PrintDate,
			 @EmployeeId, @CurrencyId, @ManagementStructureId, @Notes, @GrandTotal, @GrandTotal, @MasterCompanyId, @CreatedBy, @CreatedBy);

		DECLARE @BillingInvoicingId BIGINT = SCOPE_IDENTITY();

		DECLARE @LeaseInvoiceCodeTypeId INT, @CodePrefix NVARCHAR(50), @CodeSuffix NVARCHAR(50), @CurrentNo INT = 0, @InvoiceNo VARCHAR(256);

		SELECT @LeaseInvoiceCodeTypeId = CodeTypeId FROM [dbo].[CodeTypes] WITH (NOLOCK)
		WHERE CodeType = 'LeaseInvoice' AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

		IF (@LeaseInvoiceCodeTypeId IS NOT NULL)
		BEGIN
			SELECT TOP 1 @CodePrefix = CodePrefix, @CodeSuffix = CodeSufix FROM [dbo].[CodePrefixes] WITH (NOLOCK)
			WHERE CodeTypeId = @LeaseInvoiceCodeTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;
		END

		IF (COALESCE(@CodePrefix, '') <> '')
		BEGIN
			SELECT @CurrentNo = ISNULL(CurrentNummber, 0) FROM [dbo].[CodePrefixes] WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId;
			IF (@CurrentNo > 0)
			BEGIN
				SET @CurrentNo = @CurrentNo + 1;
				UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @CurrentNo WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId;
			END
			ELSE
			BEGIN
				SET @CurrentNo = (SELECT ISNULL(StartsFrom, 0) FROM [dbo].[CodePrefixes] WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId) + 1;
				UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @CurrentNo WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId;
			END
			SET @InvoiceNo = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNo, ISNULL(@CodePrefix, ''), ISNULL(@CodeSuffix, '')));
		END
		ELSE
		BEGIN			
			DECLARE @LastInvoiceNo VARCHAR(256);
			DECLARE @LastInvoiceNumber INT;

			-- Get the last Leasing invoice number
			SELECT TOP 1 @LastInvoiceNo = InvoiceNo	FROM [dbo].[BillingInvoicing] WITH (UPDLOCK, HOLDLOCK) 	
			WHERE ModuleId = @LeaseModuleId   AND InvoiceNo LIKE 'LSI-%' AND ISNUMERIC(REPLACE(InvoiceNo, 'LSI-', '')) = 1
			ORDER BY BillingInvoicingId DESC;

			-- Get numeric portion
			SET @LastInvoiceNumber =ISNULL(TRY_CAST(REPLACE(@LastInvoiceNo, 'LSI-', '') AS INT),0);

			-- Increment
			SET @LastInvoiceNumber = @LastInvoiceNumber + 1;
			SET @InvoiceNo = 'LSI-' + RIGHT('000000' + CAST(@LastInvoiceNumber AS VARCHAR(20)), 6);
		END

		UPDATE [dbo].[BillingInvoicing] SET InvoiceNo = @InvoiceNo WHERE BillingInvoicingId = @BillingInvoicingId;

		INSERT INTO [dbo].[BillingInvoicingDetails]
			(BillingInvoicingId, SoldToCustomerId, SoldToSiteId, SoldToAttention,
			 ShipToCustomerId, ShipToSiteId, ShipToAttention, ShipviaId, ShipAccountInfo, ShippingTermsName)
		VALUES
			(@BillingInvoicingId, @SoldToCustomerId, @SoldToSiteId, @SoldToAttention,
			 @ShipToCustomerId, @ShipToSiteId, @ShipToAttention, @ShipViaId, @ShipAccountInfo, @ShippingTermsName);

		DECLARE @InsertedItems TABLE (BillingInvoicingItemId BIGINT, LeaseStocklineId BIGINT);

		INSERT INTO [dbo].[BillingInvoicingItems]
			(BillingInvoicingId, ModuleId, ReferenceId, SubModuleId, SubReferenceId, ItemMasterId, StocklineId, ConditionId,
			 SerialNumber, GrandTotal, ShipDate, MasterCompanyId, CreatedBy, UpdatedBy)
		OUTPUT inserted.BillingInvoicingItemId, inserted.SubReferenceId INTO @InsertedItems (BillingInvoicingItemId, LeaseStocklineId)
		SELECT
			@BillingInvoicingId, @LeaseModuleId, @LeaseHeaderId, @LeaseModuleId, LeaseStocklineId, ItemMasterId, StockLineId, ConditionId,
			SerialNumber, TotalBillingAmount, @ShipDate, @MasterCompanyId, @CreatedBy, @CreatedBy
		FROM #LeaseBillingCalc;

		INSERT INTO [dbo].[LeaseBillingInvoicingItemDetails]
			(BillingInvoicingItemId, LeaseStocklineId, BillingMethod, BillingFrequency,
			 FlatRate, FlatRateAmount,
			 TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount,
			 CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, TotalBillingAmount,
			 TimeUsageQty, TimeUsageRate, TimeUsageAmount, CycleUsageQty, CycleUsageRate, CycleUsageAmount,
			 MasterCompanyId, CreatedBy, UpdatedBy)
		SELECT
			II.BillingInvoicingItemId, C.LeaseStocklineId, C.BillingMethod, C.BillingFrequency,
			C.FlatRate, C.FlatRateAmount,
			CASE WHEN C.TimeRecorded IS NOT NULL THEN C.TimeRecorded / 60 ELSE NULL END,
			CASE WHEN C.TimeLimit IS NOT NULL THEN C.TimeLimit / 60 ELSE NULL END,
			CASE WHEN C.TimeOver IS NOT NULL THEN C.TimeOver / 60 ELSE NULL END,
			C.TimeOverageRate, C.TimeBillingAmount,
			C.CycleRecorded, C.CycleLimit, C.CycleOver, C.CycleOverageRate, C.CycleBillingAmount, C.TotalBillingAmount,
			C.TimeUsageQty, C.TimeUsageRate, C.TimeUsageAmount, C.CycleUsageQty, C.CycleUsageRate, C.CycleUsageAmount,
			@MasterCompanyId, @CreatedBy, @CreatedBy
		FROM @InsertedItems II
		INNER JOIN #LeaseBillingCalc C ON C.LeaseStocklineId = II.LeaseStocklineId;

		UPDATE H
			SET H.IsInvoiced = 1,
				H.BillingInvoicingItemId = II.BillingInvoicingItemId,
				H.UpdatedBy = @CreatedBy,
				H.UpdatedDate = SYSUTCDATETIME()
		FROM [dbo].[LeaseStocklineUsageHistory] H
		INNER JOIN @InsertedItems II ON II.LeaseStocklineId = H.LeaseStocklineId
		WHERE H.IsInvoiced = 0 AND H.IsActive = 1 AND H.IsDeleted = 0;

		UPDATE LSL
			SET LSL.IsInvoicePost = 1,
				LSL.UpdatedBy = @CreatedBy,
				LSL.UpdatedDate = GETUTCDATE()
		FROM [dbo].[LeaseStockline] LSL
		INNER JOIN @InsertedItems II ON II.LeaseStocklineId = LSL.LeaseStocklineId
		WHERE LSL.IsInvoicePost = 0;

		DROP TABLE #LeaseBillingCalc;

		COMMIT TRANSACTION;

		SELECT BillingInvoicingId, InvoiceNo, InvoiceDate, GrandTotal FROM [dbo].[BillingInvoicing] WHERE BillingInvoicingId = @BillingInvoicingId;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		IF OBJECT_ID('tempdb..#LeaseBillingCalc') IS NOT NULL
			DROP TABLE #LeaseBillingCalc;

		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_CreateLeaseBillingInvoice]',
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
