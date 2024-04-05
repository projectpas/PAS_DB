/*************************************************************           
 ** File:   [USP_BatchTriggerBasedonCustomerReceiptByIdNew]
 ** Author:  Deep Patel
 ** Description: This stored procedure is used USP_BatchTriggerBasedonSOInvoice
 ** Purpose:         
 ** Date:   08/11/2022
          
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/11/2022  Deep Patel     Created
    2    02/06/2023  Satish Gohil	Modify (SET @IsDeposit value as per condition) 
	3	 11/08/2023	 Satish Gohil   Modify (Formetted and dynamic distribution added) 
	4    21/08/2023  Moin Bloch     Modify (Added Accounting MS Entry)
	5    11/09/2023  Moin Bloch     Modify (Customer Wise Entry Will Store)
	6    19/09/2023  Hemnat Saliya  Modify (CR/DR Type)
	7    11/26/2023	 HEMANT SALIYA  Updated Journal Type Id and Name in Batch Details
	8    03/12/2024  Moin Bloch     Modify (Added Suspense Entry)
	9    04/03/2024  Devendra Shekh Modify (changed entry to suspense from AR for customer)
	10    04/04/2024  Devendra Shekh Modify (added both entry suspense and AR for known customer)

	EXEC [dbo].[USP_BatchTriggerBasedonCustomerReceiptByIdNew] 8,218

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_BatchTriggerBasedonCustomerReceiptByIdNew]
@DistributionMasterId BIGINT=NULL,
@ReceiptId BIGINT=NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @JournalTypeId INT
		DECLARE @JournalTypeCode VARCHAR(200) 
		DECLARE @JournalBatchHeaderId BIGINT
		DECLARE @GlAccountId INT
		DECLARE @StatusId INT
		DECLARE @StatusName VARCHAR(200)
		DECLARE @StartsFrom VARCHAR(200)='00'
		DECLARE @CurrentNumber INT
		DECLARE @GlAccountName VARCHAR(200) 
		DECLARE @GlAccountNumber VARCHAR(200) 
		DECLARE @JournalTypename VARCHAR(200) 
		DECLARE @Distributionname VARCHAR(200) 
		DECLARE @CustomerId BIGINT
		DECLARE @ManagementStructureId BIGINT
		DECLARE @CustomerName VARCHAR(200)
		DECLARE @SalesOrderNumber VARCHAR(200) 
		DECLARE @MPNName VARCHAR(200) 
		DECLARE @PiecePNId BIGINT
		DECLARE @PiecePN VARCHAR(200) 
		DECLARE @ItemmasterId BIGINT
		DECLARE @PieceItemmasterId BIGINT
		DECLARE @CustRefNumber VARCHAR(200)
		DECLARE @LineNumber INT=1
		DECLARE @TotalDebit decimal(18,2)=0
		DECLARE @TotalCredit decimal(18,2)=0
		DECLARE @TotalBalance decimal(18,2)=0
		DECLARE @UnitPrice decimal(18,2)=0
		DECLARE @LaborHrs decimal(18,2)=0
		DECLARE @DirectLaborCost decimal(18,2)=0
		DECLARE @OverheadCost decimal(18,2)=0
		DECLARE @partId BIGINT=0
		DECLARE @batch VARCHAR(100)
		DECLARE @AccountingPeriod VARCHAR(100)
		DECLARE @AccountingPeriodId BIGINT=0
		DECLARE @CurrentPeriodId BIGINT=0
		DECLARE @Currentbatch VARCHAR(100)
		DECLARE @LastMSLevel VARCHAR(200)
		DECLARE @AllMSlevels VARCHAR(max)
		DECLARE @DistributionSetupId INT=0
		DECLARE @DistributionCode VARCHAR(200)
		DECLARE @InvoiceTotalCost decimal(18,2)=0
		DECLARE @MaterialCost decimal(18,2)=0
		DECLARE @LaborOverHeadCost decimal(18,2)=0
		DECLARE @FreightCost decimal(18,2)=0
		DECLARE @SalesTax decimal(18,2)=0
		DECLARE @InvoiceNo VARCHAR(100)
		DECLARE @MiscChargesCost decimal(18,2)=0
		DECLARE @LaborCost decimal(18,2)=0
		DECLARE @InvoiceLaborCost decimal(18,2)=0
		DECLARE @RevenuWO decimal(18,2)=0
		DECLARE @CurrentManagementStructureId BIGINT=0
		DECLARE @JournalBatchDetailId BIGINT=0
		DECLARE @DocumentNumber VARCHAR(2000);
		DECLARE @CrDrType BIGINT
		DECLARE @BankId BIGINT = 0;
		DECLARE @BankType VARCHAR(100);
		DECLARE @BankGlAccId BIGINT = 0;

		DECLARE @UpdatedBy VARCHAR(200);
		DECLARE @MasterCompanyId INT=0;
		
		SELECT @MasterCompanyId = MasterCompanyId, 
		       @UpdatedBy = CreatedBy,
			   @BankType = BankType,
			   @BankId = BankName
		 FROM [dbo].[CustomerPayments] WITH(NOLOCK) WHERE ReceiptId = @ReceiptId;

		SELECT @DistributionCode = DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK) WHERE ID = @DistributionMasterId
		SELECT @StatusId = Id,@StatusName = [name] FROM dbo.BatchStatus WITH(NOLOCK) WHERE Name = 'Open'
		SELECT TOP 1 @JournalTypeId = [JournalTypeId] FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId
		SELECT @JournalBatchHeaderId = [JournalBatchHeaderId] FROM dbo.BatchHeader WITH(NOLOCK) WHERE JournalTypeId= @JournalTypeId AND StatusId=@StatusId
		SELECT @JournalTypeCode = [JournalTypeCode], @JournalTypename = [JournalTypeName] FROM dbo.JournalType WITH(NOLOCK)  WHERE ID = @JournalTypeId
	
	    DECLARE @currentNo AS BIGINT = 0;
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @JournalTypeNumber VARCHAR(100);
		DECLARE @CustomerTypeId INT=0;
		DECLARE @CustomerTypeName VARCHAR(50);
		DECLARE @StocklineNumber VARCHAR(50);
		DECLARE @ReceiptNo VARCHAR(50);
		DECLARE @CRMSModuleId INT=59;
		DECLARE @ModuleName VARCHAR(200);
		DECLARE @Amount decimal(18,2)=0;
		DECLARE @CommonJournalBatchDetailId BIGINT=0;
		DECLARE @ValidDistribution BIT = 1;
		DECLARE @AccountMSModuleId INT = 0
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

		DECLARE @IsRestrict BIT;
		DECLARE @IsAccountByPass BIT;

		EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdatedBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

		IF((@JournalTypeCode ='CRS') AND ISNULL(@IsAccountByPass, 0) = 0)
		BEGIN
			SELECT @ReceiptNo = [ReceiptNo], 
			       @CurrentManagementStructureId = [ManagementStructureId] 
			  FROM [dbo].[CustomerPayments] WITH(NOLOCK) WHERE [ReceiptId] = @ReceiptId;

	        SELECT @LastMSLevel = [LastMSLevel], 
			       @AllMSlevels = [AllMSlevels] 
			  FROM [dbo].[CustomerManagementStructureDetails] WITH(NOLOCK) WHERE [ReferenceID] = @ReceiptId AND [ModuleID] = @CRMSModuleId;
			  					  
			SET @ManagementStructureId= @CurrentManagementStructureId;

			SELECT TOP 1  @AccountingPeriodId = acc.[AccountingCalendarId],
			              @AccountingPeriod = [PeriodName] FROM [dbo].[EntityStructureSetup] est WITH(NOLOCK) 
			INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
			INNER JOIN [dbo].[AccountingCalendar] acc WITH(NOLOCK) ON msl.[LegalEntityId] = acc.[LegalEntityId] AND acc.[IsDeleted] = 0
			WHERE est.[EntityStructureId] = @CurrentManagementStructureId 
			  AND acc.[MasterCompanyId] = @MasterCompanyId  
			  AND CAST(GETUTCDATE() AS DATE) >= CAST([FromDate] AS DATE) 
			  AND CAST(GETUTCDATE() AS DATE) <= CAST([ToDate] AS DATE)

			IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCodePrefixes
			END

			CREATE TABLE #tmpCodePrefixes
			(
				[ID] BIGINT NOT NULL IDENTITY, 
				[CodePrefixId] BIGINT NULL,
				[CodeTypeId] BIGINT NULL,
				[CurrentNumber] BIGINT NULL,
				[CodePrefix] VARCHAR(50) NULL,
				[CodeSufix] VARCHAR(50) NULL,
				[StartsFrom] BIGINT NULL,
			)

			IF OBJECT_ID(N'tempdb..#tmpCustomername') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCustomername
			END
				
			CREATE TABLE #tmpCustomername
			(
				[ID] BIGINT NOT NULL IDENTITY, 
				[ReceiptId] BIGINT NULL,
				[CustomerId] BIGINT NULL,
				[CustomerName] VARCHAR(1000) NULL,
			)

			IF OBJECT_ID(N'tempdb..#tmpCustomernameGroup') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCustomernameGroup
			END
				
			CREATE TABLE #tmpCustomernameGroup
			(
				[ID] BIGINT NOT NULL IDENTITY, 
				[ReceiptId] BIGINT NULL,
				[CustomerId] BIGINT NULL
			)

			IF OBJECT_ID(N'tempdb..#tmpPaymentMethodname') IS NOT NULL
			BEGIN
				DROP TABLE #tmpPaymentMethodname
			END
				
			CREATE TABLE #tmpPaymentMethodname
			(
				[ID] BIGINT NOT NULL IDENTITY, 
				[ReceiptId] BIGINT NULL,
				[PaymentMethod] VARCHAR(max) NULL,
			)

			IF OBJECT_ID(N'tempdb..#tmpPaymentMethod') IS NOT NULL
			BEGIN
				DROP TABLE #tmpPaymentMethod
			END
				
			CREATE TABLE #tmpPaymentMethod
			(
				[ID] BIGINT NOT NULL IDENTITY, 
				[ReceiptId] BIGINT NULL,
				[PaymentMethod] VARCHAR(max) NULL,
			)

			IF OBJECT_ID(N'tempdb..#tmpCustomerPaymentDetails') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCustomerPaymentDetails
			END

			CREATE TABLE #tmpCustomerPaymentDetails
			(
				[ID] BIGINT NOT NULL IDENTITY,									
				[CustomerId] BIGINT NULL,					
			)			

			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
			FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId))
			BEGIN 
				SELECT @currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
						ELSE CAST(StartsFrom AS BIGINT) + 1 END 
				FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId

				SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN
				ROLLBACK TRAN;
			END
			
			SELECT @currentNo = CASE WHEN CP.[CurrentNummber] > 0 THEN CAST([CurrentNummber] AS BIGINT) + 1 
					ELSE CAST([StartsFrom] AS BIGINT) + 1 END 						
			FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

			SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,
			(SELECT CodePrefix 
			FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0),																		
			
			(SELECT CodeSufix 
			FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0)))
			
			

			IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM dbo.BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId AND  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
			BEGIN
				IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK))
				BEGIN
					SET @batch ='001'
					SET @Currentbatch='001'
				END
				ELSE
				BEGIN
					SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
				   								ELSE  1 END 
				   			FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
				SET @batch = CAST(@JournalTypeCode +' '+cast(@batch AS VARCHAR(100)) AS VARCHAR(100))
				          
				INSERT INTO [dbo].[BatchHeader]([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module],[CustomerTypeId])
				      VALUES(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,'CRS',0);
            	
				SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
				UPDATE [dbo].[BatchHeader] SET [CurrentNumber] = @CurrentNumber WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId
				END
				ELSE
				BEGIN
					SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and StatusId=@StatusId and CustomerTypeId=@CustomerTypeId
					SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
						FROM dbo.BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  ORDER BY JournalBatchDetailId desc 
				    
					IF(@CurrentPeriodId =0)
					BEGIN
						UPDATE [dbo].[BatchHeader] SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
					END
				END
				INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], 
				       	    [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[AccountingPeriodId],[AccountingPeriod])
					 VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, 0, 0, 0, 'CustomerReceipts', NULL, NULL, @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,@AccountingPeriodId,@AccountingPeriod)
					 
					SET @JournalBatchDetailId = SCOPE_IDENTITY()


			IF(UPPER(@DistributionCode) = UPPER('CashReceiptsTradeReceivable'))
			BEGIN
				DECLARE @PaymentAmount DECIMAL(18,2)=0;
				DECLARE @CaseAmount DECIMAL(18,2)=0;
				DECLARE @AccountsReceivablesAmount DECIMAL(18,2)=0;
				DECLARE @EarlyDiscAmount DECIMAL(18,2)=0;
				DECLARE @NotEarlyDiscAmount DECIMAL(18,2)=0;
				DECLARE @OtherDiscAmount DECIMAL(18,2)=0;
				DECLARE @WireBankFeesAmount DECIMAL(18,2)=0;
				DECLARE @FXFeesAmount DECIMAL(18,2)=0;
				DECLARE @OtherAdjustmentAmount DECIMAL(18,2)=0;
				DECLARE @AapliedAmount DECIMAL(18,2)=0;
				DECLARE @InvoiceAmount DECIMAL(18,2)=0;
				DECLARE @InvoiceAmountDiffeence DECIMAL(18,2)=0;
				DECLARE @RemainingAmount DECIMAL(18,2)=0;
						 
				DECLARE @InvoiceType VARCHAR(50);
				DECLARE @SOBillingInvoicingId BIGINT=0;
				DECLARE @IsDeposit BIT=0;
				DECLARE @AccountReceivablesAmount DECIMAL(18,2)=0;
				DECLARE @DepositeAmount DECIMAL(18,2)=0;
				DECLARE @miscellaneousAmount DECIMAL(18,2)=0;
				DECLARE @Ismiscellaneous BIT=0;

				DECLARE @TotalRecord INT = 0;   
				DECLARE @MinId BIGINT = 1;    

				INSERT INTO #tmpCustomerPaymentDetails ([CustomerId])
				SELECT [CustomerId] FROM [dbo].[CustomerPaymentDetails] cc WITH(NOLOCK) 
				WHERE ReceiptId = @ReceiptId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,1) = 1
				GROUP BY [CustomerId] 

				SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmpCustomerPaymentDetails    

				WHILE @MinId <= @TotalRecord
				BEGIN	
					SELECT @CustomerId = [CustomerId] FROM #tmpCustomerPaymentDetails WHERE ID = @MinId
																							
				    SELECT TOP 1 @UpdatedBy = [UpdatedBy] 
					    FROM [dbo].[CustomerPaymentDetails] WITH(NOLOCK)
				       WHERE [ReceiptId] = @ReceiptId 
					     AND [CustomerId] = @CustomerId 
						 AND ISNULL([IsDeleted],0) = 0 AND ISNULL([IsActive],1) = 1;
					   						 
					SELECT @CustomerTypeId = c.[CustomerAffiliationId],
						   @CustomerTypeName = caf.[Description] FROM [dbo].[Customer] c WITH(NOLOCK)
					 INNER JOIN [dbo].[CustomerAffiliation] caf WITH(NOLOCK) ON c.[CustomerAffiliationId] = caf.[CustomerAffiliationId]
					 WHERE c.[CustomerId] = @CustomerId;

					----------------------------------------------------------------------------------------------------------------------
					
					INSERT INTO #tmpPaymentMethodname ([ReceiptId],[PaymentMethod]) 
					SELECT [ReceiptId],
					(CASE WHEN cc.IsMultiplePaymentMethod = 1 THEN 
					(CASE WHEN cc.IsCheckPayment = 1 AND IsWireTransfer = 1 THEN 'Check and Wire Transfer'
						  WHEN cc.IsCheckPayment = 1 THEN 'Check' WHEN cc.IsWireTransfer = 1 THEN 'Wire Transfer'  ELSE '' END) 
						  WHEN cc.IsCheckPayment = 1 THEN 'Check' WHEN cc.IsWireTransfer = 1 THEN 'Wire Transfer' 
						  WHEN cc.IsCCDCPayment = 1 THEN ' Credit Card/Debit Card '   ELSE '' END) AS PaymentMethod
					FROM [dbo].[CustomerPaymentDetails] cc WITH(NOLOCK) WHERE [ReceiptId] = @ReceiptId AND [CustomerId] = @CustomerId 
					GROUP BY [ReceiptId],[IsMultiplePaymentMethod],[IsCCDCPayment],[IsCheckPayment],[IsWireTransfer] ORDER BY 1 DESC	
					
					----------------------------------------------------------------------------------------------------------------------
													   										
					INSERT INTO #tmpPaymentMethod ([ReceiptId],[PaymentMethod]) 
					SELECT TOP 1 [ReceiptId]
					,STUFF((SELECT ', ' + CAST(cc.[PaymentMethod] AS VARCHAR(2000)) [text()]
						FROM #tmpPaymentMethodname cc
						WHERE cc.ReceiptId = t.ReceiptId
						FOR XML PATH(''), TYPE)
					.value('.','NVARCHAR(MAX)'),1,2,' ') PaymentMethod
					FROM dbo.CustomerPaymentDetails t WITH(NOLOCK) 
					WHERE ReceiptId = @ReceiptId AND [CustomerId] = @CustomerId AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsActive,1)=1
					GROUP BY [ReceiptId]

					----------------------------------------------------------------------------------------------------------------------
										
					SELECT @CustomerName = [Name] FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId

					SELECT TOP 1 @DocumentNumber = [PaymentMethod] FROM #tmpPaymentMethod WHERE [ReceiptId] = @ReceiptId 
					
					SELECT @CaseAmount = SUM(ISNULL(Amount,0)) ,
				           @AapliedAmount = SUM(ISNULL(AppliedAmount,0)),
					       @InvoiceAmount = SUM(ISNULL(InvoiceAmount,0)) ,
					       @RemainingAmount = SUM(ISNULL(AmountRem,0))
				      FROM [dbo].[CustomerPaymentDetails] WITH(NOLOCK) 
					 WHERE [ReceiptId] = @ReceiptId AND [CustomerId] = @CustomerId 
					   AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,1) = 1;			  
					  
					SELECT @DepositeAmount = SUM(ISNULL([Amount],0)) 
					FROM [dbo].[CustomerPaymentDetails] WITH(NOLOCK)
					WHERE [ReceiptId] = @ReceiptId 
					  AND [CustomerId] = @CustomerId  
					  AND ISNULL(IsDeposite,0) = 1 
					  AND ISNULL(IsDeleted,0)=0 AND ISNULL(IsActive,1)=1;

					IF(ISNULL(@DepositeAmount,0) <> 0)
					BEGIN 
						SET @IsDeposit = 1
					END
					ELSE
					BEGIN
						SET @IsDeposit = 0
					END

					--SELECT @miscellaneousAmount = SUM(ISNULL([AppliedAmount],0)),
					SELECT @miscellaneousAmount = ISNULL(SUM([Amount]),0),  					
				           @Ismiscellaneous = ISNULL([Ismiscellaneous],0) 
				      FROM [dbo].[CustomerPaymentDetails] WITH(NOLOCK)					 
				     WHERE [ReceiptId] = @ReceiptId 
				       AND [CustomerId] = @CustomerId  
				       AND ISNULL([Ismiscellaneous],0)=1 
				       AND ISNULL(IsDeleted,0)=0 
					   AND ISNULL([IsActive],1)=1
					   GROUP BY [Ismiscellaneous];

					SELECT @InvoiceAmountDiffeence = ISNULL(SUM(ISNULL([AppliedAmount],0)) - SUM(ISNULL([InvoiceAmount],0)),0)
				      FROM [dbo].[CustomerPaymentDetails] WITH(NOLOCK)
				     WHERE [ReceiptId] = @ReceiptId  
				       AND [CustomerId] = @CustomerId  
				       AND ISNULL(Ismiscellaneous,0) = 0 AND ISNULL([IsDeleted],0) = 0 AND ISNULL([IsActive],1) = 1;

					SELECT @EarlyDiscAmount = ISNULL(SUM(IVP.[DiscAmount]),0) 
					FROM [dbo].[InvoicePayments] IVP WITH(NOLOCK)
					INNER JOIN [dbo].[MasterDiscountType] MDT WITH(NOLOCK) ON IVP.[DiscType] = MDT.[Id]
					WHERE [ReceiptId] = @ReceiptId 
					  AND [CustomerId] = @CustomerId  
					  AND UPPER(MDT.[Name]) = UPPER('Early Pay (Earned)') AND IVP.[IsDeleted] = 0;
					  					  
					SELECT @NotEarlyDiscAmount = ISNULL(SUM(IVP.DiscAmount),0) 
					FROM [dbo].[InvoicePayments] IVP WITH(NOLOCK)
					INNER JOIN [dbo].[MasterDiscountType] MDT WITH(NOLOCK) ON IVP.DiscType = MDT.Id
					WHERE [ReceiptId] = @ReceiptId 
					  AND [CustomerId] = @CustomerId  
					  AND UPPER(MDT.[Name]) = UPPER('Early Pay (Not Earned)') AND IVP.IsDeleted = 0;

					SELECT @OtherDiscAmount = ISNULL(SUM(IVP.DiscAmount),0) 
					FROM [dbo].[InvoicePayments] IVP WITH(NOLOCK)
					INNER JOIN [dbo].[MasterDiscountType] MDT WITH(NOLOCK) ON IVP.DiscType = MDT.Id
					WHERE [ReceiptId] = @ReceiptId 
					  AND [CustomerId] = @CustomerId  
					  AND UPPER(MDT.[Name]) = UPPER('Other Discounts') AND IVP.IsDeleted = 0;
					  
					SELECT @WireBankFeesAmount=ISNULL(SUM(IVP.BankFeeAmount),0) 
					  FROM [dbo].[InvoicePayments] IVP WITH(NOLOCK)
					INNER JOIN [dbo].[MasterBankFeesType] MFT WITH(NOLOCK) ON IVP.BankFeeType = MFT.Id
					WHERE [ReceiptId] = @ReceiptId 
					  AND [CustomerId] = @CustomerId  
					  AND UPPER(MFT.[Name]) = UPPER('Wire/ACH Fees') AND IVP.IsDeleted = 0;
						 
					SELECT @FXFeesAmount = ISNULL(SUM(IVP.BankFeeAmount),0) 
					FROM [dbo].[InvoicePayments] IVP WITH(NOLOCK)
					INNER JOIN [dbo].[MasterBankFeesType] MFT WITH(NOLOCK) ON IVP.BankFeeType = MFT.Id
					WHERE [ReceiptId] = @ReceiptId 
					  AND [CustomerId] = @CustomerId  
					  AND UPPER(MFT.[Name]) = UPPER('FX Fees') AND IVP.IsDeleted = 0;

					SELECT @OtherAdjustmentAmount=ISNULL(SUM(IVP.OtherAdjustAmt),0) 
					  FROM [dbo].[InvoicePayments] IVP WITH(NOLOCK)
					 WHERE [ReceiptId] = @ReceiptId 
					   AND [CustomerId] = @CustomerId  
					   AND IVP.IsDeleted=0;

					SET @AccountReceivablesAmount = @CaseAmount + @EarlyDiscAmount +@NotEarlyDiscAmount + @OtherDiscAmount + @WireBankFeesAmount + @FXFeesAmount + @OtherAdjustmentAmount - @RemainingAmount

					SET @miscellaneousAmount = CASE WHEN ISNULL(@Ismiscellaneous, 0) = 0 THEN @RemainingAmount ELSE @miscellaneousAmount END;

					IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId AND [IsManualText] = 0 AND ISNULL(GlAccountId,0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END

					SELECT @BankGlAccId = CASE WHEN @BankType = 'Operating Account' THEN LB.GLAccountId
											   WHEN @BankType = 'WirePayment' THEN LB.GLAccountId
											   WHEN @BankType = 'ACH' THEN LB.GLAccountId
											   ELSE 0 END
					FROM [dbo].[CustomerPayments] C WITH(NOLOCK)
					LEFT JOIN [dbo].[LegalEntityBankingLockBox] LB WITH(NOLOCK) ON C.BankName = LB.LegalEntityBankingLockBoxId 
					LEFT JOIN [dbo].[LegalEntityINTernationalWireBanking] V  WITH(NOLOCK) ON C.BankName = V.INTernationalWirePaymentId 
					LEFT JOIN [dbo].[INTernationalWirePayment] VP WITH(NOLOCK) ON VP.INTernationalWirePaymentId = V.INTernationalWirePaymentId  
					LEFT JOIN [dbo].[ACH] A WITH(NOLOCK) ON C.BankName = A.ACHId
					WHERE C.[ReceiptId] = @ReceiptId;				

					IF (ISNULL(@BankGlAccId,0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END
										
					IF(@ValidDistribution = 1)
					BEGIN
						-----Account Receivables------		
						IF(@AccountReceivablesAmount > 0 AND @Ismiscellaneous = 0)
						BEGIN	
							SELECT top 1 @DistributionSetupId=ID,
							             @DistributionName=Name,
										 @JournalTypeId =JournalTypeId,
										 @GlAccountId=GlAccountId,
										 @GlAccountNumber=GlAccountNumber,
										 @GlAccountName=GlAccountName,
										 @CrDrType = CRDRType 
							FROM DBO.DistributionSetup WITH(NOLOCK)  
							WHERE UPPER(DistributionSetupCode) = UPPER('CRSACCRECH') 
							AND DistributionMasterId=@DistributionMasterId 
							AND MasterCompanyId = @MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],
								[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @AccountReceivablesAmount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @AccountReceivablesAmount END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[CustomerReceiptBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo ,@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,@DocumentNumber,NULL,NULL,@CommonJournalBatchDetailId)
						END

						-----Cash Entry------						
						IF(@CaseAmount > 0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType = CRDRType 
							FROM DBO.DistributionSetup WITH(NOLOCK)  where UPPER(DistributionSetupCode) = UPPER('CRSCASH') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

							SELECT @GlAccountId=GlAccountId,@GlAccountNumber=AccountCode,@GlAccountName=AccountName
							FROM DBO.GLAccount WITH(NOLOCK) WHERE GLAccountId = @BankGlAccId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
						 		[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @CaseAmount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @CaseAmount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
						 
							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[CustomerReceiptBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],
								[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo ,
								@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,@DocumentNumber,NULL,NULL,@CommonJournalBatchDetailId)
						END

						-----Cash Entry------

						-----Early Pay (Earned)------
						IF(@EarlyDiscAmount > 0)
						BEGIN
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM dbo.DistributionSetup WITH(NOLOCK)  where UPPER(DistributionSetupCode) = UPPER('CRSEARLYPAYEARNED') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails](JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							      VALUES(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
										 CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
										 CASE WHEN @CrDrType = 1 THEN @EarlyDiscAmount ELSE 0 END,
										 CASE WHEN @CrDrType = 1 THEN 0 ELSE @EarlyDiscAmount END
										 ,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
						 
							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 
						 
							INSERT INTO [dbo].[CustomerReceiptBatchDetails](JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							      VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo,@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,@DocumentNumber,NULL,NULL,@CommonJournalBatchDetailId)
						END
						-----Early Pay (Earned)------

						-----Early Pay (un-Earned)------
						IF(@NotEarlyDiscAmount > 0)
						BEGIN
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DBO.DistributionSetup WITH(NOLOCK)  where UPPER(DistributionSetupCode) = UPPER('CRSEARLYPAYUNEARNED') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
								[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @NotEarlyDiscAmount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @NotEarlyDiscAmount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
						 
							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 
						 
							INSERT INTO [dbo].[CustomerReceiptBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo ,@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,@DocumentNumber,NULL,NULL,@CommonJournalBatchDetailId)
						END
						-----Early Pay (un-Earned)------

						-----Other Discount------
						IF(@OtherDiscAmount > 0)
						BEGIN
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DBO.DistributionSetup WITH(NOLOCK) WHERE UPPER(DistributionSetupCode) = UPPER('CRSOTHERDISCOUNT') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId						
 
							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
								[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @OtherDiscAmount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @OtherDiscAmount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
						 
							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 
						 
							INSERT INTO [dbo].[CustomerReceiptBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo ,@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,@DocumentNumber,NULL,NULL,@CommonJournalBatchDetailId)
						END
						-----Other Discount------

						-----Wire/ACH Fees------
						IF(@WireBankFeesAmount>0)
						BEGIN
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DBO.DistributionSetup WITH(NOLOCK) WHERE UPPER(DistributionSetupCode) = UPPER('CRSWIREACHFEE') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId						
 
							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
								[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @WireBankFeesAmount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @WireBankFeesAmount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[CustomerReceiptBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo ,@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,@DocumentNumber,NULL,NULL,@CommonJournalBatchDetailId)
						END
						-----Wire/ACH Fees------

						-----FX Fees------
						IF(@FXFeesAmount>0)
						BEGIN
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DBO.DistributionSetup WITH(NOLOCK) WHERE UPPER(DistributionSetupCode) = UPPER('CRSFXFEE') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId						
 
							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
								[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @FXFeesAmount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @FXFeesAmount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[CustomerReceiptBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo ,@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,@DocumentNumber,NULL,NULL,@CommonJournalBatchDetailId)
						END
						-----FX Fees------

						-----Other Adjustments------
						IF(@OtherAdjustmentAmount > 0)
						BEGIN
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DBO.DistributionSetup WITH(NOLOCK) WHERE UPPER(DistributionSetupCode) = UPPER('CRSOTHERADJ') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId						

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
								[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,
								GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								1, @OtherAdjustmentAmount, 0,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[CustomerReceiptBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo ,@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,@DocumentNumber,NULL,NULL,@CommonJournalBatchDetailId)		
						END
						-----Other Adjustments------
						IF(@OtherAdjustmentAmount < 0)
						BEGIN
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DBO.DistributionSetup WITH(NOLOCK) WHERE UPPER(DistributionSetupCode) = UPPER('CRSOTHERADJ') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId						

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
								[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,
								GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								0,0,@OtherAdjustmentAmount,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[CustomerReceiptBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo ,@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,@DocumentNumber,NULL,NULL,@CommonJournalBatchDetailId)		
						END
						-----Other Adjustments------

						-----Deposit/Unearned Revenue------
						IF(@IsDeposit = 1 AND @DepositeAmount > 0)
						BEGIN
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DBO.DistributionSetup WITH(NOLOCK) WHERE UPPER(DistributionSetupCode) = UPPER('CRSDEPOSITREVNUE') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId						

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
								[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,
								GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @DepositeAmount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @DepositeAmount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 
						 
							INSERT INTO [dbo].[CustomerReceiptBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo ,@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,@DocumentNumber,NULL,NULL,@CommonJournalBatchDetailId)
						END
						-----Deposit/Unearned Revenue------

						-----Suspense------						
						IF(@miscellaneousAmount >0)
						BEGIN					
							SELECT TOP 1 @DistributionSetupId=ID,
							             @DistributionName=Name,
										 @JournalTypeId =JournalTypeId,
										 @GlAccountId=GlAccountId,
										 @GlAccountNumber=GlAccountNumber,
										 @GlAccountName=GlAccountName,
										 @CrDrType = CRDRType 
							FROM DBO.DistributionSetup WITH(NOLOCK) 
							WHERE UPPER(DistributionSetupCode) = UPPER('CRSSUSPENSE') 
							AND DistributionMasterId=@DistributionMasterId 
							AND MasterCompanyId = @MasterCompanyId						

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
								[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,
								GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @miscellaneousAmount ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @miscellaneousAmount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 
						 
							INSERT INTO [dbo].[CustomerReceiptBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo ,@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,'Unapplied Payment',NULL,NULL,@CommonJournalBatchDetailId)
						END
						-----Suspense------

						-----Revenue - Misc Charge------
						IF(@InvoiceAmountDiffeence > 0)
						BEGIN
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DBO.DistributionSetup WITH(NOLOCK) WHERE UPPER(DistributionSetupCode) = UPPER('CRSMISCCHRS') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId						

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
								[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,
								GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @InvoiceAmountDiffeence ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @InvoiceAmountDiffeence END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 
					     
							INSERT INTO [dbo].[CustomerReceiptBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ModuleId],[ReferenceId] ,[ReferenceNumber],[ReferenceInvId],[ReferenceInvNumber],[DocumentId],[DocumentNumber],ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,0,@ReceiptId,@ReceiptNo ,@SOBillingInvoicingId,@InvoiceNo,@SOBillingInvoicingId,@DocumentNumber,NULL,NULL,@CommonJournalBatchDetailId)
						END
						-----Revenue - Misc Charge------

						SET @TotalDebit = 0;
						SET @TotalCredit = 0;

						SELECT @TotalDebit = SUM(DebitAmount),
						       @TotalCredit=SUM(CreditAmount) 
						  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
						 WHERE [JournalBatchDetailId] = @JournalBatchDetailId 
						 GROUP BY [JournalBatchDetailId]
					
						UPDATE [dbo].[BatchDetails] 
						   SET [DebitAmount] = @TotalDebit,
						       [CreditAmount] = @TotalCredit,
							   [UpdatedDate] = GETUTCDATE(),
							   [UpdatedBy] = @UpdatedBy   
						 WHERE [JournalBatchDetailId] = @JournalBatchDetailId

						SELECT @TotalDebit = SUM(DebitAmount),
						       @TotalCredit = SUM(CreditAmount) 
						  FROM [dbo].[BatchDetails] WITH(NOLOCK) 
						 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId 
						   AND [IsDeleted] = 0 
						 GROUP BY [JournalBatchHeaderId]
			   	          
						SET @TotalBalance = @TotalDebit - @TotalCredit
						
						UPDATE [dbo].[CodePrefixes]
						   SET [CurrentNummber] = @currentNo 
						 WHERE [CodeTypeId] = @CodeTypeId 
						   AND [MasterCompanyId] = @MasterCompanyId    
						
						UPDATE [dbo].[BatchHeader] 
						   SET [TotalDebit] = @TotalDebit,
						       [TotalCredit] = @TotalCredit,
							   [TotalBalance] = @TotalBalance,
							   [UpdatedDate] = GETUTCDATE(),
							   [UpdatedBy] = @UpdatedBy
					     WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;

					END

					SET @MinId = @MinId + 1

					TRUNCATE TABLE #tmpPaymentMethodname;					
					TRUNCATE TABLE #tmpPaymentMethod;
					TRUNCATE TABLE #tmpCustomername;
					TRUNCATE TABLE #tmpCodePrefixes;
				
				END

			END
			
			IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCodePrefixes 
			END
			IF OBJECT_ID(N'tempdb..#tmpCustomername') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCustomername 
			END
			IF OBJECT_ID(N'tempdb..#tmpPaymentMethodname') IS NOT NULL
			BEGIN
				DROP TABLE #tmpPaymentMethodname 
			END
			IF OBJECT_ID(N'tempdb..#tmpCustomername') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCustomername
			END
			IF OBJECT_ID(N'tempdb..#tmpCustomernameGroup') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCustomernameGroup
			END
			IF OBJECT_ID(N'tempdb..#tmpCustomerPaymentDetails') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCustomerPaymentDetails
			END

		END

	END
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_BatchTriggerBasedonCustomerReceipt' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@DistributionMasterId, '') + ''
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