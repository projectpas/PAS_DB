/*************************************************************           
 ** File:  [USP_GetRFQHistoryByPartNumber]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get RFQ History By Part And Condition
 ** Purpose:         
 ** Date:   13/08/2025      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   ----------  -----------		--------------------------------          
    1    13/08/2025  Moin Bloch		    Created
	2    14/08/2025  Moin Bloch         Removed Markuppercent from SO,SOQ
	3    04/09/2025  Devendra Shekh     Modified (Added Vendor Quote Calculation, Changed calculation Based on QuoteSetting)
	4    12/09/2025  Devendra Shekh     Modified (PO Quote Price Selection)
	5    12/09/2025  Devendra Shekh     Modified (Date Range Changes)
	6    17/09/2025  Devendra Shekh     Modified (added PercentId to Select)

  EXEC [dbo].[USP_GetRFQHistoryByPartNumber] 'NICKITEST-A',7,1
  EXEC [dbo].[USP_GetRFQHistoryByPartNumber] '1150-C',2,1
  
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetRFQHistoryByPartNumber]
@PartNumber VARCHAR(50)=NULL,
@ConditionId BIGINT=NULL,
@MasterCompanyId INT=NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  
	DECLARE @NECondition INT=NULL, @OHCondition INT=NULL, @NSCondition INT=NULL,@SVCondition INT =NULL,@ARCondition INT =NULL;
	DECLARE @NECode VARCHAR(20)='NE', @OHCode VARCHAR(20)='OH', @NSCode VARCHAR(20)='NS',@SVCode VARCHAR(20)='SV',@ARCode VARCHAR(20)='AR';
	DECLARE @MarkUpPercentId BIGINT=NULL, @MarkUpPercentValue DECIMAL(18,2)=0
	DECLARE @Month INT = 0,@Year INT = 0;
	DECLARE	@RecordsTotalSOQ INT = 0,@PerUnitPriceSOQ DECIMAL(18,2) = 0,@FinalUnitPriceSOQ DECIMAL(18,2) = 0,@UnitSalesPriceTotalSOQ DECIMAL(18,2) = 0
	DECLARE @Status_Code VARCHAR(100) = 'Rejected,Cancelled';
	DECLARE @CostPlusPrice DECIMAL(18,2) = 0,@RecommendedPrice DECIMAL(18,2) = 0
	DECLARE @TotalRecord int = 0;   
	DECLARE @MinId BIGINT = 1;  
	DECLARE @PriceListCode VARCHAR(50)  = 'Price List';
	DECLARE @AvgHistoricalSOCode VARCHAR(50)  = 'Avg Historical SO';
	DECLARE @AvgHistoricalSOQCode VARCHAR(50)  = 'Avg Historical SOQ';
	DECLARE @PurchasePriceCode VARCHAR(50)  = 'Purchase Price + Mark up';
	DECLARE @RecommendedPriceCode VARCHAR(50)  = 'Suggested Price';
	DECLARE @VendorQuoteCode VARCHAR(50)  = 'Purchase Quote + Mark Up';
	
	IF OBJECT_ID(N'tempdb..#tmpRFQHistoryResult') IS NOT NULL
	BEGIN
		DROP TABLE #tmpRFQHistoryResult
	END

	IF OBJECT_ID(N'tempdb..#tmpRFQConditionResult') IS NOT NULL
	BEGIN
		DROP TABLE #tmpRFQConditionResult
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
	   
	CREATE TABLE #tmpRFQConditionResult
	(
		[ID] BIGINT NOT NULL IDENTITY, 
		[Condition] VARCHAR(20) NULL,
		[ConditionId] BIGINT NULL		
	)

	--SELECT @MarkUpPercentId = ISNULL(SIS.[PercentId],0),
	--       @MarkUpPercentValue = ISNULL(SIS.[PercentValue],0), 					
	--	   @Year = ISNULL(YR.[YearName],0),
	--	   @Month = ISNULL(MON.[MonthNumber],0)
	--FROM [DBO].[AiIntegrationSetting] SIS WITH(NOLOCK) 
	--INNER JOIN [DBO].[Years] YR WITH(NOLOCK) ON SIS.[YearId] = YR.[YearId]
	--INNER JOIN [DBO].[Months] MON WITH(NOLOCK) ON SIS.[MonthId] = MON.[MonthId]
	--WHERE SIS.[MasterCompanyId] = @MasterCompanyId;
	
  	IF(@MasterCompanyId = 11)
	BEGIN
		SELECT @NECondition  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'NEW';
		SELECT @OHCondition  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'OVERHAULED';
		SELECT @NSCondition  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'NS';
		SELECT @SVCondition  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'SV';
		IF(@SVCondition IS NULL)
		BEGIN
			SELECT TOP 1 @SVCondition = [ConditionId] FROM [dbo].[Condition] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'SVC';
		END
		SELECT @ARCondition  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'ASREMOVE';
	END
	ELSE
	BEGIN
	    SELECT @NECondition  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'NEW';
		SELECT @OHCondition  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'OVERHAUL';
		
		IF(@OHCondition IS NULL)
		BEGIN
			SELECT TOP 1 @OHCondition = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'OVERHAULED';
		END
		SELECT @NSCondition  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'NS';	
		SELECT @SVCondition  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'SV';
		IF(@SVCondition IS NULL)
		BEGIN
			SELECT TOP 1 @SVCondition = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'SVC';
		END
		SELECT @ARCondition  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = 'ASREMOVE';
	END
	
	INSERT INTO #tmpRFQConditionResult([Condition],[ConditionId])  	  
	VALUES(@NECode,@NECondition),(@OHCode,@OHCondition),(@NSCode,@NSCondition),(@SVCode,@SVCondition),(@ARCode,@ARCondition)

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
		WHERE TRIM(SQP.[PartNumber]) = TRIM(@PartNumber)
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
		WHERE TRIM(SP.[PartNumber]) = TRIM(@PartNumber)
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
		WHERE TRIM(IPS.[PartNumber]) = TRIM(@PartNumber)
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
		WHERE TRIM(POP.[PartNumber]) = TRIM(@PartNumber)
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
		WHERE TRIM(IPS.[PartNumber]) = TRIM(@PartNumber)
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
	
	SELECT * from #tmpRFQHistoryResult
     
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'		
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_GetRFQHistoryByPartAndCondition]',
            @ProcedureParameters varchar(3000) = '@customerId = ''' + CAST(ISNULL(@PartNumber, '') AS varchar(100)),
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