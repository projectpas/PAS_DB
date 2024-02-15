/*************************************************************             
 ** File:   [USP_GetWOBillingDepositeData_ByWOId]             
 ** Author:   Devendra Shekh 
 ** Description: This stored procedure is used to get Deposite Amt for Billing Deposite
 ** Purpose:           
 ** Date:   14/02/2024 (DD/MM/YYYY)     
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------				-------------------------------            
    1    14/02/2024   Devendra Shekh		Created

EXEC  [dbo].[USP_GetWOBillingDepositeData_ByWOId] 4349
**************************************************************/ 

CREATE   PROCEDURE [dbo].[USP_GetWOBillingDepositeData_ByWOId]      
@WorkOrderId BIGINT = NULL
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      

	SELECT  wobi.WorkOrderId,
			wobi.MasterCompanyId,
			SUM(ISNULL(wobi.GrandTotal, 0)) AS GrandTotal,
			SUM(ISNULL(wobi.RemainingAmount, 0)) AS RemainingAmount,
			SUM(ISNULL(wobi.DepositAmount, 0)) AS DepositAmount,
			SUM(ISNULL(wobi.UsedDeposit, 0)) AS UsedDeposit
		FROM [DBO].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK)
		WHERE wobi.WorkOrderId = @WorkOrderId
			  AND wobi.IsPerformaInvoice = 1 AND wobi.IsVersionIncrease = 0 AND UPPER(InvoiceStatus) = 'INVOICED'
		GROUP BY wobi.WorkOrderId,wobi.MasterCompanyId
    
 END TRY          
 BEGIN CATCH      
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'USP_GetWOBillingDepositeData_ByWOId'       
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@WorkOrderId AS VARCHAR(10)), '') + ''      
        , @ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
        exec spLogException       
                @DatabaseName           = @DatabaseName      
                , @AdhocComments          = @AdhocComments                  , @ProcedureParameters = @ProcedureParameters      
                , @ApplicationName        =  @ApplicationName      
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;      
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)      
        RETURN(1);      
 END CATCH      
END