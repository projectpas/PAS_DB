/*************************************************************             
 ** File:   [USP_GetWorkOrdMaterialsStocklineListForAddInKitMaterial]             
 ** Author:   Vishal Suthar  
 ** Description: This SP is Used to get Stockline list to add into KIT material      
 ** Purpose:           
 ** Date:   04/05/2023          
            
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author   Change Description              
 ** --   --------     -------   --------------------------------            
    1    04/05/2023   Vishal Suthar  Created  
       
 EXECUTE USP_GetDataFromVendorRFQPurchaseOrderPartReference 32,45
**************************************************************/   
Create   PROCEDURE [dbo].[USP_GetDataFromVendorRFQPurchaseOrderPartReference]
@VendorRFQPurchaseOrderId BIGINT,
@VendorRFQPOPartRecordId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
			--DECLARE @ModuleId INT = NULL;
			--SET @ModuleId = (SELECT ModuleId FROM  PurchaseOrderPartReference WHERE PurchaseOrderId = @PurchaseOrderId);
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			;WITH Result AS (
				SELECT DISTINCT POR.ReferenceId as RefId,VendorRFQPurchaseOrderPartReferenceId,POR.ModuleId, POR.Qty AS Qty,POR.RequestedQty,
							  CASE WHEN POR.ModuleId = 1 THEN 'Work Order'
							  WHEN POR.ModuleId = 5 THEN 'Sub Work Order'
									WHEN POR.ModuleId = 3 THEN 'Sales Order' ELSE NULL END AS ModuleName,
							   CASE WHEN POR.ModuleId = 1 THEN wo.WorkOrderNum 
									WHEN POR.ModuleId = 5 THEN sw.SubWorkOrderNo
									WHEN POR.ModuleId = 3 THEN so.SalesOrderNumber ELSE  NULL END AS ReferenceId,
									CASE WHEN POR.ModuleId = 5 THEN sw.WorkOrderId ELSE 0 END AS WorkOrderId  
									
				 

				FROM [VendorRFQPurchaseOrderPartReference] POR WITH (NOLOCK) 
				LEFT JOIN [DBO].[WorkOrder] wo WITH (NOLOCK) ON wo.WorkOrderId = POR.ReferenceId
				LEFT JOIN [DBO].[RepairOrder] ro WITH (NOLOCK) ON ro.RepairOrderId = POR.ReferenceId
				LEFT JOIN [DBO].[SalesOrder] so WITH (NOLOCK) ON so.SalesOrderId = POR.ReferenceId
				LEFT JOIN [DBO].[ExchangeSalesOrder] eso WITH (NOLOCK) ON eso.ExchangeSalesOrderId = POR.ReferenceId
				LEFT JOIN [DBO].[Lot] l WITH (NOLOCK) ON l.LotId = POR.ReferenceId
				LEFT JOIN [DBO].[SubWorkOrder] sw WITH (NOLOCK) ON sw.SubWorkOrderId = POR.ReferenceId
				WHERE POR.VendorRFQPurchaseOrderId = @VendorRFQPurchaseOrderId AND POR.VendorRFQPOPartRecordId = @VendorRFQPOPartRecordId)
			SELECT *, (SELECT SUM(QTY) FROM Result) AS TotalQty INTO #TempTblLot FROM  Result 
			   SELECT * FROM #TempTblLot
			--SELECT  SUM(POR.Qty) as TotalQty FROM [PurchaseOrderPartReference] POR  WITH (NOLOCK) WHERE POR.PurchaseOrderId = @PurchaseOrderId AND POR.PurchaseOrderPartId = @PurchaseOrderPartRecordId
				
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetDataFromVendorRFQPurchaseOrderPartReference' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRFQPurchaseOrderId, '') + ''
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