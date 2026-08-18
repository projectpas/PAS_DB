/*************************************************************             
 ** File:   [GetSalesOrderPartsView]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetSalesOrderPartsView
 ** Purpose:           
 ** Date:  12/12/2024        
            
 ** PARAMETERS: @SalesOrderId bigint  , @CurrencyId bigint
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    12/12/2024		EKTA CHANDEGRA	 Created  
    2    16/12/2024		EKTA CHANDEGRA	 Handled divided by zero exception for UnitSalesPricePerUnit   
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	4    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	5    20/July/2026			 RAJESH GAMI						[PN-17350] - Allow Non-Stock Inventory Parts in Sales Order Quote and Sales Order: removed IsNonStock=0 filters from StockLine and ItemMaster joins.
	6    11/August/2026			 Priyansh Patel						[PN-17573] SOQ/SO/Invoice Print: Added IsNonStock and IsService so SO Print can hide Stockline Number/Serial Number for Non-Stock Service Items.

 EXEC GetSalesOrderPartsView 1555 , 0
************************************************************************/ 
CREATE PROCEDURE [dbo].[GetSalesOrderPartsView]
    @SalesOrderId BIGINT,
    @CurrencyId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @ApprovedStatus INT = 2
		
		SELECT 
			part.SalesOrderId,
			part.SalesOrderPartId,
			soqps.SalesOrderQuoteId,
			part.ItemMasterId,
			sops.StockLineId,
			ISNULL(qs.StockLineNumber, '') AS StockLineNumber,
			part.FxRate,
			part.QtyOrder AS Qty,
			ISNULL(sopc.UnitSalesPrice, 0) AS UnitSalePrice,
			ISNULL(sopc.MarkUpPercentage, 0) AS MarkUpPercentage,
			0 AS SalesBeforeDiscount,
			ISNULL(sopc.DiscountPercentage, 0) AS Discount,
			ISNULL(sopc.DiscountAmount, 0) AS DiscountAmount,
			sopc.NetSaleAmount AS NetSales,
			part.MasterCompanyId,
			part.CreatedBy,
			part.CreatedDate,
			part.UpdatedBy,
			part.UpdatedDate,
			itemMaster.PartNumber,
			itemMaster.PartDescription,
			ISNULL(qs.OEM,0) AS IsOEM,
			itemMaster.IsPma AS IsPMA,
			itemMaster.IsDER AS IsDER,
			ISNULL(itemMaster.IsNonStock, 0) AS IsNonStock,
			ISNULL(itemMaster.IsService, 0) AS IsService,
			'' AS MethodType,
			'' AS Method,
			ISNULL(qs.SerialNumber, '') AS SerialNumber,
			ISNULL(sopc.UnitCost, 0) AS UnitCost,
			ISNULL(sopc.UnitSalesPriceExtended, 0) AS SalesPriceExtended,
			ISNULL(sopc.MarginAmount, 0) AS MarkupExtended,
			0 AS SalesDiscountExtended,
			ISNULL(sopc.NetSaleAmount, 0) AS NetSalePriceExtended,
			ISNULL(sopc.UnitCostExtended, 0) AS UnitCostExtended,
			ISNULL(sopc.MarginAmount, 0) AS MarginAmount,
			ISNULL(sopc.MarginAmount, 0) AS MarginAmountExtended,
			ISNULL(sopc.MarginPercentage, 0) AS MarginPercentage,
			ISNULL((SELECT Code 
			FROM [dbo].[Currency] WITH(NOLOCK)
			WHERE CurrencyId = ISNULL(@CurrencyId,0)),'') AS CurrencyDescription, 
			ISNULL(cp.Description, '') AS ConditionDescription,
			ISNULL(q.SalesOrderQuoteNumber, '') AS SalesOrderQuoteNumber,
			ISNULL(qs.QuantityAvailable,0)  AS QtyAvailable,
			ISNULL(iu.Description, '') AS UOM,
			ISNULL(rPart.QtyToReserve, 0) AS QtyReserved,
			CASE WHEN sop.CustomerStatusId = @ApprovedStatus THEN 1 ELSE 0 END AS IsApproved,
			part.PriorityId,
			0 AS ItemNo,
			part.CustomerRequestDate,
			part.PromisedDate,
			part.EstimatedShipDate,
			part.ConditionId,
			part.QtyRequested,
			part.StatusId,
			part.CurrencyId,
			0 AS GrossSalePricePerUnit,
			0 AS GrossSalePrice,
			'' AS TaxType,
			ISNULL(sopc.TaxPercentage, 0) AS TaxPercentage,
			ISNULL(sopc.TaxAmount, 0) AS TaxAmount,
			'' AS AltOrEqType,
			qs.ControlNumber,
			qs.IdNumber,
			part.POId,
			part.PONextDlvrDate,
			CASE
				WHEN ISNULL(part.QtyOrder,0) > 0 
				THEN (ISNULL(sopc.NetSaleAmount,0) / part.QtyOrder)
				ELSE ISNULL(sopc.NetSaleAmount,0)
			END AS UnitSalesPricePerUnit
			
		FROM [dbo].[SalesOrderPartV1] part WITH(NOLOCK)
		LEFT JOIN [dbo].[SalesOrderStockLineV1] sops WITH(NOLOCK) ON part.SalesOrderPartId = sops.SalesOrderPartId
		LEFT JOIN [dbo].[SalesOrderPartCost] sopc WITH(NOLOCK) ON part.SalesOrderPartId = sopc.SalesOrderPartId
		LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON sops.StockLineId = qs.StockLineId
		LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
		 LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON part.ConditionId = cp.ConditionId
		LEFT JOIN [dbo].[SalesOrderQuotePartV1] soqps WITH(NOLOCK) ON part.SalesOrderQuotePartId = soqps.SalesOrderQuotePartId
		LEFT JOIN [dbo].[SalesOrderQuote] q WITH(NOLOCK) ON soqps.SalesOrderQuoteId = q.SalesOrderQuoteId
		LEFT JOIN [dbo].[UnitOfMeasure] iu WITH(NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
		LEFT JOIN [dbo].[SalesOrderReserveParts] rPart WITH(NOLOCK) ON part.SalesOrderPartId = rPart.SalesOrderPartId
		LEFT JOIN [dbo].[SalesOrderApproval] sop WITH(NOLOCK) ON part.SalesOrderPartId = sop.SalesOrderPartId
		WHERE part.SalesOrderId = @SalesOrderId
			AND ISNULL(part.IsDeleted,0) = 0
			AND ISNULL(part.IsActive,0) = 1
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderPartsView'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''',
													 @Parameter2 = ' + ISNULL(@CurrencyId, '') +''
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

END;