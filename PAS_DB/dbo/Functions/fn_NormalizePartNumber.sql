/*************************************************************
 ** File:   [fn_NormalizePartNumber]
 ** Author:   Bhargav Saliya
 ** Description: Strips separator characters (dash '-', slash '/', underscore '_', backslash '\')
 **              from a part number so Part Number search/filter matches regardless of separator
 **              formatting (e.g. '1158333' matches '11-5833-3'). Filter use only.
 ** Date:   02-Sep-2026
 ** RETURN VALUE: VARCHAR(50) with '-', '/', '_', '\' removed
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author           Change Description
 ** --   --------       -------          --------------------------------
    1    02-Sep-2026   Bhargav Saliya    [PN-17849] Created
**************************************************************/
CREATE   FUNCTION dbo.fn_NormalizePartNumber
(
    @value VARCHAR(100)
)
RETURNS VARCHAR(100)
WITH SCHEMABINDING
AS
BEGIN
    RETURN REPLACE(REPLACE(REPLACE(REPLACE(@value, '-', ''), '/', ''), '_', ''), '\', '');
END
