/*************************************************************               
 ** File:   [USP_UpdateStocklineForReceivingPO]              
 ** Author:   Vishal Suthar    
 ** Description: This stored procedure is used to Update stocklines for receiving PO  
 ** Purpose:             
 ** Date:   09/22/2023            
              
 ** PARAMETERS:    
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author   Change Description                
 ** --   --------     -------   --------------------------------              
    1    09/22/2023   Vishal Suthar  Created  
    2    10/05/2023   Vishal Suthar  Modified to get parent stockline draft details to bind as parent record  
    
declare @p2 dbo.POPartsToReceive  
insert into @p2 values(1821,3412,5)  
  
exec dbo.USP_UpdateStocklineForReceivingPO @PurchaseOrderId=1821,@tbl_POPartsToReceive=@p2,@UpdatedBy=N'ADMIN User',@MasterCompanyId=1  
**************************************************************/    
CREATE    PROCEDURE [dbo].[USP_UpdateNonStockForReceivingPO]  
(    
 @PurchaseOrderId BIGINT = NULL,  
 @UpdatedBy VARCHAR(100) = NULL,  
 @MasterCompanyId BIGINT = NULL,  
 @tbl_UpdateNonStocklineReceivingPOType UpdateNonStocklineReceivingPOType READONLY,
 @tbl_UpdateTimeLifeReceivingPOType UpdateTimeLifeReceivingPOType READONLY   
)    
AS    
BEGIN    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  SET NOCOUNT ON  
 BEGIN TRY    
    BEGIN TRANSACTION    
    BEGIN  
  DECLARE @LoopID AS INT = 0;  
  
  IF OBJECT_ID(N'tempdb..#UpdateNonStocklineReceivingPOType') IS NOT NULL  
  BEGIN  
   DROP TABLE #UpdateNonStocklineReceivingPOType   
  END  
     
  CREATE TABLE #UpdateNonStocklineReceivingPOType   
  (  
   ID BIGINT NOT NULL IDENTITY,  
   [NonStockInventoryDraftId] [bigint] NOT NULL,  
   [NonStockDraftNumber] [varchar](50) NULL,
   [PurchaseOrderId] [bigint] NOT NULL,  
   [PurchaseOrderPartRecordId] [bigint] NOT NULL,  
   [PurchaseOrderNumber] [varchar](50)  NULL, 
   [IsParent] [bit] NULL,  
   [ParentId] [bigint] NULL,  
   [MasterPartId] [bigint] NOT NULL,  
   [PartNumber] [varchar](50) NULL,
   [PartDescription] [nvarchar](50) NULL,
   [NonStockInventoryId] [bigint] NULL,  
   [NonStockInventoryNumber] [varchar](50) NULL,
   [ControlNumber] [varchar](50) NULL,  
   [ControlID] [varchar](50) NULL,  
   [IdNumber] [varchar](100) NULL,  
   [ReceiverNumber] [varchar](50) NULL,  
   [ReceivedDate] [datetime2](7) NULL,  
   [isSerialized] [bit] NOT NULL,  
   [SerialNumber] [varchar](50) NULL,  
   [Quantity] [int] NOT NULL,  
   [QuantityRejected] [int] NULL,  
   [QuantityOnHand] [int] NULL,  
   [CurrencyId] [bigint] NULL,  
   [Currency] [varchar](50) NULL,
   [ConditionId] [bigint] NULL,  
   [Condition] [varchar](250) NULL,  
   [GLAccountId] [bigint] NULL,  
   [GLAccount] [varchar](250) NULL,  
   [UnitOfMeasureId] [bigint] NULL,  
   [UnitOfMeasure] [varchar](250) NULL,  
   [ManufacturerId] [bigint] NULL,  
   [Manufacturer] [varchar](50) NULL, 
   [MfgExpirationDate] [datetime2](7) NULL,  
   [UnitCost] [decimal](18, 2) NULL,  
   [ExtendedCost] [decimal](18, 2) NULL,  
   [Acquired] [int] NULL,  
   [IsHazardousMaterial] [bit] NULL,  
   [ItemNonStockClassificationId] [bigint] NULL,  
   [NonStockClassification] [varchar](50) NULL, 
   [SiteId] [bigint] NOT NULL,  
   [Site] [varchar](250) NULL,  
   [WarehouseId] [bigint] NULL,  
   [Warehouse] [varchar](250) NULL,  
   [LocationId] [bigint] NULL,  
   [Location] [varchar](250) NULL,  
   [ShelfId] [bigint] NULL,  
   [Shelf] [varchar](250) NULL,  
   [BinId] [bigint] NULL,  
   [Bin] [varchar](250) NULL,  
   [ShippingViaId] [bigint] NULL,  
   [ShippingVia] [varchar](250) NULL,  
   [ShippingAccount] [nvarchar](400) NULL,  
   [ShippingReference] [nvarchar](400) NULL,  
   [IsSameDetailsForAllParts] [bit] NULL,  
   [VendorId] [bigint] NULL,  
   [VendorName] [varchar](100) NULL,  
   [RequisitionerId] [bigint] NULL,  
   [Requisitioner] [varchar](100) NULL,  
   [OrderDate] [datetime2](7) NULL,  
   [EntryDate] [datetime2](7) NULL,  
   [ManagementStructureEntityId] [bigint] NOT NULL,  
   [Level1] [varchar](200) NULL,  
   [Level2] [varchar](200) NULL,  
   [Level3] [varchar](200) NULL,  
   [Level4] [varchar](200) NULL,
   [Memo] [nvarchar](max) NULL,  
   [MasterCompanyId] [int] NOT NULL,  
   [CreatedBy] [varchar](256) NULL,  
   [UpdatedBy] [varchar](256) NULL,  
   [CreatedDate] [datetime2](7) NULL,  
   [UpdatedDate] [datetime2](7) NULL,
   [isActive] [bit] NULL,  
   [isDeleted] [bit] NULL  
  )  
  
  INSERT INTO #UpdateNonStocklineReceivingPOType ([NonStockInventoryDraftId],[NonStockDraftNumber],[PurchaseOrderId],[PurchaseOrderPartRecordId],[PurchaseOrderNumber],[IsParent],[ParentId],[MasterPartId],
  [PartNumber],[PartDescription],[NonStockInventoryId],[NonStockInventoryNumber],[ControlNumber],[ControlID],[IdNumber],[ReceiverNumber],[ReceivedDate],[isSerialized],[SerialNumber],[Quantity],
  [QuantityRejected],[QuantityOnHand],[CurrencyId],[Currency],[ConditionId],[Condition],[GLAccountId],[GLAccount],[UnitOfMeasureId],[UnitOfMeasure],[ManufacturerId],[Manufacturer],[MfgExpirationDate],
  [UnitCost],[ExtendedCost],[Acquired],[IsHazardousMaterial],[ItemNonStockClassificationId],[NonStockClassification],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[ShelfId],[Shelf],
  [BinId],[Bin],[ShippingViaId],[ShippingVia],[ShippingAccount],[ShippingReference],[IsSameDetailsForAllParts],[VendorId],[VendorName],[RequisitionerId],[Requisitioner],[OrderDate],[EntryDate],
  [ManagementStructureEntityId],[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isActive],[isDeleted])  
  SELECT [NonStockInventoryDraftId],[NonStockDraftNumber],[PurchaseOrderId],[PurchaseOrderPartRecordId],[PurchaseOrderNumber],[IsParent],[ParentId],[MasterPartId],
  [PartNumber],[PartDescription],[NonStockInventoryId],[NonStockInventoryNumber],[ControlNumber],[ControlID],[IdNumber],[ReceiverNumber],[ReceivedDate],[isSerialized],[SerialNumber],[Quantity],
  [QuantityRejected],[QuantityOnHand],[CurrencyId],[Currency],[ConditionId],[Condition],[GLAccountId],[GLAccount],[UnitOfMeasureId],[UnitOfMeasure],[ManufacturerId],[Manufacturer],[MfgExpirationDate],
  [UnitCost],[ExtendedCost],[Acquired],[IsHazardousMaterial],[ItemNonStockClassificationId],[NonStockClassification],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[ShelfId],[Shelf],
  [BinId],[Bin],[ShippingViaId],[ShippingVia],[ShippingAccount],[ShippingReference],[IsSameDetailsForAllParts],[VendorId],[VendorName],[RequisitionerId],[Requisitioner],[OrderDate],[EntryDate],
  [ManagementStructureEntityId],[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isActive],[isDeleted] FROM @tbl_UpdateNonStocklineReceivingPOType;  
  
  DECLARE @QuantityBackOrdered INT = 0;  
  
  SELECT @LoopID = MAX(ID) FROM #UpdateNonStocklineReceivingPOType;  
  
  WHILE (@LoopID > 0)  
  BEGIN  
   DECLARE @SelectedNonStockInventoryDraftId BIGINT = 0;  
   DECLARE @SelectedPurchaseOrderPartRecordId BIGINT = 0;  
   DECLARE @ManagementStructureId BIGINT = 0;  
   DECLARE @Quantity INT = 0;  
   DECLARE @CreatedBy VARCHAR(100) = '';  
   DECLARE @ManagementStructureModuleReceivingPODraft INT = 31;  
   DECLARE @StockLineDraftMSDetailsOpr INT = 0;  
   DECLARE @PrevIsSameDetailsForAllParts BIT = 0;  
   DECLARE @PrevIsSerialized BIT = 0;  
   DECLARE @PrevIsParent BIT = 0;  
   DECLARE @IsSameDetailsForAllParts BIT = 0;  
   DECLARE @IsSerialized BIT = 0;  
  
   SELECT @SelectedNonStockInventoryDraftId = NonStockInventoryDraftId, @SelectedPurchaseOrderPartRecordId = PurchaseOrderPartRecordId, @Quantity = Quantity, @IsSameDetailsForAllParts = IsSameDetailsForAllParts, @IsSerialized = IsSerialized  
   FROM #UpdateNonStocklineReceivingPOType WHERE ID = @LoopID;  
  
   SELECT @PrevIsSameDetailsForAllParts = IsSameDetailsForAllParts, @PrevIsSerialized = IsSerialized, @PrevIsParent = IsParent FROM DBO.NonStockInventoryDraft StkDraft WHERE StkDraft.NonStockInventoryDraftId = @SelectedNonStockInventoryDraftId;  
  
  
   UPDATE StkDraft  
   SET StkDraft.ManagementStructureId = TmpStkDraft.ManagementStructureEntityId,  
   StkDraft.SiteId = CASE WHEN TmpStkDraft.SiteId > 0 THEN TmpStkDraft.SiteId ELSE NULL END,  
   StkDraft.WarehouseId = CASE WHEN TmpStkDraft.WarehouseId > 0 THEN TmpStkDraft.WarehouseId ELSE NULL END,  
   StkDraft.LocationId = CASE WHEN TmpStkDraft.LocationId > 0 THEN TmpStkDraft.LocationId ELSE NULL END,  
   StkDraft.ShelfId = CASE WHEN TmpStkDraft.ShelfId > 0 THEN TmpStkDraft.ShelfId ELSE NULL END,  
   StkDraft.BinId = CASE WHEN TmpStkDraft.BinId > 0 THEN TmpStkDraft.BinId ELSE NULL END,  
   StkDraft.UnitCost = TmpStkDraft.UnitCost,  
   StkDraft.ExtendedCost = TmpStkDraft.ExtendedCost,  
   StkDraft.ConditionId = TmpStkDraft.ConditionId,  
   StkDraft.ShippingViaId = CASE WHEN TmpStkDraft.ShippingViaId > 0 THEN TmpStkDraft.ShippingViaId ELSE NULL END,  
   StkDraft.ShippingReference = TmpStkDraft.ShippingReference,  
   StkDraft.ShippingAccount = TmpStkDraft.ShippingAccount,  
   StkDraft.MfgExpirationDate = TmpStkDraft.MfgExpirationDate, 
   StkDraft.UpdatedBy = TmpStkDraft.UpdatedBy,  
   StkDraft.UnitOfMeasureId = TmpStkDraft.UnitOfMeasureId,  
   StkDraft.UpdatedDate = GETUTCDATE()  
   FROM DBO.NonStockInventoryDraft StkDraft  
   INNER JOIN #UpdateNonStocklineReceivingPOType TmpStkDraft ON TmpStkDraft.NonStockInventoryDraftId = StkDraft.NonStockInventoryDraftId  
   WHERE StkDraft.NonStockInventoryDraftId = @SelectedNonStockInventoryDraftId;  
  
   SELECT @ManagementStructureId = ManagementStructureId, @CreatedBy = CreatedBy FROM DBO.NonStockInventoryDraft StkDraft WHERE StkDraft.NonStockInventoryDraftId = @SelectedNonStockInventoryDraftId;  
  
   SET @StockLineDraftMSDetailsOpr = 2;  
  
   EXEC dbo.[PROCAddStockLineDraftMSData] @SelectedNonStockInventoryDraftId, @ManagementStructureId, @MasterCompanyId, @CreatedBy, @UpdatedBy, @ManagementStructureModuleReceivingPODraft, @StockLineDraftMSDetailsOpr; -- @MSDetailsId OUTPUT  
  
   SET @QuantityBackOrdered = @QuantityBackOrdered + @Quantity;  
  
   SET @LoopID = @LoopID - 1;  
  END  
  
  /* Insert/Update Stockline Timelife Info */  
     DECLARE @LoopIDTimelife INT = 0;    
    
   IF OBJECT_ID(N'tempdb..#UpdateTimeLifeReceivingPOType') IS NOT NULL    
   BEGIN    
    DROP TABLE #UpdateTimeLifeReceivingPOType     
   END    
       
   CREATE TABLE #UpdateTimeLifeReceivingPOType    
   (    
    ID BIGINT NOT NULL IDENTITY,    
    [TimeLifeDraftCyclesId] [bigint] NULL,    
    [StockLineDraftId] [bigint] NULL,    
    [CyclesRemaining] [varchar](20) NULL,    
    [CyclesSinceNew] [varchar](20) NULL,    
    [CyclesSinceOVH] [varchar](20) NULL,    
    [CyclesSinceInspection] [varchar](20) NULL,    
    [CyclesSinceRepair] [varchar](20) NULL,    
    [TimeRemaining] [varchar](20) NULL,    
    [TimeSinceNew] [varchar](20) NULL,    
    [TimeSinceOVH] [varchar](20) NULL,    
    [TimeSinceInspection] [varchar](20) NULL,    
    [TimeSinceRepair] [varchar](20) NULL,    
    [LastSinceNew] [varchar](20) NULL,    
    [LastSinceOVH] [varchar](20) NULL,    
    [LastSinceInspection] [varchar](20) NULL,    
    [DetailsNotProvided] [bit] NULL    
   )    
    
   INSERT INTO #UpdateTimeLifeReceivingPOType ([TimeLifeDraftCyclesId],[StockLineDraftId],[CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],    
   [CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[DetailsNotProvided])    
   SELECT [TimeLifeDraftCyclesId],[StockLineDraftId],[CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],    
   [CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[DetailsNotProvided]    
   FROM @tbl_UpdateTimeLifeReceivingPOType WHERE [StockLineDraftId] = @SelectedNonStockInventoryDraftId;    
    
   SELECT @LoopIDTimelife = MAX(ID) FROM #UpdateTimeLifeReceivingPOType;    
      
   WHILE (@LoopIDTimelife > 0)    
   BEGIN    
    DECLARE @SelectedTimeLifeDraftCyclesId BIGINT = 0;    
    
    SELECT @SelectedTimeLifeDraftCyclesId = TimeLifeDraftCyclesId FROM #UpdateTimeLifeReceivingPOType WHERE ID = @LoopIDTimelife;    
    
    IF (@SelectedTimeLifeDraftCyclesId = 0)    
    BEGIN    
     INSERT INTO DBO.TimeLifeDraft ([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],    
     [TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],    
     [UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineDraftId],[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId],    
     [VendorRMAId],[VendorRMADetailId])    
     SELECT [CyclesRemaining], [CyclesSinceNew], [CyclesSinceOVH], [CyclesSinceInspection], [CyclesSinceRepair], [TimeRemaining], [TimeSinceNew],    
     [TimeSinceOVH], [TimeSinceInspection], [TimeSinceRepair], [LastSinceNew], [LastSinceOVH], [LastSinceInspection], @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(),    
     GETUTCDATE(), 1, @PurchaseOrderId, @SelectedPurchaseOrderPartRecordId, [StockLineDraftId], [DetailsNotProvided], NULL, NULL,    
     NULL, NULL    
     FROM #UpdateTimeLifeReceivingPOType WHERE ID = @LoopIDTimelife;    
    END    
    ELSE    
    BEGIN    
     UPDATE TLDraft    
     SET TLDraft.CyclesRemaining = UTLDraft.CyclesRemaining,    
     TLDraft.[CyclesSinceNew] = UTLDraft.[CyclesSinceNew],    
     TLDraft.[CyclesSinceOVH] = UTLDraft.[CyclesSinceOVH],    
     TLDraft.[CyclesSinceInspection] = UTLDraft.[CyclesSinceInspection],    
     TLDraft.[CyclesSinceRepair] = UTLDraft.[CyclesSinceRepair],    
     TLDraft.[TimeRemaining] = UTLDraft.[TimeRemaining],    
     TLDraft.[TimeSinceNew] = UTLDraft.[TimeSinceNew],    
     TLDraft.[TimeSinceOVH] = UTLDraft.[TimeSinceOVH],    
     TLDraft.[TimeSinceInspection] = UTLDraft.[TimeSinceInspection],    
     TLDraft.[TimeSinceRepair] = UTLDraft.[TimeSinceRepair],    
     TLDraft.[LastSinceNew] = UTLDraft.[LastSinceNew],    
     TLDraft.[LastSinceOVH] = UTLDraft.[LastSinceOVH],    
     TLDraft.[LastSinceInspection] = UTLDraft.[LastSinceInspection],    
     TLDraft.[UpdatedBy] = @UpdatedBy,    
     TLDraft.UpdatedDate = GETUTCDATE()    
     FROM DBO.TimeLifeDraft TLDraft    
     INNER JOIN #UpdateTimeLifeReceivingPOType UTLDraft ON TLDraft.StockLineDraftId = UTLDraft.StockLineDraftId    
     WHERE TLDraft.TimeLifeDraftCyclesId = @SelectedTimeLifeDraftCyclesId    
    END    
    
    SET @LoopIDTimelife = @LoopIDTimelife - 1;    
   END    
    
   SET @LoopID = @LoopID - 1;    
  

  
  EXEC DBO.UpdateNonStockDraftDetail @PurchaseOrderId;  
 END    
    COMMIT TRANSACTION    
    
  END TRY    
  BEGIN CATCH    
    IF @@trancount > 0    
   ROLLBACK TRAN;    
   DECLARE @ErrorLogID int    
   ,@DatabaseName varchar(100) = DB_NAME()    
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------    
   ,@AdhocComments varchar(150) = 'USP_UpdateNonStockForReceivingPO'    
   ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@PurchaseOrderId, '') + ''    
   ,@ApplicationName varchar(100) = 'PAS'    
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