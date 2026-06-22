
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
	4    07/26/2024   Vishal Suthar		Modified StartWith condition and removed join with stockline table to improve the performance
	5    08/12/2024   Devendra Shekh	Modified to select UnitOfMeasure
	6    09/06/2024   Moin Bloch	    Modified (Added Site,WareHouse,LocationId,ShelfId,BinId,IsExpirationDateAvailable)	
	7    30/01/2025   Shrey Chandegara  Modified due to add itemgroup
	8    06/01/2026   Rajesh Gami		UOM Conversion: Return related fields (Stock,Consume Qty and Cost)
	9    08/01/2026   Rajesh Gami		Added MasterCompanyId Parameter While Calling UOM Conversion Function
	10   18/06/2026   Ayushi			[PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
--EXEC [AutoCompleteDropdownsItemMasterWithManufacturer] '725',1,20,'',18  
EXEC [AutoCompleteDropdownsItemMasterWithManufacturer] 'Gal',1,50,'',1  
**************************************************************/
CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsItemMasterWithManufacturer]  
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
  
      IF OBJECT_ID(N'tempdb..#TempTable_DropDown') IS NOT NULL
      BEGIN
          DROP TABLE #TempTable_DropDown
      END

		  CREATE TABLE #TempTable_DropDown (
			ItemMasterId BIGINT,
			Value BIGINT,
			PartNumber VARCHAR(255),
			Label VARCHAR(255),
			PartDescription VARCHAR(MAX),
			ItemClassificationId BIGINT,
			ManufacturerId BIGINT,
			GLAccountId BIGINT,
			UnitOfMeasureId BIGINT,
			UnitOfMeasure VARCHAR(100),
			Figure VARCHAR(100),
			Item VARCHAR(255),
			UnitCost DECIMAL(18, 6),
			StockType VARCHAR(100),
			Manufacturer VARCHAR(MAX),
			RevisedPart VARCHAR(255),
			IsSerialized BIT,
			IsTimeLife BIT,
			ConditionId BIGINT,
			ItemClassification VARCHAR(100),
			SiteId BIGINT,
			WarehouseId BIGINT,
			LocationId BIGINT,
			ShelfId BIGINT,
			BinId BIGINT,
			IsExpirationDateAvailable BIT,
			ItemGroup VARCHAR(50),
			StockUnitOfMeasureId BIGINT,
			StockUnitOfMeasure VARCHAR(100),
			ConsumeUnitOfMeasureId BIGINT,
			ConsumeUnitOfMeasure VARCHAR(100),
			ConsumeUnitCost DECIMAL(18, 6),
			ConsumeQuanity DECIMAL(18, 6) NULL
		);


  IF(@IsActive = 1)  
   BEGIN    
	INSERT INTO #TempTable_DropDown (
				ItemMasterId,
				Value,
				PartNumber,
				Label,
				PartDescription,
				ItemClassificationId,
				ManufacturerId,
				GLAccountId,
				UnitOfMeasureId,
				UnitOfMeasure,
				Figure,
				Item,
				UnitCost,
				StockType,
				Manufacturer,
				RevisedPart,
				IsSerialized,
				IsTimeLife,
				ConditionId,
				ItemClassification,
				SiteId,
				WarehouseId,
				LocationId,
				ShelfId,
				BinId,
				IsExpirationDateAvailable,
				ItemGroup,
				StockUnitOfMeasureId,
				StockUnitOfMeasure,
				ConsumeUnitOfMeasureId,
				ConsumeUnitOfMeasure,
				ConsumeUnitCost
			)

     SELECT DISTINCT TOP 50   
		  Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,   
		  Im.partnumber AS PartNumber,   
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
		  Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
		  uom.ShortName AS UnitOfMeasure,
		  Im.Figure,  
		  Im.Item,  
		  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) Where imps.ItemMasterId = im.ItemMasterId),  
		  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
			WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
			WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
			ELSE 'OEM'  
		  END AS StockType,  
		  M.Name As Manufacturer,  
		  isnull(rp. RevisedPart,'')  AS RevisedPart,  
		  Im.isSerialized AS IsSerialized,  
		  Im.isTimeLife AS IsTimeLife,  
		  ConditionId = (select top 1 imp.ConditionId from dbo.ItemMasterPurchaseSale imp with(NoLock) Where imp.ItemMasterId = im.ItemMasterId),
		  Ic.ItemClassificationCode as ItemClassification,
		  Im.SiteId,
		  Im.WarehouseId,
		  Im.LocationId,
		  Im.ShelfId,
		  Im.BinId,
		  Im.IsExpirationDateAvailable,
		  Ig.ItemGroupCode As ItemGroup,
		  Im.StockUnitOfMeasureId AS StockUnitOfMeasureId,  
		  uomStock.ShortName AS StockUnitOfMeasure,
		  Im.ConsumeUnitOfMeasureId AS ConsumeUnitOfMeasureId,  
		  uomConsume.ShortName AS ConsumeUnitOfMeasure,
		  0 as ConsumeUnitCost
     FROM dbo.ItemMaster Im WITH(NOLOCK)   
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
		  LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId 
		  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		  LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK)  ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
		  LEFT JOIN dbo.UnitOfMeasure uomStock WITH(NOLOCK)  ON Im.StockUnitOfMeasureId = uomStock.UnitOfMeasureId
		  LEFT JOIN dbo.UnitOfMeasure uomConsume WITH(NOLOCK)  ON Im.ConsumeUnitOfMeasureId = uomConsume.UnitOfMeasureId
		  LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK)  ON Im.ItemGroupId =  Ig.ItemGroupId
     WHERE (ISNULL(Im.IsActive,0) = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE  @StartWith + '%'))      
     
	 UNION   
	 
     SELECT DISTINCT Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,   
		  Im.partnumber AS PartNumber,   
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
		  Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
		  uom.ShortName AS UnitOfMeasure,
		  Im.Figure,  
		  Im.Item,  
		  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) Where imps.ItemMasterId = im.ItemMasterId),  
		  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
			WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
			WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
			ELSE 'OEM'  
		  END AS StockType,  
		  M.Name As Manufacturer,  
		  isnull(rp. RevisedPart, '')  AS RevisedPart,  
		  Im.isSerialized AS IsSerialized,  
		  Im.isTimeLife AS IsTimeLife,  
		  ConditionId = (select top 1 imp.ConditionId from dbo.ItemMasterPurchaseSale imp with(NoLock) Where imp.ItemMasterId = im.ItemMasterId),
		  Ic.ItemClassificationCode as ItemClassification,
		  Im.SiteId,
		  Im.WarehouseId,
		  Im.LocationId,
		  Im.ShelfId,
		  Im.BinId,
		  Im.IsExpirationDateAvailable,
		  Ig.ItemGroupCode As ItemGroup,
		  Im.StockUnitOfMeasureId AS StockUnitOfMeasureId,  
		  uomStock.ShortName AS StockUnitOfMeasure,
		  Im.ConsumeUnitOfMeasureId AS ConsumeUnitOfMeasureId,  
		  uomConsume.ShortName AS ConsumeUnitOfMeasure,
		  0 as ConsumeUnitCost
     FROM dbo.ItemMaster Im WITH(NOLOCK)   
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK) ON Im.ItemMasterId =  rp.ItemMasterId  
		  LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
		  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		  LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK)  ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
		  LEFT JOIN dbo.UnitOfMeasure uomStock WITH(NOLOCK)  ON Im.StockUnitOfMeasureId = uomStock.UnitOfMeasureId
		  LEFT JOIN dbo.UnitOfMeasure uomConsume WITH(NOLOCK)  ON Im.ConsumeUnitOfMeasureId = uomConsume.UnitOfMeasureId
		  LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK)  ON Im.ItemGroupId =  Ig.ItemGroupId
     WHERE im.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))      
	 ORDER BY Label      
   End  
   ELSE  
   BEGIN
		INSERT INTO #TempTable_DropDown (
				ItemMasterId,
				Value,
				PartNumber,
				Label,
				PartDescription,
				ItemClassificationId,
				ManufacturerId,
				GLAccountId,
				UnitOfMeasureId,
				UnitOfMeasure,
				Figure,
				Item,
				UnitCost,
				StockType,
				Manufacturer,
				RevisedPart,
				IsSerialized,
				IsTimeLife,
				ConditionId,
				ItemClassification,
				SiteId,
				WarehouseId,
				LocationId,
				ShelfId,
				BinId,
				IsExpirationDateAvailable,
				ItemGroup,
				StockUnitOfMeasureId,
				StockUnitOfMeasure,
				ConsumeUnitOfMeasureId,
				ConsumeUnitOfMeasure,
				ConsumeUnitCost
			)

		SELECT DISTINCT TOP 50   
		  Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,   
		  Im.partnumber AS PartNumber,    
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
		  Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
		  uom.ShortName AS UnitOfMeasure,
		  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) Where imps.ItemMasterId = im.ItemMasterId),  
		  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
			WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
			WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
			ELSE 'OEM'  
		  END AS StockType,  
		  M.Name As Manufacturer,  
		  isnull(rp. RevisedPart, '')  AS RevisedPart,  
		  Im.isSerialized AS IsSerialized,  
		  Im.isTimeLife AS IsTimeLife,  
		  ConditionId = (select top 1 imp.ConditionId from dbo.ItemMasterPurchaseSale imp with(NoLock) Where imp.ItemMasterId = im.ItemMasterId),
		  Ic.ItemClassificationCode as ItemClassification,
		  Im.SiteId,
		  Im.WarehouseId,
		  Im.LocationId,
		  Im.ShelfId,
		  Im.BinId,
		  Im.IsExpirationDateAvailable,
		  Ig.ItemGroupCode As ItemGroup,
		  Im.StockUnitOfMeasureId AS StockUnitOfMeasureId,  
		  uomStock.ShortName AS StockUnitOfMeasure,
		  Im.ConsumeUnitOfMeasureId AS ConsumeUnitOfMeasureId,  
		  uomConsume.ShortName AS ConsumeUnitOfMeasure,
		  0 as ConsumeUnitCost
     FROM dbo.ItemMaster Im WITH(NOLOCK)   
		LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
		LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
		LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK)  ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
		LEFT JOIN dbo.UnitOfMeasure uomStock WITH(NOLOCK)  ON Im.StockUnitOfMeasureId = uomStock.UnitOfMeasureId
		LEFT JOIN dbo.UnitOfMeasure uomConsume WITH(NOLOCK)  ON Im.ConsumeUnitOfMeasureId = uomConsume.UnitOfMeasureId
		LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK)  ON Im.ItemGroupId =  Ig.ItemGroupId
    WHERE Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND Im.partnumber LIKE  @StartWith + '%'  
    
	UNION   

    SELECT DISTINCT TOP 50   
		  Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,    
		  Im.partnumber AS PartNumber,  
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
		  Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
		  uom.ShortName AS UnitOfMeasure,
		  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) Where imps.ItemMasterId = im.ItemMasterId),  
		  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
			WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
			WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
			ELSE 'OEM'  
		  END AS StockType,  
		  M.Name As Manufacturer,  
		  isnull(rp. RevisedPart, '')  AS RevisedPart,  
		  Im.isSerialized AS IsSerialized,  
		  Im.isTimeLife AS IsTimeLife,  
		  ConditionId = (select top 1 imp.ConditionId from dbo.ItemMasterPurchaseSale imp with(NoLock) Where imp.ItemMasterId = im.ItemMasterId),
		  Ic.ItemClassificationCode as ItemClassification,
		  Im.SiteId,
		  Im.WarehouseId,
		  Im.LocationId,
		  Im.ShelfId,
		  Im.BinId,
		  Im.IsExpirationDateAvailable,
		  Ig.ItemGroupCode As ItemGroup,
		  Im.StockUnitOfMeasureId AS StockUnitOfMeasureId,  
		  uomStock.ShortName AS StockUnitOfMeasure,
		  Im.ConsumeUnitOfMeasureId AS ConsumeUnitOfMeasureId,  
		  uomConsume.ShortName AS ConsumeUnitOfMeasure,
		  0 as ConsumeUnitCost
     FROM dbo.ItemMaster Im WITH(NOLOCK)   
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
		  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		  LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
		  LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK)  ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
		  LEFT JOIN dbo.UnitOfMeasure uomStock WITH(NOLOCK)  ON Im.StockUnitOfMeasureId = uomStock.UnitOfMeasureId
		  LEFT JOIN dbo.UnitOfMeasure uomConsume WITH(NOLOCK)  ON Im.ConsumeUnitOfMeasureId = uomConsume.UnitOfMeasureId
		  LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK)  ON Im.ItemGroupId =  Ig.ItemGroupId
    WHERE Im.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))  
    ORDER BY Label   
   END  
   UPDATE #TempTable_DropDown SET ConsumeUnitCost = CASE 
														WHEN ISNULL(UnitOfMeasure, '') = ISNULL(ConsumeUnitOfMeasure, '') 
														THEN UnitCost
														ELSE dbo.fn_ConvertUOM(UnitCost, UnitOfMeasure, ConsumeUnitOfMeasure, 1, 0)
													END,
								  ConsumeQuanity  = CASE 
														WHEN ISNULL(UnitOfMeasure, '') = ISNULL(ConsumeUnitOfMeasure, '') 
														THEN 1
														ELSE dbo.fn_ConvertUOM(1, UnitOfMeasure, ConsumeUnitOfMeasure, 0, 0)
													END
   Select * from #TempTable_DropDown
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