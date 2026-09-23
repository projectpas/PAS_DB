/*********************
 ** File:   [dbo].[usp_Get_WorkOrderQuoteFreightCommonHistory]
 ** Author:   Ayushi Patel
 ** Description:
 ** Purpose: Backs the "History" icon shown after "Download Data" on the Work Order Quote Freight tab
 **          (app-work-order-freight) of Work Order Quote. Returns one row per change-event (Added /
 **          Updated / Deleted) across every WorkOrderQuoteFreight row under a given quote details,
 **          newest first, with a ChangedFields list driving red-highlighting on the client. Reads from
 **          dbo.WorkOrderQuoteFreightAudit - Action/ChangedFields are computed here at
 **          read time via LAG/CHECKSUM, comparing each snapshot to the previous one for the same
 **          WorkOrderQuoteFreightId, and consecutive identical snapshots are skipped (avoids duplicate entries).
 **
 ** PARAMETERS:
 **   @WorkOrderQuoteDetailsId     - the quote details whose freight history is requested
 **   @EmployeeId                  - used to convert dates to the requesting employee's timezone
 **   @SortDir                     - ASC | DESC (by EventDate), defaults to DESC (most recent first)
 **   @WorkOrderQuoteFreightId     - optional fallback to find details ID if details ID is not passed
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
 ** 1      23-SEP-2026   Ayushi Patel    [PN-14788] Created
 **
 ** exec usp_Get_WorkOrderQuoteFreightCommonHistory @WorkOrderQuoteDetailsId=7624, @EmployeeId=2
 **********************/

