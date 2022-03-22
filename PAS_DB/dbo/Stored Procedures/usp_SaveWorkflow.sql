
/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <03/18/2021>  
** Description: <Save Workflow Details from Workflow & Work Order>  
  
Exec [usp_SaveWorkflow] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    03/18/2021  Hemant Saliya    Save Workflow Details from Workflow & Work Order


DROP PROCEDURE [dbo].[usp_SaveWorkflow]

declare @p1 dbo.WorkflowChargesType
insert into @p1 values(67,109,5,N'33',1,11.00,11.00,122,N'123444ss2',7)
insert into @p1 values(72,109,6,N'55',5,20.00,100.00,318,N'Hemant',7)
insert into @p1 values(73,109,4,N'111',11,11.00,121.00,414,N'Hemant_02022021',7)
insert into @p1 values(74,109,2,N'121',12,12.00,144.00,95,N'TYRE123',7)
insert into @p1 values(0,109,9,N'Desc 13',13,130.00,1690.00,5,N'Bond Enterprisesp1',7)

exec dbo.usp_SaveWorkflow @tbl_WorkflowChargesType=@p1,@CreatedDate='2021-03-18 18:12:44.610',@UpdatedDate='2021-03-18 18:12:44.857',@CreatedBy=N'Roger',@UpdatedBy=N'Roger',@MasterCompanyId=1,@WorkOrderNumber=N'ACC109'


