-- =============================================
-- Author:		HEMANT SALIYA	
-- Create date: 27-03-2025
-- Description:	This stored procedure is used to Detete kit Stockline 
-- =============================================

/*************************************************************   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    27-03-2025   HEMANT SALIYA			Created

	EXEC [USP_DeleteWorkOrderMaterialkitStocklineById]
**************************************************************/

CREATE   PROCEDURE USP_UnMappedPOByWorkOrderMaterialsId
    @WorkOrderMaterialsKitId BIGINT,
    @IsKit BIT,
    @IsSubWO BIT,
    @ReferenceId BIGINT = NULL, -- @WorkOrderId OR @SubWorkOrderId
    @POId BIGINT = NULL,
    @UpdatedBy VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PurchaseOrderPartId BIGINT;
	DECLARE @POWOCount INT;
	DECLARE @POSubWOCount INT;
	DECLARE @WorkorderModuleId INT = 1; --Enum PurchaseOrderPartReference Module For WO
	DECLARE @SubWorkOrderModuleId INT = 5; --Enum PurchaseOrderPartReference Module for Sub WO

    -- Get the first matching record
    SELECT TOP 1 @PurchaseOrderPartId = PurchaseOrderPartRecordId 
    FROM [DBO].PurchaseOrderPart WITH (NOLOCK)
    WHERE WorkOrderMaterialsId = @WorkOrderMaterialsKitId AND ISNULL(IsKit, 0) = @IsKit AND ISNULL(IsSubWO, 0) = @IsSubWO;

    IF @PurchaseOrderPartId IS NOT NULL
    BEGIN
        IF ISNULL(@IsSubWO, 0) = 1
        BEGIN
            
            SELECT @POSubWOCount = COUNT(*) 
            FROM [DBO].PurchaseOrderPart WITH (NOLOCK)
            WHERE SubWorkOrderId = @ReferenceId 
                  AND PurchaseOrderId = @POId;

            IF ISNULL(@POSubWOCount, 0) = 1
            BEGIN
                -- Update SubWorkOrderId and SubWorkOrderNo to NULL
                UPDATE [DBO].PurchaseOrderPart
                SET SubWorkOrderId = NULL,
                    SubWorkOrderNo = NULL,
					WorkOrderMaterialsId = NULL,
					IsKit = 0,
					IsSubWO = 0,
					UpdatedBy = @updatedBy,
					UpdatedDate = GETUTCDATE()
                WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartId;

                -- Delete related records in PurchaseOrderPartReference
                DELETE FROM [DBO].PurchaseOrderPartReference
                WHERE ReferenceId = @ReferenceId 
                      AND PurchaseOrderId = @POId 
                      AND ModuleId = @SubWorkOrderModuleId;
            END
        END
        ELSE
        BEGIN
            
            SELECT @POWOCount = COUNT(*) 
            FROM [DBO].PurchaseOrderPart WITH (NOLOCK)
            WHERE WorkOrderId = @ReferenceId 
                  AND PurchaseOrderId = @POId;

            IF ISNULL(@POWOCount, 0) = 1
            BEGIN
                -- Update WorkOrderId and WorkOrderNo to NULL
                UPDATE [DBO].PurchaseOrderPart
                SET WorkOrderId = NULL,
                    WorkOrderNo = NULL,
					WorkOrderMaterialsId = NULL,
					IsKit = 0,
					IsSubWO = 0,
					UpdatedBy = @UpdatedBy,
					UpdatedDate = GETUTCDATE()
                WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartId;

                -- Delete related records in PurchaseOrderPartReference
                DELETE FROM [DBO].PurchaseOrderPartReference
                WHERE ReferenceId = @ReferenceId 
                      AND PurchaseOrderId = @POId 
                      AND ModuleId = @WorkorderModuleId;
            END
        END
    END
END