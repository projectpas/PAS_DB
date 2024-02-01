/*************************************************************           
 ** File:   [sp_GetSalesOrderPerformaInvoiceChildList]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used to retrieve Invoice child listing data
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	 1    01/29/2024   AMIT GHEDIYA			Created
     
 EXEC [dbo].[sp_GetSalesOrderPerformaInvoiceChildList] 814, 318, 15  
**************************************************************/
CREATE     PROCEDURE [dbo].[sp_GetSalesOrderPerformaInvoiceChildList]
	 @SalesOrderId  bigint,  
	 @SalesOrderPartId bigint,  
	 @ConditionId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
 BEGIN TRANSACTION  
   BEGIN  
		SELECT DISTINCT 0 AS SalesOrderShippingId,   
				sobi.SOBillingInvoicingId,
				sobi.InvoiceDate,
				sobi.InvoiceNo AS InvoiceNo,
				'' AS SOShippingNum, 
				sop.Qty AS QtyToBill, 
				so.SalesOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,  
				sl.SerialNumber, cr.[Name] AS CustomerName,   
				sop.StockLineId,  
				(SELECT b.NoofPieces FROM SalesOrderBillingInvoicing a WITH (NOLOCK) 
					INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
					WHERE b.SOBillingInvoicingItemId = SOBII.SOBillingInvoicingItemId AND ISNULL(b.IsProforma,0) = 1 AND ISNULL(a.IsProforma,0) = 1) AS QtyBilled,  
				sop.ItemNo,  
				sop.SalesOrderId, sop.SalesOrderPartId, cond.Description AS 'Condition',   
				curr.Code as 'CurrencyCode',  
				sobi.GrandTotal as 'TotalSales',  
				(SELECT a.InvoiceStatus FROM DBO.SalesOrderBillingInvoicing a WITH (NOLOCK) 
					INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
					Where a.SalesOrderId = @SalesOrderId 
					AND b.SOBillingInvoicingItemId = sobii.SOBillingInvoicingItemId
					AND ISNULL(b.IsProforma,0) = 1 AND ISNULL(a.IsProforma,0) = 1) AS InvoiceStatus,
				0 AS 'SmentNo',
				sobii.VersionNo, 
				(CASE WHEN sobii.IsVersionIncrease = 1 THEN 0 ELSE 1 END) IsVersionIncrease,
				CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice
				FROM DBO.SalesOrderPart sop WITH (NOLOCK)
				LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobii.SalesOrderPartId = sop.SalesOrderPartId AND ISNULL(sobii.IsProforma,0) = 1
				LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) ON sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId  AND ISNULL(sobi.IsProforma,0) = 1
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId  
				LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
				LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = sop.StockLineId  
				LEFT JOIN DBO.Customer cr WITH (NOLOCK) ON cr.CustomerId = so.CustomerId  
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON cond.ConditionId = sop.ConditionId  
				LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON curr.CurrencyId = so.CurrencyId  
				WHERE sop.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId  
				 
				ORDER BY sobi.SOBillingInvoicingId DESC;
   END  
   COMMIT  TRANSACTION  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'sp_GetSalesOrderPerformaInvoiceChildList'   
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