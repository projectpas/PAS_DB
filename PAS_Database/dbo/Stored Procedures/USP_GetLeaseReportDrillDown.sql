/*************************************************************
 ** File:   [USP_GetLeaseReportDrillDown]
 ** Description: Lease -> Reports tab (Summary view): drill down of one leased part.
 **              @DrillType = 'Revenue' : the invoices of the part inside the date range
 **                           (InvoiceDate, BillingInvoicingId, InvoiceNo, BaseAmount, TimeOverage, CycleOverage, Maintenance, Insurance, Taxes, TotalRevenue)
 **              @DrillType = 'Expense' : the cost activities that make the Expenses of the Summary row (same rules as USP_GetLeaseReportByLeaseHeaderId)
 **                           PO Cost, RO Cost and every service component (Description, StartDate, EndDate, ComponentAmount, Amount counted in the date range)
 ** PARAMETERS: @LeaseHeaderId BIGINT, @LeaseStocklineId BIGINT, @DrillType VARCHAR(20), @FromDate DATE (NULL = first lease part start date), @ToDate DATE (NULL = today)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    27/10/2026     Kishor Makwana          [Lease Reports] Created

EXEC USP_GetLeaseReportDrillDown @LeaseHeaderId = 22, @LeaseStocklineId = 52, @DrillType = 'Revenue'
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
				   CAST(SUM(CASE WHEN D.[LineType] IN ('Flat Rate', 'Charges', 'Others') THEN ISNULL(D.[LineAmount], 0) ELSE 0 END) AS DECIMAL(18, 2)) AS BaseAmount,
				   CAST(SUM(CASE WHEN D.[LineType] = 'Overrun' THEN ISNULL(D.[TimeBillingAmount], 0) ELSE 0 END) AS DECIMAL(18, 2)) AS TimeOverage,
				   CAST(SUM(CASE WHEN D.[LineType] = 'Overrun' THEN ISNULL(D.[CycleBillingAmount], 0) ELSE 0 END) AS DECIMAL(18, 2)) AS CycleOverage,
				   CAST(SUM(CASE WHEN D.[LineType] = 'Maintenance' THEN ISNULL(D.[LineAmount], 0) ELSE 0 END) AS DECIMAL(18, 2)) AS Maintenance,
				   CAST(SUM(CASE WHEN D.[LineType] = 'Insurance' THEN ISNULL(D.[LineAmount], 0) ELSE 0 END) AS DECIMAL(18, 2)) AS Insurance,
				   CAST(SUM(CASE WHEN D.[LineType] = 'Taxes' THEN ISNULL(D.[LineAmount], 0) ELSE 0 END) AS DECIMAL(18, 2)) AS Taxes,
				   CAST(SUM(CASE WHEN D.[LineType] IN ('Flat Rate', 'Charges', 'Others', 'Maintenance', 'Insurance', 'Taxes') THEN ISNULL(D.[LineAmount], 0)
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
			DECLARE @FromMonth DATE = DATEFROMPARTS(YEAR(@FromDate), MONTH(@FromDate), 1);

			-- service components : month split (full month = 1, part month = days / 30, the last month takes the rounding remainder) - same as the Summary row
			;WITH Nums AS (
				SELECT TOP (1200) CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS INT) AS n FROM sys.all_columns
			),
			ComponentSlicesBase AS (
				SELECT SC.[LeaseStocklineServiceComponentId] AS ComponentId, M.MonthStart, ISNULL(SC.[Amount], 0) AS Amount,
					CASE WHEN SL.SliceFrom = M.MonthStart AND SL.SliceTo = EOMONTH(M.MonthStart) THEN CAST(1 AS DECIMAL(18,6))
						ELSE CAST(DATEDIFF(DAY, SL.SliceFrom, SL.SliceTo) + 1 AS DECIMAL(18,6)) / 30.0 END AS Weight
				FROM [dbo].[LeaseStocklineServiceComponent] SC WITH (NOLOCK)
				INNER JOIN Nums N ON N.n <= DATEDIFF(MONTH, SC.[StartDate], SC.[EndDate])
				CROSS APPLY (SELECT DATEADD(MONTH, N.n, DATEFROMPARTS(YEAR(SC.[StartDate]), MONTH(SC.[StartDate]), 1)) AS MonthStart) M
				CROSS APPLY (SELECT
						CASE WHEN CAST(SC.[StartDate] AS DATE) > M.MonthStart THEN CAST(SC.[StartDate] AS DATE) ELSE M.MonthStart END AS SliceFrom,
						CASE WHEN CAST(SC.[EndDate] AS DATE) < EOMONTH(M.MonthStart) THEN CAST(SC.[EndDate] AS DATE) ELSE EOMONTH(M.MonthStart) END AS SliceTo) SL
				WHERE SC.[LeaseStocklineId] = @LeaseStocklineId AND SC.[IsDeleted] = 0 AND SC.[StartDate] IS NOT NULL AND SC.[EndDate] IS NOT NULL
				  AND SC.[EndDate] >= SC.[StartDate] AND ISNULL(SC.[Amount], 0) <> 0
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
			),
			ComponentInRange AS (
				SELECT ComponentId, SUM(SliceAmount) AS Amt
				FROM ComponentSlices
				WHERE MonthStart >= @FromMonth AND MonthStart <= @ToDate
				GROUP BY ComponentId
			)
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
				SELECT SC.[ComponentName], CAST(SC.[StartDate] AS DATE), CAST(SC.[EndDate] AS DATE),
					   ISNULL(SC.[Amount], 0),
					   -- components without a valid date range are counted once in full, the others only for the months inside the date range
					   CASE WHEN SC.[StartDate] IS NULL OR SC.[EndDate] IS NULL OR SC.[EndDate] < SC.[StartDate] THEN ISNULL(SC.[Amount], 0)
							ELSE ISNULL(CR.Amt, 0) END,
					   3, SC.[LeaseStocklineServiceComponentId]
				FROM [dbo].[LeaseStocklineServiceComponent] SC WITH (NOLOCK)
				LEFT JOIN ComponentInRange CR ON CR.ComponentId = SC.[LeaseStocklineServiceComponentId]
				WHERE SC.[LeaseStocklineId] = @LeaseStocklineId AND SC.[IsDeleted] = 0
			) T
			ORDER BY T.SortOrder, T.[Description], T.SortId;
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