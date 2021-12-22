﻿CREATE PROCEDURE [dbo].[GetReceiverStockPO]
	@PurchaseOrderId bigint,
	@isParentData varchar(10),
	@ItemMasterId bigint,
	@ConditionId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF(@isParentData = '1')
		BEGIN
			SELECT i.ItemMasterId,sl.ConditionId,i.partnumber,i.PartDescription,sl.Condition,sl.UnitOfMeasure from Stockline sl WITH(NOLOCK)
			INNER JOIN ItemMaster i WITH(NOLOCK) on i.ItemMasterId = sl.ItemMasterId
			WHERE PurchaseOrderId=@PurchaseOrderId and IsParent=1
			GROUP BY i.ItemMasterId,ConditionId,sl.PurchaseUnitOfMeasureId,i.partnumber,i.PartDescription,sl.Condition,sl.UnitOfMeasure;
		END
		IF(@isParentData = '0')
		BEGIN
			SELECT i.ItemMasterId,sl.ConditionId,sl.PurchaseUnitOfMeasureId,i.partnumber,i.PartDescription,sl.Condition,sl.UnitOfMeasure,
			sl.StockLineId,sl.StockLineNumber,sl.SerialNumber,sl.Quantity as Qty,sl.ControlNumber,sl.IdNumber,
			s.[Name] as 'SiteName',w.[Name] as 'WareHouseName',bn.[Name] as 'BinName',sf.[Name] as 'ShelfName',lc.[Name] as 'LocationName' from Stockline sl WITH(NOLOCK)
			INNER JOIN ItemMaster i WITH(NOLOCK) on i.ItemMasterId = sl.ItemMasterId
			LEFT JOIN [Site] s WITH(NOLOCK) on s.SiteId = sl.SiteId
			LEFT JOIN Warehouse w WITH(NOLOCK) on w.WarehouseId = sl.WarehouseId
			LEFT JOIN Bin bn WITH(NOLOCK) on bn.BinId = sl.BinId
			LEFT JOIN Shelf sf WITH(NOLOCK) on sf.ShelfId = sl.ShelfId
			LEFT JOIN Location lc WITH(NOLOCK) on lc.LocationId = sl.LocationId
			where PurchaseOrderId=@PurchaseOrderId AND sl.ItemMasterId = @ItemMasterId AND sl.ConditionId = @ConditionId and IsParent=1
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