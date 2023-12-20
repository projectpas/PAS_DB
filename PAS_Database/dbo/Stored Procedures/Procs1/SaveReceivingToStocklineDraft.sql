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
    2    05/13/2022   Devendra Shekh	added [IsStkTimeLife] for insert  
	3    12/04/2023   Shrey Chandegara	Updated For Insert into NonStockInventoryDraft  
	4    12/20/2023   Vishal Suthar		Fixed non stock issues
         
 EXEC [SaveReceivingToStocklineDraft] 2281, 'ADMIN User'    
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
    DECLARE @ShippingAccountNo VARCHAR(100);    
    DECLARE @ManagementStructureId BIGINT;    
    DECLARE @IsSerialized BIT = 0;    
	DECLARE @LotId BIGINT = NULL  
    
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
    SELECT POP.PurchaseOrderPartRecordId FROM dbo.PurchaseOrderPart POP WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND POP.ItemTypeId = 1    
    AND (PurchaseOrderPartRecordId NOT IN (SELECT POPI.ParentId FROM dbo.PurchaseOrderPart POPI WITH(NOLOCK) WHERE POPI.PurchaseOrderId = @PurchaseOrderId AND ParentId IS NOT NULL))    
    AND (PurchaseOrderPartRecordId NOT IN (SELECT StkDraft.PurchaseOrderPartRecordId FROM dbo.StocklineDraft StkDraft WITH(NOLOCK) WHERE StkDraft.PurchaseOrderId = @PurchaseOrderId AND StkDraft.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId))  
    
    SELECT @LoopID = MAX(ID) FROM #tmpPurchaseOrderParts;    
    
    WHILE (@LoopID > 0)    
    BEGIN    
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
     SELECT @OrderDate = PO.OpenDate, @ManagementStructureId = PO.ManagementStructureId, @LotId = PO.LotId FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId;    
     SELECT @POUnitCost = IMS.PP_VendorListPrice FROM DBO.ItemMasterPurchaseSale IMS WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId;    
     SELECT @ShipViaId = ShipViaId, @ShipViaName = ShipVia, @ShippingAccountNo = ShippingAccountNo FROM AllShipVia WHERE ReferenceId = @PurchaseOrderId AND ModuleId = 13;    
    
     INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)    
     SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom    
     FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId    
     WHERE CT.CodeTypeId = @IdCodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;    
    
     SELECT @IsSerialized = ISNULL(IM.isSerialized, 0) FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId = @ItemMasterId;    
    
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
      [VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment],[IsStkTimeLife])    
    
      SELECT IM.partnumber, NULL, NULL, NULL, @ItemMasterId, @Quantity, @ConditionId, '', 0, NULL, IM.WarehouseId,     
      IM.LocationId, NULL, NULL, NULL, IM.ManufacturerId, IM.ManufacturerName, NULL, NULL, NULL, NULL,    
      NULL, NULL, NULL, NULL, NULL, NULL, NULL, @OrderDate, @PurchaseOrderId, CASE WHEN @POPartUnitCost = 0 THEN @POUnitCost ELSE @POPartUnitCost END, NULL,    
      NULL, NULL, GETUTCDATE(), NULL, NULL, NULL, CASE WHEN @POPartUnitCost = 0 THEN @POUnitCost ELSE @POPartUnitCost END, IM.GLAccountId, NULL, IM.IsHazardousMaterial, IM.IsPma,     
      IM.IsDER, IM.IsOEM, NULL, @ManagementStructureId, NULL, @MasterCompanyId, @UserName, @UserName, GETUTCDATE(), GETUTCDATE(), IM.isSerialized, NULL, NULL, IM.SiteId,    
      NULL, NULL, NULL, NULL, NULL, @IdNumber, 1, ((CASE WHEN @POPartUnitCost = 0 THEN @POUnitCost ELSE @POPartUnitCost END) * 1),     
      NULL, NULL, NULL, CASE WHEN @ShipViaId = 0 THEN NULL ELSE @ShipViaId END, NULL, 0, @PurchaseOrderPartRecordId, @ShippingAccountNo, '',    
	  NULL, 0, NULL, NULL, NULL, NULL, NULL, @QuantityOnHand, @QuantityAvailable,     
      NULL, NULL, NULL, 0, NULL, 0, NULL, 0, NULL, NULL, 1, 0, 0, NULL, NULL, NULL, @IsParent, 0, 1, NULL, NULL, NULL, NULL, @ConditionName,    
      IM.WarehouseName, IM.LocationName, '', '', '', IM.GLAccount, NULL, NULL, NULL, NULL, IM.SiteName, '', '',    
      '', NULL, NULL, @ShipViaName, NULL, NULL, 0, 'STL_DRFT-000000',     
      NULL, NULL, NULL, IM.PurchaseUnitOfMeasureId, IM.PurchaseUnitOfMeasure, NULL, NULL, 0, NULL, NULL, NULL,    
      NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL,    
      @LotId, NULL, NULL, NULL, NULL, NULL, @QtyToTraverse, NULL, NULL, NULL, NULL, NULL, NULL,    
      NULL, NULL, NULL, 0, 0, NULL,IM.isTimeLife    
      FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId = @ItemMasterId;    
    
      SELECT @NewStocklineDraftId = SCOPE_IDENTITY();    
    
      EXEC [PROCAddStockLineDraftMSData] @NewStocklineDraftId, @ManagementStructureId, @MasterCompanyId, @UserName, @UserName, 31, 1;    
    
      SET @LoopID_Qty = @LoopID_Qty - 1;    
      SET @CurrentIndex = @CurrentIndex + 1;      
     END    
    
     SET @LoopID = @LoopID - 1;    
    END    
    
    /* Start: Asset changes */
    IF OBJECT_ID(N'tempdb..#tmpPurchaseOrderPartsAsset') IS NOT NULL    
    BEGIN    
     DROP TABLE #tmpPurchaseOrderPartsAsset    
    END    
    
    CREATE TABLE #tmpPurchaseOrderPartsAsset    
    (    
     ID BIGINT NOT NULL IDENTITY,       
     PurchaseOrderPartRecordId BIGINT NULL    
    )    
    
    INSERT INTO #tmpPurchaseOrderPartsAsset (PurchaseOrderPartRecordId)     
    SELECT POP.PurchaseOrderPartRecordId FROM dbo.PurchaseOrderPart POP WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND POP.ItemTypeId = 11    
    AND (PurchaseOrderPartRecordId NOT IN (SELECT POPI.ParentId FROM dbo.PurchaseOrderPart POPI WITH(NOLOCK) WHERE POPI.PurchaseOrderId = @PurchaseOrderId AND ParentId IS NOT NULL))    
    AND (PurchaseOrderPartRecordId NOT IN (SELECT StkDraft.PurchaseOrderPartRecordId FROM dbo.AssetInventoryDraft StkDraft WITH(NOLOCK) WHERE StkDraft.PurchaseOrderId = @PurchaseOrderId AND StkDraft.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId))    
    
    DECLARE @LoopID_Asset AS int;    
    
    SELECT @LoopID_Asset = MAX(ID) FROM #tmpPurchaseOrderPartsAsset;    
    
    WHILE (@LoopID_Asset > 0)    
    BEGIN    
     DECLARE @POPartGLAccountId BIGINT = 0;    
     DECLARE @POPartGLAccountName VARCHAR(100) = '';    
    
     SET @PurchaseOrderPartRecordId = 0;    
     SET @QtyToTraverse = 0;    
     SET @QtyOrdered = 0;    
     SET @ItemMasterId = 0;    
     SET @ConditionId = 0;    
     SET @POUnitCost = 0;    
     SET @POPartUnitCost = 0;    
     SET @IdCodeTypeId = 0;    
     SET @MasterCompanyId = 0;    
     SET @ShipViaId = 0;    
     SET @ConditionName = '';    
     SET @ShipViaName = '';    
     SET @ManagementStructureId = 0;    
     SET @IsSerialized = 0;    
    
     SELECT @IdCodeTypeId = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'Id Number';      
    
     IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_Asset') IS NOT NULL      
     BEGIN      
      DROP TABLE #tmpCodePrefixes_Asset      
     END      
          
     CREATE TABLE #tmpCodePrefixes_Asset      
     (      
      ID BIGINT NOT NULL IDENTITY,       
      CodePrefixId BIGINT NULL,      
      CodeTypeId BIGINT NULL,      
      CurrentNumber BIGINT NULL,      
      CodePrefix VARCHAR(50) NULL,      
      CodeSufix VARCHAR(50) NULL,      
      StartsFrom BIGINT NULL,      
     )      
      
     SELECT @PurchaseOrderPartRecordId = PurchaseOrderPartRecordId FROM #tmpPurchaseOrderPartsAsset WHERE ID  = @LoopID_Asset;    
    
     SELECT @QtyToTraverse = POP.QuantityOrdered, @QtyOrdered = POP.QuantityOrdered, @ItemMasterId = POP.ItemMasterId, @ConditionId = POP.ConditionId, @ConditionName = POP.Condition, @MasterCompanyId = POP.MasterCompanyId, @POPartUnitCost = POP.UnitCost, 
   
     @POPartGLAccountId = POP.GlAccountId, @POPartGLAccountName = POP.GLAccount FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId;    
     SELECT @OrderDate = PO.OpenDate, @ManagementStructureId = PO.ManagementStructureId FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId;    
     SELECT @POUnitCost = IMS.PP_VendorListPrice FROM DBO.ItemMasterPurchaseSale IMS WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId;    
     SELECT @ShipViaId = ShipViaId, @ShipViaName = ShipVia, @ShippingAccountNo = ShippingAccountNo FROM DBO.AllShipVia WITH (NOLOCK) WHERE ReferenceId = @PurchaseOrderId AND ModuleId = 13;    
    
     INSERT INTO #tmpCodePrefixes_Asset (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)    
     SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom    
     FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId    
     WHERE CT.CodeTypeId = @IdCodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;    
    
     SELECT @IsSerialized = ISNULL(Asst.isSerialized, 0) FROM DBO.Asset Asst WITH (NOLOCK) WHERE Asst.AssetRecordId = @ItemMasterId;    
    
     SET @CurrentIndex = 0;    
     SET @LoopID_Qty = @QtyToTraverse;    
    
     SET @LoopID_Qty = @LoopID_Qty + 1;    
    
     WHILE (@LoopID_Qty > 0)    
     BEGIN    
      DECLARE @NewAssetStocklineDraftId BIGINT;    
      DECLARE @IsParent_Asset BIT = 1;    
          
      IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = @IdCodeTypeId))    
      BEGIN    
       IF (@CurrentIndex = 0)    
       BEGIN    
        SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END       
        FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = @IdCodeTypeId    
       END    
       ELSE    
       BEGIN    
        SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END    
        FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = @IdCodeTypeId    
       END    
          
       SET @IdNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentIdNumber,    
        (SELECT CodePrefix FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = @IdCodeTypeId),    
        (SELECT CodeSufix FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = @IdCodeTypeId)))      
      END    
    
      SET @Quantity = 1;    
      SET @QuantityAvailable = 1;    
      SET @QuantityOnHand = 1;    
          
      IF (@CurrentIndex = 0)    
      BEGIN    
       IF (@IsSerialized = 0)    
       BEGIN    
        SET @Quantity = @QtyOrdered;    
        SET @QuantityAvailable = @QtyOrdered;    
        SET @QuantityOnHand = @QtyOrdered;    
    
        SET @IsParent_Asset = 1;    
       END    
       ELSE IF (@IsSerialized = 1)    
       BEGIN    
        SET @Quantity = @QtyOrdered;    
        SET @QuantityAvailable = @QtyOrdered;    
        SET @QuantityOnHand = @QtyOrdered;    
    
        SET @IsParent_Asset = 0;    
       END    
      END    
      ELSE    
      BEGIN    
       IF (@IsSerialized = 0)    
       BEGIN    
        SET @IsParent_Asset = 0;    
       END    
       ELSE IF (@IsSerialized = 1)    
       BEGIN    
        SET @IsParent_Asset = 1;    
       END    
      END    
    
      INSERT INTO DBO.AssetInventoryDraft ([AssetInventoryId],[AssetRecordId],[AssetId],[AlternateAssetRecordId],[Name],[Description],[ManagementStructureId],    
      [CalibrationRequired],[CertificationRequired],[InspectionRequired],[VerificationRequired],[IsTangible],[IsIntangible],[AssetAcquisitionTypeId],[ManufacturerId],    
      [ManufacturedDate],[Model],[IsSerialized],[UnitOfMeasureId],[CurrencyId],[UnitCost],[ExpirationDate],[Memo],[AssetParentRecordId],[TangibleClassId],[AssetIntangibleTypeId],    
      [AssetCalibrationMin],[AssetCalibrationMinTolerance],[AssetCalibratonMax],[AssetCalibrationMaxTolerance],[AssetCalibrationExpected],[AssetCalibrationExpectedTolerance],    
      [AssetCalibrationMemo],[AssetIsMaintenanceReqd],[AssetMaintenanceIsContract],[AssetMaintenanceContractFile],[MaintenanceFrequencyMonths],[MaintenanceFrequencyDays],[MaintenanceDefaultVendorId],    
      [MaintenanceGLAccountId],[MaintenanceMemo],[IsWarrantyRequired],[WarrantyCompany],[WarrantyStartDate],[WarrantyEndDate],[WarrantyStatusId],[UnexpiredTime],[MasterCompanyId],    
      [AssetLocationId],[IsDeleted],[Warranty],[IsActive],[CalibrationDefaultVendorId],[CertificationDefaultVendorId],[InspectionDefaultVendorId],[VerificationDefaultVendorId],    
      [CertificationFrequencyMonths],[CertificationFrequencyDays],[CertificationDefaultCost],[CertificationGlAccountId],[CertificationMemo],[InspectionMemo],[InspectionGlaAccountId],    
      [InspectionDefaultCost],[InspectionFrequencyMonths],[InspectionFrequencyDays],[VerificationFrequencyDays],[VerificationFrequencyMonths],[VerificationDefaultCost],[CalibrationDefaultCost],    
      [CalibrationFrequencyMonths],[CalibrationFrequencyDays],[CalibrationGlAccountId],[CalibrationMemo],[VerificationMemo],[VerificationGlAccountId],[CalibrationCurrencyId],    
      [CertificationCurrencyId],[InspectionCurrencyId],[VerificationCurrencyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[AssetMaintenanceContractFileExt],[WarrantyFile],    
      [WarrantyFileExt],[MasterPartId],[EntryDate],[InstallationCost],[Freight],[Insurance],[Taxes],[TotalCost],[WarrantyDefaultVendorId],[WarrantyGLAccountId],[IsDepreciable],[IsNonDepreciable],    
      [IsAmortizable],[IsNonAmortizable],[SerialNo],[IsInsurance],[AssetLife],[WarrantyCompanyId],[WarrantyCompanyName],[WarrantyCompanySelectId],[WarrantyMemo],[IsQtyReserved],    
      [InventoryStatusId],[InventoryNumber],[AssetStatusId],[Level1],[Level2],[Level3],[Level4],[ManufactureName],[LocationName],[Qty],[StklineNumber],[AvailStatus],[PartNumber],    
      [ControlNumber],[TagDate],[ShippingViaId],[ShippingVia],[ShippingAccount],[ShippingReference],[RepairOrderId],[RepairOrderPartRecordId],[PurchaseOrderId],[PurchaseOrderPartRecordId],    
      [SiteId],[WarehouseId],[LocationId],[ShelfId],[BinId],[GLAccountId],[GLAccount],[SiteName],[Warehouse],[Location],[ShelfName],[BinName],[IsParent],[ParentId],[IsSameDetailsForAllParts],    
      [ReceiverNumber],[ReceivedDate],[CalibrationVendorId],[PerformedById],[LastCalibrationDate],[NextCalibrationDate])    
    
      SELECT 0, @ItemMasterId, '', NULL, '', NULL, @ManagementStructureId,    
      0, 0, 0, 0, 0, 0, A.AssetAcquisitionTypeId, A.ManufacturerId,    
      A.ManufacturedDate, A.Model, A.IsSerialized, A.UnitOfMeasureId, A.CurrencyId, CASE WHEN @POPartUnitCost = 0 THEN @POUnitCost ELSE @POPartUnitCost END, A.ExpirationDate, A.Memo, 0, A.TangibleClassId, A.AssetIntangibleTypeId,    
      NULL, NULL, NULL, NULL, NULL, NULL,     
      NULL, 0, A.AssetMaintenanceIsContract, NULL, 0, 0, NULL,    
      NULL, NULL, 0, NULL, NULL, NULL, 0, 0, @MasterCompanyId,    
      A.[AssetLocationId], 0, 0, 1, NULL, NULL, NULL, NULL,    
      0, 0, 0, NULL, NULL, NULL, NULL,    
      0, 0, 0, 0, 0, 0, NULL,    
      0, NULL, NULL, NULL, NULL, NULL, NULL,    
      NULL, NULL, NULL, @UserName, @UserName, GETUTCDATE(), GETUTCDATE(), A.[AssetMaintenanceContractFileExt], NULL,    
      NULL, A.[MasterPartId], A.[EntryDate], 0, 0, 0, 0, 0, NULL, NULL, A.[IsDepreciable], A.[IsNonDepreciable],    
      A.[IsAmortizable], A.[IsNonAmortizable], '', 0, 0, 0, NULL, 0, NULL, 0,    
      NULL, NULL, NULL, A.[Level1], A.[Level2], A.[Level3], A.[Level4], NULL, NULL, @Quantity, NULL, NULL, NULL,    
      NULL, NULL, CASE WHEN @ShipViaId = 0 THEN NULL ELSE @ShipViaId END, @ShipViaName, @ShippingAccountNo, NULL, NULL, NULL, @PurchaseOrderId, @PurchaseOrderPartRecordId,    
      A.SiteId, A.WarehouseId, NULL, A.ShelfId, A.BinId, @POPartGLAccountId, @POPartGLAccountName, NULL, NULL, NULL, NULL, NULL, @IsParent_Asset, 0, 1,    
      NULL, NULL, NULL, NULL, NULL, NULL    
      FROM DBO.Asset A WITH (NOLOCK) WHERE A.AssetRecordId = @ItemMasterId;    
    
      SELECT @NewAssetStocklineDraftId = SCOPE_IDENTITY();    
    
      EXEC dbo.[PROCAddStockLineDraftMSData] @NewAssetStocklineDraftId, @ManagementStructureId, @MasterCompanyId, @UserName, @UserName, 56, 1;    
    
      SET @LoopID_Qty = @LoopID_Qty - 1;    
      SET @CurrentIndex = @CurrentIndex + 1;      
     END    
    
     SET @LoopID_Asset = @LoopID_Asset - 1;    
    END    
   END    
  
    /* Start: Non Stock changes */    
    IF OBJECT_ID(N'tempdb..#tmpPurchaseOrderPartsNonStock') IS NOT NULL    
    BEGIN    
     DROP TABLE #tmpPurchaseOrderPartsNonStock    
    END    
    
    CREATE TABLE #tmpPurchaseOrderPartsNonStock    
    (    
     ID BIGINT NOT NULL IDENTITY,       
     PurchaseOrderPartRecordId BIGINT NULL    
    )    
    
    INSERT INTO #tmpPurchaseOrderPartsNonStock (PurchaseOrderPartRecordId)     
    SELECT POP.PurchaseOrderPartRecordId FROM dbo.PurchaseOrderPart POP WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND POP.ItemTypeId = 2    
    AND (PurchaseOrderPartRecordId NOT IN (SELECT POPI.ParentId FROM dbo.PurchaseOrderPart POPI WITH(NOLOCK) WHERE POPI.PurchaseOrderId = @PurchaseOrderId AND ParentId IS NOT NULL))    
    AND (PurchaseOrderPartRecordId NOT IN (SELECT StkDraft.PurchaseOrderPartRecordId FROM dbo.NonStockInventoryDraft StkDraft WITH(NOLOCK) WHERE StkDraft.PurchaseOrderId = @PurchaseOrderId AND StkDraft.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId))    
    
    DECLARE @LoopID_Nonstock AS int;    
    
    SELECT @LoopID_Nonstock = MAX(ID) FROM #tmpPurchaseOrderPartsNonStock;    
    
    WHILE (@LoopID_Nonstock > 0)    
    BEGIN    
        
	DECLARE @PONumber VARCHAR(100) = NULL;  
    
     SET @PurchaseOrderPartRecordId = 0;   
	 SET @PONumber = (SELECT PO.PurchaseOrderNumber FROM DBO.PurchaseOrder PO WHERE PO.PurchaseOrderId=@PurchaseOrderId);  
     SET @QtyToTraverse = 0;    
     SET @QtyOrdered = 0;    
     SET @ItemMasterId = 0;    
     SET @ConditionId = 0;    
     SET @POUnitCost = 0;    
     SET @POPartUnitCost = 0;    
     SET @IdCodeTypeId = 0;    
     SET @MasterCompanyId = 0;    
     SET @ShipViaId = 0;    
     SET @ConditionName = '';    
     SET @ShipViaName = '';    
     SET @ManagementStructureId = 0;    
     SET @IsSerialized = 0;    
    
     SELECT @IdCodeTypeId = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'Id Number';      
    
     IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_NonStock') IS NOT NULL      
     BEGIN      
      DROP TABLE #tmpCodePrefixes_NonStock      
     END      
          
	CREATE TABLE #tmpCodePrefixes_NonStock      
	(      
		ID BIGINT NOT NULL IDENTITY,       
		CodePrefixId BIGINT NULL,      
		CodeTypeId BIGINT NULL,      
		CurrentNumber BIGINT NULL,      
		CodePrefix VARCHAR(50) NULL,      
		CodeSufix VARCHAR(50) NULL,      
		StartsFrom BIGINT NULL,      
	)
      
     SELECT @PurchaseOrderPartRecordId = PurchaseOrderPartRecordId FROM #tmpPurchaseOrderPartsNonStock WHERE ID  = @LoopID_Nonstock;    
    
     SELECT @QtyToTraverse = POP.QuantityOrdered, @QtyOrdered = POP.QuantityOrdered, @ItemMasterId = POP.ItemMasterId, @ConditionId = POP.ConditionId, @ConditionName = POP.Condition, @MasterCompanyId = POP.MasterCompanyId, @POPartUnitCost = POP.UnitCost, 
  
   
      @POPartGLAccountId = POP.GlAccountId, @POPartGLAccountName = POP.GLAccount FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId;    
     SELECT @OrderDate = PO.OpenDate, @ManagementStructureId = PO.ManagementStructureId FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId;    
     SELECT @POUnitCost = IMS.PP_VendorListPrice FROM DBO.ItemMasterPurchaseSale IMS WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId;    
     SELECT @ShipViaId = ShipViaId, @ShipViaName = ShipVia, @ShippingAccountNo = ShippingAccountNo FROM DBO.AllShipVia WITH (NOLOCK) WHERE ReferenceId = @PurchaseOrderId AND ModuleId = 13;    
    
     INSERT INTO #tmpCodePrefixes_NonStock (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)    
     SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom    
     FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId    
     WHERE CT.CodeTypeId = @IdCodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;    
      
     SELECT @IsSerialized = ISNULL(Asst.IsSerialized, 0) FROM DBO.ItemMasterNonStock Asst WITH (NOLOCK) WHERE Asst.MasterPartId = @ItemMasterId;    

     SET @CurrentIndex = 0;    
     SET @LoopID_Qty = @QtyToTraverse;    
    
     SET @LoopID_Qty = @LoopID_Qty + 1;    
    
     WHILE (@LoopID_Qty > 0)    
     BEGIN    
      DECLARE @NewNonStocklineDraftId BIGINT;    
      DECLARE @IsParent_NonStock BIT = 1;    
          
      IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes_NonStock WHERE CodeTypeId = @IdCodeTypeId))    
      BEGIN    
       IF (@CurrentIndex = 0)    
       BEGIN    
        SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END       
        FROM #tmpCodePrefixes_NonStock WHERE CodeTypeId = @IdCodeTypeId    
       END    
       ELSE    
       BEGIN    
        SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END    
        FROM #tmpCodePrefixes_NonStock WHERE CodeTypeId = @IdCodeTypeId    
       END    
          
       SET @IdNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentIdNumber,    
        (SELECT CodePrefix FROM #tmpCodePrefixes_NonStock WHERE CodeTypeId = @IdCodeTypeId),    
        (SELECT CodeSufix FROM #tmpCodePrefixes_NonStock WHERE CodeTypeId = @IdCodeTypeId)))      
      END    
    
      SET @Quantity = 1;    
      SET @QuantityAvailable = 1;    
      SET @QuantityOnHand = 1;    
          
      IF (@CurrentIndex = 0)    
      BEGIN    
       IF (@IsSerialized = 0)    
       BEGIN    
        SET @Quantity = @QtyOrdered;    
        SET @QuantityAvailable = @QtyOrdered;    
        SET @QuantityOnHand = @QtyOrdered;    
    
        SET @IsParent_NonStock = 1;    
       END    
       ELSE IF (@IsSerialized = 1)    
       BEGIN    
        SET @Quantity = @QtyOrdered;    
        SET @QuantityAvailable = @QtyOrdered;    
        SET @QuantityOnHand = @QtyOrdered;    
    
        SET @IsParent_NonStock = 0;    
       END    
      END    
      ELSE    
      BEGIN    
       IF (@IsSerialized = 0)    
       BEGIN    
        SET @IsParent_NonStock = 0;    
       END    
       ELSE IF (@IsSerialized = 1)    
       BEGIN    
        SET @IsParent_NonStock = 1;    
       END    
      END    
    
	   INSERT INTO [dbo].[NonStockInventoryDraft]  
		([NonStockDraftNumber],[PurchaseOrderId],[PurchaseOrderPartRecordId],[PurchaseOrderNumber] ,[IsParent] ,[ParentId],[MasterPartId],[PartNumber],[PartDescription],[NonStockInventoryId],
		[NonStockInventoryNumber],[ControlNumber],[ControlID],[IdNumber],[ReceiverNumber],[ReceivedDate],[IsSerialized],[SerialNumber],[Quantity],[QuantityRejected],[QuantityOnHand],[CurrencyId],
		[Currency],[ConditionId],[Condition],[GLAccountId],[GLAccount],[UnitOfMeasureId],[UnitOfMeasure],[ManufacturerId],[Manufacturer],[MfgExpirationDate],[UnitCost],[ExtendedCost],[Acquired],
		[IsHazardousMaterial],[ItemNonStockClassificationId],[NonStockClassification],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[ShelfId],[Shelf],[BinId],[Bin],[ShippingViaId],
		[ShippingVia],[ShippingAccount],[ShippingReference],[IsSameDetailsForAllParts],[VendorId],[VendorName],[RequisitionerId],[Requisitioner],[OrderDate],[EntryDate],[ManagementStructureId],
		[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ShippingReferenceNumberNotProvided],
		[SerialNumberNotProvided],[TimeLifeDetailsNotProvided])
		SELECT NULL, @PurchaseOrderId, @PurchaseOrderPartRecordId, @PONumber,@IsParent_NonStock,0,IMN.MasterPartId,IMN.PartNumber,IMN.PartDescription,NULL,NULL,NULL,NULL,@IdNumber,NULL,GETUTCDATE(),
		ISNULL(IMN.IsSerialized,0),'',@Quantity,0,@QuantityOnHand,IMN.CurrencyId,IMN.Currency,@ConditionId,@ConditionName, @POPartGLAccountId, @POPartGLAccountName,IMN.PurchaseUnitOfMeasureId,
		'',IMN.ManufacturerId,IMN.Manufacturer,IMN.MfgExpirationDate,CASE WHEN @POPartUnitCost = 0 THEN @POUnitCost ELSE @POPartUnitCost END,((CASE WHEN @POPartUnitCost = 0 THEN @POUnitCost ELSE @POPartUnitCost END) * 1),
		NULL,IMN.IsHazardousMaterial,IMN.ItemNonStockClassificationId,IMN.ItemNonStockClassification,IMN.SiteId,IMN.Site,IMN.WarehouseId,IMN.Warehouse,IMN.LocationId,IMN.Location,IMN.ShelfId,IMN.Shelf,IMN.BinId,IMN.Bin,
		CASE WHEN @ShipViaId = 0 THEN NULL ELSE @ShipViaId END, @ShipViaName,@ShippingAccountNo,NULL,1,NULL,NULL,NULL,NULL,NULL,NUll,@ManagementStructureId,NULL,NUll,NULL,NULL,NULL,@MasterCompanyId,
		@UserName, @UserName, GETUTCDATE(), GETUTCDATE(),1,0,0,0,0
		FROM DBO.ItemMasterNonStock IMN WITH (NOLOCK) WHERE IMN.MasterPartId = @ItemMasterId;  
      
	  SELECT @NewNonStocklineDraftId = SCOPE_IDENTITY();    
    
      EXEC dbo.[PROCAddStockLineDraftMSData] @NewNonStocklineDraftId, @ManagementStructureId, @MasterCompanyId, @UserName, @UserName, 55, 1;    
    
      SET @LoopID_Qty = @LoopID_Qty - 1;    
      SET @CurrentIndex = @CurrentIndex + 1;      
     END    
    
     SET @LoopID_Nonstock = @LoopID_Nonstock - 1;    
    END    
    
   EXEC UpdateStocklineDraftDetail @PurchaseOrderId;    
   EXEC UpdateAssetInventoryDraftPoDetails @PurchaseOrderId;    
   EXEC UpdateNonStockDraftDetail @PurchaseOrderId;  
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
                , @ProcedureParameters    =  @ProcedureParameters    
                , @ApplicationName        =  @ApplicationName    
                , @ErrorLogID             =  @ErrorLogID OUTPUT ;    
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
        RETURN(1);    
  END CATCH    
END