
-- EXEC [dbo].[CopyWorkFlowRecord] 97, 'ADMIN User', 0
CREATE   PROCEDURE [dbo].[CopyWorkFlowRecord]
-- Add the parameters for the stored procedure here
@WorkflowId bigint,	
@CreatedBy  varchar(50)=null,
@returnOut varchar(200) out	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		SET @returnOut = 'E';

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				declare @newWorkFlowId bigint 
				declare @chargesCount int =(Select count(*) from dbo.WorkflowChargesList WITH (NOLOCK) where WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0)
				declare @directionCount int =(Select count(*) from dbo.WorkFlowDirection WITH (NOLOCK) where WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0)
				declare @equipmentCount int =(Select count(*) from dbo.WorkflowEquipmentList WITH (NOLOCK) where WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0)
				declare @exclusionsCount int =(Select count(*) from dbo.WorkFlowExclusion WITH (NOLOCK) where WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0)
				declare @expertiseListCount int =(Select count(*) from dbo.WorkflowExpertiseList WITH (NOLOCK) where WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0)
				declare @materialCount int =(Select count(*) from dbo.WorkflowMaterial WITH (NOLOCK) where WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0)
				declare @measurementsCount int =(Select count(*) from dbo.WorkflowMeasurement WITH (NOLOCK) where WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0)
				declare @publicationCount int =(Select count(*) from dbo.WorkflowPublications WITH (NOLOCK) where WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0)

				SELECT WorkflowDescription, Version, WorkScopeId, ItemMasterId, PartNumberDescription, CustomerId, CurrencyId, WorkflowExpirationDate, IsCalculatedBERThreshold, IsFixedAmount, FixedAmount, IsPercentageOfNew, CostOfNew, PercentageOfNew, IsPercentageOfReplacement, CostOfReplacement, PercentageOfReplacement, Memo, ManagementStructureId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, PartNumber, CustomerName, FlatRate, BERThresholdAmount, WorkOrderNumber, CustomerCode, OtherCost, WorkflowCreateDate, ChangedPartNumberId, PercentageOfMaterial, PercentageOfExpertise, PercentageOfCharges, PercentageOfOthers, PercentageOfTotal, RevisedPartNumber, changedPartNumberDescription, ChangedPartNumber, WorkScope, Currency, WFParentId, IsVersionIncrease INTO #tempTable FROM dbo.Workflow WITH (NOLOCK) WHERE WorkflowId = @WorkflowId
				UPDATE #tempTable SET CreatedBy = @CreatedBy,UpdatedBy =@CreatedBy, CreatedDate = GETDATE(), UpdatedDate = GETDATE()
				INSERT INTO dbo.Workflow SELECT * FROM #tempTable
				
				SET @newWorkFlowId=SCOPE_IDENTITY()

				DECLARE @WorkFlowNumber VARCHAR(50);
				DECLARE @MasterCompanyId INT;
				SELECT @MasterCompanyId = MasterCompanyId FROM dbo.Workflow WITH (NOLOCK) WHERE WorkflowId = @WorkflowId

				/* Code Prefix */
				IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
				BEGIN
				DROP TABLE #tmpCodePrefixes
				END
				
				CREATE TABLE #tmpCodePrefixes
				(
						ID BIGINT NOT NULL IDENTITY, 
						CodePrefixId BIGINT NULL,
						CodeTypeId BIGINT NULL,
						CurrentNummber BIGINT NULL,
						CodePrefix VARCHAR(50) NULL,
						CodeSufix VARCHAR(50) NULL,
						StartsFrom BIGINT NULL,
				)

				INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNummber, CodePrefix, CodeSufix, StartsFrom) 
				SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId IN (33) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

				/* Code Prefix */
				DECLARE @CurrentNo AS BIGINT;

				IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 33))
				BEGIN 
					SELECT @CurrentNo = CASE WHEN CurrentNummber > 0 
						THEN CAST(CurrentNummber AS BIGINT) + 1 
							ELSE CAST(StartsFrom AS BIGINT) + 1 END 
					FROM #tmpCodePrefixes WHERE CodeTypeId = 33

					SET @WorkFlowNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo, (SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 33), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 33)))
				END

				
				Update dbo.Workflow set WorkOrderNumber = @WorkFlowNumber where WorkflowId = @newWorkFlowId
				
				UPDATE CodePrefixes SET CurrentNummber = @CurrentNo WHERE CodeTypeId = 33 AND MasterCompanyId = @MasterCompanyId

				DROP TABLE #tempTable	
					IF(@chargesCount >0)
					BEGIN
						SELECT WorkflowId, WorkflowChargeTypeId, [Description], Quantity, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, VendorId, TaskId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, VendorName, [Order], IsDeleted, Memo, WFParentId, IsVersionIncrease
						INTO #tempTable2 FROM dbo.WorkflowChargesList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0
						UPDATE #tempTable2 SET WorkflowId = @newWorkFlowId,CreatedBy = @CreatedBy,UpdatedBy =@CreatedBy, CreatedDate = GETDATE(), UpdatedDate = GETDATE()
						INSERT INTO dbo.WorkflowChargesList  SELECT * FROM #tempTable2
						DROP TABLE #tempTable2
					END
					IF(@directionCount >0)
					BEGIN
						SELECT WorkflowId, [Action], [Description], [Sequence], Memo, TaskId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, [Order], WFParentId, IsVersionIncrease INTO #tempTable3 FROM dbo.WorkFlowDirection WITH (NOLOCK) WHERE WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0
						UPDATE #tempTable3 SET WorkflowId = @newWorkFlowId,CreatedBy = @CreatedBy,UpdatedBy =@CreatedBy, CreatedDate = GETDATE(), UpdatedDate = GETDATE()
						INSERT INTO dbo.WorkFlowDirection SELECT * FROM #tempTable3
						DROP TABLE #tempTable3
					END
					IF(@equipmentCount >0)
					BEGIN
						SELECT WorkflowId, AssetId, AssetTypeId, AssetDescription, Quantity, TaskId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, PartNumber, [Order], Memo, WFParentId, IsVersionIncrease, AssetAttributeTypeId INTO #tempTable4 FROM dbo.WorkflowEquipmentList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0
						UPDATE #tempTable4 SET WorkflowId = @newWorkFlowId,CreatedBy = @CreatedBy,UpdatedBy =@CreatedBy, CreatedDate = GETDATE(), UpdatedDate = GETDATE()
						INSERT INTO dbo.WorkflowEquipmentList SELECT * FROM #tempTable4
						DROP TABLE #tempTable4
					END
					IF(@exclusionsCount >0)
					BEGIN
						SELECT  WorkflowId, ItemMasterId, UnitCost, Quantity, ExtendedCost, EstimtPercentOccurrance, Memo, TaskId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, PartNumber, PartDescription, [Order], ConditionId, ItemClassificationId, WFParentId, IsVersionIncrease INTO #tempTable5 FROM dbo.WorkFlowExclusion WITH (NOLOCK) WHERE WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0
						UPDATE #tempTable5 SET WorkflowId = @newWorkFlowId,CreatedBy = @CreatedBy,UpdatedBy =@CreatedBy, CreatedDate = GETDATE(), UpdatedDate = GETDATE()
						INSERT INTO dbo.WorkFlowExclusion SELECT * FROM #tempTable5
						DROP TABLE #tempTable5
					END
					IF(@expertiseListCount >0)
					BEGIN
						SELECT  WorkflowId, ExpertiseTypeId, EstimatedHours, LaborDirectRate, DirectLaborRate, OverheadBurden, OverheadCost, StandardRate, LaborOverheadCost, TaskId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, [Order], Memo, WFParentId, IsVersionIncrease, OverheadburdenPercentId INTO #tempTable6 FROM dbo.WorkflowExpertiseList WITH (NOLOCK) WHERE WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0
						UPDATE #tempTable6 SET WorkflowId = @newWorkFlowId,CreatedBy = @CreatedBy,UpdatedBy =@CreatedBy, CreatedDate = GETDATE(), UpdatedDate = GETDATE()
						INSERT INTO dbo.WorkflowExpertiseList SELECT * FROM #tempTable6
						DROP TABLE #tempTable6
					END
					IF(@materialCount >0)
					BEGIN
						SELECT  WorkflowId, ItemMasterId, TaskId, Quantity, UnitOfMeasureId, ConditionCodeId, UnitCost, ExtendedCost, Price, ProvisionId, IsDeferred, WorkflowActionId, Memo, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, MaterialMandatoriesName, PartNumber, PartDescription, ItemClassificationId, ExtendedPrice, [Order], MaterialMandatoriesId, WFParentId, IsVersionIncrease, Figure, Item INTO #tempTable7 FROM dbo.WorkflowMaterial WITH (NOLOCK) WHERE WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0
						UPDATE #tempTable7 SET WorkflowId = @newWorkFlowId,CreatedBy = @CreatedBy,UpdatedBy =@CreatedBy, CreatedDate = GETDATE(), UpdatedDate = GETDATE()
						INSERT INTO dbo.WorkflowMaterial SELECT * FROM #tempTable7
						DROP TABLE #tempTable7
					END
					IF(@measurementsCount >0)
					BEGIN
						SELECT WorkflowId, Sequence, Stage, Min, Max, Expected, DiagramURL, Memo, TaskId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, ItemMasterId, PartNumber, [Order], PartDescription, WFParentId, IsVersionIncrease INTO #tempTable8 FROM dbo.WorkflowMeasurement WITH (NOLOCK) WHERE WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0
						UPDATE #tempTable8 SET WorkflowId = @newWorkFlowId,CreatedBy = @CreatedBy,UpdatedBy =@CreatedBy, CreatedDate = GETDATE(), UpdatedDate = GETDATE()
						INSERT INTO dbo.WorkflowMeasurement SELECT * FROM #tempTable8
						DROP TABLE #tempTable8
					END
					IF(@publicationCount >0)
					BEGIN
						SELECT CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsDeleted, PublicationId, PublicationDescription, PublicationType, [Sequence], Source, AircraftManufacturer, Model, [Location], Revision, RevisionDate, VerifiedBy, VerifiedDate, [Status], [Image], TaskId, WorkflowId, MasterCompanyId, [Order], IsActive, Memo, WFParentId, IsVersionIncrease INTO #tempTable9 FROM dbo.WorkflowPublications WITH (NOLOCK) WHERE WorkflowId = @WorkflowId and ISNULL(IsDeleted,0) =0
						UPDATE #tempTable9 SET WorkflowId = @newWorkFlowId,CreatedBy = @CreatedBy,UpdatedBy =@CreatedBy, CreatedDate = GETDATE(), UpdatedDate = GETDATE()
						INSERT INTO dbo.WorkflowPublications SELECT * FROM #tempTable9
						DROP TABLE #tempTable9
					END

					SET @returnOut = 'S';
			END
		COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CopyWorkFlowRecord' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkflowId, '') + ''', 
													   @Parameter2 = ' + ISNULL(@CreatedBy ,'') +''
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