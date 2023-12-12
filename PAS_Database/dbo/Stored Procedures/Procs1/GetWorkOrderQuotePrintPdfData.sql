  
/*************************************************************             
 ** File:   [GetWorkOrderQuotePrintPdfData]             
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to get work order quote pdf details  
 ** Purpose:           
 ** Date:   11/08/2021          
            
 ** PARAMETERS:   
 ** RETURN VALUE:             
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    11/08/2021   Vishal Suthar Created  
--EXEC [GetWorkOrderPrintPdfData] 274,258  
**************************************************************/  
CREATE   PROCEDURE [dbo].[GetWorkOrderQuotePrintPdfData]  
 @WorkOrderQuoteId bigint,  
 @workOrderPartNoId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
    SELECT DISTINCT   
     im.PartNumber,  
     im.PartDescription,  
     RevisedPartNo = CASE WHEN im1.ItemMasterId IS null THEN  '' ELSE im1.PartNumber END,  
     Revenue = SUM(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0)),  
     SUM(wqd.MaterialCost) AS 'MaterialCost',  
     SUM(wqd.MaterialRevenuePercentage) AS 'MaterialRevenuePercentage',  
     SUM(wqd.LaborCost) AS 'LaborCost',  
     SUM(wqd.LaborRevenuePercentage) AS 'LaborRevenuePercentage',  
     SUM(wqd.OverHeadCost) AS 'OverHeadCost',  
     SUM(wqd.OverHeadCostRevenuePercentage) AS 'OverHeadCostRevenuePercentage',  
     SUM(wqd.FreightRevenue) AS 'FreightRevenue',  
     OtherCost = SUM(wqd.ChargesCost),  
     DirectCost = SUM(wqd.MaterialCost + wqd.LaborCost + wqd.ChargesCost),  
     Margin = SUM(wqd.MaterialMargin + wqd.LaborMargin + wqd.ChargesMargin),  
     MarginPercentage = SUM(wqd.MaterialMarginPer + wqd.LaborMarginPer + wqd.ChargesMarginPer),  
     Scope = s.Description,  
     sl.StockLineNumber,  
     sl.SerialNumber,  
     SUM(wqd.MaterialRevenue) AS 'MaterialRevenue',  
     SUM(wqd.LaborRevenue) AS 'LaborRevenue',  
     SUM(wqd.ChargesRevenue) AS 'ChargesRevenue',  
     SUM(wqd.MaterialFlatBillingAmount) AS 'MaterialFlatBillingAmount',  
     SUM(wqd.LaborFlatBillingAmount) AS 'LaborFlatBillingAmount',  
     SUM(wqd.ChargesFlatBillingAmount) AS 'ChargesFlatBillingAmount',  
     SUM(wqd.FreightFlatBillingAmount) AS 'FreightFlatBillingAmount',  
     wop.Quantity,  
     ISNULL(wqd.QuoteMethod,0) AS QuoteMethod,  
     wqd.CommonFlatRate,  
     wop.TATDaysStandard ,
	 ISNULL(wqd.EvalFees,0) AS EvalFees
     FROM WorkOrder wo   
     INNER JOIN WorkOrderQuote woq ON wo.WorkOrderId = woq.WorkOrderId  
     INNER JOIN WorkOrderQuoteDetails wqd ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId  
     INNER JOIN WorkOrderPartNumber wop on wqd.WOPartNoId = wop.ID  
     INNER JOIN ItemMaster im on wop.ItemMasterId = im.ItemMasterId  
     LEFT JOIN ItemMaster im1 on im.RevisedPartId = im1.ItemMasterId  
     INNER JOIN WorkScope s on wop.WorkOrderScopeId = s.WorkScopeId  
     INNER JOIN StockLine sl on wop.StockLineId = sl.StockLineId  
     Where woq.WorkOrderQuoteId = @WorkOrderQuoteId AND wop.ID = @workOrderPartNoId  
     AND woq.IsActive = 1 AND woq.IsDeleted = 0  
     GROUP BY im.PartNumber,  
     im.PartDescription, im1.ItemMasterId, im1.PartNumber, s.Description,  
     sl.StockLineNumber, sl.SerialNumber, wop.Quantity, wqd.QuoteMethod, wqd.CommonFlatRate, TATDaysStandard,wqd.EvalFees  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderQuotePrintPdfData'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        = @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END