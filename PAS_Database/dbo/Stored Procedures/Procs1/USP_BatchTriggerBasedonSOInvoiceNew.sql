/*************************************************************           
 ** File:   [USP_BatchTriggerBasedonSOInvoiceNew]
 ** Author:  Deep Patel
 ** Description: This stored procedure is used to enter acounting entry for SO
 ** Purpose:         
 ** Date:   08/11/2022
          
 ** PARAMETERS: @JournalBatchHeaderId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/11/2022  Deep Patel     Created
	2    19/07/2023  Satish Gohil   Modify(Change distribution entry static to dyamic)
	3    24/07/2023	 Satish GOhil   Modify(Change Name to distribution seeup code in condition)
	4    18/08/2023  Moin Bloch     Modify(Added Accounting MS Entry)
	5    18/08/2023  Hemant Saliya  Corrected For MS entry not Saved.
	6    30/11/2023  Moin Bloch     Modify(Added LotId And Lot Number in CommonBatchDetails)
	7    11/12/2023  Moin Bloch     Modify(If Invoice Entry NOT EXISTS Then only Invoice Entry Will Store)
	8    08/01/2024  Moin Bloch     Modify(Replace Invocedate instead of GETUTCDATE() in Invoice)
    9	 01/02/2024	 AMIT GHEDIYA	added isperforma Flage for SO
	10   02/04/2024  HEMANT SALIYA  Added LE Params to Get Correct Accounting Cal Id
	11   19/09/2024	 AMIT GHEDIYA   Added for AutoPost Batch
	12	 09/10/2024	 Devendra Shekh	Added new fields for [CommonBatchDetails]
	13	 11/04/2024  Devendra Shekh Added ReferenceId, ReferenceModule For [CommonBatchDetails]
	14	 11/29/2024  Vishal Suthar  Modified the SP to make use of new SO tables
	15	 12/03/2024  Vishal Suthar  Fixed accounting entry while shipping
	16	 12/05/2024  Devendra Shekh Fixed amount issue while shipping/billing(cogs/inventory) accounting entry
	17	 12/06/2024  Moin Bloch     Fixed Duplicate amount issue 
	18	 06/01/2025  AMIT GHEDIYA   Modify(get Distribution based on new settings from stockline level with single bill)
	19	 24/04/2025	 Devendra Shekh	Modify (Added [IsManualText] check for DistributionSetup)
	20	 02/06/2025	 Abhishek Jirawla Fixed Name concat read script
  	21	 16/06/2025	 RAJESH GAMI	Implement new BILLING INVOICING table structure 
	22	 31/07/2025	 RAJESH GAMI	Fixed : Getting Freight and Charges Amount from the invoice table instead of SO Part table
	23    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	24    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	25    20/July/2026			 RAJESH GAMI						[PN-17350] - Removed IsNonStock=0 filters from SO invoice GL journal-entry creation (COGS/Revenue/Inventory distribution lookups) so Non-Stock items are included.
	26    12-Aug-2026			 RAJESH GAMI						[PN-17569] Fixed: the existing-BatchHeader lookup (both the SOI and SOS blocks) was matching purely on
																	JournalTypeId/MasterCompanyId/EntryDate/StatusId/CustomerTypeId, which a Re-Open accounting
																	reversal's batch header (see USP_ReverseSOInvoiceAccountingEntry) also satisfies same-day -
																	so re-invoicing after a Re-Open was gluing its fresh (non-reversal) lines onto that reversal's
																	batch header instead of starting a new one. Both the existence check and the header lookup now
																	exclude any BatchHeader that has a BatchDetails row with IsReversedJE = 1.
	27    12-Aug-2026			 RAJESH GAMI						[PN-17569] Fixed: re-posting a Sales Order invoice after Re-Open (same BillingInvoicingId,
																no version increase) was silently creating NO accounting entries at all. The SOINVOICE
																duplicate-post guard only checked "does ANY SalesOrderBatchDetails row already exist for
																this DocumentId" - Re-Open's reversal leaves the original rows in place (it reverses them,
																it doesn't delete them), so that guard always found rows and skipped posting entirely on
																every subsequent re-invoice of the same document. It now only blocks when an entry exists
																that is newer (by JournalBatchDetailId) than the most recent reversal for this document, so
																a genuine duplicate post is still blocked but a post-after-Re-Open now creates fresh entries.
	28	 23/06/2026	 Moin Bloch   	Modify (Added IsBypassAccounting Flag to bypass Accounting Entry PN-16871)
	29	  23/Aug/2026	          Moin Bloch                    [PN-17606] - Modify (Added Intercompany Accounting – Affiliate Tagging & Mirrored GL Postings)

EXEC dbo.USP_BatchTriggerBasedonSOInvoiceNew
@DistributionMasterId=12,@ReferenceId=515,@ReferencePartId=252,@ReferencePieceId=252,@InvoiceId=252,
@StocklineId=0,@Qty=0,@Amount=0,@ModuleName=N'SO',@MasterCompanyId=1,@UpdateBy=N'ADMIN User'
exec [dbo].[USP_BatchTriggerBasedonSOInvoiceNew] 7,913,0,0,3400,0,0,0,'SO',1,'RAJESH GAMI',1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_BatchTriggerBasedonSOInvoiceNew]
	@DistributionMasterId BIGINT = NULL,
	@ReferenceId BIGINT = NULL,
	@ReferencePartId BIGINT = NULL,
	@ReferencePieceId BIGINT = NULL,
	@InvoiceId BIGINT = NULL,
	@StocklineId BIGINT = NULL,
	@Qty INT = 0,
	@Amount DECIMAL(18,2),
	@ModuleName VARCHAR(200),
	@MasterCompanyId INT,
	@UpdateBy VARCHAR(200),
	@LegalEntityId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		DECLARE @JournalTypeId INT
	    DECLARE @JournalTypeCode VARCHAR(200) 
	    DECLARE @JournalBatchHeaderId BIGINT
	    DECLARE @GlAccountId INT
	    DECLARE @StatusId INT
	    DECLARE @StatusName VARCHAR(200)
	    DECLARE @StartsFrom VARCHAR(200)='00'
	    DECLARE @CurrentNumber INT
	    DECLARE @GlAccountName VARCHAR(200) 
	    DECLARE @GlAccountNumber VARCHAR(200) 
	    DECLARE @JournalTypename VARCHAR(200) 
	    DECLARE @Distributionname VARCHAR(200) 
	    DECLARE @CustomerId BIGINT
	    DECLARE @ManagementStructureId BIGINT
	    DECLARE @CustomerName VARCHAR(200)
        DECLARE @SalesOrderNumber VARCHAR(200) 
        DECLARE @MPNName VARCHAR(200) 
	    DECLARE @PiecePNId BIGINT
        DECLARE @PiecePN VARCHAR(200) 
        DECLARE @ItemmasterId BIGINT
	    DECLARE @PieceItemmasterId BIGINT
	    DECLARE @CustRefNumber VARCHAR(200)
	    DECLARE @LineNumber INT=1
	    DECLARE @TotalDebit DECIMAL(18,2)=0
	    DECLARE @TotalCredit DECIMAL(18,2)=0
	    DECLARE @TotalBalance DECIMAL(18,2)=0
	    DECLARE @UnitPrice DECIMAL(18,2)=0
	    DECLARE @LaborHrs DECIMAL(18,2)=0
	    DECLARE @DirectLaborCost DECIMAL(18,2)=0
	    DECLARE @OverheadCost DECIMAL(18,2)=0
	    DECLARE @partId BIGINT=0
		DECLARE @batch VARCHAR(100)
		DECLARE @AccountingPeriod VARCHAR(100)
		DECLARE @AccountingPeriodId BIGINT=0
		DECLARE @CurrentPeriodId BIGINT=0
		DECLARE @Currentbatch VARCHAR(100)
	    DECLARE @LastMSLevel VARCHAR(200)
		DECLARE @AllMSlevels VARCHAR(max)
		DECLARE @DistributionSetupId INT=0
		DECLARE @IsAccountByPass BIT=0
		DECLARE @DistributionCode VARCHAR(200)
		DECLARE @InvoiceTotalCost DECIMAL(18,2)=0
	    DECLARE @MaterialCost DECIMAL(18,2)=0
	    DECLARE @LaborOverHeadCost DECIMAL(18,2)=0
	    DECLARE @FreightCost DECIMAL(18,2)=0
		DECLARE @InvoiceNo VARCHAR(100)
		DECLARE @MiscChargesCost DECIMAL(18,2)=0
		DECLARE @LaborCost DECIMAL(18,2)=0
		DECLARE @InvoiceLaborCost DECIMAL(18,2)=0
		DECLARE @RevenuWO DECIMAL(18,2)=0
		DECLARE @CurrentManagementStructureId BIGINT=0
		DECLARE @JournalBatchDetailId BIGINT=0
	    DECLARE @currentNo AS BIGINT = 0;
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @JournalTypeNumber VARCHAR(100);
		DECLARE @CustomerTypeId INT=0;
		DECLARE @CustomerTypeName VARCHAR(50);
		DECLARE @StocklineNumber VARCHAR(50);
		DECLARE @FreightBillingMethodId INT;
		DECLARE @ChargesBillingMethodId INT;
		DECLARE @CommonJournalBatchDetailId BIGINT=0;
		DECLARE @PartGLAccountId BIGINT;
		DECLARE @STKGlAccountId INT;
		DECLARE @STKGlAccountName VARCHAR(200);
		DECLARE @STKGlAccountNumber VARCHAR(200);
		DECLARE @PartUnitSalesPrices DECIMAL(18,2);
		DECLARE @STKId BIGINT;
		DECLARE @CrDrType BIGINT;
		DECLARE @ValidDistribution BIT = 1;
		DECLARE @ManagementModuleId INT = 0;
		DECLARE @AccountMSModuleId INT = 0
		DECLARE @LotId BIGINT=0;
		DECLARE @LotNumber VARCHAR(50);
		DECLARE @IsAutoPost INT = 0;
		DECLARE @IsBatchGenerated INT = 0;
		DECLARE @LocalCurrencyCode VARCHAR(20) = '';
		DECLARE @ForeignCurrencyCode VARCHAR(20) = '';
		DECLARE @FXRate DECIMAL(9,2) = 1;	--Default Value set to : 1
		DECLARE @ReferenceModule VARCHAR(100) = 'SO';
		DECLARE @IsBypassAccounting  BIT = 0;
		DECLARE @CustomerAffiliationId BIGINT = 0
		DECLARE @CustomerLegalEntityId BIGINT = 0

		DECLARE @GLStocklineId BIGINT = 0;
		DECLARE @InventoryToBillGLAccId BIGINT = 0;
		DECLARE @InventoryGLAccId BIGINT = 0;
		DECLARE @COGSSalesOrderGLAccId BIGINT = 0;
		DECLARE @RevenueSoGLAccId BIGINT = 0;
		DECLARE @soModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')
		SELECT @IsAccountByPass =IsAccountByPass FROM dbo.MasterCompany WITH(NOLOCK)  WHERE MasterCompanyId= @MasterCompanyId
	    SELECT @DistributionCode =DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK)  WHERE ID= @DistributionMasterId
	    SELECT @StatusId =Id,@StatusName=name FROM dbo.BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
	    SELECT top 1 @JournalTypeId =JournalTypeId FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId = @DistributionMasterId
	    SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
	    SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM dbo.JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
		SELECT @CurrentManagementStructureId = ManagementStructureId FROM dbo.Employee WITH(NOLOCK) WHERE CONCAT(TRIM(REPLACE([FirstName], ' ', '')),'',TRIM(REPLACE([LastName], ' ', ''))) IN (replace(@UpdateBy, ' ', '')) and MasterCompanyId = @MasterCompanyId
		SELECT @ManagementModuleId = ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'SalesOrder'
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
		SELECT @CustomerAffiliationId = [CustomerAffiliationId] FROM [dbo].[CustomerAffiliation] WITH(NOLOCK) WHERE [Description] = 'Affiliate'


		IF((@JournalTypeCode ='SOI' or @JournalTypeCode ='SOS') and @IsAccountByPass=0)
		BEGIN

			SELECT @SalesOrderNumber = SalesOrderNumber,
			       @CustomerId=CustomerId,
				   @CustomerName= CustomerName,
				   @CustRefNumber=CustomerReference,
				   @ManagementStructureId =ManagementStructureId,
			       @FreightBillingMethodId = FreightBilingMethodId,
				   @ChargesBillingMethodId=ChargesBilingMethodId,
				   @LocalCurrencyCode = ISNULL(CF.Code, ''),
				   @ForeignCurrencyCode = ISNULL(CL.Code, ''),
				   @FXRate = ISNULL(SO.ForeignExchangeRate, @FXRate)
			  FROM dbo.SalesOrder SO WITH(NOLOCK)
			  LEFT JOIN [DBO].[Currency] CL WITH(NOLOCK) ON CL.CurrencyId = SO.ReportCurrencyId
			  LEFT JOIN [DBO].[Currency] CF WITH(NOLOCK) ON CF.CurrencyId = SO.FunctionalCurrencyId
			  WHERE SalesOrderId=@ReferenceId
			
			SELECT @CustomerTypeId = c.CustomerAffiliationId,
			       @CustomerTypeName = caf.[Description],
				   @CustomerLegalEntityId = c.[LegalEntityId]
			  FROM dbo.Customer c WITH(NOLOCK)
			 INNER JOIN dbo.CustomerAffiliation caf WITH(NOLOCK) ON c.CustomerAffiliationId = caf.CustomerAffiliationId 
			 WHERE c.CustomerId=@CustomerId;
			
			SET @partId = @ReferencePartId;
	       
		    SELECT @ItemmasterId = SOP.ItemMasterId,
			       @StockLineId = STK.StockLineId
			   FROM dbo.SalesOrderPartV1 SOP WITH(NOLOCK)
			   LEFT JOIN dbo.SalesOrderStocklineV1 STK WITH(NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
			   WHERE SOP.SalesOrderId = @ReferenceId and SOP.SalesOrderPartId = @partId
	        
			SELECT @MPNName = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId 
	        

			 SELECT @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels FROM dbo.SalesOrderManagementStructureDetails  WITH(NOLOCK)  WHERE ReferenceID=@ReferenceId AND ModuleID = @ManagementModuleId
			
			SELECT @StocklineNumber= STK.[StockLineNumber],
			       @LotId = STK.[LotId], 
				   @LotNumber = LO.[LotNumber]				   
			  FROM [dbo].[Stockline] STK WITH(NOLOCK) 
			  LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK) ON  LO.LotId = STK.LotId  
			  WHERE StockLineId=@StockLineId

			SELECT TOP 1 @AccountingPeriodId = AccountingCalendarId, @AccountingPeriod = PeriodName 
			FROM dbo.AccountingCalendar WITH(NOLOCK) 
			WHERE IsDeleted = 0 AND LegalEntityId = @LegalEntityId AND MasterCompanyId = @MasterCompanyId AND CAST(GETUTCDATE() as date) >= CAST(FromDate as date) and  CAST(GETUTCDATE() as date) <= CAST(ToDate as date)

			--SELECT TOP 1 @AccountingPeriodId = acc.AccountingCalendarId, @AccountingPeriod = PeriodName 
			--FROM dbo.EntityStructureSetup est WITH(NOLOCK) 
			--INNER JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
			--INNER JOIN dbo.AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
			--WHERE est.EntityStructureId = @CurrentManagementStructureId AND acc.MasterCompanyId = @MasterCompanyId  and CAST(GETUTCDATE() as date) >= CAST(FromDate as date) and  CAST(GETUTCDATE() as date) <= CAST(ToDate as date)
		             
			SET @ReferencePartId=@partId	
			SELECT @InvoiceNo=InvoiceNo  FROM 
			       dbo.BillingInvoicing  WITH(NOLOCK)
			WHERE BillingInvoicingId=@InvoiceId AND ISNULL(IsPerformaInvoice,0) = 0 AND ISNULL(IsVersionIncrease,0) = 0 AND ModuleId = @soModuleId

			IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCodePrefixes
			END
				
			CREATE TABLE #tmpCodePrefixes
			(
					ID BIGINT NOT NULL IDENTITY, 
					CodePrefixId BIGINT NULL,
					CodeTypeId BIGINT NULL,
					CurrentNumber BIGINT NULL,
					CodePrefix VARCHAR(50) NULL,
					CodeSufix VARCHAR(50) NULL,
					StartsFrom BIGINT NULL,
			)

			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
			FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
			BEGIN 
				SELECT 
					@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
						ELSE CAST(StartsFrom AS BIGINT) + 1 END 
				FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId

				SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN
				ROLLBACK TRAN;
			END


			IF(UPPER(@DistributionCode) = UPPER('SOINVOICE'))
			BEGIN

				IF NOT EXISTS (
					SELECT 1 FROM [dbo].[SalesOrderBatchDetails] SOD WITH(NOLOCK)
					INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON BD.[JournalBatchDetailId] = SOD.[JournalBatchDetailId]
					WHERE SOD.[SalesOrderId] = @ReferenceId AND SOD.[DocumentId] = @InvoiceId
					  AND SOD.[JournalBatchDetailId] > ISNULL(
							(SELECT MAX(SOD2.[JournalBatchDetailId])
							 FROM [dbo].[SalesOrderBatchDetails] SOD2 WITH(NOLOCK)
							 INNER JOIN [dbo].[BatchDetails] BD2 WITH(NOLOCK) ON BD2.[JournalBatchDetailId] = SOD2.[JournalBatchDetailId]
							 WHERE SOD2.[SalesOrderId] = @ReferenceId AND SOD2.[DocumentId] = @InvoiceId AND ISNULL(BD2.[IsReversedJE],0) = 1),
							0)
				)
				BEGIN

				IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId]=@MasterCompanyId AND ISNULL([GlAccountId],0) = 0 AND ISNULL([IsManualText],0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END
				
				IF(@ValidDistribution = 1)
				BEGIN
					DECLARE @UnitSalesPricePerUnit DECIMAL(18,2)=0;
					DECLARE @InoiceGrandTotal DECIMAL(18,2)=0;
					DECLARE @AccountsReceivablesAmount DECIMAL(18,2)=0;
					DECLARE @UnitSalesPrice DECIMAL(18,2)=0;
					DECLARE @PartUnitSalesPrice DECIMAL(18,2)=0;
					DECLARE @COGSDifference DECIMAL(18,2)=0;
					DECLARE @SalesTax DECIMAL(18,2)=0;
					DECLARE @OtherTax DECIMAL(18,2)=0;
					DECLARE @TotalTax DECIMAL(18,2)=0;
					DECLARE @SalesTotal DECIMAL(18,2)=0;
					DECLARE @InvoiceDate DATETIME2(7) = NULL;

					
					IF OBJECT_ID(N'tempdb..#tmpSOPartIds') IS NOT NULL
					BEGIN
						DROP TABLE #tmpSOPartIds
					END
					CREATE TABLE #tmpSOPartIds (
							SubReferenceId BIGINT
					);

					INSERT INTO #tmpSOPartIds (SubReferenceId)
						SELECT DISTINCT BII.SubReferenceId  FROM [dbo].BillingInvoicing SOBI WITH(NOLOCK) 
					 INNER JOIN dbo.BillingInvoicingItems BII WITH(NOLOCK) ON SOBI.BillingInvoicingId = BII.BillingInvoicingId
					 WHERE SOBI.BillingInvoicingId=@InvoiceId 
					 AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND ISNULL(SOBI.[IsVersionIncrease],0) = 0  AND ISNULL(BII.IsPerformaInvoice,0) = 0 AND ISNULL(BII.[IsVersionIncrease],0) = 0

					--SELECT @MiscChargesCost =SUM(ISNULL(MiscCharges,0)),@FreightCost =SUM(ISNULL(Freight,0)) FROM SalesOrderPartCost WHERE SalesOrderPartId in(SELECT SubReferenceId FROM #tmpSOPartIds)
					SELECT @MiscChargesCost =SUM(ISNULL(MiscChargesCostPlus,0)),@FreightCost =SUM(ISNULL(FreightCostPlus,0)) FROM DBO.BillingInvoicingItems WITH(NOLOCK) 
					WHERE ModuleId =@soModuleId AND SubReferenceId in(SELECT SubReferenceId FROM #tmpSOPartIds)
						  AND BillingInvoicingId = @InvoiceId AND ISNULL(IsPerformaInvoice,0) = 0  AND ISNULL([IsVersionIncrease],0) = 0
					 SELECT @SalesTotal = SUM(ISNULL(PartCost,0))
					 FROM [dbo].BillingInvoicing SOBI WITH(NOLOCK) 
					 INNER JOIN dbo.BillingInvoicingItems BII WITH(NOLOCK) ON SOBI.BillingInvoicingId = BII.BillingInvoicingId
					 WHERE SOBI.BillingInvoicingId=@InvoiceId 

					 AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND ISNULL(SOBI.[IsVersionIncrease],0) = 0  AND ISNULL(BII.IsPerformaInvoice,0) = 0 AND ISNULL(BII.[IsVersionIncrease],0) = 0
					SELECT 
					       @InoiceGrandTotal = ISNULL(SubTotal,0),
						   @SalesTax = ISNULL(SalesTax,0),
						   @OtherTax = ISNULL(OtherTax,0),
						   @InvoiceDate = [InvoiceDate],
						   @LocalCurrencyCode = ISNULL(CL.Code, @LocalCurrencyCode),
						   @ForeignCurrencyCode = ISNULL(CL.Code, @ForeignCurrencyCode)
					 FROM [dbo].[BillingInvoicing] SOBI WITH(NOLOCK) 
					 LEFT JOIN [DBO].[Currency] CL WITH(NOLOCK) ON CL.CurrencyId = SOBI.CurrencyId 
					 WHERE SOBI.BillingInvoicingId=@InvoiceId 
					 AND ISNULL(IsPerformaInvoice,0) = 0 AND ISNULL([IsVersionIncrease],0) = 0 AND SOBI.ModuleId = @soModuleId

					SET @TotalTax = (@SalesTax + @OtherTax);

					SELECT @PartUnitSalesPrice = SUM(ISNULL(sosc.UnitCostExtended, 0))
					FROM [dbo].[BillingInvoicing] soi WITH(NOLOCK)
					INNER JOIN [dbo].[BillingInvoicingItems] soit WITH(NOLOCK) ON soi.BillingInvoicingId = soit.BillingInvoicingId AND ISNULL(soit.IsPerformaInvoice,0) = 0 AND ISNULL(soit.[IsVersionIncrease],0) = 0
					INNER JOIN [dbo].[SalesOrderStocklineV1] sop WITH(NOLOCK) ON soit.StockLineId = sop.StockLineId --soit.SalesOrderPartId = sop.SalesOrderPartId
					INNER JOIN [dbo].[SalesOrderStockLineCost] sosc WITH(NOLOCK) ON sosc.SalesOrderStocklineId = sop.SalesOrderStocklineId
					WHERE soi.BillingInvoicingId = @InvoiceId AND ISNULL(soi.IsPerformaInvoice,0) = 0 AND ISNULL(soi.IsVersionIncrease,0) = 0 AND soi.ModuleId = @soModuleId


					SELECT TOP 1 @StocklineId = stk.[StockLineId],
					            @partId = sop.[ItemMasterId],
							 @MPNName = itm.[partnumber]								
					FROM [dbo].[BillingInvoicing] soi WITH(NOLOCK)
					INNER JOIN [dbo].[BillingInvoicingItems] soit WITH(NOLOCK) ON soi.BillingInvoicingId = soit.BillingInvoicingId AND ISNULL(soit.IsPerformaInvoice,0) = 0 AND ISNULL(soit.[IsVersionIncrease],0) = 0
					INNER JOIN [dbo].[SalesOrderPartV1] sop WITH(NOLOCK) ON soit.SubReferenceId = sop.SalesOrderPartId
					INNER JOIN [dbo].[SalesOrderStocklineV1] stk WITH(NOLOCK) ON sop.SalesOrderPartId = stk.SalesOrderPartId AND soit.StockLineId = stk.StockLineId
					LEFT JOIN [dbo].[ItemMaster] itm WITH(NOLOCK) ON itm.[ItemMasterId] = sop.[ItemMasterId]					

					 WHERE soi.BillingInvoicingId = @InvoiceId 
					AND soit.SubReferenceId = @ReferencePartId
					AND ISNULL(soi.IsPerformaInvoice,0) = 0 AND ISNULL(soi.IsVersionIncrease,0) = 0 AND soi.ModuleId = @soModuleId

					SELECT @LotId = SL.LotId,
						   @LotNumber = LO.[LotNumber],						  
						   @StocklineNumber = SL.[StockLineNumber]
					  FROM [dbo].[Stockline] SL WITH(NOLOCK)					 
					  LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK) ON  LO.LotId = SL.LotId  
					  WHERE SL.[StockLineId] = @StocklineId;

					SELECT top 1 @GLStocklineId = soi.[StockLineId] 
					FROM [dbo].[BillingInvoicingItems] soi WITH(NOLOCK) 
					WHERE soi.[BillingInvoicingId] = @InvoiceId AND soi.ModuleId = @soModuleId
					PRINT @GLStocklineId
					PRINT '---@GLStocklineId---'
					SELECT @StocklineNumber = SL.[StockLineNumber],
						   @InventoryToBillGLAccId = SL.InventoryToBillGLAccId, --For INVENTORY TO BILL Distribution (Shipping & Billing)
						   @InventoryGLAccId = SL.GLAccountId, -- For PARTS INVENTORY Distribution (Shipping)
						   @COGSSalesOrderGLAccId = SL.COGS_SalesOrderGLAccId,  -- For COGS EXc Sales Order Distribution (Billing)
						   @RevenueSoGLAccId = SL.RevenueSoGLAccId -- For Revenue EXc SO Distribution (Billing)
					  FROM [dbo].[Stockline] SL WITH(NOLOCK)					 
					  WHERE SL.[StockLineId] = @GLStocklineId;
					  			PRINT @RevenueSoGLAccId
					PRINT '---@@RevenueSoGLAccId---'
					SET @COGSDifference = (@PartUnitSalesPrice - @InoiceGrandTotal);
					 
					SET @RevenuWO = @InvoiceTotalCost - (@FreightCost + @MiscChargesCost + @SalesTax);

					SET @AccountsReceivablesAmount = (@SalesTotal + @FreightCost + @MiscChargesCost + @SalesTax + @OtherTax);
					-----Revenue - SO------
					PRINT '	-----Revenue - SO------'
					PRINT @SalesTotal
					IF(@SalesTotal > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId=ID,
						             @DistributionName=Name,
									 @JournalTypeId =JournalTypeId,
									 @GlAccountId=GlAccountId,
									 @GlAccountNumber=GlAccountNumber,
									 @GlAccountName=GlAccountName,
									 @CrDrType = CRDRType,
									 @IsAutoPost = ISNULL(IsAutoPost,0),
									 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
						FROM dbo.DistributionSetup WITH(NOLOCK)  
						WHERE UPPER(DistributionSetupCode) =UPPER('REVENUESALESORDER') 
						AND DistributionMasterId=@DistributionMasterId 
						AND MasterCompanyId = @MasterCompanyId;

						
						--GET GL Accounting Data from GLAccout based on stockline
						SELECT @GlAccountId = [GLAccountId],
							   @GlAccountNumber = [AccountCode],
							   @GlAccountName = [AccountName]
						FROM [dbo].[GLAccount] WITH(NOLOCK)
						WHERE [GLAccountId] = @RevenueSoGLAccId
						AND [MasterCompanyId] = @MasterCompanyId;
							
						-- Exclude batch headers that only hold a Re-Open accounting reversal (see USP_ReverseSOInvoiceAccountingEntry) -
					-- those match the same Type/Company/Date/Status/CustomerType keys as a normal day's posting batch, so
					-- without this exclusion a same-day re-invoice after a Re-Open was gluing its fresh (non-reversal) lines
					-- onto the reversal's batch header instead of getting its own new sequential batch.
					IF NOT EXISTS(SELECT BH.JournalBatchHeaderId FROM dbo.BatchHeader BH WITH(NOLOCK)  WHERE BH.JournalTypeId= @JournalTypeId and BH.MasterCompanyId=@MasterCompanyId and  CAST(BH.EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE) and BH.StatusId=@StatusId AND BH.CustomerTypeId=@CustomerTypeId AND NOT EXISTS (SELECT 1 FROM dbo.BatchDetails BDChk WITH(NOLOCK) WHERE BDChk.JournalBatchHeaderId = BH.JournalBatchHeaderId AND ISNULL(BDChk.IsReversedJE,0) = 1))
						BEGIN
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK))
							BEGIN
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
				   							ELSE  1 END 
				   					FROM dbo.BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

								IF(CAST(@Currentbatch AS BIGINT) >99)
								BEGIN

									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   							ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE IF(CAST(@Currentbatch AS BIGINT) >9)
								BEGIN

									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   							ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   							ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END			               
							END

							SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 
							SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as VARCHAR(100)) as VARCHAR(100))
					
				          
							INSERT INTO [dbo].[BatchHeader]
										([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module],[CustomerTypeId])
							VALUES
										(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,'SOI',@CustomerTypeId);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
							UPDATE dbo.BatchHeader SET CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId		   

						END
						ELSE 
						BEGIN
							SELECT @JournalBatchHeaderId=BH.JournalBatchHeaderId,@CurrentPeriodId=isnull(BH.AccountingPeriodId,0) FROM dbo.BatchHeader BH WITH(NOLOCK)  WHERE BH.JournalTypeId= @JournalTypeId and BH.StatusId=@StatusId and BH.CustomerTypeId=@CustomerTypeId AND NOT EXISTS (SELECT 1 FROM dbo.BatchDetails BDChk WITH(NOLOCK) WHERE BDChk.JournalBatchHeaderId = BH.JournalBatchHeaderId AND ISNULL(BDChk.IsReversedJE,0) = 1)
							SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   									FROM dbo.BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
							IF(@CurrentPeriodId =0)
							BEGIN
								UPDATE dbo.BatchHeader SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END

							SET @IsBatchGenerated = 1;
						END
							
						INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], 
						[IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[AccountingPeriodId],[AccountingPeriod])
							VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, @InvoiceDate, GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, 0, 0, 0, @ModuleName, NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0,@AccountingPeriodId,@AccountingPeriod)
						SET @JournalBatchDetailId=SCOPE_IDENTITY()
						
						IF(@IsBypassAccounting = 0)
						BEGIN

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @SalesTotal ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @SalesTotal END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber,@SalesOrderNumber,@CustomerName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceId,@ReferenceModule)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
											   
						INSERT INTO [dbo].[SalesOrderBatchDetails]
						(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
						VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)

						END
					
					END
					-----Revenue - SO------

					-----Misc Charges------
					IF(@MiscChargesCost >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,
						             @DistributionName=Name,
									 @JournalTypeId =JournalTypeId,
									 @GlAccountId=GlAccountId,
									 @GlAccountNumber=GlAccountNumber,
									 @GlAccountName=GlAccountName,
									 @CrDrType = CRDRType,
									 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
						FROM dbo.DistributionSetup WITH(NOLOCK)  
						WHERE UPPER(DistributionSetupCode) = UPPER('REVENUEMISCCHARGE') 
						AND DistributionMasterId=@DistributionMasterId
						AND MasterCompanyId = @MasterCompanyId	
						
						IF(@IsBypassAccounting = 0)
						BEGIN
						
						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @MiscChargesCost ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @MiscChargesCost END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SalesOrderNumber,@CustomerName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceId,@ReferenceModule)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[SalesOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
						
						END					
					END
					-----Misc Charges------

					-----Freight------
					IF(@FreightCost >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,
						             @DistributionName=Name,
									 @JournalTypeId =JournalTypeId,
									 @GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType,
									 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
						FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('REVENUEFREIGHT') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
						
						IF(@IsBypassAccounting = 0)
						BEGIN

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @FreightCost ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @FreightCost END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SalesOrderNumber,@CustomerName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceId,@ReferenceModule)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 


						INSERT INTO [dbo].[SalesOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
						
						END

					END

					-----Freight------

					-----Sales Tax------
					IF(@SalesTax > 0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType,
					                 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
						FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('SALESTAXPAYABLE') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
						
						IF(@IsBypassAccounting = 0)
						BEGIN

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @SalesTax ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @SalesTax END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SalesOrderNumber,@CustomerName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceId,@ReferenceModule)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[SalesOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
					
						END
					END
					-----Sales Tax------

					-----Other Tax------
					IF(@OtherTax > 0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType,
					                 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
						FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('TAXPAYABLEOTHER') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
						
						IF(@IsBypassAccounting = 0)
						BEGIN

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @OtherTax ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @OtherTax END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SalesOrderNumber,@CustomerName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceId,@ReferenceModule)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[SalesOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
					
						END
					END
					-----Other Tax------

					----Accounts Receivables - Trade----------

					IF(@AccountsReceivablesAmount >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType,
					                 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
						FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('ACCOUNTSRECEIVABLESTRADE') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
						
						IF(@IsBypassAccounting = 0)
						BEGIN

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @AccountsReceivablesAmount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @AccountsReceivablesAmount END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber,@SalesOrderNumber,@CustomerName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceId,@ReferenceModule)
				      
						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
				      
						INSERT INTO [dbo].[SalesOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
						END
					END

					----Accounts Receivables - Trade----------

					----GL Account wise COGS-Parts and Inventory-Parts Entry----
					DECLARE @SalesOrderPartDetailsCursor AS CURSOR;
					SET @SalesOrderPartDetailsCursor = CURSOR FAST_FORWARD FOR	
					SELECT STL.GLAccountId as PartGLAccountId FROM dbo.BillingInvoicing soi WITH(NOLOCK)
					INNER JOIN dbo.BillingInvoicingItems soit WITH(NOLOCK) ON soi.BillingInvoicingId = soit.BillingInvoicingId AND ISNULL(soit.IsPerformaInvoice,0) = 0 AND ISNULL(soit.IsVersionIncrease,0) = 0
					INNER JOIN dbo.SalesOrderPartV1 sop WITH(NOLOCK) ON soit.SubReferenceId = sop.SalesOrderPartId
					INNER JOIN dbo.SalesOrderStocklineV1 stk WITH(NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId AND soit.StockLineId = stk.StockLineId
					INNER JOIN dbo.Stockline STL WITH(NOLOCK) ON stk.StockLineId = STL.StockLineId
					WHERE soi.BillingInvoicingId=@InvoiceId AND ISNULL(soi.IsPerformaInvoice,0) = 0 AND ISNULL(soi.IsVersionIncrease,0) = 0
					GROUP BY STL.GLAccountId
					
					OPEN @SalesOrderPartDetailsCursor;
					FETCH NEXT FROM @SalesOrderPartDetailsCursor INTO @PartGLAccountId;
					WHILE @@FETCH_STATUS = 0
					BEGIN
						SELECT @PartUnitSalesPrices = SUM(ISNULL(sosc.UnitCost,0) * ISNULL(soit.QtyBilled,0)) FROM dbo.BillingInvoicing soi WITH(NOLOCK)
						INNER JOIN dbo.BillingInvoicingItems soit WITH(NOLOCK) ON soi.BillingInvoicingId = soit.BillingInvoicingId AND ISNULL(soit.IsPerformaInvoice,0) = 0 AND ISNULL(soit.IsVersionIncrease,0) = 0
						--INNER JOIN SalesOrderPart sop WITH(NOLOCK) ON soit.SalesOrderPartId = sop.SalesOrderPartId
						INNER JOIN dbo.SalesOrderStocklineV1 sop WITH(NOLOCK) ON soit.SubReferenceId = sop.SalesOrderPartId AND sop.StockLineId = soit.StockLineId
						INNER JOIN dbo.Stockline STL WITH(NOLOCK) ON SOP.StockLineId = STL.StockLineId
						INNER JOIN dbo.SalesOrderStockLineCost sosc WITH(NOLOCK) ON sosc.SalesOrderStocklineId = sop.SalesOrderStocklineId
						WHERE soi.BillingInvoicingId=@InvoiceId AND ISNULL(soi.IsPerformaInvoice,0) = 0 AND ISNULL(soi.IsVersionIncrease,0) = 0 
						AND STL.GLAccountId=@PartGLAccountId;

						SELECT TOP 1 @STKId = STL.StockLineId,
									 @InventoryToBillGLAccId = STL.InventoryToBillGLAccId, --For INVENTORY TO BILL Distribution (Shipping & Billing)
									 @InventoryGLAccId = STL.GLAccountId, -- For PARTS INVENTORY Distribution (Shipping)
									 @COGSSalesOrderGLAccId = STL.COGS_SalesOrderGLAccId,  -- For COGS Sales Order Distribution (Billing)
									 @RevenueSoGLAccId = STL.RevenueSoGLAccId -- For Revenue SO Distribution (Billing)
						FROM BillingInvoicing soi WITH(NOLOCK)
						INNER JOIN BillingInvoicingItems soit WITH(NOLOCK) ON soi.BillingInvoicingId = soit.BillingInvoicingId AND ISNULL(soit.IsPerformaInvoice,0) = 0 AND ISNULL(soit.IsVersionIncrease,0) = 0
						--INNER JOIN SalesOrderPart sop WITH(NOLOCK) ON soit.SalesOrderPartId = sop.SalesOrderPartId
						INNER JOIN SalesOrderStocklineV1 sop WITH(NOLOCK) ON soit.SubReferenceId = sop.SalesOrderPartId AND soit.StockLineId = sop.StockLineId
						INNER JOIN DBO.Stockline STL WITH(NOLOCK) ON SOP.StockLineId = STL.StockLineId
						WHERE soi.BillingInvoicingId=@InvoiceId AND ISNULL(soi.IsPerformaInvoice,0) = 0 
						AND ISNULL(soi.IsVersionIncrease,0) = 0 
						AND STL.GLAccountId=@PartGLAccountId;

						SELECT TOP 1 @STKGlAccountId=SL.GLAccountId,@STKGlAccountNumber=GL.AccountCode,@STKGlAccountName=GL.AccountName FROM DBO.Stockline SL WITH(NOLOCK)
						INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId WHERE SL.StockLineId=@STKId;

						----COGS - Parts----
						IF(@PartUnitSalesPrices >0)
						BEGIN	
						
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType,
					                     @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
							FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('COGSPARTS') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
							

							--GET GL Accounting Data from GLAccout based on stockline
							SELECT @GlAccountId = [GLAccountId],
								   @GlAccountNumber = [AccountCode],
								   @GlAccountName = [AccountName]
							FROM [dbo].[GLAccount] WITH(NOLOCK)
							WHERE [GLAccountId] = @COGSSalesOrderGLAccId
							AND [MasterCompanyId] = @MasterCompanyId;

							IF(@IsBypassAccounting = 0)
							BEGIN

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @PartUnitSalesPrices ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @PartUnitSalesPrices END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber,@SalesOrderNumber,@CustomerName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceId,@ReferenceModule)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[SalesOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)

							END
						
						END
						----COGS - Parts----
						----Inventory - Parts----
						IF(@PartUnitSalesPrices >0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType,
					                     @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
							FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('INVENTORYPARTS') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
							 
							--GET GL Accounting Data from GLAccout based on stockline
							SELECT @GlAccountId = [GLAccountId],
								   @GlAccountNumber = [AccountCode],
								   @GlAccountName = [AccountName]
							FROM [dbo].[GLAccount] WITH(NOLOCK)
							WHERE [GLAccountId] = @InventoryToBillGLAccId
							AND [MasterCompanyId] = @MasterCompanyId;

							IF(@IsBypassAccounting = 0)
							BEGIN

				    		INSERT INTO [dbo].[CommonBatchDetails]
				    			(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
				    		VALUES
				    			(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,@InvoiceDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @PartUnitSalesPrices ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @PartUnitSalesPrices END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber,@SalesOrderNumber,@CustomerName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceId,@ReferenceModule)
						
							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
							
							INSERT INTO [dbo].[SalesOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
						
							END
						END
						----Inventory - Parts----

					FETCH NEXT FROM @SalesOrderPartDetailsCursor INTO @PartGLAccountId
					END
					CLOSE @SalesOrderPartDetailsCursor  
					DEALLOCATE @SalesOrderPartDetailsCursor
					----GL Account wise COGS-Parts and Inventory-Parts Entry----

					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit = SUM(DebitAmount), @TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
					UPDATE BatchDetails SET DebitAmount=@TotalDebit, CreditAmount=@TotalCredit,UpdatedDate = GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchDetailId=@JournalBatchDetailId

					SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	          
					SET @TotalBalance =@TotalDebit-@TotalCredit
					UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
					UPDATE [dbo].[BatchHeader] SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId

					--AutoPost Batch
					IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
					BEGIN
						EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
					END
					IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
					BEGIN
						EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
					END
				END

				END
			END

			IF(UPPER(@DistributionCode) = UPPER('SO_SHIPMENT'))
	        BEGIN				
				IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0 AND ISNULL([IsManualText],0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END
				IF(@ValidDistribution = 1)
				BEGIN	
					SELECT TOP 1 @IsAutoPost = ISNULL([IsAutoPost],0),
								 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
						    FROM dbo.DistributionSetup WITH(NOLOCK)  
						   WHERE UPPER(DistributionSetupCode) = UPPER('INVENTORYTOBILLSO') 
							 AND DistributionMasterId=@DistributionMasterId 
							 AND MasterCompanyId = @MasterCompanyId;


					SELECT @PartUnitSalesPrices = SUM(ISNULL(STKC.UnitCost, 0) * ISNULL(soit.QtyShipped, 0))
					FROM [dbo].[SalesOrderShipping] soi WITH(NOLOCK)
					INNER JOIN [dbo].[SalesOrderShippingItem] soit WITH(NOLOCK) ON soi.SalesOrderShippingId = soit.SalesOrderShippingId
					INNER JOIN [dbo].[SOPickTicket] SOPT WITH(NOLOCK) ON SOPT.SOPickTicketId = soit.SOPickTicketId
					INNER JOIN [dbo].[SalesOrderStocklineV1] stk WITH(NOLOCK) ON STK.SalesOrderStocklineId = SOPT.SalesOrderPartStocklineId
					INNER JOIN [dbo].[Stockline] STL WITH(NOLOCK) ON stk.StockLineId = STL.StockLineId
					INNER JOIN [dbo].[SalesOrderStockLineCost] STKC WITH(NOLOCK) ON STKC.SalesOrderStocklineId = stk.SalesOrderStocklineId
					WHERE soi.SalesOrderShippingId=@InvoiceId
					
					IF(@PartUnitSalesPrices > 0)
					BEGIN
						-- Exclude batch headers that only hold a Re-Open accounting reversal (see USP_ReverseSOInvoiceAccountingEntry) -
					-- those match the same Type/Company/Date/Status/CustomerType keys as a normal day's posting batch, so
					-- without this exclusion a same-day re-invoice after a Re-Open was gluing its fresh (non-reversal) lines
					-- onto the reversal's batch header instead of getting its own new sequential batch.
					IF NOT EXISTS(SELECT BH.JournalBatchHeaderId FROM dbo.BatchHeader BH WITH(NOLOCK)  WHERE BH.JournalTypeId= @JournalTypeId and BH.MasterCompanyId=@MasterCompanyId and  CAST(BH.EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE) and BH.StatusId=@StatusId AND BH.CustomerTypeId=@CustomerTypeId AND NOT EXISTS (SELECT 1 FROM dbo.BatchDetails BDChk WITH(NOLOCK) WHERE BDChk.JournalBatchHeaderId = BH.JournalBatchHeaderId AND ISNULL(BDChk.IsReversedJE,0) = 1))
						BEGIN
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK))
							BEGIN
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN

								SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
				   							ELSE  1 END 
				   					FROM dbo.BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

								IF(CAST(@Currentbatch AS BIGINT) >99)
								BEGIN

									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   							ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE IF(CAST(@Currentbatch AS BIGINT) >9)
								BEGIN

									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   							ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
				   							ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 

								END
			               
							END

							SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 
							SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as VARCHAR(100)) as VARCHAR(100))
					
				          
							INSERT INTO [dbo].[BatchHeader]
										([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module],[CustomerTypeId])
							VALUES
										(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,'SOI',@CustomerTypeId);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
							UPDATE dbo.BatchHeader SET CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId		   
						END
						ELSE 
						BEGIN
							SELECT @JournalBatchHeaderId=BH.JournalBatchHeaderId,@CurrentPeriodId=isnull(BH.AccountingPeriodId,0) FROM dbo.BatchHeader BH WITH(NOLOCK)  WHERE BH.JournalTypeId= @JournalTypeId and BH.StatusId=@StatusId and BH.CustomerTypeId=@CustomerTypeId AND NOT EXISTS (SELECT 1 FROM dbo.BatchDetails BDChk WITH(NOLOCK) WHERE BDChk.JournalBatchHeaderId = BH.JournalBatchHeaderId AND ISNULL(BDChk.IsReversedJE,0) = 1)
							SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   									FROM dbo.BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
							IF(@CurrentPeriodId =0)
							BEGIN
								UPDATE dbo.BatchHeader SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END

							SET @IsBatchGenerated = 1;
						END
						INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], 
							[IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[AccountingPeriodId],[AccountingPeriod])
						VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), @JournalTypeId, @JournalTypename, 1, 0, 0, 0, @ModuleName, NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0,@AccountingPeriodId,@AccountingPeriod)
						
						SET @JournalBatchDetailId=SCOPE_IDENTITY()
					END

					----GL Account wise COGS-Parts and Inventory-Parts Entry----
					DECLARE @SalesOrderPartDetailsCursor1 AS CURSOR;
					SET @SalesOrderPartDetailsCursor1 = CURSOR FAST_FORWARD FOR	
					SELECT STL.GLAccountId as PartGLAccountId 
					FROM [dbo].[SalesOrderShipping] soi WITH(NOLOCK)
					INNER JOIN [dbo].[SalesOrderShippingItem] soit WITH(NOLOCK) ON soi.SalesOrderShippingId = soit.SalesOrderShippingId
					INNER JOIN [dbo].[SalesOrderPartV1] sop WITH(NOLOCK) ON soit.SalesOrderPartId = sop.SalesOrderPartId
					INNER JOIN [dbo].[SalesOrderStocklineV1] stk WITH(NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
					INNER JOIN [dbo].[Stockline] STL WITH(NOLOCK) ON stk.StockLineId = STL.StockLineId
					WHERE soi.[SalesOrderShippingId] = @InvoiceId GROUP BY STL.GLAccountId

					OPEN @SalesOrderPartDetailsCursor1;
					FETCH NEXT FROM @SalesOrderPartDetailsCursor1 INTO @PartGLAccountId;
					WHILE @@FETCH_STATUS = 0
					BEGIN
						SELECT @PartUnitSalesPrices = SUM(ISNULL(STKC.UnitCost, 0) * ISNULL(soit.QtyShipped, 0))
						FROM [dbo].[SalesOrderShipping] soi WITH(NOLOCK)
						INNER JOIN [dbo].[SalesOrderShippingItem] soit WITH(NOLOCK) ON soi.SalesOrderShippingId = soit.SalesOrderShippingId
						INNER JOIN [dbo].[SOPickTicket] sopt WITH(NOLOCK) ON sopt.SOPickTicketId = soit.SOPickTicketId
						INNER JOIN [dbo].[SalesOrderPartV1] sop WITH(NOLOCK) ON soit.SalesOrderPartId = sop.SalesOrderPartId
						INNER JOIN [dbo].[SalesOrderStocklineV1] stk WITH(NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId AND stk.SalesOrderStocklineId = sopt.SalesOrderPartStocklineId
						INNER JOIN [dbo].[Stockline] STL WITH(NOLOCK) ON stk.StockLineId = STL.StockLineId
						INNER JOIN [dbo].[SalesOrderStockLineCost] STKC WITH(NOLOCK) ON STKC.SalesOrderStocklineId = stk.SalesOrderStocklineId
						WHERE soi.SalesOrderShippingId=@InvoiceId AND STL.GLAccountId=@PartGLAccountId;

						SELECT TOP 1 @STKId = STL.StockLineId,
						             @partId = sop.[SalesOrderPartId],--sop.[ItemMasterId],
								     @MPNName = itm.[partnumber],
									 @InventoryToBillGLAccId = STL.InventoryToBillGLAccId, --For INVENTORY TO BILL Distribution (Shipping & Billing)
									 @InventoryGLAccId = STL.GLAccountId, -- For PARTS INVENTORY Distribution (Shipping)
									 @COGSSalesOrderGLAccId = STL.COGS_SalesOrderGLAccId,  -- For COGS Sales Order Distribution (Billing)
									 @RevenueSoGLAccId = STL.RevenueSoGLAccId -- For Revenue SO Distribution (Billing)
						FROM [dbo].[SalesOrderShipping] soi WITH(NOLOCK)
						INNER JOIN [dbo].[SalesOrderShippingItem] soit WITH(NOLOCK) ON soi.SalesOrderShippingId = soit.SalesOrderShippingId
						INNER JOIN [dbo].[SOPickTicket] sopt WITH(NOLOCK) ON sopt.SOPickTicketId = soit.SOPickTicketId
						INNER JOIN [dbo].[SalesOrderPartV1] sop WITH(NOLOCK) ON soit.SalesOrderPartId = sop.SalesOrderPartId
						INNER JOIN [dbo].[SalesOrderStocklineV1] stk WITH(NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId AND stk.SalesOrderStocklineId = sopt.SalesOrderPartStocklineId
						INNER JOIN [dbo].[Stockline] STL WITH(NOLOCK) ON stk.StockLineId = STL.StockLineId
						INNER JOIN [dbo].[SalesOrderStockLineCost] STKC WITH(NOLOCK) ON STKC.SalesOrderStocklineId = stk.SalesOrderStocklineId
					     LEFT JOIN [dbo].[ItemMaster] itm WITH(NOLOCK) ON itm.[ItemMasterId] = sop.[ItemMasterId]

					      WHERE soi.SalesOrderShippingId=@InvoiceId AND STL.GLAccountId=@PartGLAccountId;

						SELECT @STKGlAccountId=SL.GLAccountId,
						       @STKGlAccountNumber=GL.AccountCode,
							   @STKGlAccountName=GL.AccountName,
							   @LotId = SL.LotId,
							   @LotNumber = LO.[LotNumber],
							   @StocklineId = SL.[StockLineId],
							   @StocklineNumber = SL.[StockLineNumber]
						  FROM [dbo].[Stockline] SL WITH(NOLOCK)
						  INNER JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId 
						  LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK) ON  LO.LotId = SL.LotId  
						  WHERE SL.StockLineId = @STKId;
						  
						----Inventory to Bill------
						IF(@PartUnitSalesPrices >0)
						BEGIN
							 IF(@CustomerTypeId = @CustomerAffiliationId)
							 BEGIN
								SELECT @DistributionSetupId=ID,
									   @DistributionName=Name,
									   @JournalTypeId =JournalTypeId,
									   @GlAccountId=GlAccountId,
									   @GlAccountNumber=GlAccountNumber,
									   @GlAccountName=GlAccountName,
									   @CrDrType = CRDRType,
									   @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
								  FROM [dbo].[DistributionSetup] WITH(NOLOCK)
								 WHERE UPPER([DistributionSetupCode]) = UPPER('INTERCOMPANYRECEIVABLESSOI')
								  AND [DistributionMasterId] = @DistributionMasterId
								  AND [MasterCompanyId] = @MasterCompanyId;

								  IF(@CustomerLegalEntityId > 0)
								  BEGIN
									  SELECT TOP 1 @ManagementStructureId  = ESS.[EntityStructureId]
										FROM [dbo].[EntityStructureSetup] ESS WITH (NOLOCK)
										INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH (NOLOCK) ON ESS.[Level1Id] = MSL.[ID]
										INNER JOIN [dbo].[LegalEntity] le WITH (NOLOCK) ON MSL.[LegalEntityId] = LE.[LegalEntityId]
										WHERE ess.[IsActive] = 1
										  AND ess.[IsDeleted] = 0
										  AND MSL.[LegalEntityId] = @CustomerLegalEntityId AND MSL.[MasterCompanyId] = @MasterCompanyId

										IF(@ManagementStructureId > 0)
										BEGIN
											IF OBJECT_ID(N'tempdb..#tmpMSDetails') IS NOT NULL
												DROP TABLE #tmpMSDetails;

											CREATE TABLE #tmpMSDetails
											(
												[EntityStructureId] BIGINT,
												[MasterCompanyId] INT,
												[Level1Id] BIGINT, [Level1Name] VARCHAR(200),
												[Level2Id] BIGINT, [Level2Name] VARCHAR(200),
												[Level3Id] BIGINT, [Level3Name] VARCHAR(200),
												[Level4Id] BIGINT, [Level4Name] VARCHAR(200),
												[Level5Id] BIGINT, [Level5Name] VARCHAR(200),
												[Level6Id] BIGINT, [Level6Name] VARCHAR(200),
												[Level7Id] BIGINT, [Level7Name] VARCHAR(200),
												[Level8Id] BIGINT, [Level8Name] VARCHAR(200),
												[Level9Id] BIGINT, [Level9Name] VARCHAR(200),
												[Level10Id] BIGINT, [Level10Name] VARCHAR(200),
												[AllMSlevels] NVARCHAR(MAX),
												[LastMSName] VARCHAR(200)
											);

											INSERT INTO #tmpMSDetails
											EXEC [dbo].[USP_GetEntityManagementStructureDetailsById] @ManagementStructureId;

											SELECT @AllMSlevels = [AllMSlevels], @LastMSLevel = [LastMSName] FROM #tmpMSDetails;

											DROP TABLE #tmpMSDetails;
										END
								  END
							END
							ELSE
							BEGIN
								SELECT top 1 @DistributionSetupId=ID,
										 @DistributionName=Name,
										 @JournalTypeId =JournalTypeId,
										 @GlAccountId=GlAccountId,
										 @GlAccountNumber=GlAccountNumber,
										 @GlAccountName=GlAccountName,
										 @CrDrType = CRDRType,
										 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode) =UPPER('INVENTORYTOBILLSO')
									 AND DistributionMasterId=@DistributionMasterId
									 AND MasterCompanyId = @MasterCompanyId;

								--GET GL Accounting Data from GLAccout based on stockline
								SELECT @GlAccountId = [GLAccountId],
									   @GlAccountNumber = [AccountCode],
									   @GlAccountName = [AccountName]
								FROM [dbo].[GLAccount] WITH(NOLOCK)
								WHERE [GLAccountId] = @InventoryToBillGLAccId
								AND [MasterCompanyId] = @MasterCompanyId;
							END

							IF(@IsBypassAccounting = 0)
							BEGIN
							
							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @PartUnitSalesPrices ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @PartUnitSalesPrices END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber,@SalesOrderNumber,@CustomerName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceId,@ReferenceModule)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[SalesOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)

							END
						END
						----Inventory to Bill------
						----Inventory - Parts-----
						IF(@PartUnitSalesPrices >0)
						BEGIN
							 IF(@CustomerTypeId = @CustomerAffiliationId)
							 BEGIN
								SELECT @DistributionSetupId=ID,
									   @DistributionName=Name,
									   @JournalTypeId =JournalTypeId,
									   @GlAccountId=GlAccountId,
									   @GlAccountNumber=GlAccountNumber,
									   @GlAccountName=GlAccountName,
									   @CrDrType = CRDRType,
									   @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
								  FROM [dbo].[DistributionSetup] WITH(NOLOCK)
								  WHERE UPPER([DistributionSetupCode]) =UPPER('INTERCOMPANYSALESSOI')
								  AND [DistributionMasterId]=@DistributionMasterId
								  AND [MasterCompanyId] = @MasterCompanyId;
							END
							ELSE
							BEGIN
								SELECT top 1 @DistributionSetupId=ID,
											 @DistributionName=Name,
											 @JournalTypeId =JournalTypeId,
											 @GlAccountId=GlAccountId,
											 @GlAccountNumber=GlAccountNumber,
											 @GlAccountName=GlAccountName,
											 @CrDrType = CRDRType,
											 @IsBypassAccounting = ISNULL([IsBypassAccounting],0)
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode) =UPPER('PARTSINVENTORY')
										AND DistributionMasterId=@DistributionMasterId
										AND MasterCompanyId = @MasterCompanyId;

								--GET GL Accounting Data from GLAccout based on stockline
								SELECT @GlAccountId = [GLAccountId],
									   @GlAccountNumber = [AccountCode],
									   @GlAccountName = [AccountName]
								FROM [dbo].[GLAccount] WITH(NOLOCK)
								WHERE [GLAccountId] = @InventoryGLAccId
								AND [MasterCompanyId] = @MasterCompanyId;
							END

							IF(@IsBypassAccounting = 0)
							BEGIN
				            
				    		INSERT INTO [dbo].[CommonBatchDetails]
				    			(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceId],[ReferenceModule])
				    		VALUES
				    			(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @PartUnitSalesPrices ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @PartUnitSalesPrices END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber,@SalesOrderNumber,@CustomerName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceId,@ReferenceModule)
				    
							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
				    
							INSERT INTO [dbo].[SalesOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
				    		
							END
						END
						----Inventory - Parts-----
					FETCH NEXT FROM @SalesOrderPartDetailsCursor1 INTO @PartGLAccountId
					END
					CLOSE @SalesOrderPartDetailsCursor1  
					DEALLOCATE @SalesOrderPartDetailsCursor1
					----GL Account wise COGS-Parts and Inventory-Parts Entry----
					SET @TotalDebit=0;
					SET @TotalCredit=0;

					SELECT @TotalDebit = SUM(DebitAmount),
					       @TotalCredit=SUM(CreditAmount) 
					  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
					  WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
					
					UPDATE BatchDetails 
					   SET DebitAmount=@TotalDebit,
					       CreditAmount=@TotalCredit,
						   UpdatedDate=GETUTCDATE(),
						   UpdatedBy=@UpdateBy 
					 WHERE JournalBatchDetailId=@JournalBatchDetailId

					--AutoPost Batch
					IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
					BEGIN
						EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
					END
					IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
					BEGIN
						EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
					END
				END

			END
			
			SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	          
			SET @TotalBalance =@TotalDebit-@TotalCredit
			UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
			UPDATE BatchHeader SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId

			IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCodePrefixes 
			END
		END
	END 
	END TRY
	BEGIN CATCH  
		IF @@trancount > 0
		PRINT 'ROLLBACK'
		--ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_BatchTriggerBasedonSOInvoiceNew'         
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@DistributionMasterId, 0) AS VARCHAR(100)) 
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
