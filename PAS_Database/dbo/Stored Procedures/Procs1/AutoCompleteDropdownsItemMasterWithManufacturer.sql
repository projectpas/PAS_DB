/*************************************************************             
 ** File:   [AutoCompleteDropdownsItemMasterWithManufacturer]             
 ** Author:   Rajesh Gami  
 ** Description: This stored procedure is used retrieve Item Master List with Manufacturer detail for Auto complete Dropdown List      
 ** Purpose:           
 ** Date:   15/02/2023          
            
 ** PARAMETERS: @UserType varchar(60)     
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    15/02/2023   Rajesh Gami		Created  
	2    06/14/2024   Vishal Suthar		Increased Limit of records from 20 to 50 for Item Master Module
	3    07/26/2024   Hemant Saliya		Updated for Performance Improvement
       
--EXEC [AutoCompleteDropdownsItemMasterWithManufacturer] '',1,50,'',1  
**************************************************************/
CREATE     PROCEDURE [dbo].[AutoCompleteDropdownsItemMasterWithManufacturer]  
@StartWith VARCHAR(50),  
@IsActive bit = true,  
@Count VARCHAR(10) = '0',  
@Idlist VARCHAR(max) = '0',  
@MasterCompanyId int  
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON    
	BEGIN TRY   
		DECLARE @Sql NVARCHAR(MAX);   

		IF OBJECT_ID(N'tempdb..#tmpItemMasterList') IS NOT NULL
		BEGIN
		DROP TABLE #tmpItemMasterList
		END

		CREATE TABLE #tmpItemMasterList
		(
			ID BIGINT NOT NULL IDENTITY, 	
			[ItemMasterId] [bigint] NULL,
			[Value] [bigint] NULL,
			[PartNumber] [varchar](200) NULL,
			[Label] [varchar](200) NULL,
			[PartDescription] [varchar](MAX) NULL,
			[ItemClassificationId] [bigint] NULL,   
			[ManufacturerId] [bigint] NULL,
			[GLAccountId] [bigint] NULL,
			[UnitOfMeasureId] [bigint] NULL,  
			[Figure] [varchar](MAX) NULL, 
			[Item] [varchar](MAX) NULL,
			[UnitCost] [decimal](18, 2) NULL,
			[StockType] [varchar](20) NULL,
			[Manufacturer] [varchar](200) NULL,
			[RevisedPart] [varchar](200) NULL,
			[IsSerialized] [bit] NULL,
			[IsTimeLife] [bit] NULL,
			[ConditionId] [bigint] NULL,
			[ItemClassification] [varchar](250) NULL,
		)
  
		IF(@IsActive = 1)  
		 BEGIN
			PRINT '1'
			 INSERT INTO #tmpItemMasterList(ItemMasterId, [Value], PartNumber, PartDescription, ItemClassificationId, ManufacturerId, GLAccountId, 
						UnitOfMeasureId, Figure, Item, StockType, Manufacturer, RevisedPart, IsSerialized, IsTimeLife, ItemClassification)
			 SELECT DISTINCT TOP 50   
				  Im.ItemMasterId,  
				  Im.ItemMasterId AS Value,   
				  Im.partnumber AS PartNumber,   
				  --im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
				  Im.PartDescription,   
				  Im.ItemClassificationId,   
				  Im.ManufacturerId,   
				  Im.GLAccountId,  
				  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
				  Im.Figure,  
				  Im.Item,  
				  --UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId),  
				  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
					WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
					WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
					ELSE 'OEM'  
				  END AS StockType,  
				  M.Name As Manufacturer,  
				  ISNULL(rp. RevisedPart,'')  AS RevisedPart,  
				  Im.isSerialized AS IsSerialized,  
				  Im.isTimeLife AS IsTimeLife,  
				  --ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId),
				  Ic.ItemClassificationCode as ItemClassification 
			 FROM dbo.ItemMaster Im WITH(NOLOCK)   
				  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
				  LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId 
				  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
			 WHERE (Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%'))      
		
			PRINT '1.1'
			INSERT INTO #tmpItemMasterList(ItemMasterId, [Value], PartNumber, PartDescription, ItemClassificationId, ManufacturerId, GLAccountId, 
						UnitOfMeasureId, Figure, Item, StockType, Manufacturer, RevisedPart, IsSerialized, IsTimeLife, ItemClassification)
			 SELECT DISTINCT 
				  Im.ItemMasterId,  
				  Im.ItemMasterId AS Value,   
				  Im.partnumber AS PartNumber,   
				  --im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
				  Im.PartDescription,   
				  Im.ItemClassificationId,   
				  Im.ManufacturerId,   
				  Im.GLAccountId,  
				  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
				  Im.Figure,  
				  Im.Item,  
				  --UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId),  
				  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
					WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
					WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
					ELSE 'OEM'  
				  END AS StockType,  
				  M.Name As Manufacturer,  
				  ISNULL(rp. RevisedPart, '')  AS RevisedPart,  
				  Im.isSerialized AS IsSerialized,  
				  Im.isTimeLife AS IsTimeLife,  
				  --ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId),
				  Ic.ItemClassificationCode as ItemClassification
			 FROM dbo.ItemMaster Im WITH(NOLOCK)   
				  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK) ON Im.ItemMasterId =  rp.ItemMasterId  
				  LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
				  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
			 WHERE im.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))      
			ORDER BY PartNumber
			
			PRINT '1.2'

			UPDATE #tmpItemMasterList 
				SET [Label] = tmpIM.PartNumber + (CASE WHEN (SELECT COUNT(ISNULL(IM.[ManufacturerId], 0)) FROM [dbo].[ItemMaster] IM WITH(NOLOCK)  WHERE tmpIM.PartNumber = IM.partnumber AND IM.MasterCompanyId = @MasterCompanyId) > 1 THEN ' - '+ M.[Name] ELSE '' END), 
					UnitCost = (SELECT TOP 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps WITH(NOLOCK) INNER JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.ItemMasterId = tmpIM.ItemMasterId AND SL.ConditionId = imps.ConditionId WHERE imps.ItemMasterId = tmpIM.ItemMasterId),
					ConditionId = (SELECT TOP 1 s.ConditionId FROM dbo.Stockline s WITH(NOLOCK) WHERE s.ItemMasterId = tmpIM.ItemMasterId)
			FROM #tmpItemMasterList tmpIM 
				LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON tmpIM.ManufacturerId = M.ManufacturerId  
			
			PRINT '1.3'
		 END  
		 ELSE  
		 BEGIN  
			INSERT INTO #tmpItemMasterList(ItemMasterId, [Value], PartNumber, PartDescription, ItemClassificationId, ManufacturerId, GLAccountId, 
						UnitOfMeasureId, Figure, Item, StockType, Manufacturer, RevisedPart, IsSerialized, IsTimeLife, ItemClassification)
			SELECT DISTINCT TOP 50   
				  Im.ItemMasterId,  
				  Im.ItemMasterId AS Value,   
				  Im.partnumber AS PartNumber,    
				 -- im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
				  Im.PartDescription,   
				  Im.ItemClassificationId,   
				  Im.ManufacturerId,   
				  Im.GLAccountId,  
				  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
				  Im.Figure,  
				  Im.Item,  
				  --UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId),  
				  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
					WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
					WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
					ELSE 'OEM'  
				  END AS StockType,  
				  M.Name As Manufacturer,  
				  isnull(rp. RevisedPart, '')  AS RevisedPart,  
				  Im.isSerialized AS IsSerialized,  
				  Im.isTimeLife AS IsTimeLife,  
				  --ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId),
				  Ic.ItemClassificationCode as ItemClassification
			FROM dbo.ItemMaster Im WITH(NOLOCK)   
				LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
				LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
				LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
			WHERE Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND Im.partnumber LIKE '%' + @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%'  
			
			INSERT INTO #tmpItemMasterList(ItemMasterId, [Value], PartNumber, PartDescription, ItemClassificationId, ManufacturerId, GLAccountId, 
						UnitOfMeasureId, Figure, Item, StockType, Manufacturer, RevisedPart, IsSerialized, IsTimeLife, ItemClassification)   
			SELECT DISTINCT TOP 20   
				  Im.ItemMasterId,  
				  Im.ItemMasterId AS Value,    
				  Im.partnumber AS PartNumber,  
				  --im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
				  Im.PartDescription,   
				  Im.ItemClassificationId,   
				  Im.ManufacturerId,   
				  Im.GLAccountId,  
				  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
				  Im.Figure,  
				  Im.Item,  
				  --UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId),  
				  CASE	WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
						WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
						WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
						ELSE 'OEM'  
				  END AS StockType,  
				  M.Name As Manufacturer,  
				  ISNULL(rp. RevisedPart, '')  AS RevisedPart,  
				  Im.isSerialized AS IsSerialized,  
				  Im.isTimeLife AS IsTimeLife,  
				  --ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId),
				  Ic.ItemClassificationCode as ItemClassification
			 FROM dbo.ItemMaster Im WITH(NOLOCK)   
				  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
				  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
				  LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
			WHERE Im.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))  
			ORDER BY PartNumber   

			UPDATE #tmpItemMasterList 
				SET [Label] = tmpIM.PartNumber + (CASE WHEN (SELECT COUNT(ISNULL(IM.[ManufacturerId], 0)) FROM [dbo].[ItemMaster] IM WITH(NOLOCK)  WHERE tmpIM.PartNumber = IM.partnumber AND IM.MasterCompanyId = @MasterCompanyId) > 1 THEN ' - '+ M.[Name] ELSE '' END), 
					UnitCost = (SELECT TOP 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps WITH(NOLOCK) INNER JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.ItemMasterId = tmpIM.ItemMasterId AND SL.ConditionId = imps.ConditionId WHERE imps.ItemMasterId = tmpIM.ItemMasterId),
					ConditionId = (SELECT TOP 1 s.ConditionId FROM dbo.Stockline s WITH(NOLOCK) WHERE s.ItemMasterId = tmpIM.ItemMasterId)
			FROM #tmpItemMasterList tmpIM 
				LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON tmpIM.ManufacturerId = M.ManufacturerId
		END
	   
	   SELECT * FROM #tmpItemMasterList ORDER BY [Label]


	 END TRY   
 BEGIN CATCH       
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsItemMasterWithManufacturer'                 
     ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))  
      + '@Parameter2 = ''' + CAST(ISNULL(@IsActive, '') as varchar(100))   
      + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))  
      + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))    
      + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))     
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
 END CATCH   
END