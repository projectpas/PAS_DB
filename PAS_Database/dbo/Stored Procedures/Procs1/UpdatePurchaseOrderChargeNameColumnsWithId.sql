/*************************************************************           
 ** File:   [UpdatePurchaseOrderChargeNameColumnsWithId]           
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used to Get Purchase Order Charges coloum Update
 ** Purpose:         
 ** Date:   17/05/2022      
          
 ** PARAMETERS: @@PurchaseOrderChargestId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    17/05/2022  Subhash Saliya     Created
     
-- EXEC UpdatePurchaseOrderChargeNameColumnsWithId 8,0
************************************************************************/

CREATE PROCEDURE [dbo].[UpdatePurchaseOrderChargeNameColumnsWithId]
	@PurchaseOrderId int
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
			FROM [dbo].PurchaseOrderCharges soc WITH (NOLOCK)
			LEFT JOIN DBO.Vendor v WITH (NOLOCK) ON soc.VendorId = v.VendorId
			LEFT JOIN DBO.Charge c WITH (NOLOCK) ON soc.ChargesTypeId = c.ChargeId
			LEFT JOIN DBO.[Percent] p WITH (NOLOCK) ON soc.MarkupPercentageId = p.PercentId
			Where soc.PurchaseOrderId = @PurchaseOrderId
		END
		COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdatePurchaseOrderChargeNameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''
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