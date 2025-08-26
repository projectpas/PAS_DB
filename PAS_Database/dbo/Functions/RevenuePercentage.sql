CREATE   FUNCTION dbo.RevenuePercentage
(
    @Cost DECIMAL(18, 2), 
    @TotalRevenue DECIMAL(18, 2)
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @Result DECIMAL(18, 2) = 0;

    IF @TotalRevenue > 0
        SET @Result = (ISNULL(@Cost,0) / @TotalRevenue) * 100;
    ELSE
        SET @Result = 0;

    RETURN @Result;
END