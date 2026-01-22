/*************************************************************
 ** File:   [sp_GetROPickTicketChildList]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get Pick ticket child table list
 ** Purpose:
 ** Date:

 ** PARAMETERS:
         
 ** RETURN VALUE:
  
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			-----------------------
	1    04/14/2025   Vishal Suthar		Created
     
  EXEC [dbo].[sp_GetROPickTicketChildList] 2547, 20751, 1, 2
**************************************************************/
CREATE   Procedure [dbo].[sp_GetROPickTicketChildList]
	@RepairOrderId BIGINT,
	@RepairOrderPartId BIGINT,
	@EmployeeId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
		FROM dbo.Employee E WITH (NOLOCK)
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;

		SELECT DISTINCT ropt.ROPickTicketNumber, 
		ropt.QtyToShip, 
		sl.SerialNumber,
		sl.StockLineNumber,
		CASE WHEN CAST(ropt.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ropt.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) END PickedDate,
		CONCAT(emp.FirstName, ' ', emp.LastName) as PickedBy,
		ropt.ROPickTicketId, 
		ropt.RepairOrderId,
		ropt.RepairOrderPartId,
		CONCAT(empy.FirstName, ' ', empy.LastName) as ConfirmedBy, sl.ControlNumber, sl.IdNumber,
		CASE WHEN CAST(ropt.ConfirmedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ropt.ConfirmedDate, @CurrntEmpTimeZoneDesc) AS DATE)) END ConfirmedDate,
		sl.StockLineId, ropt.IsConfirmed 
		FROM DBO.ROPickTicket ropt WITH(NOLOCK)
		INNER JOIN DBO.RepairOrderPart rop WITH(NOLOCK) on rop.RepairOrderId = ropt.RepairOrderId  AND rop.RepairOrderPartRecordId = ropt.RepairOrderPartId
		LEFT JOIN DBO.StockLine sl WITH(NOLOCK) on sl.StockLineId = rop.StockLineId
		INNER JOIN DBO.Employee emp WITH(NOLOCK) on emp.EmployeeId = ropt.PickedById
		LEFT JOIN DBO.Employee empy WITH(NOLOCK) on empy.EmployeeId = ropt.ConfirmedById
		WHERE ropt.RepairOrderId = @RepairOrderId AND rop.RepairOrderPartRecordId = @RepairOrderPartId;
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'sp_GetROPickTicketChildList' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderId, '') + ''',
													@Parameter2 = ' + ISNULL(@RepairOrderPartId,'') + ''
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