CREATE PROCEDURE [dbo].[GetVendorRFQRORepairOrderPart]
@VendorRFQRepairOrderId bigint,
@VendorRFQROPartRecordId bigint
AS
BEGIN
	DECLARE @ModuleId INT=23;
	 IF(@VendorRFQROPartRecordId > 0)
	 BEGIN
		 SELECT [VendorRFQROPartRecordId],
				[ItemMasterId],
				[PartNumber],
				[ConditionId],
				[Condition],
				[QuantityOrdered],
				[UnitCost],
				PriorityId,Priority,WorkPerformedId,WorkPerformed,WorkOrderId,WorkOrderNo,SubWorkOrderId,SubWorkOrderNo
				,SalesOrderId,SalesOrderNo,ItemTypeId,ItemType,
				EntityMSID AS EntityStructureId,
				MSD.LastMSLevel,
				MSD.AllMSlevels
		   FROM dbo.VendorRFQRepairOrderPart VRF WITH(NOLOCK) 
		   INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = VRF.VendorRFQROPartRecordId AND MSD.ModuleID=@ModuleId
		   WHERE [VendorRFQROPartRecordId]=@VendorRFQROPartRecordId AND RepairOrderId IS NULL;
	  END
	  ELSE
	  BEGIN
		  SELECT [VendorRFQROPartRecordId],
				 [ItemMasterId],
				 [PartNumber],
				 [ConditionId],
				 [Condition],
				 [QuantityOrdered], 
				 [UnitCost],
				 PriorityId,Priority,WorkPerformedId,WorkPerformed,WorkOrderId,WorkOrderNo,SubWorkOrderId,SubWorkOrderNo
				 ,SalesOrderId,SalesOrderNo,ItemTypeId,ItemType,
				EntityMSID AS EntityStructureId,
				MSD.LastMSLevel,
				MSD.AllMSlevels
		   FROM dbo.VendorRFQRepairOrderPart VRF WITH(NOLOCK)
		   INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = VRF.VendorRFQROPartRecordId AND MSD.ModuleID=@ModuleId
		   WHERE [VendorRFQRepairOrderId]=@VendorRFQRepairOrderId AND RepairOrderId IS NULL;
	  END
END