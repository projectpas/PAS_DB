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
			--IF (ISNULL(@DefaultUserId, 0) = 0)
			--BEGIN
			--	SET @FoundError = 1;
			--	SET @ErrorMsg = @ErrorMsg + '<p>Default User Id not found</p>'
			--END
			--IF (ISNULL(@CreditLimit, 0) = 0)
			--BEGIN
			--	SET @FoundError = 1;
			--	SET @ErrorMsg = @ErrorMsg + '<p>Credit Limit is missing OR zero</p>'
			--END
			
			IF (@FoundError = 1)
			BEGIN
				UPDATE WOM
				SET WOM.ErrorMsg = @ErrorMsg
				FROM [Quantum_Staging].DBO.[WorkOrderMaterials] WOM WHERE WOM.WorkOrderMaterialId = @CurrentWorkOrderMaterialId;

				SET @RecordsWithError = @RecordsWithError + 1;
			END

			DECLARE @InsertedWorkOrderMaterialId BIGINT;

			IF (@FoundError = 0)
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