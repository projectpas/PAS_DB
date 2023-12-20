/*************************************************************                 
 ** File:   [WorkOrderSettingDefaultStageCode]                 
 ** Author: Shrey Chandegara      
 ** Description: This stored procedure is used retrieve Scrap Certificate Data userd      
 ** Purpose:               
 ** Date:   04/18/2023      
      
 ** PARAMETERS:                 
               
 ** RETURN VALUE:                 
        
 **************************************************************                 
  ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change			Description                  
 ** --   --------     -------  --------		------------------------                
    1    04/18/2023   Shrey Chandegara			Created
	2	 10/02/2023	  Nainshi Joshi				Add Field - StageCode
           
--EXEC [WorkOrderSettingDefaultStageCode] 1      
**************************************************************/      
CREATE   PROCEDURE [dbo].[WorkOrderSettingDefaultStageCode] @MasterCompanyId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN
			SELECT T.workOrderStage
				,T.WorkOrderStageId
				,T.WorkOrderStaus
				,T.WorkOrderStausId
				,T.WorkOrderStageCode
			FROM (
				SELECT stage.code + '-' + stage.Stage AS workOrderStage
					,stage.WorkOrderStageId
					,19999999999999999 AS st
					,ws.STATUS AS WorkOrderStaus
					,ws.Id AS WorkOrderStausId
					,stage.StageCode AS WorkOrderStageCode
				FROM dbo.WorkOrderStage stage WITH (NOLOCK)
				JOIN WorkOrderStatus ws WITH (NOLOCK) ON stage.StatusId = ws.Id
				WHERE Isnumeric(stage.code) = 0
					AND stage.IsActive = 1
					AND stage.IsDeleted = 0
					AND stage.MasterCompanyId = @MasterCompanyId
				
				UNION ALL
				
				SELECT stage.code + '-' + stage.Stage AS workOrderStage
					,stage.WorkOrderStageId
					,cast(stage.Code AS BIGINT) AS st
					,ws.STATUS AS WorkOrderStaus
					,ws.Id AS WorkOrderStausId
					,stage.StageCode AS WorkOrderStageCode
				FROM dbo.WorkOrderStage stage WITH (NOLOCK)
				JOIN WorkOrderStatus ws WITH (NOLOCK) ON stage.StatusId = ws.Id
				WHERE Isnumeric(stage.code) = 1
					AND stage.IsActive = 1
					AND stage.IsDeleted = 0
					AND stage.MasterCompanyId = @MasterCompanyId
				) T
			ORDER BY T.st ASC
		END
	END TRY

	BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'

		DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
			,@AdhocComments VARCHAR(150) = 'WorkOrderSettingDefaultStageCode'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + ISNULL(@MasterCompanyId, '')
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