/*********************           
 ** File:   [USP_PostNonPO_BatchDetails]           
 ** Author: Devendra Shekh
 ** Description: This stored procedure is used to insert accounting batch details for non po
 ** Purpose:         
 ** Date:  10-OCT-2023

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date				 Author					Change Description            
 ** --   --------			-------				--------------------------------          
    1    10-OCT-2023		 Devendra Shekh			Created	
    2    12-OCT-2023		 Devendra Shekh			accounting calender changes	
    3    16-OCT-2023		 Devendra Shekh			batch insert issue resolved
    4    30-OCT-2023		 Devendra Shekh			added ExtendedPrice for amount
    5    31-OCT-2023		 Devendra Shekh			added posteddate for npoheaderupdate
    6    02-NOV-2023		 Devendra Shekh			added EXEC [USP_AddVendorPaymentDetailsForNonPOById]
    7    09-JAN-2024         Moin Bloch             Modify(Replace Invocedate instead of GETUTCDATE() in Invoice) 
	8    14/02/2023	         Moin Bloch	            Updated Used Distribution Setup Code Insted of Name 
	9    03/04/2024			 HEMANT SALIYA	        Updated for Restrict Accounting Entry by Master Company
	10   29/07/2024          Sahdev Saliya          Updated For Add AccountingPeriodId, AccountingPeriod In BatchDetails
	11	 29-AUG-2024		 Devendra Shekh			JE Sequence Skipping issue resolved	
	12   26/09/2024			 AMIT GHEDIYA			Added for AutoPost Batch
	13	 14-OCT-2024		 Devendra Shekh			Added new fields for [CommonBatchDetails]
	14	 04-NOV-2024		 Devendra Shekh			Added ReferenceId, ReferenceModule For [CommonBatchDetails]
	15   06-JAN-2025		 Rajesh Gami			add new DistributionSetup for the DEPOSIT
	16   07-JAN-2025		 Rajesh Gami			Modified DistributionSetup for the DEPOSIT from itemGLAccount to DistributionSetup GL and Amount logic change to SUM of extended cost instead of Item Level
	17	 02/JUN/2025	     Abhishek Jirawla		Fixed Name concat read script
	18	 25/JUN/2025	     Devendra Shekh			Modified DistributionSetup for the DEPOSIT from DistributionSetup to itemGLAccount
	19	 06/March/2026	     AMIT GHEDIYA			Modified for revert accounting entry whle click on unpost Also not allow to add in vendorPayment & after revert sodt delete vendorpayment table (PN-15580)
	20	 12/March/2026	     AMIT GHEDIYA			Modified for revert after revert Hard delete vendorpayment table & approval process(PN-15580)
	21	 06/07/2026	         Moin Bloch             Modify (Added IsBypassAccounting Flag to bypass Accounting Entry PN-16871)

	 exec USP_PostNonPO_BatchDetails 6,'admin'
**********************/

