CREATE PROCEDURE [dbo].[GetVendorRFQRORepairOrderPart]
@VendorRFQRepairOrderId bigint,
@VendorRFQROPartRecordId bigint
AS
BEGIN
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
				 ,SalesOrderId,SalesOrderNo,ItemTypeId,ItemType
		   FROM dbo.VendorRFQRepairOrderPart WITH(NOLOCK) WHERE [VendorRFQROPartRecordId]=@VendorRFQROPartRecordId AND RepairOrderId IS NULL;
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
				 ,SalesOrderId,SalesOrderNo,ItemTypeId,ItemType
		   FROM dbo.VendorRFQRepairOrderPart WITH(NOLOCK) WHERE [VendorRFQRepairOrderId]=@VendorRFQRepairOrderId AND RepairOrderId IS NULL;
	  END
END