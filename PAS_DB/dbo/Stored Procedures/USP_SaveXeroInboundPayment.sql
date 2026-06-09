
/*************************************************************
 ** File:        [USP_SaveXeroInboundPayment]
 ** Author:      Abhishek Jirawla
 ** Description: Saves a payment made directly in Xero into PAS.
 **
 **              Flow:
 **              1.  Guard — skip if Xero PaymentID already imported.
 **              2.  Read BillingInvoicing for context.
 **              3.  Generate ReceiptNo from CodePrefixes (CodePrefix=cR).
 **              4.  Insert CustomerPayments receipt (StatusId = 2 / Posted).
 **              5.  Insert CustomerPaymentDetails — XeroPaymentId stored in
 **                  QuickBooksReferenceId (USP_GetKnownXeroPaymentIds reads this).
 **              6.  Insert InvoicePayments — links receipt to billing invoice.
 **              7.  EXEC USP_UpdateBillingPayments — reduces BillingInvoicing.RemainingAmount.
 **              8.  EXEC UpdatePaymentPrice(@ReceiptId) — recalculates
 **                  CustomerPayments.AmtApplied / AmtRemaining from
 **                  CustomerPaymentDetails.Amount.
 **
 ** Parameters:
 **   @BillingInvoicingId  BIGINT
 **   @XeroInvoiceId       NVARCHAR(200)
 **   @XeroPaymentId       NVARCHAR(200)
 **   @Amount              DECIMAL(18,2)
 **   @PaymentDate         DATETIME
 **   @Reference           NVARCHAR(500)
 **   @AccountCode         NVARCHAR(50)
 **   @MasterCompanyId     INT
 **   @CreatedBy           NVARCHAR(200)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR  Date          Author              Description
 ** --  ----------    ----------------    --------------------
    1   08-Jun-2026   Abhishek Jirawla    Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveXeroInboundPayment]
    @BillingInvoicingId  BIGINT,
    @XeroInvoiceId       NVARCHAR(200),
    @XeroPaymentId       NVARCHAR(200),
    @Amount              DECIMAL(18, 2),
    @PaymentDate         DATETIME,
    @Reference           NVARCHAR(500) = NULL,
    @AccountCode         NVARCHAR(50)  = NULL,
    @MasterCompanyId     INT,
    @CreatedBy           NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
        --DECLARE @PostedStatusId TINYINT;
        --SELECT @PostedStatusId = Id FROM MasterCustomerPaymentStatus WHERE Name = 'Posted'

        ---- ── 0. Resolve Xero IntegrationTypeId ────────────────────────
        --DECLARE @XeroIntegrationTypeId INT;
        --SELECT @XeroIntegrationTypeId = IntegrationTypeId
        --FROM   dbo.AccountingIntegrationType WITH (NOLOCK)
        --WHERE  IntegrationType = 'Xero';

        ---- ── Guard: skip if this Xero PaymentID was already imported ───
        --IF EXISTS (
        --    SELECT 1
        --    FROM   dbo.CustomerPaymentDetails WITH (NOLOCK)
        --    WHERE  QuickBooksReferenceId = @XeroPaymentId
        --      AND  IntegrationTypeId     = @XeroIntegrationTypeId
        --      AND  ISNULL(IsDeleted, 0)  = 0
        --)
        --BEGIN
        --    ROLLBACK TRANSACTION;
        --    RETURN 0;
        --END

        -- ── 1. Look up context from BillingInvoicing ──────────────────
        DECLARE @ManagementStructureId  BIGINT
              , @LegalEntityId          BIGINT
              , @CustomerId             BIGINT
              , @BillingModuleId        INT
              , @InvoiceRemainingAmount DECIMAL(18, 2)
              , @InvoiceGrandTotal      DECIMAL(18, 2);

        SELECT
            @ManagementStructureId  = bi.ManagementStructureId,
            @CustomerId             = bi.CustomerId,
            @LegalEntityId          = ms.LegalEntityId,
            @BillingModuleId        = bi.ModuleId,
            @InvoiceRemainingAmount = ISNULL(bi.RemainingAmount, bi.GrandTotal),
            @InvoiceGrandTotal      = ISNULL(bi.GrandTotal, 0)
        FROM   dbo.BillingInvoicing    bi WITH (NOLOCK)
        JOIN   dbo.ManagementStructure ms WITH (NOLOCK)
               ON  ms.ManagementStructureId = bi.ManagementStructureId
        WHERE  bi.BillingInvoicingId = @BillingInvoicingId;

        --IF @ManagementStructureId IS NULL
        --BEGIN
        --    ROLLBACK TRANSACTION;
        --    RAISERROR('BillingInvoicingId %d not found.', 16, 1, @BillingInvoicingId);
        --    RETURN 1;
        --END

        ---- ── 2. Generate ReceiptNo from CodePrefixes (CodeTypeId = 41 = CR) ──
        ----      Mirrors PASCommon.GenerateCodeNumber(currentNo, CodePrefix, CodeSufix)
        --DECLARE @CodePrefixId BIGINT
        --      , @CodePrefix   NVARCHAR(50)
        --      , @CodeSufix    NVARCHAR(50)
        --      , @CurrentNo    BIGINT
        --      , @StartsFrom   BIGINT
        --      , @ReceiptNo    NVARCHAR(100);

        --SELECT
        --    @CodePrefixId = CodePrefixId,
        --    @CodePrefix   = ISNULL(CodePrefix, ''),
        --    @CodeSufix    = ISNULL(CodeSufix, ''),
        --    @CurrentNo    = ISNULL(CurrentNummber, 0),
        --    @StartsFrom   = ISNULL(StartsFrom, 0)
        --FROM   dbo.CodePrefixes WITH (UPDLOCK)  -- row lock prevents concurrent duplicate numbers
        --WHERE  CodePrefix      = 'cR'             -- CodePrefixEnum.CR
        --  AND  MasterCompanyId = @MasterCompanyId
        --  AND  IsActive        = 1
        --  AND  IsDeleted       = 0;

        --SET @CurrentNo = CASE WHEN @CurrentNo <> 0
        --                      THEN @CurrentNo + 1
        --                      ELSE @StartsFrom + 1
        --                 END;

        --SET @ReceiptNo = @CodePrefix
        --               + RIGHT(REPLICATE('0', 6) + CAST(@CurrentNo AS VARCHAR(20)), 6)
        --               + @CodeSufix;

        --UPDATE dbo.CodePrefixes
        --SET    CurrentNummber = @CurrentNo
        --WHERE  CodePrefixId   = @CodePrefixId;

        ---- ── 3. Insert CustomerPayments receipt ────────────────────────
        ----      AmtApplied / AmtRemaining start at 0 / Amount.
        ----      UpdatePaymentPrice (step 7) will correct them from
        ----      CustomerPaymentDetails.Amount.
        --DECLARE @NewReceiptId BIGINT;

        --INSERT INTO dbo.CustomerPayments
        --(
        --    ReceiptNo,    DepositDate,
        --    Amount,       AmtApplied,  AmtRemaining,
        --    Reference,    ManagementStructureId,  LegalEntityId,
        --    OpenDate,     StatusId,    PostedDate,
        --    EmployeeId,   Memo,
        --    MasterCompanyId, CreatedBy,  CreatedDate,
        --    UpdatedBy,    UpdatedDate, IsActive,  IsDeleted
        --)
        --VALUES
        --(
        --    @ReceiptNo,   @PaymentDate,
        --    @Amount,      0,           @Amount,
        --    @Reference,   @ManagementStructureId, @LegalEntityId,
        --    GETUTCDATE(), @PostedStatusId,           GETUTCDATE(),   -- StatusId = 2 (Posted)
        --    2,            'Imported from Xero',
        --    @MasterCompanyId, @CreatedBy, GETUTCDATE(),
        --    @CreatedBy,   GETUTCDATE(), 1,        0
        --);

        --SET @NewReceiptId = SCOPE_IDENTITY();

        ---- ── 4. Insert CustomerPaymentDetails ─────────────────────────
        ----      QuickBooksReferenceId = Xero Payment GUID.
        ----      UpdatePaymentPrice sums CustomerPaymentDetails.Amount
        ----      to compute CustomerPayments.AmtApplied, so Amount must
        ----      be set correctly here.
        --DECLARE @NewDetailsId BIGINT;

        --INSERT INTO dbo.CustomerPaymentDetails
        --(
        --    ReceiptId,    CustomerId,   LegalEntityId,
        --    Amount,       AmountRem,    AppliedAmount,  InvoiceAmount,
        --    IsMultiplePaymentMethod,    PaymentMode,
        --    QuickBooksReferenceId,      IntegrationTypeId,
        --    IsUpdated,    LastSyncDate, SyncToken,
        --    MasterCompanyId, CreatedBy, CreatedDate,
        --    UpdatedBy,    UpdatedDate, IsActive,  IsDeleted
        --)
        --VALUES
        --(
        --    @NewReceiptId, @CustomerId, @LegalEntityId,
        --    @Amount,       0,          @Amount,        @Amount,
        --    0,             1,                          -- PaymentMode 1 = default
        --    @XeroPaymentId, @XeroIntegrationTypeId,
        --    0,             GETUTCDATE(), NULL,
        --    @MasterCompanyId, @CreatedBy, GETUTCDATE(),
        --    @CreatedBy,    GETUTCDATE(), 1,        0
        --);

        --SET @NewDetailsId = SCOPE_IDENTITY();

        ---- ── 5. Insert InvoicePayments ─────────────────────────────────
        ----      RemainingAmount = invoice balance AFTER this payment
        ----      (mirrors SaveAndPostPayments: inv.RemainingAmount -= paymentAmount)
        --INSERT INTO dbo.InvoicePayments
        --(
        --    CustomerId,  SOBillingInvoicingId,  ReceiptId,
        --    PaymentAmount, OriginalAmount,
        --    RemainingAmount,                    -- remaining AFTER payment
        --    IsMultiplePaymentMethod, InvoiceType,
        --    CustomerPaymentDetailsId,
        --    MasterCompanyId, CreatedBy,  CreatedDate,
        --    UpdatedBy,   UpdatedDate,    IsActive, IsDeleted
        --)
        --VALUES
        --(
        --    @CustomerId,  @BillingInvoicingId,  @NewReceiptId,
        --    @Amount,      @InvoiceGrandTotal,
        --    @InvoiceRemainingAmount - @Amount,  -- post-payment remaining
        --    0,            @BillingModuleId,
        --    @NewDetailsId,
        --    @MasterCompanyId, @CreatedBy, GETUTCDATE(),
        --    @CreatedBy,   GETUTCDATE(),  1,     0
        --);

        ---- ── 6. Reduce BillingInvoicing.RemainingAmount ───────────────
        ----      Opr = 1 deducts (@PaymentAmount + disc + fee + other).
        ----      Disc/fee/other all 0 for a straight Xero payment.
        EXEC dbo.USP_UpdateBillingPayments
             @BillingInvoicingId = @BillingInvoicingId,
             @PaymentAmount      = @Amount,
             @DiscAmount         = 0,
             @BankFeeAmount      = 0,
             @OtherAdjustAmt     = 0,
             @OriginalAmount     = 0,
             @ModuleId           = @BillingModuleId,
             @Opr                = 1;

        ---- ── 7. Recalculate CustomerPayments.AmtApplied / AmtRemaining ─
        ----      Reads SUM(CustomerPaymentDetails.Amount) WHERE ReceiptId = @NewReceiptId
        ----      and sets AmtApplied / AmtRemaining on CustomerPayments.
        ----      NOTE: use @ReceiptId (actual param name), not @p0 (EF alias).
        --EXEC dbo.UpdatePaymentPrice
        --     @ReceiptId = @NewReceiptId;

        COMMIT TRANSACTION;
        RETURN 0;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID           INT
              , @DatabaseName         VARCHAR(100) = DB_NAME()
              , @AdhocComments        VARCHAR(150)  = 'USP_SaveXeroInboundPayment'
              , @ProcedureParameters  VARCHAR(3000) =
                    '@BillingInvoicingId = ' + CAST(ISNULL(@BillingInvoicingId, 0) AS VARCHAR)
                  + ', @XeroPaymentId = '   + ISNULL(@XeroPaymentId, '')
                  + ', @Amount = '          + CAST(ISNULL(@Amount, 0) AS VARCHAR)
              , @ApplicationName      VARCHAR(100) = 'PAS';

        EXEC spLogException
             @DatabaseName        = @DatabaseName
           , @AdhocComments       = @AdhocComments
           , @ProcedureParameters = @ProcedureParameters
           , @ApplicationName     = @ApplicationName
           , @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN 1;

    END CATCH
END