/***************************************************************  
 ** File:   [USP_GetWorkFlowTaskInstructionMasterList]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to task Instruction Master List For Work Flow
 ** Date:  07-Feb-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  					Change Description              
 ** --   --------			-------					--------------------------------            
    1    07-Feb-2025		Devendra Shekh					Created

	exec dbo.USP_GetWorkFlowTaskInstructionMasterList @WorkflowId=43,@TaskId=10,@MasterCompanyId=1,@IsDeleted=1

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkFlowTaskInstructionMasterList]
	@WorkflowId BIGINT = NULL,
	@TaskId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@IsDeleted BIT = NULL
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
			WFD.WorkflowDirectionId,
			WFD.WorkflowId,
			WFD.[Action],
			WFD.[Description],
			WFD.[Memo],
			WFD.[Order],
			WFD.[WFParentId],
			WFD.[IsVersionIncrease],
			WFD.ParentId,
			WFD.IsParent,
			WFD.IsTaskDetails,
			WFD.TaskId,
			T.[Description] TaskName,
			WFD.[Action] InstructionTitle,
			CAST(ISNULL(WFD.[Sequence], '') AS BIGINT) SequenceNumber,
			ISNULL(WFD.[Sequence], '') AS [Sequence],
			WFD.[Description] InstructionDetails,
			WFD.MasterCompanyId,
			WFD.CreatedBy,
			WFD.UpdatedBy,
			WFD.CreatedDate,
			WFD.UpdatedDate,
			WFD.IsActive,
			WFD.IsDeleted 
			FROM dbo.WorkFlowDirection WFD WITH(NOLOCK)
			LEFT JOIN DBO.Task T WITH(NOLOCK) ON T.TaskId = WFD.TaskId
			WHERE WFD.MasterCompanyId = @MasterCompanyId AND ISNULL(WFD.IsActive,0) = 1 AND ISNULL(WFD.IsDeleted,0) = @IsDeleted AND WFD.WorkflowId = @WorkflowId AND WFD.TaskId = @TaskId
		)

		SELECT * INTO #LeafTempTbl FROM CTE

		SELECT * FROM #LeafTempTbl ORDER BY SequenceNumber;
		
	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetWorkFlowTaskInstructionMasterList'
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