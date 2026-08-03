/* =====================================================================
 PN-17009 : BUGFIX - remove redundant/harmful IsNonStock filters on
            queries and updates that are already scoped to one exact
            @StockLineId (or equivalent single-record parameter).

 Root cause: during the PN-17009 sweep, many Stockline-related SPs got
 an "" / ""
 style filter added wherever dbo.ItemMaster or dbo.Stockline appeared in
 a query. That filter makes sense for LIST queries (e.g. the Stockline
 grid, PN dropdowns) where you're choosing WHICH rows to return. It does
 NOT make sense - and actively breaks things - on a query/UPDATE that is
 already pinned to one exact StockLineId via a parameter: the row you
 want is already uniquely identified, so filtering it out again by type
 just makes migrated Non-Stock Stockline records silently disappear
 (INNER JOIN cases) or lose their derived fields (LEFT JOIN cases).

 This is very likely the root cause of the "editing a migrated NonStock
 Stockline record redirects to /unauthorized-access" issue: with the
 filter in place, dbo.GetStockLineDetails returned ZERO rows for those
 records, so the API response body was empty and
 res.masterCompanyId != this.currentUserMasterCompanyId evaluated to
 true in stock-line-setup.component.ts, triggering the redirect.

 4 objects fixed (this file only - no other SPs changed):
   1) dbo.GetStockLineDetails                         (2 filters removed)
   2) dbo.UpdateStocklineColumnsWithId                 (8 filters removed)
   3) dbo.GetStocklineAuditById                        (2 filters removed)
   4) dbo.USP_GetStocklinePrintDataByStockLineId       (6 filters removed)

 In every case, filters on auxiliary/reference ItemMaster joins that
 point at a DIFFERENT item than the Stockline's own (RevisedPN, OEM PN,
 TLA, NHA, WorkOrderPartNumber's MPN) were deliberately left untouched -
 those are legitimate "only let Stock items be picked as this reference"
 rules, not the single-record redundancy bug.

 Author : RAJESH GAMI
 Date   : 13/July/2026
===================================================================== */

-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.GetStockLineDetails   (source: PAS_DB/dbo/Stored Procedures/Procs1/GetStockLineDetails.sql)
-- ---------------------------------------------------------------------------------------------------
/*********************************************************************************************           
 ** File:   [GetStockLineDetails]           
 ** Author:  MOIN BLOCH
 ** Description: This stored procedure is used GET Stockline Details By StockLineId
 ** Purpose:         
 ** Date:   09/09/2024      
          
 ** PARAMETERS:  @StockLineId BIGINT = 0
         
 ** RETURN VALUE:           
  
 *********************************************************************************************           
  ** Change History           
 *********************************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/09/2024  MOIN BLOCH 		Created
	2    07/01/2025  Bhavesh Raval 		Add GL Account Details
    3    21-01-25    Bhavesh Raval   Remove Name and Notes Columns 
	4	 11/02/2025	 Bhargav Saliya  get InventoryGLAccName Changes
	5	 09/02/2025	 Devendra Shekh	 Added new field 'QuantityAdjustment'
	6    21/04/2025  Abhishek Jirawla Added Integration portal changes
	7    23/07/2025  MOIN BLOCH 	  Added BatchNumber
	8    24/09/2025  Sahdev Saliya    Added Classification
	7    27/11/2025  Bhargav Saliya	  Modified(Get GL accound code and name from the GLAcount Table).
	8    02/12/2025  Bhargav Saliya	  Revert Changes.
	9    29/05/2026  Nakul Chandigra  Added AircraftSN,ExchangeSalesOrderNumber fields
	10   29/05/2026  Priyansh Patel 	Added new field 'TTSN, TCSN '(PN-16477)
	14   30/06/2026  Nakul Chandigra    Added new field 'Note' [Note] [PN-17012]
	15    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	16    07/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory into Stockline : Return IsNonStock, Currency, CurrencyId
	17    08/July/2026			 RAJESH GAMI						[PN-17009] - Return ItemNonStockClassificationId, NonStockClassification
	18    13/July/2026			 RAJESH GAMI						[PN-17009] - BUGFIX: removed 2 redundant "AND ISNULL(im/iM.IsNonStock,0) = 0"
	19    23/July/2026			 RAJESH GAMI						[PN-17350] - Removed 2 more leftover soft IsNonStock=0 exclusions (oempnpart/rPart aliases) missed by the earlier PN-17009 bugfix pass.
										 filters. (1) The final WHERE clause filtered on im.IsNonStock even though this SP is
										 already scoped to one exact @StockLineId and im is joined via INNER JOIN
										 dbo.ItemMaster ON stl.ItemMasterId = im.ItemMasterId (the Stockline's own item) -
										 this returned ZERO rows for every migrated Non-Stock Stockline record, which is very
										 likely why editing a migrated Non-Stock record was failing. (2) The ipAgg integration-
										 portal subquery filtered the same way, silently blanking that field for Non-Stock
										 records. Left the oempnpart/rPart joins untouched (different ItemMaster rows).
	20   29-July-2026             Ayushi Patel		                Added New Field IsService [PN-17470]
    EXEC dbo.GetStockLineDetails  179632  180170
***********************************************************************************************/

