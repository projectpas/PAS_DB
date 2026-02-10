/*************************************************************           
 ** File:   [usprpt_CashReceiptReportList_SSRS]           
 ** Author:   RAJESH GAMI  
 ** Description: Get Data for Cash receipt report data fro the SSRS
 ** Purpose:         
 ** Date:   29 JAN 2026       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  			Change Description            
 ** --   --------		-------				--------------------------------          
	1	 29 JAN 2026		RAJESH GAMI  		CREATED
	2	 04 FEB 2026		RAJESH GAMI  		Resolved Issue
	3	 06 FEB 2026		RAJESH GAMI  		Record Mismatch issue
**************************************************************/
CREATE          PROCEDURE [dbo].[usprpt_CashReceiptReportList_SSRS]
@id VARCHAR(MAX) = NULL,
@id2 VARCHAR(MAX) = NULL,
@id3 VARCHAR(MAX) = NULL,
@id4 VARCHAR(MAX) = NULL,
@strFilter VARCHAR(MAX) = NULL,
@mastercompanyid INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
   	
  BEGIN TRY
		IF OBJECT_ID(N'tempdb..#TempDataFilter') IS NOT NULL    
		BEGIN    
			DROP TABLE #TempDataFilter
		END

		CREATE TABLE #TempDataFilter([ID] BIGINT  IDENTITY(1,1),[Field] VARCHAR(MAX));

		INSERT INTO #TempDataFilter(Field) SELECT Item FROM DBO.SPLITSTRING(@id2,'!');

		DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT;
		DECLARE @PageNumber INT = 1,
				@PageSize INT = 1000000,
				@SortColumn VARCHAR(50)=NULL,
				@SortOrder INT = NULL,
				@GlobalFilter varchar(50) = '',
				@ViewType varchar(50) = @id,
				@FromDate DATETIME2 = NULL,
				@ToDate DATETIME2 = NULL,
				@CustomerId BIGINT = NULL,
				@CustomerName VARCHAR(100) = NULL,
				@PaymentMethod VARCHAR(50) = NULL,
				@PaymentReference VARCHAR(50) = NULL,
				@PostedDate DATETIME2 = NULL,
				@BaseCurrency VARCHAR(50) = NULL,
				@BaseCurrencyAmount DECIMAL(18, 2) = NULL,
				@InvoiceNum VARCHAR(50) = NULL,
				@InvoiceDate DATETIME2 = NULL,
				@DueDate DATETIME2 = NULL,
				@BankAccount VARCHAR(50) = NULL,
				@GlAccountNum VARCHAR(50) = NULL,
				@Employee VARCHAR(50) = NULL,
				@level1Str VARCHAR(500) = NULL,
				@level2Str VARCHAR(500) = NULL,
				@level3Str VARCHAR(500) = NULL,
				@level4Str VARCHAR(500) = NULL,
				@level5Str VARCHAR(500) = NULL,
				@level6Str VARCHAR(500) = NULL,
				@level7Str VARCHAR(500) = NULL,
				@level8Str VARCHAR(500) = NULL,
				@level9Str VARCHAR(500) = NULL,
				@level10Str VARCHAR(500) = NULL,
				@LegalEntityName VARCHAR(500) = NULL,
				@EmployeeId BIGINT = NULL;

	
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
		DECLARE @SOInvoiceType INT = 1
		DECLARE @WOInvoiceType INT = 2
		DECLARE	@CREDITMEMO INT = 3
		DECLARE	@STANDALONECREDITMEMO INT = 4
		DECLARE	@MANUALJOURNAL INT = 5
		DECLARE	@ESOInvoiceType INT = 6
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

		DECLARE @RecordFrom INT,@StatusID INT =(select ID from dbo.MasterCustomerPaymentStatus WITH(NOLOCK) WHERE [Description] = 'Posted')
			 ,@Status VARCHAR(50),@IsUpdated BIT = 0;
        DECLARE @MSModuleID INT = 59; -- CustomerPayment Management Structure Module ID
        SET @RecordFrom = (@PageNumber - 1) * @PageSize;

		IF OBJECT_ID('tempdb..#CustomerPaymentDetailsTmp') IS NOT NULL
			DROP TABLE #CustomerPaymentDetailsTmp

		IF OBJECT_ID('tempdb..#CreditMemoTmp') IS NOT NULL
			DROP TABLE #CreditMemoTmp
		IF OBJECT_ID('tempdb..#invoiceTmpTable') IS NOT NULL
			DROP TABLE #invoiceTmpTable
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
		
		CREATE TABLE #invoiceTmpTable
		(
			 [Id] [bigint] IDENTITY(1,1) NOT NULL,
			 [ReceiptId] [bigint] NULL,
			 InvoiceNum VARCHAR(50) NULL,
			 [InvoiceDate] [datetime2] NULL,
			 [Amount] [decimal](18,2) NULL,
			 InvoicePaymentId [bigint] NULL,
			 [PaymentType] [varchar](100) NULL,
		)
		SELECT @FromDate = ISNULL(TRY_CAST([Field] AS DATETIME2), NULL) FROM #TempDataFilter WHERE ID = 1;

		SELECT @ToDate = ISNULL(TRY_CAST([Field] AS DATETIME2), NULL) FROM #TempDataFilter WHERE ID = 2;

		SELECT @CustomerId = ISNULL(TRY_CAST([Field] AS BIGINT), NULL)	FROM #TempDataFilter WHERE ID = 3;

		SELECT @CustomerName = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempDataFilter WHERE ID = 4;

		SELECT @PaymentMethod = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempDataFilter WHERE ID = 5;

		SELECT @PaymentReference = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempDataFilter WHERE ID = 6;

		SELECT @PostedDate = ISNULL(TRY_CAST([Field] AS DATETIME2), NULL)	FROM #TempDataFilter WHERE ID = 7;

		SELECT @BaseCurrency = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempDataFilter WHERE ID = 8;

		SELECT @BaseCurrencyAmount = ISNULL(TRY_CAST([Field] AS DECIMAL(18,2)), NULL) FROM #TempDataFilter WHERE ID = 9;

		SELECT @InvoiceNum = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END	FROM #TempDataFilter WHERE ID = 10;

		SELECT @InvoiceDate = ISNULL(TRY_CAST([Field] AS DATETIME2), NULL)	FROM #TempDataFilter WHERE ID = 11;

		SELECT @DueDate = ISNULL(TRY_CAST([Field] AS DATETIME2), NULL)	FROM #TempDataFilter WHERE ID = 12;

		SELECT @BankAccount = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END	FROM #TempDataFilter WHERE ID = 13;

		SELECT @GlAccountNum = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempDataFilter WHERE ID = 14;

		SELECT @Employee = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempDataFilter WHERE ID = 15;

		SELECT @LegalEntityName = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END	FROM #TempDataFilter WHERE ID = 16;

		SELECT @EmployeeId = ISNULL(TRY_CAST([Field] AS BIGINT), NULL)	FROM #TempDataFilter WHERE ID = 17;
		

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
		SELECT 
				@CurrntEmpTimeZoneDesc = COALESCE(
					ETZ.[Description],  -- Prefer Employee's TimeZone description if available
					LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
				)
		FROM 
			DBO.Employee E WITH (NOLOCK) 
		LEFT JOIN 
			dbo.TimeZone ETZ WITH (NOLOCK) 
			ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN 
			dbo.LegalEntity LE WITH (NOLOCK) 
			ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN 
			dbo.TimeZone LTZ WITH (NOLOCK) 
			ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE 
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

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

	
	PRINT ISNULL(@ViewType, '')
		IF(ISNULL(@ViewType, '') = 'Details')
		BEGIN
			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Check', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(ICP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), ICP.CheckDate, isnull(ICP.CheckNumber, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceCheckPayment] ICP WITH(NOLOCK) ON ICP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsCheckPayment, 0) = 1 AND ISNULL(CPD.IsMultiplePaymentMethod, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICP.CheckDate, ICP.CheckNumber, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Check', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(ICP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), ICP.CheckDate, isnull(ICP.CheckNumber, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceCheckPayment] ICP WITH(NOLOCK) ON ICP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsMultiplePaymentMethod, 0) = 1 AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0  AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICP.CheckDate, ICP.CheckNumber, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Wire Transfer', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(IWP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), IWP.WireDate, isnull(IWP.ReferenceNo, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH(NOLOCK) ON IWP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsWireTransfer, 0) = 1 AND ISNULL(CPD.IsMultiplePaymentMethod, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND Cp.MasterCompanyId =@mastercompanyid 
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, IWP.WireDate, IWP.ReferenceNo, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Wire Transfer', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(IWP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), IWP.WireDate, isnull(IWP.ReferenceNo, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH(NOLOCK) ON IWP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsMultiplePaymentMethod, 0) = 1 AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0  AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, IWP.WireDate, IWP.ReferenceNo, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Credit Card/Debit Card', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(ICDP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), ICDP.PaymentDate, isnull(ICDP.Reference, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceCreditDebitCardPayment] ICDP WITH(NOLOCK) ON ICDP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsCCDCPayment, 0) = 1 AND ISNULL(CPD.IsMultiplePaymentMethod, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0  AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICDP.PaymentDate, ICDP.Reference, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Credit Card/Debit Card', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(ICDP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), ICDP.PaymentDate, isnull(ICDP.Reference, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceCreditDebitCardPayment] ICDP WITH(NOLOCK) ON ICDP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsMultiplePaymentMethod, 0) = 1 AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICDP.PaymentDate, ICDP.Reference, CPD.CustomerPaymentDetailsId

			INSERT INTO #CreditMemoTmp([ReceiptId], [CreditMemoAmount], [CustomerPaymentDetailsId])
			SELECT CP.ReceiptId, SUM(ABS(ISNULL(IVP.OriginalAmount, 0))),CPD.CustomerPaymentDetailsId
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			LEFT JOIN [dbo].[InvoicePayments] IVP WITH(NOLOCK) ON IVP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			WHERE IVP.InvoiceType IN (3, 4, 5, 7) AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CP.ReceiptId, CPD.CustomerPaymentDetailsId

			INSERT INTO #invoiceTmpTable([ReceiptId], InvoiceNum, InvoiceDate,Amount,InvoicePaymentId,[PaymentType])
			SELECT DISTINCT
				[IP].[ReceiptId],
				 UPPER([IP].[DocNum]) AS InvoiceNum,   
				 [IP].[InvoiceDate] as InvoiceDate,  
				 --UPPER([IP].[WOSONum]) AS WOSONum,  
				 [IP].[PaymentAmount] As Amount   
				 ,Ip.PaymentId as InvoicePaymentId,
				 --CASE WHEN CPD.IsCheckPayment = 1 THEN 'Check' WHEN CPD.IsWireTransfer = 1 THEN 'Wire Transfer' WHEN CPD.IsCCDCPayment = 1 THEN 'Credit Card/Debit Card' END AS PaymentType
				 --,[IP].[Status]
				  CASE WHEN [IP].IsCheckPayment = 1 THEN 'Check' WHEN [IP].IsWireTransfer = 1 THEN 'Wire Transfer' WHEN [IP].IsCCDCPayment = 1 THEN 'Credit Card/Debit Card' END AS PaymentType
			FROM  [dbo].[InvoicePayments] [IP] WITH(NOLOCK)
				  INNER JOIN dbo.[CustomerPaymentDetails]  CPD WITH(NOLOCK) ON [IP].ReceiptId = CPD.ReceiptId AND CPD.CustomerPaymentDetailsId = [IP].CustomerPaymentDetailsId
				  INNER JOIN [dbo].[CustomerPayments] CP WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
				  --INNER JOIN [dbo].[InvoicePayments] [IP] WITH (NOLOCK)  ON  CPD.ReceiptId = [IP].ReceiptId 
				  LEFT JOIN [dbo].[BillingInvoicing] SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId = [IP].SOBillingInvoicingId AND SOBI.[ModuleId] = @SOModuleId AND [IP].[InvoiceType] = @SOInvoiceType  	 
				  LEFT JOIN [dbo].[SalesOrder] S WITH (NOLOCK) ON SOBI.ReferenceId = S.SalesOrderId      
				  LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId      
				  LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON SOBI.CustomerId = CF.CustomerId      
				  LEFT JOIN [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) ON WOBI.BillingInvoicingId = [IP].SOBillingInvoicingId AND WOBI.[ModuleId] = @WOModuleId AND [IP].[InvoiceType] = @WOInvoiceType 	 	 
				  LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON  WO.WorkOrderId = WOBI.ReferenceId  and WOBI.IsVersionIncrease = 0      
				  LEFT JOIN [dbo].[Customer] CW WITH (NOLOCK) ON WOBI.CustomerId = CW.CustomerId      
				  LEFT JOIN [dbo].[CustomerFinancial] CFW WITH (NOLOCK) ON WOBI.CustomerId = CFW.CustomerId      
				  LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK) ON ESOBI.SOBillingInvoicingId = [IP].SOBillingInvoicingId  
				  LEFT JOIN [dbo].[ExchangeSalesOrder] ES WITH (NOLOCK) ON ESOBI.ExchangeSalesOrderId = ES.ExchangeSalesOrderId      
				  LEFT JOIN [dbo].[Customer] CE WITH (NOLOCK) ON ESOBI.CustomerId = CE.CustomerId      
				  LEFT JOIN [dbo].[CustomerFinancial] CFE WITH (NOLOCK) ON ESOBI.CustomerId = CFE.CustomerId  

			WHERE [IP].[IsDeleted]=0  AND  ((@FromDate IS NULL OR (CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(CP.PostedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CP.PostedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(CP.PostedDate AS DATETIME)) END) >= @FromDate) AND (@ToDate IS NULL OR (CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(CP.PostedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CP.PostedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(CP.PostedDate AS DATETIME)) END) < DATEADD(DAY, 1, @ToDate)))
				  GROUP BY [IP].[ReceiptId],[IP].[DocNum],[IP].[InvoiceDate],[IP].PaymentAmount,Ip.PaymentId,
				  [IP].IsCheckPayment,[IP].IsWireTransfer,[IP].IsCCDCPayment
				  --CPD.IsCheckPayment,CPD.IsWireTransfer,CPD.IsCCDCPayment
				  
			PRINT 'Details Data'
			;WITH Result AS (
				SELECT DISTINCT
					CP.ReceiptID,
					CP.ReceiptNo AS 'ReceiptNo',
					LEB.BankName AS 'BankAccount',
					tmpVal.PaymentType as 'PaymentMethod',
					tmpVal.Reference as 'PaymentReference',
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(CP.PostedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CP.PostedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(CP.PostedDate AS DATETIME)) END PostedDate,
					tmpVal.CustomerName,
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(CP.OpenDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CP.OpenDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(CP.OpenDate AS DATETIME)) END OpenDate,
					
					tmpInv.Amount AS 'baseCurrencyAmount',
					CP.CreatedDate,				
					S.Name AS 'Status',
					CASE 
						WHEN ISNULL(ic.CurrencyId, 0) > 0 THEN ic.CurrencyId
						WHEN ISNULL(iw.CurrencyId, 0) > 0 THEN iw.CurrencyId
						WHEN ISNULL(icd.CurrencyId, 0) > 0 THEN icd.CurrencyId
						ELSE 0 
					END AS 'CurrencyId',
					Cp.GLAccountId,
					Cp.EmployeeId,
					UPPER(MSD.[Level1Name]) as level1,
					UPPER(MSD.[Level2Name]) as level2,       
					UPPER(MSD.[Level3Name]) as level3,       
					UPPER(MSD.[Level4Name]) as level4,       
					UPPER(MSD.[Level5Name]) as level5,       
					UPPER(MSD.[Level6Name]) as level6,       
					UPPER(MSD.[Level7Name]) as level7,       
					UPPER(MSD.[Level8Name]) as level8,       
					UPPER(MSD.[Level9Name]) as level9,       
					UPPER(MSD.[Level10Name])as level10,
					MSD.[Level1Id], 
					MSD.[Level2Id], 
					MSD.[Level3Id], 
					MSD.[Level4Id], 
					MSD.[Level5Id], 
					MSD.[Level6Id], 
					MSD.[Level7Id], 
					MSD.[Level8Id], 
					MSD.[Level9Id], 
					MSD.[Level10Id],
					tmpInv.InvoiceNum as 'InvoiceNum',
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(tmpInv.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(tmpInv.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(tmpInv.InvoiceDate AS DATETIME)) END InvoiceDate,
					DATEADD(DAY, ctm.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(tmpInv.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(tmpInv.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(tmpInv.InvoiceDate AS DATETIME)) END) as DueDate,
				  --'' as 'InvoiceNum',
				  --	  GETUTCDATE() as InvoiceDate,
				  --GETUTCDATE() as DueDate,
					tmpVal.CustomerId
				FROM #invoiceTmpTable tmpInv 
				INNER JOIN dbo.InvoicePayments INV ON tmpInv.InvoicePaymentId = INV.PaymentId
				INNER JOIN [dbo].[CustomerPayments] CP WITH(NOLOCK) ON CP.ReceiptId = tmpInv.ReceiptId
				INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.CustomerPaymentDetailsId = INV.CustomerPaymentDetailsId --AND ISNULL(CPD.IsDeleted, 0) = 0
				INNER JOIN [dbo].[CustomerManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = CP.ReceiptId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH(NOLOCK) ON CP.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN [dbo].[EmployeeUserRole] EUR WITH(NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				LEFT JOIN [dbo].[MasterCustomerPaymentStatus] S WITH(NOLOCK) ON S.Id = CP.StatusId
				LEFT JOIN [dbo].[LegalEntityBankingLockBox] LEB WITH(NOLOCK) ON LEB.LegalEntityBankingLockBoxId = CP.BankName
				LEFT JOIN #CustomerPaymentDetailsTmp tmpVal ON  CPD.CustomerPaymentDetailsId = tmpVal.CustomerPaymentDetailsId  AND tmpVal.PaymentType = tmpInv.PaymentType
				LEFT JOIN #CreditMemoTmp tmpCM ON CPD.CustomerPaymentDetailsId = tmpCM.CustomerPaymentDetailsId
				--INNER JOIN #invoiceTmpTable tmpInv ON CP.ReceiptId = tmpInv.ReceiptId  AND tmpInv.PaymentType = tmpVal.PaymentType
				--INNER JOIN dbo.[InvoicePayments] INV ON  tmpInv.InvoicePaymentId = INV.PaymentId
				LEFT JOIN  [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON CPD.CustomerId = cf.CustomerId AND ISNULL(cf.IsDeleted,0) = 0
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON cf.CreditTermsId = ctm.CreditTermsId
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
				WHERE  (ISNULL(@IsUpdated,0) <> 1 OR ISNULL(CPD.IsUpdated,0) = ISNULL(@IsUpdated,0)) AND Cp.MasterCompanyId =@mastercompanyid
			),
			FinalResult AS (
				SELECT C.Code AS 'BaseCurrency',(G.AccountCode +'-'+G.AccountName) AS 'GlAccountNum' ,
				(E.FirstName +' '+E.LastName) AS 'Employee',
				R.* 
				FROM Result R  
				LEFT JOIN [dbo].[Currency] C WITH(NOLOCK) ON R.CurrencyId = C.CurrencyId  
				LEFT JOIN [dbo].[GLAccount] G WITH(NOLOCK) ON R.GLAccountId = G.GLAccountId
				LEFT JOIN [dbo].[Employee] E WITH(NOLOCK) ON R.EmployeeId = E.EmployeeId
				WHERE (
					    
					((
						(ISNULL(@bankAccount, '') = '' OR bankAccount LIKE '%' + @bankAccount + '%') AND    
						(ISNULL(@PaymentReference, '') = '' OR PaymentReference LIKE '%' + @PaymentReference + '%') AND    
						(ISNULL(@baseCurrency, '') = '' OR C.Code LIKE '%' + @baseCurrency + '%') AND  
						(ISNULL(@InvoiceNum, '') = '' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND 
						(ISNULL(@CustomerName, '') = '' OR CustomerName LIKE '%' + @CustomerName + '%') AND  
						(ISNULL(@CustomerId, 0) = 0 OR CustomerId =@CustomerId) AND
						(ISNULL(@PaymentMethod, '') = '' OR PaymentMethod LIKE '%' + @PaymentMethod + '%') AND     
						(@PostedDate IS NULL OR CAST(PostedDate AS DATE) = CAST(@PostedDate AS DATE)) AND    
						(@baseCurrencyAmount IS NULL   OR CONCAT(baseCurrencyAmount, '') LIKE '%' + CONCAT(@baseCurrencyAmount, '') + '%') AND    
						(ISNULL(@level1Str,'') ='' OR [level1] LIKE '%' + @level1Str + '%') AND
						  (ISNULL(@level2Str,'') ='' OR [level2] LIKE '%' + @level2Str + '%') AND
						  (ISNULL(@level3Str,'') ='' OR [level3] LIKE '%' + @level3Str + '%') AND
						  (ISNULL(@level4Str,'') ='' OR [level4] LIKE '%' + @level4Str + '%') AND
						  (ISNULL(@level5Str,'') ='' OR [level5] LIKE '%' + @level5Str + '%') AND
						  (ISNULL(@level6Str,'') ='' OR [level6] LIKE '%' + @level6Str + '%') AND
						  (ISNULL(@level7Str,'') ='' OR [level7] LIKE '%' + @level7Str + '%') AND
						  (ISNULL(@level8Str,'') ='' OR [level8] LIKE '%' + @level8Str + '%') AND
						  (ISNULL(@level9Str,'') ='' OR [level9] LIKE '%' + @level9Str + '%') AND
						  (ISNULL(@level10Str,'') ='' OR [level10] LIKE '%' + @level10Str + '%') AND
						  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
						  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
						  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
						  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
						  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
						  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
						  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
						  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
						  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
						  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))) AND
						  ((@FromDate IS NULL OR PostedDate >= @FromDate) AND (@ToDate IS NULL OR PostedDate < DATEADD(DAY, 1, @ToDate)))AND
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
				CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME') THEN CustomerName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME') THEN CustomerName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END ASC, 
				CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END DESC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='PaymentReference') THEN PaymentReference END ASC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentReference') THEN PaymentReference END DESC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='PostedDate') THEN PostedDate END ASC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='PostedDate') THEN PostedDate END DESC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='BaseCurrency') THEN BaseCurrency END ASC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='BaseCurrency') THEN BaseCurrency END DESC, 
				CASE WHEN (@SortOrder=1 and @SortColumn='BaseCurrencyAmount') THEN baseCurrencyAmount END ASC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='BaseCurrencyAmount') THEN baseCurrencyAmount END DESC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='GlAccountNum') THEN GlAccountNum END ASC, 
				CASE WHEN (@SortOrder=-1 and @SortColumn='GlAccountNum') THEN GlAccountNum END DESC,  
				CASE WHEN (@SortOrder=1 and @SortColumn='Employee') THEN Employee END ASC,   
				CASE WHEN (@SortOrder=-1 and @SortColumn='Employee') THEN Employee END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNum') THEN InvoiceNum END ASC,   
				CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNum') THEN InvoiceNum END DESC, 
				CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate') THEN InvoiceDate END ASC,   
				CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceDate') THEN InvoiceDate END DESC, 
				CASE WHEN (@SortOrder=1 and @SortColumn='DueDate') THEN DueDate END ASC,   
				CASE WHEN (@SortOrder=-1 and @SortColumn='DueDate') THEN DueDate END DESC, 
				CASE WHEN (@SortOrder=1 and @SortColumn='BankAccount') THEN BankAccount END ASC, 		   
				CASE WHEN (@SortOrder=-1 and @SortColumn='BankAccount') THEN BankAccount END DESC   
				    
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
			WHERE ISNULL(CPD.IsCheckPayment, 0) = 1 AND ISNULL(CPD.IsMultiplePaymentMethod, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICP.CheckDate, ICP.CheckNumber, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Check', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(ICP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), ICP.CheckDate, isnull(ICP.CheckNumber, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceCheckPayment] ICP WITH(NOLOCK) ON ICP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsMultiplePaymentMethod, 0) = 1 AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0  AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICP.CheckDate, ICP.CheckNumber, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Wire Transfer', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(IWP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), IWP.WireDate, isnull(IWP.ReferenceNo, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH(NOLOCK) ON IWP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsWireTransfer, 0) = 1 AND ISNULL(CPD.IsMultiplePaymentMethod, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND Cp.MasterCompanyId =@mastercompanyid 
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, IWP.WireDate, IWP.ReferenceNo, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Wire Transfer', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(IWP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), IWP.WireDate, isnull(IWP.ReferenceNo, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceWireTransferPayment] IWP WITH(NOLOCK) ON IWP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsMultiplePaymentMethod, 0) = 1 AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0  AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, IWP.WireDate, IWP.ReferenceNo, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Credit Card/Debit Card', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(ICDP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), ICDP.PaymentDate, isnull(ICDP.Reference, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceCreditDebitCardPayment] ICDP WITH(NOLOCK) ON ICDP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsCCDCPayment, 0) = 1 AND ISNULL(CPD.IsMultiplePaymentMethod, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0  AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICDP.PaymentDate, ICDP.Reference, CPD.CustomerPaymentDetailsId

			INSERT INTO #CustomerPaymentDetailsTmp([ReceiptId], [CustomerPaymentDetailsId], [PaymentType], [CustomerId], [CustomerName], [CustomerCode], [Amount], [AmtApplied], [AmtRemaining], [CheckDate], [Reference])
			SELECT CPD.ReceiptId, CPD.CustomerPaymentDetailsId, 'Credit Card/Debit Card', CPD.CustomerId, CU.Name, CU.CustomerCode, SUM(ISNULL(ICDP.Amount, 0)), SUM(ISNULL(CPD.AppliedAmount, 0)), SUM(ISNULL(CPD.AmountRem, 0)), ICDP.PaymentDate, isnull(ICDP.Reference, '')
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			INNER JOIN [dbo].[InvoiceCreditDebitCardPayment] ICDP WITH(NOLOCK) ON ICDP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = CPD.CustomerId
			WHERE ISNULL(CPD.IsMultiplePaymentMethod, 0) = 1 AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CPD.ReceiptId, CPD.CustomerId, CU.Name, CU.CustomerCode, ICDP.PaymentDate, ICDP.Reference, CPD.CustomerPaymentDetailsId

			INSERT INTO #CreditMemoTmp([ReceiptId], [CreditMemoAmount], [CustomerPaymentDetailsId])
			SELECT CP.ReceiptId, SUM(ABS(ISNULL(IVP.OriginalAmount, 0))),CPD.CustomerPaymentDetailsId
			FROM [dbo].[CustomerPayments] CP WITH(NOLOCK)
			INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
			LEFT JOIN [dbo].[InvoicePayments] IVP WITH(NOLOCK) ON IVP.CustomerPaymentDetailsId = CPD.CustomerPaymentDetailsId
			WHERE IVP.InvoiceType IN (3, 4, 5, 7) AND ISNULL(CPD.IsDeleted, 0) = 0 AND ISNULL(CPD.IsDeleted, 0) = 0 AND Cp.MasterCompanyId =@mastercompanyid
			GROUP BY CP.ReceiptId, CPD.CustomerPaymentDetailsId

			INSERT INTO #invoiceTmpTable([ReceiptId], InvoiceNum, InvoiceDate,Amount,InvoicePaymentId,[PaymentType])
			SELECT DISTINCT
				[IP].[ReceiptId],
				 UPPER([IP].[DocNum]) AS InvoiceNum,   
				 [IP].[InvoiceDate] as InvoiceDate,  
				 --UPPER([IP].[WOSONum]) AS WOSONum,  
				 [IP].[PaymentAmount] As Amount   
				 ,Ip.PaymentId as InvoicePaymentId,
				 --CASE WHEN CPD.IsCheckPayment = 1 THEN 'Check' WHEN CPD.IsWireTransfer = 1 THEN 'Wire Transfer' WHEN CPD.IsCCDCPayment = 1 THEN 'Credit Card/Debit Card' END AS PaymentType
				 --,[IP].[Status]
				  CASE WHEN [IP].IsCheckPayment = 1 THEN 'Check' WHEN [IP].IsWireTransfer = 1 THEN 'Wire Transfer' WHEN [IP].IsCCDCPayment = 1 THEN 'Credit Card/Debit Card' END AS PaymentType
			FROM  [dbo].[InvoicePayments] [IP] WITH(NOLOCK)
				  INNER JOIN dbo.[CustomerPaymentDetails]  CPD WITH(NOLOCK) ON [IP].ReceiptId = CPD.ReceiptId AND CPD.CustomerPaymentDetailsId = [IP].CustomerPaymentDetailsId
				  INNER JOIN [dbo].[CustomerPayments] CP WITH(NOLOCK) ON CPD.ReceiptId = CP.ReceiptId
				  --INNER JOIN [dbo].[InvoicePayments] [IP] WITH (NOLOCK)  ON  CPD.ReceiptId = [IP].ReceiptId 
				  LEFT JOIN [dbo].[BillingInvoicing] SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId = [IP].SOBillingInvoicingId AND SOBI.[ModuleId] = @SOModuleId AND [IP].[InvoiceType] = @SOInvoiceType  	 
				  LEFT JOIN [dbo].[SalesOrder] S WITH (NOLOCK) ON SOBI.ReferenceId = S.SalesOrderId      
				  LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId      
				  LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON SOBI.CustomerId = CF.CustomerId      
				  LEFT JOIN [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) ON WOBI.BillingInvoicingId = [IP].SOBillingInvoicingId AND WOBI.[ModuleId] = @WOModuleId AND [IP].[InvoiceType] = @WOInvoiceType 	 	 
				  LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON  WO.WorkOrderId = WOBI.ReferenceId  and WOBI.IsVersionIncrease = 0      
				  LEFT JOIN [dbo].[Customer] CW WITH (NOLOCK) ON WOBI.CustomerId = CW.CustomerId      
				  LEFT JOIN [dbo].[CustomerFinancial] CFW WITH (NOLOCK) ON WOBI.CustomerId = CFW.CustomerId      
				  LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK) ON ESOBI.SOBillingInvoicingId = [IP].SOBillingInvoicingId  
				  LEFT JOIN [dbo].[ExchangeSalesOrder] ES WITH (NOLOCK) ON ESOBI.ExchangeSalesOrderId = ES.ExchangeSalesOrderId      
				  LEFT JOIN [dbo].[Customer] CE WITH (NOLOCK) ON ESOBI.CustomerId = CE.CustomerId      
				  LEFT JOIN [dbo].[CustomerFinancial] CFE WITH (NOLOCK) ON ESOBI.CustomerId = CFE.CustomerId  

			WHERE [IP].[IsDeleted]=0  AND  ((@FromDate IS NULL OR (CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(CP.PostedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CP.PostedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(CP.PostedDate AS DATETIME)) END) >= @FromDate) AND (@ToDate IS NULL OR (CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(CP.PostedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CP.PostedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(CP.PostedDate AS DATETIME)) END) < DATEADD(DAY, 1, @ToDate)))
				  GROUP BY [IP].[ReceiptId],[IP].[DocNum],[IP].[InvoiceDate],[IP].PaymentAmount,Ip.PaymentId,
				  [IP].IsCheckPayment,[IP].IsWireTransfer,[IP].IsCCDCPayment
				  --CPD.IsCheckPayment,CPD.IsWireTransfer,CPD.IsCCDCPayment


				PRINT 'Summary Data'
			;WITH Result AS (
				SELECT DISTINCT
					CP.ReceiptID,
					CP.ReceiptNo AS 'ReceiptNo',
					LEB.BankName AS 'BankAccount',
					tmpVal.PaymentType as 'PaymentMethod',
					tmpVal.Reference as 'PaymentReference',
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(CP.PostedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CP.PostedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(CP.PostedDate AS DATETIME)) END PostedDate,
					tmpVal.CustomerName,
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(CP.OpenDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CP.OpenDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(CP.OpenDate AS DATETIME)) END OpenDate,
					
					tmpInv.Amount AS 'baseCurrencyAmount',
					CP.CreatedDate,				
					S.Name AS 'Status',
					CASE 
						WHEN ISNULL(ic.CurrencyId, 0) > 0 THEN ic.CurrencyId
						WHEN ISNULL(iw.CurrencyId, 0) > 0 THEN iw.CurrencyId
						WHEN ISNULL(icd.CurrencyId, 0) > 0 THEN icd.CurrencyId
						ELSE 0 
					END AS 'CurrencyId',
					Cp.GLAccountId,
					Cp.EmployeeId,
					UPPER(MSD.[Level1Name]) as level1,
					UPPER(MSD.[Level2Name]) as level2,       
					UPPER(MSD.[Level3Name]) as level3,       
					UPPER(MSD.[Level4Name]) as level4,       
					UPPER(MSD.[Level5Name]) as level5,       
					UPPER(MSD.[Level6Name]) as level6,       
					UPPER(MSD.[Level7Name]) as level7,       
					UPPER(MSD.[Level8Name]) as level8,       
					UPPER(MSD.[Level9Name]) as level9,       
					UPPER(MSD.[Level10Name])as level10,
					MSD.[Level1Id], 
					MSD.[Level2Id], 
					MSD.[Level3Id], 
					MSD.[Level4Id], 
					MSD.[Level5Id], 
					MSD.[Level6Id], 
					MSD.[Level7Id], 
					MSD.[Level8Id], 
					MSD.[Level9Id], 
					MSD.[Level10Id],
					tmpInv.InvoiceNum as 'InvoiceNum',
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(tmpInv.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(tmpInv.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(tmpInv.InvoiceDate AS DATETIME)) END InvoiceDate,
					DATEADD(DAY, ctm.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(tmpInv.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(tmpInv.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(tmpInv.InvoiceDate AS DATETIME)) END) as DueDate,
					tmpVal.CustomerId
				FROM #invoiceTmpTable tmpInv 
				INNER JOIN dbo.InvoicePayments INV ON tmpInv.InvoicePaymentId = INV.PaymentId
				INNER JOIN [dbo].[CustomerPayments] CP WITH(NOLOCK) ON CP.ReceiptId = tmpInv.ReceiptId
				INNER JOIN [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) ON CPD.CustomerPaymentDetailsId = INV.CustomerPaymentDetailsId --AND ISNULL(CPD.IsDeleted, 0) = 0
				INNER JOIN [dbo].[CustomerManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = CP.ReceiptId
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH(NOLOCK) ON CP.ManagementStructureId = RMS.EntityStructureId
				INNER JOIN [dbo].[EmployeeUserRole] EUR WITH(NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				LEFT JOIN [dbo].[MasterCustomerPaymentStatus] S WITH(NOLOCK) ON S.Id = CP.StatusId
				LEFT JOIN [dbo].[LegalEntityBankingLockBox] LEB WITH(NOLOCK) ON LEB.LegalEntityBankingLockBoxId = CP.BankName
				LEFT JOIN #CustomerPaymentDetailsTmp tmpVal ON  CPD.CustomerPaymentDetailsId = tmpVal.CustomerPaymentDetailsId  AND tmpVal.PaymentType = tmpInv.PaymentType
				LEFT JOIN #CreditMemoTmp tmpCM ON CPD.CustomerPaymentDetailsId = tmpCM.CustomerPaymentDetailsId
						LEFT JOIN  [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON CPD.CustomerId = cf.CustomerId AND ISNULL(cf.IsDeleted,0) = 0
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON cf.CreditTermsId = ctm.CreditTermsId
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
				WHERE  (ISNULL(@IsUpdated,0) <> 1 OR ISNULL(CPD.IsUpdated,0) = ISNULL(@IsUpdated,0)) AND Cp.MasterCompanyId =@mastercompanyid
			),
			FinalResult AS (
				SELECT C.Code AS 'BaseCurrency',(G.AccountCode +'-'+G.AccountName) AS 'GlAccountNum' ,
				(E.FirstName +' '+E.LastName) AS 'Employee',
				R.* 
				FROM Result R  
				LEFT JOIN [dbo].[Currency] C WITH(NOLOCK) ON R.CurrencyId = C.CurrencyId  
				LEFT JOIN [dbo].[GLAccount] G WITH(NOLOCK) ON R.GLAccountId = G.GLAccountId
				LEFT JOIN [dbo].[Employee] E WITH(NOLOCK) ON R.EmployeeId = E.EmployeeId
				WHERE (      
					((
						(ISNULL(@bankAccount, '') = '' OR bankAccount LIKE '%' + @bankAccount + '%') AND    
						(ISNULL(@PaymentReference, '') = '' OR PaymentReference LIKE '%' + @PaymentReference + '%') AND    
						(ISNULL(@baseCurrency, '') = '' OR C.Code LIKE '%' + @baseCurrency + '%') AND  
						(ISNULL(@CustomerName, '') = '' OR CustomerName LIKE '%' + @CustomerName + '%') AND
						(ISNULL(@CustomerId, 0) = 0 OR CustomerId =@CustomerId) AND
						(ISNULL(@PaymentMethod, '') = '' OR PaymentMethod LIKE '%' + @PaymentMethod + '%') AND     
						(@PostedDate IS NULL OR CAST(PostedDate AS DATE) = CAST(@PostedDate AS DATE)) AND    
						(@baseCurrencyAmount IS NULL   OR CONCAT(baseCurrencyAmount, '') LIKE '%' + CONCAT(@baseCurrencyAmount, '') + '%') AND   
						(ISNULL(@level1Str,'') ='' OR [level1] LIKE '%' + @level1Str + '%') AND
						  (ISNULL(@level2Str,'') ='' OR [level2] LIKE '%' + @level2Str + '%') AND
						  (ISNULL(@level3Str,'') ='' OR [level3] LIKE '%' + @level3Str + '%') AND
						  (ISNULL(@level4Str,'') ='' OR [level4] LIKE '%' + @level4Str + '%') AND
						  (ISNULL(@level5Str,'') ='' OR [level5] LIKE '%' + @level5Str + '%') AND
						  (ISNULL(@level6Str,'') ='' OR [level6] LIKE '%' + @level6Str + '%') AND
						  (ISNULL(@level7Str,'') ='' OR [level7] LIKE '%' + @level7Str + '%') AND
						  (ISNULL(@level8Str,'') ='' OR [level8] LIKE '%' + @level8Str + '%') AND
						  (ISNULL(@level9Str,'') ='' OR [level9] LIKE '%' + @level9Str + '%') AND
						  (ISNULL(@level10Str,'') ='' OR [level10] LIKE '%' + @level10Str + '%') AND
						  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
						  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
						  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
						  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
						  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
						  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
						  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
						  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
						  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
						  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))) AND
						  ((@FromDate IS NULL OR PostedDate >= @FromDate) AND (@ToDate IS NULL OR PostedDate < DATEADD(DAY, 1, @ToDate)))AND
						(ISNULL(@Status, '') = '' OR Status LIKE '%' + @Status + '%')       
					))
				)
			),
			 CustomerWiseResult AS
				(
					SELECT
						CustomerId,
						CustomerName,

						SUM(baseCurrencyAmount) AS baseCurrencyAmount,

						CASE 
							WHEN COUNT(DISTINCT PaymentReference) > 1 
								THEN 'Multiple'
							ELSE MAX(PaymentReference)
						END AS PaymentReference,

						CASE 
							WHEN COUNT(DISTINCT ReceiptNo) > 1 
								THEN 'Multiple'
							ELSE MAX(ReceiptNo)
						END AS ReceiptNo,
						MAX(PostedDate) PostedDate,
						--CASE 
						--	WHEN COUNT(DISTINCT CAST(PostedDate AS DATE)) > 1
						--		THEN 'Multiple'
						--	ELSE CONVERT(VARCHAR(10), MAX(PostedDate), 120)
						--END AS PostedDate,

						CASE 
							WHEN COUNT(DISTINCT PaymentMethod) > 1 
								THEN 'Multiple'
							ELSE MAX(PaymentMethod)
						END AS PaymentMethod,
						CASE 
							WHEN COUNT(DISTINCT BankAccount) > 1 
								THEN 'Multiple'
							ELSE MAX(BankAccount)
						END AS BankAccount,

						--MAX(BaseCurrency) AS BaseCurrency,
						CASE 
							WHEN COUNT(DISTINCT BaseCurrency) > 1 
								THEN 'Multiple'
							ELSE MAX(BaseCurrency)
						END AS BaseCurrency,
						--MAX(PaymentMethod) AS PaymentMethod,
						--MAX(BankAccount) AS BankAccount,
						MAX(Status) AS Status,
						--MAX(GlAccountNum) AS GlAccountNum,
						CASE 
							WHEN COUNT(DISTINCT GlAccountNum) > 1 
								THEN 'Multiple'
							ELSE MAX(GlAccountNum)
						END AS GlAccountNum,
						--MAX(Employee) AS Employee,
						CASE 
							WHEN COUNT(DISTINCT Employee) > 1 
								THEN 'Multiple'
							ELSE MAX(Employee)
						END AS Employee,

						MAX(level1) AS level1,
						MAX(level2) AS level2,
						MAX(level3) AS level3,
						MAX(level4) AS level4,
						MAX(level5) AS level5,
						MAX(level6) AS level6,
						MAX(level7) AS level7,
						MAX(level8) AS level8,
						MAX(level9) AS level9,
						MAX(level10) AS level10,
						'' as 'InvoiceNum',
						GETUTCDATE() InvoiceDate,
						GETUTCDATE() as DueDate
					FROM FinalResult
					WHERE CustomerId IS NOT NULL
					GROUP BY
						CustomerId,
						CustomerName
				),
			ResultCount AS (
				SELECT COUNT(CustomerId) AS NumberOfItems FROM CustomerWiseResult
			)
			SELECT * 
			FROM CustomerWiseResult, ResultCount    
			ORDER BY    
				CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME') THEN CustomerName END ASC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME') THEN CustomerName END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END ASC, 
				CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentMethod')  THEN PaymentMethod END DESC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='PaymentReference') THEN PaymentReference END ASC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='PaymentReference') THEN PaymentReference END DESC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='PostedDate') THEN PostedDate END ASC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='PostedDate') THEN PostedDate END DESC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='BaseCurrency') THEN BaseCurrency END ASC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='BaseCurrency') THEN BaseCurrency END DESC, 
				CASE WHEN (@SortOrder=1 and @SortColumn='BaseCurrencyAmount') THEN baseCurrencyAmount END ASC,    
				CASE WHEN (@SortOrder=-1 and @SortColumn='BaseCurrencyAmount') THEN baseCurrencyAmount END DESC,    
				CASE WHEN (@SortOrder=1 and @SortColumn='GlAccountNum') THEN GlAccountNum END ASC, 
				CASE WHEN (@SortOrder=-1 and @SortColumn='GlAccountNum') THEN GlAccountNum END DESC,  
				CASE WHEN (@SortOrder=1 and @SortColumn='Employee') THEN Employee END ASC,   
				CASE WHEN (@SortOrder=-1 and @SortColumn='Employee') THEN Employee END DESC, 
				CASE WHEN (@SortOrder=1 and @SortColumn='BankAccount') THEN BankAccount END ASC, 		   
				CASE WHEN (@SortOrder=-1 and @SortColumn='BankAccount') THEN BankAccount END DESC   
				    
			OFFSET @RecordFrom ROWS FETCH NEXT @PageSize ROWS ONLY;

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
    IF OBJECT_ID(N'tempdb..#TEMPInvoiceRecordsDetailsView') IS NOT NULL
    BEGIN
      DROP TABLE #TEMPInvoiceRecordsDetailsView
    END

    DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME(),
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        @AdhocComments varchar(150) = '[usprpt_CashReceiptReportList_SSRS]',
        @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
        @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
        @AdhocComments = @AdhocComments,
        @ProcedureParameters = @ProcedureParameters,
        @ApplicationName = @ApplicationName,
        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH

  IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
  BEGIN
    DROP TABLE #managmetnstrcture
  END
END