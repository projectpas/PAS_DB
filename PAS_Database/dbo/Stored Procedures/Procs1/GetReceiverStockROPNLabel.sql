﻿/*************************************************************             
 ** File:   [GetReceiverStockROPNLabel]            
 ** Author:   
 ** Description: This stored procedure is used to get data for PN Label
 ** Purpose:           
 ** Date:        
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
	1
    2    11/16/2023   Devendra Shekh	Added case for partdescription - truncated description
  
-- EXEC GetReceiverStockROPNLabel 1110,'0','0','0','RecNo-000004'

exec dbo.GetReceiverStockROPNLabel @RepairOrderId=1190,@isParentData=N'0',@ItemMasterId=1,@ConditionId=1,@ReceiverNumber=N'RecNo-000002'
**************************************************************/
CREATE   PROCEDURE [dbo].[GetReceiverStockROPNLabel]
@RepairOrderId bigint,
@isParentData varchar(10),
@ItemMasterId bigint,
@ConditionId int,
@ReceiverNumber varchar(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		IF(@isParentData = '1')
		BEGIN
			SELECT sl.ReceiverNumber,CAST(sl.ReceivedDate AS DATE) AS ReceivedDate FROM [dbo].[Stockline] sl WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] i WITH(NOLOCK) ON i.ItemMasterId = sl.ItemMasterId
			WHERE RepairOrderId=@RepairOrderId and IsParent=1
			GROUP BY sl.ReceiverNumber,CAST(sl.ReceivedDate AS DATE)

			UNION

			SELECT sl.ReceiverNumber,CAST(sl.ReceivedDate AS DATE) AS ReceivedDate FROM [dbo].[AssetInventory] sl WITH(NOLOCK)
			INNER JOIN [dbo].[Asset] i WITH(NOLOCK) ON i.AssetRecordId = sl.AssetRecordId
			WHERE RepairOrderId = @RepairOrderId 
			GROUP BY sl.ReceiverNumber,CAST(sl.ReceivedDate AS DATE);
		END
		IF(@isParentData = '0')
		BEGIN
			SELECT i.ItemMasterId,
				  sl.ConditionId,
				  sl.PurchaseUnitOfMeasureId,
				   i.partnumber,
				   CASE WHEN LEN(i.PartDescription) > 50 THEN SUBSTRING(i.PartDescription, 1 , 50) + '...' ELSE i.PartDescription END AS 'PartDescription',
				  sl.Condition,
				  sl.UnitOfMeasure,
			      sl.StockLineId,
				  sl.StockLineNumber,
				  sl.SerialNumber,
				  --sl.Quantity AS Qty,
				  CASE WHEN sd.WOQty > 0 THEN sd.WOQty WHEN sd.SOQty > 0 THEN sd.SOQty WHEN sd.ForStockQty > 0 THEN sd.ForStockQty ELSE sl.Quantity END AS Qty,	
				  sl.ControlNumber,
				  sl.IdNumber,
				  sl.ReceiverNumber,
				  CAST(sl.ReceivedDate AS DATE) AS ReceivedDate,
			       s.[Name] AS 'SiteName',
				   w.[Name] AS 'WareHouseName',
				  bn.[Name] AS 'BinName',
				  sf.[Name] AS 'ShelfName',
				  lc.[Name] AS 'LocationName',
				   CASE WHEN sd.WOQty > 0 THEN 3 WHEN sd.SOQty > 0 THEN 2 ELSE 1 END AS Modules,
				  CASE WHEN sd.WOQty > 0 THEN 'WO' WHEN sd.SOQty > 0 THEN 'SO' ELSE 'STOCK' END AS ModuleName,				
				  CASE WHEN sd.WOQty > 0 THEN wo.WorkOrderNum WHEN sd.SOQty > 0 THEN so.SalesOrderNumber ELSE '' END AS ReferenceNumber,
				  sl.Manufacturer,				  
				  CAST(sl.ExpirationDate AS DATE) AS ExpirationDate,
				  sl.TraceableToName
			    FROM [dbo].[Stockline] sl WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] i WITH(NOLOCK) ON i.ItemMasterId = sl.ItemMasterId
			INNER JOIN [dbo].[StocklineDraft] sd WITH(NOLOCK) ON sl.StockLineId = sd.StockLineId
			LEFT JOIN  [dbo].[SalesOrder] so WITH(NOLOCK) ON sd.SalesOrderId = so.SalesOrderId
			LEFT JOIN  [dbo].[WorkOrder] wo WITH(NOLOCK) ON sd.WorkOrderId = wo.WorkOrderId
			LEFT JOIN  [dbo].[Site] s WITH(NOLOCK) ON s.SiteId = sl.SiteId
			LEFT JOIN  [dbo].[Warehouse] w WITH(NOLOCK) ON w.WarehouseId = sl.WarehouseId
			LEFT JOIN  [dbo].[Bin] bn WITH(NOLOCK) ON bn.BinId = sl.BinId
			LEFT JOIN  [dbo].[Shelf] sf WITH(NOLOCK) ON sf.ShelfId = sl.ShelfId
			LEFT JOIN  [dbo].[Location] lc WITH(NOLOCK) ON lc.LocationId = sl.LocationId
			WHERE sl.RepairOrderId=@RepairOrderId 			
			AND sl.ReceiverNumber = @ReceiverNumber AND sl.IsParent=1

			UNION

			SELECT i.ItemMasterId,
				  sl.ConditionId,
				  sl.PurchaseUnitOfMeasureId,
				   i.partnumber,
				   CASE WHEN LEN(i.PartDescription) > 50 THEN SUBSTRING(i.PartDescription, 1 , 50) + '...' ELSE i.PartDescription END AS 'PartDescription',
				  sl.Condition,
				  sl.UnitOfMeasure,
			      sl.StockLineId,
				  sl.StockLineNumber,
				  sl.SerialNumber,
				  sd.ForStockQty AS Qty,	
				  sl.ControlNumber,
				  sl.IdNumber,
				  sl.ReceiverNumber,
				  CAST(sl.ReceivedDate AS DATE) AS ReceivedDate,
			       s.[Name] AS 'SiteName',
				   w.[Name] AS 'WareHouseName',
				  bn.[Name] AS 'BinName',
				  sf.[Name] AS 'ShelfName',
				  lc.[Name] AS 'LocationName', 
				   1 AS Modules,
				  'STOCK' AS ModuleName,				
				  '' AS ReferenceNumber,
				  sl.Manufacturer,
				  CAST(sl.ExpirationDate AS DATE) AS ExpirationDate,
				  sl.TraceableToName
			    FROM [dbo].[Stockline] sl WITH(NOLOCK)			
			INNER JOIN [dbo].[ItemMaster] i WITH(NOLOCK) ON i.ItemMasterId = sl.ItemMasterId
			INNER JOIN [dbo].[StocklineDraft] sd WITH(NOLOCK) ON sl.StockLineId = sd.StockLineId
			LEFT JOIN  [dbo].[SalesOrder] so WITH(NOLOCK) ON sd.SalesOrderId = so.SalesOrderId
			LEFT JOIN  [dbo].[WorkOrder] wo WITH(NOLOCK) ON sd.WorkOrderId = wo.WorkOrderId
			LEFT JOIN  [dbo].[Site] s WITH(NOLOCK) ON s.SiteId = sl.SiteId
			LEFT JOIN  [dbo].[Warehouse] w WITH(NOLOCK) ON w.WarehouseId = sl.WarehouseId
			LEFT JOIN  [dbo].[Bin] bn WITH(NOLOCK) ON bn.BinId = sl.BinId
			LEFT JOIN  [dbo].[Shelf] sf WITH(NOLOCK) ON sf.ShelfId = sl.ShelfId
			LEFT JOIN  [dbo].[Location] lc WITH(NOLOCK) ON lc.LocationId = sl.LocationId
			WHERE sl.RepairOrderId=@RepairOrderId 		
			AND sl.ReceiverNumber = @ReceiverNumber AND sl.IsParent=1 AND sd.ForStockQty > 0

			UNION

			SELECT sl.AssetRecordId AS ItemMasterId,
				    0 AS ConditionId,
				   sl.UnitOfMeasureId AS PurchaseUnitOfMeasureId,
				   sl.AssetId AS partnumber,
				   CASE WHEN LEN(sl.Description) > 50 THEN SUBSTRING(sl.Description, 1 , 50) + '...' ELSE sl.Description END AS 'PartDescription',
				   '' AS Condition,
				   UM.shortname AS UnitOfMeasure,
			       sl.AssetInventoryId AS StockLineId,
				   sl.StklineNumber AS StockLineNumber,
				   sl.SerialNo AS SerialNumber,
				   sl.Qty,
				   sl.ControlNumber,
				   '' AS IdNumber,
				   sl.ReceiverNumber,
				   cast(sl.ReceivedDate AS DATE) AS ReceivedDate,
				   sl.SiteName AS 'SiteName',
				   sl.Warehouse AS 'WareHouseName',
			       sl.BinName AS 'BinName',
				   sl.ShelfName AS 'ShelfName',
				   sl.Location AS 'LocationName', 
				   1 as Modules,
				   'STOCK'  as ModuleName,
				   ''  as ReferenceNumber,
				   sl.ManufactureName AS Manufacturer,
				   CAST(sl.ExpirationDate AS DATE) AS ExpirationDate,
				    '' AS TraceableToName
			FROM [dbo].[AssetInventory] sl WITH(NOLOCK) LEFT JOIN [dbo].[UnitOfMeasure] UM WITH (NOLOCK) ON UM.unitOfMeasureId = sl.UnitOfMeasureId		
			WHERE RepairOrderId=@RepairOrderId 
			AND sl.ReceiverNumber = @ReceiverNumber;
		END	

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReceiverStockROPNLabel' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderId, '') + ''',
													 @Parameter2 = ' + ISNULL(@isParentData,'') + ''
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