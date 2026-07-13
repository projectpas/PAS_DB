/*************************************************************           
 ** File:   [GetROPackagingLabelPrint]
 ** Author: unknown
 ** Description:
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR  Date		Author			Change Description            
 ** --  --------	-------			--------------------------------          
    1	05/15/2025	VISHAL SUTHAR	Created
	2   13/07/2026  Ayushi Patel	UOM Changes [PN-17172]
EXEC GetROPackagingLabelPrint 2601, 1
************************************************************************/
CREATE   PROCEDURE [dbo].[GetROPackagingLabelPrint]
	@RepairOrderId bigint,
	@PackagingSlipId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT SPB.PackagingSlipId, SPB.PackagingSlipNo, sopt.RepairOrderId, sl.StockLineNumber, sop.QuantityOrdered Qty, sopt.QtyToShip as QtyPicked, 
		imt.partnumber as PartNumber,imt.PartDescription, sopt.ROPickTicketNumber,
		sl.SerialNumber, sl.ControlNumber, sl.IdNumber, co.[Description] as ConditionDescription,
		so.RepairOrderNumber,uom.ShortName as UOM, 
	(SELECT top 1 QtyShipped FROM DBO.RepairOrderShippingItem SOSI WITH(NOLOCK) Where SOSI.RepairOrderPartId = sopt.RepairOrderPartId AND sopt.ROPickTicketId = SOSI.ROPickTicketId) AS QtyShipped,
		(SELECT top 1 NoOfContainer FROM DBO.RepairOrderShippingItem SOSI WITH(NOLOCK) LEFT JOIN DBO.RepairOrderShipping SOS WITH(NOLOCK) ON SOS.RepairOrderShippingId = SOSI.RepairOrderShippingId
		Where SOSI.RepairOrderPartId = sopt.RepairOrderPartId AND sopt.ROPickTicketId = SOSI.ROPickTicketId) AS NoOfContainer,
		'' AS InvoiceNo,
		'' AS InvoiceDate
		FROM ROPickTicket sopt WITH(NOLOCK)
		LEFT JOIN DBO.RepairOrderPackaginSlipItems SPI WITH(NOLOCK) ON sopt.ROPickTicketId = SPI.ROPickTicketId AND SPI.RepairOrderPartId = sopt.RepairOrderPartId
		LEFT JOIN DBO.RepairOrderPackaginSlipHeader SPB WITH(NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId
		LEFT JOIN DBO.RepairOrderShippingItem SSI WITH(NOLOCK) ON SSI.ROPickTicketId = sopt.ROPickTicketId
		INNER JOIN RepairOrderPart sop WITH(NOLOCK) on sop.RepairOrderId = sopt.RepairOrderId AND sop.RepairOrderPartRecordId = sopt.RepairOrderPartId
		INNER JOIN RepairOrder so WITH(NOLOCK) on so.RepairOrderId = sop.RepairOrderId
		LEFT JOIN Stockline sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		LEFT JOIN ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN Condition co WITH(NOLOCK) on co.ConditionId = sop.ConditionId
		LEFT JOIN UnitOfMeasure uom WITH(NOLOCK) on uom.UnitOfMeasureId = sl.StockUnitOfMeasureId
		LEFT JOIN DBO.RepairOrderShippingItem SOSI WITH(NOLOCK) ON SOSI.RepairOrderPartId = sopt.RepairOrderPartId AND sopt.ROPickTicketId = SOSI.ROPickTicketId
		LEFT JOIN DBO.RepairOrderShipping SOS WITH(NOLOCK) ON SOS.RepairOrderShippingId = SOSI.RepairOrderShippingId AND SOS.RepairOrderId = @RepairOrderId
		WHERE SPI.PackagingSlipId = @PackagingSlipId AND SPB.RepairOrderId = @RepairOrderId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetROPackagingLabelPrint' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderId, '') + ''',
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