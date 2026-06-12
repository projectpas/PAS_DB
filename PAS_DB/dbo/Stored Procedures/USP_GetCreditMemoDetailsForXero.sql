/*************************************************************           
 ** File:  [USP_GetCreditMemoDetailsForXero]          
 ** Author:   Bhargav Saliya
 ** Description: Get Credit Memo Part Details    
 ** Purpose:         
 ** Date:   02-Jun-2026      
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    02-Jun-2026     Bhargav Saliya	  Created
    2    11-Jun-2026     Bhargav Saliya	  Modified  

--  EXECUTE [USP_GetCreditMemoDetailsForXero] 1, 36
 EXECUTE [USP_GetCreditMemoDetailsForXero] 77, 68
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetCreditMemoDetailsForXero]
    @CreditMemoId BIGINT,
    @ModuleId     BIGINT  
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY

        DECLARE @CustCreditModuleId     BIGINT
               ,@VendorCrediModuleId    BIGINT
               ,@CustGLAccountId        BIGINT
               ,@CustAccountCode        VARCHAR(50)
               ,@CustXeroGUID           VARCHAR(200)
               ,@VendorGLAccountId      BIGINT
               ,@VendorAccountCode      VARCHAR(50)
               ,@VendorXeroGUID         VARCHAR(200)
               ,@MasterCompanyId        INT

        SELECT @CustCreditModuleId  = AccountingModuleId FROM dbo.AccountingModule WITH(NOLOCK) WHERE UPPER(AccountingModuleName) = 'CREDITMEMO'

        SELECT @VendorCrediModuleId = AccountingModuleId FROM dbo.AccountingModule WITH(NOLOCK) WHERE UPPER(AccountingModuleName) = 'VENDORCREDITMEMO'

        --Get MasterCompanyId from Credit Memo
        IF(@ModuleId = @CustCreditModuleId)
            SELECT @MasterCompanyId = MasterCompanyId FROM dbo.CreditMemo WITH(NOLOCK) WHERE CreditMemoHeaderId = @CreditMemoId

        IF(@ModuleId = @VendorCrediModuleId)
            SELECT @MasterCompanyId = MasterCompanyId FROM dbo.VendorCreditMemo WITH(NOLOCK) WHERE VendorCreditMemoId = @CreditMemoId

        --Get Customer Credit Memo GL from Config Table
        SELECT 
            @CustGLAccountId  = XC.GLAccountId,
            @CustAccountCode  = XC.AccountCode,
            @CustXeroGUID     = GA.QuickBooksReferenceId
        FROM dbo.XeroAccountingGLConfig XC WITH(NOLOCK)
        INNER JOIN dbo.GLAccount GA WITH(NOLOCK) ON GA.GLAccountId = XC.GLAccountId
        WHERE XC.ModuleId = @CustCreditModuleId AND XC.MasterCompanyId = @MasterCompanyId AND ISNULL(XC.IsActive, 0) = 1 AND ISNULL(XC.IsDeleted, 0) = 0

        --Get Vendor Credit Memo GL from Config Table
        SELECT 
            @VendorGLAccountId = XC.GLAccountId,
            @VendorAccountCode = XC.AccountCode,
            @VendorXeroGUID    = GA.QuickBooksReferenceId
        FROM dbo.XeroAccountingGLConfig XC WITH(NOLOCK)
        INNER JOIN dbo.GLAccount GA WITH(NOLOCK) ON GA.GLAccountId = XC.GLAccountId
        WHERE XC.ModuleId = @VendorCrediModuleId AND XC.MasterCompanyId = @MasterCompanyId AND ISNULL(XC.IsActive, 0) = 1 AND ISNULL(XC.IsDeleted, 0) = 0

        --Customer Credit Memo
        IF(@ModuleId = @CustCreditModuleId)
        BEGIN
            -- Table[0]: Header
            SELECT
                CM.CreditMemoHeaderId   AS CreditMemoId,
                CM.CreditMemoNumber,
                CM.InvoiceDate          AS CreditMemoDate,
                CM.MasterCompanyId,
                CM.QuickBooksReferenceId,
                CM.IsUpdated,
                CM.SyncToken,
                CST.QuickBooksReferenceId AS ContactQuickBooksReferenceId
            FROM dbo.CreditMemo CM WITH(NOLOCK)
            INNER JOIN dbo.Customer CST WITH(NOLOCK) ON CST.CustomerId = CM.CustomerId
            WHERE CM.CreditMemoHeaderId = @CreditMemoId
              AND ISNULL(CM.IsActive,0)  = 1
              AND ISNULL(CM.IsDeleted,0) = 0

            -- Table[1]: Line Items
            SELECT
                CMD.CreditMemoDetailId  AS LineItemId,
                CMD.CreditMemoHeaderId  AS CreditMemoId,
                CMD.PartNumber,
                CMD.PartDescription     AS Description,
                CMD.Qty,
                CMD.UnitPrice           AS UnitAmount,
                -- ✅ From Config Table
                @CustXeroGUID           AS GLAccountReferenceId,
                @CustAccountCode        AS AccountCode,
                IM.ItemMasterId
            FROM dbo.CreditMemoDetails CMD WITH(NOLOCK)
            INNER JOIN dbo.CreditMemo CM WITH(NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
            LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = CMD.ItemMasterId
            WHERE CMD.CreditMemoHeaderId = @CreditMemoId
              AND ISNULL(CMD.IsActive,0)  = 1
              AND ISNULL(CMD.IsDeleted,0) = 0
        END

        -- Vendor Credit Memo
        IF(@ModuleId = @VendorCrediModuleId)
        BEGIN
            -- Table[0]: Header
            SELECT
                VCM.VendorCreditMemoId      AS CreditMemoId,
                VCM.VendorCreditMemoNumber  AS CreditMemoNumber,
                VCM.OpenDate                AS CreditMemoDate,
                VCM.MasterCompanyId,
                VCM.QuickBooksReferenceId,
                VCM.IsUpdated,
                VCM.SyncToken,
                V.QuickBooksReferenceId     AS ContactQuickBooksReferenceId
            FROM dbo.VendorCreditMemo VCM WITH(NOLOCK)
            INNER JOIN dbo.Vendor V WITH(NOLOCK) ON V.VendorId = VCM.VendorId
            WHERE VCM.VendorCreditMemoId = @CreditMemoId
              AND ISNULL(VCM.IsActive,0)  = 1
              AND ISNULL(VCM.IsDeleted,0) = 0

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
            WHERE VCMD.VendorCreditMemoId = @CreditMemoId
              AND ISNULL(VCMD.IsActive,0)  = 1
              AND ISNULL(VCMD.IsDeleted,0) = 0
        END

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT
            ,@DatabaseName          VARCHAR(100) = db_name()
            ,@AdhocComments         VARCHAR(150) = 'USP_GetCreditMemoDetailsForXero'
            ,@ProcedureParameters   VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CreditMemoId, '') AS VARCHAR(100))
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