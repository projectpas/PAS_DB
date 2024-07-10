/*************************************************************           
 ** File:   [USP_GetReceivedRfqList]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used Get Received Rfq List data
 ** Purpose:         
 ** Date:   22/02/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    22/02/2024  Rajesh Gami    Created
	2    10-07-2024  SHrey Chandegara MOdify for QuoteCond (add case condition to handle null )by Rajesh Gami 
     
-- EXEC USP_GetReceivedRfqList 
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetReceivedRfqList]
	@PageSize INT,
	@PageNumber INT,
	@SortColumn VARCHAR(50)=null,
	@SortOrder INT,
	@GlobalFilter VARCHAR(50) = null,
	@RfqId VARCHAR(20) = null,
	@RfqCreatedDate DATETIME=null,
	@BuyerCompanyName [VARCHAR](250)= NULL,
	@BuyerName [VARCHAR](250) = NULL,
	@BuyerCountry [VARCHAR](50) = NULL,
	@LinePartNumber [VARCHAR](250) = NULL,
	@Description [VARCHAR](250) = NULL,
	@PortalType [VARCHAR](50) = NULL,
	@MasterCompanyId INT,
	@CreatedDate DATETIME=null,
    @UpdatedDate  DATETIME=null,
	@CreatedBy VARCHAR(50)=null,
	@UpdatedBy VARCHAR(50)=null,
	@IsDeleted BIT = 0,
	@IntegrationPortalId INT = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
			DECLARE @RecordFrom INT;
				SET @RecordFrom = (@PageNumber-1) * @PageSize;
				IF @IsDeleted is null
				BEGIN
					SET @IsDeleted=0
				END
				
				IF @SortColumn is null
				BEGIN
					SET @SortColumn=Upper('CreatedDate')
				END 
				Else
				BEGIN 
					SET @SortColumn=Upper(@SortColumn)
				END
				IF(@IntegrationPortalId = 0)
				BEGIN
					Set @IntegrationPortalId = NULL
				END
			;With Result AS(
				SELECT RFQ.[CustomerRfqId],
					RFQ.[RfqId], 
					RFQ.[RfqCreatedDate] AS 'RfqcreatedDate',
					RFQ.[BuyerName] AS 'rfqFrom',
					RFQ.[BuyerCompanyName] AS 'companyName',
					RFQ.[BuyerCountry] AS 'country',
					RFQ.[LinePartNumber] AS 'partNumber',
					RFQ.[LineDescription] AS 'lineDescription',
					RFQ.[BuyerAddress] AS 'rfqAddress',
					RFQ.[BuyerCity] AS 'rfqCity',
					RFQ.[BuyerCountry] AS 'rfqCountry',
					RFQ.[BuyerState] AS 'rfqState',
					RFQ.[BuyerZip] AS 'rfqZip',
					RFQ.[IsQuote],
					RFQ.[Type] AS 'PortalType',
					RFQ.IntegrationPortalId AS IntegrationPortalId,
					RFQ.CreatedDate, RFQ.UpdatedDate, RFQ.CreatedBy, RFQ.UpdatedBy,
					RFQ.[AltPartNumber] AS 'AltPartNumber',
					RFQ.[Quantity] AS 'Quantity',
					RFQ.[Condition] AS 'Condition'
				FROM CustomerRfq RFQ WITH (NOLOCK)
				WHERE RFQ.MasterCompanyId = @MasterCompanyId 
				--AND RFQ.IsQuote IS NOT NULL 
					AND (@IntegrationPortalId IS NULL OR RFQ.IntegrationPortalId = @IntegrationPortalId)),
				FinalResult AS (
				SELECT * FROM Result
				WHERE (
					(@GlobalFilter <>'' AND ((RfqId like '%' +@GlobalFilter+'%') OR 
							(RfqcreatedDate like '%' +@GlobalFilter+'%') OR
							(rfqFrom like '%' +@GlobalFilter+'%') OR
							(lineDescription like '%' +@GlobalFilter+'%') OR
							(PortalType like '%' +@GlobalFilter+'%') OR
							(companyName like '%' +@GlobalFilter+'%') OR
							(country like '%' +@GlobalFilter+'%') OR
							(partNumber like '%'+@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@RfqId,'') ='' OR CAST(rfqId AS VARCHAR(20)) like '%' + CAST(@RfqId AS VARCHAR(20)) + '%') and 
							(IsNull(@RfqCreatedDate,'') ='' OR Cast(RfqcreatedDate as date)=Cast(@RfqCreatedDate as date)) and
							(IsNull(@BuyerName,'') ='' OR rfqFrom like  '%'+@BuyerName+'%') and
							(IsNull(@Description,'') ='' OR lineDescription like  '%'+@Description+'%') and
							(IsNull(@PortalType,'') ='' OR PortalType like  '%'+@PortalType+'%') and
							(IsNull(@BuyerCompanyName,'') ='' OR companyName like '%'+@BuyerCompanyName+'%') and
							(IsNull(@BuyerCountry,'') ='' OR country like '%'+ @BuyerCountry+'%') and
							(IsNull(@LinePartNumber,'') ='' OR partNumber like '%'+@LinePartNumber+'%') and
							(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%'+ @CreatedBy+'%') and
							(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%'+ @UpdatedBy+'%') and
							(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and
							(IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)))
							)),
						ResultCount AS (Select COUNT(CustomerRfqId) AS NumberOfItems FROM FinalResult)


					SELECT * INTO #resultTemp 
					FROM FinalResult, ResultCount
					ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERRFQID')  THEN CustomerRfqId END DESC,
					CASE WHEN (@SortOrder=1 and @SortColumn='RFQID')  THEN RfqId END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='RFQCREATEDDATE')  THEN RfqcreatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='RFQFROM')  THEN rfqFrom END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='COMPANYNAME')  THEN companyName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='COUNTRY')  THEN country END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN partNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Description')  THEN lineDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PortalType')  THEN PortalType END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERRFQID')  THEN CustomerRfqId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RFQID')  THEN RfqId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RFQCREATEDDATE')  THEN RfqcreatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RFQFROM')  THEN rfqFrom END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='COMPANYNAME')  THEN companyName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='COUNTRY')  THEN country END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN partNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Description')  THEN lineDescription END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PortalType')  THEN PortalType END DESC
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY

					Select * from #resultTemp

					SELECT  
							crq.[CustomerRfqQuoteId],
							crq.[CustomerRfqId],
							crq.[RfqId],
							crq.[AddComment],
							crq.[IsAddCommentQuote],
							crq.[FaaEasaRelease],
							crq.[IsFaaEasaReleaseQuote],
							crq.[RpOh],
							crq.[IsRpOhQuote],
							crq.[LegalEntityId],
							crq.Note,
							csd.[CustomerRfqQuoteDetailsId],
							csd.[ServiceType],
							csd.[QuotePrice],
							csd.[QuoteTat],
							csd.[Low],
							csd.[Mid],
							csd.[High],
							csd.[AvgTat],
							csd.[QuoteTatQty],
							(CASE WHEN csd.[QuoteCond] = '' THEN NULL ELSE csd.[QuoteCond] END) QuoteCond,
							csd.[QuoteTrace],
							csd.[IlsQty],
							csd.[IlsTraceability],
							csd.[IlsUom],
							csd.[IlsPrice],
							csd.[IlsPriceType],
							csd.[IlsTagDate],
							csd.[IlsLeadTime],
							csd.[IlsMinQty],
							csd.[IlsComment],
							csd.[IlsCondition],

							res.[CustomerRfqId],
							res.[RfqId], 
							res.RfqcreatedDate,
							res.rfqFrom,
							res.companyName,
							res.country,
							res.partNumber,
							res.lineDescription,
							res.rfqAddress,
							res.rfqCity,
							res.rfqCountry,
							res.rfqState,
							res.rfqZip,
							res.[IsQuote],
							res.PortalType,
							res.IntegrationPortalId AS IntegrationPortalId,
							res.CreatedDate, res.UpdatedDate, res.CreatedBy, res.UpdatedBy,
							res.AltPartNumber,
							res.Quantity,
							res.Condition

					FROM dbo.CustomerRfqQuote crq WITH(NOLOCK)
					INNER JOIN #resultTemp res on crq.CustomerRfqId = res.CustomerRfqId
					INNER JOIN  dbo.CustomerRfqQuoteDetails csd WITH(NOLOCK) on crq.CustomerRfqQuoteId = csd.CustomerRfqQuoteId
					WHERE ISNULL(crq.IsDeleted,0) = 0 AND ISNULL(csd.IsDeleted,0) = 0
				END
				COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetReceivedRfqList' 
            , @ProcedureParameters VARCHAR(3000) = '@RfqId = ''' + CAST(ISNULL(@RfqId, '') as varchar(100))
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