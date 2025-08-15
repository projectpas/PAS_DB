/*************************************************************           
 ** File:   [USP_AutoCreateILSQuoteSyc]           
 ** Author:   Amit Ghediya
 ** Description: Update RFQ Price Details based on AI suggestions
 ** Purpose:         
 ** Date:   14/08/2025
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		  Change Description            
 ** --   --------     -------		  --------------------------------          
    1    14/08/2025   Amit Ghediya    Created

EXEC USP_AutoCreateILSQuoteSyc 129,1
**************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_AutoCreateILSQuoteSyc]
	@MasterCompanyId INT=NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY  	
	
		DECLARE @MasterLoopID INT = 0,
				--@PartNumber NVARCHAR(200) = '0856AE15',
				@CustomerRfqIds BIGINT = 0,
				@RfqId BIGINT = 0,
				@Condition VARCHAR(256),
				@ConditionId BIGINT,
				@CustomerRfqQuoteId BIGINT = 0,
				@PartNumber NVARCHAR(200) = NULL,
				@BuyerCompanyName NVARCHAR(200) = NULL,
				@SalesOrderQuoteId BIGINT = 0,
				@Condition_Code VARCHAR(100) = 'Rejected,Open,Cancelled',
				@AiPercentValue DECIMAL(18,2) = 0,
				@IsEnableDisableAIintegration BIT = 0,
				--@MasterCompanyId INT = 0,
				@UnitSalesPriceTotal DECIMAL(18,2) = 0,
				@RecordsTotal INT = 0,
				@PerUnitPrice DECIMAL(18,2) = 0,
				@QuoteSendReviewId INT = 0,
				@CreatedBy VARCHAR(256) = 'Admin',
				@IsAutoInternalQuote BIT,
				@Month INT,
				@Year INT,
				@Quantity INT;

		--Get FROM SalesOrderQuotePart data for selected part
		IF OBJECT_ID(N'tempdb..#tmpCustomerRfqd') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCustomerRfqd
		END

		CREATE TABLE #tmpCustomerRfqd
		(
			ID BIGINT NOT NULL IDENTITY, 
			CustomerRfqId BIGINT NULL,
			RfqId BIGINT NULL,
			Quantity INT,
			Condition VARCHAR(256),
			PartNumber VARCHAR(200) NULL,
			BuyerCompanyName VARCHAR(200) NULL,
			MasterCompanyId BIGINT NULL,
			CreatedBy VARCHAR(200) NULL
		)

		INSERT INTO #tmpCustomerRfqd (CustomerRfqId,RfqId,Quantity,Condition,PartNumber,BuyerCompanyName,MasterCompanyId,CreatedBy) 
				  SELECT CRFQ.CustomerRfqId,CRFQ.RfqId,CRFQ.Quantity,CRFQ.Condition,CRFQ.LinePartNumber,CRFQ.BuyerCompanyName,CRFQ.MasterCompanyId,CRFQ.CreatedBy
		FROM [DBO].[CustomerRfq] CRFQ WITH(NOLOCK)
		WHERE CRFQ.[IsQuote] IS  NULL
		AND ISNULL(CRFQ.[IsMRO],0) = 1
		AND CRFQ.IntegrationPortalId = 1
		AND CRFQ.MasterCompanyId = @MasterCompanyId
		ORDER BY CRFQ.CustomerRfqId DESC
		
		--select * from #tmpCustomerRfqd

		SELECT  @MasterLoopID = MAX(ID) FROM #tmpCustomerRfqd;
		WHILE(@MasterLoopID > 0)
		BEGIN
			 SELECT @PartNumber = PartNumber,
					@BuyerCompanyName = BuyerCompanyName,
					@MasterCompanyId = MasterCompanyId,
					@CustomerRfqIds = CustomerRfqId,
					@RfqId = RfqId,
					@Quantity = Quantity,
					@Condition = Condition,
					@CreatedBy = CreatedBy
			 FROM #tmpCustomerRfqd WITH(NOLOCK) 
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
					  DECLARE @FinalUnitPrice DECIMAL(18,2) = 0;

					  SELECT @ConditionId  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Code] = @Condition;

					  IF(@ConditionId IS NULL)
					  BEGIN
					  	   SELECT @ConditionId  = [ConditionId] FROM [dbo].[Condition] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [Description] = @Condition;
					  END

					  CREATE TABLE #RFQHistoryResult (
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
					  INSERT INTO #RFQHistoryResult
					  EXEC [dbo].[USP_GetRFQHistoryByPartNumberCondition] @PartNumber,@Condition,@MasterCompanyId;

					  SELECT @PerUnitPrice = [UnitPrice],@QuoteSendReviewId = [QuoteSendReviewId]  FROM #RFQHistoryResult;

					  -- Clean up
					  DROP TABLE #RFQHistoryResult;

					  -- SET @PerUnitPrice  =  @UnitSalesPriceTotal / @RecordsTotal;

					  -- --Check if PercentValue selected or not
					  -- IF(@AiPercentValue > 0)
					  -- BEGIN
							--SET @FinalUnitPrice  = (@PerUnitPrice * @AiPercentValue) / 100;
							--SET @PerUnitPrice = @PerUnitPrice + @FinalUnitPrice;
					  -- END
					   
					   ---------------------------Start Insert into Rfq Quote table --------------------------------------------------
					  IF NOT EXISTS(SELECT TOP 1 CustomerRfqQuoteId FROM [dbo].[CustomerRfqQuote] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqIds )
					  BEGIN
						   INSERT INTO [dbo].[CustomerRfqQuote]
											   ([CustomerRfqId] ,[RfqId] ,[AddComment] ,[IsAddCommentQuote] ,[FaaEasaRelease] ,[IsFaaEasaReleaseQuote] ,
												[RpOh] ,[IsRpOhQuote] ,[LegalEntityId] ,[MasterCompanyId] ,	
												[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
									VALUES (@CustomerRfqIds ,@RfqId ,'' ,0 ,'' ,0,
										   '' ,0,1,@MasterCompanyId,
										   @CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE()  ,1 ,0);

						 SET @CustomerRfqQuoteId = SCOPE_IDENTITY();	
					 END
					 
					  ---------------------------End Insert into Rfq Quote table --------------------------------------------------

					  -------------------Start Customer RFQ Quote Details add ---------------------------------------------------------
					  IF(@CustomerRfqQuoteId > 0)
					  BEGIN
							IF NOT EXISTS(SELECT TOP 1 CustomerRfqQuoteId FROM [dbo].[CustomerRfqQuoteDetails] WITH(NOLOCK) WHERE [CustomerRfqQuoteId] = @CustomerRfqQuoteId AND [ConditionId] = @ConditionId)
							BEGIN
							
								   INSERT INTO [dbo].[CustomerRfqQuoteDetails]
						   				   ([CustomerRfqQuoteId] ,[ServiceType] ,IlsQty ,IlsTraceability ,IlsUom ,IlsPrice ,
						   					IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition,	
						   					[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted], [ConditionId])
								   VALUES(@CustomerRfqQuoteId ,0 ,@Quantity ,0078 ,1 ,@PerUnitPrice ,
											'Outright' ,GETUTCDATE() ,0 ,0 ,NULL,@Condition,	
										  @CreatedBy,@CreatedBy,GETUTCDATE() ,GETUTCDATE() ,1 ,0,@ConditionId)
							 END
					  END

					  
					  -------------------End Customer RFQ Quote Details add ---------------------------------------------------------

					  ------- Update Csutomer RFQ for Is Quote added ----------					 
						 UPDATE [dbo].[CustomerRfq] 
							SET IsQuote = 1,
							    QuotedBy = @CreatedBy,
								QuotedDate = GETUTCDATE(),
								QuoteSendReviewId = @QuoteSendReviewId
						 WHERE [CustomerRfqId] = @CustomerRfqIds;

					 ------- END Update Csutomer RFQ for Is Quote added ----------

			 END

			 SET @MasterLoopID = @MasterLoopID - 1;
		END

		--SELECT * FROM #tmpCustomerRfqd;
		

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'            
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AutoCreateILSQuoteSyc'             
			   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))			                                      
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