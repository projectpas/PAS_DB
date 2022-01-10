



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

CREATE PROCEDURE GetVendorRFQRORepairOrderPart
@VendorRFQRepairOrderId bigint
AS
BEGIN
	 SELECT [VendorRFQROPartRecordId],
			[ItemMasterId],
			[PartNumber],
			[ConditionId],
			[Condition],
			[QuantityOrdered] 
	   FROM dbo.VendorRFQRepairOrderPart WITH(NOLOCK) WHERE [VendorRFQRepairOrderId]=@VendorRFQRepairOrderId AND RepairOrderId IS NULL;
END