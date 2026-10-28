/*************************************************************
 ** File:   [USP_GetLeaseSummaryByLeaseHeaderId]
 ** Description: Lease -> Lease Summary tab: consolidated financial overview of one lease (PO cost, RO cost, other cost, total cost, revenue, profit/loss).
 **
 **              PO Cost     = from the Stockline table only (no PO tables): for each leased stockline Stockline.PurchaseOrderUnitCost x quantity on the lease.
 **              RO Cost     = from the Stockline table only (no RO tables): for each leased stockline Stockline.RepairOrderUnitCost x quantity on the lease.
 **              Other Cost  = Maintenance + Insurance + Taxes + Others of the lease parts' service components (LeaseStocklineServiceComponent), CURRENT MONTH wise
 **                            exactly like the Billing tab (Amount split over StartDate-EndDate calendar months; full month = 1, part month = days/30; only this month's share).
 **              Total Cost  = PO Cost + RO Cost + Other Cost
 **              Revenue     = generated (draft) and posted lease invoices, voided invoices excluded, Taxes lines excluded; each invoice line counted once
 **                            (Line Amount of LeaseBillingInvoicingItemDetails, version-increase rows ignored).
 **              Profit/Loss = Revenue - Total Cost  (positive = profit, negative = loss, 0 = break-even)
 **              Amounts are returned as stored on the PO / RO / lease / invoice (no re-conversion).
 ** PARAMETERS: @LeaseHeaderId BIGINT
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    21/10/2026     Kishor Makwana          [Lease Summary] Created
    2    22/10/2026     Kishor Makwana          [Lease Summary] PO / RO cost are calculated stockline wise (leased stocklines' PO part lines / RO part lines), not per PO / RO id

    3    22/10/2026     Kishor Makwana          [Lease Summary] Other Cost now from LeaseStocklineServiceComponent (Maintenance, Insurance, Taxes, Others), current month wise like Billing

    4    27/10/2026     Kishor Makwana          [Lease Summary] PO Cost / RO Cost now come from the Stockline table (PurchaseOrderUnitCost / RepairOrderUnitCost x lease qty), no PurchaseOrderPart / RepairOrderPart / RepairOrder joins

EXEC USP_GetLeaseSummaryByLeaseHeaderId @LeaseHeaderId = 22
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseSummaryByLeaseHeaderId]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @LeaseModuleId INT = (SELECT TOP 1 [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Leasing');
		DECLARE @PoCost DECIMAL(18, 6) = 0, @RoCost DECIMAL(18, 6) = 0, @OtherCost DECIMAL(18, 6) = 0, @Revenue DECIMAL(18, 6) = 0;

		-- PO Cost / RO Cost: taken from the Stockline table only (no PO / RO table joins) - for every leased stockline
		-- Stockline.PurchaseOrderUnitCost / Stockline.RepairOrderUnitCost x quantity on the lease
		SELECT @PoCost = ISNULL(SUM(ISNULL(STK.[PurchaseOrderUnitCost], 0) * LSL.[QtyOrder]), 0),
			   @RoCost = ISNULL(SUM(ISNULL(STK.[RepairOrderUnitCost], 0) * LSL.[QtyOrder]), 0)
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
		WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId AND LSL.[IsDeleted] = 0;

		-- Other Cost: Maintenance + Insurance + Taxes + Others from the lease parts' service components (LeaseStocklineServiceComponent),
		-- calculated CURRENT MONTH wise exactly like the Billing tab: the component Amount is the total for StartDate-EndDate, split over the calendar months
		-- (full month = 1, part month = days / 30, last month takes the rounding remainder) and only the current calendar month's share is counted.
		-- Components without Start / End date are counted once in full (one-time, same as billing).
		;WITH LeasedStocklines AS (
			SELECT DISTINCT LSL.[LeaseStocklineId] FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId AND LSL.[IsDeleted] = 0
		),
		Nums AS (
			SELECT TOP (1200) CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS INT) AS n FROM sys.all_columns
		),
		ComponentSlicesBase AS (
			SELECT SC.[LeaseStocklineServiceComponentId] AS ComponentId, M.MonthStart, ISNULL(SC.[Amount], 0) AS Amount,
				CASE WHEN SL.SliceFrom = M.MonthStart AND SL.SliceTo = EOMONTH(M.MonthStart) THEN CAST(1 AS DECIMAL(18,6))
					ELSE CAST(DATEDIFF(DAY, SL.SliceFrom, SL.SliceTo) + 1 AS DECIMAL(18,6)) / 30.0 END AS Weight
			FROM [dbo].[LeaseStocklineServiceComponent] SC WITH (NOLOCK)
			INNER JOIN LeasedStocklines LS ON LS.[LeaseStocklineId] = SC.[LeaseStocklineId]
			INNER JOIN Nums N ON N.n <= DATEDIFF(MONTH, SC.[StartDate], SC.[EndDate])
			CROSS APPLY (SELECT DATEADD(MONTH, N.n, DATEFROMPARTS(YEAR(SC.[StartDate]), MONTH(SC.[StartDate]), 1)) AS MonthStart) M
			CROSS APPLY (SELECT
					CASE WHEN CAST(SC.[StartDate] AS DATE) > M.MonthStart THEN CAST(SC.[StartDate] AS DATE) ELSE M.MonthStart END AS SliceFrom,
					CASE WHEN CAST(SC.[EndDate] AS DATE) < EOMONTH(M.MonthStart) THEN CAST(SC.[EndDate] AS DATE) ELSE EOMONTH(M.MonthStart) END AS SliceTo) SL
			WHERE SC.[IsDeleted] = 0 AND SC.[StartDate] IS NOT NULL AND SC.[EndDate] IS NOT NULL AND SC.[EndDate] >= SC.[StartDate] AND ISNULL(SC.[Amount], 0) <> 0
		),
		ComponentSlicesRounded AS (
			SELECT ComponentId, MonthStart, Amount,
				ROUND(Amount * Weight / NULLIF(SUM(Weight) OVER (PARTITION BY ComponentId), 0), 2) AS ShareRounded
			FROM ComponentSlicesBase
		),
		ComponentSlices AS (
			SELECT ComponentId, MonthStart,
				CASE WHEN MonthStart = MAX(MonthStart) OVER (PARTITION BY ComponentId)
					THEN Amount - (SUM(ShareRounded) OVER (PARTITION BY ComponentId) - ShareRounded)
					ELSE ShareRounded END AS SliceAmount
			FROM ComponentSlicesRounded
		)
		SELECT @OtherCost =
			ISNULL((SELECT SUM(CS.SliceAmount) FROM ComponentSlices CS
					WHERE CS.MonthStart = DATEFROMPARTS(YEAR(GETUTCDATE()), MONTH(GETUTCDATE()), 1)), 0)
			+ ISNULL((SELECT SUM(ISNULL(SC.[Amount], 0)) FROM [dbo].[LeaseStocklineServiceComponent] SC WITH (NOLOCK)
					  INNER JOIN LeasedStocklines LS ON LS.[LeaseStocklineId] = SC.[LeaseStocklineId]
					  WHERE SC.[IsDeleted] = 0 AND (SC.[StartDate] IS NULL OR SC.[EndDate] IS NULL OR SC.[EndDate] < SC.[StartDate])), 0);

		-- Revenue: generated (draft) + posted invoices, not voided; each invoice line once; Taxes lines are not revenue
		SELECT @Revenue = ISNULL(SUM(ISNULL(D.[LineAmount], 0)), 0)
		FROM [dbo].[LeaseBillingInvoicingItemDetails] D WITH (NOLOCK)
		INNER JOIN [dbo].[BillingInvoicingItems] BX WITH (NOLOCK)
			ON BX.[BillingInvoicingItemId] = D.[BillingInvoicingItemId] AND BX.[IsDeleted] = 0 AND ISNULL(BX.[IsVersionIncrease], 0) = 0
			AND BX.[ModuleId] = @LeaseModuleId AND BX.[ReferenceId] = @LeaseHeaderId
		INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK)
			ON BI.[BillingInvoicingId] = BX.[BillingInvoicingId] AND BI.[IsDeleted] = 0 AND BI.[ModuleId] = @LeaseModuleId
			AND ISNULL(BI.[InvoiceStatus], '') <> 'Voided'
		WHERE ISNULL(D.[IsDeleted], 0) = 0 AND ISNULL(D.[IsVersionIncrease], 0) = 0 AND ISNULL(D.[LineType], '') <> 'Taxes';

		SELECT CAST(@PoCost AS DECIMAL(18, 2)) AS PoCost,
			   CAST(@RoCost AS DECIMAL(18, 2)) AS RoCost,
			   CAST(@OtherCost AS DECIMAL(18, 2)) AS OtherCost,
			   CAST(@PoCost + @RoCost + @OtherCost AS DECIMAL(18, 2)) AS TotalCost,
			   CAST(@Revenue AS DECIMAL(18, 2)) AS Revenue,
			   CAST(@Revenue - (@PoCost + @RoCost + @OtherCost) AS DECIMAL(18, 2)) AS ProfitLoss;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseSummaryByLeaseHeaderId'
			, @ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			@DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END