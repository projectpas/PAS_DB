
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_GetPurchaseOrderPartViewByPOId   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_GetPurchaseOrderPartViewByPOId.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************   
-- =============================================
-- Author:		<Rajesh Gami>
-- Create date: <20-Nov-2024>
-- Description:	<Get Purchase Part List By PurchaseOrder Id from the VIEW>
-- =============================================
**************************************************************

** Change History 
**************************************************************   
** PR   Date			Author				Change Description  
** --   --------		-------				--------------------------------
** 1    20-Nov-2024		RAJESH GAMI		    CREATED
   2    24-Dec-2024		Ayushi Patel		Return functional and report currency
   3	08-May-2026	    Priyansh Patel 		Added Ac tail number (PN-16231)
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	5    20/July/2026			 RAJESH GAMI						[PN-17350] - Non-Stock branch of the PartNumber CASE (both parent-row and child-row selects) now reads DBO.ItemMaster (IsNonStock=1) instead of the legacy DBO.ItemMasterNonStock table

--EXEC [dbo].[USP_GetPurchaseOrderPartViewByPOId] 3131 ,NULL,NULL
**************************************************************/ 

CREATE           PROCEDURE [dbo].[USP_GetPurchaseOrderPartViewByPOId]
@PurchaseOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @RoutinePriorityId INT = (SELECT TOP 1 PriorityId FROM dbo.[Priority] WITH(NOLOCK) WHERE LOWER(Description) = 'routine');
				DECLARE @TotalPartsCount int = 0, @PartLoopId int = 1, @ItemTypeIdAsset int = (SELECT TOP 1 ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE Name = 'Asset');
				DECLARE @ItemTypeIdStock int = (SELECT TOP 1 ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE Name = 'Stock'), @ItemMasterId BIGINT =0, @StockLineCount INT =0, @DraftedStockLineCount INT =0;
				DECLARE @ItemTypeIdNonStock int = (SELECT TOP 1 ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE Name = 'Non-Stock'),@PartDescription VARCHAR(MAX);
				DECLARE @isParentPart bit = 0, @WorkOrderMaterialsId BIGINT = 0, @ItemTypeId INT =0,@AltEquiPartNumberId BIGINT =0,@ManufacturerId BIGINT =0; 
				DECLARE @GlAccountId BIGINT =0, @UOMId BIGINT,@IsPartApproved bit =0, @ActionId INT =0, @ApprovedActionId INT = (SELECT ApprovalProcessId FROM DBO.ApprovalProcess WITH(NOLOCK) WHERE Name ='Approved');
				DECLARE @AssetAltEquiPartNumber VARCHAR(50),@Manufacturer VARCHAR(100), @GlAccount VARCHAR(200),@UnitOfMeasure VARCHAR(100),@PurchaseOrderPartRecordId BIGINT =0;
				DECLARE @PoPartMGMTModuleId BIGINT = (SELECT ManagementStructureModuleId FROM DBO.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName ='POPart'); 
				DECLARE @wonum VARCHAR(MAX)='', @ronum VARCHAR(MAX)='', @sonum VARCHAR(MAX)='', @lotnum VARCHAR(MAX)='', @swonum VARCHAR(MAX)='',@esonum VARCHAR(MAX)='';
                IF OBJECT_ID(N'tempdb..#tmpPoPartList') IS NOT NULL    
				BEGIN    
					DROP TABLE #tmpPoPartList
				END
				IF OBJECT_ID(N'tempdb..#tmpWOMtbl') IS NOT NULL    
				BEGIN    
					DROP TABLE #tmpWOMtbl
				END
				CREATE TABLE #tmpPoPartList (
					Id [int] IDENTITY(1,1) NOT NULL,
					PurchaseOrderPartRecordId BIGINT NULL,
					PurchaseOrderId BIGINT NULL,
					ItemMasterId BIGINT NULL,
					PartNumber VARCHAR(250) NULL,
					PartDescription VARCHAR(MAX) NULL,
					AltEquiPartNumberId BIGINT NULL,
					AltEquiPartNumber VARCHAR(250) NULL,
					AltEquiPartDescription VARCHAR(MAX) NULL,
					StockType VARCHAR(50) NULL,
					ManufacturerId BIGINT NULL,
					Manufacturer VARCHAR(250) NULL,
					PriorityId BIGINT NULL,
					Priority VARCHAR(50) NULL,
					NeedByDate DATETIME2(7) NULL,
					ConditionId BIGINT NULL,
					Condition VARCHAR(256) NULL,
					QuantityOrdered INT NULL,
					QuantityBackOrdered INT NULL,
					QuantityRejected INT NULL,
					VendorListPrice DECIMAL(18, 2) NULL,
					DiscountPercent BIGINT NULL,
					DiscountPerUnit DECIMAL(18, 2) NULL,
					DiscountAmount DECIMAL(18, 2) NULL,
					UnitCost DECIMAL(18, 2) NULL,
					ExtendedCost DECIMAL(18, 2) NULL,
					FunctionalCurrencyId INT NULL,
					FunctionalCurrency VARCHAR(50) NULL,
					ForeignExchangeRate DECIMAL(18, 2) NULL,
					ReportCurrencyId INT NULL,
					ReportCurrency VARCHAR(50) NULL,
					WorkOrderId BIGINT NULL,
					WorkOrderNo VARCHAR(250) NULL,
					SubWorkOrderId BIGINT NULL,
					SubWorkOrderNo VARCHAR(250) NULL,
					RepairOrderId BIGINT NULL,
					ReapairOrderNo VARCHAR(250) NULL,
					SalesOrderId BIGINT NULL,
					SalesOrderNo VARCHAR(250) NULL,
					ItemTypeId INT NULL,
					ItemType VARCHAR(250) NULL,
					GlAccountId BIGINT NULL,
					GLAccount VARCHAR(250) NULL,
					UOMId BIGINT NULL,
					UnitOfMeasure VARCHAR(25) NULL,
					ManagementStructureId BIGINT NULL,
					Level1 VARCHAR(200) NULL,
					Level2 VARCHAR(200) NULL,
					Level3 VARCHAR(200) NULL,
					Level4 VARCHAR(200) NULL,
					ParentId BIGINT NULL,
					isParent BIT NULL,
					Memo NVARCHAR(MAX) NULL,
					POPartSplitUserTypeId INT NULL,
					POPartSplitUserType VARCHAR(100) NULL,
					POPartSplitUserId BIGINT NULL,
					POPartSplitUser VARCHAR(100) NULL,
					POPartSplitSiteId BIGINT NULL,
					POPartSplitSiteName VARCHAR(500) NULL,
					POPartSplitAddressId BIGINT NULL,
					POPartSplitAddress1 VARCHAR(100) NULL,
					POPartSplitAddress2 VARCHAR(100) NULL,
					POPartSplitAddress3 VARCHAR(100) NULL,
					POPartSplitCity VARCHAR(50) NULL,
					POPartSplitState VARCHAR(50) NULL,
					POPartSplitPostalCode VARCHAR(20) NULL,
					POPartSplitCountryId INT NULL,
					POPartSplitCountryName VARCHAR(200) NULL,
					MasterCompanyId INT NULL,
					CreatedBy VARCHAR(256) NULL,
					UpdatedBy VARCHAR(256) NULL,
					CreatedDate DATETIME2(7) NULL,
					UpdatedDate DATETIME2(7) NULL,
					IsActive BIT NULL,
					IsDeleted BIT NULL,
					DiscountPercentValue DECIMAL(18, 2) NULL,
					EstDeliveryDate DATETIME2(7) NULL,
					ExchangeSalesOrderId BIGINT NULL,
					ExchangeSalesOrderNo VARCHAR(250) NULL,
					ManufacturerPN VARCHAR(150) NULL,
					AssetModel VARCHAR(30) NULL,
					AssetClass VARCHAR(50) NULL,
					IsLotAssigned BIT NULL,
					LotId BIGINT NULL,
					WorkOrderMaterialsId BIGINT NULL,
					VendorRFQPOPartRecordId BIGINT NULL,
					TraceableTo BIGINT NULL,
					TraceableToName VARCHAR(250) NULL,
					TraceableToType INT NULL,
					TagTypeId BIGINT NULL,
					TaggedBy BIGINT NULL,
					TaggedByType INT NULL,
					TaggedByName VARCHAR(250) NULL,
					TaggedByTypeName VARCHAR(250) NULL,
					TagDate DATETIME2(7) NULL,
					IsKit BIT NULL DEFAULT 0,
					IsSubWO BIT NULL,
					AircraftRegistryNumber VARCHAR(30) NULL,
					ACTailNum VARCHAR(250) NULL
				);
				 IF OBJECT_ID(N'tempdb..#tmpSubWOMtbl') IS NOT NULL    
				BEGIN    
					DROP TABLE #tmpSubWOMtbl
				END
				 IF OBJECT_ID(N'tempdb..#tmpItemMasterTbl') IS NOT NULL    
				BEGIN    
					DROP TABLE #tmpItemMasterTbl
				END
				IF OBJECT_ID(N'tempdb..#mainReturnTable') IS NOT NULL    
				BEGIN    
					DROP TABLE #mainReturnTable
				END
				CREATE TABLE #mainReturnTable (
					PurchaseOrderPartRecordId BIGINT NULL,
					PurchaseOrderId BIGINT NULL,
					ItemMasterId BIGINT NULL,
					PartNumber VARCHAR(250) NULL,
					PartDescription VARCHAR(MAX) NULL,
					AltEquiPartNumberId BIGINT NULL,
					AltEquiPartNumber VARCHAR(250) NULL,
					AltEquiPartDescription VARCHAR(MAX) NULL,
					StockType VARCHAR(50) NULL,
					ManufacturerId BIGINT NULL,
					Manufacturer VARCHAR(250) NULL,
					PriorityId BIGINT NULL,
					Priority VARCHAR(50) NULL,
					NeedByDate DATETIME2(7) NULL,
					ConditionId BIGINT NULL,
					Condition VARCHAR(256) NULL,
					QuantityOrdered INT NULL,
					QuantityBackOrdered INT NULL,
					QuantityRejected INT NULL,
					VendorListPrice DECIMAL(18, 2) NULL,
					DiscountPercent BIGINT NULL,
					DiscountPerUnit DECIMAL(18, 2) NULL,
					DiscountAmount DECIMAL(18, 2) NULL,
					UnitCost DECIMAL(18, 2) NULL,
					ExtendedCost DECIMAL(18, 2) NULL,
					FunctionalCurrencyId INT NULL,
					FunctionalCurrency VARCHAR(50) NULL,
					ForeignExchangeRate DECIMAL(18, 2) NULL,
					ReportCurrencyId INT NULL,
					ReportCurrency VARCHAR(50) NULL,
					WorkOrderId BIGINT NULL,
					WorkOrderNo VARCHAR(250) NULL,
					SubWorkOrderId BIGINT NULL,
					SubWorkOrderNo VARCHAR(250) NULL,
					RepairOrderId BIGINT NULL,
					RepairOrderNo VARCHAR(250) NULL,
					SalesOrderId BIGINT NULL,
					SalesOrderNo VARCHAR(250) NULL,
					ItemTypeId INT NULL,
					ItemType VARCHAR(250) NULL,
					GlAccountId BIGINT NULL,
					GLAccount VARCHAR(250) NULL,
					UOMId BIGINT NULL,
					UnitOfMeasure VARCHAR(25) NULL,
					ManagementStructureId BIGINT NULL,
					Level1 VARCHAR(200) NULL,
					Level2 VARCHAR(200) NULL,
					Level3 VARCHAR(200) NULL,
					Level4 VARCHAR(200) NULL,
					ParentId BIGINT NULL,
					IsParent BIT NULL,
					Memo NVARCHAR(MAX) NULL,
					POPartSplitUserTypeId INT NULL,
					POPartSplitUserType VARCHAR(100) NULL,
					POPartSplitUserId BIGINT NULL,
					POPartSplitUser VARCHAR(100) NULL,
					POPartSplitSiteId BIGINT NULL,
					POPartSplitSiteName VARCHAR(500) NULL,
					POPartSplitAddressId BIGINT NULL,
					POPartSplitAddress1 VARCHAR(100) NULL,
					POPartSplitAddress2 VARCHAR(100) NULL,
					POPartSplitAddress3 VARCHAR(100) NULL,
					POPartSplitCity VARCHAR(50) NULL,
					POPartSplitState VARCHAR(50) NULL,
					POPartSplitPostalCode VARCHAR(20) NULL,
					POPartSplitCountryId INT NULL,
					POPartSplitCountryName VARCHAR(200) NULL,
					MasterCompanyId INT NULL,
					CreatedBy VARCHAR(256) NULL,
					UpdatedBy VARCHAR(256) NULL,
					CreatedDate DATETIME2(7) NULL,
					UpdatedDate DATETIME2(7) NULL,
					IsActive BIT NULL,
					IsDeleted BIT NULL,
					DiscountPercentValue DECIMAL(18, 2) NULL,
					EstDeliveryDate DATETIME2(7) NULL,
					ExchangeSalesOrderId BIGINT NULL,
					ExchangeSalesOrderNo VARCHAR(250) NULL,
					ManufacturerPN VARCHAR(150) NULL,
					AssetModel VARCHAR(30) NULL,
					AssetClass VARCHAR(50) NULL,
					IsLotAssigned BIT NULL,
					LotId BIGINT NULL,
					WorkOrderMaterialsId BIGINT NULL,
					VendorRFQPOPartRecordId BIGINT NULL,
					TraceableTo BIGINT NULL,
					TraceableToName VARCHAR(250) NULL,
					TraceableToType INT NULL,
					TagTypeId BIGINT NULL,
					TaggedBy BIGINT NULL,
					TaggedByType INT NULL,
					TaggedByName VARCHAR(250) NULL,
					TaggedByTypeName VARCHAR(250) NULL,
					TagDate DATETIME2(7) NULL,
					IsKit BIT NULL DEFAULT 0,
					IsSubWO BIT NULL,
					ExpectedSerialNumber VARCHAR(250) NULL,POChargesCount INT NULL, POFrightsCount INT NULL,IsApproved BIT NULL,
					LastMSLevel VARCHAR(MAX) NULL,AllMSlevels VARCHAR(MAX) NULL,
					LotNumber VARCHAR(100) NULL,
					ReapairOrderNo VARCHAR(100) NULL,
					StockLineCount INT NULL,
					DraftedStockLineCount INT NULL,
					PurchaseUnitOfMeasureId BIGINT NULL,
					ConditionCodeId BIGINT NULL,
					Quantity INT NULL,
					AircraftRegistryNumber VARCHAR(30) NULL,
					ACTailNum VARCHAR(250) NULL
				);
				INSERT INTO #tmpPoPartList SELECT 
				PurchaseOrderPartRecordId,
				PurchaseOrderId,
				ItemMasterId,
				PartNumber,
				PartDescription,
				AltEquiPartNumberId,
				AltEquiPartNumber,
				AltEquiPartDescription,
				StockType,
				ManufacturerId,
				Manufacturer,
				PriorityId,
				(SELECT TOP 1 [Description] from dbo.[Priority] PR WITH(NOLOCK) WHERE PR.PriorityId = P.PriorityId),
				NeedByDate,
				ConditionId,
				Condition,
				QuantityOrdered,
				QuantityBackOrdered,
				QuantityRejected,
				VendorListPrice,
				DiscountPercent,
				DiscountPerUnit,
				DiscountAmount,
				UnitCost,
				ExtendedCost,
				FunctionalCurrencyId,
				FunctionalCurrency,
				ForeignExchangeRate,
				ReportCurrencyId,
				ReportCurrency,
				WorkOrderId,
				WorkOrderNo,
				SubWorkOrderId,
				SubWorkOrderNo,
				RepairOrderId,
				ReapairOrderNo,
				SalesOrderId,
				SalesOrderNo,
				ItemTypeId,
				ItemType,
				GlAccountId,
				GLAccount,
				UOMId,
				(SELECT TOP 1 ShortName from dbo.UnitOfMeasure U WITH(NOLOCK) WHERE U.UnitOfMeasureId = P.UOMId),
				ManagementStructureId,
				Level1,
				Level2,
				Level3,
				Level4,
				ParentId,
				isParent,
				Memo,
				POPartSplitUserTypeId,
				POPartSplitUserType,
				POPartSplitUserId,
				POPartSplitUser,
				POPartSplitSiteId,
				POPartSplitSiteName,
				POPartSplitAddressId,
				POPartSplitAddress1,
				POPartSplitAddress2,
				POPartSplitAddress3,
				POPartSplitCity,
				POPartSplitState,
				POPartSplitPostalCode,
				POPartSplitCountryId,
				POPartSplitCountryName,
				MasterCompanyId,
				CreatedBy,
				UpdatedBy,
				CreatedDate,
				UpdatedDate,
				IsActive,
				IsDeleted,
				DiscountPercentValue,
				EstDeliveryDate,
				ExchangeSalesOrderId,
				ExchangeSalesOrderNo,
				ManufacturerPN,
				AssetModel,
				AssetClass,
				IsLotAssigned,
				LotId,
				WorkOrderMaterialsId,
				VendorRFQPOPartRecordId,
				TraceableTo,
				TraceableToName,
				TraceableToType,
				TagTypeId,
				TaggedBy,
				TaggedByType,
				TaggedByName,
				TaggedByTypeName,
				TagDate,
				IsKit,
				IsSubWO,
				AircraftRegistryNumber,
				ACTailNum
				FROM DBO.PurchaseOrderPart P WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND ISNULL(IsDeleted,0) = 0 
				--SELECT * FROM #tmpPoPartList
				--SELECT * INTO #tmpPoPartList FROM (SELECT * FROM DBO.PurchaseOrderPart WITH(NOLOCK) WHERE PurchaseOrderId = @PurchaseOrderId AND ISNULL(IsDeleted,0) = 0) AS partResult
				SET @TotalPartsCount = (SELECT COUNT(1) FROM #tmpPoPartList)
				IF(@TotalPartsCount>0)
				BEGIN -->>>>> Start: If Main @TotalPartsCount>0
					WHILE @PartLoopId <= @TotalPartsCount
					BEGIN -->>>>> Start: While Loop Main
						IF OBJECT_ID(N'tempdb..#tmpLoopTable') IS NOT NULL    
						BEGIN    
							DROP TABLE #tmpLoopTable
						END
						IF OBJECT_ID(N'tempdb..#tmpWOMTble') IS NOT NULL    
						BEGIN    
							DROP TABLE #tmpWOMTble
						END
						SELECT * INTO #tmpLoopTable FROM (SELECT * FROM #tmpPoPartList WHERE Id = @PartLoopId) as res
						SELECT @isParentPart = IsParent,@WorkOrderMaterialsId = WorkOrderMaterialsId, @ItemTypeId = ItemTypeId,
							   @AltEquiPartNumberId =AltEquiPartNumberId, @ManufacturerId = ManufacturerId, @GlAccountId = GlAccountId, @UOMId =UOMId,
							   @PurchaseOrderPartRecordId = PurchaseOrderPartRecordId,@ItemMasterId = ItemMasterId,@PartDescription =PartDescription,
							   @AssetAltEquiPartNumber = AltEquiPartNumber,@Manufacturer = Manufacturer,@UnitOfMeasure = UnitOfMeasure,@GlAccount = GlAccount
							   FROM #tmpLoopTable
							SELECT * INTO #tmpWOMTble FROM (SELECT TOP 1 * FROM DBO.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId) as result
								   						
							IF OBJECT_ID(N'tempdb..#tmppoApproval') IS NOT NULL    
							BEGIN    
								DROP TABLE #tmppoApproval
							END
							IF OBJECT_ID(N'tempdb..#tmpPOPMs') IS NOT NULL    
							BEGIN    
								DROP TABLE #tmpPOPMs
							END
							SELECT * INTO #tmppoApproval FROM (SELECT TOP 1 * FROM DBO.PurchaseOrderApproval WITH(NOLOCK) WHERE PurchaseOrderPartId = @PurchaseOrderPartRecordId) as po
							SELECT @ActionId = ActionId FROM #tmppoApproval
							SET @IsPartApproved = (CASE WHEN  @ActionId = @ApprovedActionId THEN 1 ELSE 0 END)

							SELECT * INTO #tmpPOPMs FROM (SELECT TOP 1 * FROM DBO.PurchaseOrderManagementStructureDetails WITH(NOLOCK) WHERE ReferenceID = @PurchaseOrderPartRecordId AND ModuleID = @PoPartMGMTModuleId) as popMs
							
						IF(@isParentPart = 1)
						BEGIN -->> START:  @isParentPart = 1 If
							--IF(@ItemTypeId = @ItemTypeIdAsset)
							--BEGIN -->> START: Check ItemType Asset
							--	IF(@AltEquiPartNumberId >0)
							--	BEGIN
							--		SET @AssetAltEquiPartNumber = (SELECT TOP 1 AssetId FROM DBO.Asset WITH(NOLOCK) WHERE AssetRecordId = @AltEquiPartNumberId )
							--	END
							--	IF(@ManufacturerId >0)
							--	BEGIN
							--		SET @Manufacturer = (SELECT TOP 1 Name FROM DBO.Manufacturer WITH(NOLOCK) WHERE ManufacturerId = @ManufacturerId )
							--	END
							--	IF(@GlAccountId >0)
							--	BEGIN
							--		SET @GlAccount = (SELECT TOP 1 (AccountCode +  '-' + AccountName)  FROM DBO.GLAccount WITH(NOLOCK) WHERE GlAccountId = @GlAccountId )
							--	END
							--	IF(@UOMId >0)
							--	BEGIN
							--		SET @UnitOfMeasure = (SELECT TOP 1 ShortName FROM DBO.UnitOfMeasure WITH(NOLOCK) WHERE UnitOfMeasureId = @UOMId )
							--	END
							--END -->> END: Check ItemType Asset
						
							SET @wonum = (SELECT STRING_AGG(WorkOrderNum, ',') FROM DBO.WorkOrder WITH(NOLOCK) WHERE WorkOrderId IN (SELECT ReferenceId
																					FROM DBO.PurchaseOrderPartReference WITH(NOLOCK)
																					WHERE PurchaseOrderId = @purchaseOrderId AND PurchaseOrderPartId = @purchaseOrderPartRecordId AND ModuleId = 1)); /* ModuleId = 1 for the WO */
							SET @ronum = (SELECT STRING_AGG(RepairOrderNumber, ',') FROM DBO.RepairOrder WITH(NOLOCK) WHERE RepairOrderId IN (SELECT ReferenceId
																					FROM DBO.PurchaseOrderPartReference WITH(NOLOCK)
																					WHERE PurchaseOrderId = @purchaseOrderId AND PurchaseOrderPartId = @purchaseOrderPartRecordId AND ModuleId = 2)); /* ModuleId = 2 for the RO */
							SET @sonum = (SELECT STRING_AGG(SalesOrderNumber, ',')  FROM DBO.SalesOrder WITH(NOLOCK) WHERE SalesOrderId IN (SELECT ReferenceId
																					FROM DBO.PurchaseOrderPartReference WITH(NOLOCK)
																					WHERE PurchaseOrderId = @purchaseOrderId AND PurchaseOrderPartId = @purchaseOrderPartRecordId AND ModuleId = 3)); /* ModuleId = 3 for the SO */
							SET @esonum = (SELECT STRING_AGG(ExchangeSalesOrderNumber, ',') FROM DBO.ExchangeSalesOrder WITH(NOLOCK) WHERE ExchangeSalesOrderId IN (SELECT ReferenceId
																					FROM DBO.PurchaseOrderPartReference WITH(NOLOCK)
																					WHERE PurchaseOrderId = @purchaseOrderId AND PurchaseOrderPartId = @purchaseOrderPartRecordId AND ModuleId = 4)); /* ModuleId = 4 for the Exchnage */
							SET @lotnum = (SELECT STRING_AGG(LotNumber, ',') FROM DBO.Lot WITH(NOLOCK) WHERE LotId IN (SELECT ReferenceId
																					FROM DBO.PurchaseOrderPartReference WITH(NOLOCK)
																					WHERE PurchaseOrderId = @purchaseOrderId AND PurchaseOrderPartId = @purchaseOrderPartRecordId AND ModuleId = 6)); /* ModuleId = 5 for the LOT */
							SET @swonum = (SELECT STRING_AGG(SubWorkOrderNo, ',') FROM DBO.SubWorkOrder WITH(NOLOCK) WHERE SubWorkOrderId IN (SELECT ReferenceId
																					FROM DBO.PurchaseOrderPartReference WITH(NOLOCK)
																					WHERE PurchaseOrderId = @purchaseOrderId AND PurchaseOrderPartId = @purchaseOrderPartRecordId AND ModuleId = 5)); /* ModuleId = 6 for the Sub WO */
							--SET @StockLineCount = (SELECT SUM(ISNULL(Quantity,0)) FROM Dbo.Stockline WITH(NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND ISNULL(isDeleted,0) = 0 AND ISNULL(IsParent,0) = 1)
							--SET @DraftedStockLineCount = (SELECT SUM(ISNULL(Quantity,0)) FROM  Dbo.StockLineDraft WITH(NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND ISNULL(isDeleted,0) = 0 AND ISNULL(IsParent,0) = 1 AND ISNULL(StockLineId,0) = 0)
							INSERT INTO #mainReturnTable (
								PartNumber,
								PartDescription,
								AltEquiPartNumber,
								AltEquiPartDescription,
								PurchaseOrderPartRecordId,
								PurchaseOrderId,
								IsParent,
								LastMSLevel,
								AllMSlevels,
								WorkOrderNo,
								SalesOrderNo,
								ExchangeSalesOrderNo,
								SubWorkOrderNo,
								LotNumber,
								ReapairOrderNo,
								ItemMasterId,
								ManufacturerId,
								Manufacturer,
								GlAccountId,
								GlAccount,
								UOMId,
								UnitOfMeasure,
								NeedByDate,
								EstDeliveryDate,
								ConditionId,
								Condition,
								QuantityOrdered,
								QuantityBackOrdered,
								QuantityRejected,
								UnitCost,
								VendorListPrice,
								DiscountAmount,
								DiscountPercent,
								DiscountPercentValue,
								ExtendedCost,
								FunctionalCurrencyId,
								FunctionalCurrency,
								ReportCurrencyId,
								ReportCurrency,
								ForeignExchangeRate,
								WorkOrderId,
								SubWorkOrderId,
								RepairOrderId,
								SalesOrderId,
								ManagementStructureId,
								Memo,
								MasterCompanyId,
								CreatedBy,
								CreatedDate,
								UpdatedBy,
								UpdatedDate,
								IsActive,
								DiscountPerUnit,
								AltEquiPartNumberId,
								PriorityId,
								StockType,
								StockLineCount,
								DraftedStockLineCount,
								ExchangeSalesOrderId,
								ItemTypeId,
								ManufacturerPN,
								AssetModel,
								AssetClass,
								IsLotAssigned,
								LotId,
								WorkOrderMaterialsId,
								ExpectedSerialNumber,
								TraceableTo,
								TraceableToName,
								TraceableToType,
								TagTypeId,
								TaggedBy,
								TaggedByName,
								TaggedByType,
								TaggedByTypeName,
								TagDate,
								POChargesCount,
								POFrightsCount,[Priority],
								AircraftRegistryNumber,
								ACTailNum
								)
							SELECT (CASE WHEN @ItemTypeId = @ItemTypeIdStock THEN (SELECT TOP 1 PartNumber  FROM DBO.ItemMaster  WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 )
										 WHEN @ItemTypeId = @ItemTypeIdNonStock THEN (SELECT TOP 1 PartNumber  FROM DBO.ItemMaster  WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ISNULL(IsNonStock,0) = 1 )
										 ELSE  (SELECT TOP 1 AssetId  FROM DBO.Asset  WITH(NOLOCK) WHERE AssetRecordId  = @ItemMasterId)
										 END) AS PartNumber,
									(CASE WHEN @ItemTypeId = @ItemTypeIdAsset THEN (SELECT TOP 1 Description  FROM DBO.Asset  WITH(NOLOCK) WHERE AssetRecordId  = @ItemMasterId)
										  ELSE @PartDescription
									 END) AS PartDescription,
									 @AssetAltEquiPartNumber as AltEquiPartNumber,
									 LT.AltEquiPartDescription,
									 LT.PurchaseOrderPartRecordId,
									 LT.PurchaseOrderId,
									 1 as IsParent,
									 ms.LastMSLevel, ms.AllMSlevels,
									 @wonum as WorkOrderNo,
									 @sonum as SalesOrderNo,
									 @esonum as ExchangeSalesOrderNo,
									 @swonum as SubWorkOrderNo,
									 @lotnum as LotNumber,
									 @ronum as ReapairOrderNo,
									 LT.ItemMasterId,
									 ManufacturerId,
									 @Manufacturer Manufacturer,
									 GlAccountId, @GlAccount GlAccount,
									 UOMId, @UnitOfMeasure UnitOfMeasure,
									 NeedByDate,EstDeliveryDate,
									 ConditionId, Condition,QuantityOrdered,QuantityBackOrdered,QuantityRejected,LT.UnitCost,VendorListPrice,
									 DiscountAmount,DiscountPercent,DiscountPercentValue,LT.ExtendedCost,FunctionalCurrencyId,fc.Code AS FunctionalCurrency,ReportCurrencyId,rc.Code AS ReportCurrency,ForeignExchangeRate,
									 LT.WorkOrderId,SubWorkOrderId,RepairOrderId,SalesOrderId,ManagementStructureId,LT.Memo,LT.MasterCompanyId,lt.CreatedBy,lt.CreatedDate,
									 lt.UpdatedBy, lt.UpdatedDate,lt.IsActive,lt.DiscountPerUnit,AltEquiPartNumberId,PriorityId,StockType,
									 @StockLineCount StockLineCount, @DraftedStockLineCount DraftedStockLineCount,ExchangeSalesOrderId,ItemTypeId,ManufacturerPN,
									 AssetModel,AssetClass, ISNULL(IsLotAssigned,0) IsLotAssigned,ISNULL(LotId,0) LotId,ISNULL(LT.WorkOrderMaterialsId,0) WorkOrderMaterialsId,
									 ExpectedSerialNumber,TraceableTo,TraceableToName,TraceableToType,TagTypeId,TaggedBy,TaggedByName,TaggedByType,TaggedByTypeName,TagDate,
									 (SELECT COUNT(1) FROM dbo.PurchaseOrderCharges C WITH(NOLOCK) WHERE c.PurchaseOrderPartRecordId= LT.PurchaseOrderPartRecordId and ISNULL(c.IsDeleted,0) = 0)POChargesCount,
									 (SELECT COUNT(1) FROM dbo.PurchaseOrderFreight C WITH(NOLOCK) WHERE c.PurchaseOrderPartRecordId= LT.PurchaseOrderPartRecordId and ISNULL(c.IsDeleted,0) = 0)POFrightsCount,[Priority],
									  LT.AircraftRegistryNumber,
									 LT.ACTailNum
									 FROM #tmpLoopTable LT LEFT JOIN #tmpPOPMs ms on ms.ReferenceID = LT.PurchaseOrderPartRecordId AND ms.ModuleID = @PoPartMGMTModuleId
									 LEFT JOIN #tmpWOMTble wom on wom.WorkOrderMaterialsId = LT.WorkOrderMaterialsId
									 LEFT JOIN Currency fc on fc.CurrencyId = FunctionalCurrencyId
									 LEFT JOIN Currency rc on rc.CurrencyId = ReportCurrencyId
									 WHERE ISNULL(LT.IsParent,0) = 1
						END -->> END:  @isParentPart = 1 If
						ELSE
						BEGIN
							INSERT INTO #mainReturnTable (
								PartNumber,
								PartDescription,
								AltEquiPartNumber,
								AltEquiPartDescription,
								PurchaseOrderPartRecordId,
								PurchaseOrderId,
								IsParent,
								ParentId,
								LastMSLevel,
								AllMSlevels,
								WorkOrderNo,
								SalesOrderNo,
								ExchangeSalesOrderNo,
								SubWorkOrderNo,
								LotNumber,
								ReapairOrderNo,
								ItemMasterId,
								UOMId,
								UnitOfMeasure,
								NeedByDate,
								EstDeliveryDate,
								ConditionId,
								Condition,
								QuantityOrdered,
								QuantityBackOrdered,
								QuantityRejected,
								UnitCost,
								VendorListPrice,
								DiscountAmount,
								DiscountPercent,
								DiscountPercentValue,
								ExtendedCost,
								FunctionalCurrencyId,
								FunctionalCurrency,
								ReportCurrencyId,
								ReportCurrency,
								ForeignExchangeRate,
								WorkOrderId,
								SubWorkOrderId,
								RepairOrderId,
								SalesOrderId,
								ManagementStructureId,
								Memo,
								MasterCompanyId,
								CreatedBy,
								CreatedDate,
								UpdatedBy,
								UpdatedDate,
								IsActive,
								DiscountPerUnit,
								AltEquiPartNumberId,
								PriorityId,
								StockType,
								StockLineCount,
								DraftedStockLineCount,
								IsApproved,
								POPartSplitAddressId,
								POPartSplitPostalCode,
								POPartSplitCountryId,
								POPartSplitState,
								POPartSplitCity,
								POPartSplitAddress3,
								POPartSplitAddress2,
								POPartSplitAddress1,
								POPartSplitUserTypeId,POPartSplitUserType,POPartSplitUserId,POPartSplitUser,POPartSplitSiteId,POPartSplitSiteName,POPartSplitCountryName,[Priority]
								)
							SELECT (CASE WHEN @ItemTypeId = @ItemTypeIdStock THEN (SELECT TOP 1 PartNumber  FROM DBO.ItemMaster  WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 )
										 WHEN @ItemTypeId = @ItemTypeIdNonStock THEN (SELECT TOP 1 PartNumber  FROM DBO.ItemMaster  WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ISNULL(IsNonStock,0) = 1 )
										 ELSE  (SELECT TOP 1 AssetId  FROM DBO.Asset  WITH(NOLOCK) WHERE AssetRecordId  = @ItemMasterId)
										 END) AS PartNumber,
									(CASE WHEN @ItemTypeId = @ItemTypeIdAsset THEN (SELECT TOP 1 Description  FROM DBO.Asset  WITH(NOLOCK) WHERE AssetRecordId  = @ItemMasterId)
										  ELSE @PartDescription
									 END) AS PartDescription,
									 @AssetAltEquiPartNumber as AltEquiPartNumber,
									 LT.AltEquiPartDescription,
									 LT.PurchaseOrderPartRecordId,
									 LT.PurchaseOrderId,
									 0 as IsParent,ParentId,
									 ms.LastMSLevel, ms.AllMSlevels,
									 @wonum as WorkOrderNo,
									 @sonum as SalesOrderNo,
									 @esonum as ExchangeSalesOrderNo,
									 @swonum as SubWorkOrderNo,
									 @lotnum as LotNumber,
									 @ronum as ReapairOrderNo,
									 LT.ItemMasterId,
									 UOMId, @UnitOfMeasure UnitOfMeasure,
									 NeedByDate,EstDeliveryDate,
									 ConditionId, Condition,QuantityOrdered,QuantityBackOrdered,QuantityRejected,LT.UnitCost,VendorListPrice,
									 DiscountAmount,DiscountPercent,DiscountPercentValue,LT.ExtendedCost,FunctionalCurrencyId,fc.Code AS FunctionalCurrency,ReportCurrencyId,rc.Code AS ReportCurrency,ForeignExchangeRate,
									 LT.WorkOrderId,SubWorkOrderId,RepairOrderId,SalesOrderId,ManagementStructureId,LT.Memo,LT.MasterCompanyId,lt.CreatedBy,lt.CreatedDate,
									 lt.UpdatedBy, lt.UpdatedDate,lt.IsActive,lt.DiscountPerUnit,AltEquiPartNumberId,PriorityId,StockType,
									 @StockLineCount StockLineCount, @DraftedStockLineCount DraftedStockLineCount,
									 @IsPartApproved as IsApproved,POPartSplitAddressId,POPartSplitPostalCode,POPartSplitCountryId,POPartSplitState,POPartSplitCity,POPartSplitAddress3,
									 POPartSplitAddress2,POPartSplitAddress1,POPartSplitUserTypeId,POPartSplitUserType,POPartSplitUserId,POPartSplitUser,POPartSplitSiteId,POPartSplitSiteName,POPartSplitCountryName
									 ,[Priority]
									 FROM #tmpLoopTable LT LEFT JOIN #tmpPOPMs ms on ms.ReferenceID = LT.PurchaseOrderPartRecordId AND ms.ModuleID = @PoPartMGMTModuleId
									 LEFT JOIN Currency fc on fc.CurrencyId = FunctionalCurrencyId
									 LEFT JOIN Currency rc on rc.CurrencyId = ReportCurrencyId
						END

						SET @PartLoopId +=1
					END -->>>>> End: While Loop Main
				END -->>>>> End: If Main @TotalPartsCount>0

				SELECT * FROM #mainReturnTable
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
			SELECT ERROR_NUMBER() AS ErrorNumber,ERROR_STATE() AS ErrorState, ERROR_SEVERITY() AS ErrorSeverity,ERROR_PROCEDURE() AS ErrorProcedure, ERROR_LINE() AS ErrorLine,ERROR_MESSAGE() AS ErrorMessage;
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetPurchaseOrderPartViewByPOId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END