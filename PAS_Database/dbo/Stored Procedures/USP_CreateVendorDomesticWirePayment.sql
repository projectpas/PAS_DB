/******************************************************************************************
** File:         [USP_CreateVendorDomesticWirePayment]
** Author:       Ayushi Patel
** Description:  Creates a Domestic Wire Payment record for a Vendor, including Address.
** Date:         17-07-2025
*******************************************************************************************
** Change History
*******************************************************************************************
** PR     Date         Author         Change Description
** --     ----------   ------------   -----------------------------------------------------
** 1      17-07-2025   Ayushi Patel   Created
** 2      21-10-2026   Nakul          Added Payee Name, Bank Location 1/2, Intermediate Bank, SWIFT and GL Account (Legal Entity banking fields) (PN-18294)
**                                    Bank Address and Bank Account Type are optional; Address row is created only when CountryId is passed
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateVendorDomesticWirePayment]
    @ABA VARCHAR(50),
    @AccountNumber VARCHAR(100),
    @BankName VARCHAR(200) = NULL,
    @AccountNameId BIGINT,
    @VendorBankAccountTypeId BIGINT = NULL,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(100),
    @UpdatedBy VARCHAR(100),
    @CountryId INT = NULL,
    @Line1 VARCHAR(200) = NULL,
    @Line2 VARCHAR(200) = NULL,
    @Line3 VARCHAR(200) = NULL,
    @City VARCHAR(100) = NULL,
    @StateOrProvince VARCHAR(100) = NULL,
    @PostalCode VARCHAR(50) = NULL,
    @NewDomesticWirePaymentId BIGINT OUTPUT,
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

        DECLARE @CurrentDate DATETIME2 = GETUTCDATE();
        DECLARE @AddressId BIGINT;

        IF NULLIF(@CountryId, 0) IS NOT NULL
        BEGIN
            INSERT INTO dbo.Address (
                Line1, Line2, Line3,
                City, StateOrProvince, PostalCode, CountryId,
                MasterCompanyId, IsActive, IsDeleted,
                CreatedBy, CreatedDate, UpdatedBy, UpdatedDate
            )
            VALUES (
                ISNULL(@Line1, ''),
                @Line2,
                @Line3,
                ISNULL(@City, ''),
                ISNULL(@StateOrProvince, ''),
                ISNULL(@PostalCode, ''),
                @CountryId,
                IIF(@MasterCompanyId = 0, 1, @MasterCompanyId),
                1, -- IsActive
                0, -- IsDeleted
                @CreatedBy,
                @CurrentDate,
                @UpdatedBy,
                @CurrentDate
            );

            SET @AddressId = SCOPE_IDENTITY();
        END

        INSERT INTO dbo.DomesticWirePayment (
            ABA, AccountNumber, BankName, AccountNameId, VendorBankAccountTypeId,
            MasterCompanyId, IsActive,
            CreatedBy, CreatedDate, UpdatedBy, UpdatedDate,
            BankAddressId,
            PayeeName, BankLocation1, BankLocation2, IntermediaryBankName, SwiftCode, GLAccountId
        )
        VALUES (
            @ABA,
            @AccountNumber,
            ISNULL(@BankName, ''),
            @AccountNameId,
            NULLIF(@VendorBankAccountTypeId, 0),
            IIF(@MasterCompanyId = 0, 1, @MasterCompanyId),
            1,
            @CreatedBy,
            @CurrentDate,
            @UpdatedBy,
            @CurrentDate,
            @AddressId,
            @PayeeName, @BankLocation1, @BankLocation2, @IntermediaryBankName, @SwiftCode, @GLAccountId
        );

        SET @NewDomesticWirePaymentId = SCOPE_IDENTITY();

        SELECT
            d.DomesticWirePaymentId,
            d.ABA,
            d.AccountNumber,
            d.BankName,
            d.IntermediaryBankName,
            d.BenificiaryBankName,
            d.BankAddressId,
            d.AccountNameId,
            d.VendorBankAccountTypeId,
            d.MasterCompanyId,
            d.CreatedBy,
            d.CreatedDate,
            d.UpdatedBy,
            d.UpdatedDate,
            ISNULL(d.IsActive,0)AS IsActive,
            ISNULL(d.IsDeleted,0) AS IsDeleted,
            d.PayeeName,
            d.BankLocation1,
            d.BankLocation2,
            d.SwiftCode,
            d.GLAccountId
        FROM dbo.DomesticWirePayment d WITH (NOLOCK)
        WHERE d.DomesticWirePaymentId = @NewDomesticWirePaymentId;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[USP_CreateVendorDomesticWirePayment]',
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