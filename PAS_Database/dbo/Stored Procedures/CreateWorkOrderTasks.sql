/*************************************************************           
 ** File:   [dbo].[CreateWorkOrderTasks]
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Create Work Order Tasks
 ** Purpose:         
 ** Date:   18/03/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18/03/2025   Moin Bloch    Created
     
--   EXEC [dbo].[CreateWorkOrderTasks]
**************************************************************/
CREATE   PROCEDURE [dbo].[CreateWorkOrderTasks]
@tbl_WorkOrderPartNumberType WorkOrderPartNumberType READONLY,
@WorkOrderId BIGINT,
@WorkOrderTypeId BIGINT,
@CreatedBy VARCHAR(256),
@CreatedDate DATETIME2(7),
@MasterCompanyId INT
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
			[ID] [BIGINT] NULL
		)
		
		INSERT INTO #tempCreateWorkOrderTasksForCreateWO([ID])
		SELECT [ID] FROM @tbl_WorkOrderPartNumberType

		SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tempCreateWorkOrderTasksForCreateWO  

		WHILE @MinId <= @TotalRecord
		BEGIN
			DECLARE @WorkOrderPartNoId BIGINT = NULL,@WorkFlowWorkOrderId BIGINT = NULL
		
			SELECT @WorkOrderPartNoId = [ID] FROM #tempCreateWorkOrderTasksForCreateWO WHERE [PKID] = @MinId
				
			SELECT TOP 1 @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId] = @WorkOrderPartNoId;

			EXEC [dbo].[USP_CreateWorkOrderTasks] @WorkOrderTypeId,@WorkOrderId,@WorkOrderPartNoId,@WorkFlowWorkOrderId,@MasterCompanyId,@CreatedBy;		
			
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