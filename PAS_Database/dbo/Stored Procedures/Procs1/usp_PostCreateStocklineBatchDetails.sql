/*************************************************************             
 ** File:   [usp_PostCreateStocklineBatchDetails]             
 ** Author:   Satish Gohil  
 ** Description: This stored procedure is used to create Batch while Post RRO
 ** Purpose:           
 ** Date:   19/05/2023     
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	2    01/06/2023   Satish Gohil  Modify (convert GETDATE() to GETUTCDATE())
	3    24/07/2023   Satish Gohil  Modify(Formatted and set name to distribution code in condition and dynamic cr/dr set)
	3    11/08/2023   Satish Gohil  Modify(Set stock type wise distribution entry)
	4    18/08/2023   Moin Bloch    Modify(Added Accounting MS Entry)
	5    23/11/2023   Moin Bloch    Modify(Added LastMSLevel,AllMSlevels In CommonBatchDetails)
	6    27/11/2023   Moin Bloch    Modify(Added LotId and LotNumber)
	7    14/12/2023   Moin Bloch    Modify(Skip Record If Sockline Exists)
**************************************************************/

CREATE   PROCEDURE [dbo].[usp_PostCreateStocklineBatchDetails]
@tbl_PostStocklineBatchType PostStocklineBatchType READONLY,
@MstCompanyId INT,
@updatedByName VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @StocklineId BIGINT = 0;
		DECLARE @Qty INT = 0;
		DECLARE @Amount DECIMAL(18, 2) = 0;
		DECLARE @ModuleName VARCHAR(256) = 0;
		DECLARE @UpdateBy VARCHAR(256) = 0;
		DECLARE @MasterCompanyId INT = 0;
		DECLARE @StockType VARCHAR(256)= 0;
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @JournalTypeNumber VARCHAR(100);
		DECLARE @JournalBatchDetailId BIGINT=0;
		DECLARE @JlBatchHeaderId BIGINT=0;
		DECLARE @TotalDebit DECIMAL(18, 2) =0;
		DECLARE @TotalCredit DECIMAL(18, 2) =0;
		DECLARE @TotalBalance DECIMAL(18, 2) =0;
		DECLARE @INPUTMethod VARCHAR(100);
		DECLARE @jlTypeId BIGINT;
		DECLARE @jlTypeName VARCHAR(100);
		DECLARE @CrDrType BIGINT
		DECLARE @STKGlAccountId INT;
		DECLARE @STKGlAccountName VARCHAR(200);
		DECLARE @STKGlAccountNumber VARCHAR(200);
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
		DECLARE @ManagementStructureId BIGINT
		DECLARE @LotId BIGINT = 0
		DECLARE @LotNumber VARCHAR(50) 		
		DECLARE @WorkOrderNumber VARCHAR(200) 
		DECLARE @MPNName VARCHAR(200) 
		DECLARE @PiecePNId BIGINT
		DECLARE @PiecePN VARCHAR(200) 
		DECLARE @PieceItemmasterId BIGINT
		DECLARE @CustRefNumber VARCHAR(200)
		DECLARE @LineNumber INT=1
		DECLARE @UnitPrice DECIMAL(18,2)=0
		DECLARE @LaborHrs DECIMAL(18,2)=0
		DECLARE @DirectLaborCost DECIMAL(18,2)=0
		DECLARE @OverheadCost DECIMAL(18,2)=0
		DECLARE @partId BIGINT=0
		DECLARE @batch VARCHAR(100)
		DECLARE @AccountingPeriod VARCHAR(100)
		DECLARE @AccountingPeriodId BIGINT=0
		DECLARE @CurrentPeriodId BIGINT=0
		DECLARE @Currentbatch VARCHAR(100)
		DECLARE @LastMSLevel NVARCHAR(200)
		DECLARE @AllMSlevels NVARCHAR(MAX)
		DECLARE @DistributionSetupId INT=0
		DECLARE @IsAccountByPass bit=0
		DECLARE @DistributionCode VARCHAR(200)
		DECLARE @InvoiceTotalCost DECIMAL(18,2)=0
		DECLARE @MaterialCost DECIMAL(18,2)=0
		DECLARE @LaborOverHeadCost DECIMAL(18,2)=0
		DECLARE @FreightCost DECIMAL(18,2)=0
		DECLARE @SalesTax DECIMAL(18,2)=0
		DECLARE @InvoiceNo VARCHAR(100)
		DECLARE @MiscChargesCost DECIMAL(18,2)=0
		DECLARE @LaborCost DECIMAL(18,2)=0
		DECLARE @InvoiceLaborCost DECIMAL(18,2)=0
		DECLARE @RevenuWO DECIMAL(18,2)=0
		DECLARE @CurrentManagementStructureId BIGINT=0			  
		DECLARE @DistributionMasterId BIGINT;
		DECLARE @VendorId BIGINT;
		DECLARE @VendorName VARCHAR(50);
		DECLARE @ReferenceId BIGINT=NULL;
		DECLARE @ItemMasterId BIGINT=NULL;
		DECLARE @STKMSModuleID BIGINT=2;
		DECLARE @NONStockMSModuleID BIGINT=11;
		DECLARE @AssetMSModuleID BIGINT=42;
		DECLARE @ReferencePartId BIGINT=0;
		DECLARE @ReferencePieceId BIGINT=0;
		DECLARE @PurchaseOrderId BIGINT=0;
		DECLARE @PurchaseOrderNumber VARCHAR(50)='';
		DECLARE @RepairOrderId BIGINT=0;
		DECLARE @RepairOrderNumber VARCHAR(50)='';
		DECLARE @StocklineNumber VARCHAR(50)='';
		DECLARE @SiteId BIGINT;
		DECLARE @Site VARCHAR(100)='';
		DECLARE @WarehouseId BIGINT;
		DECLARE @Warehouse VARCHAR(100)='';
		DECLARE @LocationId BIGINT;
		DECLARE @Location VARCHAR(100)='';
		DECLARE @BinId BIGINT;
		DECLARE @Bin VARCHAR(100)='';
		DECLARE @ShelfId BIGINT;
		DECLARE @Shelf VARCHAR(100)='';
		DECLARE @Desc VARCHAR(100);
		DECLARE @CommonJournalBatchDetailId BIGINT=0;
		DECLARE @AccountMSModuleId INT = 0

		IF OBJECT_ID(N'tempdb..#StocklinePostType') IS NOT NULL    
		BEGIN    
			DROP TABLE #StocklinePostType
		END        
		
		CREATE TABLE #StocklinePostType
		(    
			[StocklineId] [BIGINT] NOT NULL,
			[Qty] [INT] NOT NULL,
			[Amount] [DECIMAL](18, 2) NULL,
			[ModuleName] [VARCHAR](256) NULL,
			[UpdateBy] [VARCHAR](256) NULL,
			[MasterCompanyId] [INT] NULL,
			[StockType] [VARCHAR](256) NULL
		)    
					    
		INSERT INTO #StocklinePostType ([StocklineId],[Qty],[Amount],[ModuleName],[UpdateBy],[MasterCompanyId],[StockType])
		SELECT [StocklineId],[Qty],[Amount],[ModuleName],[UpdateBy],[MasterCompanyId],[StockType] FROM @tbl_PostStocklineBatchType
		
		SELECT @DistributionMasterId =ID FROM DistributionMaster WITH(NOLOCK)  WHERE UPPER(DistributionCode)= UPPER('ReceivingPOStockline')
					  
		SELECT @IsAccountByPass =IsAccountByPass FROM MasterCompany WITH(NOLOCK)  WHERE MasterCompanyId= @MstCompanyId
		SELECT @DistributionCode =DistributionCode FROM DistributionMaster WITH(NOLOCK)  WHERE ID= @DistributionMasterId
		SELECT @StatusId =Id,@StatusName=name FROM BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
		SELECT TOP 1 @JournalTypeId =JournalTypeId FROM DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId
		SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
		SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
		SELECT @CurrentManagementStructureId =ManagementStructureId FROM Employee WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (replace(@updatedByName, ' ', '')) and MasterCompanyId=@MstCompanyId
					  
		SELECT @Amount = SUM(Amount) FROM #StocklinePostType
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
			   		 
		IF(ISNULL(@Amount,0) > 0)
		BEGIN
			IF((@JournalTypeCode ='RPO') and @IsAccountByPass=0)
			BEGIN
				SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName FROM EntityStructureSetup est WITH(NOLOCK) 
				INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
				INNER JOIN AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
				WHERE est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MstCompanyId  and CAST(GETUTCDATE() as date)   >= CAST(FromDate as date) and  CAST(GETUTCDATE() as date) <= CAST(ToDate as date)

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
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MstCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

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

				IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MstCompanyId and CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
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
						(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MstCompanyId,@updatedByName,@updatedByName,GETUTCDATE(),GETUTCDATE(),1,0,'RPO');
            				          
					SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
					SELECT @JlBatchHeaderId = SCOPE_IDENTITY()
					UPDATE BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId
				END
				ELSE
				BEGIN
					SELECT @JlBatchHeaderId=JournalBatchHeaderId,@JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
					SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
						FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc
						
					IF(@CurrentPeriodId =0)
					BEGIN
						Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
					END
				END

				INSERT INTO [dbo].[BatchDetails]
					(JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount],
					[ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[AccountingPeriodId],[AccountingPeriod])
				VALUES
					(@JournalTypeNumber,@currentNo,0, NULL, @JlBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, 0, 0, 0, 'ReceivingPOStockline', NULL, NULL, @MasterCompanyId, @updatedByName, @updatedByName, GETUTCDATE(), GETUTCDATE(), 1, 0,@AccountingPeriodId,@AccountingPeriod)
				
				SET @JournalBatchDetailId=SCOPE_IDENTITY()

				DECLARE @PostStocklineBatchCursor AS CURSOR;
				SET @PostStocklineBatchCursor = CURSOR FOR	

				SELECT [StocklineId],[Qty],[Amount],[ModuleName],[UpdateBy],[MasterCompanyId],[StockType] FROM #StocklinePostType
				OPEN @PostStocklineBatchCursor;
				FETCH NEXT FROM @PostStocklineBatchCursor INTO @StocklineId,@Qty,@Amount,@ModuleName,@UpdateBy,@MasterCompanyId,@StockType;
						
					WHILE @@FETCH_STATUS = 0
					BEGIN
						IF(UPPER(@DistributionCode) = UPPER('ReceivingPOStockline') AND UPPER(@StockType) = 'STOCK')
						BEGIN
						
							SELECT @VendorId=ST.VendorId
							      ,@ReferenceId=ST.StockLineId
								  ,@PurchaseOrderId=ST.PurchaseOrderId
								  ,@RepairOrderId=ST.RepairOrderId
								  ,@StocklineNumber=ST.StocklineNumber
								  ,@SiteId=ST.[SiteId]
								  ,@Site=ST.[Site]
								  ,@WarehouseId=ST.[WarehouseId]
								  ,@Warehouse=ST.[Warehouse]
								  ,@LocationId=ST.[LocationId]
								  ,@Location=ST.[Location]
								  ,@BinId=ST.[BinId]
								  ,@Bin=ST.[Bin]
								  ,@ShelfId=ST.[ShelfId]
								  ,@Shelf=ST.[Shelf]
								  ,@PieceItemmasterId=ST.ItemMasterId
								  ,@WorkOrderNumber=ST.StockLineNumber
								  ,@partId=ST.PurchaseOrderPartRecordId
								  ,@ItemMasterId=ST.ItemMasterId
								  ,@ManagementStructureId= ST.ManagementStructureId 
								  ,@LotId = ST.LotId
								  ,@LotNumber = LO.LotNumber
							FROM [dbo].[Stockline] ST WITH(NOLOCK) 
							     LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK) ON ST.[LotId] = LO.[LotId]
							WHERE ST.[StockLineId] = @StocklineId;

							IF NOT EXISTS(SELECT 1 FROM [dbo].[StocklineBatchDetails] SLBD WITH(NOLOCK) WHERE SLBD.[PoId] = @PurchaseOrderId AND SLBD.[StocklineId] = @StocklineId)
							BEGIN

							SELECT @VendorName = VendorName FROM Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;

							SELECT @PurchaseOrderNumber=PurchaseOrderNumber FROM PurchaseOrder WITH(NOLOCK)  WHERE PurchaseOrderId= @PurchaseOrderId;
							
							SELECT @RepairOrderNumber=RepairOrderNumber FROM RepairOrder WITH(NOLOCK)  WHERE RepairOrderId= @RepairOrderId;

							SET @UnitPrice = @Amount;
							SET @Amount = (@Qty * @Amount);

							--SELECT @WorkOrderNumber=StockLineNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=ItemMasterId,
							--@ManagementStructureId=ManagementStructureId 
							--FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId;

							SELECT @MPNName = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId 
							
							--SELECT TOP 1 @LastMSLevel=[LastMSLevel],@AllMSlevels=[AllMSlevels] 
							--FROM dbo.StocklineManagementStructureDetails WITH(NOLOCK)  
							--WHERE ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID

							SELECT @LastMSLevel = (SELECT LastMSName  FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
							SELECT @AllMSlevels = (SELECT AllMSlevels  FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))

							Set @ReferencePartId =@partId	

							--SELECT @PieceItemmasterId=ItemMasterId FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId


							SELECT @PiecePN = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 
							SET @Desc = 'Receiving PO-' + @PurchaseOrderNumber + '  PN-' + @MPNName + '  SL-' + @StocklineNumber
							
							SELECT TOP 1 @DistributionSetupId=ID,
							             @DistributionName=Name,
										 @JournalTypeId =JournalTypeId,
										 @GlAccountId=GlAccountId,
							             @GlAccountNumber=GlAccountNumber,
										 @GlAccountName=GlAccountName,
										 @CrDrType =CRDRType 
							        FROM dbo.DistributionSetup WITH(NOLOCK)  
									WHERE UPPER(DistributionSetupCode) =UPPER('RPOSTKINV') 
							        AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId =@MasterCompanyId

							SELECT TOP 1 @STKGlAccountId=SL.GLAccountId,@STKGlAccountNumber=GL.AccountCode,@STKGlAccountName=GL.AccountName FROM DBO.Stockline SL WITH(NOLOCK)
							INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId WHERE SL.StockLineId=@StocklineId

							IF(ISNULL(@Amount,0) > 0)
							BEGIN
								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@STKGlAccountId ,@STKGlAccountNumber ,@STKGlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
									@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

								INSERT INTO [StocklineBatchDetails]
									(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
									[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
									@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)

								-----Goods Received Not Invoiced (GRNI)--------
								SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,
								@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType 
								FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('RPOGRNI')
								AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId =@MasterCompanyId

								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
									@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

								INSERT INTO [StocklineBatchDetails]
									(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
									[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
									@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)

								-----Goods Received Not Invoiced (GRNI)--------
								EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
							END

							END

						END
							
						IF(UPPER(@DistributionCode) = UPPER('ReceivingPOStockline') AND UPPER(@StockType) = 'NONSTOCK')
						BEGIN
							SELECT @VendorId=VendorId,@ReferenceId=NonStockInventoryId,@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=NonStockInventoryNumber
							,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf]
							FROM NonStockInventory WITH(NOLOCK) WHERE NonStockInventoryId=@StocklineId;
							SELECT @VendorName =VendorName FROM Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;
							SELECT @PurchaseOrderNumber=PurchaseOrderNumber FROM PurchaseOrder WITH(NOLOCK)  WHERE PurchaseOrderId= @PurchaseOrderId;
							SELECT @RepairOrderNumber=RepairOrderNumber FROM RepairOrder WITH(NOLOCK)  WHERE RepairOrderId= @RepairOrderId;
								
							SET @UnitPrice = @Amount;
							SET @Amount = (@Qty * @Amount);

							SELECT @WorkOrderNumber=NonStockInventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId FROM NonStockInventory WITH(NOLOCK) WHERE NonStockInventoryId=@StocklineId;
							SELECT @MPNName = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId 
							
							--SELECT TOP 1 @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels FROM dbo.NonStocklineManagementStructureDetails WITH(NOLOCK) WHERE ReferenceID=@StockLineId AND ModuleID=@NONStockMSModuleID
							SELECT @LastMSLevel = (SELECT LastMSName  FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
							SELECT @AllMSlevels = (SELECT AllMSlevels  FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))

							SET @ReferencePartId=@partId	


							SELECT @PieceItemmasterId=MasterPartId FROM NonStockInventory WITH(NOLOCK) WHERE NonStockInventoryId=@StocklineId
							SELECT @PiecePN = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 
							SET @Desc = 'Receiving PO-' + @PurchaseOrderNumber + '  PN-' + @MPNName + '  SL-' + @StocklineNumber
							
							-----NonStock - Inventory--------
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,
							@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType 
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('RPONONSTKINV')
							AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId =@MasterCompanyId


							SELECT TOP 1 @STKGlAccountId=SL.GLAccountId,@STKGlAccountNumber=GL.AccountCode,@STKGlAccountName=GL.AccountName FROM DBO.NonStockInventory SL WITH(NOLOCK)
							INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId WHERE SL.NonStockInventoryId=@StocklineId

							IF(ISNULL(@Amount,0) > 0)
							BEGIN
								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@STKGlAccountId ,@STKGlAccountNumber ,@STKGlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
									@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

								INSERT INTO [StocklineBatchDetails]
									(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
									[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
									@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)

								-----Goods Received Not Invoiced (GRNI)--------
								SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,
								@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType  
								FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('RPOGRNI') AND 
								DistributionMasterId=@DistributionMasterId AND MasterCompanyId =@MasterCompanyId

								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
									@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

								INSERT INTO [StocklineBatchDetails]
									(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
									[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
									@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)


								-----Goods Received Not Invoiced (GRNI)--------
								EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
							END
						END
							
						IF(UPPER(@DistributionCode) = UPPER('ReceivingPOStockline') AND UPPER(@StockType) = 'ASSET')
						BEGIN
							SELECT @ReferenceId=AssetInventoryId,@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber
							,@SiteId=[SiteId],@Site=[SiteName],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[BinName],@ShelfId=[ShelfId],@Shelf=[ShelfName]
							FROM AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId;
							SELECT @PurchaseOrderNumber=PurchaseOrderNumber,@VendorId=VendorId FROM PurchaseOrder WITH(NOLOCK)  WHERE PurchaseOrderId= @PurchaseOrderId;
							SELECT @VendorName =VendorName FROM Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;

							SET @UnitPrice = @Amount;
							SET @Amount = (@Qty * @Amount);

							SELECT @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId FROM AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId;
							SELECT @MPNName = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId 
							--SELECT TOP 1 @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels FROM dbo.AssetManagementStructureDetails WITH(NOLOCK) WHERE ReferenceID=@StockLineId AND ModuleID=@AssetMSModuleID
							SELECT @LastMSLevel = (SELECT LastMSName  FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
							SELECT @AllMSlevels = (SELECT AllMSlevels  FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))

							Set @ReferencePartId=@partId	

							SELECT @PieceItemmasterId=MasterPartId FROM AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId
							SELECT @PiecePN = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 
							
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType=CRDRType 
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('RPOASSETINV') AND
							DistributionMasterId=@DistributionMasterId AND MasterCompanyId =@MasterCompanyId

							SELECT TOP 1 @GlAccountId=SL.AcquiredGLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName 
							FROM DBO.AssetInventory SL WITH(NOLOCK)
							INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.AcquiredGLAccountId=GL.GLAccountId 
							WHERE AssetInventoryId=@StocklineId;

							IF(ISNULL(@Amount,0) > 0)
							BEGIN
								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

								SET @Desc = 'Receiving PO-' + @PurchaseOrderNumber + '  PN-' + @MPNName + '  SL-' + @StocklineNumber

								INSERT INTO [StocklineBatchDetails]
									(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
									[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
									@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)

								-----Goods Received Not Invoiced (GRNI)--------
								SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,
								@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType 
								FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('RPOGRNI') 
								AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId =@MasterCompanyId

								INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
									[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
									CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
									@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

								SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

								-----  Accounting MS Entry  -----

								EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

								INSERT INTO [StocklineBatchDetails]
									(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
									[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
								VALUES
									(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
									@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)

								EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
								-----Goods Received Not Invoiced (GRNI)--------
							END
						END
						
						SET @TotalDebit=0;
						SET @TotalCredit=0;
						SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
						Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

						FETCH NEXT FROM @PostStocklineBatchCursor INTO @StocklineId,@Qty,@Amount,@ModuleName,@UpdateBy,@MasterCompanyId,@StockType;
					END
				
				CLOSE @PostStocklineBatchCursor
				DEALLOCATE @PostStocklineBatchCursor
			END

			SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JlBatchHeaderId and IsDeleted=0 --group by JournalBatchHeaderId
			   	          
			SET @TotalBalance =@TotalDebit-@TotalCredit
			UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MstCompanyId    
			Update BatchHeader  SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@updatedByName WHERE JournalBatchHeaderId= @JlBatchHeaderId

		END
		IF OBJECT_ID(N'tempdb..#StocklinePostType') IS NOT NULL
		BEGIN
			DROP TABLE #StocklinePostType
		END
	END
	COMMIT  TRANSACTION
	END TRY
	BEGIN CATCH  
		IF @@trancount > 0
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