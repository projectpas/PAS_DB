/***************************************************************  
 ** File:   [GetWorkOrderTaskInstructionById]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Get Work Order Task Instruction By Id
 ** Date:  03-March-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    03-March-2025		Devendra Shekh				Created

	EXEC GetWorkOrderTaskInstructionById @WorkflowDirectionId=530,@MasterCompanyId=1,@IsDeleted=0
**************************************************************/
CREATE   PROCEDURE [dbo].[GetWorkOrderTaskInstructionById]
	@WorkOrderTaskInstructionId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@IsDeleted BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		SELECT	
		WTI.WorkOrderTaskInstructionId,
		WTI.InstructionTitle,
		WTI.InstructionDetails,
		WTI.MasterCompanyId,
		WTI.CreatedBy,
		WTI.UpdatedBy,
		WTI.CreatedDate,
		WTI.UpdatedDate,
		WTI.IsActive,
		WTI.IsDeleted,
		TSK.TaskId,
		TSK.Description AS TaskName,
		WTI.TechName,
		WTI.TechUpdatedDate,
		WTI.InspectorName,
		WTI.InspectorUpdatedDate,
		WTI.PrintInWO,
		WTI.PrintInWOQ
		FROM [dbo].[WorkOrderTaskInstruction] WTI  WITH(NOLOCK)
		INNER JOIN [dbo].[WorkOrderTask] WOT WITH(NOLOCK) ON WTI.WorkOrderTaskId = WOT.WorkOrderTaskId
		INNER JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
		WHERE	WTI.WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId AND WTI.MasterCompanyId = @MasterCompanyId
				AND ISNULL(WTI.IsActive,0) = 1
				AND ISNULL(WTI.IsDeleted,0) = @IsDeleted

	END TRY
	BEGIN CATCH
	  DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetWorkOrderTaskInstructionById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderTaskInstructionId, '') AS varchar(100))+
												  '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END