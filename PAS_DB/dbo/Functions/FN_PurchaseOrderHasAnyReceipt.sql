-- =============================================
-- Author:		Abhishek Jirawala
-- Create date: 26 Aug 2026
-- Description:	Unlink PO - returns 1 if any part/line on the given
--              Purchase Order has been received, by any of the three
--              receipt signals used elsewhere in the app (PurchaseOrderPart
--              .QuantityReceived, Stockline, StockLineDraft, AssetInventoryDraft).
--              Deliberately conservative (ORs all signals) so Unlink PO
--              never allows unlinking a PO that has any receipt activity.
-- =============================================
/*************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------				--------------------------------
    1    26/Aug/2026   Abhishek Jirawala	Created for Unlink PO feature

SELECT dbo.FN_PurchaseOrderHasAnyReceipt(1863)
**************************************************************/
CREATE FUNCTION [dbo].[FN_PurchaseOrderHasAnyReceipt]
(
    @PurchaseOrderId BIGINT
)
RETURNS BIT
AS
BEGIN
    DECLARE @HasReceipt BIT = 0

    IF EXISTS (
        SELECT 1 FROM [dbo].[PurchaseOrderPart] WITH (NOLOCK)
        WHERE [PurchaseOrderId] = @PurchaseOrderId AND ISNULL([IsDeleted], 0) = 0 AND ISNULL([QuantityReceived], 0) > 0
    )
    SET @HasReceipt = 1

    IF @HasReceipt = 0 AND EXISTS (
        SELECT 1 FROM [dbo].[Stockline] WITH (NOLOCK)
        WHERE [PurchaseOrderId] = @PurchaseOrderId AND ISNULL([isDeleted], 0) = 0
    )
    SET @HasReceipt = 1

    IF @HasReceipt = 0 AND EXISTS (
        SELECT 1 FROM [dbo].[StockLineDraft] WITH (NOLOCK)
        WHERE [PurchaseOrderId] = @PurchaseOrderId AND ISNULL([isDeleted], 0) = 0 AND [StockLineId] IS NOT NULL
    )
    SET @HasReceipt = 1

    IF @HasReceipt = 0 AND EXISTS (
        SELECT 1 FROM [dbo].[AssetInventoryDraft] WITH (NOLOCK)
        WHERE [PurchaseOrderId] = @PurchaseOrderId AND ISNULL([isDeleted], 0) = 0 AND ISNULL([AssetInventoryId], 0) > 0
    )
    SET @HasReceipt = 1

    RETURN @HasReceipt
END
