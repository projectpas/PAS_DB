
/*************************************************************           
 ** File:   [USP_SendOneFourtyFiveQuote]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used Send One Fourty Five Quote Data Into Our Database
 ** Purpose:         
 ** Date:   05 Mar 2024      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05 Mar 2024  Rajesh Gami    Created
     
-- EXEC USP_SendOneFourtyFiveQuote
************************************************************************/
Create     PROCEDURE [dbo].[USP_SendOneFourtyFiveQuote]
	@tbl_CustomerRfqQuoteDetailsType CustomerRfqQuoteDetailsType READONLY,
	@CustomerRfqId BIGINT,
	@RfqId BIGINT,
	@AddComment VARCHAR(250),
	@IsAddCommentQuote BIT,
	@FaaEasaRelease VARCHAR(250),
	@IsFaaEasaReleaseQuote BIT,
	@RpOh VARCHAR(250),
	@IsRpOhQuote BIT,
	@LegalEntityId BIGINT,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

					DECLARE @CustomerRfqQuoteId BIGINT, @GetCustomerRfqId BIGINT;

					SELECT @GetCustomerRfqId = CustomerRfqId FROM CustomerRfq WHERE RfqId = @RfqId;

		--------------------------- Insert into Rfq Quote table --------------------------------------------------

					INSERT INTO [dbo].[CustomerRfqQuote]
										   ([CustomerRfqId] ,[RfqId] ,[AddComment] ,[IsAddCommentQuote] ,[FaaEasaRelease] ,[IsFaaEasaReleaseQuote] ,
											[RpOh] ,[IsRpOhQuote] ,[LegalEntityId] ,[MasterCompanyId] ,	
											[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES (@GetCustomerRfqId ,@RfqId ,@AddComment ,@IsAddCommentQuote ,@FaaEasaRelease ,@IsFaaEasaReleaseQuote ,
									   @RpOh ,@IsRpOhQuote ,@LegalEntityId ,@MasterCompanyId ,
									   @CreatedBy ,GETUTCDATE() ,@CreatedBy ,GETUTCDATE() ,1 ,0);

					SELECT @CustomerRfqQuoteId = SCOPE_IDENTITY();	
		
		------------------- Customer RFQ Quote Details add ---------------------------------------------------------

					--IF OBJECT_ID(N'tempdb..#tmpCustomerRfqQuoteDetails') IS NOT NULL
					--BEGIN
					--	DROP TABLE #tmpCustomerRfqQuoteDetails
					--END
			
					--CREATE TABLE #tmpCustomerRfqQuoteDetails
					--(
					--	ID BIGINT NOT NULL IDENTITY, 
					--	[ServiceType] [INT] NULL,
					--	[QuotePrice] [DECIMAL](10,2) NULL,
					--	[QuoteTat] [DECIMAL](10,2) NULL,
					--	[Low] [DECIMAL](10,2) NULL,
					--	[Mid] [DECIMAL](10,2) NULL,
					--	[High] [DECIMAL](10,2) NULL,
					--	[AvgTat] [DECIMAL](10,2) NULL,
					--	[QuoteTatQty] [INT] NULL,
					--	[QuoteCond] [VARCHAR](150) NULL,
					--	[QuoteTrace] [VARCHAR](150) NULL,
					--	[CreatedBy] [VARCHAR](50) NOT NULL,
					--	[CreatedDate] [datetime2](7) NOT NULL,
					--	[UpdatedBy] [VARCHAR](50) NOT NULL,
					--	[UpdatedDate] [DATETIME2](7) NOT NULL,
					--	[IsActive] [BIT] NOT NULL,
					--	[IsDeleted] [BIT] NOT NULL,
					--)

					--INSERT INTO #tmpCustomerRfqQuoteDetails ([ServiceType] ,[QuotePrice] ,[QuoteTat] ,[Low] ,[Mid] ,
					--			[High] ,[AvgTat] ,[QuoteTatQty] ,[QuoteCond] ,[QuoteTrace] ,
					--			[CreatedBy] ,[CreatedDate] ,[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
					--SELECT [ServiceType] ,[QuotePrice] ,[QuoteTat] ,[Low] ,[Mid] ,
					--	   [High] ,[AvgTat] ,[QuoteTatQty] ,[QuoteCond] ,[QuoteTrace] ,
					--	   @CreatedBy ,GETUTCDATE() ,@CreatedBy ,GETUTCDATE() ,1 ,0
					--FROM @tbl_CustomerRfqQuoteDetailsType;

					INSERT INTO [dbo].[CustomerRfqQuoteDetails]
							   ([CustomerRfqQuoteId] ,[ServiceType] ,[QuotePrice] ,[QuoteTat] ,[Low] ,[Mid] ,
								[High] ,[AvgTat] ,[QuoteTatQty] ,[QuoteCond] ,[QuoteTrace] ,	
								[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
					SELECT @CustomerRfqQuoteId ,[ServiceType] ,[QuotePrice] ,[QuoteTat] ,[Low] ,[Mid] ,
						   [High] ,[AvgTat] ,[QuoteTatQty] ,[QuoteCond] ,[QuoteTrace] ,
						   @CreatedBy, @CreatedBy ,GETUTCDATE() ,GETUTCDATE() ,1 ,0
					 FROM @tbl_CustomerRfqQuoteDetailsType;

					 ------- Update Csutomer RFQ for Is Quote added ----------
					 
					 UPDATE [dbo].[CustomerRfq] 
						SET IsQuote = 1
					 WHERE CustomerRfqId = @GetCustomerRfqId;
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_SendOneFourtyFiveQuote' 
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