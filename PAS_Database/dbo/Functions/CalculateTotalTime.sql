CREATE FUNCTION dbo.CalculateTotalTime (@Time1 VARCHAR(10), @Time2 VARCHAR(10))
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @H1 INT, @M1 INT, @H2 INT, @M2 INT
    DECLARE @TotalMinutes INT, @ExtraHours INT, @FinalMinutes INT, @FinalHours INT
    DECLARE @Result VARCHAR(10)

    -- Splitting hours and minutes for Time1
    SET @H1 = CAST(LEFT(@Time1, CHARINDEX('.', @Time1) - 1) AS INT)
    SET @M1 = CAST(RIGHT(@Time1, LEN(@Time1) - CHARINDEX('.', @Time1)) AS INT)

    -- Splitting hours and minutes for Time2
    SET @H2 = CAST(LEFT(@Time2, CHARINDEX('.', @Time2) - 1) AS INT)
    SET @M2 = CAST(RIGHT(@Time2, LEN(@Time2) - CHARINDEX('.', @Time2)) AS INT)

    -- Adding minutes and adjusting hours
    SET @TotalMinutes = @M1 + @M2
    SET @ExtraHours = @TotalMinutes / 60
    SET @FinalMinutes = @TotalMinutes % 60
    SET @FinalHours = @H1 + @H2 + @ExtraHours

    -- Formatting the final result as H.MM
    SET @Result = CAST(@FinalHours AS VARCHAR) + '.' + RIGHT('00' + CAST(@FinalMinutes AS VARCHAR), 2)

    -- Return the final formatted result
    RETURN @Result
END