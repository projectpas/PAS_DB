/***************************************************************  
 ** File:   [USP_UpdateSubWorkOrderStageDetails]             
 ** Author:   Shrey Chandegara
 ** Description: Update SubWorkOrder Stage Details
 ** Date:  14-04-2025
            
  ** Change   
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    14-04-2025		Shrey Chandegara		Created  	
		
	exec dbo.USP_UpdateSubWorkOrderStageDetails 8631,8331
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateSubWorkOrderStageDetails]
@SubWorkOrderId BIGINT,
@SubWOPartNoId BIGINT,
@SubWorkOrderStageId BIGINT,
@SubWorkOrderStatusId BIGINT

AS 
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

	UPDATE [dbo].[SubWorkOrder]
		SET 
			SubWorkOrderStatusId = @SubWorkOrderStatusId
		WHERE SubWorkOrderId = @SubWorkOrderId;

	UPDATE [dbo].[SubWorkOrderPartNumber]
        SET 
            SubWorkOrderStatusId = @SubWorkOrderStatusId,
            SubWorkOrderStageId = @SubWorkOrderStageId
        WHERE SubWOPartNoId = @SubWOPartNoId;

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateSubWorkOrderStageDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH

END