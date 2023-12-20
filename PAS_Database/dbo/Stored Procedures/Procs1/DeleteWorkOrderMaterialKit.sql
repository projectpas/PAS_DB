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