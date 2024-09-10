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
			 ,(SELECT STRING_AGG(inte.[Description], ',') 
				FROM [dbo].[ItemMaster] v WITH(NOLOCK)
				INNER JOIN [dbo].[ItemMasterIntegrationPortal] mp WITH(NOLOCK) ON v.[ItemMasterId] = mp.[ItemMasterId]
				INNER JOIN [dbo].[IntegrationPortal] inte WITH(NOLOCK) ON mp.[IntegrationPortalId] = CAST(inte.[IntegrationPortalId] AS BIGINT)
				WHERE v.[ItemMasterId] = im.[ItemMasterId]) 'integrationPortal'
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
			  ,CASE WHEN stl.[IsSerialized] = 1 AND (stl.[SerialNumber] IS NULL OR stl.[SerialNumber] = '') THEN 1 ELSE 0 END AS IsSkipSerialNo
			  ,stl.[RepairOrderNumber] RONumber			                
		FROM [dbo].[StockLine] stl WITH(NOLOCK)
		INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON stl.[ItemMasterId] = im.[ItemMasterId]
		INNER JOIN [dbo].[StocklineManagementStructureDetails] msd WITH(NOLOCK) ON stl.[StockLineId] = msd.[ReferenceID] AND msd.[ModuleID] = @StocklineMSModuleId 
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