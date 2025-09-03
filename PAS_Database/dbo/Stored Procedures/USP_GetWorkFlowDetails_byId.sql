/*************************************************************           
 ** File:   [USP_GetWorkFlowDetails_byId]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to get the WorkFlow Details
 ** Date:   23-April-2025      
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author					Change Description            
 ** --   --------			-------				--------------------------------          
    1    23-April-2025		Devendra Shekh			Created
	2    02-Sep-2025        Sahdev Saliya           Added New Field Verified, VerifiedBy And VerifiedDate

EXEC [USP_GetWorkFlowDetails_byId] 5242, 2
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkFlowDetails_byId]
 @WorkflowId BIGINT = NULL,  
 @EmployeeId BIGINT	= NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
			
			DECLARE @WFItemMasterId BIGINT = 0, @WFWorkScopeId BIGINT = 0;
			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
			DECLARE @PublicationAttachmentModuleId INT = (SELECT [AttachmentModuleId] FROM [dbo].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'Publication');

			DECLARE @IGDescription VARCHAR(256), @Symbol VARCHAR(10), @Code VARCHAR(10), @chargesTypeName VARCHAR(256), @AssetName VARCHAR(50), @AssetId VARCHAR(30), @AssetTypeName VARCHAR(50), @stockType VARCHAR(30), @ItemClassification VARCHAR(30),
					@Condition VARCHAR(256), @ManufacturerName VARCHAR(250), @ExpetiseTypeName VARCHAR(30), @UnitOfMeasure VARCHAR(100), @PublicationTypeName VARCHAR(100), @ModelName VARCHAR(50), @PublicationId VARCHAR(100);

			SELECT	@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description],LTZ.[Description])
			FROM [dbo].[Employee] E WITH(NOLOCK) 
			LEFT JOIN [dbo].TimeZone ETZ WITH(NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN [dbo].LegalEntity LE WITH(NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN [dbo].TimeZone LTZ WITH(NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
			WHERE E.EmployeeId = @EmployeeId;

			-- Getting WorkFlow Details
			SELECT	[WorkflowId], [WorkflowDescription], [Version], [WorkScopeId], [ItemMasterId], [PartNumberDescription], [CustomerId], [CurrencyId], [WorkflowExpirationDate], [IsCalculatedBERThreshold], [IsFixedAmount], [FixedAmount], [IsPercentageOfNew],
					[CostOfNew], [PercentageOfNew], [IsPercentageOfReplacement], [CostOfReplacement], [PercentageOfReplacement], [Memo], [ManagementStructureId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
					[PartNumber], [CustomerName], [FlatRate], [BERThresholdAmount], [WorkOrderNumber], [CustomerCode], [OtherCost], [WorkflowCreateDate], [ChangedPartNumberId], [PercentageOfMaterial], [PercentageOfExpertise], [PercentageOfCharges], 
					[PercentageOfOthers], [PercentageOfTotal], [RevisedPartNumber], [changedPartNumberDescription], [ChangedPartNumber], [Currency], [WFParentId], [IsVersionIncrease], @Symbol AS [CurrencySymbol], @Code AS [CurrencyText], @IGDescription AS [ItemGroup], [Verified], [VerifiedBy], [VerifiedDate]
			INTO #tmpWorkFLow FROM [dbo].[Workflow] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId;

			UPDATE	TMP
			SET	TMP.ItemGroup = IG.[Description],
				TMP.CustomerName = CU.[Name],
				TMP.CustomerCode = CU.[CustomerCode],
				TMP.CurrencySymbol = CY.[Symbol],
				TMP.CurrencyText = CY.[Code]
			FROM #tmpWorkFLow TMP
			LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON TMP.ItemMasterId = IM.ItemMasterId
			LEFT JOIN [dbo].[ItemGroup] IG WITH(NOLOCK) ON IM.ItemGroupId = IG.ItemGroupId
			LEFT JOIN [dbo].[Customer] CU WITH(NOLOCK) ON TMP.CustomerId = CU.CustomerId
			LEFT JOIN [dbo].[Currency] CY WITH(NOLOCK) ON TMP.CurrencyId = CY.CurrencyId
			
			SELECT @WFItemMasterId = [ItemMasterId], @WFWorkScopeId = [WorkScopeId] FROM #tmpWorkFLow WHERE [WorkflowId] = @WorkflowId;

			-- Getting ItemMaster Details
			SELECT	[ItemMasterId], [ItemTypeId], [PartAlternatePartId], [ItemGroupId], [ItemClassificationId], [IsHazardousMaterial], [IsExpirationDateAvailable], [ExpirationDate], [IsReceivedDateAvailable], [DaysReceived], [IsManufacturingDateAvailable],
					[ManufacturingDays], [IsTagDateAvailable], [TagDays], [IsOpenDateAvailable], [OpenDays], [IsShippedDateAvailable], [ShippedDays], [IsOtherDateAvailable], [OtherDays], [ProvisionId], [ManufacturerId], [IsDER], [NationalStockNumber],
					[IsSchematic], [OverhaulHours], [RPHours], [TestHours], [RFQTracking], [GLAccountId], [PurchaseUnitOfMeasureId], [StockUnitOfMeasureId], [ConsumeUnitOfMeasureId], [LeadTimeDays], [ReorderPoint], [ReorderQuantiy], [MinimumOrderQuantity],
					[PartListPrice], [PriorityId], [WarningId], [Memo], [ExportCountryId], [ExportValue], [ExportCurrencyId], [ExportWeight], [ExportWeightUnit], [ExportSizeLength], [ExportSizeWidth], [ExportSizeHeight], [ExportSizeUnit], [ExportClassificationId],
					[PurchaseCurrencyId], [SalesIsFixedPrice], [SalesCurrencyId], [SalesLastSalePriceDate], [SalesLastSalesDiscountPercentDate], [IsActive], [CurrencyId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [TurnTimeOverhaulHours],
					[TurnTimeRepairHours], [SoldUnitOfMeasureId], [IsDeleted], [ExportUomId], [partnumber], [PartDescription], [isTimeLife], [isSerialized], [ManagementStructureId], [ShelfLife], [DiscountPurchasePercent], [UnitCost], [ListPrice], [PriceDate], 
					[ItemNonStockClassificationId], [StockLevel], [ExportECCN], [ITARNumber], [ShelfLifeAvailable], [mfgHours], [IsPma], [turnTimeMfg], [turnTimeBenchTest], [IsExportUnspecified], [IsExportNONMilitary], [IsExportMilitary], [IsExportDual], [IsOemPNId],
					[MasterPartId], [RepairUnitOfMeasureId], [RevisedPartId], [SiteId], [WarehouseId], [LocationId], [ShelfId], [BinId], [ItemMasterAssetTypeId], [IsHotItem], [ExportSizeUnitOfMeasureId], [IsAcquiredMethodBuy], [IsOEM], [RevisedPart], [OEMPN],
					[ItemClassificationName], [ItemGroup], [AssetAcquistionType], [ManufacturerName], [PurchaseUnitOfMeasure], [StockUnitOfMeasure], [ConsumeUnitOfMeasure], [PurchaseCurrency], [SalesCurrency], [GLAccount], [Priority], [SiteName], [WarehouseName],
					[LocationName], [ShelfName], [BinName], [CurrentStlNo], [MTBUR], [NE], [NS], [OH], [REP], [SVC], [Figure], [Item], [UNCode], [InventoryGLSettingId], [GoodsReceivedNotInvoicesGLAccId], [WorkInProgressGLAccId], [InventoryToBillGLAccId],
					[FinishedGoodsGLAccId], [InventoryExchAgreementGLAccId], [InventoryReserveGLAccId], [COGS_WorkOrderGLAccId], [COGS_SalesOrderGLAccId], [COGS_QtyVarianceGLAccId], [COGS_UnitCostVarianceGLAccId], [RevenueMroGLAccId], [RevenueSoGLAccId], [RevenueExchGLAccId],
					[COGS_ExchSalesOrderGLAccId], [GoodsReceivedNotInvoicesGLAccName], [WorkInProgressGLAccName], [InventoryToBillGLAccName], [FinishedGoodsGLAccName], [InventoryExchAgreementGLAccName], [InventoryReserveGLAccName], [COGS_WorkOrderGLAccName],
					[COGS_SalesOrderGLAccName], [COGS_QtyVarianceGLAccName], [COGS_UnitCostVarianceGLAccName], [RevenueMroGLAccName], [RevenueSoGLAccName], [RevenueExchGLAccName], [COGS_ExchSalesOrderGLAccName], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate],
					[SyncToken], [WorkOrderFormTypeId] 
			INTO #tmpItemMaster FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @WFItemMasterId;
			
			-- Getting WorkScope Details
			SELECT	[WorkScopeId], [WorkScopeCode], [Description], [Memo], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [WorkScopeCodeNew], [ConditionId]
			INTO #tmpWorkScope FROM [dbo].[WorkScope] WITH(NOLOCK) WHERE [WorkScopeId] = @WFWorkScopeId;

			-- Getting WorkflowChargesList Details
			SELECT	[WorkflowChargesListId], [WorkflowId], [WorkflowChargeTypeId], [Description], [Quantity], [UnitCost], [ExtendedCost], [UnitPrice], [ExtendedPrice], [VendorId], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive],
					[VendorName], [Order], [IsDeleted], [Memo], [WFParentId], [IsVersionIncrease], @chargesTypeName AS [chargesTypeName]
			INTO #tmpWorkflowChargesList FROM [dbo].[WorkflowChargesList] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND ISNULL(IsDeleted, 0) = 0 ORDER BY [Order]
			
			UPDATE	TMP
			SET TMP.chargesTypeName = CH.ChargeType
			FROM #tmpWorkflowChargesList TMP
			LEFT JOIN [dbo].[Charge] CH WITH(NOLOCK) ON TMP.WorkflowChargeTypeId = CH.ChargeId
			
			-- Getting WorkFlowDirection Details
			SELECT	[WorkflowDirectionId], [WorkflowId], [Action], [Description], [Sequence], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Order], [WFParentId], [IsVersionIncrease], [TaskName], 
					[ParentId], [IsParent], [IsTaskDetails]
			INTO #tmpWorkflowDirection FROM [dbo].[WorkflowDirection] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND ISNULL(IsDeleted, 0) = 0 ORDER BY [Order]
			
			UPDATE	TMP
			SET	TMP.CreatedDate = CAST(DBO.ConvertUTCtoLocal(TMP.CreatedDate,@CurrntEmpTimeZoneDesc) AS DATETIME),
				TMP.UpdatedDate = CAST(DBO.ConvertUTCtoLocal(TMP.UpdatedDate,@CurrntEmpTimeZoneDesc) AS DATETIME)
			FROM #tmpWorkflowDirection TMP

			-- Getting WorkflowEquipmentList Details
			SELECT	[WorkflowEquipmentListId], [WorkflowId], [AssetId], [AssetTypeId], [AssetDescription], [Quantity], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [PartNumber], [Order], [Memo], [WFParentId],
					[IsVersionIncrease], [AssetAttributeTypeId], @AssetName AS [AssetName], @AssetId AS [assetIdName], @AssetTypeName AS [AssetTypeName]
			INTO #tmpWorkflowEquipmentList FROM [dbo].[WorkflowEquipmentList] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND ISNULL(IsDeleted, 0) = 0 ORDER BY [Order]
			
			UPDATE	TMP
			SET TMP.[AssetName] = A.[Name],
				TMP.[assetIdName] = A.[AssetId],
				TMP.[AssetTypeName] = ISNULL((SELECT TOP 1
											ta.TangibleClassName
											FROM [dbo].Asset AST WITH(NOLOCK)
											LEFT JOIN [dbo].AssetAttributeType atd WITH(NOLOCK) ON AST.AssetAttributeTypeId = atd.AssetAttributeTypeId
											LEFT JOIN [dbo].TangibleClass ta WITH(NOLOCK) ON atd.TangibleClassId = ta.TangibleClassId
											WHERE AST.AssetAttributeTypeId = TMP.AssetAttributeTypeId 
											AND AST.AssetRecordId = TMP.AssetId), '')
			FROM #tmpWorkflowEquipmentList TMP
			LEFT JOIN [dbo].[Asset] A WITH(NOLOCK) ON TMP.AssetId = A.AssetRecordId

			-- Getting WorkFlowExclusion Details
			SELECT	[WorkflowExclusionId], [WorkflowId], [ItemMasterId], [UnitCost], [Quantity], [ExtendedCost], [EstimtPercentOccurrance], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
					[PartNumber], [PartDescription], [Order], [ConditionId], [ItemClassificationId], [WFParentId], [IsVersionIncrease], @stockType AS [stockType], @ItemClassification AS [ItemClassification], @Condition AS [Condition], @ManufacturerName AS [ManufacturerName]
			INTO #tmpWorkflowExclusion FROM [dbo].[WorkflowExclusion] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND ISNULL(IsDeleted, 0) = 0 ORDER BY [Order]

			UPDATE	TMP
			SET TMP.ItemClassification = ICC.[ItemClassificationCode],
				TMP.Condition = CD.[Description],
				TMP.ManufacturerName = IM.ManufacturerName,
				TMP.stockType = CASE 
									WHEN ISNULL(IM.IsPma, 0) = 1 AND ISNULL(IM.IsDER, 0) = 1 THEN 'PMA&DER'
									WHEN ISNULL(IM.IsPma, 0) = 1 AND ISNULL(IM.IsDER, 0) = 0 THEN 'PMA'
									WHEN ISNULL(IM.IsPma, 0) = 0 AND ISNULL(IM.IsDER, 0) = 1 THEN 'DER'
									ELSE 'OEM'
								END
			FROM #tmpWorkflowExclusion TMP
			LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON TMP.ItemMasterId = IM.ItemMasterId
			LEFT JOIN [dbo].[ItemClassification] ICC WITH(NOLOCK) ON TMP.ItemClassificationId = ICC.ItemClassificationId
			LEFT JOIN [dbo].[Condition] CD WITH(NOLOCK) ON TMP.ConditionId = CD.ConditionId

			-- Getting WorkflowExpertiseList Details
			SELECT [WorkflowExpertiseListId], [WorkflowId], [ExpertiseTypeId], [EstimatedHours], [LaborDirectRate], [DirectLaborRate], [OverheadBurden], [OverheadCost], [StandardRate], [LaborOverheadCost], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],
				   [UpdatedDate], [IsActive], [IsDeleted], [Order], [Memo], [WFParentId], [IsVersionIncrease], [OverheadburdenPercentId], @ExpetiseTypeName AS [ExpetiseTypeName]
			INTO #tmpWorkflowExpertiseList FROM [dbo].[WorkflowExpertiseList] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND ISNULL(IsDeleted, 0) = 0 ORDER BY [WorkflowExpertiseListId]
			
			UPDATE	TMP
			SET	TMP.[ExpetiseTypeName] = EE.[Description]
			FROM #tmpWorkflowExpertiseList TMP
			LEFT JOIN [dbo].[EmployeeExpertise] EE WITH(NOLOCK) ON TMP.ExpertiseTypeId = EE.EmployeeExpertiseId

			-- Getting WorkflowMaterial Details
			SELECT	[WorkflowMaterialListId], [WorkflowId], [ItemMasterId], [TaskId], [Quantity], [UnitOfMeasureId], [ConditionCodeId], [UnitCost], [ExtendedCost], [Price], [ProvisionId], [IsDeferred], [WorkflowActionId], [Memo], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
					[IsActive], [IsDeleted], [MaterialMandatoriesName], [PartNumber], [PartDescription], [ItemClassificationId], [ExtendedPrice], [Order], [MaterialMandatoriesId], [WFParentId], [IsVersionIncrease], [Figure], [Item], @stockType AS [StockType], @ManufacturerName AS [ManufacturerName], @ItemClassification AS [ItemClassification],
					@UnitOfMeasure AS [UnitOfMeasure], @Condition AS [ConditionName]
			INTO #tmpWorkflowMaterial FROM [dbo].[WorkflowMaterial] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND ISNULL(IsDeleted, 0) = 0 ORDER BY [Order]
			
			UPDATE	TMP
			SET	TMP.ItemClassification = ICC.ItemClassificationCode,
				TMP.UnitOfMeasure = UM.ShortName,
				TMP.ConditionName = CD.[Description],
				TMP.ManufacturerName = IM.ManufacturerName,
				TMP.StockType =  CASE 
									WHEN ISNULL(IM.IsPma, 0) = 1 AND ISNULL(IM.IsDER, 0) = 1 THEN 'PMA&DER'
									WHEN ISNULL(IM.IsPma, 0) = 1 AND ISNULL(IM.IsDER, 0) = 0 THEN 'PMA'
									WHEN ISNULL(IM.IsPma, 0) = 0 AND ISNULL(IM.IsDER, 0) = 1 THEN 'DER'
									ELSE 'OEM'
								END
			FROM #tmpWorkflowMaterial TMP
			LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON TMP.ItemMasterId = IM.ItemMasterId
			LEFT JOIN [dbo].[ItemClassification] ICC WITH(NOLOCK) ON TMP.ItemClassificationId = ICC.ItemClassificationId
			LEFT JOIN [dbo].[UnitOfMeasure] UM WITH(NOLOCK) ON TMP.UnitOfMeasureId = UM.UnitOfMeasureId
			LEFT JOIN [dbo].[Condition] CD WITH(NOLOCK) ON TMP.ConditionCodeId = CD.ConditionId

			-- Getting WorkflowMeasurement Details
			SELECT	[WorkflowMeasurementId], [WorkflowId], [Sequence], [Stage], [Min], [Max], [Expected], [DiagramURL], [Memo], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [ItemMasterId], [PartNumber], [Order], [PartDescription], [WFParentId],
					[IsVersionIncrease], @ManufacturerName AS [ManufacturerName]
			INTO #tmpWorkflowMeasurement FROM [dbo].[WorkflowMeasurement] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND ISNULL(IsDeleted, 0) = 0 ORDER BY [Order]
			
			UPDATE	TMP
			SET	TMP.ManufacturerName = IM.ManufacturerName
			FROM #tmpWorkflowMeasurement TMP
			LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON TMP.ItemMasterId = IM.ItemMasterId

			-- Getting WorkflowPublications Details
			SELECT	[WorkflowPublicationsId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsDeleted], [PublicationId], [PublicationDescription], [PublicationType], [Sequence], [Source], [AircraftManufacturer], [Model], [Location], [Revision], [RevisionDate], [VerifiedBy], [VerifiedDate], [Status],
					[Image], [TaskId], [WorkflowId], [MasterCompanyId], [Order], [IsActive], [Memo], [WFParentId], [IsVersionIncrease], @PublicationTypeName AS [PublicationTypeName], @ModelName AS [ModelName], @ManufacturerName AS [AircraftManufacturerName], @PublicationId AS [PublicationName]
			INTO #tmpWorkflowPublications FROM [dbo].[WorkflowPublications] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND ISNULL(IsDeleted, 0) = 0 ORDER BY [Order]
			
			UPDATE	TMP
			SET	TMP.PublicationTypeName = ISNULL(PT.[NAME], ''),
				TMP.ModelName = ACM.ModelName,
				TMP.AircraftManufacturerName = MF.[Name],
				TMP.PublicationName = PB.PublicationId				
			FROM #tmpWorkflowPublications TMP
			LEFT JOIN [dbo].[PublicationType] PT WITH(NOLOCK) ON CAST(TMP.PublicationType AS INT) = PT.PublicationTypeId
			LEFT JOIN [dbo].[AircraftModel] ACM WITH(NOLOCK) ON TMP.Model = ACM.AircraftModelId
			LEFT JOIN [dbo].[Manufacturer] MF WITH(NOLOCK) ON TMP.AircraftManufacturer = MF.ManufacturerId
			LEFT JOIN [dbo].[Publication] PB WITH(NOLOCK) ON TMP.PublicationId = PB.PublicationRecordId

			-- Getting Publications Attachment Details
			SELECT ATD.[AttachmentDetailId], ATD.[AttachmentId], ATD.[FileName], ATD.[Description], ATD.[Link], ATD.[FileFormat], ATD.[FileSize], ATD.[FileType], ATD.[CreatedDate], ATD.[UpdatedDate], ATD.[CreatedBy], ATD.[UpdatedBy], ATD.[IsActive], ATD.[IsDeleted], ATD.[Name], ATD.[Memo], ATD.[TypeId], ATC.[ReferenceId]
			INTO #tmpWorkflowPublicationsAttachmentDetails
			FROM [dbo].[AttachmentDetails] ATD WITH(NOLOCK) 
			LEFT JOIN [dbo].[Attachment] ATC WITH(NOLOCK) ON ATD.AttachmentId = ATC.AttachmentId
			WHERE ATC.ModuleId = @PublicationAttachmentModuleId AND ISNULL(ATD.IsActive, 0) = 1 AND ISNULL(ATD.IsDeleted, 0) = 0 AND ATC.ReferenceId IN (SELECT [PublicationId] FROM #tmpWorkflowPublications)

			--	Getting WorkFlowTask Details
			SELECT [WorkFlowTaskId], [WorkFlowId], [WorkFlowNumber], [TaskId], [TaskDescription], [SequenceNumber], [Descrepancy], [Resolution], [IsVersionIncrease], [WFParentId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
			INTO #tmpWorkFlowTask FROM [dbo].[WorkFlowTask] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND ISNULL(IsDeleted, 0) = 0

			--------------------------------------------------------------------------------  selecting the result --------------------------------------------------------------------------------

			SELECT * FROM #tmpWorkFLow;

			SELECT * FROM #tmpItemMaster;

			SELECT * FROM #tmpWorkScope;

			SELECT * FROM #tmpWorkflowChargesList;

			SELECT * FROM #tmpWorkflowDirection;

			SELECT * FROM #tmpWorkflowEquipmentList;

			SELECT * FROM #tmpWorkflowExclusion;

			SELECT * FROM #tmpWorkflowExpertiseList;

			SELECT * FROM #tmpWorkflowMaterial;

			SELECT * FROM #tmpWorkflowMeasurement;

			SELECT * FROM #tmpWorkflowPublications;

			SELECT * FROM #tmpWorkflowPublicationsAttachmentDetails;

			SELECT * FROM #tmpWorkFlowTask;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkFlowDetails_byId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkflowId, '') + ''
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