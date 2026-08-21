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
    2    23-March-2025		Ekta Chandegra					Convert date using ConvertUTCtoLocal method according user timezone
    3    21-AUG-2026		Rajesh Gami					    Added [WorkFlowTask] JOIN with WorkFlowDirection (As discussed with Hemant)
	exec dbo.USP_GetWorkFlowTaskInstructionMasterList @WorkflowId=5205,@TaskId=10,@MasterCompanyId=1,@IsDeleted=0,@EmployeeId=223


**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkFlowTaskInstructionMasterList]
	@WorkflowId BIGINT = NULL,
	@TaskId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@IsDeleted BIT = NULL,
	@EmployeeId BIGINT

AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
	 DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		SELECT 
		@CurrntEmpTimeZoneDesc = COALESCE(
			ETZ.[Description],  -- Prefer Employee's TimeZone description if available
			LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
		)
		FROM 
		dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN 
		dbo.TimeZone ETZ WITH (NOLOCK) 
		ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN 
		dbo.LegalEntity LE WITH (NOLOCK) 
		ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN 
		dbo.TimeZone LTZ WITH (NOLOCK) 
		ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE 
		E.EmployeeId = @EmployeeId;

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
            (Cast(DBO.ConvertUTCtoLocal(WFD.CreatedDate, @CurrntEmpTimeZoneDesc)AS DATE)) CreatedDate,
            (Cast(DBO.ConvertUTCtoLocal(WFD.UpdatedDate, @CurrntEmpTimeZoneDesc)AS DATE)) UpdatedDate,
			WFD.IsActive,
			WFD.IsDeleted 
			FROM dbo.WorkFlowDirection WFD WITH(NOLOCK)
			LEFT JOIN DBO.Task T WITH(NOLOCK) ON T.TaskId = WFD.TaskId
			INNER JOIN DBO.[WorkFlowTask] WF WITH(NOLOCK) ON WFD.[WorkflowId] = WF.[WorkflowId] AND WFD.TaskId = WF.TaskId
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
