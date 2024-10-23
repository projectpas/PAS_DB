/*************************************************************           
 ** File:   [sp_GetPickTicketChildList]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get Pick ticket child table list
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    10/15/2024   Vishal Suthar Modified SP to get Pick ticket child table list from new SO Part tables
     
-- EXEC [dbo].[sp_GetPickTicketChildList] 1103, 3, 7
**************************************************************/
CREATE  Procedure [dbo].[sp_GetPickTicketChildList]
	@SalesOrderId  bigint,
	@ItemMasterId bigint,
	@ConditionId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

		SELECT sopt.SOPickTicketNumber, sopt.QtyToShip, sl.SerialNumber, sl.StockLineNumber, sopt.CreatedDate as PickedDate,
		CONCAT(emp.FirstName, ' ', emp.LastName) as PickedBy, sopt.SOPickTicketId, sopt.SalesOrderId, sopt.SalesOrderPartId,
		CONCAT(empy.FirstName, ' ', empy.LastName) as ConfirmedBy, sl.ControlNumber, sl.IdNumber, sopt.ConfirmedDate, 
		sl.StockLineId, sopt.IsConfirmed 
		FROM SOPickTicket sopt WITH(NOLOCK)
		INNER JOIN SalesOrderPartV1 sop WITH(NOLOCK) on sop.SalesOrderId = sopt.SalesOrderId  AND sop.SalesOrderPartId = sopt.SalesOrderPartId
		LEFT JOIN SalesOrderStocklineV1 stk WITH(NOLOCK) on stk.SalesOrderPartId = sopt.SalesOrderPartId
		LEFT JOIN StockLine sl WITH(NOLOCK) on sl.StockLineId = stk.StockLineId
		INNER JOIN Employee emp WITH(NOLOCK) on emp.EmployeeId = sopt.PickedById
		LEFT JOIN Employee empy WITH(NOLOCK) on empy.EmployeeId = sopt.ConfirmedById
		WHERE sopt.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @ItemMasterId and sop.ConditionId = @ConditionId
	
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetPickTicketChildList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''',
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