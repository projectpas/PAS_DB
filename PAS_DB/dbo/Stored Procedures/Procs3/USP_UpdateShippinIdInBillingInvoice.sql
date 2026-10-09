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
	2    24/AUG/2026  Kishor Makwana [PN-17763] - Update  BillingInvoicingItems based on SalesorderPart + Stockline .
	3    08/Oct/2026  Kishor Makwana [PN-18238] - [PN-17760] - UPDATE re-pointed ALL invoice items of the part/stockline to the shipment being performed (an invoice for shipment 1 became shipment 2). Now only items without a ShippingId are linked, and not to a shipment that already has its own invoice item.


	EXEC [dbo].[USP_UpdateShippinIdInBillingInvoice] 295,1
**************************************************************/  
CREATE PROCEDURE [dbo].[USP_UpdateShippinIdInBillingInvoice]
(
	@SalesorderShippingId BIGINT,
	@MasterCompanyId BIGINT,
	@salesOrderPartId BIGINT,
	@SalesOrderId BIGINT
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	 SET NOCOUNT ON;  
  
	  BEGIN TRY  
		  BEGIN TRANSACTION  
		   BEGIN    			
		   DECLARE @SOModuleId INT = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder')

		   --UPDATE T
					--SET T.ShippingId = @SalesorderShippingId
					--FROM dbo.BillingInvoicingItems T
					--INNER JOIN dbo.SalesOrderShippingItem SOS WITH (NOLOCK)
					--	ON T.SubReferenceId = SOS.SalesOrderPartId
					--WHERE SOS.SalesOrderShippingId = @SalesorderShippingId
					--  AND ISNULL(SOS.IsDeleted, 0) = 0
					--  AND T.ModuleId = @SOModuleId 
					--  AND T.MasterCompanyId = @MasterCompanyId AND SOS.MasterCompanyId = @MasterCompanyId
			UPDATE BII SET BII.ShippingId=  @SalesorderShippingId FROM BillingInvoicingItems  BII WITH (NOLOCK)
			INNER JOIN SalesorderStocklinev1 SSLV  WITH (NOLOCK) ON  SSLV.SalesOrderPartid =BII.SubReferenceId and SSLV.stocklineid = BII.StocklineId
			INNER JOIN SOPickTicket SPT WITH (NOLOCK) ON SPT.SalesOrderPartStocklineId = SSLV.SalesOrderStocklineId and SPT.SalesOrderPartid =SSLV.SalesOrderPartid
			INNER JOIN SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOSI.SalesOrderPartid =  SPT.SalesOrderPartid AND SOSI.SOPickTicketId =SPT.SOPickTicketId AND  SOSI.SalesOrderShippingId = @SalesorderShippingId
			WHERE BII.referenceId= @SalesOrderId and BII.SubReferenceId=@salesOrderPartId
			AND ISNULL(SOSI.IsDeleted, 0) = 0 AND BII.ModuleId = @SOModuleId  AND BII.MasterCompanyId = @MasterCompanyId AND SOSI.MasterCompanyId = @MasterCompanyId
			-- [PN-18238] only link an invoice item that has no shipment yet (invoiced before shipping), and never to a shipment that already has its own invoice item for this stockline.
			-- Previously every item of the part/stockline was re-pointed to the newest shipment, so an invoice for shipment 1 jumped to shipment 2 when shipment 2 was performed.
			AND ISNULL(BII.ShippingId, 0) = 0
			AND NOT EXISTS (SELECT 1 FROM BillingInvoicingItems BIX WITH (NOLOCK) WHERE BIX.ReferenceId = BII.ReferenceId AND BIX.SubReferenceId = BII.SubReferenceId AND BIX.StocklineId = BII.StocklineId
								AND BIX.ShippingId = @SalesorderShippingId AND BIX.BillingInvoicingItemId <> BII.BillingInvoicingItemId AND ISNULL(BIX.IsVersionIncrease,0) = 0 AND ISNULL(BIX.IsPerformaInvoice,0) = 0 AND BIX.ModuleId = @SOModuleId)
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