 /**************************************************************                   
  ** Change History                   
 **************************************************************                   
 ** S NO   Date            Author			Change Description                    
 ** --   --------         -------			--------------------------------                  
    1    13-July-2023	  Ayesha			Credit memo changes     
	2    24-July-2023     Moin Bloch		Added Credit Memo List For SO AND WO AND Format the Stored Procedure
	3    28-July-2023     Moin Bloch		Changed PostedDate to InvoiceDate  
	4    23-Aug--2023     Moin Bloch		Changed Balance Amount (Added Discount Amount +  Bank Fees Amount + Other Adjustment Amount in Balance Amount)
	6    16-OCT-2023      Moin Bloch		Modify(Added Posted Status Insted of Fulfilling Credit Memo Status)
	7    18-OCT-2023      Moin Bloch		Modify(Added Stand Alone Credit Memo)
	8    07-NOV-2023      AMIT GHEDIYA		Modify(Added Add Exchange Invoice)
	9	 31-JAN-2024		Devendra Shekh  added isperforma Flage for WO

**************************************************************/  
--exec GetCustomerInvoiceList @PageNumber=1,@PageSize=10,@SortColumn=N'CustName',@SortOrder=1,@GlobalFilter=N'',@StatusId=2,@CustName='Fast',@CustomerCode=NULL,@CustomertType=NULL,@currencyCode=NULL,@BalanceAmount=NULL,@CurrentlAmount=NULL,@Amountpaidbylessthen0days=NULL,@Amountpaidby30days=NULL,@Amountpaidby60days=NULL,@Amountpaidby90days=NULL,@Amountpaidby120days=NULL,@Amountpaidbymorethan120days=NULL,@LegelEntity=NULL,@EmployeeId=2,@CreatedBy=NULL,@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,@viewType=N'Deatils',@MasterCompanyId=1,@InvoiceDate=NULL,@CustomerRef=NULL,@InvoiceNo=NULL,@DocType=NULL,@Salesperson=NULL,@Terms=NULL,@DueDate=NULL,@FixRateAmount=NULL,@InvoiceAmount=NULL,@InvoicePaidAmount=NULL,@InvoicePaidDate=NULL,@PaymentRef=NULL,@CMAmount=NULL,@CMDate=NULL,@AdjustMentAmount=NULL,@AdjustMentDate=NULL,@SOMSModuleID=17,@WOMSModuleID=12

