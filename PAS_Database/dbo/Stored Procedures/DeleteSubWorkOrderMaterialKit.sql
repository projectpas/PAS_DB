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
** 2    16/10/2024  RAJESH GAMI      Un Mapped PO by WO-SubWO Materials Id | KIT, While Delete the Materials

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

				IF OBJECT_ID(N'tempdb..##TempTableWOM') IS NOT NULL
					BEGIN
						DROP TABLE #TempTableWOM
					END
					CREATE TABLE #TempTableWOM(SubWorkOrderMaterialsKitMappingId BIGINT)
					INSERT INTO #TempTableWOM (SubWorkOrderMaterialsKitMappingId)
					SELECT SubWorkOrderMaterialsKitMappingId FROM [DBO].[SubWorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND SubWOPartNoId = @SubWOPartNoId
					
					IF OBJECT_ID(N'tempdb..##TempWOtblM') IS NOT NULL
					BEGIN
						DROP TABLE #TempWOtblM
					END

					CREATE TABLE #TempWOtblM(SubWorkOrderMaterialsKitId BIGINT)
					INSERT INTO #TempWOtblM (SubWorkOrderMaterialsKitId)
					SELECT DISTINCT WOM.SubWorkOrderMaterialsKitId
					FROM dbo.[SubWorkOrderMaterialsKit] WOM WITH(NOLOCK) INNER JOIN #TempTableWOM tmp ON WOM.SubWorkOrderMaterialsKitMappingId = tmp.SubWorkOrderMaterialsKitMappingId
					WHERE WOM.SubWorkOrderMaterialsKitMappingId = tmp.SubWorkOrderMaterialsKitMappingId

					UPDATE P    
				    SET WorkOrderMaterialsId = 0, 
					       IsKit = 0, IsSubWO =0, 
						   UpdatedDate = GETUTCDATE()
					FROM DBO.PurchaseOrderPart P
					  INNER JOIN #TempWOtblM tmp ON P.WorkOrderMaterialsId = tmp.SubWorkOrderMaterialsKitId
					  WHERE P.WorkOrderMaterialsId  = tmp.SubWorkOrderMaterialsKitId AND ISNULL(IsKit,0) = 1 AND ISNULL(IsSubWO,0) = 1


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