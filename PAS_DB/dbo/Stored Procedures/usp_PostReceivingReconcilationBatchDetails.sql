/*************************************************************             
 ** File:   [usp_PostReceivingReconcilationBatchDetails]             
 ** Author:   
 ** Description: This stored procedure is used to Posting Reconsilation to Batch
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    30/05/2023   Satish Gohil  Modify (Gl Account Id Nullable Error fixed)
	2    05/06/2023   Satish Gohil  Modify (Add amount > 0 condition while insert record in commonbatchdetails table)
	3    14/08/2023	  Satish Gohil  Modify (Formatted and Change batch entry value)
	4    18/08/2023   Moin Bloch    Modify(Added Accounting MS Entry)
	5    08/09/2023   Moin Bloch    Modify(Added InvoicedQty Insted OF ReceivedQty)

**************************************************************/  
CREATE   PROCEDURE [dbo].[usp_PostReceivingReconcilationBatchDetails]
@tbl_PostRRBatchType PostRRBatchType READONLY,
@MasterCompanyId int
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			DECLARE @StocklineId bigint = 0;
			DECLARE @InvoicedQty int = 0;
			DECLARE @InvoicedUnitCost decimal(18, 2) = 0;
			DECLARE @JournalTypeName varchar(256) = 0;
			DECLARE @CreatedBy varchar(256) = 0;
			DECLARE @Module varchar(256) = 0;
			DECLARE @JournalBatchHeaderId bigint = 0;
			DECLARE @StockType varchar(256)	 = 0;
			DECLARE @Packagingid int = 0;
			DECLARE @EmployeeId BIGINT
			DECLARE @id bigint = 0;
			DECLARE @ReceivingReconciliationDetailId bigint = 0;

			DECLARE @currentNo AS BIGINT = 0;
			DECLARE @CodeTypeId AS BIGINT = 74;
			DECLARE @JournalTypeNumber varchar(100);
			DECLARE @JournalBatchDetailId BIGINT=0;
			DECLARE @UpdateBy varchar(100);
			DECLARE @JlBatchHeaderId bigint=0;
			DECLARE @TotalDebit decimal(18, 2) =0;
			DECLARE @TotalCredit decimal(18, 2) =0;
			DECLARE @TotalBalance decimal(18, 2) =0;
			DECLARE @INPUTMethod varchar(100);
			DECLARE @jlTypeId BIGINT;
			DECLARE @jlTypeName varchar(100);
			DECLARE @TotalAmt DECIMAL(18,2);
			DECLARE @batch VARCHAR(100)
			DECLARE @AccountingPeriod VARCHAR(100)
			DECLARE @AccountingPeriodId BIGINT=0
			DECLARE @CurrentManagementStructureId BIGINT=0		
			DECLARE @DistributionMasterId BIGINT;
			DECLARE @IsAccountByPass bit=0
			DECLARE @DistributionCode VARCHAR(200)
			DECLARE @StatusId INT
			DECLARE @StatusName VARCHAR(200)
			DECLARE @JournalTypeId INT
			DECLARE @JournalTypeCode VARCHAR(200) 
			DECLARE @Currentbatch varchar(100);  
			DECLARE @CurrentNumber int;
			DECLARE @CurrentPeriodId bigint=0;  
		    DECLARE @LineNumber int=1; 
			DECLARE @DisCode varchar(100);
			DECLARE @ReceivingReconciliationId BIGINT = 0
			DECLARE @updatedByName VARCHAR(100)
			DECLARE @AccountMSModuleId INT = 0

			IF OBJECT_ID(N'tempdb..#RRPostType') IS NOT NULL    
			BEGIN    
				DROP TABLE #RRPostType  
			END        
			CREATE TABLE #RRPostType  
			(    
				[StocklineId] [bigint] NOT NULL,
				[InvoicedQty] [int] NULL,
				[InvoicedUnitCost] [decimal](18, 2) NULL,
				[JournalTypeName] [varchar](256) NULL,
				[CreatedBy] [varchar](256) NULL,
				[Module] [varchar](256) NULL,
				[JournalBatchHeaderId] [bigint] NULL,
				[StockType] [varchar](256) NULL,
				[Packagingid] [int] NULL,
				[EmployeeId] [bigint] NOT NULL,
				[id] [bigint] NOT NULL,
				[ReceivingReconciliationDetailId] [bigint] NOT NULL
			) 

			INSERT INTO #RRPostType ([StocklineId],[InvoicedQty],[InvoicedUnitCost],[JournalTypeName],[CreatedBy],[Module],[JournalBatchHeaderId],[StockType],
				[Packagingid],[EmployeeId],[id],[ReceivingReconciliationDetailId])    
			SELECT [StocklineId],[InvoicedQty],[InvoicedUnitCost],[JournalTypeName],[CreatedBy],[Module],[JournalBatchHeaderId],[StockType],
				[Packagingid],[EmployeeId],[id],[ReceivingReconciliationDetailId] FROM @tbl_PostRRBatchType

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
				StartsFROM BIGINT NULL,
			)

			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFROM) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFROM 
			FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
			BEGIN 
				SELECT 
					@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
						ELSE CAST(StartsFROM AS BIGINT) + 1 END 
				FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  
				SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes 
				WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN
				ROLLBACK TRAN;
			END

			SET @JlBatchHeaderId = (SELECT TOP 1 JournalBatchHeaderId FROM @tbl_PostRRBatchType)
		--	SET @UpdateBy = (SELECT TOP 1 CreatedBy FROM @tbl_PostRRBatchType)
			--SET @INPUTMethod = (SELECT TOP 1 Module FROM @tbl_PostRRBatchType)
			--SET @jlTypeId = (SELECT TOP 1 JournalTypeId  FROM dbo.BatchHeader WITH(NOLOCK) WHERE JournalBatchHeaderId = @JlBatchHeaderId)
			--SET @jlTypeName = (SELECT TOP 1 JournalTypeName  FROM dbo.BatchHeader WITH(NOLOCK) WHERE JournalBatchHeaderId = @JlBatchHeaderId)

			SELECT @TotalAmt = SUM(ISNULL(InvoicedQty,0)) * SUM(ISNULL(InvoicedUnitCost,0)) FROM #RRPostType

			SELECT TOP 1 @ReceivingReconciliationId = [id],@EmployeeId = EmployeeId FROM #RRPostType

			SELECT @CurrentManagementStructureId =ManagementStructureId, @UpdateBy = CONCAT(TRIM(FirstName),' ',TRIM(LastName)) FROM Employee 
			WITH(NOLOCK)  WHERE EmployeeId = @EmployeeId and MasterCompanyId=@MasterCompanyId

			SET @DisCode = (select top 1 CASE WHEN [Type] =1 THEN 'ReconciliationPO'  
				WHEN [Type] = 2 THEN 'ReconciliationRO' ELSE '' END  
			FROM DBO.ReceivingReconciliationDetails WITH(NOLOCK) WHERE ReceivingReconciliationId = @ReceivingReconciliationId) 

			SELECT @DistributionMasterId =ID FROM DistributionMaster WITH(NOLOCK)  
			WHERE UPPER(DistributionCode)= UPPER(@DisCode)

			SET @INPUTMethod = @DisCode
			
			SELECT @IsAccountByPass = IsAccountByPass FROM MasterCompany WITH(NOLOCK)  WHERE MasterCompanyId= @MasterCompanyId
			SELECT @DistributionCode =DistributionCode FROM DistributionMaster WITH(NOLOCK)  WHERE ID= @DistributionMasterId
			SELECT @StatusId =Id,@StatusName=name FROM BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
			SELECT TOP 1 @JournalTypeId =JournalTypeId,@jlTypeId = JournalTypeId FROM DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId
			SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
			SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName,@jlTypeName = JournalTypeName FROM JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
			SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

			IF(ISNULL(@TotalAmt,0) > 0 AND @IsAccountByPass = 0 AND (@DisCode = 'ReconciliationPO' OR @DisCode = 'ReconciliationRO'))
			BEGIN
			
				SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName FROM EntityStructureSetup est WITH(NOLOCK) 
				INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
				INNER JOIN AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
				WHERE est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  and CAST(GETUTCDATE() as date)   >= CAST(FromDate as date) and  CAST(GETUTCDATE() as date) <= CAST(ToDate as date)

				IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId AND IsDeleted =0)
				BEGIN
					IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
					BEGIN
						SET @batch ='001'
						SET @Currentbatch='001'
					END
					ELSE
					BEGIN
						SELECT TOP 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
								ELSE  1 END 
						FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
					SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as VARCHAR(100)) as VARCHAR(100))

					INSERT INTO [dbo].[BatchHeader]
						([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
					VALUES
						(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@JournalTypeCode);
            				          
					SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
					SELECT @JlBatchHeaderId = SCOPE_IDENTITY()
					UPDATE BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId
				END
				ELSE
				BEGIN
					SELECT @JlBatchHeaderId=JournalBatchHeaderId,@JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK) 
					WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
					SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
						FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc
						
					IF(@CurrentPeriodId =0)
					BEGIN
						Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
					END
				END

				UPDATE #RRPostType SET 
				[JournalTypeName] = @JournalTypename,
				[CreatedBy] = @UpdateBy,
				[Module] = CASE WHEN @DisCode = 'ReconciliationPO' THEN 'ReconciliationPO' ELSE 'ReconciliationRO' END,
				[JournalBatchHeaderId] = @JournalBatchHeaderId
				
				PRINT @UpdateBy

				DECLARE @PostRRBatchCursor AS CURSOR;
				SET @PostRRBatchCursor = CURSOR FOR	

				SELECT [StocklineId],[InvoicedQty],[InvoicedUnitCost],[JournalTypeName],[CreatedBy],[Module],[JournalBatchHeaderId],[StockType],
					[Packagingid],[EmployeeId],[id],[ReceivingReconciliationDetailId] FROM #RRPostType

				OPEN @PostRRBatchCursor;
				FETCH NEXT FROM @PostRRBatchCursor INTO @StocklineId,@InvoicedQty,@InvoicedUnitCost,@JournalTypeName,@CreatedBy,@Module,@JournalBatchHeaderId,@StockType,@Packagingid,@EmployeeId,@id,@ReceivingReconciliationDetailId;
					WHILE @@FETCH_STATUS = 0
					BEGIN
						DECLARE @PieceItemmasterId bigint=0;
						DECLARE @PiecePNId bigint=0;
						DECLARE @PiecePN varchar(200);
						DECLARE @DistributionSetupId int=0;
						DECLARE @Distributionname varchar(200);
						DECLARE @GlAccountId int;
						DECLARE @GlAccountNumber varchar(200);
						DECLARE @GlAccountName varchar(200);
						DECLARE @WorkOrderNumber varchar(200);
						DECLARE @partId bigint=0;
						DECLARE @ItemMasterId bigint=NULL;
						DECLARE @ManagementStructureId bigint;
						DECLARE @LastMSLevel varchar(200);
						DECLARE @AllMSlevels varchar(max);
						DECLARE @PurchaseOrderId BIGINT=0;
						DECLARE @PurchaseOrderNumber varchar(50) ='';
						DECLARE @RepairOrderId BIGINT=0;
						DECLARE @RepairOrderNumber varchar(50) ='';
						DECLARE @StocklineNumber varchar(50) ='';
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
						DECLARE @VendorName varchar(50);
						DECLARE @STKMSModuleID bigint=2;
						DECLARE @EMPMSModuleID bigint=47;
						DECLARE @ReceivedQty BIGINT=0;
						DECLARE @StocklineQtyOH BIGINT=0;
						DECLARE @StocklineQtyAvail BIGINT=0;
						DECLARE @StocklineQtyreserved BIGINT=0;
						DECLARE @POStocklineUnitPrice decimal(18, 2) =0;
						DECLARE @ROStocklineUnitPrice decimal(18, 2) =0;
						DECLARE @StocklineUnitPrice decimal(18, 2) =0;
						DECLARE @POROUnitPrice decimal(18, 2) =0;
						DECLARE @RRUnitPrice decimal(18, 2) =0;
						DECLARE @APTotalPrice decimal(18, 2) =0;
						DECLARE @Amount decimal(18,2) =0;
						DECLARE @Qty int=0;
						DECLARE @RRId bigint=0;
						DECLARE @CommonJournalBatchDetailId bigint=0;
						DECLARE @ModuleName varchar(256);
						DECLARE @CrDrType BIGINT

						SELECT @POROUnitPrice=ISNULL(POUnitCost, 0), @ReceivedQty=ISNULL(InvoicedQty, 0), @RRUnitPrice=ISNULL(InvoicedUnitCost, 0)
						FROM dbo.ReceivingReconciliationDetails WITH(NOLOCK)
						WHERE ReceivingReconciliationDetailId=@ReceivingReconciliationDetailId

						SET @Amount = @InvoicedUnitCost;
						SET @Qty = @InvoicedQty;
						SET @RRId = @id;
						SET @ModuleName = @Module;

						IF(UPPER(@ModuleName)=UPPER('ReconciliationPO'))
						BEGIN
							INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate],
								[EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
							VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JlBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), @jlTypeId, @jlTypeName, 1, 0, 0, 0, @INPUTMethod,
								@JournalTypeId ,@JournalTypename, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)

							SET @JournalBatchDetailId=SCOPE_IDENTITY()

							SELECT @DistributionMasterId =ID,@DistributionCode =DistributionCode from dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('ReconciliationPO');
							IF(UPPER(@StockType) = 'STOCK')
							BEGIN
								SELECT @WorkOrderNumber=StockLineNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=ItemMasterId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
										@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=StocklineNumber,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse]
										,@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
										@VendorId=VendorId,@POStocklineUnitPrice=ISNULL(PurchaseOrderUnitCost,0),@ROStocklineUnitPrice=ISNULL(RepairOrderUnitCost,0),@StocklineQtyAvail=ISNULL(QuantityAvailable,0)
								FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId;
												  
								SELECT @PieceItemmasterId=ItemMasterId FROM dbo.Stockline WITH(NOLOCK)  WHERE StockLineId=@StocklineId
							END
							IF(UPPER(@StockType) = 'NONSTOCK')
							BEGIN
								SELECT @WorkOrderNumber=NonStockInventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
										@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=NonStockInventoryNumber,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],
										@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
										@VendorId=VendorId,@POStocklineUnitPrice=ISNULL(UnitCost,0),@ROStocklineUnitPrice=ISNULL(UnitCost,0),@StocklineQtyAvail=QuantityOnHand 
								FROM dbo.NonStockInventory WITH(NOLOCK) WHERE NonStockInventoryId=@StocklineId;
												  
								SELECT @PieceItemmasterId=MasterPartId FROM dbo.NonStockInventory WITH(NOLOCK)  WHERE NonStockInventoryId=@StocklineId

							END

							IF(UPPER(@StockType) = 'ASSET')
							BEGIN
									SELECT @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
									@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber
									,@SiteId=[SiteId],@Site=SiteName,@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=BinName,@ShelfId=[ShelfId],@Shelf=ShelfName,
									@POStocklineUnitPrice=ISNULL(UnitCost,0),@ROStocklineUnitPrice=ISNULL(UnitCost,0),@StocklineQtyAvail=1 FROM AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId;
												  
									SELECT @PurchaseOrderNumber=PurchaseOrderNumber,@VendorId=VendorId FROM dbo.PurchaseOrder WITH(NOLOCK)  WHERE PurchaseOrderId= @PurchaseOrderId;
									SELECT @PieceItemmasterId=MasterPartId FROM dbo.AssetInventory WITH(NOLOCK)  WHERE AssetInventoryId=@StocklineId

							END

							SELECT @MPNName = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId;
							SELECT @VendorName =VendorName FROM dbo.Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;
							SELECT @PurchaseOrderNumber=PurchaseOrderNumber FROM dbo.PurchaseOrder WITH(NOLOCK)  WHERE PurchaseOrderId= @PurchaseOrderId;
							SELECT @PiecePN = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 
													   
							IF(@PackagingId > 0)
							BEGIN
								 SET @Amount=(@Qty * @Amount);
								 SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, 
										@GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName
								 FROM dbo.DistributionSetup WITH(NOLOCK)
								 WHERE UPPER(DistributionSetupCode)=UPPER('RECPOVARCOGS') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

								 SELECT @LastMSLevel=LastMSLevel, @AllMSlevels=AllMSlevels FROM dbo.EmployeeManagementStructureDetails WITH(NOLOCK)
								 WHERE ReferenceID=@EmployeeId AND ModuleID=@EMPMSModuleID;
							
								 SELECT @VendorId=VendorId, @VendorName=VendorName FROM dbo.ReceivingReconciliationHeader WITH(NOLOCK)
								 WHERE ReceivingReconciliationId=@RRId;

								 IF(ISNULL(@Amount,0) > 0)
								 BEGIN
									INSERT INTO [dbo].[CommonBatchDetails]
										(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
										[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
									VALUES
										(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
										1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

									SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

									-----  Accounting MS Entry  -----

									EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

									SET @Desc='Receiving PO-'+@PurchaseOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber

									INSERT INTO dbo.[StocklineBatchDetails]
										(JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
									VALUES
										(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)

								 END
								 IF(ISNULL(@Amount,0) < 0)
								 BEGIN
									INSERT INTO [dbo].[CommonBatchDetails]
										(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
										[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
									VALUES
										(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
										0,0,ABS(@Amount),@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

									SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

									-----  Accounting MS Entry  -----

									EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

									SET @Desc='Receiving PO-'+@PurchaseOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber

									INSERT INTO dbo.[StocklineBatchDetails]
										(JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
									VALUES
										(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)

								 END
							END
							ELSE
							BEGIN
								SELECT @LastMSLevel=LastMSLevel, @AllMSlevels=AllMSlevels FROM dbo.StocklineManagementStructureDetails WITH(NOLOCK)
								WHERE ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID;

								SET @Desc='Receiving PO-'+@PurchaseOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber
								SET @Amount=(ISNULL(@StocklineQtyAvail, 0)* @Amount);

								IF(ISNULL(@StocklineQtyAvail, 0)=ISNULL(@ReceivedQty, 0)and @POROUnitPrice=ISNULL(@RRUnitPrice, 0))
								BEGIN 
									------- Goods Received Not Invoiced (GRNI)-------
									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId,
									@GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType = CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOGRNI') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

										SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, 
											StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '',
											@Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END

									------- Goods Received Not Invoiced (GRNI)-------

									------- Accounts Payable --------

									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, 
									@GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType = CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOACCPAYABLE') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename , 
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)

										SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- Accounts Payable --------

								END
								ELSE IF(ISNULL(@StocklineQtyAvail, 0)=ISNULL(@ReceivedQty, 0)and @POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
								BEGIN
									------- Stock - Inventory -----
									SET @Amount=ISNULL(((@RRUnitPrice-@POROUnitPrice)* ISNULL(@StocklineQtyAvail, 0)), 0);
									SET @APTotalPrice=@APTotalPrice+@Amount

									IF(UPPER(@StockType) = 'STOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0) and ISNULL(@StocklineQtyAvail, 0)>0)
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice+@ROStocklineUnitPrice
											UPDATE dbo.Stockline
											SET PurchaseOrderUnitCost=@RRUnitPrice, UnitCost=@StocklineUnitPrice
											WHERE StockLineId=@StocklineId
										END

										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,@CrDrType= CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECPOSTKINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;

										SELECT TOP 1 @GlAccountId=SL.GLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName FROM DBO.Stockline SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId WHERE SL.StockLineId=@StocklineId
									END

									IF(UPPER(@StockType) = 'NONSTOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE dbo.NonStockInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE NonStockInventoryId=@StocklineId
										END

										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,@CrDrType= CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECPONONSTKINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;

										SELECT TOP 1 @GlAccountId=SL.GLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName FROM DBO.NonStockInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId WHERE SL.NonStockInventoryId=@StocklineId
									END

									IF(UPPER(@StockType) = 'ASSET')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE dbo.AssetInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE AssetInventoryId=@StocklineId
										END
														     
										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,@CrDrType= CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECPOASSETINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;
										
										SELECT TOP 1 @GlAccountId=SL.AcquiredGLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName 
										FROM DBO.AssetInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.AcquiredGLAccountId=GL.GLAccountId 
										WHERE AssetInventoryId=@StocklineId;
									END

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
											,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO [dbo].[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber,
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, 
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END

									------- Stock - Inventory -----

									------- Goods Received Not Invoiced (GRNI)------
									SET @Amount=(@ReceivedQty * @POROUnitPrice);
									SET @APTotalPrice=@APTotalPrice+@Amount

									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId,
									@GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType = CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOGRNI') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
										(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
										[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
										(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
										CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
										CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
										CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
										@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
															 
										SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, 
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, 
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- Goods Received Not Invoiced (GRNI)------

									------- Accounts Payable ------
									SET @Amount=@APTotalPrice;

									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, 
									@GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType= CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOACCPAYABLE') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- Accounts Payable -------
								END
								ELSE IF(ISNULL(@StocklineQtyAvail, 0)!=ISNULL(@ReceivedQty, 0))
								BEGIN
									------- Stock - Inventory ---
									SET @Amount=(@RRUnitPrice-@POROUnitPrice)* ISNULL(@StocklineQtyAvail, 0);
									set @APTotalPrice=@APTotalPrice+@Amount

									IF(UPPER(@StockType) = 'STOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0) and ISNULL(@StocklineQtyAvail, 0)>0)
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice+@ROStocklineUnitPrice
											UPDATE dbo.Stockline
											SET PurchaseOrderUnitCost=@RRUnitPrice, UnitCost=@StocklineUnitPrice
											WHERE StockLineId=@StocklineId
										END

										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECPOSTKINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;

										SELECT TOP 1 @GlAccountId=SL.GLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName FROM DBO.Stockline SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId WHERE SL.StockLineId=@StocklineId

									END
									IF(UPPER(@StockType) = 'NONSTOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE dbo.NonStockInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE NonStockInventoryId=@StocklineId
										END
										
										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,@CrDrType=CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECPONONSTKINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;

										SELECT TOP 1 @GlAccountId=SL.GLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName FROM DBO.NonStockInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId WHERE SL.NonStockInventoryId=@StocklineId
									END
									IF(UPPER(@StockType) = 'ASSET')
									BEGIN

										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE dbo.AssetInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE AssetInventoryId=@StocklineId
										END
														     
										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,@CrDrType = CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECPOASSETINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;
										
										SELECT TOP 1 @GlAccountId=SL.AcquiredGLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName 
										FROM DBO.AssetInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.AcquiredGLAccountId=GL.GLAccountId 
										WHERE AssetInventoryId=@StocklineId;
									END

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber,
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, 
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END

									------- Stock - Inventory -------
									------- VAR - Cost/Qty - COGS ------

									SET @Amount=ISNULL(((@ReceivedQty-ISNULL(@StocklineQtyAvail, 0))*(@RRUnitPrice-@POROUnitPrice)), 0);
									SET @APTotalPrice=@APTotalPrice+@Amount

									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOVARCOGS') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, 
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber,
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END

									IF(ISNULL(@Amount,0) < 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											0,0,ABS(@Amount),@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, 
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber,
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END

									------- VAR - Cost/Qty - COGS -------

									------- Goods Received Not Invoiced (GRNI)-------
									SET @Amount=(@ReceivedQty * @POROUnitPrice);
									SET @APTotalPrice=@APTotalPrice+@Amount

									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,
									@GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType = CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOGRNI') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
															 
										SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, 
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber,
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- Goods Received Not Invoiced (GRNI)-------
									------- Accounts Payable ------
									SET @Amount=@APTotalPrice;
									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, 
									@GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType = CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOACCPAYABLE') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
											,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber,
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, 
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- Accounts Payable ------
								END
							END
							EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId

						END


						ELSE IF(UPPER(@ModuleName)=UPPER('ReconciliationRO'))
						BEGIN
							PRINT @ModuleName
							PRINT @JournalTypeId
							PRINT @JournalTypename

							INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate],
								[EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
							VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JlBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), @jlTypeId, @jlTypeName, 1, 0, 0, 0, @INPUTMethod,
								@JournalTypeId, @JournalTypename, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)

							SET @JournalBatchDetailId=SCOPE_IDENTITY()

							SELECT @DistributionMasterId =ID,@DistributionCode =DistributionCode from dbo.DistributionMaster WITH(NOLOCK)
							where UPPER(DistributionCode)= UPPER('ReconciliationRO');
							IF(UPPER(@StockType) = 'STOCK')
							BEGIN
								SELECT @WorkOrderNumber=StockLineNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=ItemMasterId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
								@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=StocklineNumber
								,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
								@VendorId=VendorId,@StocklineQtyAvail=ISNULL(QuantityAvailable,0),@POStocklineUnitPrice=ISNULL(PurchaseOrderUnitCost,0),@ROStocklineUnitPrice=ISNULL(RepairOrderUnitCost,0)  
								FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId;
															  
								SELECT @PieceItemmasterId=ItemMasterId FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId
							END
							IF(UPPER(@StockType) = 'ASSET')
							BEGIN
								SELECT @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
								@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber
								,@SiteId=[SiteId],@Site=SiteName,@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=BinName,@ShelfId=[ShelfId],@Shelf=ShelfName,
								@POStocklineUnitPrice=ISNULL(UnitCost,0),@ROStocklineUnitPrice=ISNULL(UnitCost,0),@StocklineQtyAvail=1 
								FROM AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId;
															  
								SELECT @RepairOrderNumber=RepairOrderNumber,@VendorId=VendorId FROM dbo.RepairOrder WITH(NOLOCK)  WHERE RepairOrderId= @RepairOrderId;
								SELECT @PieceItemmasterId=MasterPartId  FROM dbo.AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId
							END

							SELECT @MPNName = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId;
							SELECT @VendorName =VendorName FROM dbo.Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;
							SELECT @RepairOrderNumber=RepairOrderNumber FROM dbo.RepairOrder WITH(NOLOCK)  WHERE RepairOrderId= @RepairOrderId;
							SET @Amount = (@Qty * @Amount);

							SELECT @PieceItemmasterId=ItemMasterId FROM dbo.Stockline  WHERE StockLineId=@StocklineId
							SELECT @PiecePN = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 

							IF(@PackagingId>0)
							BEGIN
								SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
								FROM dbo.DistributionSetup WITH(NOLOCK)
								WHERE UPPER(DistributionSetupCode)=UPPER('RECROVARCOGS') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId
							
								SELECT @LastMSLevel=LastMSLevel, @AllMSlevels=AllMSlevels FROM dbo.EmployeeManagementStructureDetails WITH(NOLOCK)
								WHERE ReferenceID=@EmployeeId AND ModuleID=@EMPMSModuleID;
							
								SELECT @VendorId=VendorId, @VendorName=VendorName FROM dbo.ReceivingReconciliationHeader WITH(NOLOCK)
								WHERE ReceivingReconciliationId=@RRId;
								SET @Amount=(@Qty * @Amount);

								IF(ISNULL(@Amount,0) > 0)
								BEGIN
									INSERT INTO [dbo].[CommonBatchDetails]
										(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
										[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
									VALUES
										(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
										1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
														 
									SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

									-----  Accounting MS Entry  -----

									EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

									SET @Desc='Receiving RO-'+@RepairOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber
									INSERT INTO [dbo].[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber,
										Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
									VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber,
										'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
								END
								IF(ISNULL(@Amount,0) < 0)
								BEGIN
									INSERT INTO [dbo].[CommonBatchDetails]
										(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
										[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
									VALUES
										(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
										0,0,ABS(@Amount),@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
														 
									SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

									-----  Accounting MS Entry  -----

									EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

									SET @Desc='Receiving RO-'+@RepairOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber
									INSERT INTO [dbo].[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber,
										Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
									VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber,
										'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
								END
							END
							ELSE
							BEGIN
								PRINT '11'
								SELECT @LastMSLevel=LastMSLevel, @AllMSlevels=AllMSlevels FROM dbo.StocklineManagementStructureDetails WITH(NOLOCK)
								WHERE ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID;

								SET @Desc='Receiving RO-'+@RepairOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber
								SET @Amount=(ISNULL(@StocklineQtyAvail, 0)* @Amount);
								
									PRINT @JournalTypename
									PRINT @DistributionMasterId
									PRINT @MasterCompanyId
								IF(ISNULL(@StocklineQtyAvail, 0)=ISNULL(@ReceivedQty, 0)and @POROUnitPrice=ISNULL(@RRUnitPrice, 0))
								BEGIN
									------- Goods Received Not Invoiced (GRNI)------
									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, 
									@GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType = CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECROGRNI') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId


									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO [dbo].[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, 
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber,
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- Goods Received Not Invoiced (GRNI)------

									------- Accounts Payable -------
									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,
									@GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType=CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECROACCPAYABLE') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId
									SET @Amount=(ISNULL(@StocklineQtyAvail, 0)* @Amount);

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO [dbo].[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, 
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, 
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- Accounts Payable -------

								END
								ELSE IF(ISNULL(@StocklineQtyAvail, 0)=ISNULL(@ReceivedQty, 0)and @POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
								BEGIN
									------- Stock - Inventory ---
									SET @Amount=ISNULL(((@RRUnitPrice-@POROUnitPrice)* ISNULL(@StocklineQtyAvail, 0)), 0);
									SET @APTotalPrice=@APTotalPrice+@Amount
									IF(UPPER(@StockType) = 'STOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0) and ISNULL(@StocklineQtyAvail, 0) >0)
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice+@POStocklineUnitPrice
											UPDATE dbo.Stockline
											SET RepairOrderUnitCost=@RRUnitPrice, UnitCost=@StocklineUnitPrice
											WHERE StockLineId=@StocklineId
										END
										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,@CrDrType=CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECROSTKINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

										SELECT TOP 1 @GlAccountId=SL.GLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName FROM DBO.Stockline SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId WHERE SL.StockLineId=@StocklineId
									END
									IF(UPPER(@StockType) = 'ASSET')
									BEGIN

										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE dbo.AssetInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE AssetInventoryId=@StocklineId
										END
														     
										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,@CrDrType=CRDRType
										FROM DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECROASSETINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

										SELECT TOP 1 @GlAccountId=SL.AcquiredGLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName 
										FROM DBO.AssetInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.AcquiredGLAccountId=GL.GLAccountId 
										WHERE AssetInventoryId=@StocklineId;
									END

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO [dbo].[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, 
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, 
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- Goods Received Not Invoiced (GRNI)-------
									SET @Amount=ISNULL((@ReceivedQty * @POROUnitPrice), 0);
									SET @APTotalPrice=@APTotalPrice+@Amount

									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, 
									@GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType=CRDRType
									FROM DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECROGRNI') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, 
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber,
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- Goods Received Not Invoiced (GRNI)-------
								END
								ELSE IF(ISNULL(@StocklineQtyAvail, 0)!=ISNULL(@ReceivedQty, 0))
								BEGIN
									------- Stock - Inventory -----
									SET @Amount=((@RRUnitPrice-@POROUnitPrice)* ISNULL(@StocklineQtyAvail, 0));
									SET @APTotalPrice=@APTotalPrice+@Amount

									IF(UPPER(@StockType) = 'STOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice+@POStocklineUnitPrice
											UPDATE dbo.Stockline
											SET RepairOrderUnitCost=@RRUnitPrice, UnitCost=@StocklineUnitPrice
											WHERE StockLineId=@StocklineId
										END

										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,@CrDrType=CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECROSTKINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

										SELECT TOP 1 @GlAccountId=SL.GLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName FROM DBO.Stockline SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId WHERE SL.StockLineId=@StocklineId

									END			     
									IF(UPPER(@StockType) = 'ASSET')
									BEGIN

										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE AssetInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE AssetInventoryId=@StocklineId
										END
														     
										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,@CrDrType=CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECROASSETINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

										SELECT TOP 1 @GlAccountId=SL.AcquiredGLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName 
										FROM DBO.AssetInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.AcquiredGLAccountId=GL.GLAccountId 
										WHERE AssetInventoryId=@StocklineId;

									END
									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
											,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, 
										Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, 
										'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END

									------- Stock - Inventory -----

									------- VAR - Cost/Qty - COGS ------
									SET @Amount=((@RRUnitPrice-@POROUnitPrice)*(@ReceivedQty-ISNULL(@StocklineQtyAvail, 0)));
									SET @APTotalPrice=@APTotalPrice+@Amount

									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, 
									@GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType=CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECROVARCOGS') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId
								
									IF(ISNULL(@Amount,0) > 0)
									BEGIN 
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber,
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber,
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									IF(ISNULL(@Amount,0) < 0)
									BEGIN 
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											1,0,ABS(@Amount),@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber,
											Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber,
											'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- VAR - Cost/Qty - COGS ------

									 ------- Goods Received Not Invoiced (GRNI)------
									SET @Amount=ISNULL((@ReceivedQty * @POROUnitPrice), 0);
									SET @APTotalPrice=@APTotalPrice+@Amount

									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,
									@GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType = CRDRType
									FROM DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECROGRNI') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

									IF(ISNULL(@Amount,0) > 0)
									BEGIN 
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
											,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- Goods Received Not Invoiced (GRNI)-----
									------- Accounts Payable ------
									SET @Amount=@APTotalPrice
									SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, 
									@GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName,@CrDrType=CRDRType
									FROM DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECROACCPAYABLE') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

									IF(ISNULL(@Amount,0) > 0)
									BEGIN 
										INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

										INSERT INTO [dbo].[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId])
										VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId)
									END
									------- Accounts Payable ------
								END

							END
							EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
						END
						
						SET @TotalDebit=0;
						SET @TotalCredit=0;
						SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
						
						UPDATE dbo.BatchDetails SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchDetailId=@JournalBatchDetailId
						
						UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
						
						SET @currentNo = @currentNo + 1

						SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes
						WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))

						FETCH NEXT FROM @PostRRBatchCursor INTO @StocklineId,@InvoicedQty,@InvoicedUnitCost,@JournalTypeName,@CreatedBy,@Module,@JournalBatchHeaderId,@StockType,@Packagingid,@EmployeeId,@id,@ReceivingReconciliationDetailId;
					END

					CLOSE @PostRRBatchCursor
					DEALLOCATE @PostRRBatchCursor

				        
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JlBatchHeaderId and IsDeleted=0 --group by JournalBatchHeaderId
			   	          
					SET @TotalBalance =@TotalDebit-@TotalCredit
					
					Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JlBatchHeaderId

					IF OBJECT_ID(N'tempdb..#RRPostType') IS NOT NULL
					BEGIN
						DROP TABLE #RRPostType 
					END
			END
		END 
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_PostCreateStocklineBatchDetails' 
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