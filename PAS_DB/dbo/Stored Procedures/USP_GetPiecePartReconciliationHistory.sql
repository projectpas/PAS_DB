/*************************************************************
 ** File:   [USP_GetPiecePartReconciliationHistory]
 ** Author:   Abhishek Jirawla
 ** Description: Returns the full reconciliation event history
 **              for a single piece part line (RepairOrderPartRecordId).
 ** Purpose:
 ** Date:   22/06/2026

 ** PARAMETERS:
 **   @RepairOrderPartRecordId  BIGINT  -- the piece part RO line
 **   @MasterCompanyId          INT

 ** RETURN VALUE:
 **   One row per PiecePartReconciliation event for the given line.

 **************************************************************
  ** Change History
 **************************************************************
  ** S NO   Date            Author				Change Description
  ** --   --------			-------				--------------------------------
     1    22/06/2026		Abhishek Jirawla	Created
 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetPiecePartReconciliationHistory]
    @RepairOrderPartRecordId    BIGINT,
    @MasterCompanyId            INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        /* Compute running remaining balance ordered oldest-first, then display newest-first. */
        ;WITH RankedHistory AS
        (
            SELECT
                ppr.PiecePartReconciliationId,
                ppr.RepairOrderPartRecordId,
                ppr.SourceRepairOrderId,
                srcRO.RepairOrderNumber         AS SourceRONumber,
                ppr.ConsumedRepairOrderId,
                conRO.RepairOrderNumber         AS ConsumedRONumber,
                rop.PartNumber,
                rop.PartDescription,
                rop.Condition,
                srcRO.VendorName,
                srcRO.VendorCode,
                ppr.QtyShipped,
                ppr.QtyConsumed,
                ppr.QtyReturned,
                ppr.QtyDamagedLost,
                -- Running remaining = QtyShipped minus all qty consumed/returned/damaged up to this row
                ppr.QtyShipped
                    - SUM(ppr.QtyConsumed + ppr.QtyReturned + ppr.QtyDamagedLost)
                      OVER (
                          PARTITION BY ppr.RepairOrderPartRecordId
                          ORDER BY ppr.CreatedDate ASC, ppr.PiecePartReconciliationId ASC
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                      )                         AS QtyRemaining,
                ppr.ReconciliationStatus,
                ppr.Memo,
                ppr.CreatedBy,
                ppr.CreatedDate,
                ppr.ParentRepairOrderPartId,
                CASE
                    WHEN parentROP.RepairOrderPartRecordId IS NULL THEN NULL
                    WHEN ISNULL(parentROP.SerialNumber, '') = ''   THEN parentROP.PartNumber
                    ELSE parentROP.PartNumber + ' / SN: ' + parentROP.SerialNumber
                END                                 AS ParentPartNumber
            FROM  dbo.PiecePartReconciliation  ppr  WITH (NOLOCK)
            LEFT JOIN dbo.RepairOrderPart      rop  WITH (NOLOCK)
                  ON  rop.RepairOrderPartRecordId = ppr.RepairOrderPartRecordId
            LEFT JOIN dbo.RepairOrder          srcRO WITH (NOLOCK)
                  ON  srcRO.RepairOrderId         = ppr.SourceRepairOrderId
            LEFT JOIN dbo.RepairOrder          conRO WITH (NOLOCK)
                  ON  conRO.RepairOrderId         = ppr.ConsumedRepairOrderId
            LEFT JOIN dbo.RepairOrderPart      parentROP WITH (NOLOCK)
                  ON  parentROP.RepairOrderPartRecordId = ppr.ParentRepairOrderPartId
            WHERE ppr.RepairOrderPartRecordId = @RepairOrderPartRecordId
              AND ppr.MasterCompanyId         = @MasterCompanyId
              AND ISNULL(ppr.IsDeleted, 0)    = 0
              -- Defense-in-depth: re-check the tenant boundary against the parent RO/part's own
              -- MasterCompanyId, not just ppr.MasterCompanyId. NULL-safe (IS NULL) so history for
              -- a hard-deleted RepairOrderPart/RepairOrder (rop/srcRO are LEFT JOINed) stays visible.
              AND (rop.MasterCompanyId IS NULL OR rop.MasterCompanyId = @MasterCompanyId)
              AND (srcRO.MasterCompanyId IS NULL OR srcRO.MasterCompanyId = @MasterCompanyId)
        )
        SELECT
            PiecePartReconciliationId,
            RepairOrderPartRecordId,
            SourceRepairOrderId,
            SourceRONumber,
            ConsumedRepairOrderId,
            ConsumedRONumber,
            PartNumber,
            PartDescription,
            Condition,
            VendorName,
            VendorCode,
            QtyShipped,
            QtyConsumed,
            QtyReturned,
            QtyDamagedLost,
            QtyRemaining,
            ReconciliationStatus,
            Memo,
            CreatedBy,
            CreatedDate,
            ParentRepairOrderPartId,
            ParentPartNumber
        FROM  RankedHistory
        ORDER BY CreatedDate DESC, PiecePartReconciliationId DESC;

    END TRY
    BEGIN CATCH

        DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,
            @AdhocComments varchar(150) = '[USP_GetPiecePartReconciliationHistory]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@RepairOrderPartRecordId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'

        EXEC Splogexception @DatabaseName = @DatabaseName,
                            @AdhocComments = @AdhocComments,
                            @ProcedureParameters = @ProcedureParameters,
                            @ApplicationName = @ApplicationName,
                            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

        RETURN (1);
    END CATCH

END