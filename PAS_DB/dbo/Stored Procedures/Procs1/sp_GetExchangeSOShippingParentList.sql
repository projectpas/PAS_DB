CREATE Procedure [dbo].[sp_GetExchangeSOShippingParentList]
@ExchangeSalesOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		select DISTINCT imt.ItemMasterId as ExchangeSalesOrderPartId, 0 AS ItemNo, so.ExchangeSalesOrderNumber,imt.partnumber,imt.PartDescription, 
		SUM(ISNULL(sopt.QtyToShip, 0)) as QtyToShip,
		SUM(ISNULL(sosi.QtyShipped, 0)) as QtyShipped,
		sop.ExchangeSalesOrderId,
		--sop.SalesOrderPartId,
		SUM(ISNULL(sopt.QtyToShip, 0)) - SUM(ISNULL(sosi.QtyShipped,0)) as QtyRemaining,
		CASE WHEN SUM(ISNULL(sopt.QtyToShip, 0)) = SUM(ISNULL(sosi.QtyShipped, 0)) THEN 'Fullfilled'
		ELSE 'Fullfilling' END as [Status]--,sop.ItemNo 
		from DBO.ExchangeSalesOrderPart sop WITH (NOLOCK)
		LEFT JOIN DBO.ExchangeSalesOrder so WITH (NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
		INNER JOIN DBO.ExchangeSOPickTicket sopt WITH (NOLOCK) on sopt.ExchangeSalesOrderId = sop.ExchangeSalesOrderId AND sopt.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
		LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId
		LEFT JOIN DBO.ExchangeSalesOrderShippingItem sosi WITH (NOLOCK) on sosi.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId AND sosi.SOPickTicketId = sopt.SOPickTicketId
		LEFT JOIN DBO.ExchangeSalesOrderShipping sos WITH (NOLOCK) on sos.ExchangeSalesOrderShippingId = sosi.ExchangeSalesOrderShippingId AND sos.ExchangeSalesOrderId = sopt.ExchangeSalesOrderId
		WHERE sop.ExchangeSalesOrderId = @ExchangeSalesOrderId AND sopt.IsConfirmed = 1
		GROUP BY so.ExchangeSalesOrderNumber,imt.partnumber,imt.PartDescription, imt.ItemMasterId,
		sop.ExchangeSalesOrderId--,sop.SalesOrderPartId--, sop.ItemNo;
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetExchangeSOShippingParentList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''
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