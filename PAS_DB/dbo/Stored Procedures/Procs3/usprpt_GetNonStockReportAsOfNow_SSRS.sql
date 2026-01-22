/*************************************************************           
 ** File:   [usprpt_GetNonStockReportAsOfNow_SSRS]
 ** Author:   Vishal Suthar  
 ** Description: Get Data for Not Stock Report As of Now
 ** Purpose:         
 ** Date:   01-17-2024
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** SrNO	Date			Author				Change Description              
 ** --		--------		-------				--------------------------------            
    1		01-17-2024		Vishal Suthar		Created

 exec usprpt_GetNonStockReportAsOfNow_SSRS @mastercompanyid=1,@id=N'1/17/2024',@id2=N'1,2,3',@strFilter=N'1,5,6,52!2,7,8,9!3,11,10!4,12,13!!!!!!'
**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetNonStockReportAsOfNow_SSRS] 
	@mastercompanyid INT,
	@id DATETIME2,
	@id2 VARCHAR(100),
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

	DECLARE @ModuleID INT = 11; -- MS Module ID 
	
	  ;WITH rptCTE (TotalRecordsCount, pn, pndescription, sernum, nonstockinventorynumber, cond, uom, Item_Group, Item_Type, AltEquiv,
				 vendorname, vendorcode, qtyonhand,unitcost,extcost,mfg,unitprice, extprice, level1, level2, level3, level4, level5, level6, level7, level8,
			  level9, level10, site, warehouse, Location, Shelf, Bin, glaccount, ponum, ronum, rcvddate, receivernum, masterCompanyId) AS (
      SELECT COUNT(1) OVER () AS TotalRecordsCount,
        UPPER(im.partnumber) AS 'pn',
        UPPER(im.PartDescription) AS 'pndescription',
        UPPER(stl.SerialNumber) 'sernum',
        UPPER(stl.NonStockInventoryNumber) 'nonstockinventorynumber',
        UPPER(stl.condition) 'cond',
        UPPER(stl.unitofmeasure) 'uom',
		UPPER(IG.[Description]) 'Item_Group',
		UPPER('Non-Stock') AS 'Item_Type', 
        UPPER(POP.altequipartnumber) 'AltEquiv',
        UPPER(VNDR.VendorName) 'vendorname',
        UPPER(VNDR.VendorCode) 'vendorcode',
        stl.QuantityOnHand 'qtyonhand',
		ISNULL(stl.UnitCost ,0) 'unitcost', 
		--ISNULL(stl.ExtendedCost ,0) 'extcost', 
		(ISNULL(stl.UnitCost,0) * ISNULL(stl.QuantityOnHand,0)) AS 'extcost',
        UPPER(stl.manufacturer) 'mfg',
		FORMAT(stl.UnitCost , 'N', 'en-us') 'unitprice',
		FORMAT(ISNULL(stl.UnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 'N', 'en-us') 'extprice',
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
        UPPER(stl.GLAccount) 'glaccount',
        UPPER(pox.PurchaseOrderNumber) 'ponum',
        UPPER(rox.RepairOrderNumber) 'ronum',
		convert(VARCHAR(50), STL.receiveddate, 107) AS 'rcvddate', 
        UPPER(stl.ReceiverNumber) 'receivernum',
		stl.MasterCompanyId
      FROM DBO.NonStockInventory stl WITH (NOLOCK)
	    INNER JOIN dbo.NonStocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.NonStockInventoryId
		LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID
		LEFT OUTER JOIN DBO.ItemMasterNonStock im WITH (NOLOCK) ON stl.MasterPartId = im.MasterPartId
		LEFT JOIN dbo.ItemGroup IG WITH (NOLOCK) ON IM.ItemGroupId = IG.ItemGroupId
		LEFT OUTER JOIN DBO.PurchaseOrder pox WITH (NOLOCK) ON stl.PurchaseOrderId = pox.PurchaseOrderId
		LEFT OUTER JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK) ON stl.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId
		LEFT OUTER JOIN DBO.RepairOrder rox WITH (NOLOCK) ON stl.RepairOrderId = rox.repairorderid
		LEFT JOIN DBO.vendor VNDR WITH (NOLOCK) ON stl.VendorId = VNDR.VendorId
      WHERE stl.mastercompanyid = @mastercompanyid AND stl.IsParent = 1 AND stl.IsDeleted = 0 AND CAST(stl.CreatedDate AS DATE) <= CAST(@id AS DATE)
	        AND (ISNULL(@id2,'') = '' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@id2,''), ',')))
			AND (ISNULL(@Level1,'') = '' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
			AND (ISNULL(@Level2,'') = '' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
			AND (ISNULL(@Level3,'') = '' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
			AND (ISNULL(@Level4,'') = '' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
			AND (ISNULL(@Level5,'') = '' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
			AND (ISNULL(@Level6,'') = '' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
			AND (ISNULL(@Level7,'') = '' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
			AND (ISNULL(@Level8,'') = '' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
			AND (ISNULL(@Level9,'') = '' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
			AND (ISNULL(@Level10,'') = ''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))))

		SELECT * FROM rptCTE;			
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usprpt_GetNonStockReportAsOfNow]',
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
END