/***************************************************************  
 ** File:   [GetTaskInstructionMasterListById]             
 ** Author:   Ekta Chandegra
 ** Description: This stored procedure is used to GetTaskInstructionMasterListById
 ** Date:  20-Jan-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    20-Jan-2025		Ekta Chandegra			Created
    2    27-Jan-2025		Ekta Chandegra			Add @IsDeleted parameter


	EXEC GetTaskInstructionMasterListById @TaskInstructionId=3,@TaskId=0,@IsDeleted=0
**************************************************************/

CREATE   PROCEDURE [dbo].[GetTaskInstructionMasterListById]
	@TaskInstructionId BIGINT = NULL,
	@TaskId BIGINT = NULL,
	@IsDeleted BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		SELECT	
		TIM.TaskInstructionId,
		TIM.Title AS InstructionTitle,
		TIM.Description AS InstructionDetails,
		TIM.MasterCompanyId,
		TIM.CreatedBy,
		TIM.UpdatedBy,
		TIM.CreatedDate,
		TIM.UpdatedDate,
		TIM.IsActive,
		TIM.IsDeleted 
		FROM [dbo].[TaskInstructionMaster] TIM  WITH(NOLOCK)
		WHERE TIM.TaskInstructionId = @TaskInstructionId 
		AND ISNULL(TIM.IsActive,0) = 1
		AND ISNULL(TIM.IsDeleted,0) = @IsDeleted

		SELECT 
		TSK.TaskId,
		TSK.Description AS TaskName
		FROM[dbo].[Task] TSK WITH(NOLOCK) 
		WHERE TSK.TaskId = @TaskId 
		AND ISNULL(TSK.IsActive,0) = 1
		AND ISNULL(TSK.IsDeleted,0) = 0

	END TRY
	BEGIN CATCH
	  DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetTaskInstructionMasterListById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@TaskInstructionId, '') AS varchar(100))+
												  '@Parameter2 = ''' + CAST(ISNULL(@TaskId, '') AS varchar(100))
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