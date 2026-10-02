/*********************
 ** File:   [dbo].[usp_Get_WorkOrderQuoteChargesCommonHistory]
 ** Author:   Ayushi Patel
 ** Description:
 ** Purpose: Backs the "History" icon shown at the end of the header action buttons on the
 **          Work Order Quote Charges tab (app-work-order-charges) of Work Order Quote. Returns one
 **          row per change-event (Added / Updated / Deleted) across every WorkOrderQuoteCharges row
 **          under a given quote details, newest first, with a ChangedFields list driving red-highlighting
 **          on the client. Reads from dbo.WorkOrderQuoteChargesAudit - Action/ChangedFields are
 **          computed at read time via LAG/CHECKSUM, comparing each snapshot to the previous one
 **          for the same WorkOrderQuoteChargesId, and consecutive identical snapshots are skipped.
 **
 ** PARAMETERS:
 **   @WorkOrderQuoteDetailsId     - the quote details whose charges history is requested
 **   @EmployeeId                  - used to convert dates to the requesting employee's timezone
 **   @SortDir                     - ASC | DESC (by EventDate), defaults to DESC (most recent first)
 **   @WorkOrderQuoteChargesId     - optional fallback to find details ID if details ID is not passed
 **   @WorkOrderId                 - optional fallback with @WOPartNoId
 **   @WOPartNoId                  - optional fallback with @WorkOrderId
 **
 ** RETURN VALUE: one row per snapshot/action event - see column list in the final SELECT.
 **
 **********************
 ** Change History
 **********************
 ** S NO   Date          Author          Change Description
 ** --     --------      -------------   --------------------------------
 ** 1      01-OCT-2026   Ayushi Patel    Created
 **
 ** exec usp_Get_WorkOrderQuoteChargesCommonHistory @WorkOrderQuoteDetailsId=8377, @EmployeeId=2
 **********************/

