CREATE   FUNCTION dbo.GetAveragePriceById
(
    @SalesOrderQuoteId BIGINT,
	@PartNumber VARCHAR(256),
	@MasterCompanyId INT = NULL
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE 
        @RecordsTotal INT,
        @UnitSalesPriceTotal DECIMAL(18, 2),
        @PerUnitPrice DECIMAL(18, 2),
        @FinalUnitPrice DECIMAL(18, 2),
        @IlsPrice DECIMAL(18, 2),
		@Month INT ,
		@Year INT,
		@AiPercentValue DECIMAL(18,2) = 0,
		@IsEnableDisableAIintegration BIT = 0,
		@Status_Code VARCHAR(100) = 'Rejected,Open,Cancelled';

		--Get Value from Aisetting table mastercompany wise
			 SELECT @AiPercentValue = ISNULL(SIS.[PercentValue],0), 
					@IsEnableDisableAIintegration = ISNULL(SIS.[IsEnableDisableAIintegration],0),
					@Year = ISNULL(YR.[YearName],0),
					@Month = ISNULL(MON.[MonthNumber],0)
			 FROM [DBO].[AiIntegrationSetting] SIS WITH(NOLOCK) 
			 INNER JOIN [DBO].[Years] YR WITH(NOLOCK) ON SIS.[YearId] = YR.[YearId]
			 INNER JOIN [DBO].[Months] MON WITH(NOLOCK) ON SIS.[MonthId] = MON.[MonthId]
			 WHERE SIS.[MasterCompanyId] = @MasterCompanyId;

			-- Calculate total records and total sales price
			SELECT	
				@RecordsTotal = COUNT(SOPC.SalesOrderQuotePartId), 
				@UnitSalesPriceTotal = ISNULL(SUM(SOPC.UnitSalesPrice), 0)
			FROM [DBO].[SalesOrderQuotePartV1] SQP WITH(NOLOCK)
			INNER JOIN [DBO].[SalesOrderQuotePartCost] SOPC WITH(NOLOCK) 
				ON SQP.[SalesOrderQuotePartId] = SOPC.[SalesOrderQuotePartId]
			INNER JOIN [DBO].[SalesOrderQuote] SQ WITH(NOLOCK) 
				ON SQP.[SalesOrderQuoteId] = SQ.[SalesOrderQuoteId]
			INNER JOIN [DBO].[MasterSalesOrderQuoteStatus] SQS WITH(NOLOCK) 
				ON SQ.[StatusId] = SQS.[Id]
			WHERE 
				SQ.SalesOrderQuoteId = @SalesOrderQuoteId
				AND TRIM(SQP.PartNumber) = TRIM(@PartNumber)
				AND MONTH(SQ.[OpenDate]) >= @Month
				AND YEAR(SQ.[OpenDate]) >= @Year
				AND SQS.[Name] NOT IN (SELECT item FROM dbo.SplitString(@Status_Code, ','))
				AND SQP.[MasterCompanyId] = @MasterCompanyId;
			
			-- Calculate per unit price
			IF (@RecordsTotal > 0)
			BEGIN
				SET @PerUnitPrice = @UnitSalesPriceTotal / @RecordsTotal;

				IF (@AiPercentValue > 0)
				BEGIN
					SET @FinalUnitPrice = (@PerUnitPrice * @AiPercentValue) / 100;
					SET @PerUnitPrice = @PerUnitPrice + @FinalUnitPrice;
				END
			END
			ELSE
			BEGIN
				SET @PerUnitPrice = 0;
			END

			SET @IlsPrice = @PerUnitPrice;

			RETURN @IlsPrice;
END