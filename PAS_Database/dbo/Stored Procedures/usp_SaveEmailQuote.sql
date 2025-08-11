/*************************************************************           
 ** File:   [usp_SaveEmailQuote]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used Send ILS QUOTE Into Our Database
 ** Purpose:         
 ** Date:   08 Aug 2025      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    08 Aug 2025	Devendra Shekh		Created
     
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_SaveEmailQuote]
	@tbl_EmailRfqQuoteDetailsType EmailRfqQuoteDetailsType READONLY,
	@CustomerRfqQuoteId BIGINT = NULL,
	@CustomerRfqId BIGINT,
	@RfqId NVARCHAR(200) NULL,
	@LegalEntityId BIGINT,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN

		DECLARE @GetCustomerRfqId BIGINT, @PercentId BIGINT, @PercentValue DECIMAL(18,2);

		--Get markup % on fly
		SELECT @PercentId = [PercentId],@PercentValue = [PercentValue] FROM [dbo].[AiIntegrationSetting] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;

		IF(@CustomerRfqQuoteId > 0)
		BEGIN
			UPDATE [dbo].[CustomerRfqQuote] SET UpdatedBy = @CreatedBy, UpdatedDate = GETUTCDATE() WHERE CustomerRfqQuoteId = @CustomerRfqQuoteId;

			UPDATE CRQ 
			SET
				CRQ.IlsQty = TMP.IlsQty,
				CRQ.IlsTraceability = TMP.IlsTraceability,
				CRQ.IlsUom = TMP.IlsUom,
				CRQ.IlsPrice = TMP.IlsPrice,
				CRQ.IlsPriceType = TMP.IlsPriceType,
				CRQ.IlsTagDate = TMP.IlsTagDate,
				CRQ.IlsLeadTime = TMP.IlsLeadTime,
				CRQ.IlsMinQty = TMP.IlsMinQty,
				CRQ.IlsComment = TMP.IlsComment,
				CRQ.IlsCondition = TMP.IlsCondition,
				CRQ.UpdatedBy = @CreatedBy,
				CRQ.UpdatedDate = GETUTCDATE()
			FROM dbo.CustomerRfqQuoteDetails CRQ
			INNER JOIN @tbl_EmailRfqQuoteDetailsType TMP ON CRQ.CustomerRfqQuoteDetailsId = TMP.CustomerRfqQuoteDetailsId
		END
		ELSE
		BEGIN
			--------------------------- Insert into Rfq Quote table --------------------------------------------------
			INSERT INTO [dbo].[CustomerRfqQuote]
			(	[CustomerRfqId], [RfqId], [AddComment], [IsAddCommentQuote], [FaaEasaRelease], [IsFaaEasaReleaseQuote],
				[RpOh], [IsRpOhQuote], [LegalEntityId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES	(@CustomerRfqId, @RfqId, '', 0, '', 0,
					'', 0, @LegalEntityId, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1,0);

			SELECT @CustomerRfqQuoteId = SCOPE_IDENTITY();	
		
			------------------- Customer RFQ Quote Details add ---------------------------------------------------------

			INSERT INTO [dbo].[CustomerRfqQuoteDetails]
			(	[CustomerRfqQuoteId], [ServiceType], IlsQty, IlsTraceability, IlsUom, IlsPrice,
				IlsPriceType, IlsTagDate, IlsLeadTime, IlsMinQty, IlsComment, IlsCondition, ConditionId, [CustomerRfqPartMappingId],	
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [PercentId], [PercentValue])
			SELECT	@CustomerRfqQuoteId, 0, IlsQty, IlsTraceability, IlsUom, IlsPrice,
					IlsPriceType, IlsTagDate, IlsLeadTime, IlsMinQty, IlsComment, IlsCondition, ConditionId, [CustomerRfqPartMappingId],	
					@CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @PercentId, @PercentValue
			FROM @tbl_EmailRfqQuoteDetailsType;

			------- Update Csutomer RFQ for Is Quote added ----------					 
			UPDATE [dbo].[CustomerRfq] 
			SET IsQuote = 1
			WHERE CustomerRfqId = @CustomerRfqId;
		END
	END			
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_SaveEmailQuote' 
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