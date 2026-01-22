/*************************************************************           
 ** File:  [usp_GetRFQPricingAnalysisDetails]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used to Get RFQ Pricing Analysis (History) By Part And Condition
 ** Purpose:         
 ** Date:   17-Sept-2025
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date					Author						Change Description            
 ** --   ----------				-----------				--------------------------------          
    1    17-Sept-2025			Devendra Shekh				Created

exec dbo.usp_GetRFQPricingAnalysisDetails @PartNumber=N'1150-C',@ConditionId=7,@MasterCompanyId=1,@SODays=0,@SOQDays=0,@SuggestedPriceType=0,
@NEPOPriceMarkUpPercentId=3,@OHPOPriceMarkUpPercentId=3,@NSPOPriceMarkUpPercentId=3,@SVPOPriceMarkUpPercentId=3,@ARPOPriceMarkUpPercentId=0,
@NEPOQuoteMarkUpPercentId=40,@OHPOQuoteMarkUpPercentId=40,@NSPOQuoteMarkUpPercentId=40,@SVPOQuoteMarkUpPercentId=20,@ARPOQuoteMarkUpPercentId=25
go

************************************************************************/
CREATE     PROCEDURE [dbo].[usp_GetRFQPricingAnalysisDetails]
@PartNumber VARCHAR(50) = NULL,
@ConditionId BIGINT = NULL,
@MasterCompanyId INT = NULL,
@SODays INT = NULL,
@SOQDays INT = NULL,
@SuggestedPriceType INT = NULL,
@NEPOPriceMarkUpPercentId INT = NULL,
@OHPOPriceMarkUpPercentId INT = NULL,
@NSPOPriceMarkUpPercentId INT = NULL,
@SVPOPriceMarkUpPercentId INT = NULL,
@ARPOPriceMarkUpPercentId INT = NULL,
@NEPOQuoteMarkUpPercentId INT = NULL,
@OHPOQuoteMarkUpPercentId INT = NULL,
@NSPOQuoteMarkUpPercentId INT = NULL,
@SVPOQuoteMarkUpPercentId INT = NULL,
@ARPOQuoteMarkUpPercentId INT = NULL
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
  
		DECLARE @NECondition INT=NULL, @OHCondition INT=NULL, @NSCondition INT=NULL,@SVCondition INT =NULL,@ARCondition INT =NULL;
		DECLARE @NECode VARCHAR(20)='NE', @OHCode VARCHAR(20)='OH', @NSCode VARCHAR(20)='NS',@SVCode VARCHAR(20)='SV',@ARCode VARCHAR(20)='AR';
		
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

		DECLARE @MaxDays INT = (SELECT DATEDIFF(DAY, '0001-01-01', GETUTCDATE()) AS MaxDays);
		SET @SODays = IIF(ISNULL(@SODays, 0) > ISNULL(@MaxDays, 0), @MaxDays, @SODays);
		SET @SOQDays = IIF(ISNULL(@SOQDays, 0) > ISNULL(@MaxDays, 0), @MaxDays, @SOQDays);
	
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

			DECLARE @SOQSettingDays INT;

			--SELECT @SOQSettingDays = ISNULL([Days], 0) FROM [dbo].[AIAutoQouteSetting] WITH(NOLOCK) WHERE [Code] = @AvgHistoricalSOQCode AND [MasterCompanyId] = @MasterCompanyId;
			SET @SOQSettingDays = ISNULL(@SOQDays, 0);

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
			END

			------------------------------SO------------------------------

			DECLARE	@RecordsTotalSO INT = 0,@PerUnitPriceSO DECIMAL(18,2) = 0,@FinalUnitPriceSO DECIMAL(18,2) = 0,@UnitSalesPriceTotalSO DECIMAL(18,2) = 0;
			DECLARE @SOSettingDays INT;

			--SELECT @SOSettingDays = ISNULL([Days], 0) FROM [dbo].[AIAutoQouteSetting] WITH(NOLOCK) WHERE [Code] = @AvgHistoricalSOCode AND [MasterCompanyId] = @MasterCompanyId;
			SET @SOSettingDays = ISNULL(@SODays, 0);

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
			END
	  
			------------------------------Purchase And Sale------------------------------ 

			DECLARE @RecordsTotalPS INT = 0,@PerUnitPricePS DECIMAL(18,2) = 0, @UnitSalesPriceTotal DECIMAL(18,2) = 0, @POPricePercentId BIGINT = 0;
			DECLARE @POSSettingPercentValue DECIMAL(18,2) = 0;

			--SELECT @POSSettingPercentValue = ISNULL([PercentValue], 0), @POPricePercentId = [PercentId] FROM [dbo].[AIAutoQouteSetting] WITH(NOLOCK) WHERE [Code] = @PurchasePriceCode AND [MasterCompanyId] = @MasterCompanyId;
			
			SET @POPricePercentId = CASE	WHEN @Code = @NECode THEN @NEPOPriceMarkUpPercentId
											WHEN @Code = @OHCode THEN @OHPOPriceMarkUpPercentId
											WHEN @Code = @NSCode THEN @NSPOPriceMarkUpPercentId
											WHEN @Code = @SVCode THEN @SVPOPriceMarkUpPercentId
											WHEN @Code = @ARCode THEN @ARPOPriceMarkUpPercentId
											ELSE 0 END
			
			SELECT @POSSettingPercentValue = [PercentValue] FROM [dbo].[Percent] WITH(NOLOCK) WHERE [PercentId] = @POPricePercentId AND [MasterCompanyId] = @MasterCompanyId;
			SET @POSSettingPercentValue = CASE WHEN ISNULL(@POPricePercentId, 0) = 0 THEN 0 ELSE @POSSettingPercentValue END;

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
			DECLARE @VQSettingPercentValue DECIMAL(18,2) = 0, @VQSettingDays INT;

			SELECT @VQSettingPercentValue = [PercentValue], @VQSettingDays = ISNULL([Days], 0), @POQuotePercentId = [PercentId] FROM [dbo].[AIAutoQouteSetting] WITH(NOLOCK) WHERE [Code] = @VendorQuoteCode AND [MasterCompanyId] = @MasterCompanyId;

			SET @POQuotePercentId = CASE	WHEN @Code = @NECode THEN @NEPOQuoteMarkUpPercentId
											WHEN @Code = @OHCode THEN @OHPOQuoteMarkUpPercentId
											WHEN @Code = @NSCode THEN @NSPOQuoteMarkUpPercentId
											WHEN @Code = @SVCode THEN @SVPOQuoteMarkUpPercentId
											WHEN @Code = @ARCode THEN @ARPOQuoteMarkUpPercentId
											ELSE 0 END
			
			SELECT @VQSettingPercentValue = [PercentValue] FROM [dbo].[Percent] WITH(NOLOCK) WHERE [PercentId] = @POQuotePercentId AND [MasterCompanyId] = @MasterCompanyId;
			SET @VQSettingPercentValue = CASE WHEN ISNULL(@POQuotePercentId, 0) = 0 THEN 0 ELSE @VQSettingPercentValue END;

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

			IF(ISNULL(@SuggestedPriceType, 0) = 0)
			BEGIN
				SELECT @RecommendedPrice = MAX(v) FROM (VALUES (@CostPlusPrice),(@PerUnitPriceSO),(@PerUnitPriceSOQ),(@PerUnitPricePL),(@PerUnitPricePOCostPlus)) AS t(v);
			END
			ELSE
			BEGIN
				SELECT @RecommendedPrice = AVG(NULLIF(v, 0)) FROM (VALUES (@CostPlusPrice),(@PerUnitPriceSO),(@PerUnitPriceSOQ),(@PerUnitPricePL),(@PerUnitPricePOCostPlus)) AS t(v);
			END
	
			INSERT INTO #tmpRFQHistoryResult([PartNumber],[Condition],[PurchaseSalePrice],[SOUnitPrice],[SOQUnitPrice],[IlsPrice],[MarkUpPercentValue],[CostPlusPrice],[RecommendedPrice],[POUnitPrice],[POMarkUpPercentValue],[POUnitPriceCostPlus],[POPricePercentId],[POQuotePercentId])
									   VALUES (@PartNumber, @Code, @PerUnitPricePS,@PerUnitPriceSO,@PerUnitPriceSOQ,@PerUnitPricePL,@POSSettingPercentValue,@CostPlusPrice,@RecommendedPrice,@PerUnitPricePO,@VQSettingPercentValue,@PerUnitPricePOCostPlus,@POPricePercentId,@POQuotePercentId)
	
			SET @MinId = @MinId + 1
		END			   	 		
	
		SELECT * from #tmpRFQHistoryResult;
     
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'usp_GetRFQPricingAnalysisDetails',
            @ProcedureParameters varchar(3000) = '@PartNumber = ''' + CAST(ISNULL(@PartNumber, '') AS varchar(100)),
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