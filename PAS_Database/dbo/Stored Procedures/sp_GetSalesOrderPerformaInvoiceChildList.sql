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
				(SELECT ISNULL(SUM(SORR.QtyToReserve), 0) FROM DBO.SalesOrderReserveParts SORR WITH (NOLOCK) WHERE SORR.SalesOrderPartId = sop.SalesOrderPartId AND SORR.StockLineId = sop.StockLineId) AS QtyToBill,   
				so.SalesOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,  
				sl.SerialNumber, cr.[Name] AS CustomerName,   
				sop.StockLineId,  
				(SELECT b.NoofPieces FROM SalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId WHERE b.SOBillingInvoicingItemId = SOBII.SOBillingInvoicingItemId) AS QtyBilled,  
				sop.ItemNo,  
				sop.SalesOrderId, sop.SalesOrderPartId, cond.Description AS 'Condition',   
				curr.Code as 'CurrencyCode',  
				CASE WHEN ISNULL(sobi.SOBillingInvoicingId, 0) = 0 THEN ((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +   
				((((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM DBO.SalesOrderFreight sof WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM DBO.SalesOrderCharges socg WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0)
				) * ISNULL(sop.TaxPercentage, 0)) / 100) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM DBO.SalesOrderFreight sof WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM DBO.SalesOrderCharges socg WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0))
				ELSE sobi.GrandTotal END as 'TotalSales',  
				(SELECT a.InvoiceStatus FROM DBO.SalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId Where a.SalesOrderId = @SalesOrderId AND b.SOBillingInvoicingItemId = sobii.SOBillingInvoicingItemId) AS InvoiceStatus,
				0 AS 'SmentNo',
				sobii.VersionNo, 
				(CASE WHEN sobii.IsVersionIncrease = 1 THEN 0 ELSE 1 END) IsVersionIncrease,
				CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice
				FROM DBO.SalesOrderPart sop WITH (NOLOCK)
				LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobii.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) ON sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId  
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId  
				LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
				LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = sop.StockLineId  
				LEFT JOIN DBO.Customer cr WITH (NOLOCK) ON cr.CustomerId = so.CustomerId  
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON cond.ConditionId = sop.ConditionId  
				LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON curr.CurrencyId = so.CurrencyId  
				LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) ON SOR.SalesOrderPartId = sop.SalesOrderPartId
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