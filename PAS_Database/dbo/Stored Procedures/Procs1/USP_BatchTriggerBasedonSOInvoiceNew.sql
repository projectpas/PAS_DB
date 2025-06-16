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
	7    30/11/2023  Moin Bloch     Modify(Added LotId And Lot Number in CommonBatchDetails)
	8    11/12/2023  Moin Bloch     Modify(If Invoice Entry NOT EXISTS Then only Invoice Entry Will Store)
	9    08/01/2024  Moin Bloch     Modify(Replace Invocedate instead of GETUTCDATE() in Invoice)
    10	 01/02/2024	 AMIT GHEDIYA	added isperforma Flage for SO
	11   02/04/2024  HEMANT SALIYA  Added LE Params to Get Correct Accounting Cal Id
	12   19/09/2024	 AMIT GHEDIYA   Added for AutoPost Batch
	13	 09/10/2024	 Devendra Shekh	Added new fields for [CommonBatchDetails]
	14	 11/04/2024  Devendra Shekh Added ReferenceId, ReferenceModule For [CommonBatchDetails]
	15	 11/29/2024  Vishal Suthar  Modified the SP to make use of new SO tables
	16	 12/03/2024  Vishal Suthar  Fixed accounting entry while shipping
	17	 12/05/2024  Devendra Shekh Fixed amount issue while shipping/billing(cogs/inventory) accounting entry
	18	 12/06/2024  Moin Bloch     Fixed Duplicate amount issue 
	19	 06/01/2025  AMIT GHEDIYA   Modify(get Distribution based on new settings from stockline level with single bill)
	20	 24/04/2025	 Devendra Shekh	Modify (Added [IsManualText] check for DistributionSetup)
	21	 02/06/2025	 Abhishek Jirawla Fixed Name concat read script
  	22	 16/06/2025	 RAJESH GAMI	Implement new BILLING INVOICING table structure 
