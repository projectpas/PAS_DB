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
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    22/02/2024  Rajesh Gami         Created
	2    10-07-2024  SHrey Chandegara    MOdify for QuoteCond (add case condition to handle null )by Rajesh Gami 
	3    21-07-2025  Amit Ghediya        MOdify for get RFQ part is in our inventory or not (ItemMasterId,StockLineId)
	4    21-07-2025  Devendra Shekh		 Modified (Added CustomerId to select)
	5    31-07-2025  Amit Ghediya		 Modified (Added ModuleId,ReferenceId to select)
	6    04-08-2025  Devendra Shekh		 Modified (Added EmployeeId,EmployeeName to select)
	7    06-08-2025  Amit Ghediya		 Modified (Added RefrenceQuoteNumber,QuotedBy,QuotedDate)
	8    13-08-2025  Devendra Shekh		 Modified (Added Changes for Email Integration, Added RefrenceQuoteNumber to Param)
	9    19-08-2025  Devendra Shekh		 Modified (Added DisableRow Field to select)
	10	 20-08-2025  Devendra Shekh		 Modified (Duplicate Part Data Issue Resolved) 
	11	 21-08-2025  Devendra Shekh		 Modified (Added one more Case for CustomerId) 
	12	 26-08-2025  Devendra Shekh		 Modified (Added LOWER/TRIM for PartNumber and Customer for Join) 
	13   01-09-2025  Amit Ghediya		 Modified (Update RefrenceQuoteNumber field selection)
     
