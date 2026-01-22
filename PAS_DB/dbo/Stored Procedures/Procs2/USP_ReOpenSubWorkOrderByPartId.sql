/*************************************************************           
 ** File:   [USP_ReOpenSubWorkOrderByPartId]           
 ** Author:  HEMANT SALIYA
 ** Description: This stored procedure is used TO Re Open Sub WorkOrder BY Part ID
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
		@SubWorkOrderId BIGINT = 0,
		@SWOStockLineId BIGINT = 0,
		@MasterCompanyId INT = 0,
		@RevisedStockLineId BIGINT = 0,
		@WorkOrderMaterialId BIGINT = 0;
		DECLARE @SubWOQuantity INT = 1; -- It will be Always 1  
		DECLARE @SubWorkOrderStatusId INT = 0; 
		DECLARE @SubWorkOrderStageId INT = 0; 
		
		SELECT @SubWorkOrderStatusId = Id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE [Status] = 'Open'

		IF(ISNULL(@SubWorkOrderStatusId, 0) <= 0)
		BEGIN
			SET @SubWorkOrderStatusId = 1 -- It will be Open
		END

		SELECT @RevisedStockLineId = RevisedStockLineId, @SubWorkOrderId = SubWorkOrderId, @MasterCompanyId = MasterCompanyId FROM dbo.SubWorkOrderPartNumber WITH(NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId 
		SELECT TOP 1 @SubWorkOrderStageId = WorkOrderStageId FROM dbo.WorkOrderStage WITH(NOLOCK) WHERE StageCode IN ('RECEIVED', 'OPEN') AND MasterCompanyId = @MasterCompanyId

		UPDATE dbo.Stockline SET QuantityReserved = ISNULL(QuantityReserved, 0) + ISNULL(@SubWOQuantity, 0) , 
								 QuantityAvailable = ISNULL(QuantityAvailable, 0) - ISNULL(@SubWOQuantity, 0)
		WHERE StockLineId = @RevisedStockLineId
		UPDATE dbo.SubWorkOrder SET SubWorkOrderStatusId = @SubWorkOrderStatusId WHERE  SubWorkOrderId = @SubWorkOrderId
		UPDATE dbo.SubWorkOrderPartNumber SET SubWorkOrderStatusId = @SubWorkOrderStatusId, SubWorkOrderStageId = @SubWorkOrderStageId, 
				IsClosed = 0, IsFinishGood = 0, islocked = 0 , IsTransferredToParentWO = 0
		WHERE  SubWorkOrderId = @SubWorkOrderId

		UPDATE SubWorkOrderSettlementDetails SET IsMastervalue = 0, Isvalue_NA = 0, ConditionId = NULL, conditionName = null, RevisedItemmasterid = null WHERE SubWorkOrderId = @SubWorkOrderId AND WorkOrderSettlementId IN (7, 9)

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