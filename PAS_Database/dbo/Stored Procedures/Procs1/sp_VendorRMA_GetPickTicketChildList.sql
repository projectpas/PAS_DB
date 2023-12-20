/*************************************************************           
 ** File:   [sp_VendorRMA_GetPickTicketChildList]           
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to retrieve pickticket listing data for Vendor RMA STK details
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    06/19/2023   Amit Ghediya  Created
     
-- EXEC [dbo].[sp_VendorRMA_GetPickTicketChildList] 478
**************************************************************/
CREATE      Procedure [dbo].[sp_VendorRMA_GetPickTicketChildList]
	@VendorRMAId  bigint,
	@VendorRMADetailId  bigint,
	@ItemMasterId bigint,
	@ConditionId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

		SELECT sopt.RMAPickTicketNumber, sopt.QtyToShip, sl.SerialNumber, sl.StockLineNumber, sopt.CreatedDate as PickedDate,
		CONCAT(emp.FirstName, ' ', emp.LastName) as PickedBy, sopt.RMAPickTicketId, sopt.VendorRMAId, sopt.VendorRMADetailId,
		CONCAT(empy.FirstName, ' ', empy.LastName) as ConfirmedBy, sl.ControlNumber, sl.IdNumber, sopt.ConfirmedDate, 
		sl.StockLineId, sopt.IsConfirmed 
		FROM RMAPickTicket sopt WITH(NOLOCK)
		INNER JOIN VendorRMADetail sop WITH(NOLOCK) on sop.VendorRMAId = sopt.VendorRMAId AND sop.VendorRMADetailId = sopt.VendorRMADetailId
		LEFT JOIN StockLine sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		INNER JOIN Employee emp WITH(NOLOCK) on emp.EmployeeId = sopt.PickedById
		LEFT JOIN Employee empy WITH(NOLOCK) on empy.EmployeeId = sopt.ConfirmedById
		WHERE sopt.VendorRMAId = @VendorRMAId AND sopt.VendorRMADetailId = @VendorRMADetailId AND sop.ItemMasterId = @ItemMasterId and sl.ConditionId = @ConditionId
	
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_VendorRMA_GetPickTicketChildList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''',
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