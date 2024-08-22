/*************************************************************               
 ** File:   [USP_GetPOApprovalList]               
 ** Author:   SHREY CHANDEGARA    
 ** Description:         
 ** Purpose:             
 ** Date:   21/08/2024            
              
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author   Change Description                
 ** --   --------     -------   --------------------------------              
    1    21/08/2024    SHREY CHANDEGARA  Created    
         
 EXECUTE USP_GetPOApprovalList 1863  
**************************************************************/     
CREATE   PROCEDURE [dbo].[USP_GetPOApprovalList]  
 @PurchaseOrderId BIGINT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY
		SELECT 
			ISNULL(poa.PurchaseOrderApprovalId, 0) AS PurchaseOrderApprovalId,
			ISNULL(poa.ApprovedById, 0) AS ApprovedById,
			poa.UpdatedDate,
			poa.PurchaseOrderId
		FROM 
			DBO.[PurchaseOrderApproval] poa WITH(NOLOCK)
		LEFT JOIN 
			DBO.[PurchaseOrderPart] pop WITH(NOLOCK) ON poa.PurchaseOrderPartId = pop.PurchaseOrderPartRecordId
		WHERE 
			poa.PurchaseOrderId = @PurchaseOrderId; 
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetPOApprovalList'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''  
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