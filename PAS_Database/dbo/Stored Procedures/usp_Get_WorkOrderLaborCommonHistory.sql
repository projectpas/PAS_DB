/*********************
 ** File:   [dbo].[usp_Get_WorkOrderLaborCommonHistory]
 ** Author:   Ayushi Patel
 ** Description:
 ** Purpose: Backs the "History" icon shown before "Print Traveler Form" on the Labor tab
 **          (app-work-order-traveler) of Work Order Edit. Returns one row per change-event (Added /
 **          Updated / Deleted) across every WorkOrderLabor task row under a given labor header, newest
 **          first, with a ChangedFields list driving red-highlighting on the client. Reads from
 **          dbo.WorkOrderLaborAudit (Trg_WorkOrderLaborAudit) - Action/ChangedFields are computed here at
 **          read time via LAG/CHECKSUM, comparing each snapshot to the previous one for the same
 **          WorkOrderLaborId, and consecutive identical snapshots are skipped (avoids duplicate entries).
 **          PN-17600.
 **
 ** PARAMETERS:
 **   @WorkOrderLaborHeaderId - the labor header whose task history is requested (one per Work Order part)
 **   @EmployeeId             - used to convert dates to the requesting employee's timezone
 **   @SortDir                - ASC | DESC (by EventDate), defaults to DESC (most recent first)
 **
 ** RETURN VALUE: one row per snapshot/action event - see column list in the final SELECT.
 **
 **********************
 ** Change History
 **********************
 ** S NO   Date          Author          Change Description
 ** --     --------      -------------   --------------------------------
    1      08-SEP-2026   Ayushi Patel    Created (PN-14788)
    2      10-SEP-2026   Ayushi Patel    use isDeleted instead of isRowDeleted (PN-14788)
exec usp_Get_WorkOrderLaborCommonHistory @WorkOrderLaborHeaderId=12345, @EmployeeId=2
**********************/

