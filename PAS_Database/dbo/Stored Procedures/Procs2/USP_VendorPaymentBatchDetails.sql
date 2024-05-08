
/*************************************************************           
 ** File:   [USP_PostWireTransferBatchDetails]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used insert account report in batch
 ** Purpose:         
 ** Date:   08/11/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/11/2023   Moin Bloch	Created	
	2    09/22/2023   AMIT GHEDIYA	Added for creditmemo pay for vendorpayment.	
	3    04/04/2024   AMIT GHEDIYA	Entry With Details data id.
	
	EXEC USP_VendorPaymentBatchDetails 122
	
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_VendorPaymentBatchDetails]
@ReadyToPayId BIGINT,
@ReadyToPayDetailsId BIGINT
AS
BEGIN 
	BEGIN TRY
	BEGIN TRANSACTION  
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
		DECLARE @StartsFrom varchar(200)='00'
		DECLARE @GlAccountName varchar(200) 
		DECLARE @GlAccountNumber varchar(200) 
		DECLARE @CheckAmount DECIMAL(18,2)
		DECLARE @BankId INT =0;
		DECLARE @ManagementStructureId bigint;
		DECLARE @LastMSLevel varchar(200);
		DECLARE @AllMSlevels varchar(max);
		DECLARE @ModuleId INT;
		DECLARE @TotalDebit decimal(18, 2) =0;
		DECLARE @TotalCredit decimal(18, 2) =0;
		DECLARE @TotalBalance decimal(18, 2) =0;
		DECLARE @CheckNumber VARCHAR(20);
		DECLARE @VendorName VARCHAR(50);
		DECLARE @CheckDate Datetime;
		DECLARE @DiscountAmount DECIMAL(18,2);
		DECLARE @TotalAmount DECIMAL(18,2);
		DECLARE @CrDrType INT;
		DECLARE @ValidDistribution BIT = 1;
		DECLARE @BankGLAccId BIGINT
		DECLARE @IsAccountByPass bit=0
		DECLARE @PaymentMethodId INT;
		DECLARE @VendorId BIGINT;
		DECLARE @ReceivingReconciliationId BIGINT;
		DECLARE @IsVendorPayment BIT;
		DECLARE @VendorCreditMemoId BIGINT;
		DECLARE @VendorPaymentDetailsId BIGINT;

		DECLARE @Check INT;
		DECLARE @DomesticWire INT;
		DECLARE @InternationalWire INT;
		DECLARE @ACHTransfer INT;
		DECLARE @CreditCard INT;
		DECLARE @MasterLoopID AS INT;
		DECLARE @MasterLoopIDs AS INT;
		DECLARE @CreditMemoLoopID AS INT;
		DECLARE @StatusIdClosed AS BIGINT;
		DECLARE @AccountMSModuleId INT = 0

		SELECT @Check = [VendorPaymentMethodId] FROM [VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Check'; 
		SELECT @DomesticWire = [VendorPaymentMethodId] FROM [VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Domestic Wire';
		SELECT @InternationalWire = [VendorPaymentMethodId] FROM [VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'International Wire';
		SELECT @ACHTransfer = [VendorPaymentMethodId] FROM [VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'ACH Transfer';
		SELECT @CreditCard = [VendorPaymentMethodId] FROM [VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Credit Card';
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
					   
		IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCodePrefixes
		END

		IF OBJECT_ID(N'tempdb..#tmpVendorReadyToPayDetails') IS NOT NULL
		BEGIN
			DROP TABLE #tmpVendorReadyToPayDetails
		END

		IF OBJECT_ID(N'tempdb..#tmpVendorReadyToPayDetail') IS NOT NULL
		BEGIN
			DROP TABLE #tmpVendorReadyToPayDetail
		END

		IF OBJECT_ID(N'tempdb..#tmpCreditMemo') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCreditMemo
		END

		CREATE TABLE #tmpCreditMemo
		(
			[ID] BIGINT NOT NULL IDENTITY, 						
			[VendorId] BIGINT,
			[VendorPaymentDetailsId] BIGINT,
			[VendorCreditMemoId] BIGINT
		)
					  	  
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

		SELECT @MasterCompanyId = [MasterCompanyId], @UpdateBy = [CreatedBy] FROM [dbo].[VendorReadyToPayHeader] WITH(NOLOCK) WHERE [ReadyToPayId] = @ReadyToPayId;
			
		INSERT INTO #tmpCodePrefixes ([CodePrefixId],[CodeTypeId],[CurrentNumber], [CodePrefix], [CodeSufix], [StartsFrom]) 
				SELECT [CodePrefixId], CP.[CodeTypeId], [CurrentNummber], [CodePrefix], [CodeSufix], [StartsFrom]
				  FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) 
				  JOIN [dbo].[CodeTypes] CT WITH(NOLOCK) ON CP.[CodeTypeId] = CT.[CodeTypeId]
				 WHERE CT.[CodeTypeId] IN (@CodeTypeId) AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0;

		IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId))
		BEGIN 
			SELECT @currentNo = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 
						ELSE CAST([StartsFrom] AS BIGINT) + 1 END 
						FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  	  
					SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT [CodePrefix] FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId), (SELECT [CodeSufix] FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId)))
		END
		ELSE 
		BEGIN
			ROLLBACK TRAN;
		END

		CREATE TABLE #tmpVendorReadyToPayDetails
		(
			[ID] BIGINT NOT NULL IDENTITY, 						
			[VendorId] BIGINT,
			[PaymentMethodId] INT,
			[PaymentMade] DECIMAL(18,2),
			[DiscountToken] DECIMAL(18,2),
			[CheckNumber] NVARCHAR(50),
			[CheckDate] DATETIME,
			[ReceivingReconciliationId] BIGINT,
			[IsVendorPayment] BIT
		)

		CREATE TABLE #tmpVendorReadyToPayDetail
		(
			[ID] BIGINT NOT NULL IDENTITY, 						
			[VendorId] BIGINT,
			[PaymentMethodId] INT,
			[PaymentMade] DECIMAL(18,2),
			[DiscountToken] DECIMAL(18,2),
			[CheckNumber] NVARCHAR(50),
			[CheckDate] DATETIME,
			[ReceivingReconciliationId] BIGINT,
			[IsVendorPayment] BIT,
			VendorPaymentDetailsId BIGINT
		)

		INSERT INTO #tmpVendorReadyToPayDetails 
		           ([VendorId]
				   ,[PaymentMethodId]
				   ,[PaymentMade]
				   ,[DiscountToken]				  
				   ,[CheckNumber]
				   ,[CheckDate]
				   ,[ReceivingReconciliationId]
				   ,[IsVendorPayment])		    
			 SELECT [VendorId]
				   ,[PaymentMethodId]
				   ,SUM(ISNULL([PaymentMade],0)) 
				   ,SUM(ISNULL([DiscountToken],0))				   
				   ,[CheckNumber]
				   ,CAST([CheckDate] AS DATE) [CheckDate]
				   ,[ReceivingReconciliationId]
				   ,CASE WHEN ISNULL([CreditMemoAmount],0) > 0 THEN 1 ELSE 0 END
			
			   FROM [VendorReadyToPayDetails] WHERE [ReadyToPayId] = @ReadyToPayId AND ReadyToPayDetailsId = @ReadyToPayDetailsId AND [PaymentMethodId] <> @Check
			   GROUP BY [VendorId],[PaymentMethodId],[CheckNumber],CAST([CheckDate] AS DATE),[ReceivingReconciliationId],[CreditMemoAmount]

		INSERT INTO #tmpVendorReadyToPayDetail
		           ([VendorId]
				   ,[PaymentMethodId]
				   ,[PaymentMade]
				   ,[DiscountToken]				  
				   ,[CheckNumber]
				   ,[CheckDate]
				   ,[ReceivingReconciliationId]
				   ,[IsVendorPayment],VendorPaymentDetailsId)		    
			 SELECT [VendorId]
				   ,[PaymentMethodId]
				   --,SUM(ISNULL([PaymentMade],0)) 
				   --,SUM(ISNULL([DiscountToken],0))	
				    ,ISNULL([PaymentMade],0)
				   ,ISNULL([DiscountToken],0)			
				   ,[CheckNumber]
				   ,CAST([CheckDate] AS DATE) [CheckDate]
				   ,[ReceivingReconciliationId]
				   ,CASE WHEN ISNULL([CreditMemoAmount],0) > 0 THEN 1 ELSE 0 END
				   ,VendorPaymentDetailsId
			   FROM [VendorReadyToPayDetails] WHERE [ReadyToPayId] = @ReadyToPayId AND ReadyToPayDetailsId = @ReadyToPayDetailsId
			   --GROUP BY [VendorId],[PaymentMethodId],[CheckNumber],CAST([CheckDate] AS DATE),[ReceivingReconciliationId],[CreditMemoAmount]

		SELECT  @MasterLoopID = MAX(ID) FROM #tmpVendorReadyToPayDetails
		SELECT  @MasterLoopIDs = MAX(ID) FROM #tmpVendorReadyToPayDetail

		WHILE(@MasterLoopID > 0)
		BEGIN
			SELECT @PaymentMethodId = [PaymentMethodId], 
			       @VendorId = [VendorId],
			       @CheckAmount = [PaymentMade], 
				   @DiscountAmount = [DiscountToken],
				   @TotalAmount = [PaymentMade] + [DiscountToken],
				   @CheckNumber = [CheckNumber],
				   @CheckDate = [CheckDate],
				   @ReceivingReconciliationId = [ReceivingReconciliationId],
				   @IsVendorPayment = [IsVendorPayment]
			  FROM #tmpVendorReadyToPayDetails WHERE ID  = @MasterLoopID;	
			  
				IF(@PaymentMethodId = @DomesticWire OR @PaymentMethodId = @InternationalWire)
				BEGIN
					SELECT @DistributionMasterId = [ID], 
					       @DistributionCode = [DistributionCode] 
				      FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE UPPER([DistributionCode])= UPPER('WIRETRANSFER');	
				END
				IF(@PaymentMethodId = @ACHTransfer)
				BEGIN
					SELECT @DistributionMasterId = [ID], 
					       @DistributionCode = [DistributionCode] 
				      FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE UPPER([DistributionCode])= UPPER('ACHTRANSFER');	
				END
				IF(@PaymentMethodId = @CreditCard)
				BEGIN
					SELECT @DistributionMasterId = [ID], 
					       @DistributionCode = [DistributionCode] 
				      FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE UPPER([DistributionCode])= UPPER('CREDITCARDPAYMENT');	
				END		
									   
				SELECT @StatusId = [Id], @StatusName = [name] FROM [dbo].[BatchStatus] WITH(NOLOCK) WHERE [Name] = 'Open';

				SELECT TOP 1 @JournalTypeId = [JournalTypeId]  FROM  [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId;

				SELECT @JournalBatchHeaderId = [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [StatusId] = @StatusId;
		
				SELECT @JournalTypeCode = [JournalTypeCode], @JournalTypename = [JournalTypeName] FROM [dbo].[JournalType] WITH(NOLOCK)  WHERE [ID] = @JournalTypeId;
		
				SELECT @CurrentManagementStructureId = [ManagementStructureId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (REPLACE(@UpdateBy, ' ', '')) AND [MasterCompanyId] = @MasterCompanyId;
		
				SELECT @ManagementStructureId = [ManagementStructureId] FROM [dbo].[VendorReadyToPayHeader] WITH(NOLOCK) WHERE [ReadyToPayId] = @ReadyToPayId;

				SELECT @ModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ReadyToPay';

				SELECT @LastMSLevel = [LastMSLevel],@AllMSlevels = [AllMSlevels] FROM [dbo].[AccountingManagementStructureDetails] WITH(NOLOCK) WHERE [EntityMSID] = @ManagementStructureId AND [ModuleID] = @ModuleId AND [ReferenceID] = @ReadyToPayId;

				SELECT @VendorName = [VendorName] FROM dbo.Vendor WITH(NOLOCK) WHERE [VendorId] = @VendorId;

				SELECT @IsAccountByPass = [IsAccountByPass] FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;

				SELECT @BankGLAccId = G.[GLAccountId] 
				  FROM [dbo].[LegalEntityBankingLockBox] LB WITH(NOLOCK)
				  INNER JOIN [dbo].[VendorReadyToPayHeader] V WITH(NOLOCK) ON LB.LegalEntityBankingLockBoxId = V.BankId
				   LEFT JOIN [dbo].[GLAccount] G WITH(NOLOCK) ON LB.GLAccountId = G.GLAccountId
				  WHERE [ReadyToPayId] = @ReadyToPayId;
				  				
		
				IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([GlAccountId],0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END
			   
				IF (ISNULL(@BankGLAccId,0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END

				IF(ISNULL(@TotalAmount,0) > 0 AND @ValidDistribution = 1 AND @IsAccountByPass = 0)
				BEGIN
					
					SELECT TOP 1 @AccountingPeriodId = acc.[AccountingCalendarId],
								 @AccountingPeriod = [PeriodName]
					FROM [dbo].[EntityStructureSetup] est WITH(NOLOCK) 
					INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
					INNER JOIN [dbo].[AccountingCalendar] acc WITH(NOLOCK) ON msl.LegalEntityId = acc.LegalEntityId AND acc.IsDeleted = 0
					WHERE est.[EntityStructureId] = @CurrentManagementStructureId 
					  AND acc.[MasterCompanyId] = @MasterCompanyId  
					  AND CAST(GETUTCDATE() AS DATE) >= CAST([FromDate] AS DATE) AND CAST(GETUTCDATE() AS DATE) <= CAST([ToDate] AS DATE)
					
					IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId] = @MasterCompanyId AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId] = @StatusId)
					BEGIN
						IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
						BEGIN  
							SET @batch ='001'  
							SET @Currentbatch='001' 
						END
						ELSE
						BEGIN 							
							SELECT TOP 1 @Currentbatch = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1   
							  ELSE  1 END   
							FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY [JournalBatchHeaderId] DESC  

							IF(CAST(@Currentbatch AS BIGINT) >99)  
							BEGIN
								SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
								  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END   
							END  
							ELSE IF(CAST(@Currentbatch AS BIGINT) >9)  
							BEGIN    
								SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
								  ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END   
							END
							ELSE
							BEGIN
							   SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
								  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END     
							END  
						END
			
						SET @CurrentNumber = CAST(@Currentbatch AS BIGINT)     
						SET @batch = CAST(@JournalTypeCode +' '+ CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))  
											
						INSERT INTO [dbo].[BatchHeader]
							       ([BatchName]
							       ,[CurrentNumber]
							       ,[EntryDate]
							       ,[AccountingPeriod]
							       ,[AccountingPeriodId]
							       ,[StatusId]
							       ,[StatusName]
							       ,[JournalTypeId]
							       ,[JournalTypeName]
							       ,[TotalDebit]
							       ,[TotalCredit]
							       ,[TotalBalance]
							       ,[MasterCompanyId]
							       ,[CreatedBy]
							       ,[UpdatedBy]
							       ,[CreatedDate]
							       ,[UpdatedDate]
							       ,[IsActive]
							       ,[IsDeleted]
							       ,[Module])    
						    VALUES (@batch
							       ,@CurrentNumber
							       ,GETUTCDATE()
							       ,@AccountingPeriod
							       ,@AccountingPeriodId
							       ,@StatusId
							       ,@StatusName
							       ,@JournalTypeId
							       ,@JournalTypename
							       ,@Amount
							       ,@Amount
							       ,0
							       ,@MasterCompanyId
							       ,@UpdateBy
							       ,@UpdateBy
							       ,GETUTCDATE()
							       ,GETUTCDATE()
							       ,1
							       ,0
							       ,@JournalTypeCode);    
                           
						SELECT @JournalBatchHeaderId = SCOPE_IDENTITY() 
				
						UPDATE [dbo].[BatchHeader] SET [CurrentNumber] = @CurrentNumber WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;  
				    END
					ELSE
					BEGIN 
						SELECT @JournalBatchHeaderId = [JournalBatchHeaderId],
							   @CurrentPeriodId = ISNULL([AccountingPeriodId],0) 
						  FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [StatusId] = @StatusId   

						SELECT @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE  1 END   
						 FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  ORDER BY JournalBatchDetailId DESC   
          
						IF(@CurrentPeriodId =0)  
						BEGIN  
						   UPDATE [dbo].[BatchHeader] 
							  SET [AccountingPeriodId] = @AccountingPeriodId,
								  [AccountingPeriod] = @AccountingPeriod   
							WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;  
						END  
					END
					
					INSERT INTO [dbo].[BatchDetails]
						       ([JournalTypeNumber]
						       ,[CurrentNumber]
						       ,[DistributionSetupId]
						       ,[DistributionName]
						       ,[JournalBatchHeaderId]
						       ,[LineNumber]
						       ,[GlAccountId]
						       ,[GlAccountNumber]
						       ,[GlAccountName]
						       ,[TransactionDate]
						       ,[EntryDate]
						       ,[JournalTypeId]
						       ,[JournalTypeName]
						       ,[IsDebit]
						       ,[DebitAmount]
						       ,[CreditAmount]
						       ,[ManagementStructureId]
						       ,[ModuleName]
						       ,[LastMSLevel]
						       ,[AllMSlevels]
						       ,[MasterCompanyId]
						       ,[CreatedBy]
						       ,[UpdatedBy]
						       ,[CreatedDate]
						       ,[UpdatedDate]
						       ,[IsActive]
						       ,[IsDeleted]
						       ,[AccountingPeriodId]
						       ,[AccountingPeriod])
						 VALUES(@JournalTypeNumber
						       ,@currentNo
						       ,0
						       ,NULL
						       ,@JournalBatchHeaderId
						       ,1
						       ,0
						       ,NULL
						       ,NULL
						       ,GETUTCDATE()
						       ,GETUTCDATE()
						       ,@JournalTypeId
						       ,@JournalTypename
						       ,1
						       ,0
						       ,0
						       ,@ManagementStructureId
						       ,@DistributionCode               ------------------------------------- Check  Payment   
						       ,NULL
						       ,NULL
						       ,@MasterCompanyId
						       ,@UpdateBy
						       ,@UpdateBy
						       ,GETUTCDATE()
						       ,GETUTCDATE()
						       ,1
						       ,0
						       ,@AccountingPeriodId
						       ,@AccountingPeriod)
		
					SET @JournalBatchDetailId = SCOPE_IDENTITY()
			
					-----Account Payable Start--------

					SELECT TOP 1 @DistributionSetupId = [ID],
							     @DistributionName = [Name],
							     @JournalTypeId = [JournalTypeId],
							     @GlAccountId = [GlAccountId],
							     @GlAccountNumber = [GlAccountNumber],
							     @GlAccountName = [GlAccountName],
							     @CrDrType = CRDRType 
						    FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
						   WHERE [DistributionSetupCode] = CASE WHEN @PaymentMethodId = @DomesticWire OR @PaymentMethodId = @InternationalWire THEN 'WRT-ACCOUNTSPAYABLE' 
						                                        WHEN @PaymentMethodId = @ACHTransfer THEN 'ACHT-ACCOUNTSPAYABLE'
																WHEN @PaymentMethodId = @CreditCard  THEN 'CCP-ACCOUNTSPAYABLE'
															END
						     AND [DistributionMasterId] = @DistributionMasterId 
						     AND [MasterCompanyId] = @MasterCompanyId
							 
					INSERT INTO [dbo].[CommonBatchDetails]
							   ([JournalBatchDetailId]
							   ,[JournalTypeNumber]
							   ,[CurrentNumber]
							   ,[DistributionSetupId]
							   ,[DistributionName]
							   ,[JournalBatchHeaderId]
							   ,[LineNumber]
							   ,[GlAccountId]
							   ,[GlAccountNumber]
							   ,[GlAccountName] 
							   ,[TransactionDate]
							   ,[EntryDate] 
							   ,[JournalTypeId]
							   ,[JournalTypeName]
							   ,[IsDebit]
							   ,[DebitAmount] 
							   ,[CreditAmount]
							   ,[ManagementStructureId]
							   ,[ModuleName]
							   ,[LastMSLevel]
							   ,[AllMSlevels]
							   ,[MasterCompanyId]
							   ,[CreatedBy]
							   ,[UpdatedBy]
							   ,[CreatedDate]
							   ,[UpdatedDate] 
							   ,[IsActive] 
							   ,[IsDeleted])
					    VALUES	
							   (@JournalBatchDetailId
							   ,@JournalTypeNumber
							   ,@currentNo
							   ,@DistributionSetupId
							   ,@DistributionName
							   ,@JournalBatchHeaderId
							   ,1 
							   ,@GlAccountId 
							   ,@GlAccountNumber 
							   ,@GlAccountName
							   ,GETUTCDATE()
							   ,GETUTCDATE()
							   ,@JournalTypeId 
							   ,@JournalTypename
							   ,CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END
							   ,CASE WHEN @CrDrType = 1 THEN @TotalAmount ELSE 0 END
							   ,CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalAmount END
							   ,@ManagementStructureId 
							   ,'VendorPayment'
							   ,@LastMSLevel
							   ,@AllMSlevels 
							   ,@MasterCompanyId
							   ,@UpdateBy
							   ,@UpdateBy
							   ,GETUTCDATE()
							   ,GETUTCDATE()
							   ,1
							   ,0)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [dbo].[VendorPaymentBatchDetails]
							   ([JournalBatchHeaderId]
							   ,[JournalBatchDetailId]
							   ,[ReferenceId]
							   ,[DocumentNo]
							   ,[VendorId]
							   ,[CheckDate]
							   ,[CommonJournalBatchDetailId])
					     VALUES(@JournalBatchHeaderId
							   ,@JournalBatchDetailId
							   ,@ReadyToPayDetailsId
							   ,@CheckNumber
							   ,@VendorId
							   ,@CheckDate
							   ,@CommonBatchDetailId)

					-----Account Payable End--------

					-----Bank Account Start--------

					IF(@CheckAmount > 0)
				    BEGIN					
						SELECT TOP 1 @DistributionSetupId = [ID], @DistributionName = [Name], 
						             @JournalTypeId = [JournalTypeId], @CrDrType = [CRDRType]
							  FROM [dbo].[DistributionSetup] WITH(NOLOCK)							
							 WHERE [DistributionSetupCode] = CASE WHEN @PaymentMethodId = @DomesticWire OR @PaymentMethodId = @InternationalWire THEN 'WRT-BANKACCOUNT' 
						                                        WHEN @PaymentMethodId = @ACHTransfer THEN 'ACHT-BANKACCOUNT'
																WHEN @PaymentMethodId = @CreditCard  THEN 'CCP-BANKACCOUNT'
															 END
							   AND [DistributionMasterId] = @DistributionMasterId 
							   AND [MasterCompanyId] = @MasterCompanyId;				

						SELECT @GlAccountId = G.[GLAccountId], @GlAccountNumber = G.[AccountCode], @GlAccountName = G.[AccountName]
							FROM [dbo].[LegalEntityBankingLockBox] LB WITH(NOLOCK)
							INNER JOIN [dbo].[VendorReadyToPayHeader] V WITH(NOLOCK) ON LB.[LegalEntityBankingLockBoxId] = V.[BankId]
							 LEFT JOIN [dbo].[GLAccount] G WITH(NOLOCK) ON LB.[GLAccountId] = G.[GLAccountId]
							WHERE [ReadyToPayId] = @ReadyToPayId;
							
						INSERT INTO [dbo].[CommonBatchDetails]
							       ([JournalBatchDetailId]
							       ,[JournalTypeNumber]
							       ,[CurrentNumber]
							       ,[DistributionSetupId]
							       ,[DistributionName]
							       ,[JournalBatchHeaderId]
							       ,[LineNumber]
							       ,[GlAccountId]
							       ,[GlAccountNumber]
							       ,[GlAccountName] 
							       ,[TransactionDate]
							       ,[EntryDate] 
							       ,[JournalTypeId]
							       ,[JournalTypeName]
							       ,[IsDebit]
							       ,[DebitAmount] 
							       ,[CreditAmount]
							       ,[ManagementStructureId]
							       ,[ModuleName]
							       ,[LastMSLevel]
							       ,[AllMSlevels]
							       ,[MasterCompanyId]
							       ,[CreatedBy]
							       ,[UpdatedBy]
							       ,[CreatedDate]
							       ,[UpdatedDate] 
							       ,[IsActive] 
							       ,[IsDeleted])
							VALUES	
							       (@JournalBatchDetailId
							       ,@JournalTypeNumber
							       ,@currentNo
							       ,@DistributionSetupId
							       ,@DistributionName
							       ,@JournalBatchHeaderId
							       ,1
							       ,@GlAccountId 
							       ,@GlAccountNumber 
							       ,@GlAccountName
							       ,GETUTCDATE()
							       ,GETUTCDATE()
							       ,@JournalTypeId 
							       ,@JournalTypename
							       ,CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END
							       ,CASE WHEN @CrDrType = 1 THEN @CheckAmount ELSE 0 END
							       ,CASE WHEN @CrDrType = 1 THEN 0 ELSE @CheckAmount END
							       ,@ManagementStructureId 
							       ,'VendorPayment'
							       ,@LastMSLevel
							       ,@AllMSlevels 
							       ,@MasterCompanyId
							       ,@UpdateBy
							       ,@UpdateBy
							       ,GETUTCDATE()
							       ,GETUTCDATE()
							       ,1
							       ,0)
					      
						SET @CommonBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					      
						INSERT INTO [dbo].[VendorPaymentBatchDetails]
							   ([JournalBatchHeaderId]
							   ,[JournalBatchDetailId]
							   ,[ReferenceId]
							   ,[DocumentNo]
							   ,[VendorId]
							   ,[CheckDate]
							   ,[CommonJournalBatchDetailId])
						 VALUES
							   (@JournalBatchHeaderId
							   ,@JournalBatchDetailId
							   ,@ReadyToPayDetailsId
							   ,@CheckNumber
							   ,@VendorId
							   ,@CheckDate
							   ,@CommonBatchDetailId)
					END

					-----Bank Account End--------

					-----Discount Taken Start--------

					IF(@DiscountAmount > 0)
					BEGIN						
						SELECT TOP 1 @DistributionSetupId =[ID],
								     @DistributionName = [Name],
								     @JournalTypeId = [JournalTypeId],
								     @GlAccountId = [GlAccountId],
								     @GlAccountNumber = [GlAccountNumber],
								     @GlAccountName = [GlAccountName],
								     @CrDrType = [CRDRType]
						        FROM [dbo].[DistributionSetup] WITH(NOLOCK)						     
							   WHERE [DistributionSetupCode] = CASE WHEN @PaymentMethodId = @DomesticWire OR @PaymentMethodId = @InternationalWire THEN 'WRT-DISCOUNTTAKEN' 
						                                        WHEN @PaymentMethodId = @ACHTransfer THEN 'ACHT-DISCOUNTTAKEN'
																WHEN @PaymentMethodId = @CreditCard  THEN 'CCP-DISCOUNTTAKEN'
															END
						         AND [DistributionMasterId] = @DistributionMasterId 
						         AND [MasterCompanyId] = @MasterCompanyId;					

						INSERT INTO [dbo].[CommonBatchDetails]
							        ([JournalBatchDetailId]
							        ,[JournalTypeNumber]
							        ,[CurrentNumber]
							        ,[DistributionSetupId]
							        ,[DistributionName]
							        ,[JournalBatchHeaderId]
							        ,[LineNumber]
							        ,[GlAccountId]
							        ,[GlAccountNumber]
							        ,[GlAccountName] 
							        ,[TransactionDate]
							        ,[EntryDate] 
							        ,[JournalTypeId]
							        ,[JournalTypeName]
							        ,[IsDebit]
							        ,[DebitAmount] 
							        ,[CreditAmount]
							        ,[ManagementStructureId]
							        ,[ModuleName]
							        ,[LastMSLevel]
							        ,[AllMSlevels]
							        ,[MasterCompanyId]
							        ,[CreatedBy]
							        ,[UpdatedBy]
							        ,[CreatedDate]
							        ,[UpdatedDate] 
							        ,[IsActive] 
							        ,[IsDeleted])
							VALUES	
							        (@JournalBatchDetailId
							        ,@JournalTypeNumber
							        ,@currentNo
							        ,@DistributionSetupId
							        ,@DistributionName
							        ,@JournalBatchHeaderId
							        ,1 
							        ,@GlAccountId 
							        ,@GlAccountNumber 
							        ,@GlAccountName
							        ,GETUTCDATE()
							        ,GETUTCDATE()
							        ,@JournalTypeId 
							        ,@JournalTypename
							        ,CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END
							        ,CASE WHEN @CrDrType = 1 THEN @DiscountAmount ELSE 0 END
							        ,CASE WHEN @CrDrType = 1 THEN 0 ELSE @DiscountAmount END
							        ,@ManagementStructureId 
							        ,'VendorPayment'
							        ,@LastMSLevel
							        ,@AllMSlevels 
							        ,@MasterCompanyId
							        ,@UpdateBy
							        ,@UpdateBy
							        ,GETUTCDATE()
							        ,GETUTCDATE()
							        ,1
							        ,0);

						SET @CommonBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
						INSERT INTO [dbo].[VendorPaymentBatchDetails]
							       ([JournalBatchHeaderId]
							       ,[JournalBatchDetailId]
							       ,[ReferenceId]
							       ,[DocumentNo]
							       ,[VendorId]
							       ,[CheckDate]
							       ,[CommonJournalBatchDetailId])
							 VALUES(@JournalBatchHeaderId
							       ,@JournalBatchDetailId
							       ,@ReadyToPayDetailsId
							       ,@CheckNumber
							       ,@VendorId
							       ,@CheckDate
							       ,@CommonBatchDetailId);
					END
					
					-----Discount Taken End--------

					SET @TotalDebit=0;
					SET @TotalCredit=0;

					SELECT @TotalDebit = SUM([DebitAmount]),
					       @TotalCredit = SUM([CreditAmount]) 
				      FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
				      WHERE [JournalBatchDetailId] = @JournalBatchDetailId 
				    GROUP BY [JournalBatchDetailId]

					UPDATE [dbo].[BatchDetails] 
				       SET [DebitAmount] = @TotalDebit,
					       [CreditAmount] = @TotalCredit,
					       [UpdatedDate] = GETUTCDATE(),
					       [UpdatedBy] = @UpdateBy   
				     WHERE [JournalBatchDetailId] = @JournalBatchDetailId;

					SET @currentNo = @currentNo + 1;  
					
					SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT [CodePrefix] FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId), (SELECT [CodeSufix] FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId)))
									   
				END
		
				SELECT @TotalDebit = SUM([DebitAmount]),
				       @TotalCredit = SUM([CreditAmount]) 
			      FROM [dbo].[BatchDetails] WITH(NOLOCK) 
			     WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId 
			       AND [IsDeleted] = 0; 

				SET @TotalBalance = (@TotalDebit - @TotalCredit)

				UPDATE [dbo].[CodePrefixes] 
			       SET [CurrentNummber] = @currentNo 
			     WHERE [CodeTypeId] = @CodeTypeId 
			       AND [MasterCompanyId] = @MasterCompanyId    

				UPDATE [dbo].[BatchHeader] 
			       SET [TotalDebit] = @TotalDebit,
				       [TotalCredit] = @TotalCredit,
				       [TotalBalance] = @TotalBalance,
				       [UpdatedDate] = GETUTCDATE(),
				       [UpdatedBy] = @UpdateBy 
			     WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;
				 			 
			SET @MasterLoopID = @MasterLoopID - 1;
		END

		WHILE(@MasterLoopIDs > 0)
		BEGIN
			SELECT @PaymentMethodId = [PaymentMethodId], 
			       @VendorId = [VendorId],
			       @CheckAmount = [PaymentMade], 
				   @DiscountAmount = [DiscountToken],
				   @TotalAmount = [PaymentMade] + [DiscountToken],
				   @CheckNumber = [CheckNumber],
				   @CheckDate = [CheckDate],
				   @ReceivingReconciliationId = [ReceivingReconciliationId],
				   @IsVendorPayment = [IsVendorPayment],
				   @VendorPaymentDetailsId = VendorPaymentDetailsId
			  FROM #tmpVendorReadyToPayDetail WHERE ID  = @MasterLoopIDs;	
		

			INSERT INTO #tmpCreditMemo ([VendorId],[VendorPaymentDetailsId],[VendorCreditMemoId])
					SELECT [VendorId],[VendorPaymentDetailsId],[VendorCreditMemoId] 
			FROM [dbo].[VendorCreditMemoMapping] WITH(NOLOCK) WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId;
					
			SELECT  @CreditMemoLoopID = MAX(ID) FROM #tmpCreditMemo

			WHILE(@CreditMemoLoopID > 0)
			BEGIN
			PRINT 'Insert'
				SELECT @VendorCreditMemoId = [VendorCreditMemoId]
				FROM #tmpCreditMemo WHERE ID  = @CreditMemoLoopID;
				
				SELECT @StatusIdClosed = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE Name='Closed';

				UPDATE [dbo].[VendorCreditMemo] SET IsVendorPayment = 1,VendorPaymentDetailsId = @VendorPaymentDetailsId,VendorCreditMemoStatusId = @StatusIdClosed
				WHERE VendorCreditMemoId = @VendorCreditMemoId;

				SET @VendorCreditMemoId = 0;
				SET @CreditMemoLoopID = @CreditMemoLoopID - 1;
			END

			SET @MasterLoopIDs = @MasterLoopIDs - 1;
		END

	  END
	 COMMIT  TRANSACTION  		
	END TRY
	BEGIN CATCH
	    ROLLBACK TRANSACTION;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_VendorPaymentBatchDetails' 
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