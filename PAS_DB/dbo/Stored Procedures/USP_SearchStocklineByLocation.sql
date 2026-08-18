/*************************************************************
 ** File:   [USP_SearchStocklineByLocation]
 ** Description: Searches Stockline records by one or more Site/Warehouse/Location/Shelf/Bin ids.
                 Each dimension is optional - an empty table-valued parameter means "no filter on that dimension".
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

-- EXEC USP_SearchStocklineByLocation
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_SearchStocklineByLocation]
	@tbl_SiteIds TVP_BigInt READONLY,
	@tbl_WarehouseIds TVP_BigInt READONLY,
	@tbl_LocationIds TVP_BigInt READONLY,
	@tbl_ShelfIds TVP_BigInt READONLY,
	@tbl_BinIds TVP_BigInt READONLY,
	@MasterCompanyId INT
AS
BEGIN

 SET NOCOUNT ON;

  BEGIN TRY
    BEGIN
		SELECT TOP 500
			s.[StockLineId],
			s.[PartNumber],
			s.[PNDescription] AS [PartDescription],
			s.[StockLineNumber],
			s.[ControlNumber],
			s.[IdNumber],
			s.[Manufacturer],
			s.[Condition],
			s.[SerialNumber],
			s.[QuantityOnHand],
			s.[QuantityAvailable],
			s.[Site],
			s.[Warehouse],
			s.[Location],
			s.[Shelf],
			s.[Bin]
		FROM dbo.Stockline s
		WHERE s.MasterCompanyId = @MasterCompanyId
			AND (NOT EXISTS (SELECT 1 FROM @tbl_SiteIds) OR s.SiteId IN (SELECT [Value] FROM @tbl_SiteIds))
			AND (NOT EXISTS (SELECT 1 FROM @tbl_WarehouseIds) OR s.WarehouseId IN (SELECT [Value] FROM @tbl_WarehouseIds))
			AND (NOT EXISTS (SELECT 1 FROM @tbl_LocationIds) OR s.LocationId IN (SELECT [Value] FROM @tbl_LocationIds))
			AND (NOT EXISTS (SELECT 1 FROM @tbl_ShelfIds) OR s.ShelfId IN (SELECT [Value] FROM @tbl_ShelfIds))
			AND (NOT EXISTS (SELECT 1 FROM @tbl_BinIds) OR s.BinId IN (SELECT [Value] FROM @tbl_BinIds))
		ORDER BY s.StockLineId DESC;
    END
  END TRY
  BEGIN CATCH
   IF @@trancount > 0
    PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SearchStocklineByLocation'
              , @ProcedureParameters VARCHAR(3000)  = '@MasterCompanyId = ''' + CONVERT(VARCHAR(20), @MasterCompanyId) + ''''
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