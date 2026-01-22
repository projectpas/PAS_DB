/*****************************************************************************
 ** File:   [ValidatePDFAddress]
 ** Author:   Unkwon
 ** Description: Merge Address
 ** Purpose:
 ** Date:    
 ******************************************************************************
  ** Change History
 ******************************************************************************
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1				  Moin					Created	
	2    04/07/2025   Moin Bloch			Get Country in ship to address.
******************************************************************************/ 
CREATE FUNCTION [dbo].[FN_ValidatePDFAddress]
(
    @Address1 NVARCHAR(255),
    @Address2 NVARCHAR(255),
    @Address3 NVARCHAR(255),
    @City NVARCHAR(255),
    @StateOrProvince NVARCHAR(255),
    @PostalCode NVARCHAR(50),
    @Country NVARCHAR(255),
    @PhoneNumber NVARCHAR(50),
    @PhoneExt NVARCHAR(50),
    @Email NVARCHAR(255)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @address NVARCHAR(MAX) = '';
    DECLARE @lineBreak NVARCHAR(10) = ', <br/>';
    DECLARE @newLine NVARCHAR(10) = '<br/>';

    -- Helper table
    DECLARE @parts TABLE (Value NVARCHAR(MAX), Separator NVARCHAR(10));

    -- Add clean values
    INSERT INTO @parts
    SELECT TRIM(@Address1), '' WHERE TRIM(ISNULL(@Address1, '')) NOT IN ('', '-')
    UNION ALL
    SELECT TRIM(@Address2), @lineBreak WHERE TRIM(ISNULL(@Address2, '')) NOT IN ('', '-')
    UNION ALL
    SELECT TRIM(@Address3), @lineBreak WHERE TRIM(ISNULL(@Address3, '')) NOT IN ('', '-')
    UNION ALL
    SELECT TRIM(@City), @lineBreak WHERE TRIM(ISNULL(@City, '')) NOT IN ('', '-')
    UNION ALL
    SELECT TRIM(@StateOrProvince), ', ' WHERE TRIM(ISNULL(@StateOrProvince, '')) NOT IN ('', '-')
    UNION ALL
    SELECT TRIM(@PostalCode), ', ' WHERE TRIM(ISNULL(@PostalCode, '')) NOT IN ('', '-')
   -- UNION ALL
   -- SELECT TRIM(@Country), @lineBreak WHERE TRIM(ISNULL(@Country, '')) NOT IN ('', '-');

    -- Build string
    SELECT @address = @address +
        CASE WHEN LEN(@address) > 0 THEN Separator ELSE '' END + Value
    FROM @parts;

    -- Append phone
    IF TRIM(ISNULL(@PhoneNumber, '')) NOT IN ('', '-')
    BEGIN
        SET @address = @address + @newLine + TRIM(@PhoneNumber);
        IF TRIM(ISNULL(@PhoneExt, '')) NOT IN ('', '-')
            SET @address = @address + ' ' + TRIM(@PhoneExt);
    END

    -- Append email
    IF TRIM(ISNULL(@Email, '')) NOT IN ('', '-')
        SET @address = @address + @newLine + TRIM(@Email);

	 -- Append email
    IF TRIM(ISNULL(@Country, '')) NOT IN ('', '-')
        SET @address = @address + @newLine + TRIM(@Country);

    RETURN UPPER(@address);
END