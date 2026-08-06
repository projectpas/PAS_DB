/*********************************************************************************************
 ** File:   [USP_QueryStocklineAcrossDatabase]
 ** Author:  Claude
 ** Description: Dynamically searches every table in the database that contains a StockLineId
 **              column and returns all rows matching the supplied StockLineId value, along
 **              with the source schema, table name, and row count for each hit.
 ** Purpose:     Diagnostic / audit tool – find every record tied to a given StockLineId.
 **
 ** PARAMETERS:
 **   @StockLineId     BIGINT  – The StockLineId value to search for (e.g. 220005)
 **   @ExcludeAudit    BIT     – When 1, skip tables whose names end with 'Audit'  (default 0)
 **   @ExcludeHangFire BIT     – When 1, skip the HangFire schema tables           (default 1)
 **
 ** RETURN VALUE:  Multiple result sets – one per table that contains matching rows.
 **               A final summary result set lists every table searched and its row count.
 **
 ** Usage:
 **   EXEC dbo.USP_QueryStocklineAcrossDatabase @StockLineId = 220005;
 **   EXEC dbo.USP_QueryStocklineAcrossDatabase @StockLineId = 220005, @ExcludeAudit = 1;
 **
 *********************************************************************************************
 ** Change History
 *********************************************************************************************
 ** PR   Date         Author    Change Description
 ** --   ----------   -------   --------------------------------
    1    2026-04-22   Claude    Created
**********************************************************************************************/

CREATE PROCEDURE [dbo].[USP_QueryStocklineAcrossDatabase]
    @StockLineId     BIGINT,
    @ExcludeAudit    BIT = 0,
    @ExcludeHangFire BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    -- -------------------------------------------------------------------------
    -- Summary table – collects one row per table checked
    -- -------------------------------------------------------------------------
    DECLARE @Summary TABLE
    (
        SchemaName  NVARCHAR(128),
        TableName   NVARCHAR(128),
        RowsMatched INT
    );

    -- -------------------------------------------------------------------------
    -- Cursor over every table that owns a column called StockLineId
    -- -------------------------------------------------------------------------
    DECLARE @SchemaName  NVARCHAR(128);
    DECLARE @TableName   NVARCHAR(128);
    DECLARE @ColumnName  NVARCHAR(128);
    DECLARE @SQL         NVARCHAR(MAX);
    DECLARE @CountSQL    NVARCHAR(MAX);
    DECLARE @RowCount    INT;
    DECLARE @Params      NVARCHAR(200) = N'@StockLineId BIGINT, @RowCount INT OUTPUT';

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            s.name  AS SchemaName,
            t.name  AS TableName,
            c.name  AS ColumnName
        FROM
            sys.columns        c
            INNER JOIN sys.tables  t ON t.object_id = c.object_id
            INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
        WHERE
            c.name LIKE 'StockLineId'   -- exact match, case-insensitive by default collation
            AND t.type = 'U'            -- user tables only
            AND (
                @ExcludeHangFire = 0
                OR s.name <> 'HangFire'
            )
            AND (
                @ExcludeAudit = 0
                OR t.name NOT LIKE '%Audit'
            )
        ORDER BY
            s.name,
            t.name;

    OPEN cur;

    FETCH NEXT FROM cur INTO @SchemaName, @TableName, @ColumnName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Count matching rows first so we can record in summary
        SET @CountSQL = N'SELECT @RowCount = COUNT(1) FROM '
                      + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName)
                      + N' WITH (NOLOCK) WHERE ' + QUOTENAME(@ColumnName) + N' = @StockLineId';

        EXEC sp_executesql
            @CountSQL,
            @Params,
            @StockLineId = @StockLineId,
            @RowCount    = @RowCount OUTPUT;

        INSERT INTO @Summary (SchemaName, TableName, RowsMatched)
        VALUES (@SchemaName, @TableName, @RowCount);

        -- Only emit a result set for tables that actually have matching rows
        IF @RowCount > 0
        BEGIN
            -- Build SELECT that prefixes each row with the source table info
            SET @SQL = N'SELECT '
                     + QUOTENAME(@SchemaName, '''') + N' AS [SchemaName], '
                     + QUOTENAME(@TableName,  '''') + N' AS [TableName], '
                     + N'* '
                     + N'FROM ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName)
                     + N' WITH (NOLOCK) '
                     + N'WHERE ' + QUOTENAME(@ColumnName) + N' = @StockLineId '
                     + N'ORDER BY ' + QUOTENAME(@ColumnName) + N';';

            EXEC sp_executesql
                @SQL,
                N'@StockLineId BIGINT',
                @StockLineId = @StockLineId;
        END

        FETCH NEXT FROM cur INTO @SchemaName, @TableName, @ColumnName;
    END

    CLOSE cur;
    DEALLOCATE cur;

    -- -------------------------------------------------------------------------
    -- Final summary result set
    -- -------------------------------------------------------------------------
    SELECT
        SchemaName,
        TableName,
        RowsMatched,
        CASE WHEN RowsMatched > 0 THEN 'HIT' ELSE 'no rows' END AS Status
    FROM
        @Summary
    ORDER BY
        RowsMatched DESC,
        SchemaName,
        TableName;

END
