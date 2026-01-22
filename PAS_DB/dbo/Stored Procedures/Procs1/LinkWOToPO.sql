/*************************************************************             
 ** File:   [LinkWOToPO]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to link Work Order to PO Records
 ** Purpose:           
 ** Date:   02/01/2024

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    02/01/2024   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC LinkWOToPO @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=12,@UserName=N'ROGER BENTLY',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[LinkWOToPO]
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

		IF OBJECT_ID(N'tempdb..#TempWorkOrder') IS NOT NULL
		BEGIN
			DROP TABLE #TempWorkOrder
		END

		CREATE TABLE #TempWorkOrder
		(
			ID bigint NOT NULL IDENTITY,
			[WorkOrderId] [bigint] NOT NULL,
			[WorkOrderNumber] [varchar](100) NULL,
			[StocklineId] [bigint] NULL,
			[ItemMasterId] [bigint] NULL,
			[CustomerId] [bigint] NULL,
			[WorkOrderMaterialId] [bigint] NULL,
			[SystemUserId] [bigint] NULL,
			[EntryDate] [datetime2](7) NULL,
			[OpenFlag] [varchar](10) NULL,
			[Notes] [varchar](max) NULL,
			[KitQty] [int] NULL,
			[WorkOrderStatusId] [bigint] NULL,
			[OPM_Id] [bigint] NULL,
			[DueDate] [datetime2](7) NULL,
			[CompanyRefNumber] [varchar](100) NULL,
			[PriorityId] [int] NULL,
			[TailNumber] [varchar](100) NULL,
			[EngineNumber] [varchar](100) NULL,
			[WarranteeFlag] [varchar](10) NULL,
			[PartConditionId] [bigint] NULL,
			[WoType] [varchar](10) NULL,
			[ShipViaCodeId] [bigint] NULL,
			[IsActive] [varchar](10) NULL,
			[Description] [varchar](max) NULL,
			[SalesOrderPartId] [bigint] NULL,
			[WorkOrderParentId] [bigint] NULL,
			[CurrencyId] [bigint] NULL,
			[CountryCodeId] [bigint] NULL,
			[BatchNumber] [varchar](100) NULL,
			[EstTotalCost] [decimal](18, 2) NULL,
			[UrlLink] [varchar](100) NULL,
			[ReleaseDate] [datetime2](7) NULL,
			[IsTearDown] [varchar](10) NULL,
			[WorkOrderLotId] [bigint] NULL,
			[IntegrationType] [varchar](100) NULL,
			[IsAutoInvoice] [varchar](10) NULL,
			[DateCreated] [datetime2](7) NULL,
			[MasterCompanyId] [bigint] NULL,
			[Migrated_Id] [bigint] NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL
		)

		INSERT INTO #TempWorkOrder ([WorkOrderId],[WorkOrderNumber],[StocklineId],[ItemMasterId],[CustomerId],[WorkOrderMaterialId],[SystemUserId],[EntryDate],[OpenFlag],[Notes],[KitQty],[WorkOrderStatusId],[OPM_Id],
		[DueDate],[CompanyRefNumber],[PriorityId],[TailNumber],[EngineNumber],[WarranteeFlag],[PartConditionId],[WoType],[ShipViaCodeId],[IsActive],[Description],[SalesOrderPartId],[WorkOrderParentId],[CurrencyId],
		[CountryCodeId],[BatchNumber],[EstTotalCost],[UrlLink],[ReleaseDate],[IsTearDown],[WorkOrderLotId],[IntegrationType],[IsAutoInvoice],[DateCreated],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT [WorkOrderId],[WorkOrderNumber],[StocklineId],[ItemMasterId],[CustomerId],[WorkOrderMaterialId],[SystemUserId],[EntryDate],[OpenFlag],[Notes],[KitQty],[WorkOrderStatusId],[OPM_Id],
		[DueDate],[CompanyRefNumber],[PriorityId],[TailNumber],[EngineNumber],[WarranteeFlag],[PartConditionId],[WoType],[ShipViaCodeId],[IsActive],[Description],[SalesOrderPartId],[WorkOrderParentId],[CurrencyId],
		[CountryCodeId],[BatchNumber],[EstTotalCost],[UrlLink],[ReleaseDate],[IsTearDown],[WorkOrderLotId],[IntegrationType],[IsAutoInvoice],[DateCreated],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
		FROM [Quantum_Staging].dbo.[WorkOrderHeaders] WOH WITH (NOLOCK);

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempWorkOrder;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;
			
			DECLARE @WOO_AUTO_KEY BIGINT;
			DECLARE @SI_NUMBER VARCHAR(200) = NULL;
			DECLARE @ENTRY_DATE DATETIME2 = NULL;

			SELECT @WOO_AUTO_KEY = WorkOrderId, @SI_NUMBER = WorkOrderNumber, @ENTRY_DATE = CAST(EntryDate AS DATETIME2)
			FROM #TempWorkOrder WHERE ID = @LoopID;
			
			IF EXISTS (SELECT 1 FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderNum] = @SI_NUMBER AND [MasterCompanyId] = @FromMasterComanyID)
			BEGIN
				IF OBJECT_ID(N'tempdb..#WOMaterial') IS NOT NULL
				BEGIN
					DROP TABLE #WOMaterial
				END

				CREATE TABLE #WOMaterial
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

				INSERT INTO #WOMaterial ([WorkOrderMaterialId],[WorkOrderId],[ItemMasterId],[SystemUserId],[PartConditionCodeId],[QtyNeeded],[QtyReserved],[QtyIssued],[QtyTurn],[CondLevel],[Notes],[WorkOrderTaskId],
					[UnitPrice],[Requisition],[IsROPartLinked],[IsPOPartLinked],[IsCQDetailLinked],[EstCost],[NeedDate],[QtyScrapped],[QtyServiceable],[Figure],[ConsignmentCodeId],[QtySpare],[QtyPurchase],[Priority],[ItemNumber],
					[Remarks],[OperationMasterId],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
				SELECT [WorkOrderMaterialId],[WorkOrderId],[ItemMasterId],[SystemUserId],[PartConditionCodeId],[QtyNeeded],[QtyReserved],[QtyIssued],[QtyTurn],[CondLevel],[Notes],[WorkOrderTaskId],
					[UnitPrice],[Requisition],[IsROPartLinked],[IsPOPartLinked],[IsCQDetailLinked],[EstCost],[NeedDate],[QtyScrapped],[QtyServiceable],[Figure],[ConsignmentCodeId],[QtySpare],[QtyPurchase],[Priority],[ItemNumber],
					[Remarks],[OperationMasterId],[EntryDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
				FROM [Quantum_Staging].dbo.[WorkOrderMaterials] WOM WITH (NOLOCK) WHERE WOM.WorkOrderId = @WOO_AUTO_KEY AND WOM.IsPOPartLinked = 'T';

				DECLARE @WOMLoopID AS INT;
				DECLARE @TotWOMCount AS INT;
				SELECT @TotWOMCount = COUNT(*), @WOMLoopID = MIN(ID) FROM #WOMaterial;

				WHILE (@WOMLoopID <= @TotWOMCount)
				BEGIN
					DECLARE @PCC_AUTO_KEY BIGINT = NULL;
					DECLARE @Part_NUMBER VARCHAR(50),@Part_Desc NVARCHAR(MAX)
					DECLARE @WOB_AUTO_KEY BIGINT;
					DECLARE @UOM_AUTO_KEY BIGINT;
					DECLARE @ConditionCodeId BIGINT;
					DECLARE @ItemMaster_Id BIGINT;
					DECLARE @PNM_AUTO_KEY BIGINT = 0;
					DECLARE @WorkOrder_Id_In_PAS BIGINT;

					SELECT @WOB_AUTO_KEY = WorkOrderMaterialId, @PCC_AUTO_KEY = PartConditionCodeId, @PNM_AUTO_KEY = ItemMasterId FROM #WOMaterial WHERE ID = @WOMLoopID;

					SELECT @Part_NUMBER = IM.[PN], @Part_Desc = IM.[DESCRIPTION] FROM [Quantum].[QCTL_NEW_3].[PARTS_MASTER] IM  WITH(NOLOCK) WHERE IM.[PNM_AUTO_KEY] = @PNM_AUTO_KEY;
			    
					SELECT @ItemMaster_Id = IM.[ItemMasterId] FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE UPPER(IM.[partnumber]) = UPPER(@Part_NUMBER) AND UPPER(IM.[PartDescription]) = UPPER(@Part_Desc);

					SELECT @ConditionCodeId = ConditionId FROM DBO.[Condition] C WHERE UPPER(C.Description) IN (SELECT UPPER(CC.CONDITION_CODE) FROM [Quantum].QCTL_NEW_3.PART_CONDITION_CODES CC Where CC.PCC_AUTO_KEY = @PCC_AUTO_KEY) AND MasterCompanyId = @FromMasterComanyID;
					
					SELECT @WorkOrder_Id_In_PAS = WO.WorkOrderId FROM [dbo].[WorkOrder] AS WO WHERE UPPER(WO.WorkOrderNum) = UPPER(@SI_NUMBER);

					IF OBJECT_ID(N'tempdb..#PURCHASE_WO') IS NOT NULL
					BEGIN
						DROP TABLE #PURCHASE_WO
					END

					CREATE TABLE #PURCHASE_WO
					(
						[ID] [bigint] NOT NULL IDENTITY,
						[PWO_AUTO_KEY] [float] NOT NULL,
						[POD_AUTO_KEY] [float] NOT NULL,
						[WOB_AUTO_KEY] [float] NOT NULL,
						[QTY_ORDERED] [numeric](11, 2) NULL,
						[QTY_REC] [numeric](11, 2) NULL,
						[CRQ_AUTO_KEY] [float] NULL,
						[CONVERTED] [varchar](1) NULL,
						[CONVERSION_ID] [float] NULL,
						[SYSTEM] [char](1) NULL,
						[ROWID] [uniqueidentifier] NOT NULL,
					)

					INSERT INTO #PURCHASE_WO ([PWO_AUTO_KEY],[POD_AUTO_KEY],[WOB_AUTO_KEY],[QTY_ORDERED],[QTY_REC],[CRQ_AUTO_KEY],[CONVERTED],[CONVERSION_ID],[SYSTEM],[ROWID])
					SELECT [PWO_AUTO_KEY],[POD_AUTO_KEY],[WOB_AUTO_KEY],[QTY_ORDERED],[QTY_REC],[CRQ_AUTO_KEY],[CONVERTED],[CONVERSION_ID],[SYSTEM],[ROWID]
					FROM [Quantum].[QCTL_NEW_3].[PURCHASE_WO] POWO WHERE POWO.WOB_AUTO_KEY = @WOB_AUTO_KEY;

					DECLARE @WOMSLoopID AS INT;
					DECLARE @TotWOMSCount AS INT;
					SELECT @TotWOMSCount = COUNT(*), @WOMSLoopID = MIN(ID) FROM #PURCHASE_WO;

					WHILE (@WOMSLoopID <= @TotWOMSCount)
					BEGIN
						DECLARE @POD_AUTO_KEY BIGINT;
						DECLARE @PCC_AUTO_KEY_POD BIGINT;
						DECLARE @PNM_AUTO_KEY_POD BIGINT;
						DECLARE @POH_AUTO_KEY BIGINT;
						DECLARE @PO_Number VARCHAR(100);
						DECLARE @ConditionCode VARCHAR(100);
						DECLARE @PO_Id_IN_PAS BIGINT;
						DECLARE @ConditionId BIGINT;

						SELECT @POD_AUTO_KEY = POD_AUTO_KEY FROM #PURCHASE_WO WHERE ID = @WOMSLoopID;
						SELECT @PNM_AUTO_KEY_POD = POD.PNM_AUTO_KEY, @POH_AUTO_KEY = POH_AUTO_KEY, @PCC_AUTO_KEY_POD = POD.PCC_AUTO_KEY FROM [Quantum].[QCTL_NEW_3].[PO_DETAIL] POD WHERE POD.POD_AUTO_KEY = @POD_AUTO_KEY;

						SELECT @Part_NUMBER = IM.[PN], @Part_Desc = IM.[DESCRIPTION] FROM [Quantum].[QCTL_NEW_3].[PARTS_MASTER] IM  WITH(NOLOCK) WHERE IM.[PNM_AUTO_KEY] = @PNM_AUTO_KEY_POD;
						SELECT @ItemMaster_Id = IM.[ItemMasterId] FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE UPPER(IM.[partnumber]) = UPPER(@Part_NUMBER) AND UPPER(IM.[PartDescription]) = UPPER(@Part_Desc);

						SELECT @PO_Number = POH.PO_NUMBER FROM [Quantum].[QCTL_NEW_3].[PO_HEADER] POH WITH(NOLOCK) WHERE POH.[POH_AUTO_KEY] = @POH_AUTO_KEY;
						SELECT @PO_Id_IN_PAS = PO.PurchaseOrderId FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK) WHERE UPPER(PO.PurchaseOrderNumber) = UPPER(@PO_Number);

						SELECT @ConditionCode = CC.CONDITION_CODE FROM [Quantum].[QCTL_NEW_3].PART_CONDITION_CODES CC WHERE CC.PCC_AUTO_KEY = @PCC_AUTO_KEY_POD;
						SELECT @ConditionId = ConditionId FROM DBO.Condition Cond WHERE UPPER(Cond.Description) = UPPER(@ConditionCode);

						IF (@PO_Id_IN_PAS > 0)
						BEGIN
							IF EXISTS (SELECT TOP 1 1 FROM [dbo].[PurchaseOrder] PO WHERE PO.PurchaseOrderId = @PO_Id_IN_PAS AND PO.MasterCompanyId = @FromMasterComanyID)
							BEGIN
								DECLARE @PO_Part_Id BIGINT = 0;
								SELECT @PO_Part_Id = POP.PurchaseOrderPartRecordId FROM [dbo].[PurchaseOrderPart] POP WHERE POP.PurchaseOrderId = @PO_Id_IN_PAS AND POP.ItemMasterId = @ItemMaster_Id AND POP.ConditionId = @ConditionId;

								IF (@PO_Part_Id > 0)
								BEGIN
									DECLARE @WO_Materials_Id BIGINT;

									SELECT @WO_Materials_Id = WOM.WorkOrderMaterialsId FROM DBO.WorkOrderMaterials WOM WHERE WOM.WorkOrderId = @WorkOrder_Id_In_PAS AND WOM.ItemMasterId = @ItemMaster_Id AND WOM.ConditionCodeId = @ConditionId AND WOM.MasterCompanyId = @FromMasterComanyID;

									UPDATE WOM
									SET WOM.POId = @PO_Id_IN_PAS
									FROM DBO.WorkOrderMaterials WOM WHERE WOM.WorkOrderMaterialsId = @WO_Materials_Id;

									UPDATE POP
									SET POP.WorkOrderId = @WorkOrder_Id_In_PAS
									FROM [DBO].[PurchaseOrderPart] POP
									WHERE POP.PurchaseOrderPartRecordId = @PO_Part_Id AND POP.MasterCompanyId = @FromMasterComanyID AND POP.WorkOrderId IS NULL;
								END
							END
						END

						SET @WOMSLoopID = @WOMSLoopID + 1;
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
	  ,@AdhocComments varchar(150) = 'LinkWOToPO'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END