/*************************************************************             
 ** File:  [USP_AddBillingInvoicingDetails]
 ** Author:  Moin Bloch  
 ** Description: This stored procedure is used to store Billing Details
 ** Purpose:           
 ** Date:   07/05/2025                      
 ** PARAMETERS:            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
    1    07/05/2025   MOIN BLOCH     Created  
    2    21/05/2025   RAJESH GAMI    Make it common for all module
	3    12/06/2025   MOIN BLOCH     Added MPN Cost Details
	4    13/06/2025   MOIN BLOCH     Added CustomerId,WorkFlowWorkOrderId

-- EXEC USP_AddBillingInvoicingDetails 
************************************************************************/  
  
CREATE    PROCEDURE [dbo].[USP_AddBillingInvoicingDetails]  
-------------------------------------------BillingInvoicing-------------------------------------------
@BillingInvoicingId BIGINT = NULL,  
@ModuleId INT = NULL,
@ReferenceId BIGINT = NULL,
@InvoiceTypeId INT= NULL,
@InvoiceNo VARCHAR(256) = NULL,
@InvoiceDate DATETIME2(7) = NULL,
@InvoiceTime VARCHAR(10) = NULL,
@PrintDate DATETIME2(7) = NULL,
@EmployeeId BIGINT = NULL,
@CurrencyId INT = NULL,
@RevisionTypeId BIGINT = NULL,
@InvoiceStatusId INT = NULL,
@InvoiceStatus VARCHAR(50) = NULL,
@InvoiceFilePath VARCHAR(1000) = NULL,
@RevType VARCHAR(200) = NULL,
@VersionNo VARCHAR(10) = NULL,
@CostPlusType VARCHAR(50) = NULL,
@IsPerformaInvoice BIT = 0,
@IsVersionIncrease BIT = 0,
@PostedDate DATETIME2(7) = NULL,
@SubTotal DECIMAL(18,2) = 0,
@OtherTax DECIMAL(18,2) = 0,
@SalesTax DECIMAL(18,2) = 0,
@DepositAmount DECIMAL(18,2) = 0,
@GrandTotal DECIMAL(18,2) = NULL,
@Notes NVARCHAR(MAX) = NULL,
@ManagementStructureId BIGINT = NULL,
@MasterCompanyId INT = NULL,
@CreatedBy VARCHAR(256) = NULL,
@UpdatedBy VARCHAR(256) = NULL,
@CreatedDate DATETIME2(7) = NULL,
@UpdatedDate DATETIME2(7) = NULL,
@IsActive BIT = 1,
@IsDeleted BIT = 0,
@IsReversedJE BIT = 0,
@QuickBooksReferenceId VARCHAR(200) = NULL,
@IsUpdated BIT = 0,
@LastSyncDate DATETIME2(7) = NULL,
@SyncToken VARCHAR(200) = NULL,
@IsCreatedFromQuote BIT = 0,
@IsQuickBookGeneratedInvoice BIT = NULL,
-------------------------------------------BillingInvoicingDetails-------------------------------------------
@SoldToCustomerId BIGINT = NULL,
@SoldToSiteId BIGINT = NULL,
@SoldToAttention VARCHAR(256) = NULL,
@ShipToCustomerId BIGINT = NULL,
@ShipToSiteId BIGINT = NULL,
@ShipToAttention VARCHAR(256) = NULL,
@CustomerDomensticShippingShipViaId BIGINT = NULL,
@WayBillRef VARCHAR(100) = NULL,
@ShipAccountInfo VARCHAR(200) = NULL,
-------------------------------------------BillingInvoicingItems-------------------------------------------
@tbl_BillingInvoicingItemsType BillingInvoicingItemsType READONLY
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;   
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN    
	DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT, @TotalRecord INT = 0,@MinId BIGINT = 1, @CommonBillingInvoicingId BIGINT = NULL;
	DECLARE @CodePrefix NVARCHAR(50),@CodeSuffix NVARCHAR(50),@VerCodePrefix NVARCHAR(50)
	DECLARE @BilledInvoiceStatusId INT = 0,@WorkOrderMPNModuleID INT 
	DECLARE @BilledInvoiceStatus VARCHAR(50), @InvoiceCodeTypeId INT,@ProformaInvoiceCodeTypeId INT,@VerCode INT
	DECLARE @CurrentNo INT = 0, @TemplateBody VARCHAR(MAX)='',@PartNumber VARCHAR(50)='', @BillingInvoicingIdNew BIGINT = 0
	DECLARE @RemainingAmount DECIMAL(18,2) = 0,@CustomerId BIGINT
	
	SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';

	SET @CreatedDate = GETUTCDATE();
    SET @UpdatedDate = GETUTCDATE();
	
	SELECT @BilledInvoiceStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [Status] = 'Billed';		
	SELECT @BilledInvoiceStatus = [Status] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [InvoiceStatusId] = @BilledInvoiceStatusId;	
	SELECT @VerCode  = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Version';	

	IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
	BEGIN
		SELECT @InvoiceCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='WOInvoice';
		SELECT @ProformaInvoiceCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='WOProformaInvoice';
		SELECT @WorkOrderMPNModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrderMPN';
		SELECT @CustomerId = [CustomerId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @ReferenceId
	END
	ELSE IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
	BEGIN
		SELECT @InvoiceCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='SOInvoice';
		SELECT @ProformaInvoiceCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='SOProformaInvoice';
		SELECT @CustomerId = [CustomerId] FROM [dbo].[SalesOrder] WITH(NOLOCK) WHERE [SalesOrderId] = @ReferenceId

		SELECT @CommonBillingInvoicingId = BillingInvoicingId
					FROM @tbl_BillingInvoicingItemsType
					WHERE BillingInvoicingId <> 0 GROUP BY BillingInvoicingId HAVING COUNT(*) = (SELECT COUNT(*) FROM @tbl_BillingInvoicingItemsType WHERE BillingInvoicingId <> 0) AND COUNT(DISTINCT BillingInvoicingId) = 1;
		
		IF(@CommonBillingInvoicingId > 0)
		BEGIN
			SET @InvoiceNo = (SELECT TOP 1 InvoiceNo FROM dbo.BillingInvoicing WITH(NOLOCK) Where BillingInvoicingId = @CommonBillingInvoicingId)
		END	

	END
	ELSE IF(@ModuleId = @EXModuleId) /*********START: Exchange  ********/
	BEGIN
		PRINT '---------------Exchange----------------'
	END

	IF (@IsPerformaInvoice = 0)
	BEGIN
		SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @InvoiceCodeTypeId AND [MasterCompanyId] = @MasterCompanyId;
	END
	IF (@IsPerformaInvoice = 1)
	BEGIN
		SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @ProformaInvoiceCodeTypeId AND [MasterCompanyId] = @MasterCompanyId;
	END

	SELECT TOP 1 @VerCodePrefix = [CodePrefix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @VerCode AND [MasterCompanyId] = @MasterCompanyId;

		-- Check for current number and increment
		IF(@CommonBillingInvoicingId IS NULL)
		BEGIN
			IF COALESCE(@CodePrefix, '') <> ''
			BEGIN
				SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;        
				IF @CurrentNo > 0
				BEGIN
					SET @CurrentNo = @CurrentNo + 1;
					UPDATE [dbo].[CodePrefixes] 
					SET [CurrentNummber] = @CurrentNo
					WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
				END
				ELSE
				BEGIN
					SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0)  FROM [dbo].[CodePrefixes] WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
					UPDATE [dbo].[CodePrefixes]
					SET [CurrentNummber] = @CurrentNo 
					WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
				END			
				SET @InvoiceNo = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
			END
			ELSE
			BEGIN			
				SET @InvoiceNo = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNo, '',''))
			END
		END

        DECLARE @VersionNum INT= 0;
		IF (@VersionNo IS NOT NULL AND LEN(@VersionNo) > 0)
		BEGIN
			IF (LEN(@VersionNo) > 6)
			BEGIN
				DECLARE @Part2 NVARCHAR(20) = PARSENAME(REPLACE(@VersionNo, '-', '.'), 1);
				IF (@Part2 IS NOT NULL AND ISNUMERIC(@Part2) = 1)
				BEGIN
					SET @VersionNum = CAST(@Part2 AS INT) + 1;
				END
			END
			ELSE
			BEGIN
				SET @VersionNum = CAST(SUBSTRING(@VersionNo, 3, LEN(@VersionNo)) AS INT) + 1;
			END

			SET @VersionNo = (SELECT * FROM [dbo].[udfGenerateCodeNumber](@VersionNum, ISNULL(@VerCodePrefix,''),''));
		END
		ELSE
		BEGIN			
			SET @VersionNo = (SELECT * FROM [dbo].[udfGenerateCodeNumber](1, ISNULL(@VerCodePrefix,''),''));
		END			
		
		IF OBJECT_ID(N'tempdb..#tmprAddBillingInvoicingDetailsTemp') IS NOT NULL
		BEGIN
			DROP TABLE #tmprAddBillingInvoicingDetailsTemp
		END

		CREATE TABLE #tmprAddBillingInvoicingDetailsTemp
		(
			[PKID] [BIGINT] NOT NULL IDENTITY,
			[BillingInvoicingItemId] [BIGINT] NULL,
			[BillingInvoicingId] [BIGINT] NULL,
			[ModuleId] [INT] NULL,
			[ReferenceId] [BIGINT] NULL,
			[SubModuleId] [INT] NULL,
			[SubReferenceId] [BIGINT] NULL,
			[ItemMasterId] [BIGINT] NULL,
			[StocklineId] [BIGINT] NULL,
			[ConditionId] [BIGINT] NULL,
			[CostPlusType] [VARCHAR](50) NULL,
			[UnitPrice] [DECIMAL](18, 2) NULL,
			[QtyBilled] [INT] NULL,
			[PartCost] [DECIMAL](18, 2) NULL,
			[IsTotalCheck] [bit] NULL,
			[TotalBillingCost] [decimal](18, 2) NULL,
			[TotalBillingCostPercent] [bigint] NULL,
			[TotalBillingCostPlus] [decimal](18, 2) NULL,
			[IsMaterialCheck] [bit] NULL,				
			[MaterialCost] [DECIMAL](18, 2) NULL,
			[MaterialCostPercent] [BIGINT] NULL,
			[MaterialCostPlus] [DECIMAL](18, 2) NULL,
			[IsLaborCheck] [bit] NULL,		
			[LaborCost] [DECIMAL](18, 2) NULL,
			[LaborCostPercent] [BIGINT] NULL,
			[LaborCostPlus] [DECIMAL](18, 2) NULL,
			[IsFreightCheck] [bit] NULL,	
			[Freight] [DECIMAL](18, 2) NULL,
			[FreightCostPercent] [BIGINT] NULL,
			[FreightCostPlus] [DECIMAL](18, 2) NULL,
			[IsMiscChargesCheck] [bit] NULL,
			[MiscCharges] [DECIMAL](18, 2) NULL,
			[MiscChargesCostPercent] [BIGINT] NULL,
			[MiscChargesCostPlus] [DECIMAL](18, 2) NULL,
			[SubTotal] [DECIMAL](18, 2) NULL,
			[SalesTaxPercent] [BIGINT] NULL,
			[SalesTax] [DECIMAL](18, 2) NULL,
			[OtherTaxPercent] [BIGINT] NULL,
			[OtherTax] [DECIMAL](18, 2) NULL,
			[GrandTotal] [DECIMAL](18, 2) NULL,
			[PDFPath] [NVARCHAR](MAX) NULL,
			[VersionNo] [VARCHAR](20) NULL,
			[IsVersionIncrease] [BIT] NULL,
			[IsPerformaInvoice] [BIT] NULL,
			[MasterCompanyId] [INT] NULL,
			[CreatedBy] [VARCHAR](256) NULL,
			[UpdatedBy] [VARCHAR](256) NULL,
			[CreatedDate] [DATETIME2](7) NULL,
			[UpdatedDate] [DATETIME2](7) NULL,
			[IsActive] [BIT] NULL,
			[IsDeleted] [BIT] NULL
		)

		SET @SubTotal = 0;
		SET @SalesTax = 0;
		SET @OtherTax = 0;
		SET @GrandTotal = 0;
		SET @RemainingAmount = 0;
		
		SELECT @SubTotal = ISNULL(SUM([SubTotal]),0),
		       @SalesTax = ISNULL(SUM([SalesTax]),0), 
			   @OtherTax = ISNULL(SUM([OtherTax]),0), 
			   @GrandTotal = ISNULL(SUM([GrandTotal]),0), 
			   @RemainingAmount = ISNULL(SUM([GrandTotal]),0) 
		  FROM @tbl_BillingInvoicingItemsType;

		INSERT INTO [dbo].[BillingInvoicing]
				   ([ModuleId],[ReferenceId],[CustomerId],[InvoiceTypeId],[InvoiceNo],[InvoiceDate],[InvoiceTime],[PrintDate],[EmployeeId]
				   ,[CurrencyId],[RevisionTypeId],[InvoiceStatusId],[InvoiceStatus],[InvoiceFilePath],[RevType],[VersionNo],[CostPlusType]
				   ,[IsPerformaInvoice],[IsVersionIncrease],[PostedDate],[SubTotal],[OtherTax],[SalesTax],[DepositAmount],[GrandTotal]
				   ,[Notes],[ManagementStructureId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
				   ,[IsActive],[IsDeleted],[IsReversedJE],[QuickBooksReferenceId],[IsUpdated],[LastSyncDate],[SyncToken]
				   ,[IsCreatedFromQuote],[IsQuickBookGeneratedInvoice],[RemainingAmount])		 
			 VALUES (@ModuleId, @ReferenceId, @CustomerId, @InvoiceTypeId, @InvoiceNo, @InvoiceDate, @InvoiceTime, @PrintDate, @EmployeeId,
					 @CurrencyId, @RevisionTypeId, @InvoiceStatusId, @InvoiceStatus, @InvoiceFilePath, @RevType, @VersionNo, @CostPlusType,
					 @IsPerformaInvoice, @IsVersionIncrease, @PostedDate, @SubTotal, @OtherTax, @SalesTax, @DepositAmount, @GrandTotal,
					 @Notes, @ManagementStructureId, @MasterCompanyId, @CreatedBy, @CreatedBy, @CreatedDate, @CreatedDate,
					 @IsActive, @IsDeleted, @IsReversedJE, @QuickBooksReferenceId, @IsUpdated, @LastSyncDate, @SyncToken,
					 @IsCreatedFromQuote, @IsQuickBookGeneratedInvoice,@RemainingAmount);
				 
		SET @BillingInvoicingIdNew = SCOPE_IDENTITY();	  

		INSERT INTO [dbo].[BillingInvoicingDetails]
				   ([BillingInvoicingId],[SoldToCustomerId],[SoldToSiteId],[SoldToAttention],[ShipToCustomerId]
				   ,[ShipToSiteId],[ShipToAttention],[CustomerDomensticShippingShipViaId],[WayBillRef],[ShipAccountInfo])
			VALUES (@BillingInvoicingIdNew, @SoldToCustomerId, @SoldToSiteId,@SoldToAttention, @ShipToCustomerId, 
					@ShipToSiteId,@ShipToAttention, @CustomerDomensticShippingShipViaId,@WayBillRef, @ShipAccountInfo);

		INSERT INTO #tmprAddBillingInvoicingDetailsTemp([BillingInvoicingItemId],[BillingInvoicingId],[ModuleId],[ReferenceId],[SubModuleId],
					[SubReferenceId],[ItemMasterId],[StocklineId],[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],
					[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
					[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],
					[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],
					[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],
					[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],
					[PDFPath],[VersionNo],[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],PartCost)
			SELECT  [BillingInvoicingItemId],[BillingInvoicingId],@ModuleId,[ReferenceId],[SubModuleId],
					[SubReferenceId],[ItemMasterId],[StocklineId],[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],
					[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
					[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],
					[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],
					[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],
					[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],
					[PDFPath],@VersionNo,[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,0,PartCost
			   FROM @tbl_BillingInvoicingItemsType

		SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprAddBillingInvoicingDetailsTemp    

		WHILE @MinId <= @TotalRecord /****** START : MAIN WHILE LOOP *******/
		BEGIN  
			DECLARE @BillingInvoicingItemId BIGINT = 0,@SubReferenceId BIGINT = 0,@WorkFlowWorkOrderId BIGINT = NULL

			 SELECT @BillingInvoicingId = ISNULL([BillingInvoicingId],0),
			        @BillingInvoicingItemId = ISNULL([BillingInvoicingItemId],0),
					@SubReferenceId = [SubReferenceId]
			  FROM #tmprAddBillingInvoicingDetailsTemp WHERE [PKID] = @MinId 

			IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
			BEGIN
				SELECT @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId]=@SubReferenceId;				
			END
			
			IF(@BillingInvoicingId = 0)
			BEGIN
				INSERT INTO [dbo].[BillingInvoicingItems]([BillingInvoicingId],[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[ItemMasterId],[StocklineId]
						   ,[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus]
						   ,[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus]
						   ,[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent]
						   ,[SalesTax],[OtherTaxPercent],[OtherTax],[GrandTotal],[RemainingAmount],[PDFPath],[VersionNo],[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId]
						   ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartCost],[WorkFlowWorkOrderId])
					SELECT  @BillingInvoicingIdNew,[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[ItemMasterId],[StocklineId],
							[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
							[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],
							[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],
							[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],[GrandTotal],[PDFPath],[VersionNo],[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],
							@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,0,[PartCost],@WorkFlowWorkOrderId
					  FROM #tmprAddBillingInvoicingDetailsTemp WHERE [PKID] = @MinId
			END
			ELSE
			BEGIN				
				DECLARE @VersionNums INT= 0;
				SELECT @VersionNo = [VersionNo] FROM [dbo].[BillingInvoicingItems] WITH(NOLOCK) WHERE [BillingInvoicingItemId] = @BillingInvoicingItemId AND [BillingInvoicingId] = @BillingInvoicingId; 
				
				IF (@VersionNo IS NOT NULL AND LEN(@VersionNo) > 0)
				BEGIN
					IF (LEN(@VersionNo) > 6)
					BEGIN
						DECLARE @Part3 NVARCHAR(20) = PARSENAME(REPLACE(@VersionNo, '-', '.'), 1);
						IF (@Part3 IS NOT NULL AND ISNUMERIC(@Part3) = 1)
						BEGIN
							SET @VersionNum = CAST(@Part3 AS INT) + 1;
						END
					END
					ELSE
					BEGIN
						SET @VersionNum = CAST(SUBSTRING(@VersionNo, 3, LEN(@VersionNo)) AS INT) + 1;
					END
					SET @VersionNo = (SELECT * FROM [dbo].[udfGenerateCodeNumber](@VersionNum, ISNULL(@VerCodePrefix,''),''));
				END
				
			    UPDATE [dbo].[BillingInvoicing] SET [IsVersionIncrease] = 1, [InvoiceStatusId] = @BilledInvoiceStatusId, [InvoiceStatus] = @BilledInvoiceStatus WHERE [BillingInvoicingId] = @BillingInvoicingId; 

				UPDATE [dbo].[BillingInvoicingItems] SET [IsVersionIncrease] = 1, [PDFPath] = NULL  WHERE [BillingInvoicingId] = @BillingInvoicingId; 

				INSERT INTO [dbo].[BillingInvoicingItems]([BillingInvoicingId],[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[ItemMasterId],[StocklineId]
						   ,[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus]
						   ,[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus]
						   ,[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus]
						   ,[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus]
						   ,[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent]
						   ,[SalesTax],[OtherTaxPercent],[OtherTax],[GrandTotal],[RemainingAmount],[PDFPath],[VersionNo],[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId]
						   ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartCost],[WorkFlowWorkOrderId])
					SELECT  @BillingInvoicingIdNew,[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[ItemMasterId],[StocklineId],
							[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
							[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],
							[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],	
							[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],
							[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],
							[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],[GrandTotal],[PDFPath],@VersionNo,[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],
							@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,0,[PartCost],@WorkFlowWorkOrderId
					   FROM #tmprAddBillingInvoicingDetailsTemp WHERE [PKID] = @MinId
			END						

			IF(@ModuleId = @WOModuleId)
			BEGIN
				-- USED TO RECALCULATE WO TOTAL COST   
				DECLARE @WFWorkOrderId BIGINT = 0  
				SELECT TOP 1 @WFWorkOrderId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId] = @SubReferenceId

				EXEC [dbo].[USP_UpdateWOTotalCostDetails] @ReferenceId,@WFWorkOrderId,@UpdatedBy,@MasterCompanyId

				EXEC [dbo].[USP_UpdateWOCostDetails] @ReferenceId,@WFWorkOrderId,@UpdatedBy,@MasterCompanyId

				SELECT @PartNumber = IM.[PartNumber] FROM [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WP.ItemMasterId = IM.ItemMasterId WHERE WP.[ID] = @SubReferenceId;					   
				SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = 'Invoicing';								   
				SET @TemplateBody = REPLACE(@TemplateBody, '##WoMPN##', @PartNumber);
				SET @TemplateBody = REPLACE(@TemplateBody, '##InvoiceNo##', @InvoiceNo);
				EXEC [dbo].[USP_History] @WOModuleId,@ReferenceId,@WorkOrderMPNModuleID,@SubReferenceId,'False','True',@TemplateBody,'Invoicing',@MasterCompanyId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate
			END
			IF(@ModuleId = @SOModuleId)
			BEGIN
				DECLARE @SOBilledStatusId int = (select TOP 1 SOPartStatusId from SOPartStatus WHERE Description = 'Billed')
				EXEC [dbo].[SP_SaveSOPartStatusByPartId] @SalesOrderPartId  = @SubReferenceId, @StatusId = @SOBilledStatusId
			END

			SET @MinId = @MinId + 1;
		END  /****** END : MAIN WHILE LOOP *******/

	/********* Return New Billing Invoicing Id **********/
	SELECT @BillingInvoicingIdNew AS [BillingInvoicingId]  
 END   
 COMMIT  TRANSACTION  
 END TRY   
 BEGIN CATCH        
  IF @@trancount > 0  
  PRINT 'ROLLBACK'  
    ROLLBACK TRANSACTION;  
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_AddBillingInvoicingDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))  
             + '@Parameter2 = ''' + CAST(ISNULL(@ModuleId, '') AS VARCHAR(100))   
             + '@Parameter3 = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100))   
             + '@Parameter4 = ''' + CAST(ISNULL(@InvoiceTypeId, '') AS VARCHAR(100))   
             + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))    
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
 END CATCH  
END