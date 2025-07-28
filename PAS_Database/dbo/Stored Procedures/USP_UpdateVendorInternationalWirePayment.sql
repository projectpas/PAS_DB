/****************************************************************************************** 
** File:        [USP_UpdateVendorInternationalWirePayment]
** Author:      Ayushi Patel
** Description: Update International Wire Payment record for a Vendor, including Address.
** Date:        17-07-2025
*******************************************************************************************
** Change History
*******************************************************************************************
** PR     Date         Author         Change Description
** --     ----------   ------------   -----------------------------------------------------
** 1      17-07-2025   Ayushi Patel   Created
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendorInternationalWirePayment]
    @InternationalWirePaymentId       BIGINT,
    @SwiftCode                        NVARCHAR(100),
    @BeneficiaryBankAccount          NVARCHAR(250),
    @BeneficiaryBank                 NVARCHAR(250),
    @BeneficiaryCustomer             NVARCHAR(250),
    @BeneficiaryCustomerId           BIGINT,
    @VendorBankAccountTypeId         BIGINT,
    @MasterCompanyId                 BIGINT,
    @CreatedBy                       NVARCHAR(100),
    @UpdatedBy                       NVARCHAR(100),
    @Address1                        NVARCHAR(1000),
    @Address2                        NVARCHAR(1000),
    @Address3                        NVARCHAR(1000),
    @City                            NVARCHAR(100),
    @StateOrProvince                 NVARCHAR(100),
    @PostalCode                      NVARCHAR(100),
    @CountryId                       BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @BankAddressId BIGINT;

        SELECT @BankAddressId = BankAddressId
        FROM InternationalWirePayment WITH (NOLOCK)
        WHERE InternationalWirePaymentId = @InternationalWirePaymentId;

        IF @BankAddressId IS NOT NULL
        BEGIN
            UPDATE Address
            SET Line1 = @Address1,
                Line2 = @Address2,
                Line3 = @Address3,
                City = ISNULL(@City, ''),
                StateOrProvince = ISNULL(@StateOrProvince, ''),
                PostalCode = ISNULL(@PostalCode, ''),
                CountryId = @CountryId,
                MasterCompanyId = @MasterCompanyId,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE AddressId = @BankAddressId;
        END

        UPDATE InternationalWirePayment
        SET SwiftCode = @SwiftCode,
            BeneficiaryBankAccount = @BeneficiaryBankAccount,
            BeneficiaryBank = @BeneficiaryBank,
            BeneficiaryCustomer = @BeneficiaryCustomer,
            BeneficiaryCustomerId = @BeneficiaryCustomerId,
            VendorBankAccountTypeId = @VendorBankAccountTypeId,
            MasterCompanyId = @MasterCompanyId,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = GETUTCDATE(),
            IsActive = 1
        WHERE InternationalWirePaymentId = @InternationalWirePaymentId;

        SELECT 
            iwp.InternationalWirePaymentId,
            iwp.SwiftCode,
            iwp.BeneficiaryBankAccount,
            iwp.BeneficiaryBank,
            iwp.BeneficiaryCustomer,
            iwp.BeneficiaryCustomerId,
            iwp.VendorBankAccountTypeId,
            iwp.BankAddressId,
            iwp.MasterCompanyId,
            iwp.CreatedBy,
            iwp.CreatedDate,
            iwp.UpdatedBy,
            iwp.UpdatedDate,
            iwp.IsActive,
            a.Line1 AS Address1,
            a.Line2 AS Address2,
            a.Line3 AS Address3,
            a.City,
            a.StateOrProvince,
            a.PostalCode,
            a.CountryId,
            iwp.IsDeleted
        FROM InternationalWirePayment iwp WITH (NOLOCK)
        LEFT JOIN Address a WITH (NOLOCK) ON iwp.BankAddressId = a.AddressId
        WHERE iwp.InternationalWirePaymentId = @InternationalWirePaymentId;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        DECLARE 
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
            @AdhocComments VARCHAR(150) = '[USP_UpdateVendorInternationalWirePayment]',
            @ProcedureParameters VARCHAR(3000) = '',
            @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occurred. Please contact support. ErrorLogID: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END