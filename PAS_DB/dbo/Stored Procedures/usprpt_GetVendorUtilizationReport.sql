
/*************************************************************           
 ** File:   [usprpt_GetVendorUtilizationReport]           
 ** Author:   Mahesh Sorathiya  
 ** Description: Get Data for VendorUtilization Report  
 ** Purpose:         
 ** Date:   14-April-2022       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	      Change Description            
 ** --   --------       -------		      --------------------------------          
    1    15-April-2022  Mahesh Sorathiya  Created
     
EXECUTE   [dbo].[usprpt_GetVendorUtilizationReport] '','','2020-06-15','2022-06-15','2',1,10,'1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetVendorUtilizationReport]
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

   DECLARE @fromdate datetime,
	@todate datetime,
	@status varchar(50) = NULL,
	@vendorname varchar(40) = NULL,
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
    
	SELECT 
	@fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Open Start Date' 
	then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
	@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Open End Date' 
	then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,
	@status=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Status' 
	then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @status end,
	@vendorname=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Vendor Name(Optional)' 
	then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @vendorname end,
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
			SELECT @PageSize=COUNT(*) 
			FROM (SELECT IM.partnumber 
			FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
			INNER JOIN DBO.PurchaseOrder PO WITH (NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId
			INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = 4 AND MSD.ReferenceID = POP.PurchaseOrderId
			LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN DBO.Stockline STL WITH (NOLOCK)  ON POP.PurchaseOrderPartRecordId = STL.PurchaseOrderPartRecordId and stl.IsParent=1
			LEFT JOIN DBO.Workorder WO WITH (NOLOCK) ON POP.workorderid = WO.workorderid 
			--LEFT JOIN DBO.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
			LEFT JOIN DBO.Itemmaster IM WITH (NOLOCK) ON POP.itemmasterid = IM.itemmasterid
			LEFT JOIN DBO.WorkOrderMaterials WOM WITH (NOLOCK) ON POP.PurchaseOrderId = WOM.POId
			LEFT JOIN DBO.itemmaster IM1 WITH (NOLOCK) ON WOM.itemmasterid = IM1.itemmasterid
       		LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK) ON POP.salesorderid = SO.SalesOrderId
			LEFT JOIN DBO.salesorderpart SOP WITH (NOLOCK) ON POP.salesorderid = SOP.SalesOrderId AND SOP.ItemMasterId = POP.ItemMasterId  
			LEFT JOIN DBO.itemmaster IM2 WITH (NOLOCK) ON SOP.ItemMasterId = IM2.itemmasterid 
		  WHERE PO.VendorId = ISNULL(@vendorname,PO.VendorId) 
			AND CAST(PO.opendate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
			AND (PO.StatusId IN (SELECT value FROM String_split(@status, ',')) OR ISNULL(@status,'') = '') 
			AND PO.mastercompanyid = @mastercompanyid AND 
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
		   GROUP BY 
			   PO.PurchaseOrderNumber, FORMAT (PO.OpenDate, 'MM/dd/yyyy hh:mm:tt'), IM.partnumber,IM.PartDescription,STL.itemtype,
				CASE WHEN stl.isPma = 1 AND stl.IsDER = 1 THEN 'PMA&DER' WHEN stl.isPma = 1 AND (stl.IsDER IS NULL OR stl.IsDER = 0) THEN 'PMA'
					 WHEN (stl.isPma = 0 OR stl.isPma IS NULL) AND stl.IsDER = 1 THEN 'DER' ELSE 'OEM' END,
			   PO.status,PO.VendorName,PO.VendorCode,POP.unitofmeasure, POP.QuantityOrdered, POP.PurchaseOrderId, STL.UnitCost ,POP.functionalcurrency, FORMAT (POP.NeedByDate, 'MM/dd/yyyy hh:mm:tt'),
			   STL.PurchaseOrderExtendedCost,POP.workorderno,IM1.partnumber,IM1.partdescription,POP.salesorderno,IM2.partnumber,IM2.partnumber,IM2.partdescription,WO.CustomerName,
			   MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name
			) TEMP
		END

	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

     SELECT  COUNT(1) OVER () AS TotalRecordsCount, 
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
        UPPER(PO.PurchaseOrderNumber) 'ponum',
        FORMAT (PO.OpenDate, 'MM/dd/yyyy hh:mm:tt') 'podate',
        UPPER(IM.partnumber) 'pn',
        UPPER(IM.PartDescription) 'pndescription',
        UPPER(STL.itemtype) 'itemtype',
        CASE
          WHEN stl.isPma = 1 AND
            stl.IsDER = 1 THEN 'PMA&DER'
          WHEN stl.isPma = 1 AND
            (stl.IsDER IS NULL OR
            stl.IsDER = 0) THEN 'PMA'
          WHEN (stl.isPma = 0 OR
            stl.isPma IS NULL) AND
            stl.IsDER = 1 THEN 'DER'
          ELSE 'OEM'
        END AS 'stocktype',
        UPPER(PO.status) 'status',
        UPPER(PO.VendorName) 'vendorname',
        UPPER(PO.VendorCode) 'vendorcode',
        UPPER(POP.unitofmeasure) 'uom',
        POP.QuantityOrdered 'qty',
        POP.PurchaseOrderId,
        STL.UnitCost 'unitcost',
        UPPER(POP.functionalcurrency) 'currency',
        STL.PurchaseOrderExtendedCost 'extamount',
        'N/A' 'localamount',
        FORMAT (POP.NeedByDate, 'MM/dd/yyyy hh:mm:tt') 'requestdate',
        UPPER(ISNULL(POP.workorderno,'')) 'wonum',
        UPPER(ISNULL(IM1.partnumber,'')) 'wompn',
        UPPER(ISNULL(IM1.partdescription,'')) 'mpndescription',
        UPPER(ISNULL(POP.salesorderno,'')) 'sonum',
        UPPER(ISNULL(IM2.partnumber,'')) 'sopn',
        UPPER(ISNULL(IM2.partdescription,'')) 'sopndescription',
        UPPER(ISNULL(WO.CustomerName,'')) 'customer'
      FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
		INNER JOIN DBO.PurchaseOrder PO WITH (NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId
		INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = 4 AND MSD.ReferenceID = POP.PurchaseOrderId
		LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
        LEFT JOIN DBO.Stockline STL WITH (NOLOCK)  ON POP.PurchaseOrderPartRecordId = STL.PurchaseOrderPartRecordId and stl.IsParent=1
        LEFT JOIN DBO.Workorder WO WITH (NOLOCK) ON POP.workorderid = WO.workorderid 
		--LEFT JOIN DBO.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
        LEFT JOIN DBO.Itemmaster IM WITH (NOLOCK) ON POP.itemmasterid = IM.itemmasterid
        LEFT JOIN DBO.WorkOrderMaterials WOM WITH (NOLOCK) ON POP.PurchaseOrderId = WOM.POId
        LEFT JOIN DBO.itemmaster IM1 WITH (NOLOCK) ON WOM.itemmasterid = IM1.itemmasterid
       	LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK) ON POP.salesorderid = SO.SalesOrderId
	    LEFT JOIN DBO.salesorderpart SOP WITH (NOLOCK) ON POP.salesorderid = SOP.SalesOrderId AND SOP.ItemMasterId = POP.ItemMasterId  
	    LEFT JOIN DBO.itemmaster IM2 WITH (NOLOCK) ON SOP.ItemMasterId = IM2.itemmasterid 
      WHERE PO.VendorId = ISNULL(@vendorname,PO.VendorId) 
		AND CAST(PO.opendate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
		AND (PO.StatusId IN (SELECT value FROM String_split(@status, ',')) OR ISNULL(@status,'') = '') 
		AND PO.mastercompanyid = @mastercompanyid AND 
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
       GROUP BY 
		   PO.PurchaseOrderNumber, FORMAT (PO.OpenDate, 'MM/dd/yyyy hh:mm:tt'), IM.partnumber,IM.PartDescription,STL.itemtype,
			CASE WHEN stl.isPma = 1 AND stl.IsDER = 1 THEN 'PMA&DER' WHEN stl.isPma = 1 AND (stl.IsDER IS NULL OR stl.IsDER = 0) THEN 'PMA'
				 WHEN (stl.isPma = 0 OR stl.isPma IS NULL) AND stl.IsDER = 1 THEN 'DER' ELSE 'OEM' END,
		   PO.status,PO.VendorName,PO.VendorCode,POP.unitofmeasure, POP.QuantityOrdered, POP.PurchaseOrderId, STL.UnitCost ,POP.functionalcurrency, FORMAT (POP.NeedByDate, 'MM/dd/yyyy hh:mm:tt'),
		   STL.PurchaseOrderExtendedCost,POP.workorderno,IM1.partnumber,IM1.partdescription,POP.salesorderno,IM2.partnumber,IM2.partnumber,IM2.partdescription,WO.CustomerName,
		   MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name
	   ORDER BY PO.PurchaseOrderNumber,IM.partnumber
	   OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY; 
	   
  END TRY

  BEGIN CATCH
 
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[usprpt_GetVendorUtilizationReport]',
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