/*************************************************************   
** Author:  <Vishal Suthar>  
** Create date: <03/28/2023>  
** Description: <Delete Work Order Material KIT>  
  
EXEC [usp_ReserveWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    03/28/2023  Vishal Suthar   Created
** 2    16/10/2024  RAJESH GAMI      Un Mapped PO by WO-SubWO Materials Id | KIT, While Delete the Materials

exec dbo.[DeleteWorkOrderMaterialKit] 17
**************************************************************/ 
CREATE   PROCEDURE [dbo].[DeleteWorkOrderMaterialKit]
	@KitId BIGINT,
	@WOPartNoId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					IF OBJECT_ID(N'tempdb..##TempTableWOM') IS NOT NULL
					BEGIN
						DROP TABLE #TempTableWOM
					END
					CREATE TABLE #TempTableWOM(WorkOrderMaterialsKitMappingId BIGINT)
					INSERT INTO #TempTableWOM (WorkOrderMaterialsKitMappingId)
					SELECT WorkOrderMaterialsKitMappingId FROM [DBO].[WorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND WOPartNoId = @WOPartNoId


					IF OBJECT_ID(N'tempdb..##TempWOtblM') IS NOT NULL
					BEGIN
						DROP TABLE #TempWOtblM
					END

					CREATE TABLE #TempWOtblM(WorkOrderMaterialsKitId BIGINT)
					INSERT INTO #TempWOtblM (WorkOrderMaterialsKitId)
					SELECT DISTINCT WOM.WorkOrderMaterialsKitId
					FROM dbo.[WorkOrderMaterialsKit] WOM WITH(NOLOCK) INNER JOIN #TempTableWOM tmp ON WOM.WorkOrderMaterialsKitMappingId = tmp.WorkOrderMaterialsKitMappingId
					WHERE WOM.WorkOrderMaterialsKitMappingId = tmp.WorkOrderMaterialsKitMappingId

					UPDATE P    
				    SET WorkOrderMaterialsId = 0, 
					       IsKit = 0, IsSubWO =0, 
						   UpdatedDate = GETUTCDATE()
					FROM DBO.PurchaseOrderPart P
					  INNER JOIN #TempWOtblM tmp ON P.WorkOrderMaterialsId = tmp.WorkOrderMaterialsKitId
					  WHERE P.WorkOrderMaterialsId  = tmp.WorkOrderMaterialsKitId AND ISNULL(IsKit,0) = 1 AND ISNULL(IsSubWO,0) = 0

					DELETE FROM [dbo].[WorkOrderMaterialStockLineKit] WHERE WorkOrderMaterialsKitId IN (SELECT WorkOrderMaterialsKitId FROM [DBO].[WorkOrderMaterialsKit] WHERE WorkOrderMaterialsKitMappingId IN (SELECT WorkOrderMaterialsKitMappingId FROM [DBO].[WorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND WOPartNoId = @WOPartNoId));
					DELETE FROM [DBO].[WorkOrderMaterialsKit] WHERE WorkOrderMaterialsKitMappingId IN (SELECT WorkOrderMaterialsKitMappingId FROM [DBO].[WorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND WOPartNoId = @WOPartNoId);
					DELETE FROM [DBO].[WorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND WOPartNoId = @WOPartNoId;
				END

			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteWorkOrderMaterialKit' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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