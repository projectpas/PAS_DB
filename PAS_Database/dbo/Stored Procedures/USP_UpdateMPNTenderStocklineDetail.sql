/*************************************************************           
 ** File:     [USP_UpdateMPNTenderStocklineDetail]           
 ** Author:	  Moin Bloch
 ** Description: This SP IS Used update Tendor Stockline 
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

	EXEC [USP_UpdateMPNTenderStocklineDetail] 1,1,'dsdsd'
**************************************************************/ 
create   PROCEDURE [dbo].[USP_UpdateMPNTenderStocklineDetail]
@WorkOrderId BIGINT,
@WorkOrderPartNumberId BIGINT,
@UpdatedBy VARCHAR(50),
@Opr INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN	
				
				DECLARE @StockLineId BIGINT = 0;
				DECLARE @QuantityReserved INT = 0;
				DECLARE @QuantityOnHand INT = 0;
				DECLARE @QuantityAvailable INT = 0;
				DECLARE @QuantityIssued INT = 0;
					
				SELECT @StockLineId = [StockLineId] FROM  [dbo].[WorkOrderPartNumber] WITH(NOLOCK)  WHERE [WorkOrderId] = @WorkOrderId AND [ID] = @WorkOrderPartNumberId;

				SELECT @QuantityReserved = ISNULL([QuantityReserved],0),
				       @QuantityOnHand = ISNULL([QuantityOnHand],0), 
				       @QuantityAvailable = ISNULL([QuantityAvailable],0),
					   @QuantityIssued = ISNULL([QuantityIssued],0)
				FROM  [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StocklineId;

				
				IF(@Opr = 1)   -- If Remaining Amount > 0
				BEGIN
					UPDATE [dbo].[Stockline] 
					   SET [QuantityReserved] = @QuantityReserved - 1,
						   [QuantityOnHand] = @QuantityOnHand - 1,						   
						   [QuantityIssued] = @QuantityIssued + 1
					 WHERE [StockLineId] = @StocklineId;	
				END
				IF(@Opr = 2)  -- If Remaining Amount = 0
				BEGIN
					UPDATE [dbo].[Stockline] 
					   SET [QuantityReserved] = @QuantityReserved - 1,
						   [QuantityAvailable] = @QuantityAvailable + 1
					 WHERE [StockLineId] = @StocklineId;	
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
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateTenderStocklineDetail' 
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