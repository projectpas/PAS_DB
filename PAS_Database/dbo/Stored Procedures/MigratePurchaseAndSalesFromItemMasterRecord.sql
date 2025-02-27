/*************************************************************             
 ** File:   [MigratePurchaseAndSalesFromItemMasterRecord]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate Item Master Records
 ** Purpose:           
 ** Date:   24/02/2025

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    24/02/2025   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigratePurchaseAndSalesFromItemMasterRecord @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=20,@UserName=N'ADMIN ADMIN',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigratePurchaseAndSalesFromItemMasterRecord]
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
			[Migrated_Id] BIGINT NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL
		)

		INSERT INTO #TempItemMaster ([ItemMasterId],[CurrencyId],[ItemGroupId],[ItemClassificationId],[ManufacturerId],[UnitOfMeasureId],[PartNumber],[PartDescription],
		[Hazard_Material],[DER_Flag],[Reorder_Cond_Level],[MinimumOrderQuantity],[PartListPrice],[NotesAdded],[IsActive],[Date_Created],[IsTimeLife],[IsSerialized],
		[Shelf_Life],[List_Price_Date],[ECC_Number],[ITAR_Number],[Shelf_Life_Days],[PMA_Flag],[Procurement],[IsHOTPart],[LeadDays],[SalesPrice],[Alert],[UOM],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT [ItemMasterId],[CurrencyId],[ItemGroupId],[ItemClassificationId],[ManufacturerId],[UnitOfMeasureId],[PartNumber],[PartDescription],
		[Hazard_Material],[DER_Flag],[Reorder_Cond_Level],[MinimumOrderQuantity],[PartListPrice],[NotesAdded],[IsActive],[Date_Created],[IsTimeLife],[IsSerialized],
		[Shelf_Life],[List_Price_Date],[ECC_Number],[ITAR_Number],[Shelf_Life_Days],[PMA_Flag],[Procurement],[IsHOTPart],[LeadDays],[SalesPrice],[Alert],[UOM],[Migrated_Id],[SuccessMsg],[ErrorMsg] 
		FROM [Quantum_Staging].dbo.ItemMasters IM WITH (NOLOCK) WHERE IM.MasterCompanyId = @FromMasterComanyID
		AND Migrated_Id IS NOT NULL;

		IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCodePrefixes
		END
      
		CREATE TABLE #tmpCodePrefixes  
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

		INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)   
		SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
		FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId  
		WHERE CT.CodeTypeId IN (30,17,9) AND CP.MasterCompanyId = @FromMasterComanyID AND CP.IsActive = 1 AND CP.IsDeleted = 0;

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

				SELECT @MigratedId = Migrated_Id, @ManufacturerId = ManufacturerId, @OnHandQty = 0, @ConditionId = 298, @UnitCost = 0, @SalePrice = 0, @LastOrderedDate = GETDATE(),
				@GLAccountId = 2395, @ManagementStructureId = 38, @LegalEntityId = 33, @SiteId = 25, @QtyReserved = 0, @QtyIssued = 0, @QtyOnOrder = 0, @VendorId = NULL, @Condition = 'NE',
				@CustomerId = NULL, @EntityStructureId = 38
				FROM #TempItemMaster WHERE ID = @LoopID;

				IF NOT EXISTS (SELECT * FROM DBO.ItemMasterPurchaseSale IMPS WHERE IMPS.ItemMasterId = @MigratedId AND IMPS.MasterCompanyId = @FromMasterComanyID)
				BEGIN
					INSERT INTO DBO.ItemMasterPurchaseSale
					([ItemMasterId],[PartNumber],[PP_UOMId],[PP_CurrencyId],[PP_FXRatePerc],[PP_VendorListPrice],[PP_LastListPriceDate],[PP_PurchaseDiscPerc],[PP_PurchaseDiscAmount],
					[PP_LastPurchaseDiscDate],[PP_UnitPurchasePrice],[SP_FSP_UOMId],[SP_FSP_CurrencyId],[SP_FSP_FXRatePerc],[SP_FSP_FlatPriceAmount],[SP_FSP_LastFlatPriceDate],
					[SP_CalSPByPP_MarkUpPercOnListPrice],[SP_CalSPByPP_MarkUpAmount],[SP_CalSPByPP_LastMarkUpDate],[SP_CalSPByPP_BaseSalePrice],[SP_CalSPByPP_SaleDiscPerc],[SP_CalSPByPP_SaleDiscAmount],
					[SP_CalSPByPP_LastSalesDiscDate],[SP_CalSPByPP_UnitSalePrice],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
					[ConditionId],[SalePriceSelectId],[ConditionName],[PP_UOMName],[SP_FSP_UOMName],[PP_CurrencyName],[SP_FSP_CurrencyName],[PP_PurchaseDiscPercValue],
					[SP_CalSPByPP_SaleDiscPercValue],[SP_CalSPByPP_MarkUpPercOnListPriceValue],[SalePriceSelectName])

					SELECT @MigratedId,PartNumber,UnitOfMeasureId,CurrencyId,1,PartListPrice,GETDATE(),NULL,0,
					GETDATE(),SalesPrice,UnitOfMeasureId,CurrencyId,1,SalesPrice,GETDATE(),
					0,0,NULL,0,0,0,
					NULL,SalesPrice,@FromMasterComanyID,@UserName,@UserName,GETDATE(),GETDATE(),1,0,
					@ConditionId,1,NULL,NULL,NULL,NULL,NULL,NULL,
					NULL,NULL,'Flat'
					FROM #TempItemMaster AS ST WHERE ID = @LoopID;

					SET @InsertedStocklineId = SCOPE_IDENTITY();

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