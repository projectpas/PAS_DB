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
     
exec usprpt_GetStockReportAsOfNow @mastercompanyid=1,@id=N'1/16/2024',@id2=N'1,2,3',@id3=1,@strFilter=N'1,5,6,52!2,7,8,9!3,11,10!4,12,13!!!!!!'
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
		Alt_Equiv VARCHAR(250) NULL,
		Vendor_Name VARCHAR(100) NULL,
		Vendor_Code VARCHAR(100) NULL,
		QTY_on_Hand INT NULL,
		Qty_Reserved INT NULL,
		Qty_Available INT NULL,
		qtyscrapped INT NULL,
		Qty_Adjusted INT NULL,
		PO_UnitCost decimal(18, 2) NULL,
		ExtCost decimal(18, 2) NULL,
		POExtCost decimal(18, 2) NULL,
		ROExtCost decimal(18, 2) NULL,
		ObtainedFrom VARCHAR(50) NULL,
		[Owner] VARCHAR(50) NULL,
		Traceableto VARCHAR(50) NULL,
		Mfg VARCHAR(50) NULL,
		UnitCost decimal(18, 2) NULL,
		ExtUnitCost decimal(18, 2) NULL,
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
		RO_Cost decimal(18, 2) NULL,
		Total_Cost decimal(18, 2) NULL,
		Inventory_Cost decimal(18, 2) NULL,
		RcvdDate DATETIME2(7) NULL,
		ReceiverNum VARCHAR(100) NULL,
		ReceiverRecon VARCHAR(100) NULL,
		POQty INT NULL,
		MasterCompanyId INT NULL,
		StockLineId BIGINT NULL
	) 

	INSERT INTO #TEMPOriginalStocklineRecords (TotalRecordsCount, PN, PN_Description, Serial_Num, SL_Num, ControlNumber, Cond, Item_Group, Is_Customer_Stock, UOM, Item_Type, stocktype, Alt_Equiv,
	Vendor_Name, Vendor_Code, QTY_on_Hand, Qty_Reserved, Qty_Available, qtyscrapped, Qty_Adjusted, PO_UnitCost, ExtCost, POExtCost, ROExtCost, ObtainedFrom, [Owner], Traceableto, Mfg, UnitCost, ExtUnitCost, UnitPrice, ExtPrice,
	CostAdjustment, ExtCostAdjustment, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, [Site], Warehouse, [Location], Shelf, Bin, GlAccount, PO_Num, RO_Num, RO_Cost, 
	Total_Cost, Inventory_Cost, RcvdDate, ReceiverNum, ReceiverRecon, POQty, MasterCompanyId, StockLineId)
	SELECT COUNT(1) OVER () AS TotalRecordsCount,    
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
        UPPER(POP.altequipartnumber) 'Alt_Equiv',    
        UPPER(VNDR.VendorName) 'Vendor_Name',    
        UPPER(VNDR.VendorCode) 'Vendor_Code',    
        stl.QuantityOnHand 'QTY_on_Hand',    
        stl.QuantityReserved 'Qty_Reserved',    
        UPPER(stl.QuantityAvailable) 'Qty_Available',    
        0 'qtyscrapped',    
        CASE WHEN stladjtype.StocklineAdjustmentDataTypeId = 10 THEN STl.QuantityOnHand - stladj.ChangedTo ELSE 0 END AS 'Qty_Adjusted',
		ISNULL(stl.purchaseorderUnitCost , 0) 'PO_UnitCost',    
		ISNULL(stl.PurchaseOrderExtendedCost , 0) 'ExtCost',    
		ISNULL(ISNULL(stl.purchaseorderUnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) 'POExtCost',
		ISNULL(ISNULL(stl.RepairOrderUnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) 'ROExtCost',
		UPPER(stl.Obtainfromname) 'ObtainedFrom',    
        UPPER(stl.OwnerName) 'Owner',    
        UPPER(stl.TraceableToname) 'Traceableto',    
        UPPER(stl.manufacturer) 'Mfg',    
		ISNULL(stl.UnitCost , 0) 'UnitCost',    
		ISNULL(ISNULL(stl.UnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) 'ExtUnitCost', 
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
		ISNULL(stl.RepairOrderUnitCost ,0) 'RO_Cost',    
		(ISNULL(stl.PurchaseOrderExtendedCost ,0) + ISNULL(stl.RepairOrderUnitCost ,0) + ISNULL(stl.Adjustment ,0)) 'Total_Cost',
		(ISNULL(ISNULL(stl.purchaseorderUnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) + ISNULL(ISNULL(stl.RepairOrderUnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) + ISNULL(ISNULL(stl.Adjustment,0) * ISNULL(stl.QuantityOnHand,0) , 0)) 'Inventory_Cost',
		convert(VARCHAR(50), STL.receiveddate, 107) 'RcvdDate',
        UPPER(stl.ReceiverNumber) 'ReceiverNum',    
        UPPER(stl.ReconciliationNumber) 'ReceiverRecon',
		UPPER(ISNULL(stl.Quantity,0)) 'POQty',
		stl.MasterCompanyId,
		stl.StockLineId
      FROM DBO.stockline stl WITH (NOLOCK)    
     INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	 LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID    
	 LEFT OUTER JOIN DBO.ItemMaster im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId    
	 LEFT OUTER JOIN DBO.PurchaseOrder pox WITH (NOLOCK) ON stl.PurchaseOrderId = pox.PurchaseOrderId    
	 LEFT OUTER JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK) ON stl.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId    
	 LEFT OUTER JOIN DBO.RepairOrder rox WITH (NOLOCK) ON stl.RepairOrderId = rox.repairorderid    
	 LEFT JOIN DBO.vendor VNDR WITH (NOLOCK) ON stl.VendorId = VNDR.VendorId    
	 LEFT JOIN DBO.StocklineAdjustment stladj WITH (NOLOCK) ON stl.StockLineId = stladj.StocklineId    
	 LEFT JOIN DBO.StocklineAdjustmentDataType stladjtype WITH (NOLOCK) ON stladj.StocklineAdjustmentDataTypeId = stladjtype.StocklineAdjustmentDataTypeId    
     WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 and CAST(stl.CreatedDate AS DATE) <= CAST(GETUTCDATE() AS DATE)  --CAST(@id AS DATE)  
	 --AND stl.QuantityOnHand > 0
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
		QTY_OH INT NULL,
		MasterCompanyId INT NULL
	)

	INSERT INTO #TEMPStocklineReceivedDate (StocklineId, QTY_OH, MasterCompanyId)
	SELECT stl.StockLineId AS StocklineId,    
        (stl.QuantityOnHand) 'QTY_OH',    
        stl.MasterCompanyId
      FROM DBO.stockline stl WITH (NOLOCK)    
     INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	 LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID  
     WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	 AND CAST(stl.ReceivedDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(GETUTCDATE() AS DATE)  
	 AND stl.QuantityOnHand > 0
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
	 SET StkOriginal.QTY_on_Hand = StkOriginal.QTY_on_Hand - StkReceived.QTY_OH
	 FROM #TEMPOriginalStocklineRecords StkOriginal
	 INNER JOIN #TEMPStocklineReceivedDate StkReceived ON StkOriginal.StockLineId = StkReceived.StocklineId

	 --SELECT * FROM #TEMPStocklineReceivedDate;

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
	AND CAST(SOS.ShipDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(GETDATE() AS DATE)  
	AND stl.QuantityOnHand > 0
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
	 SET StkOriginal.QTY_on_Hand = StkOriginal.QTY_on_Hand + StkSold.QTY_OH
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
        (StkHistory.QtyOnAction) 'QTY_OH',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.Stkline_History StkHistory WITH (NOLOCK) ON StkHistory.StockLineId = stl.StockLineId AND StkHistory.ActionId = 4
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND CAST(StkHistory.UpdatedDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(GETUTCDATE() AS DATE)  
	AND stl.QuantityOnHand > 0
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
	SET StkOriginal.QTY_on_Hand = StkOriginal.QTY_on_Hand + StkSold.QTY_OH
	FROM #TEMPOriginalStocklineRecords StkOriginal
	INNER JOIN #TEMPStocklineConsumed StkSold ON StkOriginal.StockLineId = StkSold.StocklineId

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
	AND CAST(StkAdjust.CreatedDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(GETUTCDATE() AS DATE)  
	AND stl.QuantityOnHand > 0
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
	AND CAST(StkAdjust.CreatedDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(GETUTCDATE() AS DATE)  
	AND stl.QuantityOnHand > 0
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
	SET StkOriginal.QTY_on_Hand = StkOriginal.QTY_on_Hand + StkSold.QTY_OH
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
	AND stl.QuantityOnHand > 0
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
	AND CAST(StkAdjust.CreatedDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(GETDATE() AS DATE)  
	AND stl.QuantityOnHand > 0
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
	SET StkOriginal.QTY_on_Hand = StkOriginal.QTY_on_Hand - StkSold.QTY_OH
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
        (ISNULL(ISNULL(CAST(StkAdjust.ChangedFrom AS INT), 0) - ISNULL(CAST(StkAdjust.ChangedTo AS INT), 0), 0)) 'UnitCost',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.StocklineAdjustment StkAdjust WITH (NOLOCK) ON StkAdjust.StockLineId = stl.StockLineId AND StkAdjust.StocklineAdjustmentDataTypeId = 11  -- Unit Cost
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND CAST(StkAdjust.CreatedDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(GETDATE() AS DATE)  
	AND stl.QuantityOnHand > 0
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
        (ISNULL(ISNULL(CAST(StkAdjust.ChangedFrom AS INT), 0) - ISNULL(CAST(StkAdjust.ChangedTo AS INT), 0), 0)) 'UnitPrice',    
        stl.MasterCompanyId
    FROM DBO.stockline stl WITH (NOLOCK)
	INNER JOIN dbo.StocklineAdjustment StkAdjust WITH (NOLOCK) ON StkAdjust.StockLineId = stl.StockLineId AND StkAdjust.StocklineAdjustmentDataTypeId = 12  -- Unit Sales Price
	INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId    
	LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
    WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 
	AND CAST(StkAdjust.CreatedDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(GETDATE() AS DATE)  
	AND stl.QuantityOnHand > 0
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

	/* Final Result Set */
	SELECT TotalRecordsCount,    
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
        Alt_Equiv,
		Vendor_Name,    
        Vendor_Code,
        QTY_on_Hand,
        Qty_Reserved,
        Qty_Available,
        qtyscrapped,
        Qty_Adjusted,
		PO_UnitCost,
		ExtCost,
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
		RO_Cost,
		Total_Cost,
		--(ISNULL(ISNULL(stl.PO_UnitCost, 0) * ISNULL(stl.QTY_on_Hand,0), 0) + 
		--	ISNULL(ISNULL(stl.RO_Cost, 0) * ISNULL(stl.QTY_on_Hand, 0), 0) + 
		--	ISNULL(ISNULL(stl.CostAdjustment, 0) * ISNULL(stl.QTY_on_Hand, 0), 0)) AS Inventory_Cost,
		ISNULL(stl.UnitCost, 0) * ISNULL(stl.QTY_on_Hand, 0) AS Inventory_Cost,
		RcvdDate,
        ReceiverNum,
        ReceiverRecon,
		POQty,
		stl.MasterCompanyId,
		stl.StockLineId 
		FROM #TEMPOriginalStocklineRecords stl WHERE QTY_on_Hand > 0;
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