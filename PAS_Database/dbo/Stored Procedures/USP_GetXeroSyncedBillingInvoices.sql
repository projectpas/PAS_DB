
/*************************************************************
 ** File:        [USP_GetXeroSyncedBillingInvoices]
 ** Author:      Abhishek Jirawla
 ** Description: Returns all BillingInvoicing records that have
 **              been synced to Xero (QuickBooksReferenceId is
 **              populated with a Xero Invoice GUID).
 **              Used by XeroPaymentService.SyncPaymentsFromXeroAsync
 **              to determine which invoices to check for inbound
 **              payments.
 ** Parameters:
 **   @MasterCompanyId  INT  - company filter
 **   @ModuleId         INT  - 0 = all modules, otherwise filter
 **************************************************************
 ** Change History
 **************************************************************
 ** PR  Date          Author              Description
 ** --  ----------    ----------------    --------------------
    1   08-Jun-2026   Abhishek Jirawla    Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetXeroSyncedBillingInvoices]
    @MasterCompanyId INT,
    @ModuleId        INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

        DECLARE @XeroIntegrationTypeId INT;
        SELECT @XeroIntegrationTypeId = IntegrationTypeId
        FROM   dbo.AccountingIntegrationType WITH (NOLOCK)
        WHERE  IntegrationType = 'Xero';

        SELECT
            bi.BillingInvoicingId,
            bi.QuickBooksReferenceId AS XeroInvoiceId,
            bi.InvoiceNo,
            bi.ModuleId,
            bi.CustomerId
        FROM   dbo.BillingInvoicing      bi WITH (NOLOCK)
        JOIN   dbo.ManagementStructure   ms WITH (NOLOCK)
               ON  ms.ManagementStructureId = bi.ManagementStructureId
        WHERE  ISNULL(bi.IsDeleted, 0)          = 0
          AND  ISNULL(bi.QuickBooksReferenceId, '') <> ''
          AND  bi.IntegrationTypeId              = @XeroIntegrationTypeId
          AND  ms.MasterCompanyId                = @MasterCompanyId
          AND  (@ModuleId = 0 OR bi.ModuleId     = @ModuleId);

    END TRY
    BEGIN CATCH

        DECLARE @ErrorLogID           INT
              , @DatabaseName         VARCHAR(100) = DB_NAME()
              , @AdhocComments        VARCHAR(150)  = 'USP_GetXeroSyncedBillingInvoices'
              , @ProcedureParameters  VARCHAR(3000) = '@MasterCompanyId = '
                                                      + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(20))
                                                      + ', @ModuleId = '
                                                      + CAST(ISNULL(@ModuleId, '') AS VARCHAR(20))
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