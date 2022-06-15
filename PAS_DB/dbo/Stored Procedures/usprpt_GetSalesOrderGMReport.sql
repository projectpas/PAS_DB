/*************************************************************             
 ** File:   [usprpt_GetSalesOrderGMReport]             
 ** Author:   Mahesh Sorathiya    
 ** Description: Get Data for SalesOrder GM Report   
 ** Purpose:           
 ** Date:   22-march-2022         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    22-April-2022  Mahesh Sorathiya   Created 
       
EXECUTE   [dbo].[usprpt_GetSalesOrderGMReport] '','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'  
**************************************************************/  
CREATE   PROCEDURE [dbo].[usprpt_GetSalesOrderGMReport] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  DECLARE @name varchar(40) = NULL,  
	@Fromdate datetime,  
	@Todate datetime,
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
    
	  SELECT 
		@fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From SO Invoice Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
		@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To SO Invoice Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,
		@name=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer(Optional)' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @name end,
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
        
       DECLARE @ModuleID INT = 17; -- MS Module ID
	   SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END

	   IF ISNULL(@PageSize,0)=0
		BEGIN 
			SELECT @PageSize=COUNT(*) 
			FROM (SELECT C.customercode
			FROM dbo.salesorder SO WITH (NOLOCK) 
			LEFT JOIN dbo.salesorderpart SOP WITH (NOLOCK) ON So.salesorderid = SOP.salesorderid  
			INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SO.SalesOrderId
			LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN dbo.salesorderquote SOQ WITH (NOLOCK) ON SO.SalesOrderQuoteId = SOQ.salesorderquoteid  
			LEFT JOIN dbo.salesorderbillinginvoicing SOBI WITH (NOLOCK) ON SO.salesorderid = SOBI.salesorderid  
			LEFT JOIN dbo.somarginsummary SOMS WITH (NOLOCK) ON SO.salesorderid = SOMS.salesorderid  
			LEFT JOIN dbo.customer C WITH (NOLOCK) ON SOBI.customerid = C.customerid 
			LEFT JOIN dbo.itemmaster IM WITH (NOLOCK) ON SOP.itemmasterid = IM.itemmasterid  
			LEFT JOIN dbo.stockline STL WITH (NOLOCK) ON SOP.stocklineid = STL.stocklineid and stl.IsParent=1  
			LEFT JOIN dbo.condition CDTN WITH (NOLOCK) ON SOP.conditionid = CDTN.conditionid 
            LEFT JOIN (SELECT SalesOrderPartId,SUM(BillingAmount) 'BillingAmount' FROM  dbo.SalesOrderCharges A1 WITH (NOLOCK) WHERE A1.[IsActive] = 1 
		              GROUP BY SalesOrderPartId) Charges ON Charges.SalesOrderPartId = SOP.SalesOrderPartId     
			WHERE  C.customerid=ISNULL(@name,C.customerid)  
			AND CAST(SOBI.invoicedate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)  
			AND SO.mastercompanyid = @mastercompanyid  
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
			  C.NAME,C.customercode,IM.partnumber,IM.partdescription,CDTN.description,SO.salesordernumber,FORMAT (STL.receiveddate, 'MM/dd/yyyy'),
			  FORMAT (SO.opendate, 'MM/dd/yyyy'),SOBI.invoiceno,SOP.qty,SOP.unitsaleprice,SOBI.freight,SOBI.misccharges,SOBI.salestax,SOMS.productcost,
			  SOQ.salesorderquotenumber,FORMAT (SOQ.OpenDate, 'MM/dd/yyyy'),CASE  WHEN soq.statusid IN(2,4) THEN FORMAT (soq.ApprovedDate, 'MM/dd/yyyy') END,
			  FORMAT (SOBI.shipdate, 'MM/dd/yyyy'),SO.SalesPersonName,SO.CustomerServiceRepName,FORMAT (SOBI.invoicedate, 'MM/dd/yyyy'), SOP.netsales,SOMS.misc,  
			  MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name,Charges.BillingAmount
		   ) TEMP
		END

	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

      SELECT COUNT(1) OVER () AS TotalRecordsCount,    
        UPPER(C.NAME) 'customer',  
        UPPER(C.customercode) 'custcode',  
        UPPER(IM.partnumber) 'pn',  
        UPPER(IM.partdescription) 'pndescription',  
        UPPER(CDTN.description) 'cond',  
        UPPER(SO.salesordernumber) 'sonum', 
		UPPER(SOBI.invoiceno) 'invnum',  

		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(STL.receiveddate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), STL.receiveddate, 107) END 'rcvddate', 
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SO.opendate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SO.opendate, 107) END 'soopendate', 
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOBI.invoicedate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOBI.invoicedate, 107) END 'invdate', 
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOQ.OpenDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOQ.OpenDate, 107) END 'qtedate', 
		CASE  WHEN soq.statusid IN(2,4) THEN CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(soq.ApprovedDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), soq.ApprovedDate, 107) END END AS 'qteapprovaldate',  
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOBI.shipdate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOBI.shipdate, 107) END 'shipdate', 

  --      FORMAT (STL.receiveddate, 'MM/dd/yyyy') 'rcvddate',  
  --      FORMAT (SO.opendate, 'MM/dd/yyyy') 'soopendate',  
  --      FORMAT (SOBI.invoicedate, 'MM/dd/yyyy') 'invdate',
		--FORMAT (SOQ.OpenDate, 'MM/dd/yyyy') 'qtedate',  
  --      FORMAT (SOBI.shipdate, 'MM/dd/yyyy') 'shipdate',  

        SOP.netsales 'Netsales',  
        UPPER(SOMS.misc) 'Misc',  
        FORMAT(((SOP.NetSales) +  ISNULL(Charges.BillingAmount, 0)),'#,0.00')  'rev',  
        FORMAT(SOMS.productcost,'#,0.00')  'directcost',  
        FORMAT(((SOMS.productcost) / NULLIF((SOP.NetSales) +  ISNULL(Charges.BillingAmount, 0), 0)),'#,0.00')+'%' 'dcofrevperc',  
        FORMAT(((SOP.NetSales) +  ISNULL(Charges.BillingAmount, 0) -  SOMS.productcost),'#,0.00') 'marginamt',  
        FORMAT(((((SOP.NetSales) +  ISNULL(Charges.BillingAmount, 0) -  SOMS.productcost) * 100) / NULLIF((SOP.NetSales) +  ISNULL(Charges.BillingAmount, 0), 0)),'#,0.00')+'%' 'marginrevperc',  
		SOQ.salesorderquotenumber 'qtenum',  
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
        UPPER(SO.SalesPersonName) 'salesperson',  
        UPPER(SO.CustomerServiceRepName) 'csr'  
      FROM dbo.salesorder SO WITH (NOLOCK) 
	    LEFT JOIN dbo.salesorderpart SOP WITH (NOLOCK) ON So.salesorderid = SOP.salesorderid  
		INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SO.SalesOrderId
		LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
        LEFT JOIN dbo.salesorderquote SOQ WITH (NOLOCK) ON SO.SalesOrderQuoteId = SOQ.salesorderquoteid  
        LEFT JOIN dbo.salesorderbillinginvoicing SOBI WITH (NOLOCK) ON SO.salesorderid = SOBI.salesorderid  
        LEFT JOIN dbo.somarginsummary SOMS WITH (NOLOCK) ON SO.salesorderid = SOMS.salesorderid  
        LEFT JOIN dbo.customer C WITH (NOLOCK) ON SOBI.customerid = C.customerid 
		LEFT JOIN dbo.itemmaster IM WITH (NOLOCK) ON SOP.itemmasterid = IM.itemmasterid  
        LEFT JOIN dbo.stockline STL WITH (NOLOCK) ON SOP.stocklineid = STL.stocklineid and stl.IsParent=1  
        LEFT JOIN dbo.condition CDTN WITH (NOLOCK) ON SOP.conditionid = CDTN.conditionid  
		LEFT JOIN (SELECT SalesOrderPartId,SUM(BillingAmount) 'BillingAmount' FROM  dbo.SalesOrderCharges A1 WITH (NOLOCK) WHERE A1.[IsActive] = 1 
		          GROUP BY SalesOrderPartId) Charges ON Charges.SalesOrderPartId = SOP.SalesOrderPartId 
      WHERE C.customerid=ISNULL(@name,C.customerid)  
       AND CAST(SOBI.invoicedate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)  
       AND SO.mastercompanyid = @mastercompanyid  
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
			  C.NAME,C.customercode,IM.partnumber,IM.partdescription,CDTN.description,SO.salesordernumber,
			  --FORMAT (STL.receiveddate, 'MM/dd/yyyy'),
			  --FORMAT (SO.opendate, 'MM/dd/yyyy'),
			  --FORMAT (SOQ.OpenDate, 'MM/dd/yyyy'),
			  --FORMAT (SOBI.shipdate, 'MM/dd/yyyy'),
			  --CASE  WHEN soq.statusid IN(2,4) THEN FORMAT (soq.ApprovedDate, 'MM/dd/yyyy') END,
			  --FORMAT (SOBI.invoicedate, 'MM/dd/yyyy'),
			  CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(STL.receiveddate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), STL.receiveddate, 107) END, 
			  CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SO.opendate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SO.opendate, 107) END , 
			  CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOBI.invoicedate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOBI.invoicedate, 107) END , 
			  CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOQ.OpenDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOQ.OpenDate, 107) END , 
			  CASE  WHEN soq.statusid IN(2,4) THEN CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(soq.ApprovedDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), soq.ApprovedDate, 107) END END ,  
			  CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOBI.shipdate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOBI.shipdate, 107) END , 
			  SOBI.invoiceno,SOP.qty,SOP.unitsaleprice,SOBI.freight,SOBI.misccharges,SOBI.salestax,SOMS.productcost,
			  SOQ.salesorderquotenumber,
			  SO.SalesPersonName,SO.CustomerServiceRepName,
			  SOP.netsales,SOMS.misc,  
			  MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name,Charges.BillingAmount
	  ORDER BY C.customercode
		OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY; 
   
  END TRY  
  
  BEGIN CATCH  
      
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[usprpt_GetSalesOrderGMReport]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter, '') AS varchar(max)),
            @ApplicationName varchar(100) = 'PAS' 
  
    -------------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH  
   
END