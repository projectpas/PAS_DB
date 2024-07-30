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
	
       
--EXEC [AutoCompleteDropdownsItemMasterWithManufacturer] '725',1,20,'',18  
**************************************************************/
CREATE PROCEDURE [dbo].[AutoCompleteDropdownsItemMasterWithManufacturer]  
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
  
  IF(@IsActive = 1)  
   BEGIN    
     SELECT DISTINCT TOP 20   
		  Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,   
		  Im.partnumber AS PartNumber,   
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
		  Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
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
		  Ic.ItemClassificationCode as ItemClassification 
     FROM dbo.ItemMaster Im WITH(NOLOCK)   
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
		  LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId 
		  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
     WHERE (Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%'))      
     
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
		  Ic.ItemClassificationCode as ItemClassification
     FROM dbo.ItemMaster Im WITH(NOLOCK)   
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK) ON Im.ItemMasterId =  rp.ItemMasterId  
		  LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
		  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
     WHERE im.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))      
	 ORDER BY Label      
   End  
   ELSE  
   BEGIN  
    SELECT DISTINCT TOP 20   
		  Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,   
		  Im.partnumber AS PartNumber,    
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
		  Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
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
		  Ic.ItemClassificationCode as ItemClassification
     FROM dbo.ItemMaster Im WITH(NOLOCK)   
		LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
		LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
    WHERE Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND Im.partnumber LIKE @StartWith + '%'  
    
	UNION   

    SELECT DISTINCT TOP 20   
		  Im.ItemMasterId,  
		  Im.ItemMasterId AS Value,    
		  Im.partnumber AS PartNumber,  
		  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,  
		  Im.PartDescription,   
		  Im.ItemClassificationId,   
		  Im.ManufacturerId,   
		  Im.GLAccountId,  
		  Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,  
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
		  Ic.ItemClassificationCode as ItemClassification
     FROM dbo.ItemMaster Im WITH(NOLOCK)   
		  LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId  
		  LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Ic.ItemClassificationId = Im.ItemClassificationId
		  LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
    WHERE Im.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))  
    ORDER BY Label   
   END  
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