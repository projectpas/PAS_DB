/*************************************************************           
 ** File:   [USP_PostManualStockLineBatchDetails]           
 ** Author: Devendra Shekh
 ** Description: This stored procedure is used insert manual stockline detail(report) in batch
 ** Purpose:         
 ** Date:  14-July-2023

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				 Author					Change Description            
 ** --   --------			-------				--------------------------------          
    1    14-July-2023		 Devendra Shekh			Created	
	2    18-July-2023		 Devendra Shekh			getting glaccount details for stock inventory
	3    21/08/2023          Moin Bloch             Modify(Added Accounting MS Entry)
	4    14/02/2024          HEMANT SALIYA          Updated for Use Code insted of Name
	5    11/26/2023			 HEMANT SALIYA		    Updated Journal Type Id and Name in Batch Details
	6    28-AUG-2024	     Devendra Shekh		    JE Number reset to Zero Issue resolved
	7    20/09/2024			 AMIT GHEDIYA			Added for AutoPost Batch
	8	 09/10/2024			 Devendra Shekh			Added new fields for [CommonBatchDetails]
     
	 exec USP_PostManualStockLineBatchDetails 164040
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_PostManualStockLineBatchDetails]
(
	@StocklineId BIGINT
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
		DECLARE @CheckAmount DECIMAL(18,2)
		DECLARE @ManagementStructureId bigint
		DECLARE @LastMSLevel varchar(200)
		DECLARE @AllMSlevels varchar(max)
		DECLARE @ModuleId INT
		DECLARE @TotalDebit decimal(18, 2) =0;
		DECLARE @TotalCredit decimal(18, 2) =0;
		DECLARE @TotalBalance decimal(18, 2) =0;
		DECLARE @VendorName VARCHAR(50);
		DECLARE @CRDRType BIGINT = 0;
		DECLARE @StocklineNumber varchar(50) ='';
		DECLARE @WorkOrderNumber varchar(200);
		DECLARE @partId bigint=0;
		DECLARE @ItemMasterId bigint=NULL;
		DECLARE @PurchaseOrderId BIGINT=0;
		DECLARE @PurchaseOrderNumber varchar(50) ='';
		DECLARE @RepairOrderId BIGINT=0;
		DECLARE @RepairOrderNumber varchar(50) ='';
		DECLARE @SiteId BIGINT;
		DECLARE @Site varchar(100) ='';
		DECLARE @WarehouseId BIGINT;
		DECLARE @Warehouse varchar(100) ='';
		DECLARE @LocationId BIGINT;
		DECLARE @Location varchar(100) ='';
		DECLARE @BinId BIGINT;
		DECLARE @Bin varchar(100) ='';
		DECLARE @ShelfId BIGINT;
		DECLARE @Shelf varchar(100) ='';
		DECLARE @MPNName varchar(200);
		DECLARE @Desc varchar(100);
		DECLARE @VendorId bigint;
		DECLARE @StockType VARCHAR(50) = 'STOCK';
		DECLARE @StkGlAccountId BIGINT
		DECLARE @StkGlAccountName varchar(200) 
		DECLARE @StkGlAccountNumber varchar(200) 
		DECLARE @AccountMSModuleId INT = 0
		DECLARE @IsAutoPost INT = 0;
		DECLARE @IsBatchGenerated INT = 0;
		DECLARE @CurrencyCode VARCHAR(20) = '';
		DECLARE @FXRate DECIMAL(9,2) = 1;	--Default Value set to : 1

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
		
		SELECT @CheckAmount = SUM(ISNULL(UnitCost * Quantity,0)) FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @StocklineId --AND VendorId = @VendorId
		SELECT @MasterCompanyId=MasterCompanyId,@UpdateBy=CreatedBy FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @StocklineId
		SELECT @DistributionMasterId =ID,@DistributionCode =DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK)  WHERE UPPER(DistributionCode)= UPPER('ManualStockLine')	

		DECLARE @IsRestrict BIT;
		DECLARE @IsAccountByPass BIT;

		EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdateBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

		IF(ISNULL(@CheckAmount,0) > 0 AND ISNULL(@IsAccountByPass, 0) = 0)
		BEGIN		
			
			SELECT @StatusId =Id,@StatusName=name FROM dbo.BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
			SELECT TOP 1 @JournalTypeId =JournalTypeId FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId
			SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
			SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM dbo.JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
			SELECT @CurrentManagementStructureId =ManagementStructureId FROM dbo.Employee WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (replace(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
			SELECT @ModuleId = ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'Stockline'

			SELECT @WorkOrderNumber=StockLineNumber, @partId=PurchaseOrderPartRecordId, @ItemMasterId=ItemMasterId, @ManagementStructureId=ManagementStructureId, @MasterCompanyId=sl.MasterCompanyId,
				@PurchaseOrderId=PurchaseOrderId, @RepairOrderId=RepairOrderId, @StocklineNumber=StocklineNumber, @SiteId=[SiteId], @Site=[Site], @WarehouseId=[WarehouseId], @Warehouse=[Warehouse],
				@LocationId=[LocationId], @Location=[Location], @BinId=[BinId], @Bin=[Bin], @ShelfId=[ShelfId], @Shelf=[Shelf], @VendorId=VendorId,
				@StkGlAccountId = sl.GLAccountId, @StkGlAccountName = gl.AccountName, @StkGlAccountNumber = gl.AccountCode
			FROM dbo.Stockline sl WITH(NOLOCK)
				LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON sl.GLAccountId = gl.GLAccountId
			WHERE StockLineId=@StocklineId;

			SELECT @LastMSLevel = LastMSLevel,@AllMSlevels = AllMSlevels FROM dbo.StocklineManagementStructureDetails WITH(NOLOCK) WHERE EntityMSID = @ManagementStructureId AND ModuleID = @ModuleId AND ReferenceID = @StocklineId
			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
			FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

			SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
			FROM dbo.EntityStructureSetup est WITH(NOLOCK) 
				INNER JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
				INNER JOIN dbo.AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
			WHERE est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  
				AND CAST(GETUTCDATE() as date)   >= CAST(FromDate as date) and  CAST(GETUTCDATE() as date) <= CAST(ToDate as date)

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
			
			IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
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
				SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId   
				   SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END   
						 FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc   
          
				if(@CurrentPeriodId =0)  
				begin  
				   Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
				END  

				SET @IsBatchGenerated = 1;
			END

			INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
			[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
			[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
			@JournalTypeId, @JournalTypename, 1, 0, 0, @ManagementStructureId, 'ManualStockLine', 
			NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
		
			SET @JournalBatchDetailId = SCOPE_IDENTITY()

			 -----Account Payable || COGS / Inventory Reserve--------

			 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId, @CRDRType =CRDRType,
			 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@IsAutoPost = ISNULL(IsAutoPost,0) 
			 FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) = UPPER('MSTK-ACCPAYABLE')  --WHERE UPPER(Name) =UPPER('COGS / Inventory Reserve') 
			 AND DistributionMasterId = (SELECT TOP 1 ID FROM dbo.DistributionMaster WITH(NOLOCK) WHERE DistributionCode = 'ManualStockLine')

			 INSERT INTO [dbo].[CommonBatchDetails]
				(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
				[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
				[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
				[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
				VALUES	
				(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
				,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
				CASE WHEN @CRDRType = 1 THEN 1 ELSE 0 END,
				CASE WHEN @CRDRType = 1 THEN @CheckAmount ELSE 0 END,
				CASE WHEN @CRDRType = 1 THEN 0 ELSE @CheckAmount END,
				--1,@CheckAmount,0
				@ManagementStructureId ,'Stockline',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
				@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@StocklineNumber,'',@CurrencyCode,@FXRate,@CurrencyCode)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
				INSERT INTO [dbo].[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, 
				RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], 
				[ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
				VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, 
				@RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, 
				@StockType,@CommonBatchDetailId)

			 -----Account Payable || COGS / Inventory Reserve--------

			 -----STOCK - INVENTORY--------
			 				
			 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId, @CRDRType =CRDRType,
			 @GlAccountId = GlAccountId,@GlAccountNumber = GlAccountNumber,@GlAccountName = GlAccountName 
			 FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) = UPPER('MSTK-STOCK-INV') 
			 AND DistributionMasterId = (SELECT TOP 1 ID FROM dbo.DistributionMaster WITH(NOLOCK) WHERE DistributionCode = 'ManualStockLine')


			 INSERT INTO [dbo].[CommonBatchDetails]
				(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
				[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
				[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
				[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
				VALUES	
				(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
				,@StkGlAccountId ,@StkGlAccountNumber ,@StkGlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,				
				1,@CheckAmount,0,
				@ManagementStructureId ,'Stockline',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
				@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@StocklineNumber,'',@CurrencyCode,@FXRate,@CurrencyCode)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
				INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, 
				RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], 
				[ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
				VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, 
				@RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, 
				@StockType,@CommonBatchDetailId)

			 -----STOCK - INVENTORY--------

			SET @TotalDebit=0;
			SET @TotalCredit=0;
			SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
			UPDATE BatchDetails SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate = GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchDetailId=@JournalBatchDetailId

		
			SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].BatchDetails 
			WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 
			SET @TotalBalance =@TotalDebit-@TotalCredit

			UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
			UPDATE BatchHeader SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId

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

	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PostManualStockLineBatchDetails' 
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