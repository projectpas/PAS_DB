
/*************************************************************           
 ** File:   [dbo].[GetReceivingRepairOrderForView]          
 ** Author:   Moin Bloch
 ** Description: Get Receiving Repair Order For View
 ** Date:   16/12/2025
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    16/12/2025   Moin Bloch    Created

	EXEC [dbo].[GetReceivingRepairOrderForView] 12969
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetReceivingRepairOrderForView]
@RepairOrderId bigint
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
	BEGIN TRY
	
		DECLARE @StockItemTypeId INT= 1,@AssetItemTypeId INT= 11

		DECLARE @ROPart INT,@ROSplitPart INT,@ReceivingRODraft INT,@ReceivingAssetDraft INT

		SELECT @ROPart = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule]  WITH(NOLOCK) WHERE [ModuleName] = 'ROPart';
	    SELECT @ROSplitPart = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule]  WITH(NOLOCK) WHERE [ModuleName] = 'ROSplitPart';		
	    SELECT @ReceivingRODraft = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule]  WITH(NOLOCK) WHERE [ModuleName] = 'ReceivingRODraft';
	    SELECT @ReceivingAssetDraft = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule]  WITH(NOLOCK) WHERE [ModuleName] = 'ReceivingAssetDraft';				
				
		CREATE TABLE #ResultPartIds
		(
			RepairOrderPartRecordId BIGINT NULL
		)

		INSERT INTO #ResultPartIds
		SELECT DISTINCT S.RepairOrderPartRecordId FROM [dbo].[StockLineDraft] S WITH(NOLOCK) WHERE S.RepairOrderId=@RepairOrderId AND S.IsDeleted=0 AND S.IsParent=1 AND (S.StockLineId IS NULL OR S.StockLineId = 0)
		UNION   
		SELECT DISTINCT S.RepairOrderPartRecordId FROM [dbo].[AssetInventoryDraft] S WITH(NOLOCK) WHERE S.RepairOrderId=@RepairOrderId AND S.IsDeleted=0 AND S.IsParent = 1 AND (S.StklineNumber IS NULL OR S.StklineNumber = '')
		
		SELECT 
		CASE WHEN part.ItemTypeId = @StockItemTypeId THEN itm.SiteId ELSE ast.SiteId END AS SiteId,
        CASE WHEN part.ItemTypeId = @StockItemTypeId THEN itm.WarehouseId ELSE ast.WarehouseId END AS WarehouseId,
        CASE WHEN part.ItemTypeId = @StockItemTypeId THEN itm.LocationId ELSE ast.AssetLocationId END AS LocationId,
        CASE WHEN part.ItemTypeId = @StockItemTypeId THEN itm.ShelfId ELSE ast.ShelfId END AS ShelfId,
        CASE WHEN part.ItemTypeId = @StockItemTypeId THEN itm.BinId ELSE ast.BinId END AS BinId,
        part.ConditionId,
        part.RepairOrderId,
        part.RepairOrderPartRecordId,
        part.ItemMasterId,
        part.PartNumber,
        part.PartDescription,
        part.QuantityOrdered,
        part.QuantityBackOrdered,
        part.QuantityRejected,
        part.ManufacturerId [Manufacturerid],
        part.Manufacturer,
        part.ManagementStructureId,		
		(
            SELECT TOP 1 LastMSLevel
            FROM [dbo].[RepairOrderManagementStructureDetails] AS msd WITH(NOLOCK)
            WHERE msd.ReferenceID = part.RepairOrderPartRecordId 
            AND msd.ModuleID = CASE WHEN part.IsParent = 1 THEN @ROPart ELSE @ROSplitPart END
        ) AS LastMSLevel,
        (
            SELECT TOP 1 AllMSlevels
            FROM [dbo].[RepairOrderManagementStructureDetails] AS msd WITH(NOLOCK)
            WHERE msd.ReferenceID = part.RepairOrderPartRecordId 
            AND msd.ModuleID = CASE WHEN part.IsParent = 1 THEN @ROPart ELSE @ROSplitPart END
        ) AS AllMSlevels,
        ISNULL(part.UnitCost,0) UnitCost,
        ISNULL(part.ExtendedCost,0) ExtendedCost,
        ISNULL(part.DiscountPerUnit,0) DiscountPerUnit,
        part.WorkOrderNo,
        part.WorkOrderId,
        part.SubWorkOrderNo,
        part.SalesOrderNo,
        part.AltEquiPartNumberId,
        part.AltEquiPartNumber,
        part.AltEquiPartDescription,
        part.ItemType,
        part.StockType,
        part.Level1 AS CompanyText,
        part.Level2 AS BusinessUnitText,
        part.Level3 AS DivisionText,
        part.Level4 AS DepartmentText,
        part.UOMId,
        part.UnitOfMeasure AS uomText,
        part.RoPartSplitUser AS RoPartSplitUserName,
        ISNULL(part.IsParent,0) IsParent,
        CASE WHEN part.IsAsset = 1 AND asi.IsIntangible IS NOT NULL THEN asi.IsIntangible ELSE 0 END AS IsIntangible,
        part.QuantityOrdered AS QuantityToRepair,
        part.ItemTypeId,
        part.ManufacturerPN,
        part.AssetModel,
        part.AssetClass,
        part.SerialNumber,
        ISNULL(part.LotId, 0) AS LotId,
        CASE WHEN ISNULL(part.LotId, 0) > 0 THEN lot.LotNumber ELSE '' END AS LotNumber,
        CASE
            WHEN part.ItemTypeId = 1 AND ISNULL(part.IsAsset,0) = 0 THEN 
                (SELECT SUM(x.Quantity) FROM [dbo].[StockLine] x WITH(NOLOCK) WHERE x.RepairOrderPartRecordId = part.RepairOrderPartRecordId AND x.PurchaseOrderPartRecordId IS NOT NULL AND x.IsDeleted = 0 AND x.IsParent = 1)
            WHEN part.IsAsset = 1 THEN 
                (SELECT SUM(x.Qty) FROM [dbo].[AssetInventory] x WITH(NOLOCK) WHERE x.RepairOrderPartRecordId = part.RepairOrderPartRecordId AND x.PurchaseOrderPartRecordId IS NOT NULL AND x.IsDeleted = 0)
            ELSE 0 
        END AS [ReceivedCount],
		CASE 
		    WHEN part.ItemTypeId = 1
			THEN
			    ISNULL((
                    SELECT SUM(sld.Quantity)
                    FROM [dbo].[StockLineDraft] sld WITH(NOLOCK)
                    WHERE sld.RepairOrderId = @RepairOrderId
                      AND sld.RepairOrderPartRecordId = part.RepairOrderPartRecordId
                      AND part.IsAsset = 0
                      AND sld.IsDeleted = 0
                      AND ((sld.IsParent = 1 AND sld.IsSameDetailsForAllParts = 1) OR ISNULL(sld.IsSameDetailsForAllParts,0) = 0)
                      AND (sld.StockLineId IS NULL OR sld.StockLineId = 0)
                ),0)
			ELSE 
				ISNULL((
                    SELECT SUM(aid.Qty)
                    FROM [dbo].[AssetInventoryDraft] aid WITH(NOLOCK)
                    WHERE aid.RepairOrderId = @RepairOrderId
                      AND aid.RepairOrderPartRecordId = part.RepairOrderPartRecordId
                      AND part.IsAsset = 1
                      AND aid.IsDeleted = 0
                      AND (aid.StklineNumber IS NULL OR aid.StklineNumber = '')
                ),0)
		END [StockLineCount],
        CASE WHEN part.ItemTypeId = 1 THEN itm.PartNumber ELSE asi.AssetId END AS ItemMaster_PartNumber,
        CASE WHEN part.ItemTypeId = 1 THEN itm.PartDescription ELSE asi.Name END AS ItemMaster_PartDescription,
        CASE WHEN part.ItemTypeId = 1 THEN itm.GLAccountId ELSE part.GLAccountId END AS ItemMaster_GLAccountId,
        part.GLAccount AS ItemMaster_GLAccount_AccountName,
        CASE WHEN part.ItemTypeId = 1 THEN itm.IsTimeLife ELSE 0 END AS ItemMaster_IsTimeLife,
        CASE WHEN part.ItemTypeId = 1 THEN itm.IsSerialized ELSE asi.IsSerialized END AS ItemMaster_IsSerialized,
        CASE WHEN part.ItemTypeId = 1 THEN itm.ManufacturerId ELSE asi.ManufacturerId END AS ItemMaster_ManufacturerId,
        CASE WHEN part.ItemTypeId = 1 THEN itm.IsPma ELSE 0 END AS ItemMaster_IsPma,
        CASE WHEN part.ItemTypeId = 1 THEN itm.IsDER ELSE 0 END AS ItemMaster_IsDer
    FROM [dbo].[RepairOrderPart] part WITH(NOLOCK)
    INNER JOIN #ResultPartIds roids ON part.RepairOrderPartRecordId = roids.RepairOrderPartRecordId
     LEFT JOIN [dbo].[ItemMaster] itm WITH(NOLOCK) ON part.ItemMasterId = itm.ItemMasterId AND part.ItemTypeId = @StockItemTypeId
     LEFT JOIN [dbo].[AssetInventory] asi WITH(NOLOCK) ON part.ItemMasterId = asi.AssetRecordId AND part.StockLineId = asi.AssetInventoryId AND part.ItemTypeId = @AssetItemTypeId
     LEFT JOIN [dbo].[Asset] ast WITH(NOLOCK) ON part.ItemMasterId = ast.AssetRecordId AND part.ItemTypeId = @AssetItemTypeId
     LEFT JOIN [dbo].[Lot] lot WITH(NOLOCK) ON part.LotId = lot.LotId   
	WHERE part.[RepairOrderId] = @RepairOrderId

		SELECT		 
        (
            SELECT TOP 1 LastMSLevel
            FROM [dbo].[StockLineDraftManagementStructureDetails] msd WITH(NOLOCK)
            WHERE msd.ReferenceID = s.StockLineDraftId
            AND msd.ModuleID = @ReceivingRODraft
        ) AS LastMSLevel,
        (
            SELECT TOP 1 AllMSlevels
            FROM [dbo].[StockLineDraftManagementStructureDetails] msd WITH(NOLOCK)
            WHERE msd.ReferenceID = s.StockLineDraftId
            AND msd.ModuleID = @ReceivingRODraft 
        ) AS AllMSlevels,
        s.RepairOrderPartRecordId,
		s.RepairOrderId,
        s.StockLineDraftId,
        s.StockLineNumber,
        s.ControlNumber,
        s.IdNumber,
        s.SerialNumber,
        ISNULL(s.Quantity,0) Quantity,
        ISNULL(s.RepairOrderUnitCost,0) RepairOrderUnitCost,
        ISNULL(s.RepairOrderExtendedCost,0) RepairOrderExtendedCost,
        s.ReceiverNumber,
        s.OwnerType,
        s.ObtainFromType,
        s.TraceableToType,
        s.OwnerTypeName,
        s.ObtainFromName AS ObtainFromTypeName,
        s.TraceableToName AS TraceableToTypeName,
        s.ManufacturingTrace AS ManufacturingTraceName,
        s.ManufacturingTrace,
        s.ManufacturerId,
        s.ManufacturerLotNumber,        
		CASE WHEN s.ManufacturingDate IS NOT NULL THEN FORMAT(s.ManufacturingDate, 'MM/dd/yyyy') ELSE NULL END AS ManufacturingDate,
        s.ManufacturingBatchNumber,
        s.PartCertificationNumber,
        s.EngineSerialNumber,
        s.ShippingViaId,
        s.ShippingReference,
        s.ShippingAccount,        
		CASE WHEN s.CertifiedDate IS NOT NULL THEN FORMAT(s.CertifiedDate, 'MM/dd/yyyy') ELSE NULL END AS CertifiedDate,
        s.CertifiedBy,        
		CASE WHEN s.TagDate IS NOT NULL THEN FORMAT(s.TagDate, 'MM/dd/yyyy') ELSE NULL END AS TagDate,
        s.TagType,        
		CASE WHEN s.ExpirationDate IS NOT NULL THEN FORMAT(s.ExpirationDate, 'MM/dd/yyyy') ELSE NULL END AS ExpirationDate,        
		CASE WHEN s.CertifiedDueDate IS NOT NULL THEN FORMAT(s.CertifiedDueDate, 'MM/dd/yyyy') ELSE NULL END AS CertifiedDueDate,
        s.AircraftTailNumber,
        s.GLAccountId,
        s.GLAccount AS GLAccountText,
        s.ConditionId,
        s.Condition AS ConditionText,
        s.ManagementStructureEntityId,
        s.SiteId,
        s.WarehouseId,
        s.LocationId,
        s.ShelfId,
        s.BinId,
        s.Manufacturer AS ManufacturerText,
        s.ShippingVia AS ShippingViaText,
        s.SiteName AS SiteText,
        s.Warehouse AS WarehouseText,
        s.Location AS LocationText,
        s.ShelfName AS ShelfText,
        s.BinName AS BinText,
        s.ObtainFrom,
        s.ObtainFromName,
        s.Owner,
        s.OwnerName,
        s.TraceableTo,
        s.TraceableToName,
        s.NHAItemMasterId,
        s.TLAItemMasterId,
		s.ObtainFromName ObtainFromText,
		s.OwnerName OwnerText,
		s.TraceableToName TraceableToText,
        s.Level1 AS CompanyText,
        s.Level2 AS BusinessUnitText,
        s.Level3 AS DivisionText,
        s.Level4 AS DepartmentText,
        s.TaggedBy,
        s.TaggedByName,
        s.TaggedByType,
        s.TaggedByTypeName,
        s.UnitOfMeasureId,
        s.UnitOfMeasure,
        s.RevisedPartId,
        s.RevisedPartNumber,
        s.CertifiedById,
        s.CertifiedTypeId,
        s.CertifiedType,
        s.CertType,
        s.CertTypeId,
        ISNULL(s.RepairOrderUnitCost,0) AS UnitCost,
        ISNULL(s.LotId, 0) AS LotId,
        CASE WHEN ISNULL(s.LotId, 0) > 0 THEN lot.LotNumber ELSE '' END AS LotNumber
    FROM [dbo].[StockLineDraft] s WITH(NOLOCK)
    INNER JOIN #ResultPartIds roids ON s.RepairOrderPartRecordId = roids.RepairOrderPartRecordId
    LEFT JOIN Lot lot WITH(NOLOCK) ON s.LotId = lot.LotId
    WHERE s.[RepairOrderId] = @RepairOrderId
        AND s.[IsDeleted] = 0
        AND (s.[StockLineId] IS NULL OR s.[StockLineId] = 0)
        AND (s.[IsParent] = 1 OR s.[IsSameDetailsForAllParts] = 0)

		SELECT
	     (
            SELECT TOP 1 LastMSLevel
            FROM [dbo].[StockLineDraftManagementStructureDetails] msd WITH(NOLOCK)
            WHERE msd.ReferenceID = a.AssetInventoryDraftId
            AND msd.ModuleID = @ReceivingAssetDraft 
        ) AS LastMSLevel,
        (
            SELECT TOP 1 AllMSlevels
            FROM [dbo].[StockLineDraftManagementStructureDetails] msd WITH(NOLOCK)
            WHERE msd.ReferenceID = a.AssetInventoryDraftId
            AND msd.ModuleID = @ReceivingAssetDraft 
        ) AS AllMSlevels,        
		a.RepairOrderPartRecordId,
		a.RepairOrderId,
        a.AssetInventoryDraftId AS StockLineDraftId, 
        a.StklineNumber AS StockLineNumber, 
        a.ControlNumber,
		'' IdNumber,
        a.SerialNo AS SerialNumber,
        ISNULL(a.Qty,0) AS Quantity,
        ISNULL(a.UnitCost,0) AS RepairOrderUnitCost,
        (ISNULL(a.Qty,0) * ISNULL(a.UnitCost,0)) AS RepairOrderExtendedCost,
		'' AS ReceiverNumber,
		0 AS OwnerType, 
		0 AS ObtainFromType, 
		0 AS TraceableToType, 

		'' AS OwnerTypeName, 
		'' AS ObtainFromTypeName, 
		'' AS TraceableToTypeName, 
		'' AS ManufacturingTraceName, 
		'' AS ManufacturingTrace,
		a.ManufacturerId, 
		'' AS ManufacturerLotNumber,        
		CASE WHEN a.ManufacturedDate IS NOT NULL THEN FORMAT(a.ManufacturedDate, 'MM/dd/yyyy') ELSE NULL END AS ManufacturingDate,
		'' AS ManufacturingBatchNumber,
		'' AS PartCertificationNumber,
		'' AS EngineSerialNumber,
        a.ShippingViaId,
        a.ShippingReference,
        a.ShippingAccount,
		NULL AS CertifiedDate,
		'' AS CertifiedBy,        
		CASE WHEN a.TagDate IS NOT NULL THEN FORMAT(a.TagDate, 'MM/dd/yyyy') ELSE NULL END AS TagDate,
        '' AS TagType,        
		CASE WHEN a.ExpirationDate IS NOT NULL THEN FORMAT(a.ExpirationDate, 'MM/dd/yyyy') ELSE NULL END AS ExpirationDate,        
		CASE WHEN a.LastCalibrationDate IS NOT NULL THEN FORMAT(a.LastCalibrationDate, 'MM/dd/yyyy') ELSE NULL END AS LastCalibrationDate,        
		CASE WHEN a.NextCalibrationDate IS NOT NULL THEN FORMAT(a.NextCalibrationDate, 'MM/dd/yyyy') ELSE NULL END AS NextCalibrationDate,
		NULL AS CertifiedDueDate,
		'' AS AircraftTailNumber,
		a.GLAccountId,
        a.GLAccount AS GLAccountText,
		0 AS ConditionId,
		'' AS ConditionText,
        a.ManagementStructureId AS ManagementStructureEntityId,
        a.SiteId,
        a.WarehouseId,
        a.LocationId,
        a.ShelfId,
        a.BinId,
        a.ManufactureName AS ManufacturerText,
        a.ShippingVia AS ShippingViaText,
        a.SiteName AS SiteText,
        a.Warehouse AS WarehouseText,
        a.Location AS LocationText,
        a.ShelfName AS ShelfText,
        a.BinName AS BinText,
        a.Level1 AS CompanyText,
        a.Level2 AS BusinessUnitText,
        a.Level3 AS DivisionText,
        a.Level4 AS DepartmentText,
        ISNULL(a.UnitCost,0) AS UnitCost
    FROM [dbo].[AssetInventoryDraft] a WITH(NOLOCK)
    INNER JOIN #ResultPartIds roids ON a.RepairOrderPartRecordId = roids.RepairOrderPartRecordId
    WHERE a.[RepairOrderId] = @RepairOrderId
        AND a.[IsDeleted] = 0
        AND (a.[StklineNumber] IS NULL OR a.[StklineNumber] = '') 

		SELECT t.[TimeLifeDraftCyclesId]
			  ,t.[CyclesRemaining]
			  ,t.[CyclesSinceNew]
			  ,t.[CyclesSinceOVH]
			  ,t.[CyclesSinceInspection]
			  ,t.[CyclesSinceRepair]
			  ,t.[TimeRemaining]
			  ,t.[TimeSinceNew]
			  ,t.[TimeSinceOVH]
			  ,t.[TimeSinceInspection]
			  ,t.[TimeSinceRepair]
			  ,t.[LastSinceNew]
			  ,t.[LastSinceOVH]
			  ,t.[LastSinceInspection]
			  ,t.[MasterCompanyId]
			  ,t.[CreatedBy]
			  ,t.[UpdatedBy]
			  ,t.[CreatedDate]
			  ,t.[UpdatedDate]
			  ,t.[IsActive]
			  ,t.[PurchaseOrderId]
			  ,t.[PurchaseOrderPartRecordId]
			  ,t.[StockLineDraftId]
			  ,t.[DetailsNotProvided]
			  ,t.[RepairOrderId]
			  ,t.[RepairOrderPartRecordId]
			  ,t.[VendorRMAId]
			  ,t.[VendorRMADetailId]
		FROM [dbo].[TimeLifeDraft] t WITH(NOLOCK)
		INNER JOIN #ResultPartIds roids ON t.RepairOrderPartRecordId = roids.RepairOrderPartRecordId
		WHERE t.RepairOrderId = @RepairOrderId  

	DROP TABLE #ResultPartIds;

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'			
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'GetBillingInvoiceByShipping' 
			, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@RepairOrderId AS VARCHAR(10)), '') + ''
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