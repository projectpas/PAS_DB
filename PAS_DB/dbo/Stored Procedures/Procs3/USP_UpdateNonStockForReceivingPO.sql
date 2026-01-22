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
      
declare @p4 dbo.UpdateNonStocklineReceivingPOType
insert into @p4 values(307,NULL,2319,3968,NULL,1,NULL,0,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,0,N'',0,0,NULL,0,NULL,7,NULL,2,NULL,3,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,2,NULL,0,NULL,0,NULL,0,NULL,0,NULL,5,NULL,N'DHFL-78978',N'sadad',1,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,1,N'ADMIN User',N'ADMIN User','2023-12-18 18:35:38.5446619','2023-12-18 13:05:38.1860000',1,0,0,0,0)
insert into @p4 values(308,NULL,2319,3968,NULL,0,NULL,0,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,0,N'',0,0,NULL,0,NULL,7,NULL,2,NULL,3,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,2,NULL,0,NULL,0,NULL,0,NULL,0,NULL,5,NULL,N'DHFL-78978',N'sadad',1,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,1,N'ADMIN User',N'ADMIN User','2023-12-18 18:35:38.5451734','2023-12-18 13:05:38.1860000',1,0,0,0,0)
insert into @p4 values(309,NULL,2319,3968,NULL,0,NULL,0,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,0,N'',0,0,NULL,0,NULL,7,NULL,2,NULL,3,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,2,NULL,0,NULL,0,NULL,0,NULL,0,NULL,5,NULL,N'DHFL-78978',N'sadad',1,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,1,N'ADMIN User',N'ADMIN User','2023-12-18 18:35:38.5456305','2023-12-18 13:05:38.1860000',1,0,0,0,0)

declare @p5 dbo.UpdateTimeLifeReceivingPOType

exec dbo.USP_UpdateNonStockForReceivingPO @PurchaseOrderId=2319,@UpdatedBy=N'ADMIN User',@MasterCompanyId=1,@tbl_UpdateNonStocklineReceivingPOType=@p4,@tbl_UpdateTimeLifeReceivingPOType=@p5  

