/*************************************************************             
 ** File:   [USP_GetSOBillingDepositeData_BySOId]             
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used to get Deposite Amt for Billing Deposite
 ** Purpose:           
 ** Date:   15/02/2024  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------				-------------------------------            
    1    15/02/2024   AMIT GHEDIYA		    Created
	2    07-07-2025   Moin Bloch            Changed Old To New Billing Table

EXEC  [dbo].[USP_GetSOBillingDepositeData_BySOId] 4349
**************************************************************/ 
CREATE    PROCEDURE [dbo].[USP_GetSOBillingDepositeData_BySOId]      
@SalesOrderId BIGINT = NULL
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      

	DECLARE @SOModuleId INT
	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	
	SELECT  sobi.ReferenceId SalesOrderId,
			sobi.MasterCompanyId,
			SUM(ISNULL(sobi.GrandTotal, 0)) AS GrandTotal,
			SUM(ISNULL(sobi.RemainingAmount, 0)) AS RemainingAmount,
			SUM(ISNULL(sobi.DepositAmount, 0)) AS DepositAmount,
			SUM(ISNULL(sobi.UsedDeposit, 0)) AS UsedDeposit
		FROM [DBO].[BillingInvoicing] sobi WITH(NOLOCK)
		WHERE sobi.ReferenceId = @SalesOrderId AND sobi.[ModuleId] = @SOModuleId
			  AND sobi.IsPerformaInvoice = 1 AND UPPER(InvoiceStatus) = 'INVOICED' 
		GROUP BY sobi.ReferenceId,sobi.MasterCompanyId

 END TRY          
 BEGIN CATCH      
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'USP_GetSOBillingDepositeData_BySOId'       
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@SalesOrderId AS VARCHAR(10)), '') + ''      
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