/*************************************************************
 ** File:   [USP_SaveVendorACHPayment]
 ** Author:   Nakul
 ** Description: Creates or updates the ACH Transfer banking details of a Vendor.
 **              A vendor has one active ACH record; saving without an Id updates
 **              the existing record of that vendor if there is one.
 ** Purpose: Vendor > Payment Info > ACH Transfer tab
 ** Date:   21/10/2026

 ** RETURN VALUE:
 The saved record (same columns as USP_GetVendorACHPaymentByVendorId)

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				--------------------------------
    1    21/10/2026   Nakul					Created (PN-18294)
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveVendorACHPayment]
    @VendorACHPaymentId BIGINT = 0,
    @VendorId BIGINT,
    @PayeeName VARCHAR(100),
    @IntermediateBankName VARCHAR(100) = NULL,
    @BeneficiaryBankName VARCHAR(100) = NULL,
    @AccountNumber VARCHAR(50),
    @ABA VARCHAR(50),
    @SwiftCode VARCHAR(50) = NULL,
    @GLAccountId BIGINT = NULL,
    @VendorBankAccountTypeId INT = NULL,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(256),
    @UpdatedBy VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
    BEGIN TRANSACTION

        DECLARE @CurrentDate DATETIME2 = GETUTCDATE();

        IF ISNULL(@VendorACHPaymentId, 0) = 0
        BEGIN
            SELECT TOP 1 @VendorACHPaymentId = VendorACHPaymentId
            FROM dbo.VendorACHPayment WITH (NOLOCK)
            WHERE VendorId = @VendorId AND IsDeleted = 0
            ORDER BY VendorACHPaymentId DESC;
        END

        IF ISNULL(@VendorACHPaymentId, 0) > 0
        BEGIN
            UPDATE dbo.VendorACHPayment
            SET PayeeName = @PayeeName,
                IntermediateBankName = @IntermediateBankName,
                BeneficiaryBankName = @BeneficiaryBankName,
                AccountNumber = @AccountNumber,
                ABA = @ABA,
                SwiftCode = @SwiftCode,
                GLAccountId = @GLAccountId,
                VendorBankAccountTypeId = NULLIF(@VendorBankAccountTypeId, 0),
                MasterCompanyId = @MasterCompanyId,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = @CurrentDate,
                IsActive = 1
            WHERE VendorACHPaymentId = @VendorACHPaymentId;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.VendorACHPayment (
                VendorId, PayeeName, IntermediateBankName, BeneficiaryBankName,
                AccountNumber, ABA, SwiftCode, GLAccountId, VendorBankAccountTypeId,
                MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
            )
            VALUES (
                @VendorId, @PayeeName, @IntermediateBankName, @BeneficiaryBankName,
                @AccountNumber, @ABA, @SwiftCode, @GLAccountId, NULLIF(@VendorBankAccountTypeId, 0),
                @MasterCompanyId, @CreatedBy, @UpdatedBy, @CurrentDate, @CurrentDate, 1, 0
            );
        END

    COMMIT TRANSACTION

        EXEC dbo.USP_GetVendorACHPaymentByVendorId @VendorId = @VendorId;
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            ROLLBACK TRAN;
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
            , @AdhocComments VARCHAR(150) = 'USP_SaveVendorACHPayment'
            , @ProcedureParameters VARCHAR(3000) = '@VendorId = ' + ISNULL(CAST(@VendorId AS VARCHAR(20)), '')
                                                 + ', @VendorACHPaymentId = ' + ISNULL(CAST(@VendorACHPaymentId AS VARCHAR(20)), '')
            , @ApplicationName VARCHAR(100) = 'PAS'
        EXEC dbo.spLogException
            @DatabaseName = @DatabaseName
            , @AdhocComments = @AdhocComments
            , @ProcedureParameters = @ProcedureParameters
            , @ApplicationName = @ApplicationName
            , @ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN(1);
    END CATCH
END
