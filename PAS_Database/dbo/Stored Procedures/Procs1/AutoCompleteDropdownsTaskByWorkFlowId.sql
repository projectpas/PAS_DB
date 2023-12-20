/*************************************************************           
 ** File:   [AutoCompleteDropdownsTaskByWorkFlowId]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Task List for Auto Complete Dropdown 
 ** Purpose:         
 ** Date:   12/29/2020        
          
 ** PARAMETERS:  @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/29/2020   Hemant Saliya Created
     
--EXEC [AutoCompleteDropdownsTaskByWorkFlowId] '',1,20,10169,1
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsTaskByWorkFlowId]
@StartWith VARCHAR(50),
@IsActive BIT = true,
@Count VARCHAR(10) = '0',
@WorkFlowId BIGINT = 0,
@MasterCompanyId INT
AS
BEGIN	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY  

		DECLARE @Sql NVARCHAR(MAX);	
		DECLARE @WorkFlowIds NVARCHAR(MAX);	

		IF OBJECT_ID(N'tempdb..#tmpTaskIds') IS NOT NULL
		BEGIN
			DROP TABLE #tmpTaskIds 
		END

		CREATE TABLE #tmpTaskIds(TaskId BIGINT) 

		IF(@Count = '0') 
		   BEGIN
		   SET @Count = '20';	
		END	
		IF(@WorkFlowId > 0)
		BEGIN
			INSERT INTO #tmpTaskIds(TaskId) SELECT DISTINCT CH.TaskId FROM WorkflowChargesList CH WITH(NOLOCK) WHERE CH.MasterCompanyId = @MasterCompanyId AND CH.WorkflowId = @WorkFlowId  
			INSERT INTO #tmpTaskIds(TaskId) SELECT DISTINCT D.TaskId FROM WorkFlowDirection D WITH(NOLOCK) WHERE D.MasterCompanyId = @MasterCompanyId AND D.WorkflowId = @WorkFlowId
			INSERT INTO #tmpTaskIds(TaskId) SELECT DISTINCT EQ.TaskId FROM WorkflowEquipmentList EQ WITH(NOLOCK) WHERE EQ.MasterCompanyId = @MasterCompanyId AND EQ.WorkflowId = @WorkFlowId
			INSERT INTO #tmpTaskIds(TaskId) SELECT DISTINCT EXC.TaskId FROM WorkFlowExclusion EXC WITH(NOLOCK) WHERE EXC.MasterCompanyId = @MasterCompanyId AND EXC.WorkflowId = @WorkFlowId
			INSERT INTO #tmpTaskIds(TaskId) SELECT DISTINCT EX.TaskId FROM WorkflowExpertiseList EX WITH(NOLOCK) WHERE EX.MasterCompanyId = @MasterCompanyId AND EX.WorkflowId = @WorkFlowId
			INSERT INTO #tmpTaskIds(TaskId) SELECT DISTINCT M.TaskId FROM WorkflowMaterial M WITH(NOLOCK) WHERE M.MasterCompanyId = @MasterCompanyId AND M.WorkflowId = @WorkFlowId
			INSERT INTO #tmpTaskIds(TaskId) SELECT DISTINCT ME.TaskId FROM WorkflowMeasurement ME WITH(NOLOCK) WHERE ME.MasterCompanyId = @MasterCompanyId AND ME.WorkflowId = @WorkFlowId
			INSERT INTO #tmpTaskIds(TaskId) SELECT DISTINCT P.TaskId FROM WorkflowPublications P WITH(NOLOCK) WHERE P.MasterCompanyId = @MasterCompanyId AND P.WorkflowId = @WorkFlowId
		END

		SELECT DISTINCT  
			T.TaskId AS Value, 
			T.Description AS Label,		
			T.TaskId,
			T.Description, 
			T.Sequence
		FROM dbo.Task T WITH(NOLOCK)					
		WHERE T.MasterCompanyId = @MasterCompanyId AND (T.IsActive = 1 AND ISNULL(T.IsDeleted, 0) = 0 AND (T.Description LIKE @StartWith + '%'))
		UNION     
		SELECT DISTINCT  
			T.TaskId AS Value, 
			T.Description AS Label,		
			T.TaskId,
			T.Description, 
			T.Sequence
		FROM dbo.Task T WITH(NOLOCK)
				JOIN #tmpTaskIds tmpT ON T.TaskId = tmpT.TaskId
		WHERE T.MasterCompanyId = @MasterCompanyId  
		ORDER BY Label

		IF OBJECT_ID(N'tempdb..#tmpTaskIds') IS NOT NULL
		BEGIN
			DROP TABLE #tmpTaskIds 
		END
		END TRY
	BEGIN CATCH	
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdownsAsset'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@IsActive, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))  
			   + '@Parameter4 = ''' + CAST(ISNULL(@WorkFlowId, '') as varchar(100))			  
			   + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100)) 
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);

	END CATCH
END