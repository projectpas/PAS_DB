/*************************************************************   
** Author:  <SHREY CHANDEGARA>  
** Create date: <06/01/2025>  [mm/dd/yyyy]
** Description: <Get The cash receipt Search Data>  
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	20/11/2024		SHREY CHANDEGARA			Created
** 2    28/01/2025      SHREY CHANDEGARA        UPDATED due to duplicated record.
** 3    25/02/2025      SHREY CHANDEGARA        UPDATED due to PaymentMethod and PaymentReference(like if it is a checkpayment method then chek number).
** 4    07-07-2025      Moin Bloch              Changed Old To New Billing Table
**************************************************************/
CREATE   PROCEDURE [dbo].[SaveSearch_CashReceiptSaveSearchData]
	@PageNumber INT,
	@PageSize INT,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT,
	@GlobalFilter VARCHAR(50) = NULL,
	@FromInvoiceDate DATETIME = NULL,
	@ToInvoiceDate DATETIME = NULL,
	@FromChekNumber VARCHAR(150) = NULL,
	@ToChekNumber VARCHAR(150) = NULL,
	@FromReceiptDate DATETIME = NULL,
	@ToReceiptDate DATETIME = NULL,
	@FromInvoiceNum VARCHAR(150) = NULL,
	@ToInvoiceNum VARCHAR(150) = NULL,
	@FromPostDate DATETIME = NULL,
	@ToPostDate DATETIME = NULL,
	@PaymentMethodId VARCHAR(100) = NULL,
	@FromBankAccount NVARCHAR(MAX) = NULL,
	@FromCustomerId VARCHAR(100) = NULL,
	@Customer VARCHAR(200) = NULL,
	@InvoiceNum VARCHAR(150) = NULL,
	@InvoiceDate DATETIME = NULL,
	@ReferenceNum VARCHAR(150) = NULL,
	@BatchRef VARCHAR(150) = NULL,
	@OriginalAmount VARCHAR(100) = NULL,
	@AmountPaid VARCHAR(100) = NULL,
	@RemainAmount VARCHAR(100) = NULL,
	@DiscAmount VARCHAR(100) = NULL,
	@BankFees VARCHAR(100) = NULL,
	@OtherAdj VARCHAR(100) = NULL,
	@AccountPeriod VARCHAR(150) = NULL,
	@Currency VARCHAR(150) = NULL,
	@PaymentMethod VARCHAR(150) = NULL,
	@PaymentRef VARCHAR(150) = NULL,
	@PaymentDate DATETIME = NULL,
	@InvoiceType VARCHAR(150) = NULL,
	@PostDate DATETIME = NULL,
	@BankAccount VARCHAR(150) = NULL,
	@CntrlNum VARCHAR(150) = NULL,
	@IsDownload BIT = NULL,
	@strFilter VARCHAR(MAX) = NULL,
	@level1Str VARCHAR(MAX) = NULL,
	@level2Str VARCHAR(MAX) = NULL,
	@level3Str VARCHAR(MAX) = NULL,
	@level4Str VARCHAR(MAX) = NULL,
	@level5Str VARCHAR(MAX) = NULL,
	@level6Str VARCHAR(MAX) = NULL,
	@level7Str VARCHAR(MAX) = NULL,
	@level8Str VARCHAR(MAX) = NULL,
	@level9Str VARCHAR(MAX) = NULL,
	@level10Str VARCHAR(MAX) = NULL,
	@MasterCompanyId BIGINT NULL

