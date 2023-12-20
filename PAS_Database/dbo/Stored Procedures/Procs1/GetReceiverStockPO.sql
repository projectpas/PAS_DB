/*************************************************************             
 ** File:   [GetReceiverStockPO]            
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to get data for PN Label and Receiver Stock Print Report 
 ** Purpose:           
 ** Date:   10/27/2023          
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    10/27/2023   Vishal Suthar		Added Stored Procedure History
    2    10/27/2023   Vishal Suthar		Added New Parameter @PurchaseOrderPartId 
    2    11/16/2023   Devendra Shekh	Added case for partdescription - truncated description
  
-- EXEC GetReceiverStockPO 2014, '1', 1, 1, 'RecNo000047', 3683
r
exec dbo.GetReceiverStockPO @PurchaseOrderId=2014,@isParentData=N'0',@ItemMasterId=1,@ConditionId=1,@ReceiverNumber=N'RecNo000001',@PurchaseOrderPartId=0
**************************************************************/
CREATE   PROCEDURE [dbo].[GetReceiverStockPO]
	@PurchaseOrderId bigint,
	@isParentData varchar(10),
	@ItemMasterId bigint,
	@ConditionId int,
	@ReceiverNumber varchar(100),
	@PurchaseOrderPartId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		IF(@isParentData = '1')
		BEGIN			
			SELECT sl.ReceiverNumber,CAST(sl.ReceivedDate AS DATE) AS ReceivedDate,
				CASE WHEN MAX(POP.WorkOrderId) > 1 THEN 3 WHEN MAX(POP.SalesOrderId) > 1 THEN 2 ELSE 1 END AS Modules FROM [dbo].[Stockline] sl WITH(NOLOCK)
				INNER JOIN [dbo].[ItemMaster] i WITH(NOLOCK) ON i.ItemMasterId = sl.ItemMasterId
				INNER JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderId = sl.PurchaseOrderId AND POP.ItemMasterId=i.ItemMasterId AND POP.PurchaseOrderPartRecordId=sl.PurchaseOrderPartRecordId
				WHERE sl.PurchaseOrderId = @PurchaseOrderId AND (@PurchaseOrderPartId = 0 OR sl.PurchaseOrderPartRecordId = @PurchaseOrderPartId) AND sl.IsParent = 1
				GROUP BY sl.ReceiverNumber,CAST(sl.ReceivedDate AS DATE)
			UNION
			SELECT sl.ReceiverNumber,CAST(sl.ReceivedDate as date) as ReceivedDate,
				CASE WHEN MAX(POP.WorkOrderId) >1 THEN 3 when MAX(POP.SalesOrderId) > 1 THEN 2 ELSE 1 END AS Modules 
				FROM [dbo].[NonStockInventory] sl WITH(NOLOCK)
				INNER JOIN [dbo].[ItemMasterNonStock] i WITH(NOLOCK) ON i.MasterPartId = sl.MasterPartId
				LEFT JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderId = sl.PurchaseOrderId AND POP.ItemMasterId=sl.MasterPartId AND POP.PurchaseOrderPartRecordId=sl.PurchaseOrderPartRecordId
				WHERE sl.PurchaseOrderId = @PurchaseOrderId AND (@PurchaseOrderPartId = 0 OR sl.PurchaseOrderPartRecordId = @PurchaseOrderPartId) AND sl.IsParent = 1
				GROUP BY sl.ReceiverNumber,CAST(sl.ReceivedDate AS DATE)
			UNION
			SELECT sl.ReceiverNumber, CAST(sl.ReceivedDate AS DATE) AS ReceivedDate, 1 AS Modules FROM [dbo].[AssetInventory] sl WITH(NOLOCK)
				INNER JOIN [dbo].[Asset] i WITH(NOLOCK) ON i.AssetRecordId = sl.AssetRecordId
				WHERE PurchaseOrderId = @PurchaseOrderId AND (@PurchaseOrderPartId = 0 OR sl.PurchaseOrderPartRecordId = @PurchaseOrderPartId)
				GROUP BY sl.ReceiverNumber, CAST(sl.ReceivedDate AS DATE) ORDER BY Modules DESC			
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
				  sl.Quantity as Qty,
				  sl.ControlNumber,
				  sl.IdNumber,
				  sl.ReceiverNumber,
				  cast(sl.ReceivedDate as date) as ReceivedDate,
			      s.[Name] as 'SiteName',w.[Name] as 'WareHouseName',
				  bn.[Name] as 'BinName',sf.[Name] as 'ShelfName',
				  lc.[Name] as 'LocationName' ,
				--CASE WHEN POP.WorkOrderId > 1 THEN 3 when POP.SalesOrderId >1 then 2 ELSE 1 END as Modules,
				--CASE WHEN POP.WorkOrderId > 1 THEN 'WO' when POP.SalesOrderId > 1 then 'SO' ELSE 'STOCK' END as ModuleName,				
				--CASE WHEN POP.WorkOrderId > 1 THEN POP.WorkOrderNo when POP.SalesOrderId >1 then POP.SalesOrderNo ELSE '' END as ReferenceNumber
				  CASE WHEN sd.WOQty > 0 THEN 3 WHEN sd.SOQty > 0 THEN 2 ELSE 1 END AS Modules,
				  CASE WHEN sd.WOQty > 0 THEN 'WO' WHEN sd.SOQty > 0 THEN 'SO' ELSE 'STOCK' END AS ModuleName,				
				  CASE WHEN sd.WOQty > 0 THEN wo.WorkOrderNum WHEN sd.SOQty > 0 THEN so.SalesOrderNumber ELSE '' END AS ReferenceNumber,
				  sl.Manufacturer,				  
				  CAST(sl.ExpirationDate AS DATE) AS ExpirationDate,
				  sl.TraceableToName
			FROM [dbo].[Stockline] sl WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] i WITH(NOLOCK) ON i.ItemMasterId = sl.ItemMasterId
			--INNER JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderId = sl.PurchaseOrderId and POP.ItemMasterId=i.ItemMasterId and POP.PurchaseOrderPartRecordId=sl.PurchaseOrderPartRecordId
			INNER JOIN  [dbo].[StocklineDraft] sd WITH(NOLOCK) ON sl.StockLineId = sd.StockLineId 
			LEFT JOIN [dbo].[PurchaseOrderPartReference] popr WITH(NOLOCK) ON sl.PurchaseOrderPartRecordId = popr.PurchaseOrderPartId
			--LEFT JOIN  [dbo].[SalesOrder] so WITH(NOLOCK) ON popr.ModuleId = 3 AND popr.ReferenceId = so.SalesOrderId 
			--LEFT JOIN  [dbo].[WorkOrder] wo WITH(NOLOCK) ON popr.ModuleId = 1 AND popr.ReferenceId = wo.WorkOrderId 
			LEFT JOIN  [dbo].[SalesOrder] so WITH(NOLOCK) ON sd.SalesOrderId = so.SalesOrderId
			LEFT JOIN  [dbo].[WorkOrder] wo WITH(NOLOCK) ON sd.WorkOrderId = wo.WorkOrderId
			LEFT JOIN  [dbo].[Site] s WITH(NOLOCK) ON s.SiteId = sl.SiteId
			LEFT JOIN  [dbo].[Warehouse] w WITH(NOLOCK) ON w.WarehouseId = sl.WarehouseId
			LEFT JOIN  [dbo].[Bin] bn WITH(NOLOCK) ON bn.BinId = sl.BinId
			LEFT JOIN  [dbo].[Shelf] sf WITH(NOLOCK) ON sf.ShelfId = sl.ShelfId
			LEFT JOIN  [dbo].[Location] lc WITH(NOLOCK) ON lc.LocationId = sl.LocationId
			WHERE sl.PurchaseOrderId = @PurchaseOrderId AND (@PurchaseOrderPartId = 0 OR sl.PurchaseOrderPartRecordId = @PurchaseOrderPartId)
			--AND sl.ItemMasterId = @ItemMasterId 
			--AND sl.ConditionId = @ConditionId
			AND sl.ReceiverNumber = @ReceiverNumber AND sl.IsParent=1 and sl.isSerialized = 1

			UNION

			--SELECT i.ItemMasterId,
			--	  sl.ConditionId,
			--	  sl.PurchaseUnitOfMeasureId,
			--	   i.partnumber,
			--	   i.PartDescription,
			--	  sl.Condition,
			--	  sl.UnitOfMeasure,
			--      sl.StockLineId,
			--	  sl.StockLineNumber,
			--	  sl.SerialNumber,
			--	  --sl.Quantity as Qty,
			--	  --CASE WHEN sd.WOQty > 0 THEN sd.WOQty WHEN sd.SOQty > 0 THEN sd.SOQty WHEN sd.ForStockQty > 0 THEN sd.ForStockQty ELSE sl.Quantity END AS Qty,	
			--	  popr.ReservedQty AS Qty,
			--	  sl.ControlNumber,
			--	  sl.IdNumber,
			--	  sl.ReceiverNumber,
			--	  cast(sl.ReceivedDate as date) as ReceivedDate,
			--      s.[Name] as 'SiteName',w.[Name] as 'WareHouseName',
			--	  bn.[Name] as 'BinName',sf.[Name] as 'ShelfName',
			--	  lc.[Name] as 'LocationName' ,
			--	--CASE WHEN POP.WorkOrderId > 1 THEN 3 when POP.SalesOrderId >1 then 2 ELSE 1 END as Modules,
			--	--CASE WHEN POP.WorkOrderId > 1 THEN 'WO' when POP.SalesOrderId > 1 then 'SO' ELSE 'STOCK' END as ModuleName,				
			--	--CASE WHEN POP.WorkOrderId > 1 THEN POP.WorkOrderNo when POP.SalesOrderId >1 then POP.SalesOrderNo ELSE '' END as ReferenceNumber
			--	  CASE WHEN sd.WOQty > 0 THEN 3 WHEN sd.SOQty > 0 THEN 2 ELSE 1 END AS Modules,
			--	  CASE WHEN sd.WOQty > 0 THEN 'WO' WHEN sd.SOQty > 0 THEN 'SO' ELSE 'STOCK' END AS ModuleName,				
			--	  CASE WHEN sd.WOQty > 0 THEN wo.WorkOrderNum WHEN sd.SOQty > 0 THEN so.SalesOrderNumber ELSE '' END AS ReferenceNumber,
			--	  sl.Manufacturer,
			--	  CAST(sl.ExpirationDate AS DATE) AS ExpirationDate,
			--	  sl.TraceableToName
			--FROM [dbo].[Stockline] sl WITH(NOLOCK)
			--INNER JOIN [dbo].[ItemMaster] i WITH(NOLOCK) ON i.ItemMasterId = sl.ItemMasterId
			----INNER JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderId = sl.PurchaseOrderId and POP.ItemMasterId=i.ItemMasterId and POP.PurchaseOrderPartRecordId=sl.PurchaseOrderPartRecordId
			--INNER JOIN  [dbo].[StocklineDraft] sd WITH(NOLOCK) ON sl.StockLineId = sd.StockLineId 
			----LEFT JOIN  [dbo].[SalesOrder] so WITH(NOLOCK) ON sd.SalesOrderId = so.SalesOrderId
			----LEFT JOIN  [dbo].[WorkOrder] wo WITH(NOLOCK) ON sd.WorkOrderId = wo.WorkOrderId
			--LEFT JOIN [dbo].[PurchaseOrderPartReference] popr WITH(NOLOCK) ON sl.PurchaseOrderPartRecordId = popr.PurchaseOrderPartId
			--LEFT JOIN  [dbo].[SalesOrder] so WITH(NOLOCK) ON popr.ModuleId = 3 AND popr.ReferenceId = so.SalesOrderId 
			--LEFT JOIN  [dbo].[WorkOrder] wo WITH(NOLOCK) ON popr.ModuleId = 1 AND popr.ReferenceId = wo.WorkOrderId 
			--LEFT JOIN  [dbo].[Site] s WITH(NOLOCK) ON s.SiteId = sl.SiteId
			--LEFT JOIN  [dbo].[Warehouse] w WITH(NOLOCK) ON w.WarehouseId = sl.WarehouseId
			--LEFT JOIN  [dbo].[Bin] bn WITH(NOLOCK) ON bn.BinId = sl.BinId
			--LEFT JOIN  [dbo].[Shelf] sf WITH(NOLOCK) ON sf.ShelfId = sl.ShelfId
			--LEFT JOIN  [dbo].[Location] lc WITH(NOLOCK) ON lc.LocationId = sl.LocationId
			--WHERE sl.PurchaseOrderId=@PurchaseOrderId
			----AND sl.ItemMasterId = @ItemMasterId 
			----AND sl.ConditionId = @ConditionId
			--AND sl.ReceiverNumber = @ReceiverNumber AND sl.IsParent=1 and sl.isSerialized = 0 
			
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
				  --sl.Quantity as Qty,
				  CASE WHEN sd.WOQty > 0 THEN sd.WOQty WHEN sd.SOQty > 0 THEN sd.SOQty WHEN sd.ForStockQty > 0 THEN sd.ForStockQty ELSE sl.Quantity END AS Qty,	
				  --CASE WHEN sd.WOQty > 0 THEN popr.ReservedQty WHEN sd.SOQty > 0 THEN popr.ReservedQty ELSE sd.ForStockQty END AS Qty,
				  --popr.ReservedQty AS Qty,
				  sl.ControlNumber,
				  sl.IdNumber,
				  sl.ReceiverNumber,
				  cast(sl.ReceivedDate as date) as ReceivedDate,
			      s.[Name] as 'SiteName',w.[Name] as 'WareHouseName',
				  bn.[Name] as 'BinName',sf.[Name] as 'ShelfName',
				  lc.[Name] as 'LocationName' ,
				--CASE WHEN POP.WorkOrderId > 1 THEN 3 when POP.SalesOrderId >1 then 2 ELSE 1 END as Modules,
				--CASE WHEN POP.WorkOrderId > 1 THEN 'WO' when POP.SalesOrderId > 1 then 'SO' ELSE 'STOCK' END as ModuleName,				
				--CASE WHEN POP.WorkOrderId > 1 THEN POP.WorkOrderNo when POP.SalesOrderId >1 then POP.SalesOrderNo ELSE '' END as ReferenceNumber
				  CASE WHEN sd.WOQty > 0 THEN 3 WHEN sd.SOQty > 0 THEN 2 ELSE 1 END AS Modules,
				  CASE WHEN sd.WOQty > 0 THEN 'WO' WHEN sd.SOQty > 0 THEN 'SO' ELSE 'STOCK' END AS ModuleName,				
				  CASE WHEN sd.WOQty > 0 THEN wo.WorkOrderNum WHEN sd.SOQty > 0 THEN so.SalesOrderNumber ELSE '' END AS ReferenceNumber,
				  sl.Manufacturer,
				  CAST(sl.ExpirationDate AS DATE) AS ExpirationDate,
				  sl.TraceableToName
			FROM [dbo].[Stockline] sl WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] i WITH(NOLOCK) ON i.ItemMasterId = sl.ItemMasterId
			--INNER JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderId = sl.PurchaseOrderId and POP.ItemMasterId=i.ItemMasterId and POP.PurchaseOrderPartRecordId=sl.PurchaseOrderPartRecordId
			INNER JOIN  [dbo].[StocklineDraft] sd WITH(NOLOCK) ON sl.StockLineId = sd.StockLineId 
			LEFT JOIN [dbo].[PurchaseOrderPartReference] popr WITH(NOLOCK) ON sl.PurchaseOrderPartRecordId = popr.PurchaseOrderPartId
			LEFT JOIN  [dbo].[SalesOrder] so WITH(NOLOCK) ON sd.SalesOrderId = so.SalesOrderId
			LEFT JOIN  [dbo].[WorkOrder] wo WITH(NOLOCK) ON sd.WorkOrderId = wo.WorkOrderId
			--LEFT JOIN  [dbo].[SalesOrder] so WITH(NOLOCK) ON popr.ModuleId = 3 AND popr.ReferenceId = so.SalesOrderId 
			--LEFT JOIN  [dbo].[WorkOrder] wo WITH(NOLOCK) ON popr.ModuleId = 1 AND popr.ReferenceId = wo.WorkOrderId 
			LEFT JOIN  [dbo].[Site] s WITH(NOLOCK) ON s.SiteId = sl.SiteId
			LEFT JOIN  [dbo].[Warehouse] w WITH(NOLOCK) ON w.WarehouseId = sl.WarehouseId
			LEFT JOIN  [dbo].[Bin] bn WITH(NOLOCK) ON bn.BinId = sl.BinId
			LEFT JOIN  [dbo].[Shelf] sf WITH(NOLOCK) ON sf.ShelfId = sl.ShelfId
			LEFT JOIN  [dbo].[Location] lc WITH(NOLOCK) ON lc.LocationId = sl.LocationId
			WHERE sl.PurchaseOrderId = @PurchaseOrderId AND (@PurchaseOrderPartId = 0 OR sl.PurchaseOrderPartRecordId = @PurchaseOrderPartId)
			--AND sl.ItemMasterId = @ItemMasterId 
			--AND sl.ConditionId = @ConditionId
			AND sl.ReceiverNumber = @ReceiverNumber AND sl.IsParent=1 and sl.isSerialized = 0 

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
				  --sl.Quantity as Qty,
				  sd.ForStockQty AS Qty,	
				  sl.ControlNumber,
				  sl.IdNumber,
				  sl.ReceiverNumber,
				  cast(sl.ReceivedDate as date) as ReceivedDate,
			      s.[Name] as 'SiteName',w.[Name] as 'WareHouseName',
				  bn.[Name] as 'BinName',sf.[Name] as 'ShelfName',
				  lc.[Name] as 'LocationName' ,
				--CASE WHEN POP.WorkOrderId > 1 THEN 3 when POP.SalesOrderId >1 then 2 ELSE 1 END as Modules,
				--CASE WHEN POP.WorkOrderId > 1 THEN 'WO' when POP.SalesOrderId > 1 then 'SO' ELSE 'STOCK' END as ModuleName,				
				--CASE WHEN POP.WorkOrderId > 1 THEN POP.WorkOrderNo when POP.SalesOrderId >1 then POP.SalesOrderNo ELSE '' END as ReferenceNumber
				  1 AS Modules,
				  'STOCK' AS ModuleName,				
				  '' AS ReferenceNumber,
				  sl.Manufacturer,
				  CAST(sl.ExpirationDate AS DATE) AS ExpirationDate,
				  sl.TraceableToName
			FROM [dbo].[Stockline] sl WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] i WITH(NOLOCK) ON i.ItemMasterId = sl.ItemMasterId
			--INNER JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderId = sl.PurchaseOrderId and POP.ItemMasterId=i.ItemMasterId and POP.PurchaseOrderPartRecordId=sl.PurchaseOrderPartRecordId
			INNER JOIN  [dbo].[StocklineDraft] sd WITH(NOLOCK) ON sl.StockLineId = sd.StockLineId 
			LEFT JOIN  [dbo].[SalesOrder] so WITH(NOLOCK) ON sd.SalesOrderId = so.SalesOrderId
			LEFT JOIN  [dbo].[WorkOrder] wo WITH(NOLOCK) ON sd.WorkOrderId = wo.WorkOrderId
			LEFT JOIN  [dbo].[Site] s WITH(NOLOCK) ON s.SiteId = sl.SiteId
			LEFT JOIN  [dbo].[Warehouse] w WITH(NOLOCK) ON w.WarehouseId = sl.WarehouseId
			LEFT JOIN  [dbo].[Bin] bn WITH(NOLOCK) ON bn.BinId = sl.BinId
			LEFT JOIN  [dbo].[Shelf] sf WITH(NOLOCK) ON sf.ShelfId = sl.ShelfId
			LEFT JOIN  [dbo].[Location] lc WITH(NOLOCK) ON lc.LocationId = sl.LocationId
			WHERE sl.PurchaseOrderId = @PurchaseOrderId AND (@PurchaseOrderPartId = 0 OR sl.PurchaseOrderPartRecordId = @PurchaseOrderPartId)
			--AND sl.ItemMasterId = @ItemMasterId 
			--AND sl.ConditionId = @ConditionId
			AND sl.ReceiverNumber = @ReceiverNumber AND sl.IsParent=1 AND sl.isSerialized = 0 AND sd.ForStockQty > 0
					   
			UNION

			SELECT sl.MasterPartId AS ItemMasterId,
				   sl.ConditionId,
				   sl.UnitOfMeasureId AS PurchaseUnitOfMeasureId,
				   sl.PartNumber AS partnumber,
				   CASE WHEN LEN(sl.PartDescription) > 50 THEN SUBSTRING(sl.PartDescription, 1 , 50) + '...' ELSE sl.PartDescription END AS 'PartDescription',
				   sl.Condition,
				   sl.UnitOfMeasure,
			       sl.NonStockInventoryId AS StockLineId,
				   sl.NonStockInventoryNumber AS StockLineNumber,
				   sl.SerialNumber,
				   sl.Quantity as Qty,
				   sl.ControlNumber,
				   sl.IdNumber,
				   sl.ReceiverNumber,
				   cast(sl.ReceivedDate as date) as ReceivedDate,
				   sl.Site AS 'SiteName',
				   sl.Warehouse AS 'WareHouseName',
			       sl.Bin as 'BinName',
				   sl.Shelf AS 'ShelfName',
				   sl.Location AS 'LocationName',
			      CASE WHEN POP.WorkOrderId >1 THEN 3 when POP.SalesOrderId >1 then 2 ELSE 1 END as Modules,
				  CASE WHEN POP.WorkOrderId >1 THEN 'WO3' when POP.SalesOrderId >1 then 'SO' ELSE 'STOCK' END as ModuleName,
				  CASE WHEN POP.WorkOrderId >1 THEN POP.WorkOrderNo when POP.SalesOrderId >1 then POP.SalesOrderNo ELSE '' END as ReferenceNumber,
				  sl.Manufacturer,
				  CAST(sl.MfgExpirationDate AS DATE) AS ExpirationDate,
				   '' AS TraceableToName
			FROM [dbo].[NonStockInventory] sl WITH(NOLOCK)
			LEFT JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) on POP.PurchaseOrderId = sl.PurchaseOrderId and POP.ItemMasterId=sl.MasterPartId and POP.PurchaseOrderPartRecordId=sl.PurchaseOrderPartRecordId
			WHERE sl.PurchaseOrderId = @PurchaseOrderId AND (@PurchaseOrderPartId = 0 OR sl.PurchaseOrderPartRecordId = @PurchaseOrderPartId)
			AND sl.ReceiverNumber = @ReceiverNumber AND sl.IsParent=1
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
				   cast(sl.ReceivedDate as date) as ReceivedDate,
				   sl.SiteName AS 'SiteName',
				   sl.Warehouse AS 'WareHouseName',
			       sl.BinName as 'BinName',
				   sl.ShelfName AS 'ShelfName',
				   sl.Location AS 'LocationName', 
				   1 as Modules,
				   'STOCK'  as ModuleName,
				   ''  as ReferenceNumber,
				   sl.ManufactureName AS Manufacturer,
				   CAST(sl.ExpirationDate AS DATE) AS ExpirationDate,
				    '' AS TraceableToName
			FROM [dbo].[AssetInventory] sl WITH(NOLOCK) 
			LEFT JOIN [dbo].[UnitOfMeasure]  UM WITH (NOLOCK) ON UM.unitOfMeasureId = sl.UnitOfMeasureId		
			--LEFT JOIN PurchaseOrderPart POP WITH(NOLOCK) on POP.PurchaseOrderId = sl.PurchaseOrderId and POP.ass=sl.AssetRecordId
			WHERE PurchaseOrderId = @PurchaseOrderId AND (@PurchaseOrderPartId = 0 OR sl.PurchaseOrderPartRecordId = @PurchaseOrderPartId)
			AND sl.ReceiverNumber = @ReceiverNumber Order by Modules desc
		END
	END
	END TRY    
	BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReceiverStockPO' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''',
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