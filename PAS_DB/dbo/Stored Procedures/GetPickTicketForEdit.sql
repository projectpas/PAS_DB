CREATE PROCEDURE [dbo].[GetPickTicketForEdit]
@SOPickTicketId bigint,
@SalesOrderId bigint,
@SalesOrderPartId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		;WITH cte as(
			select SUM(QtyToShip) as TotalQtyToShip, SalesOrderId, SalesOrderPartId from SOPickTicket WITH(NOLOCK) where SalesOrderId = @SalesOrderId and SalesOrderPartId = @SalesOrderPartId
			group by SalesOrderId, SalesOrderPartId
		)
		select sopt.SOPickTicketId,
			sopt.SalesOrderId,
			sopt.SalesOrderPartId,
			imt.PartNumber
			,sl.StockLineId
			,imt.ItemMasterId As PartId
			,imt.PartDescription AS Description
			,sl.StockLineNumber
			,sl.SerialNumber
			,ISNULL(sl.QuantityAvailable, 0) AS QtyAvailable
			,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand,
			sopt.QtyToShip
			,CASE 
				WHEN imt.IsPma = 1 and imt.IsDER = 1 THEN 'PMA&DER'
				WHEN imt.IsPma = 1 and imt.IsDER = 0 THEN 'PMA'
				WHEN imt.IsPma = 0 and imt.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
				END AS StockType
			,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
					WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
					WHEN sl.TraceableToType = 9 THEN leTraceble.Name
					WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
					ELSE
						''
					END
				 AS TracableToName,
				 ISNULL(sop.Qty, 0) - ISNULL(cte.TotalQtyToShip, 0) as QtyToPick from cte
		INNER JOIN DBO.SOPickTicket sopt WITH(NOLOCK) on sopt.SalesOrderId = cte.SalesOrderId AND sopt.SalesOrderPartId = cte.SalesOrderPartId
		INNER JOIN DBO.SalesOrder so WITH(NOLOCK) on so.SalesOrderId = sopt.SalesOrderId
		INNER JOIN DBO.SalesOrderPart sop WITH(NOLOCK) on sop.SalesOrderId = sopt.SalesOrderId AND sop.SalesOrderPartId = sopt.SalesOrderPartId
		INNER JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		INNER JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
		LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
		LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
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
            , @AdhocComments     VARCHAR(150)    = 'GetPickTicketForEdit' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SOPickTicketId, '') + ''',
														@Parameter2 = ' + ISNULL(@SalesOrderId,'') + ', 
														@Parameter3 = ' + ISNULL(@SalesOrderPartId,'') + ''
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