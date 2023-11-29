/*************************************************************           
 ** File:   [GetReceiverStockRO]
 ** Author:  MOIN BLOCH
 ** Description: Show WO#, SO#, and For Stock based on grouping in Receiving Repair Order Stock Report Print
 ** Purpose:         
 ** Date:   29/05/2023  
          
 ** PARAMETERS: @RepairOrderId BIGINT,@isParentData VARCHAR(10),@ItemMasterId BIGINT,@@ConditionId INT,@ReceiverNumber VARCHAR(100)
     
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    29/05/2023   MOIN BLOCH    UPDATE TO Show WO#, SO#, and For Stock based on grouping 
     
--  EXEC GetReceiverStockRO 1123,'0',1,1,'RecNo-000001'
--  EXEC GetReceiverStockRO 1122,'0',1,1,'RecNo-000001'
************************************************************************/
CREATE   PROCEDURE [dbo].[GetReceiverStockRO]
@RepairOrderId BIGINT,
@isParentData VARCHAR(10),
@ItemMasterId BIGINT,
@ConditionId INT,
@ReceiverNumber VARCHAR(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	--BEGIN TRANSACTION
	--BEGIN
		IF(@isParentData = '1')
		BEGIN
			SELECT sl.ReceiverNumber,CAST(sl.ReceivedDate AS DATE) AS ReceivedDate FROM Stockline sl WITH(NOLOCK)
			INNER JOIN ItemMaster i WITH(NOLOCK) on i.ItemMasterId = sl.ItemMasterId
			WHERE RepairOrderId=@RepairOrderId AND IsParent=1
			GROUP BY sl.ReceiverNumber,CAST(sl.ReceivedDate AS DATE)

			UNION

			SELECT sl.ReceiverNumber,CAST(sl.ReceivedDate AS DATE) AS ReceivedDate FROM AssetInventory sl WITH(NOLOCK)
				INNER JOIN Asset i WITH(NOLOCK) ON i.AssetRecordId = sl.AssetRecordId
				WHERE RepairOrderId = @RepairOrderId 
				GROUP BY sl.ReceiverNumber,CAST(sl.ReceivedDate AS DATE);
		END
		IF(@isParentData = '0')
		BEGIN
			SELECT i.ItemMasterId,
				  sl.ConditionId,
				  sl.PurchaseUnitOfMeasureId,
				   i.partnumber,
				   i.PartDescription,
				  sl.Condition,
				  sl.UnitOfMeasure,
			      sl.StockLineId,
				  sl.StockLineNumber,
				  sl.SerialNumber,
				  --sl.Quantity as Qty,
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
			WHERE sl.[RepairOrderId] = @RepairOrderId 
			  AND sl.[ReceiverNumber] = @ReceiverNumber AND sl.[IsParent]=1

			UNION

			SELECT i.ItemMasterId,
				  sl.ConditionId,
				  sl.PurchaseUnitOfMeasureId,
				   i.partnumber,
				   i.PartDescription,
				  sl.Condition,
				  sl.UnitOfMeasure,
			      sl.StockLineId,
				  sl.StockLineNumber,
				  sl.SerialNumber,
				  sd.ForStockQty AS Qty,	
				  sl.ControlNumber,
				  sl.IdNumber,
				  sl.ReceiverNumber,
				  cast(sl.ReceivedDate AS DATE) AS ReceivedDate,
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
			WHERE sl.[RepairOrderId] = @RepairOrderId 
			  AND sl.[ReceiverNumber] = @ReceiverNumber AND sl.[IsParent]=1 AND sd.ForStockQty > 0

			UNION

			SELECT sl.AssetRecordId AS ItemMasterId,
				    0 AS ConditionId,
				   sl.UnitOfMeasureId AS PurchaseUnitOfMeasureId,
				   sl.AssetId AS partnumber,
				   sl.[Description] AS PartDescription,
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
				    1 AS Modules,
				   'STOCK'  AS ModuleName,
				   ''  as ReferenceNumber,
				   sl.ManufactureName AS Manufacturer,
				   CAST(sl.ExpirationDate AS DATE) AS ExpirationDate,
				    '' AS TraceableToName
			FROM [dbo].[AssetInventory] sl WITH(NOLOCK) LEFT JOIN [dbo].[UnitOfMeasure] UM WITH (NOLOCK) ON UM.unitOfMeasureId = sl.UnitOfMeasureId		
			WHERE [RepairOrderId] = @RepairOrderId 
			AND sl.ReceiverNumber = @ReceiverNumber;
		END
	--END
	--COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			--ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReceiverStockRO' 
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