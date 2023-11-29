/*************************************************************           
 ** File:   [USP_BatchTriggerBasedonDistribution]           
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used USP_BatchTriggerBasedonDistribution
 ** Purpose:         
 ** Date:   08/10/2022      
 ** PARAMETERS: @JournalBatchHeaderId bigint
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/10/2022  Subhash Saliya     Created
-- EXEC USP_BatchTriggerBasedonDistribution 3
   EXEC [dbo].[USP_BatchTriggerBasedonDistributionStockline] 2,5,'10','ReceivingPO','Deep'
************************************************************************/
CREATE PROCEDURE [dbo].[USP_BatchTriggerBasedonDistributionStockline]
@StocklineId bigint=NULL,
@Qty int=0,
@Amount Decimal(18,2),
@ModuleName varchar(200),
@UpdateBy varchar(200),
@MasterCompanyId bigint,
@StockType varchar(100),
@BatchId BIGINT OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

	         Declare @JournalTypeId int
	         Declare @JournalTypeCode varchar(200) 
	         Declare @JournalBatchHeaderId bigint
	         Declare @GlAccountId int
	         Declare @StatusId int
	         Declare @StatusName varchar(200)
	         Declare @StartsFrom varchar(200)='00'
	         Declare @CurrentNumber int
	         Declare @GlAccountName varchar(200) 
	         Declare @GlAccountNumber varchar(200) 
	         Declare @JournalTypename varchar(200) 
	         Declare @Distributionname varchar(200) 
	         Declare @ManagementStructureId bigint
             Declare @WorkOrderNumber varchar(200) 
             Declare @MPNName varchar(200) 
	         Declare @PiecePNId bigint
             Declare @PiecePN varchar(200) 
	         Declare @PieceItemmasterId bigint
	         Declare @CustRefNumber varchar(200)
	         declare @LineNumber int=1
	         declare @TotalDebit decimal(18,2)=0
	         declare @TotalCredit decimal(18,2)=0
	         declare @TotalBalance decimal(18,2)=0
	         declare @UnitPrice decimal(18,2)=0
	         declare @LaborHrs decimal(18,2)=0
	         declare @DirectLaborCost decimal(18,2)=0
	         declare @OverheadCost decimal(18,2)=0
	         declare @partId bigint=0
			 declare @batch varchar(100)
			 declare @AccountingPeriod varchar(100)
			 declare @AccountingPeriodId bigint=0
			 declare @CurrentPeriodId bigint=0
			  declare @Currentbatch varchar(100)
	         declare @LastMSLevel varchar(200)
			 declare @AllMSlevels varchar(max)
			 declare @DistributionSetupId int=0
			 declare @IsAccountByPass bit=0
			 declare @DistributionCode varchar(200)
			 declare @InvoiceTotalCost decimal(18,2)=0
	         declare @MaterialCost decimal(18,2)=0
	         declare @LaborOverHeadCost decimal(18,2)=0
	         declare @FreightCost decimal(18,2)=0
			 declare @SalesTax decimal(18,2)=0
			 declare @InvoiceNo varchar(100)
			 declare @MiscChargesCost decimal(18,2)=0
			 declare @LaborCost decimal(18,2)=0
			 declare @InvoiceLaborCost decimal(18,2)=0
			 declare @RevenuWO decimal(18,2)=0
			 declare @CurrentManagementStructureId bigint=0

			 DECLARE @DistributionMasterId bigint;
			 Declare @VendorId bigint;
			 Declare @VendorName varchar(50);
			 DECLARE @ReferenceId bigint=NULL;
			 DECLARE @ItemMasterId bigint=NULL;
			 DECLARE @STKMSModuleID bigint=2;
			 DECLARE @NONStockMSModuleID bigint=11;
			 DECLARE @AssetMSModuleID bigint=42;
			 DECLARE @ReferencePartId BIGINT=0;
			 DECLARE @ReferencePieceId BIGINT=0;
			 DECLARE @JournalBatchDetailId BIGINT=0;
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
			 declare @CommonJournalBatchDetailId bigint=0;
			 DECLARE @currentNo AS BIGINT = 0;
			 DECLARE @CodeTypeId AS BIGINT = 74;
			 DECLARE @JournalTypeNumber varchar(100);
			 select @DistributionMasterId =ID from DistributionMaster WITH(NOLOCK)  where UPPER(DistributionCode)= UPPER('ReceivingPOStockline')

			 select @IsAccountByPass =IsAccountByPass from MasterCompany WITH(NOLOCK)  where MasterCompanyId= @MasterCompanyId
	         select @DistributionCode =DistributionCode from DistributionMaster WITH(NOLOCK)  where ID= @DistributionMasterId
	         select @StatusId =Id,@StatusName=name from BatchStatus WITH(NOLOCK)  where Name= 'Open'
	         select top 1 @JournalTypeId =JournalTypeId from DistributionSetup WITH(NOLOCK)  where DistributionMasterId =@DistributionMasterId
	         select @JournalBatchHeaderId =JournalBatchHeaderId from BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and StatusId=@StatusId
	         select @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName from JournalType WITH(NOLOCK)  where ID= @JournalTypeId
	         --select @CurrentManagementStructureId =ManagementStructureId from Employee WITH(NOLOCK)  where CONCAT(FirstName,' ',LastName) IN (@UpdateBy) and MasterCompanyId=@MasterCompanyId
			 select @CurrentManagementStructureId =ManagementStructureId from Employee WITH(NOLOCK)  where CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (replace(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
	         
			 if((@JournalTypeCode ='RPO') and @IsAccountByPass=0)
			 BEGIN
					  select top 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName from EntityStructureSetup est WITH(NOLOCK) 
					  inner join ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
					  inner join AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
					  where est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  and CAST(getdate() as date)   >= CAST(FromDate as date) and  CAST(getdate() as date) <= CAST(ToDate as date)


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
				  	ROLLBACK TRAN;
				  END

				  IF NOT EXISTS(select JournalBatchHeaderId from BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
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
				           print @CurrentNumber
				          
                           INSERT INTO [dbo].[BatchHeader]
                                      ([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
                           VALUES
                                      (@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,'RPO');
            	          
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

			      IF(UPPER(@DistributionCode) = UPPER('ReceivingPOStockline') AND UPPER(@StockType) = 'STOCK')
	              BEGIN
					  Select @VendorId=VendorId,@ReferenceId=StockLineId,@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=StocklineNumber
					  ,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf]
					  from Stockline where StockLineId=@StocklineId;
					  select @VendorName =VendorName from Vendor WITH(NOLOCK)  where VendorId= @VendorId;
					  select @PurchaseOrderNumber=PurchaseOrderNumber from PurchaseOrder WITH(NOLOCK)  where PurchaseOrderId= @PurchaseOrderId;
					  select @RepairOrderNumber=RepairOrderNumber from RepairOrder WITH(NOLOCK)  where RepairOrderId= @RepairOrderId;
						

					  SET @UnitPrice = @Amount;
					  SET @Amount = (@Qty * @Amount);

					  Select @WorkOrderNumber=StockLineNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=ItemMasterId,@ManagementStructureId=ManagementStructureId from Stockline where StockLineId=@StocklineId;
	                  select @MPNName = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@ItemmasterId 
	                  select @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels from StocklineManagementStructureDetails  where ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID
					  Set @ReferencePartId=@partId	

		              --SELECT @PieceItemmasterId=ItemMasterId,@UnitPrice=UnitCost,@Amount=(@Qty * UnitCost) from WorkOrderMaterialStockLine  where StockLineId=@StocklineId
					  SELECT @PieceItemmasterId=ItemMasterId from Stockline  where StockLineId=@StocklineId
		              SELECT @PiecePN = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@PieceItemmasterId 
				      					SET @Desc = 'Receiving PO-' + @PurchaseOrderNumber + '  PN-' + @MPNName + '  SL-' + @StocklineNumber
					  SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Stock - Inventory') AND DistributionMasterId=@DistributionMasterId

				     INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
							[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
							[ManagementStructureId],[ModuleName],
							LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						   @JournalTypeId ,@JournalTypename ,1,@Amount ,0,
						   @ManagementStructureId ,@ModuleName,
						   @LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)


					SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[CommonBatchDetails]
                            (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					 SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()



					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)

                   -----Goods Received Not Invoiced (GRNI)--------
					SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Goods Received Not Invoiced (GRNI)') AND DistributionMasterId=@DistributionMasterId

				 --    INSERT INTO [dbo].[BatchDetails]
     --                       (DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
					--		[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
					--		[ManagementStructureId],[ModuleName],
					--		LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
     --                VALUES
     --                      (@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
					--	   @JournalTypeId ,@JournalTypename ,0,0 ,@Amount,
					--	   @ManagementStructureId ,@ModuleName,
					--	   @LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)


					--SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[CommonBatchDetails]
                            (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0,@Amount,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					 SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()



					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)


					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM CommonBatchDetails WITH(NOLOCK) where JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
			        Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy where JournalBatchDetailId=@JournalBatchDetailId


					EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
				end

				  IF(UPPER(@DistributionCode) = UPPER('ReceivingPOStockline') AND UPPER(@StockType) = 'NONSTOCK')
	              BEGIN
				      Select @VendorId=VendorId,@ReferenceId=NonStockInventoryId,@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=NonStockInventoryNumber
					  ,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf]
					  from NonStockInventory where NonStockInventoryId=@StocklineId;
					  select @VendorName =VendorName from Vendor WITH(NOLOCK)  where VendorId= @VendorId;
					  select @PurchaseOrderNumber=PurchaseOrderNumber from PurchaseOrder WITH(NOLOCK)  where PurchaseOrderId= @PurchaseOrderId;
					  select @RepairOrderNumber=RepairOrderNumber from RepairOrder WITH(NOLOCK)  where RepairOrderId= @RepairOrderId;
						
					  SET @UnitPrice = @Amount;
					  SET @Amount = (@Qty * @Amount);

					  Select @WorkOrderNumber=NonStockInventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId from NonStockInventory where NonStockInventoryId=@StocklineId;
	                  select @MPNName = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@ItemmasterId 
	                  select @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels from NonStocklineManagementStructureDetails  where ReferenceID=@StockLineId AND ModuleID=@NONStockMSModuleID
					  Set @ReferencePartId=@partId	

					  SELECT @PieceItemmasterId=MasterPartId from NonStockInventory  where NonStockInventoryId=@StocklineId
		              SELECT @PiecePN = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@PieceItemmasterId 
				      SET @Desc = 'Receiving PO-' + @PurchaseOrderNumber + '  PN-' + @MPNName + '  SL-' + @StocklineNumber
					  -----NonStock - Inventory--------
					  SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('NonStock - Inventory') AND DistributionMasterId=@DistributionMasterId

				     INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
							[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
							[ManagementStructureId],[ModuleName],
							LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						   @JournalTypeId ,@JournalTypename ,1,@Amount ,0,
						   @ManagementStructureId ,@ModuleName,
						   @LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)


					SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[CommonBatchDetails]
                            (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					 SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					
					

					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)

					-----Goods Received Not Invoiced (GRNI)--------
					SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Goods Received Not Invoiced (GRNI)') AND DistributionMasterId=@DistributionMasterId

				 --    INSERT INTO [dbo].[BatchDetails]
     --                       (DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
					--		[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
					--		[ManagementStructureId],[ModuleName],
					--		LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
     --                VALUES
     --                      (@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
					--	   @JournalTypeId ,@JournalTypename ,0,0 ,@Amount,
					--	   @ManagementStructureId ,@ModuleName,
					--	   @LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)


					--SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[CommonBatchDetails]
                            (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0,@Amount,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					 SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()


					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)


					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM CommonBatchDetails WITH(NOLOCK) where JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
			        Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy where JournalBatchDetailId=@JournalBatchDetailId



					EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
				end

				  IF(UPPER(@DistributionCode) = UPPER('ReceivingPOStockline') AND UPPER(@StockType) = 'ASSET')
	              BEGIN
				      Select @ReferenceId=AssetInventoryId,@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber
					  ,@SiteId=[SiteId],@Site=[SiteName],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[BinName],@ShelfId=[ShelfId],@Shelf=[ShelfName]
					  from AssetInventory where AssetInventoryId=@StocklineId;
					  select @PurchaseOrderNumber=PurchaseOrderNumber,@VendorId=VendorId from PurchaseOrder WITH(NOLOCK)  where PurchaseOrderId= @PurchaseOrderId;
					  select @VendorName =VendorName from Vendor WITH(NOLOCK)  where VendorId= @VendorId;
						
					  SET @UnitPrice = @Amount;
					  SET @Amount = (@Qty * @Amount);

					  Select @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId from AssetInventory where AssetInventoryId=@StocklineId;
	                  select @MPNName = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@ItemmasterId 
	                  select @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels from AssetManagementStructureDetails  where ReferenceID=@StockLineId AND ModuleID=@AssetMSModuleID
					  Set @ReferencePartId=@partId	

					  SELECT @PieceItemmasterId=MasterPartId from AssetInventory  where AssetInventoryId=@StocklineId
		              SELECT @PiecePN = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@PieceItemmasterId 
				      SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Asset - Inventory') AND DistributionMasterId=@DistributionMasterId

				     INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
							[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
							[ManagementStructureId],[ModuleName],
							LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						   @JournalTypeId ,@JournalTypename ,1,@Amount ,0,
						   @ManagementStructureId ,@ModuleName,
						   @LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)


					SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[CommonBatchDetails]
                            (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					 SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					
					SET @Desc = 'Receiving PO-' + @PurchaseOrderNumber + '  PN-' + @MPNName + '  SL-' + @StocklineNumber

					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)

                    
					-----Goods Received Not Invoiced (GRNI)--------
					SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Goods Received Not Invoiced (GRNI)') AND DistributionMasterId=@DistributionMasterId

				 --    INSERT INTO [dbo].[BatchDetails]
     --                       (DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
					--		[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
					--		[ManagementStructureId],[ModuleName],
					--		LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
     --                VALUES
     --                      (@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
					--	   @JournalTypeId ,@JournalTypename ,0,0 ,@Amount,
					--	   @ManagementStructureId ,@ModuleName,
					--	   @LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)


					--SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[CommonBatchDetails]
                            (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0,@Amount,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					 SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()


					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType,@CommonJournalBatchDetailId)


					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM CommonBatchDetails WITH(NOLOCK) where JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
			        Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy where JournalBatchDetailId=@JournalBatchDetailId


					EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
				end
					          
				     SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	         
			         SET @TotalBalance =@TotalDebit-@TotalCredit
				         
			         Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   where JournalBatchHeaderId= @JournalBatchHeaderId
					 UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
			 
            END

			SET @BatchId = @JournalBatchHeaderId;

END
  COMMIT  TRANSACTION



    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_BatchTriggerBasedonDistribution' 
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