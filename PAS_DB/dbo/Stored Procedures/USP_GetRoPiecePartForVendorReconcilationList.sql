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
    @ReconciliationStatus   NVARCHAR(50)    = NULL,
    -- Standard params
    @IsDeleted              BIT             = 0,
    @EmployeeId             BIGINT,
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

            -- Total pieces the customer sent in
            ISNULL((
                SELECT SUM(rcw.Quantity)
                FROM   dbo.ReceivingCustomerWork rcw WITH (NOLOCK)
                WHERE  rcw.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
                  AND  rcw.IsPiecePart = 1
                  AND  rcw.IsDeleted   = 0
            ), rop.QuantityOrdered)                         AS QtyShipped,

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
            ISNULL(rop.WorkOrderNo, wo.WorkOrderNum)        AS WONumber,

            rop.ManufacturerPN                              AS MPN,
            im.PartDescription                              AS MPNDescription,

            ISNULL(rop.QuantityBackOrdered, 0)              AS QuantityBackOrdered

        FROM  dbo.RepairOrderPart  rop WITH (NOLOCK)
        JOIN  dbo.RepairOrder       ro WITH (NOLOCK)  ON  ro.RepairOrderId   = rop.RepairOrderId
        LEFT JOIN dbo.StockLine     sl  WITH (NOLOCK) ON  sl.StockLineId     = rop.StockLineId
        LEFT JOIN dbo.WorkOrder     wo  WITH (NOLOCK) ON  wo.WorkOrderId     = rop.WorkOrderId
        LEFT JOIN dbo.ItemMaster    im  WITH (NOLOCK) ON  im.ItemMasterId    = rop.ItemMasterId

        WHERE rop.IsPiecePart       = 1
          AND rop.IsDeleted         = ISNULL(@IsDeleted, 0)
          AND rop.MasterCompanyId   = @MasterCompanyId

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
    WHERE (
        @ReconciliationStatus IS NULL
        OR ReconciliationStatus = @ReconciliationStatus
        OR (@ReconciliationStatus = 'Consumed' AND ReconciliationStatus IN ('Fully Consumed', 'Partially Consumed'))
    )
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
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'RONumber'             THEN RONumber             END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'RONumber'             THEN RONumber             END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'WONumber'             THEN WONumber             END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'WONumber'             THEN WONumber             END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'ReconciliationStatus' THEN ReconciliationStatus END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'ReconciliationStatus' THEN ReconciliationStatus END DESC,
        CASE WHEN @SortOrder =  1 AND @SortColumn = 'DateShipped'          THEN DateShipped          END ASC,
        CASE WHEN @SortOrder = -1 AND @SortColumn = 'DateShipped'          THEN DateShipped          END DESC,
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