CREATE   PROCEDURE [dbo].[GetStockLineDetails]
@StockLineId BIGINT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @StocklineMSModuleId INT = 0;
		DECLARE @CustomerModuleId INT=0,@VendorModuleId INT=0,@CompanyModuleId INT=0,@OthersModuleId INT=0;
		DECLARE @CustomerModuleName VARCHAR(50)='',@VendorModuleName VARCHAR(50)='',@CompanyModuleName VARCHAR(50)='',@OthersModuleName VARCHAR(50)=''; 		
		
		SELECT @CustomerModuleId = [ModuleId] , @CustomerModuleName = [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]  = 'Customer';
		SELECT @VendorModuleId = [ModuleId] , @VendorModuleName = [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]  = 'Vendor';
		SELECT @CompanyModuleId = [ModuleId] , @CompanyModuleName = [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]  = 'Company';
		SELECT @OthersModuleId = [ModuleId] , @OthersModuleName = [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]  = 'Others';


		SELECT @StocklineMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline';

		SELECT stl.[StockLineId]
			  ,stl.[PartNumber]  'partNumber'
			  ,stl.[StockLineNumber] 'stockLineNumber'
			  ,stl.[ControlNumber]
              ,stl.[TagDate]
			  ,stl.[GLAccountId] 'glGLAccountId'
			  ,stl.[UnitCost]
              ,stl.[RevicedPNId]
              ,stl.[TaggedBy]
              ,stl.[RevicedPNNumber]
              ,stl.[OEMPNNumber]
              ,stl.[TaggedByName]
              ,stl.[TaggedByType]
              ,stl.[TaggedByTypeName]
              ,stl.[Location]
              ,stl.[Warehouse]
              ,stl.[ExpirationDate]
              ,stl.[SerialNumber]
              ,stl.[ConditionId]
			  ,stl.[itemGroup]
			  ,stl.[itemType] 'itemCategory'                                
              ,stl.[IdNumber]
              ,stl.[ItemMasterId]
			  ,stl.[PNDescription] 'partDescription'                                
              ,stl.[ManagementStructureId]
              ,''  [managementStructureName]
              ,ISNULL(stl.[Quantity],0) 'Quantity'
              ,ISNULL(stl.[QuantityOnOrder],0) 'QuantityOnOrder'
              ,ISNULL(stl.[QuantityIssued],0) 'QuantityIssued'
              ,stl.[QuantityOnHand] 'QuantityOnHand'
              ,ISNULL(stl.[QuantityAvailable],0) 'QuantityAvailable'
              ,ISNULL(stl.[QuantityTurnIn],0) 'QuantityTurnIn'
              ,ISNULL(stl.[QuantityReserved],0) 'QuantityReserved'
              ,stl.[Accident]
              ,stl.[AccidentReason]
              ,stl.[Incident]
              ,stl.[IncidentReason]
              ,stl.[BlackListed]
              ,stl.[BlackListedReason]
              ,stl.[EngineSerialNumber]
              ,stl.[AircraftTailNumber]
              ,stl.[Condition]
              ,stl.[ShelfLife]
			  ,stl.[ShelfLifeExpirationDate]
			  ,stl.[Site] 'siteName'
			  ,stl.[Shelf] 'shelfName'
			  ,stl.[Bin] 'binName'
			  ,stl.[SiteId] 'siteId'
			  ,stl.[ShelfId]
              ,stl.[BinId]  
			  ,stl.[WarehouseId]  'warehouseId'
			  ,stl.[LocationId] 'locationId'
			  ,stl.[ReceiverNumber] 'Receiver'
			  ,stl.[ObtainFrom]
              ,stl.[Owner]
              ,stl.[TraceableTo]
              ,stl.[ManufacturerLotNumber]
              ,stl.[ManufacturingDate]
              ,stl.[ManufacturingBatchNumber]
              ,stl.[PartCertificationNumber]
              ,stl.[CertType]
              ,stl.[CertTypeId]
              ,stl.[CertifiedBy]
              ,stl.[CertifiedById]
              ,stl.[CertifiedType]
              ,stl.[CertifiedTypeId]
              ,stl.[CertifiedDate]
              ,stl.[TagTypeId]    
			  ,ISNULL(tt.[Name], '') 'TagType'
			  ,stl.[CertifiedDueDate]
              ,stl.[CalibrationMemo]
              ,stl.[OrderDate]
			  ,ISNULL(po.[PurchaseOrderNumber], '') 'PurchaseOrderNumber'
              ,ISNULL(stl.[PurchaseOrderUnitCost],0) 'PurchaseOrderUnitCost'
              ,ISNULL(ro.[RepairOrderNumber], '') 'RepairOrderNumber'
			  ,ISNULL(stl.[RepairOrderUnitCost],0)  'RepairOrderUnitCost'
              ,ISNULL(stl.[InventoryUnitCost],0) 'InventoryUnitCost'
              ,stl.[ReceivedDate]
              ,stl.[ReconciliationNumber]
              ,ISNULL(stl.[UnitSalesPrice],0) 'UnitSalesPrice'
              ,stl.[SalesPriceExpiryDate]
              ,ISNULL(stl.[CoreUnitCost],0) 'CoreUnitCost'
              ,stl.[GLAccountId]
              ,stl.[AssetId]
              ,stl.[IsPMA]
              ,stl.[IsOemPNId]
              ,stl.[IsDER]
              ,stl.[OEM]
              ,stl.[Memo]
              ,stl.[ObtainFromType]
              ,stl.[OwnerType]
              ,stl.[TraceableToType]
              ,stl.[ManufacturerId]
              ,stl.[UnitCostAdjustmentReasonTypeId]
              ,stl.[UnitSalePriceAdjustmentReasonTypeId]
              ,stl.[TimeLifeCyclesId]
              ,stl.[IsActive]
              ,stl.[TLAItemMasterId]
              ,stl.[NHAItemMasterId]
              ,stl.[TLAPartNumber]
              ,stl.[NHAPartNumber]
			  ,ISNULL(oempnpart.[PartNumber], '') 'OEMPnPartNum'
			  ,stl.[Condition] 'conditionType'
			  ,im.[ItemTypeId]
			  ,CASE WHEN stl.[PurchaseUnitOfMeasureId] > 0 then stl.[PurchaseUnitOfMeasureId] ELSE im.[PurchaseUnitOfMeasureId] END 'PurchaseUnitOfMeasureId'
			  ,stl.[UnitOfMeasure]
              ,stl.[Manufacturer]
			  ,'' [Code]        
              ,stl.[CreatedBy]
              ,stl.[CreatedDate]
              ,stl.[UpdatedBy]
              ,stl.[UpdatedDate]
              ,stl.[TimeLifeDetailsNotProvided]
              ,stl.[PurchaseOrderId]
              ,stl.[RepairOrderId]
              ,ISNULL(stl.[IsCustomerStock],0) IsCustomerStock
              ,stl.[QuantityRejected]
              ,stl.[IsDeleted]
              ,stl.[LegalEntityId]
              ,stl.[MasterCompanyId]
              ,ISNULL(stl.[IsSerialized],0) IsSerialized
              ,stl.[WorkOrderId]
              ,stl.[PurchaseOrderPartRecordId]
              ,stl.[PurchaseOrderExtendedCost]
              ,stl.[ShippingViaId]
              ,stl.[RepairOrderPartRecordId]
              ,ISNULL(stl.[WorkOrderExtendedCost],0) WorkOrderExtendedCost
              ,NULL  'PurchaseOrderPartRecord'
			  ,ISNULL(stl.[RepairOrderExtendedCost],0) RepairOrderExtendedCost
              ,ISNULL(stl.[IsHazardousMaterial],0) IsHazardousMaterial
              ,ISNULL(stl.[IsNonStock],0) IsNonStock
              ,stl.[Currency]
              ,stl.[CurrencyId]
              ,stl.[ItemNonStockClassificationId]
              ,stl.[NonStockClassification]
              ,ISNULL(stl.[QuantityToReceive],0) QuantityToReceive
              ,stl.[ManufacturingTrace]
              ,stl.[WorkOrderMaterialsId]
              ,stl.[ShippingAccount]
              ,stl.[ShippingReference]
              ,im.[NationalStockNumber]
              ,stl.[EntryDate]
              ,ISNULL(stl.[LotCost],0) LotCost
              ,stl.[CustomerId]
              ,stl.[ExistingCustomerId]
			  ,stl.[ExistingCustomer] 'ExistingCustomerName'
			  ,ISNULL(ct.[Name], '') 'CustomerName'
			  ,ISNULL(imx.[ExportECCN], '') 'ExportECCN'
			  ,ISNULL(imx.[ITARNumber], '') 'ITARNumber'
			  ,CASE   
					WHEN stl.[OwnerType] = @CustomerModuleId THEN @CustomerModuleName
					WHEN stl.[OwnerType] = @VendorModuleId THEN @VendorModuleName
					WHEN stl.[OwnerType] = @CompanyModuleId THEN @CompanyModuleName
					WHEN stl.[OwnerType] = @OthersModuleId THEN @OthersModuleName
					ELSE ''
			  END  'OwnerTypeName'
			 ,CASE 
					WHEN stl.[TraceableToType] = @CustomerModuleId THEN @CustomerModuleName
					WHEN stl.[TraceableToType] = @VendorModuleId THEN  @VendorModuleName
					WHEN stl.[TraceableToType] = @CompanyModuleId THEN @CompanyModuleName
					WHEN stl.[TraceableToType] = @OthersModuleId THEN @OthersModuleName
					ELSE ''
			  END 'TraceableToTypeName'
			 ,CASE 
					WHEN stl.[ObtainFromType] = @CustomerModuleId THEN @CustomerModuleName
					WHEN stl.[ObtainFromType] = @VendorModuleId THEN  @VendorModuleName
					WHEN stl.[ObtainFromType] = @CompanyModuleId THEN @CompanyModuleName
					WHEN stl.[ObtainFromType] = @OthersModuleId THEN @OthersModuleName
					ELSE ''
			  END 'ObtainFromTypeName'
			 ,CASE WHEN stl.[OwnerType] = @CustomerModuleId THEN CUST.[Name] 
	               WHEN stl.[OwnerType] = @VendorModuleId THEN VEN.[VendorName]
	    		   WHEN stl.[OwnerType] = @CompanyModuleId THEN COM.[Name]	
				   WHEN stl.[OwnerType] = @OthersModuleId THEN stl.[OwnerName]
	    		   ELSE ''
	    	  END 'OwnerName'
			 ,CASE WHEN stl.[TraceableToType] = @CustomerModuleId THEN CUSTTTN.[Name] 
	               WHEN stl.[TraceableToType] = @VendorModuleId THEN VENTTN.[VendorName]
	    		   WHEN stl.[TraceableToType] = @CompanyModuleId THEN COMTTN.[Name]	
				   WHEN stl.[TraceableToType] = @OthersModuleId THEN stl.[TraceableToName]
	    		   ELSE ''
	    	  END 'TracableToName'
			 ,CASE WHEN stl.[ObtainFromType] = @CustomerModuleId THEN CUSTOBF.[Name] 
	               WHEN stl.[ObtainFromType] = @VendorModuleId THEN VENOBF.[VendorName]
	    		   WHEN stl.[ObtainFromType] = @CompanyModuleId THEN COMOBF.[Name]	
				   WHEN stl.[ObtainFromType] = @OthersModuleId THEN stl.[ObtainFromName]
	    		   ELSE ''
	    	  END 'ObtainFromName'
			 ,stl.[NHAPartNumber] 'nha'
			 ,stl.[TLAPartNumber] 'tla'
			 ,stl.[NHAPartDescription] 'nhaPartDescription'
			 ,stl.[TLAPartDescription] 'tlaPartDescription'
			 ,0 'DaysReceived'
			 ,0 'TagDays'
			 ,0 'OpenDays'
			 ,0 'ManufacturingDays'
			 ,stl.[GlAccountName]
             ,stl.[AcquistionTypeId]
			 ,ISNULL(iaty.[Name], '') 'AcquistionTypeName'
			 ,stl.[RequestorId]
			 ,stl.[LotNumber]
			 ,stl.[LotDescription]
			 ,stl.[TagNumber]
             ,stl.[InspectionBy]
             ,stl.[InspectionDate]
			 ,ISNULL(CONCAT(empr.[FirstName], ' ', empr.[LastName]), '') 'RequestedByName'
             ,ISNULL(CONCAT(empi.[FirstName], ' ', empi.[LastName]), '')  'InspectionByName'
			 
			 --,ISNULL(stl.IntegrationPortal, ISNULL(ipAgg.integrationPortal, '')) AS IntegrationPortalDescriptions
			 ,ISNULL(ipFromStockLine.IntegrationPortalDescriptions, ISNULL(ipAgg.integrationPortal, '')) AS IntegrationPortalDescriptions

			 ,ISNULL(NULLIF(stl.IntegrationPortal, ''), ISNULL(ipAgg.IntegrationPortalStringIds, '')) AS IntegrationPortalStringIds
			 --,(SELECT STRING_AGG(inte.[Description], ',') 
				--FROM [dbo].[ItemMaster] v WITH(NOLOCK)
				--INNER JOIN [dbo].[ItemMasterIntegrationPortal] mp WITH(NOLOCK) ON v.[ItemMasterId] = mp.[ItemMasterId]
				--INNER JOIN [dbo].[IntegrationPortal] inte WITH(NOLOCK) ON mp.[IntegrationPortalId] = CAST(inte.[IntegrationPortalId] AS BIGINT)
				--WHERE v.[ItemMasterId] = im.[ItemMasterId]) 'integrationPortal'
			  ,rPart.[PartNumber] 'RevisedPart'
              ,im.[RevisedPartId]
              ,stl.[WorkOrderNumber]				  
			  ,ISNULL(ti.[TimeLifeCyclesId], 0) AS TimeLifeCyclesIds        
              ,ISNULL(ti.[CyclesRemaining], '') AS CyclesRemaining
              ,ISNULL(ti.[CyclesSinceNew], '') AS CyclesSinceNew
              ,ISNULL(ti.[CyclesSinceOVH], '') AS CyclesSinceOVH
              ,ISNULL(ti.[CyclesSinceRepair], '') AS CyclesSinceRepair
              ,ISNULL(ti.[CyclesSinceInspection], '') AS CyclesSinceInspection
              ,ISNULL(ti.[TimeRemaining], '') AS TimeRemaining
              ,ISNULL(ti.[TimeSinceInspection], '') AS TimeSinceInspection
              ,ISNULL(ti.[TimeSinceNew], '') AS TimeSinceNew
              ,ISNULL(ti.[TimeSinceOVH], '') AS TimeSinceOVH
              ,ISNULL(ti.[TimeSinceRepair], '') AS TimeSinceRepair
              ,ISNULL(ti.[LastSinceInspection], '') AS LastSinceInspection
              ,ISNULL(ti.[LastSinceNew], '') AS LastSinceNew
              ,ISNULL(ti.[LastSinceOVH], '') AS LastSinceOVH
			  ,stl.[VendorId]
			  ,ISNULL(ve.[VendorName], '') AS VendorName			 
			  ,ISNULL(stl.[isCustomerstockType],0) isCustomerstockType
			  ,ISNULL(rc.[ReceivingInspectionId], 0) AS ReceivingInspectionId    
			  ,msd.[EntityMSID] 'EntityStructureId'
			  ,msd.[LastMSLevel] 'LastMSLevel'
			  ,msd.[AllMSlevels] 'AllMSlevels'
			  ,GETUTCDATE() CurrentDate
			  ,stl.[ExchangeSalesOrderId]
              ,stl.[SubWorkOrderId]
              ,stl.[SubWorkOrderNumber]
			  ,ISNULL(stl.[IsManualEntry], 0) AS IsManualEntry
              ,ISNULL(stl.[Adjustment], 0) AS Adjustment
              ,ISNULL(stl.[FreightAdjustment], 0) AS FreightAdjustment
              ,ISNULL(stl.[TaxAdjustment], 0) AS TaxAdjustment
			  ,'' AS TaxAdjustmentAmounts
			  ,ISNULL(stl.[IsStkTimeLife], im.[IsTimeLife]) AS isTimeLife
			  ,CASE WHEN stl.[IsSerialized] = 1 AND (stl.[SerialNumber] IS NULL OR stl.[SerialNumber] = '') THEN 1
