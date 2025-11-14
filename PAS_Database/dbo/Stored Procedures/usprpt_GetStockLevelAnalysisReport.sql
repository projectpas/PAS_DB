/*************************************************************           
 ** File:   [usprpt_GetStockLevelAnalysisReport]
 ** Author:   Vishal Suthar
 ** Description: Get Data for Stock Level Analysis Report
 ** Purpose:         
 ** Date:   04-November-2025
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
  ** S NO   Date            Author				Change Description              
 ** --   --------			-------				--------------------------------            
    1    04-November-2022	Vishal Suthar			Created

EXECUTE   [dbo].[usprpt_GetStockLevelAnalysisReport] '2','2010-01-01','2022-04-26',null,1,10
**************************************************************/
CREATE    PROCEDURE [dbo].[usprpt_GetStockLevelAnalysisReport] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @level1 VARCHAR(MAX) = NULL,
	@level2 VARCHAR(MAX) = NULL,
	@level3 VARCHAR(MAX) = NULL,
	@level4 VARCHAR(MAX) = NULL,
	@Level5 VARCHAR(MAX) = NULL,
	@Level6 VARCHAR(MAX) = NULL,
	@Level7 VARCHAR(MAX) = NULL,
	@Level8 VARCHAR(MAX) = NULL,
	@Level9 VARCHAR(MAX) = NULL,
	@Level10 VARCHAR(MAX) = NULL,

	@PN VARCHAR(MAX) = NULL,
	@Condition VARCHAR(MAX) = NULL,

	@Site VARCHAR(MAX) = NULL,
	@Warehouse VARCHAR(MAX) = NULL,
	@Location VARCHAR(MAX) = NULL,
	@Shelf VARCHAR(MAX) = NULL,
	@Bin VARCHAR(MAX) = NULL,

	@IsDownload BIT = NULL

  BEGIN TRY
	select 
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
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level10 end,

		@PN=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='PN' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @PN end,
		@Condition=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Condition' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Condition end,

		@Site=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Site' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Site end,
		@Warehouse=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Warehouse' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Warehouse end,
		@Location=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Location' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Location end,
		@Shelf=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Shelf' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Shelf end,
		@Bin=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Bin' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Bin end

  FROM
      @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)

      DECLARE @ModuleID INT = 2; -- MS Module ID
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END
	  	  
	   IF ISNULL(@PageSize,0)=0
		BEGIN 
		  SELECT @PageSize=COUNT(*)
		  FROM DBO.Stockline stl WITH (NOLOCK)
			INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId
			LEFT JOIN dbo.EntityStructureSetup ES WITH(NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID
			WHERE stl.mastercompanyid = @mastercompanyid AND ISNULL(stl.IsParent, 0) = 1 AND stl.IsDeleted=0 AND ISNULL(stl.IsCustomerStock, 0) = 0
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

	 -- ;WITH rptCTE (TotalRecordsCount, pn, pndescription,manufacturer,cond,stockLineId,stockuom, masterCompanyId,stocklevel,leadtimedays,reorderpoint,reorderqty,minqtyorder,
		--			qtyonhand,qtyonavail,reorder,qtytoorder,site,warehouse,location,shelf,bin,level1, level2, level3, level4, level5, level6, level7, level8,
		--	     level9, level10) AS (
  --    SELECT COUNT(1) OVER () AS TotalRecordsCount,
  --      UPPER(stl.partnumber) AS 'pn',
  --      UPPER(stl.PNDescription) AS 'pndescription',
		--UPPER(stl.Manufacturer) AS 'manufacturer',
		--UPPER(stl.Condition) AS 'cond',
		--stl.StockLineId AS 'stockLineId',
		--stl.UnitOfMeasure AS 'stockuom',
		--stl.MasterCompanyId AS 'masterCompanyId',
		--IM.StockLevel AS 'stocklevel',
		--IM.LeadTimeDays AS 'leadtimedays',
		--IM.ReorderPoint AS 'reorderpoint',
		--IM.ReorderQuantiy AS 'reorderqty',
		--IM.MinimumOrderQuantity AS 'minqtyorder',
		--stl.QuantityOnHand AS 'qtyonhand',
		--stl.QuantityAvailable AS 'qtyonavail',
		--CASE WHEN stl.QuantityAvailable <= IM.StockLevel THEN 'YES' ELSE 'NO' END AS 'reorder',
		--CASE 
		--	WHEN 
		--		(ISNULL(IM.StockLevel,0) - ISNULL(stl.QuantityAvailable,0)) > ISNULL(IM.MinimumOrderQuantity,0) 
		--	THEN (ISNULL(IM.StockLevel,0) - ISNULL(stl.QuantityAvailable,0)) ELSE ISNULL(IM.MinimumOrderQuantity,0)
		--END	AS 'qtytoorder',
		--UPPER(stl.[Site]) As 'site',
		--UPPER(stl.[Warehouse]) As 'warehouse',
		--UPPER(stl.[Location]) As 'location',
		--UPPER(stl.[Shelf]) As 'shelf',
		--UPPER(stl.[Bin]) As 'bin',
		--UPPER(MSD.Level1Name) AS level1,     
		--UPPER(MSD.Level2Name) AS level2,    
		--UPPER(MSD.Level3Name) AS level3,    
		--UPPER(MSD.Level4Name) AS level4,    
		--UPPER(MSD.Level5Name) AS level5,    
		--UPPER(MSD.Level6Name) AS level6,    
		--UPPER(MSD.Level7Name) AS level7,   
		--UPPER(MSD.Level8Name) AS level8,    
		--UPPER(MSD.Level9Name) AS level9,    
		--UPPER(MSD.Level10Name) AS level10
		--FROM DBO.Stockline stl WITH (NOLOCK)
		--INNER JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = stl.ItemMasterId
	 --   INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId
		--LEFT JOIN dbo.EntityStructureSetup ES WITH(NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID
		--WHERE stl.mastercompanyid = @mastercompanyid and stl.isActive =1 AND ISNULL(stl.IsParent, 0) = 1 AND stl.IsDeleted=0 AND ISNULL(stl.IsCustomerStock, 0) = 0
		--	AND (ISNULL(@PN,'') ='' OR stl.ItemMasterId  = @PN)
		--	AND (ISNULL(@Condition,'') ='' OR stl.ConditionId IN (SELECT Item FROM DBO.SPLITSTRING(@Condition,','))) 
		--	AND (ISNULL(@Site,'') ='' OR stl.SiteId IN (SELECT Item FROM DBO.SPLITSTRING(@Site,',')))   
		--	AND (ISNULL(@Warehouse,'') ='' OR stl.WarehouseId IN (SELECT Item FROM DBO.SPLITSTRING(@Warehouse,',')))   
		--	AND (ISNULL(@Location,'') ='' OR stl.LocationId IN (SELECT Item FROM DBO.SPLITSTRING(@Location,',')))   
		--	AND (ISNULL(@Shelf,'') ='' OR stl.ShelfId IN (SELECT Item FROM DBO.SPLITSTRING(@Shelf,',')))   
		--	AND (ISNULL(@Bin,'') ='' OR stl.BinId IN (SELECT Item FROM DBO.SPLITSTRING(@Bin,',')))
	 --       AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
		--	AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
		--	AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
		--	AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
		--	AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
		--	AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
		--	AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
		--	AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
		--	AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
		--	AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
		--	)
		--	,FinalCTE(TotalRecordsCount, pn, pndescription,manufacturer,cond,stockLineId,stockuom,stocklevel,leadtimedays,reorderpoint,reorderqty,minqtyorder,qtyonhand,qtyonavail,reorder,qtytoorder,site,warehouse,location,shelf,bin,level1, level2, level3, level4, level5, level6, level7, level8,level9, level10, masterCompanyId) 
		--	  AS (SELECT DISTINCT TotalRecordsCount, pn, pndescription,manufacturer,cond,stockLineId,stockuom,stocklevel,leadtimedays,reorderpoint,reorderqty,minqtyorder,qtyonhand,qtyonavail,reorder,qtytoorder,site,warehouse,location,shelf,bin,level1, level2, level3, level4, level5, level6, level7, level8,level9, level10, masterCompanyId 
		--	  FROM rptCTE)

		--	,WithTotal (masterCompanyId) 
		--	  AS (SELECT masterCompanyId
		--		FROM FinalCTE
		--		GROUP BY masterCompanyId)

		--	  SELECT COUNT(2) OVER () AS TotalRecordsCount, pn, pndescription,manufacturer,cond,stockLineId,stockuom,stocklevel,leadtimedays,reorderpoint,reorderqty,minqtyorder,qtyonhand,qtyonavail,reorder,qtytoorder,site,warehouse,location,shelf,bin,level1, level2, level3, level4, level5, level6, level7, level8,level9, level10
		--		FROM FinalCTE FC
		--			INNER JOIN WithTotal WC ON FC.masterCompanyId = WC.masterCompanyId
		--		ORDER BY pn DESC
		--		OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY; 
		;WITH rptCTE AS (
			SELECT 
				COUNT(1) OVER () AS TotalRecordsCount,
				UPPER(stl.partnumber) AS pn,
				IM.itemMasterId,
				UPPER(stl.PNDescription) AS pndescription,
				UPPER(stl.Manufacturer) AS manufacturer,
				UPPER(stl.Condition) AS cond,
				stl.StockLineId AS stockLineId,
				stl.UnitOfMeasure AS stockuom,
				stl.MasterCompanyId AS masterCompanyId,
				IM.StockLevel AS stocklevel,
				IM.LeadTimeDays AS leadtimedays,
				IM.ReorderPoint AS reorderpoint,
				IM.ReorderQuantiy AS reorderqty,
				IM.MinimumOrderQuantity AS minqtyorder,
				stl.QuantityOnHand AS qtyonhand,
				stl.QuantityAvailable AS qtyonavail,
				CASE WHEN stl.QuantityAvailable <= IM.StockLevel THEN 'YES' ELSE 'NO' END AS reorder,
				CASE 
					WHEN (ISNULL(IM.StockLevel,0) - ISNULL(stl.QuantityAvailable,0)) > ISNULL(IM.MinimumOrderQuantity,0)
					THEN (ISNULL(IM.StockLevel,0) - ISNULL(stl.QuantityAvailable,0)) 
					ELSE ISNULL(IM.MinimumOrderQuantity,0)
				END AS qtytoorder,
				UPPER(stl.[Site]) AS site,
				UPPER(stl.[Warehouse]) AS warehouse,
				UPPER(stl.[Location]) AS location,
				UPPER(stl.[Shelf]) AS shelf,
				UPPER(stl.[Bin]) AS bin,
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
			FROM DBO.Stockline stl WITH (NOLOCK)
			INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = stl.ItemMasterId
			INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK)
				ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = stl.StockLineId
			LEFT JOIN dbo.EntityStructureSetup ES WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID
			WHERE 
				stl.mastercompanyid = @mastercompanyid 
				AND stl.isActive = 1 
				AND ISNULL(stl.IsParent, 0) = 1 
				AND stl.IsDeleted = 0 
				AND ISNULL(stl.IsCustomerStock, 0) = 0
				AND (ISNULL(@PN,'') = '' OR stl.ItemMasterId = @PN)
				AND (ISNULL(@Condition,'') = '' OR stl.ConditionId IN (SELECT Item FROM DBO.SPLITSTRING(@Condition,',')))
				AND (ISNULL(@Site,'') = '' OR stl.SiteId IN (SELECT Item FROM DBO.SPLITSTRING(@Site,',')))   
				AND (ISNULL(@Warehouse,'') = '' OR stl.WarehouseId IN (SELECT Item FROM DBO.SPLITSTRING(@Warehouse,',')))   
				AND (ISNULL(@Location,'') = '' OR stl.LocationId IN (SELECT Item FROM DBO.SPLITSTRING(@Location,',')))   
				AND (ISNULL(@Shelf,'') = '' OR stl.ShelfId IN (SELECT Item FROM DBO.SPLITSTRING(@Shelf,',')))   
				AND (ISNULL(@Bin,'') = '' OR stl.BinId IN (SELECT Item FROM DBO.SPLITSTRING(@Bin,',')))
				AND (ISNULL(@Level1,'') = '' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
				AND (ISNULL(@Level2,'') = '' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
				AND (ISNULL(@Level3,'') = '' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
				AND (ISNULL(@Level4,'') = '' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
				AND (ISNULL(@Level5,'') = '' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
				AND (ISNULL(@Level6,'') = '' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
				AND (ISNULL(@Level7,'') = '' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
				AND (ISNULL(@Level8,'') = '' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
				AND (ISNULL(@Level9,'') = '' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
				AND (ISNULL(@Level10,'') = '' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
		)

		,GroupedCTE AS (
			SELECT 
				MAX(TotalRecordsCount) AS TotalRecordsCount,
				pn,
				MAX(itemMasterId) AS itemMasterId,
				MAX(pndescription) AS pndescription,
				MAX(manufacturer) AS manufacturer,
				cond,
				site,
				MAX(stockuom) AS stockuom,
				MAX(stocklevel) AS stocklevel,
				MAX(leadtimedays) AS leadtimedays,
				MAX(reorderpoint) AS reorderpoint,
				MAX(reorderqty) AS reorderqty,
				MAX(minqtyorder) AS minqtyorder,
				SUM(qtyonhand) AS qtyonhand,
				SUM(qtyonavail) AS qtyonavail,
				MAX(reorder) AS reorder,
				MAX(qtytoorder) AS qtytoorder,
				MAX(warehouse) AS warehouse,
				MAX(location) AS location,
				MAX(shelf) AS shelf,
				MAX(bin) AS bin,
				MAX(level1) AS level1,
				MAX(level2) AS level2,
				MAX(level3) AS level3,
				MAX(level4) AS level4,
				MAX(level5) AS level5,
				MAX(level6) AS level6,
				MAX(level7) AS level7,
				MAX(level8) AS level8,
				MAX(level9) AS level9,
				MAX(level10) AS level10,
				MAX(masterCompanyId) AS masterCompanyId
			FROM rptCTE
			GROUP BY pn, cond, site 
		)
		SELECT 
			COUNT(1) OVER () AS TotalRecordsCount,
			pn, itemMasterId, pndescription, manufacturer, cond, site,
			stockuom, stocklevel, leadtimedays, reorderpoint, reorderqty, 
			minqtyorder, qtyonhand, qtyonavail, CASE WHEN qtyonavail  <= stocklevel THEN 'YES' ELSE 'NO' END AS reorder
			,CASE 
				WHEN (ISNULL(StockLevel,0) - ISNULL(qtyonavail,0)) > ISNULL(minqtyorder,0)
				THEN (ISNULL(StockLevel,0) - ISNULL(qtyonavail,0)) 
				ELSE ISNULL(minqtyorder,0)
			END AS qtytoorder,
			warehouse, location, shelf, bin,
			level1, level2, level3, level4, level5, level6, level7, level8, level9, level10
		FROM GroupedCTE
		ORDER BY pn DESC
		OFFSET ((@PageNumber - 1) * @PageSize) ROWS
		FETCH NEXT @PageSize ROWS ONLY;

  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[usprpt_GetStockLevelAnalysisReport]',
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