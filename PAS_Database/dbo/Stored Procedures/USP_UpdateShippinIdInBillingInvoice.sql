/*************************************************************             
 ** File:   [USP_UpdateShippinIdInBillingInvoice]             
 ** Author:   RAJESH GAMI  
 ** Description: This stored procedure is used to update the shipping id in Billing Invoicing Item By Shipping Id
 ** Purpose:           
 ** Date:   09/Jul/2025     
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
    1    09/Jul/2025  RAJESH GAMI	Created    
	
	EXEC [dbo].[USP_UpdateShippinIdInBillingInvoice] 295,1
**************************************************************/  
CREATE    PROCEDURE [dbo].[USP_UpdateShippinIdInBillingInvoice]
(
	@SalesorderShippingId BIGINT,
	@MasterCompanyId BIGINT
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	 SET NOCOUNT ON;  
  
	  BEGIN TRY  
		  BEGIN TRANSACTION  
		   BEGIN    			
		   DECLARE @SOModuleId INT = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder')

		   UPDATE T
					SET T.ShippingId = @SalesorderShippingId
					FROM dbo.BillingInvoicingItems T
					INNER JOIN dbo.SalesOrderShippingItem SOS WITH (NOLOCK)
						ON T.SubReferenceId = SOS.SalesOrderPartId
					WHERE SOS.SalesOrderShippingId = @SalesorderShippingId
					  AND ISNULL(SOS.IsDeleted, 0) = 0
					  AND T.ModuleId = @SOModuleId 
					  AND T.MasterCompanyId = @MasterCompanyId AND SOS.MasterCompanyId = @MasterCompanyId

		   END
		  COMMIT TRANSACTION
	  END TRY
	  BEGIN CATCH
		IF @@trancount > 0  
		SELECT  
		ERROR_NUMBER() AS ErrorNumber,  
		ERROR_STATE() AS ErrorState,  
		ERROR_SEVERITY() AS ErrorSeverity,  
		ERROR_PROCEDURE() AS ErrorProcedure,  
		ERROR_LINE() AS ErrorLine,  
		ERROR_MESSAGE() AS ErrorMessage;  
  
		ROLLBACK TRANSACTION;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				  , @AdhocComments     VARCHAR(150)    = 'USP_UpdateShippinIdInBillingInvoice'   
				  , @ProcedureParameters VARCHAR(3000)  = '@SalesorderShippingId = '''+ ISNULL(@SalesorderShippingId, '') + '' 
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