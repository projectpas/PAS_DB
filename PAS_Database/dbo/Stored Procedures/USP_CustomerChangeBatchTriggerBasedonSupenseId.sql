/*************************************************************           
 ** File:   [USP_CustomerChangeBatchTriggerBasedonSupenseId]
 ** Author:  Deep Patel
 ** Description: This stored procedure is used TO Add Batch Entry WHile Customer Change for Suspense Cash Amount
 ** Purpose:         
 ** Date:  06/25/2024 [mm/dd/yyyy]
          
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    06/25/2024		Devendra Shekh			Created

exec dbo.USP_CustomerChangeBatchTriggerBasedonSupenseId @CustomerCreditPaymentDetailId=76,@NewCustomerId=85,@OldCustomerId=69
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CustomerChangeBatchTriggerBasedonSupenseId]
@CustomerCreditPaymentDetailId BIGINT = NULL,
@NewCustomerId BIGINT = NULL,
@OldCustomerId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @JournalTypeId INT;
		DECLARE @JournalTypeCode VARCHAR(200);
		DECLARE @JournalBatchHeaderId BIGINT;
		DECLARE @GlAccountId INT;
		DECLARE @StatusId INT;
		DECLARE @StatusName VARCHAR(200);
		DECLARE @CurrentNumber INT;
		DECLARE @GlAccountName VARCHAR(200);
		DECLARE @GlAccountNumber VARCHAR(200); 
		DECLARE @JournalTypename VARCHAR(200); 
		DECLARE @Distributionname VARCHAR(200); 
		DECLARE @CustomerId BIGINT;
		DECLARE @ManagementStructureId BIGINT;
		DECLARE @CustomerName VARCHAR(200);
		DECLARE @LineNumber INT = 1;
		DECLARE @TotalDebit decimal(18,2) = 0;
		DECLARE @TotalCredit decimal(18,2) = 0;
		DECLARE @TotalBalance decimal(18,2) = 0;
		DECLARE @batch VARCHAR(100);
		DECLARE @AccountingPeriod VARCHAR(100);
		DECLARE @AccountingPeriodId BIGINT = 0;
		DECLARE @CurrentPeriodId BIGINT = 0;
		DECLARE @Currentbatch VARCHAR(100);
		DECLARE @LastMSLevel VARCHAR(200);
		DECLARE @AllMSlevels VARCHAR(max);
		DECLARE @DistributionSetupId INT = 0;
		DECLARE @DistributionCode VARCHAR(200);
		DECLARE @CurrentManagementStructureId BIGINT=0;
		DECLARE @JournalBatchDetailId BIGINT = 0;
		DECLARE @CrDrType BIGINT
		DECLARE @DistributionMasterId BIGINT = 0;

		DECLARE @UpdatedBy VARCHAR(200);
		DECLARE @MasterCompanyId INT=0;
		DECLARE @IsMiscellaneous BIT=0;
		DECLARE @IsNewCustomerMiscellaneous BIT=0;
		DECLARE @OldCustomerName VARCHAR(100) = '';
		DECLARE @NewCustomerName VARCHAR(100) = '';
		DECLARE @MemoText VARCHAR(250) = '';
		
		SELECT @MasterCompanyId = MasterCompanyId, 
		       @UpdatedBy = CreatedBy
		FROM [dbo].[CustomerCreditPaymentDetail] WITH(NOLOCK) WHERE CustomerCreditPaymentDetailId = @CustomerCreditPaymentDetailId;

		SELECT @NewCustomerName = [Name], @IsNewCustomerMiscellaneous  = ISNULL(IsMiscellaneous, 0) FROM [DBO].[Customer] WITH(NOLOCK) WHERE CustomerId = @NewCustomerId;
		SELECT @OldCustomerName = [Name], @IsMiscellaneous = ISNULL(IsMiscellaneous, 0) FROM [DBO].[Customer] WITH(NOLOCK) WHERE CustomerId = @OldCustomerId;
		SET @MemoText = 'Customer Changed From:- ' + @OldCustomerName + ', To:- ' + @NewCustomerName;

		SELECT @DistributionCode = DistributionCode, @DistributionMasterId = ID FROM dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode) = 'CMDISACC';
		SELECT @StatusId = Id,@StatusName = [name] FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Open';
		SELECT TOP 1 @JournalTypeId = [JournalTypeId] FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId;
		SELECT @JournalBatchHeaderId = [JournalBatchHeaderId] FROM dbo.BatchHeader WITH(NOLOCK) WHERE JournalTypeId = @JournalTypeId AND StatusId = @StatusId;
		SELECT @JournalTypeCode = [JournalTypeCode], @JournalTypename = [JournalTypeName] FROM dbo.JournalType WITH(NOLOCK)  WHERE ID = @JournalTypeId;
	
	    DECLARE @currentNo AS BIGINT = 0;
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @JournalTypeNumber VARCHAR(100);
		DECLARE @CustomerTypeId INT = 0;
		DECLARE @CustomerTypeName VARCHAR(50);
		DECLARE @ReferenceNum VARCHAR(50);
		DECLARE @CRMSModuleId INT = 78;
		DECLARE @ModuleName VARCHAR(200);
		DECLARE @Amount decimal(18,2) = 0;
		DECLARE @CommonJournalBatchDetailId BIGINT = 0;
		DECLARE @AccountMSModuleId INT = 0
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

		DECLARE @IsRestrict BIT;
		DECLARE @IsAccountByPass BIT;

		EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdatedBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

		IF((@JournalTypeCode ='CMDA') AND ISNULL(@IsAccountByPass, 0) = 0 AND (@OldCustomerId != @NewCustomerId))
		BEGIN
			SELECT @ReferenceNum = [SuspenseUnappliedNumber],
			       @CurrentManagementStructureId = [ManagementStructureId] 
			  FROM [dbo].[CustomerCreditPaymentDetail] WITH(NOLOCK) WHERE [CustomerCreditPaymentDetailId] = @CustomerCreditPaymentDetailId;

	        SELECT @LastMSLevel = [LastMSLevel], 
			       @AllMSlevels = [AllMSlevels] 
			  FROM [dbo].[SuspenseAndUnAppliedPaymentMSDetails] WITH(NOLOCK) WHERE [ReferenceID] = @CustomerCreditPaymentDetailId AND [ModuleID] = @CRMSModuleId;
			  					  
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
				      VALUES(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,'CMDA',0);
            	
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


			IF(UPPER(@DistributionCode) = UPPER('CMDISACC'))
			BEGIN
				DECLARE @PaymentAmount DECIMAL(18,2)=0;
				DECLARE @TotalRecord INT = 0;   
				DECLARE @MinId BIGINT = 1;    

				DECLARE @VendorId BIGINT;
				DECLARE @VendorName VARCHAR(50);

				SELECT @CustomerId = [CustomerId], @VendorId = [VendorId] FROM [dbo].[CustomerCreditPaymentDetail] WITH(NOLOCK) 
				WHERE CustomerCreditPaymentDetailId = @CustomerCreditPaymentDetailId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,1) = 1;

				SELECT @VendorName = [VendorName] FROM [dbo].[Vendor] WITH(NOLOCK) WHERE [VendorId] = @VendorId;
				SELECT @CustomerName = [Name] FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId		  
																						
				SELECT @UpdatedBy = [UpdatedBy] , @PaymentAmount = (ISNULL(RemainingAmount,0)) 
						FROM [dbo].[CustomerCreditPaymentDetail] WITH(NOLOCK)
						WHERE [CustomerCreditPaymentDetailId] = @CustomerCreditPaymentDetailId 
						AND [CustomerId] = @CustomerId 
						AND ISNULL([IsDeleted],0) = 0 AND ISNULL([IsActive],1) = 1;
				
				IF(ISNULL(@PaymentAmount ,0) > 0)
				BEGIN

					IF(@IsMiscellaneous = 1)
					BEGIN
						-----Suspense------						
						SELECT TOP 1 @DistributionSetupId=ID,
							             @DistributionName=Name,
										 @JournalTypeId =JournalTypeId,
										 @GlAccountId=GlAccountId,
										 @GlAccountNumber=GlAccountNumber,
										 @GlAccountName=GlAccountName,
										 @CrDrType = CRDRType 
						FROM DBO.DistributionSetup WITH(NOLOCK) 
						WHERE UPPER(DistributionSetupCode) = UPPER('CMSSUSPENSE') 
						AND DistributionMasterId = @DistributionMasterId 
						AND MasterCompanyId = @MasterCompanyId						

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
							[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,
							GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							--CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
							--CASE WHEN @CrDrType = 0 THEN @PaymentAmount ELSE 0 END,
							--CASE WHEN @CrDrType = 0 THEN 0 ELSE @PaymentAmount END
							1, @PaymentAmount, 0
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 
						 
						INSERT INTO [SuspenseAndUnAppliedPaymentBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, CommonJournalBatchDetailId, VendorId, VendorName, ReferenceId, ReferenceNumber, Memo)
						VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @CommonJournalBatchDetailId , @VendorId, @VendorName, @CustomerCreditPaymentDetailId, @ReferenceNum, @MemoText)
						-----Suspense------
					END
					ELSE
					BEGIN
						-----Account Receivables------	DR					
						SELECT top 1 @DistributionSetupId=ID,
							             @DistributionName=Name,
										 @JournalTypeId =JournalTypeId,
										 @GlAccountId=GlAccountId,
										 @GlAccountNumber=GlAccountNumber,
										 @GlAccountName=GlAccountName,
										 @CrDrType = CRDRType 
						FROM DBO.DistributionSetup WITH(NOLOCK)  
						WHERE UPPER(DistributionSetupCode) = UPPER('CMART') 
						AND DistributionMasterId=@DistributionMasterId 
						AND MasterCompanyId = @MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],
							[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							--CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
							--CASE WHEN @CrDrType = 0 THEN @PaymentAmount ELSE 0 END,
							--CASE WHEN @CrDrType = 0 THEN 0 ELSE @PaymentAmount END,
							1, @PaymentAmount, 0,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 

						INSERT INTO [SuspenseAndUnAppliedPaymentBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, CommonJournalBatchDetailId, VendorId, VendorName, ReferenceId, ReferenceNumber, Memo, CustomerId, CustomerName)
						VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @CommonJournalBatchDetailId , @VendorId, @VendorName, @CustomerCreditPaymentDetailId, @ReferenceNum, @MemoText, @OldCustomerId, @OldCustomerName)
						
						-----Account Receivables------	
					END

					-----Account Receivables------	CR				
					SELECT top 1 @DistributionSetupId=ID,
						             @DistributionName=Name,
									 @JournalTypeId =JournalTypeId,
									 @GlAccountId=GlAccountId,
									 @GlAccountNumber=GlAccountNumber,
									 @GlAccountName=GlAccountName,
									 @CrDrType = CRDRType 
					FROM DBO.DistributionSetup WITH(NOLOCK)  
					WHERE UPPER(DistributionSetupCode) = UPPER('CMART') 
					AND DistributionMasterId=@DistributionMasterId 
					AND MasterCompanyId = @MasterCompanyId

					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],
						[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
						--CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
						--CASE WHEN @CrDrType = 1 THEN @PaymentAmount ELSE 0 END,
						--CASE WHEN @CrDrType = 1 THEN 0 ELSE @PaymentAmount END,
						0, 0, @PaymentAmount,
						@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 

					INSERT INTO [SuspenseAndUnAppliedPaymentBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, CommonJournalBatchDetailId, VendorId, VendorName, ReferenceId, ReferenceNumber, Memo, CustomerId, CustomerName)
					VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @CommonJournalBatchDetailId , @VendorId, @VendorName, @CustomerCreditPaymentDetailId, @ReferenceNum, @MemoText, @NewCustomerId, @NewCustomerName)
					
					-----Account Receivables------		

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

				TRUNCATE TABLE #tmpCodePrefixes;
			END
			
			IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCodePrefixes 
			END

			UPDATE CCP
			SET CCP.IsMiscellaneous = @IsNewCustomerMiscellaneous
			FROM [dbo].[CustomerCreditPaymentDetail] CCP WHERE CCP.CustomerCreditPaymentDetailId = @CustomerCreditPaymentDetailId;
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