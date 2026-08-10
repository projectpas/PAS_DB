/*************************************************************             
 ** File:   [usp_GetEmailCustomerRFQbyId]             
 ** Author:   Devendra Shekh    
 ** Description: Get Customer RFQ Details By Id
 ** Date:   08-Aug-2025 
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO	Date				Author				Change Description              
 ** --		--------			-------				--------------------------------            
 **	1		08-Aug-2025		Devendra Shekh			Created
 **	2		13-Aug-2025		Devendra Shekh			Added Changes for Suggestion Price
 **	3		15-Aug-2025		Devendra Shekh			Modified for Price Changes, Added QuoteSendReviewId
 **	4		25-Sep-2025		Devendra Shekh		    Added Changes for [ItemMasterId] and [StockLineId] 
 ** 5       03-Oct-2025     Devendra Shekh			Added [IsCustomerStock] for Stk
 ** 6       07-Oct-2025     Devendra Shekh			Added [CustomerId]
 ** 7       13-Oct-2025     Devendra Shekh			Added [VendorRFQId], [ThirdPartyRFQId], [ILSRFQPartId]
	8    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	9    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
EXECUTE [dbo].[usp_GetEmailCustomerRFQbyId] 1005
**************************************************************/  
CREATE PROCEDURE [dbo].[usp_GetEmailCustomerRFQbyId]
@CustomerRfqId BIGINT = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
	BEGIN TRY
		BEGIN
			
			DECLARE @TotalRow INT, @CurrentRow INT;
			DECLARE @CustomerRfqPartMappingId BIGINT, @MasterCompanyId INT, @PartNumber VARCHAR(250), @Condition VARCHAR(250), @VendorRFQId VARCHAR(50);

			IF OBJECT_ID('tempdb..#tmpCustomerRfqPartMapping') IS NOT NULL
				DROP TABLE #tmpCustomerRfqPartMapping;

			CREATE TABLE #tmpCustomerRfqPartMapping (
				Id [bigint] IDENTITY(1,1),
				CustomerRfqPartMappingId [bigint] NULL,
				CustomerRfqId [bigint] NULL,
				Notes [varchar](max) NULL,
				PartNumber [varchar](250) NULL,
				PartDescription [varchar](250) NULL,
				AltPartNumber [varchar](250) NULL,
				Quantity [int] NULL,
				Condition [varchar](250) NULL,
				MasterCompanyId [int] NULL,
				CreatedBy [varchar](50) NULL,
				CreatedDate [datetime2](7) NULL,
				UpdatedBy [varchar](50) NULL,
				UpdatedDate [datetime2](7) NULL,
				IsActive [bit] NULL,
				IsDeleted [bit] NULL,
				UnitPrice [decimal](18,2) NULL,
				QuoteSendReviewId [Int] NULL,
				ItemMasterId [bigint] NULL,
				StockLineId [bigint] NULL,
				CustomerId [bigint] NULL,
				VendorRFQId [varchar](50) NULL,
				ThirdPartyRFQId [bigint] NULL,
				ILSRFQPartId [bigint] NULL,
			);

			IF OBJECT_ID(N'tempdb..#tmpResult') IS NOT NULL
			BEGIN
				DROP TABLE #tmpResult
			END

			CREATE TABLE #tmpResult
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
			
			SELECT @MasterCompanyId = [MasterCompanyId] FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;

			;With ItemResult AS (
				SELECT MAX(RIM.ItemMasterId) AS ItemMasterId, RIM.partnumber AS partnumber, MAX(RIM.PartDescription) AS PartDescription, RIM.MasterCompanyId 
				FROM [dbo].[ItemMaster] RIM WITH(NOLOCK) 
				WHERE RIM.[MasterCompanyId] = @MasterCompanyId AND RIM.IsActive = 1 AND RIM.IsDeleted = 0
				 AND ISNULL(RIM.IsNonStock,0) = 0
				 GROUP BY RIM.partnumber, RIM.MasterCompanyId
			),	
			StkResult AS (
				SELECT  MAX(STK.StockLineId) AS StockLineId, STK.ItemMasterId, STK.MasterCompanyId  
				FROM [dbo].[Stockline] STK WITH(NOLOCK) 
				INNER JOIN ItemResult RIM ON STK.ItemMasterId = RIM.ItemMasterId AND STK.MasterCompanyId = RIM.MasterCompanyId
				WHERE STK.[MasterCompanyId] = @MasterCompanyId AND STK.IsActive = 1 AND STK.IsDeleted = 0 AND ISNULL(STK.[QuantityAvailable],0) > 0 AND ISNULL(STK.[IsCustomerStock],0) = 0 AND ISNULL(STK.IsNonStock,0) = 0
				GROUP BY STK.ItemMasterId, STK.MasterCompanyId
			)
			INSERT INTO #tmpCustomerRfqPartMapping
			SELECT	[CustomerRfqPartMappingId], CRFQ.[CustomerRfqId], CRFQ.[Notes], CRFQ.[PartNumber], CRFQ.[PartDescription], CRFQ.[AltPartNumber], CRFQ.[Quantity], CRFQ.[Condition], CRFQ.[MasterCompanyId], CRFQ.[CreatedBy], CRFQ.[CreatedDate],
					CRFQ.[UpdatedBy], CRFQ.[UpdatedDate], CRFQ.[IsActive], CRFQ.[IsDeleted], 0, 0, IM.ItemMasterId, CASE WHEN ISNULL(STk.StockLineId,0) > 0 THEN 1 ELSE 0 END StockLineId
					,(CASE WHEN ISNULL(RFQ.CustomerId ,0) > 0 THEN RFQ.CustomerId WHEN LOWER(TRIM(CU.[Name])) = LOWER(TRIM(RFQ.BuyerCompanyName)) THEN CU.[CustomerId] ELSE 0 END) CustomerId, @VendorRFQId, 0, 0
			FROM [dbo].[CustomerRfqPartMapping] CRFQ WITH(NOLOCK)
			LEFT JOIN ItemResult IM WITH(NOLOCK) ON LOWER(TRIM(CRFQ.[PartNumber])) = LOWER(TRIM(IM.[partnumber])) AND CRFQ.[MasterCompanyId] = IM.[MasterCompanyId]
			LEFT JOIN StkResult STK WITH(NOLOCK) ON STK.ItemMasterId = IM.ItemMasterId AND CRFQ.[MasterCompanyId] = IM.[MasterCompanyId]
			INNER JOIN [dbo].[CustomerRfq] RFQ WITH(NOLOCK) ON CRFQ.CustomerRfqId = RFQ.CustomerRfqId
			LEFT JOIN [dbo].[Customer] CU WITH(NOLOCK) ON (LOWER(TRIM(RFQ.[BuyerCompanyName])) = LOWER(TRIM(CU.[Name])) AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) OR (RFQ.CustomerId = CU.CustomerId AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]) AND CU.IsActive = 1 AND CU.IsDeleted = 0
			WHERE CRFQ.[CustomerRfqId] = @CustomerRfqId;

			SELECT @TotalRow = MAX(Id), @CurrentRow = MIN(Id) FROM #tmpCustomerRfqPartMapping;
			
			WHILE(ISNULL(@TotalRow, 0) >= ISNULL(@CurrentRow, 0)) AND @TotalRow > 0
			BEGIN
				SELECT @CustomerRfqPartMappingId = CustomerRfqPartMappingId, @MasterCompanyId = MasterCompanyId, @PartNumber = PartNumber, @Condition = Condition FROM #tmpCustomerRfqPartMapping WHERE Id = @CurrentRow;

				TRUNCATE TABLE #tmpResult
				INSERT INTO #tmpResult
				EXEC [dbo].[USP_GetRFQHistoryByPartNumberCondition]	@PartNumber, @Condition, @MasterCompanyId

				UPDATE TMP
				SET	TMP.UnitPrice = (SELECT ISNULL(UnitPrice,0) FROM #tmpResult),
					TMP.QuoteSendReviewId = (SELECT ISNULL(QuoteSendReviewId,0) FROM #tmpResult),
					TMP.VendorRFQId = VRFQResult.RFQId,
					TMP.ThirdPartyRFQId = VRFQResult.ThirdPartyRFQId,
					TMP.ILSRFQPartId = VRFQResult.ILSRFQPartId
				FROM #tmpCustomerRfqPartMapping TMP
				OUTER APPLY (
					SELECT ILS.ThirdPartyRFQId, ILS.MasterCompanyId, ILSP.CustomerRfqId, TRQ.RFQId, MAX(ILSP.ILSRFQPartId) AS ILSRFQPartId
					FROM [dbo].[ThirdPartyRFQ] TRQ WITH(NOLOCK)
					INNER JOIN [dbo].[ILSRFQDetail] ILS WITH(NOLOCK) ON ILS.ThirdPartyRFQId = TRQ.ThirdPartyRFQId
					INNER JOIN [dbo].[ILSRFQPart] ILSP WITH(NOLOCK) ON ILSP.ILSRFQDetailId = ILS.ILSRFQDetailId AND LOWER(TRIM(ILSP.PartNumber)) = LOWER(TRIM(TMP.PartNumber)) AND LOWER(TRIM(ILSP.Condition)) = LOWER(TRIM(TMP.Condition)) AND ILSP.CustomerRfqId = TMP.CustomerRfqId
					WHERE ILSP.CustomerRfqId = TMP.CustomerRfqId AND ILSP.MasterCompanyId = TMP.MasterCompanyId
					GROUP BY ILS.ThirdPartyRFQId, ILS.MasterCompanyId, ILSP.CustomerRfqId, TRQ.RFQId
				) AS VRFQResult
				WHERE Id = @CurrentRow
				
				SET @CurrentRow += 1;
			END

			SELECT	[CustomerRfqId], [RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes], [BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity], [BuyerCountry], 
					[BuyerState], [BuyerZip], [LinePartNumber], [LineDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId], [CreatedBy], [CreatedDate],
					[UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [IsQuote], [IsMRO], [ModuleId], [ReferenceId]
			FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;

			SELECT	[CustomerRfqPartMappingId], [CustomerRfqId], [Notes], [PartNumber], [PartDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId], [CreatedBy], [CreatedDate],
					[UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [UnitPrice], [QuoteSendReviewId], [ItemMasterId], [StockLineId], [CustomerId], [VendorRFQId], [ThirdPartyRFQId], [ILSRFQPartId]
			FROM #tmpCustomerRfqPartMapping;
			
		END
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_GetEmailCustomerRFQbyId' 
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