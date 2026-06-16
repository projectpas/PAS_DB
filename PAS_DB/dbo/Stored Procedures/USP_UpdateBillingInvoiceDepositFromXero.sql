/*************************************************************
 ** File:        [USP_UpdateBillingInvoiceDepositFromXero]
 ** Author:      Abhishek Jirawla
 ** Description: Saves a payment made directly in Xero into PAS.
 **
 ** Parameters:
 **   @BillingInvoicingId  BIGINT
 **   @MasterCompanyId     INT
 **************************************************************
 ** Change History
 **************************************************************
 ** PR  Date          Author              Description
 ** --  ----------    ----------------    --------------------
    1   15-Jun-2026   Abhishek Jirawla    Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateBillingInvoiceDepositFromXero]
    @BillingInvoicingId BIGINT,
    @MasterCompanyId    INT,
    @DepositAmount      DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.BillingInvoicing
    SET
        DepositAmount   = @DepositAmount,
        RemainingAmount = ISNULL(GrandTotal, 0) - @DepositAmount,
        UpdatedDate     = GETUTCDATE()
    WHERE BillingInvoicingId = @BillingInvoicingId
      AND MasterCompanyId    = @MasterCompanyId;
END