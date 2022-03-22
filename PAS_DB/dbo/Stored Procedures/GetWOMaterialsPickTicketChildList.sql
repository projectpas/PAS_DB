/*************************************************************           
 ** File:   [GetWOMaterialsPickTicketChildList]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Material list for Pick Ticket    
 ** Purpose:         
 ** Date:   05/10/2021        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/10/2021   Vishal Suthar Created
	1    05/24/2021   Hemant Saliya Updated Stockline Condition and Add Content Managment
     
--EXEC [GetWOMaterialsPickTicketChildList] 343,768
**************************************************************/

CREATE PROCEDURE [dbo].[GetWOMaterialsPickTicketChildList]
@WorkOrderId  bigint,
@OrderPartId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION
			SELECT DISTINCT wopt.PickTicketNumber as PickTicketNumber,
					wopt.QtyToShip,
					sl.SerialNumber,
					sl.StockLineNumber,
					wopt.CreatedDate as PickedDate,
					CONCAT(emp.FirstName ,' ', emp.LastName) as PickedBy,
					wopt.PickTicketId as PickTicketId,
					wopt.WorkorderId as referenceId,
					wopt.WorkOrderMaterialsId as OrderPartId,
					CONCAT(empy.FirstName ,' ', empy.LastName) as ConfirmedBy,
					sl.ControlNumber,
					sl.IdNumber,
					wopt.ConfirmedDate,
					sl.StockLineId,
					wopt.IsConfirmed 
			FROM dbo.WorkorderPickTicket wopt WITH(NOLOCK)
				INNER JOIN dbo.Employee emp WITH(NOLOCK) on emp.EmployeeId = wopt.PickedById
				INNER JOIN dbo.WorkOrderMaterials wop WITH(NOLOCK) ON wop.WorkOrderId = wopt.WorkorderId AND wop.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId
				LEFT JOIN dbo.StockLine sl WITH(NOLOCK) on sl.StockLineId = wopt.StocklineId
				LEFT JOIN dbo.Employee empy WITH(NOLOCK) on empy.EmployeeId = wopt.ConfirmedById
			WHERE wopt.WorkorderId=@WorkOrderId AND wopt.WorkOrderMaterialsId=@OrderPartId AND wopt.QtyToShip > 0 
		COMMIT  TRANSACTION
		END TRY
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWOMaterialsPickTicketChildList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''',
													   @Parameter2 = '''+ ISNULL(@OrderPartId, '') + ''
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