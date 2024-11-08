/*************************************************************           
 ** File:   [USP_Lot_GetAllLotViewsByLotId_Filter]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to Get all the views of LOT(All PN, PN IN Stock,PN SOLD, PN REPAIRED etc...
 ** Purpose:         
 ** Date:   12/07/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   ----------  -----------	--------------------------------          
    1    12/07/2023  Rajesh Gami	Created
	2	 02/1/2024	 AMIT GHEDIYA	added isperforma Flage for SO
	3    10/16/2024	 Abhishek Jirawla	Implemented the new tables for SalesOrder related tables
     
-- EXEC USP_Lot_GetAllLotViewsByLotId_Filter 7,'ViewAllPN',1
-- EXEC USP_Lot_GetAllLotViewsByLotId 67,'ViewAllPN',1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_GetAllLotViewsByLotId_Filter]
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@StatusId int = 1,
	@Status varchar(50) = '',
	@GlobalFilter varchar(50) = '',
	@LotNumber varchar(100) = '',  --R
	@LotName varchar(100) = '', --R
	@PartNumber varchar(100) = NULL,
	@Description varchar(200) = NULL,
	@SerialNum varchar(100) = NULL,
	@StkLineNum varchar(100) = NULL,
	@ItemClassfication varchar(100) = NULL, 
	@ItemGroup varchar(100) = NULL, 
	@Condition varchar(100) = NULL,
	@Uom varchar(100) = NULL,
	@Qty int = NULL, 
	@QtyOnHand int = NULL,
	@QtyRes int = NULL,
	@QtyIss int = NULL,
	@QtyAvailable int = NULL,
	@TransUnitCost decimal(18,2) = NULL,
	@UnitCost decimal(18,2) = NULL,
	@ExtCost decimal(18,2) = NULL,
	@RepairCost decimal(18,2) = NULL,
	@TotalCost decimal(18,2) = NULL,
	@UnitSalePrice decimal(18,2) = NULL,
	@ExtPrice decimal(18,2) = NULL,
	@MarginAmt decimal(18,2) = NULL,
	@Margin decimal(18,2) = NULL,
	@HowAcquired varchar(100) = NULL,
	@AcquiredRef varchar(100) = NULL,
	@PoNum varchar(100) = NULL,
	@RoNum varchar(100) = NULL,
	@WoNum varchar(100) = NULL,
	@QuoteNum varchar(100) = NULL,
	@SoNum varchar(100) = NULL,
	@InvoiceNum varchar(100) = NULL,
	@Vendor varchar(100) = NULL,
	@VendorCode varchar(100) = NULL,
	@ReferenceNum varchar(100) = NULL, --R
	@CustomerName varchar(100) = NULL,
	@InvoiceDate  datetime = NULL,
	@LastMSLevel varchar(100) = NULL,
	@Memo varchar(100) = NULL,
	@Cost decimal(18,2) = NULL,
	@ControlNumber  varchar(50) = NULL, --R
	@IdNumber  varchar(50) = NULL, --R
	@ManufacturerName  varchar(100) = NULL, --R
	@ItemType  varchar(100) = NULL, --R
	@PercentValue decimal(18,2) = NULL, --R
	@TraceableToName  varchar(50) = NULL, --R
	@TaggedByName  varchar(50) = NULL, --R
	@TagDate  datetime = NULL, --R
	@InitialPOCost decimal(18,2) = NULL, --R
	@StocklineTotalCost decimal(18,2) = NULL, --R
	@RemainStocklineCost decimal(18,2) = NULL, --R
	@Adjustment decimal(18,2) = NULL, --R
	@Site varchar(100) = NULL,
	@Warehouse varchar(100) = NULL,
	@Location varchar(100) = NULL,
	@Shelf varchar(100) = NULL,
	@Bin varchar(100) = NULL,
	@UnitPrice decimal(18,2) = NULL,
	@ExtendedPrice decimal(18,2) = NULL,
	@TotalDirectCost decimal(18,2) = NULL,
	@PoDate  datetime = NULL,
	@FreightCost decimal(18,2) = NULL,
	@ChargesCost decimal(18,2) = NULL,
	@CommissionExpense decimal(18,2) = NULL,
	@HowCalculate varchar(200) = NULL,
	@LotId bigint, 
	@Type VARCHAR(50) = '',
	@IsAvailableQty BIT = 0,
	@MasterCompanyId int
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;


		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN		
				DECLARE @Count Int;
				DECLARE @RecordFrom int, @AvailableQty int = 0;
				SET @RecordFrom = (@PageNumber-1)*@PageSize;

				IF @IsAvailableQty = 1 AND UPPER(@Type) = UPPER('PNInStockView')
				BEGIN
					SET @AvailableQty = 1
				END
				IF @SortColumn IS NULL
				BEGIN
					SET @SortColumn = Upper('CreatedDate')
					SET @SortOrder = -1
				END 
				ELSE
				BEGIN 
					Set @SortColumn = Upper(@SortColumn)
				END

			DECLARE @LOT_PO_Type VARCHAR(100) = 'PO'; DECLARE @LOT_RO_Type VARCHAR(100)= 'RO'; DECLARE @LOT_SO_Type VARCHAR(100)= 'SO';	DECLARE @LOT_WO_Type VARCHAR(100)= 'WO';
			DECLARE @LOT_TransIn_LOT VARCHAR(100) = 'Trans In(Lot)'; DECLARE @LOT_TransIn_PO VARCHAR(100) = 'Trans In(PO)';	DECLARE @LOT_TransIn_RO VARCHAR(100) = 'Trans In(RO)';
			DECLARE @LOT_TransIn_SO VARCHAR(100) = 'Trans In(SO)'; DECLARE @LOT_TransIn_WO VARCHAR(100) = 'Trans In(WO)'; DECLARE @LOT_TransOut_LOT VARCHAR(100) = 'Trans Out(Lot)';
			DECLARE @LOT_TransOut_PO VARCHAR(100) = 'Trans Out(PO)'; DECLARE @LOT_TransOut_RO VARCHAR(100) = 'Trans Out(RO)';
			DECLARE @LOT_TransOut_SO VARCHAR(100) = 'Trans Out(SO)'; DECLARE @LOT_TransOut_WO VARCHAR(100) = 'Trans Out(WO)'; 
			DECLARE @LotTransIn VARCHAR(100) = 'Trans In',@LotTransOut VARCHAR(100) = 'Trans Out', @LotPO VARCHAR(100) = 'Purchase Order',@LotRO VARCHAR(100) = 'Repair Order',@LotSO VARCHAR(100) = 'Sales Order', @LotWO VARCHAR(100) = 'Work Order';
			DECLARE @AppModuleId INT = 0;
			SELECT @AppModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Lot';

			DECLARE @AppModuleCustomerId INT = 0;
			DECLARE @AppModuleVendorId INT = 0;
			DECLARE @AppModuleCompanyId INT = 0;
			DECLARE @AppModuleOthersId INT = 0;
			SELECT @AppModuleCustomerId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Customer';
			SELECT @AppModuleVendorId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Vendor';
			SELECT @AppModuleCompanyId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Company';
			SELECT @AppModuleOthersId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Others';


			SELECT DISTINCT SL.StockLineId,SL.[PartNumber],SL.[StockLineNumber],SL.[StocklineMatchKey],SL.[ControlNumber],SL.[ItemMasterId] ,SL.[Quantity],SL.[ConditionId],SL.[SerialNumber],SL.[ShelfLife],SL.[ShelfLifeExpirationDate],SL.[WarehouseId] ,SL.[LocationId],SL.[ObtainFrom],SL.[Owner],SL.[TraceableTo],SL.[ManufacturerId],SL.[Manufacturer],SL.[ManufacturerLotNumber],SL.[ManufacturingDate],SL.[ManufacturingBatchNumber],SL.[PartCertificationNumber]
           ,SL.[CertifiedBy],SL.[CertifiedDate],SL.[TagDate],SL.[TagType],SL.[CertifiedDueDate],SL.[CalibrationMemo],SL.[OrderDate] ,SL.[PurchaseOrderId],SL.[PurchaseOrderUnitCost],SL.[InventoryUnitCost],SL.[RepairOrderId] ,SL.[RepairOrderUnitCost],SL.[ReceivedDate],SL.[ReceiverNumber],SL.[ReconciliationNumber],SL.[UnitSalesPrice],SL.[CoreUnitCost] ,SL.[GLAccountId],SL.[AssetId],SL.[IsHazardousMaterial],SL.[IsPMA],SL.[IsDER],SL.[OEM]
           ,SL.[Memo],SL.[ManagementStructureId],SL.[LegalEntityId],SL.[MasterCompanyId],SL.[CreatedBy] ,SL.[UpdatedBy],SL.[CreatedDate],SL.[UpdatedDate],SL.[isSerialized],SL.[ShelfId],SL.[BinId],SL.[SiteId],SL.[ObtainFromType] ,SL.[OwnerType],SL.[TraceableToType],SL.[UnitCostAdjustmentReasonTypeId] ,SL.[UnitSalePriceAdjustmentReasonTypeId] ,SL.[IdNumber],SL.[QuantityToReceive] ,SL.[PurchaseOrderExtendedCost] ,SL.[ManufacturingTrace]
           ,SL.[ExpirationDate] ,SL.[AircraftTailNumber] ,SL.[ShippingViaId] ,SL.[EngineSerialNumber] ,SL.[QuantityRejected] ,SL.[PurchaseOrderPartRecordId] ,SL.[ShippingAccount],SL.[ShippingReference],SL.[TimeLifeCyclesId] ,SL.[TimeLifeDetailsNotProvided],SL.[WorkOrderId],SL.[WorkOrderMaterialsId] ,SL.[QuantityReserved] ,SL.[QuantityTurnIn] ,SL.[QuantityIssued] ,SL.[QuantityOnHand],SL.[QuantityAvailable] ,SL.[QuantityOnOrder],SL.[QtyReserved]
           ,SL.[QtyIssued],SL.[BlackListed],SL.[BlackListedReason],SL.[Incident],SL.[IncidentReason] ,SL.[Accident],SL.[AccidentReason],SL.[RepairOrderPartRecordId],SL.[isActive],SL.[isDeleted],SL.[WorkOrderExtendedCost],SL.[RepairOrderExtendedCost],SL.[IsCustomerStock],SL.[EntryDate],SL.[LotCost],SL.[NHAItemMasterId] ,SL.[TLAItemMasterId] ,SL.[ItemTypeId],SL.[AcquistionTypeId] ,SL.[RequestorId],SL.[LotNumber] ,SL.[LotDescription] ,SL.[TagNumber] ,SL.[InspectionBy]
           ,SL.[InspectionDate],SL.[VendorId],SL.[IsParent],SL.[ParentId] ,SL.[IsSameDetailsForAllParts] ,SL.[WorkOrderPartNoId] ,SL.[SubWorkOrderId],SL.[SubWOPartNoId],SL.[IsOemPNId] ,SL.[PurchaseUnitOfMeasureId],SL.[ObtainFromName],SL.[OwnerName],SL.[TraceableToName] ,SL.[Level1] ,SL.[Level2] ,SL.[Level3] ,SL.[Level4] ,SL.[Condition] ,SL.[GlAccountName] ,SL.[Site] ,SL.[Warehouse] ,SL.[Location],SL.[Shelf] ,SL.[Bin] ,SL.[UnitOfMeasure]
           ,SL.[WorkOrderNumber],SL.[itemGroup] ,SL.[TLAPartNumber] ,SL.[NHAPartNumber] ,SL.[TLAPartDescription],SL.[NHAPartDescription] ,SL.[itemType],SL.[CustomerId],SL.[CustomerName],SL.[isCustomerstockType],SL.[PNDescription],SL.[RevicedPNId],SL.[RevicedPNNumber],SL.[OEMPNNumber],SL.[TaggedBy],SL.[TaggedByName],SL.[UnitCost],SL.[TaggedByType],SL.[TaggedByTypeName],SL.[CertifiedById] ,SL.[CertifiedTypeId],SL.[CertifiedType],SL.[CertTypeId]
           ,SL.[CertType],SL.[TagTypeId],SL.[IsFinishGood],SL.[IsTurnIn],SL.[IsCustomerRMA],SL.[RMADeatilsId],SL.[DaysReceived],SL.[ManufacturingDays],SL.[TagDays],SL.[OpenDays],SL.[ExchangeSalesOrderId],SL.[RRQty],SL.[SubWorkOrderNumber] ,SL.[IsManualEntry],SL.[WorkOrderMaterialsKitId],SL.[LotId],SL.[IsLotAssigned],SL.[LOTQty],SL.[LOTQtyReserve],SL.[OriginalCost],SL.[POOriginalCost],SL.[ROOriginalCost] ,SL.[VendorRMAId]
           ,SL.[VendorRMADetailId] ,SL.[LotMainStocklineId],SL.[IsFromInitialPO],SL.[LotSourceId],SL.[Adjustment]
				INTO #commonTemp FROM DBO.LotTransInOutDetails ltin WITH(NOLOCK) 
				INNER JOIN DBO.Stockline sl WITH(NOLOCK) on ltin.StockLineId = sl.StockLineId WHERE ltin.LotId = @LotId

			IF(UPPER(@Type) = UPPER('ViewAllPN'))
			BEGIN
				;WITH Result AS (SELECT 
				 lot.LotId
				,lot.LotNumber
				,lot.LotName
				,ISNULL(SL.PurchaseOrderId,0) PurchaseOrderId
				,ISNULL(SL.RepairOrderId,0) RepairOrderId
				,ISNULL(SL.WorkOrderId,0) WorkOrderId
				,ISNULL(0,0) QuoteId
				,ISNULL(so.SalesOrderId,0) SalesOrderId
				,ISNULL(ltin.LotTransInOutId,0) LotTransInOutId
				,ISNULL(ltCal.LotCalculationId,0) LotCalculationId
				,im.PartNumber
				,im.PartDescription AS Description
				,sl.StockLineId
				,sl.SerialNumber AS SerialNum
				,sl.StockLineNumber StkLineNum
				,ic.ItemClassificationCode ItemClassfication
				,ig.Description AS ItemGroup
				,c.Description AS Condition
				,UPPER(sl.UnitOfMeasure) AS Uom
				,(CASE WHEN UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransOut_SO,' ','')) THEN 'SOLD'
					   WHEN UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransOut_RO,' ','')) THEN 'RO Created'
					   WHEN UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransIn_RO,' ','')) THEN 'RO Completed'
					ELSE UPPER(ltCal.Type) END) Status
				,ltCal.Qty AS Qty
				,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
				,ISNULL(sl.QuantityReserved, 0) AS QtyRes
				,ISNULL(sl.QuantityIssued, 0) AS QtyIss
				,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
				,(CASE  WHEN REPLACE(ltCal.Type,' ','') =REPLACE(@LOT_TransOut_SO,' ','') OR REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_LOT,' ','') OR  REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_RO,' ','') THEN ltCal.TransferredOutCost ELSE ltCal.TransferredInCost END) TransUnitCost
				,ISNULL(sl.PurchaseOrderUnitCost,0.00) UnitCost
				--,(ISNULL(sl.PurchaseOrderUnitCost,0) * ltCal.Qty) ExtCost
				,(ISNULL(sl.UnitCost,0) * ltCal.Qty) ExtCost
				,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				,ISNULL(sl.UnitCost,0) AS TotalCost
				,ltCal.SalesUnitPrice UnitSalesPrice
				,ltCal.ExtSalesUnitPrice ExtPrice
				,ltCal.MarginAmount MarginAmt
				,CASE WHEN ISNULL(ltCal.ExtSalesUnitPrice,0) = 0 THEN 0 ELSE CONVERT(DECIMAL(10,2),((100 * ISNULL(ltCal.MarginAmount,0))/ISNULL(ltCal.ExtSalesUnitPrice,1)))END Margin
				--,ltCal.Margin Margin
				,(CASE WHEN REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_TransIn_LOT,' ','')  THEN @LotTransIn 
					    WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_LOT,' ','')  THEN @LotTransOut
						WHEN REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_TransIn_PO,' ','')  THEN @LotPO
					   WHEN REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_TransIn_RO,' ','')  OR REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_RO,' ','') THEN @LotRO 
					   WHEN REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_TransOut_SO,' ','')  THEN @LotSO 
					   WHEN REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_TransIn_WO,' ','')  THEN @LotWO 
				ELSE '' END) HowAcquired
				,(CASE WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransIn_LOT,' ','') OR REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_LOT,' ','') THEN sl.StockLineNumber 
					   WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransIn_PO,' ','')  THEN (CASE WHEN ISNULL(SL.PurchaseOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 pod.PurchaseOrderNumber FROM dbo.PurchaseOrder pod WITH(NOLOCK) WHERE pod.PurchaseOrderId = sl.PurchaseOrderId) END)
					   WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransIn_RO,' ','')  OR REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_RO,' ','') THEN (CASE WHEN ISNULL(SL.RepairOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 rod.RepairOrderNumber FROM dbo.RepairOrder rod WITH(NOLOCK) WHERE rod.RepairOrderId = sl.RepairOrderId) END) 
					   WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_SO,' ','')  THEN so.SalesOrderNumber 
					   WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransIn_WO,' ','')  THEN (CASE WHEN ISNULL(SL.WorkOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 wod.WorkOrderNum FROM dbo.WorkOrder wod WITH(NOLOCK) WHERE wod.WorkOrderId = sl.WorkOrderId) END)
				ELSE '' END) AS AcquiredRef
				--,po.PurchaseOrderNumber PoNum
				,(CASE WHEN ISNULL(SL.PurchaseOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 pod.PurchaseOrderNumber FROM dbo.PurchaseOrder pod WITH(NOLOCK) WHERE pod.PurchaseOrderId = sl.PurchaseOrderId) END) PoNum
				--,ro.RepairOrderNumber RoNum
				,(CASE WHEN ISNULL(SL.RepairOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 rod.RepairOrderNumber FROM dbo.RepairOrder rod WITH(NOLOCK) WHERE rod.RepairOrderId = sl.RepairOrderId) END) RoNum
				--,wo.WorkOrderNum WoNum
				,(CASE WHEN ISNULL(SL.WorkOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 wod.WorkOrderNum FROM dbo.WorkOrder wod WITH(NOLOCK) WHERE wod.WorkOrderId = sl.WorkOrderId) END) WoNum
				,''  QuoteNum
				,So.SalesOrderNumber SoNum
				,sobi.InvoiceNo InvoiceNum 
				,ven.VendorName Vendor 
				,ISNULL(ven.VendorCode,'')VendorCode
				,ISNULL(ven.VendorId,0) VendorId
				,lot.ReferenceNumber ReferenceNum
				,sl.CustomerName
				,'' Co
				,'' Bu
				,'' Div
				,'' Dept
				,sl.Memo
				,UPPER(MSD.LastMSLevel)	LastMSLevel
				,UPPER(MSD.AllMSlevels) AllMSlevels
				,ISNULL(so.CustomerId,0) SoCustomerId
				,ltCal.CreatedDate
				,sl.ConditionId
				,sl.ItemMasterId
				,sl.CustomerId
				,sl.ControlNumber
				,sl.IdNumber
					,(CASE WHEN SL.TraceableToType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.[TraceableTo] )
						    WHEN SL.TraceableToType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleOthersId THEN SL.[TraceableToName]
					   END) AS [TraceableToName],
				(CASE WHEN SL.TaggedByType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.TaggedBy )
						    WHEN SL.TaggedByType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleOthersId THEN SL.[TaggedByName]
					   END) [TaggedByName] 
				,sl.TagDate
				,sl.TraceableTo
				,sl.TraceableToType
				,sl.TaggedBy
				,sl.TaggedByType
				,ISNULL(lot.InitialPOCost,0)InitialPOCost
				,ISNULL(lot.StocklineTotalCost,0)StocklineTotalCost
				,(ISNULL(lot.InitialPOCost,0) - ISNULL(lot.StocklineTotalCost,0))AS RemainStocklineCost
				,Sl.LotSourceId
				,Sl.IsFromInitialPO
				,SL.LotMainStocklineId
		        ,(ISNULL(sl.Adjustment,0) * ISNULL(sl.QuantityOnHand, 0)) Adjustment
				,im.ManufacturerName
				,sobi.InvoiceDate InvoiceDate,
				(CASE WHEN ISNULL(lot.InitialPOId,0) != 0 AND ISNULL(lot.InitialPOId,0) =ISNULL(SL.PurchaseOrderId,0) THEN 1 ELSE 0 END) As IsInitialPO
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN #commonTemp sl on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 Inner JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on ltCal.ReferenceId = so.SalesOrderId AND UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransOut_SO,' ',''))
					 LEFT JOIN DBO.SalesOrderPartV1 sop WITH(NOLOCK) on ltcal.ChildId = sop.SalesOrderPartId AND so.SalesOrderId = sop.SalesOrderId
					 LEFT JOIN DBO.SalesOrderBillingInvoicing sobi on so.SalesOrderId = sobi.SalesOrderId AND sobi.MasterCompanyId = so.MasterCompanyId AND ISNULL(sobi.IsProforma,0) = 0
					 LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii on sop.SalesOrderPartId = sobii.SalesOrderPartId AND sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobii.IsProforma,0) = 0
					 LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
					 LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	
				WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(*) AS totalItems FROM Result) 

				SELECT * INTO #TempResult FROM  Result
				WHERE
				 (
					(@GlobalFilter <>'' AND (
					(LotNumber LIKE '%' + @GlobalFilter + '%') OR
					(LotName LIKE '%' + @GlobalFilter + '%') OR
					(Partnumber LIKE '%' + @GlobalFilter + '%') OR
					([Description] LIKE '%' + @GlobalFilter + '%') OR
					(StkLineNum LIKE '%' + @GlobalFilter + '%') OR
					(SerialNum LIKE '%' + @GlobalFilter + '%') OR
					(ItemClassfication like '%' + @GlobalFilter + '%') OR
					(ItemGroup like '%' + @GlobalFilter + '%') OR
					(Condition LIKE '%' + @GlobalFilter + '%') OR
					(Uom LIKE '%' + @GlobalFilter + '%') OR
					(CAST(Qty AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyOnHand AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyRes AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyIss AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyAvailable AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(TransUnitCost LIKE '%' + @GlobalFilter + '%') OR
					(UnitCost LIKE '%' + @GlobalFilter + '%') OR
					(ExtCost like '%' + @GlobalFilter + '%') OR
					(RepairCost like '%' + @GlobalFilter + '%') OR
					(TotalCost like '%' + @GlobalFilter + '%') OR
					(UnitSalesPrice like '%' + @GlobalFilter + '%') OR
					(WONum like '%' + @GlobalFilter + '%') OR
					(ExtPrice like '%' + @GlobalFilter + '%') OR
					(MarginAmt like '%' + @GlobalFilter + '%') OR
					(Margin like '%' + @GlobalFilter + '%') OR
					(HowAcquired like '%' + @GlobalFilter + '%') OR
					(AcquiredRef like '%' + @GlobalFilter + '%') OR
					(PoNum like '%' + @GlobalFilter + '%') OR
					(RoNum like '%' + @GlobalFilter + '%') OR
					(WoNum like '%' + @GlobalFilter + '%') OR
					(QuoteNum like '%' + @GlobalFilter + '%') OR
					(SoNum like '%' + @GlobalFilter + '%') OR
					(Vendor like '%' + @GlobalFilter + '%') OR
					(CustomerName like '%' + @GlobalFilter + '%') OR
					(InvoiceNum like '%' + @GlobalFilter + '%') OR
					(LastMSLevel like '%' + @GlobalFilter + '%') OR			
					(Memo like '%' + @GlobalFilter + '%') OR	
					(VendorCode like '%' + @GlobalFilter + '%') OR
					(ReferenceNum like '%' + @GlobalFilter + '%') OR
					(ControlNumber like '%' + @GlobalFilter + '%') OR
					(IdNumber like '%' + @GlobalFilter + '%') OR
					(TraceableToName like '%' + @GlobalFilter + '%') OR
					(TaggedByName like '%' + @GlobalFilter + '%') OR
					(TagDate like '%' + @GlobalFilter + '%') OR
					(InvoiceDate like '%' + @GlobalFilter + '%') OR
					(InitialPOCost like '%' + @GlobalFilter + '%') OR
					(StocklineTotalCost like '%' + @GlobalFilter + '%') OR
					(RemainStocklineCost like '%' + @GlobalFilter + '%') OR
					(Adjustment like '%' + @GlobalFilter + '%') OR
						(ManufacturerName like '%' + @GlobalFilter + '%') OR	
					([Status] like '%' + @GlobalFilter + '%')
					))
					OR
					(@GlobalFilter = '' AND 
	
					(ISNULL(@Partnumber, '') = '' OR Partnumber LIKE '%' + @Partnumber + '%') AND
					(ISNULL(@Description, '') = '' OR [Description] LIKE '%' + @Description + '%') AND
					(ISNULL(@StkLineNum, '') = '' OR StkLineNum LIKE '%' + @StkLineNum + '%') AND
					(ISNULL(@SerialNum, '') = '' OR SerialNum LIKE '%' + @SerialNum + '%') AND
					(ISNULL(@Condition, '') = '' OR Condition LIKE '%' + @Condition + '%') AND
					(ISNULL(@Uom,'') ='' OR Uom LIKE '%' + @Uom + '%') AND
					(IsNull(@QtyOnHand, 0) = 0 OR CAST(QtyOnHand as VARCHAR(10)) like @QtyOnHand) AND
					(IsNull(@QtyRes, 0) = 0 OR CAST(QtyRes as VARCHAR(10)) like @QtyRes) AND
					(IsNull(@QtyIss, 0) = 0 OR CAST(QtyIss as VARCHAR(10)) like @QtyIss) AND
					(IsNull(@QtyAvailable, 0) = 0 OR CAST(QtyAvailable as VARCHAR(10)) like @QtyAvailable) AND

					(ISNULL(@TransUnitCost, 0) = 0 OR CAST(TransUnitCost as VARCHAR(10)) LIKE @TransUnitCost) AND
					(ISNULL(@UnitCost, 0) = 0 OR CAST(UnitCost as VARCHAR(10)) LIKE @UnitCost) AND
					(ISNULL(@ExtCost, 0) = 0 OR CAST(ExtCost as VARCHAR(10)) = @ExtCost) AND
					(ISNULL(@RepairCost, 0) = 0 OR CAST(RepairCost as VARCHAR(10)) = @RepairCost) AND
					(ISNULL(@TotalCost, 0) = 0 OR CAST(TotalCost as VARCHAR(10)) = @TotalCost) AND
					(ISNULL(@WONum, '') = '' OR WONum  like '%'+ @WONum + '%') AND
					--(ISNULL(@LastPODate,'') ='' OR CAST(LastPODate AS Date) = CAST(@LastPODate AS date)) AND
					(ISNULL(@ExtPrice, 0) = 0 OR CAST(ExtPrice as VARCHAR(10)) LIKE @ExtPrice) AND
					(ISNULL(@MarginAmt, 0) = 0 OR CAST(MarginAmt as VARCHAR(10)) LIKE @MarginAmt) AND
					(ISNULL(@Margin, 0) = 0 OR CAST(Margin as VARCHAR(10)) LIKE @Margin) AND

					(ISNULL(@HowAcquired,'') ='' OR HowAcquired LIKE '%' + @HowAcquired + '%') AND
					(ISNULL(@AcquiredRef,'') ='' OR AcquiredRef LIKE '%' + @AcquiredRef + '%') AND
					(ISNULL(@PoNum,'') ='' OR PoNum LIKE '%' + @PoNum + '%') AND
					(ISNULL(@RoNum,'') ='' OR RoNum LIKE '%' + @RoNum + '%') AND
					(ISNULL(@WoNum,'') ='' OR WoNum LIKE '%' + @WoNum + '%') AND
					(ISNULL(@QuoteNum,'') ='' OR QuoteNum LIKE '%' + @QuoteNum + '%') AND
					(ISNULL(@SoNum,'') ='' OR SoNum LIKE '%' + @SoNum + '%') AND
					(ISNULL(@Vendor,'') ='' OR Vendor LIKE '%' + @Vendor + '%') AND
					(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%') AND
					(ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND
					(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%' + @LastMSLevel + '%') AND
					(ISNULL(@ItemClassfication,'') ='' OR ItemClassfication LIKE '%' + @ItemClassfication + '%') AND
					(ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND
					(ISNULL(@Memo,'') ='' OR Memo LIKE '%' + @Memo + '%') AND
					(IsNull(@Qty, 0) = 0 OR CAST(Qty as VARCHAR(10)) like @Qty) AND
					(IsNull(@VendorCode, '') = '' OR VendorCode like '%' + @VendorCode + '%') AND
					
					(ISNULL(@LotNumber, '') = '' OR LotNumber LIKE '%' + @LotNumber + '%') AND
					(ISNULL(@LotName, '') = '' OR LotName LIKE '%' + @LotName + '%') AND
					(ISNULL(@TransUnitCost, 0) = 0 OR CAST(TransUnitCost as VARCHAR(10)) = @TransUnitCost) AND
					(ISNULL(@ReferenceNum,'') ='' OR ReferenceNum LIKE '%' + @ReferenceNum + '%') AND
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND
					(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND		
					(ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND		
					(ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND
					(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date) = CAST(@TagDate AS date)) AND
					(ISNULL(@InitialPOCost, 0) = 0 OR CAST(InitialPOCost as VARCHAR(10)) LIKE @InitialPOCost) AND
					(ISNULL(@StocklineTotalCost, 0) = 0 OR CAST(StocklineTotalCost as VARCHAR(10)) LIKE @StocklineTotalCost) AND
					(ISNULL(@RemainStocklineCost, 0) = 0 OR CAST(RemainStocklineCost as VARCHAR(10)) LIKE @RemainStocklineCost) AND
					(ISNULL(@Adjustment, 0) = 0 OR CAST(Adjustment as VARCHAR(10)) LIKE @Adjustment) AND
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(ISNULL(@InvoiceDate,'') ='' OR CAST(InvoiceDate AS Date) = CAST(@InvoiceDate AS date)) AND
					(ISNULL(@UnitSalePrice, 0) = 0 OR CAST(UnitSalesPrice as VARCHAR(10)) LIKE @UnitSalePrice) 
					AND (IsNull(@Status, '') = '' OR [Status] like '%' + @Status + '%')					
					)
				  )

				SELECT @Count = COUNT(*) FROM #TempResult
			
				SELECT *, @Count AS NumberOfItems FROM #TempResult
				ORDER BY 	
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNum')  THEN SerialNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNum')  THEN SerialNum END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StkLineNum')  THEN StkLineNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StkLineNum')  THEN StkLineNum END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Uom')  THEN Uom END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Uom')  THEN Uom END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyOnHand')  THEN QtyOnHand END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyOnHand')  THEN QtyOnHand END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyRes')  THEN QtyRes END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyRes')  THEN QtyRes END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyIss')  THEN QtyIss END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyIss')  THEN QtyIss END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyAvailable')  THEN QtyAvailable END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyAvailable')  THEN QtyAvailable END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TransUnitCost')  THEN TransUnitCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TransUnitCost')  THEN TransUnitCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='UnitCost')  THEN UnitCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='UnitCost')  THEN UnitCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ExtCost')  THEN ExtCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ExtCost')  THEN ExtCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RepairCost')  THEN RepairCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RepairCost')  THEN RepairCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TotalCost')  THEN TotalCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TotalCost')  THEN TotalCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ExtPrice')  THEN ExtPrice END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ExtPrice')  THEN ExtPrice END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='MarginAmt')  THEN MarginAmt END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='MarginAmt')  THEN MarginAmt END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Margin')  THEN Margin END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Margin')  THEN Margin END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='HowAcquired')  THEN HowAcquired END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='HowAcquired')  THEN HowAcquired END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='AcquiredRef')  THEN AcquiredRef END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='AcquiredRef')  THEN AcquiredRef END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PoNum')  THEN PoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PoNum')  THEN PoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RoNum')  THEN RoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RoNum')  THEN RoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='WoNum')  THEN WoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='WoNum')  THEN WoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='QuoteNum')  THEN QuoteNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='QuoteNum')  THEN QuoteNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='SoNum')  THEN SoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='SoNum')  THEN SoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Vendor')  THEN Vendor END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Vendor')  THEN Vendor END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ItemClassfication')  THEN ItemClassfication END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ItemClassfication')  THEN ItemClassfication END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Memo')  THEN Memo END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Memo')  THEN Memo END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Qty')  THEN Qty END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Qty')  THEN Qty END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='VendorCode')  THEN VendorCode END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='VendorCode')  THEN VendorCode END DESC,

				CASE WHEN (@SortOrder=1 and @SortColumn='LotNumber')  THEN LotNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotNumber')  THEN LotNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LotName')  THEN LotName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotName')  THEN LotName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ReferenceNum')  THEN ReferenceNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ReferenceNum')  THEN ReferenceNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='IdNumber')  THEN IdNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='IdNumber')  THEN IdNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TraceableToName')  THEN TraceableToName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TraceableToName')  THEN TraceableToName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TaggedByName')  THEN TaggedByName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TaggedByName')  THEN TaggedByName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TagDate')  THEN TagDate END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TagDate')  THEN TagDate END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InitialPOCost')  THEN InitialPOCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InitialPOCost')  THEN InitialPOCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='StocklineTotalCost')  THEN StocklineTotalCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='StocklineTotalCost')  THEN StocklineTotalCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RemainStocklineCost')  THEN RemainStocklineCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RemainStocklineCost')  THEN RemainStocklineCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Adjustment')  THEN Adjustment END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Adjustment')  THEN Adjustment END DESC,

				CASE WHEN (@SortOrder=1 and @SortColumn='UnitSalesPrice')  THEN UnitSalesPrice END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='UnitSalesPrice')  THEN UnitSalesPrice END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN Status END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Status')  THEN Status END DESC
				,CreatedDate  DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY

			END
			ELSE IF(UPPER(@Type) = UPPER('PNInStockView'))
			BEGIN
			;WITH Result AS (SELECT
				 lot.LotId
				,lot.LotNumber
				,lot.LotName
				,ISNULL(sl.PurchaseOrderId,0) PurchaseOrderId
				,ISNULL(sl.RepairOrderId,0) RepairOrderId
				,ISNULL(sl.WorkOrderId,0) WorkOrderId
				,ISNULL(0,0) QuoteId
				,ISNULL(so.SalesOrderId,0) SalesOrderId
				,ISNULL(ltin.LotTransInOutId,0) LotTransInOutId
				,ISNULL(ltCal.LotCalculationId,0) LotCalculationId
				,im.PartNumber
				,im.PartDescription AS Description
				,sl.StockLineId
				,sl.SerialNumber AS SerialNum
				,sl.StockLineNumber StkLineNum
				,ic.ItemClassificationCode ItemClassfication
				,ig.Description AS ItemGroup
				,c.Description AS Condition

				,ltCal.Qty AS Qty
				,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
				,ISNULL(sl.QuantityReserved, 0) AS QtyRes
				,ISNULL(sl.QuantityIssued, 0) AS QtyIss
				,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
				,ISNULL(sl.PurchaseOrderUnitCost,0.00) UnitCost
				--,(ISNULL(sl.UnitCost,0) * ltCal.Qty) ExtCost
				,(ISNULL(sl.UnitCost,0) * ISNULL(sl.QuantityOnHand,0)) ExtCost
				,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				,ISNULL(sl.UnitCost,0) AS TotalCost
				--,ro.RepairOrderNumber RoNum
				,(CASE WHEN ISNULL(SL.RepairOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 rod.RepairOrderNumber FROM dbo.RepairOrder rod WITH(NOLOCK) WHERE rod.RepairOrderId = sl.RepairOrderId) END) RoNum
				--,wo.WorkOrderNum WoNum
				,(CASE WHEN ISNULL(SL.WorkOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 wod.WorkOrderNum FROM dbo.WorkOrder wod WITH(NOLOCK) WHERE wod.WorkOrderId = sl.WorkOrderId) END) WoNum

				,So.SalesOrderNumber SoNum
				,sobi.InvoiceNo InvoiceNum 
				,ven.VendorName Vendor
				,ISNULL(ven.VendorCode,'')VendorCode
				,ISNULL(ven.VendorId,0) VendorId
				,sl.Site AS Site
				,sl.Warehouse
				,sl.Location
				,sl.Shelf
				,sl.Bin
				,UPPER(MSD.LastMSLevel)	LastMSLevel
				,UPPER(MSD.AllMSlevels) AllMSlevels
				,ISNULL(so.CustomerId,0) SoCustomerId
				,sl.ConditionId
				,sl.ItemMasterId
				,sl.CustomerId
				,sl.ControlNumber
				,sl.IdNumber
				,im.ManufacturerName
				,sl.itemType
				,UPPER(sl.UnitOfMeasure) AS Uom		
				--,per.PercentValue
				,(CASE WHEN SL.TraceableToType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.[TraceableTo] )
						    WHEN SL.TraceableToType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleOthersId THEN SL.[TraceableToName]
					   END) AS [TraceableToName],
				(CASE WHEN SL.TaggedByType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.TaggedBy )
						    WHEN SL.TaggedByType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleOthersId THEN SL.[TaggedByName]
					   END) [TaggedByName]
				,sl.TagDate
				,sl.TraceableTo
				,sl.TraceableToType
				,sl.TaggedBy
				,sl.TaggedByType
				,ISNULL(lot.InitialPOCost,0)InitialPOCost
				,ISNULL(lot.StocklineTotalCost,0)StocklineTotalCost
				,(ISNULL(lot.InitialPOCost,0) - ISNULL(lot.StocklineTotalCost,0))AS RemainStocklineCost
				,sl.Memo
				,Sl.LotSourceId
				,Sl.IsFromInitialPO
				,SL.LotMainStocklineId
				,ISNULL(sl.Adjustment,0) Adjustment
				,ltCal.CreatedDate
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN #commonTemp sl on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 --LEFT JOIN DBO.LotSetupMaster lsm WITH(NOLOCK) on lot.LotId = lsm.LotId
					 --LEFT JOIN DBO.[Percent] per WITH(NOLOCK) on lsm.MarginPercentageId = per.PercentId
					 INNER JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on ltCal.ReferenceId = so.SalesOrderId AND UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransOut_SO,' ',''))
					 LEFT JOIN DBO.SalesOrderPartV1 sop WITH(NOLOCK) on ltcal.ChildId = sop.SalesOrderPartId AND so.SalesOrderId = sop.SalesOrderId
					 LEFT JOIN DBO.SalesOrderBillingInvoicing sobi on so.SalesOrderId = sobi.SalesOrderId AND sobi.MasterCompanyId = so.MasterCompanyId AND ISNULL(sobi.IsProforma,0) = 0
					 LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii on sop.SalesOrderPartId = sobii.SalesOrderPartId AND sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobii.IsProforma,0) = 0

					 LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
					 LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId	 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	AND MSD.EntityMSID = Lot.ManagementStructureId
				 WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId AND ISNULL(sl.QuantityOnHand,0) > 0 AND (UPPER(REPLACE(ltCal.Type,' ','')) NOT IN (UPPER(REPLACE(@LOT_TransOut_SO,' ','')), UPPER(REPLACE(@LOT_TransOut_RO,' ','')),UPPER(REPLACE(@LOT_TransOut_LOT,' ',''))))
				 AND (ISNULL(sl.QuantityAvailable,0) >= @AvailableQty)
				 ), ResultCount AS(Select COUNT(*) AS totalItems FROM Result) 

					SELECT * INTO #PNInStockTbl FROM  Result
					WHERE 
					((@GlobalFilter <>'' AND ((Partnumber LIKE '%' + @GlobalFilter + '%') OR
					([Description] LIKE '%' + @GlobalFilter + '%') OR
					(StkLineNum LIKE '%' + @GlobalFilter + '%') OR
					(SerialNum LIKE '%' + @GlobalFilter + '%') OR
					(Condition LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyOnHand AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyRes AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyIss AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyAvailable AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(UnitCost LIKE '%' + @GlobalFilter + '%') OR
					(ExtCost like '%' + @GlobalFilter + '%') OR
					(RepairCost like '%' + @GlobalFilter + '%') OR
					(TotalCost like '%' + @GlobalFilter + '%') OR
					(WONum like '%' + @GlobalFilter + '%') OR
					(RoNum like '%' + @GlobalFilter + '%') OR
					(WoNum like '%' + @GlobalFilter + '%') OR
					(SoNum like '%' + @GlobalFilter + '%') OR
					(Vendor like '%' + @GlobalFilter + '%') OR
					(InvoiceNum like '%' + @GlobalFilter + '%') OR
					(LastMSLevel like '%' + @GlobalFilter + '%') OR
					(ItemClassfication like '%' + @GlobalFilter + '%') OR
					(ItemGroup like '%' + @GlobalFilter + '%') OR
					(Qty like '%' + @GlobalFilter + '%') OR
					(Site like '%' + @GlobalFilter + '%') OR
					(Warehouse like '%' + @GlobalFilter + '%') OR
					(Location like '%' + @GlobalFilter + '%') OR
					(Shelf like '%' + @GlobalFilter + '%') OR
					(Bin like '%' + @GlobalFilter + '%') OR

					(LotNumber LIKE '%' + @GlobalFilter + '%') OR
					(LotName LIKE '%' + @GlobalFilter + '%') OR
					(Uom LIKE '%' + @GlobalFilter + '%') OR
					--(PercentValue LIKE '%' + @GlobalFilter + '%') OR
					(ControlNumber like '%' + @GlobalFilter + '%') OR
					(IdNumber like '%' + @GlobalFilter + '%') OR
					(TraceableToName like '%' + @GlobalFilter + '%') OR
					(TaggedByName like '%' + @GlobalFilter + '%') OR
					(TagDate like '%' + @GlobalFilter + '%') OR
					(InitialPOCost like '%' + @GlobalFilter + '%') OR
					(StocklineTotalCost like '%' + @GlobalFilter + '%') OR
					(RemainStocklineCost like '%' + @GlobalFilter + '%') OR
						(ManufacturerName like '%' + @GlobalFilter + '%') OR	
					(Adjustment like '%' + @GlobalFilter + '%') OR
					
					(VendorCode like '%' + @GlobalFilter + '%')
					))
					OR
					(@GlobalFilter = '' AND (ISNULL(@Partnumber, '') = '' OR Partnumber LIKE '%' + @Partnumber + '%') AND
					(ISNULL(@Description, '') = '' OR [Description] LIKE '%' + @Description + '%') AND
					(ISNULL(@StkLineNum, '') = '' OR StkLineNum LIKE '%' + @StkLineNum + '%') AND
					(ISNULL(@SerialNum, '') = '' OR SerialNum LIKE '%' + @SerialNum + '%') AND
					(ISNULL(@Condition, '') = '' OR Condition LIKE '%' + @Condition + '%') AND
					(IsNull(@QtyOnHand, 0) = 0 OR CAST(QtyOnHand as VARCHAR(10)) like @QtyOnHand) AND
					(IsNull(@QtyRes, 0) = 0 OR CAST(QtyRes as VARCHAR(10)) like @QtyRes) AND
					(IsNull(@QtyIss, 0) = 0 OR CAST(QtyIss as VARCHAR(10)) like @QtyIss) AND
					(IsNull(@QtyAvailable, 0) = 0 OR CAST(QtyAvailable as VARCHAR(10)) like @QtyAvailable) AND
					(ISNULL(@UnitCost, 0) = 0 OR CAST(UnitCost as VARCHAR(10)) LIKE @UnitCost) AND
					(ISNULL(@ExtCost, 0) = 0 OR CAST(ExtCost as VARCHAR(10)) = @ExtCost) AND
					(ISNULL(@RepairCost, 0) = 0 OR CAST(RepairCost as VARCHAR(10)) = @RepairCost) AND
					(ISNULL(@TotalCost, 0) = 0 OR CAST(TotalCost as VARCHAR(10)) = @TotalCost) AND
					(ISNULL(@WONum, '') = '' OR WONum  like '%'+ @WONum + '%') AND
					--(ISNULL(@LastPODate,'') ='' OR CAST(LastPODate AS Date) = CAST(@LastPODate AS date)) AND
					(ISNULL(@RoNum,'') ='' OR RoNum LIKE '%' + @RoNum + '%') AND
					(ISNULL(@WoNum,'') ='' OR WoNum LIKE '%' + @WoNum + '%') AND
					(ISNULL(@SoNum,'') ='' OR SoNum LIKE '%' + @SoNum + '%') AND
					(ISNULL(@Vendor,'') ='' OR Vendor LIKE '%' + @Vendor + '%') AND
					(ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND
					(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%' + @LastMSLevel + '%') AND
					(ISNULL(@ItemClassfication,'') ='' OR ItemClassfication LIKE '%' + @ItemClassfication + '%') AND
					(ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND
					(IsNull(@Qty, 0) = 0 OR CAST(Qty as VARCHAR(10)) like @Qty) AND
					(ISNULL(@Site,'') ='' OR Site LIKE '%' + @Site + '%') AND
					(ISNULL(@Warehouse,'') ='' OR Warehouse LIKE '%' + @Warehouse + '%') AND
					(ISNULL(@Location,'') ='' OR Location LIKE '%' + @Location + '%') AND
					(ISNULL(@Shelf,'') ='' OR Shelf LIKE '%' + @Shelf + '%') AND
					(ISNULL(@Bin,'') ='' OR Bin LIKE '%' + @Bin + '%') AND

					(ISNULL(@LotNumber, '') = '' OR LotNumber LIKE '%' + @LotNumber + '%') AND
					(ISNULL(@LotName, '') = '' OR LotName LIKE '%' + @LotName + '%') AND
					--(ISNULL(@TransUnitCost, 0) = 0 OR CAST(TransUnitCost as VARCHAR(10)) = @TransUnitCost) AND
					--(ISNULL(@ReferenceNum,'') ='' OR ReferenceNum LIKE '%' + @ReferenceNum + '%') AND
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND
					(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND		
					(ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND		
					(ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND
					(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date) = CAST(@TagDate AS date)) AND
					(ISNULL(@InitialPOCost, 0) = 0 OR CAST(InitialPOCost as VARCHAR(10)) LIKE @InitialPOCost) AND
					(ISNULL(@StocklineTotalCost, 0) = 0 OR CAST(StocklineTotalCost as VARCHAR(10)) LIKE @StocklineTotalCost) AND
					(ISNULL(@RemainStocklineCost, 0) = 0 OR CAST(RemainStocklineCost as VARCHAR(10)) LIKE @RemainStocklineCost) AND
					(ISNULL(@Adjustment, 0) = 0 OR CAST(Adjustment as VARCHAR(10)) LIKE @Adjustment) AND
					(ISNULL(@Uom,'') ='' OR Uom LIKE '%' + @Uom + '%') AND
					--(ISNULL(@PercentValue, 0) = 0 OR CAST(PercentValue as VARCHAR(10)) LIKE @PercentValue) AND
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(IsNull(@VendorCode, '') = '' OR VendorCode like '%' + @VendorCode + '%')
					)
				  )

				SELECT @Count = COUNT(*) FROM #PNInStockTbl
			
				SELECT *, @Count AS NumberOfItems FROM #PNInStockTbl
				ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNum')  THEN SerialNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNum')  THEN SerialNum END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StkLineNum')  THEN StkLineNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StkLineNum')  THEN StkLineNum END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyOnHand')  THEN QtyOnHand END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyOnHand')  THEN QtyOnHand END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyRes')  THEN QtyRes END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyRes')  THEN QtyRes END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyIss')  THEN QtyIss END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyIss')  THEN QtyIss END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyAvailable')  THEN QtyAvailable END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyAvailable')  THEN QtyAvailable END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='UnitCost')  THEN UnitCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='UnitCost')  THEN UnitCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ExtCost')  THEN ExtCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ExtCost')  THEN ExtCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RepairCost')  THEN RepairCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RepairCost')  THEN RepairCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TotalCost')  THEN TotalCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TotalCost')  THEN TotalCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RoNum')  THEN RoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RoNum')  THEN RoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='WoNum')  THEN WoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='WoNum')  THEN WoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='SoNum')  THEN SoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='SoNum')  THEN SoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Vendor')  THEN Vendor END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Vendor')  THEN Vendor END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ItemClassfication')  THEN ItemClassfication END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ItemClassfication')  THEN ItemClassfication END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Qty')  THEN Qty END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Qty')  THEN Qty END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Site')  THEN Site END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Site')  THEN Site END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Warehouse')  THEN Warehouse END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Warehouse')  THEN Warehouse END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Location')  THEN Location END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Location')  THEN Location END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Shelf')  THEN Shelf END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Shelf')  THEN Shelf END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Bin')  THEN Bin END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Bin')  THEN Bin END DESC,

				CASE WHEN (@SortOrder=1 and @SortColumn='LotNumber')  THEN LotNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotNumber')  THEN LotNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LotName')  THEN LotName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotName')  THEN LotName END DESC,
				--CASE WHEN (@SortOrder=1 and @SortColumn='TransUnitCost')  THEN TransUnitCost END ASC,
				--CASE WHEN (@SortOrder=-1 and @SortColumn='TransUnitCost')  THEN TransUnitCost END DESC,
				--CASE WHEN (@SortOrder=1 and @SortColumn='ReferenceNum')  THEN ReferenceNum END ASC,
				--CASE WHEN (@SortOrder=-1 and @SortColumn='ReferenceNum')  THEN ReferenceNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='IdNumber')  THEN IdNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='IdNumber')  THEN IdNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TraceableToName')  THEN TraceableToName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TraceableToName')  THEN TraceableToName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TaggedByName')  THEN TaggedByName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TaggedByName')  THEN TaggedByName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TagDate')  THEN TagDate END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TagDate')  THEN TagDate END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InitialPOCost')  THEN InitialPOCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InitialPOCost')  THEN InitialPOCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='StocklineTotalCost')  THEN StocklineTotalCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='StocklineTotalCost')  THEN StocklineTotalCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RemainStocklineCost')  THEN RemainStocklineCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RemainStocklineCost')  THEN RemainStocklineCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Adjustment')  THEN Adjustment END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Adjustment')  THEN Adjustment END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Uom')  THEN Uom END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Uom')  THEN Uom END DESC,
				--CASE WHEN (@SortOrder=1 and @SortColumn='PercentValue')  THEN PercentValue END ASC,
				--CASE WHEN (@SortOrder=-1 and @SortColumn='PercentValue')  THEN PercentValue END DESC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='VendorCode')  THEN VendorCode END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='VendorCode')  THEN VendorCode END DESC
				,CreatedDate  DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF(UPPER(@Type) = UPPER('PNQuoteView'))
			BEGIN
			;WITH Result AS (SELECT 
				 lot.LotId
				,lot.LotNumber
				,lot.LotName
				,ISNULL(sl.PurchaseOrderId,0) PurchaseOrderId
				,ISNULL(sl.RepairOrderId,0) RepairOrderId
				,ISNULL(sl.WorkOrderId,0) WorkOrderId
				,ISNULL(soq.SalesOrderQuoteId,0) QuoteId
				,ISNULL(so.SalesOrderId,0) SalesOrderId
				,im.PartNumber
				,im.PartDescription AS Description
				,sl.StockLineId
				,sl.SerialNumber AS SerialNum
				,sl.StockLineNumber StkLineNum
				,ic.ItemClassificationCode ItemClassfication
				,ig.Description AS ItemGroup
				,c.Description AS Condition
				,'Quote' AS Status
				,Soq.CustomerName
				,soqp.QtyRequested Qty
				,soqpc.UnitSalesPrice UnitPrice
				,ISNULL(soqpc.UnitSalesPrice,0) * ISNULL(soqp.QtyQuoted,0) ExtendedPrice		
				,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
				,ISNULL(sl.QuantityReserved, 0) AS QtyRes
				,ISNULL(sl.QuantityIssued, 0) AS QtyIss
				,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
				,(CASE WHEN ISNULL(SL.RepairOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 rod.RepairOrderNumber FROM dbo.RepairOrder rod WITH(NOLOCK) WHERE rod.RepairOrderId = sl.RepairOrderId) END) RoNum
				,(CASE WHEN ISNULL(SL.WorkOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 wod.WorkOrderNum FROM dbo.WorkOrder wod WITH(NOLOCK) WHERE wod.WorkOrderId = sl.WorkOrderId) END) WoNum
				,So.SalesOrderNumber SoNum
				,ven.VendorName Vendor
				,ISNULL(ven.VendorCode,'')VendorCode
				,ISNULL(ven.VendorId,0) VendorId
				,sl.Site AS Site
				,sl.Warehouse
				,sl.Location
				,sl.Shelf
				,sl.Bin
				,UPPER(MSD.LastMSLevel)	LastMSLevel
				,UPPER(MSD.AllMSlevels) AllMSlevels
				,ISNULL(so.CustomerId,0) SoCustomerId
				,sl.ConditionId
				,sl.ItemMasterId
				,sl.CustomerId
				,sl.ControlNumber
				,sl.IdNumber
				,(CASE WHEN SL.TraceableToType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.[TraceableTo] )
						    WHEN SL.TraceableToType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleOthersId THEN SL.[TraceableToName]
					   END) AS [TraceableToName],
				(CASE WHEN SL.TaggedByType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.TaggedBy )
						    WHEN SL.TaggedByType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleOthersId THEN SL.[TaggedByName]
					   END) [TaggedByName]
				,sl.TagDate
				,sl.TraceableTo
				,sl.TraceableToType
				,sl.TaggedBy
				,sl.TaggedByType
				,ISNULL(lot.InitialPOCost,0)InitialPOCost
				,ISNULL(lot.StocklineTotalCost,0)StocklineTotalCost
				,(ISNULL(lot.InitialPOCost,0) - ISNULL(lot.StocklineTotalCost,0))AS RemainStocklineCost
				,sl.Memo
				,Sl.LotSourceId
				,Sl.IsFromInitialPO
				,SL.LotMainStocklineId
				,ISNULL(sl.Adjustment,0) Adjustment
				,soqp.CreatedDate
				,soq.SalesOrderQuoteNumber AS  QuoteNum
				,im.ManufacturerName
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER join dbo.SalesOrderQuotePartV1 soqp WITH(NOLOCK) on lot.LotId =soqp.LotId
					 INNER JOIN dbo.SalesOrderQuote soq WITH(NOLOCK) on soqp.SalesOrderQuoteId = soq.SalesOrderQuoteId
					 INNER join dbo.SalesOrderQuoteStocklineV1 sov WITH(NOLOCK) on  sov.SalesOrderQuotePartId = soqp.SalesOrderQuotePartId --lot.LotId =soqp.LotId
					 INNER join dbo.SalesOrderQuotePartCost soqpc WITH(NOLOCK) on soqpc.SalesOrderQuotePartId = soqp.SalesOrderQuotePartId AND soqpc.IsDeleted = 0
					 INNER JOIN #commonTemp sl on sov.StockLineId = sl.StockLineId
					 LEFT JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on soq.SalesOrderQuoteId = so.SalesOrderQuoteId
					 LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
					 LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	AND MSD.EntityMSID = Lot.ManagementStructureId
				 WHERE soqp.LotId = @LotId AND soqp.MasterCompanyId = @MasterCompanyId 
				 	 	), ResultCount AS(Select COUNT(*) AS totalItems FROM Result) 
				
				SELECT * INTO #PNQuoteViewTbl FROM  Result 
				WHERE 
				((@GlobalFilter <>'' AND ((Partnumber LIKE '%' + @GlobalFilter + '%') OR
					([Description] LIKE '%' + @GlobalFilter + '%') OR
					(StkLineNum LIKE '%' + @GlobalFilter + '%') OR
					(SerialNum LIKE '%' + @GlobalFilter + '%') OR
					(Condition LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyOnHand AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyRes AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyIss AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyAvailable AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(WONum like '%' + @GlobalFilter + '%') OR
					(RoNum like '%' + @GlobalFilter + '%') OR
					(WoNum like '%' + @GlobalFilter + '%') OR
					(SoNum like '%' + @GlobalFilter + '%') OR
					(Vendor like '%' + @GlobalFilter + '%') OR
					(CustomerName like '%' + @GlobalFilter + '%') OR
					(LastMSLevel like '%' + @GlobalFilter + '%') OR
					(ItemClassfication like '%' + @GlobalFilter + '%') OR
					(ItemGroup like '%' + @GlobalFilter + '%') OR
					(Qty like '%' + @GlobalFilter + '%') OR
					(VendorCode like '%' + @GlobalFilter + '%') OR
					(Site like '%' + @GlobalFilter + '%') OR
					(Warehouse like '%' + @GlobalFilter + '%') OR
					(Location like '%' + @GlobalFilter + '%') OR
					(Shelf like '%' + @GlobalFilter + '%') OR
					(Bin like '%' + @GlobalFilter + '%') OR
					(UnitPrice like '%' + @GlobalFilter + '%') OR
					(ExtendedPrice like '%' + @GlobalFilter + '%') OR					
					(LotNumber LIKE '%' + @GlobalFilter + '%') OR
					(LotName LIKE '%' + @GlobalFilter + '%') OR
					(ControlNumber like '%' + @GlobalFilter + '%') OR
					(IdNumber like '%' + @GlobalFilter + '%') OR
					(TraceableToName like '%' + @GlobalFilter + '%') OR
					(TaggedByName like '%' + @GlobalFilter + '%') OR
					(TagDate like '%' + @GlobalFilter + '%') OR
					(InitialPOCost like '%' + @GlobalFilter + '%') OR
					(StocklineTotalCost like '%' + @GlobalFilter + '%') OR
					(RemainStocklineCost like '%' + @GlobalFilter + '%') OR
					(Adjustment like '%' + @GlobalFilter + '%') OR
						(ManufacturerName like '%' + @GlobalFilter + '%') OR	
					([Status] like '%' + @GlobalFilter + '%')
					))
					OR
					(@GlobalFilter = '' AND (ISNULL(@Partnumber, '') = '' OR Partnumber LIKE '%' + @Partnumber + '%') AND
					(ISNULL(@Description, '') = '' OR [Description] LIKE '%' + @Description + '%') AND
					(ISNULL(@StkLineNum, '') = '' OR StkLineNum LIKE '%' + @StkLineNum + '%') AND
					(ISNULL(@SerialNum, '') = '' OR SerialNum LIKE '%' + @SerialNum + '%') AND
					(ISNULL(@Condition, '') = '' OR Condition LIKE '%' + @Condition + '%') AND
					(IsNull(@QtyOnHand, 0) = 0 OR CAST(QtyOnHand as VARCHAR(10)) like @QtyOnHand) AND
					(IsNull(@QtyRes, 0) = 0 OR CAST(QtyRes as VARCHAR(10)) like @QtyRes) AND
					(IsNull(@QtyIss, 0) = 0 OR CAST(QtyIss as VARCHAR(10)) like @QtyIss) AND
					(IsNull(@QtyAvailable, 0) = 0 OR CAST(QtyAvailable as VARCHAR(10)) like @QtyAvailable) AND
					(ISNULL(@WONum, '') = '' OR WONum  like '%'+ @WONum + '%') AND
					(ISNULL(@RoNum,'') ='' OR RoNum LIKE '%' + @RoNum + '%') AND
					(ISNULL(@WoNum,'') ='' OR WoNum LIKE '%' + @WoNum + '%') AND
					(ISNULL(@SoNum,'') ='' OR SoNum LIKE '%' + @SoNum + '%') AND
					(ISNULL(@Vendor,'') ='' OR Vendor LIKE '%' + @Vendor + '%') AND
					(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%') AND
					(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%' + @LastMSLevel + '%') AND
					(ISNULL(@ItemClassfication,'') ='' OR ItemClassfication LIKE '%' + @ItemClassfication + '%') AND
					(ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND
					(IsNull(@Qty, 0) = 0 OR CAST(Qty as VARCHAR(10)) like @Qty) AND
					(IsNull(@VendorCode, '') = '' OR VendorCode like '%' + @VendorCode + '%') AND
					(ISNULL(@Site,'') ='' OR Site LIKE '%' + @Site + '%') AND
					(ISNULL(@Warehouse,'') ='' OR Warehouse LIKE '%' + @Warehouse + '%') AND
					(ISNULL(@Location,'') ='' OR Location LIKE '%' + @Location + '%') AND
					(ISNULL(@Shelf,'') ='' OR Shelf LIKE '%' + @Shelf + '%') AND
					(ISNULL(@Bin,'') ='' OR Bin LIKE '%' + @Bin + '%') AND
					(ISNULL(@UnitPrice, 0) = 0 OR CAST(UnitPrice as VARCHAR(10)) = @UnitPrice) AND
					(ISNULL(@LotNumber, '') = '' OR LotNumber LIKE '%' + @LotNumber + '%') AND
					(ISNULL(@LotName, '') = '' OR LotName LIKE '%' + @LotName + '%') AND
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND
					(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND		
					(ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND		
					(ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND
					(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date) = CAST(@TagDate AS date)) AND
					(ISNULL(@InitialPOCost, 0) = 0 OR CAST(InitialPOCost as VARCHAR(10)) LIKE @InitialPOCost) AND
					(ISNULL(@StocklineTotalCost, 0) = 0 OR CAST(StocklineTotalCost as VARCHAR(10)) LIKE @StocklineTotalCost) AND
					(ISNULL(@RemainStocklineCost, 0) = 0 OR CAST(RemainStocklineCost as VARCHAR(10)) LIKE @RemainStocklineCost) AND
					(ISNULL(@Adjustment, 0) = 0 OR CAST(Adjustment as VARCHAR(10)) LIKE @Adjustment) AND
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(IsNull(@Status, '') = '' OR [Status] like '%' + @Status + '%')	
					)
				  )

				SELECT @Count = COUNT(*) FROM #PNQuoteViewTbl
			
				SELECT *, @Count AS NumberOfItems FROM #PNQuoteViewTbl
				ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNum')  THEN SerialNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNum')  THEN SerialNum END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StkLineNum')  THEN StkLineNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StkLineNum')  THEN StkLineNum END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyOnHand')  THEN QtyOnHand END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyOnHand')  THEN QtyOnHand END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyRes')  THEN QtyRes END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyRes')  THEN QtyRes END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyIss')  THEN QtyIss END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyIss')  THEN QtyIss END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyAvailable')  THEN QtyAvailable END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyAvailable')  THEN QtyAvailable END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RoNum')  THEN RoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RoNum')  THEN RoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='WoNum')  THEN WoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='WoNum')  THEN WoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='SoNum')  THEN SoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='SoNum')  THEN SoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Vendor')  THEN Vendor END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Vendor')  THEN Vendor END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ItemClassfication')  THEN ItemClassfication END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ItemClassfication')  THEN ItemClassfication END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Qty')  THEN Qty END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Qty')  THEN Qty END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='VendorCode')  THEN VendorCode END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='VendorCode')  THEN VendorCode END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Site')  THEN Site END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Site')  THEN Site END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Warehouse')  THEN Warehouse END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Warehouse')  THEN Warehouse END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Location')  THEN Location END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Location')  THEN Location END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Shelf')  THEN Shelf END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Shelf')  THEN Shelf END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Bin')  THEN Bin END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Bin')  THEN Bin END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='UnitPrice')  THEN UnitPrice END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='UnitPrice')  THEN UnitPrice END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ExtendedPrice')  THEN ExtendedPrice END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ExtendedPrice')  THEN ExtendedPrice END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LotNumber')  THEN LotNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotNumber')  THEN LotNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LotName')  THEN LotName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotName')  THEN LotName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='IdNumber')  THEN IdNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='IdNumber')  THEN IdNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TraceableToName')  THEN TraceableToName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TraceableToName')  THEN TraceableToName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TaggedByName')  THEN TaggedByName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TaggedByName')  THEN TaggedByName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TagDate')  THEN TagDate END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TagDate')  THEN TagDate END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InitialPOCost')  THEN InitialPOCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InitialPOCost')  THEN InitialPOCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='StocklineTotalCost')  THEN StocklineTotalCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='StocklineTotalCost')  THEN StocklineTotalCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RemainStocklineCost')  THEN RemainStocklineCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RemainStocklineCost')  THEN RemainStocklineCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Adjustment')  THEN Adjustment END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Adjustment')  THEN Adjustment END DESC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN Status END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Status')  THEN Status END DESC
				,CreatedDate  DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF(UPPER(@Type) = UPPER('PNSoldView'))
			BEGIN
			;WITH Result AS (SELECT 
				 lot.LotId
				,lot.LotNumber
				,lot.LotName
				,ISNULL(sl.PurchaseOrderId,0) PurchaseOrderId
				,ISNULL(sl.RepairOrderId,0) RepairOrderId
				,ISNULL(sl.WorkOrderId,0) WorkOrderId
				,ISNULL(0,0) QuoteId
				,ISNULL(so.SalesOrderId,0) SalesOrderId
				,ISNULL(ltin.LotTransInOutId,0) LotTransInOutId
				,ISNULL(ltCal.LotCalculationId,0) LotCalculationId
				,im.PartNumber
				,im.PartDescription AS Description
				,sl.StockLineId
				,sl.SerialNumber AS SerialNum
				,sl.StockLineNumber StkLineNum
				,ic.ItemClassificationCode ItemClassfication
				,ig.Description AS ItemGroup
				,c.Description AS Condition
				,'SOLD' AS Status
				,So.CustomerName
				,sobi.InvoiceDate
				,ltCal.Qty Qty
				,ltCal.SalesUnitPrice UnitPrice
				,ltCal.ExtSalesUnitPrice ExtendedPrice		
				,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
				,ISNULL(sl.QuantityReserved, 0) AS QtyRes
				,ISNULL(sl.QuantityIssued, 0) AS QtyIss
				,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
				--,(CASE WHEN ISNULL(ltcal.Qty,0) > 0 THEN ISNULL(ltcal.cogs,0.00)/ ltCal.Qty ELSE 0 END) AS Cost
				,(CASE WHEN ISNULL(ltcal.Qty,0) > 0 THEN convert(decimal(18,2),(ISNULL(ltcal.cogs,0.00)/ ltCal.Qty)) ELSE 0.00 END) AS Cost
				,(ISNULL(ltcal.cogs,0)) ExtCost
				,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				,(ISNULL(ltcal.cogs,0.00) + ISNULL(sl.RepairOrderUnitCost,0)) TotalDirectCost
				,ltCal.MarginAmount MarginAmt
				--,ltCal.Margin Margin
				,CASE WHEN ISNULL(ltCal.ExtSalesUnitPrice,0) = 0 THEN 0 ELSE CONVERT(DECIMAL(10,2),((100 * ISNULL(ltCal.MarginAmount,0))/ISNULL(ltCal.ExtSalesUnitPrice,1)))END Margin
				--,ro.RepairOrderNumber RoNum
				,(CASE WHEN ISNULL(SL.RepairOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 rod.RepairOrderNumber FROM dbo.RepairOrder rod WITH(NOLOCK) WHERE rod.RepairOrderId = sl.RepairOrderId) END) RoNum
				--,wo.WorkOrderNum WoNum
				,(CASE WHEN ISNULL(SL.WorkOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 wod.WorkOrderNum FROM dbo.WorkOrder wod WITH(NOLOCK) WHERE wod.WorkOrderId = sl.WorkOrderId) END) WoNum
				,So.SalesOrderNumber SoNum
				,sobi.InvoiceNo InvoiceNum 
				,ven.VendorName Vendor
				,ISNULL(ven.VendorCode,'')VendorCode
				,ISNULL(ven.VendorId,0) VendorId
				,sl.Site AS Site
				,sl.Warehouse
				,sl.Location
				,sl.Shelf
				,sl.Bin
				,UPPER(MSD.LastMSLevel)	LastMSLevel
				,UPPER(MSD.AllMSlevels) AllMSlevels
				,ISNULL(so.CustomerId,0) SoCustomerId
				,sl.ConditionId
				,sl.ItemMasterId
				,sl.CustomerId
				,sl.ControlNumber
				,sl.IdNumber
				,(CASE WHEN SL.TraceableToType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.[TraceableTo] )
						    WHEN SL.TraceableToType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleOthersId THEN SL.[TraceableToName]
					   END) AS [TraceableToName],
				(CASE WHEN SL.TaggedByType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.TaggedBy )
						    WHEN SL.TaggedByType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleOthersId THEN SL.[TaggedByName]
					   END) [TaggedByName]
				,sl.TagDate
				,sl.TraceableTo
				,sl.TraceableToType
				,sl.TaggedBy
				,sl.TaggedByType
				,ISNULL(lot.InitialPOCost,0)InitialPOCost
				,ISNULL(lot.StocklineTotalCost,0)StocklineTotalCost
				,(ISNULL(lot.InitialPOCost,0) - ISNULL(lot.StocklineTotalCost,0))AS RemainStocklineCost
				,sl.Memo
				,Sl.LotSourceId
				,Sl.IsFromInitialPO
				,SL.LotMainStocklineId
				,(ISNULL(sl.Adjustment,0) * ISNULL(sl.QuantityOnHand, 0)) Adjustment
				,ltCal.CreatedDate
				,im.ManufacturerName
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN #commonTemp sl on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 INNER JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 INNER JOIN DBO.SalesOrder so WITH(NOLOCK) on ltCal.ReferenceId = so.SalesOrderId AND UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransOut_SO,' ',''))
					 INNER JOIN DBO.SalesOrderPartV1 sop WITH(NOLOCK) on ltcal.ChildId = sop.SalesOrderPartId AND so.SalesOrderId = sop.SalesOrderId
					 LEFT JOIN DBO.SalesOrderBillingInvoicing sobi on so.SalesOrderId = sobi.SalesOrderId AND sobi.MasterCompanyId = so.MasterCompanyId AND ISNULL(sobi.IsProforma,0) = 0
					 LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii on sop.SalesOrderPartId = sobii.SalesOrderPartId AND sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobii.IsProforma,0) = 0
					 LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
					 LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	AND MSD.EntityMSID = Lot.ManagementStructureId
				 WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId AND UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransOut_SO,' ',''))
				 	 	), ResultCount AS(Select COUNT(*) AS totalItems FROM Result) 
				
				SELECT * INTO #PNSoldViewTbl FROM  Result 
				WHERE 
				((@GlobalFilter <>'' AND ((Partnumber LIKE '%' + @GlobalFilter + '%') OR
					([Description] LIKE '%' + @GlobalFilter + '%') OR
					(StkLineNum LIKE '%' + @GlobalFilter + '%') OR
					(SerialNum LIKE '%' + @GlobalFilter + '%') OR
					(Condition LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyOnHand AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyRes AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyIss AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyAvailable AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(ExtCost like '%' + @GlobalFilter + '%') OR
					(RepairCost like '%' + @GlobalFilter + '%') OR
					(WONum like '%' + @GlobalFilter + '%') OR
					(MarginAmt like '%' + @GlobalFilter + '%') OR
					(Margin like '%' + @GlobalFilter + '%') OR
					(RoNum like '%' + @GlobalFilter + '%') OR
					(WoNum like '%' + @GlobalFilter + '%') OR
					(SoNum like '%' + @GlobalFilter + '%') OR
					(Vendor like '%' + @GlobalFilter + '%') OR
					(CustomerName like '%' + @GlobalFilter + '%') OR
					(InvoiceNum like '%' + @GlobalFilter + '%') OR
					(LastMSLevel like '%' + @GlobalFilter + '%') OR
					(ItemClassfication like '%' + @GlobalFilter + '%') OR
					(ItemGroup like '%' + @GlobalFilter + '%') OR
					(Qty like '%' + @GlobalFilter + '%') OR
					(VendorCode like '%' + @GlobalFilter + '%') OR
					(InvoiceDate like '%' + @GlobalFilter + '%') OR
					(Cost like '%' + @GlobalFilter + '%') OR
					(Site like '%' + @GlobalFilter + '%') OR
					(Warehouse like '%' + @GlobalFilter + '%') OR
					(Location like '%' + @GlobalFilter + '%') OR
					(Shelf like '%' + @GlobalFilter + '%') OR
					(Bin like '%' + @GlobalFilter + '%') OR
					(UnitPrice like '%' + @GlobalFilter + '%') OR
					(ExtendedPrice like '%' + @GlobalFilter + '%') OR
					(TotalDirectCost like '%' + @GlobalFilter + '%') OR
					
					(LotNumber LIKE '%' + @GlobalFilter + '%') OR
					(LotName LIKE '%' + @GlobalFilter + '%') OR
					(ControlNumber like '%' + @GlobalFilter + '%') OR
					(IdNumber like '%' + @GlobalFilter + '%') OR
					(TraceableToName like '%' + @GlobalFilter + '%') OR
					(TaggedByName like '%' + @GlobalFilter + '%') OR
					(TagDate like '%' + @GlobalFilter + '%') OR
					(InitialPOCost like '%' + @GlobalFilter + '%') OR
					(StocklineTotalCost like '%' + @GlobalFilter + '%') OR
					(RemainStocklineCost like '%' + @GlobalFilter + '%') OR
					(Adjustment like '%' + @GlobalFilter + '%') OR
						(ManufacturerName like '%' + @GlobalFilter + '%') OR	
					([Status] like '%' + @GlobalFilter + '%')
					))
					OR
					(@GlobalFilter = '' AND (ISNULL(@Partnumber, '') = '' OR Partnumber LIKE '%' + @Partnumber + '%') AND
					(ISNULL(@Description, '') = '' OR [Description] LIKE '%' + @Description + '%') AND
					(ISNULL(@StkLineNum, '') = '' OR StkLineNum LIKE '%' + @StkLineNum + '%') AND
					(ISNULL(@SerialNum, '') = '' OR SerialNum LIKE '%' + @SerialNum + '%') AND
					(ISNULL(@Condition, '') = '' OR Condition LIKE '%' + @Condition + '%') AND
					(IsNull(@QtyOnHand, 0) = 0 OR CAST(QtyOnHand as VARCHAR(10)) like @QtyOnHand) AND
					(IsNull(@QtyRes, 0) = 0 OR CAST(QtyRes as VARCHAR(10)) like @QtyRes) AND
					(IsNull(@QtyIss, 0) = 0 OR CAST(QtyIss as VARCHAR(10)) like @QtyIss) AND
					(IsNull(@QtyAvailable, 0) = 0 OR CAST(QtyAvailable as VARCHAR(10)) like @QtyAvailable) AND
					(ISNULL(@ExtCost, 0) = 0 OR CAST(ExtCost as VARCHAR(10)) = @ExtCost) AND
					(ISNULL(@RepairCost, 0) = 0 OR CAST(RepairCost as VARCHAR(10)) = @RepairCost) AND
					(ISNULL(@WONum, '') = '' OR WONum  like '%'+ @WONum + '%') AND
					(ISNULL(@MarginAmt, 0) = 0 OR CAST(MarginAmt as VARCHAR(10)) LIKE @MarginAmt) AND
					(ISNULL(@Margin, 0) = 0 OR CAST(Margin as VARCHAR(10)) LIKE @Margin) AND
					(ISNULL(@RoNum,'') ='' OR RoNum LIKE '%' + @RoNum + '%') AND
					(ISNULL(@WoNum,'') ='' OR WoNum LIKE '%' + @WoNum + '%') AND
					(ISNULL(@SoNum,'') ='' OR SoNum LIKE '%' + @SoNum + '%') AND
					(ISNULL(@Vendor,'') ='' OR Vendor LIKE '%' + @Vendor + '%') AND
					(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%') AND
					(ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND
					(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%' + @LastMSLevel + '%') AND
					(ISNULL(@ItemClassfication,'') ='' OR ItemClassfication LIKE '%' + @ItemClassfication + '%') AND
					(ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND
					(IsNull(@Qty, 0) = 0 OR CAST(Qty as VARCHAR(10)) like @Qty) AND
					(IsNull(@VendorCode, '') = '' OR VendorCode like '%' + @VendorCode + '%') AND
					(ISNULL(@Site,'') ='' OR Site LIKE '%' + @Site + '%') AND
					(ISNULL(@Warehouse,'') ='' OR Warehouse LIKE '%' + @Warehouse + '%') AND
					(ISNULL(@Location,'') ='' OR Location LIKE '%' + @Location + '%') AND
					(ISNULL(@Shelf,'') ='' OR Shelf LIKE '%' + @Shelf + '%') AND
					(ISNULL(@Bin,'') ='' OR Bin LIKE '%' + @Bin + '%') AND
					(ISNULL(@InvoiceDate,'') ='' OR CAST(InvoiceDate AS Date) = CAST(@InvoiceDate AS date)) AND
					(ISNULL(@Cost, 0) = 0 OR CAST(Cost as VARCHAR(10)) = @Cost) AND
					(ISNULL(@UnitPrice, 0) = 0 OR CAST(UnitPrice as VARCHAR(10)) = @UnitPrice) AND
					(ISNULL(@ExtendedPrice, 0) = 0 OR CAST(RepairCost as VARCHAR(10)) = @ExtendedPrice) AND
					(ISNULL(@TotalDirectCost, 0) = 0 OR CAST(TotalDirectCost as VARCHAR(10)) = @TotalDirectCost) AND
			
					(ISNULL(@LotNumber, '') = '' OR LotNumber LIKE '%' + @LotNumber + '%') AND
					(ISNULL(@LotName, '') = '' OR LotName LIKE '%' + @LotName + '%') AND
					--(ISNULL(@TransUnitCost, 0) = 0 OR CAST(TransUnitCost as VARCHAR(10)) = @TransUnitCost) AND
					--(ISNULL(@ReferenceNum,'') ='' OR ReferenceNum LIKE '%' + @ReferenceNum + '%') AND
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND
					(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND		
					(ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND		
					(ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND
					(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date) = CAST(@TagDate AS date)) AND
					(ISNULL(@InitialPOCost, 0) = 0 OR CAST(InitialPOCost as VARCHAR(10)) LIKE @InitialPOCost) AND
					(ISNULL(@StocklineTotalCost, 0) = 0 OR CAST(StocklineTotalCost as VARCHAR(10)) LIKE @StocklineTotalCost) AND
					(ISNULL(@RemainStocklineCost, 0) = 0 OR CAST(RemainStocklineCost as VARCHAR(10)) LIKE @RemainStocklineCost) AND
					(ISNULL(@Adjustment, 0) = 0 OR CAST(Adjustment as VARCHAR(10)) LIKE @Adjustment) AND
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(IsNull(@Status, '') = '' OR [Status] like '%' + @Status + '%')	
					)
				  )

				SELECT @Count = COUNT(*) FROM #PNSoldViewTbl
			
				SELECT *, @Count AS NumberOfItems FROM #PNSoldViewTbl
				ORDER BY  
				--CASE WHEN (@SortOrder=1  AND @SortColumn='Status')  THEN Status END ASC,
				--CASE WHEN (@SortOrder=-1  AND @SortColumn='Status')  THEN Status END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNum')  THEN SerialNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNum')  THEN SerialNum END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StkLineNum')  THEN StkLineNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StkLineNum')  THEN StkLineNum END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyOnHand')  THEN QtyOnHand END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyOnHand')  THEN QtyOnHand END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyRes')  THEN QtyRes END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyRes')  THEN QtyRes END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyIss')  THEN QtyIss END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyIss')  THEN QtyIss END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyAvailable')  THEN QtyAvailable END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyAvailable')  THEN QtyAvailable END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ExtCost')  THEN ExtCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ExtCost')  THEN ExtCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RepairCost')  THEN RepairCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RepairCost')  THEN RepairCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='MarginAmt')  THEN MarginAmt END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='MarginAmt')  THEN MarginAmt END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Margin')  THEN Margin END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Margin')  THEN Margin END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RoNum')  THEN RoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RoNum')  THEN RoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='WoNum')  THEN WoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='WoNum')  THEN WoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='SoNum')  THEN SoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='SoNum')  THEN SoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Vendor')  THEN Vendor END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Vendor')  THEN Vendor END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ItemClassfication')  THEN ItemClassfication END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ItemClassfication')  THEN ItemClassfication END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Qty')  THEN Qty END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Qty')  THEN Qty END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='VendorCode')  THEN VendorCode END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='VendorCode')  THEN VendorCode END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Cost')  THEN Cost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Cost')  THEN Cost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Site')  THEN Site END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Site')  THEN Site END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Warehouse')  THEN Warehouse END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Warehouse')  THEN Warehouse END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Location')  THEN Location END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Location')  THEN Location END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Shelf')  THEN Shelf END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Shelf')  THEN Shelf END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Bin')  THEN Bin END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Bin')  THEN Bin END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='UnitPrice')  THEN UnitPrice END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='UnitPrice')  THEN UnitPrice END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ExtendedPrice')  THEN ExtendedPrice END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ExtendedPrice')  THEN ExtendedPrice END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TotalDirectCost')  THEN TotalDirectCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TotalDirectCost')  THEN TotalDirectCost END DESC,

				CASE WHEN (@SortOrder=1 and @SortColumn='LotNumber')  THEN LotNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotNumber')  THEN LotNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LotName')  THEN LotName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotName')  THEN LotName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='IdNumber')  THEN IdNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='IdNumber')  THEN IdNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TraceableToName')  THEN TraceableToName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TraceableToName')  THEN TraceableToName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TaggedByName')  THEN TaggedByName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TaggedByName')  THEN TaggedByName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TagDate')  THEN TagDate END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TagDate')  THEN TagDate END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InitialPOCost')  THEN InitialPOCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InitialPOCost')  THEN InitialPOCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='StocklineTotalCost')  THEN StocklineTotalCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='StocklineTotalCost')  THEN StocklineTotalCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RemainStocklineCost')  THEN RemainStocklineCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RemainStocklineCost')  THEN RemainStocklineCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Adjustment')  THEN Adjustment END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Adjustment')  THEN Adjustment END DESC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN Status END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Status')  THEN Status END DESC
				,CreatedDate  DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF(UPPER(@Type) = UPPER('RepairedView'))
			BEGIN
			  ;WITH Result AS (SELECT 
				 lot.LotId
				,lot.LotNumber
				,lot.LotName
				,ISNULL(sl.PurchaseOrderId,0) PurchaseOrderId
				,ISNULL(sl.RepairOrderId,0) RepairOrderId
				,ISNULL(sl.WorkOrderId,0) WorkOrderId
				,ISNULL(0,0) QuoteId
				,ISNULL(so.SalesOrderId,0) SalesOrderId
				,ISNULL(ltin.LotTransInOutId,0) LotTransInOutId
				,ISNULL(ltCal.LotCalculationId,0) LotCalculationId
				,im.PartNumber
				,im.PartDescription AS Description
				,sl.StockLineId
				,sl.SerialNumber AS SerialNum
				,sl.StockLineNumber StkLineNum
				,ic.ItemClassificationCode ItemClassfication
				,ig.Description AS ItemGroup
				,c.Description AS Condition
				,UPPER(sl.UnitOfMeasure) AS Uom
				,ltCal.Qty Qty
				,ISNULL(sl.PurchaseOrderUnitCost,0.00) AS UnitPrice
				--,(ISNULL(sl.UnitCost,0) * (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END)) AS ExtendedPrice
				,(ISNULL(sl.UnitCost,0) * ltCal.Qty) AS ExtendedPrice
				,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
				,ISNULL(sl.QuantityReserved, 0) AS QtyRes
				,ISNULL(sl.QuantityIssued, 0) AS QtyIss
				,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
				,ISNULL(sl.PurchaseOrderUnitCost,0.00) Cost
				--,(ISNULL(sl.PurchaseOrderUnitCost,0)* (CASE WHEN ISNULL(ltin.QtyToTransIn,0) = 0 THEN ISNULL(ltin.QtyToTransOut,0) ELSE ISNULL(ltin.QtyToTransIn,0) END)) ExtCost
				,(ISNULL(sl.UnitCost,0)* ltCal.Qty) ExtCost
				,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				,ISNULL(sl.UnitCost,0) AS TotalCost
				--,(ISNULL(sl.RepairOrderUnitCost,0) + (ISNULL(sl.PurchaseOrderUnitCost,0))) TotalCost
				----,ro.RepairOrderNumber RoNum
				--,wo.WorkOrderNum WoNum
				,(CASE WHEN ISNULL(SL.RepairOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 rod.RepairOrderNumber FROM dbo.RepairOrder rod WITH(NOLOCK) WHERE rod.RepairOrderId = sl.RepairOrderId) END) RoNum
				--,wo.WorkOrderNum WoNum
				,(CASE WHEN ISNULL(SL.WorkOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 wod.WorkOrderNum FROM dbo.WorkOrder wod WITH(NOLOCK) WHERE wod.WorkOrderId = sl.WorkOrderId) END) WoNum
				,So.SalesOrderNumber SoNum
				,sobi.InvoiceNo InvoiceNum 
				,ven.VendorName Vendor
				,ISNULL(ven.VendorCode,'')VendorCode
				,ISNULL(ven.VendorId,0) VendorId
				,sl.Site AS Site
				,sl.Warehouse
				,sl.Location
				,sl.Shelf
				,sl.Bin
				,UPPER(MSD.LastMSLevel)	LastMSLevel
				,UPPER(MSD.AllMSlevels) AllMSlevels
				,ISNULL(so.CustomerId,0) SoCustomerId
				,sl.ConditionId
				,sl.ItemMasterId
				,sl.CustomerId
				,sl.ControlNumber
				,sl.IdNumber
				,(CASE WHEN SL.TraceableToType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.[TraceableTo] )
						    WHEN SL.TraceableToType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleOthersId THEN SL.[TraceableToName]
					   END) AS [TraceableToName],
				(CASE WHEN SL.TaggedByType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.TaggedBy )
						    WHEN SL.TaggedByType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleOthersId THEN SL.[TaggedByName]
					   END) [TaggedByName]
				,sl.TagDate
				,sl.TraceableTo
				,sl.TraceableToType
				,sl.TaggedBy
				,sl.TaggedByType
				,ISNULL(lot.InitialPOCost,0)InitialPOCost
				,ISNULL(lot.StocklineTotalCost,0)StocklineTotalCost
				,(ISNULL(lot.InitialPOCost,0) - ISNULL(lot.StocklineTotalCost,0))AS RemainStocklineCost
				,sl.Memo
				,Sl.LotSourceId
				,Sl.IsFromInitialPO
				,SL.LotMainStocklineId
				,ISNULL(sl.Adjustment,0) Adjustment
				,ltCal.CreatedDate
				,im.ManufacturerName
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN #commonTemp sl on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 INNER JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on ltCal.ReferenceId = so.SalesOrderId AND UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransOut_SO,' ',''))
					 LEFT JOIN DBO.SalesOrderPartV1 sop WITH(NOLOCK) on ltcal.ChildId = sop.SalesOrderPartId AND so.SalesOrderId = sop.SalesOrderId
					 LEFT JOIN DBO.SalesOrderBillingInvoicing sobi on so.SalesOrderId = sobi.SalesOrderId AND sobi.MasterCompanyId = so.MasterCompanyId AND ISNULL(sobi.IsProforma,0) = 0
					 LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii on sop.SalesOrderPartId = sobii.SalesOrderPartId AND sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobii.IsProforma,0) = 0
					 LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
					 LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.UnitOfMeasure uom  WITH(NOLOCK) ON sl.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId 
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	AND MSD.EntityMSID = Lot.ManagementStructureId
				 WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId AND (UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransIn_RO,' ','')))
				 ), ResultCount AS(Select COUNT(*) AS totalItems FROM Result) 

				SELECT * INTO #RepairedViewTbl FROM  Result 
				WHERE 
				((@GlobalFilter <>'' AND ((Partnumber LIKE '%' + @GlobalFilter + '%') OR
					([Description] LIKE '%' + @GlobalFilter + '%') OR
					(StkLineNum LIKE '%' + @GlobalFilter + '%') OR
					(SerialNum LIKE '%' + @GlobalFilter + '%') OR
					(Condition LIKE '%' + @GlobalFilter + '%') OR
					(Uom LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyOnHand AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyRes AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyIss AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(QtyAvailable AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(ExtCost like '%' + @GlobalFilter + '%') OR
					(RepairCost like '%' + @GlobalFilter + '%') OR
					(TotalCost like '%' + @GlobalFilter + '%') OR
					(WONum like '%' + @GlobalFilter + '%') OR
					(RoNum like '%' + @GlobalFilter + '%') OR
					(WoNum like '%' + @GlobalFilter + '%') OR
					(SoNum like '%' + @GlobalFilter + '%') OR
					(Vendor like '%' + @GlobalFilter + '%') OR
					(InvoiceNum like '%' + @GlobalFilter + '%') OR
					(LastMSLevel like '%' + @GlobalFilter + '%') OR
					(ItemClassfication like '%' + @GlobalFilter + '%') OR
					(ItemGroup like '%' + @GlobalFilter + '%') OR
					(Qty like '%' + @GlobalFilter + '%') OR
					(Cost like '%' + @GlobalFilter + '%') OR
					(Site like '%' + @GlobalFilter + '%') OR
					(Warehouse like '%' + @GlobalFilter + '%') OR
					(Location like '%' + @GlobalFilter + '%') OR
					(Shelf like '%' + @GlobalFilter + '%') OR
					(Bin like '%' + @GlobalFilter + '%') OR
					(UnitPrice like '%' + @GlobalFilter + '%') OR
					(ExtendedPrice like '%' + @GlobalFilter + '%') OR
					
					(LotNumber LIKE '%' + @GlobalFilter + '%') OR
					(LotName LIKE '%' + @GlobalFilter + '%') OR
					(Uom LIKE '%' + @GlobalFilter + '%') OR
					(ControlNumber like '%' + @GlobalFilter + '%') OR
					(IdNumber like '%' + @GlobalFilter + '%') OR
					(TraceableToName like '%' + @GlobalFilter + '%') OR
					(TaggedByName like '%' + @GlobalFilter + '%') OR
					(TagDate like '%' + @GlobalFilter + '%') OR
					(InitialPOCost like '%' + @GlobalFilter + '%') OR
					(StocklineTotalCost like '%' + @GlobalFilter + '%') OR
					(RemainStocklineCost like '%' + @GlobalFilter + '%') OR
					(Adjustment like '%' + @GlobalFilter + '%') OR
						(ManufacturerName like '%' + @GlobalFilter + '%') OR	
					(VendorCode like '%' + @GlobalFilter + '%')
					))
					OR
					(@GlobalFilter = '' AND (ISNULL(@Partnumber, '') = '' OR Partnumber LIKE '%' + @Partnumber + '%') AND
					(ISNULL(@Description, '') = '' OR [Description] LIKE '%' + @Description + '%') AND
					(ISNULL(@StkLineNum, '') = '' OR StkLineNum LIKE '%' + @StkLineNum + '%') AND
					(ISNULL(@SerialNum, '') = '' OR SerialNum LIKE '%' + @SerialNum + '%') AND
					(ISNULL(@Condition, '') = '' OR Condition LIKE '%' + @Condition + '%') AND
					(ISNULL(@Uom,'') ='' OR Uom LIKE '%' + @Uom + '%') AND
					(IsNull(@QtyOnHand, 0) = 0 OR CAST(QtyOnHand as VARCHAR(10)) like @QtyOnHand) AND
					(IsNull(@QtyRes, 0) = 0 OR CAST(QtyRes as VARCHAR(10)) like @QtyRes) AND
					(IsNull(@QtyIss, 0) = 0 OR CAST(QtyIss as VARCHAR(10)) like @QtyIss) AND
					(IsNull(@QtyAvailable, 0) = 0 OR CAST(QtyAvailable as VARCHAR(10)) like @QtyAvailable) AND

					(ISNULL(@ExtCost, 0) = 0 OR CAST(ExtCost as VARCHAR(10)) = @ExtCost) AND
					(ISNULL(@RepairCost, 0) = 0 OR CAST(RepairCost as VARCHAR(10)) = @RepairCost) AND
					(ISNULL(@TotalCost, 0) = 0 OR CAST(TotalCost as VARCHAR(10)) = @TotalCost) AND
					(ISNULL(@WONum, '') = '' OR WONum  like '%'+ @WONum + '%') AND
					--(ISNULL(@LastPODate,'') ='' OR CAST(LastPODate AS Date) = CAST(@LastPODate AS date)) AND
					(ISNULL(@RoNum,'') ='' OR RoNum LIKE '%' + @RoNum + '%') AND
					(ISNULL(@WoNum,'') ='' OR WoNum LIKE '%' + @WoNum + '%') AND
					(ISNULL(@SoNum,'') ='' OR SoNum LIKE '%' + @SoNum + '%') AND
					(ISNULL(@Vendor,'') ='' OR Vendor LIKE '%' + @Vendor + '%') AND
					(ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND
					(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%' + @LastMSLevel + '%') AND
					(ISNULL(@ItemClassfication,'') ='' OR ItemClassfication LIKE '%' + @ItemClassfication + '%') AND
					(ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND
					(IsNull(@Qty, 0) = 0 OR CAST(Qty as VARCHAR(10)) like @Qty) AND
					(ISNULL(@Site,'') ='' OR Site LIKE '%' + @Site + '%') AND
					(ISNULL(@Warehouse,'') ='' OR Warehouse LIKE '%' + @Warehouse + '%') AND
					(ISNULL(@Location,'') ='' OR Location LIKE '%' + @Location + '%') AND
					(ISNULL(@Shelf,'') ='' OR Shelf LIKE '%' + @Shelf + '%') AND
					(ISNULL(@Bin,'') ='' OR Bin LIKE '%' + @Bin + '%') AND
					(ISNULL(@Cost, 0) = 0 OR CAST(Cost as VARCHAR(10)) = @Cost) AND
					(ISNULL(@UnitPrice, 0) = 0 OR CAST(UnitPrice as VARCHAR(10)) = @UnitPrice) AND
					(ISNULL(@ExtendedPrice, 0) = 0 OR CAST(RepairCost as VARCHAR(10)) = @ExtendedPrice) AND
					(IsNull(@VendorCode, '') = '' OR VendorCode like '%' + @VendorCode + '%')AND
					
					(ISNULL(@LotNumber, '') = '' OR LotNumber LIKE '%' + @LotNumber + '%') AND
					(ISNULL(@LotName, '') = '' OR LotName LIKE '%' + @LotName + '%') AND
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND
					(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND		
					(ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND		
					(ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND
					(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date) = CAST(@TagDate AS date)) AND
					(ISNULL(@InitialPOCost, 0) = 0 OR CAST(InitialPOCost as VARCHAR(10)) LIKE @InitialPOCost) AND
					(ISNULL(@StocklineTotalCost, 0) = 0 OR CAST(StocklineTotalCost as VARCHAR(10)) LIKE @StocklineTotalCost) AND
					(ISNULL(@RemainStocklineCost, 0) = 0 OR CAST(RemainStocklineCost as VARCHAR(10)) LIKE @RemainStocklineCost) AND
					(ISNULL(@Adjustment, 0) = 0 OR CAST(Adjustment as VARCHAR(10)) LIKE @Adjustment) AND
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(ISNULL(@Uom,'') ='' OR Uom LIKE '%' + @Uom + '%') 
					)
				  )

				SELECT @Count = COUNT(*) FROM #RepairedViewTbl
			
				SELECT *, @Count AS NumberOfItems FROM #RepairedViewTbl
				ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNum')  THEN SerialNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNum')  THEN SerialNum END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StkLineNum')  THEN StkLineNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StkLineNum')  THEN StkLineNum END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Uom')  THEN Uom END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Uom')  THEN Uom END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyOnHand')  THEN QtyOnHand END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyOnHand')  THEN QtyOnHand END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyRes')  THEN QtyRes END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyRes')  THEN QtyRes END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyIss')  THEN QtyIss END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyIss')  THEN QtyIss END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='QtyAvailable')  THEN QtyAvailable END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyAvailable')  THEN QtyAvailable END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ExtCost')  THEN ExtCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ExtCost')  THEN ExtCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RepairCost')  THEN RepairCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RepairCost')  THEN RepairCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TotalCost')  THEN TotalCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TotalCost')  THEN TotalCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RoNum')  THEN RoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RoNum')  THEN RoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='WoNum')  THEN WoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='WoNum')  THEN WoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='SoNum')  THEN SoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='SoNum')  THEN SoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Vendor')  THEN Vendor END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Vendor')  THEN Vendor END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ItemClassfication')  THEN ItemClassfication END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ItemClassfication')  THEN ItemClassfication END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Qty')  THEN Qty END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Qty')  THEN Qty END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Site')  THEN Site END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Site')  THEN Site END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Warehouse')  THEN Warehouse END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Warehouse')  THEN Warehouse END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Location')  THEN Location END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Location')  THEN Location END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Shelf')  THEN Shelf END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Shelf')  THEN Shelf END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Bin')  THEN Bin END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Bin')  THEN Bin END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Cost')  THEN Cost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Cost')  THEN Cost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='UnitPrice')  THEN UnitPrice END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='UnitPrice')  THEN UnitPrice END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ExtendedPrice')  THEN ExtendedPrice END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ExtendedPrice')  THEN ExtendedPrice END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LotNumber')  THEN LotNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotNumber')  THEN LotNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LotName')  THEN LotName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotName')  THEN LotName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='IdNumber')  THEN IdNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='IdNumber')  THEN IdNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TraceableToName')  THEN TraceableToName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TraceableToName')  THEN TraceableToName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TaggedByName')  THEN TaggedByName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TaggedByName')  THEN TaggedByName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TagDate')  THEN TagDate END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TagDate')  THEN TagDate END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InitialPOCost')  THEN InitialPOCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InitialPOCost')  THEN InitialPOCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='StocklineTotalCost')  THEN StocklineTotalCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='StocklineTotalCost')  THEN StocklineTotalCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RemainStocklineCost')  THEN RemainStocklineCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RemainStocklineCost')  THEN RemainStocklineCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Adjustment')  THEN Adjustment END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Adjustment')  THEN Adjustment END DESC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='VendorCode')  THEN VendorCode END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='VendorCode')  THEN VendorCode END DESC
				,CreatedDate  DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY

			END
			ELSE IF(UPPER(@Type) = UPPER('OtherCost'))
			BEGIN
			;WITH Result AS (SELECT
				 lot.LotId
				,ISNULL(po.PurchaseOrderId,0) PurchaseOrderId			
				,ven.VendorName Vendor
				,ISNULL(ven.VendorCode,'') VendorCode
				,ISNULL(ven.VendorId,0) VendorId			
				,ISNULL((SELECT SUM(ISNULL(PF.Amount,0)) FROM dbo.PurchaseOrderFreight PF WITH(NOLOCK) WHERE PF.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PF.IsDeleted,0) = 0),0) AS FreightCost
				,ISNULL((SELECT SUM(ISNULL(PC.ExtendedCost,0)) FROM dbo.PurchaseOrderCharges PC WITH(NOLOCK) WHERE PC.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PC.IsDeleted,0) = 0),0) AS ChargesCost
				,Po.CreatedDate AS PoDate
				,po.PurchaseOrderNumber AS PoNum			
				,part.PartNumber
				,part.PartDescription
				,part.Condition
				,part.Manufacturer
				FROM DBO.PurchaseOrder po WITH(NOLOCK)
					 INNER JOIN DBO.LOT lot WITH(NOLOCK) on po.LotId = lot.LotId
					 INNER JOIN PurchaseOrderPart part WITH(NOLOCK) on part.PurchaseOrderId = po.PurchaseOrderId
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN #commonTemp sl on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId AND ltCal.ReferenceId = po.PurchaseOrderId AND ltCal.ChildId = part.PurchaseOrderPartRecordId
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON po.VendorId = ven.VendorId
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	AND MSD.EntityMSID = Lot.ManagementStructureId
				 WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId 
					   AND (ISNULL((SELECT SUM(ISNULL(PF.Amount,0)) FROM dbo.PurchaseOrderFreight PF WITH(NOLOCK) WHERE PF.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PF.IsDeleted,0) = 0),0) > 0 
							OR ISNULL((SELECT SUM(ISNULL(PC.ExtendedCost,0)) FROM dbo.PurchaseOrderCharges PC WITH(NOLOCK) WHERE PC.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND ISNULL(PC.IsDeleted,0) = 0),0) >0)
				
				UNION ALL

					SELECT
					 lot.LotId
					,ISNULL(ro.RepairOrderId,0) PurchaseOrderId			
					,ven.VendorName Vendor
					,ISNULL(ven.VendorCode,'') VendorCode
					,ISNULL(ven.VendorId,0) VendorId			
					,ISNULL((SELECT SUM(ISNULL(PF.Amount,0)) FROM dbo.RepairOrderFreight PF WITH(NOLOCK) WHERE PF.RepairOrderPartRecordId = part.RepairOrderPartRecordId AND ISNULL(PF.IsDeleted,0) = 0),0) AS FreightCost
					,ISNULL((SELECT SUM(ISNULL(PC.ExtendedCost,0)) FROM dbo.RepairOrderCharges PC WITH(NOLOCK) WHERE PC.RepairOrderPartRecordId = part.RepairOrderPartRecordId AND ISNULL(PC.IsDeleted,0) = 0),0) AS ChargesCost
					,ro.CreatedDate AS PoDate
					,ro.RepairOrderNumber AS PoNum			
					,part.PartNumber
					,part.PartDescription
					,part.Condition
					,part.Manufacturer
					FROM DBO.LOT lot WITH(NOLOCK) 
						 INNER JOIN RepairOrderPart part WITH(NOLOCK) on part.LotId = lot.LotId
						 INNER JOIN RepairOrder ro WITH(NOLOCK) on part.RepairOrderId = ro.RepairOrderId
						 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
						 INNER JOIN #commonTemp sl on ltin.StockLineId = sl.StockLineId
						 INNER JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId AND ltCal.ReferenceId = ro.RepairOrderId AND ltCal.ChildId = part.RepairOrderPartRecordId AND ltCal.Type = 'Trans In (RO)'
						 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON ro.VendorId = ven.VendorId
						 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	AND MSD.EntityMSID = Lot.ManagementStructureId
					 WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId 
						   AND (ISNULL((SELECT SUM(ISNULL(PF.Amount,0)) FROM dbo.RepairOrderFreight PF WITH(NOLOCK) WHERE PF.RepairOrderPartRecordId = part.RepairOrderPartRecordId AND ISNULL(PF.IsDeleted,0) = 0),0) > 0 
								OR ISNULL((SELECT SUM(ISNULL(PC.ExtendedCost,0)) FROM dbo.RepairOrderCharges PC WITH(NOLOCK) WHERE PC.RepairOrderPartRecordId = part.RepairOrderPartRecordId AND ISNULL(PC.IsDeleted,0) = 0),0) >0)
				
				 ), ResultCount AS(Select COUNT(*) AS totalItems FROM Result) 

				 SELECT * INTO #OtherCostTbl FROM  Result 
				WHERE 
				((@GlobalFilter <>'' AND (
					(Condition LIKE '%' + @GlobalFilter + '%') OR
					(PoNum like '%' + @GlobalFilter + '%') OR
					(Vendor like '%' + @GlobalFilter + '%') OR
					(VendorCode like '%' + @GlobalFilter + '%') OR
					(PoDate like '%' + @GlobalFilter + '%') OR
					(PartNumber like '%' + @GlobalFilter + '%') OR
					(PartDescription like '%' + @GlobalFilter + '%') OR
					(Manufacturer like '%' + @GlobalFilter + '%') OR
					(FreightCost like '%' + @GlobalFilter + '%') OR
					(ChargesCost like '%' + @GlobalFilter + '%')
					))
					OR
					(@GlobalFilter = '' AND 
					(ISNULL(@Condition, '') = '' OR Condition LIKE '%' + @Condition + '%') AND
					(ISNULL(@PoNum,'') ='' OR PoNum LIKE '%' + @PoNum + '%') AND
					(ISNULL(@Vendor,'') ='' OR Vendor LIKE '%' + @Vendor + '%') AND
					(IsNull(@VendorCode, '') = '' OR VendorCode like '%' + @VendorCode + '%') AND
					
					(IsNull(@PartNumber, '') = '' OR PartNumber like '%' + @PartNumber + '%') AND
					(IsNull(@Description, '') = '' OR PartDescription like '%' + @Description + '%') AND
					(IsNull(@ManufacturerName, '') = '' OR Manufacturer like '%' + @ManufacturerName + '%') AND
					
					(ISNULL(@FreightCost, 0) = 0 OR CAST(FreightCost as VARCHAR(10)) = @FreightCost) AND
					(ISNULL(@ChargesCost, 0) = 0 OR CAST(ChargesCost as VARCHAR(10)) = @ChargesCost) AND
					(ISNULL(@PoDate,'') ='' OR CAST(PoDate AS Date) = CAST(@PoDate AS date))
					)
				  )
				  Group by LotId,PurchaseOrderId,Vendor,VendorCode,VendorId,FreightCost,ChargesCost,PoDate,PoNum,PartNumber,PartDescription,Condition,Manufacturer 
				  --ORDER BY PoDate DESC

				SELECT @Count = COUNT(*) FROM #OtherCostTbl

				SELECT *, @Count AS NumberOfItems FROM #OtherCostTbl
				ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PoNum')  THEN PoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PoNum')  THEN PoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Vendor')  THEN Vendor END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Vendor')  THEN Vendor END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='VendorCode')  THEN VendorCode END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='VendorCode')  THEN VendorCode END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='FreightCost')  THEN FreightCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='FreightCost')  THEN FreightCost END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ChargesCost')  THEN ChargesCost END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ChargesCost')  THEN ChargesCost END DESC,

				CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Manufacturer')  THEN Manufacturer END DESC,
				
				CASE WHEN (@SortOrder=1 and @SortColumn='PoDate')  THEN PoDate END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PoDate')  THEN PoDate END DESC

				,PoDate  DESC
				OFFSET @RecordFrom ROWS 

				FETCH NEXT @PageSize ROWS ONLY
				 --Select * from Result Group by LotId,PurchaseOrderId,Vendor,VendorCode,VendorId,FreightCost,ChargesCost,PoDate,PoNum,PartNumber,PartDescription,Condition,Manufacturer ORDER BY PoDate DESC
			END
			ELSE IF(UPPER(@Type) = UPPER('Commission'))
			BEGIN
			   ;WITH Result AS (SELECT 
				 lot.LotId
				,lot.LotNumber
				,lot.LotName
				,ISNULL(so.SalesOrderId,0) SalesOrderId
				,ISNULL(ltin.LotTransInOutId,0) LotTransInOutId
				,ISNULL(ltCal.LotCalculationId,0) LotCalculationId
				,im.PartNumber
				,im.PartDescription AS Description
				,sl.StockLineId
				,sl.SerialNumber AS SerialNum
				,sl.StockLineNumber StkLineNum
				--,(CASE  WHEN ltCal.Type = @LOT_TransOut_SO OR ltCal.Type = @LOT_TransOut_LOT OR  ltCal.Type = @LOT_TransOut_RO THEN ltCal.TransferredOutCost ELSE ltCal.TransferredInCost END) TransUnitCost
				,ltCal.SalesUnitPrice UnitSalesPrice
				,ltCal.ExtSalesUnitPrice ExtPrice
				,ltCal.MarginAmount MarginAmt
				--,ltCal.Margin Margin
				,CASE WHEN ISNULL(ltCal.ExtSalesUnitPrice,0) = 0 THEN 0 ELSE CONVERT(DECIMAL(10,2),((100 * ISNULL(ltCal.MarginAmount,0))/ISNULL(ltCal.ExtSalesUnitPrice,1)))END Margin
				,ISNULL(ltCal.CommissionExpense,0) AS CommissionExpense
				,So.SalesOrderNumber SoNum
				,sobi.InvoiceNo InvoiceNum 
				,lot.ReferenceNumber ReferenceNum
				,UPPER(MSD.LastMSLevel)	LastMSLevel
				,UPPER(MSD.AllMSlevels) AllMSlevels
				,ISNULL(so.CustomerId,0) SoCustomerId
				,ltCal.CreatedDate
				,sl.ConditionId
				,sl.ItemMasterId
				,sl.CustomerId
				,sl.ControlNumber
				,sl.IdNumber
				,(CASE WHEN SL.TraceableToType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.[TraceableTo] )
						    WHEN SL.TraceableToType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.[TraceableTo])
						    WHEN SL.TraceableToType = @AppModuleOthersId THEN SL.[TraceableToName]
					   END) AS [TraceableToName],
				(CASE WHEN SL.TaggedByType = @AppModuleCustomerId THEN (SELECT CUT.[Name] FROM [dbo].[Customer] CUT WHERE CUT.CustomerId = SL.TaggedBy )
						    WHEN SL.TaggedByType = @AppModuleVendorId THEN (SELECT VET.[VendorName] FROM [dbo].[Vendor] VET WHERE VET.[VendorId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleCompanyId THEN (SELECT CTT.[Name] FROM [dbo].[LegalEntity] CTT WHERE CTT.[LegalEntityId] = SL.TaggedBy)
						    WHEN SL.TaggedByType = @AppModuleOthersId THEN SL.[TaggedByName]
					   END) [TaggedByName] 
				,sl.TagDate
				,sl.TraceableTo
				,sl.TraceableToType
				,sl.TaggedBy
				,sl.TaggedByType
				,SL.LotMainStocklineId
		        ,ISNULL(sl.Adjustment,0) Adjustment		
				,im.ManufacturerName
			    ,(CASE WHEN ISNULL(lc.IsRevenue,0) = 1 THEN 'REVENUE' WHEN ISNULL(lc.IsMargin,0) = 1 THEN 'MARGIN' WHEN ISNULL(lc.IsFixedAmount,0) = 1 THEN 'FIXED AMOUNT' WHEN ISNULL(lc.IsRevenueSplit,0) = 1 THEN 'REVENUE SPLIT' ELSE '' END) HowCalculate

				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN #commonTemp sl on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 INNER JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 INNER JOIN DBO.SalesOrder so WITH(NOLOCK) on ltCal.ReferenceId = so.SalesOrderId AND UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransOut_SO,' ',''))
					 INNER JOIN DBO.SalesOrderPartV1 sop WITH(NOLOCK) on ltcal.ChildId = sop.SalesOrderPartId AND so.SalesOrderId = sop.SalesOrderId
					 INNER JOIN DBO.LotConsignment LC WITH(NOLOCK) on lot.LotId = LC.LotId
					 LEFT JOIN DBO.SalesOrderBillingInvoicing sobi on so.SalesOrderId = sobi.SalesOrderId AND sobi.MasterCompanyId = so.MasterCompanyId AND ISNULL(sobi.IsProforma,0) = 0
					 LEFT JOIN dbo.LotManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AppModuleId,',')) AND MSD.ReferenceID = lot.LotId	
				WHERE lot.LotId = @LotId AND lot.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(*) AS totalItems FROM Result) 

				SELECT * INTO #CommisionResult FROM  Result
				WHERE
				 (
					(@GlobalFilter <>'' AND (
					(LotNumber LIKE '%' + @GlobalFilter + '%') OR
					(LotName LIKE '%' + @GlobalFilter + '%') OR
					(Partnumber LIKE '%' + @GlobalFilter + '%') OR
					([Description] LIKE '%' + @GlobalFilter + '%') OR
					(StkLineNum LIKE '%' + @GlobalFilter + '%') OR
					(SerialNum LIKE '%' + @GlobalFilter + '%') OR
					(UnitSalesPrice like '%' + @GlobalFilter + '%') OR
					(ExtPrice like '%' + @GlobalFilter + '%') OR
					(MarginAmt like '%' + @GlobalFilter + '%') OR
					(Margin like '%' + @GlobalFilter + '%') OR
					(SoNum like '%' + @GlobalFilter + '%') OR
					(InvoiceNum like '%' + @GlobalFilter + '%') OR
					(LastMSLevel like '%' + @GlobalFilter + '%') OR			
					(ReferenceNum like '%' + @GlobalFilter + '%') OR
					(ControlNumber like '%' + @GlobalFilter + '%') OR
					(IdNumber like '%' + @GlobalFilter + '%') OR
					(TraceableToName like '%' + @GlobalFilter + '%') OR
					(TaggedByName like '%' + @GlobalFilter + '%') OR
					(TagDate like '%' + @GlobalFilter + '%') OR
					(CommissionExpense like '%' + @GlobalFilter + '%') OR
					
					(HowCalculate like '%' + @GlobalFilter + '%') OR
					(ManufacturerName like '%' + @GlobalFilter + '%') OR					
					(Adjustment like '%' + @GlobalFilter + '%')
					))
					OR
					(@GlobalFilter = '' AND 	
					(ISNULL(@Partnumber, '') = '' OR Partnumber LIKE '%' + @Partnumber + '%') AND
					(ISNULL(@Description, '') = '' OR [Description] LIKE '%' + @Description + '%') AND
					(ISNULL(@StkLineNum, '') = '' OR StkLineNum LIKE '%' + @StkLineNum + '%') AND
					(ISNULL(@SerialNum, '') = '' OR SerialNum LIKE '%' + @SerialNum + '%') AND
					(ISNULL(@ExtPrice, 0) = 0 OR CAST(ExtPrice as VARCHAR(10)) LIKE @ExtPrice) AND
					(ISNULL(@MarginAmt, 0) = 0 OR CAST(MarginAmt as VARCHAR(10)) LIKE @MarginAmt) AND
					(ISNULL(@Margin, 0) = 0 OR CAST(Margin as VARCHAR(10)) LIKE @Margin) AND
					(ISNULL(@SoNum,'') ='' OR SoNum LIKE '%' + @SoNum + '%') AND
					(ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND
					(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%' + @LastMSLevel + '%') AND
					(ISNULL(@LotNumber, '') = '' OR LotNumber LIKE '%' + @LotNumber + '%') AND
					(ISNULL(@LotName, '') = '' OR LotName LIKE '%' + @LotName + '%') AND
					(ISNULL(@ReferenceNum,'') ='' OR ReferenceNum LIKE '%' + @ReferenceNum + '%') AND
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND
					(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND		
					(ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND		
					(ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND
					(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date) = CAST(@TagDate AS date)) AND
					(ISNULL(@Adjustment, 0) = 0 OR CAST(Adjustment as VARCHAR(10)) LIKE @Adjustment) AND
					(ISNULL(@CommissionExpense, 0) = 0 OR CAST(CommissionExpense as VARCHAR(10)) LIKE @CommissionExpense) AND	
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(ISNULL(@HowCalculate, '') = '' OR HowCalculate LIKE '%' + @HowCalculate + '%') AND
					(ISNULL(@UnitSalePrice, 0) = 0 OR CAST(UnitSalesPrice as VARCHAR(10)) LIKE @UnitSalePrice)))

				SELECT @Count = COUNT(*) FROM #CommisionResult
			
				SELECT *, @Count AS NumberOfItems FROM #CommisionResult
				ORDER BY 	
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNum')  THEN SerialNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNum')  THEN SerialNum END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StkLineNum')  THEN StkLineNum END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StkLineNum')  THEN StkLineNum END DESC,			
				CASE WHEN (@SortOrder=1 and @SortColumn='ExtPrice')  THEN ExtPrice END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ExtPrice')  THEN ExtPrice END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='MarginAmt')  THEN MarginAmt END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='MarginAmt')  THEN MarginAmt END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Margin')  THEN Margin END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Margin')  THEN Margin END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='SoNum')  THEN SoNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='SoNum')  THEN SoNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LotNumber')  THEN LotNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotNumber')  THEN LotNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='LotName')  THEN LotName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='LotName')  THEN LotName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ReferenceNum')  THEN ReferenceNum END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ReferenceNum')  THEN ReferenceNum END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='IdNumber')  THEN IdNumber END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='IdNumber')  THEN IdNumber END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TraceableToName')  THEN TraceableToName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TraceableToName')  THEN TraceableToName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TaggedByName')  THEN TaggedByName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TaggedByName')  THEN TaggedByName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='TagDate')  THEN TagDate END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='TagDate')  THEN TagDate END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Adjustment')  THEN Adjustment END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Adjustment')  THEN Adjustment END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='CommissionExpense')  THEN CommissionExpense END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='CommissionExpense')  THEN CommissionExpense END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='HowCalculate')  THEN HowCalculate END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='HowCalculate')  THEN HowCalculate END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='UnitSalesPrice')  THEN UnitSalesPrice END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='UnitSalesPrice')  THEN UnitSalesPrice END DESC
				,CreatedDate  DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
		END
	COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
		    SELECT  
            ERROR_NUMBER() AS ErrorNumber  
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  

			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Lot_GetAllLotViewsByLotId' 
               , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LotId, '') + ''',
														@Parameter2 = ' + ISNULL(@Type,'') + ', 
														@Parameter3 = ' + ISNULL(@MasterCompanyId,'') + ''
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