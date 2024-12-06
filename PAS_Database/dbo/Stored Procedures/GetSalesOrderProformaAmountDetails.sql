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

	IF(ISNULL(@StocklineId,0) > 0)
	BEGIN
		SELECT ISNULL(SOSC.[NetSaleAmount],0) NetSaleAmount,
			   ISNULL(sobii.[NoofPieces],0) NoofPieces,
			   ISNULL(SOSC.[NetSaleAmount],0) / ISNULL(sobii.[NoofPieces],0) UnitPrice,
			   stk.[StockLineId]
		FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
		LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderPartCost spc WITH (NOLOCK) ON spc.SalesOrderPartId = sop.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
		LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobii.SalesOrderPartId = sop.SalesOrderPartId AND (sobii.StockLineId = stk.StockLineId OR ISNULL(sobii.StockLineId, 0) = 0) AND ISNULL(sobii.IsProforma,0) = 1
		LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) ON sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId  AND ISNULL(sobi.IsProforma,0) = 1 AND sobi.SalesOrderId = @SalesOrderId
		WHERE sop.SalesOrderId = @SalesOrderId 
		  AND sop.SalesOrderPartId = @SalesOrderPartId
		  AND stk.StockLineId = @StocklineId
	END	
	ELSE
	BEGIN
		SELECT ISNULL(spc.[NetSaleAmount],0) NetSaleAmount,
			   ISNULL(sobii.[NoofPieces],0) NoofPieces,
			   ISNULL(spc.[NetSaleAmount],0) / ISNULL(sobii.[NoofPieces],0) UnitPrice,
			   NULL [StockLineId]
		FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
		LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderPartCost spc WITH (NOLOCK) ON spc.SalesOrderPartId = sop.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobii.SalesOrderPartId = sop.SalesOrderPartId AND (sobii.StockLineId = stk.StockLineId OR ISNULL(sobii.StockLineId, 0) = 0) AND ISNULL(sobii.IsProforma,0) = 1
		LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) ON sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId  AND ISNULL(sobi.IsProforma,0) = 1 AND sobi.SalesOrderId = @SalesOrderId
		WHERE sop.SalesOrderId = @SalesOrderId 
		  AND sop.SalesOrderPartId = @SalesOrderPartId
	END

  END TRY      
  BEGIN CATCH        
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderProformaAmountDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''  
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