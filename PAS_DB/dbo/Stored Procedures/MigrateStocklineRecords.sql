/*************************************************************             
 ** File:   [MigrateStocklineRecords]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate Stockline Records
 ** Purpose:           
 ** Date:   11/24/2023

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    11/24/2023   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigrateStocklineRecords @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=12,@UserName=N'ROGER BENTLY',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigrateStocklineRecords]
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

		IF OBJECT_ID(N'tempdb..#TempStockline') IS NOT NULL
		BEGIN
			DROP TABLE #TempStockline
		END

		CREATE TABLE #TempStockline
		(
			ID bigint NOT NULL IDENTITY,
			[StocklineId] [bigint] NOT NULL,
			[CustomerId] [bigint] NULL,
			[ManufacturerId] [bigint] NULL,
			[ConditionId] [bigint] NULL,
			[WarehouseId] [bigint] NULL,
			[LocationId] [bigint] NULL,
			[ItemMasterId] [bigint] NULL,
			[PartNumber] [varchar](100) NULL,
			[StocklineNumber] [varchar](100) NULL,
			[Ctrl_Number] [varchar](100) NULL,
			[Ctrl_ID] [varchar](100) NULL,
			[Qty_Received] [int] NULL,
			[Qty_OH] [int] NULL,
			[Qty_Available] [int] NULL,
			[Qty_Reserved] [int] NULL,
			[Qty_Adjusted] [int] NULL,
			[SerialNumber] [varchar](100) NULL,
			[ShelfLife] [varchar](10) NULL,
			[ExpirationDate] datetime2(7) NULL,
			[MfgLotNum] [varchar](100) NULL,
			[MfgDate] datetime2(7) NULL,
			[PartCertNumber] [varchar](100) NULL,
			[TagDate] datetime2(7) NULL,
			[CalibRemarks] [varchar](100) NULL,
			[OrderRecDate] datetime2(7) NULL,
			[OriginalCost] decimal(18, 2) NULL,
			[RepairOrderUnitCost] decimal(18, 2) NULL,
			[RecDate] datetime2(7) NULL,
			[ReceiverNumber] [varchar](100) NULL,
			[UnitPrice] decimal(18, 2) NULL,
			[CoreCost] decimal(18, 2) NULL,
			[UnitCost] decimal(18, 2) NULL,
			[HazardMaterial] bit NULL,
			[Notes] [varchar](max) NULL,
			[TailNumber] [varchar](100) NULL,
			[IsIncident] bit NULL,
			[IncidentReason] [varchar](max) NULL,
			[IsCustomerOwned] bit NULL,
			[TagNumber] [varchar](100) NULL,
			[Owner] [varchar](100) NULL,
			[TaggedBy] [varchar](100) NULL,
			[IsManuallyAdded] bit NULL,
			[MasterCompanyId] BIGINT NULL,
			[Migrated_Id] BIGINT NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL
		)

		INSERT INTO #TempStockline ([StocklineId],[CustomerId],[ManufacturerId],[ConditionId],[WarehouseId],[LocationId],[ItemMasterId],[PartNumber],[StocklineNumber],[Ctrl_Number],
		[Ctrl_ID],[Qty_Received],[Qty_OH],[Qty_Available],[Qty_Reserved],[Qty_Adjusted],[SerialNumber],[ShelfLife],[ExpirationDate],[MfgLotNum],[MfgDate],[PartCertNumber],[TagDate],
		[CalibRemarks],[OrderRecDate],[OriginalCost],[RepairOrderUnitCost],[RecDate],[ReceiverNumber],[UnitPrice],[CoreCost],[UnitCost],[HazardMaterial],[Notes],[TailNumber],[IsIncident],
		[IncidentReason],[IsCustomerOwned],[TagNumber],[Owner],[TaggedBy],[IsManuallyAdded],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT [StocklineId],[CustomerId],[ManufacturerId],[ConditionId],[WarehouseId],[LocationId],[ItemMasterId],[PartNumber],[StocklineNumber],[Ctrl_Number],
		[Ctrl_ID],[Qty_Received],[Qty_OH],[Qty_Available],[Qty_Reserved],[Qty_Adjusted],[SerialNumber],[ShelfLife],[ExpirationDate],[MfgLotNum],[MfgDate],[PartCertNumber],[TagDate],
		[CalibRemarks],[OrderRecDate],[OriginalCost],[RepairOrderUnitCost],[RecDate],[ReceiverNumber],[UnitPrice],[CoreCost],[UnitCost],[HazardMaterial],[Notes],[TailNumber],[IsIncident],
		[IncidentReason],[IsCustomerOwned],[TagNumber],[Owner],[TaggedBy],[IsManuallyAdded],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
		FROM [Quantum_Staging].dbo.[Stocklines] STK WITH (NOLOCK) WHERE STK.Migrated_Id IS NULL;

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempStockline;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;

			DECLARE @CurrentStocklineId BIGINT = 0;
			DECLARE @PN VARCHAR(100) = NULL;
			DECLARE @CurrentConditionId BIGINT = 0;
			DECLARE @CurrentWarehouseId BIGINT = 0;
			DECLARE @CurrentLocationId BIGINT = 0;
			DECLARE @CurrentManufacturerId BIGINT = 0;
			DECLARE @CurrentItemMasterId BIGINT = 0;
			DECLARE @CurrentCustomerId BIGINT = 0;
			DECLARE @CurrentStocklineNumber VARCHAR(100) = NULL;
			DECLARE @ManufacturerId BIGINT = 0;
			
			DECLARE @InsertedStocklineId BIGINT = 0;
			DECLARE @AssetAcquisitionTypeId_BUY BIGINT = 0;
			DECLARE @AssetAcquisitionTypeId_MAKE BIGINT = 0;

			DECLARE @FoundError BIT = 0;
			DECLARE @ErrorMsg VARCHAR(MAX) = '';

			SELECT @CurrentStocklineId = StocklineId, @CurrentConditionId = ConditionId, @CurrentWarehouseId = WarehouseId, @CurrentLocationId = LocationId, @CurrentManufacturerId = ManufacturerId,
			@CurrentItemMasterId = ItemMasterId, @CurrentCustomerId = CustomerId, @CurrentStocklineNumber = StocklineNumber
			FROM #TempStockline WHERE ID = @LoopID;

			IF (ISNULL(@CurrentConditionId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Condition is missing</p>'
			END
			IF (ISNULL(@CurrentManufacturerId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Manufacturer is missing</p>'
			END
			IF (ISNULL(@CurrentStocklineNumber, '') = '')
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Stockline Number is missing</p>'
			END
			IF (ISNULL(@CurrentWarehouseId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>@Warehouse is missing</p>'
			END
			
			IF (@FoundError = 1)
			BEGIN
				UPDATE Stk
				SET Stk.ErrorMsg = @ErrorMsg
				FROM [Quantum_Staging].DBO.Stocklines Stk WHERE Stk.StocklineId = @CurrentStocklineId;

				SET @RecordsWithError = @RecordsWithError + 1;
			END

			IF (@FoundError = 0)
			BEGIN
				DECLARE @ConditionId AS FLOAT;
				DECLARE @ConditionName AS VARCHAR(100);
				DECLARE @WarehouseId AS FLOAT;
				DECLARE @LocationId AS FLOAT;
				DECLARE @OwnerId AS FLOAT;
				DECLARE @ItemMasterId AS FLOAT;
				DECLARE @CustomerId AS FLOAT;
				DECLARE @EntityStructureId BIGINT;
				DECLARE @PurchaseUnitOfMeasureId BIGINT;
				DECLARE @ItemGroupId BIGINT;
				DECLARE @ItemManufacturerId BIGINT;

				SELECT @ConditionId = ConditionId, @ConditionName = [Description] FROM DBO.Condition MF WHERE UPPER(MF.[Code]) IN (SELECT UPPER(CONDITION_CODE) FROM [Quantum].QCTL_NEW_3.PART_CONDITION_CODES Where PCC_AUTO_KEY = @CurrentConditionId) AND MasterCompanyId = @FromMasterComanyID;
				SELECT @WarehouseId = WarehouseId FROM DBO.Warehouse WH WHERE UPPER(WH.[Name]) IN (SELECT UPPER(DESCRIPTION) FROM [Quantum].QCTL_NEW_3.WAREHOUSE Where WHS_AUTO_KEY = @CurrentWarehouseId) AND MasterCompanyId = @FromMasterComanyID;
				SELECT @LocationId = LocationId FROM DBO.[Location] LOC WHERE UPPER(LOC.[Name]) IN (SELECT UPPER(DESCRIPTION) FROM [Quantum].QCTL_NEW_3.LOCATION Where LOC_AUTO_KEY = @CurrentLocationId) AND MasterCompanyId = @FromMasterComanyID;
				SELECT @ManufacturerId = ManufacturerId FROM DBO.Manufacturer MF WHERE UPPER(MF.[Name]) IN (SELECT UPPER(DESCRIPTION) FROM [Quantum].QCTL_NEW_3.MANUFACTURER Where MFG_AUTO_KEY = @CurrentManufacturerId) AND MasterCompanyId = @FromMasterComanyID;
				SELECT @ItemMasterId = ItemMasterId FROM DBO.ItemMaster IM WHERE UPPER(IM.[partnumber]) IN (SELECT UPPER(PN) FROM [Quantum].QCTL_NEW_3.PARTS_MASTER Where PNM_AUTO_KEY = @CurrentItemMasterId) AND MasterCompanyId = @FromMasterComanyID;
				SELECT @CustomerId = CustomerId FROM DBO.Customer C WHERE UPPER(C.[Name]) IN (SELECT UPPER(COMPANY_NAME) FROM [Quantum].QCTL_NEW_3.COMPANIES Where CMP_AUTO_KEY = @CurrentCustomerId) AND MasterCompanyId = @FromMasterComanyID;
				SELECT @PurchaseUnitOfMeasureId = IM.PurchaseUnitOfMeasureId FROM DBO.ItemMaster IM WHERE ItemMasterId = @ItemMasterId;
				SELECT @ItemGroupId = IM.ItemGroupId FROM DBO.ItemMaster IM WHERE ItemMasterId = @ItemMasterId;
				SELECT @ItemManufacturerId = IM.ManufacturerId FROM DBO.ItemMaster IM WHERE ItemMasterId = @ItemMasterId;

				SET @EntityStructureId = 37;
				DECLARE @OwnerType INT = 4; -- Others

				DECLARE @DefaultSiteId BIGINT;
				SELECT @DefaultSiteId = SiteId FROM DBO.[Site] WHERE UPPER([Name]) = UPPER('MIG') AND MasterCompanyId = @FromMasterComanyID;

				IF NOT EXISTS (SELECT * FROM DBO.Stockline stock WHERE StockLineNumber = (SELECT CAST(StocklineNumber AS VARCHAR(100)) FROM #TempStockline STL WHERE STL.ID = @LoopID) AND stock.ControlNumber = (SELECT CAST(STL.Ctrl_Number AS VARCHAR(100)) FROM #TempStockline STL WHERE STL.ID = @LoopID) AND stock.IdNumber = (SELECT CAST(STL.Ctrl_ID AS VARCHAR(100)) FROM #TempStockline STL WHERE STL.ID = @LoopID) AND MasterCompanyId = @FromMasterComanyID)
				BEGIN
					PRINT @CurrentStocklineId;
					PRINT @ConditionId;

					DECLARE @SiteId BIGINT = NULL;

					SELECT TOP 1 @SiteId = SiteId FROM DBO.ItemMaster WHERE ItemMasterId = @ItemMasterId;

					INSERT INTO DBO.Stockline
					([PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId],[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],
					[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber],
					[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],
					[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],
					[Memo],[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],
					[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],
					[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],
					[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId],[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],
					[QtyReserved],[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive],[isDeleted],[WorkOrderExtendedCost],
					[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId],[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],
					[TagNumber],[InspectionBy],[InspectionDate],[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId],
					[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition],[GlAccountName],[Site],[Warehouse],[Location],[Shelf],
					[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber],[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],[CustomerId],[CustomerName],[isCustomerstockType],
					[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],
					[CertTypeId],[CertType],[TagTypeId],[IsFinishGood],[IsTurnIn],[IsCustomerRMA],[RMADeatilsId],[DaysReceived],[ManufacturingDays],[TagDays],[OpenDays],[ExchangeSalesOrderId],[RRQty],[SubWorkOrderNumber],[IsManualEntry])

					SELECT ST.PartNumber, ST.StocklineNumber, NULL, CAST(ST.CTRL_NUMBER AS VARCHAR(50)), @ItemMasterId, ST.QTY_OH, @ConditionId, ST.SerialNumber, ISNULL(ST.ShelfLife, 0), CASE WHEN ST.ExpirationDate IS NOT NULL THEN CAST(ST.ExpirationDate AS Datetime2) ELSE NULL END, @WarehouseId,
					@LocationId, NULL, NULL, NULL, ISNULL(@ManufacturerId, (SELECT TOP 1 ManufacturerId FROM DBO.ItemMaster WHERE ItemMasterId = @ItemMasterId)), (SELECT TOP 1 UPPER([Name]) FROM dbo.Manufacturer WHERE ManufacturerId = @ItemManufacturerId), ST.MfgLotNum, CASE WHEN ST.MfgDate IS NOT NULL THEN CAST(ST.MfgDate AS Datetime2) ELSE NULL END, NULL, ST.PartCertNumber,
					NULL, NULL, CASE WHEN ST.TagDate IS NOT NULL THEN CAST(ST.TagDate AS datetime2) ELSE NULL END, NULL, NULL, ST.CalibRemarks, CASE WHEN ST.OrderRecDate IS NOT NULL THEN CAST(ST.OrderRecDate AS datetime2) ELSE NULL END, NULL, CAST(ISNULL(ST.OriginalCost, 0) AS decimal), 0, NULL,
					CAST(ST.RepairOrderUnitCost AS decimal), CASE WHEN ST.OrderRecDate IS NOT NULL THEN CAST(ST.OrderRecDate AS datetime2) ELSE NULL END, ST.ReceiverNumber, NULL, CAST(ISNULL(ST.UnitPrice, 0) AS decimal), CAST(ISNULL(ST.CoreCost, 0) AS decimal), (SELECT TOP 1 GLAccountId FROM DBO.ItemMaster WHERE ItemMasterId = @ItemMasterId), NULL, ISNULL(ST.HazardMaterial, 0), ISNULL((SELECT TOP 1 IsPma FROM DBO.ItemMaster WHERE ItemMasterId = @ItemMasterId), 0), ISNULL((SELECT TOP 1 IsDER FROM DBO.ItemMaster WHERE ItemMasterId = @ItemMasterId), 0), ISNULL((SELECT TOP 1 IsOEM FROM DBO.ItemMaster WHERE ItemMasterId = @ItemMasterId), 0),
					ST.NOTES, @EntityStructureId, (SELECT LegalEntityId FROM dbo.LegalEntity WHERE UPPER([Name]) = UPPER('MTI Aviation Inc.') AND MasterCompanyId = @FromMasterComanyID), @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), CASE WHEN ST.SerialNumber IS NOT NULL THEN 1 ELSE 0 END, NULL, NULL, ISNULL(@SiteId, @DefaultSiteId), NULL,
					@OwnerType, NULL, NULL, NULL, CAST(ST.CTRL_ID AS VARCHAR(50)), ST.Qty_Received, (ISNULL(ST.OriginalCost, 0) * ISNULL(ST.QTY_OH, 0)), NULL,
					CASE WHEN ST.ExpirationDate IS NOT NULL THEN CAST(ST.ExpirationDate AS datetime2) ELSE NULL END, ST.TailNumber, NULL, NULL, 0, NULL, NULL, NULL, NULL,
					0, NULL, NULL, ISNULL(ST.QTY_RESERVED, 0), NULL, CASE WHEN ST.Qty_Adjusted < 0 THEN ABS(ST.Qty_Adjusted) ELSE 0 END, ISNULL(ST.QTY_OH, 0), ISNULL(ST.QTY_AVAILABLE, 0), ISNULL(ST.Qty_Received, 0),
					ISNULL(ST.QTY_RESERVED, 0), ISNULL(ST.Qty_Received, 0), 0, NULL, ST.IsIncident, ST.IncidentReason, 0, NULL, NULL, 1, 0, 0,
					0, ST.IsCustomerOwned, CASE WHEN ST.RecDate IS NOT NULL THEN CAST(ST.RecDate AS datetime2) ELSE NULL END, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
					ST.TagNumber, NULL, NULL, NULL, 1, 0, 0, 0, NULL, NULL, NULL, 
					@PurchaseUnitOfMeasureId, NULL, ST.[OWNER], NULL, NULL, NULL, NULL, NULL, @ConditionName, (SELECT TOP 1 GLAccount FROM DBO.ItemMaster WHERE ItemMasterId = @ItemMasterId), (SELECT TOP 1 SiteName FROM DBO.ItemMaster WHERE ItemMasterId = @ItemMasterId), NULL, NULL, NULL,
					NULL, (SELECT TOP 1 UPPER(IM.ShortName) FROM DBO.UnitOfMeasure IM WHERE UnitOfMeasureId = @PurchaseUnitOfMeasureId), NULL, (SELECT TOP 1 IM.ItemGroupCode FROM DBO.ItemGroup IM WHERE ItemGroupId = @ItemGroupId), NULL, NULL, NULL, NULL, NULL, ST.IsCustomerOwned, (SELECT TOP 1 [Name] FROM DBO.Customer WHERE CustomerId = @CustomerId), 0,
					(SELECT TOP 1 IM.PartDescription FROM DBO.ItemMaster IM WHERE ItemMasterId = @ItemMasterId), NULL, NULL, NULL, CASE WHEN ST.TaggedBy IS NOT NULL THEN (SELECT TOP 1 CustomerId FROM DBO.Customer WHERE [Name] = UPPER(ST.TaggedBy)) END, UPPER(ST.TaggedBy), CASE WHEN ST.UnitCost IS NOT NULL THEN CAST(ST.UnitCost AS decimal) ELSE NULL END, 1, 'CUSTOMER', NULL, NULL, NULL,
					NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, NULL, 0, NULL, ST.IsManuallyAdded
					FROM #TempStockline AS ST WHERE ID = @LoopID;

					SET @InsertedStocklineId = SCOPE_IDENTITY();

					DECLARE @StocklineModuleId BIGINT;

					SELECT @StocklineModuleId = ManagementStructureModuleId FROM dbo.[ManagementStructureModule] WHERE ModuleName = 'Stockline';

					INSERT INTO dbo.[StocklineManagementStructureDetails]
					([ModuleID],[ReferenceID],[EntityMSID],[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],[Level6Id],
					[Level6Name],[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],
					[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels])
					SELECT @StocklineModuleId, @InsertedStockLineId, @EntityStructureId, 
					(SELECT Level1Id FROM dbo.[EntityStructureSetup] WHERE EntityStructureId = @EntityStructureId), 
					(SELECT (ISNULL(Code, '') + ' - ' + ISNULL(Description, '')) FROM dbo.[ManagementStructureLevel] WHERE ID = (SELECT Level1Id FROM dbo.[EntityStructureSetup] WHERE EntityStructureId = @EntityStructureId)), 
					(SELECT Level2Id FROM dbo.[EntityStructureSetup] WHERE EntityStructureId = @EntityStructureId), 
					(SELECT (ISNULL(Code, '') + ' - ' + ISNULL(Description, '')) FROM dbo.[ManagementStructureLevel] WHERE ID = (SELECT Level2Id FROM dbo.[EntityStructureSetup] WHERE EntityStructureId = @EntityStructureId)), 
					(SELECT Level3Id FROM dbo.[EntityStructureSetup] WHERE EntityStructureId = @EntityStructureId), 
					(SELECT (ISNULL(Code, '') + ' - ' + ISNULL(Description, '')) FROM dbo.[ManagementStructureLevel] WHERE ID = (SELECT Level3Id FROM dbo.[EntityStructureSetup] WHERE EntityStructureId = @EntityStructureId)), 
					NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1, 0, '', 
					'<p> LE :   ' + (SELECT (ISNULL(Code, '') + ' - ' + ISNULL(Description, '')) FROM dbo.[ManagementStructureLevel] WHERE ID = (SELECT Level1Id FROM dbo.[EntityStructureSetup] WHERE EntityStructureId = @EntityStructureId)) + 
					'</p><p> Division :   ' + (SELECT (ISNULL(Code, '') + ' - ' + ISNULL(Description, '')) FROM dbo.[ManagementStructureLevel] WHERE ID = (SELECT Level2Id FROM dbo.[EntityStructureSetup] WHERE EntityStructureId = @EntityStructureId)) + '</p>' +
					'</p><p> Department :   ' + (SELECT (ISNULL(Code, '') + ' - ' + ISNULL(Description, '')) FROM dbo.[ManagementStructureLevel] WHERE ID = (SELECT Level3Id FROM dbo.[EntityStructureSetup] WHERE EntityStructureId = @EntityStructureId)) + '</p>'

					UPDATE Stk
					SET Stk.Migrated_Id = @InsertedStocklineId,
					Stk.SuccessMsg = 'Record migrated successfully'
					FROM [Quantum_Staging].DBO.Stocklines Stk WHERE Stk.StocklineId = @CurrentStocklineId;

					SET @MigratedRecords = @MigratedRecords + 1;
				END
				ELSE
				BEGIN
					UPDATE Stk
					SET Stk.ErrorMsg = ISNULL(ErrorMsg, '') + '<p>Stockline record already exists</p>'
					FROM [Quantum_Staging].DBO.Stocklines Stk WHERE Stk.StocklineId = @CurrentStocklineId;

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

	SELECT @Processed AS Processed, @Migrated AS Migrated, @Failed AS Failed, @Exists AS 'Exists';
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
	  ,@AdhocComments varchar(150) = 'MigrateStocklineRecords'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END