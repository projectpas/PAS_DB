/*********************
 ** File:   [dbo].[usp_Get_WorkOrderQuoteMaterialCommonHistory]
 ** Author:   Ayushi Patel
 ** Description:
 ** Purpose: Backs the "History" icon shown at the end of the header action buttons on the
 **          Work Order Quote Material List tab (custome_material) of Work Order Quote. Returns one
 **          row per change-event (Added / Updated / Deleted) across every WorkOrderQuoteMaterial row
 **          under a given quote details, newest first, with a ChangedFields list driving red-highlighting
 **          on the client. Reads from dbo.WorkOrderQuoteMaterialAudit - Action/ChangedFields are
 **          computed at read time via LAG/CHECKSUM, comparing each snapshot to the previous one
 **          for the same WorkOrderQuoteMaterialId, and consecutive identical snapshots are skipped.
 **
 ** PARAMETERS:
 **   @WorkOrderQuoteDetailsId     - the quote details whose material history is requested
 **   @EmployeeId                  - used to convert dates to the requesting employee's timezone
 **   @SortDir                     - ASC | DESC (by EventDate), defaults to DESC (most recent first)
 **   @WorkOrderQuoteMaterialId    - optional fallback to find details ID if details ID is not passed
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
 ** 1      02-OCT-2026   Ayushi Patel    Created
 **
 ** exec usp_Get_WorkOrderQuoteMaterialCommonHistory @WorkOrderQuoteDetailsId=8396, @EmployeeId=2
 **********************/

