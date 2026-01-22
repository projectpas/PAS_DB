
/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <07/30/2021>  
** Description: <Delete Items From WO Materisl When Work Flow has been Changed>  
  
Exec [usp_SaveWorkOrderMaterials] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    07/30/2021  Hemant Saliya    Delete Items From WO Materisl When Work Flow has been Changed

EXEC dbo.usp_DeleteWFMaterialsFromWOMaterils 54,'Admin'

**************************************************************/ 
CREATE PROCEDURE [dbo].[usp_DeleteWFMaterialsFromWOMaterils]
	@WorkFlowWorkOrderId BIGINT
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					IF OBJECT_ID(N'tempdb..#TempWorkOrderMaterials') IS NOT NULL
					BEGIN
						DROP TABLE #TempWorkOrderMaterials 
					END
					CREATE TABLE #TempWorkOrderMaterials(WorkOrderMaterialsId BIGINT)

					INSERT INTO #TempWorkOrderMaterials (WorkOrderMaterialsId)
					SELECT DISTINCT WorkOrderMaterialsId 
					FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.IsFromWorkFlow = 1 AND (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0)) = 0;
					
					UPDATE dbo.Stockline  SET WorkOrderMaterialsId = NULL FROM dbo.Stockline S JOIN #TempWorkOrderMaterials tmpWOM ON S.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId

					DELETE WOIS FROM dbo.WorkOrderIssuedStock WOIS JOIN #TempWorkOrderMaterials tmpWOM ON WOIS.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId;

					DELETE WOUS FROM dbo.WorkOrderUnIssuedStock WOUS JOIN #TempWorkOrderMaterials tmpWOM ON WOUS.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId;
					
					DELETE WORS FROM dbo.WorkOrderReservedStock WORS JOIN #TempWorkOrderMaterials tmpWOM ON WORS.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId

					DELETE WOURS FROM dbo.WorkOrderUnReservedStock WOURS JOIN #TempWorkOrderMaterials tmpWOM ON WOURS.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId;

					DELETE WOSR FROM dbo.WorkOrderStockLineReserve WOSR JOIN #TempWorkOrderMaterials tmpWOM ON WOSR.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId;

					DELETE WOMS FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #TempWorkOrderMaterials tmpWOM ON WOMS.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId;

					DELETE WOM FROM dbo.WorkOrderMaterials WOM JOIN #TempWorkOrderMaterials tmpWOM ON WOM.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId;

					IF OBJECT_ID(N'tempdb..#TempWorkOrderMaterials') IS NOT NULL
					BEGIN
						DROP TABLE #TempWorkOrderMaterials 
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
              , @AdhocComments     VARCHAR(150)    = 'usp_DeleteWFMaterialsFromWOMaterils' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowWorkOrderId, '') + ''
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