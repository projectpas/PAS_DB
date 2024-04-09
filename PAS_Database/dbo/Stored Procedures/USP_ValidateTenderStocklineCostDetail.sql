/*************************************************************           
 ** File:     [USP_ValidateTenderStocklineCostDetail]           
 ** Author:	  Moin Bloch
 ** Description: This SP IS Used to Validate Tendor Stockline 
 ** Purpose:         
 ** Date:   01/04/2024	          
 ** PARAMETERS:       
 ** RETURN VALUE:     
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date			Author					Change Description            
 ** --   	--------		-------				--------------------------------     
	1		05/04/2024		Moin Bloch			CREATED
	
	EXEC [USP_ValidateTenderStocklineCostDetail] 3801,3299,177958,100
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_ValidateTenderStocklineCostDetail]
@WorkOrderId BIGINT,
@WorkOrderPartNumberId BIGINT,
@StocklineId  BIGINT,
@UnitCost DECIMAL(18,2)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY

				DECLARE @TendorStocklineCost DECIMAL(18,2) = 0;
				DECLARE @StocklineCost DECIMAL(18,2) = 0;
				DECLARE @PartsCost DECIMAL(18,2) = 0;
				DECLARE @LaborCost DECIMAL(18,2) = 0;
				DECLARE @OtherCost DECIMAL(18,2) = 0;
				DECLARE @StkUnitCost DECIMAL(18,2) = 0;
				DECLARE @MarginUnitCost DECIMAL(18,2) = 0;
				DECLARE @TotalTendorCost DECIMAL(18,2) = 0;
				DECLARE @TotalCost DECIMAL(18,2) = 0;		
				DECLARE @RemainingCost DECIMAL(18,2) = 0;	

				SELECT @StkUnitCost = ISNULL([UnitCost],0) FROM  [dbo].[Stockline] WHERE [StockLineId] = @StocklineId;
				SELECT @TendorStocklineCost = ISNULL([TendorStocklineCost],0) FROM  [dbo].[WorkOrderPartNumber]  WHERE [WorkOrderId] = @WorkOrderId AND [ID] = @WorkOrderPartNumberId;
				
				SELECT @PartsCost = ISNULL(WOPC.PartsCost,0), 
				       @LaborCost = ISNULL(WOPC.LaborCost,0), 
					   @OtherCost = ISNULL(WOPC.OtherCost,0),
					   @StocklineCost = ISNULL(WOP.StocklineCost,0)
				  FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) 
                  LEFT JOIN [dbo].[WorkOrderMPNCostDetails] WOPC WITH(NOLOCK) ON WOP.ID = WOPC.WOPartNoId
				  WHERE WOP.[WorkOrderId] = @WorkOrderId 
				    AND WOP.[ID] = @WorkOrderPartNumberId;

				  IF(@StkUnitCost > @UnitCost)
				  BEGIN
						SET @MarginUnitCost = @StkUnitCost - @UnitCost;	
						SET @TotalTendorCost = @TendorStocklineCost - @MarginUnitCost 
				  END
				  IF(@StkUnitCost < @UnitCost)
				  BEGIN
						SET @MarginUnitCost = @UnitCost - @StkUnitCost;	
						SET @TotalTendorCost = @TendorStocklineCost + @MarginUnitCost; 
				  END
				  
				  SET @TotalCost = @StocklineCost + @PartsCost + @LaborCost + @OtherCost;
								  
				  SET @RemainingCost = ISNULL(@TotalCost,0) - ISNULL(@TotalTendorCost,0)
				  
				  SELECT @RemainingCost AS RemainingCost
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ValidateTenderStocklineCostDetail' 
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