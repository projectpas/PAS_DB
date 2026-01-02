
--EXEC sp_help 'Stockline';
--EXEC sp_help 'StocklineAudit';

/*************************************************************             
 ** File:   [USP_AlterColumnsToDecimal]            
 ** Author:   RAJESH GAMI
 ** Description: This stored procedure is used to Alter Columns To Decimal
 ** Purpose:           
 ** Date:   24/11/2025 

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History             
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    24/11/2025   RAJESH GAMI		Created
**************************************************************/
CREATE   PROCEDURE dbo.USP_AlterColumnsToDecimal
(
    @TableName SYSNAME,               -- Table name
    @ColumnList NVARCHAR(MAX)         -- Comma-separated column names
)
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------------
    -- Convert column list into table variable
    --------------------------------------------------------
    DECLARE @Columns TABLE (ColName SYSNAME);
    DECLARE @Pos INT=1, @NextPos INT, @Col SYSNAME;

    WHILE @Pos <= LEN(@ColumnList)
    BEGIN
        SET @NextPos = CHARINDEX(',', @ColumnList + ',', @Pos);
        --SET @Col = LTRIM(RTRIM(SUBSTRING(@ColumnList, @Pos, @NextPos - @Pos)));
		SET @Col = REPLACE(REPLACE(LTRIM(RTRIM(SUBSTRING(@ColumnList, @Pos, @NextPos - @Pos))),'[', ''),']', '');

        INSERT INTO @Columns VALUES (@Col);

        SET @Pos = @NextPos + 1;
    END

    --------------------------------------------------------
    -- Temp table for dropped constraints
    --------------------------------------------------------
    IF OBJECT_ID('tempdb..#DroppedConstraints') IS NOT NULL
        DROP TABLE #DroppedConstraints;

    CREATE TABLE #DroppedConstraints
    (
        ConstraintName NVARCHAR(255),
        ColumnName NVARCHAR(255),
        DefaultDefinition NVARCHAR(4000)
    );

    --------------------------------------------------------
    -- Insert matching constraints into temp table
    --------------------------------------------------------
    INSERT INTO #DroppedConstraints (ConstraintName, ColumnName, DefaultDefinition)
    SELECT 
        dc.name,
        c.name,
        dc.definition
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c 
        ON dc.parent_object_id = c.object_id 
        AND dc.parent_column_id = c.column_id
    WHERE dc.parent_object_id = OBJECT_ID(@TableName)
    AND c.name IN (SELECT ColName FROM @Columns);

    --------------------------------------------------------
    -- Drop constraints
    --------------------------------------------------------
    DECLARE @DropSQL NVARCHAR(MAX) = N'';

    SELECT @DropSQL = @DropSQL +
        'ALTER TABLE ' + @TableName + 
        ' DROP CONSTRAINT [' + ConstraintName + '];' + CHAR(10)
    FROM #DroppedConstraints;

    PRINT @DropSQL;
    EXEC (@DropSQL);

    --------------------------------------------------------
    -- ALTER COLUMNS to DECIMAL(18,6)
    --------------------------------------------------------
    DECLARE @AlterSQL NVARCHAR(MAX) = N'';

    SELECT @AlterSQL = @AlterSQL +
        'ALTER TABLE ' + @TableName +
        ' ALTER COLUMN [' + ColName + '] DECIMAL(18,6) NULL;' + CHAR(10)
    FROM @Columns;

    PRINT @AlterSQL;
    EXEC (@AlterSQL);

    --------------------------------------------------------
    -- Re-create dropped constraints
    --------------------------------------------------------
    DECLARE @AddSQL NVARCHAR(MAX) = N'';

    SELECT @AddSQL = @AddSQL +
        'ALTER TABLE ' + @TableName +
        ' ADD CONSTRAINT [' + ConstraintName + '] DEFAULT ' + DefaultDefinition +
        ' FOR [' + ColumnName + '];' + CHAR(10)
    FROM #DroppedConstraints;

    PRINT @AddSQL;
    EXEC (@AddSQL);

END