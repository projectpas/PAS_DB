/****************************************************************************************************
** File:        [USP_Agent_SearchStock]
** Description: PAS Assistant (AI agent) tool "search_stock".
**              Inventory stock level (quantity on hand / available) for a part number, per stock line,
**              with description, manufacturer, type, condition, serial number, UOM, unit cost,
**              vendor, PO number and traceability, plus totals per part number and condition.
**
**              Always returns TWO result sets:
**                1. Totals per part number + condition (max 20 rows)
**                2. Stock lines (max @Top rows, most available first, TotalRecords = full count)
**
** Parameters:  @MasterCompanyId   - required, tenant filter
**              @PartNumber        - required, contains match on part number
**              @Condition         - optional, exact condition code (NE, OH, SV, AR ...)
**              @OnlyAvailable     - optional, 1 = only stock lines with quantity available > 0
**              @Top               - max stock lines returned
*****************************************************************************************************
** Change History
*****************************************************************************************************
** PR   Date         Author             Change Description
** --   ----------   -------------      --------------------------------
** 1    24/11/2026   Hemant             Created (PAS Assistant stock level tool)
*****************************************************************************************************/
-- EXEC [dbo].[USP_Agent_SearchStock] @MasterCompanyId = 1, @PartNumber = 'BELLCRANK';
CREATE   PROCEDURE [dbo].[USP_Agent_SearchStock]
    @MasterCompanyId    INT,
    @PartNumber         VARCHAR(100),
    @Condition          VARCHAR(20) = NULL,
    @OnlyAvailable      BIT         = 0,
    @Top                INT         = 25
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @Condition = NULLIF(LTRIM(RTRIM(@Condition)), '');

        -- "contains" pattern; LIKE wildcards typed by the user are matched literally
        DECLARE @PnPattern VARCHAR(220) =
            '%' + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(@PartNumber, ''))), '[', '[[]'), '%', '[%]'), '_', '[_]') + '%';

        -- Matching stock lines, collected once and reused by both result sets
        DECLARE @Lines TABLE
        (
            StockLineId     BIGINT PRIMARY KEY,
            ItemMasterId    BIGINT,
            VendorId        BIGINT
        );

        INSERT INTO @Lines (StockLineId, ItemMasterId, VendorId)
        SELECT SL.StockLineId, SL.ItemMasterId, SL.VendorId
        FROM [dbo].[Stockline] SL WITH (NOLOCK)
        WHERE SL.MasterCompanyId = @MasterCompanyId
          AND SL.IsDeleted = 0
          AND SL.IsActive  = 1
          AND SL.PartNumber LIKE @PnPattern
          AND (@Condition IS NULL OR SL.Condition = @Condition)
          AND (ISNULL(@OnlyAvailable, 0) = 0 OR SL.QuantityAvailable > 0);

        DECLARE @TotalRecords INT = (SELECT COUNT(1) FROM @Lines);

        -- Result set 1: totals per part number + condition
        SELECT TOP (20)
            SL.PartNumber                                       AS partNumber,
            SL.Condition                                        AS condition,
            COUNT(1)                                            AS stockLines,
            SUM(ISNULL(SL.QuantityOnHand, 0))                   AS qtyOnHand,
            SUM(ISNULL(SL.QuantityAvailable, 0))                AS qtyAvailable,
            SUM(ISNULL(SL.QuantityReserved, 0))                 AS qtyReserved
        FROM @Lines L
        INNER JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.StockLineId = L.StockLineId
        GROUP BY SL.PartNumber, SL.Condition
        ORDER BY SL.PartNumber, SL.Condition;

        -- Result set 2: stock lines
        SELECT TOP (@Top)
            SL.PartNumber                                       AS partNumber,
            IM.PartDescription                                  AS [description],
            SL.Manufacturer                                     AS manufacturer,
            SL.ItemType                                         AS [type],
            SL.Condition                                        AS condition,
            SL.SerialNumber                                     AS serialNumber,
            SL.QuantityAvailable                                AS qtyAvailable,
            SL.QuantityOnHand                                   AS qtyOnHand,
            SL.QuantityReserved                                 AS qtyReserved,
            SL.UnitOfMeasure                                    AS uom,
            SL.UnitCost                                         AS unitCost,
            SL.UnitSalesPrice                                   AS unitSalesPrice,
            V.VendorName                                        AS vendor,
            SL.PurchaseOrderNumber                              AS poNumber,
            SL.TraceableToName                                  AS traceability,
            SL.StockLineNumber                                  AS stockLineNumber,
            SL.ControlNumber                                    AS controlNumber,
            SL.Site                                             AS site,
            SL.Warehouse                                        AS warehouse,
            SL.Location                                         AS location,
            SL.Shelf                                            AS shelf,
            SL.Bin                                              AS bin,
            CONVERT(VARCHAR(10), SL.ReceivedDate, 23)           AS receivedDate,
            SL.IsCustomerStock                                  AS isCustomerStock,
            @TotalRecords                                       AS TotalRecords
        FROM @Lines L
        INNER JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.StockLineId = L.StockLineId
        LEFT JOIN  [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = L.ItemMasterId
        LEFT JOIN  [dbo].[Vendor]     V  WITH (NOLOCK) ON V.VendorId      = L.VendorId
        ORDER BY SL.PartNumber, SL.QuantityAvailable DESC, SL.StockLineId DESC;

    END TRY

    BEGIN CATCH

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_Agent_SearchStock',
            @ProcedureParameters VARCHAR(3000) =
                  '@MasterCompanyId = '  + ISNULL(CAST(@MasterCompanyId AS VARCHAR(20)), 'NULL')
                + ', @PartNumber = '     + ISNULL(@PartNumber, 'NULL')
                + ', @Condition = '      + ISNULL(@Condition, 'NULL')
                + ', @OnlyAvailable = '  + ISNULL(CAST(@OnlyAvailable AS VARCHAR(5)), 'NULL')
                + ', @Top = '            + ISNULL(CAST(@Top AS VARCHAR(10)), 'NULL'),
            @ApplicationName     VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected error in the database. Please provide error number %d to the support team.',
            16, 1, @ErrorLogID
        );

        RETURN 1;

    END CATCH;
END;
