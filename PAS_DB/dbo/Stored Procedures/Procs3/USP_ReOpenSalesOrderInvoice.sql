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

    EXEC [dbo].[USP_ReOpenSalesOrderInvoice] 8998,'ADMIN User'

**********************/
CREATE PROCEDURE [dbo].[USP_ReOpenSalesOrderInvoice]
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
			SELECT 0 AS IsSuccess, 'This invoice can’t be Re-Opened because a payment has been received against it.' AS Message
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
