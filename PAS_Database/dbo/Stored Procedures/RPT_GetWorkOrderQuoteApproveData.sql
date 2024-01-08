/*************************************************************             
 ** File:   [RPT_GetWorkOrderQuoteApproveData]             
 ** Author:   AMIT GHEDIYA  
 ** Description: This stored procedure is used to get work order quote pdf Approve details  
 ** Purpose:           
 ** Date:   01/05/2024          
            
 ** PARAMETERS:   
 ** RETURN VALUE:             
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		 Change Description              
 ** --   --------     -------		--------------------------------            
    1    01/05/2024   AMIT GHEDIYA    Created  

--EXEC [RPT_GetWorkOrderQuoteApproveData] 3018
**************************************************************/  
CREATE       PROCEDURE [dbo].[RPT_GetWorkOrderQuoteApproveData]  
 @workOrderPartNoId bigint 
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
		SELECT 
			woq.WorkOrderQuoteId,
            woq.CustomerStatusId,
            custapproval = ISNULL(ca.[Name],''),
            custrejected = ISNULL(css.[Name],''),
            QuoteStatusId = woq.ApprovalActionId
	    FROM dbo.WorkOrderApproval woq WITH(NOLOCK)
			LEFT JOIN dbo.CustomerContact ccon WITH(NOLOCK) ON woq.CustomerApprovedById = ccon.ContactId
			LEFT JOIN dbo.Customer ca WITH(NOLOCK) ON ccon.CustomerId = ca.CustomerId
			LEFT JOIN dbo.Customer css WITH(NOLOCK) ON ccon.CustomerId = css.CustomerId
		WHERE woq.IsDeleted = 0 AND woq.WorkOrderPartNoId = 3018

   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetWorkOrderQuoteApproveData'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workOrderPartNoId, '') + ''  
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