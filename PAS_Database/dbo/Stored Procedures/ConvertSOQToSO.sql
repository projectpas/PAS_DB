/*************************************************************
 ** File:   [ConvertSOQToSO]
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used to convert sales order quote to sales order
 ** Purpose:
 ** Date:   07/16/2024
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    07/16/2024   Vishal Suthar		Created
    2    09/12/2024   Vishal Suthar		Fixed an issue with getting the credit term for matching
	3    09/16/2024   AMIT GHEDIYA		Adding FunctionalCurrencyId,ReportCurrencyId and ForeignExchangeRate for ConvertSOQToSO

declare @p13 bigint
set @p13=NULL
declare @p14 bigint
set @p14=NULL
exec sp_executesql N'EXEC ConvertSOQToSO @SalesOrderQuoteId, @EmployeeId, @EmployeeName, @CustomerReference, @ReserveStockline, @TransferStockline, @TransferCharges, @TransferFreight, @TransferMemos, @TransferNotes, @SalesOrderId OUTPUT, @CustomerId OUTPUT',N'@SalesOrderQuoteId bigint,@EmployeeId bigint,@EmployeeName nvarchar(11),@CustomerReference nvarchar(10),@ReserveStockline bit,@TransferStockline bit,@TransferCharges bit,@TransferFreight bit,@TransferMemos bit,@TransferNotes bit,@SalesOrderId bigint output,@CustomerId bigint output',@SalesOrderQuoteId=655,@EmployeeId=162,@EmployeeName=N'ADMIN ADMIN',@CustomerReference=N'6300393349',@ReserveStockline=1,@TransferStockline=1,@TransferCharges=0,@TransferFreight=0,@TransferMemos=0,@TransferNotes=0,@SalesOrderId=@p13 output,@CustomerId=@p14 output
select @p13, @p14

**************************************************************/
CREATE   PROCEDURE [dbo].[ConvertSOQToSO]
	@SalesOrderQuoteId bigint = 0,
	@EmployeeId bigint = 0,
	@EmployeeName VARCHAR(200) = NULL,
	@CustomerReference VARCHAR(200) = NULL,
	@ReserveStockline BIT = NULL,
	@TransferStockline BIT = NULL,
	@TransferCharges BIT = NULL,
	@TransferFreight BIT = NULL,
	@TransferMemos BIT = NULL,
	@TransferNotes BIT = NULL,
	@SalesOrderId BIGINT OUTPUT,
	@CustomerId BIGINT OUTPUT
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SET NOCOUNT ON;

 BEGIN TRY
  BEGIN TRANSACTION
   BEGIN
	-- Fetch salesView
	SELECT TOP 1 * INTO #salesView FROM SalesOrderQuote	WHERE SalesOrderQuoteId = @SalesOrderQuoteId;

	-- Fetch customerData
	SELECT TOP 1 * INTO #customerData FROM Customer	WHERE CustomerId = (SELECT CustomerId FROM #salesView);

	-- Initialize isCreditTermsRequired
	DECLARE @isCreditTermsRequired BIT = 0;
	DECLARE @creditterms VARCHAR(100) = '';
	DECLARE @FunctionalCurrencyId BIGINT = 0;
    DECLARE @ReportCurrencyId BIGINT = 0;
    DECLARE @ForeignExchangeRate BIGINT = 0;

	--From SOQSO Header
	SELECT @FunctionalCurrencyId = SOQ.[FunctionalCurrencyId],
		   @ReportCurrencyId = SOQ.[ReportCurrencyId],
		   @ForeignExchangeRate = SOQ.[ForeignExchangeRate]
    FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) WHERE SOQ.SalesOrderQuoteId = @SalesOrderQuoteId;

	-- Fetch creditterms
	SELECT TOP 1 Code INTO #creditterms FROM DBO.CreditTerms WITH (NOLOCK) WHERE CreditTermsId = (SELECT CreditTermId FROM #salesView);

	SELECT @creditterms = CODE FROM #creditterms;

	-- Check creditterms and set isCreditTermsRequired
	IF @creditterms IS NOT NULL
	BEGIN
		IF UPPER(@creditterms) IN ('COD', 'CIA', 'CREDITCARD', 'PREPAID')
		BEGIN
			SET @isCreditTermsRequired = 1;
		END
	END

	-- If customerData is not null
	IF EXISTS (SELECT 1 FROM #customerData)
	BEGIN
		-- Fetch customerTypeResult
		SELECT TOP 1 * INTO #customerTypeResult	FROM CustomerType WHERE CustomerTypeId = (SELECT CustomerTypeId FROM #customerData);

		-- Check customerTypeResult
		IF EXISTS (SELECT 1 FROM #customerTypeResult)
		BEGIN
			IF UPPER((SELECT CustomerTypeName FROM #customerTypeResult)) = 'LEAD'
			BEGIN
				-- Return 422 Unprocessable Entity
				RETURN; --StatusCodes.Status422UnprocessableEntity, PASMessages.CustomerTypeLead;
			END
			ELSE IF UPPER((SELECT CustomerTypeName FROM #customerTypeResult)) = 'CUSTOMER'
			BEGIN
				-- Fetch customerFinData
				SELECT TOP 1 * INTO #customerFinData FROM CustomerFinancial WHERE CustomerId = (SELECT CustomerId FROM #salesView);

				-- Check customerFinData and isCreditTermsRequired

				IF EXISTS (SELECT 1 FROM #customerFinData) AND @isCreditTermsRequired = 0
				BEGIN
					IF (SELECT CreditTermsId FROM #customerFinData) = 0 OR (SELECT CreditLimit FROM #customerFinData) = 0
					BEGIN
						-- Return 422 Unprocessable Entity
						RETURN; --StatusCodes.Status422UnprocessableEntity, PASMessages.CustomerCreditTermAndCreditLimitSOQ;
					END
				END
				ELSE
				BEGIN
					IF @isCreditTermsRequired = 0
					BEGIN
						-- Return 422 Unprocessable Entity
						RETURN; --StatusCodes.Status422UnprocessableEntity, PASMessages.CustomerCreditTermAndCreditLimitSOQ;
					END
				END
			END
		END
	END
	
	DECLARE @totalrevenue DECIMAL(18, 2) = 0;

	-- Main query
	WITH SalesOrderQuoteAnalysisView AS (SELECT 
		part.SalesOrderQuotePartId,
		part.SalesOrderQuoteId,
		part.NetSales,
		ISNULL((
			SELECT SUM(charges.BillingAmount)
			FROM DBO.SalesOrderQuoteCharges charges WITH (NOLOCK)
			WHERE charges.SalesOrderQuoteId = soq.SalesOrderQuoteId 
				AND charges.IsActive = 1 
				AND charges.IsDeleted = 0 
				AND charges.SalesOrderQuotePartId = part.SalesOrderQuotePartId
		), 0) AS Misc
	FROM DBO.SalesOrderQuote soq WITH (NOLOCK)
	JOIN DBO.SalesOrderQuotePart part WITH (NOLOCK) ON soq.SalesOrderQuoteId = part.SalesOrderQuoteId
	LEFT JOIN DBO.StockLine qs WITH (NOLOCK) ON part.StockLineId = qs.StockLineId
	WHERE part.SalesOrderQuoteId = @SalesOrderQuoteId AND part.IsDeleted = 0)
	,SalesOrderQuoteAnalysisData AS (
		SELECT NetSales, Misc FROM SalesOrderQuoteAnalysisView WHERE SalesOrderQuoteId = @SalesOrderQuoteId
	)

	SELECT @totalrevenue = SUM(NetSales + Misc) FROM SalesOrderQuoteAnalysisData;

	-- Print or return the total revenue
	SELECT @totalrevenue AS TotalRevenue;

	DECLARE @SalesOrderCodePrefix INT = 26;
	DECLARE @FulfillingStatusId INT = 10;
	DECLARE @mastCompanyId INT;
	--DECLARE @CustomerId INT;
	DECLARE @CreditTermsId INT;
	DECLARE @CreditLimit DECIMAL(18, 2);
	DECLARE @CreditTermsName VARCHAR(100);
	--DECLARE @SalesOrderId INT;
	DECLARE @CurrentNumber BIGINT;
	DECLARE @CurrentDateTime DATETIME = GETUTCDATE();
	DECLARE @ClosedPartStatusId INT = 10;
	DECLARE @SOQModuleId INT = NULL;
	DECLARE @SOModuleId INT = NULL;

	SELECT @CreditTermsId = CF.CreditTermsId, @CreditLimit = CF.CreditLimit FROM DBO.CustomerFinancial CF WITH (NOLOCK) WHERE CF.CustomerId = (SELECT CustomerId FROM #salesView);
	SELECT @CreditTermsName = CT.[Name] FROM DBO.CreditTerms CT WITH (NOLOCK) WHERE CT.CreditTermsId = @CreditTermsId;
	SELECT @ClosedPartStatusId = SS.SOPartStatusId FROM DBO.SOPartStatus SS WITH (NOLOCK) WHERE SS.PartStatus = 'Closed';
	SELECT @SOQModuleId = M.ModuleId FROM DBO.Module M WITH (NOLOCK) WHERE M.ModuleName = 'SalesQuote';
	SELECT @SOModuleId = M.ModuleId FROM DBO.Module M WITH (NOLOCK) WHERE M.ModuleName = 'SalesOrder';

	SELECT TOP 1 @mastCompanyId = COALESCE(MasterCompanyId, 0)
	FROM DBO.SalesOrderQuote WITH (NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId;

	-- Fetch soCodeData
	SELECT TOP 1 * INTO #soCodeData	FROM CodePrefixes WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = @SalesOrderCodePrefix AND MasterCompanyId = @mastCompanyId;

	-- Determine the current number
	IF EXISTS (SELECT 1 FROM #soCodeData)
	BEGIN
		IF (SELECT CurrentNummber FROM #soCodeData) > 0
		BEGIN
			SET @CurrentNumber = (SELECT CurrentNummber FROM #soCodeData) + 1;
		END
		ELSE
		BEGIN
			SET @CurrentNumber = (SELECT StartsFrom FROM #soCodeData) + 1;
		END

		-- Update soCodeData with new current number
		UPDATE CodePrefixes
		SET CurrentNummber = @CurrentNumber
		WHERE CodePrefixId = (SELECT CodePrefixId FROM #soCodeData);

		-- Generate SalesOrderNumber
		DECLARE @SalesOrderNumber NVARCHAR(50);
		SET @SalesOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNumber, (SELECT CodePrefix FROM #soCodeData), (SELECT CodeSufix FROM #soCodeData)));
	END
	ELSE
	BEGIN
		-- Generate SalesOrderNumber without prefix/suffix
		SET @SalesOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(0, '', ''));
	END

	-- Insert SalesOrder
	INSERT INTO DBO.SalesOrder ([Version],[TypeId],[OpenDate],[ShippedDate],[NumberOfItems],[AccountTypeId],[CustomerId],[CustomerContactId],
	[CustomerReference],[CurrencyId],[TotalSalesAmount],[CustomerHold],[DepositAmount],[BalanceDue],[SalesPersonId],[AgentId],[CustomerSeviceRepId],
	[EmployeeId],[ApprovedById],[ApprovedDate],[Memo],[StatusId],[StatusChangeDate],[Notes],[RestrictPMA],[RestrictDER],[ManagementStructureId],
	[CustomerWarningId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[MasterCompanyId],[IsDeleted],[SalesOrderQuoteId],[QtyRequested],[QtyToBeQuoted],
	[SalesOrderNumber],[IsActive],[ContractReference],[TypeName],[AccountTypeName],[CustomerName],[SalesPersonName],[CustomerServiceRepName],
	[EmployeeName],[CurrencyName],[CustomerWarningName],[ManagementStructureName],[CreditLimit],[CreditTermId],[CreditLimitName],[CreditTermName],
	[VersionNumber],[TotalFreight],[TotalCharges],[FreightBilingMethodId],[ChargesBilingMethodId],[EnforceEffectiveDate],[IsEnforceApproval],
	[Level1],[Level2],[Level3],[Level4],[ATAPDFPath],[LotId],[IsLotAssigned],[AllowInvoiceBeforeShipping],[PercentId],[Days],[NetDays],[COCManufacturingPDFPath],
	[FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate])
	SELECT 1, SOQ.QuoteTypeId, GETUTCDATE(), NULL, 0, SOQ.[AccountTypeId], SOQ.[CustomerId], SOQ.[CustomerContactId],
	CASE WHEN @CustomerReference IS NULL THEN SOQ.CustomerReference ELSE @CustomerReference END, SOQ.[CurrencyId], 0, 0 , 0, 0, SOQ.SalesPersonId, SOQ.[AgentId], SOQ.[CustomerSeviceRepId],
	SOQ.[EmployeeId], NULL, NULL, CASE WHEN @TransferMemos = 1 THEN SOQ.Memo ELSE '' END, @FulfillingStatusId, GETUTCDATE(), CASE WHEN @TransferNotes = 1 THEN SOQ.Notes ELSE '' END, SOQ.[RestrictPMA], SOQ.[RestrictDER], SOQ.[ManagementStructureId],
	NULL, SOQ.[CreatedBy], GETUTCDATE(), SOQ.[UpdatedBy], GETUTCDATE(), SOQ.[MasterCompanyId], 0, @SalesOrderQuoteId, 0, 0,
	@SalesOrderNumber, 1, NULL, NULL, NULL, NULL, NULL, NULL,
	NULL, NULL, NULL, NULL, @CreditLimit, @CreditTermsId, NULL, @CreditTermsName,
	NULL, SOQ.[TotalFreight], SOQ.[TotalCharges], SOQ.[FreightBilingMethodId], SOQ.[ChargesBilingMethodId], NULL, NULL,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	[FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate]
	FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) WHERE SOQ.SalesOrderQuoteId = @SalesOrderQuoteId;
	
	SELECT @SalesOrderId = SCOPE_IDENTITY();

	SELECT @CustomerId = SO.CustomerId FROM DBO.SalesOrder SO WITH (NOLOCK) WHERE SO.SalesOrderId = @SalesOrderId;

	-- Fetch SalesOrder settings
	DECLARE @soqSettingApprovalRule BIT;
	DECLARE @soqSettingEffectiveDate DATETIME;
	DECLARE @soAllowInvoiceBeforeShipping BIT;

	SELECT TOP 1
		@soqSettingApprovalRule = IsApprovalRule,
		@soqSettingEffectiveDate = EffectiveDate,
		@soAllowInvoiceBeforeShipping = AllowInvoiceBeforeShipping
	FROM DBO.SalesOrderSettings WITH (NOLOCK)
	WHERE IsActive = 1 AND IsDeleted = 0 AND MasterCompanyId = @mastCompanyId;

	-- Update SalesOrder with settings
	UPDATE DBO.SalesOrder
	SET 
		IsEnforceApproval = @soqSettingApprovalRule,
		EnforceEffectiveDate = @soqSettingEffectiveDate,
		AllowInvoiceBeforeShipping = @soAllowInvoiceBeforeShipping
	WHERE SalesOrderId = @SalesOrderId;


	/* Transfer Parts */
	INSERT INTO DBO.SalesOrderPart ([SalesOrderId],[ItemMasterId],[StockLineId],[FxRate],[Qty],[UnitSalePrice],[MarkUpPercentage],[SalesBeforeDiscount],
	[Discount],[DiscountAmount],[NetSales],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsDeleted],[UnitCost],[MethodType],
	[SalesPriceExtended],[MarkupExtended],[SalesDiscountExtended],[NetSalePriceExtended],[UnitCostExtended],[MarginAmount],[MarginAmountExtended],[MarginPercentage],
	[ConditionId],[SalesOrderQuoteId],[SalesOrderQuotePartId],[IsActive],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[PriorityId],[StatusId],
	[CustomerReference],[QtyRequested],[Notes],[CurrencyId],[MarkupPerUnit],[GrossSalePricePerUnit],[GrossSalePrice],[TaxType],[TaxPercentage],[TaxAmount],
	[AltOrEqType],[ControlNumber],[IdNumber],[ItemNo],[POId],[PONumber],[PONextDlvrDate],[UnitSalesPricePerUnit],[LotId],[IsLotAssigned])
	SELECT @SalesOrderId, sop.[ItemMasterId], sop.[StockLineId], @ForeignExchangeRate, sop.QtyQuoted, sop.[UnitSalePrice], sop.[MarkUpPercentage], sop.[SalesBeforeDiscount],
	sop.[Discount], sop.[DiscountAmount], sop.[NetSales], sop.[MasterCompanyId], sop.[CreatedBy], sop.[CreatedDate], sop.[UpdatedBy], sop.[UpdatedDate], sop.[IsDeleted], sop.[UnitCost], sop.[MethodType],
	sop.[SalesPriceExtended], sop.[MarkupExtended], sop.[SalesDiscountExtended], sop.[NetSalePriceExtended], sop.[UnitCostExtended], sop.[MarginAmount], sop.[MarginAmountExtended], sop.[MarginPercentage],
	sop.[ConditionId], sop.[SalesOrderQuoteId], sop.[SalesOrderQuotePartId], sop.[IsActive], sop.[CustomerRequestDate], sop.[PromisedDate], sop.[EstimatedShipDate], sop.[PriorityId], sop.[StatusId],
	@CustomerReference, sop.[QtyRequested], sop.[Notes], @FunctionalCurrencyId, sop.[MarkupPerUnit], sop.[GrossSalePricePerUnit], sop.[GrossSalePrice], sop.[TaxType], sop.[TaxPercentage], sop.[TaxAmount],
	sop.[AltOrEqType], sop.[ControlNumber], sop.[IdNumber], sop.[ItemNo], NULL, NULL, NULL, sop.[UnitSalesPricePerUnit], sop.[LotId], sop.[IsLotAssigned]
	FROM DBO.SalesOrderQuotePart sop WITH (NOLOCK)
	WHERE sop.SalesOrderQuoteId = @SalesOrderQuoteId
    AND ((@TransferStockline = 0 AND LOWER(sop.MethodType) <> 's') OR @TransferStockline = 1)
	AND ISNULL(sop.IsNoQuote, 0) <> 1;

	DECLARE @LoopID AS INT;
	CREATE TABLE #sopList
    (
        ID BIGINT NOT NULL IDENTITY,
        [SalesOrderPartId] [bigint] NULL,
        [SalesOrderQuotePartId] [bigint] NULL,
        [ItemMasterId] [bigint] NULL,
        [ConditionId] [bigint] NULL
    )

	INSERT INTO #sopList
    (
        [SalesOrderPartId],
        [SalesOrderQuotePartId],
        [ItemMasterId],
        [ConditionId]
    )
	SELECT DISTINCT sopp.SalesOrderPartId, sopp.SalesOrderQuotePartId, sopp.ItemMasterId, sopp.ConditionId
	FROM DBO.SalesOrderPart sopp WITH (NOLOCK) WHERE sopp.SalesOrderId = @SalesOrderId;

	SELECT @LoopID = MAX(ID) FROM #sopList;
	WHILE (@LoopID > 0)
	BEGIN
		DECLARE @CurrentSOPartId BIGINT = NULL;
		DECLARE @CurrentSOQPartId BIGINT = NULL;
		DECLARE @CurrentItemMasterId BIGINT = NULL;
		DECLARE @CurrentConditionId BIGINT = NULL;

		SELECT @CurrentSOPartId = SOP.SalesOrderPartId, @CurrentSOQPartId = SOP.SalesOrderQuotePartId, @CurrentItemMasterId = SOP.ItemMasterId, @CurrentConditionId = SOP.ConditionId FROM #sopList SOP WHERE SOP.ID = @LoopID;

		/* Transfer Freights */
		IF (@TransferFreight = 1)
		BEGIN
			INSERT INTO DBO.SalesOrderFreight ([SalesOrderQuoteId],[SalesOrderId],[SalesOrderPartId],[ShipViaId],[Weight],[Memo],[Amount],[MarkupPercentageId],
			[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],[BillingRate],[BillingAmount],[Length],[Width],[Height],[UOMId],[DimensionUOMId],[CurrencyId],
			[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId],[ConditionId])
			SELECT sof.SalesOrderQuoteId, @SalesOrderId, @CurrentSOPartId, sof.ShipViaId, sof.[Weight], sof.Memo, sof.Amount, sof.MarkupPercentageId,
			sof.MarkupFixedPrice, sof.HeaderMarkupId, sof.BillingMethodId, sof.BillingRate, sof.BillingAmount, sof.[Length], sof.Width, sof.Height, sof.UOMId, sof.DimensionUOMId, sof.CurrencyId,
			sof.MasterCompanyId, sof.CreatedBy, sof.UpdatedBy, GETUTCDATE() AS CreatedDate, GETUTCDATE() AS UpdatedDate, sof.IsActive, sof.IsDeleted, sof.HeaderMarkupPercentageId, sof.ItemMasterId, sof.ConditionId
			FROM DBO.SalesOrderQuoteFreight sof WITH (NOLOCK)
			LEFT JOIN #sopList sop ON sop.ItemMasterId = sof.ItemMasterId AND sop.ConditionId = sof.ConditionId
			WHERE sof.SalesOrderQuotePartId = @CurrentSOQPartId;
		END

		/* Transfer Charges */
		IF (@TransferCharges = 1)
		BEGIN
			INSERT INTO DBO.SalesOrderCharges ([SalesOrderQuoteId],[SalesOrderId],[SalesOrderPartId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],
			[Description],[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId],[RefNum],
			[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId],[ConditionId],[UOMId])
			SELECT soc.[SalesOrderQuoteId], @SalesOrderId, @CurrentSOPartId, soc.[ChargesTypeId], soc.[VendorId], soc.[Quantity], soc.[MarkupPercentageId],
			soc.[Description], soc.[UnitCost], soc.[ExtendedCost], soc.[MasterCompanyId], soc.[MarkupFixedPrice], soc.[BillingMethodId], soc.[BillingAmount], soc.[BillingRate], soc.[HeaderMarkupId], soc.[RefNum],
			soc.[CreatedBy], soc.[UpdatedBy], GETUTCDATE(), GETUTCDATE(), soc.[IsActive], soc.[IsDeleted], soc.[HeaderMarkupPercentageId], soc.[ItemMasterId], soc.[ConditionId], soc.[UnitOfMeasureId]
			FROM DBO.SalesOrderQuoteCharges soc WITH (NOLOCK)
			LEFT JOIN #sopList sop ON sop.ItemMasterId = soc.ItemMasterId AND sop.ConditionId = soc.ConditionId
			WHERE soc.SalesOrderQuotePartId = @CurrentSOQPartId;
		END

		IF EXISTS (SELECT TOP 1 SOP.SalesOrderPartId FROM DBO.SalesOrderPart SOP WITH (NOLOCK) WHERE SOP.SalesOrderId = @SalesOrderId)
		BEGIN
			INSERT INTO DBO.SalesOrderApproval ([SalesOrderId],[SalesOrderPartId],[SalesOrderQuoteId],[SalesOrderQuotePartId],[CustomerId],[InternalMemo],
			[InternalSentDate],[InternalApprovedDate],[InternalApprovedById],[CustomerSentDate],[CustomerApprovedDate],[CustomerApprovedById],[ApprovalActionId],
			[CustomerStatusId],[InternalStatusId],[CustomerMemo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
			[InternalApprovedBy],[CustomerApprovedBy],[ApprovalAction],[CustomerStatus],[InternalStatus],[RejectedById],[RejectedByName],[RejectedDate],
			[InternalRejectedById],[InternalRejectedByName],[InternalRejectedDate],[InternalSentToId],[InternalSentToName],[InternalSentById])
			SELECT @SalesOrderId, @CurrentSOPartId, SOQA.[SalesOrderQuoteId], SOQA.[SalesOrderQuotePartId], SOQA.[CustomerId], SOQA.[InternalMemo],
			SOQA.[InternalSentDate], SOQA.[InternalApprovedDate], SOQA.[InternalApprovedById], SOQA.[CustomerSentDate], SOQA.[CustomerApprovedDate], SOQA.[CustomerApprovedById], SOQA.[ApprovalActionId],
			SOQA.[CustomerStatusId], SOQA.[InternalStatusId], SOQA.[CustomerMemo], SOQA.[MasterCompanyId], SOQA.[CreatedBy], SOQA.[UpdatedBy], SOQA.[CreatedDate], SOQA.[UpdatedDate], SOQA.[IsActive], SOQA.[IsDeleted],
			SOQA.[InternalApprovedBy], SOQA.[CustomerApprovedBy], SOQA.[ApprovalAction], SOQA.[CustomerStatus], SOQA.[InternalStatus], SOQA.[RejectedById], SOQA.[RejectedByName], SOQA.[RejectedDate],
			SOQA.[InternalRejectedById], SOQA.[InternalRejectedByName], SOQA.[InternalRejectedDate], SOQA.[InternalSentToId], SOQA.[InternalSentToName], SOQA.[InternalSentById]
			FROM DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) WHERE SOQA.SalesOrderQuotePartId = @CurrentSOQPartId;
		END

		IF (@ReserveStockline = 1)
		BEGIN
			DECLARE @InsertedReservePartId BIGINT = NULL;
			DECLARE @StocklineId BIGINT = NULL;
			DECLARE @ReservedQty INT = NULL;

			SELECT @StocklineId = SOP.StocklineId FROM DBO.SalesOrderPart SOP WHERE SOP.SalesOrderPartId = @CurrentSOPartId;

			INSERT INTO DBO.SalesOrderReserveParts ([SalesOrderId],[StockLineId],[ItemMasterId],[PartStatusId],[IsEquPart],[EquPartMasterPartId],[IsAltPart],
			[AltPartMasterPartId],[QtyToReserve],[QtyToIssued],[ReservedById],[ReservedDate],[IssuedById],[IssuedDate],[CreatedBy],[CreatedDate],[UpdatedBy],
			[UpdatedDate],[IsActive],[IsDeleted],[SalesOrderPartId],[TotalReserved],[TotalIssued],[MasterCompanyId])
			SELECT @SalesOrderId, SOP.StockLineId, SOP.[ItemMasterId], 1, 0, NULL, 0,
			NULL, CASE WHEN Stk.QuantityAvailable >= SOP.Qty THEN SOP.Qty ELSE Stk.QuantityAvailable END, 0, @EmployeeId, GETUTCDATE(), NULL, NULL, @EmployeeName, GETUTCDATE(), @EmployeeName,
			GETUTCDATE(), 1, 0, SOP.SalesOrderPartId, CASE WHEN Stk.QuantityAvailable >= SOP.Qty THEN SOP.Qty ELSE Stk.QuantityAvailable END, NULL, SOP.MasterCompanyId
			FROM DBO.SalesOrderPart SOP 
			INNER JOIN DBO.Stockline Stk ON SOP.StockLineId = Stk.StockLineId
			WHERE SOP.SalesOrderPartId = @CurrentSOPartId;

			SELECT @InsertedReservePartId = SCOPE_IDENTITY();

			SELECT @ReservedQty = QtyToReserve FROM DBO.SalesOrderReserveParts WITH (NOLOCK) WHERE SalesOrderReservePartId = @InsertedReservePartId;

			UPDATE DBO.Stockline 
			SET QuantityAvailable = QuantityAvailable - @ReservedQty,
			QuantityReserved = QuantityReserved + @ReservedQty
			WHERE StockLineId = @StocklineId;

			EXEC USP_AddUpdateStocklineHistory @StocklineId, @SOModuleId, @SalesOrderId, @SOQModuleId, @SalesOrderQuoteId, 2, @ReservedQty, @EmployeeName;
		END

		UPDATE DBO.SalesOrderQuotePart SET IsConvertedToSalesOrder = 1, StatusId = @ClosedPartStatusId WHERE SalesOrderQuotePartId = @CurrentSOQPartId;

		SET @LoopID = @LoopID - 1;
	END

	DECLARE @ApprovedActionId BIGINT = 5;
	DECLARE @SOQPartClosedStatusId BIGINT = 2;

	IF NOT EXISTS (SELECT TOP 1 * FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) 
				INNER JOIN DBO.SalesOrderQuotePart SOQP WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
				LEFT JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) ON SOQA.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId
				WHERE SOQ.SalesOrderQuoteId = @SalesOrderQuoteId AND SOQA.ApprovalActionId <> @ApprovedActionId)
	BEGIN
		-- Close Sales Order Quote
		UPDATE DBO.SalesOrderQuote 
		SET StatusId  = @SOQPartClosedStatusId,
			StatusChangeDate = GETUTCDATE(),
			UpdatedDate = GETUTCDATE()
		WHERE SalesOrderQuoteId = @SalesOrderQuoteId;
	END

	DECLARE @MSModuleID INT = 17;
	DECLARE @MSDetailsId BIGINT;
	DECLARE @EntityMSID BIGINT;
	DECLARE @UpdatedBy VARCHAR(100);

	SELECT @EntityMSID = SO.ManagementStructureId, @UpdatedBy = SO.UpdatedBy FROM DBO.SalesOrder SO WITH (NOLOCK) WHERE SO.SalesOrderId = @SalesOrderId;

	EXEC dbo.[USP_SaveSOMSDetails] @MSModuleID, @SalesOrderId, @EntityMSID, @mastCompanyId, @UpdatedBy, @MSDetailsId OUTPUT;
	EXEC UpdateSONameColumnsWithId @SalesOrderId;
	EXEC ReallocateItemNo @SalesOrderId;

   END

   SELECT @SalesOrderId, @CustomerId;

   COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
   IF @@trancount > 0
    PRINT 'ROLLBACK'
    ROLLBACK TRAN;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'ConvertSOQToSO'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@SalesOrderQuoteId AS varchar(10)) ,'') +''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
  END CATCH
END