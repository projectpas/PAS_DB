/*************************************************************           
 ** File:   [sp_GetWOShippingParentList]           
 ** Author:   Subhash Saliya
 ** Description: Get  for Work order Shipping List    
 ** Purpose:         
 ** Date:   23-Feb-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    06/25/2020   Hemant  Saliya Added Transation & Content Management
    2    02/23/2021   Subhash Saliya Created
	3    07/16/2024   Devendra Shekh Added Case For Status
	4    07/28/2025   Moin Bloch     Added Condition For Enforce Mpn Pick Ticket Confirmation
  	5    05/JUNE/2026 Rajesh Gami	 Skip the IsFinishGood = 1 condition when the Work Order type is Teardown.[PN-16719]        
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	7    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
 EXECUTE [sp_GetWOShippingParentList] 19769, 39
**************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[sp_GetWOShippingParentList]
@WorkOrderId  bigint,
@WorkOrderPartId bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		  BEGIN TRANSACTION
			BEGIN
			   
				DECLARE @EnforceMpnPickTicketConfirmation BIT
				DECLARE @IsTearDownWO BIT = 0,@WorkOrderTypeId INT, @TearDownWOTypeId INT = (SELECT TOP 1 ID FROM dbo.WorkOrderType WHERE Description = 'Internal Teardown');
				SELECT TOP 1 @WorkOrderTypeId = [WorkOrderTypeId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
				SET @IsTearDownWO = CASE WHEN @WorkOrderTypeId = @TearDownWOTypeId THEN 1 ELSE 0 END

				SELECT @EnforceMpnPickTicketConfirmation = ISNULL(wo.[EnforceMpnPickTicketConfirmation],0)
				FROM [dbo].[WorkOrder] wo WITH(NOLOCK) WHERE wo.[WorkOrderId] = @WorkOrderId 

				SELECT 
					wo.WorkOrderNum,
					CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
			        CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription', 
					SUM(ISNULL(wopt.QtyToShip, 0)) as QtyToShip,
					SUM(ISNULL(wosi.QtyShipped, 0)) as QtyShipped,
					wop.WorkOrderId,
					wop.ID as WorkOrderPartId,
					SUM(ISNULL(wopt.QtyToShip, 0)) - SUM(ISNULL(wosi.QtyShipped,0)) as QtyRemaining,
					--CASE WHEN SUM(ISNULL(wopt.QtyToShip, 0)) = SUM(ISNULL(wosi.QtyShipped, 0)) THEN 'Fullfilled' ELSE 'Fullfilling' END as [Status], 
					CASE WHEN SS.[Status] IS NULL THEN 'Ready' ELSE SS.[Status] END As [Status],
					1 as ItemNo,
					ISNULL(cds.ShipViaId,0) AS ShipViaId
				FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)
					LEFT JOIN DBO.WorkOrder wo  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId
					INNER JOIN DBO.WOPickTicket wopt  WITH(NOLOCK) ON wopt.WorkorderId = wop.WorkorderId  AND wopt.OrderPartId = wop.ID
					LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) ON imt.ItemMasterId = wop.ItemMasterId
					 AND ISNULL(imt.IsNonStock,0) = 0
					 LEFT JOIN DBO.Stockline sl WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
					LEFT JOIN DBO.CustomerDomensticShipping CDSD WITH(NOLOCK) ON CDSD.CustomerId = wo.CustomerId and CDSD.IsPrimary=1
					LEFT JOIN DBO.CustomerDomensticShippingShipVia cds WITH(NOLOCK) ON CDSD.CustomerDomensticShippingId = cds.CustomerDomensticShippingId and cds.IsPrimary=1					
					LEFT JOIN DBO.WorkOrderShippingItem wosi  WITH(NOLOCK) ON wosi.WorkOrderPartNumId = wop.ID AND wosi.WOPickTicketId = wopt.PickTicketId
					LEFT JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) ON wos.WorkOrderShippingId = wosi.WorkOrderShippingId and wos.WorkOrderId = wo.WorkOrderId
					LEFT JOIN DBO.ShippingStatus SS WITH(NOLOCK) ON wos.WOShippingStatusId = SS.ShippingStatusId
				WHERE wop.[WorkOrderId] = @WorkOrderId 
				--AND wopt.IsConfirmed = 1
				AND (@IsTearDownWO = 1 OR wop.[IsFinishGood] = 1) --and wop.ID=@WorkOrderPartId
				AND (
				   @EnforceMpnPickTicketConfirmation = 0 
				   OR wopt.[IsConfirmed] = 1                 
			    )
				GROUP BY wo.WorkOrderNum,imt.partnumber,imt.PartDescription,cds.ShipViaId,wop.WorkOrderId,wop.ID,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription, SS.[Status];
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetWOShippingParentList' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH

END