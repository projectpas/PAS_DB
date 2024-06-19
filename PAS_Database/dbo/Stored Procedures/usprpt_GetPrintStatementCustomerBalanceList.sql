/*************************************************************           
 ** File:   [usprpt_GetPrintStatementCustomerBalanceList]           
 ** Author:   HEMANT SALIYA  
 ** Description: Get Data for PRINT STATEMENT INVOICE LISTING SCREEN 
 ** Purpose:         
 ** Date:   17-06-2024       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  			Change Description            
 ** --   --------		-------				--------------------------------          
	1	 17-06-2024		HEMANT SALIYA  		Created

EXEC [dbo].[usprpt_GetPrintStatementCustomerBalanceList] 1,10,'CreatedDate',-1,'',2,'','','','',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,61,NULL,NULL,NULL,NULL,NULL,'ALL',1	     

**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetPrintStatementCustomerBalanceList]
  @PageNumber                  INT = NULL,
  @PageSize                    INT = NULL,
  @SortColumn                  VARCHAR(50)=NULL,
  @SortOrder                   INT = NULL,
  @GlobalFilter                VARCHAR(50) = NULL,
  @StatusId                    INT = NULL,
  @CustName                    VARCHAR(50) = NULL,
  @CustomerCode                VARCHAR(50) = NULL,
  @CustomertType               VARCHAR(50) = NULL,
  @CurrencyCode                VARCHAR(50) = NULL,
  @BalanceAmount               DECIMAL(18,2) = NULL,
  @CurrentAmount               DECIMAL(18,2) = NULL,
  @CreditMemoAmount            DECIMAL(18,2) = NULL,
  @Amountlessthan0days		   DECIMAL(18,2) = NULL,
  @Amountlessthan30days        DECIMAL(18,2) = NULL,
  @Amountlessthan60days        DECIMAL(18,2) = NULL,
  @Amountlessthan90days        DECIMAL(18,2) = NULL,
  @Amountlessthan120days       DECIMAL(18,2) = NULL,
  @Amountmorethan120days	   DECIMAL(18,2) = NULL,
  @LegelEntity                 VARCHAR(50) = NULL,
  @EmployeeId                  BIGINT = NULL,
  @CreatedBy                   VARCHAR(50) = NULL,
  @CreatedDate                 DATETIME = NULL,
  @UpdatedBy                   VARCHAR(50) = NULL,
  @UpdatedDate                 DATETIME = NULL,
  @viewType                    VARCHAR(50) = NULL,
  @MasterCompanyId             BIGINT = NULL

AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    DECLARE @RecordFrom INT;
	DECLARE @Count INT;
	DECLARE @TotalAmount DECIMAL(18,2) = 0;	
	DECLARE @TotalCurrentAmount DECIMAL(18,2) = 0;
	DECLARE @TotalReceivedAmount DECIMAL(18,2) = 0;
	DECLARE @TotalAmountlessthan0days  DECIMAL(18,2) = 0;
	DECLARE @TotalAmountlessthan30days DECIMAL(18,2) = 0;  
	DECLARE @TotalAmountlessthan60days DECIMAL(18,2) = 0; 
	DECLARE @TotalAmountlessthan90days DECIMAL(18,2) = 0;
	DECLARE @TotalAmountlessthan120days DECIMAL(18,2) = 0;
	DECLARE @TotalAmountmorethan120days DECIMAL(18,2) = 0;

	DECLARE @CMPostedStatusId INT;
	DECLARE @ClosedCreditMemoStatus INT;
	DECLARE @WOInvoiceTypeId INT;
	DECLARE @SOInvoiceTypeId INT;
	DECLARE @EXInvoiceTypeId INT;
    DECLARE @InvoiceStatus VARCHAR(20)='Invoiced'
	DECLARE @SO INT = 1;
	DECLARE @WO INT = 2;
	DECLARE @Exch INT = 6;
	DECLARE @CustomerPaymentsPostedStatus INT= 2;
	DECLARE @MJEPostStatusId INT;
	DECLARE @MSModuleId INT;	
	DECLARE @CustomerCreditPaymentOpenStatus INT = 1

	DECLARE @WOModuleTypeId INT = 1
	DECLARE @SOModuleTypeId INT = 2
	DECLARE @EXSOModuleTypeId INT = 3
	DECLARE @CMModuleTypeId INT = 4	
	DECLARE @STLCMModuleTypeId INT = 5
	DECLARE @MJEModuleTypeId INT = 6
	DECLARE @UAModuleTypeId INT = 7		
	
    SELECT @CMPostedStatusId = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'POSTED';  	  
    SELECT @ClosedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Closed';
    SELECT @WOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WHERE ModuleName='WorkOrder';
    SELECT @SOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WHERE ModuleName='SalesOrder';
    SELECT @EXInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WHERE ModuleName='Exchange';
    SELECT @MJEPostStatusId = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WHERE [Name] = 'Posted';
    SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='ManualJournalAccounting';
	
	SET @RecordFrom = (@PageNumber - 1) * @PageSize;
				
	IF @SortColumn IS NULL
	BEGIN
		SET @SortColumn = UPPER('INVOICEDATE')		
	END 
	ELSE
	BEGIN 
		SET @SortColumn = UPPER(@SortColumn)		
	END	

	IF (ISNULL(@ViewType, '') = '')
	BEGIN
		SET @viewType = 'ALL'
	END
		
    BEGIN TRY

		DECLARE @SOMSModuleID BIGINT ; -- = 17 Sales Order MS Module ID 
		DECLARE @WOMSModuleID BIGINT ; -- = 12 Work Order MS Module ID  
		DECLARE @CMMSModuleID BIGINT ; -- = 61 CM MS Module ID  
		DECLARE @ESOMSModuleID BIGINT;
		DECLARE @SuspenseModuleID BIGINT;
		DECLARE @ISDebugMode BIT;

		DECLARE @CustomerId BIGINT

		SET @CustName = 'LUICE INDIA LTD'
		SET @CustomerId = 3389
		SET @ISDebugMode = 0;
			  
		SELECT @WOMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='WORKORDERMPN';
		SELECT @SOMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='SALESORDER ';
		SELECT @CMMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='CREDITMEMOHEADER';
	    SELECT @ESOMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSOHeader';
		SELECT @SuspenseModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='SUSPENSEANDUNAPPLIEDPAYMENT';
		
		IF(UPPER(@ViewType) = 'ALL')  -- VIEW
		BEGIN
			IF OBJECT_ID(N'tempdb..#TEMPInvoiceRecords') IS NOT NULL    
			BEGIN    
				DROP TABLE #TEMPInvoiceRecords
			END

			CREATE TABLE #TEMPInvoiceRecords(        
				[ID] BIGINT IDENTITY(1,1),      
				[BillingInvoicingId] BIGINT NOT NULL,
				[CustomerId] BIGINT NULL,
				[CustomerName] VARCHAR(200) NULL,
				[CustomerCode] VARCHAR(50) NULL,	
				[CurrencyCode] VARCHAR(50) NULL,		
				[BalanceAmount] DECIMAL(18, 2) NULL,
				[CurrentAmount] DECIMAL(18, 2) NULL,
				[PaymentAmount] DECIMAL(18, 2) NULL,
				[Amountlessthan0days] DECIMAL(18, 2) NULL,
				[Amountlessthan30days] DECIMAL(18, 2) NULL,
				[Amountlessthan60days] DECIMAL(18, 2) NULL,
				[Amountlessthan90days] DECIMAL(18, 2) NULL,
				[Amountlessthan120days] DECIMAL(18, 2) NULL,
				[Amountmorethan120days] DECIMAL(18, 2) NULL,		
				[InvoiceAmount] DECIMAL(18, 2) NULL,
				[CMAmount] DECIMAL(18, 2) NULL,
				[CreditMemoAmount] DECIMAL(18, 2) NULL,
				[CreditMemoUsed] DECIMAL(18, 2) NULL,
				[MasterCompanyId] INT NULL,
				[StatusId] BIGINT NULL,
				[IsCreditMemo] BIT NULL,
				[InvoicePaidAmount] DECIMAL(18, 2) NULL,
				[ModuleTypeId] INT NULL,
				[LegalEntityName] VARCHAR(MAX) NULL,
				[ReceivedAmount] DECIMAL(18, 2) NULL,
			) 
		
			-- WO INVOICE DETAILS

			SELECT WO.WorkOrderId, WO.customerid, SUM(ISNULL(WOBI.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(WOBI.DepositAmount,0)) as OriginalDepositAmt  
			INTO #ProformaDepositAmt
			FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) 
			INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId	= WOBI.WorkOrderId
			GROUP BY WO.WorkOrderId, WO.customerid
			
			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],[CurrencyCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName],[ReceivedAmount])
			SELECT DISTINCT WOBI.[BillingInvoicingId],			               
							C.[CustomerId],
							UPPER(ISNULL(C.[Name],'')),      
							UPPER(ISNULL(C.[CustomerCode],'')),
							CR.Code,
							WOBI.[GrandTotal], -- BalanceAmount
							((ISNULL(WOBI.[GrandTotal], 0) - ISNULL(WOBI.[RemainingAmount], 0)) + ISNULL(WOBI.[CreditMemoUsed], 0)),  -- CurrentAmount     
							ISNULL(WOBI.[RemainingAmount], 0) + ISNULL(WOBI.[CreditMemoUsed], 0), --PaymentAmount  		               				
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN WOBI.RemainingAmount	ELSE 0 END),
							WOBI.[GrandTotal],  -- InvoiceAmount      
							0,
							0,
							ISNULL(WOBI.[CreditMemoUsed],0) AS CreditMemoUsed,							
							WO.MasterCompanyId,
							0 AS StatusId,
							0 AS IsCreditMemo,
							0,
							@WOModuleTypeId, -- 'WorkOrder',
							LegalEntityName = (SELECT   
							STUFF((SELECT DISTINCT ',' + LE.[Name]  
								FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK)
									JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = WOP.ManagementStructureId
									JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
									JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
								WHERE WOP.WorkOrderId = WO.WorkOrderId
								FOR XML PATH('')), 1, 1, '')),
							0
			FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) 
				INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = WOBI.WorkOrderId      
				INNER JOIN [dbo].[Customer] C  WITH (NOLOCK) ON C.CustomerId = WO.CustomerId
				INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = WOBI.CurrencyId
				LEFT JOIN  [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = WO.CreditTermId      
				LEFT JOIN #ProformaDepositAmt PDA ON PDA.WorkOrderId = WO.WorkOrderId
			WHERE ISNULL(WOBI.[IsVersionIncrease],0) = 0 AND WO.[MasterCompanyId] = @MasterCompanyid 
				AND ISNULL(WOBI.[RemainingAmount],0) > 0 AND WOBI.[InvoiceStatus] = @InvoiceStatus

				AND ISNULL(WOBI.[RemainingAmount],0) > 0

				--((ISNULL(WOBI.[GrandTotal], 0) - ISNULL(WOBI.[RemainingAmount], 0)) + ISNULL(WOBI.[CreditMemoUsed], 0)) END > 0

				AND ((ISNULL(WOBI.[IsPerformaInvoice],0) = 0) OR (ISNULL(WOBI.[IsPerformaInvoice],0) = 1 AND (ISNULL(WOBI.GrandTotal, 0) - ISNULL(WOBI.RemainingAmount, 0)) > 0 AND PDA.OriginalDepositAmt - PDA.UsedDepositAmt != 0))
				
				AND WO.[CustomerId] = ISNULL(@CustomerId, WO.CustomerId) 
				--AND ISNULL(WOBI.[IsPerformaInvoice],0) = 0
				--AND CAST(WOBI.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
				--AND @IsInvoice = 1
				--AND (CASE WHEN @IsDeposit = 1 THEN ((ISNULL(WOBI.[GrandTotal], 0) - ISNULL(WOBI.[RemainingAmount], 0)) + ISNULL(WOBI.[CreditMemoUsed], 0)) END > 0 OR CASE WHEN @IsDeposit = 0 THEN 1 END = 1) 
							
			UPDATE #TEMPInvoiceRecords SET InvoicePaidAmount = ISNULL(tmpcash.InvoicePaidAmount,0)
				FROM( SELECT 
					   ISNULL(SUM(IPS.PaymentAmount),0)  AS 'InvoicePaidAmount',				  
					   IPS.SOBillingInvoicingId AS BillingInvoicingId
				 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)   
					JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = IPS.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @WOModuleTypeId
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId  
				 WHERE CP.StatusId = @CustomerPaymentsPostedStatus AND IPS.InvoiceType = @WO 
				 GROUP BY IPS.SOBillingInvoicingId 
				) tmpcash WHERE tmpcash.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId

			UPDATE #TEMPInvoiceRecords SET CreditMemoAmount = ISNULL(tmpcm.CMAmount, 0)
					FROM( SELECT ISNULL(SUM(CMD.Amount),0) AS 'CMAmount', TmpInv.BillingInvoicingId, CMD.BillingInvoicingItemId      
						FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)   
							INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
							INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK) ON WOBII.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId 
							JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = WOBII.BillingInvoicingId AND TmpInv.ModuleTypeId = @WOModuleTypeId
						WHERE CMD.IsWorkOrder = 1 AND CM.CustomerId = TmpInv.CustomerId AND CM.StatusId = @CMPostedStatusId
						GROUP BY CMD.BillingInvoicingItemId, TmpInv.BillingInvoicingId  
				) tmpcm WHERE tmpcm.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId	
		

			IF(@ISDebugMode = 1)
			BEGIN
				SELECT 'WO'
				SELECT * FROM #TEMPInvoiceRecords
			END
			-- SO INVOICE DETAILS

			SELECT SO.SalesOrderId, SO.customerid, SUM(ISNULL(nsobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nsobi.DepositAmount,0)) as OriginalDepositAmt  
			INTO #SOProformaDepositAmt
			FROM [dbo].SalesOrder SO WITH (NOLOCK)  
				INNER JOIN [dbo].SalesOrderPart nsop WITH(NOLOCK) on nsop.SalesOrderId = SO.SalesOrderId
				INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] nsobii WITH(NOLOCK) on nsop.SalesOrderPartId = nsobii.SalesOrderPartId AND ISNULL(nsobii.IsProforma, 0) = 1
				INNER JOIN [dbo].[SalesOrderBillingInvoicing] nsobi WITH(NOLOCK) on nsobii.SOBillingInvoicingId = nsobi.SOBillingInvoicingId AND ISNULL(nsobi.IsProforma, 0) = 1
				AND nsobii.SalesOrderPartId = nsop.SalesOrderPartId 
			GROUP BY SO.SalesOrderId, SO.customerid
			
			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],[CurrencyCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],				   
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName],[ReceivedAmount])
			SELECT DISTINCT SOBI.[SOBillingInvoicingId],
				                C.[CustomerId],  					
                                UPPER(ISNULL(C.[Name],'')),      
                                UPPER(ISNULL(C.[CustomerCode],'')),		
								CR.Code,
								SOBI.[GrandTotal],  -- [BalanceAmount]
								(SOBI.[GrandTotal] - SOBI.[RemainingAmount] + ISNULL(SOBI.[CreditMemoUsed],0)), -- 'CurrentlAmount',
								SOBI.[RemainingAmount] + ISNULL(SOBI.[CreditMemoUsed],0), -- 'PaymentAmount', 
								(CASE WHEN DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
										 WHEN CTM.Code='CIA' THEN -1
										 WHEN CTM.Code='CreditCard' THEN -1
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN SOBI.RemainingAmount ELSE 0 END),
								(CASE WHEN DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN SOBI.RemainingAmount ELSE 0 END),      
                               SOBI.GrandTotal,  -- 'InvoiceAmount'
							   0, -- CMAmount
					           0, -- CreditMemoAmount
							   ISNULL(SOBI.CreditMemoUsed,0), --CreditMemoUsed							  
							   SOBI.MasterCompanyId,
							   0,  --StatusId  
					           0,  --IsCreditMemo
							   0,  --InvoicePaidAmount,
							   @SOModuleTypeId,  --'SalesOrder',
							   LegalEntityName = (SELECT   
								STUFF((SELECT DISTINCT ',' + LE.[Name]  
									 FROM [dbo].[SalesOrderPart] SOP WITH (NOLOCK)
										JOIN [dbo].[Stockline] SL ON SL.StockLineId = SOP.StockLineId
										JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = SL.ManagementStructureId
										JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
										JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
									WHERE SOP.SalesOrderId = SO.SalesOrderId
									FOR XML PATH('')), 1, 1, '')),
							    0
				FROM [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK)       
					INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId      
					INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId = SO.CustomerId   
					INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = SOBI.CurrencyId
					LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON CTM.CreditTermsId = SO.CreditTermId   
					LEFT JOIN #SOProformaDepositAmt SPDA ON SPDA.SalesOrderId = SO.SalesOrderId 
				WHERE SO.[MasterCompanyId] = @Mastercompanyid
					AND ISNULL(SOBI.[RemainingAmount],0) > 0 AND SOBI.[InvoiceStatus] = @InvoiceStatus 
					AND ((ISNULL(SOBI.[IsProforma],0) = 0) OR (ISNULL(SOBI.[IsProforma],0) = 1 AND (ISNULL(SOBI.GrandTotal, 0) - ISNULL(SOBI.RemainingAmount, 0)) > 0 AND SPDA.OriginalDepositAmt - SPDA.UsedDepositAmt != 0))
					

					AND SO.[CustomerId] = ISNULL(@CustomerId, SO.CustomerId) 
					--AND ISNULL(SOBI.[IsProforma],0) = 0 
					--AND CAST(SOBI.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
					--AND @IsInvoice = 1	
					--AND (CASE WHEN @IsDeposit = 1 THEN ((ISNULL(SOBI.[GrandTotal], 0) - ISNULL(SOBI.[RemainingAmount], 0)) + ISNULL(SOBI.[CreditMemoUsed], 0)) END > 0 OR CASE WHEN @IsDeposit = 0 THEN 1 END = 1) 
										
			UPDATE #TEMPInvoiceRecords SET [InvoicePaidAmount] = ISNULL(tmpcash.[InvoicePaidAmount],0)
				FROM(SELECT ISNULL(SUM(IPS.PaymentAmount),0) AS 'InvoicePaidAmount',
					   IPS.SOBillingInvoicingId AS BillingInvoicingId
				 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)   
					JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = IPS.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @SOModuleTypeId
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId  
				 WHERE CP.[StatusId] = @CustomerPaymentsPostedStatus AND IPS.[InvoiceType] = @SO 
				 GROUP BY IPS.SOBillingInvoicingId 
				) tmpcash WHERE tmpcash.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId

			UPDATE #TEMPInvoiceRecords SET [CreditMemoAmount] = ISNULL(tmpcm.[CMAmount], 0)
				FROM( SELECT ISNULL(SUM(CMD.Amount),0) AS 'CMAmount', TmpInv.BillingInvoicingId, CMD.BillingInvoicingItemId      
					FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)   
						INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId 
						INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) ON SOBII.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId 
						JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = SOBII.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @SOModuleTypeId
					WHERE CMD.[IsWorkOrder] = 0 AND CM.[CustomerId] = TmpInv.CustomerId AND CM.[StatusId] = @CMPostedStatusId AND ISNULL(CM.IsClosed, 0) = 0
					GROUP BY CMD.BillingInvoicingItemId, TmpInv.BillingInvoicingId  
			) tmpcm WHERE tmpcm.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId
			
			IF(@ISDebugMode = 1)
			BEGIN
				SELECT 'SO'
				SELECT * FROM #TEMPInvoiceRecords
			END
			-- EXCHANGE SO INVOICE DETAILS --

			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],[CurrencyCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],				   
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName],[ReceivedAmount])			
		    SELECT DISTINCT ESOBI.SOBillingInvoicingId,
				            C.[CustomerId],  					
                            UPPER(ISNULL(C.[Name],'')),      
                            UPPER(ISNULL(C.[CustomerCode],'')),  
							CR.Code,
							(ESOBI.[GrandTotal]), -- 'BalanceAmount',
			                (ESOBI.[GrandTotal] - ESOBI.[RemainingAmount] + ISNULL(ESOBI.[CreditMemoUsed],0)), -- 'CurrentlAmount',
				            (ESOBI.[RemainingAmount] + ISNULL(ESOBI.[CreditMemoUsed],0)), -- 'PaymentAmount', 	
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN ctm.[Code] = 'COD' THEN -1
								   WHEN CTM.[Code]='CIA' THEN -1
								   WHEN CTM.[Code]='CreditCard' THEN -1
								   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) <= 0 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS AmountpaidbylessTHEN0days,
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
								   WHEN CTM.[Code]='CIA' THEN -1
								   WHEN CTM.[Code]='CreditCard' THEN -1
								   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 30 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby30days,
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
								   WHEN CTM.[Code]='CIA' THEN -1
								   WHEN CTM.[Code]='CreditCard' THEN -1
								   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 60 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby60days,
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 				   WHEN CTM.[Code]='CIA' THEN -1
				 				   WHEN CTM.[Code]='CreditCard' THEN -1
				 				   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 90 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby90days,
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 				   WHEN CTM.[Code]='CIA' THEN -1
				 				   WHEN CTM.[Code]='CreditCard' THEN -1
				 				   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 120 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby120days,
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 				   WHEN CTM.[Code]='CIA' THEN -1
								   WHEN CTM.[Code]='CreditCard' THEN -1
								   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 120 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidbymorethan120days,
				             ESOBI.[GrandTotal] AS 'InvoiceAmount', 
							 0, -- CMAmount
					         0, -- CreditMemoAmount
							 ISNULL(ESOBI.CreditMemoUsed,0), --CreditMemoUsed	
							 ESO.[MasterCompanyId],
							 0,
							 0,
							 0,  --InvoicePaidAmount,
							 @EXSOModuleTypeId, 
							 LegalEntityName = (SELECT   
								STUFF((SELECT DISTINCT ',' + LE.[Name]  
									 FROM [dbo].[ExchangeSalesOrderPart] ESOP WITH (NOLOCK)
										JOIN [dbo].[Stockline] SL ON SL.StockLineId = ESOP.StockLineId
										JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = SL.ManagementStructureId
										JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
										JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
									WHERE ESOP.ExchangeSalesOrderId = ESO.ExchangeSalesOrderId
									FOR XML PATH('')), 1, 1, '')),
							0
				FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK)    
							INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.ExchangeSalesOrderId = ESOBI.ExchangeSalesOrderId      
							INNER JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.CustomerId = ESO.CustomerId 
							INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = ESOBI.CurrencyId
							LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = ESO.CreditTermId      
				WHERE ESO.[MasterCompanyId] = @Mastercompanyid 
					AND ISNULL(ESOBI.[RemainingAmount],0) > 0 
					AND ESOBI.[InvoiceStatus] = @InvoiceStatus

					AND ESO.[CustomerId] = ISNULL(@CustomerId, ESO.CustomerId) 
					--AND CAST(ESOBI.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
					--AND @IsInvoice = 1
				    --AND (CASE WHEN @IsDeposit = 1 THEN ((ISNULL(ESOBI.[GrandTotal], 0) - ISNULL(ESOBI.[RemainingAmount], 0)) + ISNULL(ESOBI.[CreditMemoUsed], 0)) END > 0 OR CASE WHEN @IsDeposit = 0 THEN 1 END = 1) 
								
			UPDATE #TEMPInvoiceRecords SET [InvoicePaidAmount] = ISNULL(tmpcash.[InvoicePaidAmount],0)
				FROM(SELECT ISNULL(SUM(IPS.PaymentAmount),0) AS 'InvoicePaidAmount',				  
					   IPS.SOBillingInvoicingId AS BillingInvoicingId
				 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)   
					JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = IPS.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @EXSOModuleTypeId
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId  
				 WHERE CP.[StatusId] = @CustomerPaymentsPostedStatus AND IPS.[InvoiceType] = @Exch
				 GROUP BY IPS.SOBillingInvoicingId 
				) tmpcash WHERE tmpcash.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId

			UPDATE #TEMPInvoiceRecords SET [CreditMemoAmount] = ISNULL(tmpcm.[CMAmount], 0)
				FROM( SELECT ISNULL(SUM(CMD.Amount),0) AS 'CMAmount', TmpInv.BillingInvoicingId, CMD.BillingInvoicingItemId      
					FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)   
						INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId 
						INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) ON SOBII.ExchangeSOBillingInvoicingItemId = CMD.BillingInvoicingItemId 
						JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = SOBII.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @EXSOModuleTypeId
					WHERE CM.InvoiceTypeId = @EXInvoiceTypeId AND CM.[CustomerId] = TmpInv.CustomerId AND CM.[StatusId] = @CMPostedStatusId
					GROUP BY CMD.BillingInvoicingItemId, TmpInv.BillingInvoicingId  
			) tmpcm WHERE tmpcm.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId
			
			IF(@ISDebugMode = 1)
			BEGIN
				SELECT 'Exch SO'
				SELECT * FROM #TEMPInvoiceRecords
			END
			-- CREDIT MEMO --

			--INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
			--       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
			--	   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
			--	   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],				   
			--	   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName],[ReceivedAmount])	
			--SELECT DISTINCT CM.[CreditMemoHeaderId],
			--                C.[CustomerId],     
			--				UPPER(C.[Name]),
			--		        UPPER(C.[CustomerCode]),						
			--				CMD.[Amount],
			--				0,
			--				0,
			--				CMD.[Amount],
			--				0,
			--				0,
			--				0,
			--				0,
			--				0,
			--				CMD.[Amount], --  'InvoiceAmount', 
			--				CMD.[Amount], -- 'CMAmount', 
			--				CMD.[Amount], -- 'CreditMemoAmount',
			--				0, --'CreditMemoUsed'	
			--				CM.[MasterCompanyId],
			--				CM.[StatusId],
			--				1,
			--				0,  -- 'InvoicePaidAmount',
			--				@CMModuleTypeId,  -- 'Credit Memo',
			--		        LE.[Name],
			--				0
			-- FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
			--	INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
			--	LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
			--    LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			--    LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CF.CreditTermsId  
			--	INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId
			--	INNER JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = CM.ManagementStructureId
			--	INNER JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
			--	INNER JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
			--WHERE CM.MasterCompanyId = @MasterCompanyid  
			--	AND CM.StatusId = @CMPostedStatusId		 
			--	AND CM.[CustomerId] = ISNULL(@CustomerId, CM.CustomerId) 
				----AND CAST(CM.InvoiceDate AS DATE) <= CAST(@AsOfDate AS DATE) 
				----AND CM.MasterCompanyId = @MasterCompanyid  
				----AND @IsCredits = 1
			
			IF(@ISDebugMode = 1)
			BEGIN
				SELECT 'CREDIT MEMO'
				SELECT * FROM #TEMPInvoiceRecords
			END
			-- STAND ALONE CREDIT MEMO --
				
			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],[CurrencyCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],				   
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName],[ReceivedAmount])	
			SELECT DISTINCT CM.[CreditMemoHeaderId],
			                C.[CustomerId],     
							UPPER(C.[Name]),
					        UPPER(C.[CustomerCode]),	
							CR.Code,
							CM.Amount,
							0,
							0,
							CM.Amount,
							0,
							0,
							0,
							0,
							0,
							CM.[Amount], --  'InvoiceAmount', 
							CM.[Amount], --  'CMAmount', 
							CM.[Amount], --  'CreditMemoAmount',
							0,         --  'CreditMemoUsed'			
							CM.MasterCompanyId,
							CM.StatusId,
							1,  -- 'IsCreditMemo'
							0,  -- 'InvoicePaidAmount',
							@STLCMModuleTypeId,  -- 'SalesOrderCreditMemo',
					        LE.[Name],
							0
			 FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
					LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0    
					LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
					LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
					LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId    
					LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId
					LEFT JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId			  
					LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID  
					INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH (NOLOCK) ON ES.Level1Id = MSL.ID
					INNER JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON MSL.LegalEntityId = LE.LegalEntityId  
			WHERE CM.[MasterCompanyId] = @Mastercompanyid      
				AND CM.[IsStandAloneCM] = 1           
				AND CM.[StatusId] = @CMPostedStatusId

				AND CM.[CustomerId] = ISNULL(@CustomerId, CM.CustomerId)
		    --AND CM.[MasterCompanyId] = @Mastercompanyid      
		    --AND CAST(CM.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
			--AND @IsCredits = 1

			IF(@ISDebugMode = 1)
			BEGIN
				SELECT 'CREDIT MEMO'
				SELECT * FROM #TEMPInvoiceRecords
			END

			-- MANUAL JOURNAL --
				
			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],[CurrencyCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],				   
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[ReceivedAmount])	
			SELECT DISTINCT MJH.[ManualJournalHeaderId],
	                        MJD.[ReferenceId],
							UPPER(ISNULL(CST.[Name],'')),
						    UPPER(ISNULL(CST.[CustomerCode],'')),
							CR.Code,
							ISNULL(SUM(MJD.[Debit]),0) - ISNULL(SUM(MJD.[Credit]),0),
							0,
							0,
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.[Code] = 'COD' THEN -1      
								 WHEN ctm.[Code]='CIA' THEN -1      
								 WHEN ctm.[Code]='CreditCard' THEN -1      
								 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS AmountpaidbylessTHEN0days,      
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby30days,      
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby60days,      
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby90days,      
						    (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby120days,      
						    (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidbymorethan120days,
							ISNULL(SUM(MJD.[Debit]),0) - ISNULL(SUM(MJD.[Credit]),0), -- 'InvoiceAmount', 
							0, --  'CMAmount', 
							0, --  'CreditMemoAmount',
							0, --  'CreditMemoUsed'	
							MJH.[MasterCompanyId],
							0,
							0,  -- 'IsCreditMemo'
							0,  -- 'InvoicePaidAmount',
							@MJEModuleTypeId,  -- 'SalesOrderCreditMemo',
							0
			FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)   
				INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.[ManualJournalHeaderId] = MJD.[ManualJournalHeaderId]
				INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.[CustomerId] = MJD.[ReferenceId]
				LEFT JOIN [dbo].[CustomerFinancial] CSF  ON CSF.[CustomerId] = CST.[CustomerId]
				LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CSF.CurrencyId
				INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @MSModuleId AND MSD.[ReferenceID] = MJD.[ManualJournalDetailsId]    
				LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.[EntityStructureId] = MSD.[EntityMSID] 
				LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.[CreditTermsId] = CSF.[CreditTermsId]      
				LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CST.[CustomerTypeId] = CT.[CustomerTypeId] 
			WHERE MJH.[MasterCompanyId] = @Mastercompanyid  
					AND MJH.[ManualJournalStatusId] = @MJEPostStatusId
					AND MJD.[ReferenceTypeId] = 1  
					AND ISNULL(MJH.IsActive, 0) = 1 AND ISNULL(MJH.IsDeleted, 0) = 0
					--AND CAST(MJH.[PostedDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
					--AND MJH.[MasterCompanyId] = @Mastercompanyid  
					--AND @IsCredits = 1
			GROUP BY MJH.[ManualJournalHeaderId],MJD.[ReferenceId],CST.[Name],CST.[CustomerCode],MJH.[JournalNumber], 
					MJH.[PostedDate],CTM.[Name],ctm.[Code],ctm.[NetDays],
					MJH.[MasterCompanyId], CR.Code
				
			-- SUSPENSE AND UNAPPLIED CASH   --

			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],[CurrencyCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],				  
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName],[ReceivedAmount])	
			SELECT DISTINCT CCP.[CustomerCreditPaymentDetailId],
			                C.[CustomerId],     
							UPPER(C.[Name]),
					        UPPER(C.[CustomerCode]),	
							CR.Code,
							CCP.[RemainingAmount],
							0,
							0,
							CCP.[RemainingAmount],
							0,
							0,
							0,
							0,
							0,
							CCP.[RemainingAmount], --  'InvoiceAmount', 
							0, -- 'CMAmount', 
							0, -- 'CreditMemoAmount',
							0, --'CreditMemoUsed'	
							CCP.[MasterCompanyId],
							0,
							1,
							0,  -- 'InvoicePaidAmount',
							@UAModuleTypeId,  -- 'SUSPENSE AND UNAPPLIED CASH',
					        LE.[Name],
							0
			  FROM [dbo].[CustomerCreditPaymentDetail] CCP WITH (NOLOCK)   
				LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CCP.CustomerId = C.CustomerId   
				LEFT JOIN [dbo].[CustomerFinancial] CSF  ON CSF.[CustomerId] = C.[CustomerId]
				LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CSF.CurrencyId
				INNER JOIN [dbo].[SuspenseAndUnAppliedPaymentMSDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SuspenseModuleID AND MSD.ReferenceID = CCP.CustomerCreditPaymentDetailId
				INNER JOIN [dbo].[EntityStructureSetup] ES WITH (NOLOCK)ON ES.EntityStructureId = CCP.ManagementStructureId
				INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH (NOLOCK)ON ES.Level1Id = MSL.ID
				INNER JOIN [dbo].[LegalEntity] LE WITH (NOLOCK)ON MSL.LegalEntityId = LE.LegalEntityId  
			WHERE CCP.[MasterCompanyId] = @MasterCompanyid  
				AND CCP.[StatusId] = @CustomerCreditPaymentOpenStatus	
				AND ISNULL(IsProcessed, 0) = 0 AND ISNULL(CCP.IsActive, 0) = 1 AND ISNULL(CCP.IsDeleted, 0) = 0
				--AND CAST(CCP.[ReceiveDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
				--AND CCP.[MasterCompanyId] = @MasterCompanyid  
				--AND @IsUnappliedAmounts = 1	
				
			--SELECT * FROM #TEMPInvoiceRecords

			SELECT  [CustomerId],
					[CustomerName] AS 'CustName',
					[CustomerCode],
					[CurrencyCode] As 'CurrencyCode',
					ISNULL(SUM([BalanceAmount]),0) [BalanceAmount],
					--CASE WHEN [IsCreditMemo] = 0 THEN ISNULL((ISNULL(SUM([Amountlessthan0days]),0) + ISNULL(SUM([Amountlessthan30days]),0) + ISNULL(SUM([Amountlessthan60days]),0) + ISNULL(SUM([Amountlessthan90days]),0) + ISNULL(SUM([Amountlessthan120days]),0) + ISNULL(SUM([Amountmorethan120days]),0) + ISNULL(SUM([CreditMemoAmount]),0)),0) ELSE CASE WHEN [StatusId] = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(SUM([CreditMemoAmount]),0) END END AS [CurrentAmount], 
					CASE WHEN [IsCreditMemo] = 0 THEN ISNULL((ISNULL(SUM([Amountlessthan0days]),0) + ISNULL(SUM([Amountlessthan30days]),0) + ISNULL(SUM([Amountlessthan60days]),0) + ISNULL(SUM([Amountlessthan90days]),0) + ISNULL(SUM([Amountlessthan120days]),0) + ISNULL(SUM([Amountmorethan120days]),0)),0) ELSE CASE WHEN [StatusId] = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(SUM([CreditMemoAmount]),0) END END AS [CurrentAmount], 
					ISNULL(SUM([PaymentAmount]),0) [PaymentAmount],									   
					ISNULL(SUM([Amountlessthan0days]),0) [Amountpaidbylessthen0days],
					ISNULL(SUM([Amountlessthan30days]),0) [Amountpaidby30days],
					ISNULL(SUM([Amountlessthan60days]),0) [Amountpaidby60days],
					ISNULL(SUM([Amountlessthan90days]),0) [Amountpaidby90days],
					ISNULL(SUM([Amountlessthan120days]),0) [Amountpaidby120days],
					ISNULL(SUM([Amountmorethan120days]),0) [Amountpaidbymorethan120days],
					ISNULL(SUM([InvoiceAmount]),0) [InvoiceAmount],
					ISNULL(SUM([CMAmount]),0) [CMAmount],
					ISNULL(SUM([CreditMemoAmount]),0) [CreditMemoAmount],
					ISNULL(SUM([CreditMemoUsed]),0) [CreditMemoUsed],	
					[LegalEntityName] AS 'LegelEntity',
					ISNULL(SUM([CurrentAmount]),0) AS [ReceivedAmount]
			 INTO #TempResult1 FROM #TEMPInvoiceRecords		
			 WHERE((ISNULL(@CustName,'') ='' OR [CustomerName] LIKE '%' + @CustName+'%') AND
				  (ISNULL(@CustomerCode,'') ='' OR [CustomerCode] LIKE '%' + @CustomerCode + '%') AND					
				  (ISNULL(@BalanceAmount,0) = 0 OR [BalanceAmount] = @BalanceAmount) AND	
				  (ISNULL(@CurrentAmount,0) = 0 OR [CurrentAmount] = @CurrentAmount) AND	
				  --(ISNULL(@ReceivedAmount,0) = 0 OR [ReceivedAmount] = @ReceivedAmount) AND	
				  --(ISNULL(@PaymentAmount,0) = 0 OR [PaymentAmount] = @PaymentAmount) AND
				  (ISNULL(@Amountlessthan0days,0) = 0 OR [Amountlessthan0days] = @Amountlessthan0days) AND
				  (ISNULL(@Amountlessthan30days,0) =0 OR [Amountlessthan30days] = @Amountlessthan30days) AND
				  (ISNULL(@Amountlessthan60days,0) =0 OR [Amountlessthan60days]= @Amountlessthan60days) AND
				  (ISNULL(@Amountlessthan90days,0) =0 OR [Amountlessthan90days]= @Amountlessthan90days) AND
				  (ISNULL(@Amountlessthan120days,0) =0 OR [Amountlessthan120days] = @Amountlessthan120days) AND					
				  (ISNULL(@Amountmorethan120days,0) =0 OR [Amountmorethan120days] = @Amountmorethan120days)) 
				  --(ISNULL(@InvoiceAmount,0) = 0 OR [InvoiceAmount] = @InvoiceAmount)) 
			GROUP BY [CustomerId],[CustomerName],[CustomerCode],[LegalEntityName],[IsCreditMemo],[StatusId],[CurrencyCode]

			--Select * from #TempResult1
				 		
			SELECT @Count = COUNT(CustomerId),
			       @TotalAmount = ISNULL(SUM([InvoiceAmount]),0), 
				   @TotalCurrentAmount = ISNULL(SUM([CurrentAmount]),0),
				   @TotalReceivedAmount = ISNULL(SUM([ReceivedAmount]),0),
				   @TotalAmountlessthan0days = ISNULL(SUM([Amountpaidbylessthen0days]),0),
				   @TotalAmountlessthan30days = ISNULL(SUM([Amountpaidby30days]),0),
				   @TotalAmountlessthan60days = ISNULL(SUM([Amountpaidby60days]),0),
				   @TotalAmountlessthan90days = ISNULL(SUM([Amountpaidby90days]),0),
				   @TotalAmountlessthan120days = ISNULL(SUM([Amountpaidby120days]),0),
				   @TotalAmountmorethan120days = ISNULL(SUM([Amountpaidbymorethan120days]),0) FROM #TempResult1;
				   			
			SELECT *, @Count AS NumberOfItems,
			          @TotalAmount AS TotalAmount,
					  @TotalCurrentAmount AS TotalCurrentAmount,
					  @TotalReceivedAmount AS TotalReceivedAmount,
					  @TotalAmountlessthan0days AS TotalAmountlessthan0days,
					  @TotalAmountlessthan30days AS TotalAmountlessthan30days,
					  @TotalAmountlessthan60days AS TotalAmountlessthan60days,
					  @TotalAmountlessthan90days AS TotalAmountlessthan90days,
					  @TotalAmountlessthan120days AS TotalAmountlessthan120days,
					  @TotalAmountmorethan120days AS TotalAmountmorethan120days  FROM #TempResult1 ORDER BY  	
			CASE WHEN (@SortOrder=1  AND @SortColumn='CUSTOMERNAME') THEN [CustName] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERNAME') THEN [CustName] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CUSTOMERCODE') THEN [CustomerCode] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCODE') THEN [CustomerCode] END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='BALANCEAMOUNT') THEN [BalanceAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='BALANCEAMOUNT') THEN [BalanceAmount] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CURRENTAMOUNT') THEN [CurrentAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CURRENTAMOUNT') THEN [CurrentAmount] END DESC, 		
			CASE WHEN (@SortOrder=1  AND @SortColumn='RECEIVEDAMOUNT') THEN [ReceivedAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RECEIVEDAMOUNT') THEN [ReceivedAmount] END DESC, 		
			CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTAMOUNT') THEN [PaymentAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTAMOUNT') THEN [PaymentAmount] END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN0DAYS') THEN [Amountpaidbylessthen0days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN0DAYS') THEN [Amountpaidbylessthen0days] END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN30DAYS') THEN [Amountpaidby30days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN30DAYS') THEN [Amountpaidby30days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN60DAYS') THEN [Amountpaidby60days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN60DAYS') THEN [Amountpaidby60days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN90DAYS') THEN [Amountpaidby90days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN90DAYS') THEN [Amountpaidby90days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN120DAYS') THEN [Amountpaidby120days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN120DAYS') THEN [Amountpaidby120days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTMORETHAN120DAYS') THEN [Amountpaidbymorethan120days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTMORETHAN120DAYS') THEN [Amountpaidbymorethan120days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='INVOICEAMOUNT') THEN [InvoiceAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='INVOICEAMOUNT') THEN [InvoiceAmount] END DESC,
			
			CASE WHEN (@SortOrder=1  AND @SortColumn='LegalEntityName') THEN [LegelEntity] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LegalEntityName') THEN [LegelEntity] END DESC
			
			OFFSET @RecordFrom ROWS FETCH NEXT @PageSize ROWS ONLY
					   				 
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
        @AdhocComments varchar(150) = '[usprpt_GetARAgingAsOfNowReport]',
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