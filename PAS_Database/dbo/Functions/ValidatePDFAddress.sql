CREATE FUNCTION [dbo].[ValidatePDFAddress]
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
    DECLARE @address NVARCHAR(MAX);
    SET @address = '';

    -- Helper variables for conditional new line
    DECLARE @lineBreak NVARCHAR(10) = ', <br/>';
    DECLARE @newLine NVARCHAR(10) = '<br/>';

    -- Append Address1, Address2, Address3
    SET @address = COALESCE(NULLIF(TRIM(@Address1), '-'), '') + 
                   COALESCE(NULLIF(TRIM(@Address2), '-'), '') +
                   COALESCE(NULLIF(TRIM(@Address3), '-'), '');

    -- Append City, StateOrProvince, and PostalCode
    IF (COALESCE(NULLIF(TRIM(@City), '-'), '') <> '')
    BEGIN
        SET @address = @address + @City;
    END

    IF (COALESCE(NULLIF(TRIM(@StateOrProvince), '-'), '') <> '')
    BEGIN
        SET @address = @address + CASE WHEN LEN(@address) > 0 THEN ', ' ELSE '' END + @StateOrProvince;
    END

    IF (COALESCE(NULLIF(TRIM(@PostalCode), '-'), '') <> '')
    BEGIN
        SET @address = @address + CASE WHEN LEN(@address) > 0 THEN ', ' ELSE '' END + @PostalCode + @lineBreak;
    END

    -- Append Country
    SET @address = @address + COALESCE(NULLIF(TRIM(@Country), '-'), '') + CASE WHEN LEN(@address) > 0 THEN @newLine ELSE '' END;

    -- Append PhoneNumber and PhoneExt
    SET @address = @address + COALESCE(NULLIF(TRIM(@PhoneNumber), '-'), '') + CASE WHEN LEN(@address) > 0 THEN @newLine ELSE '' END;
    
    IF (COALESCE(NULLIF(TRIM(@PhoneExt), '-'), '') <> '')
    BEGIN
        SET @address = @address + ' ' + @PhoneExt + @newLine;
    END

    -- Append Email
    IF (COALESCE(NULLIF(TRIM(@Email), '-'), '') <> '')
    BEGIN
        SET @address = @address + @Email;
    END

    RETURN UPPER(@address);
END;