/*************************************************************             
 ** File:   [usprpt_GetSOBacklogReport]             
 ** Author:   Subhash saliya   
 ** Description: Get Data for Ar Aging Report  
 ** Purpose:           
 ** Date:   13-Julay-2022         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    13-Julay-2022 Subhash saliya      Created  

**************************************************************/  
Create   PROCEDURE [dbo].[usprpt_GetARAgingReport] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
 
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
  
		DECLARE @customerid varchar(40) = NULL,  
		@fromdate datetime,  
		@todate datetime, 
		@exludedebit varchar(40) = NULL,  
		@tagtype varchar(50) = NULL,
		@level1 VARCHAR(MAX) = NULL,
		@level2 VARCHAR(MAX) = NULL,
		@level3 VARCHAR(MAX) = NULL,
		@level4 VARCHAR(MAX) = NULL,
		@Level5 VARCHAR(MAX) = NULL,
		@Level6 VARCHAR(MAX) = NULL,
		@Level7 VARCHAR(MAX) = NULL,
		@Level8 VARCHAR(MAX) = NULL,
		@Level9 VARCHAR(MAX) = NULL,
		@Level10 VARCHAR(MAX) = NULL,
		@IsDownload BIT = NULL

  
  BEGIN TRY  
    --BEGIN TRANSACTION  
       
      DECLARE @ModuleID INT = 17; -- MS Module ID
	  DECLARE @SOMSModuleID bigint = 17
      DECLARE @WOMSModuleID bigint = 12
	   Declare @Count bigint =0
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END

	   SELECT 
		@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='As of Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,
		@customerid=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer(Optional)' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @customerid end,
		@exludedebit=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Exclude Debit Bal' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @exludedebit end,
		@tagtype=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Tag Type' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @tagtype end,
		@level1=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level1 end,
		@level2=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level2 end,
		@level3=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level3 end,
		@level4=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level4 end,
		@level5=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level5 end,
		@level6=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level6 end,
		@level7=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level7 end,
		@level8=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level8 end,
		@level9=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level9 end,
		@level10=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level10 end
	  FROM
		  @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)

		  if(ISNULL(@exludedebit,'')='' or @exludedebit is null)
		  begin
		  set @exludedebit =2;
		  end

	  IF ISNULL(@PageSize,0)=0
	  BEGIN 
		  SELECT @PageSize=COUNT(*) 
		  FROM (select wobi.BillingInvoicingId as BillingInvoicingId FROM dbo.WorkOrderBillingInvoicing wobi WITH (NOLOCK) 
			   INNER JOIN dbo.[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = wobi.WorkOrderId
			   INNER JOIN dbo.Customer c  WITH (NOLOCK) ON C.CustomerId=WO.CustomerId
			   LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = wo.CreditTermId
			   LEFT JOIN Employee emp WITH(NOLOCK) ON emp.EmployeeId = WO.SalesPersonId
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId and wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0 AND wobii.WorkOrderPartId = wop.ID
		 	   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = wobi.CurrencyId
			   INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wop.ID
			   LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			
            WHERE WO.CustomerId=ISNULL(@customerid,WO.CustomerId)  
		    AND CAST(wobi.PostedDate AS DATE) >= CAST(@ToDate AS DATE) AND WO.mastercompanyid = @mastercompanyid
			AND  
			(ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))
				AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
				AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
				AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
				AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
				AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
				AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
				AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
				AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
				AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
				AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
			 GROUP BY wobi.BillingInvoicingId
			UNION ALL
			
			Select sobi.SOBillingInvoicingId as BillingInvoicingId FROM dbo.SalesOrderBillingInvoicing sobi WITH (NOLOCK) 
			   INNER JOIN dbo.[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId
			   INNER JOIN dbo.Customer c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId
			    LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN DBO.SalesOrderPart sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			   INNER JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId
			   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
			   INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
			   LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			
               WHERE SO.CustomerId=ISNULL(@customerid,SO.CustomerId)  
		    AND CAST(sobi.PostedDate AS DATE) >= CAST(@ToDate AS DATE) AND SO.mastercompanyid = @mastercompanyid
			AND  
			(ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))
				AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
				AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
				AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
				AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
				AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
				AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
				AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
				AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
				AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
				AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
			
		       GROUP BY sobi.SOBillingInvoicingId
			) TEMP
	  END

	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

	 ;WITH CTE AS (   
			          SELECT DISTINCT (C.CustomerId) as CustomerId,
                       ((ISNULL(C.[Name],''))) 'CustName' ,
					   ((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       (CT.CustomerTypeName) 'CustomertType' ,
					   (CR.Code) as  'currencyCode',
					   wobi.GrandTotal as 'BalanceAmount',
					   (wobi.GrandTotal - wobi.RemainingAmount) as 'CurrentlAmount',
					   wobi.RemainingAmount  as 'PaymentAmount',
					   (wobi.InvoiceNo) as 'InvoiceNo',
					   wobi.PostedDate as InvoiceDate,
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
					   '0' as 'FixRateAmount',
					   wobi.GrandTotal as 'InvoiceAmount',
					   B.CMAmount as 'CMAmount',
					   (CASE WHEN ISNULL((wobi.RemainingAmount + Isnull(B.CMAmount,0)),0) > 0 THEN (case when isnull(@exludedebit,2) =1 then  1 else 2 end) ELSE 2 END) as 'FROMDebit',
			           DATEADD(day, ctm.NetDays,wobi.PostedDate) as 'DueDate',
			           UPPER(MSD.Level1Name) AS level1,  
			           UPPER(MSD.Level2Name) AS level2, 
			           UPPER(MSD.Level3Name) AS level3, 
			           UPPER(MSD.Level4Name) AS level4, 
			           UPPER(MSD.Level5Name) AS level5, 
			           UPPER(MSD.Level6Name) AS level6, 
			           UPPER(MSD.Level7Name) AS level7, 
			           UPPER(MSD.Level8Name) AS level8, 
			           UPPER(MSD.Level9Name) AS level9, 
			           UPPER(MSD.Level10Name) AS level10
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
			   LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
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
      WHERE WO.CustomerId=ISNULL(@customerid,WO.CustomerId)  
		    AND CAST(wobi.PostedDate AS DATE) >= CAST(@ToDate AS DATE) AND WO.mastercompanyid = @mastercompanyid
			AND  
			(ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))
				AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
				AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
				AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
				AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
				AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
				AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
				AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
				AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
				AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
				AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
		
		
		--ORDER BY CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(wobi.PostedDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), wobi.PostedDate, 107) 
		UNION ALL
		SELECT    DISTINCT    (C.CustomerId) as CustomerId,
                       ((ISNULL(C.[Name],''))) 'CustName' ,
					   ((ISNULL(C.CustomerCode,''))) 'CustomerCode' ,
                       (CT.CustomerTypeName) 'CustomertType' ,
					   (CR.Code) as  'currencyCode',
					   sobi.GrandTotal as 'BalanceAmount',
					   (sobi.GrandTotal - sobi.RemainingAmount) as 'CurrentlAmount',
					   sobi.RemainingAmount as 'PaymentAmount',
					   (sobi.InvoiceNo) as 'InvoiceNo',
					   sobi.PostedDate as InvoiceDate,
					   ISNULL(ctm.NetDays,0) AS NetDays,
					   (CASE WHEN DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) <= 0 THEN sobi.RemainingAmount ELSE 0 END) AS Amountpaidbylessthen0days,
					   (CASE
						WHEN DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 0 AND DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE())<= 30 THEN sobi.RemainingAmount
						ELSE 0
					  END) AS Amountpaidby30days,
					   (CASE
						WHEN DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + (CASE WHEN ctm.Code = 'COD' THEN -1
																	WHEN ctm.Code='CIA' THEN -1
																	WHEN ctm.Code='CreditCard' THEN -1
																	WHEN ctm.Code='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) as date), GETDATE()) > 30 AND DATEDIFF(DAY, CASt(CAST(sobi.PostedDate as datetime) + ISNULL(ctm.NetDays,0)  as date), GETDATE())<= 60 THEN sobi.RemainingAmount
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
					   '0' as 'FixRateAmount',
					   sobi.GrandTotal as 'InvoiceAmount',
					   B.CMAmount as 'CMAmount',
					   (CASE WHEN ISNULL((sobi.RemainingAmount + Isnull(B.CMAmount,0)),0) > 0 THEN (case when isnull(@exludedebit,2) =1 then  1 else 2 end) ELSE 2 END) as 'FROMDebit',
			           DATEADD(day, ctm.NetDays,sobi.PostedDate) as 'DueDate',
			           UPPER(MSD.Level1Name) AS level1,  
			           UPPER(MSD.Level2Name) AS level2, 
			           UPPER(MSD.Level3Name) AS level3, 
			           UPPER(MSD.Level4Name) AS level4, 
			           UPPER(MSD.Level5Name) AS level5, 
			           UPPER(MSD.Level6Name) AS level6, 
			           UPPER(MSD.Level7Name) AS level7, 
			           UPPER(MSD.Level8Name) AS level8, 
			           UPPER(MSD.Level9Name) AS level9, 
			           UPPER(MSD.Level10Name) AS level10
          FROM dbo.SalesOrderBillingInvoicing sobi WITH (NOLOCK) 
			   INNER JOIN dbo.[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = sobi.SalesOrderId
			   INNER JOIN dbo.Customer c  WITH (NOLOCK) ON C.CustomerId=SO.CustomerId
			    LEFT JOIN CreditTerms ctm WITH(NOLOCK) ON ctm.CreditTermsId = SO.CreditTermId
			   INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			   INNER JOIN DBO.SalesOrderPart sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
			   INNER JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND sobii.SalesOrderPartId = sop.SalesOrderPartId
			   INNER JOIN DBO.Currency CR WITH(NOLOCK) on CR.CurrencyId = sobi.CurrencyId
			   INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
			   LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
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
      WHERE SO.CustomerId=ISNULL(@customerid,SO.CustomerId)  
		    AND CAST(sobi.PostedDate AS DATE) >= CAST(@ToDate AS DATE) AND SO.mastercompanyid = @mastercompanyid
			AND  
			(ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))
				AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
				AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
				AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
				AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
				AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
				AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
				AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
				AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
				AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
				AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
		
		) 

		, Result AS(
				SELECT DISTINCT 
				       (CTE.CustomerId) as CustomerId ,
                       ((ISNULL(CTE.CustName,''))) 'CustName' ,
					   ((ISNULL(CTE.CustomerCode,''))) 'CustomerCode' ,
                       (CTE.CustomertType) 'CustomertType' ,
					   (CTE.currencyCode) as  'currencyCode',
					   FORMAT(ISNULL((CTE.PaymentAmount + Isnull(CTE.CMAmount,0)),0) , 'N', 'en-us') as 'BalanceAmount',
					   FORMAT((ISNULL((CTE.Amountpaidbylessthen0days + Isnull(CTE.CMAmount,0)),0)) , 'N', 'en-us')as 'CurrentlAmount',
					   ISNULL(CTE.PaymentAmount,0) as 'PaymentAmount',
					   (CTE.InvoiceNo) as 'InvoiceNo',
					   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(CTE.InvoiceDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), CTE.InvoiceDate, 107) END 'InvoiceDate', 
					   FORMAT(ISNULL(Case when CTE.Amountpaidbylessthen0days > 0 then  (CTE.Amountpaidbylessthen0days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidbylessthen0days) end,0) , 'N', 'en-us') as 'Amountpaidbylessthen0days',
					   FORMAT(ISNULL(Case when CTE.Amountpaidby30days > 0 then  (CTE.Amountpaidby30days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidby30days) end,0), 'N', 'en-us') as 'Amountpaidby30days',      
                       FORMAT(ISNULL(Case when CTE.Amountpaidby60days > 0 then  (CTE.Amountpaidby60days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidby60days) end,0), 'N', 'en-us') as 'Amountpaidby60days',
					   FORMAT(ISNULL(Case when CTE.Amountpaidby90days > 0 then  (CTE.Amountpaidby90days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidby90days) end,0), 'N', 'en-us') as 'Amountpaidby90days',
					   FORMAT(ISNULL(Case when CTE.Amountpaidby120days > 0 then  (CTE.Amountpaidby120days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidby120days) end,0), 'N', 'en-us') as 'Amountpaidby120days',
					   FORMAT(ISNULL(Case when CTE.Amountpaidbymorethan120days > 0 then  (CTE.Amountpaidbymorethan120days + Isnull(CTE.CMAmount,0)) else (CTE.Amountpaidbymorethan120days) end,0) , 'N', 'en-us') as 'Amountpaidbymorethan120days',  
					   (C.CreatedDate) AS CreatedDate,
                       (C.UpdatedDate) AS UpdatedDate,
					   (C.CreatedBy) as CreatedBy,
                       (C.UpdatedBy) as UpdatedBy,
					   (CTE.ManagementStructureId) as ManagementStructureId,
					   CTE.DocType as DocType,
					   CTE.CustomerRef as 'CustomerRef',
					   CTE.Salesperson as 'Salesperson',
					   CTE.Terms as 'Terms',
					   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(DATEADD(day, CTE.NetDays,CTE.InvoiceDate), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), DATEADD(day, CTE.NetDays,CTE.InvoiceDate), 107) END 'DueDate', 
					   ISNULL(CTE.FixRateAmount,0) as 'FixRateAmount',
					   FORMAT(ISNULL(CTE.InvoiceAmount,0) , 'N', 'en-us') as 'InvoiceAmount',
					   ISNULL(CTE.CMAmount,0) as 'CMAmount',
					   ISNULL(CTE.FROMDebit,0) as 'FROMDebit',
					   UPPER(CTE.level1) AS level1,  
			           UPPER(CTE.level2) AS level2, 
			           UPPER(CTE.level3) AS level3, 
			           UPPER(CTE.level4) AS level4, 
			           UPPER(CTE.level5) AS level5, 
			           UPPER(CTE.level6) AS level6, 
			           UPPER(CTE.level7) AS level7, 
			           UPPER(CTE.level8) AS level8, 
			           UPPER(CTE.level9) AS level9, 
			           UPPER(CTE.level10) AS level10
					
			   FROM CTE as CTE WITH (NOLOCK) 
			   INNER JOIN Customer as c WITH (NOLOCK) ON c.CustomerId = CTE.CustomerId 
			   WHERe C.MasterCompanyId = @MasterCompanyId and CTE.FROMDebit =@exludedebit


			) , ResultCount AS(SELECT COUNT(CustomerId) AS totalItems FROM Result)
			SELECT * INTO #TempResult1 FROM  Result

			 SELECT @Count = COUNT(CustomerId) FROM #TempResult1

			 SELECT *, @Count AS TotalRecordsCount FROM #TempResult1
		     ORDER BY CASE WHEN ISNULL(@IsDownload,0) = 0 THEN InvoiceDate ELSE InvoiceDate 
			
		
		END
		
			OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;  

   
   
  END TRY  
  
  BEGIN CATCH  
    
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(), 
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetARAgingReport]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter, '') AS varchar(max)),
            @ApplicationName varchar(100) = 'PAS' 
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH  
   
END