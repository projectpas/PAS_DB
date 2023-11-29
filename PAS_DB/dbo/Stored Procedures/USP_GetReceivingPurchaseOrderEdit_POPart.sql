/*************************************************************             
 ** File:   [USP_GetReceivingPurchaseOrderEdit_POPart]            
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to get stockline draft details to receive
 ** Purpose:           
 ** Date:   08/21/2023          
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    08/21/2023   Vishal Suthar		Created
  
EXEC [dbo].[USP_GetReceivingPurchaseOrderEdit_POPart] 1908
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetReceivingPurchaseOrderEdit_POPart]
(  
	@PurchaseOrderId BIGINT = NULL
)  
AS  
BEGIN  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  SET NOCOUNT ON  
  
    BEGIN TRY  
		--SELECT DISTINCT
		--part.PurchaseOrderId,
  --      part.ItemTypeId,
  --      part.PurchaseOrderPartRecordId,
  --      part.ItemMasterId,
  --      part.PartNumber,
  --      part.PartDescription,
  --      part.QuantityOrdered,
  --      part.QuantityBackOrdered,
  --      (SELECT SUM(STK.Quantity) FROM DBO.Stockline STK WITH (NOLOCK) WHERE STK.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND STK.IsParent = 1 AND STK.StockLineId IN 
		--(SELECT StockLineId FROM DBO.StocklineDraft STKD WITH (NOLOCK) WHERE STKD.PurchaseOrderId = @PurchaseOrderId)) AS QuantityReceived,
  --      part.ManufacturerId,
  --      part.Manufacturer,
  --      part.ManagementStructureId,
		--(SELECT LastMSLevel FROM DBO.PurchaseOrderManagementStructureDetails P WITH (NOLOCK) WHERE P.ReferenceID = part.PurchaseOrderPartRecordId AND p.ModuleID = 5) AS LastMSLevel,
		--(SELECT AllMSlevels FROM DBO.PurchaseOrderManagementStructureDetails P WITH (NOLOCK) WHERE P.ReferenceID = part.PurchaseOrderPartRecordId AND p.ModuleID = 5) AS AllMSlevels,
  --      part.UnitOfMeasure,
  --      part.UnitCost,
  --      part.ExtendedCost,
  --      part.DiscountPerUnit,
  --      part.DiscountAmount,
  --      part.WorkOrderNo,
  --      part.SubWorkOrderNo,
  --      part.SalesOrderNo,
  --      part.ReapairOrderNo,
		--(CASE WHEN part.ItemTypeId = 1 THEN itm.IsManufacturingDateAvailable ELSE 0 END) AS IsManufacturingDateAvailable,
  --      (CASE WHEN part.ItemTypeId = 1 THEN itm.IsReceivedDateAvailable ELSE 0 END) AS IsReceivedDateAvailable,
  --      (CASE WHEN part.ItemTypeId = 1 THEN itm.IsTagDateAvailable ELSE 0 END) AS IsTagDateAvailable,
  --      (CASE WHEN part.ItemTypeId = 1 THEN itm.IsExpirationDateAvailable ELSE 0 END) AS IsExpirationDateAvailable,
		--part.AltEquiPartNumberId,
  --      part.AltEquiPartNumber,
  --      part.AltEquiPartDescription,
  --      part.ItemType,
		--(CASE WHEN part.ItemTypeId = 11 THEN asi.IsIntangible ELSE 0 END) AS IsIntangible,
		--part.StockType,
  --      part.ManufacturerPN,
  --      part.AssetModel,
  --      part.AssetClass,
		--part.POPartSplitUser AS PoPartSplitUserName,
  --      CASE WHEN part.LotId IS NOT NULL THEN part.LotId ELSE 0 END AS LotId,
		--(CASE WHEN part.LotId IS NOT NULL AND part.LotId > 0 THEN (SELECT TOP 1 L.LotNumber FROM DBO.Lot L WITH (NOLOCK) WHERE L.LotId = part.LotId) ELSE '' END) AS LotNumber,
  --      CASE WHEN part.IsLotAssigned IS NOT NULL THEN part.IsLotAssigned ELSE 0 END AS IsLotAssigned,
		--CASE WHEN part.ItemTypeId = 1 THEN itm.isSerialized WHEN part.ItemTypeId = 2 THEN nsi.IsSerialized ELSE asi.IsSerialized END AS IsSerialized,
		--CASE WHEN part.ItemTypeId = 1 THEN itm.IsTimeLife ELSE 0 END AS IsTimeLife,
		--itm.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
		--0 AS TraceableToType,
		--(SELECT ShipViaId FROM AllShipVia WHERE ReferenceId = @PurchaseOrderId AND ModuleId = 13) AS ShippingViaId,
		--0 AS OwnerType,
		--0 AS ObtainFromType,
		--0 AS CertifiedTypeId,
		--0 AS TagTypeId,
		--0 AS TaggedByType,
		--(SELECT TOP 1 SL.IsSameDetailsForAllParts FROM DBO.StockLineDraft SL WITH (NOLOCK) WHERE part.PurchaseOrderPartRecordId = SL.PurchaseOrderPartRecordId) AS IsSameDetailsForAllParts,
		--0 AS TimeLifeDetailsNotProvided,
		--itm.GLAccountId AS GLAccountId
		--FROM DBO.PurchaseOrderPart part WITH (NOLOCK)
		--LEFT JOIN DBO.ItemMaster itm WITH (NOLOCK) ON part.ItemMasterId = itm.ItemMasterId
		--LEFT JOIN DBO.Asset asi WITH (NOLOCK) ON part.ItemMasterId = asi.AssetRecordId
		--LEFT JOIN DBO.ItemMasterNonStock nsi WITH (NOLOCK) ON part.ItemMasterId = nsi.MasterPartId
		--WHERE part.PurchaseOrderId = @PurchaseOrderId
		--AND (PurchaseOrderPartRecordId NOT IN (SELECT ParentId FROM PurchaseOrderPart WHERE PurchaseOrderId = @PurchaseOrderId AND ParentId IS NOT NULL));

		SELECT DISTINCT
		part.PurchaseOrderId,
        part.ItemTypeId,
        part.PurchaseOrderPartRecordId,
        part.ItemMasterId,
        part.PartNumber,
        part.PartDescription,
        part.QuantityOrdered,
        part.QuantityBackOrdered,
        CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.ConditionId ELSE StkD_NonSer.ConditionId END AS ConditionId,
        CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.Condition ELSE StkD_NonSer.Condition END AS ConditionText,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.ShippingReference ELSE StkD_NonSer.ShippingReference END AS ShippingReference,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.ShippingAccount ELSE StkD_NonSer.ShippingAccount END AS ShippingAccount,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.TraceableToName ELSE StkD_NonSer.TraceableToName END AS TraceableToName,
        (SELECT SUM(STK.Quantity) FROM DBO.Stockline STK WITH (NOLOCK) WHERE STK.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND STK.IsParent = 1 AND STK.StockLineId IN 
		(SELECT StockLineId FROM DBO.StocklineDraft STKD WITH (NOLOCK) WHERE STKD.PurchaseOrderId = @PurchaseOrderId)) AS QuantityReceived,
        part.ManufacturerId,
        part.Manufacturer,
        part.ManagementStructureId,
		(SELECT LastMSLevel FROM DBO.PurchaseOrderManagementStructureDetails P WITH (NOLOCK) WHERE P.ReferenceID = part.PurchaseOrderPartRecordId AND p.ModuleID = 5) AS LastMSLevel,
		(SELECT AllMSlevels FROM DBO.PurchaseOrderManagementStructureDetails P WITH (NOLOCK) WHERE P.ReferenceID = part.PurchaseOrderPartRecordId AND p.ModuleID = 5) AS AllMSlevels,
        --part.UnitOfMeasure,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.UnitOfMeasureId ELSE StkD_NonSer.UnitOfMeasureId END AS UnitOfMeasureId,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.UnitOfMeasure ELSE StkD_NonSer.UnitOfMeasure END AS UnitOfMeasure,
        --part.UnitCost,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.PurchaseOrderUnitCost ELSE StkD_NonSer.PurchaseOrderUnitCost END AS UnitCost,
		--part.ExtendedCost,
		CASE WHEN itm.isSerialized = 1 THEN (StkD_Ser.PurchaseOrderUnitCost * part.QuantityOrdered) ELSE (StkD_NonSer.PurchaseOrderUnitCost * part.QuantityOrdered) END AS ExtendedCost,
        part.DiscountPerUnit,
        part.DiscountAmount,
        part.WorkOrderNo,
        part.SubWorkOrderNo,
        part.SalesOrderNo,
        part.ReapairOrderNo,
		(CASE WHEN part.ItemTypeId = 1 THEN itm.IsManufacturingDateAvailable ELSE 0 END) AS IsManufacturingDateAvailable,
        (CASE WHEN part.ItemTypeId = 1 THEN itm.IsReceivedDateAvailable ELSE 0 END) AS IsReceivedDateAvailable,
        (CASE WHEN part.ItemTypeId = 1 THEN itm.IsTagDateAvailable ELSE 0 END) AS IsTagDateAvailable,
        (CASE WHEN part.ItemTypeId = 1 THEN itm.IsExpirationDateAvailable ELSE 0 END) AS IsExpirationDateAvailable,
		part.AltEquiPartNumberId,
        part.AltEquiPartNumber,
        part.AltEquiPartDescription,
        part.ItemType,
		(CASE WHEN part.ItemTypeId = 11 THEN asi.IsIntangible ELSE 0 END) AS IsIntangible,
		part.StockType,
        part.ManufacturerPN,
        part.AssetModel,
        part.AssetClass,
		part.POPartSplitUser AS PoPartSplitUserName,
        CASE WHEN part.LotId IS NOT NULL THEN part.LotId ELSE 0 END AS LotId,
		(CASE WHEN part.LotId IS NOT NULL AND part.LotId > 0 THEN (SELECT TOP 1 L.LotNumber FROM DBO.Lot L WITH (NOLOCK) WHERE L.LotId = part.LotId) ELSE '' END) AS LotNumber,
        CASE WHEN part.IsLotAssigned IS NOT NULL THEN part.IsLotAssigned ELSE 0 END AS IsLotAssigned,
		CASE WHEN part.ItemTypeId = 1 THEN itm.isSerialized WHEN part.ItemTypeId = 2 THEN nsi.IsSerialized ELSE asi.IsSerialized END AS IsSerialized,
		CASE WHEN part.ItemTypeId = 1 THEN itm.IsTimeLife ELSE 0 END AS IsTimeLife,
		--itm.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.TraceableToType ELSE StkD_NonSer.TraceableToType END AS TraceableToType,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.TraceableTo ELSE StkD_NonSer.TraceableTo END AS TraceableTo,
		(SELECT ShipViaId FROM AllShipVia WHERE ReferenceId = @PurchaseOrderId AND ModuleId = 13) AS ShippingViaId,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.OwnerType ELSE StkD_NonSer.OwnerType END AS OwnerType,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.ObtainFromType ELSE StkD_NonSer.ObtainFromType END AS ObtainFromType,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.CertifiedTypeId ELSE StkD_NonSer.CertifiedTypeId END AS CertifiedTypeId,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.TagTypeId ELSE StkD_NonSer.TagTypeId END AS TagTypeId,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.TaggedByType ELSE StkD_NonSer.TaggedByType END AS TaggedByType,
		(SELECT TOP 1 SL.IsSameDetailsForAllParts FROM DBO.StockLineDraft SL WITH (NOLOCK) WHERE part.PurchaseOrderPartRecordId = SL.PurchaseOrderPartRecordId) AS IsSameDetailsForAllParts,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.TimeLifeDetailsNotProvided ELSE StkD_NonSer.TimeLifeDetailsNotProvided END AS TimeLifeDetailsNotProvided,
		--itm.GLAccountId AS GLAccountId
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.GLAccountId ELSE StkD_NonSer.GLAccountId END AS GLAccountId,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.ObtainFrom ELSE StkD_NonSer.ObtainFrom END AS ObtainFrom,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.ObtainFromName ELSE StkD_NonSer.ObtainFromName END AS ObtainFromName,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.[Owner] ELSE StkD_NonSer.[Owner] END AS [Owner],
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.OwnerName ELSE StkD_NonSer.OwnerName END AS OwnerName,
		CASE WHEN itm.isSerialized = 1 THEN CASE WHEN StkD_Ser.ExpirationDate IS NOT NULL THEN StkD_Ser.ExpirationDate ELSE NULL END ELSE CASE WHEN StkD_NonSer.ExpirationDate IS NOT NULL THEN StkD_NonSer.ExpirationDate ELSE NULL END END AS ExpirationDate,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.SerialNumber ELSE StkD_NonSer.SerialNumber END AS SerialNumber,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.ManufacturingTrace ELSE StkD_NonSer.ManufacturingTrace END AS ManufacturingTrace,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.ManufacturerLotNumber ELSE StkD_NonSer.ManufacturerLotNumber END AS ManufacturerLotNumber,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.ManufacturingDate ELSE StkD_NonSer.ManufacturingDate END AS ManufacturingDate,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.ManufacturingBatchNumber ELSE StkD_NonSer.ManufacturingBatchNumber END AS ManufacturingBatchNumber,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.PartCertificationNumber ELSE StkD_NonSer.PartCertificationNumber END AS PartCertificationNumber,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.CertifiedDate ELSE StkD_NonSer.CertifiedDate END AS CertifiedDate,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.CertifiedDueDate ELSE StkD_NonSer.CertifiedDueDate END AS CertifiedDueDate,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.TagDate ELSE StkD_NonSer.TagDate END AS TagDate,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.EngineSerialNumber ELSE StkD_NonSer.EngineSerialNumber END AS EngineSerialNumber,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.CertTypeId ELSE StkD_NonSer.CertTypeId END AS CertTypeId,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.CertType ELSE StkD_NonSer.CertType END AS CertType,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.CertifiedById ELSE StkD_NonSer.CertifiedById END AS CertifiedById,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.CertifiedBy ELSE StkD_NonSer.CertifiedBy END AS CertifiedBy,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.TaggedBy ELSE StkD_NonSer.TaggedBy END AS TaggedBy,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.TaggedByName ELSE StkD_NonSer.TaggedByName END AS TaggedByName,
		CASE WHEN itm.isSerialized = 1 THEN StkD_Ser.TaggedByTypeName ELSE StkD_NonSer.TaggedByTypeName END AS TaggedByTypeName
		FROM DBO.PurchaseOrderPart part WITH (NOLOCK)
		LEFT JOIN DBO.ItemMaster itm WITH (NOLOCK) ON part.ItemMasterId = itm.ItemMasterId
		LEFT JOIN DBO.Asset asi WITH (NOLOCK) ON part.ItemMasterId = asi.AssetRecordId
		LEFT JOIN DBO.ItemMasterNonStock nsi WITH (NOLOCK) ON part.ItemMasterId = nsi.MasterPartId
		LEFT JOIN DBO.StocklineDraft StkD_Ser WITH (NOLOCK) ON StkD_Ser.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND StkD_Ser.isSerialized = 1 AND StkD_Ser.IsParent = 0
		LEFT JOIN DBO.StocklineDraft StkD_NonSer WITH (NOLOCK) ON StkD_NonSer.PurchaseOrderPartRecordId = part.PurchaseOrderPartRecordId AND StkD_NonSer.isSerialized = 0 AND StkD_NonSer.IsParent = 1
		WHERE part.PurchaseOrderId = @PurchaseOrderId
		AND (part.PurchaseOrderPartRecordId NOT IN (SELECT ParentId FROM PurchaseOrderPart WHERE PurchaseOrderId = @PurchaseOrderId AND ParentId IS NOT NULL));

		SELECT DISTINCT SL.PurchaseOrderId,
        SL.PurchaseOrderPartRecordId,
        SL.StockLineDraftId,
        SL.StockLineNumber,
        SL.StockLineId,
		1 AS ItemTypeId, --ItemTypeEnum.Stock,
		(SELECT LastMSLevel FROM DBO.StockLineDraftManagementStructureDetails P WITH (NOLOCK) WHERE P.ReferenceID = SL.StockLineDraftId AND p.ModuleID = 31) AS LastMSLevel,
		(SELECT AllMSlevels FROM DBO.StockLineDraftManagementStructureDetails P WITH (NOLOCK) WHERE P.ReferenceID = SL.StockLineDraftId AND p.ModuleID = 31) AS AllMSlevels,
        SL.ControlNumber,
        SL.IdNumber,
        SL.ConditionId,
        SL.SerialNumber,
        SL.Quantity,
        SL.PurchaseOrderUnitCost,
        SL.PurchaseOrderExtendedCost,
        SL.ReceiverNumber,
		'' AS WorkOrder,
        '' AS SalesOrder,
        '' AS SubWorkOrder,
		SL.OwnerType,
        SL.ObtainFromType,
        SL.TraceableToType,
        SL.ManufacturingTrace,
        SL.ManufacturerId,
        SL.ManufacturerLotNumber,
		CASE WHEN SL.ManufacturingDate IS NOT NULL THEN SL.ManufacturingDate ELSE NULL END AS ManufacturingDate,
		SL.ManufacturingBatchNumber,
        SL.PartCertificationNumber,
        SL.EngineSerialNumber,
        SL.ShippingViaId,
        SL.ShippingReference,
        SL.ShippingAccount,
		CASE WHEN SL.CertifiedDate IS NOT NULL THEN SL.CertifiedDate ELSE NULL END CertifiedDate,
		SL.CertifiedBy,
		CASE WHEN SL.TagDate IS NOT NULL THEN SL.TagDate ELSE NULL END TagDate,
		CASE WHEN SL.ExpirationDate IS NOT NULL THEN SL.ExpirationDate ELSE NULL END ExpirationDate,
		CASE WHEN SL.CertifiedDueDate IS NOT NULL THEN SL.CertifiedDueDate ELSE NULL END CertifiedDueDate,
		SL.AircraftTailNumber,
		SL.GLAccountId,
		SL.GLAccount AS GLAccountText,
		SL.Condition AS ConditionText,
		SL.ManagementStructureEntityId,
		SL.SiteId,
		SL.WarehouseId,
		SL.LocationId,
		SL.ShelfId,
		SL.BinId,
		SL.SiteName AS SiteText,
		SL.Warehouse AS WarehouseText,
		SL.Location AS LocationText,
		SL.ShelfName AS ShelfText,
		SL.BinName AS BinText,
		SL.ObtainFrom AS ObtainFrom,
		SL.ObtainFromName,
		SL.OwnerName,
		SL.TraceableToName,
		SL.Owner,
		SL.TraceableTo,
		SL.IsDeleted,
		SL.IsSerialized,
		SL.TaggedBy,
		SL.TaggedByName,
		SL.UnitOfMeasureId,
		SL.UnitOfMeasure,
		SL.TagType,
		SL.TagTypeId,
		SL.TaggedByType,
		SL.TaggedByTypeName,
		SL.CertifiedById,
		SL.CertifiedTypeId,
		SL.CertifiedType,
		SL.CertTypeId,
		SL.CertType,
		'' AS AssetAcquisitionTypeId,
		'' AS IsIntangible,
		CASE WHEN SL.LotId IS NOT NULL THEN SL.LotId ELSE 0 END LotId,
		CASE WHEN SL.LotId IS NOT NULL AND SL.LotId > 0 THEN (SELECT TOP 1 LotNumber FROM DBO.Lot WITH (NOLOCK) WHERE LotId = SL.LotId) ELSE '' END LotNumber,
		SL.IsParent,
		SL.IsSameDetailsForAllParts,
		SL.TimeLifeDetailsNotProvided
		FROM DBO.StockLineDraft SL WITH (NOLOCK) 
		LEFT JOIN DBO.PurchaseOrderPart part WITH (NOLOCK) ON part.PurchaseOrderId = SL.PurchaseOrderId
		WHERE SL.PurchaseOrderId = @PurchaseOrderId --AND SL.IsParent = 1
		--AND SL.StockLineNumber IS NULL;
		AND SL.StockLineNumber IS NULL;

  END TRY  
  BEGIN CATCH  
	  DECLARE @ErrorLogID int  
	  ,@DatabaseName varchar(100) = DB_NAME()  
	  -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------  
	  ,@AdhocComments varchar(150) = 'USP_GetReceivingPurchaseOrderEdit_POPart'  
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