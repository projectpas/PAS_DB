/****************************************************************************************** 
** File:        [USP_CreateInternationalWirePayment]
** Author:      Ayushi Patel
** Description: Create International Wire Payment record for a Vendor, including Address.
** Date:        17-07-2025
*******************************************************************************************
** Change History
*******************************************************************************************
** PR     Date         Author         Change Description
** --     ----------   ------------   -----------------------------------------------------
** 1      17-07-2025   Ayushi Patel   Created
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateInternationalWirePayment]
    @MasterCompanyId BIGINT,
    @SwiftCode NVARCHAR(100),
    @BeneficiaryBankAccount NVARCHAR(100),
    @BeneficiaryBank NVARCHAR(200),
    @BeneficiaryCustomerId BIGINT,
	@BeneficiaryCustomer  NVARCHAR(100),
    @VendorBankAccountTypeId BIGINT,
    @Address1 NVARCHAR(100),
    @Address2 NVARCHAR(100)=NULL,
    @Address3 NVARCHAR(100)=NULL,
    @PostalCode NVARCHAR(50),
    @StateOrProvince NVARCHAR(100),
    @City NVARCHAR(100),
    @CountryId BIGINT,
    @IntermediaryBank NVARCHAR(200) = NULL,
    @ABA NVARCHAR(100) = NULL,
    @BankName NVARCHAR(200) = NULL,
    @BankLocation1 NVARCHAR(200) = NULL,
    @BankLocation2 NVARCHAR(200) = NULL,
    @GLAccountId BIGINT = NULL,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100),
    @IsActive BIT = 1 
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @CurrentDate DATETIME = GETUTCDATE();
        DECLARE @AddressId BIGINT;
        DECLARE @InternationalWirePaymentId BIGINT;

        
        INSERT INTO [dbo].[Address] (
            Line1, Line2, Line3, PostalCode, StateOrProvince,
            City, CountryId, MasterCompanyId,
            CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive
        )
        VALUES (
            ISNULL(@Address1, ''), @Address2, @Address3, @PostalCode, @StateOrProvince,
            @City, @CountryId, @MasterCompanyId,
            @CreatedBy, @UpdatedBy, @CurrentDate, @CurrentDate, ISNULL(@IsActive, 1)
        );

        SET @AddressId = SCOPE_IDENTITY();

        
        INSERT INTO [dbo].[InternationalwirePayment] (
            SwiftCode, BeneficiaryBankAccount, BeneficiaryBank,
            IntermediaryBank, ABA, BankName,
            BankLocation1, BankLocation2,
            BeneficiaryCustomerId, VendorBankAccountTypeId, GLAccountId,
            BankAddressId,BeneficiaryCustomer, MasterCompanyId,
            CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive
        )
        VALUES (
            @SwiftCode, @BeneficiaryBankAccount, @BeneficiaryBank,
            @IntermediaryBank, @ABA, @BankName,
            @BankLocation1, @BankLocation2,
            @BeneficiaryCustomerId, @VendorBankAccountTypeId, @GLAccountId,
            @AddressId,@BeneficiaryCustomer, @MasterCompanyId,
            @CreatedBy, @UpdatedBy, @CurrentDate, @CurrentDate, 1
        );

        SET @InternationalWirePaymentId = SCOPE_IDENTITY();

        
        SELECT 
            i.InternationalWirePaymentId,
            i.SwiftCode,
            i.BeneficiaryBankAccount,
            i.BeneficiaryBank,
            i.IntermediaryBank,
            i.ABA,
            i.BankName,
            i.BankAddressId,
            i.BeneficiaryCustomerId,
            i.BeneficiaryCustomer,
            i.BankLocation1,
            i.BankLocation2,
            i.GLAccountId,
            i.VendorBankAccountTypeId,
            i.MasterCompanyId,
            i.CreatedBy,
            i.CreatedDate,
            i.UpdatedBy,
            i.UpdatedDate,
            i.IsActive,
            i.IsDeleted
        FROM [dbo].[InternationalwirePayment] i
        WHERE i.InternationalWirePaymentId = @InternationalWirePaymentId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        DECLARE 
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
            @AdhocComments VARCHAR(150) = '[USP_CreateInternationalWirePayment]',
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