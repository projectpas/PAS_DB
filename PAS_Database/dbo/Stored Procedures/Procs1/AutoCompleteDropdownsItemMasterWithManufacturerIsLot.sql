/*************************************************************             
 ** File:   [AutoCompleteDropdownsItemMasterWithManufacturerIsLot]             
 ** Author:   Rajesh Gami  
 ** Description: This stored procedure is used retrieve Item Master List based on lot with Manufacturer detail for Auto complete Dropdown List      
 ** Purpose:           
 ** Date:   11/16/2023          
            
 ** PARAMETERS: 
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
    1    11/16/2023   AMIT GHEDIYA  Created  
	2    11/17/2023   AMIT GHEDIYA  Updated only Display part which is added in Lot. 
	3    12/07/2023   Rajesh Gami   LOT condition change
	4    06/14/2024   Vishal Suthar	Increased Limit of records from 20 to 50 for Item Master Module
	5    12 Mar 2025  RAJESH GAMI 	Getting the data by module wise    
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	7    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
--EXEC [AutoCompleteDropdownsItemMasterWithManufacturerIsLot] '',1,100,'',1  
**************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[AutoCompleteDropdownsItemMasterWithManufacturerIsLot]  
	@StartWith VARCHAR(50),  
	@IsActive bit = true,  
	@Count VARCHAR(10) = '0',  
	@Idlist VARCHAR(max) = '0',  
	@MasterCompanyId int,
	@ReferenceId BIGINT,
	@ModuleName VARCHAR(30) = '' 
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON    
 BEGIN TRY   
  DECLARE @Sql NVARCHAR(MAX),
		  @LotId BIGINT,
		  @StockLineId VARCHAR(MAX), @RepairModule VARCHAR(30) = 'REPAIRORDER', @SalesModule VARCHAR(30) = 'SALESORDER', @SalesQuoteModule VARCHAR(30) = 'SALESORDERQUOTE';
		

  IF(UPPER(@ModuleName) = @RepairModule)
  BEGIN
		SET @LotId = (SELECT LotId FROM dbo.RepairOrder WITH(NOLOCK) where RepairOrderId = @ReferenceId);
		SET @StockLineId = (SELECT ',' + CAST(StockLineId AS VARCHAR(256)) from DBO.LotTransInOutDetails WITH(NOLOCK) WHERE LotId = @LotId for XML PATH(''));
	 IF(@IsActive = 1)  
	   BEGIN    
		 SELECT DISTINCT TOP 50   
		  Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,   
		  Im.partnumber AS PartNumber,   
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
			 Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
		  Im.Figure,  
		  Im.Item,  
		  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId AND ISNULL(SL.IsNonStock,0) = 0),  
		  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
			WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
			WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
			ELSE 'OEM'  
		  END AS StockType,  
		  M.Name As Manufacturer,  
		  isnull(rp. RevisedPart,'')  AS RevisedPart,  
		  Im.isSerialized AS IsSerialized,  
		  Im.isTimeLife AS IsTimeLife,  
		  ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND ISNULL(s.IsNonStock,0) = 0),
		  Ic.ItemClassificationCode as ItemClassification 
		 FROM dbo.ItemMaster Im WITH(NOLOCK)   
		  INNER JOIN dbo.Stockline stl WITH(NOLOCK) ON Im.ItemMasterId = stl.ItemMasterId AND ISNULL(stl.LotId,0) >0 AND stl.StockLineId in(SELECT Item FROM dbo.SplitString(@StockLineId, ','))
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
		   AND ISNULL(rp.IsNonStock,0) = 0
		   LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId 
		  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		 WHERE (Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%'))      
		   AND ISNULL(Im.IsNonStock,0) = 0 AND ISNULL(stl.IsNonStock,0) = 0
		  UNION       
		 SELECT DISTINCT Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,   
		  Im.partnumber AS PartNumber,   
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
			 Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
		  Im.Figure,  
		  Im.Item,  
		  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId AND ISNULL(SL.IsNonStock,0) = 0),  
		  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
			WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
			WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
			ELSE 'OEM'  
		  END AS StockType,  
		  M.Name As Manufacturer,  
		  isnull(rp. RevisedPart, '')  AS RevisedPart,  
		  Im.isSerialized AS IsSerialized,  
		  Im.isTimeLife AS IsTimeLife,  
		  ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND ISNULL(s.IsNonStock,0) = 0),
		  Ic.ItemClassificationCode as ItemClassification
		 FROM dbo.ItemMaster Im WITH(NOLOCK)   
		  INNER JOIN dbo.Stockline stl WITH(NOLOCK) ON Im.ItemMasterId = stl.ItemMasterId AND ISNULL(stl.LotId,0) >0 AND stl.StockLineId in(SELECT Item FROM dbo.SplitString(@StockLineId, ','))
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK) ON Im.ItemMasterId =  rp.ItemMasterId  
		   AND ISNULL(rp.IsNonStock,0) = 0
		   LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
		  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		 WHERE im.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))      
		 AND ISNULL(Im.IsNonStock,0) = 0 AND ISNULL(stl.IsNonStock,0) = 0
		  ORDER BY Label      
	   End  
	   ELSE  
	   BEGIN  
		SELECT DISTINCT TOP 50   
		  Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,   
		  Im.partnumber AS PartNumber,    
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
			 Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
		  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId AND ISNULL(SL.IsNonStock,0) = 0),  
		  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
			WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
			WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
			ELSE 'OEM'  
		  END AS StockType,  
		  M.Name As Manufacturer,  
		  isnull(rp. RevisedPart, '')  AS RevisedPart,  
		  Im.isSerialized AS IsSerialized,  
		  Im.isTimeLife AS IsTimeLife,  
		  ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND ISNULL(s.IsNonStock,0) = 0),
		  Ic.ItemClassificationCode as ItemClassification
		 FROM dbo.ItemMaster Im WITH(NOLOCK)   
		  INNER JOIN dbo.Stockline stl WITH(NOLOCK) ON Im.ItemMasterId = stl.ItemMasterId AND ISNULL(stl.LotId,0) >0 AND stl.RepairOrderId = @ReferenceId
		  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
		   AND ISNULL(rp.IsNonStock,0) = 0
		   LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
		WHERE ISNULL(Im.IsNonStock,0) = 0 AND ( Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND Im.partnumber LIKE '%' + @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%'  
		) AND ISNULL(stl.IsNonStock,0) = 0 UNION   
		SELECT DISTINCT TOP 50   
		  Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,    
		  Im.partnumber AS PartNumber,  
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
			 Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
		  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId AND ISNULL(SL.IsNonStock,0) = 0),  
		  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
			WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
			WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
			ELSE 'OEM'  
		  END AS StockType,  
		  M.Name As Manufacturer,  
		  isnull(rp. RevisedPart, '')  AS RevisedPart,  
		  Im.isSerialized AS IsSerialized,  
		  Im.isTimeLife AS IsTimeLife,  
		  ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND ISNULL(s.IsNonStock,0) = 0),
		  Ic.ItemClassificationCode as ItemClassification
		 FROM dbo.ItemMaster Im WITH(NOLOCK)    
		  INNER JOIN dbo.Stockline stl WITH(NOLOCK) ON Im.ItemMasterId = stl.ItemMasterId AND ISNULL(stl.LotId,0) >0 AND stl.RepairOrderId = @ReferenceId
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
		   AND ISNULL(rp.IsNonStock,0) = 0
		   LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		  LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
		WHERE Im.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))  
		 AND ISNULL(Im.IsNonStock,0) = 0 AND ISNULL(stl.IsNonStock,0) = 0
		 ORDER BY Label  
	 END
  END
  ELSE IF(UPPER(@ModuleName) = @SalesModule)
  BEGIN
		SET @LotId = (SELECT LotId FROM dbo.SalesOrder WITH(NOLOCK) where SalesOrderId = @ReferenceId);
		SET @StockLineId = (SELECT ',' + CAST(StockLineId AS VARCHAR(256)) from DBO.LotTransInOutDetails WITH(NOLOCK) WHERE LotId = @LotId for XML PATH(''));
  END
  ELSE IF(UPPER(@ModuleName) = @SalesQuoteModule)
  BEGIN
		SET @LotId = (SELECT LotId FROM dbo.SalesOrderQuote WITH(NOLOCK) where SalesOrderQuoteId = @ReferenceId);
		SET @StockLineId = (SELECT ',' + CAST(StockLineId AS VARCHAR(256)) from DBO.LotTransInOutDetails WITH(NOLOCK) WHERE LotId = @LotId for XML PATH(''));
  END
  IF(UPPER(@ModuleName) = @SalesModule OR UPPER(@ModuleName) = @SalesQuoteModule)
  BEGIN
		SELECT DISTINCT TOP 50   
		  Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,   
		  Im.partnumber AS PartNumber,   
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
			 Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
		  Im.Figure,  
		  Im.Item,  
		  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId AND ISNULL(SL.IsNonStock,0) = 0),  
		  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
			WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
			WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
			ELSE 'OEM'  
		  END AS StockType,  
		  M.Name As Manufacturer,  
		  isnull(rp. RevisedPart,'')  AS RevisedPart,  
		  Im.isSerialized AS IsSerialized,  
		  Im.isTimeLife AS IsTimeLife,  
		  ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND ISNULL(s.IsNonStock,0) = 0),
		  Ic.ItemClassificationCode as ItemClassification 
		 FROM dbo.ItemMaster Im WITH(NOLOCK)   
		  INNER JOIN dbo.Stockline stl WITH(NOLOCK) ON Im.ItemMasterId = stl.ItemMasterId AND ISNULL(stl.LotId,0) >0 AND stl.StockLineId in(SELECT Item FROM dbo.SplitString(@StockLineId, ','))
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
		   AND ISNULL(rp.IsNonStock,0) = 0
		   LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId 
		  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		 WHERE (Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%'))      
		   AND ISNULL(Im.IsNonStock,0) = 0 AND ISNULL(stl.IsNonStock,0) = 0
		  UNION       
		 SELECT DISTINCT Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,   
		  Im.partnumber AS PartNumber,   
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
			 Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
		  Im.Figure,  
		  Im.Item,  
		  UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId AND ISNULL(SL.IsNonStock,0) = 0),  
		  CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'  
			WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'  
			WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'  
			ELSE 'OEM'  
		  END AS StockType,  
		  M.Name As Manufacturer,  
		  isnull(rp. RevisedPart, '')  AS RevisedPart,  
		  Im.isSerialized AS IsSerialized,  
		  Im.isTimeLife AS IsTimeLife,  
		  ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND ISNULL(s.IsNonStock,0) = 0),
		  Ic.ItemClassificationCode as ItemClassification
		 FROM dbo.ItemMaster Im WITH(NOLOCK)   
		  INNER JOIN dbo.Stockline stl WITH(NOLOCK) ON Im.ItemMasterId = stl.ItemMasterId AND ISNULL(stl.LotId,0) >0 AND stl.StockLineId in(SELECT Item FROM dbo.SplitString(@StockLineId, ','))
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK) ON Im.ItemMasterId =  rp.ItemMasterId  
		   AND ISNULL(rp.IsNonStock,0) = 0
		   LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
		  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		 WHERE im.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))      
		 AND ISNULL(Im.IsNonStock,0) = 0 AND ISNULL(stl.IsNonStock,0) = 0
		  ORDER BY Label   
  END



 END TRY   
 BEGIN CATCH       
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsItemMasterWithManufacturerIsLot'                 
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