EXEC dbo.USP_BatchTriggerBasedonSOInvoiceNew 
@DistributionMasterId=12,@ReferenceId=515,@ReferencePartId=252,@ReferencePieceId=252,@InvoiceId=252,
@StocklineId=0,@Qty=0,@Amount=0,@ModuleName=N'SO',@MasterCompanyId=1,@UpdateBy=N'ADMIN User'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_BatchTriggerBasedonSOInvoiceNew]
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
			       @CustomerTypeName = caf.[Description] 
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
				IF NOT EXISTS (SELECT 1 FROM [dbo].[SalesOrderBatchDetails] SOD WITH(NOLOCK) WHERE SOD.[SalesOrderId] = @ReferenceId AND SOD.[DocumentId] = @InvoiceId)
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

					SELECT @MiscChargesCost =SUM(ISNULL(MiscCharges,0)),@FreightCost =SUM(ISNULL(Freight,0)) FROM SalesOrderPartCost WHERE SalesOrderPartId in(SELECT SubReferenceId FROM #tmpSOPartIds)

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

					SELECT @GLStocklineId = soi.[StockLineId] 
					FROM [dbo].[BillingInvoicingItems] soi WITH(NOLOCK) 
					WHERE soi.[BillingInvoicingId] = @InvoiceId AND soi.ModuleId = @soModuleId AND soi.SubReferenceId = @ReferencePartId;

					SELECT @StocklineNumber = SL.[StockLineNumber],
						   @InventoryToBillGLAccId = SL.InventoryToBillGLAccId, --For INVENTORY TO BILL Distribution (Shipping & Billing)
						   @InventoryGLAccId = SL.GLAccountId, -- For PARTS INVENTORY Distribution (Shipping)
						   @COGSSalesOrderGLAccId = SL.COGS_SalesOrderGLAccId,  -- For COGS EXc Sales Order Distribution (Billing)
						   @RevenueSoGLAccId = SL.RevenueSoGLAccId -- For Revenue EXc SO Distribution (Billing)
					  FROM [dbo].[Stockline] SL WITH(NOLOCK)					 
					  WHERE SL.[StockLineId] = @GLStocklineId;

					SET @COGSDifference = (@PartUnitSalesPrice - @InoiceGrandTotal);
					 
					SET @RevenuWO = @InvoiceTotalCost - (@FreightCost + @MiscChargesCost + @SalesTax);

					SET @AccountsReceivablesAmount = (@SalesTotal + @FreightCost + @MiscChargesCost + @SalesTax + @OtherTax);
					-----Revenue - SO------
					IF(@SalesTotal > 0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType,@IsAutoPost = ISNULL(IsAutoPost,0)
						FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('REVENUESALESORDER') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;

						--GET GL Accounting Data from GLAccout based on stockline
						SELECT @GlAccountId = [GLAccountId],
							   @GlAccountNumber = [AccountCode],
							   @GlAccountName = [AccountName]
						FROM [dbo].[GLAccount] WITH(NOLOCK)
						WHERE [GLAccountId] = @RevenueSoGLAccId
						AND [MasterCompanyId] = @MasterCompanyId;
						
						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId AND CustomerTypeId=@CustomerTypeId)
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
							SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId and CustomerTypeId=@CustomerTypeId
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
					-----Revenue - SO------

					-----Misc Charges------
					IF(@MiscChargesCost >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('REVENUEMISCCHARGE') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId				 
						
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
					-----Misc Charges------

					-----Freight------
					IF(@FreightCost >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('REVENUEFREIGHT') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
						
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

					-----Freight------

					-----Sales Tax------
					IF(@SalesTax > 0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('SALESTAXPAYABLE') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
						
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
					-----Sales Tax------

					-----Other Tax------
					IF(@OtherTax > 0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('TAXPAYABLEOTHER') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
						
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
					-----Other Tax------

					----Accounts Receivables - Trade----------

					IF(@AccountsReceivablesAmount >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('ACCOUNTSRECEIVABLESTRADE') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
						
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
						
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
							FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('COGSPARTS') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
							
							--GET GL Accounting Data from GLAccout based on stockline
							SELECT @GlAccountId = [GLAccountId],
								   @GlAccountNumber = [AccountCode],
								   @GlAccountName = [AccountName]
							FROM [dbo].[GLAccount] WITH(NOLOCK)
							WHERE [GLAccountId] = @COGSSalesOrderGLAccId
							AND [MasterCompanyId] = @MasterCompanyId;

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
						----COGS - Parts----
						----Inventory - Parts----
						IF(@PartUnitSalesPrices >0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
							FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('INVENTORYPARTS') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId	
							 
							--GET GL Accounting Data from GLAccout based on stockline
							SELECT @GlAccountId = [GLAccountId],
								   @GlAccountNumber = [AccountCode],
								   @GlAccountName = [AccountName]
							FROM [dbo].[GLAccount] WITH(NOLOCK)
							WHERE [GLAccountId] = @InventoryToBillGLAccId
							AND [MasterCompanyId] = @MasterCompanyId;

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
					SELECT top 1 @IsAutoPost = ISNULL(IsAutoPost,0)
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
						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId AND CustomerTypeId=@CustomerTypeId)
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
							SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId and CustomerTypeId=@CustomerTypeId
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
							SELECT top 1 @DistributionSetupId=ID,
							             @DistributionName=Name,
										 @JournalTypeId =JournalTypeId,
										 @GlAccountId=GlAccountId,
										 @GlAccountNumber=GlAccountNumber,
										 @GlAccountName=GlAccountName,
										 @CrDrType = CRDRType
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
						----Inventory to Bill------
						----Inventory - Parts-----
						IF(@PartUnitSalesPrices >0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,
							             @DistributionName=Name,
										 @JournalTypeId =JournalTypeId,
										 @GlAccountId=GlAccountId,
										 @GlAccountNumber=GlAccountNumber,
										 @GlAccountName=GlAccountName,
										 @CrDrType = CRDRType
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
        , @AdhocComments     VARCHAR(150)    = 'USP_BatchTriggerBasedonSOInvoice' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@DistributionMasterId, '') + ''
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