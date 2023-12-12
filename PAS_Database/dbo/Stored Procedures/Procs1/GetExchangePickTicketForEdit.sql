CREATE PROCEDURE [dbo].[GetExchangePickTicketForEdit]
@SOPickTicketId bigint,
@ExchangeSalesOrderId bigint,
@ExchangeSalesOrderPartId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		;WITH cte as(
			select SUM(QtyToShip)as TotalQtyToShip,ExchangeSalesOrderId,ExchangeSalesOrderPartId from ExchangeSOPickTicket WITH(NOLOCK) where ExchangeSalesOrderId=@ExchangeSalesOrderId and ExchangeSalesOrderPartId=@ExchangeSalesOrderPartId
			group by ExchangeSalesOrderId,ExchangeSalesOrderPartId
		)
		--select * from cte;
		select sopt.SOPickTicketId,
			sopt.ExchangeSalesOrderId,
			sopt.ExchangeSalesOrderPartId,
			imt.PartNumber
			,sl.StockLineId
			,imt.ItemMasterId As PartId
			,imt.PartDescription AS Description
			,sl.StockLineNumber
			,sl.SerialNumber
			,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
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
				 ISNULL(sop.QtyQuoted,0) - ISNULL(cte.TotalQtyToShip,0) as QtyToPick from cte
		INNER JOIN DBO.ExchangeSOPickTicket sopt WITH(NOLOCK) on sopt.ExchangeSalesOrderId = cte.ExchangeSalesOrderId AND sopt.ExchangeSalesOrderPartId = cte.ExchangeSalesOrderPartId
		INNER JOIN DBO.ExchangeSalesOrder so WITH(NOLOCK) on so.ExchangeSalesOrderId = sopt.ExchangeSalesOrderId
		INNER JOIN DBO.ExchangeSalesOrderPart sop WITH(NOLOCK) on sop.ExchangeSalesOrderId = sopt.ExchangeSalesOrderId AND sop.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId
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
            , @AdhocComments     VARCHAR(150)    = 'GetExchangePickTicketForEdit' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SOPickTicketId, '') + ''',
														@Parameter2 = ' + ISNULL(@ExchangeSalesOrderId,'') + ', 
														@Parameter3 = ' + ISNULL(@ExchangeSalesOrderPartId,'') + ''
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