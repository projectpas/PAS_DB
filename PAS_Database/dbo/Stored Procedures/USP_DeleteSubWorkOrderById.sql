/*************************************************************           
 ** File:   [USP_DeleteSubWorkOrderById]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used TO DELETE Sub WorkOrder BY ID
 ** Purpose:         
 ** Date:   12/26/2023      
          
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    12/26/2023   Devendra Shekh			Created
    2    01/05/2024   Devendra Shekh			Created
     
exec [USP_DeleteSubWorkOrderById] 

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_DeleteSubWorkOrderById]
@SubWorkOrderId BIGINT = NULL,
@UserName VARCHAR(100) = NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
	BEGIN TRANSACTION
		
	IF(ISNULL(@SubWorkOrderId, 0) > 0)
	BEGIN
		
		DECLARE	@SWOStockLineId BIGINT = 0,
		@SWOQty BIGINT = 0,
		@WorkOrderMaterialId BIGINT = 0;

		SELECT @SWOStockLineId = [StockLineId], @WorkOrderMaterialId = [WorkOrderMaterialsId] FROM [dbo].[SubWorkOrder] WITH(NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId;
		SELECT @SWOQty = SUM(ISNULL(Quantity, 0)) FROM [dbo].[SubWorkOrderPartNumber] WITH(NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId;

		DELETE FROM [dbo].[WorkOrderMaterialStockLineAudit] WHERE [StockLineId] = @SWOStockLineId AND [WorkOrderMaterialsId] = @WorkOrderMaterialId;
		DELETE FROM [dbo].[WorkOrderMaterialStockLine] WHERE [StockLineId] = @SWOStockLineId AND [WorkOrderMaterialsId] = @WorkOrderMaterialId;

		UPDATE [dbo].[WorkOrderMaterials]
		SET Quantity = Quantity - ISNULL(@SWOQty, 0), [UpdatedDate] = GETUTCDATE()
		WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialId 

		UPDATE [dbo].[Stockline]
		SET [QuantityAvailable] = QuantityAvailable + ISNULL(@SWOQty, 0),
			[QuantityReserved] = ISNULL(QuantityReserved, 0) - ISNULL(@SWOQty, 0),
			[UpdatedBy] = @UserName,
			[UpdatedDate] = GETUTCDATE()
		WHERE [StockLineId] = @SWOStockLineId;
		
		UPDATE [dbo].[SubWorkOrder]
		SET [IsDeleted] = 1, [UpdatedBy] = @UserName, [UpdatedDate] = GETUTCDATE()
		WHERE [SubWorkOrderId] = @SubWorkOrderId

	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			 ROLLBACK TRAN;
	         DECLARE @ErrorLogID INT
			 
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_DeleteSubWorkOrderById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SubWorkOrderId, '') AS VARCHAR(100))
			   		                                           
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