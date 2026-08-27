/*************************************************************           
 ** File:   [USP_CreateStocklineForNosStockSalesOrderPart]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to create stockline for Non-Stock
 ** Purpose:         
 ** Date: 30-07-2026
          
 ** PARAMETERS: 

 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    30-07-2026	  Moin Bloch	Created 
	2    26-08-2026   Ayushi Patel  [PN-17781] changed qty fields data type from int to decimal
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateStocklineForNosStockSalesOrderPart]
@SalesOrderId BIGINT = 0,
@SalesOrderPartId BIGINT = 0,
@ItemMasterId BIGINT = 0,
@CreatedBy  VARCHAR(100) = '',
@MasterCompanyId BIGINT = 0,
@StockLineId BIGINT = 0 OUTPUT 
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		BEGIN TRANSACTION

		DECLARE @PartNumber VARCHAR(50),@ManufacturerId BIGINT, @ConditionId BIGINT,@QtyOrder DECIMAL(18,6),@SerialNumber VARCHAR(30) = ''
		DECLARE @SiteId BIGINT,@WarehouseId BIGINT = NULL,@LocationId BIGINT = NULL, @ShelfId BIGINT = NULL,@BinId BIGINT= NULL
		DECLARE @GLAccountId BIGINT = NULL,@IsPMA BIT,@IsDER BIT,@IsOEM BIT,@PurchaseUnitOfMeasureId BIGINT = NULL
		DECLARE @ItemGroup VARCHAR(256) = NULL,@ItemType VARCHAR(20) = 'Non-Stock'
		DECLARE @CreatedDate DATETIME2(7) = GETUTCDATE(),@ManagementStructureId BIGINT,@LegalEntityId BIGINT,@IsSerialized BIT
		DECLARE @Memo NVARCHAR(MAX) ='Stockline Created For Sales Order Non-Stock Item'
		DECLARE @ObtainFromType INT=4, @OwnerType INT=4, @TraceableToType INT=4
		DECLARE @QuantityReserved DECIMAL(18,6) = 0,@QuantityIssued DECIMAL(18,6) = 0,@QuantityOnHand DECIMAL(18,6) = 0,@QuantityAvailable DECIMAL(18,6) = 0,@QtyReserved DECIMAL(18,6) = 0,@QtyIssued DECIMAL(18,6) = 0
		DECLARE @IsCustomerStock BIT = 0,@ItemTypeId INT= 2
		DECLARE @UnitCost DECIMAL(18,2) = 0,@IsStkTimeLife BIT,@ItemNonStockClassificationId BIGINT
		DECLARE @StkManagementStructureModuleId BIGINT=0,@StockLineModuleID INT=0

		SELECT @ManagementStructureId = SO.[ManagementStructureId] FROM [dbo].[SalesOrder] SO WITH(NOLOCK) WHERE [SalesOrderId] = @SalesOrderId

		SELECT @LegalEntityId = [LegalEntityId] FROM [dbo].[ManagementStructure] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ManagementStructureId] = @ManagementStructureId;

		SELECT @PartNumber = ITM.[PartNumber], 
		       @ManufacturerId = ITM.[ManufacturerId],
			   @ConditionId = SOP.[ConditionId],
			   @QtyOrder = ISNULL(SOP.[QtyOrder],0),
			   @SiteId = ITM.[SiteId],
			   @WarehouseId = ITM.[WarehouseId], 
			   @LocationId = ITM.[LocationId],
			   @ShelfId = ITM.[ShelfId],
			   @BinId =  ITM.[BinId],
			   @GLAccountId = ITM.[GLAccountId],
			   @IsPMA = ITM.IsPMA,
			   @IsDER = ITM.IsDER,	 
			   @IsOEM = ITM.IsOEM,
			   @IsSerialized = ITM.IsSerialized,
			   @PurchaseUnitOfMeasureId = ITM.[PurchaseUnitOfMeasureId],
			   @ItemGroup = ITM.ItemGroup,
			   @QuantityOnHand = ISNULL(SOP.[QtyOrder],0),
			   @QuantityAvailable = ISNULL(SOP.[QtyOrder],0),
			   --@UnitCost = ISNULL(SOP.[UnitSalesPrice],0),
			   @UnitCost = 0,
			   @IsStkTimeLife = ITM.[isTimeLife],
			   @ItemNonStockClassificationId = ITM.[ItemClassificationId]			 
		FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) 
		INNER JOIN [dbo].[ItemMaster] ITM WITH (NOLOCK) ON SOP.[ItemMasterId] = ITM.[ItemMasterId]
		WHERE SOP.[SalesOrderId] = @SalesOrderId AND SOP.[SalesOrderPartId] = @SalesOrderPartId AND SOP.[ItemMasterId] = @ItemMasterId;

		DECLARE @StockLineNumber VARCHAR(100), @IdCodeTypeId BIGINT,@ControlNumberCodeTypeId BIGINT,@CurrentIndex BIGINT = 0, @CurrentIdNumber BIGINT,@ReceiverNumber VARCHAR(50);
		DECLARE @currentNo BIGINT = 0, @stockLineCurrentNo AS BIGINT;
		DECLARE @CNCurrentNumber BIGINT,@ControlNumber VARCHAR(50);
		DECLARE @IdNumberCodeTypeId BIGINT
		
		SELECT @IdCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Stock Line';
		SELECT @ControlNumberCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Control Number';
		SELECT @IdNumberCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Id Number';
	
		-- Modules
		  SELECT @StockLineModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='StockLine';

		-- Management Structure Module
		  SELECT @StkManagementStructureModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline';


		IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCodePrefixes
		END

		CREATE TABLE #tmpCodePrefixes
		(
			[ID] BIGINT NOT NULL IDENTITY,
			[CodePrefixId] BIGINT NULL,
			[CodeTypeId] BIGINT NULL,
			[CurrentNumber] BIGINT NULL,
			[CodePrefix] VARCHAR(50) NULL,
			[CodeSufix] VARCHAR(50) NULL,
			[StartsFrom] BIGINT NULL
		)

		INSERT INTO #tmpCodePrefixes (CodePrefixId, CodeTypeId, CurrentNumber, CodePrefix, CodeSufix, StartsFrom)
		SELECT CP.CodePrefixId, CP.CodeTypeId, CP.CurrentNummber, CP.CodePrefix, CP.CodeSufix, CP.StartsFrom
		FROM dbo.CodePrefixes CP WITH (NOLOCK)
		JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
		WHERE CT.CodeTypeId IN (@IdCodeTypeId, @IdNumberCodeTypeId, @ControlNumberCodeTypeId)
		  AND CP.MasterCompanyId = @MasterCompanyId
		  AND CP.IsActive = 1
		  AND CP.IsDeleted = 0;

		IF (@CurrentIndex = 0)
		BEGIN
			SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END
			FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
		END
		ELSE
		BEGIN
			SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END
			FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
		END

		SET @ReceiverNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentIdNumber, 'RecNo', (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))

		SELECT @currentNo = ISNULL(IM.[CurrentStlNo], 0)
		FROM [dbo].[ItemMaster] IM WITH (NOLOCK)
		WHERE IM.[ItemMasterId] = @ItemMasterId AND IM.[ManufacturerId] = @ManufacturerId;

		IF (@currentNo <> 0)
		BEGIN
			SET @stockLineCurrentNo = @currentNo + 1;
		END
		ELSE
		BEGIN
			SET @stockLineCurrentNo = 1;
		END

		IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @IdCodeTypeId))
		BEGIN
			SET @StockLineNumber =
			(SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@stockLineCurrentNo, 
			(SELECT [CodePrefix] FROM #tmpCodePrefixes WHERE [CodeTypeId] = @IdCodeTypeId),
			(SELECT [CodeSufix]  FROM #tmpCodePrefixes WHERE [CodeTypeId] = @IdCodeTypeId)))

			UPDATE [dbo].[ItemMaster]
			SET [CurrentStlNo] = @stockLineCurrentNo
			WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId
		END

		IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @ControlNumberCodeTypeId))
		BEGIN
			SELECT @CNCurrentNumber = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE CAST([StartsFrom] AS BIGINT) + 1 END
			FROM #tmpCodePrefixes WHERE CodeTypeId = @ControlNumberCodeTypeId;

			SET @ControlNumber =
			(
				SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CNCurrentNumber, 
				(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @ControlNumberCodeTypeId),
				(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @ControlNumberCodeTypeId))
			)
		END

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
		SELECT @PartNumber, @StockLineNumber, NULL, @ControlNumber, @ItemMasterId, @QtyOrder, @ConditionId, @SerialNumber, 0
			  ,NULL, @WarehouseId, @LocationId, NULL, NULL, NULL, @ManufacturerId, NULL, NULL, NULL
			  ,NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL 
			  ,0, 0, NULL, 0, @CreatedDate, @ReceiverNumber, NULL, 0, 0 
			  ,@GLAccountId, NULL, 0, @IsPMA, @IsDER, @IsOEM, @Memo, @ManagementStructureId, @LegalEntityId, @MasterCompanyId, @CreatedBy, @CreatedBy
			  ,@IsSerialized, @ShelfId, @BinId, @SiteId, @ObtainFromType, @OwnerType, @TraceableToType, NULL, NULL
			  ,NULL, 0, 0, NULL, NULL, NULL, 0, NULL
			  ,0, NULL, NULL, NULL, NULL, 0, NULL, NULL
			  ,@QuantityReserved, 0, @QuantityIssued, @QuantityOnHand, @QuantityAvailable, 0, @QtyReserved, @QtyIssued, 0, NULL
			  ,0, NULL, 0, NULL, NULL, 1, 0, 0.00, 0.00, @IsCustomerStock
			  ,@CreatedDate , 0.00, NULL, NULL, @ItemTypeId, NULL, NULL, NULL, NULL, NULL, NULL
			  ,NULL , NULL, 1, 0, 0, NULL, NULL, NULL, NULL, @PurchaseUnitOfMeasureId
			  ,NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '', '', '', '', '', ''
			  ,NULL, '', @ItemGroup, '', '', '', '', @ItemType, NULL, ''
			  ,@IsCustomerStock, NULL, NULL, '', '', '', '', @UnitCost, NULL, '', NULL
			  ,NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, NULL, 0, 0
			  ,NULL, 0, NULL, 0, '', NULL, NULL, NULL, 0, NULL, NULL
			  ,NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 0.00, @SalesOrderPartId
			  ,0.00, 0.00, @IsStkTimeLife, NULL, NULL, NULL, 0, NULL
			  ,0, NULL, NULL, NULL, NULL, 0, NULL, NULL
			  ,'', NULL, NULL, NULL, NULL, NULL 
			  ,NULL, NULL, NULL, NULL, NULL, NULL
			  ,NULL, NULL, NULL, NULL, NULL, NULL
			  ,NULL, NULL, NULL, NULL, NULL, NULL
			  ,NULL, NULL, NULL, NULL, NULL, 0, 0
			  ,0, 0, NULL, 0, NULL, 0, NULL, NULL, NULL
			  ,NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL
			  ,@ItemNonStockClassificationId, NULL, 1, @CreatedDate, @CreatedDate

		SET @StockLineId = SCOPE_IDENTITY();

		UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @stockLineCurrentNo WHERE [CodeTypeId] = @IdCodeTypeId AND [MasterCompanyId] = @MasterCompanyId;
		UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @CNCurrentNumber WHERE [CodeTypeId] = @ControlNumberCodeTypeId AND MasterCompanyId = @MasterCompanyId;


		EXEC dbo.[USP_SaveSLMSDetails] @StkManagementStructureModuleId,@StockLineId,@ManagementStructureId,@MasterCompanyId,@CreatedBy;

		EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId;

		--EXEC [dbo].[USP_PostManualStockLineBatchDetails] @StockLineId,@AccountPayableglAccountId

		EXEC [dbo].[USP_AddUpdateStocklineHistory] @StockLineId,@StockLineModuleID,@StockLineId,NULL,NULL,1,@QuantityOnHand,@CreatedBy;

		COMMIT TRANSACTION				
	END TRY
	BEGIN CATCH
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID INT,
				@DatabaseName VARCHAR(100) = DB_NAME()
				-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				,@AdhocComments VARCHAR(150) = 'USP_CreateStocklineForNosStockSalesOrderPart'
				,@ProcedureParameters VARCHAR(3000) = '@SalesOrderId = ''' + ISNULL(CAST(@SalesOrderId AS VARCHAR(20)), '') + ''', @SalesOrderPartId = ''' + ISNULL(CAST(@SalesOrderPartId AS VARCHAR(20)), '') + ''', @ItemMasterId = ''' + ISNULL(CAST(@ItemMasterId AS VARCHAR(20)), '') + ''''
				,@ApplicationName VARCHAR(100) = 'PAS'
				-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName,
							@AdhocComments = @AdhocComments,
							@ProcedureParameters = @ProcedureParameters,
							@ApplicationName = @ApplicationName,
							@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END