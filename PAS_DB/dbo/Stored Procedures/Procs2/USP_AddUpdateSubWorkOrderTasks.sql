/***************************************************************  
 ** File:   [USP_AddUpdateSubWorkOrderTasks]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used add or update sales order part details
 ** Purpose:
 ** Date:   03/18/2025

 ** Change History
 **************************************************************
 ** PR   Date         Author  		 Change Description
 ** --   --------     -------		 --------------------------------
    1    03/18/2025   Vishal Suthar	 Created
	2    24/Apr/2025  RAJESH GAMI    add the WorkOrderPartNumberId where condition while adding the Sequence Number (We need to increase Sequence By Part No Id)
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateSubWorkOrderTasks]
	@SubWorkOrderTaskId BIGINT,
	@WorkOrderId BIGINT,
	@SubWorkOrderId BIGINT,
	@TaskId BIGINT,
	@TaskName VARCHAR(250) = '',
	@OpenDate DATETIME2(7) = NULL,
	@OpenBy VARCHAR(100) = '',
	@SWOPartNumberId BIGINT = NULL,
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

	IF (ISNULL(@SubWorkOrderTaskId, 0) = 0)
	BEGIN
		DECLARE @CurrentSequenceNo INT = 0;

		SELECT @CurrentSequenceNo = ISNULL(MAX(SequenceNumber), 0) FROM DBO.SubWorkOrderTask WHERE WorkOrderId = @WorkOrderId AND SubWorkOrderId = @SubWorkOrderId AND ISNULL(SubWOPartNoId,0) = ISNULL(@SWOPartNumberId,0);
		DECLARE @InsertedWorkOrderTaskId BIGINT = 0;

		INSERT INTO DBO.SubWorkOrderTask ([WorkOrderId],[SubWorkOrderId],[TaskId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
		[SubWOPartNoId],[SequenceNumber],[OpenDate],[OpenBy],[IsIncludeInPrint],[HasInstruction],[TaskName])
		SELECT @WorkOrderId, @SubWorkOrderId,@TaskId, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,
		@SWOPartNumberId, (@CurrentSequenceNo + 1), @OpenDate, @OpenBy, @IsIncludeInPrint, @HasInstruction, @TaskName;

		SET @InsertedWorkOrderTaskId = SCOPE_IDENTITY();

		INSERT INTO DBO.SubWorkOrderTaskDetails ([SubWorkOrderTaskId],[OpenDate],[OpenBy],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],[InspectorUpdatedDate],[Descrepancy],
		[Resolution],[HasInstruction],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted], [PrintInWO], [PrintInWOQ],IsPrintInspector,IsPrintTechnician)
		SELECT @InsertedWorkOrderTaskId, @OpenDate, @OpenBy, @TechId, @TechName, @TechUpdatedDate, @InspectorId, @InspectorName, @InspectorUpdatedDate, @Descrepancy,
		@Resolution, @HasInstruction, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @PrintInWO, @PrintInWOQ,@IsPrintInspector,@IsPrintTechnician;

		-- Add Entry in History Table
		--SET @StatusCode = 'CreateWorkOrderTask';

		--SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode

		--SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));

		--EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, '', @TaskName, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL

		SELECT @InsertedWorkOrderTaskId AS SubWorkOrderTaskId;
	END
	ELSE
	BEGIN
		DECLARE @OldDescrepancy VARCHAR(MAX);
		DECLARE @OldResolution VARCHAR(MAX);

		SELECT @OldDescrepancy = Descrepancy, @OldResolution = Resolution FROM DBO.SubWorkOrderTaskDetails WHERE SubWorkOrderTaskId = @SubWorkOrderTaskId;
		SELECT @TaskName = TaskName FROM DBO.SubWorkOrderTask WHERE SubWorkOrderTaskId = @SubWorkOrderTaskId;

		UPDATE DBO.SubWorkOrderTaskDetails
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
		WHERE SubWorkOrderTaskId = @SubWorkOrderTaskId;

		-- Add Entry in History Table
		IF (@OldDescrepancy <> @Descrepancy)
		BEGIN
			SET @StatusCode = 'UpdateWorkOrderTaskDescrepancy';

			SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode;

			SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##OldDescrepancy##', ISNULL(@OldDescrepancy,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##NewDescrepancy##', ISNULL(@Descrepancy,''));

			--EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, @OldDescrepancy, @Descrepancy, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL
		END

		IF (@OldResolution <> @Resolution)
		BEGIN
			SET @StatusCode = 'UpdateWorkOrderTaskResolution';

			SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode;

			SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##OldResolution##', ISNULL(@OldResolution,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##NewResolution##', ISNULL(@Resolution,''));

			--EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNumberId, @OldResolution, @Resolution, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL
		END

		SELECT @SubWorkOrderTaskId AS SubWorkOrderTaskId;
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
            ,@AdhocComments varchar(150) = 'USP_AddUpdateSubWorkOrderTasks',
            @ProcedureParameters varchar(3000) = '@WorkOrderTaskId = ''' + CAST(ISNULL(@SubWorkOrderTaskId, '') AS varchar(100)),
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