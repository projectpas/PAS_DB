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
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
	 1   01/29/2024		AMIT GHEDIYA		Created
	 2   10/16/2024		Abhishek Jirawla	Implemented the new tables for SalesOrder related tables
     3   07-07-2025     Moin Bloch          Changed Old To New Billing Table
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
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
        DECLARE @SOModuleId INT
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

		SELECT DISTINCT 0 AS SalesOrderShippingId,   
				sobi.BillingInvoicingId SOBillingInvoicingId,
				sobi.InvoiceDate,
				sobi.InvoiceNo AS InvoiceNo,
				'' AS SOShippingNum, 
				sop.QtyOrder AS QtyToBill, 
				so.SalesOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,  
				sl.SerialNumber, cr.[Name] AS CustomerName,   
				sov.StockLineId,  
				(SELECT b.QtyBilled FROM dbo.BillingInvoicing a WITH (NOLOCK) 
					INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId  AND a.[ModuleId] = @SOModuleId
					WHERE b.BillingInvoicingItemId = SOBII.BillingInvoicingItemId AND ISNULL(b.IsPerformaInvoice,0) = 1 AND ISNULL(a.IsPerformaInvoice,0) = 1) AS QtyBilled,  
				0 AS ItemNo,  
				sop.SalesOrderId, sop.SalesOrderPartId, cond.Description AS 'Condition',   
				curr.Code as 'CurrencyCode',  
				sobi.GrandTotal as 'TotalSales',  
				(SELECT a.InvoiceStatus FROM DBO.BillingInvoicing a WITH (NOLOCK) 
					INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId  AND a.[ModuleId] = @SOModuleId
					Where a.ReferenceId = @SalesOrderId  AND a.[ModuleId] = @SOModuleId
					AND b.BillingInvoicingItemId = sobii.BillingInvoicingItemId
					AND ISNULL(b.IsPerformaInvoice,0) = 1 AND ISNULL(a.IsPerformaInvoice,0) = 1) AS InvoiceStatus,
				0 AS 'SmentNo',
				sobii.VersionNo, 
				(CASE WHEN sobii.IsVersionIncrease = 1 THEN 0 ELSE 1 END) IsVersionIncrease,
				CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice
				FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
				LEFT JOIN DBO.SalesOrderStockLineV1 sov WITH (NOLOCK) ON sov.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) ON sobii.SubReferenceId = sop.SalesOrderPartId AND ISNULL(sobii.IsPerformaInvoice,0) = 1 AND sobii.[ModuleId] = @SOModuleId
				LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) ON sobi.BillingInvoicingId = sobii.BillingInvoicingId  AND ISNULL(sobi.IsPerformaInvoice,0) = 1 AND sobi.[ModuleId] = @SOModuleId
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId  
				LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
				 AND ISNULL(imt.IsNonStock,0) = 0 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = sov.StockLineId  
				LEFT JOIN DBO.Customer cr WITH (NOLOCK) ON cr.CustomerId = so.CustomerId  
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON cond.ConditionId = sop.ConditionId  
				LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON curr.CurrencyId = so.CurrencyId  
				WHERE sop.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId  
				 
				ORDER BY sobi.BillingInvoicingId DESC;
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