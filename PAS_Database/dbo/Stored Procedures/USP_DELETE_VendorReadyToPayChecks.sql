/*************************************************************           
 ** File:   [USP_DELETE_VendorReadyToPayChecks]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used USP_DELETE_VendorReadyToPayChecks 
 ** Purpose:         
 ** Date:   11/03/2024    
          
 ** PARAMETERS:           
 @ReadyToPayDetailsId BIGINT,@ReadyToPayId  BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
	1    11/03/2024   AMIT GHEDIYA		Crated
	2    05/04/2024   AMIT GHEDIYA		Update to delete CM as well.
     
-- EXEC USP_DELETE_VendorReadyToPayChecks 356,271 
**************************************************************/
CREATE      PROCEDURE [dbo].[USP_DELETE_VendorReadyToPayChecks]  
@ReadyToPayDetailsId BIGINT = NULL,  
@ReadyToPayId BIGINT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  

	DECLARE @VendorPaymentDetailsId BIGINT,@VendorId BIGINT,@VendorCreditMemoId BIGINT;

	SELECT @VendorPaymentDetailsId = VendorPaymentDetailsId FROM [DBO].[VendorReadyToPayDetails] WITH(NOLOCK) WHERE ReadyToPayDetailsId = @ReadyToPayDetailsId;
	
	If(@VendorPaymentDetailsId > 0)
	BEGIN 
		SELECT @VendorCreditMemoId = VendorCreditMemoId FROM [DBO].[VendorCreditMemoMapping] WITH(NOLOCK) WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId;
		IF(@VendorCreditMemoId > 0)
		BEGIN
			UPDATE [DBO].[VendorCreditMemo] set IsVendorPayment = null WHERE VendorCreditMemoId = @VendorCreditMemoId;
			DELETE [DBO].[VendorCreditMemoMapping] WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId;
		END
	END

	DELETE [DBO].[VendorReadyToPayDetails] WHERE ReadyToPayDetailsId = @ReadyToPayDetailsId AND ReadyToPayId = @ReadyToPayId;

  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_DELETE_VendorReadyToPayChecks'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReadyToPayDetailsId, '') + ''  
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