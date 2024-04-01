/*************************************************************           
 ** File:   [USP_StandAloneCM_PostCheckBatchDetails]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used insert account report in batch from StandAloneCM.
 ** Purpose:         
 ** Date:   09/01/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/01/2023   Amit Ghediya	Created	
	2    09/05/2023   Amit Ghediya	Update to allow negative value for batch.	
	3    09/15/2023   Amit Ghediya	Update for management stucture add in common table.
     
**************************************************************/

CREATE        PROCEDURE [dbo].[USP_StandAloneCM_PostCheckBatchDetails]
(
	@StandAloneCreditMemoDetailsId BIGINT,
	@CreditMemoHeaderId BIGINT,
	@ManagementStructureDetailsId BIGINT,
	@Amount DECIMAL(18,2),
	@MasterCompanyId INT,
	@UpdateBy VARCHAR(100)
)
AS
BEGIN 
	BEGIN TRY
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
		DECLARE @DistributionSetupId int=0
		DECLARE @Distributionname varchar(200) 
		DECLARE @GlAccountId int
		DECLARE @StartsFrom varchar(200)='00'
		DECLARE @GlAccountName varchar(200) 
		DECLARE @GlAccountNumber varchar(200) 
		DECLARE @ExtAmount DECIMAL(18,2)
		DECLARE @BankId INT =0;
		DECLARE @ManagementStructureId bigint
		DECLARE @LastMSLevel varchar(200)
		DECLARE @AllMSlevels varchar(max)
		DECLARE @ModuleId INT
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
		DECLARE @tmpVendorRMADetailId BIGINT;

		SET @DistributionCodeName = 'CMDISACC';

		DECLARE @AccountMSModuleId INT = 0
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

		SELECT @CodeTypeId = CodeTypeId FROM [DBO].[CodeTypes] WITH(NOLOCK) WHERE CodeType = 'JournalType';

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

		IF(ISNULL(@Amount,0) <> 0)
		BEGIN 
			SELECT @DistributionMasterId =ID,@DistributionCode =DistributionCode FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('CMDISACC')
			
			SELECT TOP 1 @JournalTypeId =JournalTypeId FROM [DBO].[DistributionSetup] WITH(NOLOCK)
			WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND DistributionSetupCode='CMART';
			
			SELECT @StatusId =Id,@StatusName=name FROM [DBO].[BatchStatus] WITH(NOLOCK)  WHERE Name= 'Open'
			SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
			SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM [DBO].[JournalType] WITH(NOLOCK)  WHERE ID= @JournalTypeId
			SELECT @CurrentManagementStructureId =ManagementStructureId FROM [DBO].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (REPLACE(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
			
			SELECT @ManagementStructureId = ManagementStructureId FROM [DBO].[CreditMemo] WITH(NOLOCK) WHERE CreditMemoHeaderId = @CreditMemoHeaderId;
			SELECT @LastMSLevel = LastMSLevel,@AllMSlevels = AllMSlevels FROM [DBO].[StocklineManagementStructureDetails] WITH(NOLOCK) WHERE ReferenceID = @stklineId;

			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
			FROM [DBO].[CodePrefixes] CP WITH(NOLOCK) JOIN [DBO].[CodeTypes] CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND  CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
			
			SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
			FROM [DBO].[EntityStructureSetup] est WITH(NOLOCK) 
			INNER JOIN [DBO].[ManagementStructureLevel] msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
			INNER JOIN [DBO].[AccountingCalendar] acc WITH(NOLOCK) ON msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
			where est.EntityStructureId=@CurrentManagementStructureId AND acc.MasterCompanyId=@MasterCompanyId  
			AND CAST(GETUTCDATE() AS DATE)   >= CAST(FromDate AS DATE) AND  CAST(GETUTCDATE() AS DATE) <= CAST(ToDate AS DATE)
			
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
			
			IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
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
				SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId   
				   SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END   
						 FROM [DBO].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  ORDER BY JournalBatchDetailId DESC   
          
				IF(@CurrentPeriodId = 0)  
				BEGIN  
				   Update [DBO].[BatchHeader] SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod  WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
				END  
			END
			
			INSERT INTO [DBO].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
			[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
			[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [AccountingPeriodId], [AccountingPeriod])
			VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
			@JournalTypeId, @JournalTypename, 1, 0, 0, @ManagementStructureId, @DistributionCodeName, 
			NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @AccountingPeriodId, @AccountingPeriod)
		
			SET @JournalBatchDetailId=SCOPE_IDENTITY()


				-----Account Recevable--------

				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
				 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'CMART' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
					@ManagementStructureId ,'StandAloneCreditMemo',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [dbo].CreditMemoPaymentBatchDetails(JournalBatchHeaderId,JournalBatchDetailId,ManagementStructureId,ReferenceId,DocumentNo,CheckDate,CommonJournalBatchDetailId,InvoiceReferenceId,ModuleId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@ManagementStructureDetailsId,@StandAloneCreditMemoDetailsId,@ExtNumber,@ExtDate,@CommonBatchDetailId,0,53)

				 -----Account Recevable--------

				 -----Account Above--------

				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @CrDrType = CRDRType
				 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'CMINVSTK' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

				 SELECT @GlAccountId = GlAccountId FROM StandAloneCreditMemoDetails WHERE StandAloneCreditMemoDetailId = @StandAloneCreditMemoDetailsId;
				 
				 select @GlAccountNumber = AccountCode,@GlAccountName=AccountName from GLAccount WHERE GLAccountId=@GlAccountId;

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
					@ManagementStructureId ,'StandAloneCreditMemo',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [dbo].CreditMemoPaymentBatchDetails(JournalBatchHeaderId,JournalBatchDetailId,ManagementStructureId,ReferenceId,DocumentNo,CheckDate,CommonJournalBatchDetailId,InvoiceReferenceId,ModuleId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@ManagementStructureDetailsId,@StandAloneCreditMemoDetailsId,@ExtNumber,@ExtDate,@CommonBatchDetailId,0,53)

				 -----Account Above--------

			SET @TotalDebit=0;
			SET @TotalCredit=0;
			SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
			UPDATE [dbo].[BatchDetails] SET DebitAmount = @TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy  WHERE JournalBatchDetailId=@JournalBatchDetailId
		END

		
		SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [DBO].[BatchDetails] 
		WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 
		SET @TotalBalance =@TotalDebit-@TotalCredit

		UPDATE [DBO].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
	    UPDATE [DBO].[BatchHeader] SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId

	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_StandAloneCM_PostCheckBatchDetails' 
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