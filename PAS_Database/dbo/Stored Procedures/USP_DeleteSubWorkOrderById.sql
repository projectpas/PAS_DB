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

	IF(ISNULL(@SubWorkOrderId, 0) > 0)
	BEGIN
		
		DECLARE @LaborHeaderId BIGINT = 0,
		@SWOStockLineId BIGINT = 0,
		@SWOQty BIGINT = 0;

		SET @LaborHeaderId = (SELECT [SubWorkOrderLaborHeaderId] FROM [dbo].[SubWorkOrderLaborHeader] WITH(NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId);
		SELECT @SWOStockLineId = [StockLineId] FROM [dbo].[SubWorkOrder] WITH(NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId;
		SELECT @SWOQty = SUM(ISNULL(Quantity, 0)) FROM [dbo].[SubWorkOrderPartNumber] WITH(NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId;
		
		UPDATE [dbo].[Stockline]
		SET QuantityAvailable = @SWOQty
		WHERE [StockLineId] = @SWOStockLineId;

		UPDATE [dbo].[SubWorkOrder]
		SET [IsDeleted] = 1, [UpdatedBy] = @UserName, [UpdatedDate] = GETUTCDATE()
		WHERE [SubWorkOrderId] = @SubWorkOrderId

	END

	END TRY    
	BEGIN CATCH      
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