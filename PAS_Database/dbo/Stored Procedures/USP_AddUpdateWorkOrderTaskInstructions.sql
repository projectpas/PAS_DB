/***************************************************************  
 ** File:   [USP_AddUpdateWorkOrderTaskInstructions]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used add or update sales order part details
 ** Purpose:
 ** Date:   12/24/2024

 ** Change History
 **************************************************************
 ** PR   Date         Author  		 Change Description
 ** --   --------     -------		 --------------------------------
    1    01/01/2025   Vishal Suthar	 Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateWorkOrderTaskInstructions]
	@WorkOrderTaskInstructionId BIGINT,
	@WorkOrderTaskId BIGINT,
	@TechId BIGINT = NULL,
	@TechName VARCHAR(100) = NULL,
	@TechUpdatedDate DATETIME2(7) = NULL,
	@InspectorId BIGINT = NULL,
	@InspectorName VARCHAR(100) = NULL,
	@InspectorUpdatedDate DATETIME2(7) = NULL,
	@PrintInWO BIT = NULL,
	@PrintInWOQ BIT = NULL,
	@InstructionListId VARCHAR(250) = NULL,
	@CreatedBy VARCHAR(100) = NULL,
	@MasterCompanyId BIGINT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	
	IF (ISNULL(@WorkOrderTaskInstructionId, 0) = 0)
	BEGIN
		DECLARE @InsertedWorkOrderTaskInstructionId BIGINT = 0;

		INSERT INTO DBO.WorkOrderTaskInstruction ([WorkOrderTaskId],[InstructionTitle],[SequenceNumber],[InstructionDetails],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],
		[InspectorUpdatedDate],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
		SELECT @WorkOrderTaskId, TIM.Title, TIM.[SequenceNumber], TIM.[Description],@TechId,@TechName,@TechUpdatedDate,@InspectorId,@InspectorName,
		@InspectorUpdatedDate,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0
		FROM DBO.TaskInstructionMaster TIM WITH (NOLOCK) WHERE TaskInstructionId IN (SELECT Item FROM DBO.SPLITSTRING(@InstructionListId, ','))
		OR ParentId IN (SELECT Item FROM DBO.SPLITSTRING(@InstructionListId, ','))

		SET @InsertedWorkOrderTaskInstructionId = SCOPE_IDENTITY();
	END
	ELSE
	BEGIN
		--UPDATE DBO.WorkOrderTaskDetails
		--SET Descrepancy = @Descrepancy,
		--Resolution = @Resolution,
		--InspectorId = @InspectorId,
		--InspectorName = @InspectorName,
		--InspectorUpdatedDate = @InspectorUpdatedDate,
		--TechId = @TechId,
		--TechName = @TechName,
		--TechUpdatedDate = @TechUpdatedDate
		--WHERE WorkOrderTaskId = @WorkOrderTaskId;

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
            ,@AdhocComments varchar(150) = 'USP_AddUpdateWorkOrderTaskInstructions',
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