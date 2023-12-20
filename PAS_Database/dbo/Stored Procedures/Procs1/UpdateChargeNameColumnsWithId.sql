
--  EXEC [dbo].[UpdateChargeNameColumnsWithId] 5
CREATE PROCEDURE [dbo].[UpdateChargeNameColumnsWithId]
	@SalesOrderId int
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
			MarkupName = p.PercentValue, -- Mark up name is pased as input from soq create component whichis percentage
			ItemMasterId = sop.ItemMasterId,
			ConditionId = sop.ConditionId
			FROM [dbo].[SalesOrderCharges] soc WITH (NOLOCK)
			LEFT JOIN DBO.Vendor v WITH (NOLOCK) ON soc.VendorId = v.VendorId
			LEFT JOIN DBO.Charge c WITH (NOLOCK) ON soc.ChargesTypeId = c.ChargeId
			LEFT JOIN DBO.[Percent] p WITH (NOLOCK) ON soc.MarkupPercentageId = p.PercentId
			LEFT JOIN DBO.[SalesOrderPart] sop WITH (NOLOCK) ON soc.SalesOrderPartId = sop.SalesOrderPartId
			Where soc.SalesOrderId = @SalesOrderId
		END
		COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateAssetInventoryColumns' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
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