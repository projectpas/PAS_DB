/*************************************************************           
 ** File:  [GetSalesOrderPartStocklineDetailsBySOId]           
 ** Author:	  Rajesh Gami
 ** Description: This SP is Used to Get SalesOrder Part Stockline Details
 ** Purpose:         
 ** Date:   29/May/2024          
 ** PARAMETERS: 
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------     
	1    29/May/2025   Rajesh Gami		Created
	2    09/July/2026   RAJESH GAMI		[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	3    22/July/2026   RAJESH GAMI		[PN-17350] - Removed leftover IsNonStock=0 exclusion filter from the PN-17008/17009 transitional phase so Non-Stock parts print/display correctly now that Non-Stock is fully merged
	[dbo].[GetSalesOrderPartStocklineDetailsBySOId] 846
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetSalesOrderPartStocklineDetailsBySOId]
    @SalesOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    SELECT 
        sops.StockLineId,
        sops.SalesOrderPartId,
        qs.StockLineNumber,
        qs.ControlNumber,
        qs.IdNumber,
        qs.SerialNumber
    FROM dbo.SalesOrderPartV1 part WITH(NOLOCK)
    LEFT JOIN dbo.SalesOrderStockLineV1 sops WITH(NOLOCK) ON part.SalesOrderPartId = sops.SalesOrderPartId
    LEFT JOIN dbo.StockLine qs WITH(NOLOCK) ON sops.StockLineId = qs.StockLineId
    WHERE part.SalesOrderId = @SalesOrderId
	END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderPartStocklineDetailsBySOId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END