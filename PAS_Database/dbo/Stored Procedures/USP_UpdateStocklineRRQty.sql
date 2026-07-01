/*************************************************************           
 ** File:   [USP_UpdateStocklineRRQty]           
 ** Author:   Priyansh Patel
 ** Description: This stored procedure updates RRQty (Receiving Reconciliation Qty)
 **              across StockLine, NonStockInventory and AssetInventory based on
 **              StockType, for a list of receiving reconciliation detail rows.
 ** Purpose:         
 ** Date:   30/06/2026   
         
 ** RETURN VALUE: 1 = Success           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author			Change Description            
 ** --   --------      -------			--------------------------------          
    1    30/06/2026    Priyansh Patel	Created - converted from C# loop-based update to set-based SP

--   EXEC [USP_UpdateStocklineRRQty] 
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_UpdateStocklineRRQty]
@tbl_ReceivingReconciliationDetails ReceivingReconciliationDetailsType READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	BEGIN TRY
		DECLARE @UpdatedDate DATETIME2(7) = GETUTCDATE();
		DECLARE @StockType_STOCK    VARCHAR(20) = 'STOCK',
        @StockType_NONSTOCK VARCHAR(20) = 'NONSTOCK',
        @StockType_ASSET    VARCHAR(20) = 'ASSET';

		-- STOCK
		UPDATE SL
		   SET SL.[RRQty] = CASE WHEN CV.[ConvertedRRQty] = ISNULL(CASE WHEN RR.[InvoicedQty] > 0 THEN RR.[InvoicedQty] ELSE 0 END,0) THEN 0
		                         WHEN CV.[ConvertedRRQty] <= SL.[Quantity] THEN SL.[RRQty] - ISNULL(CASE WHEN RR.[InvoicedQty] > 0 THEN RR.[InvoicedQty] ELSE 0 END,0)
		                         ELSE SL.[RRQty] END,
		       SL.[UpdatedDate] = @UpdatedDate
		  FROM [dbo].[StockLine] SL
		 INNER JOIN [dbo].[ItemMaster] IM  WITH (NOLOCK) ON SL.[ItemMasterId] = IM.[ItemMasterId]
		 INNER JOIN @tbl_ReceivingReconciliationDetails RR ON RR.[StocklineId] = SL.[StockLineId] AND RR.[StockType] = @StockType_STOCK    
		 CROSS APPLY (
		        SELECT ConvertedRRQty = CASE WHEN NULLIF(IM.[StockUnitOfMeasure],'') IS NULL OR NULLIF(IM.[PurchaseUnitOfMeasure],'') IS NULL OR IM.[StockUnitOfMeasure] = IM.[PurchaseUnitOfMeasure]
		                                      THEN SL.[RRQty]
		                                      ELSE dbo.fn_ConvertUOM(SL.[RRQty], IM.[StockUnitOfMeasure], IM.[PurchaseUnitOfMeasure], 0, IM.[MasterCompanyId])
		                                 END
		       ) CV;

		-- NONSTOCK
		UPDATE NS
		   SET NS.[RRQty] = CASE WHEN NS.[RRQty] = ISNULL(CASE WHEN RR.[InvoicedQty] > 0 THEN RR.[InvoicedQty] ELSE 0 END,0) THEN 0
		                         WHEN NS.[RRQty] <= NS.[Quantity] THEN NS.[RRQty] - ISNULL(CASE WHEN RR.[InvoicedQty] > 0 THEN RR.[InvoicedQty] ELSE 0 END,0)
		                         ELSE NS.[RRQty] END,
		       NS.[UpdatedDate] = @UpdatedDate
		  FROM [dbo].[NonStockInventory] NS
		 INNER JOIN @tbl_ReceivingReconciliationDetails RR ON RR.[StocklineId] = NS.[NonStockInventoryId] AND RR.[StockType] = @StockType_NONSTOCK

		-- ASSET
		UPDATE AI
		   SET AI.[RRQty] = CASE WHEN AI.[RRQty] = ISNULL(CASE WHEN RR.[InvoicedQty] > 0 THEN RR.[InvoicedQty] ELSE 0 END,0) THEN 0
		                         WHEN AI.[RRQty] <= AI.[Qty] THEN AI.[RRQty] - ISNULL(CASE WHEN RR.[InvoicedQty] > 0 THEN RR.[InvoicedQty] ELSE 0 END,0)
		                         ELSE AI.[RRQty] END,
		       AI.[UpdatedDate] = @UpdatedDate
		  FROM [dbo].[AssetInventory] AI
		 INNER JOIN @tbl_ReceivingReconciliationDetails RR ON RR.[StocklineId] = AI.[AssetInventoryId] AND RR.[StockType] =  @StockType_ASSET
		 WHERE RR.[StocklineId] IS NOT NULL AND RR.[StocklineId] > 0;

	END TRY
	BEGIN CATCH
		PRINT 'ROLLBACK'
		--ROLLBACK TRAN;
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_STATE() AS ErrorState,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_PROCEDURE() AS ErrorProcedure,
			ERROR_LINE() AS ErrorLine,
			ERROR_MESSAGE() AS ErrorMessage;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_UpdateStocklineRRQty' 
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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