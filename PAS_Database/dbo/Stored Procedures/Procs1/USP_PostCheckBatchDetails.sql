/*************************************************************           
 ** File:   [USP_PostCheckBatchDetails]           
 ** Author: Satish Gohil
 ** Description: This stored procedure is used insert account report in batch
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
	2    07/06/2023   Satish Gohil  Batch detail table insert value added
	3    08/09/2023	  Satish Gohil	Modify(Dynamic distribution set and discount taken distribution added)
	4    08/14/2023   Moin Bloch    Added Check Payment Method to check only check payments
	5    11/22/2023   Moin Bloch    Modify(Added Accounting MS Entry)     
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_PostCheckBatchDetails]
@ReadyToPayId BIGINT,
@VendorId BIGINT
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
		DECLARE @CheckNumber VARCHAR(20);
		DECLARE @VendorName VARCHAR(50);
		DECLARE @CheckDate Datetime
		DECLARE @DiscountAmount DECIMAL(18,2)
		DECLARE @TotalAmount DECIMAL(18,2)
		DECLARE @CrDrType INT
		DECLARE @ValidDistribution BIT = 1;
		DECLARE @BankGLAccId BIGINT
		DECLARE @IsAccountByPass bit=0
		DECLARE @Check INT;
		DECLARE @AccountMSModuleId INT = 0

		SELECT @Check = [VendorPaymentMethodId] FROM [VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Check'; 
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

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
		
		SELECT @CheckAmount = SUM(ISNULL(PaymentMade,0)),@DiscountAmount = SUM(ISNULL(DiscountToken,0)),@TotalAmount = SUM(ISNULL(PaymentMade,0)) + SUM(ISNULL(DiscountToken,0)),@CheckNumber = MAX(CheckNumber),@CheckDate = MAX(CheckDate)
		FROM VendorReadyToPayDetails WITH(NOLOCK) WHERE ReadyToPayId = @ReadyToPayId AND VendorId = @VendorId AND [PaymentMethodId] = @Check; 	 		

		SELECT @MasterCompanyId=MasterCompanyId,@UpdateBy=CreatedBy from dbo.VendorReadyToPayHeader WITH(NOLOCK) WHERE ReadyToPayId = @ReadyToPayId
		SELECT @DistributionMasterId =ID,@DistributionCode =DistributionCode from DistributionMaster WITH(NOLOCK)  WHERE UPPER(DistributionCode)= UPPER('CheckPayment')	
		SELECT @StatusId =Id,@StatusName=name from BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
		SELECT top 1 @JournalTypeId =JournalTypeId from DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId
		SELECT @JournalBatchHeaderId =JournalBatchHeaderId from BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
		SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName from JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
		SELECT @CurrentManagementStructureId =ManagementStructureId from Employee WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (replace(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
		SELECT @ManagementStructureId = ManagementStructureId FROM DBO.VendorReadyToPayHeader WITH(NOLOCK) WHERE ReadyToPayId = @ReadyToPayId
		SELECT @ModuleId = ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'ReadyToPay'
		SELECT @LastMSLevel = LastMSLevel,@AllMSlevels = AllMSlevels FROM AccountingManagementStructureDetails WITH(NOLOCK) WHERE EntityMSID = @ManagementStructureId AND ModuleID = @ModuleId AND ReferenceID = @ReadyToPayId
		SELECT @VendorName = VendorName FROM dbo.Vendor WITH(NOLOCK) WHERE VendorId = @VendorId
		INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
		SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
		FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
		WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

		SELECT @IsAccountByPass =IsAccountByPass FROM dbo.MasterCompany WITH(NOLOCK)  WHERE MasterCompanyId= @MasterCompanyId

		IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
		BEGIN
			SET @ValidDistribution = 0;
		END

		SELECT @BankGLAccId = G.GLAccountId
				FROM dbo.LegalEntityBankingLockBox LB WITH(NOLOCK)
				INNER JOIN dbo.VendorReadyToPayHeader V WITH(NOLOCK) ON LB.LegalEntityBankingLockBoxId = V.BankId
				LEFT JOIN GLAccount G WITH(NOLOCK) ON LB.GLAccountId = G.GLAccountId
				WHERE ReadyToPayId= @ReadyToPayId

		IF (ISNULL(@BankGLAccId,0) = 0)
		BEGIN
			SET @ValidDistribution = 0;
		END

		IF(ISNULL(@TotalAmount,0) > 0 AND @ValidDistribution = 1 AND @IsAccountByPass = 0)
		BEGIN

			SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
			FROM EntityStructureSetup est WITH(NOLOCK) 
			INNER JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
			INNER JOIN dbo.AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
			WHERE est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  
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

			IF NOT EXISTS(select JournalBatchHeaderId from BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
			BEGIN
				IF NOT EXISTS(select JournalBatchHeaderId from BatchHeader WITH(NOLOCK))
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
				SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) from BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId   
				   SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END   
						 FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc   
          
				if(@CurrentPeriodId =0)  
				begin  
				   Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
				END  
			END


			INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
			[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
			[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[AccountingPeriodId],[AccountingPeriod])
			VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
			@JournalTypeId, @JournalTypename, 1, 0, 0, @ManagementStructureId, 'CheckPayment', 
			NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0,@AccountingPeriodId,@AccountingPeriod)
		
			SET @JournalBatchDetailId=SCOPE_IDENTITY()

			 -----Account Payable--------

			 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
			 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
			 from DistributionSetup WITH(NOLOCK)  WHERE DistributionSetupCode = 'CKSACCPAYBLE'
			 AND DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId


			 INSERT INTO [dbo].[CommonBatchDetails]
				(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
				[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
				[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
				[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
				VALUES	
				(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
				,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
				CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
				CASE WHEN @CrDrType = 1 THEN @TotalAmount ELSE 0 END,
				CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalAmount END,
				@ManagementStructureId ,'VendorPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
				@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
								
				INSERT INTO [dbo].[VendorPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId)
				VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@ReadyToPayId,@CheckNumber,@VendorId,@CheckDate,@CommonBatchDetailId)

			 -----Account Payable--------

			 -----Bank Account--------

				IF(@CheckAmount > 0)
				BEGIN
					SELECT top 1 @DistributionSetupId=ID,@DistributionName=[Name],@JournalTypeId =JournalTypeId,@CrDrType = CRDRType
					 FROM DistributionSetup WITH(NOLOCK)  WHERE  DistributionSetupCode = 'CKSBANKACCOUNT' 
					 AND DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId
				

					SELECT @GlAccountId = G.GLAccountId,@GlAccountNumber = G.AccountCode,@GlAccountName = G.AccountName 
					FROM LegalEntityBankingLockBox LB WITH(NOLOCK)
					INNER JOIN VendorReadyToPayHeader V WITH(NOLOCK) ON LB.LegalEntityBankingLockBoxId = V.BankId
					LEFT JOIN GLAccount G WITH(NOLOCK) ON LB.GLAccountId = G.GLAccountId
					WHERE ReadyToPayId= @ReadyToPayId


					INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @CheckAmount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @CheckAmount END,
					@ManagementStructureId ,'VendorPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
								
					INSERT INTO [dbo].VendorPaymentBatchDetails(JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@ReadyToPayId,@CheckNumber,@VendorId,@CheckDate,@CommonBatchDetailId)
				END
			 -----Bank Account--------

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
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @DiscountAmount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @DiscountAmount END,
					@ManagementStructureId ,'VendorPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
								
					INSERT INTO [dbo].VendorPaymentBatchDetails(JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@ReadyToPayId,@CheckNumber,@VendorId,@CheckDate,@CommonBatchDetailId)
				END
			 -----Discount Taken--------

			SET @TotalDebit=0;
			SET @TotalCredit=0;
			SELECT @TotalDebit = SUM(DebitAmount),
			       @TotalCredit=SUM(CreditAmount) 
			  FROM dbo.CommonBatchDetails WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
			Update BatchDetails SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchDetailId=@JournalBatchDetailId
		END

		
		SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM dbo.BatchDetails   
		WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 
		SET @TotalBalance =@TotalDebit-@TotalCredit

		UPDATE dbo.CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
	    Update dbo.BatchHeader SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId

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