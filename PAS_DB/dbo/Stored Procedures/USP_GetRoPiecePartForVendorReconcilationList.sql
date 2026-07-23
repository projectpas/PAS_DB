/*************************************************************             
 ** File:   [USP_GetRoPiecePartForVendorReconcilationList]             
 ** Author:   Abhishek Jirawla   
 ** Description: Get Ro PiecePart For Vendor Reconcilation List 
 ** Purpose:           
 ** Date:   22/06/2026	       
            
 ** PARAMETERS:             
     
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
  ** S NO   Date            Author				Change Description              
  ** --   --------			-------				--------------------------------            
     1    22/06/2026		Abhishek Jirawla	Created
     2    09/July/2026		RAJESH GAMI	[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock 
     2    16/07/2026		Abhishek Jirawla	QtyShipped falls back to QuantityOrdered when Enforce Pick Ticket is off
     3    16/07/2026		Abhishek Jirawla	WorkOrderNumber falls back to '-' when RO has no attached WO
     4    16/07/2026		Abhishek Jirawla	WorkOrderNumber falls back to a sibling RO part's WO when the piece part itself has none
     5    16/07/2026		Abhishek Jirawla	Renamed output column WorkOrderNumber to WONumber to match Field Master grid config
     6    21/07/2026		Abhishek Jirawla	Added ORDER BY support for Condition, SerialNumber, StocklineNumber, ControlNumber, ControlId, MPN, MPNDescription so every grid column is sortable
 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetRoPiecePartForVendorReconcilationList]
    @PageNumber             INT,
    @PageSize               INT,
    @SortColumn             NVARCHAR(100)   = 'RepairOrderPartRecordId',
    @SortOrder              INT             = -1,           -- 1 = ASC, -1 = DESC
    @GlobalFilter           NVARCHAR(500)   = '',
    -- Column-level filters
    @VendorName             NVARCHAR(255)   = NULL,
    @VendorCode             NVARCHAR(100)   = NULL,
    @PartNumber             NVARCHAR(255)   = NULL,
    @PartDescription        NVARCHAR(500)   = NULL,
    @RONumber               NVARCHAR(100)   = NULL,
    @WONumber               NVARCHAR(100)   = NULL,
    @Condition              NVARCHAR(100)   = NULL,
    @SerialNumber           NVARCHAR(100)   = NULL,
    @StocklineNumber        NVARCHAR(100)   = NULL,
    @ControlNumber          NVARCHAR(100)   = NULL,
    @ControlId              NVARCHAR(50)    = NULL,
    @MPN                    NVARCHAR(255)   = NULL,
    @MPNDescription         NVARCHAR(500)   = NULL,
    @ReconciliationStatus   NVARCHAR(50)    = NULL,
    -- Qty/cost filters are matched against AggregatedParts' computed values below,
    -- so they're kept as varchar "contains" filters like the other columns rather
    -- than numeric equality/range params.
    @QtyShippedFilter       NVARCHAR(50)    = NULL,
    @QtyConsumedFilter      NVARCHAR(50)    = NULL,
    @QtyReturnedFilter      NVARCHAR(50)    = NULL,
    @QtyDamagedLostFilter   NVARCHAR(50)    = NULL,
    @QtyRemainingFilter     NVARCHAR(50)    = NULL,
    @UnitCostFilter         NVARCHAR(50)    = NULL,
    @ExtendedCostFilter     NVARCHAR(50)    = NULL,
    @DateShipped            DATETIME        = NULL,
    @DateReturned           DATETIME        = NULL,
    @VendorId               BIGINT          = NULL,
    @RepairOrderId          BIGINT          = NULL,
    -- Standard params
    @IsDeleted              BIT             = 0,
    @MasterCompanyId        INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

    /* ────────────────────────────────────────────────────────────────────
       BasePieceParts — one row per RepairOrderPart (IsPiecePart = 1).
       All column-level and global filters are applied here so they work
       consistently for both the consumed rows and the pending row.
    ──────────────────────────────────────────────────────────────────── */
    ;WITH BasePieceParts AS
    (
        SELECT
            rop.RepairOrderPartRecordId,
            rop.RepairOrderId,

            ro.VendorName,
            ro.VendorCode,

            rop.PartNumber,
            rop.PartDescription,
            rop.Condition,
            ISNULL(rop.SerialNumber,    sl.SerialNumber)    AS SerialNumber,
            ISNULL(rop.StockLineNumber, sl.StockLineNumber) AS StocklineNumber,
            ISNULL(rop.ControlNumber,   sl.ControlNumber)   AS ControlNumber,
            rop.ControlId,
            rop.StockLineId,

            -- Total pieces actually shipped to the vendor. When Enforce Pick Ticket is
            -- off (0/NULL) on the Repair Order, the Pick/Shipping process is skipped
            -- entirely, so there are no RepairOrderShippingItem rows to sum; fall back
            -- to the ordered quantity (what QuantityBackOrdered is seeded from in that flow).
            CASE
                WHEN ro.IsEnforcePickTicket = 1
                THEN ISNULL((
                    SELECT SUM(ISNULL(rsi.QtyShipped, 0))
                    FROM   dbo.RepairOrderShippingItem rsi WITH (NOLOCK)
                    WHERE  rsi.RepairOrderPartId = rop.RepairOrderPartRecordId
                      AND  rsi.IsDeleted         = 0
                ), 0)
                ELSE ISNULL(rop.QuantityOrdered, 0)
            END                                              AS QtyShipped,

            rop.UnitCost,
            rop.ExtendedCost,

            (
                SELECT MIN(rsh.ShipDate)
                FROM   dbo.RepairOrderShipping rsh WITH (NOLOCK)
                WHERE  rsh.RepairOrderId = ro.RepairOrderId
            )                                               AS DateShipped,

            (
                SELECT MAX(rcw.ReceivedDate)
                FROM   dbo.ReceivingCustomerWork rcw WITH (NOLOCK)
                WHERE  rcw.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
                  AND  rcw.IsPiecePart = 1
                  AND  rcw.IsDeleted   = 0
            )                                               AS DateReturned,

            ro.RepairOrderNumber                            AS RONumber,

            -- Piece parts (customer-supplied) aren't created against a specific Work Order
            -- material requirement, so they rarely carry their own WorkOrderId/WorkOrderNo.
            -- Fall back to any sibling part on the same RO that does, then to '-'.
            COALESCE(
                rop.WorkOrderNo,
                wo.WorkOrderNum,
                (
                    SELECT TOP 1 COALESCE(sibling.WorkOrderNo, sibWo.WorkOrderNum)
                    FROM   dbo.RepairOrderPart sibling WITH (NOLOCK)
                    LEFT JOIN dbo.WorkOrder sibWo WITH (NOLOCK) ON sibWo.WorkOrderId = sibling.WorkOrderId
                    WHERE  sibling.RepairOrderId = rop.RepairOrderId
                      AND  sibling.IsDeleted     = 0
                      AND  sibling.WorkOrderId  IS NOT NULL
                ),
                '-'
            )                                                AS WONumber,

            rop.ManufacturerPN                              AS MPN,
            im.PartDescription                              AS MPNDescription,

            ISNULL(rop.QuantityBackOrdered, 0)              AS QuantityBackOrdered

        FROM  dbo.RepairOrderPart  rop WITH (NOLOCK)
        JOIN  dbo.RepairOrder       ro WITH (NOLOCK)  ON  ro.RepairOrderId   = rop.RepairOrderId
        LEFT JOIN dbo.StockLine     sl  WITH (NOLOCK) ON  sl.StockLineId     = rop.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
        LEFT JOIN dbo.WorkOrder     wo  WITH (NOLOCK) ON  wo.WorkOrderId     = rop.WorkOrderId
        LEFT JOIN dbo.ItemMaster    im  WITH (NOLOCK) ON  im.ItemMasterId    = rop.ItemMasterId

        WHERE rop.IsPiecePart       = 1
          AND rop.IsDeleted         = ISNULL(@IsDeleted, 0)
          AND rop.MasterCompanyId   = @MasterCompanyId
          AND ro.StatusId IN (
              SELECT ROStatusId FROM dbo.ROStatus WITH(NOLOCK)
              WHERE Description IN ('Fulfilling', 'Closed', 'Shipped')
          )

          AND (
              @GlobalFilter = ''
              OR ro.VendorName            LIKE '%' + @GlobalFilter + '%'
              OR ro.VendorCode            LIKE '%' + @GlobalFilter + '%'
              OR rop.PartNumber           LIKE '%' + @GlobalFilter + '%'
              OR rop.PartDescription      LIKE '%' + @GlobalFilter + '%'
              OR ro.RepairOrderNumber     LIKE '%' + @GlobalFilter + '%'
              OR rop.WorkOrderNo          LIKE '%' + @GlobalFilter + '%'
              OR wo.WorkOrderNum          LIKE '%' + @GlobalFilter + '%'
              OR rop.ManufacturerPN       LIKE '%' + @GlobalFilter + '%'
          )
          AND (@VendorName      IS NULL OR ro.VendorName        LIKE '%' + @VendorName      + '%')
          AND (@VendorCode      IS NULL OR ro.VendorCode        LIKE '%' + @VendorCode      + '%')
          AND (@PartNumber      IS NULL OR rop.PartNumber       LIKE '%' + @PartNumber      + '%')
          AND (@PartDescription IS NULL OR rop.PartDescription  LIKE '%' + @PartDescription + '%')
          AND (@RONumber        IS NULL OR ro.RepairOrderNumber  LIKE '%' + @RONumber        + '%')
          AND (@WONumber        IS NULL OR ISNULL(rop.WorkOrderNo, wo.WorkOrderNum)
                                              LIKE '%' + @WONumber + '%')
          AND (@Condition       IS NULL OR rop.Condition        LIKE '%' + @Condition       + '%')
          AND (@SerialNumber    IS NULL OR ISNULL(rop.SerialNumber, sl.SerialNumber)
                                              LIKE '%' + @SerialNumber    + '%')
          AND (@StocklineNumber IS NULL OR ISNULL(rop.StockLineNumber, sl.StockLineNumber)
                                              LIKE '%' + @StocklineNumber + '%')
          AND (@ControlNumber   IS NULL OR ISNULL(rop.ControlNumber, sl.ControlNumber)
                                              LIKE '%' + @ControlNumber   + '%')
          AND (@ControlId       IS NULL OR rop.ControlId        LIKE '%' + @ControlId       + '%')
          AND (@MPN             IS NULL OR rop.ManufacturerPN   LIKE '%' + @MPN             + '%')
          AND (@MPNDescription  IS NULL OR im.PartDescription   LIKE '%' + @MPNDescription  + '%')
          AND (@VendorId        IS NULL OR ro.VendorId          = @VendorId)
          AND (@RepairOrderId   IS NULL OR rop.RepairOrderId    = @RepairOrderId)
    ),

    /* ────────────────────────────────────────────────────────────────────
       AggregatedParts — one row per piece part with cumulative quantities
       summed from all PiecePartReconciliation events.
       QtyRemaining comes from QuantityBackOrdered (the live running balance
       decremented by USP_ReconcilePiecePart on every reconcile call).
    ──────────────────────────────────────────────────────────────────── */
    AggregatedParts AS
    (
        SELECT
            bp.RepairOrderPartRecordId,
            bp.RepairOrderId,
            bp.VendorName,
            bp.VendorCode,
            bp.PartNumber,
            bp.PartDescription,
            bp.Condition,
            bp.SerialNumber,
            bp.StockLineId,
            bp.StocklineNumber,
            bp.ControlNumber,
            bp.ControlId,
            bp.QtyShipped,
            ISNULL(SUM(ppr.QtyConsumed),    0) AS QtyConsumed,
            ISNULL(SUM(ppr.QtyReturned),    0) AS QtyReturned,
            ISNULL(SUM(ppr.QtyDamagedLost), 0) AS QtyDamagedLost,
            bp.QuantityBackOrdered             AS QtyRemaining,
            bp.UnitCost,
            bp.ExtendedCost,
            bp.DateShipped,
            bp.DateReturned,
            bp.RONumber,
            bp.WONumber,
            bp.MPN,
            bp.MPNDescription,
            CAST(NULL AS BIGINT)               AS PiecePartReconciliationId,
            CAST(NULL AS BIGINT)               AS ConsumedRepairOrderId,
            CAST(NULL AS NVARCHAR(100))        AS ConsumedByRONumber,
            CASE
                WHEN bp.QtyShipped = 0                      THEN 'No Qty'
                WHEN bp.QuantityBackOrdered = 0             THEN 'Fully Consumed'
                WHEN bp.QuantityBackOrdered < bp.QtyShipped THEN 'Partially Consumed'
                ELSE                                             'Pending'
            END                                AS ReconciliationStatus
        FROM  BasePieceParts bp
        LEFT JOIN dbo.PiecePartReconciliation ppr WITH (NOLOCK)
              ON  ppr.RepairOrderPartRecordId = bp.RepairOrderPartRecordId
              AND ppr.IsDeleted = 0
        GROUP BY
            bp.RepairOrderPartRecordId,
            bp.RepairOrderId,
            bp.VendorName,
            bp.VendorCode,
            bp.PartNumber,
            bp.PartDescription,
            bp.Condition,
            bp.SerialNumber,
            bp.StockLineId,
            bp.StocklineNumber,
            bp.ControlNumber,
            bp.ControlId,
            bp.QtyShipped,
            bp.QuantityBackOrdered,
            bp.UnitCost,
            bp.ExtendedCost,
            bp.DateShipped,
            bp.DateReturned,
            bp.RONumber,
            bp.WONumber,
            bp.MPN,
            bp.MPNDescription
    )

    SELECT
        RepairOrderPartRecordId,
        RepairOrderId,
        VendorName,
        VendorCode,
        PartNumber,
        PartDescription,
        Condition,
        SerialNumber,
        StockLineId,
        StocklineNumber,
        ControlNumber,
        ControlId,
        QtyShipped,
        QtyConsumed,
        QtyReturned,
        QtyDamagedLost,
        QtyRemaining,
        UnitCost,
        ExtendedCost,
        DateShipped,
        DateReturned,
        RONumber,
        WONumber,
        MPN,
        MPNDescription,
        PiecePartReconciliationId,
        ConsumedRepairOrderId,
        ConsumedByRONumber,
        ReconciliationStatus,
        COUNT(1) OVER ()                AS NumberOfItems
    FROM  AggregatedParts
    WHERE (@ReconciliationStatus IS NULL OR ReconciliationStatus LIKE '%' + @ReconciliationStatus + '%')
      AND (@QtyShippedFilter     IS NULL OR CAST(QtyShipped     AS VARCHAR(50)) LIKE '%' + @QtyShippedFilter     + '%')
      AND (@QtyConsumedFilter    IS NULL OR CAST(QtyConsumed    AS VARCHAR(50)) LIKE '%' + @QtyConsumedFilter    + '%')
      AND (@QtyReturnedFilter    IS NULL OR CAST(QtyReturned    AS VARCHAR(50)) LIKE '%' + @QtyReturnedFilter    + '%')
      AND (@QtyDamagedLostFilter IS NULL OR CAST(QtyDamagedLost AS VARCHAR(50)) LIKE '%' + @QtyDamagedLostFilter + '%')
      AND (@QtyRemainingFilter   IS NULL OR CAST(QtyRemaining   AS VARCHAR(50)) LIKE '%' + @QtyRemainingFilter   + '%')
      AND (@UnitCostFilter       IS NULL OR CAST(UnitCost       AS VARCHAR(50)) LIKE '%' + @UnitCostFilter       + '%')
      AND (@ExtendedCostFilter   IS NULL OR CAST(ExtendedCost   AS VARCHAR(50)) LIKE '%' + @ExtendedCostFilter   + '%')
      -- Date-only match (time component stripped), matching the convention used for
      -- other date columns (e.g. ExpirationDate/ReceivedDate in ProcStockList).
      AND (@DateShipped          IS NULL OR CAST(DateShipped  AS DATE) = CAST(@DateShipped  AS DATE))
      AND (@DateReturned         IS NULL OR CAST(DateReturned AS DATE) = CAST(@DateReturned AS DATE))
    ORDER BY
        -- User-selected sort column
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'VendorName'           THEN VendorName           END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'VendorName'           THEN VendorName           END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'VendorCode'           THEN VendorCode           END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'VendorCode'           THEN VendorCode           END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'PartNumber'           THEN PartNumber           END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'PartNumber'           THEN PartNumber           END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'PartDescription'      THEN PartDescription      END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'PartDescription'      THEN PartDescription      END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'Condition'            THEN Condition            END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'Condition'            THEN Condition            END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'SerialNumber'         THEN SerialNumber         END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'SerialNumber'         THEN SerialNumber         END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'StocklineNumber'      THEN StocklineNumber      END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'StocklineNumber'      THEN StocklineNumber      END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'ControlNumber'        THEN ControlNumber        END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'ControlNumber'        THEN ControlNumber        END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'ControlId'            THEN ControlId            END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'ControlId'            THEN ControlId            END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'MPN'                  THEN MPN                  END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'MPN'                  THEN MPN                  END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'MPNDescription'       THEN MPNDescription       END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'MPNDescription'       THEN MPNDescription       END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'RONumber'             THEN RONumber             END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'RONumber'             THEN RONumber             END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'WONumber'       THEN WONumber      END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'WONumber'       THEN WONumber      END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'ReconciliationStatus' THEN ReconciliationStatus END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'ReconciliationStatus' THEN ReconciliationStatus END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'DateShipped'          THEN DateShipped          END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'DateShipped'          THEN DateShipped          END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'DateReturned'         THEN DateReturned         END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'DateReturned'         THEN DateReturned         END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'QtyShipped'          THEN QtyShipped           END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'QtyShipped'          THEN QtyShipped           END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'QtyConsumed'         THEN QtyConsumed          END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'QtyConsumed'         THEN QtyConsumed          END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'QtyReturned'         THEN QtyReturned          END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'QtyReturned'         THEN QtyReturned          END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'QtyDamagedLost'      THEN QtyDamagedLost       END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'QtyDamagedLost'      THEN QtyDamagedLost       END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'QtyRemaining'        THEN QtyRemaining         END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'QtyRemaining'        THEN QtyRemaining         END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'UnitCost'            THEN UnitCost             END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'UnitCost'            THEN UnitCost             END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'ExtendedCost'        THEN ExtendedCost         END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'ExtendedCost'        THEN ExtendedCost         END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'RepairOrderPartRecordId' THEN RepairOrderPartRecordId END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'RepairOrderPartRecordId' THEN RepairOrderPartRecordId END DESC,
        -- Secondary stable sort
        RepairOrderPartRecordId DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH  NEXT @PageSize ROWS ONLY;
  
  END TRY  
  
  BEGIN CATCH  
     
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[USP_GetRoPiecePartForVendorReconcilationList]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS' 
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH  
END