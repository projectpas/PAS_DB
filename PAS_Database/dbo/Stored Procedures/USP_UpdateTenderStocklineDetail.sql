﻿/*************************************************************           
 ** File:     [USP_UpdateTenderStocklineDetail]           
 ** Author:	  Moin Bloch
 ** Description: This SP IS Used update Tendor Stockline Serial Number And Condition
 ** Purpose:         
 ** Date:   01/04/2024	          
 ** PARAMETERS:       
 ** RETURN VALUE:     
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date			Author					Change Description            
 ** --   	--------		-------				--------------------------------     
	1		01/04/2024		Moin Bloch			CREATED
	2		05/04/2024		Moin Bloch			Added Unit Cost

	EXEC [USP_UpdateTenderStocklineDetail] 1,1,'dsdsd'
**************************************************************/ 
CREATE PROCEDURE [dbo].[USP_UpdateTenderStocklineDetail]
@WorkOrderId BIGINT,
@WorkOrderPartNumberId BIGINT,
@StocklineId  BIGINT,
@ConditionId BIGINT,
@SerialrNumber varchar(50),
@UnitCost DECIMAL(18,2) NULL = 0,
@Opr INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN	
				DECLARE @TendorStocklineCost DECIMAL(18,2) = 0;				
				DECLARE @StkUnitCost DECIMAL(18,2) = 0;
				DECLARE @MarginUnitCost DECIMAL(18,2) = 0;
				
				IF(@Opr = 1)
				BEGIN
					DECLARE @Condition VARCHAR(50)
					SELECT @Condition = [Description] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [ConditionId] = @ConditionId;

					UPDATE [dbo].[Stockline] 
					   SET [ConditionId] = @ConditionId,
						   [Condition] = @Condition, 
						   [SerialNumber] = @SerialrNumber
					 WHERE [StockLineId] = @StocklineId;	
				END
				ELSE
				BEGIN
					
				  SELECT @StkUnitCost = ISNULL([UnitCost],0) FROM  [dbo].[Stockline] WHERE [StockLineId] = @StocklineId;
				  SELECT @TendorStocklineCost = ISNULL([TendorStocklineCost],0) FROM  [dbo].[WorkOrderPartNumber]  WHERE [WorkOrderId] = @WorkOrderId AND [ID] = @WorkOrderPartNumberId;
				  
				  IF(@StkUnitCost > @UnitCost)
				  BEGIN
						SET @MarginUnitCost = @StkUnitCost - @UnitCost;
						
						UPDATE  [dbo].[WorkOrderPartNumber] 
					        SET [TendorStocklineCost] = @TendorStocklineCost - @MarginUnitCost 
					      WHERE [WorkOrderId] = @WorkOrderId 
					        AND [ID] = @WorkOrderPartNumberId;
				  END
				  IF(@StkUnitCost < @UnitCost)
				  BEGIN
						SET @MarginUnitCost = @UnitCost - @StkUnitCost;

						UPDATE  [dbo].[WorkOrderPartNumber] 
					        SET [TendorStocklineCost] = @TendorStocklineCost + @MarginUnitCost 
					      WHERE [WorkOrderId] = @WorkOrderId 
					        AND [ID] = @WorkOrderPartNumberId;
				  END
				  UPDATE [dbo].[Stockline] SET [UnitCost] = @UnitCost WHERE [StockLineId] = @StocklineId;
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