/*************************************************************             
 ** File:   [usprpt_GetWorkOrderOnTimeReport]             
 ** Author:   Mahesh Sorathiya    
 ** Description: Get Data for WorkOrderOnTime Report    
 ** Purpose:           
 ** Date:   06-May-2022         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    06-May-2022  Mahesh Sorathiya   Created  
    2    31-JAN-2024   Devendra Shekh	added isperforma Flage for WO

**************************************************************/  
CREATE   PROCEDURE [dbo].[usprpt_GetWorkOrderOnTimeReport] 
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
       
      DECLARE @ModuleID INT = 12; -- MS Module ID
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END

	   SELECT 
		@fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='WO Start Ship Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
		@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='WO End Ship Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,
		@customerid=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer(Optional)' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @customerid end,
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

	  IF ISNULL(@PageSize,0)=0
	  BEGIN 
		  SELECT @PageSize=COUNT(*) 
		  FROM DBO.WorkOrder WO WITH (NOLOCK)  
			INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WO.WorkOrderId = WOPN.WorkOrderId  
			INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID
			LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN DBO.Customer WITH (NOLOCK) ON WO.CustomerId = Customer.CustomerId  
			LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOPN.itemmasterId = IM.itemmasterId  
			LEFT JOIN DBO.WorkScope AS WS WITH (NOLOCK) ON WOPN.WorkOrderScopeId = WS.WorkScopeId  
			LEFT JOIN DBO.Condition CDTN WITH (NOLOCK) ON WOPN.ConditionId = CDTN.ConditionId  
			LEFT JOIN DBO.Employee AS E WITH (NOLOCK) ON WO.salespersonid = E.EmployeeId  
			LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK) ON WO.csrid = E1.Employeeid  
			LEFT JOIN DBO.WorkOrderBillingInvoicing AS WBI WITH (NOLOCK) ON WO.WorkOrderId = WBI.WorkOrderId and IsVersionIncrease=0 AND ISNULL(WBI.IsPerformaInvoice, 0) = 0  
			LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOPN.ID = WOSI.WorkOrderPartNumId  
			LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId  
			LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK) ON WO.WorkOrderId = woq.WorkOrderId 
		  WHERE WO.CustomerId=ISNULL(@customerid,WO.CustomerId)  
				AND CAST(WOS.ShipDate AS DATE) BETWEEN CAST(@fromdate AS DATE) AND CAST(@todate AS DATE) AND WO.mastercompanyid = @mastercompanyid
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
	  END

	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

      SELECT COUNT(1) OVER () AS TotalRecordsCount,  
			UPPER(Customer.Name) 'customer',  
			UPPER(Customer.CustomerCode) 'custcode',  
			UPPER(IM.PartNumber) 'pn',  
			UPPER(IM.PartDescription) 'pndescription',  
			UPPER(WS.WorkScopeCode) 'workscope',  
			UPPER(CDTN.Description) 'cond',  
			UPPER(WO.WorkOrderNum) 'wonum', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.ReceivedDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOPN.ReceivedDate, 107) END 'rcvddate', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.promiseddate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOPN.promiseddate, 107) END 'promisedate', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.CustomerRequestDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOPN.CustomerRequestDate, 107) END 'reqdate', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOQ.OpenDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOQ.OpenDate, 107) END 'qtedate', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOQ.ApprovedDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOQ.ApprovedDate, 107) END 'approvaldate', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOS.ShipDate, 'MM/dd/yyyy') ELSE CONVERT(VARCHAR(50), WOS.ShipDate, 107) END 'shipdate', 
			(CASE WHEN FORMAT(WOS.ShipDate,'MM/dd/yyyy') <= FORMAT(WOPN.PromisedDate,'MM/dd/yyyy') THEN 'YES' ELSE 'NO' END) AS 'ontime',
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
			UPPER(E.FirstName + ' ' + E.lastname) 'salesperson',  
			UPPER(E1.firstname + ' ' + E1.lastname) 'csr'  
      FROM DBO.WorkOrder WO WITH (NOLOCK)  
		INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WO.WorkOrderId = WOPN.WorkOrderId  
		INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID
		LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
		LEFT JOIN DBO.Customer WITH (NOLOCK) ON WO.CustomerId = Customer.CustomerId  
		LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOPN.itemmasterId = IM.itemmasterId  
        LEFT JOIN DBO.WorkScope AS WS WITH (NOLOCK) ON WOPN.WorkOrderScopeId = WS.WorkScopeId  
        LEFT JOIN DBO.Condition CDTN WITH (NOLOCK) ON WOPN.ConditionId = CDTN.ConditionId  
        LEFT JOIN DBO.Employee AS E WITH (NOLOCK) ON WO.salespersonid = E.EmployeeId  
        LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK) ON WO.csrid = E1.Employeeid  
        LEFT JOIN DBO.WorkOrderBillingInvoicing AS WBI WITH (NOLOCK) ON WO.WorkOrderId = WBI.WorkOrderId and IsVersionIncrease=0 AND ISNULL(WBI.IsPerformaInvoice, 0) = 0  
        LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOPN.ID = WOSI.WorkOrderPartNumId  
        LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId  
        LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK) ON WO.WorkOrderId = woq.WorkOrderId 
      WHERE WO.CustomerId=ISNULL(@customerid,WO.CustomerId)  
		    AND CAST(WOS.ShipDate AS DATE) BETWEEN CAST(@fromdate AS DATE) AND CAST(@todate AS DATE) AND WO.mastercompanyid = @mastercompanyid
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
		ORDER BY CAST(WOS.ShipDate AS DATE)
			OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;  
   
  END TRY  
  
  BEGIN CATCH  
    
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(), 
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetWorkOrderOnTimeReport]',  
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