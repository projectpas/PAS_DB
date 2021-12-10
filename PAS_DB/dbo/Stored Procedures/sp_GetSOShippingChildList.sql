CREATE Procedure [dbo].[sp_GetSOShippingChildList]
	@SalesOrderId  bigint,
	@SalesOrderPartId bigint,
	@ConditionId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT DISTINCT sopt.SOPickTicketId, sos.SalesOrderShippingId, CASE WHEN sosi.SalesOrderPartId IS NOT NULL THEN sos.ShipDate ELSE NULL END AS ShipDate,
		CASE WHEN sosi.SalesOrderPartId IS NOT NULL THEN sos.SOShippingNum ELSE NULL END AS SOShippingNum,
		sopt.SOPickTicketNumber, sopt.QtyToShip, so.SalesOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
		sl.SerialNumber, cr.[Name] as CustomerName, soc.CustomsValue, soc.CommodityCode, ISNULL(sosi.QtyShipped,0) as QtyShipped, sop.ItemNo,
		sos.SalesOrderId, (CASE WHEN sosi.SalesOrderPartId IS NOT NULL THEN sosi.SalesOrderPartId ELSE sop.SalesOrderPartId END) SalesOrderPartId,
		sos.AirwayBill, SPB.PackagingSlipNo, SPB.PackagingSlipId, 
		CASE WHEN sos.SalesOrderShippingId IS NOT NULL THEN sos.SmentNum ELSE 0 END AS 'SmentNo'
		FROM DBO.SOPickTicket sopt WITH (NOLOCK) 
		INNER JOIN DBO.SalesOrderPart sop WITH (NOLOCK) ON sop.SalesOrderId = sopt.SalesOrderId 
					AND sop.SalesOrderPartId = sopt.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sosi.SalesOrderPartId = sop.SalesOrderPartId 
					AND sosi.SOPickTicketId = sopt.SOPickTicketId
		LEFT JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId 
					AND sos.SalesOrderId = sopt.SalesOrderId
		INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
		LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = sop.StockLineId
		LEFT JOIN DBO.SalesOrderCustomsInfo soc WITH (NOLOCK) ON soc.SalesOrderShippingId = sos.SalesOrderShippingId
		LEFT JOIN DBO.Customer cr WITH (NOLOCK)  on cr.CustomerId = so.CustomerId
		LEFT JOIN DBO.SalesOrderPackaginSlipItems SPI WITH (NOLOCK) ON sopt.SOPickTicketId = SPI.SOPickTicketId 
					AND SPI.SalesOrderPartId = sop.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderPackaginSlipHeader SPB WITH (NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId
		WHERE sopt.SalesOrderId = @SalesOrderId
		AND sop.ItemMasterId = @SalesOrderPartId
		AND sop.ConditionId = @ConditionId
		AND sopt.IsConfirmed = 1
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetSOShippingChildList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''',
													 @Parameter2 = ' + ISNULL(@SalesOrderPartId,'') + ''
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