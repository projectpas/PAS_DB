
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

CREATE PROCEDURE [dbo].[GetWorkOrderPartlistFormData]
@WorkorderId bigint,
@workOrderPartNoId bigint
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
						wop.Quantity, 
						woq.QuoteNumber,
						woq.OpenDate as qouteDate,
						'1' as NoofItem,
						'' as page,
						wo.CreatedBy as Preparedby,
						getdate() as DatePrinted,
						wo.CreatedDate as workreqDate,
						wop.ManagementStructureId,
						wop.WorkflowId as WorkFlowWorkOrderId,
						imt.partnumber as partnumber,
						imt.PartDescription as PartDescription,
						wo.WorkOrderNum,
						wo.UpdatedDate
				FROM WorkOrder wo WITH (NOLOCK)
					INNER JOIN WorkOrderPartNumber wop WITH (NOLOCK) on wop.WorkOrderId = wo.WorkOrderId 
					LEFT JOIN WorkOrderQuote woq WITH (NOLOCK) on wo.WorkOrderId = woq.WorkOrderId and woq.IsVersionIncrease=0
					LEFT JOIN ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
				WHERE wo.WorkOrderId = @WorkorderId AND wop.ID = @workOrderPartNoId
		END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderPartlistFormData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter2 = ' + ISNULL(@workOrderPartNoId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        = @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END