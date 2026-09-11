/*********************
 ** File:   [dbo].[usp_Get_WorkorderPickTicketCommonHistory]
 ** Author:   Ayushi Patel
 ** Description:
 ** Purpose: Backs the "Pick Ticket History" icon shown before "Print Multiple PickTicket" on the (non-MPN)
 **          Pick Ticket tab (app-work-order-pickticket, opened from the Material List tab), and the merged
 **          delete-confirmation-plus-history popup. Returns one row per change-event (Added / Confirmed /
 **          Updated / Deleted) across every WorkorderPickTicket row under a given Work Order (every
 **          material/kit line's tickets, not just one), newest first, with a ChangedFields list driving
 **          red-highlighting on the client. Reads from dbo.WorkorderPickTicketAudit
 **          (Trg_WorkorderPickTicketAudit) - Action/ChangedFields are computed here at read time via
 **          LAG/CHECKSUM, comparing each snapshot to the previous one for the same PickTicketId, and
 **          consecutive identical snapshots are skipped (avoids duplicate entries). Unlike Pick MPN's
 **          WOPickTicket, this table has a real hard DELETE (WorkOrderRepository.DeleteWOMaterialsPickTicket).
 **          No new column was needed to represent that: IsDeleted already exists and is never set to 1
 **          anywhere else in this table's lifecycle (no soft-delete path exists here), so the trigger's
 **          DELETE branch writes IsDeleted = 1 explicitly on that final snapshot - Action = 'Deleted' below
 **          is simply IsDeleted = 1 (there is no other way to detect the event since the row is physically
 **          gone). Display
 **          fields (PN Num/Description/Manufacturer, Serial/Stock Line/Control/Id Number, Picked By/
 **          Confirmed By names) are not stored on WorkorderPickTicket itself, so they are resolved via JOIN
 **          here at read time - same joins GetWOMaterialsPickTicketApproveList/GetWOMaterialsPickTicketChildList
 **          already use for the live grid - rather than snapshotted. WorkorderPickTicketAudit already
 **          mirrors WorkorderId/WorkOrderMaterialsId/IsKitType/StocklineId from the base table on every row,
 **          so no JOIN-back to the live table is needed for scoping/kit-branching. One Work Order can have
 **          multiple MPN lines ("Multiple MPN" header), each its own WorkFlowWorkOrderId, and the live Pick
 **          Ticket grid (GetWOMaterialsPickTicketApproveList) scopes to just the one currently selected via
 **          wom.WorkFlowWorkOrderId = @workflowWorkOrderId - so this proc resolves each audit row's own
 **          WorkFlowWorkOrderId via the same WorkOrderMaterials/WorkOrderMaterialsKit join already needed for
 **          PN/Manufacturer, and filters by @WorkFlowWorkOrderId too, so history only ever shows the
 **          currently-selected MPN's tickets, matching the live grid.
 **          NOTE: results are ordered by PickTicketAuditId (the audit table's own IDENTITY column), not by
 **          EventDate/UpdatedDate, for the same reason already found and fixed on
 **          usp_Get_WOPickTicketCommonHistory: sp_savePickTicketItemInterface_WO (shared by both MPN and
 **          non-MPN pick tickets) populates UpdatedDate inconsistently - INSERT uses GETUTCDATE(), a
 **          Qty-only UPDATE uses GETDATE() (local server time, not UTC), and neither the auto-confirm-at-
 **          create nor the manual Confirm UPDATE touch UpdatedDate at all - so it cannot be trusted to
 **          reflect true chronological order. PickTicketAuditId always increases in true write order
 **          regardless of what date value the app supplied, so it's used as the sort key instead;
 **          EventDate/UpdatedDate are still returned for display only. PN-14788.
 **
 ** PARAMETERS:
 **   @WorkOrderId         - the Work Order whose Pick Ticket history is requested
 **   @WorkFlowWorkOrderId - the currently-selected MPN line (matches GetWOMaterialsPickTicketApproveList's
 **                          own @workflowWorkOrderId scope) - history only covers this MPN's material/kit lines
 **   @EmployeeId          - used to convert dates to the requesting employee's timezone
 **   @SortDir             - ASC | DESC (by PickTicketAuditId, i.e. true write order), defaults to DESC (most recent first)
 **
 ** RETURN VALUE: one row per snapshot/action event - see column list in the final SELECT.
 **
 **********************
 ** Change History
 **********************
 ** S NO   Date          Author          Change Description
 ** --     --------      -------------   --------------------------------
    1      10-SEP-2026   Ayushi Patel    Created (PN-14788)

exec usp_Get_WorkorderPickTicketCommonHistory @WorkOrderId=10688, @WorkFlowWorkOrderId=1074, @EmployeeId=2
**********************/

