
/*************************************************************
 ** File:        [USP_GetKnownXeroPaymentIds]
 ** Author:      Abhishek Jirawla
 ** Description: Returns all Xero PaymentIDs already present in
 **              the PAS system for a given company.  This covers:
 **
 **              (a) Payments pushed FROM PAS → Xero
 **                  (recorded by QuickBooks_UpdateReferenceDetails
 **                   with ModuleName = 'CustomerPayment').
 **
 **              (b) Payments previously imported FROM Xero → PAS
 **                  (recorded by USP_SaveXeroInboundPayment).
 **
 **              Both sets are stored in CustomerPaymentDetails
 **              .QuickBooksReferenceId with IntegrationTypeId = Xero.
 **              The sync engine skips any Xero payment whose ID is
 **              in this result set.
 ** Parameters:
 **   @MasterCompanyId  INT  - company filter
 **************************************************************
 ** Change History
 **************************************************************
 ** PR  Date          Author              Description
 ** --  ----------    ----------------    --------------------
    1   08-Jun-2026   Abhishek Jirawla    Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetKnownXeroPaymentIds]
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

        DECLARE @XeroIntegrationTypeId INT;
        SELECT @XeroIntegrationTypeId = IntegrationTypeId
        FROM   dbo.AccountingIntegrationType WITH (NOLOCK)
        WHERE  IntegrationType = 'Xero';

        SELECT DISTINCT
            cpd.QuickBooksReferenceId AS XeroPaymentId
        FROM   dbo.CustomerPaymentDetails  cpd WITH (NOLOCK)
        JOIN   dbo.CustomerPayments        cp  WITH (NOLOCK)
               ON  cp.ReceiptId = cpd.ReceiptId
        JOIN   dbo.ManagementStructure     ms  WITH (NOLOCK)
               ON  ms.ManagementStructureId = cp.ManagementStructureId
        WHERE  cpd.IntegrationTypeId                  = @XeroIntegrationTypeId
          AND  ISNULL(cpd.QuickBooksReferenceId, '') <> ''
          AND  ISNULL(cpd.IsDeleted, 0)               = 0
          AND  ISNULL(cp.IsDeleted, 0)                = 0
          AND  ms.MasterCompanyId                     = @MasterCompanyId;

    END TRY
    BEGIN CATCH

        DECLARE @ErrorLogID           INT
              , @DatabaseName         VARCHAR(100) = DB_NAME()
              , @AdhocComments        VARCHAR(150)  = 'USP_GetKnownXeroPaymentIds'
              , @ProcedureParameters  VARCHAR(3000) = '@MasterCompanyId = '
                                                      + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(20))
              , @ApplicationName      VARCHAR(100)  = 'PAS';

        EXEC spLogException
             @DatabaseName         = @DatabaseName
           , @AdhocComments        = @AdhocComments
           , @ProcedureParameters  = @ProcedureParameters
           , @ApplicationName      = @ApplicationName
           , @ErrorLogID           = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN 1;

    END CATCH
END