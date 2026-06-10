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
    2    08-Jun-2026     Bhargav Saliya	  Modified

 EXECUTE [Xero_GetNewGLAccountListForCreateAccount] 2,1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetNewCreditMemoListForCreateCreditMemo]
    @IntegrationTypeId INT     = NULL,
    @MasterCompanyId   INT     = NULL,
    @ModuleId BIGINT 
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY

        DECLARE @XeroIntegrationTypeId INT
        SELECT @XeroIntegrationTypeId = IntegrationTypeId 
        FROM dbo.AccountingIntegrationType WITH(NOLOCK) 
        WHERE IntegrationType = 'Xero'

        DECLARE @PostedStatusId INT 
        SELECT @PostedStatusId = Id 
        FROM dbo.CreditMemoStatus WITH(NOLOCK) 
        WHERE UPPER(Name) = 'POSTED'

        DECLARE @CustCreditModuleId BIGINT,@VendorCrediModuleId BIGINT;

        SELECT @CustCreditModuleId = [AccountingModuleId] FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'CREDITMEMO';
		SELECT @VendorCrediModuleId = [AccountingModuleId] FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'VENDORCREDITMEMO';

        IF(ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId)
        BEGIN

            -- ✅ Customer Credit Memo
            IF(@ModuleId = @CustCreditModuleId)
            BEGIN
                -- Table[0]: Header
                SELECT
                    CM.CreditMemoHeaderId       AS CreditMemoId,
                    CM.CreditMemoNumber,
                    CM.InvoiceDate              AS CreditMemoDate,
                    CM.MasterCompanyId,
                    CM.QuickBooksReferenceId,
                    CST.QuickBooksReferenceId   AS ContactQuickBooksReferenceId
                FROM dbo.CreditMemo CM WITH(NOLOCK)
                INNER JOIN dbo.Customer CST WITH(NOLOCK) ON CST.CustomerId = CM.CustomerId
                WHERE ISNULL(CM.QuickBooksReferenceId, '') = ''
                  AND ISNULL(CM.IsUpdated, 0) = 1
                  AND CM.IsActive  = 1
                  AND CM.IsDeleted = 0
                  AND CM.StatusId  = @PostedStatusId
                  AND CM.MasterCompanyId = @MasterCompanyId

                -- Table[1]: Line Items
                SELECT
                    CMD.CreditMemoDetailId      AS LineItemId,
                    CMD.CreditMemoHeaderId      AS CreditMemoId,
                    CMD.PartNumber,
                    CMD.PartDescription         AS Description,
                    CMD.Qty,
                    CMD.UnitPrice               AS UnitAmount,
                    GA.QuickBooksReferenceId    AS GLAccountReferenceId,
                    --GA.AccountCode,
                    '1200' as AccountCode,
                    GA.AccountName,
                    IM.ItemMasterId
                FROM dbo.CreditMemoDetails CMD WITH(NOLOCK)
                INNER JOIN dbo.CreditMemo CM WITH(NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
                LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = CMD.ItemMasterId
                LEFT JOIN dbo.GLAccount GA WITH(NOLOCK) ON GA.GLAccountId = IM.GLAccountId
                WHERE ISNULL(CM.QuickBooksReferenceId, '') = ''
                  AND ISNULL(CM.IsUpdated, 0) = 1
                  AND CM.IsActive  = 1
                  AND CM.IsDeleted = 0
                  AND CMD.IsActive  = 1
                  AND CMD.IsDeleted = 0
                  AND CM.StatusId  = @PostedStatusId
                  AND CM.MasterCompanyId = @MasterCompanyId
            END

            --Vendor Credit Memo
            IF(@ModuleId = @VendorCrediModuleId)
            BEGIN
                -- Table[0]: Header
                SELECT
                    VCM.VendorCreditMemoId          AS CreditMemoId,
                    VCM.VendorCreditMemoNumber      AS CreditMemoNumber,
                    VCM.OpenDate                    AS CreditMemoDate,
                    VCM.MasterCompanyId,
                    VCM.QuickBooksReferenceId,
                    V.QuickBooksReferenceId         AS ContactQuickBooksReferenceId
                FROM dbo.VendorCreditMemo VCM WITH(NOLOCK)
                INNER JOIN dbo.Vendor V WITH(NOLOCK) ON V.VendorId = VCM.VendorId
                WHERE ISNULL(VCM.QuickBooksReferenceId, '') = ''
                  AND ISNULL(VCM.IsUpdated, 0) = 1
                  AND VCM.IsActive  = 1
                  AND VCM.IsDeleted = 0
                  AND VCM.VendorCreditMemoStatusId = @PostedStatusId
                  AND VCM.MasterCompanyId = @MasterCompanyId

                -- Table[1]: Line Items
                SELECT
                    VCMD.VendorCreditMemoDetailId   AS LineItemId,
                    VCMD.VendorCreditMemoId         AS CreditMemoId,
                    IM.PartNumber,
                    IM.PartDescription            AS Description,
                    VCMD.Qty,
                    VCMD.UnitCost                   AS UnitAmount,
                    GA.QuickBooksReferenceId        AS GLAccountReferenceId,
                    --GA.AccountCode,
                    '2000' AccountCode,
                    GA.AccountName,
                    IM.ItemMasterId
                FROM dbo.VendorCreditMemoDetail VCMD WITH(NOLOCK)
                INNER JOIN dbo.VendorCreditMemo VCM WITH(NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
                LEFT JOIN Stockline sl WITH (NOLOCK) ON VCMD.StockLineId = sl.StockLineId
                LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = sl.ItemMasterId
                LEFT JOIN dbo.GLAccount GA WITH(NOLOCK) ON GA.GLAccountId = IM.GLAccountId
                WHERE ISNULL(VCM.QuickBooksReferenceId, '') = ''
                  AND ISNULL(VCM.IsUpdated, 0) = 1
                  AND VCM.IsActive  = 1
                  AND VCM.IsDeleted = 0
                  AND VCMD.IsActive  = 1
                  AND VCMD.IsDeleted = 0
                  AND VCM.VendorCreditMemoStatusId = @PostedStatusId
                  AND VCM.MasterCompanyId = @MasterCompanyId
            END
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
