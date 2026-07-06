/*************************************************************             
** File:   [USP_AddTasksFromTemplatesToWorkOrder]
** Author:   Antigravity
** Description: Bulk adds workflow tasks to a Work Order, copying child records (materials, labor, charges, assets, instructions).
** Purpose:
** Date:   07/02/2026
**************************************************************/
CREATE PROCEDURE [dbo].[USP_AddTasksFromTemplatesToWorkOrder]
(
    @WorkOrderId BIGINT,
    @WorkOrderPartNumberId BIGINT,
    @TaskTemplatesXml VARCHAR(MAX),
    @CreatedBy VARCHAR(100),
    @MasterCompanyId INT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION
        BEGIN
            DECLARE @Xml XML = CAST(@TaskTemplatesXml AS XML);

            -- Determine or Create WorkFlowWorkOrderId
            DECLARE @WorkFlowWorkOrderId BIGINT;
            SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId 
            FROM dbo.WorkOrderWorkFlow WITH (NOLOCK) 
            WHERE WorkOrderId = @WorkOrderId AND WorkOrderPartNoId = @WorkOrderPartNumberId;

            IF (@WorkFlowWorkOrderId IS NULL OR @WorkFlowWorkOrderId = 0)
            BEGIN
                INSERT INTO dbo.WorkOrderWorkFlow (WorkOrderId, WorkOrderPartNoId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
                VALUES (@WorkOrderId, @WorkOrderPartNumberId, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);

                SET @WorkFlowWorkOrderId = SCOPE_IDENTITY();
            END

            -- Load XML tasks
            CREATE TABLE #NewTasks (
                ID INT IDENTITY(1,1),
                WorkflowId BIGINT,
                TaskId BIGINT
            );

            INSERT INTO #NewTasks (WorkflowId, TaskId)
            SELECT 
                T.c.value('(workflowId)[1]', 'BIGINT'),
                T.c.value('(taskId)[1]', 'BIGINT')
            FROM @Xml.nodes('/tasks/task') T(c);

            DECLARE @TotalRows INT, @CurrentRow INT = 1;
            SELECT @TotalRows = COUNT(1) FROM #NewTasks;

            WHILE (@CurrentRow <= @TotalRows)
            BEGIN
                DECLARE @WfId BIGINT, @TskId BIGINT;
                SELECT @WfId = WorkflowId, @TskId = TaskId FROM #NewTasks WHERE ID = @CurrentRow;

                -- Check duplicates
                IF NOT EXISTS (SELECT 1 FROM dbo.WorkOrderTask WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkOrderPartNumberId = @WorkOrderPartNumberId AND TaskId = @TskId AND IsActive = 1 AND IsDeleted = 0)
                BEGIN
                    -- Calculate next sequence number
                    DECLARE @NextSeq INT = 1;
                    SELECT @NextSeq = ISNULL(MAX(TRY_CAST(SequenceNumber AS INT)), 0) + 1 
                    FROM dbo.WorkOrderTask WITH(NOLOCK) 
                    WHERE WorkOrderId = @WorkOrderId AND WorkOrderPartNumberId = @WorkOrderPartNumberId;

                    DECLARE @SeqStr VARCHAR(50) = RIGHT('00' + CAST(@NextSeq AS VARCHAR(10)), 3);

                    -- Insert WorkOrderTask
                    DECLARE @NewTaskId BIGINT;
                    INSERT INTO dbo.WorkOrderTask (
                        WorkOrderId, WorkFlowWorkOrderId, TaskId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted,
                        WorkOrderPartNumberId, SequenceNumber, IsIncludeInPrint, HasInstruction, TaskName, IsFromWorkFlow
                    )
                    SELECT TOP 1
                        @WorkOrderId,
                        @WorkFlowWorkOrderId,
                        @TskId,
                        @MasterCompanyId,
                        @CreatedBy,
                        @CreatedBy,
                        GETUTCDATE(),
                        GETUTCDATE(),
                        1,
                        0,
                        @WorkOrderPartNumberId,
                        @SeqStr,
                        T.IsPrintInWO,
                        CASE WHEN EXISTS (SELECT 1 FROM dbo.WorkflowDirection WITH(NOLOCK) WHERE WorkflowId = @WfId AND TaskId = @TskId AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsActive, 0) = 1) THEN 1 ELSE 0 END,
                        T.TaskName,
                        1
                    FROM dbo.Task T WITH(NOLOCK)
                    WHERE T.TaskId = @TskId;

                    SET @NewTaskId = SCOPE_IDENTITY();

                    -- Insert WorkOrderTaskDetails
                    INSERT INTO dbo.WorkOrderTaskDetails (
                        WorkOrderTaskId, Descrepancy, Resolution, HasInstruction, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
                        IsActive, IsDeleted, PrintInWO, PrintInWOQ, IsPrintInspector, IsPrintTechnician, IsPrintAdmin
                    )
                    SELECT TOP 1
                        @NewTaskId,
                        wft.Descrepancy,
                        wft.Resolution,
                        CASE WHEN EXISTS (SELECT 1 FROM dbo.WorkflowDirection WITH(NOLOCK) WHERE WorkflowId = @WfId AND TaskId = @TskId AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(IsActive, 0) = 1) THEN 1 ELSE 0 END,
                        @MasterCompanyId,
                        @CreatedBy,
                        @CreatedBy,
                        GETUTCDATE(),
                        GETUTCDATE(),
                        1,
                        0,
                        1,
                        1,
                        0,
                        0,
                        0
                    FROM dbo.WorkflowTask wft WITH(NOLOCK)
                    WHERE wft.WorkflowId = @WfId AND wft.TaskId = @TskId;

                    -- 1. Copy Materials
                    INSERT INTO dbo.WorkOrderMaterials (
                        CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, MasterCompanyId, WorkOrderId, WorkFlowWorkOrderId,
                        ItemMasterId, TaskId, ConditionCodeId, MaterialMandatoriesId, ItemClassificationId, Quantity, UnitOfMeasureId, UnitCost, ExtendedCost,
                        Memo, IsDeferred, ProvisionId, Figure, Item, IsFromWorkFlow, WOPartNoId
                    )
                    SELECT 
                        @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @MasterCompanyId, @WorkOrderId, @WorkFlowWorkOrderId,
                        wfm.ItemMasterId, @NewTaskId, wfm.ConditionCodeId, wfm.MaterialMandatoriesId, wfm.ItemClassificationId, wfm.Quantity, wfm.UnitOfMeasureId, ISNULL(wfm.UnitCost, 0), ISNULL(wfm.ExtendedCost, 0),
                        wfm.Memo, wfm.IsDeferred, wfm.ProvisionId, wfm.Figure, wfm.Item, 1, @WorkOrderPartNumberId
                    FROM dbo.WorkflowMaterial wfm WITH(NOLOCK)
                    WHERE wfm.WorkflowId = @WfId AND wfm.TaskId = @TskId AND ISNULL(wfm.IsDeleted, 0) = 0;

                    -- 2. Copy Labor
                    DECLARE @LaborHeaderId BIGINT;
                    SELECT TOP 1 @LaborHeaderId = WorkOrderLaborHeaderId
                    FROM dbo.WorkOrderLaborHeader WITH (NOLOCK) 
                    WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(IsDeleted, 0) = 0;

                    IF (@LaborHeaderId IS NULL AND EXISTS (SELECT 1 FROM dbo.WorkflowExpertiseList WITH(NOLOCK) WHERE WorkflowId = @WfId AND TaskId = @TskId AND ISNULL(IsDeleted, 0) = 0))
                    BEGIN
                        INSERT INTO dbo.WorkOrderLaborHeader (
                            WorkOrderId, WorkFlowWorkOrderId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, DataEnteredBy, HoursorClockId
                        )
                        VALUES (
                            @WorkOrderId, @WorkFlowWorkOrderId, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, 1, 1
                        );
                        SET @LaborHeaderId = SCOPE_IDENTITY();
                    END

                    IF (@LaborHeaderId IS NOT NULL)
                    BEGIN
                        INSERT INTO dbo.WorkOrderLabor (
                            CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, ExpertiseId, MasterCompanyId, [Hours], AdjustedHours, BurdaenRatePercentageId,
                            BurdenRateAmount, DirectLaborOHCost, TotalCostPerHour, TotalCost, Memo, TaskId, TaskStatusId, BillableId, IsFromWorkFlow, WorkOrderLaborHeaderId, StandardHours, StandardMinute, StatusChangedDate
                        )
                        SELECT 
                            @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, wfe.ExpertiseTypeId, @MasterCompanyId, wfe.EstimatedHours, wfe.EstimatedHours, wfe.OverheadburdenPercentId,
                            ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0), ISNULL(wfe.LaborDirectRate, 0),
                            ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0),
                            ISNULL(wfe.EstimatedHours * (ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0)), 0),
                            wfe.Memo, @NewTaskId, 1, 1, 1, @LaborHeaderId, T.StandardHours, T.StandardMinute, GETUTCDATE()
                        FROM dbo.WorkflowExpertiseList wfe WITH(NOLOCK)
                        JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = wfe.TaskId
                        WHERE wfe.WorkflowId = @WfId AND wfe.TaskId = @TskId AND ISNULL(wfe.IsDeleted, 0) = 0;
                    END

                    -- 3. Copy Charges
                    INSERT INTO dbo.WorkOrderCharges (
                        CreatedBy, CreatedDate, IsActive, IsDeleted, ChargesTypeId, MasterCompanyId, Quantity, UpdatedBy, UpdatedDate, VendorId,
                        WorkOrderId, WorkFlowWorkOrderId, Description, ExtendedCost, IsFromWorkFlow, TaskId, UnitCost, ReferenceNo, WOPartNoId
                    )
                    SELECT 
                        @CreatedBy, GETUTCDATE(), 1, 0, wfc.WorkflowChargeTypeId, @MasterCompanyId, ISNULL(wfc.Quantity, 0), @CreatedBy, GETUTCDATE(), wfc.VendorId,
                        @WorkOrderId, @WorkFlowWorkOrderId, wfc.Description, ISNULL(wfc.ExtendedCost, 0), 1, @NewTaskId, ISNULL(wfc.UnitCost, 0), '', @WorkOrderPartNumberId
                    FROM dbo.WorkflowChargesList wfc WITH(NOLOCK)
                    WHERE wfc.WorkflowId = @WfId AND wfc.TaskId = @TskId AND ISNULL(wfc.IsDeleted, 0) = 0;

                    -- 4. Copy Assets/Equipments
                    INSERT INTO dbo.WorkOrderAssets (
                        AssetRecordId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, MasterCompanyId, Quantity, WorkOrderId,
                        WorkFlowWorkOrderId, TaskId, IsFromWorkFlow, WOPartNoId
                    )
                    SELECT 
                        wfe.AssetId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @MasterCompanyId, ISNULL(wfe.Quantity, 0), @WorkOrderId,
                        @WorkFlowWorkOrderId, @NewTaskId, 1, @WorkOrderPartNumberId
                    FROM dbo.WorkflowEquipmentList wfe WITH(NOLOCK)
                    WHERE wfe.WorkflowId = @WfId AND wfe.TaskId = @TskId AND ISNULL(wfe.IsDeleted, 0) = 0;

                    -- 5. Copy Directions (Instructions)
                    IF OBJECT_ID(N'tempdb..#tmpWFDir') IS NOT NULL
                    BEGIN
                        DROP TABLE #tmpWFDir;
                    END

                    CREATE TABLE #tmpWFDir (
                        ID INT IDENTITY(1,1),
                        WorkflowDirectionId BIGINT,
                        ParentId BIGINT,
                        NewParentId BIGINT,
                        IsParent BIT,
                        InstructionTitle VARCHAR(8000),
                        SequenceNumber VARCHAR(100),
                        InstructionDetails VARCHAR(MAX),
                        IsPrintInWO BIT
                    );

                    -- Insert parents
                    INSERT INTO #tmpWFDir (WorkflowDirectionId, ParentId, IsParent, InstructionTitle, SequenceNumber, InstructionDetails, IsPrintInWO)
                    SELECT 
                        WFD.WorkflowDirectionId,
                        NULL,
                        1,
                        WFD.[Action],
                        CAST(ROW_NUMBER() OVER (ORDER BY WFD.WorkflowDirectionId) AS VARCHAR(100)),
                        WFD.[Description],
                        1
                    FROM dbo.WorkflowDirection WFD WITH(NOLOCK)
                    WHERE WFD.WorkflowId = @WfId 
                      AND ISNULL(WFD.IsTaskDetails, 0) = 0
                      AND WFD.TaskId = @TskId
                      AND ISNULL(WFD.IsParent, 0) = 1
                      AND ISNULL(WFD.IsActive, 0) = 1 
                      AND ISNULL(WFD.IsDeleted, 0) = 0;

                    -- Insert children
                    INSERT INTO #tmpWFDir (WorkflowDirectionId, ParentId, IsParent, InstructionTitle, SequenceNumber, InstructionDetails, IsPrintInWO)
                    SELECT 
                        WFD.WorkflowDirectionId,
                        WFD.ParentId,
                        0,
                        WFD.[Action],
                        CAST(ROW_NUMBER() OVER (PARTITION BY WFD.ParentId ORDER BY WFD.WorkflowDirectionId) AS VARCHAR(100)),
                        WFD.[Description],
                        1
                    FROM dbo.WorkflowDirection WFD WITH(NOLOCK)
                    WHERE WFD.WorkflowId = @WfId 
                      AND ISNULL(WFD.IsTaskDetails, 0) = 0
                      AND WFD.TaskId = @TskId
                      AND ISNULL(WFD.IsParent, 0) = 0
                      AND ISNULL(WFD.IsActive, 0) = 1 
                      AND ISNULL(WFD.IsDeleted, 0) = 0;

                    DECLARE @WFDirTotal INT, @WFDirCurrent INT = 1;
                    SELECT @WFDirTotal = COUNT(1) FROM #tmpWFDir;

                    WHILE (@WFDirCurrent <= @WFDirTotal)
                    BEGIN
                        DECLARE @ParentWfdId BIGINT, @NewInstId BIGINT;
                        SELECT @ParentWfdId = WorkflowDirectionId FROM #tmpWFDir WHERE ID = @WFDirCurrent;

                        INSERT INTO dbo.WorkOrderTaskInstruction (
                            WorkOrderTaskId, ParentId, IsParent, InstructionTitle, SequenceNumber, InstructionDetails, PrintInWO, PrintInWOQ,
                            MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, IsFromWorkFlow
                        )
                        SELECT 
                            @NewTaskId,
                            NewParentId,
                            IsParent,
                            InstructionTitle,
                            SequenceNumber,
                            InstructionDetails,
                            IsPrintInWO,
                            IsPrintInWO,
                            @MasterCompanyId,
                            @CreatedBy,
                            @CreatedBy,
                            GETUTCDATE(),
                            GETUTCDATE(),
                            1,
                            0,
                            1
                        FROM #tmpWFDir 
                        WHERE ID = @WFDirCurrent;

                        SET @NewInstId = SCOPE_IDENTITY();

                        UPDATE #tmpWFDir 
                        SET NewParentId = @NewInstId 
                        WHERE ParentId = @ParentWfdId;

                        SET @WFDirCurrent += 1;
                    END

                    IF OBJECT_ID(N'tempdb..#tmpWFDir') IS NOT NULL
                    BEGIN
                        DROP TABLE #tmpWFDir;
                    END

                    -- Add history row
                    EXEC [dbo].[USP_AddWorkOrderTaskHistory] @NewTaskId, @CreatedBy, 0, @NextSeq;
                END

                SET @CurrentRow += 1;
            END

            DROP TABLE #NewTasks;
        END
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name();
        DECLARE @AdhocComments VARCHAR(150) = 'USP_AddTasksFromTemplatesToWorkOrder';
        DECLARE @ProcedureParameters VARCHAR(3000) = '@WorkOrderId = ' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100));
        EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters, @ApplicationName = 'PAS', @ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database.', 16, 1);
    END CATCH
END
