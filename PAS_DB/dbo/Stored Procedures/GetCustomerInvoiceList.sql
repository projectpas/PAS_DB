--exec GetCustomerInvoiceList @PageNumber=1,@PageSize=10,@SortColumn=N'CustName',@SortOrder=1,@GlobalFilter=N'',@StatusId=2,@CustName='Fast',@CustomerCode=NULL,@CustomertType=NULL,@currencyCode=NULL,@BalanceAmount=NULL,@CurrentlAmount=NULL,@Amountpaidbylessthen0days=NULL,@Amountpaidby30days=NULL,@Amountpaidby60days=NULL,@Amountpaidby90days=NULL,@Amountpaidby120days=NULL,@Amountpaidbymorethan120days=NULL,@LegelEntity=NULL,@EmployeeId=2,@CreatedBy=NULL,@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,@viewType=N'Deatils',@MasterCompanyId=1,@InvoiceDate=NULL,@CustomerRef=NULL,@InvoiceNo=NULL,@DocType=NULL,@Salesperson=NULL,@Terms=NULL,@DueDate=NULL,@FixRateAmount=NULL,@InvoiceAmount=NULL,@InvoicePaidAmount=NULL,@InvoicePaidDate=NULL,@PaymentRef=NULL,@CMAmount=NULL,@CMDate=NULL,@AdjustMentAmount=NULL,@AdjustMentDate=NULL,@SOMSModuleID=17,@WOMSModuleID=12
CREATE PROCEDURE [dbo].[GetCustomerInvoiceList]
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
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@viewType varchar(50) = NULL,
@MasterCompanyId bigint = NULL,
@InvoiceDate datetime = NULL,
@CustomerRef varchar(50) = NULL,
@InvoiceNo varchar(50) = NULL,
@DocType varchar(50) = NULL,
@Salesperson varchar(50) = NULL,
@Terms varchar(50) = NULL,
@DueDate datetime = NULL,
@fixRateAmount decimal(18,2) = NULL,
@InvoiceAmount decimal(18,2) = NULL,
@InvoicePaidAmount decimal(18,2) = NULL,
@InvoicePaidDate datetime = NULL,
@PaymentRef varchar(50) = NULL,
@CMAmount decimal(18,2) = NULL,
@CMDate datetime = NULL,
@AdjustMentAmount decimal(18,2) = NULL,
@AdjustMentDate datetime = NULL,
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
	    Declare @adjustString  varchar(500);
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		IF (@viewType='all')
		BEGIN
			SET @viewType=NULL
		END 
		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CustName')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
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
			SET @IsActive=NULL;
		END

		IF (@viewType = 'Deatils')
		begin

	
		 ;WITH CTE AS(
						SELECT DISTINCT (C.CustomerId) as CustomerId,

                       ((ISNULL(C.[Name],''))) 'CustName' ,
					   ((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       (CT.CustomerTypeName) 'CustomertType' ,
					   (CR.Code) as  'currencyCode',
					   (wobi.GrandTotal) as 'BalanceAmount',
					   (wobi.GrandTotal - wobi.RemainingAmount)as 'CurrentlAmount',             
					   (wobi.RemainingAmount)as 'PaymentAmount',
					   (wobi.InvoiceNo) as 'InvoiceNo',
			           (wobi.PostedDate) as 'InvoiceDate',
					   ISNULL(ctm.NetDays,0) AS NetDays,
					   (CASE WHEN DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) <= 0 THEN wobi.RemainingAmount ELSE 0 END) AS Amountpaidbylessthen0days,
					   (CASE
						WHEN DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 0 AND DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE())<= 30 THEN wobi.RemainingAmount
						ELSE 0
					  END) AS Amountpaidby30days,
					   (CASE
						WHEN DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 30 AND DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE())<= 60 THEN wobi.RemainingAmount
						ELSE 0
					  END) AS Amountpaidby60days,
						(CASE
						WHEN DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 60 AND DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE()) <= 90 THEN wobi.RemainingAmount
						ELSE 0
					  END) AS Amountpaidby90days,
					   (CASE
						WHEN DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE()) <= 120 THEN wobi.RemainingAmount
						ELSE 0
					  END) AS Amountpaidby120days,
					   (CASE
						WHEN DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 120 THEN wobi.RemainingAmount
						ELSE 0
					  END) AS Amountpaidbymorethan120days,
                       (C.UpdatedBy) as UpdatedBy,
					   (wop.ManagementStructureId) as ManagementStructureId,

					   'AR-Inv' AS 'DocType',
					   wop.CustomerReference as 'CustomerRef',
					   isnull(emp.FirstName,'Unassigned') as 'Salesperson',
					   ctm.Name as 'Terms',
					   A.FxRate as 'FixRateAmount',
					   wobi.GrandTotal as 'InvoiceAmount',
					   A.InvoicePaidAmount as 'InvoicePaidAmount',
					   A.InvoicePaidDate as 'InvoicePaidDate',
					   A.ReceiptNo as 'PaymentRef',
					   B.CMAmount as 'CMAmount',
					   D.CMDate as 'CMDate',
					   A.AdjustMentAmount as 'AdjustMentAmount',
					   A.InvoicePaidDate as 'AdjustMentDate',
					   (
                      (case when A.DiscAmount >0 then 'Discounts , ' else '' end) +
                      (case when A.OtherAdjustAmt >0 then 'Other AdjustMents , ' else '' end) +
                      (case when A.BankFeeAmount >0 then 'Wire Fee' else '' end)) as AdjustMentAmountType
			   FROM dbo.WorkOrderBillingInvoicing wobi WITH (NOLOCK) 
			  
			   INNER JOIN dbo.[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = wobi.WorkOrderId
			   INNER JOIN dbo.Customer c  WITH (NOLOCK) ON C.CustomerId=WO.CustomerId
			   LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId
			   LEFT JOIN Employee emp WITH(NOLOCK) ON emp.EmployeeId = WO.SalesPersonId
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId and wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID
		 	   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			   INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID
			   Left JOIN DBO.ManagementStructureLevel MSL WITH(NOLOCK) on MSL.ID = MSD.Level1Id
			    OUTER APPLY
			   (
					SELECT Max(CP.ReceiptNo) as 'ReceiptNo',Max(IPS.CreatedDate) as 'InvoicePaidDate',   sum(IPS.PaymentAmount)  AS 'InvoicePaidAmount',sum(IPS.FxRate)  AS 'FxRate',sum( IPS.DiscAmount +IPS.OtherAdjustAmt +IPS.BankFeeAmount) as AdjustMentAmount,
					max(Isnull(IPS.DiscAmount,0)) as DiscAmount , max(Isnull(IPS.OtherAdjustAmt,0))  as OtherAdjustAmt , max(Isnull(IPS.BankFeeAmount,0)) as BankFeeAmount
					FROM DBO.InvoicePayments IPS WITH (NOLOCK)
					LEFT JOIN DBO.CustomerPayments CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					Where wobi.BillingInvoicingId = IPS.SOBillingInvoicingId and CP.StatusId=2 AND IPS.InvoiceType=2 GROUP BY IPS.SOBillingInvoicingId 
		       ) A
			    OUTER APPLY
			   (
					SELECT sum(CMD.Amount)  AS 'CMAmount'
					FROM DBO.CreditMemoDetails CMD WITH (NOLOCK)
					INNER JOIN DBO.CreditMemo CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = WO.CustomerId
					Where wobii.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=1 AND CM.CustomerId = WO.CustomerId GROUP BY CMD.BillingInvoicingItemId 
		       ) B

			     OUTER APPLY
			   (
					SELECT MAX(CM.CreatedDate)  AS 'CMDate'
					FROM DBO.CreditMemoDetails CMD WITH (NOLOCK)
					INNER JOIN DBO.CreditMemo CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = WO.CustomerId
					Where wobii.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=1 AND CM.CustomerId = WO.CustomerId GROUP BY CMD.BillingInvoicingItemId 
		       ) D
			  WHERE  wobi.InvoiceStatus = 'Invoiced' and WO.MasterCompanyId = @MasterCompanyId 
			UNION ALL
			SELECT DISTINCT (C.CustomerId) as CustomerId,
                       ((ISNULL(C.[Name],''))) 'CustName' ,
					   ((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       (CT.CustomerTypeName) 'CustomertType' ,
					   (CR.Code) as  'currencyCode',
					   (sobi.GrandTotal) as 'BalanceAmount',
					   (sobi.GrandTotal - sobi.RemainingAmount)as 'CurrentlAmount',   
					   isnull(sobi.RemainingAmount,0)as 'PaymentAmount',
					   (sobi.InvoiceNo) as 'InvoiceNo',
			           (sobi.PostedDate) as 'InvoiceDate',
					   ISNULL(ctm.NetDays,0) AS NetDays,
                      (CASE WHEN DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) <= 0 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidbylessthen0days,
					  (CASE
						WHEN DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 0 AND DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE()) <= 30 THEN sobi.RemainingAmount
						ELSE 0
					  END) AS Amountpaidby30days,
					   (CASE
						WHEN DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 30 AND DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE()) <= 60 THEN sobi.RemainingAmount
						ELSE 0
					  END) AS Amountpaidby60days,
						(CASE
						WHEN DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 60 AND DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE()) <= 90 THEN sobi.RemainingAmount
						ELSE 0
					  END) AS Amountpaidby90days,
					   (CASE
						WHEN DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 90 AND DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE()) <= 120 THEN sobi.RemainingAmount
						ELSE 0
					  END) AS Amountpaidby120days,
					   (CASE
						WHEN DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 120 THEN sobi.RemainingAmount
						ELSE 0
					  END) AS Amountpaidbymorethan120days,
                       (C.UpdatedBy) as UpdatedBy,
					   (SO.ManagementStructureId) as ManagementStructureId,
					   'AR-Inv' AS 'DocType',
					   sop.CustomerReference as 'CustomerRef',
					   isnull(SO.SalesPersonName,'Unassigned') as 'Salesperson',
					   ctm.Name as 'Terms',
					   A.FxRate as 'FixRateAmount',
					   sobi.GrandTotal as 'InvoiceAmount',
					   A.InvoicePaidAmount as 'InvoicePaidAmount',
					   A.InvoicePaidDate as 'InvoicePaidDate',
					   A.ReceiptNo as 'PaymentRef',
					   B.CMAmount as 'CMAmount',
					   D.CMDate as 'CMDate',
					   A.AdjustMentAmount as 'AdjustMentAmount',
					   A.InvoicePaidDate as 'AdjustMentDate',
					  (
                      (case when A.DiscAmount >0 then 'Discounts , ' else '' end) +
                      (case when A.OtherAdjustAmt >0 then 'Other AdjustMents , ' else '' end) +
                      (case when A.BankFeeAmount >0 then 'Wire Fee' else '' end)) as AdjustMentAmountType
			   FROM dbo.SalesOrderBillingInvoicing sobi WITH (NOLOCK) 
			   INNER JOIN dbo.[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId
			   INNER JOIN dbo.Customer c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId
			    LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN DBO.SalesOrderPart sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			   INNER JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId
			   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
			   INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
		 	   Left JOIN DBO.ManagementStructureLevel MSL WITH(NOLOCK) on MSL.ID = MSD.Level1Id
			   OUTER APPLY
			   (
					SELECT Max(CP.ReceiptNo) as 'ReceiptNo',Max(IPS.CreatedDate) as 'InvoicePaidDate',   sum(IPS.PaymentAmount)  AS 'InvoicePaidAmount',sum(IPS.FxRate)  AS 'FxRate',sum( IPS.DiscAmount +IPS.OtherAdjustAmt +IPS.BankFeeAmount) as AdjustMentAmount,
					max(Isnull(IPS.DiscAmount,0)) as DiscAmount , max(Isnull(IPS.OtherAdjustAmt,0))  as OtherAdjustAmt , max(Isnull(IPS.BankFeeAmount,0)) as BankFeeAmount
					FROM DBO.InvoicePayments IPS WITH (NOLOCK)
					LEFT JOIN DBO.CustomerPayments CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					Where sobii.SOBillingInvoicingId = IPS.SOBillingInvoicingId and CP.StatusId=2 AND IPS.InvoiceType=1 GROUP BY IPS.SOBillingInvoicingId 
		       ) A
			   OUTER APPLY
			   (
					SELECT sum(CMD.Amount)  AS 'CMAmount'
					FROM DBO.CreditMemoDetails CMD WITH (NOLOCK)
					INNER JOIN DBO.CreditMemo CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = SO.CustomerId
					Where sobii.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=0 AND CM.CustomerId = SO.CustomerId GROUP BY CMD.BillingInvoicingItemId 
		       ) B

			     OUTER APPLY
			   (
					SELECT MAX(CM.CreatedDate)  AS 'CMDate'
					FROM DBO.CreditMemoDetails CMD WITH (NOLOCK)
					INNER JOIN DBO.CreditMemo CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CM.CustomerId = SO.CustomerId
					Where sobii.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId AND CMD.IsWorkOrder=0 AND CM.CustomerId = SO.CustomerId GROUP BY CMD.BillingInvoicingItemId 
		       ) D
			  WHERE   sobi.InvoiceStatus = 'Invoiced'  and SO.MasterCompanyId = @MasterCompanyId 	      
			  )
						
			, Result AS(
				SELECT DISTINCT 
				       (CTE.CustomerId) as CustomerId ,
                       ((ISNULL(CTE.CustName,''))) 'CustName' ,
					   ((ISNULL(CTE.CustomerCode,''))) 'CustomerCode' ,
                       (CTE.CustomertType) 'CustomertType' ,
					   (CTE.currencyCode) as  'currencyCode',
					   ISNULL((CTE.PaymentAmount + Isnull(CTE.CMAmount,0)),0) as 'BalanceAmount',
					   ISNULL((CTE.Amountpaidbylessthen0days + Isnull(CTE.CMAmount,0)),0) as 'CurrentlAmount',   
					   ISNULL(CTE.PaymentAmount,0) as 'PaymentAmount',
					   (CTE.InvoiceNo) as 'InvoiceNo',
			           (CTE.InvoiceDate) as 'InvoiceDate',
					   ISNULL(Case when CTE.Amountpaidbylessthen0days > 0 then  (CTE.Amountpaidbylessthen0days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidbylessthen0days) end,0) as 'Amountpaidbylessthen0days',   
					   ISNULL(Case when CTE.Amountpaidby30days > 0 then  (CTE.Amountpaidby30days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidby30days) end,0) as 'Amountpaidby30days',      
                       ISNULL(Case when CTE.Amountpaidby60days > 0 then  (CTE.Amountpaidby60days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidby60days) end,0) as 'Amountpaidby60days',
					   ISNULL(Case when CTE.Amountpaidby90days > 0 then  (CTE.Amountpaidby90days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidby90days) end,0) as 'Amountpaidby90days',
					   ISNULL(Case when CTE.Amountpaidby120days > 0 then  (CTE.Amountpaidby120days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidby120days) end,0) as 'Amountpaidby120days',
					   ISNULL(Case when CTE.Amountpaidbymorethan120days > 0 then  (CTE.Amountpaidbymorethan120days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidbymorethan120days) end,0) as 'Amountpaidbymorethan120days',  
					   (C.CreatedDate) AS CreatedDate,
                       (C.UpdatedDate) AS UpdatedDate,
					   (C.CreatedBy) as CreatedBy,
                       (C.UpdatedBy) as UpdatedBy,
					   (CTE.ManagementStructureId) as ManagementStructureId,
					   CTE.DocType as DocType,
					   CTE.CustomerRef as 'CustomerRef',
					   CTE.Salesperson as 'Salesperson',
					   CTE.Terms as 'Terms',
					   DATEADD(day, CTE.NetDays,CTE.InvoiceDate) as 'DueDate',
					   ISNULL(CTE.FixRateAmount,0) as 'FixRateAmount',
					   ISNULL(CTE.InvoiceAmount,0) as 'InvoiceAmount',
					   ISNULL(CTE.InvoicePaidAmount,0) as 'InvoicePaidAmount',
					   CTE.InvoicePaidDate as 'InvoicePaidDate',
					   CTE.PaymentRef as 'PaymentRef',
					   ISNULL(CTE.CMAmount,0) as 'CMAmount',
					   CTE.CMDate as 'CMDate',
					   ISNULL(CTE.AdjustMentAmount,0) as 'AdjustMentAmount',
					   CTE.AdjustMentDate as 'AdjustMentDate',
					   CTE.AdjustMentAmountType AS 'AdjustMentAmountType'
			   FROM CTE as CTE WITH (NOLOCK) 
			   INNER JOIN Customer as c WITH (NOLOCK) ON c.CustomerId = CTE.CustomerId 
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
					(ISNULL(@DueDate,'') ='' OR CAST(DueDate AS Date)=CAST(@DueDate AS date)) AND
					(ISNULL(@InvoicePaidDate,'') ='' OR CAST(InvoicePaidDate AS Date)=CAST(@InvoicePaidDate AS date)) AND
					(ISNULL(@CMDate,'') ='' OR CAST(CMDate AS Date)=CAST(@CMDate AS date)) AND
					(ISNULL(@InvoiceDate,'') ='' OR CAST(InvoiceDate AS Date)=CAST(@InvoiceDate AS date)) AND
					(ISNULL(@AdjustMentDate,'') ='' OR CAST(AdjustMentDate AS Date)=CAST(@AdjustMentDate AS date)) AND
					
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
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
		end
		else
		begin

		;WITH CTEData AS(
			select C.CustomerId,CASt(sobi.InvoiceDate as date) AS InvoiceDate,
			sobi.GrandTotal,
			sobi.RemainingAmount,
			DATEDIFF(DAY, CASt(sobi.PostedDate as date), GETDATE()) AS dayDiff,
			ctm.NetDays,
			DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) AS CreditRemainingDays
			FROM dbo.Customer C WITH (NOLOCK) 
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
			   INNER JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SalesOrderId = so.SalesOrderId
			   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
		 	   LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId
			    WHERE  C.MasterCompanyId=@MasterCompanyId AND sobi.InvoiceStatus = 'Invoiced'
			UNION ALL
			
			select C.CustomerId,CASt(wobi.PostedDate as date) AS InvoiceDate,
			wobi.GrandTotal,
			wobi.RemainingAmount,
			DATEDIFF(DAY, CASt(wobi.PostedDate as date), GETDATE()) AS dayDiff,
			ctm.NetDays,
			DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) AS CreditRemainingDays
			FROM dbo.Customer C WITH (NOLOCK) 
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[WorkOrder] WO WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			   LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = WO.CreditTermId
			   INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.IsVersionIncrease=0 AND wobi.WorkOrderId=WO.WorkOrderId
		 	   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			   INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID
			   WHERE  C.MasterCompanyId=@MasterCompanyId AND wobi.InvoiceStatus = 'Invoiced'
			
			--group by wobi.InvoiceDate,ct.CustomerId,wobi.GrandTotal,wobi.RemainingAmount,ctm.NetDays,PostedDate
			
			), CTECalculation AS(
			select
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
			    from CTEData c group by CustomerId
			),
			
		   CTE AS(
						SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CR.Code) as  'currencyCode',
					   SUM(wobi.GrandTotal) as 'BalanceAmount',
					   ISNULL(SUM(wobi.GrandTotal - wobi.RemainingAmount),0)as 'CurrentlAmount',   
					   SUM(wobi.RemainingAmount)as 'RemainingAmount',
					   SUM(0) as 'Amountpaidbylessthen0days',      
                       SUM(0) as 'Amountpaidby30days',      
                       SUM(0) as 'Amountpaidby60days',
					   SUM(0) as 'Amountpaidby90days',
					   SUM(0) as 'Amountpaidby120days',
					   SUM(0) as 'Amountpaidbymorethan120days',  
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(wop.ManagementStructureId) as ManagementStructureId,
					   Max(wo.CreditTerms) as 'Terms',
					   SUM(wobi.GrandTotal) as 'InvoiceAmount',
					   Max(A.InvoicePaidAmount) as 'InvoicePaidAmount',
					   Max(A.FxRate) as 'FixRateAmount',
					   Max(AB.InvoicePaidDate) as 'InvoicePaidDate',
					   Max(A.AdjustMentAmount) as 'AdjustMentAmount',
					   max(ctm.NetDays) AS TermDays,
					   Max(B.InvoiceNo) as 'InvoiceNo',
					   Max(wobi.PostedDate) as 'PostedDate',
					   Max(E.InvoiceDateNew) as 'InvoiceDate',
					   Max(D.CustomerReference) as CustomerRef,
					   Max(AA.ReceiptNo) as 'ReceiptNo',
					   max(EMP.FirstName +' '+EMP.LastName) as 'SalesPerson',
					   count(wobi.BillingInvoicingId) as 'InvoiceCount',
					   Max(A.PaymentCount) as 'PaymentCount',
					    max(
                      (case when A.DiscAmount >0 then 'Discounts , ' else '' end) +
                      (case when A.OtherAdjustAmt >0 then 'Other AdjustMents , ' else '' end) +
                      (case when A.BankFeeAmount >0 then 'Wire Fee' else '' end)) as AdjustMentAmountType
			   FROM dbo.Customer C WITH (NOLOCK) 
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[WorkOrder] WO WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			   LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = WO.CreditTermId
			   INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN dbo.[WorkOrderWorkFlow] F WITH (NOLOCK) ON F.WorkOrderPartNoId = wop.ID
			   INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.IsVersionIncrease=0 AND wobi.WorkFlowWorkOrderId=F.WorkFlowWorkOrderId
		 	   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			   LEFT JOIN Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WO.SalesPersonId 
			   INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID
			   OUTER APPLY
			   (
					SELECT count(IPS.ReceiptId) as PaymentCount,sum(IPS.PaymentAmount)  AS 'InvoicePaidAmount',sum(IPS.FxRate)  AS 'FxRate',sum( IPS.DiscAmount +IPS.OtherAdjustAmt +IPS.BankFeeAmount) as AdjustMentAmount,
					max(Isnull(IPS.DiscAmount,0)) as DiscAmount , max(Isnull(IPS.OtherAdjustAmt,0))  as OtherAdjustAmt , max(Isnull(IPS.BankFeeAmount,0)) as BankFeeAmount
					FROM DBO.InvoicePayments IPS WITH (NOLOCK)
					LEFT JOIN DBO.CustomerPayments CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					Where C.CustomerId = IPS.CustomerId AND IPS.InvoiceType=2 and CP.StatusId=2 GROUP BY IPS.CustomerId 
		       ) A
			     Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(CP.ReceiptNo) >0 then ',' ELSE '' END + CP.ReceiptNo  
					 FROM DBO.InvoicePayments IPS WITH (NOLOCK)
					LEFT JOIN DBO.CustomerPayments CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					Where C.CustomerId = IPS.CustomerId AND IPS.InvoiceType=2 and CP.StatusId=2 
					 FOR XML PATH('')), 1, 1, '') ReceiptNo  
				) AA

				   Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(IPS.CreatedDate) >0 then ',' ELSE '' END + CONVERT(VARCHAR, IPS.CreatedDate, 110)
					 FROM DBO.InvoicePayments IPS WITH (NOLOCK)
					LEFT JOIN DBO.CustomerPayments CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					Where C.CustomerId = IPS.CustomerId AND IPS.InvoiceType=2 and CP.StatusId=2 
					 FOR XML PATH('')), 1, 1, '') InvoicePaidDate  
				) AB
			   Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(S.InvoiceNo) >0 then ',' ELSE '' END + s.InvoiceNo  
					 FROM WorkOrderBillingInvoicing S WITH (NOLOCK)  
					 Where wobi.CustomerId = s.CustomerId AND S.InvoiceStatus = 'Invoiced'  and s.IsVersionIncrease=0
					 FOR XML PATH('')), 1, 1, '') InvoiceNo  
				) B
					Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(S.CustomerReference) >0 then ',' ELSE '' END + s.CustomerReference  
					 FROM [WorkOrder] WOS WITH (NOLOCK) 
					 INNER JOIN dbo.[WorkOrderPartNumber] s WITH (NOLOCK) ON WOS.WorkOrderId = s.WorkOrderId
					 INNER JOIN dbo.[WorkOrderWorkFlow] F WITH (NOLOCK) ON F.WorkOrderPartNoId = s.ID
					 INNER JOIN DBO.WorkOrderBillingInvoicing wobis WITH(NOLOCK) on wobis.IsVersionIncrease=0 AND wobis.WorkFlowWorkOrderId=F.WorkFlowWorkOrderId
					Where wobi.CustomerId = wobis.CustomerId  and wobis.InvoiceStatus = 'Invoiced'
					 FOR XML PATH('')), 1, 1, '') CustomerReference  
				) D
				 Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(S.PostedDate) >0 then ',' ELSE '' END + CONVERT(VARCHAR, S.PostedDate, 110)   
					 FROM WorkOrderBillingInvoicing S WITH (NOLOCK)  
					 Where wobi.CustomerId = s.CustomerId AND S.InvoiceStatus = 'Invoiced'  and s.IsVersionIncrease=0
					 FOR XML PATH('')), 1, 1, '') InvoiceDateNew  
				) E

			   
			   WHERE  C.MasterCompanyId=@MasterCompanyId AND wobi.InvoiceStatus = 'Invoiced'	GROUP BY C.CustomerId  --,wop.CustomerReference ,wobi.InvoiceNo,wobi.BillingInvoicingId
			  
     UNION ALL
          SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CR.Code) as  'currencyCode',
					   SUM(sobi.GrandTotal) as 'BalanceAmount',
					   ISNULL(SUM(sobi.GrandTotal - sobi.RemainingAmount),0)as 'CurrentlAmount',   
					   SUM(sobi.RemainingAmount)as 'RemainingAmount',
					   SUM(0) as 'Amountpaidbylessthen0days',      
                       SUM(0) as 'Amountpaidby30days',      
                       SUM(0) as 'Amountpaidby60days',
					   SUM(0) as 'Amountpaidby90days',
					   SUM(0) as 'Amountpaidby120days',
					   SUM(0) as 'Amountpaidbymorethan120days',  
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(SO.ManagementStructureId) as ManagementStructureId,
					   Max(SO.CreditLimitName) as 'Terms',
					   SUM(sobi.GrandTotal) as 'InvoiceAmount',
					   Max(A.InvoicePaidAmount) as 'InvoicePaidAmount',
					   Max(A.FxRate) as 'FixRateAmount',
					   Max(AB.InvoicePaidDate) as 'InvoicePaidDate',
					   Max(A.AdjustMentAmount) as 'AdjustMentAmount',
					   max(ctm.NetDays) AS TermDays,
					   Max(B.InvoiceNo) as 'InvoiceNo',
					   Max(sobi.PostedDate) as 'PostedDate',
					   Max(E.InvoiceDateNew) as 'InvoiceDate',
					   Max(d.CustomerReference) as CustomerRef,
					   Max(AA.ReceiptNo) as 'ReceiptNo',
					   max(SO.SalesPersonName) as 'SalesPerson',
					   count(sobi.SOBillingInvoicingId) as 'InvoiceCount',
					   Max(A.PaymentCount) as 'PaymentCount',
					   max(
                      (case when A.DiscAmount >0 then 'Discounts , ' else '' end) +
                      (case when A.OtherAdjustAmt >0 then 'Other AdjustMents , ' else '' end) +
                      (case when A.BankFeeAmount >0 then 'Wire Fee' else '' end)) as AdjustMentAmountType
			   FROM dbo.Customer C WITH (NOLOCK) 
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
			   INNER JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SalesOrderId = so.SalesOrderId
			   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
			   INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
		 	   LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId
			   OUTER APPLY
			   (
					SELECT count(IPS.ReceiptId) as PaymentCount,sum(IPS.PaymentAmount)  AS 'InvoicePaidAmount',sum(IPS.FxRate)  AS 'FxRate',sum( IPS.DiscAmount +IPS.OtherAdjustAmt +IPS.BankFeeAmount) as AdjustMentAmount,
					max(Isnull(IPS.DiscAmount,0)) as DiscAmount , max(Isnull(IPS.OtherAdjustAmt,0))  as OtherAdjustAmt , max(Isnull(IPS.BankFeeAmount,0)) as BankFeeAmount
					FROM DBO.InvoicePayments IPS WITH (NOLOCK)
					LEFT JOIN DBO.CustomerPayments CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					Where C.CustomerId = IPS.CustomerId AND IPS.InvoiceType=1 and CP.StatusId=2 GROUP BY IPS.CustomerId 
		       ) A
			   Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(CP.ReceiptNo) >0 then ',' ELSE '' END + CP.ReceiptNo  
					 FROM DBO.InvoicePayments IPS WITH (NOLOCK)
					LEFT JOIN DBO.CustomerPayments CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					Where C.CustomerId = IPS.CustomerId AND IPS.InvoiceType=1 and CP.StatusId=2 
					 FOR XML PATH('')), 1, 1, '') ReceiptNo  
				) AA

				   Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(IPS.CreatedDate) >0 then ',' ELSE '' END + CONVERT(VARCHAR(max), IPS.CreatedDate, 110)
					 FROM DBO.InvoicePayments IPS WITH (NOLOCK)
					LEFT JOIN DBO.CustomerPayments CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId
					Where C.CustomerId = IPS.CustomerId AND IPS.InvoiceType=1 and CP.StatusId=2  
					 FOR XML PATH('')), 1, 1, '') InvoicePaidDate  
				) AB
			    Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(S.InvoiceNo) >0 then ',' ELSE '' END + s.InvoiceNo  
					 FROM SalesOrderBillingInvoicing S WITH (NOLOCK)  
					 Where sobi.CustomerId = s.CustomerId AND S.InvoiceStatus = 'Invoiced' 
					 FOR XML PATH('')), 1, 1, '') InvoiceNo  
				) B
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(WOS.CustomerReference) >0 then ',' ELSE '' END + WOS.CustomerReference  
					 FROM SalesOrder WOS WITH (NOLOCK) 
					 INNER JOIN DBO.SalesOrderBillingInvoicing sobis WITH(NOLOCK) on  sobis.SalesOrderId=WOS.SalesOrderId
					 Where sobi.CustomerId = sobis.CustomerId  and sobis.InvoiceStatus = 'Invoiced'
					 FOR XML PATH('')), 1, 1, '') CustomerReference  
				) D
				  Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(S.PostedDate) >0 then ',' ELSE '' END + CONVERT(VARCHAR(max), S.PostedDate, 110)   
					 FROM SalesOrderBillingInvoicing S WITH (NOLOCK)  
					 Where sobi.CustomerId = s.CustomerId AND S.InvoiceStatus = 'Invoiced' 
					 FOR XML PATH('')), 1, 1, '') InvoiceDateNew  
				) E
			 WHERE  C.MasterCompanyId=@MasterCompanyId AND sobi.InvoiceStatus = 'Invoiced'	GROUP BY C.CustomerId  --,SO.CustomerReference,sobi.InvoiceNo,sobi.SOBillingInvoicingId
						), Result AS(
				SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CTE.currencyCode) as  'currencyCode',
					   --ISNULL(SUM(CTE.PaymentAmount),0) as 'BalanceAmount',
					   ISNULL(SUM(CTE.BalanceAmount - CTE.RemainingAmount),0)as 'CurrentlAmount',                    
					   ISNULL(SUM(CTE.RemainingAmount),0) as 'PaymentAmount',
					   ISNULL(Max(Case when CTECalculation.paidbylessthen0days > 0 then  (CTECalculation.paidbylessthen0days + Isnull(E.CMAmount,0)) else (CTECalculation.paidbylessthen0days) end),0) as 'Amountpaidbylessthen0days',  
					   ISNULL(Max(Case when CTECalculation.paidby30days > 0 then  (CTECalculation.paidby30days + Isnull(E.CMAmount,0)) else (CTECalculation.paidby30days) end),0) as 'Amountpaidby30days', 
					   ISNULL(Max(Case when CTECalculation.paidby60days > 0 then  (CTECalculation.paidby60days + Isnull(E.CMAmount,0)) else (CTECalculation.paidby60days) end),0) as 'Amountpaidby60days', 
					   ISNULL(Max(Case when CTECalculation.paidby90days > 0 then  (CTECalculation.paidby90days + Isnull(E.CMAmount,0)) else (CTECalculation.paidby90days) end),0) as 'Amountpaidby90days', 
					   ISNULL(Max(Case when CTECalculation.paidby120days > 0 then  (CTECalculation.paidby120days + Isnull(E.CMAmount,0)) else (CTECalculation.paidby120days) end),0) as 'Amountpaidby120days', 
					   ISNULL(Max(Case when CTECalculation.paidbymorethan120days > 0 then  (CTECalculation.paidbymorethan120days + Isnull(E.CMAmount,0)) else (CTECalculation.paidbymorethan120days) end),0) as 'Amountpaidbymorethan120days', 
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(CTE.ManagementStructureId) as ManagementStructureId,
					   Max(ctm.Name) as 'Terms',
					   DATEADD(day, max(CTE.TermDays), Max(CTE.PostedDate)) as 'DueDate',
					   ISNULL(SUM(CTE.RemainingAmount) + Max(isnull(E.CMAmount,0)),0) as 'BalanceAmount',
					   SUM(ISNULL(CTE.InvoiceAmount,0)) as 'InvoiceAmount',
					   SUM(ISNULL(CTE.FixRateAmount,0)) as 'FixRateAmount',
					   SUM(ISNULL(CTE.InvoicePaidAmount,0)) as 'InvoicePaidAmount',
					   Max(AB.InvoicePaidDate) as 'InvoicePaidDateType',
					   ISNULL(max(E.CMAmount),0) as 'CMAmount',
					   Max(F.CMDate) as 'CMDateType',
					   Max(A.InvoiceNo) as 'InvoiceNoType',
					   Max(B.InvoiceDate) as 'InvoiceDateType',
					   Max(D.CustomerRef) as 'CustomerRefType',
					   ISNULL(SUM(CTE.AdjustMentAmount),0) as 'AdjustMentAmount',
					   Max(AA.ReceiptNo) as 'PaymentRefType',
					   Max(G.Salesperson) as 'SalespersonType',
					   Max(AB.InvoicePaidDate)  as 'AdjustMentDateType',
					   'AR-Inv' AS 'DocType',
					   ISNULL(Max(E.CMCount),0) as 'CMCount',
					   Max(CTE.AdjustMentAmountType) AS 'AdjustMentAmountType',
					   (Case When sum(CTE.InvoiceCount) > 1 Then 'Multiple' ELse Max(A.InvoiceNo) End)  as 'InvoiceNo',
					   (Case When sum(CTE.InvoiceCount) > 1 Then 'Multiple' ELse Max(B.InvoiceDate) End)  AS InvoiceDate,
					   (Case When sum(CTE.InvoiceCount) > 1 Then 'Multiple' ELse Max(Isnull(G.Salesperson,'Unassigned')) End)  AS Salesperson,
					   (Case When sum(CTE.InvoiceCount) > 1 Then 'Multiple' ELse Max(D.CustomerRef) End)  AS CustomerRef,
					   (Case When sum(CTE.PaymentCount) > 1 Then 'Multiple' ELse Max(AB.InvoicePaidDate) End)  AS InvoicePaidDate,
					   (Case When ISNULL(SUM(CTE.AdjustMentAmount),0) > 1 Then 'Multiple' ELse '' End)  AS AdjustMentDate,
					   (Case When sum(CTE.PaymentCount) > 1 Then 'Multiple' ELse Max(AA.ReceiptNo) End)  AS PaymentRef,
					   (Case When Max(E.CMCount) > 1 Then 'Multiple' ELse Max(F.CMDate) End)  as 'CMDate'
					   FROM dbo.Customer C WITH (NOLOCK) 
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN CTE as CTE WITH (NOLOCK) ON CTE.CustomerId = C.CustomerId 
			   INNER JOIN CTECalculation as CTECalculation WITH (NOLOCK) ON CTECalculation.CustomerId = C.CustomerId 
			   INNER JOIN CustomerFinancial ctf WITH(NOLOCK) ON ctf.CustomerId = C.CustomerId
			   LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = ctf.CreditTermsId
			   Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(S.InvoiceNo) >0 then ',' ELSE '' END + s.InvoiceNo  
					 FROM CTE S WITH (NOLOCK)  
					 Where C.CustomerId = s.CustomerId 
					 FOR XML PATH('')), 1, 1, '') InvoiceNo  
				) A
				 Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(S.ReceiptNo) >0 then ',' ELSE '' END + s.ReceiptNo  
					 FROM CTE S WITH (NOLOCK)  
					 Where C.CustomerId = s.CustomerId 
					 FOR XML PATH('')), 1, 1, '') ReceiptNo  
				) AA
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(S.InvoiceDate) >0 then ',' ELSE '' END + S.InvoiceDate  
					 FROM CTE S WITH (NOLOCK)  
					 Where C.CustomerId = s.CustomerId 
					 FOR XML PATH('')), 1, 1, '') InvoiceDate  
				) B
					Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(S.InvoicePaidDate) >0 then ',' ELSE '' END + CONVERT(VARCHAR(max), S.InvoicePaidDate, 110)  
					 FROM CTE S WITH (NOLOCK)  
					 Where C.CustomerId = s.CustomerId 
					 FOR XML PATH('')), 1, 1, '') InvoicePaidDate  
				) AB
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(S.CustomerRef) >0 then ',' ELSE '' END + S.CustomerRef  
					 FROM CTE S WITH (NOLOCK)  
					 Where C.CustomerId = s.CustomerId 
					 FOR XML PATH('')), 1, 1, '') CustomerRef  
				) D
				OUTER APPLY
			   (
					SELECT sum(CMD.Amount)  AS 'CMAmount',count(CM.CreditMemoHeaderId) as 'CMCount'
					FROM DBO.CreditMemoDetails CMD WITH (NOLOCK)
					INNER JOIN DBO.CreditMemo CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId 
					Where  CM.CustomerId = C.CustomerId GROUP BY CM.CustomerId 
		       ) E

			     OUTER APPLY
			   (
					 SELECT   
					 STUFF((SELECT CASE WHEN LEN(CM.CreatedDate) >0 then ',' ELSE '' END + CONVERT(VARCHAR(max), CM.CreatedDate, 110)  
					 FROM CreditMemo CM WITH (NOLOCK)  
					 INNER JOIN DBO.CreditMemoDetails CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId 
					 Where C.CustomerId = CM.CustomerId 
					 FOR XML PATH('')), 1, 1, '') CMDate  
		       ) F
			   Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(S.SalesPerson) >0 then ',' ELSE '' END + S.SalesPerson  
					 FROM CTE S WITH (NOLOCK)  
					 Where C.CustomerId = s.CustomerId 
					 FOR XML PATH('')), 1, 1, '') SalesPerson  
				) G
			   WHERE  C.MasterCompanyId=@MasterCompanyId	GROUP BY C.CustomerId


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
					(ISNULL(@DueDate,'') ='' OR CAST(DueDate AS Date)=CAST(@DueDate AS date)) AND
					(ISNULL(@InvoicePaidDate,'') ='' OR CAST(InvoicePaidDate AS Date)=CAST(@InvoicePaidDate AS date)) AND
					(ISNULL(@CMDate,'') ='' OR CAST(CMDate AS Date)=CAST(@CMDate AS date)) AND
					(ISNULL(@InvoiceDate,'') ='' OR CAST(InvoiceDate AS Date)=CAST(@InvoiceDate AS date)) AND
					(ISNULL(@AdjustMentDate,'') ='' OR CAST(AdjustMentDate AS Date)=CAST(@AdjustMentDate AS date)) AND
					
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
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
		end
		
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
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@CustName, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@CustomerCode, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@CustomertType , '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@currencyCode , '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@BalanceAmount, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@CurrentlAmount, '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@Amountpaidby30days, '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@Amountpaidby60days, '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@Amountpaidby90days , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@Amountpaidby120days , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@Amountpaidbymorethan120days , '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@LegelEntity , '') AS varchar(100))
			  + '@Parameter19 = ''' + CAST(ISNULL(@EmployeeId , '') AS varchar(100))	
			  + '@Parameter20 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter21 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter23 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter24 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
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