**************************************************************/      
CREATE     PROCEDURE [dbo].[USP_UpdateNonStockForReceivingPO]    
(      
	@PurchaseOrderId BIGINT = NULL,    
	@UpdatedBy VARCHAR(100) = NULL,    
	@MasterCompanyId BIGINT = NULL,    
	@tbl_UpdateNonStocklineReceivingPOType UpdateNonStocklineReceivingPOType READONLY,  
	@tbl_UpdateTimeLifeReceivingPOType UpdateTimeLifeReceivingPOType READONLY,
	@IsCreate BIT
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
   [isDeleted] [bit] NULL,
   [ShippingReferenceNumberNotProvided] [bit] NULL,
   [SerialNumberNotProvided] [bit] NULL,
   [TimeLifeDetailsNotProvided] [bit] NULL
  )    
    
  INSERT INTO #UpdateNonStocklineReceivingPOType ([NonStockInventoryDraftId],[NonStockDraftNumber],[PurchaseOrderId],[PurchaseOrderPartRecordId],[PurchaseOrderNumber],[IsParent],[ParentId],[MasterPartId],  
  [PartNumber],[PartDescription],[NonStockInventoryId],[NonStockInventoryNumber],[ControlNumber],[ControlID],[IdNumber],[ReceiverNumber],[ReceivedDate],[isSerialized],[SerialNumber],[Quantity],  
  [QuantityRejected],[QuantityOnHand],[CurrencyId],[Currency],[ConditionId],[Condition],[GLAccountId],[GLAccount],[UnitOfMeasureId],[UnitOfMeasure],[ManufacturerId],[Manufacturer],[MfgExpirationDate],  
  [UnitCost],[ExtendedCost],[Acquired],[IsHazardousMaterial],[ItemNonStockClassificationId],[NonStockClassification],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[ShelfId],[Shelf],  
  [BinId],[Bin],[ShippingViaId],[ShippingVia],[ShippingAccount],[ShippingReference],[IsSameDetailsForAllParts],[VendorId],[VendorName],[RequisitionerId],[Requisitioner],[OrderDate],[EntryDate],  
  [ManagementStructureEntityId],[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isActive],[isDeleted],[ShippingReferenceNumberNotProvided],
  [SerialNumberNotProvided],[TimeLifeDetailsNotProvided])    
  SELECT [NonStockInventoryDraftId],[NonStockDraftNumber],[PurchaseOrderId],[PurchaseOrderPartRecordId],[PurchaseOrderNumber],[IsParent],[ParentId],[MasterPartId],  
  [PartNumber],[PartDescription],[NonStockInventoryId],[NonStockInventoryNumber],[ControlNumber],[ControlID],[IdNumber],[ReceiverNumber],[ReceivedDate],[isSerialized],[SerialNumber],[Quantity],  
  [QuantityRejected],[QuantityOnHand],[CurrencyId],[Currency],[ConditionId],[Condition],[GLAccountId],[GLAccount],[UnitOfMeasureId],[UnitOfMeasure],[ManufacturerId],[Manufacturer],[MfgExpirationDate],  
  [UnitCost],[ExtendedCost],[Acquired],[IsHazardousMaterial],[ItemNonStockClassificationId],[NonStockClassification],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[ShelfId],[Shelf],  
  [BinId],[Bin],[ShippingViaId],[ShippingVia],[ShippingAccount],[ShippingReference],[IsSameDetailsForAllParts],[VendorId],[VendorName],[RequisitionerId],[Requisitioner],[OrderDate],[EntryDate],  
  [ManagementStructureEntityId],[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isActive],[isDeleted],[ShippingReferenceNumberNotProvided],
  [SerialNumberNotProvided],[TimeLifeDetailsNotProvided] FROM @tbl_UpdateNonStocklineReceivingPOType;    
    

	--SELECT * FROM #UpdateNonStocklineReceivingPOType;

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
    SELECT * FROM #UpdateNonStocklineReceivingPOType WHERE NonStockInventoryDraftId = @SelectedNonStockInventoryDraftId; 
    
   IF (@PrevIsSerialized = 1 AND @IsSerialized = 0)
	BEGIN
		IF (@PrevIsParent = 1 AND @IsSameDetailsForAllParts = 0)
			SET @PrevIsParent = 0;
		ELSE IF (@PrevIsParent = 0 AND @IsSameDetailsForAllParts = 0)
			SET @PrevIsParent = 1;
	END

	IF (@IsCreate = 1)
	BEGIN
		IF (@IsSerialized = 0)
		BEGIN
			IF (@PrevIsSameDetailsForAllParts <> @IsSameDetailsForAllParts)
			BEGIN
				IF (@PrevIsParent = 1 AND (@PrevIsSameDetailsForAllParts = 1 AND @IsSameDetailsForAllParts = 0))
					SET @PrevIsParent = 0;
				ELSE IF (@PrevIsParent = 0 AND (@PrevIsSameDetailsForAllParts = 1 AND @IsSameDetailsForAllParts = 0))
					SET @PrevIsParent = 1;
				ELSE IF (@PrevIsParent = 0 AND (@PrevIsSameDetailsForAllParts = 0 AND @IsSameDetailsForAllParts = 1))
					SET @PrevIsParent = 1;
				ELSE IF (@PrevIsParent = 1 AND (@PrevIsSameDetailsForAllParts = 0 AND @IsSameDetailsForAllParts = 1))
					SET @PrevIsParent = 0;
			END
		END
	END

   UPDATE StkDraft    
   SET StkDraft.ManagementStructureId = TmpStkDraft.ManagementStructureEntityId,
   StkDraft.SiteId = CASE WHEN TmpStkDraft.SiteId > 0 THEN TmpStkDraft.SiteId ELSE NULL END,    
   StkDraft.WarehouseId = CASE WHEN TmpStkDraft.WarehouseId > 0 THEN TmpStkDraft.WarehouseId ELSE NULL END,    
   StkDraft.LocationId = CASE WHEN TmpStkDraft.LocationId > 0 THEN TmpStkDraft.LocationId ELSE NULL END,    
   StkDraft.ShelfId = CASE WHEN TmpStkDraft.ShelfId > 0 THEN TmpStkDraft.ShelfId ELSE NULL END,    
   StkDraft.BinId = CASE WHEN TmpStkDraft.BinId > 0 THEN TmpStkDraft.BinId ELSE NULL END,    
   StkDraft.UnitCost = ISNULL(TmpStkDraft.UnitCost, 0),    
   StkDraft.ExtendedCost = ISNULL(TmpStkDraft.ExtendedCost, 0),    
   StkDraft.ConditionId = TmpStkDraft.ConditionId,    
   StkDraft.ShippingViaId = CASE WHEN TmpStkDraft.ShippingViaId > 0 THEN TmpStkDraft.ShippingViaId ELSE NULL END,    
   StkDraft.ShippingReference = TmpStkDraft.ShippingReference,    
   StkDraft.ShippingAccount = TmpStkDraft.ShippingAccount,    
   StkDraft.MfgExpirationDate = TmpStkDraft.MfgExpirationDate,   
   StkDraft.IsSameDetailsForAllParts = TmpStkDraft.IsSameDetailsForAllParts, 
   StkDraft.TimeLifeDetailsNotProvided = TmpStkDraft.TimeLifeDetailsNotProvided,  
   StkDraft.SerialNumberNotProvided = TmpStkDraft.SerialNumberNotProvided,  
   StkDraft.ShippingReferenceNumberNotProvided = TmpStkDraft.ShippingReferenceNumberNotProvided,  
   StkDraft.UpdatedBy = TmpStkDraft.UpdatedBy,    
   StkDraft.UnitOfMeasureId = TmpStkDraft.UnitOfMeasureId,    
   StkDraft.UpdatedDate = GETUTCDATE(),  
   StkDraft.Acquired = TmpStkDraft.Acquired,
   StkDraft.IsParent = @PrevIsParent
   FROM DBO.NonStockInventoryDraft StkDraft    
   INNER JOIN #UpdateNonStocklineReceivingPOType TmpStkDraft ON TmpStkDraft.NonStockInventoryDraftId = StkDraft.NonStockInventoryDraftId    
   WHERE StkDraft.NonStockInventoryDraftId = @SelectedNonStockInventoryDraftId;    
    
   IF(@IsCreate = 0)
   	BEGIN
		IF (@PrevIsSameDetailsForAllParts <> @IsSameDetailsForAllParts)
		BEGIN
			UPDATE StkDraft
			SET StkDraft.IsSameDetailsForAllParts = CASE WHEN TmpStkDraft.IsSameDetailsForAllParts = 1 THEN 0 ELSE 1 END
			FROM DBO.NonStockInventoryDraft StkDraft
			INNER JOIN #UpdateNonStocklineReceivingPOType TmpStkDraft ON TmpStkDraft.NonStockInventoryDraftId = StkDraft.NonStockInventoryDraftId
			WHERE StkDraft.NonStockInventoryDraftId = @SelectedNonStockInventoryDraftId;
		END
	END

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