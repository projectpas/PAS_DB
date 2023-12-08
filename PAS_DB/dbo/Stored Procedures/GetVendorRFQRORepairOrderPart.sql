/*************************************************************                 
 ** File:  [GetVendorRFQRORepairOrderPart]                 
 ** Author:      
 ** Description: This stored procedure is used to Get vendor RFQ RO Part List      
 ** Purpose:               
 ** Date:             
                
 ** PARAMETERS: @@VendorRFQRepairOrderId bigint,@VendorRFQROPartRecordId bigint   
               
 ** RETURN VALUE:                 
 **************************************************************                 
 ** Change History                 
 **************************************************************                 
 ** PR   Date         Author          Change Description                  
 ** --   --------     -------         --------------------------------                
    1    06/12/2023  AMIT GHEDIYA     Updated (Added Traceable & Tagged fields)  
           
-- EXEC [GetVendorRFQRORepairOrderPart] 33,23     
************************************************************************/ 
CREATE OR ALTER PROCEDURE [dbo].[GetVendorRFQRORepairOrderPart]
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
				MSD.AllMSlevels,
				[TraceableTo],
				[TraceableToName],
				[TraceableToType],
				[TagTypeId],
				[TaggedBy],
				[TaggedByType],
				[TaggedByName],
				[TaggedByTypeName],
				[TagDate]
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
				MSD.AllMSlevels,
				[TraceableTo],
				[TraceableToName],
				[TraceableToType],
				[TagTypeId],
				[TaggedBy],
				[TaggedByType],
				[TaggedByName],
				[TaggedByTypeName],
				[TagDate]
		   FROM dbo.VendorRFQRepairOrderPart VRF WITH(NOLOCK)
		   INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = VRF.VendorRFQROPartRecordId AND MSD.ModuleID=@ModuleId
		   WHERE [VendorRFQRepairOrderId]=@VendorRFQRepairOrderId AND RepairOrderId IS NULL;
	  END
END