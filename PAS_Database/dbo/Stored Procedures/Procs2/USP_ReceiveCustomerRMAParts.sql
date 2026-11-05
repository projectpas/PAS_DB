/*************************************************************
 ** File:   [USP_ReceiveCustomerRMAParts]
 ** Author:   Rajesh Gami
 ** Description: Receiving Customer RMA - Create Stockline (app-receiving-customer-rma).
 **              One row of @tbl_ReceiveParts = one new stockline:
 **                - copied from the original (sold) stockline of the RMA part, then the values entered on the
 **                  screen are applied (qty, condition, site / warehouse / location / shelf / bin, GL, serial,
 **                  unit cost, mfr lot / batch / dates, cert, tag, memo)
 **                - stock type (IsCustomerStock / customer) same as the original stockline, Obtain From = RMA customer, IsCustomerRMA = 1, RMADeatilsId link
 **                - new Stockline / Control / ID numbers, one Receiver Number per call (RecNo + sequence per RMA)
 **                - TimeLife, documents, MS details, stockline history and LOT trans-in as in CreateStocklineForCustomerRMADeatils
 **              CustomerRMADeatils.QtyReceived += qty; RMA -> Closed (5) when every part is fully received.
 **              Partial receipts allowed. Serialized part: 1 per row.
 ** Purpose:
 ** Date:   04-Nov-2026

 ** RETURN: RS1 = IsSuccess, Message, RMAStatusId, RMAStatus, ReceiverNumber
 **         RS2 = created stocklines (StockLineId, StockLineNumber, RMADeatilsId, Quantity)

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    04-Nov-2026  RAJESH GAMI		[PN-18254] Created
    2    05-Nov-2026  RAJESH GAMI		[PN-18254] GlAccountName from the GL Account chosen on the screen (UpdateStocklineColumnsWithId does not set it)
    3    05-Nov-2026  RAJESH GAMI		[PN-18254] Customer / company stock copied from the original stockline (IsCustomerStock, CustomerId, CustomerName, isCustomerstockType)
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_ReceiveCustomerRMAParts]
	@tbl_ReceiveParts [dbo].[CustomerRMAReceivePartsType] READONLY,
	@RMAHeaderId BIGINT,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @FulfilledStatusId BIGINT = 2, @ClosedStatusId BIGINT = 5, @ClosedStatus VARCHAR(100) = 'Closed';
	DECLARE @ValidationMessage NVARCHAR(MAX) = '';

	SELECT @FulfilledStatusId = ISNULL((SELECT TOP 1 [RMAStatusId] FROM [dbo].[RMAStatus] WITH (NOLOCK) WHERE UPPER([Description]) = 'FULFILLED'), 2);
	SELECT @ClosedStatusId = ISNULL((SELECT TOP 1 [RMAStatusId] FROM [dbo].[RMAStatus] WITH (NOLOCK) WHERE UPPER([Description]) = 'CLOSED'), 5);

	/*------------------------------------------------------------------
	  Validation (no change is made when something is wrong)
	------------------------------------------------------------------*/
	IF NOT EXISTS (SELECT 1 FROM [dbo].[CustomerRMAHeader] WITH (NOLOCK) WHERE [RMAHeaderId] = @RMAHeaderId AND ISNULL([IsDeleted], 0) = 0)
		SET @ValidationMessage = 'RMA not found.';
	ELSE IF NOT EXISTS (SELECT 1 FROM [dbo].[CustomerRMAHeader] WITH (NOLOCK) WHERE [RMAHeaderId] = @RMAHeaderId AND [RMAStatusId] = @FulfilledStatusId)
		SET @ValidationMessage = 'Only a Fulfilled RMA can be received.';
	ELSE IF NOT EXISTS (SELECT 1 FROM @tbl_ReceiveParts)
		SET @ValidationMessage = 'Please select at least one part to receive.';

	IF @ValidationMessage = ''
	BEGIN
		;WITH RequestedQtyByPart AS (
			SELECT ReceivePart.[RMADeatilsId], SUM(ReceivePart.[QtyToReceive]) AS [RequestedQty]
			FROM @tbl_ReceiveParts ReceivePart
			GROUP BY ReceivePart.[RMADeatilsId]
		)
		SELECT @ValidationMessage = @ValidationMessage +
			ISNULL(RMADetail.[PartNumber], 'Part ' + CAST(ReceivePart.[RMADeatilsId] AS VARCHAR(20))) + ': ' +
			CASE
				WHEN RMADetail.[RMADeatilsId] IS NULL THEN 'part does not belong to this RMA.'
				WHEN ISNULL(ReceivePart.[QtyToReceive], 0) <= 0 THEN 'Qty to Receive must be greater than 0.'
				WHEN RequestedQtyByPart.[RequestedQty] > ISNULL(RMADetail.[Qty], 0) - ISNULL(RMADetail.[QtyReceived], 0) THEN 'Qty to Receive is more than Qty Pending.'
				WHEN ISNULL(PartItemMaster.[isSerialized], 0) = 1 AND ReceivePart.[QtyToReceive] <> 1 THEN 'serialized part - receive 1 at a time.'
				WHEN ISNULL(PartItemMaster.[isSerialized], 0) = 1 AND LTRIM(RTRIM(ISNULL(ReceivePart.[SerialNumber], ''))) = '' THEN 'Serial Num is required.'
				WHEN ISNULL(ReceivePart.[ConditionId], 0) = 0 THEN 'Cond is required.'
				WHEN ISNULL(ReceivePart.[SiteId], 0) = 0 THEN 'Site is required.'
				WHEN ISNULL(ReceivePart.[GLAccountId], 0) = 0 THEN 'GL Account is required.'
				WHEN RMADetail.[StocklineId] IS NULL OR OriginalStockline.[StockLineId] IS NULL THEN 'original stockline not found.'
			END + '<br/>'
		FROM @tbl_ReceiveParts ReceivePart
			INNER JOIN RequestedQtyByPart ON RequestedQtyByPart.[RMADeatilsId] = ReceivePart.[RMADeatilsId]
			LEFT JOIN [dbo].[CustomerRMADeatils] RMADetail WITH (NOLOCK) ON RMADetail.[RMADeatilsId] = ReceivePart.[RMADeatilsId]
				AND RMADetail.[RMAHeaderId] = @RMAHeaderId AND ISNULL(RMADetail.[IsDeleted], 0) = 0
			LEFT JOIN [dbo].[ItemMaster] PartItemMaster WITH (NOLOCK) ON PartItemMaster.[ItemMasterId] = RMADetail.[ItemMasterId]
			LEFT JOIN [dbo].[Stockline] OriginalStockline WITH (NOLOCK) ON OriginalStockline.[StockLineId] = RMADetail.[StocklineId]
		WHERE RMADetail.[RMADeatilsId] IS NULL
		   OR ISNULL(ReceivePart.[QtyToReceive], 0) <= 0
		   OR RequestedQtyByPart.[RequestedQty] > ISNULL(RMADetail.[Qty], 0) - ISNULL(RMADetail.[QtyReceived], 0)
		   OR (ISNULL(PartItemMaster.[isSerialized], 0) = 1 AND (ReceivePart.[QtyToReceive] <> 1 OR LTRIM(RTRIM(ISNULL(ReceivePart.[SerialNumber], ''))) = ''))
		   OR ISNULL(ReceivePart.[ConditionId], 0) = 0
		   OR ISNULL(ReceivePart.[SiteId], 0) = 0
		   OR ISNULL(ReceivePart.[GLAccountId], 0) = 0
		   OR OriginalStockline.[StockLineId] IS NULL;
	END

	IF @ValidationMessage <> ''
	BEGIN
		SELECT CAST(0 AS BIT) AS [IsSuccess], @ValidationMessage AS [Message], NULL AS [RMAStatusId], NULL AS [RMAStatus], NULL AS [ReceiverNumber];
		SELECT CAST(NULL AS BIGINT) AS [StockLineId], CAST(NULL AS VARCHAR(50)) AS [StockLineNumber], CAST(NULL AS BIGINT) AS [RMADeatilsId], CAST(NULL AS DECIMAL(18,6)) AS [Quantity] WHERE 1 = 0;
		RETURN;
	END

	BEGIN TRY
		BEGIN TRANSACTION

		DECLARE @RMANumber VARCHAR(100), @CustomerId BIGINT, @CustomerName VARCHAR(200), @HeaderMSId BIGINT;
		DECLARE @CustomerRMAModuleId BIGINT, @CreateFromCustomerRMAActionId INT, @StocklineAttachmentModuleId INT,
				@StocklineMSModuleId INT, @CustomerObtainFromType INT;
		DECLARE @ReceiverNumber VARCHAR(50), @ReceiverSequence BIGINT;
		DECLARE @ReceivedDate DATETIME2(7) = GETUTCDATE();

		SELECT @RMANumber = RMAHeader.[RMANumber], @CustomerId = RMAHeader.[CustomerId], @CustomerName = RMAHeader.[CustomerName],
			   @HeaderMSId = RMAHeader.[ManagementStructureId]
		FROM [dbo].[CustomerRMAHeader] RMAHeader WITH (UPDLOCK, HOLDLOCK)
		WHERE RMAHeader.[RMAHeaderId] = @RMAHeaderId;

		SELECT @CustomerRMAModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'CustomerRMA';
		SELECT @CustomerObtainFromType = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Customer';
		SELECT @CreateFromCustomerRMAActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH (NOLOCK) WHERE [Type] = 'Create-Customer-RMA';
		SELECT @StocklineAttachmentModuleId = [AttachmentModuleId] FROM [dbo].[AttachmentModule] WITH (NOLOCK) WHERE [Name] = 'StockLine';
		SELECT @StocklineMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH (NOLOCK) WHERE [ModuleName] = 'Stockline';

		/* one Receiver Number per receipt (per call): RecNo + sequence within this RMA */
		SELECT @ReceiverSequence = COUNT(DISTINCT RMAStockline.[ReceiverNumber]) + 1
		FROM [dbo].[Stockline] RMAStockline WITH (NOLOCK)
			INNER JOIN [dbo].[CustomerRMADeatils] RMADetail WITH (NOLOCK) ON RMADetail.[RMADeatilsId] = RMAStockline.[RMADeatilsId]
		WHERE RMADetail.[RMAHeaderId] = @RMAHeaderId AND ISNULL(RMAStockline.[ReceiverNumber], '') <> '';
		SET @ReceiverNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@ReceiverSequence, 'RecNo', ''));

		IF OBJECT_ID(N'tempdb..#ReceiveRows') IS NOT NULL DROP TABLE #ReceiveRows;
		CREATE TABLE #ReceiveRows (
			[RowId] INT IDENTITY(1,1) NOT NULL,
			[RMADeatilsId] BIGINT, [QtyToReceive] DECIMAL(18,6), [ConditionId] BIGINT, [SiteId] BIGINT, [WarehouseId] BIGINT,
			[LocationId] BIGINT, [ShelfId] BIGINT, [BinId] BIGINT, [GLAccountId] BIGINT, [SerialNumber] VARCHAR(30),
			[UnitCost] DECIMAL(18,6), [ManufacturerLotNumber] VARCHAR(50), [ManufacturingBatchNumber] VARCHAR(50),
			[ManufacturingDate] DATETIME2(7), [ExpirationDate] DATETIME2(7), [PartCertificationNumber] VARCHAR(50),
			[CertifiedDate] DATETIME2(7), [CertTypeId] VARCHAR(100), [TagDate] DATETIME2(7), [TagTypeId] BIGINT, [Memo] NVARCHAR(MAX)
		);
		INSERT INTO #ReceiveRows ([RMADeatilsId],[QtyToReceive],[ConditionId],[SiteId],[WarehouseId],[LocationId],[ShelfId],[BinId],[GLAccountId],
			[SerialNumber],[UnitCost],[ManufacturerLotNumber],[ManufacturingBatchNumber],[ManufacturingDate],[ExpirationDate],
			[PartCertificationNumber],[CertifiedDate],[CertTypeId],[TagDate],[TagTypeId],[Memo])
		SELECT [RMADeatilsId],[QtyToReceive],[ConditionId],[SiteId],NULLIF([WarehouseId],0),NULLIF([LocationId],0),NULLIF([ShelfId],0),NULLIF([BinId],0),[GLAccountId],
			NULLIF(LTRIM(RTRIM([SerialNumber])),''),ISNULL([UnitCost],0),[ManufacturerLotNumber],[ManufacturingBatchNumber],[ManufacturingDate],[ExpirationDate],
			[PartCertificationNumber],[CertifiedDate],NULLIF([CertTypeId],'0'),[TagDate],NULLIF([TagTypeId],0),[Memo]
		FROM @tbl_ReceiveParts;

		IF OBJECT_ID(N'tempdb..#CreatedStocklines') IS NOT NULL DROP TABLE #CreatedStocklines;
		CREATE TABLE #CreatedStocklines ([StockLineId] BIGINT, [StockLineNumber] VARCHAR(50), [RMADeatilsId] BIGINT, [Quantity] DECIMAL(18,6));

		DECLARE @RowId INT = 1, @RowCount INT = (SELECT COUNT(1) FROM #ReceiveRows);

		WHILE (@RowId <= @RowCount)
		BEGIN
			DECLARE @RMADeatilsId BIGINT, @QtyToReceive DECIMAL(18,6), @OriginalStocklineId BIGINT, @NewStocklineId BIGINT,
					@ItemMasterId BIGINT, @ManufacturerId BIGINT, @StockLineNumber VARCHAR(50), @ControlNumber VARCHAR(50), @IDNumber VARCHAR(100),
					@StockLineCurrentNo BIGINT, @ControlCurrentNo BIGINT, @IDCurrentNo BIGINT, @SourceLotId BIGINT, @RowUnitCost DECIMAL(18,6),
					@RowMemo NVARCHAR(MAX), @CertTypeIdList VARCHAR(100), @CertTypeNames VARCHAR(MAX), @OriginalIsCustomerStock BIT;

			SELECT @RMADeatilsId = ReceiveRow.[RMADeatilsId], @QtyToReceive = ReceiveRow.[QtyToReceive], @RowUnitCost = ReceiveRow.[UnitCost],
				   @RowMemo = ReceiveRow.[Memo], @CertTypeIdList = ReceiveRow.[CertTypeId]
			FROM #ReceiveRows ReceiveRow WHERE ReceiveRow.[RowId] = @RowId;

			/* re-check pending qty under lock (two users receiving at the same time) */
			IF EXISTS (SELECT 1 FROM [dbo].[CustomerRMADeatils] RMADetail WITH (UPDLOCK, HOLDLOCK)
					   WHERE RMADetail.[RMADeatilsId] = @RMADeatilsId
						 AND @QtyToReceive > ISNULL(RMADetail.[Qty], 0) - ISNULL(RMADetail.[QtyReceived], 0))
			BEGIN
				RAISERROR ('Qty to Receive is more than Qty Pending (already received by another user).', 16, 1);
			END

			SELECT @OriginalStocklineId = RMADetail.[StocklineId] FROM [dbo].[CustomerRMADeatils] RMADetail WITH (NOLOCK) WHERE RMADetail.[RMADeatilsId] = @RMADeatilsId;
			SELECT @ItemMasterId = OriginalStockline.[ItemMasterId], @ManufacturerId = OriginalStockline.[ManufacturerId], @SourceLotId = ISNULL(OriginalStockline.[LotId], 0),
				   @OriginalIsCustomerStock = ISNULL(OriginalStockline.[IsCustomerStock], 0)
			FROM [dbo].[Stockline] OriginalStockline WITH (NOLOCK) WHERE OriginalStockline.[StockLineId] = @OriginalStocklineId;

			/* Stockline Number (per PN + Manufacturer, ItemMaster.CurrentStlNo, code type 30) */
			SELECT @StockLineCurrentNo = ISNULL(PartItemMaster.[CurrentStlNo], 0) + 1
			FROM [dbo].[ItemMaster] PartItemMaster WITH (UPDLOCK) WHERE PartItemMaster.[ItemMasterId] = @ItemMasterId;
			SET @StockLineNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@StockLineCurrentNo,
				(SELECT TOP 1 [CodePrefix] FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE [CodeTypeId] = 30 AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0),
				(SELECT TOP 1 [CodeSufix] FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE [CodeTypeId] = 30 AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0)));
			UPDATE [dbo].[ItemMaster] SET [CurrentStlNo] = @StockLineCurrentNo WHERE [ItemMasterId] = @ItemMasterId;

			/* Control Number (code type 9) */
			SELECT @ControlCurrentNo = CASE WHEN ISNULL([CurrentNummber], 0) > 0 THEN CAST([CurrentNummber] AS BIGINT) + 1 ELSE CAST(ISNULL([StartsFrom], 0) AS BIGINT) + 1 END
			FROM [dbo].[CodePrefixes] WITH (UPDLOCK) WHERE [CodeTypeId] = 9 AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
			SET @ControlNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@ControlCurrentNo,
				(SELECT TOP 1 [CodePrefix] FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE [CodeTypeId] = 9 AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0),
				(SELECT TOP 1 [CodeSufix] FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE [CodeTypeId] = 9 AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0)));
			UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @ControlCurrentNo WHERE [CodeTypeId] = 9 AND [MasterCompanyId] = @MasterCompanyId;

			/* ID Number (code type 17) */
			SELECT @IDCurrentNo = CASE WHEN ISNULL([CurrentNummber], 0) > 0 THEN CAST([CurrentNummber] AS BIGINT) + 1 ELSE CAST(ISNULL([StartsFrom], 0) AS BIGINT) + 1 END
			FROM [dbo].[CodePrefixes] WITH (UPDLOCK) WHERE [CodeTypeId] = 17 AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
			SET @IDNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@IDCurrentNo,
				(SELECT TOP 1 [CodePrefix] FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE [CodeTypeId] = 17 AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0),
				(SELECT TOP 1 [CodeSufix] FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE [CodeTypeId] = 17 AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0)));
			UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @IDCurrentNo WHERE [CodeTypeId] = 17 AND [MasterCompanyId] = @MasterCompanyId;

			/* 1. copy the original stockline (same column list as CreateStocklineForCustomerRMADeatils) */
			INSERT INTO [dbo].[Stockline]
			   ([PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId]
			   ,[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo]
			   ,[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber]
			   ,[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId]
			   ,[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber]
			   ,[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER]
			   ,[OEM],[Memo],[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
			   ,[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId]
			   ,[UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace]
			   ,[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId]
			   ,[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId]
			   ,[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved]
			   ,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId]
			   ,[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId]
			   ,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate]
			   ,[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId]
			   ,[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition]
			   ,[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber]
			   ,[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],[CustomerId],[CustomerName],[isCustomerstockType]
			   ,[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType]
			   ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId]
			   ,[LotId],[IsLotAssigned],[LotMainStocklineId],[LotSourceId],[TransferredFromLotId],[TransferredFromLotNumber]
			   ,[IsFinishGood],[IsCustomerRMA],[RMADeatilsId],[StockUnitOfMeasureId],[ConsumeUnitOfMeasureId])
			SELECT [PartNumber],@StockLineNumber,[StocklineMatchKey],@ControlNumber,[ItemMasterId],@QtyToReceive,[ConditionId]
			   ,[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo]
			   ,[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber]
			   ,[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],NULL
			   ,0,[InventoryUnitCost],NULL,0,@ReceivedDate,@ReceiverNumber
			   ,NULL,[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER]
			   ,[OEM],[Memo],@HeaderMSId,[LegalEntityId],[MasterCompanyId],@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE()
			   ,[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId]
			   ,[UnitSalePriceAdjustmentReasonTypeId],@IDNumber,0,0,[ManufacturingTrace]
			   ,[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],0,NULL
			   ,[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],NULL,NULL
			   ,0,0,0,@QtyToReceive,@QtyToReceive,0,0
			   ,0,[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],NULL
			   ,1,0,0,0,ISNULL([IsCustomerStock],0),@ReceivedDate,[LotCost],[NHAItemMasterId]
			   ,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate]
			   ,[VendorId],1,NULL,[IsSameDetailsForAllParts],0,NULL,0,[IsOemPNId]
			   ,[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition]
			   ,[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],NULL,[itemGroup],[TLAPartNumber]
			   ,[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],[CustomerId],[CustomerName],[isCustomerstockType]
			   ,[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],0,[TaggedByType]
			   ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId]
			   ,[LotId],[IsLotAssigned],[LotMainStocklineId],[LotSourceId],[TransferredFromLotId],[TransferredFromLotNumber]
			   ,0,1,@RMADeatilsId,[StockUnitOfMeasureId],[ConsumeUnitOfMeasureId]
			FROM [dbo].[Stockline] WITH (NOLOCK)
			WHERE [StockLineId] = @OriginalStocklineId;

			SELECT @NewStocklineId = SCOPE_IDENTITY();

			/* 2. values entered on the Receiving Customer RMA screen; Obtain From = RMA customer */
			SELECT @CertTypeNames = STRING_AGG(CertificationTypeMaster.[CertificationName], ',')
			FROM [dbo].[CertificationType] CertificationTypeMaster WITH (NOLOCK)
			WHERE @CertTypeIdList IS NOT NULL
			  AND CertificationTypeMaster.[CertificationTypeId] IN (SELECT TRY_CAST(LTRIM(RTRIM(CertTypeValue.[value])) AS BIGINT) FROM STRING_SPLIT(@CertTypeIdList, ',') CertTypeValue);

			UPDATE NewStockline
			SET NewStockline.[ConditionId]              = ReceiveRow.[ConditionId],
				NewStockline.[SiteId]                   = ReceiveRow.[SiteId],
				NewStockline.[WarehouseId]              = ReceiveRow.[WarehouseId],
				NewStockline.[LocationId]               = ReceiveRow.[LocationId],
				NewStockline.[ShelfId]                  = ReceiveRow.[ShelfId],
				NewStockline.[BinId]                    = ReceiveRow.[BinId],
				NewStockline.[GLAccountId]              = ReceiveRow.[GLAccountId],
				NewStockline.[GlAccountName]            = CASE WHEN ReceiveGLAccount.[GLAccountId] IS NULL THEN NewStockline.[GlAccountName]
															   ELSE ReceiveGLAccount.[AccountCode] + '-' + ReceiveGLAccount.[AccountName] END,
				NewStockline.[SerialNumber]             = CASE WHEN ISNULL(NewStockline.[isSerialized], 0) = 1 THEN ReceiveRow.[SerialNumber] ELSE NewStockline.[SerialNumber] END,
				NewStockline.[UnitCost]                 = ReceiveRow.[UnitCost],
				NewStockline.[ManufacturerLotNumber]    = ReceiveRow.[ManufacturerLotNumber],
				NewStockline.[ManufacturingBatchNumber] = ReceiveRow.[ManufacturingBatchNumber],
				NewStockline.[ManufacturingDate]        = ReceiveRow.[ManufacturingDate],
				NewStockline.[ExpirationDate]           = ReceiveRow.[ExpirationDate],
				NewStockline.[PartCertificationNumber]  = ReceiveRow.[PartCertificationNumber],
				NewStockline.[CertifiedDate]            = ReceiveRow.[CertifiedDate],
				NewStockline.[CertTypeId]               = ReceiveRow.[CertTypeId],
				NewStockline.[CertType]                 = CASE WHEN ReceiveRow.[CertTypeId] IS NULL THEN NULL ELSE @CertTypeNames END,
				NewStockline.[TagDate]                  = ReceiveRow.[TagDate],
				NewStockline.[TagTypeId]                = ReceiveRow.[TagTypeId],
				NewStockline.[ObtainFromType]           = ISNULL(@CustomerObtainFromType, NewStockline.[ObtainFromType]),
				NewStockline.[ObtainFrom]               = @CustomerId,
				NewStockline.[ObtainFromName]           = @CustomerName
			FROM [dbo].[Stockline] NewStockline
				INNER JOIN #ReceiveRows ReceiveRow ON ReceiveRow.[RowId] = @RowId
				LEFT JOIN [dbo].[GLAccount] ReceiveGLAccount WITH (NOLOCK) ON ReceiveGLAccount.[GLAccountId] = ReceiveRow.[GLAccountId]
			WHERE NewStockline.[StockLineId] = @NewStocklineId;

			/* 3. TimeLife of the original stockline */
			INSERT INTO [dbo].[TimeLife]
				([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining],[TimeSinceNew]
				,[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[MasterCompanyId]
				,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineId]
				,[DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId])
			SELECT OriginalTimeLife.[CyclesRemaining],OriginalTimeLife.[CyclesSinceNew],OriginalTimeLife.[CyclesSinceOVH],OriginalTimeLife.[CyclesSinceInspection]
				,OriginalTimeLife.[CyclesSinceRepair],OriginalTimeLife.[TimeRemaining],OriginalTimeLife.[TimeSinceNew],OriginalTimeLife.[TimeSinceOVH]
				,OriginalTimeLife.[TimeSinceInspection],OriginalTimeLife.[TimeSinceRepair],OriginalTimeLife.[LastSinceNew],OriginalTimeLife.[LastSinceOVH]
				,OriginalTimeLife.[LastSinceInspection],OriginalTimeLife.[MasterCompanyId],@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE()
				,OriginalTimeLife.[IsActive],NULL,NULL,@NewStocklineId,OriginalTimeLife.[DetailsNotProvided],NULL,NULL
			FROM [dbo].[TimeLife] OriginalTimeLife WITH (NOLOCK)
			WHERE OriginalTimeLife.[StockLineId] = @OriginalStocklineId;

			/* 4. documents of the original stockline (before UpdateStocklineColumnsWithId so IsDocument is set) */
			DECLARE @AttachmentMap TABLE ([OldAttachmentId] BIGINT, [NewAttachmentId] BIGINT);
			DELETE FROM @AttachmentMap;

			MERGE INTO [dbo].[Attachment] AS TargetAttachment
			USING (SELECT SourceAttachment.[AttachmentId], SourceAttachment.[MasterCompanyId], SourceAttachment.[CreatedBy], SourceAttachment.[UpdatedBy],
						  SourceAttachment.[SubModuleId], SourceAttachment.[SubReferenceId]
				   FROM [dbo].[Attachment] SourceAttachment WITH (NOLOCK)
				   WHERE SourceAttachment.[AttachmentId] IN (SELECT DISTINCT SourceDocument.[AttachmentId] FROM [dbo].[CommonDocumentDetails] SourceDocument WITH (NOLOCK)
														   WHERE SourceDocument.[ModuleId] = @StocklineAttachmentModuleId AND SourceDocument.[ReferenceId] = @OriginalStocklineId
															 AND ISNULL(SourceDocument.[IsDeleted], 0) = 0)) AS SourceAttachment
			ON 1 = 0
			WHEN NOT MATCHED THEN
				INSERT ([ModuleId],[ReferenceId],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[SubModuleId],[SubReferenceId])
				VALUES (@StocklineAttachmentModuleId, @NewStocklineId, SourceAttachment.[MasterCompanyId], SourceAttachment.[CreatedBy], GETUTCDATE(), SourceAttachment.[UpdatedBy], GETUTCDATE(), 1, 0, SourceAttachment.[SubModuleId], SourceAttachment.[SubReferenceId])
			OUTPUT SourceAttachment.[AttachmentId], inserted.[AttachmentId] INTO @AttachmentMap ([OldAttachmentId], [NewAttachmentId]);

			INSERT INTO [dbo].[AttachmentDetails] ([AttachmentId],[FileName],[Description],[Link],[FileFormat],[FileSize],[FileType],[CreatedDate],[UpdatedDate],[CreatedBy],[UpdatedBy],[IsActive],[IsDeleted],[Name],[Memo],[TypeId])
			SELECT AttachmentCopy.[NewAttachmentId], SourceDetail.[FileName], SourceDetail.[Description], SourceDetail.[Link], SourceDetail.[FileFormat], SourceDetail.[FileSize], SourceDetail.[FileType],
				   GETUTCDATE(), GETUTCDATE(), SourceDetail.[CreatedBy], SourceDetail.[UpdatedBy], 1, 0, SourceDetail.[Name], SourceDetail.[Memo], SourceDetail.[TypeId]
			FROM [dbo].[AttachmentDetails] SourceDetail WITH (NOLOCK)
				INNER JOIN @AttachmentMap AttachmentCopy ON SourceDetail.[AttachmentId] = AttachmentCopy.[OldAttachmentId]
			WHERE ISNULL(SourceDetail.[IsActive], 1) = 1 AND ISNULL(SourceDetail.[IsDeleted], 0) = 0;

			INSERT INTO [dbo].[CommonDocumentDetails] ([ModuleId],[ReferenceId],[AttachmentId],[DocName],[DocMemo],[DocDescription],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[DocumentTypeId],[ExpirationDate],[ReferenceIndex],[ModuleType],[SubModuleId],[SubReferenceId])
			SELECT SourceDocument.[ModuleId], @NewStocklineId, AttachmentCopy.[NewAttachmentId], SourceDocument.[DocName], SourceDocument.[DocMemo], SourceDocument.[DocDescription], SourceDocument.[MasterCompanyId],
				   SourceDocument.[CreatedBy], SourceDocument.[UpdatedBy], GETUTCDATE(), GETUTCDATE(), SourceDocument.[IsActive], 0, SourceDocument.[DocumentTypeId], SourceDocument.[ExpirationDate],
				   SourceDocument.[ReferenceIndex], SourceDocument.[ModuleType], SourceDocument.[SubModuleId], SourceDocument.[SubReferenceId]
			FROM [dbo].[CommonDocumentDetails] SourceDocument WITH (NOLOCK)
				INNER JOIN @AttachmentMap AttachmentCopy ON SourceDocument.[AttachmentId] = AttachmentCopy.[OldAttachmentId]
			WHERE SourceDocument.[ModuleId] = @StocklineAttachmentModuleId AND SourceDocument.[ReferenceId] = @OriginalStocklineId AND ISNULL(SourceDocument.[IsDeleted], 0) = 0;

			/* 5. name columns, MS details, memo, history */
			EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId;

			EXEC [dbo].[USP_SaveSLMSDetails] @StocklineMSModuleId, @NewStocklineId, @HeaderMSId, @MasterCompanyId, @UpdatedBy;

			UPDATE [dbo].[Stockline]
			SET [IsCustomerStock] = @OriginalIsCustomerStock, -- keep the original stock type (UpdateStocklineColumnsWithId recalculates it from the customer affiliation)
				[Memo] = ISNULL([Memo], '') + N'<p>Stockline Received from Customer RMA – ' + ISNULL(@RMANumber, '') + N' (' + ISNULL(@ReceiverNumber, '') + N')</p>'
					   + CASE WHEN ISNULL(@RowMemo, '') <> '' THEN N'<p>' + @RowMemo + N'</p>' ELSE N'' END
			WHERE [StockLineId] = @NewStocklineId;

			EXEC [dbo].[USP_AddUpdateStocklineHistory]
				@StocklineId = @NewStocklineId,
				@ModuleId = @CustomerRMAModuleId,
				@ReferenceId = @RMAHeaderId,
				@SubModuleId = NULL,
				@SubRefferenceId = NULL,
				@ActionId = @CreateFromCustomerRMAActionId,
				@Qty = @QtyToReceive,
				@UpdatedBy = @UpdatedBy;

			/* 6. original stockline was sold from a LOT: Trans-In the received stockline back into the same LOT */
			IF ISNULL(@SourceLotId, 0) > 0
			BEGIN
				DECLARE @LotDetails [dbo].[LotTransInOutDetailsType];
				DECLARE @LotCreatedDate DATETIME = GETUTCDATE();
				DELETE FROM @LotDetails;

				INSERT INTO @LotDetails ([LotTransInOutId],[StockLineId],[LotId],[QtyToTransIn],[QtyToTransOut],[LotTransInOutDetails],
										 [UnitCost],[ExtCost],[IsTransOut],[TransInMemo],[TransOutMemo])
				SELECT 0, ReceivedStockline.[StockLineId], @SourceLotId, @QtyToReceive, 0, 0,
					   ISNULL(ReceivedStockline.[UnitCost], 0), ISNULL(ReceivedStockline.[UnitCost], 0) * @QtyToReceive, 0,
					   'Trans In From Customer RMA - ' + ISNULL(@RMANumber, ''), ''
				FROM [dbo].[Stockline] ReceivedStockline WITH (NOLOCK)
				WHERE ReceivedStockline.[StockLineId] = @NewStocklineId;

				IF OBJECT_ID('tempdb..#LotResult') IS NOT NULL DROP TABLE #LotResult;
				CREATE TABLE #LotResult ([LotTransInOutId] BIGINT);

				INSERT INTO #LotResult
				EXEC [dbo].[USP_Lot_AddUpdateLotTransInOutDetails]
					@tbl_LotTransInOutDetailsType = @LotDetails,
					@LotTransInOutId              = 0,
					@MasterCompanyId              = @MasterCompanyId,
					@IsTransInOut                 = 0,
					@IsInOut                      = 1,
					@CreatedBy                    = @UpdatedBy,
					@UpdatedBy                    = @UpdatedBy,
					@CreatedDate                  = @LotCreatedDate,
					@UpdatedDate                  = @LotCreatedDate,
					@IsFromPreCostStk             = 1;

				DROP TABLE #LotResult;
			END

			/* 7. RMA part: received qty, receiver / return date */
			UPDATE RMADetail
			SET RMADetail.[QtyReceived] = ISNULL(RMADetail.[QtyReceived], 0) + @QtyToReceive,
				RMADetail.[ReceiverNum] = @ReceiverNumber,
				RMADetail.[ReturnDate]  = ISNULL(RMADetail.[ReturnDate], @ReceivedDate),
				RMADetail.[UpdatedBy]   = @UpdatedBy,
				RMADetail.[UpdatedDate] = GETUTCDATE()
			FROM [dbo].[CustomerRMADeatils] RMADetail
			WHERE RMADetail.[RMADeatilsId] = @RMADeatilsId;

			INSERT INTO #CreatedStocklines ([StockLineId],[StockLineNumber],[RMADeatilsId],[Quantity])
			VALUES (@NewStocklineId, @StockLineNumber, @RMADeatilsId, @QtyToReceive);

			SET @RowId = @RowId + 1;
		END

		/* RMA header: receiver / return date; Closed when every part is fully received */
		UPDATE RMAHeader
		SET RMAHeader.[ReceiverNum] = @ReceiverNumber,
			RMAHeader.[ReturnDate]  = ISNULL(RMAHeader.[ReturnDate], @ReceivedDate),
			RMAHeader.[RMAStatusId] = CASE WHEN NOT EXISTS (SELECT 1 FROM [dbo].[CustomerRMADeatils] PendingDetail WITH (NOLOCK)
															WHERE PendingDetail.[RMAHeaderId] = @RMAHeaderId AND ISNULL(PendingDetail.[IsDeleted], 0) = 0
															  AND ISNULL(PendingDetail.[QtyReceived], 0) < ISNULL(PendingDetail.[Qty], 0))
										   THEN @ClosedStatusId ELSE RMAHeader.[RMAStatusId] END,
			RMAHeader.[RMAStatus]   = CASE WHEN NOT EXISTS (SELECT 1 FROM [dbo].[CustomerRMADeatils] PendingDetail WITH (NOLOCK)
															WHERE PendingDetail.[RMAHeaderId] = @RMAHeaderId AND ISNULL(PendingDetail.[IsDeleted], 0) = 0
															  AND ISNULL(PendingDetail.[QtyReceived], 0) < ISNULL(PendingDetail.[Qty], 0))
										   THEN @ClosedStatus ELSE RMAHeader.[RMAStatus] END,
			RMAHeader.[UpdatedBy]   = @UpdatedBy,
			RMAHeader.[UpdatedDate] = GETUTCDATE()
		FROM [dbo].[CustomerRMAHeader] RMAHeader
		WHERE RMAHeader.[RMAHeaderId] = @RMAHeaderId;

		COMMIT TRANSACTION

		SELECT CAST(1 AS BIT) AS [IsSuccess],
			   'Stockline created successfully. Receiver Num: ' + ISNULL(@ReceiverNumber, '') AS [Message],
			   RMAHeader.[RMAStatusId], RMAHeader.[RMAStatus], @ReceiverNumber AS [ReceiverNumber]
		FROM [dbo].[CustomerRMAHeader] RMAHeader WITH (NOLOCK)
		WHERE RMAHeader.[RMAHeaderId] = @RMAHeaderId;

		SELECT CreatedStockline.[StockLineId], CreatedStockline.[StockLineNumber], CreatedStockline.[RMADeatilsId], CreatedStockline.[Quantity]
		FROM #CreatedStocklines CreatedStockline;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_ReceiveCustomerRMAParts'
			, @ProcedureParameters VARCHAR(3000) = '@RMAHeaderId = ''' + CAST(ISNULL(@RMAHeaderId, '') AS VARCHAR(100)) + ''', @UpdatedBy = ''' + ISNULL(@UpdatedBy, '') + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END
