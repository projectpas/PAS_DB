/*************************************************************           
 ** File:   [USP_PostCheckBatchDetailsForVoidCheck]           
 ** Author: Satish Gohil
 ** Description: This stored procedure is used insert account report in batch while void check
 ** Purpose:         
 ** Date:   06/30/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/30/2023   Satish Gohil	Created	
	2    08/09/2023	  Satish Gohil	Modify(Dynamic distribution set and discount taken distribution added)
	3    22/01/2024	  Moin Bloch	Modify(Added PdfPath Null when IsVoidedCheck Is True)
     
**************************************************************/

CREATE    PROCEDURE [dbo].[USP_PostCheckBatchDetailsForVoidCheck]
(
	@tbl_VoidedCheckListType VoidedCheckListType Readonly
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
		DECLARE @DistributionSetupId int=0
		DECLARE @Distributionname varchar(200) 
		DECLARE @GlAccountId int
		DECLARE @StartsFrom varchar(200)='00'
		DECLARE @GlAccountName varchar(200) 
		DECLARE @GlAccountNumber varchar(200) 
		DECLARE @CheckAmount DECIMAL(18,2)
		DECLARE @BankId INT =0;
		DECLARE @ManagementStructureId bigint
		DECLARE @LastMSLevel varchar(200)
		DECLARE @AllMSlevels varchar(max)
		DECLARE @ModuleId INT
		DECLARE @TotalDebit decimal(18, 2) =0;
		DECLARE @TotalCredit decimal(18, 2) =0;
		DECLARE @TotalBalance decimal(18, 2) =0;
		DECLARE @ReadyToPayId BIGINT;
		DECLARE @VendorId BIGINT;
		DECLARE @CheckNumber VARCHAR(20);
		DECLARE @VendorName VARCHAR(50);
		DECLARE @CheckDate Datetime
		DECLARE @CommonBatchDetailId BIGINT=0;
		DECLARE @DiscountAmount DECIMAL(18,2)
		DECLARE @TotalAmount DECIMAL(18,2)
		DECLARE @CrDrType INT
		DECLARE @ValidDistribution BIT = 1;
		DECLARE @BankGLAccId BIGINT

		IF OBJECT_ID(N'tempdb..#temptable') IS NOT NULL          
		BEGIN          
			DROP TABLE #temptable          
		END    

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

		CREATE TABLE #temptable(          
			ReadyToPayId BIGINT,
			VendorId BIGINT
	    )    

		INSERT INTO #temptable(ReadyToPayId,VendorId)
		SELECT ReadyToPayId,VendorId
		FROM @tbl_VoidedCheckListType

		DECLARE @PostBatchCursor AS CURSOR;
		SET @PostBatchCursor = CURSOR FOR	

		SELECT ReadyToPayId,VendorId FROM #temptable
		OPEN @PostBatchCursor;
		FETCH NEXT FROM @PostBatchCursor INTO @ReadyToPayId,@VendorId
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE dbo.VendorReadyToPayDetails
			SET IsVoidedCheck = 1,
				UpdatedDate = GETUTCDATE(),
				PdfPath = NULL
				WHERE ReadyToPayId = @ReadyToPayId AND VendorId = @VendorId 

			----- Update Vendor Payment details------
			UPDATE s1
			SET
			s1.PaymentMade =  s1.PaymentMade - s2.PaymentMade,
			s1.DiscountToken = s1.DiscountToken - s2.DiscountToken,
			s1.RemainingAmount = s1.RemainingAmount + s2.PaymentMade + s2.DiscountToken
			FROM dbo.VendorPaymentDetails s1 
			INNER JOIN dbo.VendorReadyToPayDetails s2 ON s1.VendorPaymentDetailsId = s2.VendorPaymentDetailsId
			WHERE s2.ReadyToPayId = @ReadyToPayId and s2.VendorId = @VendorId

			----- Update Vendor Payment details------

			SELECT @CheckAmount = SUM(ISNULL(PaymentMade,0)),@DiscountAmount = SUM(ISNULL(DiscountToken,0)),@TotalAmount = SUM(ISNULL(PaymentMade,0)) + SUM(ISNULL(DiscountToken,0)),@CheckNumber = MAX(CheckNumber),@CheckDate = MAX(CheckDate) 
			FROM dbo.VendorReadyToPayDetails WITH(NOLOCK) WHERE ReadyToPayId = @ReadyToPayId AND VendorId = @VendorId

			SELECT @MasterCompanyId=MasterCompanyId,@UpdateBy=CreatedBy from dbo.VendorReadyToPayHeader WITH(NOLOCK) where ReadyToPayId = @ReadyToPayId
			SELECT @DistributionMasterId =ID,@DistributionCode =DistributionCode from dbo.DistributionMaster WITH(NOLOCK)  where UPPER(DistributionCode)= UPPER('CheckPayment')	
			SELECT @StatusId =Id,@StatusName=name from dbo.BatchStatus WITH(NOLOCK)  where Name= 'Open'
			SELECT top 1 @JournalTypeId =JournalTypeId from dbo.DistributionSetup WITH(NOLOCK)  where DistributionMasterId =@DistributionMasterId
			SELECT @JournalBatchHeaderId =JournalBatchHeaderId from dbo.BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and StatusId=@StatusId
			SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName from dbo.JournalType WITH(NOLOCK)  where ID= @JournalTypeId
			SELECT @CurrentManagementStructureId =ManagementStructureId from dbo.Employee WITH(NOLOCK)  where CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (replace(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
			SELECT @ManagementStructureId = ManagementStructureId FROM DBO.VendorReadyToPayHeader WITH(NOLOCK) WHERE ReadyToPayId = @ReadyToPayId
			SELECT @ModuleId = ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'ReadyToPay'
			SELECT @LastMSLevel = LastMSLevel,@AllMSlevels = AllMSlevels FROM dbo.AccountingManagementStructureDetails WITH(NOLOCK) WHERE EntityMSID = @ManagementStructureId AND ModuleID = @ModuleId AND ReferenceID = @ReadyToPayId

			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
			FROM dbo.CodePrefixes CP WITH(NOLOCK) 
			INNER JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

			select top 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
			from dbo.EntityStructureSetup est WITH(NOLOCK) 
			inner join dbo.ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
			inner join dbo.AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
			where est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  
			and CAST(GETUTCDATE() as date)   >= CAST(FromDate as date) and  CAST(GETUTCDATE() as date) <= CAST(ToDate as date)

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
			BEGIN 
				SELECT 
					@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
					ELSE CAST(StartsFrom AS BIGINT) + 1 END 
					FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  	  
				SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN
				ROLLBACK TRAN;
			END

			IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
			BEGIN
				SET @ValidDistribution = 0;
			END

			SELECT @BankGLAccId = G.GLAccountId
					FROM LegalEntityBankingLockBox LB WITH(NOLOCK)
					INNER JOIN VendorReadyToPayHeader V WITH(NOLOCK) ON LB.LegalEntityBankingLockBoxId = V.BankId
					LEFT JOIN GLAccount G WITH(NOLOCK) ON LB.GLAccountId = G.GLAccountId
					WHERE ReadyToPayId= @ReadyToPayId

			IF (ISNULL(@BankGLAccId,0) = 0)
			BEGIN
				SET @ValidDistribution = 0;
			END


			IF(ISNULL(@TotalAmount,0) > 0 AND @ValidDistribution = 1)
			BEGIN

				IF NOT EXISTS(select JournalBatchHeaderId from dbo.BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
				BEGIN
					IF NOT EXISTS(select JournalBatchHeaderId from dbo.BatchHeader WITH(NOLOCK))
					BEGIN  
						set @batch ='001'  
						set @Currentbatch='001' 
					END
					ELSE
					BEGIN 
						SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1   
							ELSE  1 END   
						FROM dbo.BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc  

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
					Update dbo.BatchHeader set CurrentNumber=@CurrentNumber  where JournalBatchHeaderId= @JournalBatchHeaderId  
				END
				ELSE
				BEGIN 
					SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) from dbo.BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and StatusId=@StatusId   
						SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END   
								FROM BatchDetails WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc   
          
					if(@CurrentPeriodId =0)  
					begin  
						Update dbo.BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   where JournalBatchHeaderId= @JournalBatchHeaderId  
					END  
				END


				INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
				[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[AccountingPeriodId],[AccountingPeriod])
				VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
				@JournalTypeId, @JournalTypename, 1, 0, 0, 0, 'CheckPayment', 
				NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0,@AccountingPeriodId,@AccountingPeriod)
		
				SET @JournalBatchDetailId=SCOPE_IDENTITY()

				--------Account Payable--------

				SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
				 FROM DistributionSetup WITH(NOLOCK)  WHERE DistributionSetupCode = 'CKSACCPAYBLE'
				 AND DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId


				INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
				VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 0 THEN @TotalAmount ELSE 0 END,
					CASE WHEN @CrDrType = 0 THEN 0 ELSE @TotalAmount END,
					@ManagementStructureId ,'VendorPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()
			
				INSERT INTO [dbo].VendorPaymentBatchDetails(JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId)
				VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@ReadyToPayId,@CheckNumber,@VendorId,@CheckDate,@CommonBatchDetailId)
				-----Account Payable--------

				-----Bank Account--------
				IF(@CheckAmount > 0)
				BEGIN

					SELECT top 1 @DistributionSetupId=ID,@DistributionName=[Name],@JournalTypeId =JournalTypeId,@CrDrType = CRDRType
					 FROM DistributionSetup WITH(NOLOCK)  WHERE  DistributionSetupCode = 'CKSBANKACCOUNT' 
					 AND DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId
				
					SELECT @GlAccountId = G.GLAccountId,@GlAccountNumber = G.AccountCode,@GlAccountName = G.AccountName 
					FROM dbo.LegalEntityBankingLockBox LB WITH(NOLOCK)
					INNER JOIN dbo.VendorReadyToPayHeader V WITH(NOLOCK) ON LB.LegalEntityBankingLockBoxId = V.BankId
					LEFT JOIN dbo.GLAccount G WITH(NOLOCK) ON LB.GLAccountId = G.GLAccountId
					WHERE ReadyToPayId= @ReadyToPayId


					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
						[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
						[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES	
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
						,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
						CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
						CASE WHEN @CrDrType = 0 THEN @CheckAmount ELSE 0 END,
						CASE WHEN @CrDrType = 0 THEN 0 ELSE @CheckAmount END,
						@ManagementStructureId ,'VendorPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
						@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()
			
					INSERT INTO [dbo].VendorPaymentBatchDetails(JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@ReadyToPayId,@CheckNumber,@VendorId,@CheckDate,@CommonBatchDetailId)
				END
				------Bank Account--------
				-----Discount Taken--------

				IF(@DiscountAmount > 0)
				BEGIN
					SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
					@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
					 from DistributionSetup WITH(NOLOCK)  WHERE  DistributionSetupCode = 'CKSDISCOUNTTAKEN' 
					 AND DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId
	

					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
						[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
						[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES	
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
						,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
						CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
						CASE WHEN @CrDrType = 0 THEN @DiscountAmount ELSE 0 END,
						CASE WHEN @CrDrType = 0 THEN 0 ELSE @DiscountAmount END,
						@ManagementStructureId ,'VendorPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
						@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()
			
					INSERT INTO [dbo].VendorPaymentBatchDetails(JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@ReadyToPayId,@CheckNumber,@VendorId,@CheckDate,@CommonBatchDetailId)
				END
				-----Discount Taken--------
				
				SET @TotalDebit=0;
				SET @TotalCredit=0;
				SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM dbo.CommonBatchDetails WITH(NOLOCK) where JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
				Update dbo.BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   where JournalBatchDetailId=@JournalBatchDetailId
			
				IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
				BEGIN
					TRUNCATE TABLE #tmpCodePrefixes
				END
			END

			FETCH NEXT FROM @PostBatchCursor INTO @ReadyToPayId,@VendorId
		END
		CLOSE @PostBatchCursor
		DEALLOCATE @PostBatchCursor

		SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails 
		WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 
		SET @TotalBalance =@TotalDebit-@TotalCredit

		UPDATE dbo.CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
	    Update dbo.BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy where JournalBatchHeaderId= @JournalBatchHeaderId

	END TRY
	BEGIN CATCH 
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_PostROCreateStocklineBatchDetails' 
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