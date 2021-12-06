CREATE PROCEDURE [dbo].[GetExchangePackagingLabelPrint]
	@ExchangeSalesOrderId bigint,
	@PackagingSlipId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		select SPB.PackagingSlipId, SPB.PackagingSlipNo, sopt.ExchangeSalesOrderId, sl.StockLineNumber, sop.QtyQuoted as Qty, sopt.QtyToShip as QtyPicked, 
		imt.partnumber as PartNumber,imt.PartDescription, sopt.SOPickTicketNumber,
		sl.SerialNumber, sl.ControlNumber, sl.IdNumber, co.[Description] as ConditionDescription,
		so.ExchangeSalesOrderNumber,uom.ShortName as UOM, 
		(SELECT QtyShipped FROM DBO.ExchangeSalesOrderShippingItem SOSI  WITH(NOLOCK) Where SOSI.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId AND sopt.SOPickTicketId = SOSI.SOPickTicketId) AS QtyShipped,
		(SELECT NoOfContainer FROM DBO.ExchangeSalesOrderShippingItem SOSI  WITH(NOLOCK) LEFT JOIN DBO.ExchangeSalesOrderShipping SOS WITH(NOLOCK) ON SOS.ExchangeSalesOrderShippingId = SOSI.ExchangeSalesOrderShippingId
		Where SOSI.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId AND sopt.SOPickTicketId = SOSI.SOPickTicketId) AS NoOfContainer,
		(SELECT InvoiceNo FROM DBO.ExchangeSalesOrderBillingInvoicing SOBI WITH(NOLOCK) Where SOBI.ExchangeSalesOrderId = SOS.ExchangeSalesOrderId) AS InvoiceNo,
			(SELECT InvoiceDate FROM DBO.ExchangeSalesOrderBillingInvoicing SOBI WITH(NOLOCK) Where SOBI.ExchangeSalesOrderId = SOS.ExchangeSalesOrderId) AS InvoiceDate
		from ExchangeSOPickTicket sopt WITH(NOLOCK)
		LEFT JOIN DBO.ExchangeSalesOrderPackaginSlipItems SPI WITH(NOLOCK) ON sopt.SOPickTicketId = SPI.SOPickTicketId AND SPI.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId
		LEFT JOIN DBO.ExchangeSalesOrderPackaginSlipHeader SPB WITH(NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId
		LEFT JOIN DBO.SalesOrderShippingItem SSI WITH(NOLOCK) ON SSI.SOPickTicketId = sopt.SOPickTicketId
		INNER JOIN ExchangeSalesOrderPart sop WITH(NOLOCK) on sop.ExchangeSalesOrderId = sopt.ExchangeSalesOrderId AND sop.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId
		INNER JOIN ExchangeSalesOrder so WITH(NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
		LEFT JOIN Stockline sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		LEFT JOIN ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN Condition co WITH(NOLOCK) on co.ConditionId = sop.ConditionId
		LEFT JOIN UnitOfMeasure uom WITH(NOLOCK) on uom.UnitOfMeasureId = sl.PurchaseUnitOfMeasureId
		LEFT JOIN DBO.ExchangeSalesOrderShippingItem SOSI WITH(NOLOCK) ON SOSI.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId AND sopt.SOPickTicketId = SOSI.SOPickTicketId
		LEFT JOIN DBO.ExchangeSalesOrderShipping SOS WITH(NOLOCK) ON SOS.ExchangeSalesOrderShippingId = SOSI.ExchangeSalesOrderShippingId AND SOS.ExchangeSalesOrderId = @ExchangeSalesOrderId
		Where SPI.PackagingSlipId = @PackagingSlipId AND SPB.ExchangeSalesOrderId = @ExchangeSalesOrderId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetExchangePackagingLabelPrint' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''',
													 @Parameter2 = ' + ISNULL(@PackagingSlipId,'') + ''
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