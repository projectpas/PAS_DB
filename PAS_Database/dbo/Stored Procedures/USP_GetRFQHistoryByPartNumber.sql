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

  EXEC [dbo].[USP_GetRFQHistoryByPartNumber] 'NICKITEST-A',7,1
  EXEC [dbo].[USP_GetRFQHistoryByPartNumber] 'ABC123',7,1
  
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
	DECLARE @Status_Code VARCHAR(100) = 'Rejected,Open,Cancelled';
	DECLARE @CostPlusPrice DECIMAL(18,2) = 0,@RecommendedPrice DECIMAL(18,2) = 0
	
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
		[RecommendedPrice] DECIMAL(18,2) NULL
	)


	SELECT @MarkUpPercentId = ISNULL(SIS.[PercentId],0),
	       @MarkUpPercentValue = ISNULL(SIS.[PercentValue],0), 					
		   @Year = ISNULL(YR.[YearName],0),
		   @Month = ISNULL(MON.[MonthNumber],0)
	FROM [DBO].[AiIntegrationSetting] SIS WITH(NOLOCK) 
	INNER JOIN [DBO].[Years] YR WITH(NOLOCK) ON SIS.[YearId] = YR.[YearId]
	INNER JOIN [DBO].[Months] MON WITH(NOLOCK) ON SIS.[MonthId] = MON.[MonthId]
	WHERE SIS.[MasterCompanyId] = @MasterCompanyId;
	
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
	
	   	  
	

	-- SOQ NE
	   
	SELECT	@RecordsTotalSOQ = COUNT(SOPC.SalesOrderQuotePartId), 
			@UnitSalesPriceTotalSOQ = ISNULL(SUM(SOPC.UnitSalesPrice),0)
	FROM [dbo].[SalesOrderQuotePartV1] SQP WITH(NOLOCK)
	INNER JOIN [dbo].[SalesOrderQuotePartCost] SOPC WITH(NOLOCK) ON SQP.[SalesOrderQuotePartId] = SOPC.[SalesOrderQuotePartId]
	INNER JOIN [dbo].[SalesOrderQuote] SQ WITH(NOLOCK) ON SQP.[SalesOrderQuoteId] = SQ.[SalesOrderQuoteId]
	INNER JOIN [dbo].[MasterSalesOrderQuoteStatus] SQS WITH(NOLOCK) ON SQ.[StatusId] = SQS.[Id]
	WHERE TRIM(SQP.[PartNumber]) = TRIM(@PartNumber)
	  AND SQP.[ConditionId] = @NECondition   -------------------  NE Condition
	  AND MONTH(SQ.[OpenDate]) >= @Month
	  AND YEAR(SQ.[OpenDate]) >= @Year
	  AND SQS.[Name] NOT IN (SELECT item FROM SplitString(@Status_Code,','))
	  AND SQP.[MasterCompanyId] = @MasterCompanyId;				
	  IF(@RecordsTotalSOQ > 0)
	  BEGIN
	  	SET @PerUnitPriceSOQ  = ISNULL((@UnitSalesPriceTotalSOQ / @RecordsTotalSOQ),0);
	  	--Check if PercentValue selected or not
	  	IF(@MarkUpPercentValue > 0)
	  	BEGIN
	  		SET @FinalUnitPriceSOQ  = (@PerUnitPriceSOQ * @MarkUpPercentValue) / 100;
	  		SET @PerUnitPriceSOQ = @PerUnitPriceSOQ + ISNULL(@FinalUnitPriceSOQ,0);
	  	END
	  END

	--  SO NE 

	DECLARE	@RecordsTotalSO INT = 0,@PerUnitPriceSO DECIMAL(18,2) = 0,@FinalUnitPriceSO DECIMAL(18,2) = 0,@UnitSalesPriceTotalSO DECIMAL(18,2) = 0

	SELECT	@RecordsTotalSO = COUNT(SOPC.SalesOrderPartId), 
			@UnitSalesPriceTotalSO = ISNULL(SUM(SOPC.UnitSalesPrice),0)
	FROM [dbo].[SalesOrderPartV1] SP WITH(NOLOCK)
	INNER JOIN [dbo].[SalesOrderPartCost] SOPC WITH(NOLOCK) ON SP.[SalesOrderPartId] = SOPC.[SalesOrderPartId]
	INNER JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON SP.[SalesOrderId] = SO.[SalesOrderId]
	INNER JOIN [dbo].[MasterSalesOrderStatus] SOS WITH(NOLOCK) ON SO.[StatusId] = SOS.[Id]
	WHERE TRIM(SP.[PartNumber]) = TRIM(@PartNumber)
	  AND SP.[ConditionId] = @NECondition   -------------------  NE Condition
	  AND MONTH(SO.[OpenDate]) >= @Month
	  AND YEAR(SO.[OpenDate]) >= @Year
	  AND SOS.[Name] NOT IN (SELECT item FROM SplitString(@Status_Code,','))
	  AND SP.[MasterCompanyId] = @MasterCompanyId;				
	  IF(@RecordsTotalSO > 0)
	  BEGIN
	  	SET @PerUnitPriceSO  = ISNULL((@UnitSalesPriceTotalSO / @RecordsTotalSO),0);
	  	--Check if PercentValue selected or not
	  	IF(@MarkUpPercentValue > 0)
	  	BEGIN
	  		SET @FinalUnitPriceSO  = (@PerUnitPriceSO * @MarkUpPercentValue) / 100;
	  		SET @PerUnitPriceSO = @PerUnitPriceSO + ISNULL(@FinalUnitPriceSO,0);
	  	END
	  END
	  
	-- Purchase And Sale NE

	DECLARE @RecordsTotalPS INT = 0,@PerUnitPricePS DECIMAL(18,2) = 0, @UnitSalesPriceTotal DECIMAL(18,2) = 0
	
	SELECT  @RecordsTotalPS = COUNT(IPS.ItemMasterId), 
			@UnitSalesPriceTotal = ISNULL(SUM(IPS.PP_UnitPurchasePrice),0)
	FROM [dbo].[ItemMasterPurchaseSale] IPS WITH(NOLOCK)
	WHERE TRIM(IPS.[PartNumber]) = TRIM(@PartNumber)
	  AND IPS.[ConditionId] = @NECondition   -------------------  NE Condition

	IF(@RecordsTotalPS > 0)
	BEGIN
	  	SET @PerUnitPricePS  = ISNULL((@UnitSalesPriceTotal / @RecordsTotalPS),0);	  		  	
	END

	SELECT @CostPlusPrice = @PerUnitPricePS + (@PerUnitPricePS * @MarkUpPercentValue / 100)

	SELECT @RecommendedPrice = MAX(v) FROM (VALUES (@PerUnitPricePS),(@PerUnitPriceSO),(@PerUnitPriceSOQ)) AS t(v);
	
	INSERT INTO #tmpRFQHistoryResult([PartNumber],[Condition],[PurchaseSalePrice],[SOUnitPrice],[SOQUnitPrice],[IlsPrice],[MarkUpPercentValue],[CostPlusPrice],[RecommendedPrice])
				               VALUES (@PartNumber, @NECode, @PerUnitPricePS,@PerUnitPriceSO,@PerUnitPriceSOQ,0,@MarkUpPercentValue,@CostPlusPrice,@RecommendedPrice)
	
				   	 		
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