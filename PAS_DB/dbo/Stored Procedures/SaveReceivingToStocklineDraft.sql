/*************************************************************           
 ** File:   [SaveReceivingToStocklineDraft]           
 ** Author: Vishal Suthar
 ** Description: This stored procedure is save receiving PO data into stockline draft
 ** Purpose:         
 ** Date:   08/10/2023

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    05/13/2022   Vishal Suthar		Created
     
 EXEC [SaveReceivingToStocklineDraft] 1894, 'ADMIN User'
**************************************************************/
CREATE   PROCEDURE [dbo].[SaveReceivingToStocklineDraft]
	@PurchaseOrderId bigint = 0,
	@UserName VARCHAR(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @LoopID AS int;
				DECLARE @LoopID_Qty AS int;
				DECLARE @CurrentIndex BIGINT;
				DECLARE @CurrentIdNumber AS BIGINT;
				DECLARE @IdNumber AS VARCHAR(50);

				IF OBJECT_ID(N'tempdb..#tmpPurchaseOrderParts') IS NOT NULL
				BEGIN
					DROP TABLE #tmpPurchaseOrderParts
				END

				CREATE TABLE #tmpPurchaseOrderParts
				(
					ID BIGINT NOT NULL IDENTITY,   
					PurchaseOrderPartRecordId BIGINT NULL
				)

				INSERT INTO #tmpPurchaseOrderParts (PurchaseOrderPartRecordId) 
				--SELECT POP.PurchaseOrderPartRecordId FROM dbo.PurchaseOrderPart POP WITH(NOLOCK) WHERE POP.PurchaseOrderId = @PurchaseOrderId;
				SELECT POP.PurchaseOrderPartRecordId FROM dbo.PurchaseOrderPart POP WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND POP.ItemTypeId = 1
				AND (PurchaseOrderPartRecordId NOT IN (SELECT POPI.ParentId FROM dbo.PurchaseOrderPart POPI WITH(NOLOCK) WHERE POPI.PurchaseOrderId = @PurchaseOrderId AND ParentId IS NOT NULL))
				AND (PurchaseOrderPartRecordId NOT IN (SELECT StkDraft.PurchaseOrderPartRecordId FROM dbo.StocklineDraft StkDraft WITH(NOLOCK) WHERE StkDraft.PurchaseOrderId = @PurchaseOrderId AND StkDraft.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId))

				SELECT @LoopID = MAX(ID) FROM #tmpPurchaseOrderParts;

				WHILE (@LoopID > 0)
				BEGIN
					DECLARE @PurchaseOrderPartRecordId BIGINT = 0;
					DECLARE @QtyToTraverse INT = 0;
					DECLARE @QtyOrdered INT = 0;
					DECLARE @ItemMasterId BIGINT = 0;
					DECLARE @ConditionId BIGINT = 0;
					DECLARE @OrderDate DATETIME;
					DECLARE @POUnitCost DECIMAL(18, 2) = 0;
					DECLARE @POPartUnitCost DECIMAL(18, 2) = 0;
					DECLARE @IdCodeTypeId BIGINT;
					DECLARE @MasterCompanyId BIGINT;
					DECLARE @ShipViaId BIGINT = 0;
					DECLARE @ConditionName VARCHAR(100);
					DECLARE @ShipViaName VARCHAR(100);
					DECLARE @ManagementStructureId BIGINT;
					DECLARE @IsSerialized BIT = 0;

					SELECT @IdCodeTypeId = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'Id Number';  

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
  
					SELECT @PurchaseOrderPartRecordId = PurchaseOrderPartRecordId FROM #tmpPurchaseOrderParts WHERE ID  = @LoopID;

					SELECT @QtyToTraverse = POP.QuantityOrdered, @QtyOrdered = POP.QuantityOrdered, @ItemMasterId = POP.ItemMasterId, @ConditionId = POP.ConditionId, @ConditionName = POP.Condition, @MasterCompanyId = POP.MasterCompanyId, @POPartUnitCost = POP.UnitCost FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId;
					SELECT @OrderDate = PO.OpenDate, @ManagementStructureId = PO.ManagementStructureId FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId;
					SELECT @POUnitCost = IMS.PP_VendorListPrice FROM DBO.ItemMasterPurchaseSale IMS WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId;
					SELECT @ShipViaId = ShipViaId, @ShipViaName = ShipVia FROM AllShipVia WHERE ReferenceId = @PurchaseOrderId AND ModuleId = 13;

					PRINT '@POUnitCost'
					PRINT @POUnitCost
					PRINT '@POPartUnitCost'
					PRINT @POPartUnitCost

					INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)
					SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom
					FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
					WHERE CT.CodeTypeId = @IdCodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

					SELECT @IsSerialized = IM.isSerialized  FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId = @ItemMasterId;

					SET @CurrentIndex = 0;
					SET @LoopID_Qty = @QtyToTraverse;

					SET @LoopID_Qty = @LoopID_Qty + 1;

					WHILE (@LoopID_Qty > 0)
					BEGIN
						DECLARE @NewStocklineDraftId BIGINT;
						DECLARE @IsParent BIT = 1;
						
						IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId))
						BEGIN
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
						
							SET @IdNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentIdNumber,
								(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId),
								(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))  
						END

						DECLARE @Quantity INT = 1;
						DECLARE @QuantityAvailable INT = 1;
						DECLARE @QuantityOnHand INT = 1;
						
						IF (@CurrentIndex = 0)
						BEGIN
							IF (@IsSerialized = 0)
							BEGIN
								SET @Quantity = @QtyOrdered;
								SET @QuantityAvailable = @QtyOrdered;
								SET @QuantityOnHand = @QtyOrdered;

								SET @IsParent = 1;
							END
							ELSE IF (@IsSerialized = 1)
							BEGIN
								SET @Quantity = @QtyOrdered;
								SET @QuantityAvailable = @QtyOrdered;
								SET @QuantityOnHand = @QtyOrdered;

								SET @IsParent = 0;
							END
						END
						ELSE
						BEGIN
							IF (@IsSerialized = 0)
							BEGIN
								SET @IsParent = 0;
							END
							ELSE IF (@IsSerialized = 1)
							BEGIN
								SET @IsParent = 1;
							END
						END

						PRINT '@IsParent'
						PRINT @IsParent
						PRINT '@Quantity'
						PRINT @Quantity

						INSERT INTO DBO.StocklineDraft (
						[PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],
						[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber],
						[CertifiedBy],[CertifiedDate],[TagDate],[TagTypeIds],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],
						[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],
						[IsDER],[OEM],[Memo],[ManagementStructureEntityId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId],[BinId],[SiteId],
						[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],
						[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],
						[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId],[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],
						[QuantityOnOrder],[QtyReserved],[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive],[isDeleted],
						[WorkOrderExtendedCost],[RepairOrderExtendedCost],[NHAItemMasterId],[TLAItemMasterId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[Level1],[Level2],[Level3],[Level4],[Condition],
						[Warehouse],[Location],[ObtainFromName],[OwnerName],[TraceableToName],[GLAccount],[AssetName],[LegalEntityName],[ShelfName],[BinName],[SiteName],[ObtainFromTypeName],[OwnerTypeName],
						[TraceableToTypeName],[UnitCostAdjustmentReasonType],[UnitSalePriceAdjustmentReasonType],[ShippingVia],[WorkOrder],[WorkOrderMaterialsName],[TagTypeId],[StockLineDraftNumber],
						[StockLineId],[TaggedBy],[TaggedByName],[UnitOfMeasureId],[UnitOfMeasure],[RevisedPartId],[RevisedPartNumber],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],
						[CertifiedType],[CertTypeId],[CertType],[IsCustomerStock],[isCustomerstockType],[CustomerId],[CalibrationVendorId],[PerformedById],[LastCalibrationDate],[NextCalibrationDate],
						[LotId],[SalesOrderId],[SubWorkOrderId],[ExchangeSalesOrderId],[WOQty],[SOQty],[ForStockQty],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost],[ROOriginalCost],
						[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment])

						SELECT IM.partnumber, NULL, NULL, NULL, @ItemMasterId, @Quantity, @ConditionId, '', 0, NULL, IM.WarehouseId, 
						IM.LocationId, NULL, NULL, NULL, IM.ManufacturerId, IM.ManufacturerName, NULL, NULL, NULL, NULL,
						NULL, NULL, NULL, NULL, NULL, NULL, NULL, @OrderDate, @PurchaseOrderId, CASE WHEN @POPartUnitCost = 0 THEN @POUnitCost ELSE @POPartUnitCost END, NULL,
						NULL, NULL, GETUTCDATE(), NULL, NULL, NULL, CASE WHEN @POPartUnitCost = 0 THEN @POUnitCost ELSE @POPartUnitCost END, IM.GLAccountId, NULL, IM.IsHazardousMaterial, IM.IsPma, 
						IM.IsDER, IM.IsOEM, NULL, @ManagementStructureId, NULL, @MasterCompanyId, @UserName, @UserName, GETUTCDATE(), GETUTCDATE(), IM.isSerialized, NULL, NULL, IM.SiteId,
						NULL, NULL, NULL, NULL, NULL, @IdNumber, 1, ((CASE WHEN @POPartUnitCost = 0 THEN @POUnitCost ELSE @POPartUnitCost END) * 1), 
						NULL, NULL, NULL, CASE WHEN @ShipViaId = 0 THEN NULL ELSE @ShipViaId END, NULL, 0, @PurchaseOrderPartRecordId, '', '',
						NULL, 0, NULL, NULL, NULL, NULL, NULL, @QuantityOnHand, @QuantityAvailable, 
						NULL, NULL, NULL, 0, NULL, 0, NULL, 0, NULL, NULL, 1, 0, 0, NULL, NULL, NULL, @IsParent, 0, 1, NULL, NULL, NULL, NULL, @ConditionName,
						IM.WarehouseName, IM.LocationName, '', '', '', IM.GLAccount, NULL, NULL, NULL, NULL, IM.SiteName, '', '',
						'', NULL, NULL, @ShipViaName, NULL, NULL, 0, 'STL_DRFT-000000', 
						NULL, NULL, NULL, IM.PurchaseUnitOfMeasureId, IM.PurchaseUnitOfMeasure, NULL, NULL, 0, NULL, NULL, NULL,
						NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL,
						NULL, NULL, NULL, NULL, NULL, NULL, @QtyToTraverse, NULL, NULL, NULL, NULL, NULL, NULL,
						NULL, NULL, NULL, 0, 0, NULL
						FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId = @ItemMasterId;

						SELECT @NewStocklineDraftId = SCOPE_IDENTITY();

						EXEC [PROCAddStockLineDraftMSData] @NewStocklineDraftId, @ManagementStructureId, @MasterCompanyId, @UserName, @UserName, 31, 1;

						SET @LoopID_Qty = @LoopID_Qty - 1;
						SET @CurrentIndex = @CurrentIndex + 1;  
					END

					SET @LoopID = @LoopID - 1;
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
              , @AdhocComments     VARCHAR(150)    = 'SaveReceivingToStocklineDraft' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@PurchaseOrderId AS varchar(10)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END