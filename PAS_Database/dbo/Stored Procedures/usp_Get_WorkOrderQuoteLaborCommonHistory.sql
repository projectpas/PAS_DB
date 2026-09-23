/*********************
 ** File:   [dbo].[usp_Get_WorkOrderQuoteLaborCommonHistory]
 ** Author:   Ayushi Patel
 ** Description:
 ** Purpose: Backs the "History" icon shown after "Download Data" on the Work Order Quote Labor tab
 **          (app-work-order-labor) of Work Order Quote. Returns one row per change-event (Added /
 **          Updated / Deleted) across every WorkOrderQuoteLabor task row under a given quote labor header,
 **          newest first, with a ChangedFields list driving red-highlighting on the client. Reads from
 **          dbo.WorkOrderQuoteLaborAudit (Trg_WorkOrderQuoteLaborAudit) - Action/ChangedFields are computed here at
 **          read time via LAG/CHECKSUM, comparing each snapshot to the previous one for the same
 **          WorkOrderQuoteLaborId, and consecutive identical snapshots are skipped (avoids duplicate entries).
 **
 ** PARAMETERS:
 **   @WorkOrderQuoteLaborHeaderId - the quote labor header whose task history is requested
 **   @EmployeeId                  - used to convert dates to the requesting employee's timezone
 **   @SortDir                     - ASC | DESC (by EventDate), defaults to DESC (most recent first)
 **   @WorkOrderQuoteDetailsId     - optional fallback to find header ID if header ID is not passed
 **
 ** RETURN VALUE: one row per snapshot/action event - see column list in the final SELECT.
 **
 **********************
 ** Change History
 **********************
 ** S NO   Date          Author          Change Description
 ** --     --------      -------------   --------------------------------
    1      23-SEP-2026   Ayushi Patel    [PN-14788] Created
exec usp_Get_WorkOrderQuoteLaborCommonHistory @WorkOrderQuoteLaborHeaderId=4193, @EmployeeId=2
**********************/

