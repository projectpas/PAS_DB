/*************************************************************             
 ** File:   [USP_UpdateSalesOrderShippingAirwayBillNo]             
 ** Author:   Amit Ghediya 
 ** Description: This stored procedure is used Add/Update Sales Order Shipping Tracking Number
 ** Purpose:           
 ** Date:   06/30/2023      
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			-------------------------------            
    1    06/30/2023   Amit Ghediya		Created       
**************************************************************/  
CREATE    PROCEDURE [dbo].[USP_VendorRMA_UpdateSalesOrderShippingAirwayBillNo]
(
	@RMAShippingId BIGINT,
	@AirwayBill VARCHAR(MAX)
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	 SET NOCOUNT ON;  
  
	  BEGIN TRY  
		  BEGIN TRANSACTION  
		   BEGIN    
				UPDATE DBO.RMAShipping SET AirwayBill = @AirwayBill
				WHERE RMAShippingId = @RMAShippingId

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
				  , @AdhocComments     VARCHAR(150)    = 'USP_VendorRMA_UpdateSalesOrderShippingAirwayBillNo'   
				  , @ProcedureParameters VARCHAR(3000)  = '@SalesorderShippingId = '''+ ISNULL(@RMAShippingId, '') + '' +  
					'@AirwayBill = '''+ ISNULL(@AirwayBill, '') + ''  
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