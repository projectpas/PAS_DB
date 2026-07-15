/*************************************************************           
 ** File:   [GetPackagingLabelPrint]
 ** Author: unknown
 ** Description:
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1					unknown			Created
	2	02/1/2024		AMIT GHEDIYA	added isperforma Flage for SO
	3	10/15/2024		VISHAL SUTHAR	Modified to make use of new SO part tables
	4   07-07-2025      Moin Bloch      Changed Old To New Billing Table
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	6    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0

************************************************************************/
CREATE PROCEDURE [dbo].[GetPackagingLabelPrint]
	@SalesOrderId bigint,
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
		
		SELECT SPB.PackagingSlipId, SPB.PackagingSlipNo, sopt.SalesOrderId, sl.StockLineNumber, sop.QtyOrder Qty, sopt.QtyToShip as QtyPicked, 
		imt.partnumber as PartNumber,imt.PartDescription, sopt.SOPickTicketNumber,
		sl.SerialNumber, sl.ControlNumber, sl.IdNumber, co.[Description] as ConditionDescription,
		so.SalesOrderNumber,uom.ShortName as UOM, 
	(SELECT top 1 QtyShipped FROM DBO.SalesOrderShippingItem SOSI WITH(NOLOCK) Where SOSI.SalesOrderPartId = sopt.SalesOrderPartId AND sopt.SOPickTicketId = SOSI.SOPickTicketId) AS QtyShipped,
		(SELECT top 1 NoOfContainer FROM DBO.SalesOrderShippingItem SOSI WITH(NOLOCK) LEFT JOIN DBO.SalesOrderShipping SOS WITH(NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
		Where SOSI.SalesOrderPartId = sopt.SalesOrderPartId AND sopt.SOPickTicketId = SOSI.SOPickTicketId) AS NoOfContainer,
		(SELECT top 1 InvoiceNo FROM DBO.BillingInvoicing SOBI WITH(NOLOCK) Where SOBI.ReferenceId = SOS.SalesOrderId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0  AND sobi.[ModuleId] = @SOModuleId) AS InvoiceNo,
		(SELECT top 1 InvoiceDate FROM DBO.BillingInvoicing SOBI WITH(NOLOCK) Where SOBI.ReferenceId = SOS.SalesOrderId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0  AND sobi.[ModuleId] = @SOModuleId) AS InvoiceDate
		FROM dbo.SOPickTicket sopt WITH(NOLOCK)
		LEFT JOIN DBO.SalesOrderPackaginSlipItems SPI WITH(NOLOCK) ON sopt.SOPickTicketId = SPI.SOPickTicketId AND SPI.SalesOrderPartId = sopt.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderPackaginSlipHeader SPB WITH(NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId
		LEFT JOIN DBO.SalesOrderShippingItem SSI WITH(NOLOCK) ON SSI.SOPickTicketId = sopt.SOPickTicketId
		INNER JOIN dbo.SalesOrderPartV1 sop WITH(NOLOCK) on sop.SalesOrderId = sopt.SalesOrderId AND sop.SalesOrderPartId = sopt.SalesOrderPartId
		LEFT JOIN dbo.SalesOrderStocklineV1 stk WITH(NOLOCK) on stk.SalesOrderPartId = sop.SalesOrderPartId AND stk.SalesOrderStocklineId = sopt.SalesOrderPartStocklineId
		INNER JOIN dbo.SalesOrder so WITH(NOLOCK) on so.SalesOrderId = sop.SalesOrderId
		LEFT JOIN dbo.Stockline sl WITH(NOLOCK) on sl.StockLineId = stk.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
		LEFT JOIN dbo.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		 AND ISNULL(imt.IsNonStock,0) = 0
		 LEFT JOIN dbo.Condition co WITH(NOLOCK) on co.ConditionId = sop.ConditionId
		LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK) on uom.UnitOfMeasureId = sl.PurchaseUnitOfMeasureId
		LEFT JOIN DBO.SalesOrderShippingItem SOSI WITH(NOLOCK) ON SOSI.SalesOrderPartId = sopt.SalesOrderPartId AND sopt.SOPickTicketId = SOSI.SOPickTicketId
		LEFT JOIN DBO.SalesOrderShipping SOS WITH(NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId AND SOS.SalesOrderId = @SalesOrderId
		WHERE SPI.PackagingSlipId = @PackagingSlipId AND SPB.SalesOrderId = @SalesOrderId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPackagingLabelPrint' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''',
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