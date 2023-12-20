CREATE   PROCEDURE [dbo].[GetPackagingLabelPrintForVendorRMA]
	@VendorRMAId bigint,
	@PackagingSlipId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT SPB.PackagingSlipId, SPB.PackagingSlipNo, sopt.VendorRMAId, sl.StockLineNumber, sop.Qty, sopt.QtyToShip as QtyPicked, 
		imt.partnumber as PartNumber,imt.PartDescription, sopt.RMAPickTicketNumber,
		sl.SerialNumber, sl.ControlNumber, sl.IdNumber, co.[Description] as ConditionDescription,
		so.RMANumber,uom.ShortName as UOM, 
		(SELECT top 1 QtyShipped FROM DBO.RMAShippingItem SOSI WITH(NOLOCK) Where SOSI.VendorRMADetailId = sopt.VendorRMADetailId AND sopt.RMAPickTicketId = SOSI.RMAPickTicketId) AS QtyShipped,
		(SELECT top 1 NoOfContainer FROM DBO.RMAShippingItem SOSI WITH(NOLOCK) LEFT JOIN DBO.RMAShipping SOS WITH(NOLOCK) ON SOS.RMAShippingId = SOSI.RMAShippingId
		Where SOSI.VendorRMADetailId = sopt.VendorRMADetailId AND sopt.RMAPickTicketId = SOSI.RMAPickTicketId) AS NoOfContainer,
		(SELECT top 1 InvoiceNo FROM DBO.SalesOrderBillingInvoicing SOBI WITH(NOLOCK) Where SOBI.SalesOrderId = SOS.VendorRMAId) AS InvoiceNo,
		(SELECT top 1 InvoiceDate FROM DBO.SalesOrderBillingInvoicing SOBI WITH(NOLOCK) Where SOBI.SalesOrderId = SOS.VendorRMAId) AS InvoiceDate
		FROM RMAPickTicket sopt WITH(NOLOCK)
		LEFT JOIN DBO.VendorRMAPackaginSlipItems SPI WITH(NOLOCK) ON sopt.RMAPickTicketId = SPI.RMAPickTicketId AND SPI.VendorRMADetailId = sopt.VendorRMADetailId
		LEFT JOIN DBO.VendorRMAPackaginSlipHeader SPB WITH(NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId
		LEFT JOIN DBO.RMAShippingItem SSI WITH(NOLOCK) ON SSI.RMAPickTicketId = sopt.RMAPickTicketId
		INNER JOIN VendorRMADetail sop WITH(NOLOCK) on sop.VendorRMAId = sopt.VendorRMAId AND sop.VendorRMADetailId = sopt.VendorRMADetailId
		INNER JOIN VendorRMA so WITH(NOLOCK) on so.VendorRMAId = sop.VendorRMAId
		LEFT JOIN Stockline sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		LEFT JOIN ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN Condition co WITH(NOLOCK) on co.ConditionId = sl.ConditionId
		LEFT JOIN UnitOfMeasure uom WITH(NOLOCK) on uom.UnitOfMeasureId = sl.PurchaseUnitOfMeasureId
		LEFT JOIN DBO.RMAShippingItem SOSI WITH(NOLOCK) ON SOSI.VendorRMADetailId = sopt.VendorRMADetailId AND sopt.RMAPickTicketId = SOSI.RMAPickTicketId
		LEFT JOIN DBO.RMAShipping SOS WITH(NOLOCK) ON SOS.RMAShippingId = SOSI.RMAShippingId AND SOS.VendorRMAId = @VendorRMAId
		WHERE SPI.PackagingSlipId = @PackagingSlipId AND SPB.VendorRMAId = @VendorRMAId
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPackagingLabelPrintForVendorRMA' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''',
													 @Parameter2 = ' + ISNULL(@PackagingSlipId,'') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName          = @DatabaseName
                    , @AdhocComments       = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName     =  @ApplicationName
                    , @ErrorLogID          = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END