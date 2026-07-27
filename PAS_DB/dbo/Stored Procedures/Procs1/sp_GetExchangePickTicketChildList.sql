/*************************************************************	
 ** File:   [sp_GetExchangePickTicketChildList]           
 ** Author:  <Unknown>
 ** Description: This stored procedure is used get exchange pick ticket child list.
 ** Purpose:         
 ** Date:         
 ** PARAMETERS: 
 ** RETURN VALUE:              
*************************************************************          
 ** Change History             
*************************************************************       
 ** PR   Date			 Author					Change Description              
 ** --   --------		 -------				--------------------------------            
    1    Unknown		Unknown					Unknown
	2    27-Mar-2025	Divyesh Kathiriya		Update PickedDate based on Employee time zone
	3    09/July/2026	RAJESH GAMI		[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	4    20/July/2026	RAJESH GAMI		[PN-17350] - Removed IsNonStock=0 filters so Non-Stock parts appear on the pick ticket.

	EXEC [dbo].[sp_GetExchangePickTicketChildList] 135,3,1,226
***************************************************************/
CREATE Procedure [dbo].[sp_GetExchangePickTicketChildList]
	@ExchangeSalesOrderId  bigint,
	@ItemMasterId bigint,
	@ConditionId bigint,
	@EmployeeId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
		SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM 
			dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN 
			dbo.TimeZone ETZ WITH (NOLOCK) 
			ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN 
			dbo.LegalEntity LE WITH (NOLOCK) 
			ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN 
			dbo.TimeZone LTZ WITH (NOLOCK) 
			ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE 
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee


		select sopt.SOPickTicketNumber, sopt.QtyToShip, sl.SerialNumber, sl.StockLineNumber,
		--sopt.CreatedDate as PickedDate,
		CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
			CASE WHEN CAST(sopt.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(sopt.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
		ELSE (CAST(sopt.CreatedDate AS DATETIME)) END PickedDate,
		CONCAT(emp.FirstName , ' ', emp.LastName) as PickedBy, sopt.SOPickTicketId, sopt.ExchangeSalesOrderId, sopt.ExchangeSalesOrderPartId,
		CONCAT(empy.FirstName , ' ', empy.LastName) as ConfirmedBy, sl.ControlNumber, sl.IdNumber, 
		--sopt.ConfirmedDate,		
		CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
			CASE WHEN CAST(sopt.ConfirmedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(sopt.ConfirmedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
		ELSE (CAST(sopt.ConfirmedDate AS DATETIME)) END ConfirmedDate,		
		sl.StockLineId, sopt.IsConfirmed 
		from ExchangeSOPickTicket sopt WITH(NOLOCK)
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