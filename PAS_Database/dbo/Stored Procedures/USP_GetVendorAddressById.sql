 /***************************************************************  
 ** File:   USP_GetVendorAddressById             
 ** Author: Ayushi Patel 
 ** Description: Get vendor address details including merged address using ValidatePDFAddress  
 ** Purpose:  Used in vendor profile view  
 ** Date:     2025-05-26  
            
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-05-26		  Ayushi Patel				Created
*************************************************************/ 
CREATE   PROCEDURE USP_GetVendorAddressById  
    @VendorId BIGINT  
AS  
BEGIN  
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
    BEGIN TRY  
        SELECT  
            v.VendorId,  
            v.VendorName,  
            v.VendorCode,  
            v.VendorEmail,  
            v.VendorPhone,  
            v.VendorPhoneExt,  
            a.Line1 AS Address1,  
            a.Line2 AS Address2,  
            a.City,  
            a.StateOrProvince,  
            a.PostalCode,  
            c.countries_name AS Country,  
            c.countries_id AS CountryId,  
            cur.Code AS Currency,  
            dbo.ValidatePDFAddress(
                a.Line1, 
                a.Line2,
				'',
                a.City, 
                a.StateOrProvince, 
                a.PostalCode, 
                c.countries_name, 
                v.VendorPhone, 
                '',
				''
            ) AS MergedAddress
        FROM dbo.Vendor v WITH (NOLOCK)  
        INNER JOIN dbo.Address a WITH (NOLOCK) ON v.AddressId = a.AddressId  
        LEFT JOIN dbo.Countries c WITH (NOLOCK) ON a.CountryId = c.countries_id  
        LEFT JOIN dbo.Currency cur WITH (NOLOCK) ON v.CurrencyId = cur.CurrencyId  
        WHERE v.VendorId = @VendorId;  
    END TRY  
    BEGIN CATCH  
        DECLARE @ErrorLogID INT,  
                @DatabaseName VARCHAR(100) = DB_NAME(),  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------- 
                @AdhocComments VARCHAR(150) = 'USP_GetVendorAddressById',  
                @ProcedureParameters VARCHAR(3000) = '@VendorId = ' + CAST(@VendorId AS VARCHAR),  
                @ApplicationName VARCHAR(100) = 'PAS';
 -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException  
            @DatabaseName = @DatabaseName,  
            @AdhocComments = @AdhocComments,  
            @ProcedureParameters = @ProcedureParameters,  
            @ApplicationName = @ApplicationName,  
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected error occurred. Please contact support with ErrorLogID: %d', 16, 1, @ErrorLogID);  
        RETURN (1);  
    END CATCH  
END