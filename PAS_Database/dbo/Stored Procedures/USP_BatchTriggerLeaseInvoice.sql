/*************************************************************
 ** File:   [USP_BatchTriggerLeaseInvoice]
 ** Description: Creates the accounting journal (GL entries) for a POSTED Lease billing invoice (PN-18302). Lease equivalent of
 **              USP_BatchTriggerSOInvoiceNewCommon. Called by USP_PostLeaseBillingInvoice inside the post transaction,
 **              so the journal is created only when an invoice is posted (not when a draft is saved).
 **
 **              The journal depends on the Lease Type name of the lease (Finance = name contains FINANC, Operating = name contains OPERAT):
 **
 **              OPERATING LEASE - OLI (DistributionMaster OPERATINGLEASEINVOICE)
 **                Debit   Accounts Receivable            (OLIACCOUNTSRECEIVABLE)       = invoice total
 **                Credit  Revenue - Operating Lease      (OLIREVENUEOPERATINGLEASE)    = invoice amount, one line per lease stockline
 **
 **              FINANCE LEASE - FLI (DistributionMaster FINANCELEASEINVOICE)
 **                Debit   Accounts Receivable                    (FLIACCOUNTSRECEIVABLE)                 = invoice total
 **                Credit  Revenue - Financing Lease              (FLIREVENUEFINANCINGLEASE)              = fixed flat-rate payment, plus Charges / Others lines
 **                Credit  Revenue - Time / Cycle overage         (FLIREVENUETIMEOVERAGE / FLIREVENUECYCLEOVERAGE)
 **                Credit  Revenue - Maintenance / Insurance      (FLIREVENUEMAINTENANCE / FLIREVENUEINSURANCE)
 **                Credit  Revenue - Tax Payable                  (FLITAXPAYABLE)
 **
 **              Amounts are taken from the current invoice rows only (IsVersionIncrease = 0). Journal lines follow the DisplayNumber (Seq) of the distribution setup.
 **              Every credit/debit line is linked to the lease through LeaseBatchDetails (Lease -> Accounting tab).
 **
 **              Safe no-op (nothing is written, posting is NOT blocked) when: accounting is bypassed for the company, the lease type is neither Finance nor Operating,
 **              the distribution / journal type / journal-number prefix is not set up, any needed distribution has no GL account yet, the invoice has no billable amount,
 **              or a journal already exists for the invoice (idempotent). Any unexpected error is raised so the post rolls back.
 **
 **              Auto-post: when the AR distribution row has IsAutoPost = 1 the batch is posted immediately
 **              (same mechanism as Sales Order: UpdateToPostFullBatch for a new batch, USP_UpdateCommonBatchStatus
 **              when the day's open batch is reused).
 ** PARAMETERS: @BillingInvoicingId BIGINT, @MasterCompanyId INT, @UpdateBy VARCHAR(200)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    08/10/2026     Kishor Makwana          [Lease Accounting] Created
    2    08/10/2026     Kishor Makwana          LastMSLevel / AllMSlevels (udfGetAllEntityMSLevelString) stored on BatchDetails and CommonBatchDetails
    3    14/10/2026     Kishor Makwana          [PN-18302] Journal by lease type: Finance -> FLI, Operating -> OLI. Replaces the LEASEINVOICE distribution.

EXEC USP_BatchTriggerLeaseInvoice @BillingInvoicingId = 1, @MasterCompanyId = 1, @UpdateBy = 'ADMIN User'
************************************************************************/
CREATE PROCEDURE [dbo].[USP_BatchTriggerLeaseInvoice]
	@BillingInvoicingId BIGINT,
	@MasterCompanyId INT,
	@UpdateBy VARCHAR(200)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @DistributionCode VARCHAR(100), @ARCode VARCHAR(100);			-- set below from the lease type (Finance: FLI, Operating: OLI)
		DECLARE @IsFinance BIT = 0, @IsOperating BIT = 0, @LeaseTypeName VARCHAR(500);
		DECLARE @JournalCodeTypeId BIGINT = 74;			-- same journal-number sequence (CodePrefixes) Sales Order uses
		DECLARE @ModuleName VARCHAR(200) = 'LeaseInvoice';
		DECLARE @ReferenceModule VARCHAR(100) = 'LEASE';

		DECLARE @LeaseModuleId INT, @LeaseHeaderId BIGINT, @InvoiceNo VARCHAR(256), @InvoiceDate DATETIME2(7), @ManagementStructureId BIGINT;
		DECLARE @IsAccountByPass BIT = 0;
		DECLARE @DistributionMasterId BIGINT, @JournalTypeId BIGINT, @JournalTypeCode VARCHAR(50), @JournalTypeName VARCHAR(200);
		DECLARE @LeaseNumber VARCHAR(50), @CustomerId BIGINT, @CustomerName VARCHAR(100), @CustomerRef VARCHAR(100), @CustomerTypeId INT, @CustomerTypeName VARCHAR(50);
		DECLARE @LocalCurrencyCode VARCHAR(20) = '', @ForeignCurrencyCode VARCHAR(20) = '', @FXRate DECIMAL(18,2) = 1;
		DECLARE @LegalEntityId BIGINT, @AccountingPeriodId BIGINT = 0, @AccountingPeriod VARCHAR(100);
		DECLARE @StatusId INT, @StatusName VARCHAR(200);
		DECLARE @AccountMSModuleId INT = 0;

		SELECT TOP 1 @LeaseModuleId = ModuleId FROM [dbo].[Module] WITH (NOLOCK) WHERE ModuleName = 'Leasing';

		SELECT @LeaseHeaderId = BI.ReferenceId, @InvoiceNo = BI.InvoiceNo, @InvoiceDate = BI.InvoiceDate, @ManagementStructureId = BI.ManagementStructureId
		FROM [dbo].[BillingInvoicing] BI WITH (NOLOCK)
		WHERE BI.BillingInvoicingId = @BillingInvoicingId AND BI.ModuleId = @LeaseModuleId AND ISNULL(BI.IsDeleted, 0) = 0 AND ISNULL(BI.IsInvoicePosted, 0) = 1;

		IF (@LeaseHeaderId IS NULL) RETURN (0);

		SELECT @IsAccountByPass = ISNULL(IsAccountByPass, 0) FROM [dbo].[MasterCompany] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;
		IF (@IsAccountByPass = 1) RETURN (0);

		-- one journal per invoice
		IF EXISTS (SELECT 1 FROM [dbo].[LeaseBatchDetails] WITH (NOLOCK) WHERE DocumentId = @BillingInvoicingId) RETURN (0);

		-- Finance Lease -> FLI journal, Operating Lease -> OLI journal (decided by the Lease Type name); any other lease type posts nothing
		SELECT @LeaseTypeName = LT.[LeaseType]
		FROM [dbo].[LeaseHeader] LH WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseType] LT WITH (NOLOCK) ON LT.LeaseTypeId = LH.LeaseTypeId
		WHERE LH.LeaseHeaderId = @LeaseHeaderId;
		IF (UPPER(ISNULL(@LeaseTypeName, '')) LIKE '%FINANC%') SET @IsFinance = 1;
		ELSE IF (UPPER(ISNULL(@LeaseTypeName, '')) LIKE '%OPERAT%') SET @IsOperating = 1;
		IF (@IsFinance = 0 AND @IsOperating = 0) RETURN (0);

		SET @DistributionCode = CASE WHEN @IsFinance = 1 THEN 'FINANCELEASEINVOICE' ELSE 'OPERATINGLEASEINVOICE' END;
		SET @ARCode = CASE WHEN @IsFinance = 1 THEN 'FLIACCOUNTSRECEIVABLE' ELSE 'OLIACCOUNTSRECEIVABLE' END;

		-- DistributionMaster and JournalType are common to all companies (MasterCompanyId = 0); only DistributionSetup is per company
		SELECT TOP 1 @DistributionMasterId = ID FROM [dbo].[DistributionMaster] WITH (NOLOCK)
		WHERE UPPER(DistributionCode) = @DistributionCode AND ISNULL(IsDeleted, 0) = 0;
		IF (@DistributionMasterId IS NULL) RETURN (0);

		-- distribution not configured yet (a row without a GL account)
		IF EXISTS (SELECT 1 FROM [dbo].[DistributionSetup] WITH (NOLOCK)
				   WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted, 0) = 0
				     AND ISNULL(GlAccountId, 0) = 0 AND ISNULL(IsManualText, 0) = 0) RETURN (0);

		SELECT TOP 1 @JournalTypeId = JournalTypeId FROM [dbo].[DistributionSetup] WITH (NOLOCK)
		WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId;
		SELECT @JournalTypeCode = JournalTypeCode, @JournalTypeName = JournalTypeName FROM [dbo].[JournalType] WITH (NOLOCK) WHERE ID = @JournalTypeId;
		IF (@JournalTypeCode IS NULL) RETURN (0);

		-- ---- invoice lines: one per lease stockline and LineType (current rows only) ----
		IF OBJECT_ID(N'tempdb..#LeaseJournalLines') IS NOT NULL DROP TABLE #LeaseJournalLines;
		IF OBJECT_ID(N'tempdb..#InvLines') IS NOT NULL DROP TABLE #InvLines;
		IF OBJECT_ID(N'tempdb..#RawJournalLines') IS NOT NULL DROP TABLE #RawJournalLines;

		CREATE TABLE #LeaseJournalLines (
			Seq INT IDENTITY(1,1) NOT NULL,
			LeaseStocklineId BIGINT NULL, StocklineId BIGINT NULL, StocklineNumber VARCHAR(100) NULL,
			ItemMasterId BIGINT NULL, PartNumber NVARCHAR(100) NULL,
			LineType VARCHAR(50) NULL, SetupCode VARCHAR(100) NOT NULL, Amount DECIMAL(18,6) NOT NULL
		);
		CREATE TABLE #RawJournalLines (LeaseStocklineId BIGINT NULL, LineType VARCHAR(50) NULL, SetupCode VARCHAR(100) NOT NULL, Amount DECIMAL(18,6) NOT NULL);

		SELECT LBID.LeaseStocklineId, LBID.LineType, SUM(ISNULL(LBID.LineAmount, 0)) AS Amount, SUM(ISNULL(LBID.TimeBillingAmount, 0)) AS TimeAmount, SUM(ISNULL(LBID.CycleBillingAmount, 0)) AS CycleAmount,
			   MIN(LBID.FromDate) AS FromDate, MAX(LBID.ToDate) AS ToDate
		INTO #InvLines
		FROM [dbo].[BillingInvoicingItems] BII WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH (NOLOCK) ON LBID.BillingInvoicingItemId = BII.BillingInvoicingItemId
		WHERE BII.BillingInvoicingId = @BillingInvoicingId AND ISNULL(BII.IsDeleted, 0) = 0 AND ISNULL(BII.IsVersionIncrease, 0) = 0
		  AND ISNULL(LBID.IsDeleted, 0) = 0 AND ISNULL(LBID.IsVersionIncrease, 0) = 0
		GROUP BY LBID.LeaseStocklineId, LBID.LineType
		HAVING SUM(ISNULL(LBID.LineAmount, 0)) > 0;

		IF NOT EXISTS (SELECT 1 FROM #InvLines) BEGIN DROP TABLE #InvLines; DROP TABLE #LeaseJournalLines; DROP TABLE #RawJournalLines; RETURN (0); END

		IF (@IsOperating = 1)
		BEGIN
			-- OLI: AR DR = invoice total, Revenue - Operating Lease CR = invoice amount (one line per lease stockline)
			INSERT INTO #RawJournalLines (LeaseStocklineId, LineType, SetupCode, Amount)
			SELECT LeaseStocklineId, 'Operating Lease', 'OLIREVENUEOPERATINGLEASE', SUM(Amount) FROM #InvLines GROUP BY LeaseStocklineId;
		END
		ELSE
		BEGIN
			-- FLI: Flat Rate lines. A usage rate line (Usage (Time/Cycle) billing, rate per hour / per cycle) carries its amount in TimeBillingAmount / CycleBillingAmount:
			-- time part -> Revenue - Time Overage, cycle part -> Revenue - Cycle Overage; whatever is left (fixed monthly amount) -> Revenue - Financing Lease.
			-- (principal / interest split with an amortization schedule is not implemented yet - pending client requirement)
			INSERT INTO #RawJournalLines (LeaseStocklineId, LineType, SetupCode, Amount)
			SELECT F.LeaseStocklineId, 'Flat Rate', 'FLIREVENUETIMEOVERAGE', CASE WHEN F.TimeAmount > F.Amount THEN F.Amount ELSE F.TimeAmount END
			FROM #InvLines F WHERE F.LineType = 'Flat Rate';

			INSERT INTO #RawJournalLines (LeaseStocklineId, LineType, SetupCode, Amount)
			SELECT F.LeaseStocklineId, 'Flat Rate', 'FLIREVENUECYCLEOVERAGE', CASE WHEN F.CycleAmount > F.Amount - CASE WHEN F.TimeAmount > F.Amount THEN F.Amount ELSE F.TimeAmount END
														  THEN F.Amount - CASE WHEN F.TimeAmount > F.Amount THEN F.Amount ELSE F.TimeAmount END ELSE F.CycleAmount END
			FROM #InvLines F WHERE F.LineType = 'Flat Rate';

			INSERT INTO #RawJournalLines (LeaseStocklineId, LineType, SetupCode, Amount)
			SELECT F.LeaseStocklineId, 'Flat Rate', 'FLIREVENUEFINANCINGLEASE',
				   F.Amount - (CASE WHEN F.TimeAmount > F.Amount THEN F.Amount ELSE F.TimeAmount END)
							- (CASE WHEN F.CycleAmount > F.Amount - CASE WHEN F.TimeAmount > F.Amount THEN F.Amount ELSE F.TimeAmount END THEN F.Amount - CASE WHEN F.TimeAmount > F.Amount THEN F.Amount ELSE F.TimeAmount END ELSE F.CycleAmount END)
			FROM #InvLines F WHERE F.LineType = 'Flat Rate';

			-- Overrun: time part and cycle part
			INSERT INTO #RawJournalLines (LeaseStocklineId, LineType, SetupCode, Amount)
			SELECT LeaseStocklineId, 'Overrun', 'FLIREVENUETIMEOVERAGE', CASE WHEN TimeAmount > Amount THEN Amount ELSE TimeAmount END FROM #InvLines WHERE LineType = 'Overrun';

			INSERT INTO #RawJournalLines (LeaseStocklineId, LineType, SetupCode, Amount)
			SELECT LeaseStocklineId, 'Overrun', 'FLIREVENUECYCLEOVERAGE', Amount - CASE WHEN TimeAmount > Amount THEN Amount ELSE TimeAmount END FROM #InvLines WHERE LineType = 'Overrun';

			-- Maintenance / Insurance / Taxes; Charges, Others and any other line type have no FLI distribution of their own and go to Revenue - Financing Lease
			INSERT INTO #RawJournalLines (LeaseStocklineId, LineType, SetupCode, Amount)
			SELECT LeaseStocklineId, LineType,
				CASE LineType WHEN 'Maintenance' THEN 'FLIREVENUEMAINTENANCE' WHEN 'Insurance' THEN 'FLIREVENUEINSURANCE' WHEN 'Taxes' THEN 'FLITAXPAYABLE' ELSE 'FLIREVENUEFINANCINGLEASE' END,
				Amount
			FROM #InvLines WHERE ISNULL(LineType, '') NOT IN ('Flat Rate', 'Overrun');
		END

		DELETE FROM #RawJournalLines WHERE Amount <= 0;

		-- lines in the order of the distribution setup (Seq / DisplayNumber), then per stockline
		INSERT INTO #LeaseJournalLines (LeaseStocklineId, StocklineId, StocklineNumber, ItemMasterId, PartNumber, LineType, SetupCode, Amount)
		SELECT R.LeaseStocklineId, LSL.StockLineId, LSL.StocklineNumber, LSL.ItemMasterId, LSL.PN, R.LineType, R.SetupCode, R.Amount
		FROM #RawJournalLines R
		LEFT JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.LeaseStocklineId = R.LeaseStocklineId
		LEFT JOIN [dbo].[DistributionSetup] DS WITH (NOLOCK) ON DS.DistributionMasterId = @DistributionMasterId AND DS.MasterCompanyId = @MasterCompanyId
			 AND ISNULL(DS.IsDeleted, 0) = 0 AND UPPER(DS.DistributionSetupCode) = R.SetupCode
		ORDER BY DS.DisplayNumber, R.LeaseStocklineId;

		DROP TABLE #RawJournalLines;

		IF NOT EXISTS (SELECT 1 FROM #LeaseJournalLines) BEGIN DROP TABLE #LeaseJournalLines; RETURN (0); END

		-- every distribution this journal needs must exist (otherwise the journal would not balance)
		IF EXISTS (SELECT 1 FROM (SELECT DISTINCT SetupCode FROM #LeaseJournalLines UNION SELECT @ARCode) C
				   WHERE NOT EXISTS (SELECT 1 FROM [dbo].[DistributionSetup] DS WITH (NOLOCK)
									 WHERE DS.DistributionMasterId = @DistributionMasterId AND DS.MasterCompanyId = @MasterCompanyId
									   AND ISNULL(DS.IsDeleted, 0) = 0 AND UPPER(DS.DistributionSetupCode) = C.SetupCode))
		BEGIN DROP TABLE #LeaseJournalLines; RETURN (0); END

		-- ---- lease / customer / period ----
		DECLARE @LocalCurrencyId INT, @ForeignCurrencyId INT, @ForeignExchangeRate DECIMAL(18,6);
		SELECT @LeaseNumber = LH.LeaseNumber, @CustomerId = LH.CustomerId, @CustomerRef = LH.CustomerRef,
			   @LocalCurrencyId = LH.LocalCurrencyId, @ForeignCurrencyId = LH.ForeignCurrencyId, @ForeignExchangeRate = LH.ForeignExchangeRate
		FROM [dbo].[LeaseHeader] LH WITH (NOLOCK) WHERE LH.LeaseHeaderId = @LeaseHeaderId;
		SELECT @LocalCurrencyCode = ISNULL(Code, '') FROM [dbo].[Currency] WITH (NOLOCK) WHERE CurrencyId = @LocalCurrencyId;
		SELECT @ForeignCurrencyCode = ISNULL(Code, '') FROM [dbo].[Currency] WITH (NOLOCK) WHERE CurrencyId = @ForeignCurrencyId;
		SET @FXRate = ISNULL(NULLIF(@ForeignExchangeRate, 0), 1);

		SELECT @CustomerName = C.[Name], @CustomerTypeId = C.CustomerAffiliationId, @CustomerTypeName = CAF.[Description]
		FROM [dbo].[Customer] C WITH (NOLOCK)
		LEFT JOIN [dbo].[CustomerAffiliation] CAF WITH (NOLOCK) ON CAF.CustomerAffiliationId = C.CustomerAffiliationId
		WHERE C.CustomerId = @CustomerId;

		SELECT TOP 1 @LegalEntityId = MSL.LegalEntityId
		FROM [dbo].[EntityStructureSetup] ESS WITH (NOLOCK)
		INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH (NOLOCK) ON MSL.ID = ESS.Level1Id
		WHERE ESS.EntityStructureId = @ManagementStructureId;

		SELECT TOP 1 @AccountingPeriodId = AccountingCalendarId, @AccountingPeriod = PeriodName
		FROM [dbo].[AccountingCalendar] WITH (NOLOCK)
		WHERE IsDeleted = 0 AND LegalEntityId = @LegalEntityId AND MasterCompanyId = @MasterCompanyId
		  AND CAST(GETUTCDATE() AS DATE) >= CAST(FromDate AS DATE) AND CAST(GETUTCDATE() AS DATE) <= CAST(ToDate AS DATE);

		SELECT @StatusId = Id, @StatusName = [Name] FROM [dbo].[BatchStatus] WITH (NOLOCK) WHERE [Name] = 'Open';
		SELECT @AccountMSModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH (NOLOCK) WHERE ModuleName = 'Accounting';

		-- ---- journal number (same CodePrefixes sequence as the other modules) ----
		DECLARE @currentNo BIGINT = 0, @JournalTypeNumber VARCHAR(100);
		SELECT @currentNo = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END,
			   @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END, CodePrefix, CodeSufix))
		FROM [dbo].[CodePrefixes] WITH (UPDLOCK, HOLDLOCK)
		WHERE CodeTypeId = @JournalCodeTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;
		IF (@JournalTypeNumber IS NULL) BEGIN DROP TABLE #LeaseJournalLines; RETURN (0); END

		-- ---- batch header: reuse today's open batch of this journal type / customer type, else create one ----
		DECLARE @JournalBatchHeaderId BIGINT, @IsBatchGenerated BIT = 0, @CurrentPeriodId BIGINT = 0;
		SELECT TOP 1 @JournalBatchHeaderId = JournalBatchHeaderId, @CurrentPeriodId = ISNULL(AccountingPeriodId, 0)
		FROM [dbo].[BatchHeader] WITH (NOLOCK)
		WHERE JournalTypeId = @JournalTypeId AND MasterCompanyId = @MasterCompanyId AND CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)
		  AND StatusId = @StatusId AND ISNULL(CustomerTypeId, 0) = ISNULL(@CustomerTypeId, 0) AND IsDeleted = 0
		ORDER BY JournalBatchHeaderId DESC;

		IF (@JournalBatchHeaderId IS NULL)
		BEGIN
			DECLARE @BatchNo BIGINT, @BatchName VARCHAR(100);
			SELECT TOP 1 @BatchNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE 1 END FROM [dbo].[BatchHeader] WITH (NOLOCK) ORDER BY JournalBatchHeaderId DESC;
			SET @BatchNo = ISNULL(@BatchNo, 1);
			SET @BatchName = @JournalTypeCode + ' ' + CASE WHEN @BatchNo > 99 THEN CAST(@BatchNo AS VARCHAR(50)) ELSE RIGHT('000' + CAST(@BatchNo AS VARCHAR(50)), 3) END;

			INSERT INTO [dbo].[BatchHeader]
				([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],[AccountingPeriodId],[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],
				 [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module],[CustomerTypeId])
			VALUES
				(@BatchName,@BatchNo,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypeName,0,0,0,
				 @MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@JournalTypeCode,@CustomerTypeId);
			SET @JournalBatchHeaderId = SCOPE_IDENTITY();
		END
		ELSE
		BEGIN
			SET @IsBatchGenerated = 1;
			IF (@CurrentPeriodId = 0)
				UPDATE [dbo].[BatchHeader] SET AccountingPeriodId = @AccountingPeriodId, AccountingPeriod = @AccountingPeriod WHERE JournalBatchHeaderId = @JournalBatchHeaderId;
		END

		-- ---- journal (BatchDetails) header row; debit / credit totals are filled in after the lines ----
		DECLARE @JournalBatchDetailId BIGINT, @LineNo INT = 0;

		-- management structure of the invoice as text (last level name + all levels), stored on BatchDetails and CommonBatchDetails like the other modules
		DECLARE @LastMSLevel NVARCHAR(MAX) = NULL, @AllMSlevels NVARCHAR(MAX) = NULL;
		SELECT @AllMSlevels = MSF.[AllMSlevels], @LastMSLevel = MSF.[LastMSName] FROM [dbo].[udfGetAllEntityMSLevelString](@ManagementStructureId) MSF;

		INSERT INTO [dbo].[BatchDetails]
			([JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],[EntryDate],
			 [JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],[ModuleName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
			 [IsActive],[IsDeleted],[AccountingPeriodId],[AccountingPeriod],[LastMSLevel],[AllMSlevels])
		VALUES
			(@JournalTypeNumber,@currentNo,0,NULL,@JournalBatchHeaderId,1,0,NULL,NULL,@InvoiceDate,GETUTCDATE(),
			 @JournalTypeId,@JournalTypeName,1,0,0,0,@ModuleName,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),
			 1,0,@AccountingPeriodId,@AccountingPeriod,@LastMSLevel,@AllMSlevels);
		SET @JournalBatchDetailId = SCOPE_IDENTITY();

		-- ---- journal lines: AR first (Seq 0), then the revenue lines ----
		DECLARE @Total DECIMAL(18,6) = (SELECT SUM(Amount) FROM #LeaseJournalLines);
		DECLARE @Seq INT = 0, @MaxSeq INT = (SELECT MAX(Seq) FROM #LeaseJournalLines);
		DECLARE @SetupCode VARCHAR(100), @Amount DECIMAL(18,6), @DistributionSetupId INT, @DistributionName VARCHAR(200), @GlAccountId BIGINT, @GlAccountNumber VARCHAR(200), @GlAccountName VARCHAR(200), @CrDrType INT;
		DECLARE @LeaseStocklineId BIGINT, @StocklineId BIGINT, @StocklineNumber VARCHAR(100), @ItemMasterId BIGINT, @PartNumber NVARCHAR(100), @LineType VARCHAR(50);
		DECLARE @CommonJournalBatchDetailId BIGINT, @IsAutoPost INT = 0;

		WHILE (@Seq <= @MaxSeq)
		BEGIN
			SELECT @SetupCode = NULL, @LeaseStocklineId = NULL, @StocklineId = NULL, @StocklineNumber = NULL, @ItemMasterId = NULL, @PartNumber = NULL, @LineType = NULL;
			IF (@Seq = 0)
			BEGIN
				SET @SetupCode = @ARCode; SET @Amount = @Total;
			END
			ELSE
			BEGIN
				SELECT @SetupCode = SetupCode, @Amount = Amount, @LeaseStocklineId = LeaseStocklineId, @StocklineId = StocklineId, @StocklineNumber = StocklineNumber,
					   @ItemMasterId = ItemMasterId, @PartNumber = PartNumber, @LineType = LineType
				FROM #LeaseJournalLines WHERE Seq = @Seq;
			END

			SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = [Name], @GlAccountId = GlAccountId, @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName, @CrDrType = CRDRType,
						 @IsAutoPost = CASE WHEN @Seq = 0 THEN ISNULL(IsAutoPost, 0) ELSE @IsAutoPost END
			FROM [dbo].[DistributionSetup] WITH (NOLOCK)
			WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted, 0) = 0 AND UPPER(DistributionSetupCode) = @SetupCode;

			SET @LineNo = @LineNo + 1;
			INSERT INTO [dbo].[CommonBatchDetails]
				([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],
				 [TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],
				 [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
			VALUES
				(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,@LineNo,@GlAccountId,@GlAccountNumber,@GlAccountName,
				 @InvoiceDate,GETUTCDATE(),@JournalTypeId,@JournalTypeName,
				 CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
				 CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
				 CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
				 @ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,
				 @MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LeaseNumber,@CustomerName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@LeaseHeaderId,@ReferenceModule);
			SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

			-- management-structure levels of the journal line (same as every other module)
			EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId, @ManagementStructureId, @MasterCompanyId, @UpdateBy, @AccountMSModuleId, 1;

			INSERT INTO [dbo].[LeaseBatchDetails]
				([JournalBatchDetailId],[JournalBatchHeaderId],[CommonJournalBatchDetailId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],
				 [LeaseHeaderId],[LeaseNumber],[LeaseStocklineId],[StocklineId],[StocklineNumber],[DocumentId],[DocumentNumber],[LineType],[ARControlNumber],[CustomerRef],[MasterCompanyId],[CreatedBy])
			VALUES
				(@JournalBatchDetailId,@JournalBatchHeaderId,@CommonJournalBatchDetailId,@CustomerTypeId,@CustomerTypeName,@CustomerId,@CustomerName,@ItemMasterId,@ItemMasterId,@PartNumber,
				 @LeaseHeaderId,@LeaseNumber,@LeaseStocklineId,@StocklineId,@StocklineNumber,@BillingInvoicingId,@InvoiceNo,@LineType,NULL,@CustomerRef,@MasterCompanyId,@UpdateBy);

			SET @Seq = @Seq + 1;
		END

		-- ---- totals ----
		DECLARE @TotalDebit DECIMAL(18,6) = 0, @TotalCredit DECIMAL(18,6) = 0;
		SELECT @TotalDebit = ISNULL(SUM(DebitAmount), 0), @TotalCredit = ISNULL(SUM(CreditAmount), 0) FROM [dbo].[CommonBatchDetails] WITH (NOLOCK) WHERE JournalBatchDetailId = @JournalBatchDetailId;
		UPDATE [dbo].[BatchDetails] SET DebitAmount = @TotalDebit, CreditAmount = @TotalCredit, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdateBy WHERE JournalBatchDetailId = @JournalBatchDetailId;

		SELECT @TotalDebit = ISNULL(SUM(DebitAmount), 0), @TotalCredit = ISNULL(SUM(CreditAmount), 0) FROM [dbo].[BatchDetails] WITH (NOLOCK) WHERE JournalBatchHeaderId = @JournalBatchHeaderId AND IsDeleted = 0;
		UPDATE [dbo].[BatchHeader] SET TotalDebit = @TotalDebit, TotalCredit = @TotalCredit, TotalBalance = @TotalDebit - @TotalCredit, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdateBy WHERE JournalBatchHeaderId = @JournalBatchHeaderId;

		UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @JournalCodeTypeId AND MasterCompanyId = @MasterCompanyId;


		-- ---- auto-post (IsAutoPost on the AR distribution row) ----
		IF (@IsAutoPost = 1 AND @IsBatchGenerated = 0)
			EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId, @UpdateBy;
		IF (@IsAutoPost = 1 AND @IsBatchGenerated = 1)
		BEGIN
			-- USP_UpdateCommonBatchStatus also returns a diagnostic result set (SELECT * FROM AccountingCalendar). It is swallowed here so the
			-- caller (USP_PostLeaseBillingInvoice -> API) still reads its own invoice result as the first result set.
			IF OBJECT_ID(N'tempdb..#LeaseAcctCalSink') IS NOT NULL DROP TABLE #LeaseAcctCalSink;
			SELECT TOP 0 * INTO #LeaseAcctCalSink FROM [dbo].[AccountingCalendar];
			INSERT INTO #LeaseAcctCalSink EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId, @UpdateBy, @AccountingPeriodId, @AccountingPeriod;
			DROP TABLE #LeaseAcctCalSink;
		END

		DROP TABLE #LeaseJournalLines;
		IF OBJECT_ID(N'tempdb..#InvLines') IS NOT NULL DROP TABLE #InvLines;

	END TRY
	BEGIN CATCH
		IF OBJECT_ID(N'tempdb..#LeaseJournalLines') IS NOT NULL DROP TABLE #LeaseJournalLines;
		IF OBJECT_ID(N'tempdb..#RawJournalLines') IS NOT NULL DROP TABLE #RawJournalLines;
		IF OBJECT_ID(N'tempdb..#InvLines') IS NOT NULL DROP TABLE #InvLines;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_BatchTriggerLeaseInvoice'
			, @ProcedureParameters VARCHAR(3000) = '@BillingInvoicingId = ''' + CAST(ISNULL(@BillingInvoicingId, 0) AS VARCHAR(100)) + ''''
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