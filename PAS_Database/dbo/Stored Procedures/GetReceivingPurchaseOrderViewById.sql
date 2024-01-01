/*************************************************************             
 ** File:   [GetReceivingOurchaseOrderViewById]             
 ** Author:    
 ** Description: Get Search Data for SOQ List   
 ** Purpose:           
 ** Date:     
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author             Change Description              
 ** --   --------     -------           --------------------------------            
    1    26/12/2023   Shrey Chandegara     Created 

	exec GetReceivingPurchaseOrderViewById 2348
**************************************************************/ 

CREATE   PROCEDURE [DBO].[GetReceivingPurchaseOrderViewById]
@PurchaseOrderId [BIGINT]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON; 

	BEGIN TRY

		SELECT
			POP.PurchaseOrderId,
			P.PurchaseOrderNumber,
			POP.PurchaseOrderPartRecordId,
			POP.ItemMasterId,
			POP.PartNumber,
			POP.ManufacturerId,
			POP.PriorityId,
			POP.UOMId,
			POP.DiscountPercent,
			POP.GlAccountId,
			POP.ConditionId,
			POP.isParent AS 'IsParent',
			POP.ManagementStructureId,
			POP.QuantityOrdered,
			POP.QuantityBackOrdered,
			POP.DiscountPerUnit,
			POP.ExtendedCost,
			POP.UnitCost,
			POP.QuantityRejected,
			POP.AltEquiPartNumberId,
			POP.AltEquiPartNumber,
			POP.AltEquiPartDescription,
			POP.ItemType,
			POP.ItemTypeId,
			POP.StockType,
			CASE WHEN POP.ItemTypeId=1 THEN 
			(SELECT ISNULL(SUM(Quantity),0) FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [PurchaseOrderId] = POP.[PurchaseOrderId] AND [PurchaseOrderPartRecordId] = POP.PurchaseOrderPartRecordId AND IsDeleted = 0 AND IsParent = 1)  
			WHEN  POP.ItemTypeId=2 THEN 
			(SELECT ISNULL(SUM(Quantity),0) FROM [dbo].[NonStockInventory] WITH(NOLOCK) WHERE [PurchaseOrderId] = POP.[PurchaseOrderId] AND [PurchaseOrderPartRecordId] = POP.PurchaseOrderPartRecordId AND IsDeleted = 0 AND IsParent = 1) 
			WHEN POP.ItemTypeId = 11 THEN
			(SELECT ISNULL(SUM(Qty),0) FROM [dbo].[AssetInventory] WITH(NOLOCK) WHERE [PurchaseOrderId] = POP.[PurchaseOrderId] AND [PurchaseOrderPartRecordId] = POP.PurchaseOrderPartRecordId AND IsDeleted = 0 ) 
			ELSE 0 END AS StockLineCount ,
			CASE WHEN POP.ItemTypeId=1 THEN 
			(SELECT ISNULL(SUM(Quantity),0) FROM [dbo].[StocklineDraft] WITH(NOLOCK) WHERE [PurchaseOrderId] = POP.[PurchaseOrderId] AND [PurchaseOrderPartRecordId] = POP.PurchaseOrderPartRecordId AND IsDeleted = 0 AND IsParent = 1 AND (StockLineId = 0 OR StockLineId IS  NULL))  
			WHEN POP.ItemTypeId = 2 THEN
			(SELECT ISNULL(SUM(Quantity),0) FROM [dbo].[NonStockInventoryDraft] WITH(NOLOCK) WHERE [PurchaseOrderId] = POP.[PurchaseOrderId] AND [PurchaseOrderPartRecordId] = POP.PurchaseOrderPartRecordId AND IsDeleted = 0 AND IsParent = 1 AND (NonStockInventoryId = 0 OR NonStockInventoryId IS  NULL))  
			WHEN POP.ItemTypeId = 11 THEN
			(SELECT ISNULL(SUM(Qty),0) FROM [dbo].[AssetInventoryDraft] WITH(NOLOCK) WHERE [PurchaseOrderId] = POP.[PurchaseOrderId] AND [PurchaseOrderPartRecordId] = POP.PurchaseOrderPartRecordId AND IsDeleted = 0 AND IsParent = 1 AND AssetInventoryId = 0)  
			ELSE 0 END AS StockLineDraftCount
			
			
			
		FROM DBO.[PurchaseOrderPart] POP WITH (NOLOCK)
		LEFT JOIN  [dbo].[PurchaseOrder] P WITH(NOLOCK) ON P.PurchaseOrderId = @PurchaseOrderId 
		--LEFT JOIN  [dbo].[Stockline] SL WITH(NOLOCK) ON  SL.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId AND SL.isDeleted=0 AND (SL.IsParent = 1 AND SL.IsSameDetailsForAllParts = 1 OR SL.IsSameDetailsForAllParts = 0)
		--LEFT JOIN  [dbo].[StocklineDraft] SLD WITH(NOLOCK) ON SLD.PurchaseOrderId = @PurchaseOrderId AND SLD.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId AND SLD.isDeleted=0 AND (SLD.IsParent = 1 AND SLD.IsSameDetailsForAllParts = 1 OR SLD.IsSameDetailsForAllParts = 0) AND (SLD.StockLineId = 0 OR SLD.StockLineId IS  NULL)
		
		WHERE POP.PurchaseOrderId=@PurchaseOrderId
		group by POP.PurchaseOrderId,POP.PurchaseOrderPartRecordId,POP.UOMId,POP.ConditionId,POP.isParent,POP.ManagementStructureId,POP.QuantityOrdered,POP.QuantityBackOrdered,POP.DiscountPerUnit,POP.ExtendedCost
		,POP.UnitCost,POP.QuantityRejected,POP.AltEquiPartNumberId,
			POP.AltEquiPartNumber,
			POP.AltEquiPartDescription,
			POP.ItemType,
			POP.ItemTypeId,
			POP.StockType,POP.ItemMasterId,POP.ManufacturerId,POP.PriorityId,POP.DiscountPercent,POP.GlAccountId,P.PurchaseOrderNumber,POP.PartNumber

		/* START SELECT FROM StocklineDrfat */
		SELECT
		SLD.PurchaseOrderPartRecordId,
		SLDM.LastMSLevel,
		SLDM.AllMSlevels,
		SLD.StockLineDraftId  AS 'StockLineDraftId',
		SLD.StockLineNumber AS 'StockLineNumber',
		SLD.ControlNumber,
		SLD.IdNumber,
		SLD.ConditionId,
		SLD.SerialNumber,
		SLD.Quantity,
		SLD.PurchaseOrderUnitCost,
		SLD.PurchaseOrderExtendedCost,
		SLD.ReceiverNumber,
		0 AS WorkOrder,
		0 AS SalesOrder,
		0 AS SubWorkOrder,
		SLD.OwnerType,
		SLD.ObtainFromType,
		SLD.TraceableToType,
		SLD.ManufacturingTrace,
		SLD.ManufacturerId,
		SLD.Manufacturer,
		SLD.ManufacturerLotNumber,
		SLD.ManufacturingDate,
		SLD.ManufacturingBatchNumber,
		SLD.PartCertificationNumber,
		SLD.EngineSerialNumber,
		SLD.ShippingViaId,
		SV.Name AS 'ShippingViatext',
		SLD.ShippingReference,
		SLD.ShippingAccount,
		SLD.CertifiedDate,
		SLD.CertifiedBy,
		SLD.TagType,
		SLD.TagDate,
		SLD.ExpirationDate,
		SLD.CertifiedDueDate,
		SLD.AircraftTailNumber,
		SLD.GLAccountId,
		GL.AccountName AS 'GLAccountText',
		C.Description AS 'ConditionText',
		SLD.ManagementStructureEntityId,
		SLD.SiteId,
		SLD.WarehouseId,
		SLD.LocationId,
		SLD.ShelfId,
		SLD.BinId,
		SLD.NHAItemMasterId,
		SLD.TLAItemMasterId,
		IMN.partnumber AS 'NHAItemMasterText',
		IMT.partnumber AS 'TLAItemMasterText',
		S.Name AS 'SiteText',
		W.Name AS'WarehouseText',
		L.Name AS'LocationText',
		SH.Name AS 'ShelfText',
		B.Name AS 'BinText',
		SLD.ObtainFromName,
		SLD.OwnerName,
		SLD.TraceableToName,
		SLD.Level1,
		SLD.Level2,
		SLD.Level3,
		SLD.Level4,
		SLD.UnitOfMeasure,
		SLD.TaggedByName,
		SLD.CertTypeId,
		SLD.CertType
		FROM DBO.[StocklineDraft] SLD WITH (NOLOCK)
		LEFT JOIN  [dbo].[StockLineDraftManagementStructureDetails] SLDM WITH(NOLOCK) ON SLDM.ReferenceID = SLD.StockLineDraftId AND ModuleID = 31
		LEFT JOIN  [dbo].[ShippingVia] SV WITH(NOLOCK) ON SV.ShippingViaId = SLD.ShippingViaId
		LEFT JOIN  [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = SLD.GLAccountId
		LEFT JOIN  [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = SLD.ConditionId
		LEFT JOIN  [dbo].[ItemMaster] IMN WITH(NOLOCK) ON IMN.ItemMasterId = SLD.NHAItemMasterId
		LEFT JOIN  [dbo].[ItemMaster] IMT WITH(NOLOCK) ON IMT.ItemMasterId = SLD.TLAItemMasterId
		LEFT JOIN  [dbo].[Site] S WITH(NOLOCK) ON S.SiteId = SLD.SiteId
		LEFT JOIN  [dbo].[Warehouse] W WITH(NOLOCK) ON W.WarehouseId = SLD.WarehouseId
		LEFT JOIN  [dbo].[Location] L WITH(NOLOCK) ON L.LocationId = SLD.LocationId
		LEFT JOIN  [dbo].[Shelf] SH WITH(NOLOCK) ON SH.ShelfId = SLD.ShelfId
		LEFT JOIN  [dbo].[Bin] B WITH(NOLOCK) ON B.BinId = SLD.BinId
		WHERE SLD.PurchaseOrderId=@PurchaseOrderId


		/* START SELECT FROM NonStockInventoryDraft */
		SELECT 
		SLD.PurchaseOrderPartRecordId,
		SLDM.LastMSLevel,
		SLDM.AllMSlevels,
		SLD.NonStockInventoryDraftId AS 'StockLineDraftId',
		SLD.NonStockInventoryNumber AS 'StockLineNumber',
		SLD.ControlNumber,
		SLD.IdNumber,
		SLD.ConditionId,
		SLD.SerialNumber,
		SLD.Quantity,
		SLD.UnitCost AS 'PurchaseOrderUnitCost',
		SLD.ExtendedCost AS 'PurchaseOrderExtendedCost',
		SLD.ReceiverNumber,
		0 AS WorkOrder,
		0 AS SalesOrder,
		0 AS SubWorkOrder,
		'' AS 'OwnerType',
		'' AS 'ObtainFromType',
		'' AS 'TraceableToType',
		'' AS 'ManufacturingTrace',
		SLD.ManufacturerId,
		SLD.Manufacturer,
		'' AS 'ManufacturerLotNumber',
		'' AS 'ManufacturingDate',
		'' AS 'ManufacturingBatchNumber',
		'' AS 'PartCertificationNumber',
		'' AS 'EngineSerialNumber',
		SLD.ShippingViaId,
		SLD.ShippingVia,
		SLD.ShippingReference,
		SLD.ShippingAccount,
		'' AS 'CertifiedDate',
		'' AS 'CertifiedBy',
		'' AS 'TagType',
		'' AS 'TagDate',
		SLD.MfgExpirationDate,
		'' AS 'CertifiedDueDate',
		'' AS 'AircraftTailNumber',
		SLD.GLAccountId,
		SLD.GLAccount,
		SLD.Condition,
		SLD.ManagementStructureId,
		SLD.SiteId,
		SLD.WarehouseId,
		SLD.LocationId,
		SLD.ShelfId,
		SLD.BinId,
		'' AS 'NHAItemMasterId',
		'' AS 'TLAItemMasterId',
		'' AS 'NHAItemMasterText',
		'' AS 'TLAItemMasterText',
		SLD.Site AS 'SiteText',
		SLD.Warehouse AS 'WarehouseText',
		SLD.Location AS 'LocationText',
		SLD.Shelf AS 'ShelfText',
		SLD.Bin AS 'BinText',
		'' AS 'ObtainFrom',
		'' AS 'Owner',
		'' AS 'TraceableTo',
		SLD.Level1,
		SLD.Level2,
		SLD.Level3,
		SLD.Level4,
		SLD.UnitOfMeasure,
		'' AS 'TaggedByName',
		'' AS 'CertTypeId',
		'' AS 'CertType'
		FROM DBO.[NonStockInventoryDraft] SLD WITH (NOLOCK)
		LEFT JOIN  [dbo].[StockLineDraftManagementStructureDetails] SLDM WITH(NOLOCK) ON SLDM.ReferenceID = SLD.NonStockInventoryDraftId AND ModuleID = 55
		WHERE SLD.PurchaseOrderId = @PurchaseOrderId


		/* START SELECT FROM AssetInventoryDraft */
		SELECT 
		SLD.PurchaseOrderPartRecordId,
		SLDM.LastMSLevel,
		SLDM.AllMSlevels,
		SLD.AssetInventoryDraftId AS 'StockLineDraftId',
		SLD.StklineNumber AS 'StockLineNumber',
		SLD.ControlNumber,
		'' AS 'IdNumber',
		'' AS 'ConditionId',
		SLD.SerialNo AS 'SerialNumber',
		SLD.Qty As 'Quantity',
		SLD.UnitCost AS 'PurchaseOrderUnitCost',
		(SLD.Qty * SLD.UnitCost) AS 'PurchaseOrderExtendedCost',
		'' AS 'ReceiverNumber',
		0 AS WorkOrder,
		0 AS SalesOrder,
		0 AS SubWorkOrder,
		'' AS 'OwnerType',
		'' AS 'ObtainFromType',
		'' AS 'TraceableToType',
		'' AS 'ManufacturingTrace',
		SLD.ManufacturerId,
		SLD.ManufactureName,
		'' AS 'ManufacturerLotNumber',
		SLD.ManufacturedDate,
		'' AS 'ManufacturingBatchNumber',
		'' AS 'PartCertificationNumber',
		'' AS 'EngineSerialNumber',
		SLD.ShippingViaId,
		SLD.ShippingVia,
		SLD.ShippingReference,
		SLD.ShippingAccount,
		'' AS 'CertifiedDate',
		'' AS 'CertifiedBy',
		'' AS 'TagType',
		SLD.TagDate,
		SLD.ExpirationDate,
		CASE WHEN SLD.ExpirationDate IS NULL THEN NULL ELSE SLD.LastCalibrationDate END AS 'LastCalibrationDate',
		CASE WHEN SLD.ExpirationDate IS NULL THEN NULL ELSE SLD.NextCalibrationDate END AS 'NextCalibrationDate',
		'' AS 'CertifiedDueDate',
		'' AS 'AircraftTailNumber',
		SLD.GLAccountId,
		SLD.GLAccount,
		'' AS 'ConditionText',
		SLD.ManagementStructureId,
		SLD.SiteId,
		SLD.WarehouseId,
		SLD.LocationId,
		SLD.ShelfId,
		SLD.BinId,
		'' AS 'NHAItemMasterId',
		'' AS 'TLAItemMasterId',
		'' AS 'NHAItemMasterText',
		'' AS 'TLAItemMasterText',
		SLD.SiteName AS 'SiteText',
		SLD.Warehouse AS 'WarehouseText',
		SLD.Location AS 'SiteText',
		SLD.ShelfName AS 'ShelfText',
		SLD.BinName AS 'BinText',
		'' AS 'ObtainFrom',
		'' AS 'Owner',
		'' AS 'TraceableTo',
		SLD.Level1,
		SLD.Level2,
		SLD.Level3,
		SLD.Level4,
		'' AS 'UnitOfMeasure',
		'' AS 'TaggedByName',
		'' AS 'CertTypeId',
		'' AS 'CertType'
		FROM DBO.[AssetInventoryDraft] SLD WITH (NOLOCK)
		LEFT JOIN  [dbo].[StockLineDraftManagementStructureDetails] SLDM WITH(NOLOCK) ON SLDM.ReferenceID = SLD.AssetInventoryDraftId AND ModuleID = 56
		WHERE SLD.PurchaseOrderId = @PurchaseOrderId


		/* START SELECT FROM Stockline */
		SELECT 
		SL.PurchaseOrderPartRecordId,
		SL.StockLineId,
		SL.StockLineNumber,
		SL.ControlNumber,
		SL.IdNumber,
		SL.ConditionId,
		SL.SerialNumber,
		SL.Quantity,
		SL.PurchaseOrderUnitCost,
		SL.PurchaseOrderExtendedCost,
		SL.ReceiverNumber,
		0 AS WorkOrder,
		0 AS SalesOrder,
		0 AS SubWorkOrder,
		SL.OwnerType,
        SL.ObtainFromType,
        SL.TraceableToType,
        SL.ManufacturingTrace,
        SL.ManufacturerId,
        SL.ManufacturerLotNumber,
		SL.ManufacturingDate, 
		SL.ManufacturingBatchNumber,
        SL.PartCertificationNumber,
        SL.EngineSerialNumber,
        SL.ShippingViaId,
        SL.ShippingReference,
        SL.ShippingAccount,
        SL.CertifiedDate, 
		SL.CertifiedBy,
		SL.TagDate,
		SL.ExpirationDate,
		SL.UnitOfMeasure,
		SL.TaggedByName,
		SL.CertifiedDueDate,
		SL.AircraftTailNumber,
		SL.GLAccountId,
		GL.AccountName AS 'GLAccountText',
		C.Description AS 'ConditionText',
		SL.ManagementStructureId,
		SL.SiteId,
        SL.WarehouseId,
        SL.LocationId,
        SL.ShelfId,
        SL.BinId,
        SL.NHAItemMasterId,
        SL.TLAItemMasterId,
		IMN.partnumber AS 'NHAItemMasterText',
		IMT.partnumber AS 'TLAItemMasterText',
		S.Name AS 'SiteText',
		W.Name AS'WarehouseText',
		L.Name AS'LocationText',
		SH.Name AS 'ShelfText',
		B.Name AS 'BinText',
		SL.ObtainFrom AS 'ObtainFrom',
		SL.Owner AS 'Owner',
        SL.TraceableTo AS 'TraceableTo',
        SL.Level1 AS 'Level1',
        SL.Level2 AS 'Level2',
        SL.Level3 AS 'Level3',
        SL.Level4 AS 'Level4'
		FROM DBO.[Stockline] SL WITH(NOLOCK)
		LEFT JOIN  [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = SL.GLAccountId
		LEFT JOIN  [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = SL.ConditionId
		LEFT JOIN  [dbo].[ItemMaster] IMN WITH(NOLOCK) ON IMN.ItemMasterId = SL.NHAItemMasterId
		LEFT JOIN  [dbo].[ItemMaster] IMT WITH(NOLOCK) ON IMT.ItemMasterId = SL.TLAItemMasterId
		LEFT JOIN  [dbo].[Site] S WITH(NOLOCK) ON S.SiteId = SL.SiteId
		LEFT JOIN  [dbo].[Warehouse] W WITH(NOLOCK) ON W.WarehouseId = SL.WarehouseId
		LEFT JOIN  [dbo].[Location] L WITH(NOLOCK) ON L.LocationId = SL.LocationId
		LEFT JOIN  [dbo].[Shelf] SH WITH(NOLOCK) ON SH.ShelfId = SL.ShelfId
		LEFT JOIN  [dbo].[Bin] B WITH(NOLOCK) ON B.BinId = SL.BinId
		WHERE SL.PurchaseOrderId = @PurchaseOrderId

		SELECT * FROM TimeLifeDraft WHERE PurchaseOrderId= @PurchaseOrderId
		SELECT * FROM TimeLife WHERE PurchaseOrderId= @PurchaseOrderId

	
	END TRY
	BEGIN CATCH        
	   IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN; 
		 SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
	
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				  , @AdhocComments     VARCHAR(150)    = 'GetReceivingPurchaseOrderViewById'   
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''  
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