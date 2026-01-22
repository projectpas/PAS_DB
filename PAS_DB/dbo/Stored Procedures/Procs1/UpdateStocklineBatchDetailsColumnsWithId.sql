/*************************************************************             
 ** File:   [[UpdateStocklineBatchDetailsColumnsWithId]]             
 ** Author:   
 ** Description: This stored procedure is used to Update Stockline BatchDetails Columns With Id
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			Author			Change Description              
 ** --   --------		-------			-------------------------------            
	1		-				-			CREATED
	2    20-Jan-2025   RAJESH GAMI      Update SP due to performance 
	EXEC [dbo].[UpdateStocklineBatchDetailsColumnsWithId] 184058
**************************************************************/  
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
				
				IF OBJECT_ID(N'tempdb..#tmpStocklineBatchDetails') IS NOT NULL
				BEGIN
				DROP TABLE #tmpStocklineBatchDetails
				END
				IF OBJECT_ID(N'tempdb..#tmpItemMaster') IS NOT NULL
				BEGIN
				DROP TABLE #tmpItemMaster
				END

				SELECT * INTO #tmpStocklineBatchDetails FROM (SELECT * FROM [dbo].[StocklineBatchDetails] SLB WITH(NOLOCK) WHERE SLB.StocklineId = @StocklineId) AS Result
				SELECT * INTO #tmpItemMaster FROM (SELECT IM.* FROM [dbo].[ItemMaster] IM WITH(NOLOCK) INNER JOIN #tmpStocklineBatchDetails STK ON STK.ItemMasterId = IM.ItemMasterId) AS ItM

				IF OBJECT_ID(N'tempdb..#tmpFinalTable') IS NOT NULL
				BEGIN
				DROP TABLE #tmpFinalTable
				END

				SELECT * INTO #tmpFinalTable FROM 
				(
					SELECT 
						SL.StocklineBatchDetailId,
						S.[Name] [Site],
						W.[Name] Warehouse,
						L.[Name] [Location],
						SF.[Name] Shelf,
						B.[Name] Bin
					FROM #tmpStocklineBatchDetails SL
					INNER JOIN #tmpItemMaster IM ON IM.ItemMasterId = SL.ItemMasterId
					INNER JOIN dbo.[Site] S WITH(NOLOCK) ON S.SiteId = SL.SiteId
					LEFT JOIN dbo.Warehouse W WITH(NOLOCK) ON W.WarehouseId = SL.WarehouseId
					LEFT JOIN dbo.[Location] L WITH(NOLOCK) ON L.LocationId = SL.LocationId
					LEFT JOIN dbo.Shelf SF WITH(NOLOCK) ON SF.ShelfId = SL.ShelfId
					LEFT JOIN dbo.Bin B WITH(NOLOCK) ON B.BinId = SL.BinId
				) as finalTable
				
				UPDATE SL WITH (ROWLOCK)
					SET SL.Site = F.Site,
						SL.Warehouse = F.Warehouse,
						SL.Location = F.Location,
						SL.Shelf = F.Shelf,
						SL.Bin = F.Bin
					FROM dbo.StocklineBatchDetails SL
					INNER JOIN #tmpFinalTable F ON F.StocklineBatchDetailId = SL.StocklineBatchDetailId
					
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