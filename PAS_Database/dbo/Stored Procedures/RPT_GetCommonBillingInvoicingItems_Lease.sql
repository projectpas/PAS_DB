/*****************************************************************************************           
 ** File:   [RPT_GetCommonBillingInvoicingItems_Lease]           
 ** Author:   Kishor Makwana 
 ** Description: This stored procedure is used to Get the Lease Invoice line-item grid data for
 **              the Lease Invoice SSRS report (LeaseBilling.rdl). 
 ** Purpose:         
 ** Date:   24/SEP/2026     
 ** RETURN VALUE:           
 ******************************************************************************************           
 ** Change History           
 ******************************************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    24/SEP/2026   Kishor Makwana	CREATED [PN-18072]
    2    28/SEP/2026   Kishor Makwana	[PN-17949 follow-up] Time/Cycle billing now persists a base-usage breakdown (TimeUsageQty/Rate/Amount, CycleUsageQty/Rate/Amount) on
	                                        LeaseBillingInvoicingItemDetails alongside the existing overage-only columns, because TimeBillingAmount/CycleBillingAmount now include
	                                        BOTH the base (Min-Max range) usage and the overage, so the old 'Time Overrun'/'Cycle Overrun' rows (Qty=TimeOver, Price=OverageRate,
	                                        Total=TimeBillingAmount) no longer had Qty*Price=Total. Added new 'Time Usage'/'Cycle Usage' line items reading the new persisted
	                                        columns, and tightened the Overrun rows to use TimeOver/CycleOver > 0 (with LineTotal recomputed as TimeOver/CycleOver * OverageRate * Qty)
	                                        so every row's Qty*UnitPrice=Total again. SortOrder renumbered: 1 Flat Rate, 2 Time Usage, 3 Time Overrun, 4 Cycle Usage,
	                                        5 Cycle Overrun, 6 Maintenance, 7 Insurance, 8 Taxes, 9 Other, 10 Charges, 0 fallback.
    3    05/10/2026   Kishor Makwana	[PN-18072 draft/per-line invoice] Invoices are now stored as one LeaseBillingInvoicingItemDetails row PER LINE (LineType/FromDate/ToDate/LineAmount),
	                                        so joining every detail row to every synthesized line type printed each line N times (and live Maintenance/Insurance/Charges instead of what was
	                                        saved on the invoice). Items that have typed detail rows now print exactly one row per detail row (TypedLines, same labels/amounts as the preview).
	                                        Legacy items (no typed rows) still use the old single-row Lines logic.
	                                        [Usage Based] A Usage Based period line prints as two lines - 'Usage Time' (TimeUsageQty x rate) and 'Usage Cycle' (CycleUsageQty x rate) - from the saved TimeUsage* / CycleUsage* columns.
    4    06/10/2026     Kishor Makwana   [PN-18188 service component] Maintenance/Insurance/Taxes are now read from the LeaseStocklineServiceComponent rows named Maintenance/Insurance/Taxes (new storage of the Edit Service Component popup); the LeaseStockline columns are only a fallback when no such row exists. 'Other' is the sum of the remaining custom rows only - it used to sum every row, so Maintenance/Insurance/Taxes were counted twice.
    5    07/10/2026     Kishor Makwana   [PN-17949 service component by date] Service components with a Start Date and End Date are now billed month by month and saved as one detail row per month (USP_CreateLeaseBillingInvoice), so the typed rows already print each month's share. The legacy single-row fallback (items with no detail rows) no longer adds the TOTAL of dated components as a one-time line (only components without dates).
    6    16/10/2026   Kishor Makwana	[PN-18338 charges qty] Charges are printed one row per Lease Charge linked to the invoice item (Qty = Charge Qty, Unit Price = Unit Cost) instead of one row with Qty 1 and
	                                        the summed amount as the unit price. Falls back to the saved single summed row when the charge rows do not add up to the saved Charges amount.
    7    16/10/2026   Kishor Makwana	[PN-18345 recorded time/cycle] New RecordedTimeCycle column: the Usage Time / Usage Cycle rows now show the RECORDED time (HH:MM, same as the Billing grid) / recorded cycles there,
	                                        and Qty is the stockline quantity with Unit Price = the saved usage rate (before, Qty was the rounded hours/cycles, which did not multiply out to the Total).
    
--   EXEC [dbo].[RPT_GetCommonBillingInvoicingItems_Lease] 1,72
********************************************************************************************/
CREATE PROCEDURE [dbo].[RPT_GetCommonBillingInvoicingItems_Lease]
@BillingInvoicingId BIGINT = NULL,
@ModuleId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @LeaseModuleId INT
		SELECT @LeaseModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Leasing';

		IF(@ModuleId = @LeaseModuleId) /*********START: LEASE ********/
		BEGIN
			;WITH Base AS (
				SELECT
					BII.[BillingInvoicingItemId],
					BII.[BillingInvoicingId],
					LSL.[LeaseStocklineId] AS SubReferenceId,
					BII.[ItemMasterId],
					UPPER(ISNULL(LSL.[PN], '')) AS PNumber,
					UPPER(ISNULL(LSL.[PNDescription], '')) AS PNDescription,
					UPPER(COALESCE(BII.[SerialNumber], STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber,
					UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
					UPPER(COALESCE(IM.[ConsumeUnitOfMeasure], IM.[StockUnitOfMeasure], '')) AS UOM,
					ISNULL(LSL.[QtyReserved], 0) AS Qty,
					COALESCE(LBID.[BillingMethod], LSL.[BillingMethod], '') AS BillingMethod,
					LBID.[FlatRate],
					LBID.[FlatRateAmount],
					LBID.[TimeOver],
					LBID.[TimeOverageRate],
					LBID.[TimeBillingAmount],
					LBID.[CycleOver],
					LBID.[CycleOverageRate],
					LBID.[CycleBillingAmount],
					LBID.[TimeUsageQty],
					LBID.[TimeUsageRate],
					LBID.[TimeUsageAmount],
					LBID.[CycleUsageQty],
					LBID.[CycleUsageRate],
					LBID.[CycleUsageAmount],
					ISNULL(BII.[GrandTotal], 0) AS GrandTotal,
					ISNULL(ChargesAgg.Charges, 0) AS Charges,
					COALESCE(SC_SUM.MaintenanceAmount, LSL.[Maintenance]) AS [Maintenance],
					COALESCE(SC_SUM.InsuranceAmount, LSL.[Insurance]) AS [Insurance],
					COALESCE(SC_SUM.TaxesAmount, LSL.[Taxes]) AS [Taxes],
					ISNULL(SC_SUM.OtherComponentAmount, 0) AS OtherComponentAmount
				FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
				INNER JOIN [dbo].[LeaseStockline] LSL WITH(NOLOCK) ON BII.[SubReferenceId] = LSL.[LeaseStocklineId]
				LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON BII.[StocklineId] = STK.[StockLineId]
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON BII.[ItemMasterId] = IM.[ItemMasterId]
				LEFT JOIN [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH(NOLOCK) ON LBID.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId] AND ISNULL(LBID.[IsDeleted],0) = 0 AND ISNULL(LBID.[IsVersionIncrease],0) = 0
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
					SUM(CASE WHEN UPPER(LTRIM(RTRIM(ComponentName))) IN ('MAINTENANCE', 'INSURANCE', 'TAXES') OR (StartDate IS NOT NULL AND EndDate IS NOT NULL AND EndDate >= StartDate) THEN 0 ELSE ISNULL(Amount, 0) END) AS OtherComponentAmount
					FROM [dbo].[LeaseStocklineServiceComponent] WITH (NOLOCK)
					WHERE IsDeleted = 0
					GROUP BY LeaseStocklineId
				) SC_SUM ON SC_SUM.LeaseStocklineId = LSL.LeaseStocklineId
				WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsDeleted],0) = 0 AND ISNULL(BII.[IsVersionIncrease],0) = 0
				  AND NOT EXISTS (SELECT 1 FROM [dbo].[LeaseBillingInvoicingItemDetails] LBX WITH(NOLOCK)
								  WHERE LBX.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId] AND ISNULL(LBX.[IsDeleted],0) = 0 AND ISNULL(LBX.[IsVersionIncrease],0) = 0 AND LBX.[LineType] IS NOT NULL)
			),
			Lines AS (
				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Flat Rate' AS LineBillingMethod,
					CAST(Qty AS DECIMAL(18,6)) AS LineQty,
					ISNULL(FlatRate, 0) AS LineUnitPrice,
					FlatRateAmount AS LineTotal,
					1 AS SortOrder
				FROM Base WHERE FlatRateAmount IS NOT NULL

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Time Usage' AS LineBillingMethod,
					CAST(TimeUsageQty AS DECIMAL(18,6)) AS LineQty,
					ISNULL(TimeUsageRate, 0) AS LineUnitPrice,
					TimeUsageAmount AS LineTotal,
					2 AS SortOrder
				FROM Base WHERE TimeUsageQty IS NOT NULL AND TimeUsageQty > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Time Overrun' AS LineBillingMethod,
					CAST(TimeOver AS DECIMAL(18,6)) AS LineQty,
					ISNULL(TimeOverageRate, 0) AS LineUnitPrice,
					ISNULL(TimeOver, 0) * ISNULL(TimeOverageRate, 0) * Qty AS LineTotal,
					3 AS SortOrder
				FROM Base WHERE TimeOver IS NOT NULL AND TimeOver > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Cycle Usage' AS LineBillingMethod,
					CAST(CycleUsageQty AS DECIMAL(18,6)) AS LineQty,
					ISNULL(CycleUsageRate, 0) AS LineUnitPrice,
					CycleUsageAmount AS LineTotal,
					4 AS SortOrder
				FROM Base WHERE CycleUsageQty IS NOT NULL AND CycleUsageQty > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Cycle Overrun' AS LineBillingMethod,
					CAST(CycleOver AS DECIMAL(18,6)) AS LineQty,
					ISNULL(CycleOverageRate, 0) AS LineUnitPrice,
					ISNULL(CycleOver, 0) * ISNULL(CycleOverageRate, 0) * Qty AS LineTotal,
					5 AS SortOrder
				FROM Base WHERE CycleOver IS NOT NULL AND CycleOver > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Maintenance' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Maintenance, 0) AS LineUnitPrice,
					ISNULL(Maintenance, 0) AS LineTotal,
					6 AS SortOrder
				FROM Base WHERE ISNULL(Maintenance, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Insurance' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Insurance, 0) AS LineUnitPrice,
					ISNULL(Insurance, 0) AS LineTotal,
					7 AS SortOrder
				FROM Base WHERE ISNULL(Insurance, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Taxes' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Taxes, 0) AS LineUnitPrice,
					ISNULL(Taxes, 0) AS LineTotal,
					8 AS SortOrder
				FROM Base WHERE ISNULL(Taxes, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Other' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(OtherComponentAmount, 0) AS LineUnitPrice,
					ISNULL(OtherComponentAmount, 0) AS LineTotal,
					9 AS SortOrder
				FROM Base WHERE ISNULL(OtherComponentAmount, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Charges' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Charges, 0) AS LineUnitPrice,
					ISNULL(Charges, 0) AS LineTotal,
					10 AS SortOrder
				FROM Base WHERE ISNULL(Charges, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					CASE BillingMethod
						WHEN 'FlatRateOnly' THEN 'Flat Rate Only'
						WHEN 'FlatRatePlusOverrun' THEN 'Flat Rate + Overrun'
						WHEN 'UsageBased' THEN 'Usage Based'
						ELSE ISNULL(BillingMethod, '')
					END AS LineBillingMethod,
					CAST(Qty AS DECIMAL(18,6)) AS LineQty,
					CAST(0 AS DECIMAL(18,6)) AS LineUnitPrice,
					GrandTotal AS LineTotal,
					0 AS SortOrder
				FROM Base
				WHERE NOT (TimeUsageQty IS NOT NULL AND TimeUsageQty > 0)
				  AND NOT (TimeOver IS NOT NULL AND TimeOver > 0)
				  AND NOT (CycleUsageQty IS NOT NULL AND CycleUsageQty > 0)
				  AND NOT (CycleOver IS NOT NULL AND CycleOver > 0)
				  --FlatRateAmount IS NULL AND (kept out intentionally, same as before)
			)
			,ChargeRows AS (
				-- the individual Lease Charges behind each saved 'Charges' detail row (charges are linked to the invoice item when it is created)
				SELECT BII.[BillingInvoicingItemId], LBID.[FromDate], ISNULL(LBID.[LineAmount], 0) AS DAmt, LC.[LeaseChargesId], LC.[Quantity], LC.[ExtendedCost], LC.[ReportedDate]
				FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
				INNER JOIN [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH(NOLOCK) ON LBID.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId]
					AND ISNULL(LBID.[IsDeleted],0) = 0 AND ISNULL(LBID.[IsVersionIncrease],0) = 0 AND LBID.[LineType] = 'Charges'
				INNER JOIN [dbo].[LeaseCharges] LC WITH(NOLOCK) ON LC.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId] AND LC.[IsDeleted] = 0
				WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsDeleted],0) = 0 AND ISNULL(BII.[IsVersionIncrease],0) = 0
				  AND (
						(LBID.[FromDate] IS NOT NULL AND CAST(LC.[ReportedDate] AS DATE) BETWEEN CAST(LBID.[FromDate] AS DATE) AND CAST(LBID.[ToDate] AS DATE))
					 OR (LBID.[FromDate] IS NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[LeaseBillingInvoicingItemDetails] L2 WITH(NOLOCK)
								WHERE L2.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId] AND L2.[LineType] = 'Charges' AND ISNULL(L2.[IsDeleted],0) = 0 AND L2.[FromDate] IS NOT NULL
								  AND CAST(LC.[ReportedDate] AS DATE) BETWEEN CAST(L2.[FromDate] AS DATE) AND CAST(L2.[ToDate] AS DATE)))
				  )
			)
			,ChargeExact AS (
				-- only split a Charges row when its charges add up exactly to the saved amount, otherwise keep the single saved row
				SELECT BillingInvoicingItemId, FromDate
				FROM ChargeRows
				GROUP BY BillingInvoicingItemId, FromDate, DAmt
				HAVING ABS(SUM(ISNULL([ExtendedCost], 0)) - DAmt) < 0.005
			)
			,TypedLines AS (
				-- One printed row per saved detail row (what the user saw/saved), no live re-computation.
				SELECT
					BII.[BillingInvoicingItemId], BII.[BillingInvoicingId], LSL.[LeaseStocklineId] AS SubReferenceId, BII.[ItemMasterId],
					UPPER(ISNULL(LSL.[PN], '')) AS PNumber,
					UPPER(ISNULL(LSL.[PNDescription], '')) AS PNDescription,
					UPPER(COALESCE(BII.[SerialNumber], STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber,
					UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
					UPPER(COALESCE(IM.[ConsumeUnitOfMeasure], IM.[StockUnitOfMeasure], '')) AS UOM,
					CASE LBID.[LineType] WHEN 'Others' THEN 'Other' ELSE LBID.[LineType] END AS LineBillingMethod,
					CAST(QX.Q AS DECIMAL(18,6)) AS LineQty,
					CAST(ISNULL(LBID.[LineAmount], 0) / QX.Q AS DECIMAL(18,6)) AS LineUnitPrice,
					ISNULL(LBID.[LineAmount], 0) AS LineTotal,
					CASE LBID.[LineType] WHEN 'Flat Rate' THEN 1 WHEN 'Overrun' THEN 3 WHEN 'Maintenance' THEN 6 WHEN 'Insurance' THEN 7
						WHEN 'Taxes' THEN 8 WHEN 'Others' THEN 9 WHEN 'Charges' THEN 10 ELSE 11 END AS SortOrder,
					LBID.[FromDate] AS SortDate,
					CAST(CASE WHEN LBID.[LineType] = 'Flat Rate' AND (ISNULL(LBID.[TimeLimit], 0) > 0 OR ISNULL(LBID.[CycleLimit], 0) > 0) THEN CASE WHEN ISNULL(LBID.[TimeLimit], 0) > 0 THEN CAST(CAST(ROUND(LBID.[TimeLimit] * 60, 0) AS INT) / 60 AS VARCHAR(10)) + ':' + RIGHT('0' + CAST(CAST(ROUND(LBID.[TimeLimit] * 60, 0) AS INT) % 60 AS VARCHAR(2)), 2) ELSE '' END + CASE WHEN ISNULL(LBID.[TimeLimit], 0) > 0 AND ISNULL(LBID.[CycleLimit], 0) > 0 THEN ' / ' ELSE '' END + CASE WHEN ISNULL(LBID.[CycleLimit], 0) > 0 THEN CAST(CAST(ROUND(LBID.[CycleLimit], 0) AS INT) AS VARCHAR(20)) ELSE '' END WHEN LBID.[LineType] = 'Overrun' THEN CASE WHEN ISNULL(LBID.[TimeOver], 0) > 0 THEN CAST(CAST(ROUND(LBID.[TimeOver] * 60, 0) AS INT) / 60 AS VARCHAR(10)) + ':' + RIGHT('0' + CAST(CAST(ROUND(LBID.[TimeOver] * 60, 0) AS INT) % 60 AS VARCHAR(2)), 2) ELSE '' END + CASE WHEN ISNULL(LBID.[TimeOver], 0) > 0 AND ISNULL(LBID.[CycleOver], 0) > 0 THEN ' / ' ELSE '' END + CASE WHEN ISNULL(LBID.[CycleOver], 0) > 0 THEN CAST(CAST(ROUND(LBID.[CycleOver], 0) AS INT) AS VARCHAR(20)) ELSE '' END ELSE '' END AS VARCHAR(40)) AS LineRecorded,
					CAST(CASE WHEN LBID.[FromDate] IS NOT NULL AND LBID.[ToDate] IS NOT NULL THEN CONVERT(VARCHAR(8), LBID.[FromDate], 1) + ' - ' + CONVERT(VARCHAR(8), LBID.[ToDate], 1) ELSE '' END AS VARCHAR(25)) AS LinePeriod
				FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
				INNER JOIN [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH(NOLOCK) ON LBID.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId]
					AND ISNULL(LBID.[IsDeleted],0) = 0 AND ISNULL(LBID.[IsVersionIncrease],0) = 0 AND LBID.[LineType] IS NOT NULL
					AND NOT (LBID.[LineType] = 'Overrun' AND ISNULL(LBID.[LineAmount],0) = 0)
				INNER JOIN [dbo].[LeaseStockline] LSL WITH(NOLOCK) ON BII.[SubReferenceId] = LSL.[LeaseStocklineId]
				LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON BII.[StocklineId] = STK.[StockLineId]
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON BII.[ItemMasterId] = IM.[ItemMasterId]
				CROSS APPLY (SELECT CASE WHEN LBID.[LineType] IN ('Flat Rate', 'Overrun') AND ISNULL(LSL.[QtyReserved], 0) > 0 THEN LSL.[QtyReserved] ELSE 1 END AS Q) QX
				CROSS APPLY (SELECT CASE WHEN LBID.[LineType] = 'Overrun' AND (ISNULL(LBID.[TimeBillingAmount], 0) <> 0 OR ISNULL(LBID.[CycleBillingAmount], 0) <> 0)
						AND ABS(ISNULL(LBID.[LineAmount], 0) - (ISNULL(LBID.[TimeBillingAmount], 0) + ISNULL(LBID.[CycleBillingAmount], 0))) < 0.005 THEN 1 ELSE 0 END AS Spl) OV
				WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsDeleted],0) = 0 AND ISNULL(BII.[IsVersionIncrease],0) = 0
				  AND NOT (LBID.[LineType] = 'Flat Rate' AND LSL.[BillingMethod] = 'UsageBased')
				  AND NOT (LBID.[LineType] = 'Overrun' AND OV.Spl = 1)
				  AND NOT (LBID.[LineType] = 'Charges' AND EXISTS (SELECT 1 FROM ChargeExact CE WHERE CE.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId] AND ISNULL(CE.[FromDate], '19000101') = ISNULL(LBID.[FromDate], '19000101')))

				UNION ALL

				-- Charges: one row per Lease Charge (Qty x Unit Cost = Extended Cost)
				SELECT
					BII.[BillingInvoicingItemId], BII.[BillingInvoicingId], LSL.[LeaseStocklineId] AS SubReferenceId, BII.[ItemMasterId],
					UPPER(ISNULL(LSL.[PN], '')) AS PNumber,
					UPPER(ISNULL(LSL.[PNDescription], '')) AS PNDescription,
					UPPER(COALESCE(BII.[SerialNumber], STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber,
					UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
					UPPER(COALESCE(IM.[ConsumeUnitOfMeasure], IM.[StockUnitOfMeasure], '')) AS UOM,
					'Charges' AS LineBillingMethod,
					CAST(ISNULL(NULLIF(CR.[Quantity], 0), 1) AS DECIMAL(18,6)) AS LineQty,
					CAST(ISNULL(CR.[ExtendedCost], 0) / ISNULL(NULLIF(CR.[Quantity], 0), 1) AS DECIMAL(18,6)) AS LineUnitPrice,
					ISNULL(CR.[ExtendedCost], 0) AS LineTotal,
					10 AS SortOrder,
					CAST(CR.[ReportedDate] AS DATETIME2(7)) AS SortDate,
					CAST('' AS VARCHAR(40)) AS LineRecorded,
					CAST(CONVERT(VARCHAR(8), CR.[ReportedDate], 1) AS VARCHAR(25)) AS LinePeriod
				FROM ChargeRows CR
				INNER JOIN ChargeExact CE ON CE.[BillingInvoicingItemId] = CR.[BillingInvoicingItemId] AND ISNULL(CE.[FromDate], '19000101') = ISNULL(CR.[FromDate], '19000101')
				INNER JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON BII.[BillingInvoicingItemId] = CR.[BillingInvoicingItemId]
				INNER JOIN [dbo].[LeaseStockline] LSL WITH(NOLOCK) ON BII.[SubReferenceId] = LSL.[LeaseStocklineId]
				LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON BII.[StocklineId] = STK.[StockLineId]
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON BII.[ItemMasterId] = IM.[ItemMasterId]

				UNION ALL

				SELECT
					BII.[BillingInvoicingItemId], BII.[BillingInvoicingId], LSL.[LeaseStocklineId] AS SubReferenceId, BII.[ItemMasterId],
					UPPER(ISNULL(LSL.[PN], '')) AS PNumber,
					UPPER(ISNULL(LSL.[PNDescription], '')) AS PNDescription,
					UPPER(COALESCE(BII.[SerialNumber], STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber,
					UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
					UPPER(COALESCE(IM.[ConsumeUnitOfMeasure], IM.[StockUnitOfMeasure], '')) AS UOM,
					'Usage Time' AS LineBillingMethod,
					CAST(QX.Q AS DECIMAL(18,6)) AS LineQty,
					CAST(COALESCE(NULLIF(LBID.[TimeUsageRate], 0), ISNULL(LBID.[TimeBillingAmount], 0) / NULLIF(ISNULL(NULLIF(LBID.[TimeUsageQty],0), 1) * QX.Q, 0)) AS DECIMAL(18,6)) AS LineUnitPrice,
					ISNULL(LBID.[TimeBillingAmount], 0) AS LineTotal,
					1 AS SortOrder,
					LBID.[FromDate] AS SortDate,
					CAST(CAST(RM.M / 60 AS VARCHAR(10)) + ':' + RIGHT('0' + CAST(RM.M % 60 AS VARCHAR(2)), 2) AS VARCHAR(40)) AS LineRecorded,
					CAST(CASE WHEN LBID.[FromDate] IS NOT NULL AND LBID.[ToDate] IS NOT NULL THEN CONVERT(VARCHAR(8), LBID.[FromDate], 1) + ' - ' + CONVERT(VARCHAR(8), LBID.[ToDate], 1) ELSE '' END AS VARCHAR(25)) AS LinePeriod
				FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
				INNER JOIN [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH(NOLOCK) ON LBID.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId]
					AND ISNULL(LBID.[IsDeleted],0) = 0 AND ISNULL(LBID.[IsVersionIncrease],0) = 0 AND LBID.[LineType] IS NOT NULL
					AND NOT (LBID.[LineType] = 'Overrun' AND ISNULL(LBID.[LineAmount],0) = 0)
				INNER JOIN [dbo].[LeaseStockline] LSL WITH(NOLOCK) ON BII.[SubReferenceId] = LSL.[LeaseStocklineId]
				LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON BII.[StocklineId] = STK.[StockLineId]
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON BII.[ItemMasterId] = IM.[ItemMasterId]
				CROSS APPLY (SELECT CASE WHEN LBID.[LineType] IN ('Flat Rate', 'Overrun') AND ISNULL(LSL.[QtyReserved], 0) > 0 THEN LSL.[QtyReserved] ELSE 1 END AS Q) QX
				CROSS APPLY (SELECT CASE WHEN LBID.[LineType] = 'Overrun' AND (ISNULL(LBID.[TimeBillingAmount], 0) <> 0 OR ISNULL(LBID.[CycleBillingAmount], 0) <> 0)
						AND ABS(ISNULL(LBID.[LineAmount], 0) - (ISNULL(LBID.[TimeBillingAmount], 0) + ISNULL(LBID.[CycleBillingAmount], 0))) < 0.005 THEN 1 ELSE 0 END AS Spl) OV
				CROSS APPLY (SELECT CAST(ROUND(COALESCE(NULLIF(LBID.[TimeUsageQty], 0) * 60, LBID.[TimeRecorded] * 60, 0), 0) AS INT) AS M) RM
				WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsDeleted],0) = 0 AND ISNULL(BII.[IsVersionIncrease],0) = 0
				  AND LBID.[LineType] = 'Flat Rate' AND LSL.[BillingMethod] = 'UsageBased' AND ISNULL(LBID.[TimeBillingAmount],0) <> 0

				UNION ALL

				SELECT
					BII.[BillingInvoicingItemId], BII.[BillingInvoicingId], LSL.[LeaseStocklineId] AS SubReferenceId, BII.[ItemMasterId],
					UPPER(ISNULL(LSL.[PN], '')) AS PNumber,
					UPPER(ISNULL(LSL.[PNDescription], '')) AS PNDescription,
					UPPER(COALESCE(BII.[SerialNumber], STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber,
					UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
					UPPER(COALESCE(IM.[ConsumeUnitOfMeasure], IM.[StockUnitOfMeasure], '')) AS UOM,
					'Usage Cycle' AS LineBillingMethod,
					CAST(QX.Q AS DECIMAL(18,6)) AS LineQty,
					CAST(COALESCE(NULLIF(LBID.[CycleUsageRate], 0), ISNULL(LBID.[CycleBillingAmount], 0) / NULLIF(ISNULL(NULLIF(LBID.[CycleUsageQty],0), 1) * QX.Q, 0)) AS DECIMAL(18,6)) AS LineUnitPrice,
					ISNULL(LBID.[CycleBillingAmount], 0) AS LineTotal,
					2 AS SortOrder,
					LBID.[FromDate] AS SortDate,
					CAST(CAST(CAST(ROUND(COALESCE(NULLIF(LBID.[CycleUsageQty], 0), LBID.[CycleRecorded], 0), 0) AS INT) AS VARCHAR(20)) AS VARCHAR(40)) AS LineRecorded,
					CAST(CASE WHEN LBID.[FromDate] IS NOT NULL AND LBID.[ToDate] IS NOT NULL THEN CONVERT(VARCHAR(8), LBID.[FromDate], 1) + ' - ' + CONVERT(VARCHAR(8), LBID.[ToDate], 1) ELSE '' END AS VARCHAR(25)) AS LinePeriod
				FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
				INNER JOIN [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH(NOLOCK) ON LBID.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId]
					AND ISNULL(LBID.[IsDeleted],0) = 0 AND ISNULL(LBID.[IsVersionIncrease],0) = 0 AND LBID.[LineType] IS NOT NULL
					AND NOT (LBID.[LineType] = 'Overrun' AND ISNULL(LBID.[LineAmount],0) = 0)
				INNER JOIN [dbo].[LeaseStockline] LSL WITH(NOLOCK) ON BII.[SubReferenceId] = LSL.[LeaseStocklineId]
				LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON BII.[StocklineId] = STK.[StockLineId]
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON BII.[ItemMasterId] = IM.[ItemMasterId]
				CROSS APPLY (SELECT CASE WHEN LBID.[LineType] IN ('Flat Rate', 'Overrun') AND ISNULL(LSL.[QtyReserved], 0) > 0 THEN LSL.[QtyReserved] ELSE 1 END AS Q) QX
				CROSS APPLY (SELECT CASE WHEN LBID.[LineType] = 'Overrun' AND (ISNULL(LBID.[TimeBillingAmount], 0) <> 0 OR ISNULL(LBID.[CycleBillingAmount], 0) <> 0)
						AND ABS(ISNULL(LBID.[LineAmount], 0) - (ISNULL(LBID.[TimeBillingAmount], 0) + ISNULL(LBID.[CycleBillingAmount], 0))) < 0.005 THEN 1 ELSE 0 END AS Spl) OV
				WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsDeleted],0) = 0 AND ISNULL(BII.[IsVersionIncrease],0) = 0
				  AND LBID.[LineType] = 'Flat Rate' AND LSL.[BillingMethod] = 'UsageBased' AND ISNULL(LBID.[CycleBillingAmount],0) <> 0

				UNION ALL

				SELECT
					BII.[BillingInvoicingItemId], BII.[BillingInvoicingId], LSL.[LeaseStocklineId] AS SubReferenceId, BII.[ItemMasterId],
					UPPER(ISNULL(LSL.[PN], '')) AS PNumber,
					UPPER(ISNULL(LSL.[PNDescription], '')) AS PNDescription,
					UPPER(COALESCE(BII.[SerialNumber], STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber,
					UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
					UPPER(COALESCE(IM.[ConsumeUnitOfMeasure], IM.[StockUnitOfMeasure], '')) AS UOM,
					'Overrun - Time' AS LineBillingMethod,
					CAST(QX.Q AS DECIMAL(18,6)) AS LineQty,
					CAST(COALESCE(NULLIF(LBID.[TimeOverageRate], 0), LBID.[TimeBillingAmount] / NULLIF(LBID.[TimeOver] * QX.Q, 0)) AS DECIMAL(18,6)) AS LineUnitPrice,
					ISNULL(LBID.[TimeBillingAmount], 0) AS LineTotal,
					3 AS SortOrder,
					LBID.[FromDate] AS SortDate,
					CAST(CAST(CAST(ROUND(LBID.[TimeOver] * 60, 0) AS INT) / 60 AS VARCHAR(10)) + ':' + RIGHT('0' + CAST(CAST(ROUND(LBID.[TimeOver] * 60, 0) AS INT) % 60 AS VARCHAR(2)), 2) AS VARCHAR(40)) AS LineRecorded,
					CAST(CASE WHEN LBID.[FromDate] IS NOT NULL AND LBID.[ToDate] IS NOT NULL THEN CONVERT(VARCHAR(8), LBID.[FromDate], 1) + ' - ' + CONVERT(VARCHAR(8), LBID.[ToDate], 1) ELSE '' END AS VARCHAR(25)) AS LinePeriod
				FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
				INNER JOIN [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH(NOLOCK) ON LBID.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId]
					AND ISNULL(LBID.[IsDeleted],0) = 0 AND ISNULL(LBID.[IsVersionIncrease],0) = 0 AND LBID.[LineType] IS NOT NULL
					AND NOT (LBID.[LineType] = 'Overrun' AND ISNULL(LBID.[LineAmount],0) = 0)
				INNER JOIN [dbo].[LeaseStockline] LSL WITH(NOLOCK) ON BII.[SubReferenceId] = LSL.[LeaseStocklineId]
				LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON BII.[StocklineId] = STK.[StockLineId]
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON BII.[ItemMasterId] = IM.[ItemMasterId]
				CROSS APPLY (SELECT CASE WHEN LBID.[LineType] IN ('Flat Rate', 'Overrun') AND ISNULL(LSL.[QtyReserved], 0) > 0 THEN LSL.[QtyReserved] ELSE 1 END AS Q) QX
				CROSS APPLY (SELECT CASE WHEN LBID.[LineType] = 'Overrun' AND (ISNULL(LBID.[TimeBillingAmount], 0) <> 0 OR ISNULL(LBID.[CycleBillingAmount], 0) <> 0)
						AND ABS(ISNULL(LBID.[LineAmount], 0) - (ISNULL(LBID.[TimeBillingAmount], 0) + ISNULL(LBID.[CycleBillingAmount], 0))) < 0.005 THEN 1 ELSE 0 END AS Spl) OV
				WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsDeleted],0) = 0 AND ISNULL(BII.[IsVersionIncrease],0) = 0
				  AND LBID.[LineType] = 'Overrun' AND OV.Spl = 1 AND ISNULL(LBID.[TimeBillingAmount],0) <> 0

				UNION ALL

				SELECT
					BII.[BillingInvoicingItemId], BII.[BillingInvoicingId], LSL.[LeaseStocklineId] AS SubReferenceId, BII.[ItemMasterId],
					UPPER(ISNULL(LSL.[PN], '')) AS PNumber,
					UPPER(ISNULL(LSL.[PNDescription], '')) AS PNDescription,
					UPPER(COALESCE(BII.[SerialNumber], STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber,
					UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
					UPPER(COALESCE(IM.[ConsumeUnitOfMeasure], IM.[StockUnitOfMeasure], '')) AS UOM,
					'Overrun - Cycle' AS LineBillingMethod,
					CAST(QX.Q AS DECIMAL(18,6)) AS LineQty,
					CAST(COALESCE(NULLIF(LBID.[CycleOverageRate], 0), LBID.[CycleBillingAmount] / NULLIF(LBID.[CycleOver] * QX.Q, 0)) AS DECIMAL(18,6)) AS LineUnitPrice,
					ISNULL(LBID.[CycleBillingAmount], 0) AS LineTotal,
					4 AS SortOrder,
					LBID.[FromDate] AS SortDate,
					CAST(CAST(CAST(ROUND(LBID.[CycleOver], 0) AS INT) AS VARCHAR(20)) AS VARCHAR(40)) AS LineRecorded,
					CAST(CASE WHEN LBID.[FromDate] IS NOT NULL AND LBID.[ToDate] IS NOT NULL THEN CONVERT(VARCHAR(8), LBID.[FromDate], 1) + ' - ' + CONVERT(VARCHAR(8), LBID.[ToDate], 1) ELSE '' END AS VARCHAR(25)) AS LinePeriod
				FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
				INNER JOIN [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH(NOLOCK) ON LBID.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId]
					AND ISNULL(LBID.[IsDeleted],0) = 0 AND ISNULL(LBID.[IsVersionIncrease],0) = 0 AND LBID.[LineType] IS NOT NULL
					AND NOT (LBID.[LineType] = 'Overrun' AND ISNULL(LBID.[LineAmount],0) = 0)
				INNER JOIN [dbo].[LeaseStockline] LSL WITH(NOLOCK) ON BII.[SubReferenceId] = LSL.[LeaseStocklineId]
				LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON BII.[StocklineId] = STK.[StockLineId]
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON BII.[ItemMasterId] = IM.[ItemMasterId]
				CROSS APPLY (SELECT CASE WHEN LBID.[LineType] IN ('Flat Rate', 'Overrun') AND ISNULL(LSL.[QtyReserved], 0) > 0 THEN LSL.[QtyReserved] ELSE 1 END AS Q) QX
				CROSS APPLY (SELECT CASE WHEN LBID.[LineType] = 'Overrun' AND (ISNULL(LBID.[TimeBillingAmount], 0) <> 0 OR ISNULL(LBID.[CycleBillingAmount], 0) <> 0)
						AND ABS(ISNULL(LBID.[LineAmount], 0) - (ISNULL(LBID.[TimeBillingAmount], 0) + ISNULL(LBID.[CycleBillingAmount], 0))) < 0.005 THEN 1 ELSE 0 END AS Spl) OV
				WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsDeleted],0) = 0 AND ISNULL(BII.[IsVersionIncrease],0) = 0
				  AND LBID.[LineType] = 'Overrun' AND OV.Spl = 1 AND ISNULL(LBID.[CycleBillingAmount],0) <> 0
			),
			AllLines AS (
				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					LineBillingMethod, LineQty, LineUnitPrice, LineTotal, SortOrder, CAST(NULL AS DATETIME2(7)) AS SortDate, CAST('' AS VARCHAR(40)) AS LineRecorded, CAST('' AS VARCHAR(25)) AS LinePeriod
				FROM Lines
				UNION ALL
				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					LineBillingMethod, LineQty, LineUnitPrice, LineTotal, SortOrder, SortDate, LineRecorded, LinePeriod
				FROM TypedLines
			)
			SELECT
				ROW_NUMBER() OVER (ORDER BY SubReferenceId, SortOrder, SortDate, BillingInvoicingItemId) AS ItemNo,
				BillingInvoicingItemId,
				BillingInvoicingId,
				SubReferenceId,
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
				DENSE_RANK() OVER (ORDER BY SubReferenceId) AS PnLineNo
			FROM AllLines
			ORDER BY SubReferenceId, SortOrder, SortDate, BillingInvoicingItemId;
		END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCommonBillingInvoicingItems_Lease' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))
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