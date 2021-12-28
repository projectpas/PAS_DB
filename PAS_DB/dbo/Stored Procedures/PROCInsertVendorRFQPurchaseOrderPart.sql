

CREATE PROCEDURE [dbo].[PROCInsertVendorRFQPurchaseOrderPart](@TableVendorRFQPurchaseOrderPart VendorRFQPurchaseOrderPartType READONLY)  
AS  
BEGIN  
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					IF((SELECT COUNT(VendorRFQPurchaseOrderId) FROM @TableVendorRFQPurchaseOrderPart) > 0 )
					BEGIN
						DECLARE @VendorRFAPOId AS bigint
						SET @VendorRFAPOId = (SELECT TOP 1 VendorRFQPurchaseOrderId FROM @TableVendorRFQPurchaseOrderPart);
						MERGE dbo.VendorRFQPurchaseOrderPart AS TARGET
						USING @TableVendorRFQPurchaseOrderPart AS SOURCE ON (TARGET.VendorRFQPurchaseOrderId = SOURCE.VendorRFQPurchaseOrderId AND 
					  													     TARGET.VendorRFQPOPartRecordId = SOURCE.VendorRFQPOPartRecordId) 
						WHEN MATCHED 
						THEN UPDATE 
						SET TARGET.[ItemMasterId] = SOURCE.ItemMasterId,
						TARGET.[ManufacturerId] = SOURCE.ManufacturerId,
						TARGET.[PriorityId] = SOURCE.PriorityId,
						TARGET.[NeedByDate] = SOURCE.NeedByDate,
						TARGET.[PromisedDate] = SOURCE.PromisedDate,
						TARGET.[ConditionId] = SOURCE.ConditionId,
						TARGET.[QuantityOrdered] = SOURCE.QuantityOrdered,
						TARGET.[UnitCost] = SOURCE.UnitCost,
						TARGET.[ExtendedCost] = SOURCE.ExtendedCost,
						TARGET.[WorkOrderId] = SOURCE.WorkOrderId,
						TARGET.[SubWorkOrderId] = SOURCE.SubWorkOrderId,
						TARGET.[SalesOrderId] = SOURCE.SalesOrderId,
						TARGET.[ManagementStructureId] = SOURCE.ManagementStructureId,
						TARGET.[Memo] = SOURCE.Memo,
						TARGET.[UpdatedBy] = SOURCE.UpdatedBy,
						TARGET.[UpdatedDate] = SOURCE.UpdatedDate,
						TARGET.[IsActive] = SOURCE.IsActive,
						TARGET.[IsDeleted] = SOURCE.IsDeleted

						WHEN NOT MATCHED BY TARGET
						THEN
							INSERT([VendorRFQPurchaseOrderId],[ItemMasterId],[PartNumber],[PartDescription],[StockType],
								   [ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[PromisedDate],
								   [ConditionId],[Condition],[QuantityOrdered],[UnitCost],[ExtendedCost],[WorkOrderId],
								   [WorkOrderNo],[SubWorkOrderId],[SubWorkOrderNo],[SalesOrderId],[SalesOrderNo],
								   [ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],
								   [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
							VALUES(SOURCE.VendorRFQPurchaseOrderId,SOURCE.ItemMasterId,SOURCE.PartNumber,SOURCE.PartDescription,SOURCE.StockType,
								   SOURCE.ManufacturerId,SOURCE.Manufacturer,SOURCE.PriorityId,SOURCE.Priority,SOURCE.NeedByDate,SOURCE.PromisedDate,
								   SOURCE.ConditionId,SOURCE.Condition,SOURCE.QuantityOrdered,SOURCE.UnitCost,SOURCE.ExtendedCost,SOURCE.WorkOrderId,
								   SOURCE.WorkOrderNo,SOURCE.SubWorkOrderId,SOURCE.SubWorkOrderNo,SOURCE.SalesOrderId,SOURCE.SalesOrderNo,
								   SOURCE.ManagementStructureId,SOURCE.Level1,SOURCE.Level2,SOURCE.Level3,SOURCE.Level4,SOURCE.Memo,SOURCE.MasterCompanyId,
								   SOURCE.CreatedBy,SOURCE.UpdatedBy,SOURCE.CreatedDate,SOURCE.UpdatedDate,SOURCE.IsActive,SOURCE.IsDeleted);
					
					  													     
					 
				   	     EXEC PROCUpdateVendorRFQPurchaseOrderDetail @VendorRFAPOId;									    
					END
					
				END
			COMMIT  TRANSACTION
		END TRY  
		BEGIN CATCH      
			IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'PROCInsertVendorRFQPurchaseOrderPart' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL('', '') + ''													   
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