  
/*************************************************************               
 ** File:   [usprpt_GetWorkOrderBacklogCustomerServiceReport]               
 ** Author:   Rajesh Gami      
 ** Description: Get Data for WorkOrderBacklog Customer Service Report    
 ** Purpose:             
 ** Date:   17-August-2022       
              
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** S NO   Date         Author   Change Description                
 ** --   --------     -------  --------------------------------     
 1 17-08-2023   Rajesh CREATED  
 2 25-Aug-2023  Bhargav Saliya   Convert Dates UTC To LegalEntity Time Zone
  
          
**************************************************************/    
CREATE    PROCEDURE [dbo].[usprpt_GetWorkOrderBacklogCustomerServiceReport]     
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
    @Fromdate DATETIME,    
    @Todate DATETIME,    
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
    DECLARE @customerid varchar(40) = NULL  
  
     DECLARE @ModuleID INT = 12; -- MS Module ID    
     SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END    
    
     SELECT @Fromdate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date'     
     THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Fromdate END,    
    
     @Todate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date'     
     THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Todate END,    
    
      @customerid = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer(Optional)'         
   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @customerid END,   
     
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
      LEFT JOIN dbo.WorkOrderTurnArroundTime WTT WITH(NOLOCK) ON WTT.WorkOrderPartNoId = WOPN.ID AND WOPN.WorkOrderStageId = WTT.CurrentStageId  
      LEFT JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId   
      LEFT JOIN DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WQD.WorkOrderQuoteId  
      LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = WO.CustomerId  
      LEFT JOIN DBO.WorkOrderShipping woshi WITH (NOLOCK) ON WO.WorkOrderId = woshi.WorkOrderId  
      LEFT JOIN DBO.Stockline SL WITH (NOLOCK) ON WOPN.StockLineId = SL.StockLineId AND SL.IsParent = 1    
      LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID    
      LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId    
       WHERE  WO.CustomerId=ISNULL(@customerid,WO.CustomerId) AND CAST(WO.opendate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)    
      AND  ISNULL(WO.IsDeleted, 0) = 0  AND  ISNULL(WO.IsActive, 1) = 1 AND  ISNULL(WO.WorkOrderStatusId, 0) != 2 --WO Not Closed  
      AND  ISNULL(WOPN.WorkOrderStatusId, 0) != 2 AND  ISNULL(WOPN.IsClosed, 0) != 1 --MPN Not Closed  
      AND WO.WorkOrderId NOT IN(ISNULL(woshi.WorkOrderId,0))  
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
    
    ;WITH rptCTE (TotalRecordsCount, WorkOrderId,customername, pn, pndescription,ronum, wonum, serialnum, stagecode, totalDaysinStage, opendate,requestdate,promisedate,estshipdate,shipdate,requestdatesince,  
    promisedatesince,estshipdatesince,shipdatesince,level1, level2, level3, level4, level5, level6, level7, level8,level9, level10, masterCompanyId)  
    AS (SELECT 0 AS TotalRecordsCount,    
    WO.WorkOrderId,  
    MAX(UPPER(C.Name)) 'customername',  
    MAX(UPPER(IM.partnumber)) 'pn',    
    MAX(UPPER(IM.PartDescription)) 'pndescription',    
    --MAX(ISNULL((SELECT ISNULL(MAX(RepairOrderNumber),0) FROM dbo.RepairOrder rep WITH(NOLOCK) where rep.RepairOrderId = SL.RepairOrderId),0)) 'ronum',  
    MAX(ISNULL(ro.RepairOrderNumber,'')) 'ronum',  
    MAX(UPPER(WO.WorkOrderNum)) 'wonum',    
    MAX(UPPER(SL.serialnumber)) 'serialnum',    
    MAX(UPPER(WOS.Stage)) 'stagecode',    
    (isnull((sum(WTT.[Days])+ (sum(WTT.[Hours])/24)+ (sum(WTT.[Mins])/1440)),0)) + ISNULL(DATEDIFF(day, Max(WTT.StatusChangedDate), GETDATE()), 0) as totalDaysinStage,  
    CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))), 'MM/dd/yyyy') ELSE convert(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (MAX(WO.OpenDate),Max(TZ.Description))), 107) END 'opendate',  
    CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(MAX(WOPN.CustomerRequestDate), 'MM/dd/yyyy') ELSE convert(VARCHAR(50), MAX(WOPN.CustomerRequestDate), 107) END 'requestdate',    
    CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(MAX(WOPN.PromisedDate), 'MM/dd/yyyy') ELSE convert(VARCHAR(50), MAX(WOPN.PromisedDate), 107) END 'promisedate',    
    CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(MAX(WOPN.EstimatedShipDate), 'MM/dd/yyyy') ELSE convert(VARCHAR(50), MAX(WOPN.EstimatedShipDate), 107) END 'estshipdate',  
    CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(MAX(woshi.ShipDate), 'MM/dd/yyyy') ELSE convert(VARCHAR(50), MAX(woshi.ShipDate), 107) END 'shipdate',  
    (CASE WHEN MAX(WOPN.CustomerRequestDate) is not null THEN  ISNULL(DATEDIFF(day, Max(WOPN.CustomerRequestDate), GETDATE()), '') ELSE '' END) 'requestdatesince',  
    (CASE WHEN MAX(WOPN.PromisedDate) is not null THEN  ISNULL(DATEDIFF(day, Max(WOPN.PromisedDate), GETDATE()), '') ELSE '' END) 'promisedatesince',  
    (CASE WHEN MAX(WOPN.EstimatedShipDate) is not null THEN  ISNULL(DATEDIFF(day, Max(WOPN.EstimatedShipDate), GETDATE()), '') ELSE '' END)  'estshipdatesince',  
    (CASE WHEN ISNULL(MAX(woshi.ShipDate),'') != '' THEN  ISNULL(DATEDIFF(day, Max(woshi.ShipDate), GETDATE()), '') ELSE '' END) 'shipdatesince',  
    UPPER(MAX(MSD.Level1Name)) AS level1,      
    UPPER(MAX(MSD.Level2Name)) AS level2,     
    UPPER(MAX(MSD.Level3Name)) AS level3,     
    UPPER(MAX(MSD.Level4Name)) AS level4,     
    UPPER(MAX(MSD.Level5Name)) AS level5,     
    UPPER(MAX(MSD.Level6Name)) AS level6,     
    UPPER(MAX(MSD.Level7Name)) AS level7,     
    UPPER(MAX(MSD.Level8Name)) AS level8,     
    UPPER(MAX(MSD.Level9Name)) AS level9,     
    UPPER(MAX(MSD.Level10Name)) AS level10 ,  
    MAX(WO.MasterCompanyId) MasterCompanyId  
   FROM DBO.WorkOrder WO WITH (NOLOCK)      
    INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId     
    INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID    
    INNER JOIN DBO.ItemMaster AS IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId    
    INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID    
    LEFT JOIN dbo.WorkOrderTurnArroundTime WTT WITH(NOLOCK) ON WTT.WorkOrderPartNoId = WOPN.ID AND WOPN.WorkOrderStageId = WTT.CurrentStageId  
    LEFT JOIN dbo.RepairOrder RO WITH(NOLOCK) ON WOPN.RepairOrderId = RO.RepairOrderId  
    LEFT JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId   
    LEFT JOIN DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WQD.WorkOrderQuoteId  
    LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = WO.CustomerId  
    LEFT JOIN DBO.WorkOrderShipping woshi WITH (NOLOCK) ON WO.WorkOrderId = woshi.WorkOrderId  
    LEFT JOIN DBO.Stockline SL WITH (NOLOCK) ON WOPN.StockLineId = SL.StockLineId AND SL.IsParent = 1    
    LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID    
    LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId   
	
	LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
    LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
    LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
   WHERE    
    WO.CustomerId=ISNULL(@customerid,WO.CustomerId) AND   
    CAST((select [dbo].[ConvertUTCtoLocal] (WO.OpenDate,TZ.Description)) AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)  AND  
     ISNULL(WO.IsDeleted, 0) = 0  AND  ISNULL(WO.IsActive, 1) = 1 AND  ISNULL(WO.WorkOrderStatusId, 0) != 2 -----WO Not Closed  
    AND  ISNULL(WOPN.WorkOrderStatusId, 0) != 2 AND  ISNULL(WOPN.IsClosed, 0) != 1 -----MPN Not Closed  
    AND WO.WorkOrderId NOT IN(ISNULL(woshi.WorkOrderId,0))  
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
  
     GROUP BY WO.WorkOrderId  
     )  
      
    
    ,finalCTE (WorkOrderId,customername, pn, pndescription,ronum, wonum, serialnum, stagecode, totalDaysinStage, opendate,requestdate,promisedate,estshipdate,shipdate,requestdatesince,  
    promisedatesince,estshipdatesince,shipdatesince,level1, level2, level3, level4, level5, level6, level7, level8,level9, level10, masterCompanyId)  
    AS (SELECT DISTINCT WorkOrderId,customername, pn, pndescription,ronum, wonum, serialnum, stagecode, totalDaysinStage, opendate,requestdate,promisedate,estshipdate,shipdate,requestdatesince,  
    promisedatesince,estshipdatesince,(CASE WHEN shipdatesince = '0' THEN ''  ELSE shipdatesince END),level1, level2, level3, level4, level5, level6, level7, level8,level9, level10, masterCompanyId FROM rptCTE)  
  
    SELECT COUNT(2) OVER () AS TotalRecordsCount, WorkOrderId,customername, pn, pndescription,ronum, wonum, serialnum, stagecode, totalDaysinStage, opendate,requestdate,promisedate,estshipdate,shipdate,requestdatesince,  
    promisedatesince,estshipdatesince,(CASE WHEN shipdatesince = '0' THEN ''  ELSE shipdatesince END)shipdatesince,level1, level2, level3, level4, level5, level6, level7, level8,level9, level10   
    FROM finalCTE FC  
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
            @AdhocComments varchar(150) = '[usprpt_GetWorkOrderBacklogCustomerServiceReport]',    
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +    
            '@Parameter3 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +    
            '@Parameter4 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +    
            '@Parameter5 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +    
            '@Parameter6 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +    
            '@Parameter7 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),   
  
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