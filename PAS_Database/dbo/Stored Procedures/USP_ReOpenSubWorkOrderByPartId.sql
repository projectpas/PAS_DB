/*************************************************************           
 ** File:   [USP_ReOpenSubWorkOrderByPartId]           
 ** Author:  HEMANT SALIYA
 ** Description: This stored procedure is used TO DELETE Sub WorkOrder BY ID
 ** Purpose:         
 ** Date:   01/16/2024      
          
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    01/16/2024   HEMANT SALIYA			Created

     
exec [USP_ReOpenSubWorkOrderByPartId] 

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_ReOpenSubWorkOrderByPartId]
@SubWOPartNoId BIGINT = NULL,
@UserName VARCHAR(100) = NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
	BEGIN TRANSACTION
		
	IF(ISNULL(@SubWOPartNoId, 0) > 0)
	BEGIN
		
		DECLARE 
		@SWOStockLineId BIGINT = 0,
		@RevisedStockLineId BIGINT = 0,
		@WorkOrderMaterialId BIGINT = 0;

		IF OBJECT_ID('tempdb..#tempSubWOPart') IS NOT NULL
			DROP TABLE #tempSubWOPart

		CREATE TABLE #tempSubWOPart
		(
			ID INT IDENTITY(1,1) NOT NULL,
			SubWorkOrderId BIGINT NULL,
			SubWOPartNoId BIGINT NULL,
		)

		INSERT INTO #tempSubWOPart(SubWorkOrderId, SubWOPartNoId)
		SELECT SubWorkOrderId, SubWOPartNoId FROM [dbo].[SubWorkOrderPartNumber] WHERE [SubWorkOrderId] = @SubWOPartNoId;

		

	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			 ROLLBACK TRAN;
	         DECLARE @ErrorLogID INT
			 
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_ReOpenSubWorkOrderByPartId'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SubWOPartNoId, '') AS VARCHAR(100))
			   		                                           
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