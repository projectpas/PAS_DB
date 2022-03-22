﻿
/*************************************************************           
 ** File:   [GetSubWOMaterialsPickTicketApproveList]           
 ** Author:   Hemant Saliya
 ** Description: This SP is used Get Sub WO Pick Ticket Details    
 ** Purpose:         
 ** Date:   09/20/2021       
          
 ** PARAMETERS:           
@WorkOrderId BIGINT,
@SubworkOrderId BIGINT,
@SubworkOrderPartNoId BIGINT 
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/20/2021   Hemant Saliya Created
     
 EXECUTE GetSubWOMaterialsPickTicketApproveList 48,30,31

**************************************************************/ 
CREATE PROCEDURE [dbo].[GetSubWOMaterialsPickTicketApproveList]
@WorkOrderId BIGINT,
@SubworkOrderId BIGINT,
@SubworkOrderPartNoId BIGINT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				SELECT WOMS.* INTO #WOMStockline FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) JOIN dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId WHERE WOM.WorkOrderId = @workOrderId AND WOM.SubWorkOrderId = @SubworkOrderId AND WOM.SubWOPartNoId = @SubworkOrderPartNoId
				
				SELECT 
					wom.SubWorkOrderMaterialsId as OrderPartId, 
					wom.WorkOrderId as referenceId, 
					wom.SubWorkOrderId,
					wom.SubWOPartNoId,
					IM.PartNumber, 
					IM.PartDescription,
					wom.Quantity as Qty,
					wo.WorkOrderNum as OrderNumber, 
					''  as OrderQuoteNumber,
					wom.ItemMasterId, 
					wom.ConditionCodeId AS ConditionId,
					C.[Name] as CustomerName, 
					C.CustomerCode,
					(SELECT SUM(ISNULL(sl.QuantityAvailable, 0)) FROM #WOMStockline WMSL JOIN dbo.StockLine sl WITH (NOLOCK) ON WMSL.StockLineId = sl.StockLineId WHERE wom.SubWorkOrderMaterialsId = WMSL.SubWorkOrderMaterialsId) AS QuantityAvailable,
					CASE WHEN ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.SubWorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId), 0) = 0 THEN ISNULL(wom.Quantity, 0) ELSE
					(SELECT SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.SubWorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId) END AS QtyToShip,

					(ISNULL(wom.Quantity, 0) - ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.SubWorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId), 0)) AS QtyToPick,

					CASE WHEN ISNULL(wom.Quantity, 0) = ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.SubWorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId), 0) THEN 'Fulfilled'
					ELSE 'Fullfillng' END as [Status],

					(( ISNULL((Select SUM(ISNULL(wmsl.QtyReserved, 0)) FROM #WOMStockline wmsl WHERE wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId),0) 
					+ ISNULL((Select SUM(ISNULL(wmsl.QtyIssued, 0)) FROM #WOMStockline wmsl WHERE wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId),0)) 
					- ISNULL((Select SUM(ISNULL(wopt.QtyToShip,0)) FROM dbo.SubWorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId),0))  
					AS ReadyToPick
				FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)
					INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) on IM.ItemMasterId = WOM.ItemMasterId
					INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) on WO.WorkOrderId = WOM.WorkOrderId
					INNER JOIN dbo.Customer C WITH (NOLOCK) on C.CustomerId = WO.CustomerId
				WHERE WOM.WorkOrderId=@workOrderId AND WOM.SubWorkOrderId = @SubworkOrderId AND WOM.SubWOPartNoId = @SubworkOrderPartNoId AND (ISNULL(wom.QuantityReserved,0) + ISNULL(wom.QuantityIssued,0)) > 0  
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSubWOMaterialsPickTicketApproveList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workOrderId, '') + ''',
													   @Parameter2 = ' + ISNULL(@SubworkOrderId ,'') +''
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