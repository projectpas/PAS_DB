/*************************************************************             
 ** File:   [usp_GetWorkOrderTATReport]             
 ** Author:   Hemant    
 ** Description: Get Data for WorkOrderTAT Report  
 ** Purpose:           
 ** Date:   30-APR-2022        
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date         Author   Change Description              
 ** --   --------     -------  --------------------------------            
 1 30-APR-2022  Hemant  Convert to Angular Reports  
 2 24/08/2023   BHARGAV SALIYA   Convert Dates UTC To LegalEntity Time Zone      
 3 01/31/2024   Devendra Shekh	added isperforma Flage for WO 
 4 03/29/2024   Ekta Chandegra	IsDeleted and IsActive flag is added
 5 12-12-2024   Shrey Chandegara  Modify Due to change calculation of quotedays ,approvedays,shipdays and tatdays and add another filter
 6 09-Jan-2025	Devendra Shekh	Reading Revised PN details if exists
 7 03-Jul-2025	Devendra Shekh	Added @Stage for Filtering, Removed ConvertUTCtoLocal function, using BaseUtcOffsetSec for date conversion
 8 08-dec-2025  Ayushi Patel	changed the table name workOrderBillingInvoicing -> BillingInvoicing
 9 11-Dec-2025  Ayushi Patel     Mapped BillingInvoicing through BillingInvoicingItems
 10 23-Dec-2025  Ayushi Patel	 Get The Newly versioned invoice 
	11    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
EXECUTE   [dbo].[usp_GetWorkOrderTATReport]   
**************************************************************/  
--EXEC usp_GetWorkOrderTATReport  '1,4,43,44,45,80,84,88','46,47','58,59','64,65,77'  
CREATE    PROCEDURE [dbo].[usprpt_GetWorkOrderTATReport]   
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
  
     DECLARE   
  @customername VARCHAR(40) = NULL,
  @Stage VARCHAR(300) = NULL,
  @Fromdate DATETIME,  
  @Todate DATETIME,  
  @itemMasterId VARCHAR(50) = NULL,  
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
  
  DECLARE @ModuleID INT = 12; -- MS Module ID  
  DECLARE @WoModuleID AS BIGINT = (select ModuleId from DBO.Module WITH (NOLOCK) where ModuleName = 'WorkOrder')
  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END  
  
  SELECT @Fromdate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Shipped Date'   
   THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Fromdate END,  
  
   @Todate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Shipped Date'   
   THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Todate END,  
  
   @itemMasterId=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='PN(Optional)'   
   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @itemMasterId END,  
  
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
   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 end,
   
   @Stage=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(500)')='Stage'     
   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(500)') ELSE @Stage END
  
    FROM @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)  


	IF OBJECT_ID(N'tempdb..#tmpTop10TATData') IS NOT NULL
	BEGIN
		DROP TABLE #tmpTop10TATData
	END

	IF OBJECT_ID(N'tempdb..#Result') IS NOT NULL
	BEGIN
		DROP TABLE #Result
	END

	IF OBJECT_ID(N'tempdb..#finalSumData') IS NOT NULL
	BEGIN
		DROP TABLE #finalSumData
	END


		;WITH TimeSums AS (
		SELECT 
				SUM(WT.Days) AS TotalDays, 
				SUM(WT.Hours) AS TotalHours, 
				SUM(WT.Mins) AS TotalMinutes,
				WOP.ID,
				WT.CurrentStageId
		FROM dbo.[WorkOrderPartNumber] WOP WITH(NOLOCK)
			INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
			INNER JOIN dbo.WorkOrderTurnArroundTime WT WITH (NOLOCK) ON WT.WorkOrderPartNoId = WOP.ID 
			INNER JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOP.ID
			INNER JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId
		WHERE CAST(@Fromdate AS DATE) <= CAST(WOS.ShipDate AS DATE) AND CAST(WOS.ShipDate AS DATE) <= CAST(@Todate AS DATE)
			AND WO.customerid=ISNULL(@customername,WO.customerid)  
			AND WO.mastercompanyid = @mastercompanyid  
			AND WO.IsDeleted = 0 AND WO.IsActive = 1
			AND  ISNULL(WT.StatusChangedEndDate,0) != 0
			GROUP BY WOP.ID,WT.CurrentStageId
			
		UNION

		SELECT 
				0 AS TotalDays, 
				0 AS TotalHours, 
				SUM(DATEDIFF(MINUTE, WT.StatusChangedDate, GETUTCDATE())) AS TotalMinutes,
				WOP.ID,
				WT.CurrentStageId
		FROM dbo.[WorkOrderPartNumber] WOP WITH(NOLOCK)
			INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
			INNER JOIN dbo.WorkOrderTurnArroundTime WT WITH (NOLOCK) ON WT.WorkOrderPartNoId = WOP.ID 
			INNER JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOP.ID
			INNER JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId
		WHERE CAST(@Fromdate AS DATE) <= CAST(WOS.ShipDate AS DATE) AND CAST(WOS.ShipDate AS DATE) <= CAST(@Todate AS DATE)
			AND WO.customerid=ISNULL(@customername,WO.customerid)  
			AND WO.mastercompanyid = @mastercompanyid  
			AND WO.IsDeleted = 0 AND WO.IsActive = 1
			AND ISNULL(WT.StatusChangedEndDate,0) = 0
			GROUP BY WOP.ID,WT.CurrentStageId),

		timeSumData AS (
		select TotalDays, TotalHours, TotalMinutes, ID, CurrentStageId,QuoteDays,ApprovedDays,ShippedDays,IncludeInTAT,0 as TotalRecDays
		FROM TimeSums WT
		LEFT JOIN dbo.WorkOrderStage WS WITH (NOLOCK) ON WS.WorkOrderStageId = WT.CurrentStageId
		)

		SELECT
			TotalDays, TotalHours, TotalMinutes, ID, CurrentStageId,QuoteDays,ApprovedDays,ShippedDays,IncludeInTAT,TotalRecDays
		INTO #tmpTop10TATData
		FROM timeSumData

		select SUM(TotalDays + (TotalHours / 24.0) + (TotalMinutes / 1440.0)) AS totaldays , ID, CurrentStageId
		INTO #finalSumData
		FROM #tmpTop10TATData
		GROUP BY CurrentStageId, ID


  
	  IF ISNULL(@PageSize,0)=0  
	  BEGIN   
	   SELECT @PageSize=COUNT(*)  
	   FROM DBO.WorkOrder WO WITH (NOLOCK)  
		   INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId   
		   INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID  
		   INNER JOIN DBO.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID  
		   LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
		   LEFT JOIN DBO.BillingInvoicingItems WBII ON WBII.SubReferenceId = WOPN.ID AND WBII.ModuleId = @WoModuleID and ISNULL(WBII.IsVersionIncrease,0)=0
		   LEFT JOIN DBO.BillingInvoicing AS WOBI WITH (NOLOCK) ON WBII.BillingInvoicingId = WOBI.BillingInvoicingId and ISNULL(WOBI.IsVersionIncrease,0)=0 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 AND WOBI.ModuleId = @WoModuleID
		   --LEFT JOIN DBO.BillingInvoicing WOBI WITH (NOLOCK) ON WO.WorkOrderId = WOBI.ReferenceId AND ISNULL(WOBI.IsVersionIncrease, 0)=0 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0  
		   LEFT JOIN DBO.Condition CN WITH (NOLOCK) ON WOPN.ConditionId = CN.ConditionId  
		   LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK) ON WO.WorkOrderId = woq.WorkOrderId AND woq.IsVersionIncrease=0  
		   LEFT JOIN DBO.WorkOrderType WITH (NOLOCK) ON WO.WorkOrderTypeId = WorkOrderType.Id  
		   LEFT JOIN DBO.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId  
		   LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId  
		    AND ISNULL(IM.IsNonStock,0) = 0 LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOPN.ID  
		   LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId  
		   LEFT JOIN DBO.Employee AS E WITH (NOLOCK) ON WOPN.TechnicianId = E.EmployeeId  
	  WHERE CAST(@Fromdate AS DATE) <= CAST(WOS.ShipDate AS DATE) AND CAST(WOS.ShipDate AS DATE) <= CAST(@Todate AS DATE)  
			AND WO.customerid=ISNULL(@customername,WO.customerid)  
			AND WO.mastercompanyid = @mastercompanyid 
			AND WO.IsDeleted = 0 AND WO.IsActive = 1 AND WOPN.ItemMasterId = ISNULL(@itemMasterId,WOPN.ItemMasterId)
			AND (ISNULL(@Stage,'') ='' OR WOPN.WorkOrderStageId IN(SELECT value FROM String_split(ISNULL(@Stage,WOPN.WorkOrderStageId), ',')))
			--AND (ISNULL(@tagtype,'') ='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,ES.OrganizationTagTypeId), ',')))  
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
	   END  
  
	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END  
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END  
  
	  SELECT COUNT(1) OVER () AS TotalRecordsCount,    
		   UPPER(C.Name) 'customername',  
		   UPPER(C.CustomerCode) 'customercode',  
		   CASE WHEN ISNULL(WOPN.RevisedPartNumber, '') = '' THEN UPPER(IM.partnumber) ELSE UPPER(WOPN.RevisedPartNumber) END 'pn',  
		   CASE WHEN ISNULL(WOPN.RevisedPartDescription, '') = '' THEN UPPER(IM.PartDescription) ELSE UPPER(WOPN.RevisedPartDescription) END 'pndescription',  
		   WOPN.Quantity 'qty',  
		   UPPER(WOPN.WorkScope) 'workscope',  
		   CASE WHEN ISNULL(RCN.Description, '') = '' THEN UPPER(CN.Description) ELSE UPPER(RCN.Description) END 'condition',  
		   UPPER(WO.WorkOrderNum) 'wonum',  
		   WOBI.InvoiceNo 'invoicenum',  
		   DATEDIFF(DAY, WOPN.ReceivedDate, WOQ.sentDate) 'quotedays',
		   0 AS 'quotedaysavg',
		   DATEDIFF(DAY, WOQ.sentDate, WOQ.approveddate) 'approveddays',  
		   0 AS 'approveddaysavg',
		   DATEDIFF(DAY, WOQ.approveddate, WOPN.EstimatedShipDate) 'estshipdays', 
		   0 AS 'estshipdaysavg',
		   DATEDIFF(DAY, WOQ.approveddate, WOPN.EstimatedShipDate) + DATEDIFF(DAY, WOPN.ReceivedDate, WOQ.sentDate) 'tat',  
		   0 AS 'tatavg',
  
		   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.ReceivedDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOPN.ReceivedDate, 107) END 'receiveddate',   
		   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select DATEADD(SECOND, TZ.BaseUtcOffsetSec, WO.OpenDate)), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), (select DATEADD(SECOND, TZ.BaseUtcOffsetSec, WO.OpenDate)), 107) END 'opendate',   
		   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOQ.SentDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOQ.SentDate, 107) END 'quotedate',   
		   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select DATEADD(SECOND, TZ.BaseUtcOffsetSec, WOQ.approveddate)), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), (select DATEADD(SECOND, TZ.BaseUtcOffsetSec, WOQ.approveddate)), 107) END 'approveddate',   
		   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.EstimatedShipDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOPN.EstimatedShipDate, 107) END 'estshipdate',   
		   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select DATEADD(SECOND, TZ.BaseUtcOffsetSec, WOBI.InvoiceDate)), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), (select DATEADD(SECOND, TZ.BaseUtcOffsetSec, WOBI.InvoiceDate)), 107) END 'invoicedate',   
     
		   UPPER(E.FirstName + ' ' + E.LastName) 'techname',  
		   UPPER(MSD.Level1Name) AS level1,      UPPER(MSD.Level2Name) AS level2,     UPPER(MSD.Level3Name) AS level3,     UPPER(MSD.Level4Name) AS level4,     UPPER(MSD.Level5Name) AS level5,     UPPER(MSD.Level6Name) AS level6,     UPPER(MSD.Level7Name) AS level7,     UPPER(MSD.Level8Name) AS level8,     UPPER(MSD.Level9Name) AS level9,     UPPER(MSD.Level10Name) AS level10  ,
		   TZ.TimeZoneName AS 'TIMEZONE_NAME',
			WOPN.ID ,
			WOPN.mastercompanyid,
			WOPN.WorkOrderStage AS 'workorderstage'
	  INTO #Result
	  FROM DBO.WorkOrder WO WITH (NOLOCK)  
	   INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId   
	   INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID 
	   INNER JOIN DBO.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID  
	   LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID  
	   LEFT JOIN DBO.BillingInvoicingItems WBII ON WBII.SubReferenceId = WOPN.ID AND WBII.ModuleId = @WoModuleID and ISNULL(WBII.IsVersionIncrease,0)=0
	   LEFT JOIN DBO.BillingInvoicing AS WOBI WITH (NOLOCK) ON WBII.BillingInvoicingId = WOBI.BillingInvoicingId and ISNULL(WOBI.IsVersionIncrease,0)=0 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 AND WOBI.ModuleId = @WoModuleID
	   --LEFT JOIN DBO.BillingInvoicing WOBI WITH (NOLOCK) ON WO.WorkOrderId = WOBI.ReferenceId AND ISNULL(WOBI.IsVersionIncrease, 0)=0 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 
	   LEFT JOIN DBO.Condition CN WITH (NOLOCK) ON WOPN.ConditionId = CN.ConditionId  
	   LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK) ON WO.WorkOrderId = woq.WorkOrderId AND woq.IsVersionIncrease=0  
	   LEFT JOIN DBO.WorkOrderType WITH (NOLOCK) ON WO.WorkOrderTypeId = WorkOrderType.Id  
	   LEFT JOIN DBO.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId  
	   LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId  
	    AND ISNULL(IM.IsNonStock,0) = 0 LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOPN.ID  
	   LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId  
	   LEFT JOIN DBO.Employee AS E WITH (NOLOCK) ON WOPN.TechnicianId = E.EmployeeId  

	   LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
	   LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
	   LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
	   LEFT JOIN [dbo].[Condition] RCN WITH (NOLOCK) ON WOPN.RevisedConditionId = RCN.ConditionId
	  WHERE CAST(@Fromdate AS DATE) <= CAST(WOS.ShipDate AS DATE) AND CAST(WOS.ShipDate AS DATE) <= CAST(@Todate AS DATE)
		AND WO.customerid=ISNULL(@customername,WO.customerid)  
		AND WO.mastercompanyid = @mastercompanyid  
		AND WO.IsDeleted = 0 AND WO.IsActive = 1 AND WOPN.ItemMasterId = ISNULL(@itemMasterId,WOPN.ItemMasterId)
		AND (ISNULL(@Stage,'') ='' OR WOPN.WorkOrderStageId IN(SELECT value FROM String_split(ISNULL(@Stage,WOPN.WorkOrderStageId), ',')))
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
 

 		UPDATE TP 
		SET TP.approveddays = CASE WHEN  ISNULL(daysResult.totaldays, 0) >= 1 THEN ISNULL(daysResult.totaldays, 0) ELSE 0 END   
		FROM #Result TP
		OUTER APPLY (
		SELECT SUM(tm1.totaldays) AS totaldays FROM
		#finalSumData tm1
		left join #tmpTop10TATData tm2 on tm2.CurrentStageId = tm1.CurrentStageId and tm1.ID = tm2.ID
		WHERE ISNULL(ApprovedDays,0) = 1 AND TP.ID = tm1.ID
		) daysResult

		UPDATE TP 
		SET TP.quotedays = CASE WHEN  ISNULL(daysResult.totaldays, 0) >= 1 THEN ISNULL(daysResult.totaldays, 0) ELSE 0 END   
		FROM #Result TP
		OUTER APPLY (
		SELECT SUM(tm1.totaldays) AS totaldays FROM
		#finalSumData tm1
		left join #tmpTop10TATData tm2 on tm2.CurrentStageId = tm1.CurrentStageId and tm1.ID = tm2.ID
		WHERE ISNULL(quotedays,0) = 1 AND TP.ID = tm1.ID
		) daysResult

		UPDATE TP 
		SET TP.estshipdays = CASE WHEN  ISNULL(daysResult.totaldays, 0) >= 1 THEN ISNULL(daysResult.totaldays, 0) ELSE 0 END   
		FROM #Result TP
		OUTER APPLY (
		SELECT SUM(tm1.totaldays) AS totaldays FROM
		#finalSumData tm1
		left join #tmpTop10TATData tm2 on tm2.CurrentStageId = tm1.CurrentStageId and tm1.ID = tm2.ID
		WHERE ISNULL(ShippedDays,0) = 1 AND TP.ID = tm1.ID
		) daysResult

		UPDATE TP 
		SET TP.tat = CASE WHEN  ISNULL(daysResult.totaldays, 0) >= 1 THEN ISNULL(daysResult.totaldays, 0) ELSE 0 END   
		FROM #Result TP
		OUTER APPLY (
		SELECT SUM(tm1.totaldays) AS totaldays FROM
		#finalSumData tm1
		left join #tmpTop10TATData tm2 on tm2.CurrentStageId = tm1.CurrentStageId and tm1.ID = tm2.ID
		WHERE ISNULL(IncludeInTAT,0) = 1 AND TP.ID = tm1.ID
		) daysResult

	 ;with AvgDaysTotal as (
		select 
		SUM(quotedays) as quotedaysavg,
		SUM(approveddays) as approveddaysavg,
		SUM(estshipdays) as estshipdaysavg,
		SUM(tat) as tatavg,
		MasterCompanyid
		from #Result group by MasterCompanyid)

	 UPDATE WOPN 
	 set WOPN.quotedaysavg =  tt.quotedaysavg,WOPN.approveddaysavg = tt.approveddaysavg,WOPN.estshipdaysavg = tt.estshipdaysavg,WOPN.tatavg = tt.tatavg
	 from #Result WOPN
	 left join AvgDaysTotal tt on tt.MasterCompanyid = WOPN.MasterCompanyId
 
	 select * from #Result
	 ORDER BY CAST(OpenDate AS DATE)  
	   OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;  
  
    COMMIT TRANSACTION  
  END TRY  
  
  BEGIN CATCH  
    ROLLBACK TRANSACTION  
  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[usprpt_GetWorkOrderTATReport]',  
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