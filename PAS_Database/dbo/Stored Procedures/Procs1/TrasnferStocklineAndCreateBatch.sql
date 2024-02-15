/*************************************************************           
 ** File:   [TrasnferStocklineAndCreateBatch]           
 ** Author: 
 ** Description: This stored procedure is used insert account report in batch FROM Stockline Adjustment.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    08/23/2023   Amit Ghediya	Modify for restrict entry when amount is 0.	
	2    01/01/2024   BHARGAV SALIYA  CONVERT DATE IN UTC
	3    14/02/2023	  Moin Bloch	  Updated Used Distribution Setup Code Insted of Name 
**************************************************************/
-----------------------------------------------------------------------------------------------------
/*************************************************************
-- EXEC [TrasnferStocklineAndCreateBatch] 50573,1,1,9,0,0,0,0,0,0
**************************************************************/
CREATE     PROCEDURE [dbo].[TrasnferStocklineAndCreateBatch]
--@WorkOrderPartNumberId BIGINT
	@StocklineId BIGINT,
	@Qty INT,
	@ManagementStructureId BIGINT,
	@ManagementStructureIdTo BIGINT,
	@SiteIdTo BIGINT,
	@WarehouseIdTo BIGINT,
	@LocationIdTo BIGINT,
	@ShelfIdTo BIGINT,
	@BinIdTo BIGINT,
	@Result bigint =1 OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @NewStocklineId BIGINT;
				DECLARE @PartNumber varchar(100);
				DECLARE @ItemMasterId BIGINT;
				DECLARE @Quantity INT;
				DECLARE @MasterCompanyId BIGINT;
				DECLARE @ConditionId BIGINT;
				DECLARE @StockLineNumber VARCHAR(50);
				DECLARE @StkeNumber VARCHAR(50);
				DECLARE @SerialNumber VARCHAR(50);
				DECLARE @IsPMA BIT;
				DECLARE @IsDER BIT;	
				DECLARE @OEM BIT;
				DECLARE @PurchaseOrderId bigint;
				DECLARE @PurchaseOrderPartRecordId bigint;
				DECLARE @PurchaseOrderUnitCost decimal(18,2);
				DECLARE @InventoryUnitCost decimal(18,2);
				DECLARE @RepairOrderId bigint;
				DECLARE @RepairOrderUnitCost decimal(18,2);
				DECLARE @UnitSalesPrice decimal(18,2);
				DECLARE @CoreUnitCost decimal(18,2);
				DECLARE @CreatedBy VARCHAR(256);
				DECLARE @UpdatedBy VARCHAR(256);
				DECLARE @CreatedDate datetime;
				DECLARE @UpdatedDate datetime;
				DECLARE @QuantityOnHand int;
				DECLARE @QuantityAvailable int;
				DECLARE @QuantityIssued int;
				DECLARE @QuantityReserved int;
				DECLARE @QuantityOnOrder int;
				DECLARE @QtyReserved int;
				DECLARE @QtyIssued int;
				DECLARE @SiteId bigint;
				DECLARE @CNCurrentNumber BIGINT;
				DECLARE @ControlNumber VARCHAR(50);
				DECLARE @IDNumber VARCHAR(50);
				DECLARE @SLCurrentNumber BIGINT;
				DECLARE @EntityMSID BIGINT;
				DECLARE @ModuleID INT;
				DECLARE @ValidUnitCost decimal(18,2)=0;
				SET @ModuleID = 2; -- Stockline Module ID

				SELECT @MasterCompanyId=STK.MasterCompanyId,@Quantity = (STK.QuantityOnHand - @Qty),@QuantityOnHand = (STK.QuantityOnHand - @Qty),@QuantityAvailable = (STK.QuantityOnHand - @Qty),@StkeNumber = STK.StockLineNumber
				FROM dbo.Stockline STK WITH(NOLOCK)
				WHERE STK.StockLineId = @StocklineId

				IF OBJECT_ID(N'tempdb..#tmpCodePrefixestable') IS NOT NULL
				BEGIN
				DROP TABLE #tmpCodePrefixestable
				END
				
				CREATE TABLE #tmpCodePrefixestable
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 CodePrefixId BIGINT NULL,
					 CodeTypeId BIGINT NULL,
					 CurrentNumber BIGINT NULL,
					 CodePrefix VARCHAR(50) NULL,
					 CodeSufix VARCHAR(50) NULL,
					 StartsFrom BIGINT NULL,
				)

				/* PN Manufacturer Combination Stockline logic */
				CREATE TABLE #tmpPNManufacturer
				(
						ID BIGINT NOT NULL IDENTITY, 
						ItemMasterId BIGINT NULL,
						ManufacturerId BIGINT NULL,
						StockLineNumber VARCHAR(100) NULL,
						CurrentStlNo BIGINT NULL,
						isSerialized BIT NULL
				)

				;WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId) AS
				(
					SELECT ac.ItemMasterId, ac.ManufacturerId, MAX(ac.StockLineId) StockLineId
					FROM (SELECT DISTINCT ItemMasterId FROM DBO.Stockline WITH (NOLOCK)) ac1 CROSS JOIN
						(SELECT DISTINCT ManufacturerId FROM DBO.Stockline WITH (NOLOCK)) ac2 LEFT JOIN
						DBO.Stockline ac WITH (NOLOCK)
						ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId
					WHERE ac.MasterCompanyId = @MasterCompanyId
					GROUP BY ac.ItemMasterId, ac.ManufacturerId
					HAVING COUNT(ac.ItemMasterId) > 0
				)

				INSERT INTO #tmpPNManufacturer (ItemMasterId, ManufacturerId, StockLineNumber, CurrentStlNo, isSerialized)
				SELECT CSTL.ItemMasterId, CSTL.ManufacturerId, StockLineNumber, ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo, IM.isSerialized
				FROM CTE_Stockline CSTL INNER JOIN DBO.Stockline STL WITH (NOLOCK) 
				INNER JOIN DBO.ItemMaster IM ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId
				ON CSTL.StockLineId = STL.StockLineId
				/* PN Manufacturer Combination Stockline logic */

				INSERT INTO #tmpCodePrefixestable (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
				SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId IN (30,17,9) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
				
				DECLARE @currentNo AS BIGINT = 0;
				DECLARE @stockLineCurrentNo AS BIGINT;
				DECLARE @ManufacturerId AS BIGINT;

				SELECT @ItemMasterId = ItemMasterId, @ManufacturerId = ManufacturerId FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @StocklineId

				SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId

				IF (@currentNo <> 0)
				BEGIN
					SET @stockLineCurrentNo = @currentNo + 1
				END
				ELSE
				BEGIN
					SET @stockLineCurrentNo = 1
				END

				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixestable WHERE CodeTypeId = 30))
				BEGIN 
					SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@stockLineCurrentNo,(SELECT CodePrefix FROM #tmpCodePrefixestable WHERE CodeTypeId = 30), (SELECT CodeSufix FROM #tmpCodePrefixestable WHERE CodeTypeId = 30)))

					UPDATE DBO.ItemMaster
					SET CurrentStlNo = @stockLineCurrentNo
					WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId
				END
				ELSE 
				BEGIN
					ROLLBACK TRAN;
				END
				
				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixestable WHERE CodeTypeId = 9))
				BEGIN 
					SELECT 
						@CNCurrentNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
							ELSE CAST(StartsFrom AS BIGINT) + 1 END 
					FROM #tmpCodePrefixestable WHERE CodeTypeId = 9

					SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@CNCurrentNumber,(SELECT CodePrefix FROM #tmpCodePrefixestable WHERE CodeTypeId = 9), (SELECT CodeSufix FROM #tmpCodePrefixestable WHERE CodeTypeId = 9)))
				END
				ELSE 
				BEGIN
					ROLLBACK TRAN;
				END
				
				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixestable WHERE CodeTypeId = 17))
				BEGIN 

					SET @IDNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(1,(SELECT CodePrefix FROM #tmpCodePrefixestable WHERE CodeTypeId = 17), (SELECT CodeSufix FROM #tmpCodePrefixestable WHERE CodeTypeId = 17)))
				END
				ELSE 
				BEGIN
					ROLLBACK TRAN;
				END
				
				INSERT INTO [dbo].[Stockline]
				   ([PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId]
				   ,[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo]
				   ,[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber]
				   ,[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId]
				   ,[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber]
				   ,[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER]
				   ,[OEM],[Memo],[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
				   ,[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId]
				   ,[UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace]
				   ,[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId]
				   ,[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId]
				   ,[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved]
				   ,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId]
				   ,[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId]
				   ,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate]
				   ,[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId]
				   ,[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition]
				   ,[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber]
				   ,[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],[CustomerId],[CustomerName],[isCustomerstockType]
				   ,[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType]
				   ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],IsFinishGood
				   )
			 SELECT PartNumber,@StockLineNumber,[StocklineMatchKey],@ControlNumber,ItemmasterId,@Qty,ConditionId
				   ,[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],CASE WHEN ISNULL(@WarehouseIdTo, 0) > 0 THEN @WarehouseIdTo ELSE NULL END,CASE WHEN ISNULL(@LocationIdTo, 0) > 0 THEN @LocationIdTo ELSE NULL END,[ObtainFrom],[Owner],[TraceableTo]
				   ,[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber]
				   ,[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId]
				   ,[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber]
				   ,[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER]
				   ,[OEM],[Memo],@ManagementStructureIdTo,[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE()
				   ,[isSerialized],CASE WHEN ISNULL(@ShelfIdTo, 0) > 0 THEN @ShelfIdTo ELSE NULL END,CASE WHEN ISNULL(@BinIdTo, 0) > 0 THEN @BinIdTo ELSE NULL END,@SiteIdTo,[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId]
				   ,[UnitSalePriceAdjustmentReasonTypeId],@IDNumber,[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace]
				   ,[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],0,[PurchaseOrderPartRecordId]
				   ,[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId]
				   ,0,0,0,@Qty,@Qty,0,[QtyReserved]
				   ,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId]
				   ,[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost], IsCustomerStock,[EntryDate],[LotCost],[NHAItemMasterId]
				   ,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate]
				   ,[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId]
				   ,[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition]
				   ,[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber]
				   ,[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],CustomerId,CustomerName, isCustomerstockType
				   ,[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType]
				   ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],0
			FROM dbo.Stockline WITH(NOLOCK)
			WHERE StockLineId = @StocklineId
			
				SELECT @NewStocklineId = SCOPE_IDENTITY();

				--Get UnitCost FROM Stockline to restrict to add in batch accounting entry.
				SELECT @ValidUnitCost = UnitCost FROM [dbo].[Stockline] WITH(NOLOCK) WHERE StockLineId = @NewStocklineId;

				UPDATE CodePrefixes SET CurrentNummber = @SLCurrentNumber WHERE CodeTypeId = 30 AND MasterCompanyId = @MasterCompanyId

				EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId

				INSERT INTO [dbo].[TimeLife]
					([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair]
					,[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew]
					,[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
					,[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineId],[DetailsNotProvided]
					,[RepairOrderId],[RepairOrderPartRecordId])
				SELECT [CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair]
					,[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew]
					,[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(), GETUTCDATE()
					,[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],@NewStocklineId,[DetailsNotProvided]
					,[RepairOrderId],[RepairOrderPartRecordId] 
				FROM TimeLife TL WITH (NOLOCK) WHERE TL.StockLineId = @StocklineId

				declare @isSerializePart bit=0;

				SELECT @Quantity = (QuantityOnHand - @Qty),@QuantityOnHand = (QuantityOnHand - @Qty),@QuantityAvailable = (QuantityAvailable - @Qty),@StkeNumber = StockLineNumber,@isSerializePart = isSerialized
				FROM dbo.Stockline STK WITH(NOLOCK)
				WHERE STK.StockLineId = @StocklineId

				UPDATE DBO.Stockline SET Quantity = (QuantityOnHand - @Qty),QuantityOnHand = (QuantityOnHand - @Qty),QuantityAvailable = (QuantityAvailable - @Qty)
				WHERE StockLineId = @StocklineId

				UPDATE [dbo].[Stockline] SET Memo = 'This PN has been Transfered. Previous STK: ' + @StkeNumber + ' has been Transfered to STK: ' + @StockLineNumber + ' Date: '+ FORMAT (getdate(), 'dd/MM/yyyy ')
				WHERE StockLineId = @NewStocklineId

				DECLARE @QuantityNew INT;
				DECLARE @QuantityOnHandNew INT;
				DECLARE @QuantityAvailableNew INT;
				declare @isSerializePartNew bit=0;

				SELECT @QuantityNew = (QuantityOnHand),@QuantityOnHandNew = (QuantityOnHand),@QuantityAvailableNew = (QuantityAvailable),@isSerializePartNew = isSerialized
				FROM dbo.Stockline STK WITH(NOLOCK)
				WHERE STK.StockLineId = @NewStocklineId

				EXEC USP_SaveSLMSDetails @ModuleID, @NewStocklineId, @ManagementStructureIdTo, @MasterCompanyId, 'Stockline Adjustment'

				DECLARE @StockAdjustmentModuleID INT=40;
				IF(@isSerializePartNew = 0 AND (@QuantityOnHand > 1))
				BEGIN
					EXEC [dbo].[USP_CreateChildStockline]  @NewStocklineId, @MasterCompanyId, @StockAdjustmentModuleID, 1, 1, 1, 0, 0, 0,0,0
				END
				ELSE
				BEGIN
					EXEC [dbo].[USP_CreateChildStockline]  @NewStocklineId, @MasterCompanyId, @StockAdjustmentModuleID, 1, 0, 0, 0, 0, 1,0,0
				END

				EXEC [dbo].[USP_CreateChildStockline]  @StocklineId, @MasterCompanyId, @StockAdjustmentModuleID, 1, 0, 0, 0, 0, 0,0,0

				SELECT	@Result = @NewStocklineId;

				DECLARE @DistributionMasterId bigint;
				declare @DistributionSetupId int=0
				declare @IsAccountByPass bit=0
				declare @DistributionCode varchar(200);
				Declare @JournalTypeId int
				Declare @JournalTypeCode varchar(200) 
				Declare @JournalBatchHeaderId bigint
				Declare @GlAccountId bigint
				Declare @StatusId int
				Declare @StatusName varchar(200)
				Declare @StartsFrom varchar(200)='00'
				Declare @CurrentNumber bigint
				Declare @GlAccountName varchar(200) 
				Declare @GlAccountNumber varchar(200) 
				Declare @JournalTypename varchar(200) 
				Declare @Distributionname varchar(200);
				declare @CurrentManagementStructureId bigint=0;
				declare @AccountingPeriod varchar(100)
				declare @AccountingPeriodId bigint=0;
				declare @CurrentPeriodId bigint=0;
				declare @Currentbatch varchar(100);
				DECLARE @CodeTypeId AS BIGINT = 74;
				DECLARE @JournalTypeNumber varchar(100);
				declare @batch varchar(100);
				declare @LineNumber int=1;
				Declare @VendorId bigint;
				Declare @VendorName varchar(50);
				DECLARE @ReferenceId bigint=NULL;
				DECLARE @STKMSModuleID bigint=2;
				DECLARE @PurchaseOrderNumber varchar(50)='';
				DECLARE @RepairOrderNumber varchar(50)='';
				declare @LastMSLevel varchar(200);
				declare @AllMSlevels varchar(max);
				declare @TotalDebit decimal(18,2)=0
				declare @TotalCredit decimal(18,2)=0
				declare @TotalBalance decimal(18,2)=0
				declare @UnitPrice decimal(18,2)=0;
				declare @Amount Decimal(18,2)=0;
				Declare @MPNName varchar(200) 
				Declare @PiecePNId bigint
				Declare @PiecePN varchar(200) 
				Declare @PieceItemmasterId bigint;
				DECLARE @ReferencePartId BIGINT=0;
				declare @ModuleName varchar(200)='StocklineAdjustment';
				DECLARE @Desc varchar(100);
				declare @UpdateBy varchar(200);
				DECLARE @JournalBatchDetailId BIGINT=0;
				declare @CommonJournalBatchDetailId bigint=0;
				declare @partId bigint=0

				SELECT @DistributionMasterId =ID FROM DistributionMaster WITH(NOLOCK)  WHERE UPPER(DistributionCode)= UPPER('StocklineAdjustment')

				SELECT @IsAccountByPass =IsAccountByPass FROM DBO.MasterCompany WITH(NOLOCK)  WHERE MasterCompanyId= @MasterCompanyId
				SELECT @DistributionCode =DistributionCode FROM DBO.DistributionMaster WITH(NOLOCK)  WHERE ID= @DistributionMasterId
				SELECT @StatusId =Id,@StatusName=name FROM DBO.BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
				SELECT TOP 1 @JournalTypeId =JournalTypeId FROM DBO.DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId
				SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM DBO.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
				SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM DBO.JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
				SET @CurrentManagementStructureId = @ManagementStructureIdTo;

				IF((@JournalTypeCode ='ADJ') AND @IsAccountByPass=0 AND @ValidUnitCost > 0)
				BEGIN
					  SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName FROM DBO.EntityStructureSetup est WITH(NOLOCK) 
					  INNER JOIN DBO.ManagementStructureLevel msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
					  INNER JOIN DBO.AccountingCalendar acc WITH(NOLOCK) ON msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
					  WHERE est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  and CAST(getdate() as date)   >= CAST(FROMDate as date) and  CAST(getdate() as date) <= CAST(ToDate as date)

					  SELECT @UpdateBy = CreatedBy FROM DBO.Stockline WITH(NOLOCK) WHERE StockLineId=@NewStocklineId;

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

				  IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
                  BEGIN

			              IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
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
                                      (@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,ISNULL(@AccountingPeriodId,0),@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,'RPO');

				          SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
				          UPDATE BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId
						   
                 END
			      ELSE
				  BEGIN
				    	SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
			            SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   					         FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
					   IF(@CurrentPeriodId =0)
					   BEGIN
					      UPDATE DBO.BatchHeader SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
					   END
				  END
			      IF(UPPER(@DistributionCode) = UPPER('StocklineAdjustment'))
	              BEGIN
					  SELECT @VendorId=VendorId,@ReferenceId=StockLineId,@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=StocklineNumber,@Amount = UnitCost,@UpdateBy = CreatedBy
					  FROM DBO.Stockline WITH(NOLOCK) WHERE StockLineId=@NewStocklineId;
					  SELECT @VendorName =VendorName FROM DBO.Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;
					  SELECT @PurchaseOrderNumber=PurchaseOrderNumber FROM DBO.PurchaseOrder WITH(NOLOCK)  WHERE PurchaseOrderId= @PurchaseOrderId;
					  SELECT @RepairOrderNumber=RepairOrderNumber FROM DBO.RepairOrder WITH(NOLOCK)  WHERE RepairOrderId= @RepairOrderId;
						

					  SET @UnitPrice = @Amount;
					  SET @Amount = (@Qty * @Amount);
					  SET @ManagementStructureId = @ManagementStructureIdTo;
	                  SELECT @MPNName = partnumber FROM DBO.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId 
	                  SELECT @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels FROM StocklineManagementStructureDetails WITH(NOLOCK)  WHERE ReferenceID=@NewStocklineId AND ModuleID=@STKMSModuleID
					  Set @ReferencePartId=0

					  SELECT @PieceItemmasterId=ItemMasterId FROM Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId
		              SELECT @PiecePN = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 
				      					SET @Desc = 'Transfer - PN-' + @MPNName + '  SL-' + @StocklineNumber

					  SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId 
					  FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER([DistributionSetupCode]) =UPPER('ADJSPEC') 
					  AND DistributionMasterId=@DistributionMasterId

					  SELECT @GlAccountId=GlAccountId FROM DBO.Stockline WITH(NOLOCK) WHERE StocklineId=@StocklineId;
					  SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName FROM DBO.GLAccount WITH(NOLOCK) WHERE @GlAccountId=GlAccountId;

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
                           (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0,@Amount,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					 SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@PurchaseOrderId,@PurchaseOrderNumber,@RepairOrderId,@RepairOrderNumber,@NewStocklineId,
						@StocklineNumber,'',@Desc,@SiteIdTo,'',@WarehouseIdTo,'',@LocationIdTo,'',@BinIdTo,'',@ShelfIdTo,'','STOCK',@CommonJournalBatchDetailId)

					-----Existing Stockline--------
					SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName 
					FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) = UPPER('ADJSPEC') AND DistributionMasterId=@DistributionMasterId

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
						@StocklineNumber,'',@Desc,@SiteIdTo,'',@WarehouseIdTo,'',@LocationIdTo,'',@BinIdTo,'',@ShelfIdTo,'','STOCK',@CommonJournalBatchDetailId)

					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM CommonBatchDetails WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
			        UPDATE BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

					EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId
				end
					          
				     SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	         
			         SET @TotalBalance =@TotalDebit-@TotalCredit
				         
			         UPDATE BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
					 UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
			 
				END

				IF OBJECT_ID(N'tempdb..#tmpCodePrefixestable') IS NOT NULL
				BEGIN
					DROP TABLE #tmpCodePrefixestable 
				END

				IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL
				BEGIN
					DROP TABLE #tmpPNManufacturer 
				END		
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'TrasnferStocklineAndCreateBatch' 
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