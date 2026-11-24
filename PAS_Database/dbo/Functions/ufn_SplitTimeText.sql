/*************************************************************
 ** File:   [ufn_SplitTimeText]
 ** Description: Splits a time text into Hours and Minutes (whole minutes). Used where an old text value (TimeLife.TimeSinceNew / TimeSinceOVH,
                 old Receiving Customer Work TSN / TSO) has to go into the Hours + Minutes columns (TSN + TSNMM, TSO + TSOMM).
                   'HH:MM'            -> HH and MM          ('14027:30' -> 14027 , 30)
                   decimal hours      -> HH and MM          ('22443.2'  -> 22443 , 12)
                   NULL / blank / 'UNK' -> 0 , 0
                   anything else (not a number) -> NULL , NULL
 ** Date:   19/NOV/2026
 ** Author:  Rajesh Gami
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author         Change Description
 ** --   --------     -------        --------------------------------
    1    19/NOV/2026  Rajesh Gami    [PN-18595] Created
 -- SELECT * FROM dbo.ufn_SplitTimeText('22443.2')
************************************************************************/
CREATE FUNCTION [dbo].[ufn_SplitTimeText] (@TimeText VARCHAR(50))
RETURNS TABLE
AS
RETURN
(
	SELECT CAST(FLOOR(M.[TotalMinutes] / 60) AS DECIMAL(18, 6)) AS [Hours],
		   CAST(M.[TotalMinutes] - FLOOR(M.[TotalMinutes] / 60) * 60 AS DECIMAL(18, 6)) AS [Minutes]
	FROM (SELECT LTRIM(RTRIM(ISNULL(@TimeText, ''))) AS [TextValue]) X
	CROSS APPLY (
		SELECT CASE
			WHEN X.[TextValue] = '' OR UPPER(X.[TextValue]) = 'UNK' THEN CAST(0 AS DECIMAL(18, 6))
			WHEN CHARINDEX(':', X.[TextValue]) > 0
				THEN TRY_CAST(LEFT(X.[TextValue], CHARINDEX(':', X.[TextValue]) - 1) AS DECIMAL(18, 6)) * 60
				   + TRY_CAST(SUBSTRING(X.[TextValue], CHARINDEX(':', X.[TextValue]) + 1, 10) AS DECIMAL(18, 6))
			WHEN TRY_CAST(REPLACE(X.[TextValue], ',', '') AS DECIMAL(18, 6)) IS NOT NULL
				THEN ROUND(TRY_CAST(REPLACE(X.[TextValue], ',', '') AS DECIMAL(18, 6)) * 60, 0)
			ELSE NULL END AS [TotalMinutes]
	) M
)
