/*************************************************************             
 ** File:   [USP_Lot_GetStocklineHistoryById]             
 ** Author: RAJESH GAMI
 ** Description: This stored procedure is used to Get History Of particular LOT Stockline
 ** Date:   27/Aug/2025  
 ** PARAMETERS:             
 ** RETURN VALUE:  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		---------------------------       
    1   27/Aug/2025  RAJESH GAMI     Created  
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	4    23/July/2026			 RAJESH GAMI						[PN-17350] - Removed 2 leftover IsNonStock=0 exclusion filters added during PN-17008/PN-17009 transitional Non-Stock merge phase (Non-Stock is now merged; filters no longer needed).
	5    25-Aug-2026			 RAJESH GAMI						[PN-17745] Ported from PAS_DB - HowAcquired/AcquiredRef CASE expressions now also recognize the new 'Turn In' type (in addition to 'Trans In(Lot)') so stocklines created via "Create Stockline from Lot" are still displayed correctly.
**************************************************************
EXEC USP_Lot_GetStocklineHistoryById 34,207818,1,245  
**************************************************************/  
CREATE PROCEDURE [dbo].[USP_Lot_GetStocklineHistoryById]   
@LotId bigint ,
@StockLineId bigint,
@MasterCompanyId bigint =NULL,
@EmployeeId bigint
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY  
  BEGIN TRANSACTION  
 BEGIN 
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
			DECLARE @LOT_PO_Type VARCHAR(100) = 'PO'; DECLARE @LOT_RO_Type VARCHAR(100)= 'RO'; DECLARE @LOT_SO_Type VARCHAR(100)= 'SO';	DECLARE @LOT_WO_Type VARCHAR(100)= 'WO';
			DECLARE @LOT_TransIn_LOT VARCHAR(100) = 'Trans In(Lot)'; DECLARE @LOT_TransIn_PO VARCHAR(100) = 'Trans In(PO)';	DECLARE @LOT_TransIn_RO VARCHAR(100) = 'Trans In(RO)';
			DECLARE @LOT_TransIn_SO VARCHAR(100) = 'Trans In(SO)'; DECLARE @LOT_TransIn_WO VARCHAR(100) = 'Trans In(WO)'; DECLARE @LOT_TransOut_LOT VARCHAR(100) = 'Trans Out(Lot)';
			DECLARE @LOT_TransOut_PO VARCHAR(100) = 'Trans Out(PO)'; DECLARE @LOT_TransOut_RO VARCHAR(100) = 'Trans Out(RO)';
			DECLARE @LOT_TransOut_SO VARCHAR(100) = 'Trans Out(SO)'; DECLARE @LOT_TransOut_WO VARCHAR(100) = 'Trans Out(WO)',@LOT_SO_Shipped VARCHAR(100) = 'Shipped';
			DECLARE @LOT_TurnIn VARCHAR(100) = 'Turn In';
			DECLARE @LotTransIn VARCHAR(100) = 'Trans In',@LotTransOut VARCHAR(100) = 'Trans Out', @LotPO VARCHAR(100) = 'Purchase Order',@LotRO VARCHAR(100) = 'Repair Order',@LotSO VARCHAR(100) = 'Sales Order', @LotWO VARCHAR(100) = 'Work Order';
			DECLARE @SOModuleId INT = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder')
			
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

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
				INNER JOIN DBO.Stockline sl WITH(NOLOCK) on ltin.StockLineId = sl.StockLineId WHERE ltin.LotId = @LotId And ltin.StockLineId = @StockLineId


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
				,c.Description AS Condition
				,UPPER(sl.UnitOfMeasure) AS Uom
				,(CASE WHEN UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransOut_SO,' ','')) THEN 'INVOICED'
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
				,(ISNULL(sl.UnitCost,0) * ltCal.Qty) ExtCost
				,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				,ISNULL(sl.UnitCost,0) AS TotalCost
				,ltCal.SalesUnitPrice UnitSalesPrice
				,ltCal.ExtSalesUnitPrice ExtPrice
				,ltCal.MarginAmount MarginAmt
				,CASE WHEN ISNULL(ltCal.ExtSalesUnitPrice,0) = 0 THEN 0 ELSE CONVERT(DECIMAL(10,2),((100 * ISNULL(ltCal.MarginAmount,0))/ISNULL(ltCal.ExtSalesUnitPrice,1)))END Margin
				,(CASE WHEN REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_TransIn_LOT,' ','')  THEN @LotTransIn
					    WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_LOT,' ','')  THEN @LotTransOut
						WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TurnIn,' ','')  THEN @LotTransIn
						WHEN REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_TransIn_PO,' ','')  THEN @LotPO
					   WHEN REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_TransIn_RO,' ','')  OR REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_RO,' ','') THEN @LotRO
					   WHEN REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_TransOut_SO,' ','') OR REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_SO_Shipped,' ','')  THEN @LotSO
					   WHEN REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_TransIn_WO,' ','')  THEN @LotWO
				ELSE '' END) HowAcquired
				,(CASE WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransIn_LOT,' ','') OR REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_LOT,' ','') OR REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TurnIn,' ','') THEN sl.StockLineNumber
					   WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransIn_PO,' ','')  THEN (CASE WHEN ISNULL(SL.PurchaseOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 pod.PurchaseOrderNumber FROM dbo.PurchaseOrder pod WITH(NOLOCK) WHERE pod.PurchaseOrderId = sl.PurchaseOrderId) END)
					   WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransIn_RO,' ','')  OR REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_RO,' ','') THEN (CASE WHEN ISNULL(SL.RepairOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 rod.RepairOrderNumber FROM dbo.RepairOrder rod WITH(NOLOCK) WHERE rod.RepairOrderId = sl.RepairOrderId) END) 
					   WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransOut_SO,' ','') OR REPLACE(ltCal.Type,' ','')  = REPLACE(@LOT_SO_Shipped,' ','')  THEN so.SalesOrderNumber 
					   WHEN REPLACE(ltCal.Type,' ','') = REPLACE(@LOT_TransIn_WO,' ','')  THEN (CASE WHEN ISNULL(SL.WorkOrderId,0) = 0 then ''  ELSE (SELECT TOP 1 wod.WorkOrderNum FROM dbo.WorkOrder wod WITH(NOLOCK) WHERE wod.WorkOrderId = sl.WorkOrderId) END)
				ELSE '' END) AS AcquiredRef
				,So.SalesOrderNumber SoNum
				,sobi.InvoiceNo InvoiceNum 
				,ven.VendorName Vendor 
				,ISNULL(ven.VendorCode,'')VendorCode
				,ISNULL(ven.VendorId,0) VendorId
				,lot.ReferenceNumber ReferenceNum
				,sl.CustomerName
				,ISNULL(so.CustomerId,0) SoCustomerId
			
				,sl.ConditionId
				,sl.ItemMasterId
				,sl.CustomerId
				,sl.ControlNumber
				,sl.IdNumber
				,ISNULL(lot.InitialPOCost,0)InitialPOCost
				,ISNULL(lot.StocklineTotalCost,0)StocklineTotalCost
				,(ISNULL(sl.UnitCost,0) * ltCal.Qty) AS RemainStocklineCost
				,Sl.LotSourceId
				,Sl.IsFromInitialPO
				,ISNULL(Sl.IsCustomerStock, 0) IsCustomerStock
				,SL.LotMainStocklineId
				,im.ManufacturerName
				,sobi.InvoiceDate InvoiceDate
				,ISNULL(ltin.ReferenceNumber,'') as ReferenceNumber
				,ltCal.CreatedDate	,ltCal.CreatedBy	,  case when CAST(ltCal.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(ltCal.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime2)) END AS UpdatedDate 	,ltCal.UpdatedBy
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN #commonTemp sl on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 Inner JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on ltCal.ReferenceId = so.SalesOrderId AND (UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_TransOut_SO,' ','')) OR UPPER(REPLACE(ltCal.Type,' ','')) = UPPER(REPLACE(@LOT_SO_Shipped,' ','')))
					 LEFT JOIN DBO.SalesOrderPartV1 sop WITH(NOLOCK) on ltcal.ChildId = sop.SalesOrderPartId AND so.SalesOrderId = sop.SalesOrderId
					 LEFT JOIN DBO.BillingInvoicing sobi WITH(NOLOCK) on so.SalesOrderId = sobi.ReferenceId AND sobi.MasterCompanyId = so.MasterCompanyId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.[ModuleId] = @SOModuleId
					 LEFT JOIN DBO.BillingInvoicingItems sobii WITH(NOLOCK) on sop.SalesOrderPartId = sobii.SubReferenceId AND sobi.BillingInvoicingId = sobii.BillingInvoicingId AND ISNULL(sobii.IsPerformaInvoice,0) = 0 AND sobii.[ModuleId] = @SOModuleId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId
				WHERE lot.LotId = @LotId AND ltin.StockLineId = @StockLineId AND lot.MasterCompanyId = @MasterCompanyId ), ResultCount AS(Select COUNT(*) AS totalItems FROM Result) 			
				SELECT * FROM Result ORDER BY UpdatedDate DESC	

 END  
 COMMIT  TRANSACTION  
  END TRY  
  BEGIN CATCH  
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
  DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,@AdhocComments varchar(150) = '[USP_Lot_GetStocklineHistoryById]',  
            @ProcedureParameters varchar(3000) = '@LotId = ''' + CAST(ISNULL(@LotId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'  
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