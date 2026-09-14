/*************************************************************           
 ** File:   [USP_PostManualStockLineBatchDetails]           
 ** Author: Devendra Shekh
 ** Description: This stored procedure is used insert GRNI Repord Adjustment Batch Entry
 ** Purpose:         
 ** Date:  11-09-2026

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				 Author					Change Description            
 ** --   --------			-------				--------------------------------          
    1    11-09-2026		    Moin Bloch			       Created	

     
	EXEC [USP_PostGRNIAdjusmentBatchDetails] 164040
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_PostGRNIAdjusmentBatchDetails]
(
	@RefrenceId BIGINT,
	@SubReferenceId BIGINT,
	@ModuleId INT,
	@GRNIglAccountId BIGINT,
	@COGSglAccountId BIGINT,
	@AdjusmentAmount DECIMAL(18,6) = 0,
	@MasterCompanyId INT,
	@UpdateBy VARCHAR(256)
)
AS
BEGIN 
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @CodeTypeId AS BIGINT = 74;				
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @JournalTypeNumber VARCHAR(100);
		DECLARE @DistributionMasterId BIGINT;    
		DECLARE @DistributionCode VARCHAR(200); 
		DECLARE @CurrentManagementStructureId BIGINT=0; 
		DECLARE @StatusId INT;    
		DECLARE @StatusName VARCHAR(200);    
		DECLARE @AccountingPeriod VARCHAR(100);    
		DECLARE @AccountingPeriodId BIGINT=0;   
		DECLARE @JournalTypeId INT;    
		DECLARE @JournalTypeCode VARCHAR(200);
		DECLARE @JournalBatchHeaderId BIGINT;    
		DECLARE @JournalTypename VARCHAR(200);  
		DECLARE @batch VARCHAR(100);    
		DECLARE @Currentbatch VARCHAR(100);    
		DECLARE @CurrentNumber INT;    
		DECLARE @Amount DECIMAL(18,6); 
		DECLARE @CurrentPeriodId BIGINT=0; 
		DECLARE @LineNumber INT=1;    
		DECLARE @JournalBatchDetailId BIGINT=0;
		DECLARE @CommonBatchDetailId BIGINT=0;
		DECLARE @DistributionSetupId INT=0
		DECLARE @Distributionname VARCHAR(200) 
		DECLARE @GlAccountId INT
		DECLARE @GlAccountName VARCHAR(200) 
		DECLARE @GlAccountNumber VARCHAR(200) 		
		DECLARE @ManagementStructureId BIGINT
		DECLARE @LastMSLevel VARCHAR(200)
		DECLARE @AllMSlevels VARCHAR(MAX)
		DECLARE @TotalDebit DECIMAL(18, 6) =0;
		DECLARE @TotalCredit DECIMAL(18, 6) =0;
		DECLARE @TotalBalance DECIMAL(18, 6) =0;
		DECLARE @VendorName VARCHAR(50);
		DECLARE @CRDRType BIGINT = 0;		
		DECLARE @ItemMasterId BIGINT=NULL;
		DECLARE @OrderNumber VARCHAR(50) ='';		
		DECLARE @MPNName VARCHAR(200);
		DECLARE @Desc VARCHAR(100);
		DECLARE @VendorId BIGINT;
		DECLARE @StockType VARCHAR(50) = 'STOCK';		
		DECLARE @AccountMSModuleId INT = 0
		DECLARE @IsAutoPost INT = 0;
		DECLARE @IsBatchGenerated INT = 0;
		DECLARE @CurrencyCode VARCHAR(20) = '';
		DECLARE @FXRate DECIMAL(9,6) = 1;	--Default Value set to : 1
		DECLARE @ReferenceModule VARCHAR(100) = '';
		DECLARE @ModuleName VARCHAR(20) = ''
		DECLARE @RPOReferenceModule VARCHAR(100) = 'RPO';		
		DECLARE @RROReferenceModule VARCHAR(100) = 'RRO';


		DECLARE @IsBypassAccounting BIT = 0;		

		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
		SELECT @CodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'JournalType'
		DECLARE @POModuleID INT = 4; 
		DECLARE @ROModuleID INT = 24;
		SELECT @POModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'POHeader';
		SELECT @ROModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ROHeader';

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

		SELECT @DistributionMasterId = [ID],
		       @DistributionCode = [DistributionCode]
		 FROM [dbo].[DistributionMaster] WITH(NOLOCK)
		WHERE [DistributionCode] = 'GRNIADJUSTMENT'	

		DECLARE @IsRestrict BIT;
		DECLARE @IsAccountByPass BIT;

		EXEC [dbo].[USP_GetSubLadgerGLAccountRestriction]  @DistributionCode,  @MasterCompanyId,  0,  @UpdateBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

		SELECT @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
		  FROM [dbo].[DistributionSetup] WITH(NOLOCK)   
		  WHERE [DistributionSetupCode] = 'GRNIADJUSTMENT'
		    AND [MasterCompanyId] = @MasterCompanyId
		    AND [DistributionMasterId] = (SELECT  [ID] FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'GRNIADJUSTMENT')

		IF(ISNULL(@AdjusmentAmount,0) > 0 AND ISNULL(@IsAccountByPass, 0) = 0 AND @IsBypassAccounting = 0)
		BEGIN		
			
			SELECT @StatusId =[Id],@StatusName=[Name] FROM [dbo].[BatchStatus] WITH(NOLOCK)  WHERE [Name]= 'Open'

			SELECT TOP 1 @JournalTypeId = [JournalTypeId] FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE [DistributionMasterId] =@DistributionMasterId

			SELECT @JournalBatchHeaderId = [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE [JournalTypeId]= @JournalTypeId and [StatusId]=@StatusId

			SELECT @JournalTypeCode =[JournalTypeCode],@JournalTypename=[JournalTypeName] FROM [dbo].[JournalType] WITH(NOLOCK)  WHERE [ID] = @JournalTypeId

			SELECT @CurrentManagementStructureId = [ManagementStructureId] FROM [dbo].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM(REPLACE([FirstName], ' ', '')),'',TRIM(REPLACE([LastName], ' ', ''))) IN (REPLACE(@UpdateBy, ' ', '')) and [MasterCompanyId]=@MasterCompanyId
					
			IF(@ModuleId = @POModuleID)
			BEGIN
				SELECT @OrderNumber = [PurchaseOrderNumber],@VendorId=[VendorId],@VendorName = [VendorName] FROM [dbo].[PurchaseOrder] WITH(NOLOCK) WHERE [PurchaseOrderId] = @RefrenceId;

				SELECT @ItemMasterId = [ItemMasterId],@MPNName = [PartNumber],@ManagementStructureId =[ManagementStructureId] FROM [dbo].[PurchaseOrderPart] WITH(NOLOCK) WHERE [PurchaseOrderId] = @RefrenceId AND [PurchaseOrderPartRecordId] = @SubReferenceId;

				SELECT @LastMSLevel = [LastMSLevel],
				       @AllMSlevels = [AllMSlevels] 
			    FROM [dbo].[PurchaseOrderManagementStructureDetails] WITH(NOLOCK) 
				WHERE [EntityMSID] = @ManagementStructureId AND [ModuleID] = @POModuleID AND [ReferenceID] = @RefrenceId;
				
				SET @ReferenceModule = 'RPO';
				
				SET @ModuleName = 'ReceivingPO';

				UPDATE [dbo].[PurchaseOrderPart] SET [IsGRNIAdjustment] = 1 WHERE [PurchaseOrderId] = @RefrenceId AND [PurchaseOrderPartRecordId] = @SubReferenceId;				
			END
			ELSE
			BEGIN
				SELECT @OrderNumber = [RepairOrderNumber],@VendorId=[VendorId],@VendorName = [VendorName] FROM [dbo].[RepairOrder] WITH(NOLOCK) WHERE [RepairOrderId] = @RefrenceId;

				SELECT @ItemMasterId = [ItemMasterId],@MPNName = [PartNumber],@ManagementStructureId =[ManagementStructureId] FROM [dbo].[RepairOrderPart] WITH(NOLOCK) WHERE [RepairOrderId] = @RefrenceId AND [RepairOrderPartRecordId] = @SubReferenceId;

				SELECT @LastMSLevel = [LastMSLevel],
				       @AllMSlevels = [AllMSlevels] 
			    FROM [dbo].[RepairOrderManagementStructureDetails] WITH(NOLOCK) 
				WHERE [EntityMSID] = @ManagementStructureId AND [ModuleID] = @ROModuleID AND [ReferenceID] = @RefrenceId;	

				SET @ReferenceModule = 'RRO';		

				SET @ModuleName = 'ReceivingRO';

				UPDATE [dbo].[RepairOrderPart] SET [IsGRNIAdjustment] = 1 WHERE [RepairOrderId] = @RefrenceId AND [RepairOrderPartRecordId] = @SubReferenceId;
			END					
			
			INSERT INTO #tmpCodePrefixes ([CodePrefixId],[CodeTypeId],[CurrentNumber], [CodePrefix], [CodeSufix], [StartsFrom]) 
			SELECT [CodePrefixId], CP.[CodeTypeId], [CurrentNummber], [CodePrefix], [CodeSufix], [StartsFrom] 
			FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) JOIN [dbo].[CodeTypes] CT WITH(NOLOCK) ON CP.[CodeTypeId] = CT.[CodeTypeId]
			WHERE CT.[CodeTypeId] IN (@CodeTypeId) AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0;


			SELECT TOP 1  @AccountingPeriodId=acc.[AccountingCalendarId],@AccountingPeriod=[PeriodName] 
			FROM [dbo].[EntityStructureSetup] est WITH(NOLOCK) 
				INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) on est.[Level1Id] = msl.[ID] 
				INNER JOIN [dbo].[AccountingCalendar] acc WITH(NOLOCK) on msl.[LegalEntityId] = acc.[LegalEntityId] and acc.[IsDeleted] =0
			WHERE est.[EntityStructureId]=@CurrentManagementStructureId and acc.[MasterCompanyId]=@MasterCompanyId  
				AND CAST(GETUTCDATE() AS DATE)   >= CAST([FromDate] AS DATE) and  CAST(GETUTCDATE() AS DATE) <= CAST([ToDate] AS DATE)

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId))
			BEGIN 
				SELECT 
					@currentNo = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 
					ELSE CAST([StartsFrom] AS BIGINT) + 1 END 
					FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId
					  	  
				SET @JournalTypeNumber = (SELECT * FROM [dbo].udfGenerateCodeNumber(@currentNo,(SELECT [CodePrefix] FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId), (SELECT [CodeSufix] FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId)))
			END
			ELSE 
			BEGIN
				ROLLBACK TRAN;
			END
			
			IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE [JournalTypeId]= @JournalTypeId and [MasterCompanyId]=@MasterCompanyId and CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE)and [StatusId]=@StatusId)
			BEGIN
				IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
				BEGIN  
					set @batch ='001'  
					set @Currentbatch='001' 
				END
				ELSE
				BEGIN 
					SELECT top 1 @Currentbatch = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1   
					  ELSE  1 END   
					FROM [dbo].[BatchHeader] WITH(NOLOCK) Order by [JournalBatchHeaderId] desc  

					IF(CAST(@Currentbatch AS BIGINT) >99)  
					BEGIN
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))  
						  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END   
					END  
					ELSE IF(CAST(@Currentbatch AS BIGINT) >9)  
					BEGIN    
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))  
						  ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END   
					END
					ELSE
					BEGIN
					   SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))  
						  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END   
  
					END  
				END
			
				SET @CurrentNumber = CAST(@Currentbatch AS BIGINT)     
				SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as VARCHAR(100)) AS VARCHAR(100))  

				INSERT INTO [dbo].[BatchHeader]    
				  ([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],[AccountingPeriodId],[StatusId],[StatusName],
				  [JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],
				  [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])    
				VALUES    
				  (@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,
				  @JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,
				  @UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@JournalTypeCode);    
                           
				SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()    
				Update [dbo].[BatchHeader] set [CurrentNumber]=@CurrentNumber  WHERE [JournalBatchHeaderId]= @JournalBatchHeaderId  
			END
			ELSE
			BEGIN 
				SELECT @JournalBatchHeaderId=[JournalBatchHeaderId],@CurrentPeriodId=isnull([AccountingPeriodId],0) FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE [JournalTypeId]= @JournalTypeId and [StatusId]=@StatusId   
				   SELECT @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE  1 END   
						 FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE [JournalBatchHeaderId]=@JournalBatchHeaderId  Order by [JournalBatchDetailId] desc   
          
				if(@CurrentPeriodId =0)  
				begin  
				   Update [dbo].[BatchHeader] set [AccountingPeriodId]=@AccountingPeriodId,[AccountingPeriod]=@AccountingPeriod   WHERE [JournalBatchHeaderId]= @JournalBatchHeaderId  
				END  

				SET @IsBatchGenerated = 1;
			END

			INSERT INTO [dbo].[BatchDetails]([JournalTypeNumber],[CurrentNumber],[DistributionSetupId], [DistributionName], [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
			[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], [LastMSLevel], [AllMSlevels], [MasterCompanyId], 
			[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[AccountingPeriodId],[AccountingPeriod])
			VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
			@JournalTypeId, @JournalTypename, 1, 0, 0, @ManagementStructureId, 'GRNI ADJUSTMENT', 
			NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0 , @AccountingPeriodId,@AccountingPeriod)
		
			SET @JournalBatchDetailId = SCOPE_IDENTITY()

			 ----- GRNI --------

			 SELECT TOP 1 @DistributionSetupId=[ID],
			              @DistributionName=[Name],
						  @JournalTypeId =[JournalTypeId], 
						  @CRDRType =[CRDRType],			    
						  @IsAutoPost = ISNULL([IsAutoPost],0), 
						  @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
			 FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
			 WHERE [DistributionSetupCode] = 'GRNIADJUSTMENT'
			   AND [DistributionMasterId] = (SELECT [ID] FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'GRNIADJUSTMENT')
			   AND [MasterCompanyId] = @MasterCompanyId
			 							
			SELECT @GlAccountId = [GLAccountId],
				   @GlAccountNumber = [AccountCode],
				   @GlAccountName = [AccountName]
			FROM [dbo].[GLAccount] WITH(NOLOCK)
			WHERE [GLAccountId] = @GRNIglAccountId
			  AND [MasterCompanyId] = @MasterCompanyId;
			

			IF(@IsBypassAccounting = 0)
			BEGIN
				 INSERT INTO [dbo].[CommonBatchDetails]
					([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					1,@AdjusmentAmount,0,				
					@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@OrderNumber,@VendorName,@CurrencyCode,@FXRate,@CurrencyCode,@RefrenceId,@ReferenceModule)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
				INSERT INTO [dbo].[StocklineBatchDetails]([JournalBatchDetailId], [JournalBatchHeaderId], [VendorId], [VendorName], [ItemMasterId], [PartId], [PartNumber], [PoId], [PONum], [RoId], 
					[RONum], [StocklineId], [StocklineNumber], [Consignment], [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], 
					[ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
					VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @SubReferenceId, @MPNName, @RefrenceId, @OrderNumber, @RefrenceId, 
					@OrderNumber, NULL, NULL, '', @Desc, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
					@StockType,@CommonBatchDetailId)

			END

			 ----- COGS ------
			 						 				
			 SELECT TOP 1 @DistributionSetupId=[ID],
			              @DistributionName=[Name],
						  @JournalTypeId =[JournalTypeId], 
						  @CRDRType =[CRDRType],			    
						  @IsAutoPost = ISNULL([IsAutoPost],0), 
						  @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
			 FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
			 WHERE [DistributionSetupCode] = 'COGSADJUSTMENT'
			 AND [DistributionMasterId] = (SELECT [ID] FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'GRNIADJUSTMENT')
			 AND [MasterCompanyId] = @MasterCompanyId
			 							
			SELECT @GlAccountId = [GLAccountId],
				   @GlAccountNumber = [AccountCode],
				   @GlAccountName = [AccountName]
			FROM [dbo].[GLAccount] WITH(NOLOCK)
			WHERE [GLAccountId] = @COGSglAccountId
			  AND [MasterCompanyId] = @MasterCompanyId;

			IF(@IsBypassAccounting = 0)
			BEGIN

			 INSERT INTO [dbo].[CommonBatchDetails]
				([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],
				[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
				[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],
				[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
				VALUES	
				(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
				,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,				
				0,0,@AdjusmentAmount,
				@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
				@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@OrderNumber,@VendorName,@CurrencyCode,@FXRate,@CurrencyCode,@RefrenceId,@ReferenceModule)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
				INSERT INTO [dbo].[StocklineBatchDetails]([JournalBatchDetailId], [JournalBatchHeaderId], [VendorId], [VendorName], [ItemMasterId], [PartId], [PartNumber], [PoId], [PONum], [RoId], 
				[RONum], [StocklineId], [StocklineNumber], [Consignment], [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], 
				[ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
				VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @SubReferenceId, @MPNName, @RefrenceId, @OrderNumber, @RefrenceId, 
				@OrderNumber, NULL, NULL, '', @Desc, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
				@StockType,@CommonBatchDetailId)

			 -----STOCK - INVENTORY--------
            END

			SET @TotalDebit=0;
			SET @TotalCredit=0;
			SELECT @TotalDebit = SUM([DebitAmount]),@TotalCredit = SUM([CreditAmount]) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE [JournalBatchDetailId]=@JournalBatchDetailId group by [JournalBatchDetailId]
			UPDATE [dbo].[BatchDetails] SET [DebitAmount]=@TotalDebit,[CreditAmount]=@TotalCredit,[UpdatedDate] = GETUTCDATE(),[UpdatedBy]=@UpdateBy   WHERE [JournalBatchDetailId]=@JournalBatchDetailId

		
			SELECT @TotalDebit = SUM([DebitAmount]),@TotalCredit = SUM([CreditAmount]) FROM [dbo].[BatchDetails] 
			WITH(NOLOCK) WHERE [JournalBatchHeaderId]=@JournalBatchHeaderId and [IsDeleted]=0 
			SET @TotalBalance =@TotalDebit-@TotalCredit

			UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @currentNo WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId    
			UPDATE [dbo].[BatchHeader] SET [TotalDebit]=@TotalDebit,[TotalCredit]=@TotalCredit,[TotalBalance]=@TotalBalance,[UpdatedDate]=GETUTCDATE(),[UpdatedBy]=@UpdateBy WHERE [JournalBatchHeaderId]= @JournalBatchHeaderId

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
	END
	COMMIT  TRANSACTION
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PostManualStockLineBatchDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec [dbo].[spLogException] 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END