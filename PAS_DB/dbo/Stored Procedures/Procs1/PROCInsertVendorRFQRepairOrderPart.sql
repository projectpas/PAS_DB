/*************************************************************             
 ** File:   [PROCInsertVendorRFQRepairOrderPart]             
 ** Author:   
 ** Description: This stored procedure is used to PROCInsertVendorRFQRepairOrderPart
 ** Purpose:           
 ** Date:  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    06/12/2023   Amit Ghediya     Modify(Added Traceable & Tagged fields)
	2    03-07-2024   Shrey Chandegara Modify(Add new Field [IsNoQuote])

**************************************************************/ 
CREATE     PROCEDURE [dbo].[PROCInsertVendorRFQRepairOrderPart](@TableVendorRFQRepairOrderPart VendorRFQRepairOrderPartType READONLY)  
AS  
BEGIN  
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					IF((SELECT COUNT(VendorRFQRepairOrderId) FROM @TableVendorRFQRepairOrderPart) > 0 )
					BEGIN
						DECLARE @VendorRFQROId AS bigint
						SET @VendorRFQROId = (SELECT TOP 1 VendorRFQRepairOrderId FROM @TableVendorRFQRepairOrderPart);
						MERGE dbo.VendorRFQRepairOrderPart AS TARGET
						USING @TableVendorRFQRepairOrderPart AS SOURCE ON (TARGET.VendorRFQRepairOrderId = SOURCE.VendorRFQRepairOrderId AND 
					  													     TARGET.VendorRFQROPartRecordId = SOURCE.VendorRFQROPartRecordId) 
						WHEN MATCHED 
						THEN UPDATE 
						SET TARGET.[ItemMasterId] = SOURCE.ItemMasterId,
						TARGET.[AltEquiPartNumberId] = SOURCE.AltEquiPartNumberId,
						TARGET.[RevisedPartId] = SOURCE.RevisedPartId,
						TARGET.[ManufacturerId] = SOURCE.ManufacturerId,
						TARGET.[PriorityId] = SOURCE.PriorityId,
						TARGET.[NeedByDate] = SOURCE.NeedByDate,
						TARGET.[PromisedDate] = SOURCE.PromisedDate,
						TARGET.[ConditionId] = SOURCE.ConditionId,
						TARGET.[WorkPerformedId] = SOURCE.WorkPerformedId,
						TARGET.[QuantityOrdered] = SOURCE.QuantityOrdered,
						TARGET.[UnitCost] = SOURCE.UnitCost,
						TARGET.[ExtendedCost] = SOURCE.ExtendedCost,
						TARGET.[WorkOrderId] = SOURCE.WorkOrderId,
						TARGET.[SubWorkOrderId] = SOURCE.SubWorkOrderId,
						TARGET.[SalesOrderId] = SOURCE.SalesOrderId,
						TARGET.[ItemTypeId] = SOURCE.ItemTypeId,
						TARGET.[UOMId] = SOURCE.UOMId,
						TARGET.[ManagementStructureId] = SOURCE.ManagementStructureId,
						TARGET.[Memo] = SOURCE.Memo,
						TARGET.[UpdatedBy] = SOURCE.UpdatedBy,
						TARGET.[UpdatedDate] = SOURCE.UpdatedDate,
						TARGET.[IsActive] = SOURCE.IsActive,
						TARGET.[IsDeleted] = SOURCE.IsDeleted,
						TARGET.[TraceableTo] = SOURCE.TraceableTo,
						TARGET.[TraceableToName] = SOURCE.TraceableToName,
						TARGET.[TraceableToType] = SOURCE.TraceableToType,
						TARGET.[TagTypeId] = SOURCE.TagTypeId,
						TARGET.[TaggedByType] = SOURCE.TaggedByType,
						TARGET.[TaggedBy] = SOURCE.TaggedBy,
						TARGET.[TaggedByName] = SOURCE.TaggedByName,
						TARGET.[TaggedByTypeName] = SOURCE.TaggedByTypeName,
						TARGET.[TagDate] = SOURCE.TagDate,
						TARGET.[IsNoQuote] = SOURCE.IsNoQuote

						WHEN NOT MATCHED BY TARGET
						THEN
						INSERT ([VendorRFQRepairOrderId],[ItemMasterId],[PartNumber],[PartDescription],[AltEquiPartNumberId],[AltEquiPartNumber],[AltEquiPartDescription]
                               ,[RevisedPartId],[RevisedPartNumber],[StockType],[ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[PromisedDate]
                               ,[ConditionId],[Condition],[WorkPerformedId],[WorkPerformed],[QuantityOrdered],[UnitCost],[ExtendedCost],[WorkOrderId],[WorkOrderNo]
                               ,[SubWorkOrderId],[SubWorkOrderNo],[SalesOrderId],[SalesOrderNo],[ItemTypeId],[ItemType],[UOMId],[UnitOfMeasure],[ManagementStructureId]
                               ,[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]
							   ,[TraceableTo],[TraceableToName],[TraceableToType],[TagTypeId]
							   ,[TaggedByType],[TaggedBy],[TaggedByName],[TaggedByTypeName],[TagDate],[IsNoQuote])
						VALUES (SOURCE.VendorRFQRepairOrderId,SOURCE.ItemMasterId,SOURCE.PartNumber,SOURCE.PartDescription,SOURCE.AltEquiPartNumberId,SOURCE.AltEquiPartNumber
                               ,SOURCE.AltEquiPartDescription,SOURCE.RevisedPartId,SOURCE.RevisedPartNumber,SOURCE.StockType,SOURCE.ManufacturerId,SOURCE.Manufacturer
                               ,SOURCE.PriorityId,SOURCE.Priority,SOURCE.NeedByDate,SOURCE.PromisedDate,SOURCE.ConditionId,SOURCE.Condition,SOURCE.WorkPerformedId
                               ,SOURCE.WorkPerformed,SOURCE.QuantityOrdered,SOURCE.UnitCost,SOURCE.ExtendedCost,SOURCE.WorkOrderId,SOURCE.WorkOrderNo,SOURCE.SubWorkOrderId
                               ,SOURCE.SubWorkOrderNo,SOURCE.SalesOrderId,SOURCE.SalesOrderNo,SOURCE.ItemTypeId,SOURCE.ItemType,SOURCE.UOMId,SOURCE.UnitOfMeasure
                               ,SOURCE.ManagementStructureId,SOURCE.Level1,SOURCE.Level2,SOURCE.Level3,SOURCE.Level4,SOURCE.Memo,SOURCE.MasterCompanyId
                               ,SOURCE.CreatedBy,SOURCE.UpdatedBy,SOURCE.CreatedDate,SOURCE.UpdatedDate,SOURCE.IsActive,SOURCE.IsDeleted
							   ,SOURCE.TraceableTo,SOURCE.TraceableToName,SOURCE.TraceableToType,SOURCE.TagTypeId
							   ,SOURCE.TaggedByType,SOURCE.TaggedBy,SOURCE.TaggedByName,SOURCE.TaggedByTypeName,SOURCE.TagDate,SOURCE.IsNoQuote);
							   
				   	     EXEC UpdateVendorRFQRepairOrderDetail @VendorRFQROId;									    
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
              , @AdhocComments     VARCHAR(150)    = 'PROCInsertVendorRFQRepairOrderPart' 
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