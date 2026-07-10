-- ===== PROCEDURE: [dbo].[usprpt_GetWorkOrderBillingReport]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs3/usprpt_GetWorkOrderBillingReport.sql) =====
/*************************************************************             
 ** File:   [usprpt_GetWorkOrderBillingReport]             
 ** Author:       
 ** Description: Get Data for WorkOrderBillingReport  
 ** Purpose:           
 ** Date:            
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date         Author				Change Description              
 ** --  --------		-------				--------------------------------      
	1   24-Aug-2023		Bhargav Saliya		Convert Dates UTC To LegalEntity Time Zone
    2   25-AUG-2023		Ekta Chandegra		Convert text into uppercase
	3   31-JAN-2024		Devendra Shekh		changes for performInvoice
	4   29-MARCH-2024	Ekta Chandegra		Add IsDeleted and IsActive flag  
	5   01-SEPT-2024	Hemant Saliya		Add Is Performa Invoice Condition 
	6   20-Nov-2024		Moin Bloch			Added Is Delete and Format SP
	7   10-APR-2025		Hemant Saliya		Updated for Get Revised Part number  & Handle Duplicate Part Issue
	8   10-APR-2025		Vishal Suthar		Added WOBillingInvoicingItemId column in the select statement to display all the records
	9   28-MAY-2025		Hemant Saliya		Updated for Flat rate Amount Correction
	10  20-June-2025	Devendra Shekh		Billing Table Changes
	11  10-Nov-2025	    Moin Bloch			Updated Credit memo Amount Get From CreditMemoDetails
	12  10-Nov-2025	    Moin Bloch			Updated Fix For Duplicate Credit Memo
	13  16-Jun-2026	    Bhargav Saliya		Fixed Date Converation Issue as per selected time zone
	14    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	15    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0


EXECUTE   [dbo].[usp_GetWorkOrderBillingReport] 'krunal','','','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,59','51,52,53'
**************************************************************/  
CREATE   PROCEDURE [dbo].[usprpt_GetWorkOrderBillingReport]
	@PageNumber INT = 1,
	@PageSize INT = NULL,
	@mastercompanyid INT,
	@xmlFilter XML
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  
  BEGIN TRY  
    --BEGIN TRANSACTION  
  
 DECLARE   
		  @PageSizeCM INT =0,  
		  @customername VARCHAR(40) = NULL,  
		  @Fromdate DATETIME,  
		  @Todate DATETIME,  
		  @tagtype VARCHAR(50) = NULL,  
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
		  @IsDownload BIT = NULL,  
		  @Status VARCHAR(50) = NULL,
		  @EmployeeId INT = NULL

		  DECLARE @StkModuleID INT = 0; 
		  SELECT @StkModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'STOCKLINE'
   
		  DECLARE @ModuleID INT = 0; -- MS Module ID  
		  SELECT @ModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'WORKORDERMPN'

		  DECLARE @WOModuleId BIGINT = 0, @SubModuleId BIGINT = 0;
		  SELECT @WOModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		  SELECT @SubModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN';
  
		  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END  
  
		  SELECT @Fromdate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date'   
		   THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Fromdate END,  
  
		   @Todate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date'   
		   THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Todate END,  
  
		   @tagtype=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Tag Type'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @tagtype END,  
     
		   @customername=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer(Optional)'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @customername END,  
  
		   @Status=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Invoice Status'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Status END,  
  
		   @level1=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level1 END,  
  
		   @level2=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level2 END,  
  
		   @level3=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level3 END,  
  
		   @level4=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level4 END,  
  
		   @level5=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level5 END,  
  
		   @level6=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level6 END,  
  
		   @level7=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level7 END,  
  
		   @level8=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level8 END,  
  
		   @level9=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level9 END,  
  
		   @level10=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 end,  

		   @EmployeeId=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='employeeId'   
		   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @EmployeeId END
  
			FROM @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)  
  
		  DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		  SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
		  FROM dbo.Employee E WITH (NOLOCK)
			  LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			  LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			  LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		  WHERE E.EmployeeId = @EmployeeId;

		   IF ISNULL(@PageSize,0)=0  
		   BEGIN   
			SELECT @PageSize=COUNT(*)  
			 FROM [dbo].[BillingInvoicing] WOBI WITH (NOLOCK)  
				 INNER JOIN [dbo].[BillingInvoicingItems] WOBIM WITH (NOLOCK) ON WOBI.BillingInvoicingId = WOBIM.BillingInvoicingId AND WOBIM.IsVersionIncrease = 0 AND ISNULL(WOBIM.IsPerformaInvoice, 0) = 0 AND WOBIM.SubModuleId = @SubModuleId
				 INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOBI.ReferenceId = WO.WorkOrderId
				 INNER JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WOBIM.SubReferenceId = WOPN.ID  
				 INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID  
				 INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId  
				 LEFT JOIN [dbo].[WorkOrderShippingItem] AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOBIM.SubReferenceId  
				 LEFT JOIN [dbo].[WorkOrderShipping] AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId   
				 INNER JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON WOPN.StockLineId = SL.StockLineId AND SL.IsParent = 1  
				 LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID  
				 LEFT JOIN [dbo].[WorkOrderQuote] woq WITH (NOLOCK) ON WO.WorkOrderId = woq.WorkOrderId AND woq.IsVersionIncrease = 0  
				 LEFT JOIN [dbo].[WorkOrderType] WITH (NOLOCK) ON WO.WorkOrderTypeId = WorkOrderType.Id  
				 LEFT JOIN [dbo].[ReceivingCustomerWork] RCW WITH (NOLOCK) ON WO.WorkOrderId = RCW.WorkOrderId  
				 LEFT JOIN [dbo].[Employee] AS E WITH (NOLOCK) ON WO.SalesPersonId = E.EmployeeId  
				 LEFT JOIN [dbo].[Employee] AS E1 WITH (NOLOCK) ON WO.CsrId = E1.EmployeeId  
				 LEFT JOIN [dbo].[WorkOrderStage] AS WTG WITH (NOLOCK) ON WOPN.WorkOrderStageId = WTG.WorkOrderStageId  
				 LEFT JOIN [dbo].[WorkOrderStatus] AS WTS WITH (NOLOCK) ON WOPN.WorkOrderStatusId = WTS.Id  
				 LEFT JOIN [dbo].[InvoiceStatus] AS IVS WITH (NOLOCK) ON WOBI.InvoiceStatus = IVS.Status  
			WHERE CAST(WOBI.invoicedate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) AND WOBI.IsVersionIncrease = 0  
				 AND WO.CustomerId=ISNULL(@customername,WO.customerid)   
				 AND WO.MasterCompanyId = @mastercompanyid  
				 AND WO.IsDeleted = 0 AND WO.IsActive = 1
				 AND WOBI.ModuleId = @WOModuleId
				 AND (ISNULL(@tagtype,'') ='' OR ES.OrganizationTagTypeId IN(SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,ES.OrganizationTagTypeId), ',')))  
				 AND (ISNULL(@Status,'') ='' OR IVS.InvoiceStatusId IN(SELECT value FROM STRING_SPLIT(ISNULL(@Status,IVS.InvoiceStatusId), ',')))  
				 AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))  
				 AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))  
				 AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))  
				 AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))  
				 AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))  
				 AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))  
				 AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))  
				 AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))  
				 AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))  
				 AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  
  
		    AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
				  SELECT @PageSizeCM=COUNT(*)  
			FROM [dbo].[CreditMemo] CM WITH (NOLOCK)  
				  INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.[IsDeleted] = 0 AND CMD.[IsActive] = 1
				  LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON CM.ReferenceId = WO.WorkOrderId  
				  INNER JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WO.WorkOrderId = WOPN.WorkOrderId    
				  LEFT JOIN [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) ON CM.InvoiceId = WOBI.BillingInvoicingId AND WOBI.ModuleId = @WOModuleId
				  --LEFT JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOBI.WorkOrderPartNoId = WOWF.WorkOrderPartNoId  
				  LEFT JOIN [dbo].[Employee] E WITH (NOLOCK) ON WO.SalesPersonId = E.EmployeeId  
				  LEFT JOIN [dbo].[Employee] E1 WITH (NOLOCK) ON WO.CsrId = E1.EmployeeId  
				  LEFT JOIN [dbo].[WorkOrderQuote] WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId AND WOQ.IsVersionIncrease = 0  
				  INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @StkModuleID AND MSD.ReferenceID = CMD.StocklineId  
				  LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID  
				  LEFT JOIN [dbo].[InvoiceStatus] IVS WITH (NOLOCK) ON WOBI.InvoiceStatus = IVS.Status  
				  LEFT JOIN [dbo].[WorkOrderStage] WTG WITH (NOLOCK) ON WOPN.WorkOrderStageId = WTG.WorkOrderStageId  
				  LEFT JOIN [dbo].[WorkOrderStatus] AS WTS WITH (NOLOCK) ON WOPN.WorkOrderStatusId = WTS.Id  
				  LEFT JOIN [dbo].[BillingInvoicingItems] WOBIM WITH (NOLOCK) ON CMD.InvoiceId = WOBIM.BillingInvoicingId AND CMD.BillingInvoicingItemId = WOBIM.BillingInvoicingItemId  AND ISNULL(WOBIM.IsVersionIncrease,0) = 0 AND ISNULL(WOBIM.IsPerformaInvoice, 0) = 0 AND WOBIM.SubModuleId = @SubModuleId    
				  LEFT JOIN [dbo].[WorkOrderShippingItem] AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOBIM.SubReferenceId  
				  LEFT JOIN [dbo].[WorkOrderShipping] AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId  
				  LEFT JOIN [dbo].[ReceivingCustomerWork] RCW WITH (NOLOCK) ON WO.WorkOrderId = RCW.WorkOrderId  
     
			 WHERE CAST(CM.CreatedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)   
				  AND CM.CustomerId=ISNULL(@customername,CM.customerid)   
				  AND CM.MasterCompanyId = @mastercompanyid  
				  AND CM.[IsDeleted] = 0 AND CM.[IsActive] = 1
				  AND ISNULL(CM.IsWorkOrder,0) = 1	  
				  AND (ISNULL(@tagtype,'') ='' OR ES.OrganizationTagTypeId IN(SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,ES.OrganizationTagTypeId), ',')))  
				  AND (ISNULL(@Status,'') ='' OR IVS.InvoiceStatusId IN(SELECT value FROM STRING_SPLIT(ISNULL(@Status,IVS.InvoiceStatusId), ',')))  
				  AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))  
				  AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))  
				  AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))  
				  AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))  
				  AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))  
				  AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))  
				  AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))  
				  AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))  
				  AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))  
				  AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  
      
			 SET @PageSize = ISNULL(@PageSize,0) + ISNULL(@PageSizeCM,0)   
		   END  
  
		   SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END  
		   SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END  
  
		   --INSERT INTO #tmpBilling  
		  ;WITH rptCTE (TotalRecordsCount, WorkOrderId, WOBillingInvoicingItemId, customername, customercode, pn, pndescription, serialnum, workscope, wonum, invoicenum, revenue,  
				 quotenum, receiveddate, opendate,invoicedate,quotedate,quoteapprovaldate,shipdate, tat, salesperson,csr, level1, level2, level3, level4, level5, level6, level7, level8,  
				 level9, level10, woStage, CodeDescription, woStatus, invoiceStatus, masterCompanyId, rn) AS (  
		  SELECT DISTINCT COUNT(1) OVER () AS TotalRecordsCount,  
			   WO.WorkOrderId,  
			   WOBIM.BillingInvoicingItemId,
			   UPPER(C.Name) 'customername',  
			   UPPER(C.CustomerCode) 'customercode',  
			   CASE WHEN ISNULL(WOPN.RevisedItemmasterid,0) > 0 THEN  UPPER(RIM.partnumber) ELSE  UPPER(IM.partnumber) END AS 'pn',  
			   CASE WHEN ISNULL(WOPN.RevisedItemmasterid,0) > 0 THEN  UPPER(RIM.PartDescription) ELSE  UPPER(IM.PartDescription) END AS 'pndescription',  
			   CASE WHEN ISNULL(WOPN.RevisedSerialNumber,'') = '' THEN UPPER(SL.SerialNumber)ELSE  UPPER( WOPN.RevisedSerialNumber) END AS 'serialnum', 
			   UPPER(WOPN.WorkScope) 'workscope',  
			   UPPER(WO.WorkOrderNum) 'wonum',  
			   WOBI.InvoiceNo 'invoicenum',  
			   CASE WHEN WOBI.CostPlusType = 'Flat Rate' AND ISNULL(WOBIM.GrandTotal,0) > 0 THEN ISNULL(WOBIM.GrandTotal,0) ELSE CASE WHEN ISNULL(WOBIM.GrandTotal,0) > 0 THEN (ISNULL(WOBIM.GrandTotal, 0) - (ISNULL(WOBIM.SalesTax, 0) + ISNULL(WOBIM.OtherTax, 0))) WHEN ISNULL(WOBIM.SubTotal,0) > 0 THEN ISNULL(WOBIM.SubTotal,0) ELSE ISNULL(WOBIM.UnitPrice,0) END END AS 'revenue',   
			   UPPER(WOQ.QuoteNumber) 'quotenum',  
			   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.ReceivedDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOPN.ReceivedDate, 107) END 'receiveddate',   
			   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(CASE WHEN CAST(WO.OpenDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WO.OpenDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 'MM/dd/yyyy') 
					ELSE CONVERT(VARCHAR(50), CASE WHEN CAST(WO.OpenDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WO.OpenDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 107) 
			   END 'opendate', 
			   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 'MM/dd/yyyy') 
					ELSE CONVERT(VARCHAR(50), CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 107) 
			   END 'invoicedate',   
			   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOQ.OpenDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOQ.OpenDate, 107) END 'quotedate',   
			   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(CASE WHEN CAST(WOQ.ApprovedDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WOQ.ApprovedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 'MM/dd/yyyy') 
					ELSE CONVERT(VARCHAR(50), CASE WHEN CAST(WOQ.ApprovedDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WOQ.ApprovedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 107) 
			   END 'quoteapprovaldate',   
			   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOS.ShipDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOS.ShipDate, 107) END 'shipdate',   
			   CASE  
				 WHEN WOS.ShipDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)  
				 WHEN ApprovedDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)  
				 WHEN SentDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate)  
				 WHEN RCW.ReceivedDate IS NOT NULL THEN DATEDIFF(DAY, RCW.ReceivedDate, GETDATE())  
			   END AS 'tat',  
				--0 AS 'tat',  
			   UPPER(E.FirstName + ' ' + E.LastName) 'salesperson',  
			   UPPER(E1.FirstName + ' ' + E1.LastName) 'csr',  
			   UPPER(MSD.Level1Name) AS level1,      UPPER(MSD.Level2Name) AS level2,     UPPER(MSD.Level3Name) AS level3,     UPPER(MSD.Level4Name) AS level4,     UPPER(MSD.Level5Name) AS level5,     UPPER(MSD.Level6Name) AS level6,     UPPER(MSD.Level7Name) AS level7,     UPPER(MSD.Level8Name) AS level8,     UPPER(MSD.Level9Name) AS level9,     UPPER(MSD.Level10Name) AS level10,  
			   UPPER(WTG.Stage) AS 'woStage',  
			   UPPER(WTG.CodeDescription) AS 'CodeDescription',  
			   UPPER(WTS.[Description]) AS 'woStatus',  
			   UPPER(WOBI.InvoiceStatus) AS 'invoiceStatus',  
			   WO.MasterCompanyId AS masterCompanyId,
			   ROW_NUMBER() OVER (PARTITION BY WO.WorkOrderId, WOBIM.BillingInvoicingItemId ORDER BY WOS.ShipDate DESC) AS rn
		  FROM [dbo].[WorkOrder] WO WITH (NOLOCK)  
				INNER JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WO.WorkOrderId = WOPN.WorkOrderId    
				INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID  
				INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId  
				LEFT JOIN [dbo].[ItemMaster] RIM WITH (NOLOCK) ON WOPN.RevisedItemmasterid = RIM.ItemMasterId  
				 AND ISNULL(RIM.IsNonStock,0) = 0
				 INNER JOIN [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) ON WO.WorkOrderId = WOBI.ReferenceId AND WOBI.IsVersionIncrease = 0 AND WOBI.IsVersionIncrease = 0 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 AND WOBI.ModuleId = @WOModuleId
				INNER JOIN [dbo].[BillingInvoicingItems] WOBIM WITH (NOLOCK) ON WOBI.BillingInvoicingId = WOBIM.BillingInvoicingId AND WOBIM.SubReferenceId = WOPN.ID AND WOBIM.IsVersionIncrease = 0 AND ISNULL(WOBIM.IsPerformaInvoice, 0) = 0 AND WOBIM.SubModuleId = @SubModuleId
				LEFT JOIN [dbo].[WorkOrderShippingItem] AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOBIM.SubReferenceId  
				LEFT JOIN [dbo].[WorkOrderShipping] AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId   
				LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON WOPN.StockLineId = SL.StockLineId AND SL.IsParent = 1 AND ISNULL(SL.IsNonStock,0) = 0  
				LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID  
				LEFT JOIN [dbo].[WorkOrderQuote] woq WITH (NOLOCK) ON WO.WorkOrderId = woq.WorkOrderId AND woq.IsVersionIncrease = 0  
				LEFT JOIN [dbo].[WorkOrderType] WITH (NOLOCK) ON WO.WorkOrderTypeId = WorkOrderType.Id  
				LEFT JOIN [dbo].[customer] C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId  
				LEFT JOIN [dbo].[ReceivingCustomerWork] RCW WITH (NOLOCK) ON WO.WorkOrderId = RCW.WorkOrderId    
				LEFT JOIN [dbo].[Employee] AS E WITH (NOLOCK) ON WO.SalesPersonId = E.EmployeeId  
				LEFT JOIN [dbo].[Employee] AS E1 WITH (NOLOCK) ON WO.CsrId = E1.EmployeeId  
				LEFT JOIN [dbo].[WorkOrderStage] AS WTG WITH (NOLOCK) ON WOPN.WorkOrderStageId = WTG.WorkOrderStageId  
				LEFT JOIN [dbo].[WorkOrderStatus] AS WTS WITH (NOLOCK) ON WOPN.WorkOrderStatusId = WTS.Id  
				LEFT JOIN [dbo].[InvoiceStatus] AS IVS WITH (NOLOCK) ON WOBI.InvoiceStatus = IVS.Status  
		   WHERE CAST(WOBI.InvoiceDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)   
				AND WO.customerid=ISNULL(@customername,WO.customerid)   
				AND WO.mastercompanyid = @mastercompanyid  
				AND WO.IsDeleted = 0 AND WO.IsActive = 1
				AND (ISNULL(@tagtype,'') ='' OR ES.OrganizationTagTypeId IN(SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,ES.OrganizationTagTypeId), ',')))  
				AND (ISNULL(@Status,'') ='' OR IVS.InvoiceStatusId IN(SELECT value FROM STRING_SPLIT(ISNULL(@Status,IVS.InvoiceStatusId), ',')))  
				AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))  
				AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))  
				AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))  
				AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))  
				AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))  
				AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))  
				AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))  
				AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))  
				AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))  
				AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  
      
			 AND ISNULL(IM.IsNonStock,0) = 0
				 UNION ALL  
  
			SELECT DISTINCT COUNT(1) OVER () AS TotalRecordsCount,  
				 CM.WorkOrderId,  
				 WOBIM.BillingInvoicingItemId,
				 UPPER(CM.CustomerName) 'customername',  
				 UPPER(CM.CustomerCode) 'customercode',  
				 UPPER(CMD.partnumber) 'pn',  
				 UPPER(CMD.PartDescription) 'pndescription',  
				 UPPER(CMD.SerialNumber) 'serialnum',  
				 UPPER(WOPN.WorkScope) 'workscope',  
				 UPPER(WO.WorkOrderNum) + ' (' + UPPER(CM.CreditMemoNumber) +')' AS 'wonum',  
				 CM.InvoiceNumber 'invoicenum',  
				 ISNULL(CMD.Amount,0) 'revenue',   
				 UPPER(WOQ.QuoteNumber) 'quotenum',  
				 CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.ReceivedDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOPN.ReceivedDate, 107) END 'receiveddate',   
				 CASE WHEN ISNULL(@IsDownload,0) = 0 
				  THEN FORMAT(CASE WHEN CAST(WO.OpenDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WO.OpenDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 'MM/dd/yyyy') 
				  ELSE CONVERT(VARCHAR(50), CASE WHEN CAST(WO.OpenDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WO.OpenDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 107) 
				 END 'opendate',
				 CASE WHEN ISNULL(@IsDownload,0) = 0 
				  THEN FORMAT(CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 'MM/dd/yyyy') 
				  ELSE CONVERT(VARCHAR(50), CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 107) 
			     END 'invoicedate',
				 CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOQ.OpenDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOQ.OpenDate, 107) END 'quotedate', 
				 CASE WHEN ISNULL(@IsDownload,0) = 0 
				  THEN FORMAT(CASE WHEN CAST(WOQ.ApprovedDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WOQ.ApprovedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 'MM/dd/yyyy') 
				  ELSE CONVERT(VARCHAR(50), CASE WHEN CAST(WOQ.ApprovedDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(WOQ.ApprovedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END, 107) 
			     END 'quoteapprovaldate',
				 CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOS.ShipDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOS.ShipDate, 107) END 'shipdate',  
				 CASE  
				   WHEN WOS.ShipDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)  
				   WHEN ApprovedDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)  
				   WHEN SentDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate)  
				   WHEN RCW.ReceivedDate IS NOT NULL THEN DATEDIFF(DAY, RCW.ReceivedDate, GETDATE())  
				 END AS 'tat',  
				 --0 AS 'tat',  
				 UPPER(E.FirstName + ' ' + E.LastName) 'salesperson',  
				 UPPER(E1.FirstName + ' ' + E1.LastName) 'csr',  
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
				 UPPER(WTG.Stage) as 'woStage',  
				 UPPER(WTG.CodeDescription) as 'CodeDescription',  
				 UPPER(WTS.Description) as 'woStatus',  
				 UPPER('Credit Memo') as 'invoiceStatus',  
				 WO.MasterCompanyId AS masterCompanyId ,
				 ROW_NUMBER() OVER (PARTITION BY WO.WorkOrderId, WOBIM.BillingInvoicingItemId ORDER BY WOS.ShipDate DESC) AS rn
			FROM [dbo].[CreditMemo] CM WITH (NOLOCK)  
				INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.[IsDeleted] = 0 AND CMD.[IsActive] = 1 
				LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON CM.ReferenceId = WO.WorkOrderId  
				INNER JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WO.WorkOrderId = WOPN.WorkOrderId    
				LEFT JOIN [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) ON CM.InvoiceId = WOBI.BillingInvoicingId AND WOBI.ModuleId = @WOModuleId
				LEFT JOIN [dbo].[Employee] E WITH (NOLOCK) ON WO.SalesPersonId = E.EmployeeId  
				LEFT JOIN [dbo].[Employee] E1 WITH (NOLOCK) ON WO.CsrId = E1.EmployeeId  
				LEFT JOIN [dbo].[WorkOrderQuote] WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId AND WOQ.IsVersionIncrease = 0  
				INNER JOIN [dbo].StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @StkModuleID AND MSD.ReferenceID = CMD.StocklineId  
				LEFT JOIN [dbo].EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID  
				LEFT JOIN [dbo].InvoiceStatus IVS WITH (NOLOCK) ON WOBI.InvoiceStatus = IVS.Status  
				LEFT JOIN [dbo].WorkOrderStage WTG WITH (NOLOCK) ON WOPN.WorkOrderStageId = WTG.WorkOrderStageId  
				LEFT JOIN [dbo].WorkOrderStatus AS WTS WITH (NOLOCK) ON WOPN.WorkOrderStatusId = WTS.Id  
				LEFT JOIN [dbo].BillingInvoicingItems WOBIM WITH (NOLOCK) ON CMD.InvoiceId = WOBIM.BillingInvoicingId AND CMD.BillingInvoicingItemId = WOBIM.BillingInvoicingItemId  AND ISNULL(WOBIM.IsVersionIncrease,0) = 0 AND ISNULL(WOBIM.IsPerformaInvoice, 0) = 0 AND WOBIM.SubModuleId = @SubModuleId    
				LEFT JOIN [dbo].WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOBIM.SubReferenceId  
				LEFT JOIN [dbo].WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId  
				LEFT JOIN [dbo].ReceivingCustomerWork RCW WITH (NOLOCK) ON WO.WorkOrderId = RCW.WorkOrderId  
				LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
				LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
				LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId     
			 WHERE CAST(CM.CreatedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)   
				  AND CM.CustomerId=ISNULL(@customername,CM.customerid)   
				  AND CM.MasterCompanyId = @mastercompanyid  
				  AND CM.[IsDeleted] = 0 AND CM.[IsActive] = 1
				  AND ISNULL(CM.IsWorkOrder,0) = 1
				  AND (ISNULL(@tagtype,'') ='' OR ES.OrganizationTagTypeId IN(SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,ES.OrganizationTagTypeId), ',')))  
				  AND (ISNULL(@Status,'') ='' OR IVS.InvoiceStatusId IN(SELECT value FROM STRING_SPLIT(ISNULL(@Status,IVS.InvoiceStatusId), ',')))  
				  AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))  
				  AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))  
				  AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))  
				  AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))  
				  AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))  
				  AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))  
				  AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))  
				  AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))  
				  AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))  
				  AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  
			  )      
        
		   ,FinalCTE(TotalRecordsCount, WorkOrderId, WOBillingInvoicingItemId, customername, customercode, pn, pndescription, serialnum, workscope, wonum, invoicenum, revenue,  
			 quotenum, receiveddate, opendate,invoicedate,quotedate,quoteapprovaldate,shipdate, tat, salesperson,csr, level1, level2, level3, level4, level5, level6, level7, level8,  
			 level9, level10, woStage, CodeDescription, woStatus, invoiceStatus, masterCompanyId)   
			 AS (SELECT DISTINCT TotalRecordsCount, WorkOrderId, WOBillingInvoicingItemId, customername, customercode, pn, pndescription, serialnum, workscope, wonum, invoicenum, revenue,  
			 quotenum, receiveddate, opendate,invoicedate,quotedate,quoteapprovaldate,shipdate, tat, salesperson,csr, level1, level2, level3, level4, level5, level6, level7, level8,  
			 level9, level10, woStage, CodeDescription, woStatus, invoiceStatus, masterCompanyId FROM rptCTE where rn = 1)  
  
		   ,WithTotal (masterCompanyId, TotalRevenue)   
			 AS (SELECT masterCompanyId,   
			FORMAT(SUM(revenue), 'N', 'en-us') TotalRevenue  
			FROM FinalCTE  
			GROUP BY masterCompanyId)  
  
			 SELECT COUNT(2) OVER () AS TotalRecordsCount, WorkOrderId, WOBillingInvoicingItemId, customername, customercode, pn, pndescription, serialnum, workscope, wonum, quotenum, invoicenum,   
				 receiveddate, opendate,invoicedate,quotedate,quoteapprovaldate,shipdate,   
				 FORMAT(ISNULL(revenue,0) , 'N', 'en-us') 'revenue',      
				 tat, salesperson,csr, level1, level2, level3, level4, level5, level6, level7, level8,  
				 level9, level10, woStage, CodeDescription, woStatus, invoiceStatus,  
				 WC.TotalRevenue  
			FROM FinalCTE FC  
				INNER JOIN WithTotal WC ON FC.masterCompanyId = WC.masterCompanyId  
			ORDER BY WorkOrderId DESC  
			OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;   
  
    --COMMIT TRANSACTION  
  END TRY  
  
  BEGIN CATCH  
    --ROLLBACK TRANSACTION  
  
 SELECT     ERROR_NUMBER() AS ErrorNumber,     ERROR_STATE() AS ErrorState,     ERROR_SEVERITY() AS ErrorSeverity,     ERROR_PROCEDURE() AS ErrorProcedure,     ERROR_LINE() AS ErrorLine,     ERROR_MESSAGE() AS ErrorMessage;  
  
    IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL  
    BEGIN  
      DROP TABLE #managmetnstrcture  
    END  
  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[usp_GetWorkOrderBillingReport]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@customername, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +  
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +  
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +  
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +  
            '@Parameter8 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),  
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