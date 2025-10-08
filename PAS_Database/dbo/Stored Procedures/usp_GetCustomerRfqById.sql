/*************************************************************             
 ** File:   [usp_GetCustomerRFQbyId]             
 ** Author:   Devendra Shekh    
 ** Description: Get Customer RFQ Details By Id
 ** Date:   01-Aug-2025 
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO	Date			Author				Change Description              
 ** --		--------		-------				--------------------------------            
 **	1		01-Aug-2025		Devendra Shekh		Created
 **	2		07-Aug-2025		Devendra Shekh		Added [CustomerRfqPartMapping] select
 **	3		14-Aug-2025		Bhargav Saliya		Added [PriorityId] and [ExpirationDate] 
 **	4		25-Sep-2025		Devendra Shekh		Added Changes for [ItemMasterId] and [StockLineId] 
 ** 5       03-Oct-2025     Devendra Shekh		Added [IsCustomerStock] for Stk
 ** 6       07-Oct-2025     Devendra Shekh		Added [CustomerId]
 
EXECUTE [dbo].[usp_GetCustomerRFQbyId] 961
**************************************************************/  
CREATE   PROCEDURE [dbo].[usp_GetCustomerRfqById]
@CustomerRfqId BIGINT = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
	BEGIN TRY
		BEGIN
			
			IF OBJECT_ID('tempdb..#ItemResults') IS NOT NULL
			BEGIN
				DROP TABLE #ItemResults
			END

			IF OBJECT_ID('tempdb..#StkResults') IS NOT NULL
			BEGIN
				DROP TABLE #StkResults
			END

			DECLARE @LegalEntityId BIGINT = 0, @MasterCompanyId BIGINT = 0;

			SELECT @MasterCompanyId = [MasterCompanyId] FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;
			SELECT TOP 1 @LegalEntityId = [LegalEntityId] FROM [dbo].[CustomerRfqQuote] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId; 
			
			SELECT MAX(RIM.ItemMasterId) AS ItemMasterId, RIM.partnumber AS partnumber, MAX(RIM.PartDescription) AS PartDescription, RIM.MasterCompanyId 
			INTO #ItemResults
			FROM [dbo].[ItemMaster] RIM WITH(NOLOCK) 
			WHERE RIM.[MasterCompanyId] = @MasterCompanyId AND RIM.IsActive = 1 AND RIM.IsDeleted = 0
			GROUP BY RIM.partnumber, RIM.MasterCompanyId

			SELECT  MAX(STK.StockLineId) AS StockLineId, STK.ItemMasterId, STK.MasterCompanyId  
			INTO #StkResults
			FROM [dbo].[Stockline] STK WITH(NOLOCK) 
			INNER JOIN #ItemResults RIM ON STK.ItemMasterId = RIM.ItemMasterId AND STK.MasterCompanyId = RIM.MasterCompanyId
			WHERE STK.[MasterCompanyId] = @MasterCompanyId AND STK.IsActive = 1 AND STK.IsDeleted = 0 AND ISNULL(STK.[QuantityAvailable],0) > 0 AND ISNULL(STK.[IsCustomerStock],0) = 0
			GROUP BY STK.ItemMasterId, STK.MasterCompanyId

			SELECT	[CustomerRfqId], [RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes], [BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity], [BuyerCountry], 
					[BuyerState], [BuyerZip], [LinePartNumber], [LineDescription], [AltPartNumber], [Quantity], [Condition], RFQ.[MasterCompanyId], RFQ.[CreatedBy], RFQ.[CreatedDate],
					RFQ.[UpdatedBy], RFQ.[UpdatedDate], RFQ.[IsActive], RFQ.[IsDeleted], [IsQuote], [IsMRO], [ModuleId], [ReferenceId], IM.ItemMasterId, CASE WHEN ISNULL(STk.StockLineId,0) > 0 THEN 1 ELSE 0 END StockLineId
					,(CASE WHEN ISNULL(RFQ.CustomerId ,0) > 0 THEN RFQ.CustomerId WHEN LOWER(TRIM(CU.[Name])) = LOWER(TRIM(RFQ.BuyerCompanyName)) THEN CU.[CustomerId] ELSE 0 END) CustomerId
			FROM [dbo].[CustomerRfq] RFQ WITH(NOLOCK)
			LEFT JOIN #ItemResults IM WITH(NOLOCK) ON LOWER(TRIM(RFQ.[LinePartNumber])) = LOWER(TRIM(IM.[partnumber])) AND RFQ.[MasterCompanyId] = IM.[MasterCompanyId]
			LEFT JOIN #StkResults STK WITH(NOLOCK) ON STK.ItemMasterId = IM.ItemMasterId AND RFQ.[MasterCompanyId] = IM.[MasterCompanyId]
			LEFT JOIN [dbo].[Customer] CU WITH(NOLOCK) ON (LOWER(TRIM(RFQ.[BuyerCompanyName])) = LOWER(TRIM(CU.[Name])) AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) OR (RFQ.CustomerId = CU.CustomerId AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) AND CU.IsActive = 1 AND CU.IsDeleted = 0
			WHERE [CustomerRfqId] = @CustomerRfqId;

			SELECT	[CustomerRfqQuoteId], [CustomerRfqId], [RfqId], [AddComment], [IsAddCommentQuote], [FaaEasaRelease], [IsFaaEasaReleaseQuote], [RpOh], [IsRpOhQuote], [LegalEntityId],
					[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [Note]
			FROM [dbo].[CustomerRfqQuote] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;

			SELECT	[CustomerRfqQuoteDetailsId], CRQD.[CustomerRfqQuoteId], [ServiceType], [QuotePrice], [QuoteTat], [Low], [Mid], [High], [AvgTat], [QuoteTatQty], [QuoteCond], [QuoteTrace],
					CRQD.[CreatedBy], CRQD.[CreatedDate], CRQD.[UpdatedBy], CRQD.[UpdatedDate], CRQD.[IsActive], CRQD.[IsDeleted], [IlsQty], [IlsTraceability], [IlsUom], [IlsPrice], [IlsPriceType], [IlsTagDate], [IlsLeadTime],
					[IlsMinQty], [IlsComment], [IlsCondition], [ConditionId], [PercentId], [PercentValue], [CustomerRfqPartMappingId], [PriorityId],[ExpirationDate]
			FROM [dbo].[CustomerRfqQuoteDetails] CRQD WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerRfqQuote] CRQ WITH(NOLOCK) ON CRQ.[CustomerRfqQuoteId] = CRQD.[CustomerRfqQuoteId]
			WHERE [CustomerRfqId] = @CustomerRfqId;

			SELECT	LE.Name,
					(ISNULL(Ad.Line1,'')+' '+ISNULL(Ad.Line2,'') +' '+ISNULL(Ad.Line3,'')) As RAddress,
					Ad.City,
					Co.countries_name,
					LE.PhoneNumber, LE.FaxNumber
			FROM [dbo].[LegalEntity] LE WITH (NOLOCK)
			LEFT JOIN [dbo].[Address] Ad WITH (NOLOCK) ON LE.AddressId = Ad.AddressId
			LEFT JOIN [dbo].[Countries] Co WITH (NOLOCK) ON Ad.CountryId = Co.countries_id
			WHERE LE.LegalEntityId = @LegalEntityId;
			
			SELECT	[CustomerRfqPartMappingId], CRFQ.[CustomerRfqId], CRFQ.[Notes], CRFQ.[PartNumber], CRFQ.[PartDescription], CRFQ.[AltPartNumber], CRFQ.[Quantity], CRFQ.[Condition], CRFQ.[MasterCompanyId], CRFQ.[CreatedBy], CRFQ.[CreatedDate],
					CRFQ.[UpdatedBy], CRFQ.[UpdatedDate], CRFQ.[IsActive], CRFQ.[IsDeleted], IM.ItemMasterId, CASE WHEN ISNULL(STk.StockLineId,0) > 0 THEN 1 ELSE 0 END StockLineId
					,(CASE WHEN ISNULL(RFQ.CustomerId ,0) > 0 THEN RFQ.CustomerId WHEN LOWER(TRIM(CU.[Name])) = LOWER(TRIM(RFQ.BuyerCompanyName)) THEN CU.[CustomerId] ELSE 0 END) CustomerId
			FROM [dbo].[CustomerRfqPartMapping] CRFQ WITH(NOLOCK)
			LEFT JOIN #ItemResults IM WITH(NOLOCK) ON LOWER(TRIM(CRFQ.[PartNumber])) = LOWER(TRIM(IM.[partnumber])) AND CRFQ.[MasterCompanyId] = IM.[MasterCompanyId]
			LEFT JOIN #StkResults STK WITH(NOLOCK) ON STK.ItemMasterId = IM.ItemMasterId AND CRFQ.[MasterCompanyId] = IM.[MasterCompanyId]
			INNER JOIN [dbo].[CustomerRfq] RFQ WITH(NOLOCK) ON CRFQ.CustomerRfqId = RFQ.CustomerRfqId
			LEFT JOIN [dbo].[Customer] CU WITH(NOLOCK) ON (LOWER(TRIM(RFQ.[BuyerCompanyName])) = LOWER(TRIM(CU.[Name])) AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) OR (RFQ.CustomerId = CU.CustomerId AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) AND CU.IsActive = 1 AND CU.IsDeleted = 0
			WHERE CRFQ.[CustomerRfqId] = @CustomerRfqId;
		END
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_GetCustomerRFQbyId' 
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