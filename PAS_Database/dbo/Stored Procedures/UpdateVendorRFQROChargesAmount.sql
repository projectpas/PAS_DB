/*************************************************************           
 ** File:   [UpdateVendorRFQROChargesAmount]           
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to update VendorRFQROCharges Billing Amount
 ** Purpose:         
 ** Date:   15/07/2024        
          
 ** PARAMETERS: @VendorRFQROId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15/07/2024   Abhishek Jirawla     Created
     
-- EXEC [UpdateVendorRFQROChargesAmount] 13
************************************************************************/

CREATE  PROCEDURE [dbo].[UpdateVendorRFQROChargesAmount]
@VendorRFQROId bigint,
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
		UPDATE dbo.VendorRFQRepairOrder SET [TotalCharges] = ISNULL([TotalCharges], 0) - ISNULL(@BillingAmount,0) where [VendorRFQRepairOrderId] = @VendorRFQROId;
	END
	ELSE
	BEGIN
	    UPDATE dbo.VendorRFQRepairOrder SET [TotalCharges] = ISNULL([TotalCharges], 0) + ISNULL(@BillingAmount,0) where [VendorRFQRepairOrderId] = @VendorRFQROId;
	END
	COMMIT  TRANSACTION  
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateVendorRFQROChargesAmount' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@VendorRFQROId, '') AS varchar(100))													
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