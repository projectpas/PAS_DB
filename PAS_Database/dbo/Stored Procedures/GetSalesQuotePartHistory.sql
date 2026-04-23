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
 ** PR   Date         Author             Change Description                
 ** --   --------     -------           --------------------------------              
    1    13/11/2024    SHREY CHANDEGARA   Created    
    2    22/04/2025    Bhargav Saliya     UOM Changes    
         
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
		SET @CustomerApprovalEnum = (SELECT ApprovalStatusId FROM dbo.[ApprovalStatus] WITH(NOLOCK) WHERE Name='Approved')
		SELECT DISTINCT
			part.AuditSalesOrderQuotePartId as auditSalesOrderQuotePartId,
			part.SalesOrderQuotePartId as salesOrderQuotePartId,
			part.SalesOrderQuoteId as salesOrderQuoteId,
			part.ItemMasterId as itemMasterId,
			soqs.StockLineId as stockLineId,
			qs.StockLineNumber AS stockLineNumber,
			part.FxRate as fxRate,
			[dbo].[fn_ConvertUOM](ISNULL(part.QtyQuoted, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) as qtyQuoted,
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN [dbo].[fn_ConvertUOM](ISNULL(soqsc.UnitSalesPrice, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) ELSE [dbo].[fn_ConvertUOM](ISNULL(soqc.UnitSalesPrice, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) END AS 'unitSalePrice',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.MarkUpPercentage ELSE soqc.MarkUpPercentage END AS 'markUpPercentage',
			'' AS salesBeforeDiscount,
			'' AS 'discount',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.DiscountAmount ELSE soqc.DiscountAmount END AS 'discountAmount',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN [dbo].[fn_ConvertUOM](ISNULL(soqsc.NetSaleAmount, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) ELSE [dbo].[fn_ConvertUOM](ISNULL(soqc.NetSaleAmount, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) END AS 'netSales',
			part.MasterCompanyId as masterCompanyId,
			part.CreatedBy as createdBy,
			part.CreatedDate as createdDate,
			part.UpdatedBy as updatedBy,
			part.UpdatedDate as updatedDate,
			part.partnumber AS 'partNumber',
			part.PartDescription AS 'partDescription',
			qs.OEM AS 'isOEM',
			im.IsPma AS 'isPMA',
			im.IsDER AS 'isDER',
			'' AS 'methodType',
			'' AS 'method',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN qs.SerialNumber ELSE '' END 'serialNumber',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN qs.ControlNumber ELSE '' END 'controlNumber',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN [dbo].[fn_ConvertUOM](ISNULL(soqsc.UnitCost, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) ELSE [dbo].[fn_ConvertUOM](ISNULL(soqc.UnitCost, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) END AS 'unitCost',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN [dbo].[fn_ConvertUOM](ISNULL(soqsc.UnitSalesPriceExtended, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) ELSE [dbo].[fn_ConvertUOM](ISNULL(soqc.UnitSalesPriceExtended, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) END AS 'salesPriceExtended',
			'' AS markupExtended,
			'' AS salesDiscountExtended,
			'' AS netSalePriceExtended,
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN [dbo].[fn_ConvertUOM](ISNULL(soqsc.UnitCostExtended, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) ELSE [dbo].[fn_ConvertUOM](ISNULL(soqc.UnitCostExtended, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) END AS 'unitCostExtended',
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN [dbo].[fn_ConvertUOM](ISNULL(soqsc.MarginAmount, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) ELSE [dbo].[fn_ConvertUOM](ISNULL(soqc.MarginAmount, 0), im.StockUnitOfMeasure, im.ConsumeUnitOfMeasure, 0, part.MasterCompanyId) END AS 'marginAmount',
			'' AS marginAmountExtended,
			CASE WHEN ISNULL(soqs.StockLineId,0) > 0 THEN soqsc.MarginPercentage ELSE soqc.MarginPercentage END AS 'marginPercentage',
			part.CurrencyName AS currencyDescription,
			part.ConditionId AS conditionId,
			part.ConditionName AS conditionDescription,
			ISNULL(qs.IdNumber, '') AS idNumber,
			CASE WHEN sqap.CustomerStatusId = @CustomerApprovalEnum THEN 1 ELSE 0 END AS isApproved,
			ISNULL(um.ShortName, '') AS uomName,
			ISNULL(po.PurchaseOrderNumber, '') AS poNumber,
			ISNULL(ro.RepairOrderNumber, '') AS roNumber,
			part.CustomerRequestDate AS customerRequestDate,
			part.PromisedDate AS promisedDate,
			part.EstimatedShipDate as estimatedShipDate,
			part.PriorityId AS priorityId,
			part.PriorityName AS priorityName,
			part.StatusId AS statusId,
			part.StatusName as statusName,
			soq.CustomerReference AS 'customerReference'
		FROM [dbo].[SalesOrderQuotePartV1Audit] part WITH(NOLOCK)
			LEFT JOIN [dbo].[SalesOrderQuoteAudit] soq WITH(NOLOCK) ON part.SalesOrderQuoteId = soq.SalesOrderQuoteId
			LEFT JOIN [dbo].[SalesOrderQuoteStocklineV1Audit] soqs WITH(NOLOCK) ON soqs.SalesOrderQuotePartId = part.SalesOrderQuotePartId
			LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON soqs.StockLineId = qs.StockLineId
			LEFT JOIN [dbo].[SalesOrderQuotePartCostAudit] soqc WITH(NOLOCK) ON soqc.SalesOrderQuotePartId = part.SalesOrderQuotePartId
			LEFT JOIN [dbo].[SalesOrderQuoteStockLineCostAudit] soqsc WITH(NOLOCK) ON soqsc.SalesOrderQuoteStocklineId = soqs.SalesOrderQuoteStocklineId
			LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON part.ItemMasterId = im.ItemMasterId
			LEFT JOIN [dbo].[SalesOrderQuoteApproval] sqap WITH(NOLOCK) ON part.SalesOrderQuotePartId = sqap.SalesOrderQuotePartId
			LEFT JOIN [dbo].[UnitOfMeasure] um WITH(NOLOCK) ON im.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
			LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
			LEFT JOIN [dbo].[RepairOrder] ro WITH(NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId	
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