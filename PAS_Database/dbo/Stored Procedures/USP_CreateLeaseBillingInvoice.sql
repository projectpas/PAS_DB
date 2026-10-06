

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
	6    05/10/2026     Kishor Makwana         [PN-18072 multi-part invoice] Several lease stocklines on one invoice: the selected stockline list is de-duplicated (@SelIds) before it is used.

DECLARE @Ids dbo.TVP_BigInt;
INSERT INTO @Ids (Value) VALUES (1), (2);
EXEC USP_CreateLeaseBillingInvoice @LeaseHeaderId = 1, @LeaseStocklineIds = @Ids,
    @SoldToCustomerId = 1, @SoldToSiteId = 1, @ShipToCustomerId = 1, @ShipToSiteId = 1,
    @MasterCompanyId = 1, @CreatedBy = 'test'
************************************************************************/
CREATE  PROCEDURE [dbo].[USP_CreateLeaseBillingInvoice]
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
	@CreatedBy VARCHAR(256),
	@DraftMonthsOnly BIT = 0   -- 1 = draft sync: only re-bill usage/charges of the calendar months the draft already covers (USP_SyncLeaseBillingDraftInvoices)
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

		DECLARE @SelIds TABLE (Value BIGINT PRIMARY KEY);
		INSERT INTO @SelIds (Value) SELECT DISTINCT Value FROM @LeaseStocklineIds WHERE Value IS NOT NULL;

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

		BEGIN TRANSACTION

		DECLARE @AbsorbItems TABLE (BillingInvoicingItemId BIGINT PRIMARY KEY, BillingInvoicingId BIGINT, LeaseStocklineId BIGINT);
		INSERT INTO @AbsorbItems (BillingInvoicingItemId, BillingInvoicingId, LeaseStocklineId)
		SELECT BX.BillingInvoicingItemId, BX.BillingInvoicingId, BX.SubReferenceId
		FROM [dbo].[BillingInvoicingItems] BX WITH (NOLOCK)
		INNER JOIN @SelIds SEL ON SEL.Value = BX.SubReferenceId
		INNER JOIN [dbo].[BillingInvoicing] BIX WITH (NOLOCK) ON BIX.BillingInvoicingId = BX.BillingInvoicingId
		WHERE BX.IsDeleted = 0 AND ISNULL(BX.IsVersionIncrease, 0) = 0 AND BX.ModuleId = @LeaseModuleId AND BX.ReferenceId = @LeaseHeaderId
		  AND BIX.IsDeleted = 0 AND BIX.ModuleId = @LeaseModuleId
		  AND ISNULL(BIX.IsInvoicePosted, 0) = 0 AND ISNULL(BIX.InvoiceStatus, '') <> 'Voided';

		-- Calendar months each absorbed draft already covers (taken BEFORE its usage is released below)
		CREATE TABLE #DraftMonths (LeaseStocklineId BIGINT NOT NULL, PeriodKey DATE NOT NULL);
		INSERT INTO #DraftMonths (LeaseStocklineId, PeriodKey)
		SELECT H.LeaseStocklineId, DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1)
		FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
		INNER JOIN @AbsorbItems AI ON AI.BillingInvoicingItemId = H.BillingInvoicingItemId
		WHERE H.FromDate IS NOT NULL
		UNION
		SELECT LX.LeaseStocklineId, DATEFROMPARTS(YEAR(LX.FromDate), MONTH(LX.FromDate), 1)
		FROM [dbo].[LeaseBillingInvoicingItemDetails] LX WITH (NOLOCK)
		INNER JOIN @AbsorbItems AI ON AI.BillingInvoicingItemId = LX.BillingInvoicingItemId
		WHERE ISNULL(LX.IsDeleted, 0) = 0 AND ISNULL(LX.IsVersionIncrease, 0) = 0 AND LX.FromDate IS NOT NULL;

		DECLARE @DraftInvoiceId BIGINT;
		SELECT @DraftInvoiceId = MIN(BillingInvoicingId) FROM @AbsorbItems;
		DECLARE @BillingInvoicingId BIGINT = @DraftInvoiceId;

		IF (@DraftInvoiceId IS NOT NULL)
		BEGIN
			-- Release the old usage / charges so they are billed again together with the new usage
			UPDATE H
				SET H.BillingInvoicingItemId = NULL, H.UpdatedBy = @CreatedBy, H.UpdatedDate = SYSUTCDATETIME()
			FROM [dbo].[LeaseStocklineUsageHistory] H
			INNER JOIN @AbsorbItems AI ON AI.BillingInvoicingItemId = H.BillingInvoicingItemId
			WHERE ISNULL(H.IsInvoiced, 0) = 0;

			UPDATE LC
				SET LC.BillingInvoicingItemId = NULL, LC.UpdatedBy = @CreatedBy, LC.UpdatedDate = SYSUTCDATETIME()
			FROM [dbo].[LeaseCharges] LC
			INNER JOIN @AbsorbItems AI ON AI.BillingInvoicingItemId = LC.BillingInvoicingItemId
			WHERE ISNULL(LC.IsInvoiced, 0) = 0;

			-- Retire the old detail + item rows as a superseded VERSION: IsVersionIncrease = 1 (IsActive / IsDeleted are left
			-- untouched - same convention as SO/WO invoice versions). The rows inserted below are the current version (IsVersionIncrease = 0).
			UPDATE LBID
				SET LBID.IsVersionIncrease = 1, LBID.UpdatedBy = @CreatedBy, LBID.UpdatedDate = SYSUTCDATETIME()
			FROM [dbo].[LeaseBillingInvoicingItemDetails] LBID
			INNER JOIN @AbsorbItems AI ON AI.BillingInvoicingItemId = LBID.BillingInvoicingItemId;

			UPDATE BII
				SET BII.IsVersionIncrease = 1, BII.UpdatedBy = @CreatedBy, BII.UpdatedDate = SYSUTCDATETIME()
			FROM [dbo].[BillingInvoicingItems] BII
			INNER JOIN @AbsorbItems AI ON AI.BillingInvoicingItemId = BII.BillingInvoicingItemId;

			-- Any other draft that had stocklines folded into the chosen one and is now empty is voided
			DECLARE @VoidedStatusId INT;
			SELECT TOP 1 @VoidedStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH (NOLOCK) WHERE [Status] = 'Voided';

			UPDATE BI
				SET BI.InvoiceStatus = 'Voided', BI.InvoiceStatusId = ISNULL(@VoidedStatusId, BI.InvoiceStatusId),
					BI.IsReOpened = 1, BI.UpdatedBy = @CreatedBy, BI.UpdatedDate = GETUTCDATE()
			FROM [dbo].[BillingInvoicing] BI
			WHERE BI.BillingInvoicingId IN (SELECT DISTINCT BillingInvoicingId FROM @AbsorbItems WHERE BillingInvoicingId <> @DraftInvoiceId)
			  AND NOT EXISTS (SELECT 1 FROM [dbo].[BillingInvoicingItems] X WITH (NOLOCK)
							  WHERE X.BillingInvoicingId = BI.BillingInvoicingId AND X.IsDeleted = 0 AND ISNULL(X.IsVersionIncrease, 0) = 0);
		END

		-- One-time lines (and the no-usage flat fee) that already sit on an OPEN draft invoice (generated but not
		-- yet posted, not voided) for the selected stocklines - they must not be put on a second invoice.
		SELECT DISTINCT LBX.LeaseStocklineId, LBX.LineType, LBX.FromDate
		INTO #OpenDraftLines
		FROM [dbo].[LeaseBillingInvoicingItemDetails] LBX WITH (NOLOCK)
		INNER JOIN @SelIds SEL ON SEL.Value = LBX.LeaseStocklineId
		INNER JOIN [dbo].[BillingInvoicingItems] BX WITH (NOLOCK) ON BX.BillingInvoicingItemId = LBX.BillingInvoicingItemId AND BX.IsDeleted = 0 AND ISNULL(BX.IsVersionIncrease, 0) = 0
		INNER JOIN [dbo].[BillingInvoicing] BIX WITH (NOLOCK) ON BIX.BillingInvoicingId = BX.BillingInvoicingId
			AND ISNULL(BIX.IsInvoicePosted, 0) = 0 AND ISNULL(BIX.InvoiceStatus, '') <> 'Voided'
		WHERE ISNULL(LBX.IsDeleted, 0) = 0 AND ISNULL(LBX.IsVersionIncrease, 0) = 0 AND LBX.LineType IS NOT NULL;

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
				LSL.RateUnit,
				CASE WHEN LSL.MaximumTimes IS NOT NULL AND LSL.MaximumTimes > 0 THEN LSL.MaximumTimes * 60 ELSE NULL END AS TimeLimit,
				CASE WHEN LSL.MinimumTimes IS NOT NULL THEN LSL.MinimumTimes * 60 ELSE NULL END AS TimeMinimum,
				LSL.UsagePerUnitTimes,
				LSL.OverrunPerUnitTimes,
				CASE WHEN LSL.MaximumCycles > 0 THEN LSL.MaximumCycles ELSE NULL END AS CycleLimit,
				LSL.MinimumCycles AS CycleMinimum,
				LSL.UsagePerUnitCycles,
				LSL.OverrunPerUnitCycles,
				LSL.IsInvoicePost,
				LSL.[Maintenance],
				LSL.[Insurance],
				LSL.[Taxes],
				ISNULL(SC_SUM.OtherComponentAmount, 0) AS OtherComponentAmount,
				CASE WHEN LSL.BillingMethod IN ('FlatRatePlusOverrun', 'UsageBased') THEN 1 ELSE 0 END AS IsOverageBillingMethod,
				CASE WHEN LSL.BillingMethod IN ('FlatRateOnly', 'FlatRatePlusOverrun') THEN 1 ELSE 0 END AS IsFlatRateBillingMethod
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			INNER JOIN @SelIds SEL ON SEL.Value = LSL.LeaseStocklineId
			LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
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
				DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1) AS PeriodKey,
				MIN(H.FromDate) AS PeriodFromDate,
				MAX(H.ToDate) AS PeriodToDate,
				SUM(ISNULL(H.TSNHours, 0) * 60 + ISNULL(H.TSNMinutes, 0)) AS TimeReadingAbs
			FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
			INNER JOIN @SelIds SEL ON SEL.Value = H.LeaseStocklineId
			WHERE H.UsageType = 'T' AND H.IsActive = 1 AND H.IsDeleted = 0 AND ISNULL(H.IsInvoiced, 0) = 0 AND H.BillingInvoicingItemId IS NULL
			  AND (@DraftMonthsOnly = 0 OR EXISTS (SELECT 1 FROM #DraftMonths DM WHERE DM.LeaseStocklineId = H.LeaseStocklineId AND DM.PeriodKey = DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1)))
			GROUP BY H.LeaseStocklineId, DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1)
		),
		CycleSeries AS (
			SELECT
				H.LeaseStocklineId,
				DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1) AS PeriodKey,
				MIN(H.FromDate) AS PeriodFromDate,
				MAX(H.ToDate) AS PeriodToDate,
				SUM(ISNULL(H.CSN, 0)) AS CycleReadingAbs
			FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
			INNER JOIN @SelIds SEL ON SEL.Value = H.LeaseStocklineId
			WHERE H.UsageType = 'C' AND H.IsActive = 1 AND H.IsDeleted = 0 AND ISNULL(H.IsInvoiced, 0) = 0 AND H.BillingInvoicingItemId IS NULL
			  AND (@DraftMonthsOnly = 0 OR EXISTS (SELECT 1 FROM #DraftMonths DM WHERE DM.LeaseStocklineId = H.LeaseStocklineId AND DM.PeriodKey = DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1)))
			GROUP BY H.LeaseStocklineId, DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1)
		),
		TimeFirstMonthEver AS (
			SELECT H.LeaseStocklineId, MIN(DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1)) AS FirstMonth
			FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
			INNER JOIN @SelIds SEL ON SEL.Value = H.LeaseStocklineId
			WHERE H.UsageType = 'T' AND H.IsActive = 1 AND H.IsDeleted = 0
			GROUP BY H.LeaseStocklineId
		),
		CycleFirstMonthEver AS (
			SELECT H.LeaseStocklineId, MIN(DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1)) AS FirstMonth
			FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
			INNER JOIN @SelIds SEL ON SEL.Value = H.LeaseStocklineId
			WHERE H.UsageType = 'C' AND H.IsActive = 1 AND H.IsDeleted = 0
			GROUP BY H.LeaseStocklineId
		),
		Periods AS (
			SELECT
				COALESCE(T.LeaseStocklineId, C.LeaseStocklineId) AS LeaseStocklineId,
				COALESCE(T.PeriodKey, C.PeriodKey) AS PeriodKey,
				(SELECT MIN(D) FROM (VALUES (T.PeriodFromDate), (C.PeriodFromDate)) AS Dates(D)) AS PeriodFromDate,
				(SELECT MAX(D) FROM (VALUES (T.PeriodToDate), (C.PeriodToDate)) AS Dates(D)) AS PeriodToDate,
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
				S.Qty,
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
				S.RateUnit
			FROM Periods P
			INNER JOIN StocklineBase S ON S.LeaseStocklineId = P.LeaseStocklineId
			WHERE P.TimePending = 1 OR P.CyclePending = 1
		),
		PeriodAmounts AS (
			SELECT
				LeaseStocklineId, PeriodKey, PeriodFromDate, PeriodToDate,
				TimePending, TimeReadingAbs, PriorTimeReadingAbs,
				CyclePending, CycleReadingAbs, PriorCycleReadingAbs,
				Qty, TimeLimit, TimeMinimum, UsagePerUnitTimes, OverrunPerUnitTimes,
				CycleLimit, CycleMinimum, UsagePerUnitCycles, OverrunPerUnitCycles,
				IsOverageBillingMethod, IsFlatRateBillingMethod, RateUnit,
				ISNULL(PriorTimeReadingAbs, 0) AS TimePriorAbs,
				CASE WHEN TimePending = 1 AND TimeIsFirstEverMonth = 1 THEN 1 ELSE 0 END AS TimeIsFirstEver,
				ISNULL(PriorCycleReadingAbs, 0) AS CyclePriorAbs,
				CASE WHEN CyclePending = 1 AND CycleIsFirstEverMonth = 1 THEN 1 ELSE 0 END AS CycleIsFirstEver
			FROM PendingPeriodsJoined
		),
		PeriodAmounts2 AS (
			SELECT
				LeaseStocklineId, PeriodKey, PeriodFromDate, PeriodToDate,
				TimePending, TimeReadingAbs, PriorTimeReadingAbs,
				CyclePending, CycleReadingAbs, PriorCycleReadingAbs,
				Qty, TimeLimit, TimeMinimum, UsagePerUnitTimes, OverrunPerUnitTimes,
				CycleLimit, CycleMinimum, UsagePerUnitCycles, OverrunPerUnitCycles,
				IsOverageBillingMethod, IsFlatRateBillingMethod, RateUnit, TimePriorAbs, TimeIsFirstEver, CyclePriorAbs, CycleIsFirstEver,
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
				LeaseStocklineId, PeriodKey, PeriodFromDate, PeriodToDate,
				TimePending, TimeReadingAbs, PriorTimeReadingAbs,
				CyclePending, CycleReadingAbs, PriorCycleReadingAbs,
				Qty, TimeLimit, TimeMinimum, UsagePerUnitTimes, OverrunPerUnitTimes,
				CycleLimit, CycleMinimum, UsagePerUnitCycles, OverrunPerUnitCycles,
				IsOverageBillingMethod, IsFlatRateBillingMethod, RateUnit, TimePriorAbs, TimeIsFirstEver, CyclePriorAbs, CycleIsFirstEver,
				TimeEffectiveCurrAbs, CycleEffectiveCurrAbs, TimeOverMinutes, CycleOverCount,
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
		)
		SELECT * INTO #PeriodAmounts3 FROM PeriodAmounts3;

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
				LSL.RateUnit,
				CASE WHEN LSL.MaximumTimes IS NOT NULL AND LSL.MaximumTimes > 0 THEN LSL.MaximumTimes * 60 ELSE NULL END AS TimeLimit,
				CASE WHEN LSL.MinimumTimes IS NOT NULL THEN LSL.MinimumTimes * 60 ELSE NULL END AS TimeMinimum,
				LSL.UsagePerUnitTimes,
				LSL.OverrunPerUnitTimes,
				CASE WHEN LSL.MaximumCycles > 0 THEN LSL.MaximumCycles ELSE NULL END AS CycleLimit,
				LSL.MinimumCycles AS CycleMinimum,
				LSL.UsagePerUnitCycles,
				LSL.OverrunPerUnitCycles,
				LSL.IsInvoicePost,
				LSL.[Maintenance],
				LSL.[Insurance],
				LSL.[Taxes],
				ISNULL(SC_SUM.OtherComponentAmount, 0) AS OtherComponentAmount,
				CASE WHEN LSL.BillingMethod IN ('FlatRatePlusOverrun', 'UsageBased') THEN 1 ELSE 0 END AS IsOverageBillingMethod,
				CASE WHEN LSL.BillingMethod IN ('FlatRateOnly', 'FlatRatePlusOverrun') THEN 1 ELSE 0 END AS IsFlatRateBillingMethod
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			INNER JOIN @SelIds SEL ON SEL.Value = LSL.LeaseStocklineId
			LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
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
		ChargesToBill AS (
			SELECT PA.LeaseStocklineId, PA.PeriodKey, PA.PeriodFromDate, PA.PeriodToDate, LC.LeaseChargesId, LC.ExtendedCost
			FROM #PeriodAmounts3 PA
			INNER JOIN [dbo].[LeaseCharges] LC WITH (NOLOCK)
				ON LC.LeaseStocklineId = PA.LeaseStocklineId
				AND LC.IsDeleted = 0 AND ISNULL(LC.IsInvoiced, 0) = 0 AND LC.BillingInvoicingItemId IS NULL
				AND CAST(LC.ReportedDate AS DATE) BETWEEN CAST(PA.PeriodFromDate AS DATE) AND CAST(PA.PeriodToDate AS DATE)

			UNION ALL

			SELECT S.LeaseStocklineId, NULL, NULL, NULL, LC.LeaseChargesId, LC.ExtendedCost
			FROM StocklineBase S
			INNER JOIN [dbo].[LeaseCharges] LC WITH (NOLOCK)
				ON LC.LeaseStocklineId = S.LeaseStocklineId AND LC.IsDeleted = 0 AND ISNULL(LC.IsInvoiced, 0) = 0 AND LC.BillingInvoicingItemId IS NULL
			WHERE (@DraftMonthsOnly = 0 OR EXISTS (SELECT 1 FROM #DraftMonths DM WHERE DM.LeaseStocklineId = LC.LeaseStocklineId AND DM.PeriodKey = DATEFROMPARTS(YEAR(LC.ReportedDate), MONTH(LC.ReportedDate), 1)))
			AND NOT EXISTS (
				SELECT 1 FROM #PeriodAmounts3 PA2
				WHERE PA2.LeaseStocklineId = S.LeaseStocklineId
				  AND CAST(LC.ReportedDate AS DATE) BETWEEN CAST(PA2.PeriodFromDate AS DATE) AND CAST(PA2.PeriodToDate AS DATE)
			)
		)
		SELECT * INTO #ChargesToBill FROM ChargesToBill;

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
				LSL.RateUnit,
				CASE WHEN LSL.MaximumTimes IS NOT NULL AND LSL.MaximumTimes > 0 THEN LSL.MaximumTimes * 60 ELSE NULL END AS TimeLimit,
				CASE WHEN LSL.MinimumTimes IS NOT NULL THEN LSL.MinimumTimes * 60 ELSE NULL END AS TimeMinimum,
				LSL.UsagePerUnitTimes,
				LSL.OverrunPerUnitTimes,
				CASE WHEN LSL.MaximumCycles > 0 THEN LSL.MaximumCycles ELSE NULL END AS CycleLimit,
				LSL.MinimumCycles AS CycleMinimum,
				LSL.UsagePerUnitCycles,
				LSL.OverrunPerUnitCycles,
				LSL.IsInvoicePost,
				LSL.[Maintenance],
				LSL.[Insurance],
				LSL.[Taxes],
				ISNULL(SC_SUM.OtherComponentAmount, 0) AS OtherComponentAmount,
				CASE WHEN LSL.BillingMethod IN ('FlatRatePlusOverrun', 'UsageBased') THEN 1 ELSE 0 END AS IsOverageBillingMethod,
				CASE WHEN LSL.BillingMethod IN ('FlatRateOnly', 'FlatRatePlusOverrun') THEN 1 ELSE 0 END AS IsFlatRateBillingMethod
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			INNER JOIN @SelIds SEL ON SEL.Value = LSL.LeaseStocklineId
			LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
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
		ChargesByPeriodTotals AS (
			SELECT LeaseStocklineId, PeriodKey, PeriodFromDate, PeriodToDate, SUM(ISNULL(ExtendedCost, 0)) AS ChargesAmount
			FROM #ChargesToBill
			WHERE PeriodKey IS NOT NULL
			GROUP BY LeaseStocklineId, PeriodKey, PeriodFromDate, PeriodToDate
			HAVING SUM(ISNULL(ExtendedCost, 0)) <> 0
		),
		ChargesNoPeriodTotals AS (
			SELECT LeaseStocklineId, SUM(ISNULL(ExtendedCost, 0)) AS ChargesAmount
			FROM #ChargesToBill
			WHERE PeriodKey IS NULL
			GROUP BY LeaseStocklineId
			HAVING SUM(ISNULL(ExtendedCost, 0)) <> 0
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
		InvoiceLines AS (
			SELECT
				S.LeaseStocklineId, S.BillingMethod, S.BillingFrequency,
				LineType = 'Flat Rate',
				FromDate = PA.PeriodFromDate, ToDate = PA.PeriodToDate,
				FlatRate = CASE WHEN S.IsFlatRateBillingMethod = 1 THEN S.FlatRate ELSE NULL END,
				FlatRateAmount = X.MonthFlat,
				TimeRecorded = CASE WHEN PA.TimePending = 1 THEN (CASE WHEN PA.TimeReadingAbs < 0 THEN 0 ELSE PA.TimeReadingAbs END) / 60.0 ELSE NULL END,
				TimeLimit = CASE WHEN PA.TimePending = 1 AND S.IsOverageBillingMethod = 1 AND PA.TimeLimit IS NOT NULL THEN PA.TimeLimit / 60.0 ELSE NULL END,
				TimeOver = CAST(NULL AS DECIMAL(18,6)), TimeOverageRate = CAST(NULL AS DECIMAL(18,6)),
				TimeBillingAmount = CASE WHEN PA.TimeUsageQty IS NOT NULL AND X.TimeRate IS NOT NULL THEN (PA.TimeUsageQty / 60.0) * X.TimeRate * S.Qty ELSE NULL END,
				CycleRecorded = CASE WHEN PA.CyclePending = 1 THEN (CASE WHEN PA.CycleReadingAbs < 0 THEN 0 ELSE PA.CycleReadingAbs END) ELSE NULL END,
				CycleLimit = CASE WHEN PA.CyclePending = 1 AND S.IsOverageBillingMethod = 1 THEN PA.CycleLimit ELSE NULL END,
				CycleOver = CAST(NULL AS DECIMAL(18,6)), CycleOverageRate = CAST(NULL AS DECIMAL(18,6)),
				CycleBillingAmount = CASE WHEN PA.CycleUsageQty IS NOT NULL AND X.CycleRate IS NOT NULL THEN PA.CycleUsageQty * X.CycleRate * S.Qty ELSE NULL END,
				TimeUsageQty = CASE WHEN PA.TimeUsageQty IS NOT NULL AND X.TimeRate IS NOT NULL THEN PA.TimeUsageQty / 60.0 ELSE NULL END,
				TimeUsageRate = CASE WHEN PA.TimeUsageQty IS NOT NULL AND X.TimeRate IS NOT NULL THEN X.TimeRate ELSE NULL END,
				TimeUsageAmount = CASE WHEN PA.TimeUsageQty IS NOT NULL AND X.TimeRate IS NOT NULL THEN (PA.TimeUsageQty / 60.0) * X.TimeRate * S.Qty ELSE NULL END,
				CycleUsageQty = CASE WHEN PA.CycleUsageQty IS NOT NULL AND X.CycleRate IS NOT NULL THEN PA.CycleUsageQty ELSE NULL END,
				CycleUsageRate = CASE WHEN PA.CycleUsageQty IS NOT NULL AND X.CycleRate IS NOT NULL THEN X.CycleRate ELSE NULL END,
				CycleUsageAmount = CASE WHEN PA.CycleUsageQty IS NOT NULL AND X.CycleRate IS NOT NULL THEN PA.CycleUsageQty * X.CycleRate * S.Qty ELSE NULL END,
				LineAmount =
					  ISNULL(X.MonthFlat, 0)
					+ ISNULL(CASE WHEN PA.TimeUsageQty IS NOT NULL AND X.TimeRate IS NOT NULL THEN (PA.TimeUsageQty / 60.0) * X.TimeRate * S.Qty ELSE NULL END, 0)
					+ ISNULL(CASE WHEN PA.CycleUsageQty IS NOT NULL AND X.CycleRate IS NOT NULL THEN PA.CycleUsageQty * X.CycleRate * S.Qty ELSE NULL END, 0)
			FROM StocklineBase S
			INNER JOIN #PeriodAmounts3 PA ON PA.LeaseStocklineId = S.LeaseStocklineId
			CROSS APPLY (SELECT
					MonthFlat = CASE WHEN S.IsFlatRateBillingMethod = 1 AND UPPER(LTRIM(RTRIM(ISNULL(S.RateUnit, '')))) = 'MONTH'
								AND NOT EXISTS (SELECT 1 FROM PostedFlatMonths PM WHERE PM.LeaseStocklineId = S.LeaseStocklineId AND PM.MonthKey = PA.PeriodKey)
							THEN ISNULL(S.FlatRate, 0) * S.Qty ELSE NULL END,
					TimeRate = CASE WHEN S.IsFlatRateBillingMethod = 1 AND UPPER(LTRIM(RTRIM(ISNULL(S.RateUnit, '')))) NOT IN ('CYCLE', 'MONTH') THEN ISNULL(S.FlatRate, 0)
								WHEN S.IsOverageBillingMethod = 1 AND S.IsFlatRateBillingMethod = 0 THEN ISNULL(S.UsagePerUnitTimes, 0) ELSE NULL END,
					CycleRate = CASE WHEN S.IsFlatRateBillingMethod = 1 AND UPPER(LTRIM(RTRIM(ISNULL(S.RateUnit, '')))) = 'CYCLE' THEN ISNULL(S.FlatRate, 0)
								WHEN S.IsOverageBillingMethod = 1 AND S.IsFlatRateBillingMethod = 0 THEN ISNULL(S.UsagePerUnitCycles, 0) ELSE NULL END
				) X

			UNION ALL

			SELECT
				S.LeaseStocklineId, S.BillingMethod, S.BillingFrequency,
				LineType = 'Flat Rate',
				FromDate = NULL, ToDate = NULL,
				FlatRate = S.FlatRate, FlatRateAmount = ISNULL(S.FlatRate, 0) * S.Qty,
				NULL, NULL, NULL,
				NULL, NULL,
				NULL, NULL, NULL,
				NULL, NULL, NULL,
				NULL, NULL,
				NULL, NULL, NULL,
				LineAmount = ISNULL(S.FlatRate, 0) * S.Qty
			FROM StocklineBase S
			WHERE S.IsFlatRateBillingMethod = 1
			  AND UPPER(LTRIM(RTRIM(ISNULL(S.RateUnit, '')))) IN ('MONTH', '')
			  AND S.IsInvoicePost = 0
			  AND NOT EXISTS (SELECT 1 FROM #PeriodAmounts3 PA2 WHERE PA2.LeaseStocklineId = S.LeaseStocklineId)
			  AND NOT EXISTS (SELECT 1 FROM #OpenDraftLines OD WHERE OD.LeaseStocklineId = S.LeaseStocklineId AND OD.LineType = 'Flat Rate')

			UNION ALL

			SELECT
				S.LeaseStocklineId, S.BillingMethod, S.BillingFrequency,
				LineType = 'Overrun',
				FromDate = PA.PeriodFromDate, ToDate = PA.PeriodToDate,
				NULL, NULL,
				TimeRecorded = CAST(NULL AS DECIMAL(18,6)), TimeLimit = CAST(NULL AS DECIMAL(18,6)),
				TimeOver = CASE WHEN PA.TimeOverMinutes IS NOT NULL THEN PA.TimeOverMinutes / 60.0 ELSE NULL END,
				TimeOverageRate = CASE WHEN PA.TimeOverMinutes IS NOT NULL THEN S.OverrunPerUnitTimes ELSE NULL END,
				TimeBillingAmount = CASE WHEN PA.TimeOverMinutes IS NOT NULL THEN (PA.TimeOverMinutes / 60.0) * ISNULL(S.OverrunPerUnitTimes, 0) * S.Qty ELSE NULL END,
				CycleRecorded = CAST(NULL AS DECIMAL(18,6)), CycleLimit = CAST(NULL AS DECIMAL(18,6)),
				CycleOver = PA.CycleOverCount,
				CycleOverageRate = CASE WHEN PA.CycleOverCount IS NOT NULL THEN S.OverrunPerUnitCycles ELSE NULL END,
				CycleBillingAmount = CASE WHEN PA.CycleOverCount IS NOT NULL THEN PA.CycleOverCount * ISNULL(S.OverrunPerUnitCycles, 0) * S.Qty ELSE NULL END,
				TimeUsageQty = CAST(NULL AS DECIMAL(18,6)), TimeUsageRate = CAST(NULL AS DECIMAL(18,6)), TimeUsageAmount = CAST(NULL AS DECIMAL(18,6)),
				CycleUsageQty = CAST(NULL AS DECIMAL(18,6)), CycleUsageRate = CAST(NULL AS DECIMAL(18,6)), CycleUsageAmount = CAST(NULL AS DECIMAL(18,6)),
				LineAmount =
					  ISNULL(CASE WHEN PA.TimeOverMinutes IS NOT NULL THEN (PA.TimeOverMinutes / 60.0) * ISNULL(S.OverrunPerUnitTimes, 0) * S.Qty ELSE NULL END, 0)
					+ ISNULL(CASE WHEN PA.CycleOverCount IS NOT NULL THEN PA.CycleOverCount * ISNULL(S.OverrunPerUnitCycles, 0) * S.Qty ELSE NULL END, 0)
			FROM #PeriodAmounts3 PA
			INNER JOIN StocklineBase S ON S.LeaseStocklineId = PA.LeaseStocklineId
			WHERE S.IsOverageBillingMethod = 1
			  AND (ISNULL(PA.TimeOverMinutes, 0) > 0 OR ISNULL(PA.CycleOverCount, 0) > 0)

			UNION ALL

			SELECT
				S.LeaseStocklineId, S.BillingMethod, S.BillingFrequency,
				LineType = 'Charges',
				FromDate = CP.PeriodFromDate, ToDate = CP.PeriodToDate,
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
				LineAmount = CP.ChargesAmount
			FROM ChargesByPeriodTotals CP
			INNER JOIN StocklineBase S ON S.LeaseStocklineId = CP.LeaseStocklineId

			UNION ALL

			SELECT
				S.LeaseStocklineId, S.BillingMethod, S.BillingFrequency,
				LineType = 'Charges',
				FromDate = NULL, ToDate = NULL,
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
				LineAmount = CN.ChargesAmount
			FROM ChargesNoPeriodTotals CN
			INNER JOIN StocklineBase S ON S.LeaseStocklineId = CN.LeaseStocklineId

			UNION ALL

			SELECT
				S.LeaseStocklineId, S.BillingMethod, S.BillingFrequency,
				LineType = 'Maintenance',
				FromDate = NULL, ToDate = NULL,
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
				LineAmount = S.[Maintenance]
			FROM StocklineBase S
			WHERE S.IsInvoicePost = 0 AND ISNULL(S.[Maintenance], 0) <> 0
			  AND NOT EXISTS (SELECT 1 FROM #OpenDraftLines OD WHERE OD.LeaseStocklineId = S.LeaseStocklineId AND OD.LineType = 'Maintenance')

			UNION ALL

			SELECT
				S.LeaseStocklineId, S.BillingMethod, S.BillingFrequency,
				LineType = 'Insurance',
				FromDate = NULL, ToDate = NULL,
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
				LineAmount = S.[Insurance]
			FROM StocklineBase S
			WHERE S.IsInvoicePost = 0 AND ISNULL(S.[Insurance], 0) <> 0
			  AND NOT EXISTS (SELECT 1 FROM #OpenDraftLines OD WHERE OD.LeaseStocklineId = S.LeaseStocklineId AND OD.LineType = 'Insurance')

			UNION ALL

			SELECT
				S.LeaseStocklineId, S.BillingMethod, S.BillingFrequency,
				LineType = 'Taxes',
				FromDate = NULL, ToDate = NULL,
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
				LineAmount = S.[Taxes]
			FROM StocklineBase S
			WHERE S.IsInvoicePost = 0 AND ISNULL(S.[Taxes], 0) <> 0
			  AND NOT EXISTS (SELECT 1 FROM #OpenDraftLines OD WHERE OD.LeaseStocklineId = S.LeaseStocklineId AND OD.LineType = 'Taxes')

			UNION ALL

			SELECT
				S.LeaseStocklineId, S.BillingMethod, S.BillingFrequency,
				LineType = 'Others',
				FromDate = NULL, ToDate = NULL,
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
				LineAmount = S.OtherComponentAmount
			FROM StocklineBase S
			WHERE S.IsInvoicePost = 0 AND ISNULL(S.OtherComponentAmount, 0) <> 0
			  AND NOT EXISTS (SELECT 1 FROM #OpenDraftLines OD WHERE OD.LeaseStocklineId = S.LeaseStocklineId AND OD.LineType = 'Others')
		)
		SELECT * INTO #InvoiceLines FROM InvoiceLines;

		SELECT LeaseStocklineId, SUM(LineAmount) AS TotalBillingAmount
		INTO #StocklineItemTotals
		FROM #InvoiceLines
		GROUP BY LeaseStocklineId;

		IF NOT EXISTS (SELECT 1 FROM #StocklineItemTotals)
		BEGIN
			RAISERROR('None of the selected lease stocklines are eligible for billing (inactive, not reserved, or nothing left to bill).', 16, 1);
			RETURN (1);
		END

		DECLARE @GrandTotal DECIMAL(18, 6);
		SELECT @GrandTotal = SUM(ISNULL(TotalBillingAmount, 0)) FROM #StocklineItemTotals;

		DECLARE @DraftStatus VARCHAR(50) = 'Reviewed', @DraftStatusId INT;
		SELECT TOP 1 @DraftStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH (NOLOCK) WHERE [Status] = @DraftStatus;

		IF (@DraftInvoiceId IS NULL)
		BEGIN
		INSERT INTO [dbo].[BillingInvoicing]
			(ModuleId, ReferenceId, CustomerId, InvoiceTypeId, InvoiceNo, InvoiceDate, InvoiceTime, PrintDate,
			 EmployeeId, CurrencyId, ManagementStructureId, Notes, SubTotal, GrandTotal, MasterCompanyId, CreatedBy, UpdatedBy,
			 InvoiceStatusId, InvoiceStatus, IsInvoicePosted)
		VALUES
			(@LeaseModuleId, @LeaseHeaderId, @CustomerId, @InvoiceTypeId, 'PENDING', @InvoiceDate, @InvoiceTime, @PrintDate,
			 @EmployeeId, @CurrencyId, @ManagementStructureId, @Notes, @GrandTotal, @GrandTotal, @MasterCompanyId, @CreatedBy, @CreatedBy,
			 @DraftStatusId, @DraftStatus, 0);

		SET @BillingInvoicingId = SCOPE_IDENTITY();

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
		END
		ELSE
		BEGIN
			-- Re-generating an existing draft: keep BillingInvoicingId / InvoiceNo, refresh the header + Bill To/Ship To
			UPDATE [dbo].[BillingInvoicing]
				SET InvoiceDate = @InvoiceDate, InvoiceTime = @InvoiceTime, PrintDate = @PrintDate, EmployeeId = @EmployeeId,
					CurrencyId = @CurrencyId, Notes = @Notes, UpdatedBy = @CreatedBy, UpdatedDate = GETUTCDATE()
			WHERE BillingInvoicingId = @BillingInvoicingId;

			UPDATE [dbo].[BillingInvoicingDetails]
				SET SoldToCustomerId = @SoldToCustomerId, SoldToSiteId = @SoldToSiteId, SoldToAttention = @SoldToAttention,
					ShipToCustomerId = @ShipToCustomerId, ShipToSiteId = @ShipToSiteId, ShipToAttention = @ShipToAttention,
					ShipviaId = @ShipViaId, ShipAccountInfo = @ShipAccountInfo, ShippingTermsName = @ShippingTermsName
			WHERE BillingInvoicingId = @BillingInvoicingId;
		END

		DECLARE @InsertedItems TABLE (BillingInvoicingItemId BIGINT, LeaseStocklineId BIGINT);

		INSERT INTO [dbo].[BillingInvoicingItems]
			(BillingInvoicingId, ModuleId, ReferenceId, SubModuleId, SubReferenceId, ItemMasterId, StocklineId, ConditionId,
			 SerialNumber, SubTotal, GrandTotal, ShipDate, MasterCompanyId, CreatedBy, UpdatedBy)
		OUTPUT inserted.BillingInvoicingItemId, inserted.SubReferenceId INTO @InsertedItems (BillingInvoicingItemId, LeaseStocklineId)
		SELECT
			@BillingInvoicingId, @LeaseModuleId, @LeaseHeaderId, @LeaseModuleId, SIT.LeaseStocklineId, S.ItemMasterId, S.StockLineId, S.ConditionId,
			SLIVE.SerialNumber, SIT.TotalBillingAmount, SIT.TotalBillingAmount, @ShipDate, @MasterCompanyId, @CreatedBy, @CreatedBy
		FROM #StocklineItemTotals SIT
		INNER JOIN [dbo].[LeaseStockline] S WITH (NOLOCK) ON S.LeaseStocklineId = SIT.LeaseStocklineId
		LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = S.StockLineId;

		INSERT INTO [dbo].[LeaseBillingInvoicingItemDetails]
			(BillingInvoicingItemId, LeaseStocklineId, BillingMethod, BillingFrequency,
			 LineType, FromDate, ToDate, LineAmount,
			 FlatRate, FlatRateAmount,
			 TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount,
			 CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, TotalBillingAmount,
			 TimeUsageQty, TimeUsageRate, TimeUsageAmount, CycleUsageQty, CycleUsageRate, CycleUsageAmount,
			 MasterCompanyId, CreatedBy, UpdatedBy)
		SELECT
			II.BillingInvoicingItemId, IL.LeaseStocklineId, IL.BillingMethod, IL.BillingFrequency,
			IL.LineType, IL.FromDate, IL.ToDate, IL.LineAmount,
			IL.FlatRate, IL.FlatRateAmount,
			IL.TimeRecorded, IL.TimeLimit, IL.TimeOver, IL.TimeOverageRate, IL.TimeBillingAmount,
			IL.CycleRecorded, IL.CycleLimit, IL.CycleOver, IL.CycleOverageRate, IL.CycleBillingAmount, IL.LineAmount,
			IL.TimeUsageQty, IL.TimeUsageRate, IL.TimeUsageAmount, IL.CycleUsageQty, IL.CycleUsageRate, IL.CycleUsageAmount,
			@MasterCompanyId, @CreatedBy, @CreatedBy
		FROM @InsertedItems II
		INNER JOIN #InvoiceLines IL ON IL.LeaseStocklineId = II.LeaseStocklineId;

		-- Header total = every active line on the invoice (covers a re-generated draft that still holds other stocklines)
		UPDATE BI
			SET BI.GrandTotal = T.Total, BI.SubTotal = T.Total
		FROM [dbo].[BillingInvoicing] BI
		CROSS APPLY (SELECT SUM(ISNULL(X.GrandTotal, 0)) AS Total FROM [dbo].[BillingInvoicingItems] X WITH (NOLOCK)
					 WHERE X.BillingInvoicingId = BI.BillingInvoicingId AND X.IsDeleted = 0 AND ISNULL(X.IsVersionIncrease, 0) = 0) T
		WHERE BI.BillingInvoicingId = @BillingInvoicingId;

		UPDATE H
			SET H.BillingInvoicingItemId = II.BillingInvoicingItemId,
				H.UpdatedBy = @CreatedBy,
				H.UpdatedDate = SYSUTCDATETIME()
		FROM [dbo].[LeaseStocklineUsageHistory] H
		INNER JOIN @InsertedItems II ON II.LeaseStocklineId = H.LeaseStocklineId
		WHERE H.IsInvoiced = 0 AND H.BillingInvoicingItemId IS NULL AND H.IsActive = 1 AND H.IsDeleted = 0;

		UPDATE LC
			SET LC.BillingInvoicingItemId = II.BillingInvoicingItemId,
				LC.UpdatedBy = @CreatedBy,
				LC.UpdatedDate = SYSUTCDATETIME()
		FROM [dbo].[LeaseCharges] LC
		INNER JOIN #ChargesToBill CTB ON CTB.LeaseChargesId = LC.LeaseChargesId
		INNER JOIN @InsertedItems II ON II.LeaseStocklineId = CTB.LeaseStocklineId;

		DROP TABLE #PeriodAmounts3;
		DROP TABLE #ChargesToBill;
		DROP TABLE #InvoiceLines;
		DROP TABLE #StocklineItemTotals;
		DROP TABLE #OpenDraftLines;
		DROP TABLE #DraftMonths;

		COMMIT TRANSACTION;

		SELECT BillingInvoicingId, InvoiceNo, InvoiceDate, GrandTotal FROM [dbo].[BillingInvoicing] WHERE BillingInvoicingId = @BillingInvoicingId;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		IF OBJECT_ID('tempdb..#PeriodAmounts3') IS NOT NULL
			DROP TABLE #PeriodAmounts3;
		IF OBJECT_ID('tempdb..#ChargesToBill') IS NOT NULL
			DROP TABLE #ChargesToBill;
		IF OBJECT_ID('tempdb..#InvoiceLines') IS NOT NULL
			DROP TABLE #InvoiceLines;
		IF OBJECT_ID('tempdb..#StocklineItemTotals') IS NOT NULL
			DROP TABLE #StocklineItemTotals;
		IF OBJECT_ID('tempdb..#OpenDraftLines') IS NOT NULL
			DROP TABLE #OpenDraftLines;
		IF OBJECT_ID('tempdb..#DraftMonths') IS NOT NULL
			DROP TABLE #DraftMonths;

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
