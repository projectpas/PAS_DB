/*************************************************************             
 ** File:   [USP_GetCommonBillingDepositeDataById]             
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Deposite Amt for Billing Deposite
 ** Purpose:           
 ** Date:   26/05/2025
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------				-------------------------------            
    1    26/05/2025   Moin Bloch		Created
    2    27/05/2025   Rajesh Gami		Added ModuleId and Check with NULL value
 EXEC  [dbo].[USP_GetCommonBillingDepositeDataById] 8810,15
**************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_GetCommonBillingDepositeDataById]      
@ReferenceId BIGINT = NULL, 
@ModuleId INT
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      

	SELECT  wobi.[ReferenceId],
			wobi.[MasterCompanyId],
			SUM(ISNULL(wobi.[GrandTotal], 0)) AS GrandTotal,
			SUM(ISNULL(wobi.[RemainingAmount], 0)) AS RemainingAmount,
			SUM(ISNULL(wobi.[DepositAmount], 0)) AS DepositAmount,
			SUM(ISNULL(wobi.[UsedDeposit], 0)) AS UsedDeposit
		FROM [DBO].[BillingInvoicing] wobi WITH(NOLOCK)
		WHERE wobi.[ReferenceId] = @ReferenceId AND wobi.ModuleId = @ModuleId
			  AND ISNULL(wobi.[IsPerformaInvoice],0) = 1 AND ISNULL(wobi.[IsVersionIncrease],0) = 0 AND UPPER([InvoiceStatus]) = 'INVOICED'
		GROUP BY wobi.ReferenceId,wobi.MasterCompanyId
    
 END TRY          
 BEGIN CATCH      
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = '[USP_GetCommonBillingDepositeData_ById]'       
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@ReferenceId AS VARCHAR(100)), '') + ''      
        , @ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
        exec spLogException       
                @DatabaseName           = @DatabaseName      
                , @AdhocComments          = @AdhocComments                  , @ProcedureParameters = @ProcedureParameters      
                , @ApplicationName        =  @ApplicationName      
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;      
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)      
        RETURN(1);      
 END CATCH      
END