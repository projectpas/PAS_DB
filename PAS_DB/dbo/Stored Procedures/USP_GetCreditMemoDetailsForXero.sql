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

-- exec [USP_GetCreditMemoDetailsForXero] 181
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetCreditMemoDetailsForXero]
    @CreditMemoHeaderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        -- Table[0]: Credit Memo Header + Customer Xero GUID
        SELECT
            CM.CreditMemoHeaderId,
            CM.CreditMemoNumber,
            CM.CustomerId,
            CM.CustomerName,
            CM.InvoiceDate,
            CM.Status,
            CM.StatusId,
            CM.QuickBooksReferenceId,
            CST.QuickBooksReferenceId AS CustomerQuickBooksReferenceId
        FROM dbo.CreditMemo CM WITH(NOLOCK)
        INNER JOIN dbo.Customer CST WITH(NOLOCK) ON CST.CustomerId = CM.CustomerId
        WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId
          AND CM.IsActive  = 1
          AND CM.IsDeleted = 0

        -- Table[1]: Line Items
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
        WHERE CMD.CreditMemoHeaderId = @CreditMemoHeaderId
          AND CMD.IsActive  = 1
          AND CMD.IsDeleted = 0

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT
            ,@DatabaseName          VARCHAR(100) = db_name()
            ,@AdhocComments         VARCHAR(150) = 'USP_GetCreditMemoDetailsForXero'
            ,@ProcedureParameters   VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CreditMemoHeaderId, '') AS VARCHAR(100))
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