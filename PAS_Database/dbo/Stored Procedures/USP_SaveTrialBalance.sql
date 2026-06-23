/*************************************************************             
 ** File:   [USP_SaveTrialBalance]             
 ** Author: Divyesh Kathiriya  
 ** Description: This stored procedure is used to Save Trial Balance Upload Data.
 ** Purpose:           
 ** Date:   23-JUNE-2026
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 S NO	Date				Author					Change Description              
 ----	-----------			-------------------		-------------------------------            
  1		23-JUNE-2026		Divyesh Kathiriya		Created 
	
**************************************************************/  

CREATE   PROCEDURE [dbo].[USP_SaveTrialBalance]
@tbl_SaveTrialBalanceUploadType SaveTrialBalanceUploadType ReadOnly
AS
BEGIN
	BEGIN TRY
        DECLARE @AccountingPeriodId BIGINT = 0;
		DECLARE @AccountingPeriod VARCHAR(100);
		
		DECLARE @CurrentNumber INT;
		DECLARE @CurrentNo BIGINT = 0;
		DECLARE @Currentbatch VARCHAR(100);		 

		DECLARE @GlAccountNumber varchar(200);
		DECLARE @GlAccountName varchar(200);

		DECLARE @JournalTypeId INT;
		DECLARE @JournalTypeCode VARCHAR(200);
		DECLARE @JournalTypename VARCHAR(200);
		DECLARE @JournalTypeNumber varchar(100);
		DECLARE @JournalBatchHeaderId BIGINT;
		DECLARE @JournalBatchDetailId BIGINT=0;		

		DECLARE @DistributionMasterId BIGINT;		
		DECLARE @DistributionCodeName VARCHAR(100);
		DECLARE @DistributionSetupCode VARCHAR(100);
		DECLARE @DistributionSetupId INT=0;
		DECLARE @DistributionName VARCHAR(200);
		DECLARE @DistributionSetupCodeCredit VARCHAR(100);

		DECLARE @StatusId INT;
		DECLARE @StatusName VARCHAR(200);
		DECLARE @Status VARCHAR(50);	
	
		DECLARE @UpdateBy VARCHAR(100);
		DECLARE @TransactionDate DATETIME2(7) = NULL;
		DECLARE @EntryDate DATETIME2(7) = NULL;
		DECLARE @ManagementStructureId BIGINT;
		DECLARE @GlAccountId BIGINT;
		DECLARE @MasterCompanyId INT;
		DECLARE @EmployeeId BIGINT;
		DECLARE @batch VARCHAR(100);
		DECLARE @Debit DECIMAL(18, 2) = 0;
		DECLARE @Credit DECIMAL(18, 2) = 0;
		DECLARE @TotalDebit DECIMAL(18, 2) = 0;
		DECLARE @TotalCredit DECIMAL(18, 2) = 0;
		DECLARE @TotalBalance DECIMAL(18, 2) = 0;
		DECLARE @LineNumber INT=1;
		DECLARE @CodeTypeId BIGINT;		
		DECLARE @LastMSLevel VARCHAR(200);
		DECLARE @AllMSlevels VARCHAR(max);	
		DECLARE @TotalRecords BIGINT = 0; 
		DECLARE @CurrentRecord BIGINT = 0;		

		SET @DistributionCodeName = 'ManualJournal';
		SET @DistributionSetupCode = 'ManualJouralDebit';
		SET @DistributionSetupCodeCredit = 'ManualJouralCredit'	
		SET @Status = 'Open';

		-- === POPULATE VARIABLES FROM INPUT TABLE PARAMETER ===
		SET @CodeTypeId = (SELECT [CodeTypeId] FROM [DBO].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'JournalType');
		SET @MasterCompanyId = (SELECT TOP 1 [MasterCompanyId] FROM @tbl_SaveTrialBalanceUploadType);
		SET @EmployeeId = (SELECT TOP 1 [EmployeeId] FROM @tbl_SaveTrialBalanceUploadType);
		SET @UpdateBy = (SELECT TOP 1 [UpdatedBy] FROM @tbl_SaveTrialBalanceUploadType);
		SET @TransactionDate = (SELECT TOP 1 [TransactionDate] FROM @tbl_SaveTrialBalanceUploadType);
		SET @EntryDate = (SELECT TOP 1 [EntryDate] FROM @tbl_SaveTrialBalanceUploadType);
		SET @LastMSLevel = (SELECT TOP 1 [LastMSLevel] FROM @tbl_SaveTrialBalanceUploadType);
		SET @AllMSlevels = (SELECT TOP 1 [AllMSlevels] FROM @tbl_SaveTrialBalanceUploadType);
	
		SET @ManagementStructureId = (SELECT [ManagementStructureId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @EmployeeId);

		-- === PREPARE TEMP TABLE WITH INPUT DATA ===
		IF OBJECT_ID(N'tempdb..#tmpTrialBalanceDetails') IS NOT NULL
		BEGIN
			DROP TABLE #tmpTrialBalanceDetails;
		END
			
		CREATE TABLE #tmpTrialBalanceDetails
		(
			[ID] INT IDENTITY(1,1) NOT NULL,			
			[GlAccountId] [bigint] NULL,
			[AccountCode] [varchar](50) NULL,	
			[Debit] [decimal](18, 2) NULL,
			[Credit] [decimal](18, 2) NULL,
			[TransactionDate] [datetime2] NULL,
			[EntryDate] [datetime2] NULL						
		);

		INSERT INTO #tmpTrialBalanceDetails ([GlAccountId], [AccountCode], [Debit], [Credit], [TransactionDate], [EntryDate])
		SELECT [GlAccountId], [AccountCode], [Debit], [Credit], [TransactionDate], [EntryDate]
		FROM @tbl_SaveTrialBalanceUploadType;

		-- === GET ACCOUNTING PERIOD ===		
		SELECT @AccountingPeriodId = [AccountingCalendarId], @AccountingPeriod = [PeriodName]
		FROM [DBO].[AccountingCalendar] WITH(NOLOCK)
		WHERE [MasterCompanyId] = @MasterCompanyId
		AND CAST(@EntryDate AS DATE) BETWEEN [FromDate] AND [ToDate]
		ORDER BY [AccountingCalendarId] DESC

		-- === CALCULATE TOTAL AMOUNT ===
		SELECT @TotalDebit = SUM(ISNULL([Debit],0)) FROM #tmpTrialBalanceDetails;
		SELECT @TotalCredit = SUM(ISNULL([Credit],0)) FROM #tmpTrialBalanceDetails;
		SELECT @TotalBalance = SUM(ISNULL([Debit],0) - ISNULL([Credit],0)) FROM #tmpTrialBalanceDetails;

		IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCodePrefixes
		END
					  	  
		CREATE TABLE #tmpCodePrefixes
		(
			ID BIGINT NOT NULL IDENTITY, 
			CodePrefixId BIGINT NULL,
			CodeTypeId BIGINT NULL,
			CurrentNumber BIGINT NULL,
			CodePrefix VARCHAR(50) NULL,
			CodeSufix VARCHAR(50) NULL,
			StartsFrom BIGINT NULL,
		)    

		-- === GET DISTRIBUTION AND JOURNAL TYPE INFO ===
		SELECT @DistributionMasterId = ID
		FROM [DBO].[DistributionMaster] WITH(NOLOCK) 
		WHERE UPPER(DistributionCode) = UPPER(@DistributionCodeName);		

		SELECT TOP 1 @JournalTypeId = JournalTypeId 
		FROM [DBO].[DistributionSetup] WITH(NOLOCK)
		WHERE DistributionMasterId = @DistributionMasterId 
		AND MasterCompanyId = @MasterCompanyId 
		AND UPPER(DistributionSetupCode) = UPPER(@DistributionSetupCode);		

		SELECT @StatusId = [Id], @StatusName = [name] FROM [DBO].[BatchStatus] WITH(NOLOCK) WHERE UPPER([Name]) = UPPER(@Status);

		SELECT @JournalTypeCode = JournalTypeCode, @JournalTypename = JournalTypeName 
		FROM [DBO].[JournalType] WITH(NOLOCK) WHERE ID = @JournalTypeId;

		-- === GET CODE PREFIXES ===
		INSERT INTO #tmpCodePrefixes (CodePrefixId, CodeTypeId, CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
		SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
		FROM [DBO].[CodePrefixes] CP WITH(NOLOCK) 
		INNER JOIN [DBO].[CodeTypes] CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
		WHERE CT.CodeTypeId = @CodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;		

		-- === GENERATE JOURNAL TYPE NUMBER ===
		SELECT @CurrentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
				ELSE CAST(StartsFrom AS BIGINT) + 1 END 
		FROM #tmpCodePrefixes 
		WHERE CodeTypeId = @CodeTypeId;
						  	  
		SET @JournalTypeNumber = (SELECT * FROM [DBO].[udfGenerateCodeNumber](
			@CurrentNo,
			(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), 
			(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)
		));

		UPDATE [dbo].[CodePrefixes]
		SET [CurrentNummber] = @CurrentNo 
		WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId;

		-- === INSERT INTO BATCHHEADER ===
		IF NOT EXISTS(
			SELECT 1 FROM [DBO].[BatchHeader] WITH(NOLOCK) 
			WHERE JournalTypeId = @JournalTypeId 
			AND MasterCompanyId = @MasterCompanyId 
			AND CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE) 
			AND StatusId = @StatusId 
			AND AccountingPeriodId = @AccountingPeriodId
		)
		BEGIN
			-- Generate batch name
			SELECT TOP 1 @Currentbatch = CAST(ISNULL(CurrentNumber, 0) AS BIGINT) + 1
			FROM [DBO].[BatchHeader] WITH(NOLOCK) 
			ORDER BY JournalBatchHeaderId DESC;

			IF(@Currentbatch IS NULL OR @Currentbatch = 0)
			BEGIN
				SET @Currentbatch = 1;
			END

			SET @batch = CASE 
				WHEN @Currentbatch > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				WHEN @Currentbatch > 9 THEN CONCAT('0', CAST(@Currentbatch AS VARCHAR(100)))
				ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(100)))
			END;

			SET @CurrentNumber = CAST(@Currentbatch AS INT);
			SET @batch = CONCAT(@JournalTypeCode, ' ', @batch);

			INSERT INTO [dbo].[BatchHeader]    
				([BatchName], [CurrentNumber], [EntryDate], [AccountingPeriod], [AccountingPeriodId], [StatusId], [StatusName],
				[JournalTypeId], [JournalTypeName], [TotalDebit], [TotalCredit], [TotalBalance], [MasterCompanyId],
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Module])    
			VALUES    
				(@batch, @CurrentNumber, @EntryDate, @AccountingPeriod, @AccountingPeriodId, @StatusId, @StatusName,
				@JournalTypeId, @JournalTypename, @TotalDebit, @TotalCredit, @TotalBalance, @MasterCompanyId,
				@UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @JournalTypeCode);    
                         
			SELECT @JournalBatchHeaderId = SCOPE_IDENTITY();
		END
		ELSE
		BEGIN
			SELECT @JournalBatchHeaderId = JournalBatchHeaderId
			FROM [DBO].[BatchHeader] WITH(NOLOCK)  
			WHERE JournalTypeId = @JournalTypeId 
			AND StatusId = @StatusId 
			AND AccountingPeriodId = @AccountingPeriodId;			
		END

		-- === INSERT INTO BATCHDETAILS ===
		INSERT INTO [DBO].[BatchDetails](
			[JournalTypeNumber], [CurrentNumber], [DistributionSetupId], [DistributionName], [JournalBatchHeaderId], [LineNumber], 
			[GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], 
			[IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], [LastMSLevel], [AllMSlevels], 
			[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], 
			[AccountingPeriodId], [AccountingPeriod])
		VALUES(
			@JournalTypeNumber, @CurrentNo, 0, NULL, @JournalBatchHeaderId, @LineNumber, 0, NULL, NULL, @TransactionDate, @EntryDate, 
			@JournalTypeId, @JournalTypename, 1, @TotalDebit, @TotalCredit, @ManagementStructureId, @DistributionCodeName, @LastMSLevel, @AllMSlevels,
			@MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @AccountingPeriodId, @AccountingPeriod);
	
		SET @JournalBatchDetailId = SCOPE_IDENTITY();		

		SELECT @TotalRecords = MAX(ID), @CurrentRecord = MIN(ID) FROM #tmpTrialBalanceDetails;	

		-- === LOOP THROUGH EACH RECORD ===
		WHILE(ISNULL(@TotalRecords, 0) >= ISNULL(@CurrentRecord, 0))
		BEGIN
			SELECT	
				@GlAccountId = [GlAccountId],
				@Debit = [Debit],
				@Credit = [Credit]	
			FROM #tmpTrialBalanceDetails 
			WHERE [ID] = @CurrentRecord;

			SELECT @GlAccountNumber = AccountCode, @GlAccountName = AccountName 
			FROM [DBO].[GLAccount] WITH(NOLOCK) 
			WHERE GLAccountId = @GlAccountId;

			-- === GET DISTRIBUTION SETUP INFO ===
			IF(ISNULL(@Debit, 0) > 0)
			BEGIN
				SELECT TOP 1 
					@DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId
				FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
				WHERE UPPER(DistributionSetupCode) = UPPER(@DistributionSetupCode)
				AND MasterCompanyId = @MasterCompanyId 
				AND DistributionMasterId = @DistributionMasterId;
			END
			ELSE
			BEGIN
				SELECT TOP 1 
					@DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId
				FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
				WHERE UPPER(DistributionSetupCode) = UPPER(@DistributionSetupCodeCredit)
				AND MasterCompanyId = @MasterCompanyId 
				AND DistributionMasterId = @DistributionMasterId;
			END			
			-- === INSERT INTO COMMONBATCHDETAILS ===
			INSERT INTO [dbo].[CommonBatchDetails]
				([JournalBatchDetailId], [JournalTypeNumber], [CurrentNumber], [DistributionSetupId], [DistributionName], [JournalBatchHeaderId], [LineNumber],
				[GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName],
				[IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], [LastMSLevel], [AllMSlevels], [MasterCompanyId],
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES	
				(@JournalBatchDetailId, @JournalTypeNumber, @CurrentNo,
				@DistributionSetupId,
				@DistributionName,
				@JournalBatchHeaderId, @LineNumber,
				@GlAccountId, @GlAccountNumber, @GlAccountName, @TransactionDate, @EntryDate, @JournalTypeId, @JournalTypename,
				CASE WHEN ISNULL(@Debit, 0) > 0 THEN 1 ELSE 0 END,
				CASE WHEN ISNULL(@Debit, 0) > 0 THEN @Debit ELSE 0 END,
				CASE WHEN ISNULL(@Debit, 0) > 0 THEN 0 ELSE @Credit END,
				@ManagementStructureId, @DistributionCodeName, @LastMSLevel, @AllMSlevels, @MasterCompanyId,
				@UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0);

			
			SET @CurrentRecord += 1;
		END		

	END TRY
	BEGIN CATCH  
  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[USP_SaveTrialBalance]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''',  
            @ApplicationName varchar(100) = 'PAS'  
  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH   
END