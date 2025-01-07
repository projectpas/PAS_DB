/*************************************************************
 ** File:   [USP_CreateWorkOrderTasks]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to insert default tasks in work order
 ** Purpose:
 ** Date:   12/17/2024
            
 ** PARAMETERS:
           
 ** RETURN VALUE:
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			-----------------------
    1    12/17/2024   Vishal Suthar		Created

-- EXEC [USP_CreateWorkOrderTasks] 44
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateWorkOrderTasks]
@WorkOrderTypeId bigint,
@WorkOrderId bigint,
@WorkOrderPartNoId bigint,
@WorkFlowWorkOrderId bigint,
@MasterCompanyId bigint = null,
@CreatedBy varchar(100)
AS
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
	BEGIN TRY  
	BEGIN TRANSACTION  
	BEGIN    
		DECLARE @TaskTypes NVARCHAR(MAX) = '';

		SELECT @TaskTypes = TaskTypes FROM DBO.WorkOrderSettings WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND WorkOrderTypeId = @WorkOrderTypeId;

		IF OBJECT_ID(N'tempdb..#DefaultTask') IS NOT NULL
		BEGIN
			DROP TABLE #DefaultTask
		END

		CREATE TABLE #DefaultTask
		(
			ID bigint NOT NULL IDENTITY,
			TaskId BIGINT NULL
		)

		INSERT INTO #DefaultTask ([TaskId])
		SELECT Item FROM DBO.SPLITSTRING(@TaskTypes, ',');

		DECLARE @LoopID AS INT;
		DECLARE @TotCount AS INT;

		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #DefaultTask;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			DECLARE @WorkOrderTaskId BIGINT = 0;

			INSERT INTO DBO.WorkOrderTask ([WorkOrderId],[WorkFlowWorkOrderId],[TaskId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
			[WorkOrderPartNumberId],[SequenceNumber],[OpenDate],[OpenBy],[IsIncludeInPrint],[HasInstruction],[TaskName])
			SELECT @WorkOrderId,@WorkFlowWorkOrderId,T.[TaskId],[MasterCompanyId],@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,
			@WorkOrderPartNoId,1,NULL,NULL,NULL,NULL,T.[Description]
			FROM DBO.Task T WITH (NOLOCK) WHERE TaskId IN (SELECT TaskId FROM #DefaultTask WHERE ID = @LoopID);

			SELECT @WorkOrderTaskId = SCOPE_IDENTITY();

			INSERT INTO DBO.WorkOrderTaskDetails ([WorkOrderTaskId],[OpenDate],[OpenBy],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],[InspectorUpdatedDate],
			[Descrepancy],[Resolution],[HasInstruction],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
			SELECT @WorkOrderTaskId,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			NULL,NULL,NULL,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0
			FROM DBO.WorkOrderTask WHERE WorkOrderTaskId = @WorkOrderTaskId;

			SET @LoopID = @LoopID + 1;
		END
	END  
	COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
   IF @@trancount > 0  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateWorkOrderTasks'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workorderid, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName         = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END