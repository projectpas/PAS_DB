/*************************************************************           
 ** File:   [GetVendorPaymentTotalCost]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used TO GET VendorPayment TotalCost
 ** Purpose:         
 ** Date:   20/03/2024      
          
 ** PARAMETERS: @LegalEntityId bigint
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------		-------------------------------- 
	1    20/03/2024   AMIT GHEDIYA		Created
     
-- EXEC GetVendorPaymentTotalCost 1
**************************************************************/
CREATE    PROCEDURE [dbo].[GetVendorPaymentTotalCost]  
@LegalEntityId bigint
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
	
	SELECT 
		SUM(VRTPD.PaymentMade) AS 'totalcost'
	FROM [DBO].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK)
		INNER JOIN [DBO].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId 
	WHERE VRTPDH.LegalEntityId = @LegalEntityId;
  
 END TRY  
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetVendorPaymentTotalCost'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LegalEntityId, '') + ''  
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