CREATE PROCEDURE [dbo].[usp_Get_WorkOrderQuoteLaborCommonHistory]
    @WorkOrderQuoteLaborHeaderId BIGINT      = NULL,
    @EmployeeId                  BIGINT      = NULL,
    @SortDir                     NVARCHAR(4) = N'DESC',
    @WorkOrderQuoteDetailsId     BIGINT      = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        IF @SortDir NOT IN (N'ASC', N'DESC') SET @SortDir = N'DESC';

        IF (ISNULL(@WorkOrderQuoteLaborHeaderId, 0) = 0 AND ISNULL(@WorkOrderQuoteDetailsId, 0) > 0)
        BEGIN
            SELECT TOP 1 @WorkOrderQuoteLaborHeaderId = WorkOrderQuoteLaborHeaderId
            FROM dbo.WorkOrderQuoteLaborHeader WITH (NOLOCK)
            WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId
            ORDER BY WorkOrderQuoteLaborHeaderId DESC;
        END

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
                WQLA.WorkOrderQuoteLaborAuditId,
                WQLA.WorkOrderQuoteLaborId,
                WQLA.UpdatedDate AS RawDate,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN WQLA.UpdatedDate
                     ELSE CAST(dbo.ConvertUTCtoLocal(WQLA.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                WQLA.UpdatedBy AS ChangedBy,
                WQLA.CreatedBy AS CreatedByRaw,
                COALESCE(NULLIF(WQLA.TaskName, ''), T1.[Description], T2.[Description], '') AS Task,
                COALESCE(NULLIF(WQLA.Expertise, ''), EE.[Description], '') AS Expertise,
                COALESCE(NULLIF(WQLA.Billabletype, ''), CASE WHEN WQLA.BillableId = 1 THEN 'Billable' WHEN WQLA.BillableId = 2 THEN 'Non-Billable' ELSE '' END) AS Billable,
                WQLA.Hours,
                COALESCE(NULLIF(WQLA.BurdaenRatePercentage, ''), CAST(BP.[PercentValue] AS VARCHAR(50)), '') AS BurdenRatePercentage,
                WQLA.BurdenRateAmount,
                WQLA.TotalCostPerHour,
                WQLA.TotalCost,
                COALESCE(NULLIF(WQLA.BillingName, ''), CASE WHEN WQLA.BillingMethodId = 1 THEN 'T&M' WHEN WQLA.BillingMethodId = 2 THEN 'Actual' ELSE '' END) AS BillingMethodName,
                COALESCE(NULLIF(WQLA.MarkUp, ''), CAST(P.[PercentValue] AS VARCHAR(50)), '') AS Markup,
                WQLA.BillingRate,
                WQLA.BillingAmount,
                WQLA.DirectLaborOHCost,
                WQLA.IsDeleted
            FROM [dbo].[WorkOrderQuoteLaborAudit] WQLA WITH (NOLOCK)
            LEFT JOIN [dbo].[WorkOrderQuoteTask] WOQT WITH (NOLOCK) ON WOQT.WorkOrderQuoteTaskId = WQLA.TaskId
            LEFT JOIN [dbo].[Task] T1 WITH (NOLOCK) ON T1.TaskId = WQLA.TaskId
            LEFT JOIN [dbo].[Task] T2 WITH (NOLOCK) ON T2.TaskId = WOQT.TaskId
            LEFT JOIN [dbo].[EmployeeExpertise] EE WITH (NOLOCK) ON EE.EmployeeExpertiseId = WQLA.ExpertiseId
            LEFT JOIN [dbo].[Percent] P WITH (NOLOCK) ON P.PercentId = WQLA.MarkupPercentageId
            LEFT JOIN [dbo].[Percent] BP WITH (NOLOCK) ON BP.PercentId = WQLA.BurdaenRatePercentageId
            WHERE WQLA.WorkOrderQuoteLaborHeaderId = @WorkOrderQuoteLaborHeaderId
        ),
        Lagged AS
        (
            SELECT
                *,
                CHECKSUM(Task, Expertise, Billable, Hours, BurdenRatePercentage, BurdenRateAmount,
                         TotalCostPerHour, TotalCost, BillingMethodName, Markup,
                         BillingRate, BillingAmount, DirectLaborOHCost, IsDeleted) AS RowHash,
                LAG(CHECKSUM(Task, Expertise, Billable, Hours, BurdenRatePercentage, BurdenRateAmount,
                         TotalCostPerHour, TotalCost, BillingMethodName, Markup,
                         BillingRate, BillingAmount, DirectLaborOHCost, IsDeleted))
                    OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevHash,
                LAG(Task)                 OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevTask,
                LAG(Expertise)            OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevExpertise,
                LAG(Billable)             OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevBillable,
                LAG(Hours)                OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevHours,
                LAG(BurdenRatePercentage) OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevBurdenRatePercentage,
                LAG(BurdenRateAmount)     OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevBurdenRateAmount,
                LAG(TotalCostPerHour)     OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevTotalCostPerHour,
                LAG(TotalCost)            OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevTotalCost,
                LAG(BillingMethodName)    OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevBillingMethodName,
                LAG(Markup)               OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevMarkup,
                LAG(BillingRate)          OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevBillingRate,
                LAG(BillingAmount)        OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevBillingAmount,
                LAG(DirectLaborOHCost)    OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevDirectLaborOHCost,
                LAG(IsDeleted)            OVER (PARTITION BY WorkOrderQuoteLaborId ORDER BY WorkOrderQuoteLaborAuditId) AS PrevIsDeleted
            FROM Raw
        ),
        Rows AS
        (
            SELECT
                Task, Expertise, Billable, Hours, BurdenRatePercentage, BurdenRateAmount,
                TotalCostPerHour, TotalCost, BillingMethodName, Markup, BillingRate, BillingAmount, DirectLaborOHCost,
                CASE WHEN PrevHash IS NULL THEN N'Added' WHEN IsDeleted = 1 THEN N'Deleted' ELSE N'Updated' END AS Action,
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Task, '') <> ISNULL(PrevTask, '') THEN ',task' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Expertise, '') <> ISNULL(PrevExpertise, '') THEN ',expertise' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Billable, '') <> ISNULL(PrevBillable, '') THEN ',billable' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Hours, -1) <> ISNULL(PrevHours, -1) THEN ',hours' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BurdenRatePercentage, '') <> ISNULL(PrevBurdenRatePercentage, '') THEN ',burdenRatePercentage' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BurdenRateAmount, -1) <> ISNULL(PrevBurdenRateAmount, -1) THEN ',burdenRateAmount' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(TotalCostPerHour, -1) <> ISNULL(PrevTotalCostPerHour, -1) THEN ',totalCostPerHour' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(TotalCost, -1) <> ISNULL(PrevTotalCost, -1) THEN ',totalCost' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BillingMethodName, '') <> ISNULL(PrevBillingMethodName, '') THEN ',billingMethodName' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Markup, '') <> ISNULL(PrevMarkup, '') THEN ',markup' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BillingRate, -1) <> ISNULL(PrevBillingRate, -1) THEN ',billingRate' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BillingAmount, -1) <> ISNULL(PrevBillingAmount, -1) THEN ',billingAmount' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(DirectLaborOHCost, -1) <> ISNULL(PrevDirectLaborOHCost, -1) THEN ',directLaborOHCost' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsDeleted AS INT), -1) <> ISNULL(CAST(PrevIsDeleted AS INT), -1) THEN ',isDeleted' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                EventDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                WorkOrderQuoteLaborAuditId AS RowSeq,
                RowHash,
                PrevHash
            FROM Lagged
        )
        SELECT
            Task, Expertise, Billable, Hours, BurdenRatePercentage, BurdenRateAmount,
            TotalCostPerHour, TotalCost, BillingMethodName, Markup, BillingRate, BillingAmount, DirectLaborOHCost,
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
            @AdhocComments VARCHAR(150) = '[usp_Get_WorkOrderQuoteLaborCommonHistory]',
            @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderQuoteLaborHeaderId, 0) AS VARCHAR(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, 0) AS VARCHAR(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@SortDir, '') AS VARCHAR(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@WorkOrderQuoteDetailsId, 0) AS VARCHAR(100)),
            @ApplicationName VARCHAR(100) = 'PAS'

    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

    RETURN(1);

    END CATCH
END
