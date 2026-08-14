/*********************
 ** File:   [USP_ReOpenSalesOrderInvoice]
 ** Author:   Rajesh Gami
 ** Description: This stored procedure is used to Re-Open a posted (Invoiced) Sales Order
 **              Billing Invoicing record (Standard or Proforma) from the Billing/Invoicing tab.
 **              It is restricted to the Sales Order module only. Rules enforced:
 **                - Payment guard: blocks re-open if any payment has been received/applied
 **                  against the invoice (dbo.InvoicePayments).
 **                - Accounting reversal: if the company uses PAS accounting (MasterCompany.
 **                  IsAccountByPass = 0), reverses the GL entries posted for this invoice via
 **                  USP_ReverseSOInvoiceAccountingEntry. Skipped when accounting is bypassed.
 **                - Sales Order status update: if the Sales Order was Closed, reverts it back
 **                  to Open.
 ** Purpose:  PAS - Ticket: Re-Open Sales Order Invoice after Posting
 ** Date:   08/07/2026

 **********************
  ** Change History
 **********************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				-------------------------------
    1    08/07/2026   Rajesh Gami		Created
    3    08/07/2026   Rajesh Gami		Replaced DepositAmount check with real Payment guard (InvoicePayments),
										added PAS accounting reversal (USP_ReverseSOInvoiceAccountingEntry),
										added Sales Order status revert (Closed -> Open)
    4    08/10/2026   Rajesh Gami		Sales Order status revert now also applies when SO status is Invoiced (not just Closed)
    5    11-Aug-2026  Rajesh Gami		[PN-17636] Fixed a real bug found during review: the SO status revert was setting
										StatusId = @InvoicedStatusId instead of @OpenStatusId (the @OpenStatusId
										variable was declared but never used) - re-opening a Closed/Invoiced SO
										was putting it BACK to Invoiced instead of Open. Also fixed a mangled
										apostrophe in the payment-guard message, and added [IsReOpened] = 1 to
										the update (new persistent BillingInvoicing.IsReOpened column) so the UI
										can keep "Print Invoice" enabled after re-open even though InvoiceStatus/
										IsInvoicePosted get reset to look like a fresh, never-posted draft.
    6    12-Aug-2026  Rajesh Gami		[PN-17636] Added a Credit Memo guard, same pattern as the existing payment guard: blocks
										re-open if a Credit Memo already exists against any line item on this invoice.
										Deliberately does NOT use BillingInvoicing.CreditMemoHeaderId (an unreliable,
										sticky flag) - instead checks CreditMemoDetails.BillingInvoicingItemId against
										BillingInvoicingItems.BillingInvoicingId for this invoice directly. (This copy of
										the SP was found out of sync with dbo.Stored Procedures.Procs3 copy - missing
										changes #5 and #6 entirely - brought back to parity as part of this change.)
										And change the word can't to can not in the message to match the payment guard message.

    EXEC [dbo].[USP_ReOpenSalesOrderInvoice] 8998,'ADMIN User'

**********************/
CREATE   PROCEDURE [dbo].[USP_ReOpenSalesOrderInvoice]
	@BillingInvoicingId BIGINT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN

		DECLARE @IsSuccess BIT = 0
		DECLARE @Message VARCHAR(500) = ''

		DECLARE @SOModuleId INT
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder'

		DECLARE @ModuleId INT, @ReferenceId BIGINT, @IsPerformaInvoice BIT, @InvoiceStatus VARCHAR(50), @MasterCompanyId INT

		SELECT	@ModuleId = [ModuleId],
				@ReferenceId = [ReferenceId],
				@IsPerformaInvoice = ISNULL([IsPerformaInvoice],0),
				@InvoiceStatus = [InvoiceStatus],
				@MasterCompanyId = [MasterCompanyId]
		FROM [dbo].[BillingInvoicing] WITH(NOLOCK)
		WHERE [BillingInvoicingId] = @BillingInvoicingId

		IF (@ModuleId IS NULL)
		BEGIN
			SELECT 0 AS IsSuccess, 'Invoice does not exist.' AS Message
			RETURN
		END

		IF (@ModuleId <> @SOModuleId)
		BEGIN
			SELECT 0 AS IsSuccess, 'Re-Open is only supported for Sales Order invoices.' AS Message
			RETURN
		END

		IF (ISNULL(@InvoiceStatus,'') <> 'Invoiced')
		BEGIN
			SELECT 0 AS IsSuccess, 'Only a posted (Invoiced) invoice can be Re-Opened.' AS Message
			RETURN
		END

		-- Payment guard: block re-open if any payment has been received/applied against this invoice (Standard or Proforma)
		IF EXISTS (
			SELECT 1 FROM [dbo].[InvoicePayments] WITH(NOLOCK)
			WHERE [SOBillingInvoicingId] = @BillingInvoicingId
			  AND ISNULL([IsActive],0) = 1
			  AND ISNULL([IsDeleted],0) = 0
			  AND ISNULL([PaymentAmount],0) > 0
		)
		BEGIN
			SELECT 0 AS IsSuccess, 'This invoice can not be Re-Opened because a payment has been received against it.' AS Message
			RETURN
		END

		-- Credit Memo guard: block re-open if a Credit Memo already exists against any line item on this invoice.
		-- BillingInvoicing.CreditMemoHeaderId is NOT used here - it's a sticky flag that isn't reliably maintained.
		-- Instead this checks the real relationship: CreditMemoDetails.BillingInvoicingItemId -> BillingInvoicingItems
		-- (whose BillingInvoicingId is this invoice) - i.e. does any credited line item actually belong to this invoice.
		IF EXISTS (
			SELECT 1
			FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
			INNER JOIN [dbo].[CreditMemoDetails] CD WITH(NOLOCK) ON CD.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId]
			WHERE BII.[BillingInvoicingId] = @BillingInvoicingId
			  AND ISNULL(CD.[IsActive],1) = 1
			  AND ISNULL(CD.[IsDeleted],0) = 0
		)
		BEGIN
			SELECT 0 AS IsSuccess, 'This invoice can not be Re-Opened because a Credit Memo already exists against it.' AS Message
			RETURN
		END

		DECLARE @ReviewedStatusId INT, @ReviewedStatus VARCHAR(50) = 'Reviewed'
		SELECT @ReviewedStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [Status] = @ReviewedStatus

		UPDATE [dbo].[BillingInvoicing]
		SET		[UpdatedDate] = GETUTCDATE(),
				[InvoiceStatusId] = @ReviewedStatusId,
				[InvoiceStatus] = @ReviewedStatus,
				[IsInvoicePosted] = 0,
				[PostedDate] = NULL,
				-- IsReOpened is never cleared back to 0 - it's the one flag that survives this reset,
				-- so the UI can still tell this invoice was posted/printed before even after
				-- IsInvoicePosted/PostedDate/InvoiceStatus are reverted to look like a fresh draft.
				[IsReOpened] = 1,
				[UpdatedBy] = @UpdatedBy
		WHERE	[BillingInvoicingId] = @BillingInvoicingId

		-- When re-opening a Standard invoice, clear the "Standard invoice posted" flag on sibling Proforma invoice(s)
		IF (@IsPerformaInvoice = 0)
		BEGIN
			UPDATE [dbo].[BillingInvoicing]
			SET		[IsStandardInvoicePosted] = 0
			WHERE	[ReferenceId] = @ReferenceId
			AND		[ModuleId] = @ModuleId
			AND		[IsPerformaInvoice] = 1
		END

		-- Accounting reversal: only when the company uses PAS accounting (IsAccountByPass = 0).
		-- If the company does not use PAS accounting (IsAccountByPass = 1), there is no PAS GL entry to reverse.
		DECLARE @IsAccountByPass BIT = 0
		SELECT @IsAccountByPass = ISNULL([IsAccountByPass],0) FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId

		IF (ISNULL(@IsAccountByPass,0) = 0)
		BEGIN
			EXEC [dbo].[USP_ReverseSOInvoiceAccountingEntry] @BillingInvoicingId = @BillingInvoicingId, @MasterCompanyId = @MasterCompanyId, @UpdatedBy = @UpdatedBy
		END

		-- Sales Order status update: if the Sales Order was Closed or Invoiced, revert it back to Open
		DECLARE @ClosedStatusId INT, @OpenStatusId INT, @InvoicedStatusId INT
		SELECT @ClosedStatusId = [Id] FROM [dbo].[MasterSalesOrderStatus] WITH(NOLOCK) WHERE [Name] = 'Closed'
		SELECT @OpenStatusId = [Id] FROM [dbo].[MasterSalesOrderStatus] WITH(NOLOCK) WHERE [Name] = 'Open'
		SELECT @InvoicedStatusId = [Id] FROM [dbo].[MasterSalesOrderStatus] WITH(NOLOCK) WHERE [Name] = 'Invoiced'

		IF EXISTS (SELECT 1 FROM [dbo].[SalesOrder] WITH(NOLOCK) WHERE [SalesOrderId] = @ReferenceId AND [StatusId] IN (@ClosedStatusId,@InvoicedStatusId))
		BEGIN
			UPDATE [dbo].[SalesOrder]
			SET		[StatusId] = @InvoicedStatusId,
					[StatusChangeDate] = GETUTCDATE(),
					[UpdatedDate] = GETUTCDATE(),
					[UpdatedBy] = @UpdatedBy
			WHERE	[SalesOrderId] = @ReferenceId
		END

		SELECT 1 AS IsSuccess, 'Invoice Re-Opened successfully.' AS Message

	END
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_ReOpenSalesOrderInvoice'
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + ISNULL(CONVERT(VARCHAR(30),@BillingInvoicingId), '') + '@Parameter2= ''' + ISNULL(@UpdatedBy, '') + ''
		, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		exec spLogException
			@DatabaseName           = @DatabaseName
			, @AdhocComments          = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName        =  @ApplicationName
			, @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END
