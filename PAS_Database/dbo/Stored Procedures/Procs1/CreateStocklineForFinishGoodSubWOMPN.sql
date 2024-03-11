
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
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
 1    04/04/2022   Hemant Saliya   Created  
 2    05/05/2022   Hemant Saliya   Update Existing STL Inactive  
 3    25/05/2023   Moin Bloch      Added Output Parameter For Return Newly Created StocklineId   
 4    06/15/2023   Devendra Shekh  changed function udfGenerateCodeNumber to [udfGenerateCodeNumberWithOutDash]
 5    08/24/2023   Moin Bloch      Updated Newly Created Stockline Unit Cost For Subwork Order
 6    08/28/2023   Moin Bloch      Added SubWorkOrder Labor + Part Cost Reverse Batch Entry 
 7    08/29/2023   Moin Bloch      Added WO Part Issue Batch Entry 
 8    10/16/2023   Devendra Shekh  TIMELIFE issue resolved
 9    01/17/2024   Hemant Saliya   Update Revised STL While Close Sub WO  
10    01/17/2024   Hemant Saliya   Update RepairOrderUnitCost NULL to Zero
11    01/22/2024   Hemant Saliya   Add For create Sub WO Stockline History
12    10/16/2023   Devendra Shekh  update revised serialnum close sub wo
13	  03/06/2023   Bhargav Saliya  Update History When We Close The Sub WO 
       
-- EXEC sp_executesql N'EXEC dbo.CreateStocklineForFinishGoodSubWOMPN @SubWOPartNumberId, @UpdatedBy, @IsMaterialStocklineCreate',N'@SubWOPartNumberId bigint,@UpdatedBy nvarchar(11),@IsMaterialStocklineCreate bit',@SubWOPartNumberId=290,@UpdatedBy=N'ADMIN 
ADMIN',@IsMaterialStocklineCreate=1  
**************************************************************/  
  
