/*************************************************************           
 ** File:   [GetSubWOMaterialsPickTicketChildList]           
 ** Author:   Hemant Saliya
 ** Description: This SP is used retrieve Sub WO Material list for Pick Ticket    
 ** Purpose:         
 ** Date:   09/20/2021 
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/20/2021   Hemant Saliya Created
     
--EXEC [GetSubWOMaterialsPickTicketChildList] 343,768
**************************************************************/

CREATE PROCEDURE [dbo].[GetSubWOMaterialsPickTicketChildList]
@WorkOrderId  BIGINT,
@SubWorkOrderId  BIGINT,
@OrderPartId  BIGINT
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
					wopt.SubWorkorderId,
					wopt.SubWorkorderPartNoId,
					wopt.SubWorkOrderMaterialsId as OrderPartId,
					CONCAT(empy.FirstName ,' ', empy.LastName) as ConfirmedBy,
					sl.ControlNumber,
					sl.IdNumber,
					wopt.ConfirmedDate,
					sl.StockLineId,
					wopt.IsConfirmed 
			FROM dbo.SubWorkorderPickTicket wopt WITH(NOLOCK)
				INNER JOIN dbo.Employee emp WITH(NOLOCK) on emp.EmployeeId = wopt.PickedById
				INNER JOIN dbo.SubWorkOrderMaterials wop WITH(NOLOCK) ON wop.WorkOrderId = wopt.WorkorderId AND wop.SubWorkOrderId = wopt.SubWorkOrderId AND wop.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId
				LEFT JOIN dbo.StockLine sl WITH(NOLOCK) on sl.StockLineId = wopt.StocklineId
				LEFT JOIN dbo.Employee empy WITH(NOLOCK) on empy.EmployeeId = wopt.ConfirmedById
			WHERE wopt.WorkorderId=@WorkOrderId AND wopt.SubWorkOrderId=@SubWorkOrderId AND wopt.SubWorkOrderMaterialsId = @OrderPartId AND wopt.QtyToShip > 0 
		COMMIT  TRANSACTION
		END TRY
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSubWOMaterialsPickTicketChildList' 
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