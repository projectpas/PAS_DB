/*************************************************************           
 ** File:   [dbo].[CreateWorkOrderTasks]
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Create Work Order Tasks
 ** Purpose:         
 ** Date:   29/05/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    29/05/2025   Moin Bloch    Created
     
--   EXEC [dbo].[CreateWorkOrderTasksForWorksheet]
**************************************************************/
CREATE   PROCEDURE [dbo].[CreateWorkOrderTasksForWorksheet]
@tbl_WorkOrderPartNumberType WorkOrderPartNumberType READONLY,
@WorkOrderId BIGINT,
@WorkOrderPartNoId BIGINT,
@WorkOrderTypeId BIGINT,
@CreatedBy VARCHAR(256),
@CreatedDate DATETIME2(7),
@MasterCompanyId INT,
@WorksheetId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN	
		DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1
			
		IF OBJECT_ID(N'tempdb..#tempCreateWorkOrderTasksForCreateWO') IS NOT NULL
		BEGIN
			DROP TABLE #tempCreateWorkOrderTasksForCreateWO
		END	
	
		CREATE TABLE #tempCreateWorkOrderTasksForCreateWO
		(
			[PKID] [BIGINT] NOT NULL IDENTITY, 
			[DefectDescription] [varchar](500) NULL
		)
		
		INSERT INTO #tempCreateWorkOrderTasksForCreateWO([DefectDescription])
		SELECT [DefectDescription] FROM [dbo].[WorksheetPart] WITH(NOLOCK) WHERE [WorksheetHeaderId] = @WorksheetId


		SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tempCreateWorkOrderTasksForCreateWO  

		WHILE @MinId <= @TotalRecord
		BEGIN
			DECLARE @WorkFlowWorkOrderId BIGINT = NULL,@WorkOrderTaskId BIGINT = NULL
			DECLARE @DefectDescription [varchar](500) = NULL,@TaskId BIGINT = NULL,@SequenceNumber INT =0 
		
			SELECT @DefectDescription = [DefectDescription] FROM #tempCreateWorkOrderTasksForCreateWO WHERE [PKID] = @MinId

			IF NOT EXISTS(SELECT 1 FROM [dbo].[Task] WHERE [Description] = @DefectDescription AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0)
			BEGIN
				INSERT INTO [dbo].[Task]([Description],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Sequence],[IsTravelerTask],[Descrepancy],[Resolution],[StandardHours],[StandardMinute],[IsPrintInWO],[IsPrintInWOQ],[IsPrintInspector],[IsPrintTechnician],[IsPrintAdmin])
				 VALUES (@DefectDescription,'',@MasterCompanyId,'AUTO SCRIPT','AUTO SCRIPT',GETUTCDATE(),GETUTCDATE(),1,0,(SELECT (MAX([Sequence]) + 1) FROM [dbo].[Task] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId),1,NULL,NULL,0,0,0,0,1,0,1);						
			END

			SELECT @TaskId = [TaskId] FROM [dbo].[Task] WHERE [Description] = @DefectDescription AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([IsDeleted],0) = 0;
							
			SELECT TOP 1 @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId] = @WorkOrderPartNoId;
			
			SELECT @SequenceNumber = ISNULL(MAX([SequenceNumber]),0) FROM [dbo].[WorkOrderTask] WHERE [WorkOrderId] = @WorkOrderId AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
			
			SET @SequenceNumber = @SequenceNumber + 1;

			INSERT INTO [dbo].[WorkOrderTask] ([WorkOrderId],[WorkFlowWorkOrderId],[TaskId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
							[WorkOrderPartNumberId],[SequenceNumber],[OpenDate],[OpenBy],[IsIncludeInPrint],[HasInstruction],[TaskName])
			SELECT @WorkOrderId,@WorkFlowWorkOrderId,@TaskId,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,
							   @WorkOrderPartNoId,@SequenceNumber,NULL,NULL,NULL,NULL,@DefectDescription			
							   
			SELECT @WorkOrderTaskId = SCOPE_IDENTITY() 

			IF NOT EXISTS(SELECT 1 FROM [dbo].[WorkOrderTaskDetails] WHERE [WorkOrderTaskId] = @WorkOrderTaskId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([IsDeleted],0) = 0)
			BEGIN
				INSERT INTO [dbo].[WorkOrderTaskDetails](WorkOrderTaskId,OpenDate,OpenBy,TechId,TechName,TechUpdatedDate,InspectorId,InspectorName,InspectorUpdatedDate,
					Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,PrintInWO,PrintInWOQ,IsPrintInspector,IsPrintTechnician,IsPrintAdmin)
					VALUES(@WorkOrderTaskId,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,'','',NULL,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,0,0,1,1,0);
			END					
		
			SET @MinId = @MinId + 1
		END	
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CreateWorkOrderTasks' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@CreatedBy, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH     
END