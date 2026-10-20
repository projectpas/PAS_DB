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
    3    05/10/2026   Kishor Makwana	[PN-17949] A Usage Based period line is printed as two lines: 'Usage Time' (hours x Usage per Unit - Times) and 'Usage Cycle' (cycles x Usage per Unit - Cycles).
    4    16/10/2026   Kishor Makwana	[PN-18338 charges qty] Charges are printed one row per Lease Charge (Qty = Charge Qty, Unit Price = Unit Cost) instead of one row with Qty 1 and the summed
										amount as the unit price. Falls back to the old single summed row when the charge rows do not add up to the billed Charges amount.
    5    16/10/2026   Kishor Makwana	[PN-18345 recorded time/cycle] New RecordedTimeCycle column: the Usage Time / Usage Cycle rows now show the RECORDED time (HH:MM, same as the Billing grid) / recorded cycles there,
										and Qty is the stockline quantity with Unit Price = the usage rate (before, Qty was the rounded hours/cycles, which did not multiply out to the Total).
    
--   EXEC [dbo].[RPT_GetCommonBillingInvoicingItems_LeasePreview] @LeaseHeaderId = 1, @LeaseStocklineIds = '1,2,3'
********************************************************************************************/
CREATE PROCEDURE [dbo].[RPT_GetCommonBillingInvoicingItems_LeasePreview]
	@LeaseHeaderId BIGINT = NULL,
	@LeaseStocklineIds VARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		CREATE TABLE #G (
			LeaseStocklineId BIGINT, PartNumber NVARCHAR(MAX), PartDescription NVARCHAR(MAX), SerialNumber NVARCHAR(MAX), Qty DECIMAL(28,6),
			BillingMethod NVARCHAR(100), BillingFrequency NVARCHAR(100), FlatRate DECIMAL(28,6), LineType NVARCHAR(100), FromDate DATETIME2(7), ToDate DATETIME2(7),
			LineAmount DECIMAL(28,6), TimeRecorded DECIMAL(28,6), TimeLimit DECIMAL(28,6), TimeOver DECIMAL(28,6), TimeOverageRate DECIMAL(28,6), TimeBillingAmount DECIMAL(28,6),
			CycleRecorded DECIMAL(28,6), CycleLimit DECIMAL(28,6), CycleOver DECIMAL(28,6), CycleOverageRate DECIMAL(28,6), CycleBillingAmount DECIMAL(28,6),
			BillingInvoicingId BIGINT, BillingStatus VARCHAR(5), InvoiceNumber NVARCHAR(100), InvoiceDate DATETIME2(7),
			HasUsageInfo BIT, IsActive BIT, LeaseStatusId INT);
		-- The preview shows exactly what Create Invoice will save: the same lines the Billing grid computes (one source of truth).
		INSERT INTO #G EXEC [dbo].[USP_GetLeaseBillingListByLeaseHeaderId] @LeaseHeaderId = @LeaseHeaderId;

		;WITH SelectedIds AS (
			SELECT DISTINCT CAST(Item AS BIGINT) AS LeaseStocklineId
			FROM [dbo].[SplitString](@LeaseStocklineIds, ',')
			WHERE ISNUMERIC(Item) = 1
		),
		Src AS (
			SELECT
				G.LeaseStocklineId, LSL.[ItemMasterId],
				UPPER(ISNULL(LSL.[PN], '')) AS PNumber,
				UPPER(ISNULL(LSL.[PNDescription], '')) AS PNDescription,
				UPPER(COALESCE(STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber,
				UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
				UPPER(COALESCE(IM.[ConsumeUnitOfMeasure], IM.[StockUnitOfMeasure], '')) AS UOM,
				G.LineType, G.BillingMethod, G.FromDate,
				ISNULL(LSL.[QtyReserved], 0) AS LQty,
				LSL.[UsagePerUnitTimes] AS TimeRate, LSL.[UsagePerUnitCycles] AS CycleRate,
				G.TimeBillingAmount, G.CycleBillingAmount, G.TimeRecorded, G.CycleRecorded, G.ToDate,
				CASE WHEN G.LineType = 'Overrun' AND ISNULL(G.LineAmount, 0) = 0 AND (ISNULL(G.TimeBillingAmount, 0) <> 0 OR ISNULL(G.CycleBillingAmount, 0) <> 0) THEN 1 ELSE 0 END AS OvSplit,
				G.TimeLimit, G.TimeOver, G.TimeOverageRate, G.CycleLimit, G.CycleOver, G.CycleOverageRate,
				QX.Q, TX.Total, G.BillingStatus
			FROM #G G
			INNER JOIN SelectedIds SEL ON SEL.LeaseStocklineId = G.LeaseStocklineId
			INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.[LeaseStocklineId] = G.LeaseStocklineId
			LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
			LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = LSL.[ItemMasterId]
			CROSS APPLY (SELECT CASE WHEN G.LineType IN ('Flat Rate', 'Overrun') AND ISNULL(LSL.[QtyReserved], 0) > 0 THEN LSL.[QtyReserved] ELSE 1 END AS Q) QX
			CROSS APPLY (SELECT ISNULL(G.LineAmount, 0) + ISNULL(G.TimeBillingAmount, 0) + ISNULL(G.CycleBillingAmount, 0) AS Total) TX
			WHERE G.BillingStatus = 'D' OR (G.BillingStatus = 'N' AND TX.Total <> 0)
		),
		ChargesG AS (
			-- the 'Charges' lines the billing grid computed for the selected stocklines
			SELECT G.LeaseStocklineId, G.FromDate, G.ToDate, G.BillingStatus, G.BillingInvoicingId, ISNULL(G.LineAmount, 0) AS LineAmount
			FROM #G G
			INNER JOIN SelectedIds SEL ON SEL.LeaseStocklineId = G.LeaseStocklineId
			WHERE G.LineType = 'Charges' AND (G.BillingStatus = 'D' OR (G.BillingStatus = 'N' AND ISNULL(G.LineAmount, 0) <> 0))
		),
		ChargeRows AS (
			-- the individual Lease Charges that make up each 'Charges' line (same period rule as USP_GetLeaseBillingListByLeaseHeaderId)
			SELECT CG.LeaseStocklineId, CG.FromDate, CG.LineAmount AS GAmt, LC.[LeaseChargesId], LC.[Quantity], LC.[ExtendedCost], LC.[ReportedDate]
			FROM ChargesG CG
			INNER JOIN [dbo].[LeaseCharges] LC WITH (NOLOCK) ON LC.[LeaseStocklineId] = CG.LeaseStocklineId AND LC.[IsDeleted] = 0
				AND (
					(CG.BillingStatus = 'N' AND ISNULL(LC.[IsInvoiced], 0) = 0 AND LC.[BillingInvoicingItemId] IS NULL)
					OR (CG.BillingStatus = 'D' AND LC.[BillingInvoicingItemId] IN (SELECT BX.[BillingInvoicingItemId] FROM [dbo].[BillingInvoicingItems] BX WITH (NOLOCK)
							WHERE BX.[BillingInvoicingId] = CG.BillingInvoicingId AND BX.[SubReferenceId] = CG.LeaseStocklineId))
				)
			WHERE (CG.FromDate IS NOT NULL AND CAST(LC.[ReportedDate] AS DATE) BETWEEN CAST(CG.FromDate AS DATE) AND CAST(CG.ToDate AS DATE))
			   OR (CG.FromDate IS NULL AND NOT EXISTS (SELECT 1 FROM #G P WHERE P.LeaseStocklineId = CG.LeaseStocklineId AND P.FromDate IS NOT NULL AND P.LineType IN ('Flat Rate', 'Overrun')
							AND CAST(LC.[ReportedDate] AS DATE) BETWEEN CAST(P.FromDate AS DATE) AND CAST(P.ToDate AS DATE)))
		),
		ChargeExact AS (
			-- only split a Charges line when its charges add up exactly to the billed amount, otherwise keep the single summed row
			SELECT LeaseStocklineId, FromDate
			FROM ChargeRows
			GROUP BY LeaseStocklineId, FromDate, GAmt
			HAVING ABS(SUM(ISNULL([ExtendedCost], 0)) - GAmt) < 0.005
		),
		Lines AS (
			-- every line except a Usage Based period line (split into Usage Time / Usage Cycle), a Charges line that splits per charge, and an Overrun line that splits into Time / Cycle
			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				CASE LineType WHEN 'Others' THEN 'Other' ELSE LineType END AS LineBillingMethod,
				CAST(Q AS DECIMAL(18,6)) AS LineQty,
				CAST(Total / Q AS DECIMAL(18,6)) AS LineUnitPrice,
				Total AS LineTotal,
				CASE LineType WHEN 'Flat Rate' THEN 1 WHEN 'Overrun' THEN 3 WHEN 'Maintenance' THEN 6 WHEN 'Insurance' THEN 7
					WHEN 'Taxes' THEN 8 WHEN 'Others' THEN 9 WHEN 'Charges' THEN 10 ELSE 11 END AS SortOrder,
				FromDate AS SortDate,
				CAST(CASE WHEN LineType = 'Flat Rate' AND (ISNULL(TimeLimit, 0) > 0 OR ISNULL(CycleLimit, 0) > 0) THEN CASE WHEN ISNULL(TimeLimit, 0) > 0 THEN CAST(CAST(ROUND(TimeLimit, 0) AS INT) / 60 AS VARCHAR(10)) + ':' + RIGHT('0' + CAST(CAST(ROUND(TimeLimit, 0) AS INT) % 60 AS VARCHAR(2)), 2) ELSE '' END + CASE WHEN ISNULL(TimeLimit, 0) > 0 AND ISNULL(CycleLimit, 0) > 0 THEN ' / ' ELSE '' END + CASE WHEN ISNULL(CycleLimit, 0) > 0 THEN CAST(CAST(ROUND(CycleLimit, 0) AS INT) AS VARCHAR(20)) ELSE '' END WHEN LineType = 'Overrun' THEN CASE WHEN ISNULL(TimeOver, 0) > 0 THEN CAST(CAST(ROUND(TimeOver, 0) AS INT) / 60 AS VARCHAR(10)) + ':' + RIGHT('0' + CAST(CAST(ROUND(TimeOver, 0) AS INT) % 60 AS VARCHAR(2)), 2) ELSE '' END + CASE WHEN ISNULL(TimeOver, 0) > 0 AND ISNULL(CycleOver, 0) > 0 THEN ' / ' ELSE '' END + CASE WHEN ISNULL(CycleOver, 0) > 0 THEN CAST(CAST(ROUND(CycleOver, 0) AS INT) AS VARCHAR(20)) ELSE '' END ELSE '' END AS VARCHAR(40)) AS LineRecorded,
				CAST(CASE WHEN FromDate IS NOT NULL AND ToDate IS NOT NULL THEN CONVERT(VARCHAR(8), FromDate, 1) + ' - ' + CONVERT(VARCHAR(8), ToDate, 1) ELSE '' END AS VARCHAR(25)) AS LinePeriod
			FROM Src
			WHERE NOT (LineType = 'Flat Rate' AND BillingMethod = 'UsageBased')
			  AND NOT (LineType = 'Overrun' AND OvSplit = 1)
			  AND NOT (LineType = 'Charges' AND EXISTS (SELECT 1 FROM ChargeExact CE WHERE CE.LeaseStocklineId = Src.LeaseStocklineId AND ISNULL(CE.FromDate, '19000101') = ISNULL(Src.FromDate, '19000101')))

			UNION ALL

			-- Charges: one row per Lease Charge (Qty x Unit Cost = Extended Cost)
			SELECT S.LeaseStocklineId, S.ItemMasterId, S.PNumber, S.PNDescription, S.SerialNumber, S.StockLineNumber, S.UOM,
				'Charges',
				CAST(ISNULL(NULLIF(CR.[Quantity], 0), 1) AS DECIMAL(18,6)),
				CAST(ISNULL(CR.[ExtendedCost], 0) / ISNULL(NULLIF(CR.[Quantity], 0), 1) AS DECIMAL(18,6)),
				ISNULL(CR.[ExtendedCost], 0),
				10,
				CAST(CR.[ReportedDate] AS DATETIME2(7)),
				CAST('' AS VARCHAR(40)),
				CAST(CONVERT(VARCHAR(8), CR.[ReportedDate], 1) AS VARCHAR(25))
			FROM ChargeRows CR
			INNER JOIN ChargeExact CE ON CE.LeaseStocklineId = CR.LeaseStocklineId AND ISNULL(CE.FromDate, '19000101') = ISNULL(CR.FromDate, '19000101')
			INNER JOIN Src S ON S.LeaseStocklineId = CR.LeaseStocklineId AND S.LineType = 'Charges' AND ISNULL(S.FromDate, '19000101') = ISNULL(CR.FromDate, '19000101')

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Usage Time',
				CAST(Q AS DECIMAL(18,6)),
				CAST(COALESCE(NULLIF(TimeRate, 0), TimeBillingAmount / NULLIF(H.Hours * Q, 0)) AS DECIMAL(18,6)),
				TimeBillingAmount, 1, FromDate,
				CAST(CAST(RM.M / 60 AS VARCHAR(10)) + ':' + RIGHT('0' + CAST(RM.M % 60 AS VARCHAR(2)), 2) AS VARCHAR(40)),
				CAST(CASE WHEN FromDate IS NOT NULL AND ToDate IS NOT NULL THEN CONVERT(VARCHAR(8), FromDate, 1) + ' - ' + CONVERT(VARCHAR(8), ToDate, 1) ELSE '' END AS VARCHAR(25))
			FROM Src
			CROSS APPLY (SELECT COALESCE(TimeBillingAmount / NULLIF(TimeRate * LQty, 0), TimeRecorded / 60.0, 1) AS Hours) H
			CROSS APPLY (SELECT CAST(ROUND(COALESCE(H.Hours * 60, TimeRecorded, 0), 0) AS INT) AS M) RM
			WHERE LineType = 'Flat Rate' AND BillingMethod = 'UsageBased' AND ISNULL(TimeBillingAmount, 0) <> 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Usage Cycle',
				CAST(Q AS DECIMAL(18,6)),
				CAST(COALESCE(NULLIF(CycleRate, 0), CycleBillingAmount / NULLIF(H.Cycles * Q, 0)) AS DECIMAL(18,6)),
				CycleBillingAmount, 2, FromDate,
				CAST(CAST(ROUND(COALESCE(H.Cycles, CycleRecorded, 0), 0) AS INT) AS VARCHAR(20)),
				CAST(CASE WHEN FromDate IS NOT NULL AND ToDate IS NOT NULL THEN CONVERT(VARCHAR(8), FromDate, 1) + ' - ' + CONVERT(VARCHAR(8), ToDate, 1) ELSE '' END AS VARCHAR(25))
			FROM Src
			CROSS APPLY (SELECT COALESCE(CycleBillingAmount / NULLIF(CycleRate * LQty, 0), CycleRecorded, 1) AS Cycles) H
			WHERE LineType = 'Flat Rate' AND BillingMethod = 'UsageBased' AND ISNULL(CycleBillingAmount, 0) <> 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Overrun - Time',
				CAST(Q AS DECIMAL(18,6)),
				CAST(COALESCE(NULLIF(TimeOverageRate, 0), TimeBillingAmount / NULLIF((TimeOver / 60.0) * Q, 0)) AS DECIMAL(18,6)),
				TimeBillingAmount, 3, FromDate,
				CAST(CAST(CAST(ROUND(TimeOver, 0) AS INT) / 60 AS VARCHAR(10)) + ':' + RIGHT('0' + CAST(CAST(ROUND(TimeOver, 0) AS INT) % 60 AS VARCHAR(2)), 2) AS VARCHAR(40)),
				CAST(CASE WHEN FromDate IS NOT NULL AND ToDate IS NOT NULL THEN CONVERT(VARCHAR(8), FromDate, 1) + ' - ' + CONVERT(VARCHAR(8), ToDate, 1) ELSE '' END AS VARCHAR(25))
			FROM Src
			WHERE LineType = 'Overrun' AND OvSplit = 1 AND ISNULL(TimeBillingAmount, 0) <> 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Overrun - Cycle',
				CAST(Q AS DECIMAL(18,6)),
				CAST(COALESCE(NULLIF(CycleOverageRate, 0), CycleBillingAmount / NULLIF(CycleOver * Q, 0)) AS DECIMAL(18,6)),
				CycleBillingAmount, 4, FromDate,
				CAST(CAST(CAST(ROUND(CycleOver, 0) AS INT) AS VARCHAR(20)) AS VARCHAR(40)),
				CAST(CASE WHEN FromDate IS NOT NULL AND ToDate IS NOT NULL THEN CONVERT(VARCHAR(8), FromDate, 1) + ' - ' + CONVERT(VARCHAR(8), ToDate, 1) ELSE '' END AS VARCHAR(25))
			FROM Src
			WHERE LineType = 'Overrun' AND OvSplit = 1 AND ISNULL(CycleBillingAmount, 0) <> 0
		)
		SELECT
				ROW_NUMBER() OVER (ORDER BY LeaseStocklineId, SortOrder, SortDate) AS ItemNo,
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
				LineRecorded AS BilledBasis,
				LinePeriod AS PeriodText,
				LineQty AS Qty,
				LineUnitPrice AS UnitPrice,
				LineTotal AS Total,
				DENSE_RANK() OVER (ORDER BY LeaseStocklineId) AS PnLineNo
			FROM Lines
			ORDER BY LeaseStocklineId, SortOrder, SortDate;

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