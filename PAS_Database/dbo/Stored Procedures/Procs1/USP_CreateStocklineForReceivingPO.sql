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
	7    05-07-2024   Moin Bloch        Modified the SP to set RRQty  PN-8032
	8    15-07-2024   Devendra Shekh    Modified For Account BatchDetail Entry
	9	 26-07-2024   Bhargav Saliya    Fixed Calculation of UnitSalesPrice In [ItemMasterPurchaseSale] When We Create Receving PO Stockline
	10	 05-08-2024   Devendra Shekh    Non-Stock, Accounting Entry Issue Resolved
	11   11-10-2024	  Ekta Chandegra    Add history when update Part
	12   23-10-2024	  Rajesh Gami       Add new field in StocklineDraft Table (IsKitType, IsSubWOType), And manage NULL value 
	13   20-12-2024   Moin Bloch        Fixed Asset Inventory Partial Receive issue
    14   17-JAN-2025  RAJESH GAMI       Fixed Asset Inventory to insert RRQty by default as 1 instead of 0
	15   07/01/2025   Ayushi Patel      cast PP_LastPurchaseDiscDate dateTime into Date
	16   18-MAR-2025  HEMANT SALIYA     Updated DB Standards
	17   10-APR-2025  Moin Bloch        Updated [QuantityReceived] in [PurchaseOrderPart] Table
	18   18-APR-2025  Abhishek Jirawla  Added Integration Portal in Stockline
	19   05-MAY-2025  Abhishek Jirawla  Added ObtainFrom in Stockline
	20   16-JUL-2025  Moin Bloch        Modified ObtainFromType As NULL when it comes 0
	21   01-DEC-2025  Rajesh Gami       UOM Conversion Related Changes
	22   03-Dec-2025  Moin Bloch        Modified Fix Status Closed For Split Part
	23   04-Dec-2025  Moin Bloch        Modified Fix For Asset Inverntory
    24   19-Dec-2025  HEMANT SALIYA     Modified for remove corss join
	25   07/01/2026   Rajesh Gami		Added MasterCompanyId Parameter While Calling UOM Conversion Function
	26   06/03/2026   Bhargav Saliya	PN-15667[When we add a flat price, there is no need to Sum @PP_UnitPurchasePrice + @PP_FlatPrice] 
	27   26-MAr-2026  Moin Bloch        Modified Fix Issue For Close PO When SO Shipped Partial Stockline Qty
	28   10-APR-2026  Rajesh Gami		UOM Conversion Changes [PN-15733]
	29   21-APR-2026  Rajesh Gami		UOM Conversion Issue Resolved [PN-16133]
	30   27-APR-2026  Priyansh patel 	Updated Aircraftpartdetails with New StocklineId [PN-16177]
	31   04-May-2026  RAJESH GAMI       Insert Stock,NonStock,Asset InventoryId In the DRAFT Table when Order QTY more than 500 (Where IsParent = 1) [PN-16244]
	32   20-May-2026  Amit Ghediya  	Updated Aircraftpartdetails with New StocklineId for part wise not header wise [PN-16232]
    33	 19/06/2026	  Ayushi			[PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
    34	 30/06/2026	  Priyansh Patel	Reduced @maxQtyLimit from 499 to 0 [PN-16893]
	35    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	36    16/July/2026			 RAJESH GAMI						[PN-17271] - Non-Stock parts now received into DBO.Stockline (IsNonStock=1) from DBO.StocklineDraft instead of legacy NonStockInventory/NonStockInventoryDraft tables.
    37   06/08/2026   Priyansh Patel    Added the removed code  [PN-17271]
	38    13/Aug/2026   RAJESH GAMI       [PN-17008] - Re-added missing ISNULL(im.IsNonStock,0) = 0 filter on the #tmpPNManufacturer (STOCK) rebuild query's ItemMaster JOIN; the query was independently rewritten (LastStockline CTE) after the BETA port and the rewrite dropped the filter that the twin NS-suffixed block still has.
declare @p2 dbo.POPartsToReceive  insert into @p2 values(2371,4051,2)
exec dbo.USP_CreateStocklineForReceivingPO @PurchaseOrderId=2371,@tbl_POPartsToReceive=@p2,@UpdatedBy=N'ADMIN User',@MasterCompanyId=1  
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_CreateStocklineForReceivingPO]
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
			DECLARE @StkCount INT = 0;
			DECLARE @AstInvCount INT = 0;
			DECLARE @NonStkCount INT = 0;
			DECLARE @p2 dbo.PostStocklineBatchType;
			DECLARE @p3 dbo.PostStocklineBatchType;
			DECLARE @p4 dbo.PostStocklineBatchType;
			DECLARE @maxQtyLimit INT = 0
            IF OBJECT_ID(N'tempdb..#POPartsToReceive') IS NOT NULL
            BEGIN
                DROP TABLE #POPartsToReceive
            END

            CREATE TABLE #POPartsToReceive
            (
                ID BIGINT NOT NULL IDENTITY,
                [PurchaseOrderId] [bigint] NULL,
                [PurchaseOrderPartRecordId] [bigint] NULL,
                [QtyToReceive] [decimal](18,6) NULL
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
                DECLARE @QtyToReceive  DECIMAL(18,6);
                DECLARE @MainPOPartBackOrderQty INT;
                DECLARE @ItemTypeId INT;
				DECLARE @PurchaseUnitOfMeasureId BIGINT = 0,  @StockUnitOfMeasureId BIGINT = 0,@ConsumeUnitOfMeasureId BIGINT = 0, @QtyToReceiveAfterConversion DECIMAL(18,6) =0, @QtyAfterConversion DECIMAL(18,6)  =0;
				DECLARE @POUnitOfMeasure VARCHAR(100),  @StockUnitOfMeasure VARCHAR(100),@ConsumeUnitOfMeasure VARCHAR(100), @DraftQty DECIMAL(18,6) =0, @DraftUnitCost DECIMAL(18,6) =0, @UnitCostAfterConversion DECIMAL(18,6) =0;

                SELECT @SelectedPurchaseOrderPartRecordId = [PurchaseOrderPartRecordId],
                       @QtyToReceive = [QtyToReceive]
                FROM #POPartsToReceive
                WHERE ID = @MainPartLoopID;

                SELECT @ItemMasterId_Part = POP.ItemMasterId,
                       @MainPOPartBackOrderQty = POP.QuantityBackOrdered,
                       @ItemTypeId = ItemTypeId
                FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
                WHERE POP.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;

				SELECT @PurchaseUnitOfMeasureId = IM.PurchaseUnitOfMeasureId,@StockUnitOfMeasureId =StockUnitOfMeasureId, @ConsumeUnitOfMeasureId = ConsumeUnitOfMeasureId FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId = @ItemMasterId_Part;
				SET @POUnitOfMeasure = (SELECT ShortName FROM DBO.UnitOfMeasure WITH(NOLOCK) WHERE UnitOfMeasureId = @PurchaseUnitOfMeasureId)
				SET @StockUnitOfMeasure = (SELECT ShortName FROM DBO.UnitOfMeasure WITH(NOLOCK) WHERE UnitOfMeasureId = @StockUnitOfMeasureId)
				SET @ConsumeUnitOfMeasure = (SELECT ShortName FROM DBO.UnitOfMeasure WITH(NOLOCK) WHERE UnitOfMeasureId = @ConsumeUnitOfMeasureId)
                IF (@ItemTypeId = 1)
                BEGIN
                    SELECT @IsSerializedPart = IM.isSerialized FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId = @ItemMasterId_Part AND ISNULL(IM.IsNonStock,0) = 0 ;

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
                        [Quantity] [decimal](18,6) NOT NULL,
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
                        [PurchaseOrderUnitCost] DECIMAL(18,6) NULL,
                        [InventoryUnitCost] DECIMAL(18,6) NULL,
                        [RepairOrderId] [bigint] NULL,
                        [RepairOrderUnitCost] DECIMAL(18,6) NULL,
                        [ReceivedDate] [datetime2](7) NULL,
                        [ReceiverNumber] [varchar](50) NULL,
                        [ReconciliationNumber] [varchar](50) NULL,
                        [UnitSalesPrice] DECIMAL(18,6) NULL,
                        [CoreUnitCost] DECIMAL(18,6) NULL,
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
                        [QuantityToReceive] [decimal](18,6) NOT NULL,
                        [PurchaseOrderExtendedCost] DECIMAL(18,6) NOT NULL,
                        [ManufacturingTrace] [nvarchar](200) NULL,
                        [ExpirationDate] [datetime2](7) NULL,
                        [AircraftTailNumber] [nvarchar](200) NULL,
                        [ShippingViaId] [bigint] NULL,
                        [EngineSerialNumber] [nvarchar](200) NULL,
                        [QuantityRejected] [decimal](18,6) NOT NULL,
                        [PurchaseOrderPartRecordId] [bigint] NULL,
                        [ShippingAccount] [nvarchar](200) NULL,
                        [ShippingReference] [nvarchar](200) NULL,
                        [TimeLifeCyclesId] [bigint] NULL,
                        [TimeLifeDetailsNotProvided] [bit] NOT NULL,
                        [WorkOrderId] [bigint] NULL,
                        [WorkOrderMaterialsId] [bigint] NULL,
                        [QuantityReserved] [decimal](18,6) NULL,
                        [QuantityTurnIn] [decimal](18,6) NULL,
                        [QuantityIssued] [decimal](18,6) NULL,
                        [QuantityOnHand] [decimal](18,6) NULL,
                        [QuantityAvailable] [decimal](18,6) NULL,
                        [QuantityOnOrder] [decimal](18,6) NULL,
                        [QtyReserved] [decimal](18,6) NULL,
                        [QtyIssued] [decimal](18,6) NULL,
                        [BlackListed] [bit] NOT NULL,
                        [BlackListedReason] [varchar](500) NULL,
                        [Incident] [bit] NOT NULL,
                        [IncidentReason] [varchar](500) NULL,
                        [Accident] [bit] NOT NULL,
                        [AccidentReason] [varchar](500) NULL,
                        [RepairOrderPartRecordId] [bigint] NULL,
                        [isActive] [bit] NOT NULL,
                        [isDeleted] [bit] NOT NULL,
                        [WorkOrderExtendedCost] DECIMAL(18,6) NOT NULL,
                        [RepairOrderExtendedCost] DECIMAL(18,6) NULL,
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
                        [WOQty] [decimal](18,6) NULL,
                        [SOQty] [decimal](18,6) NULL,
                        [ForStockQty] [decimal](18,6) NULL,
                        [IsLotAssigned] [bit] NULL,
                        [LOTQty] [decimal](18,6) NULL,
                        [LOTQtyReserve] [decimal](18,6) NULL,
                        [OriginalCost] DECIMAL(18,6) NULL,
                        [POOriginalCost] DECIMAL(18,6) NULL,
                        [ROOriginalCost] DECIMAL(18,6) NULL,
                        [VendorRMAId] [bigint] NULL,
                        [VendorRMADetailId] [bigint] NULL,
                        [LotMainStocklineId] [bigint] NULL,
                        [IsFromInitialPO] [bit] NULL,
                        [LotSourceId] [int] NULL,
                        [Adjustment] DECIMAL(18,6) NULL,
                        [SerialNumberNotProvided] [bit] NULL,
                        [ShippingReferenceNumberNotProvided] [bit] NULL,
                        [IsStkTimeLife] [bit] NULL,
						[IsKitType] [bit] NULL,
						[IsSubWOType] [bit] NULL
						
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
					IsFromInitialPO,LotSourceId,Adjustment,SerialNumberNotProvided,ShippingReferenceNumberNotProvided,IsStkTimeLife,IsKitType,IsSubWOType
					FROM DBO.StocklineDraft StkDraft WITH (NOLOCK)
                    WHERE StkDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND ISNULL(IsParent, 0) = 1 AND StockLineNumber IS NULL
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
                        WHERE ISNULL(IsParent, 0) = 1 AND StkDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;
						PRINT @IsSameDetailsForAllParts
						PRINT '@IsSameDetailsForAllParts'
                        IF (@IsSameDetailsForAllParts = 0)
                        BEGIN
							DECLARE @IntegerPart INT = FLOOR(@QtyToReceive);
							DECLARE @DecimalPart DECIMAL(18,6) = @QtyToReceive - @IntegerPart;
							SET @LoopID = @IntegerPart + CASE WHEN @DecimalPart > 0 THEN 1 ELSE 0 END;
							PRINT '@IsSameDetailsForAllParts = 0 LoopId'
							PRINT @LoopID
                        END
                        ELSE
                        BEGIN
                            SELECT @LoopID = MAX(ID) FROM #tmpStocklineDraft;
								PRINT 'Direct LoopId LoopId'
							PRINT @LoopID
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
                        DECLARE @StkPurchaseOrderUnitCost AS DECIMAL(18,6) = 0;
                        DECLARE @ManufacturerId AS BIGINT;
                        DECLARE @PreviousStockLineNumber VARCHAR(50);
                        DECLARE @AircraftInstalledPartDetailsId BIGINT = NULL;


                        SELECT @SelectedStockLineDraftId = StockLineDraftId FROM #tmpStocklineDraft WHERE ID = @LoopID;

                        SELECT @PORequestorId = RequestedBy, @POVendorId = VendorId FROM DBO.PurchaseOrder WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId;

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
                       IF OBJECT_ID('tempdb..#tmpPNManufacturer') IS NOT NULL DROP TABLE #tmpPNManufacturer;

                        CREATE TABLE #tmpPNManufacturer
                        (
                            ID BIGINT NOT NULL IDENTITY,
                            ItemMasterId BIGINT NULL,
                            ManufacturerId BIGINT NULL,
                            StockLineNumber VARCHAR(100) NULL,
                            CurrentStlNo BIGINT NULL,
                            isSerialized BIT NULL
                        );

                        ;WITH LastStockline AS
                        (
                          SELECT
                            s.ItemMasterId,
                            s.ManufacturerId,
                            MAX(s.StockLineId) AS StockLineId
                          FROM dbo.Stockline s WITH (NOLOCK)
                          WHERE s.MasterCompanyId = @MasterCompanyId
                          GROUP BY s.ItemMasterId, s.ManufacturerId
                        )
                        INSERT INTO #tmpPNManufacturer (ItemMasterId, ManufacturerId, StockLineNumber, CurrentStlNo, isSerialized)
                        SELECT
                          ls.ItemMasterId,
                          ls.ManufacturerId,
                          st.StockLineNumber,
                          ISNULL(im.CurrentStlNo, 0),
                          im.isSerialized
                        FROM LastStockline ls
                        JOIN dbo.Stockline st WITH (NOLOCK) ON st.StockLineId = ls.StockLineId
                        JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = ls.ItemMasterId AND im.ManufacturerId = ls.ManufacturerId AND ISNULL(im.IsNonStock,0) = 0;

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
						JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
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

						DECLARE @IntegrationPortal VARCHAR(50)

						SELECT
							@IntegrationPortal = STRING_AGG(CAST(mp.IntegrationPortalId AS VARCHAR), ',')
						FROM dbo.ItemMaster iM WITH(NOLOCK)
						LEFT JOIN dbo.ItemMasterIntegrationPortal mp WITH(NOLOCK) ON iM.ItemMasterId = mp.ItemMasterId
						LEFT JOIN dbo.IntegrationPortal ip WITH(NOLOCK) ON mp.IntegrationPortalId = ip.IntegrationPortalId
						WHERE iM.ItemMasterId = @ItemMasterId AND iM.MasterCompanyId = @MasterCompanyId AND mp.IntegrationPortalId IS NOT NULL
						 AND ISNULL(iM.IsNonStock,0) = 0
						GROUP BY iM.ItemMasterId
						
						SET @QtyToReceiveAfterConversion = ISNULL(@QtyToReceive,0);

                         SELECT @DraftQty = Quantity,
                               @DraftUnitCost = PurchaseOrderUnitCost
                        FROM #tmpStocklineDraft
                        WHERE StockLineDraftId = @SelectedStockLineDraftId;


                        SET @QtyAfterConversion = ISNULL(@DraftQty,0);
                        SET @UnitCostAfterConversion = ISNULL(@DraftUnitCost,0);

                        IF (ISNULL(@POUnitOfMeasure,'') <> ISNULL(@StockUnitOfMeasure,''))
                        BEGIN
                            SET @QtyToReceiveAfterConversion = dbo.fn_ConvertUOM(@QtyToReceive, @POUnitOfMeasure, @StockUnitOfMeasure, 0, @MasterCompanyId);
                            SET @QtyAfterConversion = dbo.fn_ConvertUOM(@DraftQty, @POUnitOfMeasure, @StockUnitOfMeasure, 0, @MasterCompanyId);
                            SET @UnitCostAfterConversion = dbo.fn_ConvertUOM(@DraftUnitCost, @POUnitOfMeasure, @StockUnitOfMeasure, 1, @MasterCompanyId);
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
						[OriginalCost],[POOriginalCost],[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment],[IsStkTimeLife], [IntegrationPortal],PoPartUnitCost,
						StockUnitOfMeasureId,StockUnitOfMeasure,ConsumeUnitOfMeasureId,ConsumeUnitOfMeasure)

                        SELECT [PartNumber],@StockLineNumber,[StocklineMatchKey],@ControlNumber,[ItemMasterId],CASE WHEN @IsSerializedPart = 1 THEN @QtyAfterConversion ELSE 
							CASE WHEN IsSameDetailsForAllParts = 0 THEN @QtyAfterConversion ELSE @QtyToReceiveAfterConversion END END,[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],
						[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber],
						[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],@UnitCostAfterConversion,[InventoryUnitCost],[RepairOrderId],
						ISNULL([RepairOrderUnitCost], 0),GETUTCDATE(),@ReceiverNumber,[ReconciliationNumber],ISNULL([UnitSalesPrice], 0),ISNULL([CoreUnitCost], 0),[GLAccountId],[AssetId],[IsHazardousMaterial],
						[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureEntityId],[LegalEntityId],[MasterCompanyId],@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),[isSerialized],[ShelfId],[BinId],[SiteId],
						CASE WHEN [ObtainFromType] = 0 THEN NULL ELSE [ObtainFromType] END,[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],
						[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],
						[WorkOrderId],CASE WHEN [WorkOrderMaterialsId] = 0 THEN NULL ELSE[WorkOrderMaterialsId]END,ISNULL([QuantityReserved], 0),ISNULL([QuantityTurnIn], 0),ISNULL([QuantityIssued], 0),CASE WHEN @IsSerializedPart = 1 THEN @QtyAfterConversion ELSE 
							CASE WHEN IsSameDetailsForAllParts = 0 THEN @QtyAfterConversion ELSE @QtyToReceiveAfterConversion END END,
						CASE WHEN @IsSerializedPart = 1 THEN @QtyAfterConversion 
							ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN @QtyAfterConversion ELSE @QtyToReceiveAfterConversion END END,
						ISNULL([QuantityOnOrder], 0),ISNULL([QtyReserved], 0),ISNULL([QtyIssued], 0),[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],
						[isActive],[isDeleted],[WorkOrderExtendedCost],ISNULL([RepairOrderExtendedCost], 0),[IsCustomerStock],GETUTCDATE(),0,[NHAItemMasterId],[TLAItemMasterId],NULL,NULL,@PORequestorId,NULL,NULL,
						NULL,NULL,NULL,@POVendorId,[IsParent],[ParentId],[IsSameDetailsForAllParts],0,[SubWorkOrderId],0,NULL,[UnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],
						[Level3],[Level4],[Condition],NULL,NULL,[Warehouse],[Location],NULL,NULL,[UnitOfMeasure],NULL,NULL,NULL,NULL,NULL,NULL,NULL,[CustomerId],NULL,ISNULL([isCustomerstockType], 0),'',NULL,NULL,
						NULL,[TaggedBy],[TaggedByName],@UnitCostAfterConversion,[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],
						[CertifiedType],[CertTypeId],[CertType],[TagTypeId],0,0,NULL,NULL,NULL,NULL,NULL,NULL,[ExchangeSalesOrderId],CASE WHEN @IsSerializedPart = 1 THEN @QtyAfterConversion ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN @QtyAfterConversion ELSE @QtyToReceiveAfterConversion END END,NULL,1,NULL,
						[LotId],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost],[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],ISNULL(Adjustment, 0),[IsStkTimeLife], ISNULL(@IntegrationPortal, ''),@DraftUnitCost,
						@StockUnitOfMeasureId,@StockUnitOfMeasure,@ConsumeUnitOfMeasureId,@ConsumeUnitOfMeasure
                        FROM #tmpStocklineDraft
                        WHERE StockLineDraftId = @SelectedStockLineDraftId;

                        DECLARE @QtyAdded DECIMAL(18,6) = 0,@QtyOnAction DECIMAL(18,6) = 0;
                        DECLARE @PurchaseOrderUnitCostAdded DECIMAL(18,6) = 0;
                        DECLARE @SelectedIsSameDetailsForAllParts BIT = 0;
                        DECLARE @IsTimeLIfe BIT

                        SELECT @QtyAdded = CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN ISNULL(IsSameDetailsForAllParts,0) = 0 THEN [Quantity] ELSE @QtyToReceive END END,
							 @QtyOnAction = CASE WHEN @IsSerializedPart = 1 THEN @QtyAfterConversion ELSE CASE WHEN ISNULL(IsSameDetailsForAllParts,0) = 0 THEN @QtyAfterConversion ELSE @QtyToReceiveAfterConversion END END,
                               @SelectedIsSameDetailsForAllParts = IsSameDetailsForAllParts,
                               @PurchaseOrderUnitCostAdded = PurchaseOrderUnitCost,
                               @IsTimeLIfe = [IsStkTimeLife]
                        FROM #tmpStocklineDraft WHERE StockLineDraftId = @SelectedStockLineDraftId;

                        SELECT @NewStocklineId = SCOPE_IDENTITY();


                        INSERT INTO #InsertedStkForLot (StockLineId)
                        SELECT @NewStocklineId  

                        -- For Aircraftinstalled Parts
                        SET @AircraftInstalledPartDetailsId = NULL;
                        SELECT @AircraftInstalledPartDetailsId = AircraftInstalledPartDetailsId FROM [DBO].[PurchaseOrderPart] WITH (NOLOCK) WHERE [PurchaseOrderPartRecordId] = @SelectedPurchaseOrderPartRecordId--PurchaseOrderId = @PurchaseOrderId;

                        IF (@AircraftInstalledPartDetailsId IS NOT NULL AND @AircraftInstalledPartDetailsId > 0)
                        BEGIN
                           UPDATE DBO.AircraftInstalledPartDetails SET StockLineId = @NewStocklineId  WHERE AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId
                                  AND (StockLineId IS NULL OR StockLineId = 0); 
                        END

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
                            FROM DBO.TimeLifeDraft WITH (NOLOCK)
                            WHERE StockLineDraftId = @SelectedStockLineDraftId;
                        END

                        /* Accounting Entry */
                        --DECLARE @p2 dbo.PostStocklineBatchType;

                        INSERT INTO @p2 VALUES (@NewStocklineId, @QtyAdded, @PurchaseOrderUnitCostAdded, 'ReceivingPO', @UpdatedBy, @MasterCompanyId, 'STOCK')

                        --EXEC dbo.usp_PostCreateStocklineBatchDetails @tbl_PostStocklineBatchType = @p2, @MstCompanyId = @MasterCompanyId, @updatedByName = @UpdatedBy;

                        DECLARE @ReceivingPurchaseOrderModule AS BIGINT = 28;

                        EXEC USP_AddUpdateStocklineHistory @NewStocklineId, @ReceivingPurchaseOrderModule, @PurchaseOrderId, NULL, NULL, 11, @QtyOnAction, @UpdatedBy;
                        EXEC USP_CreateStocklinePartHistory @NewStocklineId, 1, 0, 0, 0;

						UPDATE [dbo].[PurchaseOrderPart] SET [QuantityReceived] += @QtyAdded WHERE [PurchaseOrderId] = @PurchaseOrderId AND [PurchaseOrderPartRecordId] = @SelectedPurchaseOrderPartRecordId
						
                        UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @CNCurrentNumber WHERE CodeTypeId = 9 AND MasterCompanyId = @MasterCompanyId;

                        DECLARE @StkManagementStructureModuleId BIGINT = 2;
                        DECLARE @ManagementStructureEntityId BIGINT = 0;

                        SELECT @ManagementStructureEntityId = [ManagementStructureId] FROM DBO.Stockline WITH (NOLOCK) WHERE StocklineId = @NewStocklineId;

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

                            DECLARE @TotalQtyToTraverse DECIMAL(18,6) = 0;

                            SET @TotalQtyToTraverse = @QtyToReceive;

                            WHILE (@LoopID_QtyToReceive > 0)
                            BEGIN
                                IF (@TotalQtyToTraverse > 0)
                                BEGIN
                                    DECLARE @CurrentStocklineDraftId BIGINT = 0;

                                    SELECT @CurrentStocklineDraftId = StocklineDraftId
                                    FROM #StocklineDraftForQtyToReceive
                                    WHERE ID = @LoopID_QtyToReceive;

                                    UPDATE dbo.StocklineDraft
                                    SET StockLineId = @NewStocklineId,
                                        StockLineNumber = @StockLineNumber,
                                        ForStockQty = @QtyAdded --@QtyToReceive            
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
						ELSE IF(@IsSerializedPart = 0 AND @SelectedIsSameDetailsForAllParts = 0)
						BEGIN
							UPDATE dstl
                            SET dstl.StockLineId = @NewStocklineId,
                                dstl.StockLineNumber = @StockLineNumber,
                                dstl.ControlNumber = @ControlNumber,
                                dstl.ReceiverNumber = @ReceiverNumber, ForStockQty = @QtyAdded 
                            FROM DBO.StocklineDraft dstl
                            WHERE StockLineDraftId = @SelectedStockLineDraftId;
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

                        /* Update ItemMasterPurchaseSale*/
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
                            DECLARE @POP_UnitCost DECIMAL(18,6) = 0;
                            DECLARE @POP_VendorListPrice DECIMAL(18,6) = 0;
                            DECLARE @POP_DiscountPerUnit DECIMAL(18,6) = 0;
                            DECLARE @POP_DiscountPercent BIGINT = 0;
                            DECLARE @POP_DiscountPercentValue BIGINT = 0;
                            DECLARE @POP_ConditionId BIGINT = 0;

                            DECLARE @PP_VendorListPrice DECIMAL(18,6) = 0;
                            DECLARE @PP_PurchaseDiscAmount DECIMAL(18,6) = 0;
                            DECLARE @PP_UnitPurchasePrice DECIMAL(18,6) = 0;
                            DECLARE @PP_PurchaseDiscPerc DECIMAL(18,6) = 0;

							DECLARE @PP_MarkUpPerc BIGINT = 0;
							DECLARE @PP_newUnitSalePrice DECIMAL(18,6) = 0;
							DECLARE @PP_newMarkUpAmount DECIMAL(18,6) = 0;
							DECLARE @PP_FlatPrice DECIMAL(18,6) = 0;
							DECLARE @SalePriceSelectId INT = (SELECT ItemMasterPurchaseSaleMasterId FROM [dbo].ItemMasterPurchaseSaleMaster WHERE [Name] = 'Flat');

                            SELECT @POP_UnitCost = POP.UnitCost,
                                   @POP_VendorListPrice = POP.VendorListPrice,
                                   @POP_DiscountPerUnit = POP.DiscountPerUnit,
                                   @POP_DiscountPercent = POP.DiscountPercent,
                                   @POP_DiscountPercentValue = POP.DiscountPercentValue,
                                   @POP_ConditionId = POP.ConditionId,
								   @PP_FlatPrice = IMP.SP_FSP_FlatPriceAmount,
								   @PP_MarkUpPerc = p.PercentValue


                            FROM dbo.PurchaseOrderPart POP WITH (NOLOCK)
							LEFT JOIN dbo.ItemMasterPurchaseSale IMP WITH (NOLOCK) ON POP.ItemMasterId = IMP.ItemMasterId AND POP.ConditionId = IMP.ConditionId
							LEFT JOIN dbo.[Percent] P WITH (NOLOCK) ON P.PercentId = IMP.sP_CalSPByPP_MarkUpPercOnListPrice
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
                                DECLARE @disamt AS DECIMAL(18,6) = 0;
                                SET @disamt = ((ISNULL(@StkPurchaseOrderUnitCost, 0) * (ISNULL(@POP_DiscountPercentValue, 0))) / 100);

                                SET @PP_VendorListPrice = ISNULL(@StkPurchaseOrderUnitCost, 0) + @disamt;
                                SET @PP_PurchaseDiscAmount = ISNULL(@disamt, 0);
                                SET @PP_UnitPurchasePrice = ISNULL(@StkPurchaseOrderUnitCost, 0);
                                SET @PP_PurchaseDiscPerc = @POP_DiscountPercent;
                            END
							IF(ISNULL(@PP_MarkUpPerc , 0) > 0)
							BEGIN
								SET @PP_newMarkUpAmount =  ((ISNULL(@PP_UnitPurchasePrice, 0) * ISNULL(@PP_MarkUpPerc, 0)) / 100);
								SET @PP_newUnitSalePrice = (ISNULL(@PP_newMarkUpAmount, 0)  + ISNULL(@PP_UnitPurchasePrice, 0));
							END
							ELSE
							BEGIN
								--SET @PP_newUnitSalePrice = ISNULL(@PP_UnitPurchasePrice, 0) + ISNULL(@PP_FlatPrice, 0);
								SET @PP_newUnitSalePrice = ISNULL(@PP_FlatPrice, 0);
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
                                    CAST(GETUTCDATE() as date),
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
                                    @SalePriceSelectId,
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
                                 AND ISNULL(IM.IsNonStock,0) = 0
                                WHERE POP.PurchaseOrderId = @PurchaseOrderId
                                      AND POP.ItemMasterId = @ItemMasterId
                                      AND POP.ConditionId = @ConditionId;

                                EXEC dbo.UpdateItemMasterPurchaseSaleDetails @ItemMasterId;

								DECLARE @ItemMasterPurchaseSaleId  BIGINT = 0;

								SELECT @ItemMasterPurchaseSaleId =  ItemMasterPurchaseSaleId FROM [dbo].[ItemMasterPurchaseSale] WITH (NOLOCK)
								WHERE ItemMasterId = @ItemMasterId 
								AND ConditionId = @ConditionId;

								EXEC USP_AddUpdatePriceMasterHistory @ItemMasterPurchaseSaleId , @ReceivingPurchaseOrderModule , @MasterCompanyId , @PurchaseOrderId;
                            END
                            ELSE
                            BEGIN
                                UPDATE IMPS
                                SET IMPS.PP_VendorListPrice = @PP_VendorListPrice,
                                    IMPS.PP_PurchaseDiscAmount = @PP_PurchaseDiscAmount,
                                    IMPS.PP_UnitPurchasePrice = @PP_UnitPurchasePrice,
                                    IMPS.PP_PurchaseDiscPerc = @PP_PurchaseDiscPerc,

									IMPS.SP_CalSPByPP_MarkUpAmount = @PP_newMarkUpAmount,
									IMPS.SP_CalSPByPP_UnitSalePrice = @PP_newUnitSalePrice,

                                    IMPS.UpdatedBy = @UpdatedBy,
                                    IMPS.UpdatedDate = GETUTCDATE()
                                FROM DBO.ItemMasterPurchaseSale IMPS
                                WHERE IMPS.ItemMasterId = @ItemMasterId AND IMPS.ConditionId = @ConditionId;

								SELECT @ItemMasterPurchaseSaleId =  ItemMasterPurchaseSaleId FROM [dbo].[ItemMasterPurchaseSale] WITH (NOLOCK)
								WHERE ItemMasterId = @ItemMasterId 
								AND ConditionId = @ConditionId;

								EXEC USP_AddUpdatePriceMasterHistory @ItemMasterPurchaseSaleId , @ReceivingPurchaseOrderModule , @MasterCompanyId, @PurchaseOrderId;
                            END
                        END
						
						/*******Due to not showing PO Part while receive reconciliation (When QTY is more than 500)********/
						IF(@QtyAdded > @maxQtyLimit)
						BEGIN
							  UPDATE dbo.StocklineDraft SET StockLineId = @NewStocklineId, StockLineNumber = @StockLineNumber,	ControlNumber =@ControlNumber 
									WHERE PurchaseOrderId = @PurchaseOrderId AND PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 1 AND isSerialized = 0
						END

                        EXEC UpdateStocklineColumnsWithId @NewStocklineId;

                        SET @LoopID = @LoopID - 1;
                    END

					UPDATE Stk
					SET Stk.IsParent = 0
					FROM DBO.StocklineDraft Stk WHERE ISNULL(Stk.IsParent, 0) = 1 AND ISNULL(Stk.isSerialized, 0) = 0 AND Stk.StockLineNumber IS NOT NULL AND Stk.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;
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
                        [UnitCost] DECIMAL(18,6) NULL,
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
                        [CertificationDefaultCost] DECIMAL(18,6) NULL,
                        [CertificationGlAccountId] [bigint] NULL,
                        [CertificationMemo] [nvarchar](max) NULL,
                        [InspectionMemo] [nvarchar](max) NULL,
                        [InspectionGlaAccountId] [bigint] NULL,
                        [InspectionDefaultCost] DECIMAL(18,6) NULL,
                        [InspectionFrequencyMonths] [int] NOT NULL,
                        [InspectionFrequencyDays] [bigint] NULL,
                        [VerificationFrequencyDays] [bigint] NULL,
                        [VerificationFrequencyMonths] [int] NOT NULL,
                        [VerificationDefaultCost] DECIMAL(18,6) NULL,
                        [CalibrationDefaultCost] DECIMAL(18,6) NULL,
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
                        [InstallationCost] DECIMAL(18,6) NULL,
                        [Freight] DECIMAL(18,6) NULL,
                        [Insurance] DECIMAL(18,6) NULL,
                        [Taxes] DECIMAL(18,6) NULL,
                        [TotalCost] DECIMAL(18,6) NULL,
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
                        [Qty] DECIMAL(18,6) NULL,
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
						DepreciationStartDate [datetime] NULL,
                    )

                    IF (@IsSerializedPart = 1)
                    BEGIN
                        INSERT INTO #tmpAssetInventoryDraft
                        SELECT 
							[AssetInventoryDraftId],
							[AssetInventoryId],
							[AssetRecordId],
							[AssetId],
							[AlternateAssetRecordId],
							[Name],
							[Description],
							[ManagementStructureId],
							[CalibrationRequired],
							[CertificationRequired],
							[InspectionRequired],
							[VerificationRequired],
							[IsTangible],
							[IsIntangible],
							[AssetAcquisitionTypeId],
							[ManufacturerId],
							[ManufacturedDate],
							[Model],
							[IsSerialized],
							[UnitOfMeasureId],
							[CurrencyId],
							[UnitCost],
							[ExpirationDate],
							[Memo],
							[AssetParentRecordId],
							[TangibleClassId],
							[AssetIntangibleTypeId],
							[AssetCalibrationMin],
							[AssetCalibrationMinTolerance],
							[AssetCalibratonMax],
							[AssetCalibrationMaxTolerance],
							[AssetCalibrationExpected],
							[AssetCalibrationExpectedTolerance],
							[AssetCalibrationMemo],
							[AssetIsMaintenanceReqd],
							[AssetMaintenanceIsContract],
							[AssetMaintenanceContractFile],
							[MaintenanceFrequencyMonths],
							[MaintenanceFrequencyDays],
							[MaintenanceDefaultVendorId],
							[MaintenanceGLAccountId],
							[MaintenanceMemo],
							[IsWarrantyRequired],
							[WarrantyCompany],
							[WarrantyStartDate],
							[WarrantyEndDate],
							[WarrantyStatusId],
							[UnexpiredTime],
							[MasterCompanyId],
							[AssetLocationId],
							[IsDeleted],
							[Warranty],
							[IsActive],
							[CalibrationDefaultVendorId],
							[CertificationDefaultVendorId],
							[InspectionDefaultVendorId],
							[VerificationDefaultVendorId],
							[CertificationFrequencyMonths],
							[CertificationFrequencyDays],
							[CertificationDefaultCost],
							[CertificationGlAccountId],
							[CertificationMemo],
							[InspectionMemo],
							[InspectionGlaAccountId],
							[InspectionDefaultCost],
							[InspectionFrequencyMonths],
							[InspectionFrequencyDays],
							[VerificationFrequencyDays],
							[VerificationFrequencyMonths],
							[VerificationDefaultCost],
							[CalibrationDefaultCost],
							[CalibrationFrequencyMonths],
							[CalibrationFrequencyDays],
							[CalibrationGlAccountId],
							[CalibrationMemo],
							[VerificationMemo],
							[VerificationGlAccountId],
							[CalibrationCurrencyId],
							[CertificationCurrencyId],
							[InspectionCurrencyId],
							[VerificationCurrencyId],
							[CreatedBy],
							[UpdatedBy],
							[CreatedDate],
							[UpdatedDate],
							[AssetMaintenanceContractFileExt],
							[WarrantyFile],
							[WarrantyFileExt],
							[MasterPartId],
							[EntryDate],
							[InstallationCost],
							[Freight],
							[Insurance],
							[Taxes],
							[TotalCost],
							[WarrantyDefaultVendorId],
							[WarrantyGLAccountId],
							[IsDepreciable],
							[IsNonDepreciable],
							[IsAmortizable],
							[IsNonAmortizable],
							[SerialNo],
							[IsInsurance],
							[AssetLife],
							[WarrantyCompanyId],
							[WarrantyCompanyName],
							[WarrantyCompanySelectId],
							[WarrantyMemo],
							[IsQtyReserved],
							[InventoryStatusId],
							[InventoryNumber],
							[AssetStatusId],
							[Level1],
							[Level2],
							[Level3],
							[Level4],
							[ManufactureName],
							[LocationName],
							[Qty],
							[StklineNumber],
							[AvailStatus],
							[PartNumber],
							[ControlNumber],
							[TagDate],
							[ShippingViaId],
							[ShippingVia],
							[ShippingAccount],
							[ShippingReference],
							[RepairOrderId],
							[RepairOrderPartRecordId],
							[PurchaseOrderId],
							[PurchaseOrderPartRecordId],
							[SiteId],
							[WarehouseId],
							[LocationId],
							[ShelfId],
							[BinId],
							[GLAccountId],
							[GLAccount],
							[SiteName],
							[Warehouse],
							[Location],
							[ShelfName],
							[BinName],
							[IsParent],
							[ParentId],
							[IsSameDetailsForAllParts],
							[ReceiverNumber],
							[ReceivedDate],
							[CalibrationVendorId],
							[PerformedById],
							[LastCalibrationDate],
							[NextCalibrationDate],
							DepreciationStartDate
						FROM DBO.AssetInventoryDraft AssetDraft WITH (NOLOCK)
                        WHERE AssetDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 1 AND StklineNumber IS NULL
                        ORDER BY CreatedDate;
                    END
                    ELSE
                    BEGIN
                        IF EXISTS (SELECT TOP 1 1 FROM DBO.AssetInventoryDraft AssetDraft WITH (NOLOCK) WHERE AssetDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 0 AND IsSameDetailsForAllParts = 0 AND StklineNumber IS NULL)
                        BEGIN
                            INSERT INTO #tmpAssetInventoryDraft
                            SELECT [AssetInventoryDraftId],
							[AssetInventoryId],
							[AssetRecordId],
							[AssetId],
							[AlternateAssetRecordId],
							[Name],
							[Description],
							[ManagementStructureId],
							[CalibrationRequired],
							[CertificationRequired],
							[InspectionRequired],
							[VerificationRequired],
							[IsTangible],
							[IsIntangible],
							[AssetAcquisitionTypeId],
							[ManufacturerId],
							[ManufacturedDate],
							[Model],
							[IsSerialized],
							[UnitOfMeasureId],
							[CurrencyId],
							[UnitCost],
							[ExpirationDate],
							[Memo],
							[AssetParentRecordId],
							[TangibleClassId],
							[AssetIntangibleTypeId],
							[AssetCalibrationMin],
							[AssetCalibrationMinTolerance],
							[AssetCalibratonMax],
							[AssetCalibrationMaxTolerance],
							[AssetCalibrationExpected],
							[AssetCalibrationExpectedTolerance],
							[AssetCalibrationMemo],
							[AssetIsMaintenanceReqd],
							[AssetMaintenanceIsContract],
							[AssetMaintenanceContractFile],
							[MaintenanceFrequencyMonths],
							[MaintenanceFrequencyDays],
							[MaintenanceDefaultVendorId],
							[MaintenanceGLAccountId],
							[MaintenanceMemo],
							[IsWarrantyRequired],
							[WarrantyCompany],
							[WarrantyStartDate],
							[WarrantyEndDate],
							[WarrantyStatusId],
							[UnexpiredTime],
							[MasterCompanyId],
							[AssetLocationId],
							[IsDeleted],
							[Warranty],
							[IsActive],
							[CalibrationDefaultVendorId],
							[CertificationDefaultVendorId],
							[InspectionDefaultVendorId],
							[VerificationDefaultVendorId],
							[CertificationFrequencyMonths],
							[CertificationFrequencyDays],
							[CertificationDefaultCost],
							[CertificationGlAccountId],
							[CertificationMemo],
							[InspectionMemo],
							[InspectionGlaAccountId],
							[InspectionDefaultCost],
							[InspectionFrequencyMonths],
							[InspectionFrequencyDays],
							[VerificationFrequencyDays],
							[VerificationFrequencyMonths],
							[VerificationDefaultCost],
							[CalibrationDefaultCost],
							[CalibrationFrequencyMonths],
							[CalibrationFrequencyDays],
							[CalibrationGlAccountId],
							[CalibrationMemo],
							[VerificationMemo],
							[VerificationGlAccountId],
							[CalibrationCurrencyId],
							[CertificationCurrencyId],
							[InspectionCurrencyId],
							[VerificationCurrencyId],
							[CreatedBy],
							[UpdatedBy],
							[CreatedDate],
							[UpdatedDate],
							[AssetMaintenanceContractFileExt],
							[WarrantyFile],
							[WarrantyFileExt],
							[MasterPartId],
							[EntryDate],
							[InstallationCost],
							[Freight],
							[Insurance],
							[Taxes],
							[TotalCost],
							[WarrantyDefaultVendorId],
							[WarrantyGLAccountId],
							[IsDepreciable],
							[IsNonDepreciable],
							[IsAmortizable],
							[IsNonAmortizable],
							[SerialNo],
							[IsInsurance],
							[AssetLife],
							[WarrantyCompanyId],
							[WarrantyCompanyName],
							[WarrantyCompanySelectId],
							[WarrantyMemo],
							[IsQtyReserved],
							[InventoryStatusId],
							[InventoryNumber],
							[AssetStatusId],
							[Level1],
							[Level2],
							[Level3],
							[Level4],
							[ManufactureName],
							[LocationName],
							[Qty],
							[StklineNumber],
							[AvailStatus],
							[PartNumber],
							[ControlNumber],
							[TagDate],
							[ShippingViaId],
							[ShippingVia],
							[ShippingAccount],
							[ShippingReference],
							[RepairOrderId],
							[RepairOrderPartRecordId],
							[PurchaseOrderId],
							[PurchaseOrderPartRecordId],
							[SiteId],
							[WarehouseId],
							[LocationId],
							[ShelfId],
							[BinId],
							[GLAccountId],
							[GLAccount],
							[SiteName],
							[Warehouse],
							[Location],
							[ShelfName],
							[BinName],
							[IsParent],
							[ParentId],
							[IsSameDetailsForAllParts],
							[ReceiverNumber],
							[ReceivedDate],
							[CalibrationVendorId],
							[PerformedById],
							[LastCalibrationDate],
							[NextCalibrationDate],
							DepreciationStartDate FROM DBO.AssetInventoryDraft AssetDraft WITH (NOLOCK)
                            WHERE AssetDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 1 AND StklineNumber IS NULL
                            ORDER BY CreatedDate;
                        END
                        ELSE
                        BEGIN
                            INSERT INTO #tmpAssetInventoryDraft
                            SELECT [AssetInventoryDraftId],
							[AssetInventoryId],
							[AssetRecordId],
							[AssetId],
							[AlternateAssetRecordId],
							[Name],
							[Description],
							[ManagementStructureId],
							[CalibrationRequired],
							[CertificationRequired],
							[InspectionRequired],
							[VerificationRequired],
							[IsTangible],
							[IsIntangible],
							[AssetAcquisitionTypeId],
							[ManufacturerId],
							[ManufacturedDate],
							[Model],
							[IsSerialized],
							[UnitOfMeasureId],
							[CurrencyId],
							[UnitCost],
							[ExpirationDate],
							[Memo],
							[AssetParentRecordId],
							[TangibleClassId],
							[AssetIntangibleTypeId],
							[AssetCalibrationMin],
							[AssetCalibrationMinTolerance],
							[AssetCalibratonMax],
							[AssetCalibrationMaxTolerance],
							[AssetCalibrationExpected],
							[AssetCalibrationExpectedTolerance],
							[AssetCalibrationMemo],
							[AssetIsMaintenanceReqd],
							[AssetMaintenanceIsContract],
							[AssetMaintenanceContractFile],
							[MaintenanceFrequencyMonths],
							[MaintenanceFrequencyDays],
							[MaintenanceDefaultVendorId],
							[MaintenanceGLAccountId],
							[MaintenanceMemo],
							[IsWarrantyRequired],
							[WarrantyCompany],
							[WarrantyStartDate],
							[WarrantyEndDate],
							[WarrantyStatusId],
							[UnexpiredTime],
							[MasterCompanyId],
							[AssetLocationId],
							[IsDeleted],
							[Warranty],
							[IsActive],
							[CalibrationDefaultVendorId],
							[CertificationDefaultVendorId],
							[InspectionDefaultVendorId],
							[VerificationDefaultVendorId],
							[CertificationFrequencyMonths],
							[CertificationFrequencyDays],
							[CertificationDefaultCost],
							[CertificationGlAccountId],
							[CertificationMemo],
							[InspectionMemo],
							[InspectionGlaAccountId],
							[InspectionDefaultCost],
							[InspectionFrequencyMonths],
							[InspectionFrequencyDays],
							[VerificationFrequencyDays],
							[VerificationFrequencyMonths],
							[VerificationDefaultCost],
							[CalibrationDefaultCost],
							[CalibrationFrequencyMonths],
							[CalibrationFrequencyDays],
							[CalibrationGlAccountId],
							[CalibrationMemo],
							[VerificationMemo],
							[VerificationGlAccountId],
							[CalibrationCurrencyId],
							[CertificationCurrencyId],
							[InspectionCurrencyId],
							[VerificationCurrencyId],
							[CreatedBy],
							[UpdatedBy],
							[CreatedDate],
							[UpdatedDate],
							[AssetMaintenanceContractFileExt],
							[WarrantyFile],
							[WarrantyFileExt],
							[MasterPartId],
							[EntryDate],
							[InstallationCost],
							[Freight],
							[Insurance],
							[Taxes],
							[TotalCost],
							[WarrantyDefaultVendorId],
							[WarrantyGLAccountId],
							[IsDepreciable],
							[IsNonDepreciable],
							[IsAmortizable],
							[IsNonAmortizable],
							[SerialNo],
							[IsInsurance],
							[AssetLife],
							[WarrantyCompanyId],
							[WarrantyCompanyName],
							[WarrantyCompanySelectId],
							[WarrantyMemo],
							[IsQtyReserved],
							[InventoryStatusId],
							[InventoryNumber],
							[AssetStatusId],
							[Level1],
							[Level2],
							[Level3],
							[Level4],
							[ManufactureName],
							[LocationName],
							[Qty],
							[StklineNumber],
							[AvailStatus],
							[PartNumber],
							[ControlNumber],
							[TagDate],
							[ShippingViaId],
							[ShippingVia],
							[ShippingAccount],
							[ShippingReference],
							[RepairOrderId],
							[RepairOrderPartRecordId],
							[PurchaseOrderId],
							[PurchaseOrderPartRecordId],
							[SiteId],
							[WarehouseId],
							[LocationId],
							[ShelfId],
							[BinId],
							[GLAccountId],
							[GLAccount],
							[SiteName],
							[Warehouse],
							[Location],
							[ShelfName],
							[BinName],
							[IsParent],
							[ParentId],
							[IsSameDetailsForAllParts],
							[ReceiverNumber],
							[ReceivedDate],
							[CalibrationVendorId],
							[PerformedById],
							[LastCalibrationDate],
							[NextCalibrationDate],
							DepreciationStartDate FROM DBO.AssetInventoryDraft AssetDraft WITH (NOLOCK)
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
                        DECLARE @StkPurchaseOrderUnitCost_Asset AS DECIMAL(18,6) = 0;
                        DECLARE @ManufacturerId_Asset AS BIGINT;
                        DECLARE @PreviousStockLineNumber_Asset VARCHAR(50);
                        DECLARE @IsTangible BIT = 0;

                        SELECT @SelectedStockLineDraftId_Asset = AssetInventoryDraftId, @IsTangible = IsTangible FROM #tmpAssetInventoryDraft WHERE ID = @LoopID;

                        SELECT @PORequestorId_Asset = RequestedBy, @POVendorId_Asset = VendorId FROM DBO.PurchaseOrder WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId;

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
                        FROM dbo.CodePrefixes CP WITH (NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
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
						@UpdatedBy,@UpdatedBy,[CreatedDate],[UpdatedDate],[AssetMaintenanceContractFileExt],[WarrantyFile],[WarrantyFileExt],[MasterPartId],[EntryDate],[InstallationCost],[Freight],[Insurance],[Taxes],
						[TotalCost],[WarrantyDefaultVendorId],[WarrantyGLAccountId],[IsDepreciable],[IsNonDepreciable],[IsAmortizable],[IsNonAmortizable],[SerialNo],[IsInsurance],[AssetLife],[WarrantyCompanyId],[WarrantyCompanyName],
						[WarrantyCompanySelectId],[WarrantyMemo],[IsQtyReserved],1,@InventoryNumber_Asset,[AssetStatusId],[Level1],[Level2],[Level3],[Level4],[ManufactureName],[LocationName],[Qty],@StockLineNumber_Asset,[AvailStatus],
						[PartNumber],@ControlNumber_Asset,[RepairOrderId],[RepairOrderPartRecordId],[PurchaseOrderId],[PurchaseOrderPartRecordId],@ReceiverNumber_Asset,GETUTCDATE(),[SiteId],[SiteName],[WarehouseId],[Warehouse],
						[LocationId],[Location],[ShelfId],[ShelfName],[BinId],[BinName],'',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						NULL,NULL,NULL,NULL,NULL,NULL
						FROM #tmpAssetInventoryDraft
                        WHERE AssetInventoryDraftId = @SelectedStockLineDraftId_Asset;

                        DECLARE @QtyAdded_Asset INT = 0;
                        DECLARE @PurchaseOrderUnitCostAdded_Asset DECIMAL(18,6) = 0;
                        DECLARE @SelectedIsSameDetailsForAllParts_Asset BIT = 0;
                        DECLARE @IsTimeLIfe_Asset BIT;

                        SELECT @QtyAdded_Asset = CASE WHEN @IsSerializedPart = 1 THEN [Qty] ELSE CASE WHEN  ISNULL(IsSameDetailsForAllParts,0) = 0 THEN [Qty] ELSE 1 END END,
                               @SelectedIsSameDetailsForAllParts_Asset = IsSameDetailsForAllParts,
                               @PurchaseOrderUnitCostAdded_Asset = UnitCost
                        FROM #tmpAssetInventoryDraft WHERE AssetInventoryDraftId = @SelectedStockLineDraftId_Asset;

                        SELECT @NewStocklineId_Asset = SCOPE_IDENTITY();

						SET @NewAssetRecordId = (SELECT AssetRecordId FROM AssetInventory WITH (NOLOCK) WHERE AssetInventoryId = @NewStocklineId_Asset)
											

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
                        --DECLARE @p3 dbo.PostStocklineBatchType;

                        INSERT INTO @p3
                        VALUES (@NewStocklineId_Asset, @QtyAdded_Asset, @PurchaseOrderUnitCostAdded_Asset, 'ReceivingPO', @UpdatedBy, @MasterCompanyId, 'ASSET')

                        --EXEC dbo.usp_PostCreateStocklineBatchDetails @tbl_PostStocklineBatchType = @p3, @MstCompanyId = @MasterCompanyId, @updatedByName = @UpdatedBy;

                        DECLARE @ReceivingPurchaseOrderModule_Asset AS BIGINT = 28;

                        EXEC USP_AddUpdateStocklineHistory @NewStocklineId_Asset, @ReceivingPurchaseOrderModule_Asset, @PurchaseOrderId, NULL, NULL, 11, @QtyAdded_Asset, @UpdatedBy;
                        EXEC USP_CreateStocklinePartHistory @NewStocklineId_Asset, 1, 0, 0, 0;

						UPDATE [dbo].[PurchaseOrderPart] SET [QuantityReceived] += @QtyAdded_Asset WHERE [PurchaseOrderId] = @PurchaseOrderId AND [PurchaseOrderPartRecordId] = @SelectedPurchaseOrderPartRecordId
						
                        UPDATE [dbo].[CodePrefixes]
                        SET CurrentNummber = @CNCurrentNumber_Asset
                        WHERE CodeTypeId = 9 AND MasterCompanyId = @MasterCompanyId;

                        DECLARE @StkManagementStructureModuleId_Asset BIGINT = 2;
                        DECLARE @ManagementStructureEntityId_Asset BIGINT = 0;
                        DECLARE @ModuleId_AssetMS BIGINT = CASE WHEN @IsTangible = 1 THEN 42 ELSE 43 END;

                        SELECT @ManagementStructureEntityId_Asset = [ManagementStructureId]
                        FROM DBO.AssetInventory WITH (NOLOCK) WHERE [AssetInventoryId] = @NewStocklineId_Asset;

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

                                    UPDATE dbo.AssetInventoryDraft
                                    SET AssetInventoryId = @NewStocklineId_Asset,
                                        StklineNumber = @StockLineNumber_Asset,
										ControlNumber =@ControlNumber_Asset 
                                    WHERE AssetInventoryDraftId = @CurrentStocklineDraftId_Asset;

                                    SET @TotalQtyToTraverse_Asset = @TotalQtyToTraverse_Asset - 1;
                                END
                                SET @LoopID_QtyToReceive_Asset = @LoopID_QtyToReceive_Asset - 1;
                            END

                            --IF ((@MainPOPartBackOrderQty - @QtyToReceive) > 0)
                            --BEGIN
                            --    SET @StockLineNumber_Asset = NULL;
                            --    SET @NewStocklineId_Asset = NULL;
                            --END

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
						
						/******* Due to not showing PO Part while receive reconciliation (When QTY is more than 500)********/
						IF(@QtyAdded_Asset > @maxQtyLimit)
						BEGIN
							  UPDATE  dbo.AssetInventoryDraft SET AssetInventoryId = @NewStocklineId_Asset, InventoryNumber = @StockLineNumber_Asset,	ControlNumber =@ControlNumber_Asset 
									WHERE PurchaseOrderId = @PurchaseOrderId AND PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 1 AND isSerialized = 0
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
                    /* [PN-17271] 16/July/2026 RAJESH GAMI - Non-Stock PO Parts are now received into DBO.Stockline
                       (IsNonStock = 1) instead of DBO.NonStockInventory. Sourced from DBO.StocklineDraft
                       (IsNonStock = 1) instead of the legacy DBO.NonStockInventoryDraft. Uses the same
                       StockLineNumber/ControlNumber numbering as Stock (dbo.ItemMaster.CurrentStlNo + CodeTypeId 30/9)
                       and the same dbo.USP_SaveSLMSDetails MS-data linkage, since it is now one shared table. */
                    DECLARE @NonStockItemTypeId BIGINT;
                    DECLARE @NonStockItemTypeName VARCHAR(100);

                    SELECT @NonStockItemTypeId = ItemTypeId, @NonStockItemTypeName = Description
                    FROM DBO.ItemType WITH (NOLOCK) WHERE Description = 'Non-Stock';

                    SELECT @IsSerializedPart = IM.isSerialized FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId = @ItemMasterId_Part AND ISNULL(IM.IsNonStock,0) = 1 ;

                    IF OBJECT_ID(N'tempdb..#tmpStocklineDraft_NS') IS NOT NULL
                    BEGIN
                        DROP TABLE #tmpStocklineDraft_NS
                    END

                    CREATE TABLE #tmpStocklineDraft_NS
                    (
                        ID BIGINT NOT NULL IDENTITY,
                        [StockLineDraftId] [bigint] NOT NULL,
                        [PartNumber] [varchar](50) NOT NULL,
                        [StockLineNumber] [varchar](50) NULL,
                        [StocklineMatchKey] [varchar](100) NULL,
                        [ControlNumber] [varchar](50) NULL,
                        [ItemMasterId] [bigint] NULL,
                        [Quantity] [decimal](18,6) NOT NULL,
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
                        [PurchaseOrderUnitCost] DECIMAL(18,6) NULL,
                        [InventoryUnitCost] DECIMAL(18,6) NULL,
                        [RepairOrderId] [bigint] NULL,
                        [RepairOrderUnitCost] DECIMAL(18,6) NULL,
                        [ReceivedDate] [datetime2](7) NULL,
                        [ReceiverNumber] [varchar](50) NULL,
                        [ReconciliationNumber] [varchar](50) NULL,
                        [UnitSalesPrice] DECIMAL(18,6) NULL,
                        [CoreUnitCost] DECIMAL(18,6) NULL,
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
                        [QuantityToReceive] [decimal](18,6) NOT NULL,
                        [PurchaseOrderExtendedCost] DECIMAL(18,6) NOT NULL,
                        [ManufacturingTrace] [nvarchar](200) NULL,
                        [ExpirationDate] [datetime2](7) NULL,
                        [AircraftTailNumber] [nvarchar](200) NULL,
                        [ShippingViaId] [bigint] NULL,
                        [EngineSerialNumber] [nvarchar](200) NULL,
                        [QuantityRejected] [decimal](18,6) NOT NULL,
                        [PurchaseOrderPartRecordId] [bigint] NULL,
                        [ShippingAccount] [nvarchar](200) NULL,
                        [ShippingReference] [nvarchar](200) NULL,
                        [TimeLifeCyclesId] [bigint] NULL,
                        [TimeLifeDetailsNotProvided] [bit] NOT NULL,
                        [WorkOrderId] [bigint] NULL,
                        [WorkOrderMaterialsId] [bigint] NULL,
                        [QuantityReserved] [decimal](18,6) NULL,
                        [QuantityTurnIn] [decimal](18,6) NULL,
                        [QuantityIssued] [decimal](18,6) NULL,
                        [QuantityOnHand] [decimal](18,6) NULL,
                        [QuantityAvailable] [decimal](18,6) NULL,
                        [QuantityOnOrder] [decimal](18,6) NULL,
                        [QtyReserved] [decimal](18,6) NULL,
                        [QtyIssued] [decimal](18,6) NULL,
                        [BlackListed] [bit] NOT NULL,
                        [BlackListedReason] [varchar](500) NULL,
                        [Incident] [bit] NOT NULL,
                        [IncidentReason] [varchar](500) NULL,
                        [Accident] [bit] NOT NULL,
                        [AccidentReason] [varchar](500) NULL,
                        [RepairOrderPartRecordId] [bigint] NULL,
                        [isActive] [bit] NOT NULL,
                        [isDeleted] [bit] NOT NULL,
                        [WorkOrderExtendedCost] DECIMAL(18,6) NOT NULL,
                        [RepairOrderExtendedCost] DECIMAL(18,6) NULL,
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
                        [WOQty] [decimal](18,6) NULL,
                        [SOQty] [decimal](18,6) NULL,
                        [ForStockQty] [decimal](18,6) NULL,
                        [IsLotAssigned] [bit] NULL,
                        [LOTQty] [decimal](18,6) NULL,
                        [LOTQtyReserve] [decimal](18,6) NULL,
                        [OriginalCost] DECIMAL(18,6) NULL,
                        [POOriginalCost] DECIMAL(18,6) NULL,
                        [ROOriginalCost] DECIMAL(18,6) NULL,
                        [VendorRMAId] [bigint] NULL,
                        [VendorRMADetailId] [bigint] NULL,
                        [LotMainStocklineId] [bigint] NULL,
                        [IsFromInitialPO] [bit] NULL,
                        [LotSourceId] [int] NULL,
                        [Adjustment] DECIMAL(18,6) NULL,
                        [SerialNumberNotProvided] [bit] NULL,
                        [ShippingReferenceNumberNotProvided] [bit] NULL,
                        [IsStkTimeLife] [bit] NULL,
						[IsKitType] [bit] NULL,
						[IsSubWOType] [bit] NULL
                    )

                    INSERT INTO #tmpStocklineDraft_NS
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
					IsFromInitialPO,LotSourceId,Adjustment,SerialNumberNotProvided,ShippingReferenceNumberNotProvided,IsStkTimeLife,IsKitType,IsSubWOType
					FROM DBO.StocklineDraft StkDraft WITH (NOLOCK)
                    WHERE StkDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND ISNULL(IsParent, 0) = 1 AND StockLineNumber IS NULL AND ISNULL(IsNonStock,0) = 1
                    ORDER BY CreatedDate;

                    SET @CurrentIndex = 0;

                    IF (@IsSerializedPart = 1)
                    BEGIN
                        SET @LoopID = @QtyToReceive;
                    END
                    ELSE
                    BEGIN
                        DECLARE @IsSameDetailsForAllParts_NS BIT = 1;
                        SELECT TOP 1 @IsSameDetailsForAllParts_NS = StkDraft.IsSameDetailsForAllParts
                        FROM DBO.StocklineDraft StkDraft WITH (NOLOCK)
                        WHERE ISNULL(IsParent, 0) = 1 AND StkDraft.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;

                        IF (@IsSameDetailsForAllParts_NS = 0)
                        BEGIN
                            SET @LoopID = @QtyToReceive;
                        END
                        ELSE
                        BEGIN
                            SELECT @LoopID = MAX(ID) FROM #tmpStocklineDraft_NS;
                        END
                    END

                    WHILE (@LoopID > 0)
                    BEGIN
                        DECLARE @SelectedStockLineDraftId_NS BIGINT;
                        DECLARE @CurrentIdNumber_NS AS BIGINT;
                        DECLARE @ReceiverNumber_NS AS VARCHAR(50);
                        DECLARE @IdCodeTypeId_NS BIGINT;
                        DECLARE @PORequestorId_NS BIGINT;
                        DECLARE @POVendorId_NS BIGINT;
                        DECLARE @NewStocklineId_NS BIGINT;
                        DECLARE @StockLineNumber_NS VARCHAR(100);
                        DECLARE @CNCurrentNumber_NS BIGINT;
                        DECLARE @ControlNumber_NS VARCHAR(50);
                    
                        DECLARE @currentNo_NS AS BIGINT = 0;
                        DECLARE @stockLineCurrentNo_NS AS BIGINT;
                        DECLARE @ItemMasterId_NS AS BIGINT;
                        DECLARE @ConditionId_NS AS BIGINT;
                        DECLARE @StkPurchaseOrderUnitCost_NS AS DECIMAL(18, 2) = 0;
                        DECLARE @ManufacturerId_NS AS BIGINT;
                        DECLARE @PreviousStockLineNumber_NS VARCHAR(50);
						DECLARE @AircraftInstalledPartDetailsId_NS BIGINT = NULL;

                        SELECT @SelectedStockLineDraftId_NS = StockLineDraftId FROM #tmpStocklineDraft_NS WHERE ID = @LoopID;

                        SELECT @PORequestorId_NS = RequestedBy, @POVendorId_NS = VendorId FROM DBO.PurchaseOrder WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId;

                        SELECT @IdCodeTypeId_NS = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) WHERE CodeType = 'Stock Line';

                        IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_NS') IS NOT NULL
                        BEGIN
                            DROP TABLE #tmpCodePrefixes_NS
                        END

                        CREATE TABLE #tmpCodePrefixes_NS
                        (
                            ID BIGINT NOT NULL IDENTITY,
                            CodePrefixId BIGINT NULL,
                            CodeTypeId BIGINT NULL,
                            CurrentNumber BIGINT NULL,
                            CodePrefix VARCHAR(50) NULL,
                            CodeSufix VARCHAR(50) NULL,
                            StartsFrom BIGINT NULL,
                        )

                        INSERT INTO #tmpCodePrefixes_NS
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
                        WHERE CT.CodeTypeId = @IdCodeTypeId_NS
                              AND CP.MasterCompanyId = @MasterCompanyId
                              AND CP.IsActive = 1
                              AND CP.IsDeleted = 0;

                        IF (@CurrentIndex = 0)
                        BEGIN
                            SELECT @CurrentIdNumber_NS = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END
                            FROM #tmpCodePrefixes_NS WHERE CodeTypeId = @IdCodeTypeId_NS
                        END
                        ELSE
                        BEGIN
                            SELECT @CurrentIdNumber_NS = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END
                            FROM #tmpCodePrefixes_NS WHERE CodeTypeId = @IdCodeTypeId_NS
                        END

                        SET @ReceiverNumber_NS = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentIdNumber_NS, 'RecNo', (SELECT CodeSufix FROM #tmpCodePrefixes_NS WHERE CodeTypeId = @IdCodeTypeId_NS)))

                        /* PN Manufacturer Combination Stockline logic */
                        IF OBJECT_ID(N'tempdb..#tmpPNManufacturer_NS') IS NOT NULL
                        BEGIN
                            DROP TABLE #tmpPNManufacturer_NS
                        END

                        CREATE TABLE #tmpPNManufacturer_NS
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

                        INSERT INTO #tmpPNManufacturer_NS
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
						INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId 
						ON CSTL.StockLineId = STL.StockLineId
                        /* PN Manufacturer Combination Stockline logic */

                         WHERE ISNULL(IM.IsNonStock,0) = 1
DELETE FROM #tmpCodePrefixes_NS;

                        INSERT INTO #tmpCodePrefixes_NS
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
						JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
                        WHERE CT.CodeTypeId IN ( 30, 17, 9 )
                              AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

                        SELECT @ItemMasterId_NS = ItemMasterId,
                               @ConditionId_NS = ConditionId,
                               @StkPurchaseOrderUnitCost_NS = PurchaseOrderUnitCost,
                               @ManufacturerId_NS = ManufacturerId,
                               @PreviousStockLineNumber_NS = StockLineNumber
                        FROM dbo.StocklineDraft WITH (NOLOCK)
                        WHERE StockLineDraftId = @SelectedStockLineDraftId_NS;

                        SELECT @currentNo_NS = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer_NS WHERE ItemMasterId = @ItemMasterId_NS AND ManufacturerId = @ManufacturerId_NS;

                        IF (@currentNo_NS <> 0)
                        BEGIN
                            SET @stockLineCurrentNo_NS = @currentNo_NS + 1;
                        END
                        ELSE
                        BEGIN
                            SET @stockLineCurrentNo_NS = 1;
                        END

                        IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes_NS WHERE CodeTypeId = 30))
                        BEGIN
                            SET @StockLineNumber_NS =
                            (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@stockLineCurrentNo_NS,
							(SELECT CodePrefix FROM #tmpCodePrefixes_NS WHERE CodeTypeId = 30),
							(SELECT CodeSufix FROM #tmpCodePrefixes_NS WHERE CodeTypeId = 30)))

                            UPDATE DBO.ItemMaster
                            SET CurrentStlNo = @stockLineCurrentNo_NS
                            WHERE ItemMasterId = @ItemMasterId_NS AND ManufacturerId = @ManufacturerId_NS
                        END

                        IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes_NS WHERE CodeTypeId = 9))
                        BEGIN
                            SELECT @CNCurrentNumber_NS = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END
                            FROM #tmpCodePrefixes_NS WHERE CodeTypeId = 9;
                            SET @ControlNumber_NS =
                            (
                                SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CNCurrentNumber_NS,
								(SELECT CodePrefix FROM #tmpCodePrefixes_NS WHERE CodeTypeId = 9),
								(SELECT CodeSufix FROM #tmpCodePrefixes_NS WHERE CodeTypeId = 9))
                            )
                        END

						DECLARE @IntegrationPortal_NS VARCHAR(50)

						SELECT
							@IntegrationPortal_NS = STRING_AGG(CAST(mp.IntegrationPortalId AS VARCHAR), ',')
						FROM dbo.ItemMaster iM WITH(NOLOCK)
						LEFT JOIN dbo.ItemMasterIntegrationPortal mp WITH(NOLOCK) ON iM.ItemMasterId = mp.ItemMasterId
						LEFT JOIN dbo.IntegrationPortal ip WITH(NOLOCK) ON mp.IntegrationPortalId = ip.IntegrationPortalId
						WHERE iM.ItemMasterId = @ItemMasterId_NS AND iM.MasterCompanyId = @MasterCompanyId AND mp.IntegrationPortalId IS NOT NULL
						 AND ISNULL(iM.IsNonStock,0) = 0
						 GROUP BY iM.ItemMasterId



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
						[OriginalCost],[POOriginalCost],[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment],[IsStkTimeLife], [IntegrationPortal], [IsNonStock])

                        SELECT [PartNumber],@StockLineNumber_NS,[StocklineMatchKey],@ControlNumber_NS,[ItemMasterId],CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE
							CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],
						[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber],
						[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],
						ISNULL([RepairOrderUnitCost], 0),GETUTCDATE(),@ReceiverNumber_NS,[ReconciliationNumber],ISNULL([UnitSalesPrice], 0),ISNULL([CoreUnitCost], 0),[GLAccountId],[AssetId],[IsHazardousMaterial],
						[IsPMA],[IsDER],[OEM],[Memo],[ManagementStructureEntityId],[LegalEntityId],[MasterCompanyId],@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),[isSerialized],[ShelfId],[BinId],[SiteId],
						CASE WHEN [ObtainFromType] = 0 THEN NULL ELSE [ObtainFromType] END,[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],
						[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],
						[WorkOrderId],CASE WHEN [WorkOrderMaterialsId] = 0 THEN NULL ELSE[WorkOrderMaterialsId]END,ISNULL([QuantityReserved], 0),ISNULL([QuantityTurnIn], 0),ISNULL([QuantityIssued], 0),CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE
							CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,
						CASE WHEN @IsSerializedPart = 1 THEN [Quantity]
							ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,
						ISNULL([QuantityOnOrder], 0),ISNULL([QtyReserved], 0),ISNULL([QtyIssued], 0),[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],
						[isActive],[isDeleted],[WorkOrderExtendedCost],ISNULL([RepairOrderExtendedCost], 0),[IsCustomerStock],GETUTCDATE(),0,[NHAItemMasterId],[TLAItemMasterId],@NonStockItemTypeId,NULL,@PORequestorId_NS,NULL,NULL,
						NULL,NULL,NULL,@POVendorId_NS,[IsParent],[ParentId],[IsSameDetailsForAllParts],0,[SubWorkOrderId],0,NULL,[UnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],
						[Level3],[Level4],[Condition],NULL,NULL,[Warehouse],[Location],NULL,NULL,[UnitOfMeasure],NULL,NULL,NULL,NULL,NULL,NULL,@NonStockItemTypeName,[CustomerId],NULL,ISNULL([isCustomerstockType], 0),'',NULL,NULL,
						NULL,[TaggedBy],[TaggedByName],(ISNULL(PurchaseOrderUnitCost, 0) + ISNULL(RepairOrderUnitCost, 0) + ISNULL(Adjustment, 0)),[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],
						[CertifiedType],[CertTypeId],[CertType],[TagTypeId],0,0,NULL,NULL,NULL,NULL,NULL,NULL,[ExchangeSalesOrderId],CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN IsSameDetailsForAllParts = 0 THEN [Quantity] ELSE @QtyToReceive END END,NULL,1,NULL,
						[LotId],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost],[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],ISNULL(Adjustment, 0),[IsStkTimeLife], ISNULL(@IntegrationPortal_NS, ''), 1
                        FROM #tmpStocklineDraft_NS
                        WHERE StockLineDraftId = @SelectedStockLineDraftId_NS;

                        DECLARE @QtyAdded_NS INT = 0;
                        DECLARE @PurchaseOrderUnitCostAdded_NS DECIMAL(18, 2) = 0;
                        DECLARE @SelectedIsSameDetailsForAllParts_NS BIT = 0;
                        DECLARE @IsTimeLIfe_NS BIT

                        SELECT @QtyAdded_NS = CASE WHEN @IsSerializedPart = 1 THEN [Quantity] ELSE CASE WHEN ISNULL(IsSameDetailsForAllParts,0) = 0 THEN [Quantity] ELSE @QtyToReceive END END,
                               @SelectedIsSameDetailsForAllParts_NS = IsSameDetailsForAllParts,
                               @PurchaseOrderUnitCostAdded_NS = PurchaseOrderUnitCost,
                               @IsTimeLIfe_NS = [IsStkTimeLife]
                        FROM #tmpStocklineDraft_NS WHERE StockLineDraftId = @SelectedStockLineDraftId_NS;

                        SELECT @NewStocklineId_NS = SCOPE_IDENTITY();


                        INSERT INTO #InsertedStkForLot (StockLineId)
                        SELECT @NewStocklineId_NS

						-- For Aircraftinstalled Parts
                        SET @AircraftInstalledPartDetailsId_NS = NULL;
                        SELECT @AircraftInstalledPartDetailsId_NS = AircraftInstalledPartDetailsId FROM [DBO].[PurchaseOrderPart] WITH (NOLOCK) WHERE [PurchaseOrderPartRecordId] = @SelectedPurchaseOrderPartRecordId--PurchaseOrderId = @PurchaseOrderId;

                        IF (@AircraftInstalledPartDetailsId_NS IS NOT NULL AND @AircraftInstalledPartDetailsId_NS > 0)
                        BEGIN
                           UPDATE DBO.AircraftInstalledPartDetails SET StockLineId = @NewStocklineId_NS  WHERE AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId_NS
                                  AND (StockLineId IS NULL OR StockLineId = 0);
                        END

                        IF (@IsTimeLIfe_NS = 1)
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
                                   @NewStocklineId_NS,
                                   [DetailsNotProvided],
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL
                            FROM DBO.TimeLifeDraft WITH (NOLOCK)
                            WHERE StockLineDraftId = @SelectedStockLineDraftId_NS;
                        END

                        /* Accounting Entry */
                        --DECLARE @p2 dbo.PostStocklineBatchType;

                        INSERT INTO @p4 VALUES (@NewStocklineId_NS, @QtyAdded_NS, @PurchaseOrderUnitCostAdded_NS, 'ReceivingPO', @UpdatedBy, @MasterCompanyId, 'NONSTOCK')

                        --EXEC dbo.usp_PostCreateStocklineBatchDetails @tbl_PostStocklineBatchType = @p2, @MstCompanyId = @MasterCompanyId, @updatedByName = @UpdatedBy;

                        DECLARE @ReceivingPurchaseOrderModule_NS AS BIGINT = 28;

                        EXEC USP_AddUpdateStocklineHistory @NewStocklineId_NS, @ReceivingPurchaseOrderModule_NS, @PurchaseOrderId, NULL, NULL, 11, @QtyAdded_NS, @UpdatedBy;
                        EXEC USP_CreateStocklinePartHistory @NewStocklineId_NS, 1, 0, 0, 0;

						UPDATE [dbo].[PurchaseOrderPart] SET [QuantityReceived] += @QtyAdded_NS WHERE [PurchaseOrderId] = @PurchaseOrderId AND [PurchaseOrderPartRecordId] = @SelectedPurchaseOrderPartRecordId

                        UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @CNCurrentNumber_NS WHERE CodeTypeId = 9 AND MasterCompanyId = @MasterCompanyId;

                        DECLARE @StkManagementStructureModuleId_NS BIGINT = 2;
                        DECLARE @ManagementStructureEntityId_NS BIGINT = 0;

                        SELECT @ManagementStructureEntityId_NS = [ManagementStructureId] FROM DBO.Stockline WITH (NOLOCK) WHERE StocklineId = @NewStocklineId_NS;

                        EXEC dbo.[USP_SaveSLMSDetails] @StkManagementStructureModuleId_NS, @NewStocklineId_NS, @ManagementStructureEntityId_NS, @MasterCompanyId, @UpdatedBy;

							IF (@IsSerializedPart = 0 AND @SelectedIsSameDetailsForAllParts_NS = 1)
							BEGIN
								DECLARE @LoopID_QtyToReceive_NS INT = 0;
                            IF OBJECT_ID(N'tempdb..#StocklineDraftForQtyToReceive_NS') IS NOT NULL
								BEGIN
                                DROP TABLE #StocklineDraftForQtyToReceive_NS
								END

                            CREATE TABLE #StocklineDraftForQtyToReceive_NS
								(
									ID BIGINT NOT NULL IDENTITY,
                                [StocklineDraftId] [bigint] NULL
								)

                            INSERT INTO #StocklineDraftForQtyToReceive_NS
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

                            SELECT @LoopID_QtyToReceive_NS = MAX(ID) FROM #StocklineDraftForQtyToReceive_NS;

								DECLARE @TotalQtyToTraverse_NS [decimal](18,6) = 0;

								SET @TotalQtyToTraverse_NS = @QtyToReceive;

								WHILE (@LoopID_QtyToReceive_NS > 0)
								BEGIN
									IF (@TotalQtyToTraverse_NS > 0)
									BEGIN
                                    DECLARE @CurrentStocklineDraftId_NS BIGINT = 0;

                                    SELECT @CurrentStocklineDraftId_NS = StocklineDraftId
                                    FROM #StocklineDraftForQtyToReceive_NS
										WHERE ID = @LoopID_QtyToReceive_NS;

                                    UPDATE dbo.StocklineDraft
                                    SET StockLineId = @NewStocklineId_NS,
                                        StockLineNumber = @StockLineNumber_NS,
                                        ForStockQty = @QtyAdded_NS --@QtyToReceive            
                                    WHERE StockLineDraftId = @CurrentStocklineDraftId_NS;

										SET @TotalQtyToTraverse_NS = @TotalQtyToTraverse_NS - 1;
									END

									SET @LoopID_QtyToReceive_NS = @LoopID_QtyToReceive_NS - 1;
								END

								IF ((@MainPOPartBackOrderQty - @QtyToReceive) > 0)
								BEGIN
                                SET @StockLineNumber_NS = NULL;
                                SET @NewStocklineId_NS = NULL;
								END

								UPDATE dstl
                            SET dstl.StockLineId = @NewStocklineId_NS,
                                dstl.StockLineNumber = @StockLineNumber_NS,
                                dstl.ControlNumber = @ControlNumber_NS,
                                dstl.ReceiverNumber = @ReceiverNumber_NS
                            FROM DBO.StocklineDraft dstl
                            WHERE StockLineDraftId = @SelectedStockLineDraftId_NS;

                            UPDATE DBO.StocklineDraft
                            SET StockLineId = 0
                            WHERE StockLineDraftId = @SelectedStockLineDraftId_NS
										AND isSerialized = 0
										AND IsSameDetailsForAllParts = 1
										AND IsParent = 1;
							END
						ELSE IF(@IsSerializedPart = 0 AND @SelectedIsSameDetailsForAllParts_NS = 0)
						BEGIN
							UPDATE dstl
                            SET dstl.StockLineId = @NewStocklineId_NS,
                                dstl.StockLineNumber = @StockLineNumber_NS,
                                dstl.ControlNumber = @ControlNumber_NS,
                                dstl.ReceiverNumber = @ReceiverNumber_NS, ForStockQty = @QtyAdded_NS 
                            FROM DBO.StocklineDraft dstl
                            WHERE StockLineDraftId = @SelectedStockLineDraftId_NS;
						END
							ELSE
							BEGIN
                            UPDATE dstl
                            SET dstl.StockLineId = @NewStocklineId_NS,
                                dstl.StockLineNumber = @StockLineNumber_NS,
                                dstl.ControlNumber = @ControlNumber_NS,
                                dstl.ReceiverNumber = @ReceiverNumber_NS
                            FROM DBO.StocklineDraft dstl
                            WHERE StockLineDraftId = @SelectedStockLineDraftId_NS;
                        END

						/* Update ItemMasterPurchaseSale*/
						IF EXISTS
						(
							SELECT TOP 1
								1
							FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
							WHERE POP.PurchaseOrderId = @PurchaseOrderId
								  AND POP.ItemMasterId = @ItemMasterId_NS
								  AND POP.ConditionId = @ConditionId_NS
						)
						BEGIN
							DECLARE @POP_UnitCost_NS DECIMAL(18, 2) = 0;
							DECLARE @POP_VendorListPrice_NS DECIMAL(18, 2) = 0;
							DECLARE @POP_DiscountPerUnit_NS DECIMAL(18, 2) = 0;
							DECLARE @POP_DiscountPercent_NS BIGINT = 0;
							DECLARE @POP_DiscountPercentValue_NS BIGINT = 0;
							DECLARE @POP_ConditionId_NS BIGINT = 0;

							DECLARE @PP_VendorListPrice_NS DECIMAL(18, 2) = 0;
							DECLARE @PP_PurchaseDiscAmount_NS DECIMAL(18, 2) = 0;
							DECLARE @PP_UnitPurchasePrice_NS DECIMAL(18, 2) = 0;
							DECLARE @PP_PurchaseDiscPerc_NS DECIMAL(18, 2) = 0;

							DECLARE @PP_MarkUpPerc_NS BIGINT = 0;
							DECLARE @PP_newUnitSalePrice_NS DECIMAL(18, 2) = 0;
							DECLARE @PP_newMarkUpAmount_NS DECIMAL(18, 2) = 0;
							DECLARE @PP_FlatPrice_NS DECIMAL(18, 2) = 0;
							DECLARE @SalePriceSelectId_NS INT = (SELECT ItemMasterPurchaseSaleMasterId FROM [dbo].ItemMasterPurchaseSaleMaster WHERE [Name] = 'Flat');

							SELECT @POP_UnitCost_NS = POP.UnitCost,
								   @POP_VendorListPrice_NS = POP.VendorListPrice,
								   @POP_DiscountPerUnit_NS = POP.DiscountPerUnit,
								   @POP_DiscountPercent_NS = POP.DiscountPercent,
								   @POP_DiscountPercentValue_NS = POP.DiscountPercentValue,
								   @POP_ConditionId_NS = POP.ConditionId,
								   @PP_FlatPrice_NS = IMP.SP_FSP_FlatPriceAmount,
								   @PP_MarkUpPerc_NS = p.PercentValue

							FROM dbo.PurchaseOrderPart POP WITH (NOLOCK)
							LEFT JOIN dbo.ItemMasterPurchaseSale IMP WITH (NOLOCK) ON POP.ItemMasterId = IMP.ItemMasterId AND POP.ConditionId = IMP.ConditionId
							LEFT JOIN dbo.[Percent] P WITH (NOLOCK) ON P.PercentId = IMP.sP_CalSPByPP_MarkUpPercOnListPrice
							WHERE POP.PurchaseOrderId = @PurchaseOrderId
								  AND POP.ItemMasterId = @ItemMasterId_NS
								  AND POP.ConditionId = @ConditionId_NS;

							IF (@StkPurchaseOrderUnitCost_NS = @POP_UnitCost_NS)
							BEGIN
								SET @PP_VendorListPrice_NS = ISNULL(@POP_VendorListPrice_NS, 0);
								SET @PP_PurchaseDiscAmount_NS = ISNULL(@POP_DiscountPerUnit_NS, 0);
								SET @PP_UnitPurchasePrice_NS
									= (ISNULL(@POP_VendorListPrice_NS, 0) - ISNULL(@POP_DiscountPerUnit_NS, 0));
								SET @PP_PurchaseDiscPerc_NS = @POP_DiscountPercent_NS;
							END
							ELSE
							BEGIN
								DECLARE @disamt_NS AS DECIMAL(18, 2) = 0;
								SET @disamt_NS = ((ISNULL(@StkPurchaseOrderUnitCost_NS, 0) * (ISNULL(@POP_DiscountPercentValue_NS, 0))) / 100);

								SET @PP_VendorListPrice_NS = ISNULL(@StkPurchaseOrderUnitCost_NS, 0) + @disamt_NS;
								SET @PP_PurchaseDiscAmount_NS = ISNULL(@disamt_NS, 0);
								SET @PP_UnitPurchasePrice_NS = ISNULL(@StkPurchaseOrderUnitCost_NS, 0);
								SET @PP_PurchaseDiscPerc_NS = @POP_DiscountPercent_NS;
							END
							IF(ISNULL(@PP_MarkUpPerc_NS , 0) > 0)
							BEGIN
								SET @PP_newMarkUpAmount_NS =  ((ISNULL(@PP_UnitPurchasePrice_NS, 0) * ISNULL(@PP_MarkUpPerc_NS, 0)) / 100);
								SET @PP_newUnitSalePrice_NS = (ISNULL(@PP_newMarkUpAmount_NS, 0)  + ISNULL(@PP_UnitPurchasePrice_NS, 0));
							END
							ELSE
							BEGIN
								SET @PP_newUnitSalePrice_NS = ISNULL(@PP_UnitPurchasePrice_NS, 0) + ISNULL(@PP_FlatPrice_NS, 0);
							END


							IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.ItemMasterPurchaseSale IMPS WITH (NOLOCK) WHERE IMPS.ItemMasterId = @ItemMasterId_NS AND IMPS.ConditionId = @ConditionId_NS)
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
									@ItemMasterId_NS,
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
									@PP_VendorListPrice_NS,
									GETUTCDATE(),
									@PP_PurchaseDiscPerc_NS,
									@PP_PurchaseDiscAmount_NS,
									CAST(GETUTCDATE() as date),
									@PP_UnitPurchasePrice_NS,
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
									@POP_ConditionId_NS,
									@SalePriceSelectId_NS,
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
									  AND POP.ItemMasterId = @ItemMasterId_NS
									  AND POP.ConditionId = @ConditionId_NS;

								EXEC dbo.UpdateItemMasterPurchaseSaleDetails @ItemMasterId_NS;

								DECLARE @ItemMasterPurchaseSaleId_NS  BIGINT = 0;

								SELECT @ItemMasterPurchaseSaleId_NS =  ItemMasterPurchaseSaleId FROM [dbo].[ItemMasterPurchaseSale] WITH (NOLOCK)
								WHERE ItemMasterId = @ItemMasterId_NS 
								AND ConditionId = @ConditionId_NS;

								EXEC USP_AddUpdatePriceMasterHistory @ItemMasterPurchaseSaleId_NS , @ReceivingPurchaseOrderModule_NS , @MasterCompanyId , @PurchaseOrderId;
							END
							ELSE
							BEGIN
								UPDATE IMPS
								SET IMPS.PP_VendorListPrice = @PP_VendorListPrice_NS,
									IMPS.PP_PurchaseDiscAmount = @PP_PurchaseDiscAmount_NS,
									IMPS.PP_UnitPurchasePrice = @PP_UnitPurchasePrice_NS,
									IMPS.PP_PurchaseDiscPerc = @PP_PurchaseDiscPerc_NS,

									IMPS.SP_CalSPByPP_MarkUpAmount = @PP_newMarkUpAmount_NS,
									IMPS.SP_CalSPByPP_UnitSalePrice = @PP_newUnitSalePrice_NS,

									IMPS.UpdatedBy = @UpdatedBy,
									IMPS.UpdatedDate = GETUTCDATE()
								FROM DBO.ItemMasterPurchaseSale IMPS
								WHERE IMPS.ItemMasterId = @ItemMasterId_NS AND IMPS.ConditionId = @ConditionId_NS;

								SELECT @ItemMasterPurchaseSaleId_NS =  ItemMasterPurchaseSaleId FROM [dbo].[ItemMasterPurchaseSale] WITH (NOLOCK)
								WHERE ItemMasterId = @ItemMasterId_NS 
								AND ConditionId = @ConditionId_NS;

								EXEC USP_AddUpdatePriceMasterHistory @ItemMasterPurchaseSaleId_NS , @ReceivingPurchaseOrderModule_NS , @MasterCompanyId, @PurchaseOrderId;
							END
						END

						/*******Due to not showing PO Part while receive reconciliation (When QTY is more than 500)********/
						IF(@QtyAdded_NS > @maxQtyLimit)
						BEGIN
							  UPDATE dbo.StocklineDraft SET StockLineId = @NewStocklineId_NS, StockLineNumber = @StockLineNumber_NS,	ControlNumber =@ControlNumber_NS 
									WHERE PurchaseOrderId = @PurchaseOrderId AND PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId AND IsParent = 1 AND isSerialized = 0
						END

						EXEC UpdateStocklineColumnsWithId @NewStocklineId_NS;

						SET @LoopID = @LoopID - 1;
					END

						UPDATE Stk
					SET Stk.IsParent = 0
					FROM DBO.StocklineDraft Stk WHERE ISNULL(Stk.IsParent, 0) = 1 AND ISNULL(Stk.isSerialized, 0) = 0 AND Stk.StockLineNumber IS NOT NULL AND Stk.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartRecordId;
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
                    FROM DBO.StocklineDraft dstl WITH (NOLOCK)
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

			SELECT @StkCount = COUNT(StockLineId) FROM @p2;
			SELECT @AstInvCount = COUNT(StockLineId) FROM @p3;
			SELECT @NonStkCount = COUNT(StockLineId) FROM @p4;
			/* Accounting Entry For StockLine*/
			IF(@StkCount > 0)
			BEGIN
				EXEC dbo.usp_PostCreateStocklineBatchDetails @tbl_PostStocklineBatchType = @p2, @MstCompanyId = @MasterCompanyId, @updatedByName = @UpdatedBy;
			END

			/* Accounting Entry For AssetInventory*/
			IF(@AstInvCount > 0)
			BEGIN
				EXEC dbo.usp_PostCreateStocklineBatchDetails @tbl_PostStocklineBatchType = @p3, @MstCompanyId = @MasterCompanyId, @updatedByName = @UpdatedBy;
			END

			/* Accounting Entry For NonStock*/
			IF(@NonStkCount > 0)
			BEGIN
				EXEC dbo.usp_PostCreateStocklineBatchDetails @tbl_PostStocklineBatchType = @p4, @MstCompanyId = @MasterCompanyId, @updatedByName = @UpdatedBy;
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
                [QuantityOrdered] [decimal](18,6) NULL,
				[QuantityReceived] [decimal](18,6) NULL
            )

            INSERT INTO #POParts ([PurchaseOrderId], [PurchaseOrderPartRecordId], [QuantityOrdered],[QuantityReceived])
            --SELECT [PurchaseOrderId], [PurchaseOrderPartRecordId], [QuantityOrdered] FROM DBO.PurchaseOrderPart WITH (NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId;
			SELECT [PurchaseOrderId],[PurchaseOrderPartRecordId],[QuantityOrdered],ISNULL([QuantityReceived],0) FROM [dbo].[PurchaseOrderPart] P WITH(NOLOCK)
			WHERE P.[PurchaseOrderId] = @PurchaseOrderId AND 
			    ((P.ParentId IS NOT NULL AND EXISTS (SELECT 1 FROM [dbo].[PurchaseOrderPart] C WITH(NOLOCK) WHERE C.PurchaseOrderId = P.PurchaseOrderId AND C.ParentId IS NOT NULL))
			  OR (P.ParentId IS NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[PurchaseOrderPart] C WITH(NOLOCK) WHERE C.PurchaseOrderId = P.PurchaseOrderId AND C.ParentId IS NOT NULL)));
			  	
            SELECT @POPartLoopID = MAX(ID) FROM #POParts;

            DECLARE @MainQuantityOrdered [decimal](18,6) = 0;
            DECLARE @MainStkQuantity [decimal](18,6) = 0;

            WHILE (@POPartLoopID > 0)
            BEGIN
                DECLARE @PurchaseOrderPartRecordId BIGINT = 0;
                DECLARE @QuantityOrdered [decimal](18,6) = 0;
                DECLARE @StkQuantity [decimal](18,6) = 0;
                DECLARE @StkAssetQuantity [decimal](18,6) = 0;
                DECLARE @NonStkInventoryQuantity [decimal](18,6) = 0;

                SELECT @QuantityOrdered = [QuantityOrdered], @PurchaseOrderPartRecordId = [PurchaseOrderPartRecordId] FROM #POParts WHERE ID = @POPartLoopID;

				SELECT @StkQuantity = [QuantityReceived], @PurchaseOrderPartRecordId = [PurchaseOrderPartRecordId] FROM #POParts WHERE ID = @POPartLoopID;

                --SELECT @StkQuantity = ISNULL(SUM([Quantity]), 0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND IsParent = 1;
                
				--SELECT @StkAssetQuantity = ISNULL(SUM(Qty), 0) FROM DBO.AssetInventory Stk WITH (NOLOCK) WHERE Stk.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId;

				--SELECT @NonStkInventoryQuantity = ISNULL(SUM(Quantity), 0) FROM DBO.NonStockInventory NonStk WITH (NOLOCK) WHERE NonStk.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId;

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
				@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PurchaseOrderId, '') AS VARCHAR(100)),
                @ApplicationName VARCHAR(100) = 'PAS'
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