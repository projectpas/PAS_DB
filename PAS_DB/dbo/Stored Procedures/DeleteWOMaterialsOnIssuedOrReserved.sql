
/*************************************************************   
-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <26-7-2023>
-- Description:	<Delete WO Materials & its Stockline if not issued/ reserved & no WO Provision>
-- =============================================
**************************************************************

** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    26/7/2023  Ayesha Sultana   Delete WO Materials & its Stockline if not issued/ reserved & no WO Provision

**************************************************************/ 

CREATE   PROCEDURE [dbo].[DeleteWOMaterialsOnIssuedOrReserved]
	@WorkFlowWorkOrderId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN TRANSACTION

			IF OBJECT_ID(N'tempdb..##TempWOtbl') IS NOT NULL
				BEGIN
					DROP TABLE #TempWOtbl
				END

			CREATE TABLE #TempWOtbl(WorkOrderMaterialsId BIGINT)

			INSERT INTO #TempWOtbl (WorkOrderMaterialsId)

			SELECT DISTINCT WOM.WorkOrderMaterialsId

			FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)

			WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
					AND (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0)) = 0 
					AND WOM.ProvisionId NOT IN ( SELECT ProvisionId FROM Provision WHERE Description = 'SUB WORK ORDER') ;

			UPDATE dbo.Stockline SET WorkOrderMaterialsId = NULL FROM dbo.Stockline S JOIN #TempWOtbl tmpWOM ON S.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
			DELETE WOMS FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #TempWOtbl tmpWOM ON WOMS.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
			DELETE WOM FROM dbo.WorkOrderMaterials WOM JOIN #TempWOtbl tmpWOM ON WOM.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId;

			IF OBJECT_ID(N'tempdb..#TempWOtbl') IS NOT NULL
				BEGIN
					DROP TABLE #TempWOtbl 
				END

			COMMIT  TRANSACTION
		END TRY
		
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteWOMaterialsOnIssuedOrReserved' 
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