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
	2    13/08/2025  Hemant Saliya	    Update for Get the single Price.

  EXEC [dbo].[USP_GetRFQHistoryByPartNumberCondition] 'NICKITEST-A','NE',1
  EXEC [dbo].[USP_GetRFQHistoryByPartNumberCondition] 'ABC123','NE',1
  
************************************************************************/
CREATE OR ALTER    PROCEDURE [dbo].[USP_GetRFQHistoryByPartNumberCondition]
	@PartNumber VARCHAR(50)=NULL,
	@ConditionCode VARCHAR(100)=NULL,
	@MasterCompanyId INT=NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  
	DECLARE @MarkUpPercentId BIGINT=NULL, @MarkUpPercentValue DECIMAL(18,2)=0
	DECLARE @Month INT = 0,@Year INT = 0;
	DECLARE	@RecordsTotalSOQ INT = 0,@PerUnitPriceSOQ DECIMAL(18,2) = 0,@FinalUnitPriceSOQ DECIMAL(18,2) = 0,@UnitSalesPriceTotalSOQ DECIMAL(18,2) = 0
	DECLARE @Status_Code VARCHAR(100) = 'Rejected,Open,Cancelled';
	DECLARE @CostPlusPrice DECIMAL(18,2) = 0,@RecommendedPrice DECIMAL(18,2) = 0
	DECLARE @TotalRecord int = 0;   
	DECLARE @MinId BIGINT = 1;    

	DECLARE @ConditionCodeData VARCHAR(20),
	        @ConditionId INT = NULL;
	
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
		--[PurchaseSalePrice] DECIMAL(18,2) NULL,		
		--[SOUnitPrice] DECIMAL(18,2) NULL,
		--[SOQUnitPrice] DECIMAL(18,2) NULL,
		--[IlsPrice] DECIMAL(18,2) NULL,		
  --      [MarkUpPercentValue] DECIMAL(18,2) NULL,
		--[CostPlusPrice] DECIMAL(18,2) NULL,
		--[RecommendedPrice] DECIMAL(18,2) NULL,
		[UnitPrice] DECIMAL(18,2) NULL,
		[Code] VARCHAR(50) NULL,
	)
	   
	CREATE TABLE #tmpRFQConditionResult
	(
		[ID] BIGINT NOT NULL IDENTITY, 
		[Condition] VARCHAR(20) NULL,
		[ConditionId] BIGINT NULL		
	)

	SELECT @MarkUpPercentId = ISNULL(SIS.[PercentId],0),
	       @MarkUpPercentValue = ISNULL(SIS.[PercentValue],0), 					
		   @Year = ISNULL(YR.[YearName],0),
		   @Month = ISNULL(MON.[MonthNumber],0)
	FROM [DBO].[AiIntegrationSetting] SIS WITH(NOLOCK) 
	INNER JOIN [DBO].[Years] YR WITH(NOLOCK) ON SIS.[YearId] = YR.[YearId]
	INNER JOIN [DBO].[Months] MON WITH(NOLOCK) ON SIS.[MonthId] = MON.[MonthId]
	WHERE SIS.[MasterCompanyId] = @MasterCompanyId;
	
	SELECT @ConditionId  = [ConditionId], @ConditionCodeData = [Code] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = @ConditionCode;

	IF(@ConditionId IS NULL)
	BEGIN
		 SELECT @ConditionId  = [ConditionId], @ConditionCodeData = [Code] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Description] = @ConditionCode;
	END

 
	INSERT INTO #tmpRFQConditionResult([Condition],[ConditionId])  	  
	VALUES(@ConditionCodeData,@ConditionId)
		
	SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmpRFQConditionResult    

	PRINT 1

	WHILE @MinId <= @TotalRecord
	BEGIN
		DECLARE @NewConditionId BIGINT=0,@Code VARCHAR(20)=''

		SELECT @NewConditionId = [ConditionId],
			   @Code = [Condition]	    
		FROM #tmpRFQConditionResult WHERE [ID] = @MinId

		------------------------------SOQ------------------------------ 
	   
		SELECT	@RecordsTotalSOQ = COUNT(SOPC.SalesOrderQuotePartId), 
				@UnitSalesPriceTotalSOQ = ISNULL(SUM(SOPC.UnitSalesPrice),0)
		FROM [dbo].[SalesOrderQuotePartV1] SQP WITH(NOLOCK)
		INNER JOIN [dbo].[SalesOrderQuotePartCost] SOPC WITH(NOLOCK) ON SQP.[SalesOrderQuotePartId] = SOPC.[SalesOrderQuotePartId]
		INNER JOIN [dbo].[SalesOrderQuote] SQ WITH(NOLOCK) ON SQP.[SalesOrderQuoteId] = SQ.[SalesOrderQuoteId]
		INNER JOIN [dbo].[MasterSalesOrderQuoteStatus] SQS WITH(NOLOCK) ON SQ.[StatusId] = SQS.[Id]
		WHERE TRIM(SQP.[PartNumber]) = TRIM(@PartNumber)
		  AND SQP.[ConditionId] = @NewConditionId   
		  AND MONTH(SQ.[OpenDate]) >= @Month
		  AND YEAR(SQ.[OpenDate]) >= @Year
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

		DECLARE	@RecordsTotalSO INT = 0,@PerUnitPriceSO DECIMAL(18,2) = 0,@FinalUnitPriceSO DECIMAL(18,2) = 0,@UnitSalesPriceTotalSO DECIMAL(18,2) = 0

		SELECT	@RecordsTotalSO = COUNT(SOPC.SalesOrderPartId), 
				@UnitSalesPriceTotalSO = ISNULL(SUM(SOPC.UnitSalesPrice),0)
		FROM [dbo].[SalesOrderPartV1] SP WITH(NOLOCK)
		INNER JOIN [dbo].[SalesOrderPartCost] SOPC WITH(NOLOCK) ON SP.[SalesOrderPartId] = SOPC.[SalesOrderPartId]
		INNER JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON SP.[SalesOrderId] = SO.[SalesOrderId]
		INNER JOIN [dbo].[MasterSalesOrderStatus] SOS WITH(NOLOCK) ON SO.[StatusId] = SOS.[Id]
		WHERE TRIM(SP.[PartNumber]) = TRIM(@PartNumber)
		  AND SP.[ConditionId] = @NewConditionId   
		  AND MONTH(SO.[OpenDate]) >= @Month
		  AND YEAR(SO.[OpenDate]) >= @Year
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

		DECLARE @RecordsTotalPS INT = 0,@PerUnitPricePS DECIMAL(18,2) = 0, @UnitSalesPriceTotal DECIMAL(18,2) = 0
	
		SELECT  @RecordsTotalPS = COUNT(IPS.ItemMasterId), 
				@UnitSalesPriceTotal = ISNULL(SUM(IPS.PP_UnitPurchasePrice),0)
		FROM [dbo].[ItemMasterPurchaseSale] IPS WITH(NOLOCK)
		WHERE TRIM(IPS.[PartNumber]) = TRIM(@PartNumber)
		  AND IPS.[ConditionId] = @NewConditionId   

		IF(@RecordsTotalPS > 0)
		BEGIN
	  		SET @PerUnitPricePS  = ISNULL((@UnitSalesPriceTotal / @RecordsTotalPS),0);	  		  	
		END
		SELECT @CostPlusPrice = @PerUnitPricePS + (@PerUnitPricePS * @MarkUpPercentValue / 100)

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
		--PRINT 2
		SELECT @RecommendedPrice = MAX(v) FROM (VALUES (@CostPlusPrice),(@PerUnitPriceSO),(@PerUnitPriceSOQ),(@PerUnitPricePL)) AS t(v);
	
		INSERT INTO #tmpRFQHistoryResult([PartNumber],[Condition],[UnitPrice],[Code])
								   VALUES (@PartNumber, @Code, @PerUnitPricePS,'Price List')
		INSERT INTO #tmpRFQHistoryResult([PartNumber],[Condition],[UnitPrice],[Code])
								   VALUES (@PartNumber, @Code, @PerUnitPriceSO,'Avg Historical SO')
		INSERT INTO #tmpRFQHistoryResult([PartNumber],[Condition],[UnitPrice],[Code])
								   VALUES (@PartNumber, @Code, @PerUnitPriceSOQ,'Avg Historical SOQ')
		INSERT INTO #tmpRFQHistoryResult([PartNumber],[Condition],[UnitPrice],[Code])
								   VALUES (@PartNumber, @Code, @CostPlusPrice,'Purchase Price + MArk Up')
		INSERT INTO #tmpRFQHistoryResult([PartNumber],[Condition],[UnitPrice],[Code])
								   VALUES (@PartNumber, @Code, @RecommendedPrice,'Recommended Price')

		IF OBJECT_ID(N'tempdb..#tmpRFQConditionResult') IS NOT NULL
		BEGIN
			DROP TABLE #tmpRFQConditionResult
		END

		CREATE TABLE #tmpResult
		(
			[ID] BIGINT NOT NULL IDENTITY, 
			[PartNumber] VARCHAR(50) NULL,
			[Condition] VARCHAR(50) NULL,
			[UnitPrice] DECIMAL(18,2) NULL,
			[Code] VARCHAR(50) NULL,
			[Sequence] Int NULL,
			[QuoteSendReviewId] Int NULL,
			[QuoteSendReview] VARCHAR(50) NULL,

		)
		--PRINT 3
		INSERT INTO #tmpResult(PartNumber, Condition, Code, UnitPrice, [Sequence], QuoteSendReviewId, QuoteSendReview)
		SELECT @PartNumber,@Code, code,  
			CASE WHEN Code = 'Price List' THEN @PerUnitPricePS
				 WHEN Code = 'Avg Historical SO' THEN @PerUnitPriceSO
				 WHEN Code = 'Avg Historical SOQ' THEN @PerUnitPriceSOQ
				 WHEN Code = 'Purchase Price + Mark up' THEN @CostPlusPrice
				 WHEN Code = 'Recommended Price' THEN @RecommendedPrice
			ELSE 0 END,
			[Sequence], QuoteSendReviewId, QuoteSendReview
		FROM dbo.[AIAutoQouteSetting] WITH(NOLOCK)
		WHERE MasterCompanyId = @MasterCompanyId
	
		SET @MinId = @MinId + 1
	END			   	 		
	
	--SELECT *  FROM #tmpResult;
	IF((SELECT MAX(UnitPrice) FROM #tmpResult) > 0)
	BEGIN
		SELECT TOP 1 * FROM #tmpResult WHERE ISNULL(UnitPrice, 0) > 0 Order by Sequence
	END
	ELSE 
	BEGIN
		SELECT TOP 1 * FROM #tmpResult Order by Sequence
	END
	--SELECT * from #tmpRFQHistoryResult
     
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
  END CATCH
END
