/*********************
 ** File:   [dbo].[usp_Get_WOPickTicketCommonHistory]
 ** Author:   Ayushi Patel
 ** Description:
 ** Purpose: Backs the "Pick MPN History" icon shown before "Create Multiple Pick Tickets" on the Pick MPN
 **          tab (app-work-order-part-pickticket) of Work Order Edit. Returns one row per change-event
 **          (Added / Confirmed / Updated) across every WOPickTicket row under a given Work Order (every
 **          PN row's pick tickets, not just one), newest first, with a ChangedFields list driving
 **          red-highlighting on the client. Reads from dbo.WOPickTicketAudit (Trg_WOPickTicketAudit, a
 **          pre-existing full-mirror trigger) - Action/ChangedFields are computed here at read time via
 **          LAG/CHECKSUM, comparing each snapshot to the previous one for the same PickTicketId, and
 **          consecutive identical snapshots are skipped (avoids duplicate entries). There is no delete
 **          path for this table (Create/Confirm only ever INSERT or UPDATE via
 **          sp_savePickTicketItemInterface_WO), so Action is Added/Updated, plus a dedicated "Confirmed"
 **          label when IsConfirmed transitions 0->1 (Create auto-confirms in the same call when
 **          WorkOrder.EnforceMpnPickTicketConfirmation = 0, which correctly yields Added then Confirmed as
 **          two distinct rows). Display fields (PN Num/Description, Serial Number, Stock Line Number,
 **          Control/Id Number, Picked By/Confirmed By names) are not stored on WOPickTicket itself, so they
 **          are resolved via JOIN here at read time - same joins sp_GetPickTicketApproveList_MainPart /
 **          sp_GetPickTicketChildList_MainPart already use for the live grid - rather than snapshotted.
 **          WOPickTicketAudit already mirrors WorkorderId/WorkFlowWorkOrderId/OrderPartId from the base
 **          table on every row, so no new columns or JOIN-back to the live table is needed for scoping.
 **          NOTE: results are ordered by PickTicketAuditId (the audit table's own IDENTITY column), not by
 **          EventDate/UpdatedDate. sp_savePickTicketItemInterface_WO populates UpdatedDate inconsistently
 **          for this table - INSERT sets it via GETUTCDATE(), a Qty-only UPDATE sets it via GETDATE()
 **          (local server time, not UTC), and both the auto-confirm-at-create and the manual Confirm UPDATE
 **          don't touch UpdatedDate at all (so a Confirmed snapshot's UpdatedDate is just whatever it was
 **          before that UPDATE ran) - so UpdatedDate cannot be trusted to reflect true chronological order
 **          across action types. PickTicketAuditId is a plain IDENTITY column that always increases in true
 **          write order regardless of what date value the app supplied, so it's used as the sort key
 **          instead; EventDate/UpdatedDate are still returned for display only. PN-14788.
 **
 ** PARAMETERS:
 **   @WorkOrderId - the Work Order whose Pick MPN history is requested (covers every PN row's tickets)
 **   @EmployeeId  - used to convert dates to the requesting employee's timezone
 **   @SortDir     - ASC | DESC (by PickTicketAuditId, i.e. true write order), defaults to DESC (most recent first)
 **
 ** RETURN VALUE: one row per snapshot/action event - see column list in the final SELECT.
 **
 **********************
 ** Change History
 **********************
 ** S NO   Date          Author          Change Description
 ** --     --------      -------------   --------------------------------
    1      10-SEP-2026   Ayushi Patel    Created (PN-14788)

exec usp_Get_WOPickTicketCommonHistory @WorkOrderId=20751, @EmployeeId=2
**********************/

