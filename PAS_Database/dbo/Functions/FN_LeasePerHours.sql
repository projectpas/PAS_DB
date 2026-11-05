/*************************************************************
 Function Name : dbo.FN_LeasePerHours
 Description   : Number of hours in a Lease Properties "Per" value (Hour / Day / Month / Qtr. / Year). Month = 30 days, Qtr. = 3 months, Year = 12 months,
                 matching the 30 day month the lease billing engine uses. Returns NULL for Cycle / blank / unknown values.
                 The accepted values mirror LeasePerEnum in the web app (enum/lease-per.enum.ts) plus the older spellings (Monthly, Hourly ...).
 Change History
 ** PR   Date         Author           Change Description
 ** --   --------     -------          ---------------------------------------
    1    03/11/2026   Kishor Makwana   Created
*************************************************************/
CREATE   FUNCTION [dbo].[FN_LeasePerHours]
(
	@Per NVARCHAR(50)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
	DECLARE @P NVARCHAR(50) = LOWER(LTRIM(RTRIM(REPLACE(ISNULL(@Per, ''), '.', ''))));

	RETURN CASE
		WHEN @P IN ('hour', 'hourly', 'hr') THEN 1
		WHEN @P IN ('day', 'daily') THEN 24
		WHEN @P IN ('month', 'monthly') THEN 720
		WHEN @P IN ('qtr', 'quarter', 'quarterly') THEN 2160
		WHEN @P IN ('year', 'yearly', 'annual', 'annually') THEN 8640
		ELSE NULL
	END;
END