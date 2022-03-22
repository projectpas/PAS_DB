


-- EXEC GetReceiverStockPO 212,'1',0,0,''
CREATE PROCEDURE [dbo].[GetReceiverStockPO]
	@PurchaseOrderId bigint,
	@isParentData varchar(10),
	@ItemMasterId bigint,
	@ConditionId int,
	@ReceiverNumber varchar(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF(@isParentData = '1')
		BEGIN
			SELECT sl.ReceiverNumber,cast(sl.ReceivedDate as date) as ReceivedDate FROM Stockline sl WITH(NOLOCK)
				INNER JOIN ItemMaster i WITH(NOLOCK) on i.ItemMasterId = sl.ItemMasterId
				WHERE PurchaseOrderId=@PurchaseOrderId and IsParent=1
				GROUP BY sl.ReceiverNumber,cast(sl.ReceivedDate as date)
			UNION
			SELECT sl.ReceiverNumber,cast(sl.ReceivedDate as date) as ReceivedDate FROM NonStockInventory sl WITH(NOLOCK)
				INNER JOIN ItemMasterNonStock i WITH(NOLOCK) on i.MasterPartId = sl.MasterPartId
				WHERE PurchaseOrderId=@PurchaseOrderId AND IsParent=1
				GROUP BY sl.ReceiverNumber,cast(sl.ReceivedDate as date)
			UNION
			SELECT sl.ReceiverNumber,cast(sl.ReceivedDate as date) as ReceivedDate FROM AssetInventory sl WITH(NOLOCK)
				INNER JOIN Asset i WITH(NOLOCK) on i.AssetRecordId = sl.AssetRecordId
				WHERE PurchaseOrderId=@PurchaseOrderId 
				GROUP BY sl.ReceiverNumber,cast(sl.ReceivedDate as date)			
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
				  sl.Quantity as Qty,
				  sl.ControlNumber,
				  sl.IdNumber,
				  sl.ReceiverNumber,
				  cast(sl.ReceivedDate as date) as ReceivedDate,
			      s.[Name] as 'SiteName',w.[Name] as 'WareHouseName',
				  bn.[Name] as 'BinName',sf.[Name] as 'ShelfName',
				  lc.[Name] as 'LocationName' 
			from Stockline sl WITH(NOLOCK)
			INNER JOIN ItemMaster i WITH(NOLOCK) on i.ItemMasterId = sl.ItemMasterId
			LEFT JOIN [Site] s WITH(NOLOCK) on s.SiteId = sl.SiteId
			LEFT JOIN Warehouse w WITH(NOLOCK) on w.WarehouseId = sl.WarehouseId
			LEFT JOIN Bin bn WITH(NOLOCK) on bn.BinId = sl.BinId
			LEFT JOIN Shelf sf WITH(NOLOCK) on sf.ShelfId = sl.ShelfId
			LEFT JOIN Location lc WITH(NOLOCK) on lc.LocationId = sl.LocationId
			where PurchaseOrderId=@PurchaseOrderId
			--AND sl.ItemMasterId = @ItemMasterId 
			--AND sl.ConditionId = @ConditionId
			AND sl.ReceiverNumber = @ReceiverNumber AND IsParent=1
			UNION
			SELECT sl.MasterPartId AS ItemMasterId,
				   sl.ConditionId,
				   sl.UnitOfMeasureId AS PurchaseUnitOfMeasureId,
				   sl.PartNumber AS partnumber,
				   sl.PartDescription,
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
				   sl.Location AS 'LocationName' 
			FROM NonStockInventory sl WITH(NOLOCK)			
			WHERE PurchaseOrderId=@PurchaseOrderId			
			AND sl.ReceiverNumber = @ReceiverNumber AND IsParent=1
			UNION
			SELECT sl.AssetRecordId AS ItemMasterId,
				    0 AS ConditionId,
				   sl.UnitOfMeasureId AS PurchaseUnitOfMeasureId,
				   sl.AssetId AS partnumber,
				   sl.Description AS PartDescription,
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
				   sl.Location AS 'LocationName' 
			FROM AssetInventory sl WITH(NOLOCK) LEFT JOIN dbo.UnitOfMeasure  UM WITH (NOLOCK) ON UM.unitOfMeasureId = sl.UnitOfMeasureId		
			WHERE PurchaseOrderId=@PurchaseOrderId	
			AND sl.ReceiverNumber = @ReceiverNumber;
		END
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
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