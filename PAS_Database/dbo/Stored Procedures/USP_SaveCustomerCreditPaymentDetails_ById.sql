/*****************************************************************************     
** Author:  <Devendra Shekh>    
** Create date: <03/04/2024>    
** Description: <Add Customer Credit Payment Details>    
    
EXEC [USP_SaveCustomerCreditPaymentDetails_ById]   
**********************   
** Change History   
**********************     

	  (mm/dd/yyyy)
** PR   Date			Author				Change Description    
** --   --------		-------				--------------------------------  
** 1    03/04/2024		Devendra Shekh		created
   2    12/03/2024      Moin Bloch          added missing AmtApplied
   3    15/03/2024      Devendra Shekh      added CodePrefix for SuspenseAndUnapplied

	EXEC [dbo].[USP_SaveCustomerCreditPaymentDetails_ById] 132,1,'ADMIN User'
*****************************************************************************/  

CREATE   PROCEDURE [dbo].[USP_SaveCustomerCreditPaymentDetails_ById]
@ReceiptId BIGINT,
@MasterCompanyId BIGINT,
@UserName VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

				DECLARE @TotalPaymentRec BIGINT = 0,
				@PayMentStartCount BIGINT = 1,
				@CustomerId BIGINT = 0,
				@PaymentId BIGINT = 0,
				@CheckDate DATETIME2,
				@CheckNumber VARCHAR(50) = '',
				@IsCheckPayment BIT = 0,
				@IsWireTransger BIT = 0,
				@IsCCDCPayment BIT = 0;

				DECLARE @IdCodeTypeId BIGINT;
				DECLARE @CurrentNumber AS BIGINT;
				DECLARE @SuspenseAndUnsuppliedNumber AS VARCHAR(50);

				SELECT @IdCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'SuspenseAndUnapplied';

				IF OBJECT_ID('tempdb..#CustomerPayment') IS NOT NULL
					DROP TABLE #CustomerPayment

				IF OBJECT_ID('tempdb..#CustomerAmountDetails') IS NOT NULL
					DROP TABLE #CustomerAmountDetails

				CREATE TABLE #CustomerPayment
				(
					[Id] [BIGINT] NOT NULL IDENTITY,
					[ReceiptId] [BIGINT] NULL,
					[CustomerId] [BIGINT] NULL,
					[VendorId] [BIGINT] NULL,
					[CustomerName] [VARCHAR](100) NULL,
					[CustomerCode] [VARCHAR](100) NULL,
					[IsCheckPayment] [BIT] NULL,
					[IsWireTransfer] [BIT] NULL,
					[IsCCDCPayment] [BIT] NULL,
					[RemainingAmount] [DECIMAL](18,2) NULL,
					[TotalAmount] [DECIMAL](18,2) NULL,
					[PaidAmount] [DECIMAL](18,2) NULL,
					[ReferenceNumber] [VARCHAR](100) NULL,
				)

				CREATE TABLE #CustomerAmountDetails
				(
					[Id] [BIGINT] NOT NULL IDENTITY,
					[ReceiptId] [BIGINT] NULL,
					[CustomerId] [BIGINT] NULL,
					[Name] [VARCHAR](100) NULL,
					[CustomerCode] [VARCHAR](100) NULL,
					[PaymentRef] [VARCHAR](100) NULL,
					[Amount] [DECIMAL](18,2) NULL,
					[AmountRemaining] [DECIMAL](18,2) NULL,
					[AmtApplied] [DECIMAL](18,2) NULL,
				)

				INSERT INTO #CustomerPayment (ReceiptId, CustomerId, VendorId, IsCheckPayment, IsWireTransfer, IsCCDCPayment, ReferenceNumber) 
				SELECT CP.ReceiptId, CustomerId, 0, IsCheckPayment, IsWireTransfer, IsCCDCPayment, CP.ReceiptNo
				FROM dbo.CustomerPayments CP WITH(NOLOCK) 
				INNER JOIN [DBO].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CP.ReceiptId = CPD.ReceiptId
 				WHERE CP.ReceiptId = @ReceiptId;

				INSERT INTO #CustomerAmountDetails([ReceiptId],[CustomerId],[Name],[CustomerCode],[PaymentRef],[Amount],[AmountRemaining],[AmtApplied])
				EXEC [CustomerPaymentsReview] @ReceiptId;

				UPDATE CP
				SET CP.RemainingAmount = CA.AmountRemaining, CP.[TotalAmount] = CA.Amount, CP.[PaidAmount] = ISNULL(CA.Amount, 0) - ISNULL(CA.AmountRemaining, 0),
					CP.CustomerName = CA.[Name], CP.CustomerCode = CA.CustomerCode,
					CP.VendorId = VA.VendorId
				FROM #CustomerPayment CP 
				INNER JOIN #CustomerAmountDetails CA ON CA.[CustomerId] = CP.CustomerId
				LEFT JOIN [dbo].[Vendor] VA WITH(NOLOCK) ON VA.[RelatedCustomerId] = CP.CustomerId

				SELECT @TotalPaymentRec = MAX(Id) FROM #CustomerPayment;

				WHILE(@TotalPaymentRec >= @PayMentStartCount)
				BEGIN

					SELECT @CustomerId = CustomerId, @IsCheckPayment = IsCheckPayment, @IsWireTransger = IsWireTransfer, @IsCCDCPayment = IsCCDCPayment
					FROM #CustomerPayment WHERE Id = @PayMentStartCount;
				
					IF(@IsCheckPayment = 1)
					BEGIN
						SELECT TOP 1 @CheckNumber = CheckNumber, @CheckDate = CheckDate, @PaymentId = CheckPaymentId FROM [dbo].[InvoiceCheckPayment] WITH(NOLOCK) WHERE ReceiptId = @ReceiptId AND CustomerId = @CustomerId;
					END
					ELSE IF(@IsWireTransger = 1)
					BEGIN
						SELECT TOP 1 @CheckNumber = ReferenceNo, @PaymentId = WireTransferId FROM [dbo].[InvoiceWireTransferPayment] WITH(NOLOCK) WHERE ReceiptId = @ReceiptId AND CustomerId = @CustomerId;
					END
					ELSE IF(@IsCCDCPayment = 1)
					BEGIN
						SELECT TOP 1 @CheckNumber = Reference, @PaymentId = CreditDebitPaymentId FROM [dbo].[InvoiceCreditDebitCardPayment] WITH(NOLOCK) WHERE ReceiptId = @ReceiptId AND CustomerId = @CustomerId;
					END

					/*************** Prefixes ***************/		   			
					IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
					BEGIN
						DROP TABLE #tmpCodePrefixes
					END
	
					CREATE TABLE #tmpCodePrefixes
					(
							ID BIGINT NOT NULL IDENTITY, 
							CodePrefixId BIGINT NULL,
							CodeTypeId BIGINT NULL,
							CurrentNumber BIGINT NULL,
							CodePrefix VARCHAR(50) NULL,
							CodeSufix VARCHAR(50) NULL,
							StartsFrom BIGINT NULL,
					)

					INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
					SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
					FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
					WHERE CT.CodeTypeId = @IdCodeTypeId
					AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

					IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId))
					BEGIN
						SELECT @CurrentNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END 
						FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
					
						SET @SuspenseAndUnsuppliedNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
										@CurrentNumber,
										(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId),
										(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))
					END
					/*****************End Prefixes*******************/	

					INSERT INTO [CustomerCreditPaymentDetail]([CustomerId], [CustomerName], [CustomerCode], [ReceiptId], [StatusId], [PaymentId], [ReceiveDate], [ReferenceNumber], 
								[TotalAmount], [PaidAmount], [RemainingAmount], [RefundAmount], [CheckNumber], [CheckDate], [IsCheckPayment], [IsWireTransfer], [IsCCDCPayment], [IsProcessed], [Memo], [VendorId],
								[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [SuspenseUnappliedNumber])
					SELECT  CustomerId, CustomerName, CustomerCode, ReceiptId, 1, @PaymentId ,GETUTCDATE(), ReferenceNumber, 
								TotalAmount, PaidAmount, RemainingAmount, 0, @CheckNumber, @CheckDate, IsCheckPayment, IsWireTransfer, IsCCDCPayment, 0, '', [VendorId], 
								@MasterCompanyId, @UserName, GETUTCDATE(), @UserName, GETUTCDATE(), 1, 0, @SuspenseAndUnsuppliedNumber
					FROM #CustomerPayment 
					WHERE Id = @PayMentStartCount AND ISNULL(RemainingAmount, 0) > 0;

					UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNumber AS BIGINT) + 1 WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MasterCompanyId;

					SET @PayMentStartCount = @PayMentStartCount + 1;
				
				END

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveCustomerCreditPaymentDetails_ById'              
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReceiptId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END