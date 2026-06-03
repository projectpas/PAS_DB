
CREATE     FUNCTION [dbo].[fn_TransformSelectList] 
( 
    @SelectList    NVARCHAR(MAX), 
    @TextTransform NVARCHAR(10) 
) 
RETURNS NVARCHAR(MAX) 
AS 
BEGIN 
    IF @TextTransform IS NULL OR @TextTransform = '' OR UPPER(@TextTransform) = 'NORMAL' 
        RETURN @SelectList; 

    DECLARE @Transform NVARCHAR(10);

    SET @Transform = CASE UPPER(@TextTransform) 
                        WHEN 'UPPER' THEN 'UPPER' 
                        WHEN 'LOWER' THEN 'LOWER' 
                        ELSE NULL 
                     END; 

    IF @Transform IS NULL 
        RETURN @SelectList; 

    DECLARE @Result       NVARCHAR(MAX) = ''; 
    DECLARE @Column       NVARCHAR(MAX) = '';
    DECLARE @ColumnExpr   NVARCHAR(MAX);
    DECLARE @AliasIndex   INT; 
    DECLARE @Char         NCHAR(1);
    DECLARE @Depth        INT = 0;      
    DECLARE @i            INT = 1;
    DECLARE @Len          INT = DATALENGTH(@SelectList)/2;

    WHILE @i <= @Len
    BEGIN
        SET @Char = SUBSTRING(@SelectList, @i, 1);

        -- Track depth
        IF @Char = '(' SET @Depth = @Depth + 1;
        IF @Char = ')' SET @Depth = @Depth - 1;

        --  Only split on comma at top level (depth = 0)
        IF @Char = ',' AND @Depth = 0
        BEGIN
            -- Process the column collected so far
            SET @Column = LTRIM(RTRIM(@Column));
            SET @AliasIndex = CHARINDEX(' AS [', @Column);

            IF @AliasIndex > 0
            BEGIN
                SET @ColumnExpr = LTRIM(RTRIM(LEFT(@Column, @AliasIndex - 1)));
                SET @Column = @Transform + '(' + @ColumnExpr + ')'
                              + SUBSTRING(@Column, @AliasIndex, DATALENGTH(@Column)/2);
            END
            ELSE
            BEGIN
                SET @Column = @Transform + '(' + @Column + ')';
            END

            SET @Result = @Result + @Column + ', ';
            SET @Column = '';  -- Reset for next column
        END
        ELSE
        BEGIN
            SET @Column = @Column + @Char;
        END

        SET @i = @i + 1;
    END

    -- Process last column
    SET @Column = LTRIM(RTRIM(@Column));
    IF LEN(@Column) > 0
    BEGIN
        SET @AliasIndex = CHARINDEX(' AS [', @Column);

        IF @AliasIndex > 0
        BEGIN
            SET @ColumnExpr = LTRIM(RTRIM(LEFT(@Column, @AliasIndex - 1)));
            SET @Column = @Transform + '(' + @ColumnExpr + ')'
                          + SUBSTRING(@Column, @AliasIndex, DATALENGTH(@Column)/2);
        END
        ELSE
        BEGIN
            SET @Column = @Transform + '(' + @Column + ')';
        END

        SET @Result = @Result + @Column;
    END

    -- Remove trailing ', ' if exists
    IF RIGHT(@Result, 2) = ', '
        SET @Result = LEFT(@Result, DATALENGTH(@Result)/2 - 2);

    RETURN @Result; 
END