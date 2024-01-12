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
     
exec usprpt_GetStockReportAsOfNow @mastercompanyid=1,@id=N'1/12/2024',@id2=N'1,2,3',@id3=0,@strFilter=N'52!!!!!!!!!'
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
        'NA' 'qtyscrapped',    
        CASE WHEN stladjtype.StocklineAdjustmentDataTypeId = 10 THEN STl.QuantityOnHand - stladj.ChangedTo ELSE 0 END AS 'Qty_Adjusted',
		ISNULL(stl.purchaseorderUnitCost , 0) 'PO_UnitCost',    
		ISNULL(stl.PurchaseOrderExtendedCost , 0) 'ExtCost',    
		ISNULL(ISNULL(stl.PurchaseOrderExtendedCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) 'POExtCost',
		ISNULL(ISNULL(stl.RepairOrderUnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) 'ROExtCost',
		UPPER(stl.Obtainfromname) 'ObtainedFrom',    
        UPPER(stl.OwnerName) 'Owner',    
        UPPER(stl.TraceableToname) 'Traceableto',    
        UPPER(stl.manufacturer) 'Mfg',    
		ISNULL(stl.UnitCost , 0) 'UnitPrice',    
		ISNULL(ISNULL(stl.UnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 0) 'ExtPrice', 
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
		stl.MasterCompanyId
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
     WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent = 1 AND stl.IsDeleted = 0 and  CAST(stl.CreatedDate AS DATE) <= CAST(@id AS DATE)  
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
        @AdhocComments varchar(150) = '[usp_GetStockReport]',
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