/*************************************************************           
 ** File:   [usp_SaveEmailQuote]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used Send ILS QUOTE Into Our Database
 ** Purpose:         
 ** Date:   08 Aug 2025      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    08 Aug 2025	Devendra Shekh		Created
    2    13 Aug 2025	Devendra Shekh		Added Changes to Create SOQ
	3    13-08-2025		Rajesh Gami			Pass the new parameter (USP_CreateSalesOrderQuoteFromAI) @SourceBy,@MarketPlaceRef        
	4    14-08-2025		Devendra Shekh		Pass the new parameter (USP_CreateSalesOrderQuoteFromAI) @QuoteSendReviewId   
	5	 15-08-2025		Devendra Shekh		Removed @IsAutoInternalQuote, Added [QuoteSendReviewId] select
	7    15/08/2025     Moin Bloch          Added @SoqId OUTPUT Param
	8	 18-08-2025		Bhargav Saliya		Added [ExpirationDate]
	9    18-08-2025     Devendra Shekh		Handling New Part Add While Update
   10    18-Aug-2025    Amit Ghediya        Update RFQ SOQ Price.
   11    21-Aug-2025    Devendra Shekh		Checking customerId in CustomerRFQ for @CustomerId
   12	 22-Aug-2025    Devendra Shekh		Modified (set @QuoteReviewRequiredId based on Review Required)
   13    26 Aug 2025	Devendra Shekh		Modified (added @EmployeeId Param)
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_SaveEmailQuote]
	@tbl_EmailRfqQuoteDetailsType EmailRfqQuoteDetailsType READONLY,
	@CustomerRfqQuoteId BIGINT = NULL,
	@CustomerRfqId BIGINT,
	@RfqId NVARCHAR(200) NULL,
	@LegalEntityId BIGINT,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200),
	@QuoteSendReviewId INT = NULL,
	@EmployeeId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
	    DECLARE @SalesOrderQuoteId BIGINT = 0;
		DECLARE @GetCustomerRfqId BIGINT, @PercentId BIGINT, @PercentValue DECIMAL(18,2),@SourceBy Varchar(30),@MarketplaceRef Varchar(50);
		DECLARE @QuoteReviewRequiredId BIGINT = 0, @Code VARCHAR(50) = 'Review Required', @CreateSOQ BIT = 1;

		--Get markup % on fly
		SELECT @PercentId = [PercentId],@PercentValue = [PercentValue] FROM [dbo].[AiIntegrationSetting] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
		SET @EmployeeId = CASE WHEN ISNULL(@EmployeeId, 0) > 0 THEN @EmployeeId ELSE 2 END;

		IF(ISNULL(@LegalEntityId, 0) = 0 AND ISNULL(@EmployeeId, 0) > 0)
		BEGIN
			SELECT @LegalEntityId = [LegalEntityId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @EmployeeId;
		END

		SELECT @QuoteReviewRequiredId = QuoteSendReviewId FROM [dbo].[QuoteSendReview] WITH(NOLOCK) WHERE [Code] = @Code;
		IF EXISTS(SELECT 1 FROM @tbl_EmailRfqQuoteDetailsType WHERE ISNULL([QuoteSendReviewId], 0) = @QuoteReviewRequiredId OR ISNULL([QuoteSendReviewId], 0) = 0)
		BEGIN
			SET @QuoteSendReviewId = @QuoteReviewRequiredId;
		END
		ELSE
		BEGIN
			SET @QuoteSendReviewId = (SELECT TOP 1 [QuoteSendReviewId] FROM @tbl_EmailRfqQuoteDetailsType);
		END

		IF(@CustomerRfqQuoteId > 0)
		BEGIN
			UPDATE [dbo].[CustomerRfqQuote] SET UpdatedBy = @CreatedBy, UpdatedDate = GETUTCDATE() WHERE CustomerRfqQuoteId = @CustomerRfqQuoteId;

			UPDATE CRQ 
			SET
				CRQ.IlsQty = TMP.IlsQty,
				CRQ.IlsTraceability = TMP.IlsTraceability,
				CRQ.IlsUom = TMP.IlsUom,
				CRQ.IlsPrice = TMP.IlsPrice,
				CRQ.IlsPriceType = TMP.IlsPriceType,
				CRQ.IlsTagDate = TMP.IlsTagDate,
				CRQ.IlsLeadTime = TMP.IlsLeadTime,
				CRQ.IlsMinQty = TMP.IlsMinQty,
				CRQ.IlsComment = TMP.IlsComment,
				CRQ.IlsCondition = TMP.IlsCondition,
				CRQ.UpdatedBy = @CreatedBy,
				CRQ.UpdatedDate = GETUTCDATE(),
				CRQ.[ExpirationDate] = TMP.[ExpirationDate]
			FROM dbo.CustomerRfqQuoteDetails CRQ
			INNER JOIN @tbl_EmailRfqQuoteDetailsType TMP ON CRQ.CustomerRfqQuoteDetailsId = TMP.CustomerRfqQuoteDetailsId

			------------------- Customer RFQ Quote Details add ---------------------------------------------------------

			INSERT INTO [dbo].[CustomerRfqQuoteDetails]
			(	[CustomerRfqQuoteId], [ServiceType], IlsQty, IlsTraceability, IlsUom, IlsPrice,
				IlsPriceType, IlsTagDate, IlsLeadTime, IlsMinQty, IlsComment, IlsCondition, ConditionId, [CustomerRfqPartMappingId],	
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [PercentId], [PercentValue],[ExpirationDate])
			SELECT	@CustomerRfqQuoteId, 0, IlsQty, IlsTraceability, IlsUom, IlsPrice,
					IlsPriceType, IlsTagDate, IlsLeadTime, IlsMinQty, IlsComment, IlsCondition, ConditionId, [CustomerRfqPartMappingId],	
					@CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @PercentId, @PercentValue,[ExpirationDate]
			FROM @tbl_EmailRfqQuoteDetailsType WHERE ISNULL(CustomerRfqQuoteDetailsId, 0) = 0;

			--Declare type
			DECLARE @IlsRfqQuoteDetailsTypes IlsRfqQuoteDetailsType;

			INSERT  INTO @IlsRfqQuoteDetailsTypes
			([CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],[IlsTraceability],[IlsUom],[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],[IlsComment],[IlsCondition],[ConditionId],[ItemMasterId])
			SELECT [CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],NULL,NULL,[IlsPrice],[IlsPriceType],[IlsTagDate],NULL,[IlsMinQty],NULL,NULL,ConditionId,0
			FROM @tbl_EmailRfqQuoteDetailsType;

			------Update RFQ SOQ Data--------------------------
			EXEC [dbo].[USP_UpdateRFQQuoteDetails] @IlsRfqQuoteDetailsTypes,@CustomerRfqQuoteId,@CustomerRfqId,@RfqId,@MasterCompanyId,@CreatedBy
		END
		ELSE
		BEGIN
			--------------------------- Insert into Rfq Quote table --------------------------------------------------
			INSERT INTO [dbo].[CustomerRfqQuote]
			(	[CustomerRfqId], [RfqId], [AddComment], [IsAddCommentQuote], [FaaEasaRelease], [IsFaaEasaReleaseQuote],
				[RpOh], [IsRpOhQuote], [LegalEntityId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES	(@CustomerRfqId, @RfqId, '', 0, '', 0,
					'', 0, @LegalEntityId, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1,0);

			SELECT @CustomerRfqQuoteId = SCOPE_IDENTITY();	
		
			------------------- Customer RFQ Quote Details add ---------------------------------------------------------

			INSERT INTO [dbo].[CustomerRfqQuoteDetails]
			(	[CustomerRfqQuoteId], [ServiceType], IlsQty, IlsTraceability, IlsUom, IlsPrice,
				IlsPriceType, IlsTagDate, IlsLeadTime, IlsMinQty, IlsComment, IlsCondition, ConditionId, [CustomerRfqPartMappingId],	
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [PercentId], [PercentValue],[ExpirationDate])
			SELECT	@CustomerRfqQuoteId, 0, IlsQty, IlsTraceability, IlsUom, IlsPrice,
					IlsPriceType, IlsTagDate, IlsLeadTime, IlsMinQty, IlsComment, IlsCondition, ConditionId, [CustomerRfqPartMappingId],	
					@CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @PercentId, @PercentValue,[ExpirationDate]
			FROM @tbl_EmailRfqQuoteDetailsType;

			------- Update Csutomer RFQ for Is Quote added ----------					 
			UPDATE [dbo].[CustomerRfq] 
			SET IsQuote = 1,
				QuotedBy = @CreatedBy,
				QuotedDate = GETUTCDATE(),
				QuoteSendReviewId = @QuoteSendReviewId
			WHERE CustomerRfqId = @CustomerRfqId;

			IF(ISNULL(@CustomerRfqId, 0) > 0 AND ISNULL(@CustomerRfqQuoteId, 0) > 0)
			BEGIN
				DECLARE @ItemMasterId BIGINT = 0,
						@CustomerId BIGINT = 0,
						@RfqCustomerId BIGINT = 0,
						@PartNumber NVARCHAR(200) = NULL,
						@BuyerCompanyName NVARCHAR(200) = NULL;
				
				IF OBJECT_ID(N'tempdb..#tmpCustomerRfqQuoteDetails') IS NOT NULL
				BEGIN
					DROP TABLE #tmpCustomerRfqQuoteDetails
				END

				CREATE TABLE  #tmpCustomerRfqQuoteDetails (
					[RowId] [bigint] IDENTITY(1,1) NOT NULL,
					[CustomerRfqQuoteDetailsId] [bigint] NULL,
					[CustomerRfqQuoteId] [bigint] NULL,
					[IlsQty] [int] NULL,
					[IlsTraceability] [varchar](50) NULL,
					[IlsUom] [varchar](50) NULL,
					[IlsPrice] [decimal](18, 2) NULL,
					[IlsPriceType] [varchar](50) NULL,
					[IlsTagDate] [datetime2](7) NULL,
					[IlsLeadTime] [varchar](50) NULL,
					[IlsMinQty] [int] NULL,
					[IlsComment] [varchar](max) NULL,
					[IlsCondition] [varchar](50) NULL,
					[ConditionId] [bigint] NULL,
					[CustomerRfqPartMappingId] [bigint] NULL,
					[ItemMasterId] [bigint] NULL,
				)

				INSERT  INTO #tmpCustomerRfqQuoteDetails
				([CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],[IlsTraceability],[IlsUom],[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],[IlsComment],[IlsCondition],[ConditionId],[CustomerRfqPartMappingId],[ItemMasterId])
				SELECT [CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],NULL,NULL,[IlsPrice],[IlsPriceType],[IlsTagDate],NULL,[IlsMinQty],NULL,NULL,ConditionId,[CustomerRfqPartMappingId],0
				FROM [dbo].[CustomerRfqQuoteDetails] WITH(NOLOCK) WHERE [CustomerRfqQuoteId] = @CustomerRfqQuoteId;

				UPDATE TMP
				SET	TMP.ItemMasterId = IM.ItemMasterId
				FROM #tmpCustomerRfqQuoteDetails TMP
				LEFT JOIN dbo.[CustomerRfqPartMapping] CRPM WITH(NOLOCK) ON CRPM.CustomerRfqPartMappingId = TMP.CustomerRfqPartMappingId
				LEFT JOIN dbo.[ItemMaster] IM WITH(NOLOCK) ON LOWER(TRIM(IM.partnumber)) = LOWER(TRIM(CRPM.PartNumber)) AND IM.MasterCompanyId = CRPM.MasterCompanyId AND IM.IsActive = 1 AND IM.IsDeleted = 0
				
				--Create SOQ
				SELECT @PartNumber = [LinePartNumber], @BuyerCompanyName = [BuyerCompanyName], @SourceBy = ISNULL([Type],''),  @MarketplaceRef = ISNULL(RfqId,''), @RfqCustomerId = [CustomerId] FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;

				--Declare type
				DECLARE @EmailRfqQuoteDetails IlsRfqQuoteDetailsType;

				INSERT  INTO @EmailRfqQuoteDetails
				([CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],[IlsTraceability],[IlsUom],[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],[IlsComment],[IlsCondition],[ConditionId],[ItemMasterId])
				SELECT [CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],NULL,NULL,[IlsPrice],[IlsPriceType],[IlsTagDate],NULL,[IlsMinQty],NULL,NULL,ConditionId,[ItemMasterId]
				FROM #tmpCustomerRfqQuoteDetails;
				--FROM [dbo].[CustomerRfqQuoteDetails] WITH(NOLOCK) WHERE [CustomerRfqQuoteId] = @CustomerRfqQuoteId;

				SELECT @ItemMasterId = [ItemMasterId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE LOWER(TRIM([PartNumber])) = LOWER(TRIM(@PartNumber)) AND [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;
				SELECT @CustomerId = [CustomerId] FROM [dbo].[Customer] WITH(NOLOCK) WHERE LOWER(TRIM([Name])) = LOWER(TRIM(@BuyerCompanyName)) AND [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;						
				SET @CustomerId = CASE WHEN ISNULL(@RfqCustomerId, 0) > 0 THEN @RfqCustomerId ELSE @CustomerId END;

				IF EXISTS(SELECT 1 FROM #tmpCustomerRfqQuoteDetails WHERE ISNULL(ItemMasterId, 0) = 0 OR ISNULL(ConditionId, 0) = 0)
				BEGIN
					SET @CreateSOQ = 0;
				END

				IF(ISNULL(@CreateSOQ,0) > 0 AND ISNULL(@CustomerId,0) > 0)
				BEGIN
					EXEC [dbo].[USP_CreateSalesOrderQuoteFromAI] @EmailRfqQuoteDetails,@CustomerId,@MasterCompanyId,@CreatedBy,@EmployeeId,@CustomerRfqId,@ItemMasterId,0,@SourceBy,@MarketplaceRef,@QuoteSendReviewId,@SalesOrderQuoteId OUTPUT
				END
			END
		END

		SET @SalesOrderQuoteId = CASE WHEN @QuoteSendReviewId = @QuoteReviewRequiredId THEN 0 ELSE @SalesOrderQuoteId END;

		SELECT @SalesOrderQuoteId AS SOQID
	END			
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_SaveEmailQuote' 
            , @ProcedureParameters VARCHAR(3000) = '@CustomerRfqId = ''' + CAST(ISNULL(@CustomerRfqId, '') as varchar(100))
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