CREATE    PROCEDURE [dbo].[USP_PostNonPO_BatchDetails]
(
	@NonPOInvoiceId BIGINT,
	@UserName VARCHAR(50),
	@IsRevert BIT = 0
)
AS
BEGIN 
	BEGIN TRY
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
		DECLARE @ModuleId INT
		DECLARE @TotalDebit decimal(18, 2) =0;
		DECLARE @TotalCredit decimal(18, 2) =0;
		DECLARE @TotalBalance decimal(18, 2) =0;
		DECLARE @VendorName VARCHAR(50);
		DECLARE @InvoiceDate DATETIME2(7) = NULL;

		DECLARE @BatchDetailCount BIGINT = 0;
		DECLARE @CRDRType BIGINT = 0;
		DECLARE @VendorId BIGINT;
		DECLARE @TotalNonPOPart BIGINT
		DECLARE @NonPOPartStart BIGINT = 1
		DECLARE @PartMemo VARCHAR(500)
		DECLARE @PartGlAccId BIGINT
		DECLARE @ReferenceNum VARCHAR(100)= '';
		DECLARE @AccountMSModuleId INT = 0
		DECLARE @PartAmtSum DECIMAL(18,2) =0;
		DECLARE @IsAutoPost INT = 0;
		DECLARE @IsBatchGenerated INT = 0;
		DECLARE @IsBypassAccounting BIT = 0;
		DECLARE @LocalCurrencyCode VARCHAR(20) = '';
		DECLARE @ForeignCurrencyCode VARCHAR(20) = '';
		DECLARE @FXRate DECIMAL(9,2) = 1;	--Default Value set to : 1
		DECLARE @ReferenceModule VARCHAR(100) = 'NONPO';
		DECLARE @isItemLevelCalculation BIT = 1;
		DECLARE @NPOOpenStausId INT = 0;

		SELECT @NPOOpenStausId = [NonPOInvoiceHeaderStatusId] from [dbo].[NonPOInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Open';
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

		SELECT @ReferenceNum = NPONumber, @LocalCurrencyCode = ISNULL(CU.Code,''), @ForeignCurrencyCode = ISNULL(CU.Code,'') FROM [dbo].[NonPOInvoiceHeader] NPO WITH(NOLOCK)
		LEFT JOIN [dbo].[Currency] CU WITH(NOLOCK) ON NPO.CurrencyId = CU.CurrencyId
		WHERE [NonPOInvoiceId] = @NonPOInvoiceId

		IF OBJECT_ID(N'tempdb..#tmpNonPOPartDetails') IS NOT NULL
		BEGIN
		DROP TABLE #tmpNonPOPartDetails
		END
  
		CREATE TABLE #tmpNonPOPartDetails
		(
			ID [BIGINT] NOT NULL IDENTITY, 
			NonPOInvoicePartDetailsId [BIGINT] NULL,
			Amount [decimal](18,2) NULL,
			GlAccountId [BIGINT] NULL,
			Memo [varchar](500) NULL,
			ExtendedPrice [decimal](18,2) NULL,
		) 
		IF(@isItemLevelCalculation = 1)
		BEGIN			
				INSERT INTO #tmpNonPOPartDetails
				SELECT [NonPOInvoicePartDetailsId], [Amount], [GlAccountId], [Memo], [ExtendedPrice]
				FROM [dbo].[NonPOInvoicePartDetails] WITH(NOLOCK) WHERE NonPOInvoiceId = @NonPOInvoiceId
		END
		ELSE
		BEGIN
				INSERT INTO #tmpNonPOPartDetails
				SELECT  MAX(ISNULL([NonPOInvoicePartDetailsId],0)), SUM(ISNULL([Amount],0)), MAX([GlAccountId]), MAX([Memo]), SUM(ISNULL([ExtendedPrice],0))
				FROM [dbo].[NonPOInvoicePartDetails] WITH(NOLOCK) WHERE NonPOInvoiceId = @NonPOInvoiceId
		END


		SELECT @PartAmtSum = SUM(ExtendedPrice) FROM #tmpNonPOPartDetails

		SET @TotalNonPOPart = (SELECT COUNT(ID) FROM #tmpNonPOPartDetails)

		WHILE @NonPOPartStart <= @TotalNonPOPart
		BEGIN

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

			SELECT @CheckAmount = ExtendedPrice, @PartMemo = Memo, @PartGlAccId = GlAccountId FROM #tmpNonPOPartDetails WHERE [ID] = @NonPOPartStart
			SELECT @MasterCompanyId=MasterCompanyId,@UpdateBy=CreatedBy,@InvoiceDate = [InvoiceDate]  FROM dbo.NonPOInvoiceHeader WITH(NOLOCK) WHERE NonPOInvoiceId = @NonPOInvoiceId
			SELECT @DistributionMasterId =ID,@DistributionCode =DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK)  WHERE UPPER(DistributionCode)= UPPER('NonPOInvoice')	

			DECLARE @IsRestrict BIT;
			DECLARE @IsAccountByPass BIT;
			DECLARE @IsNewJE BIT = 0;

			EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdateBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

			IF(ISNULL(@CheckAmount,0) <> 0 AND ISNULL(@IsAccountByPass, 0) = 0)
			BEGIN		
				
				SELECT @StatusId =Id,@StatusName=name FROM dbo.BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
				SELECT top 1 @JournalTypeId =JournalTypeId FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId = @MasterCompanyId
				
				SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM dbo.JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
				SELECT @CurrentManagementStructureId =ManagementStructureId FROM dbo.Employee WITH(NOLOCK)  WHERE CONCAT(TRIM(REPLACE([FirstName], ' ', '')),'',TRIM(REPLACE([LastName], ' ', ''))) IN (replace(@UpdateBy, ' ', '')) AND MasterCompanyId=@MasterCompanyId
				SELECT @ModuleId = ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'NonPOInvoiceHeader'

				SELECT @VendorName = NPH.VendorName, @VendorId = NPH.VendorId, @ManagementStructureId = ManagementStructureId FROM dbo.NonPOInvoiceHeader NPH WITH(NOLOCK) WHERE NPH.NonPOInvoiceId =  @NonPOInvoiceId
				SELECT @LastMSLevel = LastMSLevel,@AllMSlevels = AllMSlevels FROM dbo.NonPOInvoiceManagementStructureDetails WITH(NOLOCK) WHERE EntityMSID = @ManagementStructureId AND ModuleID = @ModuleId AND ReferenceID = @NonPOInvoiceId

				INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFROM) 
				SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFROM 
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

				SELECT top 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
				FROM dbo.EntityStructureSetup est WITH(NOLOCK) 
				INNER JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
				INNER JOIN dbo.AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId AND acc.IsDeleted =0
				INNER JOIN dbo.NonPOInvoiceHeader npd WITH(NOLOCK) on npd.AccountingCalendarId = acc.AccountingCalendarId
				WHERE NonPOInvoiceId = @NonPOInvoiceId

				SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId AND StatusId=@StatusId AND AccountingPeriodId = @AccountingPeriodId AND MasterCompanyId = @MasterCompanyId

				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
				BEGIN 
					IF @BatchDetailCount = 0
					BEGIN
						SELECT 
							@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
							ELSE CAST(StartsFROM AS BIGINT) + 1 END 
							FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  	  
						SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
						SET @IsNewJE = 1;
					END
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
					SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId AND StatusId=@StatusId AND AccountingPeriodId = @AccountingPeriodId AND MasterCompanyId = @MasterCompanyId
					   SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END   
							 FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc   
          
					IF(@CurrentPeriodId =0)  
					begin  
					   Update [dbo].[BatchHeader] set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
					END  

					SET @IsBatchGenerated = 1;
				END


				IF @BatchDetailCount = 0
				BEGIN
					INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
					[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
					[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[AccountingPeriodId], [AccountingPeriod], [IsReversedJE])
					VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, @InvoiceDate, GETUTCDATE(), 
					@JournalTypeId, @JournalTypename, 1, 0, 0, @ManagementStructureId, 'Non PO Invoice', 
					NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0,@AccountingPeriodId,@AccountingPeriod, CASE WHEN @IsRevert > 0 THEN 1 ELSE NULL END)

					SET @BatchDetailCount = @BatchDetailCount + 1
					SET @JournalBatchDetailId = SCOPE_IDENTITY()
				END

				 ----- GL ACCOUNT PRESENT IN PART --------
			 				
				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId, @CRDRType =CRDRType,@IsAutoPost = ISNULL(IsAutoPost,0),
				 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName, @IsBypassAccounting = ISNULL(IsBypassAccounting,0)
				 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE UPPER([DistributionSetupCode]) = UPPER('NPO-DEPOSIT') 
				 AND DistributionMasterId = (SELECT TOP 1 ID FROM dbo.DistributionMaster WITH(NOLOCK) WHERE DistributionCode = 'NonPOInvoice')
				 AND MasterCompanyId = @MasterCompanyId;

				 SELECT @GlAccountId = GlAccountId, @GlAccountNumber = AccountCode, @GlAccountName = AccountName FROM [dbo].[GLAccount] WITH(NOLOCK) WHERE [GLAccountId] = @PartGlAccId AND MasterCompanyId = @MasterCompanyId;

				 IF(@IsBypassAccounting = 0)
				 BEGIN

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
				VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CRDRType = 1 THEN 1 ELSE 0 END,
					--CASE WHEN @CRDRType = 1 THEN @CheckAmount ELSE 0 END,
					--CASE WHEN @CRDRType = 1 THEN 0 ELSE ABS(@CheckAmount) END,
					CASE WHEN @CrDrType = 1 THEN CASE WHEN @IsRevert = 1 THEN 0 ELSE ABS(@CheckAmount) END ELSE CASE WHEN @IsRevert = 1 THEN ABS(@CheckAmount) ELSE 0 END END,
					CASE WHEN @CrDrType = 1 THEN CASE WHEN @IsRevert = 1 THEN ABS(@CheckAmount) ELSE 0 END ELSE CASE WHEN @IsRevert = 1 THEN 0 ELSE ABS(@CheckAmount) END END,
					@ManagementStructureId ,'NonPOInvoice',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReferenceNum,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@NonPOInvoiceId,@ReferenceModule)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
				INSERT INTO [NonPOInvoiceBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, CommonJournalBatchDetailId, VendorId, VendorName, NonPOInvoiceId, NPONumber, Memo)
				VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @CommonBatchDetailId , @VendorId, @VendorName, @NonPOInvoiceId, @ReferenceNum, @PartMemo)

				 END
				 ----- GL ACCOUNT PRESENT IN PART --------

				-----Account Payable--------

				IF @NonPOPartStart = @TotalNonPOPart
				BEGIN
						SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId, @CRDRType =CRDRType,
						@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName, @IsBypassAccounting = ISNULL(IsBypassAccounting,0)
						FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE UPPER([DistributionSetupCode]) = UPPER('NPO-ACCPAYABLE')
						AND DistributionMasterId = (SELECT TOP 1 ID FROM dbo.DistributionMaster WITH(NOLOCK) WHERE DistributionCode = 'NonPOInvoice')
						AND MasterCompanyId = @MasterCompanyId;

						IF(@IsBypassAccounting = 0)
						BEGIN

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
							[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
							[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
						VALUES	
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
							,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CRDRType = 1 THEN 1 ELSE 0 END,
							--CASE WHEN @CRDRType = 1 THEN @PartAmtSum ELSE 0 END,
							--CASE WHEN @CRDRType = 1 THEN 0 ELSE @PartAmtSum END,
							CASE WHEN @CrDrType = 1 THEN CASE WHEN @IsRevert = 1 THEN 0 ELSE ABS(@PartAmtSum) END ELSE CASE WHEN @IsRevert = 1 THEN ABS(@PartAmtSum) ELSE 0 END END,
							CASE WHEN @CrDrType = 1 THEN CASE WHEN @IsRevert = 1 THEN ABS(@PartAmtSum) ELSE 0 END ELSE CASE WHEN @IsRevert = 1 THEN 0 ELSE ABS(@PartAmtSum) END END,
							@ManagementStructureId ,'NonPOInvoice',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
							@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReferenceNum,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@NonPOInvoiceId,@ReferenceModule)

						SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  ----
					
					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [NonPOInvoiceBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, CommonJournalBatchDetailId, VendorId, VendorName, NonPOInvoiceId, NPONumber, Memo)
					VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @CommonBatchDetailId , @VendorId, @VendorName, @NonPOInvoiceId, @ReferenceNum, @PartMemo)

					END
				END
				 -----Account Payable--------

				SET @TotalDebit=0;
				SET @TotalCredit=0;
				SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
				UPDATE [dbo].[BatchDetails] SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate = GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchDetailId=@JournalBatchDetailId

				SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[BatchDetails]
				WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId AND IsDeleted=0 
				SET @TotalBalance =@TotalDebit-@TotalCredit

				IF @IsNewJE = 1
				BEGIN
					UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
				END
				UPDATE [dbo].[BatchHeader] SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId

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

			SET @NonPOPartStart = @NonPOPartStart + 1

		END

		UPDATE NonPOInvoiceHeader
		SET StatusId = (SELECT NonPOInvoiceHeaderStatusId FROM [dbo].[NonPOInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Posted'), [UpdatedDate] = GETUTCDATE(), [PostedDate] = GETUTCDATE()
		WHERE NonPOInvoiceId = @NonPOInvoiceId

		--Update status to open when unpost action click
		IF(@IsRevert = 1)
		BEGIN
			 UPDATE [dbo].[NonPOInvoiceHeader] SET StatusId = @NPOOpenStausId
			 WHERE [NonPOInvoiceId] = @NonPOInvoiceId;

			 --Hard delete after revert payment for vendorPayment.
			 IF NOT EXISTS(SELECT [ReadyToPayDetailsId] FROM [dbo].[VendorReadyToPayDetails] WITH(NOLOCK) WHERE [NonPOInvoiceId] = @NonPOInvoiceId)
			 BEGIN
				  DELETE [dbo].[VendorPaymentDetails] WHERE [NonPOInvoiceId] = @NonPOInvoiceId;
			 END

			 --Hard delete from approval
			 IF EXISTS(SELECT [NonPOApprovalId] FROM [dbo].[NonPOApproval] WITH(NOLOCK) WHERE [NonPOInvoiceId] = @NonPOInvoiceId)
			 BEGIN
				  DELETE [dbo].[NonPOApproval] WHERE [NonPOInvoiceId] = @NonPOInvoiceId;
			 END
		END
		ELSE
		BEGIN
			 EXEC [USP_AddVendorPaymentDetailsForNonPOById] @NonPOInvoiceId
		END
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PostNonPO_BatchDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@NonPOInvoiceId, '') + '' 
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