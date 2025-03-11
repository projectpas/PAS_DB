/*************************************************************             
 ** File:   [MigrateWorkFlowRecord]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate Work Flow (Templates) Records
 ** Purpose:           
 ** Date:   06/03/2025

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    06/03/2025   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigrateWorkFlowRecord @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=20,@UserName=N'ADMIN ADMIN',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigrateWorkFlowRecord]
(
	@FromMasterComanyID INT = NULL,
	@UserName VARCHAR(100) NULL,
	@Processed INT OUTPUT,
	@Migrated INT OUTPUT,
	@Failed INT OUTPUT,
	@Exists INT OUTPUT
)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  
    BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN
		DECLARE @LoopID AS INT;

		IF OBJECT_ID(N'tempdb..#TempDistinctParts') IS NOT NULL
		BEGIN
			DROP TABLE #TempDistinctParts
		END

		CREATE TABLE #TempDistinctParts
		(
			ID bigint NOT NULL IDENTITY,
			[PartId] [varchar](200) NULL,
			[CustomerName] [varchar](500) NULL,
			[Parnum] BIGINT NULL
		)

		INSERT INTO #TempDistinctParts ([PartId], [CustomerName], [Parnum])
		SELECT DISTINCT P.Id, C.[Name], PR.Parnum
		FROM TempNeoMigration.[dbo].[PartRoute] PR LEFT JOIN TempNeoMigration.[dbo].[Parts] P ON PR.Parnum = P.Num LEFT JOIN TempNeoMigration.[dbo].[Customer] C ON C.Num = P.Cusnum 
		WHERE C.Id = ''; --AND (P.Id <> '103686-35' AND P.Id <> '112N6101-4' AND P.Id <> '112N6102-2' AND P.Id <> '112N6102-6');

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempDistinctParts;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;

			DECLARE @FoundError BIT = 0;

			IF (@FoundError = 0)
			BEGIN
				DECLARE @PartId VARCHAR(200) = '';
				DECLARE @CustomerCode VARCHAR(200) = '';
				DECLARE @Parnum BIGINT = 0;
				DECLARE @CustomerId BIGINT = 0;
				DECLARE @CustomerName VARCHAR(200) = '';

				SELECT @PartId = TRIM(PartId), @CustomerCode = [CustomerName], @Parnum = Parnum FROM #TempDistinctParts WHERE ID = @LoopID;
				SELECT @CustomerId = C.CustomerId, @CustomerName = C.[Name] FROM DBO.Customer C WITH (NOLOCK) WHERE UPPER(C.Name) = UPPER(@CustomerCode) AND MasterCompanyId = @FromMasterComanyID;

				IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.Workflow WF WITH (NOLOCK) INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WF.ItemMasterId = IM.ItemMasterId WHERE UPPER(IM.partnumber) = UPPER(@PartId) AND CustomerId = @CustomerId AND WF.MasterCompanyId = @FromMasterComanyID)
				BEGIN
					DECLARE @InsertedWorkflowId BIGINT = 0;
					DECLARE @WorkScopeId BIGINT = 0;
					DECLARE @CurrencyId BIGINT = 0;
					DECLARE @ItemMasterId BIGINT = 0;

					--PRINT '@CustomerCode'
					--PRINT @CustomerCode

					SELECT @WorkScopeId = WS.WorkScopeId FROM DBO.WorkScope WS WITH (NOLOCK) WHERE WorkScopeCode = 'OVERHAUL' AND MasterCompanyId = @FromMasterComanyID;
					SELECT @CurrencyId = Curr.CurrencyId FROM DBO.Currency Curr WITH (NOLOCK) WHERE Curr.Code = 'USD' AND MasterCompanyId = @FromMasterComanyID;
					SELECT @ItemMasterId = IM.ItemMasterId FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE UPPER(IM.partnumber) = UPPER(@PartId) AND MasterCompanyId = @FromMasterComanyID;
					SELECT @CustomerId = C.CustomerId, @CustomerName = C.[Name] FROM DBO.Customer C WITH (NOLOCK) WHERE UPPER(C.Name) = UPPER(@CustomerCode) AND MasterCompanyId = @FromMasterComanyID;

					DECLARE @CurrentNummber BIGINT;
					DECLARE @CodePrefixs VARCHAR(50);
					DECLARE @CodeSufix VARCHAR(50);
					DECLARE @WorkOrderNumber VARCHAR(50);

					DECLARE @CodePrefixEnum_WorkflowId BIGINT = 33;

					DECLARE @CodePrefix TABLE (
						CodePrefixId BIGINT,
						CurrentNummber BIGINT,
						StartsFrom BIGINT
					);

					DELETE FROM @CodePrefix;

					-- Fetch the CodePrefix record
					INSERT INTO @CodePrefix
					SELECT TOP 1 CodePrefixId, CurrentNummber, StartsFrom FROM DBO.CodePrefixes WITH (NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0 
					AND CodeTypeId = 33 AND MasterCompanyId = @FromMasterComanyID
					ORDER BY CodePrefixId;

					IF EXISTS (SELECT 1 FROM @CodePrefix)
					BEGIN
						SELECT @CurrentNummber = CASE WHEN CurrentNummber >= 0 THEN CurrentNummber + 1 ELSE StartsFrom + 1 END FROM @CodePrefix;

						UPDATE CodePrefixes SET CurrentNummber = @CurrentNummber WHERE CodePrefixId = (SELECT CodePrefixId FROM @CodePrefix) AND MasterCompanyId = @FromMasterComanyID;

						SELECT @CodePrefixs = CodePrefix, @CodeSufix = CodeSufix FROM CodePrefixes WHERE CodePrefixId = (SELECT CodePrefixId FROM @CodePrefix) AND MasterCompanyId = @FromMasterComanyID;
					END

					SET @WorkOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNummber, @CodePrefixs, @CodeSufix));

					--PRINT '@CustomerId'
					--PRINT @CustomerId
					--PRINT '@ItemMasterId'
					--PRINT @ItemMasterId
					--PRINT '@WorkOrderNumber'
					--PRINT @WorkOrderNumber

					IF (@ItemMasterId = 0)
					BEGIN
						DECLARE @GLAccountId BIGINT = 0;
						DECLARE @UOM_AUTO_KEY AS FLOAT = 0;
						DECLARE @UOMId BIGINT = 0;
						DECLARE @PriorityId BIGINT = 0;
						DECLARE @ManufacturerId BIGINT = 0;
						DECLARE @AssetAcquisitionTypeId_BUY BIGINT = 0;
						DECLARE @AssetAcquisitionTypeId_MAKE BIGINT = 0;
						DECLARE @ItemGroupdId BIGINT = 0;
						DECLARE @ItemClassificationId BIGINT = 0;
						DECLARE @InsertedPartId BIGINT = 0;

						SELECT @GLAccountId = GLAccountId FROM DBO.GLAccount GL WITH (NOLOCK) WHERE AccountCode = '10000' AND MasterCompanyId = @FromMasterComanyID;
						SELECT @UOMId = UnitOfMeasureId FROM DBO.UnitOfMeasure MF WHERE UPPER(MF.ShortName) = 'EA' AND MasterCompanyId = @FromMasterComanyID;
						SELECT @ManufacturerId = ManufacturerId FROM DBO.Manufacturer MF WHERE UPPER(MF.[Name]) = 'NA' AND MasterCompanyId = @FromMasterComanyID;
						SELECT @PriorityId = PriorityId FROM DBO.[Priority] P WHERE UPPER(Description) = 'ROUTINE' AND MasterCompanyId = @FromMasterComanyID;
						SELECT @CurrencyId = CurrencyId FROM DBO.[Currency] C WHERE UPPER(Code) = 'USD' AND MasterCompanyId = @FromMasterComanyID;
						SELECT @AssetAcquisitionTypeId_BUY = AssetAcquisitionTypeId FROM DBO.[AssetAcquisitionType] C WHERE UPPER(Name) = 'BUY' AND MasterCompanyId = @FromMasterComanyID;
						SELECT @AssetAcquisitionTypeId_MAKE = AssetAcquisitionTypeId FROM DBO.[AssetAcquisitionType] C WHERE UPPER(Name) = 'MAKE' AND MasterCompanyId = @FromMasterComanyID;
						SELECT @ItemGroupdId = C.ItemGroupId FROM DBO.[ItemGroup] C WHERE UPPER(ItemGroupCode) = 'N/A' AND MasterCompanyId = @FromMasterComanyID;
						SELECT @ItemClassificationId = C.ItemClassificationId FROM DBO.[ItemClassification] C WHERE UPPER(ItemClassificationCode) = 'NA' AND MasterCompanyId = @FromMasterComanyID;

						DECLARE @DefaultSiteId BIGINT;
						SELECT @DefaultSiteId = SiteId FROM DBO.[Site] WHERE UPPER([Name]) = UPPER('NEO-NEOSOURCE INC.') AND MasterCompanyId = @FromMasterComanyID;

						IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.[ItemMaster] WITH (NOLOCK) WHERE TRIM([partnumber]) = TRIM(@PartId) AND ManufacturerId = @ManufacturerId AND MasterCompanyId = @FromMasterComanyID)
						BEGIN
							INSERT INTO [MasterParts]
							([PartNumber], [Description], [MasterCompanyId], [CreatedDate], [CreatedBy], [UpdatedDate], [UpdatedBy], [IsActive], [IsDeleted], [ManufacturerId], [PartType])
							SELECT TRIM(@PartId), TRIM(T.[Desc]), @FromMasterComanyID, GETDATE(), @UserName, GETDATE(), @UserName, 1, 0, @ManufacturerId, NULL
							FROM [TempNeoMigration].[dbo].[Parts] AS T WHERE TRIM(T.Id) = TRIM(@PartId);

							SET @InsertedPartId = SCOPE_IDENTITY();

							INSERT INTO [ItemMaster]
							 ([ItemTypeId],[PartAlternatePartId],[ItemGroupId],[ItemClassificationId],[IsHazardousMaterial],[IsExpirationDateAvailable],[ExpirationDate]
							,[IsReceivedDateAvailable],[DaysReceived],[IsManufacturingDateAvailable],[ManufacturingDays],[IsTagDateAvailable],[TagDays],[IsOpenDateAvailable]
							,[OpenDays],[IsShippedDateAvailable],[ShippedDays],[IsOtherDateAvailable],[OtherDays],[ProvisionId],[ManufacturerId],[IsDER],[NationalStockNumber],[IsSchematic]
							,[OverhaulHours],[RPHours],[TestHours],[RFQTracking],[GLAccountId],[PurchaseUnitOfMeasureId],[StockUnitOfMeasureId],[ConsumeUnitOfMeasureId],[LeadTimeDays]
							,[ReorderPoint],[ReorderQuantiy],[MinimumOrderQuantity],[PartListPrice],[PriorityId],[WarningId],[Memo],[ExportCountryId],[ExportValue],[ExportCurrencyId]
							,[ExportWeight],[ExportWeightUnit],[ExportSizeLength],[ExportSizeWidth],[ExportSizeHeight],[ExportSizeUnit],[ExportClassificationId],[PurchaseCurrencyId]
							,[SalesIsFixedPrice],[SalesCurrencyId],[SalesLastSalePriceDate],[SalesLastSalesDiscountPercentDate],[IsActive],[CurrencyId],[MasterCompanyId],[CreatedBy]
							,[UpdatedBy],[CreatedDate],[UpdatedDate],[TurnTimeOverhaulHours],[TurnTimeRepairHours],[SoldUnitOfMeasureId],[IsDeleted],[ExportUomId],[partnumber],[PartDescription]
							,[isTimeLife],[isSerialized],[ManagementStructureId],[ShelfLife],[DiscountPurchasePercent],[UnitCost],[ListPrice],[PriceDate],[ItemNonStockClassificationId]
							,[StockLevel],[ExportECCN],[ITARNumber],[ShelfLifeAvailable],[mfgHours],[IsPma],[turnTimeMfg],[turnTimeBenchTest],[IsExportUnspecified],[IsExportNONMilitary]
							,[IsExportMilitary],[IsExportDual],[IsOemPNId],[MasterPartId],[RepairUnitOfMeasureId],[RevisedPartId],[SiteId],[WarehouseId],[LocationId],[ShelfId]
							,[BinId],[ItemMasterAssetTypeId],[IsHotItem],[ExportSizeUnitOfMeasureId],[IsAcquiredMethodBuy],[IsOEM],[RevisedPart],[OEMPN],[ItemClassificationName]
							,[ItemGroup],[AssetAcquistionType],[ManufacturerName],[PurchaseUnitOfMeasure],[StockUnitOfMeasure],[ConsumeUnitOfMeasure],[PurchaseCurrency],[SalesCurrency]
							,[GLAccount],[Priority],[SiteName],[WarehouseName],[LocationName],[ShelfName],[BinName],[CurrentStlNo],[MTBUR],[NE],[NS],[OH],[REP],[SVC],[Figure],[Item])

							SELECT TOP 1 1, NULL, @ItemGroupdId, @ItemClassificationId, 0, 0, NULL
							,0, 0, 0, 0, 0, 0, 0
							,0, 0, 0, 0, 0, NULL, @ManufacturerId, 0, NULL, 0
							,0, 0, 0, 0, @GLAccountId, @UOMId, NULL, NULL, 0
							,0, 0, 0, NULL, @PriorityId, NULL, T.notes, NULL, NULL, NULL
							,NULL, NULL, NULL, NULL, NULL, NULL, NULL, @CurrencyId
							,NULL, @CurrencyId, GETUTCDATE(), GETUTCDATE(), 1, @CurrencyId, @FromMasterComanyID, @UserName
							,@UserName, GETUTCDATE(), GETUTCDATE(), 0, 0, NULL, 0, NULL, TRIM(T.Id), TRIM(T.[Desc])
							,0, T.Serialize, NULL, 0, NULL, NULL, T.Price, NULL, NULL
							,0, NULL, NULL, 0, 0, 0, 0, 0, NULL, NULL
							,NULL, NULL, NULL, @InsertedPartId, NULL, NULL, @DefaultSiteId, NULL, NULL, NULL
							,NULL, @AssetAcquisitionTypeId_BUY, 0, NULL, 0, 1, NULL, NULL, NULL
							,NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
							,NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0, NULL, NULL
							FROM [TempNeoMigration].[dbo].[Parts] AS T WHERE TRIM(T.Id) = TRIM(@PartId);

							SET @ItemMasterId = SCOPE_IDENTITY();
						END
						ELSE
						BEGIN
							SELECT @ItemMasterId = ItemMasterId FROM DBO.[ItemMaster] WITH (NOLOCK) WHERE UPPER(TRIM([partnumber])) = UPPER(TRIM(@PartId)) AND ManufacturerId = @ManufacturerId AND MasterCompanyId = @FromMasterComanyID;
						END
					END

					INSERT INTO DBO.Workflow
					([WorkflowDescription],[Version],[WorkScopeId],[ItemMasterId],[PartNumberDescription],[CustomerId],[CurrencyId],[WorkflowExpirationDate],[IsCalculatedBERThreshold],[IsFixedAmount],
					[FixedAmount],[IsPercentageOfNew],[CostOfNew],[PercentageOfNew],[IsPercentageOfReplacement],[CostOfReplacement],[PercentageOfReplacement],[Memo],[ManagementStructureId],[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartNumber],[CustomerName],[FlatRate],[BERThresholdAmount],[WorkOrderNumber],[CustomerCode],[OtherCost],
					[WorkflowCreateDate],[ChangedPartNumberId],[PercentageOfMaterial],[PercentageOfExpertise],[PercentageOfCharges],[PercentageOfOthers],[PercentageOfTotal],[RevisedPartNumber],
					[changedPartNumberDescription],[ChangedPartNumber],[WorkScope],[Currency],[WFParentId],[IsVersionIncrease])

					SELECT NULL,'VER-000001',@WorkScopeId,@ItemMasterId,NULL,@CustomerId,@CurrencyId,NULL,NULL,NULL,
					NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@FromMasterComanyID,
					@UserName,@UserName,GETUTCDATE(),GETUTCDATE(),1,0,@PartId,@CustomerName,NULL,0,@WorkOrderNumber,NULL,0,
					GETDATE(),NULL,0,0,0,0,0,'',
					NULL,NULL,'OVERHAUL','USD',NULL,0
					FROM #TempDistinctParts AS WF WHERE WF.Id = @LoopID;

					SET @InsertedWorkflowId = SCOPE_IDENTITY();

					IF OBJECT_ID(N'tempdb..#TempWorkflowDirection') IS NOT NULL
					BEGIN
						DROP TABLE #TempWorkflowDirection
					END

					CREATE TABLE #TempWorkflowDirection
					(
						ID bigint NOT NULL IDENTITY,
						[TaskId] [bigint] NOT NULL,
						[Seq] [int] NOT NULL,
						[Prt_notes] [varchar](max) NULL
					)

					INSERT INTO #TempWorkflowDirection ([TaskId], [Seq], [Prt_notes])
					SELECT [Dronum], [Seq], [Prt_notes] FROM TempNeoMigration.[dbo].[PartRoute] WHERE Parnum = @Parnum;

					DECLARE @TotalCount AS INT;
					DECLARE @WFDLoopID AS INT;

					SELECT @TotalCount = COUNT(*), @WFDLoopID = MIN(ID) FROM #TempWorkflowDirection;

					WHILE (@WFDLoopID <= @TotalCount)
					BEGIN
						PRINT 'Current WFDLoopID: ' + CAST(@WFDLoopID AS NVARCHAR);
						PRINT 'Total Count: ' + CAST(@TotalCount AS NVARCHAR);

						DECLARE @TaskId BIGINT = 0;
						DECLARE @TaskId_PAS BIGINT = NULL;
						DECLARE @ExistingTaskInWorkflow INT = 0;
						DECLARE @NewTaskName NVARCHAR(255);
						DECLARE @BaseTaskName NVARCHAR(255);
						DECLARE @TaskSuffix INT = 1;
						DECLARE @TempTaskId BIGINT = NULL;

						-- Get the TaskId from TempWorkflowDirection
						SELECT @TaskId = TaskId FROM #TempWorkflowDirection WHERE ID = @WFDLoopID;

						-- Get the base task name (trim any spaces)
						SELECT @BaseTaskName = RTRIM(OP.[Name]) 
						FROM TempNeoMigration.[dbo].[Operations] OP 
						WHERE OP.Num = @TaskId;

						PRINT 'Processing Task: ' + @BaseTaskName;
						PRINT 'MasterCompanyId: ' + CAST(@FromMasterComanyID AS NVARCHAR);

						-- Step 1: Check if the task (including suffixed versions) exists globally
						SELECT TOP 1 @TaskId_PAS = TaskId 
						FROM DBO.Task 
						WHERE [Description] = @BaseTaskName 
						AND MasterCompanyId = @FromMasterComanyID;

						-- Step 2: If Task exists globally, check if it's already in the current workflow
						IF @TaskId_PAS IS NOT NULL
						BEGIN
							PRINT 'Existing Task Found: ' + CAST(@TaskId_PAS AS NVARCHAR);

							SELECT @ExistingTaskInWorkflow = COUNT(*)
							FROM WorkFlowTask WFT
							WHERE WFT.WorkflowId = @InsertedWorkflowId 
							AND WFT.TaskId = @TaskId_PAS;

							-- If the task already exists in this workflow, find an unused variation (Task1, Task2, etc.)
							IF @ExistingTaskInWorkflow > 0
							BEGIN
								PRINT 'Task already exists in this workflow, generating a new Task name';

								-- Find the next available Task name
								WHILE 1 = 1
								BEGIN
									SET @NewTaskName = RTRIM(@BaseTaskName) + CAST(@TaskSuffix AS NVARCHAR(10));

									SET @TempTaskId = NULL;

									-- Check if this new task name exists globally
									SELECT @TempTaskId = TaskId 
									FROM DBO.Task 
									WHERE [Description] = @NewTaskName 
									AND MasterCompanyId = @FromMasterComanyID;

									-- If the new task name exists, check if it's used in the current workflow
									IF @TempTaskId IS NOT NULL
									BEGIN
										SELECT @ExistingTaskInWorkflow = COUNT(*)
										FROM WorkFlowTask WFT
										WHERE WFT.WorkflowId = @InsertedWorkflowId 
										AND WFT.TaskId = @TempTaskId;

										-- If it's not in this workflow, reuse it
										IF @ExistingTaskInWorkflow = 0
										BEGIN
											PRINT 'Reusing Existing Task: ' + @NewTaskName;
											SET @TaskId_PAS = @TempTaskId;
											BREAK;
										END
										ELSE
											PRINT 'Task ' + @NewTaskName + ' already exists in workflow. Trying next suffix.';
									END
									ELSE
									BEGIN
										-- Insert new task with unique name
										PRINT 'Inserting New Task: ' + @NewTaskName;
										INSERT INTO DBO.Task ([Description],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Sequence],[IsTravelerTask],
															  [Descrepancy],[Resolution],[StandardHours],[StandardMinute],[IsPrintInWO],[IsPrintInWOQ],[IsPrintInspector],[IsPrintTechnician])
										SELECT @NewTaskName, '', @FromMasterComanyID, @UserName, @UserName, GETUTCDATE(), GETUTCDATE(), 1, 0, 
											   (SELECT ISNULL(MAX(Sequence), 0) + 1 FROM Task WHERE MasterCompanyId = @FromMasterComanyID), 
											   1, '', '', 0, 0, 1, 1, 1, 1;

										-- Get the newly inserted TaskId
										SELECT @TaskId_PAS = SCOPE_IDENTITY();
										PRINT '✅ New Task Inserted with ID: ' + CAST(@TaskId_PAS AS NVARCHAR);
										BREAK;
									END

									-- Increase suffix for next iteration
									SET @TaskSuffix = @TaskSuffix + 1;
								END
							END
							ELSE
							BEGIN
								PRINT 'Using existing TaskId for workflow';
							END
						END

						-- Step 3: If TaskId is still NULL, insert the original task
						IF @TaskId_PAS IS NULL
						BEGIN
							PRINT 'No Existing Task Found - Inserting New Task: ' + @BaseTaskName;
							SET @NewTaskName = @BaseTaskName; -- Ensure base name is used when inserting

							-- Insert new task
							INSERT INTO DBO.Task ([Description],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Sequence],[IsTravelerTask],
												  [Descrepancy],[Resolution],[StandardHours],[StandardMinute],[IsPrintInWO],[IsPrintInWOQ],[IsPrintInspector],[IsPrintTechnician])
							SELECT @NewTaskName, '', @FromMasterComanyID, @UserName, @UserName, GETUTCDATE(), GETUTCDATE(), 1, 0, 
								   (SELECT ISNULL(MAX(Sequence), 0) + 1 FROM Task WHERE MasterCompanyId = @FromMasterComanyID), 
								   1, '', '', 0, 0, 1, 1, 1, 1;

							-- Get the newly inserted TaskId
							SELECT @TaskId_PAS = SCOPE_IDENTITY();
						END

						-- Debug output: Final TaskId
						PRINT 'Final TaskId Used: ' + CAST(@TaskId_PAS AS NVARCHAR);

						-- Insert into WorkFlowTask
						INSERT INTO DBO.WorkFlowTask ([WorkFlowId],[WorkFlowNumber],[TaskId],[TaskDescription],[SequenceNumber],[Descrepancy],[Resolution],[IsVersionIncrease],[WFParentId],
						[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])
						SELECT @InsertedWorkflowId, @WorkOrderNumber, @TaskId_PAS, NULL, Seq, NULL, NULL, 0, NULL,
						@FromMasterComanyID, @UserName, GETUTCDATE(), @UserName, GETUTCDATE(), 1, 0
						FROM #TempWorkflowDirection WHERE ID = @WFDLoopID;

						-- Insert into WorkflowDirection
						DECLARE @TaskName VARCHAR(150) = '';
						SELECT @TaskName = T.[Description] FROM DBO.Task T WITH (NOLOCK) WHERE T.TaskId = @TaskId_PAS;

						INSERT INTO DBO.WorkflowDirection
						([WorkflowId],[Action],[Description],[Sequence],[Memo],[TaskId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Order],
						[WFParentId],[IsVersionIncrease],[TaskName],[ParentId],[IsParent],[IsTaskDetails])
						SELECT @InsertedWorkflowId, @TaskName + ' - STEP', Prt_notes, Seq, NULL, @TaskId_PAS, @FromMasterComanyID, @UserName, @UserName, GETUTCDATE(), GETUTCDATE(), 1, 0, NULL,
						NULL, NULL, '', NULL, 1, NULL
						FROM #TempWorkflowDirection WHERE ID = @WFDLoopID;

						-- Increment loop counter
						SET @WFDLoopID = @WFDLoopID + 1;

						PRINT 'Incrementing WFDLoopID to: ' + CAST(@WFDLoopID AS NVARCHAR);
					END


					SET @MigratedRecords = @MigratedRecords + 1;
				END
			END

			SET @LoopID = @LoopID + 1;
		END
	END

	COMMIT TRANSACTION

	SET @Processed = @ProcessedRecords;
	SET @Migrated = @MigratedRecords;
	SET @Failed = @RecordsWithError;
	SET @Exists = @RecordExits;

	SELECT @Processed, @Migrated, @Failed, @Exists;
  END TRY
  BEGIN CATCH
    IF @@trancount > 0
	  ROLLBACK TRAN;
	  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
	  DECLARE @ErrorLogID int
	  ,@DatabaseName varchar(100) = DB_NAME()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
	  ,@AdhocComments varchar(150) = 'MigrateWorkFlowRecord'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END