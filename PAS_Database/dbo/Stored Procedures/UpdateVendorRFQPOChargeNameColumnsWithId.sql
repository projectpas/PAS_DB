/*************************************************************           
 ** File:   [UpdateVendorRFQPOChargeNameColumnsWithId]           
 ** Author:  Shrey Chandegara
 ** Description: This stored procedure is used to Get Purchase Order Charges coloum Update
 ** Purpose:         
 ** Date:   17/05/2022      
          
 ** PARAMETERS: @VendorRFQPOId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    16-07-2024  Shrey Chandegara     Created
     
-- EXEC UpdateVendorRFQPOChargeNameColumnsWithId 8,0
************************************************************************/

CREATE   PROCEDURE [dbo].[UpdateVendorRFQPOChargeNameColumnsWithId]
	@VendorRFQPOId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
		BEGIN 
			Update soc
			SET VendorName = v.VendorName,
			ChargeName = C.ChargeType,
			MarkupName = p.PercentValue
			FROM [dbo].VendorRFQPOCharges soc WITH (NOLOCK)
			LEFT JOIN DBO.Vendor v WITH (NOLOCK) ON soc.VendorId = v.VendorId
			LEFT JOIN DBO.Charge c WITH (NOLOCK) ON soc.ChargesTypeId = c.ChargeId
			LEFT JOIN DBO.[Percent] p WITH (NOLOCK) ON soc.MarkupPercentageId = p.PercentId
			Where soc.VendorRFQPurchaseOrderId = @VendorRFQPOId
		END
		COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateVendorRFQPOChargeNameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRFQPOId, '') + ''
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