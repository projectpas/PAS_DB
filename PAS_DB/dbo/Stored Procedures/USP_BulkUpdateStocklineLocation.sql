/*************************************************************
 ** File:   [USP_BulkUpdateStocklineLocation]
 ** Description: Bulk-updates the Site/Warehouse/Location/Shelf/Bin location fields
                 for a set of Stockline records in a single set-based UPDATE.
                 Any level not supplied (NULL) clears that level and everything below it
                 on every matched record. Returns the Updated/NotFound status per submitted StockLineId.
 ** Date:   08/17/2026
 ** Author:  Nakul

 ** PARAMETERS:

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    08/17/2026  Nakul     Created

-- EXEC USP_BulkUpdateStocklineLocation
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_BulkUpdateStocklineLocation]
	@tbl_StockLineIds TVP_BigInt READONLY,
	@SiteId BIGINT,
	@Site VARCHAR(100),
	@WarehouseId BIGINT = NULL,
	@Warehouse VARCHAR(100) = NULL,
	@LocationId BIGINT = NULL,
	@Location VARCHAR(100) = NULL,
	@ShelfId BIGINT = NULL,
	@Shelf VARCHAR(100) = NULL,
	@BinId BIGINT = NULL,
	@Bin VARCHAR(100) = NULL,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN

 SET NOCOUNT ON;
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION
    BEGIN
		IF OBJECT_ID(N'tempdb..#BulkUpdateLocationResult') IS NOT NULL
		BEGIN
			DROP TABLE #BulkUpdateLocationResult
		END

		CREATE TABLE #BulkUpdateLocationResult
		(
			[StockLineId] BIGINT NOT NULL,
			[Status] VARCHAR(20) NOT NULL
		);

		-- Submitted ids that don't match an existing Stockline row for this company
		INSERT INTO #BulkUpdateLocationResult ([StockLineId], [Status])
		SELECT t.[Value], 'NotFound'
		FROM @tbl_StockLineIds t
		WHERE NOT EXISTS (
			SELECT 1 FROM dbo.Stockline s WITH (NOLOCK)
			WHERE s.StockLineId = t.[Value] AND s.MasterCompanyId = @MasterCompanyId
		);

		UPDATE s
		SET
			s.SiteId = @SiteId,
			s.Site = @Site,
			s.WarehouseId = @WarehouseId,
			s.Warehouse = @Warehouse,
			s.LocationId = @LocationId,
			s.Location = @Location,
			s.ShelfId = @ShelfId,
			s.Shelf = @Shelf,
			s.BinId = @BinId,
			s.Bin = @Bin,
			s.UpdatedBy = @UpdatedBy,
			s.UpdatedDate = GETDATE()
		FROM dbo.Stockline s 
		INNER JOIN @tbl_StockLineIds t ON s.StockLineId = t.[Value]
		WHERE s.MasterCompanyId = @MasterCompanyId;

		INSERT INTO #BulkUpdateLocationResult ([StockLineId], [Status])
		SELECT t.[Value], 'Updated'
		FROM @tbl_StockLineIds t
		WHERE EXISTS (
			SELECT 1 FROM dbo.Stockline s WITH (NOLOCK)
			WHERE s.StockLineId = t.[Value] AND s.MasterCompanyId = @MasterCompanyId
		);

		SELECT [StockLineId], [Status] FROM #BulkUpdateLocationResult;

		DROP TABLE #BulkUpdateLocationResult;
    END
    COMMIT  TRANSACTION

  END TRY
  BEGIN CATCH
   IF @@trancount > 0
    PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_BulkUpdateStocklineLocation'
              , @ProcedureParameters VARCHAR(3000)  = '@SiteId = ''' + CONVERT(VARCHAR(20), @SiteId) + ''''
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