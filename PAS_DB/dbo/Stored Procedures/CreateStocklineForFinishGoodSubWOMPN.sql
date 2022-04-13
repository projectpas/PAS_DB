------------------------------------------------------------------------------------------------------


/*************************************************************           
 ** File:   [CreateStocklineForFinishGoodSubWOMPN]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Create Stockline For SUB Finished Good.    
 ** Purpose:         
 ** Date:   04/04/2022        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/04/2022   Hemant Saliya Created
     
-- EXEC [CreateStocklineForFinishGoodSubWOMPN] 26, 'Admin', 0
**************************************************************/

CREATE PROCEDURE [dbo].[CreateStocklineForFinishGoodSubWOMPN]
@SubWOPartNumberId BIGINT,
@UpdatedBy VARCHAR(50),
@IsMaterialStocklineCreate BIT = FLASE
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @StocklineId BIGINT;
				DECLARE @NewStocklineId BIGINT;
				DECLARE @RevisedConditionId BIGINT;
				DECLARE @MasterCompanyId BIGINT;
				DECLARE @SLCurrentNumber BIGINT;
				DECLARE @StockLineNumber VARCHAR(50);
				DECLARE @CNCurrentNumber BIGINT;	
				DECLARE @ControlNumber VARCHAR(50);
				DECLARE @IDCurrentNumber BIGINT;	
				DECLARE @IDNumber VARCHAR(50);
				DECLARE @WOPartNoID BIGINT;	
				DECLARE @ProvisionId BIGINT;
				DECLARE @WorkOrderId BIGINT;
				DECLARE @SubWorkOrderId BIGINT;
				DECLARE @WorkOrderWorkflowId BIGINT;
				DECLARE @SubWOQuantity INT = 1;	-- It will be Always 1
				DECLARE @OldWorkOrderMaterialsId BIGINT;	
				DECLARE @NewWorkOrderMaterialsId BIGINT;
				DECLARE @ModuleId BIGINT;	
				DECLARE @SubModuleId BIGINT;	
				DECLARE @ReferenceId BIGINT;	
				DECLARE @SubReferenceId BIGINT;	
				DECLARE @IsSerialised BIT;
				DECLARE @stockLineQty INT;
				DECLARE @stockLineQtyAvailable INT;
				DECLARE @count INT;
				DECLARE @slcount INT;
				DECLARE @IsAddUpdate BIT; 
				DECLARE @ExecuteParentChild BIT; 
				DECLARE @UpdateQuantities BIT;
				DECLARE @IsOHUpdated BIT; 
				DECLARE @AddHistoryForNonSerialized BIT; 
				DECLARE @WorkOrderNum VARCHAR(50);
				DECLARE @ExtStlNo VARCHAR(50);
				DECLARE @SubWorkOrderStatusId BIGINT;

				DECLARE @MSModuleID INT;
				DECLARE @EntityMSID BIGINT;

				SET @MSModuleID = 2; -- Stockline Module ID

				SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
				SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 33; -- For WORK ORDER Materials Module				
				SELECT @ProvisionId  = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE UPPER(StatusCode) = 'REPLACE';
				SELECT @SubWorkOrderStatusId  = Id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE UPPER(StatusCode) = 'CLOSED'

				SELECT	@StocklineId = StockLineId, 
						@SubWorkOrderId = SubWorkOrderId,
						@RevisedConditionId = CASE WHEN ISNULL(RevisedConditionId, 0) > 0 THEN RevisedConditionId ELSE ConditionId END,
						@MasterCompanyId  = MasterCompanyId
				FROM dbo.SubWorkOrderPartNumber WITH(NOLOCK) WHERE SubWOPartNoId = @SubWOPartNumberId

				SELECT @ExtStlNo = StockLineNumber, @EntityMSID=ManagementStructureId FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @StocklineId;
				

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

				INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
				SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId IN (30,17,9) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

				DECLARE @currentNo AS BIGINT = 0;
				DECLARE @stockLineCurrentNo AS BIGINT;
				DECLARE @ItemMasterId AS BIGINT;
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

				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 30))
				BEGIN 

					SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@stockLineCurrentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 30), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 30)))

					UPDATE DBO.ItemMaster
					SET CurrentStlNo = @stockLineCurrentNo
					WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId
				END
				ELSE 
				BEGIN
					ROLLBACK TRAN;
				END

				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 17))
				BEGIN 

					SET @IDNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(1,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 17), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 17)))
				END
				ELSE 
				BEGIN
					ROLLBACK TRAN;
				END

				IF((SELECT COUNT(1) FROM dbo.SubWorkOrderPartNumber WITH (NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND SubWorkOrderStatusId <> @SubWorkOrderStatusId ) = 0)
				BEGIN
				
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
						   ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],IsFinishGood, IsTurnIn)
					 SELECT [PartNumber],@StockLineNumber,[StocklineMatchKey],[ControlNumber],[ItemMasterId],1,@RevisedConditionId
						   ,[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo]
						   ,[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber]
						   ,[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId]
						   ,[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber]
						   ,[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER]
						   ,[OEM],[Memo],[ManagementStructureId],[LegalEntityId],[MasterCompanyId],@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE()
						   ,[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId]
						   ,[UnitSalePriceAdjustmentReasonTypeId],@IDNumber,[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace]
						   ,[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],0,[PurchaseOrderPartRecordId]
						   ,[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId]
						   --,[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved]
						   ,0,1,0,1,1,0,[QtyReserved]
						   ,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId]
						   ,[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId]
						   ,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate]
						   ,[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId]
						   ,[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition]
						   ,[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber]
						   ,[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],[CustomerId],[CustomerName],[isCustomerstockType]
						   ,[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType]
						   ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],1, 1
					FROM dbo.Stockline WITH(NOLOCK)
					WHERE StockLineId = @StocklineId

					SELECT @NewStocklineId = SCOPE_IDENTITY()

					UPDATE CodePrefixes SET CurrentNummber = @SLCurrentNumber WHERE CodeTypeId = 30 AND MasterCompanyId = @MasterCompanyId
					--UPDATE CodePrefixes SET CurrentNummber = @CNCurrentNumber WHERE CodeTypeId = 9 AND MasterCompanyId = @MasterCompanyId

					EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId

					EXEC USP_SaveSLMSDetails @MSModuleID, @NewStocklineId, @EntityMSID, @MasterCompanyId, 'SWO Close Job'

					SELECT	@WorkOrderWorkflowId = WFWO.WorkFlowWorkOrderId, 
							@OldWorkOrderMaterialsId =  SWO.WorkOrderMaterialsId,
							@WorkOrderId = SWO.WorkOrderId
					FROM dbo.SubWorkOrderPartNumber SWP WITH(NOLOCK) 
					JOIN dbo.SubWorkOrder SWO WITH(NOLOCK) ON SWP.SubWorkOrderId = SWO.SubWorkOrderId
					JOIN dbo.WorkOrderWorkflow WFWO WITH(NOLOCK) ON WFWO.WorkOrderPartNoId = SWO.WorkOrderPartNumberId
					WHERE SWP.SubWOPartNoId = @SubWOPartNumberId AND SWO.StockLineId = @StocklineId

					SELECT @WorkOrderNum = WorkOrderNum FROM dbo.WorkOrder WO WITH(NOLOCK) where WO.WorkOrderId = @WorkOrderId				

					UPDATE dbo.WorkOrderMaterialStockLine SET Quantity = 0, QtyReserved = 0, QtyIssued = 0 WHERE StockLineId = @StocklineId AND WorkOrderMaterialsId = @OldWorkOrderMaterialsId;

					UPDATE dbo.WorkOrderMaterials 
						SET Quantity = ISNULL(WOM.Quantity,0) - @SubWOQuantity,
							--QuantityReserved = ISNULL(WOM.QuantityReserved,0) - @SubWOQuantity,
							--TotalReserved = ISNULL(WOM.TotalReserved,0) - @SubWOQuantity,
							UpdatedDate = GETDATE()												
					FROM dbo.WorkOrderMaterials WOM WHERE WorkOrderMaterialsId = @OldWorkOrderMaterialsId;

					UPDATE StockLine 
						SET QuantityOnHand = ISNULL(SL.QuantityOnHand,0) - ISNULL(@SubWOQuantity,0),								 
							--QuantityReserved = ISNULL(SL.QuantityReserved,0) - ISNULL(@SubWOQuantity,0),		
							UpdatedDate = GETDATE(), UpdatedBy = @UpdatedBy, WorkOrderMaterialsId = @NewWorkOrderMaterialsId
					FROM dbo.StockLine SL 
					WHERE SL.StockLineId = @StocklineId

					INSERT INTO [dbo].[StockLineHistoryDetails] ([StocklineId], [ItemMasterId_o], [ItemMasterId_m], [StocklineNum],
						[PurchaseOrderId], [PONum], [POCost], [ConditionId], [ConditionName], [RepairOrderId], [RONum], [WorkscoprId],[WorkscopeName],
						[RepairCost],[VendorId],[VendorName],[RecdDate],[Cost],[LotNum],[WONum],[PreviousStockLine],[extstocklineId],[InventoryCost],[AltEquiPartNumber])
					SELECT @NewStocklineId, STL.ItemMasterId, 0, STL.StockLineNumber,
						STL.PurchaseOrderId, NULL, 0, STL.ConditionId,STL.Condition,NULL,NULL,NULL,NULL,
						NULL,STL.VendorId,null,STL.ReceivedDate,0,STL.LotNumber, @WorkOrderNum,@ExtStlNo,@StocklineId,STL.UnitCost,null
					FROM DBO.Stockline STL  WITH(NOLOCK) 
					WHERE STL.StockLineId = @NewStocklineId

					-- #STEP 2 ADD STOCKLINE TO WO MATERIAL LIST
						IF(@IsMaterialStocklineCreate = 1)
						BEGIN
					
						SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId 
							FROM dbo.WorkOrderMaterials WITH(NOLOCK)
							WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = @RevisedConditionId AND 
										WorkFlowWorkOrderId = @WorkOrderWorkflowId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0
						
							IF((SELECT COUNT(1) FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = @RevisedConditionId AND 
								WorkFlowWorkOrderId = @WorkOrderWorkflowId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0) > 0)
							BEGIN
								UPDATE dbo.WorkOrderMaterials 
									SET Quantity = ISNULL(Quantity, 0) + @SubWOQuantity,
										QuantityReserved = ISNULL(QuantityReserved, 0) + @SubWOQuantity,
										TotalReserved = ISNULL(TotalReserved, 0) + @SubWOQuantity
								FROM dbo.WorkOrderMaterials WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
							END
							ELSE
							BEGIN
								INSERT INTO dbo.WorkOrderMaterials (WorkOrderId, WorkFlowWorkOrderId, ItemMasterId, TaskId, ConditionCodeId, ItemClassificationId, Quantity, UnitOfMeasureId,
											UnitCost,ExtendedCost,Memo,IsDeferred, QuantityReserved, TotalReserved, QuantityIssued, MaterialMandatoriesId,ProvisionId,CreatedDate, CreatedBy, UpdatedDate, 
											UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
								SELECT WOM.WorkOrderId, WOWF.WorkFlowWorkOrderId, @ItemMasterId, WOM.TaskId, @RevisedConditionId, WOM.ItemClassificationId, @SubWOQuantity, WOM.UnitOfMeasureId, 0, 0, WOM.Memo, 
											WOM.IsDeferred, @SubWOQuantity, @SubWOQuantity, 0, WOM.MaterialMandatoriesId,@ProvisionId,GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0 
								FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) 
									JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
								WHERE WOM.WorkOrderMaterialsId = @OldWorkOrderMaterialsId;

								SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY()
							END

							INSERT INTO dbo.WorkOrderMaterialStockLine (WorkOrderMaterialsId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QtyReserved, QtyIssued,
										UnitCost,ExtendedCost,UnitPrice,CreatedDate, CreatedBy, UpdatedDate,UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							SELECT @NewWorkOrderMaterialsId, @NewStocklineId, @ItemMasterId, @ProvisionId, @RevisedConditionId, @SubWOQuantity, @SubWOQuantity, 0, 0, 0, 0,
										GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0 
							FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) 
							WHERE WOM.WorkOrderMaterialsId = @NewWorkOrderMaterialsId;

							SET @count = @SubWOQuantity;
							SET @slcount = @SubWOQuantity;
							SET @IsAddUpdate = 0;
							SET @ExecuteParentChild = 1;
							SET @UpdateQuantities = 1;
							SET @IsOHUpdated = 0;
							SET @AddHistoryForNonSerialized = 0;					

							--FOR STOCK LINE HISTORY
							WHILE @count >= @slcount
							BEGIN
							
								SET @StocklineId = @NewStocklineId;
								SET @ReferenceId = @WorkOrderId;
								SET @SubReferenceId = @NewWorkOrderMaterialsId

								SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

								IF (@IsSerialised = 0 AND (@stockLineQtyAvailable > 1 OR @stockLineQty > 1))
								BEGIN
									EXEC [dbo].[USP_CreateChildStockline]  @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = @IsAddUpdate, @ExecuteParentChild = @ExecuteParentChild, @UpdateQuantities = @UpdateQuantities, @IsOHUpdated = @IsOHUpdated, @AddHistoryForNonSerialized = @AddHistoryForNonSerialized, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId
								END
								ELSE
								BEGIN
									EXEC [dbo].[USP_CreateChildStockline]  @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = 0, @ExecuteParentChild = 0, @UpdateQuantities = 0, @IsOHUpdated = 0, @AddHistoryForNonSerialized = 1, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId
								END

								SET @slcount = @slcount + 1;
							END;

							UPDATE StockLine 
								SET QuantityAvailable = ISNULL(SL.QuantityAvailable,0) - ISNULL(@SubWOQuantity,0),								 
									QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(@SubWOQuantity,0),		
									UpdatedDate = GETDATE(), UpdatedBy = @UpdatedBy, WorkOrderMaterialsId = @NewWorkOrderMaterialsId
							FROM dbo.StockLine SL 
							WHERE SL.StockLineId = @NewStocklineId

							--UPDATE WO PART LEVEL TOTAL COST
							EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;

							--UPDATE WO PART LEVEL TOTAL COST
							EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;

							--UPDATE MATERIALS COST
							EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @NewWorkOrderMaterialsId;
						END


					IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
					BEGIN
					DROP TABLE #tmpCodePrefixes 
					END

					IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL
					BEGIN
						DROP TABLE #tmpPNManufacturer 
					END		
				
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
              , @AdhocComments     VARCHAR(150)    = 'CreateStocklineForFinishGoodSubWOMPN' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWOPartNumberId, '') + ''
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