**************************************************************/ 
CREATE PROCEDURE [dbo].[usp_SaveWorkflow]
	@tbl_WorkflowChargesType WorkflowChargesType READONLY,
	@tbl_WorkflowDirectionsType WorkflowDirectionsType READONLY,
	@tbl_WorkflowEquipmentType WorkflowEquipmentType READONLY,
	@tbl_WorkflowExclusionsType WorkflowExclusionsType READONLY,
	@tbl_WorkflowExpertiseType WorkflowExpertiseType READONLY,
	@tbl_WorkflowMaterialListType WorkflowMaterialListType READONLY,
	@tbl_WorkflowMeasurementType WorkflowMeasurementType READONLY,
	@tbl_WorkflowPublicationType WorkflowPublicationType READONLY,
	@CreatedBy VARCHAR(30),
	@UpdatedBy VARCHAR(30),
	@CreatedDate DATETIME2, 
	@UpdatedDate DATETIME2,
	@MasterCompanyId INT,
	@WorkOrderNumber VARCHAR(30),
	@IsVersionIncrease bit,
	@Version VARCHAR(30)
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY

			BEGIN TRANSACTION
				BEGIN
					-- CASE 1 WORKFLOW CHARGE LIST
					IF((SELECT COUNT(WorkflowId) FROM @tbl_WorkflowChargesType) > 0 )
					BEGIN
						MERGE dbo.WorkflowChargesList AS TARGET
						USING @tbl_WorkflowChargesType AS SOURCE ON (TARGET.WorkflowId = SOURCE.WorkflowId AND TARGET.WorkflowChargesListId = SOURCE.WorkflowChargesListId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED AND SOURCE.WorkflowChargeTypeId = TARGET.WorkflowChargeTypeId 					
							THEN UPDATE 						
							SET TARGET.WorkflowId = SOURCE.WorkflowId,
								TARGET.WorkflowChargeTypeId = SOURCE.WorkflowChargeTypeId,
								TARGET.Description = SOURCE.Description,
								TARGET.Quantity = SOURCE.Quantity,
								TARGET.UnitCost = SOURCE.UnitCost,
								TARGET.ExtendedCost = SOURCE.ExtendedCost,
								TARGET.VendorName = SOURCE.VendorName,
								TARGET.VendorId = SOURCE.VendorId,
								TARGET.TaskId = SOURCE.TaskId,
								TARGET.MasterCompanyId = @MasterCompanyId,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy,
								TARGET.IsDeleted = SOURCE.IsDeleted
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (WorkflowId, WorkflowChargeTypeId, Description, Quantity, UnitCost, ExtendedCost, VendorName, VendorId, TaskId, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							VALUES (SOURCE.WorkflowId, SOURCE.WorkflowChargeTypeId, SOURCE.Description, SOURCE.Quantity, SOURCE.UnitCost, SOURCE.ExtendedCost, SOURCE.VendorName, SOURCE.VendorId, SOURCE.TaskId, @CreatedDate, @CreatedBy, @UpdatedDate, @UpdatedBy, @MasterCompanyId, 1, 0)
						WHEN NOT MATCHED BY SOURCE
						THEN UPDATE SET 
								TARGET.IsDeleted = 1,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy;

						DELETE WorkflowChargesList FROM dbo.WorkflowChargesList wfch JOIN @tbl_WorkflowChargesType tblwf
								ON wfch.WorkflowId =  tblwf.WorkflowId 
									WHERE wfch.IsDeleted = 1 

					END

					-- CASE 2 WORKFLOW DIRECTIONS LIST
					IF((SELECT COUNT(WorkflowId) FROM @tbl_WorkflowDirectionsType) > 0 )
					BEGIN
						MERGE dbo.WorkflowDirection AS TARGET
						USING @tbl_WorkflowDirectionsType AS SOURCE ON (TARGET.WorkflowId = SOURCE.WorkflowId AND TARGET.WorkflowDirectionId = SOURCE.WorkflowDirectionId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED  					
							THEN UPDATE 						
							SET TARGET.WorkflowId = SOURCE.WorkflowId,
								TARGET.Description = SOURCE.Description,
								TARGET.Action = SOURCE.Action,
								TARGET.Sequence = SOURCE.Sequence,
								TARGET.Memo = SOURCE.Memo,
								TARGET.TaskId = SOURCE.TaskId,
								TARGET.[Order] = SOURCE.[Order],
								TARGET.MasterCompanyId = @MasterCompanyId,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy,
								TARGET.IsDeleted = SOURCE.IsDeleted								
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (WorkflowId, [Action], [Description], [Sequence], Memo, TaskId, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted, [Order]) 
							VALUES (SOURCE.WorkflowId, SOURCE.Action, SOURCE.Description, SOURCE.Sequence, SOURCE.Memo, SOURCE.TaskId, @CreatedDate, @CreatedBy, @UpdatedDate, @UpdatedBy, @MasterCompanyId, 1, 0, SOURCE.[Order])
						WHEN NOT MATCHED BY SOURCE
						THEN UPDATE SET 
								TARGET.IsDeleted = 1,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy;

						DELETE WorkflowDirection FROM dbo.WorkflowDirection wfd JOIN @tbl_WorkflowDirectionsType tblwf
								ON wfd.WorkflowId =  tblwf.WorkflowId 
									WHERE wfd.IsDeleted = 1 

					END

					-- CASE 3 WORKFLOW EQUIPMENTS LIST
					IF((SELECT COUNT(WorkflowId) FROM @tbl_WorkflowEquipmentType) > 0 )
					BEGIN
						MERGE dbo.WorkflowEquipmentList AS TARGET
						USING @tbl_WorkflowEquipmentType AS SOURCE ON (TARGET.WorkflowId = SOURCE.WorkflowId AND TARGET.WorkflowEquipmentListId = SOURCE.WorkflowEquipmentListId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET TARGET.WorkflowId = SOURCE.WorkflowId,
								TARGET.AssetId = SOURCE.AssetId,
								TARGET.AssetTypeId = SOURCE.AssetTypeId,
								TARGET.AssetDescription = SOURCE.AssetDescription,
								TARGET.Quantity = SOURCE.Quantity,
								TARGET.PartNumber = SOURCE.PartNumber,
								TARGET.TaskId = SOURCE.TaskId,
								TARGET.[Order] = SOURCE.[Order],
								TARGET.MasterCompanyId = @MasterCompanyId,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy,
								TARGET.IsDeleted = SOURCE.IsDeleted
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (WorkflowId, AssetId, AssetTypeId, AssetDescription, Quantity, TaskId, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted, [Order]) 
							VALUES (SOURCE.WorkflowId, SOURCE.AssetId, SOURCE.AssetTypeId, SOURCE.AssetDescription, SOURCE.Quantity, SOURCE.TaskId, @CreatedDate, @CreatedBy, @UpdatedDate, @UpdatedBy, @MasterCompanyId, 1, 0, SOURCE.[Order])
						WHEN NOT MATCHED BY SOURCE
						THEN UPDATE SET 
								TARGET.IsDeleted = 1,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy;

						DELETE WorkflowEquipmentList FROM dbo.WorkflowEquipmentList wfe JOIN @tbl_WorkflowEquipmentType tblwf
								ON wfe.WorkflowId =  tblwf.WorkflowId 
									WHERE wfe.IsDeleted = 1 

					END

					-- CASE 4 WORKFLOW EXCLUSIONS LIST
					IF((SELECT COUNT(WorkflowId) FROM @tbl_WorkflowExclusionsType) > 0 )
					BEGIN
						MERGE dbo.WorkflowExclusion AS TARGET
						USING @tbl_WorkflowExclusionsType AS SOURCE ON (TARGET.WorkflowId = SOURCE.WorkflowId AND TARGET.WorkflowExclusionId = SOURCE.WorkflowExclusionId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET TARGET.WorkflowId = SOURCE.WorkflowId,
								TARGET.ItemMasterId = SOURCE.ItemMasterId,
								TARGET.UnitCost = SOURCE.UnitCost,
								TARGET.Quantity = SOURCE.Quantity,
								TARGET.ExtendedCost = SOURCE.ExtendedCost,
								TARGET.EstimtPercentOccurrance = SOURCE.EstimtPercentOccurrance,
								TARGET.Memo = SOURCE.Memo,
								TARGET.PartNumber = SOURCE.PartNumber,
								TARGET.PartDescription = SOURCE.PartDescription,
								TARGET.ItemClassificationId = SOURCE.ItemClassificationId,
								TARGET.TaskId = SOURCE.TaskId,
								TARGET.[Order] = SOURCE.[Order],
								TARGET.MasterCompanyId = @MasterCompanyId,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy,
								TARGET.IsDeleted = SOURCE.IsDeleted,
								TARGET.[ConditionId] = SOURCE.[ConditionId]
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT ([WorkflowId],[ItemMasterId],[UnitCost],[Quantity],[ExtendedCost],[EstimtPercentOccurrance],[Memo],[TaskId],[MasterCompanyId],[CreatedBy],
											[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartNumber],[PartDescription],[Order],[ConditionId],[ItemClassificationId]) 
							VALUES (SOURCE.[WorkflowId],SOURCE.[ItemMasterId],SOURCE.[UnitCost],SOURCE.[Quantity],SOURCE.[ExtendedCost],SOURCE.[EstimtPercentOccurrance],SOURCE.[Memo],SOURCE.[TaskId],
					   						@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,SOURCE.[PartNumber],SOURCE.[PartDescription],SOURCE.[Order],SOURCE.[ConditionId],SOURCE.[ItemClassificationId])
						WHEN NOT MATCHED BY SOURCE
						THEN UPDATE SET 
								TARGET.IsDeleted = 1,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy;

						DELETE WorkflowExclusion FROM dbo.WorkflowExclusion wfe JOIN @tbl_WorkflowExclusionsType tblwf
								ON wfe.WorkflowId =  tblwf.WorkflowId 
									WHERE wfe.IsDeleted = 1 

					END

					-- CASE 5 WORKFLOW EXPERTIZE LIST
					IF((SELECT COUNT(WorkflowId) FROM @tbl_WorkflowExpertiseType) > 0 )
					BEGIN
						MERGE dbo.WorkflowExpertiseList AS TARGET
						USING @tbl_WorkflowExpertiseType AS SOURCE ON (TARGET.WorkflowId = SOURCE.WorkflowId AND TARGET.[WorkflowExpertiseListId] = SOURCE.WorkflowExpertiseListId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET TARGET.WorkflowId = SOURCE.WorkflowId,
								TARGET.ExpertiseTypeId = SOURCE.ExpertiseTypeId,
								TARGET.EstimatedHours = SOURCE.EstimatedHours,
								TARGET.LaborDirectRate = SOURCE.LaborDirectRate,
								TARGET.DirectLaborRate = SOURCE.DirectLaborRate,
								TARGET.OverheadBurden = SOURCE.OverheadBurden,
								TARGET.OverheadCost = SOURCE.OverheadCost,
								TARGET.StandardRate = SOURCE.StandardRate,
								TARGET.LaborOverheadCost = SOURCE.LaborOverheadCost,
								TARGET.TaskId = SOURCE.TaskId,
								TARGET.[Order] = SOURCE.[Order],
								TARGET.MasterCompanyId = @MasterCompanyId,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy,
								TARGET.IsDeleted = SOURCE.IsDeleted
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT ([WorkflowId],ExpertiseTypeId,EstimatedHours,LaborDirectRate,DirectLaborRate,OverheadBurden,OverheadCost,StandardRate,LaborOverheadCost,[TaskId],
											[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Order]) 
							VALUES (SOURCE.[WorkflowId],SOURCE.[ExpertiseTypeId],SOURCE.[EstimatedHours],SOURCE.[LaborDirectRate],SOURCE.[DirectLaborRate],SOURCE.[OverheadBurden],SOURCE.[OverheadCost],
											SOURCE.StandardRate,SOURCE.LaborOverheadCost,SOURCE.[TaskId],@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,SOURCE.[Order])
						WHEN NOT MATCHED BY SOURCE
						THEN UPDATE SET 
								TARGET.IsDeleted = 1,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy;

						DELETE WorkflowExpertiseList FROM dbo.WorkflowExpertiseList wfe JOIN @tbl_WorkflowExpertiseType tblwf
								ON wfe.WorkflowId =  tblwf.WorkflowId 
									WHERE wfe.IsDeleted = 1 

					END

					-- CASE 6 WORKFLOW MATERIALS LIST
					IF((SELECT COUNT(WorkflowId) FROM @tbl_WorkflowMaterialListType) > 0 )
					BEGIN
						MERGE dbo.WorkflowMaterial AS TARGET
						USING @tbl_WorkflowMaterialListType AS SOURCE ON (TARGET.WorkflowId = SOURCE.WorkflowId AND TARGET.WorkflowMaterialListId = SOURCE.WorkflowMaterialListId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED AND SOURCE.WorkflowMaterialListId = TARGET.WorkflowMaterialListId 					
							THEN UPDATE 						
							SET TARGET.WorkflowId = SOURCE.WorkflowId,
								TARGET.ItemMasterId = SOURCE.ItemMasterId,
								TARGET.PartNumber = SOURCE.PartNumber,
								TARGET.PartDescription = SOURCE.PartDescription,
								TARGET.ItemClassificationId = SOURCE.ItemClassificationId,
								TARGET.TaskId = SOURCE.TaskId,
								TARGET.Quantity = SOURCE.Quantity,
								TARGET.UnitOfMeasureId = SOURCE.UnitOfMeasureId,
								TARGET.ConditionCodeId = SOURCE.ConditionCodeId,
								TARGET.UnitCost = SOURCE.UnitCost,
								TARGET.ExtendedCost = SOURCE.ExtendedCost,
								TARGET.Price = SOURCE.Price,
								TARGET.ExtendedPrice = SOURCE.ExtendedPrice,
								TARGET.MaterialMandatoriesName = SOURCE.MaterialMandatoriesName,
								TARGET.MaterialMandatoriesId = SOURCE.MaterialMandatoriesId,
								TARGET.ProvisionId = SOURCE.ProvisionId,
							    TARGET.IsDeferred = SOURCE.IsDeferred,
								TARGET.WorkflowActionId = SOURCE.WorkflowActionId,
								TARGET.Memo = SOURCE.Memo,
								TARGET.[Order] = SOURCE.[Order],

								TARGET.MasterCompanyId = @MasterCompanyId,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy,
								TARGET.IsDeleted = SOURCE.IsDeleted
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (WorkflowId, ItemMasterId, PartNumber, PartDescription, ItemClassificationId, TaskId, Quantity, UnitOfMeasureId,ConditionCodeId,UnitCost,ExtendedCost,Price,ExtendedPrice,MaterialMandatoriesName,MaterialMandatoriesId,ProvisionId,IsDeferred,WorkflowActionId,Memo,[Order], CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							VALUES (SOURCE.WorkflowId, SOURCE.ItemMasterId, SOURCE.PartNumber, SOURCE.PartDescription, SOURCE.ItemClassificationId, SOURCE.TaskId, SOURCE.Quantity, SOURCE.UnitOfMeasureId,SOURCE.ConditionCodeId,SOURCE.UnitCost,SOURCE.ExtendedCost,SOURCE.Price,SOURCE.ExtendedPrice,SOURCE.MaterialMandatoriesName,SOURCE.MaterialMandatoriesId,SOURCE.ProvisionId,SOURCE.IsDeferred,SOURCE.WorkflowActionId,SOURCE.Memo,SOURCE.[Order], @CreatedDate, @CreatedBy, @UpdatedDate, @UpdatedBy, @MasterCompanyId, 1, 0)
						WHEN NOT MATCHED BY SOURCE
						THEN UPDATE SET 
								TARGET.IsDeleted = 1,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy;

						DELETE WorkflowMaterial FROM dbo.WorkflowMaterial wfm JOIN @tbl_WorkflowMaterialListType tblwf
								ON wfm.WorkflowId =  tblwf.WorkflowId 
									WHERE wfm.IsDeleted = 1 

					END

					-- CASE 7 WORKFLOW MEASUREMENT LIST
					IF((SELECT COUNT(WorkflowId) FROM @tbl_WorkflowMeasurementType) > 0 )
					BEGIN
						MERGE dbo.WorkflowMeasurement AS TARGET
						USING @tbl_WorkflowMeasurementType AS SOURCE ON (TARGET.WorkflowId = SOURCE.WorkflowId AND TARGET.WorkflowMeasurementId = SOURCE.WorkflowMeasurementId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED AND SOURCE.WorkflowMeasurementId = TARGET.WorkflowMeasurementId 					
							THEN UPDATE 						
							SET TARGET.WorkflowId = SOURCE.WorkflowId,
								TARGET.ItemMasterId = SOURCE.ItemMasterId,
								TARGET.PartNumber = SOURCE.PartNumber,
								TARGET.PartDescription = SOURCE.PartDescription,
								TARGET.TaskId = SOURCE.TaskId,
								TARGET.Sequence = SOURCE.Sequence,
								TARGET.Stage = SOURCE.Stage,
								TARGET.Min = SOURCE.Min,
								TARGET.Max = SOURCE.Max,
								TARGET.Expected = SOURCE.Expected,
								TARGET.DiagramURL = SOURCE.DiagramURL,
								TARGET.Memo = SOURCE.Memo,
								TARGET.[Order] = SOURCE.[Order],
								TARGET.MasterCompanyId = @MasterCompanyId,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy,
								TARGET.IsDeleted = SOURCE.IsDeleted
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (WorkflowId, ItemMasterId, PartNumber, PartDescription, TaskId, Sequence, Stage,Min,Max,Expected,DiagramURL,Memo,[Order], CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							VALUES (SOURCE.WorkflowId, SOURCE.ItemMasterId, SOURCE.PartNumber, SOURCE.PartDescription, SOURCE.TaskId, SOURCE.Sequence, SOURCE.Stage,SOURCE.Min,SOURCE.Max,SOURCE.Expected,SOURCE.DiagramURL,SOURCE.Memo,SOURCE.[Order], @CreatedDate, @CreatedBy, @UpdatedDate, @UpdatedBy, @MasterCompanyId, 1, 0)
						WHEN NOT MATCHED BY SOURCE
						THEN UPDATE SET 
								TARGET.IsDeleted = 1,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy;

						DELETE WorkflowMeasurement FROM dbo.WorkflowMeasurement wfms JOIN @tbl_WorkflowMeasurementType tblwf
								ON wfms.WorkflowId =  tblwf.WorkflowId 
									WHERE wfms.IsDeleted = 1 

					END

					---- CASE 8 WORKFLOW PUBLICATION LIST
					IF((SELECT COUNT(WorkflowId) FROM @tbl_WorkflowPublicationType) > 0 )
					BEGIN
						MERGE dbo.WorkflowPublications AS TARGET
						USING @tbl_WorkflowPublicationType AS SOURCE ON (TARGET.WorkflowId = SOURCE.WorkflowId AND TARGET.WorkflowPublicationsId = SOURCE.WorkflowPublicationsId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED AND SOURCE.WorkflowPublicationsId = TARGET.WorkflowPublicationsId 					
							THEN UPDATE 						
							SET TARGET.WorkflowId = SOURCE.WorkflowId,
								TARGET.PublicationId = SOURCE.PublicationId,
								TARGET.PublicationDescription = SOURCE.PublicationDescription,
								TARGET.PublicationType = SOURCE.PublicationType,
								TARGET.Sequence = SOURCE.Sequence,
								TARGET.Source = SOURCE.Source,
								TARGET.AircraftManufacturer = SOURCE.AircraftManufacturer,
								TARGET.Model = SOURCE.Model,
								TARGET.Location = SOURCE.Location,
								TARGET.Revision = SOURCE.Revision,
								TARGET.RevisionDate = SOURCE.RevisionDate,
								TARGET.VerifiedBy = SOURCE.VerifiedBy,
								TARGET.VerifiedDate = SOURCE.VerifiedDate,
								TARGET.Status = SOURCE.Status,
								TARGET.Image = SOURCE.Image,
								TARGET.TaskId = SOURCE.TaskId,
								TARGET.[Order] = SOURCE.[Order],
								TARGET.MasterCompanyId = @MasterCompanyId,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy,
								TARGET.IsDeleted = SOURCE.IsDeleted
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (WorkflowId, PublicationId, PublicationDescription, PublicationType, Sequence, Source, AircraftManufacturer,Model,Location,Revision,RevisionDate,VerifiedBy,VerifiedDate,Status,Image,TaskId,[Order], CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							VALUES (SOURCE.WorkflowId, SOURCE.PublicationId, SOURCE.PublicationDescription, SOURCE.PublicationType, SOURCE.Sequence, SOURCE.Source, SOURCE.AircraftManufacturer,SOURCE.Model,SOURCE.Location,SOURCE.Revision,SOURCE.RevisionDate,SOURCE.VerifiedBy,SOURCE.VerifiedDate,SOURCE.Status,SOURCE.Image,SOURCE.TaskId,SOURCE.[Order], @CreatedDate, @CreatedBy, @UpdatedDate, @UpdatedBy, @MasterCompanyId, 1, 0)
						WHEN NOT MATCHED BY SOURCE
						THEN UPDATE SET 
								TARGET.IsDeleted = 1,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = @UpdatedBy;

						DELETE WorkflowPublications FROM dbo.WorkflowPublications wfp JOIN @tbl_WorkflowPublicationType tblwf
								ON wfp.WorkflowId =  tblwf.WorkflowId 
									WHERE wfp.IsDeleted = 1 
					END

					-- UPDATE WORK FLOW DETAILS COMMON
					UPDATE dbo.Workflow   						
							SET WorkOrderNumber = @WorkOrderNumber,
								IsActive = 1,
								MasterCompanyId = @MasterCompanyId,
								CreatedBy = @CreatedBy,
								CreatedDate = GETDATE(),
								UpdatedDate = GETDATE(),
								UpdatedBy = @UpdatedBy,
								[Version] = CASE WHEN @IsVersionIncrease = 1 THEN @Version ELSE [Version] END
							WHERE WorkOrderNumber = @WorkOrderNumber
				END

			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveWorkflow' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderNumber, '') + ''', 
													   @Parameter3 = ' + ISNULL(@Version,'') + ', 
													   @Parameter4 = ' + CAST(ISNULL(@CreatedDate,'') AS VARCHAR) + ', 
													   @Parameter5 = ' + CAST(ISNULL(@UpdatedDate,'') AS VARCHAR) + ', 
													   @Parameter6 = ' + ISNULL(@CreatedBy,'') + ', 
													   @Parameter7 = ' + ISNULL(@UpdatedBy,'') + ', 
													   @Parameter8 = ' + ISNULL(@MasterCompanyId ,'') +''
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