/*************************************************************           
 ** File:   [USP_GetSalesQuoteIdFromCustomerRfq]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used get the Sales Quote Id 
 ** Purpose:         
 ** Date:   20 Aug 2025
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
	1    20 Aug 2025	Moin Bloch		    Created

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSalesQuoteIdFromCustomerRfq]
@tbl_CustomerRfqIdListType dbo.CustomerRfqIdListType READONLY
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		DECLARE @TotalRecord INT = 0;   
		DECLARE @MinId BIGINT = 1;  
		DECLARE @ModuleId INT = 0;   
		DECLARE @QuoteReviewRequiredId BIGINT = 0, @Code VARCHAR(50) = 'Review Required';

		SELECT @ModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';
		SELECT @QuoteReviewRequiredId = QuoteSendReviewId FROM [dbo].[QuoteSendReview] WITH(NOLOCK) WHERE [Code] = @Code;				

		IF OBJECT_ID(N'tempdb..#tmpCustomerRfqIdFromCustomerRfq') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCustomerRfqIdFromCustomerRfq
		END
		IF OBJECT_ID(N'tempdb..#tmpSalesQuoteIdFromCustomerRfq') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSalesQuoteIdFromCustomerRfq
		END

		CREATE TABLE #tmpCustomerRfqIdFromCustomerRfq
		(
			[ID] BIGINT NOT NULL IDENTITY, 
			[CustomerRfqId] [BIGINT] NULL				
		)		

		CREATE TABLE #tmpSalesQuoteIdFromCustomerRfq
		(
			[ID] BIGINT NOT NULL IDENTITY, 
			[SalesOrderQuoteId] [BIGINT] NULL				
		)				   

		INSERT INTO #tmpCustomerRfqIdFromCustomerRfq ([CustomerRfqId])
		SELECT TMP.[CustomerRfqId] FROM @tbl_CustomerRfqIdListType TMP
		INNER JOIN [dbo].[CustomerRfq] RFQ WITH(NOLOCK) ON TMP.CustomerRfqId = RFQ.CustomerRfqId
		WHERE RFQ.QuoteSendReviewId != @QuoteReviewRequiredId;

		SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmpCustomerRfqIdFromCustomerRfq    

		WHILE @MinId <= @TotalRecord
		BEGIN	
			DECLARE @CustomerRfqId BIGINT = 0,@SalesOrderQuoteId BIGINT = 0

			SELECT @CustomerRfqId = [CustomerRfqId]			          
			FROM #tmpCustomerRfqIdFromCustomerRfq 
			WHERE [ID] = @MinId
											
			SELECT @SalesOrderQuoteId = [ReferenceId] 
			FROM [dbo].[CustomerRfq] WITH(NOLOCK) 
			WHERE [CustomerRfqId] = @CustomerRfqId AND [ModuleId] = @ModuleId	
			
			IF(@SalesOrderQuoteId > 0)
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM [dbo].[SalesOrderQuoteApproval] WITH(NOLOCK) WHERE [SalesOrderQuoteId] = @SalesOrderQuoteId AND [IsActive] = 1 AND [IsDeleted] = 0)
				BEGIN
					INSERT INTO #tmpSalesQuoteIdFromCustomerRfq ([SalesOrderQuoteId])
					SELECT @SalesOrderQuoteId
				END
			END
						
			SET @MinId = @MinId + 1
		END

		SELECT * FROM #tmpSalesQuoteIdFromCustomerRfq		
	END		

	END TRY	
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_GetSalesQuoteIdFromCustomerRfq' 
		, @ProcedureParameters VARCHAR(3000) = '@EmployeeId = ''' + CAST(ISNULL(1, '') AS VARCHAR(100))
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