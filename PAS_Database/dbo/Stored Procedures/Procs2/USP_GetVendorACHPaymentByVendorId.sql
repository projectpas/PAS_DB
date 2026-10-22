/*************************************************************
 ** File:   [USP_GetVendorACHPaymentByVendorId]
 ** Author:   Nakul
 ** Description: Gets the ACH Transfer banking details of a Vendor
 ** Purpose: Vendor > Payment Info > ACH Transfer tab and vendor view popups
 ** Date:   21/10/2026

 ** PARAMETERS:
 @VendorId BIGINT

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				--------------------------------
    1    21/10/2026   Nakul					Created (PN-18294)

 -- EXEC USP_GetVendorACHPaymentByVendorId 5526
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetVendorACHPaymentByVendorId]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        SELECT TOP 1
            ach.VendorACHPaymentId,
            ach.VendorId,
            ach.PayeeName,
            ach.IntermediateBankName,
            ach.BeneficiaryBankName,
            ach.AccountNumber,
            ach.ABA,
            ach.SwiftCode,
            ach.GLAccountId,
            ISNULL(gl.AccountCode + ' - ' + gl.AccountName, '') AS GLAccountName,
            ach.VendorBankAccountTypeId,
            ISNULL(bat.VendorBankAccountType, '') AS VendorBankAccountType,
            ach.MasterCompanyId,
            ach.CreatedBy,
            ach.CreatedDate,
            ach.UpdatedBy,
            ach.UpdatedDate,
            ach.IsActive,
            ach.IsDeleted
        FROM dbo.VendorACHPayment ach WITH (NOLOCK)
        LEFT JOIN dbo.GLAccount gl WITH (NOLOCK) ON gl.GLAccountId = ach.GLAccountId
        LEFT JOIN dbo.VendorBankAccountType bat WITH (NOLOCK) ON bat.VendorBankAccountTypeId = ach.VendorBankAccountTypeId
        WHERE ach.VendorId = @VendorId
          AND ach.IsDeleted = 0
        ORDER BY ach.VendorACHPaymentId DESC;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
            , @AdhocComments VARCHAR(150) = 'USP_GetVendorACHPaymentByVendorId'
            , @ProcedureParameters VARCHAR(3000) = '@VendorId = ' + ISNULL(CAST(@VendorId AS VARCHAR(20)), '')
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
