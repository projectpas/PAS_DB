
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
	@SequenceNumber INT = NULL,
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
	@IsPrintTechnician BIT = NULL
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
		DECLARE @CurrentSequenceNo INT = 0;

		SELECT @CurrentSequenceNo = ISNULL(MAX(SequenceNumber), 0) FROM DBO.WorkOrderTask WHERE WorkOrderId = @WorkOrderId AND WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WorkOrderPartNumberId = ISNULL(@WorkOrderPartNumberId,0);
		DECLARE @InsertedWorkOrderTaskId BIGINT = 0;

		INSERT INTO DBO.WorkOrderTask ([WorkOrderId],[WorkFlowWorkOrderId],[TaskId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
		[WorkOrderPartNumberId],[SequenceNumber],[OpenDate],[OpenBy],[IsIncludeInPrint],[HasInstruction],[TaskName])
		SELECT @WorkOrderId, @WorkFlowWorkOrderId,@TaskId, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,
		@WorkOrderPartNumberId, (@CurrentSequenceNo + 1), @OpenDate, @OpenBy, @IsIncludeInPrint, @HasInstruction, @TaskName;

		SET @InsertedWorkOrderTaskId = SCOPE_IDENTITY();

		INSERT INTO DBO.WorkOrderTaskDetails ([WorkOrderTaskId],[OpenDate],[OpenBy],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],[InspectorUpdatedDate],[Descrepancy],
		[Resolution],[HasInstruction],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted], [PrintInWO], [PrintInWOQ],IsPrintInspector,IsPrintTechnician)
		SELECT @InsertedWorkOrderTaskId, @OpenDate, @OpenBy, @TechId, @TechName, @TechUpdatedDate, @InspectorId, @InspectorName, @InspectorUpdatedDate, @Descrepancy,
		@Resolution, @HasInstruction, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @PrintInWO, @PrintInWOQ,@IsPrintInspector,@IsPrintTechnician;

		-- Add Entry in History Table
		SET @StatusCode = 'CreateWorkOrderTask';

		SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode

		SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));

		EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, '', @TaskName, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL

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
		[IsPrintTechnician] = @IsPrintTechnician
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