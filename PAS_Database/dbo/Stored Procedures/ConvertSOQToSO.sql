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
	4    10/21/2024   AMIT GHEDIYA		Updated old table with new table.
	5    11/26/2024   AMIT GHEDIYA		Updated for add HSCODE,ECCN etc to so part.
	6    11/28/2024   Vishal Suthar		Updated for fixing an issue with converting part with multiple stocklines.
	7    11/29/2024   Rajesh Gami		Changes the STATUSID changes for stockline level
	8    12/05/2024   Vishal Suthar		Removing temp table before using it which was giving exception
	9    12/09/2024   Moin Bloch		Updated for fixing an issue with converting part Qty
	10   12/13/2024   AMIT GHEDIYA		Add RefrenceNumber in stocktable.
	11   28/02/2025   Ayushi Patel		Cast OpenDate As a Date
	12   29/09/2025   Vishal Suthar		Fixed an issue with order of parts after transfer
	13   16/10/2024   Moin Bloch		Updated Added SalesPersion Details
	14   12/12/2025   Devendra Shekh	Added SP usp_MapRFQReferences For PO Part Reference Mapping
	15   28/04/2026   BHARGAV SALIYA	[PN-16221] When Convert SOQ to SO Save ShipTO BillTO Address in SO
	16   21/May/2026  Rajesh Gami	    [PN-16507] SOQ to SO: SOQ status should not change to Closed until all parts are converted to SO
	17   17/JUN/2026  AMIT GHEDIYA	    Save ContractReference data move soq to so [PN-16119] 
	18   19/JUN/2026  AMIT GHEDIYA	    Save [SourceBy],[MarketplaceRef] data move soq to so [PN-16922]
	19   09/July/2026  RAJESH GAMI	    [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	20   20/July/2026  RAJESH GAMI	    [PN-17350] - Allow Non-Stock Inventory Parts in Sales Order Quote and Sales Order: removed IsNonStock=0 filters from SOQ-to-SO revenue view and stock reservation logic.
	21   01/Aug/2024   Moin Bloch		[PN-17485] - Create Stockline For Non-Stock Parts And Auto Reserved
declare @p13 bigint
set @p13=NULL
declare @p14 bigint
set @p14=NULL
exec sp_executesql N'EXEC ConvertSOQToSO @SalesOrderQuoteId, @EmployeeId, @EmployeeName, @CustomerReference, @ReserveStockline, @TransferStockline, @TransferCharges, @TransferFreight, @TransferMemos, @TransferNotes, @SalesOrderId OUTPUT, @CustomerId OUTPUT',N'@SalesOrderQuoteId bigint,@EmployeeId bigint,@EmployeeName nvarchar(10),@CustomerReference nvarchar(7),@ReserveStockline bit,@TransferStockline bit,@TransferCharges bit,@TransferFreight bit,@TransferMemos bit,@TransferNotes bit,@SalesOrderId bigint output,@CustomerId bigint output',@SalesOrderQuoteId=784,@EmployeeId=2,@EmployeeName=N'ADMIN User',@CustomerReference=N'ESO-123',@ReserveStockline=1,@TransferStockline=1,@TransferCharges=0,@TransferFreight=0,@TransferMemos=0,@TransferNotes=0,@SalesOrderId=@p13 output,@CustomerId=@p14 output
select @p13, @p14
**************************************************************/
CREATE    PROCEDURE [dbo].[ConvertSOQToSO]
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
	SELECT TOP 1 * INTO #salesView FROM DBO.SalesOrderQuote WITH (NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId;
	DECLARE @SOPartStatusOpen Varchar(100) = (SELECT TOP 1 SOPartStatusId FROM DBO.SOPartStatus WITH (NOLOCK) WHERE [Description] = 'Open')
	DECLARE @SOPartStatusFulfilled Varchar(100) = (SELECT TOP 1 SOPartStatusId FROM DBO.SOPartStatus WITH (NOLOCK) WHERE [Description] = 'Fulfilled')
	DECLARE @totalrevenue DECIMAL(18, 2) = 0;
	DECLARE @FunctionalCurrencyId BIGINT = 0;
    DECLARE @ReportCurrencyId BIGINT = 0;
    DECLARE @ForeignExchangeRate DECIMAL(18, 6) = 0;
	DECLARE @SalesOrderQuoteNumber VARCHAR(100) = NULL;
	DECLARE @StkAutoReserveRefNumber VARCHAR(100) = 'Auto Reserve Stock - ';
	DECLARE @RefNumber VARCHAR(100) = '';

	--From SOQSO Header
	SELECT @FunctionalCurrencyId = SOQ.[FunctionalCurrencyId],
		   @ReportCurrencyId = SOQ.[ReportCurrencyId],
		   @ForeignExchangeRate = SOQ.[ForeignExchangeRate],
		   @SalesOrderQuoteNumber = SOQ.[SalesOrderQuoteNumber]
    FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) WHERE SOQ.SalesOrderQuoteId = @SalesOrderQuoteId;

	-- Main query
	WITH SalesOrderQuoteAnalysisView AS (SELECT 
		part.SalesOrderQuotePartId,
		part.SalesOrderQuoteId,
		partc.NetSaleAmount NetSales,
		ISNULL((
			SELECT SUM(charges.BillingAmount)
			FROM DBO.SalesOrderQuoteCharges charges WITH (NOLOCK)
			WHERE charges.SalesOrderQuoteId = soq.SalesOrderQuoteId 
				AND charges.IsActive = 1 
				AND charges.IsDeleted = 0 
				AND charges.SalesOrderQuotePartId = part.SalesOrderQuotePartId
		), 0) AS Misc
	FROM DBO.SalesOrderQuote soq WITH (NOLOCK)
	JOIN DBO.SalesOrderQuotePartV1 part WITH (NOLOCK) ON soq.SalesOrderQuoteId = part.SalesOrderQuoteId
	INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) 
			ON part.SalesOrderQuotePartId = SOQA.SalesOrderQuotePartId
	LEFT JOIN DBO.SalesOrderQuoteStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderQuotePartId = part.SalesOrderQuotePartId
	LEFT JOIN DBO.SalesOrderQuotePartCost partc WITH (NOLOCK) ON partc.SalesOrderQuotePartId = part.SalesOrderQuotePartId
	LEFT JOIN DBO.StockLine qs WITH (NOLOCK) ON stk.StockLineId = qs.StockLineId
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
	SELECT TOP 1 * INTO #soCodeData	FROM DBO.CodePrefixes WITH (NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = @SalesOrderCodePrefix AND MasterCompanyId = @mastCompanyId;

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
	[FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate],[MarketplaceRef])
	SELECT 1, SOQ.QuoteTypeId, cast(GETUTCDATE() as date), NULL, 0, SOQ.[AccountTypeId], SOQ.[CustomerId], SOQ.[CustomerContactId],
	CASE WHEN @CustomerReference IS NULL THEN SOQ.CustomerReference ELSE @CustomerReference END, SOQ.[CurrencyId], 0, 0 , 0, 0, SOQ.SalesPersonId, SOQ.[AgentId], SOQ.[CustomerSeviceRepId],
	SOQ.[EmployeeId], NULL, NULL, CASE WHEN @TransferMemos = 1 THEN SOQ.Memo ELSE '' END, @FulfillingStatusId, GETUTCDATE(), CASE WHEN @TransferNotes = 1 THEN SOQ.Notes ELSE '' END, SOQ.[RestrictPMA], SOQ.[RestrictDER], SOQ.[ManagementStructureId],
	NULL, SOQ.[CreatedBy], GETUTCDATE(), SOQ.[UpdatedBy], GETUTCDATE(), SOQ.[MasterCompanyId], 0, @SalesOrderQuoteId, 0, 0,
	@SalesOrderNumber, 1, SOQ.[ContractReference], NULL, NULL, NULL, NULL, NULL,
	NULL, NULL, NULL, NULL, @CreditLimit, @CreditTermsId, NULL, @CreditTermsName,
	NULL, SOQ.[TotalFreight], SOQ.[TotalCharges], SOQ.[FreightBilingMethodId], SOQ.[ChargesBilingMethodId], NULL, NULL,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	[FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate],[MarketplaceRef]
	FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) WHERE SOQ.SalesOrderQuoteId = @SalesOrderQuoteId;
	
	SELECT @SalesOrderId = SCOPE_IDENTITY();

	SELECT @CustomerId = SO.CustomerId FROM DBO.SalesOrder SO WITH (NOLOCK) WHERE SO.SalesOrderId = @SalesOrderId;

	EXEC [dbo].[USP_UpdateSalesPersonDetails] @SalesOrderId,@CustomerId,@mastCompanyId,@SOModuleId;

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

	DECLARE @SOQLoopID AS INT;
	CREATE TABLE #soqpList
    (
        ID BIGINT NOT NULL IDENTITY,
        [SalesOrderQuotePartId] [bigint] NULL,
        [ItemMasterId] [bigint] NULL,
        [ConditionId] [bigint] NULL,
		[CreatedBy] [varchar](100) NULL,
		[MasterCompanyId] [int] NULL
    )

	INSERT INTO #soqpList
    (
        [SalesOrderQuotePartId],
        [ItemMasterId],
        [ConditionId],
		[CreatedBy],
		[MasterCompanyId]
    )
	SELECT DISTINCT SOQP.SalesOrderQuotePartId, 
	SOQP.ItemMasterId, SOQP.ConditionId, SOQP.CreatedBy, SOQP.MasterCompanyId
	FROM DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK)
	INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) 
			ON SOQP.SalesOrderQuotePartId = SOQA.SalesOrderQuotePartId
	WHERE SOQP.SalesOrderQuoteId = @SalesOrderQuoteId
	AND ((@TransferStockline = 0) OR @TransferStockline = 1)
	AND ISNULL(SOQP.IsNoQuote, 0) <> 1
	AND ISNULL(SOQP.IsConvertedToSalesOrder,0) = 0
	ORDER BY SOQP.SalesOrderQuotePartId DESC;

	SELECT @SOQLoopID = MAX(ID) FROM #soqpList;
	WHILE (@SOQLoopID > 0)
	BEGIN
		DECLARE @CurrentSOPartId BIGINT = NULL;
		DECLARE @NewSOStocklineId BIGINT = NULL;		
		DECLARE @CurrentSOQPartId BIGINT = NULL;
		DECLARE @CurrentItemMasterId BIGINT = NULL;
		DECLARE @CurrentConditionId BIGINT = NULL;
		DECLARE @CreatedBy VARCHAR(100);
		DECLARE @MasterCompanyId BIGINT = 0;
		DECLARE @SOPStocklineId BIGINT = 0;
		DECLARE @IsService BIT = 0;
		DECLARE @IsNonStock BIT = 0;			

		SELECT @CurrentSOQPartId = SOQP.SalesOrderQuotePartId,
		@CurrentItemMasterId = SOQP.ItemMasterId, @CurrentConditionId = SOQP.ConditionId , @CreatedBy = SOQP.CreatedBy, @MasterCompanyId = SOQP.MasterCompanyId
		FROM #soqpList SOQP WHERE SOQP.ID = @SOQLoopID;

		/* Transfer Part Data */
		INSERT INTO DBO.SalesOrderPartV1 ([SalesOrderId],
			[ItemMasterId],[ConditionId],[QtyRequested],[QtyOrder],[CurrencyId],
			[QtyReserved],
			[PriorityId],[StatusId],[FxRate],[CustomerRequestDate],[PromisedDate],
			[EstimatedShipDate],[Notes],[MasterCompanyId],[CreatedBy],[CreatedDate],
			[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[SalesOrderQuotePartId],
			[ECCN],[HSCODE],[Weight],[SizeLength],[SizeWidth],[SizeHeight])
		SELECT @SalesOrderId,
			sop.[ItemMasterId],sop.[ConditionId],sop.[QtyRequested],sop.[QtyRequested],sop.[CurrencyId],
			0,
			sop.[PriorityId],sop.[StatusId],sop.[FxRate],sop.[CustomerRequestDate],sop.[PromisedDate],
			sop.[EstimatedShipDate],sop.[Notes],sop.[MasterCompanyId],sop.[CreatedBy],GETUTCDATE(),
			sop.[UpdatedBy],GETUTCDATE(),sop.[IsActive],sop.[IsDeleted],sop.[SalesOrderQuotePartId],
			ime.[ExportECCN],ime.[HSCODE],ime.[ExportWeight],ime.[ExportSizeLength],ime.[ExportSizeWidth],ime.[ExportSizeHeight]
		FROM DBO.SalesOrderQuotePartV1 sop WITH(NOLOCK)
		INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) 
			ON sop.SalesOrderQuotePartId = SOQA.SalesOrderQuotePartId
		LEFT JOIN DBO.ItemMasterExportInfo ime WITH (NOLOCK) ON ime.ItemMasterId = sop.ItemMasterId
		WHERE sop.SalesOrderQuotePartId = @CurrentSOQPartId
		AND ((@TransferStockline = 0) OR @TransferStockline = 1)
		AND ISNULL(SOP.IsConvertedToSalesOrder,0) = 0
		AND ISNULL(sop.IsNoQuote, 0) <> 1;

		SET @CurrentSOPartId = SCOPE_IDENTITY();
		/* END Transfer Part Data */

		/* Transfer Part Cost */
		INSERT INTO DBO.SalesOrderPartCost([SalesOrderId],[SalesOrderPartId],[UnitSalesPrice],[UnitSalesPriceExtended],[UnitCost],
			[UnitCostExtended],[MarkUpPercentage],[MarkUpAmount],[MarginAmount],[MarginPercentage],
			[DiscountPercentage],[DiscountAmount],[TaxPercentage],[TaxAmount],[NetSaleAmount],
			[MiscCharges],[Freight],[TotalRevenue],[MasterCompanyId],[CreatedBy],
			[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])
		SELECT @SalesOrderId,@CurrentSOPartId,SOPC.[UnitSalesPrice],SOPC.[UnitSalesPriceExtended],SOPC.[UnitCost],
			SOPC.[UnitCostExtended],SOPC.[MarkUpPercentage],SOPC.[MarkUpAmount],SOPC.[MarginAmount],SOPC.[MarginPercentage],
			SOPC.[DiscountPercentage],SOPC.[DiscountAmount],SOPC.[TaxPercentage],SOPC.[TaxAmount],SOPC.[NetSaleAmount],
			SOPC.[MiscCharges],SOPC.[Freight],SOPC.[TotalRevenue],SOPC.[MasterCompanyId],SOPC.[CreatedBy],
			GETUTCDATE(),SOPC.[UpdatedBy],GETUTCDATE(),SOPC.[IsActive],SOPC.[IsDeleted]
		FROM DBO.SalesOrderQuotePartCost SOPC WITH(NOLOCK)
		WHERE SOPC.SalesOrderQuotePartId = @CurrentSOQPartId 
		AND SOPC.SalesOrderQuoteId = @SalesOrderQuoteId;
		/* END Transfer Part Cost */

		/* Checking if part stockline exists or not */
		IF EXISTS(SELECT 1 FROM DBO.SalesOrderQuoteStocklineV1 SOPSTK WITH(NOLOCK) WHERE SOPSTK.SalesOrderQuotePartId = @CurrentSOQPartId)
		BEGIN
			DECLARE @SOQStocklineLoopID AS INT;

			IF OBJECT_ID(N'tempdb..#soqpsList') IS NOT NULL
			BEGIN
				DROP TABLE #soqpsList
			END

			CREATE TABLE #soqpsList
			(
				ID BIGINT NOT NULL IDENTITY,
				[SalesOrderQuoteStocklineId] [bigint] NULL,
				[StocklineId] [bigint] NULL
			)

			INSERT INTO #soqpsList([SalesOrderQuoteStocklineId],[StocklineId])
			SELECT DISTINCT SOQPS.SalesOrderQuoteStocklineId, SOQPS.StockLineId
			FROM DBO.SalesOrderQuoteStocklineV1 SOQPS WITH (NOLOCK)
			WHERE SOQPS.SalesOrderQuotePartId = @CurrentSOQPartId;

			SELECT @SOQStocklineLoopID = MAX(ID) FROM #soqpsList;
			WHILE (@SOQStocklineLoopID > 0)
			BEGIN
				DECLARE @CurrentSOQStocklineId BIGINT = NULL;

				SELECT @CurrentSOQStocklineId = SalesOrderQuoteStocklineId FROM #soqpsList SOPSTK WITH(NOLOCK) WHERE SOPSTK.ID = @SOQStocklineLoopID;

				/* Transfer Part Stockline */
				INSERT INTO DBO.SalesOrderStocklineV1([SalesOrderPartId],
					[StockLineId],[ConditionId],[QtyOrder],[QtyReserved],[QtyAvailable],[QtyOH],
					[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[StatusId],[MasterCompanyId],
					[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
					[ECCN],[HSCODE],[Weight],[SizeLength],[SizeWidth],[SizeHeight])
				SELECT @CurrentSOPartId,
					SOPSTK.[StockLineId],SOPSTK.[ConditionId],SOPSTK.[QtyQuoted],0,SOPSTK.[QtyAvailable],SOPSTK.[QtyOH],
					SOPSTK.[CustomerRequestDate],SOPSTK.[PromisedDate],SOPSTK.[EstimatedShipDate],SOPSTK.StatusId,SOPSTK.[MasterCompanyId],
					SOPSTK.[CreatedBy],GETUTCDATE(),SOPSTK.UpdatedBy,GETUTCDATE(),SOPSTK.IsActive,SOPSTK.IsDeleted,
					ime.[ExportECCN],ime.[HSCODE],ime.[ExportWeight],ime.[ExportSizeLength],ime.[ExportSizeWidth],ime.[ExportSizeHeight]
				FROM DBO.SalesOrderQuoteStocklineV1 SOPSTK WITH(NOLOCK)
				INNER JOIN DBO.SalesOrderQuotePartV1 SOP WITH (NOLOCK) ON SOP.SalesOrderQuotePartId = SOPSTK.SalesOrderQuotePartId
				INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) ON SOP.SalesOrderQuotePartId = SOQA.SalesOrderQuotePartId
				LEFT JOIN DBO.ItemMasterExportInfo ime WITH (NOLOCK) ON ime.ItemMasterId = SOP.ItemMasterId
				WHERE SOPSTK.SalesOrderQuoteStocklineId = @CurrentSOQStocklineId AND ISNULL(SOP.IsConvertedToSalesOrder,0) = 0; 
				--WHERE SOPSTK.SalesOrderQuotePartId = @CurrentSOQPartId;

				SET @NewSOStocklineId = SCOPE_IDENTITY();
				/* END Transfer Part Stockline */

				/* Transfer Part Stockline Cost */
				INSERT INTO DBO.SalesOrderStockLineCost([SalesOrderId],[SalesOrderPartId],[SalesOrderStocklineId],[UnitSalesPrice],[UnitSalesPriceExtended],
						[UnitCost],[UnitCostExtended],[MarkUpPercentage],[MarkUpAmount],[DiscountPercentage],
						[DiscountAmount],[MarginAmount],[MarginPercentage],[NetSaleAmount],[MasterCompanyId],
						[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])
				SELECT @SalesOrderId,@CurrentSOPartId,@NewSOStocklineId,SOSCO.[UnitSalesPrice],SOSCO.[UnitSalesPriceExtended],
						SOSCO.[UnitCost],SOSCO.[UnitCostExtended],SOSCO.[MarkUpPercentage],SOSCO.[MarkUpAmount],SOSCO.[DiscountPercentage],
						SOSCO.[DiscountAmount],SOSCO.[MarginAmount],SOSCO.[MarginPercentage],SOSCO.[NetSaleAmount],SOSCO.[MasterCompanyId],
						SOSCO.[CreatedBy],GETUTCDATE(),SOSCO.[UpdatedBy],GETUTCDATE(),SOSCO.[IsActive],SOSCO.[IsDeleted]
				FROM DBO.SalesOrderQuoteStockLineCost SOSCO WITH(NOLOCK)
				WHERE SOSCO.SalesOrderQuoteStocklineId = @CurrentSOQStocklineId
				AND SOSCO.SalesOrderQuoteId = @SalesOrderQuoteId
				--AND SOSCO.SalesOrderQuotePartId = @CurrentSOQPartId

				/* END Transfer Part Stockline Cost */

				IF (@ReserveStockline = 1)
				BEGIN
					DECLARE @InsertedReservePartId BIGINT = NULL;
					DECLARE @StocklineId BIGINT = NULL;
					DECLARE @ReservedQty INT = NULL;

					--Set RefrenceNumber
					SET @RefNumber = @StkAutoReserveRefNumber + @SalesOrderQuoteNumber + ' To ' + @SalesOrderNumber;

					INSERT INTO DBO.SalesOrderReserveParts ([SalesOrderId],[StockLineId],[ItemMasterId],[PartStatusId],[IsEquPart],[EquPartMasterPartId],[IsAltPart],
					[AltPartMasterPartId],[QtyToReserve],[QtyToIssued],[ReservedById],[ReservedDate],[IssuedById],[IssuedDate],[CreatedBy],[CreatedDate],[UpdatedBy],
					[UpdatedDate],[IsActive],[IsDeleted],[SalesOrderPartId],[TotalReserved],[TotalIssued],[MasterCompanyId])
					SELECT @SalesOrderId, SOPSTK.StockLineId, SOP.[ItemMasterId], 1, 0, NULL, 0,
					NULL, CASE WHEN Stk.QuantityAvailable >= SOP.QtyOrder THEN SOP.QtyOrder ELSE Stk.QuantityAvailable END, 0, @EmployeeId, GETUTCDATE(), NULL, NULL, @EmployeeName, GETUTCDATE(), @EmployeeName,
					GETUTCDATE(), 1, 0, SOP.SalesOrderPartId, CASE WHEN Stk.QuantityAvailable >= SOP.QtyOrder THEN SOP.QtyOrder ELSE Stk.QuantityAvailable END, NULL, SOP.MasterCompanyId
					FROM DBO.SalesOrderPartV1 SOP WITH(NOLOCK)
					INNER JOIN DBO.SalesOrderStocklineV1 SOPSTK WITH(NOLOCK) ON SOPSTK.SalesOrderPartId = SOP.SalesOrderPartId
					INNER JOIN DBO.Stockline Stk WITH(NOLOCK) ON SOPSTK.StockLineId = Stk.StockLineId
					WHERE SOPSTK.SalesOrderStocklineId = @NewSOStocklineId;
					--SOP.SalesOrderPartId = @CurrentSOPartId;

					SELECT @InsertedReservePartId = SCOPE_IDENTITY();

					SELECT @StocklineId = SOPSTK.StocklineId FROM DBO.SalesOrderStocklineV1 SOPSTK WITH(NOLOCK) WHERE SOPSTK.SalesOrderStocklineId = @NewSOStocklineId; --SOPSTK.SalesOrderPartId = @CurrentSOPartId;

					UPDATE SOPSTK
					SET SOPSTK.QtyReserved = CASE WHEN Stk.QuantityAvailable >= SOP.QtyOrder THEN SOP.QtyOrder ELSE Stk.QuantityAvailable END
					FROM DBO.SalesOrderPartV1 SOP WITH(NOLOCK)
					INNER JOIN DBO.SalesOrderStocklineV1 SOPSTK WITH(NOLOCK) ON SOPSTK.SalesOrderPartId = SOP.SalesOrderPartId
					INNER JOIN DBO.Stockline Stk WITH(NOLOCK) ON SOPSTK.StockLineId = Stk.StockLineId
					WHERE SOPSTK.SalesOrderPartId = @CurrentSOPartId AND SOPSTK.StockLineId = @StocklineId;

					UPDATE SOPSTK
					SET SOPSTK.StatusId = CASE WHEN (SOPSTK.QtyOrder = SOPSTK.QtyReserved) THEN @SOPartStatusFulfilled ELSE @SOPartStatusOpen END
					FROM DBO.SalesOrderPartV1 SOP WITH(NOLOCK)
					INNER JOIN DBO.SalesOrderStocklineV1 SOPSTK WITH(NOLOCK) ON SOPSTK.SalesOrderPartId = SOP.SalesOrderPartId
					INNER JOIN DBO.Stockline Stk WITH(NOLOCK) ON SOPSTK.StockLineId = Stk.StockLineId
					WHERE SOPSTK.SalesOrderPartId = @CurrentSOPartId AND SOPSTK.StockLineId = @StocklineId;

					Update DBO.SalesOrderPartV1 
					SET StatusId = CASE WHEN QtyOrder = QtyReserved THEN @SOPartStatusFulfilled ELSE @SOPartStatusOpen END
					WHERE SalesOrderPartId = @CurrentSOPartId

					SELECT @ReservedQty = QtyToReserve FROM DBO.SalesOrderReserveParts WITH (NOLOCK) WHERE SalesOrderReservePartId = @InsertedReservePartId;

					UPDATE DBO.Stockline 
					SET QuantityAvailable = QuantityAvailable - @ReservedQty,
					QuantityReserved = QuantityReserved + @ReservedQty
					WHERE StockLineId = @StocklineId;

					--Add RefrenceNumber for SOQ TO SO
					UPDATE [DBO].[SalesOrderStocklineV1] 
					SET ReferenceNumber = @RefNumber
					WHERE SalesOrderPartId = @CurrentSOPartId AND StockLineId = @StockLineId

					EXEC USP_AddUpdateStocklineHistory @StocklineId, @SOModuleId, @SalesOrderId, @SOQModuleId, @SalesOrderQuoteId, 2, @ReservedQty, @EmployeeName;
				END

				SET @SOQStocklineLoopID = @SOQStocklineLoopID - 1;
			END
		END
		ELSE
		BEGIN
			/* Create Stockline For Non-Stock Part */
			SELECT @SOPStocklineId = [StockLineId] FROM [dbo].[SalesOrderQuoteStocklineV1] WITH(NOLOCK) WHERE [SalesOrderQuotePartId] = @CurrentSOQPartId;

			SELECT @IsService = ISNULL([IsService],0), @IsNonStock = ISNULL([IsNonStock],0) FROM [dbo].[ItemMaster] WITH (NOLOCK) WHERE [ItemMasterId] = @CurrentItemMasterId;

			IF(@IsService = 1 AND @IsNonStock = 1 AND ISNULL(@SOPStocklineId, 0) = 0)
			BEGIN
				EXEC [dbo].[USP_CreateStocklineForNosStockSalesOrderPart]
						   @SalesOrderId = @SalesOrderId,
						   @SalesOrderPartId = @CurrentSOPartId,
						   @ItemMasterId = @CurrentItemMasterId,
						   @CreatedBy = @CreatedBy,
						   @MasterCompanyId = @MasterCompanyId,
						   @StockLineId = @SOPStocklineId OUTPUT;

				IF(@SOPStocklineId > 0)
				BEGIN
					DECLARE @CustomerRequestDate AS Datetime2(7);
					DECLARE @PromisedDate AS Datetime2(7);
					DECLARE @EstimatedShipDate AS Datetime2(7);
					DECLARE @SOPartStatus BIGINT;
					DECLARE @PriorityId BIGINT;

					DECLARE @UnitSalesPrice AS decimal(18,4);
					DECLARE @MarkUpAmount AS decimal(18,4);
					DECLARE @MarkUpPercentage AS decimal(18,4);
					DECLARE @NetSaleAmount AS decimal(18,4);
					DECLARE @DiscountAmount AS decimal(18,4);
					DECLARE @MarginAmount AS decimal(18,4);
					DECLARE @UnitCost AS decimal(18,4);
					DECLARE @MarginPercentage AS decimal(18,4);
					DECLARE @DiscountPercentage AS decimal(18,4);
					DECLARE @NetSalesPerUnitAmt AS decimal(18,4);
					DECLARE @QtyOrder AS INT;

					SELECT @CustomerRequestDate = sop.[CustomerRequestDate],
					        @PromisedDate = sop.[PromisedDate],
						    @EstimatedShipDate = sop.[EstimatedShipDate],
							@SOPartStatus = sop.[StatusId],
							@PriorityId = sop.[PriorityId],
							@QtyOrder =  sop.[QtyRequested]
					FROM [dbo].[SalesOrderQuotePartV1] sop WITH(NOLOCK)
					LEFT JOIN [dbo].[ItemMasterExportInfo] ime WITH (NOLOCK) ON ime.ItemMasterId = sop.ItemMasterId
					WHERE sop.[SalesOrderQuotePartId] = @CurrentSOQPartId
					AND ((@TransferStockline = 0) OR @TransferStockline = 1)
					AND ISNULL(SOP.[IsConvertedToSalesOrder],0) = 0
					AND ISNULL(sop.[IsNoQuote], 0) <> 1;

					INSERT INTO [dbo].[SalesOrderStocklineV1] ([SalesOrderPartId], [StockLineId], [ConditionId], [QtyOrder], [QtyReserved],
						[QtyAvailable], [QtyOH], [CustomerRequestDate], [PromisedDate], [EstimatedShipDate], [StatusId], [MasterCompanyId], [CreatedBy], [CreatedDate],
						[UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [ECCN],[HSCODE],[Weight],[SizeLength],[SizeWidth],[SizeHeight],[PriorityId])
					SELECT @CurrentSOPartId, STK.StockLineId, STK.ConditionId, stk.Quantity, 0,
						stk.QuantityAvailable, STK.QuantityOnHand, @CustomerRequestDate, @PromisedDate, @EstimatedShipDate, @SOPartStatus, @MasterCompanyId, @CreatedBy, GETUTCDATE(),
						@CreatedBy, GETUTCDATE(), 1, 0,	ime.[ExportECCN],ime.[HSCODE],ime.[ExportWeight],ime.[ExportSizeLength],ime.[ExportSizeWidth],ime.[ExportSizeHeight],@PriorityId
					FROM [dbo].[Stockline] STK
					LEFT JOIN [dbo].[ItemMasterExportInfo] ime WITH(NOLOCK) ON ime.[ItemMasterId] = STK.[ItemMasterId]
					WHERE STK.[StockLineId] = @SOPStocklineId;

					SET @NewSOStocklineId = SCOPE_IDENTITY();

					SELECT @UnitSalesPrice = ISNULL(SOPC.[UnitSalesPrice],0),
					       @UnitCost =   ISNULL(SOPC.[UnitCost],0),
						   @MarkUpPercentage = ISNULL(SOPC.[MarkUpPercentage],0),
						   @MarkUpAmount = ISNULL(SOPC.[MarkUpAmount],0),
						   @MarginAmount = ISNULL(SOPC.[MarginAmount],0),
						   @MarginPercentage = ISNULL(SOPC.[MarginPercentage],0),
						   @DiscountPercentage = ISNULL(SOPC.[DiscountPercentage],0),
						   @DiscountAmount = ISNULL(SOPC.[DiscountAmount],0),
						   @NetSaleAmount = ISNULL(SOPC.[NetSaleAmount],0)
						FROM [dbo].[SalesOrderQuotePartCost] SOPC WITH(NOLOCK)
						WHERE SOPC.SalesOrderQuotePartId = @CurrentSOQPartId
						AND SOPC.SalesOrderQuoteId = @SalesOrderQuoteId;

					INSERT INTO [dbo].[SalesOrderStockLineCost] ([SalesOrderId], [SalesOrderPartId], [SalesOrderStocklineId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [NetSaleAmount],
					[UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [DiscountPercentage], [DiscountAmount],
					[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
					SELECT @SalesOrderId, @CurrentSOPartId, @NewSOStocklineId, @UnitSalesPrice, ISNULL((@UnitSalesPrice * @QtyOrder), 0), @MarkUpPercentage, ISNULL((@MarkUpAmount * @QtyOrder), 0), @NetSaleAmount,
						@UnitCost, ISNULL((@UnitCost * @QtyOrder), 0), @MarginAmount, @MarginPercentage, @DiscountPercentage, ISNULL((@DiscountAmount * @QtyOrder), 0),
						@MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0
						FROM [DBO].[StockLine] Stkl
						WHERE Stkl.StockLineId = @SOPStocklineId

					SET @ReserveStockline = 1;

					IF (@ReserveStockline = 1)
					BEGIN
						DECLARE @InsertedReservePartId2 BIGINT = NULL;
						DECLARE @StocklineId2 BIGINT = NULL;
						DECLARE @ReservedQty2 INT = NULL;

						--Set RefrenceNumber
						SET @RefNumber = @StkAutoReserveRefNumber + @SalesOrderQuoteNumber + ' To ' + @SalesOrderNumber;

						INSERT INTO DBO.SalesOrderReserveParts ([SalesOrderId],[StockLineId],[ItemMasterId],[PartStatusId],[IsEquPart],[EquPartMasterPartId],[IsAltPart],
						[AltPartMasterPartId],[QtyToReserve],[QtyToIssued],[ReservedById],[ReservedDate],[IssuedById],[IssuedDate],[CreatedBy],[CreatedDate],[UpdatedBy],
						[UpdatedDate],[IsActive],[IsDeleted],[SalesOrderPartId],[TotalReserved],[TotalIssued],[MasterCompanyId])
						SELECT @SalesOrderId, SOPSTK.StockLineId, SOP.[ItemMasterId], 1, 0, NULL, 0,
						NULL, CASE WHEN Stk.QuantityAvailable >= SOP.QtyOrder THEN SOP.QtyOrder ELSE Stk.QuantityAvailable END, 0, @EmployeeId, GETUTCDATE(), NULL, NULL, @EmployeeName, GETUTCDATE(), @EmployeeName,
						GETUTCDATE(), 1, 0, SOP.SalesOrderPartId, CASE WHEN Stk.QuantityAvailable >= SOP.QtyOrder THEN SOP.QtyOrder ELSE Stk.QuantityAvailable END, NULL, SOP.MasterCompanyId
						FROM DBO.SalesOrderPartV1 SOP WITH(NOLOCK)
						INNER JOIN DBO.SalesOrderStocklineV1 SOPSTK WITH(NOLOCK) ON SOPSTK.SalesOrderPartId = SOP.SalesOrderPartId
						INNER JOIN DBO.Stockline Stk WITH(NOLOCK) ON SOPSTK.StockLineId = Stk.StockLineId
						WHERE SOPSTK.SalesOrderStocklineId = @NewSOStocklineId;
						--SOP.SalesOrderPartId = @CurrentSOPartId;

						SELECT @InsertedReservePartId2 = SCOPE_IDENTITY();

						SELECT @StocklineId2 = SOPSTK.StocklineId FROM DBO.SalesOrderStocklineV1 SOPSTK WITH(NOLOCK) WHERE SOPSTK.SalesOrderStocklineId = @NewSOStocklineId; --SOPSTK.SalesOrderPartId = @CurrentSOPartId;

						UPDATE SOPSTK
						SET SOPSTK.QtyReserved = CASE WHEN Stk.QuantityAvailable >= SOP.QtyOrder THEN SOP.QtyOrder ELSE Stk.QuantityAvailable END
						FROM DBO.SalesOrderPartV1 SOP WITH(NOLOCK)
						INNER JOIN DBO.SalesOrderStocklineV1 SOPSTK WITH(NOLOCK) ON SOPSTK.SalesOrderPartId = SOP.SalesOrderPartId
						INNER JOIN DBO.Stockline Stk WITH(NOLOCK) ON SOPSTK.StockLineId = Stk.StockLineId
						WHERE SOPSTK.SalesOrderPartId = @CurrentSOPartId AND SOPSTK.StockLineId = @StocklineId2;

						UPDATE SOPSTK
						SET SOPSTK.StatusId = CASE WHEN (SOPSTK.QtyOrder = SOPSTK.QtyReserved) THEN @SOPartStatusFulfilled ELSE @SOPartStatusOpen END
						FROM DBO.SalesOrderPartV1 SOP WITH(NOLOCK)
						INNER JOIN DBO.SalesOrderStocklineV1 SOPSTK WITH(NOLOCK) ON SOPSTK.SalesOrderPartId = SOP.SalesOrderPartId
						INNER JOIN DBO.Stockline Stk WITH(NOLOCK) ON SOPSTK.StockLineId = Stk.StockLineId
						WHERE SOPSTK.SalesOrderPartId = @CurrentSOPartId AND SOPSTK.StockLineId = @StocklineId2;

						Update DBO.SalesOrderPartV1
						SET StatusId = CASE WHEN QtyOrder = QtyReserved THEN @SOPartStatusFulfilled ELSE @SOPartStatusOpen END
						WHERE SalesOrderPartId = @CurrentSOPartId

						SELECT @ReservedQty2 = QtyToReserve FROM DBO.SalesOrderReserveParts WITH (NOLOCK) WHERE SalesOrderReservePartId = @InsertedReservePartId2;

						UPDATE DBO.Stockline
						SET QuantityAvailable = QuantityAvailable - @ReservedQty2,
						QuantityReserved = QuantityReserved + @ReservedQty2
						WHERE StockLineId = @StocklineId2;

						--Add RefrenceNumber for SOQ TO SO
						UPDATE [DBO].[SalesOrderStocklineV1]
						SET ReferenceNumber = @RefNumber
						WHERE SalesOrderPartId = @CurrentSOPartId AND StockLineId = @StockLineId2

						EXEC USP_AddUpdateStocklineHistory @StocklineId2, @SOModuleId, @SalesOrderId, @SOQModuleId, @SalesOrderQuoteId, 2, @ReservedQty2, @EmployeeName;
					END
				END
			END
			/* END Create Stockline For Non-Stock Part */
		END

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
			--LEFT JOIN #sopList sop ON sop.ItemMasterId = sof.ItemMasterId AND sop.ConditionId = sof.ConditionId
			WHERE sof.SalesOrderQuotePartId = @CurrentSOQPartId;
		END
		/* END Transfer Freights */

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
			--LEFT JOIN #sopList sop ON sop.ItemMasterId = soc.ItemMasterId AND sop.ConditionId = soc.ConditionId
			WHERE soc.SalesOrderQuotePartId = @CurrentSOQPartId;
		END
		/* END Transfer Charges */

		/* Transfer SalesOrderApproval */
		IF EXISTS (SELECT TOP 1 SOP.SalesOrderPartId FROM DBO.SalesOrderPartV1 SOP WITH (NOLOCK) WHERE SOP.SalesOrderId = @SalesOrderId)
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
			FROM DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) WHERE SOQA.SalesOrderQuotePartId = @CurrentSOQPartId AND SOQA.SalesOrderQuoteId = @SalesOrderQuoteId;
		END
		/* END Transfer SalesOrderApproval */

		/* Add ShipToAddress */
		DECLARE @UserTypeId bigint,@SiteId bigint = 0,@UserId bigint,@SiteName varchar(500),@AddressId bigint = 0,@Address1 varchar(100),@Address2 varchar(100) = '',@Address3 varchar(100) = '',
		@City varchar(100),@StateOrProvince varchar(100),@PostalCode varchar(100),@CountryId bigint,@IsPrimary bit = 0,@UpdateBy varchar(100),@AllAddressId BIGINT = 0,
		@IsModuleOnly bit = 0,@IsShippingAdd bit = 0,@Memo varchar(500),@ContactId bigint,@ContactName varchar(500),@Country varchar(50),@UserTypeName varchar(100),@UserName varchar(100);

		IF EXISTS (SELECT 1 FROM dbo.AllAddress WHERE ReffranceId = @SalesOrderQuoteId AND ModuleId = @SOQModuleId AND ISNULL(IsShippingAdd,0) = 1)
		BEGIN
			SELECT TOP 1
				@UserTypeId = UserType,
				@SiteId = SiteId,
				@UserId = UserId,
				@SiteName = SiteName,
				@AddressId = AddressId,
				@Address1 = Line1,
				@Address2 = Line2,
				@Address3 = Line3,
				@City = City,
				@StateOrProvince = StateOrProvince,
				@PostalCode = PostalCode,
				@CountryId = CountryId,
				@IsPrimary = ISNULL(IsPrimary,0),
				@IsModuleOnly = ISNULL(IsModuleOnly,0),
				@IsShippingAdd = ISNULL(IsShippingAdd,0),
				@Memo = Memo,
				@ContactId = ContactId,
				@ContactName = ContactName,
				@Country = Country,
				@UserTypeName = UserTypeName,
				@UserName = UserName,
				@UpdateBy = UpdatedBy
			FROM dbo.AllAddress WITH(NOLOCK)
			WHERE ReffranceId = @SalesOrderQuoteId AND ModuleId = @SOQModuleId AND ISNULL(IsShippingAdd,0) = 1

			IF NOT EXISTS (SELECT 1 FROM dbo.AllAddress WHERE ReffranceId = @SalesOrderId AND ModuleId = @SOModuleId AND ISNULL(IsShippingAdd,0) = 1)
			BEGIN
				EXEC dbo.usp_createAllAddress @SiteId,@UserTypeId, @UserId,@SiteName,@AddressId, @Address1, @Address2,@Address3,@City,@StateOrProvince,@PostalCode,@CountryId,@IsPrimary,@MasterCompanyId,@CreatedBy,@UpdateBy,
					@SalesOrderId,@IsModuleOnly,@SOModuleId,@IsShippingAdd,@Memo,@ContactId,@ContactName,@Country,@AllAddressId, @UserTypeName,@UserName;
			END
		END
		/* END ShipToAddress */

		/* Add BillToAddress */
		IF EXISTS (SELECT 1 FROM dbo.AllAddress WHERE ReffranceId = @SalesOrderQuoteId AND ModuleId = @SOQModuleId AND ISNULL(IsShippingAdd,0) = 0)
		BEGIN
			SELECT TOP 1
				@UserTypeId = UserType,
				@SiteId = SiteId,
				@UserId = UserId,
				@SiteName = SiteName,
				@AddressId = AddressId,
				@Address1 = Line1,
				@Address2 = Line2,
				@Address3 = Line3,
				@City = City,
				@StateOrProvince = StateOrProvince,
				@PostalCode = PostalCode,
				@CountryId = CountryId,
				@IsPrimary = ISNULL(IsPrimary,0),
				@IsModuleOnly = ISNULL(IsModuleOnly,0),
				@IsShippingAdd = ISNULL(IsShippingAdd,0),
				@Memo = Memo,
				@ContactId = ContactId,
				@ContactName = ContactName,
				@Country = Country,
				@UserTypeName = UserTypeName,
				@UserName = UserName,
				@UpdateBy = UpdatedBy
			FROM dbo.AllAddress WITH(NOLOCK)
			WHERE ReffranceId = @SalesOrderQuoteId AND ModuleId = @SOQModuleId AND ISNULL(IsShippingAdd,0) = 0
		
			IF NOT EXISTS (SELECT 1 FROM dbo.AllAddress WHERE ReffranceId = @SalesOrderId AND ModuleId = @SOModuleId AND ISNULL(IsShippingAdd,0) = 0)
			BEGIN
				EXEC dbo.usp_createAllAddress @SiteId,@UserTypeId, @UserId,@SiteName,@AddressId, @Address1, @Address2,@Address3,@City,@StateOrProvince,@PostalCode,@CountryId,@IsPrimary,@MasterCompanyId,@CreatedBy,@UpdateBy,
					@SalesOrderId,@IsModuleOnly,@SOModuleId,@IsShippingAdd,@Memo,@ContactId,@ContactName,@Country,@AllAddressId, @UserTypeName,@UserName;
			END
		END
		/* END BillToAddress */

		/* Add ShipVia */
		DECLARE @AllShipViaId bigint = 0,@UserType int,@ShipViaId bigint = 0,@ShippingCost decimal(20,3),@HandlingCost decimal(20,3),@IsModuleShipVia bit,@ShippingAccountNo varchar(100),@ShipVia varchar(100),
		@ShippingViaId bigint,@ShippingTerms varchar(100) = null;

		IF EXISTS (SELECT 1 FROM dbo.AllShipVia WITH (NOLOCK) WHERE ReferenceId = @SalesOrderQuoteId AND ModuleId = @SOQModuleId)
		BEGIN
			SELECT TOP 1
				@UserType = UserType,
				@ShipViaId = ShipViaId,
				@ShippingCost = ISNULL(ShippingCost,0),
				@HandlingCost = ISNULL(HandlingCost,0),
				@IsModuleShipVia = ISNULL(IsModuleShipVia,0),
				@ShippingAccountNo = ShippingAccountNo,
				@ShipVia = ShipVia,
				@ShippingViaId = ShippingViaId,
				@ShippingTerms = ShippingTerms
			FROM dbo.AllShipVia WITH (NOLOCK) WHERE ReferenceId = @SalesOrderQuoteId AND ModuleId = @SOQModuleId;

			IF NOT EXISTS (SELECT 1 FROM dbo.AllShipVia WITH (NOLOCK) WHERE ReferenceId = @SalesOrderId AND ModuleId = @SOModuleId)
			BEGIN
				EXEC dbo.usp_createAllShipVia 0, @SalesOrderId, @SOModuleId, @UserType,@ShipViaId,@ShippingCost,@HandlingCost,@IsModuleShipVia,@ShippingAccountNo,@ShipVia,@ShippingViaId,@MasterCompanyId,@CreatedBy,@UpdateBy,@ShippingTerms;
			END
		END
		/* Add ShipVia */

		UPDATE DBO.SalesOrderQuotePartV1 SET IsConvertedToSalesOrder = 1, StatusId = @ClosedPartStatusId WHERE SalesOrderQuotePartId = @CurrentSOQPartId;
		
		/* Update SOPart Cost Details */
		EXEC [dbo].[USP_UpdateSOPartCostDetails] @SalesOrderId, @CurrentSOPartId, @CreatedBy, @MasterCompanyId;

		SET @SOQLoopID = @SOQLoopID - 1;
	END

	DECLARE @ApprovedActionId BIGINT = 5;
	DECLARE @SOQPartClosedStatusId BIGINT = 2;

	IF NOT EXISTS (
		SELECT 1 
		FROM DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK)
		LEFT JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) 
			ON SOQA.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId
		WHERE SOQP.SalesOrderQuoteId = @SalesOrderQuoteId
		  AND (SOQA.ApprovalActionId IS NULL                    -- Part has no approval record
			OR SOQA.ApprovalActionId <> @ApprovedActionId)      -- Part is not approved
	)
	BEGIN
		-- Close Sales Order Quote (all parts are approved)
		UPDATE DBO.SalesOrderQuote 
		SET StatusId         = @SOQPartClosedStatusId,
			StatusChangeDate = GETUTCDATE(),
			UpdatedDate      = GETUTCDATE()
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

   EXEC [dbo].[usp_MapRFQReferences] @SOModuleId, @SalesOrderId, @MasterCompanyId, @EmployeeName;

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