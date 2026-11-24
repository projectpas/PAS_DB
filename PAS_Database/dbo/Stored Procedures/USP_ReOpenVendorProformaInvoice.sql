/*********************
 ** File:   [USP_ReOpenVendorProformaInvoice]
 ** Author:   Moin Bloch
 ** Description: Re-Opens a Posted Vendor Proforma Invoice (single transaction):
 **                - Only a Posted invoice can be Re-Opened.
 **                - Payment guard: blocked when payment has been initialized (selected in Ready To Pay /
 **                  check / payment made against the invoice).
 **                - Accounting reversal via USP_ReverseVendorProformaInvoiceAccountingEntry (PAS accounting only).
 **                - Removes the invoice from Vendor Payment (soft-deletes its VendorPaymentDetails row);
 **                  re-posting creates a fresh row via USP_AddVendorPaymentDetailsForVendorProformaById.
 **                - Header status set back to Open so the Item List can be changed and posted again;
 **                  history is kept by Trg_VendorProformaInvoiceHeaderAudit.
 ** Purpose:  Vendor Proforma Invoice - Re-Open Posted Invoice
 ** Date:   19-Nov-2026

 **********************
  ** Change History
 **********************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				-------------------------------
    1    19-Nov-2026  Moin Bloch			Created

    EXEC [dbo].[USP_ReOpenVendorProformaInvoice] 47, 'ADMIN User'
**********************/
CREATE   PROCEDURE [dbo].[USP_ReOpenVendorProformaInvoice]
	@VendorProformaInvoiceId BIGINT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @IsSuccess BIT = 0, @Message VARCHAR(500) = ''
		DECLARE @StatusId INT, @MasterCompanyId INT, @PostedStatusId INT, @IsAccountByPass BIT = 0

		SELECT @PostedStatusId = [VendorProformaInvoiceHeaderStatusId] FROM [dbo].[VendorProformaInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Posted'

		-- UPDLOCK: serializes concurrent Re-Open clicks on the same invoice
		SELECT @StatusId = [StatusId], @MasterCompanyId = [MasterCompanyId]
		FROM [dbo].[VendorProformaInvoiceHeader] WITH(UPDLOCK, ROWLOCK)
		WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId

		IF (@StatusId IS NULL)
			SET @Message = 'Vendor Proforma Invoice does not exist.'
		ELSE IF (@StatusId <> @PostedStatusId)
			SET @Message = 'Only a Posted Vendor Proforma Invoice can be Re-Opened.'
		ELSE IF EXISTS (SELECT 1 FROM [dbo].[VendorReadyToPayDetails] WITH(NOLOCK)
						WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId AND ISNULL([IsDeleted], 0) = 0 AND ISNULL([IsVoidedCheck], 0) = 0)
			 OR EXISTS (SELECT 1 FROM [dbo].[VendorPaymentDetails] WITH(NOLOCK)
						WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId AND ISNULL([IsDeleted], 0) = 0 AND ISNULL([PaymentMade], 0) > 0)
			SET @Message = 'This Vendor Proforma Invoice cannot be reopened because payment has already been initialized.'
		ELSE
		BEGIN
			-- Accounting reversal (only when the company uses PAS accounting)
			SELECT @IsAccountByPass = ISNULL([IsAccountByPass], 0) FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId

			IF (@IsAccountByPass = 0)
				EXEC [dbo].[USP_ReverseVendorProformaInvoiceAccountingEntry] @VendorProformaInvoiceId = @VendorProformaInvoiceId, @MasterCompanyId = @MasterCompanyId, @UpdatedBy = @UpdatedBy

			-- Remove from Vendor Payment
			UPDATE [dbo].[VendorPaymentDetails]
			SET [IsActive] = 0, [IsDeleted] = 1, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId AND ISNULL([IsDeleted], 0) = 0

			-- Back to Open so the user can change the Item List and post again (same start point as a new invoice)
			UPDATE [dbo].[VendorProformaInvoiceHeader]
			SET [StatusId] = (SELECT [VendorProformaInvoiceHeaderStatusId] FROM [dbo].[VendorProformaInvoiceHeaderStatus] WITH(NOLOCK) WHERE [Description] = 'Open'),
				[PostedDate] = NULL, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId

			SET @IsSuccess = 1
			SET @Message = 'Vendor Proforma Invoice Re-Opened successfully.'
		END
	END
	COMMIT TRANSACTION

	SELECT @IsSuccess AS IsSuccess, @Message AS Message
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_ReOpenVendorProformaInvoice'
		, @ProcedureParameters VARCHAR(3000)  = '@VendorProformaInvoiceId = ''' + ISNULL(CONVERT(VARCHAR(30), @VendorProformaInvoiceId), '') + ''', @UpdatedBy = ''' + ISNULL(@UpdatedBy, '') + ''''
		, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			@DatabaseName           = @DatabaseName
			, @AdhocComments          = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName        =  @ApplicationName
			, @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END
