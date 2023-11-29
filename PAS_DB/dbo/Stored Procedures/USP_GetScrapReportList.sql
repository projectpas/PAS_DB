/*************************************************************             
 ** File:   [USP_GetScrapReportList]             
 ** Author:   Subhash Saliya    
 ** Description: Get Data for WorkOrderBillingReport  
 ** Purpose:           
 ** Date:   18-Nov-2022       
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date         Author   Change Description              
 ** --   --------     -------  --------------------------------            
 1 18-Nov-2022  Subhash Saliya  Update to Angular Reports  
 2 25/08/2023   BHARGAV SALIYA   Convert Dates UTC To LegalEntity Time Zone       
EXECUTE   [dbo].[USP_GetScrapReportList] 'krunal','','','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,59','51,52,53'  
**************************************************************/  
Create    PROCEDURE [dbo].[USP_GetScrapReportList]   
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
  
  SELECT @Fromdate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date'   
   THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Fromdate END,  
  
   @Todate=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date'   
   THEN convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Todate END,  
  
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
     FROM dbo.WorkOrder WO WITH (NOLOCK)  
    INNER JOIN WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WO.WorkOrderId  
    INNER JOIN ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId=IM.ItemMasterId  
    INNER JOIN Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ST.IsParent = 1  
    INNER JOIN ScrapCertificate SC WITH (NOLOCK) ON SC.WorkOrderId=WO.WorkOrderId AND WOPN.ID=SC.workOrderPartNoId  
    LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = WOPN.ItemMasterId  
    INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID  
    LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID  
    LEFT JOIN ScrapReason SR WITH (NOLOCK) ON SR.Id=SC.ScrapReasonId   
    LEFT JOIN vendor vo WITH (NOLOCK) ON vo.vendorid=SC.ScrapedByVendorId   
    LEFT JOIN employee EM WITH (NOLOCK) ON EM.EmployeeId=SC.ScrapedByEmployeeId   
    LEFT JOIN employee EMc WITH (NOLOCK) ON EMc.EmployeeId=SC.CertifiedById   
    WHERE CAST(SC.CreatedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) AND SC.IsDeleted = 0  
     AND WO.mastercompanyid = @mastercompanyid  
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
  
  --INSERT INTO #tmpBilling  
  SELECT COUNT(1) OVER () AS TotalRecordsCount,  
   UPPER(WO.customerName) 'customername',  
   UPPER(ST.ControlNumber) 'cntrlNum',  
   UPPER(IM.partnumber) 'partNumber',  
   UPPER(IM.PartDescription) 'partDescription',  
   UPPER(ST.SerialNumber) 'serialNumber',  
   UPPER(case when isnull(SC.IsExternal,0)  =1 then vo.vendorName else (EM.FirstName +'  '+EM.LastName) end) 'scrapedByEmployee',  
   UPPER(WO.WorkOrderNum) 'workOrderNumber',  
   UPPER(SR.Reason) 'scrapReason',  
   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (SC.CreatedDate,TZ.Description)), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (SC.CreatedDate,TZ.Description)), 107) END 'createdDate',   
   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT((select [dbo].[ConvertUTCtoLocal] (SC.updatedDate,TZ.Description)), 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (SC.updatedDate,TZ.Description)), 107) END 'updatedDate',   
   UPPER(MSD.Level1Name) AS level1,      UPPER(MSD.Level2Name) AS level2,     UPPER(MSD.Level3Name) AS level3,     UPPER(MSD.Level4Name) AS level4,     UPPER(MSD.Level5Name) AS level5,     UPPER(MSD.Level6Name) AS level6,     UPPER(MSD.Level7Name) AS level7,     UPPER(MSD.Level8Name) AS level8,     UPPER(MSD.Level9Name) AS level9,     UPPER(MSD.Level10Name) AS level10   
  INTO #tmpBilling  
  FROM dbo.WorkOrder WO WITH (NOLOCK)  
    INNER JOIN WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WO.WorkOrderId  
    INNER JOIN ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId=IM.ItemMasterId  
    INNER JOIN Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ST.IsParent = 1  
    INNER JOIN ScrapCertificate SC WITH (NOLOCK) ON SC.WorkOrderId=WO.WorkOrderId AND WOPN.ID=SC.workOrderPartNoId  
    LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = WOPN.ItemMasterId  
    INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID  
    LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID  
    LEFT JOIN ScrapReason SR WITH (NOLOCK) ON SR.Id=SC.ScrapReasonId   
    LEFT JOIN vendor vo WITH (NOLOCK) ON vo.vendorid=SC.ScrapedByVendorId   
    LEFT JOIN employee EM WITH (NOLOCK) ON EM.EmployeeId=SC.ScrapedByEmployeeId   
    LEFT JOIN employee EMc WITH (NOLOCK) ON EMc.EmployeeId=SC.CertifiedById   

	LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
    LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
    LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
   WHERE  CAST((select [dbo].[ConvertUTCtoLocal] (SC.CreatedDate,TZ.Description)) AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) AND SC.IsDeleted = 0  
    AND WO.mastercompanyid = @mastercompanyid  
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
   ORDER BY IM.partnumber  
   OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;  
  
   SELECT DISTINCT * FROM #tmpBilling  
  
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
            @AdhocComments varchar(150) = '[USP_GetScrapReportList]',  
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