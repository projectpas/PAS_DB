/*************************************************************           
 ** File:   [usp_GetInventoryDataForPowerBIReport]
 ** Author:    SUMIT KUMAR
 ** Description: Fetches inventory dashboard data for the PowerBI report.
 **              The @Type parameter controls which dataset is returned:
 **                  'KPI'              -> Summary KPI cards (one aggregated row)
 **                  'TopManufacturers' -> Inventory value grouped by manufacturer
 **                  'ConditionWise'    -> Quantity grouped by condition code
 **                  'InventoryData'    -> Full row-level detail grid
 ** Purpose:          
 ** Date:   09-Jul-2026
 ** PARAMETERS:
 **     @MasterCompanyId    INT             - The master company to filter data for
 **     @Type               VARCHAR(50)     - Report type selector (see above)
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
  ** S NO   Date            Author              Change Description              
 ** --   --------         -------              --------------------------------            
	1    09-Jul-2026     Sumit Kumar            Created

**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetInventoryDataForPowerBIReport]
(
    @MasterCompanyId    INT,
    @Type               VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        -- -------------------------------------------------------
        -- KPI Summary Cards
        -- Returns one aggregated row for all top-level KPI tiles:
        --   TotalAvailableQty, TotalInTransitQty, TotalInventoryValue,
        --   TotalParts, TotalReservedQty, TotalStockLines
        -- -------------------------------------------------------
        IF @Type = 'KPI'
        BEGIN
            SELECT
                SUM(ISNULL(SL.[QuantityAvailable], 0))                                          AS TotalAvailableQty,
                SUM(ISNULL(SL.[QuantityOnOrder],   0))                                          AS TotalInTransitQty,
                SUM(ISNULL(SL.[QuantityAvailable], 0) * ISNULL(SL.[UnitCost], 0))              AS TotalInventoryValue,
                COUNT(DISTINCT SL.[ItemMasterId])                                                AS TotalParts,
                SUM(ISNULL(SL.[QuantityReserved],  0))                                          AS TotalReservedQty,
                COUNT(SL.[StockLineId])                                                          AS TotalStockLines
            FROM
                [dbo].[StockLine] SL WITH (NOLOCK)
            WHERE
                SL.[MasterCompanyId] = @MasterCompanyId
                AND SL.[IsDeleted]   = 0
                AND SL.[IsActive]    = 1;
        END

        -- -------------------------------------------------------
        -- Top Manufacturers
        -- Returns inventory value grouped by manufacturer name,
        -- ordered descending so PowerBI shows the top manufacturers.
        -- -------------------------------------------------------
        ELSE IF @Type = 'TopManufacturers'
        BEGIN
            SELECT
                ISNULL(SL.[Manufacturer], 'Unknown')                                            AS ManufacturerName,
                SUM(ISNULL(SL.[QuantityAvailable], 0) * ISNULL(SL.[UnitCost], 0))              AS TotalInventoryValue
            FROM
                [dbo].[StockLine] SL WITH (NOLOCK)
            WHERE
                SL.[MasterCompanyId] = @MasterCompanyId
                AND SL.[IsDeleted]   = 0
                AND SL.[IsActive]    = 1
            GROUP BY
                ISNULL(SL.[Manufacturer], 'Unknown')
            ORDER BY
                TotalInventoryValue DESC;
        END

        -- -------------------------------------------------------
        -- Condition-Wise Breakdown
        -- Returns total quantity grouped by condition code for the
        -- "Condition Wise Inventory" area chart.
        -- -------------------------------------------------------
        ELSE IF @Type = 'ConditionWise'
        BEGIN
            SELECT
                ISNULL(SL.[Condition], 'Unknown')                                               AS Condition,
                SUM(ISNULL(SL.[QuantityAvailable], 0))                                          AS TotalQuantity
            FROM
                [dbo].[StockLine] SL WITH (NOLOCK)
            WHERE
                SL.[MasterCompanyId] = @MasterCompanyId
                AND SL.[IsDeleted]   = 0
                AND SL.[IsActive]    = 1
            GROUP BY
                ISNULL(SL.[Condition], 'Unknown')
            ORDER BY
                TotalQuantity DESC;
        END

        -- -------------------------------------------------------
        -- Full Inventory Detail Grid
        -- Returns the row-level data for the "Inventory Data" grid
        -- in the PowerBI report.
        -- -------------------------------------------------------
        ELSE IF @Type = 'InventoryData'
        BEGIN
            SELECT
                SL.[StockLineId],
                ISNULL(SL.[Bin],          '')                                                   AS Bin,
                ISNULL(SL.[Condition],    '')                                                   AS Condition,
                ISNULL(SL.[QuantityAvailable], 0) * ISNULL(SL.[UnitCost], 0)                   AS InventoryValue,
                ISNULL(SL.[Location],     '')                                                   AS Location,
                ISNULL(SL.[Manufacturer], 'Unknown')                                            AS ManufacturerName,
                ISNULL(SL.[QuantityAvailable], 0)                                               AS QuantityAvailable,
                ISNULL(SL.[QuantityReserved],  0)                                               AS QuantityReserved,
                ISNULL(SL.[Shelf],        '')                                                   AS Shelf,
                ISNULL(SL.[UnitCost],     0)                                                    AS UnitCost,
                ISNULL(SL.[PartNumber],   '')                                                   AS PartNumber,
                ISNULL(SL.[Site],         '')                                                   AS Site,
                ISNULL(SL.[Warehouse],    '')                                                   AS Warehouse
            FROM
                [dbo].[StockLine] SL WITH (NOLOCK)
            WHERE
                SL.[MasterCompanyId] = @MasterCompanyId
                AND SL.[IsDeleted]   = 0
                AND SL.[IsActive]    = 1
            ORDER BY
                SL.[StockLineId];
        END

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                ,
                @AdhocComments VARCHAR(150) = '[usp_GetInventoryDataForPowerBIReport]',
                @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) +
                '@Parameter2 = ''' + CAST(ISNULL(@Type, '') AS VARCHAR(50)),
                @ApplicationName VARCHAR(100) = 'PAS'

        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC Splogexception @DatabaseName = @DatabaseName,
                            @AdhocComments = @AdhocComments,
                            @ProcedureParameters = @ProcedureParameters,
                            @ApplicationName = @ApplicationName,
                            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN (1);
    END CATCH
END
GO
