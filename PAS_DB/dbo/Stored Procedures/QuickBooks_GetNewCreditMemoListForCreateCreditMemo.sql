/*************************************************************           
 ** File:  [QuickBooks_GetNewCreditMemoListForCreateCreditMemo]          
 ** Author:   Bhargav Saliya
 ** Description: Get Credit Memo For Sync In  Xero    
 ** Purpose:         
 ** Date:   03-Jun-2026      
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    03-Jun-2026     Bhargav Saliya	  Created

 EXECUTE [Xero_GetNewGLAccountListForCreateAccount] 2,1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetNewCreditMemoListForCreateCreditMemo]
    @IntegrationTypeId INT = NULL,
    @MasterCompanyId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY

        DECLARE @QBIntegrationTypeId    INT
               ,@XeroIntegrationTypeId  INT
               ,@PostedStatusId         INT  

        SELECT @QBIntegrationTypeId   = IntegrationTypeId FROM dbo.AccountingIntegrationType WITH(NOLOCK) WHERE IntegrationType = 'QuickBooks'
        SELECT @XeroIntegrationTypeId = IntegrationTypeId FROM dbo.AccountingIntegrationType WITH(NOLOCK) WHERE IntegrationType = 'Xero'

        -- Get Posted StatusId
        SELECT @PostedStatusId = Id FROM dbo.CreditMemoStatus WITH(NOLOCK) WHERE UPPER(Name) = 'POSTED'

        -- FOR Xero
        IF(ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId)
        BEGIN
            -- Table[0]: Credit Memo Header
            SELECT 
                CM.CreditMemoHeaderId,
                CM.CreditMemoNumber,
                CM.InvoiceId,
                CM.InvoiceNumber,
                CM.InvoiceDate,
                CM.CustomerId,
                CM.CustomerName,
                CM.CustomerCode,
                CM.Status,
                CM.StatusId,
                CM.Notes,
                CM.Memo,
                CM.Amount,
                CM.TotalFreight,
                CM.TotalCharges,
                CM.MasterCompanyId,
                CM.QuickBooksReferenceId,
                CM.IsUpdated,
                CM.SyncToken,
                CST.QuickBooksReferenceId AS CustomerQuickBooksReferenceId
            FROM dbo.CreditMemo CM WITH(NOLOCK)
            INNER JOIN dbo.Customer CST WITH(NOLOCK) ON CST.CustomerId = CM.CustomerId
            WHERE ISNULL(CM.QuickBooksReferenceId, '') = ''
              AND ISNULL(CM.IsUpdated, 0) = 1
              AND CM.IsActive = 1
              AND CM.IsDeleted = 0
              AND CM.StatusId = @PostedStatusId  
              AND CM.MasterCompanyId = @MasterCompanyId

            -- Table[1]: Credit Memo Line Items
            SELECT 
                CMD.CreditMemoDetailId,
                CMD.CreditMemoHeaderId,
                CMD.ItemMasterId,
                CMD.PartNumber,
                CMD.PartDescription         AS Description,
                CMD.Qty,
                CMD.UnitPrice               AS UnitAmount,
                CMD.Amount,
                CMD.SalesTax,
                CMD.OtherTax,
                CMD.Notes,
                CMD.Reason,
                IM.QuickBooksReferenceId    AS ItemReferenceId,
                GA.QuickBooksReferenceId    AS GLAccountReferenceId,
                GA.AccountCode,
                GA.AccountName
            FROM dbo.CreditMemoDetails CMD WITH(NOLOCK)
            INNER JOIN dbo.CreditMemo CM WITH(NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
            LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = CMD.ItemMasterId
            LEFT JOIN dbo.GLAccount GA WITH(NOLOCK) ON GA.GLAccountId = IM.GLAccountId
            WHERE ISNULL(CM.QuickBooksReferenceId, '') = ''
              AND ISNULL(CM.IsUpdated, 0) = 1
              AND CM.IsActive = 1
              AND CM.IsDeleted = 0
              AND CMD.IsActive = 1
              AND CMD.IsDeleted = 0
              AND CM.StatusId = @PostedStatusId  
              AND CM.MasterCompanyId = @MasterCompanyId
        END

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT
            ,@DatabaseName          VARCHAR(100) = db_name()
            ,@AdhocComments         VARCHAR(150) = 'QuickBooks_GetNewCreditMemoListForCreateCreditMemo'
            ,@ProcedureParameters   VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS VARCHAR(100))
            ,@ApplicationName       VARCHAR(100) = 'PAS'

        EXEC spLogException
             @DatabaseName          = @DatabaseName
            ,@AdhocComments         = @AdhocComments
            ,@ProcedureParameters   = @ProcedureParameters
            ,@ApplicationName       = @ApplicationName
            ,@ErrorLogID            = @ErrorLogID OUTPUT

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN(1)
    END CATCH
END