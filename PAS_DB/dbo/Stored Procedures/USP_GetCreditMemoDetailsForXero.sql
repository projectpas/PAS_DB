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
    1    05-Jun-2026     Bhargav Saliya	  Modified

--  EXECUTE [USP_GetCreditMemoDetailsForXero] 1, 36
 EXECUTE [USP_GetCreditMemoDetailsForXero] 77, 68
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetCreditMemoDetailsForXero]
    @CreditMemoId BIGINT,
    @ModuleId BIGINT  
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY

        DECLARE @CustCreditModuleId BIGINT,@VendorCrediModuleId BIGINT;
        --SELECT @CustCreditModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'CreditMemo';
        --SELECT @VendorCrediModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'VendorCreditMemo';

        SELECT @CustCreditModuleId = [AccountingModuleId] FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'CREDITMEMO';
		SELECT @VendorCrediModuleId = [AccountingModuleId] FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'VENDORCREDITMEMO';


        IF(@ModuleId = @CustCreditModuleId)
        BEGIN
            -- Table[0]: Header + Customer Xero GUID
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
              AND CM.IsActive  = 1
              AND CM.IsDeleted = 0

            -- Table[1]: Line Items
            SELECT
                CMD.CreditMemoDetailId  AS LineItemId,
                CMD.CreditMemoHeaderId  AS CreditMemoId,
                CMD.PartNumber,
                CMD.PartDescription     AS Description,
                CMD.Qty,
                CMD.UnitPrice           AS UnitAmount,
                GA.QuickBooksReferenceId AS GLAccountReferenceId,
                GA.AccountCode,
                GA.AccountName
            FROM dbo.CreditMemoDetails CMD WITH(NOLOCK)
            INNER JOIN dbo.CreditMemo CM WITH(NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
            LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = CMD.ItemMasterId
            LEFT JOIN dbo.GLAccount GA WITH(NOLOCK) ON GA.GLAccountId = IM.GLAccountId
            WHERE CMD.CreditMemoHeaderId = @CreditMemoId
              AND CMD.IsActive  = 1
              AND CMD.IsDeleted = 0
        END

        IF(@ModuleId = @VendorCrediModuleId)
        BEGIN
            -- Table[0]: Header + Vendor Xero GUID
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
              AND VCM.IsActive  = 1
              AND VCM.IsDeleted = 0

            -- Table[1]: Line Items
            SELECT
                VCMD.VendorCreditMemoDetailId   AS LineItemId,
                VCMD.VendorCreditMemoId         AS CreditMemoId,
                IM.PartNumber,
                IM.PartDescription            AS Description,
                VCMD.Qty,
                VCMD.UnitCost                   AS UnitAmount,
                GA.QuickBooksReferenceId        AS GLAccountReferenceId,
                GA.AccountCode,
                GA.AccountName
            FROM dbo.VendorCreditMemoDetail VCMD WITH(NOLOCK)
            INNER JOIN dbo.VendorCreditMemo VCM WITH(NOLOCK) ON VCM.VendorCreditMemoId = VCMD.VendorCreditMemoId
            LEFT JOIN Stockline sl WITH (NOLOCK) ON VCMD.StockLineId = sl.StockLineId
            LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = sl.ItemMasterId
            LEFT JOIN dbo.GLAccount GA WITH(NOLOCK) ON GA.GLAccountId = IM.GLAccountId
            WHERE VCMD.VendorCreditMemoId = @CreditMemoId
              AND VCMD.IsActive  = 1
              AND VCMD.IsDeleted = 0
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