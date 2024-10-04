/*************************************************************           
 ** File:   [SP_AddUpdatePurchaseOrderParts]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to create and update Purchase order parts
 ** Purpose:         
 ** Date:   17/09/2024     
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1    17/09/2024   RAJESH GAMI			Created

************************************************************************/
CREATE   PROCEDURE [dbo].[SP_AddUpdatePurchaseOrderParts]
	@userName varchar(50) = NULL,
	@masterCompanyId bigint = NULL,
	@tbl_PurchaseOrderPartType PurchaseOrderPartType READONLY,
	@tbl_PurchaseOrderSplitPartsType PurchaseOrderSplitPartsType READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN -->>>>> Start: Main Transaction 

			DECLARE @TotalPartsCount int = 0,@TotalSplitPartsCount int = 0, @PartLoopId int = 1, @SplitPartLoopId int = 0,@ManagementStructureId BIGINT,@ManagementStructureIdSplit BIGINT;
			DECLARE @ModuleId INT = (SELECT TOP 1 ManagementStructureModuleId FROM DBO.ManagementStructureModule WITH(NOLOCK) WHERE LOWER(ModuleName) ='popart' AND ISNULL(IsDeleted,0) = 0)
			DECLARE @NewPartId BIGINT = 0, @PurchaseOrderPartRecordId BIGINT, @IsDeletedPart BIT = 0,@PurchaseOrderId BIGINT,@PurchaseOrderNumber VARCHAR(100),@EmployeeID BIGINT;
			DECLARE @IsLotAssigned BIT =0, @LotId BIGINT, @StatusId INT, @FulfillStatusId INT = (SELECT TOP 1 POStatusId FROM DBO.POStatus WITH(NOLOCK) WHERE LOWER(Description) = 'fulfilling');
			DECLARE @ApproveProcessId INT = (SELECT TOP 1 ApprovalProcessId FROM DBO.ApprovalProcess WITH(NOLOCK) WHERE LOWER(Name) = 'approved' AND ISNULL(IsActive,0) = 1)
			DECLARE @ApproveStatusId INT, @ApproveStatus VARCHAR(100),@SalesOrderId BIGINT,@ConditionId BIGINT
			DECLARE @ItemMasterId BIGINT,@SalesOrderPartId BIGINT,@ExchProvisionId INT
			DECLARE @IsCreateExchange BIT = 0, @CoreDueDate DATETIME,@MainWorkOrderMaterialsId BIGINT
			DECLARE @PurchaseOrderPartRecordIdSplit BIGINT,@SplitPartIsDeleted BIT, @WorkOrderMaterialsId BIGINT,@EstDeliveryDate DATETIME, @ExpectedSerialNumber VARCHAR(100)

			DECLARE @OrderPartStatusId INT = (SELECT POPartStatusId FROM dbo.POPartStatus WITH(NOLOCK) WHERE LOWER(Description) ='order')
			SELECT TOP 1 @ApproveStatusId = ApprovalStatusId,@ApproveStatus = [Description]  FROM DBO.ApprovalStatus WITH(NOLOCK) WHERE LOWER(Name) = 'approved' AND ISNULL(IsActive,0) = 1
			

			IF OBJECT_ID(N'tempdb..#tmpPoPartList') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpPoPartList
			END
			IF OBJECT_ID(N'tempdb..#tmpPoSplitAllPartList') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpPoSplitAllPartList
			END
			IF OBJECT_ID(N'tempdb..#tmpPoSplitParts') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpPoSplitParts
			END
			IF OBJECT_ID(N'tempdb..#tmpMainPoPartList') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpMainPoPartList
			END

			
			SELECT * INTO #tmpPoPartList FROM (SELECT * FROM @tbl_PurchaseOrderPartType) AS partResult
			SELECT * INTO #tmpPoSplitAllPartList FROM (SELECT * FROM @tbl_PurchaseOrderSplitPartsType) AS splitPart
			
			SELECT @IsLotAssigned = IsLotAssigned,@LotId = LotId ,@StatusId = StatusId , @PurchaseOrderId = PurchaseOrderId ,@PurchaseOrderNumber =PurchaseOrderNumber
				FROM DBO.PurchaseOrder WHERE PurchaseOrderId = (SELECT TOP 1 PurchaseOrderId FROM #tmpPoPartList)		

			SET @TotalPartsCount = (SELECT COUNT(1) FROM #tmpPoPartList)

			WHILE @PartLoopId <= @TotalPartsCount
			BEGIN -->>>>> Start: While Loop Main
					SELECT @PurchaseOrderPartRecordId= PurchaseOrderPartRecordId,@IsDeletedPart = IsDeleted,@EmployeeID =EmployeeID, @SalesOrderId = SalesOrderId, 
							@ConditionId = ConditionId,@ItemMasterId =ItemMasterId, @WorkOrderMaterialsId = WorkOrderMaterialsId,@EstDeliveryDate =EstDeliveryDate,
							@ExpectedSerialNumber = ExpectedSerialNumber,@ManagementStructureId =ManagementStructureId
							FROM #tmpPoPartList WHERE PoPartSrNum = @PartLoopId;
					IF(@PurchaseOrderPartRecordId > 0)  -->>>>> Start:1 @PurchaseOrderPartRecordId > 0
					BEGIN						
						IF(@IsDeletedPart = 1) -->>>>> Start:2 IF @IsDeletedPart = 1
						BEGIN
							DELETE FROM DBO.PurchaseOrderApproval WHERE PurchaseOrderPartId = @PurchaseOrderPartRecordId
							DELETE FROM DBO.PurchaseOrderCharges WHERE PurchaseOrderPartRecordId =  @PurchaseOrderPartRecordId
							DELETE FROM DBO.PurchaseOrderFreight WHERE PurchaseOrderPartRecordId =  @PurchaseOrderPartRecordId
							DELETE FROM DBO.StockLineDraft WHERE PurchaseOrderPartRecordId =  @PurchaseOrderPartRecordId
							DELETE FROM DBO.PurchaseOrderPart WHERE PurchaseOrderPartRecordId =  @PurchaseOrderPartRecordId							
						END -->>>>> END:2 IF @IsDeletedPart = 1
						ELSE 
						BEGIN
							UPDATE SL
								SET SL.ItemMasterId = PT.ItemMasterId,SL.PurchaseOrderUnitCost = PT.UnitCost,SL.PurchaseOrderExtendedCost = PT.UnitCost,SL.UnitOfMeasureId = PT.UOMId,
								    SL.ConditionId = PT.ConditionId,SL.TraceableToType = PT.TraceableToType,SL.TraceableTo = PT.TraceableTo,SL.TraceableToName = PT.TraceableToName,
									SL.TagTypeId = PT.TagTypeId,SL.TaggedByType = PT.TaggedByType,SL.TaggedBy = PT.TaggedBy,SL.TagDate = PT.TagDate,
									--, SL.CurrencyId = PT.FunctionalCurrencyId,
									SL.UpdatedBy = @userName,SL.UpdatedDate = GETUTCDATE()
								FROM DBO.StockLineDraft SL
								JOIN #tmpPoPartList PT ON SL.PurchaseOrderPartRecordId = PT.PurchaseOrderPartRecordId
								WHERE PT.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId AND ISNULL(SL.StockLineId,0) = 0

							UPDATE PART
								SET PART.ItemMasterId = TMP.ItemMasterId, PART.PartNumber = TMP.PartNumber, 
									PART.PartDescription = TMP.PartDescription,PART.AltEquiPartNumberId = TMP.AltEquiPartNumberId, 
									PART.AltEquiPartNumber = TMP.AltEquiPartNumber, PART.AltEquiPartDescription = TMP.AltEquiPartDescription, 
									PART.StockType = TMP.StockType,PART.ManufacturerId = TMP.ManufacturerId,
									PART.Manufacturer = TMP.Manufacturer,PART.PriorityId = TMP.PriorityId,
									PART.[Priority] = TMP.[Priority], PART.NeedByDate = TMP.NeedByDate, 
									PART.ConditionId = TMP.ConditionId,PART.Condition = TMP.Condition,
									PART.QuantityOrdered = TMP.QuantityOrdered,PART.QuantityBackOrdered = TMP.QuantityBackOrdered,
									PART.QuantityRejected = TMP.QuantityRejected,PART.VendorListPrice = TMP.VendorListPrice,
									PART.DiscountPercent = TMP.DiscountPercent,PART.DiscountPerUnit = TMP.DiscountPerUnit,
									PART.DiscountAmount = TMP.DiscountAmount,PART.UnitCost = TMP.UnitCost,
									PART.ExtendedCost = TMP.ExtendedCost,PART.FunctionalCurrencyId = TMP.FunctionalCurrencyId,
									PART.FunctionalCurrency = TMP.FunctionalCurrency,PART.ForeignExchangeRate = TMP.ForeignExchangeRate,
									PART.ReportCurrencyId = TMP.ReportCurrencyId,PART.ReportCurrency = TMP.ReportCurrency,
									PART.WorkOrderId = TMP.WorkOrderId,PART.WorkOrderNo = TMP.WorkOrderNo,
									PART.SubWorkOrderId = TMP.SubWorkOrderId,PART.SubWorkOrderNo = TMP.SubWorkOrderNo,
									PART.RepairOrderId = TMP.RepairOrderId,PART.ReapairOrderNo = TMP.ReapairOrderNo,
									PART.SalesOrderId = TMP.SalesOrderId,PART.SalesOrderNo = TMP.SalesOrderNo,
									PART.ItemTypeId = TMP.ItemTypeId,PART.ItemType = TMP.ItemType,
									PART.GlAccountId = TMP.GlAccountId,PART.GLAccount = TMP.GLAccount,
									PART.UOMId = TMP.UOMId,PART.UnitOfMeasure = TMP.UnitOfMeasure,
									PART.ManagementStructureId = TMP.ManagementStructureId,
									PART.Level1 = TMP.Level1,PART.Level2 = TMP.Level2,PART.Level3 = TMP.Level3,PART.Level4 = TMP.Level4,
									PART.ParentId = TMP.ParentId,PART.isParent = TMP.isParent,PART.Memo = TMP.Memo,
									PART.POPartSplitUserTypeId = TMP.POPartSplitUserTypeId,PART.POPartSplitUserType = TMP.POPartSplitUserType,
									PART.POPartSplitUserId = TMP.POPartSplitUserId,PART.POPartSplitUser = TMP.POPartSplitUser,
									PART.POPartSplitSiteId = TMP.POPartSplitSiteId,PART.POPartSplitSiteName = TMP.POPartSplitSiteName,
									PART.POPartSplitAddressId = TMP.POPartSplitAddressId,PART.POPartSplitAddress1 = TMP.POPartSplitAddress1,
									PART.POPartSplitAddress2 = TMP.POPartSplitAddress2,PART.POPartSplitAddress3 = TMP.POPartSplitAddress3,
									PART.POPartSplitCity = TMP.POPartSplitCity,PART.POPartSplitState = TMP.POPartSplitState,
									PART.POPartSplitPostalCode = TMP.POPartSplitPostalCode,PART.POPartSplitCountryId = TMP.POPartSplitCountryId,
									PART.POPartSplitCountryName = TMP.POPartSplitCountryName,
									PART.MasterCompanyId = @masterCompanyId,PART.UpdatedBy = @userName,PART.UpdatedDate = GETUTCDATE(),
									PART.DiscountPercentValue = TMP.DiscountPercentValue,PART.EstDeliveryDate = TMP.EstDeliveryDate,
									PART.ExchangeSalesOrderId = TMP.ExchangeSalesOrderId,PART.ExchangeSalesOrderNo = TMP.ExchangeSalesOrderNo,
									PART.ManufacturerPN = TMP.ManufacturerPN,PART.AssetModel = TMP.AssetModel,
									PART.AssetClass = TMP.AssetClass,PART.IsLotAssigned = TMP.IsLotAssigned,
									PART.LotId = TMP.LotId,PART.WorkOrderMaterialsId = TMP.WorkOrderMaterialsId,
									PART.VendorRFQPOPartRecordId = TMP.VendorRFQPOPartRecordId,PART.TraceableTo = TMP.TraceableTo,
									PART.TraceableToName = TMP.TraceableToName,PART.TraceableToType = TMP.TraceableToType,
									PART.TagTypeId = TMP.TagTypeId,PART.TaggedBy = TMP.TaggedBy,PART.TaggedByType = TMP.TaggedByType,
									PART.TaggedByName = TMP.TaggedByName,PART.TaggedByTypeName = TMP.TaggedByTypeName,PART.TagDate = TMP.TagDate
								FROM DBO.PurchaseOrderPart PART
								JOIN #tmpPoPartList TMP
									ON PART.PurchaseOrderPartRecordId = TMP.PurchaseOrderPartRecordId
								WHERE PART.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId

							EXEC dbo.[PROCAddPOMSData] @PurchaseOrderPartRecordId,@ManagementStructureId,@MasterCompanyId,@userName,@userName,@ModuleId,4, 0
                            EXEC dbo.sp_UpdateStocklineDraftForPurchaseOrder @PurchaseOrderId	                                                     
						END -->>>>> END:2 ELSE @IsDeletedPart = 1
					END -->>>>> END:1 @PurchaseOrderPartRecordId > 0
					ELSE
					BEGIN -->>>>> START:1 ELSE @PurchaseOrderPartRecordId > 0

					  INSERT INTO [dbo].[PurchaseOrderPart]
					   ([PurchaseOrderId]
					   ,[ItemMasterId]
					   ,[PartNumber]
					   ,[PartDescription]
					   ,[AltEquiPartNumberId]
					   ,[AltEquiPartNumber]
					   ,[AltEquiPartDescription]
					   ,[StockType]
					   ,[ManufacturerId]
					   ,[Manufacturer]
					   ,[PriorityId]
					   ,[Priority]
					   ,[NeedByDate]
					   ,[ConditionId]
					   ,[Condition]
					   ,[QuantityOrdered]
					   ,[QuantityBackOrdered]
					   ,[QuantityRejected]
					   ,[VendorListPrice]
					   ,[DiscountPercent]
					   ,[DiscountPerUnit]
					   ,[DiscountAmount]
					   ,[UnitCost]
					   ,[ExtendedCost]
					   ,[FunctionalCurrencyId]
					   ,[FunctionalCurrency]
					   ,[ForeignExchangeRate]
					   ,[ReportCurrencyId]
					   ,[ReportCurrency]
					   ,[WorkOrderId]
					   ,[WorkOrderNo]
					   ,[SubWorkOrderId]
					   ,[SubWorkOrderNo]
					   ,[RepairOrderId]
					   ,[ReapairOrderNo]
					   ,[SalesOrderId]
					   ,[SalesOrderNo]
					   ,[ItemTypeId]
					   ,[ItemType]
					   ,[GlAccountId]
					   ,[GLAccount]
					   ,[UOMId]
					   ,[UnitOfMeasure]
					   ,[ManagementStructureId]
					   ,[Level1]
					   ,[Level2]
					   ,[Level3]
					   ,[Level4]
					   ,[ParentId]
					   ,[isParent]
					   ,[Memo]
					   ,[POPartSplitUserTypeId]
					   ,[POPartSplitUserType]
					   ,[POPartSplitUserId]
					   ,[POPartSplitUser]
					   ,[POPartSplitSiteId]
					   ,[POPartSplitSiteName]
					   ,[POPartSplitAddressId]
					   ,[POPartSplitAddress1]
					   ,[POPartSplitAddress2]
					   ,[POPartSplitAddress3]
					   ,[POPartSplitCity]
					   ,[POPartSplitState]
					   ,[POPartSplitPostalCode]
					   ,[POPartSplitCountryId]
					   ,[POPartSplitCountryName]
					   ,[MasterCompanyId]
					   ,[CreatedBy]
					   ,[UpdatedBy]
					   ,[CreatedDate]
					   ,[UpdatedDate]
					   ,[IsActive]
					   ,[IsDeleted]
					   ,[DiscountPercentValue]
					   ,[EstDeliveryDate]
					   ,[ExchangeSalesOrderId]
					   ,[ExchangeSalesOrderNo]
					   ,[ManufacturerPN]
					   ,[AssetModel]
					   ,[AssetClass]
					   ,[IsLotAssigned]
					   ,[LotId]
					   ,[WorkOrderMaterialsId]
					   ,[VendorRFQPOPartRecordId]
					   ,[TraceableTo]
					   ,[TraceableToName]
					   ,[TraceableToType]
					   ,[TagTypeId]
					   ,[TaggedBy]
					   ,[TaggedByType]
					   ,[TaggedByName]
					   ,[TaggedByTypeName]
					   ,[TagDate])
			
					   (SELECT 
						@PurchaseOrderId
					   ,ItemMasterId
					   ,PartNumber
					   ,PartDescription
					   ,AltEquiPartNumberId
					   ,AltEquiPartNumber
					   ,AltEquiPartDescription
					   ,StockType
					   ,ManufacturerId
					   ,Manufacturer
					   ,PriorityId
					   ,Priority
					   ,NeedByDate
					   ,ConditionId
					   ,Condition
					   ,QuantityOrdered
					   ,QuantityBackOrdered
					   ,QuantityRejected
					   ,VendorListPrice
					   ,DiscountPercent
					   ,DiscountPerUnit
					   ,DiscountAmount
					   ,UnitCost
					   ,ExtendedCost
					   ,FunctionalCurrencyId
					   ,FunctionalCurrency
					   ,ForeignExchangeRate
					   ,ReportCurrencyId
					   ,ReportCurrency
					   ,WorkOrderId
					   ,WorkOrderNo
					   ,SubWorkOrderId
					   ,SubWorkOrderNo
					   ,RepairOrderId
					   ,ReapairOrderNo
					   ,SalesOrderId
					   ,SalesOrderNo
					   ,ItemTypeId
					   ,ItemType
					   ,GlAccountId
					   ,GLAccount
					   ,UOMId
					   ,UnitOfMeasure
					   ,ManagementStructureId
					   ,Level1
					   ,Level2
					   ,Level3
					   ,Level4
					   ,ParentId
					   ,1
					   ,Memo
					   ,POPartSplitUserTypeId
					   ,POPartSplitUserType
					   ,POPartSplitUserId
					   ,POPartSplitUser
					   ,POPartSplitSiteId
					   ,POPartSplitSiteName
					   ,POPartSplitAddressId
					   ,POPartSplitAddress1
					   ,POPartSplitAddress2
					   ,POPartSplitAddress3
					   ,POPartSplitCity
					   ,POPartSplitState
					   ,POPartSplitPostalCode
					   ,POPartSplitCountryId
					   ,POPartSplitCountryName
					   ,MasterCompanyId
					   ,@userName
					   ,@userName
					   ,GETUTCDATE()
					   ,GETUTCDATE()
					   ,1
					   ,0
					   ,DiscountPercentValue
					   ,EstDeliveryDate
					   ,ExchangeSalesOrderId
					   ,ExchangeSalesOrderNo
					   ,ManufacturerPN
					   ,AssetModel
					   ,AssetClass
					   ,@IsLotAssigned
					   ,@LotId
					   ,WorkOrderMaterialsId
					   ,VendorRFQPOPartRecordId
					   ,TraceableTo
					   ,TraceableToName
					   ,TraceableToType
					   ,TagTypeId
					   ,TaggedBy
					   ,TaggedByType
					   ,TaggedByName
					   ,TaggedByTypeName
					   ,TagDate
					    FROM #tmpPoPartList WHERE PoPartSrNum = @PartLoopId)

					  SET @PurchaseOrderPartRecordId = SCOPE_IDENTITY();
					  UPDATE #tmpPoPartList SET PurchaseOrderPartRecordId =  @PurchaseOrderPartRecordId, [isParent] = 1,IsLotAssigned =  @IsLotAssigned,LotId= @LotId  WHERE PoPartSrNum = @PartLoopId

						IF(@StatusId = @FulfillStatusId)
						BEGIN -- START: Fulfill Status :IF
							INSERT INTO [dbo].[PurchaseOrderApproval]
							   ([PurchaseOrderId],[PurchaseOrderPartId],[SentDate],[ApprovedDate],
								[ApprovedById],[StatusId],[StatusName],[ActionId],
							    [MasterCompanyId],[CreatedBy],[UpdatedBy],
								[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted] )
							VALUES
							   (@PurchaseOrderId,@PurchaseOrderPartRecordId,GETUTCDATE(),GETUTCDATE(),
							    @EmployeeID,@ApproveStatusId,@ApproveStatus,@ApproveProcessId,
							    @masterCompanyId,@userName,@userName,
							    GETUTCDATE(),GETUTCDATE(),1,0)
						END -- END: Fulfill Status :IF
						
						EXEC dbo.[PROCAddPOMSData] @PurchaseOrderPartRecordId,@ManagementStructureId,@MasterCompanyId,@userName,@userName,@ModuleId,3, 0
						
						IF(ISNULL(@SalesOrderId,0) > 0)
						BEGIN --START: IF  SalesOrderPart
							SELECT TOP 1 @SalesOrderPartId = SalesOrderPartId FROM Dbo.SalesOrderPart WITH(NOLOCK) WHERE SalesOrderId = @SalesOrderId AND ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId
							IF(ISNULL(@SalesOrderPartId,0) > 0 )
							BEGIN
								EXEC dbo.[SP_SaveSOPartStatusByPartId] @SalesOrderPartId, @OrderPartStatusId
							END
						END --END: IF SalesOrderPart
					END -->>>>> END:1 ELSE @PurchaseOrderPartRecordId > 0									
				
/* ----------------------------START:  SPLIT PART Functionality ---------------------------------- */
					SET @SplitPartLoopId = 1;
						IF OBJECT_ID(N'tempdb..#tmpPoSplitParts') IS NOT NULL    
						BEGIN    
							DROP TABLE #tmpPoSplitParts
						END
					SELECT * INTO #tmpPoSplitParts FROM (SELECT * FROM #tmpPoSplitAllPartList sp WHERE sp.PoPartSrNum = @PartLoopId) AS res
					SET @TotalSplitPartsCount = (SELECT COUNT(PoSplitPartSrNum) FROM #tmpPoSplitParts)
					--SELECT * INTO #tmpPoSplitParts FROM (SELECT * FROM #tmpPoSplitAllPartList sp WHERE sp.PoPartSrNum = @PartLoopId) AS res
					
					--SET @TotalSplitPartsCount = (SELECT COUNT(1) FROM #tmpPoSplitAllPartList)
				
					WHILE @SplitPartLoopId <= @TotalSplitPartsCount
					BEGIN -->>>>> Start: Split Part While Loop		
						IF((SELECT COUNT(PoSplitPartSrNum) FROM #tmpPoSplitParts WHERE PoPartSrNum = @PartLoopId AND PoSplitPartSrNum = @SplitPartLoopId) > 0)
						BEGIN
							SELECT @PurchaseOrderPartRecordIdSplit = PurchaseOrderPartRecordId FROM DBO.PurchaseOrderPart WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = (SELECT TOP 1 PurchaseOrderPartRecordId FROM #tmpPoSplitParts WHERE PoSplitPartSrNum = @SplitPartLoopId AND PoPartSrNum = @PartLoopId)		
							SELECT @SplitPartIsDeleted = IsDeleted,@ManagementStructureIdSplit = ManagementStructureId FROM #tmpPoSplitParts WHERE PoSplitPartSrNum = @SplitPartLoopId AND PoPartSrNum = @PartLoopId
							IF(ISNULL(@PurchaseOrderPartRecordIdSplit,0) = 0)
							BEGIN -- START :IF : @PurchaseOrderPartRecordIdSplit,0) = 0
								INSERT INTO [dbo].[PurchaseOrderPart]  -- Insert the split part
								   ([PurchaseOrderId]
								   ,[ItemMasterId]
								   ,[PartNumber]
								   ,[PartDescription]
								   ,[AltEquiPartNumberId]
								   ,[AltEquiPartNumber]
								   ,[AltEquiPartDescription]
								   ,[StockType]
								   ,[ManufacturerId]
								   ,[Manufacturer]
								   ,[PriorityId]
								   ,[Priority]
								   ,[NeedByDate]
								   ,[ConditionId]
								   ,[Condition]
								   ,[QuantityOrdered]
								   ,[QuantityBackOrdered]
								   ,[QuantityRejected]
								   ,[VendorListPrice]
								   ,[DiscountPercent]
								   ,[DiscountPerUnit]
								   ,[DiscountAmount]
								   ,[UnitCost]
								   ,[ExtendedCost]
								   ,[FunctionalCurrencyId]
								   ,[FunctionalCurrency]
								   ,[ForeignExchangeRate]
								   ,[ReportCurrencyId]
								   ,[ReportCurrency]
								   ,[WorkOrderId]
								   ,[WorkOrderNo]
								   ,[SubWorkOrderId]
								   ,[SubWorkOrderNo]
								   ,[RepairOrderId]
								   ,[ReapairOrderNo]
								   ,[SalesOrderId]
								   ,[SalesOrderNo]
								   ,[ItemTypeId]
								   ,[ItemType]
								   ,[GlAccountId]
								   ,[GLAccount]
								   ,[UOMId]
								   ,[UnitOfMeasure]
								   ,[ManagementStructureId]
								   ,[Level1]
								   ,[Level2]
								   ,[Level3]
								   ,[Level4]
								   ,[ParentId]
								   ,[isParent]
								   ,[Memo]
								   ,[POPartSplitUserTypeId]
								   ,[POPartSplitUserType]
								   ,[POPartSplitUserId]
								   ,[POPartSplitUser]
								   ,[POPartSplitSiteId]
								   ,[POPartSplitSiteName]
								   ,[POPartSplitAddressId]
								   ,[POPartSplitAddress1]
								   ,[POPartSplitAddress2]
								   ,[POPartSplitAddress3]
								   ,[POPartSplitCity]
								   ,[POPartSplitState]
								   ,[POPartSplitPostalCode]
								   ,[POPartSplitCountryId]
								   ,[POPartSplitCountryName]
								   ,[MasterCompanyId]
								   ,[CreatedBy]
								   ,[UpdatedBy]
								   ,[CreatedDate]
								   ,[UpdatedDate]
								   ,[IsActive]
								   ,[IsDeleted]
								   ,[DiscountPercentValue]
								   ,[EstDeliveryDate]
								   ,[ExchangeSalesOrderId]
								   ,[ExchangeSalesOrderNo]
								   ,[ManufacturerPN]
								   ,[AssetModel]
								   ,[AssetClass]
								   ,[IsLotAssigned]
								   ,[LotId]
								   ,[WorkOrderMaterialsId]
								   ,[VendorRFQPOPartRecordId]
								   ,[TraceableTo]
								   ,[TraceableToName]
								   ,[TraceableToType]
								   ,[TagTypeId]
								   ,[TaggedBy]
								   ,[TaggedByType]
								   ,[TaggedByName]
								   ,[TaggedByTypeName]
								   ,[TagDate])
			
								   (SELECT 
									@PurchaseOrderId
								   ,tmp.ItemMasterId
								   ,tmp.PartNumber
								   ,tmp.PartDescription
								   ,tmp.AltEquiPartNumberId
								   ,tmp.AltEquiPartNumber
								   ,tmp.AltEquiPartDescription
								   ,tmp.StockType
								   ,tmp.ManufacturerId
								   ,tmp.Manufacturer
								   ,tmp.PriorityId
								   ,tmp.Priority
								   ,tmp.NeedByDate
								   ,tmp.ConditionId
								   ,tmp.Condition
								   ,split.QuantityOrdered
								   ,split.QuantityBackOrdered
								   ,tmp.QuantityRejected
								   ,tmp.VendorListPrice
								   ,tmp.DiscountPercent
								   ,tmp.DiscountPerUnit
								   ,tmp.DiscountAmount
								   ,tmp.UnitCost
								   ,(ISNULL(split.QuantityOrdered,0) * ISNULL(tmp.UnitCost,0))
								   ,tmp.FunctionalCurrencyId
								   ,tmp.FunctionalCurrency
								   ,tmp.ForeignExchangeRate
								   ,tmp.ReportCurrencyId
								   ,tmp.ReportCurrency
								   ,tmp.WorkOrderId
								   ,tmp.WorkOrderNo
								   ,tmp.SubWorkOrderId
								   ,tmp.SubWorkOrderNo
								   ,tmp.RepairOrderId
								   ,tmp.ReapairOrderNo
								   ,tmp.SalesOrderId
								   ,tmp.SalesOrderNo
								   ,tmp.ItemTypeId
								   ,tmp.ItemType
								   ,tmp.GlAccountId
								   ,tmp.GLAccount
								   ,tmp.UOMId
								   ,tmp.UnitOfMeasure
								   ,tmp.ManagementStructureId
								   ,tmp.Level1
								   ,tmp.Level2
								   ,tmp.Level3
								   ,tmp.Level4
								   ,@PurchaseOrderPartRecordId
								   ,0
								   ,tmp.Memo
								   ,split.POPartSplitUserTypeId
								   ,split.POPartSplitUserType
								   ,split.POPartSplitUserId
								   ,split.POPartSplitUser
								   ,split.POPartSplitSiteId
								   ,split.POPartSplitSiteName
								   ,split.POPartSplitAddressId
								   ,split.POPartSplitAddress1
								   ,split.POPartSplitAddress2
								   ,split.POPartSplitAddress3
								   ,split.POPartSplitCity
								   ,split.POPartSplitState
								   ,split.POPartSplitPostalCode
								   ,split.POPartSplitCountryId
								   ,split.POPartSplitCountryName
								   ,tmp.MasterCompanyId
								   ,@userName
								   ,@userName
								   ,GETUTCDATE()
								   ,GETUTCDATE()
								   ,1
								   ,0
								   ,tmp.DiscountPercentValue
								   ,tmp.EstDeliveryDate
								   ,tmp.ExchangeSalesOrderId
								   ,tmp.ExchangeSalesOrderNo
								   ,tmp.ManufacturerPN
								   ,tmp.AssetModel
								   ,tmp.AssetClass
								   ,@IsLotAssigned
								   ,@LotId
								   ,tmp.WorkOrderMaterialsId
								   ,tmp.VendorRFQPOPartRecordId
								   ,tmp.TraceableTo
								   ,tmp.TraceableToName
								   ,tmp.TraceableToType
								   ,tmp.TagTypeId
								   ,tmp.TaggedBy
								   ,tmp.TaggedByType
								   ,tmp.TaggedByName
								   ,tmp.TaggedByTypeName
								   ,tmp.TagDate
									FROM #tmpPoSplitParts split INNER JOIN  #tmpPoPartList tmp  ON split.PoPartSrNum = tmp.PoPartSrNum WHERE split.PoSplitPartSrNum = @SplitPartLoopId AND split.PoPartSrNum = @PartLoopId)

									SET @PurchaseOrderPartRecordIdSplit = SCOPE_IDENTITY();
									UPDATE #tmpPoSplitAllPartList SET PurchaseOrderPartRecordId =  @PurchaseOrderPartRecordIdSplit, ParentId = @PurchaseOrderPartRecordId, IsParent = 0 WHERE PoSplitPartSrNum = @SplitPartLoopId AND PoPartSrNum = @PartLoopId
								EXEC dbo.[PROCAddPOMSData] @PurchaseOrderPartRecordIdSplit,@ManagementStructureIdSplit,@MasterCompanyId,@userName,@userName,@ModuleId,3, 0
							 END -- END :IF : @PurchaseOrderPartRecordIdSplit,0) = 0
							 ELSE
							 BEGIN -- START :ELSE : @PurchaseOrderPartRecordIdSplit,0) = 0							  
								  IF(@SplitPartIsDeleted = 1)
								  BEGIN
									DELETE FROM DBO.PurchaseOrderApproval WHERE PurchaseOrderPartId = @PurchaseOrderPartRecordIdSplit
									DELETE FROM DBO.PurchaseOrderPart WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartRecordIdSplit
								  END
								  ELSE
								  BEGIN
									UPDATE PART
									SET PART.ItemMasterId = TMP.ItemMasterId, PART.PartNumber = TMP.PartNumber, 
										PART.PartDescription = TMP.PartDescription,PART.AltEquiPartNumberId = TMP.AltEquiPartNumberId, 
										PART.AltEquiPartNumber = TMP.AltEquiPartNumber, PART.AltEquiPartDescription = TMP.AltEquiPartDescription, 
										PART.StockType = TMP.StockType,PART.ManufacturerId = TMP.ManufacturerId,
										PART.Manufacturer = TMP.Manufacturer,PART.PriorityId = TMP.PriorityId,
										PART.[Priority] = TMP.[Priority], PART.NeedByDate = TMP.NeedByDate, 
										PART.ConditionId = TMP.ConditionId,PART.Condition = TMP.Condition,
										PART.QuantityOrdered = split.QuantityOrdered,PART.QuantityBackOrdered = split.QuantityBackOrdered,
										PART.QuantityRejected = TMP.QuantityRejected,PART.VendorListPrice = TMP.VendorListPrice,
										PART.DiscountPercent = TMP.DiscountPercent,PART.DiscountPerUnit = TMP.DiscountPerUnit,
										PART.DiscountAmount = TMP.DiscountAmount,PART.UnitCost = TMP.UnitCost,
										PART.ExtendedCost = (ISNULL(split.QuantityOrdered,0) * ISNULL(TMP.UnitCost,0)) ,PART.FunctionalCurrencyId = TMP.FunctionalCurrencyId,
										PART.FunctionalCurrency = TMP.FunctionalCurrency,PART.ForeignExchangeRate = TMP.ForeignExchangeRate,
										PART.ReportCurrencyId = TMP.ReportCurrencyId,PART.ReportCurrency = TMP.ReportCurrency,
										PART.WorkOrderId = TMP.WorkOrderId,PART.WorkOrderNo = TMP.WorkOrderNo,
										PART.SubWorkOrderId = TMP.SubWorkOrderId,PART.SubWorkOrderNo = TMP.SubWorkOrderNo,
										PART.RepairOrderId = TMP.RepairOrderId,PART.ReapairOrderNo = TMP.ReapairOrderNo,
										PART.SalesOrderId = TMP.SalesOrderId,PART.SalesOrderNo = TMP.SalesOrderNo,
										PART.ItemTypeId = TMP.ItemTypeId,PART.ItemType = TMP.ItemType,
										PART.GlAccountId = TMP.GlAccountId,PART.GLAccount = TMP.GLAccount,
										PART.UOMId = TMP.UOMId,PART.UnitOfMeasure = TMP.UnitOfMeasure,
										PART.ManagementStructureId = TMP.ManagementStructureId,
										PART.Level1 = TMP.Level1,PART.Level2 = TMP.Level2,PART.Level3 = TMP.Level3,PART.Level4 = TMP.Level4,
										PART.ParentId = @PurchaseOrderPartRecordId,PART.isParent = 0,PART.Memo = TMP.Memo,
										PART.POPartSplitUserTypeId = split.POPartSplitUserTypeId,PART.POPartSplitUserType = split.POPartSplitUserType,
										PART.POPartSplitUserId = split.POPartSplitUserId,PART.POPartSplitUser = split.POPartSplitUser,
										PART.POPartSplitSiteId = split.POPartSplitSiteId,PART.POPartSplitSiteName = split.POPartSplitSiteName,
										PART.POPartSplitAddressId = split.POPartSplitAddressId,PART.POPartSplitAddress1 = split.POPartSplitAddress1,
										PART.POPartSplitAddress2 = split.POPartSplitAddress2,PART.POPartSplitAddress3 = split.POPartSplitAddress3,
										PART.POPartSplitCity = split.POPartSplitCity,PART.POPartSplitState = split.POPartSplitState,
										PART.POPartSplitPostalCode = split.POPartSplitPostalCode,PART.POPartSplitCountryId = split.POPartSplitCountryId,
										PART.POPartSplitCountryName = split.POPartSplitCountryName,
										PART.MasterCompanyId = @masterCompanyId,PART.UpdatedBy = @userName,PART.UpdatedDate = GETUTCDATE(),
										PART.DiscountPercentValue = TMP.DiscountPercentValue,PART.EstDeliveryDate = TMP.EstDeliveryDate,
										PART.ExchangeSalesOrderId = TMP.ExchangeSalesOrderId,PART.ExchangeSalesOrderNo = TMP.ExchangeSalesOrderNo,
										PART.ManufacturerPN = TMP.ManufacturerPN,PART.AssetModel = TMP.AssetModel,
										PART.AssetClass = TMP.AssetClass,PART.IsLotAssigned = @IsLotAssigned,
										PART.LotId = @LotId,PART.WorkOrderMaterialsId = TMP.WorkOrderMaterialsId,
										PART.VendorRFQPOPartRecordId = TMP.VendorRFQPOPartRecordId,PART.TraceableTo = TMP.TraceableTo,
										PART.TraceableToName = TMP.TraceableToName,PART.TraceableToType = TMP.TraceableToType,
										PART.TagTypeId = TMP.TagTypeId,PART.TaggedBy = TMP.TaggedBy,PART.TaggedByType = TMP.TaggedByType,
										PART.TaggedByName = TMP.TaggedByName,PART.TaggedByTypeName = TMP.TaggedByTypeName,PART.TagDate = TMP.TagDate
									FROM DBO.PurchaseOrderPart PART
									JOIN #tmpPoPartList TMP							 
										ON PART.PurchaseOrderPartRecordId = TMP.PurchaseOrderPartRecordId
									JOIN #tmpPoSplitParts split ON TMP.PoPartSrNum = split.PoPartSrNum
									WHERE PART.PurchaseOrderPartRecordId = @PurchaseOrderPartRecordIdSplit

									EXEC dbo.[PROCAddPOMSData] @PurchaseOrderPartRecordIdSplit,@ManagementStructureIdSplit,@MasterCompanyId,@userName,@userName,@ModuleId,4, 0
								  END				  

							 END -- END :ELSE : @PurchaseOrderPartRecordIdSplit,0) = 0

						END							
						SET @SplitPartLoopId +=1 
					END -->>>>> End: Split Part While Loop
/* ----------------------------END:  SPLIT PART Functionality ---------------------------------- */
/* ----------------------------START:  WO Materials Update ---------------------------------- */					
					IF(@WorkOrderMaterialsId > 0)
					BEGIN
						IF((SELECT COUNT(WorkOrderMaterialsId) FROM DBO.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId) > 0)
						BEGIN
							UPDATE DBO.WorkOrderMaterials SET PONextDlvrDate = @EstDeliveryDate, 
															  ExpectedSerialNumber = @ExpectedSerialNumber,
															  POId = @PurchaseOrderId, 
															  PONum = @PurchaseOrderNumber
														  WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
						END
					END
/* ----------------------------END:  WO Materials Update ---------------------------------- */	
				SET @PartLoopId +=1
			END -->>>>> End: While Loop Main

/* ----------------------------START:  Main Part Detail ---------------------------------- */				
			SELECT * INTO #tmpMainPoPartList FROM (SELECT Top 1 * FROM #tmpPoPartList) AS partResult
			SELECT TOP 1 @MainWorkOrderMaterialsId = WorkOrderMaterialsId, @CoreDueDate =  CoreDueDate, @IsCreateExchange = ISNULL(IsCreateExchange,0) FROM #tmpMainPoPartList 
			IF(@MainWorkOrderMaterialsId > 0)
			BEGIN
				SET @ExchProvisionId = (SELECT TOP 1 ProvisionId FROM DBO.Provision WITH(NOLOCK) WHERE UPPER(StatusCode) = 'EXCHANGE' AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,0) = 1)
				IF((SELECT COUNT(WorkOrderMaterialsId) FROM DBO.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @MainWorkOrderMaterialsId AND ProvisionId = @ExchProvisionId) > 0)
				BEGIN
					EXEC dbo.[USP_CreateExchangeFromPO] 0,@PurchaseOrderId,@MainWorkOrderMaterialsId,@CoreDueDate,@IsCreateExchange
				END
			END
/* ----------------------------END:  Main Part Detail ---------------------------------- */	
			 DELETE FROM #tmpPoPartList WHERE IsDeleted = 1
			 DELETE FROM #tmpPoSplitAllPartList WHERE IsDeleted = 1

			 SELECT * FROM #tmpPoPartList
			 SELECT * FROM #tmpPoSplitAllPartList

/* ----------------------------START:  Update PO Details ---------------------------------- */				
			IF(@PurchaseOrderId >0)
			BEGIN
				EXEC sp_UpdatePurchaseOrderDetail @PurchaseOrderId
			END

		END -->>>>> End: Main Transaction 
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
	SELECT ERROR_NUMBER() AS ErrorNumber,ERROR_STATE() AS ErrorState, ERROR_SEVERITY() AS ErrorSeverity,ERROR_PROCEDURE() AS ErrorProcedure, ERROR_LINE() AS ErrorLine,ERROR_MESSAGE() AS ErrorMessage;
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SP_AddUpdatePurchaseOrderParts'             
			, @ProcedureParameters VARCHAR(3000) = '@userName = ''' + CAST(ISNULL(@userName, '') AS VARCHAR(100))+ 
			'@masterCompanyId = ''' + CAST(ISNULL(@masterCompanyId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
	END CATCH
END