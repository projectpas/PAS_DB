/***************************************************************  
 ** File:   [GetTemplateTaskInstructionById]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Get Template Task Instruction By Id
 ** Date:  03-March-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    03-March-2025		Devendra Shekh				Created

	EXEC GetTemplateTaskInstructionById @WorkflowDirectionId=530,@MasterCompanyId=1,@IsDeleted=0
**************************************************************/
CREATE   PROCEDURE [dbo].[GetTemplateTaskInstructionById]
	@WorkflowDirectionId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@IsDeleted BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		SELECT	
		WFD.WorkflowDirectionId,
		WFD.Action AS InstructionTitle,
		WFD.Description AS InstructionDetails,
		WFD.MasterCompanyId,
		WFD.CreatedBy,
		WFD.UpdatedBy,
		WFD.CreatedDate,
		WFD.UpdatedDate,
		WFD.IsActive,
		WFD.IsDeleted,
		TSK.TaskId,
		TSK.Description AS TaskName
		FROM [dbo].[WorkFlowDirection] WFD  WITH(NOLOCK)
		INNER JOIN [dbo].[Task] TSK WITH(NOLOCK) ON WFD.TaskId = TSK.TaskId
		WHERE	WFD.WorkflowDirectionId = @WorkflowDirectionId AND WFD.MasterCompanyId = @MasterCompanyId
				AND ISNULL(WFD.IsActive,0) = 1
				AND ISNULL(WFD.IsDeleted,0) = @IsDeleted

	END TRY
	BEGIN CATCH
	  DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetTemplateTaskInstructionById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkflowDirectionId, '') AS varchar(100))+
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