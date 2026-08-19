/*********************
 ** File:   [USP_ReverseSOInvoiceAccountingEntry]
 ** Author:   Rajesh Gami
 ** Description: This stored procedure reverses the PAS accounting (GL) entries that were
 **              created when a Sales Order invoice (Standard or Proforma) was posted.
 **              It reads the exact GL rows already posted for the invoice
 **              (dbo.SalesOrderBatchDetails.DocumentId = @BillingInvoicingId) and mirrors
 **              them into the SAME journal batch (BatchHeader) as the original entries, with
 **              Debit/Credit swapped - the original
 **              rows are left untouched (audit trail) and both the original and the new
 **              reversal rows are flagged via dbo.BatchDetails.IsReversedJE = 1.
 **              If nothing was posted for this invoice (e.g. accounting was bypassed at
 **              posting time, or no distribution was configured), this SP is a safe no-op.
 ** Purpose:  PAS - Ticket: Re-Open Sales Order Invoice - Accounting Reversal (PAS accounting only)
 ** Date:   08/07/2026

 **********************
  ** Change History
 **********************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				-------------------------------
    1    08/07/2026   Rajesh Gami		Created
    2    08/10/2026   Rajesh Gami		Fixed: the real per-line GlAccountId/IsDebit/DebitAmount/CreditAmount/
										ManagementStructureId/DistributionSetupId etc. live on dbo.CommonBatchDetails,
										not dbo.BatchDetails (BatchDetails only holds a shared placeholder/rolled-up-total
										row per posting batch group - see USP_BatchTriggerBasedonSOInvoiceNew, which sums
										all CommonBatchDetails rows back into that one BatchDetails row after posting).
										Sourcing amounts from BatchDetails was producing one identical summed value on
										every reversed line instead of each line's own correct amount. Now sources all
										per-line financial fields from CommonBatchDetails.
    3    08/10/2026   Rajesh Gami		Removed the dbo.BillingInvoicing.IsReversedJE guard/update (no such column exists
										there, and none is needed) - the double-reversal guard and the "reversed" flag
										used by the UI both live on dbo.BatchDetails.IsReversedJE, which this SP now sets
										to 1 on BOTH the original posted row(s) AND the newly inserted reversal row(s).
    4    12-Aug-2026  Rajesh Gami		[PN-17569] Stopped hardcoding Batch Ref as '<JournalTypeName> (REVERSED)' - it was showing up
										on the grid even for non-reversal rows once a same-day re-invoice reused this
										batch header (see the companion fix in USP_BatchTriggerBasedonSOInvoiceNew).
										Batch Ref is now generated the same dynamic way normal posting does (JournalTypeCode
										+ running number, e.g. 'SOI 1637'); the "(Reverse)" label is added client-side from
										BatchDetails.IsReversedJE instead.
    5    13-Aug-2026  Rajesh Gami		[PN-17635] Fixed two more issues found on the Batch Detail screen for a reversal batch:
										(1) JE Number was just copying the ORIGINAL entry's JournalTypeNumber verbatim onto
										every reversal line, so the reversal showed the exact same JE Number as the invoice
										it was reversing - now generates a genuinely new one via the same CodeTypeId=74/
										CodePrefixes/udfGenerateCodeNumber mechanism USP_BatchTriggerBasedonSOInvoiceNew uses
										for normal posting. (2) AccountingPeriod/AccountingPeriodId were never set on the
										reversal BatchHeader at all (only on the line-item BatchDetails rows), so the Batch
										Detail screen showed Accounting Period as blank/'--Select--' - now captured once from
										the original entries and included on the BatchHeader insert.
    6    18-Aug-2026  Rajesh Gami		[PN-17635] Reversal no longer creates a brand new BatchHeader/batch number. The reversal's
										BatchDetails/CommonBatchDetails/SalesOrderBatchDetails rows are now inserted
										under the SAME JournalBatchHeaderId as the original invoice entries being
										reversed (reused directly from #OriginalEntries) instead of INSERT-ing a fresh
										BatchHeader row. So the Batch Ref no longer changes for a reversal - it keeps
										the invoice's original batch number (e.g. 'SOI 1926'); the reversal JE is still
										distinguished by its own new JE Number (PR 5) and BatchDetails.IsReversedJE = 1.
										This makes the header AccountingPeriod/BatchName generation added in PR 4/PR 5
										unnecessary (removed) - the reused header already carries the correct values
										from when it was first created. The existing header's TotalDebit/TotalCredit/
										TotalBalance are now incremented by the reversal's amounts instead of being
										overwritten, since the header now represents both the original and reversal
										activity together.
    7    19-Aug-2026  Rajesh Gami		[PN-17663] Batch Detail grid was showing one row PER reversed GL line instead of
										ONE aggregated row (matching how the original SO Invoice POST displays as a
										single summed row). dbo.BatchDetails now gets exactly one placeholder row per
										reversal event (inserted once, before the cursor below runs) with DebitAmount/
										CreditAmount pre-summed from #OriginalEntries; every reversed line still gets
										its own dbo.CommonBatchDetails/dbo.SalesOrderBatchDetails row attached to that
										same JournalBatchDetailId, so the 'view' action still lists every individual line.

    EXEC [dbo].[USP_ReverseSOInvoiceAccountingEntry] @BillingInvoicingId = 8998, @MasterCompanyId = 1, @UpdatedBy = 'ADMIN User'

**********************/
CREATE   PROCEDURE [dbo].[USP_ReverseSOInvoiceAccountingEntry]
	@BillingInvoicingId BIGINT,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256),
	@ReversalMessage VARCHAR(500) = NULL OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN

		-- Double-reversal guard lives entirely on dbo.BatchDetails.IsReversedJE (no such column on
		-- dbo.BillingInvoicing, and none is needed) - the #OriginalEntries query below already only
		-- picks up rows where BD.IsReversedJE = 0, so if this invoice was already reversed, #OriginalEntries
		-- comes back empty and the SP no-ops.
		IF OBJECT_ID('tempdb..#OriginalEntries') IS NOT NULL DROP TABLE #OriginalEntries

		-- NOTE: the real per-line GlAccountId/IsDebit/DebitAmount/CreditAmount/ManagementStructureId/
		-- DistributionSetupId/etc. live on dbo.CommonBatchDetails (CBD). dbo.BatchDetails (BD) only holds
		-- batch/journal-type-level metadata plus a shared placeholder row per posting-batch-group whose
		-- own DebitAmount/CreditAmount is later overwritten with the SUM across all of its child
		-- CommonBatchDetails rows (see USP_BatchTriggerBasedonSOInvoiceNew) - so BD must never be used as
		-- the source of a single line's amount/account.
		SELECT
			SOD.[SalesOrderBatchDetailId],
			SOD.[JournalBatchDetailId],
			SOD.[JournalBatchHeaderId],
			SOD.[CommonJournalBatchDetailId],
			SOD.[CustomerTypeId],
			SOD.[CustomerType],
			SOD.[CustomerId],
			SOD.[CustomerName],
			SOD.[ItemMasterId],
			SOD.[PartId],
			SOD.[PartNumber],
			SOD.[SalesOrderId],
			SOD.[SalesOrderNumber],
			SOD.[DocumentId],
			SOD.[DocumentNumber],
			SOD.[StocklineId],
			SOD.[StocklineNumber],
			SOD.[ARControlNumber],
			SOD.[CustomerRef],
			BD.[JournalTypeId],
			BD.[JournalTypeName],
			BD.[JournalTypeNumber],
			BD.[AccountingPeriodId],
			BD.[AccountingPeriod],
			CBD.[GlAccountId],
			CBD.[GlAccountNumber],
			CBD.[GlAccountName],
			CBD.[IsDebit],
			CBD.[DebitAmount],
			CBD.[CreditAmount],
			CBD.[ManagementStructureId],
			CBD.[ModuleName],
			CBD.[LastMSLevel],
			CBD.[AllMSlevels],
			CBD.[DistributionSetupId],
			CBD.[DistributionName],
			CBD.[LotId],
			CBD.[LotNumber],
			CBD.[ReferenceNumber],
			CBD.[ReferenceName],
			CBD.[LocalCurrency],
			CBD.[FXRate],
			CBD.[ForeignCurrency],
			CBD.[ReferenceId],
			CBD.[ReferenceModule],
			BH.[Module],
			BH.[CustomerTypeId] AS [HeaderCustomerTypeId]
		INTO #OriginalEntries
		FROM [dbo].[SalesOrderBatchDetails] SOD WITH(NOLOCK)
		INNER JOIN [dbo].[CommonBatchDetails] CBD WITH(NOLOCK) ON CBD.[CommonJournalBatchDetailId] = SOD.[CommonJournalBatchDetailId]
		INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON BD.[JournalBatchDetailId] = SOD.[JournalBatchDetailId]
		INNER JOIN [dbo].[BatchHeader] BH WITH(NOLOCK) ON BH.[JournalBatchHeaderId] = SOD.[JournalBatchHeaderId]
		WHERE SOD.[DocumentId] = @BillingInvoicingId
		  AND ISNULL(CBD.[IsDeleted],0) = 0
		  AND ISNULL(CBD.[IsActive],1) = 1
		  AND ISNULL(BD.[IsReversedJE],0) = 0

		-- Nothing was ever posted for this invoice (bypassed / not configured), or it was already reversed
		-- previously - nothing to reverse. Surface this via @ReversalMessage so it's visible to the caller
		-- instead of silently doing nothing.
		IF NOT EXISTS(SELECT 1 FROM #OriginalEntries)
		BEGIN
			DROP TABLE #OriginalEntries
			SET @ReversalMessage = 'No PAS accounting entries were found to reverse for this invoice (either none were ever posted, or they were already reversed previously).'
			RETURN
		END

		DECLARE @LineCountReversed INT = (SELECT COUNT(*) FROM #OriginalEntries)

		DECLARE @AccountMSModuleId INT
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Accounting'

		DECLARE @JournalTypeId BIGINT, @JournalTypeName VARCHAR(200)
		SELECT TOP 1 @JournalTypeId = [JournalTypeId], @JournalTypeName = [JournalTypeName] FROM #OriginalEntries

		-- Reversal entries belong in the SAME batch as the original invoice they're reversing - reuse the
		-- original JournalBatchHeaderId (already captured on #OriginalEntries) instead of inserting a new
		-- BatchHeader row. Batch Ref and Accounting Period therefore stay exactly as they already are on
		-- that header; nothing needs to be (re)generated for either of them here.
		DECLARE @NewJournalBatchHeaderId BIGINT, @HeaderCurrentNumber BIGINT
		SELECT TOP 1 @NewJournalBatchHeaderId = [JournalBatchHeaderId] FROM #OriginalEntries
		SELECT @HeaderCurrentNumber = [CurrentNumber] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalBatchHeaderId] = @NewJournalBatchHeaderId

		-- [PN-17635] JE Number for the reversal batch used to just copy the ORIGINAL entry's JournalTypeNumber
		-- verbatim (via the cursor below), so the reversal showed the exact same JE Number as the invoice it was
		-- reversing. Generate a genuinely new one here, using the same CodeTypeId/CodePrefixes/
		-- udfGenerateCodeNumber mechanism USP_BatchTriggerBasedonSOInvoiceNew uses for normal posting - one new
		-- number for the whole reversal event, applied to every line inserted below.
		DECLARE @JECodeTypeId BIGINT = 74
		DECLARE @JECurrentNo BIGINT, @NewJournalTypeNumber VARCHAR(50)
		SELECT @JECurrentNo = CASE WHEN CP.[CurrentNummber] > 0 THEN CAST(CP.[CurrentNummber] AS BIGINT) + 1 ELSE CAST(CP.[StartsFrom] AS BIGINT) + 1 END
		FROM [dbo].[CodePrefixes] CP WITH(NOLOCK)
		INNER JOIN [dbo].[CodeTypes] CT WITH(NOLOCK) ON CP.[CodeTypeId] = CT.[CodeTypeId]
		WHERE CT.[CodeTypeId] = @JECodeTypeId AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0

		IF (@JECurrentNo IS NOT NULL)
		BEGIN
			SELECT @NewJournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@JECurrentNo,
				(SELECT CP.[CodePrefix] FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) WHERE CP.[CodeTypeId] = @JECodeTypeId AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0),
				(SELECT CP.[CodeSufix] FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) WHERE CP.[CodeTypeId] = @JECodeTypeId AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0)))
			UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @JECurrentNo WHERE [CodeTypeId] = @JECodeTypeId AND [MasterCompanyId] = @MasterCompanyId
		END

		DECLARE @LineNumber INT = 1
		DECLARE @TotalDebit DECIMAL(18,2) = 0, @TotalCredit DECIMAL(18,2) = 0

		DECLARE @GlAccountId BIGINT, @GlAccountNumber VARCHAR(200), @GlAccountName VARCHAR(200), @DebitAmount DECIMAL(18,2), @CreditAmount DECIMAL(18,2), @IsDebit BIT
		DECLARE @ManagementStructureId BIGINT, @ModuleName VARCHAR(200), @LastMSLevel VARCHAR(200), @AllMSlevels VARCHAR(MAX)
		DECLARE @DistributionSetupId INT, @DistributionName VARCHAR(200), @JournalTypeNumber VARCHAR(50), @AccountingPeriodId BIGINT, @AccountingPeriod VARCHAR(100)
		DECLARE @LotId BIGINT, @LotNumber VARCHAR(50), @ReferenceNumber VARCHAR(150), @ReferenceName VARCHAR(256), @LocalCurrency VARCHAR(20), @FXRate DECIMAL(18,2), @ForeignCurrency VARCHAR(20), @ReferenceId BIGINT, @ReferenceModule VARCHAR(100)
		DECLARE @CustomerTypeId INT, @CustomerType VARCHAR(50), @OrigCustomerId BIGINT, @CustomerName VARCHAR(200), @ItemMasterId BIGINT, @PartId BIGINT, @PartNumber NVARCHAR(100)
		DECLARE @SalesOrderId BIGINT, @SalesOrderNumber VARCHAR(50), @DocumentId BIGINT, @DocumentNumber VARCHAR(50), @StocklineId BIGINT, @StocklineNumber VARCHAR(50), @ARControlNumber VARCHAR(50), @CustomerRef VARCHAR(MAX)
		DECLARE @OrigJournalBatchDetailId BIGINT
		DECLARE @NewJournalBatchDetailId BIGINT, @NewCommonJournalBatchDetailId BIGINT

		-- [PN-17663] The Batch Detail grid must show ONE row per reversal JE with the SUM of Debit/Credit
		-- across every reversed GL line - exactly like the original SO Invoice POST does - instead of one
		-- row per original line. So a single dbo.BatchDetails placeholder row is inserted ONCE here (before
		-- the cursor below runs), using totals computed directly from #OriginalEntries. Every line the
		-- cursor processes below then attaches its own dbo.CommonBatchDetails/dbo.SalesOrderBatchDetails
		-- row to THIS SAME @NewJournalBatchDetailId, so the 'view' action still lists every individual line -
		-- only the dbo.BatchDetails summary row is now aggregated (mirrors USP_BatchTriggerBasedonSOInvoiceNew).
		DECLARE @HeaderLineNumber BIGINT = 1
		SELECT @HeaderLineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE 1 END
		FROM [dbo].[BatchDetails] WITH(NOLOCK)
		WHERE [JournalBatchHeaderId] = @NewJournalBatchHeaderId
		ORDER BY [JournalBatchDetailId] DESC

		SELECT TOP 1 @AccountingPeriodId = [AccountingPeriodId], @AccountingPeriod = [AccountingPeriod] FROM #OriginalEntries

		-- Debit/Credit swapped the same way each reversed line is swapped below, so this total matches the
		-- sum of what the cursor is about to insert into CommonBatchDetails.
		SELECT @TotalDebit = SUM(ISNULL([CreditAmount],0)), @TotalCredit = SUM(ISNULL([DebitAmount],0)) FROM #OriginalEntries

		INSERT INTO [dbo].[BatchDetails]
			([JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
			 [IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],[ModuleName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
			 [LastMSLevel],[AllMSlevels],[DistributionSetupId],[DistributionName],[JournalTypeNumber],[CurrentNumber],[StatusId],[AccountingPeriodId],[AccountingPeriod],[IsReversedJE])
		VALUES
			(@NewJournalBatchHeaderId,@HeaderLineNumber,0,NULL,NULL,GETUTCDATE(),GETUTCDATE(),@JournalTypeId,@JournalTypeName,
			 1,
			 @TotalDebit,
			 @TotalCredit,
			 0,NULL,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,
			 NULL,NULL,NULL,NULL,@NewJournalTypeNumber,@HeaderCurrentNumber,1,@AccountingPeriodId,@AccountingPeriod,1)

		SET @NewJournalBatchDetailId = SCOPE_IDENTITY()

		DECLARE curReverse CURSOR LOCAL FAST_FORWARD FOR
			SELECT [JournalBatchDetailId],[GlAccountId],[GlAccountNumber],[GlAccountName],[DebitAmount],[CreditAmount],[IsDebit],
			       [ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[DistributionSetupId],[DistributionName],
			       [JournalTypeNumber],[AccountingPeriodId],[AccountingPeriod],
			       [LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule],
			       [CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId],[SalesOrderNumber],
			       [DocumentId],[DocumentNumber],[StocklineId],[StocklineNumber],[ARControlNumber],[CustomerRef]
			FROM #OriginalEntries

		OPEN curReverse
		FETCH NEXT FROM curReverse INTO @OrigJournalBatchDetailId,@GlAccountId,@GlAccountNumber,@GlAccountName,@DebitAmount,@CreditAmount,@IsDebit,
			@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@DistributionSetupId,@DistributionName,
			@JournalTypeNumber,@AccountingPeriodId,@AccountingPeriod,
			@LotId,@LotNumber,@ReferenceNumber,@ReferenceName,@LocalCurrency,@FXRate,@ForeignCurrency,@ReferenceId,@ReferenceModule,
			@CustomerTypeId,@CustomerType,@OrigCustomerId,@CustomerName,@ItemMasterId,@PartId,@PartNumber,@SalesOrderId,@SalesOrderNumber,
			@DocumentId,@DocumentNumber,@StocklineId,@StocklineNumber,@ARControlNumber,@CustomerRef

		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- [PN-17663] Per-line dbo.BatchDetails insert removed - all reversed lines now share the single
			-- @NewJournalBatchDetailId row inserted once above this loop.
			INSERT INTO [dbo].[CommonBatchDetails]
				([JournalBatchHeaderId],[JournalBatchDetailId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
				 [IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],[ModuleName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
				 [LastMSLevel],[AllMSlevels],[DistributionSetupId],[DistributionName],[JournalTypeNumber],[LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
			VALUES
				(@NewJournalBatchHeaderId,@NewJournalBatchDetailId,@LineNumber,@GlAccountId,@GlAccountNumber,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId,@JournalTypeName,
				 CASE WHEN ISNULL(@IsDebit,0) = 1 THEN 0 ELSE 1 END,
				 ISNULL(@CreditAmount,0),
				 ISNULL(@DebitAmount,0),
				 @ManagementStructureId,@ModuleName,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,
				 @LastMSLevel,@AllMSlevels,@DistributionSetupId,@DistributionName,@NewJournalTypeNumber,@LotId,@LotNumber,@ReferenceNumber,@ReferenceName,@LocalCurrency,@FXRate,@ForeignCurrency,@ReferenceId,@ReferenceModule)

			SET @NewCommonJournalBatchDetailId = SCOPE_IDENTITY()

			IF (ISNULL(@ManagementStructureId,0) > 0 AND ISNULL(@AccountMSModuleId,0) > 0)
			BEGIN
				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @NewCommonJournalBatchDetailId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy, @AccountMSModuleId, 1
			END

			INSERT INTO [dbo].[SalesOrderBatchDetails]
				([JournalBatchDetailId],[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId],[SalesOrderNumber],[DocumentId],[DocumentNumber],[StocklineId],[StocklineNumber],[ARControlNumber],[CustomerRef],[CommonJournalBatchDetailId])
			VALUES
				(@NewJournalBatchDetailId,@NewJournalBatchHeaderId,@CustomerTypeId,@CustomerType,@OrigCustomerId,@CustomerName,@ItemMasterId,@PartId,@PartNumber,@SalesOrderId,@SalesOrderNumber,@DocumentId,@DocumentNumber,@StocklineId,@StocklineNumber,@ARControlNumber,@CustomerRef,@NewCommonJournalBatchDetailId)

			-- Flag the original line as reversed (audit trail only - original Debit/Credit values are left untouched)
			--UPDATE [dbo].[BatchDetails]
			--SET		[IsReversedJE] = 1,
			--		[UpdatedBy] = @UpdatedBy,
			--		[UpdatedDate] = GETUTCDATE()
			--WHERE	[JournalBatchDetailId] = @OrigJournalBatchDetailId

			-- [PN-17663] @TotalDebit/@TotalCredit are pre-summed from #OriginalEntries above (not accumulated
			-- per-line here anymore) since dbo.BatchDetails now gets one aggregated row, not one per line.
			SET @LineNumber = @LineNumber + 1

			FETCH NEXT FROM curReverse INTO @OrigJournalBatchDetailId,@GlAccountId,@GlAccountNumber,@GlAccountName,@DebitAmount,@CreditAmount,@IsDebit,
				@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@DistributionSetupId,@DistributionName,
				@JournalTypeNumber,@AccountingPeriodId,@AccountingPeriod,
				@LotId,@LotNumber,@ReferenceNumber,@ReferenceName,@LocalCurrency,@FXRate,@ForeignCurrency,@ReferenceId,@ReferenceModule,
				@CustomerTypeId,@CustomerType,@OrigCustomerId,@CustomerName,@ItemMasterId,@PartId,@PartNumber,@SalesOrderId,@SalesOrderNumber,
				@DocumentId,@DocumentNumber,@StocklineId,@StocklineNumber,@ARControlNumber,@CustomerRef
		END

		CLOSE curReverse
		DEALLOCATE curReverse

		-- The header now represents both the original entries AND this reversal, so add to whatever totals
		-- it already has instead of overwriting them (overwriting would erase the original invoice's totals).
		UPDATE [dbo].[BatchHeader]
		SET		[TotalDebit] = ISNULL([TotalDebit],0) + @TotalDebit,
				[TotalCredit] = ISNULL([TotalCredit],0) + @TotalCredit,
				[TotalBalance] = (ISNULL([TotalDebit],0) + @TotalDebit) - (ISNULL([TotalCredit],0) + @TotalCredit),
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETUTCDATE()
		WHERE	[JournalBatchHeaderId] = @NewJournalBatchHeaderId

		SET @ReversalMessage = CAST(@LineCountReversed AS VARCHAR(10)) + ' PAS accounting line(s) reversed successfully.'

		DROP TABLE #OriginalEntries

	END
	END TRY
	BEGIN CATCH
		IF CURSOR_STATUS('local','curReverse') >= -1
		BEGIN
			CLOSE curReverse
			DEALLOCATE curReverse
		END
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_ReverseSOInvoiceAccountingEntry'
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + ISNULL(CONVERT(VARCHAR(30),@BillingInvoicingId), '') + '@Parameter2= ''' + ISNULL(@UpdatedBy, '') + ''
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