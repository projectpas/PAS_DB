/*************************************************************           
 ** File:   [USP_ReallocateWOInvoiceAccountingPeriod]           
 ** Author:   Vishal Suthar
 ** Description: Update Batch entry date for WO Invoice
 ** Purpose:         
 ** Date:   11/09/2026
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    11/09/2026		Vishal Suthar	Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_ReallocateWOInvoiceAccountingPeriod]
	@BillingInvoicingId BIGINT,
	@NewInvoiceDate DATETIME2(7),
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(200)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE @ManagementStructureId BIGINT = NULL;
		DECLARE @LegalEntityId BIGINT = NULL;

		SELECT @ManagementStructureId = [ManagementStructureId]
		FROM [dbo].[BillingInvoicing] WITH(NOLOCK)
		WHERE [BillingInvoicingId] = @BillingInvoicingId;

		SELECT @LegalEntityId = [LegalEntityId]
		FROM [dbo].[ManagementStructure] WITH(NOLOCK)
		WHERE [ManagementStructureId] = @ManagementStructureId;

		DECLARE @IsAccountByPass BIT = 0;
		DECLARE @IsPASAccounting BIT = 0;
		DECLARE @WOIJournalTypeId BIGINT = NULL;
		DECLARE @OpenStatusId INT = NULL;

		SELECT @IsAccountByPass = ISNULL([IsAccountByPass], 0)
		FROM [dbo].[MasterCompany] WITH(NOLOCK)
		WHERE [MasterCompanyId] = @MasterCompanyId;

		SET @IsPASAccounting = CASE WHEN @IsAccountByPass = 0 THEN 1 ELSE 0 END;

		IF(@IsPASAccounting = 0)
		BEGIN
			COMMIT TRANSACTION;
			RETURN(0);
		END

		-- NOTE: assumes JournalTypeCode 'WOI' matches BatchHeader.JournalTypeName = 'WO Invoice' seen in sample data - please confirm.
		SELECT @WOIJournalTypeId = ID FROM [dbo].[JournalType] WITH(NOLOCK) WHERE UPPER([JournalTypeCode]) = UPPER('WOI');
		SELECT @OpenStatusId = Id FROM [dbo].[BatchStatus] WITH(NOLOCK) WHERE [Name] = 'Open';

		DECLARE @NewAccountingPeriodId BIGINT = NULL;
		DECLARE @NewAccountingPeriod VARCHAR(100) = NULL;
		DECLARE @NewPeriodClosed BIT = 0;

		SELECT TOP 1
			   @NewAccountingPeriodId = AccountingCalendarId,
			   @NewAccountingPeriod   = PeriodName,
			   @NewPeriodClosed       = CASE WHEN UPPER(ISNULL([Status], '')) = 'CLOSED' THEN 1 ELSE 0 END
		FROM [dbo].[AccountingCalendar] WITH(NOLOCK)
		WHERE [IsDeleted] = 0
		  AND [LegalEntityId] = @LegalEntityId
		  AND [MasterCompanyId] = @MasterCompanyId
		  AND CAST(@NewInvoiceDate AS DATE) >= CAST([FromDate] AS DATE)
		  AND CAST(@NewInvoiceDate AS DATE) <= CAST([ToDate] AS DATE);

		IF(@NewAccountingPeriodId IS NULL OR @NewAccountingPeriodId = 0)
		BEGIN
			RAISERROR('No accounting period is defined for the new Invoice Date. Invoice Date change was not applied to the accounting entry.', 16, 1);
			ROLLBACK TRANSACTION;
			RETURN(1);
		END

		IF(@NewPeriodClosed = 1)
		BEGIN
			RAISERROR('The accounting period covering the new Invoice Date is closed. This invoice cannot be re-dated into a closed period.', 16, 1);
			ROLLBACK TRANSACTION;
			RETURN(1);
		END

		IF OBJECT_ID(N'tempdb..#tmpExistingEntries') IS NOT NULL DROP TABLE #tmpExistingEntries;
		CREATE TABLE #tmpExistingEntries
		(
			JournalBatchDetailId BIGINT,
			JournalBatchHeaderId BIGINT,
			CommonJournalBatchDetailId BIGINT,
			CurrentStatusId INT
		);

		-- ASSUMPTION TO CONFIRM: WorkOrderBatchDetails.InvoiceId is populated with BillingInvoicingId
		-- for the actual invoice GL entries (as opposed to the WIP/material/labor entries where it's NULL).
		INSERT INTO #tmpExistingEntries (JournalBatchDetailId, JournalBatchHeaderId, CommonJournalBatchDetailId, CurrentStatusId)
		SELECT DISTINCT WOD.[JournalBatchDetailId], BD.[JournalBatchHeaderId], WOD.[CommonJournalBatchDetailId], BH.[StatusId]
		FROM [dbo].[WorkOrderBatchDetails] WOD WITH(NOLOCK)
		INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON BD.[JournalBatchDetailId] = WOD.[JournalBatchDetailId]
		INNER JOIN [dbo].[BatchHeader] BH WITH(NOLOCK) ON BH.[JournalBatchHeaderId] = BD.[JournalBatchHeaderId]
		WHERE WOD.[InvoiceId] = @BillingInvoicingId
		  AND BD.[JournalTypeId] = @WOIJournalTypeId
		  AND BD.[MasterCompanyId] = @MasterCompanyId
		  AND ISNULL(BD.[IsReversedJE], 0) = 0
		  AND ISNULL(BD.[IsDeleted], 0) = 0;

		IF NOT EXISTS(SELECT 1 FROM #tmpExistingEntries)
		BEGIN
			DROP TABLE #tmpExistingEntries;
			COMMIT TRANSACTION;
			RETURN(0);
		END

		IF EXISTS(SELECT 1 FROM #tmpExistingEntries WHERE CurrentStatusId <> @OpenStatusId)
		BEGIN
			RAISERROR('This invoice''s accounting entry has already been posted/finalized and cannot be re-dated automatically. Please reverse and re-post to move it to the new period.', 16, 1);
			DROP TABLE #tmpExistingEntries;
			ROLLBACK TRANSACTION;
			RETURN(1);
		END

		DECLARE @LoopJBDId BIGINT, @LoopJBHId BIGINT, @LoopCommonId BIGINT;
		DECLARE @CurrentHeaderPeriodId BIGINT;
		DECLARE @TargetHeaderId BIGINT;

		DECLARE entry_cursor CURSOR FAST_FORWARD FOR
			SELECT JournalBatchDetailId, JournalBatchHeaderId, CommonJournalBatchDetailId FROM #tmpExistingEntries;

		OPEN entry_cursor;
		FETCH NEXT FROM entry_cursor INTO @LoopJBDId, @LoopJBHId, @LoopCommonId;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @CurrentHeaderPeriodId = ISNULL([AccountingPeriodId], 0) FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalBatchHeaderId] = @LoopJBHId;

			IF(@CurrentHeaderPeriodId = @NewAccountingPeriodId)
			BEGIN
				UPDATE [dbo].[BatchDetails]
				   SET [TransactionDate] = @NewInvoiceDate,
					   [UpdatedDate] = GETUTCDATE(),
					   [UpdatedBy] = @UpdatedBy
				 WHERE [JournalBatchDetailId] = @LoopJBDId;

				UPDATE [dbo].[CommonBatchDetails]
				   SET [TransactionDate] = @NewInvoiceDate,
					   [UpdatedDate] = GETUTCDATE(),
					   [UpdatedBy] = @UpdatedBy
				 WHERE [CommonJournalBatchDetailId] = @LoopCommonId;
			END
			ELSE
			BEGIN
				SELECT TOP 1 @TargetHeaderId = BH2.[JournalBatchHeaderId]
				FROM [dbo].[BatchHeader] BH2 WITH(NOLOCK)
				INNER JOIN [dbo].[BatchHeader] BHOrig WITH(NOLOCK) ON BHOrig.[JournalBatchHeaderId] = @LoopJBHId
				WHERE BH2.[JournalTypeId] = BHOrig.[JournalTypeId]
				  AND BH2.[MasterCompanyId] = @MasterCompanyId
				  AND BH2.[StatusId] = @OpenStatusId
				  AND BH2.[AccountingPeriodId] = @NewAccountingPeriodId
				  AND ISNULL(BH2.[CustomerTypeId], -1) = ISNULL(BHOrig.[CustomerTypeId], -1)
				  AND NOT EXISTS (SELECT 1 FROM [dbo].[BatchDetails] BDChk WITH(NOLOCK) WHERE BDChk.[JournalBatchHeaderId] = BH2.[JournalBatchHeaderId] AND ISNULL(BDChk.[IsReversedJE],0) = 1);

				IF(@TargetHeaderId IS NULL)
				BEGIN
					INSERT INTO [dbo].[BatchHeader]
						([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],[AccountingPeriodId],[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module],[CustomerTypeId])
					SELECT
						[BatchName] + '-RD',
						[CurrentNumber], GETUTCDATE(), @NewAccountingPeriod, @NewAccountingPeriodId, [StatusId], [StatusName], [JournalTypeId], [JournalTypeName],
						0, 0, 0, [MasterCompanyId], @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, [Module], [CustomerTypeId]
					FROM [dbo].[BatchHeader] WITH(NOLOCK)
					WHERE [JournalBatchHeaderId] = @LoopJBHId;

					SET @TargetHeaderId = SCOPE_IDENTITY();
				END

				UPDATE [dbo].[BatchDetails]
				   SET [JournalBatchHeaderId] = @TargetHeaderId,
					   [TransactionDate] = @NewInvoiceDate,
					   [AccountingPeriodId] = @NewAccountingPeriodId,
					   [AccountingPeriod] = @NewAccountingPeriod,
					   [UpdatedDate] = GETUTCDATE(),
					   [UpdatedBy] = @UpdatedBy
				 WHERE [JournalBatchDetailId] = @LoopJBDId;

				UPDATE [dbo].[WorkOrderBatchDetails]
				   SET [JournalBatchHeaderId] = @TargetHeaderId
				 WHERE [JournalBatchDetailId] = @LoopJBDId;

				UPDATE [dbo].[CommonBatchDetails]
				   SET [JournalBatchHeaderId] = @TargetHeaderId,
					   [TransactionDate] = @NewInvoiceDate,
					   [UpdatedDate] = GETUTCDATE(),
					   [UpdatedBy] = @UpdatedBy
				 WHERE [CommonJournalBatchDetailId] = @LoopCommonId;

				DECLARE @OldDebit DECIMAL(18,6) = 0, @OldCredit DECIMAL(18,6) = 0;
				SELECT @OldDebit = ISNULL(SUM(DebitAmount),0), @OldCredit = ISNULL(SUM(CreditAmount),0)
				FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE [JournalBatchHeaderId] = @LoopJBHId AND ISNULL([IsDeleted],0)=0;

				UPDATE [dbo].[BatchHeader]
				   SET [TotalDebit] = @OldDebit, [TotalCredit] = @OldCredit, [TotalBalance] = @OldDebit - @OldCredit,
					   [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
				 WHERE [JournalBatchHeaderId] = @LoopJBHId;

				DECLARE @NewDebit DECIMAL(18,6) = 0, @NewCredit DECIMAL(18,6) = 0;
				SELECT @NewDebit = ISNULL(SUM(DebitAmount),0), @NewCredit = ISNULL(SUM(CreditAmount),0)
				FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE [JournalBatchHeaderId] = @TargetHeaderId AND ISNULL([IsDeleted],0)=0;

				UPDATE [dbo].[BatchHeader]
				   SET [TotalDebit] = @NewDebit, [TotalCredit] = @NewCredit, [TotalBalance] = @NewDebit - @NewCredit,
					   [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
				 WHERE [JournalBatchHeaderId] = @TargetHeaderId;

				SET @TargetHeaderId = NULL;
			END

			FETCH NEXT FROM entry_cursor INTO @LoopJBDId, @LoopJBHId, @LoopCommonId;
		END

		CLOSE entry_cursor;
		DEALLOCATE entry_cursor;

		DROP TABLE #tmpExistingEntries;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
				@AdhocComments VARCHAR(150) = 'USP_ReallocateWOInvoiceAccountingPeriod',
				@ProcedureParameters VARCHAR(3000) = '@BillingInvoicingId = ' + CAST(ISNULL(@BillingInvoicingId,0) AS VARCHAR(50)) + ', @NewInvoiceDate = ' + ISNULL(CONVERT(VARCHAR(50), @NewInvoiceDate, 121), ''),
				@ApplicationName VARCHAR(100) = 'PAS';

		EXEC spLogException
			@DatabaseName = @DatabaseName,
			@AdhocComments = @AdhocComments,
			@ProcedureParameters = @ProcedureParameters,
			@ApplicationName = @ApplicationName,
			@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END