/*************************************************************           
 ** File:   [UpdateSOFreightNameColumnsWithId]           
 ** Author:   
 ** Description: 
 ** Purpose:         
 ** Date: 
          
 ** PARAMETERS:           
 @MasterCompanyId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    10/17/2024   Vishal Suthar		Modified to make use of new SO tables
     
 --  EXEC [dbo].[UpdateSOFreightNameColumnsWithId] 5
**************************************************************/
CREATE PROCEDURE [dbo].[UpdateSOFreightNameColumnsWithId]
	@SalesOrderId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update sof
		SET ShipViaName = sv.Name,
		UOMName = uom.ShortName,
		DimensionUOMName = duom.ShortName,
		CurrencyName = c.Code,
		ItemMasterId = sop.ItemMasterId,
		ConditionId = sop.ConditionId
		FROM [dbo].[SalesOrderFreight] sof WITH (NOLOCK)
		LEFT JOIN DBO.ShippingVia sv WITH (NOLOCK) ON sof.ShipViaId = sv.ShippingViaId
		LEFT JOIN DBO.UnitOfMeasure uom WITH (NOLOCK) ON sof.UOMId = uom.UnitOfMeasureId
		LEFT JOIN DBO.UnitOfMeasure duom WITH (NOLOCK) ON sof.DimensionUOMId = duom.UnitOfMeasureId
		LEFT JOIN DBO.Currency c WITH (NOLOCK) ON sof.CurrencyId = c.CurrencyId
		LEFT JOIN DBO.[SalesOrderPartV1] sop WITH (NOLOCK) ON sof.SalesOrderPartId = sop.SalesOrderPartId
		Where sof.SalesOrderId = @SalesOrderId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateSOFreightNameColumnsWithId' 
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