/*************************************************************             
 ** File:   [PROCInsertVendorRFQPurchaseOrderPart]             
 ** Author:   
 ** Description: This stored procedure is used to PROCInsertVendorRFQPurchaseOrderPart
 ** Purpose:           
 ** Date:  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    01/12/2023   Amit Ghediya     Modify(Added Traceable & Tagged fields)
	2	 23/09/2025	  Amit Ghediya	   Update VendorRFQ refrence
	3    08/12/2025   Ayushi Patel	   Modify(Added SalesOrderQuoteId,SalesOrderQuoteNumber fields)
**************************************************************/ 
CREATE  PROCEDURE [dbo].[PROCInsertVendorRFQPurchaseOrderPart](@TableVendorRFQPurchaseOrderPart VendorRFQPurchaseOrderPartType READONLY)  
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
						TARGET.[IsDeleted] = SOURCE.IsDeleted,
						TARGET.[UOMId] = SOURCE.UOMId,
						TARGET.[TraceableTo] = SOURCE.TraceableTo,
						TARGET.[TraceableToName] = SOURCE.TraceableToName,
						TARGET.[TraceableToType] = SOURCE.TraceableToType,
						TARGET.[TagTypeId] = SOURCE.TagTypeId,
						TARGET.[TaggedByType] = SOURCE.TaggedByType,
						TARGET.[TaggedBy] = SOURCE.TaggedBy,
						TARGET.[TaggedByName] = SOURCE.TaggedByName,
						TARGET.[TaggedByTypeName] = SOURCE.TaggedByTypeName,
						TARGET.[TagDate] = SOURCE.TagDate,
						TARGET.[IsNoQuote] = SOURCE.IsNoQuote,
						TARGET.[SalesOrderQuoteId] = SOURCE.SalesOrderQuoteId,
						TARGET.[SalesOrderQuoteNumber] = SOURCE.SalesOrderQuoteNumber
						WHEN NOT MATCHED BY TARGET
						THEN
							INSERT([VendorRFQPurchaseOrderId],[ItemMasterId],[PartNumber],[PartDescription],[StockType],
								   [ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[PromisedDate],
								   [ConditionId],[Condition],[QuantityOrdered],[UnitCost],[ExtendedCost],[WorkOrderId],
								   [WorkOrderNo],[SubWorkOrderId],[SubWorkOrderNo],[SalesOrderId],[SalesOrderNo],
								   [ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],
								   [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[UOMId],
								   [TraceableTo],[TraceableToName],[TraceableToType],
								   [TagTypeId]
								   ,[TaggedByType]
								   ,[TaggedBy]
								   ,[TaggedByName]
								   ,[TaggedByTypeName],[TagDate],[IsNoQuote],[SalesOrderQuoteId], [SalesOrderQuoteNumber]
								   )
							VALUES(SOURCE.VendorRFQPurchaseOrderId,SOURCE.ItemMasterId,SOURCE.PartNumber,SOURCE.PartDescription,SOURCE.StockType,
								   SOURCE.ManufacturerId,SOURCE.Manufacturer,SOURCE.PriorityId,SOURCE.Priority,SOURCE.NeedByDate,SOURCE.PromisedDate,
								   SOURCE.ConditionId,SOURCE.Condition,SOURCE.QuantityOrdered,SOURCE.UnitCost,SOURCE.ExtendedCost,SOURCE.WorkOrderId,
								   SOURCE.WorkOrderNo,SOURCE.SubWorkOrderId,SOURCE.SubWorkOrderNo,SOURCE.SalesOrderId,SOURCE.SalesOrderNo,
								   SOURCE.ManagementStructureId,SOURCE.Level1,SOURCE.Level2,SOURCE.Level3,SOURCE.Level4,SOURCE.Memo,SOURCE.MasterCompanyId,
								   SOURCE.CreatedBy,SOURCE.UpdatedBy,SOURCE.CreatedDate,SOURCE.UpdatedDate,SOURCE.IsActive,SOURCE.IsDeleted,SOURCE.UOMId,
								   SOURCE.TraceableTo,SOURCE.TraceableToName,SOURCE.TraceableToType,
								   SOURCE.TagTypeId
								   ,SOURCE.TaggedByType
								   ,SOURCE.TaggedBy
								   ,SOURCE.TaggedByName
								   ,SOURCE.TaggedByTypeName,SOURCE.TagDate,SOURCE.IsNoQuote,SOURCE.SalesOrderQuoteId, SOURCE.SalesOrderQuoteNumber
								   );
					
					 
				   	        EXEC PROCUpdateVendorRFQPurchaseOrderDetail @VendorRFAPOId;			
					END

					--Update VendorRFQ
					DECLARE @TotalPartsCount int = 0,
							@PartLoopId int,
							@VendorRFQPurchaseOrderId BIGINT,
							@IsFromVendorRFQ BIGINT = 0;
					DECLARE @RFQModuleId BIGINT = 0;

					SELECT @RFQModuleId = ModuleId FROM dbo.[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPurchaseOrder';

					IF OBJECT_ID(N'tempdb..#tmpRFQPoPartList') IS NOT NULL    
					BEGIN    
						DROP TABLE #tmpRFQPoPartList
					END

					CREATE TABLE #tmpRFQPoPartList
					(
						ID BIGINT NOT NULL IDENTITY, 
						[VendorRFQPOPartRecordId] [bigint] NULL,
						[VendorRFQPurchaseOrderId] [bigint] NULL,
						[IsFromVendorRFQ] [bigint] NULL
					)

					INSERT INTO #tmpRFQPoPartList ([VendorRFQPOPartRecordId],[VendorRFQPurchaseOrderId]
																	,[IsFromVendorRFQ] )
					SELECT [VendorRFQPOPartRecordId],[VendorRFQPurchaseOrderId]
																	,[IsFromVendorRFQ]
					FROM @TableVendorRFQPurchaseOrderPart;
					
					SELECT  @PartLoopId = MAX(ID) FROM #tmpRFQPoPartList
					
					WHILE(@PartLoopId > 0)
					BEGIN 
						SELECT @VendorRFQPurchaseOrderId = VendorRFQPurchaseOrderId,@IsFromVendorRFQ = IsFromVendorRFQ
						FROM #tmpRFQPoPartList WHERE ID = @PartLoopId;
						
						IF(ISNULL(@VendorRFQPurchaseOrderId,0) > 0)
						BEGIN 
							 IF(ISNULL(@IsFromVendorRFQ,0) > 0)
							 BEGIN 
								  UPDATE dbo.[VendorRFQPart] SET ReferenceId = @VendorRFQPurchaseOrderId, ModuleId = @RFQModuleId WHERE [VendorRFQPartId] = @IsFromVendorRFQ;
							 END
						END

						SET @PartLoopId = @PartLoopId - 1;
					END
					
				END
			COMMIT  TRANSACTION
		END TRY  
		BEGIN CATCH    
			SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
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