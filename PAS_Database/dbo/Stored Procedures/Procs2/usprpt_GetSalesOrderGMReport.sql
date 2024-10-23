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
    2    20-JUNE-2023  Devendra Shekh      made changes to do the total 
    3    11-JULY-2023  AYESHA SULTANA      CREDIT MEMO DATA CORRESPONDING TO SALES ORDER GROSS MARGIN IF ANY
    3    20-JULY-2023  AYESHA SULTANA      CREDIT MEMO DATA CORRESPONDING TO SALES ORDER GROSS MARGIN IF ANY - revenue amount changes
	4	 01-JAN-2024   AMIT GHEDIYA		   added isperforma Flage for SO
	5	 28-MARCH-2024 Ekta Chandegra	   IsDeleted and IsActive flag is added
	6    10-OCT-2024   Abhishek Jirawla	   Implemented the new tables for SalesOrderQuotePart related tables
       
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
  
  DECLARE @PageSizeCM INT =0,@name varchar(40) = NULL,  
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
			--LEFT JOIN dbo.salesorderpart SOP WITH (NOLOCK) ON So.salesorderid = SOP.salesorderid  
			LEFT JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
			LEFT JOIN dbo.SalesOrderStocklineV1 SOV WITH (NOLOCK) ON SOP.SalesOrderPartId = SOV.SalesOrderPartId
		    LEFT JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
			INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SO.SalesOrderId
			LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN dbo.salesorderquote SOQ WITH (NOLOCK) ON SO.SalesOrderQuoteId = SOQ.salesorderquoteid  
			LEFT JOIN dbo.salesorderbillinginvoicing SOBI WITH (NOLOCK) ON SO.salesorderid = SOBI.salesorderid AND ISNULL(SOBI.IsProforma,0) = 0 
			LEFT JOIN dbo.somarginsummary SOMS WITH (NOLOCK) ON SO.salesorderid = SOMS.salesorderid  
			LEFT JOIN dbo.customer C WITH (NOLOCK) ON SOBI.customerid = C.customerid 
			LEFT JOIN dbo.itemmaster IM WITH (NOLOCK) ON SOP.itemmasterid = IM.itemmasterid  
			LEFT JOIN dbo.stockline STL WITH (NOLOCK) ON SOV.stocklineid = STL.stocklineid and stl.IsParent=1  
			LEFT JOIN dbo.condition CDTN WITH (NOLOCK) ON SOP.conditionid = CDTN.conditionid 
            LEFT JOIN (SELECT SalesOrderPartId,SUM(BillingAmount) 'BillingAmount' FROM  dbo.SalesOrderCharges A1 WITH (NOLOCK) WHERE A1.[IsActive] = 1 
		              GROUP BY SalesOrderPartId) Charges ON Charges.SalesOrderPartId = SOP.SalesOrderPartId     
			WHERE  C.customerid=ISNULL(@name,C.customerid)  
			AND CAST(SOBI.invoicedate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)  
			AND SO.mastercompanyid = @mastercompanyid AND SO.IsDeleted = 0 AND SO.IsActive = 1
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
			  FORMAT (SO.opendate, 'MM/dd/yyyy'),SOBI.invoiceno,SOP.QtyOrder,SOPC.UnitSalesPrice,SOBI.freight,SOBI.misccharges,SOBI.salestax,SOMS.productcost,
			  SOQ.salesorderquotenumber,FORMAT (SOQ.OpenDate, 'MM/dd/yyyy'),CASE  WHEN soq.statusid IN(2,4) THEN FORMAT (soq.ApprovedDate, 'MM/dd/yyyy') END,
			  FORMAT (SOBI.shipdate, 'MM/dd/yyyy'),SO.SalesPersonName,SO.CustomerServiceRepName,FORMAT (SOBI.invoicedate, 'MM/dd/yyyy'), SOPC.NetSaleAmount,SOMS.misc,  
			  MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name,Charges.BillingAmount
		   ) TEMP


		    SELECT  @PageSizeCM =COUNT(*)					
				  FROM DBO.CreditMemo CM WITH (NOLOCK)   
						INNER JOIN DBO.CreditMemoDetails CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
						LEFT JOIN DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON CM.InvoiceId = SOBI.SOBillingInvoicingId AND ISNULL(SOBI.IsProforma,0) = 0
						LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
						--LEFT JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId 
						LEFT JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
						LEFT JOIN dbo.SalesOrderStocklineV1 SOV WITH (NOLOCK) ON SOP.SalesOrderPartId = SOV.SalesOrderPartId
						LEFT JOIN DBO.SalesOrderQuote SOQ WITH (NOLOCK)  ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId   
						LEFT JOIN DBO.Condition CDTN WITH (NOLOCK) ON SOP.ConditionId = CDTN.ConditionId  
						LEFT JOIN DBO.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SO.SalesOrderId
						LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
						LEFT JOIN DBO.Stockline STL WITH (NOLOCK) ON SOV.StockLineId = STL.StockLineId and STL.IsParent=1 
						LEFT JOIN DBO.SOMarginSummary SOMS WITH (NOLOCK) ON SO.SalesOrderId = SOMS.SalesOrderId   
						LEFT JOIN DBO.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId 
						LEFT JOIN (SELECT SalesOrderPartId,SUM(BillingAmount) 'BillingAmount' FROM  DBO.SalesOrderCharges A1 WITH (NOLOCK) WHERE A1.[IsActive] = 1 
							  GROUP BY SalesOrderPartId) Charges ON Charges.SalesOrderPartId = SOP.SalesOrderPartId
				  WHERE C.CustomerId=ISNULL(@name,C.CustomerId)  
					AND CAST(CM.InvoiceDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)  
					AND SO.mastercompanyid = @mastercompanyid AND SO.IsDeleted = 0 AND SO.IsActive = 1
					AND ISNULL(CM.IsWorkOrder,0) = 0
					AND  (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))
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
				 
						  
					print @PageSizeCM  
			SET @PageSize = ISNULL(@PageSize,0) + ISNULL(@PageSizeCM,0)	
		END

	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

	;WITH rptCTE (TotalRecordsCount, ChargesBillingAmt, customer, custcode, pn, pndescription, cond, sonum, invnum, rcvddate, soopendate, invdate, qtedate, qteapprovaldate, shipdate,
				 Netsales, Misc, rev, directcost, dcofrevperc, marginamt, marginrevperc, qtenum, 
				 level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, salesperson, csr, masterCompanyId
				 ,CreditMemoNumber
				 ) AS (
      SELECT COUNT(1) OVER () AS TotalRecordsCount,    
		ISNULL(Charges.BillingAmount,0) AS 'ChargesBillingAMt',
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

        ISNULL(SOPC.NetSaleAmount,0) 'Netsales',
        UPPER(SOMS.misc) 'Misc',  
        ISNULL(((SOPC.NetSaleAmount) +  ISNULL(Charges.BillingAmount, 0)),0)  'rev',  
        ISNULL(SOMS.productcost,0)  'directcost', 
        ISNULL(((SOMS.productcost) / NULLIF((SOPC.NetSaleAmount) +  ISNULL(Charges.BillingAmount, 0), 0)),0) 'dcofrevperc',   
		ISNULL(((SOPC.NetSaleAmount) +  ISNULL(Charges.BillingAmount, 0) -  SOMS.productcost),0) 'marginamt',  
        ISNULL(((((SOPC.NetSaleAmount) +  ISNULL(Charges.BillingAmount, 0) -  SOMS.productcost) * 100) / NULLIF((SOPC.NetSaleAmount) +  ISNULL(Charges.BillingAmount, 0), 0)),0) 'marginrevperc', 
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
        UPPER(SO.CustomerServiceRepName) 'csr',
		SO.MasterCompanyId
		,'' AS CreditMemoNumber
      FROM dbo.salesorder SO WITH (NOLOCK) 
	    --LEFT JOIN dbo.salesorderpart SOP WITH (NOLOCK) ON So.salesorderid = SOP.salesorderid
		LEFT JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
		LEFT JOIN dbo.SalesOrderStocklineV1 SOV WITH (NOLOCK) ON SOP.SalesOrderPartId = SOV.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
		INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SO.SalesOrderId
		LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
        LEFT JOIN dbo.salesorderquote SOQ WITH (NOLOCK) ON SO.SalesOrderQuoteId = SOQ.salesorderquoteid  
        LEFT JOIN dbo.salesorderbillinginvoicing SOBI WITH (NOLOCK) ON SO.salesorderid = SOBI.salesorderid AND ISNULL(SOBI.IsProforma,0) = 0
        LEFT JOIN dbo.somarginsummary SOMS WITH (NOLOCK) ON SO.salesorderid = SOMS.salesorderid  
        LEFT JOIN dbo.customer C WITH (NOLOCK) ON SOBI.customerid = C.customerid 
		LEFT JOIN dbo.itemmaster IM WITH (NOLOCK) ON SOP.itemmasterid = IM.itemmasterid  
        LEFT JOIN dbo.stockline STL WITH (NOLOCK) ON SOV.stocklineid = STL.stocklineid and stl.IsParent=1  
        LEFT JOIN dbo.condition CDTN WITH (NOLOCK) ON SOP.conditionid = CDTN.conditionid  
		LEFT JOIN (SELECT SalesOrderPartId,SUM(BillingAmount) 'BillingAmount' FROM  dbo.SalesOrderCharges A1 WITH (NOLOCK) WHERE A1.[IsActive] = 1 
		          GROUP BY SalesOrderPartId) Charges ON Charges.SalesOrderPartId = SOP.SalesOrderPartId 
      WHERE C.customerid=ISNULL(@name,C.customerid)  
		AND CAST(SOBI.invoicedate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)  
		AND SO.mastercompanyid = @mastercompanyid AND SO.IsDeleted = 0 AND SO.IsActive = 1 
		AND  (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))
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
			  SOBI.invoiceno,SOP.QtyOrder,SOPC.UnitSalesPrice,SOBI.freight,SOBI.misccharges,SOBI.salestax,SOMS.productcost,
			  SOQ.salesorderquotenumber,
			  SO.SalesPersonName,SO.CustomerServiceRepName,
			  SOPC.NetSaleAmount,SOMS.misc,  
			  MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name,Charges.BillingAmount,SO.MasterCompanyId
			  
			  UNION ALL

			  SELECT COUNT(1) OVER () AS TotalRecordsCount,    
					ISNULL(Charges.BillingAmount,0) AS 'ChargesBillingAMt',
					UPPER(CM.CustomerName) 'customer',  
					UPPER(CM.CustomerCode) 'custcode',  
					UPPER(CMD.PartNumber) 'pn',  
					UPPER(CMD.PartDescription) 'pndescription',  
					UPPER(CDTN.Description) 'cond',  
					UPPER(SO.SalesOrderNumber) AS  'sonum', 
					UPPER(CM.InvoiceNumber) 'invnum',  

					CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(STL.receiveddate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), STL.receiveddate, 107) END 'rcvddate', 
					CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SO.opendate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SO.opendate, 107) END 'soopendate', 
					CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(CM.InvoiceDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), CM.InvoiceDate, 107) END 'invdate', 
					CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOQ.OpenDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOQ.OpenDate, 107) END 'qtedate', 
					CASE  WHEN SOQ.statusid IN(2,4) THEN CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOQ.ApprovedDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOQ.ApprovedDate, 107) END END AS 'qteapprovaldate',  
					CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOBI.shipdate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOBI.shipdate, 107) END 'shipdate', 

			  --      FORMAT (STL.receiveddate, 'MM/dd/yyyy') 'rcvddate',  
			  --      FORMAT (SO.opendate, 'MM/dd/yyyy') 'soopendate',  
			  --      FORMAT (SOBI.invoicedate, 'MM/dd/yyyy') 'invdate',
					--FORMAT (SOQ.OpenDate, 'MM/dd/yyyy') 'qtedate',  
			  --      FORMAT (SOBI.shipdate, 'MM/dd/yyyy') 'shipdate',  

					ISNULL(SOPC.NetSaleAmount,0) 'Netsales',
					UPPER(SOMS.misc) 'Misc',  
					-- ISNULL(((SOP.NetSales) +  ISNULL(Charges.BillingAmount, 0)),0)  'rev',  
					UPPER(CM.Amount) 'rev',  
					ISNULL(SOMS.productcost,0)  'directcost', 
					ISNULL(((SOMS.productcost) / NULLIF((SOPC.NetSaleAmount) +  ISNULL(Charges.BillingAmount, 0), 0)),0) 'dcofrevperc',   
					ISNULL(((SOPC.NetSaleAmount) +  ISNULL(Charges.BillingAmount, 0) -  SOMS.productcost),0) 'marginamt',  
					ISNULL(((((SOPC.NetSaleAmount) +  ISNULL(Charges.BillingAmount, 0) -  SOMS.productcost) * 100) / NULLIF((SOPC.NetSaleAmount) +  ISNULL(Charges.BillingAmount, 0), 0)),0) 'marginrevperc', 
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
					UPPER(SO.CustomerServiceRepName) 'csr',
					SO.MasterCompanyId
					,ISNULL(CM.CreditMemoNumber,'') AS CreditMemoNumber

				  FROM DBO.CreditMemo CM WITH (NOLOCK)   
						INNER JOIN DBO.CreditMemoDetails CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
						LEFT JOIN DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON CM.InvoiceId = SOBI.SOBillingInvoicingId AND ISNULL(SOBI.IsProforma,0) = 0
						LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
						--LEFT JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId 
						LEFT JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
						LEFT JOIN dbo.SalesOrderStocklineV1 SOV WITH (NOLOCK) ON SOP.SalesOrderPartId = SOV.SalesOrderPartId
						LEFT JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
						LEFT JOIN DBO.SalesOrderQuote SOQ WITH (NOLOCK)  ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId   
						LEFT JOIN DBO.Condition CDTN WITH (NOLOCK) ON SOP.ConditionId = CDTN.ConditionId  
						LEFT JOIN DBO.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SO.SalesOrderId
						LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
						LEFT JOIN DBO.Stockline STL WITH (NOLOCK) ON SOV.StockLineId = STL.StockLineId and STL.IsParent=1 
						LEFT JOIN DBO.SOMarginSummary SOMS WITH (NOLOCK) ON SO.SalesOrderId = SOMS.SalesOrderId   
						LEFT JOIN DBO.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId 
						LEFT JOIN (SELECT SalesOrderPartId,SUM(BillingAmount) 'BillingAmount' FROM  DBO.SalesOrderCharges A1 WITH (NOLOCK) WHERE A1.[IsActive] = 1 
							  GROUP BY SalesOrderPartId) Charges ON Charges.SalesOrderPartId = SOP.SalesOrderPartId 


				  WHERE C.CustomerId=ISNULL(@name,C.CustomerId)  
					AND CAST(CM.InvoiceDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)  
					AND SO.mastercompanyid = @mastercompanyid AND SO.IsDeleted = 0 AND SO.IsActive = 1
					AND ISNULL(CM.IsWorkOrder,0) = 0
					AND  (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))
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
						  CM.CustomerName,CM.CustomerCode,CMD.PartNumber,CMD.PartDescription,CDTN.Description,SO.SalesOrderNumber,
						  --FORMAT (STL.receiveddate, 'MM/dd/yyyy'),
						  --FORMAT (SO.opendate, 'MM/dd/yyyy'),
						  --FORMAT (SOQ.OpenDate, 'MM/dd/yyyy'),
						  --FORMAT (SOBI.shipdate, 'MM/dd/yyyy'),
						  --CASE  WHEN soq.statusid IN(2,4) THEN FORMAT (soq.ApprovedDate, 'MM/dd/yyyy') END,
						  --FORMAT (SOBI.invoicedate, 'MM/dd/yyyy'),
						  CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(STL.receiveddate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), STL.receiveddate, 107) END, 
						  CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SO.opendate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SO.opendate, 107) END , 
						  CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(CM.InvoiceDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), CM.InvoiceDate, 107) END , 
						  CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOQ.OpenDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOQ.OpenDate, 107) END , 
						  CASE  WHEN SOQ.StatusId IN(2,4) THEN CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOQ.ApprovedDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOQ.ApprovedDate, 107) END END ,  
						  CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOBI.shipdate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOBI.shipdate, 107) END , 
						  CM.InvoiceNumber,SOP.QtyOrder,SOPC.UnitSalesPrice,SOBI.freight,SOBI.misccharges,SOBI.salestax,SOMS.productcost,
						  SOQ.salesorderquotenumber,
						  SO.SalesPersonName,SO.CustomerServiceRepName,
						  SOPC.NetSaleAmount,SOMS.misc, CM.Amount,
						  MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name,Charges.BillingAmount,SO.MasterCompanyId,CM.CreditMemoNumber
						  )


	  ,FinalCTE(TotalRecordsCount, customer, custcode, pn, pndescription, cond, sonum, invnum, rcvddate, soopendate, invdate, qtedate, qteapprovaldate, shipdate,
				 Netsales, Misc, rev, directcost, dcofrevperc, marginamt, marginrevperc, qtenum, 
				 level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, salesperson, csr, ChargesBillingAmt, masterCompanyId,CreditMemoNumber) 
			  AS (SELECT DISTINCT TotalRecordsCount, customer, custcode, pn, pndescription, cond, sonum, invnum, rcvddate, soopendate, invdate, qtedate, qteapprovaldate, shipdate,
				 Netsales, Misc, rev, directcost, dcofrevperc, marginamt, marginrevperc, qtenum, 
				 level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, salesperson, csr, ChargesBillingAmt, masterCompanyId,CreditMemoNumber FROM rptCTE)

			,WithTotal (masterCompanyId, TotalRevenue, TotalDirectCost, TotalDCOfRevPerc, TotalMarginAmt, TotalMarginRevPerc) 
			  AS (SELECT masterCompanyId, 
				FORMAT(SUM(rev),'#,0.00') TotalRevenue,
				FORMAT(SUM(directcost),'#,0.00') TotalDirectCost,
				FORMAT((SUM(directcost) / NULLIF(SUM(NetSales) +  SUM(ChargesBillingAmt), 0)),'#,0.00') TotalDCOfRevPerc,
				FORMAT(SUM(marginamt),'#,0.00') TotalMarginAmt,
				--FORMAT(((((NetSales) +  ISNULL(Charges.BillingAmount, 0) -  directcost) * 100) / NULLIF((NetSales) +  ISNULL(Charges.BillingAmount, 0), 0)),'#,0.00')+'%' TotalMarginRevPerc
				FORMAT((((SUM(NetSales) +  SUM(ChargesBillingAmt) -  SUM(directcost)) * 100) / NULLIF(SUM(NetSales) +  SUM(ChargesBillingAmt), 0)),'#,0.00') TotalMarginRevPerc
				FROM FinalCTE
				GROUP BY masterCompanyId)

			  SELECT COUNT(2) OVER () AS TotalRecordsCount, customer, custcode, pn, pndescription, cond, sonum + (CASE WHEN FC.CreditMemoNumber is not null AND FC.CreditMemoNumber != '' THEN ( ' (' + FC.CreditMemoNumber +')') ELSE '' END) AS sonum, invnum, rcvddate, soopendate, invdate, qtedate, qteapprovaldate, shipdate,
					 Netsales, Misc, 
					FORMAT(ISNULL(rev,0) , 'N', 'en-us') 'rev',    
					FORMAT(ISNULL(directcost,0) , 'N', 'en-us') 'directcost',    
					FORMAT(ISNULL(dcofrevperc,0) , 'N', 'en-us') 'dcofrevperc',    
					FORMAT(ISNULL(marginamt,0) , 'N', 'en-us') 'marginamt',    
					FORMAT(ISNULL(marginrevperc,0) , 'N', 'en-us') 'marginrevperc',    
					qtenum, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, salesperson, csr, ChargesBillingAmt,
					WC.TotalRevenue, WC.TotalDirectCost, WC.TotalDCOfRevPerc, WC.TotalMarginAmt, WC.TotalMarginRevPerc
				FROM FinalCTE FC
					INNER JOIN WithTotal WC ON FC.masterCompanyId = WC.masterCompanyId
	  ORDER BY custcode
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