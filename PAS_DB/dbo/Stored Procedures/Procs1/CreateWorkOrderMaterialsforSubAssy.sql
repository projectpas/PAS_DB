/*************************************************************           
 ** File:   [dbo].[CreateWorkOrderMaterialsforSubAssy]
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Create a Work Order Materials for Sub Assy : By Rajesh
 ** Purpose:         
 ** Date:   18/03/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18/03/2025   Moin Bloch    Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
--   EXEC [dbo].[CreateWorkOrderMaterialsforSubAssy]
**************************************************************/
CREATE   PROCEDURE [dbo].[CreateWorkOrderMaterialsforSubAssy]
@tbl_WorkOrderPartNumberType WorkOrderPartNumberType READONLY,
@WorkOrderId BIGINT,
@WorkOrderTypeId BIGINT,
@CreatedBy VARCHAR(256),
@CreatedDate DATETIME2(7),
@MasterCompanyId INT,
@WorkOrderFormTypeId BIT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN	
		DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1
		DECLARE @AssemplyTotalRecord INT = 0,@AssemplyMinId BIGINT = 1
		DECLARE @MaterialsTotalRecord INT = 0,@MaterialsMinId BIGINT = 1

		DECLARE @ItemMasterId BIGINT = NULL,@SubWorkorderProvisionEnum INT,@WorkOrderPartNoId BIGINT=0,@WorkFlowWorkOrderId BIGINT=0
		DECLARE @ALLTASKEnum VARCHAR(20) ='',@ARCondition VARCHAR(20) ='',@ASSEMBLEEnum VARCHAR(20) =''
		DECLARE @TaskId BIGINT = NULL,@ConditionId BIGINT = NULL,@WorkOrderTaskId BIGINT = 0,@WorkOrderModuleID INT,@WorkOrderMPNModuleID INT		
		DECLARE @isExistingMaterilas BIT = 0,@IsAutoIssue BIT = 0,@TemplateBody VARCHAR(MAX)=''
	    DECLARE	@MatItemMasterId BIGINT=NULL,@ConditionCodeId BIGINT=NULL,@MatTaskId BIGINT=NULL,@MatItemClassificationId BIGINT=NULL,@PurchaseUnitOfMeasureId BIGINT=NULL
		DECLARE @Item NVARCHAR(100),@Figure NVARCHAR(100),@WorkOrderMaterialsId BIGINT=0
		DECLARE @QtyToTurnIn INT=0,@ManQuantity	INT=0,@UnitOfMeasureId BIGINT=NULL,@StockLineId BIGINT=NULL
		DECLARE	@ProvisionId BIGINT=NULL,@SubItemMasterId BIGINT=NULL,@MappingItemMasterId BIGINT=NULL,@ItemClassificationId BIGINT=NULL,@Quantity INT=0
		DECLARE @MatProvisionId BIGINT=NULL,@IsAltPart BIT=0,@AltPartMasterPartId BIGINT=NULL,@IsAlternatePart BIGINT=NULL,@IsEquPart BIT=0,@EquPartMasterPartId BIGINT=NULL
		DECLARE @UnitCost DECIMAL(18,2)=0

		SELECT @SubWorkorderProvisionEnum = [ProvisionId] FROM [dbo].[Provision] WITH(NOLOCK) WHERE [Description] = 'SUB WORK ORDER'

		SELECT @WorkOrderModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrder';

		SELECT @WorkOrderMPNModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrderMPN';

		SELECT @ALLTASKEnum = [Description] FROM [dbo].[Task] WITH(NOLOCK) WHERE [Description] = 'ALL TASK' AND [MasterCompanyId] = @MasterCompanyId;

		SELECT @ARCondition = [Description] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [Description] = 'AR' AND [MasterCompanyId] = @MasterCompanyId;

		SELECT @ASSEMBLEEnum = [Description] FROM [dbo].[Task] WITH(NOLOCK) WHERE [Description] = 'ASSEMBLE' AND [MasterCompanyId] = @MasterCompanyId;
			   									
		IF OBJECT_ID(N'tempdb..#tempCreateWorkOrderMaterialsforSubAssyForCreateWO') IS NOT NULL
		BEGIN
			DROP TABLE #tempCreateWorkOrderMaterialsforSubAssyForCreateWO
		END		
		IF OBJECT_ID(N'tempdb..#tempsubAssyListForCreateWO') IS NOT NULL
		BEGIN
			DROP TABLE #tempsubAssyListForCreateWO
		END		
		IF OBJECT_ID(N'tempdb..#tempWorkOrderTaskIdForCreateWO') IS NOT NULL
		BEGIN
			DROP TABLE #tempWorkOrderTaskIdForCreateWO
		END
		IF OBJECT_ID(N'tempdb..#tempWorkOrderMaterialsforSubAssy') IS NOT NULL
		BEGIN
			DROP TABLE #tempWorkOrderMaterialsforSubAssy
		END	
	
		CREATE TABLE #tempCreateWorkOrderMaterialsforSubAssyForCreateWO
		(
			[PKID] [BIGINT] NOT NULL IDENTITY, 
			[ID] [BIGINT] NULL,
			[ItemMasterId] [BIGINT] NULL
		)

		CREATE TABLE #tempsubAssyListForCreateWO
		(
			[ASYID] [BIGINT] NOT NULL IDENTITY, 			
			[MappingItemMasterId] [BIGINT] NULL,
			[ItemMasterId] [BIGINT] NULL,
			[Quantity] INT NULL,
			[ProvisionId] [BIGINT] NULL
		)

		CREATE TABLE #tempWorkOrderTaskIdForCreateWO
		(					
			[WorkOrderTaskId] [BIGINT] NULL			
		)		

		CREATE TABLE #tempWorkOrderMaterialsforSubAssy
		(
			[MID] [BIGINT] NOT NULL IDENTITY, 
			[ProvisionId] [BIGINT] NULL,
			[WorkOrderId] [BIGINT] NULL,
			[WorkFlowWorkOrderId] [BIGINT] NULL,
			[ItemMasterId] [BIGINT] NULL,
			[MasterCompanyId] [INT] NULL,
			[CreatedBy] [VARCHAR](256) NULL,
			[UpdatedBy] [VARCHAR](256) NULL,
			[CreatedDate] [DATETIME2](7) NULL,
			[UpdatedDate] [DATETIME2](7) NULL,
			[IsActive] [BIT] NULL,
			[IsDeleted] [BIT] NULL,
			[TaskId] [BIGINT] NULL,
			[ItemClassificationId] [BIGINT] NULL,
			[Quantity] [INT] NULL,
			[ConditionCodeId] [BIGINT] NULL,
			[MaterialMandatoriesId] [INT] NULL,
			[Item] [NVARCHAR](100) NULL,
			[Figure] [NVARCHAR](100) NULL,
			[WorkOrderMaterialsId] [BIGINT] NULL,
			[isExistingMaterilas] [BIT] NULL,
			[QtyToTurnIn] [INT] NULL,
			[UnitOfMeasureId] [BIGINT] NULL,
			[StockLineId] [BIGINT] NULL,
			[IsAltPart] [BIT] NULL,
			[AltPartMasterPartId] [BIGINT] NULL,
			[IsAlternatePart] [BIGINT] NULL,
			[IsEquPart] [BIT] NULL,
			[EquPartMasterPartId] [BIGINT] NULL,
			[UnitCost] [DECIMAL](18,2) NULL,
			[ExtendedCost] [DECIMAL](18,2) NULL,
			[Memo] [NVARCHAR](MAX) NULL,
			[IsDeferred] [bit] NULL,
	        [QuantityReserved] [int] NULL,
	        [QuantityIssued] [int] NULL,
	        [IssuedDate] [datetime2](7) NULL,
	        [ReservedDate] [datetime2](7) NULL,
	        [IsFromWorkFlow] [bit] NULL,
	        [PartStatusId] [int] NULL,
	        [UnReservedQty] [int] NULL,
	        [UnIssuedQty] [int] NULL,
	        [IssuedById] [bigint] NULL,
	        [ReservedById] [bigint] NULL,
	        [ParentWorkOrderMaterialsId] [bigint] NULL,
	        [ItemMappingId] [bigint] NULL,
	        [TotalReserved] [int] NULL,
	        [TotalIssued] [int] NULL,
	        [TotalUnReserved] [int] NULL,
	        [TotalUnIssued] [int] NULL,
	        [WOPartNoId] [bigint] NULL,
	        [TotalStocklineQtyReq] [int] NULL,
	        [QtyOnOrder] [int] NULL,
	        [QtyOnBkOrder] [int] NULL,
	        [POId] [bigint] NULL,
	        [PONum] [varchar](100) NULL,
	        [PONextDlvrDate] [datetime] NULL,
	        [isfromsubWorkOrder] [bit] NULL,
	        [ExpectedSerialNumber] [varchar](30) NULL,
			[StocklineQuantity] [int] NULL
		)
				
		INSERT INTO #tempCreateWorkOrderMaterialsforSubAssyForCreateWO([ID],[ItemMasterId])
		SELECT [ID],[ItemMasterId] FROM @tbl_WorkOrderPartNumberType
		
		SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tempCreateWorkOrderMaterialsforSubAssyForCreateWO  

		WHILE @MinId <= @TotalRecord
		BEGIN
			SELECT @WorkOrderPartNoId=[ID],@ItemMasterId = [ItemMasterId] FROM #tempCreateWorkOrderMaterialsforSubAssyForCreateWO WHERE [PKID] = @MinId

			IF(@ItemMasterId > 0)
			BEGIN				
				INSERT INTO #tempsubAssyListForCreateWO([MappingItemMasterId],[ItemMasterId],[Quantity],[ProvisionId])
				SELECT [MappingItemMasterId],[ItemMasterId],[Quantity],[ProvisionId] FROM [dbo].[Assemply] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId AND [ProvisionId] = @SubWorkorderProvisionEnum AND [PopulateWoMaterialList] = 1 AND [IsActive] = 1 AND [IsDeleted] = 0
			
				SELECT TOP 1 @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId] = @WorkOrderPartNoId;

				SELECT @AssemplyTotalRecord = COUNT(*), @AssemplyMinId = MIN([ASYID]) FROM #tempsubAssyListForCreateWO  

				IF(@AssemplyTotalRecord > 0)
				BEGIN
					SELECT TOP 1 @TaskId = [TaskId] FROM [dbo].[Task] WITH(NOLOCK) WHERE [Description] = @ALLTASKEnum AND [MasterCompanyId] = @MasterCompanyId;

					SELECT @ConditionId = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [Description] = @ARCondition AND [MasterCompanyId] = @MasterCompanyId;

					IF(@WorkOrderFormTypeId = 1)
					BEGIN
						DECLARE @TTaskId BIGINT=0,@Description VARCHAR(200)='',@Descrepancy NVARCHAR(MAX),@Resolution NVARCHAR(MAX),@IsPrintInWO BIT,@IsPrintInWOQ BIT

						SELECT TOP 1 @TTaskId = [TaskId],
						             @Description = [Description],
									 @Descrepancy = [Descrepancy],
									 @Resolution = [Resolution],
									 @IsPrintInWO = ISNULL([IsPrintInWO],0),
									 @IsPrintInWOQ = ISNULL([IsPrintInWOQ],0)
						        FROM [dbo].[Task] WITH(NOLOCK) 
							   WHERE [Description] = @ASSEMBLEEnum AND [MasterCompanyId] = @MasterCompanyId;

                        INSERT INTO	#tempWorkOrderTaskIdForCreateWO([WorkOrderTaskId])										 
						EXEC [dbo].[USP_AddUpdateWorkOrderTasks] @WorkOrderTaskId,@WorkOrderId,@WorkFlowWorkOrderId,@TTaskId,@Description,NULL,NULL,@WorkOrderPartNoId,NULL,NULL,0,NULL,'',NULL,NULL,NULL,NULL,@Descrepancy,@Resolution,@CreatedBy,@MasterCompanyId,@IsPrintInWO,@IsPrintInWOQ,NULL,NULL

						SET @WorkOrderTaskId = (SELECT TOP 1 [WorkOrderTaskId] from #tempWorkOrderTaskIdForCreateWO) 

						DELETE FROM #tempWorkOrderTaskIdForCreateWO
					END
					
					WHILE @AssemplyMinId <= @AssemplyTotalRecord
					BEGIN
						SELECT @ProvisionId=[ProvisionId],
						       @SubItemMasterId = [ItemMasterId],
							   @MappingItemMasterId=[MappingItemMasterId], 
							   @Quantity = [Quantity]
						  FROM #tempsubAssyListForCreateWO WHERE [ASYID] = @AssemplyMinId

						IF(@ProvisionId > 0 AND @SubItemMasterId > 0)
						BEGIN
							SELECT @ItemClassificationId = [ItemClassificationId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @MappingItemMasterId AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 ;

							INSERT INTO #tempWorkOrderMaterialsforSubAssy([ProvisionId],[WorkOrderId],[WorkFlowWorkOrderId],[ItemMasterId],[MasterCompanyId],[CreatedBy],[UpdatedBy],
								   [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[TaskId],[ItemClassificationId],[Quantity],[ConditionCodeId],[MaterialMandatoriesId])
							SELECT @ProvisionId,@WorkOrderId,@WorkFlowWorkOrderId,@MappingItemMasterId,@MasterCompanyId,@CreatedBy,@CreatedBy,
								   @CreatedDate,@CreatedDate,1,0,CASE WHEN @WorkOrderFormTypeId = 1 THEN @WorkOrderTaskId ELSE @TaskId END,@ItemClassificationId,
								   CASE WHEN @Quantity > 0 THEN @Quantity ELSE 1 END,@ConditionId,1		
						END
						SET @AssemplyMinId = @AssemplyMinId + 1
					END
					DELETE FROM #tempsubAssyListForCreateWO;		
					
					-- CreateWorkOrderMaterials

					SELECT @MaterialsTotalRecord = COUNT(*), @MaterialsMinId = MIN([MID]) FROM #tempWorkOrderMaterialsforSubAssy  

					WHILE @MaterialsMinId <= @MaterialsTotalRecord
					BEGIN							

						SELECT @MatItemMasterId=[ItemMasterId],@ConditionCodeId=[ConditionCodeId],@MatTaskId=[TaskId],@Item=[Item],@Figure=[Figure]
						  FROM #tempWorkOrderMaterialsforSubAssy WHERE [MID] = @MaterialsMinId
						  						  
						SELECT TOP 1 @WorkOrderMaterialsId = [WorkOrderMaterialsId] FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK)
						WHERE [ItemMasterId] = @MatItemMasterId AND [ConditionCodeId] = @ConditionCodeId AND [TaskId] = @MatTaskId 
						AND [Item] = @Item AND [Figure] = @Figure AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [WorkOrderId] = @WorkOrderId

						IF(@WorkOrderMaterialsId > 0)
						BEGIN
							UPDATE #tempWorkOrderMaterialsforSubAssy 
							   SET [WorkOrderMaterialsId] = @WorkOrderMaterialsId,
							       [isExistingMaterilas] = 1							
							 WHERE [MID] = @MaterialsMinId;
							  
							  SET  @isExistingMaterilas = 1;
						END					
						SET @MaterialsMinId = @MaterialsMinId + 1
					END

					SELECT TOP 1 @IsAutoIssue = [IsAutoIssue] FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [WorkOrderTypeId] = @WorkOrderTypeId AND [MasterCompanyId] = @MasterCompanyId

					--Add Entry in History Table
					IF(@isExistingMaterilas = 0)
					BEGIN
						DECLARE @AddPNPart VARCHAR(20)='AddPN';
						DECLARE @MatQuantity INT=0,@SumOFQuantity INT=0
						DECLARE @PartNumber VARCHAR(50)='AddPN';						

						SELECT TOP 1 @WorkOrderMaterialsId = [WorkOrderMaterialsId],
						             @WorkFlowWorkOrderId=[WorkFlowWorkOrderId],
									 @ItemMasterId = [ItemMasterId],
									 @Quantity = [Quantity]
								FROM #tempWorkOrderMaterialsforSubAssy

						SELECT @WorkOrderPartNoId = [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId

						SELECT @PartNumber = [PartNumber] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId

						 AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0
						 SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @AddPNPart;

						SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', @PartNumber)
						
						IF(@WorkOrderMaterialsId > 0)
						BEGIN
							SELECT TOP 1 @MatQuantity = [Quantity] FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId
							SET @SumOFQuantity = @MatQuantity + @Quantity
						END	
						ELSE
						BEGIN
							SET @MatQuantity = 0
							SET @SumOFQuantity = @Quantity
						END

						EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,@WorkOrderMPNModuleID,@WorkOrderPartNoId,@MatQuantity,@SumOFQuantity,@TemplateBody,'AddPN',@MasterCompanyId,@CreatedBy,@CreatedDate,@CreatedBy,@CreatedDate
						
					END
					
				   --Need To Discuss AT The Time Of Create Materials Update Materials Not Use
				    IF(@isExistingMaterilas = 1)
				    BEGIN 
						PRINT 'UpdateWorkOrderMaterials'
						--return UpdateWorkOrderMaterials(workOrderMaterials);
					END
					ELSE
					BEGIN

						SELECT TOP 1 @ProvisionId = [ProvisionId] FROM [dbo].[Provision] WITH(NOLOCK) WHERE [ProvisionId] = @SubWorkorderProvisionEnum AND [IsActive] = 1 AND [IsDeleted] = 0

						SELECT @MaterialsTotalRecord = COUNT(*), @MaterialsMinId = MIN([MID]) FROM #tempWorkOrderMaterialsforSubAssy  

						WHILE @MaterialsMinId <= @MaterialsTotalRecord
						BEGIN	
							SELECT @MatItemMasterId = [ItemMasterId],
								   @MatItemClassificationId = ISNULL([ItemClassificationId],0),
								   @MatProvisionId = [ProvisionId],
								   @QtyToTurnIn = ISNULL([QtyToTurnIn],0),
								   @ManQuantity = ISNULL([Quantity],0),
								   @UnitOfMeasureId = ISNULL([UnitOfMeasureId],0),
								   @StockLineId = [StockLineId],
								   @IsAltPart = ISNULL([IsAltPart],0),
								   @IsAlternatePart = [IsAlternatePart],
								   @IsEquPart = ISNULL([IsEquPart],0)
							  FROM #tempWorkOrderMaterialsforSubAssy WHERE [MID] = @MaterialsMinId

							  IF(@MatItemClassificationId = 0)
							  BEGIN
									SELECT @MatItemClassificationId = [ItemClassificationId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @MatItemMasterId
							   AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0
									 END
							  IF(@MatProvisionId = @ProvisionId)
							  BEGIN
									SET @QtyToTurnIn = @ManQuantity;
									SET @ManQuantity = 0;		
							  END
							  IF(@UnitOfMeasureId = 0)
							  BEGIN
									IF(@StockLineId > 0)
									BEGIN
										SELECT @PurchaseUnitOfMeasureId = [PurchaseUnitOfMeasureId] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId
									END
									ELSE
									BEGIN
										SELECT @PurchaseUnitOfMeasureId = [ItemClassificationId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @MatItemMasterId
									 AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0
										 END
							  END
							  IF(@IsAltPart=1)
							  BEGIN
									SET @IsAltPart = @IsAltPart
									SET @AltPartMasterPartId = @IsAlternatePart
							  END
							  IF(@IsEquPart=1)
							  BEGIN
									SET @IsEquPart = @IsEquPart
									SET @EquPartMasterPartId = @IsAlternatePart
							  END
						  
							  UPDATE #tempWorkOrderMaterialsforSubAssy 
								 SET [ItemClassificationId] = @MatItemClassificationId,
									 [QtyToTurnIn] = @QtyToTurnIn,
									 [Quantity] = @ManQuantity,
									 [UnitOfMeasureId] = @PurchaseUnitOfMeasureId,
									 [IsAltPart] = @IsAltPart,
									 [AltPartMasterPartId] = @AltPartMasterPartId,
									 [IsEquPart] = @IsEquPart,
									 [EquPartMasterPartId] = @EquPartMasterPartId
							   WHERE [MID] = @MaterialsMinId

							  INSERT INTO [dbo].[WorkOrderMaterials]([WorkOrderId],[WorkFlowWorkOrderId],[ItemMasterId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
										 ,[IsActive],[IsDeleted],[TaskId],[ConditionCodeId],[ItemClassificationId],[Quantity],[UnitOfMeasureId],[UnitCost],[ExtendedCost],[Memo],[IsDeferred]
										 ,[QuantityReserved],[QuantityIssued],[IssuedDate],[ReservedDate],[IsAltPart],[AltPartMasterPartId],[IsFromWorkFlow],[PartStatusId],[UnReservedQty]
										 ,[UnIssuedQty],[IssuedById],[ReservedById],[IsEquPart],[ParentWorkOrderMaterialsId],[ItemMappingId],[TotalReserved],[TotalIssued],[TotalUnReserved]
										 ,[TotalUnIssued],[ProvisionId],[MaterialMandatoriesId],[WOPartNoId],[TotalStocklineQtyReq],[QtyOnOrder],[QtyOnBkOrder],[POId],[PONum],[PONextDlvrDate]
										 ,[QtyToTurnIn],[Figure],[Item],[EquPartMasterPartId],[isfromsubWorkOrder],[ExpectedSerialNumber])
								  SELECT @WorkOrderId,[WorkFlowWorkOrderId],[ItemMasterId],@MasterCompanyId,@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate
										,[IsActive],[IsDeleted],[TaskId],[ConditionCodeId],[ItemClassificationId],ISNULL([Quantity],0),[UnitOfMeasureId],ISNULL([UnitCost],0),ISNULL([ExtendedCost],0),[Memo],[IsDeferred]
										,ISNULL([QuantityReserved],0),ISNULL([QuantityIssued],0),[IssuedDate],[ReservedDate],[IsAltPart],[AltPartMasterPartId],[IsFromWorkFlow],[PartStatusId],[UnReservedQty]
										,[UnIssuedQty],CASE WHEN [IssuedById] = 0 THEN NULL ELSE [IssuedById] END,CASE WHEN [ReservedById] = 0 THEN NULL ELSE [ReservedById] END,[IsEquPart],[ParentWorkOrderMaterialsId],[ItemMappingId],[TotalReserved],[TotalIssued],[TotalUnReserved]
										,[TotalUnIssued],[ProvisionId],CASE WHEN [MaterialMandatoriesId] = 0 THEN NULL ELSE [MaterialMandatoriesId] END,0,ISNULL([TotalStocklineQtyReq],0),ISNULL([QtyOnOrder],0),ISNULL([QtyOnBkOrder],0),[POId],[PONum],[PONextDlvrDate]
										,ISNULL([QtyToTurnIn],0),[Figure],[Item],[EquPartMasterPartId],[isfromsubWorkOrder],[ExpectedSerialNumber]
								   FROM #tempWorkOrderMaterialsforSubAssy WHERE [MID] = @MaterialsMinId

							  SET @WorkOrderMaterialsId = SCOPE_IDENTITY();

							  UPDATE #tempWorkOrderMaterialsforSubAssy 
								SET [WorkOrderMaterialsId] = @WorkOrderMaterialsId					     
							   WHERE [MID] = @MaterialsMinId

							  IF(@StockLineId > 0)
							  BEGIN
								SELECT @UnitCost = [UnitCost] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

								INSERT INTO [dbo].[WorkOrderMaterialStockLine]([WorkOrderMaterialsId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],[QtyIssued]
										   ,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId]
										   ,[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure]
										   ,[Item],[RepairOrderPartRecordId],[ReferenceNumber],[ReservedById],[ReservedDate],[IssuedById],[IssuedDate])
									 SELECT @WorkOrderMaterialsId,@StockLineId,[ItemMasterId],[ConditionCodeId],[StocklineQuantity],0,0
										   ,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],CASE WHEN [IsAltPart]=1 THEN [IsAlternatePart] ELSE NULL END,NULL
										   ,[IsAltPart],[IsEquPart],[UnitCost],([UnitCost]*[StocklineQuantity]),[UnitCost],([UnitCost]*[StocklineQuantity]),[ProvisionId],NULL,0,[Figure]
										   ,[Item],NULL,NULL,NULL,NULL,[IssuedById],[IssuedDate]									   
									 FROM #tempWorkOrderMaterialsforSubAssy WHERE [MID] = @MaterialsMinId
							 END

							  SET @MaterialsMinId = @MaterialsMinId + 1
						 END

						 SELECT TOP 1 @WorkFlowWorkOrderId = [WorkFlowWorkOrderId],@WorkOrderMaterialsId = [WorkOrderMaterialsId]  FROM #tempWorkOrderMaterialsforSubAssy

						 -- Auto Reserve Issue WorkOrder Materials
						
						 EXEC [dbo].[USP_AutoReserveIssueWorkOrderMaterials] @WorkFlowWorkOrderId,@CreatedBy
                         
						 -- Upadte Materials Cost
						 EXEC [dbo].[USP_UpdateWOMaterialsCost] @WorkOrderMaterialsId
						 
						 -- Update WO Total Cost Details
						 EXEC [dbo].[USP_UpdateWOTotalCostDetails] @WorkOrderId,@WorkFlowWorkOrderId,@CreatedBy,@MasterCompanyId
						
						 -- Update WO Cost Details SP
						 EXEC [dbo].[USP_UpdateWOCostDetails] @WorkOrderId,@WorkFlowWorkOrderId,@CreatedBy,@MasterCompanyId
					 
					 END
					 -- var isValid = false; // Will enable it once WO auto issue functionality implement 

					 -- *************** CREATE A TENDER STOCKLINE FOR SUB WORK ORDER FOR SUB ASSY TENDER STOCK : BY DEVENDRA ***************

					 SELECT @MaterialsTotalRecord = COUNT(*), @MaterialsMinId = MIN([MID]) FROM #tempWorkOrderMaterialsforSubAssy  
					 
					 WHILE @MaterialsMinId <= @MaterialsTotalRecord
					 BEGIN
						SELECT @WorkFlowWorkOrderId = [WorkFlowWorkOrderId],
						       @WorkOrderMaterialsId = [WorkOrderMaterialsId]
						  FROM #tempWorkOrderMaterialsforSubAssy WHERE [MID] = @MaterialsMinId

						EXEC [dbo].[USP_TenderStockLineForSubAssembly] @WorkOrderId,@WorkFlowWorkOrderId,@WorkOrderMaterialsId

						SET @MaterialsMinId = @MaterialsMinId + 1
					 END
					
					 /*************** CREATE A TENDER STOCKLINE FOR SUB WORK ORDER FOR SUB ASSY TENDER STOCK : BY HEMANT ***************/
					 EXEC [dbo].[CreateSubWorkOrderForTenderStockline] @WorkOrderId,@WorkOrderPartNoId,@CreatedBy
					
					 DELETE FROM #tempWorkOrderMaterialsforSubAssy
				END							   			
			END
								
			SET @MinId = @MinId + 1
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
              , @AdhocComments     VARCHAR(150)    = 'CreateWorkOrderMaterialsforSubAssy' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@CreatedBy, '') AS VARCHAR(100))
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