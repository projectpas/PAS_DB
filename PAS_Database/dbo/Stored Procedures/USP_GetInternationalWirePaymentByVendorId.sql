/************************************************************* 
** File:     [USP_GetInternationalWirePaymentByVendorId]
** Author:   Ayushi Patel
** Description: Gets InternationalWirePayment details for a given VendorId
** Purpose:  Replaces EF logic for InternationalWirePayment
** Date:     01-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    01-07-2025   Ayushi Patel   Created

-- EXEC USP_GetInternationalWirePaymentByVendorId 2345
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetInternationalWirePaymentByVendorId]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            iwp.InternationalWirePaymentId,
            iwp.SwiftCode,
            iwp.BeneficiaryBankAccount,
            iwp.BeneficiaryBank,
            iwp.IntermediaryBank,
            iwp.ABA,
            iwp.BankName,
            iwp.BankAddressId,
            iwp.BeneficiaryCustomer,
            iwp.BeneficiaryCustomerId,
            iwp.BankLocation1,
            iwp.BankLocation2,
            iwp.GLAccountId,
            iwp.VendorBankAccountTypeId,
            iwp.MasterCompanyId,
            iwp.CreatedBy,
            iwp.CreatedDate,
            iwp.UpdatedBy,
            iwp.UpdatedDate,
            ISNULL(iwp.IsActive, 0) AS IsActive,
            ISNULL(iwp.IsDeleted, 0) AS IsDeleted,

            ISNULL(addr.Line1, '') AS Address1,
            ISNULL(addr.Line2, '') AS Address2,
            ISNULL(addr.Line3, '') AS Address3,
            ISNULL(addr.City, '') AS City,
            ISNULL(addr.StateOrProvince, '') AS StateOrProvince,
            ISNULL(addr.PostalCode, '') AS PostalCode,
            addr.AddressId,
            addr.CountryId,
            ISNULL(cty.countries_name, '') AS CountryName,

            viwp.VendorId,
            viwp.VendorInternationalWirePaymentId,
            ISNULL(vn.VendorName, '') AS VendorName

        FROM InternationalWirePayment iwp WITH (NOLOCK)
        INNER JOIN VendorInternationlWirePayment viwp WITH (NOLOCK) 
            ON iwp.InternationalWirePaymentId = viwp.InternationalWirePaymentId
        LEFT JOIN Address addr WITH (NOLOCK) ON iwp.BankAddressId = addr.AddressId
        LEFT JOIN Countries cty WITH (NOLOCK) ON addr.CountryId = cty.countries_id
        LEFT JOIN Vendor vn WITH (NOLOCK) ON iwp.BeneficiaryCustomerId = vn.VendorId
        WHERE viwp.VendorId = @VendorId
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetInternationalWirePaymentByVendorId',
                @ProcedureParameters VARCHAR(MAX) = 'VendorId=' + CAST(@VendorId AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Database error occurred. ErrorLogID = %d', 16, 1, @ErrorLogID);
    END CATCH
END