﻿/*************************************************************           
 ** File:   [USP_VendorRMA_PostCheckBatchDetails]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used insert account report in batch from Vendor RMA.
 ** Purpose:         
 ** Date:   07/21/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    07/21/2023   Amit Ghediya			Created	
	2    08/07/2023   Amit Ghediya			Update CodeTypes from JournalType; 
	3    08/09/2023   Amit Ghediya			Delete DistributionSetup where name condition; 
	4    21/08/2023   Moin Bloch			Modify(Added Accounting MS Entry)
	5    22/08/2023   Amit Ghediya			Added StockLineId in VendorRMAPaymentBatchDetails table.
    6    27/11/2023   Moin Bloch			Modify(Added @VendorCreditMemoId insted of  @VendorRMAId in VendorRMAPaymentBatchDetails) 
	7    02/26/2024   Bhargav Saliya		Resoved Shipping Issue
	8    02/27/2024	  HEMANT SALIYA			Updated for Restrict Accounting Entry by Master Company
	9    08/01/2024	  Devendra Shekh		Modified for ModuleId for VendorRMAPaymentBatchDetails
	10   08/28/2024   Devendra Shekh		JE Number reset to Zero Issue resolved
	11   20/09/2024	  AMIT GHEDIYA			Added for AutoPost Batch
	12	 09/10/2024	  Devendra Shekh		Added new fields for [CommonBatchDetails]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorRMA_PostCheckBatchDetails]
(
	@VendorRMADetailId BIGINT,
	@VendorRMAId BIGINT,
	@VendorId BIGINT,
	@Module VARCHAR(100)
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
		DECLARE @VendorCreditMemoId BIGINT;
		DECLARE @IsAutoPost INT = 0;
		DECLARE @IsBatchGenerated INT = 0;
		DECLARE @LocalCurrencyCode VARCHAR(20) = '';
		DECLARE @ForeignCurrencyCode VARCHAR(20) = '';
		DECLARE @RMANumber VARCHAR(100) = '';
		DECLARE @FXRate DECIMAL(9,2) = 1;	--Default Value set to : 1

		--SET @DistributionCodeName = 'VendorRMA';

		DECLARE @AccountMSModuleId INT = 0
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

		SELECT @CodeTypeId = CodeTypeId FROM [DBO].[CodeTypes] WITH(NOLOCK) WHERE CodeType = 'JournalType';

		--SELECT @DistributionMasterId =ID,@DistributionCode = DistributionCode FROM [DBO].DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('VendorRMA')
		SELECT @ModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='VendorRMA';

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

		IF(@Module = 'VRMACA')
		BEGIN 
			SET @DistributionCodeName = 'VRMACA';
			SELECT @DistributionMasterId =ID,@DistributionCode = DistributionCode FROM [DBO].DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('VRMACA');
			SET @tmpVendorRMADetailId = @VendorRMADetailId;
			SELECT @VendorRMADetailId = VendorRMADetailId, 
			       @VendorRMAId = VendorRMAId,
				   @ExtAmount = ISNULL(ApplierdAmt,0), 
				   @VendorCreditMemoId = VendorCreditMemoId
			FROM [DBO].[VendorCreditMemoDetail] WITH(NOLOCK) WHERE VendorCreditMemoId = @VendorRMADetailId;

			SELECT @VendorId = VendorId FROM [DBO].[VendorRMA] WITH(NOLOCK) WHERE VendorRMAId = @VendorRMAId;
			SELECT @ModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='VendorCreditMemo';
		END
		ELSE
		BEGIN
			SELECT @ExtAmount = ISNULL(ExtendedCost,0),@VendorCreditMemoId = VendorRMAId FROM [DBO].[VendorRMADetail] WITH(NOLOCK) WHERE  VendorRMADetailId = @VendorRMADetailId;
		END

		SELECT @MasterCompanyId = MasterCompanyId, @UpdateBy = CreatedBy, @RMANumber = RMANumber FROM [DBO].[VendorRMA] WITH(NOLOCK) WHERE VendorRMAId = @VendorRMAId;

		IF(ISNULL(@MasterCompanyId, 0) = 0)
		BEGIN 
			SELECT @MasterCompanyId = MasterCompanyId,
			       @UpdateBy = CreatedBy 
			 FROM [DBO].[VendorCreditMemoDetail] WITH(NOLOCK) WHERE VendorCreditMemoId = @tmpVendorRMADetailId;
		END

		DECLARE @IsRestrict BIT;
		DECLARE @IsAccountByPass BIT;

		EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdateBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

		IF(ISNULL(@ExtAmount,0) > 0 AND ISNULL(@IsAccountByPass, 0) = 0)
		BEGIN 
			IF(@Module = 'VRMACS')  -- RMA Shipping
			BEGIN
				SET @DistributionCodeName = 'VRMACS';
				SELECT @DistributionMasterId =ID,@DistributionCode = DistributionCode FROM [DBO].DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('VRMACS');
				SELECT TOP 1 @JournalTypeId =JournalTypeId,@IsAutoPost = ISNULL(IsAutoPost,0) FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
				WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND DistributionSetupCode='VRMASC-AP';
			END
			ELSE IF(@Module = 'VRMAPR')  -- RMA Receiving
			BEGIN 
				SET @DistributionCodeName = 'VRMAPR';
				SELECT @DistributionMasterId =ID,@DistributionCode = DistributionCode FROM [DBO].DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('VRMAPR');
				SELECT TOP 1 @JournalTypeId =JournalTypeId,@IsAutoPost = ISNULL(IsAutoPost,0) FROM [DBO].[DistributionSetup] WITH(NOLOCK) 
				WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND DistributionSetupCode='VRMAPR-IP';
			END
			ELSE IF(@Module = 'VRMACA') -- RMA Approved Credit Memo
			BEGIN
			    SET @DistributionCodeName = 'VRMACA';
				SELECT @DistributionMasterId =ID,@DistributionCode = DistributionCode FROM [DBO].DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('VRMACA');
				SELECT TOP 1 @JournalTypeId =JournalTypeId,@IsAutoPost = ISNULL(IsAutoPost,0) FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
				WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND DistributionSetupCode='VRMACA-ART';
			END
		
			SELECT @StatusId =Id,@StatusName=name FROM [DBO].[BatchStatus] WITH(NOLOCK)  WHERE Name= 'Open'
			SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
			SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM [DBO].[JournalType] WITH(NOLOCK)  WHERE ID= @JournalTypeId
			SELECT @CurrentManagementStructureId =ManagementStructureId FROM [DBO].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (REPLACE(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
			
			SELECT @stklineId= StockLineId FROM [DBO].[VendorRMADetail] WITH(NOLOCK) WHERE VendorRMADetailId = @VendorRMADetailId;
			IF(@stklineId = 0 OR @stklineId IS NULL )
			BEGIN 
				SELECT @stklineId= StockLineId,
				       @VendorCreditMemoId = VendorCreditMemoId
				FROM [DBO].[VendorCreditMemoDetail] WITH(NOLOCK) WHERE VendorCreditMemoId = @tmpVendorRMADetailId;
			END
			
			SELECT @ManagementStructureId = ManagementStructureId FROM [DBO].[Stockline] WITH(NOLOCK) WHERE StockLineId = @stklineId;
			SELECT @LastMSLevel = LastMSLevel,@AllMSlevels = AllMSlevels FROM [DBO].[StocklineManagementStructureDetails] WITH(NOLOCK) WHERE ReferenceID = @stklineId;

			SELECT	@VendorName = VendorName, @LocalCurrencyCode = ISNULL(CU.Code, ''), @ForeignCurrencyCode = ISNULL(CU.Code, '') FROM [DBO].[Vendor] V WITH(NOLOCK) LEFT JOIN [dbo].[Currency] CU WITH(NOLOCK) ON V.CurrencyId = CU.CurrencyId WHERE VendorId = @VendorId;

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

				SET @IsBatchGenerated = 1;
			END
			
			INSERT INTO [DBO].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
			[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
			[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [AccountingPeriodId], [AccountingPeriod])
			VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
			@JournalTypeId, @JournalTypename, 1, 0, 0, @ManagementStructureId, @DistributionCodeName, 
			NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @AccountingPeriodId, @AccountingPeriod)
		
			SET @JournalBatchDetailId=SCOPE_IDENTITY()

			IF(@Module = 'VRMACS')   -- RMA Shipping
			BEGIN
				 -----Account Payable--------

				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
				 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'VRMASC-AP' AND MasterCompanyId= @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @ExtAmount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @ExtAmount END,
					@ManagementStructureId ,'VendorRMAPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@RMANumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					INSERT INTO [dbo].[VendorRMAPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId,StockLineId,ModuleId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@VendorCreditMemoId,@ExtNumber,@VendorId,@ExtDate,@CommonBatchDetailId,@stklineId,@ModuleId)
					-- @VendorRMAId
				 -----Account Payable--------

				 -----Purchase Return/Inventory--------

				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
				 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'VRMASC-PI' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @ExtAmount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @ExtAmount END,
					@ManagementStructureId ,'VendorRMAPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@RMANumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [dbo].[VendorRMAPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId,StockLineId,ModuleId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@VendorCreditMemoId,@ExtNumber,@VendorId,@ExtDate,@CommonBatchDetailId,@stklineId,@ModuleId)
					-- @VendorRMAId
				 -----Purchase Return/Inventory--------
			END
			ELSE IF(@Module = 'VRMACA')  -- RMA Approved Credit Memo
			BEGIN
				-----Account Payable--------

				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
				 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'VRMACA-AP' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @ExtAmount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @ExtAmount END,
					@ManagementStructureId ,'VendorRMAPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@RMANumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					INSERT INTO [dbo].[VendorRMAPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId,StockLineId,ModuleId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@VendorCreditMemoId,@ExtNumber,@VendorId,@ExtDate,@CommonBatchDetailId,@stklineId,@ModuleId)
					-- @VendorRMAId
				 -----Account Payable--------
				 -----Account Receivabes Other--------

				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
				 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'VRMACA-ART' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @ExtAmount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @ExtAmount END,
					@ManagementStructureId ,'VendorRMAPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@RMANumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [dbo].VendorRMAPaymentBatchDetails(JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId,StockLineId,ModuleId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@VendorCreditMemoId,@ExtNumber,@VendorId,@ExtDate,@CommonBatchDetailId,@stklineId,@ModuleId)
					-- @VendorRMAId
				 -----Account Payable--------
			END
			ELSE IF(@Module = 'VRMAPR')  -- RMA Receiving
			BEGIN

				-----Inventory - Parts--------

				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
				 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'VRMAPR-IP' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @ExtAmount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @ExtAmount END,
					@ManagementStructureId ,'VendorRMAPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@RMANumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [dbo].VendorRMAPaymentBatchDetails(JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId,StockLineId,ModuleId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@VendorCreditMemoId,@ExtNumber,@VendorId,@ExtDate,@CommonBatchDetailId,@stklineId,@ModuleId)
					-- @VendorRMAId
				 -----Inventory - Parts--------

				 -----Account Payable--------

				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName ,@CrDrType = CRDRType
				 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'VRMAPR-AP' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN @ExtAmount ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE @ExtAmount END,
					@ManagementStructureId ,'VendorRMAPayment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@RMANumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
					INSERT INTO [dbo].VendorRMAPaymentBatchDetails(JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,VendorId,CheckDate,CommonJournalBatchDetailId,StockLineId,ModuleId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@VendorCreditMemoId,@ExtNumber,@VendorId,@ExtDate,@CommonBatchDetailId,@stklineId,@ModuleId)
					-- @VendorRMAId
				 -----Account Payable--------
			END

			SET @TotalDebit=0;
			SET @TotalCredit=0;
			SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
			UPDATE [dbo].[BatchDetails] SET DebitAmount = @TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy  WHERE JournalBatchDetailId=@JournalBatchDetailId
			UPDATE [DBO].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    

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
		
		SELECT @TotalDebit =SUM(DebitAmount), @TotalCredit=SUM(CreditAmount) FROM [DBO].[BatchDetails] 
		WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId AND IsDeleted = 0 

		SET @TotalBalance = ISNULL(@TotalDebit,0) - ISNULL(@TotalCredit,0)

	    UPDATE [DBO].[BatchHeader] SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId

	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_VendorRMA_PostCheckBatchDetails' 
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