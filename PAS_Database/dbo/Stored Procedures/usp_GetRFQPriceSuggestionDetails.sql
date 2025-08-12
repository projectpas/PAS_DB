/*************************************************************             
 ** File:   [usp_GetRFQPriceSuggestionDetails]             
 ** Author:   Devendra Shekh    
 ** Description: Get RFQ Price Suggetion Based on Invoices
 ** Date:   31-July-2025 
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO	Date			Author				Change Description              
 ** --		--------		-------				--------------------------------            
 **	1		31-July-2025	Devendra Shekh		Created
 **	2		12-Aug-2025		Devendra Shekh		changed @RfqId dataType to NVARCHAR(400)
 
EXECUTE [dbo].[usp_GetRFQPriceSuggestionDetails] 6, 1   
**************************************************************/  
CREATE    PROCEDURE [dbo].[usp_GetRFQPriceSuggestionDetails]
@CustomerRfqId BIGINT = NULL,
@MasterCompanyId INT = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
	BEGIN TRY
		BEGIN

			DECLARE @Month INT = 7;
			DECLARE @Year INT = 2025;

			DECLARE	@IsMRO BIT, 
					@RfqId NVARCHAR(400),
					@WOModuleId INT = 0,
					@RecordsTotal INT = 0,
					@IntegrationPortalId INT = 0,
					@PartNumber NVARCHAR(256) = '',
					@PerUnitPrice DECIMAL(18,2) = 0,
					@FinalUnitPrice DECIMAL(18,2) = 0,
					@AiPercentValue DECIMAL(18,2) = 0,
					@IsEnableDisableAIintegration BIT = 0,
					@UnitSalesPriceTotal DECIMAL(18,2) = 0,
					@Condition_Code VARCHAR(100) = 'Rejected,Open,Cancelled';
			
			IF OBJECT_ID(N'tempdb..#tmpResult') IS NOT NULL
			BEGIN
				DROP TABLE #tmpResult
			END

			CREATE TABLE #tmpResult
			(
				ID BIGINT NOT NULL IDENTITY, 
				CustomerRfqId BIGINT NULL,
				RfqId NVARCHAR(400) NULL,
				PartNumber VARCHAR(200) NULL,
				MasterCompanyId BIGINT NULL,
				IlsPrice DECIMAL(18, 2) NULL
			)


			SELECT @RfqId = [RfqId], @PartNumber = [LinePartNumber], @IsMRO = ISNULL([IsMRO], 0), @IntegrationPortalId = [IntegrationPortalId] FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId AND [MasterCompanyId] = @MasterCompanyId;
			SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

			--Get Ai Percent Value from Aisetting table mastercompany wise
			 SELECT @AiPercentValue = ISNULL(SIS.[PercentValue],0), 
					@IsEnableDisableAIintegration = ISNULL(SIS.[IsEnableDisableAIintegration],0),
					@Year = ISNULL(YR.[YearName],0),
					@Month = ISNULL(MON.[MonthNumber],0)
			 FROM [DBO].[AiIntegrationSetting] SIS WITH(NOLOCK) 
			 INNER JOIN [DBO].[Years] YR WITH(NOLOCK) ON SIS.[YearId] = YR.[YearId]
			 INNER JOIN [DBO].[Months] MON WITH(NOLOCK) ON SIS.[MonthId] = MON.[MonthId]
			 WHERE SIS.[MasterCompanyId] = @MasterCompanyId;

			--Check isMRO
			IF(@IsMRO > 0)
			BEGIN
				--Get data from WO Billing
				SELECT	@RecordsTotal = COUNT(WBI.[BillingInvoicingItemId]),
						@UnitSalesPriceTotal = ISNULL(SUM(WBI.GrandTotal),0)
				FROM [dbo].[BillingInvoicingItems] WBI WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WBI.[ReferenceId] = WO.[WorkOrderId]
				LEFT JOIN [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK) ON WO.[WorkOrderId] = WOQ.[WorkOrderId]
				INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WBI.[ItemMasterId] = IM.[ItemMasterId]
				INNER JOIN [DBO].[WorkOrderStatus] WOS WITH(NOLOCK) ON WOS.[Id] = WO.[WorkOrderStatusId]
				WHERE WBI.[ModuleId] = @WOModuleId
				AND LOWER(TRIM(IM.[PartNumber])) = LOWER(TRIM(@PartNumber))
				AND MONTH(WOQ.[OpenDate]) >= @Month
				AND YEAR(WOQ.[OpenDate]) >= @Year
				AND ISNULL(WBI.[IsPerformaInvoice],0) = 0
				AND ISNULL(WBI.[IsVersionIncrease],0) = 0
				AND WBI.[MasterCompanyId] = @MasterCompanyId

				--Get data from WOQ
				IF(@RecordsTotal = 0)
				BEGIN
					SELECT 
						@RecordsTotal = COUNT(WQD.[WorkOrderQuoteDetailsId]),
						@UnitSalesPriceTotal = ISNULL(SUM(
							CASE 
								WHEN ISNULL(WQD.QuoteMethod, 0) > 0 THEN WQD.CommonFlatRate 
								ELSE ISNULL(WQD.MaterialFlatBillingAmount, 0) 
								   + ISNULL(WQD.LaborFlatBillingAmount, 0) 
								   + ISNULL(WQD.ChargesFlatBillingAmount, 0) 
								   + ISNULL(WQD.FreightFlatBillingAmount, 0) 
							END
						),0)
					FROM [dbo].[WorkOrderQuoteDetails] WQD WITH(NOLOCK)
					JOIN [dbo].[WorkOrderQuote] WOQ ON WOQ.WorkOrderQuoteId = WQD.WorkOrderQuoteId
					INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WQD.[ItemMasterId] = IM.[ItemMasterId]
					AND LOWER(TRIM(IM.[PartNumber])) = LOWER(TRIM(@PartNumber))
					AND MONTH(WOQ.[OpenDate]) >= @Month
					AND YEAR(WOQ.[OpenDate]) >= @Year
					AND WOQ.[MasterCompanyId] = @MasterCompanyId
				END
				  
				IF(@RecordsTotal > 0)
				BEGIN
					SET @PerUnitPrice  =  @UnitSalesPriceTotal / @RecordsTotal;

					--Check if PercentValue selected or not
					IF(@AiPercentValue > 0)
					BEGIN
						SET @FinalUnitPrice  = (@PerUnitPrice * @AiPercentValue) / 100;
						SET @PerUnitPrice = @PerUnitPrice + @FinalUnitPrice;
					END
				END

				--Saving Return Result Data
				INSERT INTO #tmpResult([CustomerRfqId], [RfqId], [PartNumber], [MasterCompanyId], [IlsPrice])
				VALUES (@CustomerRfqId, @RfqId, @PartNumber, @MasterCompanyId, @PerUnitPrice)
			END
			ELSE
			BEGIN
				SELECT	@RecordsTotal = COUNT(SOPC.SalesOrderQuotePartId), 
						@UnitSalesPriceTotal = ISNULL(SUM(SOPC.UnitSalesPrice),0)
				FROM [DBO].[SalesOrderQuotePartV1] SQP WITH(NOLOCK)
				INNER JOIN [DBO].[SalesOrderQuotePartCost] SOPC WITH(NOLOCK) ON SQP.[SalesOrderQuotePartId] = SOPC.[SalesOrderQuotePartId]
				INNER JOIN [DBO].[SalesOrderQuote] SQ WITH(NOLOCK) ON SQP.[SalesOrderQuoteId] = SQ.[SalesOrderQuoteId]
				INNER JOIN [DBO].[MasterSalesOrderQuoteStatus] SQS WITH(NOLOCK) ON SQ.[StatusId] = SQS.[Id]
				WHERE LOWER(TRIM(SQP.[PartNumber])) = LOWER(TRIM(@PartNumber))
				AND MONTH(SQ.[OpenDate]) >= @Month
				AND YEAR(SQ.[OpenDate]) >= @Year
				AND SQS.[Name] NOT IN (SELECT item FROM SplitString(@Condition_Code,','))
				AND SQP.[MasterCompanyId] = @MasterCompanyId;
				  
				IF(@RecordsTotal > 0)
				BEGIN
					SET @PerUnitPrice  =  @UnitSalesPriceTotal / @RecordsTotal;

					--Check if PercentValue selected or not
					IF(@AiPercentValue > 0)
					BEGIN
						SET @FinalUnitPrice  = (@PerUnitPrice * @AiPercentValue) / 100;
						SET @PerUnitPrice = @PerUnitPrice + @FinalUnitPrice;
					END
				END

				--Saving Return Result Data
				INSERT INTO #tmpResult([CustomerRfqId], [RfqId], [PartNumber], [MasterCompanyId], [IlsPrice])
				VALUES (@CustomerRfqId, @RfqId, @PartNumber, @MasterCompanyId, @PerUnitPrice)
			END


			SELECT	[CustomerRfqId] AS customerRfqId,
					[RfqId] AS rfqId,
					[PartNumber] AS partNumber,
					[MasterCompanyId] AS masterCompanyId,
					[IlsPrice] AS ilsPrice
			FROM #tmpResult

		END
	END TRY    
	BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_GetRFQPriceSuggestionDetails' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerRfqId, '')+''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            EXEC spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END