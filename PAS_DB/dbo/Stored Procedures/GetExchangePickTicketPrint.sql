
CREATE PROCEDURE [dbo].[GetExchangePickTicketPrint]
@ExchangeSalesOrderId bigint,
@ExchangeSalesOrderPartId bigint,
@SOPickTicketId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		;WITH cte as(
				select SUM(QtyToShip)as TotalQtyToShip ,ExchangeSalesOrderId, ExchangeSalesOrderPartId from DBO.ExchangeSOPickTicket WITH(NOLOCK) where ExchangeSalesOrderId = @ExchangeSalesOrderId and ExchangeSalesOrderPartId = @ExchangeSalesOrderPartId
				group by ExchangeSalesOrderId, ExchangeSalesOrderPartId
		)
		select sopt.SOPickTicketId, sopt.CreatedDate as SOPickTicketDate, sopt.ExchangeSalesOrderId, sl.StockLineNumber, sop.QtyQuoted as Qty, 
		--sopt.QtyToShip as QtyShipped,
		cte.TotalQtyToShip as QtyShipped, 
		imt.partnumber as PartNumber, imt.PartDescription, sopt.SOPickTicketNumber,
		sl.SerialNumber, sl.ControlNumber, sl.IdNumber, co.[Description] as ConditionDescription,
		so.ExchangeSalesOrderNumber, uom.ShortName as UOM, s.[Name] as SiteName, w.[Name] as WarehouseName, l.[Name] as LocationName, sh.[Name] as ShelfName,
		bn.[Name] as BinName,
		'' as PriorityName,
		po.PurchaseOrderNumber as PONumber,
		sl.QuantityOnHand,sl.QuantityAvailable as QtyAvailable,
		sop.Memo as Notes,
		--(sop.QtyQuoted - cte.TotalQtyToShip) as QtyToPick 
		QtyToShip as QtyToPick
		from ExchangeSOPickTicket sopt WITH(NOLOCK)
		INNER JOIN cte  WITH(NOLOCK) on cte.ExchangeSalesOrderId = sopt.ExchangeSalesOrderId AND cte.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId
		INNER JOIN ExchangeSalesOrderPart sop WITH(NOLOCK) on sop.ExchangeSalesOrderId = sopt.ExchangeSalesOrderId AND sop.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId
		INNER JOIN ExchangeSalesOrder so WITH(NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
		LEFT JOIN Stockline sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		INNER JOIN ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN Condition co WITH(NOLOCK) on co.ConditionId = sop.ConditionId
		LEFT JOIN UnitOfMeasure uom WITH(NOLOCK) on uom.UnitOfMeasureId = imt.ConsumeUnitOfMeasureId
		LEFT JOIN [Site] s WITH(NOLOCK) on s.SiteId = sl.SiteId
		LEFT JOIN Warehouse w WITH(NOLOCK) on w.WarehouseId = sl.WarehouseId
		LEFT JOIN [Location] l WITH(NOLOCK) on l.LocationId = sl.LocationId
		LEFT JOIN Shelf sh WITH(NOLOCK) on sh.ShelfId = sl.ShelfId
		LEFT JOIN Bin bn WITH(NOLOCK) on bn.BinId = sl.BinId
		LEFT JOIN PurchaseOrder po WITH(NOLOCK) on po.PurchaseOrderId = sl.PurchaseOrderId
		WHERE sopt.SOPickTicketId = @SOPickTicketId;
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetExchangePickTicketPrint' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''',
														@Parameter2 = ' + ISNULL(@ExchangeSalesOrderPartId,'') + ', 
														@Parameter3 = ' + ISNULL(@SOPickTicketId,'') + ''
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