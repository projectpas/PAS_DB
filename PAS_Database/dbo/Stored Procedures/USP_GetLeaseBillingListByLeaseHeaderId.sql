

/*************************************************************
 ** File:   [USP_GetLeaseBillingListByLeaseHeaderId]
 ** Description: Returns the Billing/Invoicing grid rows for a LeaseHeader (PN-17949).
 **              Same reserved-only LeaseStockline population as the Usage Info tab
 **              (USP_GetUsageInfoLeaseStockPartsListByLeaseHeaderId) - only stocklines
 **              with QtyReserved > 0 are eligible for usage/billing tracking.
 **
 **              Time/Cycle "Recorded" values come from the LeaseStocklineUsage
 **              snapshot (same source as the Usage Info tab's "Last Reported"). Time
 **              figures are expressed in TOTAL MINUTES throughout (same convention as
 **              USP_GetLeaseStocklineUsageHistoryByLeaseStocklineId's cumulative
 **              columns) so the API/UI can format with formatTotalMinutesAsHHMM;
 **              Cycle figures are plain counts.
 **
 **              Overage math (Time/Cycle Over, Overage Rate, Billing Amount) is
 **              driven by the LeaseStockline properties already captured today via
 **              the Add Item tab's "Properties" popup (MaximumTimes/MaximumCycles/
 **              OverrunPerUnitTimes/OverrunPerUnitCycles) - NOT a separate Item
 **              Master (the ticket's wording notwithstanding; confirmed with the
 **              requester). These columns are populated for BillingMethod IN
 **              ('FlatRatePlusOverrun','UsageBased') whenever usage HAS been
 **              recorded (TimeRecorded/CycleRecorded present), regardless of sign -
 **              per the requirements Excel, usage below the Limit is a NEGATIVE
 **              Over/Billing Amount (a credit) that nets against the other
 **              dimension's amount in TotalBillingAmount, not a value to hide as
 **              "NA". Over/Amount are NULL (UI renders "NA") only when there is no
 **              usage recorded yet, or the billing method isn't overage-eligible.
 **
 **              Billing/Invoiced/InvoiceNumber/InvoiceDate are returned as NULL for
 **              now - there is no invoice table yet. Invoice generation/printing/
 **              posting is deliberately out of scope for this pass (the Excel mockup
 **              itself flags that part of the design as unfinished) and will be
 **              wired up in a follow-up ticket once that design is finalized.
 **
 **              "Usage Based" billing amounts are NOT specified anywhere in the
 **              ticket or mockup (both leave that row blank) - left NULL/NA here
 **              rather than inventing a formula. Flag this gap for the requester.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    17/09/2026     Kishor Makwana          [PN-17949] Created
	2    21/09/2026     Kishor Makwana          [PN-17949] UsageBased now bills the same way as FlatRatePlusOverrun (usage over the Limit x the Overage Rate) instead of always showing NA
	3    22/09/2026     Kishor Makwana          [PN-17949] Fixed Time/Cycle Over, Billing Amount and Total Billing Amount to match the requirements Excel - usage below the Limit now nets a negative (credit) amount instead of being suppressed to NA/0
	4    24/09/2026     Kishor Makwana          [PN-17949 follow-up] Optimized: (a) BillingInvoicingItems join had no IsDeleted filter and no
	                                            guarantee of a single row per stockline - a stockline with more than one non-deleted
	                                            BillingInvoicingItems row (re-invoiced/revised) would silently duplicate that whole result
	                                            row, double-counting its Charges/TotalBillingAmount in the grid's footer totals. Replaced
	                                            with an OUTER APPLY that deterministically picks just the most recent one (TOP 1 ORDER BY
	                                            BillingInvoicingItemId DESC) and filters IsDeleted = 0. (b) Charges moved from a bare scalar
	                                            subquery in the SELECT list to an OUTER APPLY alongside it, same execution shape but clearer
	                                            and pairs with the new supporting index (see PN-17949_Billing_List_Indexes.sql) that turns
	                                            both per-stockline lookups into index seeks instead of table scans. (c) Removed the redundant
	                                            "AND BII.ModuleId = 72" repeated on the BillingInvoicing join (already filtered on the
	                                            BillingInvoicingItems join it depends on).

exec USP_GetLeaseBillingListByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetLeaseBillingListByLeaseHeaderId]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		;WITH Base AS (
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
				CASE WHEN U.LeaseStocklineUsageId IS NOT NULL
					 THEN ISNULL(U.CurrentTSNHours, 0) * 60 + ISNULL(U.CurrentTSNMinutes, 0)
					 ELSE NULL END AS TimeRecorded,
				CASE WHEN LSL.MaximumTimes IS NOT NULL THEN LSL.MaximumTimes * 60 ELSE NULL END AS TimeLimit,
				LSL.OverrunPerUnitTimes AS TimeOverageRateRaw,
				U.CurrentCSN AS CycleRecorded,
				LSL.MaximumCycles AS CycleLimit,
				LSL.OverrunPerUnitCycles AS CycleOverageRateRaw,
				CASE WHEN U.LeaseStocklineUsageId IS NOT NULL THEN 1 ELSE 0 END AS HasUsageInfo,
				LSL.IsActive,
				LSL.LeaseStatusId,
				BI.BillingInvoicingId,
				BI.InvoiceNo,
				BI.InvoiceDate,
				BI.InvoiceStatus,
				ISNULL(ChargesAgg.Charges, 0) AS Charges
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
			LEFT JOIN [dbo].[LeaseStocklineUsage] U WITH (NOLOCK) ON U.LeaseStocklineId = LSL.LeaseStocklineId AND U.IsDeleted = 0
			OUTER APPLY (
				SELECT TOP (1) BII.BillingInvoicingId
				FROM [dbo].[BillingInvoicingItems] BII WITH (NOLOCK)
				WHERE BII.SubReferenceId = LSL.LeaseStocklineId AND BII.ModuleId = 72 AND BII.IsDeleted = 0
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
		WithOver AS (
			SELECT *,
				IsOverageBillingMethod = CASE WHEN BillingMethod IN ('FlatRatePlusOverrun', 'UsageBased') THEN 1 ELSE 0 END,
				IsFlatRateBillingMethod = CASE WHEN BillingMethod IN ('FlatRateOnly', 'FlatRatePlusOverrun') THEN 1 ELSE 0 END,
				TimeOverRaw = CASE WHEN TimeRecorded IS NOT NULL THEN
						CASE WHEN (TimeRecorded - ISNULL(TimeLimit, 0)) < 0 THEN 0 ELSE (TimeRecorded - ISNULL(TimeLimit, 0)) END
					ELSE NULL END,
				CycleOverRaw = CASE WHEN CycleRecorded IS NOT NULL THEN
						CASE WHEN (CycleRecorded - ISNULL(CycleLimit, 0)) < 0 THEN 0 ELSE (CycleRecorded - ISNULL(CycleLimit, 0)) END
					ELSE NULL END
			FROM Base
		)
		SELECT
			LeaseStocklineId,
			PartNumber,
			PartDescription,
			SerialNumber,
			Qty,
			BillingMethod,
			BillingFrequency,
			FlatRateAmount = CASE WHEN IsFlatRateBillingMethod = 1 THEN ISNULL(FlatRate, 0) * Qty ELSE NULL END,
			TimeRecorded,
			TimeLimit,
			TimeOver = CASE WHEN IsOverageBillingMethod = 1 AND TimeOverRaw IS NOT NULL THEN TimeOverRaw ELSE NULL END,
			TimeOverageRate = CASE WHEN IsOverageBillingMethod = 1 THEN TimeOverageRateRaw ELSE NULL END,
			TimeBillingAmount = CASE WHEN IsOverageBillingMethod = 1 AND TimeOverRaw IS NOT NULL
									  THEN (TimeOverRaw / 60.0) * ISNULL(TimeOverageRateRaw, 0) * Qty
									  ELSE NULL END,
			CycleRecorded,
			CycleLimit,
			CycleOver = CASE WHEN IsOverageBillingMethod = 1 AND CycleOverRaw IS NOT NULL THEN CycleOverRaw ELSE NULL END,
			CycleOverageRate = CASE WHEN IsOverageBillingMethod = 1 THEN CycleOverageRateRaw ELSE NULL END,
			CycleBillingAmount = CASE WHEN IsOverageBillingMethod = 1 AND CycleOverRaw IS NOT NULL
										THEN CycleOverRaw * ISNULL(CycleOverageRateRaw, 0) * Qty
										ELSE NULL END,
			Charges AS chargesAmount,
			Maintenance AS MaintenanceAmount,
			Insurance AS InsuranceAmount,
			Taxes AS TaxAmount,
			OtherComponentAmount AS OtherAmount,
			TotalBillingAmount =
					ISNULL(CASE WHEN IsFlatRateBillingMethod = 1 THEN ISNULL(FlatRate, 0) * Qty ELSE 0 END, 0)
				  + ISNULL(CASE WHEN IsOverageBillingMethod = 1 AND TimeOverRaw IS NOT NULL THEN (TimeOverRaw / 60.0) * ISNULL(TimeOverageRateRaw, 0) * Qty ELSE 0 END, 0)
				  + ISNULL(CASE WHEN IsOverageBillingMethod = 1 AND CycleOverRaw IS NOT NULL THEN CycleOverRaw * ISNULL(CycleOverageRateRaw, 0) * Qty ELSE 0 END, 0)
				  + ISNULL(Charges, 0)
				  + ISNULL(Maintenance, 0)
				  + ISNULL(Insurance, 0)
				  + ISNULL(Taxes, 0)
				  + ISNULL(OtherComponentAmount, 0),
			BillingInvoicingId,
			CASE WHEN LEN(ISNULL(InvoiceNo,'')) > 0  THEN 'Y' ELSE 'N' END AS BillingStatus,
			InvoiceNo AS InvoiceNumber,
			InvoiceDate AS InvoiceDate,
			HasUsageInfo,
			IsActive,
			LeaseStatusId
		FROM WithOver
		ORDER BY LeaseStocklineId;

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