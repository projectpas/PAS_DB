
/*************************************************************           
 ** File:   [GetWOPackagingLabelPrint]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve WO packaging Label Print Details    
 ** Purpose:         
 ** Date:   12/30/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/23/2020   Hemant Saliya Created
     
--EXEC [GetWOPackagingLabelPrint] 6
**************************************************************/

CREATE PROCEDURE [dbo].[GetWOPackagingLabelPrint]
	@WorkOrderId bigint,
	@PackagingSlipId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				SELECT  WPB.PackagingSlipId, 
						WPB.PackagingSlipNo, 
						wopt.WorkorderId, 
						wopt.PickTicketNumber,
						wopt.QtyToShip as QtyPicked, 
						wop.Quantity, 
						imt.partnumber as PartNumber,
						imt.PartDescription, 
						sl.StockLineNumber, 
						sl.SerialNumber, 
						sl.ControlNumber, 
						sl.IdNumber, 
						sl.Condition as ConditionDescription,
						sl.UnitOfMeasure as UOM, 
						wo.WorkOrderNum,
						(SELECT QtyShipped FROM DBO.WorkOrderShippingItem WOSI WITH (NOLOCK) Where WOSI.WorkOrderPartNumId = wopt.OrderPartId AND wopt.PickTicketId = WOSI.WOPickTicketId) AS QtyShipped
				FROM WOPickTicket wopt WITH (NOLOCK)
					LEFT JOIN DBO.WorkOrderPackaginSlipItems WPI WITH (NOLOCK) ON wopt.PickTicketId = WPI.WOPickTicketId AND WPI.WOPartNoId = wopt.OrderPartId
					LEFT JOIN DBO.WorkOrderPackaginSlipHeader WPB WITH (NOLOCK) ON WPB.PackagingSlipId = WPI.PackagingSlipId
					LEFT JOIN DBO.WorkOrderShippingItem WSI WITH (NOLOCK) ON WSI.WOPickTicketId = wopt.PickTicketId
					INNER JOIN WorkOrderPartNumber wop WITH (NOLOCK) on wop.WorkOrderId = wopt.WorkOrderId AND wop.ID = wopt.OrderPartId
					JOIN WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
					JOIN Stockline sl WITH (NOLOCK) on sl.StockLineId = wop.StockLineId
					JOIN ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
					LEFT JOIN DBO.WorkOrderShippingItem WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = wopt.OrderPartId AND wopt.PickTicketId = WOSI.WOPickTicketId
					LEFT JOIN DBO.WorkOrderShipping WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId AND WOS.WorkOrderId = @WorkOrderId
				WHERE WPI.PackagingSlipId = @PackagingSlipId AND WPB.WorkOrderId = @WorkOrderId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWOPackagingLabelPrint' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''',
													   @Parameter2 = ' + ISNULL(@PackagingSlipId ,'') +''
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