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
    2    11-Jun-2026     Bhargav Saliya	  Modified 
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

 EXECUTE [Xero_GetNewGLAccountListForCreateAccount] 2,1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetNewCreditMemoListForCreateCreditMemo]
    @IntegrationTypeId INT    = NULL,
    @MasterCompanyId   INT    = NULL,
    @ModuleId          BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY

        DECLARE @XeroIntegrationTypeId  INT
               ,@PostedStatusId         INT
               ,@CustCreditModuleId     BIGINT
               ,@VendorCrediModuleId    BIGINT
               ,@CustAccountCode        VARCHAR(50)
               ,@CustXeroGUID           VARCHAR(200)
               ,@VendorAccountCode      VARCHAR(50)
               ,@VendorXeroGUID         VARCHAR(200)

        SELECT @XeroIntegrationTypeId = IntegrationTypeId FROM dbo.AccountingIntegrationType WITH(NOLOCK) WHERE IntegrationType = 'Xero'

        SELECT @PostedStatusId = Id FROM dbo.CreditMemoStatus WITH(NOLOCK) WHERE UPPER(Name) = 'POSTED'

        SELECT @CustCreditModuleId  = AccountingModuleId FROM dbo.AccountingModule WITH(NOLOCK) WHERE UPPER(AccountingModuleName) = 'CREDITMEMO'

        SELECT @VendorCrediModuleId = AccountingModuleId FROM dbo.AccountingModule WITH(NOLOCK) WHERE UPPER(AccountingModuleName) = 'VENDORCREDITMEMO'

        --Get Customer Credit Memo GL from Config Table
        SELECT 
            @CustAccountCode = XC.AccountCode,
            @CustXeroGUID    = GA.QuickBooksReferenceId
        FROM dbo.XeroAccountingGLConfig XC WITH(NOLOCK)
        INNER JOIN dbo.GLAccount GA WITH(NOLOCK) ON GA.GLAccountId = XC.GLAccountId
        WHERE XC.ModuleId = @CustCreditModuleId AND XC.MasterCompanyId = @MasterCompanyId AND ISNULL(XC.IsActive, 0)  = 1 AND ISNULL(XC.IsDeleted, 0) = 0

        --Get Vendor Credit Memo GL from Config Table
        SELECT 
            @VendorAccountCode = XC.AccountCode,
            @VendorXeroGUID    = GA.QuickBooksReferenceId
        FROM dbo.XeroAccountingGLConfig XC WITH(NOLOCK)
        INNER JOIN dbo.GLAccount GA WITH(NOLOCK) ON GA.GLAccountId = XC.GLAccountId 
        WHERE XC.ModuleId = @VendorCrediModuleId AND XC.MasterCompanyId = @MasterCompanyId AND ISNULL(XC.IsActive, 0)  = 1 AND ISNULL(XC.IsDeleted, 0) = 0

        IF(ISNULL(@IntegrationTypeId, 0) = @XeroIntegrationTypeId)
        BEGIN

            --Customer Credit Memo
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
                  AND ISNULL(CM.IsUpdated, 1) = 1
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
                    CMD.COGSPartsUnitCost       AS UnitAmount,
                    --From Config Table
                    @CustXeroGUID               AS GLAccountReferenceId,
                    @CustAccountCode            AS AccountCode,
                    IM.ItemMasterId
                FROM dbo.CreditMemoDetails CMD WITH(NOLOCK)
                INNER JOIN dbo.CreditMemo CM WITH(NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
                LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = CMD.ItemMasterId
                 AND ISNULL(IM.IsNonStock,0) = 0 WHERE ISNULL(CM.QuickBooksReferenceId, '') = ''
                  AND ISNULL(CM.IsUpdated, 1) = 1
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
                  AND ISNULL(VCM.IsUpdated, 1) = 1
                  AND VCM.IsActive  = 1
                  AND VCM.IsDeleted = 0
                  AND VCM.VendorCreditMemoStatusId = @PostedStatusId
                  AND VCM.MasterCompanyId = @MasterCompanyId

                -- Table[1]: Line Items
                SELECT
                    VCMD.VendorCreditMemoDetailId   AS LineItemId,
                    VCMD.VendorCreditMemoId         AS CreditMemoId,
                    IM.PartNumber,
                    IM.PartDescription              AS Description,
                    VCMD.Qty,
                    VCMD.UnitCost                   AS UnitAmount,
                    --From Config Table
                    @VendorXeroGUID                 AS GLAccountReferenceId,
                    @VendorAccountCode              AS AccountCode,
                    IM.ItemMasterId
                FROM dbo.VendorCreditMemoDetail VCMD WITH(NOLOCK)
                INNER JOIN dbo.VendorCreditMemo VCM WITH(NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
                LEFT JOIN dbo.Stockline SL WITH(NOLOCK) ON VCMD.StockLineId = SL.StockLineId
                LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = SL.ItemMasterId
                 AND ISNULL(IM.IsNonStock,0) = 0 WHERE ISNULL(VCM.QuickBooksReferenceId, '') = ''
                  AND ISNULL(VCM.IsUpdated, 1) = 1
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