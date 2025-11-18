/*************************************************************           
** File:  [USP_GetItemMasterPurchaseSale]
** Author:   Bhargav Saliya
** Description: this Store Procedural used to get Purchase Sale Data
** Purpose:  
** Date:   27-Oct-2025 
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author           Change Description            
** --    --------     -------           -------------------------------          
** 1     27-Oct-2025   Bhargav Saliya      Created  

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetItemMasterPurchaseSale]
    @ItemMasterId BIGINT,
	@EmployeeId BIGINT = 0
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
    DECLARE @TotalRecord int = 0;   
	DECLARE @MinId BIGINT = 1;
	DECLARE @MasterCompanyId BIGINT; 
	DECLARE @PartNumber VARCHAR(200) =NULL;
	DECLARE	@RecordsTotalSOQ INT = 0,@UnitSalesPriceTotalSOQ DECIMAL(18,2) = 0,@PerUnitPriceSOQ DECIMAL(18,2) = 0
	DECLARE @AvgHistoricalSOQCode VARCHAR(50)  = 'Avg Historical SOQ';
	DECLARE @Status_Code VARCHAR(100) = 'Rejected,Cancelled';
	DECLARE @AvgHistoricalSOCode VARCHAR(50)  = 'Avg Historical SO';
	DECLARE @CostPlusPrice DECIMAL(18,2) = 0,@RecommendedPrice DECIMAL(18,2) = 0
	DECLARE @PurchasePriceCode VARCHAR(50)  = 'Purchase Price + Mark up';
	DECLARE @VendorQuoteCode VARCHAR(50)  = 'Purchase Quote + Mark Up';

	SELECT TOP 1 @PartNumber = PartNumber,@MasterCompanyId = MasterCompanyId FROM DBO.ItemMaster I WITH(NOLOCK)
	WHERE I.ItemMasterId = @ItemMasterId

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId;

	IF OBJECT_ID(N'tempdb..#tmpRFQHistoryResult') IS NOT NULL
	BEGIN
		DROP TABLE #tmpRFQHistoryResult
	END

	CREATE TABLE #tmpRFQHistoryResult
	(
		[ID] BIGINT NOT NULL IDENTITY, 
		[PartNumber] VARCHAR(50) NULL,
		[Condition] VARCHAR(50) NULL,
		[PurchaseSalePrice] DECIMAL(18,2) NULL,		
		[SOUnitPrice] DECIMAL(18,2) NULL,
		[SOQUnitPrice] DECIMAL(18,2) NULL,
		[IlsPrice] DECIMAL(18,2) NULL,		
        [MarkUpPercentValue] DECIMAL(18,2) NULL,
		[CostPlusPrice] DECIMAL(18,2) NULL,
		[RecommendedPrice] DECIMAL(18,2) NULL,
		[POUnitPrice] DECIMAL(18,2) NULL,
		[POMarkUpPercentValue] DECIMAL(18,2) NULL,
		[POUnitPriceCostPlus] DECIMAL(18,2) NULL,
		[POPricePercentId] BIGINT NULL,
		[POQuotePercentId] BIGINT NULL,
	)

	IF OBJECT_ID(N'tempdb..#tmpRFQConditionResult') IS NOT NULL
	BEGIN
		DROP TABLE #tmpRFQConditionResult
	END

	CREATE TABLE #tmpRFQConditionResult
	(
		[ID] BIGINT NOT NULL IDENTITY, 
		[Condition] VARCHAR(20) NULL,
		[ConditionId] BIGINT NULL		
	)

	INSERT INTO #tmpRFQConditionResult ([Condition], [ConditionId])
		SELECT [Description], ConditionId
		FROM dbo.Condition WITH (NOLOCK)
		WHERE MasterCompanyId = @MasterCompanyId;

	SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmpRFQConditionResult 

	WHILE @MinId <= @TotalRecord
	BEGIN
		DECLARE @NewConditionId BIGINT=0,@Code VARCHAR(20)=''

		SELECT @NewConditionId = [ConditionId],
			   @Code = [Condition]	    
		FROM #tmpRFQConditionResult WHERE [ID] = @MinId

		------------------------------SOQ------------------------------ 

		DECLARE @SOQSettingYearId BIGINT, @SOQSettingMonthId BIGINT, @SOQSettingDays INT;

		SELECT @SOQSettingYearId = ISNULL([YearId], 0), @SOQSettingMonthId = ISNULL([MonthId], 0), @SOQSettingDays = ISNULL([Days], 0) FROM [dbo].[AIAutoQouteSetting] WITH(NOLOCK) WHERE [Code] = @AvgHistoricalSOQCode AND [MasterCompanyId] = @MasterCompanyId;

		SELECT	@RecordsTotalSOQ = COUNT(SOPC.SalesOrderQuotePartId), 
				@UnitSalesPriceTotalSOQ = ISNULL(SUM(SOPC.UnitSalesPrice),0)
		FROM [dbo].[SalesOrderQuotePartV1] SQP WITH(NOLOCK)
		INNER JOIN [dbo].[SalesOrderQuotePartCost] SOPC WITH(NOLOCK) ON SQP.[SalesOrderQuotePartId] = SOPC.[SalesOrderQuotePartId]
		INNER JOIN [dbo].[SalesOrderQuote] SQ WITH(NOLOCK) ON SQP.[SalesOrderQuoteId] = SQ.[SalesOrderQuoteId]
		INNER JOIN [dbo].[MasterSalesOrderQuoteStatus] SQS WITH(NOLOCK) ON SQ.[StatusId] = SQS.[Id]
		WHERE SQP.[ItemMasterId] = @ItemMasterId
		  AND SQP.[ConditionId] = @NewConditionId   
		  AND CAST(SQ.[OpenDate] AS DATE) BETWEEN DATEADD(DAY, -@SOQSettingDays, CAST(GETUTCDATE() AS DATE)) AND CAST(GETUTCDATE() AS DATE)
		  AND SQS.[Name] NOT IN (SELECT item FROM SplitString(@Status_Code,','))
		  AND SQP.[MasterCompanyId] = @MasterCompanyId;				
		  IF(@RecordsTotalSOQ > 0)
		  BEGIN
	  		SET @PerUnitPriceSOQ  = ISNULL((@UnitSalesPriceTotalSOQ / @RecordsTotalSOQ),0);
	  		--Check if PercentValue selected or not
	  		--IF(@MarkUpPercentValue > 0)
	  		--BEGIN
	  		--	SET @FinalUnitPriceSOQ  = (@PerUnitPriceSOQ * @MarkUpPercentValue) / 100;
	  		--	SET @PerUnitPriceSOQ = @PerUnitPriceSOQ + ISNULL(@FinalUnitPriceSOQ,0);
	  		--END
		  END

		------------------------------SO------------------------------

		DECLARE	@RecordsTotalSO INT = 0,@PerUnitPriceSO DECIMAL(18,2) = 0,@FinalUnitPriceSO DECIMAL(18,2) = 0,@UnitSalesPriceTotalSO DECIMAL(18,2) = 0;
		DECLARE @SOSettingYearId BIGINT, @SOSettingMonthId BIGINT, @SOSettingDays INT;

		SELECT @SOSettingYearId = [YearId], @SOSettingMonthId = [MonthId], @SOSettingDays = ISNULL([Days], 0) FROM [dbo].[AIAutoQouteSetting] WITH(NOLOCK) WHERE [Code] = @AvgHistoricalSOCode AND [MasterCompanyId] = @MasterCompanyId;

		SELECT	@RecordsTotalSO = COUNT(SOPC.SalesOrderPartId), 
				@UnitSalesPriceTotalSO = ISNULL(SUM(SOPC.UnitSalesPrice),0)
		FROM [dbo].[SalesOrderPartV1] SP WITH(NOLOCK)
		INNER JOIN [dbo].[SalesOrderPartCost] SOPC WITH(NOLOCK) ON SP.[SalesOrderPartId] = SOPC.[SalesOrderPartId]
		INNER JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON SP.[SalesOrderId] = SO.[SalesOrderId]
		INNER JOIN [dbo].[MasterSalesOrderStatus] SOS WITH(NOLOCK) ON SO.[StatusId] = SOS.[Id]
		WHERE SP.[ItemMasterId] = @ItemMasterId
		  AND SP.[ConditionId] = @NewConditionId   
		  AND CAST(SO.[OpenDate] AS DATE) BETWEEN DATEADD(DAY, -@SOSettingDays, CAST(GETUTCDATE() AS DATE)) AND CAST(GETUTCDATE() AS DATE)
		  AND SOS.[Name] NOT IN (SELECT item FROM SplitString(@Status_Code,','))
		  AND SP.[MasterCompanyId] = @MasterCompanyId;	
		  
		  IF(@RecordsTotalSO > 0)
		  BEGIN
	  		SET @PerUnitPriceSO  = ISNULL((@UnitSalesPriceTotalSO / @RecordsTotalSO),0);
	  		--Check if PercentValue selected or not
	  		--IF(@MarkUpPercentValue > 0)
	  		--BEGIN
	  		--	SET @FinalUnitPriceSO  = (@PerUnitPriceSO * @MarkUpPercentValue) / 100;
	  		--	SET @PerUnitPriceSO = @PerUnitPriceSO + ISNULL(@FinalUnitPriceSO,0);
	  		--END
		  END
	  
		------------------------------Purchase And Sale------------------------------ 

		DECLARE @RecordsTotalPS INT = 0,@PerUnitPricePS DECIMAL(18,2) = 0, @UnitSalesPriceTotal DECIMAL(18,2) = 0, @POPricePercentId BIGINT = 0;
		DECLARE @POSSettingPercentValue DECIMAL(18,2) = 0;

		SELECT @POSSettingPercentValue = ISNULL([PercentValue], 0), @POPricePercentId = [PercentId] FROM [dbo].[AIAutoQouteSetting] WITH(NOLOCK) WHERE [Code] = @PurchasePriceCode AND [MasterCompanyId] = @MasterCompanyId;
	
		SELECT  @RecordsTotalPS = COUNT(IPS.ItemMasterId), 
				@UnitSalesPriceTotal = ISNULL(SUM(IPS.PP_UnitPurchasePrice),0)
		FROM [dbo].[ItemMasterPurchaseSale] IPS WITH(NOLOCK)
		WHERE IPS.[ItemMasterId] = @ItemMasterId
		  AND IPS.[ConditionId] = @NewConditionId   

		IF(@RecordsTotalPS > 0)
		BEGIN
	  		SET @PerUnitPricePS  = ISNULL((@UnitSalesPriceTotal / @RecordsTotalPS),0);	  		  	
		END

		IF(ISNULL(@POSSettingPercentValue, 0) > 0)
		BEGIN
			SELECT @CostPlusPrice = @PerUnitPricePS + (@PerUnitPricePS * @POSSettingPercentValue / 100)
		END
		ELSE
		BEGIN
			SELECT @CostPlusPrice = @PerUnitPricePS
		END

		------------------------------Vendor Quote (Purchase Quote + Mark Up) : Start ------------------------------ 
		DECLARE	@RecordsTotalPO INT = 0, @PerUnitPricePO DECIMAL(18,2) = 0, @FinalUnitPricePO DECIMAL(18,2) = 0, @UnitSalesPriceTotalPO DECIMAL(18,2) = 0, @PerUnitPricePOCostPlus DECIMAL(18,2) = 0, @POQuotePercentId BIGINT = 0;
		DECLARE @VQSettingYearId BIGINT, @VQSettingMonthId BIGINT, @VQSettingPercentValue DECIMAL(18,2) = 0, @VQSettingDays INT;

		SELECT @VQSettingYearId = [YearId], @VQSettingMonthId = [MonthId], @VQSettingPercentValue = [PercentValue], @VQSettingDays = ISNULL([Days], 0), @POQuotePercentId = [PercentId] FROM [dbo].[AIAutoQouteSetting] WITH(NOLOCK) WHERE [Code] = @VendorQuoteCode AND [MasterCompanyId] = @MasterCompanyId;

		SELECT	TOP 1
				@UnitSalesPriceTotalPO = ISNULL(POP.UnitCost,0)
		FROM [dbo].[VendorRFQPurchaseOrderPart] POP WITH(NOLOCK)
		INNER JOIN [dbo].[VendorRFQPurchaseOrder] PO WITH(NOLOCK) ON POP.[VendorRFQPurchaseOrderId] = PO.[VendorRFQPurchaseOrderId]
		WHERE POP.[ItemMasterId] = @ItemMasterId
			AND POP.[ConditionId] = @NewConditionId   
			AND CAST(PO.[OpenDate] AS DATE) BETWEEN DATEADD(DAY, -@VQSettingDays, CAST(GETUTCDATE() AS DATE)) AND CAST(GETUTCDATE() AS DATE)
			AND PO.[Status] NOT IN (SELECT item FROM SplitString(@Status_Code,','))
			AND PO.[MasterCompanyId] = @MasterCompanyId
			AND ISNULL(POP.IsNoQuote, 0) = 0
			ORDER BY POP.UpdatedDate DESC;	
		  
		IF(ISNULL(@UnitSalesPriceTotalPO, 0) > 0)
		BEGIN
	  	SET @PerUnitPricePO  = @UnitSalesPriceTotalPO;
	  	--Check if PercentValue selected or not
	  		IF(ISNULL(@VQSettingPercentValue,0) > 0)
	  		BEGIN
	  			SET @FinalUnitPricePO  = (@PerUnitPricePO * @VQSettingPercentValue ) / 100;
	  			SET @PerUnitPricePOCostPlus = @PerUnitPricePO + ISNULL(@FinalUnitPricePO,0);
	  		END
			ELSE
			BEGIN
				SET @PerUnitPricePOCostPlus = @PerUnitPricePO;
			END
		END
		------------------------------Vendor Quote (Purchase Quote + Mark Up) : End ------------------------------

        ------------------------------Price List------------------------------

		DECLARE @RecordsTotalPL INT = 0,@PerUnitPricePL DECIMAL(18,2) = 0, @UnitSalesPriceTotalPL DECIMAL(18,2) = 0
	
		SELECT  @RecordsTotalPL = COUNT(IPS.ItemMasterId), 
				@UnitSalesPriceTotalPL = ISNULL(SUM(IPS.SP_CalSPByPP_UnitSalePrice),0)
		FROM [dbo].[ItemMasterPurchaseSale] IPS WITH(NOLOCK)
		WHERE IPS.ItemMasterId = @ItemMasterId
		  AND IPS.[ConditionId] = @NewConditionId   

		IF(@RecordsTotalPL > 0)
		BEGIN
	  		SET @PerUnitPricePL  = ISNULL((@UnitSalesPriceTotalPL / @RecordsTotalPL),0);	  		  	
		END			   	

		SELECT @RecommendedPrice = MAX(v) FROM (VALUES (@CostPlusPrice),(@PerUnitPriceSO),(@PerUnitPriceSOQ),(@PerUnitPricePL),(@PerUnitPricePOCostPlus)) AS t(v);
	
		INSERT INTO #tmpRFQHistoryResult([PartNumber],[Condition],[PurchaseSalePrice],[SOUnitPrice],[SOQUnitPrice],[IlsPrice],[MarkUpPercentValue],[CostPlusPrice],[RecommendedPrice],[POUnitPrice],[POMarkUpPercentValue],[POUnitPriceCostPlus],[POPricePercentId],[POQuotePercentId])
								   VALUES (@PartNumber, @Code, @PerUnitPricePS,@PerUnitPriceSO,@PerUnitPriceSOQ,@PerUnitPricePL,@POSSettingPercentValue,@CostPlusPrice,@RecommendedPrice,@PerUnitPricePO,@VQSettingPercentValue,@PerUnitPricePOCostPlus,@POPricePercentId,@POQuotePercentId)
	
		SET @MinId = @MinId + 1
	END	
	

    SELECT 
        iM.ConditionId,
        iM.ItemMasterId,
        iM.ItemMasterPurchaseSaleId,
        iM.PartNumber,
        iM.PP_CurrencyId,
        iM.PP_FXRatePerc,
        iM.PP_LastListPriceDate,
        iM.PP_LastPurchaseDiscDate,
        iM.PP_PurchaseDiscAmount,
        iM.PP_PurchaseDiscPerc,
        iM.PP_UnitPurchasePrice,
        iM.PP_UOMId,
        iM.PP_VendorListPrice,
        iM.SP_CalSPByPP_BaseSalePrice,
        iM.SP_CalSPByPP_LastMarkUpDate,
        iM.SP_CalSPByPP_LastSalesDiscDate,
        iM.SP_CalSPByPP_MarkUpAmount,
        iM.SP_CalSPByPP_MarkUpPercOnListPrice,
        iM.SP_CalSPByPP_SaleDiscAmount,
        iM.SP_CalSPByPP_SaleDiscPerc,
        iM.SP_CalSPByPP_UnitSalePrice,
        iM.SP_FSP_CurrencyId,
        iM.SP_FSP_FlatPriceAmount,
        iM.SP_FSP_FXRatePerc,
        iM.SP_FSP_LastFlatPriceDate,
        iM.SP_FSP_UOMId,
        iM.UpdatedBy,
		CASE WHEN CAST(iM.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(iM.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE))END UpdatedDate,
        ISNULL(iM.IsActive,1) as IsActive,
        ISNULL(iM.IsDeleted,0) as IsDeleted,
        iM.CreatedBy,
		CASE WHEN CAST(iM.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(iM.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE))END CreatedDate,
        ISNULL(iM.ConditionName, '') AS ConditionName,
        ISNULL(iM.PP_UOMName, '') AS PP_UOMName,
        ISNULL(iM.PP_CurrencyName, '') AS PP_CurrencyName,
        ISNULL(iM.SP_FSP_UOMName, '') AS SP_FSP_UOMName,
        ISNULL(iM.SP_FSP_CurrencyName, '') AS SP_FSP_CurrencyName,
        ISNULL(iM.PP_PurchaseDiscPercValue, 0) AS PP_PurchaseDiscPercValue,
        ISNULL(per.PercentValue, 0) AS SP_CalSPByPP_MarkUpPercOnListPriceValue,
        ISNULL(iM.SP_CalSPByPP_SaleDiscPercValue, 0) AS SP_CalSPByPP_SaleDiscPercValue,
        iM.SalePriceSelectId,
        ISNULL(iM.SalePriceSelectName, '') AS SalePriceSelectName,
        ISNULL(sp.RecommendedPrice, 0) AS SuggestedPrice

    FROM dbo.ItemMasterPurchaseSale iM WITH(NOLOCK)
    LEFT JOIN dbo.[ItemMasterPurchaseSaleMaster] spdrp WITH(NOLOCK) ON iM.SalePriceSelectId = spdrp.ItemMasterPurchaseSaleMasterId
    LEFT JOIN dbo.[Percent] per WITH(NOLOCK) ON iM.SP_CalSPByPP_MarkUpPercOnListPriceValue = per.PercentId
    LEFT JOIN #tmpRFQHistoryResult sp ON sp.PartNumber = iM.PartNumber AND sp.Condition = iM.ConditionName
    WHERE iM.ItemMasterId = @ItemMasterId;
  END TRY
  BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_GetItemMasterPurchaseSale]',
            @ProcedureParameters varchar(3000) = '@ItemMasterId = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100)),
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