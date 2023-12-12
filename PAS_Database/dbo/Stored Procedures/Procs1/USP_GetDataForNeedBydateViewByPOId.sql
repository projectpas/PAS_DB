/*************************************************************             
 ** File:   [USP_GetDataForNeedBydateViewByPOId]             
 ** Author:   Shrey Chandegara
 ** Description: 
 ** Purpose:           
 ** Date:   02-11-2023         
            
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author   Change Description              
 ** --   --------     -------   --------------------------------            
    1   02-11-2023   Shrey Chandegara  Created  
       
 EXECUTE USP_GetDataForNeedBydateViewByPOId 1658
**************************************************************/   
Create   PROCEDURE [dbo].[USP_GetDataForNeedBydateViewByPOId]
@PurchaseOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
			
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			      ;WITH Result AS (
				SELECT DISTINCT POR.ReferenceId as RefId,PurchaseOrderPartReferenceId,POR.PurchaseOrderId,POR.PurchaseOrderPartId,POP.PartNumber,
							   CASE WHEN POR.ModuleId = 1 THEN wo.WorkOrderNum 
									WHEN POR.ModuleId = 3 THEN so.SalesOrderNumber
									WHEN POR.ModuleId = 4 THEN eso.ExchangeSalesOrderNumber 
									WHEN POR.ModuleId = 5 THEN sw.SubWorkOrderNo ELSE  NULL END AS ReferenceNum,
							   CASE WHEN POR.ModuleId = 1 THEN WOP.PromisedDate
									WHEN POR.ModuleId = 3 THEN SOP.PromisedDate 
									WHEN POR.ModuleId = 4 THEN ESP.PromisedDate
									WHEN POR.ModuleId = 5 THEN SWP.PromisedDate ELSE  NULL END AS 'PromisedDate',
							   CASE WHEN POR.ModuleId = 1 THEN WOP.EstimatedCompletionDate
									WHEN POR.ModuleId = 3 THEN SOP.EstimatedShipDate 
									WHEN POR.ModuleId = 4 THEN ESP.EstimatedShipDate
									WHEN POR.ModuleId = 5 THEN SWP.EstimatedCompletionDate ELSE  NULL END AS 'EstimatedCompletionDate',
							   CASE WHEN POR.ModuleId = 1 THEN WOP.EstimatedShipDate
									WHEN POR.ModuleId = 3 THEN SOP.EstimatedShipDate 
									WHEN POR.ModuleId = 4 THEN ESP.EstimatedShipDate
									WHEN POR.ModuleId = 5 THEN SWP.EstimatedShipDate ELSE  NULL END AS 'EstimatedShipDate'	
							  

				FROM [PurchaseOrderPartReference] POR WITH (NOLOCK) 
				LEFT JOIN [DBO].[WorkOrder] wo WITH (NOLOCK) ON wo.WorkOrderId = POR.ReferenceId
				LEFT JOIN [DBO].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOP.WorkOrderId = wo.WorkOrderId
				LEFT JOIN [DBO].[RepairOrder] ro WITH (NOLOCK) ON ro.RepairOrderId = POR.ReferenceId
				LEFT JOIN [DBO].[SalesOrder] so WITH (NOLOCK) ON so.SalesOrderId = POR.ReferenceId
				LEFT JOIN [DBO].[SalesOrderPart] SOP WITH (NOLOCK) ON SOP.SalesOrderId = so.SalesOrderId
				LEFT JOIN [DBO].[ExchangeSalesOrder] eso WITH (NOLOCK) ON eso.ExchangeSalesOrderId =  eso.ExchangeSalesOrderId
				LEFT JOIN [DBO].[ExchangeSalesOrderPart] ESP WITH (NOLOCK) ON ESP.ExchangeSalesOrderId = POR.ReferenceId
				LEFT JOIN [DBO].[Lot] l WITH (NOLOCK) ON l.LotId = POR.ReferenceId
				LEFT JOIN [DBO].[SubWorkOrder] sw WITH (NOLOCK) ON sw.SubWorkOrderId = POR.ReferenceId
				LEFT JOIN [DBO].[SubWorkOrderPartNumber] SWP WITH (NOLOCK) ON SWP.SubWorkOrderId = sw.SubWorkOrderId 
				LEFT JOIN [DBO].[PurchaseOrderPart] POP WITH (NOLOCK) ON POP.PurchaseOrderPartRecordId = POR.PurchaseOrderPartId
				WHERE POR.PurchaseOrderId = @PurchaseOrderId )
			SELECT * FROM  Result 
						 
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetDataForNeedBydateViewByPOId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END