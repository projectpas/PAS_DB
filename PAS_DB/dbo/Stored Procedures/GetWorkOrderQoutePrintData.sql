
/*************************************************************           
 ** File:   [GetWorkOrderPrintPdfData]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Work order Print  Details    
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
    1    06/02/2020   Subhash Saliya Created
	2	 06/28/2021	  Hemant Saliya  Added Transation & Content Managment
     
--EXEC [GetWorkOrderPrintPdfData] 274,258
**************************************************************/

CREATE PROCEDURE [dbo].[GetWorkOrderQoutePrintData]
@WorkorderId bigint,
@workOrderPartNoId bigint,
@workflowWorkorderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				SELECT  wo.WorkOrderId, 
						wo.CustomerId, 
						wo.CustomerName, 
						c.CustomerCode as Customercode, 
						'' as QuoteMethod, 
						woq.QuoteNumber,
						wop.WorkflowId as WorkFlowWorkOrderId,
						imt.partnumber as partnumber,
						imt.PartDescription as PartDescription,
						wo.WorkOrderNum,
						MaterialCost,
					    MaterialBilling,
					    LaborCost,
					    LaborBilling,
					    ChargesCost,
					    ChargesBilling,
					    FreightCost,
					    FreightBilling,
                        LaborFlatBillingAmount,
                        MaterialFlatBillingAmount,
                        ChargesFlatBillingAmount,
                        FreightFlatBillingAmount,
						(LaborFlatBillingAmount+MaterialFlatBillingAmount+ChargesFlatBillingAmount+FreightFlatBillingAmount) as TotalAmountPN
				FROM DBO.WorkOrderQuoteDetails WQD  WITH(NOLOCK)
					INNER JOIN dbo.WorkOrderQuote woq WITH(NOLOCK) on WQD.WorkOrderQuoteId = woq.WorkOrderQuoteId
					LEFT JOIN dbo.WorkOrder wo WITH(NOLOCK) ON wo.WorkOrderId = woq.WorkOrderId
					INNER JOIN dbo.WorkOrderPartNumber wop WITH(NOLOCK) on wop.WorkOrderId = wo.WorkOrderId --AND wop.ID = wopt.OrderPartId
					LEFT JOIN dbo.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
					LEFT JOIN dbo.Customer c WITH(NOLOCK) on c.Customerid = wo.Customerid
				WHERE wo.WorkOrderId = @WorkorderId and WorkflowWorkOrderId = @workflowWorkorderId and WQD.IsVersionIncrease = 0 AND wop.ID = @workOrderPartNoId 
		END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderQoutePrintData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter2 = '''+ ISNULL(@workOrderPartNoId, '') + '''
													   @Parameter3 = ' + ISNULL(@workflowWorkorderId ,'') +''
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