/*************************************************************             
 ** File:   [usprpt_GetReceivingLogReport]             
 ** Author:   Mahesh Sorathiya    
 ** Description: Get Data for ReceivingLog Report    
 ** Purpose:           
 ** Date:   27-April-2022         
            
 ** PARAMETERS:             
     
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
  ** S NO   Date            Author				Change Description              
  ** --   --------			-------				--------------------------------            
     1    27-APR-2022		Mahesh Sorathiya	Created 
	 2    20-JUN-2023		Devendra Shekh		made changes for total 
	 3    14-MAR-2024		Vishal Suthar		modified to get proper unit cost and extended unit cost based on received qty
       
EXECUTE   [dbo].[usprpt_GetReceivingLogReport] '','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'  
**************************************************************/  
CREATE   PROCEDURE [dbo].[usprpt_GetReceivingLogReport] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
  
  declare @Fromdate datetime2,
	@Todate datetime2,
	@partnumber varchar(50) = NULL,
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

  select 
   
	@Fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Stock Received Date' 
	then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @Fromdate end,
	@Todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Stock Received Date' 
	then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @Todate end,
	@partnumber=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='PN(Optional)' 
	then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @partnumber end,
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
  
  DECLARE @ModuleID INT = 4; -- MS Module ID

  IF ISNULL(@PageSize,0)=0
		BEGIN 
		  SELECT  @PageSize=COUNT(*) FROM(
		  SELECT 
				UPPER(POP.partnumber) 'pn',  
				UPPER(POP.PartDescription) 'pndescription', 
				UPPER(STL.ReceiverNumber) 'recnum',  
				FORMAT(STL.OrderDate, 'MM/dd/yyyy hh:mm:tt') 'orderdate',  
				FORMAT(STL.ReceivedDate, 'MM/dd/yyyy hh:mm:tt') 'rcvddate',  
				UPPER(PO.PurchaseOrderNumber) AS 'poronum',  
				UPPER(PO.status) 'porostatus',  
				UPPER(STL.ControlNumber) 'ctrlnum',  
				UPPER(STL.IdNumber) 'idnum',  
				UPPER(STL.StockLineNumber) 'slnum', 
				UPPER(STL.SerialNumber) 'sernum',  
				UPPER(POP.stocktype) 'stocktype',  
				UPPER(POP.AltEquiPartNumber) 'altequiv',  
				UPPER(POP.manufacturer) 'manufacturer',  
				UPPER(POP.itemtype) 'itemtype',  
				UPPER(POP.QuantityOrdered) 'qtyord',  
				UPPER(STL.Quantity) 'qtyrcvd',  
				--UPPER(POP.UnitCost) 'unitcost',  
				UPPER(ISNULL(STL.UnitCost, 0)) 'unitcost',  
				--UPPER(POP.ExtendedCost) 'extcost',  
				UPPER(ISNULL(STL.Quantity, 0) * ISNULL(STL.UnitCost, 0)) 'extcost',  
				UPPER(POP.QuantityRejected) 'qtyrej',  
				POP.QuantityBackOrdered 'qtyonbacklog',  
				UPPER(STL.CreatedBy) 'receivedby',  
				UPPER(PO.Requisitioner) 'requestor',  
				UPPER(PO.approvedby) 'approver',  
				UPPER(STL.Site) 'site',  
				UPPER(STL.Warehouse) 'warehouse',  
				UPPER(STL.Location) 'location',  
				UPPER(STL.Shelf) 'shelf',  
				UPPER(STL.bin) 'bin', 
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
			  FROM DBO.PurchaseOrder PO WITH (NOLOCK)  
				INNER JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId and POP.isParent=1  
				INNER JOIN DBO.Stockline STL WITH (NOLOCK) ON STL.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId and STL.IsParent=1     
				INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = PO.PurchaseOrderId
				LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			  WHERE (POP.partnumber like '%'+@partnumber+'%' OR ISNULL(@partnumber, '') = '')  
			   AND CAST(STL.receiveddate AS DATE) BETWEEN CAST(@Fromdate AS DATE)  AND CAST(@Todate AS DATE)  
			   AND STL.mastercompanyid = @mastercompanyid
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
		  UNION
			SELECT 
				UPPER(POP.partnumber) 'pn',  
				UPPER(POP.PartDescription) 'pndescription', 
				UPPER(STL.ReceiverNumber) 'recnum',  
				FORMAT(STL.OrderDate, 'MM/dd/yyyy hh:mm:tt') 'orderdate',  
				FORMAT(STL.ReceivedDate, 'MM/dd/yyyy hh:mm:tt') 'rcvddate',  
				UPPER(PO.RepairOrderNumber) AS 'poronum',  
				UPPER(PO.status) 'porostatus',  
				UPPER(STL.ControlNumber) 'ctrlnum',  
				UPPER(STL.IdNumber) 'idnum',  
				UPPER(STL.StockLineNumber) 'slnum', 
				UPPER(STL.SerialNumber) 'sernum',  
				UPPER(POP.stocktype) 'stocktype',  
				UPPER(POP.AltEquiPartNumber) 'altequiv',  
				UPPER(POP.manufacturer) 'manufacturer',  
				UPPER(POP.itemtype) 'itemtype',  
				UPPER(POP.QuantityOrdered) 'qtyord',  
				UPPER(STL.Quantity) 'qtyrcvd',  
				--UPPER(POP.UnitCost) 'unitcost',  
				UPPER(ISNULL(STL.UnitCost, 0)) 'unitcost',  
				--UPPER(POP.ExtendedCost) 'extcost',  
				UPPER(ISNULL(STL.Quantity, 0) * ISNULL(STL.UnitCost, 0)) 'extcost',  
				UPPER(POP.QuantityRejected) 'qtyrej',  
				POP.QuantityBackOrdered 'qtyonbacklog',  
				UPPER(STL.CreatedBy) 'receivedby',  
				UPPER(PO.Requisitioner) 'requestor',  
				UPPER(PO.approvedby) 'approver',  
				UPPER(STL.Site) 'site',  
				UPPER(STL.Warehouse) 'warehouse',  
				UPPER(STL.Location) 'location',  
				UPPER(STL.Shelf) 'shelf',  
				UPPER(STL.bin) 'bin', 
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
			  FROM DBO.RepairOrder PO WITH (NOLOCK)  
				INNER JOIN DBO.RepairOrderPart POP WITH (NOLOCK) ON PO.RepairOrderId = POP.RepairOrderId and POP.isParent=1  
				INNER JOIN DBO.Stockline STL WITH (NOLOCK) ON STL.PurchaseOrderPartRecordId = POP.RepairOrderPartRecordId and STL.IsParent=1     
				INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = 24 AND MSD.ReferenceID = PO.RepairOrderId  
				LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
				WHERE (POP.partnumber like '%'+@partnumber+'%' OR ISNULL(@partnumber, '') = '')  
			   AND CAST(STL.receiveddate AS DATE) BETWEEN CAST(@Fromdate AS DATE)  AND CAST(@Todate AS DATE)  
			   AND STL.mastercompanyid = @mastercompanyid
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
		   ) T 
  
        END
	  
	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

	  ;WITH rptCTE (TotalRecordsCount, pn, pndescription, recnum, orderdate, rcvddate, poronum, porostatus, ctrlnum, idnum, slnum, sernum, stocktype, altequiv, 
					manufacturer, itemtype, qtyord, qtyrcvd, unitcost, extcost, qtyrej, qtyonbacklog,
					receivedby, requestor, approver, site, warehouse, location, shelf, bin, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, masterCompanyId) AS (
SELECT COUNT(1) OVER () AS TotalRecordsCount,* FROM(
  SELECT 
        UPPER(POP.partnumber) 'pn',  
        UPPER(POP.PartDescription) 'pndescription', 
        UPPER(STL.ReceiverNumber) 'recnum',  
        FORMAT(STL.OrderDate, 'MM/dd/yyyy hh:mm:tt') 'orderdate',  
        FORMAT(STL.ReceivedDate, 'MM/dd/yyyy hh:mm:tt') 'rcvddate',  
        UPPER(PO.PurchaseOrderNumber) AS 'poronum',  
        UPPER(PO.status) 'porostatus',  
        UPPER(STL.ControlNumber) 'ctrlnum',  
        UPPER(STL.IdNumber) 'idnum',  
        UPPER(STL.StockLineNumber) 'slnum', 
        UPPER(STL.SerialNumber) 'sernum',  
        UPPER(POP.stocktype) 'stocktype',  
        UPPER(POP.AltEquiPartNumber) 'altequiv',  
        UPPER(POP.manufacturer) 'manufacturer',  
        UPPER(POP.itemtype) 'itemtype',  
        UPPER(POP.QuantityOrdered) 'qtyord',  
        UPPER(STL.Quantity) 'qtyrcvd',  
		--ISNULL(POP.UnitCost, 0) 'unitcost',  
		ISNULL(STL.UnitCost, 0) 'unitcost',  
        --ISNULL(POP.ExtendedCost, 0) 'extcost',   
        (ISNULL(STL.Quantity, 0) * ISNULL(STL.UnitCost, 0)) 'extcost',   
        UPPER(POP.QuantityRejected) 'qtyrej',  
        POP.QuantityBackOrdered 'qtyonbacklog',  
        UPPER(STL.CreatedBy) 'receivedby',  
        UPPER(PO.Requisitioner) 'requestor',  
        UPPER(PO.approvedby) 'approver',  
        UPPER(STL.Site) 'site',  
        UPPER(STL.Warehouse) 'warehouse',  
        UPPER(STL.Location) 'location',  
        UPPER(STL.Shelf) 'shelf',  
        UPPER(STL.bin) 'bin', 
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
		PO.MasterCompanyId
      FROM DBO.PurchaseOrder PO WITH (NOLOCK)  
        INNER JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId and POP.isParent=1  
        --INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON POP.ItemMasterId = im.ItemMasterId  
        INNER JOIN DBO.Stockline STL WITH (NOLOCK) ON STL.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId and STL.IsParent=1     
		INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = PO.PurchaseOrderId
		LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
        --INNER JOIN DBO.mastercompany MC WITH (NOLOCK) ON STL.MasterCompanyId = MC.MasterCompanyId 
      WHERE (POP.partnumber like '%'+@partnumber+'%' OR ISNULL(@partnumber, '') = '')  
       AND CAST(STL.receiveddate AS DATE) BETWEEN CAST(@Fromdate AS DATE)  AND CAST(@Todate AS DATE)  
       AND STL.mastercompanyid = @mastercompanyid
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
  UNION
	SELECT 
        UPPER(POP.partnumber) 'pn',  
        UPPER(POP.PartDescription) 'pndescription', 
        UPPER(STL.ReceiverNumber) 'recnum',  
        FORMAT(STL.OrderDate, 'MM/dd/yyyy hh:mm:tt') 'orderdate',  
        FORMAT(STL.ReceivedDate, 'MM/dd/yyyy hh:mm:tt') 'rcvddate',  
        UPPER(PO.RepairOrderNumber) AS 'poronum',  
        UPPER(PO.status) 'porostatus',  
        UPPER(STL.ControlNumber) 'ctrlnum',  
        UPPER(STL.IdNumber) 'idnum',  
        UPPER(STL.StockLineNumber) 'slnum', 
        UPPER(STL.SerialNumber) 'sernum',  
        UPPER(POP.stocktype) 'stocktype',  
        UPPER(POP.AltEquiPartNumber) 'altequiv',  
        UPPER(POP.manufacturer) 'manufacturer',  
        UPPER(POP.itemtype) 'itemtype',  
        UPPER(POP.QuantityOrdered) 'qtyord',  
        UPPER(STL.Quantity) 'qtyrcvd',  
        --ISNULL(POP.UnitCost, 0) 'unitcost',  
        ISNULL(STL.UnitCost, 0) 'unitcost',  
        --ISNULL(POP.ExtendedCost, 0) 'extcost',  
        (ISNULL(STL.Quantity, 0) * ISNULL(STL.UnitCost, 0)) 'extcost',  
        UPPER(POP.QuantityRejected) 'qtyrej',  
        POP.QuantityBackOrdered 'qtyonbacklog',  
        UPPER(STL.CreatedBy) 'receivedby',  
        UPPER(PO.Requisitioner) 'requestor',  
        UPPER(PO.approvedby) 'approver',  
        UPPER(STL.Site) 'site',  
        UPPER(STL.Warehouse) 'warehouse',  
        UPPER(STL.Location) 'location',  
        UPPER(STL.Shelf) 'shelf',  
        UPPER(STL.bin) 'bin', 
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
		PO.MasterCompanyId
      FROM DBO.RepairOrder PO WITH (NOLOCK)  
        INNER JOIN DBO.RepairOrderPart POP WITH (NOLOCK) ON PO.RepairOrderId = POP.RepairOrderId and POP.isParent=1  
        INNER JOIN DBO.Stockline STL WITH (NOLOCK) ON STL.PurchaseOrderPartRecordId = POP.RepairOrderPartRecordId and STL.IsParent=1     
	    INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = 24 AND MSD.ReferenceID = PO.RepairOrderId  
		LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
		WHERE (POP.partnumber like '%'+@partnumber+'%' OR ISNULL(@partnumber, '') = '')  
       AND CAST(STL.receiveddate AS DATE) BETWEEN CAST(@Fromdate AS DATE)  AND CAST(@Todate AS DATE)  
       AND STL.mastercompanyid = @mastercompanyid
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
   ) T )
   ,FinalCTE(TotalRecordsCount, pn, pndescription, recnum, orderdate, rcvddate, poronum, porostatus, ctrlnum, idnum, slnum, sernum, stocktype, altequiv, manufacturer, itemtype, qtyord, qtyrcvd, unitcost, extcost, qtyrej, qtyonbacklog,
				receivedby, requestor, approver, site, warehouse, location, shelf, bin, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, masterCompanyId) 
			  AS (SELECT DISTINCT TotalRecordsCount, pn, pndescription, recnum, orderdate, rcvddate, poronum, porostatus, ctrlnum, idnum, slnum, sernum, stocktype, altequiv, manufacturer, itemtype, qtyord, qtyrcvd, unitcost, extcost, qtyrej, qtyonbacklog,
				receivedby, requestor, approver, site, warehouse, location, shelf, bin, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, masterCompanyId FROM rptCTE)

			,WithTotal (masterCompanyId, TotalUnitCost, TotalExtCost ) 
			  AS (SELECT masterCompanyId, 
				FORMAT(SUM(unitcost), 'N', 'en-us') TotalUnitCost,
				FORMAT(SUM(extcost), 'N', 'en-us') TotalExtCost
				FROM FinalCTE
				GROUP BY masterCompanyId)

			  SELECT COUNT(2) OVER () AS TotalRecordsCount, pn, pndescription, recnum, orderdate, rcvddate, poronum, porostatus, ctrlnum, idnum, slnum, sernum, stocktype, altequiv, manufacturer, itemtype, qtyord, qtyrcvd,
					FORMAT(ISNULL(unitcost,0) , 'N', 'en-us') 'unitcost',    
					FORMAT(ISNULL(extcost,0) , 'N', 'en-us') 'extcost',    
					qtyrej, qtyonbacklog, receivedby, requestor, approver, site, warehouse, location, shelf, bin, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
					level9, level10,
					WC.TotalUnitCost,
					WC.TotalExtCost
					FROM FinalCTE FC
					INNER JOIN WithTotal WC ON FC.masterCompanyId = WC.masterCompanyId
			    	ORDER BY rcvddate
					OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;
  
  END TRY  
  
  BEGIN CATCH  
     
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[usprpt_GetReceivingLogReport]',  
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
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH  
    
END