-- EXEC USP_GetReceivedRfqList 
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_GetReceivedRfqList]
	@PageSize INT,
	@PageNumber INT,
	@SortColumn VARCHAR(50)=null,
	@SortOrder INT,
	@GlobalFilter VARCHAR(50) = null,
	@RfqId VARCHAR(20) = null,
	@RfqCreatedDate DATETIME=null,
	@BuyerCompanyName [VARCHAR](250)= NULL,
	@BuyerName [VARCHAR](250) = NULL,
	@pnDescription [VARCHAR](250) = NULL,
	@contact [VARCHAR](250) = NULL,
	@BuyerCountry [VARCHAR](50) = NULL,
	@LinePartNumber [VARCHAR](250) = NULL,
	@Description [VARCHAR](250) = NULL,
	@PortalType [VARCHAR](50) = NULL,
	@MasterCompanyId INT,
	@CreatedDate DATETIME=NULL,
    @UpdatedDate  DATETIME=NULL,
	@CreatedBy VARCHAR(50)=NULL,
	@UpdatedBy VARCHAR(50)=NULL,
	@IsDeleted BIT = 0,
	@IntegrationPortalId INT = NULL,
	@EmployeeName VARCHAR(100) = NULL,
	@DateAssigned DATETIME=null,
	@QuotedBy VARCHAR(50)=NULL,
	@QuotedDate DATETIME=null,
	@RefrenceQuoteNumber VARCHAR(50)=NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
			DECLARE @RecordFrom INT,
					@AautoSendQuote VARCHAR(50)= 'Auto Send',
					@ReviewRequired VARCHAR(50)= 'Review Required',
					@SoqModuleId INT,
					@SoModuleId INT;

				--Get module id
				SELECT @SoqModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';
				SELECT @SoModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

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

				DECLARE @ILSPortalId INT = 1, @OneFortyFivePortalId INT = 2, @EmailPortalId INT = 3;
			;With ItemResult AS (
				SELECT MAX(RIM.ItemMasterId) AS ItemMasterId, RIM.partnumber AS partnumber, MAX(RIM.PartDescription) AS PartDescription, RIM.MasterCompanyId 
				FROM [dbo].[ItemMaster] RIM WITH(NOLOCK)
				WHERE RIM.[MasterCompanyId] = @MasterCompanyId
				GROUP BY RIM.partnumber, RIM.MasterCompanyId
			),			
			Result AS(
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
					RFQ.[Condition] AS 'Condition',
					ISNULL(RFQ.[ModuleId],0) AS ModuleId,
					ISNULL(RFQ.[ReferenceId],0) AS ReferenceId,
					(CASE WHEN LOWER(TRIM(RFQ.[LinePartNumber])) = LOWER(TRIM(IM.[partnumber])) THEN IM.[ItemMasterId] ELSE 0 END) ItemMasterId,
					IM.PartDescription AS 'PnDescription',
					(CASE WHEN ISNULL(RFQ.CustomerId ,0) > 0 THEN RFQ.CustomerId WHEN LOWER(TRIM(CU.[Name])) = LOWER(TRIM(RFQ.BuyerCompanyName)) THEN CU.[CustomerId] ELSE 0 END) CustomerId,
					(ISNULL(Contact.FirstName,'')+' '+ISNULL(Contact.LastName,'')) AS 'Contact',
					ISNULL((SELECT TOP 1 CASE WHEN ISNULL(STk.StockLineId,0) > 0 THEN 1 ELSE 0 END  FROM dbo.Stockline STK WITH(NOLOCK) WHERE IM.[itemmasterid] = STK.[itemmasterid] AND ISNULL(STK.[QuantityAvailable],0) > 0),0) StockLineId,
					RFQ.EmployeeId,
					CONCAT(EM.FirstName, ' ', EM.LastName) AS EmployeeName,
					CASE WHEN RFQ.ModuleId = @SoqModuleId THEN ISNULL(SOQ.[SalesOrderQuoteNumber],'')
						 WHEN RFQ.ModuleId = @SoModuleId THEN ISNULL(SO.[SalesOrderNumber],'') END AS RefrenceQuoteNumber,
					RFQ.[DateAssigned],
					RFQ.[QuotedBy],
					RFQ.[QuotedDate],
					CASE 
						WHEN RFQ.IsQuote = 1 THEN	CASE	WHEN QSR.Code = @AautoSendQuote THEN 'YES (Quoted)' 
															WHEN QSR.Code = @ReviewRequired THEN 'YES (Review Required)' 
															ELSE 'YES'	END
						WHEN RFQ.IsQuote = 2 THEN 'No Quote' 
						ELSE NULL
					END AS 'QuoteStatus',
					Expired = NULL,
					DaysTillExpire = NULL,
					DisableRow = CASE WHEN ISNULL(RFQ.IsQuote, 0) > 0 THEN 1 ELSE 0 END
				FROM dbo.CustomerRfq RFQ WITH (NOLOCK)
				--LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON RFQ.[LinePartNumber] = IM.[partnumber] AND RFQ.[MasterCompanyId] = IM.[MasterCompanyId]
				LEFT JOIN ItemResult IM WITH(NOLOCK) ON LOWER(TRIM(RFQ.[LinePartNumber])) = LOWER(TRIM(IM.[partnumber])) AND RFQ.[MasterCompanyId] = IM.[MasterCompanyId]
				LEFT JOIN dbo.Customer CU WITH(NOLOCK) ON (LOWER(TRIM(RFQ.[BuyerCompanyName])) = LOWER(TRIM(CU.[Name])) AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) OR (RFQ.CustomerId = CU.CustomerId AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId])
				LEFT JOIN  dbo.CustomerContact CC  WITH (NOLOCK) ON CC.CustomerId=CU.CustomerId AND CC.IsDefaultContact=1
				LEFT JOIN  dbo.Contact  WITH (NOLOCK) ON CC.ContactId=Contact.ContactId
				LEFT JOIN dbo.Employee EM WITH(NOLOCK) ON RFQ.[EmployeeId] = EM.[EmployeeId] AND RFQ.[MasterCompanyId] = EM.[MasterCompanyId]
				LEFT JOIN dbo.SalesOrderQuote SOQ WITH(NOLOCK) ON RFQ.[ReferenceId] = SOQ.[SalesOrderQuoteId] AND RFQ.[MasterCompanyId] = SOQ.[MasterCompanyId]
				LEFT JOIN dbo.SalesOrder SO WITH(NOLOCK) ON RFQ.[ReferenceId] = SO.[SalesOrderId] AND RFQ.[MasterCompanyId] = SO.[MasterCompanyId]
				LEFT JOIN dbo.QuoteSendReview QSR WITH(NOLOCK) ON QSR.QuoteSendReviewId = RFQ.QuoteSendReviewId
				--OUTER APPLY (
				--	SELECT TOP 1 RIM.ItemMasterId, RIM.partnumber, RIM.PartDescription
				--	FROM [dbo].[ItemMaster] RIM WITH(NOLOCK)
				--	WHERE RFQ.[LinePartNumber] = RIM.[partnumber] AND RFQ.[MasterCompanyId] = RIM.[MasterCompanyId]
				--) IM
				WHERE RFQ.MasterCompanyId = @MasterCompanyId 
				AND (@IntegrationPortalId IS NULL OR RFQ.IntegrationPortalId = @IntegrationPortalId)
				AND RFQ.IntegrationPortalId IN (@ILSPortalId, @OneFortyFivePortalId)

				UNION ALL

				SELECT RFQ.[CustomerRfqId],
					RFQ.[RfqId], 
					RFQ.[RfqCreatedDate] AS 'RfqcreatedDate',
					RFQ.[BuyerName] AS 'rfqFrom',
					RFQ.[BuyerCompanyName] AS 'companyName',
					RFQ.[BuyerCountry] AS 'country',
					CRPM.[PartNumber] AS 'partNumber',
					CRPM.[PartDescription] AS 'lineDescription',
					RFQ.[BuyerAddress] AS 'rfqAddress',
					RFQ.[BuyerCity] AS 'rfqCity',
					RFQ.[BuyerCountry] AS 'rfqCountry',
					RFQ.[BuyerState] AS 'rfqState',
					RFQ.[BuyerZip] AS 'rfqZip',
					RFQ.[IsQuote],
					RFQ.[Type] AS 'PortalType',
					RFQ.IntegrationPortalId AS IntegrationPortalId,
					RFQ.CreatedDate, RFQ.UpdatedDate, RFQ.CreatedBy, RFQ.UpdatedBy,
					CRPM.[AltPartNumber] AS 'AltPartNumber',
					CRPM.[Quantity] AS 'Quantity',
					CRPM.[Condition] AS 'Condition',
					ISNULL(RFQ.[ModuleId],0) AS ModuleId,
					ISNULL(RFQ.[ReferenceId],0) AS ReferenceId,
					(CASE	WHEN LOWER(TRIM(CRPM.[PartNumber])) = LOWER(TRIM(IM.[partnumber])) THEN IM.[ItemMasterId] ELSE 0 END) ItemMasterId,
					CASE WHEN ISNULL(IM.PartDescription, '') != '' THEN IM.PartDescription ELSE CRPM.PartDescription END AS 'PnDescription',
					(CASE WHEN ISNULL(RFQ.CustomerId ,0) > 0 THEN RFQ.CustomerId WHEN LOWER(TRIM(CU.[Name])) = LOWER(TRIM(RFQ.BuyerCompanyName)) THEN CU.[CustomerId] ELSE 0 END) CustomerId,
					(ISNULL(Contact.FirstName,'')+' '+ISNULL(Contact.LastName,'')) AS 'Contact',
					ISNULL((SELECT TOP 1 CASE WHEN ISNULL(STk.StockLineId,0) > 0 THEN 1 ELSE 0 END  FROM dbo.Stockline STK WITH(NOLOCK) WHERE IM.[itemmasterid] = STK.[itemmasterid] AND ISNULL(STK.[QuantityAvailable],0) > 0),0) StockLineId,
					RFQ.EmployeeId,
					CONCAT(EM.FirstName, ' ', EM.LastName) AS EmployeeName,
					CASE WHEN RFQ.ModuleId = @SoqModuleId THEN ISNULL(SOQ.[SalesOrderQuoteNumber],'')
						 WHEN RFQ.ModuleId = @SoModuleId THEN ISNULL(SO.[SalesOrderNumber],'') END AS RefrenceQuoteNumber,
					RFQ.[DateAssigned],
					RFQ.[QuotedBy],
					RFQ.[QuotedDate],
					CASE 
						WHEN RFQ.IsQuote = 1 THEN	CASE	WHEN QSR.Code = @AautoSendQuote THEN 'YES (Quoted)' 
															WHEN QSR.Code = @ReviewRequired THEN 'YES (Review Required)' 
															ELSE 'YES'	END
						WHEN RFQ.IsQuote = 2 THEN 'No Quote' 
						ELSE NULL
					END AS 'QuoteStatus',
					Expired = NULL,
					DaysTillExpire = NULL,
					CASE 
						WHEN RFQ.IsQuote = 1 AND ISNULL(RFQ.ReferenceId, 0) > 0 THEN 1
						WHEN RFQ.IsQuote = 2 THEN 1
						ELSE 0
					END AS 'DisableRow'
				FROM dbo.CustomerRfq RFQ WITH (NOLOCK)
				LEFT JOIN dbo.Customer CU WITH(NOLOCK) ON (LOWER(TRIM(RFQ.[BuyerCompanyName])) = LOWER(TRIM(CU.[Name])) AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) OR (RFQ.CustomerId = CU.CustomerId AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId])
				LEFT JOIN  dbo.CustomerContact CC  WITH (NOLOCK) ON CC.CustomerId=CU.CustomerId AND CC.IsDefaultContact=1
				LEFT JOIN  dbo.Contact  WITH (NOLOCK) ON CC.ContactId=Contact.ContactId
				LEFT JOIN dbo.Employee EM WITH(NOLOCK) ON RFQ.[EmployeeId] = EM.[EmployeeId] AND RFQ.[MasterCompanyId] = EM.[MasterCompanyId]
				LEFT JOIN dbo.SalesOrderQuote SOQ WITH(NOLOCK) ON RFQ.[ReferenceId] = SOQ.[SalesOrderQuoteId] AND RFQ.[MasterCompanyId] = SOQ.[MasterCompanyId]
				LEFT JOIN dbo.SalesOrder SO WITH(NOLOCK) ON RFQ.[ReferenceId] = SO.[SalesOrderId] AND RFQ.[MasterCompanyId] = SO.[MasterCompanyId]
				LEFT JOIN dbo.CustomerRfqPartMapping CRPM WITH(NOLOCK) ON RFQ.[CustomerRfqId] = CRPM.[CustomerRfqId]
				--LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON CRPM.[PartNumber] = IM.[partnumber] AND CRPM.[MasterCompanyId] = IM.[MasterCompanyId]
				LEFT JOIN ItemResult IM WITH(NOLOCK) ON LOWER(TRIM(CRPM.[PartNumber])) = LOWER(TRIM(IM.[partnumber])) AND CRPM.[MasterCompanyId] = IM.[MasterCompanyId]
				LEFT JOIN dbo.QuoteSendReview QSR WITH(NOLOCK) ON QSR.QuoteSendReviewId = RFQ.QuoteSendReviewId
				--OUTER APPLY (
				--	SELECT TOP 1 RIM.ItemMasterId, RIM.partnumber, RIM.PartDescription
				--	FROM [dbo].[ItemMaster] RIM WITH(NOLOCK)
				--	WHERE RFQ.[LinePartNumber] = RIM.[partnumber] AND RFQ.[MasterCompanyId] = RIM.[MasterCompanyId]
				--) IM
				WHERE RFQ.MasterCompanyId = @MasterCompanyId 
				AND RFQ.IntegrationPortalId IN (@EmailPortalId)
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
							(PnDescription like '%' +@pnDescription+'%') OR
							(Contact like '%' +@contact+'%') OR
							(companyName like '%' +@GlobalFilter+'%') OR
							(country like '%' +@GlobalFilter+'%') OR
							(partNumber like '%'+@GlobalFilter+'%') OR
							(DateAssigned like '%' +@GlobalFilter+'%') OR
							(QuotedBy like '%' +@GlobalFilter+'%') OR
							(QuotedDate like '%' +@GlobalFilter+'%') OR
							(EmployeeName like '%'+@GlobalFilter+'%') OR
							(RefrenceQuoteNumber like '%'+@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@RfqId,'') ='' OR CAST(rfqId AS VARCHAR(20)) like '%' + CAST(@RfqId AS VARCHAR(20)) + '%') and 
							(IsNull(@RfqCreatedDate,'') ='' OR Cast(RfqcreatedDate as date)=Cast(@RfqCreatedDate as date)) and
							(IsNull(@BuyerName,'') ='' OR rfqFrom like  '%'+@BuyerName+'%') and
							(IsNull(@Description,'') ='' OR lineDescription like  '%'+@Description+'%') and
							(IsNull(@PortalType,'') ='' OR PortalType like  '%'+@PortalType+'%') and
							(IsNull(@pnDescription,'') ='' OR PnDescription like  '%'+@pnDescription+'%') and
							(IsNull(@contact,'') ='' OR Contact like  '%'+@contact+'%') and
							(IsNull(@DateAssigned,'') ='' OR Cast(DateAssigned as date)=Cast(@DateAssigned as date)) and

							(IsNull(@QuotedBy,'') ='' OR QuotedBy like '%'+ @QuotedBy+'%') and
							(IsNull(@QuotedDate,'') ='' OR Cast(QuotedDate as date)=Cast(@QuotedDate as date)) and

							(IsNull(@BuyerCompanyName,'') ='' OR companyName like '%'+@BuyerCompanyName+'%') and
							(IsNull(@BuyerCountry,'') ='' OR country like '%'+ @BuyerCountry+'%') and
							(IsNull(@LinePartNumber,'') ='' OR partNumber like '%'+@LinePartNumber+'%') and
							(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%'+ @CreatedBy+'%') and
							(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%'+ @UpdatedBy+'%') and
							(IsNull(@EmployeeName,'') ='' OR EmployeeName like '%'+ @EmployeeName +'%') and
							(IsNull(@RefrenceQuoteNumber,'') ='' OR RefrenceQuoteNumber like '%'+ @RefrenceQuoteNumber +'%') and
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
					CASE WHEN (@SortOrder=1 and @SortColumn='DateAssigned')  THEN DateAssigned END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='QuotedBy')  THEN QuotedBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='QuotedDate')  THEN QuotedDate END ASC,
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
					CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PnDescription END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Contact')  THEN Contact END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='EmployeeName')  THEN EmployeeName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='RefrenceQuoteNumber')  THEN RefrenceQuoteNumber END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERRFQID')  THEN CustomerRfqId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RFQID')  THEN RfqId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RFQCREATEDDATE')  THEN RfqcreatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='DateAssigned')  THEN DateAssigned END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='QuotedBy')  THEN QuotedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='QuotedDate')  THEN QuotedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RFQFROM')  THEN rfqFrom END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='COMPANYNAME')  THEN companyName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='COUNTRY')  THEN country END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN partNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Description')  THEN lineDescription END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PortalType')  THEN PortalType END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PnDescription END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Contact')  THEN Contact END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='EmployeeName')  THEN EmployeeName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RefrenceQuoteNumber')  THEN RefrenceQuoteNumber END DESC
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
							csd.[ExpirationDate],

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
					INNER JOIN #resultTemp res WITH(NOLOCK) on  crq.CustomerRfqId = res.CustomerRfqId
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