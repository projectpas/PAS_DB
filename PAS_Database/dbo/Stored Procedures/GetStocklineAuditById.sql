/*************************************************************           
 ** File:   [GetStocklineAuditById]           
 ** Author:   Rajesh Gami
 ** Description: Get Data for Stockline Audit History : Its convert from LINQ to Sql SP    
 ** Purpose:         
 ** Date:   12-Aug-2024                  
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date           Author		    Change Description            
 ** --   --------       -------		    --------------------------------          
    1    12-Aug-2024    Rajesh Gami  Created
     
	 EXEC [dbo].[GetStocklineAuditById] 178385
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetStocklineAuditById]
@stocklineId BIGINT = null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
	  BEGIN TRY
		DECLARE @masteCompnayID INT,@msModuleId INT = 2;
		DECLARE @customerModuleEnum int = 1,@vendorModuleEnum int = 2,@companyModuleEnum int = 9,@othersModuleEnum int = 4;
		-- Get the MasterCompanyId
		SELECT @masteCompnayID = MasterCompanyId FROM StockLine WHERE StockLineId = @stocklineId;

		SELECT 
			stl.StockLineId,
			stl.PartNumber AS partNumber,
			stl.StockLineNumber AS stockLineNumber,
			stl.ControlNumber,
			stl.TagDate,
			stl.GLAccountId AS glGLAccountId,
			stl.Location,
			stl.Warehouse,
			stl.ExpirationDate,
			stl.SerialNumber,
			stl.ConditionId AS conditionId,
			stl.ItemGroup,
			stl.ItemType AS itemCategory,
			stl.IdNumber,
			stl.ItemMasterId,
			im.PartDescription AS partDescription,
			stl.ManagementStructureId,
			msd.LastMSLevel AS managementStructureName,
			stl.Quantity,
			stl.QuantityOnOrder,
			stl.QuantityIssued,
			stl.QuantityOnHand,
			stl.QuantityAvailable,
			stl.QuantityTurnIn,
			stl.QuantityReserved,
			stl.Accident,
			stl.AccidentReason,
			stl.Incident,
			stl.IncidentReason,
			stl.BlackListed,
			stl.BlackListedReason,
			stl.EngineSerialNumber,
			stl.AircraftTailNumber,
			stl.Condition AS condition,
			stl.ShelfLife,
			stl.ShelfLifeExpirationDate,
			stl.Site AS siteName,
			stl.Shelf AS shelfName,
			stl.Bin AS binName,
			stl.SiteId AS siteId,
			stl.ShelfId,
			stl.BinId,
			stl.WarehouseId AS warehouseId,
			stl.LocationId AS locationId,
			stl.ReceiverNumber AS Receiver,
			stl.ObtainFrom,
			stl.Owner,
			stl.TraceableTo,
			stl.ManufacturerLotNumber,
			stl.ManufacturingDate,
			stl.ManufacturingBatchNumber,
			stl.PartCertificationNumber,
			stl.CertifiedBy,
			stl.CertifiedDate,
			stl.TagType,
			stl.CertifiedDueDate,
			stl.CalibrationMemo,
			stl.OrderDate,
			po.PurchaseOrderNumber,
			stl.PurchaseOrderUnitCost,
			ro.RepairOrderNumber,
			stl.RepairOrderUnitCost,
			stl.InventoryUnitCost,
			stl.ReceivedDate,
			stl.ReconciliationNumber,
			stl.UnitSalesPrice,
			stl.CoreUnitCost,
			stl.GLAccountId,
			stl.AssetId,
			stl.IsPMA,
			stl.IsDER,
			stl.OEM,
			stl.Memo,
			stl.ObtainFromType,
			stl.OwnerType,
			stl.TraceableToType,
			stl.ManufacturerId,
			stl.UnitCostAdjustmentReasonTypeId,
			stl.UnitSalePriceAdjustmentReasonTypeId,
			stl.TimeLifeCyclesId,
			stl.isActive,
			stl.TLAItemMasterId,
			stl.NHAItemMasterId,
			stl.TLAPartNumber,
			stl.NHAPartNumber,
			stl.Condition AS conditionType,
			im.ItemTypeId,
			stl.Manufacturer,
			stl.CreatedBy,
			stl.CreatedDate,
			stl.UpdatedBy,
			stl.UpdatedDate,
			stl.TimeLifeDetailsNotProvided,
			stl.PurchaseOrderId,
			stl.RepairOrderId,
			stl.IsCustomerStock,
			stl.IsCustomerstockType,
			stl.QuantityRejected,
			stl.IsDeleted,
			stl.LegalEntityId,
			stl.MasterCompanyId,
			stl.IsSerialized,
			stl.WorkOrderId,
			stl.PurchaseOrderPartRecordId,
			stl.PurchaseOrderExtendedCost,
			stl.ShippingViaId,
			stl.RepairOrderPartRecordId,
			stl.WorkOrderExtendedCost,
			--stl.PurchaseOrderPartRecord,
			stl.RepairOrderExtendedCost,
			stl.IsHazardousMaterial,
			stl.QuantityToReceive,
			stl.ManufacturingTrace,
			stl.WorkOrderMaterialsId,
			stl.ShippingAccount,
			stl.ShippingReference,
			im.NationalStockNumber,
			stl.EntryDate,
			stl.LotCost,
			ISNULL(imx.ExportECCN, '') AS ExportECCN,
			ISNULL(imx.ITARNumber, '') AS ITARNumber,
			CASE 
				WHEN stl.OwnerType = CAST(@customerModuleEnum AS INT) THEN CAST(@customerModuleEnum AS VARCHAR)
				WHEN stl.OwnerType = CAST(@vendorModuleEnum AS INT) THEN CAST(@vendorModuleEnum AS VARCHAR)
				WHEN stl.OwnerType = CAST(@companyModuleEnum AS INT) THEN CAST(@companyModuleEnum AS VARCHAR)
				WHEN stl.OwnerType = CAST(@othersModuleEnum AS INT) THEN CAST(@othersModuleEnum AS VARCHAR)
				ELSE ''
			END AS OwnerTypeName,
			CASE 
				WHEN stl.TraceableToType = CAST(@customerModuleEnum AS INT) THEN CAST(@customerModuleEnum AS VARCHAR)
				WHEN stl.TraceableToType = CAST(@vendorModuleEnum AS INT) THEN CAST(@vendorModuleEnum AS VARCHAR)
				WHEN stl.TraceableToType = CAST(@companyModuleEnum AS INT) THEN CAST(@companyModuleEnum AS VARCHAR)
				WHEN stl.TraceableToType = CAST(@othersModuleEnum AS INT) THEN CAST(@othersModuleEnum AS VARCHAR)
				ELSE ''
			END AS TraceableToTypeName,
			CASE 
				WHEN stl.ObtainFromType = CAST(@customerModuleEnum AS INT) THEN CAST(@customerModuleEnum AS VARCHAR)
				WHEN stl.ObtainFromType = CAST(@vendorModuleEnum AS INT) THEN CAST(@vendorModuleEnum AS VARCHAR)
				WHEN stl.ObtainFromType = CAST(@companyModuleEnum AS INT) THEN CAST(@companyModuleEnum AS VARCHAR)
				WHEN stl.ObtainFromType = CAST(@othersModuleEnum AS INT) THEN CAST(@othersModuleEnum AS VARCHAR)
				ELSE ''
			END AS ObtainFromTypeName,
			stl.OwnerName,
			stl.TraceableToName AS TracableToName,
			stl.ObtainFromName,
			stl.NHAPartNumber AS nha,
			stl.TLAPartNumber AS tla,
			stl.NHAPartDescription AS nhaPartDescription,
			stl.TLAPartDescription AS tlaPartDescription,
			im.DaysReceived,
			im.TagDays,
			im.OpenDays,
			stl.GLAccountName,
			stl.AcquistionTypeId,
			ISNULL(iaty.Name, '') AS AcquistionTypeName,
			stl.RequestorId,
			stl.LotNumber AS LotNum,
			stl.LotDescription,
			stl.TagNumber AS TagNum,
			stl.InspectionBy,
			stl.InspectionDate,
			ISNULL(empr.FirstName + ' ' + empr.LastName, '') AS RequestedByName,
			ISNULL(empi.FirstName + ' ' + empi.LastName, '') AS InspectionByName,
			STUFF(
				(SELECT ',' + inte.Description
				 FROM ItemMaster v
				 INNER JOIN ItemMasterIntegrationPortal mp ON v.ItemMasterId = mp.ItemMasterId
				 INNER JOIN IntegrationPortal inte ON mp.IntegrationPortalId = inte.IntegrationPortalId
				 WHERE v.MasterCompanyId = @masteCompnayID AND v.ItemMasterId = im.ItemMasterId
				 FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS integrationPortal,
			rPart.PartNumber AS RevisedPart,
			im.RevisedPartId,
			stl.WorkOrderNumber,
			ISNULL(im.ManufacturingDays, 0) AS ManufacturingDays,
			stl.Level1 AS CompanyName,
			stl.Level2 AS BuName,
			stl.Level3 AS DivName,
			stl.Level4 AS DeptName,
			ISNULL(ti.CyclesRemaining, '') AS CyclesRemaining,
			ISNULL(ti.CyclesSinceNew, '') AS CyclesSinceNew,
			ISNULL(ti.CyclesSinceOVH, '') AS CyclesSinceOVH,
			ISNULL(ti.CyclesSinceRepair, '') AS CyclesSinceRepair,
			ISNULL(ti.CyclesSinceInspection, '') AS CyclesSinceInspection,
			ISNULL(ti.TimeRemaining, '') AS TimeRemaining,
			ISNULL(ti.TimeSinceInspection, '') AS TimeSinceInspection,
			ISNULL(ti.TimeSinceNew, '') AS TimeSinceNew,
			ISNULL(ti.TimeSinceOVH, '') AS TimeSinceOVH,
			ISNULL(ti.TimeSinceRepair, '') AS TimeSinceRepair,
			ISNULL(ti.LastSinceInspection, '') AS LastSinceInspection,
			ISNULL(ti.LastSinceNew, '') AS LastSinceNew,
			ISNULL(ti.LastSinceOVH, '') AS LastSinceOVH,
			stl.VendorId,
			ISNULL(ve.VendorName, '') AS VendorName,
			ISNULL(msd.EntityMSID, 0) AS EntityStructureId,
			msd.LastMSLevel,
			msd.AllMSlevels
		FROM 
			[PAS_DEV_logs].[dbo].[StockLineAudit] stl WITH(NOLOCK)
			INNER JOIN  StocklineManagementStructureDetailsAudit msd ON stl.StockLineId = msd.ReferenceID AND msd.ModuleID = @msModuleId
			LEFT JOIN [dbo].ItemMaster im  WITH(NOLOCK) ON stl.ItemMasterId = im.ItemMasterId
			LEFT JOIN [dbo].ItemMasterExportInfo imx WITH(NOLOCK) ON im.ItemMasterId = imx.ItemMasterId
			LEFT JOIN [dbo].PurchaseOrder po WITH(NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
			LEFT JOIN [dbo].RepairOrder ro WITH(NOLOCK) ON stl.RepairOrderId = ro.RepairOrderId
			LEFT JOIN [dbo].ItemMaster rPart WITH(NOLOCK) ON im.RevisedPartId = rPart.ItemMasterId
			LEFT JOIN [dbo].AssetAcquisitionType iaty WITH(NOLOCK) ON stl.AcquistionTypeId = iaty.AssetAcquisitionTypeId
			LEFT JOIN [dbo].Employee empr WITH(NOLOCK) ON stl.RequestorId = empr.EmployeeId
			LEFT JOIN [dbo].Employee empi WITH(NOLOCK) ON stl.InspectionBy = empi.EmployeeId
			LEFT JOIN [dbo].TimeLife ti WITH(NOLOCK) ON stl.TimeLifeCyclesId = ti.TimeLifeCyclesId
			LEFT JOIN [dbo].Vendor ve WITH(NOLOCK) ON stl.VendorId = ve.VendorId
			WHERE 
				stl.StockLineId = @stocklineId;
	  END TRY 
	  BEGIN CATCH   	
			  
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetStocklineAuditById'               
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@stocklineId, '') as varchar(100))
													
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH			           
END