/*************************************************************
 ** File:   [fn_SalesOrderIsPrintFormsAllowed]
 ** Author:  RAJESH GAMI
 ** Description: Returns 1 when the Sales Order has at least one STOCK part (not Non-Stock) that is
 **              reserved or already shipped, so ATA 106 / COC - Manufacturing print options can be enabled.
 ** PARAMETERS: @SalesOrderId bigint
 ** RETURN VALUE: BIT
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author         Change Description
 ** --   --------      -------        --------------------------------
    1    16/Oct/2026   RAJESH GAMI    Created [PN-18370]
 SELECT [dbo].[fn_SalesOrderIsPrintFormsAllowed](1484)
************************************************************************/
CREATE FUNCTION [dbo].[fn_SalesOrderIsPrintFormsAllowed]
(
    @SalesOrderId BIGINT
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsAllowed BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM [dbo].[SalesOrderPartV1] sop WITH(NOLOCK)
        INNER JOIN [dbo].[ItemMaster] sopim WITH(NOLOCK) ON sopim.ItemMasterId = sop.ItemMasterId
        WHERE sop.SalesOrderId = @SalesOrderId
          AND ISNULL(sop.IsActive, 1) = 1 AND ISNULL(sop.IsDeleted, 0) = 0
          -- Stock part only. Non-Stock is decided on the SO stockline (same source as the Parts List IsNonStock);
          -- the item master flag is used only when the part has no SO stockline row yet.
          AND ( (NOT EXISTS (SELECT 1 FROM [dbo].[SalesOrderStocklineV1] s0 WITH(NOLOCK)
                             WHERE s0.SalesOrderPartId = sop.SalesOrderPartId AND s0.IsActive = 1 AND s0.IsDeleted = 0)
                 AND ISNULL(sopim.IsNonStock, 0) = 0)
                OR EXISTS (SELECT 1 FROM [dbo].[SalesOrderStocklineV1] s1 WITH(NOLOCK)
                           INNER JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON sl.StockLineId = s1.StockLineId
                           WHERE s1.SalesOrderPartId = sop.SalesOrderPartId AND s1.IsActive = 1 AND s1.IsDeleted = 0
                             AND ISNULL(sl.IsNonStock, 0) = 0) )
          -- Reserved (NULL or 0 = not reserved) or already shipped. Orders reserved before ToTalReservedQty existed
          -- (PN-17734) are still covered by QtyReserved and by the shipped quantity.
          AND ( ISNULL(sop.ToTalReservedQty, 0) > 0
                OR ISNULL(sop.QtyReserved, 0) > 0
                OR EXISTS (SELECT 1 FROM [dbo].[SalesOrderStocklineV1] s2 WITH(NOLOCK)
                           WHERE s2.SalesOrderPartId = sop.SalesOrderPartId AND s2.IsActive = 1 AND s2.IsDeleted = 0
                             AND (ISNULL(s2.ToTalReservedQty, 0) > 0 OR ISNULL(s2.QtyReserved, 0) > 0))
                OR EXISTS (SELECT 1 FROM [dbo].[SalesOrderShippingItem] sosi WITH(NOLOCK)
                           INNER JOIN [dbo].[SalesOrderShipping] sos WITH(NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId
                           WHERE sosi.SalesOrderPartId = sop.SalesOrderPartId AND sos.IsActive = 1 AND sos.IsDeleted = 0
                             AND ISNULL(sosi.QtyShipped, 0) > 0) )
    )
        SET @IsAllowed = 1;

    RETURN @IsAllowed;
END
