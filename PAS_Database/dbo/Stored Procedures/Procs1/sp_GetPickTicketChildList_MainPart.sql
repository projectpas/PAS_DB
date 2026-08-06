/*************************************************************           
 ** File:   [sp_GetPickTicketChildList_MainPart]           
 ** Author:   
 ** Description: This SP is Used to get Stockline list for Pick Ticket childlist data   
 ** Purpose:         
 ** Date:     
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------  
	1										created
	2    01/01/2024   Devendra Shekh	update for serialnumber
	3    02/17/2025   Bhargav Saliya	UTC Date Changes
	4    07/03/2025   Vishal Suthar		Added EnforceMpnPickTicketConfirmation column
	5    09/July/2026   RAJESH GAMI		[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
EXEC DBO.sp_GetPickTicketChildList_MainPart @referenceId=20751,@OrderPartId =618
**************************************************************/ 
CREATE PROCEDURE [dbo].[sp_GetPickTicketChildList_MainPart]
	@referenceId BIGINT,
	@OrderPartId BIGINT,
	@EmployeeId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT wopt.PickTicketNumber as PickTicketNumber, wopt.QtyToShip, CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END As 'SerialNumber', sl.StockLineNumber, 
		CASE WHEN CAST(wopt.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wopt.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE))END PickedDate,
		CONCAT(emp.FirstName, ' ', emp.LastName) as PickedBy, wopt.PickTicketId as PickTicketId, wopt.WorkorderId as referenceId,
		wopt.WorkFlowWorkOrderId as OrderPartId,
		CONCAT(empy.FirstName ,' ', empy.LastName) as ConfirmedBy, sl.ControlNumber, sl.IdNumber, 
		CASE WHEN CAST(wopt.ConfirmedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wopt.ConfirmedDate, @CurrntEmpTimeZoneDesc) AS DATE))END ConfirmedDate,
		sl.StockLineId,
		wopt.IsConfirmed,
		WO.EnforceMpnPickTicketConfirmation
		from DBO.WOPickTicket wopt WITH (NOLOCK)
		INNER JOIN DBO.WorkOrderWorkFlow wowf WITH (NOLOCK) on wopt.WorkFlowWorkOrderId = wowf.WorkOrderPartNoId
		INNER JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) on wop.WorkOrderId = wopt.WorkorderId and wowf.WorkOrderPartNoId = wop.ID
		LEFT JOIN DBO.StockLine sl WITH (NOLOCK) on sl.StockLineId = wop.StocklineId AND ISNULL(sl.IsNonStock,0) = 0
		INNER JOIN DBO.Employee emp WITH (NOLOCK) on emp.EmployeeId = wopt.PickedById
		LEFT JOIN DBO.Employee empy WITH (NOLOCK) on empy.EmployeeId = wopt.ConfirmedById
		LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) on WO.WorkOrderId = wopt.WorkorderId
		WHERE wopt.WorkorderId = @referenceId and wopt.WorkFlowWorkOrderId = @OrderPartId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetPickTicketChildList_MainPart' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@referenceId, '') + ''',
													 @Parameter2 = ' + ISNULL(@OrderPartId,'') + ''
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