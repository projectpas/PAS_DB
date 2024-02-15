/*************************************************************             
 ** File:   [USP_UpdateStockLineInventory]             
 ** Author:   
 ** Description: This stored procedure is used to update Stockline inventory and also manage accounting Data
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    30/05/2023   Satish Gohil  Create
	2    31/05/2023   Satish Gohil	Modify(Added Accounting entry for Negative Stockline and also  Acc Period changes)
	3    05/06/2023   Satish Gohil  Modify(Calculation issue fixed)
	4    21/08/2023   Moin Bloch    Modify(Added Accounting MS Entry)
	5    14/02/2023	  Moin Bloch	Updated Used Distribution Setup Code Insted of Name 

**************************************************************/  

CREATE   PROCEDURE [dbo].[USP_UpdateStockLineInventory]
(
	@AccountcalenderId BIGINT,
	@InventoryType VARCHAR(10),
	@tbl_StockLineInventoryType StockLineInventoryType Readonly,
	@MasterCompanyId BIGINT,
	@UpdateBy VARCHAR(50)	
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN
		BEGIN TRANSACTION
		BEGIN
		 IF OBJECT_ID(N'tempdb..#temptable') IS NOT NULL      
		 BEGIN      
		   DROP TABLE #tmpReturnTbl      
		 END      

		 create table #temptable    
		 (    
		   rownumber int identity(1,1),    
		   StockLineId bigint NULL,    
		   OldQtyAvl bigint NULL,     
		   NewQtyAvl bigint NULL,
		   UnitPrice decimal(18,2) NULL,
		   OldUnitPrice decimal(18,2) NULL,
		   QtyOnHand bigint NULL
		  )     
		
		  DECLARE @MinId BIGINT = 1;    
		  DECLARE @TotalRecord int = 0;    
		  DECLARE @StockLineModule int = 0;
		  DECLARE @UnitPrice decimal(18,2)=0;
		  DECLARE @Amount Decimal(18,2)=0;
		  DECLARE @OldQtyAvl BIGINT=0;
		  DECLARE @QtyAvl BIGINT=0;
		  DECLARE @QtyDiffenece BIGINT=0;
		  DECLARE @UnitPriceDiffenece BIGINT=0;
		  DECLARE @StockLineId BIGINT=0;
		  DECLARE @QtyOnHand BIGINT=0;
		  DECLARE @JournalBatchDetailId BIGINT=0;
		  DECLARE @CommonJournalBatchDetailId bigint=0;
		  DECLARE @DistributionMasterId bigint;
		  DECLARE @DistributionSetupId int=0
		  DECLARE @IsAccountByPass bit=0
		  DECLARE @DistributionCode varchar(200);
		  DECLARE @JournalTypeId int
		  DECLARE @JournalTypeCode varchar(200) 
		  DECLARE @JournalBatchHeaderId bigint
		  DECLARE @GlAccountId bigint
		  DECLARE @StatusId int
		  DECLARE @StatusName varchar(200)
		  DECLARE @StartsFrom varchar(200)='00'
		  DECLARE @JournalTypename varchar(200) 
		  DECLARE @AccountingPeriod varchar(100)
		  DECLARE @AccountingPeriodId bigint=0;
		  DECLARE @JournalTypeNumber varchar(100);
		  DECLARE @CodeTypeId AS BIGINT = 74;
		  DECLARE @currentNo AS BIGINT = 0;
		  DECLARE @batch varchar(100);
		  DECLARE @Currentbatch varchar(100);
		  DECLARE @CurrentNumber bigint;
		  DECLARE @CurrentPeriodId bigint=0;
		  DECLARE @LineNumber int=1;

		  DECLARE @VendorId bigint;
		  DECLARE @VendorName varchar(50);
		  DECLARE @ReferenceId bigint=NULL;
		  DECLARE @StockLineNumber VARCHAR(50);
		  DECLARE @ManagementStructureId BIGINT
		  DECLARE @Distributionname varchar(200);
		  DECLARE @GlAccountName varchar(200) 
		  DECLARE @GlAccountNumber varchar(200) 
		  DECLARE @ModuleName varchar(200)='StocklineAdjustment';
		  DECLARE @LastMSLevel varchar(200);
		  DECLARE @AllMSlevels varchar(max);
		  DECLARE @STKMSModuleID bigint=2;
		  DECLARE @ItemMasterId BIGINT;
		  DECLARE @ManufacturerId AS BIGINT;
		  DECLARE @partId bigint=0
		  DECLARE @MPNName varchar(200) 
		  DECLARE @SiteId bigint=0
		  DECLARE @WarehouseId bigint=0
		  DECLARE @LocationId bigint=0
		  DECLARE @BinId bigint=0
		  DECLARE @ShelfId bigint=0
		  DECLARE @TotalDebit decimal(18,2)=0
		  DECLARE @TotalCredit decimal(18,2)=0
		  DECLARE @TotalBalance decimal(18,2)=0
		  DECLARE @CurrentManagementStructureId INT = 0
		  DECLARE @CreatedDate DATETIME2 = NULL

		  DECLARE @AccountMSModuleId INT = 0
		  SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

		  SELECT @StockLineModule =ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'StockLine' 

		  INSERT INTO #temptable(StockLineId,OldQtyAvl,NewQtyAvl,UnitPrice,OldUnitPrice,QtyOnHand)
		  SELECT StockLineId,OldQty,NewQty,UnitPrice,OldUnitPrice,QtyOnHand
		  FROM @tbl_StockLineInventoryType


		  select top 1  @AccountingPeriodId=AccountingCalendarId,@AccountingPeriod=PeriodName,@CreatedDate = ToDate from AccountingCalendar  WITH(NOLOCK)
		  WHERE AccountingCalendarId = @AccountcalenderId AND ISNULL(isinventoryStatusName,0)= 1
		   
		  IF(ISNULL(@AccountingPeriodId,0) = 0)
		  BEGIN 
			SELECT @AccountingPeriod = ISNULL(ACC.PeriodName,''),@AccountingPeriodId = ISNULL(ACC.AccountingCalendarId,0),@CreatedDate = ACC.ToDate
			FROM dbo.AccountingCalendar A with(nolock)  
			LEFT JOIN dbo.AccountingCalendar B with(nolock) ON A.AccountingCalendarId = B.AccountingCalendarId AND ISNULL(B.isinventoryStatusName,0) = 1 
			OUTER APPLY(SELECT TOP 1 AccountingCalendarId,ISNULL(C.PeriodName,'') PeriodName,C.ToDate FROM
				dbo.AccountingCalendar C with(nolock) 
				WHERE A.LegalEntityId = C.LegalEntityId AND ISNULL(C.isinventoryStatusName,0) = 1 AND C.FromDate > A.ToDate  
			)ACC
			WHERE A.AccountingCalendarId = @AccountcalenderId  
		  END 
		 -- IF(@InventoryType = '1')
		 -- BEGIN
			--UPDATE T1
			--SET T1.QuantityAvailable = 0,
			--T1.QuantityOnHand = 0,
			--T1.UpdatedBy = @UpdateBy,
			--T1.UpdatedDate = GETUTCDATE()
			--FROM dbo.Stockline T1
			--INNER JOIN #temptable T2 ON T1.StockLineId = T2.StockLineId

		 -- END
		 -- IF(@InventoryType = '3')
		 -- BEGIN 
			IF(ISNULL(@AccountingPeriodId,0) <> 0)
			BEGIN
				SET @CreatedDate = Convert(datetime,(CAST(CONVERT (date, @CreatedDate) as varchar(10)) +' ' + CAST(CONVERT (time, GETUTCDATE(),8) as varchar(8))),20)
			END

			SELECT @TotalRecord = COUNT(*), @MinId = MIN(rownumber) FROM #temptable    

			WHILE @MinId <= @TotalRecord
			BEGIN
			
				SELECT @StockLineId =StockLineId,@QtyAvl=NewQtyAvl,
				@QtyDiffenece = CASE WHEN @InventoryType = '1' THEN ISNULL(NewQtyAvl,0) ELSE  (ISNULL(NewQtyAvl,0) -ISNULL(OldQtyAvl,0))  END,
				@UnitPriceDiffenece = (ISNULL(UnitPrice,0) - ISNULL(OldUnitPrice,0)),
				@QtyOnHand=QtyOnHand,@OldQtyAvl=OldQtyAvl,@UnitPrice = UnitPrice 
				FROM #temptable WHERE rownumber = @MinId


				------ Update StockLine --------
				UPDATE dbo.Stockline 
				SET QuantityAvailable = CASE WHEN @InventoryType = '1' THEN 0 ELSE @QtyAvl END,
				QuantityOnHand = CASE WHEN @InventoryType = '1' THEN 0 ELSE @QtyOnHand + ISNULL(@QtyDiffenece,0) END,
				UnitCost = @UnitPrice,
				UpdatedBy = @UpdateBy,
				UpdatedDate = GETUTCDATE()
				WHERE StockLineId = @StockLineId

				EXEC USP_UpdateChildStockline @StockLineId,@MasterCompanyId,@StockLineModule,@StockLineId,0,0

				------ Update StockLine --------

				------ Update StockLine Accounting --------
				SELECT @DistributionMasterId =ID from dbo.DistributionMaster WITH(NOLOCK)  WHERE UPPER(DistributionCode)= UPPER('StocklineAdjustment')

				SELECT @IsAccountByPass =IsAccountByPass from dbo.MasterCompany WITH(NOLOCK)  where MasterCompanyId= @MasterCompanyId
				SELECT @DistributionCode =DistributionCode from dbo.DistributionMaster WITH(NOLOCK)  where ID= @DistributionMasterId
				SELECT @StatusId =Id,@StatusName=name from dbo.BatchStatus WITH(NOLOCK)  where Name= 'Open'
				SELECT top 1 @JournalTypeId =JournalTypeId from dbo.DistributionSetup WITH(NOLOCK)  where DistributionMasterId =@DistributionMasterId
				SELECT @JournalBatchHeaderId =JournalBatchHeaderId from dbo.BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and StatusId=@StatusId
				SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName from dbo.JournalType WITH(NOLOCK)  where ID= @JournalTypeId
				SELECT @CurrentManagementStructureId = ManagementStructureId FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @StockLineId
				SET @Amount = ISNULL(@QtyAvl,0) * ISNULL(@UnitPrice,0)

				IF((@JournalTypeCode ='ADJ') and @IsAccountByPass=0 AND @Amount > 0)
				BEGIN
					--select top 1  @AccountingPeriodId=AccountingCalendarId,@AccountingPeriod=PeriodName from AccountingCalendar  WITH(NOLOCK) 
					--WHERE AccountingCalendarId = @AccountcalenderId

					--SELECT top 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName from EntityStructureSetup est WITH(NOLOCK) 
					--inner join ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
					--inner join AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
					--WHERE est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  and CAST(GETUTCDATE() as date)   >= CAST(FromDate as date) and  CAST(GETUTCDATE() as date) <= CAST(ToDate as date)

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

					INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
						SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
						FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
						WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

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
						ROLLBACK TRAN
					END

					IF NOT EXISTS(select JournalBatchHeaderId from BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and  CAST(EntryDate AS DATE) = CAST(CASE WHEN ISNULL(@AccountingPeriodId,0) = 0 THEN GETUTCDATE() ELSE @CreatedDate END AS DATE)and StatusId=@StatusId)
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

							if(CAST(@Currentbatch AS BIGINT) >99)
							begin

							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   						ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
							end
							Else if(CAST(@Currentbatch AS BIGINT) >9)
							begin

							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   						ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
							end
							else
							begin
							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   						ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 

							end
						END
						SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 
						SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as varchar(100)) as varchar(100))
						
						INSERT INTO [dbo].[BatchHeader]
								([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
								VALUES
											(@batch,@CurrentNumber,CASE WHEN ISNULL(@AccountingPeriodId,0) = 0 THEN GETUTCDATE() ELSE @CreatedDate END,@AccountingPeriod,ISNULL(@AccountingPeriodId,0),@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdateBy,@UpdateBy,
											CASE WHEN ISNULL(@AccountingPeriodId,0) = 0 THEN GETUTCDATE() ELSE @CreatedDate END,GETUTCDATE(),1,0,'ADJ');
				
						SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
						Update BatchHeader set CurrentNumber=@CurrentNumber  where JournalBatchHeaderId= @JournalBatchHeaderId
					END
					ELSE
					BEGIN
						SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) from BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and StatusId=@StatusId
						SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   								FROM BatchDetails WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    	
						if(@CurrentPeriodId =0)
						begin
							Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   where JournalBatchHeaderId= @JournalBatchHeaderId
						END
					END
						
					IF(UPPER(@DistributionCode) = UPPER('StocklineAdjustment'))
					BEGIN 
						Select @VendorId=VendorId,@ReferenceId=StockLineId,@StocklineNumber=StocklineNumber,@Amount = CASE WHEN ISNULL(@UnitPriceDiffenece,0) = 0 THEN UnitCost ELSE ABS(ISNULL(@UnitPriceDiffenece,0)) END
						,@ManagementStructureId = ManagementStructureId,
						@SiteId=[SiteId],@WarehouseId=[WarehouseId],@LocationId=[LocationId],@BinId=[BinId],@ShelfId=[ShelfId]
						from Stockline WITH(NOLOCK) where StockLineId=@StockLineId;
						select @VendorName =VendorName from Vendor WITH(NOLOCK)  where VendorId= @VendorId;
				
						SELECT @ItemMasterId = ItemMasterId, @ManufacturerId = ManufacturerId FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @StocklineId
						
						SET @Amount = CASE WHEN ISNULL(@QtyDiffenece,0) <> 0 AND ISNULL(@UnitPriceDiffenece,0) <> 0 THEN ABS(ABS(@UnitPrice * @QtyAvl) - ABS(@UnitPriceDiffenece * @QtyDiffenece))
						WHEN ISNULL(@QtyDiffenece,0) = 0 THEN ABS(@QtyAvl * @Amount) ELSE ABS(@QtyDiffenece * @Amount) END;	
						
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId 
						from dbo.DistributionSetup WITH(NOLOCK)  where UPPER(DistributionSetupCode) = UPPER('ADJSPEC') 
						AND DistributionMasterId=@DistributionMasterId
						
						SELECT @GlAccountId=ISNULL(GlAccountId,0) FROM DBO.Stockline WITH(NOLOCK) WHERE StocklineId=@StocklineId;
						SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName FROM DBO.GLAccount WITH(NOLOCK) WHERE @GlAccountId=GlAccountId;
						select @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels from StocklineManagementStructureDetails WITH(NOLOCK)  where ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID


						INSERT INTO [dbo].[BatchDetails]
							(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
							[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
							[ManagementStructureId],[ModuleName],
							LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,
							CASE WHEN ISNULL(@AccountingPeriodId,0) = 0 THEN GETUTCDATE() ELSE @CreatedDate END,CASE WHEN ISNULL(@AccountingPeriodId,0) = 0 THEN GETUTCDATE() ELSE @CreatedDate END,
							@JournalTypeId ,@JournalTypename ,
							1,@Amount ,0,
							@ManagementStructureId ,@ModuleName,
							@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,CASE WHEN ISNULL(@AccountingPeriodId,0) = 0 THEN GETUTCDATE() ELSE @CreatedDate END,GETUTCDATE(),1,0)

						SET @JournalBatchDetailId=SCOPE_IDENTITY()

						INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,CASE WHEN ISNULL(@AccountingPeriodId,0) = 0 THEN GETUTCDATE() ELSE @CreatedDate END,CASE WHEN ISNULL(@AccountingPeriodId,0) = 0 THEN GETUTCDATE() ELSE @CreatedDate END,@JournalTypeId ,@JournalTypename ,
									CASE WHEN @QtyDiffenece < 0 THEN 0 ELSE 1  END,
									CASE WHEN @QtyDiffenece < 0 THEN 0 ELSE @Amount END,
									CASE WHEN @QtyDiffenece < 0 THEN @Amount ELSE 0 END,
									@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,CASE WHEN ISNULL(@AccountingPeriodId,0) = 0 THEN GETUTCDATE() ELSE @CreatedDate END,GETUTCDATE(),1,0)

								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [StocklineBatchDetails]
							(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
							[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,NULL,NULL,NULL,NULL,@StockLineId,
							@StocklineNumber,'','Adjust Inventory Stock',@SiteId,'',@WarehouseId,'',@LocationId,'',@BinId,'',@ShelfId,'','STOCK',@CommonJournalBatchDetailId)


						-----Existing Stockline--------

						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName 
						from dbo.DistributionSetup WITH(NOLOCK)  
						where UPPER(DistributionSetupCode) =UPPER('ADJSPEC') AND DistributionMasterId=@DistributionMasterId

								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,CASE WHEN ISNULL(@AccountingPeriodId,0) = 0 THEN GETUTCDATE() ELSE @CreatedDate END,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									CASE WHEN @QtyDiffenece < 0 THEN 1 ELSE 0  END,
									CASE WHEN @QtyDiffenece < 0 THEN @Amount ELSE 0 END,
									CASE WHEN @QtyDiffenece < 0 THEN 0 ELSE @Amount END,
									@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,CASE WHEN ISNULL(@AccountingPeriodId,0) = 0 THEN GETUTCDATE() ELSE @CreatedDate END,GETUTCDATE(),1,0)

								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [StocklineBatchDetails]
								(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
								[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,NULL,NULL,NULL,NULL,@StockLineId,
								@StocklineNumber,'','Adjust Inventory Stock',@SiteId,'',@WarehouseId,'',@LocationId,'',@BinId,'',@ShelfId,'','STOCK',@CommonJournalBatchDetailId)

						SET @TotalDebit=0;
						SET @TotalCredit=0;
						SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
						UPDATE BatchDetails SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

						EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId

					END
					------ Update StockLine Accounting --------

					SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[BatchDetails] WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	         
					SET @TotalBalance =@TotalDebit-@TotalCredit
				         
					Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   where JournalBatchHeaderId= @JournalBatchHeaderId
					UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
				END
				
				SET @MinId = @MinId + 1
			END
		 
		
		  SELECT StockLineId FROM #temptable
	   END
	   COMMIT TRANSACTION
	END
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateStockLineInventory' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StocklineId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END