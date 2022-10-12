CREATE PROCEDURE [dbo].[UpdateStocklineBatchDetailsColumnsWithId]
	@StocklineId int
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @MSModuleID INT;
				SET @MSModuleID = 2; -- FOR STOCKLINE

				UPDATE SL SET 
					SL.Site = S.Name,
					SL.Warehouse = W.Name,
					SL.Location = L.Name,
					SL.Shelf = SF.Name,
					SL.Bin = B.Name
				FROM [dbo].[StocklineBatchDetails] SL WITH(NOLOCK)
					INNER JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = SL.ItemMasterId
					INNER JOIN dbo.Site S WITH(NOLOCK) ON S.SiteId = SL.SiteId
					LEFT JOIN dbo.Warehouse W WITH(NOLOCK) ON W.WarehouseId = SL.WarehouseId
					LEFT JOIN dbo.Location L WITH(NOLOCK) ON L.LocationId = SL.LocationId
					LEFT JOIN dbo.Shelf SF WITH(NOLOCK) ON SF.ShelfId = SL.ShelfId
					LEFT JOIN dbo.Bin B WITH(NOLOCK) ON B.BinId = SL.BinId
				WHERE SL.StocklineId = @StocklineId;
			END		   
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateStocklineBatchDetailsColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StocklineId, '') + ''
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