
/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <03/18/2021>  
** Description: <Save WorkOrder Materials Details from Workflow & Work Order>  
  
Exec [usp_SaveWorkOrderMaterials] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    03/18/2021  Hemant Saliya    Save WorkOrder Materials Details from Workflow & Work Order

DROP PROCEDURE [dbo].[usp_SaveWorkOrderMaterials]

declare @p1 dbo.WorkOrderMaterialListType
insert into @p1 values(67,109,5,N'33',1,11.00,11.00,122,N'123444ss2',7)

exec dbo.usp_SaveWorkOrderMaterials @tbl_WorkOrderMaterialListType=@p1,@CreatedDate='2021-03-18 18:12:44.610',@UpdatedDate='2021-03-18 18:12:44.857',@CreatedBy=N'Roger',@UpdatedBy=N'Roger',@MasterCompanyId=1,@WorkOrderNumber=N'ACC109'

**************************************************************/ 
CREATE PROCEDURE [dbo].[usp_SaveWorkOrderMaterials]
	@tbl_WorkOrderMaterialListType WorkOrderMaterialListType READONLY,
	@CreatedBy VARCHAR(30),
	@UpdatedBy VARCHAR(30),
	@CreatedDate DATETIME2, 
	@UpdatedDate DATETIME2,
	@MasterCompanyId INT,
	@WorkOrderId BIGINT,
	@WorkFlowWorkOrderId BIGINT
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
				
					-- CASE 1 WORKFLOW MATERIALS LIST
					IF((SELECT COUNT(WorkOrderId) FROM @tbl_WorkOrderMaterialListType) > 0 )
					BEGIN
						MERGE dbo.WorkOrderMaterials AS TARGET
						USING @tbl_WorkOrderMaterialListType AS SOURCE ON (TARGET.WorkOrderId = @WorkOrderId AND TARGET.WorkOrderMaterialsId = SOURCE.WorkOrderMaterialsId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 			
							THEN UPDATE 						
							SET TARGET.WorkOrderId = SOURCE.WorkOrderId,
								TARGET.WorkFlowWorkOrderId = @WorkFlowWorkOrderId,
								TARGET.ItemMasterId = SOURCE.ItemMasterId,	
								TARGET.TaskId = SOURCE.TaskId,
								TARGET.ConditionCodeId = SOURCE.ConditionCodeId,
								TARGET.ItemClassificationId = SOURCE.ItemClassificationId,								
								TARGET.Quantity = SOURCE.Quantity,
								TARGET.UnitOfMeasureId = SOURCE.UnitOfMeasureId,								
								TARGET.UnitCost = SOURCE.UnitCost,
								TARGET.ExtendedCost = SOURCE.ExtendedCost,		
								TARGET.Memo = SOURCE.Memo,
								TARGET.IsDeferred = SOURCE.IsDeferred,	
								TARGET.QuantityReserved = SOURCE.QuantityReserved,
								TARGET.QuantityIssued = SOURCE.QuantityIssued,
								TARGET.IssuedById = SOURCE.IssuedById,
								TARGET.IssuedDate = SOURCE.IssuedDate,
								TARGET.ReservedById = SOURCE.ReservedById,
								TARGET.ReservedDate = SOURCE.ReservedDate,
								TARGET.IsAltPart = SOURCE.IsAltPart,
								TARGET.AltPartMasterPartId = SOURCE.AltPartMasterPartId,
								TARGET.PartStatusId = SOURCE.PartStatusId,
								TARGET.UnReservedQty = SOURCE.UnReservedQty,
								TARGET.UnIssuedQty = SOURCE.UnIssuedQty,
								TARGET.ParentWorkOrderMaterialsId = SOURCE.ParentWorkOrderMaterialsId,
								TARGET.ItemMappingId = SOURCE.ItemMappingId,
								TARGET.TotalReserved = SOURCE.TotalReserved,
								TARGET.TotalIssued = SOURCE.TotalIssued,
								TARGET.TotalUnReserved = SOURCE.TotalUnReserved,
								TARGET.TotalUnIssued = SOURCE.TotalUnIssued,
								TARGET.ProvisionId = SOURCE.ProvisionId,
								TARGET.MaterialMandatoriesId = SOURCE.MaterialMandatoriesId,
								TARGET.IsFromWorkFlow = SOURCE.IsFromWorkFlow,
								TARGET.IsEquPart = SOURCE.IsEquPart,
								TARGET.MasterCompanyId = @MasterCompanyId,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy,
								TARGET.IsDeleted = SOURCE.IsDeleted
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (WorkOrderId,WorkFlowWorkOrderId, ItemMasterId, TaskId, ConditionCodeId, ItemClassificationId,  Quantity, UnitOfMeasureId,UnitCost,ExtendedCost,
										Memo,IsDeferred, QuantityReserved, QuantityIssued, IssuedById, IssuedDate, ReservedById, ReservedDate, IsAltPart, AltPartMasterPartId, PartStatusId, UnReservedQty, UnIssuedQty, 
										ParentWorkOrderMaterialsId, ItemMappingId, TotalReserved, TotalIssued, TotalUnReserved, TotalUnIssued, IsFromWorkFlow, IsEquPart,
										MaterialMandatoriesId,ProvisionId,CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							VALUES (SOURCE.WorkOrderId, @WorkFlowWorkOrderId, SOURCE.ItemMasterId, SOURCE.TaskId,SOURCE.ConditionCodeId, SOURCE.ItemClassificationId, SOURCE.Quantity, SOURCE.UnitOfMeasureId,
									SOURCE.UnitCost,SOURCE.ExtendedCost,SOURCE.Memo, SOURCE.IsDeferred, SOURCE.QuantityReserved, SOURCE.QuantityIssued, SOURCE.IssuedById, SOURCE.IssuedDate, 
									SOURCE.ReservedById, SOURCE.ReservedDate, SOURCE.IsAltPart, SOURCE.AltPartMasterPartId, SOURCE.PartStatusId, SOURCE.UnReservedQty,SOURCE. UnIssuedQty, 
									SOURCE.ParentWorkOrderMaterialsId, SOURCE.ItemMappingId, SOURCE.TotalReserved, SOURCE.TotalIssued, SOURCE.TotalUnReserved, SOURCE.TotalUnIssued, 
									SOURCE.IsFromWorkFlow, SOURCE.IsEquPart, SOURCE.MaterialMandatoriesId,SOURCE.ProvisionId,@CreatedDate, @CreatedBy, @UpdatedDate, @UpdatedBy, @MasterCompanyId, 1, 0);
						--WHEN NOT MATCHED BY SOURCE
						--THEN UPDATE SET 
						--		TARGET.IsDeleted = 1,
						--		TARGET.UpdatedDate = GETDATE(),
						--		TARGET.UpdatedBy = @UpdatedBy;

						--DELETE WorkOrderMaterials FROM dbo.WorkOrderMaterials wom JOIN @tbl_WorkOrderMaterialListType tblwo
						--		ON wom.WorkOrderId =  tblwo.WorkOrderId 
						--			WHERE wom.IsDeleted = 1 

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
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveWorkOrderMaterials' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''', 
													   @Parameter2 = ' + ISNULL(@WorkFlowWorkOrderId ,'') +'''
													   @Parameter3 = ' + ISNULL(@MasterCompanyId ,'') +'''
													   @Parameter4 = ' + ISNULL(@CreatedBy ,'') +'''
													   @Parameter5 = ' + ISNULL(@UpdatedBy ,'') +'''
													   @Parameter6 = ' + ISNULL(CAST(@CreatedDate AS varchar(20)) ,'') +'''
													   @Parameter7 = ' + ISNULL(CAST(@UpdatedDate AS varchar(20)) ,'') +''
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