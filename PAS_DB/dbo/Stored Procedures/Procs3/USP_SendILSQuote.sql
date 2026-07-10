
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_SendILSQuote   (source: PAS_DB/dbo/Stored Procedures/Procs3/USP_SendILSQuote.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [USP_SendILSQuote]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used Send ILS QUOTE Into Our Database
 ** Purpose:         
 ** Date:   06 Mar 2024      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author			 Change Description            
 ** --   --------      -------			 --------------------------------          
    1    06 Mar 2024   Rajesh Gami		 Created
	2    04 Aug 2025   Amit Ghediya		 Update for add PercentId,PercentValue on fly.
	3    06 Aug 2025   Amit Ghediya		 Update for add SOQ & part auto.
	4	 07 Aug 2025   Devendra Shekh	 changed [RfqId] Type to nvarchar
	5    11-08-2025    Amit Ghediya		 Modified (Added QuotedBy,QuotedDate)
 	6    13-08-2025    Rajesh Gami		 Pass the new parameter (USP_CreateSalesOrderQuoteFromAI) @SourceBy,@MarketPlaceRef
	7    14-08-2025	   Devendra Shekh	 Pass the new parameter (USP_CreateSalesOrderQuoteFromAI) @QuoteSendReviewId  
	8	 15-Aug-2025   Bhargav Saliya	 Added [PriorityId] and [ExpirationDate] 
	9    15/08/2025    Moin Bloch        Added @SoqId OUTPUT Param
	10   18-Aug-2025   Amit Ghediya      Update RFQ SOQ Price.
	11	 21-Aug-2025   Devendra Shekh	 Checking customerId in CustomerRFQ for @CustomerId
	12	 25-Aug-2025   Devendra Shekh	 Modified (Changes for @QuoteSendReviewId)
	13	 09-Jan-2026   Amit Ghediya	     Modified (Update custoemrcontactid when manual create soq)
	14    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

-- EXEC USP_SendILSQuote
************************************************************************/
CREATE           PROCEDURE [dbo].[USP_SendILSQuote]
	@tbl_IlsRfqQuoteDetailsType IlsRfqQuoteDetailsType READONLY,
	@CustomerRfqQuoteId BIGINT = NULL,
	@CustomerRfqId BIGINT,
	@RfqId NVARCHAR(250),
	@LegalEntityId BIGINT,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
				   DECLARE @SalesOrderQuoteId BIGINT = 0;

					DECLARE @GetCustomerRfqId BIGINT, 
						    @IsRecordExist BIT =0,
							@PercentId BIGINT,
							@SourceBy Varchar(30),
							@MarketplaceRef Varchar(50),
							@QuoteSendReviewId INT = 0,
							@PercentValue DECIMAL(18,2),
							@QuoteReferenceId BIGINT = 0,
							@NewCustomerContactId BIGINT;

					DECLARE @QuoteReviewRequiredId BIGINT = 0, @Code VARCHAR(50) = 'Review Required';

					SELECT @GetCustomerRfqId = CustomerRfqId FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE RfqId = @RfqId AND MasterCompanyId = @MasterCompanyId ;

					SELECT @QuoteReviewRequiredId = QuoteSendReviewId FROM [dbo].[QuoteSendReview] WITH(NOLOCK) WHERE [Code] = @Code;
					IF EXISTS(SELECT 1 FROM @tbl_IlsRfqQuoteDetailsType WHERE ISNULL([QuoteSendReviewId], 0) = @QuoteReviewRequiredId OR ISNULL([QuoteSendReviewId], 0) = 0)
					BEGIN
						SET @QuoteSendReviewId = @QuoteReviewRequiredId;
					END
					ELSE
					BEGIN
						SET @QuoteSendReviewId = (SELECT TOP 1 [QuoteSendReviewId] FROM @tbl_IlsRfqQuoteDetailsType);
					END

					--Get markup % on fly
					SELECT @PercentId = [PercentId],@PercentValue = [PercentValue] FROM [dbo].[AiIntegrationSetting] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;

					--SET @IsRecordExist = (CASE WHEN (SELECT COUNT(1) FROM DBO.CustomerRfqQuote WITH(NOLOCK) WHERE CustomerRfqId = @GetCustomerRfqId AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0) > 0 THEN 1 ELSE 0 END)

					IF(@CustomerRfqQuoteId >0)
					BEGIN
						--SET @CustomerRfqQuoteId = (SELECT TOP 1 CustomerRfqQuoteId FROM DBO.CustomerRfqQuote WITH(NOLOCK) WHERE CustomerRfqId = @GetCustomerRfqId AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0)

						UPDATE [dbo].[CustomerRfqQuote] SET UpdatedBy = @CreatedBy, UpdatedDate = GETUTCDATE() where CustomerRfqQuoteId = @CustomerRfqQuoteId;
						
						--DELETE FROM DBO.CustomerRfqQuoteDetails WHERE CustomerRfqQuoteId in((SELECT CustomerRfqQuoteId FROM CustomerRfqQuote Q WITH(NOLOCK) WHERE CustomerRfqId = @GetCustomerRfqId AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0 AND CustomerRfqQuoteId != @CustomerRfqQuoteId))

						DELETE FROM  DBO.CustomerRfqQuoteDetails WHERE CustomerRfqQuoteDetailsId NOT IN(SELECT lq.CustomerRfqQuoteDetailsId FROM @tbl_IlsRfqQuoteDetailsType lq INNER JOIN DBO.CustomerRfqQuoteDetails cr WITH(NOLOCK) on lq.CustomerRfqQuoteDetailsId = cr.CustomerRfqQuoteDetailsId)  

						UPDATE e set
								e.IlsQty=A.IlsQty,
								e.IlsTraceability=A.IlsTraceability,
								e.IlsUom=A.IlsUom,
								e.IlsPrice=A.IlsPrice,
								e.IlsPriceType=A.IlsPriceType,
								e.IlsTagDate=A.IlsTagDate,
								e.IlsLeadTime=A.IlsLeadTime,
								e.IlsMinQty=A.IlsMinQty,
								e.IlsComment=A.IlsComment,
								e.IlsCondition=A.IlsCondition,
								e.UpdatedBy=@CreatedBy,
								e.UpdatedDate = GETUTCDATE(),
								e.PriorityId = A.PriorityId,
								e.ExpirationDate = A.ExpirationDate
								FROM dbo.CustomerRfqQuoteDetails e
								INNER JOIN @tbl_IlsRfqQuoteDetailsType a
								ON e.CustomerRfqQuoteDetailsId = A.CustomerRfqQuoteDetailsId
						
						INSERT INTO [dbo].[CustomerRfqQuoteDetails]
								   ([CustomerRfqQuoteId] ,[ServiceType] ,IlsQty ,IlsTraceability ,IlsUom ,IlsPrice ,
									IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition, ConditionId,	
									[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted], [PercentId], [PercentValue],[PriorityId],[ExpirationDate])
						SELECT @CustomerRfqQuoteId ,0 ,IlsQty ,IlsTraceability ,IlsUom ,IlsPrice ,
									IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition, ConditionId,	
							   @CreatedBy, @CreatedBy ,GETUTCDATE() ,GETUTCDATE() ,1 ,0, @PercentId, @PercentValue,[PriorityId],[ExpirationDate]
						 FROM @tbl_IlsRfqQuoteDetailsType WHERE ISNULL(CustomerRfqQuoteDetailsId,0) = 0;

						------- Update Csutomer RFQ for Is Quote added ----------					 
						 UPDATE [dbo].[CustomerRfq] 
							SET IsQuote = 1,
								QuotedBy = @CreatedBy,
								QuotedDate = GETUTCDATE(),
								QuoteSendReviewId = @QuoteSendReviewId
						 WHERE CustomerRfqId = @GetCustomerRfqId;

						------Update RFQ SOQ Data--------------------------
						EXEC [dbo].[USP_UpdateRFQQuoteDetails] @tbl_IlsRfqQuoteDetailsType,@CustomerRfqQuoteId,@CustomerRfqId,@RfqId,@MasterCompanyId,@CreatedBy
					END
					ELSE
					BEGIN
						--------------------------- Insert into Rfq Quote table --------------------------------------------------
						INSERT INTO [dbo].[CustomerRfqQuote]
											   ([CustomerRfqId] ,[RfqId] ,[AddComment] ,[IsAddCommentQuote] ,[FaaEasaRelease] ,[IsFaaEasaReleaseQuote] ,
												[RpOh] ,[IsRpOhQuote] ,[LegalEntityId] ,[MasterCompanyId] ,	
												[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
									VALUES (@GetCustomerRfqId ,@RfqId ,'' ,0 ,'' ,0 ,
										   '' ,0 ,@LegalEntityId ,@MasterCompanyId ,
										   @CreatedBy,@CreatedBy  ,GETUTCDATE(),GETUTCDATE()  ,1 ,0);

						SELECT @CustomerRfqQuoteId = SCOPE_IDENTITY();	
		
						------------------- Customer RFQ Quote Details add ---------------------------------------------------------

						INSERT INTO [dbo].[CustomerRfqQuoteDetails]
								   ([CustomerRfqQuoteId] ,[ServiceType] ,IlsQty ,IlsTraceability ,IlsUom ,IlsPrice ,
									IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition, ConditionId,	
									[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted], [PercentId], [PercentValue],[PriorityId],[ExpirationDate])
						SELECT @CustomerRfqQuoteId ,0 ,IlsQty ,IlsTraceability ,IlsUom ,IlsPrice ,
									IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition, ConditionId,	
							   @CreatedBy, @CreatedBy ,GETUTCDATE() ,GETUTCDATE() ,1 ,0, @PercentId, @PercentValue,[PriorityId],[ExpirationDate]
						 FROM @tbl_IlsRfqQuoteDetailsType;

						 ------- Update Csutomer RFQ for Is Quote added ----------					 
						 UPDATE [dbo].[CustomerRfq] 
							SET IsQuote = 1,
								QuotedBy = @CreatedBy,
								QuotedDate = GETUTCDATE(),
								QuoteSendReviewId = @QuoteSendReviewId
						 WHERE CustomerRfqId = @GetCustomerRfqId;


						 ---------Create SOQ With part---------------------------------------------
							DECLARE @ItemMasterId BIGINT = 0,
									@CustomerId BIGINT = 0,
									@RfqCustomerId BIGINT = 0,
									@PartNumber NVARCHAR(200) = NULL,
									@BuyerCompanyName NVARCHAR(200) = NULL,
									@IsAutoInternalQuote BIT;

							SELECT @PartNumber = [LinePartNumber],
								   @BuyerCompanyName = [BuyerCompanyName],
								   @SourceBy = ISNULL([Type],''),
								   @MarketplaceRef = ISNULL(RfqId,''),
								   @RfqCustomerId = [CustomerId]
							FROM [dbo].[CustomerRfq] WITH(NOLOCK) 
							WHERE [CustomerRfqId] = @GetCustomerRfqId;

							--Get Ai Percent Value from Aisetting table mastercompany wise
						    SELECT @IsAutoInternalQuote = ISNULL(SIS.IsAutoInternalQuote,0)
						    FROM [DBO].[AiIntegrationSetting]  SIS WITH(NOLOCK) 
						    WHERE SIS.[MasterCompanyId] = @MasterCompanyId;

							SELECT @ItemMasterId = [ItemMasterId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE LOWER(TRIM([PartNumber])) = LOWER(TRIM(@PartNumber)) AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 ;
							SELECT @CustomerId = [CustomerId] FROM [dbo].[Customer] WITH(NOLOCK) WHERE LOWER(TRIM([Name])) = LOWER(TRIM(@BuyerCompanyName));
							SET @CustomerId = CASE WHEN ISNULL(@RfqCustomerId, 0) > 0 THEN @RfqCustomerId ELSE @CustomerId END;

							IF(ISNULL(@ItemMasterId,0) > 0 AND  ISNULL(@CustomerId,0) > 0)
							BEGIN
								 EXEC [dbo].[USP_CreateSalesOrderQuoteFromAI] @tbl_IlsRfqQuoteDetailsType,@CustomerId,@MasterCompanyId,@CreatedBy,2,@CustomerRfqId,@ItemMasterId,0,@SourceBy,@MarketplaceRef,@QuoteSendReviewId,@SalesOrderQuoteId OUTPUT

								 --Update Latest ContactId in SOQ
								 SELECT @QuoteReferenceId = [ReferenceId],@NewCustomerContactId = [CustomerContactId] FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;
								 IF(ISNULL(@QuoteReferenceId,0) > 0)
								 BEGIN
									  UPDATE [dbo].[SalesOrderQuote] SET [CustomerContactId] = @NewCustomerContactId WHERE [SalesOrderQuoteId] = @QuoteReferenceId;
								 END
							END					
						---------END Create SOQ With part---------------------------------------------
					END

					SET @SalesOrderQuoteId = CASE WHEN @QuoteSendReviewId = @QuoteReviewRequiredId THEN 0 ELSE @SalesOrderQuoteId END;
					SELECT @SalesOrderQuoteId AS SOQID
				
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			SELECT  
    ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;  
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_SendILSQuote' 
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