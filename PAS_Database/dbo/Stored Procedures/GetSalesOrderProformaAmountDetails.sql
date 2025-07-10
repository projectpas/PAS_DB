/*************************************************************           
 ** File:   [GetSalesOrderProformaAmountDetails]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to retrieve Proforma Invoice Amount Details
 ** Purpose:         
 ** Date:  
 ** PARAMETERS:                   
 ** RETURN VALUE:         
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    05/12/2024   Moin Bloch    Created	
	2    19/12/2024   AMIT GHEDIYA  Get QTY based on selection. 	
	3    07-07-2025   Moin Bloch    Changed Old To New Billing Table

  EXEC [dbo].[GetSalesOrderProformaAmountDetails] 1260,12,0
  EXEC [dbo].[GetSalesOrderProformaAmountDetails] 1260,10,177272
  EXEC [dbo].[GetSalesOrderProformaAmountDetails] 1260,10,180093  
**************************************************************/
CREATE   PROCEDURE [dbo].[GetSalesOrderProformaAmountDetails]
@SalesOrderId BIGINT,
@SalesOrderPartId BIGINT,
@StocklineId BIGINT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  

	DECLARE @SOModuleId INT
	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	
	IF(ISNULL(@StocklineId,0) > 0)
	BEGIN
		SELECT ISNULL(SOSC.[NetSaleAmount],0) NetSaleAmount,
			   ISNULL(sobii.[QtyBilled],0) NoofPieces,
			   ISNULL(SOSC.[NetSaleAmount],0) / ISNULL(stk.[QtyOrder],0) UnitPrice,
			   stk.[StockLineId],
			   ISNULL(stk.[QtyOrder],0) QTYOnBACKOrder
		FROM [dbo].[SalesOrderPartV1] sop WITH (NOLOCK)
		LEFT JOIN [dbo].[SalesOrderStocklineV1] stk WITH (NOLOCK) ON stk.[SalesOrderPartId] = sop.[SalesOrderPartId]
		LEFT JOIN [dbo].[SalesOrderPartCost] spc WITH (NOLOCK) ON spc.[SalesOrderPartId] = sop.[SalesOrderPartId]
		LEFT JOIN [dbo].[SalesOrderStockLineCost] SOSC WITH (NOLOCK) ON SOSC.[SalesOrderStocklineId] = stk.[SalesOrderStocklineId]
		LEFT JOIN [dbo].[BillingInvoicingItems] sobii WITH (NOLOCK) ON sobii.[SubReferenceId] = sop.[SalesOrderPartId] AND (sobii.[StockLineId] = stk.[StockLineId] OR ISNULL(sobii.[StockLineId], 0) = 0) AND ISNULL(sobii.[IsPerformaInvoice],0) = 1 AND ISNULL(sobii.[IsVersionIncrease],0) = 0 AND sobii.[ModuleId] = @SOModuleId
		LEFT JOIN [dbo].[BillingInvoicing] sobi WITH (NOLOCK) ON sobi.[BillingInvoicingId] = sobii.[BillingInvoicingId]  AND ISNULL(sobi.[IsPerformaInvoice],0) = 1 AND sobi.[ReferenceId] = @SalesOrderId AND ISNULL(sobi.[IsVersionIncrease],0) = 0 AND sobi.[ModuleId] = @SOModuleId
		WHERE sop.[SalesOrderId] = @SalesOrderId 
		  AND sop.[SalesOrderPartId] = @SalesOrderPartId
		  AND stk.[StockLineId] = @StocklineId
	END	
	ELSE
	BEGIN
		SELECT ISNULL(spc.[NetSaleAmount],0)  NetSaleAmount,
			   ISNULL(sobii.[QtyBilled],0) NoofPieces,
			   ISNULL(spc.[NetSaleAmount],0) / ISNULL(sop.[QtyRequested],0) UnitPrice,
			   NULL [StockLineId],
			   ISNULL(sop.[QtyRequested],0) QTYOnBACKOrder
		FROM [dbo].[SalesOrderPartV1] sop WITH (NOLOCK)
		LEFT JOIN [dbo].[SalesOrderStocklineV1] stk WITH (NOLOCK) ON stk.[SalesOrderPartId] = sop.[SalesOrderPartId]
		LEFT JOIN [dbo].[SalesOrderPartCost] spc WITH (NOLOCK) ON spc.[SalesOrderPartId] = sop.[SalesOrderPartId]
		LEFT JOIN [dbo].[BillingInvoicingItems] sobii WITH (NOLOCK) ON sobii.[SubReferenceId] = sop.[SalesOrderPartId] AND (sobii.[StockLineId] = stk.[StockLineId] OR ISNULL(sobii.[StockLineId], 0) = 0) AND ISNULL(sobii.[IsPerformaInvoice],0) = 1 AND ISNULL(sobii.[IsVersionIncrease],0) = 0 AND sobii.[ModuleId] = @SOModuleId
		LEFT JOIN [dbo].[BillingInvoicing] sobi WITH (NOLOCK) ON sobi.[BillingInvoicingId] = sobii.[BillingInvoicingId]  AND ISNULL(sobi.[IsPerformaInvoice],0) = 1 AND sobi.[ReferenceId] = @SalesOrderId AND ISNULL(sobi.[IsVersionIncrease],0) = 0 AND sobi.[ModuleId] = @SOModuleId
		WHERE sop.[SalesOrderId] = @SalesOrderId 
		  AND sop.[SalesOrderPartId] = @SalesOrderPartId
	END

  END TRY      
  BEGIN CATCH        
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderProformaAmountDetails'   
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END