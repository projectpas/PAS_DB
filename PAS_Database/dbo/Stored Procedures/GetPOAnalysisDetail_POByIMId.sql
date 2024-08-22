
/*************************************************************             
 ** File:   [dbo.GetPOAnalysisDetail_POByIMId]             
 ** Author:  Rajesh Gami    
 ** Description: Get Data for Purchase Order Analysis Report Detail By Item Master Id
 ** Purpose:           
 ** Date:   21-AUG-2024         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    21-AUG-2024      Rajesh Gami       Created  

**************************************************************/  
CREATE    PROCEDURE [dbo].[GetPOAnalysisDetail_POByIMId] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
 
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
		SET @PageSize = 1000;
		DECLARE @vendorId varchar(40) = NULL,  
		@fromdate datetime,  
		@todate datetime, 
		@conditionIds varchar(200) = NULL,
		@searchWOType varchar(10) = NULL,
		@isCustomerWO bit = NULL,
		@woTypeIds varchar(200) = NULL,
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
		@IsDownload BIT = NULL,
		@selectedItemMasterId varchar(40) = NULL, @totalQty Int =0, @totalUnitCost decimal(18,2)=0, @totalExtCost decimal(18,2)=0

  
  BEGIN TRY  
    --BEGIN TRANSACTION  
       print 'Start'
          DECLARE @ModuleID INT = 5; -- MS Module ID (PO Part) - ManagementStructureModule
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END
	   SELECT 
		@fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
		@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,
		
		@vendorId=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Vendor(Optional)' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @vendorId end,
		
		@selectedItemMasterId=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='itemMasterId' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @selectedItemMasterId end,

		@conditionIds=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Condition' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @conditionIds end,

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
		 
	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
	  
	  SELECT * INTO #TempPOAnalysisTbl FROM
      (SELECT DISTINCT
			UPPER(V.VendorName) 'vendor',  
			V.VendorId VendorId,
			ROW_NUMBER() OVER(Partition by STK.ItemMasterId ORDER BY STK.CreatedDate) AS Row_Number,
			IM.ItemMasterId,
			UPPER(IM.PartNumber) 'pn',  
			UPPER(IM.PartDescription) 'pnDescription',  
			UPPER(CN.Description) 'condition',  
			UPPER(POP.UnitOfMeasure) 'uom',
			(CASE WHEN ISNULL(STK.OEM,0) = 1 THEN 'OEM' ELSE 'PMA' END) AS 'oem',
			UPPER(IM.ManufacturerName) 'manufacturer',
			ISNULL(stk.Quantity,0) AS 'qtys', 
			ISNULL(POP.UnitCost,0) AS 'unitCost', 
			(ISNULL(stk.Quantity,0) * ISNULL(POP.UnitCost,0)) 'extCosts',
			CAST(stk.CreatedDate as Date) AS 'receivedDate',
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
			PO.OpenDate 'openDate',
			Stk.CreatedBy as 'requester',
			Po.PurchaseOrderNumber as 'refNumber',
			Stk.ReceiverNumber as  receiverNum,
			PO.PurchaseOrderId 'poroAnalysisId',
			1 as 'isPurchaseOrder'
        FROM 
			DBO.PurchaseOrder AS PO WITH (NOLOCK)  
			INNER JOIN DBO.PurchaseOrderPart AS POP WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId
			INNER JOIN DBO.Stockline STK WITH (NOLOCK) on PO.PurchaseOrderId = STK.PurchaseOrderId
			INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = POP.PurchaseOrderPartRecordId
			INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON POP.itemmasterId = IM.itemmasterId
			LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN DBO.Vendor V WITH (NOLOCK) ON PO.VendorId = V.VendorId  
			LEFT JOIN DBO.Condition AS CN WITH (NOLOCK) ON STK.ConditionId = CN.ConditionId 
		  
		  WHERE ISNULL(PO.IsDeleted,0) = 0 AND ISNULL(STK.IsParent,0) = 1 AND
				PO.VendorId=ISNULL(@vendorId,PO.VendorId)    AND POP.ItemMasterId = ISNULL(@selectedItemMasterId,POP.ItemMasterId)  
					AND CAST(STK.CreatedDate AS DATE) BETWEEN CAST(@fromdate AS DATE) AND CAST(@todate AS DATE) AND PO.mastercompanyid = @mastercompanyid
					AND (ISNULL(@conditionIds,'')='' OR Stk.ConditionId IN(SELECT value FROM String_split(ISNULL(@conditionIds,''), ',')))
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
		) as a

		SELECT *
			  INTO #tmpFinalAnalysisResult FROM (SELECT DISTINCT vendor,VendorId,ItemMasterId,pn,pnDescription,condition,uom,oem,manufacturer,SUM(qtys) as qty,
			   unitCost,SUM(extCosts)extCost,receivedDate,openDate,requester,refNumber,receiverNum,poroAnalysisId,isPurchaseOrder FROM #TempPOAnalysisTbl GROUP BY vendor,VendorId,ItemMasterId,pn,pnDescription,condition,uom,oem,manufacturer,
			   unitCost,receivedDate,openDate,requester,refNumber,receiverNum,poroAnalysisId,isPurchaseOrder) as res

		SELECT @totalQty = SUM(qty), @totalUnitCost = SUM(unitCost), @totalExtCost = SUM(extCost) FROM #tmpFinalAnalysisResult
		SELECT *,@totalQty as totalQty, @totalUnitCost as totalUnitCost, @totalExtCost as totalExtCost   FROM #tmpFinalAnalysisResult ORDER BY openDate DESC		

  END TRY  
  
  BEGIN CATCH  
    
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(), 
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[dbo.GetPOAnalysisDetail_POByIMId]',  
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