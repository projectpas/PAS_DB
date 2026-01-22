/************************************************************* 
** File:     [USP_GetDomesticWirePaymentByVendorId]
** Author:   Ayushi Patel
** Description: Gets DomesticWirePayment details for a given VendorId
** Purpose:  Replaces EF logic for GetDomesticWithVendor
** Date:     01-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    01-07-2025   Ayushi Patel   Created

-- EXEC USP_GetDomesticWirePaymentByVendorId 2345
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetDomesticWirePaymentByVendorId]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        SELECT 
            dwp.DomesticWirePaymentId,
            dwp.ABA,
            dwp.AccountNumber,
            dwp.BankName,
            dwp.BenificiaryBankName,
            dwp.IntermediaryBankName,
            dwp.BankAddressId,
			dwp.MasterCompanyId,
            dwp.AccountNameId,
            dwp.VendorBankAccountTypeId,
            dwp.CreatedBy,
            dwp.CreatedDate,
            dwp.UpdatedBy,
            dwp.UpdatedDate,
            ISNULL(dwp.IsActive,0) as IsActive,
			ISNULL(dwp.IsDeleted,0) as IsDeleted,

            vdwp.VendorDomesticWirePaymentId,
            vdwp.VendorId,

            v.VendorName,

            a.AddressId,
            ISNULL(a.Line1, '') AS Address1,
            ISNULL(a.Line2, '') AS Address2,
            ISNULL(a.Line3, '') AS Address3,
            ISNULL(a.City, '') AS City,
            ISNULL(a.StateOrProvince, '') AS StateOrProvince,
            ISNULL(a.PostalCode, '') AS PostalCode,
            a.CountryId,

            ISNULL(c.countries_name, '') AS CountryName

        FROM dbo.DomesticWirePayment dwp WITH(NOLOCK)
        INNER JOIN dbo.VendorDomesticWirePayment vdwp WITH(NOLOCK)
            ON dwp.DomesticWirePaymentId = vdwp.DomesticWirePaymentId
        LEFT JOIN dbo.Address a WITH(NOLOCK)
            ON dwp.BankAddressId = a.AddressId
        LEFT JOIN dbo.Vendor v WITH(NOLOCK)
            ON dwp.AccountNameId = v.VendorId
        LEFT JOIN dbo.Countries c WITH(NOLOCK)
            ON a.CountryId = c.countries_id
        WHERE vdwp.VendorId = @VendorId
            AND dwp.IsDeleted = 0
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_GetDomesticWirePaymentByVendorId',
                @ProcedureParameters VARCHAR(MAX) = 'VendorId=' + CAST(@VendorId AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Database error occurred. ErrorLogID = %d', 16, 1, @ErrorLogID);
    END CATCH
END