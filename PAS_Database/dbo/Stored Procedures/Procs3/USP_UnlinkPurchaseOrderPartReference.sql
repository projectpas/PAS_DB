/*************************************************************
 ** File:   [USP_UnlinkPurchaseOrderPartReference]
 ** Author:   Abhishek Jirawala
 ** Description: This SP revalidates every selected PurchaseOrderPartReference
 **              row inside one transaction (all-or-nothing: if any row fails
 **              validation, nothing is changed and the per-row diagnosis is
 **              returned), then hard-deletes the junction rows, clears the
 **              PurchaseOrderPart reverse pointers, and blanks/re-points/
 **              flags-as-"Multiple" the module grid's scalar PO fields
 **              depending on how many linked POs remain for that part/line.
 ** Purpose: Performs the actual Unlink PO / Unlink All PO batch operation for
 **          the Work Order Material Grid, Sales Order, and Purchase Order screens.
 **          Uses the same FN_PurchaseOrderHasAnyReceipt /
 **          FN_IsModulePartReservedOrIssued functions as
 **          USP_GetLinkedPOUnlinkEligibility so the guard here matches
 **          exactly what the Unlink PO popup showed the user.
 **          Requires each TVP row's ReferencePartId to already be resolved
 **          (as returned by USP_GetLinkedPOUnlinkEligibility) - a NULL
 **          ReferencePartId is treated as an unresolved/invalid context
 **          (reason code 5) rather than re-deriving it here.
 ** Date:   26/08/2026

 ** PARAMETERS:
 @tbl_POPartReferenceUnlink [dbo].[POPartReferenceUnlinkType] READONLY

 ** RETURN VALUE:
 Per-row diagnosis rowset: IsUnlinked/CanUnlink/CannotUnlinkReasonCode for
 every row in @tbl_POPartReferenceUnlink.

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				--------------------------------
    1    26/08/2026   Abhishek Jirawala	Created for Unlink PO feature
    2    26/08/2026   Abhishek Jirawala	Fixed "Invalid object name '#Diagnosis'" on the validation-failure
	                                        path: ROLLBACK TRAN undoes the DDL that created #Diagnosis (temp
	                                        table creation is transactional), so it must run AFTER the SELECT
	                                        that reads #Diagnosis, not before.
    3    26/08/2026   Abhishek Jirawala	Fixed "Column 'CannotUnlinkReasonCode' does not belong to table":
	                                        sp_UpdatePOPartReferenceDetail returns its own "value" rowset, which
	                                        was leaking through as an extra result set ahead of this procedure's
	                                        diagnosis SELECT. Captured via INSERT INTO #DummyPOUpdate EXEC ...
	                                        so only the diagnosis rowset reaches the caller.
    4    27/08/2026   Abhishek Jirawala	Receiving quantity against a PO must not by itself block Unlink PO -
	                                        only stock actually used against the SPECIFIC target Work Order /
	                                        Sub Work Order should. For ModuleId 1/5, reason code now comes from
	                                        FN_HasPOStockBeenUsedInTargetReference (reason 6) instead of the
	                                        blanket FN_PurchaseOrderHasAnyReceipt (reason 1); other modules keep
	                                        the blanket check. Added ReferenceNumber/ModuleName to #Diagnosis so
	                                        the rejection message can name the specific WO.
    5    28/08/2026   Abhishek Jirawala	#Validated is now an explicitly-typed temp table (was SELECT...INTO)
	                                        so IssuedQty is guaranteed DECIMAL(18,6) - the UOM branch's quantity
	                                        standard - rather than relying on implicit type inheritance.
**************************************************************/
CREATE PROCEDURE [dbo].[USP_UnlinkPurchaseOrderPartReference]
    @tbl_POPartReferenceUnlink [dbo].[POPartReferenceUnlinkType] READONLY,
    @SourceModuleId INT = 0,
    @SourceReferenceId BIGINT = 0,
    @UpdatedBy VARCHAR(256),
    @MasterCompanyId INT = 1
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
    BEGIN TRANSACTION

    IF OBJECT_ID('tempdb..#Validated') IS NOT NULL DROP TABLE #Validated
    CREATE TABLE #Validated (
        PurchaseOrderPartReferenceId BIGINT, PurchaseOrderId BIGINT, PurchaseOrderPartId BIGINT,
        ModuleId INT, ReferenceId BIGINT, ReferencePartId BIGINT, IsKit BIT,
        IssuedQty DECIMAL(18,6), NotFound BIT);

    INSERT INTO #Validated
    SELECT
        T.PurchaseOrderPartReferenceId, T.PurchaseOrderId, T.PurchaseOrderPartId, T.ModuleId, T.ReferenceId,
        T.ReferencePartId, ISNULL(T.IsKit,0) AS IsKit,
        CAST(ISNULL(POR.IssuedQty,0) AS DECIMAL(18,6)) AS IssuedQty,
        CASE WHEN POR.PurchaseOrderPartReferenceId IS NULL THEN 1 ELSE 0 END AS NotFound
    FROM @tbl_POPartReferenceUnlink T
    LEFT JOIN dbo.PurchaseOrderPartReference POR WITH (UPDLOCK, HOLDLOCK)
        ON POR.PurchaseOrderPartReferenceId = T.PurchaseOrderPartReferenceId
        AND ISNULL(POR.IsDeleted,0) = 0 AND ISNULL(POR.IsActive,1) = 1

    IF OBJECT_ID('tempdb..#POReceipt') IS NOT NULL DROP TABLE #POReceipt
    SELECT DISTINCT PurchaseOrderId, dbo.FN_PurchaseOrderHasAnyReceipt(PurchaseOrderId) AS HasAnyReceipt
    INTO #POReceipt FROM #Validated

    IF OBJECT_ID('tempdb..#Diagnosis') IS NOT NULL DROP TABLE #Diagnosis
    SELECT
        V.PurchaseOrderPartReferenceId, V.PurchaseOrderId, V.PurchaseOrderPartId, V.ModuleId, V.ReferenceId, V.ReferencePartId, V.IsKit,
        PO.PurchaseOrderNumber,
        CASE WHEN V.ModuleId = 1 THEN wo.WorkOrderNum
             WHEN V.ModuleId = 2 THEN ro.RepairOrderNumber
             WHEN V.ModuleId = 3 THEN so.SalesOrderNumber
             WHEN V.ModuleId = 4 THEN eso.ExchangeSalesOrderNumber
             WHEN V.ModuleId = 5 THEN sw.SubWorkOrderNo
             WHEN V.ModuleId = 6 THEN l.LotNumber ELSE NULL END AS ReferenceNumber,
        CASE WHEN V.ModuleId = 1 THEN 'Work Order'
             WHEN V.ModuleId = 2 THEN 'Repair Order'
             WHEN V.ModuleId = 3 THEN 'Sales Order'
             WHEN V.ModuleId = 4 THEN 'Exchange'
             WHEN V.ModuleId = 5 THEN 'Sub Work Order'
             WHEN V.ModuleId = 6 THEN 'Lot' ELSE NULL END AS ModuleName,
        CASE
            WHEN V.NotFound = 1 THEN 4
            WHEN V.ReferencePartId IS NULL THEN 5
            WHEN @SourceModuleId <> 0 AND (@SourceModuleId <> V.ModuleId OR @SourceReferenceId <> V.ReferenceId) THEN 5
            WHEN V.ModuleId IN (1,5) AND dbo.FN_HasPOStockBeenUsedInTargetReference(V.PurchaseOrderId, V.PurchaseOrderPartId, V.ModuleId, V.ReferenceId) = 1 THEN 6
            WHEN V.ModuleId NOT IN (1,5) AND ISNULL(PORc.HasAnyReceipt,0) = 1 THEN 1
            WHEN ISNULL(V.IssuedQty,0) > 0 THEN 3
            WHEN @SourceModuleId <> 0 AND dbo.FN_IsModulePartReservedOrIssued(V.ModuleId, V.ReferenceId, V.ReferencePartId, V.IsKit, NULL, NULL) = 1 THEN 2
            ELSE 0
        END AS CannotUnlinkReasonCode
    INTO #Diagnosis
    FROM #Validated V
    LEFT JOIN dbo.PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderId = V.PurchaseOrderId
    LEFT JOIN #POReceipt PORc ON PORc.PurchaseOrderId = V.PurchaseOrderId
    LEFT JOIN dbo.WorkOrder wo WITH (NOLOCK) ON V.ModuleId = 1 AND wo.WorkOrderId = V.ReferenceId
    LEFT JOIN dbo.RepairOrder ro WITH (NOLOCK) ON V.ModuleId = 2 AND ro.RepairOrderId = V.ReferenceId
    LEFT JOIN dbo.SalesOrder so WITH (NOLOCK) ON V.ModuleId = 3 AND so.SalesOrderId = V.ReferenceId
    LEFT JOIN dbo.ExchangeSalesOrder eso WITH (NOLOCK) ON V.ModuleId = 4 AND eso.ExchangeSalesOrderId = V.ReferenceId
    LEFT JOIN dbo.SubWorkOrder sw WITH (NOLOCK) ON V.ModuleId = 5 AND sw.SubWorkOrderId = V.ReferenceId
    LEFT JOIN dbo.Lot l WITH (NOLOCK) ON V.ModuleId = 6 AND l.LotId = V.ReferenceId

    IF EXISTS (SELECT 1 FROM #Diagnosis WHERE CannotUnlinkReasonCode <> 0)
    BEGIN
        -- SELECT before ROLLBACK: ROLLBACK undoes the DDL that created #Diagnosis too
        -- (temp table creation is transactional), so reading it after ROLLBACK fails
        -- with "Invalid object name '#Diagnosis'". Nothing has been written yet on
        -- this path, so rolling back afterwards only releases the UPDLOCK/HOLDLOCK.
        SELECT PurchaseOrderPartReferenceId, PurchaseOrderId, PurchaseOrderNumber, PurchaseOrderPartId, ReferenceId, ReferencePartId,
               ReferenceNumber, ModuleName,
               CAST(0 AS BIT) AS IsUnlinked, CAST(0 AS BIT) AS CanUnlink, CannotUnlinkReasonCode
        FROM #Diagnosis
        ROLLBACK TRAN
        RETURN
    END

    -- distinct affected module lines, before delete
    IF OBJECT_ID('tempdb..#Affected') IS NOT NULL DROP TABLE #Affected
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Id, ModuleId, ReferenceId, ReferencePartId, IsKit, PurchaseOrderPartId
    INTO #Affected
    FROM (SELECT DISTINCT ModuleId, ReferenceId, ReferencePartId, IsKit, PurchaseOrderPartId FROM #Validated) D

    -- null reverse pointers on the PO line itself
    UPDATE POP
    SET WorkOrderMaterialsId = NULL, IsKit = 0, IsSubWO = 0,
        WorkOrderId = CASE WHEN V.ModuleId = 1 THEN NULL ELSE WorkOrderId END,
        WorkOrderNo = CASE WHEN V.ModuleId = 1 THEN NULL ELSE WorkOrderNo END,
        SubWorkOrderId = CASE WHEN V.ModuleId = 5 THEN NULL ELSE SubWorkOrderId END,
        SubWorkOrderNo = CASE WHEN V.ModuleId = 5 THEN NULL ELSE SubWorkOrderNo END,
        SalesOrderId = CASE WHEN V.ModuleId = 3 THEN NULL ELSE SalesOrderId END,
        SalesOrderNo = CASE WHEN V.ModuleId = 3 THEN NULL ELSE SalesOrderNo END,
        ExchangeSalesOrderId = CASE WHEN V.ModuleId = 4 THEN NULL ELSE ExchangeSalesOrderId END,
        ExchangeSalesOrderNo = CASE WHEN V.ModuleId = 4 THEN NULL ELSE ExchangeSalesOrderNo END,
        LotId = CASE WHEN V.ModuleId = 6 THEN NULL ELSE LotId END,
        IsLotAssigned = CASE WHEN V.ModuleId = 6 THEN 0 ELSE IsLotAssigned END,
        UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
    FROM dbo.PurchaseOrderPart POP
    INNER JOIN #Validated V ON V.PurchaseOrderPartId = POP.PurchaseOrderPartRecordId

    -- hard delete the junction rows
    DELETE POR
    FROM dbo.PurchaseOrderPartReference POR
    INNER JOIN #Validated V ON V.PurchaseOrderPartReferenceId = POR.PurchaseOrderPartReferenceId

    -- re-point / blank / flag-Multiple the module grid's scalar PO fields
    DECLARE @LoopId INT = 1, @TotalAffected INT = (SELECT COUNT(1) FROM #Affected)
    DECLARE @ModuleId INT, @ReferenceId BIGINT, @ReferencePartId BIGINT, @IsKitRow BIT
    DECLARE @SurvivingCount INT, @SurvivingPOPartId BIGINT

    -- sp_UpdatePOPartReferenceDetail returns a "value" rowset of its own (PurchaseOrderNumber);
    -- capture it via INSERT...EXEC so it doesn't leak out as an extra, wrongly-shaped result set
    -- ahead of this procedure's own diagnosis SELECT.
    IF OBJECT_ID('tempdb..#DummyPOUpdate') IS NOT NULL DROP TABLE #DummyPOUpdate
    CREATE TABLE #DummyPOUpdate (PurchaseOrderNumber VARCHAR(50) NULL)

    WHILE @LoopId <= @TotalAffected
    BEGIN
        SELECT @ModuleId = ModuleId, @ReferenceId = ReferenceId, @ReferencePartId = ReferencePartId, @IsKitRow = IsKit
        FROM #Affected WHERE Id = @LoopId

        SELECT @SurvivingCount = COUNT(1), @SurvivingPOPartId = MIN(POR.PurchaseOrderPartId)
        FROM dbo.PurchaseOrderPartReference POR WITH (NOLOCK)
        WHERE POR.ModuleId = @ModuleId AND POR.ReferenceId = @ReferenceId
              AND ISNULL(POR.IsDeleted,0) = 0 AND ISNULL(POR.IsActive,1) = 1

        IF @SurvivingCount = 0
        BEGIN
            IF @ModuleId = 1 AND ISNULL(@IsKitRow,0) = 0
                UPDATE dbo.WorkOrderMaterials SET POId = NULL, PONum = NULL, PONextDlvrDate = NULL, QtyOnOrder = 0, QtyOnBkOrder = 0, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy WHERE WorkOrderMaterialsId = @ReferencePartId
            ELSE IF @ModuleId = 1 AND ISNULL(@IsKitRow,0) = 1
                UPDATE dbo.WorkOrderMaterialsKit SET POId = NULL, PONum = NULL, PONextDlvrDate = NULL, QtyOnOrder = 0, QtyOnBkOrder = 0, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy WHERE WorkOrderMaterialsKitId = @ReferencePartId
            ELSE IF @ModuleId = 5
                UPDATE dbo.SubWorkOrderMaterials SET POId = NULL, PONum = NULL, PONextDlvrDate = NULL, QtyOnOrder = 0, QtyOnBkOrder = 0, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy WHERE SubWorkOrderMaterialsId = @ReferencePartId
            ELSE IF @ModuleId = 3
                UPDATE dbo.SalesOrderPartV1 SET POId = NULL, PONumber = NULL, PONextDlvrDate = NULL, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy WHERE SalesOrderPartId = @ReferencePartId
            ELSE IF @ModuleId = 4
                UPDATE dbo.ExchangeSalesOrderPart SET POId = NULL, PONumber = NULL, PONextDlvrDate = NULL, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy WHERE ExchangeSalesOrderPartId = @ReferencePartId
        END
        ELSE IF @SurvivingCount = 1
        BEGIN
            INSERT INTO #DummyPOUpdate EXEC dbo.sp_UpdatePOPartReferenceDetail @PurchaseOrderPartId = @SurvivingPOPartId
        END
        ELSE -- 2 or more surviving links: the scalar PO field can't represent all of them
        BEGIN
            IF @ModuleId = 1 AND ISNULL(@IsKitRow,0) = 0
                UPDATE dbo.WorkOrderMaterials SET POId = NULL, PONum = 'Multiple', UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy WHERE WorkOrderMaterialsId = @ReferencePartId
            ELSE IF @ModuleId = 1 AND ISNULL(@IsKitRow,0) = 1
                UPDATE dbo.WorkOrderMaterialsKit SET POId = NULL, PONum = 'Multiple', UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy WHERE WorkOrderMaterialsKitId = @ReferencePartId
            ELSE IF @ModuleId = 5
                UPDATE dbo.SubWorkOrderMaterials SET POId = NULL, PONum = 'Multiple', UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy WHERE SubWorkOrderMaterialsId = @ReferencePartId
            ELSE IF @ModuleId = 3
                UPDATE dbo.SalesOrderPartV1 SET POId = NULL, PONumber = 'Multiple', UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy WHERE SalesOrderPartId = @ReferencePartId
            ELSE IF @ModuleId = 4
                UPDATE dbo.ExchangeSalesOrderPart SET POId = NULL, PONumber = 'Multiple', UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy WHERE ExchangeSalesOrderPartId = @ReferencePartId
        END

        SET @LoopId += 1
    END

    -- history entries for WO / SubWO unlinks
    IF OBJECT_ID('tempdb..#AffectedWO') IS NOT NULL DROP TABLE #AffectedWO
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Id, ModuleId, ReferenceId
    INTO #AffectedWO
    FROM (SELECT DISTINCT ModuleId, ReferenceId FROM #Affected WHERE ModuleId IN (1,5)) D

    DECLARE @HistLoopId INT = 1, @HistTotal INT = (SELECT COUNT(1) FROM #AffectedWO)
    DECLARE @HistModuleId INT, @HistReferenceId BIGINT, @TemplateBody VARCHAR(MAX), @RefNum VARCHAR(100)
    DECLARE @HistNow DATETIME = GETUTCDATE()

    WHILE @HistLoopId <= @HistTotal
    BEGIN
        SELECT @HistModuleId = ModuleId, @HistReferenceId = ReferenceId FROM #AffectedWO WHERE Id = @HistLoopId

        IF @HistModuleId = 1
            SELECT @RefNum = WorkOrderNum FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @HistReferenceId
        ELSE
            SELECT @RefNum = SubWorkOrderNo FROM dbo.SubWorkOrder WITH (NOLOCK) WHERE SubWorkOrderId = @HistReferenceId

        SET @TemplateBody = NULL
        SELECT TOP 1 @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH (NOLOCK) WHERE TemplateCode = 'UnlinkPO'

        IF @TemplateBody IS NOT NULL
        BEGIN
            SET @TemplateBody = REPLACE(@TemplateBody, '##RefNum##', ISNULL(@RefNum, ''))
            EXEC dbo.USP_History @HistModuleId, @HistReferenceId, 0, 0, '', '', @TemplateBody, 'UnlinkPO', @MasterCompanyId, @UpdatedBy, @HistNow, @UpdatedBy, @HistNow
        END

        SET @HistLoopId += 1
    END

    COMMIT TRANSACTION

    SELECT PurchaseOrderPartReferenceId, PurchaseOrderId, PurchaseOrderNumber, PurchaseOrderPartId, ReferenceId, ReferencePartId,
           ReferenceNumber, ModuleName,
           CAST(1 AS BIT) AS IsUnlinked, CAST(1 AS BIT) AS CanUnlink, 0 AS CannotUnlinkReasonCode
    FROM #Diagnosis

    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            ROLLBACK TRAN;
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
            , @AdhocComments VARCHAR(150) = 'USP_UnlinkPurchaseOrderPartReference'
            , @ProcedureParameters VARCHAR(3000) = '@SourceModuleId = ' + ISNULL(CAST(@SourceModuleId AS VARCHAR(20)), '')
            , @ApplicationName VARCHAR(100) = 'PAS'
        EXEC dbo.spLogException
            @DatabaseName = @DatabaseName
            , @AdhocComments = @AdhocComments
            , @ProcedureParameters = @ProcedureParameters
            , @ApplicationName = @ApplicationName
            , @ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN(1);
    END CATCH
END
