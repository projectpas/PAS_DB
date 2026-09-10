/*********************
 ** File:   [dbo].[usp_Get_WorkOrderAssetsCommonHistory]
 ** Author:   Ayushi Patel
 ** Description:
 ** Purpose: Backs the "Tools History" icon shown before "Download Data" on the Tools tab
 **          (app-work-order-assets) of Work Order Edit, and the merged delete-confirmation-plus-history
 **          popup (client filters this same result set down to one WorkOrderAssetId). Returns one row per
 **          change-event (Added / Updated / Deleted / Restored) across every WorkOrderAssets row under a
 **          given work-flow work order, newest first, with a ChangedFields list driving red-highlighting
 **          on the client. Reads from dbo.WorkOrderAssetsAudit (Trg_WorkOrderAssetsAudit) - Action/
 **          ChangedFields are computed here at read time via LAG/CHECKSUM, comparing each snapshot to the
 **          previous one for the same WorkOrderAssetId, and consecutive identical snapshots are skipped
 **          (avoids duplicate entries). "Remove" and "Restore" in this app are both plain UPDATEs toggling
 **          IsDeleted (see WorkOrderRepository.DeleteWorkOrderAsset and dbo.UpdateDeletedRecords) - there
 **          is no hard-DELETE path for this table, so Action is derived purely from the IsDeleted 0->1
 **          (Deleted) / 1->0 (Restored) transition, with no separate IsRowDeleted flag needed. Display
 **          fields (Tool Name/Id/Description/Class, Task) are lookup values, not columns on
 **          WorkOrderAssets itself, so they are resolved via JOIN here at read time (same joins as
 **          GetWOAssetList uses for the live grid) rather than snapshotted into the audit table - history
 **          therefore reflects each lookup's current value, not a point-in-time snapshot.
 **          PN-14788.
 **
 ** PARAMETERS:
 **   @WorkFlowWorkOrderId - the work-flow work order whose Tools history is requested (same scope as GetWOAssetList)
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

exec usp_Get_WorkOrderAssetsCommonHistory @WorkFlowWorkOrderId=3305, @EmployeeId=2
**********************/

CREATE PROCEDURE [dbo].[usp_Get_WorkOrderAssetsCommonHistory]
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
                WAA.WorkOrderAssetAuditId,
                WAA.WorkOrderAssetId,
                WAA.UpdatedDate AS RawDate,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN WAA.UpdatedDate
                     ELSE CAST(dbo.ConvertUTCtoLocal(WAA.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                WAA.UpdatedBy AS ChangedBy,
                WAA.CreatedBy AS CreatedByRaw,
                CASE WHEN ISNULL(WO.WorkOrderFormTypeId, 0) = 1 THEN WOT.[TaskName] ELSE T.[Description] END AS TaskName,
                A.[Name] AS Name,
                A.AssetId AS AssetId,
                A.[Description] AS [Description],
                TY.TangibleClassName AS AssetTypeName,
                WAA.Quantity,
                CASE WHEN ISNULL(WAA.IsFromWorkFlow, 0) = 0 THEN 'No' ELSE 'Yes' END AS IsFromWorkFlowNew,
                WAA.IsDeleted
            FROM [dbo].[WorkOrderAssetsAudit] WAA WITH (NOLOCK)
            LEFT JOIN dbo.Asset A WITH (NOLOCK) ON WAA.AssetRecordId = A.AssetRecordId
            LEFT JOIN dbo.DeprNonDeprTangibleAssets AAT WITH (NOLOCK) ON A.DeprNonDeprTangibleAssetsId = AAT.DeprNonDeprTangibleAssetsId
            LEFT JOIN dbo.TangibleClass TY WITH (NOLOCK) ON AAT.TangibleClassId = TY.TangibleClassId
            LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WAA.WorkOrderId
            LEFT JOIN dbo.WorkOrderTask WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WAA.TaskId
            LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WAA.TaskId
            WHERE WAA.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
        ),
        Lagged AS
        (
            SELECT
                *,
                CHECKSUM(TaskName, Name, AssetId, [Description], AssetTypeName, Quantity, IsFromWorkFlowNew, IsDeleted) AS RowHash,
                LAG(CHECKSUM(TaskName, Name, AssetId, [Description], AssetTypeName, Quantity, IsFromWorkFlowNew, IsDeleted))
                    OVER (PARTITION BY WorkOrderAssetId ORDER BY WorkOrderAssetAuditId) AS PrevHash,
                LAG(TaskName)          OVER (PARTITION BY WorkOrderAssetId ORDER BY WorkOrderAssetAuditId) AS PrevTaskName,
                LAG(Name)              OVER (PARTITION BY WorkOrderAssetId ORDER BY WorkOrderAssetAuditId) AS PrevName,
                LAG(AssetId)           OVER (PARTITION BY WorkOrderAssetId ORDER BY WorkOrderAssetAuditId) AS PrevAssetId,
                LAG([Description])    OVER (PARTITION BY WorkOrderAssetId ORDER BY WorkOrderAssetAuditId) AS PrevDescription,
                LAG(AssetTypeName)     OVER (PARTITION BY WorkOrderAssetId ORDER BY WorkOrderAssetAuditId) AS PrevAssetTypeName,
                LAG(Quantity)          OVER (PARTITION BY WorkOrderAssetId ORDER BY WorkOrderAssetAuditId) AS PrevQuantity,
                LAG(IsFromWorkFlowNew) OVER (PARTITION BY WorkOrderAssetId ORDER BY WorkOrderAssetAuditId) AS PrevIsFromWorkFlowNew,
                LAG(IsDeleted)         OVER (PARTITION BY WorkOrderAssetId ORDER BY WorkOrderAssetAuditId) AS PrevIsDeleted
            FROM Raw
        ),
        Rows AS
        (
            SELECT
                WorkOrderAssetId, TaskName, Name, AssetId, [Description], AssetTypeName, Quantity, IsFromWorkFlowNew,
                CASE WHEN PrevHash IS NULL THEN N'Added'
                     WHEN IsDeleted = 1 AND ISNULL(PrevIsDeleted, 0) = 0 THEN N'Deleted'
                     WHEN IsDeleted = 0 AND PrevIsDeleted = 1 THEN N'Restored'
                     ELSE N'Updated' END AS Action,
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(TaskName, '') <> ISNULL(PrevTaskName, '') THEN ',taskName' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Name, '') <> ISNULL(PrevName, '') THEN ',name' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(AssetId, '') <> ISNULL(PrevAssetId, '') THEN ',assetId' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL([Description], '') <> ISNULL(PrevDescription, '') THEN ',description' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(AssetTypeName, '') <> ISNULL(PrevAssetTypeName, '') THEN ',assetTypeName' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Quantity, -1) <> ISNULL(PrevQuantity, -1) THEN ',quantity' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(IsFromWorkFlowNew, '') <> ISNULL(PrevIsFromWorkFlowNew, '') THEN ',isFromWorkFlowNew' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                EventDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                WorkOrderAssetAuditId AS RowSeq,
                RowHash,
                PrevHash
            FROM Lagged
        )
        SELECT
            WorkOrderAssetId, TaskName, Name, AssetId, [Description], AssetTypeName, Quantity, IsFromWorkFlowNew,
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
            @AdhocComments VARCHAR(150) = '[usp_Get_WorkOrderAssetsCommonHistory]',
            @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkFlowWorkOrderId, 0) AS VARCHAR(100)) +
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
