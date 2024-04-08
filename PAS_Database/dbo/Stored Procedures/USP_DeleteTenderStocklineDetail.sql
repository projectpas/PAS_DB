/*************************************************************           
 ** File:     [USP_DeleteTenderStocklineDetail]           
 ** Author:	  Moin Bloch
 ** Description: This SP IS Used to delete Tendor Stockline 
 ** Purpose:         
 ** Date:   08/04/2024	          
 ** PARAMETERS:       
 ** RETURN VALUE:     
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date			Author					Change Description            
 ** --   	--------		-------				--------------------------------     
	1		08/04/2024		Moin Bloch			CREATED
	
	EXEC [USP_DeleteTenderStocklineDetail] 3801,3299,177958,100
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_DeleteTenderStocklineDetail]
@WorkOrderId BIGINT,
@WorkOrderPartNumberId BIGINT,
@StocklineId  BIGINT,
@UpdatedBy VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

				DECLARE @TendorStocklineCost DECIMAL(18,2) = 0;
				DECLARE @StkUnitCost DECIMAL(18,2) = 0;
				
				SELECT @StkUnitCost = ISNULL([UnitCost],0) FROM  [dbo].[Stockline] WHERE [StockLineId] = @StocklineId;
				SELECT @TendorStocklineCost = ISNULL([TendorStocklineCost],0) FROM  [dbo].[WorkOrderPartNumber]  WHERE [WorkOrderId] = @WorkOrderId AND [ID] = @WorkOrderPartNumberId;
			
				UPDATE [dbo].[WorkOrderPartNumber] 
				   SET [TendorStocklineCost] = @TendorStocklineCost - @StkUnitCost, 
				       [UpdatedBy] = @UpdatedBy,
					   [UpdatedDate] = GETUTCDATE()
				 WHERE [WorkOrderId] = @WorkOrderId 
				   AND [ID] = @WorkOrderPartNumberId;

				UPDATE [dbo].[Stockline] 
				   SET [isDeleted] = 1, 
				       [UpdatedBy] = @UpdatedBy,
					   [UpdatedDate] = GETUTCDATE()
				 WHERE [StockLineId] = @StocklineId;
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0				
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteTenderStocklineDetail' 
               ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StocklineId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END