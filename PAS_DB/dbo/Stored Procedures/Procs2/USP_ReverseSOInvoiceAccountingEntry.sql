/*********************
 ** File:   [USP_ReverseSOInvoiceAccountingEntry]
 ** Author:   Rajesh Gami
 ** Description: This stored procedure reverses the PAS accounting (GL) entries that were
 **              created when a Sales Order invoice (Standard or Proforma) was posted.
 **              It reads the exact GL rows already posted for the invoice
 **              (dbo.SalesOrderBatchDetails.DocumentId = @BillingInvoicingId) and mirrors
 **              them into a brand new journal batch with Debit/Credit swapped - the original
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

    EXEC [dbo].[USP_ReverseSOInvoiceAccountingEntry] @BillingInvoicingId = 8998, @MasterCompanyId = 1, @UpdatedBy = 'ADMIN User'

**********************/
CREATE PROCEDURE [dbo].[USP_ReverseSOInvoiceAccountingEntry]
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

		DECLARE @JournalTypeId BIGINT, @JournalTypeName VARCHAR(200), @Module VARCHAR(50), @HeaderCustomerTypeId INT
		SELECT TOP 1 @JournalTypeId = [JournalTypeId], @JournalTypeName = [JournalTypeName], @Module = [Module], @HeaderCustomerTypeId = [HeaderCustomerTypeId] FROM #OriginalEntries

		DECLARE @StatusId BIGINT, @StatusName VARCHAR(200)
		SELECT @StatusId = [Id], @StatusName = [Name] FROM [dbo].[BatchStatus] WITH(NOLOCK) WHERE [Name] = 'Open'

		-- Batch Ref used to be generated for these reversal batches as a hardcoded literal,
		-- '<JournalTypeName> (REVERSED)' (e.g. 'SO Invoice (REVERSED)') - this bled through into
		-- the UI even on rows that were NOT reversal lines, because a later same-day re-invoice
		-- would end up reusing this same batch header (see the matching fix in
		-- USP_BatchTriggerBasedonSOInvoiceNew). Whether a line is a reversal is already tracked
		-- correctly and independently via BatchDetails.IsReversedJE, so the raw Batch Ref no
		-- longer needs to carry that information - it's now generated the exact same dynamic way
		-- normal posting does (e.g. 'SOI 1637'), and the UI adds its own "(Reverse)" label from
		-- the IsReversedJE flag.
		DECLARE @JournalTypeCode VARCHAR(50)
		SELECT @JournalTypeCode = [JournalTypeCode] FROM [dbo].[JournalType] WITH(NOLOCK) WHERE [ID] = @JournalTypeId

		DECLARE @CurrentNumber BIGINT, @PaddedBatchNumber VARCHAR(100)
		SELECT TOP 1 @CurrentNumber = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE 1 END
		FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY [JournalBatchHeaderId] DESC

		-- Same zero-padding convention as normal posting (USP_BatchTriggerBasedonSOInvoiceNew):
		-- 3 digits while <= 99, unpadded once past 99.
		IF (CAST(@CurrentNumber AS BIGINT) > 99)
		BEGIN
			SET @PaddedBatchNumber = CAST(@CurrentNumber AS VARCHAR(100))
		END
		ELSE IF (CAST(@CurrentNumber AS BIGINT) > 9)
		BEGIN
			SET @PaddedBatchNumber = CONCAT('0', CAST(@CurrentNumber AS VARCHAR(50)))
		END
		ELSE
		BEGIN
			SET @PaddedBatchNumber = CONCAT('00', CAST(@CurrentNumber AS VARCHAR(50)))
		END

		DECLARE @BatchName VARCHAR(200) = CAST(ISNULL(@JournalTypeCode,'JE') + ' ' + @PaddedBatchNumber AS VARCHAR(200))

		DECLARE @NewJournalBatchHeaderId BIGINT

		INSERT INTO [dbo].[BatchHeader]
			([BatchName],[CurrentNumber],[EntryDate],[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module],[CustomerTypeId])
		VALUES
			(@BatchName,@CurrentNumber,GETUTCDATE(),@StatusId,@StatusName,@JournalTypeId,@JournalTypeName,0,0,0,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@Module,@HeaderCustomerTypeId)

		SET @NewJournalBatchHeaderId = SCOPE_IDENTITY()

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
			INSERT INTO [dbo].[BatchDetails]
				([JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
				 [IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],[ModuleName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
				 [LastMSLevel],[AllMSlevels],[DistributionSetupId],[DistributionName],[JournalTypeNumber],[CurrentNumber],[StatusId],[AccountingPeriodId],[AccountingPeriod],[IsReversedJE])
			VALUES
				(@NewJournalBatchHeaderId,@LineNumber,@GlAccountId,@GlAccountNumber,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId,@JournalTypeName,
				 CASE WHEN ISNULL(@IsDebit,0) = 1 THEN 0 ELSE 1 END,
				 ISNULL(@CreditAmount,0),
				 ISNULL(@DebitAmount,0),
				 @ManagementStructureId,@ModuleName,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,
				 @LastMSLevel,@AllMSlevels,@DistributionSetupId,@DistributionName,@JournalTypeNumber,@CurrentNumber,1,@AccountingPeriodId,@AccountingPeriod,1)

			SET @NewJournalBatchDetailId = SCOPE_IDENTITY()

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
				 @LastMSLevel,@AllMSlevels,@DistributionSetupId,@DistributionName,@JournalTypeNumber,@LotId,@LotNumber,@ReferenceNumber,@ReferenceName,@LocalCurrency,@FXRate,@ForeignCurrency,@ReferenceId,@ReferenceModule)

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

			SET @TotalDebit = @TotalDebit + ISNULL(@CreditAmount,0)
			SET @TotalCredit = @TotalCredit + ISNULL(@DebitAmount,0)
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

		UPDATE [dbo].[BatchHeader]
		SET		[TotalDebit] = @TotalDebit,
				[TotalCredit] = @TotalCredit,
				[TotalBalance] = (@TotalDebit - @TotalCredit),
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
