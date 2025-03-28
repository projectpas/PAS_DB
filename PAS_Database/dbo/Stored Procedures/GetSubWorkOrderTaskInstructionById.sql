/***************************************************************  
 ** File:   [GetSubWorkOrderTaskInstructionById]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Get Work Order Task Instruction By Id
 ** Date:  21-March-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    21-March-2025		Devendra Shekh				Created

	EXEC GetSubWorkOrderTaskInstructionById @WorkflowDirectionId=530,@MasterCompanyId=1,@IsDeleted=0
**************************************************************/
CREATE   PROCEDURE [dbo].[GetSubWorkOrderTaskInstructionById]
	@SubWorkOrderTaskInstructionId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@IsDeleted BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		SELECT	
		WTI.SubWorkOrderTaskInstructionId,
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
		FROM [dbo].[SubWorkOrderTaskInstruction] WTI  WITH(NOLOCK)
		INNER JOIN [dbo].[SubWorkOrderTask] WOT WITH(NOLOCK) ON WTI.SubWorkOrderTaskId = WOT.SubWorkOrderTaskId
		INNER JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WOT.TaskId = TSK.TaskId
		WHERE	WTI.SubWorkOrderTaskInstructionId = @SubWorkOrderTaskInstructionId AND WTI.MasterCompanyId = @MasterCompanyId
				AND ISNULL(WTI.IsActive,0) = 1
				AND ISNULL(WTI.IsDeleted,0) = @IsDeleted

	END TRY
	BEGIN CATCH
	  DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetSubWorkOrderTaskInstructionById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SubWorkOrderTaskInstructionId, '') AS varchar(100))+
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