/*************************************************************             
 ** File:   [usprpt_GetRCWReport]             
 ** Author:   HEMANT SALIYA    
 ** Description: Get Data for RCW Report   
 ** Purpose:           
 ** Date:   15-APR-2022         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO		Date			Author				Change Description              
 ** --		--------		-------------		--------------------------------            
    1		15-APR-2022		HEMANT SALIYA			Created  
	2		16-JUNE-2023     Devendra Shekh			made changes to do total
	3		29-MARCH-2024    Ekta Chandegra			IsActive and IsDeleted flag is added
  
       
--EXECUTE   [dbo].[usprpt_GetRCWReport] '','2021-06-15','2022-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'  
**************************************************************/  
CREATE   PROCEDURE [dbo].[usprpt_GetRCWReport]   
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
    
  DECLARE @customername VARCHAR(40) = NULL,  
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
    
  DECLARE @ModuleID INT = 1; -- MS Module ID  
  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END  
  
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
  
    IF ISNULL(@PageSize,0)=0  
   BEGIN   
     SELECT @PageSize=COUNT(*)  
      FROM DBO.ReceivingCustomerWork RCW WITH (NOLOCK)  
    INNER JOIN DBO.ItemMaster AS IM WITH (NOLOCK) ON RCW.ItemMasterId = IM.ItemMasterId  
    INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = RCW.ReceivingCustomerWorkId  
    LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID  
    LEFT JOIN DBO.WorkOrder AS WO WITH (NOLOCK) ON RCW.WorkOrderId = WO.WorkOrderId  
    LEFT JOIN DBO.WorkOrderPartNumber AS WOPN WITH (NOLOCK) ON RCW.ReceivingCustomerWorkId = WOPN.ReceivingCustomerWorkId  
    LEFT JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOPN.ID = WOQD.WOPartNoId          
    LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId  
    LEFT JOIN DBO.WorkOrderStatus AS WOSS WITH (NOLOCK) ON WO.WorkOrderStatusId = WOSS.Id  
    LEFT JOIN DBO.WorkOrderType AS WOT WITH (NOLOCK)ON WO.WorkOrderTypeId = WOT.Id  
    LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK) ON WO.SalesPersonId = E1.EmployeeId  
    LEFT JOIN DBO.Employee AS E2 WITH (NOLOCK) ON WO.CsrId = E2.EmployeeId  
     WHERE CAST(RCW.receiveddate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)        
      AND RCW.customerid=ISNULL(@customername,WO.customerid)   
      AND RCW.mastercompanyid = @MasterCompanyId 
	  AND WO.IsDeleted = 0 AND WO.IsActive = 1
	  AND MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))  
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
    END  
  
   SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END  
   SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END  
  
   ;WITH rptCTE (TotalRecordsCount, customername, customercode, receivernum, pn, pndescription, serialnum, workscope, manufacturer, receiveddate, opendate,
				 wonum, stagecode, status, nte, estimatedrevenue, wotype, salesperson, csr, level1, level2, level3, level4, level5, level6, level7, level8,
			  level9, level10, masterCompanyId) AS (
    SELECT COUNT(1) OVER () AS TotalRecordsCount,  
   UPPER(RCW.customerName) 'customername',  
   UPPER(RCW.CustomerCode) 'customercode',  
   UPPER(RCW.ReceivingNumber) 'receivernum',  
   UPPER(IM.partnumber) 'pn',  
   UPPER(IM.PartDescription) 'pndescription',  
   UPPER(RCW.SerialNumber) 'serialnum',  
   UPPER(RCW.WorkScope) 'workscope',
   UPPER(RCW.ManufacturerName) 'manufacturer',
   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(RCW.ReceivedDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), RCW.ReceivedDate, 107) END 'receiveddate',   
   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WO.OpenDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), WO.OpenDate, 107) END 'opendate',   
   UPPER(WO.WorkOrderNum) 'wonum',  
   UPPER(WOS.code + '-' + stage) 'stagecode',  
   UPPER(WOSS.Description) 'status',  
   WOPN.NTE 'nte',     
   ISNULL(WOQD.MaterialRevenue + WOQD.LaborRevenue + WOQD.ChargesRevenue + WOQD.FreightRevenue,0) 'estimatedrevenue',  
   UPPER(WOT.Description) 'wotype',  
   UPPER(E1.FirstName + ' ' + E1.LastName) 'salesperson',  
   UPPER(E2.FirstName + ' ' + E2.LastName) 'csr',  
   UPPER(MSD.Level1Name) AS level1,      UPPER(MSD.Level2Name) AS level2,     UPPER(MSD.Level3Name) AS level3,     UPPER(MSD.Level4Name) AS level4,     UPPER(MSD.Level5Name) AS level5,
   UPPER(MSD.Level6Name) AS level6,     UPPER(MSD.Level7Name) AS level7,     UPPER(MSD.Level8Name) AS level8,     UPPER(MSD.Level9Name) AS level9,     UPPER(MSD.Level10Name) AS level10,
   RCW.MasterCompanyId
    FROM DBO.ReceivingCustomerWork RCW WITH (NOLOCK)  
   INNER JOIN DBO.ItemMaster AS IM WITH (NOLOCK) ON RCW.ItemMasterId = IM.ItemMasterId  
   INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = RCW.ReceivingCustomerWorkId
   LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID  
   LEFT JOIN DBO.WorkOrder AS WO WITH (NOLOCK) ON RCW.WorkOrderId = WO.WorkOrderId  
   LEFT JOIN DBO.WorkOrderPartNumber AS WOPN WITH (NOLOCK) ON RCW.ReceivingCustomerWorkId = WOPN.ReceivingCustomerWorkId  
   LEFT JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOPN.ID = WOQD.WOPartNoId          
   LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId  
   LEFT JOIN DBO.WorkOrderStatus AS WOSS WITH (NOLOCK) ON WO.WorkOrderStatusId = WOSS.Id  
   LEFT JOIN DBO.WorkOrderType AS WOT WITH (NOLOCK)ON WO.WorkOrderTypeId = WOT.Id  
   LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK) ON WO.SalesPersonId = E1.EmployeeId  
   LEFT JOIN DBO.Employee AS E2 WITH (NOLOCK) ON WO.CsrId = E2.EmployeeId  
    WHERE CAST(RCW.receiveddate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)  
    AND RCW.customerid=ISNULL(@customername,WO.customerid)  
    AND RCW.mastercompanyid = @MasterCompanyId
	AND WO.IsDeleted = 0 AND WO.IsActive = 1
	AND MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))  
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
	,FinalCTE(TotalRecordsCount, customername, customercode, receivernum, pn, pndescription, serialnum, workscope, manufacturer, receiveddate, opendate,
				 wonum, stagecode, status, nte, estimatedrevenue, wotype, salesperson, csr, level1, level2, level3, level4, level5, level6, level7, level8,
			  level9, level10, masterCompanyId) 
			  AS (SELECT DISTINCT TotalRecordsCount, customername, customercode, receivernum, pn, pndescription, serialnum, workscope, manufacturer, receiveddate, opendate,
				 wonum, stagecode, status, nte, estimatedrevenue, wotype, salesperson, csr, level1, level2, level3, level4, level5, level6, level7, level8,
			  level9, level10, masterCompanyId FROM rptCTE)

			,WithTotal (masterCompanyId, TotalEstimatedRevenue) 
			  AS (SELECT masterCompanyId, 
				FORMAT(SUM(estimatedrevenue), 'N', 'en-us') TotalEstimatedRevenue
				FROM FinalCTE
				GROUP BY masterCompanyId)

			  SELECT COUNT(2) OVER () AS TotalRecordsCount, customername, customercode, receivernum, pn, pndescription, serialnum, workscope, manufacturer, receiveddate, opendate,
					 wonum, stagecode, status, nte,
					FORMAT(ISNULL(estimatedrevenue,0) , 'N', 'en-us') 'estimatedrevenue',    
					wotype, salesperson, csr, level1, level2, level3, level4, level5, level6, level7, level8,
					level9, level10,
					WC.TotalEstimatedRevenue
				FROM FinalCTE FC
					INNER JOIN WithTotal WC ON FC.masterCompanyId = WC.masterCompanyId
				ORDER BY pn
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
            @AdhocComments varchar(150) = '[usprpt_GetRCWReport]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@customername, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +  
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +  
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +  
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +  
   '@Parameter8 = ''' + CAST(ISNULL(@level5, '') AS varchar(100)) +  
   '@Parameter9 = ''' + CAST(ISNULL(@level6, '') AS varchar(100)) +  
   '@Parameter10 = ''' + CAST(ISNULL(@level7, '') AS varchar(100)) +  
   '@Parameter11 = ''' + CAST(ISNULL(@level8, '') AS varchar(100)) +  
   '@Parameter12 = ''' + CAST(ISNULL(@level9, '') AS varchar(100)) +  
   '@Parameter13 = ''' + CAST(ISNULL(@level10, '') AS varchar(100)) +  
            '@Parameter14 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),  
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