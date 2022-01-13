

/*************************************************************           
 ** File:   [GetVendorRFQRORepairOrderPart]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to get vendor RFQ  Repair Order  Parts list 
 ** Purpose:         
 ** Date:   06/01/2022        
          
 ** PARAMETERS: @VendorRFQRepairOrderId bigint,
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/01/2022  Moin Bloch     Created
     
-- EXEC [GetVendorRFQRORepairOrderPart] 31
************************************************************************/

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
				[UnitCost]
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
				 [UnitCost]
		   FROM dbo.VendorRFQRepairOrderPart WITH(NOLOCK) WHERE [VendorRFQRepairOrderId]=@VendorRFQRepairOrderId AND RepairOrderId IS NULL;
	  END
END