ELSE 0 END AS IsSkipSerialNo
			  ,stl.[RepairOrderNumber] RONumber
			,stl.InventoryGLSettingId      
			,igls.[StockInventoryName]      
			AS InventoryGLSettingName      
			,stl.InventoryGLAccName AS  InventoryGLAccName      
			,stl.GoodsReceivedNotInvoicesGLAccId  
			,stl.GoodsReceivedNotInvoicesGLAccName   
			,stl.WorkInProgressGLAccId 
			,stl.WorkInProgressGLAccName
			,stl.InventoryToBillGLAccId 
			,stl.InventoryToBillGLAccName
			,stl.FinishedGoodsGLAccId 
			,stl.FinishedGoodsGLAccName   
			,stl.InventoryExchAgreementGLAccId 
			,stl.InventoryExchAgreementGLAccName      
			,stl.InventoryReserveGLAccId
			,stl.InventoryReserveGLAccName   
			,stl.COGS_WorkOrderGLAccId
			,stl.COGS_WorkOrderGLAccName   
			,stl.COGS_SalesOrderGLAccId
			,stl.COGS_SalesOrderGLAccName   
			,stl.COGS_ExchSalesOrderGLAccId
			,stl.COGS_ExchSalesOrderGLAccName   
			,stl.COGS_QtyVarianceGLAccId
			,stl.COGS_QtyVarianceGLAccName   
			,stl.COGS_UnitCostVarianceGLAccId
			,stl.COGS_UnitCostVarianceGLAccName  
			,stl.RevenueMroGLAccId
			,stl.RevenueMroGLAccName        
			,stl.RevenueSoGLAccId
			,stl.RevenueSoGLAccName    
			,stl.RevenueExchGLAccId
			,stl.RevenueExchGLAccName
			,ISNULL(stl.[QuantityAdjustment],0) QuantityAdjustment
			,ISNULL(stl.IsPiecePart, 0) IsPiecePart
			,ISNULL(stl.IsRepairManagement, 0) IsRepairManagement
			,ISNULL(stl.[IsBatchStock],0) IsBatchStock
			,stl.[BatchNumber]
			,im.ItemClassificationName AS Classification
			,stl.AircraftSN
			,ES.ExchangeSalesOrderNumber
			,	stl.TotalTSN, stl.TotalCSN, stl.TotalTSNMM, stl.TotalCSNMM,stl.Note,stl.IsService
		FROM [dbo].[StockLine] stl WITH(NOLOCK)
		INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON stl.[ItemMasterId] = im.[ItemMasterId]
		INNER JOIN [dbo].[StocklineManagementStructureDetails] msd WITH(NOLOCK) ON stl.[StockLineId] = msd.[ReferenceID] AND msd.[ModuleID] = @StocklineMSModuleId 
		OUTER APPLY (
			SELECT STRING_AGG(ip.[Description], ', ') AS IntegrationPortalDescriptions
			FROM dbo.SplitString(stl.IntegrationPortal, ',') AS ids
			JOIN dbo.IntegrationPortal ip WITH(NOLOCK) ON ids.Item = ip.IntegrationPortalId
		) AS ipFromStockLine
		LEFT JOIN (
			SELECT
				iM.ItemMasterId,
				STRING_AGG(CAST(ip.[Description] AS NVARCHAR(MAX)), ',') AS integrationPortal,
				STRING_AGG(CAST(mp.IntegrationPortalId AS VARCHAR), ',') AS IntegrationPortalStringIds
			FROM dbo.ItemMaster iM WITH(NOLOCK)
			LEFT JOIN dbo.ItemMasterIntegrationPortal mp WITH(NOLOCK) ON iM.ItemMasterId = mp.ItemMasterId
			LEFT JOIN dbo.IntegrationPortal ip WITH(NOLOCK) ON mp.IntegrationPortalId = ip.IntegrationPortalId
			WHERE mp.IntegrationPortalId IS NOT NULL
			 GROUP BY iM.ItemMasterId
		) AS ipAgg ON stl.ItemMasterId = ipAgg.ItemMasterId
		 LEFT JOIN [dbo].[InventoryGLSetting] igls WITH(NOLOCK) ON igls.InventoryGLSettingId=stl.InventoryGLSettingId
		 LEFT JOIN [dbo].[ItemMasterExportInfo] imx WITH(NOLOCK) ON im.[ItemMasterId] = imx.[ItemMasterId]
		 LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON stl.[PurchaseOrderId] = po.[PurchaseOrderId]
		 LEFT JOIN [dbo].[RepairOrder] ro WITH(NOLOCK) ON stl.[RepairOrderId] = ro.[RepairOrderId]
		 LEFT JOIN [dbo].[TimeLife] ti WITH(NOLOCK) ON stl.[StockLineId] = ti.[StockLineId]
		 LEFT JOIN [dbo].[ItemMaster] oempnpart WITH(NOLOCK) ON stl.[IsOemPNId] = oempnpart.[ItemMasterId]
		  LEFT JOIN [dbo].[AssetAcquisitionType] iaty WITH(NOLOCK) ON stl.[AcquistionTypeId] = iaty.[AssetAcquisitionTypeId]
		 LEFT JOIN [dbo].[Employee] empr WITH(NOLOCK) ON stl.[RequestorId] = empr.[EmployeeId]
		 LEFT JOIN [dbo].[Employee] empi WITH(NOLOCK) ON stl.[InspectionBy] = empi.[EmployeeId]
		 LEFT JOIN [dbo].[ItemMaster] rPart WITH(NOLOCK) ON im.[RevisedPartId] = rPart.[ItemMasterId]
		  LEFT JOIN [dbo].[Vendor] ve WITH(NOLOCK) ON stl.[VendorId] = ve.[VendorId]
		 LEFT JOIN [dbo].[TagType] tt WITH(NOLOCK) ON stl.[TagTypeId] = tt.[TagTypeId]
		 LEFT JOIN [dbo].[Customer] ct WITH(NOLOCK) ON stl.[CustomerId] = ct.[CustomerId]
		 LEFT JOIN [dbo].[ReceivingInspection] rc WITH(NOLOCK) ON stl.[StockLineId] = rc.StockLineId
		 LEFT JOIN [dbo].[Customer] CUST WITH (NOLOCK) ON CUST.[CustomerId] = stl.[Owner]
	     LEFT JOIN [dbo].[Vendor] VEN WITH (NOLOCK) ON VEN.[VendorId] = stl.[Owner]
	     LEFT JOIN [dbo].[LegalEntity] COM WITH (NOLOCK) ON COM.[LegalEntityId] = stl.[Owner]
		 LEFT JOIN [dbo].[Customer] CUSTTTN  WITH (NOLOCK) ON CUSTTTN.[CustomerId] = stl.[TraceableTo]     
         LEFT JOIN [dbo].[Vendor] VENTTN  WITH (NOLOCK) ON VENTTN.[VendorId] = stl.[TraceableTo] 
         LEFT JOIN [dbo].[LegalEntity] COMTTN  WITH (NOLOCK) ON COMTTN.[LegalEntityId] = stl.[TraceableTo]
		 LEFT JOIN [dbo].[Customer] CUSTOBF  WITH (NOLOCK) ON CUSTOBF.[CustomerId] = stl.[ObtainFrom]     
         LEFT JOIN [dbo].[Vendor] VENOBF  WITH (NOLOCK) ON VENOBF.[VendorId] = stl.[ObtainFrom] 
         LEFT JOIN [dbo].[LegalEntity] COMOBF  WITH (NOLOCK) ON COMOBF.[LegalEntityId] = stl.[ObtainFrom]
		 LEFT JOIN DBO.ExchangeSalesOrder ES WITH (NOLOCK) ON stl.ExchangeSalesOrderId = ES.ExchangeSalesOrderId
		WHERE stl.[IsDeleted] = 0 AND stl.[StockLineId] = @StockLineId
		 END TRY
	BEGIN CATCH 
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetStockLineDetails'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH
	END