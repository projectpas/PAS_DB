/*************************************************************
 ** File:   [USP_GetLeasePendingInvoiceReminderData]
 ** Description: Data for the Lease "pending invoice generation" reminder e-mail (job: LeasePendingInvoiceReminderService
 **              -> API Leasing/sendLeasePendingInvoiceReminders). Usage is entered daily and invoices are generated at month end;
 **              this lists the part lines still waiting to be billed so users can be reminded.
 **
 **              Pending lines = exactly the Pending rows of the Billing/Invoicing tab (USP_GetLeaseBillingListByLeaseHeaderId,
 **              BillingStatus = 'N'; nothing-to-bill lines with a 0 amount are left out) for every Active lease of the company.
 **
 **              WHEN rows are returned (otherwise the result set is empty and no mail is sent):
 **                - the company has the reminder switched on and recipients in Lease Setup (LeaseSetting), and
 **                - no reminder mail was already queued in the last 12 hours (safe against a job restart), and
 **                - there is at least one pending line, and
 **                - today is within @ReminderDaysBeforeMonthEnd days of the LAST DAY OF THE MONTH (UTC), or the last day itself, or any pending line is OVERDUE (its usage period ended before the
 **                  first of the current month) - so after month end the reminder repeats DAILY until everything is billed.
 **
 **              Result: one row per pending line, with the recipients (ToEmail) and IsOverdue on every row. The API groups it by lease
 **              and queues ONE e-mail for the recipients.
 ** PARAMETERS: @MasterCompanyId INT
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    09/10/2026     Kishor Makwana          [Lease] Created - pending invoice reminder    

EXEC USP_GetLeasePendingInvoiceReminderData @MasterCompanyId = 1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeasePendingInvoiceReminderData]
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @Today DATE = CAST(GETUTCDATE() AS DATE);
		DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
		DECLARE @ReminderDaysBeforeMonthEnd INT = 2;
		DECLARE @IsMonthEnd BIT = CASE WHEN @Today >= DATEADD(DAY, -@ReminderDaysBeforeMonthEnd, EOMONTH(@Today)) THEN 1 ELSE 0 END;   -- true from that day to the end of the month
		DECLARE @SubjectPrefix NVARCHAR(100) = N'Lease Pending Invoice Reminder';   -- same prefix the API puts in front of the subject
		DECLARE @LeaseModuleId INT = (SELECT TOP 1 [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Leasing');
		DECLARE @ToEmail NVARCHAR(2000), @ShouldSend BIT = 0;
		DECLARE @ActiveLeaseStatusId INT = 2;   -- Lease status ids are fixed in the app (LeaseStatusEnum: 1 Draft, 2 Active, 3 Closed), same as USP_LeaseHeaderList

		IF OBJECT_ID(N'tempdb..#LeaseBillingRows') IS NOT NULL DROP TABLE #LeaseBillingRows;
		IF OBJECT_ID(N'tempdb..#PendingLines') IS NOT NULL DROP TABLE #PendingLines;
		IF OBJECT_ID(N'tempdb..#ItemLines') IS NOT NULL DROP TABLE #ItemLines;

		-- columns of USP_GetLeaseBillingListByLeaseHeaderId (same order); only the ones used below are typed strictly
		CREATE TABLE #LeaseBillingRows (
			LeaseStocklineId BIGINT, PartNumber NVARCHAR(MAX), PartDescription NVARCHAR(MAX), SerialNumber NVARCHAR(MAX), Qty DECIMAL(28,6),
			BillingMethod NVARCHAR(100), BillingFrequency NVARCHAR(100), FlatRate DECIMAL(28,6), LineType NVARCHAR(100), FromDate DATETIME2(7), ToDate DATETIME2(7),
			LineAmount DECIMAL(28,6), TimeRecorded DECIMAL(28,6), TimeLimit DECIMAL(28,6), TimeOver DECIMAL(28,6), TimeOverageRate DECIMAL(28,6), TimeBillingAmount DECIMAL(28,6),
			CycleRecorded DECIMAL(28,6), CycleLimit DECIMAL(28,6), CycleOver DECIMAL(28,6), CycleOverageRate DECIMAL(28,6), CycleBillingAmount DECIMAL(28,6),
			BillingInvoicingId BIGINT, BillingStatus VARCHAR(5), InvoiceNumber NVARCHAR(100), InvoiceDate DATETIME2(7),
			HasUsageInfo BIT, IsActive BIT, LeaseStatusId INT
		);
		CREATE TABLE #PendingLines (
			LeaseHeaderId BIGINT NOT NULL, LeaseNumber VARCHAR(50) NULL, LeaseName VARCHAR(200) NULL, CustomerName VARCHAR(200) NULL,
			LeaseStocklineId BIGINT NULL, PartNumber NVARCHAR(200) NULL, PartDescription NVARCHAR(MAX) NULL, SerialNumber NVARCHAR(200) NULL,
			LineType NVARCHAR(100) NULL, FromDate DATETIME2(7) NULL, ToDate DATETIME2(7) NULL, LineAmount DECIMAL(38,10) NULL, IsOverdue BIT NOT NULL DEFAULT (0)
		);

		-- item lines exactly as the Lease Invoice preview grid prints them (RPT_GetCommonBillingInvoicingItems_LeasePreview)
		CREATE TABLE #ItemLines (
			LeaseHeaderId BIGINT NOT NULL, LeaseStocklineId BIGINT NULL, PartNumber NVARCHAR(200) NULL, PartDescription NVARCHAR(MAX) NULL, SerialNumber NVARCHAR(200) NULL,
			StockLineNumber NVARCHAR(200) NULL, BillingMethod NVARCHAR(100) NULL, UOM NVARCHAR(100) NULL,
			Qty DECIMAL(18,6) NULL, UnitPrice DECIMAL(18,6) NULL, Total DECIMAL(28,6) NULL, SortOrder INT NULL, SortDate DATETIME2(7) NULL
		);

		-- 1. switched on + recipients in Lease Setup
		SELECT TOP 1 @ToEmail = LTRIM(RTRIM(LS.[PendingInvoiceReminderEmails]))
		FROM [dbo].[LeaseSetting] LS WITH (NOLOCK)
		WHERE LS.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LS.[IsDeleted], 0) = 0 AND ISNULL(LS.[IsPendingInvoiceReminderEnabled], 0) = 1;

		-- 2. (the "already sent in the last 12 hours" check is done per lease in the cursor below - one e-mail is queued per lease, with Email.ReferenceId = LeaseHeaderId)
		IF (ISNULL(@ToEmail, N'') <> N'')
		BEGIN
			-- 3. pending lines of every Active lease (same rows as the Pending tab)
			DECLARE @LeaseHeaderId BIGINT;
			DECLARE LeaseCur CURSOR LOCAL FAST_FORWARD FOR
				SELECT LH.[LeaseHeaderId]
				FROM [dbo].[LeaseHeader] LH WITH (NOLOCK)
				WHERE LH.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LH.[IsDeleted], 0) = 0 AND ISNULL(LH.[IsActive], 1) = 1
				  AND LH.[LeaseStatusId] = @ActiveLeaseStatusId
				  AND NOT EXISTS (SELECT 1 FROM [dbo].[Email] E WITH (NOLOCK)
								  WHERE E.[MasterCompanyId] = @MasterCompanyId AND E.[ModuleId] = @LeaseModuleId AND E.[ReferenceId] = LH.[LeaseHeaderId] AND ISNULL(E.[IsDeleted], 0) = 0
									AND E.[Subject] LIKE @SubjectPrefix + N'%' AND E.[CreatedDate] >= DATEADD(HOUR, -12, GETUTCDATE()))
				  AND EXISTS (SELECT 1 FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK) WHERE LSL.[LeaseHeaderId] = LH.[LeaseHeaderId] AND LSL.[IsDeleted] = 0)
				ORDER BY LH.[LeaseHeaderId];
			OPEN LeaseCur;
			FETCH NEXT FROM LeaseCur INTO @LeaseHeaderId;
			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				BEGIN TRY
					DELETE FROM #LeaseBillingRows;
					INSERT INTO #LeaseBillingRows EXEC [dbo].[USP_GetLeaseBillingListByLeaseHeaderId] @LeaseHeaderId = @LeaseHeaderId;

					INSERT INTO #PendingLines (LeaseHeaderId, LeaseNumber, LeaseName, CustomerName, LeaseStocklineId, PartNumber, PartDescription, SerialNumber, LineType, FromDate, ToDate, LineAmount, IsOverdue)
					SELECT LH.[LeaseHeaderId], LH.[LeaseNumber], LH.[LeaseName], C.[Name], R.LeaseStocklineId, R.PartNumber, R.PartDescription, R.SerialNumber, R.LineType, R.FromDate, R.ToDate,
						   (ISNULL(R.LineAmount, 0) + ISNULL(TRY_CONVERT(DECIMAL(38,10), R.TimeBillingAmount), 0) + ISNULL(TRY_CONVERT(DECIMAL(38,10), R.CycleBillingAmount), 0)),   -- same total the Pending tab uses (line + time + cycle billing)
						   CASE WHEN R.ToDate IS NOT NULL AND CAST(R.ToDate AS DATE) < @MonthStart THEN 1 ELSE 0 END
					FROM #LeaseBillingRows R
					INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = @LeaseHeaderId
					LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = LH.[CustomerId]
					WHERE R.BillingStatus = 'N'
					  AND (ISNULL(R.LineAmount, 0) + ISNULL(TRY_CONVERT(DECIMAL(38,10), R.TimeBillingAmount), 0) + ISNULL(TRY_CONVERT(DECIMAL(38,10), R.CycleBillingAmount), 0)) <> 0
					  -- the Pending tab hides stocklines that already have a draft invoice (their changes show under Invoiced)
					  AND NOT EXISTS (SELECT 1 FROM #LeaseBillingRows D WHERE D.LeaseStocklineId = R.LeaseStocklineId AND D.BillingStatus = 'D');
					-- same line splitting as the invoice preview grid (Usage Based => Usage Time / Usage Cycle; Others => Other; Qty/Unit Price/Total)
					;WITH Src AS (
						SELECT G.LeaseStocklineId,
							UPPER(ISNULL(LSL.[PN], '')) AS PNumber,
							UPPER(ISNULL(LSL.[PNDescription], '')) AS PNDescription,
							UPPER(COALESCE(STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber,
							UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
							UPPER(COALESCE(IM.[ConsumeUnitOfMeasure], IM.[StockUnitOfMeasure], '')) AS UOM,
							G.LineType, G.BillingMethod, G.FromDate,
							ISNULL(LSL.[QtyReserved], 0) AS LQty,
							LSL.[UsagePerUnitTimes] AS TimeRate, LSL.[UsagePerUnitCycles] AS CycleRate,
							G.TimeBillingAmount, G.CycleBillingAmount, G.TimeRecorded, G.CycleRecorded,
							QX.Q, TX.Total
						FROM #LeaseBillingRows G
						INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.[LeaseStocklineId] = G.LeaseStocklineId
						LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
						LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = LSL.[ItemMasterId]
						CROSS APPLY (SELECT CASE WHEN G.LineType IN ('Flat Rate', 'Overrun') AND ISNULL(LSL.[QtyReserved], 0) > 0 THEN LSL.[QtyReserved] ELSE 1 END AS Q) QX
						CROSS APPLY (SELECT ISNULL(G.LineAmount, 0) + ISNULL(G.TimeBillingAmount, 0) + ISNULL(G.CycleBillingAmount, 0) AS Total) TX
						WHERE G.BillingStatus = 'N' AND TX.Total <> 0
						  AND NOT EXISTS (SELECT 1 FROM #LeaseBillingRows D WHERE D.LeaseStocklineId = G.LeaseStocklineId AND D.BillingStatus = 'D')
					),
					Lines AS (
						SELECT LeaseStocklineId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
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
						SELECT LeaseStocklineId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM, 'Usage Time',
							CAST(H.Hours AS DECIMAL(18,6)), CAST(TimeBillingAmount / NULLIF(H.Hours, 0) AS DECIMAL(18,6)), TimeBillingAmount, 1, FromDate
						FROM Src
						CROSS APPLY (SELECT COALESCE(TimeBillingAmount / NULLIF(TimeRate * LQty, 0), TimeRecorded / 60.0, 1) AS Hours) H
						WHERE LineType = 'Flat Rate' AND BillingMethod = 'UsageBased' AND ISNULL(TimeBillingAmount, 0) <> 0
						UNION ALL
						SELECT LeaseStocklineId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM, 'Usage Cycle',
							CAST(H.Cycles AS DECIMAL(18,6)), CAST(CycleBillingAmount / NULLIF(H.Cycles, 0) AS DECIMAL(18,6)), CycleBillingAmount, 2, FromDate
						FROM Src
						CROSS APPLY (SELECT COALESCE(CycleBillingAmount / NULLIF(CycleRate * LQty, 0), CycleRecorded, 1) AS Cycles) H
						WHERE LineType = 'Flat Rate' AND BillingMethod = 'UsageBased' AND ISNULL(CycleBillingAmount, 0) <> 0
					)
					INSERT INTO #ItemLines (LeaseHeaderId, LeaseStocklineId, PartNumber, PartDescription, SerialNumber, StockLineNumber, BillingMethod, UOM, Qty, UnitPrice, Total, SortOrder, SortDate)
					SELECT @LeaseHeaderId, LeaseStocklineId, PNumber, PNDescription, SerialNumber, StockLineNumber, LineBillingMethod, UOM, LineQty, LineUnitPrice, LineTotal, SortOrder, SortDate
					FROM Lines;
				END TRY
				BEGIN CATCH
					-- one lease that cannot be evaluated must not stop the reminder for the others (the error is already logged by the called proc)
				END CATCH
				FETCH NEXT FROM LeaseCur INTO @LeaseHeaderId;
			END
			CLOSE LeaseCur;
			DEALLOCATE LeaseCur;

			-- 4. month end, or something is overdue (=> daily after month end until billed)
			IF EXISTS (SELECT 1 FROM #PendingLines) AND (@IsMonthEnd = 1 OR EXISTS (SELECT 1 FROM #PendingLines WHERE IsOverdue = 1))
				SET @ShouldSend = 1;
		END

		SELECT @ToEmail AS ToEmail, @Today AS ReminderDate, @IsMonthEnd AS IsMonthEnd,
			   IL.LeaseHeaderId, LH.[LeaseNumber], LH.[LeaseName], C.[Name] AS CustomerName,
			   IL.LeaseStocklineId,
			   ROW_NUMBER() OVER (PARTITION BY IL.LeaseHeaderId ORDER BY IL.LeaseStocklineId, IL.SortOrder, IL.SortDate) AS ItemNo,
			   IL.PartNumber, IL.PartDescription, IL.SerialNumber, IL.StockLineNumber, IL.BillingMethod, IL.UOM, IL.Qty, IL.UnitPrice, IL.Total,
			   (SELECT COUNT(1) FROM #PendingLines P WHERE P.LeaseHeaderId = IL.LeaseHeaderId AND P.IsOverdue = 1) AS OverdueLineCount
		FROM #ItemLines IL
		INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = IL.LeaseHeaderId
		LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = LH.[CustomerId]
		WHERE @ShouldSend = 1
		ORDER BY LH.[LeaseNumber], ItemNo;

		DROP TABLE #LeaseBillingRows;
		DROP TABLE #PendingLines;
		DROP TABLE #ItemLines;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeasePendingInvoiceReminderData'
			, @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100)) + ''''
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