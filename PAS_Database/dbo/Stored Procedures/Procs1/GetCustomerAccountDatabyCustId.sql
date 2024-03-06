﻿/*************************************************************           
 ** File:   [GetCustomerAccountDatabyCustId]
 ** Author: unknown
 ** Description: This stored procedure is used to Get CustomerAccountData by CustId
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1					unknown			Created
	2	01/31/2024		Devendra Shekh	added isperforma Flage for WO
	3	01/02/2024	    AMIT GHEDIYA	added isperforma Flage for SO
	4	15/02/2024	    Devendra Shekh	removed isperforma flage
	5	19/02/2024	    Devendra Shekh	added isinvoiceposted flage for wo
	6	27/02/2024	    AMIT GHEDIYA	added IsBilling flage for SO
	7	28/02/2024	    Devendra Shekh	changes for amount calculation based on isproforma for wo and so
	8	06/02/2024	    Devendra Shekh	calculation issue resolved for wo and so

-- EXEC GeSOWOtInvoiceDate '74'  
************************************************************************/
-- EXEC [dbo].[GetCustomerAccountDatabyCustId] 13
CREATE   PROCEDURE [dbo].[GetCustomerAccountDatabyCustId]
	@customerId bigint = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	
		DECLARE @SOMSModuleID INT = 17,@WOMSModuleID INT = 12;
		 ;WITH CTE AS(
						SELECT DISTINCT (C.CustomerId) as CustomerId,

                       ((ISNULL(C.[Name],''))) 'CustName' ,
					   ((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       (CT.CustomerTypeName) 'CustomertType' ,
					   (CR.Code) as  'currencyCode',
					   --(wobi.GrandTotal) as 'BalanceAmount',
					   CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.GrandTotal) ELSE 0 END AS BalanceAmount,
					   (wobi.GrandTotal - wobi.RemainingAmount)as 'CurrentlAmount',            
					   CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.RemainingAmount) ELSE 
						   CASE WHEN DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)))) END END AS PaymentAmount,
					   --(wobi.RemainingAmount)as 'PaymentAmount',
					   (wobi.InvoiceNo) as 'InvoiceNo',
			           (wobi.InvoiceDate) as 'InvoiceDate',
						CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 1 THEN RemainAmountData.InvoiceRemainingAmount
							 ELSE (CASE WHEN DaysData.CreditRemainingDays <= 0 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidbylessthen0days,
						CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 1 THEN 0
							 ELSE (CASE WHEN DaysData.CreditRemainingDays > 0 AND DaysData.CreditRemainingDays <= 30 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidby30days,
						CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 1 THEN 0
							 ELSE (CASE WHEN DaysData.CreditRemainingDays > 30 AND DaysData.CreditRemainingDays<= 60 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidby60days,
						CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 1 THEN 0
							 ELSE (CASE WHEN DaysData.CreditRemainingDays > 60 AND DaysData.CreditRemainingDays <= 90 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidby90days,
						CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 1 THEN 0
							 ELSE (CASE WHEN DaysData.CreditRemainingDays > 90 AND DaysData.CreditRemainingDays <= 120 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidby120days,
						CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 1 THEN 0
							 ELSE (CASE WHEN DaysData.CreditRemainingDays > 120 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidbymorethan120days,
					   Le.Name as 'LegelEntity',	
                       (C.UpdatedBy) as UpdatedBy,
					   (wop.ManagementStructureId) as ManagementStructureId
			   FROM dbo.WorkOrderBillingInvoicing wobi WITH (NOLOCK) 
			  
			   INNER JOIN dbo.[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = wobi.WorkOrderId
			   INNER JOIN dbo.Customer c  WITH (NOLOCK) ON C.CustomerId=WO.CustomerId
			   --LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.[Name] = wo.CreditTerms
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId and wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID AND ISNULL(wobii.IsInvoicePosted, 0) = 0
		 	   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			   --INNER JOIN InvoicePayments ipy WITH(NOLOCK) ON ipy.SOBillingInvoicingId = wobi.BillingInvoicingId AND ipy.InvoiceType=2
			   INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID
			   Left JOIN DBO.ManagementStructureLevel MSL WITH(NOLOCK) on MSL.ID = MSD.Level1Id
			   Left JOIN DBO.LegalEntity Le WITH(NOLOCK) on MSL.LegalEntityId = Le.LegalEntityId
			   LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId
			   OUTER APPLY (SELECT DATEDIFF(DAY, CAST(CAST(wobi.PostedDate AS datetime) + (CASE 
									WHEN ctm.Code IN ('COD', 'CIA', 'CreditCard', 'PREPAID') THEN -1 
									ELSE ISNULL(ctm.NetDays, 0) END) AS date), GETUTCDATE()) AS CreditRemainingDays) AS DaysData
			   OUTER APPLY (SELECT CASE WHEN ISNULL(wobi.IsPerformaInvoice, 0) = 0 THEN (wobi.RemainingAmount) 
									ELSE (0 - (ISNULL(wobi.GrandTotal,0) - (ISNULL(wobi.RemainingAmount,0)))) END AS InvoiceRemainingAmount) AS RemainAmountData
			   OUTER APPLY (SELECT nwop.WorkOrderId, SUM(ISNULL(nwobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nwobi.DepositAmount,0)) as OriginalDepositAmt  FROM [dbo].WorkOrderPartNumber nwop WITH (NOLOCK)  
							INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] nwobii WITH(NOLOCK) on nwop.ID = nwobii.WorkOrderPartId AND ISNULL(nwobii.isPerformaInvoice, 0) = 1
							INNER JOIN [dbo].[WorkOrderBillingInvoicing] nwobi WITH(NOLOCK) on nwobii.BillingInvoicingId = nwobi.BillingInvoicingId AND ISNULL(nwobi.isPerformaInvoice, 0) = 1
							and nwobii.WorkOrderPartId = nwop.ID WHERE WO.WorkOrderId = nwop.WorkOrderId GROUP BY nwop.WorkOrderId) AS DepositData
			  WHERE  wobi.InvoiceStatus = 'Invoiced' 		     
					AND C.CustomerId= @customerId   
					AND ((ISNULL(wobi.IsPerformaInvoice, 0) = 0 AND (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0)) = (ISNULL(wobi.GrandTotal,0) - ISNULL(wobi.RemainingAmount,0)) AND wobi.RemainingAmount > 0) 
					OR (ISNULL(wobi.IsPerformaInvoice, 0) = 1 AND (ISNULL(wobi.GrandTotal, 0) - ISNULL(wobi.RemainingAmount, 0)) > 0 AND DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt != 0))
				    AND ISNULL(wobi.IsInvoicePosted, 0) = 0
			UNION ALL
			SELECT DISTINCT (C.CustomerId) as CustomerId,
                       ((ISNULL(C.[Name],''))) 'CustName' ,
					   ((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       (CT.CustomerTypeName) 'CustomertType' ,
					   (CR.Code) as  'currencyCode',
					   CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.GrandTotal) ELSE 0 END AS BalanceAmount,
					   (sobi.GrandTotal - sobi.RemainingAmount)as 'CurrentlAmount', 
					   CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.RemainingAmount) ELSE 
							CASE WHEN DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt = 0 THEN 0 ELSE (0 - (ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)))) END END AS PaymentAmount,
					   (sobi.InvoiceNo) as 'InvoiceNo',
			           (sobi.InvoiceDate) as 'InvoiceDate',
                       CASE WHEN ISNULL(sobi.IsProforma, 0) = 1 THEN RemainAmountData.InvoiceRemainingAmount
							 ELSE (CASE WHEN DaysData.CreditRemainingDays <= 0 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidbylessthen0days,
						CASE WHEN ISNULL(sobi.IsProforma, 0) = 1 THEN 0
							 ELSE (CASE WHEN DaysData.CreditRemainingDays > 0 AND DaysData.CreditRemainingDays <= 30 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidby30days,
						CASE WHEN ISNULL(sobi.IsProforma, 0) = 1 THEN 0
							 ELSE (CASE WHEN DaysData.CreditRemainingDays > 30 AND DaysData.CreditRemainingDays<= 60 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidby60days,
						CASE WHEN ISNULL(sobi.IsProforma, 0) = 1 THEN 0
							 ELSE (CASE WHEN DaysData.CreditRemainingDays > 60 AND DaysData.CreditRemainingDays <= 90 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidby90days,
						CASE WHEN ISNULL(sobi.IsProforma, 0) = 1 THEN 0
							 ELSE (CASE WHEN DaysData.CreditRemainingDays > 90 AND DaysData.CreditRemainingDays <= 120 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidby120days,
						CASE WHEN ISNULL(sobi.IsProforma, 0) = 1 THEN 0
							 ELSE (CASE WHEN DaysData.CreditRemainingDays > 120 THEN RemainAmountData.InvoiceRemainingAmount ELSE 0 END) END AS Amountpaidbymorethan120days,
					    Le.Name as 'LegelEntity',
                       (C.UpdatedBy) as UpdatedBy,
					   (SO.ManagementStructureId) as ManagementStructureId
			   FROM dbo.SalesOrderBillingInvoicing sobi WITH (NOLOCK) 
			   INNER JOIN dbo.[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId
			   INNER JOIN dbo.Customer c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId
			    --LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.[Name] = SO.CreditTermName
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN DBO.SalesOrderPart sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			   INNER JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId AND ISNULL(sobii.IsBilling, 0) = 0	 
			   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
			   --INNER JOIN InvoicePayments ipy WITH(NOLOCK) ON ipy.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND ipy.InvoiceType=1
			   INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
		 	   Left JOIN DBO.ManagementStructureLevel MSL WITH(NOLOCK) on MSL.ID = MSD.Level1Id
			   Left JOIN DBO.LegalEntity Le WITH(NOLOCK) on MSL.LegalEntityId = Le.LegalEntityId
			   LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId
			   OUTER APPLY (SELECT DATEDIFF(DAY, CAST(CAST(sobi.PostedDate AS datetime) + (CASE 
									WHEN ctm.Code IN ('COD', 'CIA', 'CreditCard', 'PREPAID') THEN -1 
									ELSE ISNULL(ctm.NetDays, 0) END) AS date), GETUTCDATE()) AS CreditRemainingDays) AS DaysData
			   OUTER APPLY (SELECT CASE WHEN ISNULL(sobi.IsProforma, 0) = 0 THEN (sobi.RemainingAmount) 
									ELSE (0 - (ISNULL(sobi.GrandTotal,0) - (ISNULL(sobi.RemainingAmount,0)))) END AS InvoiceRemainingAmount) AS RemainAmountData

			   OUTER APPLY (SELECT nwop.SalesOrderId, SUM(ISNULL(nwobi.UsedDeposit,0)) as UsedDepositAmt, SUM(ISNULL(nwobi.DepositAmount,0)) as OriginalDepositAmt  FROM [dbo].SalesOrderPart nwop WITH (NOLOCK)  
							INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] nwobii WITH(NOLOCK) on nwop.SalesOrderPartId = nwobii.SalesOrderPartId AND ISNULL(nwobii.IsProforma, 0) = 1
							INNER JOIN [dbo].[SalesOrderBillingInvoicing] nwobi WITH(NOLOCK) on nwobii.SOBillingInvoicingId = nwobi.SOBillingInvoicingId AND ISNULL(nwobi.IsProforma, 0) = 1
							and nwobii.SalesOrderPartId = nwop.SalesOrderPartId WHERE so.SalesOrderId = nwop.SalesOrderId GROUP BY nwop.SalesOrderId) AS DepositData
			  WHERE   sobi.InvoiceStatus = 'Invoiced' AND ISNULL(sobi.IsBilling, 0) = 0	     
					AND C.CustomerId= @customerId 
					AND ((ISNULL(sobi.IsProforma, 0) = 0 AND (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0)) = (ISNULL(sobi.GrandTotal,0) - ISNULL(sobi.RemainingAmount,0)) AND sobi.RemainingAmount > 0) 
				    OR (ISNULL(sobi.IsProforma, 0) = 1 AND (ISNULL(sobi.GrandTotal, 0) - ISNULL(sobi.RemainingAmount, 0)) > 0 AND DepositData.OriginalDepositAmt - DepositData.UsedDepositAmt != 0))
						)
						
						, Result AS(
				SELECT DISTINCT 
				       (CTE.CustomerId) as CustomerId ,
                       ((ISNULL(CTE.CustName,''))) 'CustName' ,
					   ((ISNULL(CTE.CustomerCode,''))) 'CustomerCode' ,
                       (CTE.CustomertType) 'CustomertType' ,
					   (CTE.currencyCode) as  'currencyCode',
					   --(CTE.BalanceAmount) as 'BalanceAmount',
					   (CTE.PaymentAmount) as 'BalanceAmount',
					   --(CTE.BalanceAmount - CTE.PaymentAmount)as 'CurrentlAmount',
					   (CTE.Amountpaidbylessthen0days) as 'Amountpaidbylessthen0days',   
					   (CTE.PaymentAmount) as 'PaymentAmount',
					   (CTE.InvoiceNo) as 'InvoiceNo',
			           (CTE.InvoiceDate) as 'InvoiceDate',
					   (CTE.Amountpaidby30days) as 'Amountpaidby30days',      
                       (CTE.Amountpaidby60days) as 'Amountpaidby60days',
					   (CTE.Amountpaidby90days) as 'Amountpaidby90days',
					   (CTE.Amountpaidby120days) as 'Amountpaidby120days',
					   (CTE.Amountpaidbymorethan120days) as 'Amountpaidbymorethan120days',  
					   CTE.LegelEntity as 'LegelEntity',	
					   (C.CreatedDate) AS CreatedDate,
                       (C.UpdatedDate) AS UpdatedDate,
					   (C.CreatedBy) as CreatedBy,
                       (C.UpdatedBy) as UpdatedBy,
					   (CTE.ManagementStructureId) as ManagementStructureId
			   FROM CTE as CTE WITH (NOLOCK) 
			   INNER JOIN Customer as c WITH (NOLOCK) ON c.CustomerId = CTE.CustomerId 
			   WHERe CTE.CustomerId= @customerId --GROUP BY CTE.InvoiceNo


			) , ResultCount AS(SELECT COUNT(CustomerId) AS totalItems FROM Result)
			
			SELECT * INTO #TempResult FROM  Result
			SELECT * FROM #TempResult

			 

	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetCustomerAccountDatabyCustId' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@customerId AS VARCHAR(10)), '') + ''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
                @DatabaseName           = @DatabaseName
                , @AdhocComments          = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END