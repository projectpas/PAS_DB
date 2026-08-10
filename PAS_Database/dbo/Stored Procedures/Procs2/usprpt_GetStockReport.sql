/*************************************************************           
 ** File:   [usprpt_GetNonStockReport]
 ** Author:   
 ** Description: Get Data for Stock Report
 ** Purpose:         
 ** Date:  
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
    1    
    1    22-JUNE-2023     Devendra Shekh    made changes for total unitcost and extcost
	2    22-JULY-2025     Moin Bloch        added Some New Fields
	3    23-JULY-2025     Moin Bloch        modified Currency
	4    06-Aug-2025      Sahdev Saliya     Added New Fields(TagType,TaggedBy,TagDate)
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	6    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	7    24/July/2026			 RAJESH GAMI						[PN-17350] - Removed obsolete ItemMaster/Stockline IsNonStock=0 filters (4) to allow Non-Stock items in Stock Report
  ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
**************************************************************/
CREATE PROCEDURE [dbo].[usprpt_GetStockReport]     
@PageNumber int = 1,    
@PageSize int = NULL,    
@mastercompanyid int,    
@xmlFilter XML    
    
AS    
BEGIN    
  SET NOCOUNT ON;    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    
 declare @Fromdate DATETIME2,    
 @Todate DATETIME2,    
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
 @Site VARCHAR(MAX) = NULL,  
 @Warehouse VARCHAR(MAX) = NULL,  
 @Location VARCHAR(MAX) = NULL,  
 @Shelf VARCHAR(MAX) = NULL,  
 @Bin VARCHAR(MAX) = NULL,  
 @IsDownload BIT = NULL,    
 @ECS BIT = 0,   
 @ItemMasterId BIGINT = NULL

