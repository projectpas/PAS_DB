/*********************
 ** File:   [USP_ReverseSOInvoiceAccountingEntry]
 ** Author:   Rajesh Gami
 ** Description: This stored procedure reverses the PAS accounting (GL) entries that were
 **              created when a Sales Order invoice (Standard or Proforma) was posted.
 **              It reads the exact GL rows already posted for the invoice
 **              (dbo.SalesOrderBatchDetails.DocumentId = @BillingInvoicingId) and mirrors
 **              them into a brand new journal batch with Debit/Credit swapped - the original
 **              rows are left untouched (audit trail) and only flagged as reversed.
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

    EXEC [dbo].[USP_ReverseSOInvoiceAccountingEntry] @BillingInvoicingId = 8998, @MasterCompanyId = 1, @UpdatedBy = 'ADMIN User'

**********************/
CREATE PROCEDURE [dbo].[USP_ReverseSOInvoiceAccountingEntry]
	@BillingInvoicingId BIGINT,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN

		-- Already reversed for this invoice? Do not reverse twice.
		IF EXISTS (SELECT 1 FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [BillingInvoicingId] = @BillingInvoicingId AND ISNULL([IsReversedJE],0) = 1)
		BEGIN
			RETURN
		END

		IF OBJECT_ID('tempdb..#OriginalEntries') IS NOT NULL DROP TABLE #OriginalEntries

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
			BD.[LineNumber],
			BD.[GlAccountId],
			BD.[GlAccountNumber],
			BD.[GlAccountName],
			BD.[JournalTypeId],
			BD.[JournalTypeName],
			BD.[IsDebit],
			BD.[DebitAmount],
			BD.[CreditAmount],
			BD.[ManagementStructureId],
			BD.[ModuleName],
			BD.[LastMSLevel],
			BD.[AllMSlevels],
			BD.[DistributionSetupId],
			BD.[DistributionName],
			BD.[JournalTypeNumber],
			BD.[AccountingPeriodId],
			BD.[AccountingPeriod],
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
		INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON BD.[JournalBatchDetailId] = SOD.[JournalBatchDetailId]
		LEFT JOIN [dbo].[CommonBatchDetails] CBD WITH(NOLOCK) ON CBD.[CommonJournalBatchDetailId] = SOD.[CommonJournalBatchDetailId]
		INNER JOIN [dbo].[BatchHeader] BH WITH(NOLOCK) ON BH.[JournalBatchHeaderId] = SOD.[JournalBatchHeaderId]
		WHERE SOD.[DocumentId] = @BillingInvoicingId
		  AND ISNULL(BD.[IsDeleted],0) = 0
		  AND ISNULL(BD.[IsReversedJE],0) = 0

		-- Nothing was ever posted for this invoice (bypassed / not configured) - nothing to reverse.
		IF NOT EXISTS(SELECT 1 FROM #OriginalEntries)
		BEGIN
			DROP TABLE #OriginalEntries
			RETURN
		END

		DECLARE @AccountMSModuleId INT
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Accounting'

		DECLARE @JournalTypeId BIGINT, @JournalTypeName VARCHAR(200), @Module VARCHAR(50), @HeaderCustomerTypeId INT
		SELECT TOP 1 @JournalTypeId = [JournalTypeId], @JournalTypeName = [JournalTypeName], @Module = [Module], @HeaderCustomerTypeId = [HeaderCustomerTypeId] FROM #OriginalEntries

		DECLARE @StatusId BIGINT, @StatusName VARCHAR(200)
		SELECT @StatusId = [Id], @StatusName = [Name] FROM [dbo].[BatchStatus] WITH(NOLOCK) WHERE [Name] = 'Open'

		DECLARE @CurrentNumber BIGINT
		SELECT TOP 1 @CurrentNumber = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE 1 END
		FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY [JournalBatchHeaderId] DESC

		DECLARE @BatchName VARCHAR(200) = CAST(ISNULL(@JournalTypeName,'REV') + ' REV ' + CAST(@CurrentNumber AS VARCHAR(50)) AS VARCHAR(200))

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
				 [LastMSLevel],[AllMSlevels],[DistributionSetupId],[DistributionName],[JournalTypeNumber],[CurrentNumber],[StatusId],[AccountingPeriodId],[AccountingPeriod])
			VALUES
				(@NewJournalBatchHeaderId,@LineNumber,@GlAccountId,@GlAccountNumber,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId,@JournalTypeName,
				 CASE WHEN ISNULL(@IsDebit,0) = 1 THEN 0 ELSE 1 END,
				 ISNULL(@CreditAmount,0),
				 ISNULL(@DebitAmount,0),
				 @ManagementStructureId,@ModuleName,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,
				 @LastMSLevel,@AllMSlevels,@DistributionSetupId,@DistributionName,@JournalTypeNumber,@CurrentNumber,1,@AccountingPeriodId,@AccountingPeriod)

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
			UPDATE [dbo].[BatchDetails]
			SET		[IsReversedJE] = 1,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE()
			WHERE	[JournalBatchDetailId] = @OrigJournalBatchDetailId

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

		UPDATE [dbo].[BillingInvoicing]
		SET		[IsReversedJE] = 1,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETUTCDATE()
		WHERE	[BillingInvoicingId] = @BillingInvoicingId

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