CREATE PROCEDURE [dbo].[usp_Get_WorkorderPickTicketCommonHistory]
    @WorkOrderId         BIGINT,
    @WorkFlowWorkOrderId BIGINT,
    @EmployeeId          BIGINT      = NULL,
    @SortDir             NVARCHAR(4) = N'DESC'
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
                CASE WHEN ISNULL(IMT.PartNumber, '') = '' THEN NULL ELSE IMT.PartNumber END AS PartNumber,
                IMT.PartDescription,
                IMT.ManufacturerName,
                SL.SerialNumber,
                SL.StockLineNumber,
                SL.ControlNumber,
                SL.IdNumber,
                WPA.QtyToShip,
                CONCAT(EMP.FirstName, ' ', EMP.LastName) AS PickedBy,
                CONCAT(EMPC.FirstName, ' ', EMPC.LastName) AS ConfirmedBy,
                WPA.ConfirmedDate,
                WPA.IsConfirmed,
                WPA.IsDeleted
            FROM [dbo].[WorkorderPickTicketAudit] WPA WITH (NOLOCK)
            LEFT JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkOrderId = WPA.WorkorderId AND WOM.WorkOrderMaterialsId = WPA.WorkOrderMaterialsId AND ISNULL(WPA.IsKitType, 0) = 0
            LEFT JOIN dbo.WorkOrderMaterialsKit WOMK WITH (NOLOCK) ON WOMK.WorkOrderId = WPA.WorkorderId AND WOMK.WorkOrderMaterialsKitId = WPA.WorkOrderMaterialsId AND ISNULL(WPA.IsKitType, 0) = 1
            LEFT JOIN dbo.ItemMaster IMT WITH (NOLOCK) ON IMT.ItemMasterId = COALESCE(WOM.ItemMasterId, WOMK.ItemMasterId)
            LEFT JOIN dbo.StockLine SL WITH (NOLOCK) ON SL.StockLineId = WPA.StocklineId AND ISNULL(SL.IsNonStock, 0) = 0
            LEFT JOIN dbo.Employee EMP WITH (NOLOCK) ON EMP.EmployeeId = WPA.PickedById
            LEFT JOIN dbo.Employee EMPC WITH (NOLOCK) ON EMPC.EmployeeId = WPA.ConfirmedById
            WHERE WPA.WorkorderId = @WorkOrderId
              AND COALESCE(WOM.WorkFlowWorkOrderId, WOMK.WorkFlowWorkOrderId) = @WorkFlowWorkOrderId
        ),
        Lagged AS
        (
            SELECT
                *,
                CHECKSUM(QtyToShip, PickedBy, ConfirmedBy, ConfirmedDate, IsConfirmed, IsDeleted) AS RowHash,
                LAG(CHECKSUM(QtyToShip, PickedBy, ConfirmedBy, ConfirmedDate, IsConfirmed, IsDeleted))
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
                PickTicketId, PickTicketNumber, PartNumber, PartDescription, ManufacturerName, SerialNumber, StockLineNumber, ControlNumber, IdNumber,
                QtyToShip, PickedBy, ConfirmedBy, ConfirmedDate, IsConfirmed,
                CASE WHEN PrevHash IS NULL THEN N'Added'
                     WHEN IsDeleted = 1 THEN N'Deleted'
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
            PickTicketId, PickTicketNumber, PartNumber, PartDescription, ManufacturerName, SerialNumber, StockLineNumber, ControlNumber, IdNumber,
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
            @AdhocComments VARCHAR(150) = '[usp_Get_WorkorderPickTicketCommonHistory]',
            @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, 0) AS VARCHAR(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@WorkFlowWorkOrderId, 0) AS VARCHAR(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@EmployeeId, 0) AS VARCHAR(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@SortDir, '') AS VARCHAR(100)),
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
