/*************************************************************             
 ** File:   [USP_UpdateReceivingReconciliationStocklineAdjustments]             
 ** Author:   
 ** Description: This stored procedure is used to update  Stockline Adjustment,Freight Adjustment,Tax Adjustment
 ** Date:   09/10/2023
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    09/10/2023   Moin Bloch    Created 
	2    06/11/2023   Moin Bloch    Modified(added FreightAdjustmentPerUnit And TaxAdjustmentPerUnit) 
	       
EXEC [dbo].[USP_UpdateReceivingReconciliationStocklineAdjustments] 118

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateReceivingReconciliationStocklineAdjustments]
@ReceivingReconciliationId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN	
			DECLARE @TotalRecord int = 0;   
		    DECLARE @MinId BIGINT = 1;  			
			DECLARE @StocklineId BIGINT;  
			DECLARE @IsManual BIT;	
			DECLARE @Type INT;
			DECLARE @InvoicedQty INT;
			DECLARE @InvoicedUnitCost DECIMAL(18,2) 
			DECLARE @AdjUnitCost DECIMAL(18,2) 
			DECLARE @Freight INT  = 1
			DECLARE @Tax INT  = 3
			DECLARE @TotalFreight DECIMAL(18,2) 
			DECLARE @TotalTax DECIMAL(18,2) 
			DECLARE @FreightAdjustment DECIMAL(18,2) 
			DECLARE @TaxAdjustment DECIMAL(18,2) 
			DECLARE @StockType VARCHAR(20)
									
			IF OBJECT_ID(N'tempdb..#RRStockAdjustment') IS NOT NULL    
			BEGIN    
				DROP TABLE #RRStockAdjustment  
			END  

		    CREATE TABLE #RRStockAdjustment  
			(    
			    [ID] [BIGINT] NOT NULL IDENTITY, 
				[StocklineId] [BIGINT] NULL,
				[IsManual] [BIT] NULL,		
				[Type] [INT] NULL,				 
                [InvoicedQty] [INT] NULL,           
                [InvoicedUnitCost] [DECIMAL](18,2) NULL,         
				[AdjUnitCost] [DECIMAL](18,2) NULL, 
				[PackagingId] [INT] NULL,
				[StockType] [VARCHAR](20),
				[FreightAdjustmentPerUnit] [DECIMAL](18,2) NULL,  
				[TaxAdjustmentPerUnit] [DECIMAL](18,2) NULL
			) 

			INSERT INTO #RRStockAdjustment ([StocklineId],[IsManual],[Type],[InvoicedQty],[InvoicedUnitCost],[AdjUnitCost],[PackagingId],[StockType],[FreightAdjustmentPerUnit],[TaxAdjustmentPerUnit])
									 SELECT [StocklineId],[IsManual],[Type],[InvoicedQty],[InvoicedUnitCost],[AdjUnitCost],[PackagingId],[StockType],[FreightAdjustmentPerUnit],[TaxAdjustmentPerUnit]
									   FROM [dbo].[ReceivingReconciliationDetails] WITH(NOLOCK) 
									  WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId;
            -- Total Invoice Qty
			SELECT @InvoicedQty = SUM(ISNULL([InvoicedQty],0)) FROM #RRStockAdjustment WHERE [IsManual] = 0; 
			
			-- Total Freight
			SELECT @TotalFreight = SUM(ISNULL([InvoicedUnitCost],0)) FROM #RRStockAdjustment WHERE [IsManual] = 1 AND [PackagingId] = @Freight;
			
			-- Total Tax
			SELECT @TotalTax = SUM(ISNULL([InvoicedUnitCost],0)) FROM #RRStockAdjustment WHERE [IsManual] = 1 AND [PackagingId] =  @Tax;
				
		    SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #RRStockAdjustment WHERE [IsManual] = 0;   

			WHILE @MinId <= @TotalRecord
			BEGIN	
				DECLARE @PurchaseOrderUnitCost DECIMAL(18,2) = 0;
				DECLARE @RepairOrderUnitCost DECIMAL(18,2) = 0;
				DECLARE @UnitCost DECIMAL(18,2) = 0;
				DECLARE @FreightAdjustmentPerUnit DECIMAL(18,2) = 0;
				DECLARE @TaxAdjustmentPerUnit DECIMAL(18,2) = 0;

				SELECT @StocklineId = [StocklineId],
				       @IsManual = [IsManual],
				       @Type = [Type],					   
			           @AdjUnitCost = [AdjUnitCost],
					   @StockType = [StockType],
					   @FreightAdjustmentPerUnit = ISNULL([FreightAdjustmentPerUnit],0),					  
					   @TaxAdjustmentPerUnit = ISNULL([TaxAdjustmentPerUnit],0)
				  FROM #RRStockAdjustment WHERE [ID] = @MinId;	
				  
				--SET @FreightAdjustment = (@TotalFreight / @InvoicedQty);

				--SET @TaxAdjustment = (@TotalTax / @InvoicedQty);

				SET @FreightAdjustment = @FreightAdjustmentPerUnit;

				SET @TaxAdjustment = @TaxAdjustmentPerUnit;
				
				IF(UPPER(@StockType) = 'STOCK')
				BEGIN					
					SELECT @PurchaseOrderUnitCost = [PurchaseOrderUnitCost],
					       @RepairOrderUnitCost = [RepairOrderUnitCost],
						   @UnitCost = [UnitCost]
					  FROM [dbo].[Stockline] WHERE [StockLineId] = @StocklineId;
					  
					UPDATE SL
					   SET SL.[Adjustment] = ISNULL(SL.[Adjustment], 0) + (ISNULL(@AdjUnitCost,0) + ISNULL(@FreightAdjustment,0) + ISNULL(@TaxAdjustment,0)),
						   SL.[FreightAdjustment] = ISNULL(SL.[FreightAdjustment],0) + ISNULL(@FreightAdjustment,0),
				  	       SL.[TaxAdjustment] = ISNULL(SL.[TaxAdjustment],0) + ISNULL(@TaxAdjustment,0),					      
						   SL.[PurchaseOrderUnitCost] = CASE WHEN @Type = 1 THEN (ISNULL(@PurchaseOrderUnitCost,0) + ISNULL(@AdjUnitCost,0)) ELSE @PurchaseOrderUnitCost END,
				           SL.[RepairOrderUnitCost] = CASE WHEN @Type = 2 THEN (ISNULL(@RepairOrderUnitCost,0) + ISNULL(@AdjUnitCost,0)) ELSE @RepairOrderUnitCost END,				     					
						   SL.[UnitCost] = (ISNULL(@PurchaseOrderUnitCost,0) + ISNULL(@RepairOrderUnitCost,0) + ISNULL(@AdjUnitCost,0) + ISNULL(@FreightAdjustment,0) + ISNULL(@TaxAdjustment,0))
				      FROM [dbo].[Stockline] SL WHERE SL.[StockLineId] = @StocklineId;					  
				END
				IF(UPPER(@StockType) = 'NONSTOCK')
				BEGIN
					PRINT  @StockType
				END
				IF(UPPER(@StockType) = 'ASSET')
				BEGIN
					PRINT  @StockType
				END						
				SET @MinId = @MinId + 1
			END	
	END
    COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0			
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_UpdateReceivingReconciliationStocklineAdjustments' 
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReceivingReconciliationId, '') AS VARCHAR(100))  
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END