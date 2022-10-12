-----------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [CreateStocklineForFinishGoodMPN]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Create Stockline For Finished Good.    
 ** Purpose:         
 ** Date:   09/09/2021        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/09/2021   Hemant Saliya		Created
	2    28/09/2021   Hemant Saliya		Update for Existing STL & PN
	3    05/05/2022   Hemant Saliya		Update Existing STL Inactive
     
-- EXEC [CreateStocklineForFinishGoodMPN] 55
**************************************************************/

CREATE PROCEDURE [dbo].[CreateStocklineForFinishGoodMPN]
@WorkOrderPartNumberId BIGINT
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
				DECLARE @IDNumber VARCHAR(50);
				DECLARE @ModuleID INT;
				DECLARE @EntityMSID BIGINT;
				DECLARE @IsExchangeWO BIT;
				DECLARE @ReceivingCustomerWorkId BIGINT;	

				SET @ModuleID = 2; -- Stockline Module ID

				SELECT	@StocklineId = StockLineId, 
						@RevisedConditionId = CASE WHEN ISNULL(RevisedConditionId, 0) > 0 THEN RevisedConditionId ELSE ConditionId END,
						@MasterCompanyId  = MasterCompanyId,
						@EntityMSID = ManagementStructureId,
						@ReceivingCustomerWorkId = ReceivingCustomerWorkId
				FROM dbo.WorkOrderPartNumber WITH(NOLOCK) 
				WHERE ID = @WorkOrderPartNumberId

				SELECT @IsExchangeWO = CASE WHEN ISNULL(ExchangeSalesOrderId , 0) > 0 THEN 1 ELSE 0 END
				FROM dbo.ReceivingCustomerWork WITH(NOLOCK) WHERE ReceivingCustomerWorkId = @ReceivingCustomerWorkId

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

				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 9))
				BEGIN 
					SELECT 
						@CNCurrentNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
							ELSE CAST(StartsFrom AS BIGINT) + 1 END 
					FROM #tmpCodePrefixes WHERE CodeTypeId = 9

					SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@CNCurrentNumber,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 9), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 9)))
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
				   ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],IsFinishGood)
			 SELECT [PartNumber],@StockLineNumber,[StocklineMatchKey],@ControlNumber,[ItemMasterId],1,@RevisedConditionId
				   ,[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo]
				   ,[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber]
				   ,[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId]
				   ,[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber]
				   ,[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER]
				   ,[OEM],[Memo],[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETDATE(),GETDATE()
				   ,[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId]
				   ,[UnitSalePriceAdjustmentReasonTypeId],@IDNumber,[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace]
				   ,[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],0,[PurchaseOrderPartRecordId]
				   ,[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId]
				   ,0,0,0,1,1,0,[QtyReserved]
				   ,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId]
				   ,[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost], CASE WHEN @IsExchangeWO = 1 THEN 0 ELSE [IsCustomerStock] END,[EntryDate],[LotCost],[NHAItemMasterId]
				   ,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate]
				   ,[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId]
				   ,[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition]
				   ,[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber]
				   ,[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],CASE WHEN @IsExchangeWO = 1 THEN NULL ELSE [CustomerId] END,CASE WHEN @IsExchangeWO = 1 THEN NULL ELSE [CustomerName] END,CASE WHEN @IsExchangeWO = 1 THEN 0 ELSE [isCustomerstockType] END 
				   ,[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType]
				   ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],1
			FROM dbo.Stockline WITH(NOLOCK)
			WHERE StockLineId = @StocklineId

				SELECT @NewStocklineId = SCOPE_IDENTITY()

				UPDATE CodePrefixes SET CurrentNummber = @SLCurrentNumber WHERE CodeTypeId = 30 AND MasterCompanyId = @MasterCompanyId
				UPDATE CodePrefixes SET CurrentNummber = @CNCurrentNumber WHERE CodeTypeId = 9 AND MasterCompanyId = @MasterCompanyId

				EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId

				INSERT INTO [dbo].[TimeLife]
					([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair]
					,[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew]
					,[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
					,[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineId],[DetailsNotProvided]
					,[RepairOrderId],[RepairOrderPartRecordId])
				SELECT [CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair]
					,[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew]
					,[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETDATE(), GETDATE()
					,[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],@NewStocklineId,[DetailsNotProvided]
					,[RepairOrderId],[RepairOrderPartRecordId] 
				FROM TimeLife TL WITH (NOLOCK) WHERE TL.StockLineId = @StocklineId

				UPDATE [dbo].[WorkOrderPartNumber] SET StockLineId = @NewStocklineId WHERE ID = @WorkOrderPartNumberId;

				UPDATE [dbo].[Stockline] SET QuantityOnHand = 0, QuantityAvailable = 0, isActive = 0, 
					Memo = 'This stockline has been repaired. Repaired stockline is: ' + @StockLineNumber + ' and Control Number is: ' + @ControlNumber
				WHERE StockLineId = @StocklineId

				EXEC USP_SaveSLMSDetails @ModuleID, @NewStocklineId, @EntityMSID, @MasterCompanyId, 'WO Close Job'

				IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
				BEGIN
					DROP TABLE #tmpCodePrefixes 
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
              , @AdhocComments     VARCHAR(150)    = 'CreateStocklineForFinishGoodMPN' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderPartNumberId, '') + ''
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