CREATE PROCEDURE [dbo].[usp_Get_WOPickTicketCommonHistory]
    @WorkOrderId BIGINT,
    @EmployeeId  BIGINT      = NULL,
    @SortDir     NVARCHAR(4) = N'DESC'
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        IF @SortDir NOT IN (N'ASC', N'DESC') SET @SortDir = N'DESC';

        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
        SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
        FROM dbo.Employee E WITH (NOLOCK)
        LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
        LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
        LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE E.EmployeeId = @EmployeeId;

        ;WITH
        Raw AS
        (
            SELECT
                WPA.PickTicketAuditId,
                WPA.PickTicketId,
                WPA.UpdatedDate AS RawDate,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN WPA.UpdatedDate
                     ELSE CAST(dbo.ConvertUTCtoLocal(WPA.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                WPA.UpdatedBy AS ChangedBy,
                WPA.CreatedBy AS CreatedByRaw,
                WPA.PickTicketNumber,
                CASE WHEN ISNULL(WOP.RevisedItemmasterid, 0) > 0 THEN WOP.RevisedPartNumber ELSE IMT.PartNumber END AS PartNumber,
                CASE WHEN ISNULL(WOP.RevisedItemmasterid, 0) > 0 THEN WOP.RevisedPartDescription ELSE IMT.PartDescription END AS PartDescription,
                CASE WHEN ISNULL(WOP.RevisedSerialNumber, '') = '' THEN SL.SerialNumber ELSE WOP.RevisedSerialNumber END AS SerialNumber,
                SL.StockLineNumber,
                SL.ControlNumber,
                SL.IdNumber,
                WPA.QtyToShip,
                CONCAT(EMP.FirstName, ' ', EMP.LastName) AS PickedBy,
                CONCAT(EMPC.FirstName, ' ', EMPC.LastName) AS ConfirmedBy,
                WPA.ConfirmedDate,
                WPA.IsConfirmed
            FROM [dbo].[WOPickTicketAudit] WPA WITH (NOLOCK)
            LEFT JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.ID = WPA.WorkFlowWorkOrderId
            LEFT JOIN dbo.ItemMaster IMT WITH (NOLOCK) ON IMT.ItemMasterId = WOP.ItemMasterId
            LEFT JOIN dbo.StockLine SL WITH (NOLOCK) ON SL.StockLineId = WOP.StocklineId AND ISNULL(SL.IsNonStock, 0) = 0
            LEFT JOIN dbo.Employee EMP WITH (NOLOCK) ON EMP.EmployeeId = WPA.PickedById
            LEFT JOIN dbo.Employee EMPC WITH (NOLOCK) ON EMPC.EmployeeId = WPA.ConfirmedById
            WHERE WPA.WorkorderId = @WorkOrderId
        ),
        Lagged AS
        (
            SELECT
                *,
                CHECKSUM(QtyToShip, PickedBy, ConfirmedBy, ConfirmedDate, IsConfirmed) AS RowHash,
                LAG(CHECKSUM(QtyToShip, PickedBy, ConfirmedBy, ConfirmedDate, IsConfirmed))
                    OVER (PARTITION BY PickTicketId ORDER BY PickTicketAuditId) AS PrevHash,
                LAG(QtyToShip)     OVER (PARTITION BY PickTicketId ORDER BY PickTicketAuditId) AS PrevQtyToShip,
                LAG(PickedBy)      OVER (PARTITION BY PickTicketId ORDER BY PickTicketAuditId) AS PrevPickedBy,
                LAG(ConfirmedBy)   OVER (PARTITION BY PickTicketId ORDER BY PickTicketAuditId) AS PrevConfirmedBy,
                LAG(ConfirmedDate) OVER (PARTITION BY PickTicketId ORDER BY PickTicketAuditId) AS PrevConfirmedDate,
                LAG(IsConfirmed)   OVER (PARTITION BY PickTicketId ORDER BY PickTicketAuditId) AS PrevIsConfirmed
            FROM Raw
        ),
        Rows AS
        (
            SELECT
                PickTicketNumber, PartNumber, PartDescription, SerialNumber, StockLineNumber, ControlNumber, IdNumber,
                QtyToShip, PickedBy, ConfirmedBy, ConfirmedDate, IsConfirmed,
                CASE WHEN PrevHash IS NULL THEN N'Added'
                     WHEN IsConfirmed = 1 AND ISNULL(PrevIsConfirmed, 0) = 0 THEN N'Confirmed'
                     ELSE N'Updated' END AS Action,
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(QtyToShip, -1) <> ISNULL(PrevQtyToShip, -1) THEN ',qtyToShip' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(PickedBy, '') <> ISNULL(PrevPickedBy, '') THEN ',pickedBy' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(ConfirmedBy, '') <> ISNULL(PrevConfirmedBy, '') THEN ',confirmedBy' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CONVERT(VARCHAR(30), ConfirmedDate, 126), '') <> ISNULL(CONVERT(VARCHAR(30), PrevConfirmedDate, 126), '') THEN ',confirmedDate' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsConfirmed AS INT), -1) <> ISNULL(CAST(PrevIsConfirmed AS INT), -1) THEN ',isConfirmed' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                EventDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                PickTicketAuditId AS RowSeq,
                RowHash,
                PrevHash
            FROM Lagged
        )
        SELECT
            PickTicketNumber, PartNumber, PartDescription, SerialNumber, StockLineNumber, ControlNumber, IdNumber,
            QtyToShip, PickedBy, ConfirmedBy, ConfirmedDate, IsConfirmed,
            Action, ChangedFields, EventDate, ChangedBy
        FROM Rows
        WHERE PrevHash IS NULL OR RowHash <> PrevHash
        ORDER BY
            CASE WHEN @SortDir = N'ASC'  THEN RowSeq END ASC,
            CASE WHEN @SortDir = N'DESC' THEN RowSeq END DESC;

    END TRY
    BEGIN CATCH

    DECLARE @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments VARCHAR(150) = '[usp_Get_WOPickTicketCommonHistory]',
            @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, 0) AS VARCHAR(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, 0) AS VARCHAR(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@SortDir, '') AS VARCHAR(100)),
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
