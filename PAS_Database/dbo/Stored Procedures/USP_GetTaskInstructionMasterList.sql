/***************************************************************  
 ** File:   [USP_GetTaskInstructionMasterList]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to task Instruction Master List
 ** Date:  26-Dec-2024
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    26-Dec-2024		Devendra Shekh			Created
    2    27-Jan-2025		Ekta Chandegra			Add @IsDeleted parameter
    2    04-Mar-2025		RAJESH GAMI      		Sequence Number logic change (Group by Task)

	exec dbo.USP_GetTaskInstructionMasterList @MasterCompanyId=1,@IsDeleted=1

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetTaskInstructionMasterList]
	@MasterCompanyId bigint = NULL,
	@IsDeleted BIT
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		IF @IsDeleted IS NULL  
		Begin  
		 Set @IsDeleted=0  
		End  
			;WITH CTE AS (
				SELECT 
					TIM.TaskInstructionId,
					TIM.ParentId,
					TIM.IsParent,
					TIM.TaskId,
					T.[Description] TaskName,
					TIM.Title InstructionTitle,
					TIM.SequenceNumber AS SequenceNumber,
					TIM.[Description] InstructionDetails,
					TIM.MasterCompanyId,
					TIM.CreatedBy,
					TIM.UpdatedBy,
					TIM.CreatedDate,
					TIM.UpdatedDate,
					TIM.IsActive,
					TIM.IsDeleted,
					DENSE_RANK() OVER (ORDER BY TIM.TaskId) AS TaskSrNo
				FROM dbo.TaskInstructionMaster TIM WITH(NOLOCK)
				LEFT JOIN DBO.Task T WITH(NOLOCK) 
					ON T.TaskId = TIM.TaskId
				WHERE TIM.MasterCompanyId = @MasterCompanyId 
					AND ISNULL(TIM.IsActive, 0) = 1 
					AND ISNULL(TIM.IsDeleted, 0) = @IsDeleted

			)

			SELECT 	* INTO #LeafTempTbl FROM CTE;			
			SELECT * FROM #LeafTempTbl ORDER BY TaskId,SequenceNumber;
		
	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetTaskInstructionMasterList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
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