CREATE PROCEDURE [dbo].[usp_Get_WorkOrderQuoteFreightCommonHistory]
    @WorkOrderQuoteDetailsId     BIGINT      = NULL,
    @EmployeeId                  BIGINT      = NULL,
    @SortDir                     NVARCHAR(4) = N'DESC',
    @WorkOrderQuoteFreightId     BIGINT      = NULL,
    @WorkOrderId                 BIGINT      = NULL,
    @WOPartNoId                  BIGINT      = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        IF @SortDir NOT IN (N'ASC', N'DESC') SET @SortDir = N'DESC';

        IF (ISNULL(@WorkOrderQuoteDetailsId, 0) = 0 AND ISNULL(@WorkOrderQuoteFreightId, 0) > 0)
        BEGIN
            SELECT TOP 1 @WorkOrderQuoteDetailsId = WorkOrderQuoteDetailsId
            FROM dbo.WorkOrderQuoteFreight WITH (NOLOCK)
            WHERE WorkOrderQuoteFreightId = @WorkOrderQuoteFreightId;

            IF (ISNULL(@WorkOrderQuoteDetailsId, 0) = 0)
            BEGIN
                SELECT TOP 1 @WorkOrderQuoteDetailsId = WorkOrderQuoteDetailsId
                FROM dbo.WorkOrderQuoteFreightAudit WITH (NOLOCK)
                WHERE WorkOrderQuoteFreightId = @WorkOrderQuoteFreightId;
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
                A.WorkOrderQuoteFreightAuditId,
                A.WorkOrderQuoteFreightId,
                ISNULL(A.UpdatedDate, A.CreatedDate) AS RawDate,
                CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN ISNULL(A.UpdatedDate, A.CreatedDate)
                     ELSE CAST(dbo.ConvertUTCtoLocal(ISNULL(A.UpdatedDate, A.CreatedDate), @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END AS EventDate,
                A.UpdatedBy AS ChangedBy,
                A.CreatedBy AS CreatedByRaw,
                COALESCE(T1.[Description], T2.[Description], NULLIF(A.TaskName, ''), '') AS Task,
                COALESCE(SV.Name, NULLIF(A.Shipvia, ''), '') AS ShipVia,
                CASE 
                    WHEN A.Weight IS NULL OR LTRIM(RTRIM(A.Weight)) = '' THEN ''
                    WHEN TRY_CAST(REPLACE(A.Weight, ',', '') AS DECIMAL(18, 2)) IS NOT NULL 
                    THEN CAST(CAST(REPLACE(A.Weight, ',', '') AS DECIMAL(18, 2)) AS VARCHAR(50))
                    ELSE LTRIM(RTRIM(A.Weight))
                END AS Weight,
                COALESCE(UOM.ShortName, NULLIF(A.UomName, ''), '') AS UOM,
                A.Length,
                A.Height,
                A.Width,
                COALESCE(DUOM.ShortName, NULLIF(A.DimensionUomName, ''), '') AS DimensionUOM,
                COALESCE(C.Code, NULLIF(A.Currency, ''), '') AS Currency,
                A.Amount,
                A.Memo,
                CASE WHEN A.BillingMethodId = 1 THEN 'T&M' WHEN A.BillingMethodId = 2 THEN 'Actual' WHEN A.BillingMethodId = 3 THEN 'Flat Rate' ELSE ISNULL(A.BillingName, '') END AS BillingMethodName,
                CASE 
                    WHEN P.PercentValue IS NOT NULL THEN CAST(P.PercentValue AS VARCHAR(50))
                    WHEN TRY_CAST(REPLACE(A.MarkUp, ',', '') AS DECIMAL(18, 2)) IS NOT NULL 
                    THEN CAST(CAST(REPLACE(A.MarkUp, ',', '') AS DECIMAL(18, 2)) AS VARCHAR(50))
                    ELSE ISNULL(A.MarkUp, '')
                END AS Markup,
                A.BillingAmount,
                A.IsDeleted
            FROM dbo.WorkOrderQuoteFreightAudit A WITH (NOLOCK)
            LEFT JOIN dbo.WorkOrderQuoteTask WOQT WITH (NOLOCK) ON WOQT.WorkOrderQuoteTaskId = A.TaskId
            LEFT JOIN dbo.Task T1 WITH (NOLOCK) ON T1.TaskId = A.TaskId
            LEFT JOIN dbo.Task T2 WITH (NOLOCK) ON T2.TaskId = WOQT.TaskId
            LEFT JOIN dbo.ShippingVia SV WITH (NOLOCK) ON SV.ShippingViaId = A.ShipViaId
            LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = A.UOMId
            LEFT JOIN dbo.UnitOfMeasure DUOM WITH (NOLOCK) ON DUOM.UnitOfMeasureId = A.DimensionUOMId
            LEFT JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyId = A.CurrencyId
            LEFT JOIN dbo.[Percent] P WITH (NOLOCK) ON P.PercentId = A.MarkupPercentageId
            WHERE A.WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId
        ),
        Lagged AS
        (
            SELECT
                *,
                CHECKSUM(Task, ShipVia, Weight, UOM, Length, Height, Width, DimensionUOM, Currency, Amount, Memo, BillingMethodName, Markup, BillingAmount, IsDeleted) AS RowHash,
                LAG(CHECKSUM(Task, ShipVia, Weight, UOM, Length, Height, Width, DimensionUOM, Currency, Amount, Memo, BillingMethodName, Markup, BillingAmount, IsDeleted))
                    OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevHash,
                LAG(Task)              OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevTask,
                LAG(ShipVia)           OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevShipVia,
                LAG(Weight)            OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevWeight,
                LAG(UOM)               OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevUOM,
                LAG(Length)            OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevLength,
                LAG(Height)            OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevHeight,
                LAG(Width)             OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevWidth,
                LAG(DimensionUOM)      OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevDimensionUOM,
                LAG(Currency)          OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevCurrency,
                LAG(Amount)            OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevAmount,
                LAG(Memo)              OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevMemo,
                LAG(BillingMethodName) OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevBillingMethodName,
                LAG(Markup)            OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevMarkup,
                LAG(BillingAmount)     OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevBillingAmount,
                LAG(IsDeleted)         OVER (PARTITION BY WorkOrderQuoteFreightId ORDER BY WorkOrderQuoteFreightAuditId) AS PrevIsDeleted
            FROM Raw
        ),
        Rows AS
        (
            SELECT
                Task, ShipVia, Weight, UOM, Length, Height, Width, DimensionUOM, Currency, Amount, Memo, BillingMethodName, Markup, BillingAmount,
                CASE
                    WHEN PrevHash IS NULL AND IsDeleted = 1 THEN 'Deleted'
                    WHEN PrevHash IS NULL THEN 'Added'
                    WHEN IsDeleted = 1 THEN 'Deleted'
                    ELSE 'Updated'
                END AS Action,
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Task, '') <> ISNULL(PrevTask, '') THEN ',task' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(ShipVia, '') <> ISNULL(PrevShipVia, '') THEN ',shipVia' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Weight, '') <> ISNULL(PrevWeight, '') THEN ',weight' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(UOM, '') <> ISNULL(PrevUOM, '') THEN ',uom' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Length, -1) <> ISNULL(PrevLength, -1) THEN ',length' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Height, -1) <> ISNULL(PrevHeight, -1) THEN ',height' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Width, -1) <> ISNULL(PrevWidth, -1) THEN ',width' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(DimensionUOM, '') <> ISNULL(PrevDimensionUOM, '') THEN ',dimensionUomName' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Currency, '') <> ISNULL(PrevCurrency, '') THEN ',currency' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Amount, -1) <> ISNULL(PrevAmount, -1) THEN ',amount' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(Memo AS NVARCHAR(MAX)), '') <> ISNULL(CAST(PrevMemo AS NVARCHAR(MAX)), '') THEN ',memo' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BillingMethodName, '') <> ISNULL(PrevBillingMethodName, '') THEN ',billingMethodName' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Markup, '') <> ISNULL(PrevMarkup, '') THEN ',markup' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BillingAmount, -1) <> ISNULL(PrevBillingAmount, -1) THEN ',billingAmount' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsDeleted AS INT), -1) <> ISNULL(CAST(PrevIsDeleted AS INT), -1) THEN ',isDeleted' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                EventDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                WorkOrderQuoteFreightAuditId AS RowSeq,
                RowHash,
                PrevHash
            FROM Lagged
        )
        SELECT
            Task, ShipVia, Weight, UOM, Length, Height, Width, DimensionUOM, Currency, Amount, Memo, BillingMethodName, Markup, BillingAmount,
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
            , @AdhocComments VARCHAR(150) = 'usp_Get_WorkOrderQuoteFreightCommonHistory'
            , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderQuoteDetailsId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException
            @DatabaseName           = @DatabaseName,
            @AdhocComments          = @AdhocComments,
            @ProcedureParameters    = @ProcedureParameters,
            @ApplicationName        = @ApplicationName,
            @ErrorLogID             = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN(1);
    END CATCH
END
