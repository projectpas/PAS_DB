/*************************************************************               
 ** File:   [USP_CycleCount_GetCycleCountApprovalList]               
 ** Author:   Moin Bloch
 ** Description:         
 ** Purpose:             
 ** Date:   29/10/2024            
              
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author       Change Description                
 ** --   --------     -------      --------------------------------              
    1    29/10/2024   Moin Bloch   Created    
         
 EXEC USP_CycleCount_GetCycleCountApprovalList 1  
**************************************************************/     
create    PROCEDURE [dbo].[USP_CycleCount_GetCycleCountApprovalList]  
@CycleCountId BIGINT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY
		SELECT 
			ISNULL(cca.[CycleCountApprovalId], 0) AS CycleCountApprovalId,
			cca.[CycleCountId],
			ISNULL(cca.[ApprovedById], 0) AS ApprovedById,
			cca.[UpdatedDate]			
		FROM [dbo].[CycleCountApproval] cca WITH(NOLOCK)
		LEFT JOIN [dbo].[CycleCountDetail] pop WITH(NOLOCK) ON cca.[CycleCountDetailId] = pop.[CycleCountDetailId]
		WHERE cca.[CycleCountId] = @CycleCountId; 
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_CycleCount_GetCycleCountApprovalList'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CycleCountId, '') + ''  
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