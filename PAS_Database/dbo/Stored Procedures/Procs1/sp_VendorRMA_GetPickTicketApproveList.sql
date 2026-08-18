/*************************************************************           
 ** File:   [sp_VendorRMA_GetPickTicketApproveList]           
 ** Author:   Amit Ghediya
 ** Description: Retrieve pick ticket listing data for Vendor RMA
 ** Change History:
 ** PR   Date         Author          Description            
 ** 1    06/19/2023   Amit Ghediya    Created
 ** 2    07/04/2023   Amit Ghediya    Get RMANum from Part level
 ** 3    02/03/2026   Amit Ghediya    UOM Conversion Changes [PN-15140]
 ** 4	 19/06/2026	  Ayushi		  [PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
 ** 6    07/07/2026   Ayushi          [PN-16865] Added ROUND(,2) to quantity fields after UOM conversion
 ** 7    09/July/2026 Rajesh Gami     [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
 ** 8    13/Aug/2026  Rajesh Gami     [PN-17009] - Applied missing ISNULL(sll.IsNonStock,0) = 0 filter in AvailableQty CTE
**************************************************************/
CREATE   PROCEDURE [dbo].[sp_VendorRMA_GetPickTicketApproveList]
    @VendorRMAId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        ;WITH ConvertedQty AS (
        SELECT
            VR.VendorRMADetailId,
            VR.ItemMasterId,
            ROUND(
                CASE
                    WHEN ISNULL(IM.StockUnitOfMeasure,'') = ISNULL(IM.PurchaseUnitOfMeasure,'')
                        THEN ISNULL(VR.Qty,0)
                    ELSE [dbo].[fn_ConvertUOM](
                            ISNULL(VR.Qty,0),
                            IM.StockUnitOfMeasure,
                            IM.PurchaseUnitOfMeasure,
                            0,
                            IM.MasterCompanyId
                         )
                END,
            2) AS ConvertedQty
        FROM VendorRMADetail VR WITH(NOLOCK)
        INNER JOIN Stockline ST WITH(NOLOCK) ON ST.StockLineId = VR.StockLineId
        INNER JOIN ItemMaster IM WITH(NOLOCK) ON ST.ItemMasterId = IM.ItemMasterId
        WHERE VR.VendorRMAId = @VendorRMAId
    ),

    ShippedQty AS (
        SELECT
            SP.VendorRMADetailId,
            ROUND(
                SUM(
                    CASE
                        WHEN ISNULL(IM.StockUnitOfMeasure,'') = ISNULL(IM.PurchaseUnitOfMeasure,'')
                            THEN ISNULL(SP.QtyToShip,0)
                        ELSE [dbo].[fn_ConvertUOM](
                                ISNULL(SP.QtyToShip,0),
                                IM.StockUnitOfMeasure,
                                IM.PurchaseUnitOfMeasure,
                                0,
                                IM.MasterCompanyId
                             )
                    END
                ),
            2) AS QtyToShip
        FROM RMAPickTicket SP WITH(NOLOCK)
        INNER JOIN VendorRMADetail SO_P WITH(NOLOCK) ON SP.VendorRMADetailId = SO_P.VendorRMADetailId
        INNER JOIN Stockline ST WITH(NOLOCK) ON ST.StockLineId = SO_P.StockLineId
        INNER JOIN ItemMaster IM WITH(NOLOCK) ON ST.ItemMasterId = IM.ItemMasterId
        WHERE SP.VendorRMAId = @VendorRMAId
        GROUP BY SP.VendorRMADetailId
    ),

    AvailableQty AS (
        SELECT
            sp.ItemMasterId,
            ROUND(
                SUM(
                    CASE
                        WHEN ISNULL(IM.StockUnitOfMeasure,'') = ISNULL(IM.PurchaseUnitOfMeasure,'')
                            THEN ISNULL(sll.QuantityAvailable,0)
                        ELSE [dbo].[fn_ConvertUOM](
                                ISNULL(sll.QuantityAvailable,0),
                                IM.StockUnitOfMeasure,
                                IM.PurchaseUnitOfMeasure,
                                0,
                                IM.MasterCompanyId
                             )
                    END
                ),
            2) AS QuantityAvailable
            FROM StockLine sll WITH(NOLOCK)
            INNER JOIN VendorRMADetail sp WITH(NOLOCK) ON sll.StockLineId = sp.StockLineId
            INNER JOIN Stockline ST WITH(NOLOCK) ON ST.StockLineId = sp.StockLineId
            INNER JOIN ItemMaster IM WITH(NOLOCK) ON ST.ItemMasterId = IM.ItemMasterId
            WHERE sp.VendorRMAId = @VendorRMAId AND ISNULL(sll.IsNonStock,0) = 0
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
            LEFT JOIN StockLine sl WITH(NOLOCK)     ON sl.StockLineId = sop.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
            LEFT JOIN VendorRMA so WITH(NOLOCK)     ON so.VendorRMAId = sop.VendorRMAId
            LEFT JOIN Vendor cr WITH(NOLOCK)        ON cr.VendorId = so.VendorId
            WHERE sop.VendorRMAId = @VendorRMAId AND ISNULL(imt.IsNonStock,0) = 0
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