AS              
	BEGIN              
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
		SET NOCOUNT ON;              
             
		BEGIN TRY 
			DECLARE @Total INT;
			DECLARE @RecordFrom INT; 
			DECLARE @CHEK BIT ;
			DECLARE @WIRE BIT ;
			DECLARE @CREDIT BIT ;
			DECLARE @CheckPayment INT;
			DECLARE @WirePayment INT;
			DECLARE @CreditPayment INT;
			DECLARE @FROMSOID BIGINT;
			DECLARE @TOSOID BIGINT;
			DECLARE @FROMWOID BIGINT;
			DECLARE @TOWOID BIGINT;

			DECLARE @WOModuleId INT
			SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

			DECLARE @SOModuleId INT
			SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';


			SET @RecordFrom = (@PageNumber - 1) * @PageSize;
			SET @FROMSOID = (SELECT BillingInvoicingId FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE ISNULL(IsDeleted,0) = 0 AND ISNULL(IsVersionIncrease,0) = 0 AND InvoiceNo = @FromInvoiceNum AND [ModuleId] = @SOModuleId);

			SET @TOSOID = (CASE WHEN ISNULL(@FROMSOID,0) > 0 
								THEN (SELECT BillingInvoicingId FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE ISNULL(IsDeleted,0) = 0 AND ISNULL(IsVersionIncrease,0) = 0 AND InvoiceNo = @ToInvoiceNum AND [ModuleId] = @SOModuleId)
								ELSE NULL END);

			SET @FROMWOID = (CASE WHEN ISNULL(@FROMSOID,0) > 0 AND ISNULL(@TOSOID,0) > 0 
								  THEN NULL 
								  ELSE (SELECT BillingInvoicingId FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE ISNULL(IsDeleted,0) = 0 AND ISNULL(IsVersionIncrease,0) = 0 AND InvoiceNo = @FromInvoiceNum AND [ModuleId] = @WOModuleId)
							 END);

			SET @TOWOID = (CASE WHEN ISNULL(@FROMSOID,0) > 0 AND ISNULL(@TOSOID,0) > 0  AND ISNULL(@FROMWOID,0) > 0
								  THEN NULL 
								  ELSE (SELECT BillingInvoicingId FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE ISNULL(IsDeleted,0) = 0 AND ISNULL(IsVersionIncrease,0) = 0 AND InvoiceNo = @ToInvoiceNum AND [ModuleId] = @WOModuleId)
							 END);

			SET @CHEK = CASE WHEN @PaymentMethodId = '1' THEN 1 ELSE 0 END;
			SET @WIRE = CASE WHEN @PaymentMethodId = '2' THEN 1 ELSE 0 END;
			SET @CREDIT = CASE WHEN @PaymentMethodId = '3' THEN 1 ELSE 0 END;
			SET @CheckPayment = 1; 
			SET @WirePayment = 2;
			SET @CreditPayment = 3;

			DECLARE @CashModuleID BIGINT = (SELECT ManagementStructureModuleid FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName = 'CustomerPayment'); 

				IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
				BEGIN    
					DROP TABLE #TEMPMSFilter
				END

				CREATE TABLE #TEMPMSFilter([ID] BIGINT  IDENTITY(1,1),[LevelIds] VARCHAR(MAX)); 

				INSERT INTO #TEMPMSFilter(LevelIds)	SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!');

				DECLARE   
				@level1 VARCHAR(MAX) = NULL,  
				@level2 VARCHAR(MAX) = NULL,  
				@level3 VARCHAR(MAX) = NULL,  
				@level4 VARCHAR(MAX) = NULL,  
				@Level5 VARCHAR(MAX) = NULL,  
				@Level6 VARCHAR(MAX) = NULL,  
				@Level7 VARCHAR(MAX) = NULL,  
				@Level8 VARCHAR(MAX) = NULL,  
				@Level9 VARCHAR(MAX) = NULL,  
				@Level10 VARCHAR(MAX) = NULL 

				SELECT @level1 = LevelIds FROM #TEMPMSFilter WHERE ID = 1 
				SELECT @level2 = LevelIds FROM #TEMPMSFilter WHERE ID = 2 
				SELECT @level3 = LevelIds FROM #TEMPMSFilter WHERE ID = 3 
				SELECT @level4 = LevelIds FROM #TEMPMSFilter WHERE ID = 4 
				SELECT @level5 = LevelIds FROM #TEMPMSFilter WHERE ID = 5 
				SELECT @level6 = LevelIds FROM #TEMPMSFilter WHERE ID = 6 
				SELECT @level7 = LevelIds FROM #TEMPMSFilter WHERE ID = 7 
				SELECT @level8 = LevelIds FROM #TEMPMSFilter WHERE ID = 8 
				SELECT @level9 = LevelIds FROM #TEMPMSFilter WHERE ID = 9 
				SELECT @level10 = LevelIds FROM #TEMPMSFilter WHERE ID = 10 


				BEGIN

					 IF OBJECT_ID(N'tempdb..#tmpCash') IS NOT NULL      
					 BEGIN      
					  DROP TABLE #tmpCash      
					 END 

					IF OBJECT_ID(N'tempdb..#finalResult') IS NOT NULL      
					BEGIN      
					  DROP TABLE #finalResult    
					END 

					IF OBJECT_ID('tempdb..#TempTotalAmount') IS NOT NULL
					BEGIN
						DROP TABLE #TempTotalAmount;
					END

					CREATE TABLE #tmpCash
					(
						ID BIGINT NOT NULL IDENTITY,
						ReceiptId BIGINT NOT NULL,
						Customer VARCHAR(200) NULL,
						InvoiceNum VARCHAR(150) NULL,
						InvoiceDate DATETIME NULL,
						ReferenceNum VARCHAR(150) NULL,
						BatchRef VARCHAR(150) NULL,
						OriginalAmount DECIMAL(18,2) NULL,
						AmountPaid DECIMAL(18,2) NULL,
						RemainAmount DECIMAL(18,2) NULL,
						DiscAmount DECIMAL(18,2) NULL,
						BankFees DECIMAL(18,2) NULL,
						OtherAdj DECIMAL(18,2) NULL,
						AccountPeriod VARCHAR(150) NULL,
						Currency VARCHAR(50) NULL,
						PaymentMethod VARCHAR(50) NULL,
						PaymentRef VARCHAR(150) NULL,
						PaymentDate DATETIME NULL,
						InvoiceType VARCHAR(50) NULL,
						PostDate DATETIME NULL,
						BankAccount VARCHAR(100) NULL,
						CntrlNum VARCHAR(150) NULL,
						[MastercompanyId] [int] NULL,
						[TotalOriginalAmount] VARCHAR(25) NULL,
						[TotalAmountPaid] VARCHAR(25) NULL,
						[TotalRemainAmount] VARCHAR(25) NULL,
						[TotalDiscAmount] VARCHAR(25) NULL,
						[TotalBankFees] VARCHAR(25) NULL,
						[TotalOtherAdj] VARCHAR(25) NULL,
						level1 VARCHAR(MAX)  NULL,
						level2 VARCHAR(MAX)  NULL,
						level3 VARCHAR(MAX)  NULL,
						level4 VARCHAR(MAX)  NULL,
						level5 VARCHAR(MAX)  NULL,
						level6 VARCHAR(MAX)  NULL,
						level7 VARCHAR(MAX)  NULL,
						level8 VARCHAR(MAX)  NULL,
						level9 VARCHAR(MAX)  NULL,
						level10 VARCHAR(MAX) NULL
					)

					CREATE TABLE #TempTotalAmount
					(
						[Id] [bigint] IDENTITY(1,1),
						[MastercompanyId] [int] NULL,
						[TotalOriginalAmount] [varchar](25) NULL,
						[TotalAmountPaid] [varchar](25) NULL,
						[TotalRemainAmount] [varchar](25) NULL,
						[TotalDiscAmount] [varchar](25) NULL,
						[TotalBankFees] [varchar](25) NULL,
						[TotalOtherAdj] [varchar](25) NULL
					)

					INSERT INTO #tmpCash (ReceiptId,Customer, InvoiceNum, InvoiceDate, ReferenceNum, BatchRef, OriginalAmount, AmountPaid, RemainAmount, DiscAmount, BankFees, OtherAdj,
								AccountPeriod, Currency, PaymentMethod, PaymentRef, PaymentDate, InvoiceType, PostDate, BankAccount, CntrlNum,MastercompanyId,level1, level2, level3, level4,
								level5, level6, level7, level8, level9, level10,TotalOriginalAmount,TotalAmountPaid,TotalRemainAmount,TotalDiscAmount,TotalBankFees,TotalOtherAdj
								) 

					SELECT DISTINCT
						CP.ReceiptId,
						C.Name,
						IPS.DocNum,
						IPS.InvoiceDate,
						IPS.WOSONum,
						'' BatchRef,
						SUM(ISNULL(IPS.OriginalAmount,0)),
						SUM(ISNULL(IPS.PaymentAmount,0)),
						SUM(ISNULL(IPS.NewRemainingBal,0)),
						SUM(ISNULL(IPS.DiscAmount,0)),
						SUM(ISNULL(IPS.BankFeeAmount,0)),
						SUM(ISNULL(IPS.OtherAdjustAmt,0)),
						AC.FiscalName +'-'+ CAST(AC.FiscalYear AS VARCHAR),
						IPS.CurrencyCode,
						CASE WHEN IPM.PaymentMethodId = @CheckPayment THEN 'CHECK'
							 WHEN IPM.PaymentMethodId = @WirePayment THEN 'WIRETRANSFER'
							 WHEN IPM.PaymentMethodId = @CreditPayment THEN 'CREDIT/DEBIT CARD'
							 ELSE '' END AS PaymentMethod,
							 IPM.PaymentRef,

						--(SELECT 
						--COALESCE(
						--	CASE WHEN ICP.CheckPaymentId IS NOT NULL THEN 'CHECK' END, ''
						--) + 
						--COALESCE(
						--	CASE WHEN IWP.WireTransferId IS NOT NULL THEN CASE WHEN ICP.CheckPaymentId IS NULL THEN ' WIRETRANSFER' ELSE ', WIRETRANSFER' END END, ''
						--) + 
						--COALESCE(
						--	CASE WHEN IDP.CreditDebitPaymentId IS NOT NULL THEN CASE WHEN ICP.CheckPaymentId IS NULL AND IWP.WireTransferId IS NULL THEN  'CREDIT/DEBIT CARD' ELSE ', CREDIT/DEBIT CARD' END END, ''
						--) AS PaymentMethod),
						--(SELECT 
						--COALESCE(
						--	CASE WHEN ICP.CheckPaymentId IS NOT NULL THEN ICP.CheckNumber END, ''
						--) + 
						--COALESCE(
						--	CASE WHEN IWP.WireTransferId IS NOT NULL THEN 
						--	(CASE WHEN IWP.ReferenceNo != '' AND IWP.ReferenceNo IS NOT NULL THEN 
						--	(CASE WHEN ICP.CheckNumber != '' AND ICP.CheckNumber IS NOT NULL THEN ',' + IWP.ReferenceNo ELSE IWP.ReferenceNo END) ELSE '' END) END, ''
						--) + 
						--COALESCE(
						--	CASE WHEN IDP.CreditDebitPaymentId IS NOT NULL THEN
						--	(CASE WHEN IDP.Reference != '' AND IWP.ReferenceNo IS NOT NULL THEN 
						--	(CASE WHEN ICP.CheckNumber != '' AND ICP.CheckNumber IS NOT NULL AND IWP.ReferenceNo != '' AND IWP.ReferenceNo IS NOT NULL THEN  ',' + IDP.Reference ELSE IDP.Reference END) ELSE '' END)    END, ''
						--) AS PaymentRef),
						CP.DepositDate,
						IT.Description,
						CP.PostedDate,
						LB.BankAccountNumber,
						CP.CntrlNum,
						CP.MasterCompanyId,
						UPPER(MSD.Level1Name) AS level1,  
			            UPPER(MSD.Level2Name) AS level2, 
			            UPPER(MSD.Level3Name) AS level3, 
			            UPPER(MSD.Level4Name) AS level4, 
			            UPPER(MSD.Level5Name) AS level5, 
			            UPPER(MSD.Level6Name) AS level6, 
			            UPPER(MSD.Level7Name) AS level7, 
			            UPPER(MSD.Level8Name) AS level8, 
			            UPPER(MSD.Level9Name) AS level9, 
			            UPPER(MSD.Level10Name) AS level10,
						'',
						'',
						'',
						'',
						'',
						''
					FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
						INNER JOIN [dbo].[InvoicePayments] IPS WITH(NOLOCK) ON IPS.ReceiptId = CP.ReceiptId AND IPS.IsDeleted = 0 AND IPS.IsActive = 1
						INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CP.ReceiptId = CPD.ReceiptId AND CPD.IsDeleted = 0 AND CPD.IsActive = 1 AND CPD.CustomerId = IPS.CustomerId
						INNER JOIN [dbo].[InvoicePaymentMapping] IPM WITH(NOLOCK) ON IPS.ReceiptId = IPM.ReceiptId  AND IPS.PaymentId = IPM.PaymentId
						--LEFT JOIN [dbo].[InvoiceCheckPayment] ICP WITH(NOLOCK) ON ICP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId AND ICP.ReceiptId = CPD.ReceiptId AND CPD.CustomerId = ICP.CustomerId and IPS.PageIndex = ICP.PageIndex 
						--LEFT JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH(NOLOCK) ON IWP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId  AND IWP.ReceiptId = CPD.ReceiptId AND CPD.CustomerId = IWP.CustomerId and IPS.PageIndex = IWP.PageIndex
						--LEFT JOIN [dbo].[InvoiceCreditDebitCardPayment] IDP WITH(NOLOCK) ON IDP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId AND IDP.ReceiptId = CPD.ReceiptId AND CPD.CustomerId = IDP.CustomerId and IPS.PageIndex = IDP.PageIndex
						INNER JOIN [dbo].[Customer] C WITH(NOLOCK) ON IPS.CustomerId = C.CustomerId
						INNER JOIN [dbo].[LegalEntityBankingLockBox] LB WITH(NOLOCK) ON LB.LegalEntityBankingLockBoxId = CP.BankAcctNum
						INNER JOIN [dbo].[AccountingCalendar] AC WITH(NOLOCK) ON AC.AccountingCalendarId = CP.AcctingPeriod AND AC.IsActive = 1 AND AC.IsDeleted = 0
						INNER JOIN [dbo].[InvoiceType] IT WITH(NOLOCK) ON IT.InvoiceTypeId = IPS.InvoiceType
						INNER JOIN [dbo].[CustomerManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = CP.ReceiptId AND MSD.ModuleID = @CashModuleID
						LEFT JOIN [dbo].[BillingInvoicing] SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId = IPS.SOBillingInvoicingId AND ISNULL(SOBI.IsVersionIncrease,0) = 0 AND SOBI.IsDeleted = 0 AND SOBI.[ModuleId] = @SOModuleId
						LEFT JOIN [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) ON WOBI.BillingInvoicingId = IPS.SOBillingInvoicingId AND ISNULL(WOBI.IsVersionIncrease,0) = 0 AND WOBI.IsDeleted = 0 AND WOBI.[ModuleId] = @WOModuleId
					WHERE   CAST(@FromInvoiceDate AS DATE) <= CAST(IPS.InvoiceDate AS DATE ) AND CAST(IPS.InvoiceDate AS DATE) <= CAST(@ToInvoiceDate AS DATE)
							AND (NULLIF(@FromPostDate, '') IS NULL OR CAST(CP.PostedDate AS DATE) >= CAST(@FromPostDate AS DATE))
							AND (NULLIF(@ToPostDate, '') IS NULL OR CAST(CP.PostedDate AS DATE) <= CAST(@ToPostDate AS DATE))
							AND (NULLIF(@FromReceiptDate, '') IS NULL OR CAST(CP.DepositDate AS DATE) >= CAST(@FromReceiptDate AS DATE))
							AND (NULLIF(@ToReceiptDate, '') IS NULL OR CAST(CP.DepositDate AS DATE) <= CAST(@ToReceiptDate AS DATE))
							AND CP.MasterCompanyId = @MasterCompanyId  AND ISNULL(CP.IsActive,0)  = 1 AND  ISNULL(CP.IsDeleted,0) = 0 
							AND ( (ISNULL(@FROMSOID,'') = '' AND ISNULL(@TOSOID,'') = '') OR SOBI.BillingInvoicingId BETWEEN @FROMSOID AND @TOSOID )
							AND ( (ISNULL(@FROMWOID,'') = '' AND ISNULL(@TOWOID,'') = '') OR WOBI.BillingInvoicingId BETWEEN @FROMWOID AND @TOWOID )
							AND (ISNULL(@CHEK ,'') = '' OR ISNULL(IPM.PaymentMethodId,0) = @CheckPayment) 
							AND (ISNULL(@WIRE ,'') = '' OR ISNULL(IPM.PaymentMethodId,0) = @WirePayment) 
							AND (ISNULL(@CREDIT ,'') = '' OR ISNULL(IPM.PaymentMethodId,0) = @CreditPayment)
							AND (ISNULL(@FromCustomerId , 0) = 0 OR IPS.CustomerId = @FromCustomerId) 
							AND (ISNULL(@FromBankAccount , '') = '' OR LB.BankAccountNumber = @FromBankAccount) 
							AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
							(ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
							(ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
							(ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
							(ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
							(ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
							(ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
							(ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
							(ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
							(ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
							(ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
							(ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
							(ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
							(ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
							(ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
							(ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
							(ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
							(ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
							(ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
							(ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
					GROUP BY 
						CP.ReceiptId,C.Name,IPS.DocNum,IPS.InvoiceDate,IPS.WOSONum,CP.AcctingPeriod,IPS.CurrencyCode,IPS.CustomerId,CPD.IsCheckPayment,CPD.IsWireTransfer,
						CPD.IsCCDCPayment,CPD.PaymentRef,IPS.CreatedDate,CP.MasterCompanyId,IT.Description,CP.CntrlNum,LB.BankAccountNumber,CP.PostedDate,AC.FiscalName,
						CAST(AC.FiscalYear AS VARCHAR),CP.DepositDate,MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,
						MSD.Level8Name,MSD.Level9Name,MSD.Level10Name,CPD.IsMultiplePaymentMethod,IPM.PaymentMethodId,IPM.PaymentRef

						--ICP.CheckNumber,ICP.CheckPaymentId,IWP.WireTransferId,IWP.ReferenceNo,IDP.CreditDebitPaymentId,IDP.Reference

					SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
					SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

					INSERT INTO #TempTotalAmount([MastercompanyId], [TotalOriginalAmount],[TotalAmountPaid],[TotalRemainAmount],[TotalDiscAmount],[TotalBankFees],[TotalOtherAdj])
					SELECT MastercompanyId,   
					FORMAT(SUM(OriginalAmount), 'N', 'en-us') TotalOriginalAmount,
					FORMAT(SUM(AmountPaid), 'N', 'en-us') TotalAmountPaid,
					FORMAT(SUM(RemainAmount), 'N', 'en-us') TotalRemainAmount,
					FORMAT(SUM(DiscAmount), 'N', 'en-us') TotalDiscAmount,
					FORMAT(SUM(BankFees), 'N', 'en-us') TotalBankFees,
					FORMAT(SUM(OtherAdj), 'N', 'en-us') TotalOtherAdj
					FROM #tmpCash GROUP BY MastercompanyId
					
					UPDATE #tmpCash SET BatchRef = batchRs.BatchName
					FROM
					(SELECT 
						BH.BatchName
					FROM #tmpCash tmp
					INNER JOIN [dbo].[CustomerReceiptBatchDetails] CBD WITH(NOLOCK) ON tmp.ReceiptId = CBD.ReferenceId
					INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON BD.JournalBatchDetailId = CBD.JournalBatchDetailId
					INNER JOIN [dbo].[BatchHeader] BH WITH(NOLOCK) ON BH.JournalBatchHeaderId = BD.JournalBatchHeaderId
					GROUP BY BH.BatchName
					) batchRs

					UPDATE #tmpCash SET TotalOriginalAmount = total.TotalOriginalAmount,TotalRemainAmount = total.TotalRemainAmount,TotalAmountPaid = total.TotalAmountPaid,
										TotalDiscAmount = total.TotalDiscAmount,TotalBankFees = total.TotalBankFees,TotalOtherAdj = total.TotalOtherAdj
					FROM
					(SELECT 
						TH.TotalOriginalAmount,TH.TotalRemainAmount,TH.TotalAmountPaid,TH.TotalDiscAmount,TH.TotalBankFees,TH.TotalOtherAdj
					FROM #tmpCash tmp
					INNER JOIN #TempTotalAmount TH WITH(NOLOCK) ON TH.MastercompanyId = tmp.MastercompanyId
					) total

					SELECT * INTO #finalResult
					FROM #tmpCash
					 WHERE (
							(ISNULL(@Customer,'') ='' OR [Customer]  LIKE '%' +@Customer +'%') AND
							(ISNULL(@InvoiceNum,'') ='' OR [InvoiceNum]  LIKE '%' +@InvoiceNum +'%') AND
							(ISNULL(@InvoiceDate, '') = '' OR CAST([InvoiceDate] AS DATE) =  CAST(@InvoiceDate AS DATE) ) AND 
							(ISNULL(@ReferenceNum,'') ='' OR [ReferenceNum]  LIKE '%' +@ReferenceNum +'%') AND
							(ISNULL(@BatchRef,'') ='' OR [BatchRef]  LIKE '%' +@BatchRef +'%') AND
							(ISNULL(@OriginalAmount,'') ='' OR CAST([OriginalAmount] AS VARCHAR) LIKE '%' + @OriginalAmount +'%') AND
							(ISNULL(@AmountPaid,'') ='' OR CAST([AmountPaid] AS VARCHAR) LIKE '%' +@AmountPaid +'%') AND
							(ISNULL(@RemainAmount,'') ='' OR CAST([RemainAmount] AS VARCHAR) LIKE '%' +@RemainAmount+'%') AND
							(ISNULL(@DiscAmount ,'') ='' OR CAST([DiscAmount] AS VARCHAR) LIKE '%' + @DiscAmount +'%') AND
							(ISNULL(@BankFees ,'') ='' OR CAST([BankFees] AS VARCHAR) LIKE '%' + @BankFees +'%') AND
							(ISNULL(@OtherAdj ,'') ='' OR CAST([OtherAdj] AS VARCHAR) LIKE '%' + @OtherAdj +'%') AND
							(ISNULL(@AccountPeriod,'') ='' OR [AccountPeriod]  LIKE '%' +@AccountPeriod +'%') AND
							(ISNULL(@Currency,'') ='' OR [Currency]  LIKE '%' +@Currency +'%') AND
							(ISNULL(@PaymentMethod,'') ='' OR [PaymentMethod]  LIKE '%' +@PaymentMethod +'%') AND
							(ISNULL(@PaymentRef,'') ='' OR [PaymentRef]  LIKE '%' +@PaymentRef +'%') AND
							(ISNULL(@PaymentDate, '') = '' OR CAST([PaymentDate] AS DATE) =  CAST(@PaymentDate AS DATE) ) AND
							(ISNULL(@InvoiceType,'') ='' OR [InvoiceType]  LIKE '%' +@InvoiceType +'%') AND
							(ISNULL(@PostDate, '') = '' OR CAST([PostDate] AS DATE) =  CAST(@PostDate AS DATE) ) AND
							(ISNULL(@BankAccount,'') ='' OR [BankAccount]  LIKE '%' +@BankAccount +'%') AND
							(ISNULL(@CntrlNum,'') ='' OR [CntrlNum]  LIKE '%' +@CntrlNum +'%') 
						   )

					SET @Total = (SELECT TOP 1 COUNT(1) OVER () AS TotalRecordsCount FROM #finalResult);
					select @Total as NumberOfItems, * from #finalResult
					
					ORDER BY 
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Customer') THEN [Customer] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Customer') THEN [Customer] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'InvoiceNum') THEN [InvoiceNum] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'InvoiceNum') THEN [InvoiceNum] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'InvoiceDate') THEN [InvoiceDate] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'InvoiceDate') THEN [InvoiceDate] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ReferenceNum') THEN [ReferenceNum] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ReferenceNum') THEN [ReferenceNum] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'BatchRef') THEN [BatchRef] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'BatchRef') THEN [BatchRef] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'OriginalAmount') THEN [OriginalAmount] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'OriginalAmount') THEN [OriginalAmount] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'AmountPaid') THEN [AmountPaid] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'AmountPaid') THEN [AmountPaid] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'RemainingAmt') THEN [RemainAmount] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'RemainingAmt') THEN [RemainAmount] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'DiscAmount') THEN [DiscAmount] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'DiscAmount') THEN [DiscAmount] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'BankFees') THEN [BankFees] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'BankFees') THEN [BankFees] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'OtherAdjs') THEN [OtherAdj] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'OtherAdjs') THEN [OtherAdj] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'AccountPeriod') THEN [AccountPeriod] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'AccountPeriod') THEN [AccountPeriod] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Currency') THEN [Currency] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Currency') THEN [Currency] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PaymentMethod') THEN [PaymentMethod] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PaymentMethod') THEN [PaymentMethod] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PaymentRef') THEN [PaymentRef] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PaymentRef') THEN [PaymentRef] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PaymentDate') THEN [PaymentDate] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PaymentDate') THEN [PaymentDate] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'InvoiceType') THEN [InvoiceType] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'InvoiceType') THEN [InvoiceType] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PostDate') THEN [PostDate] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PostDate') THEN [PostDate] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'BankAcct') THEN [BankAccount] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'BankAcct') THEN [BankAccount] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CntrlNum') THEN [CntrlNum] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CntrlNum') THEN [CntrlNum] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'level1') THEN [level1] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level1') THEN [level1] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'level2') THEN [level2] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level2') THEN [level2] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'level3') THEN [level3] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level3') THEN [level3] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'level4') THEN [level4] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level4') THEN [level4] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'level5') THEN [level5] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level5') THEN [level5] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'level6') THEN [level6] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level6') THEN [level6] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'level7') THEN [level7] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level7') THEN [level7] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'level8') THEN [level8] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level8') THEN [level8] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'level9') THEN [level9] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level9') THEN [level9] END DESC,
						CASE WHEN (@SortOrder = 1 AND @SortColumn = 'level10') THEN [level10] END ASC,
						CASE WHEN (@SortOrder = -1 AND @SortColumn = 'level10') THEN [level10] END DESC
						OFFSET @RecordFrom ROWS 
   						FETCH NEXT @PageSize ROWS ONLY


				END

		END TRY                  
	BEGIN CATCH      
			SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_STATE() AS ErrorState,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_PROCEDURE() AS ErrorProcedure,
			ERROR_LINE() AS ErrorLine,
			ERROR_MESSAGE() AS ErrorMessage;	
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'SaveSearch_CashReceiptSaveSearchData'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100))
			  + '@Parameter7 = ''' + CAST(ISNULL(@masterCompanyID, '') AS VARCHAR(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH       
END