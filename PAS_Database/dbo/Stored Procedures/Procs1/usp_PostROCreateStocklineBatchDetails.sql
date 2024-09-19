/*************************************************************             
 ** File:   [usp_PostROCreateStocklineBatchDetails]             
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
	3    20/07/2023   Hemant Saliya Formated SP and Added MasterCompany Condition
	4    24/07/2023	  Satish Gohil  Modify(Set condition name to distribution code and dynamic setup)
	5    11/08/2023   Satish Gohil  Modify(Set stock type wise distribution entry)
	6    18/08/2023   Moin Bloch    Modify(Added Accounting MS Entry)
	7    27/11/2023   Moin Bloch    Modify(Added LotId and LotNumber)
	8    02/20/2024	  HEMANT SALIYA	Updated for Restrict Accounting Entry by Master Company
	9    07/24/2024	  AMIT GHEDIYA	Updated new Destribution.
	10   19/09/2024	  AMIT GHEDIYA   Added for AutoPost Batch
**************************************************************/  
CREATE   PROCEDURE [dbo].[usp_PostROCreateStocklineBatchDetails]
@tbl_PostStocklineBatchType PostStocklineBatchType READONLY,
@MstCompanyId int,
@updatedByName varchar(256)
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
				BEGIN TRANSACTION
				BEGIN
					DECLARE @StocklineId bigint = 0;
					DECLARE @Qty int = 0;
					DECLARE @Amount decimal(18, 2) = 0;
					DECLARE @ModuleName varchar(256) = 0;
					DECLARE @UpdateBy varchar(256) = 0;
					DECLARE @MasterCompanyId int = 0;
					DECLARE @StockType varchar(256)= 0;

					DECLARE @currentNo AS BIGINT = 0;
					DECLARE @CodeTypeId AS BIGINT = 74;
					DECLARE @JournalTypeNumber varchar(100);
					DECLARE @JournalBatchDetailId BIGINT=0;
					DECLARE @JlBatchHeaderId bigint=0;
					DECLARE @TotalDebit decimal(18, 2) =0;
					DECLARE @TotalCredit decimal(18, 2) =0;
					DECLARE @TotalBalance decimal(18, 2) =0;
					DECLARE @INPUTMethod varchar(100);
					DECLARE @jlTypeId BIGINT;
					DECLARE @jlTypeName varchar(100);
					DECLARE @AccountMSModuleId INT = 0;
					DECLARE @IsAutoPost INT = 0;
					DECLARE @IsAutoPostForAll INT = 1;

					IF OBJECT_ID(N'tempdb..#StocklinePostType') IS NOT NULL    
					BEGIN    
						DROP TABLE #StocklinePostType
					END        
					CREATE TABLE #StocklinePostType
					(    
						[StocklineId] [bigint] NOT NULL,
						[Qty] [int] NOT NULL,
						[Amount] [decimal](18, 2) NULL,
						[ModuleName] [varchar](256) NULL,
						[UpdateBy] [varchar](256) NULL,
						[MasterCompanyId] [int] NULL,
						[StockType] [varchar](256) NULL
					 )    
					    
					  INSERT INTO #StocklinePostType ([StocklineId],[Qty],[Amount],[ModuleName],[UpdateBy],[MasterCompanyId],[StockType])
					  SELECT [StocklineId],[Qty],[Amount],[ModuleName],[UpdateBy],[MasterCompanyId],[StockType] 
					  FROM @tbl_PostStocklineBatchType

					 --codetype
					  DECLARE @STKGlAccountId int;
					  DECLARE @STKGlAccountName varchar(200);
					  DECLARE @STKGlAccountNumber varchar(200);
					  DECLARE @JournalTypeId int
					  DECLARE @JournalTypeCode varchar(200) 
					  DECLARE @JournalBatchHeaderId bigint
					  DECLARE @GlAccountId int
					  DECLARE @StatusId int
					  DECLARE @StatusName varchar(200)
					  DECLARE @StartsFROM varchar(200)='00'
					  DECLARE @CurrentNumber int
					  DECLARE @GlAccountName varchar(200) 
					  DECLARE @GlAccountNumber varchar(200) 
					  DECLARE @JournalTypename varchar(200) 
					  DECLARE @Distributionname varchar(200) 
					  DECLARE @ManagementStructureId bigint
					  DECLARE @WorkOrderNumber varchar(200) 
					  DECLARE @MPNName varchar(200) 
					  DECLARE @PiecePNId bigint
					  DECLARE @PiecePN varchar(200) 
					  DECLARE @PieceItemmasterId bigint
					  DECLARE @CustRefNumber varchar(200)
					  DECLARE @LineNumber int=1
					  DECLARE @UnitPrice decimal(18,2)=0
					  DECLARE @LaborHrs decimal(18,2)=0
					  DECLARE @DirectLaborCost decimal(18,2)=0
					  DECLARE @OverheadCost decimal(18,2)=0
					  DECLARE @partId bigint=0
					  DECLARE @batch varchar(100)
					  DECLARE @AccountingPeriod varchar(100)
					  DECLARE @AccountingPeriodId bigint=0
					  DECLARE @CurrentPeriodId bigint=0
					  DECLARE @Currentbatch varchar(100)
					  DECLARE @LastMSLevel varchar(200)
					  DECLARE @AllMSlevels varchar(max)
					  DECLARE @DistributionSetupId int=0
					  DECLARE @DistributionCode varchar(200)
					  DECLARE @InvoiceTotalCost decimal(18,2)=0
					  DECLARE @MaterialCost decimal(18,2)=0
					  DECLARE @LaborOverHeadCost decimal(18,2)=0
					  DECLARE @FreightCost decimal(18,2)=0
					  DECLARE @SalesTax decimal(18,2)=0
					  DECLARE @InvoiceNo varchar(100)
					  DECLARE @MiscChargesCost decimal(18,2)=0
					  DECLARE @LaborCost decimal(18,2)=0
					  DECLARE @InvoiceLaborCost decimal(18,2)=0
					  DECLARE @RevenuWO decimal(18,2)=0
					  DECLARE @CurrentManagementStructureId bigint=0
					  
					  DECLARE @DistributionMasterId bigint;
					  DECLARE @VendorId bigint;
					  DECLARE @VendorName varchar(50);
					  DECLARE @ReferenceId bigint=NULL;
					  DECLARE @ItemMasterId bigint=NULL;
					  DECLARE @STKMSModuleID bigint=2;
					  DECLARE @NONStockMSModuleID bigint=11;
					  DECLARE @AssetMSModuleID bigint=42;
					  DECLARE @ReferencePartId BIGINT=0;
					  DECLARE @ReferencePieceId BIGINT=0;
					  DECLARE @PurchaseOrderId BIGINT=0;
					  DECLARE @PurchaseOrderNumber varchar(50)='';
					  DECLARE @RepairOrderId BIGINT=0;
					  DECLARE @RepairOrderNumber varchar(50)='';
					  DECLARE @StocklineNumber varchar(50)='';
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
					  DECLARE @CommonJournalBatchDetailId BIGINT=0;
					  DECLARE @CrDrType BIGINT;
					  DECLARE @LotId BIGINT = 0;
					  DECLARE @LotNumber VARCHAR(50); 	
					  DECLARE @AssetStockType VARCHAR(256)= 0;

					  SELECT @AssetStockType = [StockType] FROM #StocklinePostType;

					  IF(UPPER(@AssetStockType) = 'ASSET')
					  BEGIN
						   SELECT @DistributionMasterId = ID, @DistributionCode =DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK)  
						   WHERE UPPER(DistributionCode)= UPPER('ASSETACQUISITION');
					  END
					  ELSE
					  BEGIN
							SELECT @DistributionMasterId = ID, @DistributionCode =DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK)  
							WHERE UPPER(DistributionCode)= UPPER('ReceivingROStockline');
					  END
					  
					  
					  SELECT @MasterCompanyId = MasterCompanyId FROM dbo.MasterCompany WITH(NOLOCK)  WHERE MasterCompanyId= @MstCompanyId
					  SELECT @StatusId =Id,@StatusName=name FROM dbo.BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
					  SELECT top 1 @JournalTypeId =JournalTypeId FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId= @MstCompanyId
					  SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
					  SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM dbo.JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
					  SELECT @CurrentManagementStructureId =ManagementStructureId FROM dbo.Employee WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (replace(@updatedByName, ' ', '')) and MasterCompanyId=@MstCompanyId
					  
					  SELECT @Amount = SUM(Amount) FROM #StocklinePostType;

					  SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

					  DECLARE @IsRestrict BIT;
					  DECLARE @IsAccountByPass BIT;

					  EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @updatedByName, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;
					  
					  IF(ISNULL(@Amount,0) > 0 AND ISNULL(@IsAccountByPass, 0) = 0)
					  BEGIN
						  IF(@JournalTypeCode ='RRO' OR @JournalTypeCode = 'AST-AC')
						  BEGIN
								  SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
								  FROM EntityStructureSetup est WITH(NOLOCK) 
									JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
									JOIN dbo.AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
								  WHERE est.EntityStructureId = @CurrentManagementStructureId AND acc.MasterCompanyId  =@MstCompanyId  
										AND CAST(GETUTCDATE() AS DATE) >= CAST(FROMDate AS DATE) AND  CAST(GETUTCDATE() AS DATE) <= CAST(ToDate AS DATE)

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
					  		  FROM dbo.CodePrefixes CP WITH(NOLOCK) 
								JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
					  		  WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MstCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
					  	  
					  		  IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
					  			BEGIN 
					  	  		 SELECT 
					  	  			@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
					  	  				ELSE CAST(StartsFROM AS BIGINT) + 1 END 
					  	  		FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  	  
					  	  		SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					  		  END
					  		  ELSE 
					  		  BEGIN
					  	  		ROLLBACK TRAN;
					  		  END

							  IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MstCompanyId and CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
								  BEGIN
										  IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK))
										   BEGIN
											set @batch ='001'
											set @Currentbatch='001'
										   END
										   ELSE
										   BEGIN

											  SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
							   						FROM dbo.BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

											 if(CAST(@Currentbatch AS BIGINT) >99)
											 BEGIN

											   SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
							   								ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
											 end
											 Else if(CAST(@Currentbatch AS BIGINT) >9)
											 BEGIN

											   SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
							   								ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
											 end
											 else
											 BEGIN
												SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
							   								ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 

											 end
										  END

										  SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 
										  SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as varchar(100)) as varchar(100))
							          
										  IF(UPPER(@AssetStockType) = 'ASSET')
										  BEGIN
												INSERT INTO [dbo].[BatchHeader]
													  ([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
												VALUES
													  (@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MstCompanyId,@updatedByName,@updatedByName,GETUTCDATE(),GETUTCDATE(),1,0,'ASSETAC');
										  END
										  ELSE
										  BEGIN
												INSERT INTO [dbo].[BatchHeader]
													  ([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
												VALUES
													  (@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MstCompanyId,@updatedByName,@updatedByName,GETUTCDATE(),GETUTCDATE(),1,0,'RPO');
										  END
            				          
										  SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
										  SELECT @JlBatchHeaderId = SCOPE_IDENTITY()
										  Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId
								  END
								  ELSE
								  BEGIN
							    		SELECT @JlBatchHeaderId=JournalBatchHeaderId,@JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
										SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
							   			FROM dbo.BatchDetails WITH(NOLOCK) 
										WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
							    
									   if(@CurrentPeriodId =0)
									   BEGIN
										  UPDATE BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   
										  WHERE JournalBatchHeaderId= @JournalBatchHeaderId
									   END
								  END

								INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount],
									[ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[AccountingPeriodId],[AccountingPeriod])
								VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JlBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, 0, 0,
								0, 'ReceivingROStockline', NULL, NULL, @MasterCompanyId, @updatedByName, @updatedByName, GETUTCDATE(), GETUTCDATE(), 1, 0,@AccountingPeriodId,@AccountingPeriod)
						
								SET @JournalBatchDetailId=SCOPE_IDENTITY()

								DECLARE @PostStocklineBatchCursor AS CURSOR;

								SET @PostStocklineBatchCursor = CURSOR FOR	
							
								SELECT [StocklineId],[Qty],[Amount],[ModuleName],[UpdateBy],[MasterCompanyId],[StockType] FROM #StocklinePostType
														   
								OPEN @PostStocklineBatchCursor;
								FETCH NEXT FROM @PostStocklineBatchCursor INTO @StocklineId,@Qty,@Amount,@ModuleName,@UpdateBy,@MasterCompanyId,@StockType;
							
								WHILE @@FETCH_STATUS = 0
								BEGIN
								  IF(UPPER(@DistributionCode) = UPPER('ReceivingROStockline') AND UPPER(@StockType) = 'STOCK')
								  BEGIN
									  SELECT @VendorId=ST.VendorId,
									         @ReferenceId=ST.StockLineId,
											 @PurchaseOrderId=ST.PurchaseOrderId,
											 @RepairOrderId=ST.RepairOrderId,
											 @StocklineNumber=ST.StocklineNumber,
											 @SiteId=ST.[SiteId],
											 @Site=ST.[Site],
											 @WarehouseId=ST.[WarehouseId],
											 @Warehouse=ST.[Warehouse],
											 @LocationId=ST.[LocationId],
											 @Location=ST.[Location],
											 @BinId=ST.[BinId],
											 @Bin=ST.[Bin],
											 @ShelfId=ST.[ShelfId],
											 @Shelf=ST.[Shelf],
											 @WorkOrderNumber=ST.StockLineNumber,
											 @partId=ST.PurchaseOrderPartRecordId,
											 @ItemMasterId=ST.ItemMasterId,
											 @ManagementStructureId=ST.ManagementStructureId,
											 @PieceItemmasterId=ST.ItemMasterId,
											 @LotId = ST.LotId,
								             @LotNumber = LO.LotNumber
									    FROM [dbo].[Stockline] ST WITH(NOLOCK) 
											LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK) ON ST.[LotId] = LO.[LotId]
										WHERE ST.[StockLineId] = @StocklineId;
								
									  SELECT @RepairOrderNumber=RepairOrderNumber,@VendorId=VendorId FROM dbo.RepairOrder WITH(NOLOCK) WHERE RepairOrderId= @RepairOrderId;

									  SELECT @VendorName =VendorName FROM dbo.Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;

									  SET @UnitPrice = @Amount;
									  SET @Amount = (@Qty * @Amount);

									  SELECT @MPNName = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId 
									  SELECT @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels FROM dbo.StocklineManagementStructureDetails WITH(NOLOCK) WHERE ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID
									  SET @ReferencePartId=@partId	

									  SELECT @PiecePN = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 
									  SET @Desc = 'Receiving RO-' + @PurchaseOrderNumber + '  PN-' + @MPNName + '  SL-' + @StocklineNumber
									 
									 -----Stock - Inventory--------

									  SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId =JournalTypeId,@CrDrType = CRDRType, @IsAutoPost = ISNULL(IsAutoPost,0)
									  FROM dbo.DistributionSetup WITH(NOLOCK)  
									  WHERE UPPER(DistributionSetupCode) = UPPER('RROSTKINV') AND MasterCompanyId = @MasterCompanyId
									  AND DistributionMasterId = @DistributionMasterId

									SELECT TOP 1 @STKGlAccountId=SL.GLAccountId,@STKGlAccountNumber=GL.AccountCode,@STKGlAccountName=GL.AccountName 
									FROM DBO.Stockline SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId 
									WHERE SL.StockLineId=@StocklineId

									--Check is allow to AutoPost
									IF(@IsAutoPost = 0 AND @IsAutoPostForAll > 0)
									BEGIN
										SET @IsAutoPostForAll = 0;
									END

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										 INSERT INTO [dbo].[CommonBatchDetails]
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
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
								  
										 SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId =JournalTypeId, @GlAccountId=GlAccountId,
											@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType  
										 FROM [DBO].DistributionSetup WITH(NOLOCK)  
										 WHERE UPPER(DistributionSetupCode) = UPPER('RROGRNI') AND MasterCompanyId = @MasterCompanyId
										 AND DistributionMasterId = @DistributionMasterId

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

										INSERT INTO [DBO].[StocklineBatchDetails]
											(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
											[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
										VALUES
											(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
											@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)

										EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
									END
								 END

								  IF(UPPER(@DistributionCode) = UPPER('ASSETACQUISITION') AND UPPER(@StockType) = 'ASSET')
								  BEGIN
									  SELECT @ReferenceId=AssetInventoryId,@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber,
										@SiteId=[SiteId],@Site=[SiteName],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[BinName],@ShelfId=[ShelfId],@Shelf=[ShelfName]
									  FROM dbo.AssetInventory WITH(NOLOCK) 
									  WHERE AssetInventoryId=@StocklineId;

									  SELECT @VendorName =VendorName FROM dbo.Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;
									  SELECT @RepairOrderNumber=RepairOrderNumber,@VendorId=VendorId FROM dbo.RepairOrder WITH(NOLOCK)  
									  WHERE RepairOrderId= @RepairOrderId;
									  
									  SET @UnitPrice = @Amount;
									  SET @Amount = (@Qty * @Amount);

									  SELECT @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId FROM AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId;
									  SELECT @MPNName = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId 
									  SELECT @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels FROM dbo.StocklineManagementStructureDetails WITH(NOLOCK) WHERE ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID
									  SET @ReferencePartId=@partId	

									  SELECT @PieceItemmasterId=MasterPartId FROM dbo.AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId
									  SELECT @PiecePN = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId = @PieceItemmasterId 
									  SET @Desc = 'Receiving RO-' + @PurchaseOrderNumber + '  PN-' + @MPNName + '  SL-' + @StocklineNumber
								  
									  -----Fixed Asset--------
									  SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType=CRDRType, @IsAutoPost = ISNULL(IsAutoPost,0) 
									  FROM DistributionSetup WITH(NOLOCK)  
									  WHERE UPPER(DistributionSetupCode) =UPPER('FIXEDASSETAC') AND DistributionMasterId = @DistributionMasterId
									  AND MasterCompanyId = @MasterCompanyId

									  SELECT TOP 1 @GlAccountId=SL.AcquiredGLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName 
									  FROM DBO.AssetInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.AcquiredGLAccountId=GL.GLAccountId 
								      WHERE AssetInventoryId=@StocklineId;

									  --Check is allow to AutoPost
									  IF(@IsAutoPost = 0 AND @IsAutoPostForAll > 0)
									  BEGIN
										  SET @IsAutoPostForAll = 0;
									  END

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
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
										  SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,
												@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType  
										  FROM DistributionSetup WITH(NOLOCK)  
										  WHERE UPPER(DistributionSetupCode) =UPPER('GOODSRECEIPTNOTINVOICED') AND MasterCompanyId = @MasterCompanyId
												AND DistributionMasterId = @DistributionMasterId

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
									END
								END

								 SET @TotalDebit=0;
								 SET @TotalCredit=0;
								 SELECT @TotalDebit =SUM(DebitAmount),
								        @TotalCredit=SUM(CreditAmount) 
								  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
								  WHERE [JournalBatchDetailId] = @JournalBatchDetailId GROUP BY JournalBatchDetailId
								 
								 UPDATE [dbo].[BatchDetails] 
								    SET [DebitAmount]=@TotalDebit,
								        [CreditAmount]=@TotalCredit,
										[UpdatedDate]=GETUTCDATE(),
										[UpdatedBy]=@UpdateBy,
										[LastMSLevel] = @LastMSLevel,
										[AllMSlevels] = @AllMSlevels,
										[ManagementStructureId] = @ManagementStructureId
								  WHERE [JournalBatchDetailId] = @JournalBatchDetailId
						  
					  			FETCH NEXT FROM @PostStocklineBatchCursor INTO @StocklineId,@Qty,@Amount,@ModuleName,@UpdateBy,@MasterCompanyId,@StockType;
							END	
							CLOSE @PostStocklineBatchCursor
							DEALLOCATE @PostStocklineBatchCursor
						END
					          
						  SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM dbo.BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JlBatchHeaderId and IsDeleted=0 --group by JournalBatchHeaderId
			   	          
						  SET @TotalBalance =@TotalDebit-@TotalCredit
						  UPDATE dbo.CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MstCompanyId    
						  Update dbo.BatchHeader SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@updatedByName WHERE JournalBatchHeaderId= @JlBatchHeaderId

						  --AutoPost Batch
						  IF(@IsAutoPostForAll = 1)
						  BEGIN
							  EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
						  END
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
              , @AdhocComments     VARCHAR(150)    = 'usp_PostROCreateStocklineBatchDetails' 
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