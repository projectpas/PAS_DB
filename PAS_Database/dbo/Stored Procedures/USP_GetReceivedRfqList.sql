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
	14   16-09-2025  Devendra Shekh		 Modified (Changes for StockLineId select, reduced Query Time)
	15   18-09-2025  Devendra Shekh		 Modified (UTC DateTime Issue Resolved)
	16   03-10-2025  Devendra Shekh		 Modified (added new Param : @Condition, @Quantity) And Added [IsCustomerStock] for Stk
	17   17-11-2025  Devendra Shekh		 Modified (added new Param : @VendorRFQId, @PurchaseOrderNumber, @VendorRFQPurchaseOrderNumber)
    18   03-12-2025  Rajesh Gami		 Added Quote Sent Date (@QuoteSentDate)
	19   03-12-2025  Moin Bloch		     Modified Changed Quoted Column Status
	20   04-12-2025  Devendra Shekh		 Modified (added @SendQuote)
	21   10-12-2025  Devendra Shekh		 Modified (added IsActive/IsDeleted to Where)
	22   16-12-2025  Devendra Shekh		 Modified (added RFQNum)
	23   17-12-2025  Devendra Shekh		 Modified (added AllowAssign, FollowUpDate)
	24   22-12-2025  Devendra Shekh		 Modified (set Default @SortColumn to CustomerRfqId)
	25   09-01-2026  Amit Ghediya		 Modified (get added contact)
	26   10-02-2026  Vishal Suthar		 PN-11778 Added option for PartsBase
	27   02-03-2026  Vishal Suthar		 Fixed binding PartDescription from Response itself

