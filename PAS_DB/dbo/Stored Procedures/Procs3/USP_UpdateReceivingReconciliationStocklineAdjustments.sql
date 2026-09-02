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
	3    28/01/2025   Moin Bloch    Modified(Removed POUnitCost & RoUnitCost update in stockline)
	4    01/09/2026   Moin Bloch    Modified(added [COGSUnitCost],[MiscAdjustment] calculation) PN-17835
	       
EXEC [dbo].[USP_UpdateReceivingReconciliationStocklineAdjustments] 217

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
			-- DECLARE @InvoicedQty INT;  comment Due to not in use
			DECLARE @InvoicedUnitCost DECIMAL(18,2) = 0
			DECLARE @AdjUnitCost DECIMAL(18,2) = 0
			DECLARE @Freight INT  = 1
			DECLARE @MISC INT  = 2
			DECLARE @Tax INT  = 3
			--DECLARE @TotalFreight DECIMAL(18,2) = 0  comment Due to not in use
			--DECLARE @TotalMisc DECIMAL(18,2) = 0     comment Due to not in use
			--DECLARE @TotalTax DECIMAL(18,2) = 0      comment Due to not in use 
			DECLARE @FreightAdjustment DECIMAL(18,2) = 0
			DECLARE @MiscAdjustment DECIMAL(18,2) = 0
			DECLARE @TaxAdjustment DECIMAL(18,2) = 0
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
				[TaxAdjustmentPerUnit] [DECIMAL](18,2) NULL,
				[RowNum] [BIGINT] NULL          -- NEW: dense sequence for the loop
			) 			

			INSERT INTO #RRStockAdjustment ([StocklineId],[IsManual],[Type],[InvoicedQty],[InvoicedUnitCost],[AdjUnitCost],[PackagingId],[StockType],[FreightAdjustmentPerUnit],[TaxAdjustmentPerUnit])
									 SELECT [StocklineId],[IsManual],[Type],[InvoicedQty],[InvoicedUnitCost],[AdjUnitCost],[PackagingId],[StockType],[FreightAdjustmentPerUnit],[TaxAdjustmentPerUnit]
									   FROM [dbo].[ReceivingReconciliationDetails] WITH(NOLOCK) 
									  WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId;

			-- assign a gapless sequence only across IsManual = 0 rows
			;WITH CTE AS
			(
				SELECT [ID], ROW_NUMBER() OVER (ORDER BY [ID]) AS [RN]
				FROM #RRStockAdjustment
				WHERE [IsManual] = 0
			)

			UPDATE t SET t.[RowNum] = c.[RN] FROM #RRStockAdjustment t JOIN CTE c ON c.[ID] = t.[ID];

            -- Total Invoice Qty
			-- SELECT @InvoicedQty = SUM(ISNULL([InvoicedQty],0)) FROM #RRStockAdjustment WHERE [IsManual] = 0; 
			
			-- Total Freight
			--SELECT @TotalFreight = SUM(ISNULL([InvoicedUnitCost],0)) FROM #RRStockAdjustment WHERE [IsManual] = 1 AND [PackagingId] = @Freight;

			-- Total Freight
			--SELECT @TotalMisc = SUM(ISNULL([InvoicedUnitCost],0)) FROM #RRStockAdjustment WHERE [IsManual] = 1 AND [PackagingId] = @MISC;
			
			-- Total Tax
			--SELECT @TotalTax = SUM(ISNULL([InvoicedUnitCost],0)) FROM #RRStockAdjustment WHERE [IsManual] = 1 AND [PackagingId] =  @Tax;
					   				
			SELECT @TotalRecord = COUNT(*), @MinId = MIN([RowNum]) FROM #RRStockAdjustment WHERE [IsManual] = 0;
					
			WHILE @MinId <= @TotalRecord
			BEGIN					
				DECLARE @PurchaseOrderUnitCost DECIMAL(18,2) = 0;
				DECLARE @RepairOrderUnitCost DECIMAL(18,2) = 0;
				--DECLARE @UnitCost DECIMAL(18,2) = 0;
				DECLARE @FreightAdjustmentPerUnit DECIMAL(18,2) = 0;
				DECLARE @TaxAdjustmentPerUnit DECIMAL(18,2) = 0;
				DECLARE @MiscAdjustmentPerUnit DECIMAL(18,2) = 0;
				--DECLARE @COGSUnitCost DECIMAL(18,2) = 0;

				SELECT @StocklineId = [StocklineId],
				       @IsManual = [IsManual],
				       @Type = [Type],					   
			           @AdjUnitCost = [AdjUnitCost],
					   @StockType = [StockType],
					   @FreightAdjustmentPerUnit = ISNULL([FreightAdjustmentPerUnit],0),					  
					   @TaxAdjustmentPerUnit = ISNULL([TaxAdjustmentPerUnit],0),
					   @MiscAdjustmentPerUnit = ISNULL([MiscAdjustmentPerUnit],0)
				  FROM #RRStockAdjustment WHERE [RowNum] = @MinId;	
				  
				SET @MiscAdjustment = @MiscAdjustmentPerUnit;
				
				SET @FreightAdjustment = @FreightAdjustmentPerUnit;

				SET @TaxAdjustment = @TaxAdjustmentPerUnit;
				
				IF(UPPER(@StockType) = 'STOCK')
				BEGIN					
					SELECT @PurchaseOrderUnitCost = [PurchaseOrderUnitCost],
					       @RepairOrderUnitCost = [RepairOrderUnitCost]
						   --@UnitCost = [UnitCost],
						   --@COGSUnitCost = ISNULL([COGSUnitCost],0)
					  FROM [dbo].[Stockline] WHERE [StockLineId] = @StocklineId;	
					  
					UPDATE SL
					   SET SL.[Adjustment] = ISNULL(SL.[Adjustment], 0) + (ISNULL(@AdjUnitCost,0) + ISNULL(@FreightAdjustment,0) + ISNULL(@TaxAdjustment,0)),
						   SL.[FreightAdjustment] = ISNULL(SL.[FreightAdjustment],0) + ISNULL(@FreightAdjustment,0),
						   SL.[MiscAdjustment] = ISNULL(SL.[MiscAdjustment],0) + ISNULL(@MiscAdjustment,0),
				  	       SL.[TaxAdjustment] = ISNULL(SL.[TaxAdjustment],0) + ISNULL(@TaxAdjustment,0),					      						   			     					
						   SL.[UnitCost] = (ISNULL(@PurchaseOrderUnitCost,0) + ISNULL(@RepairOrderUnitCost,0) + ISNULL(@AdjUnitCost,0) + ISNULL(@MiscAdjustment,0) + ISNULL(@FreightAdjustment,0) + ISNULL(@TaxAdjustment,0)),
						   SL.[COGSUnitCost] = ISNULL([COGSUnitCost],0) + (ISNULL(@AdjUnitCost,0) + ISNULL(@FreightAdjustment,0) + ISNULL(@MiscAdjustment,0) + ISNULL(@TaxAdjustment,0))
					  FROM [dbo].[Stockline] SL WHERE SL.[StockLineId] = @StocklineId;	

					  EXEC [dbo].[USP_Lot_UpdateCOGSByStocklineId] @StocklineId,@FreightAdjustment,@MiscAdjustment,@TaxAdjustment
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