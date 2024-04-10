/*************************************************************               
 ** File:   [usprpt_GetWorkOrderBacklogReportNew]               
 ** Author:   Devendra Shekh      
 ** Description: Get Data for WorkOrderBacklog Report  new SP 
 ** Purpose:             
 ** Date:   10th April 2024     
              
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** S NO   Date         Author				Change Description                
 ** --   --------     -------			--------------------------------     
 **	1	10-04-2022   Devendra Shekh			created    
 
EXECUTE   [dbo].[usprpt_GetWorkOrderBacklogReportNew] 'WO Opened','','','','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60'    
**************************************************************/    
CREATE   PROCEDURE [dbo].[usprpt_GetWorkOrderBacklogReportNew]     
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
    @stage VARCHAR(300) = NULL,    
    @status VARCHAR(300) = NULL,    
    @wotype VARCHAR(300) = NULL,    
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
    
     DECLARE @ModuleID INT = 12; -- MS Module ID    
     SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END    
    
     SELECT @Fromdate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Received Date'     
     THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Fromdate END,    
    
     @Todate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Received Date'     
     THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Todate END,     
    
     @stage=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(500)')='Stage'     
     THEN filterby.value('(FieldValue/text())[1]','VARCHAR(500)') ELSE @stage END,    
    
     @status=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Status'     
     THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @status END,   
	 
	 @status=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Status'     
     THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @status END,  
    
     @wotype=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='WO Type'     
     THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @wotype END,    
    
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
  
     IF ISNULL(@PageSize,0)=0    
     BEGIN     
       SELECT @PageSize=COUNT(*)    
       FROM DBO.WorkOrder WO WITH (NOLOCK)      
      INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId     
      INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID    
      INNER JOIN DBO.ItemMaster AS IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId    
      INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID    
      LEFT JOIN DBO.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOPN.ID = WOC.WOPartNoId    
      LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID    
      LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId    
      LEFT JOIN DBO.WorkOrderStatus AS WOSS WITH (NOLOCK) ON WOPN.WorkOrderStatusId = WOSS.Id    
      LEFT JOIN DBO.WorkOrderType AS WOT WITH (NOLOCK)ON WO.WorkOrderTypeId = WOT.Id            
      LEFT JOIN DBO.ReceivingCustomerWork RCW WITH (NOLOCK) ON WO.ReceivingCustomerWorkId = RCW.ReceivingCustomerWorkId    
      LEFT JOIN DBO.Stockline STL WITH (NOLOCK) ON WOPN.StockLineId = STL.StockLineId and stl.IsParent=1    
      LEFT JOIN DBO.Employee E WITH (NOLOCK) ON WOPN.TechnicianId = E.EmployeeId         
       WHERE CAST(WO.opendate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)    
      AND WOT.Id = ISNULL(@wotype,WOT.Id) AND  ISNULL(WO.IsDeleted, 0) = 0  AND  ISNULL(WO.IsActive, 1) = 1  AND  ISNULL(WO.WorkOrderStatusId, 0) != 2 --WO Not Closed  
      AND  ISNULL(WOPN.WorkOrderStatusId, 0) != 2 AND  ISNULL(WOPN.IsClosed, 0) != 1 --WO Not Closed  
      AND (ISNULL(@stage,'') ='' OR WOS.WorkOrderStageId IN(SELECT value FROM String_split(ISNULL(@stage,WOS.WorkOrderStageId), ',')))     
      AND WOSS.Id = ISNULL(@status,WOSS.Id)     
      AND WO.mastercompanyid = @MasterCompanyId AND MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))    
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
    
    ;WITH rptCTE (TotalRecordsCount, WorkOrderId,customername, pn, pndescription, wonum, serialnum, wotype, stagecode, statuscode, receiveddate, opendate, approvedamount, unitcost, StocklineId, partscost, laborcost, overheadcost,  
    misccharge, othercost, total, wodayscount, techname, priority, workScope, quoteAmount, daysInStage, level1, level2, level3, level4, level5, level6, level7, level8,  
    level9, level10, masterCompanyId)  
    AS (SELECT 0 AS TotalRecordsCount,    
    WO.WorkOrderId,  
    UPPER(C.Name) 'customername',  
    UPPER(IM.partnumber) 'pn',    
    UPPER(IM.PartDescription) 'pndescription',    
    UPPER(WO.WorkOrderNum) 'wonum',    
    UPPER(SL.serialnumber) 'serialnum',    
    UPPER(WOT.Description) 'wotype',    
    UPPER(WOS.Stage) 'stagecode',    
    UPPER(WOSS.Description) 'statuscode',    
    CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.ReceivedDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), WOPN.ReceivedDate, 107) END 'receiveddate',     
    CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (WO.OpenDate,TZ.Description)), 'MM/dd/yyyy') ELSE convert(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WO.OpenDate,TZ.Description)), 107) END 'opendate',    
    CASE WHEN ISNULL(WQD.QuoteMethod,0) = 0 THEN ISNULL((WQD.MaterialFlatBillingAmount + WQD.LaborFlatBillingAmount + WQD.ChargesFlatBillingAmount + WQD.FreightFlatBillingAmount),0.00) ELSE ISNULL(WQD.CommonFlatRate,0.00)  END 'approvedamount',  
    ISNULL(SL.purchaseorderunitcost, 0) 'unitcost',    
    RCW.StocklineId,    
    CASE WHEN ISNULL(@IsDownload,0) = 0 THEN ISNULL(WOC.partscost, 0) ELSE CAST(ISNULL(WOC.partscost, 0) AS VARCHAR(20)) END 'partscost',     
    ISNULL(WOC.LaborCost, 0) 'laborcost',    
    ISNULL(WOC.ChargesCost, 0) + ISNULL(WOC.FreightCost, 0) 'misccharge',    
    ISNULL(WOC.OverHeadCost, 0) 'overheadcost',    
    ISNULL(WOC.OtherCost, 0) 'othercost',    
    (ISNULL(SL.PurchaseOrderUnitCost, 0) + ISNULL(WOC.PartsCost, 0) + ISNULL(WOC.LaborCost, 0) + ISNULL(WOC.OverHeadCost, 0) + ISNULL(WOC.OtherCost, 0)) 'total',    
    DATEDIFF(DAY, RCW.ReceivedDate, GETDATE()) AS 'wodayscount',    
    UPPER(E.FirstName + ' ' + E.LastName) 'techname',    
	UPPER(ISNULL(P.[Description], '')) AS 'priority',
	UPPER(ISNULL(WS.[WorkScopeCodeNew], '')) AS 'workScope',
	0 AS 'quoteAmount',
	0 AS 'daysInStage',
    UPPER(MSD.Level1Name) AS level1,      
    UPPER(MSD.Level2Name) AS level2,     
    UPPER(MSD.Level3Name) AS level3,     
    UPPER(MSD.Level4Name) AS level4,     
    UPPER(MSD.Level5Name) AS level5,     
    UPPER(MSD.Level6Name) AS level6,     
    UPPER(MSD.Level7Name) AS level7,     
    UPPER(MSD.Level8Name) AS level8,     
    UPPER(MSD.Level9Name) AS level9,     
    UPPER(MSD.Level10Name) AS level10 ,  
    WO.MasterCompanyId  
   FROM DBO.WorkOrder WO WITH (NOLOCK)      
    INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId     
    INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID    
    INNER JOIN DBO.ItemMaster AS IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId    
    INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID    
    LEFT JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId   
    LEFT JOIN DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WQD.WorkOrderQuoteId  
    LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = WO.CustomerId  
    LEFT JOIN DBO.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOPN.ID = WOC.WOPartNoId    
    LEFT JOIN DBO.Stockline SL WITH (NOLOCK) ON WOPN.StockLineId = SL.StockLineId AND SL.IsParent = 1    
    LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID    
    LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId    
    LEFT JOIN DBO.WorkOrderStatus AS WOSS WITH (NOLOCK) ON WOPN.WorkOrderStatusId = WOSS.Id    
    LEFT JOIN DBO.WorkOrderType AS WOT WITH (NOLOCK)ON WO.WorkOrderTypeId = WOT.Id            
    LEFT JOIN DBO.ReceivingCustomerWork RCW WITH (NOLOCK) ON WO.ReceivingCustomerWorkId = RCW.ReceivingCustomerWorkId        
    LEFT JOIN DBO.Employee E WITH (NOLOCK) ON WOPN.TechnicianId = E.EmployeeId 
    LEFT JOIN DBO.[Priority] P WITH (NOLOCK) ON WOPN.WorkOrderPriorityId = P.PriorityId 
    LEFT JOIN DBO.[WorkScope] WS WITH (NOLOCK) ON WOPN.WorkOrderScopeId = WS.WorkScopeId 
	
	 LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
     LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
     LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
   WHERE CAST((select [dbo].[ConvertUTCtoLocal] (WO.OpenDate,TZ.Description)) AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)    
    AND WOT.Id = ISNULL(@wotype,WOT.Id)  AND  ISNULL(WO.IsDeleted, 0) = 0  AND  ISNULL(WO.IsActive, 1) = 1 AND  ISNULL(WO.WorkOrderStatusId, 0) != 2 --WO Not Closed  
    AND  ISNULL(WOPN.WorkOrderStatusId, 0) != 2 AND  ISNULL(WOPN.IsClosed, 0) != 1 --MPN Not Closed  
    AND (ISNULL(@stage,'') ='' OR WOS.WorkOrderStageId IN(SELECT value FROM String_split(ISNULL(@stage,WOS.WorkOrderStageId), ',')))     
    AND WOSS.Id = ISNULL(@status,WOSS.Id)     
    AND WO.mastercompanyid = @MasterCompanyId AND MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))    
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
    
    ,finalCTE (WorkOrderId,customername, pn, pndescription, wonum, serialnum, wotype, stagecode, statuscode, receiveddate, opendate, approvedamount, unitcost, StocklineId, partscost, laborcost, overheadcost,  
    misccharge, othercost, total, wodayscount, techname, priority, workScope, quoteAmount, daysInStage, level1, level2, level3, level4, level5, level6, level7, level8,  
    level9, level10, masterCompanyId)  
    AS (SELECT DISTINCT WorkOrderId,customername, pn, pndescription, wonum, serialnum, wotype, stagecode, statuscode, receiveddate, rptCTE.opendate, approvedamount, unitcost, StocklineId, partscost, laborcost, overheadcost,  
    misccharge, othercost, total, wodayscount, techname, priority, workScope, quoteAmount, daysInStage, level1, level2, level3, level4, level5, level6, level7, level8,  
    level9, level10, masterCompanyId FROM rptCTE)  
  
    ,WithTotal (masterCompanyId, TotalApprovedAmount, TotalUnitCost, TotalPartsCost, TotalLaborCost, TotalMisccharge, TotalOverHeadcost, TotalOtherCost, TotalQuoteAmount, TotalCost)   
     AS (SELECT masterCompanyId,   
    FORMAT(SUM(approvedamount), 'N', 'en-us') TotalApprovedAmount,  
    FORMAT(SUM(unitcost), 'N', 'en-us') TotalUnitCost,  
    FORMAT(SUM(partscost), 'N', 'en-us') TotalPartsCost,  
    FORMAT(SUM(laborcost), 'N', 'en-us') TotalLaborCost,  
    FORMAT(SUM(misccharge), 'N', 'en-us') TotalMisccharge,  
    FORMAT(SUM(overheadcost), 'N', 'en-us') TotalOverHeadcost,  
    FORMAT(SUM(othercost), 'N', 'en-us') TotalOtherCost,  
    FORMAT(SUM(quoteAmount), 'N', 'en-us') TotalQuoteAmount,  
    FORMAT(SUM(total), 'N', 'en-us') TotalCost
    FROM FinalCTE  
    GROUP BY masterCompanyId)  
    
    SELECT COUNT(2) OVER () AS TotalRecordsCount, WorkOrderId, customername, pn, pndescription, wonum, serialnum, wotype, stagecode, statuscode, receiveddate, approvedamount , opendate, unitcost, StocklineId, partscost, laborcost, overheadcost,  
    misccharge, othercost, fc.total, wodayscount, techname, priority, workScope, daysInStage, quoteAmount, level1, level2, level3, level4, level5, level6, level7, level8,  
    level9, level10,   
    WC.TotalApprovedAmount,  
    WC.TotalUnitCost,  
    WC.TotalPartsCost,  
    WC.TotalLaborCost,  
    WC.TotalMisccharge,  
    WC.TotalOverHeadcost,  
    WC.TotalOtherCost,  
    WC.TotalQuoteAmount,  
    WC.TotalCost
    FROM finalCTE FC  
     INNER JOIN WithTotal WC ON FC.masterCompanyId = WC.masterCompanyId  
    ORDER BY WorkOrderId DESC  
    OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;    
    
    COMMIT TRANSACTION    
  END TRY    
    
  BEGIN CATCH    
  ROLLBACK TRANSACTION    
    DECLARE @ErrorLogID int,    
            @DatabaseName varchar(100) = DB_NAME()    
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            ,    
            @AdhocComments varchar(150) = '[usprpt_GetWorkOrderBacklogReportNew]',    
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +    
            '@Parameter3 = ''' + CAST(ISNULL(@stage, '') AS varchar(100)) +    
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +    
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +    
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +    
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +    
            '@Parameter8 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +    
            '@Parameter8 = ''' + CAST(ISNULL(@stage, '') AS varchar),    
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