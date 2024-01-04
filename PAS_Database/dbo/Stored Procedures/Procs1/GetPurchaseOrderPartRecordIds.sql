
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
    2    10/10/2023  Vishal Suthar  Modified to handle New Receiving PO changes
	3	 02-01-2024  Shrey Chandegara  modified for receiving po view
     
-- EXEC [GetPurchaseOrderPartRecordIds] 2382,3
************************************************************************/ 

CREATE   PROCEDURE [dbo].[GetPurchaseOrderPartRecordIds]
@PurchaseOrderId bigint=171,
@Opr int
AS
BEGIN	
	IF(@Opr = 1)
	BEGIN
		SELECT PurchaseOrderPartRecordId FROM [dbo].[StockLineDraft] WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1
		UNION
		SELECT PurchaseOrderPartRecordId FROM [dbo].[NonStockInventoryDraft] WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1
		UNION
		SELECT PurchaseOrderPartRecordId FROM [dbo].[AssetInventoryDraft]  WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1
	END
	ELSE IF (@Opr = 2)
	BEGIN
		SELECT PurchaseOrderPartRecordId FROM [dbo].[StockLineDraft] WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1 AND (StockLineId IS NULL OR  StockLineId = 0)
		UNION
		SELECT PurchaseOrderPartRecordId FROM [dbo].[NonStockInventoryDraft] WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1 AND (NonStockInventoryId IS NULL OR  NonStockInventoryId = 0)
		UNION
		SELECT PurchaseOrderPartRecordId FROM [dbo].[AssetInventoryDraft] WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND IsParent = 1 AND (AssetInventoryId IS NULL OR  AssetInventoryId = 0)
	END
	ELSE IF (@Opr = 3)
	BEGIN
		SELECT PurchaseOrderPartRecordId FROM [dbo].[StockLineDraft] WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND ((IsParent = 1 AND isSerialized = 1) OR (IsParent = 0 AND isSerialized = 0)) AND StockLineId IS NOT NULL --> 0
		UNION
		SELECT PurchaseOrderPartRecordId FROM [dbo].[NonStockInventoryDraft] WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND ((IsParent = 1 AND isSerialized = 1) OR (IsParent = 0 AND isSerialized = 0))  AND NonStockInventoryId > 0
		UNION
		SELECT PurchaseOrderPartRecordId FROM [dbo].[AssetInventoryDraft] WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND isDeleted = 0 AND ((IsParent = 1 AND isSerialized = 1) OR (IsParent = 0 AND isSerialized = 0))  AND AssetInventoryId > 0
	END
END