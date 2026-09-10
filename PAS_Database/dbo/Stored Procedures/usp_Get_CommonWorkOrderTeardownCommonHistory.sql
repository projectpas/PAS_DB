/*********************
 ** File:   [dbo].[usp_Get_CommonWorkOrderTeardownCommonHistory]
 ** Author:   Ayushi Patel
 ** Description:
 ** Purpose: Backs the "Teardown History" icon shown top-right of the Open All/Close All/View row on the
 **          Teardown Entry tab (app-common-component-teardown) of Work Order Edit. Returns one row per
 **          change-event (Added / Updated) across every CommonWorkOrderTearDown section row under a given
 **          Work Order (or Sub Work Order), newest first, with a ChangedFields list driving red-highlighting
 **          on the client. Reads from dbo.CommonWorkOrderTearDownAudit (Trg_CommonWorkOrderTearDownAudit) -
 **          Action/ChangedFields are computed here at read time via LAG/CHECKSUM, comparing each snapshot to
 **          the previous one for the same CommonWorkOrderTearDownId, and consecutive identical snapshots are
 **          skipped (avoids duplicate entries). There is no per-row delete/restore path for a teardown
 **          section today, so Action is only ever Added/Updated. Scoping columns (WorkOrderId,
 **          WorkFlowWorkOrderId, SubWorkOrderId, SubWOPartNoId, IsSubWorkOrder) are resolved via JOIN back
 **          to the live dbo.CommonWorkOrderTearDown row rather than snapshotted onto the audit table, since
 **          they never change after a row is first created. IsDocument is likewise not snapshotted - the
 **          Angular "Documents" checkbox for a section only gates the app-common-documents widget
 **          (dbo.CommonDocumentDetails/CommonDocumentDetailsAudit, keyed by ModuleId=AttachmentModule for
 **          this section's CommonTeardownType.DocumentModuleName + ReferenceId=WorkFlowWorkOrderId) - it is
 **          derived per snapshot via OUTER APPLY against CommonDocumentDetailsAudit as-of that snapshot's
 **          UpdatedDate, which is both more accurate (the checkbox itself can drift from whether a file was
 **          actually uploaded) and avoids adding a column purely to duplicate what's already recorded there.
 **          PN-14788.
 **
 ** PARAMETERS:
 **   @WorkOrderId          - Work Order id (or Sub Work Order id when @IsSubWorkOrder = 1), matching
 **                           USP_GetWorkOrderTeardownDetails's own parameter contract
 **   @WorkFlowWorkOrderId  - work-flow work order id (WO-level scope only)
 **   @IsSubWorkOrder       - 0 = Work Order scope, 1 = Sub Work Order scope
 **   @SubWOPartNoId        - Sub Work Order part number id (Sub-WO scope only)
 **   @EmployeeId           - used to convert dates to the requesting employee's timezone
 **   @SortDir              - ASC | DESC (by EventDate), defaults to DESC (most recent first)
 **
 ** RETURN VALUE: one row per snapshot/action event - see column list in the final SELECT.
 **
 **********************
 ** Change History
 **********************
 ** S NO   Date          Author          Change Description
 ** --     --------      -------------   --------------------------------
    1      09-SEP-2026   Ayushi Patel    Created (PN-14788)

exec usp_Get_CommonWorkOrderTeardownCommonHistory @WorkOrderId=8808, @WorkFlowWorkOrderId=8547, @IsSubWorkOrder=0, @SubWOPartNoId=0, @EmployeeId=2
**********************/

