/*********************             
 ** File:   USP_PostCreditMemo_RefundBatchDetails           
 ** Author:  Devendra Shekh   
 ** Description: to post accounting batch details for refunding credit memo
 ** Purpose:           
 ** Date:  18-OCT-2023        
            
    
 **********************             
  ** Change History             
 **********************             
 ** PR   Date			Author					Change Description              
 ** --   --------		-------				--------------------------------            
    1    18/10/2023		Devendra Shekh			 Created  
    2    14/02/2023		Moin Bloch			     Updated Used Distribution Setup Code Insted of Name 
 -- exec USP_PostCreditMemo_RefundBatchDetails 
**********************/   
  
CREATE   PROCEDURE [dbo].[USP_PostCreditMemo_RefundBatchDetails]  
	@CustomerRefundId BIGINT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY    
   
	BEGIN

		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @MasterCompanyId bigint=0;   
		DECLARE @UpdateBy varchar(100);
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
		DECLARE @Amount decimal(18,2); 
		DECLARE @CurrentPeriodId bigint=0; 
		DECLARE @LineNumber int=1;    
		DECLARE @JournalBatchDetailId BIGINT=0;
		DECLARE @CommonBatchDetailId BIGINT=0;
		DECLARE @DistributionSetupId int=0
		DECLARE @Distributionname varchar(200) 
		DECLARE @GlAccountId int
		DECLARE @GlAccountName varchar(200) 
		DECLARE @GlAccountNumber varchar(200) 
		DECLARE @CheckAmount DECIMAL(18,2)
		DECLARE @ManagementStructureId bigint
		DECLARE @LastMSLevel varchar(200)
		DECLARE @AllMSlevels varchar(max)
		DECLARE @TotalDebit decimal(18, 2) =0;
		DECLARE @TotalCredit decimal(18, 2) =0;
		DECLARE @TotalBalance decimal(18, 2) =0;

		DECLARE @ModuleId BIGINT = 0;
		DECLARE @CRDRType BIGINT = 0;
		DECLARE @AccountMSModuleId INT = 0
		DECLARE @AppModuleId INT = 0;
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
		DECLARE @SumAmount decimal(18,2); 


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
				StartsFROM BIGINT NULL,
			)   

		SELECT @SumAmount = ABS(SUM(Amount)) FROM [dbo].[CreditMemo] WITH(NOLOCK) WHERE [CustomerRefundId] = @CustomerRefundId

		IF(ISNULL(@SumAmount,0) <> 0)
			BEGIN		
				SELECT TOP 1 @MasterCompanyId=MasterCompanyId,@UpdateBy=CreatedBy, @CurrentManagementStructureId =ManagementStructureId FROM dbo.CustomerRefund WITH(NOLOCK) WHERE CustomerRefundId = @CustomerRefundId
				SELECT @DistributionMasterId =ID,@DistributionCode =DistributionCode FROM DistributionMaster WITH(NOLOCK)  WHERE UPPER(DistributionCode)= UPPER('CRFD')	
				SELECT @StatusId =Id,@StatusName=name FROM BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
				SELECT top 1 @JournalTypeId =JournalTypeId FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId
				
				SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
				SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'CustomerRefund'

				SELECT @AllMSlevels = (SELECT AllMSlevels FROM DBO.udfGetAllEntityMSLevelString(@CurrentManagementStructureId))
				SELECT @LastMSLevel = (SELECT LastMSName FROM DBO.udfGetAllEntityMSLevelString(@CurrentManagementStructureId))

				INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFROM) 
				SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFROM 
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

				SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
				FROM [DBO].[EntityStructureSetup] est WITH(NOLOCK) 
				INNER JOIN [DBO].[ManagementStructureLevel] msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
				INNER JOIN [DBO].[AccountingCalendar] acc WITH(NOLOCK) ON msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
				WHERE est.EntityStructureId=@CurrentManagementStructureId AND acc.MasterCompanyId=@MasterCompanyId
				AND CAST(GETUTCDATE() AS DATE)   >= CAST(FromDate AS DATE) AND  CAST(GETUTCDATE() AS DATE) <= CAST(ToDate AS DATE)

				SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId AND StatusId=@StatusId AND AccountingPeriodId = @AccountingPeriodId 

				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
				BEGIN 
					SELECT 
						@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
						ELSE CAST(StartsFROM AS BIGINT) + 1 END 
						FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  	  
					SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
				END
				ELSE 
				BEGIN
					ROLLBACK TRAN;
				END

				IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId AND MasterCompanyId=@MasterCompanyId AND CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)AND StatusId=@StatusId AND AccountingPeriodId = @AccountingPeriodId)
				BEGIN
					IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK))
					BEGIN  
						set @batch ='001'  
						set @Currentbatch='001' 
					END
					ELSE
					BEGIN 
						SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1   
						  ELSE  1 END   
						FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc  

						IF(CAST(@Currentbatch AS BIGINT) >99)  
						BEGIN
							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))  
							  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END   
						END  
						ELSE IF(CAST(@Currentbatch AS BIGINT) >9)  
						BEGIN    
							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))  
							  ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END   
						END
						ELSE
						BEGIN
						   SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))  
							  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END   
  
						END  
					END
			
					SET @CurrentNumber = CAST(@Currentbatch AS BIGINT)     
					SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as varchar(100)) as varchar(100))  

					INSERT INTO [dbo].[BatchHeader]    
					  ([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],
					  [JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],
					  [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])    
					VALUES    
					  (@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,
					  @JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,
					  @UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@JournalTypeCode);    
                           
					SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()    
					Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
				END
				ELSE
				BEGIN 
					SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId AND StatusId=@StatusId AND AccountingPeriodId = @AccountingPeriodId
					   SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END   
							 FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc   
          
					IF(@CurrentPeriodId =0)  
					begin  
					   Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
					END  
				END

				INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
				[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
				VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
				@JournalTypeId, @JournalTypename, 1, 0, 0, @CurrentManagementStructureId, 'CustomerRefund', 
				NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)

				SET @JournalBatchDetailId = SCOPE_IDENTITY()

				 ----- Account Receivable --------
			 				
				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId, @CRDRType =CRDRType,
				 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName 
				 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE UPPER(DistributionSetupCode) = UPPER('CRFDACCREC') 
				 AND DistributionMasterId = (SELECT TOP 1 ID FROM dbo.DistributionMaster WITH(NOLOCK) WHERE DistributionCode = 'CRFD')

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
				 VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CRDRType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CRDRType = 1 THEN @SumAmount ELSE 0 END,
					CASE WHEN @CRDRType = 1 THEN 0 ELSE @SumAmount END,
					@CurrentManagementStructureId ,'CustomerRefund',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@CurrentManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
				INSERT INTO [dbo].[CreditMemoPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,ModuleId,CheckDate,CommonJournalBatchDetailId,InvoiceReferenceId,ManagementStructureId)
				VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@CustomerRefundId,NULL,@ModuleId,NULL,@CommonBatchDetailId,0,@CurrentManagementStructureId);

				 ----- Account Receivable --------

				-----Account Payable--------

				SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId, @CRDRType =CRDRType,
				@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName 
				FROM dbo.DistributionSetup WITH(NOLOCK) WHERE UPPER(DistributionSetupCode) = UPPER('CRFDACCAP') 
				AND DistributionMasterId = (SELECT TOP 1 ID FROM dbo.DistributionMaster WITH(NOLOCK) WHERE DistributionCode = 'CRFD')

				INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
				VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CRDRType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CRDRType = 1 THEN @SumAmount ELSE 0 END,
					CASE WHEN @CRDRType = 1 THEN 0 ELSE @SumAmount END,
					@CurrentManagementStructureId ,'CustomerRefund',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  ----
					
				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@CurrentManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
				INSERT INTO [dbo].[CreditMemoPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,ModuleId,CheckDate,CommonJournalBatchDetailId,InvoiceReferenceId,ManagementStructureId)
				VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@CustomerRefundId,NULL,@ModuleId,NULL,@CommonBatchDetailId,0,@CurrentManagementStructureId);

				 -----Account Payable--------

				SET @TotalDebit=0;
				SET @TotalCredit=0;
				SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
				UPDATE BatchDetails SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate = GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchDetailId=@JournalBatchDetailId

				SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM BatchDetails 
				WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId AND IsDeleted=0 
				SET @TotalBalance =@TotalDebit-@TotalCredit

				UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
				UPDATE BatchHeader SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId
			END

	END
  
 END TRY      
 BEGIN CATCH  
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_UpdateCreditMemoStatus_Refund'   
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerRefundId, '') AS varchar(100))  
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