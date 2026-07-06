/*************************************************************************************
 ** File:   [USP_GetSOFrightsById]           
 ** Author:   Shrey Chandegara
 ** Description: This stored procedure is used get SO Freight By SOId    
 ** Purpose:         
 ** Date:   31-03-2025
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  				Change Description            
 ** --   --------     -------				--------------------------------          
    1    31-03-2025   Shrey Chandegara		Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

-- EXEC USP_GetSOFrightsById 760,0  
**************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSOFrightsById]
@SalesOrderId BIGINT,
@IsDeleted BIT

AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT DISTINCT
			sf.SalesOrderFreightId,
			sf.SalesOrderQuoteId,
			sf.SalesOrderId,
			sf.SalesOrderPartId,
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
			sf.BillingAmount,
			sf.BillingMethodId,
			sf.BillingRate,
			sf.HeaderMarkupId,
			sf.HeaderMarkupPercentageId,
			sf.MarkupPercentageId,
			ISNULL(uom.ShortName, '') AS UOM,
			ISNULL(duom.ShortName, '') AS DimensionUOM,
			ISNULL(cur.Code, '') AS Currency,
			im.PartNumber,
			sf.ItemMasterId,
			sf.ConditionId
		FROM [dbo].[SalesOrderFreight] sf WITH(NOLOCK)
		LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON sf.UOMId = uom.UnitOfMeasureId
		LEFT JOIN [dbo].[UnitOfMeasure] duom WITH(NOLOCK) ON sf.DimensionUOMId = duom.UnitOfMeasureId
		LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON sf.CurrencyId = cur.CurrencyId
		LEFT JOIN [dbo].[SalesOrderPartV1] part WITH(NOLOCK) ON sf.SalesOrderPartId = part.SalesOrderPartId
		LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON part.ItemMasterId = im.ItemMasterId
		 AND ISNULL(im.IsNonStock,0) = 0 WHERE sf.IsDeleted = ISNULL(@IsDeleted,0) AND sf.SalesOrderId = @SalesOrderId;

	END TRY
	BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_GetSOFrightsById'
            ,@ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
            ,@ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END