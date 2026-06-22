/*************************************************************               
 ** File:   [GetSalesOrderQuotePartStockLineDetails]              
 ** Author:  EKTA CHANDEGRA  
 ** Description: This stored procedure is used GetSalesOrderQuotePartStockLineDetails  
 ** Purpose:             
 ** Date:  09/12/2024          
              
 ** PARAMETERS: @SalesOrderQuoteId bigint  
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date    Author   Change Description                
 ** --   --------  -------   --------------------------------              
    1    09/12/2024  EKTA CHANDEGRA  Created    
    2    22/06/2024  Kishor Makwana  Added ModuleName [PN-16937] 
 EXEC GetSalesOrderQuotePartStockLineDetails 965  
************************************************************************/     
  
CREATE   PROCEDURE [dbo].[GetSalesOrderQuotePartStockLineDetails]  
    @SalesOrderQuoteId BIGINT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
    SET NOCOUNT ON;  
 BEGIN TRY  
  SELECT  
   ISNULL(stk.StockLineId,0) AS StockLineId,  
   ISNULL(qs.StockLineNumber,'') AS StockLineNumber,  
   ISNULL(qs.ControlNumber,'') AS ControlNumber,  
   ISNULL(qs.IdNumber,'') AS IdNumber,  
   ISNULL(qs.SerialNumber,'') AS SerialNumber,  
   ISNULL(qs.TraceableToName, '-') AS Traceable,  
   CASE   
    WHEN qs.TagDate IS NOT NULL   
    THEN CONVERT(VARCHAR(10), qs.TagDate, 101) -- MM/dd/yyyy format  
    ELSE '-'  
   END AS TagDate,  
   ISNULL(qs.TaggedByName, '-') AS TaggedBy,
   ISNULL(md.ModuleName,'') AS ModuleName
  FROM [dbo].[SalesOrderQuotePartV1] part WITH(NOLOCK)  
  LEFT JOIN [dbo].[SalesOrderQuoteStocklineV1] stk WITH(NOLOCK) ON part.SalesOrderQuotePartId = stk.SalesOrderQuotePartId  
  LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON stk.StockLineId = qs.StockLineId
  LEFT JOIN [dbo].[Module] md WITH(NOLOCK) ON md.ModuleId= qs.CertifiedById
  WHERE part.SalesOrderQuoteId = @SalesOrderQuoteId;  
 END TRY  
 BEGIN CATCH  
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
    , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderQuotePartStockLineDetails'       
    , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderQuoteId, '') + ''  
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