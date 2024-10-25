/*************************************************************           
 ** File:   [SearchCustomerPayments]           
 ** Author:   Unknown
 ** Description: This stored procedure is used to retrieve Customer Payments Information   
 ** Purpose:         
 ** Date:   12/23/2020        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/23/2022   Unknown			Created
	2    03/06/2024   Moin Bloch		Modified Added PostedDate
	3    24/10/2024   Devendra Shekh	Modified (added if/else for details and receipt view)
**************************************************************/  
CREATE   PROCEDURE [dbo].[SearchCustomerPayments]
    @PageNumber INT,
    @PageSize INT,
    @SortColumn VARCHAR(50) = NULL,
    @SortOrder INT,
    @StatusID INT,
    @GlobalFilter VARCHAR(50) = NULL,
    @ReceiptNo VARCHAR(50) = NULL,
    @Status VARCHAR(50) = NULL,
    @BankAcct VARCHAR(50) = NULL,
    @OpenDate DATETIME = NULL,
    @DepositDate DATETIME = NULL,
    @PostedDate DATETIME = NULL,
    @AcctingPeriod VARCHAR(50) = NULL,
    @Reference VARCHAR(50) = NULL,
    @Amount VARCHAR(50) = NULL,
    @AmtApplied VARCHAR(50) = NULL,
    @AmtRemaining VARCHAR(50) = NULL,
    @Currency VARCHAR(50) = NULL,
    @CntrlNum VARCHAR(50) = NULL,
    @LastMSLevel VARCHAR(50) = NULL,
    @MasterCompanyId INT = NULL,
    @EmployeeId BIGINT,
	@ViewType INT = NULL,
    @BackAcctNumber VARCHAR(50) = NULL,
    @CustomerName VARCHAR(100) = NULL,
    @CustomerCode VARCHAR(100) = NULL,
    @ReceiptAmount VARCHAR(50) = NULL,
    @ReceiptAmtApplied VARCHAR(50) = NULL,
    @ReceiptAmtRemaining VARCHAR(50) = NULL,
    @CreditMemoAmount VARCHAR(50) = NULL,
    @PaymentType VARCHAR(100) = NULL,
	@CheckDate DATETIME = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @RecordFrom INT;
        DECLARE @MSModuleID INT = 59; -- CustomerPayment Management Structure Module ID
        SET @RecordFrom = (@PageNumber - 1) * @PageSize;

		IF OBJECT_ID('tempdb..#CustomerPaymentDetailsTmp') IS NOT NULL
			DROP TABLE #CustomerPaymentDetailsTmp

		IF OBJECT_ID('tempdb..#CreditMemoTmp') IS NOT NULL
			DROP TABLE #CreditMemoTmp

		CREATE TABLE #CustomerPaymentDetailsTmp
		(
			 [Id] [bigint] IDENTITY(1,1) NOT NULL,
			 [ReceiptId] [bigint] NULL,
			 [CustomerPaymentDetailsId] [bigint] NULL,
			 [PaymentType] [varchar](100) NULL,
			 [CustomerId] [bigint] NULL,
			 [CustomerName] [varchar](100) NULL,
			 [CustomerCode] [varchar](100) NULL,
			 [Amount] [decimal](18,2) NULL,
			 [AmtApplied] [decimal](18,2) NULL,
			 [AmtRemaining] [decimal](18,2) NULL,
			 [CheckDate] [datetime2] NULL,
			 [Reference] [varchar](100) NULL,
		)

		CREATE TABLE #CreditMemoTmp
		(
			 [Id] [bigint] IDENTITY(1,1) NOT NULL,
			 [ReceiptId] [bigint] NULL,
			 [CustomerPaymentDetailsId] [bigint] NULL,
			 [CreditMemoAmount] [decimal](18,2) NULL
		)

        IF @StatusID = 0
        BEGIN
            SET @StatusID = NULL;
            SET @Status = NULL;
        END
        ELSE IF @StatusID = 1
        BEGIN
            SET @Status = 'Open';
        END
        ELSE IF @StatusID = 2
        BEGIN
            SET @Status = 'Posted';
        END

        -- Set sort column
        IF @SortColumn IS NULL
        BEGIN
            SET @SortColumn = UPPER('ReceiptID');
        END
        ELSE
        BEGIN
            SET @SortColumn = UPPER(@SortColumn);
        END

		IF(ISNULL(@ViewType, 1) = 1)
		BEGIN
			;WITH Result AS (
				SELECT DISTINCT
					CP.ReceiptID,
					CP.ReceiptNo AS 'ReceiptNo',
					S.Name AS 'Status',
					LEB.BankAccountNumber AS 'BankAccountNumber',
					LEB.BankName AS 'BankAcct',
					CP.OpenDate,
					CP.DepositDate,
					AP.PeriodName AS 'AcctingPeriod',
					CP.Reference,
					CP.Amount,
					CP.AmtApplied,
					CP.AmtRemaining,
					CP.CntrlNum,
					MSD.LastMSLevel,
					MSD.AllMSlevels,
					CP.CreatedDate,
					CASE 
						WHEN ISNULL(ic.CurrencyId, 0) > 0 THEN ic.CurrencyId
						WHEN ISNULL(iw.CurrencyId, 0) > 0 THEN iw.CurrencyId
						WHEN ISNULL(icd.CurrencyId, 0) > 0 THEN icd.CurrencyId
						ELSE 0 
					END AS 'CurrencyId',
					CP.PostedDate
				FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
				INNER JOIN [dbo].[CustomerManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = CP.ReceiptId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH(NOLOCK) ON CP.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN [dbo].[EmployeeUserRole] EUR WITH(NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				LEFT JOIN [dbo].[LegalEntityBankingLockBox] LEB WITH(NOLOCK) ON LEB.LegalEntityBankingLockBoxId = CP.BankName
				LEFT JOIN [dbo].[MasterCustomerPaymentStatus] S WITH(NOLOCK) ON S.Id = CP.StatusId
				LEFT JOIN [dbo].[AccountingCalendar] AP WITH(NOLOCK) ON AP.AccountingCalendarId = CP.AcctingPeriod
				LEFT JOIN (
					SELECT ReceiptId, MAX(CurrencyId) AS 'CurrencyId' 
					FROM [dbo].[InvoiceCheckPayment] iv WITH(NOLOCK)   
					GROUP BY ReceiptId  
				) ic ON CP.ReceiptId = ic.ReceiptId
				LEFT JOIN (
					SELECT ReceiptId, MAX(CurrencyId) AS 'CurrencyId' 
					FROM [dbo].[InvoiceWireTransferPayment] iv WITH(NOLOCK)   
					GROUP BY ReceiptId  
				) iw ON CP.ReceiptId = iw.ReceiptId
				LEFT JOIN (
					SELECT ReceiptId, MAX(CurrencyId) AS 'CurrencyId' 
					FROM [dbo].[InvoiceCreditDebitCardPayment] iv WITH(NOLOCK)  
					GROUP BY ReceiptId  
				) icd ON CP.ReceiptId = icd.ReceiptId  
			),
			FinalResult AS (
				SELECT C.Code AS 'Currency', R.* 
				FROM Result R  
				LEFT JOIN [dbo].[Currency] C WITH(NOLOCK) ON R.CurrencyId = C.CurrencyId  
				WHERE (
					(@GlobalFilter <> '' AND (
						(ReceiptNo LIKE '%' + @GlobalFilter + '%') OR    
						(Status LIKE '%' + @GlobalFilter + '%') OR    
						(BankAcct LIKE '%' + @GlobalFilter + '%') OR    
						(AcctingPeriod LIKE '%' + @GlobalFilter + '%') OR    
						(Reference LIKE '%' + @GlobalFilter + '%') OR    
						(C.Code LIKE '%' + @GlobalFilter + '%') OR    
						(CntrlNum LIKE '%' + @GlobalFilter + '%') OR    
						(LastMSLevel LIKE '%' + @GlobalFilter + '%') OR    
						(BankAccountNumber LIKE '%' + @GlobalFilter + '%') OR  
						(CAST(Amount AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%') OR
						(CAST(AmtApplied AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%') OR 
						(CAST(AmtRemaining AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%')  
					))    
					OR       
					(@GlobalFilter = '' AND (
						(ISNULL(@ReceiptNo, '') = '' OR ReceiptNo LIKE '%' + @ReceiptNo + '%') AND     
						(ISNULL(@Status, '') = '' OR Status LIKE '%' + @Status + '%') AND    
						(ISNULL(@BankAcct, '') = '' OR BankAcct LIKE '%' + @BankAcct + '%') AND    
						(@OpenDate IS NULL OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE)) AND    
						(@DepositDate IS NULL OR CAST(DepositDate AS DATE) = CAST(@DepositDate AS DATE)) AND  
						(@PostedDate IS NULL OR CAST(PostedDate AS DATE) = CAST(@PostedDate AS DATE)) AND    
						(ISNULL(@AcctingPeriod, '') = '' OR AcctingPeriod LIKE '%' + @AcctingPeriod + '%') AND    
						(ISNULL(@Reference, '') = '' OR Reference LIKE '%' + @Reference + '%') AND    
						(ISNULL(@Amount, '') = '' OR CAST(Amount AS VARCHAR(50)) LIKE '%' + @Amount + '%') AND    
						(ISNULL(@AmtApplied, '') = '' OR CAST(AmtApplied AS VARCHAR(50)) LIKE '%' + @AmtApplied + '%') AND    
						(ISNULL(@AmtRemaining, '') = '' OR CAST(AmtRemaining AS VARCHAR(50)) LIKE '%' + @AmtRemaining + '%') AND    
						(ISNULL(@Currency, '') = '' OR C.Code LIKE '%' + @Currency + '%') AND  
						(ISNULL(@CntrlNum, '') = '' OR CntrlNum LIKE '%' + @CntrlNum + '%') AND    
						(ISNULL(@LastMSLevel, '') = '' OR LastMSLevel LIKE '%' + @LastMSLevel + '%') AND     
						(ISNULL(@BackAcctNumber, '') = '' OR BankAccountNumber LIKE '%' + @BackAcctNumber + '%')
					))
				)
			),
			ResultCount AS (
				SELECT COUNT(ReceiptID) AS NumberOfItems FROM FinalResult
			)

			SELECT * 
			FROM FinalResult, ResultCount    
			ORDER BY    
				CASE WHEN (@SortOrder=1 and @SortColumn='RECEIPTID') THEN ReceiptId END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='RECEIPTNO') THEN ReceiptNo END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='STATUS') THEN Status END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='BANKACCT') THEN BankAcct END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE') THEN OpenDate END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='DEPOSITDATE') THEN DepositDate END ASC,  
				CASE WHEN (@SortOrder=1 and @SortColumn='POSTEDDATE') THEN PostedDate END ASC,   
				CASE WHEN (@SortOrder=1 and @SortColumn='ACCTINGPERIOD') THEN AcctingPeriod END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='REFERENCE') THEN Reference END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='AMOUNT') THEN CAST(Amount AS varchar(50)) END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='AMTAPPLIED') THEN CAST(AmtApplied  AS varchar(50)) END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='AMTREMAINING') THEN CAST(AmtRemaining  AS varchar(50)) END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='CURRENCY') THEN Currency END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='CNTRLNUM') THEN CntrlNum END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='BANKACCOUNTNUMBER')  THEN BankAccountNumber END ASC,    

				CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIPTID') THEN ReceiptId END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIPTNO')  THEN ReceiptNo END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='BANKACCT')  THEN BankAcct END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='DEPOSITDATE')  THEN DepositDate END DESC, 
				CASE WHEN (@SortOrder=-1 and @SortColumn='POSTEDDATE') THEN PostedDate END DESC, 
				CASE WHEN (@SortOrder=-1 and @SortColumn='ACCTINGPERIOD')  THEN AcctingPeriod END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='REFERENCE')  THEN Reference END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='AMOUNT')  THEN CAST(Amount AS varchar(50)) END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='AMTAPPLIED')  THEN CAST(AmtApplied  AS varchar(50)) END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='AMTREMAINING')  THEN CAST(AmtRemaining  AS varchar(50)) END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='CURRENCY')  THEN Currency END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='CNTRLNUM')  THEN CntrlNum END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='BANKACCOUNTNUMBER')  THEN BankAccountNumber END DESC   
			OFFSET @RecordFrom ROWS FETCH NEXT @PageSize ROWS ONLY;

		END
		ELSE
		BEGIN
			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Check', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(ICP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), ICP.CheckDate, isnull(ICP.CheckNumber, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceCheckPayment] ICP WITH(NOLOCK) ON ICP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsCheckPayment, 0) = 1 AND ISNULL(CPD.IsMultiplePaymentMethod, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICP.CheckDate, ICP.CheckNumber, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Check', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(ICP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), ICP.CheckDate, isnull(ICP.CheckNumber, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceCheckPayment] ICP WITH(NOLOCK) ON ICP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsMultiplePaymentMethod, 0) = 1 AND ISNULL(CPD.IsDeleted, 0) = 0
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICP.CheckDate, ICP.CheckNumber, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Wire Transfer', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(IWP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), IWP.WireDate, isnull(IWP.ReferenceNo, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH(NOLOCK) ON IWP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsWireTransfer, 0) = 1 AND ISNULL(CPD.IsMultiplePaymentMethod, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, IWP.WireDate, IWP.ReferenceNo, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Wire Transfer', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(IWP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), IWP.WireDate, isnull(IWP.ReferenceNo, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH(NOLOCK) ON IWP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsMultiplePaymentMethod, 0) = 1 AND ISNULL(CPD.IsDeleted, 0) = 0
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, IWP.WireDate, IWP.ReferenceNo, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Credit Card/Debit Card', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(ICDP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), ICDP.PaymentDate, isnull(ICDP.Reference, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceCreditDebitCardPayment] ICDP WITH(NOLOCK) ON ICDP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsCCDCPayment, 0) = 1 AND ISNULL(CPD.IsMultiplePaymentMethod, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICDP.PaymentDate, ICDP.Reference, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Credit Card/Debit Card', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(ICDP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), ICDP.PaymentDate, isnull(ICDP.Reference, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceCreditDebitCardPayment] ICDP WITH(NOLOCK) ON ICDP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsMultiplePaymentMethod, 0) = 1 AND ISNULL(CPD.IsDeleted, 0) = 0
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICDP.PaymentDate, ICDP.Reference, CPD.CustomerPaymentDetailsId

			INSERT INTO #CreditMemoTmp([ReceiptId], [CreditMemoAmount], [CustomerPaymentDetailsId])
			SELECT CP.ReceiptId, SUM(ABS(ISNULL(IVP.OriginalAmount, 0))),CPD.CustomerPaymentDetailsId
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			LEFT JOIN [dbo].[InvoicePayments] IVP WITH(NOLOCK) ON IVP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			WHERE IVP.InvoiceType IN (3, 4, 5, 7) AND ISNULL(CPD.IsDeleted, 0) = 0
			GROUP BY CP.ReceiptId, CPD.CustomerPaymentDetailsId

			;WITH Result AS (
				SELECT DISTINCT
					CP.ReceiptID,
					CP.ReceiptNo AS 'ReceiptNo',
					LEB.BankName AS 'BankAcct',
					CP.OpenDate,
					CP.Amount AS 'ReceiptAmount',
					CP.AmtApplied AS 'ReceiptAmtApplied',
					CP.AmtRemaining AS 'ReceiptAmtRemaining',
					CP.CntrlNum,
					MSD.LastMSLevel,
					MSD.AllMSlevels,
					CP.CreatedDate,
					tmpVal.PaymentType,
					tmpVal.Amount,
					tmpVal.AmtApplied,
					tmpVal.AmtRemaining,
					tmpVal.CheckDate,
					tmpVal.Reference,
					tmpVal.CustomerName,
					tmpVal.CustomerCode,
					CASE 
						WHEN tmpCM.CreditMemoAmount < 0 THEN '(' + CAST(ABS(tmpCM.CreditMemoAmount) AS VARCHAR) + ')' 
						WHEN tmpCM.CreditMemoAmount > 0 THEN CAST(tmpCM.CreditMemoAmount AS VARCHAR)
						ELSE '0' END AS 'CreditMemoAmount',
					S.Name AS 'Status',
					CASE 
						WHEN ISNULL(ic.CurrencyId, 0) > 0 THEN ic.CurrencyId
						WHEN ISNULL(iw.CurrencyId, 0) > 0 THEN iw.CurrencyId
						WHEN ISNULL(icd.CurrencyId, 0) > 0 THEN icd.CurrencyId
						ELSE 0 
					END AS 'CurrencyId'
				FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
				LEFT JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId AND ISNULL(CPD.IsDeleted, 0) = 0
				INNER JOIN [dbo].[CustomerManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = CP.ReceiptId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH(NOLOCK) ON CP.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN [dbo].[EmployeeUserRole] EUR WITH(NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				LEFT JOIN [dbo].[MasterCustomerPaymentStatus] S WITH(NOLOCK) ON S.Id = CP.StatusId
				LEFT JOIN [dbo].[LegalEntityBankingLockBox] LEB WITH(NOLOCK) ON LEB.LegalEntityBankingLockBoxId = CP.BankName
				LEFT JOIN #CustomerPaymentDetailsTmp tmpVal ON CPD.CustomerPaymentDetailsId = tmpVal.CustomerPaymentDetailsId
				LEFT JOIN #CreditMemoTmp tmpCM ON CPD.CustomerPaymentDetailsId = tmpCM.CustomerPaymentDetailsId
				LEFT JOIN (
					SELECT ReceiptId, MAX(CurrencyId) AS 'CurrencyId' 
					FROM [dbo].[InvoiceCheckPayment] iv WITH(NOLOCK)   
					GROUP BY ReceiptId  
				) ic ON CP.ReceiptId = ic.ReceiptId
				LEFT JOIN (
					SELECT ReceiptId, MAX(CurrencyId) AS 'CurrencyId' 
					FROM [dbo].[InvoiceWireTransferPayment] iv WITH(NOLOCK)   
					GROUP BY ReceiptId  
				) iw ON CP.ReceiptId = iw.ReceiptId
				LEFT JOIN (
					SELECT ReceiptId, MAX(CurrencyId) AS 'CurrencyId' 
					FROM [dbo].[InvoiceCreditDebitCardPayment] iv WITH(NOLOCK)  
					GROUP BY ReceiptId  
				) icd ON CP.ReceiptId = icd.ReceiptId  
			),
			FinalResult AS (
				SELECT C.Code AS 'Currency', R.* 
				FROM Result R  
				LEFT JOIN [dbo].[Currency] C WITH(NOLOCK) ON R.CurrencyId = C.CurrencyId  
				WHERE (
					(@GlobalFilter <> '' AND (
						(ReceiptNo LIKE '%' + @GlobalFilter + '%') OR    
						(BankAcct LIKE '%' + @GlobalFilter + '%') OR    
						(Reference LIKE '%' + @GlobalFilter + '%') OR    
						(C.Code LIKE '%' + @GlobalFilter + '%') OR    
						(CntrlNum LIKE '%' + @GlobalFilter + '%') OR    
						(LastMSLevel LIKE '%' + @GlobalFilter + '%') OR    
						(CustomerName LIKE '%' + @GlobalFilter + '%') OR    
						(CustomerCode LIKE '%' + @GlobalFilter + '%') OR    
						(PaymentType LIKE '%' + @GlobalFilter + '%') OR    
						(CAST(ReceiptAmount AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%') OR
						(CAST(ReceiptAmtApplied AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%') OR
						(CAST(ReceiptAmtRemaining AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%') OR
						(CAST(Amount AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%') OR
						(CAST(AmtApplied AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%') OR 
						(CAST(AmtRemaining AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%') OR 
						(CAST(CreditMemoAmount AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%') 
					))    
					OR       
					(@GlobalFilter = '' AND (
						(ISNULL(@ReceiptNo, '') = '' OR ReceiptNo LIKE '%' + @ReceiptNo + '%') AND     
						(ISNULL(@BankAcct, '') = '' OR BankAcct LIKE '%' + @BankAcct + '%') AND    
						(ISNULL(@Reference, '') = '' OR Reference LIKE '%' + @Reference + '%') AND    
						(ISNULL(@Currency, '') = '' OR C.Code LIKE '%' + @Currency + '%') AND  
						(ISNULL(@CntrlNum, '') = '' OR CntrlNum LIKE '%' + @CntrlNum + '%') AND    
						(ISNULL(@LastMSLevel, '') = '' OR LastMSLevel LIKE '%' + @LastMSLevel + '%') AND     
						(ISNULL(@CustomerName, '') = '' OR CustomerName LIKE '%' + @CustomerName + '%') AND     
						(ISNULL(@CustomerCode, '') = '' OR CustomerCode LIKE '%' + @CustomerCode + '%') AND     
						(ISNULL(@PaymentType, '') = '' OR PaymentType LIKE '%' + @PaymentType + '%') AND     
						(@OpenDate IS NULL OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE)) AND    
						(@CheckDate IS NULL OR CAST(CheckDate AS DATE) = CAST(@CheckDate AS DATE)) AND  
						(ISNULL(@ReceiptAmount, '') = '' OR CAST(ReceiptAmount AS VARCHAR(50)) LIKE '%' + @ReceiptAmount + '%') AND    
						(ISNULL(@ReceiptAmtApplied, '') = '' OR CAST(ReceiptAmtApplied AS VARCHAR(50)) LIKE '%' + @ReceiptAmtApplied + '%') AND    
						(ISNULL(@ReceiptAmtRemaining, '') = '' OR CAST(ReceiptAmtRemaining AS VARCHAR(50)) LIKE '%' + @ReceiptAmtRemaining + '%') AND    
						(ISNULL(@Amount, '') = '' OR CAST(Amount AS VARCHAR(50)) LIKE '%' + @Amount + '%') AND    
						(ISNULL(@AmtApplied, '') = '' OR CAST(AmtApplied AS VARCHAR(50)) LIKE '%' + @AmtApplied + '%') AND    
						(ISNULL(@AmtRemaining, '') = '' OR CAST(AmtRemaining AS VARCHAR(50)) LIKE '%' + @AmtRemaining + '%') AND    
						(ISNULL(@CreditMemoAmount, '') = '' OR CreditMemoAmount LIKE '%' + @CreditMemoAmount + '%') AND
						(ISNULL(@Status, '') = '' OR Status LIKE '%' + @Status + '%')    
					))
				)
			),
			ResultCount AS (
				SELECT COUNT(ReceiptID) AS NumberOfItems FROM FinalResult
			)

			SELECT * 
			FROM FinalResult, ResultCount    
			ORDER BY    
				CASE WHEN (@SortOrder=1 and @SortColumn='RECEIPTID') THEN ReceiptId END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='RECEIPTNO') THEN ReceiptNo END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='BANKACCT') THEN BankAcct END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE') THEN OpenDate END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='RECEIPTAMOUNT') THEN ReceiptAmount END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='RECEIPTAMTAPPLIED') THEN ReceiptAmtApplied END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='RECEIPTAMTREMAINING') THEN ReceiptAmtRemaining END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='CNTRLNUM') THEN CntrlNum END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='PAYMENTTYPE')  THEN PaymentType END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='AMOUNT') THEN CAST(Amount AS VARCHAR(50)) END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='AMTAPPLIED') THEN CAST(AmtApplied AS VARCHAR(50)) END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='AMTREMAINING') THEN CAST(AmtRemaining AS VARCHAR(50)) END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='CHECKDATE') THEN CheckDate END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='REFERENCE') THEN Reference END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME') THEN CustomerName END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='CustomerCode') THEN CustomerCode END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='CREDITMEMOAMOUNT') THEN CAST(CreditMemoAmount AS VARCHAR(50)) END ASC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='CURRENCY') THEN Currency END ASC,    

				CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIPTID') THEN ReceiptId END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIPTNO') THEN ReceiptNo END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='BANKACCT') THEN BankAcct END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE') THEN OpenDate END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIPTAMOUNT') THEN ReceiptAmount END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIPTAMTAPPLIED') THEN ReceiptAmtApplied END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIPTAMTREMAINING') THEN ReceiptAmtRemaining END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='CNTRLNUM') THEN CntrlNum END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='PAYMENTTYPE')  THEN PaymentType END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='AMOUNT') THEN CAST(Amount AS VARCHAR(50)) END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='AMTAPPLIED') THEN CAST(AmtApplied AS VARCHAR(50)) END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='AMTREMAINING') THEN CAST(AmtRemaining AS VARCHAR(50)) END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='CHECKDATE') THEN CheckDate END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='REFERENCE') THEN Reference END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME') THEN CustomerName END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerCode') THEN CustomerCode END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='CREDITMEMOAMOUNT') THEN CAST(CreditMemoAmount AS VARCHAR(50)) END DESC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='CURRENCY') THEN Currency END DESC 
			OFFSET @RecordFrom ROWS FETCH NEXT @PageSize ROWS ONLY;

		END

	END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()     
    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
        , @AdhocComments VARCHAR(150) = 'SearchCustomerPayments'     
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceiptNo, '') + ''',    
            @Parameter2 = ' + ISNULL(CAST(@Reference AS VARCHAR(10)) ,'') +''    
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