CREATE        PROCEDURE [dbo].[USP_EmailBody_WorkOrderStageChange]
@WorkOrderId BIGINT,
@WorkOrderStageId BIGINT,
@WorkOrderPartNumberId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @OldStageId BIGINT = 0
				
				SELECT top 1 @OldStageId = OldStageId from WorkOrderTurnArroundTime  where WorkOrderPartNoId =@WorkOrderPartNumberId and CurrentStageId=@WorkOrderStageId order by wotatid desc

				SELECT 
						WO.WorkOrderNum AS 'WONum',
						SL.PartNumber,
						WOS.Stage AS 'PreviousStage',
						WOSD.Stage AS 'UpdatedStage'
							From [dbo].[WorkOrderPartNumber] WOPN WITH(NOLOCK)
							LEFT JOIN [dbo].[StockLine] SL WITH(NOLOCK) ON SL.StockLineId = WOPN.StockLineId
							LEFT JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WOPN.WorkOrderId
							LEFT JOIN [dbo].[WorkOrderStage] WOS WITH(NOLOCK) ON WOS.WorkOrderStageId = @OldStageId
							LEFT JOIN [dbo].[WorkOrderStage] WOSD WITH(NOLOCK) ON WOSD.WorkOrderStageId = @WorkOrderStageId
							where ID = @WorkOrderPartNumberId  AND WOPN.WorkOrderId = @WorkOrderId
			 END
                
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_EmailBody_WorkOrderStageChange' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '' 
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