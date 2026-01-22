/*************************************************************             
 ** File:   [LinkWOToRO]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to link Work Order to RO Records
 ** Purpose:           
 ** Date:   02/05/2024

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    02/05/2024   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC LinkWOToRO @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=12,@UserName=N'ROGER BENTLY',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[LinkWOToRO]
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

		IF OBJECT_ID(N'tempdb..#RODetail') IS NOT NULL
		BEGIN
			DROP TABLE #RODetail
		END

		CREATE TABLE #RODetail
		(
			ID bigint NOT NULL IDENTITY,
			[ROPartId] [bigint] NOT NULL,
			[SOPartId] [bigint] NULL,
			[ItemMasterId] [bigint] NULL,
			[PartConditionCodeId] [bigint] NULL,
			[ROHeaderId] [bigint] NULL,
			[SysUserId] [bigint] NULL,
			[ExchangeRate] [decimal](18, 2) NULL,
			[EntryDate] [datetime2](7) NULL,
			[ItemNumber] [varchar](100) NULL,
			[LaborCost] [decimal](18, 2) NULL,
			[LastDeliveryDate] [datetime2](7) NULL,
			[MiscCost] [decimal](18, 2) NULL,
			[NextDeliveryDate] [datetime2](7) NULL,
			[PartsCost] [decimal](18, 2) NULL,
			[RepairNotes] [varchar](max) NULL,
			[SerialNumber] [varchar](max) NULL,
			[QtyRepair] [int] NULL,
			[QtyReserved] [int] NULL,
			[QtyRepaired] [int] NULL,
			[QtyScrapped] [int] NULL,
			[ItemMasterModify] [varchar](100) NULL,
			[WOMaterialId] [bigint] NULL,
			[WOOperationId] [bigint] NULL,
			[QtyBilled] [int] NULL,
			[HasPieceParts] [varchar](10) NULL,
			[ReceiverInstr] [varchar](max) NULL,
			[CapitalizeCost] [decimal](18, 2) NULL,
			[ExpenseCost] [decimal](18, 2) NULL,
			[VendorAdj] [int] NULL,
			[WOTaskId] [bigint] NULL,
			[EstPrice] [decimal](18, 2) NULL,
			[FlatRate] [varchar](10) NULL,
			[QtyRecIncr] [int] NULL,
			[LastModified] [datetime2](7) NULL,
			[SysUserModifiedId] [bigint] NULL,
			[TaxAmount] [decimal](18, 2) NULL,
			[ForeignTaxAmount] [decimal](18, 2) NULL,
			[CalcTax] [varchar](10) NULL,
			[ROCategoryCodeId] [bigint] NULL,
			[CalibrationFlag] [varchar](10) NULL,
			[ContryCodeId] [bigint] NULL,
			[ApplicationCodeId] [bigint] NULL,
			[CommitShipDate] [datetime2](7) NULL,
			[ShopFindings] [varchar](100) NULL,
			[FinalRemarks] [varchar](100) NULL,
			[ROType] [varchar](100) NULL,
			[StockCategoryId] [bigint] NULL,
			[CapabilityCodeId] [bigint] NULL,
			[GroupNumber] [varchar](100) NULL,
			[RODetailSplitFrom] [varchar](100) NULL,
			[TrackingNumber] [varchar](100) NULL,
			[ShipDate] [datetime2](7) NULL,
			[MasterCompanyId] [bigint] NULL,
			[Migrated_Id] [bigint] NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL
		)

		INSERT INTO #RODetail ([ROPartId],[SOPartId],[ItemMasterId],[PartConditionCodeId],[ROHeaderId],[SysUserId],[ExchangeRate],[EntryDate],[ItemNumber],[LaborCost],[LastDeliveryDate],[MiscCost],[NextDeliveryDate],
		[PartsCost],[RepairNotes],[SerialNumber],[QtyRepair],[QtyReserved],[QtyRepaired],[QtyScrapped],[ItemMasterModify],[WOMaterialId],[WOOperationId],[QtyBilled],[HasPieceParts],[ReceiverInstr],[CapitalizeCost],[ExpenseCost],
		[VendorAdj],[WOTaskId],[EstPrice],[FlatRate],[QtyRecIncr],[LastModified],[SysUserModifiedId],[TaxAmount],[ForeignTaxAmount],[CalcTax],[ROCategoryCodeId],[CalibrationFlag],[ContryCodeId],[ApplicationCodeId],[CommitShipDate],
		[ShopFindings],[FinalRemarks],[ROType],[StockCategoryId],[CapabilityCodeId],[GroupNumber],[RODetailSplitFrom],[TrackingNumber],[ShipDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT [ROPartId],[SOPartId],[ItemMasterId],[PartConditionCodeId],[ROHeaderId],[SysUserId],[ExchangeRate],[EntryDate],[ItemNumber],[LaborCost],[LastDeliveryDate],[MiscCost],[NextDeliveryDate],
		[PartsCost],[RepairNotes],[SerialNumber],[QtyRepair],[QtyReserved],[QtyRepaired],[QtyScrapped],[ItemMasterModify],[WOMaterialId],[WOOperationId],[QtyBilled],[HasPieceParts],[ReceiverInstr],[CapitalizeCost],[ExpenseCost],
		[VendorAdj],[WOTaskId],[EstPrice],[FlatRate],[QtyRecIncr],[LastModified],[SysUserModifiedId],[TaxAmount],[ForeignTaxAmount],[CalcTax],[ROCategoryCodeId],[CalibrationFlag],[ContryCodeId],[ApplicationCodeId],[CommitShipDate],
		[ShopFindings],[FinalRemarks],[ROType],[StockCategoryId],[CapabilityCodeId],[GroupNumber],[RODetailSplitFrom],[TrackingNumber],[ShipDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
		FROM [Quantum_Staging].dbo.[RepairOrderParts] ROP WITH (NOLOCK);

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #RODetail;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;
			
			DECLARE @PCC_AUTO_KEY BIGINT;
			DECLARE @ROH_AUTO_KEY BIGINT;
			DECLARE @SOD_AUTO_KEY BIGINT;
			DECLARE @ROD_AUTO_KEY BIGINT;
			DECLARE @WOB_AUTO_KEY BIGINT;
			DECLARE @RO_Id BIGINT = 0;
			DECLARE @RO_NUMBER VARCHAR(50);
			DECLARE @ItemMaster_Id BIGINT;
			DECLARE @Part_NUMBER VARCHAR(50);
			DECLARE @Part_Desc VARCHAR(50);
			DECLARE @PNM_AUTO_KEY BIGINT = 0;
			DECLARE @ConditionCode VARCHAR(50);

			SELECT @PNM_AUTO_KEY = ItemMasterId, @PCC_AUTO_KEY = PartConditionCodeId, @ROH_AUTO_KEY = ROHeaderId, @SOD_AUTO_KEY = SOPartId , @ROD_AUTO_KEY = ROPartId, @WOB_AUTO_KEY = WOMaterialId FROM #RODetail WHERE ID = @LoopID;

			SELECT @RO_Id = RO.[RepairOrderId] FROM dbo.[RepairOrder] RO WITH(NOLOCK) WHERE RO.[RepairOrderNumber] = @RO_NUMBER;
			SELECT @Part_NUMBER = IM.PN, @Part_Desc = IM.[DESCRIPTION] FROM [Quantum].[QCTL_NEW_3].[PARTS_MASTER] IM  WITH(NOLOCK) WHERE IM.PNM_AUTO_KEY = @PNM_AUTO_KEY;
			SELECT @ConditionCode = CC.CONDITION_CODE FROM [Quantum].QCTL_NEW_3.[PART_CONDITION_CODES] CC WITH(NOLOCK) WHERE CC.PCC_AUTO_KEY = @PCC_AUTO_KEY;
			SELECT @ItemMaster_Id = IM.ItemMasterId FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE UPPER(IM.partnumber) = UPPER(@Part_NUMBER) AND UPPER(IM.PartDescription) = UPPER(@Part_Desc);

			IF EXISTS (SELECT TOP 1 1 FROM [dbo].[RepairOrderPart] WITH(NOLOCK) WHERE [RepairOrderId] = @RO_Id AND [ItemMasterId] = @ItemMaster_Id AND [MasterCompanyId] = @FromMasterComanyID)
			BEGIN
				DECLARE @WOM_PNM_AUTO_KEY BIGINT;
				DECLARE @WOO_AUTO_KEY BIGINT;
				DECLARE @SI_NUMBER VARCHAR(100);
				DECLARE @WO_Id BIGINT;
				DECLARE @ConditionId BIGINT;
				DECLARE @RepairOrderPartRecordId BIGINT;
				DECLARE @StocklineId BIGINT = NULL;

				SELECT @WOM_PNM_AUTO_KEY = [PNM_AUTO_KEY], @WOO_AUTO_KEY = WOO_AUTO_KEY FROM Quantum.QCTL_NEW_3.WO_BOM WHERE [WOB_AUTO_KEY] = @WOB_AUTO_KEY;
				SELECT @SI_NUMBER = WO.SI_NUMBER FROM Quantum.QCTL_NEW_3.WO_OPERATION WO WHERE WO.WOO_AUTO_KEY = @WOO_AUTO_KEY;
			
				SELECT @WO_Id = WO.WorkOrderId FROM DBO.WorkOrder WO WHERE UPPER(WO.WorkOrderNum) = UPPER(@SI_NUMBER) AND MasterCompanyId = @FromMasterComanyID;
				SELECT @ConditionId = [ConditionId] FROM [dbo].[Condition] Cond WITH(NOLOCK) WHERE UPPER(Cond.Description) = UPPER(@ConditionCode) AND [MasterCompanyId] = @FromMasterComanyID;

				SELECT @RepairOrderPartRecordId = RepairOrderPartRecordId, @StocklineId = StockLineId FROM [dbo].[RepairOrderPart] WITH(NOLOCK) 
				WHERE [RepairOrderId] = @RO_Id AND [ItemMasterId] = @ItemMaster_Id AND ConditionId = @ConditionId AND [MasterCompanyId] = @FromMasterComanyID;

				IF (ISNULL(@WO_Id, 0) != 0)
				BEGIN
					DECLARE @WO_Materials_Id BIGINT;

					SELECT @WO_Materials_Id = WOM.WorkOrderMaterialsId FROM DBO.WorkOrderMaterials WOM WHERE WOM.WorkOrderId = @WO_Id AND WOM.ItemMasterId = @ItemMaster_Id AND WOM.ConditionCodeId = @ConditionId AND WOM.MasterCompanyId = @FromMasterComanyID;

					PRINT @WO_Id;
					PRINT @ConditionId;
					PRINT @ItemMaster_Id;
					PRINT @StocklineId;
					PRINT @RO_Id;
					PRINT @WO_Materials_Id;

					UPDATE WOMS
					SET WOMS.RepairOrderId = @RO_Id
					FROM DBO.WorkOrderMaterialStockLine WOMS WHERE WOMS.StockLineId = @StocklineId;

					UPDATE ROP
					SET ROP.WorkOrderId = @WO_Id
					FROM DBO.RepairOrderPart ROP WHERE ROP.RepairOrderPartRecordId = @RepairOrderPartRecordId;
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
	  ,@AdhocComments varchar(150) = 'LinkWOToRO'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END