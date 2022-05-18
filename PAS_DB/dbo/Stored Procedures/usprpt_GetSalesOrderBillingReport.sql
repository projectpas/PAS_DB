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
 ** S NO   Date         Author  		Change Description            
 ** --   --------		-------------	--------------------------------          
    1	15-APR-2022		HEMANT SALIYA	Created

     
--EXECUTE   [dbo].[usprpt_GetRCWReport] '','2021-06-15','2022-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usprpt_GetSalesOrderBillingReport] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
AS  
BEGIN  

declare @name varchar(40) = NULL  
declare @Fromdate datetime
declare @Todate datetime
declare @tagtype varchar(50) = NULL,
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

select 
@name=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Cutsomer(Optional)' 
	then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @name end,
	@Fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From SO Invoice Date' 
	then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @Fromdate end,
		@Todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To SO Invoice Date' 
	then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @Todate end,
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

	  print @Fromdate
	  print @Todate
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  BEGIN TRY  
    --BEGIN TRANSACTION  

		DECLARE @ModuleID INT = 17; -- MS Module ID

  IF ISNULL(@PageSize,0)=0
	  BEGIN 
		  SELECT @PageSize=COUNT(*) 
		  FROM dbo.salesorder SO WITH (NOLOCK)  
			INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SO.SalesOrderId
			LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN dbo.salesorderpart SOP WITH (NOLOCK) ON So.salesorderid = SOP.salesorderid  
			LEFT JOIN dbo.salesorderquote SOQ WITH (NOLOCK)  ON SO.SalesOrderQuoteId = SOQ.salesorderquoteid  
			LEFT JOIN dbo.salesorderbillinginvoicing SOBI WITH (NOLOCK) ON SO.salesorderid = SOBI.salesorderid  
			LEFT JOIN dbo.customer C WITH (NOLOCK) ON SOBI.customerid = C.customerid  
			LEFT JOIN dbo.itemmaster IM WITH (NOLOCK) ON SOP.itemmasterid = IM.itemmasterid  
			LEFT JOIN dbo.stockline STL WITH (NOLOCK) ON SOP.stocklineid = STL.stocklineid and stl.IsParent=1  
			LEFT JOIN dbo.workorder WO WITH (NOLOCK)  ON STL.workorderid = WO.workorderid  
			LEFT JOIN dbo.condition CDTN WITH (NOLOCK) ON SOP.conditionid = CDTN.conditionid          
		  WHERE SOBI.customerid=ISNULL(@name,SOBI.customerid) AND
		  CAST(SOBI.invoicedate AS DATETIME) BETWEEN CAST(@FromDate AS DATETIME) AND CAST(@ToDate AS DATETIME)  AND
		  SO.mastercompanyid = @mastercompanyid  
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
        UPPER(C.NAME) 'customername',  
        UPPER(C.customercode) 'customercode',  
        UPPER(IM.partnumber) 'pn',  
        UPPER(IM.partdescription) 'pndescription',  
        UPPER(CDTN.description) 'condition',  
        UPPER(SO.salesordernumber) 'sonum',  
		UPPER(WO.workordernum) 'wonum',  
        FORMAT (STL.receiveddate, 'MM/dd/yyyy')  AS 'receiveddate',  
		FORMAT (SO.opendate, 'MM/dd/yyyy')  AS  'opendate',  
        UPPER(SOBI.invoiceno) 'invoicenum',  
		FORMAT (SOBI.invoicedate, 'MM/dd/yyyy')  AS  'invoicedate',  
		FORMAT((isnull(SOP.SalesPriceExtended,0) + (select isnull(sum(sc.billingamount),0) from SalesOrderCharges sc WITH (NOLOCK)
			WHERE sc.SalesOrderId =SO.SalesOrderId and sop.SalesOrderPartId=sc.SalesOrderPartId and sc.isdeleted=0 and sc.isactive =1 ) ) , 'N', 'en-us') as 'revenue',  
        FORMAT (SOQ.OpenDate, 'MM/dd/yyyy') 'quotedate',  
		FORMAT (soq.ApprovedDate, 'MM/dd/yyyy')  AS 'quoteapprovaldate',  
		FORMAT (SOBI.shipdate, 'MM/dd/yyyy')  AS     'shipdate',  
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
		INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SO.SalesOrderId
		LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
		LEFT JOIN dbo.salesorderpart SOP WITH (NOLOCK) ON So.salesorderid = SOP.salesorderid  
        LEFT JOIN dbo.salesorderquote SOQ WITH (NOLOCK)  ON SO.SalesOrderQuoteId = SOQ.salesorderquoteid  
        LEFT JOIN dbo.salesorderbillinginvoicing SOBI WITH (NOLOCK) ON SO.salesorderid = SOBI.salesorderid  
        LEFT JOIN dbo.customer C WITH (NOLOCK) ON SOBI.customerid = C.customerid  
		LEFT JOIN dbo.itemmaster IM WITH (NOLOCK) ON SOP.itemmasterid = IM.itemmasterid  
        LEFT JOIN dbo.stockline STL WITH (NOLOCK) ON SOP.stocklineid = STL.stocklineid and stl.IsParent=1  
        LEFT JOIN dbo.workorder WO WITH (NOLOCK)  ON STL.workorderid = WO.workorderid  
        LEFT JOIN dbo.condition CDTN WITH (NOLOCK) ON SOP.conditionid = CDTN.conditionid  
      WHERE SOBI.customerid=ISNULL(@name,SOBI.customerid) AND
	  CAST(SOBI.invoicedate AS DATETIME) BETWEEN CAST(@FromDate AS DATETIME) AND CAST(@ToDate AS DATETIME)  AND
	  SO.mastercompanyid = @mastercompanyid  
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
			ORDER BY SOBI.invoicedate
			OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY; 
 
  END TRY  
  
  BEGIN CATCH  
        
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[usprpt_GetSalesOrderBillingReport]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@name, '') AS varchar(100)) +  
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
            '@Parameter14 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100))+
			'@Parameter15 = ''' + CAST(ISNULL(@tagtype, '') AS varchar)+
			'@Parameter16 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar)+
			'@Parameter17 = ''' + CAST(ISNULL(@PageSize, '') AS varchar),
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
END