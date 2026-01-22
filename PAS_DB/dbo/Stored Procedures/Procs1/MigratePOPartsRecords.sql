/*************************************************************             
 ** File:   [MigratePOPartsRecords]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate Purchase Order Parts Records
 ** Purpose:           
 ** Date:   12/12/2023

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    12/12/2023   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigratePOPartsRecords @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=12,@UserName=N'ROGER BENTLY',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigratePOPartsRecords]
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

		IF OBJECT_ID(N'tempdb..#TempPOPart') IS NOT NULL
		BEGIN
			DROP TABLE #TempPOPart
		END

		CREATE TABLE #TempPOPart
		(
			ID bigint NOT NULL IDENTITY,
			[POPartId] [bigint] NOT NULL,
			[ItemMasterId] [bigint] NULL,
			[AltItemMasterId] [bigint] NULL,
			[ConditionId] [bigint] NULL,
			[UnitOfMeasureId] [bigint] NULL,
			[POHeaderId] [bigint] NULL,
			[UserId] [bigint] NULL,
			[BuyAsType] VARCHAR(50) NULL,
			[EntryDate] Datetime2(7) NULL,
			[ExchangeRate] decimal(18, 2) NULL,
			[ItemNumber] VARCHAR(100) NULL,
			[LastDeliveryDate] Datetime2(7) NULL,
			[NextDeliveryDate] Datetime2(7) NULL,
			[Notes] VARCHAR(max) NULL,
			[QtyBackOrder] [int] NULL,
			[QtyOrdered] [int] NULL,
			[QtyRec] [int] NULL,
			[UnitCost] decimal(18, 2) NULL,
			[STR_Id] [int] NULL,
			[VendorPrice] decimal(18, 2) NULL,
			[POCategoryId] [bigint] NULL,
			[SODetailLink] VARCHAR(100) NULL,
			[ReceiverInstr] VARCHAR(200) NULL,
			[DSC_Id] [bigint] NULL,
			[Warehouse_Id] [bigint] NULL,
			[ListPrice] decimal(18, 2) NULL,
			[Remarks] VARCHAR(250) NULL,
			[EDINumber] VARCHAR(100) NULL,
			[ConsignmentCodeId] [bigint] NULL,
			[HasPieceParts] VARCHAR(10) NULL,
			[SHM_Id] [bigint] NULL,
			[StockCategoryCodeId] [bigint] NULL,
			[WorkOrderOperationId] [bigint] NULL,
			[ShipDate] Datetime2(7) NULL,
			[TrackingNumber] VARCHAR(250) NULL,
			[MasterCompanyId] BIGINT NULL,
			[Migrated_Id] BIGINT NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL
		)

		INSERT INTO #TempPOPart ([POPartId],[ItemMasterId],[AltItemMasterId],[ConditionId],[UnitOfMeasureId],[POHeaderId],[UserId],[BuyAsType],[EntryDate],[ExchangeRate],[ItemNumber],[LastDeliveryDate],[NextDeliveryDate],
		[Notes],[QtyBackOrder],[QtyOrdered],[QtyRec],[UnitCost],[STR_Id],[VendorPrice],[POCategoryId],[SODetailLink],[ReceiverInstr],[DSC_Id],[Warehouse_Id],[ListPrice],[Remarks],[EDINumber],[ConsignmentCodeId],
		[HasPieceParts],[SHM_Id],[StockCategoryCodeId],[WorkOrderOperationId],[ShipDate],[TrackingNumber],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT [POPartId],[ItemMasterId],[AltItemMasterId],[ConditionId],[UnitOfMeasureId],[POHeaderId],[UserId],[BuyAsType],[EntryDate],[ExchangeRate],[ItemNumber],[LastDeliveryDate],[NextDeliveryDate],
		[Notes],[QtyBackOrder],[QtyOrdered],[QtyRec],[UnitCost],[STR_Id],[VendorPrice],[POCategoryId],[SODetailLink],[ReceiverInstr],[DSC_Id],[Warehouse_Id],[ListPrice],[Remarks],[EDINumber],[ConsignmentCodeId],
		[HasPieceParts],[SHM_Id],[StockCategoryCodeId],[WorkOrderOperationId],[ShipDate],[TrackingNumber],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
		FROM [Quantum_Staging].dbo.[PurchaseOrderParts] POP WITH (NOLOCK) WHERE POP.Migrated_Id IS NULL;

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempPOPart;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;
			
			DECLARE @PNM_AUTO_KEY BIGINT = 0;
			DECLARE @ALT_PNM_AUTO_KEY BIGINT = 0;
			DECLARE @PCC_AUTO_KEY BIGINT = 0;
			DECLARE @UOM_AUTO_KEY BIGINT = 0;
			DECLARE @POH_AUTO_KEY BIGINT = 0;
			DECLARE @UOMId BIGINT = 0;
			DECLARE @UOMCode VARCHAR(50) = '';
			DECLARE @PO_NUMBER VARCHAR(50) = '';
			DECLARE @PO_Id BIGINT = 0;
			DECLARE @Part_NUMBER VARCHAR(50) = '';
			DECLARE @ALT_Part_NUMBER VARCHAR(50) = '';
			DECLARE @Part_Desc VARCHAR(50) = '';
			DECLARE @ALT_Part_Desc VARCHAR(50) = '';
			DECLARE @ConditionCode VARCHAR(50) = '';
			DECLARE @ItemMaster_Id BIGINT = 0;
			DECLARE @ALT_ItemMaster_Id BIGINT = 0;
			DECLARE @ManagementStructureId BIGINT;
			DECLARE @ManufacturerId BIGINT;
			DECLARE @IsPMA BIT, @IsDER BIT;
			DECLARE @ManufacturerName VARCHAR(100);
			DECLARE @GLAccountId BIGINT;
			DECLARE @GLAccount VARCHAR(200);
			DECLARE @PriorityId BIGINT = 0;
			DECLARE @Priority VARCHAR(100);
			DECLARE @NeedByDate DATETIME2 = NULL;

			DECLARE @FoundError BIT = 0;
			DECLARE @ErrorMsg VARCHAR(MAX) = '';
			DECLARE @CurrentPurchaseOrderPartId BIGINT = 0;

			SELECT @CurrentPurchaseOrderPartId = [POPartId], @PNM_AUTO_KEY = ItemMasterId, @ALT_PNM_AUTO_KEY = AltItemMasterId, @PCC_AUTO_KEY = ConditionId, @UOM_AUTO_KEY = UnitOfMeasureId, @POH_AUTO_KEY = POHeaderId FROM #TempPOPart WHERE ID = @LoopID;

			SELECT @UOMId = UOM.UnitOfMeasureId, @UOMCode = UOM.ShortName FROM DBO.UnitOfMeasure UOM WHERE UPPER(UOM.ShortName) IN (SELECT UPPER(UOM_CODE) FROM [Quantum].QCTL_NEW_3.UOM_CODES Where UOM_AUTO_KEY = @UOM_AUTO_KEY) AND MasterCompanyId = @FromMasterComanyID;
			SELECT @PO_NUMBER = PO.PO_NUMBER FROM [Quantum].QCTL_NEW_3.PO_HEADER PO WHERE PO.POH_AUTO_KEY = @POH_AUTO_KEY;
			SELECT @PO_Id = PurchaseOrderId FROM DBO.PurchaseOrder PO WHERE PO.PurchaseOrderNumber = @PO_NUMBER;
	
			SELECT @Part_NUMBER = IM.PN, @Part_Desc = IM.DESCRIPTION FROM [Quantum].QCTL_NEW_3.PARTS_MASTER IM WHERE IM.PNM_AUTO_KEY = @PNM_AUTO_KEY;
			SELECT @ALT_Part_NUMBER = IM.PN, @ALT_Part_Desc = IM.DESCRIPTION FROM [Quantum].QCTL_NEW_3.PARTS_MASTER IM WHERE IM.PNM_AUTO_KEY = @ALT_PNM_AUTO_KEY;
			SELECT @ConditionCode = CC.CONDITION_CODE FROM [Quantum].QCTL_NEW_3.PART_CONDITION_CODES CC WHERE CC.PCC_AUTO_KEY = @PCC_AUTO_KEY;
			SELECT @ItemMaster_Id = IM.ItemMasterId FROM DBO.ItemMaster IM WHERE UPPER(IM.partnumber) = UPPER(@Part_NUMBER) AND UPPER(IM.PartDescription) = UPPER(@Part_Desc) AND IM.MasterCompanyId = @FromMasterComanyID;
			SELECT @ALT_ItemMaster_Id = IM.ItemMasterId FROM DBO.ItemMaster IM WHERE UPPER(IM.partnumber) = UPPER(@ALT_Part_NUMBER) AND UPPER(IM.PartDescription) = UPPER(@ALT_Part_Desc);

			SELECT TOP 1 @ManagementStructureId = MS.ManagementStructureId FROM DBO.ManagementStructure MS WHERE [MasterCompanyId] = @FromMasterComanyID;

			SELECT @Part_NUMBER = IM.partnumber, @Part_Desc = IM.PartDescription, @IsPMA = IM.IsPma, @IsDER = IM.IsDER, @ManufacturerId = IM.ManufacturerId, @ManufacturerName = IM.ManufacturerName, @GLAccountId = GLAccountId, @GLAccount = GLAccount FROM DBO.ItemMaster IM WHERE IM.ItemMasterId = @ItemMaster_Id AND MasterCompanyId = @FromMasterComanyID;SELECT @Part_NUMBER = IM.partnumber, @Part_Desc = IM.PartDescription, @IsPMA = IM.IsPma, @IsDER = IM.IsDER, @ManufacturerId = IM.ManufacturerId, @ManufacturerName = IM.ManufacturerName, @GLAccountId = GLAccountId, @GLAccount = GLAccount FROM DBO.ItemMaster IM WHERE IM.ItemMasterId = @ItemMaster_Id AND MasterCompanyId = @FromMasterComanyID;
			SELECT @PriorityId = PriorityId, @Priority = [Priority], @NeedByDate = NeedByDate FROM DBO.PurchaseOrder PO WHERE PO.PurchaseOrderNumber = @PO_NUMBER AND MasterCompanyId = @FromMasterComanyID;

			IF (ISNULL(@ManufacturerId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Manufacturer Id not found on part number</p>'
			END
			IF (ISNULL(@PriorityId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Priority Id not found on part number</p>'
			END
			IF (@NeedByDate = NULL)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Need By Date not found on part number</p>'
			END
			IF (ISNULL(@ManagementStructureId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Management Structure Id not found</p>'
			END
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
			IF (ISNULL(@POH_AUTO_KEY, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>PO Header Id not found</p>'
			END
			
			IF (@FoundError = 1)
			BEGIN
				UPDATE POP
				SET POP.ErrorMsg = @ErrorMsg
				FROM [Quantum_Staging].DBO.PurchaseOrderParts POP WHERE POP.POPartId = @CurrentPurchaseOrderPartId;

				SET @RecordsWithError = @RecordsWithError + 1;
			END

			DECLARE @InsertedPurchaseOrderId BIGINT;

			IF (@FoundError = 0)
			BEGIN
				IF NOT EXISTS(SELECT * FROM DBO.PurchaseOrderPart WHERE PurchaseOrderId = @PO_Id AND ItemMasterId = @ItemMaster_Id AND MasterCompanyId = @FromMasterComanyID)
				BEGIN
					DECLARE @ConditionId BIGINT;
					DECLARE @CurrencyId BIGINT;
					DECLARE @ItemTypeId BIGINT;
					DECLARE @Level1 VARCHAR(100);
					DECLARE @ManagementStructureTypeId BIGINT = 0;
					DECLARE @POPartModuleId BIGINT;

					SELECT @Part_NUMBER = IM.partnumber, @Part_Desc = IM.PartDescription, @IsPMA = IM.IsPma, @IsDER = IM.IsDER, @ManufacturerId = IM.ManufacturerId, @ManufacturerName = IM.ManufacturerName, @GLAccountId = GLAccountId, @GLAccount = GLAccount FROM DBO.ItemMaster IM WHERE IM.ItemMasterId = @ItemMaster_Id AND MasterCompanyId = @FromMasterComanyID;
					SELECT @ALT_Part_NUMBER = IM.partnumber, @ALT_Part_Desc = IM.PartDescription FROM DBO.ItemMaster IM WHERE IM.ItemMasterId = @ALT_ItemMaster_Id AND MasterCompanyId = @FromMasterComanyID;
					SELECT @ConditionId = ConditionId FROM DBO.Condition Cond WHERE UPPER(Cond.Code) = UPPER(@ConditionCode) AND MasterCompanyId = @FromMasterComanyID;
					SELECT @CurrencyId = CurrencyId FROM DBO.[Currency] C WHERE UPPER(Code) = 'USD' AND MasterCompanyId = @FromMasterComanyID;
					SELECT @ItemTypeId = ItemTypeId FROM DBO.[ItemType] IT WHERE UPPER([Name]) = 'STOCK';
					SELECT TOP 1 @ManagementStructureId = MS.ManagementStructureId FROM DBO.ManagementStructure MS WHERE [MasterCompanyId] = @FromMasterComanyID;
					SELECT @ManagementStructureTypeId = MST.TypeID FROM DBO.ManagementStructureType MST WHERE MST.[Description] = 'LE' AND MST.[MasterCompanyId] = @FromMasterComanyID;
					SELECT @Level1 = (MSL.Code + ' - ' + MSL.[Description]) FROM DBO.ManagementStructureLevel MSL WHERE MSL.TypeID = @ManagementStructureTypeId AND MSL.[MasterCompanyId] = @FromMasterComanyID;
					
					SET @ConditionId = ISNULL(@ConditionId, (SELECT ConditionId FROM DBO.Condition Cond WHERE Cond.Code = 'NEW' AND MasterCompanyId = @FromMasterComanyID));

					INSERT INTO DBO.PurchaseOrderPart
					([PurchaseOrderId],[ItemMasterId],[PartNumber],[PartDescription],[AltEquiPartNumberId],[AltEquiPartNumber],[AltEquiPartDescription],[StockType],
					[ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[ConditionId],[Condition],[QuantityOrdered],[QuantityBackOrdered],[QuantityRejected],
					[VendorListPrice],[DiscountPercent],[DiscountPerUnit],[DiscountAmount],[UnitCost],[ExtendedCost],[FunctionalCurrencyId],[FunctionalCurrency],
					[ForeignExchangeRate],[ReportCurrencyId],[ReportCurrency],[WorkOrderId],[WorkOrderNo],[SubWorkOrderId],[SubWorkOrderNo],[RepairOrderId],[ReapairOrderNo],
					[SalesOrderId],[SalesOrderNo],[ItemTypeId],[ItemType],[GlAccountId],[GLAccount],[UOMId],[UnitOfMeasure],[ManagementStructureId],[Level1],[Level2],
					[Level3],[Level4],[ParentId],[isParent],[Memo],[POPartSplitUserTypeId],[POPartSplitUserType],[POPartSplitUserId],[POPartSplitUser],[POPartSplitSiteId],
					[POPartSplitSiteName],[POPartSplitAddressId],[POPartSplitAddress1],[POPartSplitAddress2],[POPartSplitAddress3],[POPartSplitCity],[POPartSplitState],
					[POPartSplitPostalCode],[POPartSplitCountryId],[POPartSplitCountryName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],
					[IsDeleted],[DiscountPercentValue],[EstDeliveryDate],[ExchangeSalesOrderId],[ExchangeSalesOrderNo],[ManufacturerPN],[AssetModel],[AssetClass])
					SELECT @PO_Id, @ItemMaster_Id, @Part_NUMBER, @Part_Desc, @ALT_ItemMaster_Id, @ALT_Part_NUMBER, @ALT_Part_Desc,
					CASE WHEN (@IsPMA = 1 AND @IsDER = 1) THEN 'PMA&DER' ELSE 
						CASE WHEN (@IsPMA = 1 AND @IsDER = 0) THEN 'PMA' ELSE
							CASE WHEN (@IsPMA = 0 AND @IsDER = 1) THEN 'DER' ELSE 'OEM' END
						END
					END,
					@ManufacturerId, @ManufacturerName, @PriorityId, @Priority, @NeedByDate, @ConditionId, @ConditionCode, POP.QtyOrdered, POP.QtyBackOrder, 0,
					CAST(ISNULL(POP.VendorPrice, 0) AS DECIMAL), 0, 0, 0, CAST(ISNULL(POP.VendorPrice, 0) AS DECIMAL), (CAST(ISNULL(POP.VendorPrice, 0) AS DECIMAL) * CAST(POP.QtyOrdered AS INT)), @CurrencyId, 'USD',
					CAST(POP.ExchangeRate AS DECIMAL), @CurrencyId, 'USD', NULL, NULL, NULL, NULL, NULL, NULL,
					NULL, NULL, @ItemTypeId, 'STOCK', @GLAccountId, @GLAccount, @UOMId, @UOMCode, @ManagementStructureId, @Level1, NULL,
					NULL, NULL,
					NULL, 1, -- Considering it does not have split parts
					POP.NOTES, NULL, NULL, NULL, NULL, NULL,
					NULL, NULL, NULL, NULL, NULL, NULL, NULL,
					NULL, NULL, NULL, @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1,
					0, NULL, CASE WHEN POP.NextDeliveryDate IS NOT NULL THEN CAST(POP.NextDeliveryDate AS datetime2) ELSE NULL END, NULL, NULL, NULL, NULL, NULL
					FROM #TempPOPart AS POP WHERE ID = @LoopID;

					SELECT @InsertedPurchaseOrderId = SCOPE_IDENTITY();

					SELECT @POPartModuleId = [ManagementStructureModuleId] FROM dbo.[ManagementStructureModule] WHERE [ModuleName] = 'POPart';				 						 				 

					EXEC [dbo].[PROCAddPOMSData] @InsertedPurchaseOrderId,@ManagementStructureId,@FromMasterComanyID,@UserName,@UserName,@POPartModuleId,3,0;

					UPDATE POP
					SET POP.Migrated_Id = @InsertedPurchaseOrderId,
					POP.SuccessMsg = 'Record migrated successfully'
					FROM [Quantum_Staging].DBO.PurchaseOrderParts POP WHERE POP.POPartId = @CurrentPurchaseOrderPartId;

					SET @MigratedRecords = @MigratedRecords + 1;
				END
				ELSE
				BEGIN
					UPDATE POP
					SET POP.ErrorMsg = ISNULL(ErrorMsg, '') + '<p>Purchase Order Part record already exists</p>'
					FROM [Quantum_Staging].DBO.PurchaseOrderParts POP WHERE POP.POPartId = @CurrentPurchaseOrderPartId;

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