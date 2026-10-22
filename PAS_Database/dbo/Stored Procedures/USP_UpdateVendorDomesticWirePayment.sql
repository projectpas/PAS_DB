/******************************************************************************************
** File:        [USP_UpdateVendorDomesticWirePayment]
** Author:       Ayushi Patel
** Description:  Update a Domestic Wire Payment record for a Vendor, including Address.
** Date:         17-07-2025
*******************************************************************************************
** Change History
*******************************************************************************************
** PR     Date         Author         Change Description
** --     ----------   ------------   -----------------------------------------------------
** 1      17-07-2025   Ayushi Patel   Created
** 2      21-10-2026   Nakul          Added Payee Name, Bank Location 1/2, Intermediate Bank, SWIFT and GL Account (Legal Entity banking fields) (PN-18294)
**                                    Bank Address and Bank Account Type are optional; existing values are kept when not passed
*******************************************************************************************/
CREATE PROCEDURE [dbo].[USP_UpdateVendorDomesticWirePayment]
    @DomesticWirePaymentId BIGINT,
    @VendorId BIGINT,
    @ABA NVARCHAR(100),
    @AccountNumber NVARCHAR(100),
    @BankName NVARCHAR(250) = NULL,
    @AccountNameId BIGINT,
    @VendorBankAccountTypeId BIGINT = NULL,
    @MasterCompanyId BIGINT,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100),
    @Address1 NVARCHAR(1000) = NULL,
    @Address2 NVARCHAR(1000) = NULL,
    @Address3 NVARCHAR(1000) = NULL,
    @City NVARCHAR(100) = NULL,
    @StateOrProvince NVARCHAR(100) = NULL,
    @PostalCode NVARCHAR(100) = NULL,
    @CountryId BIGINT = NULL,
    @PayeeName VARCHAR(100) = NULL,
    @BankLocation1 VARCHAR(250) = NULL,
    @BankLocation2 VARCHAR(250) = NULL,
    @IntermediaryBankName VARCHAR(100) = NULL,
    @SwiftCode VARCHAR(50) = NULL,
    @GLAccountId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @BankAddressId BIGINT;

        SELECT @BankAddressId = BankAddressId
        FROM DomesticWirePayment WITH (NOLOCK)
        WHERE DomesticWirePaymentId = @DomesticWirePaymentId;

        IF @BankAddressId IS NOT NULL AND NULLIF(@CountryId, 0) IS NOT NULL
        BEGIN
            UPDATE Address
            SET Line1 = ISNULL(@Address1, ''),
                Line2 = @Address2,
                Line3 = @Address3,
                City = ISNULL(@City, ''),
                StateOrProvince = ISNULL(@StateOrProvince, ''),
                PostalCode = ISNULL(@PostalCode, ''),
                CountryId = @CountryId,
                MasterCompanyId = @MasterCompanyId,
                CreatedBy = @CreatedBy,
                UpdatedBy = @UpdatedBy,
                CreatedDate = GETUTCDATE(),
                UpdatedDate = GETUTCDATE()
            WHERE AddressId = @BankAddressId;
        END

        UPDATE DomesticWirePayment
        SET ABA = @ABA,
            AccountNumber = @AccountNumber,
            BankName = ISNULL(@BankName, ''),
            AccountNameId = @AccountNameId,
            VendorBankAccountTypeId = ISNULL(NULLIF(@VendorBankAccountTypeId, 0), VendorBankAccountTypeId),
            MasterCompanyId = @MasterCompanyId,
            CreatedBy = @CreatedBy,
            UpdatedBy = @UpdatedBy,
            CreatedDate = GETUTCDATE(),
            UpdatedDate = GETUTCDATE(),
            IsActive = 1,
            PayeeName = @PayeeName,
            BankLocation1 = @BankLocation1,
            BankLocation2 = @BankLocation2,
            IntermediaryBankName = @IntermediaryBankName,
            SwiftCode = @SwiftCode,
            GLAccountId = @GLAccountId
        WHERE DomesticWirePaymentId = @DomesticWirePaymentId;

        UPDATE VendorDomesticWirePayment
        SET VendorId = @VendorId,
            MasterCompanyId = @MasterCompanyId,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = GETUTCDATE(),
            IsActive = 1,
            IsDeleted = 0
        WHERE DomesticWirePaymentId = @DomesticWirePaymentId;

        SELECT 
            v.DomesticWirePaymentId,
            v.ABA,
            v.AccountNumber,
            v.BankName,
            v.IntermediaryBankName,
            v.BenificiaryBankName,
            v.BankAddressId,
            v.AccountNameId,
            v.VendorBankAccountTypeId,
            v.MasterCompanyId,
            v.CreatedBy,
            v.CreatedDate,
            v.UpdatedBy,
            v.UpdatedDate,
            v.IsActive,
            v.IsDeleted,
            v.PayeeName,
            v.BankLocation1,
            v.BankLocation2,
            v.SwiftCode,
            v.GLAccountId
        FROM DomesticWirePayment v WITH (NOLOCK)
        WHERE v.DomesticWirePaymentId = @DomesticWirePaymentId;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[USP_UpdateVendorDomesticWirePayment]',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred. Please contact support. ErrorLogID: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END