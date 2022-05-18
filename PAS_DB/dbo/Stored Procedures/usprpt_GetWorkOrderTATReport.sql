
/*************************************************************           
 ** File:   [usp_GetWorkOrderTATReport]           
 ** Author:   Hemant  
 ** Description: Get Data for WorkOrderTAT Report
 ** Purpose:         
 ** Date:   30-APR-2022      
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
	1	30-APR-2022		Hemant		Convert to Angular Reports
     
EXECUTE   [dbo].[usp_GetWorkOrderTATReport] 
**************************************************************/
--EXEC usp_GetWorkOrderTATReport  '1,4,43,44,45,80,84,88','46,47','58,59','64,65,77'
CREATE PROCEDURE [dbo].[usprpt_GetWorkOrderTATReport] 
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
			FROM DBO.WorkOrder WO WITH (NOLOCK)
			INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId	
			INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID
			INNER JOIN DBO.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID
			LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON WO.WorkOrderId = WOBI.WorkOrderId AND WOBI.IsVersionIncrease=0
			LEFT JOIN DBO.Condition CN WITH (NOLOCK) ON WOPN.ConditionId = CN.ConditionId
			LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK) ON WO.WorkOrderId = woq.WorkOrderId AND woq.IsVersionIncrease=0
			LEFT JOIN DBO.WorkOrderType WITH (NOLOCK) ON WO.WorkOrderTypeId = WorkOrderType.Id
			LEFT JOIN DBO.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId
			LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOPN.ID
			LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId
			LEFT JOIN DBO.Employee AS E WITH (NOLOCK) ON WOPN.TechnicianId = E.EmployeeId
		WHERE CAST(WOPN.estimatedshipdate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
				AND	WO.customerid=ISNULL(@customername,WO.customerid)
				AND WO.mastercompanyid = @mastercompanyid
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

		SELECT DISTINCT
			UPPER(C.Name) 'customername',
			UPPER(C.CustomerCode) 'customercode',
			UPPER(IM.partnumber) 'pn',
			UPPER(IM.PartDescription) 'pndescription',
			WOPN.Quantity 'qty',
			UPPER(WOPN.WorkScope) 'workscope',
			UPPER(CN.Description) 'condition',
			UPPER(WO.WorkOrderNum) 'wonum',
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.ReceivedDate, 'MM/dd/yyyy') ELSE FORMAT(WOPN.ReceivedDate, 'dd MMM yyyy') END 'receiveddate', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WO.OpenDate, 'MM/dd/yyyy') ELSE FORMAT(WO.OpenDate, 'dd MMM yyyy') END 'opendate', 

			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOQ.SentDate, 'MM/dd/yyyy') ELSE FORMAT(WOQ.SentDate, 'dd MMM yyyy') END 'quotedate', 
			--FORMAT(WOQ.SentDate, 'MM/dd/yyyy') 'quotedate', 
			(DATEDIFF(DAY, WOPN.ReceivedDate, WOQ.sentDate)) 'quotedays',
			--FORMAT(WOQ.approveddate, 'MM/dd/yyyy') 'approveddate', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOQ.approveddate, 'MM/dd/yyyy') ELSE FORMAT(WOQ.approveddate, 'dd MMM yyyy') END 'approveddate', 
			DATEDIFF(DAY, WOQ.sentDate, WOQ.approveddate) 'approveddays',
			--FORMAT(WOPN.EstimatedShipDate, 'MM/dd/yyyy') 'estshipdate', 
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOPN.EstimatedShipDate, 'MM/dd/yyyy') ELSE FORMAT(WOPN.EstimatedShipDate, 'dd MMM yyyy') END 'estshipdate', 
			DATEDIFF(DAY, WOQ.approveddate, WOPN.EstimatedShipDate) 'estshipdays',
			DATEDIFF(DAY, WOQ.approveddate, WOPN.EstimatedShipDate) + DATEDIFF(DAY, WOPN.ReceivedDate, WOQ.sentDate) 'tat',
			WOBI.InvoiceNo 'invoicenum',
			CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(WOBI.InvoiceDate, 'MM/dd/yyyy') ELSE FORMAT(WOBI.InvoiceDate, 'dd MMM yyyy') END 'invoicedate', 
			--FORMAT(WOBI.InvoiceDate, 'MM/dd/yyyy') 'invoicedate', 
			UPPER(E.FirstName + ' ' + E.LastName) 'techname',
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
		FROM DBO.WorkOrder WO WITH (NOLOCK)
			INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId	
			INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID
			INNER JOIN DBO.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID
			LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON WO.WorkOrderId = WOBI.WorkOrderId AND WOBI.IsVersionIncrease=0
			LEFT JOIN DBO.Condition CN WITH (NOLOCK) ON WOPN.ConditionId = CN.ConditionId
			LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK) ON WO.WorkOrderId = woq.WorkOrderId AND woq.IsVersionIncrease=0
			LEFT JOIN DBO.WorkOrderType WITH (NOLOCK) ON WO.WorkOrderTypeId = WorkOrderType.Id
			LEFT JOIN DBO.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId
			LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOPN.ID
			LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId
			LEFT JOIN DBO.Employee AS E WITH (NOLOCK) ON WOPN.TechnicianId = E.EmployeeId
		WHERE CAST(WOPN.estimatedshipdate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
				AND	WO.customerid=ISNULL(@customername,WO.customerid)
				AND WO.mastercompanyid = @mastercompanyid
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

    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usprpt_GetWorkOrderTATReport]',
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