
/*************************************************************   
-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <07-11-2023>
-- Description:	<Delete Sub WO Materials & its Stockline if not issued/ reserved & no WO Provision>
-- =============================================
**************************************************************

** Change History 
**************************************************************   
** PR   Date			Author				Change Description  
** --   --------		-------				--------------------------------
** 1    07-11-2023		Ayesha Sultana		Created - Delete WO Materials & its Stockline if not issued/ reserved & no WO Provision

**************************************************************/ 

CREATE    PROCEDURE [dbo].[DeleteSubWOMaterialsOnIssuedOrReserved]
	@SubWOPartNoId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN TRANSACTION

			IF OBJECT_ID(N'tempdb..##TempSubWOtbl') IS NOT NULL
				BEGIN
					DROP TABLE #TempSubWOtbl
				END

			CREATE TABLE #TempSubWOtbl(SubWorkOrderMaterialsId BIGINT)

			INSERT INTO #TempSubWOtbl (SubWorkOrderMaterialsId)

			SELECT DISTINCT SWOM.SubWorkOrderMaterialsId

			FROM dbo.SubWorkOrderMaterials SWOM WITH(NOLOCK)

			WHERE SWOM.SubWOPartNoId = @SubWOPartNoId 
					AND (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0)) = 0 

			DELETE SWOMS FROM dbo.SubWorkOrderMaterialStockLine SWOMS JOIN #TempSubWOtbl tmpWOM ON SWOMS.SubWorkOrderMaterialsId = tmpWOM.SubWorkOrderMaterialsId
			DELETE SWOM FROM dbo.SubWorkOrderMaterials SWOM JOIN #TempSubWOtbl tmpWOM ON SWOM.SubWorkOrderMaterialsId = tmpWOM.SubWorkOrderMaterialsId;

			IF OBJECT_ID(N'tempdb..##TempSubWOtbl') IS NOT NULL
				BEGIN
					DROP TABLE #TempSubWOtbl 
				END

			COMMIT  TRANSACTION
		END TRY
		
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteSubWOMaterialsOnIssuedOrReserved' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWOPartNoId, '') + ''
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