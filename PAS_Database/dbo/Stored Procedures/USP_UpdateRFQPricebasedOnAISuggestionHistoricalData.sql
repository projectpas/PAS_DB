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
	2    19/06/2026   Moin Bloch       Fixed Error Log Errors PN-16924
	3    24/06/2026   Moin Bloch       Fixed Error Log Errors PN-16924

EXEC USP_UpdateRFQPricebasedOnAISuggestionHistoricalData '','',1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateRFQPricebasedOnAISuggestionHistoricalData]
	--@MasterCompanyId BIGINT = NULL,
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL,
	@IntegrationTypeId INT = NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY  	

				DECLARE @Month INT = 8;
				DECLARE @Year INT = 2025;
	
		DECLARE @MasterLoopID INT = 0,
				--@PartNumber NVARCHAR(200) = '0856AE15',
				@CustomerRfqId BIGINT = 0,
				@RfqId NVARCHAR(400) = NULL,
				@Condition VARCHAR(256),
				@ConditionId BIGINT,
				@CustomerRfqQuoteId BIGINT = 0,
				@PartNumber NVARCHAR(200) = NULL,
				@BuyerCompanyName NVARCHAR(200) = NULL,
				@SalesOrderQuoteId BIGINT = 0,
				@Condition_Code VARCHAR(100) = 'Rejected,Open,Cancelled',
				@AiPercentValue DECIMAL(18,2) = 0,
				@IsEnableDisableAIintegration BIT = 0,
				@MasterCompanyId INT = 0,
				@UnitSalesPriceTotal DECIMAL(18,2) = 0,
				@RecordsTotal INT = 0,
				@PerUnitPrice DECIMAL(18,2) = 0,
				@CreatedBy VARCHAR(256) = 'Admin',
				@IsAutoInternalQuote BIT;

		--Get FROM SalesOrderQuotePart data for selected part
		IF OBJECT_ID(N'tempdb..#tmpCustomerRfq') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCustomerRfq
		END

		CREATE TABLE #tmpCustomerRfq
		(
			ID BIGINT NOT NULL IDENTITY, 
			CustomerRfqId BIGINT NULL,
			RfqId NVARCHAR(400) NULL,
			Condition VARCHAR(256),
			PartNumber VARCHAR(200) NULL,
			BuyerCompanyName VARCHAR(200) NULL,
			MasterCompanyId BIGINT NULL
		)

		INSERT INTO #tmpCustomerRfq (CustomerRfqId,RfqId,Condition,PartNumber,BuyerCompanyName,MasterCompanyId) 
				  SELECT CRFQ.CustomerRfqId,CRFQ.RfqId,CRFQ.Condition,CRFQ.LinePartNumber,CRFQ.BuyerCompanyName,CRFQ.MasterCompanyId
		FROM [DBO].[CustomerRfq] CRFQ WITH(NOLOCK)
		WHERE CRFQ.[IsQuote] IS  NULL
		AND ISNULL(CRFQ.[IsMRO],0) = 1
		ORDER BY CRFQ.CustomerRfqId DESC
		
		SELECT  @MasterLoopID = MAX(ID) FROM #tmpCustomerRfq;
		WHILE(@MasterLoopID > 0)
		BEGIN
			 SELECT @PartNumber = PartNumber,
					@BuyerCompanyName = BuyerCompanyName,
					@MasterCompanyId = MasterCompanyId,
					@CustomerRfqId = CustomerRfqId,
					@RfqId = RfqId,
					@Condition = Condition
			 FROM #tmpCustomerRfq WITH(NOLOCK) 
			 WHERE [ID] = @MasterLoopID;
			 
			 --Get Ai Percent Value from Aisetting table mastercompany wise
			 SELECT @AiPercentValue = ISNULL(SIS.[PercentValue],0), 
					@IsEnableDisableAIintegration = ISNULL(SIS.IsEnableDisableAIintegration,0),
					@Year = ISNULL(YR.[YearName],0),
					@Month = ISNULL(MON.[MonthNumber],0),
					@IsAutoInternalQuote = ISNULL(SIS.IsAutoInternalQuote,0)
			 FROM [DBO].[AiIntegrationSetting]  SIS WITH(NOLOCK) 
			 INNER JOIN [DBO].[Years] YR WITH(NOLOCK) ON SIS.[YearId] = YR.[YearId]
			 INNER JOIN [DBO].[Months] MON WITH(NOLOCK) ON SIS.[MonthId] = MON.[MonthId]
			 WHERE SIS.[MasterCompanyId] = @MasterCompanyId;

			 --Check is allow AI calculation or not
			 IF(@IsEnableDisableAIintegration > 0)
			 BEGIN
				  SELECT @RecordsTotal = COUNT(SOPC.SalesOrderQuotePartId), 
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

					   DECLARE @FinalUnitPrice DECIMAL(18,2) = 0;

					   SET @PerUnitPrice  =  @UnitSalesPriceTotal / @RecordsTotal;

					  -- --Check if PercentValue selected or not
					  -- IF(@AiPercentValue > 0)
					  -- BEGIN
							--SET @FinalUnitPrice  = (@PerUnitPrice * @AiPercentValue) / 100;
							--SET @PerUnitPrice = @PerUnitPrice + @FinalUnitPrice;
					  -- END

					  CREATE TABLE #RFQHistoryResultTest (
							ID INT,
							PartNumber VARCHAR(50),
							Condition VARCHAR(50),
							UnitPrice DECIMAL(18,2),
							Code VARCHAR(50),
							[Sequence] INT,
							QuoteSendReviewId INT,
							QuoteSendReview VARCHAR(50)
					  );

					  --Call For get AI Price
					  INSERT INTO #RFQHistoryResultTest
					  EXEC [dbo].[USP_GetRFQHistoryByPartNumberCondition] @PartNumber,@Condition,@MasterCompanyId;

					  SELECT @PerUnitPrice = [UnitPrice] FROM #RFQHistoryResultTest;

					  -- Clean up
					  DROP TABLE #RFQHistoryResultTest;
					   
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

					 ------- END Update Csutomer RFQ for Is Quote added ----------

					 ---------Create SOQ With part---------------------------------------------
						--Declare type
						DECLARE @RfqQuoteDetails IlsRfqQuoteDetailsType;
					   
					    SELECT @ConditionId = [ConditionId] FROM [DBO].[Condition] WITH(NOLOCK) WHERE  LOWER(TRIM([Description])) = LOWER(TRIM(@Condition)) AND MasterCompanyId= @MasterCompanyId;

						INSERT  INTO @RfqQuoteDetails([CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],[IlsTraceability],[IlsUom],
														[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],
														[IlsComment],[IlsCondition],[ConditionId])
												SELECT [CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],NULL,NULL,
														[IlsPrice],[IlsPriceType],[IlsTagDate],NULL,[IlsMinQty],
														NULL,NULL,@ConditionId
												FROM [dbo].[CustomerRfqQuoteDetails] WHERE [CustomerRfqQuoteId] = @CustomerRfqQuoteId;
	
						DECLARE @ItemMasterId BIGINT = 0,
								@CustomerId BIGINT = 0;

						SELECT @ItemMasterId = [ItemMasterId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE LOWER(TRIM([PartNumber])) = LOWER(TRIM(@PartNumber));
						SELECT @CustomerId = [CustomerId] FROM [dbo].[Customer] WITH(NOLOCK) WHERE LOWER(TRIM([Name])) = LOWER(TRIM(@BuyerCompanyName));

						IF(ISNULL(@ItemMasterId,0) > 0 AND  ISNULL(@CustomerId,0) > 0)
						BEGIN 
							EXEC [dbo].[USP_CreateSalesOrderQuoteFromAI] @RfqQuoteDetails,@CustomerId,@MasterCompanyId,@CreatedBy,2,@CustomerRfqId,@ItemMasterId,0
						END
					 ---------END Create SOQ With part---------------------------------------------
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
			   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100))			                                      
												   + '@Parameter2 = ''' + CAST(ISNULL(@IntegrationTypeId, 0) AS VARCHAR(100)) 
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