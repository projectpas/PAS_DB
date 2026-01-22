/*************************************************************             
 ** File:   [CalculateInvoiceItemDetails]          
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used CalculateInvoiceItemDetails
 ** Purpose:           
 ** Date:  10/12/2024        
            
 ** PARAMETERS: @sobillingInvoicingItemId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    10/12/2024		EKTA CHANDEGRA	 Created  
	2    07-07-2025     Moin Bloch       Changed Old To New Billing Table

 EXEC CalculateInvoiceItemDetails 11 
************************************************************************/ 
CREATE   PROCEDURE [dbo].[CalculateInvoiceItemDetails]
@sobillingInvoicingItemId BIGINT
AS
BEGIN
	SET NOCOUNT ON;  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED   
	BEGIN TRY 
	    DECLARE @SOModuleId INT
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

		SELECT TOP 1
		sobi.QtyBilled NoofPieces,
		-- UnitPrice logic
		ISNULL(sosc.NetSaleAmount, 0) AS UnitPrice
		FROM 
			[dbo].[SalesOrder] so WITH(NOLOCK)
			INNER JOIN [dbo].[SalesOrderPartV1] sop WITH(NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			LEFT JOIN [dbo].[SalesOrderPartCost] sopc WITH(NOLOCK) ON sop.SalesOrderPartId = sopc.SalesOrderPartId
			LEFT JOIN [dbo].[BillingInvoicingItems] sobi WITH(NOLOCK) ON sop.SalesOrderPartId = sobi.SubReferenceId AND sobi.[ModuleId] = @SOModuleId
			LEFT JOIN [dbo].[SalesOrderStockLineV1] sos WITH(NOLOCK) ON sop.SalesOrderPartId = sos.SalesOrderPartId AND (sos.StockLineId = sobi.StocklineId OR sobi.StocklineId = 0)
			LEFT JOIN [dbo].[SalesOrderStocklineCost] sosc WITH(NOLOCK) ON sos.SalesOrderStocklineId = sosc.SalesOrderStocklineId
		WHERE 
			sobi.BillingInvoicingItemId = @sobillingInvoicingItemId;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
				, @AdhocComments     VARCHAR(150)    = 'CalculateInvoiceItemDetails'     
				, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@sobillingInvoicingItemId, '') + ''
				, @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
            RETURN(1); 
	END CATCH
END