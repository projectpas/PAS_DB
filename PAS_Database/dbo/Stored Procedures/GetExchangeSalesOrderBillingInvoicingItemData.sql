/*************************************************************           
 ** File:   [GetExchangeSalesOrderBillingInvoicingItemData]          
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to GetExchangeSalesOrderBillingInvoicingItemData
 ** Purpose:         
 ** Date:    06/13/2025  

 ** PARAMETERS: @ExchangeSalesOrderPartId BIGINT, @QtyShipped [decimal](18,6)
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1    06/13/2025  EKTA CHANDEGRA    Created
	2	 31-Mar-2026	Rajesh Gami		UOM Conversion Changes [PN-15866]	     
 EXEC GetExchangeSalesOrderBillingInvoicingItemData @ExchangeSalesOrderPartId = 153 , @QtyShipped = 1
************************************************************************/ 
CREATE   PROCEDURE [dbo].[GetExchangeSalesOrderBillingInvoicingItemData]
    @ExchangeSalesOrderPartId BIGINT,
    @QtyShipped [decimal](18,6)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT TOP 1
			sop.ItemMasterId,
			UPPER(ISNULL(sl.SerialNumber, '')) AS SerialNumber,
			im.PartNumber AS PNumber,
			im.PartDescription AS PNDescription,
			ISNULL(uom.ShortName, '') AS UOM,
			ISNULL(cond.Description, '') AS Cond,
			@QtyShipped AS QtyShipped,
			ISNULL(sop.QtyQuoted, 0) - @QtyShipped AS QTYOnBACKOrder,
			ISNULL(sop.ExchangeListPrice, 0) AS UnitPrice,
			ROUND(@QtyShipped * ISNULL(sop.ExchangeListPrice, 0), 2) AS Amount
		FROM [dbo].[ExchangeSalesOrder] so WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeSalesOrderPart] sop WITH(NOLOCK) ON so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
		INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON sop.ItemMasterId = im.ItemMasterId
		LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON im.ConsumeUnitOfMeasureId = uom.UnitOfMeasureId
		LEFT JOIN [dbo].[Condition] cond WITH(NOLOCK) ON sop.ConditionId = cond.ConditionId
		LEFT JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON sop.StockLineId = sl.StockLineId
		WHERE sop.ExchangeSalesOrderPartId = @ExchangeSalesOrderPartId
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeSalesOrderBillingInvoicingItemData'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderPartId = ''' + CAST(ISNULL(@ExchangeSalesOrderPartId, '') AS VARCHAR(100)) + ''' ,
													@QtyShipped = ''' + CAST(ISNULL(@QtyShipped, '') AS VARCHAR(100)) 
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);  
	END CATCH
END