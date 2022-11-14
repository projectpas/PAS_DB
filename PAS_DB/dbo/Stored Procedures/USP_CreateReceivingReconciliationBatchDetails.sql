/*************************************************************           
EXEC [dbo].[USP_CreateReceivingReconciliationBatchDetails] 'RPO',10023,0
************************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateReceivingReconciliationBatchDetails]
@StocklineId bigint=NULL,
@Qty int=0,
@Amount Decimal(18,2),
@ModuleName varchar(200),
@UpdateBy varchar(200),
@DistributionCode varchar(200),
@JournalBatchHeaderId bigint,
@JournalTypename varchar(200),
@StockType varchar(50),
@PackagingId int,
@EmployeeId BIGINT,
@RRId BIGINT,
--@JtypeCode varchar(50),
--@ReceivingReconciliationId bigint,
@BatchId BIGINT OUTPUT
AS
BEGIN
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
			Declare @MPNName varchar(200);
			DECLARE @Desc varchar(100);
			Declare @VendorId bigint;
			Declare @VendorName varchar(50);
			declare @TotalDebit decimal(18,2)=0;
	        declare @TotalCredit decimal(18,2)=0;
	        declare @TotalBalance decimal(18,2)=0;
			DECLARE @STKMSModuleID bigint=2;
			DECLARE @EMPMSModuleID bigint=47;
			IF(UPPER(@DistributionCode) = UPPER('ReceivingPOStockline'))
	              BEGIN

					  Select @WorkOrderNumber=StockLineNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=ItemMasterId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
					  @PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=StocklineNumber
					 ,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
					 @VendorId=VendorId from Stockline where StockLineId=@StocklineId;

					 select @MPNName = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@ItemmasterId;
					 select @VendorName =VendorName from Vendor WITH(NOLOCK)  where VendorId= @VendorId;
					 select @PurchaseOrderNumber=PurchaseOrderNumber from PurchaseOrder WITH(NOLOCK)  where PurchaseOrderId= @PurchaseOrderId;
					  --SET @UnitPrice = @Amount;
					  SET @Amount = (@Qty * @Amount);

		              --SELECT @PieceItemmasterId=ItemMasterId,@UnitPrice=UnitCost,@Amount=(@Qty * UnitCost) from WorkOrderMaterialStockLine  where StockLineId=@StocklineId
					  SELECT @PieceItemmasterId=ItemMasterId from Stockline  where StockLineId=@StocklineId
		              SELECT @PiecePN = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@PieceItemmasterId 

					  IF(@PackagingId > 0)
					  BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('VAR - Cost/Qty - COGS') AND JournalTypeId=6;
						select @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels from EmployeeManagementStructureDetails  where ReferenceID=@EmployeeId AND ModuleID=@EMPMSModuleID;
						Select @VendorId=VendorId,@VendorName =VendorName from ReceivingReconciliationHeader where ReceivingReconciliationId = @RRId;
					  END
					  ELSE
					  BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Goods Received Not Invoiced (GRNI)') AND JournalTypeId=6;
						select @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels from StocklineManagementStructureDetails  where ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID;
					  END

				      --SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Goods Received Not Invoiced (GRNI)') AND JournalTypeId=6;
				     INSERT INTO [dbo].[BatchDetails]
                            (DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
							--[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN] ,
							[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
							--[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber],
							[ManagementStructureId],[ModuleName],
							--Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,
							LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						   --@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,
						   @JournalTypeId ,@JournalTypename ,1,@Amount ,0,
						   --0 ,'',null ,null,null,@CustRefNumber,
						   @ManagementStructureId ,@ModuleName,
						   --@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,
						   @LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)


					SET @JournalBatchDetailId=SCOPE_IDENTITY()

					SET @Desc = 'Receiving PO-' + @PurchaseOrderNumber + '  PN-' + @MPNName + '  SL-' + @StocklineNumber

					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType)


					EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
				end
				ELSE IF(UPPER(@DistributionCode) = UPPER('ReceivingROStockline'))
	              BEGIN

					  Select @WorkOrderNumber=StockLineNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=ItemMasterId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
					  @PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=StocklineNumber
					 ,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
					 @VendorId=VendorId from Stockline where StockLineId=@StocklineId;

					 select @MPNName = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@ItemmasterId;
					 select @VendorName =VendorName from Vendor WITH(NOLOCK)  where VendorId= @VendorId;
					 --select @PurchaseOrderNumber=PurchaseOrderNumber from PurchaseOrder WITH(NOLOCK)  where PurchaseOrderId= @PurchaseOrderId;
					 select @RepairOrderNumber=RepairOrderNumber from RepairOrder WITH(NOLOCK)  where RepairOrderId= @RepairOrderId;
					  --SET @UnitPrice = @Amount;
					  SET @Amount = (@Qty * @Amount);

		              --SELECT @PieceItemmasterId=ItemMasterId,@UnitPrice=UnitCost,@Amount=(@Qty * UnitCost) from WorkOrderMaterialStockLine  where StockLineId=@StocklineId
					  SELECT @PieceItemmasterId=ItemMasterId from Stockline  where StockLineId=@StocklineId
		              SELECT @PiecePN = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@PieceItemmasterId 
				      
					  IF(@PackagingId > 0)
					  BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('VAR - Cost/Qty - COGS') AND JournalTypeId=7;
						select @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels from EmployeeManagementStructureDetails  where ReferenceID=@EmployeeId AND ModuleID=@EMPMSModuleID;
						Select @VendorId=VendorId,@VendorName =VendorName from ReceivingReconciliationHeader where ReceivingReconciliationId = @RRId;
					  END
					  ELSE
					  BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Goods Received Not Invoiced (GRNI)') AND JournalTypeId=7;
						select @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels from StocklineManagementStructureDetails  where ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID;
					  END
					  --SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Goods Received Not Invoiced (GRNI)') AND JournalTypeId=7;
				     INSERT INTO [dbo].[BatchDetails]
                            (DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
							--[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN] ,
							[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
							--[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber],
							[ManagementStructureId],[ModuleName],
							--Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,
							LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						   --@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,
						   @JournalTypeId ,@JournalTypename ,1,@Amount ,0,
						   --0 ,'',null ,null,null,@CustRefNumber,
						   @ManagementStructureId ,@ModuleName,
						   --@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,
						   @LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)


					SET @JournalBatchDetailId=SCOPE_IDENTITY()

					
					SET @Desc = 'Receiving RO-' + @RepairOrderNumber + '  PN-' + @MPNName + '  SL-' + @StocklineNumber

					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@StocklineId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StockType)


					EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
				end
					          
				     SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	         
			         SET @TotalBalance =@TotalDebit-@TotalCredit
				         
			         Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   where JournalBatchHeaderId= @JournalBatchHeaderId

					 SET @BatchId=@JournalBatchHeaderId;

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
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@JournalBatchHeaderId, '') + ''
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