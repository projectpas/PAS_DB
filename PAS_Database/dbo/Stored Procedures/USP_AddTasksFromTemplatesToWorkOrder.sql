/*************************************************************             
** File:   [USP_AddTasksFromTemplatesToWorkOrder]
** Author:   SUMIT KUMAR
** Description: Bulk adds workflow tasks to a Work Order, copying child records (materials, labor, charges, assets, instructions).
** Purpose: Copier logic for WO template tasks.
** Date:   07/02/2026
** History:
** PR   Date         Author           Change Description
** --   --------     -------          ------------------
** 1    07/06/2026   SUMIT KUMAR      Created

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

            -- SECTION 1: Resolve or Initialize the WorkOrderWorkFlow ID
            -- Ensures a valid WorkOrderWorkFlow header exists for the specified Work Order and Part Number.
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

            -- SECTION 2: Parse and Load XML Task Input
            -- Extracts workflowId and taskId inputs from the provided XML parameter into a local temporary table.
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

            -- SECTION 3: Retrieve Part Restrictions & Base Data
            -- Fetches PMA/DER restrictions from the Work Order Part Number to filter material copies.
            DECLARE @IsDER BIT = 0, @IsPMA BIT = 0;
            SELECT @IsDER = ISNULL(IsDER, 0), @IsPMA = ISNULL(IsPMA, 0) 
            FROM dbo.WorkOrderPartNumber WITH (NOLOCK) 
            WHERE ID = @WorkOrderPartNumberId;

            -- Fetches standard 'PENDING' task status identifier.
            DECLARE @PendingTaskStatusId BIGINT;
            SELECT TOP 1 @PendingTaskStatusId = TaskStatusId 
            FROM dbo.TaskStatus WITH (NOLOCK) 
            WHERE [Description] = 'PENDING' AND MasterCompanyId = @MasterCompanyId;

            DECLARE @TotalRows INT, @CurrentRow INT = 1;
            SELECT @TotalRows = COUNT(1) FROM #NewTasks;

            -- SECTION 4: Iterative Task Processing Loop
            -- Iterates through each incoming task to copy its definition and related records.
            WHILE (@CurrentRow <= @TotalRows)
            BEGIN
                DECLARE @WfId BIGINT, @TskId BIGINT;
                SELECT @WfId = WorkflowId, @TskId = TaskId FROM #NewTasks WHERE ID = @CurrentRow;

                -- Check duplicates: Verify task is not already present in the active Work Order Part Number.
                IF NOT EXISTS (SELECT 1 FROM dbo.WorkOrderTask WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId AND WorkOrderPartNumberId = @WorkOrderPartNumberId AND TaskId = @TskId AND IsActive = 1 AND IsDeleted = 0)
                BEGIN
                    -- Calculate next sequence number (focusing on active, non-deleted tasks to align with frontend lists)
                    DECLARE @NextSeq INT = 1;
                    SELECT @NextSeq = ISNULL(MAX(TRY_CAST(SequenceNumber AS INT)), 0) + 1 
                    FROM dbo.WorkOrderTask WITH(NOLOCK) 
                    WHERE WorkOrderId = @WorkOrderId 
                      AND WorkOrderPartNumberId = @WorkOrderPartNumberId
                      AND IsActive = 1
                      AND IsDeleted = 0;

                    DECLARE @SeqStr VARCHAR(50) = RIGHT('00' + CAST(@NextSeq AS VARCHAR(10)), 3);

                    -- Insert WorkOrderTask header
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
                        T.[Description],
                        1
                    FROM dbo.Task T WITH(NOLOCK)
                    WHERE T.TaskId = @TskId;

                    SET @NewTaskId = SCOPE_IDENTITY();

                    -- Insert WorkOrderTaskDetails entry
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

                    -- SUB-SECTION 4.1: Copy Materials (checking customer part restrictions)
                    DECLARE @ReplaceProvisionId BIGINT;
                    SELECT TOP 1 @ReplaceProvisionId = ProvisionId 
                    FROM dbo.Provision WITH (NOLOCK)
                    WHERE StatusCode = 'REPLACE' AND ISNULL(IsActive, 1) = 1 AND ISNULL(IsDeleted, 0) = 0;

                    INSERT INTO dbo.WorkOrderMaterials (
                        CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, MasterCompanyId, WorkOrderId, WorkFlowWorkOrderId,
                        ItemMasterId, TaskId, ConditionCodeId, MaterialMandatoriesId, ItemClassificationId, Quantity, UnitOfMeasureId, UnitCost, ExtendedCost,
                        Memo, IsDeferred, ProvisionId, Figure, Item, IsFromWorkFlow, WOPartNoId
                    )
                    SELECT 
                        @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @MasterCompanyId, @WorkOrderId, @WorkFlowWorkOrderId,
                        wfm.ItemMasterId, @NewTaskId, wfm.ConditionCodeId, wfm.MaterialMandatoriesId, wfm.ItemClassificationId, wfm.Quantity, wfm.UnitOfMeasureId, ISNULL(wfm.UnitCost, 0), ISNULL(wfm.ExtendedCost, 0),
                        wfm.Memo, wfm.IsDeferred, ISNULL(wfm.ProvisionId, @ReplaceProvisionId), wfm.Figure, wfm.Item, 1, @WorkOrderPartNumberId
                    FROM dbo.WorkflowMaterial wfm WITH(NOLOCK)
                    INNER JOIN dbo.ItemMaster im WITH(NOLOCK) ON wfm.ItemMasterId = im.ItemMasterId
                    WHERE wfm.WorkflowId = @WfId 
                      AND wfm.TaskId = @TskId 
                      AND ISNULL(wfm.IsDeleted, 0) = 0
                      AND NOT (
                          (@IsDER = 1 AND @IsPMA = 1 AND (ISNULL(im.IsDER, 0) = 1 OR ISNULL(im.IsPMA, 0) = 1)) OR
                          (@IsDER = 0 AND @IsPMA = 1 AND ISNULL(im.IsPMA, 0) = 1) OR
                          (@IsDER = 1 AND @IsPMA = 0 AND ISNULL(im.IsDER, 0) = 1)
                      );

                    -- SUB-SECTION 4.2: Copy Labor Details
                    -- Resolves/creates Labor Header based on dynamic Management Structure settings.
                    DECLARE @LaborHeaderId BIGINT;
                    SELECT TOP 1 @LaborHeaderId = WorkOrderLaborHeaderId
                    FROM dbo.WorkOrderLaborHeader WITH (NOLOCK) 
                    WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(IsDeleted, 0) = 0;

                    IF (@LaborHeaderId IS NULL AND EXISTS (SELECT 1 FROM dbo.WorkflowExpertiseList WITH(NOLOCK) WHERE WorkflowId = @WfId AND TaskId = @TskId AND ISNULL(IsDeleted, 0) = 0))
                    BEGIN
                        DECLARE @ManagementStructureId INT, @LaborHoursId INT, @laborHoursMedthodId INT, @ExpertiseId BIGINT;
                        SELECT TOP 1 @ManagementStructureId = ManagementStructureId 
                        FROM dbo.WorkOrderPartNumber WITH (NOLOCK) 
                        WHERE ID = @WorkOrderPartNumberId AND MasterCompanyId = @MasterCompanyId;

                        SELECT TOP 1 @LaborHoursId = ISNULL(LaborHoursId, 1), @laborHoursMedthodId = ISNULL(laborHoursMedthodId, 1) 
                        FROM dbo.LaborOHSettings WITH (NOLOCK) 
                        WHERE ManagementStructureId = @ManagementStructureId AND MasterCompanyId = @MasterCompanyId;

                        SELECT TOP 1 @ExpertiseId = CAST(ExpertiseTypeId AS INT) 
                        FROM dbo.WorkflowExpertiseList WITH (NOLOCK) 
                        WHERE WorkflowId = @WfId AND TaskId = @TskId AND ISNULL(IsDeleted, 0) = 0;

                        INSERT INTO dbo.WorkOrderLaborHeader (
                            WorkOrderId, WorkFlowWorkOrderId, DataEnteredBy, HoursorClockorScan, WorkOrderHoursType,
                            MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, ExpertiseId, EmployeeId, WOPartNoId
                        )
                        VALUES (
                            @WorkOrderId, @WorkFlowWorkOrderId, 1, @laborHoursMedthodId, @LaborHoursId,
                            @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @ExpertiseId, 1, @WorkOrderPartNumberId
                        );
                        SET @LaborHeaderId = SCOPE_IDENTITY();
                    END

                    -- Inserts individual labor lines converting EstimatedHours from HH.MM format into true decimals.
                    IF (@LaborHeaderId IS NOT NULL)
                    BEGIN
                        INSERT INTO dbo.WorkOrderLabor (
                            CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, ExpertiseId, MasterCompanyId, [Hours], AdjustedHours, BurdaenRatePercentageId,
                            BurdenRateAmount, DirectLaborOHCost, TotalCostPerHour, TotalCost, Memo, TaskId, TaskStatusId, EmployeeId, BillableId, IsFromWorkFlow, WorkOrderLaborHeaderId, StandardHours, StandardMinute, StatusChangedDate
                        )
                        SELECT 
                            @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, wfe.ExpertiseTypeId, @MasterCompanyId, wfe.EstimatedHours, wfe.EstimatedHours, wfe.OverheadburdenPercentId,
                            ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0), ISNULL(wfe.LaborDirectRate, 0),
                            ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0),
                            ISNULL((
                                CASE 
                                    WHEN CHARINDEX('.', CAST(wfe.EstimatedHours AS VARCHAR(100))) > 0 
                                    THEN 
                                        TRY_CAST(LEFT(CAST(wfe.EstimatedHours AS VARCHAR(100)), CHARINDEX('.', CAST(wfe.EstimatedHours AS VARCHAR(100))) - 1) AS DECIMAL(18,2)) 
                                        + (TRY_CAST(SUBSTRING(CAST(wfe.EstimatedHours AS VARCHAR(100)), CHARINDEX('.', CAST(wfe.EstimatedHours AS VARCHAR(100))) + 1, LEN(CAST(wfe.EstimatedHours AS VARCHAR(100)))) AS DECIMAL(18,2)) / 60.0)
                                    ELSE wfe.EstimatedHours 
                                END
                            ) * (ISNULL(wfe.LaborDirectRate, 0) + ISNULL((ISNULL(wfe.OverheadBurden, 0) * ISNULL(wfe.LaborDirectRate, 0)) / 100, 0)), 0),
                            wfe.Memo, @NewTaskId, ISNULL(@PendingTaskStatusId, 1), NULL, 1, 1, @LaborHeaderId, T.StandardHours, T.StandardMinute, GETUTCDATE()
                        FROM dbo.WorkflowExpertiseList wfe WITH(NOLOCK)
                        JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = wfe.TaskId
                        WHERE wfe.WorkflowId = @WfId AND wfe.TaskId = @TskId AND ISNULL(wfe.IsDeleted, 0) = 0;
                    END

                    -- SUB-SECTION 4.3: Copy Charges
                    INSERT INTO dbo.WorkOrderCharges (
                        CreatedBy, CreatedDate, IsActive, IsDeleted, ChargesTypeId, MasterCompanyId, Quantity, UpdatedBy, UpdatedDate, VendorId,
                        WorkOrderId, WorkFlowWorkOrderId, Description, ExtendedCost, IsFromWorkFlow, TaskId, UnitCost, ReferenceNo, WOPartNoId
                    )
                    SELECT 
                        @CreatedBy, GETUTCDATE(), 1, 0, wfc.WorkflowChargeTypeId, @MasterCompanyId, ISNULL(wfc.Quantity, 0), @CreatedBy, GETUTCDATE(), wfc.VendorId,
                        @WorkOrderId, @WorkFlowWorkOrderId, wfc.Description, ISNULL(wfc.ExtendedCost, 0), 1, @NewTaskId, ISNULL(wfc.UnitCost, 0), '', @WorkOrderPartNumberId
                    FROM dbo.WorkflowChargesList wfc WITH(NOLOCK)
                    WHERE wfc.WorkflowId = @WfId AND wfc.TaskId = @TskId AND ISNULL(wfc.IsDeleted, 0) = 0;

                    -- SUB-SECTION 4.4: Copy Assets/Equipments
                    INSERT INTO dbo.WorkOrderAssets (
                        AssetRecordId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, MasterCompanyId, Quantity, WorkOrderId,
                        WorkFlowWorkOrderId, TaskId, IsFromWorkFlow, WOPartNoId
                    )
                    SELECT 
                        wfe.AssetId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @MasterCompanyId, ISNULL(wfe.Quantity, 0), @WorkOrderId,
                        @WorkFlowWorkOrderId, @NewTaskId, 1, @WorkOrderPartNumberId
                    FROM dbo.WorkflowEquipmentList wfe WITH(NOLOCK)
                    WHERE wfe.WorkflowId = @WfId AND wfe.TaskId = @TskId AND ISNULL(wfe.IsDeleted, 0) = 0;

                    -- SUB-SECTION 4.5: Copy Directions (Instructions)
                    -- Iterates and inserts hierarchical instruction steps (Parents and Children).
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
