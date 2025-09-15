/*************************************************************           
 ** File:   [usp_SaveEmailRFQ]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used save the RFQs Received on Email
 ** Purpose:         
 ** Date:   06 Aug 2025
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    06 Aug 2025	Devendra Shekh		Created
    2    07 Aug 2025	Devendra Shekh		Added Changes for PartDetails Insert and RFQNumber Generate
    3    13 Aug 2025	Devendra Shekh		Added Changes To Process Send Quote Based on [AiIntegrationSetting]
    4    14 Aug 2025	Devendra Shekh		Added Changes To for AutoQuotePrice
    5    15 Aug 2025	Devendra Shekh		Added Changes To check Part/Customer are in tables or not before quote
	6    19 Aug 2025	Moin Bloch		    Returns CustomerRfqId
	7    22 Aug 2025	Devendra Shekh		Modified (added to No Quote if condition not matched or QuoteSendReviewId is 0)
	8    26 Aug 2025	Devendra Shekh		Modified (added @EmployeeId Param)
	9    27 Aug 2025	Devendra Shekh		Modified (price decimal issue when autoquote resolved)
	10	 27 Aug 2025	Devendra Shekh		Modified (select employee from LegalEntity or Employee Table if @EmployeeId is null or 0)

************************************************************************/
CREATE   PROCEDURE [dbo].[usp_SaveEmailRFQ]
	@IntegrationEmailID BIGINT = NULL,
    @tbl_RfqCustomerType dbo.RfqCustomerType READONLY,
    @tbl_RfqPartDetailType dbo.RfqPartDetailType READONLY,
	@EmployeeId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	--BEGIN TRANSACTION;
	BEGIN TRY
	BEGIN
		DECLARE @CustomerRfqId BIGINT;

		IF EXISTS(SELECT 1 FROM @tbl_RfqPartDetailType)
		BEGIN
			DECLARE @CreatedBy VARCHAR(100), @MasterCompanyId INT;
			DECLARE @TotalRow INT, @CurrentRow INT = 1;
			DECLARE @CodeTypeId BIGINT, @CurrentNumber BIGINT = 0, @RFQNumber NVARCHAR(200);
			DECLARE @ALlowProcessQuote BIT = 1;
			DECLARE @EmailRfqQuoteDetailsType EmailRfqQuoteDetailsType;

			IF OBJECT_ID(N'tempdb..#tmpCodePrefix') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCodePrefix
			END

			IF OBJECT_ID(N'tempdb..#tmpCustomerRfq') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCustomerRfq
			END

			CREATE TABLE #tmpCustomerRfq
			(
				ID BIGINT NOT NULL IDENTITY, 
				[RfqId] NVARCHAR(200) NULL,
				[RfqCreatedDate] [DATETIME2](7) NULL,
				[IntegrationPortalId] [int] NULL,
				[Type] [VARCHAR](50) NULL,
				[Notes] [VARCHAR](MAX) NULL,
				[BuyerName] [VARCHAR](250) NULL,
				[BuyerCompanyName] [VARCHAR](250) NULL,
				[BuyerAddress] [VARCHAR](250) NULL,
				[BuyerCity] [VARCHAR](50) NULL,
				[BuyerCountry] [VARCHAR](50) NULL,
				[BuyerState] [VARCHAR](50) NULL,
				[BuyerZip] [VARCHAR](50) NULL,
				[LinePartNumber] [VARCHAR](250) NULL,
				[LineDescription] [VARCHAR](500) NULL,
				[CreatedBy] [VARCHAR](50) NOT NULL,
				[CreatedDate] [datetime2](7) NOT NULL,
				[UpdatedBy] [VARCHAR](50) NOT NULL,
				[UpdatedDate] [DATETIME2](7) NOT NULL,
				[IsActive] [BIT] NOT NULL,
				[IsDeleted] [BIT] NOT NULL,
				[AltPartNumber] [VARCHAR](250) NULL,
				[Quantity] [int] NULL,
				[Condition] [varchar](250) NULL,
				[IsMRO] [bit] NULL,
				[IntegrationEmailID] [bigint] NULL
			)
			
			SELECT @CreatedBy = [CreatedBy], @MasterCompanyId = [MasterCompanyId] FROM [dbo].[IntegrationEmail] WITH(NOLOCK) WHERE [IntegrationEmailID] = @IntegrationEmailID;
			SELECT TOP 1 @CodeTypeId = CodeTypeId FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'CustomerRFQ';
			SELECT TOP 1 * INTO #tmpCodePrefix FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE ISNULL([IsActive],0) = 1 AND ISNULL([IsDeleted],0) = 0 AND [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId;

			IF(ISNULL(@EmployeeId, 0) = 0)
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[LegalEntity] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(EmployeeId, 0) > 0)
				BEGIN
					SET @EmployeeId = (SELECT TOP 1 EmployeeId FROM [dbo].[LegalEntity] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(EmployeeId, 0) > 0)
				END
				ELSE IF EXISTS(SELECT 1 FROM [dbo].[Employee] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0 AND UPPER(TRIM([FirstName])) = 'ADMIN')
				BEGIN
					SET @EmployeeId = (SELECT TOP 1 EmployeeId FROM [dbo].[Employee] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0 AND UPPER(TRIM([FirstName])) = 'ADMIN')
				END
			END

			IF(ISNULL(@EmployeeId, 0) > 0)
			BEGIN
				SELECT @CreatedBy = CONCAT(FirstName, ' ' , LastName) FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @EmployeeId;
			END
			
			-- Determine the current number
			IF EXISTS (SELECT 1 FROM #tmpCodePrefix)
			BEGIN
				IF (SELECT CurrentNummber FROM #tmpCodePrefix) > 0
				BEGIN
					SET @CurrentNumber = (SELECT CurrentNummber FROM #tmpCodePrefix);
				END
				ELSE
				BEGIN
					SET @CurrentNumber = CASE WHEN (SELECT StartsFrom FROM #tmpCodePrefix) > 0 THEN (SELECT StartsFrom FROM #tmpCodePrefix) ELSE (SELECT StartsFrom FROM #tmpCodePrefix) + 1 END;
				END				

				-- Generate CustomerRFQNumber
				SET @RFQNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNumber, (SELECT CodePrefix FROM #tmpCodePrefix), (SELECT CodeSufix FROM #tmpCodePrefix)));
			END
			ELSE
			BEGIN
				-- Generate CustomerRFQNumber without prefix/suffix
				SET @RFQNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](0, '', ''));
			END
			
			-- Saving Part Details to Temp Table
			INSERT INTO #tmpCustomerRfq ([RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes], [BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity],
			[BuyerCountry], [BuyerState], [BuyerZip], [LinePartNumber], [LineDescription], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted],
			[AltPartNumber], [Quantity], [Condition], [IsMRO], [IntegrationEmailID])
			SELECT	@RFQNumber, GETUTCDATE(), [IntegrationPortalId], [Type], [Notes], '', '', '', '',
					'', '', '', [PartNumber], [PartDescription], @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0,
					[AlternatePart], [Quantity], [Condition], ISNULL([IsMRO], 1), [IntegrationEmailID]
			FROM @tbl_RfqPartDetailType;

			-- Updating Customer/Email Sender Details
			UPDATE TMP
			SET	
				TMP.[BuyerName] = CU.[BuyerName],
				TMP.[BuyerCompanyName] = CU.[CompanyName],
				TMP.[BuyerAddress] = CU.[Address],
				TMP.[BuyerCity] = CU.[City],
				TMP.[BuyerState] = CU.[State],
				TMP.[BuyerZip] = CU.[Zip],
				TMP.[BuyerCountry] = CU.[Country]
			FROM #tmpCustomerRfq TMP
			INNER JOIN @tbl_RfqCustomerType CU ON TMP.[IntegrationEmailID] = CU.[IntegrationEmailID];

			-- Insert into Rfq table
			INSERT INTO [dbo].[CustomerRfq]
			(	[RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes], [BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity], [BuyerCountry], [BuyerState],
				[BuyerZip], [LinePartNumber], [LineDescription], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
				[AltPartNumber], [Quantity], [Condition], [IsMRO])
			SELECT	[RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes], [BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity], [BuyerCountry], [BuyerState],
					[BuyerZip], [LinePartNumber], [LineDescription], @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,
					[AltPartNumber], [Quantity], [Condition], [IsMRO]
			FROM #tmpCustomerRfq WHERE ID = @CurrentRow;

			SET @CustomerRfqId = SCOPE_IDENTITY();

			IF(ISNULL(@CustomerRfqId, 0) > 0)
			BEGIN
				-- Save CustomerRFQ Part Details
				INSERT INTO [dbo].[CustomerRfqPartMapping] 
				(	[CustomerRfqId], [Notes], [PartNumber], [PartDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]) 
				SELECT	@CustomerRfqId, [Notes], [LinePartNumber], [LineDescription], [AltPartNumber], [Quantity], [Condition], @MasterCompanyId, @CreatedBy,  GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0
				FROM #tmpCustomerRfq;

				-- Update CodeData with new current number
				UPDATE [dbo].[CodePrefixes]	SET [CurrentNummber] = @CurrentNumber + 1	WHERE [CodePrefixId] = (SELECT CodePrefixId FROM #tmpCodePrefix);
			END
		END

		UPDATE [DBO].[IntegrationEmail] SET [CustomerRfqId] = @CustomerRfqId, [IsProcessed] = 1 WHERE IntegrationEmailID = @IntegrationEmailID;

		--Save Send Quote
		IF(ISNULL(@CustomerRfqId, 0) > 0)
		BEGIN
			DECLARE @TotalQuoteRow INT, @CurrentQuoteRow INT;
			DECLARE @CustomerRfqPartMappingId BIGINT, @Condition VARCHAR(250), @PartNumber VARCHAR(250);
			DECLARE @QuoteSendReviewId INT = 0, @UnitPrice DECIMAL(18,2) = 0, @DefaultUnitPrice DECIMAL(18,2) = 0;
			
			IF OBJECT_ID(N'tempdb..#tmpQuote') IS NOT NULL
			BEGIN
				DROP TABLE #tmpQuote
			END

			IF OBJECT_ID('tempdb..#tmpRFQDetails') IS NOT NULL
			BEGIN
				DROP TABLE #tmpRFQDetails;
			END

			CREATE TABLE #tmpRFQDetails
			(
				customerRfqId INT,
				rfqId NVARCHAR(400),
				partNumber VARCHAR(100),
				masterCompanyId INT,
				ilsPrice DECIMAL(18, 2)
			);

			IF OBJECT_ID(N'tempdb..#tmpRFQPriceResult') IS NOT NULL
			BEGIN
				DROP TABLE #tmpRFQPriceResult
			END

			CREATE TABLE #tmpRFQPriceResult
			(
				[ID] BIGINT NULL, 
				[PartNumber] VARCHAR(50) NULL,
				[Condition] VARCHAR(50) NULL,
				[UnitPrice] DECIMAL(18,2) NULL,
				[Code] VARCHAR(50) NULL,
				[Sequence] Int NULL,
				[QuoteSendReviewId] Int NULL,
				[QuoteSendReview] VARCHAR(50) NULL,
			)

			SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, [CustomerRfqPartMappingId], [CustomerRfqId], [Notes], [PartNumber], [PartDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId],
					0 AS [ConditionId], @DefaultUnitPrice AS [Price], 0 AS [ItemMasterId], 0 AS [CustomerId], 0 AS QuoteSendReviewId
			INTO #tmpQuote
			FROM [dbo].[CustomerRfqPartMapping] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;

			SELECT @TotalQuoteRow = MAX(RowId), @CurrentQuoteRow = MIN(RowId) FROM #tmpQuote;

			WHILE(@TotalQuoteRow >= @CurrentQuoteRow) AND ISNULL(@TotalQuoteRow, 0) > 0
			BEGIN

				SELECT @CustomerRfqPartMappingId = CustomerRfqPartMappingId, @PartNumber = PartNumber, @Condition = Condition FROM #tmpQuote WHERE RowId = @CurrentQuoteRow;

				TRUNCATE TABLE #tmpRFQPriceResult

				INSERT INTO #tmpRFQPriceResult
				EXEC [dbo].[USP_GetRFQHistoryByPartNumberCondition] @PartNumber, @Condition, @MasterCompanyId;

				SELECT @UnitPrice = ISNULL(UnitPrice, 0), @QuoteSendReviewId = QuoteSendReviewId FROM #tmpRFQPriceResult;
				 
				UPDATE TMP
				SET	TMP.[Price] = @UnitPrice,
					TMP.ConditionId = ISNULL(A.ConditionId, 0),
					TMP.QuoteSendReviewId = ISNULL(@QuoteSendReviewId, 0)
				FROM #tmpQuote TMP 
				OUTER APPLY (
					SELECT TOP 1 CD.ConditionId
					FROM [dbo].[Condition] CD WITH(NOLOCK) 
					WHERE ((LOWER(TRIM(CD.[Description])) = LOWER(TRIM(TMP.Condition))) OR (LOWER(TRIM(CD.[Code])) = LOWER(TRIM(TMP.Condition)))) AND CD.MasterCompanyId = TMP.MasterCompanyId
				) A
				WHERE RowId = @CurrentQuoteRow;

				--TRUNCATE TABLE #tmpRFQDetails;
				----Get price based on rfqId
				--INSERT INTO #tmpRFQDetails
				--EXEC [dbo].[usp_GetRFQPriceSuggestionDetails] @CustomerRfqId, @MasterCompanyId, @CustomerRfqPartMappingId;

				--UPDATE TMP
				--SET	TMP.[Price] = (SELECT ISNULL(ilsPrice,0) FROM #tmpRFQDetails),
				--	TMP.ConditionId = A.ConditionId
				--FROM #tmpQuote TMP 
				--OUTER APPLY (
				--	SELECT TOP 1 CD.ConditionId
				--	FROM [dbo].[Condition] CD WITH(NOLOCK) 
				--	WHERE CD.[Description] = TMP.Condition AND CD.MasterCompanyId = TMP.MasterCompanyId
				--) A
				--WHERE RowId = @CurrentQuoteRow;

				SET @CurrentQuoteRow += 1;
			END

			UPDATE TMP
			SET TMP.ItemMasterId = CASE WHEN ISNULL(IM.ItemMasterId, 0) > 0 THEN IM.ItemMasterId ELSE 0 END,
				TMP.CustomerId = CASE WHEN ISNULL(CS.CustomerId, 0) > 0 THEN CS.CustomerId ELSE 0 END
			FROM #tmpQuote TMP
			LEFT JOIN dbo.[CustomerRfq] RFQ WITH(NOLOCK) ON TMP.[CustomerRfqId] = RFQ.[CustomerRfqId]
			LEFT JOIN dbo.[ItemMaster] IM WITH(NOLOCK) ON LOWER(TRIM(IM.partnumber)) = LOWER(TRIM(TMP.PartNumber)) AND IM.MasterCompanyId = TMP.MasterCompanyId AND IM.IsActive = 1 AND IM.IsDeleted = 0
			LEFT JOIN dbo.[Customer] CS WITH(NOLOCK) ON (LOWER(TRIM(CS.[Name])) = LOWER(TRIM(RFQ.[BuyerCompanyName])) OR (CS.CustomerId = RFQ.CustomerId)) AND CS.MasterCompanyId = TMP.MasterCompanyId AND CS.IsActive = 1 AND CS.IsDeleted = 0

			IF EXISTS(SELECT 1 FROM #tmpQuote WHERE ISNULL(ItemMasterId, 0) = 0 OR ISNULL(CustomerId, 0) = 0 OR ISNULL(ConditionId, 0) = 0 OR ISNULL(QuoteSendReviewId, 0) = 0)
			BEGIN
				SET @ALlowProcessQuote = 0;
			END

			IF(@ALlowProcessQuote > 0)
			BEGIN
				INSERT INTO @EmailRfqQuoteDetailsType
				(	[CustomerRfqQuoteDetailsId], [CustomerRfqQuoteId], [ServiceType], [QuotePrice], [QuoteTat], [Low], [Mid], [AvgTat], [QuoteTatQty], [QuoteCond], [QuoteTrace], [IlsQty],
					[IlsTraceability], [IlsUom], [IlsPrice], [IlsPriceType], [IlsTagDate], [IlsLeadTime], [IlsMinQty], [IlsComment], [IlsCondition], [ConditionId], [CustomerRfqPartMappingId], [QuoteSendReviewId]
				)
				SELECT	0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', [Quantity],
						'', '', [Price], '', NULL, '', 0, '', [Condition], [ConditionId], [CustomerRfqPartMappingId], [QuoteSendReviewId]
				FROM #tmpQuote;

				EXEC [dbo].[usp_SaveEmailQuote] @EmailRfqQuoteDetailsType, 0, @CustomerRfqId, @RFQNumber, 0, @MasterCompanyId, @CreatedBy, @QuoteSendReviewId, @EmployeeId;
			END
		END

		SELECT @CustomerRfqId AS [CUSTOMERRFQID]
	END		
	--COMMIT
	END TRY	
	BEGIN CATCH      
		--IF @@trancount > 0
		--	ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_SaveEmailRFQ' 
		, @ProcedureParameters VARCHAR(3000) = '@IntegrationEmailID = ''' + CAST(ISNULL(@IntegrationEmailID, '') as varchar(100))
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