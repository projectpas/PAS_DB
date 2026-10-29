/*************************************************************
 ** File:   [USP_GetLeaseReportDrillDown]
 ** Description: Lease -> Reports tab (Summary view): drill down of one leased part.
 **              @DrillType = 'Revenue' : the invoices of the part inside the date range
 **                           (InvoiceDate, BillingInvoicingId, InvoiceNo, BaseAmount (Flat Rate), TimeOverage, CycleOverage, TotalRevenue = Flat Rate + Overrun; the other line types are costs)
 **              @DrillType = 'Expense' : the cost activities that make the Expenses of the Summary row (same rules as USP_GetLeaseReportByLeaseHeaderId)
 **                           PO Cost, RO Cost and the billed Maintenance / Insurance / Taxes / Others / Charges invoice lines of the date range (Description, StartDate, EndDate, ComponentAmount, Amount)
 **              @DrillType = 'Capitalized' : the costs that make the Capitalized Cost of the Summary row (Description, Quantity, Amount): PO Cost and RO Cost of the stockline
 ** PARAMETERS: @LeaseHeaderId BIGINT, @LeaseStocklineId BIGINT, @DrillType VARCHAR(20), @FromDate DATE (NULL = first lease part start date), @ToDate DATE (NULL = today)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    27/10/2026     Kishor Makwana          [PN-18360] Created
    2    28/10/2026     Kishor Makwana          [PN-18360] Added @DrillType = 'Capitalized'
    3    28/10/2026     Kishor Makwana          [PN-18360] Charges / Others are not revenue: removed from the Revenue drill down, Charges added to the Expense drill down
    4    28/10/2026     Kishor Makwana          [PN-18360] Revenue drill down = Flat Rate + Overrun only (Maintenance / Insurance / Taxes columns removed)
    5    28/10/2026     Kishor Makwana          [PN-18360] Expense drill down: Other Cost rows = billed Maintenance / Insurance / Taxes / Others / Charges invoice lines (no service component split)

EXEC USP_GetLeaseReportDrillDown @LeaseHeaderId = 22, @LeaseStocklineId = 52, @DrillType = 'Revenue'
EXEC USP_GetLeaseReportDrillDown @LeaseHeaderId = 22, @LeaseStocklineId = 52, @DrillType = 'Capitalized'
EXEC USP_GetLeaseReportDrillDown @LeaseHeaderId = 22, @LeaseStocklineId = 52, @DrillType = 'Expense', @FromDate = '2026-01-01', @ToDate = '2026-10-27'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseReportDrillDown]
	@LeaseHeaderId BIGINT,
	@LeaseStocklineId BIGINT,
	@DrillType VARCHAR(20),
	@FromDate DATE = NULL,
	@ToDate DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @LeaseModuleId INT = (SELECT TOP 1 [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Leasing');

		IF (@FromDate IS NULL)
		BEGIN
			SELECT @FromDate = MIN(CAST(LSL.[StartDate] AS DATE))
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId AND LSL.[IsDeleted] = 0;
			IF (@FromDate IS NULL)
				SELECT @FromDate = CAST(LH.[CreatedDate] AS DATE) FROM [dbo].[LeaseHeader] LH WITH (NOLOCK) WHERE LH.[LeaseHeaderId] = @LeaseHeaderId;
		END
		IF (@ToDate IS NULL) SET @ToDate = CAST(GETUTCDATE() AS DATE);

		IF (@DrillType = 'Revenue')
		BEGIN
			-- revenue activities : one row per invoice of the part
			SELECT CAST(BI.[InvoiceDate] AS DATE) AS InvoiceDate, BI.[BillingInvoicingId], BI.[InvoiceNo],
				   CAST(SUM(CASE WHEN D.[LineType] = 'Flat Rate' THEN ISNULL(D.[LineAmount], 0) ELSE 0 END) AS DECIMAL(18, 2)) AS BaseAmount,
				   CAST(SUM(CASE WHEN D.[LineType] = 'Overrun' THEN ISNULL(D.[TimeBillingAmount], 0) ELSE 0 END) AS DECIMAL(18, 2)) AS TimeOverage,
				   CAST(SUM(CASE WHEN D.[LineType] = 'Overrun' THEN ISNULL(D.[CycleBillingAmount], 0) ELSE 0 END) AS DECIMAL(18, 2)) AS CycleOverage,
				   CAST(SUM(CASE WHEN D.[LineType] = 'Flat Rate' THEN ISNULL(D.[LineAmount], 0)
								 WHEN D.[LineType] = 'Overrun' THEN ISNULL(D.[TimeBillingAmount], 0) + ISNULL(D.[CycleBillingAmount], 0)
								 ELSE 0 END) AS DECIMAL(18, 2)) AS TotalRevenue
			FROM [dbo].[LeaseBillingInvoicingItemDetails] D WITH (NOLOCK)
			INNER JOIN [dbo].[BillingInvoicingItems] BX WITH (NOLOCK)
				ON BX.[BillingInvoicingItemId] = D.[BillingInvoicingItemId] AND BX.[IsDeleted] = 0 AND ISNULL(BX.[IsVersionIncrease], 0) = 0
				AND BX.[ModuleId] = @LeaseModuleId AND BX.[ReferenceId] = @LeaseHeaderId
			INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK)
				ON BI.[BillingInvoicingId] = BX.[BillingInvoicingId] AND BI.[IsDeleted] = 0 AND BI.[ModuleId] = @LeaseModuleId
				AND ISNULL(BI.[InvoiceStatus], '') <> 'Voided'
				AND CAST(BI.[InvoiceDate] AS DATE) >= @FromDate AND CAST(BI.[InvoiceDate] AS DATE) <= @ToDate
			WHERE D.[LeaseStocklineId] = @LeaseStocklineId AND ISNULL(D.[IsDeleted], 0) = 0 AND ISNULL(D.[IsVersionIncrease], 0) = 0
			GROUP BY CAST(BI.[InvoiceDate] AS DATE), BI.[BillingInvoicingId], BI.[InvoiceNo]
			ORDER BY CAST(BI.[InvoiceDate] AS DATE), BI.[InvoiceNo];
		END
		ELSE IF (@DrillType = 'Expense')
		BEGIN
			-- PO Cost + RO Cost of the stockline and the billed Maintenance / Insurance / Taxes / Others / Charges lines of the invoices in the date range
			SELECT T.[Description], T.[StartDate], T.[EndDate],
				   CAST(T.[ComponentAmount] AS DECIMAL(18, 2)) AS ComponentAmount,
				   CAST(T.[Amount] AS DECIMAL(18, 2)) AS Amount
			FROM (
				SELECT N'PO Cost' AS [Description], CAST(NULL AS DATE) AS [StartDate], CAST(NULL AS DATE) AS [EndDate],
					   ISNULL(STK.[PurchaseOrderUnitCost], 0) * LSL.[QtyOrder] AS [ComponentAmount], ISNULL(STK.[PurchaseOrderUnitCost], 0) * LSL.[QtyOrder] AS [Amount],
					   1 AS SortOrder, CAST(NULL AS BIGINT) AS SortId
				FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
				LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
				WHERE LSL.[LeaseStocklineId] = @LeaseStocklineId
				UNION ALL
				SELECT N'RO Cost', NULL, NULL,
					   ISNULL(STK.[RepairOrderUnitCost], 0) * LSL.[QtyOrder], ISNULL(STK.[RepairOrderUnitCost], 0) * LSL.[QtyOrder], 2, NULL
				FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
				LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
				WHERE LSL.[LeaseStocklineId] = @LeaseStocklineId
				UNION ALL
				-- billed Maintenance / Insurance / Taxes / Others / Charges lines (one row per invoice line type)
				SELECT CONCAT(D.[LineType], N' - ', BI.[InvoiceNo]), CAST(D.[FromDate] AS DATE), CAST(D.[ToDate] AS DATE),
					   SUM(ISNULL(D.[LineAmount], 0)), SUM(ISNULL(D.[LineAmount], 0)), 3, BI.[BillingInvoicingId]
				FROM [dbo].[LeaseBillingInvoicingItemDetails] D WITH (NOLOCK)
				INNER JOIN [dbo].[BillingInvoicingItems] BX WITH (NOLOCK)
					ON BX.[BillingInvoicingItemId] = D.[BillingInvoicingItemId] AND BX.[IsDeleted] = 0 AND ISNULL(BX.[IsVersionIncrease], 0) = 0
					AND BX.[ModuleId] = @LeaseModuleId AND BX.[ReferenceId] = @LeaseHeaderId
				INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK)
					ON BI.[BillingInvoicingId] = BX.[BillingInvoicingId] AND BI.[IsDeleted] = 0 AND BI.[ModuleId] = @LeaseModuleId
					AND ISNULL(BI.[InvoiceStatus], '') <> 'Voided'
					AND CAST(BI.[InvoiceDate] AS DATE) >= @FromDate AND CAST(BI.[InvoiceDate] AS DATE) <= @ToDate
				WHERE D.[LeaseStocklineId] = @LeaseStocklineId AND ISNULL(D.[IsDeleted], 0) = 0 AND ISNULL(D.[IsVersionIncrease], 0) = 0
				  AND D.[LineType] IN ('Maintenance', 'Insurance', 'Taxes', 'Others', 'Charges')
				GROUP BY D.[LineType], BI.[InvoiceNo], BI.[BillingInvoicingId], CAST(D.[FromDate] AS DATE), CAST(D.[ToDate] AS DATE)
			) T
			ORDER BY T.SortOrder, T.[Description], T.SortId;
		END
		ELSE IF (@DrillType = 'Capitalized')
		BEGIN
			-- Capitalized Cost = PO Cost + RO Cost of the stockline (not affected by the date range)
			SELECT T.[Description], T.[Quantity], CAST(T.[Amount] AS DECIMAL(18, 2)) AS Amount
			FROM (
				SELECT N'PO Cost' AS [Description], CAST(ISNULL(LSL.[QtyOrder], 0) AS DECIMAL(18, 2)) AS [Quantity],
					   ISNULL(STK.[PurchaseOrderUnitCost], 0) * LSL.[QtyOrder] AS [Amount], 1 AS SortOrder
				FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
				LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
				WHERE LSL.[LeaseStocklineId] = @LeaseStocklineId
				UNION ALL
				SELECT N'RO Cost', CAST(ISNULL(LSL.[QtyOrder], 0) AS DECIMAL(18, 2)),
					   ISNULL(STK.[RepairOrderUnitCost], 0) * LSL.[QtyOrder], 2
				FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
				LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
				WHERE LSL.[LeaseStocklineId] = @LeaseStocklineId
			) T
			ORDER BY T.SortOrder;
		END

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseReportDrillDown'
			, @ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100)) + ''', @LeaseStocklineId = ''' + CAST(ISNULL(@LeaseStocklineId, 0) AS VARCHAR(100)) + ''', @DrillType = ''' + ISNULL(@DrillType, '') + ''''
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