/*************************************************************           
 ** File:   [fn_GetRevenuePercentage]           
 ** Author:   Devendra Shekh
 ** Description: This Function is used to calculate Revenue Percentage
 ** Date:   20-May-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    20-May-2025   Devendra Shekh		Created
**************************************************************/
CREATE   FUNCTION dbo.fn_GetRevenuePercentage
(
    @Cost DECIMAL(20, 2),
    @TotalRevenue DECIMAL(20, 2)
)
RETURNS DECIMAL(20, 2)
AS
BEGIN
    DECLARE @Result DECIMAL(20, 2)

    IF ISNULL(@TotalRevenue, 0) > 0 AND @Cost IS NOT NULL
        SET @Result = (@Cost / @TotalRevenue) * 100
    ELSE
        SET @Result = 0

    RETURN @Result
END