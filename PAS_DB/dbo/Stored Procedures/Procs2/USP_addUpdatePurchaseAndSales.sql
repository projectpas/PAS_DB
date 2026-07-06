/*************************************************************           
 ** File:   [USP_addUpdatePurchaseAndSales]           
 ** Author:   Bhargav Saliya
 ** Description: This Sp Used For the Add Update Purchase and Sales  
 ** Purpose:         
 ** Date:   18-Nov-2025       
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date           Author		    Change Description            
 ** --   --------       -------		  --------------------------------          
    1    18-Nov-2025  Bhargav Saliya     Created
    2    06-Jul-2026  Ayushi Patel       [PN-17115]Added validation to check existing active/deleted Purchase & Sales records before update and return a message. 
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_addUpdatePurchaseAndSales]
 @ItemMasterPurchaseSaleType [PurchaseSalesType] readonly,
 @RetMessage varchar(500) OUTPUT
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SET NOCOUNT ON 
 BEGIN TRY
	DECLARE @ItemMasterId BIGINT,@MaxId BIGINT,@MinId BIGINT,@MasterCompanyId BIGINT,@ConditionId BIGINT, @PSItemMaster BIGINT,
			@PartNumber VARCHAR(50),@ItemMasterPurchaseSaleId BIGINT;

	IF OBJECT_ID(N'tempdb..#PurchaseSalesTemp') IS NOT NULL
	BEGIN
		DROP TABLE #PurchaseSalesTemp
	END

	CREATE TABLE #PurchaseSalesTemp
	(
	[ID] BIGINT NOT NULL IDENTITY,
    ItemMasterPurchaseSaleId BIGINT NULL,
    ItemMasterId BIGINT NULL,
    PartNumber NVARCHAR(200) NULL,
    ConditionId BIGINT NULL,
    PP_UOMId BIGINT NULL,
    PP_CurrencyId INT NULL,
    PP_FXRatePerc DECIMAL(18, 2) NULL,
    PP_VendorListPrice DECIMAL(18, 2) NULL,
    PP_LastListPriceDate DATETIME NULL,
    PP_PurchaseDiscPerc INT NULL,
    PP_PurchaseDiscAmount DECIMAL(18, 2) NULL,
    PP_LastPurchaseDiscDate DATETIME NULL,
    PP_UnitPurchasePrice DECIMAL(18, 2) NULL,
    SP_FSP_UOMId BIGINT NULL,
    SP_FSP_CurrencyId INT NULL,
    SP_FSP_FXRatePerc DECIMAL(18, 2) NULL,
    SP_FSP_FlatPriceAmount DECIMAL(18, 2) NULL,
    SP_FSP_LastFlatPriceDate DATETIME NULL,
    SP_CalSPByPP_MarkUpPercOnListPrice INT NULL,
    SP_CalSPByPP_MarkUpAmount DECIMAL(18, 2) NULL,
    SP_CalSPByPP_LastMarkUpDate DATETIME NULL,
    SP_CalSPByPP_BaseSalePrice DECIMAL(18, 2) NULL,
    SP_CalSPByPP_SaleDiscPerc INT NULL,
    SP_CalSPByPP_SaleDiscAmount DECIMAL(18, 2) NULL,
    SP_CalSPByPP_LastSalesDiscDate DATETIME NULL,
    SP_CalSPByPP_UnitSalePrice DECIMAL(18, 2) NULL,
    SalePriceSelectId INT NULL,
    ConditionName NVARCHAR(200) NULL,
    PP_UOMName NVARCHAR(200) NULL,
    PP_CurrencyName NVARCHAR(200) NULL,
    SP_FSP_UOMName NVARCHAR(200) NULL,
    SP_FSP_CurrencyName NVARCHAR(200) NULL,
    PP_PurchaseDiscPercValue DECIMAL(18, 2) NULL,
    SP_CalSPByPP_MarkUpPercOnListPriceValue DECIMAL(18, 2) NULL,
    SP_CalSPByPP_SaleDiscPercValue DECIMAL(18, 2) NULL,
    SalePriceSelectName NVARCHAR(200) NULL,
    ManufacturerName NVARCHAR(200) NULL,
    SP_CalSPByPP_MarkUpPercValueOnListPrice INT NULL,
    SuggestedPrice DECIMAL(18, 2) NULL,
	[MasterCompanyId] int NULL,
	[CreatedBy] varchar(256) NULL,
	[CreatedDate] DATETIME NULL,
	[UpdatedBy] varchar(256) NULL,
	[UpdatedDate] DATETIME NULL,
	[IsActive] bit NULL,
	[IsDeleted] bit NULL
	);

	INSERT INTO #PurchaseSalesTemp
	(ItemMasterPurchaseSaleId,ItemMasterId,PartNumber,ConditionId,PP_UOMId,PP_CurrencyId,
	PP_FXRatePerc,PP_VendorListPrice,PP_LastListPriceDate,PP_PurchaseDiscPerc,PP_PurchaseDiscAmount,PP_LastPurchaseDiscDate,
	PP_UnitPurchasePrice,SP_FSP_UOMId,SP_FSP_CurrencyId,SP_FSP_FXRatePerc,SP_FSP_FlatPriceAmount,SP_FSP_LastFlatPriceDate,
	SP_CalSPByPP_MarkUpPercOnListPrice,SP_CalSPByPP_MarkUpAmount,SP_CalSPByPP_LastMarkUpDate,SP_CalSPByPP_BaseSalePrice,SP_CalSPByPP_SaleDiscPerc,
	SP_CalSPByPP_SaleDiscAmount,SP_CalSPByPP_LastSalesDiscDate,SP_CalSPByPP_UnitSalePrice,SalePriceSelectId,ConditionName,PP_UOMName,
	PP_CurrencyName,SP_FSP_UOMName,SP_FSP_CurrencyName,PP_PurchaseDiscPercValue,SP_CalSPByPP_MarkUpPercOnListPriceValue,
	SP_CalSPByPP_SaleDiscPercValue,SalePriceSelectName,ManufacturerName,SP_CalSPByPP_MarkUpPercValueOnListPrice,SuggestedPrice,[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])

	SELECT ItemMasterPurchaseSaleId,ItemMasterId,PartNumber,ConditionId,PP_UOMId,PP_CurrencyId,PP_FXRatePerc,PP_VendorListPrice,
		PP_LastListPriceDate,PP_PurchaseDiscPerc,PP_PurchaseDiscAmount,PP_LastPurchaseDiscDate,PP_UnitPurchasePrice,SP_FSP_UOMId,SP_FSP_CurrencyId,
		SP_FSP_FXRatePerc,SP_FSP_FlatPriceAmount,SP_FSP_LastFlatPriceDate,SP_CalSPByPP_MarkUpPercOnListPrice,SP_CalSPByPP_MarkUpAmount,
		SP_CalSPByPP_LastMarkUpDate,SP_CalSPByPP_BaseSalePrice,SP_CalSPByPP_SaleDiscPerc,SP_CalSPByPP_SaleDiscAmount,SP_CalSPByPP_LastSalesDiscDate,
		SP_CalSPByPP_UnitSalePrice,SalePriceSelectId,ConditionName,PP_UOMName,PP_CurrencyName,SP_FSP_UOMName,SP_FSP_CurrencyName,PP_PurchaseDiscPercValue,
		SP_CalSPByPP_MarkUpPercOnListPriceValue,SP_CalSPByPP_SaleDiscPercValue,SalePriceSelectName,ManufacturerName,SP_CalSPByPP_MarkUpPercValueOnListPrice,SuggestedPrice,
		[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted]
	FROM @ItemMasterPurchaseSaleType;

	SELECT @MaxId = MAX(Id),@MinId = Min(Id) from #PurchaseSalesTemp

	WHILE @MinId <= @MaxId
	BEGIN
		
		SELECT @ItemMasterId = ItemMasterId, @MasterCompanyId = MasterCompanyId, @ConditionId = ConditionId, @ItemMasterPurchaseSaleId = ItemMasterPurchaseSaleId FROM #PurchaseSalesTemp WHERE ID = @MinId;

		IF @ItemMasterPurchaseSaleId > 0
		BEGIN

			DECLARE @ExistingIsDeleted BIT;

			SELECT TOP (1) @ExistingIsDeleted = IsDeleted FROM dbo.ItemMasterPurchaseSale WITH (NOLOCK)
			WHERE ItemMasterId = @ItemMasterId
			  AND ConditionId = @ConditionId
			  AND MasterCompanyId = @MasterCompanyId
			  AND ItemMasterPurchaseSaleId <> @ItemMasterPurchaseSaleId;

			IF @ExistingIsDeleted IS NOT NULL
			BEGIN
				IF @ExistingIsDeleted = 1
					SET @RetMessage = 'A record with this Condition already exists and is deleted. Please restore the existing record.';
				ELSE
					SET @RetMessage = 'A record with this Condition already exists.';

				RETURN;
			END

			UPDATE IMP
			SET 
				IMP.PartNumber = PST.PartNumber,
				IMP.PP_UOMId = PST.PP_UOMId,
				IMP.PP_CurrencyId = PST.PP_CurrencyId,
				IMP.PP_FXRatePerc = PST.PP_FXRatePerc,
				IMP.PP_VendorListPrice = PST.PP_VendorListPrice,
				IMP.PP_LastListPriceDate = PST.PP_LastListPriceDate,
				IMP.PP_PurchaseDiscPerc = PST.PP_PurchaseDiscPerc,
				IMP.PP_PurchaseDiscAmount = PST.PP_PurchaseDiscAmount,
				IMP.PP_LastPurchaseDiscDate = PST.PP_LastPurchaseDiscDate,
				IMP.PP_UnitPurchasePrice = PST.PP_UnitPurchasePrice,
				IMP.SP_FSP_UOMId = PST.SP_FSP_UOMId,
				IMP.SP_FSP_CurrencyId = PST.SP_FSP_CurrencyId,
				IMP.SP_FSP_FXRatePerc = PST.SP_FSP_FXRatePerc,
				IMP.SP_FSP_FlatPriceAmount = PST.SP_FSP_FlatPriceAmount,
				IMP.SP_FSP_LastFlatPriceDate = PST.SP_FSP_LastFlatPriceDate,
				
				IMP.SP_CalSPByPP_MarkUpPercOnListPrice = PST.SP_CalSPByPP_MarkUpPercOnListPrice,
				IMP.SP_CalSPByPP_MarkUpAmount = PST.SP_CalSPByPP_MarkUpAmount,
				IMP.SP_CalSPByPP_LastMarkUpDate = PST.SP_CalSPByPP_LastMarkUpDate,
				IMP.SP_CalSPByPP_BaseSalePrice = PST.SP_CalSPByPP_BaseSalePrice,
				IMP.SP_CalSPByPP_SaleDiscPerc = PST.SP_CalSPByPP_SaleDiscPerc,
				IMP.SP_CalSPByPP_SaleDiscAmount = PST.SP_CalSPByPP_SaleDiscAmount,
				IMP.SP_CalSPByPP_LastSalesDiscDate = PST.SP_CalSPByPP_LastSalesDiscDate,
				IMP.SP_CalSPByPP_UnitSalePrice = PST.SP_CalSPByPP_UnitSalePrice,
				IMP.UpdatedBy = PST.UpdatedBy,
				IMP.UpdatedDate = GETUTCDATE(),
				IMP.ConditionId = PST.ConditionId,
				IMP.SalePriceSelectId = PST.SalePriceSelectId,
				IMP.ConditionName = PST.ConditionName,
				IMP.PP_UOMName = PST.PP_UOMName,
				IMP.SP_FSP_UOMName = PST.SP_FSP_UOMName,
				IMP.PP_CurrencyName = PST.PP_CurrencyName,
				IMP.SP_FSP_CurrencyName = PST.SP_FSP_CurrencyName,
				IMP.PP_PurchaseDiscPercValue = PST.PP_PurchaseDiscPercValue,
				IMP.SP_CalSPByPP_SaleDiscPercValue = PST.SP_CalSPByPP_SaleDiscPercValue,
				IMP.SP_CalSPByPP_MarkUpPercOnListPriceValue = PST.SP_CalSPByPP_MarkUpPercOnListPriceValue,
				IMP.SalePriceSelectName = PST.SalePriceSelectName
			FROM dbo.ItemMasterPurchaseSale IMP WITH(NOLOCK)
			JOIN #PurchaseSalesTemp PST ON IMP.ItemMasterPurchaseSaleId = PST.ItemMasterPurchaseSaleId AND IMP.ItemMasterId = PST.ItemMasterId AND IMP.MasterCompanyId = PST.MasterCompanyId
			WHERE PST.Id = @MinId;
		END
		ELSE
		BEGIN
			DECLARE @Conditionname varchar(256), @CompanyName varchar(256);

			SELECT TOP 1  @Conditionname = [Description] FROM [dbo].Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId

			SELECT TOP 1  @CompanyName = [CompanyName] FROM [dbo].MasterCompany WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId

			SELECT @PSItemMaster = ItemMasterId FROM [dbo].ItemMasterPurchaseSale IMP WITH(NOLOCK) WHERE IMP.ItemMasterId = @ItemMasterId AND IMP.MasterCompanyId = @MasterCompanyId AND IMP.ConditionId = @ConditionId

			IF @PSItemMaster IS NULL
			BEGIN
				SELECT @PartNumber = I.PartNumber FROM [dbo].ItemMaster I WITH(NOLOCK) WHERE I.ItemMasterId = @ItemMasterId

				 AND ISNULL(I.IsNonStock,0) = 0
				 IF @PartNumber IS NOT NULL
				BEGIN
						UPDATE #PurchaseSalesTemp 
						SET PartNumber = @PartNumber,CreatedDate = GETUTCDATE(),UpdatedDate = GETUTCDATE()
						WHERE Id = @MinId
				END 

				INSERT INTO [dbo].ItemMasterPurchaseSale
					(ItemMasterId,PartNumber,ConditionId,PP_UOMId,PP_CurrencyId,
					PP_FXRatePerc,PP_VendorListPrice,PP_LastListPriceDate,PP_PurchaseDiscPerc,PP_PurchaseDiscAmount,PP_LastPurchaseDiscDate,
					PP_UnitPurchasePrice,SP_FSP_UOMId,SP_FSP_CurrencyId,SP_FSP_FXRatePerc,SP_FSP_FlatPriceAmount,SP_FSP_LastFlatPriceDate,
					SP_CalSPByPP_MarkUpPercOnListPrice,SP_CalSPByPP_MarkUpAmount,SP_CalSPByPP_LastMarkUpDate,SP_CalSPByPP_BaseSalePrice,SP_CalSPByPP_SaleDiscPerc,
					SP_CalSPByPP_SaleDiscAmount,SP_CalSPByPP_LastSalesDiscDate,SP_CalSPByPP_UnitSalePrice,SalePriceSelectId,ConditionName,PP_UOMName,
					PP_CurrencyName,SP_FSP_UOMName,SP_FSP_CurrencyName,PP_PurchaseDiscPercValue,SP_CalSPByPP_MarkUpPercOnListPriceValue,
					SP_CalSPByPP_SaleDiscPercValue,SalePriceSelectName,[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])

				select	ItemMasterId,PartNumber,ConditionId,PP_UOMId,PP_CurrencyId,PP_FXRatePerc,PP_VendorListPrice,
						PP_LastListPriceDate,PP_PurchaseDiscPerc,PP_PurchaseDiscAmount,PP_LastPurchaseDiscDate,PP_UnitPurchasePrice,SP_FSP_UOMId,SP_FSP_CurrencyId,
						SP_FSP_FXRatePerc,SP_FSP_FlatPriceAmount,SP_FSP_LastFlatPriceDate,SP_CalSPByPP_MarkUpPercOnListPrice,SP_CalSPByPP_MarkUpAmount,
						SP_CalSPByPP_LastMarkUpDate,SP_CalSPByPP_BaseSalePrice,SP_CalSPByPP_SaleDiscPerc,SP_CalSPByPP_SaleDiscAmount,SP_CalSPByPP_LastSalesDiscDate,
						SP_CalSPByPP_UnitSalePrice,SalePriceSelectId,ConditionName,PP_UOMName,PP_CurrencyName,SP_FSP_UOMName,SP_FSP_CurrencyName,PP_PurchaseDiscPercValue,
						SP_CalSPByPP_MarkUpPercOnListPriceValue,SP_CalSPByPP_SaleDiscPercValue,SalePriceSelectName,
						[MasterCompanyId],[CreatedBy],CreatedDate,[UpdatedBy],UpdatedDate,1,0 
			   from #PurchaseSalesTemp where Id = @MinId

			END
			ELSE
			BEGIN
				SET @RetMessage = 'Record already exists with these details PartNumber : ' + @PartNumber + 'Condition : ' + @Conditionname + 'CompanyName : ' + @CompanyName
			END
		END

		SET @MinId = @MinId + 1
	END

	SELECT TOP 1 @ItemMasterId = ItemMasterId FROM #PurchaseSalesTemp

	EXEC dbo.UpdateItemMasterPurchaseSaleDetails @ItemMasterId

 END TRY
 BEGIN CATCH  
 SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
  IF @@trancount > 0
  PRINT 'ROLLBACK'
  ROLLBACK TRAN;
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	, @AdhocComments     VARCHAR(150)    = 'USP_addUpdatePurchaseAndSales' 
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ''
	, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

  exec spLogException 
		@DatabaseName           =  @DatabaseName
		, @AdhocComments          =  @AdhocComments
		, @ProcedureParameters	   =  @ProcedureParameters
		, @ApplicationName        =  @ApplicationName
		, @ErrorLogID             =  @ErrorLogID OUTPUT ;
  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
  RETURN(1);
 END CATCH
END