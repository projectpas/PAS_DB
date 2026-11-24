/*********************
 ** File:   [USP_ReverseVendorProformaInvoiceAccountingEntry]
 ** Author:   Moin Bloch
 ** Description: Reverses the PAS accounting (GL) entries created when a Vendor Proforma Invoice was posted
 **              (USP_PostVendorProforma_BatchDetails). Reads the posted lines from
 **              dbo.VendorProformaInvoiceBatchDetails -> dbo.CommonBatchDetails and mirrors them with
 **              Debit/Credit swapped into TODAY's open VPI batch. Original rows are left untouched (audit trail).
 **              The new dbo.BatchDetails row is flagged IsReversedJE = 1 and each reversal line is linked back to
 **              the invoice in dbo.VendorProformaInvoiceBatchDetails (Memo = 'REVERSAL OF <original JE Number>').
 **
 **              Double-reversal guard: only original (IsReversedJE = 0) entries created AFTER the invoice's latest
 **              reversal are picked up, so each posting is reversed exactly once (post -> reopen -> post -> reopen safe).
 **              If nothing is left to reverse, this SP is a safe no-op.
 ** Purpose:  Vendor Proforma Invoice - Re-Open - Accounting Reversal
 ** Date:   19-Nov-2026

 **********************
  ** Change History
 **********************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				-------------------------------
    1    19-Nov-2026  Moin Bloch			Created

    EXEC [dbo].[USP_ReverseVendorProformaInvoiceAccountingEntry] @VendorProformaInvoiceId = 47, @MasterCompanyId = 1, @UpdatedBy = 'ADMIN User'
**********************/
CREATE   PROCEDURE [dbo].[USP_ReverseVendorProformaInvoiceAccountingEntry]
	@VendorProformaInvoiceId BIGINT,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @LastReversalDetailId BIGINT = 0

		SELECT @LastReversalDetailId = ISNULL(MAX(VBD.[JournalBatchDetailId]), 0)
		FROM [dbo].[VendorProformaInvoiceBatchDetails] VBD WITH(NOLOCK)
		INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON BD.[JournalBatchDetailId] = VBD.[JournalBatchDetailId]
		WHERE VBD.[VendorProformaInvoiceId] = @VendorProformaInvoiceId AND ISNULL(BD.[IsReversedJE], 0) = 1

		IF OBJECT_ID('tempdb..#OriginalEntries') IS NOT NULL DROP TABLE #OriginalEntries

		SELECT	VBD.[JournalBatchDetailId], VBD.[VendorId], VBD.[VendorName], VBD.[VendorProformaInvoiceNo],
				BD.[JournalTypeId], BD.[JournalTypeName], BD.[JournalTypeNumber], BD.[AccountingPeriodId], BD.[AccountingPeriod],
				CBD.[GlAccountId], CBD.[GlAccountNumber], CBD.[GlAccountName], CBD.[IsDebit], CBD.[DebitAmount], CBD.[CreditAmount],
				CBD.[ManagementStructureId], CBD.[ModuleName], CBD.[LastMSLevel], CBD.[AllMSlevels], CBD.[DistributionSetupId], CBD.[DistributionName],
				CBD.[ReferenceNumber], CBD.[ReferenceName], CBD.[LocalCurrency], CBD.[FXRate], CBD.[ForeignCurrency], CBD.[ReferenceId], CBD.[ReferenceModule]
		INTO #OriginalEntries
		FROM [dbo].[VendorProformaInvoiceBatchDetails] VBD WITH(NOLOCK)
		INNER JOIN [dbo].[CommonBatchDetails] CBD WITH(NOLOCK) ON CBD.[CommonJournalBatchDetailId] = VBD.[CommonJournalBatchDetailId]
		INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON BD.[JournalBatchDetailId] = VBD.[JournalBatchDetailId]
		WHERE VBD.[VendorProformaInvoiceId] = @VendorProformaInvoiceId
		  AND ISNULL(BD.[IsReversedJE], 0) = 0
		  AND VBD.[JournalBatchDetailId] > @LastReversalDetailId
		  AND ISNULL(CBD.[IsDeleted], 0) = 0

		IF EXISTS (SELECT 1 FROM #OriginalEntries)
		BEGIN
			DECLARE @AccountMSModuleId INT, @JournalTypeId BIGINT, @JournalTypeName VARCHAR(200), @JournalTypeCode VARCHAR(200)
			DECLARE @AccountingPeriodId BIGINT, @AccountingPeriod VARCHAR(100), @LegalEntityId BIGINT
			DECLARE @StatusId INT, @StatusName VARCHAR(200), @JournalBatchHeaderId BIGINT, @HeaderCurrentNumber BIGINT, @IsNewHeader BIT = 0
			DECLARE @JECurrentNo BIGINT, @NewJournalTypeNumber VARCHAR(50), @NewJournalBatchDetailId BIGINT, @LineNumber BIGINT = 1
			DECLARE @TotalDebit DECIMAL(18,2) = 0, @TotalCredit DECIMAL(18,2) = 0, @IsAutoPost BIT = 0

			SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Accounting'
			SELECT TOP 1 @JournalTypeId = [JournalTypeId], @JournalTypeName = [JournalTypeName], @AccountingPeriodId = [AccountingPeriodId], @AccountingPeriod = [AccountingPeriod] FROM #OriginalEntries
			SELECT @JournalTypeCode = [JournalTypeCode] FROM [dbo].[JournalType] WITH(NOLOCK) WHERE [ID] = @JournalTypeId
			SELECT @StatusId = [Id], @StatusName = [Name] FROM [dbo].[BatchStatus] WITH(NOLOCK) WHERE [Name] = 'Open'

			SELECT @IsAutoPost = ISNULL(MAX(CAST(ISNULL(DS.[IsAutoPost], 0) AS INT)), 0)
			FROM #OriginalEntries OE INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON DS.[ID] = OE.[DistributionSetupId]

			-- Reversal is dated today, so use today's accounting period for the invoice's legal entity (fallback: original period)
			SELECT TOP 1 @LegalEntityId = MSL.[LegalEntityId]
			FROM [dbo].[NonPOInvoiceManagementStructureDetails] MSD WITH(NOLOCK)
			INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON MSD.[Level1Id] = MSL.[ID]
			INNER JOIN [dbo].[ManagementStructureModule] MSM WITH(NOLOCK) ON MSM.[ManagementStructureModuleId] = MSD.[ModuleID] AND MSM.[ModuleName] = 'VendorProformaInvoice'
			WHERE MSD.[ReferenceID] = @VendorProformaInvoiceId

			SELECT TOP 1 @AccountingPeriodId = [AccountingCalendarId], @AccountingPeriod = [PeriodName]
			FROM [dbo].[AccountingCalendar] WITH(NOLOCK)
			WHERE [IsDeleted] = 0 AND [LegalEntityId] = @LegalEntityId AND [MasterCompanyId] = @MasterCompanyId
			  AND CAST(GETUTCDATE() AS DATE) BETWEEN CAST([FromDate] AS DATE) AND CAST([ToDate] AS DATE)

			-- New JE number (same CodeTypeId = 74 mechanism as posting)
			SELECT @JECurrentNo = CASE WHEN CP.[CurrentNummber] > 0 THEN CAST(CP.[CurrentNummber] AS BIGINT) + 1 ELSE CAST(CP.[StartsFrom] AS BIGINT) + 1 END
			FROM [dbo].[CodePrefixes] CP WITH(NOLOCK)
			WHERE CP.[CodeTypeId] = 74 AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0

			IF (@JECurrentNo IS NOT NULL)
			BEGIN
				SELECT @NewJournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@JECurrentNo, CP.[CodePrefix], CP.[CodeSufix]))
				FROM [dbo].[CodePrefixes] CP WITH(NOLOCK)
				WHERE CP.[CodeTypeId] = 74 AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0

				UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @JECurrentNo WHERE [CodeTypeId] = 74 AND [MasterCompanyId] = @MasterCompanyId
			END

			-- Today's open batch for this journal type (same day-bucketing as posting), else create one
			SELECT TOP 1 @JournalBatchHeaderId = [JournalBatchHeaderId], @HeaderCurrentNumber = [CurrentNumber]
			FROM [dbo].[BatchHeader] WITH(NOLOCK)
			WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId] = @MasterCompanyId AND [StatusId] = @StatusId
			  AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [AccountingPeriodId] = @AccountingPeriodId
			ORDER BY [JournalBatchHeaderId] DESC

			IF (@JournalBatchHeaderId IS NULL)
			BEGIN
				SELECT TOP 1 @HeaderCurrentNumber = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE 1 END
				FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY [JournalBatchHeaderId] DESC

				SET @HeaderCurrentNumber = ISNULL(@HeaderCurrentNumber, 1)

				INSERT INTO [dbo].[BatchHeader]
					([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],[AccountingPeriodId],[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],
					 [TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
				VALUES
					(@JournalTypeCode + ' ' + CASE WHEN @HeaderCurrentNumber > 99 THEN CAST(@HeaderCurrentNumber AS VARCHAR(50))
												   WHEN @HeaderCurrentNumber > 9 THEN CONCAT('0', @HeaderCurrentNumber)
												   ELSE CONCAT('00', @HeaderCurrentNumber) END,
					 @HeaderCurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypeName,
					 0,0,0,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@JournalTypeCode)

				SET @JournalBatchHeaderId = SCOPE_IDENTITY()
				SET @IsNewHeader = 1
			END
			ELSE
			BEGIN
				SELECT TOP 1 @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE 1 END
				FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId ORDER BY [JournalBatchDetailId] DESC
			END

			-- Debit/Credit swapped
			SELECT @TotalDebit = SUM(ISNULL([CreditAmount], 0)), @TotalCredit = SUM(ISNULL([DebitAmount], 0)) FROM #OriginalEntries

			INSERT INTO [dbo].[BatchDetails]
				([JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],
				 [TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],
				 [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AccountingPeriodId],[AccountingPeriod],[IsReversedJE])
			SELECT TOP 1 @NewJournalTypeNumber,@JECurrentNo,0,NULL,@JournalBatchHeaderId,@LineNumber,0,NULL,NULL,
				 GETUTCDATE(),GETUTCDATE(),@JournalTypeId,@JournalTypeName,1,@TotalDebit,@TotalCredit,[ManagementStructureId],[ModuleName],NULL,NULL,
				 @MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod,1
			FROM #OriginalEntries

			SET @NewJournalBatchDetailId = SCOPE_IDENTITY()

			DECLARE @OrigJENumber VARCHAR(50), @VendorId BIGINT, @VendorName VARCHAR(150), @InvoiceNo VARCHAR(150)
			DECLARE @GlAccountId BIGINT, @GlAccountNumber VARCHAR(200), @GlAccountName VARCHAR(200), @IsDebit BIT, @DebitAmount DECIMAL(18,2), @CreditAmount DECIMAL(18,2)
			DECLARE @ManagementStructureId BIGINT, @ModuleName VARCHAR(200), @LastMSLevel VARCHAR(200), @AllMSlevels VARCHAR(MAX), @DistributionSetupId INT, @DistributionName VARCHAR(200)
			DECLARE @ReferenceNumber VARCHAR(150), @ReferenceName VARCHAR(256), @LocalCurrency VARCHAR(20), @FXRate DECIMAL(18,2), @ForeignCurrency VARCHAR(20), @ReferenceId BIGINT, @ReferenceModule VARCHAR(100)
			DECLARE @NewCommonJournalBatchDetailId BIGINT

			DECLARE curReverse CURSOR LOCAL FAST_FORWARD FOR
				SELECT [JournalTypeNumber],[VendorId],[VendorName],[VendorProformaInvoiceNo],[GlAccountId],[GlAccountNumber],[GlAccountName],[IsDebit],[DebitAmount],[CreditAmount],
					   [ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[DistributionSetupId],[DistributionName],
					   [ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule]
				FROM #OriginalEntries

			OPEN curReverse
			FETCH NEXT FROM curReverse INTO @OrigJENumber,@VendorId,@VendorName,@InvoiceNo,@GlAccountId,@GlAccountNumber,@GlAccountName,@IsDebit,@DebitAmount,@CreditAmount,
				@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@DistributionSetupId,@DistributionName,
				@ReferenceNumber,@ReferenceName,@LocalCurrency,@FXRate,@ForeignCurrency,@ReferenceId,@ReferenceModule

			WHILE @@FETCH_STATUS = 0
			BEGIN
				INSERT INTO [dbo].[CommonBatchDetails]
					([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],
					 [GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
					 [IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],
					 [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
				VALUES
					(@NewJournalBatchDetailId,@NewJournalTypeNumber,@JECurrentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1,
					 @GlAccountId,@GlAccountNumber,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId,@JournalTypeName,
					 CASE WHEN ISNULL(@IsDebit, 0) = 1 THEN 0 ELSE 1 END, ISNULL(@CreditAmount, 0), ISNULL(@DebitAmount, 0),
					 @ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId,
					 @UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReferenceNumber,@ReferenceName,@LocalCurrency,@FXRate,@ForeignCurrency,@ReferenceId,@ReferenceModule)

				SET @NewCommonJournalBatchDetailId = SCOPE_IDENTITY()

				IF (ISNULL(@ManagementStructureId, 0) > 0 AND ISNULL(@AccountMSModuleId, 0) > 0)
					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @NewCommonJournalBatchDetailId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy, @AccountMSModuleId, 1

				INSERT INTO [dbo].[VendorProformaInvoiceBatchDetails]
					([JournalBatchDetailId],[JournalBatchHeaderId],[CommonJournalBatchDetailId],[VendorId],[VendorName],[VendorProformaInvoiceId],[VendorProformaInvoiceNo],[Memo])
				VALUES
					(@NewJournalBatchDetailId,@JournalBatchHeaderId,@NewCommonJournalBatchDetailId,@VendorId,@VendorName,@VendorProformaInvoiceId,@InvoiceNo,'REVERSAL OF ' + ISNULL(@OrigJENumber, ''))

				FETCH NEXT FROM curReverse INTO @OrigJENumber,@VendorId,@VendorName,@InvoiceNo,@GlAccountId,@GlAccountNumber,@GlAccountName,@IsDebit,@DebitAmount,@CreditAmount,
					@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@DistributionSetupId,@DistributionName,
					@ReferenceNumber,@ReferenceName,@LocalCurrency,@FXRate,@ForeignCurrency,@ReferenceId,@ReferenceModule
			END

			CLOSE curReverse
			DEALLOCATE curReverse

			-- Recalculate header totals the same way posting does
			SELECT @TotalDebit = SUM(ISNULL([DebitAmount], 0)), @TotalCredit = SUM(ISNULL([CreditAmount], 0))
			FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId AND [IsDeleted] = 0

			UPDATE [dbo].[BatchHeader]
			SET [TotalDebit] = @TotalDebit, [TotalCredit] = @TotalCredit, [TotalBalance] = @TotalDebit - @TotalCredit, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
			WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId

			-- Auto post, same rule as USP_PostVendorProforma_BatchDetails
			IF (@IsAutoPost = 1 AND @IsNewHeader = 1)
				EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId, @UpdatedBy;
			IF (@IsAutoPost = 1 AND @IsNewHeader = 0)
				EXEC [dbo].[USP_UpdateCommonBatchStatus] @NewJournalBatchDetailId, @UpdatedBy, @AccountingPeriodId, @AccountingPeriod;
		END

		DROP TABLE #OriginalEntries
	END
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF CURSOR_STATUS('local','curReverse') >= -1
		BEGIN
			CLOSE curReverse
			DEALLOCATE curReverse
		END
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_ReverseVendorProformaInvoiceAccountingEntry'
		, @ProcedureParameters VARCHAR(3000)  = '@VendorProformaInvoiceId = ''' + ISNULL(CONVERT(VARCHAR(30), @VendorProformaInvoiceId), '') + ''', @UpdatedBy = ''' + ISNULL(@UpdatedBy, '') + ''''
		, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			@DatabaseName           = @DatabaseName
			, @AdhocComments          = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName        =  @ApplicationName
			, @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END
