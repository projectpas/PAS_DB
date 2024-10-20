﻿/*************************************************************           
 ** File:   [USP_ManualJournal_PostCheckBatchDetails]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used insert account report in batch from ManualJournal.
 ** Purpose:         
 ** Date:   01/17/2024 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date           Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    01/17/2024   Amit Ghediya		Created	
	2    02/19/2024	  HEMANT SALIYA	    Updated for Restrict Accounting Entry by Master Company
	3    25/09/2024	  AMIT GHEDIYA		Added for AutoPost Batch
	4	 09/10/2024	  Devendra Shekh	Added new fields for [CommonBatchDetails]
     
EXEC USP_ManualJournal_PostCheckBatchDetails 10243
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_ManualJournal_PostCheckBatchDetails]
(
	@ManualJournalHeaderId BIGINT
)
AS
BEGIN 
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @JournalTypeNumber varchar(100);
		DECLARE @DistributionMasterId bigint;    
		DECLARE @DistributionCode varchar(200); 
		DECLARE @CurrentManagementStructureId bigint=0; 
		DECLARE @StatusId int;    
		DECLARE @StatusName varchar(200);    
		DECLARE @AccountingPeriod varchar(100);    
		DECLARE @AccountingPeriodId bigint=0;   
		DECLARE @JournalTypeId int;    
		DECLARE @JournalTypeCode varchar(200);
		DECLARE @JournalBatchHeaderId bigint;    
		DECLARE @JournalTypename varchar(200);  
		DECLARE @batch varchar(100);    
		DECLARE @Currentbatch varchar(100);    
		DECLARE @CurrentNumber int;    
		DECLARE @CurrentPeriodId bigint=0; 
		DECLARE @LineNumber int=1;    
		DECLARE @JournalBatchDetailId BIGINT=0;
		DECLARE @CommonBatchDetailId BIGINT=0;
		DECLARE @DistributionSetupId int=0;
		DECLARE @Distributionname varchar(200); 
		DECLARE @GlAccountId int;
		DECLARE @StartsFrom varchar(200)='00';
		DECLARE @GlAccountName varchar(200);
		DECLARE @GlAccountNumber varchar(200); 
		DECLARE @ExtAmount DECIMAL(18,2);
		DECLARE @BankId INT =0;
		DECLARE @ManagementStructureId BIGINT;
		DECLARE @ManualJorManagementStructureId BIGINT;
		DECLARE @Debit DECIMAL(18, 2) = 0;
		DECLARE @Credit DECIMAL(18, 2) = 0;
		DECLARE @LastMSLevel varchar(200);
		DECLARE @AllMSlevels varchar(max);
		DECLARE @ModuleId INT;
		DECLARE @TotalDebit decimal(18, 2) =0;
		DECLARE @TotalCredit decimal(18, 2) =0;
		DECLARE @TotalBalance decimal(18, 2) =0;
		DECLARE @ExtNumber VARCHAR(20);
		DECLARE @VendorName VARCHAR(50);
		DECLARE @ExtDate Datetime;
		DECLARE @stklineId BIGINT;
		DECLARE @DistributionCodeName VARCHAR(100);
		DECLARE @CrDrType int=0;
		DECLARE @CodePrefix VARCHAR(50);
		DECLARE @Amount DECIMAL(18, 2) =0;
		DECLARE @MasterLoopID INT;
		DECLARE @ManualJournalDetailsId BIGINT;
		DECLARE @AdjustmentAmount DECIMAL(18, 2) =0;
		DECLARE @StockLineId BIGINT;
		DECLARE @BulkStatusName varchar(200);  
		DECLARE @ManualJournalModuleID  BIGINT;
		DECLARE @DetailQtyAdjustment INT;
		DECLARE @TransferQtyAdjustment INT;
		DECLARE @QuantityOnHand INT;
		DECLARE @ChildUpdateQty INT;
		DECLARE @QuantityAvailable INT;
		DECLARE @StockModule BIGINT;
		DECLARE @AccountMSModuleId INT = 0;
		DECLARE @MasterCompanyId BIGINT=0;   
		DECLARE @UpdateBy VARCHAR(100);
		DECLARE @EmployeeId BIGINT=0;  
		DECLARE @ManualJournalStatusId BIGINT=0; 
		DECLARE @CodePrefixMJE VARCHAR(100) = 'MJE';
		DECLARE @ModuleName VARCHAR(100) = 'Accounting';
		SET @DistributionCodeName = 'ManualJournal';
		DECLARE @DistributionSetupCode VARCHAR(100) = 'ManualJouralDebit';
		DECLARE @DistributionSetupCodeCredit VARCHAR(100) = 'ManualJouralDebit';
		DECLARE @Status VARCHAR(50) = 'Open';
		DECLARE @CodePrefixSL VARCHAR(100) ='SL';
		DECLARE @StatusPosted VARCHAR(100) = 'Posted';
		DECLARE @IsAutoPost INT = 0;
		DECLARE @IsBatchGenerated INT = 0;
		DECLARE @LocalCurrencyCode VARCHAR(20) = '';
		DECLARE @ForeignCurrencyCode VARCHAR(20) = '';
		DECLARE @JournalNumber VARCHAR(100) = '';
		DECLARE @FXRate DECIMAL(9,2) = 1;	--Default Value set to : 1

		SELECT @ManualJournalModuleID = ModuleId FROM [DBO].[Module] WITH(NOLOCK) WHERE UPPER(CodePrefix)=UPPER(@CodePrefixMJE);
		
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER([ModuleName]) = UPPER(@ModuleName);

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
		
		SELECT @Amount = SUM(ISNULL(ABS(Debit),0) + ISNULL(ABS(Credit),0))
		FROM [DBO].[ManualJournalDetails] WITH(NOLOCK) 
		WHERE ManualJournalHeaderId = @ManualJournalHeaderId AND IsActive = 1;

		DECLARE @IsRestrict BIT;
		DECLARE @IsAccountByPass BIT;

		EXEC dbo.USP_GetGeneralLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdateBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

		IF(ISNULL(@Amount,0) <> 0 AND ISNULL(@IsAccountByPass, 0) = 0)
		BEGIN 
			SELECT @DistributionMasterId =ID,@DistributionCode = DistributionCode FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER(@DistributionCodeName)
			
			SELECT @MasterCompanyId = MasterCompanyId , @UpdateBy = UpdatedBy , @ManagementStructureId = ManagementStructureId FROM [DBO].[ManualJournalDetails] WITH(NOLOCK) WHERE ManualJournalHeaderId = @ManualJournalHeaderId AND IsActive = 1;

			SELECT @EmployeeId = @EmployeeId, @AccountingPeriodId = AccountingPeriodId, @JournalNumber = JournalNumber FROM [DBO].[ManualJournalHeader] WITH(NOLOCK) WHERE ManualJournalHeaderId = @ManualJournalHeaderId AND IsActive = 1;

			SELECT TOP 1 @JournalTypeId = JournalTypeId FROM [DBO].[DistributionSetup] WITH(NOLOCK)
			WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND UPPER(DistributionSetupCode)=UPPER(@DistributionSetupCode);
			
			SELECT @StatusId =Id,@StatusName=name FROM [DBO].[BatchStatus] WITH(NOLOCK)  WHERE UPPER([Name])= UPPER(@Status)
			SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId AND AccountingPeriodId = @AccountingPeriodId
			SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM [DBO].[JournalType] WITH(NOLOCK)  WHERE ID= @JournalTypeId
			SELECT @CurrentManagementStructureId =ManagementStructureId FROM [DBO].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (REPLACE(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
			
			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
			FROM [DBO].[CodePrefixes] CP WITH(NOLOCK) JOIN [DBO].[CodeTypes] CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND  CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
				
			SELECT @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
			FROM [DBO].[AccountingCalendar] acc WITH(NOLOCK)
			WHERE acc.AccountingCalendarId = @AccountingPeriodId AND acc.MasterCompanyId=@MasterCompanyId  

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
			BEGIN 
				SELECT 
					@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
					ELSE CAST(StartsFrom AS BIGINT) + 1 END 
					FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  	  
				SET @JournalTypeNumber = (SELECT * FROM [DBO].[udfGenerateCodeNumber](@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN 	
				ROLLBACK TRAN;
			END
			
			IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE) and StatusId=@StatusId AND AccountingPeriodId = @AccountingPeriodId)
			BEGIN
				IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK))
				BEGIN  
					set @batch ='001'  
					set @Currentbatch='001' 
				END
				ELSE
				BEGIN 
					SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1   
					  ELSE  1 END   
					FROM [DBO].[BatchHeader] WITH(NOLOCK) ORDER BY JournalBatchHeaderId DESC  

					IF(CAST(@Currentbatch AS BIGINT) >99)  
					BEGIN
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch AS VARCHAR(100))  
						  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END   
					END  
					ELSE IF(CAST(@Currentbatch AS BIGINT) >9)  
					BEGIN    
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch AS VARCHAR(100))  
						  ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END   
					END
					ELSE
					BEGIN
					   SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch AS VARCHAR(100))  
						  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END   
  
					END  
				END
			
				SET @CurrentNumber = CAST(@Currentbatch AS BIGINT)     
							  SET @batch = CAST(@JournalTypeCode +' '+CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))  
							
				INSERT INTO [dbo].[BatchHeader]    
				  ([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],
				  [JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],
				  [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])    
				VALUES    
				  (@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,
				  @JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,
				  @UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@JournalTypeCode);    
                         
				SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()    
				UPDATE [dbo].[BatchHeader] set CurrentNumber=@CurrentNumber WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
			END
			ELSE
			BEGIN
				SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId AND AccountingPeriodId = @AccountingPeriodId 
				   SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END   
						 FROM [DBO].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId AND AccountingPeriodId = @AccountingPeriodId  ORDER BY JournalBatchDetailId DESC   
          
				IF(@CurrentPeriodId = 0)  
				BEGIN  
				   Update [DBO].[BatchHeader] SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod  WHERE JournalBatchHeaderId= @JournalBatchHeaderId AND AccountingPeriodId = @AccountingPeriodId 
				END  

				SET @IsBatchGenerated = 1;
			END
			
			INSERT INTO [DBO].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
			[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
			[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [AccountingPeriodId], [AccountingPeriod])
			VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
			@JournalTypeId, @JournalTypename, 1, 0, 0, @ManagementStructureId, @DistributionCodeName, 
			NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @AccountingPeriodId, @AccountingPeriod)
		
			SET @JournalBatchDetailId=SCOPE_IDENTITY()
				

				IF OBJECT_ID(N'tempdb..#tmpManualJournalDetails') IS NOT NULL
				BEGIN
					DROP TABLE #tmpManualJournalDetails
				END
				
				CREATE TABLE #tmpManualJournalDetails
				(
					[ID] INT IDENTITY,
					[ManualJournalDetailsId] [bigint] NULL,
					[GlAccountId] [bigint] NOT NULL,
					[Debit] [decimal](18,2) NULL,
					[Credit] [decimal](18,2) NULL,
					[ManagementStructureId] [bigint] NULL,
					[LastMSLevel] [varchar](200) NULL,
					[AllMSlevels] [varchar](MAX) NULL
				)

				INSERT INTO #tmpManualJournalDetails ([ManualJournalDetailsId],[GlAccountId],[Debit],[Credit],[ManagementStructureId],[LastMSLevel],[AllMSlevels])
				SELECT [ManualJournalDetailsId],[GlAccountId],[Debit],[Credit],[ManagementStructureId],[LastMSLevel],[AllMSlevels] 
				FROM [DBO].[ManualJournalDetails] WITH(NOLOCK) WHERE ManualJournalHeaderId = @ManualJournalHeaderId AND IsActive = 1;

				SELECT  @MasterLoopID = MAX(ID) FROM #tmpManualJournalDetails

				WHILE(@MasterLoopID > 0)
				BEGIN
					SELECT @ManualJournalDetailsId = [ManualJournalDetailsId],
						   @GlAccountId = [GlAccountId],
						   @Debit = [Debit],
						   @Credit = [Credit],
						   @ManualJorManagementStructureId = [ManagementStructureId],
						   @LastMSLevel = [LastMSLevel],
						   @AllMSlevels = [AllMSlevels]
					FROM #tmpManualJournalDetails WHERE [ID] = @MasterLoopID;
					
					SELECT @GlAccountNumber = AccountCode, @GlAccountName=AccountName FROM [DBO].[GLAccount] WITH(NOLOCK) WHERE GLAccountId = @GlAccountId;

					-----ManualJournal-Debit/Credit--------
					IF(ISNULL(@Debit,0) > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType = CRDRType,@IsAutoPost = ISNULL(IsAutoPost,0) 
						FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) = UPPER(@DistributionSetupCode)
						AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)
					END
					ELSE
					BEGIN
						SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType = CRDRType,@IsAutoPost = ISNULL(IsAutoPost,0) 
						FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) = UPPER(@DistributionSetupCodeCredit)
						AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)
					END
					
					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
						[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
						[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
						VALUES	
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
						,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
						CASE WHEN ISNULL(@Debit,0) > 0 THEN 1 ELSE 0 END,
						CASE WHEN ISNULL(@Debit,0) > 0 THEN @Debit ELSE 0 END,
						CASE WHEN ISNULL(@Debit,0) > 0 THEN 0 ELSE @Credit END,
						@ManualJorManagementStructureId ,@DistributionCodeName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
						@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ManualJournalHeaderId,@JournalNumber,'',@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode);

					SET @CommonBatchDetailId = SCOPE_IDENTITY();

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManualJorManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [dbo].[ManualJournalPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ManagementStructureId,ReferenceId,ReferenceDetailId,CommonJournalBatchDetailId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@ManualJorManagementStructureId,@ManualJournalHeaderId,@ManualJournalDetailsId,@CommonBatchDetailId)

					-----Inventory-Stock--------

					--GEt Stockline Module ID
					SELECT @StockModule = [ModuleId]  FROM [DBO].[Module] WITH(NOLOCK) WHERE UPPER([CodePrefix]) = UPPER(@CodePrefixSL);

					SET @ManualJournalDetailsId = 0;
					SET @GlAccountId = 0;
					SET @Debit = 0;
					SET @Credit = 0;
					SET @ManualJorManagementStructureId = 0;
					SET @LastMSLevel = NULL;
					SET @AllMSlevels = NULL;
					SET @GlAccountName = NULL;
					SET @GlAccountNumber = 0;

					SET @MasterLoopID = @MasterLoopID - 1;
				END

			SET @TotalDebit=0;
			SET @TotalCredit=0;
			SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
			UPDATE [dbo].[BatchDetails] SET DebitAmount = @TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy  WHERE JournalBatchDetailId=@JournalBatchDetailId

			--AutoPost Batch
			IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
			BEGIN
			    EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
			END
			IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
			BEGIN
				EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
			END
		END
		
		SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [DBO].[BatchDetails] 
		WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 
		SET @TotalBalance =@TotalDebit-@TotalCredit

		UPDATE [DBO].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
	    UPDATE [DBO].[BatchHeader] SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId

		SELECT @ManualJournalStatusId = ManualJournalStatusId from [DBO].[ManualJournalStatus] where UPPER([Name]) = UPPER(@StatusPosted)
		--Update  Status to Post
		UPDATE ManualJournalHeader SET ManualJournalStatusId = @ManualJournalStatusId WHERE ManualJournalHeaderId = @ManualJournalHeaderId;
		SELECT @ManualJournalHeaderId AS 'ManualJournalHeaderId';
	END	
	COMMIT  TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ManualJournal_PostCheckBatchDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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