/*************************************************************
 ** File:   [USP_SaveSettlementFinalConditionForInternalKitAssembly]
 ** Author:   Moin Bloch
 ** Description: This stored procedure saves the final-condition disposition for an
 **              Internal Kit Assembly work order part, one row per kit serial number.
 ** Purpose:
 ** Date:   28/08/2026
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    28/08/2026   Moin Bloch 	        Created
**************************************************************/
CREATE PROCEDURE [dbo].[USP_SaveSettlementFinalConditionForInternalKitAssembly]
(
    @WOSettlementKitList [dbo].[WOSettlementKitListType] READONLY
)
AS
BEGIN
    SET NOCOUNT ON;

		DECLARE @TotalRecord INT = 0;
		DECLARE @MinId BIGINT = 1;
		DECLARE @UpdatedDate DATETIME2(7) =  GETUTCDATE()
		DECLARE @IdCodeTypeId BIGINT,@ControlNumberCodeTypeId BIGINT,@IdNumberCodeTypeId BIGINT,@WorkOrderClosedStatusId INT=0
		DECLARE @StkManagementStructureModuleId BIGINT=0,@StockLineModuleID INT=0,@IsUnique BIT = 0

		DECLARE @WOModuleId INT = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder')

		SELECT @IdCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Stock Line';
		SELECT @ControlNumberCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Control Number';
		SELECT @IdNumberCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Id Number';

		SELECT @StockLineModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='StockLine';
		SELECT @StkManagementStructureModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline';

	    SELECT @WorkOrderClosedStatusId = [Id] FROM [dbo].[WorkOrderStatus] WHERE Description = 'Closed'


		DECLARE @WorkOrderId         BIGINT = NULL,
		  	    @WorkOrderPartNoId   BIGINT = NULL,
				@WorkFlowWorkOrderId BIGINT = NULL,
				@SubWorkOrderId      BIGINT = NULL,
				@SubWOPartNoId       BIGINT = NULL,
				@FinalConditionId    BIGINT = NULL,
				@IsSubWorkOrder      BIT = 0,
				@UpdatedBy           VARCHAR(256) = NULL,
				@RevisedPartId       BIGINT = NULL,
				@SerialNumber        VARCHAR(100) = NULL,
				@MasterCompanyId     INT = NULL

		IF OBJECT_ID(N'tempdb..#tmprSettlementFinalConditionKit') IS NOT NULL
		BEGIN
			DROP TABLE #tmprSettlementFinalConditionKit
		END

		CREATE TABLE #tmprSettlementFinalConditionKit
		(
			[ID] BIGINT NOT NULL IDENTITY,
			[WorkOrderId]         BIGINT NULL,
            [WorkOrderPartNoId]   BIGINT NULL,
            [WorkFlowWorkOrderId] BIGINT NULL,
            [SubWorkOrderId]      BIGINT NULL,
            [SubWOPartNoId]       BIGINT NULL,
            [FinalConditionId]    BIGINT NULL,
            [IsSubWorkOrder]      BIT NULL,
            [UpdatedBy]           VARCHAR(256) NULL,
            [RevisedPartId]       BIGINT NULL,
            [SerialNumber]        VARCHAR(100) NULL
		)

		IF OBJECT_ID(N'tempdb..#ProcessedStockLine') IS NOT NULL
		BEGIN
			DROP TABLE #ProcessedStockLine
		END

		CREATE TABLE #ProcessedStockLine
		(
			[StockLineId] BIGINT NOT NULL PRIMARY KEY
		)

		INSERT INTO #tmprSettlementFinalConditionKit ([WorkOrderId],[WorkOrderPartNoId],[WorkFlowWorkOrderId],[SubWorkOrderId],[SubWOPartNoId],[FinalConditionId],[IsSubWorkOrder],[UpdatedBy],[RevisedPartId],[SerialNumber])
		SELECT [WorkOrderId],[WorkOrderPartNoId],[WorkFlowWorkOrderId],[SubWorkOrderId],[SubWOPartNoId],[FinalConditionId],[IsSubWorkOrder],[UpdatedBy],[RevisedPartId],[SerialNumber]  FROM @WOSettlementKitList

		SELECT @TotalRecord = COUNT(*), @MinId = MIN([ID]) FROM #tmprSettlementFinalConditionKit WITH (NOLOCK)

		BEGIN TRY
		BEGIN TRANSACTION

		WHILE @MinId <= @TotalRecord
		BEGIN
			DECLARE @Stocklineid BIGINT = 0
			DECLARE @PreviousStockLineNumber VARCHAR(50),@StockLineNumber VARCHAR(50),@CNCurrentNumber BIGINT,@ControlNumber VARCHAR(50);     
			DECLARE @IDNumber VARCHAR(50),@PartNumber VARCHAR(50)  
			DECLARE @CurrentIndex BIGINT = 0, @CurrentIdNumber BIGINT,@ReceiverNumber VARCHAR(50);
			DECLARE @ManagementStructureId BIGINT = NULL,@KitsToPrepare INT = 0,@TotalPartsCount INT = 0
			DECLARE @TotalCost DECIMAL(18,6) = 0
			
			SELECT  @WorkOrderId         = [WorkOrderId],
					@WorkOrderPartNoId   = [WorkOrderPartNoId],
					@WorkFlowWorkOrderId = [WorkFlowWorkOrderId],	
					@FinalConditionId    = [FinalConditionId],					
					@UpdatedBy           = [UpdatedBy],
					@RevisedPartId       = [RevisedPartId],
					@SerialNumber        = [SerialNumber]
			FROM #tmprSettlementFinalConditionKit WHERE [ID] = @MinId

			SELECT @TotalPartsCount = COUNT(*) FROM #tmprSettlementFinalConditionKit WHERE [WorkOrderId] = @WorkOrderId AND [WorkOrderPartNoId] = @WorkOrderPartNoId;
			
			SELECT @KitsToPrepare = ISNULL([KitsToPrepare],0),@Stocklineid = [Stocklineid],@MasterCompanyId = [MasterCompanyId],@ManagementStructureId = [ManagementStructureId] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [ID] = @WorkOrderPartNoId;

			SELECT @TotalCost = ISNULL(SUM([TotalCost]), 0) FROM [dbo].[WorkOrderMPNCostDetails] WITH (NOLOCK)	WHERE [WorkOrderId] = @WorkOrderId AND [WOPartNoId] = @WorkOrderPartNoId;

			SELECT @TotalCost / @KitsToPrepare

			IF(ISNULL(@StockLineId, 0) > 0)
			BEGIN				
				IF (ISNULL(@StockLineId, 0) > 0	AND NOT EXISTS (SELECT 1 FROM #ProcessedStockLine WHERE [StockLineId] = @StockLineId))
				BEGIN
					UPDATE [dbo].[Stockline]
					   SET [QuantityAvailable] = 0,
						   [QuantityOnHand] = 0,
						   [QuantityIssued] = 0,
						   [QuantityReserved] = 0,
						   [UpdatedBy] = @UpdatedBy,
						   [UpdatedDate] = GETUTCDATE()
					 WHERE [StockLineId] = @StockLineId

					DECLARE @StocklineHistoryUnReserveRemoveOnHandActionEnum INT = 0

					SELECT @StocklineHistoryUnReserveRemoveOnHandActionEnum = [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type]='UnReserve-RemoveOnHand';

					EXEC [dbo].[USP_AddUpdateStocklineHistory] @StockLineId,@WOModuleId,@WorkOrderId,NULL,NULL,@StocklineHistoryUnReserveRemoveOnHandActionEnum,0,@UpdatedBy;

					INSERT INTO #ProcessedStockLine ([StockLineId]) VALUES (@StockLineId);

					-- FINISH GOOD  AND CLOSE PART
					UPDATE [dbo].[WorkOrderPartNumber] SET [IsFinishGood] = 1, [IsClosed] = 1 WHERE [WorkOrderId] = @WorkOrderId AND [ID] = @WorkOrderPartNoId;

					-- CLOSED WORK ORDER
					UPDATE [dbo].[WorkOrder] SET [WorkOrderStatusId] = @WorkOrderClosedStatusId WHERE [WorkOrderId] = @WorkOrderId
				END				
				
				IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL  
				BEGIN  
					DROP TABLE #tmpCodePrefixes  
				END  

				IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL  
				BEGIN  
					DROP TABLE #tmpPNManufacturer  
				END  
      
				CREATE TABLE #tmpCodePrefixes  
				(  
				  [ID] BIGINT NOT NULL IDENTITY,   
				  [CodePrefixId] BIGINT NULL,  
				  [CodeTypeId] BIGINT NULL,  
				  [CurrentNumber] BIGINT NULL,  
				  [CodePrefix] VARCHAR(50) NULL,  
				  [CodeSufix] VARCHAR(50) NULL,  
				  [StartsFrom] BIGINT NULL,  
				)  
  
				/* PN Manufacturer Combination Stockline logic */  
				CREATE TABLE #tmpPNManufacturer  
				(  
				  [ID] BIGINT NOT NULL IDENTITY,   
				  [ItemMasterId] BIGINT NULL,  
				  [ManufacturerId] BIGINT NULL,  
				  [StockLineNumber] VARCHAR(100) NULL,  
				  [CurrentStlNo] BIGINT NULL,  
				  [isSerialized] BIT NULL  
				)  
  
				;WITH CTE_Stockline ([ItemMasterId],[ManufacturerId],[StockLineId]) AS  
				(  
				 SELECT ac.[ItemMasterId],ac.[ManufacturerId], MAX(ac.[StockLineId]) StockLineId  
				 FROM (SELECT DISTINCT [ItemMasterId] FROM [dbo].[Stockline] WITH (NOLOCK)) ac1 CROSS JOIN  
				  (SELECT DISTINCT [ManufacturerId] FROM [dbo].[Stockline] WITH (NOLOCK)) ac2 LEFT JOIN  
				  [dbo].[Stockline] ac WITH (NOLOCK)  
				  ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId  
					 WHERE ac.MasterCompanyId = @MasterCompanyId  
					 GROUP BY ac.ItemMasterId, ac.ManufacturerId  
					 HAVING COUNT(ac.ItemMasterId) > 0  
				)  
  
				INSERT INTO #tmpPNManufacturer ([ItemMasterId], [ManufacturerId], [StockLineNumber], [CurrentStlNo], [isSerialized])  
				SELECT CSTL.[ItemMasterId], CSTL.[ManufacturerId], [StockLineNumber], ISNULL(IM.[CurrentStlNo], 0) AS [CurrentStlNo], IM.[isSerialized]
				FROM CTE_Stockline CSTL INNER JOIN [dbo].[Stockline] STL WITH (NOLOCK)   
				INNER JOIN [dbo].[ItemMaster] IM ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId  
				ON CSTL.StockLineId = STL.StockLineId  				
				/* PN Manufacturer Combination Stockline logic */    
				WHERE ISNULL(IM.IsNonStock,0) = 0

				INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)   
					SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
					FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId  
					WHERE CT.CodeTypeId IN (@IdCodeTypeId,@IdNumberCodeTypeId,@ControlNumberCodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;  
  
				IF(@CurrentIndex = 0)
				BEGIN
					SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END
					FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
				END
				ELSE
				BEGIN
					SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END
					FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
				END

				DECLARE @currentNo AS BIGINT = 0;  
				DECLARE @stockLineCurrentNo AS BIGINT;  
				DECLARE @ItemMasterId AS BIGINT;  
				DECLARE @ManufacturerId AS BIGINT;  
  
				SELECT @ItemMasterId = CASE WHEN ISNULL(@RevisedPartId, 0) > 0 THEN @RevisedPartId ELSE [ItemMasterId] END, 
					   @ManufacturerId = ManufacturerId, 
					   @PreviousStockLineNumber = StockLineNumber		 
				 FROM dbo.Stockline WITH(NOLOCK) WHERE [StockLineId] = @StocklineId
    
				SET @ReceiverNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentIdNumber, 'RecNo', (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))

				SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId  
  				
				IF (@currentNo <> 0)  
				BEGIN  
				 SET @stockLineCurrentNo = @currentNo + 1  
				END  
				ELSE  
				BEGIN  
				 SET @stockLineCurrentNo = 1  
				END  
  
				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId))  
				BEGIN   
					SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@stockLineCurrentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))  
  
					 UPDATE DBO.ItemMaster  
					 SET CurrentStlNo = @stockLineCurrentNo  
					 WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId  
				END  
				ELSE   
				BEGIN  
				 ROLLBACK TRAN;  
				END  
  
				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @ControlNumberCodeTypeId))  
				BEGIN   
					SELECT @CNCurrentNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END   
					FROM #tmpCodePrefixes WHERE CodeTypeId = @ControlNumberCodeTypeId 
  
					SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CNCurrentNumber,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @ControlNumberCodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @ControlNumberCodeTypeId)))  
				END  
				ELSE   
				BEGIN  
					ROLLBACK TRAN;  
				END  
  
				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdNumberCodeTypeId))  
				BEGIN     
					SET @IDNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(1,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdNumberCodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdNumberCodeTypeId)))  
				END  
				ELSE   
				BEGIN  
					ROLLBACK TRAN;  
				END  

				DECLARE @IntegrationPortal VARCHAR(50)
				SELECT @IntegrationPortal = STRING_AGG(CAST(mp.[IntegrationPortalId] AS VARCHAR), ',')
				FROM [dbo].[ItemMaster] iM WITH(NOLOCK)
				LEFT JOIN [dbo].[ItemMasterIntegrationPortal] mp WITH(NOLOCK) ON iM.ItemMasterId = mp.ItemMasterId
				LEFT JOIN [dbo].[IntegrationPortal] ip WITH(NOLOCK) ON mp.IntegrationPortalId = ip.IntegrationPortalId
				WHERE iM.ItemMasterId = @ItemMasterId AND iM.MasterCompanyId = @MasterCompanyId AND mp.IntegrationPortalId IS NOT NULL
				 AND ISNULL(iM.IsNonStock,0) = 0 GROUP BY iM.ItemMasterId				 

				DECLARE @QtyOrder DECIMAL(18,6),@SiteId BIGINT,@WarehouseId BIGINT = NULL,@LocationId BIGINT = NULL, @ShelfId BIGINT = NULL,@BinId BIGINT= NULL
				DECLARE @GLAccountId BIGINT = NULL,@IsPMA BIT,@IsDER BIT,@IsOEM BIT,@PurchaseUnitOfMeasureId BIGINT = NULL
				DECLARE @ItemGroup VARCHAR(256) = NULL,@ItemType VARCHAR(20) = 'Stock'
				DECLARE @CreatedDate DATETIME2(7) = GETUTCDATE(),@LegalEntityId BIGINT,@IsSerialized BIT
				DECLARE @Memo NVARCHAR(MAX) ='Stockline Created From Internal Kit Assembly Settlement'
				DECLARE @ObtainFromType INT=4, @OwnerType INT=4, @TraceableToType INT=4
				DECLARE @Quantity DECIMAL(18,6) = 1,@QuantityReserved DECIMAL(18,6) = 0,@QuantityIssued DECIMAL(18,6) = 0,@QuantityOnHand DECIMAL(18,6) = 0,@QuantityAvailable DECIMAL(18,6) = 0,@QtyReserved DECIMAL(18,6) = 0,@QtyIssued DECIMAL(18,6) = 0
				DECLARE @IsCustomerStock BIT = 0,@ItemTypeId INT= 1
				DECLARE @UnitCost DECIMAL(18,6) = 0,@IsStkTimeLife BIT,@ItemNonStockClassificationId BIGINT
				DECLARE @NewStocklineId BIGINT = 0, @IsNonStock BIT = 0,@IsService BIT = 0								

				SELECT @LegalEntityId = [LegalEntityId] FROM [dbo].[ManagementStructure] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ManagementStructureId] = @ManagementStructureId;

				SELECT @PartNumber = ITM.[PartNumber], 
					   @ManufacturerId = ITM.[ManufacturerId],	
					   @ItemTypeId = ITM.[ItemTypeId],
					   @ItemType = IY.[Description],					  			   
					   @SiteId = ITM.[SiteId],
					   @WarehouseId = ITM.[WarehouseId], 
					   @LocationId = ITM.[LocationId],
					   @ShelfId = ITM.[ShelfId],
					   @BinId =  ITM.[BinId],
					   @GLAccountId = ITM.[GLAccountId],
					   @IsPMA = ITM.IsPMA,
					   @IsDER = ITM.IsDER,	 
					   @IsOEM = ITM.IsOEM,
					   @IsCustomerStock = 0,              					   
					   @UnitCost = ISNULL(@TotalCost / NULLIF(@KitsToPrepare, 0), 0),
					   @IsSerialized = ITM.IsSerialized,  
					   @PurchaseUnitOfMeasureId = ITM.[PurchaseUnitOfMeasureId],
					   @ItemGroup = ITM.ItemGroup,
					   @Quantity = CASE WHEN @TotalPartsCount = 1 THEN @KitsToPrepare ELSE 1 END,             
					   @QuantityOnHand  = CASE WHEN @TotalPartsCount = 1 THEN @KitsToPrepare ELSE 1 END,             
					   @QuantityAvailable= CASE WHEN @TotalPartsCount = 1 THEN @KitsToPrepare ELSE 1 END,  		  
					   @IsStkTimeLife = ITM.[isTimeLife],
					   @ItemNonStockClassificationId = ITM.[ItemClassificationId],
					   @IsNonStock = ISNULL([IsNonStock],0),
					   @IsService = ISNULL([IsService],0)
				  FROM [dbo].[ItemMaster] ITM WITH (NOLOCK)
				  LEFT JOIN [dbo].[ItemType] IY WITH (NOLOCK) ON ITM.[ItemTypeId] = IY.[ItemTypeId]
				 WHERE ITM.[ItemMasterId] = @RevisedPartId;
				 			
				INSERT INTO [dbo].[Stockline] ([PartNumber], [StockLineNumber], [StocklineMatchKey], [ControlNumber], [ItemMasterId], [Quantity], [ConditionId], [SerialNumber], [ShelfLife], 
					[ShelfLifeExpirationDate], [WarehouseId], [LocationId], [ObtainFrom], [Owner], [TraceableTo], [ManufacturerId], [Manufacturer], [ManufacturerLotNumber], [ManufacturingDate],		  
					[ManufacturingBatchNumber], [PartCertificationNumber], [CertifiedBy], [CertifiedDate], [TagDate], [TagType], [CertifiedDueDate], [CalibrationMemo], [OrderDate], [PurchaseOrderId], 
					[PurchaseOrderUnitCost], [InventoryUnitCost], [RepairOrderId], [RepairOrderUnitCost], [ReceivedDate], [ReceiverNumber], [ReconciliationNumber], [UnitSalesPrice], [CoreUnitCost], 
					[GLAccountId], [AssetId], [IsHazardousMaterial], [IsPMA], [IsDER], [OEM], [Memo], [ManagementStructureId], [LegalEntityId], [MasterCompanyId], [CreatedBy], [UpdatedBy], 
					[isSerialized], [ShelfId], [BinId], [SiteId], [ObtainFromType], [OwnerType], [TraceableToType], [UnitCostAdjustmentReasonTypeId], [UnitSalePriceAdjustmentReasonTypeId], 
					[IdNumber], [QuantityToReceive], [PurchaseOrderExtendedCost], [ManufacturingTrace], [ExpirationDate], [AircraftTailNumber], [ShippingViaId], [EngineSerialNumber], 
					[QuantityRejected], [PurchaseOrderPartRecordId], [ShippingAccount], [ShippingReference], [TimeLifeCyclesId], [TimeLifeDetailsNotProvided], [WorkOrderId], [WorkOrderMaterialsId], 
					[QuantityReserved], [QuantityTurnIn], [QuantityIssued], [QuantityOnHand], [QuantityAvailable], [QuantityOnOrder], [QtyReserved], [QtyIssued], [BlackListed], [BlackListedReason], 
					[Incident], [IncidentReason], [Accident], [AccidentReason], [RepairOrderPartRecordId], [isActive], [isDeleted], [WorkOrderExtendedCost], [RepairOrderExtendedCost], [IsCustomerStock],
					[EntryDate], [LotCost], [NHAItemMasterId], [TLAItemMasterId], [ItemTypeId], [AcquistionTypeId], [RequestorId], [LotNumber], [LotDescription], [TagNumber], [InspectionBy], 
					[InspectionDate], [VendorId], [IsParent], [ParentId], [IsSameDetailsForAllParts], [WorkOrderPartNoId], [SubWorkOrderId], [SubWOPartNoId], [IsOemPNId], [PurchaseUnitOfMeasureId],
					[ObtainFromName], [OwnerName], [TraceableToName], [Level1], [Level2], [Level3], [Level4], [Condition], [GlAccountName], [Site], [Warehouse], [Location], [Shelf], [Bin], 
					[UnitOfMeasure], [WorkOrderNumber], [itemGroup], [TLAPartNumber], [NHAPartNumber], [TLAPartDescription], [NHAPartDescription], [itemType], [CustomerId], [CustomerName], 
					[isCustomerstockType], [PNDescription], [RevicedPNId], [RevicedPNNumber], [OEMPNNumber], [TaggedBy], [TaggedByName], [UnitCost], [TaggedByType], [TaggedByTypeName], [CertifiedById], 
					[CertifiedTypeId], [CertifiedType], [CertTypeId], [CertType], [TagTypeId], [IsFinishGood], [IsTurnIn], [IsCustomerRMA], [RMADeatilsId], [DaysReceived], [ManufacturingDays],		  
					[TagDays], [OpenDays], [ExchangeSalesOrderId], [RRQty], [SubWorkOrderNumber], [IsManualEntry], [WorkOrderMaterialsKitId], [LotId], [IsLotAssigned], [LOTQty], [LOTQtyReserve],
					[OriginalCost], [POOriginalCost], [ROOriginalCost], [VendorRMAId], [VendorRMADetailId], [LotMainStocklineId], [IsFromInitialPO], [LotSourceId], [Adjustment], [SalesOrderPartId], 
					[FreightAdjustment], [TaxAdjustment], [IsStkTimeLife], [SalesPriceExpiryDate], [SubWorkOrderMaterialsId], [SubWorkOrderMaterialsKitId], [EvidenceId], [IntegrationPortal],
					[IsGenerateReleaseForm], [ExistingCustomerId], [RepairOrderNumber], [ExistingCustomer], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate], [InventoryGLSettingId], 
					[InventoryGLAccName], [GoodsReceivedNotInvoicesGLAccId], [GoodsReceivedNotInvoicesGLAccName], [WorkInProgressGLAccId], [WorkInProgressGLAccName], [InventoryToBillGLAccId], 
					[InventoryToBillGLAccName], [FinishedGoodsGLAccId], [FinishedGoodsGLAccName], [InventoryExchAgreementGLAccId], [InventoryExchAgreementGLAccName], [InventoryReserveGLAccId], 
					[InventoryReserveGLAccName], [COGS_WorkOrderGLAccId], [COGS_WorkOrderGLAccName], [COGS_SalesOrderGLAccId], [COGS_SalesOrderGLAccName], [COGS_QtyVarianceGLAccId], 
					[COGS_QtyVarianceGLAccName], [COGS_UnitCostVarianceGLAccId], [COGS_UnitCostVarianceGLAccName], [RevenueMroGLAccId], [RevenueMroGLAccName], [RevenueSoGLAccId],
					[RevenueSoGLAccName], [RevenueExchGLAccId], [RevenueExchGLAccName], [COGS_ExchSalesOrderGLAccId], [COGS_ExchSalesOrderGLAccName], [QuantityAdjustment], [IsPiecePart], 
					[IsRepairManagement], [IsDocument], [PurchaseOrderNumber], [IsBatchStock], [BatchNumber], [IsReadyReleaseForm], [AircraftInstalledPartDetailsId], [AircraftSN], [TotalTSN], 
					[TotalCSN], [TotalTSNMM], [TotalCSNMM], [PoPartUnitCost], [TransferredFromLotId], [TransferredFromLotNumber], [Note], [IsNonStock], [Currency], [CurrencyId], 
					[ItemNonStockClassificationId], [NonStockClassification], [IsService], [CreatedDate], [UpdatedDate])
				SELECT @PartNumber, @StockLineNumber, NULL, @ControlNumber, @ItemMasterId, @Quantity, @FinalConditionId, @SerialNumber, 0 
				    ,NULL, @WarehouseId, @LocationId, NULL, NULL, NULL, @ManufacturerId, NULL, NULL, NULL		  
					,NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, @CreatedDate, NULL 					
					,0, 0, NULL, 0, @CreatedDate, @ReceiverNumber, NULL, 0, 0 					
					,@GLAccountId, NULL, 0, @IsPMA, @IsDER, @IsOEM, @Memo, @ManagementStructureId, @LegalEntityId, @MasterCompanyId, @UpdatedBy, @UpdatedBy
					,@IsSerialized, @ShelfId, @BinId, @SiteId, @ObtainFromType, @OwnerType, @TraceableToType, NULL, NULL					
					,@IDNumber, 0, 0, NULL, NULL, NULL, 0, NULL
					,0, NULL, NULL, NULL, NULL, 0, @WorkOrderId, NULL
					,@QuantityReserved, 0, @QuantityIssued, @QuantityOnHand, @QuantityAvailable, 0, @QtyReserved, @QtyIssued, 0, NULL
					,0, NULL, 0, NULL, NULL, 1, 0, 0.00, 0.00, @IsCustomerStock
					,@CreatedDate , 0.00, NULL, NULL, @ItemTypeId, NULL, NULL, NULL, NULL, NULL, NULL					
					,NULL , NULL, 1, 0, 0, @WorkOrderPartNoId, NULL, NULL, NULL, @PurchaseUnitOfMeasureId					
					,NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', '', ''
					,NULL, '', @ItemGroup, '', '', '', '', @ItemType, NULL, ''
					,@IsCustomerStock, NULL, NULL, '', '', '', '', @UnitCost, NULL, '', NULL							  
					,NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, NULL, 0, 0
					,NULL, 0, NULL, 0, '', NULL, NULL, NULL, 0, NULL, NULL
					,NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 0.00, NULL
					,0.00, 0.00, @IsStkTimeLife, NULL, NULL, NULL, 0, NULL
					,0, NULL, NULL, NULL, NULL, 0, NULL, NULL
					,'', NULL, NULL, NULL, NULL, NULL 
					,NULL, NULL, NULL, NULL, NULL, NULL
					,NULL, NULL, NULL, NULL, NULL, NULL
					,NULL, NULL, NULL, NULL, NULL, NULL
					,NULL, NULL, NULL, NULL, NULL, 0, 0
					,0, 0, NULL, 0, NULL, 0, NULL, NULL, NULL
					,NULL, NULL, NULL, NULL, NULL, NULL, NULL, @IsNonStock , NULL, NULL
					,NULL, NULL, @IsService, @CreatedDate, @CreatedDate

				SELECT @NewStocklineId = SCOPE_IDENTITY();    		
		
				UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @stockLineCurrentNo WHERE [CodeTypeId] = @IdCodeTypeId AND [MasterCompanyId] = @MasterCompanyId;
				UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @CNCurrentNumber WHERE [CodeTypeId] = @ControlNumberCodeTypeId AND MasterCompanyId = @MasterCompanyId;

				EXEC dbo.[USP_SaveSLMSDetails] @StkManagementStructureModuleId,@NewStocklineId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy;

				EXEC [dbo].[UpdateStocklineColumnsWithId] @NewStocklineId;

				EXEC [dbo].[USP_AddUpdateStocklineHistory] @NewStocklineId,@StockLineModuleID,@NewStocklineId,NULL,NULL,1,@QuantityOnHand,@UpdatedBy;		
				
			END
						
			SET @MinId = @MinId + 1

		END

		IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL  
		BEGIN  
			DROP TABLE #tmpCodePrefixes   
		END

	COMMIT TRANSACTION;
	END TRY
    BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_SaveSettlementFinalConditionForInternalKitAssembly'
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, 0) AS VARCHAR(100))
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