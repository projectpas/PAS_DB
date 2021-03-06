
/*************************************************************           
 ** File:   [GetPurchaseOrderPartRecordIds]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to get PurchaseOrderPartRecordId from StockLineDraft NonStockInventoryDraft  AssetInventoryDraft Tables
 ** Purpose:         
 ** Date:   02/02/2022        
          
 ** PARAMETERS: @PurchaseOrderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/02/2022  Moin Bloch     Created
     
-- EXEC [GetPurchaseOrderPartRecordIds] 171,2
************************************************************************/ 

CREATE PROCEDURE [dbo].[GetPurchaseOrderPartRecordIds]
@PurchaseOrderId bigint=171,
@Opr int
AS
BEGIN	
	IF(@Opr = 1)
	BEGIN
		SELECT PurchaseOrderPartRecordId FROM StockLineDraft WHERE  PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1
		UNION
		SELECT PurchaseOrderPartRecordId FROM NonStockInventoryDraft WHERE  PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1
		UNION
		SELECT PurchaseOrderPartRecordId FROM AssetInventoryDraft WHERE  PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1
	END
	ELSE IF (@Opr = 2)
	BEGIN
		SELECT PurchaseOrderPartRecordId FROM StockLineDraft WHERE  PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1 AND (StockLineId IS NULL OR  StockLineId = 0)
		UNION
		SELECT PurchaseOrderPartRecordId FROM NonStockInventoryDraft WHERE  PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1 AND (NonStockInventoryId IS NULL OR  NonStockInventoryId = 0)
		UNION
		SELECT PurchaseOrderPartRecordId FROM AssetInventoryDraft WHERE  PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1 AND (AssetInventoryId IS NULL OR  AssetInventoryId = 0)
	END
	ELSE IF (@Opr = 3)
	BEGIN
		SELECT PurchaseOrderPartRecordId FROM StockLineDraft WHERE  PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1 AND StockLineId > 0
		UNION
		SELECT PurchaseOrderPartRecordId FROM NonStockInventoryDraft WHERE  PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1 AND NonStockInventoryId > 0
		UNION
		SELECT PurchaseOrderPartRecordId FROM AssetInventoryDraft WHERE  PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1 AND AssetInventoryId > 0
	END
END