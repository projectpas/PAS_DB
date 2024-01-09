/*************************************************************             
 ** File:   [MigrateWOMaterialRecords]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate Work Order Header Records
 ** Purpose:           
 ** Date:   12/18/2023

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    01/02/2024   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigrateWOMaterialRecords @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=12,@UserName=N'ROGER BENTLY',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigrateWOMaterialRecords]
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

		IF OBJECT_ID(N'tempdb..#TempWOMaterial') IS NOT NULL
		BEGIN
			DROP TABLE #TempWOMaterial
		END

		CREATE TABLE #TempWOMaterial
		(
			ID bigint NOT NULL IDENTITY,
			[WorkOrderMaterialId] [bigint] NOT NULL,
			[WorkOrderId] [bigint] NULL,
			[ItemMasterId] [bigint] NULL,
			[SystemUserId] [bigint] NULL,
			[PartConditionCodeId] [bigint] NULL,
			[QtyNeeded] [int] NULL,
			[QtyReserved] [int] NULL,
			[QtyIssued] [int] NULL,
			[QtyTurn] [int] NULL,
			[CondLevel] [varchar](100) NULL,
			[Notes] [varchar](MAX) NULL,
			[WorkOrderTaskId] [bigint] NULL,
			[UnitPrice] [decimal](18, 2) NULL,
			[Requisition] [varchar](100) NULL,
			[IsROPartLinked] [varchar](10) NULL,
			[IsPOPartLinked] [varchar](10) NULL,
			[IsCQDetailLinked] [varchar](10) NULL,
			[EstCost] [decimal](18, 2) NULL,
			[NeedDate] [datetime2](7) NULL,
			[QtyScrapped] [int] NULL,
			[QtyServiceable] [int] NULL,
			[Figure] [varchar](256) NULL,
			[ConsignmentCodeId] [bigint] NULL,
			[QtySpare] [int] NULL,
			[QtyPurchase] [int] NULL,
			[Priority] [varchar](100) NULL,
			[ItemNumber] [varchar](100) NULL,
			[Remarks] [varchar](max) NULL,
			[OperationMasterId] [bigint] NULL,
			[EntryDate] [datetime2](7) NULL,
			[MasterCompanyId] [bigint] NULL,
			[Migrated_Id] [bigint] NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL,
		)

		INSERT INTO #TempWOMaterial ([WorkOrderMaterialId],[WorkOrderId],[ItemMasterId],[SystemUserId],[PartConditionCodeId],[QtyNeeded],[QtyReserved],[QtyIssued],[QtyTurn],[CondLevel],[Notes],[WorkOrderTaskId],
		[UnitPrice],[Requisition],[IsROPartLinked],[IsPOPartLinked],[IsCQDetailLinked],[EstCost],[NeedDate],[QtyScrapped],[QtyServiceable],[Figure],[ConsignmentCodeId],[QtySpare],[QtyPurchase],[Priority],[ItemNumber],
		[Remarks],[OperationMasterId],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT [WorkOrderMaterialId],[WorkOrderId],[ItemMasterId],[SystemUserId],[PartConditionCodeId],[QtyNeeded],[QtyReserved],[QtyIssued],[QtyTurn],[CondLevel],[Notes],[WorkOrderTaskId],
		[UnitPrice],[Requisition],[IsROPartLinked],[IsPOPartLinked],[IsCQDetailLinked],[EstCost],[NeedDate],[QtyScrapped],[QtyServiceable],[Figure],[ConsignmentCodeId],[QtySpare],[QtyPurchase],[Priority],[ItemNumber],
		[Remarks],[OperationMasterId],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
		FROM [Quantum_Staging].dbo.[WorkOrderMaterials] WOM WITH (NOLOCK) WHERE WOM.Migrated_Id IS NULL;

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempWOMaterial;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;
			
			DECLARE @WOO_AUTO_KEY BIGINT = NULL, @PCC_AUTO_KEY BIGINT = NULL, @PNM_AUTO_KEY BIGINT = NULL, @PTC_AUTO_KEY BIGINT = NULL, @UOM_AUTO_KEY BIGINT = NULL;
			DECLARE @WorkOrderId BIGINT = NULL;
			DECLARE @WorkFlowWorkOrderId BIGINT = NULL;
			DECLARE @QuantumPartNumber VARCHAR(100);
			DECLARE @QuantumWorkOrderNum VARCHAR(100);
			DECLARE @WOM_PartId BIGINT = NULL, @WOM_TaskId BIGINT = NULL, @ConditionCodeId BIGINT = NULL, @ItemClassificationId BIGINT = NULL;
			DECLARE @UOMId BIGINT;
			DECLARE @ProvisionId BIGINT;

			DECLARE @FoundError BIT = 0;
			DECLARE @ErrorMsg VARCHAR(MAX) = '';
			DECLARE @CurrentWorkOrderMaterialId BIGINT = 0;

			SELECT @CurrentWorkOrderMaterialId = WorkOrderMaterialId, @WOO_AUTO_KEY = WorkOrderId, @PCC_AUTO_KEY = PartConditionCodeId, @PNM_AUTO_KEY = ItemMasterId FROM #TempWOMaterial WHERE ID = @LoopID;
			
			DECLARE @WO_MPNId BIGINT = NULL;
			DECLARE @WO_MPNId_PAS BIGINT = NULL;

			SELECT @WO_MPNId = WO.ItemMasterId FROM Quantum_Staging.dbo.WorkOrderHeaders WO WHERE WorkOrderId = @WOO_AUTO_KEY;
			SELECT @WO_MPNId_PAS = IM.Migrated_Id FROM Quantum_Staging.dbo.ItemMasters IM WHERE IM.ItemMasterId = @WO_MPNId AND IM.MasterCompanyId = @FromMasterComanyID;

			SELECT @QuantumPartNumber = PartNumber, @PTC_AUTO_KEY = IM.ItemClassificationId, @UOM_AUTO_KEY = UnitOfMeasureId FROM Quantum_Staging.dbo.ItemMasters IM WHERE ItemMasterId = @PNM_AUTO_KEY;
			SELECT @WOM_PartId  = ItemMasterId FROM dbo.[ItemMaster] WHERE UPPER(partnumber) = UPPER(@QuantumPartNumber) AND MasterCompanyId = @FromMasterComanyID;
			SELECT @QuantumWorkOrderNum = WOH.WorkOrderNumber FROM Quantum_Staging.dbo.WorkOrderHeaders WOH WHERE WOH.WorkOrderId = @WOO_AUTO_KEY;
			SELECT @WorkOrderId = WO.WorkOrderId FROM dbo.WorkOrder WO WHERE UPPER(WO.WorkOrderNum) = UPPER(@QuantumWorkOrderNum) AND MasterCompanyId = @FromMasterComanyID;
			SELECT @WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId FROM dbo.[WorkOrderWorkFlow] WOWF WHERE WOWF.WorkOrderId = @WorkOrderId AND MasterCompanyId = @FromMasterComanyID;
			SELECT @WOM_TaskId  = TaskId FROM dbo.[Task] WHERE UPPER([Description]) = UPPER('ASSEMBLE') AND MasterCompanyId = @FromMasterComanyID;
			SELECT @ConditionCodeId = ConditionId FROM DBO.[Condition] C WHERE UPPER(C.Code) IN (SELECT UPPER(CC.CONDITION_CODE) FROM [Quantum].QCTL_NEW_3.PART_CONDITION_CODES CC Where CC.PCC_AUTO_KEY = @PCC_AUTO_KEY) AND MasterCompanyId = @FromMasterComanyID;
			SELECT @ItemClassificationId = ItemClassificationId FROM DBO.ItemClassification IC WHERE UPPER(IC.Description) IN (SELECT UPPER(DESCRIPTION) FROM [Quantum].QCTL_NEW_3.PN_TYPE_CODES Where PTC_AUTO_KEY = @PTC_AUTO_KEY) AND MasterCompanyId = @FromMasterComanyID;
			SELECT @UOMId = UnitOfMeasureId FROM DBO.UnitOfMeasure MF WHERE UPPER(MF.ShortName) IN (SELECT UPPER(UOM_CODE) FROM [Quantum].QCTL_NEW_3.UOM_CODES Where UOM_AUTO_KEY = @UOM_AUTO_KEY) AND MasterCompanyId = @FromMasterComanyID;
			SELECT @ProvisionId  = ProvisionId FROM dbo.[Provision] WHERE UPPER([StatusCode]) = UPPER('REPLACE');

			IF (ISNULL(@WorkOrderId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Work Order not found</p>'
			END
			IF (ISNULL(@WorkFlowWorkOrderId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>WorkFlow Work Order Id not found</p>'
			END
			
			IF (@FoundError = 1)
			BEGIN
				UPDATE WOM
				SET WOM.ErrorMsg = @ErrorMsg
				FROM [Quantum_Staging].DBO.[WorkOrderMaterials] WOM WHERE WOM.WorkOrderMaterialId = @CurrentWorkOrderMaterialId;

				SET @RecordsWithError = @RecordsWithError + 1;
			END

			DECLARE @InsertedWorkOrderMaterialId BIGINT;
			DECLARE @InsertedWorkOrderMaterialKitId BIGINT;

			IF (@FoundError = 0)
			BEGIN
				DECLARE @WTM_AUTO_KEY BIGINT = NULL;
				DECLARE @WOT_AUTO_KEY BIGINT = NULL;

				SELECT @WTM_AUTO_KEY = WTM.WTM_AUTO_KEY FROM [Quantum].QCTL_NEW_3.WO_TASK_MASTER WTM WITH (NOLOCK) WHERE WTM.DESCRIPTION LIKE '100% KIT';
				SELECT @WOT_AUTO_KEY = WOT_AUTO_KEY FROM [Quantum].QCTL_NEW_3.WO_TASK WHERE WOO_AUTO_KEY = @WOO_AUTO_KEY AND WTM_AUTO_KEY = @WTM_AUTO_KEY;

				DECLARE @WOPartNoId BIGINT = NULL;
				SELECT @WOPartNoId = WOPN.ID FROM DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) WHERE WOPN.WorkOrderId = @WorkOrderId;

				IF EXISTS (SELECT TOP 1 1 FROM [Quantum_Staging].DBO.WorkOrderMaterials WOM WITH (NOLOCK) WHERE WOM.WorkOrderMaterialId = @CurrentWorkOrderMaterialId AND WOM.WorkOrderTaskId = @WOT_AUTO_KEY)
				BEGIN
					/* INSERT PARTS as a KIT Material */
					DECLARE @KitMasterId BIGINT = NULL;

					IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.KitMaster KM WITH (NOLOCK) WHERE KM.ItemMasterId = @WO_MPNId_PAS AND KM.MasterCompanyId = @FromMasterComanyID)
					BEGIN
						INSERT INTO DBO.KitMaster ([KitNumber],[ItemMasterId],[ManufacturerId],[PartNumber],[PartDescription],[Manufacturer],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],
						[UpdatedDate],[IsActive],[IsDeleted],[CustomerId],[CustomerName],[KitCost],[KitDescription],[WorkScopeId],[WorkScopeName],[Memo])
						SELECT '100% KIT', @WO_MPNId_PAS,NULL, IM.partnumber, IM.PartDescription, IM.ManufacturerName, @FromMasterComanyID, @UserName, @UserName, GETUTCDATE(),
						GETUTCDATE(), 1, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL
						FROM DBO.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId = @WO_MPNId_PAS;

						SELECT @KitMasterId = SCOPE_IDENTITY();
					END
					ELSE
					BEGIN
						SELECT @KitMasterId = KM.KitId FROM DBO.KitMaster KM WITH (NOLOCK) WHERE KM.ItemMasterId = @WO_MPNId_PAS AND KM.MasterCompanyId = @FromMasterComanyID;
					END

					DECLARE @WorkOrderMaterialsKitMappingId BIGINT = NULL;

					IF NOT EXISTS (SELECT * FROM DBO.WorkOrderMaterialsKitMapping WOKM WITH (NOLOCK) WHERE WOKM.WOPartNoId = @WOPartNoId AND WOKM.ItemMasterId = @WO_MPNId_PAS AND WOKM.MasterCompanyId = @FromMasterComanyID)
					BEGIN
						INSERT INTO DBO.WorkOrderMaterialsKitMapping ([WOPartNoId],[KitId],[KitNumber],[ItemMasterId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
						[IsActive],[IsDeleted])
						SELECT @WOPartNoId, @KitMasterId, KM.KitNumber,@WO_MPNId_PAS,@FromMasterComanyID,@UserName,@UserName,GETUTCDATE(),GETUTCDATE(),1,0
						FROM DBO.KitMaster KM WITH (NOLOCK) WHERE KM.KitId = @KitMasterId;

						SELECT @WorkOrderMaterialsKitMappingId = SCOPE_IDENTITY();
					END
					ELSE
					BEGIN
						SELECT @WorkOrderMaterialsKitMappingId = WOKM.WorkOrderMaterialsKitMappingId FROM DBO.WorkOrderMaterialsKitMapping WOKM WITH (NOLOCK) WHERE WOKM.WOPartNoId = @WOPartNoId AND WOKM.ItemMasterId = @WO_MPNId_PAS AND WOKM.MasterCompanyId = @FromMasterComanyID;
					END

					IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterialsKit] WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId AND ItemMasterId = @WOM_PartId AND ConditionCodeId = @ConditionCodeId AND MasterCompanyId = @FromMasterComanyID)
					BEGIN
						INSERT INTO [dbo].[WorkOrderMaterialsKit] ([WorkOrderMaterialsKitMappingId],[WorkOrderId],[WorkFlowWorkOrderId],[ItemMasterId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
								[IsActive],[IsDeleted],[TaskId],[ConditionCodeId],[ItemClassificationId],[Quantity],[UnitOfMeasureId],[UnitCost],
								[ExtendedCost],[Memo],[IsDeferred],[QuantityReserved],[QuantityIssued],[IssuedDate],[ReservedDate],[IsAltPart],[AltPartMasterPartId],[IsFromWorkFlow],[PartStatusId],
								[UnReservedQty],[UnIssuedQty],[IssuedById],[ReservedById],[IsEquPart],[ParentWorkOrderMaterialsId],[ItemMappingId],[TotalReserved],[TotalIssued],[TotalUnReserved],
								[TotalUnIssued],[ProvisionId],[MaterialMandatoriesId],[WOPartNoId],[TotalStocklineQtyReq],[QtyOnOrder],[QtyOnBkOrder],[POId],[PONum],[PONextDlvrDate],[QtyToTurnIn],
								[Figure],[Item])
						SELECT @WorkOrderMaterialsKitMappingId,@WorkOrderId, @WorkFlowWorkOrderId, @WOM_PartId, @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(),
								1, 0, @WOM_TaskId, @ConditionCodeId, @ItemClassificationId, ISNULL(WOM.QtyNeeded, 0), @UOMId, ISNULL(WOM.UnitPrice, 0),
								(ISNULL(WOM.UnitPrice, 0) * ISNULL(WOM.QtyNeeded, 0)), WOM.NOTES, 0, ISNULL(WOM.QtyReserved, 0), ISNULL(WOM.QtyIssued, 0), NULL, NULL, 0, 0, 0, 0,
								0, 0, NULL, NULL, 0, 0, 0, ISNULL(WOM.QtyReserved, 0), ISNULL(WOM.QtyIssued, 0), 0,
								0, @ProvisionId, 1, 0, ISNULL(WOM.QtyNeeded, 0), 0, 0, NULL, NULL, NULL, ISNULL(WOM.QtyTurn, 0), 
								WOM.FIGURE, WOM.ItemNumber
						FROM #TempWOMaterial WOM WHERE WOM.WorkOrderMaterialId = @CurrentWorkOrderMaterialId;

						SELECT @InsertedWorkOrderMaterialKitId = SCOPE_IDENTITY();

						IF OBJECT_ID(N'tempdb..#TempWOMaterialStocklineKIT') IS NOT NULL
						BEGIN
							DROP TABLE #TempWOMaterialStocklineKIT
						END

						CREATE TABLE #TempWOMaterialStocklineKIT
						(
							[ID] [bigint] NOT NULL IDENTITY,
							[StockReservationId] [bigint] NOT NULL,
							[SOPartId] [bigint] NULL,
							[StocklineId] [bigint] NULL,
							[ROPartId] [bigint] NULL,
							[ConsignmentCodeId] [bigint] NULL,
							[WorkOrderId] [bigint] NULL,
							[WorkOrderMaterialId] [bigint] NULL,
							[WorkOrderTaskToolId] [bigint] NULL,
							[SMDetailId] [bigint] NULL,
							[UnitCost] [decimal](18, 2) NULL,
							[QtyReserved] [int] NULL,
							[QtyShip] [int] NULL,
							[QtyInvoiced] [int] NULL,
							[QtyRepaired] [int] NULL,
							[QtyScrapped] [int] NULL,
							[POPartId] [bigint] NULL,
							[QtyIssued] [int] NULL,
							[QtyUndoIssue] [int] NULL,
							[EntryDate] [datetime2](7) NULL,
							[MasterCompanyId] [bigint] NULL,
							[Migrated_Id] [bigint] NULL,
							[SuccessMsg] [varchar](500) NULL,
							[ErrorMsg] [varchar](500) NULL
						)

						INSERT INTO #TempWOMaterialStocklineKIT ([StockReservationId],[SOPartId],[StocklineId],[ROPartId],[ConsignmentCodeId],[WorkOrderId],[WorkOrderMaterialId],[WorkOrderTaskToolId],[SMDetailId],[UnitCost],
						[QtyReserved],[QtyShip],[QtyInvoiced],[QtyRepaired],[QtyScrapped],[POPartId],[QtyIssued],[QtyUndoIssue],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
						SELECT [StockReservationId],[SOPartId],[StocklineId],[ROPartId],[ConsignmentCodeId],[WorkOrderId],[WorkOrderMaterialId],[WorkOrderTaskToolId],[SMDetailId],[UnitCost],
						[QtyReserved],[QtyShip],[QtyInvoiced],[QtyRepaired],[QtyScrapped],[POPartId],[QtyIssued],[QtyUndoIssue],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
						FROM [Quantum_Staging].dbo.[StockReservations] StkRes WITH (NOLOCK) WHERE StkRes.Migrated_Id IS NULL;

						DECLARE @QtyTurnIn_KIT INT;

						SELECT @QtyTurnIn_KIT = ISNULL(WOM.QtyTurn, 0) FROM #TempWOMaterial WOM WHERE WOM.WorkOrderMaterialId = @CurrentWorkOrderMaterialId;

						DECLARE @WOMSLoopID_KIT AS INT;
						DECLARE @TotWOMSCount_KIT AS INT;
						SELECT @TotWOMSCount_KIT = COUNT(*), @WOMSLoopID_KIT = MIN(ID) FROM #TempWOMaterialStocklineKIT;

						WHILE (@WOMSLoopID_KIT <= @TotWOMSCount_KIT)
						BEGIN
							DECLARE @WOMS_STM_AUTO_KEY_KIT BIGINT;
							DECLARE @StockLineId_KIT BIGINT = 0;
							DECLARE @QTY_RESERVED_KIT INT;
							DECLARE @STOCK_LINE_KIT VARCHAR(100) = '';

							SELECT @WOMS_STM_AUTO_KEY_KIT = StocklineId, @QTY_RESERVED_KIT = QtyReserved FROM #TempWOMaterialStocklineKIT WHERE ID = @WOMSLoopID_KIT;
							SELECT @STOCK_LINE_KIT = (CAST(ISNULL(StocklineNumber, '') AS VARCHAR)) FROM Quantum_Staging.DBO.Stocklines WHERE StocklineId = @WOMS_STM_AUTO_KEY_KIT;
							SELECT @StockLineId_KIT = [StockLineId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE UPPER([StockLineNumber])  = UPPER(@STOCK_LINE_KIT);
							 
							IF (@QTY_RESERVED_KIT > 0)
							BEGIN
								INSERT INTO [dbo].[WorkOrderMaterialStockLineKit] ([WorkOrderMaterialsKitId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],[QtyIssued],[MasterCompanyId],
									[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId],[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],
									[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure],[Item],[RepairOrderPartRecordId])
								SELECT @InsertedWorkOrderMaterialKitId, @StockLineId_KIT, @WOM_PartId, @ConditionCodeId, ISNULL(WOMS.QtyReserved, 0), ISNULL(WOMS.QtyReserved, 0), ISNULL(WOMS.QtyIssued, 0), @FromMasterComanyID,
									@UserName, @UserName, GETDATE(), GETDATE(), 1, 0, NULL, NULL, NULL, NULL, ISNULL(WOMS.UnitCost, 0), (ISNULL(WOMS.UnitCost, 0) * ISNULL(WOMS.QtyReserved, 0)),
									ISNULL(WOMS.UnitCost, 0), (ISNULL(WOMS.UnitCost, 0) * ISNULL(WOMS.QtyReserved, 0)), @ProvisionId, NULL, @QtyTurnIn_KIT, NULL, NULL, NULL
								FROM #TempWOMaterialStocklineKIT WOMS WHERE ID = @WOMSLoopID_KIT;
							END

							SET @WOMSLoopID_KIT = @WOMSLoopID_KIT + 1;
						END

						IF OBJECT_ID(N'tempdb..#TempWOMaterialStocklineIssueKIT') IS NOT NULL
						BEGIN
							DROP TABLE #TempWOMaterialStocklineIssueKIT
						END

						CREATE TABLE #TempWOMaterialStocklineIssueKIT
						(
							[ID] [bigint] NOT NULL IDENTITY,
							[StockTransactionId] [bigint] NOT NULL,
							[StocklineParentId] [bigint] NULL,
							[StocklineId] [bigint] NULL,
							[WorkOrderMaterialId] [bigint] NULL,
							[WorkOrderTaskToolId] [bigint] NULL,
							[Qty] [int] NULL,
							[TranDate] [datetime2](7) NULL,
							[TransactionType] varchar(10) NULL,
							[ROPartId] [bigint] NULL,
							[QtyReverse] [int] NULL,
							[QtyBilled] [int] NULL,
							[EntryDate] [datetime2](7) NULL,
							[MasterCompanyId] [bigint] NULL,
							[Migrated_Id] [bigint] NULL,
							[SuccessMsg] [varchar](500) NULL,
							[ErrorMsg] [varchar](500) NULL
						)

						INSERT INTO #TempWOMaterialStocklineIssueKIT ([StockTransactionId],[StocklineParentId],[StocklineId],[WorkOrderMaterialId],[WorkOrderTaskToolId],[Qty],[TranDate],[TransactionType],[ROPartId],
						[QtyReverse],[QtyBilled],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
						SELECT [StockTransactionId],[StocklineParentId],[StocklineId],[WorkOrderMaterialId],[WorkOrderTaskToolId],[Qty],[TranDate],[TransactionType],[ROPartId],
						[QtyReverse],[QtyBilled],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
						FROM [Quantum_Staging].dbo.[StockTransactions] StkTrans WITH (NOLOCK) WHERE StkTrans.Migrated_Id IS NULL;

						DECLARE @WOMSIssueLoopID_KIT AS INT;
						DECLARE @TotWOMSIssueCount_KIT AS INT;
						SELECT @TotWOMSIssueCount_KIT = COUNT(*), @WOMSIssueLoopID_KIT = MIN(ID) FROM #TempWOMaterialStocklineIssueKIT;

						WHILE (@WOMSIssueLoopID_KIT <= @TotWOMSIssueCount_KIT)
						BEGIN
							DECLARE @QTY_ISSUED_KIT INT;
							DECLARE @STOCK_LINE_NUMBER_KIT VARCHAR(50) = '';
							DECLARE @CTRL_ID_KIT VARCHAR(50) = '';
							DECLARE @CTRL_NUMBER_KIT VARCHAR(50) = '';
							DECLARE @STK_UNIT_COST_KIT DECIMAL(18,2) = NULL;
							DECLARE @Repair_ProvisionId_KIT BIGINT = NULL;

							SELECT @WOMS_STM_AUTO_KEY_KIT = StocklineId, @QTY_ISSUED_KIT = QTY FROM #TempWOMaterialStocklineIssueKIT WHERE ID = @WOMSIssueLoopID_KIT;

							SELECT @STOCK_LINE_NUMBER_KIT = (CAST(ISNULL(StocklineNumber, '') AS VARCHAR)),  @CTRL_ID_KIT = (CAST(ISNULL(STK.Ctrl_ID, '') AS VARCHAR)),
							@CTRL_NUMBER_KIT = (CAST(ISNULL(STK.Ctrl_Number, '') AS VARCHAR)) FROM Quantum_Staging.DBO.Stocklines STK WITH (NOLOCK) WHERE StocklineId = @WOMS_STM_AUTO_KEY_KIT;

							SELECT @StockLineId_KIT = [StockLineId], @STK_UNIT_COST_KIT = UnitCost FROM [dbo].[Stockline] WITH(NOLOCK) 
														WHERE UPPER([StockLineNumber])  = UPPER(@STOCK_LINE_KIT)
														AND UPPER([IdNumber])  = UPPER(@CTRL_ID_KIT) 
														AND UPPER([ControlNumber])  = UPPER(@CTRL_NUMBER_KIT)
														AND [ItemMasterId] = @WOM_PartId
														AND MasterCompanyId = @FromMasterComanyID;

							SELECT @ProvisionId  = ProvisionId FROM dbo.[Provision] WHERE UPPER([StatusCode]) = UPPER('REPLACE');
							SELECT @Repair_ProvisionId_KIT  = ProvisionId FROM dbo.[Provision] WHERE UPPER([StatusCode]) = UPPER('REPAIR');

							IF (@StockLineId_KIT > 0)
							BEGIN
								IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[WorkOrderMaterialStockLineKit] WOMS WHERE WOMS.[WorkOrderMaterialsKitId] = @InsertedWorkOrderMaterialKitId AND WOMS.StockLineId = @StockLineId_KIT AND WOMS.MasterCompanyId = @FromMasterComanyID)
								BEGIN
									DECLARE @TI_Type_KIT CHAR(1) = '';
									SELECT @QtyTurnIn_KIT = WOMS.Qty, @TI_Type_KIT = WOMS.TransactionType FROM #TempWOMaterialStocklineIssueKIT WOMS WHERE ID = @WOMSIssueLoopID_KIT;

									IF (ISNULL(@InsertedWorkOrderMaterialKitId, 0) != 0)
									BEGIN
										INSERT INTO [dbo].[WorkOrderMaterialStockLineKit] ([WorkOrderMaterialsKitId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],[QtyIssued],[MasterCompanyId],
										[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId],[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],
										[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure],[Item])
										SELECT @InsertedWorkOrderMaterialKitId, @StockLineId_KIT, @WOM_PartId, @ConditionCodeId, ISNULL(WOMS.QTY, 0), 0, CASE WHEN @TI_Type_KIT = 'I' THEN ISNULL(WOMS.QTY, 0) ELSE 0 END, @FromMasterComanyID,
										@UserName, @UserName, GETDATE(), GETDATE(), 1, 0, NULL, NULL, NULL, NULL, ISNULL(@STK_UNIT_COST_KIT, 0), (ISNULL(@STK_UNIT_COST_KIT, 0) * ISNULL(WOMS.QTY, 0)),
										ISNULL(@STK_UNIT_COST_KIT, 0), (ISNULL(@STK_UNIT_COST_KIT, 0) * ISNULL(WOMS.QTY, 0)), CASE WHEN @TI_Type_KIT = 'I' THEN @ProvisionId ELSE @Repair_ProvisionId_KIT END, NULL, CASE WHEN @TI_Type_KIT = 'T' THEN ISNULL(WOMS.QTY, 0) ELSE 0 END, NULL, NULL
										FROM #TempWOMaterialStocklineIssueKIT WOMS WHERE ID = @WOMSIssueLoopID_KIT;

										IF (@TI_Type_KIT = 'T')
										BEGIN
											UPDATE STK
											SET STK.QuantityTurnIn = @QtyTurnIn_KIT, STK.IsTurnIn = 1
											FROM DBO.Stockline STK WHERE STK.StockLineId = @StockLineId_KIT AND MasterCompanyId = @FromMasterComanyID;
										END
									END
								END
							END

							SET @WOMSIssueLoopID_KIT = @WOMSIssueLoopID_KIT + 1;
						END

						EXEC USP_UpdateWOTotalCostDetails @WorkOrderId, @WorkFlowWorkOrderId, @UserName, @FromMasterComanyID;
						EXEC USP_UpdateWOCostDetails @WorkOrderId, @WorkFlowWorkOrderId, @UserName, @FromMasterComanyID

						SET @MigratedRecords = @MigratedRecords + 1;
					END
					ELSE
					BEGIN
						UPDATE WOM
						SET WOM.ErrorMsg = WOM.ErrorMsg + '<p>Material already exists</p>'
						FROM [Quantum_Staging].DBO.[WorkOrderMaterials] WOM WHERE WOM.WorkOrderMaterialId = @CurrentWorkOrderMaterialId;

						SET @Exists = @Exists + 1;
					END
				END
				ELSE
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId AND ItemMasterId = @WOM_PartId AND ConditionCodeId = @ConditionCodeId AND MasterCompanyId = @FromMasterComanyID)
					BEGIN
						INSERT INTO [dbo].[WorkOrderMaterials] ([WorkOrderId],[WorkFlowWorkOrderId],[ItemMasterId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
								[IsActive],[IsDeleted],[TaskId],[ConditionCodeId],[ItemClassificationId],[Quantity],[UnitOfMeasureId],[UnitCost],
								[ExtendedCost],[Memo],[IsDeferred],[QuantityReserved],[QuantityIssued],[IssuedDate],[ReservedDate],[IsAltPart],[AltPartMasterPartId],[IsFromWorkFlow],[PartStatusId],
								[UnReservedQty],[UnIssuedQty],[IssuedById],[ReservedById],[IsEquPart],[ParentWorkOrderMaterialsId],[ItemMappingId],[TotalReserved],[TotalIssued],[TotalUnReserved],
								[TotalUnIssued],[ProvisionId],[MaterialMandatoriesId],[WOPartNoId],[TotalStocklineQtyReq],[QtyOnOrder],[QtyOnBkOrder],[POId],[PONum],[PONextDlvrDate],[QtyToTurnIn],
								[Figure],[Item],[EquPartMasterPartId],[isfromsubWorkOrder])
						SELECT @WorkOrderId, @WorkFlowWorkOrderId, @WOM_PartId, @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(),
								1, 0, @WOM_TaskId, @ConditionCodeId, @ItemClassificationId, ISNULL(WOM.QtyNeeded, 0), @UOMId, ISNULL(WOM.UnitPrice, 0),
								(ISNULL(WOM.UnitPrice, 0) * ISNULL(WOM.QtyNeeded, 0)), WOM.NOTES, 0, ISNULL(WOM.QtyReserved, 0), ISNULL(WOM.QtyIssued, 0), NULL, NULL, 0, 0, 0, 0,
								0, 0, NULL, NULL, 0, 0, 0, ISNULL(WOM.QtyReserved, 0), ISNULL(WOM.QtyIssued, 0), 0,
								0, @ProvisionId, 1, 0, ISNULL(WOM.QtyNeeded, 0), 0, 0, NULL, NULL, NULL, ISNULL(WOM.QtyTurn, 0), 
								WOM.FIGURE, WOM.ItemNumber, NULL, NULL
						FROM #TempWOMaterial WOM WHERE WOM.WorkOrderMaterialId = @CurrentWorkOrderMaterialId;

						SELECT @InsertedWorkOrderMaterialId = SCOPE_IDENTITY();

						IF OBJECT_ID(N'tempdb..#TempWOMaterialStockline') IS NOT NULL
						BEGIN
							DROP TABLE #TempWOMaterialStockline
						END

						CREATE TABLE #TempWOMaterialStockline
						(
							[ID] [bigint] NOT NULL IDENTITY,
							[StockReservationId] [bigint] NOT NULL,
							[SOPartId] [bigint] NULL,
							[StocklineId] [bigint] NULL,
							[ROPartId] [bigint] NULL,
							[ConsignmentCodeId] [bigint] NULL,
							[WorkOrderId] [bigint] NULL,
							[WorkOrderMaterialId] [bigint] NULL,
							[WorkOrderTaskToolId] [bigint] NULL,
							[SMDetailId] [bigint] NULL,
							[UnitCost] [decimal](18, 2) NULL,
							[QtyReserved] [int] NULL,
							[QtyShip] [int] NULL,
							[QtyInvoiced] [int] NULL,
							[QtyRepaired] [int] NULL,
							[QtyScrapped] [int] NULL,
							[POPartId] [bigint] NULL,
							[QtyIssued] [int] NULL,
							[QtyUndoIssue] [int] NULL,
							[EntryDate] [datetime2](7) NULL,
							[MasterCompanyId] [bigint] NULL,
							[Migrated_Id] [bigint] NULL,
							[SuccessMsg] [varchar](500) NULL,
							[ErrorMsg] [varchar](500) NULL
						)

						INSERT INTO #TempWOMaterialStockline ([StockReservationId],[SOPartId],[StocklineId],[ROPartId],[ConsignmentCodeId],[WorkOrderId],[WorkOrderMaterialId],[WorkOrderTaskToolId],[SMDetailId],[UnitCost],
						[QtyReserved],[QtyShip],[QtyInvoiced],[QtyRepaired],[QtyScrapped],[POPartId],[QtyIssued],[QtyUndoIssue],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
						SELECT [StockReservationId],[SOPartId],[StocklineId],[ROPartId],[ConsignmentCodeId],[WorkOrderId],[WorkOrderMaterialId],[WorkOrderTaskToolId],[SMDetailId],[UnitCost],
						[QtyReserved],[QtyShip],[QtyInvoiced],[QtyRepaired],[QtyScrapped],[POPartId],[QtyIssued],[QtyUndoIssue],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
						FROM [Quantum_Staging].dbo.[StockReservations] StkRes WITH (NOLOCK) WHERE StkRes.Migrated_Id IS NULL;

						DECLARE @QtyTurnIn INT;

						SELECT @QtyTurnIn = ISNULL(WOM.QtyTurn, 0) FROM #TempWOMaterial WOM WHERE WOM.WorkOrderMaterialId = @CurrentWorkOrderMaterialId;

						DECLARE @WOMSLoopID AS INT;
						DECLARE @TotWOMSCount AS INT;
						SELECT @TotWOMSCount = COUNT(*), @WOMSLoopID = MIN(ID) FROM #TempWOMaterialStockline;

						WHILE (@WOMSLoopID <= @TotWOMSCount)
						BEGIN
							DECLARE @WOMS_STM_AUTO_KEY BIGINT;
							DECLARE @StockLineId BIGINT = 0;
							DECLARE @QTY_RESERVED INT;
							DECLARE @STOCK_LINE VARCHAR(100) = '';

							SELECT @WOMS_STM_AUTO_KEY = StocklineId, @QTY_RESERVED = QtyReserved FROM #TempWOMaterialStockline WHERE ID = @WOMSLoopID;
							SELECT @STOCK_LINE = (CAST(ISNULL(StocklineNumber, '') AS VARCHAR)) FROM Quantum_Staging.DBO.Stocklines WHERE StocklineId = @WOMS_STM_AUTO_KEY;
							SELECT @StockLineId = [StockLineId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE UPPER([StockLineNumber])  = UPPER(@STOCK_LINE);
							 
							IF (@QTY_RESERVED > 0)
							BEGIN
								INSERT INTO [dbo].[WorkOrderMaterialStockLine] ([WorkOrderMaterialsId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],[QtyIssued],[MasterCompanyId],
									[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId],[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],
									[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure],[Item])
								SELECT @InsertedWorkOrderMaterialId, @StockLineId, @WOM_PartId, @ConditionCodeId, ISNULL(WOMS.QtyReserved, 0), ISNULL(WOMS.QtyReserved, 0), ISNULL(WOMS.QtyIssued, 0), @FromMasterComanyID,
									@UserName, @UserName, GETDATE(), GETDATE(), 1, 0, NULL, NULL, NULL, NULL, ISNULL(WOMS.UnitCost, 0), (ISNULL(WOMS.UnitCost, 0) * ISNULL(WOMS.QtyReserved, 0)),
									ISNULL(WOMS.UnitCost, 0), (ISNULL(WOMS.UnitCost, 0) * ISNULL(WOMS.QtyReserved, 0)), @ProvisionId, NULL, @QtyTurnIn, NULL, NULL
								FROM #TempWOMaterialStockline WOMS WHERE ID = @WOMSLoopID;
							END

							SET @WOMSLoopID = @WOMSLoopID + 1;
						END

						IF OBJECT_ID(N'tempdb..#TempWOMaterialStocklineIssue') IS NOT NULL
						BEGIN
							DROP TABLE #TempWOMaterialStocklineIssue
						END

						CREATE TABLE #TempWOMaterialStocklineIssue
						(
							[ID] [bigint] NOT NULL IDENTITY,
							[StockTransactionId] [bigint] NOT NULL,
							[StocklineParentId] [bigint] NULL,
							[StocklineId] [bigint] NULL,
							[WorkOrderMaterialId] [bigint] NULL,
							[WorkOrderTaskToolId] [bigint] NULL,
							[Qty] [int] NULL,
							[TranDate] [datetime2](7) NULL,
							[TransactionType] varchar(10) NULL,
							[ROPartId] [bigint] NULL,
							[QtyReverse] [int] NULL,
							[QtyBilled] [int] NULL,
							[EntryDate] [datetime2](7) NULL,
							[MasterCompanyId] [bigint] NULL,
							[Migrated_Id] [bigint] NULL,
							[SuccessMsg] [varchar](500) NULL,
							[ErrorMsg] [varchar](500) NULL
						)

						INSERT INTO #TempWOMaterialStocklineIssue ([StockTransactionId],[StocklineParentId],[StocklineId],[WorkOrderMaterialId],[WorkOrderTaskToolId],[Qty],[TranDate],[TransactionType],[ROPartId],
						[QtyReverse],[QtyBilled],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
						SELECT [StockTransactionId],[StocklineParentId],[StocklineId],[WorkOrderMaterialId],[WorkOrderTaskToolId],[Qty],[TranDate],[TransactionType],[ROPartId],
						[QtyReverse],[QtyBilled],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
						FROM [Quantum_Staging].dbo.[StockTransactions] StkTrans WITH (NOLOCK) WHERE StkTrans.Migrated_Id IS NULL;

						DECLARE @WOMSIssueLoopID AS INT;
						DECLARE @TotWOMSIssueCount AS INT;
						SELECT @TotWOMSIssueCount = COUNT(*), @WOMSIssueLoopID = MIN(ID) FROM #TempWOMaterialStocklineIssue;

						WHILE (@WOMSIssueLoopID <= @TotWOMSIssueCount)
						BEGIN
							DECLARE @QTY_ISSUED INT;
							DECLARE @STOCK_LINE_NUMBER VARCHAR(50) = '';
							DECLARE @CTRL_ID VARCHAR(50) = '';
							DECLARE @CTRL_NUMBER VARCHAR(50) = '';
							DECLARE @STK_UNIT_COST DECIMAL(18,2) = NULL;
							DECLARE @Repair_ProvisionId BIGINT = NULL;

							SELECT @WOMS_STM_AUTO_KEY = StocklineId, @QTY_ISSUED = QTY FROM #TempWOMaterialStocklineIssue WHERE ID = @WOMSIssueLoopID;

							SELECT @STOCK_LINE_NUMBER = (CAST(ISNULL(StocklineNumber, '') AS VARCHAR)),  @CTRL_ID = (CAST(ISNULL(STK.Ctrl_ID, '') AS VARCHAR)),
							@CTRL_NUMBER = (CAST(ISNULL(STK.Ctrl_Number, '') AS VARCHAR)) FROM Quantum_Staging.DBO.Stocklines STK WITH (NOLOCK) WHERE StocklineId = @WOMS_STM_AUTO_KEY;

							SELECT @StockLineId = [StockLineId], @STK_UNIT_COST = UnitCost FROM [dbo].[Stockline] WITH(NOLOCK) 
														WHERE UPPER([StockLineNumber])  = UPPER(@STOCK_LINE)
														AND UPPER([IdNumber])  = UPPER(@CTRL_ID) 
														AND UPPER([ControlNumber])  = UPPER(@CTRL_NUMBER)
														AND [ItemMasterId] = @WOM_PartId
														AND MasterCompanyId = @FromMasterComanyID;

							SELECT @ProvisionId  = ProvisionId FROM dbo.[Provision] WHERE UPPER([StatusCode]) = UPPER('REPLACE');
							SELECT @Repair_ProvisionId  = ProvisionId FROM dbo.[Provision] WHERE UPPER([StatusCode]) = UPPER('REPAIR');

							IF (@StockLineId > 0)
							BEGIN
								IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[WorkOrderMaterialStockLine] WOMS WHERE WOMS.WorkOrderMaterialsId = @InsertedWorkOrderMaterialId AND WOMS.StockLineId = @StockLineId AND WOMS.MasterCompanyId = @FromMasterComanyID)
								BEGIN
									DECLARE @TI_Type CHAR(1) = '';
									SELECT @QtyTurnIn = WOMS.Qty, @TI_Type = WOMS.TransactionType FROM #TempWOMaterialStocklineIssue WOMS WHERE ID = @WOMSIssueLoopID;

									IF (ISNULL(@InsertedWorkOrderMaterialId, 0) != 0)
									BEGIN
										INSERT INTO [dbo].[WorkOrderMaterialStockLine] ([WorkOrderMaterialsId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],[QtyIssued],[MasterCompanyId],
										[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId],[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],
										[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure],[Item])
										SELECT @InsertedWorkOrderMaterialId, @StockLineId, @WOM_PartId, @ConditionCodeId, ISNULL(WOMS.QTY, 0), 0, CASE WHEN @TI_Type = 'I' THEN ISNULL(WOMS.QTY, 0) ELSE 0 END, @FromMasterComanyID,
										@UserName, @UserName, GETDATE(), GETDATE(), 1, 0, NULL, NULL, NULL, NULL, ISNULL(@STK_UNIT_COST, 0), (ISNULL(@STK_UNIT_COST, 0) * ISNULL(WOMS.QTY, 0)),
										ISNULL(@STK_UNIT_COST, 0), (ISNULL(@STK_UNIT_COST, 0) * ISNULL(WOMS.QTY, 0)), CASE WHEN @TI_Type = 'I' THEN @ProvisionId ELSE @Repair_ProvisionId END, NULL, CASE WHEN @TI_Type = 'T' THEN ISNULL(WOMS.QTY, 0) ELSE 0 END, NULL, NULL
										FROM #TempWOMaterialStocklineIssue WOMS WHERE ID = @WOMSIssueLoopID;

										IF (@TI_Type = 'T')
										BEGIN
											UPDATE STK
											SET STK.QuantityTurnIn = @QtyTurnIn, STK.IsTurnIn = 1
											FROM DBO.Stockline STK WHERE STK.StockLineId = @StockLineId AND MasterCompanyId = @FromMasterComanyID;
										END
									END
								END
							END

							SET @WOMSIssueLoopID = @WOMSIssueLoopID + 1;
						END

						EXEC USP_UpdateWOTotalCostDetails @WorkOrderId, @WorkFlowWorkOrderId, @UserName, @FromMasterComanyID;
						EXEC USP_UpdateWOCostDetails @WorkOrderId, @WorkFlowWorkOrderId, @UserName, @FromMasterComanyID

						SET @MigratedRecords = @MigratedRecords + 1;
					END
					ELSE
					BEGIN
						UPDATE WOM
						SET WOM.ErrorMsg = WOM.ErrorMsg + '<p>Material already exists</p>'
						FROM [Quantum_Staging].DBO.[WorkOrderMaterials] WOM WHERE WOM.WorkOrderMaterialId = @CurrentWorkOrderMaterialId;

						SET @Exists = @Exists + 1;
					END
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
	  ,@AdhocComments varchar(150) = 'MigrateWOHeaderRecords'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END