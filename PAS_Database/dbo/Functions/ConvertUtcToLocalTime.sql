CREATE   FUNCTION dbo.ConvertUtcToLocalTime(@utcDateTime DATETIME, @strTimeZoneName NVARCHAR(100))
RETURNS DATETIME AS
BEGIN
    RETURN 
		@utcDateTime AT TIME ZONE 'UTC' AT TIME ZONE @strTimeZoneName
END