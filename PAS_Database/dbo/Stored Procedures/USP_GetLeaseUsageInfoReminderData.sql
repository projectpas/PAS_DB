/*************************************************************
 ** File:   [USP_GetLeaseUsageInfoReminderData]
 ** Description: Data for the Lease "usage information pending" reminder e-mail (job: LeaseUsageInfoReminderService
 **              -> API Leasing/sendLeaseUsageInfoReminders; manual: Usage Info tab -> API Leasing/sendLeaseUsageInfoReminder).
 **              Usage is entered per month; this lists the Usage Based / Flat Rate + Overrun part lines of Active leases that have NO usage entered for the current month,
 **              so the customer contact selected on the lease (LeaseHeader.Email) can be reminded to enter it.
 **
 **              Eligible line (always): lease is Active and not deleted, line is active/not deleted/reserved and its own status is Active, BillingMethod = 'UsageBased' or 'FlatRatePlusOverrun'.
 **                - Time  applies when Usage Per Unit Time > 0   (when neither rate is set both Time and Cycle apply)
 **                - Cycle applies when Usage Per Unit Cycle > 0
 **
 **              @LeaseHeaderId IS NULL (scheduled job): only from the @ReminderDayOfMonth-th day of the month (UTC) - so from the 28th until the end of the
 **                  month the reminder repeats daily until usage is entered - and only for lines that have no Time / Cycle usage entry in the current month
 **                  (LeaseStocklineUsageHistory row whose From Date - To Date period falls in the current month); never twice for a lease within 12 hours (Email.ReferenceId = LeaseHeaderId).
 **              @LeaseHeaderId = x   (manual send)    : that lease only, any day, ALL eligible lines (no month check, no 12 hour check) - the user decides to send by the button.
 **
 **              Result: one row per line with ToEmail = the lease's Email (customer contact e-mail shown on the lease header; NULL when empty).
 **              The API groups it by lease and queues ONE e-mail per lease.
 ** PARAMETERS: @MasterCompanyId INT, @LeaseHeaderId BIGINT = NULL
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    20/10/2026     Kishor Makwana          [PN-18359] Created - usage information reminder (scheduler + manual)
    2    21/10/2026     Kishor Makwana          [PN-18359] Scheduler: usage missing = no usage entry in the current month (from the 28th); manual send: all eligible lines

EXEC USP_GetLeaseUsageInfoReminderData @MasterCompanyId = 1
EXEC USP_GetLeaseUsageInfoReminderData @MasterCompanyId = 1, @LeaseHeaderId = 20   -- manual: every eligible line
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseUsageInfoReminderData]
	@MasterCompanyId INT,
	@LeaseHeaderId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @Today DATE = CAST(GETUTCDATE() AS DATE);
		DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
		DECLARE @NextMonthStart DATE = DATEADD(MONTH, 1, @MonthStart);
		DECLARE @ReminderDayOfMonth INT = 28;   -- the reminder starts on this day of the month
		DECLARE @IsManual BIT = CASE WHEN @LeaseHeaderId IS NOT NULL THEN 1 ELSE 0 END;
		DECLARE @SubjectPrefix NVARCHAR(100) = N'Lease Usage Information Reminder';   -- same prefix the API puts in front of the subject
		DECLARE @LeaseModuleId INT = (SELECT TOP 1 [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Leasing');
		DECLARE @ActiveLeaseStatusId INT = 2;   -- Lease status ids are fixed in the app (LeaseStatusEnum: 1 Draft, 2 Active, 3 Closed)

		IF (@IsManual = 0 AND @Today < DATEFROMPARTS(YEAR(@Today), MONTH(@Today), @ReminderDayOfMonth))
		BEGIN
			RETURN 0;   -- not the reminder period yet: empty result, no mail
		END

		;WITH Missing AS (
			SELECT LH.[LeaseHeaderId], LH.[LeaseNumber], LH.[LeaseName], C.[Name] AS CustomerName,
				   LH.[CustomerContactId], LTRIM(RTRIM(ISNULL(CON.[FirstName], '') + ' ' + ISNULL(CON.[LastName], ''))) AS ContactName,
				   NULLIF(LTRIM(RTRIM(LH.[Email])), '') AS ToEmail,
				   LSL.[LeaseStocklineId],
				   UPPER(ISNULL(LSL.[PN], '')) AS PartNumber, UPPER(ISNULL(LSL.[PNDescription], '')) AS PartDescription,
				   UPPER(COALESCE(STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber, UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
				   U.[CurrentTSNToDate] AS LastTimeToDate, U.[CurrentCSNToDate] AS LastCycleToDate,
				   CASE WHEN ISNULL(LSL.[UsagePerUnitTimes], 0) > 0 OR ISNULL(LSL.[UsagePerUnitCycles], 0) <= 0 THEN 1 ELSE 0 END AS TimeRequired,
				   CASE WHEN ISNULL(LSL.[UsagePerUnitCycles], 0) > 0 OR ISNULL(LSL.[UsagePerUnitTimes], 0) <= 0 THEN 1 ELSE 0 END AS CycleRequired
			FROM [dbo].[LeaseHeader] LH WITH (NOLOCK)
			INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.[LeaseHeaderId] = LH.[LeaseHeaderId]
			LEFT JOIN [dbo].[LeaseStocklineUsage] U WITH (NOLOCK) ON U.[LeaseStocklineId] = LSL.[LeaseStocklineId] AND U.[IsDeleted] = 0
			LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = LH.[CustomerId]
			LEFT JOIN [dbo].[CustomerContact] CC WITH (NOLOCK) ON CC.[CustomerContactId] = LH.[CustomerContactId]
			LEFT JOIN [dbo].[Contact] CON WITH (NOLOCK) ON CON.[ContactId] = CC.[ContactId]
			WHERE LH.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LH.[IsDeleted], 0) = 0 AND ISNULL(LH.[IsActive], 1) = 1
			  AND LH.[LeaseStatusId] = @ActiveLeaseStatusId
			  AND (@LeaseHeaderId IS NULL OR LH.[LeaseHeaderId] = @LeaseHeaderId)
			  AND LSL.[IsDeleted] = 0 AND ISNULL(LSL.[IsActive], 1) = 1 AND LSL.[QtyReserved] > 0 AND LSL.[LeaseStatusId] = @ActiveLeaseStatusId
			  AND LSL.[BillingMethod] IN ('UsageBased', 'FlatRatePlusOverrun')   -- both bill from the usage that is entered (overrun = usage over the limit)
			  AND (@IsManual = 1 OR NOT EXISTS (SELECT 1 FROM [dbo].[Email] E WITH (NOLOCK)
												WHERE E.[MasterCompanyId] = @MasterCompanyId AND E.[ModuleId] = @LeaseModuleId AND E.[ReferenceId] = LH.[LeaseHeaderId] AND ISNULL(E.[IsDeleted], 0) = 0
												  AND E.[Subject] LIKE @SubjectPrefix + N'%' AND E.[CreatedDate] >= DATEADD(HOUR, -12, GETUTCDATE())))
		)
		SELECT @Today AS ReminderDate,
			   M.[LeaseHeaderId], M.[LeaseNumber], M.[LeaseName], M.[CustomerName], M.[CustomerContactId], M.[ContactName], M.[ToEmail],
			   M.[LeaseStocklineId], M.[PartNumber], M.[PartDescription], M.[SerialNumber], M.[StockLineNumber],
			   CASE WHEN X.TimeMissing = 1 AND X.CycleMissing = 1 THEN 'Time & Cycle' WHEN X.TimeMissing = 1 THEN 'Time' ELSE 'Cycle' END AS MissingUsage,
			   M.[LastTimeToDate], M.[LastCycleToDate]
		FROM Missing M
		CROSS APPLY (SELECT CASE WHEN M.TimeRequired = 1 AND (@IsManual = 1 OR NOT EXISTS (SELECT 1 FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
																							WHERE H.[LeaseStocklineId] = M.[LeaseStocklineId] AND H.[UsageType] = 'T' AND H.[IsDeleted] = 0 AND H.[IsActive] = 1
																							  AND H.[FromDate] < @NextMonthStart AND H.[ToDate] >= @MonthStart)) THEN 1 ELSE 0 END AS TimeMissing,
							CASE WHEN M.CycleRequired = 1 AND (@IsManual = 1 OR NOT EXISTS (SELECT 1 FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
																							WHERE H.[LeaseStocklineId] = M.[LeaseStocklineId] AND H.[UsageType] = 'C' AND H.[IsDeleted] = 0 AND H.[IsActive] = 1
																							  AND H.[FromDate] < @NextMonthStart AND H.[ToDate] >= @MonthStart)) THEN 1 ELSE 0 END AS CycleMissing) X
		WHERE X.TimeMissing = 1 OR X.CycleMissing = 1
		ORDER BY M.[LeaseNumber], M.[PartNumber], M.[StockLineNumber];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseUsageInfoReminderData'
			, @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100)) + ''', @LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100)) + ''''
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