CREATE PROCEDURE [dbo].[usp_Get_WorkOrderQuoteMaterialCommonHistory]
    @WorkOrderQuoteDetailsId     BIGINT      = NULL,
    @EmployeeId                  BIGINT      = NULL,
    @SortDir                     NVARCHAR(4) = N'DESC',
    @WorkOrderQuoteMaterialId    BIGINT      = NULL,
    @WorkOrderId                 BIGINT      = NULL,
    @WOPartNoId                  BIGINT      = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        IF @SortDir NOT IN (N'ASC', N'DESC') SET @SortDir = N'DESC';

        IF (ISNULL(@WorkOrderQuoteDetailsId, 0) = 0 AND ISNULL(@WorkOrderQuoteMaterialId, 0) > 0)
        BEGIN
            SELECT TOP 1 @WorkOrderQuoteDetailsId = WorkOrderQuoteDetailsId
            FROM dbo.WorkOrderQuoteMaterial WITH (NOLOCK)
            WHERE WorkOrderQuoteMaterialId = @WorkOrderQuoteMaterialId;

            IF (ISNULL(@WorkOrderQuoteDetailsId, 0) = 0)
            BEGIN
                SELECT TOP 1 @WorkOrderQuoteDetailsId = WorkOrderQuoteDetailsId
                FROM dbo.WorkOrderQuoteMaterialAudit WITH (NOLOCK)
                WHERE WorkOrderQuoteMaterialId = @WorkOrderQuoteMaterialId;
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

        DECLARE @WorkOrderQuoteId BIGINT = 0, @WorkflowWorkOrderId BIGINT = 0;
        SELECT TOP 1 
            @WorkOrderQuoteId = WorkOrderQuoteId, 
            @WorkflowWorkOrderId = WorkflowWorkOrderId
        FROM dbo.WorkOrderQuoteDetails WITH (NOLOCK)
        WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;

        ;WITH
        Raw AS
        (
            SELECT
                'MATERIAL' AS RowType,
                A.WorkOrderQuoteMaterialId AS RowId,
                A.WorkOrderQuoteMaterialAuditId AS AuditSeq,
                A.CreatedDate AS RawCreatedDate,
                ISNULL(A.UpdatedDate, A.CreatedDate) AS RawUpdatedDate,
                COALESCE(NULLIF(A.UpdatedBy, ''), A.CreatedBy, '') AS ChangedBy,
                A.CreatedBy AS CreatedByRaw,
                COALESCE(WT.TaskName, T.[Description], NULLIF(A.TaskName, ''), '') AS Task,
                COALESCE(IM.partnumber, NULLIF(A.PartNumber, ''), '') AS PartNumber,
                COALESCE(IM.PartDescription, NULLIF(A.PartDescription, ''), '') AS PartDescription,
                COALESCE(IM.ManufacturerName, '') AS ManufacturerName,
                COALESCE(PO.[Description], NULLIF(A.Provision, ''), '') AS Provision,
                CAST(ISNULL(A.Quantity, 0) AS DECIMAL(18, 2)) AS Quantity,
                COALESCE(Uo.ShortName, NULLIF(A.UomName, ''), '') AS UOM,
                COALESCE(Co.[Description], NULLIF(A.Conditiontype, ''), '') AS Condition,
                COALESCE(CASE WHEN IM.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
                              WHEN IM.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
                              WHEN IM.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
                              ELSE 'OEM' END, NULLIF(A.Stocktype, ''), '') AS StockType,
                CAST(ISNULL(A.UnitCost, 0) AS DECIMAL(20, 2)) AS UnitCost,
                CAST(ISNULL(A.ExtendedCost, 0) AS DECIMAL(20, 2)) AS ExtendedCost,
                CASE WHEN A.BillingMethodId = 1 THEN 'T&M'
                     WHEN A.BillingMethodId = 2 THEN 'Actual'
                     WHEN A.BillingMethodId = 3 THEN 'Flat Rate'
                     ELSE ISNULL(A.BillingName, '') END AS BillingMethodName,
                COALESCE(CAST(P.PercentValue AS VARCHAR(50)), NULLIF(A.MarkUp, ''), '') AS Markup,
                CAST(ISNULL(A.BillingRate, 0) AS DECIMAL(20, 2)) AS BillingRate,
                CAST(ISNULL(A.BillingAmount, 0) AS DECIMAL(20, 2)) AS BillingAmount,
                ISNULL(A.Memo, '') AS Memo,
                CAST(ISNULL(A.IsDeleted, 0) AS BIT) AS IsDeleted
            FROM dbo.WorkOrderQuoteMaterialAudit A WITH (NOLOCK)
            LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = A.ItemMasterId
            LEFT JOIN dbo.Condition Co WITH (NOLOCK) ON Co.ConditionId = A.ConditionCodeId
            LEFT JOIN dbo.Provision PO WITH (NOLOCK) ON PO.ProvisionId = A.ProvisionId
            LEFT JOIN dbo.UnitOfMeasure Uo WITH (NOLOCK) ON Uo.UnitOfMeasureId = A.UnitOfMeasureId
            LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = A.TaskId
            LEFT JOIN dbo.WorkOrderTask WT WITH (NOLOCK) ON WT.WorkOrderTaskId = A.TaskId
            LEFT JOIN dbo.[Percent] P WITH (NOLOCK) ON P.PercentId = A.MarkupPercentageId
            WHERE A.WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId

            UNION ALL

            SELECT
                'KIT' AS RowType,
                KA.WOQMaterialKitMappingId AS RowId,
                KA.WorkOrderQuoteMaterialKitMappingAuditId AS AuditSeq,
                CASE WHEN KPART.MinPartCreatedDate IS NOT NULL AND KA.CreatedDate < KPART.MinPartCreatedDate THEN KPART.MinPartCreatedDate ELSE KA.CreatedDate END AS RawCreatedDate,
                CASE WHEN KPART.MinPartCreatedDate IS NOT NULL AND KA.UpdatedDate < KPART.MinPartCreatedDate THEN KPART.MinPartCreatedDate ELSE ISNULL(KA.UpdatedDate, KA.CreatedDate) END AS RawUpdatedDate,
                COALESCE(NULLIF(KA.UpdatedBy, ''), KA.CreatedBy, '') AS ChangedBy,
                KA.CreatedBy AS CreatedByRaw,
                COALESCE(WT.TaskName, T.[Description], '') AS Task,
                COALESCE(KM.KitNumber, KA.KitNumber, '') AS PartNumber,
                COALESCE(KM.KitDescription, '') AS PartDescription,
                '' AS ManufacturerName,
                '' AS Provision,
                CAST(ISNULL(KA.Quantity, 0) AS DECIMAL(18, 2)) AS Quantity,
                '' AS UOM,
                '' AS Condition,
                'KIT' AS StockType,
                CAST(ISNULL(KA.UnitCost, 0) AS DECIMAL(20, 2)) AS UnitCost,
                CAST(ISNULL(KA.ExtendedCost, 0) AS DECIMAL(20, 2)) AS ExtendedCost,
                CASE WHEN KA.BillingMethodId = 1 THEN 'T&M'
                     WHEN KA.BillingMethodId = 2 THEN 'Actual'
                     WHEN KA.BillingMethodId = 3 THEN 'Flat Rate'
                     ELSE ISNULL(KA.BillingName, '') END AS BillingMethodName,
                COALESCE(CAST(P.PercentValue AS VARCHAR(50)), NULLIF(KA.MarkUp, ''), '') AS Markup,
                CAST(ISNULL(KA.BillingRate, 0) AS DECIMAL(20, 2)) AS BillingRate,
                CAST(ISNULL(KA.BillingAmount, 0) AS DECIMAL(20, 2)) AS BillingAmount,
                ISNULL(KA.Memo, '') AS Memo,
                CAST(ISNULL(KA.IsDeleted, 0) AS BIT) AS IsDeleted
            FROM dbo.WorkOrderQuoteMaterialKitMappingAudit KA WITH (NOLOCK)
            LEFT JOIN (
                SELECT WOQMaterialKitMappingId, MIN(CreatedDate) AS MinPartCreatedDate
                FROM dbo.WorkOrderQuoteMaterialKit WITH (NOLOCK)
                GROUP BY WOQMaterialKitMappingId
            ) KPART ON KPART.WOQMaterialKitMappingId = KA.WOQMaterialKitMappingId
            LEFT JOIN dbo.KitMaster KM WITH (NOLOCK) ON KM.KitId = KA.KitId
            LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = KA.TaskId
            LEFT JOIN dbo.WorkOrderTask WT WITH (NOLOCK) ON WT.WorkOrderTaskId = KA.TaskId
            LEFT JOIN dbo.[Percent] P WITH (NOLOCK) ON P.PercentId = KA.MarkupPercentageId
            WHERE @WorkOrderQuoteId > 0 AND KA.WorkOrderQuoteId = @WorkOrderQuoteId AND KA.WorkflowWorkOrderId = @WorkflowWorkOrderId
        ),
        Hashed AS
        (
            SELECT
                *,
                CHECKSUM(
                    Task, PartNumber, PartDescription, ManufacturerName, Provision, Quantity, UOM, Condition, StockType,
                    UnitCost, ExtendedCost, BillingMethodName, Markup, BillingRate, BillingAmount, Memo, IsDeleted
                ) AS RowHash
            FROM Raw
        ),
        Lagged AS
        (
            SELECT
                Hashed.*,
                LAG(RowHash) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevHash,
                LAG(Task) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevTask,
                LAG(PartNumber) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevPartNumber,
                LAG(PartDescription) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevPartDescription,
                LAG(ManufacturerName) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevManufacturerName,
                LAG(Provision) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevProvision,
                LAG(Quantity) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevQuantity,
                LAG(UOM) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevUOM,
                LAG(Condition) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevCondition,
                LAG(StockType) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevStockType,
                LAG(UnitCost) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevUnitCost,
                LAG(ExtendedCost) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevExtendedCost,
                LAG(BillingMethodName) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevBillingMethodName,
                LAG(Markup) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevMarkup,
                LAG(BillingRate) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevBillingRate,
                LAG(BillingAmount) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevBillingAmount,
                LAG(Memo) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevMemo,
                LAG(IsDeleted) OVER (PARTITION BY RowType, RowId ORDER BY AuditSeq) AS PrevIsDeleted
            FROM Hashed
        ),
        Rows AS
        (
            SELECT
                Task,
                PartNumber,
                PartDescription,
                ManufacturerName,
                Provision,
                Quantity,
                UOM,
                Condition,
                StockType,
                UnitCost,
                ExtendedCost,
                BillingMethodName,
                Markup,
                BillingRate,
                BillingAmount,
                Memo,
                CASE
                    WHEN PrevHash IS NULL THEN 'Added'
                    WHEN IsDeleted = 1 AND PrevIsDeleted = 0 THEN 'Deleted'
                    ELSE 'Updated'
                END AS [Action],
                STUFF(
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Task, '') <> ISNULL(PrevTask, '') THEN ',task' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(PartNumber, '') <> ISNULL(PrevPartNumber, '') THEN ',partNumber' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(PartDescription, '') <> ISNULL(PrevPartDescription, '') THEN ',partDescription' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(ManufacturerName, '') <> ISNULL(PrevManufacturerName, '') THEN ',manufacturerName' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Provision, '') <> ISNULL(PrevProvision, '') THEN ',provision' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Quantity, -1) <> ISNULL(PrevQuantity, -1) THEN ',quantity' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(UOM, '') <> ISNULL(PrevUOM, '') THEN ',uom' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Condition, '') <> ISNULL(PrevCondition, '') THEN ',condition' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(StockType, '') <> ISNULL(PrevStockType, '') THEN ',stockType' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(UnitCost, -1) <> ISNULL(PrevUnitCost, -1) THEN ',unitCost' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(ExtendedCost, -1) <> ISNULL(PrevExtendedCost, -1) THEN ',extendedCost' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BillingMethodName, '') <> ISNULL(PrevBillingMethodName, '') THEN ',billingMethodName' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Markup, '') <> ISNULL(PrevMarkup, '') THEN ',markup' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BillingRate, -1) <> ISNULL(PrevBillingRate, -1) THEN ',billingRate' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(BillingAmount, -1) <> ISNULL(PrevBillingAmount, -1) THEN ',billingAmount' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(Memo, '') <> ISNULL(PrevMemo, '') THEN ',memo' ELSE '' END +
                    CASE WHEN PrevHash IS NOT NULL AND ISNULL(CAST(IsDeleted AS INT), -1) <> ISNULL(CAST(PrevIsDeleted AS INT), -1) THEN ',isDeleted' ELSE '' END
                , 1, 1, '') AS ChangedFields,
                CASE WHEN PrevHash IS NULL THEN
                    CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN RawCreatedDate
                         ELSE CAST(dbo.ConvertUTCtoLocal(RawCreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END
                ELSE
                    CASE WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0 THEN RawUpdatedDate
                         ELSE CAST(dbo.ConvertUTCtoLocal(RawUpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME2(3)) END
                END AS EventDate,
                CASE WHEN PrevHash IS NULL THEN RawCreatedDate ELSE RawUpdatedDate END AS RawDate,
                CASE WHEN PrevHash IS NULL THEN CreatedByRaw ELSE ChangedBy END AS ChangedBy,
                AuditSeq AS RowSeq,
                RowHash,
                PrevHash
            FROM Lagged
        )
        SELECT
            Task, PartNumber, PartDescription, ManufacturerName, Provision, Quantity, UOM, Condition, StockType,
            UnitCost, ExtendedCost, BillingMethodName, Markup, BillingRate, BillingAmount, Memo,
            Action, ChangedFields, EventDate, ChangedBy
        FROM Rows
        WHERE PrevHash IS NULL OR RowHash <> PrevHash
        ORDER BY
            CASE WHEN @SortDir = N'ASC'  THEN EventDate END ASC,
            CASE WHEN @SortDir = N'DESC' THEN EventDate END DESC,
            CASE WHEN @SortDir = N'ASC'  THEN RawDate END ASC,
            CASE WHEN @SortDir = N'DESC' THEN RawDate END DESC;

    END TRY
    BEGIN CATCH

    DECLARE @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments VARCHAR(150) = 'usp_Get_WorkOrderQuoteMaterialCommonHistory'
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
