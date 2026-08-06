/*************************************************************           
 ** File:   [usprpt_GetStockReportSSRS]
 ** Author: [Bhargav Saliya]
 ** Description: Get Data for Stock Report ssrs
 ** Purpose:         
 ** Date:  
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
  ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    22-08-2025     Bhargav Saliya      Created 
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	4    24/July/2026			 RAJESH GAMI						[PN-17350] - Removed obsolete ItemMaster/Stockline IsNonStock=0 filters (5) to allow Non-Stock items in Stock Report SSRS
**************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[usprpt_GetStockReportSSRS]   
@id DATETIME2,
@id2 DATETIME2,
@id5 VARCHAR(max) = NULL,
@id6 BIGINT = NULL,
@id7 BIT = false,
@strFilter VARCHAR(max) = NULL,
@mastercompanyid int    
    
AS    
BEGIN    
  SET NOCOUNT ON;    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    

	IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPMSFilter
	END
	
	CREATE TABLE #TEMPMSFilter(        
			ID BIGINT  IDENTITY(1,1),        
			LevelIds VARCHAR(MAX)			 
		) 

	INSERT INTO #TEMPMSFilter(LevelIds)
	SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!')

	IF OBJECT_ID(N'tempdb..#TEMPPartlocationFilter') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPPartlocationFilter
	END

	CREATE TABLE #TEMPPartlocationFilter(        
			ID BIGINT  IDENTITY(1,1),        
			PartLocationIds VARCHAR(MAX)			 
		) 

	INSERT INTO #TEMPPartlocationFilter(PartLocationIds)
	SELECT Item FROM DBO.SPLITSTRING(@id5,'!')

	DECLARE   
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
	@Bin VARCHAR(MAX) = NULL,@PageSize int = NULL,@PageNumber int = 1,@IsDownload BIT = NULL,@ModuleID INT = 2;

	SELECT @level1 = LevelIds FROM #TEMPMSFilter WHERE ID = 1 
	SELECT @level2 = LevelIds FROM #TEMPMSFilter WHERE ID = 2 
	SELECT @level3 = LevelIds FROM #TEMPMSFilter WHERE ID = 3 
	SELECT @level4 = LevelIds FROM #TEMPMSFilter WHERE ID = 4 
	SELECT @level5 = LevelIds FROM #TEMPMSFilter WHERE ID = 5 
	SELECT @level6 = LevelIds FROM #TEMPMSFilter WHERE ID = 6 
	SELECT @level7 = LevelIds FROM #TEMPMSFilter WHERE ID = 7 
	SELECT @level8 = LevelIds FROM #TEMPMSFilter WHERE ID = 8 
	SELECT @level9 = LevelIds FROM #TEMPMSFilter WHERE ID = 9 
	SELECT @level10 = LevelIds FROM #TEMPMSFilter WHERE ID = 10

	SELECT @Site = PartLocationIds FROM #TEMPPartlocationFilter WHERE ID = 1
	SELECT @Warehouse = PartLocationIds FROM #TEMPPartlocationFilter WHERE ID = 2
	SELECT @Location = PartLocationIds FROM #TEMPPartlocationFilter WHERE ID = 3
	SELECT @Shelf = PartLocationIds FROM #TEMPPartlocationFilter WHERE ID = 4
	SELECT @Bin = PartLocationIds FROM #TEMPPartlocationFilter WHERE ID = 5

BEGIN TRY    
  
  IF(@id6 = '')
  BEGIN
	SET @id6 = NULL;
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
	AND (@id6 IS NULL OR stl.ItemMasterId = @id6)
	AND CAST(stl.CreatedDate AS DATE) BETWEEN CAST(@id AS DATE)  AND CAST(@id2 AS DATE)  
    AND stl.IsCustomerStock =  CASE WHEN @id7 = 1 THEN 0 ELSE stl.IsCustomerStock END  
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

   ;WITH CTE_IntegrationPortal AS (
				SELECT
					iM.ItemMasterId,
					STRING_AGG(CAST(R.[Description] AS NVARCHAR(MAX)), ',') AS Ranking,
					STRING_AGG(mp.RankingId, ',') AS RankingIds
				FROM dbo.ItemMaster iM WITH(NOLOCK)
				left JOIN dbo.ItemMasterRanking mp WITH(NOLOCK) ON iM.ItemMasterId = mp.ItemMasterId
				left JOIN dbo.Ranking R WITH(NOLOCK) ON mp.RankingId = R.RankingId
				WHERE mp.RankingId IS NOT NULL
				 GROUP BY iM.ItemMasterId
			),

     rptCTE (TotalRecordsCount, pn, pndescription, sernum, slnum, cond, itemgroup, iscustomerstock, uom, itemtype, stocktype, Alt_Equiv,
				 vendorname, vendorcode, qtyonhand, qtyreserved, qtyavail, qtyscrapped, qtyadjusted, pounitcost, extcost, obtainedfrom, owner, traceableto, tagtype, taggedbyname, tagdate,
				 mfg, unitprice, extprice, level1, level2, level3, level4, level5, level6, level7, level8,
			     level9, level10, site, warehouse, Location, Shelf, Bin, glaccount, ponum, ronum, rocost, rcvddate, receivernum, receiverrecon, poqty, masterCompanyId,itemClassificationName,
			     workOrderNum,subWorkOrderNo,daysFromReceiveDate,currencyName,customerName,RankingsName) AS (
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
		UPPER(cst.[Name]) 'customerName',
		UPPER(itp.Ranking) 'RankingsName'
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
	 LEFT JOIN CTE_IntegrationPortal itp WITH(NOLOCK) ON im.ItemMasterId = itp.ItemMasterId
     WHERE stl.[MasterCompanyId] = @mastercompanyid 
	 AND stl.[IsParent] = 1 
	 AND stl.[IsDeleted] = 0 
	 AND (@id6 IS NULL OR stl.ItemMasterId = @id6)
	 AND CAST(stl.CreatedDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(@id2 AS DATE)  
	 AND stl.[IsCustomerStock] = CASE WHEN @id7 = 1 THEN 0 ELSE stl.[IsCustomerStock] END  
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
				level9, level10, site, warehouse, Location, Shelf, Bin, glaccount, ponum, ronum, rocost, rcvddate, receivernum, receiverrecon, poqty, masterCompanyId,itemClassificationName,workOrderNum,subWorkOrderNo,daysFromReceiveDate,currencyName,customerName,RankingsName) 
			  AS (SELECT DISTINCT TotalRecordsCount, pn, pndescription, sernum, slnum, cond, itemgroup, iscustomerstock, uom, itemtype, stocktype, Alt_Equiv,
				 vendorname, vendorcode, qtyonhand, qtyreserved, qtyavail, qtyscrapped, qtyadjusted, pounitcost, extcost, obtainedfrom, owner, traceableto, tagtype, taggedbyname, tagdate,
				 mfg, unitprice, extprice, level1, level2, level3, level4, level5, level6, level7, level8,
			  level9, level10, site, warehouse, Location, Shelf, Bin, glaccount, ponum, ronum, rocost, rcvddate, receivernum, receiverrecon, poqty, masterCompanyId,itemClassificationName,workOrderNum,subWorkOrderNo,daysFromReceiveDate,currencyName,customerName,RankingsName FROM rptCTE)

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
					FC.customerName,FC.RankingsName
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
            @AdhocComments varchar(150) = '[usprpt_GetStockReportSSRS]',    
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +      
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) +      
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),    
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