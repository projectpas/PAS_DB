﻿/*************************************************************                   
 ** File:   [GetCustomerAccountList]                   
 ** Author:  unknown   
 ** Description: Get Data For Customer Account List
 ** Purpose:                 
 ** Date: 05-01-2024     
 ** PARAMETERS:         
 ** RETURN VALUE:       
 *************************************************************************************************                   
  ** Change History                   
 *************************************************************************************************                   
 ** S NO   Date            Author          Change Description                    
 ** --   --------         -------          --------------------------------   
	1                      unknown         Created            
	2    05-01-2024     Moin Bloch         Modified (Formated The SP)
	3	 01/31/2024		Devendra Shekh	   added isperforma Flage for WO
	4	 01/02/2024	    AMIT GHEDIYA	   added isperforma Flage for SO
	5	 01/02/2024	    Devendra Shekh	   removed flage to proformainvoice for WO and SO
	6	 19/02/2024	    Devendra Shekh	   added isinvoiceposted flage for wo
	7	 27/02/2024	    AMIT GHEDIYA	   added ISBilling flage for SO
	8	 28/02/2024	    Devendra Shekh	   changes for amount calculation based on isproforma for wo and so
	9    07/03/2024	    Devendra Shekh	   Amount Calculation issue resolved
	10   07/03/2024	    Hemant Saliya	   Verify SP and Joins
	11   19/03/2024     Bhargav Saliya  Get Days And NetDays From WO,SO and ESO Table instead of CreditTerms Table
	
    EXEC [dbo].[GetCustomerAccountList] 1,10,'CreatedDate',-1,'',2,'','','','',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',61,'',NULL,'',NULL,'arbalanceonly',1
***************************************************************************************************/ 
CREATE   PROCEDURE [dbo].[GetCustomerAccountList]
  @PageNumber                  INT = NULL,
  @PageSize                    INT = NULL,
  @SortColumn                  VARCHAR(50)=NULL,
  @SortOrder                   INT = NULL,
  @GlobalFilter                VARCHAR(50) = NULL,
  @StatusId                    INT = NULL,
  @CustName                    VARCHAR(50) = NULL,
  @CustomerCode                VARCHAR(50) = NULL,
  @CustomertType               VARCHAR(50) = NULL,
  @currencyCode                VARCHAR(50) = NULL,
  @BalanceAmount               DECIMAL(18,2) = NULL,
  @CurrentlAmount              DECIMAL(18,2) = NULL,
  @Amountpaidbylessthen0days   DECIMAL(18,2) = NULL,
  @Amountpaidby30days          DECIMAL(18,2) = NULL,
  @Amountpaidby60days          DECIMAL(18,2) = NULL,
  @Amountpaidby90days          DECIMAL(18,2) = NULL,
  @Amountpaidby120days         DECIMAL(18,2) = NULL,
  @Amountpaidbymorethan120days DECIMAL(18,2) = NULL,
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
		BEGIN TRY

			DECLARE @RecordFrom INT;
			DECLARE @Count      INT;
			DECLARE @IsActive   BIT;
			SET @RecordFrom = (@PageNumber-1)*@PageSize;
			IF (@viewType='all')
			BEGIN
				SET @viewType=NULL
			END
			IF @SortColumn IS NULL
			BEGIN
				SET @SortColumn=Upper('CreatedDate')
			END
			ELSE
			BEGIN
				SET @SortColumn=Upper(@SortColumn)
			END
			IF(@StatusId=0)
			BEGIN
				SET @IsActive=0;
			END
			ELSE
			IF(@StatusId=1)
			BEGIN
				SET @IsActive=1;
			END
			ELSE
			BEGIN
				SET @IsActive=NULL;
			END
			DECLARE @SOMSModuleID INT = 17,
			@WOMSModuleID       INT = 12; ;
			;WITH NEWDepositAmt AS(
						 SELECT nso.SalesOrderId AS Id,nso.customerid, SUM(ISNULL(nsobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nsobi.DepositAmount,0)) as OriginalDepositAmt  
												FROM [dbo].SalesOrder nso WITH (NOLOCK)  
													INNER JOIN [dbo].SalesOrderPart nsop WITH(NOLOCK) on nsop.SalesOrderId = nso.SalesOrderId
													INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] nsobii WITH(NOLOCK) on nsop.SalesOrderPartId = nsobii.SalesOrderPartId AND ISNULL(nsobii.IsProforma, 0) = 1
													INNER JOIN [dbo].[SalesOrderBillingInvoicing] nsobi WITH(NOLOCK) on nsobii.SOBillingInvoicingId = nsobi.SOBillingInvoicingId AND ISNULL(nsobi.IsProforma, 0) = 1
													AND nsobii.SalesOrderPartId = nsop.SalesOrderPartId GROUP BY nso.SalesOrderId,nso.customerid
						 UNION ALL
		 
						 SELECT WO.WorkOrderId as Id, WO.customerid, SUM(ISNULL(WOBI.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(WOBI.DepositAmount,0)) as OriginalDepositAmt  
												FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) 
												   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId	= WOBI.WorkOrderId
													GROUP BY WO.WorkOrderId, WO.customerid
			), CTEData AS(
			select ct.CustomerId,CAST(sobi.InvoiceDate as date) AS InvoiceDate,
			CASE WHEN ISNULL(sobi.IsProforma, 0) = 0  THEN sobi.GrandTotal ELSE 0 END AS GrandTotal,
			CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.RemainingAmount) ELSE 
				 CASE WHEN DSA.OriginalDepositAmt - DSA.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)))) END END AS RemainingAmount,
			DATEDIFF(DAY, CAST(sobi.PostedDate as date), GETUTCDATE()) AS dayDiff,
			so.NetDays,
			DATEDIFF(DAY, CAST(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(so.NetDays,0) END) as date), GETUTCDATE()) AS CreditRemainingDays,
			ISNULL(sobi.IsProforma, 0) AS IsPerformaInvoice
			FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH(NOLOCK)
				INNER JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId
				INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId
				LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId
				LEFT JOIN NEWDepositAmt DSA ON DSA.Id = sobi.SalesOrderId
			WHERE sobi.InvoiceStatus = 'Invoiced' 
				AND ISNULL(sobi.IsBilling, 0) = 0
				AND ((ISNULL(sobi.IsProforma, 0) = 0 AND (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0)) = (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0))) 
				OR (ISNULL(sobi.IsProforma, 0) = 1 AND (ISNULL(sobi.GrandTotal, 0) - ISNULL(sobi.RemainingAmount, 0)) > 0 AND DSA.OriginalDepositAmt - DSA.UsedDepositAmt != 0))
			GROUP BY sobi.InvoiceDate,ct.CustomerId,sobi.GrandTotal,sobi.RemainingAmount,so.NetDays,PostedDate,ctm.Code,sobi.IsProforma,DSA.OriginalDepositAmt,DSA.UsedDepositAmt
			
			UNION ALL
			
			select ct.CustomerId,CAST(wobi.InvoiceDate as date) AS InvoiceDate,
			CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0  THEN wobi.GrandTotal ELSE 0 END AS GrandTotal,
			CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.RemainingAmount) ELSE 
						CASE WHEN DSA.OriginalDepositAmt - DSA.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)))) END END AS RemainingAmount,
			DATEDIFF(DAY, CAST(wobi.PostedDate as date), GETUTCDATE()) AS dayDiff,
			wo.NetDays,
			DATEDIFF(DAY, CAST(CAST(wobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(wo.NetDays,0) END) as date), GETUTCDATE()) AS CreditRemainingDays,
			ISNULL(wobi.IsPerformaInvoice, 0) AS IsPerformaInvoice
			FROM [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.WorkOrderId = wobi.WorkOrderId
				INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId
				LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId
				LEFT JOIN NEWDepositAmt DSA ON DSA.Id = wobi.WorkOrderId
			WHERE wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0
				AND ISNULL(wobi.IsInvoicePosted, 0) = 0
				AND ((ISNULL(wobi.IsPerformaInvoice, 0) = 0 AND (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0)) = (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0))) 
				OR (ISNULL(wobi.IsPerformaInvoice, 0) = 1 AND (ISNULL(wobi.GrandTotal, 0) - ISNULL(wobi.RemainingAmount, 0)) > 0 AND DSA.OriginalDepositAmt - DSA.UsedDepositAmt != 0))
			GROUP BY wobi.InvoiceDate,ct.CustomerId,wobi.GrandTotal,wobi.RemainingAmount,wo.NetDays,PostedDate,ctm.Code,wobi.IsPerformaInvoice,DSA.OriginalDepositAmt,DSA.UsedDepositAmt
			
			), CTECalculation AS(
			select
				CustomerId,
				SUM (CASE WHEN IsPerformaInvoice = 1 THEN RemainingAmount 
							ELSE (CASE WHEN CreditRemainingDays < 0 THEN RemainingAmount ELSE 0 END) END) AS paidbylessthen0days,
			    SUM (CASE WHEN IsPerformaInvoice = 1 THEN 0 
							ELSE (CASE WHEN CreditRemainingDays > 0 AND CreditRemainingDays <= 30 THEN RemainingAmount ELSE 0 END) END) AS paidby30days,
			    SUM (CASE WHEN IsPerformaInvoice = 1 THEN 0 
							ELSE (CASE WHEN CreditRemainingDays > 30 AND CreditRemainingDays <= 60 THEN RemainingAmount ELSE 0 END) END) AS paidby60days,
			    SUM (CASE WHEN IsPerformaInvoice = 1 THEN 0 
							ELSE (CASE WHEN CreditRemainingDays > 60 AND CreditRemainingDays <= 90 THEN RemainingAmount ELSE 0 END) END) AS paidby90days,
			    SUM (CASE WHEN IsPerformaInvoice = 1 THEN 0 
							ELSE (CASE WHEN CreditRemainingDays > 90 AND CreditRemainingDays <= 120 THEN RemainingAmount ELSE 0 END) END) AS paidby120days,
			    SUM (CASE WHEN IsPerformaInvoice = 1 THEN 0 
							ELSE (CASE WHEN CreditRemainingDays > 120 THEN RemainingAmount ELSE 0 END) END) AS paidbymorethan120days
			    from CTEData c group by CustomerId
			),CTE AS(
						SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CR.Code) as  'currencyCode',
					   SUM(CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0  THEN (wobi.GrandTotal) ELSE 0 END) AS 'BalanceAmount',
					   ISNULL(SUM(wobi.GrandTotal - wobi.RemainingAmount),0)as 'CurrentlAmount',   
					   SUM(CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.RemainingAmount) ELSE 
							    CASE WHEN DSA.OriginalDepositAmt - DSA.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)))) END END) AS 'PaymentAmount',   
					   SUM(0) as 'Amountpaidbylessthen0days',      
                       SUM(0) as 'Amountpaidby30days',      
                       SUM(0) as 'Amountpaidby60days',
					   SUM(0) as 'Amountpaidby90days',
					   SUM(0) as 'Amountpaidby120days',
					   SUM(0) as 'Amountpaidbymorethan120days',  
					   Max('') as 'LegelEntity',	
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy
			   FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) 
			   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId	= WOBI.WorkOrderId --AND WO.CustomerId = C.CustomerId
			   INNER JOIN [dbo].[Customer] C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
		 	   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			   LEFT JOIN NEWDepositAmt DSA ON DSA.Id = wobi.WorkOrderId
			  WHERE ((ISNULL(C.IsDeleted,0)=0) AND (@IsActive IS NULL OR C.IsActive=@IsActive))			     
					AND C.MasterCompanyId=@MasterCompanyId AND wobi.InvoiceStatus = 'Invoiced'	GROUP BY C.CustomerId
					,wobi.IsPerformaInvoice
			
			UNION ALL

			SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CR.Code) as  'currencyCode',
					   SUM(CASE WHEN ISNULL(sobi.IsProforma, 0) = 0  THEN (sobi.GrandTotal) ELSE 0 END) AS 'BalanceAmount',
					   ISNULL(SUM(sobi.GrandTotal - sobi.RemainingAmount),0)as 'CurrentlAmount',
					   SUM(CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.RemainingAmount) ELSE 
								CASE WHEN DSA.OriginalDepositAmt - DSA.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)))) END END) AS 'PaymentAmount',
					   SUM(0) as 'Amountpaidbylessthen0days',      
                       SUM(0) as 'Amountpaidby30days',      
                       SUM(0) as 'Amountpaidby60days',
					   SUM(0) as 'Amountpaidby90days',
					   SUM(0) as 'Amountpaidby120days',
					   SUM(0) as 'Amountpaidbymorethan120days',  
					   Max('') as 'LegelEntity',	
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy
			   FROM [dbo].[Customer] C WITH (NOLOCK) 
				   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				   INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				   INNER JOIN [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK) on sobi.SalesOrderId = so.SalesOrderId AND ISNULL(sobi.IsBilling, 0) = 0
				   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = sobi.CurrencyId
				   INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
				   LEFT JOIN NEWDepositAmt DSA ON DSA.Id = sobi.SalesOrderId
		 	  WHERE ((ISNULL(C.IsDeleted,0)=0) AND (@IsActive IS NULL OR C.IsActive=@IsActive))			     
					AND C.MasterCompanyId=@MasterCompanyId AND sobi.InvoiceStatus = 'Invoiced'	GROUP BY C.CustomerId ,SO.CustomerReference,sobi.IsProforma
						), Result AS(
				SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CTE.currencyCode) as  'currencyCode',
					   ISNULL(SUM(CTE.PaymentAmount),0) as 'BalanceAmount',
					   ISNULL(SUM(CTE.BalanceAmount - CTE.PaymentAmount),0)as 'CurrentlAmount',                    
					   ISNULL(SUM(CTE.PaymentAmount),0) as 'PaymentAmount',
					   MAX(CTECalculation.paidbylessthen0days) as 'Amountpaidbylessthen0days',      
					   MAX(CTECalculation.paidby30days) as 'Amountpaidby30days',      
                       MAX(CTECalculation.paidby60days) as 'Amountpaidby60days',
					   MAX(CTECalculation.paidby90days) as 'Amountpaidby90days',
					   MAX(CTECalculation.paidby120days) as 'Amountpaidby120days',
					   MAX(CTECalculation.paidbymorethan120days) as 'Amountpaidbymorethan120days',  
					   Max('') as 'LegelEntity',	
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy
			   FROM [dbo].[Customer] C WITH (NOLOCK) 
				   INNER JOIN[dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				   INNER JOIN CTE as CTE WITH (NOLOCK) ON CTE.CustomerId = C.CustomerId 
				   INNER JOIN CTECalculation as CTECalculation WITH (NOLOCK) ON CTECalculation.CustomerId = C.CustomerId 
				   INNER JOIN [dbo].[CustomerFinancial] ctf WITH(NOLOCK) ON ctf.CustomerId = C.CustomerId
			   WHERE ((ISNULL(C.IsDeleted,0)=0) AND (@IsActive IS NULL OR C.IsActive=@IsActive) AND (isnull(@viewType,'') = '' OR ctf.CreditLimit is not null))			     
					AND C.MasterCompanyId=@MasterCompanyId	GROUP BY C.CustomerId
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
					(LegelEntity LIKE '%' +@GlobalFilter+'%') OR
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
					(ISNULL(@LegelEntity,'') ='' OR LegelEntity LIKE '%' + @LegelEntity + '%') AND	
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
			CASE WHEN (@SortOrder=1  AND @SortColumn='LegelEntity')  THEN LegelEntity END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LegelEntity')  THEN LegelEntity END DESC,
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

	END TRY    
	BEGIN CATCH      
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