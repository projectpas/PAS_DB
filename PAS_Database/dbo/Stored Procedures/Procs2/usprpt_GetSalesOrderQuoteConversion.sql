/*************************************************************             
 ** File:   [usprpt_GetSalesOrderQuoteConversion]             
 ** Author:   
 ** Description: Get Data for SalesOrderQuotes Report   
 ** Purpose:           
 ** Date:   
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
   1   16/08/2023       Ekta Chandegra     Convert text into uppercase   
   2   01/02/2024	    AMIT GHEDIYA	   added isperforma Flage for SO

@ModuleID
EXECUTE   [dbo].[usprpt_GetSalesOrderQuoteConversion] '','2020-06-15','2022-06-15','2','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'  
**************************************************************/  
CREATE     PROCEDURE [dbo].[usprpt_GetSalesOrderQuoteConversion] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
 
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
  
		DECLARE @customername varchar(40) = NULL,  
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
		@IsDownload BIT = NULL,
		@partnumber varchar(40) = NULL,
		@salesperson varchar(40) = NULL,
		@csr varchar(40) = NULL
  
  BEGIN TRY  
      DECLARE @ModuleID INT = 18; -- MS Module ID
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END

	   SELECT 
		@fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Quote From Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
		@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Quote To Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,
		@customername=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @customername end,
		@partnumber=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='PN' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @partnumber end,
		@salesperson=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Sales Person' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @salesperson end,
		@csr=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='CSR' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @csr end,
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
		  FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK)   
			  INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
			  LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			  LEFT JOIN DBO.SalesOrderQuotePart SOQP WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId   
			  LEFT JOIN DBO.Stockline STL WITH (NOLOCK) ON SOQP.stocklineId = STL.StockLineId   
			  LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SO.SalesOrderQuoteId   
			  LEFT JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
			  LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
			  LEFT JOIN (SELECT SalesOrderQuotePartId,SUM(BillingAmount) 'BillingAmount' FROM  dbo.SalesOrderQuoteCharges A1 WITH (NOLOCK) WHERE A1.[IsActive] = 1 
		        GROUP BY SalesOrderQuotePartId) Charges ON Charges.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId 
		  WHERE SOQ.CustomerId=ISNULL(@customername,SOQ.CustomerId)
				AND  SOQP.ItemMasterId = ISNULL(@partnumber,SOQP.ItemMasterId)
				--AND SOQ.SalesPersonId=ISNULL(@salesperson,SOQ.SalesPersonId)  
				--AND SOQ.CustomerSeviceRepId=ISNULL(@csr,SOQ.CustomerSeviceRepId)
				AND (@salesperson IS NULL OR SOQ.SalesPersonId = @salesperson)
				AND (@csr IS NULL OR SOQ.CustomerSeviceRepId = @csr)
				AND SOQ.IsDeleted=0
				AND CAST(SOQ.opendate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE) AND SOQ.MasterCompanyId = @mastercompanyid  
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

	  DECLARE @SOConvertedCount int;
	  SET @SOConvertedCount = (SELECT COUNT(*) from DBO.SalesOrderQuote SOQ WITH (NOLOCK)   
		  INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
		  LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
		  LEFT JOIN DBO.SalesOrderQuotePart SOQP WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
		   WHERE SOQP.IsConvertedToSalesOrder = 1 AND SOQ.CustomerId=ISNULL(@customername,SOQ.CustomerId)
				AND  SOQP.ItemMasterId = ISNULL(@partnumber,SOQP.ItemMasterId)
				--AND SOQ.SalesPersonId=ISNULL(@salesperson,SOQ.SalesPersonId)  
				--AND SOQ.CustomerSeviceRepId=ISNULL(@csr,SOQ.CustomerSeviceRepId)
				AND (@salesperson IS NULL OR SOQ.SalesPersonId = @salesperson)
				AND (@csr IS NULL OR SOQ.CustomerSeviceRepId = @csr)
				AND SOQ.IsDeleted=0
				AND CAST(SOQ.opendate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE) AND SOQ.MasterCompanyId = @mastercompanyid  
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
				AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))))


		;WITH rptCTE (TotalRecordsCount, customerName, customerCode, pn, pndescription, serialnumber, condition, quotenumber, quoteversion, quoteStatus,
						datesent, quotedate, quoterevenue, sorevenue, qtedirectcost, qtemarginamt, marginperc, contactname, email, 
						level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, 
						salesperson, csr, convertedtoso, sonumber, invoicenumber, conversionration, masterCompanyId) AS (
      SELECT COUNT(1) OVER () AS TotalRecordsCount,
			UPPER(SOQ.CustomerName) 'customerName',  
			UPPER(SOQ.CustomerCode) 'customerCode',  
			CASE WHEN SOQP.IsConvertedToSalesOrder = 1 THEN (A.partnumber) 
			ELSE UPPER(SOQP.PartNumber) END as 'pn',  
			CASE WHEN SOQP.IsConvertedToSalesOrder = 1 THEN (A.PartDescription) 
			ELSE UPPER(SOQP.PartDescription) END as 'pndescription', 
			--UPPER(SOQP.PartNumber) 'pn',
			--UPPER(SOQP.PartDescription) 'pndescription', 
			UPPER(STL.SerialNumber) 'serialnumber',  
			UPPER(SOQP.ConditionName) 'condition',  
			UPPER(SOQ.SalesOrderQuoteNumber) 'quotenumber',  
			UPPER(SOQ.Versionnumber) 'quoteversion',  
			UPPER(SOQ.statusname) 'quoteStatus',  
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOQ.QuoteSentDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOQ.QuoteSentDate, 107) END 'datesent', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(SOQ.OpenDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), SOQ.OpenDate, 107) END 'quotedate', 
			ISNULL((ISNULL(SOQP.NetSales, 0) + ISNULL(Charges.BillingAmount, 0)), 0) 'quoterevenue',
			ISNULL((ISNULL(A.NetSales, 0) + ISNULL(A.BillingAmount, 0)), 0) 'sorevenue',
			FORMAT(ISNULL(SOQP.UnitCostExtended, 0),'#,0.00') 'qtedirectcost',  
			FORMAT(((ISNULL(SOQP.NetSales, 0) + ISNULL(Charges.BillingAmount, 0))-(ISNULL(SOQP.UnitCostExtended, 0))),'#,0.00') 'qtemarginamt',  
		    FORMAT((((ISNULL(SOQP.NetSales, 0) + ISNULL(Charges.BillingAmount, 0))-(ISNULL(SOQP.UnitCostExtended, 0)))*100) /  
			CASE WHEN (ISNULL(SOQP.NetSales, 0) + ISNULL(Charges.BillingAmount, 0))>0 THEN ISNULL(SOQP.NetSales, 0) + ISNULL(Charges.BillingAmount, 0) ELSE 1 END,'#,0.00')+'%' 'marginperc',  
			UPPER(SOQ.CustomerContactName) 'contactname',  
			UPPER(SOQ.CustomerContactemail) 'email',  
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
			UPPER(SOQ.SalesPersonName) 'salesperson',  
			UPPER(SOQ.CustomerServiceRepName) 'csr',
			CASE WHEN SOQP.IsConvertedToSalesOrder = 1 THEN UPPER('Yes')
			ELSE UPPER('No') END as 'convertedtoso',
			UPPER(A.SalesOrderNumber) 'sonumber',
			UPPER(A.InvoiceNo) as 'invoicenumber',
			--CAST((COUNT(1) OVER () * CONVERT(decimal(4,2), @SOConvertedCount)) / 100 as float) as 'conversionration'
			FORMAT(@SOConvertedCount / (CONVERT(decimal(18,2), COUNT(1) OVER ())) * 100 , 'N', 'en-us') as 'conversionration',
			SOQ.MasterCompanyId
      FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK)   
		  INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
		  LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
		  LEFT JOIN DBO.SalesOrderQuotePart SOQP WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId  
		  --AND SOQP.SalesOrderQuotePartId in (SELECT SalesOrderQuotePartId FROM SalesOrderPart)
		  --AND NOT EXISTS (SELECT SalesOrderQuotePartId FROM SalesOrderPart where SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId)
		  LEFT JOIN DBO.Stockline STL WITH (NOLOCK) ON SOQP.stocklineId = STL.StockLineId   
		  --LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SO.SalesOrderQuoteId   
		  --LEFT JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId AND SOP.SalesOrderQuotePartId not in (SELECT SalesOrderQuotePartId FROM SalesOrderQuotePart)
		  ----AND SOP.SalesOrderQuotePartId not in (SELECT SalesOrderQuotePartId FROM SalesOrderQuotePart where IsConvertedToSalesOrder=1)
		  --LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
		  OUTER APPLY(
			SELECT IM.partnumber,IM.PartDescription,SO.SalesOrderNumber,SOCharges.BillingAmount,SOP.NetSales,SOBilling.InvoiceNo from DBO.SalesOrder SO WITH (NOLOCK)   
			INNER JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId AND SOP.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId
			LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
			LEFT JOIN (SELECT InvoiceNo,SOBII.SalesOrderPartId FROM  DBO.SalesOrderBillingInvoicing SOBI
				LEFT JOIN DBO.SalesOrderBillingInvoicingItem SOBII ON SOBI.SOBillingInvoicingId = SOBII.SOBillingInvoicingId AND ISNULL(SOBII.IsProforma,0) = 0
				WHERE ISNULL(SOBI.IsProforma,0) = 0
				GROUP BY SalesOrderPartId,InvoiceNo) SOBilling ON SOBilling.SalesOrderPartId = SOP.SalesOrderPartId
			LEFT JOIN (SELECT SalesOrderPartId,SUM(BillingAmount) 'BillingAmount' FROM  dbo.SalesOrderCharges A2 WITH (NOLOCK) WHERE A2.[IsActive] = 1 
		    GROUP BY SalesOrderPartId) SOCharges ON SOCharges.SalesOrderPartId = SOP.SalesOrderPartId
		 ) A
		  LEFT JOIN (SELECT SalesOrderQuotePartId,SUM(BillingAmount) 'BillingAmount' FROM  dbo.SalesOrderQuoteCharges A1 WITH (NOLOCK) WHERE A1.[IsActive] = 1 
		    GROUP BY SalesOrderQuotePartId) Charges ON Charges.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId 
      WHERE SOQ.CustomerId=ISNULL(@customername,SOQ.CustomerId) 
		    AND CAST(SOQ.opendate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE) AND SOQ.MasterCompanyId = @mastercompanyid  
			AND  SOQP.ItemMasterId = ISNULL(@partnumber,SOQP.ItemMasterId)
			--AND SOQ.SalesPersonId=ISNULL(@salesperson,SOQ.SalesPersonId)  
			--AND SOQ.CustomerSeviceRepId=ISNULL(@csr,SOQ.CustomerSeviceRepId)
			AND (@salesperson IS NULL OR SOQ.SalesPersonId = @salesperson)
			AND (@csr IS NULL OR SOQ.CustomerSeviceRepId = @csr)
			AND SOQ.IsDeleted=0
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
				)
				,FinalCTE(TotalRecordsCount, customerName, customerCode, pn, pndescription, serialnumber, condition, quotenumber, quoteversion, quoteStatus,
						datesent, quotedate, quoterevenue, sorevenue, qtedirectcost, qtemarginamt, marginperc, contactname, email, 
						level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, 
						salesperson, csr, convertedtoso, sonumber, invoicenumber, conversionration, masterCompanyId) 
			  AS (SELECT DISTINCT TotalRecordsCount, customerName, customerCode, pn, pndescription, serialnumber, condition, quotenumber, quoteversion, quoteStatus,
						datesent, quotedate, quoterevenue, sorevenue, qtedirectcost, qtemarginamt, marginperc, contactname, email, 
						level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, 
						salesperson, csr, convertedtoso, sonumber, invoicenumber, conversionration, masterCompanyId FROM rptCTE)

			,WithTotal (masterCompanyId, TotalQuoteRevenue, TotalSoRevenue) 
			  AS (SELECT masterCompanyId, 
				FORMAT(SUM(quoterevenue), 'N', 'en-us') TotalQuoteRevenue,
				FORMAT(SUM(sorevenue), 'N', 'en-us') TotalSoRevenue
				FROM FinalCTE
				GROUP BY masterCompanyId)

			  SELECT COUNT(2) OVER () AS TotalRecordsCount, customerName, customerCode, pn, pndescription, serialnumber, condition, quotenumber, quoteversion, quoteStatus,
					datesent, quotedate,
					FORMAT(ISNULL(quoterevenue,0) , '#,0.00') 'quoterevenue',    
					FORMAT(ISNULL(sorevenue,0) , '#,0.00') 'sorevenue',    
					qtedirectcost, qtemarginamt, marginperc, contactname, email, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, 
					salesperson, csr, convertedtoso, sonumber, invoicenumber, conversionration,
					WC.TotalQuoteRevenue,
					WC.TotalSoRevenue
				FROM FinalCTE FC
					INNER JOIN WithTotal WC ON FC.masterCompanyId = WC.masterCompanyId
				ORDER BY quotedate
				OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY; 
  END TRY  
  
  BEGIN CATCH  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(), 
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetSalesOrderGMReport]',  
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