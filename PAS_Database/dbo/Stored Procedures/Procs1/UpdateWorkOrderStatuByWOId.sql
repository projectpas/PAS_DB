
/*************************************************************           
 ** File:   [UpdateWorkOrderStatuByWOId]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used update WO status by WO Id.    
 ** Purpose:         
 ** Date:   07/13/2021        
          
 ** PARAMETERS:           
 @@WorkOrderId BIGINT
 @WorkOrderPartNumberId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/13/2021   Hemant Saliya Created
     
--EXEC [UpdateWorkOrderStatuByWOId] 249
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateWorkOrderStatuByWOId]
@WorkOrderId BIGINT
AS
BEGIN
	   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	   SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL
					BEGIN
					DROP TABLE #TempResult 
					END

					--IF OBJECT_ID(N'tempdb..#WOSTAGECOUNT') IS NOT NULL
					--BEGIN
					--DROP TABLE #WOSTAGECOUNT 
					--END

					IF OBJECT_ID(N'tempdb..#WOSTATUSCOUNT') IS NOT NULL
					BEGIN
					DROP TABLE #WOSTATUSCOUNT
					END

					DECLARE @StatusCount AS INT = 0;
					DECLARE @StageCount AS INT = 0;

					SELECT ID AS WorkOrderPartNumberId, WorkOrderId,WorkOrderStageId, WorkOrderStatusId INTO #TempResult FROM dbo.WorkOrderPartNumber WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId

					--SELECT DISTINCT WorkOrderStageId INTO #WOSTAGECOUNT FROM #TempResult 
					SELECT DISTINCT WorkOrderStatusId INTO #WOSTATUSCOUNT FROM #TempResult 

					--SELECT @StageCount = COUNT(*) FROM #WOSTAGECOUNT
					SELECT @StatusCount = COUNT(*) FROM #WOSTATUSCOUNT

					IF((SELECT COUNT(WorkOrderPartNumberId) FROM #TempResult) > 1)
					BEGIN
						IF (@StatusCount <> (SELECT COUNT(*) FROM #TempResult))
						BEGIN
							UPDATE WorkOrder SET  WorkOrderStatusId  = (SELECT TOP 1 WorkOrderStatusId FROM  #TempResult)
						END
					END
					ELSE
					BEGIN
						IF ((SELECT COUNT(*) FROM #TempResult) > 0)
						BEGIN
							UPDATE WorkOrder SET  WorkOrderStatusId  = (SELECT TOP 1 WorkOrderStatusId FROM  #TempResult)
						END
					END

					IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL
					BEGIN
					DROP TABLE #TempResult 
					END

					IF OBJECT_ID(N'tempdb..#WOSTATUSCOUNT') IS NOT NULL
					BEGIN
					DROP TABLE #WOSTATUSCOUNT
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
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderStatuByWOId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@WorkOrderId AS VARCHAR(10)), '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END