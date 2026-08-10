
/*************************************************************           
 ** File:   [AutoCompleteDropdownsItemMaster]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Item Master List for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   12/23/2020        
          
 ** PARAMETERS: @UserType varchar(60)   
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    12/23/2020   Hemant Saliya		Created
    2    06/14/2024   Vishal Suthar		Increase limit of records from 20 to 50
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	4    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
    5    05-Aug-2026             Bhargav Saliya                     [PN-17562] Part Number search (Item Master dropdown): normalize dashes/slashes
--EXEC [AutoCompleteDropdownsItemMaster] '822',1,200,'108,109,11',1
**************************************************************/
CREATE    PROCEDURE [dbo].[AutoCompleteDropdownsItemMaster]
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
					SELECT DISTINCT TOP 50 
						Im.ItemMasterId AS Value, 
						Im.partnumber AS Label,	
						im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = Im.MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS Partnumber,
						Im.PartDescription, 
						Im.ItemClassificationId, 
						Im.ManufacturerId, 
						Im.GLAccountId,
						Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
						uom.ShortName AS UnitOfMeasure, 
						Im.Figure,
						Im.Item,
						UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId AND ISNULL(SL.IsNonStock,0) = 0),
						Ig.ItemGroupCode As ItemGroup,
						CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
							 WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
							 WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
							 ELSE 'OEM'
						END AS StockType,
						Ic.Description AS ItemClassification,
						M.Name As Manufacturer,
						GL.AccountCode + '-' + GL.AccountName AS GlAccount,
						isnull(rp. RevisedPart,'')  AS RevisedPart,
						Im.isSerialized AS IsSerialized,
						Im.isTimeLife AS IsTimeLife,
						ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND ISNULL(s.IsNonStock,0) = 0)
					FROM dbo.ItemMaster Im WITH(NOLOCK) 
						LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId
						 AND ISNULL(rp.IsNonStock,0) = 0
						 JOIN dbo.UnitOfMeasure uom WITH(NOLOCK)  ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
						LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK)  ON Im.ItemGroupId =  Ig.ItemGroupId
						LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK)  ON Im.ItemClassificationId = Ic.ItemClassificationId
						LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
						LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON Im.GLAccountId = GL.GLAccountId
					WHERE (Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') LIKE '%' + REPLACE(REPLACE(REPLACE(REPLACE(@StartWith, '-', ''), '/', ''), '_', ''), '\', '') + '%'))
			    AND ISNULL(Im.IsNonStock,0) = 0
					 UNION     
					SELECT DISTINCT Im.ItemMasterId AS Value, 
						Im.partnumber AS Label,	
						im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = Im.MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS Partnumber,
						Im.PartDescription, 
						Im.ItemClassificationId, 
						Im.ManufacturerId, 
						Im.GLAccountId,
						Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
						uom.ShortName AS UnitOfMeasure,
						Im.Figure,
						Im.Item,
						UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId AND ISNULL(SL.IsNonStock,0) = 0),
						Ig.ItemGroupCode As ItemGroup,
						CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
							 WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
							 WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
							 ELSE 'OEM'
						END AS StockType,
						Ic.Description AS ItemClassification,
						M.Name As Manufacturer,
						GL.AccountCode + '-' + GL.AccountName AS GlAccount,
						isnull(rp. RevisedPart, '')  AS RevisedPart,
						Im.isSerialized AS IsSerialized,
						Im.isTimeLife AS IsTimeLife,
						ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND ISNULL(s.IsNonStock,0) = 0)
					FROM dbo.ItemMaster Im WITH(NOLOCK) 
						LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK) ON Im.ItemMasterId =  rp.ItemMasterId
						 AND ISNULL(rp.IsNonStock,0) = 0
						 JOIN dbo.UnitOfMeasure uom WITH(NOLOCK) ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
						LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK) ON Im.ItemGroupId =  Ig.ItemGroupId
						LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Im.ItemClassificationId = Ic.ItemClassificationId
						LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
						LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON Im.GLAccountId = GL.GLAccountId
					WHERE im.ItemMasterId in (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
				 AND ISNULL(Im.IsNonStock,0) = 0
					 ORDER BY Label				
			End
			ELSE
			BEGIN
				SELECT DISTINCT TOP 50 
						Im.ItemMasterId AS Value, 
						Im.partnumber AS Label,	
						im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = Im.MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS Partnumber,
						Im.PartDescription, 
						Im.ItemClassificationId, 
						Im.ManufacturerId, 
						Im.GLAccountId,
						Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
						uom.ShortName AS UnitOfMeasure, 
						--imps.PP_UnitPurchasePrice AS UnitCost,
						UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId AND ISNULL(SL.IsNonStock,0) = 0),
						Ig.ItemGroupCode As ItemGroup,
						CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
							 WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
							 WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
							 ELSE 'OEM'
						END AS StockType,
						Ic.Description AS ItemClassification,
						M.Name As Manufacturer,
						GL.AccountCode + '-' + GL.AccountName AS GlAccount,
						isnull(rp. RevisedPart, '')  AS RevisedPart,
						Im.isSerialized AS IsSerialized,
						Im.isTimeLife AS IsTimeLife,
						ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND ISNULL(s.IsNonStock,0) = 0)
					FROM dbo.ItemMaster Im WITH(NOLOCK) 
						LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId
						 AND ISNULL(rp.IsNonStock,0) = 0
						 JOIN dbo.UnitOfMeasure uom WITH(NOLOCK)  ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
						LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK)  ON Im.ItemGroupId =  Ig.ItemGroupId
						LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK)  ON Im.ItemClassificationId = Ic.ItemClassificationId
						LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
						LEFT JOIN dbo.GLAccount GL WITH(NOLOCK)  ON Im.GLAccountId = GL.GLAccountId
				WHERE ISNULL(Im.IsNonStock,0) = 0 AND ( Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND Im.partnumber LIKE '%' + @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%' OR REPLACE(REPLACE(REPLACE(REPLACE(Im.partnumber, '-', ''), '/', ''), '_', ''), '\', '') LIKE '%' + REPLACE(REPLACE(REPLACE(REPLACE(@StartWith, '-', ''), '/', ''), '_', ''), '\', '') + '%'
				) UNION 
				SELECT DISTINCT TOP 50 
						Im.ItemMasterId AS Value,  
						Im.partnumber AS Label,
						im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = Im.MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS Partnumber,
						Im.PartDescription, 
						Im.ItemClassificationId, 
						Im.ManufacturerId, 
						Im.GLAccountId,
						Im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
						uom.ShortName AS UnitOfMeasure,
						UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL with(NoLock) on SL.ItemMasterId = Im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId AND ISNULL(SL.IsNonStock,0) = 0),
						Ig.ItemGroupCode As ItemGroup,
						CASE WHEN Im.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
							 WHEN Im.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
							 WHEN Im.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
							 ELSE 'OEM'
						END AS StockType,
						Ic.Description AS ItemClassification,
						M.Name As Manufacturer,
						GL.AccountCode + '-' + GL.AccountName AS GlAccount,
						isnull(rp. RevisedPart, '')  AS RevisedPart,
						Im.isSerialized AS IsSerialized,
						Im.isTimeLife AS IsTimeLife,
						ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND ISNULL(s.IsNonStock,0) = 0)
					FROM dbo.ItemMaster Im WITH(NOLOCK) 
						LEFT JOIN dbo.ItemMaster rp WITH(NOLOCK)  ON Im.ItemMasterId =  rp.ItemMasterId
						 AND ISNULL(rp.IsNonStock,0) = 0
						 JOIN dbo.UnitOfMeasure uom WITH(NOLOCK) ON Im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
						LEFT JOIN dbo.Itemgroup Ig WITH(NOLOCK) ON Im.ItemGroupId =  Ig.ItemGroupId
						LEFT JOIN dbo.ItemClassification Ic WITH(NOLOCK) ON Im.ItemClassificationId = Ic.ItemClassificationId
						LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
						LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON Im.GLAccountId = GL.GLAccountId
				WHERE Im.ItemMasterId in (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				 AND ISNULL(Im.IsNonStock,0) = 0
				 ORDER BY Label	
			END
	END TRY 
	BEGIN CATCH			  
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsItemMaster'               
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