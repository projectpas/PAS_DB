/*************************************************************               
 ** File:  [GetSalesOrderFreightList]               
 ** Author:  Ekta Chnadegra 
 ** Description: This stored procedure is used to GetSalesOrderFreightList By Id.    
 ** Purpose:             
 ** Date:   28/02/2025          
              
 ** PARAMETERS: @SalesOrderQuoteId BIGINT,@IsDeleted BIT
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------		--------------------------------              
    1    28/02/2025  Ekta Chandegra		Created    
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
         
-- EXEC GetSalesOrderFreightList 915 ,0
************************************************************************/   
CREATE   PROCEDURE [dbo].[GetSalesOrderFreightList]
    @SalesOrderQuoteId BIGINT,
    @IsDeleted BIT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN
			SELECT DISTINCT
				sf.SalesOrderQuoteFreightId,
				sf.SalesOrderQuoteId,
				sf.SalesOrderQuotePartId,
				sf.Amount,
				sf.CreatedBy,
				sf.CreatedDate,
				sf.IsActive,
				sf.IsDeleted,	
				sf.MasterCompanyId,
				sf.Memo,
				sf.ShipViaId,
				sf.UpdatedBy,
				sf.UpdatedDate,
				sf.Weight,
				sf.ShipViaName,
				sf.Length,
				sf.Width,
				sf.Height,
				sf.UOMId,
				sf.DimensionUOMId,
				sf.CurrencyId,
				sf.MarkupFixedPrice,
				sf.MarkupPercentageId,
				sf.HeaderMarkupId,
				sf.HeaderMarkupPercentageId,
				sf.BillingMethodId,
				sf.BillingRate,
				sf.BillingAmount,
				sf.UOMName,
				sf.DimensionUOMName,
				sf.CurrencyName,
				im.PartNumber,
				sf.ItemMasterId,
				(im.PartNumber + ' - ' + cond.Description) AS ItemNo,
				im.PartNumber AS Pn,
				part.ConditionId
			FROM [dbo].[SalesOrderQuoteFreight] sf WITH(NOLOCK)
			LEFT JOIN [dbo].[SalesOrderQuotePartV1] part WITH(NOLOCK) ON sf.SalesOrderQuotePartId = part.SalesOrderQuotePartId
			LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON sf.ItemMasterId = im.ItemMasterId
			 AND ISNULL(im.IsNonStock,0) = 0
			 INNER JOIN [dbo].[Condition] cond WITH(NOLOCK) ON sf.ConditionId = cond.ConditionId
			WHERE ISNULL(sf.IsDeleted,0) = @IsDeleted
			AND sf.SalesOrderQuoteId = @SalesOrderQuoteId;
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
        , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderFreightList'     
        ,@ProcedureParameters VARCHAR(3000) = '@SalesOrderQuoteId = ''' + CAST(ISNULL(@SalesOrderQuoteId, '') AS varchar(100)) +
											  '@IsDeleted = ''' + CAST(ISNULL(@IsDeleted, '') AS varchar(100)) 
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