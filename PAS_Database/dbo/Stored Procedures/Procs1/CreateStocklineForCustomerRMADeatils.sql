  
/*************************************************************             
 ** File:   [CreateStocklineForCustomerRMADeatils]             
 ** Author:   Subhash Saliya  
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA     
 ** Purpose:           
 ** Date:   02/05/2022          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    02/05/20221   Subhash Saliya  Created  
    2    06/14/2023   Devendra Shekh   changed function udfGenerateCodeNumber to [udfGenerateCodeNumberWithOutDash]  
	3    01/July/2026  RAJESH GAMI	   [PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
    4    11/Sep/2026   Sahdev Saliya   Customer RMA: preserve history, notes, documents and LOT linkage - [PN-17875]
-- EXEC [CreateStocklineForCustomerRMADeatils] 44  
**************************************************************/  
  
CREATE     PROCEDURE [dbo].[CreateStocklineForCustomerRMADeatils]  
@RMADeatilsId BIGINT,  
@ModuleId INT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
    DECLARE @RMAHeaderId BIGINT, @RMANumber VARCHAR(100), @RMAUpdatedBy VARCHAR(256);
    DECLARE @RMAHistoryModuleId BIGINT, @RMAAttachmentModuleId INT, @StocklineAttachmentModuleId INT;
    DECLARE @AddFromModuleActionId INT;
    DECLARE @SourceAttachmentId BIGINT, @NewAttachmentId BIGINT;
    DECLARE @RMADocuments TABLE (AttachmentId BIGINT PRIMARY KEY);
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
    DECLARE @EntityMSID BIGINT;  
    DECLARE @Qty int;  
    DECLARE @IsCustomerStock bit =1;  
  
  
    SELECT TOP 1 @StocklineId = StockLineId,@Qty=Qty,  
      @MasterCompanyId  = CRMH.MasterCompanyId,  
      @EntityMSID = ManagementStructureId,
      @RMAHeaderId = CRMH.RMAHeaderId, @RMANumber = CRMH.RMANumber,
      @RMAUpdatedBy = CRMH.UpdatedBy
    FROM dbo.CustomerRMADeatils CRM WITH(NOLOCK)  
    INNER JOIN dbo.CustomerRMAHeader CRMH WITH(NOLOCK) ON CRMH.RMAHeaderId=CRM.RMAHeaderId  
    WHERE RMADeatilsId = @RMADeatilsId  
  
  
    SELECT @RMAHistoryModuleId = ModuleId FROM dbo.Module WHERE ModuleName = 'CustomerRMA';
    SELECT @RMAAttachmentModuleId = AttachmentModuleId FROM dbo.AttachmentModule WHERE Name = 'CustomerRMA';
    SELECT @StocklineAttachmentModuleId = AttachmentModuleId FROM dbo.AttachmentModule WHERE Name = 'StockLine';
    SELECT @AddFromModuleActionId = ActionId FROM dbo.StklineHistory_Action WHERE Type = 'Add-From-Module';

    IF @RMAHistoryModuleId IS NULL OR @RMAAttachmentModuleId IS NULL
       OR @StocklineAttachmentModuleId IS NULL OR @AddFromModuleActionId IS NULL
        THROW 50001, 'Customer RMA stockline module or history action configuration is missing.', 1;

    INSERT INTO @RMADocuments (AttachmentId)
    SELECT DISTINCT CDD.AttachmentId
    FROM dbo.CommonDocumentDetails CDD
    INNER JOIN dbo.Attachment A ON A.AttachmentId = CDD.AttachmentId
    WHERE CDD.ModuleId = @RMAAttachmentModuleId AND CDD.ReferenceId = @RMAHeaderId
      AND CDD.MasterCompanyId = @MasterCompanyId AND A.MasterCompanyId = @MasterCompanyId
      AND CDD.IsActive = 1 AND CDD.IsDeleted = 0 AND A.IsActive = 1 AND A.IsDeleted = 0
      AND EXISTS (SELECT 1 FROM dbo.AttachmentDetails AD
                  WHERE AD.AttachmentId = A.AttachmentId AND AD.IsActive = 1 AND AD.IsDeleted = 0);

  DECLARE @LoopID as int  
  SELECT  @LoopID = MAX(@Qty)   
  
  WHILE(@LoopID > 0)  
  BEGIN  
  
  
    Declare @DefultQty int =1  
  
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
  
     WHERE ISNULL(IM.IsNonStock,0) = 0
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
     SELECT   
      @IDCurrentNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1   
       ELSE CAST(StartsFrom AS BIGINT) + 1 END   
     FROM #tmpCodePrefixes WHERE CodeTypeId = 17  
  
     SET @IDNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@IDCurrentNumber,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 17), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 17)))  
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
       ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],IsFinishGood,IsCustomerRMA,RMADeatilsId,[LotId],[IsLotAssigned])
    SELECT [PartNumber],@StockLineNumber,[StocklineMatchKey],[ControlNumber],[ItemMasterId],@DefultQty,[ConditionId]  
       ,[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo]  
       ,[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber]  
       ,[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId]  
       ,0,[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber]  
       ,[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER]  
       ,[OEM],CONCAT(N'Stockline Created from Customer RMA ', NCHAR(8211), N' ', @RMANumber)
       ,[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETDATE(),GETDATE()
       ,[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId]  
       ,[UnitSalePriceAdjustmentReasonTypeId],@IDNumber,[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace]  
       ,[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],0,[PurchaseOrderPartRecordId]  
       ,[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId]  
       ,0,0,0,@DefultQty,@DefultQty,0,[QtyReserved]  
       ,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId]  
       ,[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],@IsCustomerStock,[EntryDate],[LotCost],[NHAItemMasterId]  
       ,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate]  
       ,[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId]  
       ,[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition]  
       ,[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber]  
       ,[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],[CustomerId],[CustomerName],[isCustomerstockType]  
       ,[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],0,[TaggedByType]  
       ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],0,1,@RMADeatilsId,[LotId],[IsLotAssigned]
   FROM dbo.Stockline WITH(NOLOCK)  
   WHERE StockLineId = @StocklineId  
  
    IF @@ROWCOUNT <> 1
        THROW 50002, 'The original Customer RMA stockline was not found.', 1;
    SELECT @NewStocklineId = SCOPE_IDENTITY();

    -- Retain the original inventory events, including their notes and audit values.
    INSERT INTO dbo.Stkline_History
        (StocklineId, ModuleId, RefferenceId, RefferenceNumber, SubModuleId,
         SubRefferenceId, SubRefferenceNumber, ActionId, Type, QtyOH, QtyAvailable,
         QtyReserved, QtyIssued, QtyOnAction, Notes, UpdatedBy, UpdatedDate,
         UnitSalesPrice, SalesPriceExpiryDate, UOM)
    SELECT @NewStocklineId, ModuleId, RefferenceId, RefferenceNumber, SubModuleId,
           SubRefferenceId, SubRefferenceNumber, ActionId, Type, QtyOH, QtyAvailable,
           QtyReserved, QtyIssued, QtyOnAction, Notes, UpdatedBy, UpdatedDate,
           UnitSalesPrice, SalesPriceExpiryDate, UOM
    FROM dbo.Stkline_History WHERE StocklineId = @StocklineId;

    -- Each new stockline owns its document metadata; physical files retain their existing links.
    SELECT @SourceAttachmentId = MIN(AttachmentId) FROM @RMADocuments;
    WHILE @SourceAttachmentId IS NOT NULL
    BEGIN
        INSERT INTO dbo.Attachment
            (ModuleId, ReferenceId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
        VALUES (@StocklineAttachmentModuleId, @NewStocklineId, @MasterCompanyId,
                @RMAUpdatedBy, @RMAUpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);
        SET @NewAttachmentId = SCOPE_IDENTITY();

        INSERT INTO dbo.AttachmentDetails
            (AttachmentId, FileName, Description, Link, FileFormat, FileSize, FileType,
             CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsActive, IsDeleted, Name, Memo, TypeId)
        SELECT @NewAttachmentId, FileName, Description, Link, FileFormat, FileSize, FileType,
               GETUTCDATE(), GETUTCDATE(), @RMAUpdatedBy, @RMAUpdatedBy, 1, 0, Name, Memo, TypeId
        FROM dbo.AttachmentDetails
        WHERE AttachmentId = @SourceAttachmentId AND IsActive = 1 AND IsDeleted = 0;

        INSERT INTO dbo.CommonDocumentDetails
            (ModuleId, ReferenceId, AttachmentId, DocName, DocMemo, DocDescription,
             MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive,
             IsDeleted, DocumentTypeId, ExpirationDate, ReferenceIndex, ModuleType)
        SELECT @StocklineAttachmentModuleId, @NewStocklineId, @NewAttachmentId,
               DocName, DocMemo, DocDescription, @MasterCompanyId, @RMAUpdatedBy, @RMAUpdatedBy,
               GETUTCDATE(), GETUTCDATE(), 1, 0, DocumentTypeId, ExpirationDate, ReferenceIndex, ModuleType
        FROM dbo.CommonDocumentDetails
        WHERE AttachmentId = @SourceAttachmentId AND ModuleId = @RMAAttachmentModuleId
          AND ReferenceId = @RMAHeaderId AND MasterCompanyId = @MasterCompanyId
          AND IsActive = 1 AND IsDeleted = 0;

        SELECT @SourceAttachmentId = MIN(AttachmentId) FROM @RMADocuments
        WHERE AttachmentId > @SourceAttachmentId;
    END;
  
  
      INSERT INTO [dbo].[TimeLife]  
        ([CyclesRemaining]  
        ,[CyclesSinceNew]  
        ,[CyclesSinceOVH]  
        ,[CyclesSinceInspection]  
        ,[CyclesSinceRepair]  
        ,[TimeRemaining]  
        ,[TimeSinceNew]  
        ,[TimeSinceOVH]  
        ,[TimeSinceInspection]  
        ,[TimeSinceRepair]  
        ,[LastSinceNew]  
        ,[LastSinceOVH]  
        ,[LastSinceInspection]  
        ,[MasterCompanyId]  
        ,[CreatedBy]  
        ,[UpdatedBy]  
        ,[CreatedDate]  
        ,[UpdatedDate]  
        ,[IsActive]  
        ,[PurchaseOrderId]  
        ,[PurchaseOrderPartRecordId]  
        ,[StockLineId]  
        ,[DetailsNotProvided]  
        ,[RepairOrderId]  
        ,[RepairOrderPartRecordId])  
       SELECT [CyclesRemaining]  
        ,[CyclesSinceNew]  
        ,[CyclesSinceOVH]  
        ,[CyclesSinceInspection]  
        ,[CyclesSinceRepair]  
        ,[TimeRemaining]  
        ,[TimeSinceNew]  
        ,[TimeSinceOVH]  
        ,[TimeSinceInspection]  
        ,[TimeSinceRepair]  
        ,[LastSinceNew]  
        ,[LastSinceOVH]  
        ,[LastSinceInspection]  
        ,[MasterCompanyId]  
        ,[CreatedBy]  
        ,[UpdatedBy]  
        ,[CreatedDate]  
        ,[UpdatedDate]  
        ,[IsActive]  
        ,[PurchaseOrderId]  
        ,[PurchaseOrderPartRecordId]  
        ,@NewStocklineId  
        ,[DetailsNotProvided]  
        ,[RepairOrderId]  
        ,[RepairOrderPartRecordId] FROM TimeLife TL WITH (NOLOCK) WHERE TL.StockLineId = @StocklineId  
  
    UPDATE CodePrefixes SET CurrentNummber = @SLCurrentNumber WHERE CodeTypeId = 30 AND MasterCompanyId = @MasterCompanyId  
  
    EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId  
  
    -- The column refresh infers LOT membership from its display number. Restore the exact source link.
    UPDATE TargetStockline
    SET LotId = SourceStockline.LotId, IsLotAssigned = SourceStockline.IsLotAssigned
    FROM dbo.Stockline TargetStockline
    INNER JOIN dbo.Stockline SourceStockline ON SourceStockline.StockLineId = @StocklineId
    WHERE TargetStockline.StockLineId = @NewStocklineId;

    EXEC dbo.USP_AddUpdateStocklineHistory
        @StocklineId = @NewStocklineId, @ModuleId = @RMAHistoryModuleId,
        @ReferenceId = @RMAHeaderId, @ActionId = @AddFromModuleActionId,
        @Qty = @DefultQty, @UpdatedBy = @RMAUpdatedBy;

    EXEC USP_SaveSLMSDetails @ModuleID, @NewStocklineId, @EntityMSID, @MasterCompanyId, 'Create RMA Stockline'  
  
    IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL  
    BEGIN  
     DROP TABLE #tmpCodePrefixes   
    END  
  
    IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL  
    BEGIN  
     DROP TABLE #tmpPNManufacturer   
    END   
  
    SET @LoopID = @LoopID - 1;  
    END   
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'CreateStocklineForCustomerRMADeatils'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RMADeatilsId, '') + ''  
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