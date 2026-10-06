/*************************************************************
 ** File:   [USP_SyncLeaseBillingDraftInvoices]
 ** Description: Keeps OPEN draft Lease invoices (generated but not posted, not voided) in step with the lease.
 **              Invoices are monthly: while a draft exists, usage / charges added later for a calendar month the
 **              draft already covers are merged into that same draft (same BillingInvoicingId / InvoiceNo, old detail
 **              lines replaced by the new ones) instead of showing up as a second Pending invoice. A change to the
 **              stockline's lease terms or service components made after the draft was generated also re-generates it.
 **              Posted invoices are never touched - usage added after Post stays Pending and gets a new invoice.
 **              Re-uses USP_CreateLeaseBillingInvoice (draft absorb, @DraftMonthsOnly = 1) with the draft's own
 **              header / Bill To / Ship To values, so the rebuild logic lives in one place.
 **              Called by the API before the Billing grid is read. Idempotent; a draft that fails to rebuild is left as-is.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    05/10/2026     Kishor Makwana          [PN-18072 draft sync] Created
 ** EXEC USP_SyncLeaseBillingDraftInvoices @LeaseHeaderId = 1, @UpdatedBy = 'ADMIN User'
 **************************************************************/
CREATE PROCEDURE [dbo].[USP_SyncLeaseBillingDraftInvoices]
	@LeaseHeaderId BIGINT,
	@UpdatedBy VARCHAR(256) = 'System'
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @LeaseModuleId INT;
	SELECT TOP 1 @LeaseModuleId = ModuleId FROM [dbo].[Module] WITH (NOLOCK) WHERE ModuleName = 'Leasing';
	IF (@LeaseModuleId IS NULL) RETURN;

	DECLARE @Drafts TABLE (BillingInvoicingId BIGINT PRIMARY KEY);

	INSERT INTO @Drafts (BillingInvoicingId)
	SELECT BI.BillingInvoicingId
	FROM [dbo].[BillingInvoicing] BI WITH (NOLOCK)
	WHERE BI.ModuleId = @LeaseModuleId AND BI.ReferenceId = @LeaseHeaderId
	  AND ISNULL(BI.IsDeleted, 0) = 0
	  AND ISNULL(BI.IsInvoicePosted, 0) = 0
	  AND ISNULL(BI.InvoiceStatus, '') <> 'Voided'
	  AND EXISTS (
		SELECT 1
		FROM [dbo].[BillingInvoicingItems] BX WITH (NOLOCK)
		WHERE BX.BillingInvoicingId = BI.BillingInvoicingId AND BX.IsDeleted = 0 AND ISNULL(BX.IsVersionIncrease, 0) = 0
		  AND (
			-- (a) new, not-yet-billed usage in a month this draft covers
			EXISTS (
				SELECT 1 FROM [dbo].[LeaseStocklineUsageHistory] H WITH (NOLOCK)
				WHERE H.LeaseStocklineId = BX.SubReferenceId AND H.IsActive = 1 AND H.IsDeleted = 0
				  AND ISNULL(H.IsInvoiced, 0) = 0 AND H.BillingInvoicingItemId IS NULL AND H.FromDate IS NOT NULL
				  AND EXISTS (SELECT 1 FROM [dbo].[LeaseBillingInvoicingItemDetails] LX WITH (NOLOCK)
							  WHERE LX.BillingInvoicingItemId = BX.BillingInvoicingItemId AND ISNULL(LX.IsDeleted, 0) = 0 AND ISNULL(LX.IsVersionIncrease, 0) = 0 AND LX.FromDate IS NOT NULL
								AND DATEFROMPARTS(YEAR(LX.FromDate), MONTH(LX.FromDate), 1) = DATEFROMPARTS(YEAR(H.FromDate), MONTH(H.FromDate), 1))
			)
			-- (b) new, not-yet-billed charge reported in a month this draft covers
			OR EXISTS (
				SELECT 1 FROM [dbo].[LeaseCharges] LC WITH (NOLOCK)
				WHERE LC.LeaseStocklineId = BX.SubReferenceId AND LC.IsDeleted = 0
				  AND ISNULL(LC.IsInvoiced, 0) = 0 AND LC.BillingInvoicingItemId IS NULL AND LC.ReportedDate IS NOT NULL
				  AND EXISTS (SELECT 1 FROM [dbo].[LeaseBillingInvoicingItemDetails] LX WITH (NOLOCK)
							  WHERE LX.BillingInvoicingItemId = BX.BillingInvoicingItemId AND ISNULL(LX.IsDeleted, 0) = 0 AND ISNULL(LX.IsVersionIncrease, 0) = 0 AND LX.FromDate IS NOT NULL
								AND DATEFROMPARTS(YEAR(LX.FromDate), MONTH(LX.FromDate), 1) = DATEFROMPARTS(YEAR(LC.ReportedDate), MONTH(LC.ReportedDate), 1))
			)
			-- (c) lease terms / Maintenance / Insurance / Taxes / service components edited after the draft was generated
			OR EXISTS (SELECT 1 FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK) WHERE LSL.LeaseStocklineId = BX.SubReferenceId AND LSL.UpdatedDate > BX.CreatedDate)
			OR EXISTS (SELECT 1 FROM [dbo].[LeaseStocklineServiceComponent] SC WITH (NOLOCK) WHERE SC.LeaseStocklineId = BX.SubReferenceId AND SC.UpdatedDate > BX.CreatedDate)
		  )
	  );

	DECLARE @DraftId BIGINT;
	DECLARE @Ids [dbo].[TVP_BigInt];

	DECLARE @InvoiceTypeId INT, @InvoiceDate DATETIME2(7), @InvoiceTime VARCHAR(10), @PrintDate DATETIME2(7), @ShipDate DATETIME2(7),
			@CurrencyId INT, @EmployeeId BIGINT, @Notes NVARCHAR(MAX), @MasterCompanyId INT,
			@SoldToCustomerId BIGINT, @SoldToSiteId BIGINT, @SoldToAttention VARCHAR(256),
			@ShipToCustomerId BIGINT, @ShipToSiteId BIGINT, @ShipToAttention VARCHAR(256),
			@ShipViaId BIGINT, @ShipAccountInfo VARCHAR(200), @ShippingTermsName VARCHAR(256);

	WHILE EXISTS (SELECT 1 FROM @Drafts)
	BEGIN
		SELECT TOP 1 @DraftId = BillingInvoicingId FROM @Drafts ORDER BY BillingInvoicingId;
		DELETE FROM @Drafts WHERE BillingInvoicingId = @DraftId;

		BEGIN TRY
			DELETE FROM @Ids;
			INSERT INTO @Ids (Value)
			SELECT DISTINCT SubReferenceId FROM [dbo].[BillingInvoicingItems] WITH (NOLOCK)
			WHERE BillingInvoicingId = @DraftId AND IsDeleted = 0 AND ISNULL(IsVersionIncrease, 0) = 0;

			SELECT @InvoiceTypeId = BI.InvoiceTypeId, @InvoiceDate = BI.InvoiceDate, @InvoiceTime = BI.InvoiceTime, @PrintDate = BI.PrintDate,
				   @CurrencyId = BI.CurrencyId, @EmployeeId = BI.EmployeeId, @Notes = BI.Notes, @MasterCompanyId = BI.MasterCompanyId
			FROM [dbo].[BillingInvoicing] BI WITH (NOLOCK) WHERE BI.BillingInvoicingId = @DraftId;

			SELECT @ShipDate = MAX(ShipDate) FROM [dbo].[BillingInvoicingItems] WITH (NOLOCK) WHERE BillingInvoicingId = @DraftId AND IsDeleted = 0 AND ISNULL(IsVersionIncrease, 0) = 0;

			SELECT TOP 1 @SoldToCustomerId = D.SoldToCustomerId, @SoldToSiteId = D.SoldToSiteId, @SoldToAttention = D.SoldToAttention,
				   @ShipToCustomerId = D.ShipToCustomerId, @ShipToSiteId = D.ShipToSiteId, @ShipToAttention = D.ShipToAttention,
				   @ShipViaId = D.ShipviaId, @ShipAccountInfo = D.ShipAccountInfo, @ShippingTermsName = D.ShippingTermsName
			FROM [dbo].[BillingInvoicingDetails] D WITH (NOLOCK) WHERE D.BillingInvoicingId = @DraftId ORDER BY D.BillingInvoicingDetailsId;

			EXEC [dbo].[USP_CreateLeaseBillingInvoice]
				@LeaseHeaderId = @LeaseHeaderId, @LeaseStocklineIds = @Ids,
				@InvoiceTypeId = @InvoiceTypeId, @InvoiceDate = @InvoiceDate, @InvoiceTime = @InvoiceTime, @PrintDate = @PrintDate, @ShipDate = @ShipDate,
				@CurrencyId = @CurrencyId, @EmployeeId = @EmployeeId, @Notes = @Notes,
				@SoldToCustomerId = @SoldToCustomerId, @SoldToSiteId = @SoldToSiteId, @SoldToAttention = @SoldToAttention,
				@ShipToCustomerId = @ShipToCustomerId, @ShipToSiteId = @ShipToSiteId, @ShipToAttention = @ShipToAttention,
				@ShipViaId = @ShipViaId, @ShipAccountInfo = @ShipAccountInfo, @ShippingTermsName = @ShippingTermsName,
				@MasterCompanyId = @MasterCompanyId, @CreatedBy = @UpdatedBy, @DraftMonthsOnly = 1;
		END TRY
		BEGIN CATCH
			-- Leave this draft as it was (Create rolls back its own work); keep syncing the others.
			IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		END CATCH
	END
END
