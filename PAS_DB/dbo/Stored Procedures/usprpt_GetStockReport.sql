/*************************************************************           
 ** File:   [usprpt_GetStockReport]           
 ** Author:   Mahesh Sorathiya  
 ** Description: Get Data for Stock Report  
 ** Purpose:         
 ** Date:   26-April-2022       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
  ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    26-April-2022  Mahesh Sorathiya   Created 

     
EXECUTE   [dbo].[usprpt_GetStockReport] '2','2010-01-01','2022-04-26',null,1,10
**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetStockReport] 
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
      
	select 
   
	@Fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date' 
	then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @Fromdate end,
		@Todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date' 
	then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @Todate end,
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

      DECLARE @ModuleID INT = 2; -- MS Module ID
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END
	  	  
	   IF ISNULL(@PageSize,0)=0
		BEGIN 
		  SELECT @PageSize=COUNT(*)
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
          WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent =1 AND stl.IsDeleted=0 and  CAST(stl.CreatedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE)  AND CAST(@Todate AS DATE)
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

      SELECT COUNT(1) OVER () AS TotalRecordsCount,
        UPPER(im.partnumber) AS 'pn',
        UPPER(im.PartDescription) AS 'pndescription',
        UPPER(stl.SerialNumber) 'sernum',
        UPPER(stl.stocklineNumber) 'slnum',
        UPPER(stl.condition) 'cond',
        UPPER(stl.itemgroup) 'itemgroup',
        UPPER(stl.unitofmeasure) 'uom',
        UPPER(stl.itemtype) 'itemtype',
        CASE WHEN stl.isPma = 1 AND stl.IsDER = 1 THEN 'PMA&DER'
			 WHEN stl.isPma = 1 AND (stl.IsDER IS NULL OR stl.IsDER = 0) THEN 'PMA'
             WHEN (stl.isPma = 0 OR stl.isPma IS NULL) AND stl.IsDER = 1 THEN 'DER'
             ELSE 'OEM' END AS stocktype,
        UPPER(POP.altequipartnumber) 'Alt/Equiv',
        UPPER(VNDR.VendorName) 'vendorname',
        UPPER(VNDR.VendorCode) 'vendorcode',
        stl.QuantityOnHand 'qtyonhand',
        stl.QuantityReserved 'qtyreserved',
        UPPER(stl.QuantityAvailable) 'qtyavail',
        'NA' 'qtyscrapped',
        CASE WHEN stladjtype.StocklineAdjustmentDataTypeId = 10 THEN STl.QuantityOnHand - stladj.ChangedTo ELSE 0 END AS 'qtyadjusted',
		FORMAT(stl.purchaseorderUnitCost , 'N', 'en-us') 'pounitcost',
		FORMAT(stl.PurchaseOrderExtendedCost , 'N', 'en-us') 'extcost',
		UPPER(stl.Obtainfromname) 'obtainedfrom',
        UPPER(stl.OwnerName) 'owner',
        UPPER(stl.TraceableToname) 'traceableto',
        UPPER(stl.manufacturer) 'mfg',
		FORMAT(stl.UnitCost , 'N', 'en-us') 'unitprice',
		FORMAT(ISNULL(stl.UnitCost,0) * ISNULL(stl.QuantityOnHand,0) , 'N', 'en-us') 'extprice',
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
		FORMAT(stl.RepairOrderUnitCost , 'N', 'en-us') 'rocost',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(STL.receiveddate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), STL.receiveddate, 107) END 'rcvddate', 
        UPPER(stl.ReceiverNumber) 'receivernum',
        UPPER(stl.ReconciliationNumber) 'receiverrecon'
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
		--LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK) ON stl.MasterCompanyId = MC.MasterCompanyId
      WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent =1 AND stl.IsDeleted=0 and  CAST(stl.CreatedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE)  AND CAST(@Todate AS DATE)
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
	   ORDER BY IM.partnumber
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