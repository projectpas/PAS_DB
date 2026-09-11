-- =============================================
-- Author:		Abhishek Jirawala
-- Create date: 26 Aug 2026
-- Description:	Unlink PO - returns 1 if the module grid line identified by
--              (@ModuleId, @ReferenceId, @ReferencePartId, @IsKit) has any
--              reserved or issued quantity. Used to block Unlink PO from
--              the Work Order Material Grid / Sales Order entry points.
--              When @ReferencePartId is not already resolved, falls back to
--              the same Condition/ItemMaster (+ Nha_Tla_Alt_Equ_ItemMapping
--              for WorkOrder) join used by sp_UpdatePOPartReferenceDetail to
--              locate the grid row.
--              RepairOrder (2) and Lot (6) have no reservation concept in
--              this app today, so they always return 0.
-- =============================================
/*************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------				--------------------------------
    1    26/Aug/2026   Abhishek Jirawala	Created for Unlink PO feature

SELECT dbo.FN_IsModulePartReservedOrIssued(1, 500, 900, 0, NULL, NULL)
**************************************************************/
CREATE FUNCTION [dbo].[FN_IsModulePartReservedOrIssued]
(
    @ModuleId INT,
    @ReferenceId BIGINT,
    @ReferencePartId BIGINT = NULL,
    @IsKit BIT = 0,
    @ItemMasterId BIGINT = NULL,
    @ConditionId BIGINT = NULL
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT = 0

    IF @ModuleId = 1 -- WorkOrder
    BEGIN
        IF ISNULL(@IsKit, 0) = 0
        BEGIN
            IF @ReferencePartId IS NOT NULL
            BEGIN
                SELECT @Result = CASE WHEN (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0)) > 0 THEN 1 ELSE 0 END
                FROM [dbo].[WorkOrderMaterials] WITH (NOLOCK)
                WHERE WorkOrderMaterialsId = @ReferencePartId
            END
            ELSE
            BEGIN
                SELECT @Result = CASE WHEN (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0)) > 0 THEN 1 ELSE 0 END
                FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK)
                LEFT JOIN [dbo].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = @ItemMasterId
                WHERE WOM.WorkOrderId = @ReferenceId AND WOM.ConditionCodeId = @ConditionId
                      AND (WOM.ItemMasterId = @ItemMasterId OR WOM.ItemMasterId = MainNha.ItemMasterId)
            END
        END
        ELSE
        BEGIN
            IF @ReferencePartId IS NOT NULL
            BEGIN
                SELECT @Result = CASE WHEN (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0)) > 0 THEN 1 ELSE 0 END
                FROM [dbo].[WorkOrderMaterialsKit] WITH (NOLOCK)
                WHERE WorkOrderMaterialsKitId = @ReferencePartId
            END
            ELSE
            BEGIN
                SELECT @Result = CASE WHEN (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0)) > 0 THEN 1 ELSE 0 END
                FROM [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK)
                LEFT JOIN [dbo].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = @ItemMasterId
                WHERE WOM.WorkOrderId = @ReferenceId AND WOM.ConditionCodeId = @ConditionId
                      AND (WOM.ItemMasterId = @ItemMasterId OR WOM.ItemMasterId = MainNha.ItemMasterId)
            END
        END
    END
    ELSE IF @ModuleId = 5 -- SubWorkOrder
    BEGIN
        IF @ReferencePartId IS NOT NULL
        BEGIN
            SELECT @Result = CASE WHEN (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0)) > 0 THEN 1 ELSE 0 END
            FROM [dbo].[SubWorkOrderMaterials] WITH (NOLOCK)
            WHERE SubWorkOrderMaterialsId = @ReferencePartId
        END
        ELSE
        BEGIN
            SELECT @Result = CASE WHEN (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0)) > 0 THEN 1 ELSE 0 END
            FROM [dbo].[SubWorkOrderMaterials] WITH (NOLOCK)
            WHERE SubWorkOrderId = @ReferenceId AND ConditionCodeId = @ConditionId AND ItemMasterId = @ItemMasterId
        END
    END
    ELSE IF @ModuleId = 3 -- SalesOrder
    BEGIN
        DECLARE @SalesOrderPartId BIGINT = @ReferencePartId
        IF @SalesOrderPartId IS NULL
        BEGIN
            SELECT TOP 1 @SalesOrderPartId = SalesOrderPartId
            FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK)
            WHERE SalesOrderId = @ReferenceId AND ConditionId = @ConditionId AND ItemMasterId = @ItemMasterId
        END

        IF @SalesOrderPartId IS NOT NULL
        BEGIN
            SELECT @Result = CASE WHEN ISNULL(QtyReserved, 0) > 0 THEN 1 ELSE 0 END
            FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK)
            WHERE SalesOrderPartId = @SalesOrderPartId

            IF @Result = 0 AND EXISTS (
                SELECT 1 FROM [dbo].[SalesOrderStocklineV1] WITH (NOLOCK)
                WHERE SalesOrderPartId = @SalesOrderPartId AND ISNULL(QtyReserved, 0) > 0
            )
            SET @Result = 1
        END
    END
    ELSE IF @ModuleId = 4 -- Exchange
    BEGIN
        DECLARE @ExchangeSalesOrderPartId BIGINT = @ReferencePartId
        IF @ExchangeSalesOrderPartId IS NULL
        BEGIN
            SELECT TOP 1 @ExchangeSalesOrderPartId = ExchangeSalesOrderPartId
            FROM [dbo].[ExchangeSalesOrderPart] WITH (NOLOCK)
            WHERE ExchangeSalesOrderId = @ReferenceId AND ConditionId = @ConditionId AND ItemMasterId = @ItemMasterId
        END

        IF @ExchangeSalesOrderPartId IS NOT NULL AND EXISTS (
            SELECT 1 FROM [dbo].[ExchangeSalesOrderStockLineReserve] WITH (NOLOCK)
            WHERE ExchangeSalesOrderPartId = @ExchangeSalesOrderPartId AND IsReserved = 1
                  AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(QtyReserved, 0) > 0
        )
        SET @Result = 1
    END
    -- ModuleId 2 (RepairOrder) and 6 (Lot): no reservation concept, @Result stays 0

    RETURN @Result
END
