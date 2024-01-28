/*************************************************************           
 ** File:   [usprpt_GetStockReportAsOfNow]           
 ** Author:   VISHAL SUTHAR  
 ** Description: Get Data for Stock Report  
 ** Purpose:         
 ** Date:   01-01-2024       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  			Change Description            
 ** --   --------		-------				--------------------------------          
	1	 01-01-2024		VISHAL SUTHAR		Created
     
exec usprpt_GetStockReportAsOfNow @mastercompanyid=11,@id=N'1/18/2024',@id2=N'',@id3=1,@strFilter=N'49!50,51!!!!!!!!'
**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetStockReportAsOfNow]
	@mastercompanyid INT,
	@id DATETIME2,
	@id2 VARCHAR(100),
	@id3 bit,
	@strFilter VARCHAR(max) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY

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
	@Level10 VARCHAR(MAX) = NULL 

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

    DECLARE @ModuleID INT = 2; -- MS Module ID 

	IF OBJECT_ID(N'tempdb..#TEMPOriginalStocklineRecords') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPOriginalStocklineRecords
	END

	CREATE TABLE #TEMPOriginalStocklineRecords(        
		ID BIGINT IDENTITY(1,1),        
		TotalRecordsCount INT NULL,
		PN VARCHAR(50) NULL,
		PN_Description VARCHAR(MAX) NULL,
		Serial_Num VARCHAR(30) NULL,
		SL_Num VARCHAR(50) NULL,
		ControlNumber VARCHAR(50) NULL,
		Cond VARCHAR(100) NULL,
		Item_Group VARCHAR(256) NULL,
		Is_Customer_Stock BIT NULL,
		UOM VARCHAR(100) NULL,
		Item_Type VARCHAR(100) NULL,
		stocktype VARCHAR(50) NULL,
		Vendor_Name VARCHAR(100) NULL,
		Qty INT NULL,
		QTY_on_Hand INT NULL,
		Qty_Reserved INT NULL,
		Qty_Available INT NULL,
		Qty_Adjusted INT NULL,
		PO_UnitCost decimal(18, 2) NULL,
		POExtCost decimal(18, 2) NULL,
		ROExtCost decimal(18, 2) NULL,
		ObtainedFrom VARCHAR(50) NULL,
		[Owner] VARCHAR(50) NULL,
		Traceableto VARCHAR(50) NULL,
		Mfg VARCHAR(50) NULL,
		UnitCost decimal(18, 2) NULL,
		UnitPrice decimal(18, 2) NULL,
		ExtPrice decimal(18, 2) NULL,
		CostAdjustment decimal(18, 2) NULL,
		ExtCostAdjustment decimal(18, 2) NULL,
		level1 VARCHAR(500) NULL,
		level2 VARCHAR(500) NULL,
		level3 VARCHAR(500) NULL,
		level4 VARCHAR(500) NULL,
		level5 VARCHAR(500) NULL,
		level6 VARCHAR(500) NULL,
		level7 VARCHAR(500) NULL,
		level8 VARCHAR(500) NULL,
		level9 VARCHAR(500) NULL,
		level10 VARCHAR(500) NULL,
		[site] VARCHAR(100) NULL,
		Warehouse VARCHAR(100) NULL,
		[Location] VARCHAR(100) NULL,
		Shelf VARCHAR(100) NULL,
		Bin VARCHAR(100) NULL,
		GlAccount VARCHAR(100) NULL,
		PO_Num VARCHAR(100) NULL,
		RO_Num VARCHAR(100) NULL,
		WO_Num VARCHAR(100) NULL,
		SWO_Num VARCHAR(100) NULL,
		RO_Cost decimal(18, 2) NULL,
		Inventory_Cost decimal(18, 2) NULL,
		PORcvdDate VARCHAR(50) NULL,
		RORcvdDate VARCHAR(50) NULL,
		POReceiverNum VARCHAR(100) NULL,
		ROReceiverNum VARCHAR(100) NULL,
		MasterCompanyId INT NULL,
		StockLineId BIGINT NULL,
		IsCustomerStock BIT NULL,
		CustomerId BIGINT NULL,
		CustomerName VARCHAR(100),
		ReceiverNum VARCHAR(100)
	) 

	INSERT INTO #TEMPOriginalStocklineRecords (TotalRecordsCount, PN, PN_Description, Serial_Num, SL_Num, ControlNumber, Cond, Item_Group, Is_Customer_Stock, UOM, Item_Type, stocktype,
	Vendor_Name, Qty, QTY_on_Hand, Qty_Reserved, Qty_Available, Qty_Adjusted, PO_UnitCost, POExtCost, ROExtCost, ObtainedFrom, [Owner], Traceableto, Mfg, UnitCost, UnitPrice, ExtPrice,
	CostAdjustment, ExtCostAdjustment, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, [Site], Warehouse, [Location], Shelf, Bin, GlAccount, 
	PO_Num, RO_Num, WO_Num, SWO_Num, RO_Cost, Inventory_Cost, PORcvdDate, RORcvdDate, POReceiverNum, ROReceiverNum, MasterCompanyId, StockLineId, IsCustomerStock, CustomerId, CustomerName, ReceiverNum)
	SELECT DISTINCT COUNT(1) OVER () AS TotalRecordsCount,    
        UPPER(im.partnumber) AS 'PN',    
        UPPER(im.PartDescription) AS 'PN_Description',    
        UPPER(stl.SerialNumber) 'Serial_Num',    
        UPPER(stl.stocklineNumber) 'SL_Num',    
        UPPER(stl.ControlNumber) 'ControlNumber',    
        UPPER(stl.condition) 'Cond',    
        UPPER(stl.itemgroup) 'Item_Group',   
		UPPER(stl.IsCustomerStock) 'Is_Customer_Stock',  
        UPPER(stl.unitofmeasure) 'UOM',    
        UPPER(stl.itemtype) 'Item_Type',    
        CASE WHEN stl.isPma = 1 AND stl.IsDER = 1 THEN 'PMA&DER'    
			 WHEN stl.isPma = 1 AND (stl.IsDER IS NULL OR stl.IsDER = 0) THEN 'PMA'    
		   	 WHEN (stl.isPma = 0 OR stl.isPma IS NULL) AND stl.IsDER = 1 THEN 'DER'    
			 ELSE 'OEM' END AS stocktype,    
        UPPER(VNDR.VendorName) 'Vendor_Name',    
        stl.Quantity 'Qty',    
        stl.QuantityOnHand 'QTY_on_Hand',    
        stl.QuantityReserved 'Qty_Reserved',    
        UPPER(stl.QuantityAvailable) 'Qty_Available',    
        (SELECT SUM(CAST(stladj.ChangedTo AS INT) - CAST(stladj.ChangedFrom AS INT)) FROM DBO.StocklineAdjustment stladj WITH (NOLOCK) LEFT JOIN DBO.StocklineAdjustmentDataType stladjtype WITH (NOLOCK) ON stladj.StocklineAdjustmentDataTypeId = stladjtype.StocklineAdjustmentDataTypeId
		WHERE stladj.StocklineAdjustmentDataTypeId IN (10, 15) AND
		stladj.StocklineId = stl.StockLineId) AS 'Qty_Adjusted',
		ISNULL(stl.purchaseorderUnitCost , 0) 'PO_UnitCost',    
		ISNULL(ISNULL(stl.purchaseorderUnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) 'POExtCost',
		ISNULL(ISNULL(stl.RepairOrderUnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) 'ROExtCost',
		UPPER(stl.Obtainfromname) 'ObtainedFrom',    
        UPPER(stl.OwnerName) 'Owner',    
        UPPER(stl.TraceableToname) 'Traceableto',    
        UPPER(stl.manufacturer) 'Mfg',    
		ISNULL(stl.UnitCost , 0) 'UnitCost',    
		ISNULL(stl.UnitSalesPrice , 0) 'UnitPrice',    
		ISNULL(ISNULL(stl.UnitSalesPrice,0) * ISNULL(stl.QuantityOnHand,0) , 0) 'ExtPrice', 
		ISNULL(stl.Adjustment, 0) 'CostAdjustment', 
		ISNULL(ISNULL(stl.Adjustment,0) * ISNULL(stl.QuantityOnHand,0) , 0) 'ExtCostAdjustment', 
        UPPER(MSD.Level1Name) AS level1,     UPPER(MSD.Level2Name) AS level2,    UPPER(MSD.Level3Name) AS level3,    UPPER(MSD.Level4Name) AS level4,    UPPER(MSD.Level5Name) AS level5,    UPPER(MSD.Level6Name) AS level6,    UPPER(MSD.Level7Name) AS level7,    UPPER(MSD.Level8Name) AS level8,    UPPER(MSD.Level9Name) AS level9,    UPPER(MSD.Level10Name) AS level10,
        UPPER(stl.site) 'Site',
        UPPER(stl.warehouse) 'Warehouse',    
        UPPER(stl.location) 'Location',    
        UPPER(stl.shelf) 'Shelf',    
        UPPER(stl.bin) 'Bin',    
        UPPER(stl.glAccountname) 'GlAccount',    
        UPPER(pox.PurchaseOrderNumber) 'PO_Num',    
        UPPER(rox.RepairOrderNumber) 'RO_Num',    
        UPPER(wox.WorkOrderNum) 'WO_Num',    
        UPPER(swox.SubWorkOrderNo) 'SWO_Num',    
		ISNULL(stl.RepairOrderUnitCost ,0) 'RO_Cost',    
		(ISNULL(ISNULL(stl.purchaseorderUnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) + ISNULL(ISNULL(stl.RepairOrderUnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) + ISNULL(ISNULL(stl.Adjustment,0) * ISNULL(stl.QuantityOnHand,0) , 0)) 'Inventory_Cost',
		CASE WHEN ISNULL(stl.PurchaseOrderId, 0) > 0 THEN convert(VARCHAR(50), STL.receiveddate, 107) ELSE '' END 'PORcvdDate',
		CASE WHEN ISNULL(stl.RepairOrderId, 0) > 0 THEN convert(VARCHAR(50), STL.receiveddate, 107) ELSE '' END 'RORcvdDate',
        CASE WHEN ISNULL(stl.PurchaseOrderId, 0) > 0 THEN UPPER(stl.ReceiverNumber) ELSE '' END 'POReceiverNum',
        CASE WHEN ISNULL(stl.RepairOrderId, 0) > 0 THEN UPPER(stl.ReceiverNumber) ELSE '' END 'ROReceiverNum',
		stl.MasterCompanyId,
		stl.StockLineId,
		stl.IsCustomerStock AS IsCustomerStock,
		stl.CustomerId,
		CUST.[Name] AS CustomerName,
		stl.ReceiverNumber AS ReceiverNum
     FROM DBO.stockline stl WITH (NOLOCK)    
     INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId   
	 INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	 LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID    
	 LEFT JOIN DBO.PurchaseOrder pox WITH (NOLOCK) ON stl.PurchaseOrderId = pox.PurchaseOrderId    
	 LEFT JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK) ON stl.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId    
	 LEFT JOIN DBO.RepairOrder rox WITH (NOLOCK) ON stl.RepairOrderId = rox.repairorderid    
	 LEFT JOIN DBO.WorkOrder wox WITH (NOLOCK) ON stl.WorkOrderId = wox.WorkOrderId
	 LEFT JOIN DBO.SubWorkOrder swox WITH (NOLOCK) ON stl.SubWorkOrderId = swox.SubWorkOrderId
	 LEFT JOIN DBO.vendor VNDR WITH (NOLOCK) ON stl.VendorId = VNDR.VendorId    
	 LEFT JOIN DBO.Customer CUST WITH (NOLOCK) ON CUST.CustomerId = stl.CustomerId
     WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 AND CAST(stl.CreatedDate AS DATE) <= CAST(GETUTCDATE() AS DATE)
	 AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	 AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2,''), ',')))
	 AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	 AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	 AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	 AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	 AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	 AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	 AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	 AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	 AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	 AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

	/* Reduce Received Items from AsOfNow till Today */
	IF OBJECT_ID(N'tempdb..#TEMPStocklineReceivedDate') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPStocklineReceivedDate
	END

	CREATE TABLE #TEMPStocklineReceivedDate (        
		ID BIGINT IDENTITY(1,1),        
		StocklineId BIGINT NULL,
		Qty INT NULL,
		QTY_OH INT NULL,
		MasterCompanyId INT NULL
	)

	INSERT INTO #TEMPStocklineReceivedDate (StocklineId, Qty, QTY_OH, MasterCompanyId)
	SELECT stl.StockLineId AS StocklineId,    
        (stl.Quantity) 'Qty',    
        (stl.QuantityOnHand) 'QTY_OH',    
        stl.MasterCompanyId
      FROM DBO.stockline stl WITH (NOLOCK)    
     INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	 LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID  
     WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	 AND (CAST(stl.ReceivedDate AS DATE) > CAST(@id AS DATE) AND CAST(stl.ReceivedDate AS DATE) <= CAST(GETUTCDATE() AS DATE))
	 AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	 AND (ISNULL(@id2,'') = '' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	 AND  (ISNULL(@level1,'') = '' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	 AND  (ISNULL(@level2,'') = '' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	 AND  (ISNULL(@level3,'') = '' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	 AND  (ISNULL(@level4,'') = '' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	 AND  (ISNULL(@level5,'') = '' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	 AND  (ISNULL(@level6,'') = '' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	 AND  (ISNULL(@level7,'') = '' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	 AND  (ISNULL(@level8,'') = '' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	 AND  (ISNULL(@level9,'') = '' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	 AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

	 UPDATE StkOriginal
	 SET StkOriginal.QTY_on_Hand = StkOriginal.QTY_on_Hand - StkReceived.Qty,
	 StkOriginal.Qty_Available = StkOriginal.Qty_Available - StkReceived.QTY_OH
	 FROM #TEMPOriginalStocklineRecords StkOriginal
	 INNER JOIN #TEMPStocklineReceivedDate StkReceived ON StkOriginal.StockLineId = StkReceived.StocklineId

	/* Add Sold Items from AsOfNow till Today */
	IF OBJECT_ID(N'tempdb..#TEMPStocklineSoldDate') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPStocklineSoldDate
	END

	CREATE TABLE #TEMPStocklineSoldDate (        
		ID BIGINT IDENTITY(1,1),        
		StocklineId BIGINT NULL,
		QTY_OH INT NULL,
		MasterCompanyId INT NULL
	)

	INSERT INTO #TEMPStocklineSoldDate (StocklineId, QTY_OH, MasterCompanyId)
	SELECT SOP.StockLineId AS StocklineId,    
        (SOSD.QtyShipped) 'QTY_OH',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.SalesOrderPart SOP WITH (NOLOCK) ON SOP.StockLineId = stl.StockLineId    
	INNER JOIN dbo.SOPickTicket SOPick WITH (NOLOCK) ON SOPick.SalesOrderPartId = SOP.SalesOrderPartId
	INNER JOIN dbo.SalesOrderShippingItem SOSD WITH (NOLOCK) ON SOSD.SOPickTicketId = SOPick.SOPickTicketId
	INNER JOIN dbo.SalesOrderShipping SOS WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSD.SalesOrderShippingId
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND (CAST(SOS.ShipDate AS DATE) > CAST(@id AS DATE) AND CAST(SOS.ShipDate AS DATE) <= CAST(GETUTCDATE() AS DATE))
	AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

	INSERT INTO #TEMPStocklineSoldDate (StocklineId, QTY_OH, MasterCompanyId)
	SELECT ESOP.StockLineId AS StocklineId,    
        (ESOSD.QtyShipped) 'QTY_OH',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.ExchangeSalesOrderPart ESOP WITH (NOLOCK) ON ESOP.StockLineId = stl.StockLineId    
	INNER JOIN dbo.ExchangeSOPickTicket ESOPick WITH (NOLOCK) ON ESOPick.ExchangeSalesOrderPartId = ESOP.ExchangeSalesOrderPartId
	INNER JOIN dbo.ExchangeSalesOrderShippingItem ESOSD WITH (NOLOCK) ON ESOSD.SOPickTicketId = ESOPick.SOPickTicketId
	INNER JOIN dbo.ExchangeSalesOrderShipping ESOS WITH (NOLOCK) ON ESOS.ExchangeSalesOrderShippingId = ESOSD.ExchangeSalesOrderShippingId
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND (CAST(ESOS.ShipDate AS DATE) > CAST(@id AS DATE) AND CAST(ESOS.ShipDate AS DATE) <= CAST(GETUTCDATE() AS DATE))
	AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

	 UPDATE StkOriginal
	 SET StkOriginal.QTY_on_Hand = StkOriginal.QTY_on_Hand + StkSold.QTY_OH,
	 StkOriginal.Qty_Available = StkOriginal.Qty_Available + StkSold.QTY_OH
	 FROM #TEMPOriginalStocklineRecords StkOriginal
	 INNER JOIN #TEMPStocklineSoldDate StkSold ON StkOriginal.StockLineId = StkSold.StocklineId

	/* Add (Moved to WIP) from AsOfNow till Today */
	IF OBJECT_ID(N'tempdb..#TEMPStocklineConsumed') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPStocklineConsumed
	END

	CREATE TABLE #TEMPStocklineConsumed (        
		ID BIGINT IDENTITY(1,1),        
		StocklineId BIGINT NULL,
		QTY_OH INT NULL,
		MasterCompanyId INT NULL
	)

	INSERT INTO #TEMPStocklineConsumed (StocklineId, QTY_OH, MasterCompanyId)
	SELECT StkHistory.StockLineId AS StocklineId,    
        SUM(StkHistory.QtyOnAction) 'QTY_OH',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.Stkline_History StkHistory WITH (NOLOCK) ON StkHistory.StockLineId = stl.StockLineId AND StkHistory.ActionId = 4  -- Issued
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND (CAST(StkHistory.UpdatedDate AS DATE) > CAST(@id AS DATE) AND CAST(StkHistory.UpdatedDate AS DATE) <= CAST(GETUTCDATE() AS DATE))
	AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))
	GROUP BY StkHistory.StockLineId, stl.MasterCompanyId;

	-- Increase Consumed Qty
	UPDATE StkOriginal
	SET StkOriginal.QTY_on_Hand = StkOriginal.QTY_on_Hand + StkSold.QTY_OH,
	StkOriginal.Qty_Available = StkOriginal.Qty_Available + StkSold.QTY_OH
	FROM #TEMPOriginalStocklineRecords StkOriginal
	INNER JOIN #TEMPStocklineConsumed StkSold ON StkOriginal.StockLineId = StkSold.StocklineId

	IF OBJECT_ID(N'tempdb..#TEMPStocklineUnIssued') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPStocklineUnIssued
	END

	CREATE TABLE #TEMPStocklineUnIssued (        
		ID BIGINT IDENTITY(1,1),        
		StocklineId BIGINT NULL,
		QTY_OH INT NULL,
		MasterCompanyId INT NULL
	)

	INSERT INTO #TEMPStocklineUnIssued (StocklineId, QTY_OH, MasterCompanyId)
	SELECT StkHistory.StockLineId AS StocklineId,    
        SUM(StkHistory.QtyOnAction) 'QTY_OH',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.Stkline_History StkHistory WITH (NOLOCK) ON StkHistory.StockLineId = stl.StockLineId AND StkHistory.ActionId = 5 -- Un-Issued
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND (CAST(StkHistory.UpdatedDate AS DATE) > CAST(@id AS DATE) AND CAST(StkHistory.UpdatedDate AS DATE) <= CAST(GETUTCDATE() AS DATE))
	AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))
	GROUP BY StkHistory.StockLineId, stl.MasterCompanyId;

	-- Remove Un-Issued Qty
	UPDATE StkOriginal
	SET StkOriginal.QTY_on_Hand = StkOriginal.QTY_on_Hand - StkUnIssued.QTY_OH,
	StkOriginal.Qty_Available = StkOriginal.Qty_Available - StkUnIssued.QTY_OH
	FROM #TEMPOriginalStocklineRecords StkOriginal
	INNER JOIN #TEMPStocklineUnIssued StkUnIssued ON StkOriginal.StockLineId = StkUnIssued.StocklineId

	/* Add (Qty Adjusted - Decreased) from AsOfNow till Today */
	IF OBJECT_ID(N'tempdb..#TEMPStocklineQtyAdjusted_Reduced') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPStocklineQtyAdjusted_Reduced
	END

	CREATE TABLE #TEMPStocklineQtyAdjusted_Reduced (        
		ID BIGINT IDENTITY(1,1),        
		StocklineId BIGINT NULL,
		QTY_OH INT NULL,
		MasterCompanyId INT NULL
	)

	INSERT INTO #TEMPStocklineQtyAdjusted_Reduced (StocklineId, QTY_OH, MasterCompanyId)
	SELECT StkAdjust.StockLineId AS StocklineId,    
        (ISNULL(ISNULL(CAST(StkAdjust.ChangedFrom AS INT), 0) - ISNULL(CAST(StkAdjust.ChangedTo AS INT), 0), 0)) 'QTY_OH',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.StocklineAdjustment StkAdjust WITH (NOLOCK) ON StkAdjust.StockLineId = stl.StockLineId AND StkAdjust.StocklineAdjustmentDataTypeId = 15
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND (CAST(StkAdjust.CreatedDate AS DATE) > CAST(@id AS DATE) AND CAST(StkAdjust.CreatedDate AS DATE) <= CAST(GETUTCDATE() AS DATE))
	AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

	INSERT INTO #TEMPStocklineQtyAdjusted_Reduced (StocklineId, QTY_OH, MasterCompanyId)
	SELECT StkAdjust.StockLineId AS StocklineId,    
        (ISNULL(ISNULL(CAST(StkAdjust.Qty AS INT), 0) - ISNULL(CAST(StkAdjust.NewQty AS INT), 0), 0)) 'QTY_OH',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.BulkStockLineAdjustmentDetails StkAdjust WITH (NOLOCK) ON StkAdjust.StockLineId = stl.StockLineId AND StkAdjust.StockLineAdjustmentTypeId = 1
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND (CAST(StkAdjust.CreatedDate AS DATE) > CAST(@id AS DATE) AND CAST(StkAdjust.CreatedDate AS DATE) <= CAST(GETUTCDATE() AS DATE))
	AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

	-- Increase Adjusted Qty (Decreased Qty)
	UPDATE StkOriginal
	SET StkOriginal.QTY_on_Hand = StkOriginal.QTY_on_Hand + StkSold.QTY_OH,
	StkOriginal.Qty_Available = StkOriginal.Qty_Available + StkSold.QTY_OH
	FROM #TEMPOriginalStocklineRecords StkOriginal
	INNER JOIN #TEMPStocklineQtyAdjusted_Reduced StkSold ON StkOriginal.StockLineId = StkSold.StocklineId

	/* Add (Qty Adjusted - Increased) from AsOfNow till Today */
	IF OBJECT_ID(N'tempdb..#TEMPStocklineQtyAdjusted_Increased') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPStocklineQtyAdjusted_Increased
	END

	CREATE TABLE #TEMPStocklineQtyAdjusted_Increased (        
		ID BIGINT IDENTITY(1,1),        
		StocklineId BIGINT NULL,
		QTY_OH INT NULL,
		MasterCompanyId INT NULL
	)

	INSERT INTO #TEMPStocklineQtyAdjusted_Increased (StocklineId, QTY_OH, MasterCompanyId)
	SELECT StkAdjust.StockLineId AS StocklineId,    
        (ISNULL(ISNULL(CAST(StkAdjust.ChangedTo AS INT), 0) - ISNULL(CAST(StkAdjust.ChangedFrom AS INT), 0), 0)) 'QTY_OH',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.StocklineAdjustment StkAdjust WITH (NOLOCK) ON StkAdjust.StockLineId = stl.StockLineId AND StkAdjust.StocklineAdjustmentDataTypeId = 10
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND CAST(StkAdjust.CreatedDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(GETDATE() AS DATE)  
	AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

	INSERT INTO #TEMPStocklineQtyAdjusted_Increased (StocklineId, QTY_OH, MasterCompanyId)
	SELECT StkAdjust.StockLineId AS StocklineId,    
        (ISNULL(ISNULL(CAST(StkAdjust.NewQty AS INT), 0) - ISNULL(CAST(StkAdjust.Qty AS INT), 0), 0)) 'QTY_OH',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.BulkStockLineAdjustmentDetails StkAdjust WITH (NOLOCK) ON StkAdjust.StockLineId = stl.StockLineId AND StkAdjust.StockLineAdjustmentTypeId = 1
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND (CAST(StkAdjust.CreatedDate AS DATE) > CAST(@id AS DATE) AND CAST(StkAdjust.CreatedDate AS DATE) <= CAST(GETUTCDATE() AS DATE))
	AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

	-- Removed Adjusted Qty (Increased Qty)
	UPDATE StkOriginal
	SET StkOriginal.QTY_on_Hand = StkOriginal.QTY_on_Hand - StkSold.QTY_OH,
	StkOriginal.Qty_Available = StkOriginal.Qty_Available - StkSold.QTY_OH
	FROM #TEMPOriginalStocklineRecords StkOriginal
	INNER JOIN #TEMPStocklineQtyAdjusted_Increased StkSold ON StkOriginal.StockLineId = StkSold.StocklineId

	/* Add (Unit Cost Adjusted) from AsOfNow till Today */
	IF OBJECT_ID(N'tempdb..#TEMPStocklineUnitCostAdjusted') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPStocklineUnitCostAdjusted
	END

	CREATE TABLE #TEMPStocklineUnitCostAdjusted (        
		ID BIGINT IDENTITY(1,1),        
		StocklineId BIGINT NULL,
		UnitCost Decimal(18, 2) NULL,
		MasterCompanyId INT NULL
	)

	INSERT INTO #TEMPStocklineUnitCostAdjusted (StocklineId, UnitCost, MasterCompanyId)
	SELECT StkAdjust.StockLineId AS StocklineId,    
        (ISNULL(ISNULL(CAST(StkAdjust.ChangedFrom AS Decimal(18, 2)), 0) - ISNULL(CAST(StkAdjust.ChangedTo AS Decimal(18, 2)), 0), 0)) 'UnitCost',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.StocklineAdjustment StkAdjust WITH (NOLOCK) ON StkAdjust.StockLineId = stl.StockLineId AND StkAdjust.StocklineAdjustmentDataTypeId = 11  -- Unit Cost
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND (CAST(StkAdjust.CreatedDate AS DATE) > CAST(@id AS DATE) AND CAST(StkAdjust.CreatedDate AS DATE) <= CAST(GETUTCDATE() AS DATE))
	AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

	UPDATE StkOriginal
	SET StkOriginal.UnitCost = CASE WHEN StkSold.UnitCost > 0 THEN (StkOriginal.UnitCost - StkSold.UnitCost) ELSE (StkOriginal.UnitCost + StkSold.UnitCost) END
	FROM #TEMPOriginalStocklineRecords StkOriginal
	INNER JOIN #TEMPStocklineUnitCostAdjusted StkSold ON StkOriginal.StockLineId = StkSold.StocklineId

	/* Add (Unit Price Adjusted) from AsOfNow till Today */
	IF OBJECT_ID(N'tempdb..#TEMPStocklineUnitPriceAdjusted') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPStocklineUnitPriceAdjusted
	END

	CREATE TABLE #TEMPStocklineUnitPriceAdjusted (        
		ID BIGINT IDENTITY(1,1),        
		StocklineId BIGINT NULL,
		UnitPrice Decimal(18, 2) NULL,
		MasterCompanyId INT NULL
	)

	INSERT INTO #TEMPStocklineUnitPriceAdjusted (StocklineId, UnitPrice, MasterCompanyId)
	SELECT StkAdjust.StockLineId AS StocklineId,    
        (ISNULL(ISNULL(CAST(StkAdjust.ChangedFrom AS Decimal(18, 2)), 0) - ISNULL(CAST(StkAdjust.ChangedTo AS Decimal(18, 2)), 0), 0)) 'UnitPrice',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.StocklineAdjustment StkAdjust WITH (NOLOCK) ON StkAdjust.StockLineId = stl.StockLineId AND StkAdjust.StocklineAdjustmentDataTypeId = 12  -- Unit Sales Price
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND (CAST(StkAdjust.CreatedDate AS DATE) > CAST(@id AS DATE) AND CAST(StkAdjust.CreatedDate AS DATE) <= CAST(GETUTCDATE() AS DATE))
	AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

	UPDATE StkOriginal
	SET StkOriginal.UnitPrice = CASE WHEN StkSold.UnitPrice > 0 THEN (StkOriginal.UnitCost - StkSold.UnitPrice) ELSE (StkOriginal.UnitCost + StkSold.UnitPrice) END
	FROM #TEMPOriginalStocklineRecords StkOriginal
	INNER JOIN #TEMPStocklineUnitPriceAdjusted StkSold ON StkOriginal.StockLineId = StkSold.StocklineId

	/* Add (Unit Cost Adjusted - Bulk Adjustment) from AsOfNow till Today */
	IF OBJECT_ID(N'tempdb..#TEMPStocklineUnitCostAdjustedBulk') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPStocklineUnitCostAdjustedBulk
	END

	CREATE TABLE #TEMPStocklineUnitCostAdjustedBulk (        
		ID BIGINT IDENTITY(1,1),        
		StocklineId BIGINT NULL,
		UnitCost Decimal(18, 2) NULL,
		MasterCompanyId INT NULL
	)

	INSERT INTO #TEMPStocklineUnitCostAdjustedBulk (StocklineId, UnitCost, MasterCompanyId)
	SELECT BStkAdjustD.StockLineId AS StocklineId,    
        SUM(ISNULL(BStkAdjustD.UnitCostAdjustment, 0)) 'UnitCost',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	LEFT JOIN dbo.BulkStockLineAdjustmentDetails BStkAdjustD WITH (NOLOCK) ON BStkAdjustD.StockLineId = stl.StockLineId
	LEFT JOIN dbo.BulkStockLineAdjustment BStkAdjust WITH (NOLOCK) ON BStkAdjust.BulkStkLineAdjId = BStkAdjustD.BulkStkLineAdjId AND BStkAdjust.StatusId = 7
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND (CAST(BStkAdjust.UpdatedDate AS DATE) > CAST(@id AS DATE) AND CAST(BStkAdjust.UpdatedDate AS DATE) <= CAST(GETUTCDATE() AS DATE))
	AND stl.IsCustomerStock = CASE WHEN @id3 = 1 THEN 0 ELSE stl.IsCustomerStock END 
	AND (ISNULL(@id2,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2, ''), ',')))
	AND  (ISNULL(@level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
	AND  (ISNULL(@level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
	AND  (ISNULL(@level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
	AND  (ISNULL(@level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
	AND  (ISNULL(@level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
	AND  (ISNULL(@level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
	AND  (ISNULL(@level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
	AND  (ISNULL(@level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
	AND  (ISNULL(@level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
	AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))
	GROUP BY BStkAdjustD.StockLineId, stl.MasterCompanyId;

	UPDATE StkOriginal
	SET StkOriginal.UnitCost = CASE WHEN StkSold.UnitCost > 0 THEN (StkOriginal.UnitCost - StkSold.UnitCost) ELSE (StkOriginal.UnitCost + StkSold.UnitCost) END,
	StkOriginal.CostAdjustment = CASE WHEN StkSold.UnitCost > 0 THEN (StkOriginal.CostAdjustment - StkSold.UnitCost) ELSE (StkOriginal.CostAdjustment + StkSold.UnitCost) END
	FROM #TEMPOriginalStocklineRecords StkOriginal
	INNER JOIN #TEMPStocklineUnitCostAdjustedBulk StkSold ON StkOriginal.StockLineId = StkSold.StocklineId

	/* Final Result Set */
	SELECT DISTINCT TotalRecordsCount,    
        PN,
        PN_Description,
        Serial_Num,
        SL_Num,
        ControlNumber,
        Cond,
        Item_Group,
		Is_Customer_Stock,
        UOM,
        Item_Type,
        stocktype,
		Vendor_Name,    
        QTY_on_Hand,
        Qty_Reserved,
        Qty_Available,
        Qty_Adjusted,
		PO_UnitCost,
		(ISNULL(ISNULL(stl.PO_UnitCost,0) * ISNULL(stl.QTY_on_Hand, 0) , 0)) AS 'POExtCost',
		ISNULL(ISNULL(stl.RO_Cost,0) * ISNULL(stl.QTY_on_Hand,0) , 0) 'ROExtCost',
		ObtainedFrom,
        [Owner],
        Traceableto,
        Mfg,
		UnitCost,
		ISNULL(ISNULL(stl.UnitCost,0) * ISNULL(stl.QTY_on_Hand,0) , 0) 'ExtUnitCost',
		UnitPrice,
		ISNULL(ISNULL(stl.UnitPrice,0) * ISNULL(stl.QTY_on_Hand,0) , 0) 'ExtPrice', 
		CostAdjustment,
		ISNULL(ISNULL(stl.CostAdjustment,0) * ISNULL(stl.QTY_on_Hand,0) , 0) 'ExtCostAdjustment', 
        level1, 
		level2,
		level3,
		level4,
		level5,
		level6,
		level7,
		level8,
		level9,
		level10,
        Site,
        Warehouse,    
        Location,    
        Shelf,    
        Bin,    
        GlAccount,    
        PO_Num,
        RO_Num,
        WO_Num,
        SWO_Num,
		RO_Cost,
		ISNULL(stl.UnitCost, 0) * ISNULL(stl.QTY_on_Hand, 0) AS Inventory_Cost,
		PORcvdDate,
		RORcvdDate,
        POReceiverNum,
		ROReceiverNum,
		stl.MasterCompanyId,
		stl.StockLineId,
		stl.IsCustomerStock,
		stl.CustomerId,
		CustomerName,
		stl.ReceiverNum
		FROM #TEMPOriginalStocklineRecords stl WHERE QTY_on_Hand > 0
		ORDER BY PN;
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
    BEGIN
      DROP TABLE #managmetnstrcture
    END

    DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME(),
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        @AdhocComments varchar(150) = '[usprpt_GetStockReportAsOfNow]',
        @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
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