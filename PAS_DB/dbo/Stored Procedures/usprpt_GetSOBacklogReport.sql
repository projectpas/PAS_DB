/*************************************************************             
 ** File:   [usprpt_GetSOBacklogReport]             
 ** Author:   Mahesh Sorathiya    
 ** Description: Get Data for SOBacklog Report  
 ** Purpose:           
 ** Date:   05-May-2022         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    05-May-2022  Mahesh Sorathiya   Created  

**************************************************************/  
CREATE   PROCEDURE [dbo].[usprpt_GetSOBacklogReport] 
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
		@Level10 VARCHAR(MAX) = NULL  

  
  BEGIN TRY  
    --BEGIN TRANSACTION  
       
      DECLARE @ModuleID INT = 17; -- MS Module ID

	   SELECT 
		@fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From SO Open Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
		@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To SO Open Date' 
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
		  FROM (SELECT SO.SalesOrderNumber
		  FROM DBO.salesorder SO WITH (NOLOCK)  
			INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SO.SalesOrderId
			LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN dbo.MasterSalesOrderQuoteStatus ST WITH (NOLOCK) ON SO.StatusId = ST.id
			LEFT JOIN DBO.SalesOrderquote SOQ WITH (NOLOCK) ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
			LEFT JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
			LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
		  WHERE SO.CustomerId=ISNULL(@customerid,SO.CustomerId)  
		        AND CAST(SO.OpenDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE) AND SO.mastercompanyid = @mastercompanyid  
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
		  GROUP BY 
			SO.SalesOrderNumber, FORMAT(SO.openDate, 'MM/dd/yyyy'), SOQ.SalesOrderQuoteNumber, ST.name, IM.partnumber,IM.PartDescription, SO.CustomerName, SO.customerreference,
			FORMAT(SOP.unitcost,'#,0.00'),FORMAT(SOP.qty * SOP.unitcost,'#,0.00') ,FORMAT(SOP.CustomerRequestDate, 'MM/dd/yyyy'),FORMAT(SOP.EstimatedShipDate, 'MM/dd/yyyy'),
			MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name
			) TEMP
	  END

	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

      SELECT COUNT(1) OVER () AS TotalRecordsCount,  
			UPPER(SO.SalesOrderNumber) 'sonum',
			FORMAT(SO.openDate, 'MM/dd/yyyy') 'opendate',
			UPPER(SOQ.SalesOrderQuoteNumber) 'quotenum',
			UPPER(ST.name) AS 'status',        
			UPPER(IM.partnumber) AS 'pn',
			UPPER(IM.PartDescription) AS 'pndescription',
			UPPER(SO.CustomerName) AS 'customer',
			UPPER(SO.customerreference) 'custref',
			SUM(SOP.qty) 'qty',
			FORMAT(SOP.unitcost,'#,0.00') 'unitcost',
			FORMAT((SUM(SOP.qty * SOP.unitcost)),'#,0.00') 'extcost',
			FORMAT(SOP.CustomerRequestDate, 'MM/dd/yyyy') 'custreqdate',
			FORMAT(SOP.EstimatedShipDate, 'MM/dd/yyyy') 'shipdate',
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
      FROM DBO.salesorder SO WITH (NOLOCK)  
			INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SO.SalesOrderId
			LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN dbo.MasterSalesOrderQuoteStatus ST WITH (NOLOCK) ON SO.StatusId = ST.id
			LEFT JOIN DBO.SalesOrderquote SOQ WITH (NOLOCK) ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
			LEFT JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
			LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
      WHERE SO.CustomerId=ISNULL(@customerid,SO.CustomerId)  
		    AND CAST(SO.OpenDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE) AND SO.mastercompanyid = @mastercompanyid
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
		GROUP BY 
			SO.SalesOrderNumber, FORMAT(SO.openDate, 'MM/dd/yyyy'), SOQ.SalesOrderQuoteNumber, ST.name, IM.partnumber,IM.PartDescription, SO.CustomerName, SO.customerreference,
			FORMAT(SOP.unitcost,'#,0.00'),FORMAT(SOP.qty * SOP.unitcost,'#,0.00') ,FORMAT(SOP.CustomerRequestDate, 'MM/dd/yyyy'),FORMAT(SOP.EstimatedShipDate, 'MM/dd/yyyy'),
			MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name
		ORDER BY FORMAT(SO.openDate, 'MM/dd/yyyy')
			OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;  
   
  END TRY  
  
  BEGIN CATCH  
    
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(), 
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetSOBacklogReport]',  
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