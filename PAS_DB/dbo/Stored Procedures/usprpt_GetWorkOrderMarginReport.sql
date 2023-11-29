  
/*************************************************************             
 ** File:   [usprpt_GetWorkOrderMarginReport]             
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used Get Work Order Margin Report Data  
 ** Purpose:           
 ** Date:      05/26/2023  
            
 ** PARAMETERS:             
 @WorkOrderId BIGINT     
 @WFWOId BIGINT    
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author   Change Description              
 ** --   --------     -------   --------------------------------            
 1    05/26/2023   Vishal Suthar  Modified to return SUM of all the records before paging  
 2    06/07/2023   HEMANT SALIYA  Updated for Number Formating for decimal columns  
 3    11/07/2023   AYESHA SULTANA CREDIT MEMO DATA CORRESPONDING TO WORK ORDER GROSS MARGIN IF ANY  
 4    17/07/2023   AYESHA SULTANA CREDIT MEMO DATA CORRESPONDING TO WORK ORDER GROSS MARGIN IF ANY updated  
 5    20/07/2023   AYESHA SULTANA CREDIT MEMO DATA CORRESPONDING TO WORK ORDER GROSS MARGIN IF ANY updated - revenue changes  
 6    24/08/2023   BHARGAV SALIYA Convert Dates UTC To LegalEntity Time Zone
 7    04/09/2023   HEMANT SALIYA  Corrected Revenue Balance

**************************************************************/  
CREATE     PROCEDURE [dbo].[usprpt_GetWorkOrderMarginReport]  
@PageNumber INT = 1,      
@PageSize INT = NULL,      
@mastercompanyid INT,      
@xmlFilter XML      
AS      
BEGIN      
  SET NOCOUNT ON;      
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
      
  BEGIN TRY      
    BEGIN TRANSACTION      
      
			DECLARE @PageSizeCM INT =0,@customername VARCHAR(40) = NULL,      
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
			@IsDownload BIT = NULL      
      
			SELECT @Fromdate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date'       
			 THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Fromdate END,      
      
			 @Todate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date'       
			 THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Todate END,      
      
			 @tagtype=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Tag Type'       
			 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @tagtype END,      
      
			 @customername=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer(Optional)'       
			 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @customername END,      
      
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
			 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 end      
      
		  FROM @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)      
  
			 DECLARE @ModuleID INT = 12; -- MS Module ID      
		  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END      

		  IF ISNULL(@PageSize,0)=0      
			 BEGIN       
			   SELECT @PageSize=COUNT(*)      
			   FROM DBO.WorkOrder WO WITH (NOLOCK)      
				 INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WO.WorkOrderId = WOPN.WorkOrderId      
				 INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID      
				 INNER JOIN DBO.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOPN.ID = WOC.WOPartNoId AND WO.WorkOrderId = WOC.WorkOrderId    
				 LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID           
				 LEFT JOIN DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON WO.WorkOrderId = WOBI.WorkOrderId AND WOBI.IsVersionIncrease = 0      
				 LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK) ON WO.WorkOrderId = woq.WorkOrderId AND woq.IsVersionIncrease = 0      
				 LEFT JOIN DBO.WorkOrderType WITH (NOLOCK) ON WO.WorkOrderTypeId = WorkOrderType.Id      
				 LEFT JOIN DBO.ReceivingCustomerWork RCW WITH (NOLOCK) ON WO.WorkOrderId = RCW.WorkOrderId      
				 LEFT JOIN DBO.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId    
				 LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId      
				 LEFT JOIN DBO.Stockline SL WITH (NOLOCK) ON WOPN.StockLineId = SL.StockLineId AND SL.IsParent = 1      
				 LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOPN.ID      
				 LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId      
				 LEFT JOIN DBO.Employee AS E WITH (NOLOCK) ON WO.SalesPersonId = E.EmployeeId      
				 LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK) ON WO.CsrId = E1.EmployeeId    
			   WHERE CAST(WOBI.invoicedate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)      
				 AND WO.customerid=ISNULL(@customername,WO.customerid)       
				 AND WO.mastercompanyid = @mastercompanyid      
				 AND (ISNULL(@tagtype,'') ='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,ES.OrganizationTagTypeId), ',')))      
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
  
			   SELECT @PageSizeCM=COUNT(*)   
				FROM DBO.CreditMemo CM WITH (NOLOCK)    
				  INNER JOIN DBO.CreditMemoDetails CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId  
				  LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON CM.ReferenceId = WO.WorkOrderId  
				  LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WO.WorkOrderId = WOPN.WorkOrderId    
				  LEFT JOIN DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON CM.InvoiceId = WOBI.BillingInvoicingId  
				  LEFT JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOBI.WorkOrderPartNoId = WOWF.WorkOrderPartNoId  
				  LEFT JOIN DBO.Employee E WITH (NOLOCK) ON WO.SalesPersonId = E.EmployeeId  
				  LEFT JOIN DBO.Employee E1 WITH (NOLOCK) ON WO.CsrId = E1.EmployeeId  
				  LEFT JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId AND WOQ.IsVersionIncrease = 0     
				  INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = 2 AND MSD.ReferenceID = CMD.StocklineId      
				  LEFT JOIN DBO.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOPN.ID = WOC.WOPartNoId AND WO.WorkOrderId = WOC.WorkOrderId      
				  LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOPN.ID      
				  LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId    
				  LEFT JOIN DBO.ReceivingCustomerWork RCW WITH (NOLOCK) ON WO.WorkOrderId = RCW.WorkOrderId    
				  LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID         
       
			   WHERE CAST(CM.CreatedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)      
				 AND CM.customerid=ISNULL(@customername,CM.customerid)      
				 AND CM.mastercompanyid = @mastercompanyid      
				 AND ISNULL(CM.IsWorkOrder,0) = 1  
				 AND (ISNULL(@tagtype,'') ='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,ES.OrganizationTagTypeId), ',')))      
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
     
			 ;WITH rptCTE (TotalRecordsCount,WorkOrderId, customername, customercode, pn, pndescription, serialnum, workscope, wonum, quotenum, invoicenum,   
				receiveddate, opendate,invoicedate,quotedate,quoteapprovaldate,shipdate, revenue, partscost,laborcost, overheadcost, directcost, margin, partsrevper, laborrevper, ohcostper, revenueper,   
				grossmarginrevper,tat, salesperson,csr, level1, level2, level3, level4, level5, level6, level7, level8,  
				 level9, level10, masterCompanyId)  
				 AS ( SELECT DISTINCT    
						COUNT(1) OVER () AS TotalRecordsCount,    
						WO.WorkOrderId,  
						UPPER(C.name) 'customername',    
						UPPER(C.CustomerCode) 'customercode',     
						UPPER(IM.partnumber) 'pn',      
						UPPER(IM.PartDescription) 'pndescription',      
						UPPER(SL.SerialNumber) 'serialnum',      
						UPPER(WOPN.WorkScope) 'workscope',      
						UPPER(WO.WorkOrderNum) 'wonum',      
						UPPER(WOQ.QuoteNumber) 'quotenum',      
						WOBI.InvoiceNo 'invoicenum',      
						CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.ReceivedDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOPN.ReceivedDate, 107) END 'receiveddate',       
						CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (WO.OpenDate,TZ.Description)), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WO.OpenDate,TZ.Description)), 107) END 'opendate',       
						CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (WOBI.InvoiceDate,TZ.Description)), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WOBI.InvoiceDate,TZ.Description)), 107) END 'invoicedate',       
						CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOQ.OpenDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOQ.OpenDate, 107) END 'quotedate',       
						CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (WOQ.ApprovedDate,TZ.Description)), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WOQ.ApprovedDate,TZ.Description)), 107) END 'quoteapprovaldate',       
						CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOS.ShipDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOS.ShipDate, 107) END 'shipdate',       
						ISNULL(WOBI.GrandTotal,0) 'revenue',      
						ISNULL(WOC.PartsCost,0) 'partscost',      
						ISNULL(WOC.LaborCost,0) 'laborcost',      
						ISNULL(WOC.OverHeadCost,0) 'overheadcost',      
						ISNULL(WOC.DirectCost,0) 'directcost',      
						CASE WHEN ISNULL(WOC.DirectCost,0) != 0 THEN CONVERT(DECIMAL(10,4), ISNULL(WOBI.GrandTotal,0) - ISNULL(WOC.DirectCost,0))  ELSE ISNULL(WOBI.GrandTotal,0) END 'margin',      
						CASE WHEN ISNULL(WOBI.GrandTotal,0) != 0 THEN CONVERT(DECIMAL(10,4), (ISNULL(WOC.PartsCost,0) / ISNULL(WOBI.GrandTotal,0))*100) ELSE 0 END 'partsrevper',      
						CASE WHEN ISNULL(WOBI.GrandTotal,0) != 0 THEN CONVERT(DECIMAL(10,4), (ISNULL(WOC.LaborCost,0) / ISNULL(WOBI.GrandTotal,0))*100) ELSE 0 END 'laborrevper',      
						CASE WHEN ISNULL(WOBI.GrandTotal,0) != 0 THEN CONVERT(DECIMAL(10,4), (ISNULL(WOC.OverHeadCost,0) / ISNULL(WOBI.GrandTotal,0))*100) ELSE 0 END 'ohcostper',      
						CASE WHEN ISNULL(WOBI.GrandTotal,0) != 0 THEN CONVERT(DECIMAL(10,4), (ISNULL(WOC.DirectCost,0) / ISNULL(WOBI.GrandTotal,0))*100) ELSE 0 END  'revenueper',      
						CASE WHEN ISNULL(WOBI.GrandTotal,0) != 0 THEN CONVERT(DECIMAL(10,4), ((ISNULL(WOBI.GrandTotal, 0) - ISNULL(WOC.DirectCost, 0)) / ISNULL(WOBI.GrandTotal,0))*100) ELSE 0 END 'grossmarginrevper',  
						CASE      
						  WHEN WOS.ShipDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)      
						  WHEN ApprovedDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)      
						  WHEN SentDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate)      
						  WHEN RCW.ReceivedDate IS NOT NULL THEN DATEDIFF(DAY, RCW.ReceivedDate, GETDATE())      
						END AS 'tat',      
						UPPER(E.FirstName + ' ' + E.LastName) 'salesperson',      
						UPPER(E1.FirstName + ' ' + E1.LastName) 'csr',      
						UPPER(MSD.Level1Name) AS level1, UPPER(MSD.Level2Name) AS level2, UPPER(MSD.Level3Name) AS level3, UPPER(MSD.Level4Name) AS level4, UPPER(MSD.Level5Name) AS level5,        
						UPPER(MSD.Level6Name) AS level6,UPPER(MSD.Level7Name) AS level7, UPPER(MSD.Level8Name) AS level8, UPPER(MSD.Level9Name) AS level9,UPPER(MSD.Level10Name) AS level10,  
						WO.MasterCompanyId AS masterCompanyId  
					FROM DBO.WorkOrder WO WITH (NOLOCK)      
						 INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WO.WorkOrderId = WOPN.WorkOrderId      
						 INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID      
						 INNER JOIN DBO.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOPN.ID = WOC.WOPartNoId AND WO.WorkOrderId = WOC.WorkOrderId    
						 LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID           
						 LEFT JOIN DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON WO.WorkOrderId = WOBI.WorkOrderId AND WOBI.IsVersionIncrease = 0      
						 LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK) ON WO.WorkOrderId = woq.WorkOrderId AND woq.IsVersionIncrease = 0      
						 LEFT JOIN DBO.WorkOrderType WITH (NOLOCK) ON WO.WorkOrderTypeId = WorkOrderType.Id      
						 LEFT JOIN DBO.ReceivingCustomerWork RCW WITH (NOLOCK) ON WO.WorkOrderId = RCW.WorkOrderId      
						 LEFT JOIN DBO.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId    
						 LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId      
						 LEFT JOIN DBO.Stockline SL WITH (NOLOCK) ON WOPN.StockLineId = SL.StockLineId AND SL.IsParent = 1      
						 LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOPN.ID      
						 LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId      
						 LEFT JOIN DBO.Employee AS E WITH (NOLOCK) ON WO.SalesPersonId = E.EmployeeId      
						 LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK) ON WO.CsrId = E1.EmployeeId      
	 
						 LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
						 LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
						 LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
					WHERE CAST((select [dbo].[ConvertUTCtoLocal] (WOBI.InvoiceDate,TZ.Description)) AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)      
						 AND WO.customerid=ISNULL(@customername,WO.customerid)      
						 AND WO.mastercompanyid = @mastercompanyid      
						 AND (ISNULL(@tagtype,'') ='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,ES.OrganizationTagTypeId), ',')))      
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
			UNION ALL  
  
			SELECT DISTINCT    
					COUNT(1) OVER () AS TotalRecordsCount,    
					CM.WorkOrderId,  
					UPPER(CM.CustomerName) 'customername',    
					UPPER(CM.CustomerCode) 'customercode',     
					UPPER(CMD.partnumber) 'pn',      
					UPPER(CMD.PartDescription) 'pndescription',      
					UPPER(CMD.SerialNumber) 'serialnum',      
					UPPER(WOPN.WorkScope) 'workscope',      
					UPPER(WO.WorkOrderNum) + ' (' + UPPER(CM.CreditMemoNumber) +')' AS 'wonum',  
					UPPER(WOQ.QuoteNumber) 'quotenum',      
					CM.InvoiceNumber 'invoicenum',      
					CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.ReceivedDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOPN.ReceivedDate, 107) END 'receiveddate',       
					CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (WO.OpenDate,TZ.Description)), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WO.OpenDate,TZ.Description)), 107) END 'opendate',       
					CASE WHEN ISNULL(@IsDownload,0) = 0 
							THEN CASE WHEN ISNULL(WOBI.InvoiceDate, '') = '' THEN '' ELSE FORMAT((select [dbo].[ConvertUTCtoLocal] (WOBI.InvoiceDate,TZ.Description)), 'MM/dd/yyyy') END 
							ELSE CASE WHEN ISNULL(WOBI.InvoiceDate, '') = '' THEN '' ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WOBI.InvoiceDate,TZ.Description)), 107) END END 'invoicedate',       
					CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOQ.OpenDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOQ.OpenDate, 107) END 'quotedate',       
					CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (WOQ.ApprovedDate,TZ.Description)), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WOQ.ApprovedDate,TZ.Description)), 107) END 'quoteapprovaldate',       
					CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOS.ShipDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOS.ShipDate, 107) END 'shipdate',      
					ISNULL(CM.Amount,0) 'revenue', 
					0 AS 'partscost',    
					0 AS 'laborcost',
					0 AS 'overheadcost',  
					0 AS 'directcost',   
					ISNULL(CM.Amount,0) 'margin',  
					0 AS 'partsrevper',    
					0 AS 'laborrevper',
					0 AS 'ohcostper',  
					0 AS 'revenueper',   
					((ISNULL(CM.Amount,0)  * 100))/ISNULL(CM.Amount,0)'grossmarginrevper',  

					--ISNULL(CM.Amount,0) 'revenue',      
					--ISNULL(WOC.PartsCost,0) 'partscost',      
					--ISNULL(WOC.LaborCost,0) 'laborcost',      
					--ISNULL(WOC.OverHeadCost,0) 'overheadcost',      
					--ISNULL(WOC.DirectCost,0) 'directcost',      
					--CASE WHEN ISNULL(WOC.DirectCost,0) != 0 THEN CONVERT(DECIMAL(10,4), ISNULL(WOBI.GrandTotal,0) - ISNULL(WOC.DirectCost,0))  ELSE ISNULL(WOBI.GrandTotal,0) END 'margin',      
					--CASE WHEN ISNULL(WOBI.GrandTotal,0) != 0 THEN CONVERT(DECIMAL(10,4), (ISNULL(WOC.PartsCost,0) / ISNULL(WOBI.GrandTotal,0))*100) ELSE 0 END 'partsrevper',      
					--CASE WHEN ISNULL(WOBI.GrandTotal,0) != 0 THEN CONVERT(DECIMAL(10,4), (ISNULL(WOC.LaborCost,0) / ISNULL(WOBI.GrandTotal,0))*100) ELSE 0 END 'laborrevper',      
					--CASE WHEN ISNULL(WOBI.GrandTotal,0) != 0 THEN CONVERT(DECIMAL(10,4), (ISNULL(WOC.OverHeadCost,0) / ISNULL(WOBI.GrandTotal,0))*100) ELSE 0 END 'ohcostper',      
					--CASE WHEN ISNULL(WOBI.GrandTotal,0) != 0 THEN CONVERT(DECIMAL(10,4), (ISNULL(WOC.DirectCost,0) / ISNULL(WOBI.GrandTotal,0))*100) ELSE 0 END  'revenueper',      
					--CASE WHEN ISNULL(WOBI.GrandTotal,0) != 0 THEN CONVERT(DECIMAL(10,4), ((ISNULL(WOBI.GrandTotal, 0) - ISNULL(WOC.DirectCost, 0)) / ISNULL(WOBI.GrandTotal,0))*100) ELSE 0 END 'grossmarginrevper',  
					CASE      
					  WHEN WOS.ShipDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)      
					  WHEN ApprovedDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)      
					  WHEN SentDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RCW.ReceivedDate)      
					  WHEN RCW.ReceivedDate IS NOT NULL THEN DATEDIFF(DAY, RCW.ReceivedDate, GETDATE())      
					END AS 'tat',      
					UPPER(E.FirstName + ' ' + E.LastName) 'salesperson',      
					UPPER(E1.FirstName + ' ' + E1.LastName) 'csr',      
					UPPER(MSD.Level1Name) AS level1, UPPER(MSD.Level2Name) AS level2, UPPER(MSD.Level3Name) AS level3, UPPER(MSD.Level4Name) AS level4, UPPER(MSD.Level5Name) AS level5,        
					UPPER(MSD.Level6Name) AS level6,UPPER(MSD.Level7Name) AS level7, UPPER(MSD.Level8Name) AS level8, UPPER(MSD.Level9Name) AS level9,UPPER(MSD.Level10Name) AS level10,  
					WO.MasterCompanyId AS masterCompanyId  
			 FROM DBO.CreditMemo CM WITH (NOLOCK)    
				  INNER JOIN DBO.CreditMemoDetails CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId  
				  LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON CM.ReferenceId = WO.WorkOrderId  
				  LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WO.WorkOrderId = WOPN.WorkOrderId    
				  LEFT JOIN DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON CM.InvoiceId = WOBI.BillingInvoicingId  
				  LEFT JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOBI.WorkOrderPartNoId = WOWF.WorkOrderPartNoId  
				  -- LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID  
				  LEFT JOIN DBO.Employee E WITH (NOLOCK) ON WO.SalesPersonId = E.EmployeeId  
				  LEFT JOIN DBO.Employee E1 WITH (NOLOCK) ON WO.CsrId = E1.EmployeeId  
				  LEFT JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId AND WOQ.IsVersionIncrease = 0     
				  INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = 2 AND MSD.ReferenceID = CMD.StocklineId      
				  LEFT JOIN DBO.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOPN.ID = WOC.WOPartNoId AND WO.WorkOrderId = WOC.WorkOrderId      
				  LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOPN.ID      
				  LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId    
				  LEFT JOIN DBO.ReceivingCustomerWork RCW WITH (NOLOCK) ON WO.WorkOrderId = RCW.WorkOrderId    
				  LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID     
      
				  LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
				  LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
				  LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
		   WHERE CAST(CM.CreatedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)      
				 AND CM.customerid=ISNULL(@customername,CM.customerid)      
				 AND CM.mastercompanyid = @mastercompanyid      
				 AND ISNULL(CM.IsWorkOrder,0) = 1  
				 AND (ISNULL(@tagtype,'') ='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,ES.OrganizationTagTypeId), ',')))      
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
  
  
			,FinalCTE(TotalRecordsCount, WorkOrderId, customername, customercode, pn, pndescription, serialnum, workscope, wonum, quotenum, invoicenum,   
			receiveddate, opendate,invoicedate,quotedate,quoteapprovaldate,shipdate, revenue, partscost,laborcost, overheadcost, directcost, margin, partsrevper, laborrevper, ohcostper, revenueper,   
			grossmarginrevper,tat, salesperson,csr, level1, level2, level3, level4, level5, level6, level7, level8,  
			   level9, level10, masterCompanyId)   
			 AS (SELECT DISTINCT TotalRecordsCount, WorkOrderId, customername, customercode, pn, pndescription, serialnum, workscope, wonum, quotenum, invoicenum,   
			receiveddate, opendate,invoicedate,quotedate,quoteapprovaldate,shipdate, revenue, partscost,laborcost, overheadcost, directcost, margin, partsrevper, laborrevper, ohcostper, revenueper,   
			grossmarginrevper,tat, salesperson,csr, level1, level2, level3, level4, level5, level6, level7, level8,  
			   level9, level10, masterCompanyId FROM rptCTE)  
  
		   ,WithTotal (masterCompanyId, TotalRevenue, TotalPartscost, TotalLaborcost, TotalOverheadcost, TotalDirectcost, TotalMargin, TotalPartsrevper, TotalLaborrevper, TotalOhcostper, TotalDirectCostPerc, TotalMarginPerc)   
			 AS (SELECT masterCompanyId,   
					FORMAT(SUM(revenue), 'N', 'en-us') TotalRevenue,  
					FORMAT(SUM(partscost), 'N', 'en-us') TotalPartscost,  
					FORMAT(SUM(laborcost), 'N', 'en-us') TotalLaborcost,  
					FORMAT(SUM(overheadcost), 'N', 'en-us') TotalOverheadcost,  
					FORMAT(SUM(directcost), 'N', 'en-us') TotalDirectcost,  
					FORMAT(SUM(margin), 'N', 'en-us') TotalMargin,  
					FORMAT((SUM(partscost) / SUM(revenue)) * 100, 'N', 'en-us') TotalPartsrevper,  
					FORMAT((SUM(laborcost) / SUM(revenue)) * 100, 'N', 'en-us') TotalLaborrevper,  
					FORMAT((SUM(overheadcost) / SUM(revenue)) * 100, 'N', 'en-us') TotalOhcostper,  
					FORMAT((SUM(directcost) / SUM(revenue)) * 100, 'N', 'en-us') TotalDirectCostPerc,  
					FORMAT(((SUM(revenue) - SUM(directcost)) / SUM(revenue)) * 100, 'N', 'en-us') TotalMarginPerc  
				FROM FinalCTE  
				GROUP BY masterCompanyId)  
  
			 SELECT COUNT(2) OVER () AS TotalRecordsCount, WorkOrderId, customername, customercode, pn, pndescription, serialnum, workscope, wonum, quotenum, invoicenum,   
				 receiveddate, opendate,invoicedate,quotedate,quoteapprovaldate,shipdate,   
				 FORMAT(ISNULL(revenue,0) , 'N', 'en-us') 'revenue',      
				 FORMAT(ISNULL(partscost,0) , 'N', 'en-us') 'partscost',      
				 FORMAT(ISNULL(laborcost,0) , 'N', 'en-us') 'laborcost',      
				 FORMAT(ISNULL(overheadcost,0) , 'N', 'en-us') 'overheadcost',      
				 FORMAT(ISNULL(directcost,0) , 'N', 'en-us') 'directcost',    
				 FORMAT(ISNULL(margin,0) , 'N', 'en-us') 'margin',      
				 FORMAT(ISNULL(partsrevper,0) , 'N', 'en-us') 'partsrevper',      
				 FORMAT(ISNULL(laborrevper,0) , 'N', 'en-us') 'laborrevper',      
				 FORMAT(ISNULL(ohcostper,0) , 'N', 'en-us') 'ohcostper',      
				 FORMAT(ISNULL(revenueper,0) , 'N', 'en-us') 'revenueper',   
				 FORMAT(ISNULL(grossmarginrevper,0) , 'N', 'en-us') 'grossmarginrevper',  
				 tat, salesperson,csr, level1, level2, level3, level4, level5, level6, level7, level8,  
				 level9, level10,  
				 WC.TotalRevenue,  
				 WC.TotalPartscost,  
				 WC.TotalLaborcost,  
				 WC.TotalOverheadcost,  
				 WC.TotalDirectcost,  
				 WC.TotalMargin,  
				 WC.TotalPartsrevper,  
				 WC.TotalLaborrevper,  
				 WC.TotalOhcostper,  
				 WC.TotalDirectCostPerc,  
				 WC.TotalMarginPerc  
			FROM FinalCTE FC  
				INNER JOIN WithTotal WC ON FC.masterCompanyId = WC.masterCompanyId  
			ORDER BY WorkOrderId DESC  
				OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;   
      
    COMMIT TRANSACTION      
  
  END TRY      
      
  BEGIN CATCH      
    ROLLBACK TRANSACTION      
      
    IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL      
    BEGIN      
      DROP TABLE #managmetnstrcture      
    END      
      
    DECLARE @ErrorLogID int,      
            @DatabaseName varchar(100) = DB_NAME()      
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
            ,      
            @AdhocComments varchar(150) = '[usprpt_GetWorkOrderMarginReport]',      
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