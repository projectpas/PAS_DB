CREATE Procedure [dbo].[sp_GetSOShippingParentList]
@SalesOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT DISTINCT imt.ItemMasterId AS SalesOrderPartId, 0 AS ItemNo, so.SalesOrderNumber, imt.partnumber, imt.PartDescription, 
		SUM(ISNULL(sopt.QtyToShip, 0)) AS QtyToShip,
		SUM(ISNULL(sosi.QtyShipped, 0)) AS QtyShipped,
		sop.SalesOrderId,
		SUM(ISNULL(sopt.QtyToShip, 0)) - SUM(ISNULL(sosi.QtyShipped, 0)) AS QtyRemaining,
		CASE WHEN SUM(ISNULL(sopt.QtyToShip, 0)) = SUM(ISNULL(sosi.QtyShipped, 0)) THEN 'Shipped'
		ELSE 'Shipping' END AS [Status]
		FROM DBO.SalesOrderPart sop WITH (NOLOCK)
		LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
		INNER JOIN DBO.SOPickTicket sopt WITH (NOLOCK) ON sopt.SalesOrderId = sop.SalesOrderId AND sopt.SalesOrderPartId = sop.SalesOrderPartId
		LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = sop.StockLineId
		LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sosi.SalesOrderPartId = sop.SalesOrderPartId 
					AND sosi.SOPickTicketId = sopt.SOPickTicketId
		LEFT JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId 
					AND sos.SalesOrderId = sopt.SalesOrderId
		WHERE sop.SalesOrderId = @SalesOrderId AND sopt.IsConfirmed = 1
		GROUP BY so.SalesOrderNumber, imt.partnumber, imt.PartDescription, imt.ItemMasterId, sop.SalesOrderId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetSOShippingParentList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
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