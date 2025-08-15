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
 
EXECUTE [dbo].[usp_GetCustomerRFQbyId] 3
**************************************************************/  
CREATE   PROCEDURE [dbo].[usp_GetCustomerRfqById]
@CustomerRfqId BIGINT = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
	BEGIN TRY
		BEGIN

			DECLARE @LegalEntityId BIGINT = 0;

			SELECT TOP 1 @LegalEntityId = [LegalEntityId] FROM [dbo].[CustomerRfqQuote] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;  

			SELECT	[CustomerRfqId], [RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes], [BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity], [BuyerCountry], 
					[BuyerState], [BuyerZip], [LinePartNumber], [LineDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId], [CreatedBy], [CreatedDate],
					[UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [IsQuote], [IsMRO], [ModuleId], [ReferenceId]
			FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;

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
			
			SELECT	[CustomerRfqPartMappingId], [CustomerRfqId], [Notes], [PartNumber], [PartDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId], [CreatedBy], [CreatedDate],
					[UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
			FROM [dbo].[CustomerRfqPartMapping] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;
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