CREATE   PROCEDURE [dbo].[GetCustomerInvoiceList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@CustName varchar(50) = NULL,
@CustomerCode varchar(50) = NULL,
@CustomertType varchar(50) = NULL,
@currencyCode varchar(50) = NULL,
@BalanceAmount decimal(18,2) = NULL,
@CurrentlAmount decimal(18,2) = NULL,
@Amountpaidbylessthen0days decimal(18,2) = NULL,
@Amountpaidby30days decimal(18,2) = NULL,
@Amountpaidby60days decimal(18,2) = NULL,
@Amountpaidby90days decimal(18,2) = NULL,
@Amountpaidby120days decimal(18,2) = NULL,
@Amountpaidbymorethan120days decimal(18,2) = NULL,
@LegelEntity varchar(50) = NULL,
@EmployeeId bigint = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate DATETIME = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  DATETIME = NULL,
@viewType varchar(50) = NULL,
@MasterCompanyId bigint = NULL,
@InvoiceDate DATETIME = NULL,
@CustomerRef varchar(50) = NULL,
@InvoiceNo varchar(50) = NULL,
@DocType varchar(50) = NULL,
@Salesperson varchar(50) = NULL,
@Terms varchar(50) = NULL,
@DueDate DATETIME = NULL,
@fixRateAmount decimal(18,2) = NULL,
@InvoiceAmount decimal(18,2) = NULL,
@InvoicePaidAmount decimal(18,2) = NULL,
@InvoicePaidDate DATETIME = NULL,
@PaymentRef varchar(50) = NULL,
@CMAmount decimal(18,2) = NULL,
@CMDate DATETIME = NULL,
@AdjustMentAmount decimal(18,2) = NULL,
@AdjustMentDate DATETIME = NULL,
@SOMSModuleID bigint = NULL,
@WOMSModuleID bigint = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
	    DECLARE @adjustString  varchar(500);
		DECLARE @ESOMSModuleID BIGINT;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		DECLARE @CMMSModuleID bigint = 61;
		SELECT @CMMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='CreditMemoHeader';

		SELECT @ESOMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSOHeader';
		
		DECLARE @ClosedCreditMemoStatus bigint
	    SELECT @ClosedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Closed';

		DECLARE @CMPostedStatusId INT
        SELECT @CMPostedStatusId = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';
					

		IF (@viewType='all')
		BEGIN
			SET @viewType = NULL
		END 
		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = UPPER('CustName')
		END 
		ELSE
		BEGIN 
			Set @SortColumn = UPPER(@SortColumn)
		END	
		IF(@StatusId=0)
		BEGIN
			SET @IsActive=0;
		END
		ELSE IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		ELSE
		BEGIN
			SET @IsActive = NULL;
		END

		IF (@viewType = 'Deatils')
		BEGIN	
		 ;WITH CTE AS(
				SELECT DISTINCT (C.CustomerId) AS CustomerId,
                       ((ISNULL(C.[Name],''))) 'CustName' ,
					   ((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       (CT.CustomerTypeName) 'CustomertType' ,
					   (CR.Code) AS  'currencyCode',
					   (wobi.GrandTotal) AS 'BalanceAmount',
					   (wobi.GrandTotal - wobi.RemainingAmount) AS 'CurrentlAmount',             
					   (wobi.RemainingAmount) AS 'PaymentAmount',
					   (wobi.InvoiceNo) AS 'InvoiceNo',
			           (wobi.InvoiceDate) AS 'InvoiceDate',
					   ISNULL(ctm.NetDays,0) AS NetDays,
					   (CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidbylessthen0days,
					   (CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby30days,
					   (CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby60days,
					   (CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby90days,
					   (CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidby120days,
					   (CASE WHEN DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN wobi.RemainingAmount	ELSE 0 END) AS Amountpaidbymorethan120days,
                       (C.UpdatedBy) AS UpdatedBy,
					   (wop.ManagementStructureId) AS ManagementStructureId,
					   'AR-Inv' AS 'DocType',
					   wop.CustomerReference AS 'CustomerRef',
					   ISNULL(emp.FirstName,'Unassigned') AS 'Salesperson',
					   ctm.[Name] AS 'Terms',
					   A.FxRate AS 'FixRateAmount',
					   wobi.GrandTotal AS 'InvoiceAmount',
					   A.InvoicePaidAmount AS 'InvoicePaidAmount',
					   A.InvoicePaidDate AS 'InvoicePaidDate',
					   A.ReceiptNo AS 'PaymentRef',
					   0 AS 'CMAmount',
					   B.CMAmount AS CreditMemoAmount,
					   NULL AS 'CMDate',
					   A.AdjustMentAmount AS 'AdjustMentAmount',
					   A.InvoicePaidDate AS 'AdjustMentDate',
					   ((CASE WHEN A.DiscAmount > 0 THEN 'Discounts , ' ELSE '' END) +
                       (CASE WHEN A.OtherAdjustAmt > 0 THEN 'Other AdjustMents , ' ELSE'' END) +
                       (CASE WHEN A.BankFeeAmount > 0 THEN 'Wire Fee' ELSE '' END)) AS AdjustMentAmountType,
					   0 AS IsCreditMemo,					   
					   0 AS StatusId
			   FROM [dbo].[WorkOrderBillingInvoicing] wobi WITH (NOLOCK) 			  
			   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = wobi.WorkOrderId
			   INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=WO.CustomerId
			    LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId
			    LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = WO.SalesPersonId
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) ON wop.ID = wobii.WorkOrderPartId and wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID AND ISNULL(wobii.IsPerformaInvoice, 0) = 0
		 	   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = wobi.CurrencyId
			   INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID
			    LEFT JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
			   OUTER APPLY
			   (
					SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo',
					       MAX(IPS.CreatedDate) AS 'InvoicePaidDate',   
						   SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
						   SUM(IPS.FxRate)  AS 'FxRate',
						   SUM(ISNULL(IPS.DiscAmount,0) + ISNULL(IPS.OtherAdjustAmt,0) + ISNULL(IPS.BankFeeAmount,0)) AS AdjustMentAmount,
					       MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
						   MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
						   MAX(ISNULL(IPS.BankFeeAmount,0)) AS BankFeeAmount
					FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					WHERE wobi.BillingInvoicingId = IPS.SOBillingInvoicingId and CP.StatusId = 2 AND IPS.InvoiceType = 2 GROUP BY IPS.SOBillingInvoicingId 
		       ) A
			   OUTER APPLY
			   (
					SELECT SUM(CMD.Amount)  AS 'CMAmount'
					FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)
					INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = WO.CustomerId
					WHERE wobii.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=1 AND CM.CustomerId = WO.CustomerId GROUP BY CMD.BillingInvoicingItemId 
		       ) B
			  -- OUTER APPLY
			  -- (
					--SELECT MAX(CM.CreatedDate)  AS 'CMDate'
					--FROM DBO.CreditMemoDetails CMD WITH (NOLOCK)
					--INNER JOIN DBO.CreditMemo CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = WO.CustomerId
					--Where wobii.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=1 AND CM.CustomerId = WO.CustomerId GROUP BY CMD.BillingInvoicingItemId 
		   --    ) D
			  WHERE  wobi.InvoiceStatus = 'Invoiced' and WO.MasterCompanyId = @MasterCompanyId 

			UNION ALL

			SELECT DISTINCT (C.CustomerId) AS CustomerId,
                       ((ISNULL(C.[Name],''))) 'CustName' ,
					   ((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       (CT.CustomerTypeName) 'CustomertType' ,
					   (CR.Code) AS  'currencyCode',
					   (sobi.GrandTotal) AS 'BalanceAmount',
					   (sobi.GrandTotal - sobi.RemainingAmount) AS 'CurrentlAmount',   
					   ISNULL(sobi.RemainingAmount,0) AS 'PaymentAmount',
					   (sobi.InvoiceNo) AS 'InvoiceNo',
			           (sobi.InvoiceDate) AS 'InvoiceDate',
					   ISNULL(ctm.NetDays,0) AS NetDays,
                      (CASE WHEN DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN sobi.RemainingAmount ELSE 0 END) AS AmountpaidbylessTHEN0days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 30 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby30days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 60 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby60days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby90days,
					  (CASE WHEN DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidby120days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN sobi.RemainingAmount	ELSE 0 END) AS Amountpaidbymorethan120days,
                       (C.UpdatedBy) AS UpdatedBy,
					   (SO.ManagementStructureId) AS ManagementStructureId,
					   'AR-Inv' AS 'DocType',
					   sop.CustomerReference AS 'CustomerRef',
					   ISNULL(SO.SalesPersonName,'Unassigned') AS 'Salesperson',
					   ctm.[Name] AS 'Terms',
					   A.FxRate AS 'FixRateAmount',
					   sobi.GrandTotal AS 'InvoiceAmount',
					   A.InvoicePaidAmount AS 'InvoicePaidAmount',
					   A.InvoicePaidDate AS 'InvoicePaidDate',
					   A.ReceiptNo AS 'PaymentRef',
					   0 AS 'CMAmount',
					   B.CMAmount AS CreditMemoAmount,
					   NULL AS 'CMDate',
					   A.AdjustMentAmount AS 'AdjustMentAmount',
					   A.InvoicePaidDate AS 'AdjustMentDate',
					   ((CASE WHEN A.DiscAmount > 0 THEN 'Discounts , ' ELSE '' END) +
                       (CASE WHEN A.OtherAdjustAmt > 0 THEN 'Other AdjustMents , ' ELSE '' END) +
                       (CASE WHEN A.BankFeeAmount > 0 THEN 'Wire Fee' ELSE '' END)) AS AdjustMentAmountType,
					   0 AS IsCreditMemo,					   
					   0 AS StatusId
			   FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK) 
			   INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId
			   INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId
			    LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[SalesOrderPart] sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			   INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId
			   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
			   INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
		 	    LEFT JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) on MSL.ID = MSD.Level1Id
			   OUTER APPLY
			   (
					SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo',
						   MAX(IPS.CreatedDate) AS 'InvoicePaidDate',   
						   SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
						   SUM(IPS.FxRate)  AS 'FxRate',						   
						   SUM(ISNULL(IPS.DiscAmount,0) + ISNULL(IPS.OtherAdjustAmt,0) + ISNULL(IPS.BankFeeAmount,0)) AS AdjustMentAmount,
					       MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
						   MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
						   MAX(ISNULL(IPS.BankFeeAmount,0)) AS BankFeeAmount
					FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					WHERE sobii.SOBillingInvoicingId = IPS.SOBillingInvoicingId AND CP.StatusId = 2 AND IPS.InvoiceType = 1 GROUP BY IPS.SOBillingInvoicingId 
		       ) A
			   OUTER APPLY
			   (
					SELECT SUM(CMD.Amount)  AS 'CMAmount'
					FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)
					INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = SO.CustomerId
					Where sobii.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=0 AND CM.CustomerId = SO.CustomerId GROUP BY CMD.BillingInvoicingItemId 
		       ) B
			  -- OUTER APPLY
			  -- (
					--SELECT MAX(CM.CreatedDate)  AS 'CMDate'
					--FROM DBO.CreditMemoDetails CMD WITH (NOLOCK)
					--INNER JOIN DBO.CreditMemo CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = SO.CustomerId
					--Where sobii.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=0 AND CM.CustomerId = SO.CustomerId GROUP BY CMD.BillingInvoicingItemId 
		   --    ) D
			  WHERE sobi.InvoiceStatus = 'Invoiced'  and SO.MasterCompanyId = @MasterCompanyId  

			  UNION ALL

			 ------------------- WO Credit Memo ----------------------------------------------------------------------------------------------------
			  
				SELECT DISTINCT (C.CustomerId) AS CustomerId,
                       ((ISNULL(C.[Name],''))) 'CustName' ,
					   ((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       (CT.CustomerTypeName) 'CustomertType' ,
					   (CR.Code) AS  'currencyCode',
					   (wobi.GrandTotal) AS 'BalanceAmount',
					   (wobi.GrandTotal - wobi.RemainingAmount) AS 'CurrentlAmount',             
					   (wobi.RemainingAmount) AS 'PaymentAmount',
					   (CM.CreditMemoNumber) AS 'InvoiceNo',
			           (CM.CreatedDate) AS 'InvoiceDate',
					   ISNULL(ctm.NetDays,0) AS NetDays,
					   (CASE WHEN  DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN CMD.Amount ELSE 0 END) AS Amountpaidbylessthen0days,
					   (CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN CMD.Amount ELSE 0 END) AS Amountpaidby30days,
					   (CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN  CMD.Amount ELSE 0 END) AS Amountpaidby60days,
					   (CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN CMD.Amount ELSE 0 END) AS Amountpaidby90days,
					   (CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN  CMD.Amount ELSE 0 END) AS Amountpaidby120days,
					   (CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN CMD.Amount ELSE 0 END) AS Amountpaidbymorethan120days,
                       (CM.UpdatedBy) AS UpdatedBy,
					   (CM.ManagementStructureId) AS ManagementStructureId,
					   'Credit Memo' AS 'DocType',
					   wop.CustomerReference AS 'CustomerRef',
					   ISNULL(emp.FirstName,'Unassigned') AS 'Salesperson',
					   ctm.Name AS 'Terms',
					   A.FxRate AS 'FixRateAmount',
					   --wobi.GrandTotal AS 'InvoiceAmount',
					   CMD.Amount AS 'InvoiceAmount',
					   --A.InvoicePaidAmount AS 'InvoicePaidAmount',
					   0 AS 'InvoicePaidAmount',
					   A.InvoicePaidDate AS 'InvoicePaidDate',
					   'Credit Memo' AS 'PaymentRef',
					   CMD.Amount AS 'CMAmount',
					   CMD.Amount AS CreditMemoAmount,
					   CM.CreatedDate AS 'CMDate',
					   A.AdjustMentAmount AS 'AdjustMentAmount',
					   A.InvoicePaidDate AS 'AdjustMentDate',					   
                      ((CASE WHEN A.DiscAmount > 0 THEN 'Discounts , ' ELSE '' END) +
                       (CASE WHEN A.OtherAdjustAmt > 0 THEN 'Other AdjustMents , ' ELSE '' END) +
                       (CASE WHEN A.BankFeeAmount > 0 THEN 'Wire Fee' ELSE '' END)) AS AdjustMentAmountType,
					   1 AS IsCreditMemo,					   
					   CM.StatusId
			   FROM  [dbo].[CreditMemo] CM WITH (NOLOCK) 	
			   INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId			   
			   INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH (NOLOCK) ON CMD.InvoiceId = wobi.BillingInvoicingId		 			  
			   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = wobi.WorkOrderId
			   INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=WO.CustomerId
			    LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId
			    LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = WO.SalesPersonId
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) ON wop.ID = wobii.WorkOrderPartId and wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID
		 	   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = wobi.CurrencyId
			   --INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId
			   -- LEFT JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
			    OUTER APPLY
			   (
					SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo'
					      ,MAX(IPS.CreatedDate) AS 'InvoicePaidDate'
						  ,SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount'
						  ,SUM(IPS.FxRate)  AS 'FxRate'						  
						  ,SUM(ISNULL(IPS.DiscAmount,0) + ISNULL(IPS.OtherAdjustAmt,0) + ISNULL(IPS.BankFeeAmount,0)) AS AdjustMentAmount
					      ,MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount 
					      ,MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt 
						  ,MAX(ISNULL(IPS.BankFeeAmount,0)) AS BankFeeAmount
					FROM dbo.InvoicePayments IPS WITH (NOLOCK)
					LEFT JOIN dbo.CustomerPayments CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					WHERE wobi.BillingInvoicingId = IPS.SOBillingInvoicingId AND CP.StatusId = 2 AND IPS.InvoiceType = 2 GROUP BY IPS.SOBillingInvoicingId 
		       ) A			   
			  WHERE CM.StatusId = @CMPostedStatusId 
			  AND  CMD.IsWorkOrder = 1 
			  --AND wobi.InvoiceStatus = 'Invoiced' 
			  AND CM.MasterCompanyId = @MasterCompanyId 

			  UNION ALL

	------------------- SO Credit Memo ----------------------------------------------------------------------------------------------------

			SELECT DISTINCT (C.CustomerId) AS CustomerId,
                       ((ISNULL(C.[Name],''))) 'CustName' ,
					   ((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       (CT.CustomerTypeName) 'CustomertType' ,
					   (CR.Code) AS  'currencyCode',
					   (sobi.GrandTotal) AS 'BalanceAmount',
					   (sobi.GrandTotal - sobi.RemainingAmount)AS 'CurrentlAmount',   
					   ISNULL(sobi.RemainingAmount,0)AS 'PaymentAmount',
					   (CM.CreditMemoNumber) AS 'InvoiceNo',
			           (CM.CreatedDate) AS 'InvoiceDate',
					   ISNULL(ctm.NetDays,0) AS NetDays,
                      (CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN CMD.Amount ELSE 0 END) AS AmountpaidbylessTHEN0days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 30 THEN CMD.Amount ELSE 0 END) AS Amountpaidby30days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 60 THEN CMD.Amount ELSE 0 END) AS Amountpaidby60days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN CMD.Amount ELSE 0 END) AS Amountpaidby90days,
					  (CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN CMD.Amount ELSE 0 END) AS Amountpaidby120days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(CM.CreatedDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN CMD.Amount ELSE 0 END) AS Amountpaidbymorethan120days,
                       (CM.UpdatedBy) AS UpdatedBy,
					   (CM.ManagementStructureId) AS ManagementStructureId,
					   'Credit Memo' AS 'DocType',
					   sop.CustomerReference AS 'CustomerRef',
					   ISNULL(SO.SalesPersonName,'Unassigned') AS 'Salesperson',
					   ctm.Name AS 'Terms',
					   A.FxRate AS 'FixRateAmount',
					   --sobi.GrandTotal AS 'InvoiceAmount',
					   CMD.Amount AS 'InvoiceAmount',
					   --A.InvoicePaidAmount AS 'InvoicePaidAmount',
					   0 AS 'InvoicePaidAmount',
					   A.InvoicePaidDate AS 'InvoicePaidDate',					  
					   'Credit Memo' AS 'PaymentRef',
					   CMD.Amount AS 'CMAmount',
					   CMD.Amount AS CreditMemoAmount,
					   CM.CreatedDate AS 'CMDate',
					   A.AdjustMentAmount AS 'AdjustMentAmount',
					   A.InvoicePaidDate AS 'AdjustMentDate',
					  ((CASE WHEN A.DiscAmount > 0 THEN 'Discounts , ' ELSE '' END) +
                      (CASE WHEN A.OtherAdjustAmt > 0 THEN 'Other AdjustMents , ' ELSE '' END) +
                      (CASE WHEN A.BankFeeAmount > 0 THEN 'Wire Fee' ELSE '' END)) AS AdjustMentAmountType,
					  1 AS IsCreditMemo,					  
					  CM.StatusId
			    FROM  [dbo].[CreditMemo] CM WITH (NOLOCK) 	
			   INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId	
			   INNER JOIN [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK) ON CMD.InvoiceId = sobi.SOBillingInvoicingId 
			   INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId
			   INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId
			    LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[SalesOrderPart] sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			   INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] sobii WITH (NOLOCK) ON sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId
			   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = sobi.CurrencyId			  		 	  
			   --INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId			  
			   -- LEFT JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
			   			   			  
			  OUTER APPLY
			   (
					SELECT MAX(CP.ReceiptNo) AS 'ReceiptNo',
					       MAX(IPS.CreatedDate) AS 'InvoicePaidDate',   
						   SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
						   SUM(IPS.FxRate)  AS 'FxRate',						   
						   SUM(ISNULL(IPS.DiscAmount, 0) + ISNULL(IPS.OtherAdjustAmt, 0) + ISNULL(IPS.BankFeeAmount, 0)) AS AdjustMentAmount,
					       MAX(ISNULL(IPS.DiscAmount, 0)) AS DiscAmount , 
						   MAX(ISNULL(IPS.OtherAdjustAmt, 0)) AS OtherAdjustAmt , 
						   MAX(ISNULL(IPS.BankFeeAmount, 0)) AS BankFeeAmount
					FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					WHERE sobii.SOBillingInvoicingId = IPS.SOBillingInvoicingId AND CP.StatusId=2 AND IPS.InvoiceType = 1 GROUP BY IPS.SOBillingInvoicingId 
		       ) A			  
			  WHERE CM.StatusId = @CMPostedStatusId 
			  AND  CMD.IsWorkOrder = 0  
			  --AND sobi.InvoiceStatus = 'Invoiced'  
			  AND CM.MasterCompanyId = @MasterCompanyId  

			------------------- Stand Alone Credit Memo ----------------------------------------------------------------------------------------------------

			UNION ALL

			SELECT DISTINCT (C.CustomerId) AS CustomerId,
			        UPPER(ISNULL(C.[Name],'')) 'CustName' ,      
                    UPPER(ISNULL(C.CustomerCode,'')) 'CustomerCode' ,      
                    UPPER(CT.CustomerTypeName) 'CustomertType' ,      
					UPPER(CR.Code) AS  'currencyCode', 
					CM.Amount AS 'BalanceAmount',    
					CM.Amount AS 'CurrentlAmount',     
					CM.Amount AS 'PaymentAmount', 
					UPPER(CM.CreditMemoNumber) AS 'InvoiceNo',
					CM.InvoiceDate AS InvoiceDate,  
					ISNULL(CTM.NetDays,0) AS NetDays,  
					(CASE WHEN DATEDIFF(DAY, CAST(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
							 WHEN ctm.Code='CIA' THEN -1
							 WHEN ctm.Code='CreditCard' THEN -1
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(CTM.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN CM.Amount ELSE 0 END) AS AmountpaidbylessTHEN0days,
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN CM.Amount ELSE 0 END) AS Amountpaidby30days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN CM.Amount ELSE 0 END) AS Amountpaidby60days,      
				    (CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN CM.Amount ELSE 0 END) AS Amountpaidby90days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN CM.Amount ELSE 0 END) AS Amountpaidby120days,      
					(CASE WHEN DATEDIFF(DAY, CASt(CAST(CM.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
							 WHEN ctm.Code='CIA' THEN -1      
							 WHEN ctm.Code='CreditCard' THEN -1      
							 WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN CM.Amount ELSE 0 END) AS Amountpaidbymorethan120days,      
                    (CM.UpdatedBy) AS UpdatedBy,
					(CM.ManagementStructureId) AS ManagementStructureId,
					UPPER('Stand Alone Credit Memo') AS 'DocType',    
					'' AS 'CustomerRef',      
				    '' AS 'Salesperson',   						
					UPPER(CTM.[Name]) AS 'Terms',  
					'0' AS 'FixRateAmount',    
					CM.Amount AS 'InvoiceAmount', 
					0 AS 'InvoicePaidAmount',
					NULL AS 'InvoicePaidDate',	
					'Stand Alone Credit Memo' AS 'PaymentRef',
					CM.Amount AS 'CMAmount', 
				    CM.Amount AS CreditMemoAmount,
					CM.CreatedDate AS 'CMDate',
					0 AS 'AdjustMentAmount',
					NULL AS 'AdjustMentDate',
				    '' AS 'AdjustMentAmountType',
					1 AS IsCreditMemo,					  
					CM.StatusId
			FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
			LEFT JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0    
			LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0    
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId    
		    LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId  
			LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId
		   --INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId			  
			--LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID  
		  WHERE CM.MasterCompanyId = @MasterCompanyId
		    AND CM.IsStandAloneCM = 1           
		    AND CM.StatusId = @CMPostedStatusId

		------------------- SO Exchange Invoice ----------------------------------------------------------------------------------------------------

			UNION ALL

			SELECT DISTINCT (CUST.CustomerId) AS CustomerId,
                       ((ISNULL(CUST.[Name],''))) 'CustName' ,
					   ((ISNULL(CUST.CustomerCode,''))) 'CustomerCode' ,
                       (CT.CustomerTypeName) 'CustomertType' ,
					   (CR.Code) AS  'currencyCode',
					   (ESOBI.GrandTotal) AS 'BalanceAmount',
					   (ESOBI.GrandTotal - ESOBI.RemainingAmount) AS 'CurrentlAmount',   
					   ISNULL(ESOBI.RemainingAmount,0) AS 'PaymentAmount',
					   (ESOBI.InvoiceNo) AS 'InvoiceNo',
			           (ESOBI.InvoiceDate) AS 'InvoiceDate',
					   ISNULL(ctm.NetDays,0) AS NetDays,
                      (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN ESOBI.RemainingAmount ELSE 0 END) AS AmountpaidbylessTHEN0days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(ESOBI.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 30 THEN ESOBI.RemainingAmount ELSE 0 END) AS Amountpaidby30days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(ESOBI.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 60 THEN ESOBI.RemainingAmount ELSE 0 END) AS Amountpaidby60days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(ESOBI.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN ESOBI.RemainingAmount ELSE 0 END) AS Amountpaidby90days,
					  (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(ESOBI.InvoiceDate AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN ESOBI.RemainingAmount ELSE 0 END) AS Amountpaidby120days,
					  (CASE	WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN ESOBI.RemainingAmount	ELSE 0 END) AS Amountpaidbymorethan120days,
                       (CUST.UpdatedBy) AS UpdatedBy,
					   (ESO.ManagementStructureId) AS ManagementStructureId,
					   UPPER('Exchange Invoice') AS 'DocType',
					   ESO.CustomerReference AS 'CustomerRef',
					   ISNULL(ESO.SalesPersonName,'Unassigned') AS 'Salesperson',
					   CTM.[Name] AS 'Terms',
					   0 AS 'FixRateAmount',
					   ESOBI.GrandTotal AS 'InvoiceAmount',
					   0 AS 'InvoicePaidAmount',
					   NULL AS 'InvoicePaidDate',
					   'Exchange Invoice' AS 'PaymentRef',
					   0 AS 'CMAmount',
					   0 AS CreditMemoAmount,
					   NULL AS 'CMDate',
					   0 AS 'AdjustMentAmount',
					   NULL 'AdjustMentDate',
					   '' AS AdjustMentAmountType,
					   0 AS IsCreditMemo,					   
					   0 AS StatusId
			FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK)       
			INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.ExchangeSalesOrderId = ESOBI.ExchangeSalesOrderId      
			INNER JOIN [dbo].[Customer] CUST WITH (NOLOCK) ON CUST.CustomerId = ESO.CustomerId      
			LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = ESO.CreditTermId      
			INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CUST.CustomerTypeId = CT.CustomerTypeId      
			INNER JOIN [dbo].[ExchangeSalesOrderPart] ESOP WITH (NOLOCK) ON ESOP.ExchangeSalesOrderId = ESOP.ExchangeSalesOrderId      
			INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] ESOBII WITH (NOLOCK) ON ESOBII.SOBillingInvoicingId = ESOBI.SOBillingInvoicingId AND ESOBII.ExchangeSalesOrderPartId = ESOP.ExchangeSalesOrderPartId      
			INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = ESOBI.CurrencyId      
			INNER JOIN [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId      
			LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
		    WHERE ESOBI.InvoiceStatus = 'Invoiced'  and ESO.MasterCompanyId = @MasterCompanyId 
		)
			
			, Result AS(
				SELECT DISTINCT 
				       (CTE.CustomerId) AS CustomerId ,
                       ((ISNULL(CTE.CustName,''))) 'CustName' ,
					   ((ISNULL(CTE.CustomerCode,''))) 'CustomerCode' ,
                       (CTE.CustomertType) 'CustomertType' ,
					   (CTE.currencyCode) AS  'currencyCode',
					   --CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL((CTE.PaymentAmount + ISNULL(CTE.CreditMemoAmount,0)),0) ELSE ISNULL(CTE.CreditMemoAmount,0) END AS 'BalanceAmount',
					   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL((CTE.InvoiceAmount - ISNULL(CTE.InvoicePaidAmount,0)),0) - ISNULL(AdjustMentAmount,0) 
					        ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus  THEN 0 ELSE ISNULL(CTE.CreditMemoAmount,0) END END AS 'BalanceAmount',					   					   
					   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL((CTE.Amountpaidbylessthen0days + ISNULL(CTE.CreditMemoAmount,0)),0) ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus  THEN 0 ELSE ISNULL(CTE.CreditMemoAmount,0) END END AS 'CurrentlAmount',   
					   ISNULL(CTE.PaymentAmount,0) AS 'PaymentAmount',
					   (CTE.InvoiceNo) AS 'InvoiceNo',
			           (CTE.InvoiceDate) AS 'InvoiceDate',
					   --CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN  (CTE.Amountpaidbylessthen0days + ISNULL(CTE.CreditMemoAmount,0)) ELSE (CTE.Amountpaidbylessthen0days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbylessthen0days) END,0) END AS 'Amountpaidbylessthen0days',   
					   --CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN (CTE.Amountpaidby30days + ISNULL(CTE.CreditMemoAmount,0)) ELSE (CTE.Amountpaidby30days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby30days) END,0)  END  AS 'Amountpaidby30days',      
                       --CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN (CTE.Amountpaidby60days + ISNULL(CTE.CreditMemoAmount,0)) ELSE (CTE.Amountpaidby60days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby60days) END,0) END AS 'Amountpaidby60days',
					   --CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN (CTE.Amountpaidby90days + ISNULL(CTE.CreditMemoAmount,0)) ELSE (CTE.Amountpaidby90days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby90days) END,0) END AS 'Amountpaidby90days',
					   --CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN  (CTE.Amountpaidby120days + ISNULL(CTE.CreditMemoAmount,0)) ELSE (CTE.Amountpaidby120days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby120days) END,0) END AS 'Amountpaidby120days',
					   --CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN  (CTE.Amountpaidbymorethan120days + ISNULL(CTE.CreditMemoAmount,0)) ELSE (CTE.Amountpaidbymorethan120days) END,0) ELSE ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbymorethan120days) END,0) END AS 'Amountpaidbymorethan120days',  
					   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN CTE.Amountpaidbylessthen0days ELSE CTE.Amountpaidbylessthen0days END,0) 
					        ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidbylessthen0days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbylessthen0days) END,0) END END AS 'Amountpaidbylessthen0days',   							
					   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN CTE.Amountpaidby30days ELSE (CTE.Amountpaidby30days) END,0) 
							ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidby30days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby30days) END,0)  END END AS 'Amountpaidby30days',                            					  
					  CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN CTE.Amountpaidby60days ELSE (CTE.Amountpaidby60days) END,0) 
							ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidby60days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby60days) END,0) END END AS 'Amountpaidby60days',
					   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN CTE.Amountpaidby90days ELSE (CTE.Amountpaidby90days) END,0)
					        ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidby90days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby90days) END,0) END END AS 'Amountpaidby90days',
					   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN  (CTE.Amountpaidby120days) ELSE (CTE.Amountpaidby120days) END,0) 
					        ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidby120days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidby120days) END,0) END END AS 'Amountpaidby120days',
					   CASE WHEN CTE.IsCreditMemo = 0 THEN ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN  (CTE.Amountpaidbymorethan120days) ELSE (CTE.Amountpaidbymorethan120days) END,0) 
					        ELSE CASE WHEN CTE.StatusId = @ClosedCreditMemoStatus THEN 0 ELSE ISNULL(CASE WHEN CTE.Amountpaidbymorethan120days > 0 THEN ISNULL(CTE.CreditMemoAmount,0) ELSE (CTE.Amountpaidbymorethan120days) END,0) END END AS 'Amountpaidbymorethan120days',  
					   (C.CreatedDate) AS CreatedDate,
                       (C.UpdatedDate) AS UpdatedDate,
					   (C.CreatedBy) AS CreatedBy,
                       (C.UpdatedBy) AS UpdatedBy,
					   (CTE.ManagementStructureId) AS ManagementStructureId,
					   CTE.DocType AS DocType,
					   CTE.CustomerRef AS 'CustomerRef',
					   CTE.Salesperson AS 'Salesperson',
					   CTE.Terms AS 'Terms',
					   DATEADD(day, CTE.NetDays,CTE.InvoiceDate) AS 'DueDate',
					   ISNULL(CTE.FixRateAmount,0) AS 'FixRateAmount',
					   ISNULL(CTE.InvoiceAmount,0) AS 'InvoiceAmount',
					   ISNULL(CTE.InvoicePaidAmount,0) AS 'InvoicePaidAmount',
					   CTE.InvoicePaidDate AS 'InvoicePaidDate',
					   CTE.PaymentRef AS 'PaymentRef',
					   ISNULL(CTE.CMAmount,0) AS 'CMAmount',
					   CTE.CMDate AS 'CMDate',
					   ISNULL(CTE.AdjustMentAmount,0) AS 'AdjustMentAmount',
					   CTE.AdjustMentDate AS 'AdjustMentDate',
					   CTE.AdjustMentAmountType AS 'AdjustMentAmountType'
			   FROM CTE AS CTE WITH (NOLOCK) 
			   INNER JOIN [dbo].[Customer] AS c WITH (NOLOCK) ON c.CustomerId = CTE.CustomerId 
			   WHERe C.MasterCompanyId = @MasterCompanyId
			   
			) , ResultCount AS(SELECT COUNT(CustomerId) AS totalItems FROM Result)

			SELECT * INTO #TempResult1 FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((CustName LIKE '%' +@GlobalFilter+'%') OR
			        (CustomerCode LIKE '%' +@GlobalFilter+'%') OR	
					(CustomertType LIKE '%' +@GlobalFilter+'%') OR					
					(currencyCode LIKE '%' +@GlobalFilter+'%') OR						
				    (CAST(BalanceAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR						
					(CAST(CurrentlAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(PaymentAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Amountpaidbylessthen0days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Amountpaidby30days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Amountpaidby60days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Amountpaidby90days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Amountpaidby120days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR					
					(CAST(Amountpaidbymorethan120days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(InvoiceNo LIKE '%' +@GlobalFilter+'%') OR	
					(DocType LIKE '%' +@GlobalFilter+'%') OR	
					(CustomerRef LIKE '%' +@GlobalFilter+'%') OR					
					(Salesperson LIKE '%' +@GlobalFilter+'%') OR
					(Terms LIKE '%' +@GlobalFilter+'%') OR	
					(PaymentRef LIKE '%' +@GlobalFilter+'%') OR					
					(CAST(FixRateAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(InvoiceAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(InvoicePaidAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(CMAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(AdjustMentAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR	
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	

					OR   

					(@GlobalFilter='' AND (ISNULL(@CustName,'') ='' OR CustName LIKE '%' + @CustName+'%') AND
					(ISNULL(@CustomerCode,'') ='' OR CustomerCode LIKE '%' + @CustomerCode + '%') AND
					(ISNULL(@CustomertType,'') ='' OR CustomertType LIKE '%' + @CustomertType + '%') AND
					(ISNULL(@currencyCode,'') ='' OR currencyCode LIKE '%' + @currencyCode + '%') AND
				    (ISNULL(@BalanceAmount,0) =0 OR BalanceAmount= @BalanceAmount) AND
				    (ISNULL(@CurrentlAmount,0) =0 OR CurrentlAmount =@CurrentlAmount) AND			
					(ISNULL(@Amountpaidbylessthen0days,0) =0 OR Amountpaidbylessthen0days = @Amountpaidbylessthen0days) AND
					(ISNULL(@Amountpaidby30days,0) =0 OR Amountpaidby30days = @Amountpaidby30days) AND
					(ISNULL(@Amountpaidby60days,0) =0 OR Amountpaidby60days= @Amountpaidby60days) AND
					(ISNULL(@Amountpaidby90days,0) =0 OR Amountpaidby90days= @Amountpaidby90days) AND
					(ISNULL(@Amountpaidby120days,0) =0 OR Amountpaidby120days = @Amountpaidby120days) AND					
					(ISNULL(@Amountpaidbymorethan120days,0) =0 OR Amountpaidbymorethan120days = @Amountpaidbymorethan120days) AND
					
					(ISNULL(@InvoiceNo,'') ='' OR InvoiceNo LIKE '%' + @InvoiceNo + '%') AND
					(ISNULL(@DocType,'') ='' OR DocType LIKE '%' + @DocType + '%') AND
					(ISNULL(@CustomerRef,'') ='' OR CustomerRef LIKE '%' + @CustomerRef + '%') AND
					(ISNULL(@Salesperson,'') ='' OR Salesperson LIKE '%' + @Salesperson + '%') AND
					(ISNULL(@Terms,'') ='' OR Terms LIKE '%' + @Terms + '%') AND
					(ISNULL(@PaymentRef,'') ='' OR PaymentRef LIKE '%' + @PaymentRef + '%') AND
					(ISNULL(@FixRateAmount,0) =0 OR FixRateAmount = @FixRateAmount) AND
					(ISNULL(@InvoiceAmount,0) =0 OR InvoiceAmount = @InvoiceAmount) AND
					(ISNULL(@InvoicePaidAmount,0) =0 OR InvoicePaidAmount= @InvoicePaidAmount) AND
					(ISNULL(@CMAmount,0) =0 OR CMAmount= @CMAmount) AND
					(ISNULL(@AdjustMentAmount,0) =0 OR AdjustMentAmount = @AdjustMentAmount) AND					
					(ISNULL(@DueDate,'') ='' OR CAST(DueDate AS DATE)=CAST(@DueDate AS DATE)) AND
					(ISNULL(@InvoicePaidDate,'') ='' OR CAST(InvoicePaidDate AS DATE)=CAST(@InvoicePaidDate AS DATE)) AND
					(ISNULL(@CMDate,'') ='' OR CAST(CMDate AS DATE)=CAST(@CMDate AS DATE)) AND
					(ISNULL(@InvoiceDate,'') ='' OR CAST(InvoiceDate AS DATE)=CAST(@InvoiceDate AS DATE)) AND
					(ISNULL(@AdjustMentDate,'') ='' OR CAST(AdjustMentDate AS DATE)=CAST(@AdjustMentDate AS DATE)) AND
					
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE)=CAST(@CreatedDate AS DATE)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE)=CAST(@UpdatedDate AS DATE)))
				   )

		  SELECT @Count = COUNT(CustomerId) FROM #TempResult1			

		  SELECT *, @Count AS NumberOfItems FROM #TempResult1 ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustName')  THEN [CustName] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustName')  THEN [CustName] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerCode')  THEN CustomerCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerCode')  THEN CustomerCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomertType')  THEN CustomertType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomertType')  THEN CustomertType END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='currencyCode')  THEN currencyCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='currencyCode')  THEN currencyCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='BalanceAmount')  THEN BalanceAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='BalanceAmount')  THEN BalanceAmount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CurrentlAmount')  THEN CurrentlAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CurrentlAmount')  THEN CurrentlAmount END DESC, 			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidbylessthen0days')  THEN Amountpaidbylessthen0days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidbylessthen0days')  THEN Amountpaidbylessthen0days END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby30days')  THEN Amountpaidby30days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby30days')  THEN Amountpaidby30days END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby60days')  THEN Amountpaidby60days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby60days')  THEN Amountpaidby60days END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby90days')  THEN Amountpaidby90days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby90days')  THEN Amountpaidby90days END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby120days')  THEN Amountpaidby120days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby120days')  THEN Amountpaidby120days END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidbymorethan120days')  THEN Amountpaidbymorethan120days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidbymorethan120days')  THEN Amountpaidbymorethan120days END DESC,
			

			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceNo')  THEN InvoiceNo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceNo')  THEN InvoiceNo END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='DocType')  THEN DocType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DocType')  THEN DocType END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerRef')  THEN CustomerRef END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerRef')  THEN CustomerRef END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Salesperson')  THEN Salesperson END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Salesperson')  THEN Salesperson END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Terms')  THEN Terms END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Terms')  THEN Terms END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PaymentRef')  THEN PaymentRef END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PaymentRef')  THEN PaymentRef END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='FixRateAmount')  THEN FixRateAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='FixRateAmount')  THEN FixRateAmount END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceAmount')  THEN InvoiceAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceAmount')  THEN InvoiceAmount END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoicePaidAmount')  THEN InvoicePaidAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoicePaidAmount')  THEN InvoicePaidAmount END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='CMAmount')  THEN CMAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CMAmount')  THEN CMAmount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AdjustMentAmount')  THEN AdjustMentAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AdjustMentAmount')  THEN AdjustMentAmount END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='DueDate')  THEN DueDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DueDate')  THEN DueDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoicePaidDate')  THEN InvoicePaidDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoicePaidDate')  THEN InvoicePaidDate END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='CMDate')  THEN CMDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CMDate')  THEN CMDate END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AdjustMentDate')  THEN AdjustMentDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AdjustMentDate')  THEN AdjustMentDate END DESC,

			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC			
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY

		END
		ELSE
		BEGIN

		;WITH CTEData AS(
			SELECT C.CustomerId,CAST(sobi.InvoiceDate AS DATE) AS InvoiceDate,
			sobi.GrandTotal,
			sobi.RemainingAmount,
			DATEDIFF(DAY, CAST(sobi.InvoiceDate AS DATE), GETUTCDATE()) AS dayDiff,
			ctm.NetDays,
			DATEDIFF(DAY, CAST(CAST(sobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) AS CreditRemainingDays
			FROM [dbo].[Customer] C WITH (NOLOCK) 
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
			   INNER JOIN [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK) on sobi.SalesOrderId = so.SalesOrderId
			   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
		 	    LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId
			    WHERE  C.MasterCompanyId=@MasterCompanyId AND sobi.InvoiceStatus = 'Invoiced'

			UNION ALL
			
			SELECT C.CustomerId,CAST(wobi.InvoiceDate AS DATE) AS InvoiceDate,
			wobi.GrandTotal,
			wobi.RemainingAmount,
			DATEDIFF(DAY, CAST(wobi.InvoiceDate AS DATE), GETUTCDATE()) AS dayDiff,
			ctm.NetDays,
			DATEDIFF(DAY, CAST(CAST(wobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) AS CreditRemainingDays
			FROM [dbo].[Customer] C WITH (NOLOCK) 
			   INNER JOIN dbo.[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[WorkOrder] WO WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			   LEFT JOIN  dbo.[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = WO.CreditTermId
			   INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN dbo.[WorkOrderBillingInvoicing] wobi WITH(NOLOCK) ON wobi.IsVersionIncrease=0 AND wobi.WorkOrderId=WO.WorkOrderId  AND ISNULL(wobi.IsPerformaInvoice, 0) = 0
		 	   INNER JOIN dbo.[Currency] CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			   INNER JOIN dbo.[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID
			   WHERE  C.MasterCompanyId=@MasterCompanyId AND wobi.InvoiceStatus = 'Invoiced'
			
			--group by wobi.InvoiceDate,ct.CustomerId,wobi.GrandTotal,wobi.RemainingAmount,ctm.NetDays,PostedDate
			
		------------------- SO Exchange Invoice ----------------------------------------------------------------------------------------------------
			UNION ALL

			SELECT C.CustomerId,CAST(esobi.InvoiceDate AS DATE) AS InvoiceDate,
			esobi.GrandTotal,
			esobi.RemainingAmount,
			DATEDIFF(DAY, CAST(esobi.InvoiceDate AS DATE), GETUTCDATE()) AS dayDiff,
			ctm.NetDays,
			DATEDIFF(DAY, CAST(CAST(esobi.InvoiceDate AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) AS CreditRemainingDays
			FROM [dbo].[Customer] C WITH (NOLOCK) 
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.CustomerId = C.CustomerId
			   INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] esobi WITH (NOLOCK) on esobi.ExchangeSalesOrderId = ESO.ExchangeSalesOrderId
			   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = esobi.CurrencyId
		 	    LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = ESO.CreditTermId
			    WHERE  C.MasterCompanyId=@MasterCompanyId AND esobi.InvoiceStatus = 'Invoiced'

			), CTECalculation AS(
			SELECT
				CustomerId,
				SUM (CASE
			    WHEN CreditRemainingDays < 0 THEN RemainingAmount
			    ELSE 0
			  END) AS paidbylessthen0days,
			   SUM (CASE
			    WHEN CreditRemainingDays > 0 AND CreditRemainingDays <= 30 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby30days,
			  SUM (CASE
			    WHEN CreditRemainingDays > 30 AND CreditRemainingDays <= 60 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby60days,
			   SUM (CASE
			    WHEN CreditRemainingDays > 60 AND CreditRemainingDays <= 90 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby90days,
			  SUM (CASE
			    WHEN CreditRemainingDays > 90 AND CreditRemainingDays <= 120 THEN RemainingAmount
			    ELSE 0
			  END) AS paidby120days,
			  SUM (CASE
			    WHEN CreditRemainingDays > 120 THEN RemainingAmount
			    ELSE 0
			  END) AS paidbymorethan120days
			    FROM CTEData c GROUP BY CustomerId
			),
			
		   CTE AS(
					SELECT DISTINCT C.CustomerId,
                       MAX((ISNULL(C.[Name],''))) 'CustName' ,
					   MAX((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       MAX(CT.CustomerTypeName) 'CustomertType' ,
					   MAX(CR.Code) AS  'currencyCode',
					   SUM(wobi.GrandTotal) AS 'BalanceAmount',
					   ISNULL(SUM(wobi.GrandTotal - wobi.RemainingAmount),0)AS 'CurrentlAmount',   
					   SUM(wobi.RemainingAmount)AS 'RemainingAmount',
					   SUM(0) AS 'Amountpaidbylessthen0days',      
                       SUM(0) AS 'Amountpaidby30days',      
                       SUM(0) AS 'Amountpaidby60days',
					   SUM(0) AS 'Amountpaidby90days',
					   SUM(0) AS 'Amountpaidby120days',
					   SUM(0) AS 'Amountpaidbymorethan120days',  
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) AS CreatedBy,
                       MAX(C.UpdatedBy) AS UpdatedBy,
					   MAX(wop.ManagementStructureId) AS ManagementStructureId,
					   MAX(wo.CreditTerms) AS 'Terms',
					   SUM(wobi.GrandTotal) AS 'InvoiceAmount',
					   MAX(A.InvoicePaidAmount) AS 'InvoicePaidAmount',
					   MAX(A.FxRate) AS 'FixRateAmount',
					   MAX(AB.InvoicePaidDate) AS 'InvoicePaidDate',
					   MAX(A.AdjustMentAmount) AS 'AdjustMentAmount',
					   MAX(ctm.NetDays) AS TermDays,
					   MAX(B.InvoiceNo) AS 'InvoiceNo',
					   MAX(wobi.InvoiceDate) AS 'PostedDate',
					   MAX(E.InvoiceDateNew) AS 'InvoiceDate',
					   MAX(D.CustomerReference) AS CustomerRef,
					   MAX(AA.ReceiptNo) AS 'ReceiptNo',
					   MAX(EMP.FirstName +' '+EMP.LastName) AS 'SalesPerson',
					   COUNT(wobi.BillingInvoicingId) AS 'InvoiceCount',
					   MAX(A.PaymentCount) AS 'PaymentCount',
					   MAX(
                      (CASE WHEN A.DiscAmount > 0 THEN 'Discounts , ' ELSE '' END) +
                      (CASE WHEN A.OtherAdjustAmt > 0 THEN 'Other AdjustMents , ' ELSE '' END) +
                      (CASE WHEN A.BankFeeAmount > 0 THEN 'Wire Fee' ELSE '' END)) AS AdjustMentAmountType
			   FROM [dbo].[Customer] C WITH (NOLOCK) 
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			    LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = WO.CreditTermId
			   INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN [dbo].[WorkOrderWorkFlow] F WITH (NOLOCK) ON F.WorkOrderPartNoId = wop.ID
			   INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK) on wobi.IsVersionIncrease=0 AND wobi.WorkFlowWorkOrderId=F.WorkFlowWorkOrderId AND ISNULL(wobi.IsPerformaInvoice, 0) = 0
		 	   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			    LEFT JOIN [dbo].[Employee] EMP WITH(NOLOCK) ON EMP.EmployeeId = WO.SalesPersonId 
			   INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID
			   OUTER APPLY
			   (
					SELECT COUNT(IPS.ReceiptId) AS PaymentCount,
					       SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
						   SUM(IPS.FxRate)  AS 'FxRate',
						   SUM(ISNULL(IPS.DiscAmount,0) + ISNULL(IPS.OtherAdjustAmt,0) + ISNULL(IPS.BankFeeAmount,0)) AS AdjustMentAmount,
					       MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
						   MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
						   MAX(ISNULL(IPS.BankFeeAmount,0)) AS BankFeeAmount
					FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					WHERE C.CustomerId = IPS.CustomerId AND IPS.InvoiceType = 2 AND CP.StatusId = 2 GROUP BY IPS.CustomerId 
		       ) A
			   OUTER APPLY
			   (  
					SELECT STUFF((SELECT CASE WHEN LEN(CP.ReceiptNo) > 0 THEN ',' ELSE '' END + CP.ReceiptNo  
					 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
				  WHERE C.CustomerId = IPS.CustomerId AND IPS.InvoiceType = 2 AND CP.StatusId = 2 FOR XML PATH('')), 1, 1, '') ReceiptNo  
				) AA
				OUTER APPLY
				(  
					SELECT STUFF((SELECT CASE WHEN LEN(IPS.CreatedDate) > 0 THEN ',' ELSE '' END + CONVERT(VARCHAR, IPS.CreatedDate, 110)
					 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					WHERE C.CustomerId = IPS.CustomerId AND IPS.InvoiceType = 2 AND CP.StatusId = 2 FOR XML PATH('')), 1, 1, '') InvoicePaidDate  
				) AB
			   OUTER APPLY
			   (  
					SELECT STUFF((SELECT CASE WHEN LEN(S.InvoiceNo) > 0 THEN ',' ELSE '' END + s.InvoiceNo  
					 FROM [dbo].[WorkOrderBillingInvoicing] S WITH (NOLOCK)  
					 WHERE wobi.CustomerId = s.CustomerId AND S.InvoiceStatus = 'Invoiced'  AND s.IsVersionIncrease = 0 AND ISNULL(s.IsPerformaInvoice, 0) = 0 FOR XML PATH('')), 1, 1, '') InvoiceNo  
				) B
				OUTER APPLY
				(  
					SELECT STUFF((SELECT CASE WHEN LEN(S.CustomerReference) >0 then ',' ELSE '' END + s.CustomerReference  
					 FROM [dbo].[WorkOrder] WOS WITH (NOLOCK) 
					 INNER JOIN [dbo].[WorkOrderPartNumber] s WITH (NOLOCK) ON WOS.WorkOrderId = s.WorkOrderId
					 INNER JOIN [dbo].[WorkOrderWorkFlow] F WITH (NOLOCK) ON F.WorkOrderPartNoId = s.ID
					 INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobis WITH(NOLOCK) on wobis.IsVersionIncrease=0 AND wobis.WorkFlowWorkOrderId=F.WorkFlowWorkOrderId AND ISNULL(wobis.IsPerformaInvoice, 0) = 0
					WHERE wobi.CustomerId = wobis.CustomerId  AND wobis.InvoiceStatus = 'Invoiced' FOR XML PATH('')), 1, 1, '') CustomerReference  
				) D
				OUTER APPLY(  
					 SELECT	STUFF((SELECT CASE WHEN LEN(S.InvoiceDate) >0 then ',' ELSE '' END + CONVERT(VARCHAR, S.InvoiceDate, 110)   
						 FROM [dbo].[WorkOrderBillingInvoicing] S WITH (NOLOCK)  
					WHERE wobi.CustomerId = s.CustomerId AND S.InvoiceStatus = 'Invoiced'  AND s.IsVersionIncrease = 0 AND ISNULL(S.IsPerformaInvoice, 0) = 0 FOR XML PATH('')), 1, 1, '') InvoiceDateNew  
				) E
			   
			   WHERE  C.MasterCompanyId=@MasterCompanyId AND wobi.InvoiceStatus = 'Invoiced' 
			   GROUP BY C.CustomerId  --,wop.CustomerReference ,wobi.InvoiceNo,wobi.BillingInvoicingId
			  
			UNION ALL


          SELECT DISTINCT C.CustomerId,
                       MAX((ISNULL(C.[Name],''))) 'CustName' ,
					   MAX((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       MAX(CT.CustomerTypeName) 'CustomertType' ,
					   MAX(CR.Code) AS  'currencyCode',
					   SUM(sobi.GrandTotal) AS 'BalanceAmount',
					   ISNULL(SUM(sobi.GrandTotal - sobi.RemainingAmount),0)AS 'CurrentlAmount',   
					   SUM(sobi.RemainingAmount)AS 'RemainingAmount',
					   SUM(0) AS 'Amountpaidbylessthen0days',      
                       SUM(0) AS 'Amountpaidby30days',      
                       SUM(0) AS 'Amountpaidby60days',
					   SUM(0) AS 'Amountpaidby90days',
					   SUM(0) AS 'Amountpaidby120days',
					   SUM(0) AS 'Amountpaidbymorethan120days',  
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) AS CreatedBy,
                       MAX(C.UpdatedBy) AS UpdatedBy,
					   MAX(SO.ManagementStructureId) AS ManagementStructureId,
					   MAX(SO.CreditLimitName) AS 'Terms',
					   SUM(sobi.GrandTotal) AS 'InvoiceAmount',
					   MAX(A.InvoicePaidAmount) AS 'InvoicePaidAmount',
					   MAX(A.FxRate) AS 'FixRateAmount',
					   MAX(AB.InvoicePaidDate) AS 'InvoicePaidDate',
					   MAX(A.AdjustMentAmount) AS 'AdjustMentAmount',
					   MAX(ctm.NetDays) AS TermDays,
					   MAX(B.InvoiceNo) AS 'InvoiceNo',
					   MAX(sobi.InvoiceDate) AS 'PostedDate',
					   MAX(E.InvoiceDateNew) AS 'InvoiceDate',
					   MAX(d.CustomerReference) AS CustomerRef,
					   MAX(AA.ReceiptNo) AS 'ReceiptNo',
					   MAX(SO.SalesPersonName) AS 'SalesPerson',
					   count(sobi.SOBillingInvoicingId) AS 'InvoiceCount',
					   MAX(A.PaymentCount) AS 'PaymentCount',
					   MAX(
                      (CASE WHEN A.DiscAmount >0 THEN 'Discounts , ' ELSE '' END) +
                      (CASE WHEN A.OtherAdjustAmt >0 THEN 'Other AdjustMents , ' ELSE '' END) +
                      (CASE WHEN A.BankFeeAmount >0 THEN 'Wire Fee' ELSE '' END)) AS AdjustMentAmountType
			   FROM [dbo].Customer C WITH (NOLOCK) 
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
			   INNER JOIN [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK) ON sobi.SalesOrderId = so.SalesOrderId
			   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = sobi.CurrencyId
			   INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
		 	   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId
			   OUTER APPLY
			   (
					SELECT COUNT(IPS.ReceiptId) AS PaymentCount,
					         SUM(IPS.PaymentAmount)  AS 'InvoicePaidAmount',
							 SUM(IPS.FxRate)  AS 'FxRate',							
							 SUM(ISNULL(IPS.DiscAmount,0) + ISNULL(IPS.OtherAdjustAmt,0) + ISNULL(IPS.BankFeeAmount,0)) AS AdjustMentAmount,
					         MAX(ISNULL(IPS.DiscAmount,0)) AS DiscAmount , 
							 MAX(ISNULL(IPS.OtherAdjustAmt,0))  AS OtherAdjustAmt , 
							 MAX(ISNULL(IPS.BankFeeAmount,0)) AS BankFeeAmount
					FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					Where C.CustomerId = IPS.CustomerId AND IPS.InvoiceType=1 and CP.StatusId=2 GROUP BY IPS.CustomerId 
		       ) A
			   OUTER APPLY(  
					 SELECT	STUFF((SELECT CASE WHEN LEN(CP.ReceiptNo) > 0 THEN ',' ELSE '' END + CP.ReceiptNo  
						 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)
						LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
						WHERE C.CustomerId = IPS.CustomerId AND IPS.InvoiceType=1 AND CP.StatusId = 2 FOR XML PATH('')), 1, 1, '') ReceiptNo  
				) AA
				OUTER APPLY(  
					 SELECT STUFF((SELECT CASE WHEN LEN(IPS.CreatedDate) > 0 THEN ',' ELSE '' END + CONVERT(VARCHAR(MAX), IPS.CreatedDate, 110)
						 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)
						LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
						WHERE C.CustomerId = IPS.CustomerId AND IPS.InvoiceType = 1 AND CP.StatusId = 2 FOR XML PATH('')), 1, 1, '') InvoicePaidDate  
				) AB
			    OUTER APPLY(  
					 SELECT	STUFF((SELECT CASE WHEN LEN(S.InvoiceNo) >0 THEN ',' ELSE '' END + s.InvoiceNo  
						 FROM [dbo].[SalesOrderBillingInvoicing] S WITH (NOLOCK)  
						 WHERE sobi.CustomerId = s.CustomerId AND S.InvoiceStatus = 'Invoiced' FOR XML PATH('')), 1, 1, '') InvoiceNo  
				) B
				OUTER APPLY(  
					 SELECT	STUFF((SELECT CASE WHEN LEN(WOS.CustomerReference) > 0 THEN ',' ELSE '' END + WOS.CustomerReference  
						 FROM [dbo].[SalesOrder] WOS WITH (NOLOCK) 
						 INNER JOIN [dbo].[SalesOrderBillingInvoicing] sobis WITH(NOLOCK) on  sobis.SalesOrderId=WOS.SalesOrderId
						 WHERE sobi.CustomerId = sobis.CustomerId  AND sobis.InvoiceStatus = 'Invoiced'
						 FOR XML PATH('')), 1, 1, '') CustomerReference  
				) D
				OUTER APPLY(  
					 SELECT	STUFF((SELECT CASE WHEN LEN(S.InvoiceDate) >0 then ',' ELSE '' END + CONVERT(VARCHAR(MAX), S.InvoiceDate, 110)   
						 FROM [dbo].[SalesOrderBillingInvoicing] S WITH (NOLOCK)  
						 WHERE sobi.CustomerId = s.CustomerId AND S.InvoiceStatus = 'Invoiced' FOR XML PATH('')), 1, 1, '') InvoiceDateNew  
				) E
			    WHERE  C.MasterCompanyId=@MasterCompanyId AND sobi.InvoiceStatus = 'Invoiced'	
				        GROUP BY C.CustomerId  --,SO.CustomerReference,sobi.InvoiceNo,sobi.SOBillingInvoicingId

		
		------------------- SO Exchange Invoice ----------------------------------------------------------------------------------------------------
				UNION ALL

				SELECT DISTINCT C.CustomerId,
                       MAX((ISNULL(C.[Name],''))) 'CustName' ,
					   MAX((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       MAX(CT.CustomerTypeName) 'CustomertType' ,
					   MAX(CR.Code) AS  'currencyCode',
					   SUM(esobi.GrandTotal) AS 'BalanceAmount',
					   ISNULL(SUM(esobi.GrandTotal - esobi.RemainingAmount),0)AS 'CurrentlAmount',   
					   SUM(esobi.RemainingAmount)AS 'RemainingAmount',
					   SUM(0) AS 'Amountpaidbylessthen0days',      
                       SUM(0) AS 'Amountpaidby30days',      
                       SUM(0) AS 'Amountpaidby60days',
					   SUM(0) AS 'Amountpaidby90days',
					   SUM(0) AS 'Amountpaidby120days',
					   SUM(0) AS 'Amountpaidbymorethan120days',  
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) AS CreatedBy,
                       MAX(C.UpdatedBy) AS UpdatedBy,
					   MAX(ESO.ManagementStructureId) AS ManagementStructureId,
					   MAX(ESO.CreditLimitName) AS 'Terms',
					   SUM(esobi.GrandTotal) AS 'InvoiceAmount',
					   0 AS 'InvoicePaidAmount',
					   0 AS 'FixRateAmount',
					   NULL AS 'InvoicePaidDate',
					   0 AS 'AdjustMentAmount',
					   MAX(ctm.NetDays) AS TermDays,
					    MAX(B.InvoiceNo) AS 'InvoiceNo',
					   MAX(esobi.InvoiceDate) AS 'PostedDate',
					   MAX(E.InvoiceDateNew) AS 'InvoiceDate',
					   MAX(d.CustomerReference) AS CustomerRef,
					   '' AS 'ReceiptNo',
					   MAX(ESO.SalesPersonName) AS 'SalesPerson',
					   count(esobi.SOBillingInvoicingId) AS 'InvoiceCount',
					   0 AS 'PaymentCount',
					   '' AS AdjustMentAmountType
				   FROM [dbo].Customer C WITH (NOLOCK) 
				   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				   INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.CustomerId = C.CustomerId
				   INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] esobi WITH (NOLOCK) ON esobi.ExchangeSalesOrderId = ESO.ExchangeSalesOrderId
				   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = esobi.CurrencyId
				   INNER JOIN [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = esobi.ExchangeSalesOrderId
		 		   LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = ESO.CreditTermId
				   OUTER APPLY(  
					 SELECT	STUFF((SELECT CASE WHEN LEN(S.InvoiceNo) >0 THEN ',' ELSE '' END + s.InvoiceNo  
						 FROM [dbo].[SalesOrderBillingInvoicing] S WITH (NOLOCK)  
						 WHERE esobi.CustomerId = s.CustomerId AND S.InvoiceStatus = 'Invoiced' FOR XML PATH('')), 1, 1, '') InvoiceNo  
					) B
					OUTER APPLY(  
						 SELECT	STUFF((SELECT CASE WHEN LEN(WOS.CustomerReference) > 0 THEN ',' ELSE '' END + WOS.CustomerReference  
							 FROM [dbo].[ExchangeSalesOrder] WOS WITH (NOLOCK) 
							 INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] sobis WITH(NOLOCK) on  sobis.ExchangeSalesOrderId=WOS.ExchangeSalesOrderId
							 WHERE esobi.CustomerId = sobis.CustomerId  AND sobis.InvoiceStatus = 'Invoiced'
							 FOR XML PATH('')), 1, 1, '') CustomerReference  
					) D
					OUTER APPLY(  
						 SELECT	STUFF((SELECT CASE WHEN LEN(S.InvoiceDate) >0 then ',' ELSE '' END + CONVERT(VARCHAR(MAX), S.InvoiceDate, 110)   
							 FROM [dbo].[ExchangeSalesOrderBillingInvoicing] S WITH (NOLOCK)  
							 WHERE esobi.CustomerId = s.CustomerId AND S.InvoiceStatus = 'Invoiced' FOR XML PATH('')), 1, 1, '') InvoiceDateNew  
					) E
				   WHERE  C.MasterCompanyId=@MasterCompanyId AND esobi.InvoiceStatus = 'Invoiced'	
				   GROUP BY C.CustomerId
				),
				
				Result AS(
				SELECT DISTINCT C.CustomerId,
                       MAX((ISNULL(C.[Name],''))) 'CustName' ,
					   MAX((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       MAX(CT.CustomerTypeName) 'CustomertType' ,
					   MAX(CTE.currencyCode) AS  'currencyCode',
					   --ISNULL(SUM(CTE.PaymentAmount),0) AS 'BalanceAmount',
					   ISNULL(SUM(CTE.BalanceAmount - CTE.RemainingAmount),0) AS 'CurrentlAmount',                    
					   ISNULL(SUM(CTE.RemainingAmount),0) AS 'PaymentAmount',
					   ISNULL(MAX(CASE WHEN CTECalculation.paidbylessthen0days > 0 then  (CTECalculation.paidbylessthen0days + ISNULL(E.CMAmount,0) + ISNULL(H.SCMAmount,0)) ELSE (CTECalculation.paidbylessthen0days) END),0) AS 'Amountpaidbylessthen0days',  
					   ISNULL(MAX(CASE WHEN CTECalculation.paidby30days > 0 then  (CTECalculation.paidby30days + ISNULL(E.CMAmount,0) + ISNULL(H.SCMAmount,0)) ELSE (CTECalculation.paidby30days) END),0) AS 'Amountpaidby30days', 
					   ISNULL(MAX(CASE WHEN CTECalculation.paidby60days > 0 then  (CTECalculation.paidby60days + ISNULL(E.CMAmount,0) + ISNULL(H.SCMAmount,0)) ELSE (CTECalculation.paidby60days) END),0) AS 'Amountpaidby60days', 
					   ISNULL(MAX(CASE WHEN CTECalculation.paidby90days > 0 then  (CTECalculation.paidby90days + ISNULL(E.CMAmount,0) + ISNULL(H.SCMAmount,0)) ELSE (CTECalculation.paidby90days) END),0) AS 'Amountpaidby90days', 
					   ISNULL(MAX(CASE WHEN CTECalculation.paidby120days > 0 then  (CTECalculation.paidby120days + ISNULL(E.CMAmount,0) + ISNULL(H.SCMAmount,0)) ELSE (CTECalculation.paidby120days) END),0) AS 'Amountpaidby120days', 
					   ISNULL(MAX(CASE WHEN CTECalculation.paidbymorethan120days > 0 then  (CTECalculation.paidbymorethan120days + ISNULL(E.CMAmount,0) + ISNULL(H.SCMAmount,0)) ELSE (CTECalculation.paidbymorethan120days) END),0) AS 'Amountpaidbymorethan120days', 
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) AS CreatedBy,
                       MAX(C.UpdatedBy) AS UpdatedBy,
					   MAX(CTE.ManagementStructureId) AS ManagementStructureId,
					   MAX(ctm.Name) AS 'Terms',
					   DATEADD(DAY, MAX(CTE.TermDays), MAX(CTE.PostedDate)) AS 'DueDate',
					   ISNULL(SUM(CTE.RemainingAmount) + MAX(ISNULL(E.CMAmount,0)) + MAX(ISNULL(H.SCMAmount,0)),0) +  SUM(CTE.AdjustMentAmount)   AS 'BalanceAmount',
					   SUM(ISNULL(CTE.InvoiceAmount,0)) AS 'InvoiceAmount',
					   SUM(ISNULL(CTE.FixRateAmount,0)) AS 'FixRateAmount',
					   SUM(ISNULL(CTE.InvoicePaidAmount,0)) AS 'InvoicePaidAmount',
					   MAX(AB.InvoicePaidDate) AS 'InvoicePaidDateType',
					   ISNULL(MAX(E.CMAmount),0) + ISNULL(MAX(H.SCMAmount),0) AS 'CMAmount',
					   MAX(F.CMDate) AS 'CMDateType',
					   MAX(A.InvoiceNo) AS 'InvoiceNoType',
					   MAX(B.InvoiceDate) AS 'InvoiceDateType',
					   MAX(D.CustomerRef) AS 'CustomerRefType',
					   ISNULL(SUM(CTE.AdjustMentAmount),0) AS 'AdjustMentAmount',
					   MAX(AA.ReceiptNo) AS 'PaymentRefType',
					   MAX(G.Salesperson) AS 'SalespersonType',
					   MAX(AB.InvoicePaidDate)  AS 'AdjustMentDateType',
					   'AR-Inv' AS 'DocType',
					   ISNULL(MAX(E.CMCount),0) AS 'CMCount',
					   MAX(CTE.AdjustMentAmountType) AS 'AdjustMentAmountType',
					   (CASE WHEN SUM(CTE.InvoiceCount) > 1 Then 'Multiple' ELSE MAX(A.InvoiceNo) END)  AS 'InvoiceNo',
					   (CASE WHEN SUM(CTE.InvoiceCount) > 1 Then 'Multiple' ELSE MAX(B.InvoiceDate) END)  AS InvoiceDate,
					   (CASE WHEN SUM(CTE.InvoiceCount) > 1 Then 'Multiple' ELSE MAX(ISNULL(G.Salesperson,'Unassigned')) END)  AS Salesperson,
					   (CASE WHEN SUM(CTE.InvoiceCount) > 1 Then 'Multiple' ELSE MAX(D.CustomerRef) END)  AS CustomerRef,
					   (CASE WHEN SUM(CTE.PaymentCount) > 1 Then 'Multiple' ELSE MAX(AB.InvoicePaidDate) END)  AS InvoicePaidDate,
					   (CASE WHEN ISNULL(SUM(CTE.AdjustMentAmount),0) > 1 Then 'Multiple' ELSE '' END)  AS AdjustMentDate,
					   (CASE WHEN SUM(CTE.PaymentCount) > 1 Then 'Multiple' ELSE MAX(AA.ReceiptNo) END)  AS PaymentRef,
					   (CASE WHEN MAX(E.CMCount) > 1 Then 'Multiple' ELSE MAX(F.CMDate) END)  AS 'CMDate'
					   FROM [dbo].[Customer] C WITH (NOLOCK) 
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN CTE AS CTE WITH (NOLOCK) ON CTE.CustomerId = C.CustomerId 
			   INNER JOIN CTECalculation AS CTECalculation WITH (NOLOCK) ON CTECalculation.CustomerId = C.CustomerId 
			   INNER JOIN [dbo].[CustomerFinancial] ctf WITH(NOLOCK) ON ctf.CustomerId = C.CustomerId
			    LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = ctf.CreditTermsId
			   OUTER APPLY(  
					 SELECT STUFF((SELECT CASE WHEN LEN(S.InvoiceNo) > 0 THEN ',' ELSE '' END + s.InvoiceNo  
						 FROM CTE S WITH (NOLOCK)  
						 WHERE C.CustomerId = s.CustomerId FOR XML PATH('')), 1, 1, '') InvoiceNo  
			   ) A
			   OUTER APPLY(  
					 SELECT STUFF((SELECT CASE WHEN LEN(S.ReceiptNo) > 0 THEN ',' ELSE '' END + s.ReceiptNo  
						 FROM CTE S WITH (NOLOCK)  
						 WHERE C.CustomerId = s.CustomerId FOR XML PATH('')), 1, 1, '') ReceiptNo  
				) AA
				OUTER APPLY(  
					 SELECT STUFF((SELECT CASE WHEN LEN(S.InvoiceDate) > 0 THEN ',' ELSE '' END + S.InvoiceDate  
						 FROM CTE S WITH (NOLOCK)  
						 WHERE C.CustomerId = s.CustomerId FOR XML PATH('')), 1, 1, '') InvoiceDate  
				) B
				OUTER APPLY(  
					 SELECT STUFF((SELECT CASE WHEN LEN(S.InvoicePaidDate) > 0 THEN ',' ELSE '' END + CONVERT(VARCHAR(MAX), S.InvoicePaidDate, 110)  
						 FROM CTE S WITH (NOLOCK)  
						 WHERE C.CustomerId = s.CustomerId FOR XML PATH('')), 1, 1, '') InvoicePaidDate  
				) AB
				OUTER APPLY
				(  
					 SELECT STUFF((SELECT CASE WHEN LEN(S.CustomerRef) > 0 THEN ',' ELSE '' END + S.CustomerRef  
						 FROM CTE S WITH (NOLOCK)  
						 WHERE C.CustomerId = s.CustomerId FOR XML PATH('')), 1, 1, '') CustomerRef  
				) D
				OUTER APPLY
			    (
					SELECT SUM(CMD.Amount)  AS 'CMAmount',
					       COUNT(CM.CreditMemoHeaderId) AS 'CMCount'
					FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)
					INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId 
					WHERE CM.StatusId = @CMPostedStatusId AND CM.CustomerId = C.CustomerId GROUP BY CM.CustomerId 
		        ) E
			    OUTER APPLY
				(
					 SELECT STUFF((SELECT CASE WHEN LEN(CM.CreatedDate) > 0 THEN ',' ELSE '' END + CONVERT(VARCHAR(MAX), CM.CreatedDate, 110)  
					 FROM CreditMemo CM WITH (NOLOCK)  
					 INNER JOIN DBO.CreditMemoDetails CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId 
					 WHERE CM.StatusId = @CMPostedStatusId AND C.CustomerId = CM.CustomerId FOR XML PATH('')), 1, 1, '') CMDate  
		       ) F
			   OUTER APPLY
			   (  
				 SELECT STUFF((SELECT CASE WHEN LEN(S.SalesPerson) > 0 THEN ',' ELSE '' END + S.SalesPerson  
					 FROM CTE S WITH (NOLOCK)  
					 WHERE C.CustomerId = s.CustomerId FOR XML PATH('')), 1, 1, '') SalesPerson  
			   ) G
			   OUTER APPLY
			   (
					SELECT SUM(CM.Amount) AS 'SCMAmount',
					       COUNT(CM.CreditMemoHeaderId) AS 'SCMCount'					
					  FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
					LEFT JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0    
					LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0  
					WHERE CM.[StatusId] = @CMPostedStatusId 
					  AND CM.[CustomerId] = C.CustomerId 
					  AND CM.[IsStandAloneCM] = 1        
					  GROUP BY CM.CustomerId 
		       ) H

			   WHERE  C.MasterCompanyId=@MasterCompanyId	
			   GROUP BY C.CustomerId

			), ResultCount AS(SELECT COUNT(CustomerId) AS totalItems FROM Result)

			SELECT * INTO #TempResult FROM  Result
			  WHERE ((@GlobalFilter <>'' AND ((CustName LIKE '%' +@GlobalFilter+'%') OR
			        (CustomerCode LIKE '%' +@GlobalFilter+'%') OR	
					(CustomertType LIKE '%' +@GlobalFilter+'%') OR					
					(currencyCode LIKE '%' +@GlobalFilter+'%') OR						
				    (CAST(BalanceAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR						
					(CAST(CurrentlAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(PaymentAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Amountpaidbylessthen0days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Amountpaidby30days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Amountpaidby60days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Amountpaidby90days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Amountpaidby120days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR					
					(CAST(Amountpaidbymorethan120days AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR

					(InvoiceNo LIKE '%' +@GlobalFilter+'%') OR	
					(DocType LIKE '%' +@GlobalFilter+'%') OR	
					(CustomerRef LIKE '%' +@GlobalFilter+'%') OR					
					(Salesperson LIKE '%' +@GlobalFilter+'%') OR
					(Terms LIKE '%' +@GlobalFilter+'%') OR	
					(PaymentRef LIKE '%' +@GlobalFilter+'%') OR					
					(CAST(FixRateAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(InvoiceAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(InvoicePaidAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(CMAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(AdjustMentAmount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR					

					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	
					OR   
					(@GlobalFilter='' AND (ISNULL(@CustName,'') ='' OR CustName LIKE '%' + @CustName+'%') AND
					(ISNULL(@CustomerCode,'') ='' OR CustomerCode LIKE '%' + @CustomerCode + '%') AND
					(ISNULL(@CustomertType,'') ='' OR CustomertType LIKE '%' + @CustomertType + '%') AND
					(ISNULL(@currencyCode,'') ='' OR currencyCode LIKE '%' + @currencyCode + '%') AND
				    (ISNULL(@BalanceAmount,0) =0 OR BalanceAmount= @BalanceAmount) AND
				    (ISNULL(@CurrentlAmount,0) =0 OR CurrentlAmount =@CurrentlAmount) AND			
					(ISNULL(@Amountpaidbylessthen0days,0) =0 OR Amountpaidbylessthen0days = @Amountpaidbylessthen0days) AND
					(ISNULL(@Amountpaidby30days,0) =0 OR Amountpaidby30days = @Amountpaidby30days) AND
					(ISNULL(@Amountpaidby60days,0) =0 OR Amountpaidby60days= @Amountpaidby60days) AND
					(ISNULL(@Amountpaidby90days,0) =0 OR Amountpaidby90days= @Amountpaidby90days) AND
					(ISNULL(@Amountpaidby120days,0) =0 OR Amountpaidby120days = @Amountpaidby120days) AND					
					(ISNULL(@Amountpaidbymorethan120days,0) =0 OR Amountpaidbymorethan120days = @Amountpaidbymorethan120days) AND
					
					(ISNULL(@InvoiceNo,'') ='' OR InvoiceNo LIKE '%' + @InvoiceNo + '%') AND
					(ISNULL(@DocType,'') ='' OR DocType LIKE '%' + @DocType + '%') AND
					(ISNULL(@CustomerRef,'') ='' OR CustomerRef LIKE '%' + @CustomerRef + '%') AND
					(ISNULL(@Salesperson,'') ='' OR Salesperson LIKE '%' + @Salesperson + '%') AND
					(ISNULL(@Terms,'') ='' OR Terms LIKE '%' + @Terms + '%') AND
					(ISNULL(@PaymentRef,'') ='' OR PaymentRef LIKE '%' + @PaymentRef + '%') AND
					(ISNULL(@FixRateAmount,0) =0 OR FixRateAmount = @FixRateAmount) AND
					(ISNULL(@InvoiceAmount,0) =0 OR InvoiceAmount = @InvoiceAmount) AND
					(ISNULL(@InvoicePaidAmount,0) =0 OR InvoicePaidAmount= @InvoicePaidAmount) AND
					(ISNULL(@CMAmount,0) =0 OR CMAmount= @CMAmount) AND
					(ISNULL(@AdjustMentAmount,0) =0 OR AdjustMentAmount = @AdjustMentAmount) AND					
					(ISNULL(@DueDate,'') ='' OR CAST(DueDate AS DATE)=CAST(@DueDate AS DATE)) AND
					(ISNULL(@InvoicePaidDate,'') ='' OR CAST(InvoicePaidDate AS DATE)=CAST(@InvoicePaidDate AS DATE)) AND
					(ISNULL(@CMDate,'') ='' OR CAST(CMDate AS DATE)=CAST(@CMDate AS DATE)) AND
					(ISNULL(@InvoiceDate,'') ='' OR CAST(InvoiceDate AS DATE)=CAST(@InvoiceDate AS DATE)) AND
					(ISNULL(@AdjustMentDate,'') ='' OR CAST(AdjustMentDate AS DATE)=CAST(@AdjustMentDate AS DATE)) AND
					
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE)=CAST(@CreatedDate AS DATE)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE)=CAST(@UpdatedDate AS DATE)))
				   )

		  SELECT @Count = COUNT(CustomerId) FROM #TempResult			

		  SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustName')  THEN [CustName] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustName')  THEN [CustName] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerCode')  THEN CustomerCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerCode')  THEN CustomerCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomertType')  THEN CustomertType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomertType')  THEN CustomertType END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='currencyCode')  THEN currencyCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='currencyCode')  THEN currencyCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='BalanceAmount')  THEN BalanceAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='BalanceAmount')  THEN BalanceAmount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CurrentlAmount')  THEN CurrentlAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CurrentlAmount')  THEN CurrentlAmount END DESC, 			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidbylessthen0days')  THEN Amountpaidbylessthen0days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidbylessthen0days')  THEN Amountpaidbylessthen0days END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby30days')  THEN Amountpaidby30days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby30days')  THEN Amountpaidby30days END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby60days')  THEN Amountpaidby60days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby60days')  THEN Amountpaidby60days END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby90days')  THEN Amountpaidby90days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby90days')  THEN Amountpaidby90days END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidby120days')  THEN Amountpaidby120days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidby120days')  THEN Amountpaidby120days END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amountpaidbymorethan120days')  THEN Amountpaidbymorethan120days END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amountpaidbymorethan120days')  THEN Amountpaidbymorethan120days END DESC,
			

			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceNo')  THEN InvoiceNo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceNo')  THEN InvoiceNo END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='DocType')  THEN DocType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DocType')  THEN DocType END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerRef')  THEN CustomerRef END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerRef')  THEN CustomerRef END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Salesperson')  THEN Salesperson END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Salesperson')  THEN Salesperson END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Terms')  THEN Terms END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Terms')  THEN Terms END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PaymentRef')  THEN PaymentRef END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PaymentRef')  THEN PaymentRef END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='FixRateAmount')  THEN FixRateAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='FixRateAmount')  THEN FixRateAmount END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceAmount')  THEN InvoiceAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceAmount')  THEN InvoiceAmount END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoicePaidAmount')  THEN InvoicePaidAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoicePaidAmount')  THEN InvoicePaidAmount END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='CMAmount')  THEN CMAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CMAmount')  THEN CMAmount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AdjustMentAmount')  THEN AdjustMentAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AdjustMentAmount')  THEN AdjustMentAmount END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='DueDate')  THEN DueDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DueDate')  THEN DueDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoicePaidDate')  THEN InvoicePaidDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoicePaidDate')  THEN InvoicePaidDate END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='CMDate')  THEN CMDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CMDate')  THEN CMDate END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AdjustMentDate')  THEN AdjustMentDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AdjustMentDate')  THEN AdjustMentDate END DESC,

			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC			
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY
		END		
		 
		 --DECLARE @SOMSModuleID INT = 17,@WOMSModuleID INT = 12;
	END TRY    
	BEGIN CATCH      
		--IF @@trancount > 0
			--PRINT 'ROLLBACK'
            --ROLLBACK TRANSACTION;
            -- temp table drop
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'ProcLegalEntityList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			  -- + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			  -- + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			  -- + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			  -- + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			  -- + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			  -- + '@Parameter7 = ''' + CAST(ISNULL(@CustName, '') AS varchar(100))
			  -- + '@Parameter8 = ''' + CAST(ISNULL(@CustomerCode, '') AS varchar(100))
			  -- + '@Parameter9 = ''' + CAST(ISNULL(@CustomertType , '') AS varchar(100))
			  -- + '@Parameter10 = ''' + CAST(ISNULL(@currencyCode , '') AS varchar(100))
			  -- + '@Parameter11 = ''' + CAST(ISNULL(@BalanceAmount, '') AS varchar(100))
			  -- + '@Parameter12 = ''' + CAST(ISNULL(@CurrentlAmount, '') AS varchar(100))
			  --+ '@Parameter13 = ''' + CAST(ISNULL(@Amountpaidby30days, '') AS varchar(100))
			  --+ '@Parameter14 = ''' + CAST(ISNULL(@Amountpaidby60days, '') AS varchar(100))
			  --+ '@Parameter15 = ''' + CAST(ISNULL(@Amountpaidby90days , '') AS varchar(100))
			  --+ '@Parameter16 = ''' + CAST(ISNULL(@Amountpaidby120days , '') AS varchar(100))
			  --+ '@Parameter17 = ''' + CAST(ISNULL(@Amountpaidbymorethan120days , '') AS varchar(100))
			  --+ '@Parameter18 = ''' + CAST(ISNULL(@LegelEntity , '') AS varchar(100))
			  --+ '@Parameter19 = ''' + CAST(ISNULL(@EmployeeId , '') AS varchar(100))	
			  --+ '@Parameter20 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  --+ '@Parameter21 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  --+ '@Parameter22 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  --+ '@Parameter23 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  --+ '@Parameter24 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END