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
	2    05-NOV-2025     Amit Ghediya      Update for Avg price & totalPOs count fix
	3    08-JUNE-2026    Priyansh Patel    Uom releted changes for quantity and cost [PN-16756]

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
		  @totalResult VARCHAR(10) = 0;
  
  BEGIN TRY  
      DECLARE @ModuleID INT = 5; -- MS Module ID (PO Part)
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END

	  SELECT 
		@fromdate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date' 
						 THEN CONVERT(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @fromdate END,
		@todate = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date' 
						 THEN CONVERT(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) ELSE @todate END,
		@vendorId = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Vendor(Optional)' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @vendorId END,
		@conditionIds = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Condition' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @conditionIds END,
		@Count = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='defaultRecord' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @Count END,
		@itemMasterId = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='PN(Optional)' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @itemMasterId END,
		@level1 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level1 END,
		@level2 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level2 END,
		@level3 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level3 END,
		@level4 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level4 END,
		@level5 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level5 END,
		@level6 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level6 END,
		@level7 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level7 END,
		@level8 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level8 END,
		@level9 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level9 END,
		@level10 = CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10' 
						 THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 END
	  FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby);

	  SET @PageSize = COALESCE(NULLIF(@PageSize, 0), 50);
	  SET @Count = COALESCE(NULLIF(@Count, 0), 50);
	  SET @PageNumber = COALESCE(NULLIF(@PageNumber,0), 1);

	  SELECT * INTO #TempPOAnalysis FROM
		(SELECT DISTINCT
			UPPER(V.VendorName) AS vendor,  
			V.VendorId,
			ROW_NUMBER() OVER(PARTITION BY STK.ItemMasterId ORDER BY STK.CreatedDate) AS Row_Number,
			IM.ItemMasterId,
			UPPER(IM.PartNumber) AS pn,  
			UPPER(IM.PartDescription) AS pnDescription,  
			UPPER(CN.Description) AS condition,  
			UPPER(stk.UnitOfMeasure) AS uoms,
			(CASE WHEN ISNULL(STK.OEM,0)=1 THEN 'OEM' ELSE 'PMA' END) AS oems,
			UPPER(IM.ManufacturerName) AS manufacturers,
            calc.qty,
			calc.lastUnitPrice,
			calc.qty * calc.lastUnitPrice AS avgPOCost,
			CAST(stk.CreatedDate AS Date) AS lastPurchaseDates,
			(CASE WHEN ISNULL(PO.IsEnforce,0)=1 
				  THEN (CASE WHEN PO.DateApproved IS NOT NULL AND STK.ReceivedDate IS NOT NULL 
							 THEN DATEDIFF(DAY,PO.DateApproved,STK.ReceivedDate) 
							 ELSE DATEDIFF(DAY,PO.CreatedDate,STK.ReceivedDate) END)
				  ELSE DATEDIFF(DAY,PO.CreatedDate,STK.ReceivedDate) END) AS dateAge,
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
			0 AS totalPOs,
			PO.PurchaseOrderId,
			POP.PurchaseOrderPartRecordId
		FROM DBO.PurchaseOrder AS PO WITH (NOLOCK)  
			INNER JOIN DBO.PurchaseOrderPart AS POP WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId
			INNER JOIN DBO.Stockline STK WITH (NOLOCK) 
					ON POP.PurchaseOrderId = STK.PurchaseOrderId 
					AND POP.ItemMasterId = STK.ItemMasterId 
					AND STK.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId
			INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) 
					ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = STK.PurchaseOrderPartRecordId
			INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON STK.ItemMasterId = IM.ItemMasterId
			LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN DBO.Vendor V WITH (NOLOCK) ON PO.VendorId = V.VendorId  
			LEFT JOIN DBO.Condition AS CN WITH (NOLOCK) ON STK.ConditionId = CN.ConditionId
			CROSS APPLY (
			SELECT
				ROUND(dbo.fn_ConvertUOM(ISNULL(STK.Quantity, 0), STK.StockUnitOfMeasure, POP.UnitOfMeasure, 0, PO.MasterCompanyId), 2) AS qty,
				ROUND(dbo.fn_ConvertUOM(ISNULL(STK.UnitCost,  0), STK.StockUnitOfMeasure, POP.UnitOfMeasure, 1, PO.MasterCompanyId), 2) AS lastUnitPrice
			) AS calc

		WHERE ISNULL(PO.IsDeleted,0)=0 
			  AND ISNULL(STK.IsParent,0)=1
			  AND PO.VendorId=ISNULL(@vendorId,PO.VendorId) 
			  AND STK.ItemMasterId=ISNULL(@itemMasterId,STK.ItemMasterId)
			  AND CAST(STK.CreatedDate AS DATE) BETWEEN CAST(@fromdate AS DATE) AND CAST(@todate AS DATE)
			  AND PO.MasterCompanyId=@mastercompanyid
			  AND (ISNULL(@conditionIds,'')='' OR STK.ConditionId IN(SELECT value FROM STRING_SPLIT(@conditionIds,',')))
		) AS a;

	  SELECT * INTO #TempPOAnalysisFinal FROM
		(SELECT 
			(CASE WHEN (SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId=main.ItemMasterId ORDER BY Row_Number DESC)>1 
				  THEN (SELECT TOP 1 tm.uoms FROM #TempPOAnalysis tm WHERE tm.ItemMasterId=main.ItemMasterId ORDER BY Row_Number DESC) 
				  ELSE uoms END) AS uom,
			(CASE WHEN (SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId=main.ItemMasterId ORDER BY Row_Number DESC)>1 
				  THEN (SELECT TOP 1 tm.oems FROM #TempPOAnalysis tm WHERE tm.ItemMasterId=main.ItemMasterId ORDER BY Row_Number DESC) 
				  ELSE oems END) AS oem,
			(CASE WHEN (SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId=main.ItemMasterId ORDER BY Row_Number DESC)>1 
				  THEN (SELECT TOP 1 tm.lastPurchaseDates FROM #TempPOAnalysis tm WHERE tm.ItemMasterId=main.ItemMasterId ORDER BY Row_Number DESC) 
				  ELSE lastPurchaseDates END) AS lastPurchaseDate,
			(CASE WHEN (SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId=main.ItemMasterId ORDER BY Row_Number DESC)>1 
				  THEN (SELECT TOP 1 tm.manufacturers FROM #TempPOAnalysis tm WHERE tm.ItemMasterId=main.ItemMasterId ORDER BY Row_Number DESC) 
				  ELSE manufacturers END) AS manufacturer,
			(SELECT TOP 1 Row_Number FROM #TempPOAnalysis tm WHERE tm.ItemMasterId=main.ItemMasterId ORDER BY Row_Number DESC) AS LastRowNo,
			* 
		 FROM #TempPOAnalysis main) AS res;

	  SELECT * INTO #tmpFinalAnalysis1
	  FROM (
		  SELECT 
			  MAX(main.pn) AS pn,
			  MAX(main.pnDescription) AS pnDescription,
			  MAX(main.uom) AS uom,
			  MAX(main.oem) AS oem,
			  MAX(main.lastUnitPrice) AS lastUnitPrice,
			  MAX(main.lastPurchaseDate) AS lastPurchaseDate,
			  MAX(main.manufacturer) AS manufacturer,
			  MAX(main.vendor) AS vendor,
			  main.condition,
			  SUM(main.avgPOCost) AS avgPOCost,
			  SUM(main.qty) AS qty,
			  AVG(main.dateAge) AS dateAge,
			  COUNT(DISTINCT main.PurchaseOrderId) AS totalPOs,
			  MAX(main.ItemMasterId) AS ItemMasterId
		  FROM #TempPOAnalysisFinal AS main
		  GROUP BY main.ItemMasterId, main.condition
	  ) AS res;

	  SELECT * INTO #tmpFinalAnalysis
	  FROM (
		  SELECT 
			  ROW_NUMBER() OVER(PARTITION BY main.pn, main.condition ORDER BY MAX(main.lastPurchaseDate) DESC) AS MaxRow_Number,
			  main.pn,
			  main.condition,
			  main.ItemMasterId,
			  MAX(main.uom) AS uom,
			  MAX(main.oem) AS oem,
			  MAX(main.lastUnitPrice) AS lastUnitPrice,
			  MAX(main.lastPurchaseDate) AS lastPurchaseDate,
			  MAX(main.manufacturer) AS manufacturer,
			  MAX(main.vendor) AS vendor,
			  MAX(main.pnDescription) AS pnDescription,
			  CASE WHEN SUM(main.qty)=0 THEN 0 ELSE SUM(main.avgPOCost)/NULLIF(SUM(main.qty),0) END AS avgPOCost,
			  SUM(main.qty) AS qty,
			  AVG(main.dateAge) AS dateAge,
			  MAX(main.totalPOs) AS totalPOs
		  FROM #tmpFinalAnalysis1 AS main
		  GROUP BY main.pn, main.ItemMasterId, main.condition
	  ) AS res;

	  SELECT * INTO #tmpFinalResult FROM
	  (
		  SELECT 
			  condition,
			  pn,
			  avgPOCost,
			  pnDescription,
			  manufacturer,
			  ItemMasterId,
			  uom,
			  lastUnitPrice,
			  lastPurchaseDate,
			  SUM(dateAge) AS sums,
			  CONVERT(INT,ROUND((SUM(CONVERT(DECIMAL(10,2),dateAge))/MAX(MaxRow_Number)),0)) AS avgAge,
			  totalPOs AS MaxRow_Number,
			  SUM(qty) AS qty,
			  oem
		  FROM #tmpFinalAnalysis		  
		  GROUP BY pn,avgPOCost,pnDescription,condition,ItemMasterId,lastUnitPrice,uom,lastPurchaseDate,totalPOs,oem,manufacturer
	  ) AS result;

	  SET @totalResult = (SELECT COUNT(*) FROM #tmpFinalResult);

	  SET @Sql = N'SELECT TOP '+@Count+' (CASE WHEN '+@totalResult+'>'+@Count+' THEN '+@Count+' ELSE '+@totalResult+' END) AS totalRecordsCount,* 
				   FROM #tmpFinalResult ORDER BY lastPurchaseDate DESC';
	  EXEC sp_executesql @Sql, N'@Count INT, @totalResult INT OUTPUT', @Count=@Count, @totalResult=@totalResult OUTPUT;

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
			  @DatabaseName varchar(100)=DB_NAME(), 
			  @AdhocComments varchar(150)='[dbo.usprpt_GetPurchaseAnalysis_POStock]',  
			  @ProcedureParameters varchar(3000) = '@PageNumber='+CAST(ISNULL(@PageNumber,'') AS varchar(100))+
				  '@PageSize='+CAST(ISNULL(@PageSize,'') AS varchar(100))+
				  '@mastercompanyid='+CAST(ISNULL(@mastercompanyid,'') AS varchar(100)),
			  @ApplicationName varchar(100)='PAS';

	  EXEC Splogexception 
		  @DatabaseName=@DatabaseName,  
		  @AdhocComments=@AdhocComments,  
		  @ProcedureParameters=@ProcedureParameters,  
		  @ApplicationName=@ApplicationName,  
		  @ErrorLogID=@ErrorLogID OUTPUT;  
  
	  RAISERROR('Unexpected Error Occured in database. Please let support team know error number: %d',16,1,@ErrorLogID);
	  RETURN (1);  
  END CATCH  
END