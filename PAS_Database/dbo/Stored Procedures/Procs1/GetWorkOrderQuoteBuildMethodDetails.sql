  
/*************************************************************             
 ** File:   [GetWorkOrderQuoteBuildMethodDetails]             
 ** Author:   Hemant Saliya  
 ** Description: This stored procedure is used Get WorkOrder Quote Build Method Details    
 ** Purpose:           
 ** Date:   05/25/2021          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    05/25/2021   Hemant Saliya Created  
       
-- EXEC [GetWorkOrderQuoteBuildMethodDetails] 186  
**************************************************************/  
  
CREATE   PROCEDURE [dbo].[GetWorkOrderQuoteBuildMethodDetails]  
 @workflowWorkorderId BIGINT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
    SELECT   
		WQD.ItemMasterId,  
		IM.PartNumber,  
		CASE WHEN BuildMethodId = 1 THEN 'WF' WHEN BuildMethodId = 2 THEN 'WO' WHEN BuildMethodId = 3 THEN 'WF' ELSE 'Third Party' END AS BuildMethod,  
		BuildMethodId,  
		WorkOrderQuoteDetailsId,  
		LaborFlatBillingAmount,  
		MaterialFlatBillingAmount,  
		ChargesFlatBillingAmount,  
		FreightFlatBillingAmount,  
		MaterialBuildMethod,  
		LaborBuildMethod,  
		ChargesBuildMethod,  
		FreightBuildMethod,  
		MaterialMarkupId,  
		LaborMarkupId,  
		ChargesMarkupId,  
		FreightMarkupId,  
		ExclusionsMarkupId,  
        CommonFlatRate,  
        QuoteMethod,
		EvalFees
    FROM DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK)  
     LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WQD.ItemMasterId  
    WHERE WorkflowWorkOrderId = @workflowWorkorderId AND IsVersionIncrease = 0  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderQuoteBuildMethodDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workflowWorkorderId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END