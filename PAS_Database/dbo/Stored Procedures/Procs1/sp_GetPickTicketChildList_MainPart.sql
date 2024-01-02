/*************************************************************           
 ** File:   [SearchStockLinePickTicketPop_WO]           
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

EXEC DBO.sp_GetPickTicketChildList_MainPart @referenceId=20751,@OrderPartId =618
**************************************************************/ 
CREATE   Procedure [dbo].[sp_GetPickTicketChildList_MainPart]
@referenceId  bigint,
@OrderPartId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT wopt.PickTicketNumber as PickTicketNumber, wopt.QtyToShip, CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END As 'SerialNumber', sl.StockLineNumber, wopt.CreatedDate as PickedDate,
		CONCAT(emp.FirstName, ' ', emp.LastName) as PickedBy, wopt.PickTicketId as PickTicketId, wopt.WorkorderId as referenceId,
		wopt.WorkFlowWorkOrderId as OrderPartId,
		CONCAT(empy.FirstName ,' ', empy.LastName) as ConfirmedBy, sl.ControlNumber, sl.IdNumber, wopt.ConfirmedDate, sl.StockLineId,
		wopt.IsConfirmed 
		from WOPickTicket wopt WITH (NOLOCK)
		INNER JOIN DBO.WorkOrderWorkFlow wowf WITH (NOLOCK) on wopt.WorkFlowWorkOrderId = wowf.WorkOrderPartNoId
		INNER JOIN WorkOrderPartNumber wop WITH (NOLOCK) on wop.WorkOrderId = wopt.WorkorderId and wowf.WorkOrderPartNoId = wop.ID
		LEFT JOIN StockLine sl WITH (NOLOCK) on sl.StockLineId = wop.StocklineId
		INNER JOIN Employee emp WITH (NOLOCK) on emp.EmployeeId = wopt.PickedById
		LEFT JOIN Employee empy WITH (NOLOCK) on empy.EmployeeId = wopt.ConfirmedById
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