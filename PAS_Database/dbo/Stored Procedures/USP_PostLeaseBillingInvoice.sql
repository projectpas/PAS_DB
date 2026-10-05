/*************************************************************
 ** File:   [USP_PostLeaseBillingInvoice]
 ** Description: Posts a lease billing invoice that was previously GENERATED (saved) by
 **              USP_CreateLeaseBillingInvoice. Save only creates a draft; this is the separate
 **              "Post Invoice" action (Lease Invoice preview/print screen). Once posted the invoice is final -
 **              any further billing always creates a NEW invoice.
 **
 **              1. Validates the invoice is a Leasing invoice that is not deleted, not Voided and not yet posted.
 **              2. BillingInvoicing: IsInvoicePosted = 1, PostedDate, InvoiceStatus = 'Invoiced'.
 **              3. Sets the post flags on exactly the rows the invoice covers (linked at Save through
 **                 BillingInvoicingItemId): LeaseStocklineUsageHistory.IsInvoiced = 1, LeaseCharges.IsInvoiced = 1.
 **              4. LeaseStockline.IsInvoicePost = 1 for the stocklines on the invoice (one-time lines are billed once).
 **
 **              Usage / charges added after the invoice was saved are not linked to it, so they stay Pending and
 **              go to the next invoice.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    05/10/2026     Kishor Makwana          [PN-18072 Save vs Post] Created

EXEC USP_PostLeaseBillingInvoice @BillingInvoicingId = 1, @UpdatedBy = 'test'
************************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[USP_PostLeaseBillingInvoice]
	@BillingInvoicingId BIGINT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @LeaseModuleId INT, @InvoiceModuleId INT, @IsPosted BIT, @InvoiceStatus VARCHAR(50), @IsDeleted BIT;

		SELECT TOP 1 @LeaseModuleId = ModuleId FROM [dbo].[Module] WITH (NOLOCK) WHERE ModuleName = 'Leasing';

		SELECT
			@InvoiceModuleId = ModuleId,
			@IsPosted = ISNULL(IsInvoicePosted, 0),
			@InvoiceStatus = InvoiceStatus,
			@IsDeleted = IsDeleted
		FROM [dbo].[BillingInvoicing] WITH (NOLOCK)
		WHERE BillingInvoicingId = @BillingInvoicingId;

		IF (@InvoiceModuleId IS NULL OR @InvoiceModuleId <> @LeaseModuleId OR ISNULL(@IsDeleted, 0) = 1)
		BEGIN
			RAISERROR('The lease billing invoice was not found.', 16, 1);
			RETURN (1);
		END

		IF (ISNULL(@InvoiceStatus, '') = 'Voided')
		BEGIN
			RAISERROR('A voided lease billing invoice cannot be posted.', 16, 1);
			RETURN (1);
		END

		IF (@IsPosted = 1)
		BEGIN
			RAISERROR('This lease billing invoice has already been posted.', 16, 1);
			RETURN (1);
		END

		DECLARE @PostedStatus VARCHAR(50) = 'Invoiced', @PostedStatusId INT;
		SELECT TOP 1 @PostedStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH (NOLOCK) WHERE [Status] = @PostedStatus;

		BEGIN TRANSACTION

		UPDATE [dbo].[BillingInvoicing]
			SET IsInvoicePosted = 1,
				PostedDate = GETUTCDATE(),
				InvoiceStatusId = @PostedStatusId,
				InvoiceStatus = @PostedStatus,
				UpdatedBy = @UpdatedBy,
				UpdatedDate = GETUTCDATE()
		WHERE BillingInvoicingId = @BillingInvoicingId;

		UPDATE H
			SET H.IsInvoiced = 1,
				H.UpdatedBy = @UpdatedBy,
				H.UpdatedDate = SYSUTCDATETIME()
		FROM [dbo].[LeaseStocklineUsageHistory] H
		INNER JOIN [dbo].[BillingInvoicingItems] BII WITH (NOLOCK) ON BII.BillingInvoicingItemId = H.BillingInvoicingItemId
		WHERE BII.BillingInvoicingId = @BillingInvoicingId AND BII.IsDeleted = 0 AND ISNULL(BII.IsVersionIncrease, 0) = 0
		  AND H.IsInvoiced = 0 AND H.IsActive = 1 AND H.IsDeleted = 0;

		UPDATE LC
			SET LC.IsInvoiced = 1,
				LC.UpdatedBy = @UpdatedBy,
				LC.UpdatedDate = SYSUTCDATETIME()
		FROM [dbo].[LeaseCharges] LC
		INNER JOIN [dbo].[BillingInvoicingItems] BII WITH (NOLOCK) ON BII.BillingInvoicingItemId = LC.BillingInvoicingItemId
		WHERE BII.BillingInvoicingId = @BillingInvoicingId AND BII.IsDeleted = 0 AND ISNULL(BII.IsVersionIncrease, 0) = 0
		  AND LC.IsInvoiced = 0 AND LC.IsDeleted = 0;

		UPDATE LSL
			SET LSL.IsInvoicePost = 1,
				LSL.UpdatedBy = @UpdatedBy,
				LSL.UpdatedDate = GETUTCDATE()
		FROM [dbo].[LeaseStockline] LSL
		INNER JOIN [dbo].[BillingInvoicingItems] BII WITH (NOLOCK) ON BII.SubReferenceId = LSL.LeaseStocklineId
		WHERE BII.BillingInvoicingId = @BillingInvoicingId AND BII.IsDeleted = 0 AND ISNULL(BII.IsVersionIncrease, 0) = 0
		  AND LSL.IsInvoicePost = 0;

		COMMIT TRANSACTION;

		SELECT BillingInvoicingId, InvoiceNo, InvoiceDate, GrandTotal FROM [dbo].[BillingInvoicing] WHERE BillingInvoicingId = @BillingInvoicingId;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_PostLeaseBillingInvoice]',
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
