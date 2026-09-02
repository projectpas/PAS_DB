/*********************
 ** File:   [dbo].[usp_Get_WorkOrderSettlementGridHistory]
 ** Author:   AYUSHI PATEL
 ** Description: Grid-mirroring history for the Work Order Settlement tab (PN-14788, v2).
 **              Reads dbo.WorkOrderSettlementFieldHistory (fed by trg_History_WorkOrderSettlementDetails
 **              and trg_History_WorkOrderPartNumber) and groups near-simultaneous field changes (the
 **              "Update" button batches up to 7 columns in one click) into one row per real save event,
 **              per WorkOrderPartNoId, via a gaps-and-islands grouping on ChangedAt - matching the exact
 **              column layout of the live Settlement grid so the Angular component can render each event
 **              as a "diff row" directly under the changed PN's row. Only columns that actually changed in
 **              that event are populated; everything else comes back NULL so the FE shows a blank cell.
 **              Scoped by @WorkOrderId (not a single part) so the whole grid's history loads in one call.
 **
 ** Change History
 ** S NO    Date          Author          Change Description
 ** --      --------      -------------   --------------------------------
 **  1      02-SEP-2026   Ayushi Patel    Created (PN-14788 v2 - grid-mirroring settlement history)
 **
 ** exec usp_Get_WorkOrderSettlementGridHistory @WorkOrderId=10662
**********************/
CREATE PROCEDURE [dbo].[usp_Get_WorkOrderSettlementGridHistory]
    @WorkOrderId BIGINT,
    @SortDir     NVARCHAR(4) = N'DESC'
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        IF @SortDir NOT IN (N'ASC', N'DESC') SET @SortDir = N'DESC';

        ;WITH ordered AS (
            SELECT
                h.*,
                LAG(h.ChangedAt) OVER (PARTITION BY h.WorkOrderPartNoId ORDER BY h.ChangedAt, h.WorkOrderSettlementFieldHistoryId) AS PrevChangedAt
            FROM dbo.WorkOrderSettlementFieldHistory h WITH (NOLOCK)
            INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wop.ID = h.WorkOrderPartNoId
            WHERE wop.WorkOrderId = @WorkOrderId
        ),
        grouped AS (
            SELECT
                *,
                CASE WHEN PrevChangedAt IS NULL OR DATEDIFF(SECOND, PrevChangedAt, ChangedAt) > 5 THEN 1 ELSE 0 END AS IsNewGroup
            FROM ordered
        ),
        withGroupId AS (
            SELECT
                *,
                SUM(IsNewGroup) OVER (PARTITION BY WorkOrderPartNoId ORDER BY ChangedAt, WorkOrderSettlementFieldHistoryId ROWS UNBOUNDED PRECEDING) AS GroupId
            FROM grouped
        )
        SELECT
            WorkOrderPartNoId,
            MAX(ChangedAt) AS EventDate,
            MAX(ChangedBy) AS ChangedBy,
            MAX(CASE WHEN ColumnKey = N'materialIssued' THEN NewValue END) AS materialIssued,
            MAX(CASE WHEN ColumnKey = N'materialIssued' THEN OldValue END) AS materialIssuedOld,
            MAX(CASE WHEN ColumnKey = N'laborConfirmed'  THEN NewValue END) AS laborConfirmed,
            MAX(CASE WHEN ColumnKey = N'laborConfirmed'  THEN OldValue END) AS laborConfirmedOld,
            MAX(CASE WHEN ColumnKey = N'toolsChecked'    THEN NewValue END) AS toolsChecked,
            MAX(CASE WHEN ColumnKey = N'toolsChecked'    THEN OldValue END) AS toolsCheckedOld,
            MAX(CASE WHEN ColumnKey = N'releaseCerts'    THEN NewValue END) AS releaseCerts,
            MAX(CASE WHEN ColumnKey = N'releaseCerts'    THEN OldValue END) AS releaseCertsOld,
            MAX(CASE WHEN ColumnKey = N'mpnLocation'     THEN NewValue END) AS mpnLocation,
            MAX(CASE WHEN ColumnKey = N'mpnLocation'     THEN OldValue END) AS mpnLocationOld,
            MAX(CASE WHEN ColumnKey = N'movedToFG'       THEN NewValue END) AS movedToFG,
            MAX(CASE WHEN ColumnKey = N'movedToFG'       THEN OldValue END) AS movedToFGOld,
            MAX(CASE WHEN ColumnKey = N'unitShipped'     THEN NewValue END) AS unitShipped,
            MAX(CASE WHEN ColumnKey = N'unitShipped'     THEN OldValue END) AS unitShippedOld,
            MAX(CASE WHEN ColumnKey = N'woInvoiced'      THEN NewValue END) AS woInvoiced,
            MAX(CASE WHEN ColumnKey = N'woInvoiced'      THEN OldValue END) AS woInvoicedOld,
            MAX(CASE WHEN ColumnKey = N'closeWO'         THEN NewValue END) AS closeWO,
            MAX(CASE WHEN ColumnKey = N'closeWO'         THEN OldValue END) AS closeWOOld,
            MAX(CASE WHEN ColumnKey = N'reOpenFinishGood' THEN NewValue END) AS reOpenFinishGood,
            MAX(CASE WHEN ColumnKey = N'reOpenWO'        THEN NewValue END) AS reOpenWO,
            MAX(CASE WHEN ColumnKey = N'disposition'     THEN NewValue END) AS disposition,
            MAX(CASE WHEN ColumnKey = N'disposition'     THEN OldValue END) AS dispositionOld,
            MAX(CASE WHEN ColumnKey = N'revisedPart'     THEN NewValue END) AS revisedPart,
            MAX(CASE WHEN ColumnKey = N'revisedPart'     THEN OldValue END) AS revisedPartOld,
            MAX(CASE WHEN ColumnKey = N'revisedSerialNumber' THEN NewValue END) AS revisedSerialNumber,
            MAX(CASE WHEN ColumnKey = N'revisedSerialNumber' THEN OldValue END) AS revisedSerialNumberOld
        FROM withGroupId
        GROUP BY WorkOrderPartNoId, GroupId
        ORDER BY
            WorkOrderPartNoId,
            CASE WHEN @SortDir = N'ASC'  THEN MAX(ChangedAt) END ASC,
            CASE WHEN @SortDir = N'DESC' THEN MAX(ChangedAt) END DESC;

    END TRY
    BEGIN CATCH

    DECLARE @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments VARCHAR(150) = '[usp_Get_WorkOrderSettlementGridHistory]',
            @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, 0) AS VARCHAR(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@SortDir, '') AS VARCHAR(100)),
            @ApplicationName VARCHAR(100) = 'PAS'

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
