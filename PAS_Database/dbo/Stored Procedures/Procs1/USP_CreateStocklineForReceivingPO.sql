
/*************************************************************               
 ** File:   [USP_CreateStocklineForReceivingPO]              
 ** Author:   Vishal Suthar    
 ** Description: This stored procedure is used to Crate stocklines for receiving PO  
 ** Purpose:             
 ** Date:   08/21/2023            
              
 ** PARAMETERS:    
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author   Change Description                
 ** --   --------     -------   --------------------------------              
    1    08/21/2023   Vishal Suthar  Created  
    2    10/12/2023   Vishal Suthar  Fixed after shrey added 2 columns SerialNumberNotProvided, ShippingReferenceNumberNotProvided  
    3    10/13/2023   Devendra Shekh timelife issue resolved  
    4    11/09/2023   Vishal Suthar  auto reserve stockline based on PO settings  
	5    13-12-2023   Shrey Chandegara  update for stockline history  
	6    17-01-2024   Shrey Chandegara  Update for asset attributetype and glaccounts changes
    
declare @p2 dbo.POPartsToReceive  
insert into @p2 values(2371,4051,2)  
  
exec dbo.USP_CreateStocklineForReceivingPO @PurchaseOrderId=2371,@tbl_POPartsToReceive=@p2,@UpdatedBy=N'ADMIN User',@MasterCompanyId=1  
**************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateStocklineForReceivingPO]
(
    @PurchaseOrderId BIGINT = NULL,
    @UpdatedBy VARCHAR(100) = NULL,
    @MasterCompanyId BIGINT = NULL,
    @tbl_POPartsToReceive POPartsToReceive READONLY
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION
        BEGIN
            DECLARE @MainPartLoopID AS INT;
            DECLARE @LoopID AS INT;
            DECLARE @CurrentIndex BIGINT;

            IF OBJECT_ID(N'tempdb..#POPartsToReceive') IS NOT NULL
            BEGIN
                DROP TABLE #POPartsToReceive
            END

            CREATE TABLE #POPartsToReceive
            (
                ID BIGINT NOT NULL IDENTITY,
                [PurchaseOrderId] [bigint] NULL,
                [PurchaseOrderPartRecordId] [bigint] NULL,
                [QtyToReceive] [int] NULL
            )

            IF OBJECT_ID(N'tempdb..#InsertedStkForLot') IS NOT NULL
            BEGIN
                DROP TABLE #InsertedStkForLot
            END

            CREATE TABLE #InsertedStkForLot
            (
                ID BIGINT NOT NULL IDENTITY,
                [StockLineId] [bigint] NULL
            )
            INSERT INTO #POPartsToReceive
            (
                [PurchaseOrderId],
                [PurchaseOrderPartRecordId],
                [QtyToReceive]
            )
            SELECT [PurchaseOrderId], [PurchaseOrderPartRecordId], [QtyToReceive] FROM @tbl_POPartsToReceive;

            SELECT @MainPartLoopID = MAX(ID) FROM #POPartsToReceive;

            WHILE (@MainPartLoopID > 0)
            BEGIN
                DECLARE @ItemMasterId_Part BIGINT;
                DECLARE @ItemMasterNonStockId_Part BIGINT;
                DECLARE @IsSerializedPart BIT;
                DECLARE @SelectedPurchaseOrderPartRecordId BIGINT;
                DECLARE @QtyToReceive INT;
                DECLARE @MainPOPartBackOrderQty INT;
                DECLARE @ItemTypeId INT;

                SELECT @SelectedPurchaseOrderPartRecordId = [PurchaseOrderPartRecordId],
                       @QtyToReceive = [QtyToReceive]
                FROM #POPartsToReceive
                WHERE ID = @MainPartLoopID;

                SELECT @ItemMasterId_Part = POP.ItemMasterId,
                       @MainPOPartBackOrderQty = POP.QuantityBackOrdered,
                       @ItemTypeId = ItemTypeId
                FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
                WHERE POP.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;


                IF (@ItemTypeId = 1)
                BEGIN
                    SELECT @IsSerializedPart = IM.isSerialized FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId = @ItemMasterId_Part;

                    IF OBJECT_ID(N'tempdb..#tmpStocklineDraft') IS NOT NULL
                    BEGIN
                        DROP TABLE #tmpStocklineDraft
                    END

                    CREATE TABLE #tmpStocklineDraft
                    (
                        ID BIGINT NOT NULL IDENTITY,
                        [StockLineDraftId] [bigint] NOT NULL,
                        [PartNumber] [varchar](50) NOT NULL,
                        [StockLineNumber] [varchar](50) NULL,
                        [StocklineMatchKey] [varchar](100) NULL,
                        [ControlNumber] [varchar](50) NULL,
                        [ItemMasterId] [bigint] NULL,
                        [Quantity] [int] NOT NULL,
                        [ConditionId] [bigint] NULL,
                        [SerialNumber] [varchar](30) NULL,
                        [ShelfLife] [bit] NULL,
                        [ShelfLifeExpirationDate] [datetime2](7) NULL,
                        [WarehouseId] [bigint] NULL,
                        [LocationId] [bigint] NULL,
                        [ObtainFrom] [bigint] NULL,
                        [Owner] [bigint] NULL,
                        [TraceableTo] [bigint] NULL,
                        [ManufacturerId] [bigint] NULL,
                        [Manufacturer] [varchar](50) NULL,
                        [ManufacturerLotNumber] [varchar](50) NULL,
                        [ManufacturingDate] [datetime2](7) NULL,
                        [ManufacturingBatchNumber] [varchar](50) NULL,
                        [PartCertificationNumber] [varchar](50) NULL,
                        [CertifiedBy] [varchar](100) NULL,
                        [CertifiedDate] [datetime2](7) NULL,
                        [TagDate] [datetime2](7) NULL,
                        [TagTypeIds] [varchar](max) NULL,
                        [TagType] [varchar](max) NULL,
                        [CertifiedDueDate] [datetime2](7) NULL,
                        [CalibrationMemo] [nvarchar](max) NULL,
                        [OrderDate] [datetime2](7) NULL,
                        [PurchaseOrderId] [bigint] NULL,
                        [PurchaseOrderUnitCost] [decimal](18, 2) NULL,
                        [InventoryUnitCost] [decimal](18, 2) NULL,
                        [RepairOrderId] [bigint] NULL,
                        [RepairOrderUnitCost] [decimal](18, 2) NULL,
                        [ReceivedDate] [datetime2](7) NULL,
                        [ReceiverNumber] [varchar](50) NULL,
                        [ReconciliationNumber] [varchar](50) NULL,
                        [UnitSalesPrice] [decimal](18, 2) NULL,
                        [CoreUnitCost] [decimal](18, 2) NULL,
                        [GLAccountId] [bigint] NULL,
                        [AssetId] [bigint] NULL,
                        [IsHazardousMaterial] [bit] NULL,
                        [IsPMA] [bit] NULL,
                        [IsDER] [bit] NULL,
                        [OEM] [bit] NULL,
                        [Memo] [nvarchar](max) NULL,
                        [ManagementStructureEntityId] [bigint] NULL,
                        [LegalEntityId] [bigint] NULL,
                        [MasterCompanyId] [int] NOT NULL,
                        [CreatedBy] [varchar](256) NOT NULL,
                        [UpdatedBy] [varchar](256) NOT NULL,
                        [CreatedDate] [datetime2](7) NOT NULL,
                        [UpdatedDate] [datetime2](7) NOT NULL,
                        [isSerialized] [bit] NULL,
                        [ShelfId] [bigint] NULL,
                        [BinId] [bigint] NULL,
                        [SiteId] [bigint] NULL,
                        [ObtainFromType] [int] NULL,
                        [OwnerType] [int] NULL,
                        [TraceableToType] [int] NULL,
                        [UnitCostAdjustmentReasonTypeId] [int] NULL,
                        [UnitSalePriceAdjustmentReasonTypeId] [int] NULL,
                        [IdNumber] [varchar](100) NULL,
                        [QuantityToReceive] [int] NOT NULL,
                        [PurchaseOrderExtendedCost] [decimal](18, 0) NOT NULL,
                        [ManufacturingTrace] [nvarchar](200) NULL,
                        [ExpirationDate] [datetime2](7) NULL,
                        [AircraftTailNumber] [nvarchar](200) NULL,
                        [ShippingViaId] [bigint] NULL,
                        [EngineSerialNumber] [nvarchar](200) NULL,
                        [QuantityRejected] [int] NOT NULL,
                        [PurchaseOrderPartRecordId] [bigint] NULL,
                        [ShippingAccount] [nvarchar](200) NULL,
                        [ShippingReference] [nvarchar](200) NULL,
                        [TimeLifeCyclesId] [bigint] NULL,
                        [TimeLifeDetailsNotProvided] [bit] NOT NULL,
                        [WorkOrderId] [bigint] NULL,
                        [WorkOrderMaterialsId] [bigint] NULL,
                        [QuantityReserved] [int] NULL,
                        [QuantityTurnIn] [int] NULL,
                        [QuantityIssued] [int] NULL,
                        [QuantityOnHand] [int] NULL,
                        [QuantityAvailable] [int] NULL,
                        [QuantityOnOrder] [int] NULL,
                        [QtyReserved] [int] NULL,
                        [QtyIssued] [int] NULL,
                        [BlackListed] [bit] NOT NULL,
                        [BlackListedReason] [varchar](500) NULL,
                        [Incident] [bit] NOT NULL,
                        [IncidentReason] [varchar](500) NULL,
                        [Accident] [bit] NOT NULL,
                        [AccidentReason] [varchar](500) NULL,
                        [RepairOrderPartRecordId] [bigint] NULL,
                        [isActive] [bit] NOT NULL,
                        [isDeleted] [bit] NOT NULL,
                        [WorkOrderExtendedCost] [decimal](20, 2) NOT NULL,
                        [RepairOrderExtendedCost] [decimal](18, 2) NULL,
                        [NHAItemMasterId] [bigint] NULL,
                        [TLAItemMasterId] [bigint] NULL,
                        [IsParent] [bit] NULL,
                        [ParentId] [bigint] NULL,
                        [IsSameDetailsForAllParts] [bit] NULL,
                        [Level1] [varchar](200) NULL,
                        [Level2] [varchar](200) NULL,
                        [Level3] [varchar](200) NULL,
                        [Level4] [varchar](200) NULL,
                        [Condition] [varchar](250) NULL,
                        [Warehouse] [varchar](250) NULL,
                        [Location] [varchar](250) NULL,
                        [ObtainFromName] [varchar](250) NULL,
                        [OwnerName] [varchar](250) NULL,
                        [TraceableToName] [varchar](250) NULL,
                        [GLAccount] [varchar](250) NULL,
                        [AssetName] [varchar](250) NULL,
                        [LegalEntityName] [varchar](250) NULL,
                        [ShelfName] [varchar](250) NULL,
                        [BinName] [varchar](250) NULL,
                        [SiteName] [varchar](250) NULL,
                        [ObtainFromTypeName] [varchar](250) NULL,
                        [OwnerTypeName] [varchar](250) NULL,
                        [TraceableToTypeName] [varchar](250) NULL,
                        [UnitCostAdjustmentReasonType] [varchar](250) NULL,
                        [UnitSalePriceAdjustmentReasonType] [varchar](250) NULL,
                        [ShippingVia] [varchar](250) NULL,
                        [WorkOrder] [varchar](250) NULL,
                        [WorkOrderMaterialsName] [varchar](250) NULL,
                        [TagTypeId] [bigint] NULL,
                        [StockLineDraftNumber] [varchar](250) NULL,
                        [StockLineId] [bigint] NULL,
                        [TaggedBy] [bigint] NULL,
                        [TaggedByName] [varchar](250) NULL,
                        [UnitOfMeasureId] [bigint] NULL,
                        [UnitOfMeasure] [varchar](250) NULL,
                        [RevisedPartId] [bigint] NULL,
                        [RevisedPartNumber] [varchar](250) NULL,
                        [TaggedByType] [int] NULL,
                        [TaggedByTypeName] [varchar](250) NULL,
                        [CertifiedById] [bigint] NULL,
                        [CertifiedTypeId] [int] NULL,
                        [CertifiedType] [varchar](250) NULL,
                        [CertTypeId] [varchar](max) NULL,
                        [CertType] [varchar](max) NULL,
                        [IsCustomerStock] [bit] NULL,
                        [isCustomerstockType] [bit] NULL,
                        [CustomerId] [bigint] NULL,
                        [CalibrationVendorId] [bigint] NULL,
                        [PerformedById] [bigint] NULL,
                        [LastCalibrationDate] [datetime] NULL,
                        [NextCalibrationDate] [datetime] NULL,
                        [LotId] [bigint] NULL,
                        [SalesOrderId] [bigint] NULL,
                        [SubWorkOrderId] [bigint] NULL,
                        [ExchangeSalesOrderId] [bigint] NULL,
                        [WOQty] [int] NULL,
                        [SOQty] [int] NULL,
                        [ForStockQty] [int] NULL,
                        [IsLotAssigned] [bit] NULL,
                        [LOTQty] [int] NULL,
                        [LOTQtyReserve] [int] NULL,
                        [OriginalCost] [decimal](18, 2) NULL,
                        [POOriginalCost] [decimal](18, 2) NULL,
                        [ROOriginalCost] [decimal](18, 2) NULL,
                        [VendorRMAId] [bigint] NULL,
                        [VendorRMADetailId] [bigint] NULL,
                        [LotMainStocklineId] [bigint] NULL,
                        [IsFromInitialPO] [bit] NULL,
                        [LotSourceId] [int] NULL,
                        [Adjustment] [decimal](18, 2) NULL,
                        [SerialNumberNotProvided] [bit] NULL,
                        [ShippingReferenceNumberNotProvided] [bit] NULL,
                        [IsStkTimeLife] [bit] NULL
                    )

                    INSERT INTO #tmpStocklineDraft
                    SELECT StockLineDraftId,PartNumber,StockLineNumber,StocklineMatchKey,ControlNumber,ItemMasterId,Quantity,ConditionId,SerialNumber,ShelfLife,ShelfLifeExpirationDate,WarehouseId,
					LocationId,ObtainFrom,Owner,TraceableTo,ManufacturerId,Manufacturer,ManufacturerLotNumber,ManufacturingDate,ManufacturingBatchNumber,PartCertificationNumber,CertifiedBy,CertifiedDate,
					TagDate,TagTypeIds,TagType,CertifiedDueDate,CalibrationMemo,OrderDate,PurchaseOrderId,PurchaseOrderUnitCost,InventoryUnitCost,RepairOrderId,RepairOrderUnitCost,ReceivedDate,
					ReceiverNumber,ReconciliationNumber,UnitSalesPrice,CoreUnitCost,GLAccountId,AssetId,IsHazardousMaterial,IsPMA,IsDER,OEM,Memo,ManagementStructureEntityId,LegalEntityId,MasterCompanyId,
					CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,isSerialized,ShelfId,BinId,SiteId,ObtainFromType,OwnerType,TraceableToType,UnitCostAdjustmentReasonTypeId,UnitSalePriceAdjustmentReasonTypeId,
					IdNumber,QuantityToReceive,PurchaseOrderExtendedCost,ManufacturingTrace,ExpirationDate,AircraftTailNumber,ShippingViaId,EngineSerialNumber,QuantityRejected,PurchaseOrderPartRecordId,
					ShippingAccount,ShippingReference,TimeLifeCyclesId,TimeLifeDetailsNotProvided,WorkOrderId,WorkOrderMaterialsId,QuantityReserved,QuantityTurnIn,QuantityIssued,QuantityOnHand,QuantityAvailable,
					QuantityOnOrder,QtyReserved,QtyIssued,BlackListed,BlackListedReason,Incident,IncidentReason,Accident,AccidentReason,RepairOrderPartRecordId,isActive,isDeleted,WorkOrderExtendedCost,RepairOrderExtendedCost,
					NHAItemMasterId,TLAItemMasterId,IsParent,ParentId,IsSameDetailsForAllParts,Level1,Level2,Level3,Level4,Condition,Warehouse,Location,ObtainFromName,OwnerName,TraceableToName,GLAccount,
					AssetName,LegalEntityName,ShelfName,BinName,SiteName,ObtainFromTypeName,OwnerTypeName,TraceableToTypeName,UnitCostAdjustmentReasonType,UnitSalePriceAdjustmentReasonType,ShippingVia,WorkOrder,
					WorkOrderMaterialsName,TagTypeId,StockLineDraftNumber,StockLineId,TaggedBy,TaggedByName,UnitOfMeasureId,UnitOfMeasure,RevisedPartId,RevisedPartNumber,TaggedByType,TaggedByTypeName,CertifiedById,
					CertifiedTypeId,CertifiedType,CertTypeId,CertType,IsCustomerStock,isCustomerstockType,CustomerId,CalibrationVendorId,PerformedById,LastCalibrationDate,NextCalibrationDate,LotId,SalesOrderId,
					SubWorkOrderId,ExchangeSalesOrderId,WOQty,SOQty,ForStockQty,IsLotAssigned,LOTQty,LOTQtyReserve,OriginalCost,POOriginalCost,ROOriginalCost,VendorRMAId,VendorRMADetailId,LotMainStocklineId,
					IsFromInitialPO,LotSourceId,Adjustment,SerialNumberNotProvided,ShippingReferenceNumberNotProvided,IsStkTimeLife
					FROM DBO.StocklineDraft StkDraft WITH (NOLOCK)
                    WHERE StkDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 1 AND StockLineNumber IS NULL
                    ORDER BY CreatedDate;

                    SET @CurrentIndex = 0;

                    IF (@IsSerializedPart = 1)
                    BEGIN
                        SET @LoopID = @QtyToReceive;
                    END
                    ELSE
                    BEGIN
                        DECLARE @IsSameDetailsForAllParts BIT = 1;

                        SELECT TOP 1 @IsSameDetailsForAllParts = StkDraft.IsSameDetailsForAllParts
                        FROM DBO.StocklineDraft StkDraft WITH (NOLOCK)
                        WHERE IsParent = 1 AND StkDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;

                        IF (@IsSameDetailsForAllParts = 0)
                        BEGIN
                            SET @LoopID = @QtyToReceive;
                        END
                        ELSE
                        BEGIN
                            SELECT @LoopID = MAX(ID) FROM #tmpStocklineDraft;
                        END
                    END

                    WHILE (@LoopID > 0)
                    BEGIN
                        DECLARE @SelectedStockLineDraftId BIGINT;
                        DECLARE @CurrentIdNumber AS BIGINT;
                        DECLARE @ReceiverNumber AS VARCHAR(50);
                        DECLARE @IdCodeTypeId BIGINT;
                        DECLARE @PORequestorId BIGINT;
                        DECLARE @POVendorId BIGINT;
                        DECLARE @NewStocklineId BIGINT;
                        DECLARE @StockLineNumber VARCHAR(100);
                        DECLARE @CNCurrentNumber BIGINT;
                        DECLARE @ControlNumber VARCHAR(50);

                        DECLARE @currentNo AS BIGINT = 0;
                        DECLARE @stockLineCurrentNo AS BIGINT;
                        DECLARE @ItemMasterId AS BIGINT;
                        DECLARE @ConditionId AS BIGINT;
                        DECLARE @StkPurchaseOrderUnitCost AS DECIMAL(18, 2) = 0;
                        DECLARE @ManufacturerId AS BIGINT;
                        DECLARE @PreviousStockLineNumber VARCHAR(50);

                        SELECT @SelectedStockLineDraftId = StockLineDraftId FROM #tmpStocklineDraft WHERE ID = @LoopID;

                        SELECT @PORequestorId = RequestedBy, @POVendorId = VendorId FROM DBO.PurchaseOrder WHERE PurchaseOrderId = @PurchaseOrderId;

                        SELECT @IdCodeTypeId = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) WHERE CodeType = 'Stock Line';

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

                        INSERT INTO #tmpCodePrefixes
                        (
                            CodePrefixId,
                            CodeTypeId,
                            CurrentNumber,
                            CodePrefix,
                            CodeSufix,
                            StartsFrom
                        )
                        SELECT CodePrefixId,
                               CP.CodeTypeId,
                               CurrentNummber,
                               CodePrefix,
                               CodeSufix,
                               StartsFrom
                        FROM dbo.CodePrefixes CP WITH (NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
                        WHERE CT.CodeTypeId = @IdCodeTypeId
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

                        /* PN Manufacturer Combination Stockline logic */
                        IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL
                        BEGIN
                            DROP TABLE #tmpPNManufacturer
                        END

                        CREATE TABLE #tmpPNManufacturer
                        (
                            ID BIGINT NOT NULL IDENTITY,
                            ItemMasterId BIGINT NULL,
                            ManufacturerId BIGINT NULL,
                            StockLineNumber VARCHAR(100) NULL,
                            CurrentStlNo BIGINT NULL,
                            isSerialized BIT NULL
                        );
                        WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId)
                        AS (SELECT ac.ItemMasterId, ac.ManufacturerId, MAX(ac.StockLineId) StockLineId 
							FROM (SELECT DISTINCT ItemMasterId FROM DBO.Stockline WITH (NOLOCK)) ac1
                                CROSS JOIN (SELECT DISTINCT ManufacturerId FROM DBO.Stockline WITH (NOLOCK)) ac2
                                LEFT JOIN DBO.Stockline ac WITH (NOLOCK) ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId
                            WHERE ac.MasterCompanyId = @MasterCompanyId
                            GROUP BY ac.ItemMasterId, ac.ManufacturerId
                            HAVING COUNT(ac.ItemMasterId) > 0)

                        INSERT INTO #tmpPNManufacturer
                        (
                            ItemMasterId,
                            ManufacturerId,
                            StockLineNumber,
                            CurrentStlNo,
                            isSerialized
                        )
                        SELECT CSTL.ItemMasterId,
                               CSTL.ManufacturerId,
                               StockLineNumber,
                               ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo,
                               IM.isSerialized
                        FROM CTE_Stockline CSTL
						INNER JOIN DBO.Stockline STL WITH (NOLOCK)
						INNER JOIN DBO.ItemMaster IM ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId 
						ON CSTL.StockLineId = STL.StockLineId
                        /* PN Manufacturer Combination Stockline logic */

                        DELETE FROM #tmpCodePrefixes;

                        INSERT INTO #tmpCodePrefixes
                        (
                            CodePrefixId,
                            CodeTypeId,
                            CurrentNumber,
                            CodePrefix,
                            CodeSufix,
                            StartsFrom
                        )
                        SELECT CodePrefixId,
                               CP.CodeTypeId,
                               CurrentNummber,
                               CodePrefix,
                               CodeSufix,
                               StartsFrom
                        FROM dbo.CodePrefixes CP WITH (NOLOCK)
						JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
                        WHERE CT.CodeTypeId IN ( 30, 17, 9 )
                              AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

                        SELECT @ItemMasterId = ItemMasterId,
                               @ConditionId = ConditionId,
                               @StkPurchaseOrderUnitCost = PurchaseOrderUnitCost,
                               @ManufacturerId = ManufacturerId,
                               @PreviousStockLineNumber = StockLineNumber
                        FROM dbo.StocklineDraft WITH (NOLOCK)
                        WHERE StockLineDraftId = @SelectedStockLineDraftId;

                        SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId;

                        IF (@currentNo <> 0)
                        BEGIN
                            SET @stockLineCurrentNo = @currentNo + 1;
                        END
                        ELSE
                        BEGIN
                            SET @stockLineCurrentNo = 1;
                        END

                        IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 30))
                        BEGIN
                            SET @StockLineNumber =
                            (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@stockLineCurrentNo, 
							(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 30),
							(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 30)))

                            UPDATE DBO.ItemMaster
                            SET CurrentStlNo = @stockLineCurrentNo
                            WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId
                        END

                        IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 9))
                        BEGIN
                            SELECT @CNCurrentNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END
                            FROM #tmpCodePrefixes WHERE CodeTypeId = 9;
                            SET @ControlNumber =
                            (
                                SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CNCurrentNumber, 
								(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 9),
								(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 9))
                            )
                        END

                        INSERT INTO DBO.Stockline
                        ([PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],
						[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber],
						[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],
						[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo],
						[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],
						[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],
						[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],
						[WorkOrderId],[WorkOrderMaterialsId],[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved],[QtyIssued],[BlackListed],
						[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],
						[EntryDate],[LotCost],[NHAItemMasterId],[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate],[VendorId],
						[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId],[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],
						[Level1],[Level2],[Level3],[Level4],[Condition],[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber],[NHAPartNumber],
						[TLAPartDescription],[NHAPartDescription],[itemType],[CustomerId],[CustomerName],[isCustomerstockType],[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],
						[UnitCost],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],[IsFinishGood],[IsTurnIn],[IsCustomerRMA],[RMADeatilsId],
						[DaysReceived],[ManufacturingDays],[TagDays],[OpenDays],[ExchangeSalesOrderId],[RRQty],[SubWorkOrderNumber],[IsManualEntry],[WorkOrderMaterialsKitId],[LotId],[IsLotAssigned],[LOTQty],[LOTQtyReserve],
						[OriginalCost],[POOriginalCost],[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment],[IsStkTimeLife])
                        SELECT [PartNumber],@StockLineNumber,[StocklineMatchKey],@ControlNumber,[ItemMasterId],CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE 
							CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],
						[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber],
						[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],
						ISNULL([RepairOrderUnitCost], 0),[ReceivedDate],@ReceiverNumber,[ReconciliationNumber],ISNULL([UnitSalesPrice], 0),ISNULL([CoreUnitCost], 0),[GLAccountId],[AssetId],[IsHazardousMaterial],
						[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureEntityId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[isSerialized],[ShelfId],[BinId],[SiteId],
						NULL,[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],
						[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],
						[WorkOrderId],[WorkOrderMaterialsId],ISNULL([QuantityReserved], 0),ISNULL([QuantityTurnIn], 0),ISNULL([QuantityIssued], 0),CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE 
							CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,
						CASE WHEN @IsSerializedPart = 1 THEN [Quantity] 
							ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,
						ISNULL([QuantityOnOrder], 0),ISNULL([QtyReserved], 0),ISNULL([QtyIssued], 0),[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],
						[isActive],[isDeleted],[WorkOrderExtendedCost],ISNULL([RepairOrderExtendedCost], 0),[IsCustomerStock],GETUTCDATE(),0,[NHAItemMasterId],[TLAItemMasterId],NULL,NULL,@PORequestorId,NULL,NULL,
						NULL,NULL,NULL,@POVendorId,[IsParent],[ParentId],[IsSameDetailsForAllParts],0,[SubWorkOrderId],0,NULL,[UnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],
						[Level3],[Level4],[Condition],NULL,NULL,[Warehouse],[Location],NULL,NULL,[UnitOfMeasure],NULL,NULL,NULL,NULL,NULL,NULL,NULL,[CustomerId],NULL,ISNULL([isCustomerstockType], 0),'',NULL,NULL,
						NULL,[TaggedBy],[TaggedByName],(ISNULL(PurchaseOrderUnitCost, 0) + ISNULL(RepairOrderUnitCost, 0) + ISNULL(Adjustment, 0)),[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],
						[CertifiedType],[CertTypeId],[CertType],[TagTypeId],0,0,NULL,NULL,NULL,NULL,NULL,NULL,[ExchangeSalesOrderId],CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE @QtyToReceive END,NULL,1,NULL,
						[LotId],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost],[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],ISNULL(Adjustment, 0),[IsStkTimeLife]
                        FROM #tmpStocklineDraft
                        WHERE StockLineDraftId = @SelectedStockLineDraftId;

                        DECLARE @QtyAdded INT = 0;
                        DECLARE @PurchaseOrderUnitCostAdded DECIMAL(18, 2) = 0;
                        DECLARE @SelectedIsSameDetailsForAllParts BIT = 0;
                        DECLARE @IsTimeLIfe BIT

                        SELECT @QtyAdded = CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,
                               @SelectedIsSameDetailsForAllParts = IsSameDetailsForAllParts,
                               @PurchaseOrderUnitCostAdded = PurchaseOrderUnitCost,
                               @IsTimeLIfe = [IsStkTimeLife]
                        FROM #tmpStocklineDraft WHERE StockLineDraftId = @SelectedStockLineDraftId;

                        SELECT @NewStocklineId = SCOPE_IDENTITY();

                        INSERT INTO #InsertedStkForLot (StockLineId)
                        SELECT @NewStocklineId

                        IF (@IsTimeLIfe = 1)
                        BEGIN
                            INSERT INTO DBO.TimeLife
                            (
                                [CyclesRemaining],
                                [CyclesSinceNew],
                                [CyclesSinceOVH],
                                [CyclesSinceInspection],
                                [CyclesSinceRepair],
                                [TimeRemaining],
                                [TimeSinceNew],
                                [TimeSinceOVH],
                                [TimeSinceInspection],
                                [TimeSinceRepair],
                                [LastSinceNew],
                                [LastSinceOVH],
                                [LastSinceInspection],
                                [MasterCompanyId],
                                [CreatedBy],
                                [UpdatedBy],
                                [CreatedDate],
                                [UpdatedDate],
                                [IsActive],
                                [PurchaseOrderId],
                                [PurchaseOrderPartRecordId],
                                [StockLineId],
                                [DetailsNotProvided],
                                [RepairOrderId],
                                [RepairOrderPartRecordId],
                                [VendorRMAId],
                                [VendorRMADetailId]
                            )
                            SELECT [CyclesRemaining],
                                   [CyclesSinceNew],
                                   [CyclesSinceOVH],
                                   [CyclesSinceInspection],
                                   [CyclesSinceRepair],
                                   [TimeRemaining],
                                   [TimeSinceNew],
                                   [TimeSinceOVH],
                                   [TimeSinceInspection],
                                   [TimeSinceRepair],
                                   [LastSinceNew],
                                   [LastSinceOVH],
                                   [LastSinceInspection],
                                   @MasterCompanyId,
                                   @UpdatedBy,
                                   @UpdatedBy,
                                   GETUTCDATE(),
                                   GETUTCDATE(),
                                   1,
                                   @PurchaseOrderId,
                                   @SelectedPurchaseOrderPartRecordId,
                                   @NewStocklineId,
                                   [DetailsNotProvided],
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL
                            FROM DBO.TimeLifeDraft
                            WHERE StockLineDraftId = @SelectedStockLineDraftId;
                        END

                        /* Accounting Entry */
                        DECLARE @p2 dbo.PostStocklineBatchType;

                        INSERT INTO @p2 VALUES (@NewStocklineId, @QtyAdded, @PurchaseOrderUnitCostAdded, 'ReceivingPO', @UpdatedBy, @MasterCompanyId, 'STOCK')

                        EXEC dbo.usp_PostCreateStocklineBatchDetails @tbl_PostStocklineBatchType = @p2, @MstCompanyId = @MasterCompanyId, @updatedByName = @UpdatedBy;

                        DECLARE @ReceivingPurchaseOrderModule AS BIGINT = 28;

                        EXEC USP_AddUpdateStocklineHistory @NewStocklineId, @ReceivingPurchaseOrderModule, @PurchaseOrderId, NULL, NULL, 11, @QtyAdded, @UpdatedBy;
                        EXEC USP_CreateStocklinePartHistory @NewStocklineId, 1, 0, 0, 0;

                        UPDATE CodePrefixes SET CurrentNummber = @CNCurrentNumber WHERE CodeTypeId = 9 AND MasterCompanyId = @MasterCompanyId;

                        DECLARE @StkManagementStructureModuleId BIGINT = 2;
                        DECLARE @ManagementStructureEntityId BIGINT = 0;

                        SELECT @ManagementStructureEntityId = [ManagementStructureId] FROM DBO.Stockline WHERE StocklineId = @NewStocklineId;

                        EXEC dbo.[USP_SaveSLMSDetails] @StkManagementStructureModuleId, @NewStocklineId, @ManagementStructureEntityId, @MasterCompanyId, @UpdatedBy;

                        IF (@IsSerializedPart = 0 AND @SelectedIsSameDetailsForAllParts = 1)
                        BEGIN
                            DECLARE @LoopID_QtyToReceive INT = 0;
                            IF OBJECT_ID(N'tempdb..#StocklineDraftForQtyToReceive') IS NOT NULL
                            BEGIN
                                DROP TABLE #StocklineDraftForQtyToReceive
                            END

                            CREATE TABLE #StocklineDraftForQtyToReceive
                            (
                                ID BIGINT NOT NULL IDENTITY,
                                [StocklineDraftId] [bigint] NULL
                            )

                            INSERT INTO #StocklineDraftForQtyToReceive
                            (
                                [StocklineDraftId]
                            )
                            SELECT [StocklineDraftId] FROM DBO.StocklineDraft WITH (NOLOCK)
                            WHERE PurchaseOrderId = @PurchaseOrderId
                                  AND PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId
                                  AND IsParent = 0
                                  AND isSerialized = 0
                                  AND IsSameDetailsForAllParts = 1
                                  AND StockLineId IS NULL
                            ORDER BY StocklineDraftId DESC;

                            SELECT @LoopID_QtyToReceive = MAX(ID) FROM #StocklineDraftForQtyToReceive;

                            DECLARE @TotalQtyToTraverse INT = 0;

                            SET @TotalQtyToTraverse = @QtyToReceive;

                            WHILE (@LoopID_QtyToReceive > 0)
                            BEGIN
                                IF (@TotalQtyToTraverse > 0)
                                BEGIN
                                    DECLARE @CurrentStocklineDraftId BIGINT = 0;

                                    SELECT @CurrentStocklineDraftId = StocklineDraftId
                                    FROM #StocklineDraftForQtyToReceive
                                    WHERE ID = @LoopID_QtyToReceive;

                                    UPDATE StocklineDraft
                                    SET StockLineId = @NewStocklineId,
                                        StockLineNumber = @StockLineNumber,
                                        ForStockQty = @QtyToReceive
                                    WHERE StockLineDraftId = @CurrentStocklineDraftId;

                                    SET @TotalQtyToTraverse = @TotalQtyToTraverse - 1;
                                END

                                SET @LoopID_QtyToReceive = @LoopID_QtyToReceive - 1;
                            END

                            IF ((@MainPOPartBackOrderQty - @QtyToReceive) > 0)
                            BEGIN
                                SET @StockLineNumber = NULL;
                                SET @NewStocklineId = NULL;
                            END

                            UPDATE dstl
                            SET dstl.StockLineId = @NewStocklineId,
                                dstl.StockLineNumber = @StockLineNumber,
                                dstl.ControlNumber = @ControlNumber,
                                dstl.ReceiverNumber = @ReceiverNumber
                            FROM DBO.StocklineDraft dstl
                            WHERE StockLineDraftId = @SelectedStockLineDraftId;

                            UPDATE DBO.StocklineDraft
                            SET StockLineId = 0
                            WHERE StockLineDraftId = @SelectedStockLineDraftId
                                  AND isSerialized = 0
                                  AND IsSameDetailsForAllParts = 1
                                  AND IsParent = 1;
                        END
                        ELSE
                        BEGIN
                            UPDATE dstl
                            SET dstl.StockLineId = @NewStocklineId,
                                dstl.StockLineNumber = @StockLineNumber,
                                dstl.ControlNumber = @ControlNumber,
                                dstl.ReceiverNumber = @ReceiverNumber
                            FROM DBO.StocklineDraft dstl
                            WHERE StockLineDraftId = @SelectedStockLineDraftId;
                        END

                        /* Update ItemMasterPurchaseSale */
                        IF EXISTS
                        (
                            SELECT TOP 1
                                1
                            FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
                            WHERE POP.PurchaseOrderId = @PurchaseOrderId
                                  AND POP.ItemMasterId = @ItemMasterId
                                  AND POP.ConditionId = @ConditionId
                        )
                        BEGIN
                            DECLARE @POP_UnitCost DECIMAL(18, 2) = 0;
                            DECLARE @POP_VendorListPrice DECIMAL(18, 2) = 0;
                            DECLARE @POP_DiscountPerUnit DECIMAL(18, 2) = 0;
                            DECLARE @POP_DiscountPercent BIGINT = 0;
                            DECLARE @POP_DiscountPercentValue BIGINT = 0;
                            DECLARE @POP_ConditionId BIGINT = 0;

                            DECLARE @PP_VendorListPrice DECIMAL(18, 2) = 0;
                            DECLARE @PP_PurchaseDiscAmount DECIMAL(18, 2) = 0;
                            DECLARE @PP_UnitPurchasePrice DECIMAL(18, 2) = 0;
                            DECLARE @PP_PurchaseDiscPerc DECIMAL(18, 2) = 0;

                            SELECT @POP_UnitCost = POP.UnitCost,
                                   @POP_VendorListPrice = POP.VendorListPrice,
                                   @POP_DiscountPerUnit = POP.DiscountPerUnit,
                                   @POP_DiscountPercent = POP.DiscountPercent,
                                   @POP_DiscountPercentValue = POP.DiscountPercentValue,
                                   @POP_ConditionId = POP.ConditionId
                            FROM dbo.PurchaseOrderPart POP WITH (NOLOCK)
                            WHERE POP.PurchaseOrderId = @PurchaseOrderId
                                  AND POP.ItemMasterId = @ItemMasterId
                                  AND POP.ConditionId = @ConditionId;

                            IF (@StkPurchaseOrderUnitCost = @POP_UnitCost)
                            BEGIN
                                SET @PP_VendorListPrice = ISNULL(@POP_VendorListPrice, 0);
                                SET @PP_PurchaseDiscAmount = ISNULL(@POP_DiscountPerUnit, 0);
                                SET @PP_UnitPurchasePrice
                                    = (ISNULL(@POP_VendorListPrice, 0) - ISNULL(@POP_DiscountPerUnit, 0));
                                SET @PP_PurchaseDiscPerc = @POP_DiscountPercent;
                            END
                            ELSE
                            BEGIN
                                DECLARE @disamt AS DECIMAL(18, 2) = 0;
                                SET @disamt = ((ISNULL(@StkPurchaseOrderUnitCost, 0) * (ISNULL(@POP_DiscountPercentValue, 0))) / 100);

                                SET @PP_VendorListPrice = ISNULL(@StkPurchaseOrderUnitCost, 0) + @disamt;
                                SET @PP_PurchaseDiscAmount = ISNULL(@disamt, 0);
                                SET @PP_UnitPurchasePrice = ISNULL(@StkPurchaseOrderUnitCost, 0);
                                SET @PP_PurchaseDiscPerc = @POP_DiscountPercent;
                            END

                            IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.ItemMasterPurchaseSale IMPS WITH (NOLOCK) WHERE IMPS.ItemMasterId = @ItemMasterId AND IMPS.ConditionId = @ConditionId)
                            BEGIN
                                INSERT INTO DBO.ItemMasterPurchaseSale
                                (
                                    [ItemMasterId],
                                    [PartNumber],
                                    [PP_UOMId],
                                    [PP_CurrencyId],
                                    [PP_FXRatePerc],
                                    [PP_VendorListPrice],
                                    [PP_LastListPriceDate],
                                    [PP_PurchaseDiscPerc],
                                    [PP_PurchaseDiscAmount],
                                    [PP_LastPurchaseDiscDate],
                                    [PP_UnitPurchasePrice],
                                    [SP_FSP_UOMId],
                                    [SP_FSP_CurrencyId],
                                    [SP_FSP_FXRatePerc],
                                    [SP_FSP_FlatPriceAmount],
                                    [SP_FSP_LastFlatPriceDate],
                                    [SP_CalSPByPP_MarkUpPercOnListPrice],
                                    [SP_CalSPByPP_MarkUpAmount],
                                    [SP_CalSPByPP_LastMarkUpDate],
                                    [SP_CalSPByPP_BaseSalePrice],
                                    [SP_CalSPByPP_SaleDiscPerc],
                                    [SP_CalSPByPP_SaleDiscAmount],
                                    [SP_CalSPByPP_LastSalesDiscDate],
                                    [SP_CalSPByPP_UnitSalePrice],
                                    [MasterCompanyId],
                                    [CreatedBy],
                                    [UpdatedBy],
                                    [CreatedDate],
                                    [UpdatedDate],
                                    [IsActive],
                                    [IsDeleted],
                                    [ConditionId],
                                    [SalePriceSelectId],
                                    [ConditionName],
                                    [PP_UOMName],
                                    [SP_FSP_UOMName],
                                    [PP_CurrencyName],
                                    [SP_FSP_CurrencyName],
                                    [PP_PurchaseDiscPercValue],
                                    [SP_CalSPByPP_SaleDiscPercValue],
                                    [SP_CalSPByPP_MarkUpPercOnListPriceValue],
                                    [SalePriceSelectName]
                                )
                                SELECT DISTINCT
                                    @ItemMasterId,
                                    POP.PartNumber,
                                    CASE
                                        WHEN IM.ItemMasterId IS NOT NULL THEN
                                            IM.PurchaseUnitOfMeasureId
                                        ELSE
                                            0
                                    END,
                                    CASE
                                        WHEN IM.ItemMasterId IS NOT NULL THEN
                                            IM.PurchaseCurrencyId
                                        ELSE
                                            0
                                    END,
                                    POP.ForeignExchangeRate,
                                    @PP_VendorListPrice,
                                    GETUTCDATE(),
                                    @PP_PurchaseDiscPerc,
                                    @PP_PurchaseDiscAmount,
                                    GETUTCDATE(),
                                    @PP_UnitPurchasePrice,
                                    NULL,
                                    NULL,
                                    0,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    @MasterCompanyId,
                                    @UpdatedBy,
                                    @UpdatedBy,
                                    GETUTCDATE(),
                                    GETUTCDATE(),
                                    1,
                                    0,
                                    @POP_ConditionId,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL
                                FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
                                    LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
                                        ON POP.ItemMasterId = IM.ItemMasterId
                                WHERE POP.PurchaseOrderId = @PurchaseOrderId
                                      AND POP.ItemMasterId = @ItemMasterId
                                      AND POP.ConditionId = @ConditionId;

                                EXEC dbo.UpdateItemMasterPurchaseSaleDetails @ItemMasterId;
                            END
                            ELSE
                            BEGIN
                                UPDATE IMPS
                                SET IMPS.PP_VendorListPrice = @PP_VendorListPrice,
                                    IMPS.PP_PurchaseDiscAmount = @PP_PurchaseDiscAmount,
                                    IMPS.PP_UnitPurchasePrice = @PP_UnitPurchasePrice,
                                    IMPS.PP_PurchaseDiscPerc = @PP_PurchaseDiscPerc,
                                    IMPS.UpdatedBy = @UpdatedBy,
                                    IMPS.UpdatedDate = GETUTCDATE()
                                FROM DBO.ItemMasterPurchaseSale IMPS
                                WHERE IMPS.ItemMasterId = @ItemMasterId AND IMPS.ConditionId = @ConditionId;
                            END
                        END

                        EXEC UpdateStocklineColumnsWithId @NewStocklineId;

                        SET @LoopID = @LoopID - 1;
                    END

					UPDATE Stk
					SET Stk.IsParent = 0
					FROM DBO.StocklineDraft Stk WHERE Stk.IsParent = 1 AND Stk.isSerialized = 0 AND Stk.StockLineNumber IS NOT NULL AND Stk.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;
                END
                ELSE IF (@ItemTypeId = 11)
                BEGIN
                    DECLARE @CurrentIdNumber_Asset AS BIGINT;

                    SELECT @IsSerializedPart = Ass.isSerialized
                    FROM DBO.Asset Ass WITH (NOLOCK)
                    WHERE Ass.AssetRecordId = @ItemMasterId_Part;
                    
					SELECT @CurrentIdNumber_Asset = ISNULL(CP.CurrentNummber, 0)
                    FROM dbo.CodePrefixes CP WITH (NOLOCK)
                    WHERE CP.CodeTypeId = 63
                          AND CP.MasterCompanyId = @MasterCompanyId
                          AND CP.IsActive = 1
                          AND CP.IsDeleted = 0;

                    IF OBJECT_ID(N'tempdb..#tmpAssetInventoryDraft') IS NOT NULL
                    BEGIN
                        DROP TABLE #tmpAssetInventoryDraft
                    END

                    CREATE TABLE #tmpAssetInventoryDraft
                    (
                        ID BIGINT NOT NULL IDENTITY,
                        [AssetInventoryDraftId] [bigint] NOT NULL,
                        [AssetInventoryId] [bigint] NOT NULL,
                        [AssetRecordId] [bigint] NOT NULL,
                        [AssetId] [varchar](30) NOT NULL,
                        [AlternateAssetRecordId] [bigint] NULL,
                        [Name] [varchar](50) NOT NULL,
                        [Description] [nvarchar](max) NULL,
                        [ManagementStructureId] [bigint] NOT NULL,
                        [CalibrationRequired] [bit] NOT NULL,
                        [CertificationRequired] [bit] NOT NULL,
                        [InspectionRequired] [bit] NOT NULL,
                        [VerificationRequired] [bit] NOT NULL,
                        [IsTangible] [bit] NOT NULL,
                        [IsIntangible] [bit] NOT NULL,
                        [AssetAcquisitionTypeId] [bigint] NULL,
                        [ManufacturerId] [bigint] NULL,
                        [ManufacturedDate] [datetime2](7) NULL,
                        [Model] [varchar](30) NULL,
                        [IsSerialized] [bit] NOT NULL,
                        [UnitOfMeasureId] [bigint] NULL,
                        [CurrencyId] [int] NULL,
                        [UnitCost] [decimal](18, 2) NULL,
                        [ExpirationDate] [datetime2](7) NULL,
                        [Memo] [nvarchar](max) NULL,
                        [AssetParentRecordId] [bigint] NULL,
                        [TangibleClassId] [bigint] NULL,
                        [AssetIntangibleTypeId] [bigint] NULL,
                        [AssetCalibrationMin] [varchar](30) NULL,
                        [AssetCalibrationMinTolerance] [varchar](30) NULL,
                        [AssetCalibratonMax] [varchar](30) NULL,
                        [AssetCalibrationMaxTolerance] [varchar](30) NULL,
                        [AssetCalibrationExpected] [varchar](30) NULL,
                        [AssetCalibrationExpectedTolerance] [varchar](30) NULL,
                        [AssetCalibrationMemo] [nvarchar](max) NULL,
                        [AssetIsMaintenanceReqd] [bit] NOT NULL,
                        [AssetMaintenanceIsContract] [bit] NOT NULL,
                        [AssetMaintenanceContractFile] [nvarchar](512) NULL,
                        [MaintenanceFrequencyMonths] [int] NOT NULL,
                        [MaintenanceFrequencyDays] [bigint] NULL,
                        [MaintenanceDefaultVendorId] [bigint] NULL,
                        [MaintenanceGLAccountId] [bigint] NULL,
                        [MaintenanceMemo] [nvarchar](max) NULL,
                        [IsWarrantyRequired] [bit] NOT NULL,
                        [WarrantyCompany] [varchar](30) NULL,
                        [WarrantyStartDate] [datetime2](7) NULL,
                        [WarrantyEndDate] [datetime2](7) NULL,
                        [WarrantyStatusId] [bigint] NULL,
                        [UnexpiredTime] [int] NULL,
                        [MasterCompanyId] [int] NOT NULL,
                        [AssetLocationId] [bigint] NULL,
                        [IsDeleted] [bit] NOT NULL,
                        [Warranty] [bit] NOT NULL,
                        [IsActive] [bit] NOT NULL,
                        [CalibrationDefaultVendorId] [bigint] NULL,
                        [CertificationDefaultVendorId] [bigint] NULL,
                        [InspectionDefaultVendorId] [bigint] NULL,
                        [VerificationDefaultVendorId] [bigint] NULL,
                        [CertificationFrequencyMonths] [int] NOT NULL,
                        [CertificationFrequencyDays] [bigint] NULL,
                        [CertificationDefaultCost] [decimal](18, 2) NULL,
                        [CertificationGlAccountId] [bigint] NULL,
                        [CertificationMemo] [nvarchar](max) NULL,
                        [InspectionMemo] [nvarchar](max) NULL,
                        [InspectionGlaAccountId] [bigint] NULL,
                        [InspectionDefaultCost] [decimal](18, 2) NULL,
                        [InspectionFrequencyMonths] [int] NOT NULL,
                        [InspectionFrequencyDays] [bigint] NULL,
                        [VerificationFrequencyDays] [bigint] NULL,
                        [VerificationFrequencyMonths] [int] NOT NULL,
                        [VerificationDefaultCost] [decimal](18, 2) NULL,
                        [CalibrationDefaultCost] [decimal](18, 2) NULL,
                        [CalibrationFrequencyMonths] [int] NOT NULL,
                        [CalibrationFrequencyDays] [bigint] NULL,
                        [CalibrationGlAccountId] [bigint] NULL,
                        [CalibrationMemo] [nvarchar](max) NULL,
                        [VerificationMemo] [nvarchar](max) NULL,
                        [VerificationGlAccountId] [bigint] NULL,
                        [CalibrationCurrencyId] [int] NULL,
                        [CertificationCurrencyId] [int] NULL,
                        [InspectionCurrencyId] [int] NULL,
                        [VerificationCurrencyId] [int] NULL,
                        [CreatedBy] [varchar](256) NOT NULL,
                        [UpdatedBy] [varchar](256) NOT NULL,
                        [CreatedDate] [datetime2](7) NOT NULL,
                        [UpdatedDate] [datetime2](7) NOT NULL,
                        [AssetMaintenanceContractFileExt] [varchar](50) NULL,
                        [WarrantyFile] [nvarchar](512) NULL,
                        [WarrantyFileExt] [varchar](50) NULL,
                        [MasterPartId] [bigint] NULL,
                        [EntryDate] [datetime2](7) NULL,
                        [InstallationCost] [decimal](18, 2) NULL,
                        [Freight] [decimal](18, 2) NULL,
                        [Insurance] [decimal](18, 2) NULL,
                        [Taxes] [decimal](18, 2) NULL,
                        [TotalCost] [decimal](18, 2) NULL,
                        [WarrantyDefaultVendorId] [bigint] NULL,
                        [WarrantyGLAccountId] [bigint] NULL,
                        [IsDepreciable] [bit] NOT NULL,
                        [IsNonDepreciable] [bit] NOT NULL,
                        [IsAmortizable] [bit] NOT NULL,
                        [IsNonAmortizable] [bit] NOT NULL,
                        [SerialNo] [nvarchar](50) NULL,
                        [IsInsurance] [bit] NOT NULL,
                        [AssetLife] [int] NOT NULL,
                        [WarrantyCompanyId] [bigint] NULL,
                        [WarrantyCompanyName] [varchar](100) NULL,
                        [WarrantyCompanySelectId] [int] NULL,
                        [WarrantyMemo] [nvarchar](max) NULL,
                        [IsQtyReserved] [bit] NOT NULL,
                        [InventoryStatusId] [bigint] NULL,
                        [InventoryNumber] [varchar](100) NULL,
                        [AssetStatusId] [bigint] NULL,
                        [Level1] [varchar](200) NULL,
                        [Level2] [varchar](200) NULL,
                        [Level3] [varchar](200) NULL,
                        [Level4] [varchar](200) NULL,
                        [ManufactureName] [varchar](100) NULL,
                        [LocationName] [varchar](100) NULL,
                        [Qty] [decimal](13, 2) NULL,
                        [StklineNumber] [varchar](100) NULL,
                        [AvailStatus] [varchar](100) NULL,
                        [PartNumber] [varchar](100) NULL,
                        [ControlNumber] [varchar](100) NULL,
                        [TagDate] [datetime] NULL,
                        [ShippingViaId] [bigint] NULL,
                        [ShippingVia] [varchar](250) NULL,
                        [ShippingAccount] [nvarchar](400) NULL,
                        [ShippingReference] [nvarchar](400) NULL,
                        [RepairOrderId] [bigint] NULL,
                        [RepairOrderPartRecordId] [bigint] NULL,
                        [PurchaseOrderId] [bigint] NULL,
                        [PurchaseOrderPartRecordId] [bigint] NULL,
                        [SiteId] [bigint] NULL,
                        [WarehouseId] [bigint] NULL,
                        [LocationId] [bigint] NULL,
                        [ShelfId] [bigint] NULL,
                        [BinId] [bigint] NULL,
                        [GLAccountId] [bigint] NULL,
                        [GLAccount] [varchar](100) NULL,
                        [SiteName] [varchar](250) NULL,
                        [Warehouse] [varchar](250) NULL,
                        [Location] [varchar](250) NULL,
                        [ShelfName] [varchar](250) NULL,
                        [BinName] [varchar](250) NULL,
                        [IsParent] [bit] NULL,
                        [ParentId] [bigint] NULL,
                        [IsSameDetailsForAllParts] [bit] NULL,
                        [ReceiverNumber] [varchar](100) NULL,
                        [ReceivedDate] [datetime2](7) NULL,
                        [CalibrationVendorId] [bigint] NULL,
                        [PerformedById] [bigint] NULL,
                        [LastCalibrationDate] [datetime] NULL,
                        [NextCalibrationDate] [datetime] NULL,
                    )

                    IF (@IsSerializedPart = 1)
                    BEGIN
                        INSERT INTO #tmpAssetInventoryDraft
                        SELECT * FROM DBO.AssetInventoryDraft AssetDraft WITH (NOLOCK)
                        WHERE AssetDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 1 AND StklineNumber IS NULL
                        ORDER BY CreatedDate;
                    END
                    ELSE
                    BEGIN
                        IF EXISTS (SELECT TOP 1 1 FROM DBO.AssetInventoryDraft AssetDraft WITH (NOLOCK) WHERE AssetDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 0 AND IsSameDetailsForAllParts = 0 AND StklineNumber IS NULL)
                        BEGIN
                            INSERT INTO #tmpAssetInventoryDraft
                            SELECT * FROM DBO.AssetInventoryDraft AssetDraft WITH (NOLOCK)
                            WHERE AssetDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 1 AND StklineNumber IS NULL
                            ORDER BY CreatedDate;
                        END
                        ELSE
                        BEGIN
                            INSERT INTO #tmpAssetInventoryDraft
                            SELECT * FROM DBO.AssetInventoryDraft AssetDraft WITH (NOLOCK)
                            WHERE AssetDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 0 AND StklineNumber IS NULL
                            ORDER BY CreatedDate;
                        END
                    END

                    SET @CurrentIndex = 0;

                    IF (@IsSerializedPart = 1)
                    BEGIN
                        SET @LoopID = @QtyToReceive;
                    END
                    ELSE
                    BEGIN
                        SET @LoopID = @QtyToReceive;
                    END

                    WHILE (@LoopID > 0)
                    BEGIN
                        DECLARE @SelectedStockLineDraftId_Asset BIGINT;
                        DECLARE @ReceiverNumber_Asset AS VARCHAR(50);
                        DECLARE @IdCodeTypeId_Asset BIGINT;
                        DECLARE @PORequestorId_Asset BIGINT;
                        DECLARE @POVendorId_Asset BIGINT;
                        DECLARE @NewStocklineId_Asset BIGINT;
                        DECLARE @NewAssetRecordId BIGINT;
                        DECLARE @StockLineNumber_Asset VARCHAR(100);
                        DECLARE @InventoryNumber_Asset VARCHAR(100);
                        DECLARE @CNCurrentNumber_Asset BIGINT;
                        DECLARE @ControlNumber_Asset VARCHAR(50);

                        DECLARE @currentNo_Asset AS BIGINT = 0;
                        DECLARE @stockLineCurrentNo_Asset AS BIGINT;
                        DECLARE @InventoryNumberCurrentNo_Asset AS BIGINT;
                        DECLARE @ItemMasterId_Asset AS BIGINT;
                        DECLARE @ConditionId_asset AS BIGINT;
                        DECLARE @StkPurchaseOrderUnitCost_Asset AS DECIMAL(18, 2) = 0;
                        DECLARE @ManufacturerId_Asset AS BIGINT;
                        DECLARE @PreviousStockLineNumber_Asset VARCHAR(50);
                        DECLARE @IsTangible BIT = 0;

                        SELECT @SelectedStockLineDraftId_Asset = AssetInventoryDraftId, @IsTangible = IsTangible FROM #tmpAssetInventoryDraft WHERE ID = @LoopID;

                        SELECT @PORequestorId_Asset = RequestedBy, @POVendorId_Asset = VendorId FROM DBO.PurchaseOrder WHERE PurchaseOrderId = @PurchaseOrderId;

                        SELECT @IdCodeTypeId_Asset = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'Inventory Stkline Number';

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

                        INSERT INTO #tmpCodePrefixes_Asset
                        (CodePrefixId, CodeTypeId, CurrentNumber, CodePrefix, CodeSufix, StartsFrom)
                        SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom
                        FROM dbo.CodePrefixes CP WITH (NOLOCK) 
						JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
                        WHERE CT.CodeTypeId = @IdCodeTypeId_Asset
                              AND CP.MasterCompanyId = @MasterCompanyId
                              AND CP.IsActive = 1 AND CP.IsDeleted = 0;

                        SET @ReceiverNumber_Asset = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentIdNumber_Asset, 'RecNo', 
						(SELECT CodeSufix FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = @IdCodeTypeId_Asset)))

                        DELETE FROM #tmpCodePrefixes_Asset;

                        INSERT INTO #tmpCodePrefixes_Asset (CodePrefixId, CodeTypeId, CurrentNumber, CodePrefix, CodeSufix, StartsFrom)
                        SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom
                        FROM dbo.CodePrefixes CP WITH (NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
                        WHERE CT.CodeTypeId IN (63, 64, 37) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

                        DECLARE @PartNumber_Asset VARCHAR(100) = '';
                        DECLARE @AssetId_Asset VARCHAR(100) = '';
                        DECLARE @CalibrationVendorId BIGINT = 0;
						DECLARE @PerformedById BIGINT = 0;
						DECLARE @DraftCreatedBy VARCHAR(100) = '';
						DECLARE @CalibrationMemo VARCHAR(MAX) = '';
						DECLARE @LastCalibrationDate Datetime;
						DECLARE @NextCalibrationDate Datetime;

                        SELECT @ItemMasterId_Asset = AssetRecordId,
                               @AssetId_Asset = AssetId,
                               @StkPurchaseOrderUnitCost_Asset = UnitCost,
                               @ManufacturerId_Asset = ManufacturerId,
                               @PreviousStockLineNumber_Asset = StklineNumber,
                               @PartNumber_Asset = PartNumber,
							   @CalibrationVendorId = CalibrationVendorId,
							   @PerformedById = PerformedById,
							   @CalibrationMemo = CalibrationMemo,
							   @DraftCreatedBy = CreatedBy,
							   @LastCalibrationDate = LastCalibrationDate,
							   @NextCalibrationDate = NextCalibrationDate
                        FROM dbo.AssetInventoryDraft WITH (NOLOCK)
                        WHERE AssetInventoryDraftId = @SelectedStockLineDraftId_Asset;

                        --IF (@currentNo_Asset <> 0)  
                        IF EXISTS (SELECT TOP 1 1 FROM DBO.AssetInventory AI WITH (NOLOCK) WHERE AI.AssetId = @AssetId_Asset AND AI.PartNumber = @PartNumber_Asset AND AI.MasterCompanyId = @MasterCompanyId)
                        BEGIN
                            DECLARE @CntrlNumber INT = 0;

                            SELECT @CntrlNumber = ASST.CntrlNumber
                            FROM DBO.Asset ASST WITH (NOLOCK)
                            WHERE ASST.AssetId = @AssetId_Asset
                                  AND ASST.ManufacturerPN = @PartNumber_Asset
                                  AND ASST.MasterCompanyId = @MasterCompanyId;

                            PRINT @CntrlNumber;

                            SET @stockLineCurrentNo_Asset = @CntrlNumber + 1;

                            UPDATE DBO.Asset
                            SET CntrlNumber = @stockLineCurrentNo_Asset
                            WHERE AssetId = @AssetId_Asset
                                  AND ManufacturerPN = @PartNumber_Asset
                                  AND MasterCompanyId = @MasterCompanyId;
                        END
                        ELSE
                        BEGIN
                            SET @stockLineCurrentNo_Asset = 1;
                        END

                        IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = 37))
                        BEGIN
                            SELECT *
                            FROM #tmpCodePrefixes_Asset;
                            SELECT @InventoryNumberCurrentNo_Asset = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END
                            FROM #tmpCodePrefixes_Asset
                            WHERE CodeTypeId = 37;

                            SET @InventoryNumber_Asset = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@InventoryNumberCurrentNo_Asset,
                                     (SELECT CodePrefix FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = 37),
                                     (SELECT CodeSufix FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = 37)))

                            UPDATE DBO.CodePrefixes
                            SET CurrentNummber = @InventoryNumberCurrentNo_Asset
                            WHERE CodeTypeId = 37 AND MasterCompanyId = @MasterCompanyId;
                        END

                        IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = 63))
                        BEGIN
                            SET @StockLineNumber_Asset = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(   @stockLineCurrentNo_Asset,
                                     (SELECT CodePrefix FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = 63),
                                     (SELECT CodeSufix FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = 63)))

                            UPDATE DBO.CodePrefixes
                            SET CurrentNummber = @stockLineCurrentNo_Asset
                            WHERE CodeTypeId = 63 AND MasterCompanyId = @MasterCompanyId;
                        END


                        IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = 64))
                        BEGIN
                            SELECT @CNCurrentNumber_Asset = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END
                            FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = 64;

                            SET @ControlNumber_Asset = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(   @CNCurrentNumber_Asset,
                                     (SELECT CodePrefix FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = 64),
                                     (SELECT CodeSufix FROM #tmpCodePrefixes_Asset WHERE CodeTypeId = 64)))

                            UPDATE DBO.CodePrefixes SET CurrentNummber = @CNCurrentNumber_Asset WHERE CodeTypeId = 64 AND MasterCompanyId = @MasterCompanyId;
                        END

                        INSERT INTO DBO.AssetInventory
                        ([AssetRecordId],[AssetId],[AlternateAssetRecordId],[Name],[Description],[ManagementStructureId],[CalibrationRequired],[CertificationRequired],[InspectionRequired],
						[VerificationRequired],[IsTangible],[IsIntangible],[AssetAcquisitionTypeId],[ManufacturerId],[ManufacturedDate],[Model],[IsSerialized],[UnitOfMeasureId],[CurrencyId],
						[UnitCost],[ExpirationDate],[Memo],[AssetParentRecordId],[TangibleClassId],[AssetIntangibleTypeId],[AssetCalibrationMin],[AssetCalibrationMinTolerance],[AssetCalibratonMax],
						[AssetCalibrationMaxTolerance],[AssetCalibrationExpected],[AssetCalibrationExpectedTolerance],[AssetCalibrationMemo],[AssetIsMaintenanceReqd],[AssetMaintenanceIsContract],
						[AssetMaintenanceContractFile],[MaintenanceFrequencyMonths],[MaintenanceFrequencyDays],[MaintenanceDefaultVendorId],[MaintenanceGLAccountId],[MaintenanceMemo],[IsWarrantyRequired],
						[WarrantyCompany],[WarrantyStartDate],[WarrantyEndDate],[WarrantyStatusId],[UnexpiredTime],[MasterCompanyId],[AssetLocationId],[IsDeleted],[Warranty],[IsActive],[CalibrationDefaultVendorId],
						[CertificationDefaultVendorId],[InspectionDefaultVendorId],[VerificationDefaultVendorId],[CertificationFrequencyMonths],[CertificationFrequencyDays],[CertificationDefaultCost],
						[CertificationGlAccountId],[CertificationMemo],[InspectionMemo],[InspectionGlaAccountId],[InspectionDefaultCost],[InspectionFrequencyMonths],[InspectionFrequencyDays],[VerificationFrequencyDays],
						[VerificationFrequencyMonths],[VerificationDefaultCost],[CalibrationDefaultCost],[CalibrationFrequencyMonths],[CalibrationFrequencyDays],[CalibrationGlAccountId],[CalibrationMemo],
						[VerificationMemo],[VerificationGlAccountId],[CalibrationCurrencyId],[CertificationCurrencyId],[InspectionCurrencyId],[VerificationCurrencyId],[CreatedBy],[UpdatedBy],[CreatedDate],
						[UpdatedDate],[AssetMaintenanceContractFileExt],[WarrantyFile],[WarrantyFileExt],[MasterPartId],[EntryDate],[InstallationCost],[Freight],[Insurance],[Taxes],[TotalCost],[WarrantyDefaultVendorId],
						[WarrantyGLAccountId],[IsDepreciable],[IsNonDepreciable],[IsAmortizable],[IsNonAmortizable],[SerialNo],[IsInsurance],[AssetLife],[WarrantyCompanyId],[WarrantyCompanyName],[WarrantyCompanySelectId],
						[WarrantyMemo],[IsQtyReserved],[InventoryStatusId],[InventoryNumber],[AssetStatusId],[Level1],[Level2],[Level3],[Level4],[ManufactureName],[LocationName],[Qty],[StklineNumber],[AvailStatus],
						[PartNumber],[ControlNumber],[RepairOrderId],[RepairOrderPartRecordId],[PurchaseOrderId],[PurchaseOrderPartRecordId],[ReceiverNumber],[ReceivedDate],[SiteId],[SiteName],[WarehouseId],
						[Warehouse],[LocationId],[Location],[ShelfId],[ShelfName],[BinId],[BinName],[StatusNote],[RRQty],[DepreciationMethodId],[DepreciationMethodName],[ResidualPercentageId],[ResidualPercentage],
						[DepreciationFrequencyId],[DepreciationFrequencyName],[AcquiredGLAccountId],[AcquiredGLAccountName],[DeprExpenseGLAccountId],[DeprExpenseGLAccountName],[AdDepsGLAccountId],[AdDepsGLAccountName],
						[AssetSaleGLAccountId],[AssetSaleGLAccountName],[AssetWriteOffGLAccountId],[AssetWriteOffGLAccountName],[AssetWriteDownGLAccountId],[AssetWriteDownGLAccountName],[IntangibleGLAccountId],
						[IntangibleGLAccountName],[AmortExpenseGLAccountId],[AmortExpenseGLAccountName],[AccAmortDeprGLAccountId],[AccAmortDeprGLAccountName],[IntangibleWriteDownGLAccountId],[IntangibleWriteDownGLAccountName],
						[IntangibleWriteOffGLAccountId],[IntangibleWriteOffGLAccountName],[AssetAttributeTypeId],[ReceivablesAmount])
                        SELECT [AssetRecordId],[AssetId],[AlternateAssetRecordId],[Name],[Description],[ManagementStructureId],[CalibrationRequired],[CertificationRequired],[InspectionRequired],
						[VerificationRequired],[IsTangible],[IsIntangible],[AssetAcquisitionTypeId],[ManufacturerId],[ManufacturedDate],[Model],[IsSerialized],[UnitOfMeasureId],[CurrencyId],[UnitCost],
						[ExpirationDate],[Memo],[AssetParentRecordId],[TangibleClassId],[AssetIntangibleTypeId],[AssetCalibrationMin],[AssetCalibrationMinTolerance],[AssetCalibratonMax],[AssetCalibrationMaxTolerance],
						[AssetCalibrationExpected],[AssetCalibrationExpectedTolerance],[AssetCalibrationMemo],[AssetIsMaintenanceReqd],[AssetMaintenanceIsContract],[AssetMaintenanceContractFile],[MaintenanceFrequencyMonths],
						[MaintenanceFrequencyDays],[MaintenanceDefaultVendorId],[MaintenanceGLAccountId],[MaintenanceMemo],[IsWarrantyRequired],[WarrantyCompany],[WarrantyStartDate],[WarrantyEndDate],[WarrantyStatusId],
						[UnexpiredTime],[MasterCompanyId],[AssetLocationId],[IsDeleted],[Warranty],[IsActive],[CalibrationDefaultVendorId],[CertificationDefaultVendorId],[InspectionDefaultVendorId],[VerificationDefaultVendorId],
						[CertificationFrequencyMonths],[CertificationFrequencyDays],[CertificationDefaultCost],[CertificationGlAccountId],[CertificationMemo],[InspectionMemo],[InspectionGlaAccountId],[InspectionDefaultCost],
						[InspectionFrequencyMonths],[InspectionFrequencyDays],[VerificationFrequencyDays],[VerificationFrequencyMonths],[VerificationDefaultCost],[CalibrationDefaultCost],[CalibrationFrequencyMonths],
						[CalibrationFrequencyDays],[CalibrationGlAccountId],[CalibrationMemo],[VerificationMemo],[VerificationGlAccountId],[CalibrationCurrencyId],[CertificationCurrencyId],[InspectionCurrencyId],[VerificationCurrencyId],
						[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[AssetMaintenanceContractFileExt],[WarrantyFile],[WarrantyFileExt],[MasterPartId],[EntryDate],[InstallationCost],[Freight],[Insurance],[Taxes],
						[TotalCost],[WarrantyDefaultVendorId],[WarrantyGLAccountId],[IsDepreciable],[IsNonDepreciable],[IsAmortizable],[IsNonAmortizable],[SerialNo],[IsInsurance],[AssetLife],[WarrantyCompanyId],[WarrantyCompanyName],
						[WarrantyCompanySelectId],[WarrantyMemo],[IsQtyReserved],1,@InventoryNumber_Asset,[AssetStatusId],[Level1],[Level2],[Level3],[Level4],[ManufactureName],[LocationName],[Qty],@StockLineNumber_Asset,[AvailStatus],
						[PartNumber],@ControlNumber_Asset,[RepairOrderId],[RepairOrderPartRecordId],[PurchaseOrderId],[PurchaseOrderPartRecordId],@ReceiverNumber_Asset,GETUTCDATE(),[SiteId],[SiteName],[WarehouseId],[Warehouse],
						[LocationId],[Location],[ShelfId],[ShelfName],[BinId],[BinName],'',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						NULL,NULL,NULL,NULL,NULL,NULL
						FROM #tmpAssetInventoryDraft
                        WHERE AssetInventoryDraftId = @SelectedStockLineDraftId_Asset;

                        DECLARE @QtyAdded_Asset INT = 0;
                        DECLARE @PurchaseOrderUnitCostAdded_Asset DECIMAL(18, 2) = 0;
                        DECLARE @SelectedIsSameDetailsForAllParts_Asset BIT = 0;
                        DECLARE @IsTimeLIfe_Asset BIT;

                        SELECT @QtyAdded_Asset = CASE WHEN @IsSerializedPart = 1 THEN [Qty] ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Qty] ELSE @QtyToReceive END END,
                               @SelectedIsSameDetailsForAllParts_Asset = IsSameDetailsForAllParts,
                               @PurchaseOrderUnitCostAdded_Asset = UnitCost
                        FROM #tmpAssetInventoryDraft WHERE AssetInventoryDraftId = @SelectedStockLineDraftId_Asset;

                        SELECT @NewStocklineId_Asset = SCOPE_IDENTITY();

						SET @NewAssetRecordId = (SELECT AssetRecordId FROM AssetInventory WHERE AssetInventoryId = @NewStocklineId_Asset)

						IF EXISTS (SELECT TOP 1 1 FROM DBO.AssetCalibration AC WITH (NOLOCK) WHERE AC.AssetRecordId = @ItemMasterId_Asset)
						BEGIN
							DECLARE @CalibrationRequired BIT = 0;
							DECLARE @EmployeeId BIGINT = 0;

							SELECT @EmployeeId = EmployeeId FROM DBO.Employee EMP WITH (NOLOCK) WHERE EMP.FirstName + '' + EMP.LastName = @UpdatedBy AND EMP.MasterCompanyId = @MasterCompanyId;

							SELECT @CalibrationRequired = AC.CalibrationRequired FROM DBO.AssetCalibration AC WITH (NOLOCK) WHERE AC.AssetRecordId = @ItemMasterId_Asset;

							IF (@CalibrationRequired = 1)
							BEGIN
								DECLARE @CalibrationType INT = 1; -- Calibration
								EXEC dbo.USP_UpsertAssetCalibration @NewStocklineId_Asset, 1, @CalibrationVendorId, @EmployeeId, @PerformedById , @CalibrationMemo, @DraftCreatedBy, @CalibrationType, @LastCalibrationDate, @NextCalibrationDate;
							END
						END 

                        /* Accounting Entry */
                        DECLARE @p3 dbo.PostStocklineBatchType;

                        INSERT INTO @p3
                        VALUES (@NewStocklineId_Asset, @QtyAdded_Asset, @PurchaseOrderUnitCostAdded_Asset, 'ReceivingPO', @UpdatedBy, @MasterCompanyId, 'STOCK')

                        EXEC dbo.usp_PostCreateStocklineBatchDetails @tbl_PostStocklineBatchType = @p3, @MstCompanyId = @MasterCompanyId, @updatedByName = @UpdatedBy;

                        DECLARE @ReceivingPurchaseOrderModule_Asset AS BIGINT = 28;

                        EXEC USP_AddUpdateStocklineHistory @NewStocklineId_Asset, @ReceivingPurchaseOrderModule_Asset, @PurchaseOrderId, NULL, NULL, 11, @QtyAdded_Asset, @UpdatedBy;
                        EXEC USP_CreateStocklinePartHistory @NewStocklineId_Asset, 1, 0, 0, 0;

                        UPDATE CodePrefixes
                        SET CurrentNummber = @CNCurrentNumber_Asset
                        WHERE CodeTypeId = 9 AND MasterCompanyId = @MasterCompanyId;

                        DECLARE @StkManagementStructureModuleId_Asset BIGINT = 2;
                        DECLARE @ManagementStructureEntityId_Asset BIGINT = 0;
                        DECLARE @ModuleId_AssetMS BIGINT = CASE WHEN @IsTangible = 1 THEN 42 ELSE 43 END;

                        SELECT @ManagementStructureEntityId_Asset = [ManagementStructureId]
                        FROM DBO.Stockline WHERE StocklineId = @NewStocklineId_Asset;

                        EXEC dbo.[PROCAddAssetMSData] @NewStocklineId_Asset, @ManagementStructureEntityId_Asset, @MasterCompanyId, @UpdatedBy, @UpdatedBy, @ModuleId_AssetMS, 1;

                        IF (@IsSerializedPart = 0 AND @SelectedIsSameDetailsForAllParts_Asset = 1)
                        BEGIN
                            DECLARE @LoopID_QtyToReceive_Asset INT = 0;

                            IF OBJECT_ID(N'tempdb..#StocklineDraftForQtyToReceive_Asset') IS NOT NULL
                            BEGIN
                                DROP TABLE #StocklineDraftForQtyToReceive_Asset
                            END

                            CREATE TABLE #StocklineDraftForQtyToReceive_Asset
                            (
                                ID BIGINT NOT NULL IDENTITY,
                                [AssetInventoryDraftId] [bigint] NULL
                            )

                            INSERT INTO #StocklineDraftForQtyToReceive_Asset
                            (
                                [AssetInventoryDraftId]
                            )
                            SELECT [AssetInventoryDraftId]
                            FROM DBO.AssetInventoryDraft WITH (NOLOCK)
                            WHERE PurchaseOrderId = @PurchaseOrderId
                                  AND PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId
                                  AND IsParent = 0
                                  AND isSerialized = 0
                                  AND IsSameDetailsForAllParts = 1
                                  AND AssetInventoryId IS NULL
                            ORDER BY AssetInventoryDraftId DESC;

                            SELECT @LoopID_QtyToReceive_Asset = MAX(ID)
                            FROM #StocklineDraftForQtyToReceive_Asset;
                            DECLARE @TotalQtyToTraverse_Asset INT = 0;

                            SET @TotalQtyToTraverse_Asset = @QtyToReceive;

                            WHILE (@LoopID_QtyToReceive_Asset > 0)
                            BEGIN
                                IF (@TotalQtyToTraverse_Asset > 0)
                                BEGIN
                                    DECLARE @CurrentStocklineDraftId_Asset BIGINT = 0;

                                    SELECT @CurrentStocklineDraftId_Asset = AssetInventoryDraftId
                                    FROM #StocklineDraftForQtyToReceive_Asset
                                    WHERE ID = @LoopID_QtyToReceive_Asset;

                                    UPDATE AssetInventoryDraft
                                    SET AssetInventoryId = @NewStocklineId_Asset,
                                        StklineNumber = @StockLineNumber_Asset
                                    WHERE AssetInventoryDraftId = @CurrentStocklineDraftId_Asset;

                                    SET @TotalQtyToTraverse_Asset = @TotalQtyToTraverse_Asset - 1;
                                END
                                SET @LoopID_QtyToReceive_Asset = @LoopID_QtyToReceive_Asset - 1;
                            END


                            IF ((@MainPOPartBackOrderQty - @QtyToReceive) > 0)
                            BEGIN
                                SET @StockLineNumber_Asset = NULL;
                                SET @NewStocklineId_Asset = NULL;
                            END

                            UPDATE dstl
                            SET dstl.AssetInventoryId = @NewStocklineId_Asset,
                                dstl.StklineNumber = @StockLineNumber_Asset,
                                dstl.ControlNumber = @ControlNumber_Asset,
                                dstl.ReceiverNumber = @ReceiverNumber_Asset
                            FROM DBO.AssetInventoryDraft dstl
                            WHERE AssetInventoryDraftId = @SelectedStockLineDraftId_Asset;

                            UPDATE DBO.AssetInventoryDraft
                            SET AssetInventoryId = 0
                            WHERE AssetInventoryDraftId = @SelectedStockLineDraftId_Asset
                                  AND isSerialized = 0
                                  AND IsSameDetailsForAllParts = 1
                                  AND IsParent = 1;
                        END
                        ELSE
                        BEGIN
                            UPDATE dstl
                            SET dstl.AssetInventoryId = @NewStocklineId_Asset,
                                dstl.StklineNumber = @StockLineNumber_Asset,
                                dstl.ControlNumber = @ControlNumber_Asset,
                                dstl.ReceiverNumber = @ReceiverNumber_Asset
                            FROM DBO.AssetInventoryDraft dstl
                            WHERE AssetInventoryDraftId = @SelectedStockLineDraftId_Asset;
                        END

                        EXEC UpdateStocklineColumnsWithId @NewStocklineId_Asset;
						EXEC UpdateAssetInventoryAttributeColumns @NewStocklineId_Asset,@NewAssetRecordId;

                        PRINT 'Decrease @LoopID';

                        SET @LoopID = @LoopID - 1;
                    END

					UPDATE Stk
					SET Stk.IsParent = CASE WHEN Stk.IsParent = 1 THEN 0 ELSE 1 END
					FROM DBO.AssetInventoryDraft Stk WHERE Stk.IsSameDetailsForAllParts = 0 AND Stk.isSerialized = 0 AND Stk.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;
                END
                ELSE IF (@ItemTypeId = 2)
                BEGIN
                    SELECT @IsSerializedPart = ISNULL(IM.isSerialized, 0) FROM DBO.ItemMasterNonStock IM WITH (NOLOCK) WHERE IM.MasterPartId = @ItemMasterId_Part;

                    DECLARE @ParentNonStockId BIGINT = 0;
                    DECLARE @NewNonStockInventoryId BIGINT = 0;
                    DECLARE @CurrentIdNumber_NonStock BIGINT;
                    DECLARE @IdCodeTypeId_NonStock BIGINT;
                    DECLARE @NonStockTotalRec [BIGINT] = 0;
                    DECLARE @ReceiverNumber_NonStock VARCHAR(250);
                    DECLARE @TempNonStockId [BIGINT] = 0;
                    DECLARE @NonStockCintrolNum VARCHAR(250);
                    DECLARE @StartNonStock [BIGINT] = 1;
                    DECLARE @NonStockCurrentNo BIGINT = 0;

                    SELECT @CurrentIdNumber_NonStock = ISNULL(CP.CurrentNummber, 0)
                    FROM dbo.CodePrefixes CP WITH (NOLOCK)
                    WHERE CP.CodeTypeId = 66 AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

                    SELECT @IdCodeTypeId_NonStock = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'NonStockline';

                    IF OBJECT_ID(N'tempdb..#tmpNonStockInventoryDraft') IS NOT NULL
                    BEGIN
                        DROP TABLE #tmpNonStockInventoryDraft
                    END

                    CREATE TABLE #tmpNonStockInventoryDraft
                    (
                        ID BIGINT NOT NULL IDENTITY,
                        [NonStockInventoryDraftId] [bigint] NOT NULL,
                        [NonStockDraftNumber] [varchar](50) NULL,
                        [PurchaseOrderId] [bigint] NOT NULL,
                        [PurchaseOrderPartRecordId] [bigint] NOT NULL,
                        [PurchaseOrderNumber] [varchar](50) NOT NULL,
                        [IsParent] [bit] NULL,
                        [ParentId] [bigint] NULL,
                        [MasterPartId] [bigint] NOT NULL,
                        [PartNumber] [varchar](50) NULL,
                        [PartDescription] [nvarchar](max) NULL,
                        [NonStockInventoryId] [bigint] NULL,
                        [NonStockInventoryNumber] [varchar](50) NULL,
                        [ControlNumber] [varchar](50) NULL,
                        [ControlID] [varchar](50) NULL,
                        [IdNumber] [varchar](50) NULL,
                        [ReceiverNumber] [varchar](50) NULL,
                        [ReceivedDate] [datetime2](7) NULL,
                        [IsSerialized] [bit] NOT NULL,
                        [SerialNumber] [varchar](50) NULL,
                        [Quantity] [int] NOT NULL,
                        [QuantityRejected] [int] NULL,
                        [QuantityOnHand] [int] NULL,
                        [CurrencyId] [bigint] NULL,
                        [Currency] [varchar](50) NULL,
                        [ConditionId] [bigint] NULL,
                        [Condition] [varchar](50) NULL,
                        [GLAccountId] [bigint] NULL,
                        [GLAccount] [varchar](50) NULL,
                        [UnitOfMeasureId] [bigint] NULL,
                        [UnitOfMeasure] [varchar](50) NULL,
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
                        [Site] [varchar](50) NULL,
                        [WarehouseId] [bigint] NULL,
                        [Warehouse] [varchar](50) NULL,
                        [LocationId] [bigint] NULL,
                        [Location] [varchar](50) NULL,
                        [ShelfId] [bigint] NULL,
                        [Shelf] [varchar](50) NULL,
                        [BinId] [bigint] NULL,
                        [Bin] [varchar](50) NULL,
                        [ShippingViaId] [bigint] NULL,
                        [ShippingVia] [varchar](50) NULL,
                        [ShippingAccount] [nvarchar](200) NULL,
                        [ShippingReference] [nvarchar](200) NULL,
                        [IsSameDetailsForAllParts] [bit] NULL,
                        [VendorId] [bigint] NULL,
                        [VendorName] [varchar](50) NULL,
                        [RequisitionerId] [bigint] NULL,
                        [Requisitioner] [varchar](50) NULL,
                        [OrderDate] [datetime2](7) NULL,
                        [EntryDate] [datetime2](7) NULL,
                        [ManagementStructureId] [bigint] NOT NULL,
                        [Level1] [varchar](100) NULL,
                        [Level2] [varchar](100) NULL,
                        [Level3] [varchar](100) NULL,
                        [Level4] [varchar](100) NULL,
                        [Memo] [nvarchar](max) NULL,
                        [MasterCompanyId] [int] NOT NULL,
                        [CreatedBy] [varchar](256) NOT NULL,
                        [UpdatedBy] [varchar](256) NOT NULL,
                        [CreatedDate] [datetime2](7) NOT NULL,
                        [UpdatedDate] [datetime2](7) NOT NULL,
                        [IsActive] [bit] NOT NULL,
                        [IsDeleted] [bit] NOT NULL,
                        [ShippingReferenceNumberNotProvided] [bit] NULL,
                        [SerialNumberNotProvided] [bit] NULL,
                        [TimeLifeDetailsNotProvided] [bit] NULL
                    )

                    INSERT INTO #tmpNonStockInventoryDraft
                    SELECT * FROM DBO.NonStockInventoryDraft NonStockDraft WITH (NOLOCK)
                    WHERE NonStockDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 1 AND NonStockInventoryNumber IS NULL --AND ISNULL(NonStockDraft.NonStockInventoryId, 0) = 0
                    ORDER BY NonStockInventoryDraftId;

                    IF (@IsSerializedPart = 1)
                    BEGIN
                        SET @NonStockTotalRec = @QtyToReceive;
                    END
                    ELSE
                    BEGIN
                        DECLARE @IsSameDetailsForAllParts_NS BIT = 1;
                        SELECT TOP 1 @IsSameDetailsForAllParts_NS = StkDraft.IsSameDetailsForAllParts
                        FROM DBO.NonStockInventoryDraft StkDraft WITH (NOLOCK) WHERE IsParent = 1 AND StkDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;

                        SELECT * FROM #tmpNonStockInventoryDraft

                        IF (@IsSameDetailsForAllParts_NS = 0)
                        BEGIN
                            SET @NonStockTotalRec = @QtyToReceive;
                        END
                        ELSE
                        BEGIN
                            SELECT @NonStockTotalRec = MAX(ID) FROM #tmpNonStockInventoryDraft;
                        END
                    END

                    SET @NonStockTotalRec = (SELECT ISNULL(MAX(ID), 0) FROM #tmpNonStockInventoryDraft);
                    
					IF (@NonStockTotalRec > 0)
                    BEGIN
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

                        INSERT INTO #tmpCodePrefixes_NonStock (CodePrefixId, CodeTypeId, CurrentNumber, CodePrefix, CodeSufix, StartsFrom)
                        SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom
                        FROM dbo.CodePrefixes CP WITH (NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
                        WHERE CT.CodeTypeId IN (66) AND CP.MasterCompanyId = @MasterCompanyId;

                        INSERT INTO #tmpCodePrefixes_NonStock
                        (CodePrefixId, CodeTypeId, CurrentNumber, CodePrefix, CodeSufix, StartsFrom)
                        SELECT TOP 1 CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom
                        FROM dbo.CodePrefixes CP WITH (NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
                        WHERE CT.CodeTypeId IN (68) AND CP.MasterCompanyId = @MasterCompanyId;

                        SET @ReceiverNumber_NonStock = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentIdNumber_NonStock, 'RecNo', ''))

                        WHILE (@StartNonStock <= @NonStockTotalRec)
                        BEGIN
                            DECLARE @MSId BIGINT = 0;
                            DECLARE @ManagementStructureID_NonStock BIGINT = 0;
                            DECLARE @MSModuleId_NonStock BIGINT = 0;
                            DECLARE @NonStockMasterPartId BIGINT = 0;
                            DECLARE @NonStockManufacturerId BIGINT = 0;
                            DECLARE @CurrentStlNumber BIGINT = 0;
                            DECLARE @NonStockInventoryNumber VARCHAR(250);
                            DECLARE @NonStockControlNumber VARCHAR(250);
                            DECLARE @CodePrefix_NonStock VARCHAR(100);
                            DECLARE @CodeSuffix_NonStock VARCHAR(100);
                            DECLARE @NonStockCurrentNumber BIGINT = 0;
                            SET @ParentNonStockId = 0;
                            SET @TempNonStockId = (SELECT NonStockInventoryDraftId FROM #tmpNonStockInventoryDraft WHERE ID = @StartNonStock);
                            SET @MSModuleId_NonStock = (SELECT ManagementStructureModuleId FROM ManagementStructureModule WHERE ModuleName = 'NonStockStockline')

                            SELECT CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END from #tmpNonStockInventoryDraft;

                            WITH tempNonStockInventory ([PurchaseOrderId], [PurchaseOrderPartRecordId],[PurchaseOrderNumber], [RepairOrderId], [IsParent], [ParentId],[MasterPartId], [PartNumber], [PartDescription],
								[NonStockInventoryNumber], [ControlNumber], [ControlID], [IdNumber], [ReceiverNumber], [ReceivedDate], [IsSerialized],[SerialNumber], [Quantity], [QuantityRejected],[QuantityOnHand], [CurrencyId], 
								[Currency], [ConditionId],[Condition], [GLAccountId], [GLAccount], [UnitOfMeasureId],[UnitOfMeasure], [ManufacturerId], [Manufacturer],[MfgExpirationDate], [UnitCost], [ExtendedCost], [Acquired],
								[IsHazardousMaterial], [ItemNonStockClassificationId],[NonStockClassification], [SiteId], [Site], [WarehouseId],[Warehouse], [LocationId], [Location], [ShelfId], [Shelf],[BinId], [Bin], 
								[ShippingViaId], [ShippingVia],[ShippingAccount], [ShippingReference],[IsSameDetailsForAllParts], [VendorId], [VendorName],[RequisitionerId], [Requisitioner], [OrderDate], [EntryDate],
								[ManagementStructureId], [Level1], [Level2], [Level3],[Level4], [Memo], [MasterCompanyId], [CreatedBy], [UpdatedBy],[CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [RRQty])
                            AS (SELECT [PurchaseOrderId],[PurchaseOrderPartRecordId],[PurchaseOrderNumber],0,[IsParent],[ParentId],[MasterPartId],[PartNumber],[PartDescription],[NonStockInventoryNumber],[ControlNumber],
								[ControlID],[IdNumber],[ReceiverNumber],[ReceivedDate],[IsSerialized],[SerialNumber],CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,
								[QuantityRejected],CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,[CurrencyId],[Currency],[ConditionId],
								[Condition],[GLAccountId],[GLAccount],[UnitOfMeasureId],[UnitOfMeasure],[ManufacturerId],[Manufacturer],[MfgExpirationDate],[UnitCost],[ExtendedCost],[Acquired],[IsHazardousMaterial],[ItemNonStockClassificationId],
								[NonStockClassification],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[ShelfId],[Shelf],[BinId],[Bin],[ShippingViaId],[ShippingVia],[ShippingAccount],[ShippingReference],
								[IsSameDetailsForAllParts],[VendorId],[VendorName],[RequisitionerId],[Requisitioner],[OrderDate],GETUTCDATE(),[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],'',[MasterCompanyId],
								[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE @QtyToReceive END
							FROM #tmpNonStockInventoryDraft WHERE NonStockInventoryDraftId = @TempNonStockId)

                            INSERT INTO dbo.NonStockInventory
                            ([PurchaseOrderId],[PurchaseOrderPartRecordId],[PurchaseOrderNumber],[RepairOrderId],[IsParent],[ParentId],[MasterPartId],[PartNumber],[PartDescription],[NonStockInventoryNumber],
							[ControlNumber],[ControlID],[IdNumber],[ReceiverNumber],[ReceivedDate],[IsSerialized],[SerialNumber],[Quantity],[QuantityRejected],[QuantityOnHand],[CurrencyId],[Currency],[ConditionId],
							[Condition],[GLAccountId],[GLAccount],[UnitOfMeasureId],[UnitOfMeasure],[ManufacturerId],[Manufacturer],[MfgExpirationDate],[UnitCost],[ExtendedCost],[Acquired],[IsHazardousMaterial],
							[ItemNonStockClassificationId],[NonStockClassification],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[ShelfId],[Shelf],[BinId],[Bin],[ShippingViaId],[ShippingVia],
							[ShippingAccount],[ShippingReference],[IsSameDetailsForAllParts],[VendorId],[VendorName],[RequisitionerId],[Requisitioner],[OrderDate],[EntryDate],[ManagementStructureId],[Level1],[Level2],
							[Level3],[Level4],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RRQty])
                            SELECT [PurchaseOrderId],[PurchaseOrderPartRecordId],[PurchaseOrderNumber],[RepairOrderId],[IsParent],[ParentId],[MasterPartId],[PartNumber],[PartDescription],[NonStockInventoryNumber],
							[ControlNumber],[ControlID],[IdNumber],[ReceiverNumber],[ReceivedDate],[IsSerialized],[SerialNumber],[Quantity],[QuantityRejected],[QuantityOnHand],[CurrencyId],[Currency],[ConditionId],
							[Condition],[GLAccountId],[GLAccount],[UnitOfMeasureId],[UnitOfMeasure],[ManufacturerId],[Manufacturer],[MfgExpirationDate],[UnitCost],[ExtendedCost],[Acquired],[IsHazardousMaterial],[ItemNonStockClassificationId],
							[NonStockClassification],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[ShelfId],[Shelf],[BinId],[Bin],[ShippingViaId],[ShippingVia],[ShippingAccount],[ShippingReference],
							[IsSameDetailsForAllParts],[VendorId],[VendorName],[RequisitionerId],[Requisitioner],[OrderDate],[EntryDate],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],
							[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RRQty]
							FROM tempNonStockInventory

                            SET @NewNonStockInventoryId = SCOPE_IDENTITY();
                            EXEC USP_CreateStocklinePartHistory @NewNonStockInventoryId, 1, 0, 0, 0

                            SELECT @MSId = MasterCompanyId,
                                   @NonStockMasterPartId = MasterPartId,
                                   @NonStockManufacturerId = ManufacturerId,
                                   @ManagementStructureID_NonStock = ManagementStructureId
                            FROM NonStockInventory
                            WHERE NonStockInventoryId = @NewNonStockInventoryId;

                            IF (ISNULL(@CurrentIdNumber_NonStock, 0) <> 0)
                            BEGIN
                                DECLARE @temp table
                                (
                                    ItemMasterId bigint null,
                                    ManufacturerId bigint null,
                                    StockLineNumber varchar(255) null,
                                    CurrentStlNo bigint null,
                                    isSerialized bit null
                                );

                                INSERT @temp EXEC GetNonStockPNManufacturerCombinationCreated @MSId;
                                SELECT * FROM @temp;

                                ;WITH tempItemMasterNonStock (ItemMasterId, ManufacturerId, StockLineNumber, CurrentStlNo, isSerialized)
                                AS (SELECT ItemMasterId, ManufacturerId, StockLineNumber, CurrentStlNo, isSerialized FROM @temp
                                    WHERE ItemMasterId = @NonStockMasterPartId AND ManufacturerId = @NonStockManufacturerId)
                                SELECT @CurrentStlNumber = CurrentStlNo FROM tempItemMasterNonStock

                                SET @NonStockCurrentNo = CASE WHEN ISNULL(@CurrentStlNumber, 0) = 0 THEN 1 ELSE @CurrentStlNumber + 1 END;

                                UPDATE #tmpCodePrefixes_NonStock SET CurrentNumber = @NonStockCurrentNo WHERE CodeTypeId = 66;

                                SELECT @CodePrefix_NonStock = CodePrefix, @CodeSuffix_NonStock = CodeSufix
                                FROM #tmpCodePrefixes_NonStock WHERE CodeTypeId = 66;

                                SET @NonStockInventoryNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@NonStockCurrentNo, @CodePrefix_NonStock, @CodeSuffix_NonStock))

                                UPDATE ItemMasterNonStock
                                SET CurrentStlNo = @NonStockCurrentNo,
                                    UpdatedDate = GETUTCDATE(),
                                    UpdatedBy = @UpdatedBy
                                WHERE MasterPartId = @NonStockMasterPartId AND ManufacturerId = @NonStockManufacturerId
                            END

                            SELECT @NonStockCurrentNumber = CurrentNumber,
                                   @CodeSuffix_NonStock = CodeSufix,
                                   @CodePrefix_NonStock = CodePrefix
                            FROM #tmpCodePrefixes_NonStock WHERE CodeTypeId = 68
                            
							IF (ISNULL(@NonStockCurrentNumber, 0) <> 0)
                            BEGIN
                                UPDATE CodePrefixes
                                SET CurrentNummber = @NonStockCurrentNumber + 1
                                WHERE CodeTypeId = 68 AND MasterCompanyId = @MSId
                                SET @NonStockCurrentNumber = @NonStockCurrentNumber + 1;
                                SET @NonStockControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@NonStockCurrentNumber, @CodePrefix_NonStock, @CodeSuffix_NonStock))
                            END

                            UPDATE NonStockInventory
                            SET NonStockInventoryNumber = @NonStockInventoryNumber,
                                ReceiverNumber = @ReceiverNumber_NonStock,
                                ControlNumber = @NonStockControlNumber,
                                RRQty = Quantity,
                                CreatedBy = CASE WHEN ISNULL(CreatedBy, '') = '' THEN @UpdatedBy ELSE CreatedBy END,
                                UpdatedBy = CASE WHEN ISNULL(UpdatedBy, '') = '' THEN @UpdatedBy ELSE UpdatedBy END,
                                ParentId = @ParentNonStockId
                            WHERE NonStockInventoryId = @NewNonStockInventoryId;

                            EXEC dbo.[USP_SaveNonSLMSDetails] @MSModuleId_NonStock, @NewNonStockInventoryId, @ManagementStructureID_NonStock, @MSId, @UpdatedBy;

							SELECT @SelectedIsSameDetailsForAllParts = IsSameDetailsForAllParts FROM #tmpNonStockInventoryDraft WHERE NonStockInventoryDraftId = @TempNonStockId;

							PRINT '@IsSerializedPart';
							PRINT @IsSerializedPart;
							PRINT '@SelectedIsSameDetailsForAllParts';
							PRINT @SelectedIsSameDetailsForAllParts;

							IF (@IsSerializedPart = 0 AND @SelectedIsSameDetailsForAllParts = 1)
							BEGIN
								DECLARE @LoopID_QtyToReceive_NS INT = 0;

								IF OBJECT_ID(N'tempdb..#NonStocklineDraftForQtyToReceive') IS NOT NULL
								BEGIN
									DROP TABLE #NonStocklineDraftForQtyToReceive
								END

								CREATE TABLE #NonStocklineDraftForQtyToReceive
								(
									ID BIGINT NOT NULL IDENTITY,
									[NonStockInventoryDraftId] [bigint] NULL
								)

								INSERT INTO #NonStocklineDraftForQtyToReceive
								(
									[NonStockInventoryDraftId]
								)
								SELECT [NonStockInventoryDraftId]
								FROM DBO.NonStockInventoryDraft WITH (NOLOCK)
								WHERE PurchaseOrderId = @PurchaseOrderId
										AND PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId
										AND IsParent = 0
										AND isSerialized = 0
										AND IsSameDetailsForAllParts = 1
										AND NonStockInventoryId IS NULL
								ORDER BY NonStockInventoryDraftId DESC;

								SELECT @LoopID_QtyToReceive_NS = MAX(ID) FROM #NonStocklineDraftForQtyToReceive;

								DECLARE @TotalQtyToTraverse_NS INT = 0;

								SET @TotalQtyToTraverse_NS = @QtyToReceive;

								WHILE (@LoopID_QtyToReceive_NS > 0)
								BEGIN
									IF (@TotalQtyToTraverse_NS > 0)
									BEGIN
										DECLARE @CurrentNonStocklineDraftId BIGINT = 0;

										SELECT @CurrentNonStocklineDraftId = NonStockInventoryDraftId
										FROM #NonStocklineDraftForQtyToReceive
										WHERE ID = @LoopID_QtyToReceive_NS;

										UPDATE NonStockInventoryDraft
										SET NonStockInventoryId = @NewNonStockInventoryId,
											NonStockInventoryNumber = @NonStockInventoryNumber
										WHERE NonStockInventoryDraftId = @CurrentNonStocklineDraftId;

										SET @TotalQtyToTraverse_NS = @TotalQtyToTraverse_NS - 1;
									END

									SET @LoopID_QtyToReceive_NS = @LoopID_QtyToReceive_NS - 1;
								END

								IF ((@MainPOPartBackOrderQty - @QtyToReceive) > 0)
								BEGIN
									SET @NonStockInventoryNumber = NULL;
									SET @NewNonStockInventoryId = NULL;
								END

								UPDATE dstl
								SET dstl.NonStockInventoryId = @NewNonStockInventoryId,
									dstl.NonStockInventoryNumber = @NonStockInventoryNumber,
									dstl.ControlNumber = @ControlNumber,
									dstl.ReceiverNumber = @ReceiverNumber
								FROM DBO.NonStockInventoryDraft dstl
								WHERE NonStockInventoryDraftId = @TempNonStockId;

								UPDATE DBO.NonStockInventoryDraft
								SET NonStockInventoryId = 0
								WHERE NonStockInventoryDraftId = @TempNonStockId
										AND isSerialized = 0
										AND IsSameDetailsForAllParts = 1
										AND IsParent = 1;
							END
							ELSE
							BEGIN
								PRINT 'NonStock Update ELSE'
								PRINT @NonStockInventoryNumber;
								PRINT '@TempNonStockId';
								PRINT @TempNonStockId;

								UPDATE dstl
								SET dstl.NonStockInventoryId = @NewNonStockInventoryId,
									dstl.NonStockInventoryNumber = @NonStockInventoryNumber,
									dstl.ControlNumber = @ControlNumber,
									dstl.ReceiverNumber = @ReceiverNumber
								FROM DBO.NonStockInventoryDraft dstl
								WHERE NonStockInventoryDraftId = @TempNonStockId;
							END

                            SET @StartNonStock = @StartNonStock + 1;
                        END

						UPDATE Stk
						SET Stk.IsParent = CASE WHEN Stk.IsParent = 1 THEN 0 ELSE 1 END
						FROM DBO.NonStockInventoryDraft Stk WHERE Stk.IsSameDetailsForAllParts = 0 AND Stk.isSerialized = 0 AND Stk.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;
                    END
                END

                DECLARE @StocklineDraftToUpdateLoopID INT = 0;

                IF OBJECT_ID(N'tempdb..#StocklineDraftToUpdate') IS NOT NULL
                BEGIN
                    DROP TABLE #StocklineDraftToUpdate
                END

                CREATE TABLE #StocklineDraftToUpdate
                (
                    ID BIGINT NOT NULL IDENTITY,
                    [StocklineDraftId] [bigint] NULL
                )

                INSERT INTO #StocklineDraftToUpdate ([StocklineDraftId])
                SELECT [StocklineDraftId] FROM DBO.StocklineDraft WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;

                SELECT @StocklineDraftToUpdateLoopID = MAX(ID) FROM #StocklineDraftToUpdate;

                WHILE (@StocklineDraftToUpdateLoopID > 0)
                BEGIN
                    DECLARE @StocklineDraftSelected BIGINT = 0;
                    DECLARE @IsParentSelected BIGINT = 0;
                    DECLARE @IsSerializedSelected BIGINT = 0;
                    DECLARE @SelectedStocklineId BIGINT = 0;
                    DECLARE @CurrentIsSameDetailsForAllParts BIGINT = 0;

                    SELECT @StocklineDraftSelected = [StocklineDraftId] FROM #StocklineDraftToUpdate WHERE ID = @StocklineDraftToUpdateLoopID;

                    SELECT @IsParentSelected = dstl.IsParent,
                           @IsSerializedSelected = dstl.isSerialized,
                           @SelectedStocklineId = ISNULL(dstl.StockLineId, 0),
                           @CurrentIsSameDetailsForAllParts = dstl.IsSameDetailsForAllParts
                    FROM DBO.StocklineDraft dstl
                    WHERE dstl.StockLineDraftId = @StocklineDraftSelected;

                    IF (@CurrentIsSameDetailsForAllParts = 0 AND @IsParentSelected = 0 AND @IsSerializedSelected = 0 AND @SelectedStocklineId = 0)
                    BEGIN
                        UPDATE dstl SET dstl.IsParent = 1, IsSameDetailsForAllParts = 1
                        FROM DBO.StocklineDraft dstl WHERE dstl.StockLineDraftId = @StocklineDraftSelected;
                    END
                    ELSE IF (@CurrentIsSameDetailsForAllParts = 0 AND @IsParentSelected = 1 AND @IsSerializedSelected = 0 AND @SelectedStocklineId = 0)
                    BEGIN
                        UPDATE dstl SET dstl.IsParent = 0, IsSameDetailsForAllParts = 1
                        FROM DBO.StocklineDraft dstl WHERE dstl.StockLineDraftId = @StocklineDraftSelected;
                    END

                    SET @StocklineDraftToUpdateLoopID = @StocklineDraftToUpdateLoopID - 1;
                END

                SET @MainPartLoopID = @MainPartLoopID - 1;
            END

            EXEC DBO.UpdateStocklineDraftDetail @PurchaseOrderId;
            EXEC DBO.UpdateAssetInventoryDraftPoDetails @PurchaseOrderId;
            EXEC DBO.UpdateNonStockDraftDetail @PurchaseOrderId;

            DECLARE @POPartLoopID AS INT;

            IF OBJECT_ID(N'tempdb..#POParts') IS NOT NULL
            BEGIN
                DROP TABLE #POParts
            END

            CREATE TABLE #POParts
            (
                ID BIGINT NOT NULL IDENTITY,
                [PurchaseOrderId] [bigint] NULL,
                [PurchaseOrderPartRecordId] [bigint] NULL,
                [QuantityOrdered] [int] NULL
            )

            INSERT INTO #POParts ([PurchaseOrderId], [PurchaseOrderPartRecordId], [QuantityOrdered])
            SELECT [PurchaseOrderId], [PurchaseOrderPartRecordId], [QuantityOrdered] FROM DBO.PurchaseOrderPart WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId;

            SELECT @POPartLoopID = MAX(ID) FROM #POParts;

            DECLARE @MainQuantityOrdered BIGINT = 0;
            DECLARE @MainStkQuantity BIGINT = 0;

            WHILE (@POPartLoopID > 0)
            BEGIN
                DECLARE @PurchaseOrderPartRecordId BIGINT = 0;
                DECLARE @QuantityOrdered BIGINT = 0;
                DECLARE @StkQuantity BIGINT = 0;
                DECLARE @StkAssetQuantity BIGINT = 0;
                DECLARE @NonStkInventoryQuantity BIGINT = 0;

                SELECT @QuantityOrdered = [QuantityOrdered], @PurchaseOrderPartRecordId = [PurchaseOrderPartRecordId] FROM #POParts WHERE ID = @POPartLoopID;

                SELECT @StkQuantity = ISNULL(SUM([Quantity]), 0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND IsParent = 1;
                
				SELECT @StkAssetQuantity = ISNULL(SUM(Qty), 0) FROM DBO.AssetInventory Stk WITH (NOLOCK) WHERE Stk.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId;

				SELECT @NonStkInventoryQuantity = ISNULL(SUM(Quantity), 0) FROM DBO.NonStockInventory NonStk WITH (NOLOCK) WHERE NonStk.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId;

                SET @MainQuantityOrdered = @MainQuantityOrdered + @QuantityOrdered;
                SET @MainStkQuantity = @MainStkQuantity + @StkQuantity;
                SET @MainStkQuantity = @MainStkQuantity + @StkAssetQuantity;
                SET @MainStkQuantity = @MainStkQuantity + @NonStkInventoryQuantity;

                SET @POPartLoopID = @POPartLoopID - 1;
            END

            IF (@MainQuantityOrdered = @MainStkQuantity)
            BEGIN
                UPDATE PO
                SET PO.StatusId = 4, -- Closed  
                    PO.Status = 'Closed',
                    PO.ClosedDate = GETUTCDATE()
                FROM DBO.PurchaseOrder PO
                WHERE PO.PurchaseOrderId = @PurchaseOrderId
            END
            ELSE
            BEGIN
                UPDATE PO
                SET PO.StatusId = 3, -- Fulfilling  
                    PO.Status = 'Fulfilling',
                    PO.ClosedDate = GETUTCDATE()
                FROM DBO.PurchaseOrder PO
                WHERE PO.PurchaseOrderId = @PurchaseOrderId
            END

            DECLARE @IsAutoReserveReceivedStockline BIT = 0;
            SELECT @IsAutoReserveReceivedStockline = ISNULL(POS.IsAutoReserveReceivedStockline, 0)
            FROM [dbo].[PurchaseOrderSettingMaster] POS WITH (NOLOCK)
            WHERE POS.MasterCompanyId = @MasterCompanyId;

            IF (@IsAutoReserveReceivedStockline = 1)
            BEGIN
                DECLARE @SelectedPartsToReserve VARCHAR(500) = '';

                SELECT @SelectedPartsToReserve = STUFF((SELECT ',' + CAST(POPR.PurchaseOrderPartReferenceId AS VARCHAR(100))
                          FROM DBO.PurchaseOrderPartReference POPR WITH (NOLOCK)
                          WHERE POPR.PurchaseOrderId = @PurchaseOrderId
                          ORDER BY POPR.PurchaseOrderPartReferenceId
                          FOR XML PATH('')), 1, 1, '');

                EXEC DBO.USP_ReserveStocklineForReceivingPO @PurchaseOrderId = @PurchaseOrderId, @SelectedPartsToReserve = @SelectedPartsToReserve, @UpdatedBy = @UpdatedBy;
            END

            SELECT * FROM #InsertedStkForLot
        END
        
		COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            ROLLBACK TRAN;
        SELECT ERROR_NUMBER() AS ErrorNumber,
               ERROR_STATE() AS ErrorState,
               ERROR_SEVERITY() AS ErrorSeverity,
               ERROR_PROCEDURE() AS ErrorProcedure,
               ERROR_LINE() AS ErrorLine,
               ERROR_MESSAGE() AS ErrorMessage;
        DECLARE @ErrorLogID int,
                @DatabaseName varchar(100) = DB_NAME(),
                -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------    
                @AdhocComments varchar(150) = 'USP_CreateStocklineForReceivingPO',
                @ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@PurchaseOrderId, '') + '',
                @ApplicationName varchar(100) = 'PAS'
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
        EXEC spLogException @DatabaseName = @DatabaseName,
                            @AdhocComments = @AdhocComments,
                            @ProcedureParameters = @ProcedureParameters,
                            @ApplicationName = @ApplicationName,
                            @ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN (1);
    END CATCH
END