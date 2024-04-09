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
   4    20/03/2024      Devendra Shekh      added added new childTable and modified insert 
   5    20/03/2024      Devendra Shekh      added [IsMiscellaneous] 
   6    04/01/2024      Devendra Shekh      added [ManagementStructureId] 
   7    04/05/2024      Devendra Shekh      able to add suspense with known customer without any invoices

	EXEC [dbo].[USP_SaveCustomerCreditPaymentDetails_ById] 195,1,'ADMIN User'
*****************************************************************************/  

CREATE   PROCEDURE [dbo].[USP_SaveCustomerCreditPaymentDetails_ById]
@ReceiptId BIGINT,
@MasterCompanyId BIGINT,
@UserName VARCHAR(50),
@ManagementStructureId BIGINT
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
				@IsWireTransfer BIT = 0,
				@IsCCDCPayment BIT = 0,
				@CustomerCreditPaymentDetailId BIGINT = 0,
				@ChildPayMentStartCount BIGINT = 1,
				@TotalChildPaymentRec BIGINT = 0;

				DECLARE @ModuleID INT = 0;
				SET @ModuleID = (SELECT [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH (NOLOCK) WHERE [ModuleName] = 'SuspenseAndUnAppliedPayment')

				DECLARE @IdCodeTypeId BIGINT;
				DECLARE @CurrentNumber AS BIGINT;
				DECLARE @SuspenseAndUnsuppliedNumber AS VARCHAR(50);

				SELECT @IdCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'SuspenseAndUnapplied';

				IF OBJECT_ID('tempdb..#CustomerPayment') IS NOT NULL
					DROP TABLE #CustomerPayment

				IF OBJECT_ID('tempdb..#CustomerAmountDetails') IS NOT NULL
					DROP TABLE #CustomerAmountDetails

				IF OBJECT_ID('tempdb..#CustomerPaymentChild') IS NOT NULL
					DROP TABLE #CustomerPaymentChild

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
					[PaymentRef] [VARCHAR](100) NULL,
					[IsMiscellaneous] [BIT] NULL,
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

				CREATE TABLE #CustomerPaymentChild
				(
					[ChildId] [BIGINT] NOT NULL IDENTITY,
					[CustomerCreditPaymentDetailId][BIGINT] NULL,
					[CustomerId] [BIGINT] NULL,
					[PaymentId] [BIGINT] NULL,
					[IsCheckPayment] [BIT] NULL,
					[IsWireTransfer] [BIT] NULL,
					[IsCCDCPayment] [BIT] NULL,
					[ChildRemainingAmount] [DECIMAL](18,2) NULL,
					[ChildTotalAmount] [DECIMAL](18,2) NULL,
					[ChildPaidAmount] [DECIMAL](18,2) NULL,
					[CheckNumber] [VARCHAR](50) NULL,
					[CheckDate] [DATETIME2] NULL,
				)

				INSERT INTO #CustomerPayment (ReceiptId, CustomerId, VendorId, ReferenceNumber, IsMiscellaneous) 
				SELECT CP.ReceiptId, CustomerId, 0, CP.ReceiptNo, CPD.Ismiscellaneous
				FROM dbo.CustomerPayments CP WITH(NOLOCK) 
				INNER JOIN [DBO].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CP.ReceiptId = CPD.ReceiptId
 				WHERE CP.ReceiptId = @ReceiptId
				GROUP BY CP.ReceiptId, CustomerId, CP.ReceiptNo,CPD.Ismiscellaneous;

				INSERT INTO #CustomerAmountDetails([ReceiptId],[CustomerId],[Name],[CustomerCode],[PaymentRef],[Amount],[AmountRemaining],[AmtApplied])
				EXEC [CustomerPaymentsReview] @ReceiptId;

				UPDATE CP
				SET CP.RemainingAmount = CASE WHEN CP.IsMiscellaneous = 1 THEN CA.Amount ELSE CASE WHEN InvoiceData.TotalInvoies > 0 THEN CA.AmountRemaining ELSE CA.Amount END END,
					CP.[TotalAmount] = CA.Amount,
					CP.[PaidAmount] = CASE WHEN CP.IsMiscellaneous = 1 THEN 0 ELSE CASE WHEN InvoiceData.TotalInvoies > 0 THEN ISNULL(CA.Amount, 0) - ISNULL(CA.AmountRemaining, 0) ELSE 0 END END,
					CP.CustomerName = CA.[Name], CP.CustomerCode = CA.CustomerCode, CP.[PaymentRef] = CA.[PaymentRef],
					CP.VendorId = VA.VendorId
				FROM #CustomerPayment CP 
				INNER JOIN #CustomerAmountDetails CA ON CA.[CustomerId] = CP.CustomerId
				LEFT JOIN [dbo].[Vendor] VA WITH(NOLOCK) ON VA.[RelatedCustomerId] = CP.CustomerId
				OUTER APPLY (
					SELECT COUNT(PaymentId) AS TotalInvoies FROM [dbo].[InvoicePayments] INV WITH(NOLOCK) WHERE INV.ReceiptId = CP.ReceiptId AND INV.CustomerId = CP.CustomerId
				) AS InvoiceData


				SELECT @TotalPaymentRec = MAX(Id) FROM #CustomerPayment;

				WHILE(@TotalPaymentRec >= @PayMentStartCount)
				BEGIN

					SELECT @CustomerId = CustomerId--, @IsCheckPayment = IsCheckPayment, @IsWireTransger = IsWireTransfer, @IsCCDCPayment = IsCCDCPayment
					FROM #CustomerPayment WHERE Id = @PayMentStartCount;
				
					--IF(@IsCheckPayment = 1)
					--BEGIN
					--	SELECT TOP 1 @CheckNumber = CheckNumber, @CheckDate = CheckDate, @PaymentId = CheckPaymentId FROM [dbo].[InvoiceCheckPayment] WITH(NOLOCK) WHERE ReceiptId = @ReceiptId AND CustomerId = @CustomerId;
					--END
					--ELSE IF(@IsWireTransger = 1)
					--BEGIN
					--	SELECT TOP 1 @CheckNumber = ReferenceNo, @PaymentId = WireTransferId FROM [dbo].[InvoiceWireTransferPayment] WITH(NOLOCK) WHERE ReceiptId = @ReceiptId AND CustomerId = @CustomerId;
					--END
					--ELSE IF(@IsCCDCPayment = 1)
					--BEGIN
					--	SELECT TOP 1 @CheckNumber = Reference, @PaymentId = CreditDebitPaymentId FROM [dbo].[InvoiceCreditDebitCardPayment] WITH(NOLOCK) WHERE ReceiptId = @ReceiptId AND CustomerId = @CustomerId;
					--END

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
								[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [SuspenseUnappliedNumber], [IsMiscellaneous],[ManagementStructureId])
					SELECT  CustomerId, CustomerName, CustomerCode, ReceiptId, 1, NULL ,GETUTCDATE(), ReferenceNumber, 
								TotalAmount, PaidAmount, RemainingAmount, 0, [PaymentRef], NULL, NULL, NULL, NULL, 0, '', [VendorId], 
								@MasterCompanyId, @UserName, GETUTCDATE(), @UserName, GETUTCDATE(), 1, 0, @SuspenseAndUnsuppliedNumber, [IsMiscellaneous], @ManagementStructureId
					FROM #CustomerPayment 
					WHERE Id = @PayMentStartCount AND ISNULL(RemainingAmount, 0) > 0;

					SET @CustomerCreditPaymentDetailId = CASE WHEN @@ROWCOUNT > 0 THEN SCOPE_IDENTITY() ELSE 0 END;

					UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNumber AS BIGINT) + 1 WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MasterCompanyId;

					EXEC [USP_SaveSuspenseAndUnAppliedPaymenttMSDetails] @ModuleID,@CustomerCreditPaymentDetailId,@ManagementStructureId,@MasterCompanyId,@UserName

					IF(ISNULL(@CustomerCreditPaymentDetailId, 0) > 0)
					BEGIN

						INSERT INTO #CustomerPaymentChild ([CustomerCreditPaymentDetailId], [PaymentId], [IsCheckPayment], [IsWireTransfer], [IsCCDCPayment], [ChildRemainingAmount], [ChildTotalAmount], [ChildPaidAmount],
								[CheckNumber], [CheckDate]) 
						 SELECT @CustomerCreditPaymentDetailId,
							CASE WHEN ISNULL([IsCheckPayment], 0) = 1 THEN ICP.CheckPaymentId
								 WHEN ISNULL([IsWireTransfer], 0) = 1 THEN IWP.WireTransferId
								 WHEN ISNULL([IsCCDCPayment], 0) = 1 THEN ICCP.CreditDebitPaymentId
								 ELSE '' END AS 'PaymentId',
								 [IsCheckPayment], [IsWireTransfer], [IsCCDCPayment], ISNULL(CPD.AmountRem , 0), ISNULL(CPD.Amount, 0), ISNULL(CPD.AppliedAmount, 0),
								  CASE WHEN ISNULL([IsCheckPayment], 0) = 1 THEN ICP.CheckNumber
									   WHEN ISNULL([IsWireTransfer], 0) = 1 THEN IWP.ReferenceNo
									   WHEN ISNULL([IsCCDCPayment], 0) = 1 THEN ICCP.Reference
									   ELSE '' END AS 'CheckNumber',
								 CASE WHEN ISNULL([IsCheckPayment], 0) = 1 THEN ICP.CheckDate ELSE NULL END AS 'CheckDate'
						  FROM [CustomerPaymentDetails] CPD WITH (NOLOCK)  
						  LEFT JOIN [dbo].[InvoiceCheckPayment] ICP WITH (NOLOCK)  ON ICP.ReceiptId = CPD.ReceiptId AND ICP.CustomerId =  CPD.CustomerId AND CPD.CustomerPaymentDetailsId = ICP.CustomerPaymentDetailsId
						  LEFT JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH (NOLOCK) ON IWP.ReceiptId = CPD.ReceiptId AND IWP.CustomerId =  CPD.CustomerId AND CPD.CustomerPaymentDetailsId = IWP.CustomerPaymentDetailsId
						  LEFT JOIN [dbo].[InvoiceCreditDebitCardPayment] ICCP WITH (NOLOCK) ON ICCP.ReceiptId = CPD.ReceiptId AND ICCP.CustomerId =  CPD.CustomerId AND CPD.CustomerPaymentDetailsId = ICCP.CustomerPaymentDetailsId
						  WHERE CPD.ReceiptId = @ReceiptId AND CPD.CustomerId = @CustomerId

						SELECT @TotalChildPaymentRec = MAX([ChildId]) FROM #CustomerPaymentChild;

						WHILE(@TotalChildPaymentRec >= @ChildPayMentStartCount)
						BEGIN

							SELECT @IsCheckPayment = IsCheckPayment, @IsWireTransfer = IsWireTransfer, @IsCCDCPayment = IsCCDCPayment
							FROM #CustomerPaymentChild WHERE [ChildId] = @ChildPayMentStartCount;

							INSERT INTO [DBO].[CustomerCreditPaymentDetailChild]([CustomerCreditPaymentDetailId], [PaymentId], [Amount], [PaidAmount], [RemainingAmount], [RefundAmount], [CheckNumber], [CheckDate],
											  [IsCheckPayment], [IsWireTransfer], [IsCCDCPayment], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
							SELECT	[CustomerCreditPaymentDetailId], PaymentId, [ChildTotalAmount], [ChildPaidAmount], [ChildRemainingAmount], 0, CheckNumber, CheckDate, 
									[IsCheckPayment], [IsWireTransfer], [IsCCDCPayment], @MasterCompanyId, @UserName, GETUTCDATE(), @UserName, GETUTCDATE(), 1, 0
							FROM #CustomerPaymentChild 
							WHERE [ChildId] = @ChildPayMentStartCount;

							SET @ChildPayMentStartCount = @ChildPayMentStartCount + 1;

						END

						TRUNCATE TABLE #CustomerPaymentChild;
						SET @ChildPayMentStartCount = 1;

					END

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