CREATE PROCEDURE [dbo].[usp_Get_WorkOrderQuoteChargesCommonHistory]
    @WorkOrderQuoteDetailsId     BIGINT      = NULL,
    @EmployeeId                  BIGINT      = NULL,
    @SortDir                     NVARCHAR(4) = N'DESC',
    @WorkOrderQuoteChargesId     BIGINT      = NULL,
    @WorkOrderId                 BIGINT      = NULL,
    @WOPartNoId                  BIGINT      = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        IF @SortDir NOT IN (N'ASC', N'DESC') SET @SortDir = N'DESC';

        IF (ISNULL(@WorkOrderQuoteDetailsId, 0) = 0 AND ISNULL(@WorkOrderQuoteChargesId, 0) > 0)
        BEGIN
            SELECT TOP 1 @WorkOrderQuoteDetailsId = WorkOrderQuoteDetailsId
            FROM dbo.WorkOrderQuoteCharges WITH (NOLOCK)
            WHERE WorkOrderQuoteChargesId = @WorkOrderQuoteChargesId;

            IF (ISNULL(@WorkOrderQuoteDetailsId, 0) = 0)
            BEGIN
                SELECT TOP 1 @WorkOrderQuoteDetailsId = WorkOrderQuoteDetailsId
                FROM dbo.WorkOrderQuoteChargesAudit WITH (NOLOCK)
                WHERE WorkOrderQuoteChargesId = @WorkOrderQuoteChargesId;
            END
        END

        IF (ISNULL(@WorkOrderQuoteDetailsId, 0) = 0 AND ISNULL(@WorkOrderId, 0) > 0 AND ISNULL(@WOPartNoId, 0) > 0)
        BEGIN
            SELECT TOP 1 @WorkOrderQuoteDetailsId = WOQD.WorkOrderQuoteDetailsId
            FROM dbo.WorkOrderQuoteDetails WOQD WITH (NOLOCK)
            JOIN dbo.WorkOrderQuote WOQ WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
            WHERE WOQ.WorkOrderId = @WorkOrderId AND WOQD.WOPartNoId = @WOPartNoId
            ORDER BY WOQD.WorkOrderQuoteDetailsId DESC;
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
                A.WorkOrderQuoteChargesAuditId,
                A.WorkOrderQuoteChargesId,
                ISNULL(A.UpdatedDate, A.CreatedDate) AS RawDate,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN ISNULL(A.UpdatedDate, A.CreatedDate)
                     ELSE CAST(dbo.ConvertUTCtoLocal(ISNULL(A.UpdatedDate, A.CreatedDate), @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                A.UpdatedBy AS ChangedBy,
                A.CreatedBy AS CreatedByRaw,
                COALESCE(WT.TaskName, T1.[Description], T2.[Description], NULLIF(A.TaskName, ''), '') AS Task,
                COALESCE(C.ChargeType, NULLIF(A.ChargeType, ''), '') AS ChargeType,
                COALESCE(GL.AccountName, NULLIF(A.GlAccountName, 'As Per GL Allocation'), '') AS GlAccountName,
                ISNULL(A.Description, '') AS Description,
                CAST(ISNULL(A.Quantity, 0) AS DECIMAL(18, 2)) AS Quantity,
                ISNULL(A.RefNum, '') AS RefNum,
                COALESCE(UOM.ShortName, '') AS UOM,
                CAST(ISNULL(A.UnitCost, 0) AS DECIMAL(20, 2)) AS UnitCost,
                CAST(ISNULL(A.ExtendedCost, 0) AS DECIMAL(20, 2)) AS ExtendedCost,
                COALESCE(V.VendorName, NULLIF(A.VendorName, ''), '') AS VendorName,
                CASE WHEN A.BillingMethodId = 1 THEN 'T&M' WHEN A.BillingMethodId = 2 THEN 'Actual' WHEN A.BillingMethodId = 3 THEN 'Flat Rate' ELSE ISNULL(A.BillingName, '') END AS BillingMethodName,
                CASE 
                    WHEN P.PercentValue IS NOT NULL THEN CAST(P.PercentValue AS VARCHAR(50))
                    WHEN TRY_CAST(REPLACE(A.MarkUp, ',', '') AS DECIMAL(18, 2)) IS NOT NULL 
                    THEN CAST(CAST(REPLACE(A.MarkUp, ',', '') AS DECIMAL(18, 2)) AS VARCHAR(50))
                    ELSE ISNULL(A.MarkUp, '')
                END AS Markup,
                CAST(ISNULL(A.BillingRate, 0) AS DECIMAL(20, 2)) AS BillingRate,
                CAST(ISNULL(A.BillingAmount, 0) AS DECIMAL(20, 2)) AS BillingAmount,
                A.IsDeleted
            FROM dbo.WorkOrderQuoteChargesAudit A WITH (NOLOCK)
            LEFT JOIN dbo.WorkOrderQuoteTask WOQT WITH (NOLOCK) ON WOQT.WorkOrderQuoteTaskId = A.TaskId
            LEFT JOIN dbo.Task T1 WITH (NOLOCK) ON T1.TaskId = A.TaskId
            LEFT JOIN dbo.Task T2 WITH (NOLOCK) ON T2.TaskId = WOQT.TaskId
            LEFT JOIN dbo.WorkOrderTask WT WITH (NOLOCK) ON WT.WorkOrderTaskId = A.TaskId
            LEFT JOIN dbo.[Charge] C WITH (NOLOCK) ON C.ChargeId = A.ChargesTypeId
            LEFT JOIN dbo.[GLAccount] GL WITH (NOLOCK) ON GL.GLAccountId = C.GLAccountId
            LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = A.UOMId
            LEFT JOIN dbo.Vendor V WITH (NOLOCK) ON V.VendorId = A.VendorId
            LEFT JOIN dbo.[Percent] P WITH (NOLOCK) ON P.PercentId = A.MarkupPercentageId
            WHERE A.WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId
        ),
        Lagged AS
        (
            SELECT
                *,
                CHECKSUM(Task, ChargeType, GlAccountName, Description, Quantity, RefNum, UOM, UnitCost, ExtendedCost, VendorName, BillingMethodName, Markup, BillingRate, BillingAmount, IsDeleted) AS RowHash,
                LAG(CHECKSUM(Task, ChargeType, GlAccountName, Description, Quantity, RefNum, UOM, UnitCost, ExtendedCost, VendorName, BillingMethodName, Markup, BillingRate, BillingAmount, IsDeleted))
                    OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevHash,
                LAG(Task)              OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevTask,
                LAG(ChargeType)        OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevChargeType,
                LAG(GlAccountName)     OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevGlAccountName,
                LAG(Description)       OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevDescription,
                LAG(Quantity)          OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevQuantity,
                LAG(RefNum)            OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevRefNum,
                LAG(UOM)               OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevUOM,
                LAG(UnitCost)          OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevUnitCost,
                LAG(ExtendedCost)      OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevExtendedCost,
                LAG(VendorName)        OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevVendorName,
                LAG(BillingMethodName) OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevBillingMethodName,
                LAG(Markup)            OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevMarkup,
                LAG(BillingRate)       OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevBillingRate,
                LAG(BillingAmount)     OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevBillingAmount,
                LAG(IsDeleted)         OVER (PARTITION BY WorkOrderQuoteChargesId ORDER BY WorkOrderQuoteChargesAuditId) AS PrevIsDeleted
            FROM Raw
        ),
        Rows AS
        (
            SELECT
                WorkOrderQuoteChargesId,
                Task, ChargeType, GlAccountName, Description, Quantity, RefNum, UOM, UnitCost, ExtendedCost, VendorName, BillingMethodName, Markup, BillingRate, BillingAmount,
                CASE
                    WHEN PrevHash IS NULL AND IsDeleted = 1 THEN 'Deleted'
                    WHEN PrevHash IS NULL THEN 'Added'
                    WHEN IsDeleted = 1 THEN 'Deleted'
                    ELSE 'Updated'
                END AS Action,
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Task, '') <> ISNULL(PrevTask, '') THEN ',task' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(ChargeType, '') <> ISNULL(PrevChargeType, '') THEN ',chargeType' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(GlAccountName, '') <> ISNULL(PrevGlAccountName, '') THEN ',glAccountName' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Description, '') <> ISNULL(PrevDescription, '') THEN ',description' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Quantity, -1) <> ISNULL(PrevQuantity, -1) THEN ',quantity' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(RefNum, '') <> ISNULL(PrevRefNum, '') THEN ',refNum' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(UOM, '') <> ISNULL(PrevUOM, '') THEN ',uom' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(UnitCost, -1) <> ISNULL(PrevUnitCost, -1) THEN ',unitCost' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(ExtendedCost, -1) <> ISNULL(PrevExtendedCost, -1) THEN ',extendedCost' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(VendorName, '') <> ISNULL(PrevVendorName, '') THEN ',vendorName' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BillingMethodName, '') <> ISNULL(PrevBillingMethodName, '') THEN ',billingMethodName' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Markup, '') <> ISNULL(PrevMarkup, '') THEN ',markup' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BillingRate, -1) <> ISNULL(PrevBillingRate, -1) THEN ',billingRate' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BillingAmount, -1) <> ISNULL(PrevBillingAmount, -1) THEN ',billingAmount' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsDeleted AS INT), -1) <> ISNULL(CAST(PrevIsDeleted AS INT), -1) THEN ',isDeleted' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                EventDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                WorkOrderQuoteChargesAuditId AS RowSeq,
                RowHash,
                PrevHash
            FROM Lagged
        )
        SELECT
            Task, ChargeType, GlAccountName, Description, Quantity, RefNum, UOM, UnitCost, ExtendedCost, VendorName, BillingMethodName, Markup, BillingRate, BillingAmount,
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
            , @AdhocComments VARCHAR(150) = 'usp_Get_WorkOrderQuoteChargesCommonHistory'
            , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderQuoteDetailsId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException
            @DatabaseName           = @DatabaseName,
            @AdhocComments          = @AdhocComments,
            @ProcedureParameters    = @ProcedureParameters,
            @ApplicationName        =  @ApplicationName,
            @ErrorLogID             = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN(1);
    END CATCH
END
