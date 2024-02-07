/*************************************************************             
 ** File:   [RPT_GetWorkOrderQuotePrintPdfData]             
 ** Author:   AMIT GHEDIYA  
 ** Description: This stored procedure is used to get work order quote pdf details  
 ** Purpose:           
 ** Date:   01/05/2024          
            
 ** PARAMETERS:   
 ** RETURN VALUE:             
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    01/05/2024   AMIT GHEDIYA		Created  
	2    01/05/2024   HEMANT SALIYA		Updated For Handle Flat Rate values 
	3    02/07/2024   VISHAL SUTHAR		Updated to handle Flat Rate and calculate tax in SP level itself

--EXEC [RPT_GetWorkOrderQuotePrintPdfData] 2176,3752  
**************************************************************/  
CREATE PROCEDURE [dbo].[RPT_GetWorkOrderQuotePrintPdfData]  
 @WorkOrderQuoteId bigint,  
 @workOrderPartNoId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
		;WITH WOQPartCte AS (
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
		 Scope = UPPER(s.Description),
		 UPPER(sl.StockLineNumber) AS StockLineNumber,
		 UPPER(sl.SerialNumber) AS SerialNumber,
		 SUM(wqd.MaterialRevenue) AS 'MaterialRevenue',  
		 SUM(wqd.LaborRevenue) AS 'LaborRevenue',  
		 SUM(wqd.ChargesRevenue) AS 'ChargesRevenue',  
		 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate ELSE SUM(wqd.MaterialFlatBillingAmount) END AS 'MaterialFlatBillingAmount' ,  
		 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.LaborFlatBillingAmount) END AS 'LaborFlatBillingAmount',  
		 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.ChargesFlatBillingAmount) END AS 'ChargesFlatBillingAmount',  
		 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.FreightFlatBillingAmount) END AS 'FreightFlatBillingAmount',  
		 wop.Quantity,  
		 ISNULL(wqd.QuoteMethod,0) AS QuoteMethod,  
		 wqd.CommonFlatRate,  
		 wop.TATDaysStandard ,
		 ISNULL(wqd.EvalFees,0) AS EvalFees,
		 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate 
		 ELSE SUM(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0) + ISNULL(wqd.FreightFlatBillingAmount,0))
		 END AS subtotalfortax,
		 TAXRates = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
					LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
					LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId and t.Code ='SALES TAX'
				WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
		Othertax = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
					LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
					LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId 
				WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 )
	FROM dbo.WorkOrder wo WITH(NOLOCK)
		 INNER JOIN dbo.WorkOrderQuote woq WITH(NOLOCK) ON wo.WorkOrderId = woq.WorkOrderId  
		 INNER JOIN dbo.WorkOrderQuoteDetails wqd WITH(NOLOCK) ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId  
		 INNER JOIN dbo.WorkOrderPartNumber wop WITH(NOLOCK) ON wqd.WOPartNoId = wop.ID  
		 INNER JOIN dbo.ItemMaster im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId  
		 LEFT JOIN dbo.ItemMaster im1 WITH(NOLOCK) ON im.RevisedPartId = im1.ItemMasterId  
		 INNER JOIN dbo.WorkScope s WITH(NOLOCK) ON wop.WorkOrderScopeId = s.WorkScopeId  
		 INNER JOIN dbo.StockLine sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId  
		 INNER JOIN dbo.Customer cust WITH(NOLOCK)  ON woq.CustomerId = cust.CustomerId
	WHERE woq.WorkOrderQuoteId = @WorkOrderQuoteId AND wop.ID = @workOrderPartNoId  
		 AND woq.IsActive = 1 AND woq.IsDeleted = 0  
	GROUP BY im.PartNumber,  
		 im.PartDescription, im1.ItemMasterId, im1.PartNumber, s.Description,  
		 sl.StockLineNumber, sl.SerialNumber, wop.Quantity, wqd.QuoteMethod, wqd.CommonFlatRate, TATDaysStandard,wqd.EvalFees, cust.CustomerId),
	AfterTax AS (SELECT *, CAST(((Ct.subtotalfortax * Ct.TAXRates) / 100) AS DECIMAL(18, 2)) AS SalesTaxAmount, CAST(((Ct.subtotalfortax * Ct.Othertax) / 100) AS DECIMAL(18, 2)) AS OtherTaxAmount FROM WOQPartCte Ct)
	
	SELECT *, (ISNULL(FinalQuote.SalesTaxAmount, 0) + ISNULL(FinalQuote.OtherTaxAmount, 0) + ISNULL(FinalQuote.subtotalfortax, 0)) FinalTotal FROM AfterTax FinalQuote;

   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetWorkOrderQuotePrintPdfData'   
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