/*************************************************************           
 ** File:   [UpdateSOQChargeNameColumnsWithId]           
 ** Author: Vishal Suthar
 ** Description: Update name columns into corrosponding reference Id values from respective master table
 ** Purpose:         
 ** Date: 23-Dec-2020
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    10/17/2024   Vishal Suthar		Modified to make use of new SOQ tables
     
--  EXEC [dbo].[UpdateSOQChargeNameColumnsWithId] 5
**************************************************************/
CREATE PROCEDURE [dbo].[UpdateSOQChargeNameColumnsWithId]
	@SalesOrderQuoteId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update soqc
		SET VendorName = v.VendorName,
		ChargeName = C.ChargeType,
		MarkupName = p.PercentValue, -- Mark up name is pased as input from soq create component whichis percentage
		ItemMasterId = sop.ItemMasterId,
		ConditionId = sop.ConditionId
		FROM [dbo].[SalesOrderQuoteCharges] soqc WITH (NOLOCK)
		LEFT JOIN DBO.Vendor v WITH (NOLOCK) ON soqc.VendorId = v.VendorId
		LEFT JOIN DBO.Charge c WITH (NOLOCK) ON soqc.ChargesTypeId = c.ChargeId
		LEFT JOIN DBO.[Percent] p WITH (NOLOCK) ON soqc.MarkupPercentageId = p.PercentId
		LEFT JOIN DBO.[SalesOrderQuotePartV1] sop WITH (NOLOCK) ON soqc.SalesOrderQuotePartId = sop.SalesOrderQuotePartId
		Where soqc.SalesOrderQuoteId = @SalesOrderQuoteId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateSOQChargeNameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderQuoteId, '') + ''
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