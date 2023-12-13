/*************************************************************               
 ** File:   [GetStocklineIdsForReceivingPO]              
 ** Author:   Vishal Suthar    
 ** Description: This stored procedure is used to get stockline IDs created for the receiving PO  
 ** Purpose:             
 ** Date:   08/21/2023            
              
 ** PARAMETERS:    
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author   Change Description                
 ** --   --------     -------   --------------------------------              
    1    09/01/2023   Vishal Suthar  Created  
	2    06-12-2023   Shrey Chandegara Updated For Nonstock 
    
EXEC [GetStocklineIdsForReceivingPO] 2174  
**************************************************************/    
CREATE    PROCEDURE [dbo].[GetStocklineIdsForReceivingPO]  
(    
 @PurchaseOrderId BIGINT = NULL  
)    
AS    
BEGIN  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  SET NOCOUNT ON  
    
    BEGIN TRY  
    BEGIN  
    
  SELECT STUFF((SELECT ',' + CAST(Stk.StockLineId AS VARCHAR(100))  
        FROM DBO.Stockline Stk WITH (NOLOCK)  
        Where Stk.PurchaseOrderId = @PurchaseOrderId      
        AND Stk.IsActive = 1 AND Stk.IsDeleted = 0      
        FOR XML PATH('')), 1, 1, '') StocklineIds,   
   STUFF((SELECT ',' + CAST(Stk.AssetInventoryId AS VARCHAR(100))  
        FROM DBO.AssetInventory Stk WITH (NOLOCK)  
        Where Stk.PurchaseOrderId = @PurchaseOrderId      
        AND Stk.IsActive = 1 AND Stk.IsDeleted = 0      
        FOR XML PATH('')), 1, 1, '') AssetInventoryIds,
	STUFF((SELECT ',' + CAST(Stk.NonStockInventoryId AS VARCHAR(100))  
        FROM DBO.NonStockInventory Stk WITH (NOLOCK)  
        Where Stk.PurchaseOrderId = @PurchaseOrderId      
        AND Stk.IsActive = 1 AND Stk.IsDeleted = 0      
        FOR XML PATH('')), 1, 1, '') NonStockInventoryIds;
  
 END  
    
  END TRY  
  BEGIN CATCH  
    IF @@trancount > 0  
   DECLARE @ErrorLogID INT  
   ,@DatabaseName varchar(100) = DB_NAME()  
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------    
   ,@AdhocComments varchar(150) = 'GetStocklineIdsForReceivingPO'    
   ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@PurchaseOrderId, '') + ''    
   ,@ApplicationName varchar(100) = 'PAS'    
   -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
   EXEC spLogException @DatabaseName = @DatabaseName,    
    @AdhocComments = @AdhocComments,    
    @ProcedureParameters = @ProcedureParameters,    
    @ApplicationName = @ApplicationName,    
    @ErrorLogID = @ErrorLogID OUTPUT;    
   RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
   RETURN (1);    
  END CATCH    
END