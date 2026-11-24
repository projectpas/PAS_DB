/*************************************************************
 ** File:   [USP_CreateBatch_DepreciableLeaseStockline]
 ** Author:  Kishor Makwana
 ** Description: This stored procedure is used TO Create Batch for Depreciable Lease Stockline
 **              (lease version of USP_CreateBatch_DepreciableAssetInventory - same distribution, journal, batch and auto-post logic;
 **              the AssetInventory tables are replaced by LeaseStockline / LeaseHeader / Stockline / ItemMaster).
 ** Purpose:
 **              Distribution      : ASSETPERIODICDEPRECIATION -> Depreciation Expense (DEPRECIATIONEXPENSEDEP) debit, Accumulated Depreciation (ACCUMULATEDDEPRECIATIONDEP) credit
 **              Amount            : fn_GetLeaseDepreciationAmount (Stockline.UnitCost x lease qty, Item Master Asset setup life / frequency / residual %)
 **              GL accounts       : Item Master Depr Expense / Accum Depr GL account (same fields the Asset Inventory copies), else the item's Asset class, else the distribution row
 **              Journal           : only when the journal type is AST-DEPR and the company is not Accounting By Pass (same as the Asset process)
 **              Stockline link    : every line is written to StocklineBatchDetails with the lease stockline's Stockline (PN, PO, RO, vendor, site / warehouse / location / shelf / bin)
 **                                  and to LeaseBatchDetails (Lease -> Accounting tab)
 **              The history is saved by SaveLeaseDepreciationData (same as SaveAssetDeprciationData for the Asset process).
 ** Date:   17/11/2026      [dd/mm/yyyy]
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author					Change Description
 ** --   --------		-------					--------------------------------
    1    17/11/2026		Kishor Makwana			Created (Process Depreciation - Lease)

declare @p1 dbo.DepreciableLeaseStockline
insert into @p1 values(15,1,500.00,N'LeaseStockline',N'ADMIN User',1,N'AssetPeriodDepreciation',185)
exec dbo.USP_CreateBatch_DepreciableLeaseStockline @tbl_DepreciableLeaseStockline=@p1
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_CreateBatch_DepreciableLeaseStockline]
(
	@tbl_DepreciableLeaseStockline DepreciableLeaseStockline READONLY
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

		IF OBJECT_ID(N'tempdb..#DepreciableLease') IS NOT NULL
        BEGIN
            DROP TABLE #DepreciableLease
        END

        CREATE TABLE #DepreciableLease
        (
			[DepreciableLeaseID] BIGINT NOT NULL IDENTITY,
			[LeaseStocklineId] [bigint] NULL,
			[Qty] [int] NULL,
			[Amount] [decimal](18,6) NULL,
			[ModuleName] [varchar](30) NULL,
			[UpdateBy] [varchar](50) NULL,
			[MasterCompanyId] [bigint] NULL,
			[StockType] [varchar](30) NULL,
			[SelectedAccountingPeriodId] [bigint] NULL
        )

		DECLARE @LeaseStocklineId bigint=NULL,
		@Qty int=0,
		@Amount Decimal(18,6),
		@ModuleName varchar(200),
		@UpdateBy varchar(200),
		@MasterCompanyId bigint,
		@StockType varchar(100),
		@SelectedAccountingPeriodId bigint=NULL;
		DECLARE @TotalRecords BIGINT = 0;
		DECLARE @StartCount BIGINT = 1;
		DECLARE @TotalAmount decimal(18,6)=0

		DECLARE @JournalTypeId int
		DECLARE @JournalTypeCode varchar(200)
		DECLARE @JournalBatchHeaderId bigint
		DECLARE @StatusId int
		DECLARE @StatusName varchar(200)
		DECLARE @JournalTypename varchar(200)
		DECLARE @GlAccountId bigint
		DECLARE @GlAccountNumber varchar(200)
		DECLARE @GlAccountName varchar(200)
		DECLARE @DistributionName varchar(200)
		DECLARE @DistributionSetupId int
		DECLARE @DistributionMasterId bigint
		DECLARE @DistributionCode varchar(200)
		DECLARE @ManagementStructureId bigint
		DECLARE @LastMSLevel varchar(200)
		DECLARE @AllMSlevels varchar(max)
		DECLARE @AccountingPeriod varchar(100)
		DECLARE @AccountingPeriodId bigint=0
		DECLARE @CurrentPeriodId bigint=0
		DECLARE @Currentbatch varchar(100)
		DECLARE @batch varchar(100)
		DECLARE @CurrentNumber int
		DECLARE @LineNumber int=1
		DECLARE @TotalDebit decimal(18,6)=0
		DECLARE @TotalCredit decimal(18,6)=0
		DECLARE @TotalBalance decimal(18,6)=0
		DECLARE @IsAccountByPass bit=0

		DECLARE @ItemMasterId bigint=NULL;
		DECLARE @MPNName varchar(200);
		DECLARE @AccountMSModuleId INT = 0;
		DECLARE @JournalBatchDetailId BIGINT=0;
		DECLARE @CommonJournalBatchDetailId bigint=0;
		DECLARE @StocklineId BIGINT;
		DECLARE @StocklineNumber varchar(50)='';
		DECLARE @PurchaseOrderId BIGINT=0;
		DECLARE @PurchaseOrderPartRecordId BIGINT=0;
		DECLARE @PurchaseOrderNumber varchar(50)='';
		DECLARE @RepairOrderId BIGINT=0;
		DECLARE @RepairOrderNumber varchar(50)='';
		DECLARE @VendorId bigint;
		DECLARE @VendorName varchar(50);
		DECLARE @SiteId BIGINT;
		DECLARE @Site varchar(100)='';
		DECLARE @WarehouseId BIGINT;
		DECLARE @Warehouse varchar(100)='';
		DECLARE @LocationId BIGINT;
		DECLARE @Location varchar(100)='';
		DECLARE @BinId BIGINT;
		DECLARE @Bin varchar(100)='';
		DECLARE @ShelfId BIGINT;
		DECLARE @Shelf varchar(100)='';
		DECLARE @Desc varchar(100);
		DECLARE @StocktypeStock varchar(50)='STOCK';

		DECLARE @LeaseHeaderId bigint;
		DECLARE @LeaseNumber varchar(50);
		DECLARE @CustomerId bigint;
		DECLARE @CustomerName varchar(100);
		DECLARE @CurrencyCode varchar(10);
		DECLARE @DepreciationAmount decimal(18,6)=0;
		DECLARE @AlreadyDepreciated bit=0;

		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @JournalTypeNumber varchar(100);
		DECLARE @DeprExpenseGLAccountId AS BIGINT = 0;
		DECLARE @AdDepsGLAccountId AS BIGINT = 0;
		DECLARE @CrDrType int=0;
		DECLARE @isNewJENum BIT = 0;
		DECLARE @IsAutoPost INT = 0;
		DECLARE @IsBypassAccounting BIT = 0;
		DECLARE @IsBatchGenerated INT = 0;
		DECLARE @RunJournalBatchDetailId BIGINT = 0;
		DECLARE @RunAutoPost INT = 0;
		DECLARE @isNewJENumRun BIT = 0;

		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

		SELECT @DistributionMasterId =ID FROM DBO.DistributionMaster WITH(NOLOCK)  WHERE UPPER(DistributionCode)= UPPER('ASSETPERIODICDEPRECIATION')

		INSERT INTO #DepreciableLease
		( [LeaseStocklineId], [Qty], [Amount], [ModuleName], [UpdateBy], [MasterCompanyId], [StockType], [SelectedAccountingPeriodId] )
		SELECT [LeaseStocklineId], [Qty], [Amount], [ModuleName], [UpdateBy], [MasterCompanyId], [StockType], [SelectedAccountingPeriodId] FROM @tbl_DepreciableLeaseStockline;

		SELECT @TotalRecords = COUNT([DepreciableLeaseID]), @TotalAmount = SUM([Amount]) FROM #DepreciableLease;

		WHILE(@TotalRecords >= @StartCount AND @TotalAmount <> 0)
		BEGIN

			SELECT @LeaseStocklineId = [LeaseStocklineId], @Qty = [Qty], @Amount = [Amount], @ModuleName = [ModuleName], @UpdateBy = [UpdateBy], @MasterCompanyId = [MasterCompanyId]
			, @StockType = [StockType], @SelectedAccountingPeriodId = [SelectedAccountingPeriodId] FROM #DepreciableLease WHERE [DepreciableLeaseID] = @StartCount;

			SELECT @IsAccountByPass =IsAccountByPass FROM DBO.MasterCompany WITH(NOLOCK)  WHERE MasterCompanyId= @MasterCompanyId
			SELECT @DistributionCode =DistributionCode FROM DBO.DistributionMaster WITH(NOLOCK)  WHERE ID= @DistributionMasterId
			SELECT @StatusId =Id,@StatusName=name FROM DBO.BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
			SELECT top 1 @JournalTypeId =JournalTypeId FROM DBO.DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId
			SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM DBO.JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
			SET @JournalBatchDetailId = CASE WHEN @StartCount = 1 THEN 0 ELSE @JournalBatchDetailId END;
			SET @isNewJENum = 0;

			-- lease stockline : depreciation of the selected period (LeaseStockline / LeaseHeader / Stockline / Item Master Asset setup)
			SET @DepreciationAmount = 0; SET @AlreadyDepreciated = 0; SET @LeaseHeaderId = NULL;
			SELECT @LeaseHeaderId = F.LeaseHeaderId, @LeaseNumber = F.LeaseNumber, @CustomerId = F.CustomerId, @CurrencyCode = F.CurrencyCode, @ManagementStructureId = F.ManagementStructureId,
				   @DepreciationAmount = F.DepreciationAmount, @AlreadyDepreciated = F.AlreadyDepreciated
			FROM [dbo].[fn_GetLeaseDepreciationAmount](@LeaseStocklineId, @SelectedAccountingPeriodId) F;

			-- nothing to depreciate (not an Active/eligible lease stockline, fully depreciated, or the period is already depreciated)
			IF (@LeaseHeaderId IS NULL OR @AlreadyDepreciated = 1 OR ISNULL(@DepreciationAmount, 0) <= 0)
			BEGIN
				SET @LeaseHeaderId = NULL;
				SET @StartCount += 1;
				CONTINUE;
			END

			SELECT @CustomerName = C.[Name] FROM [dbo].[Customer] C WITH(NOLOCK) WHERE C.CustomerId = @CustomerId;

			-- Stockline of the lease stockline (PN, PO, RO, vendor, site / warehouse / location / shelf / bin)
			SELECT @StocklineId = STK.StockLineId, @StocklineNumber = ISNULL(LSL.StocklineNumber, STK.StockLineNumber), @ItemMasterId = STK.ItemMasterId, @MPNName = STK.PartNumber,
				   @PurchaseOrderId = ISNULL(STK.PurchaseOrderId, 0), @PurchaseOrderPartRecordId = ISNULL(STK.PurchaseOrderPartRecordId, 0), @RepairOrderId = ISNULL(STK.RepairOrderId, 0), @VendorId = STK.VendorId,
				   @SiteId = STK.SiteId, @WarehouseId = STK.WarehouseId, @LocationId = STK.LocationId, @ShelfId = STK.ShelfId, @BinId = STK.BinId,
				   @DeprExpenseGLAccountId = COALESCE(NULLIF(IM.DeprExpenseGLAccountId, 0), NULLIF(dnd.DeprExpenseGLAccountId, 0)),
				   @AdDepsGLAccountId = COALESCE(NULLIF(IM.AdDepsGLAccountId, 0), NULLIF(dnd.AccumDeprGLAccountId, 0))
			FROM [dbo].[LeaseStockline] LSL WITH(NOLOCK)
			INNER JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON STK.StockLineId = LSL.StockLineId
			INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = LSL.ItemMasterId
			LEFT JOIN [dbo].[vw_DeprNonDeprTangibleAssets] dnd WITH(NOLOCK) ON dnd.DeprNonDeprTangibleAssetsId = IM.AssetDeprNonDeprTangibleAssetsId
			WHERE LSL.LeaseStocklineId = @LeaseStocklineId;

			SET @PurchaseOrderNumber = ''; SET @RepairOrderNumber = ''; SET @VendorName = NULL;
			SELECT @PurchaseOrderNumber = ISNULL(PurchaseOrderNumber, '') FROM dbo.PurchaseOrder WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId;
			SELECT @RepairOrderNumber = ISNULL(RepairOrderNumber, '') FROM dbo.RepairOrder WITH(NOLOCK) WHERE RepairOrderId = @RepairOrderId;
			SELECT @VendorName = VendorName FROM dbo.Vendor WITH(NOLOCK) WHERE VendorId = @VendorId;

			SET @LastMSLevel = NULL; SET @AllMSlevels = NULL;
			SELECT @AllMSlevels = MSF.[AllMSlevels], @LastMSLevel = MSF.[LastMSName] FROM [dbo].[udfGetAllEntityMSLevelString](@ManagementStructureId) MSF;

			IF((@JournalTypeCode ='AST-DEPR') and @IsAccountByPass=0)
			BEGIN
				-- accounting period : the selected one, else the current period of the lease's legal entity
				IF(ISNULL(@SelectedAccountingPeriodId, 0) = 0)
				BEGIN
					SELECT top 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName FROM dbo.EntityStructureSetup est WITH(NOLOCK)
					INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID
					INNER JOIN AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
					WHERE est.EntityStructureId=@ManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  and CAST(getdate() as date)   >= CAST(FROMDate as date) and  CAST(getdate() as date) <= CAST(ToDate as date)
				END
				ELSE
				BEGIN
					SELECT top 1  @AccountingPeriodId=ACC.AccountingCalendarId,@AccountingPeriod=ACC.PeriodName
					FROM AccountingCalendar ACC WITH(NOLOCK)
					WHERE ACC.AccountingCalendarId=@SelectedAccountingPeriodId
				END

				-- journal number + batch header : once per run (first journalled row), the later rows add lines to the same journal
				IF(@JournalBatchDetailId = 0)
				BEGIN
					SELECT @currentNo = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END,
						   @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END, CodePrefix, CodeSufix))
					FROM [dbo].[CodePrefixes] WITH (UPDLOCK, HOLDLOCK)
					WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

					IF(@JournalTypeNumber IS NULL)
					BEGIN
						ROLLBACK TRAN;
						RAISERROR ('Journal number prefix is not set up for Depreciation (CodePrefixes).', 16, 1);
						RETURN(1);
					END
					SET @isNewJENum = 1; SET @isNewJENumRun = 1;
					SET @IsBatchGenerated = 0;

					IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
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

							if(CAST(@Currentbatch AS BIGINT) >99)
								SET @batch = cast(@Currentbatch as varchar(100))
							Else if(CAST(@Currentbatch AS BIGINT) >9)
								SET @batch = CONCAT('0', CAST(@Currentbatch AS VARCHAR(50)))
							else
								SET @batch = CONCAT('00', CAST(@Currentbatch AS VARCHAR(50)))
						END
						SET @CurrentNumber = CAST(@Currentbatch AS BIGINT)
						SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as varchar(100)) as varchar(100))

						INSERT INTO [dbo].[BatchHeader]
							([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
						VALUES
							(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,'ASSETDEP');

						SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
						Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId
					END
					ELSE
					BEGIN
						SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
						if(@CurrentPeriodId =0)
						begin
							Update dbo.BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
						END
						SET @IsBatchGenerated = 1;
					END
				END

				SET @Desc = LEFT('Inventory Num -' + ISNULL(@LeaseNumber, '') + '  PN-' + ISNULL(@MPNName, '') + '  SL-' + ISNULL(@StocklineNumber, ''), 100)
				SET @Amount = ISNULL(@DepreciationAmount,0);

				------Depreciation Expense -----------

				SET @GlAccountId = NULL;
				SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType=CRDRType,@IsAutoPost = ISNULL(IsAutoPost,0), @IsBypassAccounting  = ISNULL(IsBypassAccounting,0),
							 @GlAccountId = GlAccountId
				FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('DEPRECIATIONEXPENSEDEP')
				AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

				SET @GlAccountId = ISNULL(@DeprExpenseGLAccountId, NULLIF(@GlAccountId, 0));
				IF(@GlAccountId IS NULL)
				BEGIN
					ROLLBACK TRAN;
					RAISERROR ('Depreciation Expense GL account is not set (Item Master Asset setup or Distribution Setup - Asset Periodic Depreciation).', 16, 1);
					RETURN(1);
				END
				SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName FROM dbo.GLAccount WITH(NOLOCK) WHERE GLAccountId=@GlAccountId;

				IF(@IsBypassAccounting = 0)
				BEGIN
					IF(@JournalBatchDetailId = 0)
					BEGIN
						INSERT INTO [dbo].[BatchDetails]
							(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
							[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
							[ManagementStructureId],[ModuleName],
							LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted], [AccountingPeriodId], [AccountingPeriod])
						VALUES
							(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
							@JournalTypeId ,@JournalTypename ,1,0,0,
							@ManagementStructureId ,@ModuleName,
							@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)

						SET @JournalBatchDetailId=SCOPE_IDENTITY()
					END

					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],
						[ReferenceNumber],[ReferenceName],[LocalCurrency],[ReferenceId],[ReferenceModule])
					VALUES
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,
						@LeaseNumber,@CustomerName,@CurrencyCode,@LeaseHeaderId,'LEASE')

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----
					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1;

					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@PurchaseOrderPartRecordId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeStock,@CommonJournalBatchDetailId)

					INSERT INTO [dbo].[LeaseBatchDetails]
						([JournalBatchDetailId],[JournalBatchHeaderId],[CommonJournalBatchDetailId],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],
						 [LeaseHeaderId],[LeaseNumber],[LeaseStocklineId],[StocklineId],[StocklineNumber],[DocumentId],[DocumentNumber],[LineType],[MasterCompanyId],[CreatedBy])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@CommonJournalBatchDetailId,@CustomerId,@CustomerName,@ItemMasterId,@ItemMasterId,@MPNName,
						 @LeaseHeaderId,@LeaseNumber,@LeaseStocklineId,@StocklineId,@StocklineNumber,@SelectedAccountingPeriodId,@AccountingPeriod,'Depreciation Expense',@MasterCompanyId,@UpdateBy)
				END

				------Accumulated Depreciation -----------

				SET @GlAccountId = NULL;
				SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType=CRDRType, @IsBypassAccounting  = ISNULL(IsBypassAccounting,0), @GlAccountId = GlAccountId
				FROM dbo.DistributionSetup WITH(NOLOCK)
				WHERE UPPER(DistributionSetupCode) =UPPER('ACCUMULATEDDEPRECIATIONDEP') AND
				DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

				SET @GlAccountId = ISNULL(@AdDepsGLAccountId, NULLIF(@GlAccountId, 0));
				IF(@GlAccountId IS NULL)
				BEGIN
					ROLLBACK TRAN;
					RAISERROR ('Accumulated Depreciation GL account is not set (Item Master Asset setup or Distribution Setup - Asset Periodic Depreciation).', 16, 1);
					RETURN(1);
				END
				SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName FROM DBO.GLAccount WITH(NOLOCK) WHERE GLAccountId=@GlAccountId

				IF(@IsBypassAccounting = 0)
				BEGIN
					IF(@JournalBatchDetailId = 0)
					BEGIN
						-- the Depreciation Expense row is bypassed: the journal header is created with this line
						INSERT INTO [dbo].[BatchDetails]
							(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
							[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
							[ManagementStructureId],[ModuleName],
							LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted], [AccountingPeriodId], [AccountingPeriod])
						VALUES
							(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
							@JournalTypeId ,@JournalTypename ,0,0,0,
							@ManagementStructureId ,@ModuleName,
							@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)

						SET @JournalBatchDetailId=SCOPE_IDENTITY()
					END

					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],
						[ReferenceNumber],[ReferenceName],[LocalCurrency],[ReferenceId],[ReferenceModule])
					VALUES
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						0,0,@Amount,
						@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,
						@LeaseNumber,@CustomerName,@CurrencyCode,@LeaseHeaderId,'LEASE')

					SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----
					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1;

					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@PurchaseOrderPartRecordId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeStock,@CommonJournalBatchDetailId)

					INSERT INTO [dbo].[LeaseBatchDetails]
						([JournalBatchDetailId],[JournalBatchHeaderId],[CommonJournalBatchDetailId],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],
						 [LeaseHeaderId],[LeaseNumber],[LeaseStocklineId],[StocklineId],[StocklineNumber],[DocumentId],[DocumentNumber],[LineType],[MasterCompanyId],[CreatedBy])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@CommonJournalBatchDetailId,@CustomerId,@CustomerName,@ItemMasterId,@ItemMasterId,@MPNName,
						 @LeaseHeaderId,@LeaseNumber,@LeaseStocklineId,@StocklineId,@StocklineNumber,@SelectedAccountingPeriodId,@AccountingPeriod,'Accumulated Depreciation',@MasterCompanyId,@UpdateBy)
				END

				IF(@JournalBatchDetailId > 0)
				BEGIN
					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
					Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchDetailId=@JournalBatchDetailId

					EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId

					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
					SET @TotalBalance =@TotalDebit-@TotalCredit
					Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId

					SET @RunJournalBatchDetailId = @JournalBatchDetailId;
					SET @RunAutoPost = @IsAutoPost;
				END
			END

			SET @StartCount += 1;

		END

		-- journal number sequence + auto-post once for the whole run (the Asset process does it per row; the result is the same batch)
		IF(@isNewJENumRun = 1 OR @currentNo > 0)
		BEGIN
			IF(@JournalTypeNumber IS NOT NULL AND @RunJournalBatchDetailId > 0)
				UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
		END

		IF(@RunAutoPost = 1 AND @RunJournalBatchDetailId > 0 AND @IsBatchGenerated = 0)
		BEGIN
			EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
		END
		IF(@RunAutoPost = 1 AND @RunJournalBatchDetailId > 0 AND @IsBatchGenerated = 1)
		BEGIN
			-- USP_UpdateCommonBatchStatus also returns a diagnostic result set; it is swallowed so the caller gets no unexpected result
			IF OBJECT_ID(N'tempdb..#LeaseAcctCalSink') IS NOT NULL DROP TABLE #LeaseAcctCalSink;
			SELECT TOP 0 * INTO #LeaseAcctCalSink FROM [dbo].[AccountingCalendar];
			INSERT INTO #LeaseAcctCalSink EXEC [dbo].[USP_UpdateCommonBatchStatus] @RunJournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
			DROP TABLE #LeaseAcctCalSink;
		END

	END
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_CreateBatch_DepreciableLeaseStockline'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@DistributionMasterId, 0) AS VARCHAR(50)) + ''
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