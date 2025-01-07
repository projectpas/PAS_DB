/*************************************************************             
 ** File:   [CopySalesOrder]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used CopySalesOrder
 ** Purpose:           
 ** Date:  01/01/2025        
            
 ** PARAMETERS: @SalesOrderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    01/01/2024		EKTA CHANDEGRA	 Created  
    2    07/01/2024		EKTA CHANDEGRA	 Retrieve Specific columns from [dbo].[SalesOrderPartV1]

 EXEC CopySalesOrder 1666 , N'EKTA CHANDEGRA', 0
************************************************************************/ 
CREATE   PROCEDURE [dbo].[CopySalesOrder]
	@SalesOrderId BIGINT,
	@CreatedBy VARCHAR(256),
	@TransferSOApproval BIT
AS
BEGIN 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @SalesOrderCodePrefix INT = 26;
				DECLARE @MasterCompanyId INT;
				DECLARE @CurrentNumber BIGINT;
				DECLARE @OldSalesOrderId BIGINT;

				-- Fetch salesView
				SELECT TOP 1 * INTO #salesView FROM [dbo].[SalesOrder] WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId;

				SELECT TOP 1 @MasterCompanyId = ISNULL(MasterCompanyId, 0)
				FROM [dbo].[SalesOrder] WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId;

				-- Fetch soCodeData
				SELECT TOP 1 * INTO #soCodeData	FROM [dbo].[CodePrefixes] WITH (NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = @SalesOrderCodePrefix AND MasterCompanyId = @MasterCompanyId;

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
						SET @SalesOrderNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNumber, (SELECT CodePrefix FROM #soCodeData), (SELECT CodeSufix FROM #soCodeData)));
					END
					ELSE
					BEGIN
					-- Generate SalesOrderNumber without prefix/suffix
						SET @SalesOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(0, '', ''));
					END

			-- Insert SalesOrder
				INSERT INTO [dbo].[SalesOrder]
				([Version],[TypeId],[OpenDate],[ShippedDate],[NumberOfItems],[AccountTypeId],[CustomerId],[CustomerContactId],
				 [CustomerReference],[CurrencyId],[TotalSalesAmount],[CustomerHold],[DepositAmount],[BalanceDue],[SalesPersonId],
				 [AgentId],[CustomerSeviceRepId],[EmployeeId],[ApprovedById],[ApprovedDate],[Memo],[StatusId],[StatusChangeDate],
				 [Notes],[RestrictPMA],[RestrictDER],[ManagementStructureId],[CustomerWarningId],[CreatedBy],[CreatedDate],[UpdatedBy],
				 [UpdatedDate],[MasterCompanyId],[IsDeleted],[SalesOrderQuoteId],[QtyRequested],[QtyToBeQuoted],[SalesOrderNumber],
				 [IsActive],[ContractReference],[TypeName],[AccountTypeName],[CustomerName],[SalesPersonName],[CustomerServiceRepName],
				 [EmployeeName],[CurrencyName],[CustomerWarningName],[ManagementStructureName],[CreditLimit],[CreditTermId],
				 [CreditLimitName],[CreditTermName],[VersionNumber],[TotalFreight],[TotalCharges],[FreightBilingMethodId],
				 [ChargesBilingMethodId],[EnforceEffectiveDate],[IsEnforceApproval],[Level1],[Level2],[Level3],[Level4],[ATAPDFPath],
				 [LotId],[IsLotAssigned],[AllowInvoiceBeforeShipping],[PercentId],[Days],[NetDays],[COCManufacturingPDFPath],
				 [FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate])

				 SELECT 
				 SO.[Version],SO.[TypeId],GETDATE(),SO.[ShippedDate],SO.[NumberOfItems],SO.[AccountTypeId],SO.[CustomerId],SO.[CustomerContactId],
				 SO.[CustomerReference],SO.[CurrencyId],SO.[TotalSalesAmount],SO.[CustomerHold],SO.[DepositAmount],SO.[BalanceDue],SO.[SalesPersonId],
				 SO.[AgentId],SO.[CustomerSeviceRepId],SO.[EmployeeId],SO.[ApprovedById],SO.[ApprovedDate],SO.[Memo],SO.[StatusId],SO.[StatusChangeDate],
				 SO.[Notes],SO.[RestrictPMA],SO.[RestrictDER],SO.[ManagementStructureId],SO.[CustomerWarningId],@CreatedBy,GETDATE(),@CreatedBy,
				 GETDATE(),SO.[MasterCompanyId],0,SO.[SalesOrderQuoteId],SO.[QtyRequested],SO.[QtyToBeQuoted],@SalesOrderNumber,
				 1,SO.[ContractReference],SO.[TypeName],SO.[AccountTypeName],SO.[CustomerName],SO.[SalesPersonName],SO.[CustomerServiceRepName],
				 SO.[EmployeeName],SO.[CurrencyName],SO.[CustomerWarningName],SO.[ManagementStructureName],SO.[CreditLimit],SO.[CreditTermId],
				 SO.[CreditLimitName],SO.[CreditTermName],SO.[VersionNumber],SO.[TotalFreight],SO.[TotalCharges],SO.[FreightBilingMethodId],
				 SO.[ChargesBilingMethodId],SO.[EnforceEffectiveDate],SO.[IsEnforceApproval],SO.[Level1],SO.[Level2],SO.[Level3],SO.[Level4],SO.[ATAPDFPath],
				 SO.[LotId],SO.[IsLotAssigned],SO.[AllowInvoiceBeforeShipping],SO.[PercentId],SO.[Days],SO.[NetDays],SO.[COCManufacturingPDFPath],
				 SO.[FunctionalCurrencyId],SO.[ReportCurrencyId],SO.[ForeignExchangeRate]
				 FROM [dbo].[SalesOrder] SO WITH(NOLOCK)
				 WHERE SO.SalesOrderId = @SalesOrderId

			-- END Insert SalesOrder

				SELECT @OldSalesOrderId = @SalesOrderId;
				print @OldSalesOrderId;
				SELECT @SalesOrderId = SCOPE_IDENTITY();
				print @SalesOrderId;


			-- Fetch SalesOrder settings
				DECLARE @soqSettingApprovalRule BIT;
				DECLARE @soqSettingEffectiveDate DATETIME;
				DECLARE @soAllowInvoiceBeforeShipping BIT;

				SELECT TOP 1
					@soqSettingApprovalRule = IsApprovalRule,
					@soqSettingEffectiveDate = EffectiveDate,
					@soAllowInvoiceBeforeShipping = AllowInvoiceBeforeShipping
				FROM [dbo].[SalesOrderSettings] WITH (NOLOCK)
				WHERE IsActive = 1 AND IsDeleted = 0 AND MasterCompanyId = @MasterCompanyId;

			-- Update SalesOrder with settings
				UPDATE [dbo].[SalesOrder]
				SET 
					IsEnforceApproval = @soqSettingApprovalRule,
					EnforceEffectiveDate = @soqSettingEffectiveDate,
					AllowInvoiceBeforeShipping = @soAllowInvoiceBeforeShipping
				WHERE SalesOrderId = @SalesOrderId;

				DECLARE @SOLoopID AS INT;
				CREATE TABLE #sopartList
				(
					ID BIGINT NOT NULL IDENTITY,
					[SalesOrderPartId] [bigint] NULL,
					[SalesOrderId] [bigint] NOT NULL,
					[ItemMasterId] [bigint] NOT NULL,
					[ConditionId] [bigint] NOT NULL,
					[QtyRequested] [int] NOT NULL,
					[QtyOrder] [int] NOT NULL,
					[QtyReserved] [int] NOT NULL,
					[CurrencyId] [int] NULL,
					[PriorityId] [bigint] NOT NULL,
					[StatusId] [int] NOT NULL,
					[FxRate] [decimal](18, 4) NULL,
					[CustomerRequestDate] [datetime2](7) NULL,
					[PromisedDate] [datetime2](7) NULL,
					[EstimatedShipDate] [datetime2](7) NULL,
					[POId] [bigint] NULL,
					[PONumber] [varchar](256) NULL,
					[PONextDlvrDate] [datetime2](7) NULL,
					[Notes] [nvarchar](max) NULL,
					[MasterCompanyId] [int] NOT NULL,
					[CreatedBy] [varchar](256) NOT NULL,
					[CreatedDate] [datetime2](7) NOT NULL,
					[UpdatedBy] [varchar](256) NOT NULL,
					[UpdatedDate] [datetime2](7) NOT NULL,
					[IsActive] [bit] NOT NULL,
					[IsDeleted] [bit] NOT NULL,
					[OldSalesOrderPartId] [bigint] NULL,
					[PartNumber] [varchar](100) NULL,
					[PartDescription] [varchar](100) NULL,
					[ConditionName] [varchar](100) NULL,
					[CurrencyName] [varchar](100) NULL,
					[PriorityName] [varchar](100) NULL,
					[StatusName] [varchar](100) NULL,
					[SalesOrderQuotePartId] [bigint] NULL,
					[LotId] [bigint] NULL,
					[IsLotAssigned] [bit] NULL,
					[ECCN] [varchar](200) NULL,
					[HSCODE] [varchar](200) NULL,
					[Weight] [decimal](10, 2) NULL,
					[SizeLength] [decimal](10, 2) NULL,
					[SizeWidth] [decimal](10, 2) NULL,
					[SizeHeight] [decimal](10, 2) NULL,
					[AltOrEqType] [varchar](50) NULL,
				)

				INSERT INTO #sopartList
				(
					[SalesOrderPartId],
					[SalesOrderId],
					[ItemMasterId],
					[ConditionId],
					[QtyRequested],
					[QtyOrder],
					[QtyReserved],
					[CurrencyId],
					[PriorityId],
					[StatusId],
					[FxRate],
					[CustomerRequestDate],
					[PromisedDate],
					[EstimatedShipDate],
				    [POId],
					[PONumber],
					[PONextDlvrDate],
					[Notes],
					[MasterCompanyId],
					[CreatedBy],
					[CreatedDate],
					[UpdatedBy],
					[UpdatedDate],
					[IsActive],
					[IsDeleted],
					[OldSalesOrderPartId],
					[PartNumber],
					[PartDescription],
					[ConditionName],
					[CurrencyName],
					[PriorityName],
					[StatusName],
					[SalesOrderQuotePartId],
					[LotId],
					[IsLotAssigned],
					[ECCN],
					[HSCODE],
					[Weight],
					[SizeLength],
					[SizeWidth],
					[SizeHeight],
					[AltOrEqType]
				)

				SELECT DISTINCT 
					SOPV1.[SalesOrderPartId],
					SOPV1.[SalesOrderId],
					SOPV1.[ItemMasterId],
					SOPV1.[ConditionId],
					SOPV1.[QtyRequested],
					SOPV1.[QtyOrder],
					SOPV1.[QtyReserved],
					SOPV1.[CurrencyId],
					SOPV1.[PriorityId],
					SOPV1.[StatusId],
					SOPV1.[FxRate],
					SOPV1.[CustomerRequestDate],
					SOPV1.[PromisedDate],
					SOPV1.[EstimatedShipDate],
				    SOPV1.[POId],
					SOPV1.[PONumber],
					SOPV1.[PONextDlvrDate],
					SOPV1.[Notes],
					SOPV1.[MasterCompanyId],
					SOPV1.[CreatedBy],
					SOPV1.[CreatedDate],
					SOPV1.[UpdatedBy],
					SOPV1.[UpdatedDate],
					SOPV1.[IsActive],
					SOPV1.[IsDeleted],
					SOPV1.[OldSalesOrderPartId],
					SOPV1.[PartNumber],
					SOPV1.[PartDescription],
					SOPV1.[ConditionName],
					SOPV1.[CurrencyName],
					SOPV1.[PriorityName],
					SOPV1.[StatusName],
					SOPV1.[SalesOrderQuotePartId],
					SOPV1.[LotId],
					SOPV1.[IsLotAssigned],
					SOPV1.[ECCN],
					SOPV1.[HSCODE],
					SOPV1.[Weight],
					SOPV1.[SizeLength],
					SOPV1.[SizeWidth],
					SOPV1.[SizeHeight],
					SOPV1.[AltOrEqType]  FROM [dbo].[SalesOrderPartV1] SOPV1 WITH (NOLOCK) WHERE SOPV1.SalesOrderId = @OldSalesOrderId;

				SELECT @SOLoopID = MAX(ID) FROM #sopartList;
				WHILE (@SOLoopID > 0)
				BEGIN
					DECLARE @CurrentSOPartId BIGINT;
					DECLARE @OldSOPartId BIGINT;
					DECLARE @NewSOStocklineId BIGINT;		
	
					SELECT @OldSOPartId = SOP.SalesOrderPartId
					FROM #sopartList SOP WITH(NOLOCK) WHERE SOP.ID = @SOLoopID

				-- Transfer Part Data 
					INSERT INTO [dbo].[SalesOrderPartV1]
					([SalesOrderId],[ItemMasterId],[ConditionId],[QtyRequested],[QtyOrder],[QtyReserved],
					[CurrencyId],[PriorityId],[StatusId],[FxRate],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],
				    [POId],[PONumber],[PONextDlvrDate],[Notes],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],
					[IsActive],[IsDeleted],[OldSalesOrderPartId],[PartNumber],[PartDescription],[ConditionName],[CurrencyName],
					[PriorityName],[StatusName],[SalesOrderQuotePartId],[LotId],[IsLotAssigned],[ECCN],[HSCODE],[Weight],
					[SizeLength],[SizeWidth],[SizeHeight],[AltOrEqType])

					SELECT
					@SalesOrderId,SOP.[ItemMasterId],SOP.[ConditionId],SOP.[QtyRequested],SOP.[QtyOrder],SOP.[QtyReserved],
					SOP.[CurrencyId],SOP.[PriorityId],SOP.[StatusId],SOP.[FxRate],SOP.[CustomerRequestDate],SOP.[PromisedDate],SOP.[EstimatedShipDate],
				    SOP.[POId],SOP.[PONumber],SOP.[PONextDlvrDate],SOP.[Notes],SOP.[MasterCompanyId],@CreatedBy,GETDATE(),@CreatedBy,GETDATE(),
					1,0,SOP.[OldSalesOrderPartId],SOP.[PartNumber],SOP.[PartDescription],SOP.[ConditionName],SOP.[CurrencyName],
					SOP.[PriorityName],SOP.[StatusName],SOP.[SalesOrderQuotePartId],SOP.[LotId],SOP.[IsLotAssigned],IMEI.[ExportECCN],IMEI.[HSCODE],IMEI.[ExportWeight],
					IMEI.[ExportSizeLength],IMEI.[ExportSizeWidth],IMEI.[ExportSizeHeight],SOP.[AltOrEqType]

					FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK)
					LEFT JOIN [dbo].[ItemMasterExportInfo] IMEI WITH (NOLOCK) ON IMEI.ItemMasterId = SOP.ItemMasterId
					WHERE SOP.SalesOrderPartId = @OldSOPartId

					SET @CurrentSOPartId = SCOPE_IDENTITY();
				-- END Transfer Part Data 

				-- Transfer Part Cost 
					INSERT INTO [dbo].[SalesOrderPartCost]
					([SalesOrderId],[SalesOrderPartId],[UnitSalesPrice],[UnitSalesPriceExtended],
					[UnitCost],[UnitCostExtended],[MarkUpPercentage],[MarkUpAmount],[MarginAmount],
					[MarginPercentage],[DiscountPercentage],[DiscountAmount],[TaxPercentage],[TaxAmount],
					[NetSaleAmount],[MiscCharges],[Freight],[TotalRevenue],[MasterCompanyId],[CreatedBy],
					[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])

					SELECT
					@SalesOrderId,@CurrentSOPartId,SOPC.[UnitSalesPrice],SOPC.[UnitSalesPriceExtended],
					SOPC.[UnitCost],SOPC.[UnitCostExtended],SOPC.[MarkUpPercentage],SOPC.[MarkUpAmount],SOPC.[MarginAmount],
					SOPC.[MarginPercentage],SOPC.[DiscountPercentage],SOPC.[DiscountAmount],SOPC.[TaxPercentage],SOPC.[TaxAmount],
					SOPC.[NetSaleAmount],SOPC.[MiscCharges],SOPC.[Freight],SOPC.[TotalRevenue],SOPC.[MasterCompanyId],SOPC.[CreatedBy],
					GETDATE(),SOPC.[UpdatedBy],GETDATE(),SOPC.[IsActive],SOPC.[IsDeleted]
					FROM [dbo].[SalesOrderPartCost] SOPC WITH (NOLOCK)
					WHERE SOPC.SalesOrderPartId = @OldSOPartId
					AND SOPC.SalesOrderId = @OldSalesOrderId;

				-- End Transfer Part Cost 

					IF EXISTS(SELECT 1 FROM [dbo].[SalesOrderStocklineV1] SOSTL WITH(NOLOCK) WHERE SOSTL.SalesOrderPartId = @OldSOPartId)
					BEGIN
						DECLARE @SOStocklineLoopID AS INT;
						IF OBJECT_ID(N'tempdb..#soqpsList') IS NOT NULL
						BEGIN
							DROP TABLE #sopsList
						END
						CREATE TABLE #sopsList
						(
							ID BIGINT NOT NULL IDENTITY,
							[SalesOrderStocklineId] [bigint] NULL,
							[StocklineId] [bigint] NULL
						)

						INSERT INTO #sopsList([SalesOrderStocklineId],[StocklineId])
						SELECT DISTINCT SOSV1.SalesOrderStocklineId , SOSV1.StockLineId
						FROM [dbo].[SalesOrderStocklineV1] SOSV1 WITH (NOLOCK)
						WHERE SOSV1.SalesOrderPartId = @OldSOPartId

						SELECT @SOStocklineLoopID = MAX(ID) FROM #sopsList;
						WHILE(@SOStocklineLoopID > 0)
						BEGIN 
							DECLARE @OldSOStocklineId BIGINT;
							SELECT @OldSOStocklineId = SalesOrderStocklineId FROM #sopsList sopl WITH(NOLOCK) WHERE sopl.ID = @SOStocklineLoopID

						-- Transfer Part Stockline 
							INSERT INTO [dbo].[SalesOrderStocklineV1]
							([SalesOrderPartId],[StockLineId],[ConditionId],[QtyOrder],[QtyReserved],[QtyAvailable],
							 [QtyOH],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[StatusId],[MasterCompanyId],
							 [CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[StocklineNumber],
						     [ConditionName],[StatusName],[Notes],[ECCN],[HSCODE],[Weight],[SizeLength],[SizeWidth],[SizeHeight],
							 [ReferenceNumber],[PriorityId])

							SELECT 
							@CurrentSOPartId,SOSTLV1.[StockLineId],SOSTLV1.[ConditionId],SOSTLV1.[QtyOrder],SOSTLV1.[QtyReserved],SOSTLV1.[QtyAvailable],
							 SOSTLV1.[QtyOH],SOSTLV1.[CustomerRequestDate],SOSTLV1.[PromisedDate],SOSTLV1.[EstimatedShipDate],SOSTLV1.[StatusId],SOSTLV1.[MasterCompanyId],
							 SOSTLV1.[CreatedBy],GETDATE(),SOSTLV1.[UpdatedBy],GETDATE(),SOSTLV1.[IsActive],SOSTLV1.[IsDeleted],SOSTLV1.[StocklineNumber],
						     SOSTLV1.[ConditionName],SOSTLV1.[StatusName],SOSTLV1.[Notes],IMEI.[ExportECCN],IMEI.[HSCODE],IMEI.[ExportWeight],IMEI.[ExportSizeLength],IMEI.[ExportSizeWidth],IMEI.[ExportSizeHeight],
							 SOSTLV1.[ReferenceNumber],SOSTLV1.[PriorityId]
							FROM [dbo].[SalesOrderStocklineV1] SOSTLV1 WITH(NOLOCK)
							INNER JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = SOSTLV1.SalesOrderPartId
							LEFT JOIN [dbo].[ItemMasterExportInfo] IMEI WITH (NOLOCK) ON IMEI.ItemMasterId = SOP.ItemMasterId
							WHERE SOSTLV1.SalesOrderStocklineId = @OldSOStocklineId;

							SET @NewSOStocklineId = SCOPE_IDENTITY();
						-- End Transfer Part Stockline
						
						-- Transfer Part Stockline Cost 
							INSERT INTO [DBO].[SalesOrderStockLineCost]
							([SalesOrderId],[SalesOrderPartId],[SalesOrderStocklineId],[UnitSalesPrice],
							[UnitSalesPriceExtended],[UnitCost],[UnitCostExtended],[MarkUpPercentage],
							[MarkUpAmount],[DiscountPercentage],[DiscountAmount],[MarginAmount],
							[MarginPercentage],[NetSaleAmount],[MasterCompanyId],[CreatedBy],[CreatedDate],
							[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[NetSaleAmountPerUnit])

							SELECT @SalesOrderId,@CurrentSOPartId,@NewSOStocklineId,SOSTLC.[UnitSalesPrice],
							SOSTLC.[UnitSalesPriceExtended],SOSTLC.[UnitCost],SOSTLC.[UnitCostExtended],SOSTLC.[MarkUpPercentage],
							SOSTLC.[MarkUpAmount],SOSTLC.[DiscountPercentage],SOSTLC.[DiscountAmount],SOSTLC.[MarginAmount],
							SOSTLC.[MarginPercentage],SOSTLC.[NetSaleAmount],SOSTLC.[MasterCompanyId],SOSTLC.[CreatedBy],GETDATE(),
							SOSTLC.[UpdatedBy],GETDATE(),SOSTLC.[IsActive],SOSTLC.[IsDeleted],SOSTLC.[NetSaleAmountPerUnit]
							FROM [dbo].[SalesOrderStockLineCost] SOSTLC WITH(NOLOCK)
							WHERE SOSTLC.SalesOrderStocklineId = @OldSOStocklineId
							AND SOSTLC.SalesOrderId = @OldSalesOrderId 

						-- END Transfer Part Stockline Cost
							SET @SOStocklineLoopID = @SOStocklineLoopID - 1;
						END
					END

				-- Transfer Freights
					IF EXISTS(SELECT 1 FROM [dbo].[SalesOrderFreight] SOF WITH(NOLOCK) WHERE SOF.SalesOrderPartId = @OldSOPartId)
					BEGIN
						INSERT INTO [dbo].[SalesOrderFreight]
						([SalesOrderQuoteId],[SalesOrderId],[SalesOrderPartId],[ShipViaId],[Weight],[Memo],
						  [Amount],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
						  [BillingRate],[BillingAmount],[Length],[Width],[Height],[UOMId],[DimensionUOMId],
						  [CurrencyId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
						  [IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ShipViaName],[UOMName],[DimensionUOMName],
						  [CurrencyName],[ItemMasterId],[ConditionId])

						  SELECT
						  SOF.[SalesOrderQuoteId],@SalesOrderId,@CurrentSOPartId,SOF.[ShipViaId],SOF.[Weight],SOF.[Memo],
						  SOF.[Amount],SOF.[MarkupPercentageId],SOF.[MarkupFixedPrice],SOF.[HeaderMarkupId],SOF.[BillingMethodId],
						  SOF.[BillingRate],SOF.[BillingAmount],SOF.[Length],SOF.[Width],SOF.[Height],SOF.[UOMId],SOF.[DimensionUOMId],
						  SOF.[CurrencyId],SOF.[MasterCompanyId],SOF.[CreatedBy],SOF.[UpdatedBy],GETDATE(),GETDATE(),
						  SOF.[IsActive],SOF.[IsDeleted],SOF.[HeaderMarkupPercentageId],SOF.[ShipViaName],SOF.[UOMName],SOF.[DimensionUOMName],
						  SOF.[CurrencyName],SOF.[ItemMasterId],SOF.[ConditionId]
						  FROM [dbo].[SalesOrderFreight] SOF WITH(NOLOCK)
						  WHERE SOF.SalesOrderPartId = @OldSOPartId
					END
					-- End Transfer Freights

					-- Transfer Charges
					IF EXISTS(SELECT 1 FROM [dbo].[SalesOrderCharges] SOF WITH(NOLOCK) WHERE SOF.SalesOrderPartId = @OldSOPartId)
					BEGIN
						INSERT INTO [dbo].[SalesOrderCharges]
						([SalesOrderQuoteId],[SalesOrderId],[SalesOrderPartId],[ChargesTypeId],[VendorId],[Quantity],
						 [MarkupPercentageId],[Description],[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],
						 [BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId],[RefNum],[CreatedBy],[UpdatedBy],
						 [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[VendorName],
						 [ChargeName],[MarkupName],[ItemMasterId],[ConditionId],[UOMId])

						 SELECT
						 SOC.[SalesOrderQuoteId],@SalesOrderId,@CurrentSOPartId,SOC.[ChargesTypeId],SOC.[VendorId],SOC.[Quantity],
						 SOC.[MarkupPercentageId],SOC.[Description],SOC.[UnitCost],SOC.[ExtendedCost],SOC.[MasterCompanyId],SOC.[MarkupFixedPrice],
						 SOC.[BillingMethodId],SOC.[BillingAmount],SOC.[BillingRate],SOC.[HeaderMarkupId],SOC.[RefNum],SOC.[CreatedBy],SOC.[UpdatedBy],
						 GETDATE(),GETDATE(),SOC.[IsActive],SOC.[IsDeleted],SOC.[HeaderMarkupPercentageId],SOC.[VendorName],
						 SOC.[ChargeName],SOC.[MarkupName],SOC.[ItemMasterId],SOC.[ConditionId],SOC.[UOMId]
						 FROM [dbo].[SalesOrderCharges] SOC WITH (NOLOCK)
						 WHERE SOC.SalesOrderPartId = @OldSOPartId
					END
					-- End Transfer Charges

					-- Transfer SalesOrderApproval
					IF(@TransferSOApproval = 1)
					BEGIN
						IF EXISTS (SELECT TOP 1 SOP.SalesOrderPartId FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) WHERE SOP.SalesOrderId = @SalesOrderId)
						BEGIN
							INSERT INTO [dbo].[SalesOrderApproval] 
							([SalesOrderId],[SalesOrderPartId],[SalesOrderQuoteId] ,[SalesOrderQuotePartId],[CustomerId],
							 [InternalMemo],[InternalSentDate],[InternalApprovedDate],[InternalApprovedById],
							 [CustomerSentDate],[CustomerApprovedDate],[CustomerApprovedById],[ApprovalActionId],
							 [CustomerStatusId],[InternalStatusId],[CustomerMemo],[MasterCompanyId],[CreatedBy],
							 [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Customer],
							 [InternalApprovedBy],[CustomerApprovedBy],[ApprovalAction],[CustomerStatus],
							 [InternalStatus],[RejectedById],[RejectedByName],[RejectedDate],
							 [InternalRejectedById],[InternalRejectedByName],[InternalRejectedDate],
							 [InternalSentToId],[InternalSentToName],[InternalSentById])

							SELECT
							 @SalesOrderId,@CurrentSOPartId,SOA.[SalesOrderQuoteId] ,SOA.[SalesOrderQuotePartId],SOA.[CustomerId],
							 SOA.[InternalMemo],SOA.[InternalSentDate],SOA.[InternalApprovedDate],SOA.[InternalApprovedById],
							 SOA.[CustomerSentDate],SOA.[CustomerApprovedDate],SOA.[CustomerApprovedById],SOA.[ApprovalActionId],
							 SOA.[CustomerStatusId],SOA.[InternalStatusId],SOA.[CustomerMemo],SOA.[MasterCompanyId],SOA.[CreatedBy],
							 SOA.[UpdatedBy],SOA.[CreatedDate],SOA.[UpdatedDate],SOA.[IsActive],SOA.[IsDeleted],SOA.[Customer],
							 SOA.[InternalApprovedBy],SOA.[CustomerApprovedBy],SOA.[ApprovalAction],SOA.[CustomerStatus],
							 SOA.[InternalStatus],SOA.[RejectedById],SOA.[RejectedByName],SOA.[RejectedDate],
							 SOA.[InternalRejectedById],SOA.[InternalRejectedByName],SOA.[InternalRejectedDate],
							 SOA.[InternalSentToId],SOA.[InternalSentToName],SOA.[InternalSentById]
							FROM [dbo].[SalesOrderApproval] SOA WITH(NOLOCK)
							WHERE SOA.SalesOrderPartId = @OldSOPartId AND SOA.SalesOrderId = @OldSalesOrderId;
						END
					END
					-- End Transfer SalesOrderApproval
					SET @SOLoopID = @SOLoopID - 1;
					

					DECLARE @SOOpenStatusId INT = (SELECT TOP 1 Id FROM [dbo].[MasterSalesOrderStatus] MSS WITH(NOLOCK) where MSS.[Name] = 'Open');
					IF(@TransferSOApproval = 0)
					BEGIN
						IF EXISTS (SELECT TOP 1 SO.StatusId FROM [dbo].[SalesOrder] SO WITH (NOLOCK) WHERE SO.SalesOrderId = @SalesOrderId)
						BEGIN
							UPDATE [dbo].[SalesOrder]
							SET StatusId = @SOOpenStatusId,
							StatusChangeDate = GETDATE(),
							UpdatedDate = GETDATE()
							WHERE SalesOrderId = @SalesOrderId
						END
					END
				END

				DECLARE @MSModuleID INT = 17;
				DECLARE @EntityMSID BIGINT;
				DECLARE @MSDetailsId BIGINT;
				DECLARE @UpdatedBy VARCHAR(100);

				SELECT @EntityMSID = SO.ManagementStructureId, @UpdatedBy = SO.UpdatedBy FROM [dbo].[SalesOrder] SO WITH (NOLOCK) WHERE SO.SalesOrderId = @SalesOrderId;
				
				-- Save SO record in SalesOrderManagementStructureDetails table
				EXEC [dbo].[USP_SaveSOMSDetails] @MSModuleID, @SalesOrderId, @EntityMSID, @MasterCompanyId, @UpdatedBy, @MSDetailsId OUTPUT;
			END

			SELECT @SalesOrderId AS SalesOrderId, @SalesOrderNumber AS SalesOrderNumber ,@OldSalesOrderId AS OldSalesOrderId, @CurrentSOPartId AS CurrentSOPartId ;

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'CopySalesOrder'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''',
													 @Parameter2 = '''+ ISNULL(@CreatedBy, '') + ''',
													 @Parameter3 = '''+ ISNULL(@TransferSOApproval, '') + ''
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