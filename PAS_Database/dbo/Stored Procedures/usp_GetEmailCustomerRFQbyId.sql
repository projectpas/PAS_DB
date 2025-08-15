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
 **	3		15-Aug-2025		Devendra Shekh			Modified for Price Changes
 
EXECUTE [dbo].[usp_GetEmailCustomerRFQbyId] 172
**************************************************************/  
CREATE   PROCEDURE [dbo].[usp_GetEmailCustomerRFQbyId]
@CustomerRfqId BIGINT = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
	BEGIN TRY
		BEGIN
			
			DECLARE @TotalRow INT, @CurrentRow INT;
			DECLARE @CustomerRfqPartMappingId BIGINT, @MasterCompanyId INT, @PartNumber VARCHAR(250), @Condition VARCHAR(250);

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
				UnitPrice [decimal](18,2) NULL
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

			INSERT INTO #tmpCustomerRfqPartMapping
			SELECT	[CustomerRfqPartMappingId], [CustomerRfqId], [Notes], [PartNumber], [PartDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId], [CreatedBy], [CreatedDate],
					[UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], 0
			FROM [dbo].[CustomerRfqPartMapping] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;

			SELECT @TotalRow = MAX(Id), @CurrentRow = MIN(Id) FROM #tmpCustomerRfqPartMapping;
			
			WHILE(ISNULL(@TotalRow, 0) >= ISNULL(@CurrentRow, 0)) AND @TotalRow > 0
			BEGIN
				SELECT @CustomerRfqPartMappingId = CustomerRfqPartMappingId, @MasterCompanyId = MasterCompanyId, @PartNumber = PartNumber, @Condition = Condition FROM #tmpCustomerRfqPartMapping WHERE Id = @CurrentRow;

				TRUNCATE TABLE #tmpResult
				INSERT INTO #tmpResult
				EXEC [dbo].[USP_GetRFQHistoryByPartNumberCondition]	@PartNumber, @Condition, @MasterCompanyId

				UPDATE TMP
				SET	TMP.UnitPrice = (SELECT ISNULL(UnitPrice,0) FROM #tmpResult)
				FROM #tmpCustomerRfqPartMapping TMP WHERE Id = @CurrentRow
				
				SET @CurrentRow += 1;
			END

			SELECT	[CustomerRfqId], [RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes], [BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity], [BuyerCountry], 
					[BuyerState], [BuyerZip], [LinePartNumber], [LineDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId], [CreatedBy], [CreatedDate],
					[UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [IsQuote], [IsMRO], [ModuleId], [ReferenceId]
			FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;

			SELECT	[CustomerRfqPartMappingId], [CustomerRfqId], [Notes], [PartNumber], [PartDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId], [CreatedBy], [CreatedDate],
					[UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], UnitPrice
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