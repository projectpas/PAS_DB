/*****************************************************************************
 ** File:   [ValidatePDFAddressWithSiteName]
 ** Author:   Unkwon
 ** Description: Merged PDF Address with Site as well
 ** Purpose:
 ** Date:    
 ******************************************************************************
  ** Change History
 ******************************************************************************
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1	 26-Aug-2026  Abhishek Jirawla      Merged PDF Address with Site as well  (PN-17789)

******************************************************************************/ 
CREATE   FUNCTION [dbo].[ValidatePDFAddressWithSiteName]
(
    @Address1 NVARCHAR(255),
    @Address2 NVARCHAR(255),
    @Address3 NVARCHAR(255),
    @SiteName NVARCHAR(255) = NULL,
    @City NVARCHAR(255),
    @StateOrProvince NVARCHAR(255),
    @PostalCode NVARCHAR(50),
    @Country NVARCHAR(255),
    @PhoneNumber NVARCHAR(50),
    @PhoneExt NVARCHAR(50),
    @Email NVARCHAR(255),
    @MasterCompanyCode NVARCHAR(50)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN

    DECLARE @A2ZMasterCompanyCode VARCHAR(50);

    SELECT @A2ZMasterCompanyCode = MasterCompanyCode
    FROM dbo.MasterCompany WITH (NOLOCK)
    WHERE UPPER(MasterCompanyCode) = UPPER('A2Z');

    DECLARE @address NVARCHAR(MAX);
    SET @address = '';

    -- Helper variables for conditional new line
    DECLARE @lineBreak NVARCHAR(10) = '<br/>';
    DECLARE @newLine NVARCHAR(10) = '<br/>';

    -- Append Address1
    IF (COALESCE(NULLIF(TRIM(@Address1), '-'), '') <> '')
    BEGIN
        SET @address = @Address1;
    END

    -- Append Address2
    IF (COALESCE(NULLIF(TRIM(@Address2), '-'), '') <> '')
    BEGIN
        SET @address = @address
            + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END
            + @Address2;
    END

    -- Append Address3
    IF (COALESCE(NULLIF(TRIM(@Address3), '-'), '') <> '')
    BEGIN
        SET @address = @address
            + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END
            + @Address3;
    END

    -- Append SiteName
    -- SiteName is nullable. It is only appended when a valid value is supplied.
    IF (COALESCE(NULLIF(TRIM(@SiteName), '-'), '') <> '')
    BEGIN
        SET @address = @address
            + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END
            + @SiteName;
    END

    -- Append City
    IF (COALESCE(NULLIF(TRIM(@City), '-'), '') <> '')
    BEGIN
        SET @address = @address
            + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END
            + @City;
    END

    -- Append StateOrProvince
    IF (COALESCE(NULLIF(TRIM(@StateOrProvince), '-'), '') <> '')
    BEGIN
        SET @address = @address
            + CASE WHEN LEN(@address) > 0 THEN ', ' ELSE '' END
            + @StateOrProvince;
    END

    -- Append PostalCode
    IF (COALESCE(NULLIF(TRIM(@PostalCode), '-'), '') <> '')
    BEGIN
        SET @address = @address
            + CASE WHEN LEN(@address) > 0 THEN ', ' ELSE '' END
            + @PostalCode;
    END

    -- Append Country
    IF (COALESCE(NULLIF(TRIM(@Country), '-'), '') <> '')
    BEGIN
        SET @address = @address
            + CASE WHEN LEN(@address) > 0 THEN @lineBreak ELSE '' END
            + @Country;
    END

    -- Append PhoneNumber
    IF (COALESCE(NULLIF(TRIM(@PhoneNumber), '-'), '') <> '')
    BEGIN
        SET @address = @address
            + CASE WHEN LEN(@address) > 0 THEN @newLine ELSE '' END
            + @PhoneNumber;
    END

    -- Append PhoneExt
    IF (
        COALESCE(NULLIF(TRIM(@PhoneExt), '-'), '') <> ''
        AND COALESCE(NULLIF(TRIM(@PhoneNumber), '-'), '') <> ''
    )
    BEGIN
        SET @address = @address + ' ' + @PhoneExt;
    END

    -- Append Email
    IF (COALESCE(NULLIF(TRIM(@Email), '-'), '') <> '')
    BEGIN
        SET @address = @address
            + @newLine
            + @Email;
    END

    -- Preserve existing A2Z email behavior:
    -- entire address is uppercase except the email remains lowercase.
    IF (
        UPPER(ISNULL(@MasterCompanyCode, '')) =
        UPPER(ISNULL(@A2ZMasterCompanyCode, ''))
    )
    BEGIN
        IF (COALESCE(NULLIF(TRIM(@Email), '-'), '') <> '')
        BEGIN
            RETURN REPLACE(
                UPPER(@address),
                UPPER(@Email),
                LOWER(@Email)
            );
        END
    END

    RETURN UPPER(@address);
END;