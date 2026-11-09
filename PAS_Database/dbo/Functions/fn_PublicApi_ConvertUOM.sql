
---------------------------------------------------------------------------------------------
-- 4.4 UOM conversion used by the receiving and sales order procedures. Same rules as PAS dbo.fn_ConvertUOM:
-- the company's UOMConversion row FromUOM -> ToUOM, otherwise the reverse row, otherwise unchanged.
-- @IsCost = 0 converts a quantity, 1 a unit price / cost (the inverse). Returns DECIMAL(38,6)
-- so a wrong stored quantity cannot overflow, and ignores a zero factor.
---------------------------------------------------------------------------------------------
CREATE   FUNCTION [dbo].[fn_PublicApi_ConvertUOM]
(
    @Value           DECIMAL(38, 6),
    @FromUOM         VARCHAR(50),
    @ToUOM           VARCHAR(50),
    @IsCost          BIT,
    @MasterCompanyId INT
)
RETURNS DECIMAL(38, 6)
AS
BEGIN
    IF @Value IS NULL OR ISNULL(@FromUOM, '') = ISNULL(@ToUOM, '')
        RETURN @Value;

    DECLARE @Factor DECIMAL(18, 8), @IsMultiply BIT, @IsReverse BIT = 0;

    SELECT TOP (1) @Factor = NULLIF([Factor], 0), @IsMultiply = [IsMultiply]
    FROM [dbo].[UOMConversion] WITH (NOLOCK)
    WHERE [FromUOM] = @FromUOM AND [ToUOM] = @ToUOM AND [MasterCompanyId] = @MasterCompanyId;

    IF @Factor IS NULL
        SELECT TOP (1) @Factor = NULLIF([Factor], 0), @IsMultiply = [IsMultiply], @IsReverse = 1
        FROM [dbo].[UOMConversion] WITH (NOLOCK)
        WHERE [FromUOM] = @ToUOM AND [ToUOM] = @FromUOM AND [MasterCompanyId] = @MasterCompanyId;

    IF @Factor IS NULL
        RETURN @Value;

    -- Multiply when exactly one of "multiply factor", "reverse row", "unit price" applies (as in fn_ConvertUOM).
    -- DECIMAL(28,6) keeps enough scale in the division to round exactly like fn_ConvertUOM.
    DECLARE @V DECIMAL(28, 6) = @Value;
    RETURN ROUND(CASE WHEN (CAST(@IsMultiply AS INT) + CAST(@IsReverse AS INT) + CAST(@IsCost AS INT)) % 2 = 1
                      THEN @V * @Factor ELSE @V / @Factor END, 6);
END