-- EXEC USP_GetReceivedRfqList 
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetReceivedRfqList]
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
	@QuoteSentDate DATETIME=null,
	@RefrenceQuoteNumber VARCHAR(50)=NULL,
	@UserEmployeeId BIGINT = NULL,
	@Condition VARCHAR(250) = NULL,
	@Quantity INT = NULL,
	@VendorRFQId VARCHAR(100) = NULL,
	@PurchaseOrderNumber VARCHAR(MAX) = NULL,
	@VendorRFQPurchaseOrderNumber VARCHAR(MAX) = NULL,
	@SendQuote VARCHAR(100) = NULL,
	@FollowUpDate DATETIME=NULL
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
			DECLARE @PoModuleId BIGINT = 0, @RFQPOModuleId BIGINT = 0;
			DECLARE @CodeTypes VARCHAR(100) = 'CustomerRFQ', @CodePrefix VARCHAR(10);

				--Get module id
				SELECT @SoqModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';
				SELECT @SoModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

				SELECT @PoModuleId = [ModuleId] FROM [Dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'PurchaseOrder';
				SELECT @RFQPOModuleId = [ModuleId] FROM [Dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPurchaseOrder';
				SELECT @CodePrefix = [CodePrefix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [CodeTypeId] = (SELECT [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = @CodeTypes)

				SET @RecordFrom = (@PageNumber-1) * @PageSize;
				IF @IsDeleted is null
				BEGIN
					SET @IsDeleted=0
				END
				
				IF @SortColumn is null
				BEGIN
					SET @SortColumn=Upper('CustomerRfqId')
				END 
				Else
				BEGIN 
					SET @SortColumn=Upper(@SortColumn)
				END
				IF(@IntegrationPortalId = 0)
				BEGIN
					Set @IntegrationPortalId = NULL
				END

				IF OBJECT_ID('tempdb..#VendorsRFQResult') IS NOT NULL
				BEGIN
					DROP TABLE #VendorsRFQResult
				END

				/* --------------START: Get the timzone and UTC offset -------------- */
				DECLARE @CurrntEmpTimeZoneDesc VARCHAR(400) = '', @BaseUtcOffsetSec BIGINT = 0;
				SELECT 	@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description] )
				FROM dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE E.EmployeeId = @UserEmployeeId AND E.MasterCompanyId = @MasterCompanyId;	
				
				SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec FROM dbo.TimeZone WITH(NOLOCK) WHERE [Description] = @CurrntEmpTimeZoneDesc
				/* -------------- END: Get the timzone and UTC offset -------------- */
				
				IF OBJECT_ID('tempdb..#tmpSalesOrderStatus') IS NOT NULL
				BEGIN
					DROP TABLE #tmpSalesOrderStatus
				END

				SELECT Id INTO #tmpSalesOrderStatus FROM [dbo].[MasterSalesOrderStatus] WITH(NOLOCK) WHERE [Name] IN ('Closed', 'Cancelled');

				DECLARE @ILSPortalId INT = 1, @OneFortyFivePortalId INT = 2, @EmailPortalId INT = 3, @PartsBasePortalId INT = 54;

				SELECT DISTINCT tmpVRFQResult.CustomerRfqId, tmpVRFQResult.MasterCompanyId, tmpVRFQResult.VendorRFQId, tmpVRFQResult.ILSRFQDetailId, tmpVRFQResult.PartNumber, tmpVRFQResult.Condition
				INTO #VendorsRFQResult
				FROM (
					SELECT DISTINCT PT.CustomerRfqId, PT.MasterCompanyId, TP.RFQId AS VendorRFQId, 0 AS ILSRFQDetailId, RFQ.LinePartNumber AS PartNumber, RFQ.Condition
					FROM [dbo].[ILSRFQPart] PT WITH(NOLOCK)
					INNER JOIN [dbo].[CustomerRfq] RFQ WITH(NOLOCK) ON PT.CustomerRfqId = RFQ.CustomerRfqId
					INNER JOIN [dbo].[ILSRFQDetail] DT WITH(NOLOCK) ON PT.ILSRFQDetailId = DT.ILSRFQDetailId
					INNER JOIN [dbo].[ILSRFQPart] ILSP WITH(NOLOCK) ON ILSP.ILSRFQDetailId = DT.ILSRFQDetailId AND LOWER(TRIM(ILSP.PartNumber)) = LOWER(TRIM(RFQ.LinePartNumber)) AND LOWER(TRIM(ILSP.Condition)) = LOWER(TRIM(RFQ.Condition)) AND ILSP.CustomerRfqId = RFQ.CustomerRfqId
					INNER JOIN [dbo].[ThirdPartyRFQ] TP WITH(NOLOCK) ON DT.ThirdPartyRFQId = TP.ThirdPartyRFQId
					WHERE PT.IsActive = 1 AND PT.IsDeleted = 0 AND PT.MasterCompanyId = @MasterCompanyId AND RFQ.IntegrationPortalId IN (@ILSPortalId, @OneFortyFivePortalId, @PartsBasePortalId)

					UNION ALL

					SELECT DISTINCT PT.CustomerRfqId, PT.MasterCompanyId, TP.RFQId AS VendorRFQId, 0 AS ILSRFQDetailId, CRPM.PartNumber, CRPM.Condition
					FROM [dbo].[ILSRFQPart] PT WITH(NOLOCK)
					INNER JOIN [dbo].[CustomerRfq] RFQ WITH(NOLOCK) ON PT.CustomerRfqId = RFQ.CustomerRfqId
					INNER JOIN [dbo].[CustomerRfqPartMapping] CRPM WITH(NOLOCK) ON RFQ.[CustomerRfqId] = CRPM.[CustomerRfqId]
					INNER JOIN [dbo].[ILSRFQDetail] DT WITH(NOLOCK) ON PT.ILSRFQDetailId = DT.ILSRFQDetailId
					INNER JOIN [dbo].[ILSRFQPart] ILSP WITH(NOLOCK) ON ILSP.ILSRFQDetailId = DT.ILSRFQDetailId AND LOWER(TRIM(ILSP.PartNumber)) = LOWER(TRIM(CRPM.PartNumber)) AND LOWER(TRIM(ILSP.Condition)) = LOWER(TRIM(CRPM.Condition)) AND ILSP.CustomerRfqId = RFQ.CustomerRfqId
					INNER JOIN [dbo].[ThirdPartyRFQ] TP WITH(NOLOCK) ON DT.ThirdPartyRFQId = TP.ThirdPartyRFQId
					WHERE PT.IsActive = 1 AND PT.IsDeleted = 0 AND PT.MasterCompanyId = @MasterCompanyId AND RFQ.IntegrationPortalId IN (@EmailPortalId)
				) AS tmpVRFQResult

				UPDATE TMP
				SET	TMP.ILSRFQDetailId = PartResult.ILSRFQDetailId
				FROM #VendorsRFQResult TMP
				OUTER APPLY (
					SELECT MAX(PT.ILSRFQDetailId) AS ILSRFQDetailId FROM dbo.ILSRFQPart PT WITH(NOLOCK) WHERE PT.CustomerRfqId = TMP.CustomerRfqId
				) PartResult
			
			;With ItemResult AS (
				SELECT MAX(RIM.ItemMasterId) AS ItemMasterId, RIM.partnumber AS partnumber, MAX(RIM.PartDescription) AS PartDescription, RIM.MasterCompanyId 
				FROM [dbo].[ItemMaster] RIM WITH(NOLOCK) 
				WHERE RIM.[MasterCompanyId] = @MasterCompanyId AND RIM.IsActive = 1 AND RIM.IsDeleted = 0
				GROUP BY RIM.partnumber, RIM.MasterCompanyId
			),	
			StkResult AS (
				SELECT  MAX(STK.StockLineId) AS StockLineId, STK.ItemMasterId, STK.MasterCompanyId  
				FROM [dbo].[Stockline] STK WITH(NOLOCK) 
				INNER JOIN ItemResult RIM ON STK.ItemMasterId = RIM.ItemMasterId AND STK.MasterCompanyId = RIM.MasterCompanyId
				WHERE STK.[MasterCompanyId] = @MasterCompanyId AND STK.IsActive = 1 AND STK.IsDeleted = 0 AND ISNULL(STK.[QuantityAvailable],0) > 0 AND ISNULL(STK.[IsCustomerStock],0) = 0
				GROUP BY STK.ItemMasterId, STK.MasterCompanyId
			),			
			VendorRFQReferenceResult AS (
			SELECT * FROM (
				SELECT [ILSRFQDetailId], [MasterCompanyId], [ReferenceId], [ModuleId]
				,COUNT(*) OVER (PARTITION BY [ILSRFQDetailId], [ModuleId]) AS RefModCount
				FROM [DBO].[VendorRFQPart] WITH(NOLOCK)
				WHERE	ISNULL([IsDeleted], 0) = 0 AND ISNULL([IsActive], 0) = 1 AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([ModuleId], 0) = @PoModuleId
						GROUP BY [ILSRFQDetailId], [MasterCompanyId], [ReferenceId], [ModuleId]
				) AS t
			WHERE t.RefModCount = 1
			),
			RFQReferenceResult AS (
				SELECT * FROM (
					SELECT [ILSRFQDetailId], VRFQP.[MasterCompanyId], VPO.VendorRFQPurchaseOrderId AS RFQReferenceId, @RFQPOModuleId AS RFQModuleId
					,COUNT(*) OVER (PARTITION BY [ILSRFQDetailId], [ModuleId]) AS RefModCount
					FROM [DBO].[VendorRFQPart] VRFQP WITH(NOLOCK)
					INNER JOIN DBO.PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = VRFQP.ReferenceId
					INNER JOIN DBO.VendorRFQPurchaseOrderPart VPOP WITH(NOLOCK) ON VPOP.PurchaseOrderId = PO.PurchaseOrderId
					INNER JOIN DBO.VendorRFQPurchaseOrder VPO WITH(NOLOCK) ON VPO.VendorRFQPurchaseOrderId = VPOP.VendorRFQPurchaseOrderId
					WHERE	ISNULL(VRFQP.[IsDeleted], 0) = 0 AND ISNULL(VRFQP.[IsActive], 0) = 1 AND VRFQP.[MasterCompanyId] = @MasterCompanyId AND ISNULL([ModuleId], 0) = @PoModuleId
							GROUP BY [ILSRFQDetailId], VRFQP.[MasterCompanyId], VPO.[VendorRFQPurchaseOrderId], [ModuleId]
					) AS t
				WHERE t.RefModCount = 1
			),
			Result AS(
				SELECT RFQ.[CustomerRfqId],
					RFQ.[RfqId], 
					CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, RFQ.[RfqCreatedDate])) AS 'RfqcreatedDate',
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
					(CASE WHEN ISNULL(IM.PartDescription, '') != '' THEN IM.PartDescription ELSE RFQ.LineDescription END) AS 'PnDescription',
					(CASE WHEN ISNULL(RFQ.CustomerId ,0) > 0 THEN RFQ.CustomerId WHEN LOWER(TRIM(CU.[Name])) = LOWER(TRIM(RFQ.BuyerCompanyName)) THEN CU.[CustomerId] ELSE 0 END) CustomerId,
					(ISNULL(Contact.FirstName,'')+' '+ISNULL(Contact.LastName,'')) AS 'Contact',
					CASE WHEN ISNULL(STk.StockLineId,0) > 0 THEN 1 ELSE 0 END StockLineId,
					--ISNULL((SELECT TOP 1 CASE WHEN ISNULL(STk.StockLineId,0) > 0 THEN 1 ELSE 0 END  FROM dbo.Stockline STK WITH(NOLOCK) WHERE IM.[itemmasterid] = STK.[itemmasterid] AND ISNULL(STK.[QuantityAvailable],0) > 0),0) StockLineId,
					RFQ.EmployeeId,
					CONCAT(EM.FirstName, ' ', EM.LastName) AS EmployeeName,
					CASE WHEN RFQ.ModuleId = @SoqModuleId THEN ISNULL(SOQ.[SalesOrderQuoteNumber],'')
						 WHEN RFQ.ModuleId = @SoModuleId THEN ISNULL(SO.[SalesOrderNumber],'') END AS RefrenceQuoteNumber,
					CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, RFQ.[DateAssigned])) AS 'DateAssigned',
					RFQ.[QuotedBy],
					CASE WHEN  RFQ.ModuleId = @SoqModuleId THEN CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, SOQ.[CreatedDate])) ELSE CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, RFQ.[QuotedDate])) END AS 'QuotedDate',
					CASE WHEN  RFQ.ModuleId = @SoqModuleId 
						 THEN 
							CASE WHEN (Select TOP 1 SOQA.CustomerSentDate From dbo.SalesOrderQuotePartV1 SOQP WITH(NOLOCK)
									INNER JOIN  DBO.SalesOrderQuoteApproval SOQA WITH(NOLOCK) ON SOQP.SalesOrderQuotePartId = SOQA.SalesOrderQuotePartId where SOQA.SalesOrderQuoteId =SOQ.SalesOrderQuoteId AND SOQP.PartNumber = RFQ.[LinePartNumber]) IS NOT NULL THEN CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, (Select  top 1 SOQA.CustomerSentDate From dbo.SalesOrderQuotePartV1 SOQP WITH(NOLOCK) INNER JOIN  DBO.SalesOrderQuoteApproval SOQA WITH(NOLOCK) ON SOQP.SalesOrderQuotePartId = SOQA.SalesOrderQuotePartId where SOQA.SalesOrderQuoteId =SOQ.SalesOrderQuoteId AND SOQP.PartNumber =RFQ.[LinePartNumber]))) ELSE NULL END
						 ELSE NULL END AS 'quoteSentDate',

					CASE 
						WHEN RFQ.IsQuote = 1 THEN	CASE	WHEN QSR.Code = @AautoSendQuote THEN 'Auto' 
															WHEN QSR.Code = @ReviewRequired THEN 'Review Required' 
															ELSE 'YES'	END
						WHEN RFQ.IsQuote = 2 THEN 'No Quote' 
						ELSE NULL
					END AS 'QuoteStatus',
					Expired = NULL,
					DaysTillExpire = NULL,
					DisableRow = CASE WHEN ISNULL(RFQ.IsQuote, 0) > 0 THEN 1 ELSE 0 END,
					VRFQ.VendorRFQId,
					(SELECT STRING_AGG(PurchaseOrderNumber, ', ')
						FROM (
							SELECT DISTINCT PO.PurchaseOrderNumber
							FROM DBO.VendorRFQPart VRFQP WITH(NOLOCK)
							INNER JOIN DBO.PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = VRFQP.ReferenceId
							WHERE VRFQP.ILSRFQDetailId = VRFQ.ILSRFQDetailId AND VRFQP.ModuleId = @PoModuleId
						) AS DistinctVendors
					 ) AS PurchaseOrderNumber,
					(SELECT STRING_AGG(VendorRFQPurchaseOrderNumber, ', ')
						FROM (
							SELECT DISTINCT VPO.VendorRFQPurchaseOrderNumber
							FROM DBO.VendorRFQPart VRFQP WITH(NOLOCK)
							INNER JOIN DBO.PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = VRFQP.ReferenceId
							INNER JOIN DBO.VendorRFQPurchaseOrderPart VPOP WITH(NOLOCK) ON VPOP.PurchaseOrderId = PO.PurchaseOrderId
							INNER JOIN DBO.VendorRFQPurchaseOrder VPO WITH(NOLOCK) ON VPO.VendorRFQPurchaseOrderId = VPOP.VendorRFQPurchaseOrderId
							WHERE VRFQP.ILSRFQDetailId = VRFQ.ILSRFQDetailId AND VRFQP.ModuleId = @PoModuleId
						) AS DistinctVendors
					 ) AS VendorRFQPurchaseOrderNumber,
					RR.ReferenceId AS POReferenceId,
					RR.ModuleId  AS POModuleId,
					RFQR.RFQReferenceId,
					RFQR.RFQModuleId,
					REPLACE(RFQ.RfqId, @CodePrefix, '')	AS RFQNum
					,CASE WHEN RFQ.ModuleId = @SoqModuleId AND ISNULL(RFQ.[ReferenceId], 0) > 0 THEN CASE WHEN SOQ.StatusId IN (SELECT Id FROM #tmpSalesOrderStatus) THEN 0 ELSE 1 END ELSE 0 END AS AllowAssign
					,CONVERT(DATETIME2, DATEADD(SECOND, @BaseUtcOffsetSec, RFQ.[FollowUpDate])) AS 'FollowUpDate'
				FROM dbo.CustomerRfq RFQ WITH (NOLOCK)
				--LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON RFQ.[LinePartNumber] = IM.[partnumber] AND RFQ.[MasterCompanyId] = IM.[MasterCompanyId]
				LEFT JOIN ItemResult IM WITH(NOLOCK) ON LOWER(TRIM(RFQ.[LinePartNumber])) = LOWER(TRIM(IM.[partnumber])) AND RFQ.[MasterCompanyId] = IM.[MasterCompanyId]
				LEFT JOIN StkResult STK WITH(NOLOCK) ON STK.ItemMasterId = IM.ItemMasterId AND RFQ.[MasterCompanyId] = IM.[MasterCompanyId]
				LEFT JOIN dbo.Customer CU WITH(NOLOCK) ON (LOWER(TRIM(RFQ.[BuyerCompanyName])) = LOWER(TRIM(CU.[Name])) AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) OR (RFQ.CustomerId = CU.CustomerId AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) AND CU.IsActive = 1 AND CU.IsDeleted = 0
				LEFT JOIN  dbo.CustomerContact CC  WITH (NOLOCK) 
					ON (
						   (RFQ.CustomerContactId > 0 AND CC.CustomerContactId = RFQ.CustomerContactId)
						OR (ISNULL(RFQ.CustomerContactId, 0) <= 0 
							AND CC.CustomerId = CU.CustomerId
							AND CC.IsDefaultContact = 1)
					   )
				LEFT JOIN  dbo.Contact  WITH (NOLOCK) ON CC.ContactId=Contact.ContactId
				LEFT JOIN dbo.Employee EM WITH(NOLOCK) ON RFQ.[EmployeeId] = EM.[EmployeeId] AND RFQ.[MasterCompanyId] = EM.[MasterCompanyId]
				LEFT JOIN dbo.SalesOrderQuote SOQ WITH(NOLOCK) ON RFQ.[ReferenceId] = SOQ.[SalesOrderQuoteId] AND RFQ.[MasterCompanyId] = SOQ.[MasterCompanyId]
				LEFT JOIN dbo.SalesOrder SO WITH(NOLOCK) ON RFQ.[ReferenceId] = SO.[SalesOrderId] AND RFQ.[MasterCompanyId] = SO.[MasterCompanyId]
				LEFT JOIN dbo.QuoteSendReview QSR WITH(NOLOCK) ON QSR.QuoteSendReviewId = RFQ.QuoteSendReviewId
				LEFT JOIN #VendorsRFQResult VRFQ WITH(NOLOCK) ON RFQ.CustomerRfqId = VRFQ.CustomerRfqId AND LOWER(TRIM(RFQ.LinePartNumber)) = LOWER(TRIM(VRFQ.PartNumber)) AND LOWER(TRIM(RFQ.Condition)) = LOWER(TRIM(VRFQ.Condition))
				LEFT JOIN VendorRFQReferenceResult RR ON RR.ILSRFQDetailId = VRFQ.ILSRFQDetailId AND RR.[MasterCompanyId] = VRFQ.[MasterCompanyId] 
				LEFT JOIN RFQReferenceResult RFQR ON RFQR.ILSRFQDetailId = VRFQ.ILSRFQDetailId AND RFQR.[MasterCompanyId] = VRFQ.[MasterCompanyId] 
				--OUTER APPLY (
				--	SELECT TOP 1 RIM.ItemMasterId, RIM.partnumber, RIM.PartDescription
				--	FROM [dbo].[ItemMaster] RIM WITH(NOLOCK)
				--	WHERE RFQ.[LinePartNumber] = RIM.[partnumber] AND RFQ.[MasterCompanyId] = RIM.[MasterCompanyId]
				--) IM
				WHERE RFQ.MasterCompanyId = @MasterCompanyId 
				AND (@IntegrationPortalId IS NULL OR RFQ.IntegrationPortalId = @IntegrationPortalId)
				AND RFQ.IntegrationPortalId IN (@ILSPortalId, @OneFortyFivePortalId, @PartsBasePortalId)
				AND RFQ.IsActive = 1 AND RFQ.IsDeleted = 0

				UNION ALL

				SELECT RFQ.[CustomerRfqId],
					RFQ.[RfqId], 
					CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, RFQ.[RfqCreatedDate])) AS 'RfqcreatedDate',
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
					CASE WHEN ISNULL(STk.StockLineId,0) > 0 THEN 1 ELSE 0 END StockLineId,
					--ISNULL((SELECT TOP 1 CASE WHEN ISNULL(STk.StockLineId,0) > 0 THEN 1 ELSE 0 END  FROM dbo.Stockline STK WITH(NOLOCK) WHERE IM.[itemmasterid] = STK.[itemmasterid] AND ISNULL(STK.[QuantityAvailable],0) > 0),0) StockLineId,
					RFQ.EmployeeId,
					CONCAT(EM.FirstName, ' ', EM.LastName) AS EmployeeName,
					CASE WHEN RFQ.ModuleId = @SoqModuleId THEN ISNULL(SOQ.[SalesOrderQuoteNumber],'')
						 WHEN RFQ.ModuleId = @SoModuleId THEN ISNULL(SO.[SalesOrderNumber],'') END AS RefrenceQuoteNumber,
					CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, RFQ.[DateAssigned])) AS 'DateAssigned',
					RFQ.[QuotedBy],
					CASE WHEN  RFQ.ModuleId = @SoqModuleId THEN CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, SOQ.[CreatedDate])) ELSE CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, RFQ.[QuotedDate])) END AS 'QuotedDate',
					CASE WHEN  RFQ.ModuleId = @SoqModuleId 
						 THEN 
							CASE WHEN (Select TOP 1 SOQA.CustomerSentDate From dbo.SalesOrderQuotePartV1 SOQP WITH(NOLOCK)
									INNER JOIN  DBO.SalesOrderQuoteApproval SOQA WITH(NOLOCK) ON SOQP.SalesOrderQuotePartId = SOQA.SalesOrderQuotePartId where SOQA.SalesOrderQuoteId =SOQ.SalesOrderQuoteId AND SOQP.PartNumber = CRPM.[PartNumber]) IS NOT NULL THEN CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, (Select top 1 SOQA.CustomerSentDate From dbo.SalesOrderQuotePartV1 SOQP WITH(NOLOCK) INNER JOIN  DBO.SalesOrderQuoteApproval SOQA WITH(NOLOCK) ON SOQP.SalesOrderQuotePartId = SOQA.SalesOrderQuotePartId where SOQA.SalesOrderQuoteId =SOQ.SalesOrderQuoteId AND SOQP.PartNumber = CRPM.[PartNumber]))) ELSE NULL END
						 ELSE NULL END AS 'quoteSentDate',
					CASE 
						WHEN RFQ.IsQuote = 1 THEN	CASE	WHEN QSR.Code = @AautoSendQuote THEN 'Auto' 
															WHEN QSR.Code = @ReviewRequired THEN 'Review Required' 
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
					END AS 'DisableRow',
					VRFQ.VendorRFQId,
					(SELECT STRING_AGG(PurchaseOrderNumber, ', ')
						FROM (
							SELECT DISTINCT PO.PurchaseOrderNumber
							FROM DBO.VendorRFQPart VRFQP WITH(NOLOCK)
							INNER JOIN DBO.PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = VRFQP.ReferenceId
							WHERE VRFQP.ILSRFQDetailId = VRFQ.ILSRFQDetailId AND VRFQP.ModuleId = @PoModuleId
						) AS POResult
					) AS PurchaseOrderNumber,
					(SELECT STRING_AGG(VendorRFQPurchaseOrderNumber, ', ')
						FROM (
							SELECT DISTINCT VPO.VendorRFQPurchaseOrderNumber
							FROM DBO.VendorRFQPart VRFQP WITH(NOLOCK)
							INNER JOIN DBO.PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = VRFQP.ReferenceId
							INNER JOIN DBO.VendorRFQPurchaseOrderPart VPOP WITH(NOLOCK) ON VPOP.PurchaseOrderId = PO.PurchaseOrderId
							INNER JOIN DBO.VendorRFQPurchaseOrder VPO WITH(NOLOCK) ON VPO.VendorRFQPurchaseOrderId = VPOP.VendorRFQPurchaseOrderId
							WHERE VRFQP.ILSRFQDetailId = VRFQ.ILSRFQDetailId AND VRFQP.ModuleId = @PoModuleId
						) AS VPOResult
					) AS VendorRFQPurchaseOrderNumber,
					RR.ReferenceId AS POReferenceId,
					RR.ModuleId  AS POModuleId,
					RFQR.RFQReferenceId,
					RFQR.RFQModuleId,
					REPLACE(RFQ.RfqId, @CodePrefix, '')	AS RFQNum
					,CASE WHEN RFQ.ModuleId = @SoqModuleId AND ISNULL(RFQ.[ReferenceId], 0) > 0 THEN CASE WHEN SOQ.StatusId IN (SELECT Id FROM #tmpSalesOrderStatus) THEN 0 ELSE 1 END ELSE 0 END AS AllowAssign
					,CONVERT(DATETIME2, DATEADD(SECOND, @BaseUtcOffsetSec, RFQ.[FollowUpDate])) AS 'FollowUpDate'
				FROM dbo.CustomerRfq RFQ WITH (NOLOCK)
				LEFT JOIN dbo.Customer CU WITH(NOLOCK) ON (LOWER(TRIM(RFQ.[BuyerCompanyName])) = LOWER(TRIM(CU.[Name])) AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) OR (RFQ.CustomerId = CU.CustomerId AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) AND CU.IsActive = 1 AND CU.IsDeleted = 0
				LEFT JOIN  dbo.CustomerContact CC  WITH (NOLOCK) 
					ON (
						   (RFQ.CustomerContactId > 0 AND CC.CustomerContactId = RFQ.CustomerContactId)
						OR (ISNULL(RFQ.CustomerContactId, 0) <= 0 
							AND CC.CustomerId = CU.CustomerId
							AND CC.IsDefaultContact = 1)
					   )
				LEFT JOIN  dbo.Contact  WITH (NOLOCK) ON CC.ContactId=Contact.ContactId
				LEFT JOIN dbo.Employee EM WITH(NOLOCK) ON RFQ.[EmployeeId] = EM.[EmployeeId] AND RFQ.[MasterCompanyId] = EM.[MasterCompanyId]
				LEFT JOIN dbo.SalesOrderQuote SOQ WITH(NOLOCK) ON RFQ.[ReferenceId] = SOQ.[SalesOrderQuoteId] AND RFQ.[MasterCompanyId] = SOQ.[MasterCompanyId]
				LEFT JOIN dbo.SalesOrder SO WITH(NOLOCK) ON RFQ.[ReferenceId] = SO.[SalesOrderId] AND RFQ.[MasterCompanyId] = SO.[MasterCompanyId]
				LEFT JOIN dbo.CustomerRfqPartMapping CRPM WITH(NOLOCK) ON RFQ.[CustomerRfqId] = CRPM.[CustomerRfqId]
				--LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON CRPM.[PartNumber] = IM.[partnumber] AND CRPM.[MasterCompanyId] = IM.[MasterCompanyId]
				LEFT JOIN ItemResult IM WITH(NOLOCK) ON LOWER(TRIM(CRPM.[PartNumber])) = LOWER(TRIM(IM.[partnumber])) AND CRPM.[MasterCompanyId] = IM.[MasterCompanyId]
				LEFT JOIN StkResult STK WITH(NOLOCK) ON STK.ItemMasterId = IM.ItemMasterId AND RFQ.[MasterCompanyId] = IM.[MasterCompanyId]
				LEFT JOIN dbo.QuoteSendReview QSR WITH(NOLOCK) ON QSR.QuoteSendReviewId = RFQ.QuoteSendReviewId
				LEFT JOIN #VendorsRFQResult VRFQ WITH(NOLOCK) ON RFQ.CustomerRfqId = VRFQ.CustomerRfqId AND LOWER(TRIM(CRPM.PartNumber)) = LOWER(TRIM(VRFQ.PartNumber)) AND LOWER(TRIM(CRPM.Condition)) = LOWER(TRIM(VRFQ.Condition))
				LEFT JOIN VendorRFQReferenceResult RR ON RR.ILSRFQDetailId = VRFQ.ILSRFQDetailId AND RR.[MasterCompanyId] = VRFQ.[MasterCompanyId] 
				LEFT JOIN RFQReferenceResult RFQR ON RFQR.ILSRFQDetailId = VRFQ.ILSRFQDetailId AND RFQR.[MasterCompanyId] = VRFQ.[MasterCompanyId] 
				--OUTER APPLY (
				--	SELECT TOP 1 RIM.ItemMasterId, RIM.partnumber, RIM.PartDescription
				--	FROM [dbo].[ItemMaster] RIM WITH(NOLOCK)
				--	WHERE RFQ.[LinePartNumber] = RIM.[partnumber] AND RFQ.[MasterCompanyId] = RIM.[MasterCompanyId]
				--) IM
				WHERE RFQ.MasterCompanyId = @MasterCompanyId 
				AND RFQ.IntegrationPortalId IN (@EmailPortalId)
				AND RFQ.IsActive = 1 AND RFQ.IsDeleted = 0
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
							(QuoteSentDate like '%' +@GlobalFilter+'%') OR
							(EmployeeName like '%'+@GlobalFilter+'%') OR
							(Condition like '%'+@GlobalFilter+'%') OR
							(CAST(Quantity AS varchar(20)) like '%'+@GlobalFilter+'%') OR
							(VendorRFQId like '%'+@GlobalFilter+'%') OR
							(PurchaseOrderNumber like '%'+@GlobalFilter+'%') OR
							(VendorRFQPurchaseOrderNumber like '%'+@GlobalFilter+'%') OR
							(QuoteStatus like '%'+@GlobalFilter+'%') OR
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
							(IsNull(@QuoteSentDate,'') ='' OR Cast(QuoteSentDate as date)=Cast(@QuoteSentDate as date)) and
							(IsNull(@BuyerCompanyName,'') ='' OR companyName like '%'+@BuyerCompanyName+'%') and
							(IsNull(@BuyerCountry,'') ='' OR country like '%'+ @BuyerCountry+'%') and
							(IsNull(@LinePartNumber,'') ='' OR partNumber like '%'+@LinePartNumber+'%') and
							(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%'+ @CreatedBy+'%') and
							(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%'+ @UpdatedBy+'%') and
							(IsNull(@EmployeeName,'') ='' OR EmployeeName like '%'+ @EmployeeName +'%') and
							(IsNull(@RefrenceQuoteNumber,'') ='' OR RefrenceQuoteNumber like '%'+ @RefrenceQuoteNumber +'%') and
							(IsNull(@Condition,'') ='' OR Condition like '%'+ @Condition +'%') and
							(IsNull(@VendorRFQId,'') ='' OR VendorRFQId like '%'+ @VendorRFQId +'%') and
							(IsNull(@PurchaseOrderNumber,'') ='' OR PurchaseOrderNumber like '%'+ @PurchaseOrderNumber +'%') and
							(IsNull(@VendorRFQPurchaseOrderNumber,'') ='' OR VendorRFQPurchaseOrderNumber like '%'+ @VendorRFQPurchaseOrderNumber +'%') and
							(IsNull(@Quantity,'') ='' OR CAST(Quantity AS VARCHAR(20)) like '%' + CAST(@Quantity AS VARCHAR(20)) + '%') and 
							(IsNull(@SendQuote,'') ='' OR QuoteStatus like '%'+ @SendQuote +'%') and
							(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and
							(IsNull(@FollowUpDate,'') ='' OR Cast(FollowUpDate as Date)=Cast(@FollowUpDate as date)) and
							(IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)))
							)),
						ResultCount AS (Select COUNT(CustomerRfqId) AS NumberOfItems FROM FinalResult)


					SELECT * INTO #resultTemp 
					FROM FinalResult, ResultCount
					ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERRFQID')  THEN CustomerRfqId END DESC,
					CASE WHEN (@SortOrder=1 and @SortColumn='RFQID')  THEN RFQNum END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='RFQCREATEDDATETYPE')  THEN RfqcreatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='DateAssigned')  THEN DateAssigned END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='QuotedBy')  THEN QuotedBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='QuotedDate')  THEN QuotedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='QuoteSentDate')  THEN QuoteSentDate END ASC,
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
					CASE WHEN (@SortOrder=1 and @SortColumn='Condition')  THEN Condition END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Quantity')  THEN Quantity END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='VendorRFQId')  THEN VendorRFQId END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SendQuote')  THEN QuoteStatus END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='FollowUpDate')  THEN FollowUpDate END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERRFQID')  THEN CustomerRfqId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RFQID')  THEN RFQNum END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='RFQCREATEDDATETYPE')  THEN RfqcreatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='DateAssigned')  THEN DateAssigned END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='QuotedBy')  THEN QuotedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='QuotedDate')  THEN QuotedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='QuoteSentDate')  THEN QuoteSentDate END DESC,
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
					CASE WHEN (@SortOrder=-1 and @SortColumn='RefrenceQuoteNumber')  THEN RefrenceQuoteNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Condition')  THEN Condition END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Quantity')  THEN Quantity END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='VendorRFQId')  THEN VendorRFQId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SendQuote')  THEN QuoteStatus END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='FollowUpDate')  THEN FollowUpDate END DESC
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
			SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
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