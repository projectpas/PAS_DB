/*************************************************************           
 ** File:   [USP_SendMultiILSQuote]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used Send Multiple ILS QUOTE Into Our Database
 ** Purpose:         
 ** Date:   08-08-2025     
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08-08-2025   Amit Ghediya    Created
    2    12-08-2025   Devendra Shekh  Added Changes for Email Integration
   	3    13-08-2025   Rajesh Gami	 Pass the new parameter (USP_CreateSalesOrderQuoteFromAI) @SourceBy,@MarketPlaceRef      
-- EXEC USP_SendMultiILSQuote
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_SendMultiILSQuote]
	@tbl_IlsRfqMultipleQuoteDetailsType IlsRfqMultipleQuoteDetailsType READONLY,
	@LegalEntityId BIGINT,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @GetCustomerRfqId BIGINT, 
				@IsRecordExist BIT = 0,
				@PercentId BIGINT,
				@PercentValue DECIMAL(18,2),
				@RfqQuoteLoopID AS INT,
				@MinRFQId AS INT,
				@CustomerRfqQuoteId BIGINT = NULL,
				@ConditionId BIGINT,
				@Condition VARCHAR(256),
				@SourceBy Varchar(30),
				@MarketplaceRef Varchar(50),
				@IntegrationPortalId INT;
		
		DECLARE @ILSPortalId INT = 1, @OneFortyFivePortalId INT = 2, @EmailPortalId INT = 3;

		DECLARE @ItemMasterId BIGINT = 0,
				@CustomerId BIGINT = 0,
				@PartNumber NVARCHAR(200) = NULL,
				@BuyerCompanyName NVARCHAR(200) = NULL,
				@IsAutoInternalQuote BIT;

		--Get markup % on fly
		SELECT @PercentId = [PercentId],@PercentValue = [PercentValue] FROM [dbo].[AiIntegrationSetting] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;

		SELECT TOP 1 @IntegrationPortalId = IntegrationPortalId FROM @tbl_IlsRfqMultipleQuoteDetailsType;

		--Read all part which from RFQ
		IF OBJECT_ID(N'tempdb..#RfqMultiQuoteDetail') IS NOT NULL
		BEGIN
			DROP TABLE #RfqMultiQuoteDetail
		END

		CREATE TABLE #RfqMultiQuoteDetail
		(
			ID bigint NOT NULL IDENTITY,
			[CustomerRfqId] [bigint] NULL,
			[RfqId] [nvarchar](200) NULL,
			[IlsQty] [int] NULL,
			[IlsTraceability] [varchar](50) NULL,
			[IlsUom] [varchar](50) NULL,
			[IlsPrice] [decimal](10, 2) NULL,
			[IlsPriceType] [varchar](50) NULL,
			[IlsTagDate] [datetime2](7) NULL,
			[IlsLeadTime] [varchar](50) NULL,
			[IlsMinQty] [int] NULL,
			[IlsComment] [varchar](max) NULL,
			[IlsCondition] [varchar](50) NULL,
			[ConditionId] [bigint] NULL,
			[IntegrationPortalId] [int] NULL,
			[CustomerRfqPartMappingId] [bigint] NULL
		)

		INSERT	INTO #RfqMultiQuoteDetail
		([CustomerRfqId],[RfqId],[IlsQty],[IlsTraceability],[IlsUom],[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],[IlsComment],[IlsCondition],[ConditionId],[IntegrationPortalId],[CustomerRfqPartMappingId])
		SELECT [CustomerRfqId],[RfqId],[IlsQty],[IlsTraceability],[IlsUom],[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],[IlsComment],[IlsCondition],[ConditionId],[IntegrationPortalId],[CustomerRfqPartMappingId]
		FROM @tbl_IlsRfqMultipleQuoteDetailsType;

		IF(@ILSPortalId = @IntegrationPortalId)
		BEGIN			
			SELECT @RfqQuoteLoopID = MAX(ID) FROM #RfqMultiQuoteDetail;
			SELECT @MinRFQId = MIN(ID) FROM #RfqMultiQuoteDetail;

			WHILE (@MinRFQId <= @RfqQuoteLoopID)
			BEGIN

				SELECT @GetCustomerRfqId = [CustomerRfqId],
						@Condition = [IlsCondition]
				FROM #RfqMultiQuoteDetail WHERE [ID] = @MinRFQId;

				--Get Condition 
				SELECT @ConditionId = [ConditionId] 
				FROM [DBO].[Condition] WITH(NOLOCK) 
				WHERE  LOWER(TRIM([Description])) = LOWER(TRIM(@Condition)) 
				AND MasterCompanyId= @MasterCompanyId;

				--------------------------- Insert into Rfq Quote table --------------------------------------------------
				INSERT INTO [dbo].[CustomerRfqQuote]
									([CustomerRfqId] ,[RfqId] ,[AddComment] ,[IsAddCommentQuote] ,[FaaEasaRelease] ,[IsFaaEasaReleaseQuote] ,
									[RpOh] ,[IsRpOhQuote] ,[LegalEntityId] ,[MasterCompanyId] ,	
									[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
						SELECT CustomerRfqId,RfqId ,'' ,0 ,'' ,0 ,
								'' ,0 ,@LegalEntityId ,@MasterCompanyId,
								@CreatedBy,@CreatedBy  ,GETUTCDATE(),GETUTCDATE()  ,1 ,0
						FROM #RfqMultiQuoteDetail WHERE ID = @MinRFQId;

				SELECT @CustomerRfqQuoteId = SCOPE_IDENTITY();	

				------------------- Customer RFQ Quote Details add ---------------------------------------------------------
				INSERT INTO [dbo].[CustomerRfqQuoteDetails]
							([CustomerRfqQuoteId] ,[ServiceType] ,IlsQty ,IlsTraceability ,IlsUom ,IlsPrice ,
							IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition, ConditionId,	
							[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted], [PercentId], [PercentValue])
				SELECT @CustomerRfqQuoteId ,0 ,IlsQty ,IlsTraceability ,IlsUom ,IlsPrice ,
							IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition, @ConditionId,	
						@CreatedBy, @CreatedBy ,GETUTCDATE() ,GETUTCDATE() ,1 ,0, @PercentId, @PercentValue
				FROM #RfqMultiQuoteDetail WHERE ID = @MinRFQId;

				------- Update Csutomer RFQ for Is Quote added ----------					 
				UPDATE [dbo].[CustomerRfq] 
					SET [IsQuote] = 1
				WHERE [CustomerRfqId] = @GetCustomerRfqId;

				---------Create SOQ With part---------------------------------------------
				SELECT @PartNumber = [LinePartNumber],
						@BuyerCompanyName = [BuyerCompanyName],  @SourceBy = ISNULL([Type],''),
							   @MarketplaceRef = ISNULL(RfqId,'')
				FROM [dbo].[CustomerRfq] WITH(NOLOCK) 
				WHERE [CustomerRfqId] = @GetCustomerRfqId;

				--Declare type
				DECLARE @RfqQuoteDetails IlsRfqQuoteDetailsType;

				INSERT  INTO @RfqQuoteDetails([CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],[IlsTraceability],[IlsUom],
												[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],
												[IlsComment],[IlsCondition],[ConditionId])
										SELECT [CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],NULL,NULL,
												[IlsPrice],[IlsPriceType],[IlsTagDate],NULL,[IlsMinQty],
												NULL,NULL,@ConditionId
										FROM [dbo].[CustomerRfqQuoteDetails] WHERE [CustomerRfqQuoteId] = @CustomerRfqQuoteId;


				--Get Ai Percent Value from Aisetting table mastercompany wise
				SELECT @IsAutoInternalQuote = ISNULL(SIS.IsAutoInternalQuote,0)
				FROM [DBO].[AiIntegrationSetting]  SIS WITH(NOLOCK) 
				WHERE SIS.[MasterCompanyId] = @MasterCompanyId;

				SELECT @ItemMasterId = [ItemMasterId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE LOWER(TRIM([PartNumber])) = LOWER(TRIM(@PartNumber));
				SELECT @CustomerId = [CustomerId] FROM [dbo].[Customer] WITH(NOLOCK) WHERE LOWER(TRIM([Name])) = LOWER(TRIM(@BuyerCompanyName));						

				IF(ISNULL(@ItemMasterId,0) > 0 AND  ISNULL(@CustomerId,0) > 0 AND ISNULL(@IsAutoInternalQuote,0) > 0)
				BEGIN
						EXEC [dbo].[USP_CreateSalesOrderQuoteFromAI] @RfqQuoteDetails,@CustomerId,@MasterCompanyId,@CreatedBy,2,@GetCustomerRfqId,@ItemMasterId,0,@SourceBy,@MarketplaceRef
				END
												
				---------END Create SOQ With part---------------------------------------------


				SET @MinRFQId = @MinRFQId + 1;
			END
		END
		ELSE IF(@EmailPortalId = @IntegrationPortalId)
		BEGIN

			DECLARE @TotalRow INT, @CurrentRow INT = 0;

			IF OBJECT_ID(N'tempdb..#RfqQuote') IS NOT NULL
			BEGIN
				DROP TABLE #RfqQuote
			END

			CREATE TABLE #RfqQuote
			(
				ID bigint NOT NULL IDENTITY,
				[CustomerRfqId] [bigint] NULL,
				[RfqId] [nvarchar](200) NULL,
				[IntegrationPortalId] [int] NULL 
			)

			INSERT	INTO #RfqQuote
			([CustomerRfqId], [RfqId], [IntegrationPortalId])
			SELECT [CustomerRfqId], [RfqId], [IntegrationPortalId]
			FROM #RfqMultiQuoteDetail
			GROUP BY [CustomerRfqId], [RfqId], [IntegrationPortalId];

			SELECT @TotalRow = MAX(ID), @CurrentRow = MIN(ID) FROM #RfqQuote;

			WHILE (@TotalRow >= @CurrentRow)
			BEGIN
				--------------------------- Insert into Rfq Quote table --------------------------------------------------
				INSERT INTO [dbo].[CustomerRfqQuote]
				([CustomerRfqId] ,[RfqId] ,[AddComment] ,[IsAddCommentQuote] ,[FaaEasaRelease] ,[IsFaaEasaReleaseQuote] ,[RpOh] ,[IsRpOhQuote] ,[LegalEntityId] ,[MasterCompanyId] ,[CreatedBy] ,[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
				SELECT CustomerRfqId,RfqId ,'' ,0 ,'' ,0 ,'' ,0 ,@LegalEntityId ,@MasterCompanyId ,@CreatedBy ,@CreatedBy ,GETUTCDATE() ,GETUTCDATE() ,1 ,0 FROM #RfqQuote WHERE ID = @CurrentRow;

				SELECT @CustomerRfqQuoteId = SCOPE_IDENTITY();	

				TRUNCATE TABLE #RfqMultiQuoteDetail;

				INSERT	INTO #RfqMultiQuoteDetail
				([CustomerRfqId],[RfqId],[IlsQty],[IlsTraceability],[IlsUom],[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],[IlsComment],[IlsCondition],[ConditionId],[IntegrationPortalId],[CustomerRfqPartMappingId])
				SELECT [CustomerRfqId],[RfqId],[IlsQty],[IlsTraceability],[IlsUom],[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],[IlsComment],[IlsCondition],[ConditionId],[IntegrationPortalId],[CustomerRfqPartMappingId]
				FROM @tbl_IlsRfqMultipleQuoteDetailsType
				WHERE [CustomerRfqId] = (SELECT [CustomerRfqId] FROM #RfqQuote WHERE ID = @CurrentRow);
				
				SELECT @RfqQuoteLoopID = MAX(ID), @MinRFQId = MIN(ID) FROM #RfqMultiQuoteDetail;

				WHILE (@MinRFQId <= @RfqQuoteLoopID)
				BEGIN

					SELECT @GetCustomerRfqId = [CustomerRfqId],	@Condition = [IlsCondition]	FROM #RfqMultiQuoteDetail WHERE [ID] = @MinRFQId;

					--Get Condition 
					SELECT @ConditionId = [ConditionId]	FROM [DBO].[Condition] WITH(NOLOCK)	WHERE  LOWER(TRIM([Description])) = LOWER(TRIM(@Condition))	AND MasterCompanyId= @MasterCompanyId;				

					----------------- Customer RFQ Quote Details add ---------------------------------------------------------
					INSERT INTO [dbo].[CustomerRfqQuoteDetails]
					([CustomerRfqQuoteId] ,[ServiceType] ,IlsQty ,IlsTraceability ,IlsUom ,IlsPrice ,IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition ,ConditionId ,[CreatedBy] ,[UpdatedBy] ,
					[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted], [PercentId], [PercentValue],[CustomerRfqPartMappingId])
					SELECT @CustomerRfqQuoteId ,0 ,IlsQty ,IlsTraceability ,IlsUom ,IlsPrice ,IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition, @ConditionId, @CreatedBy, @CreatedBy ,
							GETUTCDATE() ,GETUTCDATE() ,1 ,0, @PercentId, @PercentValue,[CustomerRfqPartMappingId]
					FROM #RfqMultiQuoteDetail WHERE ID = @MinRFQId;

					----- Update Csutomer RFQ for Is Quote added ----------					 
					UPDATE [dbo].[CustomerRfq] 
					SET [IsQuote] = 1
					WHERE [CustomerRfqId] = @GetCustomerRfqId;

					---------Create SOQ With part---------------------------------------------
					SELECT @PartNumber = [LinePartNumber], @BuyerCompanyName = [BuyerCompanyName],  @SourceBy = ISNULL([Type],''),  @MarketplaceRef = ISNULL(RfqId,'') FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @GetCustomerRfqId;

					--Declare type
					DECLARE @EmailRfqQuoteDetails IlsRfqQuoteDetailsType;

					INSERT  INTO @EmailRfqQuoteDetails
					([CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],[IlsTraceability],[IlsUom],[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],[IlsComment],[IlsCondition],[ConditionId])
					SELECT [CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],NULL,NULL,[IlsPrice],[IlsPriceType],[IlsTagDate],NULL,[IlsMinQty],NULL,NULL,@ConditionId
					FROM [dbo].[CustomerRfqQuoteDetails] WHERE [CustomerRfqQuoteId] = @CustomerRfqQuoteId;

					--Get Ai Percent Value from Aisetting table mastercompany wise
					SELECT @IsAutoInternalQuote = ISNULL(SIS.IsAutoInternalQuote,0)
					FROM [DBO].[AiIntegrationSetting]  SIS WITH(NOLOCK) 
					WHERE SIS.[MasterCompanyId] = @MasterCompanyId;

					SELECT @ItemMasterId = [ItemMasterId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE LOWER(TRIM([PartNumber])) = LOWER(TRIM(@PartNumber));
					SELECT @CustomerId = [CustomerId] FROM [dbo].[Customer] WITH(NOLOCK) WHERE LOWER(TRIM([Name])) = LOWER(TRIM(@BuyerCompanyName));						

					IF(ISNULL(@ItemMasterId,0) > 0 AND  ISNULL(@CustomerId,0) > 0 AND ISNULL(@IsAutoInternalQuote,0) > 0)
					BEGIN
						EXEC [dbo].[USP_CreateSalesOrderQuoteFromAI] @EmailRfqQuoteDetails,@CustomerId,@MasterCompanyId,@CreatedBy,2,@GetCustomerRfqId,@ItemMasterId,0,@SourceBy,@MarketplaceRef
					END
												
					-------END Create SOQ With part---------------------------------------------
					SET @MinRFQId = @MinRFQId + 1;
				END

				SET @CurrentRow += 1;
			END			
		END
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			SELECT  
    ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;  
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_SendMultiILSQuote' 
            , @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END