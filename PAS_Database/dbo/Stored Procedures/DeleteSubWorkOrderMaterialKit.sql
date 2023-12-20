/*************************************************************   
** Author:  <Devendra Shekh>  
** Create date: <12/12/2023>  
** Description: <Delete Sub Work Order Material KIT>  
  
EXEC [DeleteSubWorkOrderMaterialKit] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author				Change Description  
** --   --------		-------				--------------------------------
** 1    12/12/2023	 Devendra Shekh			Created

exec dbo.[DeleteSubWorkOrderMaterialKit] 17
**************************************************************/ 
CREATE   PROCEDURE [dbo].[DeleteSubWorkOrderMaterialKit]
	@KitId BIGINT,
	@SubWOPartNoId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					DELETE FROM [dbo].[SubWorkOrderMaterialStockLineKit] WHERE SubWorkOrderMaterialsKitId IN (SELECT SubWorkOrderMaterialsKitId FROM [DBO].[SubWorkOrderMaterialsKit] WHERE [SubWorkOrderMaterialsKitMappingId] IN (SELECT [SubWorkOrderMaterialsKitMappingId] FROM [DBO].[SubWorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND SubWOPartNoId = @SubWOPartNoId));
					DELETE FROM [DBO].[SubWorkOrderMaterialsKit] WHERE [SubWorkOrderMaterialsKitMappingId] IN (SELECT [SubWorkOrderMaterialsKitMappingId] FROM [DBO].[SubWorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND SubWOPartNoId = @SubWOPartNoId);
					DELETE FROM [DBO].[SubWorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND SubWOPartNoId = @SubWOPartNoId;
				END

			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteSubWorkOrderMaterialKit' 
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