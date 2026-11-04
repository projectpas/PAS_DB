/*************************************************************
 ** File:   [USP_GetLeaseSummaryByLeaseHeaderId]
 ** Description: Lease -> Lease Summary tab: consolidated financial overview of one lease (PO cost, RO cost, other cost, total cost, revenue, profit/loss).
 **
 **              PO Cost     = from the Stockline table only (no PO tables): for each leased stockline Stockline.PurchaseOrderUnitCost x quantity on the lease.
 **              RO Cost     = from the Stockline table only (no RO tables): for each leased stockline Stockline.RepairOrderUnitCost x quantity on the lease.
 **              Other Cost  = the billed Maintenance + Insurance + Taxes + Others + Charges lines of the lease invoices (generated draft + posted, voided excluded),
 **                            the same lines as the Billing tab, so Revenue + Other Cost = Total Billing of the Billing tab.
 **              Total Cost  = PO Cost + RO Cost + Other Cost
 **              Revenue     = generated (draft) and posted lease invoices, voided invoices excluded, Flat Rate + Overrun lines only (Maintenance / Insurance / Taxes / Charges / Others are costs); each invoice line counted once
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

    5    28/10/2026     Kishor Makwana          [PN-18360] Charges invoice lines are added to Other Cost; Charges / Others lines are no longer part of Revenue
    6    28/10/2026     Kishor Makwana          [PN-18360] Revenue = Flat Rate + Overrun lines only (same as the Billing tab)
    7    28/10/2026     Kishor Makwana          [PN-18360] Other Cost = billed Maintenance / Insurance / Taxes / Others / Charges invoice lines (same lines as the Billing tab), no service component month split

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

		-- Other Cost: billed Maintenance + Insurance + Taxes + Others + Charges lines of the lease invoices (the same lines as the Billing tab):
		-- generated (draft) + posted invoices, not voided; each invoice line once
		SELECT @OtherCost = ISNULL(SUM(ISNULL(D.[LineAmount], 0)), 0)
		FROM [dbo].[LeaseBillingInvoicingItemDetails] D WITH (NOLOCK)
		INNER JOIN [dbo].[BillingInvoicingItems] BX WITH (NOLOCK)
			ON BX.[BillingInvoicingItemId] = D.[BillingInvoicingItemId] AND BX.[IsDeleted] = 0 AND ISNULL(BX.[IsVersionIncrease], 0) = 0
			AND BX.[ModuleId] = @LeaseModuleId AND BX.[ReferenceId] = @LeaseHeaderId
		INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK)
			ON BI.[BillingInvoicingId] = BX.[BillingInvoicingId] AND BI.[IsDeleted] = 0 AND BI.[ModuleId] = @LeaseModuleId
			AND ISNULL(BI.[InvoiceStatus], '') <> 'Voided'
		WHERE ISNULL(D.[IsDeleted], 0) = 0 AND ISNULL(D.[IsVersionIncrease], 0) = 0 AND D.[LineType] IN ('Maintenance', 'Insurance', 'Taxes', 'Others', 'Charges');

		-- Revenue: generated (draft) + posted invoices, not voided; each invoice line once; only Flat Rate + Overrun lines are revenue
		SELECT @Revenue = ISNULL(SUM(ISNULL(D.[LineAmount], 0)), 0)
		FROM [dbo].[LeaseBillingInvoicingItemDetails] D WITH (NOLOCK)
		INNER JOIN [dbo].[BillingInvoicingItems] BX WITH (NOLOCK)
			ON BX.[BillingInvoicingItemId] = D.[BillingInvoicingItemId] AND BX.[IsDeleted] = 0 AND ISNULL(BX.[IsVersionIncrease], 0) = 0
			AND BX.[ModuleId] = @LeaseModuleId AND BX.[ReferenceId] = @LeaseHeaderId
		INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK)
			ON BI.[BillingInvoicingId] = BX.[BillingInvoicingId] AND BI.[IsDeleted] = 0 AND BI.[ModuleId] = @LeaseModuleId
			AND ISNULL(BI.[InvoiceStatus], '') <> 'Voided'
		WHERE ISNULL(D.[IsDeleted], 0) = 0 AND ISNULL(D.[IsVersionIncrease], 0) = 0 AND D.[LineType] IN ('Flat Rate', 'Overrun');

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