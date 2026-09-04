/*********************
 ** File:   [dbo].[usp_Get_WorkOrderSettlementHistory]
 ** Author:   Ayushi Patel
 ** Description:
 ** Purpose: Backs the "History" icon beside "Disposition" in the Work Order Settlement tab. PN-14788.
 **
 ** PARAMETERS:
 **   @WorkOrderPartNoId - the part (WorkOrderPartNumber.ID) whose settlement history is requested
 **   @EmployeeId        - used to convert dates to the requesting employee's timezone
 **   @SortDir           - ASC | DESC (by EventDate within each settlement type), defaults to DESC
 **
 ** RETURN VALUE: one row per changed field per event, grouped by SettlementType.
 **
 **********************
 ** Change History
 **********************
 ** S NO   Date          Author          Change Description
 ** --     --------      -------------   --------------------------------
    1      01-SEP-2026   Ayushi Patel    Created (PN-14788)

exec usp_Get_WorkOrderSettlementHistory @WorkOrderPartNoId=10894, @EmployeeId=2
**********************/

CREATE PROCEDURE [dbo].[usp_Get_WorkOrderSettlementHistory]
    @WorkOrderPartNoId BIGINT,
    @EmployeeId        BIGINT      = NULL,
    @SortDir           NVARCHAR(4) = N'DESC'
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

        ;WITH Src AS
        (
            SELECT
                AL.AuditId,
                AL.ColumnName,
                AL.[Action],
                AL.OldValue,
                AL.NewValue,
                AL.ChangedBy,
                AL.ChangedAt,
                TRY_CONVERT(BIGINT, JSON_VALUE(AL.PKJson, '$.WorkOrderSettlementDetailId')) AS WorkOrderSettlementDetailId
            FROM [dbo].[AuditLog] AL WITH (NOLOCK)
            WHERE AL.ReferenceId = @WorkOrderPartNoId
              AND AL.TableName = N'WorkOrderSettlementDetails'
              AND AL.ColumnName NOT IN (
                    N'CreatedDate', N'UpdatedDate', N'CreatedBy', N'UpdatedBy', N'MasterCompanyId', N'IsActive',
                    N'WorkOrderSettlementId', N'WorkOrderId', N'WorkFlowWorkOrderId', N'workOrderPartNoId', N'UserId',
                    N'ConditionId' -- superseded by the already-resolved conditionName column
              )
        ),
        Resolved AS
        (
            SELECT
                S.AuditId, S.ColumnName, S.[Action], S.OldValue, S.NewValue, S.ChangedBy, S.ChangedAt,
                COALESCE(WSD.WorkOrderSettlementId, CreateEvt.CreatedSettlementId) AS WorkOrderSettlementId
            FROM Src S
            LEFT JOIN [dbo].[WorkOrderSettlementDetails] WSD WITH (NOLOCK) ON WSD.WorkOrderSettlementDetailId = S.WorkOrderSettlementDetailId
            OUTER APPLY (
                SELECT TOP (1) TRY_CONVERT(BIGINT, AL2.NewValue) AS CreatedSettlementId
                FROM [dbo].[AuditLog] AL2 WITH (NOLOCK)
                WHERE AL2.TableName = N'WorkOrderSettlementDetails'
                  AND AL2.ColumnName = N'WorkOrderSettlementId'
                  AND TRY_CONVERT(BIGINT, JSON_VALUE(AL2.PKJson, '$.WorkOrderSettlementDetailId')) = S.WorkOrderSettlementDetailId
                ORDER BY AL2.AuditId ASC
            ) CreateEvt
        )
        SELECT
            ISNULL(WS.WorkOrderSettlementName, N'(Unknown Settlement Type)') AS SettlementType,
            CASE R.ColumnName
                WHEN N'IsMastervalue'      THEN N'Value'
                WHEN N'Isvalue_NA'         THEN N'N/A'
                WHEN N'Memo'               THEN N'Memo'
                WHEN N'conditionName'      THEN N'Condition'
                WHEN N'RevisedPartId'      THEN N'Revised Part'
                WHEN N'UserName'           THEN N'Confirmed By'
                WHEN N'sattlement_DateTime' THEN N'Confirmed Date'
                WHEN N'IsDeleted'          THEN N'Deleted'
                ELSE R.ColumnName
            END AS FieldDisplayName,
            -- RevisedPartId is an ItemMasterId - resolve to the part number, same as everywhere else in the app.
            CASE WHEN R.ColumnName = N'RevisedPartId' THEN OldPart.PartNumber ELSE R.OldValue END AS OldValue,
            CASE WHEN R.ColumnName = N'RevisedPartId' THEN NewPart.PartNumber ELSE R.NewValue END AS NewValue,
            R.[Action],
            CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN R.ChangedAt
                 ELSE CAST(dbo.ConvertUTCtoLocal(R.ChangedAt, @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
            R.ChangedBy
        FROM Resolved R
        LEFT JOIN [dbo].[WorkOrderSettlement] WS WITH (NOLOCK) ON WS.WorkOrderSettlementId = R.WorkOrderSettlementId
        LEFT JOIN [dbo].[ItemMaster] OldPart WITH (NOLOCK) ON R.ColumnName = N'RevisedPartId' AND OldPart.ItemMasterId = TRY_CONVERT(BIGINT, R.OldValue)
        LEFT JOIN [dbo].[ItemMaster] NewPart WITH (NOLOCK) ON R.ColumnName = N'RevisedPartId' AND NewPart.ItemMasterId = TRY_CONVERT(BIGINT, R.NewValue)
        ORDER BY
            WS.WorkOrderSettlementName,
            CASE WHEN @SortDir = N'ASC'  THEN R.ChangedAt END ASC,
            CASE WHEN @SortDir = N'DESC' THEN R.ChangedAt END DESC,
            R.AuditId DESC;

    END TRY
    BEGIN CATCH

    DECLARE @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments VARCHAR(150) = '[usp_Get_WorkOrderSettlementHistory]',
            @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderPartNoId, 0) AS VARCHAR(100)) +
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
