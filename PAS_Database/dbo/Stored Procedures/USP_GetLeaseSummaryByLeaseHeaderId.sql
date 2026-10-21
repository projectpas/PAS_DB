/*************************************************************
 ** File:   [USP_GetLeaseSummaryByLeaseHeaderId]
 ** Description: Lease -> Lease Summary tab: consolidated financial overview of one lease (PO cost, RO cost, other cost, total cost, revenue, profit/loss).
 **
 **              PO Cost     = PO amount of the Purchase Orders the leased stocklines came from (LeaseStockline -> Stockline.PurchaseOrderId):
 **                            PO part lines (parent/standalone lines, Extended Cost) + PO Freight (Amount) + PO Charges (Extended Cost). Each PO is counted ONCE
 **                            even when several leased stocklines came from it.
 **              RO Cost     = actual repair cost of the Repair Orders selected on the lease part lines (LeaseStockline.RepairOrderId):
 **                            RO part lines (Extended Cost) + RO Freight (Amount) + RO Charges (Extended Cost). Each RO is counted ONCE.
 **              Other Cost  = configured Maintenance + Insurance + Taxes amounts of the active (not deleted) lease part lines.
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

		-- PO Cost: each Purchase Order once (DISTINCT), part lines + freight + charges
		;WITH LeasePO AS (
			SELECT DISTINCT STK.[PurchaseOrderId]
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
			INNER JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON PO.[PurchaseOrderId] = STK.[PurchaseOrderId] AND ISNULL(PO.[IsDeleted], 0) = 0
			WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId AND LSL.[IsDeleted] = 0 AND STK.[PurchaseOrderId] IS NOT NULL
		)
		SELECT @PoCost =
			  ISNULL((SELECT SUM(ISNULL(POP.[ExtendedCost], 0)) FROM [dbo].[PurchaseOrderPart] POP WITH (NOLOCK)
					  WHERE POP.[PurchaseOrderId] IN (SELECT [PurchaseOrderId] FROM LeasePO) AND ISNULL(POP.[IsDeleted], 0) = 0 AND POP.[ParentId] IS NULL), 0)
			+ ISNULL((SELECT SUM(ISNULL(POF.[Amount], 0)) FROM [dbo].[PurchaseOrderFreight] POF WITH (NOLOCK)
					  WHERE POF.[PurchaseOrderId] IN (SELECT [PurchaseOrderId] FROM LeasePO) AND ISNULL(POF.[IsDeleted], 0) = 0), 0)
			+ ISNULL((SELECT SUM(ISNULL(POC.[ExtendedCost], 0)) FROM [dbo].[PurchaseOrderCharges] POC WITH (NOLOCK)
					  WHERE POC.[PurchaseOrderId] IN (SELECT [PurchaseOrderId] FROM LeasePO) AND ISNULL(POC.[IsDeleted], 0) = 0), 0);

		-- RO Cost: each Repair Order once (DISTINCT), part lines + freight + charges
		;WITH LeaseRO AS (
			SELECT DISTINCT LSL.[RepairOrderId]
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			INNER JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON RO.[RepairOrderId] = LSL.[RepairOrderId] AND ISNULL(RO.[IsDeleted], 0) = 0
			WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId AND LSL.[IsDeleted] = 0 AND LSL.[RepairOrderId] IS NOT NULL
		)
		SELECT @RoCost =
			  ISNULL((SELECT SUM(ISNULL(ROP.[ExtendedCost], 0)) FROM [dbo].[RepairOrderPart] ROP WITH (NOLOCK)
					  WHERE ROP.[RepairOrderId] IN (SELECT [RepairOrderId] FROM LeaseRO) AND ISNULL(ROP.[IsDeleted], 0) = 0 AND ROP.[ParentId] IS NULL), 0)
			+ ISNULL((SELECT SUM(ISNULL(ROF.[Amount], 0)) FROM [dbo].[RepairOrderFreight] ROF WITH (NOLOCK)
					  WHERE ROF.[RepairOrderId] IN (SELECT [RepairOrderId] FROM LeaseRO) AND ISNULL(ROF.[IsDeleted], 0) = 0), 0)
			+ ISNULL((SELECT SUM(ISNULL(ROC.[ExtendedCost], 0)) FROM [dbo].[RepairOrderCharges] ROC WITH (NOLOCK)
					  WHERE ROC.[RepairOrderId] IN (SELECT [RepairOrderId] FROM LeaseRO) AND ISNULL(ROC.[IsDeleted], 0) = 0), 0);

		-- Other Cost: configured Maintenance + Insurance + Taxes of the lease part lines
		SELECT @OtherCost = ISNULL(SUM(ISNULL(LSL.[Maintenance], 0) + ISNULL(LSL.[Insurance], 0) + ISNULL(LSL.[Taxes], 0)), 0)
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId AND LSL.[IsDeleted] = 0 AND ISNULL(LSL.[IsActive], 1) = 1;

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