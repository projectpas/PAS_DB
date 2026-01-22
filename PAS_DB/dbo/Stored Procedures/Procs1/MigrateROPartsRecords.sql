/*************************************************************             
 ** File:   [MigrateROPartsRecords]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate Repair Order Parts Records
 ** Purpose:           
 ** Date:   12/12/2023

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    12/23/2023   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigrateROPartsRecords @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=12,@UserName=N'ROGER BENTLY',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigrateROPartsRecords]
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

		IF OBJECT_ID(N'tempdb..#TempROPart') IS NOT NULL
		BEGIN
			DROP TABLE #TempROPart
		END

		CREATE TABLE #TempROPart
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
			[ErrorMsg] [varchar](500) NULL,
		)

		INSERT INTO #TempROPart ([ROPartId],[SOPartId],[ItemMasterId],[PartConditionCodeId],[ROHeaderId],[SysUserId],[ExchangeRate],[EntryDate],[ItemNumber],[LaborCost],[LastDeliveryDate],[MiscCost],[NextDeliveryDate],
		[PartsCost],[RepairNotes],[SerialNumber],[QtyRepair],[QtyReserved],[QtyRepaired],[QtyScrapped],[ItemMasterModify],[WOMaterialId],[WOOperationId],[QtyBilled],[HasPieceParts],[ReceiverInstr],[CapitalizeCost],[ExpenseCost],
		[VendorAdj],[WOTaskId],[EstPrice],[FlatRate],[QtyRecIncr],[LastModified],[SysUserModifiedId],[TaxAmount],[ForeignTaxAmount],[CalcTax],[ROCategoryCodeId],[CalibrationFlag],[ContryCodeId],[ApplicationCodeId],[CommitShipDate],
		[ShopFindings],[FinalRemarks],[ROType],[StockCategoryId],[CapabilityCodeId],[GroupNumber],[RODetailSplitFrom],[TrackingNumber],[ShipDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT [ROPartId],[SOPartId],[ItemMasterId],[PartConditionCodeId],[ROHeaderId],[SysUserId],[ExchangeRate],[EntryDate],[ItemNumber],[LaborCost],[LastDeliveryDate],[MiscCost],[NextDeliveryDate],
		[PartsCost],[RepairNotes],[SerialNumber],[QtyRepair],[QtyReserved],[QtyRepaired],[QtyScrapped],[ItemMasterModify],[WOMaterialId],[WOOperationId],[QtyBilled],[HasPieceParts],[ReceiverInstr],[CapitalizeCost],[ExpenseCost],
		[VendorAdj],[WOTaskId],[EstPrice],[FlatRate],[QtyRecIncr],[LastModified],[SysUserModifiedId],[TaxAmount],[ForeignTaxAmount],[CalcTax],[ROCategoryCodeId],[CalibrationFlag],[ContryCodeId],[ApplicationCodeId],[CommitShipDate],
		[ShopFindings],[FinalRemarks],[ROType],[StockCategoryId],[CapabilityCodeId],[GroupNumber],[RODetailSplitFrom],[TrackingNumber],[ShipDate],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
		FROM [Quantum_Staging].dbo.[RepairOrderParts] ROP WITH (NOLOCK) WHERE ROP.Migrated_Id IS NULL;

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempROPart;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;
			
			DECLARE @PNM_AUTO_KEY BIGINT = 0;
			DECLARE @PCC_AUTO_KEY BIGINT;
			DECLARE @ROH_AUTO_KEY BIGINT;
			DECLARE @ROD_AUTO_KEY BIGINT;
			DECLARE @RONumber AS VARCHAR(50);
			DECLARE @RO_NUMBER VARCHAR(50);
			DECLARE @RO_Id BIGINT = 0;
			DECLARE @Part_NUMBER VARCHAR(50);
			DECLARE @Part_Desc VARCHAR(50);
			DECLARE @ConditionCode VARCHAR(50);
			DECLARE @ItemMaster_Id BIGINT;
			DECLARE @ALT_ItemMaster_Id BIGINT;
			DECLARE @ALT_Part_NUMBER VARCHAR(50);
			DECLARE @ALT_Part_Desc VARCHAR(50);
			DECLARE @UOMId BIGINT;
			DECLARE @IsPMA BIT, @IsDER BIT;
			DECLARE @ManufacturerId BIGINT;
			DECLARE @ManufacturerName VARCHAR(100);
			DECLARE @GLAccountId BIGINT;
			DECLARE @GLAccount VARCHAR(200);

			DECLARE @FoundError BIT = 0;
			DECLARE @ErrorMsg VARCHAR(MAX) = '';
			DECLARE @CurrentRepairOrderPartId BIGINT = 0;

			SELECT @CurrentRepairOrderPartId = [ROPartId], @PNM_AUTO_KEY = ItemMasterId, @PCC_AUTO_KEY = PartConditionCodeId, @ROH_AUTO_KEY = ROHeaderId, @ROD_AUTO_KEY = ROPartId FROM #TempROPart WHERE ID = @LoopID;

			SELECT @RO_NUMBER = RO.[RO_NUMBER] FROM [Quantum].[QCTL_NEW_3].[RO_HEADER] RO WITH(NOLOCK) WHERE RO.ROH_AUTO_KEY = @ROH_AUTO_KEY;
			SELECT @RO_Id = RO.[RepairOrderId] FROM dbo.[RepairOrder] RO WITH(NOLOCK) WHERE RO.[RepairOrderNumber] = @RO_NUMBER;		
			SELECT @Part_NUMBER = IM.PN, @Part_Desc = IM.[DESCRIPTION] FROM [Quantum].[QCTL_NEW_3].[PARTS_MASTER] IM  WITH(NOLOCK) WHERE IM.PNM_AUTO_KEY = @PNM_AUTO_KEY;
			SELECT @ConditionCode = CC.CONDITION_CODE FROM [Quantum].QCTL_NEW_3.[PART_CONDITION_CODES] CC WITH(NOLOCK) WHERE CC.PCC_AUTO_KEY = @PCC_AUTO_KEY;	   	  
			SELECT @ItemMaster_Id = IM.ItemMasterId FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE UPPER(IM.partnumber) = UPPER(@Part_NUMBER) AND UPPER(IM.PartDescription) = UPPER(@Part_Desc);
			SELECT @ALT_ItemMaster_Id = IM.ItemMasterId FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE UPPER(IM.partnumber) = UPPER(@ALT_Part_NUMBER) AND UPPER(IM.PartDescription) = UPPER(@ALT_Part_Desc);

			SELECT @UOMId = IM.[PurchaseUnitOfMeasureId], @Part_NUMBER = IM.[partnumber], @Part_Desc = IM.[PartDescription], @IsPMA = IM.[IsPma], @IsDER = IM.[IsDER], @ManufacturerId = IM.[ManufacturerId], @ManufacturerName = IM.[ManufacturerName], @GLAccountId = [GLAccountId], @GLAccount = [GLAccount] FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE IM.ItemMasterId = @ItemMaster_Id AND MasterCompanyId = @FromMasterComanyID;

			IF (ISNULL(@PNM_AUTO_KEY, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Item Master Id not found</p>'
			END
			IF (ISNULL(@PCC_AUTO_KEY, '') = '')
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Condition Id not found</p>'
			END
			IF (ISNULL(@GLAccountId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>GL Account Id not found</p>'
			END
			
			IF (@FoundError = 1)
			BEGIN
				UPDATE ROP
				SET ROP.ErrorMsg = @ErrorMsg
				FROM [Quantum_Staging].DBO.RepairOrderParts ROP WHERE ROP.ROPartId = @CurrentRepairOrderPartId;

				SET @RecordsWithError = @RecordsWithError + 1;
			END

			DECLARE @InsertedPurchaseOrderId BIGINT;

			IF (@FoundError = 0)
			BEGIN
				IF NOT EXISTS (SELECT * FROM DBO.RepairOrderPart WHERE RepairOrderId = @RO_Id AND ItemMasterId = @ItemMaster_Id AND MasterCompanyId = @FromMasterComanyID)
				BEGIN
					IF EXISTS (SELECT * FROM DBO.RepairOrder WHERE [RepairOrderNumber] = @RO_NUMBER AND MasterCompanyId = @FromMasterComanyID)
					BEGIN
						DECLARE @ConditionId BIGINT;
						DECLARE @PriorityId BIGINT;
						DECLARE @Priority VARCHAR(100);
						DECLARE @NeedByDate DATETIME2;
						DECLARE @CurrencyId BIGINT;
						DECLARE @ItemTypeId BIGINT;
						DECLARE @Level1 VARCHAR(100);
						DECLARE @ManagementStructureId BIGINT;
						DECLARE @WorkPerformedId BIGINT;
						DECLARE @ROPartModuleId BIGINT;
						DECLARE @UOMCode VARCHAR(50);
						DECLARE @VENDOR_PRICE DECIMAL(18,2) = 0;
						DECLARE @UNIT_COST DECIMAL(18,2) = 0;
						DECLARE @StockLineId BIGINT = NULL;
						DECLARE @STM_AUTO_KEY BIGINT = 0;
						DECLARE @STOCK_LINE  VARCHAR(50) = '';
						DECLARE @CTRL_ID VARCHAR(50) = '';
						DECLARE @CTRL_NUMBER VARCHAR(50) = '';
						DECLARE @StockLineNumber  VARCHAR(50) = '';
						DECLARE @ControlNumber VARCHAR(50) = '';
						DECLARE @IdNumber VARCHAR(50) = '';

						PRINT @RO_NUMBER;

						SELECT @UOMCode = UOM.ShortName FROM dbo.UnitOfMeasure UOM WITH(NOLOCK) WHERE UnitOfMeasureId = @UOMId;
						SELECT @ALT_Part_NUMBER = IM.[partnumber], @ALT_Part_Desc = IM.[PartDescription] FROM dbo.[ItemMaster] IM WITH(NOLOCK) WHERE IM.ItemMasterId = @ALT_ItemMaster_Id AND MasterCompanyId = @FromMasterComanyID;
						SELECT @PriorityId = [PriorityId], @Priority = [Priority], @NeedByDate = [NeedByDate] FROM [dbo].[RepairOrder] RO WITH(NOLOCK) WHERE RO.[RepairOrderNumber] = @RO_NUMBER;
						SELECT @ConditionId = [ConditionId] FROM [dbo].[Condition] Cond WITH(NOLOCK) WHERE (UPPER(Cond.Code) = UPPER(@ConditionCode) OR UPPER(Cond.Description) = UPPER(@ConditionCode)) AND [MasterCompanyId] = @FromMasterComanyID;
						SELECT @CurrencyId = [CurrencyId] FROM [dbo].[Currency] C WITH(NOLOCK) WHERE UPPER(Code) = 'USD' AND [MasterCompanyId] = @FromMasterComanyID;
						SELECT @ItemTypeId = [ItemTypeId] FROM [dbo].[ItemType] IT WITH(NOLOCK) WHERE UPPER([Name]) = 'STOCK';
						SELECT @WorkPerformedId = [CapabilityTypeId] FROM [dbo].[CapabilityType] CT WITH(NOLOCK) WHERE UPPER([Description]) = 'REP' AND [MasterCompanyId] = @FromMasterComanyID;
					
						SELECT @STM_AUTO_KEY = [STM_AUTO_KEY] FROM [Quantum].QCTL_NEW_3.STOCK_RESERVATIONS WITH(NOLOCK) WHERE [ROD_AUTO_KEY] = @ROD_AUTO_KEY;

						SELECT @PCC_AUTO_KEY = [PCC_AUTO_KEY], @STOCK_LINE = (CAST(ISNULL(STOCK_LINE, '') AS VARCHAR)), @CTRL_ID = (CAST(ISNULL(CTRL_ID, '') AS VARCHAR)), @CTRL_NUMBER = (CAST(ISNULL(CTRL_NUMBER, '') AS VARCHAR))
						FROM Quantum.QCTL_NEW_3.STOCK WHERE [STM_AUTO_KEY] = @STM_AUTO_KEY;
				
						SELECT @StockLineId = [StockLineId], @StockLineNumber = [StockLineNumber], @IdNumber = [IdNumber], @ControlNumber = [ControlNumber] 
						FROM [dbo].[Stockline] WITH(NOLOCK) 
						WHERE UPPER([StockLineNumber])  = UPPER(@STOCK_LINE) 
							   AND UPPER([IdNumber])  = UPPER(@CTRL_ID) 
							   AND UPPER([ControlNumber])  = UPPER(@CTRL_NUMBER)
							   AND [ItemMasterId] = @ItemMaster_Id;

						IF (@StockLineId IS NULL)
						BEGIN 
							SET @StockLineId = 0;
						END

						INSERT INTO [dbo].[RepairOrderPart]([RepairOrderId],[ItemMasterId],[PartNumber],[PartDescription],[AltEquiPartNumberId],[AltEquiPartNumber]
						  ,[AltEquiPartDescription],[StockType],[ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[ConditionId],[Condition]
						  ,[QuantityOrdered],[QuantityBackOrdered],[QuantityRejected],[VendorListPrice],[DiscountPercent],[DiscountPerUnit],[DiscountAmount]
						  ,[UnitCost],[ExtendedCost],[FunctionalCurrencyId],[FunctionalCurrency],[ForeignExchangeRate],[ReportCurrencyId],[ReportCurrency]
						  ,[StockLineId],[StockLineNumber],[ControlId],[ControlNumber],[PurchaseOrderNumber],[WorkOrderId],[WorkOrderNo],[SubWorkOrderId]
						  ,[SubWorkOrderNo],[SalesOrderId],[SalesOrderNo],[ItemTypeId],[ItemType],[GlAccountId],[GLAccount],[UOMId],[UnitOfMeasure]
						  ,[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[Memo],[ParentId],[IsParent],[RoPartSplitUserTypeId]
						  ,[RoPartSplitUserType],[RoPartSplitUserId],[RoPartSplitUser],[RoPartSplitSiteId],[RoPartSplitSiteName],[RoPartSplitAddressId]
						  ,[RoPartSplitAddress1],[RoPartSplitAddress2],[RoPartSplitAddress3],[RoPartSplitCity],[RoPartSplitStateOrProvince],[RoPartSplitPostalCode]
						  ,[RoPartSplitCountryId],[RoPartSplitCountry],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]
						  ,[RevisedPartId],[RevisedPartNumber],[WorkPerformedId],[WorkPerformed],[EstRecordDate],[VendorQuoteNoId],[VendorQuoteNo]
						  ,[VendorQuoteDate],[ACTailNum],[QuantityReserved],[IsAsset],[SerialNumber],[ManufacturerPN],[AssetModel],[AssetClass])
						SELECT @RO_Id, @ItemMaster_Id, @Part_NUMBER, @Part_Desc, @ALT_ItemMaster_Id, @ALT_Part_NUMBER,
							@ALT_Part_Desc, RO.ROType, @ManufacturerId, @ManufacturerName, @PriorityId, @Priority, @NeedByDate, @ConditionId, @ConditionCode,
							(CAST(ISNULL(RO.QtyRepair, 0) AS INT)), (CAST(ISNULL(RO.QtyRepair, 0) AS INT)), 0, (CAST(ISNULL(@VENDOR_PRICE, 0) AS DECIMAL)),0,0,0,
							(CAST(ISNULL(@UNIT_COST, 0) AS DECIMAL)), (CAST(ISNULL(@UNIT_COST, 0) AS DECIMAL) * CAST(RO.QtyRepair AS INT)), @CurrencyId, 'USD', CAST(RO.ExchangeRate AS DECIMAL), @CurrencyId, 'USD',
							@StockLineId,@StockLineNumber,@IdNumber,@ControlNumber,NULL,NULL,NULL,NULL,
							NULL,NULL,NULL,@ItemTypeId,'STOCK',@GLAccountId,@GLAccount,@UOMId, @UOMCode,
							@ManagementStructureId,NULL,NULL,NULL,NULL,RO.RepairNotes,NULL,1,NULL,
							NULL,NULL,NULL,NULL,NULL,NULL,
							NULL,NULL,NULL,NULL,NULL,NULL,
							NULL,NULL,@FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1, 0,
							NULL,NULL,@WorkPerformedId,'REP',CASE WHEN RO.NextDeliveryDate IS NOT NULL THEN CAST(RO.NextDeliveryDate AS datetime2) ELSE @NeedByDate END,NULL,NULL,
							NULL,NULL,(CAST(ISNULL(RO.QtyReserved, 0) AS INT)),0,RO.SerialNumber, NULL, NULL, NULL
						FROM #TempROPart AS RO WHERE ID = @LoopID;

						SELECT @InsertedPurchaseOrderId = SCOPE_IDENTITY();

						SELECT @ROPartModuleId = [ManagementStructureModuleId] FROM dbo.[ManagementStructureModule] WHERE [ModuleName] = 'ROPart';				 						 				 

						EXEC [dbo].[PROCAddROMSData] @InsertedPurchaseOrderId, @ManagementStructureId, @FromMasterComanyID, @UserName, @UserName, @ROPartModuleId, 1, 0;

						UPDATE ROP
						SET ROP.Migrated_Id = @InsertedPurchaseOrderId,
						ROP.SuccessMsg = 'Record migrated successfully'
						FROM [Quantum_Staging].DBO.RepairOrderParts ROP WHERE ROP.ROPartId = @CurrentRepairOrderPartId;

						SET @MigratedRecords = @MigratedRecords + 1;
					END
					ELSE
					BEGIN
						-- Repair Order not found
						DECLARE @NotFound INT;
					END
				END
				ELSE
				BEGIN
					UPDATE ROP
					SET ROP.ErrorMsg = ISNULL(ErrorMsg, '') + '<p>Repair Order Part record already exists</p>'
					FROM [Quantum_Staging].DBO.RepairOrderParts ROP WHERE ROP.ROPartId = @CurrentRepairOrderPartId;

					SET @RecordExits = @RecordExits + 1;
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
	  ,@AdhocComments varchar(150) = 'MigratePOPartsRecords'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END