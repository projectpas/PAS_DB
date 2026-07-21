CREATE FUNCTION [dbo].[fn_ConvertUOM]
(
    @Qty DECIMAL(18,6),
    @FromUOM VARCHAR(50),
    @ToUOM VARCHAR(50),
    @IsCost BIT = 0,
    @MasterCompanyId INT
)
RETURNS DECIMAL(18,6)
AS
BEGIN

    IF (ISNULL(@MasterCompanyId,0) = 0)
    BEGIN
        SELECT TOP 1 @MasterCompanyId = MasterCompanyId
        FROM dbo.MasterCompany WITH(NOLOCK)
        WHERE ISNULL(IsActive,0) = 1;
    END

    IF(ISNULL(@FromUOM,'') = ISNULL(@ToUOM,''))
    BEGIN
        RETURN ROUND(@Qty,6);
    END

    DECLARE
        @Factor DECIMAL(18,8) = NULL,
        @IsMultiply BIT = 0,
        @IsReverse BIT = 0;

    -- Direct conversion
    SELECT TOP 1
        @Factor = Factor,
        @IsMultiply = IsMultiply,
        @IsReverse = 0
    FROM dbo.UOMConversion WITH(NOLOCK)
    WHERE FromUOM = @FromUOM
      AND ToUOM = @ToUOM
      AND MasterCompanyId = @MasterCompanyId;

    -- Reverse conversion
    IF @Factor IS NULL
    BEGIN
        SELECT TOP 1
            @Factor = Factor,
            @IsMultiply = IsMultiply,
            @IsReverse = 1
        FROM dbo.UOMConversion WITH(NOLOCK)
        WHERE FromUOM = @ToUOM
          AND ToUOM = @FromUOM
          AND MasterCompanyId = @MasterCompanyId;
    END

    -- No conversion found
    IF @Factor IS NULL
    BEGIN
        RETURN ROUND(@Qty,6);
    END

    ----------------------------------------------------------
    -- Quantity Conversion
    ----------------------------------------------------------
    IF @IsCost = 0
    BEGIN
        IF @IsReverse = 0
        BEGIN
            RETURN ROUND(
                CASE
                    WHEN @IsMultiply = 1 THEN @Qty * @Factor
                    ELSE @Qty / @Factor
                END
            ,6);
        END
        ELSE
        BEGIN
            RETURN ROUND(
                CASE
                    WHEN @IsMultiply = 1 THEN @Qty / @Factor
                    ELSE @Qty * @Factor
                END
            ,6);
        END
    END

    ----------------------------------------------------------
    -- Cost / Price Conversion
    ----------------------------------------------------------
    IF @IsCost = 1
    BEGIN
        IF @IsReverse = 0
        BEGIN
            RETURN ROUND(
                CASE
                    WHEN @IsMultiply = 1 THEN @Qty / @Factor
                    ELSE @Qty * @Factor
                END
            ,6);
        END
        ELSE
        BEGIN
            RETURN ROUND(
                CASE
                    WHEN @IsMultiply = 1 THEN @Qty * @Factor
                    ELSE @Qty / @Factor
                END
            ,6);
        END
    END

    RETURN ROUND(@Qty,6);

END