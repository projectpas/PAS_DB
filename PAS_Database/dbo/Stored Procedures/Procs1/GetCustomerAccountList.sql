/*************************************************************                   
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
	2    05-01-2024        Moin Bloch      Modified (Formated The SP)
	3	 01/31/2024		Devendra Shekh	   added isperforma Flage for WO
	4	 01/02/2024	    AMIT GHEDIYA	   added isperforma Flage for SO
	5	 01/02/2024	    Devendra Shekh	   removed flage to proformainvoice for WO and SO
	6	 19/02/2024	    Devendra Shekh	   added isinvoiceposted flage for wo
	7	 27/02/2024	    AMIT GHEDIYA	   added ISBilling flage for SO
	8	 28/02/2024	    Devendra Shekh	   changes for amount calculation based on isproforma for wo and so
	
    EXEC [dbo].[GetCustomerAccountList] 1,10,'CreatedDate',-1,'',2,'','','','',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',61,'',NULL,'',NULL,'arbalanceonly',1
***************************************************************************************************/ 
CREATE   PROCEDURE [dbo].[GetCustomerAccountList]
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
@MasterCompanyId bigint = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		IF (@viewType='all')
		BEGIN
			SET @viewType=NULL
		END 
		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
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
		
		--BEGIN TRANSACTION
		--BEGIN
		 DECLARE @SOMSModuleID INT = 17,@WOMSModuleID INT = 12;
		 ;WITH CTEData AS(
			select ct.CustomerId,CAST(sobi.InvoiceDate as date) AS InvoiceDate,
			CASE WHEN ISNULL(sobi.IsProforma, 0) = 0  THEN sobi.GrandTotal ELSE 0 END AS GrandTotal,
			CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.RemainingAmount) ELSE (0 - (ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)))) END AS RemainingAmount,
			DATEDIFF(DAY, CAST(sobi.PostedDate as date), GETUTCDATE()) AS dayDiff,
			ctm.NetDays,
			--(DATEDIFF(DAY, CASt(sobi.InvoiceDate as date), GETDATE()) - ctm.NetDays) AS CreditRemainingDays
			--(ISNULL(ctm.NetDays,0) - DATEDIFF(DAY, CASt(sobi.PostedDate as date), GETDATE())) AS CreditRemainingDays
			DATEDIFF(DAY, CAST(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETUTCDATE()) AS CreditRemainingDays,
			ISNULL(sobi.IsProforma, 0) AS IsPerformaInvoice
			FROM [dbo].[SalesOrderBillingInvoicing] sobi WITH(NOLOCK)
			INNER JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId
			INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = so.CustomerId
			 LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = so.CreditTermId
			--where ct.CustomerId=58 AND sobi.InvoiceStatus='Reviewed'
			WHERE sobi.InvoiceStatus = 'Invoiced' AND ISNULL(sobi.IsBilling, 0) = 0
			AND ISNULL(sobi.IsBilling, 0) = 0
			GROUP BY sobi.InvoiceDate,ct.CustomerId,sobi.GrandTotal,sobi.RemainingAmount,ctm.NetDays,PostedDate,ctm.Code,sobi.IsProforma
			
			UNION ALL
			
			select ct.CustomerId,CAST(wobi.InvoiceDate as date) AS InvoiceDate,
			CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0  THEN wobi.GrandTotal ELSE 0 END AS GrandTotal,
			CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.RemainingAmount) ELSE (0 - (ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)))) END AS RemainingAmount,
			DATEDIFF(DAY, CAST(wobi.PostedDate as date), GETUTCDATE()) AS dayDiff,
			ctm.NetDays,
			--(DATEDIFF(DAY, CASt(wobi.InvoiceDate as date), GETDATE()) - ctm.NetDays) AS CreditRemainingDays
			--(ISNULL(ctm.NetDays,0) - DATEDIFF(DAY, CASt(wobi.PostedDate as date), GETDATE())) AS CreditRemainingDays
			--DATEDIFF(DAY, CASt(CAST(wobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE()) AS CreditRemainingDays
			DATEDIFF(DAY, CAST(CAST(wobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETUTCDATE()) AS CreditRemainingDays,
			ISNULL(wobi.IsPerformaInvoice, 0) AS IsPerformaInvoice
			from [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK)
			INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.WorkOrderId = wobi.WorkOrderId
			INNER JOIN [dbo].[Customer] ct WITH(NOLOCK) ON ct.CustomerId = wo.CustomerId
			--LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms
			LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId
			--where ct.CustomerId=58 AND wobi.InvoiceStatus='Reviewed'
			WHERE wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0
			AND ISNULL(wobi.IsInvoicePosted, 0) = 0
			GROUP BY wobi.InvoiceDate,ct.CustomerId,wobi.GrandTotal,wobi.RemainingAmount,ctm.NetDays,PostedDate,ctm.Code,wobi.IsPerformaInvoice
			
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
					   --SUM(wobi.GrandTotal) as 'BalanceAmount',
					   ISNULL(SUM(wobi.GrandTotal - wobi.RemainingAmount),0)as 'CurrentlAmount',   
					   SUM(CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0  THEN (wobi.RemainingAmount) ELSE (0 - ISNULL((wobi.GrandTotal - wobi.RemainingAmount),0))END) AS 'PaymentAmount',   
					   --SUM(wobi.RemainingAmount)as 'PaymentAmount',
					   SUM(0) as 'Amountpaidbylessthen0days',      
                       SUM(0) as 'Amountpaidby30days',      
                       SUM(0) as 'Amountpaidby60days',
					   SUM(0) as 'Amountpaidby90days',
					   SUM(0) as 'Amountpaidby120days',
					   SUM(0) as 'Amountpaidbymorethan120days',  
					   Max('') as 'LegelEntity',	
                       --MIN(C.IsActive) AS IsActive,
                       --MIN(C.IsDeleted)AS IsDeleted,
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(wop.ManagementStructureId) as ManagementStructureId,
					   STUFF((SELECT ', ' + WP.CustomerReference
							FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)
							INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId
							WHERE WI.BillingInvoicingId = wobi.BillingInvoicingId
							FOR XML PATH('')), 1, 1, '') 
							AS 'Reference'
			   FROM [dbo].[Customer] C WITH (NOLOCK) 
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			   INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN [dbo].[WorkOrderBillingInvoicing] wobi WITH(NOLOCK) on wobi.IsVersionIncrease=0 AND wobi.WorkOrderId=WO.WorkOrderId AND ISNULL(wobi.IsInvoicePosted, 0) = 0
		 	   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			   INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID
			  WHERE ((ISNULL(C.IsDeleted,0)=0) AND (@IsActive IS NULL OR C.IsActive=@IsActive))			     
					AND C.MasterCompanyId=@MasterCompanyId AND wobi.InvoiceStatus = 'Invoiced'	GROUP BY C.CustomerId,wop.CustomerReference,wobi.BillingInvoicingId,wobi.IsPerformaInvoice
UNION ALL
SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CR.Code) as  'currencyCode',
					   SUM(CASE WHEN ISNULL(sobi.IsProforma, 0) = 0  THEN (sobi.GrandTotal) ELSE 0 END) AS 'BalanceAmount',
					   --SUM(sobi.GrandTotal) as 'BalanceAmount',
					   ISNULL(SUM(sobi.GrandTotal - sobi.RemainingAmount),0)as 'CurrentlAmount',
					   SUM(CASE WHEN ISNULL(sobi.IsProforma, 0) = 0  THEN (sobi.RemainingAmount) ELSE (0 - ISNULL((sobi.GrandTotal - sobi.RemainingAmount),0))END) AS 'PaymentAmount',
					   --SUM(sobi.RemainingAmount)as 'PaymentAmount',
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
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(SO.ManagementStructureId) as ManagementStructureId,
					   STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)
							INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId
							WHERE SI.SOBillingInvoicingId = sobi.SOBillingInvoicingId
							FOR XML PATH('')), 1, 1, '')
							AS 'Reference'
			   FROM [dbo].[Customer] C WITH (NOLOCK) 
			   INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
			   INNER JOIN [dbo].[SalesOrderBillingInvoicing] sobi WITH (NOLOCK) on sobi.SalesOrderId = so.SalesOrderId AND ISNULL(sobi.IsBilling, 0) = 0
			   INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = sobi.CurrencyId
			   INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
		 	  WHERE ((ISNULL(C.IsDeleted,0)=0) AND (@IsActive IS NULL OR C.IsActive=@IsActive))			     
					AND C.MasterCompanyId=@MasterCompanyId AND sobi.InvoiceStatus = 'Invoiced'	GROUP BY C.CustomerId,SO.CustomerReference,sobi.SOBillingInvoicingId,sobi.IsProforma
						), Result AS(
				SELECT DISTINCT C.CustomerId,
                       Max((ISNULL(C.[Name],''))) 'CustName' ,
					   Max((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       Max(CT.CustomerTypeName) 'CustomertType' ,
					   Max(CTE.currencyCode) as  'currencyCode',
					   --SUM(CTE.BalanceAmount) as 'BalanceAmount',
					   ISNULL(SUM(CTE.PaymentAmount),0) as 'BalanceAmount',
					   ISNULL(SUM(CTE.BalanceAmount - CTE.PaymentAmount),0)as 'CurrentlAmount',                    
					   ISNULL(SUM(CTE.PaymentAmount),0) as 'PaymentAmount',
        --               SUM(0) as 'Amountpaidby30days',      
        --               SUM(0) as 'Amountpaidby60days',
					   --SUM(0) as 'Amountpaidby90days',
					   --SUM(0) as 'Amountpaidby120days',
					   --SUM(0) as 'Amountpaidbymorethan120days',
					   MAX(CTECalculation.paidbylessthen0days) as 'Amountpaidbylessthen0days',      
					   MAX(CTECalculation.paidby30days) as 'Amountpaidby30days',      
                       MAX(CTECalculation.paidby60days) as 'Amountpaidby60days',
					   MAX(CTECalculation.paidby90days) as 'Amountpaidby90days',
					   MAX(CTECalculation.paidby120days) as 'Amountpaidby120days',
					   MAX(CTECalculation.paidbymorethan120days) as 'Amountpaidbymorethan120days',  
					   Max('') as 'LegelEntity',	
                       --MIN(C.IsActive) AS IsActive,
                       --MIN(C.IsDeleted)AS IsDeleted,
					   MAX(C.CreatedDate) AS CreatedDate,
                       MAX(C.UpdatedDate) AS UpdatedDate,
					   MAX(C.CreatedBy) as CreatedBy,
                       MAX(C.UpdatedBy) as UpdatedBy,
					   max(CTE.ManagementStructureId) as ManagementStructureId
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

            --END

			--COMMIT  TRANSACTION

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