CREATE   PROCEDURE [dbo].[CreateStocklineForFinishGoodSubWOMPN]  
@SubWOPartNumberId BIGINT,  
@UpdatedBy VARCHAR(50),  
@IsMaterialStocklineCreate BIT = FLASE,  
@ReturnStocklineId BIGINT = 0 OUTPUT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
    DECLARE @StocklineId BIGINT;  
	DECLARE @OldStocklineId BIGINT;  	
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
    DECLARE @SubWOQuantity INT = 1; -- It will be Always 1  
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
    DECLARE @UnitCost DECIMAL(18,2);  
    DECLARE @SubWorkOrderNum VARCHAR(50);  
    DECLARE @CustomerAffiliationId INT;  
	DECLARE @issued bit=1
	DECLARE @InvoiceId bigint=0
  
    DECLARE @MSModuleID INT;  
    DECLARE @EntityMSID BIGINT;  
    DECLARE @RevisedPartNoId BIGINT;  
    DECLARE @IsCustStock BIT;  

	DECLARE @TotalSubWorkOrderCost DECIMAL(18,2);
	DECLARE @DistributionMasterId bigint
	DECLARE @SubWorkOrderQty int = 1   --------------   SubworkOrder Qty Always 1 For Accounting Batch Entry        
    DECLARE @ModuleName varchar(200)='SWOP-PartsIssued'
	DECLARE @WOModuleName varchar(200)='WOP-PartsIssued'
	DECLARE @laborType varchar(200)='434'
	DECLARE @WorkFlowWorkOrderId BIGINT = 0; 
	DECLARE @RevisedSerialNumber VARCHAR(50) = '';
  
    SET @MSModuleID = 2; -- Stockline Module ID  
  
    SELECT @ModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';             -- For WORK ORDER Module  
    SELECT @SubModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMaterials'  -- For WORK ORDER Materials Module      
	
    SELECT @ProvisionId  = ProvisionId FROM [dbo].[Provision] WITH(NOLOCK) WHERE UPPER(StatusCode) = 'REPLACE';  
    SELECT @SubWorkOrderStatusId  = Id FROM [dbo].[WorkOrderStatus] WITH(NOLOCK) WHERE UPPER(StatusCode) = 'CLOSED'  

	SELECT @DistributionMasterId =ID from DistributionMaster WITH(NOLOCK)  where UPPER(DistributionCode)= UPPER('WOMATERIALGRIDTAB');
  
    SELECT @StocklineId = CASE WHEN ISNULL(RevisedStockLineId, 0) > 0 THEN RevisedStockLineId ELSE StockLineId END,   
	       @OldStocklineId = StockLineId,   
           @SubWorkOrderId = SubWorkOrderId,  
		   @WorkOrderId = WorkOrderId,
           @RevisedPartNoId = CASE WHEN ISNULL(RevisedItemmasterid, 0) > 0 THEN RevisedItemmasterid ELSE ItemMasterId END,  
           @RevisedConditionId = CASE WHEN ISNULL(RevisedConditionId, 0) > 0 THEN RevisedConditionId ELSE ConditionId END,  
           @MasterCompanyId  = MasterCompanyId,
		   @RevisedSerialNumber = ISNULL(RevisedSerialNumber, '')
    FROM dbo.SubWorkOrderPartNumber WITH(NOLOCK) WHERE SubWOPartNoId = @SubWOPartNumberId  
  
    SELECT @CustomerAffiliationId = CU.[CustomerAffiliationId]  
      FROM [dbo].[SubWorkOrderPartNumber] SWP WITH(NOLOCK)   
    INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWP.SubWorkOrderId = SWO.SubWorkOrderId  
    INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON SWO.WorkOrderId = WO.WorkOrderId  
    INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON WO.CustomerId = CU.CustomerId      
     WHERE SWP.[SubWOPartNoId] = @SubWOPartNumberId;  
       
    IF(@CustomerAffiliationId = 2)  -- 2 For External Customer  
    BEGIN  
     SET @IsCustStock = 1;  
    END  
    ELSE  
    BEGIN  
     SET @IsCustStock = 0;  
    END  
  
    SELECT @SubWorkOrderNum = [SubWorkOrderNo] from [dbo].[SubWorkOrder] WITH(NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId;  
                
    SELECT @ExtStlNo = [StockLineNumber], @EntityMSID = [ManagementStructureId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE StockLineId = @StocklineId;  
  
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
     SELECT ac.ItemMasterId, 
	        ac.ManufacturerId, 
			MAX(ac.StockLineId) StockLineId  
     FROM (SELECT DISTINCT ItemMasterId FROM dbo.Stockline WITH(NOLOCK)) ac1 CROSS JOIN  
          (SELECT DISTINCT ManufacturerId FROM dbo.Stockline WITH(NOLOCK)) ac2 LEFT JOIN dbo.Stockline ac WITH (NOLOCK) ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId  
		   WHERE ac.MasterCompanyId = @MasterCompanyId  GROUP BY ac.ItemMasterId, ac.ManufacturerId  HAVING COUNT(ac.ItemMasterId) > 0)  
  
    INSERT INTO #tmpPNManufacturer (ItemMasterId, ManufacturerId, StockLineNumber, CurrentStlNo, isSerialized)  
    SELECT CSTL.ItemMasterId, CSTL.ManufacturerId, StockLineNumber, ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo, IM.isSerialized  
    FROM CTE_Stockline CSTL INNER JOIN dbo.Stockline STL WITH(NOLOCK)   
    INNER JOIN dbo.ItemMaster IM WITH(NOLOCK) ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId  
    ON CSTL.StockLineId = STL.StockLineId  
    /* PN Manufacturer Combination Stockline logic */  
  
    INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)   
    SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
    FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId  
    WHERE CT.CodeTypeId IN (30,17,9) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;  
  
    DECLARE @currentNo AS BIGINT = 0;  
    DECLARE @stockLineCurrentNo AS BIGINT;  
    DECLARE @ItemMasterId AS BIGINT;  
    DECLARE @ManufacturerId AS BIGINT;  
  
    SELECT @ItemMasterId = CASE WHEN ISNULL(@RevisedPartNoId, 0) > 0 THEN @RevisedPartNoId ELSE ItemMasterId END, @ManufacturerId = ManufacturerId FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @StocklineId  
  
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
  
     SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@stockLineCurrentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 30), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 30)))  
  
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
  
     SET @IDNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(1,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 17), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 17)))  
    END  
    ELSE   
    BEGIN  
     ROLLBACK TRAN;  
    END  
  
    IF((SELECT COUNT(1) FROM [dbo].[SubWorkOrderPartNumber] WITH (NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNumberId AND [SubWorkOrderStatusId] = @SubWorkOrderStatusId ) = 1)  
    BEGIN  

	  --UPDATE UNITCOST IN NEWLY CREATED MATERIALS  STOCKLINE	 
	   DECLARE @ROUnitCost decimal(18,2) = 0  
	
	   SELECT @TotalSubWorkOrderCost = (ISNULL(SW.[PartsCost],0) + ISNULL(SW.[LaborCost],0))
         FROM [dbo].[SubWorkOrderMPNCostDetail] SW WITH(NOLOCK)
        WHERE [WorkOrderId] = @WorkOrderId AND [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNumberId;

		SET @ROUnitCost = @TotalSubWorkOrderCost;
		
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
         ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],IsFinishGood, IsTurnIn,SubWorkorderNumber,IsManualEntry,[IsStkTimeLife])  
      SELECT CASE WHEN ISNULL(@RevisedPartNoId, 0) > 0 THEN (SELECT PartNumber FROM dbo.ItemMaster IM WITH(NOLOCK) WHERE IM.ItemMasterId = @RevisedPartNoId) ELSE [PartNumber] END,@StockLineNumber,[StocklineMatchKey],[ControlNumber],@ItemMasterId,1,@RevisedConditionId  
         ,[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo]  
         ,[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber]  
         ,[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId]  
         ,[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId], ISNULL(@ROUnitCost, 0) ,[ReceivedDate],[ReceiverNumber]  
         ,[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER]  
         ,[OEM],[Memo],[ManagementStructureId],[LegalEntityId],[MasterCompanyId],@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE()  
         ,[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId]  
         ,[UnitSalePriceAdjustmentReasonTypeId],@IDNumber,[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace]  
         ,[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],0,[PurchaseOrderPartRecordId]  
         ,[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId]  
         --,[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved]  
         ,0,0,0,1,1,0,[QtyReserved]  
         ,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId]  
         ,[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],@IsCustStock,[EntryDate],[LotCost],[NHAItemMasterId]  
         ,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate]  
         ,[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],@SubWorkOrderId,[SubWOPartNoId],[IsOemPNId]  
         ,[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition]  
         ,[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber]  
         ,[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],[CustomerId],[CustomerName],[isCustomerstockType]  
         ,[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],ISNULL(@ROUnitCost, 0),[TaggedByType]  
         ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],1, 1,@SubWorkOrderNum,1,[IsStkTimeLife]
     FROM dbo.Stockline WITH(NOLOCK)  
     WHERE StockLineId = @StocklineId  
  
     SELECT @NewStocklineId = SCOPE_IDENTITY()  
  
     UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @SLCurrentNumber WHERE [CodeTypeId] = 30 AND MasterCompanyId = @MasterCompanyId  

	 UPDATE [dbo].[SubWorkOrderPartNumber] SET RevisedStocklineId = @NewStocklineId WHERE [SubWorkOrderId] = @SubWorkOrderId AND [SubWOPartNoId] = @SubWOPartNumberId
  
     EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId  

	DECLARE @IsStkTimeLife BIT
	SELECT @IsStkTimeLife = [IsStkTimeLife] FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @NewStocklineId 
  
	IF(@IsStkTimeLife = 1)
	BEGIN
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
	END
  
     EXEC USP_SaveSLMSDetails @MSModuleID, @NewStocklineId, @EntityMSID, @MasterCompanyId, 'SWO Close Job'  
  
     SELECT TOP 1 @WorkOrderWorkflowId = WFWO.WorkFlowWorkOrderId,   
            @OldWorkOrderMaterialsId =  SWO.WorkOrderMaterialsId,  
            @WorkOrderId = SWO.WorkOrderId,  
            @SubWorkOrderNum=SWO.SubWorkOrderNo  
     FROM [dbo].[SubWorkOrderPartNumber] SWP WITH(NOLOCK)   
     JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWP.SubWorkOrderId = SWO.SubWorkOrderId  
     JOIN [dbo].[WorkOrderWorkflow] WFWO WITH(NOLOCK) ON WFWO.WorkOrderPartNoId = SWO.WorkOrderPartNumberId  
     WHERE SWP.SubWOPartNoId = @SubWOPartNumberId --AND SWO.StockLineId = @StocklineId  
  
     SELECT @WorkOrderNum = WorkOrderNum FROM dbo.WorkOrder WO WITH(NOLOCK) where WO.WorkOrderId = @WorkOrderId      
  
     UPDATE [dbo].[WorkOrderMaterialStockLine] SET Quantity = Quantity - ISNULL(@SubWOQuantity,0), QtyReserved = QtyReserved, QtyIssued = QtyIssued WHERE [StockLineId] = @StocklineId AND WorkOrderMaterialsId = @OldWorkOrderMaterialsId;  
  
     UPDATE [dbo].[WorkOrderMaterials] SET Quantity = ISNULL(WOM.Quantity,0) - ISNULL(@SubWOQuantity,0), UpdatedDate = GETUTCDATE()              
     FROM dbo.WorkOrderMaterials WOM WHERE WorkOrderMaterialsId = @OldWorkOrderMaterialsId;  
  
     UPDATE StockLine   
      SET QuantityOnHand = ISNULL(SL.QuantityOnHand,0) - ISNULL(@SubWOQuantity,0),
		  QuantityReserved = ISNULL(SL.QuantityReserved,0) - ISNULL(@SubWOQuantity,0),
       UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy, WorkOrderMaterialsId = @NewWorkOrderMaterialsId,         
       Memo = 'This stockline has been repaired. Repaired stockline is: ' + @StockLineNumber + ' and Control Number is: ' + @ControlNumber  
     FROM dbo.StockLine SL   
     WHERE SL.StockLineId = @StocklineId  
  
     UPDATE [dbo].[Stockline] SET isActive = 0        
     WHERE StockLineId = @StocklineId AND QuantityOnHand = 0 AND QuantityAvailable = 0  

	 DECLARE @SubWorkOrderModule AS BIGINT = 16; -- For Sub Work Order

	 EXEC USP_AddUpdateStocklineHistory @NewStocklineId, @SubWorkOrderModule, @SubWorkOrderId, NULL, NULL, 15, 1, @UpdatedBy;

	 --When We Close The Sub WO At That Time Update History
	 DECLARE @UpdatedQuantityOnHand INT = NULL;
	 SELECT @UpdatedQuantityOnHand = QuantityOnHand FROM [dbo].[Stockline] WITH(NOLOCK) WHERE StockLineId = @StocklineId AND QuantityOnHand = 0 AND QuantityAvailable = 0; 
	 SELECT ActionId fROM StklineHistory_Action wHERE [Type] = 'Close-Sub-WorkOrder' AND [DisplayName] = 'CLOSED SUB WORKORDER'
	 IF(ISNULL(@UpdatedQuantityOnHand,0) = 0)
	 BEGIN
		 EXEC USP_AddUpdateStocklineHistory @StocklineId, @SubWorkOrderModule, @SubWorkOrderId, NULL, NULL, ActionId, 0, @UpdatedBy;
	 END

  
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
			  QuantityIssued = ISNULL(QuantityIssued, 0) + @SubWOQuantity,  
			  TotalIssued = ISNULL(TotalIssued, 0) + @SubWOQuantity  

			FROM dbo.WorkOrderMaterials WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId  
       END  
       ELSE  
       BEGIN  
          
        SELECT @UnitCost = UnitCost FROM [dbo].[Stockline] WHERE StockLineId = @NewStocklineId;  
		
        INSERT INTO dbo.WorkOrderMaterials (WorkOrderId, WorkFlowWorkOrderId, ItemMasterId, TaskId, ConditionCodeId, ItemClassificationId, Quantity, UnitOfMeasureId,  
           UnitCost,ExtendedCost,Memo,IsDeferred, QuantityReserved, TotalReserved, QuantityIssued,TotalIssued, MaterialMandatoriesId,ProvisionId,CreatedDate, CreatedBy, UpdatedDate,   
           UpdatedBy, MasterCompanyId, IsActive, IsDeleted, isFromSubWorkOrder)   
        SELECT WOM.WorkOrderId, WOWF.WorkFlowWorkOrderId, @ItemMasterId, WOM.TaskId, @RevisedConditionId, WOM.ItemClassificationId, @SubWOQuantity, WOM.UnitOfMeasureId, @UnitCost, (ISNULL(@UnitCost, 0) * ISNULL(@SubWOQuantity, 0)), WOM.Memo,   
           WOM.IsDeferred, 0, 0, @SubWOQuantity,@SubWOQuantity, WOM.MaterialMandatoriesId,@ProvisionId,GETUTCDATE(), @UpdatedBy, GETUTCDATE(), @UpdatedBy, @MasterCompanyId, 1, 0 ,1  
        FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)   
         JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId  
        WHERE WOM.WorkOrderMaterialsId = @OldWorkOrderMaterialsId;  
  
        SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY()  
       END  
  
       INSERT INTO dbo.WorkOrderMaterialStockLine (WorkOrderMaterialsId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QtyReserved, QtyIssued,  
          UnitCost,ExtendedCost,UnitPrice,CreatedDate, CreatedBy, UpdatedDate,UpdatedBy, MasterCompanyId, IsActive, IsDeleted)   
       SELECT @NewWorkOrderMaterialsId, @NewStocklineId, @ItemMasterId, @ProvisionId, @RevisedConditionId, @SubWOQuantity, 0, @SubWOQuantity, @UnitCost, (ISNULL(@UnitCost, 0) * ISNULL(@SubWOQuantity, 0)), @UnitCost,  
          GETUTCDATE(), @UpdatedBy, GETUTCDATE(), @UpdatedBy, @MasterCompanyId, 1, 0   
       FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)   
       WHERE WOM.WorkOrderMaterialsId = @NewWorkOrderMaterialsId;  

	   SELECT @WorkFlowWorkOrderId = WOM.[WorkFlowWorkOrderId]  FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = @NewWorkOrderMaterialsId;  
	     
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
          SET [QuantityAvailable] = ISNULL(SL.QuantityAvailable,0) - ISNULL(@SubWOQuantity,0),
			  [QuantityOnHand] = ISNULL(SL.QuantityOnHand,0) - ISNULL(@SubWOQuantity,0),
              [QuantityIssued] = ISNULL(SL.QuantityIssued,0) + ISNULL(@SubWOQuantity,0),    
              [UpdatedDate] = GETUTCDATE(), 
			  [UpdatedBy] = @UpdatedBy, 
			  [WorkOrderMaterialsId] = @NewWorkOrderMaterialsId,  
              [Memo] = 'This stockline has been updated.Sub WO is: ' + @SubWorkOrderNum + ' and Main WO is: ' + @WorkOrderNum,
			  [SerialNumber] = CASE WHEN ISNULL(@RevisedSerialNumber, '') != '' THEN @RevisedSerialNumber ELSE [SerialNumber] END,
			  [isSerialized] = CASE WHEN ISNULL(@RevisedSerialNumber, '') != '' THEN 1 ELSE [isSerialized] END
         FROM [dbo].[StockLine] SL WITH(NOLOCK) WHERE SL.[StockLineId] = @NewStocklineId;  


		DECLARE @ActionId INT = 0;
		SET @ActionId = 4; -- Issue
		EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @NewStocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @SubWOQuantity, @UpdatedBy = @UpdatedBy;

		 		  
       --UPDATE WO PART LEVEL TOTAL COST  
       EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;  
  
       --UPDATE WO PART LEVEL TOTAL COST  
       EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;  
  
       --UPDATE MATERIALS COST  
       EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @NewWorkOrderMaterialsId; 

	   --  Added SubWorkOrder Labor + Part Cost Reverse Batch Entry 
	   IF NOT EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([GlAccountId],0) = 0)
	   BEGIN
			EXEC [dbo].[USP_BatchTriggerBasedonDistributionForSubWorkOrder] @DistributionMasterId,@SubWorkOrderId,@SubWOPartNumberId,@OldWorkOrderMaterialsId,0,@OldStocklineId,@SubWorkOrderQty,'',1,@TotalSubWorkOrderCost,@ModuleName,@MasterCompanyId,@UpdatedBy
	   END	
	   
	   --  Added WO Part Issue Batch Entry 
	   IF NOT EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([GlAccountId],0) = 0)
	   BEGIN
	   		EXEC [dbo].[USP_BatchTriggerBasedonDistribution] @DistributionMasterId,@WorkOrderId,0,@WorkFlowWorkOrderId,@InvoiceId,@NewStocklineId,@SubWorkOrderQty,@laborType,@issued,0,@WOModuleName,@MasterCompanyId,@UpdatedBy
	   END

      END  
  
     SELECT @ReturnStocklineId = @NewStocklineId;  
            
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
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'CreateStocklineForFinishGoodSubWOMPN'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWOPartNumberId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName         = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END