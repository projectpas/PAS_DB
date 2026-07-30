/*************************************************************           
 ** File:   [GetPackagingLabelPrintForVendorRMA]
 ** Author: unknown
 ** Description: 
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author				Change Description            
 ** --   --------      -------				--------------------------------          
    1					unknown				Created
	3	02/1/2024		AMIT GHEDIYA		added isperforma Flage for SO
	4   07-07-2025      Moin Bloch			Changed Old To New Billing Table
	5   09-06-2026      Priyansh Patel		UOM changes releted to qtyshipped [PN-16778]
	6	10/07/2026		Nakul Chandigra		Renamed sopt.QtyToShip from QtyToShip to QtyPicked.
	7	13/07/2026		Ayushi Patel		UOM Convertion [PN-17254]
	8	29/07/2026		Divyesh Kathiriya   Fixed "QtyShipped" convert double time in UOM. [PN-17476]
************************************************************************/
CREATE PROCEDURE [dbo].[GetPackagingLabelPrintForVendorRMA]
	@VendorRMAId bigint,
	@PackagingSlipId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
	    DECLARE @SOModuleId INT
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

		SELECT 
			SPB.PackagingSlipId, 
			SPB.PackagingSlipNo, 
			sopt.VendorRMAId, 
			sl.StockLineNumber, 
			--FORMAT(ISNULL(sop.Qty,0), 'N', 'en-us') AS Qty, 
			FORMAT(CASE WHEN ISNULL(imt.StockUnitOfMeasure,'') = ISNULL(imt.PurchaseUnitOfMeasure,'') OR ISNULL(imt.StockUnitOfMeasure,'') = '' OR ISNULL(imt.PurchaseUnitOfMeasure,'') = '' THEN ISNULL(sop.Qty,0) ELSE dbo.fn_ConvertUOM(ISNULL(sop.Qty,0),imt.StockUnitOfMeasure,imt.PurchaseUnitOfMeasure,0,imt.MasterCompanyId) END,'N','en-us') AS Qty,
			--FORMAT(ISNULL(sopt.QtyToShip,0), 'N', 'en-us') AS QtyPicked,
			FORMAT(CASE WHEN ISNULL(imt.StockUnitOfMeasure,'') = ISNULL(imt.PurchaseUnitOfMeasure,'') OR ISNULL(imt.StockUnitOfMeasure,'') = '' OR ISNULL(imt.PurchaseUnitOfMeasure,'') = '' THEN ISNULL(sopt.QtyToShip,0) ELSE dbo.fn_ConvertUOM(ISNULL(sopt.QtyToShip,0),imt.StockUnitOfMeasure,imt.PurchaseUnitOfMeasure,0,imt.MasterCompanyId) END,'N','en-us') AS QtyPicked,
			imt.partnumber as PartNumber,
			imt.PartDescription, 
			sopt.RMAPickTicketNumber,
			sl.SerialNumber, 
			sl.ControlNumber, 
			sl.IdNumber, 
			co.[Description] as ConditionDescription,
			so.RMANumber,uom.ShortName as UOM,
			FORMAT(ISNULL((SELECT TOP 1 QtyShipped FROM DBO.RMAShippingItem SOSI WITH(NOLOCK) WHERE SOSI.VendorRMADetailId = sopt.VendorRMADetailId AND sopt.RMAPickTicketId = SOSI.RMAPickTicketId), 0), 'N', 'en-us') AS QtyShipped,
			--FORMAT(CASE WHEN ISNULL(imt.StockUnitOfMeasure,'') = ISNULL(imt.PurchaseUnitOfMeasure,'') OR ISNULL(imt.StockUnitOfMeasure,'') = '' OR ISNULL(imt.PurchaseUnitOfMeasure,'') = '' THEN ISNULL((SELECT TOP 1 QtyShipped FROM DBO.RMAShippingItem SOSI WITH(NOLOCK) WHERE SOSI.VendorRMADetailId = sopt.VendorRMADetailId AND sopt.RMAPickTicketId = SOSI.RMAPickTicketId),0) ELSE dbo.fn_ConvertUOM(ISNULL((SELECT TOP 1 QtyShipped FROM DBO.RMAShippingItem SOSI WITH(NOLOCK) WHERE SOSI.VendorRMADetailId = sopt.VendorRMADetailId AND sopt.RMAPickTicketId = SOSI.RMAPickTicketId),0),imt.StockUnitOfMeasure,imt.PurchaseUnitOfMeasure,0,imt.MasterCompanyId) END,'N','en-us') AS QtyShipped,
			(SELECT top 1 NoOfContainer FROM DBO.RMAShippingItem SOSI WITH(NOLOCK) LEFT JOIN DBO.RMAShipping SOS WITH(NOLOCK) ON SOS.RMAShippingId = SOSI.RMAShippingId
					Where SOSI.VendorRMADetailId = sopt.VendorRMADetailId AND sopt.RMAPickTicketId = SOSI.RMAPickTicketId) AS NoOfContainer,
			(SELECT top 1 InvoiceNo FROM DBO.BillingInvoicing SOBI WITH(NOLOCK) Where SOBI.ReferenceId = SOS.VendorRMAId AND SOBI.[ModuleId] = @SOModuleId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0) AS InvoiceNo,
			(SELECT top 1 InvoiceDate FROM DBO.BillingInvoicing SOBI WITH(NOLOCK) Where SOBI.ReferenceId = SOS.VendorRMAId AND SOBI.[ModuleId] = @SOModuleId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0) AS InvoiceDate
		FROM dbo.RMAPickTicket sopt WITH(NOLOCK)
		LEFT JOIN DBO.VendorRMAPackaginSlipItems SPI WITH(NOLOCK) ON sopt.RMAPickTicketId = SPI.RMAPickTicketId AND SPI.VendorRMADetailId = sopt.VendorRMADetailId
		LEFT JOIN DBO.VendorRMAPackaginSlipHeader SPB WITH(NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId
		LEFT JOIN DBO.RMAShippingItem SSI WITH(NOLOCK) ON SSI.RMAPickTicketId = sopt.RMAPickTicketId
		INNER JOIN dbo.VendorRMADetail sop WITH(NOLOCK) on sop.VendorRMAId = sopt.VendorRMAId AND sop.VendorRMADetailId = sopt.VendorRMADetailId
		INNER JOIN dbo.VendorRMA so WITH(NOLOCK) on so.VendorRMAId = sop.VendorRMAId
		LEFT JOIN  dbo.Stockline sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		LEFT JOIN  dbo.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN  dbo.Condition co WITH(NOLOCK) on co.ConditionId = sl.ConditionId
		LEFT JOIN  dbo.UnitOfMeasure uom WITH(NOLOCK) on uom.UnitOfMeasureId = sl.PurchaseUnitOfMeasureId
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