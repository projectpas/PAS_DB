/***************************************************************  
 ** File:   [USP_AddUpdateWorkOrderTasks]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used add or update sales order part details
 ** Purpose:
 ** Date:   12/24/2024

 ** Change History
 **************************************************************
 ** PR   Date         Author  		 Change Description
 ** --   --------     -------		 --------------------------------
    1    12/24/2024   Vishal Suthar	 Created
    2    01/17/2025   Vishal Suthar	 Added History for Add and Update
    3    02/06/2025   Ekta Chandegra Added Task Resolution History for Add and Update instead of Descrepancy
    4    10/Feb/2025  RAJESH GAMI    Added @IsPrintInspector,@IsPrintTechnician
	5    24/Apr/2025  RAJESH GAMI    add the WorkOrderPartNumberId where condition while adding the Sequence Number (We need to increase Sequence By Part No Id)
	6    10/Feb/2025  Moin Bloch     Added @@IsPrintAdmin
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_AddUpdateWorkOrderTasks]
	@WorkOrderTaskId BIGINT,
	@WorkOrderId BIGINT,
	@WorkFlowWorkOrderId BIGINT,
	@TaskId BIGINT,
	@TaskName VARCHAR(250) = '',
	@OpenDate DATETIME2(7) = NULL,
	@OpenBy VARCHAR(100) = '',
	@WorkOrderPartNumberId BIGINT = NULL,
	@IsIncludeInPrint BIT = NULL,
	@HasInstruction BIT = NULL,
	@SequenceNumber VARCHAR(10) = NULL,
	@TechId BIGINT = NULL,
	@TechName VARCHAR(100) = NULL,
	@TechUpdatedDate DATETIME2(7) = NULL,
	@InspectorId BIGINT = NULL,
	@InspectorName VARCHAR(100) = NULL,
	@InspectorUpdatedDate DATETIME2(7) = NULL,
	@Descrepancy VARCHAR(MAX) = NULL,
	@Resolution VARCHAR(MAX) = NULL,
	@CreatedBy VARCHAR(100) = NULL,
	@MasterCompanyId BIGINT = NULL,
	@PrintInWO BIT = NULL,
	@PrintInWOQ BIT = NULL,
	@IsPrintInspector BIT = NULL,
	@IsPrintTechnician BIT = NULL,
	@IsPrintAdmin BIT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	
	DECLARE @StatusCode VARCHAR(100), @TemplateBody VARCHAR(MAX);
	DECLARE @ModuleId INT, @SubModuleId INT;

	SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15;
	SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderTask';

	IF (ISNULL(@WorkOrderTaskId, 0) = 0)
	BEGIN
		DECLARE @CurrentSequenceNo DECIMAL(18,6) = 0;
        DECLARE @SequenceNumberDecimal DECIMAL(18,6) = NULL;
        DECLARE @SequenceNumberToInsert VARCHAR(10) = NULL;
        DECLARE @InsertedWorkOrderTaskId BIGINT = 0;

        -- compute current max numeric sequence for given WorkOrderId + WorkFlowWorkOrderId + WorkOrderPartNumberId
        SELECT @CurrentSequenceNo = ISNULL(MAX(TRY_CAST(SequenceNumber AS DECIMAL(18,6))), 0)
        FROM DBO.WorkOrderTask WITH (NOLOCK)
        WHERE WorkOrderId = @WorkOrderId
            AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId
            AND WorkOrderPartNumberId = ISNULL(@WorkOrderPartNumberId, 0);

        -- try parse incoming string to decimal for comparison only
        SET @SequenceNumberDecimal = TRY_CAST(@SequenceNumber AS DECIMAL(18,6));

        IF @SequenceNumberDecimal IS NULL OR @SequenceNumberDecimal <= @CurrentSequenceNo
        BEGIN
            -- generate next integer sequence (as numeric)
            SET @SequenceNumberDecimal = @CurrentSequenceNo + 1;

            -- convert to string (6 decimals fixed) then trim trailing zeros/dot
            SET @SequenceNumberToInsert = RTRIM(REPLACE(STR(@SequenceNumberDecimal, 38, 6), ' ', ''));

            WHILE RIGHT(@SequenceNumberToInsert, 1) = '0'
                SET @SequenceNumberToInsert = LEFT(@SequenceNumberToInsert, LEN(@SequenceNumberToInsert) - 1);

            IF RIGHT(@SequenceNumberToInsert, 1) = '.'
                SET @SequenceNumberToInsert = LEFT(@SequenceNumberToInsert, LEN(@SequenceNumberToInsert) - 1);

            SET @SequenceNumberToInsert = LEFT(@SequenceNumberToInsert, 10);
        END
        ELSE
        BEGIN
            -- incoming string is valid and greater than max — preserve exact string (trim left/right spaces, enforce length)
            SET @SequenceNumberToInsert = LEFT(LTRIM(RTRIM(@SequenceNumber)), 10);
        END

        INSERT INTO DBO.WorkOrderTask
        (
            [WorkOrderId],[WorkFlowWorkOrderId],[TaskId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
            [WorkOrderPartNumberId],[SequenceNumber],[OpenDate],[OpenBy],[IsIncludeInPrint],[HasInstruction],[TaskName]
        )
        VALUES
        (
            @WorkOrderId, @WorkFlowWorkOrderId, @TaskId, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,
            @WorkOrderPartNumberId, @SequenceNumberToInsert, @OpenDate, @OpenBy, @IsIncludeInPrint, @HasInstruction, @TaskName
        );

        SET @InsertedWorkOrderTaskId = SCOPE_IDENTITY();

        INSERT INTO DBO.WorkOrderTaskDetails
        (
            [WorkOrderTaskId],[OpenDate],[OpenBy],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],[InspectorUpdatedDate],[Descrepancy],
            [Resolution],[HasInstruction],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PrintInWO],[PrintInWOQ],
            IsPrintInspector,IsPrintTechnician,[IsPrintAdmin]
        )
        SELECT 
            @InsertedWorkOrderTaskId, @OpenDate, @OpenBy, @TechId, @TechName, @TechUpdatedDate, @InspectorId, @InspectorName, @InspectorUpdatedDate, @Descrepancy,
            @Resolution, @HasInstruction, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @PrintInWO, @PrintInWOQ, @IsPrintInspector, @IsPrintTechnician, @IsPrintAdmin;

        -- Add Entry in History Table
        SET @StatusCode = 'CreateWorkOrderTask';
        SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode;
        SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));
        EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, '', @TaskName, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL;

        SELECT @InsertedWorkOrderTaskId AS WorkOrderTaskId;
	END
	ELSE
	BEGIN
		DECLARE @OldDescrepancy VARCHAR(MAX);
		DECLARE @OldResolution VARCHAR(MAX);

		SELECT @OldDescrepancy = Descrepancy, @OldResolution = Resolution FROM DBO.WorkOrderTaskDetails WHERE WorkOrderTaskId = @WorkOrderTaskId;
		SELECT @TaskName = TaskName FROM DBO.WorkOrderTask WHERE WorkOrderTaskId = @WorkOrderTaskId;

		UPDATE DBO.WorkOrderTaskDetails
		SET Descrepancy = @Descrepancy,
		Resolution = @Resolution,
		InspectorId = @InspectorId,
		InspectorName = @InspectorName,
		InspectorUpdatedDate = @InspectorUpdatedDate,
		TechId = @TechId,
		TechName = @TechName,
		TechUpdatedDate = @TechUpdatedDate,
		[PrintInWO] = @PrintInWO,
		[PrintInWOQ] = @PrintInWOQ,
		IsPrintInspector = @IsPrintInspector,
		[IsPrintTechnician] = @IsPrintTechnician,
		[IsPrintAdmin] = @IsPrintAdmin
		WHERE WorkOrderTaskId = @WorkOrderTaskId;

		-- Add Entry in History Table
		IF (@OldDescrepancy <> @Descrepancy)
		BEGIN
			SET @StatusCode = 'UpdateWorkOrderTaskDescrepancy';

			SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode;

			SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##OldDescrepancy##', ISNULL(@OldDescrepancy,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##NewDescrepancy##', ISNULL(@Descrepancy,''));

			EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, @OldDescrepancy, @Descrepancy, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL
		END

		IF (@OldResolution <> @Resolution)
		BEGIN
			SET @StatusCode = 'UpdateWorkOrderTaskResolution';

			SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode;

			SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##OldResolution##', ISNULL(@OldResolution,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##NewResolution##', ISNULL(@Resolution,''));

			EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, @OldResolution, @Resolution, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL
		END

		SELECT @WorkOrderTaskId AS WorkOrderTaskId;
	END
  COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_AddUpdateWorkOrderTasks',
            @ProcedureParameters varchar(3000) = '@WorkOrderTaskId = ''' + CAST(ISNULL(@WorkOrderTaskId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END