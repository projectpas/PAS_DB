/*************************************************************               
 ** File:   [GetSalesQuotePartHistory]               
 ** Author:   SHREY CHANDEGARA    
 ** Description:         
 ** Purpose:             
 ** Date:   13/11/2024            
              
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author   Change Description                
 ** --   --------     -------   --------------------------------              
    1    13/11/2024    SHREY CHANDEGARA  Created    
         
 EXECUTE GetSalesQuotePartHistory 958  
**************************************************************/     
CREATE   PROCEDURE [dbo].[GetSalesQuotePartHistory]  
 @SalesOrderQuotePartId BIGINT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY
		DECLARE @CustomerApprovalEnum INT;
		SET @CustomerApprovalEnum = (SELECT ApprovalStatusId FROM dbo.[ApprovalStatus] WHERE Name='Approved')
		SELECT DISTINCT
			part.AuditSalesOrderQuotePartId,
			part.SalesOrderQuotePartId,
			part.SalesOrderQuoteId,
			part.ItemMasterId,
			soqs.StockLineId,
			qs.StockLineNumber AS stockLineNumber,
			part.FxRate,
			part.QtyQuoted,
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.UnitSalesPrice ELSE soqc.UnitSalesPrice END AS 'UnitSalePrice',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.MarkUpPercentage ELSE soqc.MarkUpPercentage END AS 'MarkUpPercentage',
			'' AS SalesBeforeDiscount,
			'' AS 'Discount',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.DiscountAmount ELSE soqc.DiscountAmount END AS 'DiscountAmount',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.NetSaleAmount ELSE soqc.NetSaleAmount END AS 'NetSales',
			part.MasterCompanyId,
			part.CreatedBy,
			part.CreatedDate,
			part.UpdatedBy,
			part.UpdatedDate,
			part.partnumber AS 'partNumber',
			part.PartDescription AS 'partDescription',
			qs.OEM AS 'isOEM',
			im.IsPma AS 'isPMA',
			im.IsDER AS 'isDER',
			'' AS 'MethodType',
			'' AS 'Method',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN qs.SerialNumber ELSE '' END 'SerialNumber',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN qs.ControlNumber ELSE '' END 'ControlNumber',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.UnitCost ELSE soqc.UnitCost END AS 'UnitCost',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.UnitSalesPriceExtended ELSE soqc.UnitSalesPriceExtended END AS 'SalesPriceExtended',
			'' AS MarkupExtended,
			'' AS SalesDiscountExtended,
			'' AS NetSalePriceExtended,
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.UnitCostExtended ELSE soqc.UnitCostExtended END AS 'UnitCostExtended',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.MarginAmount ELSE soqc.MarginAmount END AS 'MarginAmount',
			'' AS MarginAmountExtended,
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.MarginPercentage ELSE soqc.MarginPercentage END AS 'MarginPercentage',
			part.CurrencyName AS CurrencyDescription,
			part.ConditionId AS ConditionId,
			part.ConditionName AS ConditionDescription,
			ISNULL(qs.IdNumber, '') AS IdNumber,
			CASE WHEN sqap.CustomerStatusId = @CustomerApprovalEnum THEN 1 ELSE 0 END AS IsApproved,
			ISNULL(um.ShortName, '') AS UomName,
			ISNULL(po.PurchaseOrderNumber, '') AS PoNumber,
			ISNULL(ro.RepairOrderNumber, '') AS RoNumber,
			part.CustomerRequestDate,
			part.PromisedDate,
			part.EstimatedShipDate,
			part.PriorityId,
			part.PriorityName,
			part.StatusId,
			part.StatusName,
			soq.CustomerReference AS 'CustomerReference'
		FROM [dbo].[SalesOrderQuotePartV1Audit] part WITH(NOLOCK)
			LEFT JOIN [dbo].[SalesOrderQuoteAudit] soq ON part.SalesOrderQuoteId = soq.SalesOrderQuoteId
			LEFT JOIN [dbo].[SalesOrderQuoteStocklineV1Audit] soqs ON soqs.SalesOrderQuotePartId = part.SalesOrderQuotePartId
			LEFT JOIN [dbo].[StockLine] qs ON soqs.StockLineId = qs.StockLineId
			LEFT JOIN [dbo].[SalesOrderQuotePartCostAudit] soqc ON soqc.SalesOrderQuotePartId = part.SalesOrderQuotePartId
			LEFT JOIN [dbo].[SalesOrderQuoteStockLineCostAudit] soqsc ON soqsc.SalesOrderQuoteStocklineId = soqs.SalesOrderQuoteStocklineId
			LEFT JOIN [dbo].[ItemMaster] im ON part.ItemMasterId = im.ItemMasterId
			LEFT JOIN [dbo].[SalesOrderQuoteApproval] sqap ON part.SalesOrderQuotePartId = sqap.SalesOrderQuotePartId
			LEFT JOIN [dbo].[UnitOfMeasure] um ON im.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
			LEFT JOIN [dbo].[PurchaseOrder] po ON qs.PurchaseOrderId = po.PurchaseOrderId
			LEFT JOIN [dbo].[RepairOrder] ro ON qs.RepairOrderId = ro.RepairOrderId	
		WHERE 
			part.SalesOrderQuotePartId = @SalesOrderQuotePartId AND part.PartNumber IS NOT NULL
		ORDER BY part.UpdatedDate DESC; 
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetSalesQuotePartHistory'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderQuotePartId, '') + ''  
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
            exec spLogException   
                    @DatabaseName   = @DatabaseName  
                    , @AdhocComments   = @AdhocComments  
                    , @ProcedureParameters  = @ProcedureParameters  
                    , @ApplicationName         = @ApplicationName  
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
            RETURN(1);  
 END CATCH  
END