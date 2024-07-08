/*************************************************************           
 ** File:   [UpdateVendorRFQPOFreightAmount]           
 ** Author:  Shrey Chandegara
 ** Description: This stored procedure is used to update VendorRFQPOFreight Billing Amount
 ** Purpose:         
 ** Date:   04/07/2024        
          
 ** PARAMETERS: @VendorRFQPOId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/07/2024   Shrey Chandegara     Created
     
-- EXEC [UpdateVendorRFQPOFreightAmount] 13
************************************************************************/

CREATE     PROCEDURE [dbo].[UpdateVendorRFQPOFreightAmount]
@VendorRFQPOId bigint,
@BillingAmount bigint,
@Opr int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION  
	IF(@Opr=1)
	BEGIN
		UPDATE dbo.VendorRFQPurchaseOrder SET [TotalFreight] -= @BillingAmount where [VendorRFQPurchaseOrderId] = @VendorRFQPOId;
	END
	ELSE
	BEGIN
	    UPDATE dbo.VendorRFQPurchaseOrder SET [TotalFreight] += @BillingAmount where [VendorRFQPurchaseOrderId] = @VendorRFQPOId;
	END
	COMMIT  TRANSACTION  
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateVendorRFQPOFreightAmount' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@VendorRFQPOId, '') AS varchar(100))													
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END