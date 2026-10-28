/*************************************************************
 ** File:   [USP_GetLeaseReportByLeaseHeaderId]
 ** Description: Lease -> Reports tab: revenue and cost report of one lease for an invoice date range.
 **
 **              @ViewType = 'Summary' : one row per leased stockline (PN) that has invoice lines in the range, all amounts totaled:
 **                          PN, PN Description, Serial Num, Status, Revenue, Expenses, Margin, Margin %, Capitalized Cost, Start Date, End Date,
 **                          SL Num, Lease Type, TSN, CSN, TSO, CSO
 **              @ViewType = 'PN'      : one row per invoice for each PN:
 **                          PN, PN Description, Invoice Date, Inv Num, Base Amount, Time Overage, Cycle Overage, Maintenance, Insurance, Taxes,
 **                          Total Revenue, Depreciation, Overhaul Cost
 **
 **              Invoice lines  = LeaseBillingInvoicingItemDetails of the lease invoices (generated draft + posted, voided excluded, version-increase rows ignored)
 **                               whose invoice date is between @FromDate and @ToDate.
 **              Base Amount    = LineType 'Flat Rate' (flat rate + billed time / cycle usage), 'Charges' and 'Others'
 **              Time Overage   = LineType 'Overrun' TimeBillingAmount;  Cycle Overage = LineType 'Overrun' CycleBillingAmount
 **              Maintenance / Insurance / Taxes = lines of that LineType
 **              Total Revenue  = Base + Time Overage + Cycle Overage + Maintenance + Insurance + Taxes (Depreciation / Overhaul are cost columns, not in Total Revenue)
 **              Depreciation / Overhaul Cost / Capitalized Cost = 0.00 for now (source not defined yet)
 **              Expenses       = PO Cost + RO Cost + Other Cost of the stockline (same rules as Lease Summary tab):
 **                               PO Cost = Stockline.PurchaseOrderUnitCost x lease qty, RO Cost = Stockline.RepairOrderUnitCost x lease qty,
 **                               Other Cost = Maintenance / Insurance / Taxes / Others service components (LeaseStocklineServiceComponent) split over calendar months,
 **                               only the months inside the selected date range (components without dates are counted once in full)
 **              Margin = Revenue - Expenses ; Margin % = Margin / Revenue x 100 (0 when Revenue is 0)
 **              TSN / CSN = Stockline.TotalTSN : TotalTSNMM / TotalCSN ; TSO / CSO = latest StocklineTimeCycleHistory row of the stockline
 ** PARAMETERS: @LeaseHeaderId BIGINT, @FromDate DATE (NULL = first lease part start date), @ToDate DATE (NULL = today),
 **             @ViewType VARCHAR(20) ('Summary' / 'PN'), @PartNumber NVARCHAR(100) (NULL / '' = all PNs)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    27/10/2026     Kishor Makwana          [Lease Reports] Created

EXEC USP_GetLeaseReportByLeaseHeaderId @LeaseHeaderId = 22, @ViewType = 'Summary'
EXEC USP_GetLeaseReportByLeaseHeaderId @LeaseHeaderId = 22, @ViewType = 'PN', @FromDate = '2026-01-01', @ToDate = '2026-10-27', @PartNumber = NULL
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseReportByLeaseHeaderId]
	@LeaseHeaderId BIGINT,
	@FromDate DATE = NULL,
	@ToDate DATE = NULL,
	@ViewType VARCHAR(20) = 'Summary',
	@PartNumber NVARCHAR(100) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @LeaseModuleId INT = (SELECT TOP 1 [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Leasing');
		SET @PartNumber = NULLIF(LTRIM(RTRIM(ISNULL(@PartNumber, N''))), N'');

		IF (@FromDate IS NULL)
		BEGIN
			SELECT @FromDate = MIN(CAST(LSL.[StartDate] AS DATE))
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			WHERE LSL.[LeaseHeaderId] = @LeaseHeaderId AND LSL.[IsDeleted] = 0;
			IF (@FromDate IS NULL)
				SELECT @FromDate = CAST(LH.[CreatedDate] AS DATE) FROM [dbo].[LeaseHeader] LH WITH (NOLOCK) WHERE LH.[LeaseHeaderId] = @LeaseHeaderId;
		END
		IF (@ToDate IS NULL) SET @ToDate = CAST(GETUTCDATE() AS DATE);

		-- invoice lines of the lease inside the date range (one row per invoice detail line)
		CREATE TABLE #InvLines (
			[LeaseStocklineId] BIGINT, [PartNumber] NVARCHAR(100), [PartDescription] NVARCHAR(500),
			[BillingInvoicingId] BIGINT, [InvoiceNo] VARCHAR(256), [InvoiceDate] DATE,
			[BaseAmount] DECIMAL(18, 6), [TimeOverage] DECIMAL(18, 6), [CycleOverage] DECIMAL(18, 6),
			[Maintenance] DECIMAL(18, 6), [Insurance] DECIMAL(18, 6), [Taxes] DECIMAL(18, 6)
		);

		INSERT INTO #InvLines
		SELECT LSL.[LeaseStocklineId], LSL.[PN], LSL.[PNDescription], BI.[BillingInvoicingId], BI.[InvoiceNo], CAST(BI.[InvoiceDate] AS DATE),
			CASE WHEN D.[LineType] IN ('Flat Rate', 'Charges', 'Others') THEN ISNULL(D.[LineAmount], 0) ELSE 0 END,
			CASE WHEN D.[LineType] = 'Overrun' THEN ISNULL(D.[TimeBillingAmount], 0) ELSE 0 END,
			CASE WHEN D.[LineType] = 'Overrun' THEN ISNULL(D.[CycleBillingAmount], 0) ELSE 0 END,
			CASE WHEN D.[LineType] = 'Maintenance' THEN ISNULL(D.[LineAmount], 0) ELSE 0 END,
			CASE WHEN D.[LineType] = 'Insurance' THEN ISNULL(D.[LineAmount], 0) ELSE 0 END,
			CASE WHEN D.[LineType] = 'Taxes' THEN ISNULL(D.[LineAmount], 0) ELSE 0 END
		FROM [dbo].[LeaseBillingInvoicingItemDetails] D WITH (NOLOCK)
		INNER JOIN [dbo].[BillingInvoicingItems] BX WITH (NOLOCK)
			ON BX.[BillingInvoicingItemId] = D.[BillingInvoicingItemId] AND BX.[IsDeleted] = 0 AND ISNULL(BX.[IsVersionIncrease], 0) = 0
			AND BX.[ModuleId] = @LeaseModuleId AND BX.[ReferenceId] = @LeaseHeaderId
		INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK)
			ON BI.[BillingInvoicingId] = BX.[BillingInvoicingId] AND BI.[IsDeleted] = 0 AND BI.[ModuleId] = @LeaseModuleId
			AND ISNULL(BI.[InvoiceStatus], '') <> 'Voided'
			AND CAST(BI.[InvoiceDate] AS DATE) >= @FromDate AND CAST(BI.[InvoiceDate] AS DATE) <= @ToDate
		INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			ON LSL.[LeaseStocklineId] = D.[LeaseStocklineId] AND LSL.[LeaseHeaderId] = @LeaseHeaderId
		WHERE ISNULL(D.[IsDeleted], 0) = 0 AND ISNULL(D.[IsVersionIncrease], 0) = 0
		  AND (@PartNumber IS NULL OR LSL.[PN] = @PartNumber);

		IF (@ViewType = 'PN')
		BEGIN
			-- PN view : one row per invoice for each PN
			SELECT L.[PartNumber], L.[PartDescription], L.[InvoiceDate], L.[BillingInvoicingId], L.[InvoiceNo],
				   CAST(SUM(L.[BaseAmount]) AS DECIMAL(18, 2)) AS BaseAmount,
				   CAST(SUM(L.[TimeOverage]) AS DECIMAL(18, 2)) AS TimeOverage,
				   CAST(SUM(L.[CycleOverage]) AS DECIMAL(18, 2)) AS CycleOverage,
				   CAST(SUM(L.[Maintenance]) AS DECIMAL(18, 2)) AS Maintenance,
				   CAST(SUM(L.[Insurance]) AS DECIMAL(18, 2)) AS Insurance,
				   CAST(SUM(L.[Taxes]) AS DECIMAL(18, 2)) AS Taxes,
				   CAST(SUM(L.[BaseAmount] + L.[TimeOverage] + L.[CycleOverage] + L.[Maintenance] + L.[Insurance] + L.[Taxes]) AS DECIMAL(18, 2)) AS TotalRevenue,
				   CAST(0 AS DECIMAL(18, 2)) AS Depreciation,
				   CAST(0 AS DECIMAL(18, 2)) AS OverhaulCost
			FROM #InvLines L
			GROUP BY L.[PartNumber], L.[PartDescription], L.[BillingInvoicingId], L.[InvoiceNo], L.[InvoiceDate]
			ORDER BY L.[PartNumber], L.[InvoiceDate], L.[InvoiceNo];
		END
		ELSE
		BEGIN
			-- Other Cost of the stockline for the months inside the date range (same month split as the Lease Summary tab)
			DECLARE @FromMonth DATE = DATEFROMPARTS(YEAR(@FromDate), MONTH(@FromDate), 1);

			;WITH LeasedLines AS (
				SELECT DISTINCT [LeaseStocklineId] FROM #InvLines
			),
			Nums AS (
				SELECT TOP (1200) CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS INT) AS n FROM sys.all_columns
			),
			ComponentSlicesBase AS (
				SELECT SC.[LeaseStocklineServiceComponentId] AS ComponentId, SC.[LeaseStocklineId], M.MonthStart, ISNULL(SC.[Amount], 0) AS Amount,
					CASE WHEN SL.SliceFrom = M.MonthStart AND SL.SliceTo = EOMONTH(M.MonthStart) THEN CAST(1 AS DECIMAL(18,6))
						ELSE CAST(DATEDIFF(DAY, SL.SliceFrom, SL.SliceTo) + 1 AS DECIMAL(18,6)) / 30.0 END AS Weight
				FROM [dbo].[LeaseStocklineServiceComponent] SC WITH (NOLOCK)
				INNER JOIN LeasedLines LS ON LS.[LeaseStocklineId] = SC.[LeaseStocklineId]
				INNER JOIN Nums N ON N.n <= DATEDIFF(MONTH, SC.[StartDate], SC.[EndDate])
				CROSS APPLY (SELECT DATEADD(MONTH, N.n, DATEFROMPARTS(YEAR(SC.[StartDate]), MONTH(SC.[StartDate]), 1)) AS MonthStart) M
				CROSS APPLY (SELECT
						CASE WHEN CAST(SC.[StartDate] AS DATE) > M.MonthStart THEN CAST(SC.[StartDate] AS DATE) ELSE M.MonthStart END AS SliceFrom,
						CASE WHEN CAST(SC.[EndDate] AS DATE) < EOMONTH(M.MonthStart) THEN CAST(SC.[EndDate] AS DATE) ELSE EOMONTH(M.MonthStart) END AS SliceTo) SL
				WHERE SC.[IsDeleted] = 0 AND SC.[StartDate] IS NOT NULL AND SC.[EndDate] IS NOT NULL AND SC.[EndDate] >= SC.[StartDate] AND ISNULL(SC.[Amount], 0) <> 0
			),
			ComponentSlicesRounded AS (
				SELECT ComponentId, LeaseStocklineId, MonthStart, Amount,
					ROUND(Amount * Weight / NULLIF(SUM(Weight) OVER (PARTITION BY ComponentId), 0), 2) AS ShareRounded
				FROM ComponentSlicesBase
			),
			ComponentSlices AS (
				SELECT ComponentId, LeaseStocklineId, MonthStart,
					CASE WHEN MonthStart = MAX(MonthStart) OVER (PARTITION BY ComponentId)
						THEN Amount - (SUM(ShareRounded) OVER (PARTITION BY ComponentId) - ShareRounded)
						ELSE ShareRounded END AS SliceAmount
				FROM ComponentSlicesRounded
			),
			OtherCostByLine AS (
				SELECT CS.[LeaseStocklineId], SUM(CS.SliceAmount) AS Amt
				FROM ComponentSlices CS
				WHERE CS.MonthStart >= @FromMonth AND CS.MonthStart <= @ToDate
				GROUP BY CS.[LeaseStocklineId]
				UNION ALL
				SELECT SC.[LeaseStocklineId], SUM(ISNULL(SC.[Amount], 0))
				FROM [dbo].[LeaseStocklineServiceComponent] SC WITH (NOLOCK)
				INNER JOIN LeasedLines LS ON LS.[LeaseStocklineId] = SC.[LeaseStocklineId]
				WHERE SC.[IsDeleted] = 0 AND (SC.[StartDate] IS NULL OR SC.[EndDate] IS NULL OR SC.[EndDate] < SC.[StartDate])
				GROUP BY SC.[LeaseStocklineId]
			),
			OtherCost AS (
				SELECT [LeaseStocklineId], SUM(Amt) AS Amt FROM OtherCostByLine GROUP BY [LeaseStocklineId]
			)
			SELECT LSL.[LeaseStocklineId] AS LeaseStocklineId, LSL.[PN] AS PartNumber, LSL.[PNDescription] AS PartDescription, STK.[SerialNumber] AS SerialNumber,
				   ISNULL(LST.[Name], HST.[Name]) AS [Status],
				   CAST(R.Revenue AS DECIMAL(18, 2)) AS Revenue,
				   CAST(X.Expenses AS DECIMAL(18, 2)) AS Expenses,
				   CAST(R.Revenue - X.Expenses AS DECIMAL(18, 2)) AS Margin,
				   CAST(CASE WHEN R.Revenue = 0 THEN 0 ELSE (R.Revenue - X.Expenses) * 100.0 / R.Revenue END AS DECIMAL(18, 2)) AS MarginPercent,
				   CAST(0 AS DECIMAL(18, 2)) AS CapitalizedCost,
				   LSL.[StartDate] AS StartDate, LSL.[EndDate] AS EndDate,
				   ISNULL(LSL.[StocklineNumber], STK.[StockLineNumber]) AS StocklineNumber,
				   LT.[LeaseType] AS LeaseType,
				   CONCAT(CAST(ISNULL(STK.[TotalTSN], 0) AS BIGINT), ':', RIGHT('0' + CAST(CAST(ISNULL(STK.[TotalTSNMM], 0) AS INT) AS VARCHAR(10)), 2)) AS Tsn,
				   CAST(ISNULL(STK.[TotalCSN], 0) AS DECIMAL(18, 2)) AS Csn,
				   CONCAT(CAST(ISNULL(TC.[TotalTSO], 0) AS BIGINT), ':', RIGHT('0' + CAST(CAST(ISNULL(TC.[TotalTSOMM], 0) AS INT) AS VARCHAR(10)), 2)) AS Tso,
				   CAST(ISNULL(TC.[TotalCSO], 0) AS DECIMAL(18, 2)) AS Cso
			FROM (
				SELECT [LeaseStocklineId], SUM([BaseAmount] + [TimeOverage] + [CycleOverage] + [Maintenance] + [Insurance] + [Taxes]) AS Revenue
				FROM #InvLines GROUP BY [LeaseStocklineId]
			) R
			INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.[LeaseStocklineId] = R.[LeaseStocklineId]
			INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LSL.[LeaseHeaderId]
			LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
			LEFT JOIN [dbo].[LeaseStatus] LST WITH (NOLOCK) ON LST.[LeaseStatusId] = LSL.[LeaseStatusId]
			LEFT JOIN [dbo].[LeaseStatus] HST WITH (NOLOCK) ON HST.[LeaseStatusId] = LH.[LeaseStatusId]
			LEFT JOIN [dbo].[LeaseType] LT WITH (NOLOCK) ON LT.[LeaseTypeId] = LH.[LeaseTypeId]
			LEFT JOIN OtherCost OC ON OC.[LeaseStocklineId] = LSL.[LeaseStocklineId]
			OUTER APPLY (
				SELECT TOP (1) H.[TotalTSO], H.[TotalTSOMM], H.[TotalCSO]
				FROM [dbo].[StocklineTimeCycleHistory] H WITH (NOLOCK)
				WHERE H.[StocklineId] = LSL.[StockLineId] AND ISNULL(H.[IsDeleted], 0) = 0
				ORDER BY H.[StocklineTimeCycleHistoryId] DESC
			) TC
			CROSS APPLY (
				SELECT (ISNULL(STK.[PurchaseOrderUnitCost], 0) * LSL.[QtyOrder]) + (ISNULL(STK.[RepairOrderUnitCost], 0) * LSL.[QtyOrder]) + ISNULL(OC.Amt, 0) AS Expenses
			) X
			ORDER BY LSL.[PN], STK.[SerialNumber], LSL.[LeaseStocklineId];
		END

		DROP TABLE #InvLines;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseReportByLeaseHeaderId'
			, @ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100)) + ''', @ViewType = ''' + ISNULL(@ViewType, '') + ''''
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