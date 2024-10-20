﻿/*********************
 ** File:   [SP_ValidatePDFAddress]
 ** Author:   Rajesh Gami
 ** Description: Merge Address
 ** Purpose:
 ** Date:    17/09/2024 
 **********************
  ** Change History
 **********************
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    17/09/2024   RAJESH GAMI			Created

**********************/ 
CREATE PROCEDURE [dbo].[SP_ValidatePDFAddress]
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
    @Email NVARCHAR(255),
    @AddressOutput NVARCHAR(MAX) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @address NVARCHAR(MAX);
    SET @address = '';

    -- Append Address1
    IF (@Address1 IS NOT NULL AND @Address1 <> '' AND TRIM(@Address1) <> '-')
    BEGIN
        SET @address = @address + @Address1 + ', <br/>';
    END

    -- Append Address2
    IF (@Address2 IS NOT NULL AND @Address2 <> '' AND TRIM(@Address2) <> '-')
    BEGIN
        SET @address = @address + @Address2 + ', <br/>';
    END

	-- Append Address3
    IF (@Address3 IS NOT NULL AND @Address3 <> '' AND TRIM(@Address3) <> '-')
    BEGIN
        SET @address = @address + @Address3 + ', <br/>';
    END

    -- Append City
    IF (@City IS NOT NULL AND @City <> '' AND TRIM(@City) <> '-')
    BEGIN
        SET @address = @address + @City;
    END

    -- Append StateOrProvince
    IF (@StateOrProvince IS NOT NULL AND @StateOrProvince <> '' AND TRIM(@StateOrProvince) <> '-')
    BEGIN
		IF(@City IS NOT NULL AND @City <> '' AND TRIM(@City) <> '-')
		BEGIN
			SET @address = @address+ ', ' + @StateOrProvince ;
		END
		ELSE
		BEGIN
			SET @address = @address+ ' ' + @StateOrProvince ;
		END
    END

    -- Append PostalCode
    IF (@PostalCode IS NOT NULL AND @PostalCode <> '' AND TRIM(@PostalCode) <> '-')
    BEGIN
		IF(@StateOrProvince IS NOT NULL AND @StateOrProvince <> '' AND TRIM(@StateOrProvince) <> '-')
		BEGIN
			SET @address = @address+ ', ' + @PostalCode + ', <br/>';
		END
		ELSE
		BEGIN
			IF(@City IS NOT NULL AND @City <> '' AND TRIM(@City) <> '-')
			BEGIN
				SET @address = @address + ', '+ @PostalCode + ', <br/>';
			END
			ELSE
			BEGIN
				SET @address = @address + ' '+ @PostalCode + ', <br/>';
			END
		END
    END
	ELSE
	BEGIN
		IF(@City IS NOT NULL AND @City <> '' AND TRIM(@City) <> '-')
		BEGIN
			SET @address = @address + '<br/>';
		END
		ELSE IF(@StateOrProvince IS NOT NULL AND @StateOrProvince <> '' AND TRIM(@StateOrProvince) <> '-')
		BEGIN 
			SET @address = @address + '<br/>';
		END
		ELSE IF(@PostalCode IS NOT NULL AND @PostalCode <> '' AND TRIM(@PostalCode) <> '-')
		BEGIN 
			SET @address = @address + '<br/>';
		END
	END

    -- Append Country
    IF (@Country IS NOT NULL AND @Country <> '' AND TRIM(@Country) <> '-')
    BEGIN
        SET @address = @address + @Country + '<br/>';
    END

    -- Append PhoneNumber
    IF (@PhoneNumber IS NOT NULL AND @PhoneNumber <> '' AND TRIM(@PhoneNumber) <> '-')
    BEGIN
        SET @address = @address + @PhoneNumber + '<br/>';
    END

	-- Append PhoneExt
    IF (@PhoneExt IS NOT NULL AND @PhoneExt <> '' AND TRIM(@PhoneExt) <> '-')
    BEGIN
        SET @address = @address + ' ' + @PhoneExt + '<br/>';
    END
	
    -- Append Email
    IF (@Email IS NOT NULL AND @Email <> '' AND TRIM(@Email) <> '-')
    BEGIN
        SET @address =  @address + @Email;
    END

    -- Assign final address to output parameter
    SET @AddressOutput = UPPER(@address);
END;