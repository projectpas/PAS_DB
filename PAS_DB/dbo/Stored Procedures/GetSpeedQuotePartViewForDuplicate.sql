/*************************************************************           
 ** File:  [GetSpeedQuotePartViewForDuplicate]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to get SpeedQuotePartData for duplicate.
 ** Purpose:         
 ** Date:   03/04/2023     
          
 ** PARAMETERS: @@salesQuoteId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/04/2023  Amit Ghediya    Created
     
-- EXEC GetSpeedQuotePartViewForDuplicate 78
************************************************************************/
CREATE     PROCEDURE [dbo].[GetSpeedQuotePartViewForDuplicate]  
  @salesQuoteId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN

			SELECT part.SpeedQuotePartId,
				   part.SpeedQuoteId,
				   part.ItemMasterId,
				   (CASE WHEN ISNULL(part.QuantityRequested,0) = 0 THEN 0 ELSE part.QuantityRequested END) AS QuantityRequested,
				   part.UnitSalePrice,
				   part.MasterCompanyId,
				   part.CreatedBy,
				   part.CreatedDate,
				   part.UpdatedBy,
				   part.UpdatedDate,
				   itemMaster.PartNumber,
				   itemMaster.PartDescription,
				   itemMaster.IsPma,
				   itemMaster.IsDER,
				   part.UnitCost,
				   part.SalesPriceExtended,
				   part.UnitCostExtended,
				   part.MarginAmount,
				   part.MarginAmountExtended,
				   part.MarginPercentage,
				   part.CurrencyId,
				   (CASE WHEN ISNULL(condition.ConditionId,0) =0 THEN 0 ELSE condition.ConditionId END) AS ConditionId,
				   ISNULL(condition.Description,'') AS ConditionDescription,
				   ISNULL(um.ShortName,'') AS UomName,
				   part.StatusId,
				   ISNULL(part.Notes,'') AS Notes,
				   (CASE WHEN ISNULL(part.ItemNo,0) = 0 THEN 0 ELSE part.ItemNo END) AS ItemNo,
				   part.ManufacturerId,
				   part.Manufacturer,
				   part.TAT,
				   part.Type
			FROM
				SpeedQuotePart part
				JOIN ItemMaster itemMaster ON part.ItemMasterId = itemMaster.ItemMasterId
				LEFT JOIN Condition condition ON part.ConditionId = condition.ConditionId
				LEFT JOIN UnitOfMeasure um ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
			WHERE part.SpeedQuoteId = @salesQuoteId AND part.IsDeleted = 0
		END

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetSpeedQuotePartViewForDuplicate' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@salesQuoteId, '') + ''''
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