CREATE PROCEDURE [dbo].[usp_Get_CommonWorkOrderTeardownCommonHistory]
    @WorkOrderId         BIGINT,
    @WorkFlowWorkOrderId BIGINT,
    @IsSubWorkOrder      BIT         = 0,
    @SubWOPartNoId       BIGINT      = 0,
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
                CWA.CommonWorkOrderTearDownAuditId,
                CWA.CommonWorkOrderTearDownId,
                CWA.UpdatedDate AS RawDate,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN CWA.UpdatedDate
                     ELSE CAST(dbo.ConvertUTCtoLocal(CWA.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                CWA.UpdatedBy AS ChangedBy,
                CWA.CreatedBy AS CreatedByRaw,
                CWA.CommonTeardownType AS TearDownType,
                CWA.ReasonName,
                CWA.TechnicalName AS Technician,
                CWA.TechnicianDate,
                CWA.InspectorName AS Inspector,
                CWA.InspectorDate,
                CWA.Memo,
                CASE WHEN DocAsOf.HasDocument = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsDocument
            FROM [dbo].[CommonWorkOrderTearDownAudit] CWA WITH (NOLOCK)
            INNER JOIN [dbo].[CommonWorkOrderTearDown] CWD WITH (NOLOCK) ON CWD.CommonWorkOrderTearDownId = CWA.CommonWorkOrderTearDownId
            LEFT JOIN dbo.CommonTeardownType CTT WITH (NOLOCK) ON CTT.CommonTeardownTypeId = CWD.CommonTeardownTypeId
            LEFT JOIN dbo.AttachmentModule AM WITH (NOLOCK) ON AM.Name = CTT.DocumentModuleName
            OUTER APPLY
            (
                SELECT MAX(CASE WHEN t.IsDeleted = 0 THEN 1 ELSE 0 END) AS HasDocument
                FROM
                (
                    SELECT cdda.IsDeleted,
                           ROW_NUMBER() OVER (PARTITION BY cdda.CommonDocumentDetailId ORDER BY cdda.UpdatedDate DESC) AS rn
                    FROM dbo.CommonDocumentDetailsAudit cdda WITH (NOLOCK)
                    WHERE cdda.ModuleId = AM.AttachmentModuleId
                      AND cdda.ReferenceId = CWD.WorkFlowWorkOrderId
                      AND cdda.UpdatedDate <= CWA.UpdatedDate
                ) t
                WHERE t.rn = 1
            ) DocAsOf
            WHERE
                (@IsSubWorkOrder = 0 AND ISNULL(CWD.IsSubWorkOrder, 0) = 0 AND CWD.WorkOrderId = @WorkOrderId AND CWD.WorkFlowWorkOrderId = @WorkFlowWorkOrderId)
                OR
                (@IsSubWorkOrder = 1 AND CWD.IsSubWorkOrder = 1 AND CWD.SubWorkOrderId = @WorkOrderId AND CWD.SubWOPartNoId = @SubWOPartNoId)
        ),
        Lagged AS
        (
            SELECT
                *,
                CHECKSUM(TearDownType, ReasonName, Technician, TechnicianDate, Inspector, InspectorDate, Memo, IsDocument) AS RowHash,
                LAG(CHECKSUM(TearDownType, ReasonName, Technician, TechnicianDate, Inspector, InspectorDate, Memo, IsDocument))
                    OVER (PARTITION BY CommonWorkOrderTearDownId ORDER BY CommonWorkOrderTearDownAuditId) AS PrevHash,
                LAG(TearDownType)    OVER (PARTITION BY CommonWorkOrderTearDownId ORDER BY CommonWorkOrderTearDownAuditId) AS PrevTearDownType,
                LAG(ReasonName)      OVER (PARTITION BY CommonWorkOrderTearDownId ORDER BY CommonWorkOrderTearDownAuditId) AS PrevReasonName,
                LAG(Technician)      OVER (PARTITION BY CommonWorkOrderTearDownId ORDER BY CommonWorkOrderTearDownAuditId) AS PrevTechnician,
                LAG(TechnicianDate)  OVER (PARTITION BY CommonWorkOrderTearDownId ORDER BY CommonWorkOrderTearDownAuditId) AS PrevTechnicianDate,
                LAG(Inspector)       OVER (PARTITION BY CommonWorkOrderTearDownId ORDER BY CommonWorkOrderTearDownAuditId) AS PrevInspector,
                LAG(InspectorDate)   OVER (PARTITION BY CommonWorkOrderTearDownId ORDER BY CommonWorkOrderTearDownAuditId) AS PrevInspectorDate,
                LAG(Memo)            OVER (PARTITION BY CommonWorkOrderTearDownId ORDER BY CommonWorkOrderTearDownAuditId) AS PrevMemo,
                LAG(IsDocument)      OVER (PARTITION BY CommonWorkOrderTearDownId ORDER BY CommonWorkOrderTearDownAuditId) AS PrevIsDocument
            FROM Raw
        ),
        Rows AS
        (
            SELECT
                CommonWorkOrderTearDownId, TearDownType, ReasonName, Technician, TechnicianDate, Inspector, InspectorDate, Memo, IsDocument,
                CASE WHEN PrevHash IS NULL THEN N'Added' ELSE N'Updated' END AS Action,
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(TearDownType, '') <> ISNULL(PrevTearDownType, '') THEN ',tearDownType' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(ReasonName, '') <> ISNULL(PrevReasonName, '') THEN ',reasonName' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Technician, '') <> ISNULL(PrevTechnician, '') THEN ',technician' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CONVERT(VARCHAR(30), TechnicianDate, 126), '') <> ISNULL(CONVERT(VARCHAR(30), PrevTechnicianDate, 126), '') THEN ',technicianDate' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Inspector, '') <> ISNULL(PrevInspector, '') THEN ',inspector' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CONVERT(VARCHAR(30), InspectorDate, 126), '') <> ISNULL(CONVERT(VARCHAR(30), PrevInspectorDate, 126), '') THEN ',inspectorDate' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Memo, '') <> ISNULL(PrevMemo, '') THEN ',memo' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsDocument AS INT), -1) <> ISNULL(CAST(PrevIsDocument AS INT), -1) THEN ',isDocument' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                EventDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                CommonWorkOrderTearDownAuditId AS RowSeq,
                RowHash,
                PrevHash
            FROM Lagged
        )
        SELECT
            CommonWorkOrderTearDownId, TearDownType, ReasonName, Technician, TechnicianDate, Inspector, InspectorDate, Memo, IsDocument,
            Action, ChangedFields, EventDate, ChangedBy
        FROM Rows
        WHERE PrevHash IS NULL OR RowHash <> PrevHash
        ORDER BY
            CASE WHEN @SortDir = N'ASC'  THEN EventDate END ASC,
            CASE WHEN @SortDir = N'DESC' THEN EventDate END DESC,
            CASE WHEN @SortDir = N'ASC'  THEN RowSeq END ASC,
            CASE WHEN @SortDir = N'DESC' THEN RowSeq END DESC;

    END TRY
    BEGIN CATCH

    DECLARE @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments VARCHAR(150) = '[usp_Get_CommonWorkOrderTeardownCommonHistory]',
            @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, 0) AS VARCHAR(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@WorkFlowWorkOrderId, 0) AS VARCHAR(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@IsSubWorkOrder, 0) AS VARCHAR(10)) +
            '@Parameter4 = ''' + CAST(ISNULL(@SubWOPartNoId, 0) AS VARCHAR(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@EmployeeId, 0) AS VARCHAR(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@SortDir, '') AS VARCHAR(100)),
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
