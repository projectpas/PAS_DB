/*************************************************************             
 ** File:   [dbo.usprpt_GetPurchaseAnalysis_POStock]             
 ** Author:  Rajesh Gami    
 ** Description: Get Data for Purchase Order Analysis Report Data [Most Purchased Stock]
 ** Purpose:           
 ** Date:   20-AUG-2024         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    20-AUG-2024     Rajesh Gami       Created  

**************************************************************/  
CREATE   PROCEDURE [dbo].[usprpt_GetPurchaseAnalysis_POStock]
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
 
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
		SET @PageSize = 50;
		DECLARE @Count VARCHAR(10)='50',@Sql NVARCHAR(MAX);  
		DECLARE @vendorId varchar(40) = NULL,  
		@fromdate datetime,  
		@todate datetime, 
		@conditionIds varchar(200) = NULL,
		@searchWOType varchar(10) = NULL,
		@itemMasterId varchar(40) = NULL,
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
		@totalResult VARCHAR(10) = 0

  
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
		
		@conditionIds=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Condition' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @conditionIds end,

		@Count=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='defaultRecord' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Count end,
		
		@searchWOType=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='searchWOType' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @searchWOType end,

		@itemMasterId=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='PN(Optional)' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @itemMasterId end,

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
		  SET @PageSize = COALESCE(NULLIF(@PageSize, 0), 50);
		  SET @Count = COALESCE(NULLIF(@Count, 0), 50);
	 
	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 50 ELSE @PageSize END
	  PRINT @PageSize
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
	  
	  SELECT * INTO #TempPOAnalysis FROM
		(SELECT DISTINCT
			UPPER(V.VendorName) 'vendor',  
			V.VendorId VendorId,
			ROW_NUMBER() OVER(Partition by STK.ItemMasterId ORDER BY STK.CreatedDate) AS Row_Number,
			IM.ItemMasterId,
			UPPER(IM.PartNumber) 'pn',  
			UPPER(IM.PartDescription) 'pnDescription',  
			UPPER(CN.Description) 'conditions',  
			UPPER(POP.UnitOfMeasure) 'uoms',
			(CASE WHEN ISNULL(STK.OEM,0) = 1 THEN 'OEM' ELSE 'PMA' END) AS 'oems',
			UPPER(IM.ManufacturerName) 'manufacturers',
			ISNULL(stk.Quantity,0) AS 'qty', 
			ISNULL(POP.UnitCost,0) AS 'lastUnitPrices', 
			stk.CreatedDate AS 'lastPurchaseDates',
		    (CASE WHEN po.DateApproved IS NOT NULL AND stk.ReceivedDate IS NOT NULL THEN DATEDIFF(DAY,po.DateApproved,stk.ReceivedDate) ELSE 0 END) as dateAge,
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
				    PO.VendorId=ISNULL(@vendorId,PO.VendorId) AND POP.ItemMasterId = ISNULL(@itemMasterId,POP.ItemMasterId)  
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
		
		SELECT * INTO #TempPOAnalysisFinal FROM
		 (SELECT 
			(CASE WHEN (SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) > 1 THEN (SELECT TOP 1 tm.conditions FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) ELSE conditions END) AS 'condition',
			(CASE WHEN (SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) > 1 THEN (SELECT TOP 1 tm.uoms FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) ELSE uoms END) AS 'uom',
			(CASE WHEN (SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) > 1 THEN (SELECT TOP 1 tm.oems FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) ELSE oems END) AS 'oem',
			(CASE WHEN (SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) > 1 THEN (SELECT TOP 1 CONVERT(DECIMAL(10,2),tm.lastUnitPrices) FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) ELSE CONVERT(DECIMAL(10,2),lastUnitPrices) END) AS 'lastUnitPrice',
			(CASE WHEN (SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) > 1 THEN (SELECT TOP 1 convert(varchar, tm.lastPurchaseDates, 101) FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) ELSE  convert(varchar, lastPurchaseDates, 101)  END) AS 'lastPurchaseDate',
			(CASE WHEN (SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) > 1 THEN (SELECT TOP 1 tm.manufacturers FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) ELSE manufacturers END) AS 'manufacturer',

			(SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) AS LastRowNo,
			* FROM #TempPOAnalysis main) as res

		SELECT * INTO #tmpFinalResult FROM
		 (SELECT condition,pn,pnDescription,manufacturer,ItemMasterId,uom,lastUnitPrice,lastPurchaseDate, (SUM(dateAge)/MAX(LastRowNo)) as avgAge
		 ,MAX(LastRowNo) LastRowNo
		 ,SUM(qty) qty, oem
		 FROM #TempPOAnalysisFinal GROUP BY pn,pnDescription,condition,ItemMasterId,lastUnitPrice,uom,lastPurchaseDate,oem,manufacturer) as result
		
		SET @totalResult = (SELECT COUNT(*) FROM #tmpFinalResult)
		
		SET @Sql = N'Select TOP '+@Count+' (CASE WHEN '+@totalResult+' > '+@Count+' THEN '+@Count+' ELSE '+@totalResult+' END) AS totalRecordsCount,* from #tmpFinalResult ORDER by LastRowNo DESC'
		PRINT @Sql
		EXEC sp_executesql  @Sql, N'@Count INT, @totalResult INT OUTPUT', @Count = @Count,@totalResult = @totalResult OUTPUT;
  END TRY  
  
  BEGIN CATCH  
    SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(), 
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[dbo.usprpt_GetPurchaseAnalysis_POStock]',  
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