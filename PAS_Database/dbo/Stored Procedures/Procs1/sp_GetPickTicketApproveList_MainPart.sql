/*************************************************************           
 ** File:   [sp_GetPickTicketApproveList_MainPart]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Get WO MPN List that are Ready to Pick.    
 ** Purpose: This stored procedure is used Get WO MPN List that are Ready to Pick.           
 ** Date:   07/13/2021        
          
 ** PARAMETERS:           
 @@WorkOrderId BIGINT
 @WorkOrderPartNumberId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/16/2021   Hemant Saliya		Created
    1    01/01/2024   Devendra Shekh	update for SerialNumber
     
--EXEC [sp_GetPickTicketApproveList_MainPart] 5,0
**************************************************************/

CREATE   Procedure [dbo].[sp_GetPickTicketApproveList_MainPart]
	@referenceId bigint,
	@wfwoId bigint
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
		BEGIN
			SELECT 
				wowf.WorkOrderPartNoId as OrderPartId, 
				wop.WorkOrderId as referenceId,
				CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
				CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription', 
				wop.Quantity as Qty,
				CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END AS 'SerialNumber', 
				sl.QuantityAvailable, 
				wo.WorkOrderNum as OrderNumber, 
				''  as OrderQuoteNumber
				,SUM(ISNULL(wopt.QtyToShip,0))as QtyToShip,
				CASE WHEN sl.isSerialized = 1 THEN (1 - SUM(ISNULL(wopt.QtyToShip,0))) 
				ELSE (wop.Quantity - SUM(ISNULL(wopt.QtyToShip,0))) END as QtyToPick,
				CASE WHEN wop.Quantity = SUM(wopt.QtyToShip) THEN 'Fulfilled'
				ELSE 'Fullfillng' END as [Status],
                CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE wop.ItemMasterId END As ItemMasterId,
				sl.ConditionId, (wop.Quantity - SUM(ISNULL(wopt.QtyToShip,0))) as ReadyToPick, 
				cr.[Name] as CustomerName, 
				cr.CustomerCode
			FROM dbo.WorkOrderWorkFlow wowf WITH (NOLOCK)
				INNER JOIN WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
				INNER JOIN ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
				LEFT JOIN StockLine sl WITH (NOLOCK) on sl.StockLineId = wop.StockLineId
				LEFT JOIN WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
				LEFT JOIN WOPickTicket wopt WITH (NOLOCK) on wopt.WorkorderId = wop.WorkOrderId and wopt.OrderPartId = wop.ID
				LEFT JOIN Customer cr WITH (NOLOCK) on cr.CustomerId = wo.CustomerId
			WHERE wowf.WorkOrderId = @referenceId AND wop.IsFinishGood = 1 --wowf.WorkFlowWorkOrderId = @wfwoId and wop.isLocked=1 AND 
				AND (wop.Quantity > 0 OR wopt.WorkFlowWorkOrderId IS NOT NULL)
			GROUP BY wowf.WorkOrderPartNoId,wop.WorkOrderId,imt.PartNumber,imt.PartDescription, wop.Quantity,sl.SerialNumber,
				sl.QuantityAvailable,wo.WorkOrderNum,wop.ItemMasterId,sl.ConditionId,cr.[Name],cr.CustomerCode,sl.isSerialized,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription,wop.RevisedSerialNumber;
				
		END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetPickTicketApproveList_MainPart' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@referenceId, '') + ''
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