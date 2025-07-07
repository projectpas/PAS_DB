/*************************************************************           
 ** File:   [USP_GetCommonBillingInvoicingIds]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to GET Common Billing Invoicing Pdf Data
 ** Purpose:         
 ** Date:   05/07/2025
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/07/2025   Moin Bloch		Created

--   EXEC [dbo].[USP_GetCommonBillingInvoicingIds] 9731,15
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetCommonBillingInvoicingIds]
@ReferenceId BIGINT = NULL,
@ModuleId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @WOModuleId INT
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		BEGIN		
			SELECT [BillingInvoicingId]	
			FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK) 
			WHERE BI.[ReferenceId] = @ReferenceId
				AND BI.[ModuleId] = @WOModuleId
				AND ISNULL(BI.[IsPerformaInvoice],0) = 0
				AND ISNULL(BI.[IsVersionIncrease],0) = 0
				AND BI.[IsActive] = 1 
				AND BI.[IsDeleted] = 0 
				ORDER BY InvoiceNo 
		END
	
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCommonBillingInvoicingIds' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100)) 
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