/*************************************************************
 ** File:   [USP_ReOpenLeaseBillingInvoice]
 ** Description: Void-and-recreate "Re-Open" for a Lease Billing Invoicing record (the "Create Invoice"
 **              flow's sibling undo action). Unlike USP_ReOpenSalesOrderInvoice, which only resets the
 **              invoice header back to a draft status (Sales Order invoices have a separate draft-then-post
 **              lifecycle with their own line-item edit screen), Lease invoices are built in one shot by
 **              USP_CreateLeaseBillingInvoice with no separate draft stage, so there is nothing to "edit in
 **              place". This procedure instead:
 **                1. Un-invoices every LeaseStocklineUsageHistory row and LeaseCharges row that were billed
 **                   onto this invoice (IsInvoiced = 0, BillingInvoicingItemId = NULL) - they become Pending
 **                   again on the Billing/Invoicing grid.
 **                2. Resets LeaseStockline.IsInvoicePost = 0 for every stockline on this invoice, so
 **                   Maintenance/Insurance/Taxes/Other Component (still bill-once-ever) become billable again.
 **                3. Soft-deletes every LeaseBillingInvoicingItemDetails row (now multiple rows per
 **                   BillingInvoicingItemId - one per LineType per period, not a single wide row) and the
 **                   BillingInvoicingItems line items themselves (both keep their own Audit-table history).
 **                4. Marks the BillingInvoicing header InvoiceStatus = 'Voided' (kept visible/IsActive = 1 for
 **                   audit trail - just excluded from the Invoiced tab because its line items are now
 **                   IsDeleted = 1), IsInvoicePosted = 0, PostedDate = NULL, IsReOpened = 1.
 **              The user then clicks Create Invoice again on the same stockline(s), which produces one
 **              fresh invoice number correctly covering the original usage together with anything added
 **              since - no in-place line editing needed.
 **
 **              Restricted to the Leasing module only, and refuses an invoice that is already Voided.
 **
 **              NOTE: unlike the Sales Order version, this does NOT check for payments or Credit Memos, and
 **              does NOT reverse any GL/accounting entry - there is currently no payment, Credit Memo, or
 **              accounting-posting integration wired up for the Leasing module at all. If any of that is
 **              added for Lease in future, this procedure will need the same guards USP_ReOpenSalesOrderInvoice
 **              has before it can safely void an invoice that's already been paid against or posted to the GL.
 **
 ** Purpose:  PAS - [PN-18072 invoice-detail follow-up] Re-Open (Void) a Lease Billing Invoice
 ** Date:    01/10/2026
 **************************
 ** Change History
 **************************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				-------------------------------
    1    01/10/2026   Kishor Makwana		Created
    2    02/10/2026   Kishor Makwana		Rebuilt against the per-LineType/per-period
                                        LeaseBillingInvoicingItemDetails grain (PN-18072
                                        invoice-detail follow-up) - every row for the
                                        voided invoice is now soft-deleted, not just one.

    EXEC [dbo].[USP_ReOpenLeaseBillingInvoice] @BillingInvoicingId = 8998, @UpdatedBy = 'ADMIN User'

**********************/
CREATE Or ALTER PROCEDURE [dbo].[USP_ReOpenLeaseBillingInvoice]
	@BillingInvoicingId BIGINT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @LeaseModuleId INT
		SELECT @LeaseModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'Leasing'

		DECLARE @ModuleId INT, @InvoiceStatus VARCHAR(50)
		SELECT	@ModuleId = [ModuleId],
				@InvoiceStatus = [InvoiceStatus]
		FROM [dbo].[BillingInvoicing] WITH (NOLOCK)
		WHERE [BillingInvoicingId] = @BillingInvoicingId

		IF (@ModuleId IS NULL)
		BEGIN
			SELECT 0 AS IsSuccess, 'Invoice does not exist.' AS Message
			RETURN
		END

		IF (@ModuleId <> ISNULL(@LeaseModuleId, -1))
		BEGIN
			SELECT 0 AS IsSuccess, 'Re-Open is only supported for Lease invoices.' AS Message
			RETURN
		END

		IF (ISNULL(@InvoiceStatus, '') = 'Voided')
		BEGIN
			SELECT 0 AS IsSuccess, 'This invoice has already been Voided.' AS Message
			RETURN
		END

		BEGIN TRANSACTION

		DECLARE @ItemIds TABLE (BillingInvoicingItemId BIGINT PRIMARY KEY);
		INSERT INTO @ItemIds (BillingInvoicingItemId)
		SELECT BillingInvoicingItemId
		FROM [dbo].[BillingInvoicingItems] WITH (NOLOCK)
		WHERE BillingInvoicingId = @BillingInvoicingId AND IsDeleted = 0 AND ISNULL(IsVersionIncrease, 0) = 0;

		IF NOT EXISTS (SELECT 1 FROM @ItemIds)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 0 AS IsSuccess, 'This invoice has no active line items to Re-Open.' AS Message
			RETURN
		END

		-- 1a. Un-invoice usage history rows billed onto this invoice
		UPDATE H
			SET H.IsInvoiced = 0,
				H.BillingInvoicingItemId = NULL,
				H.UpdatedBy = @UpdatedBy,
				H.UpdatedDate = SYSUTCDATETIME()
		FROM [dbo].[LeaseStocklineUsageHistory] H
		INNER JOIN @ItemIds II ON II.BillingInvoicingItemId = H.BillingInvoicingItemId;

		-- 1b. Un-invoice Charges billed onto this invoice
		UPDATE LC
			SET LC.IsInvoiced = 0,
				LC.BillingInvoicingItemId = NULL,
				LC.UpdatedBy = @UpdatedBy,
				LC.UpdatedDate = SYSUTCDATETIME()
		FROM [dbo].[LeaseCharges] LC
		INNER JOIN @ItemIds II ON II.BillingInvoicingItemId = LC.BillingInvoicingItemId;

		-- 2. Reset the whole-stockline switch so Maintenance/Insurance/Taxes/Other Component (still
		--    bill-once-ever, unchanged by this or any recent fix) become billable again too.
		UPDATE LSL
			SET LSL.IsInvoicePost = 0,
				LSL.UpdatedBy = @UpdatedBy,
				LSL.UpdatedDate = GETUTCDATE()
		FROM [dbo].[LeaseStockline] LSL
		INNER JOIN [dbo].[BillingInvoicingItems] BII WITH (NOLOCK) ON BII.SubReferenceId = LSL.LeaseStocklineId
		INNER JOIN @ItemIds II ON II.BillingInvoicingItemId = BII.BillingInvoicingItemId;

		-- 3. Soft-delete every frozen snapshot row for these items (one per LineType per period now,
		--    not a single wide row) and the line items themselves - both keep full history in their
		--    own Audit tables, same as every other IsDeleted-gated table in this schema.
		UPDATE LBID
			SET LBID.IsDeleted = 1,
				LBID.IsActive = 0,
				LBID.UpdatedBy = @UpdatedBy,
				LBID.UpdatedDate = SYSUTCDATETIME()
		FROM [dbo].[LeaseBillingInvoicingItemDetails] LBID
		INNER JOIN @ItemIds II ON II.BillingInvoicingItemId = LBID.BillingInvoicingItemId;

		UPDATE BII
			SET BII.IsDeleted = 1,
				BII.IsActive = 0,
				BII.UpdatedBy = @UpdatedBy,
				BII.UpdatedDate = SYSUTCDATETIME()
		FROM [dbo].[BillingInvoicingItems] BII
		INNER JOIN @ItemIds II ON II.BillingInvoicingItemId = BII.BillingInvoicingItemId;

		-- 4. Void the header. Kept visible (IsActive untouched, stays 1) for audit trail - it disappears from
		--    the Billing/Invoicing grid's Invoiced tab purely because that tab's InvoicedLines CTE already
		--    requires BII.IsDeleted = 0 / LBID.IsDeleted = 0, both just set above.
		UPDATE [dbo].[BillingInvoicing]
			SET	InvoiceStatus = 'Voided',
				IsInvoicePosted = 0,
				PostedDate = NULL,
				IsReOpened = 1,
				UpdatedBy = @UpdatedBy,
				UpdatedDate = GETUTCDATE()
		WHERE BillingInvoicingId = @BillingInvoicingId;

		COMMIT TRANSACTION;

		SELECT 1 AS IsSuccess,
			'Invoice Voided. Every usage period, Charge, and (if nothing else on the stockline is still outstanding) Maintenance/Insurance/Taxes/Other Component are billable again - use Create Invoice to generate a corrected invoice.' AS Message;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_ReOpenLeaseBillingInvoice]',
            @ProcedureParameters varchar(3000) = '@BillingInvoicingId = ''' + CAST(ISNULL(@BillingInvoicingId, 0) AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
	END CATCH
END
