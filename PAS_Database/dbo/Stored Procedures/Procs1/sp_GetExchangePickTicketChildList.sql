CREATE Procedure [dbo].[sp_GetExchangePickTicketChildList]
	@ExchangeSalesOrderId  bigint,
	@ItemMasterId bigint,
	@ConditionId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		select sopt.SOPickTicketNumber, sopt.QtyToShip, sl.SerialNumber, sl.StockLineNumber, sopt.CreatedDate as PickedDate,
		CONCAT(emp.FirstName , ' ', emp.LastName) as PickedBy, sopt.SOPickTicketId, sopt.ExchangeSalesOrderId, sopt.ExchangeSalesOrderPartId,
		CONCAT(empy.FirstName , ' ', empy.LastName) as ConfirmedBy, sl.ControlNumber, sl.IdNumber, sopt.ConfirmedDate, sl.StockLineId, sopt.IsConfirmed from ExchangeSOPickTicket sopt WITH(NOLOCK)
		INNER JOIN ExchangeSalesOrderPart sop WITH(NOLOCK) on sop.ExchangeSalesOrderId = sopt.ExchangeSalesOrderId and sop.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId
		LEFT JOIN StockLine sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		INNER JOIN Employee emp WITH(NOLOCK) on emp.EmployeeId = sopt.PickedById
		LEFT JOIN Employee empy WITH(NOLOCK) on empy.EmployeeId = sopt.ConfirmedById
		where sopt.ExchangeSalesOrderId=@ExchangeSalesOrderId AND sop.ItemMasterId=@ItemMasterId and sop.ConditionId = @ConditionId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetExchangePickTicketChildList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''',
													 @Parameter2 = ' + ISNULL(@ItemMasterId,'') + ',
													 @Parameter3 = ' + ISNULL(@ConditionId,'') + ''
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