CREATE PROCEDURE [dbo].[usp_Get_WorkOrderLaborCommonHistory]
    @WorkOrderLaborHeaderId BIGINT,
    @EmployeeId             BIGINT      = NULL,
    @SortDir                NVARCHAR(4) = N'DESC'
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
                WLA.WorkOrderLaborAuditId,
                WLA.WorkOrderLaborId,
                WLA.UpdatedDate AS RawDate,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN WLA.UpdatedDate
                     ELSE CAST(dbo.ConvertUTCtoLocal(WLA.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                WLA.UpdatedBy AS ChangedBy,
                WLA.CreatedBy AS CreatedByRaw,
                WLA.TaskName AS Task,
                TS.[Description] AS TaskStatusName,
                WLA.StatusChangedDate,
                WLA.LabourExpertise AS Expertise,
                WLA.LabourEmployee AS Employee,
                WLA.Billable,
                WLA.Hours,
                WLA.Adjustments,
                WLA.AdjustedHours,
                WLA.StandardHours,
                WLA.StandardMinute,
                WLA.VarianceHours,
                WLA.VarianceMinute,
                WLA.DirectLaborOHCost,
                WLA.BurdenRateAmount,
                WLA.TotalCostPerHour,
                WLA.TotalCost,
                WLA.Memo,
                WLA.IsAdjustmentTask,
                WLA.IsDeleted
            FROM [dbo].[WorkOrderLaborAudit] WLA WITH (NOLOCK)
            LEFT JOIN [dbo].[TaskStatus] TS WITH (NOLOCK) ON TS.TaskStatusId = WLA.TaskStatusId
            WHERE WLA.WorkOrderLaborAuditHeaderId = @WorkOrderLaborHeaderId
        ),
        Lagged AS
        (
            SELECT
                *,
                CHECKSUM(Task, TaskStatusName, Expertise, Employee, Billable, Hours, Adjustments, AdjustedHours,
                         StandardHours, StandardMinute, VarianceHours, VarianceMinute, DirectLaborOHCost, BurdenRateAmount,
                         TotalCostPerHour, TotalCost, Memo, IsAdjustmentTask, IsDeleted) AS RowHash,
                LAG(CHECKSUM(Task, TaskStatusName, Expertise, Employee, Billable, Hours, Adjustments, AdjustedHours,
                         StandardHours, StandardMinute, VarianceHours, VarianceMinute, DirectLaborOHCost, BurdenRateAmount,
                         TotalCostPerHour, TotalCost, Memo, IsAdjustmentTask, IsDeleted))
                    OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevHash,
                LAG(Task)             OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevTask,
                LAG(TaskStatusName)   OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevTaskStatusName,
                LAG(Expertise)        OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevExpertise,
                LAG(Employee)         OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevEmployee,
                LAG(Billable)         OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevBillable,
                LAG(Hours)            OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevHours,
                LAG(Adjustments)      OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevAdjustments,
                LAG(AdjustedHours)    OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevAdjustedHours,
                LAG(StandardHours)    OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevStandardHours,
                LAG(StandardMinute)   OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevStandardMinute,
                LAG(VarianceHours)    OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevVarianceHours,
                LAG(VarianceMinute)   OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevVarianceMinute,
                LAG(DirectLaborOHCost) OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevDirectLaborOHCost,
                LAG(BurdenRateAmount) OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevBurdenRateAmount,
                LAG(TotalCostPerHour) OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevTotalCostPerHour,
                LAG(TotalCost)        OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevTotalCost,
                LAG(Memo)             OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevMemo,
                LAG(IsAdjustmentTask) OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevIsAdjustmentTask,
                LAG(IsDeleted)        OVER (PARTITION BY WorkOrderLaborId ORDER BY WorkOrderLaborAuditId) AS PrevIsDeleted
            FROM Raw
        ),
        Rows AS
        (
            SELECT
                Task, TaskStatusName, StatusChangedDate, Expertise, Employee, Billable, Hours, Adjustments, AdjustedHours,
                StandardHours, StandardMinute, VarianceHours, VarianceMinute, DirectLaborOHCost, BurdenRateAmount,
                TotalCostPerHour, TotalCost, Memo, IsAdjustmentTask,
                CASE WHEN PrevHash IS NULL THEN N'Added' WHEN IsDeleted = 1 THEN N'Deleted' ELSE N'Updated' END AS Action,
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Task, '') <> ISNULL(PrevTask, '') THEN ',task' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(TaskStatusName, '') <> ISNULL(PrevTaskStatusName, '') THEN ',taskStatus' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Expertise, '') <> ISNULL(PrevExpertise, '') THEN ',expertise' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Employee, '') <> ISNULL(PrevEmployee, '') THEN ',employee' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Billable, '') <> ISNULL(PrevBillable, '') THEN ',billable' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Hours, -1) <> ISNULL(PrevHours, -1) THEN ',hours' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Adjustments, -1) <> ISNULL(PrevAdjustments, -1) THEN ',adjustments' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(AdjustedHours, -1) <> ISNULL(PrevAdjustedHours, -1) THEN ',adjustedHours' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND (ISNULL(StandardHours, -1) <> ISNULL(PrevStandardHours, -1) OR ISNULL(StandardMinute, -1) <> ISNULL(PrevStandardMinute, -1)) THEN ',standardHours' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND (ISNULL(VarianceHours, -1) <> ISNULL(PrevVarianceHours, -1) OR ISNULL(VarianceMinute, -1) <> ISNULL(PrevVarianceMinute, -1)) THEN ',variance' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(DirectLaborOHCost, -1) <> ISNULL(PrevDirectLaborOHCost, -1) THEN ',directLaborCost' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BurdenRateAmount, -1) <> ISNULL(PrevBurdenRateAmount, -1) THEN ',burdenRateAmount' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(TotalCostPerHour, -1) <> ISNULL(PrevTotalCostPerHour, -1) THEN ',laborCostPerHour' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(TotalCost, -1) <> ISNULL(PrevTotalCost, -1) THEN ',laborCost' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Memo, '') <> ISNULL(PrevMemo, '') THEN ',memo' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsAdjustmentTask AS INT), -1) <> ISNULL(CAST(PrevIsAdjustmentTask AS INT), -1) THEN ',isAdjustmentTask' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsDeleted AS INT), -1) <> ISNULL(CAST(PrevIsDeleted AS INT), -1) THEN ',isDeleted' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                EventDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                WorkOrderLaborAuditId AS RowSeq,
                RowHash,
                PrevHash
            FROM Lagged
        )
        SELECT
            Task, TaskStatusName, StatusChangedDate, Expertise, Employee, Billable, Hours, Adjustments, AdjustedHours,
            StandardHours, StandardMinute, VarianceHours, VarianceMinute, DirectLaborOHCost, BurdenRateAmount,
            TotalCostPerHour, TotalCost, Memo, IsAdjustmentTask, Action, ChangedFields, EventDate, ChangedBy
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
            @AdhocComments VARCHAR(150) = '[usp_Get_WorkOrderLaborCommonHistory]',
            @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderLaborHeaderId, 0) AS VARCHAR(100)) +
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
