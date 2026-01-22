/*************************************************************           
 ** File:   [fn_GetMarginPercentage]           
 ** Author:   Devendra Shekh
 ** Description: This Function is used to calculate Margin Percentage
 ** Date:   20-May-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    20-May-2025   Devendra Shekh		Created
**************************************************************/
CREATE   FUNCTION dbo.fn_GetMarginPercentage
(
    @Margin DECIMAL(20, 2),
    @Revenue DECIMAL(20, 2)
)
RETURNS DECIMAL(20, 2)
AS
BEGIN
    DECLARE @Result DECIMAL(20, 2)

    IF ISNULL(@Revenue, 0) > 0 AND @Margin IS NOT NULL
        SET @Result = (@Margin / @Revenue) * 100
    ELSE
        SET @Result = 0

    RETURN @Result
END