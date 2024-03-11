
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
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06 Mar 2024  Rajesh Gami    Created
     
-- EXEC USP_SendILSQuote
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_SendILSQuote]
	@tbl_IlsRfqQuoteDetailsType IlsRfqQuoteDetailsType READONLY,
	@CustomerRfqId BIGINT,
	@RfqId BIGINT,
	@LegalEntityId BIGINT,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

					DECLARE @CustomerRfqQuoteId BIGINT, @GetCustomerRfqId BIGINT;

					SELECT @GetCustomerRfqId = CustomerRfqId FROM CustomerRfq WHERE RfqId = @RfqId AND MasterCompanyId = @MasterCompanyId ;

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
								IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition,	
								[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
					SELECT @CustomerRfqQuoteId ,0 ,IlsQty ,IlsTraceability ,IlsUom ,IlsPrice ,
								IlsPriceType ,IlsTagDate ,IlsLeadTime ,IlsMinQty ,IlsComment,IlsCondition,	
						   @CreatedBy, @CreatedBy ,GETUTCDATE() ,GETUTCDATE() ,1 ,0
					 FROM @tbl_IlsRfqQuoteDetailsType;

					 ------- Update Csutomer RFQ for Is Quote added ----------
					 
					 UPDATE [dbo].[CustomerRfq] 
						SET IsQuote = 1
					 WHERE CustomerRfqId = @GetCustomerRfqId;
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