BEGIN TRY    
          
 SELECT
 @Fromdate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date'     
 THEN CONVERT(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Fromdate END,    
 @Todate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date'     
 THEN CONVERT(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @Todate END,    
 @tagtype = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Tag Type'     
 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @tagtype END,    
 @ECS = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Exclude Customer Stock ?'     
 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @ECS END,  
 @level1 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1'     
 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level1 END,    
 @level2 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2'     
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
 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 END,  
 @Site=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Site'     
 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Site END,
 @Warehouse=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Warehouse'     
 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Warehouse END,
 @Location=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Location'     
 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Location END,
 @Shelf=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Shelf'     
 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Shelf END,
 @Bin=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Bin'     
 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Bin END,
 @ItemMasterId=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Part Number'     
 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @ItemMasterId END

  FROM    
      @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)        
      DECLARE @ModuleID INT = 2; -- MS Module ID    
   SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END    
  
  IF(@ItemMasterId = '')
  BEGIN
	SET @ItemMasterId = NULL;
  END

  IF ISNULL(@PageSize,0)=0    
  BEGIN     
    SELECT @PageSize=COUNT(*)    
    FROM [dbo].[Stockline] stl WITH (NOLOCK)    
   INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
    LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID    
   LEFT OUTER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId LEFT OUTER JOIN [dbo].[Currency] cr WITH (NOLOCK) ON im.PurchaseCurrencyId = cr.CurrencyId
   LEFT OUTER JOIN [dbo].[Customer] cst WITH (NOLOCK) ON stl.CustomerId = cst.CustomerId  
   LEFT OUTER JOIN [dbo].PurchaseOrder pox WITH (NOLOCK) ON stl.PurchaseOrderId = pox.PurchaseOrderId    
   LEFT OUTER JOIN [dbo].PurchaseOrderPart POP WITH (NOLOCK) ON stl.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId    
   LEFT OUTER JOIN [dbo].RepairOrder rox WITH (NOLOCK) ON stl.RepairOrderId = rox.repairorderid    
   LEFT OUTER JOIN [dbo].[WorkOrder] wox WITH (NOLOCK) ON stl.WorkOrderId = wox.WorkOrderId   
   LEFT OUTER JOIN [dbo].[SubWorkOrder] swox WITH (NOLOCK) ON stl.SubWorkOrderId = swox.SubWorkOrderId 
   LEFT JOIN [dbo].[Vendor] VNDR WITH (NOLOCK) ON stl.VendorId = VNDR.VendorId    
   LEFT JOIN [dbo].[StocklineAdjustment] stladj WITH (NOLOCK) ON stl.StockLineId = stladj.StocklineId    
   LEFT JOIN [dbo].[StocklineAdjustmentDataType] stladjtype WITH (NOLOCK) ON stladj.StocklineAdjustmentDataTypeId = stladjtype.StocklineAdjustmentDataTypeId    
   WHERE stl.MasterCompanyId = @mastercompanyid 
    AND stl.IsParent = 1 
	AND stl.IsDeleted = 0 
	AND (@ItemMasterId IS NULL OR stl.ItemMasterId = @ItemMasterId)
	AND CAST(stl.CreatedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE)  AND CAST(@Todate AS DATE)  
    AND stl.IsCustomerStock =  CASE WHEN @ECS = 1 THEN 0 ELSE stl.IsCustomerStock END  
    --AND (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ','))) 
	AND (ISNULL(@Site,'') ='' OR stl.SiteId IN (SELECT Item FROM DBO.SPLITSTRING(@Site,',')))   
	AND (ISNULL(@Warehouse,'') ='' OR stl.WarehouseId IN (SELECT Item FROM DBO.SPLITSTRING(@Warehouse,',')))   
	AND (ISNULL(@Location,'') ='' OR stl.LocationId IN (SELECT Item FROM DBO.SPLITSTRING(@Location,',')))   
	AND (ISNULL(@Shelf,'') ='' OR stl.ShelfId IN (SELECT Item FROM DBO.SPLITSTRING(@Shelf,',')))   
	AND (ISNULL(@Bin,'') ='' OR stl.BinId IN (SELECT Item FROM DBO.SPLITSTRING(@Bin,',')))   
    AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))    
    AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))    
    AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))    
    AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))    
    AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))    
    AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))    
    AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))    
    AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))    
    AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))    
    AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))     
   END    
       
   SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END    
   SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END    

     ;WITH rptCTE (TotalRecordsCount, pn, pndescription, sernum, slnum, cond, itemgroup, iscustomerstock, uom, itemtype, stocktype, Alt_Equiv,
				 vendorname, vendorcode, qtyonhand, qtyreserved, qtyavail, qtyscrapped, qtyadjusted, pounitcost, extcost, obtainedfrom, owner, traceableto, tagtype, taggedbyname, tagdate,
				 mfg, unitprice, extprice, level1, level2, level3, level4, level5, level6, level7, level8,
			     level9, level10, site, warehouse, Location, Shelf, Bin, glaccount, ponum, ronum, rocost, rcvddate, receivernum, receiverrecon, poqty, masterCompanyId,itemClassificationName,
			     workOrderNum,subWorkOrderNo,daysFromReceiveDate,currencyName,customerName) AS (
      SELECT COUNT(1) OVER () AS TotalRecordsCount,    
        UPPER(im.partnumber) AS 'pn',    
        UPPER(im.PartDescription) AS 'pndescription',    
        UPPER(stl.SerialNumber) 'sernum',    
        UPPER(stl.stocklineNumber) 'slnum',    
        UPPER(stl.condition) 'cond',    
        UPPER(stl.itemgroup) 'itemgroup',   
		UPPER(stl.IsCustomerStock) 'iscustomerstock',  
        UPPER(stl.unitofmeasure) 'uom',    
        UPPER(stl.itemtype) 'itemtype',    
        CASE WHEN stl.isPma = 1 AND stl.IsDER = 1 THEN 'PMA&DER'    
			 WHEN stl.isPma = 1 AND (stl.IsDER IS NULL OR stl.IsDER = 0) THEN 'PMA'    
		   	 WHEN (stl.isPma = 0 OR stl.isPma IS NULL) AND stl.IsDER = 1 THEN 'DER'    
			 ELSE 'OEM' END AS stocktype,    
        UPPER(POP.altequipartnumber) 'Alt_Equiv',    
        UPPER(VNDR.VendorName) 'vendorname',    
        UPPER(VNDR.VendorCode) 'vendorcode',    
        stl.QuantityOnHand 'qtyonhand',    
        stl.QuantityReserved 'qtyreserved',    
        UPPER(stl.QuantityAvailable) 'qtyavail',    
        'NA' 'qtyscrapped',    
        CASE WHEN stladjtype.StocklineAdjustmentDataTypeId = 10 THEN STl.QuantityOnHand - stladj.ChangedTo ELSE 0 END AS 'qtyadjusted',    
		ISNULL(stl.purchaseorderUnitCost , 0) 'pounitcost',    
		ISNULL(stl.PurchaseOrderExtendedCost , 0) 'extcost',    
		UPPER(stl.Obtainfromname) 'obtainedfrom',    
        UPPER(stl.OwnerName) 'owner',    
        UPPER(stl.TraceableToname) 'traceableto',
		(ISNULL(stl.TagType,'')) 'tagtype',         
		(ISNULL(stl.taggedbyname,'')) 'taggedbyname',        
		stl.TagDate 'tagdate',     
        UPPER(stl.manufacturer) 'mfg',    
		ISNULL(stl.UnitCost , 0) 'unitprice',    
		ISNULL(ISNULL(stl.UnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) 'extprice',    
        --stl.UnitCost 'unitprice',    
        --stl.UnitCost*stl.QuantityOnHand 'extprice',    
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
        UPPER(stl.site) 'site',    
        UPPER(stl.warehouse) 'warehouse',    
        UPPER(stl.location) 'Location',    
        UPPER(stl.shelf) 'Shelf',    
        UPPER(stl.bin) 'Bin',    
        UPPER(stl.glAccountname) 'glaccount',    
        UPPER(pox.PurchaseOrderNumber) 'ponum',    
        UPPER(rox.RepairOrderNumber) 'ronum',    
		ISNULL(stl.RepairOrderUnitCost ,0) 'rocost',    
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(STL.receiveddate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), STL.receiveddate, 107) END 'rcvddate',     
        UPPER(stl.ReceiverNumber) 'receivernum',    
        UPPER(stl.ReconciliationNumber) 'receiverrecon',
		UPPER(ISNULL(stl.Quantity,0)) 'poqty',
		stl.MasterCompanyId,
		UPPER(im.itemClassificationName) 'itemClassificationName',
		UPPER(wox.WorkOrderNum) 'workOrderNum',
		UPPER(swox.SubWorkOrderNo) 'subWorkOrderNo',
		DATEDIFF(DAY, STL.receiveddate, GETUTCDATE()) 'daysFromReceiveDate',
		UPPER(cr.Code) 'currencyName',
		UPPER(cst.[Name]) 'customerName'
      FROM [dbo].[Stockline] stl WITH (NOLOCK)    
     INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	  LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID    
	 LEFT OUTER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId LEFT OUTER JOIN [dbo].[Currency] cr WITH (NOLOCK) ON im.PurchaseCurrencyId = cr.CurrencyId
	 LEFT OUTER JOIN [dbo].[Customer] cst WITH (NOLOCK) ON stl.CustomerId = cst.CustomerId  
	 LEFT OUTER JOIN [dbo].[PurchaseOrder] pox WITH (NOLOCK) ON stl.PurchaseOrderId = pox.PurchaseOrderId    
	 LEFT OUTER JOIN [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) ON stl.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId    
	 LEFT OUTER JOIN [dbo].[RepairOrder] rox WITH (NOLOCK) ON stl.RepairOrderId = rox.repairorderid   
	 LEFT OUTER JOIN [dbo].[WorkOrder] wox WITH (NOLOCK) ON stl.WorkOrderId = wox.WorkOrderId   
	 LEFT OUTER JOIN [dbo].[SubWorkOrder] swox WITH (NOLOCK) ON stl.SubWorkOrderId = swox.SubWorkOrderId  
	 LEFT JOIN [dbo].[Vendor] VNDR WITH (NOLOCK) ON stl.VendorId = VNDR.VendorId    
	 LEFT JOIN [dbo].[StocklineAdjustment] stladj WITH (NOLOCK) ON stl.StockLineId = stladj.StocklineId    
	 LEFT JOIN [dbo].[StocklineAdjustmentDataType] stladjtype WITH (NOLOCK) ON stladj.StocklineAdjustmentDataTypeId = stladjtype.StocklineAdjustmentDataTypeId    
     WHERE stl.[MasterCompanyId] = @mastercompanyid 
	 AND stl.[IsParent] = 1 
	 AND stl.[IsDeleted] = 0 
	 AND (@ItemMasterId IS NULL OR stl.ItemMasterId = @ItemMasterId)
	 AND CAST(stl.CreatedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)  
	 AND stl.[IsCustomerStock] = CASE WHEN @ECS = 1 THEN 0 ELSE stl.[IsCustomerStock] END  
     --AND (ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM STRING_SPLIT(ISNULL(@tagtype,''), ',')))    
     AND (ISNULL(@Site,'') ='' OR stl.SiteId IN (SELECT Item FROM DBO.SPLITSTRING(@Site,',')))   
	 AND (ISNULL(@Warehouse,'') ='' OR stl.WarehouseId IN (SELECT Item FROM DBO.SPLITSTRING(@Warehouse,',')))   
	 AND (ISNULL(@Location,'') ='' OR stl.LocationId IN (SELECT Item FROM DBO.SPLITSTRING(@Location,',')))   
	 AND (ISNULL(@Shelf,'') ='' OR stl.ShelfId IN (SELECT Item FROM DBO.SPLITSTRING(@Shelf,',')))   
	 AND (ISNULL(@Bin,'') ='' OR stl.BinId IN (SELECT Item FROM DBO.SPLITSTRING(@Bin,',')))   
	 AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))    
     AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))    
     AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))    
     AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))    
     AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))    
     AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))    
     AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))    
     AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))    
     AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))    
     AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))   
   )
   ,FinalCTE(TotalRecordsCount, pn, pndescription, sernum, slnum, cond, itemgroup, iscustomerstock, uom, itemtype, stocktype, Alt_Equiv,
				 vendorname, vendorcode, qtyonhand, qtyreserved, qtyavail, qtyscrapped, qtyadjusted, pounitcost, extcost, obtainedfrom, owner, traceableto, tagtype, taggedbyname, tagdate,
				 mfg, unitprice, extprice, level1, level2, level3, level4, level5, level6, level7, level8,
				level9, level10, site, warehouse, Location, Shelf, Bin, glaccount, ponum, ronum, rocost, rcvddate, receivernum, receiverrecon, poqty, masterCompanyId,itemClassificationName,workOrderNum,subWorkOrderNo,daysFromReceiveDate,currencyName,customerName) 
			  AS (SELECT DISTINCT TotalRecordsCount, pn, pndescription, sernum, slnum, cond, itemgroup, iscustomerstock, uom, itemtype, stocktype, Alt_Equiv,
				 vendorname, vendorcode, qtyonhand, qtyreserved, qtyavail, qtyscrapped, qtyadjusted, pounitcost, extcost, obtainedfrom, owner, traceableto, tagtype, taggedbyname, tagdate,
				 mfg, unitprice, extprice, level1, level2, level3, level4, level5, level6, level7, level8,
			  level9, level10, site, warehouse, Location, Shelf, Bin, glaccount, ponum, ronum, rocost, rcvddate, receivernum, receiverrecon, poqty, masterCompanyId,itemClassificationName,workOrderNum,subWorkOrderNo,daysFromReceiveDate,currencyName,customerName FROM rptCTE)

			,WithTotal (masterCompanyId, TotalPOUnitCost, TotalExtCost, TotalUnitPrice, TotalExtPrice,TotalROCost) 
			  AS (SELECT masterCompanyId, 
				FORMAT(SUM(pounitcost), 'N', 'en-us') TotalUnitCost,
				FORMAT(SUM(extcost), 'N', 'en-us') TotalExtCost,
				FORMAT(SUM(unitprice), 'N', 'en-us') TotalUnitPrice,
				FORMAT(SUM(extprice), 'N', 'en-us') TotalExtPrice,
				FORMAT(SUM(rocost), 'N', 'en-us') TotalROCost
				FROM FinalCTE
				GROUP BY masterCompanyId)

			  SELECT COUNT(2) OVER () AS TotalRecordsCount, pn, pndescription, sernum, slnum, cond, itemgroup, iscustomerstock, uom, itemtype, stocktype, Alt_Equiv,
					vendorname, vendorcode, qtyonhand, qtyreserved, qtyavail, qtyscrapped, qtyadjusted,
					FORMAT(ISNULL(pounitcost,0) , 'N', 'en-us') 'pounitcost',    
					FORMAT(ISNULL(extcost,0) , 'N', 'en-us') 'extcost', 
					obtainedfrom, owner, traceableto, tagtype, taggedbyname, tagdate, mfg,
					FORMAT(ISNULL(unitprice,0) , 'N', 'en-us') 'unitprice',    
					FORMAT(ISNULL(extprice,0) , 'N', 'en-us') 'extprice',    
					level1, level2, level3, level4, level5, level6, level7, level8,
					level9, level10, site,warehouse, Location, Shelf, Bin, glaccount, ponum, ronum, 
					FORMAT(ISNULL(rocost,0) , 'N', 'en-us') 'rocost',    
					rcvddate, receivernum, receiverrecon, poqty,
					WC.TotalPOUnitCost,
					WC.TotalExtCost,
					WC.TotalUnitPrice,
					WC.TotalExtPrice,
					WC.TotalROCost,
					FC.itemClassificationName,
					FC.workOrderNum,
					FC.subWorkOrderNo,
					FC.daysFromReceiveDate,
					FC.currencyName,
					FC.customerName
				FROM FinalCTE FC
					INNER JOIN WithTotal WC ON FC.masterCompanyId = WC.masterCompanyId
				ORDER BY pn DESC
				OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY; 
    
  END TRY    
    
  BEGIN CATCH    
       
    DECLARE @ErrorLogID int,    
            @DatabaseName varchar(100) = DB_NAME()    
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            ,    
            @AdhocComments varchar(150) = '[usprpt_GetStockReport]',    
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