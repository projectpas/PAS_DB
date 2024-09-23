/*************************************************************   
** Author:  <Devendra Shekh>  
** Create date: <09/12/2024>  
** Description: <Tender Multiple StockLine>  
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	09/12/2024		Devendra Shekh			Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_SaveTurnInMultipleWorkOrderMaterils]
	@tbl_SaveAndTenderMultipleStocklineType [SaveAndTenderMultipleStocklineType] READONLY
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					DECLARE @TotalWOMCount BIGINT = 0, @CurrentWOM BIGINT = 0;
					DECLARE @IsMaterialStocklineCreate BIT, @IsCustomerStock BIT, @IsCustomerstockType BIT, @ItemMasterId BIGINT, @UnitOfMeasureId BIGINT, @ConditionId BIGINT, @Quantity INT,
							@IsSerialized BIT, @SerialNumber VARCHAR(50), @CustomerId BIGINT, @ObtainFromTypeId INT, @ObtainFrom BIGINT, @ObtainFromName VARCHAR(500), @OwnerTypeId INT, @Owner BIGINT, @OwnerName VARCHAR(500),
							@TraceableToTypeId INT, @TraceableTo BIGINT, @TraceableToName VARCHAR(500), @Memo VARCHAR(MAX), @WorkOrderId BIGINT, @WorkOrderNumber VARCHAR(50), @ManufacturerId BIGINT,
							@InspectedById BIGINT, @InspectedDate DATETIME2(7), @ReceiverNumber VARCHAR(500), @ReceivedDate DATETIME2(7), @ManagementStructureId BIGINT,
							@SiteId BIGINT, @WarehouseId BIGINT, @LocationId BIGINT, @ShelfId BIGINT, @BinId BIGINT, @MasterCompanyId BIGINT, @UpdatedBy VARCHAR(100), @WorkOrderMaterialsId BIGINT, @IsKitType BIT,
							@Unitcost DECIMAL(18,2), @ProvisionId INT, @EvidenceId INT, @CtrlNumCodeTypeId BIGINT, @StkCodeTypeId BIGINT, @IdNumCodeTypeId BIGINT;

					DECLARE @PartNumber VARCHAR(500), @SLCurrentNummber BIGINT, @StockLineNumber VARCHAR(50), @CNCurrentNummber BIGINT, @ControlNumber VARCHAR(50), @IDCurrentNummber BIGINT, 
							@IDNumber VARCHAR(50), @NewWorkOrderMaterialsId BIGINT, @StockLineId BIGINT, @WorkOrderWorkflowId BIGINT, @MSModuleID INT = 2, @IsPMA BIT = 0, @IsDER BIT = 0, 
							@IsOemPNId BIGINT, @IsOEM BIT = 0, @OEMPNNumber VARCHAR(500), @count INT, @slcount INT, @IsAddUpdate BIT, @ExecuteParentChild BIT, @UpdateQuantities BIT, @IsOHUpdated BIT, @AddHistoryForNonSerialized BIT,
							@ReferenceId BIGINT, @SubReferenceId BIGINT, @IsSerialised BIT, @ModuleId BIGINT, @SubModuleId BIGINT, @stockLineQty INT, @stockLineQtyAvailable INT, @GLAccountId INT, @IsTimeLife BIT,
							@QtyTendered INT = 0, @QtyToTendered INT = 0, @TotalStlQtyReq INT = 0, @WorkOrderTypeId INT = 0, @TearDownWorkOrderTypeId INT = 0, @WorkOrderPartNoId BIGINT = 0, @isExchange BIT,
							@ActionId INT = 0, @HistoryModuleId INT = 0, @WOMStockLineId BIGINT = 0, @WorkOrderMaterialsKitMappingId BIGINT = NULL, @OLDStockLineId BIGINT = 0;
					
					DECLARE @currentNo BIGINT, @stockLineCurrentNo BIGINT; 

					SELECT @ModuleId = [ModuleId] FROM dbo.[Module] WITH(NOLOCK) WHERE [ModuleId] = 22; -- For Stockline Module  
					SELECT @SubModuleId = [ModuleId] FROM dbo.[Module] WITH(NOLOCK) WHERE [ModuleId] = 33; -- For WORK ORDER Materials Module  
					SELECT @TearDownWorkOrderTypeId = [Id] FROM [WorkOrderType] WITH(NOLOCK) WHERE UPPER([Description]) ='TEARDOWN';
					SELECT @ActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE UPPER([Type]) = 'TENDERED';
					SELECT @HistoryModuleId = [ModuleId] FROM dbo.[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'WORKORDER';
					SELECT @CtrlNumCodeTypeId = [CodeTypeId] FROM dbo.[CodeTypes] WITH(NOLOCK) WHERE UPPER([CodeType]) = 'CONTROL NUMBER';
					SELECT @StkCodeTypeId = [CodeTypeId] FROM dbo.[CodeTypes] WITH(NOLOCK) WHERE UPPER([CodeType]) = 'STOCK LINE';
					SELECT @IdNumCodeTypeId = [CodeTypeId] FROM dbo.[CodeTypes] WITH(NOLOCK) WHERE UPPER([CodeType]) = 'ID NUMBER';

					IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_Parent') IS NOT NULL  
	 					DROP TABLE #tmpCodePrefixes_Parent  

					IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL  
						DROP TABLE #tmpPNManufacturer   

					IF OBJECT_ID('tempdb..#TenderWOMListData') IS NOT NULL
						DROP TABLE #TenderWOMListData

					CREATE TABLE #tmpCodePrefixes_Parent (  
					   ID BIGINT NOT NULL IDENTITY,   
					   CodePrefixId BIGINT NULL,  
					   CodeTypeId BIGINT NULL,  
					   CurrentNummber BIGINT NULL,  
					   CodePrefix VARCHAR(50) NULL,  
					   CodeSufix VARCHAR(50) NULL,  
					   StartsFrom BIGINT NULL,  
					   MasterCompanyId INT NULL,
					 )  

					  CREATE TABLE #tmpPNManufacturer (  
						ID BIGINT NOT NULL IDENTITY,   
						ItemMasterId BIGINT NULL,  
						ManufacturerId BIGINT NULL,  
						StockLineNumber VARCHAR(100) NULL,  
						CurrentStlNo BIGINT NULL,  
						isSerialized BIT NULL  
					 )  

					CREATE TABLE #TenderWOMListData (
						[RecordId] BIGINT IDENTITY(1,1),
						[IsMaterialStocklineCreate] BIT NULL,
						[IsCustomerStock] BIT NULL,
						[IsCustomerstockType] BIT NULL,
						[ItemMasterId] BIGINT NULL,
						[UnitOfMeasureId] BIGINT NULL,
						[ConditionId] BIGINT NULL,
						[Quantity] INT NULL,
						[IsSerialized] BIT NULL,
						[SerialNumber] VARCHAR(50) NULL,
						[CustomerId] BIGINT NULL,
						[ObtainFromTypeId] INT NULL,
						[ObtainFrom] BIGINT NULL,
						[ObtainFromName] VARCHAR(500) NULL,
						[OwnerTypeId] INT NULL,
						[Owner] BIGINT NULL,
						[OwnerName] VARCHAR(500) NULL,
						[TraceableToTypeId] INT NULL,
						[TraceableTo] BIGINT NULL,
						[TraceableToName] VARCHAR(500) NULL,
						[Memo] VARCHAR(MAX) NULL,
						[WorkOrderId] BIGINT NULL,
						[WorkOrderNumber] VARCHAR(50) NULL,
						[ManufacturerId] BIGINT NULL,
						[InspectedById] BIGINT NULL,
						[InspectedDate] DATETIME2(7) NULL,
						[ReceiverNumber] VARCHAR(500) NULL,
						[ReceivedDate] DATETIME2(7) NULL,
						[ManagementStructureId] BIGINT NULL,
						[SiteId] BIGINT NULL,
						[WarehouseId] BIGINT NULL,
						[LocationId] BIGINT NULL,
						[ShelfId] BIGINT NULL,
						[BinId] BIGINT NULL,
						[MasterCompanyId] BIGINT NULL,
						[UpdatedBy] VARCHAR(100) NULL,
						[WorkOrderMaterialsId] BIGINT NULL,
						[IsKitType] BIT NULL,
						[Unitcost] DECIMAL(18,2) NULL,
						[ProvisionId] INT NULL,
						[EvidenceId] INT NULL
					);					   

					INSERT INTO #TenderWOMListData ([IsMaterialStocklineCreate], [IsCustomerStock], [IsCustomerstockType], [ItemMasterId], [UnitOfMeasureId], [ConditionId], [Quantity], [IsSerialized], [SerialNumber], [CustomerId],
							[ObtainFromTypeId], [ObtainFrom], [ObtainFromName], [OwnerTypeId], [Owner], [OwnerName], [TraceableToTypeId], [TraceableTo], [TraceableToName], [Memo], [WorkOrderId], [WorkOrderNumber], [ManufacturerId],
							[InspectedById], [InspectedDate], [ReceiverNumber], [ReceivedDate], [ManagementStructureId], [SiteId], [WarehouseId], [LocationId], [ShelfId], [BinId], [MasterCompanyId], [UpdatedBy], [WorkOrderMaterialsId],
							[IsKitType], [Unitcost], [ProvisionId], [EvidenceId])
					SELECT	[IsMaterialStocklineCreate], [IsCustomerStock], [IsCustomerstockType], [ItemMasterId], [UnitOfMeasureId], [ConditionId], [Quantity], [IsSerialized], [SerialNumber], [CustomerId], [ObtainFromTypeId],
							[ObtainFrom], [ObtainFromName], [OwnerTypeId], [Owner], [OwnerName], [TraceableToTypeId], [TraceableTo], [TraceableToName], [Memo], [WorkOrderId], [WorkOrderNumber], [ManufacturerId], [InspectedById],
							[InspectedDate], [ReceiverNumber], [ReceivedDate], [ManagementStructureId], [SiteId], [WarehouseId], [LocationId], [ShelfId], [BinId], [MasterCompanyId], [UpdatedBy], [WorkOrderMaterialsId], [IsKitType],
							[Unitcost], [ProvisionId], [EvidenceId]
					FROM @tbl_SaveAndTenderMultipleStocklineType

					SELECT @TotalWOMCount = MAX(RecordId), @CurrentWOM = MIN(RecordId) FROM #TenderWOMListData;

					WHILE(ISNULL(@TotalWOMCount, 0) >=  ISNULL(@CurrentWOM, 0))
					BEGIN											

						SELECT	@IsMaterialStocklineCreate = [IsMaterialStocklineCreate], @IsCustomerStock = [IsCustomerStock], @IsCustomerstockType = [IsCustomerstockType], @ItemMasterId = [ItemMasterId],
								@UnitOfMeasureId = [UnitOfMeasureId], @ConditionId = [ConditionId], @Quantity = [Quantity], @IsSerialized = [IsSerialized], @SerialNumber = [SerialNumber], @CustomerId = [CustomerId],
								@ObtainFromTypeId = [ObtainFromTypeId], @ObtainFrom = [ObtainFrom], @ObtainFromName = [ObtainFromName], @OwnerTypeId = [OwnerTypeId], @Owner = [Owner], @OwnerName = [OwnerName], 
								@TraceableToTypeId = [TraceableToTypeId], @TraceableTo = [TraceableTo], @TraceableToName = [TraceableToName], @Memo = [Memo], @WorkOrderId = [WorkOrderId], @WorkOrderNumber = [WorkOrderNumber],
								@ManufacturerId = [ManufacturerId], @InspectedById = [InspectedById], @InspectedDate = [InspectedDate], @ReceiverNumber = [ReceiverNumber], @ReceivedDate = [ReceivedDate],
								@ManagementStructureId = [ManagementStructureId], @SiteId = [SiteId], @WarehouseId = [WarehouseId], @LocationId = [LocationId], @ShelfId = [ShelfId], @BinId = [BinId], @MasterCompanyId = [MasterCompanyId], 
								@UpdatedBy = [UpdatedBy], @WorkOrderMaterialsId = [WorkOrderMaterialsId], @IsKitType = [IsKitType], @Unitcost = [Unitcost], @ProvisionId = [ProvisionId], @EvidenceId = [EvidenceId]
						FROM #TenderWOMListData
						WHERE RecordId = @CurrentWOM;

						SET @count = @Quantity;  
						SET @slcount = @Quantity;  
						SET @IsAddUpdate = 1;  
						SET @ExecuteParentChild = 1;  
						SET @UpdateQuantities = 0;  
						SET @IsOHUpdated = 0;  
						SET @AddHistoryForNonSerialized = 0; 

						SELECT	@QtyTendered = 0, @QtyToTendered = 0, @TotalStlQtyReq = 0, @WorkOrderTypeId = 0, @TearDownWorkOrderTypeId = 0, @WorkOrderPartNoId = 0,
								@isExchange =  (CASE WHEN UPPER((SELECT StatusCode FROM DBO.Provision WHERE ProvisionId = @ProvisionId)) = 'EXCHANGE' THEN 1 ELSE 0 END); 

						SELECT	@PartNumber = partnumber, @IsPMA = IsPMA, @IsDER = IsDER, @IsOemPNId = IsOemPNId, @IsOEM = IsOEM, @OEMPNNumber = OEMPN,@GLAccountId=GLAccountId, @IsTimeLife = isTimeLife  
								FROM dbo.ItemMaster WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId;  
						SELECT @WorkOrderTypeId = WorkOrderTypeId FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId;

						IF(ISNULL(@IsKitType, 0) = 0)
						BEGIN
							SELECT @WorkOrderWorkflowId = WorkFlowWorkOrderId FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId 
						END
						ELSE 
						BEGIN
							SELECT @WorkOrderWorkflowId = WorkFlowWorkOrderId FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId 
						END

						SELECT @WorkOrderPartNoId = WorkOrderPartNoId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId =@WorkOrderWorkflowId;
						
						IF(ISNULL(@CurrentWOM, 0) = 1)
						BEGIN
							/* PN Manufacturer Combination Stockline logic */ 
							;WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId) AS  
							 (  
								SELECT ac.ItemMasterId, ac.ManufacturerId, MAX(ac.StockLineId) StockLineId  
								FROM (SELECT DISTINCT ItemMasterId 
								FROM DBO.Stockline WITH (NOLOCK)) ac1
								CROSS JOIN  
								(SELECT DISTINCT ManufacturerId FROM DBO.Stockline WITH(NOLOCK)) ac2 LEFT JOIN  
								DBO.Stockline ac WITH(NOLOCK)  
								ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId  
								WHERE ac.MasterCompanyId = @MasterCompanyId  
								GROUP BY ac.ItemMasterId, ac.ManufacturerId  
								HAVING COUNT(ac.ItemMasterId) > 0  
							 )  
  
							 INSERT INTO #tmpPNManufacturer (ItemMasterId, ManufacturerId, StockLineNumber, CurrentStlNo, isSerialized)  
							 SELECT CSTL.ItemMasterId, CSTL.ManufacturerId, StockLineNumber, ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo, IM.isSerialized  
							 FROM CTE_Stockline CSTL WITH(NOLOCK)
							 INNER JOIN DBO.Stockline STL WITH(NOLOCK) INNER JOIN DBO.ItemMaster IM WITH(NOLOCK) ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId ON CSTL.StockLineId = STL.StockLineId  
							 /* PN Manufacturer Combination Stockline logic */
						END

						IF(ISNULL(@CurrentWOM, 0) = 1)
						BEGIN
							INSERT INTO #tmpCodePrefixes_Parent (CodePrefixId, CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom, MasterCompanyId)   
							SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom, CP.MasterCompanyId
							FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId  
							WHERE CT.CodeTypeId IN (@StkCodeTypeId, @IdNumCodeTypeId, @CtrlNumCodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
						END

						IF(@WorkOrderTypeId != @TearDownWorkOrderTypeId)  
						BEGIN  
							SET @Unitcost = 0;  
						END 

						SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId;
						SET @stockLineCurrentNo = CASE WHEN (@currentNo <> 0) THEN @currentNo + 1  ELSE 1 END;
						UPDATE #tmpPNManufacturer SET CurrentStlNo = @stockLineCurrentNo WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId;

						IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = @StkCodeTypeId))  
						BEGIN   
							SET @StockLineNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](@stockLineCurrentNo, (SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = @StkCodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = @StkCodeTypeId)))  
      
							UPDATE DBO.ItemMaster SET [CurrentStlNo] = @stockLineCurrentNo WHERE [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId  
						END  
						ELSE   
						BEGIN  
							ROLLBACK TRAN;  
						END

						IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = @CtrlNumCodeTypeId))  
						BEGIN   
							SELECT   
							@CNCurrentNummber = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1   
								ELSE CAST(StartsFrom AS BIGINT) + 1 END   
							FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = @CtrlNumCodeTypeId  
  
							SET @ControlNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](@CNCurrentNummber,(SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = @CtrlNumCodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = @CtrlNumCodeTypeId)))  
						END  
						ELSE   
						BEGIN  
							ROLLBACK TRAN;  
						END 

						IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = @IdNumCodeTypeId))  
						BEGIN   
							SET @IDCurrentNummber = 1;  
  
							SET @IDNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](@IDCurrentNummber,(SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = @IdNumCodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = @IdNumCodeTypeId)))  
						END  
						ELSE   
						BEGIN  
							ROLLBACK TRAN;  
						END

						INSERT INTO dbo.Stockline(StockLineNumber, ControlNumber, IDNumber, IsCustomerStock,IsCustomerstockType,ItemMasterId,PartNumber, PurchaseUnitOfMeasureId,ConditionId,Quantity,   
						QuantityAvailable, QuantityOnHand,QuantityTurnIn,IsSerialized,SerialNumber, CustomerId, ObtainFromType, ObtainFrom, ObtainFromName, OwnerType, [Owner], OwnerName, TraceableToType,   
						TraceableTo, TraceableToName, Memo, WorkOrderId, WorkOrderNumber, ManufacturerId, InspectionBy, InspectionDate, ReceiverNumber, IsParent, LotCost, ParentId,  
						QuantityIssued, QuantityReserved,QuantityToReceive,RepairOrderExtendedCost, SubWOPartNoId,SubWorkOrderId, WorkOrderExtendedCost, WorkOrderPartNoId,  
						ReceivedDate, ManagementStructureId, SiteId, WarehouseId, LocationId, ShelfId, BinId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,isActive, isDeleted, MasterCompanyId, IsTurnIn,  
						[OEM],IsPMA, IsDER,IsOemPNId, OEMPNNumber,GLAccountId,[IsStkTimeLife],[EvidenceId]
									) VALUES(@StockLineNumber, @ControlNumber, @IDNumber, @IsCustomerStock,@IsCustomerstockType,@ItemMasterId,@PartNumber,@UnitOfMeasureId,@ConditionId,@Quantity, @Quantity, @Quantity, @Quantity,  
						@IsSerialized,@SerialNumber, @CustomerId, @ObtainFromTypeId, @ObtainFrom, @ObtainFromName, @OwnerTypeId, @Owner, @OwnerName, @TraceableToTypeId,   
						@TraceableTo, @TraceableToName, @Memo, @WorkOrderId, @WorkOrderNumber, @ManufacturerId, @InspectedById, @InspectedDate, @ReceiverNumber, 1, 0,0,0,0,0,0,0,0,0,@WorkOrderPartNoId,  
						@ReceivedDate, @ManagementStructureId, @SiteId, @WarehouseId, @LocationId, @ShelfId, @BinId, @UpdatedBy, @UpdatedBy, GETUTCDATE(),GETUTCDATE(),1,0, @MasterCompanyId, 1,  
						@IsOEM,@IsPMA, @IsDER,@IsOemPNId, @OEMPNNumber,@GLAccountId, @IsTimeLife,@EvidenceId);  
       
						SELECT @StockLineId = SCOPE_IDENTITY();

						UPDATE CodePrefixes SET CurrentNummber = @SLCurrentNummber WHERE CodeTypeId = @StkCodeTypeId AND MasterCompanyId = @MasterCompanyId;
						UPDATE #tmpCodePrefixes_Parent SET CurrentNummber = @SLCurrentNummber WHERE CodeTypeId = @StkCodeTypeId AND MasterCompanyId = @MasterCompanyId;

						UPDATE CodePrefixes SET CurrentNummber = @CNCurrentNummber WHERE CodeTypeId = @CtrlNumCodeTypeId AND MasterCompanyId = @MasterCompanyId;
						UPDATE #tmpCodePrefixes_Parent SET CurrentNummber = @CNCurrentNummber WHERE CodeTypeId = @CtrlNumCodeTypeId AND MasterCompanyId = @MasterCompanyId;

						--: Around 5 Seconds
						EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @StockLineId;

						UPDATE [dbo].[Stockline] SET [Memo] = 'This Stockline is created using turn-in from ' + @WorkOrderNumber, Unitcost = @Unitcost WHERE StockLineId = @StockLineId; 

						IF(@isExchange = 1)
						BEGIN
							UPDATE dbo.Stockline SET WorkOrderMaterialsId = @WorkOrderMaterialsId WHEre StockLineId = @StockLineId
						END

						IF(@WorkOrderTypeId = @TearDownWorkOrderTypeId)  
						BEGIN  
							UPDATE [dbo].[WorkOrderPartNumber] SET [TendorStocklineCost] = ISNULL(TendorStocklineCost,0) + ISNULL((@Quantity * @Unitcost),0) WHERE ID = @WorkOrderPartNoId;            
  
							SET @OLDStockLineId = (SELECT [StockLineId] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNoId);  
  
							UPDATE [dbo].[Stockline] SET [Memo] = 'This Stockline cost is updated using turn-in to work order number ' + @WorkOrderNumber + ' new stockline is ' + @StockLineNumber,  
								[UnitCost] -= @Unitcost, [PurchaseOrderUnitCost] -= @Unitcost  
							WHERE [StockLineId] = @OLDStockLineId;  
						END 

						--: Around 4 Seconds
						WHILE @count >= @slcount  
						BEGIN  
							SET @ReferenceId = 0;  
							SET @SubReferenceId = @WorkOrderMaterialsId  
							SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM [dbo].[Stockline] WITH (NOLOCK) WHERE StockLineId = @StocklineId  
        
							IF (@IsSerialised = 0 AND (@stockLineQtyAvailable > 1 OR @stockLineQty > 1))  
							BEGIN  
								EXEC [dbo].[USP_CreateChildStockline]    
								@StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = @IsAddUpdate, @ExecuteParentChild = @ExecuteParentChild,   
								@UpdateQuantities = @UpdateQuantities, @IsOHUpdated = @IsOHUpdated, @AddHistoryForNonSerialized = @AddHistoryForNonSerialized, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId        
							END  
							ELSE  
							BEGIN  
								EXEC [dbo].[USP_CreateChildStockline]  @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = 0, @ExecuteParentChild = 0, @UpdateQuantities = 0, @IsOHUpdated = 0, @AddHistoryForNonSerialized = 1, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId  
							END  
							SET @slcount = @slcount + 1;  
						END; 

						--: 1 or seconds
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @HistoryModuleId, @ReferenceId = @WorkOrderId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @Quantity, @UpdatedBy = @UpdatedBy;

						--Add SL Managment Structure Details   
						EXEC USP_SaveSLMSDetails @MSModuleID, @StockLineId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy;

						-- #STEP 2 ADD STOCKLINE TO WO MATERIAL LIST
						IF (@IsKitType = 0)  
						BEGIN 
							IF (@IsMaterialStocklineCreate = 1)  
							BEGIN
								IF ((SELECT COUNT(1) FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = @ConditionId AND   
									WorkFlowWorkOrderId = @WorkOrderWorkflowId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0) > 0)  
								BEGIN 
									UPDATE dbo.WorkOrderMaterials SET   
									Quantity =  CASE WHEN ISNULL(Quantity, 0) - (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0)) >= @Quantity THEN Quantity ELSE  
									(ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0) + @Quantity) END  
									FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId  
									SELECT @NewWorkOrderMaterialsId = @WorkOrderMaterialsId;  
									IF(@isExchange = 1)
									BEGIN
										UPDATE dbo.Stockline SET WorkOrderMaterialsId = @WorkOrderMaterialsId WHEre StockLineId = @StockLineId
									END
								END
								ELSE
								BEGIN
									INSERT INTO dbo.WorkOrderMaterials (WorkOrderId, WorkFlowWorkOrderId, ItemMasterId, TaskId, ConditionCodeId, ItemClassificationId, Quantity, UnitOfMeasureId,  
									   UnitCost,ExtendedCost,Memo,IsDeferred, QuantityReserved, QuantityIssued, MaterialMandatoriesId,ProvisionId,CreatedDate, CreatedBy, UpdatedDate,   
									   UpdatedBy, MasterCompanyId, IsActive, IsDeleted)   
									SELECT @WorkOrderId, WOWF.WorkFlowWorkOrderId, @ItemMasterId, WOM.TaskId, @ConditionId, WOM.ItemClassificationId, @Quantity, @UnitOfMeasureId, 0, 0, @Memo,   
									   WOM.IsDeferred, 0, 0, WOM.MaterialMandatoriesId,WOM.ProvisionId,GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0   
									FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)   
									 JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId  
									WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId;  
  
									SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY()  
									IF(@isExchange = 1)
									BEGIN
										UPDATE dbo.Stockline SET WorkOrderMaterialsId = @NewWorkOrderMaterialsId WHEre StockLineId = @StockLineId
									END
								END

								INSERT INTO dbo.WorkOrderMaterialStockLine (WorkOrderMaterialsId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QuantityTurnIn, QtyReserved, QtyIssued,   
								UnitCost,ExtendedCost,UnitPrice,CreatedDate, CreatedBy, UpdatedDate,UpdatedBy, MasterCompanyId, IsActive, IsDeleted)   
								SELECT @NewWorkOrderMaterialsId, @StockLineId, @ItemMasterId, WOM.ProvisionId, @ConditionId, @Quantity, @Quantity, 0, 0, 0, 0, 0,  
								GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0   
								FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)   
								WHERE WOM.WorkOrderMaterialsId = @NewWorkOrderMaterialsId; 
								
								SELECT @WOMStockLineId = SCOPE_IDENTITY();

								IF(@WorkOrderTypeId = @TearDownWorkOrderTypeId)  
								BEGIN  
									UPDATE [dbo].[WorkOrderMaterialStockLine] SET UnitCost= @Unitcost,ExtendedCost=ISNULL((@Quantity * @Unitcost),0) WHERE WOMStockLineId=@WOMStockLineId;  
								END  

								--UPDATE QTY TO TURN IN IF MISMATCH  
								SELECT @QtyTendered = SUM(ISNULL(sl.QuantityTurnIn,0))   
								FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)  
								JOIN dbo.Stockline sl WITH (NOLOCK) ON womsl.StockLIneId = sl.StockLIneId  
								JOIN dbo.WorkOrderMaterials WOM WITH(NOLOCK) ON womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId  
								WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId  
								AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0  
  
								SELECT @QtyToTendered = SUM(ISNULL(QtyToTurnIn,0))                
								FROM dbo.WorkOrderMaterials WITH(NOLOCK)      
								WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId  
  
								IF (@QtyTendered > @QtyToTendered)  
								BEGIN  
									UPDATE dbo.WorkOrderMaterials SET QtyToTurnIn = @QtyTendered FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId  
								END  

								--UPDATE QTY REQ IN MATERIAL IF REQ QTY MISMATCH  
								SELECT @TotalStlQtyReq = SUM(ISNULL(womsl.Quantity,0))   
								FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)         
								WHERE womsl.WorkOrderMaterialsId = @WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0   
  
								IF(@TotalStlQtyReq > (SELECT ISNULL(Quantity, 0) FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId))  
								BEGIN  
									UPDATE dbo.WorkOrderMaterials SET Quantity = @TotalStlQtyReq FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId  
								END  

								--UPDATE WO PART LEVEL TOTAL COST  
								--Around 1 second sometimes
								EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy;  

								--UPDATE WO PART LEVEL TOTAL COST
								--Around 1 second
								EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy;

								--UPDATE MATERIALS COST  
								--Around 1 second
								EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @NewWorkOrderMaterialsId;

								--Around 2 second when all three update SP executes
							END
						END
						ELSE
						BEGIN
							SELECT @WorkOrderWorkflowId = WorkFlowWorkOrderId FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;
							IF (@IsMaterialStocklineCreate = 1)  
							BEGIN
								IF ((SELECT COUNT(1) FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = @ConditionId AND   
								WorkFlowWorkOrderId = @WorkOrderWorkflowId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0) > 0)  
								BEGIN 
									UPDATE dbo.WorkOrderMaterialsKit SET   
									Quantity =  CASE WHEN ISNULL(Quantity, 0) - (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0)) >= @Quantity THEN Quantity ELSE  
									(ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0) + @Quantity) END  
									FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId  
									SELECT @NewWorkOrderMaterialsId = @WorkOrderMaterialsId;
								END
								ELSE  
								BEGIN  
									SELECT TOP 1 @WorkOrderMaterialsKitMappingId = WorkOrderMaterialsKitMappingId FROM DBO.WorkOrderMaterialsKit (NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;

									INSERT INTO dbo.WorkOrderMaterialsKit (WorkOrderMaterialsKitMappingId, WorkOrderId, WorkFlowWorkOrderId, ItemMasterId, TaskId, ConditionCodeId, ItemClassificationId, Quantity, UnitOfMeasureId,  
									UnitCost,ExtendedCost,Memo,IsDeferred, QuantityReserved, QuantityIssued, MaterialMandatoriesId,ProvisionId,CreatedDate, CreatedBy, UpdatedDate,   
									UpdatedBy, MasterCompanyId, IsActive, IsDeleted)   
									SELECT @WorkOrderMaterialsKitMappingId, @WorkOrderId, WOWF.WorkFlowWorkOrderId, @ItemMasterId, WOM.TaskId, @ConditionId, WOM.ItemClassificationId, @Quantity, @UnitOfMeasureId, 0, 0, @Memo,   
									WOM.IsDeferred, 0, 0, WOM.MaterialMandatoriesId,WOM.ProvisionId,GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0   
									FROM dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK)   
									JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId  
									WHERE WOM.WorkOrderMaterialsKitId = @WorkOrderMaterialsId;  
  
									SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY();
								END

								INSERT INTO dbo.WorkOrderMaterialStockLineKit (WorkOrderMaterialsKitId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QuantityTurnIn, QtyReserved, QtyIssued,   
								UnitCost,ExtendedCost,UnitPrice,CreatedDate, CreatedBy, UpdatedDate,UpdatedBy, MasterCompanyId, IsActive, IsDeleted)   
								SELECT @NewWorkOrderMaterialsId, @StockLineId, @ItemMasterId, WOM.ProvisionId, @ConditionId, @Quantity, @Quantity, 0, 0, 0, 0, 0,  
								GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0   
								FROM dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK)   
								WHERE WOM.WorkOrderMaterialsKitId = @NewWorkOrderMaterialsId;

								--UPDATE QTY TO TURN IN IF MISMATCH  
								SELECT @QtyTendered = SUM(ISNULL(sl.QuantityTurnIn,0))   
								FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)  
								JOIN dbo.Stockline sl WITH (NOLOCK) ON womsl.StockLIneId = sl.StockLIneId  
								JOIN dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK) ON womsl.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId  
								WHERE WOM.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId  
								AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0  
  
								SELECT @QtyToTendered = SUM(ISNULL(QtyToTurnIn,0)) FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK)  
								WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId  
  
								IF (@QtyTendered > @QtyToTendered)  
								BEGIN  
									UPDATE dbo.WorkOrderMaterialsKit SET QtyToTurnIn = @QtyTendered FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId  
								END
								
								--UPDATE QTY REQ IN MATERIAL IF REQ QTY MISMATCH  
								SELECT @TotalStlQtyReq = SUM(ISNULL(womsl.Quantity,0))   
								FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)  
								WHERE womsl.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0   
  
								IF(@TotalStlQtyReq > (SELECT ISNULL(Quantity, 0) FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId))  
								BEGIN  
									UPDATE dbo.WorkOrderMaterialsKit SET Quantity = @TotalStlQtyReq FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId  
								END

								--UPDATE WO PART LEVEL TOTAL COST  
								EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy;

								--UPDATE WO PART LEVEL TOTAL COST  
								EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;  
  
								--UPDATE MATERIALS COST  
								EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @NewWorkOrderMaterialsId;

								--Around 3 second when all three update SP executes
							END
						END

						SET @CurrentWOM += 1;
					END

					IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_Parent') IS NOT NULL  
						DROP TABLE #tmpCodePrefixes_Parent   
  
					IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL  
						DROP TABLE #tmpPNManufacturer   

					IF OBJECT_ID('tempdb..#TenderWOMListData') IS NOT NULL
						DROP TABLE #TenderWOMListData

					--SELECT * FROM #TenderWOMListData;
			END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_TenderMultipleStockLine' 
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