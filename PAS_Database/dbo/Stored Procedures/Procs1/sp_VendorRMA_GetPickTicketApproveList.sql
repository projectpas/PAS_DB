
/*************************************************************           
 ** File:   [sp_VendorRMA_GetPickTicketApproveList]           
 ** Author:   Amit Ghediya
 ** Description: Retrieve pick ticket listing data for Vendor RMA
 ** Change History:
 ** PR   Date         Author          Description            
 ** 1    06/19/2023   Amit Ghediya    Created
 ** 2    07/04/2023   Amit Ghediya    Get RMANum from Part level
 ** 3    02/03/2026   Amit Ghediya    UOM Conversion Changes [PN-15140]
**************************************************************/
CREATE   PROCEDURE [dbo].[sp_VendorRMA_GetPickTicketApproveList]
    @VendorRMAId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Step 1: Compute converted Qty once per VendorRMADetailId
        ;WITH ConvertedQty AS (
            SELECT
                VR.VendorRMADetailId,
                VR.ItemMasterId,
                [dbo].[fn_ConvertUOM](
                    ISNULL(VR.Qty, 0),
                    IM.StockUnitOfMeasure,
                    IM.PurchaseUnitOfMeasure,
                    0,
                    IM.MasterCompanyId
                ) AS ConvertedQty
            FROM VendorRMADetail VR WITH(NOLOCK)
            INNER JOIN Stockline ST WITH(NOLOCK) ON ST.StockLineId = VR.StockLineId
            INNER JOIN ItemMaster IM WITH(NOLOCK) ON ST.ItemMasterId = IM.ItemMasterId
            WHERE VR.VendorRMAId = @VendorRMAId
        ),

        -- Step 2: Compute QtyToShip per detail line
        ShippedQty AS (
            SELECT
                SP.VendorRMADetailId,
                SUM([dbo].[fn_ConvertUOM](
                    ISNULL(SP.QtyToShip, 0),
                    IM.StockUnitOfMeasure,
                    IM.PurchaseUnitOfMeasure,
                    0,
                    IM.MasterCompanyId
                )) AS QtyToShip
            FROM RMAPickTicket SP WITH(NOLOCK)
            INNER JOIN VendorRMADetail SO_P WITH(NOLOCK) ON SP.VendorRMADetailId = SO_P.VendorRMADetailId
            INNER JOIN Stockline ST WITH(NOLOCK) ON ST.StockLineId = SO_P.StockLineId
            INNER JOIN ItemMaster IM WITH(NOLOCK) ON ST.ItemMasterId = IM.ItemMasterId
            WHERE SP.VendorRMAId = @VendorRMAId
            GROUP BY SP.VendorRMADetailId
        ),

        -- Step 3: Compute QuantityAvailable per ItemMaster
        AvailableQty AS (
            SELECT
                sp.ItemMasterId,
                SUM([dbo].[fn_ConvertUOM](
                    ISNULL(sll.QuantityAvailable, 0),
                    IM.StockUnitOfMeasure,
                    IM.PurchaseUnitOfMeasure,
                    0,
                    IM.MasterCompanyId
                )) AS QuantityAvailable
            FROM StockLine sll WITH(NOLOCK)
            INNER JOIN VendorRMADetail sp WITH(NOLOCK) ON sll.StockLineId = sp.StockLineId
            INNER JOIN Stockline ST WITH(NOLOCK) ON ST.StockLineId = sp.StockLineId
            INNER JOIN ItemMaster IM WITH(NOLOCK) ON ST.ItemMasterId = IM.ItemMasterId
            WHERE sp.VendorRMAId = @VendorRMAId
            GROUP BY sp.ItemMasterId
        ),

        -- Step 4: Main aggregation
        CTE AS (
            SELECT
                sop.VendorRMADetailId,
                sop.ItemMasterId,
                sop.VendorRMAId,
                imt.PartNumber,
                imt.PartDescription,
                cq.ConvertedQty                         AS Qty,
                ''                                      AS SerialNumber,
                ISNULL(aq.QuantityAvailable, 0)         AS QuantityAvailable,
                sop.RMANum                              AS RMANumber,
                ISNULL(sq.QtyToShip, 0)                 AS QtyToShip,
                ''                                      AS [Status],
                sl.ConditionId,
                cr.VendorName,
                cr.VendorCode,
                0                                       AS TotalReadyToPick
            FROM VendorRMADetail sop WITH(NOLOCK)
            INNER JOIN ItemMaster imt WITH(NOLOCK)  ON imt.ItemMasterId = sop.ItemMasterId
            INNER JOIN ConvertedQty cq              ON cq.VendorRMADetailId = sop.VendorRMADetailId
                                                   AND cq.ItemMasterId = sop.ItemMasterId
            LEFT JOIN AvailableQty aq               ON aq.ItemMasterId = sop.ItemMasterId
            LEFT JOIN ShippedQty sq                 ON sq.VendorRMADetailId = sop.VendorRMADetailId
            LEFT JOIN StockLine sl WITH(NOLOCK)     ON sl.StockLineId = sop.StockLineId
            LEFT JOIN VendorRMA so WITH(NOLOCK)     ON so.VendorRMAId = sop.VendorRMAId
            LEFT JOIN Vendor cr WITH(NOLOCK)        ON cr.VendorId = so.VendorId
            WHERE sop.VendorRMAId = @VendorRMAId
        )

        -- Step 5: Final output
        SELECT
            VendorRMADetailId,
            ItemMasterId,
            VendorRMAId,
            PartNumber,
            PartDescription,
            Qty,
            SerialNumber,
            QuantityAvailable,
            RMANumber,
            QtyToShip,
            (Qty - QtyToShip)                                                           AS QtyToPick,
            ConditionId,
            CASE WHEN QtyToShip > 0 THEN (Qty - QtyToShip) ELSE Qty END                AS ReadyToPick,
            [Status],
            VendorName,
            VendorCode,
            CASE WHEN TotalReadyToPick < 0 THEN 0 ELSE TotalReadyToPick END            AS TotalReadyToPick
        FROM CTE;

    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID         INT,
            @DatabaseName       VARCHAR(100)  = DB_NAME(),
            @AdhocComments      VARCHAR(150)  = 'sp_VendorRMA_GetPickTicketApproveList',
            @ProcedureParameters VARCHAR(3000) = '@VendorRMAId = ' + CAST(ISNULL(@VendorRMAId, 0) AS VARCHAR(20)),
            @ApplicationName    VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error in the database. Support error number: %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END