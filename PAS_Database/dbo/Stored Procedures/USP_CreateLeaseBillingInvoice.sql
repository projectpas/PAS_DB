/*************************************************************
 ** File:   [USP_CreateLeaseBillingInvoice]
 ** Description: Creates a Billing Invoice for a set of selected LeaseStockline rows
 **              (the "Create Invoice" button on the Lease Billing/Invoicing grid,
 **              PN-17949). Re-derives the Time/Cycle overage billing figures itself
 **              (same math as USP_GetLeaseBillingListByLeaseHeaderId) from the
 **              LIVE LeaseStockline/LeaseStocklineUsage data rather than trusting
 **              client-supplied amounts, so a stale grid can't post a wrong invoice.
 **
 **              Uses the shared BillingInvoicing (header) / BillingInvoicingItems
 **              (line item) / BillingInvoicingDetails (Bill To/Ship To/Ship Via)
 **              tables with ModuleId/SubModuleId = 72 (AppModuleEnum.Leasing -
 **              confirmed with the requester: 10 = SalesOrder, 15 = WorkOrder,
 **              72 = Leasing), same tables the SalesOrder/WorkOrder "Billing
 **              Invoice" popup writes to. SubReferenceId is the LeaseStocklineId
 **              being billed. LeaseBillingInvoicingItemDetails stores the
 **              Lease-only Time/Cycle snapshot per item (BillingInvoicingItems has
 **              no matching columns - see that table's header comment).
 **
 **              Invoice numbering follows the same CodeTypes/CodePrefixes
 **              convention as SOInvoice/WOInvoice (USP_AddBillingInvoicingDetails)
 **              - add a 'LeaseInvoice' CodeType + CodePrefix (Admin > Code Prefix
 **              Setup) to get a proper prefixed/sequential number. Until that
 **              master data exists, falls back to an always-unique
 **              'LSE######' number derived from the new invoice's own identity
 **              value, so invoicing isn't blocked on that setup step.
 **
 **              Bill To / Ship To follow the same Customer+Site shape
 **              BillingInvoicingDetails already uses for SO/WO (SoldTo.../
 **              ShipTo...) - the popup defaults both to the lease's own customer
 **              but the user can repoint either to a different customer/site,
 **              same as the SO/WO popup allows.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    18/09/2026     Kishor Makwana          [PN-17949] Created
    2    18/09/2026     Kishor Makwana          [PN-17949] Added the remaining Billing Invoice popup fields (Time/Print Date/Ship Date/Currency, Bill To/Ship To, Ship Via/Shipping Acct Info/Terms) to match the SO/WO popup's full field set.
	3    25/09/2026     Kishor Makwana          [PN-18072 follow-up 5] Added Maintenance/Insurance/Taxes/Other
	                                            (Add Item tab Service Component amounts, Other = SUM of active dynamic
	                                            LeaseStocklineServiceComponent rows) into TotalBillingAmount, unconditionally
	                                            like Charges - matches the same addition just made to
	                                            USP_GetLeaseBillingListByLeaseHeaderId so the persisted invoice total
	                                            reconciles with the Billing/Invoicing grid's Total Billing column. Not
	                                            snapshotted into LeaseBillingInvoicingItemDetails (same treatment as
	                                            Charges above - live-joined only, folded into TotalBillingAmount/GrandTotal).

DECLARE @Ids dbo.TVP_BigInt;
INSERT INTO @Ids (Value) VALUES (1), (2);
EXEC USP_CreateLeaseBillingInvoice @LeaseHeaderId = 1, @LeaseStocklineIds = @Ids,
    @SoldToCustomerId = 1, @SoldToSiteId = 1, @ShipToCustomerId = 1, @ShipToSiteId = 1,
    @MasterCompanyId = 1, @CreatedBy = 'test'
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_CreateLeaseBillingInvoice]
	@LeaseHeaderId BIGINT,
	@LeaseStocklineIds [dbo].[TVP_BigInt] READONLY,
	@InvoiceTypeId INT = NULL,
	@InvoiceDate DATETIME2(7) = NULL,
	@InvoiceTime VARCHAR(10) = NULL,
	@PrintDate DATETIME2(7) = NULL,
	@ShipDate DATETIME2(7) = NULL,
	@CurrencyId INT = NULL,
	@EmployeeId BIGINT = NULL,
	@Notes NVARCHAR(MAX) = NULL,
	@SoldToCustomerId BIGINT,
	@SoldToSiteId BIGINT,
	@SoldToAttention VARCHAR(256) = NULL,
	@ShipToCustomerId BIGINT,
	@ShipToSiteId BIGINT,
	@ShipToAttention VARCHAR(256) = NULL,
	@ShipViaId BIGINT = NULL,
	@ShipAccountInfo VARCHAR(200) = NULL,
	@ShippingTermsName VARCHAR(256) = NULL,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @CustomerId BIGINT, @ManagementStructureId BIGINT, @SalespersonEmployeeId BIGINT, @HeaderEmployeeId BIGINT, @LocalCurrencyId INT,@LeaseModuleId BIGINT;
		
		SELECT TOP 1 @LeaseModuleId = ModuleId from Module WITH (NOLOCK) WHERE ModuleName ='Leasing';
		SELECT
			@CustomerId = CustomerId,
			@ManagementStructureId = ManagementStructureId,
			@SalespersonEmployeeId = SalespersonEmployeeId,
			@HeaderEmployeeId = EmployeeId,
			@LocalCurrencyId = LocalCurrencyId
		FROM [dbo].[LeaseHeader] WITH (NOLOCK)
		WHERE LeaseHeaderId = @LeaseHeaderId AND IsDeleted = 0;

		IF (@CustomerId IS NULL)
		BEGIN
			RAISERROR('Lease Header was not found.', 16, 1);
			RETURN (1);
		END

		IF NOT EXISTS (SELECT 1 FROM @LeaseStocklineIds)
		BEGIN
			RAISERROR('At least one lease stockline must be selected for billing.', 16, 1);
			RETURN (1);
		END

		SET @EmployeeId = ISNULL(@EmployeeId, ISNULL(@SalespersonEmployeeId, @HeaderEmployeeId));
		IF (@EmployeeId IS NULL)
		BEGIN
			RAISERROR('An Employee/Sales Person is required to create the invoice.', 16, 1);
			RETURN (1);
		END

		IF (ISNULL(@InvoiceTypeId, 0) = 0)
		BEGIN
			SELECT TOP 1 @InvoiceTypeId = InvoiceTypeId FROM [dbo].[InvoiceType] WITH (NOLOCK)
			WHERE MasterCompanyId = @MasterCompanyId AND [Description] = 'STANDARD' AND IsActive = 1 AND IsDeleted = 0;
		END
		IF (@InvoiceTypeId IS NULL)
		BEGIN
			RAISERROR('No active ''STANDARD'' Invoice Type is configured for this company.', 16, 1);
			RETURN (1);
		END

		IF (ISNULL(@SoldToCustomerId, 0) = 0 OR ISNULL(@SoldToSiteId, 0) = 0)
		BEGIN
			RAISERROR('Bill To Customer and Site are required to create the invoice.', 16, 1);
			RETURN (1);
		END
		IF (ISNULL(@ShipToCustomerId, 0) = 0 OR ISNULL(@ShipToSiteId, 0) = 0)
		BEGIN
			RAISERROR('Ship To Customer and Site are required to create the invoice.', 16, 1);
			RETURN (1);
		END

		SET @InvoiceDate = ISNULL(@InvoiceDate, GETUTCDATE());
		SET @CurrencyId = ISNULL(@CurrencyId, @LocalCurrencyId);

		;WITH Base AS (
			SELECT
				LSL.LeaseStocklineId,
				LSL.ItemMasterId,
				LSL.StockLineId,
				LSL.ConditionId,
				SLIVE.SerialNumber,
				LSL.QtyReserved AS Qty,
				LSL.BillingMethod,
				LSL.BillingInterval AS BillingFrequency,
				LSL.FlatRate,
				CASE WHEN U.LeaseStocklineUsageId IS NOT NULL
					 THEN ISNULL(U.CurrentTSNHours, 0) * 60 + ISNULL(U.CurrentTSNMinutes, 0)
					 ELSE NULL END AS TimeRecorded,
				CASE WHEN LSL.MaximumTimes IS NOT NULL THEN LSL.MaximumTimes * 60 ELSE NULL END AS TimeLimit,
				LSL.OverrunPerUnitTimes AS TimeOverageRateRaw,
				U.CurrentCSN AS CycleRecorded,
				LSL.MaximumCycles AS CycleLimit,
				LSL.OverrunPerUnitCycles AS CycleOverageRateRaw,
				ISNULL(ChargesAgg.Charges, 0) AS Charges,
				LSL.[Maintenance],
				LSL.[Insurance],
				LSL.[Taxes],
				ISNULL(SC_SUM.OtherComponentAmount, 0) AS OtherComponentAmount
			FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
			INNER JOIN @LeaseStocklineIds SEL ON SEL.Value = LSL.LeaseStocklineId
			LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
			LEFT JOIN [dbo].[LeaseStocklineUsage] U WITH (NOLOCK) ON U.LeaseStocklineId = LSL.LeaseStocklineId AND U.IsDeleted = 0
			OUTER APPLY (
				SELECT SUM(ISNULL(LC.ExtendedCost, 0)) AS Charges
				FROM [dbo].[LeaseCharges] LC WITH (NOLOCK)
				WHERE LC.LeaseStocklineId = LSL.LeaseStocklineId AND LC.IsDeleted = 0
			) ChargesAgg
			LEFT JOIN (
				SELECT LeaseStocklineId, SUM(ISNULL(Amount, 0)) AS OtherComponentAmount
				FROM [dbo].[LeaseStocklineServiceComponent] WITH (NOLOCK)
				WHERE IsDeleted = 0
				GROUP BY LeaseStocklineId
			) SC_SUM ON SC_SUM.LeaseStocklineId = LSL.LeaseStocklineId
			WHERE LSL.LeaseHeaderId = @LeaseHeaderId
			  AND LSL.IsDeleted = 0
			  AND LSL.QtyReserved > 0
		),
		WithOver AS (
			SELECT *,
				IsOverageBillingMethod = CASE WHEN BillingMethod IN ('FlatRatePlusOverrun', 'UsageBased') THEN 1 ELSE 0 END,
				IsFlatRateBillingMethod = CASE WHEN BillingMethod IN ('FlatRateOnly', 'FlatRatePlusOverrun') THEN 1 ELSE 0 END,
				TimeOverRaw = CASE WHEN TimeRecorded IS NOT NULL THEN
						CASE WHEN (TimeRecorded - ISNULL(TimeLimit, 0)) < 0 THEN 0 ELSE (TimeRecorded - ISNULL(TimeLimit, 0)) END
					ELSE NULL END,
				CycleOverRaw = CASE WHEN CycleRecorded IS NOT NULL THEN
						CASE WHEN (CycleRecorded - ISNULL(CycleLimit, 0)) < 0 THEN 0 ELSE (CycleRecorded - ISNULL(CycleLimit, 0)) END
					ELSE NULL END
			FROM Base
		)
		SELECT
			LeaseStocklineId, ItemMasterId, StockLineId, ConditionId, SerialNumber, Qty,
			BillingMethod, BillingFrequency,
			FlatRate = CASE WHEN IsFlatRateBillingMethod = 1 THEN FlatRate ELSE NULL END,
			FlatRateAmount = CASE WHEN IsFlatRateBillingMethod = 1 THEN ISNULL(FlatRate, 0) * Qty ELSE NULL END,
			TimeRecorded, TimeLimit,
			TimeOver = CASE WHEN IsOverageBillingMethod = 1 AND TimeOverRaw IS NOT NULL THEN TimeOverRaw ELSE NULL END,
			TimeOverageRate = CASE WHEN IsOverageBillingMethod = 1 THEN TimeOverageRateRaw ELSE NULL END,
			TimeBillingAmount = CASE WHEN IsOverageBillingMethod = 1 AND TimeOverRaw IS NOT NULL
									  THEN (TimeOverRaw / 60.0) * ISNULL(TimeOverageRateRaw, 0) * Qty
									  ELSE NULL END,
			CycleRecorded, CycleLimit,
			CycleOver = CASE WHEN IsOverageBillingMethod = 1 AND CycleOverRaw IS NOT NULL THEN CycleOverRaw ELSE NULL END,
			CycleOverageRate = CASE WHEN IsOverageBillingMethod = 1 THEN CycleOverageRateRaw ELSE NULL END,
			CycleBillingAmount = CASE WHEN IsOverageBillingMethod = 1 AND CycleOverRaw IS NOT NULL
										THEN CycleOverRaw * ISNULL(CycleOverageRateRaw, 0) * Qty
										ELSE NULL END,
			Charges AS ChargesAmount,
			Maintenance, Insurance, Taxes, OtherComponentAmount,
			TotalBillingAmount =
					ISNULL(CASE WHEN IsFlatRateBillingMethod = 1 THEN ISNULL(FlatRate, 0) * Qty ELSE 0 END, 0)
				  + ISNULL(CASE WHEN IsOverageBillingMethod = 1 AND TimeOverRaw IS NOT NULL THEN (TimeOverRaw / 60.0) * ISNULL(TimeOverageRateRaw, 0) * Qty ELSE 0 END, 0)
				  + ISNULL(CASE WHEN IsOverageBillingMethod = 1 AND CycleOverRaw IS NOT NULL THEN CycleOverRaw * ISNULL(CycleOverageRateRaw, 0) * Qty ELSE 0 END, 0)
				  + ISNULL(Charges, 0)
				  + ISNULL(Maintenance, 0)
				  + ISNULL(Insurance, 0)
				  + ISNULL(Taxes, 0)
				  + ISNULL(OtherComponentAmount, 0)
		INTO #LeaseBillingCalc
		FROM WithOver;

		IF NOT EXISTS (SELECT 1 FROM #LeaseBillingCalc)
		BEGIN
			RAISERROR('None of the selected lease stocklines are eligible for billing (inactive or not reserved).', 16, 1);
			RETURN (1);
		END

		BEGIN TRANSACTION

		DECLARE @GrandTotal DECIMAL(18, 6);
		SELECT @GrandTotal = SUM(ISNULL(TotalBillingAmount, 0)) FROM #LeaseBillingCalc;

		-- Placeholder InvoiceNo (InvoiceNo is NOT NULL) - replaced below once we know the new
		-- BillingInvoicingId, in case no 'LeaseInvoice' CodePrefix has been configured yet.
		INSERT INTO [dbo].[BillingInvoicing]
			(ModuleId, ReferenceId, CustomerId, InvoiceTypeId, InvoiceNo, InvoiceDate, InvoiceTime, PrintDate,
			 EmployeeId, CurrencyId, ManagementStructureId, Notes, SubTotal, GrandTotal, MasterCompanyId, CreatedBy, UpdatedBy)
		VALUES
			(@LeaseModuleId, @LeaseHeaderId, @CustomerId, @InvoiceTypeId, 'PENDING', @InvoiceDate, @InvoiceTime, @PrintDate,
			 @EmployeeId, @CurrencyId, @ManagementStructureId, @Notes, @GrandTotal, @GrandTotal, @MasterCompanyId, @CreatedBy, @CreatedBy);

		DECLARE @BillingInvoicingId BIGINT = SCOPE_IDENTITY();

		DECLARE @LeaseInvoiceCodeTypeId INT, @CodePrefix NVARCHAR(50), @CodeSuffix NVARCHAR(50), @CurrentNo INT = 0, @InvoiceNo VARCHAR(256);

		SELECT @LeaseInvoiceCodeTypeId = CodeTypeId FROM [dbo].[CodeTypes] WITH (NOLOCK)
		WHERE CodeType = 'LeaseInvoice' AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

		IF (@LeaseInvoiceCodeTypeId IS NOT NULL)
		BEGIN
			SELECT TOP 1 @CodePrefix = CodePrefix, @CodeSuffix = CodeSufix FROM [dbo].[CodePrefixes] WITH (NOLOCK)
			WHERE CodeTypeId = @LeaseInvoiceCodeTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;
		END

		IF (COALESCE(@CodePrefix, '') <> '')
		BEGIN
			SELECT @CurrentNo = ISNULL(CurrentNummber, 0) FROM [dbo].[CodePrefixes] WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId;
			IF (@CurrentNo > 0)
			BEGIN
				SET @CurrentNo = @CurrentNo + 1;
				UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @CurrentNo WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId;
			END
			ELSE
			BEGIN
				SET @CurrentNo = (SELECT ISNULL(StartsFrom, 0) FROM [dbo].[CodePrefixes] WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId) + 1;
				UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @CurrentNo WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId;
			END
			SET @InvoiceNo = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNo, ISNULL(@CodePrefix, ''), ISNULL(@CodeSuffix, '')));
		END
		ELSE
		BEGIN			
			DECLARE @LastInvoiceNo VARCHAR(256);
			DECLARE @LastInvoiceNumber INT;

			-- Get the last Leasing invoice number
			SELECT TOP 1 @LastInvoiceNo = InvoiceNo	FROM [dbo].[BillingInvoicing] WITH (UPDLOCK, HOLDLOCK) 	
			WHERE ModuleId = @LeaseModuleId   AND InvoiceNo LIKE 'LSI-%' AND ISNUMERIC(REPLACE(InvoiceNo, 'LSI-', '')) = 1
			ORDER BY BillingInvoicingId DESC;

			-- Get numeric portion
			SET @LastInvoiceNumber =ISNULL(TRY_CAST(REPLACE(@LastInvoiceNo, 'LSI-', '') AS INT),0);

			-- Increment
			SET @LastInvoiceNumber = @LastInvoiceNumber + 1;
			SET @InvoiceNo = 'LSI-' + RIGHT('000000' + CAST(@LastInvoiceNumber AS VARCHAR(20)), 6);
		END

		UPDATE [dbo].[BillingInvoicing] SET InvoiceNo = @InvoiceNo WHERE BillingInvoicingId = @BillingInvoicingId;

		INSERT INTO [dbo].[BillingInvoicingDetails]
			(BillingInvoicingId, SoldToCustomerId, SoldToSiteId, SoldToAttention,
			 ShipToCustomerId, ShipToSiteId, ShipToAttention, ShipviaId, ShipAccountInfo, ShippingTermsName)
		VALUES
			(@BillingInvoicingId, @SoldToCustomerId, @SoldToSiteId, @SoldToAttention,
			 @ShipToCustomerId, @ShipToSiteId, @ShipToAttention, @ShipViaId, @ShipAccountInfo, @ShippingTermsName);

		DECLARE @InsertedItems TABLE (BillingInvoicingItemId BIGINT, LeaseStocklineId BIGINT);

		INSERT INTO [dbo].[BillingInvoicingItems]
			(BillingInvoicingId, ModuleId, ReferenceId, SubModuleId, SubReferenceId, ItemMasterId, StocklineId, ConditionId,
			 SerialNumber, GrandTotal, ShipDate, MasterCompanyId, CreatedBy, UpdatedBy)
		OUTPUT inserted.BillingInvoicingItemId, inserted.SubReferenceId INTO @InsertedItems (BillingInvoicingItemId, LeaseStocklineId)
		SELECT
			@BillingInvoicingId, @LeaseModuleId, @LeaseHeaderId, @LeaseModuleId, LeaseStocklineId, ItemMasterId, StockLineId, ConditionId,
			SerialNumber, TotalBillingAmount, @ShipDate, @MasterCompanyId, @CreatedBy, @CreatedBy
		FROM #LeaseBillingCalc;

		INSERT INTO [dbo].[LeaseBillingInvoicingItemDetails]
			(BillingInvoicingItemId, LeaseStocklineId, BillingMethod, BillingFrequency,
			 FlatRate, FlatRateAmount,
			 TimeRecorded, TimeLimit, TimeOver, TimeOverageRate, TimeBillingAmount,
			 CycleRecorded, CycleLimit, CycleOver, CycleOverageRate, CycleBillingAmount, TotalBillingAmount,
			 MasterCompanyId, CreatedBy, UpdatedBy)
		SELECT
			II.BillingInvoicingItemId, C.LeaseStocklineId, C.BillingMethod, C.BillingFrequency,
			C.FlatRate, C.FlatRateAmount,
			C.TimeRecorded/60, C.TimeLimit/60, C.TimeOver/60, C.TimeOverageRate, C.TimeBillingAmount,
			C.CycleRecorded, C.CycleLimit, C.CycleOver, C.CycleOverageRate, C.CycleBillingAmount, C.TotalBillingAmount,
			@MasterCompanyId, @CreatedBy, @CreatedBy
		FROM @InsertedItems II
		INNER JOIN #LeaseBillingCalc C ON C.LeaseStocklineId = II.LeaseStocklineId;

		DROP TABLE #LeaseBillingCalc;

		COMMIT TRANSACTION;

		SELECT BillingInvoicingId, InvoiceNo, InvoiceDate, GrandTotal FROM [dbo].[BillingInvoicing] WHERE BillingInvoicingId = @BillingInvoicingId;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		IF OBJECT_ID('tempdb..#LeaseBillingCalc') IS NOT NULL
			DROP TABLE #LeaseBillingCalc;

		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_CreateLeaseBillingInvoice]',
            @ProcedureParameters varchar(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS varchar(100)),
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