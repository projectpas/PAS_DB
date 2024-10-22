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
    1				  Unkwon					Created
	2	 10/18/2024	  Devendra Shekh			Modified(Space issue resolved)

******************************************************************************/ 
CREATE   FUNCTION [dbo].[ValidatePDFAddress]
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

	-- Assinged Address1
    IF (COALESCE(NULLIF(TRIM(@Address1), '-'), '') <> '')
    BEGIN
        SET @address = @Address1;
    END

	-- Append @Address2
    IF (COALESCE(NULLIF(TRIM(@Address2), '-'), '') <> '')
    BEGIN
        SET @address = @address + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END + @Address2;
    END

	-- Append @Address3
    IF (COALESCE(NULLIF(TRIM(@Address3), '-'), '') <> '')
    BEGIN
        SET @address = @address + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END + @Address3;
    END

    -- Append City, StateOrProvince, and PostalCode
    IF (COALESCE(NULLIF(TRIM(@City), '-'), '') <> '')
    BEGIN
        SET @address = @address + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END + @City;
    END

    IF (COALESCE(NULLIF(TRIM(@StateOrProvince), '-'), '') <> '')
    BEGIN
        SET @address = @address + CASE WHEN LEN(@address) > 0 THEN ', ' ELSE '' END + @StateOrProvince;
    END

    IF (COALESCE(NULLIF(TRIM(@PostalCode), '-'), '') <> '')
    BEGIN
        SET @address = @address + CASE WHEN LEN(@address) > 0 THEN ', ' ELSE '' END + @PostalCode;
    END

	-- Append Country
	IF (COALESCE(NULLIF(TRIM(@Country), '-'), '') <> '')
    BEGIN
        SET @address = @address + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END + @Country;
    END

	---- Append PhoneNumber
	IF (COALESCE(NULLIF(TRIM(@PhoneNumber), '-'), '') <> '')
    BEGIN
        SET @address = @address + CASE WHEN LEN(@address) > 0 THEN @newLine ELSE '' END + @PhoneNumber;
    END

    ---- Append PhoneExt
    IF (COALESCE(NULLIF(TRIM(@PhoneExt), '-'), '') <> '' AND COALESCE(NULLIF(TRIM(@PhoneNumber), '-'), '') <> '')
    BEGIN
        SET @address = @address + ' ' + @PhoneExt;
    END

    -- Append Email
    IF (COALESCE(NULLIF(TRIM(@Email), '-'), '') <> '')
    BEGIN
        SET @address = @address + @newLine + @Email;
    END

    RETURN UPPER(@address);
END;