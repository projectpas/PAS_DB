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
				G.TimeBillingAmount, G.CycleBillingAmount, G.TimeRecorded, G.CycleRecorded,
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
		Lines AS (
			-- every line except a Usage Based period line (that one is split into Usage Time / Usage Cycle below)
			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				CASE LineType WHEN 'Others' THEN 'Other' ELSE LineType END AS LineBillingMethod,
				CAST(Q AS DECIMAL(18,6)) AS LineQty,
				CAST(Total / Q AS DECIMAL(18,6)) AS LineUnitPrice,
				Total AS LineTotal,
				CASE LineType WHEN 'Flat Rate' THEN 1 WHEN 'Overrun' THEN 3 WHEN 'Maintenance' THEN 6 WHEN 'Insurance' THEN 7
					WHEN 'Taxes' THEN 8 WHEN 'Others' THEN 9 WHEN 'Charges' THEN 10 ELSE 11 END AS SortOrder,
				FromDate AS SortDate
			FROM Src
			WHERE NOT (LineType = 'Flat Rate' AND BillingMethod = 'UsageBased')

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Usage Time',
				CAST(H.Hours AS DECIMAL(18,6)),
				CAST(TimeBillingAmount / NULLIF(H.Hours, 0) AS DECIMAL(18,6)),
				TimeBillingAmount, 1, FromDate
			FROM Src
			CROSS APPLY (SELECT COALESCE(TimeBillingAmount / NULLIF(TimeRate * LQty, 0), TimeRecorded / 60.0, 1) AS Hours) H
			WHERE LineType = 'Flat Rate' AND BillingMethod = 'UsageBased' AND ISNULL(TimeBillingAmount, 0) <> 0

			UNION ALL

			SELECT LeaseStocklineId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
				'Usage Cycle',
				CAST(H.Cycles AS DECIMAL(18,6)),
				CAST(CycleBillingAmount / NULLIF(H.Cycles, 0) AS DECIMAL(18,6)),
				CycleBillingAmount, 2, FromDate
			FROM Src
			CROSS APPLY (SELECT COALESCE(CycleBillingAmount / NULLIF(CycleRate * LQty, 0), CycleRecorded, 1) AS Cycles) H
			WHERE LineType = 'Flat Rate' AND BillingMethod = 'UsageBased' AND ISNULL(CycleBillingAmount, 0) <> 0
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
				LineQty AS Qty,
				LineUnitPrice AS UnitPrice,
				LineTotal AS Total
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