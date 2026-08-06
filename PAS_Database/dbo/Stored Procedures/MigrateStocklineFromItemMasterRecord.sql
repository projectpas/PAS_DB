/*************************************************************             
 ** File:   [MigrateStocklineFromItemMasterRecord]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate Item Master Records
 ** Purpose:           
 ** Date:   21/02/2025

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    21/02/2025   Vishal Suthar		Created
	2    16/06/2026   Priyansh Patel 	Removed the ChildStockline Sp call [PN-16124]
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigrateStocklineFromItemMasterRecord @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=20,@UserName=N'ADMIN ADMIN',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigrateStocklineFromItemMasterRecord]
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
		DECLARE @StockLineNumber VARCHAR(50);  

		IF OBJECT_ID(N'tempdb..#TempItemMaster') IS NOT NULL
		BEGIN
			DROP TABLE #TempItemMaster
		END

		CREATE TABLE #TempItemMaster
		(
			ID bigint NOT NULL IDENTITY,
			[ItemMasterId] [bigint] NOT NULL,
			[CurrencyId] [bigint] NULL,
			[ItemGroupId] [bigint] NULL,
			[ItemClassificationId] [bigint] NULL,
			[ManufacturerId] [bigint] NULL,
			[UnitOfMeasureId] [bigint] NULL,
			[PartNumber] [varchar](100) NULL,
			[PartDescription] [varchar](max) NULL,
			[Hazard_Material] [varchar](10) NULL,
			[DER_Flag] [varchar](10) NULL,
			[Reorder_Cond_Level] decimal(18, 2) NULL,
			[MinimumOrderQuantity] [int] NULL,
			[PartListPrice] decimal(18, 2) NULL,
			[NotesAdded] [varchar](5000) NULL,
			[IsActive] [varchar](10) NULL,
			[Date_Created] datetime2(7) NULL,
			[IsTimeLife] [varchar](10) NULL,
			[IsSerialized] [varchar](10) NULL,
			[Shelf_Life] [varchar](10) NULL,
			[List_Price_Date] datetime2(7) NULL,
			[ECC_Number] [varchar](100) NULL,
			[ITAR_Number] [varchar](100) NULL,
			[Shelf_Life_Days] [int] NULL,
			[PMA_Flag] [varchar](10) NULL,
			[Procurement] [varchar](100) NULL,
			[IsHOTPart] [varchar](10) NULL,
			[LeadDays] [int] NULL,
			[SalesPrice] DECIMAL(18,2) NULL,
			[Alert] varchar(max) NULL,
			[UOM] varchar(50) NULL,
			VendorId BIGINT NULL,
			Condition varchar(50) NULL,
			PartType varchar(50) NULL,
			StockLevel INT NULL,
			ReOrderPoint INT NULL,
			QtyOH INT NULL,
			QtyReserved INT NULL,
			[Migrated_Id] BIGINT NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL
		)

		INSERT INTO #TempItemMaster ([ItemMasterId],[CurrencyId],[ItemGroupId],[ItemClassificationId],[ManufacturerId],[UnitOfMeasureId],[PartNumber],[PartDescription],
		[Hazard_Material],[DER_Flag],[Reorder_Cond_Level],[MinimumOrderQuantity],[PartListPrice],[NotesAdded],[IsActive],[Date_Created],[IsTimeLife],[IsSerialized],
		[Shelf_Life],[List_Price_Date],[ECC_Number],[ITAR_Number],[Shelf_Life_Days],[PMA_Flag],[Procurement],[IsHOTPart],[LeadDays],[SalesPrice],[Alert],[UOM],[Migrated_Id],[SuccessMsg],[ErrorMsg],
		[VendorId],[Condition],[PartType],[StockLevel],[ReOrderPoint],[QtyOH],[QtyReserved])
		SELECT [ItemMasterId],[CurrencyId],[ItemGroupId],[ItemClassificationId],[ManufacturerId],[UnitOfMeasureId],[PartNumber],[PartDescription],
		[Hazard_Material],[DER_Flag],[Reorder_Cond_Level],[MinimumOrderQuantity],[PartListPrice],[NotesAdded],[IsActive],[Date_Created],[IsTimeLife],[IsSerialized],
		[Shelf_Life],[List_Price_Date],[ECC_Number],[ITAR_Number],[Shelf_Life_Days],[PMA_Flag],[Procurement],[IsHOTPart],[LeadDays],[SalesPrice],[Alert],[UOM],[Migrated_Id],[SuccessMsg],[ErrorMsg],
		[VendorId],[Condition],[PartType],[StockLevel],[ReOrderPoint],[QtyOH],[QtyReserved]
		FROM [Quantum_Staging].dbo.ItemMasters IM WITH (NOLOCK) WHERE IM.MasterCompanyId = @FromMasterComanyID AND IM.Migrated_Id IS NOT NULL;

		IF OBJECT_ID(N'tempdb..#tmpCodePrefix') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCodePrefix
		END
      
		CREATE TABLE #tmpCodePrefix  
		(
			ID BIGINT NOT NULL IDENTITY,   
			CodePrefixId BIGINT NULL,  
			CodeTypeId BIGINT NULL,  
			CurrentNumber BIGINT NULL,  
			CodePrefix VARCHAR(50) NULL,  
			CodeSufix VARCHAR(50) NULL,  
			StartsFrom BIGINT NULL,  
		)

		CREATE TABLE #tmpPNManufacturer  
		(  
			ID BIGINT NOT NULL IDENTITY,   
			ItemMasterId BIGINT NULL,  
			ManufacturerId BIGINT NULL,  
			StockLineNumber VARCHAR(100) NULL,  
			CurrentStlNo BIGINT NULL,  
			isSerialized BIT NULL  
		)

		;WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId) AS  
		(  
			SELECT ac.ItemMasterId, ac.ManufacturerId, MAX(ac.StockLineId) StockLineId  
			FROM (SELECT DISTINCT ItemMasterId FROM DBO.Stockline WITH (NOLOCK)) ac1 CROSS JOIN  
			(SELECT DISTINCT ManufacturerId FROM DBO.Stockline WITH (NOLOCK)) ac2 LEFT JOIN  
			DBO.Stockline ac WITH (NOLOCK)  
			ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId  
			WHERE ac.MasterCompanyId = @FromMasterComanyID  
			GROUP BY ac.ItemMasterId, ac.ManufacturerId  
			HAVING COUNT(ac.ItemMasterId) > 0  
		)
  
		INSERT INTO #tmpPNManufacturer (ItemMasterId, ManufacturerId, StockLineNumber, CurrentStlNo, isSerialized)  
		SELECT CSTL.ItemMasterId, CSTL.ManufacturerId, StockLineNumber, ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo, IM.isSerialized  
		FROM CTE_Stockline CSTL INNER JOIN DBO.Stockline STL WITH (NOLOCK)   
		INNER JOIN DBO.ItemMaster IM ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId  
		ON CSTL.StockLineId = STL.StockLineId

		 WHERE ISNULL(IM.IsNonStock,0) = 0
		INSERT INTO #tmpCodePrefix (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)   
		SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
		FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId  
		WHERE CT.CodeTypeId IN (30,17,9) AND CP.MasterCompanyId = @FromMasterComanyID AND CP.IsActive = 1 AND CP.IsDeleted = 0;

		SELECT * FROM #tmpCodePrefix;

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempItemMaster;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;

			DECLARE @InsertedStocklineId BIGINT = 0;

			DECLARE @FoundError BIT = 0;

			IF (@FoundError = 0)
			BEGIN
				DECLARE @MigratedId BIGINT = 0;
				DECLARE @ManufacturerId BIGINT = 0;
				DECLARE @CNCurrentNumber BIGINT;
				DECLARE @ControlNumber VARCHAR(50);
				DECLARE @OnHandQty INT = 0;
				DECLARE @ConditionId BIGINT = 0;
				DECLARE @GLAccountId BIGINT = 0;
				DECLARE @ManagementStructureId BIGINT = 0;
				DECLARE @LegalEntityId BIGINT = 0;
				DECLARE @SiteId BIGINT = 0;
				DECLARE @UnitCost DECIMAL(18,2) = 0;
				DECLARE @SalePrice DECIMAL(18,2) = 0;
				DECLARE @LastOrderedDate DATETIME2(7);
				DECLARE @QtyReserved INT;
				DECLARE @QtyIssued INT;
				DECLARE @QtyOnOrder INT;
				DECLARE @VendorId BIGINT;
				DECLARE @CustomerId BIGINT;
				DECLARE @Condition VARCHAR(50);
				DECLARE @EntityStructureId BIGINT;

				SELECT @MigratedId = Migrated_Id, @ManufacturerId = ManufacturerId, @OnHandQty = QtyOH, @ConditionId = 298, @UnitCost = 0, @SalePrice = SalesPrice, @LastOrderedDate = GETDATE(),
				@GLAccountId = 2395, @ManagementStructureId = 38, @LegalEntityId = 33, @SiteId = 25, @QtyReserved = 0, @QtyIssued = 0, @QtyOnOrder = 0, @VendorId = NULL, @Condition = Condition,
				@CustomerId = NULL, @EntityStructureId = 38
				FROM #TempItemMaster WHERE ID = @LoopID;

				IF NOT EXISTS (SELECT * FROM DBO.Stockline stock WHERE stock.ItemMasterId = @MigratedId AND stock.MasterCompanyId = @FromMasterComanyID)
				BEGIN
					DECLARE @currentNo AS BIGINT = 0;
					DECLARE @stockLineCurrentNo AS BIGINT;

					SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE ItemMasterId = @MigratedId AND ManufacturerId = @ManufacturerId  
  
					IF (@currentNo <> 0)  
					BEGIN
						SET @stockLineCurrentNo = @currentNo + 1  
					END
					ELSE
					BEGIN
						SET @stockLineCurrentNo = 1
					END

					IF (EXISTS (SELECT 1 FROM #tmpCodePrefix WHERE CodeTypeId = 30))  
					BEGIN   
						SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@stockLineCurrentNo,(SELECT CodePrefix FROM #tmpCodePrefix WHERE CodeTypeId = 30), (SELECT CodeSufix FROM #tmpCodePrefix WHERE CodeTypeId = 30)))  
  
						UPDATE DBO.ItemMaster  
						SET CurrentStlNo = @stockLineCurrentNo  
						WHERE ItemMasterId = @MigratedId;
					END 
					--ELSE   
					--BEGIN  
					--	ROLLBACK TRAN;  
					--END

					IF EXISTS (SELECT 1 FROM #tmpCodePrefix WHERE CodeTypeId = 9)
					BEGIN   
						SELECT @CNCurrentNumber = CASE WHEN CurrentNumber > 0 THEN (CAST(CurrentNumber AS BIGINT) + 1) ELSE (CAST(StartsFrom AS BIGINT) + 1) END FROM #tmpCodePrefix WHERE CodeTypeId = 9;
  
						SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CNCurrentNumber,(SELECT CodePrefix FROM #tmpCodePrefix WHERE CodeTypeId = 9), (SELECT CodeSufix FROM #tmpCodePrefix WHERE CodeTypeId = 9)))  
					END 
					ELSE   
					BEGIN  
						ROLLBACK TRAN;  
					END

					SET @ConditionId = NULL;
					SELECT @ConditionId = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE Code = @Condition;

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

					SELECT [PartNumber],@StockLineNumber,NULL,@ControlNumber,Migrated_Id,@OnHandQty,ISNULL(@ConditionId, 298),'',0,NULL,NULL,
					NULL,NULL,NULL,NULL,@ManufacturerId,NULL,NULL,NULL,NULL,NULL,
					NULL,NULL,NULL,'',NULL,NULL,NULL,NULL,@UnitCost,NULL,NULL,
					0,@LastOrderedDate,'RecNo-000001',NULL,@SalePrice,NULL,@GLAccountId,NULL,0,0,0,1,
					(ST.NotesAdded + ' ' + ST.Alert),@ManagementStructureId,@LegalEntityId,@FromMasterComanyID,'ADMIN ADMIN','ADMIN ADMIN',GETUTCDATE(),GETUTCDATE(),0,NULL,NULL,@SiteId,NULL,
					NULL,NULL,NULL,NULL,'ID_NUM-000001',0,@UnitCost,'',
					NULL,NULL,NULL,'',0,NULL,'',NULL,NULL,
					1,NULL,NULL,@QtyReserved,0,@QtyIssued,@OnHandQty,@OnHandQty,@QtyOnOrder,
					0,0,0,NULL,0,NULL,0,NULL,NULL,1,0,0,
					0,0,Date_Created,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
					NULL,NULL,NULL,@VendorId,1,0,1,0,NULL,0,NULL,
					UnitOfMeasureId,'','','',NULL,NULL,NULL,NULL,@Condition,NULL,NULL,NULL,NULL,NULL,
					NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@CustomerId,NULL,0,
					PartDescription,NULL,'','',0,'',@UnitCost,0,'',0,0,'',
					'','',NULL,0,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,'',1
					FROM #TempItemMaster AS ST WHERE ID = @LoopID;

					SET @InsertedStocklineId = SCOPE_IDENTITY();

					UPDATE CodePrefixes SET CurrentNummber = @stockLineCurrentNo WHERE CodeTypeId = 30 AND MasterCompanyId = @FromMasterComanyID;

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

					DECLARE @QtyCreated INT = 0;

					SELECT @QtyCreated = @OnHandQty;

					--EXEC DBO.USP_AddUpdateChildStockline @StocklineId = @InsertedStocklineId, @ActionId = 1, @QtyOnAction = @QtyCreated, @ModuleName = 'Migration', @ReferenceNumber = NULL, @SubModuleName = NULL, @SubReferenceNumber = NULL, @UpdatedBy = @UserName;

					INSERT INTO [dbo].[Stkline_History] ([StocklineId],[ModuleId],[RefferenceId],[RefferenceNumber],[SubModuleId],[SubRefferenceId],[SubRefferenceNumber],[ActionId],[Type],
						[QtyOH],[QtyAvailable],[QtyReserved],[QtyIssued],[QtyOnAction],[Notes],[UpdatedBy],[UpdatedDate],UnitSalesPrice,SalesPriceExpiryDate)
					SELECT STL.StockLineId, 22, STL.StockLineId, STL.StockLineNumber, NULL, NULL, NULL, 1, 'Create', 
						STL.QuantityOnHand, STL.QuantityAvailable, STL.QuantityReserved, STL.QuantityIssued, STL.QuantityAvailable, STL.StockLineNumber + ' has been added through Migration', @UserName, GETUTCDATE(),UnitSalesPrice,SalesPriceExpiryDate
					FROM DBO.[Stockline] STL WITH (NOLOCK) WHERE StockLineId = @InsertedStocklineId;

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
	  ,@AdhocComments varchar(150) = 'MigrateItemMasterRecords'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END