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
 ** PR   Date			Author			Change Description              
 ** --   --------		-------			-----------------------
    1    12/17/2024		Vishal Suthar	Created
	2    12/Feb/2025	RAJESH GAMI		Added IsPrintInspector,IsPrintTechnician
	3    12/Feb/2025	Devendra Shekh	Skipping insert for #DefaultTask if @TaskTypes is Empty 
	4    14/July/2025	Vishal Suthar	Added IsPrintAdmin flag
	5    26/Feb/2026	Moin Bloch	    Ristrict Duplicate Entry PN-15571

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
		DECLARE @WorkOrderFormTypeId BIT;
		DECLARE @StatusCode VARCHAR(100), @TemplateBody VARCHAR(MAX);
		DECLARE @ModuleId INT, @SubModuleId INT;

		SELECT @ModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder'		
		SELECT @SubModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderTask';

		SELECT @WorkOrderFormTypeId = [WorkOrderFormTypeId] FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
		
		IF (ISNULL(@WorkOrderFormTypeId, 0) = 1)
		BEGIN
			SELECT @TaskTypes = [TaskTypes] FROM [dbo].[WorkOrderSettings] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [WorkOrderTypeId] = @WorkOrderTypeId;

			IF OBJECT_ID(N'tempdb..#DefaultTask') IS NOT NULL
			BEGIN
				DROP TABLE #DefaultTask
			END

			CREATE TABLE #DefaultTask
			(
				ID bigint NOT NULL IDENTITY,
				TaskId BIGINT NULL
			)

			IF(ISNULL(@TaskTypes, '') != '')
			BEGIN
				INSERT INTO #DefaultTask ([TaskId])
				SELECT Item FROM DBO.SPLITSTRING(@TaskTypes, ',');
			END

			DECLARE @SequenceNo AS INT = 0;
			DECLARE @LoopID AS INT;
			DECLARE @TotCount AS INT;

			SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #DefaultTask;

			WHILE (@LoopID <= @TotCount)
			BEGIN
				SET @SequenceNo = @SequenceNo + 1;
				DECLARE @WorkOrderTaskId BIGINT = 0;
				DECLARE @TaskName VARCHAR(500);

				IF NOT EXISTS(SELECT 1 FROM [dbo].[WorkOrderTask] WHERE [TaskId] IN (SELECT [TaskId] FROM #DefaultTask WHERE [ID] = @LoopID) AND [WorkOrderId] = @WorkOrderId AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0)
				BEGIN
					INSERT INTO [dbo].[WorkOrderTask] ([WorkOrderId],[WorkFlowWorkOrderId],[TaskId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
						[WorkOrderPartNumberId],[SequenceNumber],[OpenDate],[OpenBy],[IsIncludeInPrint],[HasInstruction],[TaskName])
					SELECT @WorkOrderId,@WorkFlowWorkOrderId,T.[TaskId],[MasterCompanyId],@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,
						@WorkOrderPartNoId,@SequenceNo,NULL,NULL,NULL,NULL,T.[Description]
					FROM [dbo].[Task] T WITH (NOLOCK) WHERE [TaskId] IN (SELECT [TaskId] FROM #DefaultTask WHERE ID = @LoopID);

					SELECT @TaskName = T.[Description] FROM [dbo].[Task] T WITH (NOLOCK) WHERE [TaskId] IN (SELECT [TaskId] FROM #DefaultTask WHERE ID = @LoopID)

					SELECT @WorkOrderTaskId = SCOPE_IDENTITY();

					INSERT INTO [dbo].[WorkOrderTaskDetails] ([WorkOrderTaskId],[OpenDate],[OpenBy],[TechId],[TechName],[TechUpdatedDate],[InspectorId],[InspectorName],[InspectorUpdatedDate],
						[Descrepancy],[Resolution],[HasInstruction],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PrintInWO],[PrintInWOQ],[IsPrintInspector],[IsPrintTechnician],[IsPrintAdmin])
					SELECT @WorkOrderTaskId,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
						T.[Descrepancy],T.[Resolution],NULL,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,T.[IsPrintInWO],T.[IsPrintInWOQ],T.[IsPrintInspector],T.[IsPrintTechnician],T.[IsPrintAdmin]
					FROM [dbo].[Task] T WITH (NOLOCK) WHERE [TaskId] IN (SELECT [TaskId] FROM #DefaultTask WHERE ID = @LoopID);

					-- Add Entry in History Table
					SET @StatusCode = 'CreateWorkOrderTask';

					SELECT @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @StatusCode

					SET @TemplateBody = REPLACE(@TemplateBody, '##TaskName##', ISNULL(@TaskName,''));

					EXEC [dbo].[USP_History] @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNoId, '', @TaskName, @TemplateBody, @StatusCode, @MasterCompanyId, @CreatedBy, NULL, @CreatedBy, NULL
				END
				SET @LoopID = @LoopID + 1;
			END
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
			  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@workorderid, '') AS VARCHAR(100)) 
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