/*************************************************************           
 ** File:   [USP_UpdateRFQPricebasedOnAISuggestionHistoricalData]           
 ** Author:   HEMANT SALIYA
 ** Description: Update RFQ Price Details based on AI suggestions
 ** Purpose:         
 ** Date:   30/06/2025
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    30/06/2025   HEMANT SALIYA    Created (Update RFQ Price Details based on AI suggestions)

EXEC USP_UpdateRFQPricebasedOnAISuggestionHistoricalData_WOQ '','',1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateRFQPricebasedOnAISuggestionHistoricalData_WOQ]
	--@MasterCompanyId BIGINT = NULL,
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL,
	@IntegrationTypeId INT = NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY  	

				DECLARE @Month INT = 7;
				DECLARE @Year INT = 2025;
	
		DECLARE @MasterLoopID INT = 0,
				@CustomerRfqId BIGINT = 0,
				@RfqId BIGINT = 0,
				@CustomerRfqQuoteId BIGINT = 0,
				@PartNumber NVARCHAR(200) = NULL,
				@SalesOrderQuoteId BIGINT = 0,
				@Condition_Code VARCHAR(100) = 'Rejected,Open,Cancelled',
				@AiPercentValue DECIMAL(18,2) = 0,
				@IsEnableDisableAIintegration BIT = 0,
				@MasterCompanyId BIGINT = 0,
				@UnitSalesPriceTotal DECIMAL(18,2) = 0,
				@RecordsTotal INT = 0,
				@PerUnitPrice DECIMAL(18,2) = 0,
				@CreatedBy VARCHAR(100) = 'Admin',
				@WOModuleId INT,
				@IsAutoInternalQuote BIT;

		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

		--Get FROM SalesOrderQuotePart data for selected part
		IF OBJECT_ID(N'tempdb..#tmpCustomerRfq') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCustomerRfq
		END

		CREATE TABLE #tmpCustomerRfq
		(
			ID BIGINT NOT NULL IDENTITY, 
			CustomerRfqId BIGINT NULL,
			RfqId BIGINT NULL,
			PartNumber VARCHAR(200) NULL,
			MasterCompanyId BIGINT NULL
		)

		INSERT INTO #tmpCustomerRfq (CustomerRfqId,RfqId,PartNumber,MasterCompanyId) 
				  SELECT CRFQ.CustomerRfqId,CRFQ.RfqId,CRFQ.LinePartNumber,CRFQ.MasterCompanyId
		FROM [DBO].[CustomerRfq] CRFQ WITH(NOLOCK)
		WHERE CRFQ.[IsQuote] IS  NULL
		ORDER BY CRFQ.CustomerRfqId DESC

		SELECT  @MasterLoopID = MAX(ID) FROM #tmpCustomerRfq;
		WHILE(@MasterLoopID > 0)
		BEGIN
			 SELECT @PartNumber = PartNumber,
					@MasterCompanyId = MasterCompanyId,
					@CustomerRfqId = CustomerRfqId,
					@RfqId = RfqId
			 FROM #tmpCustomerRfq WITH(NOLOCK) 
			 WHERE [ID] = @MasterLoopID;			 
			 
			 --Get Ai Percent Value from Aisetting table mastercompany wise
			 SELECT @AiPercentValue = ISNULL(SIS.[PercentValue],0), 
					@IsEnableDisableAIintegration = ISNULL(SIS.[IsEnableDisableAIintegration],0),
					@Year = ISNULL(YR.[YearName],0),
					@Month = ISNULL(MON.[MonthNumber],0),
					@IsAutoInternalQuote = ISNULL(SIS.IsAutoInternalQuote,0)
			 FROM [DBO].[AiIntegrationSetting] SIS WITH(NOLOCK) 
			 INNER JOIN [DBO].[Years] YR WITH(NOLOCK) ON SIS.[YearId] = YR.[YearId]
			 INNER JOIN [DBO].[Months] MON WITH(NOLOCK) ON SIS.[MonthId] = MON.[MonthId]
			 WHERE SIS.[MasterCompanyId] = @MasterCompanyId;

			 --Check is allow AI calculation or not
			 IF(@IsEnableDisableAIintegration > 0)
			 BEGIN
				  --Get data from WO Billing
				  SELECT @RecordsTotal = COUNT(WBI.[BillingInvoicingItemId]),
						 @UnitSalesPriceTotal = ISNULL(SUM(WBI.GrandTotal),0)
				  FROM [dbo].[BillingInvoicingItems] WBI WITH(NOLOCK)
				  INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WBI.[ReferenceId] = WO.[WorkOrderId]
				  LEFT JOIN [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK) ON WO.[WorkOrderId] = WOQ.[WorkOrderId]
				  INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WBI.[ItemMasterId] = IM.[ItemMasterId]
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
					   DECLARE @FinalUnitPrice DECIMAL(18,2) = 0;

					   SET @PerUnitPrice  =  @UnitSalesPriceTotal / @RecordsTotal;

					   --Check if PercentValue selected or not
					   IF(@AiPercentValue > 0)
					   BEGIN
							SET @FinalUnitPrice  = (@PerUnitPrice * @AiPercentValue) / 100;
							SET @PerUnitPrice = @PerUnitPrice + @FinalUnitPrice;
					   END
					   
					   ---------------------------Start Insert into Rfq Quote table --------------------------------------------------
						INSERT INTO [dbo].[CustomerRfqQuote]
											   ([CustomerRfqId] ,[RfqId] ,[AddComment] ,[IsAddCommentQuote] ,[FaaEasaRelease] ,[IsFaaEasaReleaseQuote] ,
												[RpOh] ,[IsRpOhQuote] ,[LegalEntityId] ,[MasterCompanyId] ,	
												[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
									VALUES (@CustomerRfqId ,@RfqId ,'' ,0 ,'' ,0,
										   '' ,0,1,@MasterCompanyId,
										   @CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE()  ,1 ,0);

						SELECT @CustomerRfqQuoteId = SCOPE_IDENTITY();	

					  ---------------------------End Insert into Rfq Quote table --------------------------------------------------

					  -------------------Start Customer RFQ Quote Details add ---------------------------------------------------------

						INSERT INTO [dbo].[CustomerRfqQuoteDetails]
								   ([CustomerRfqQuoteId] ,[ServiceType] ,IlsQty ,IlsTraceability ,IlsUom ,IlsPrice ,
									IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition,	
									[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES(@CustomerRfqQuoteId ,0 ,1 ,0078 ,1 ,@PerUnitPrice ,
									'Outright' ,GETUTCDATE() ,0 ,0 ,NULL,'NE',	
							   @CreatedBy,@CreatedBy,GETUTCDATE() ,GETUTCDATE() ,1 ,0)

					  -------------------End Customer RFQ Quote Details add ---------------------------------------------------------

					  ------- Update Csutomer RFQ for Is Quote added ----------					 
						 UPDATE [dbo].[CustomerRfq] 
							SET IsQuote = 1
						 WHERE [CustomerRfqId] = @CustomerRfqId;
				  END
			 END

			 SET @MasterLoopID = @MasterLoopID - 1;
		END

		SELECT * FROM #tmpCustomerRfq;
		

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'            
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateRFQPricebasedOnAISuggestionHistoricalData'             
			   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))			                                      
												   + '@Parameter2 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS VARCHAR(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH    
END