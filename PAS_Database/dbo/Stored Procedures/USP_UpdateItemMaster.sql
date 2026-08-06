/*************************************************************           
** File:  [USP_UpdateItemMaster]
** Author:   Bhargav Saliya
** Description: this Store Procedural used to Update Item Master
** Purpose:  
** Date:   19-Nov-2025 
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author				Change Description            
** --    --------     -------				-------------------------------          
** 1     19-Nov-2025   Bhargav Saliya		Created  
** 2     09-Mar-2026   Vishal Suthar		Handled UnitOfMeasureId to have NULL instead of 0 which will throw foreignkey constraint
** 3     26-Mar-2026   Sahdev Saliya		Added [LifeLimitedPart] :-([IsFlightHoursAvailable], [IsFlightCyclesAvailable], [IsLandingsAvailable], [IsStartsAvailable], [IsCalendarTimeAvailable], [FlightHours], [FlightMinutes], [FlightCycles], [Landings], [Starts], [CalendarDate]) (PN-15833)
** 4     03-Apr-2026   Sahdev Saliya		Remove LifeLimitedPart (PN-15833)
** 5     07-May-2026   Divyesh Kathiriya    Update "IsTimeLife" in stockline table based on ItemMaster Id. [PN-16327]
** 6     27-May-2026   Sahdev Saliya        Added Model [PN-16353]
** 7     16-June-2026  Rajesh Gami			Update the Stockline's UOM fields While ItemMaster Update that particular UOM fields [PN-16878]
** 8	 01-July-2026  Ayushi Patel         passed updatedby into USP_UpdateStocklineUOMByItemMasterId [PN-17083]
** 9	 19-Jun-2026   Moin Bloch           Fixed for Error Log PN-16924
   10	01/July/2026	RAJESH GAMI		[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
** 11    03-Aug-2026   Sahdev Saliya        Added IsKitAssy [PN-17371]

**************************************************************/
create     PROCEDURE [dbo].[USP_UpdateItemMaster]
    @tbl_ItemMasterUpdateType [TBL_ItemMasterUpdateType] readonly,
    @tbl_BigInt [TVP_BigInt] readonly,
	@Id BIGINT,
	@RetMessage VARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	SET @RetMessage = '';
	DECLARE @imItemMasterId BIGINT ,@imManufacturerId BIGINT,@imPartNumber VARCHAR(256),@MasterCompanyId INT, @AccountingModuleId BIGINT;
	--MasterParts TABLE variables Declaration--
	DECLARE @mItemMasterId BIGINT,@MasterPartId BIGINT,@PartDescription VARCHAR(256),@PartNumber VARCHAR(256),@ManufacturerId BIGINT,@QuickBooksReferenceId VARCHAR(200),@IntegrationTypeId INT,
			@mMasterCompanyId BIGINT,@CreatedBy VARCHAR(200),@UpdatedBy VARCHAR(200),@CreatedDate DATETIME2,@IsActive BIT,@IsDeleted BIT;

	SELECT @MasterCompanyId = MasterCompanyId,@imManufacturerId = ManufacturerId,@imPartNumber = PartNumber FROM @tbl_ItemMasterUpdateType tempTbl where  tempTbl.ItemMasterId = @Id

	SELECT @AccountingModuleId = AccountingModuleId FROM dbo.AccountingModule WITH(NOLOCK) WHERE AccountingModuleName = 'ItemMaster' 

	SELECT	@mItemMasterId = ItemMasterId,@MasterPartId = MasterPartId,@PartDescription = PartDescription, @QuickBooksReferenceId = [QuickBooksReferenceId], @IntegrationTypeId = [IntegrationTypeId],
			@PartNumber = PartNumber,@ManufacturerId = ManufacturerId,@mMasterCompanyId = MasterCompanyId,@CreatedBy = CreatedBy,
			@UpdatedBy = UpdatedBy,@CreatedDate = CreatedDate,@IsActive = IsActive,@IsDeleted = IsDeleted
	FROM [dbo].ItemMaster WITH(NOLOCK) WHERE ItemMasterId = @Id

	SELECT TOP 1 @imItemMasterId = i.ItemMasterId FROM [dbo].ItemMaster i WITH(NOLOCK) 
	WHERE i.ManufacturerId = @imManufacturerId AND i.PartNumber = @imPartNumber AND i.MasterCompanyId = @MasterCompanyId AND i.ItemMasterId <> @Id

	IF @imItemMasterId IS NOT NULL
	BEGIN
	  SET @RetMessage = 'Duplicate PN for the same manufacturer is not allowed'
	END
	ELSE
	BEGIN
		/******** Check any of UOM fields modified or not in the ItemMaster **********/
		DECLARE @IsUOMEdited BIT = 0,
        @IsPOUOMEdited BIT = 0,
        @IsStockUOMEdited BIT = 0,
        @IsConsumeUOMEdited BIT = 0,
		@ExistingPOUOMId BIGINT = 0,@ExistingConsumeUOMId BIGINT = 0,@ExistingStockUOMId BIGINT =0;
			SELECT
			@ExistingPOUOMId = i.PurchaseUnitOfMeasureId,
			@ExistingConsumeUOMId =i.ConsumeUnitOfMeasureId,
			@ExistingStockUOMId = i.StockUnitOfMeasureId,
				@IsPOUOMEdited =
					CASE
						WHEN ISNULL(i.PurchaseUnitOfMeasureId, 0)
							 <> ISNULL(NULLIF(PST.PurchaseUnitOfMeasureId, 0), 0)
						THEN 1 ELSE 0
					END,

				@IsStockUOMEdited =
					CASE
						WHEN ISNULL(i.StockUnitOfMeasureId, 0)
							 <> ISNULL(NULLIF(PST.StockUnitOfMeasureId, 0), 0)
						THEN 1 ELSE 0
					END,

				@IsConsumeUOMEdited =
					CASE
						WHEN ISNULL(i.ConsumeUnitOfMeasureId, 0)
							 <> ISNULL(NULLIF(PST.ConsumeUnitOfMeasureId, 0), 0)
						THEN 1 ELSE 0
					END,

				@IsUOMEdited =
					CASE
						WHEN ISNULL(i.PurchaseUnitOfMeasureId, 0)
							 <> ISNULL(NULLIF(PST.PurchaseUnitOfMeasureId, 0), 0)
						  OR ISNULL(i.StockUnitOfMeasureId, 0)
							 <> ISNULL(NULLIF(PST.StockUnitOfMeasureId, 0), 0)
						  OR ISNULL(i.ConsumeUnitOfMeasureId, 0)
							 <> ISNULL(NULLIF(PST.ConsumeUnitOfMeasureId, 0), 0)
						THEN 1 ELSE 0
					END
			FROM dbo.ItemMaster i
			JOIN @tbl_ItemMasterUpdateType PST
				ON i.ItemMasterId = PST.ItemMasterId
				AND i.MasterCompanyId = PST.MasterCompanyId
			WHERE i.ItemMasterId = @Id;

		UPDATE i
		SET 
		i.PartAlternatePartId = PST.PartAlternatePartId
		,i.ItemGroupId = CASE WHEN PST.ItemGroupId = 0 THEN NULL ELSE PST.ItemGroupId END
		,i.ItemClassificationId = PST.ItemClassificationId
		,i.IsHazardousMaterial = PST.IsHazardousMaterial
		,i.IsExpirationDateAvailable = PST.IsExpirationDateAvailable
		,i.ExpirationDate = PST.ExpirationDate
		,i.IsReceivedDateAvailable = PST.IsReceivedDateAvailable
		,i.DaysReceived = PST.DaysReceived
		,i.IsManufacturingDateAvailable = PST.IsManufacturingDateAvailable
		,i.ManufacturingDays = PST.ManufacturingDays
		,i.IsTagDateAvailable = PST.IsTagDateAvailable
		,i.TagDays = PST.TagDays
		,i.IsOpenDateAvailable = PST.IsOpenDateAvailable
		,i.OpenDays = PST.OpenDays
		,i.IsShippedDateAvailable = PST.IsShippedDateAvailable
		,i.ShippedDays = PST.ShippedDays
		,i.IsOtherDateAvailable = PST.IsOtherDateAvailable
		,i.OtherDays = PST.OtherDays
		,i.ManufacturerId = PST.ManufacturerId
		,i.IsDER = PST.IsDER
		,i.NationalStockNumber = PST.NationalStockNumber
		,i.IsSchematic = PST.IsSchematic
		,i.OverhaulHours = PST.OverhaulHours
		,i.RPHours = PST.RPHours
		,i.TestHours = PST.TestHours
		,i.RFQTracking = PST.RFQTracking
		,i.GLAccountId = PST.GLAccountId
		,i.PurchaseUnitOfMeasureId = CASE WHEN PST.PurchaseUnitOfMeasureId = 0 THEN NULL ELSE PST.PurchaseUnitOfMeasureId END
		,i.StockUnitOfMeasureId = CASE WHEN PST.StockUnitOfMeasureId = 0 THEN NULL ELSE PST.StockUnitOfMeasureId END
		,i.ConsumeUnitOfMeasureId = CASE WHEN PST.ConsumeUnitOfMeasureId = 0 THEN NULL ELSE PST.ConsumeUnitOfMeasureId END
		,i.LeadTimeDays = PST.LeadTimeDays
		,i.ReorderPoint = PST.ReorderPoint
		,i.ReorderQuantiy = PST.ReorderQuantiy
		,i.MinimumOrderQuantity = PST.MinimumOrderQuantity
		,i.PriorityId = PST.PriorityId
		,i.Memo = PST.Memo
		,i.PurchaseCurrencyId = PST.PurchaseCurrencyId
		,i.SalesCurrencyId = PST.SalesCurrencyId
		,i.SalesLastSalePriceDate = PST.SalesLastSalePriceDate
		,i.SalesLastSalesDiscountPercentDate = PST.SalesLastSalesDiscountPercentDate
		,i.MasterCompanyId = PST.MasterCompanyId
		,i.UpdatedBy = PST.UpdatedBy
		,i.UpdatedDate = GETUTCDATE()
		,i.TurnTimeOverhaulHours = PST.TurnTimeOverhaulHours
		,i.TurnTimeRepairHours = PST.TurnTimeRepairHours
		,i.PartNumber = PST.PartNumber
		,i.PartDescription = PST.PartDescription
		,i.IsTimeLife = PST.IsTimeLife
		,i.IsSerialized = PST.IsSerialized
		,i.ShelfLife = PST.ShelfLife
		,i.StockLevel = PST.StockLevel
		,i.ShelfLifeAvailable = PST.ShelfLifeAvailable
		,i.mfgHours = PST.mfgHours
		,i.IsPma = PST.IsPma
		,i.turnTimeMfg = PST.turnTimeMfg
		,i.turnTimeBenchTest = PST.turnTimeBenchTest
		,i.IsOemPNId = PST.IsOemPNId
		,i.RepairUnitOfMeasureId = CASE WHEN PST.RepairUnitOfMeasureId = 0 THEN NULL ELSE PST.RepairUnitOfMeasureId END
		,i.RevisedPartId = PST.RevisedPartId
		,i.SiteId = PST.SiteId
		,i.WarehouseId = PST.WarehouseId
		,i.LocationId = PST.LocationId
		,i.ShelfId = PST.ShelfId
		,i.BinId = PST.BinId
		,i.ItemMasterAssetTypeId = PST.ItemMasterAssetTypeId
		,i.IsHotItem = PST.IsHotItem
		,i.IsOEM = PST.IsOEM
		,i.RevisedPart = PST.RevisedPart
		,i.OEMPN = PST.OEMPN
		,i.ItemClassificationName = PST.ItemClassificationName
		,i.ItemGroup = PST.ItemGroup
		,i.AssetAcquistionType = PST.AssetAcquistionType
		,i.ManufacturerName = PST.ManufacturerName
		,i.PurchaseUnitOfMeasure = PST.PurchaseUnitOfMeasure
		,i.StockUnitOfMeasure = PST.StockUnitOfMeasure
		,i.ConsumeUnitOfMeasure = PST.ConsumeUnitOfMeasure
		,i.PurchaseCurrency = PST.PurchaseCurrency
		,i.SalesCurrency = PST.SalesCurrency
		,i.GLAccount = PST.GLAccount
		,i.Priority = PST.Priority
		,i.SiteName = PST.SiteName
		,i.WarehouseName = PST.WarehouseName
		,i.LocationName = PST.LocationName
		,i.ShelfName = PST.ShelfName
		,i.BinName = PST.BinName
		,i.CurrentStlNo = PST.CurrentStlNo
		,i.MTBUR = PST.MTBUR
		,i.NE = PST.NE
		,i.NS = PST.NS
		,i.OH = PST.OH
		,i.REP = PST.REP
		,i.SVC = PST.SVC
		,i.Figure = PST.Figure
		,i.Item = PST.Item
		,i.UNCode = PST.UNCode
		,i.InventoryGLSettingId = PST.InventoryGLSettingId
		,i.GoodsReceivedNotInvoicesGLAccId = PST.GoodsReceivedNotInvoicesGLAccId
		,i.WorkInProgressGLAccId = PST.WorkInProgressGLAccId
		,i.InventoryToBillGLAccId = PST.InventoryToBillGLAccId
		,i.FinishedGoodsGLAccId = PST.FinishedGoodsGLAccId
		,i.InventoryExchAgreementGLAccId = PST.InventoryExchAgreementGLAccId
		,i.InventoryReserveGLAccId = PST.InventoryReserveGLAccId
		,i.COGS_WorkOrderGLAccId = PST.COGS_WorkOrderGLAccId
		,i.COGS_SalesOrderGLAccId = PST.COGS_SalesOrderGLAccId
		,i.COGS_QtyVarianceGLAccId = PST.COGS_QtyVarianceGLAccId
		,i.COGS_UnitCostVarianceGLAccId = PST.COGS_UnitCostVarianceGLAccId
		,i.RevenueMroGLAccId = PST.RevenueMroGLAccId
		,i.RevenueSoGLAccId = PST.RevenueSoGLAccId
		,i.RevenueExchGLAccId = PST.RevenueExchGLAccId
		,i.COGS_ExchSalesOrderGLAccId = PST.COGS_ExchSalesOrderGLAccId
		,i.GoodsReceivedNotInvoicesGLAccName = PST.GoodsReceivedNotInvoicesGLAccName
		,i.WorkInProgressGLAccName = PST.WorkInProgressGLAccName
		,i.InventoryToBillGLAccName = PST.InventoryToBillGLAccName
		,i.FinishedGoodsGLAccName = PST.FinishedGoodsGLAccName
		,i.InventoryExchAgreementGLAccName = PST.InventoryExchAgreementGLAccName
		,i.InventoryReserveGLAccName = PST.InventoryReserveGLAccName
		,i.COGS_WorkOrderGLAccName = PST.COGS_WorkOrderGLAccName
		,i.COGS_SalesOrderGLAccName = PST.COGS_SalesOrderGLAccName
		,i.COGS_QtyVarianceGLAccName = PST.COGS_QtyVarianceGLAccName
		,i.COGS_UnitCostVarianceGLAccName = PST.COGS_UnitCostVarianceGLAccName
		,i.RevenueMroGLAccName = PST.RevenueMroGLAccName
		,i.RevenueSoGLAccName = PST.RevenueSoGLAccName
		,i.RevenueExchGLAccName = PST.RevenueExchGLAccName
		,i.COGS_ExchSalesOrderGLAccName = PST.COGS_ExchSalesOrderGLAccName
		,i.IsUpdated = 1
		,i.WorkOrderFormTypeId = PST.WorkOrderFormTypeId
		,i.IsFlightHoursAvailable = PST.IsFlightHoursAvailable
		,i.IsFlightCyclesAvailable = PST.IsFlightCyclesAvailable
		,i.IsLandingsAvailable = PST.IsLandingsAvailable
		,i.IsStartsAvailable = PST.IsStartsAvailable
		,i.IsCalendarTimeAvailable = PST.IsCalendarTimeAvailable
		,i.FlightHours = PST.FlightHours
		,i.FlightMinutes = PST.FlightMinutes
		,i.FlightCycles = PST.FlightCycles
		,i.Landings = PST.Landings
		,i.Starts = PST.Starts
		,i.CalendarDate = PST.CalendarDate
		
		,i.IsAcquiredMethodBuy              = PST.IsAcquiredMethodBuy
		,i.DiscountPurchasePercent          = PST.DiscountPurchasePercent
		,i.UnitCost                         = PST.UnitCost
		,i.ListPrice                        = PST.ListPrice
		,i.PriceDate                        = PST.PriceDate
		,i.InWarranty                       = PST.InWarranty
		,i.MfgExpirationDate                = PST.MfgExpirationDate
		,i.IsMfgExpirationDate              = PST.IsMfgExpirationDate
		,i.IsService						= ISNULL(PST.IsService, 0)
		FROM dbo.ItemMaster i WITH(NOLOCK)
		JOIN @tbl_ItemMasterUpdateType PST ON i.ItemMasterId = PST.ItemMasterId AND i.MasterCompanyId = PST.MasterCompanyId
		WHERE i.ItemMasterId = @Id;

		--Deleted Ranking If existst
		DELETE dbo.ItemMasterRanking WHERE ItemMasterId = @Id

		IF (SELECT COUNT(1) FROM @tbl_BigInt) > 0
		BEGIN
			INSERT INTO dbo.ItemMasterRanking 
			(RankingId,ItemMasterId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted)
			SELECT Value,@Id,@MasterCompanyId,@CreatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0 
			FROM @tbl_BigInt;
		END

		UPDATE MP
		SET MP.[Description] = @PartDescription,
			MP.[PartNumber] = @PartNumber,
			MP.[ManufacturerId] = @ManufacturerId,
			MP.[CreatedBy] = @CreatedBy,
			MP.[UpdatedBy] = @UpdatedBy,
			MP.[CreatedDate] = @CreatedDate,
			MP.[IsActive] = @IsActive,
			MP.[IsDeleted] = @IsDeleted,
			MP.[UpdatedDate] = GETUTCDATE()
		FROM dbo.MasterParts MP WITH(NOLOCK)
		WHERE MP.MasterPartId = @MasterPartId AND MP.[MasterCompanyId] = @mMasterCompanyId	
		PRINT @IsUOMEdited
		PRINT '>>@IsUOMEdited = 1'
		IF(@IsUOMEdited = 1)
		BEGIN
		PRINT '@IsUOMEdited = 1'
			   DECLARE @PurchaseUnitOfMeasureId  BIGINT,
                    @StockUnitOfMeasureId     BIGINT,
                    @ConsumeUnitOfMeasureId   BIGINT,@IsStkTimeLife BIT;
				SELECT TOP 1 @PurchaseUnitOfMeasureId = PurchaseUnitOfMeasureId, @StockUnitOfMeasureId = StockUnitOfMeasureId,@ConsumeUnitOfMeasureId = ConsumeUnitOfMeasureId, @IsStkTimeLife = IsTimeLife  FROM @tbl_ItemMasterUpdateType
				PRINT @PurchaseUnitOfMeasureId
				PRINT @StockUnitOfMeasureId
				PRINT @ConsumeUnitOfMeasureId
				EXEC [dbo].[USP_UpdateStocklineUOMByItemMasterId] @Id ,@MasterCompanyId,@PurchaseUnitOfMeasureId,@StockUnitOfMeasureId,@ConsumeUnitOfMeasureId,@IsPOUOMEdited,@IsStockUOMEdited,@IsConsumeUOMEdited,@ExistingPOUOMId,@ExistingStockUOMId,@ExistingConsumeUOMId,@IsStkTimeLife,@UpdatedBy
		END
		ELSE
		BEGIN
			UPDATE [dbo].[Stockline]
			SET [IsStkTimeLife] = IM.[IsTimeLife]
			FROM [dbo].[Stockline] sl
			INNER JOIN @tbl_ItemMasterUpdateType IM ON sl.[ItemMasterId] = IM.[ItemMasterId]
			WHERE sl.[ItemMasterId] = @Id;
		END
		

		EXEC dbo.UpdateItemMasterDetail @Id

		--EXEC [dbo].[QuickBooks_UpdateModuleCountDetails] @MasterCompanyId, @AccountingModuleId

	END
	SELECT @MasterPartId AS [MasterPartId],@QuickBooksReferenceId AS [QuickBooksReferenceId], @IntegrationTypeId AS [IntegrationTypeId]
  COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
  ROLLBACK TRANSACTION
    SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_UpdateItemMaster]',
            @ProcedureParameters varchar(3000) = '@ItemMasterId = ''' + CAST(ISNULL(@Id, 0) AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END