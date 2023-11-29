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
   EXEC [dbo].[USP_CreateReceivingReconciliationBatchDetails] 'RPO',10023,0
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateReceivingReconciliationBatchDetails] @StocklineId bigint=NULL, @Qty int=0, @Amount Decimal(18, 2), @ModuleName varchar(200), @UpdateBy varchar(200), @DistributionCode varchar(200), @JournalBatchHeaderId bigint, @JournalTypename varchar(200), @StockType varchar(50), @PackagingId int, @EmployeeId BIGINT, @RRId BIGINT, @ReceivingReconciliationDetailId BIGINT, @BatchId BIGINT OUTPUT
AS BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION
        BEGIN
        Declare @PieceItemmasterId bigint;
        Declare @PiecePNId bigint;
        Declare @PiecePN varchar(200);
        declare @DistributionSetupId int=0;
        Declare @Distributionname varchar(200);
        Declare @JournalTypeId int;
        Declare @GlAccountId int;
        Declare @GlAccountNumber varchar(200);
        Declare @GlAccountName varchar(200);
        Declare @WorkOrderNumber varchar(200);
        declare @partId bigint=0;
        DECLARE @ItemMasterId bigint=NULL;
        Declare @ManagementStructureId bigint;
        declare @LastMSLevel varchar(200);
        declare @AllMSlevels varchar(max);
        declare @MasterCompanyId bigint=0;
        DECLARE @JournalBatchDetailId BIGINT=0;
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
        Declare @MPNName varchar(200);
        DECLARE @Desc varchar(100);
        Declare @VendorId bigint;
        Declare @VendorName varchar(50);
        declare @TotalDebit decimal(18, 2) =0;
        declare @TotalCredit decimal(18, 2) =0;
        declare @TotalBalance decimal(18, 2) =0;
        DECLARE @STKMSModuleID bigint=2;
        DECLARE @EMPMSModuleID bigint=47;
        DECLARE @ReceivedQty BIGINT=0;
        DECLARE @StocklineQtyOH BIGINT=0;
        DECLARE @StocklineQtyAvail BIGINT=0;
        DECLARE @StocklineQtyreserved BIGINT=0;
        declare @POStocklineUnitPrice decimal(18, 2) =0;
        declare @ROStocklineUnitPrice decimal(18, 2) =0;
        declare @StocklineUnitPrice decimal(18, 2) =0;
        declare @POROUnitPrice decimal(18, 2) =0;
        declare @RRUnitPrice decimal(18, 2) =0;
        declare @APTotalPrice decimal(18, 2) =0;
        select @POROUnitPrice=isnull(POUnitCost, 0), @ReceivedQty=isnull(ReceivedQty, 0), @RRUnitPrice=Isnull(InvoicedUnitCost, 0)
        from ReceivingReconciliationDetails
        where ReceivingReconciliationDetailId=@ReceivingReconciliationDetailId
        IF(UPPER(@DistributionCode)=UPPER('ReceivingPOStockline'))
		BEGIN

            IF(UPPER(@StockType) = 'STOCK')
					BEGIN
					      Select @WorkOrderNumber=StockLineNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=ItemMasterId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
					      @PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=StocklineNumber
					     ,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
					      @VendorId=VendorId,@POStocklineUnitPrice=Isnull(PurchaseOrderUnitCost,0),@ROStocklineUnitPrice=isnull(RepairOrderUnitCost,0),@StocklineQtyAvail=isnull(QuantityAvailable,0) from Stockline where StockLineId=@StocklineId;
						  
						  SELECT @PieceItemmasterId=ItemMasterId from Stockline  where StockLineId=@StocklineId

					END

					IF(UPPER(@StockType) = 'NONSTOCK')
					 BEGIN
					      Select @WorkOrderNumber=NonStockInventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
					      @PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=NonStockInventoryNumber
					     ,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
					      @VendorId=VendorId,@POStocklineUnitPrice=Isnull(UnitCost,0),@ROStocklineUnitPrice=isnull(UnitCost,0),@StocklineQtyAvail=QuantityOnHand  from NonStockInventory where NonStockInventoryId=@StocklineId;
						  
						  SELECT @PieceItemmasterId=MasterPartId from NonStockInventory  where NonStockInventoryId=@StocklineId

					END

					IF(UPPER(@StockType) = 'ASSET')
					 BEGIN
					      Select @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
					      @PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber
					     ,@SiteId=[SiteId],@Site=SiteName,@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=BinName,@ShelfId=[ShelfId],@Shelf=ShelfName,
					      @POStocklineUnitPrice=Isnull(UnitCost,0),@ROStocklineUnitPrice=isnull(UnitCost,0),@StocklineQtyAvail=1 from AssetInventory where AssetInventoryId=@StocklineId;
						  
						  select @PurchaseOrderNumber=PurchaseOrderNumber,@VendorId=VendorId from PurchaseOrder WITH(NOLOCK)  where PurchaseOrderId= @PurchaseOrderId;
						  SELECT @PieceItemmasterId=MasterPartId  from AssetInventory  where AssetInventoryId=@StocklineId

					END



					 select @MPNName = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@ItemmasterId;
					 select @VendorName =VendorName from Vendor WITH(NOLOCK)  where VendorId= @VendorId;
					 select @PurchaseOrderNumber=PurchaseOrderNumber from PurchaseOrder WITH(NOLOCK)  where PurchaseOrderId= @PurchaseOrderId;
		             SELECT @PiecePN = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@PieceItemmasterId 
            IF(@PackagingId>0)BEGIN
                SET @Amount=(@Qty * @Amount);
                SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                from DistributionSetup WITH(NOLOCK)
                where UPPER(Name)=UPPER('VAR - Cost/Qty - COGS')AND JournalTypeId=6;
                SELECT @LastMSLevel=LastMSLevel, @AllMSlevels=AllMSlevels
                from EmployeeManagementStructureDetails
                where ReferenceID=@EmployeeId AND ModuleID=@EMPMSModuleID;
                SELECT @VendorId=VendorId, @VendorName=VendorName
                from ReceivingReconciliationHeader
                where ReceivingReconciliationId=@RRId;
                INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                SET @JournalBatchDetailId=SCOPE_IDENTITY()
                SET @Desc='Receiving PO-'+@PurchaseOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber
                INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)
            END
            ELSE BEGIN
                select @LastMSLevel=LastMSLevel, @AllMSlevels=AllMSlevels
                from StocklineManagementStructureDetails
                where ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID;
                SET @Desc='Receiving PO-'+@PurchaseOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber
                SET @Amount=(Isnull(@StocklineQtyAvail, 0)* @Amount);
                if(Isnull(@StocklineQtyAvail, 0)=isnull(@ReceivedQty, 0)and @POROUnitPrice=isnull(@RRUnitPrice, 0))begin
                    ------- Goods Received Not Invoiced (GRNI)---
                    SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                    from DistributionSetup WITH(NOLOCK)
                    where UPPER(Name)=UPPER('Goods Received Not Invoiced (GRNI)')AND JournalTypeId=6;
                    INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                    VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                    SET @JournalBatchDetailId=SCOPE_IDENTITY()
                    INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                    VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                    ------- Accounts Payable ---
                    SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                    from DistributionSetup WITH(NOLOCK)
                    where UPPER(Name)=UPPER('Accounts Payable')AND JournalTypeId=6;
                    SET @Amount=(@ReceivedQty * @POROUnitPrice);
                    INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                    VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 0, 0, @Amount, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                    SET @JournalBatchDetailId=SCOPE_IDENTITY()
                    INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                    VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)
                END
                else if(Isnull(@StocklineQtyAvail, 0)=isnull(@ReceivedQty, 0)and @POROUnitPrice !=isnull(@RRUnitPrice, 0))BEGIN
                      

                         ------- Stock - Inventory ---
                         SET @Amount=Isnull(((@RRUnitPrice-@POROUnitPrice)* Isnull(@StocklineQtyAvail, 0)), 0);
                         SET @APTotalPrice=@APTotalPrice+@Amount
                         IF(UPPER(@StockType) = 'STOCK')
					     BEGIN
						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0) and Isnull(@StocklineQtyAvail, 0)>0)
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice+@ROStocklineUnitPrice
                                 update Stockline
                                 SET PurchaseOrderUnitCost=@RRUnitPrice, UnitCost=@StocklineUnitPrice
                                where StockLineId=@StocklineId
                              END
					          SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                              FROM DistributionSetup WITH(NOLOCK)
                              WHERE UPPER(Name)=UPPER('Stock - Inventory')AND JournalTypeId=6;
					     END
					     
					     IF(UPPER(@StockType) = 'NONSTOCK')
					      BEGIN

						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0))
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice
                                 update NonStockInventory
                                 SET  UnitCost=@StocklineUnitPrice
                                where NonStockInventoryId=@StocklineId
                              END
					           SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                               FROM DistributionSetup WITH(NOLOCK)
                               WHERE UPPER(Name)=UPPER('NonStock - Inventory')AND JournalTypeId=6;
					     END
					     
					     IF(UPPER(@StockType) = 'ASSET')
					      BEGIN

						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0))
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice
                                 update AssetInventory
                                 SET  UnitCost=@StocklineUnitPrice
                                where AssetInventoryId=@StocklineId
                               END
					     
					           SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                               FROM DistributionSetup WITH(NOLOCK)
                               WHERE UPPER(Name)=UPPER('Asset - Inventory')AND JournalTypeId=6;
					     END
                         INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                         VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                         SET @JournalBatchDetailId=SCOPE_IDENTITY()
                         INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                         VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                         ------- Goods Received Not Invoiced (GRNI)---
                         SET @Amount=(@ReceivedQty * @POROUnitPrice);
                         SET @APTotalPrice=@APTotalPrice+@Amount
                         SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                         from DistributionSetup WITH(NOLOCK)
                         where UPPER(Name)=UPPER('Goods Received Not Invoiced (GRNI)')AND JournalTypeId=6;
                         INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                         VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                         SET @JournalBatchDetailId=SCOPE_IDENTITY()
                         INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                         VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                         ------- Accounts Payable ---
                         SET @Amount=@APTotalPrice;
                         SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                         from DistributionSetup WITH(NOLOCK)
                         where UPPER(Name)=UPPER('Accounts Payable')AND JournalTypeId=6;
                         INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                         VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 0, 0, @Amount, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                         SET @JournalBatchDetailId=SCOPE_IDENTITY()
                         INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                         VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)
                END
                else if(Isnull(@StocklineQtyAvail, 0)!=isnull(@ReceivedQty, 0))BEGIN
                         
						  print '@3333'
						  print @RRUnitPrice
					      print @POROUnitPrice
						  print @StocklineQtyAvail
						 ------- Stock - Inventory ---
                         SET @Amount=(@RRUnitPrice-@POROUnitPrice)* Isnull(@StocklineQtyAvail, 0);
                         print '@Amount1'
						 print @Amount
                         set @APTotalPrice=@APTotalPrice+@Amount
                      
					     IF(UPPER(@StockType) = 'STOCK')
					     BEGIN
						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0) and Isnull(@StocklineQtyAvail, 0)>0)
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice+@ROStocklineUnitPrice
                                 update Stockline
                                 SET PurchaseOrderUnitCost=@RRUnitPrice, UnitCost=@StocklineUnitPrice
                                where StockLineId=@StocklineId
                              END
					          SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                              FROM DistributionSetup WITH(NOLOCK)
                              WHERE UPPER(Name)=UPPER('Stock - Inventory')AND JournalTypeId=6;
					     END
					     
					     IF(UPPER(@StockType) = 'NONSTOCK')
					      BEGIN

						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0))
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice
                                 update NonStockInventory
                                 SET  UnitCost=@StocklineUnitPrice
                                where NonStockInventoryId=@StocklineId
                              END
					           SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                               FROM DistributionSetup WITH(NOLOCK)
                               WHERE UPPER(Name)=UPPER('NonStock - Inventory')AND JournalTypeId=6;
					     END
					     
					     IF(UPPER(@StockType) = 'ASSET')
					      BEGIN

						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0))
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice
                                 update AssetInventory
                                 SET  UnitCost=@StocklineUnitPrice
                                where AssetInventoryId=@StocklineId
                               END
					     
					           SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                               FROM DistributionSetup WITH(NOLOCK)
                               WHERE UPPER(Name)=UPPER('Asset - Inventory')AND JournalTypeId=6;
					     END

                         INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                         VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                         SET @JournalBatchDetailId=SCOPE_IDENTITY()
                         INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                         VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                         ------- VAR - Cost/Qty - COGS ---
                         SET @Amount=Isnull(((@ReceivedQty-Isnull(@StocklineQtyAvail, 0))*(@RRUnitPrice-@POROUnitPrice)), 0);
                         SET @APTotalPrice=@APTotalPrice+@Amount
						 print '@Amount2'
						 print @Amount
                         SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                         from DistributionSetup WITH(NOLOCK)
                         where UPPER(Name)=UPPER('VAR - Cost/Qty - COGS')AND JournalTypeId=6;
                         INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                         VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                         SET @JournalBatchDetailId=SCOPE_IDENTITY()
                         INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                         VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                         ------- Goods Received Not Invoiced (GRNI)---
                         SET @Amount=(@ReceivedQty * @POROUnitPrice);
                         SET @APTotalPrice=@APTotalPrice+@Amount
						 print '@Amount3'
						 print @Amount
                         SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                         from DistributionSetup WITH(NOLOCK)
                         where UPPER(Name)=UPPER('Goods Received Not Invoiced (GRNI)')AND JournalTypeId=6;
                         INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                         VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                         SET @JournalBatchDetailId=SCOPE_IDENTITY()
                         INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                         VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                         ------- Accounts Payable ---
                         SET @Amount=@APTotalPrice;
						 print '@Amount4'
						 print @Amount
                         SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                         from DistributionSetup WITH(NOLOCK)
                         where UPPER(Name)=UPPER('Accounts Payable')AND JournalTypeId=6;
                         INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                         VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 0, 0, @Amount, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                         SET @JournalBatchDetailId=SCOPE_IDENTITY()
                         INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                         VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)
                END
            END
            EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
        end
        ELSE IF(UPPER(@DistributionCode)=UPPER('ReceivingROStockline'))BEGIN
                
				IF(UPPER(@StockType) = 'STOCK')
					BEGIN
					      Select @WorkOrderNumber=StockLineNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=ItemMasterId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
					      @PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=StocklineNumber
					     ,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
					     @VendorId=VendorId,@StocklineQtyAvail=isnull(QuantityAvailable,0),@POStocklineUnitPrice=Isnull(PurchaseOrderUnitCost,0),@ROStocklineUnitPrice=isnull(RepairOrderUnitCost,0)  from Stockline where StockLineId=@StocklineId;
						  
						  SELECT @PieceItemmasterId=ItemMasterId from Stockline  where StockLineId=@StocklineId

					END

					IF(UPPER(@StockType) = 'NONSTOCK')
					 BEGIN
					      Select @WorkOrderNumber=NonStockInventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
					      @PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=NonStockInventoryNumber
					     ,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
					      @VendorId=VendorId,@POStocklineUnitPrice=Isnull(UnitCost,0),@ROStocklineUnitPrice=isnull(UnitCost,0),@StocklineQtyAvail=isnull(QuantityOnHand,0)   from NonStockInventory where NonStockInventoryId=@StocklineId;
						  
						  SELECT @PieceItemmasterId=MasterPartId from NonStockInventory  where NonStockInventoryId=@StocklineId

					END

					IF(UPPER(@StockType) = 'ASSET')
					 BEGIN
					      Select @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
					      @PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber
					     ,@SiteId=[SiteId],@Site=SiteName,@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=BinName,@ShelfId=[ShelfId],@Shelf=ShelfName,
					      @POStocklineUnitPrice=Isnull(UnitCost,0),@ROStocklineUnitPrice=isnull(UnitCost,0),@StocklineQtyAvail=1 from AssetInventory where AssetInventoryId=@StocklineId;
						  
						  select @RepairOrderNumber=RepairOrderNumber,@VendorId=VendorId from RepairOrder WITH(NOLOCK)  where RepairOrderId= @RepairOrderId;
						  SELECT @PieceItemmasterId=MasterPartId  from AssetInventory  where AssetInventoryId=@StocklineId

					END
                 	 select @MPNName = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@ItemmasterId;
					 select @VendorName =VendorName from Vendor WITH(NOLOCK)  where VendorId= @VendorId;
					 select @RepairOrderNumber=RepairOrderNumber from RepairOrder WITH(NOLOCK)  where RepairOrderId= @RepairOrderId;
					  SET @Amount = (@Qty * @Amount);

					  SELECT @PieceItemmasterId=ItemMasterId from Stockline  where StockLineId=@StocklineId
		              SELECT @PiecePN = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@PieceItemmasterId 
                 IF(@PackagingId>0)BEGIN
                     SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                     from DistributionSetup WITH(NOLOCK)
                     where UPPER(Name)=UPPER('VAR - Cost/Qty - COGS')AND JournalTypeId=7;
                     select @LastMSLevel=LastMSLevel, @AllMSlevels=AllMSlevels
                     from EmployeeManagementStructureDetails
                     where ReferenceID=@EmployeeId AND ModuleID=@EMPMSModuleID;
                     Select @VendorId=VendorId, @VendorName=VendorName
                     from ReceivingReconciliationHeader
                     where ReceivingReconciliationId=@RRId;
                     SET @Amount=(@Qty * @Amount);
                     INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                     VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                     SET @JournalBatchDetailId=SCOPE_IDENTITY()
                     SET @Desc='Receiving RO-'+@RepairOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber
                     INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                     VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)
                 END
                 ELSE BEGIN
                     select @LastMSLevel=LastMSLevel, @AllMSlevels=AllMSlevels
                     from StocklineManagementStructureDetails
                     where ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID;
                     SET @Desc='Receiving RO-'+@RepairOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber
                     SET @Amount=(Isnull(@StocklineQtyAvail, 0)* @Amount);
                     if(Isnull(@StocklineQtyAvail, 0)=isnull(@ReceivedQty, 0)and @POROUnitPrice=isnull(@RRUnitPrice, 0))begin
                         ------- Goods Received Not Invoiced (GRNI)---
                         SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                         from DistributionSetup WITH(NOLOCK)
                         where UPPER(Name)=UPPER('Goods Received Not Invoiced (GRNI)')AND JournalTypeId=7;
                         INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                         VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                         SET @JournalBatchDetailId=SCOPE_IDENTITY()
                         INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                         VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                         ------- Accounts Payable ---
                         SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                         from DistributionSetup WITH(NOLOCK)
                         where UPPER(Name)=UPPER('Accounts Payable')AND JournalTypeId=7;
                         SET @Amount=(Isnull(@StocklineQtyAvail, 0)* @Amount);
                         INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                         VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 0, 0, @Amount, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                         SET @JournalBatchDetailId=SCOPE_IDENTITY()
                         INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                         VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)
                     END
                     else if(Isnull(@StocklineQtyAvail, 0)=isnull(@ReceivedQty, 0)and @POROUnitPrice !=isnull(@RRUnitPrice, 0))BEGIN
                            
                              ------- Stock - Inventory ---
                              SET @Amount=Isnull(((@RRUnitPrice-@POROUnitPrice)* Isnull(@StocklineQtyAvail, 0)), 0);
                              SET @APTotalPrice=@APTotalPrice+@Amount
                             
							 IF(UPPER(@StockType) = 'STOCK')
					        BEGIN
						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0) and Isnull(@StocklineQtyAvail, 0) >0)
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice+@POStocklineUnitPrice
                                 update Stockline
                                 SET RepairOrderUnitCost=@RRUnitPrice, UnitCost=@StocklineUnitPrice
                                WHERE StockLineId=@StocklineId
                              END
					          SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                              FROM DistributionSetup WITH(NOLOCK)
                              WHERE UPPER(Name)=UPPER('Stock - Inventory')AND JournalTypeId=7;
					     END
					     
					     IF(UPPER(@StockType) = 'NONSTOCK')
					      BEGIN

						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0))
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice
                                 update NonStockInventory
                                 SET  UnitCost=@StocklineUnitPrice
                                WHERE NonStockInventoryId=@StocklineId
                              END
					           SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                               FROM DistributionSetup WITH(NOLOCK)
                               WHERE UPPER(Name)=UPPER('NonStock - Inventory')AND JournalTypeId=7;
					     END
					     
					     IF(UPPER(@StockType) = 'ASSET')
					      BEGIN

						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0))
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice
                                 update AssetInventory
                                 SET  UnitCost=@StocklineUnitPrice
                                WHERE AssetInventoryId=@StocklineId
                               END
					     
					           SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                               FROM DistributionSetup WITH(NOLOCK)
                               WHERE UPPER(Name)=UPPER('Asset - Inventory')AND JournalTypeId=7;
					     END

                              INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                              VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                              SET @JournalBatchDetailId=SCOPE_IDENTITY()
                              INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                              VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                              ------- Goods Received Not Invoiced (GRNI)---
                              SET @Amount=Isnull((@ReceivedQty * @POROUnitPrice), 0);
                              SET @APTotalPrice=@APTotalPrice+@Amount
                              print '2'
                              print @APTotalPrice
                              SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                              from DistributionSetup WITH(NOLOCK)
                              where UPPER(Name)=UPPER('Goods Received Not Invoiced (GRNI)')AND JournalTypeId=7;
                              INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                              VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                              SET @JournalBatchDetailId=SCOPE_IDENTITY()
                              INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                              VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                              ------- Accounts Payable ---
                              SET @Amount=@APTotalPrice
                              print '3'
                              print @APTotalPrice
                              SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                              from DistributionSetup WITH(NOLOCK)
                              where UPPER(Name)=UPPER('Accounts Payable')AND JournalTypeId=7;
                              INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                              VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 0, 0, @Amount, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                              SET @JournalBatchDetailId=SCOPE_IDENTITY()
                              INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                              VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)
                     END
                     else if(Isnull(@StocklineQtyAvail, 0)!=isnull(@ReceivedQty, 0))BEGIN
                          
						  ------- Stock - Inventory ---
                              SET @Amount=((@RRUnitPrice-@POROUnitPrice)* Isnull(@StocklineQtyAvail, 0));
                              SET @APTotalPrice=@APTotalPrice+@Amount

							  IF(UPPER(@StockType) = 'STOCK')
					      BEGIN
						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0))
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice+@POStocklineUnitPrice
                                 update Stockline
                                 SET RepairOrderUnitCost=@RRUnitPrice, UnitCost=@StocklineUnitPrice
                                WHERE StockLineId=@StocklineId
                              END
					          SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                              FROM DistributionSetup WITH(NOLOCK)
                              WHERE UPPER(Name)=UPPER('Stock - Inventory')AND JournalTypeId=7;
					     END
					     
					     IF(UPPER(@StockType) = 'NONSTOCK')
					      BEGIN

						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0))
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice
                                 update NonStockInventory
                                 SET  UnitCost=@StocklineUnitPrice
                                WHERE NonStockInventoryId=@StocklineId
                              END
					           SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                               FROM DistributionSetup WITH(NOLOCK)
                               WHERE UPPER(Name)=UPPER('NonStock - Inventory')AND JournalTypeId=7;
					     END
					     
					     IF(UPPER(@StockType) = 'ASSET')
					      BEGIN

						      IF(@POROUnitPrice !=isnull(@RRUnitPrice, 0))
						      BEGIN
                                 SET @StocklineUnitPrice=@RRUnitPrice
                                 update AssetInventory
                                 SET  UnitCost=@StocklineUnitPrice
                                WHERE AssetInventoryId=@StocklineId
                               END
					     
					           SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                               FROM DistributionSetup WITH(NOLOCK)
                               WHERE UPPER(Name)=UPPER('Asset - Inventory')AND JournalTypeId=7;
					     END

                              
                              INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                              VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                              SET @JournalBatchDetailId=SCOPE_IDENTITY()
                              INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                              VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                              ------- VAR - Cost/Qty - COGS ---
                              SET @Amount=((@RRUnitPrice-@POROUnitPrice)*(@ReceivedQty-Isnull(@StocklineQtyAvail, 0)));
                              SET @APTotalPrice=@APTotalPrice+@Amount
                              SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                              from DistributionSetup WITH(NOLOCK)
                              where UPPER(Name)=UPPER('VAR - Cost/Qty - COGS')AND JournalTypeId=7;
                              INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                              VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                              SET @JournalBatchDetailId=SCOPE_IDENTITY()
                              INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                              VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                              ------- Goods Received Not Invoiced (GRNI)---
                              SET @Amount=isnull((@ReceivedQty * @POROUnitPrice), 0);
                              SET @APTotalPrice=@APTotalPrice+@Amount
                              SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                              from DistributionSetup WITH(NOLOCK)
                              where UPPER(Name)=UPPER('Goods Received Not Invoiced (GRNI)')AND JournalTypeId=7;
                              INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                              VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, @Amount, 0, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                              SET @JournalBatchDetailId=SCOPE_IDENTITY()
                              INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                              VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)

                              ------- Accounts Payable ---
                              SET @Amount=@APTotalPrice
                              SELECT top 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId, @GlAccountId=GlAccountId, @GlAccountNumber=GlAccountNumber, @GlAccountName=GlAccountName
                              from DistributionSetup WITH(NOLOCK)
                              where UPPER(Name)=UPPER('Accounts Payable')AND JournalTypeId=7;
                              INSERT INTO [dbo].[BatchDetails](DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
                              VALUES(@DistributionSetupId, @DistributionName, @JournalBatchHeaderId, 1, @GlAccountId, @GlAccountNumber, @GlAccountName, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 0, 0, @Amount, @ManagementStructureId, @ModuleName, @LastMSLevel, @AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
                              SET @JournalBatchDetailId=SCOPE_IDENTITY()
                              INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType])
                              VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType)
                     END
                 END
                 EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
        end
        SELECT @TotalDebit=SUM(DebitAmount), @TotalCredit=SUM(CreditAmount)
        FROM BatchDetails WITH(NOLOCK)
        where JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0
        group by JournalBatchHeaderId
        SET @TotalBalance=@TotalDebit-@TotalCredit
        Update BatchHeader
        set TotalDebit=@TotalDebit, TotalCredit=@TotalCredit, TotalBalance=@TotalBalance, UpdatedDate=GETUTCDATE(), UpdatedBy=@UpdateBy
        where JournalBatchHeaderId=@JournalBatchHeaderId
        SET @BatchId=@JournalBatchHeaderId;
        END
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@trancount>0 PRINT 'ROLLBACK'
        ROLLBACK TRAN;
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) =db_name(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments VARCHAR(150) ='USP_BatchTriggerBasedonDistribution', @ProcedureParameters VARCHAR(3000) ='@Parameter1 = '''+ISNULL(@JournalBatchHeaderId, '')+'', @ApplicationName VARCHAR(100) ='PAS'
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException @DatabaseName=@DatabaseName, @AdhocComments=@AdhocComments, @ProcedureParameters=@ProcedureParameters, @ApplicationName=@ApplicationName, @ErrorLogID=@ErrorLogID OUTPUT;
        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN (1);
    END CATCH
END