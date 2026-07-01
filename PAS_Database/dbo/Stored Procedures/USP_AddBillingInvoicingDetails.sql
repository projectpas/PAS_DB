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
    5    23/06/2025   Moin Bloch     Added Version Increase 
	6    23/06/2025   RAJESH GAMI    Added SubModuleId for SO billing invoicing in the Item table.
	7    23/06/2025   Moin Bloch     Added WorkOrderShippingId
	8    24/06/2025   RAJESH GAMI    Fixed while IsProformaInvoice = true part status changed to BILLED.  
	9    25/06/2025   Moin Bloch     Fixed Version Increase 
	10   30/06/2025   Rajesh Gami    Fixed to version increase issue 
	11   02/07/2025   Rajesh Gami    Added Commercial InvoiceType Fields and Implement the functionality accordinlgy in the SO billing 
	12   02/07/2025   Moin Bloch     Added DepositAmount
	13   03 JUL 2025  RAJESH GAMI	 Change CustomerDomensticShippingShipViaId to ShipViaId  And Resolved issue while post the proforma
	14   28/07/2025   RAJESH GAMI     Implement the Update Revenue while generating the invoice(Update SO Stockline Cost)
	15   29/07/2025   RAJESH GAMI     Added stocklineIds while checking InvoiceNumber exist or not.(Only for SO)
	16   30/07/2025   BHARGAV SALIYA  Adde new [ShippingTermsName] field in [BillingInvoicingDetails] table and get it here
	17   05/11/2025   MOIN BLOCH      Added Credit Memo Logic   
	18   09/01/2026   Vishal Suthar  Added SerialNumber column in BillingInvoicingDetails for SA
	19   15/01/2026   Vishal Suthar  Issue with new version created for SA
	20   14/05/2026   Bhargav Saliya	Added UOM Changes [PN-15067]
	21   18/06/2026   Bhargav Saliya	Added Case For Skip UOM Function If FROM uom and TO uom Both are Same
	22   25/06/2025   Bhargav Saliya    Resolved Billing Issue[PN-16983]
	23   30/06/2025   Bhargav Saliya    Resolved Billing Issue[PN-17030]
-- EXEC USP_AddBillingInvoicingDetails 
************************************************************************/  
  
CREATE       PROCEDURE [dbo].[USP_AddBillingInvoicingDetails]  
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
@SubTotal DECIMAL(18,6) = 0,
@OtherTax DECIMAL(18,2) = 0,
@SalesTax DECIMAL(18,2) = 0,
@DepositAmount DECIMAL(18,6) = 0,
@GrandTotal DECIMAL(18,6) = NULL,
@Notes NVARCHAR(MAX) = NULL,
@WorkOrderShippingId  BIGINT = NULL,
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
@ShipViaId BIGINT = NULL,
@WayBillRef VARCHAR(100) = NULL,
@ShipAccountInfo VARCHAR(200) = NULL,
@OriginCountryId INT = NULL,
@DestinationCountryId INT = NULL,
@SignEmpId BIGINT = NULL,
@SignEmpDate DATETIME2(7) = NULL,
@ShippingTermsName VARCHAR(256) = NULL,
@SerialNumber VARCHAR(256) = NULL,
@IsNewVersion bit = NULL,
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
	DECLARE @BilledInvoiceStatusId INT = 0,@WorkOrderMPNModuleID INT ,@SOPartModuleId INT 
	DECLARE @BilledInvoiceStatus VARCHAR(50), @InvoiceCodeTypeId INT,@ProformaInvoiceCodeTypeId INT,@VerCode INT
	DECLARE @CurrentNo INT = 0, @TemplateBody VARCHAR(MAX)='',@PartNumber VARCHAR(50)='', @BillingInvoicingIdNew BIGINT = 0
	DECLARE @RemainingAmount DECIMAL(18,6) = 0,@CustomerId BIGINT
	DECLARE @UnitSalePrice DECIMAL(18,6) = 0,@MarkUpPercentage  DECIMAL(18,2) = 0,@DiscountPercentage DECIMAL(18,2) = 0,@MarkUpAmount DECIMAL(18,6) = 0,@DiscountAmount DECIMAL(18,6) = 0,@PartQty DECIMAL(18,6) = 0;
	DECLARE @StocklineId BIGINT = 0, @SOStocklineId BIGINT = 0,@NetSalePrice DECIMAL(18,6) = 0, @SOStockLineCostId BIGINT = 0 , @QtyOrder DECIMAL(18,6) = 0 , @NetSalePriceExtended  BIGINT = 0,@ChargesAmount AS DECIMAL(18, 4);
	SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
	DECLARE @InvoicedStatusId INT = 0,@InvoicedStatus VARCHAR(50) 

	SET @CreatedDate = GETUTCDATE();
    SET @UpdatedDate = GETUTCDATE();
	
	SELECT @BilledInvoiceStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [Status] = 'Billed';		
	SELECT @BilledInvoiceStatus = [Status] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [InvoiceStatusId] = @BilledInvoiceStatusId;
	SELECT @VerCode  = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Version';	

	SELECT @InvoicedStatusId = [InvoiceStatusId] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [Status] = 'Invoiced';		
	SELECT @InvoicedStatus = [Status] FROM [dbo].[InvoiceStatus] WITH(NOLOCK) WHERE [InvoiceStatusId] = @InvoicedStatusId;		
		
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
		SELECT @SOPartModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='SalesOrderPart';
		SELECT @CustomerId = [CustomerId] FROM [dbo].[SalesOrder] WITH(NOLOCK) WHERE [SalesOrderId] = @ReferenceId		
	END
	ELSE IF(@ModuleId = @EXModuleId) /*********START: Exchange  ********/
	BEGIN
		PRINT '---------------Exchange----------------'
	END

	DECLARE @SubReferenceIds VARCHAR(MAX) = '', @StocklineIds VARCHAR(MAX) = '' ;
	DECLARE @TotalRecordI INT = 0,@MinIdI BIGINT = 1,@isCreateNewInvoice BIT=0

	SELECT @SubReferenceIds = STRING_AGG([SubReferenceId], ',') FROM @tbl_BillingInvoicingItemsType WHERE [BillingInvoicingId] > 0
	SELECT @StocklineIds = ISNULL(STRING_AGG([StocklineId], ','), '') FROM @tbl_BillingInvoicingItemsType WHERE [BillingInvoicingId] > 0   AND StocklineId IS NOT NULL AND StocklineId <> 0;
	IF OBJECT_ID(N'tempdb..#tmprAddBillingInvoicingDetailsTempForInvoiceNo') IS NOT NULL
	BEGIN
		DROP TABLE #tmprAddBillingInvoicingDetailsTempForInvoiceNo
	END

	CREATE TABLE #tmprAddBillingInvoicingDetailsTempForInvoiceNo
	(
		[PKID] [BIGINT] NOT NULL IDENTITY,			
		[BillingInvoicingId] [BIGINT] NULL,
		[ModuleId] [INT] NULL,
		[ReferenceId] [BIGINT] NULL,
		[SubModuleId] [INT] NULL,
		[SubReferenceId] [BIGINT] NULL,
		[IsPerformaInvoice] [BIT] NULL		
	)
	INSERT INTO #tmprAddBillingInvoicingDetailsTempForInvoiceNo([BillingInvoicingId],[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[IsPerformaInvoice])
	SELECT [BillingInvoicingId],@ModuleId,[ReferenceId],[SubModuleId],[SubReferenceId],[IsPerformaInvoice] FROM @tbl_BillingInvoicingItemsType
	
	SELECT @TotalRecordI = COUNT(*), @MinIdI = MIN([PKID]) FROM #tmprAddBillingInvoicingDetailsTempForInvoiceNo    

	WHILE @MinIdI <= @TotalRecordI 
	BEGIN		
		DECLARE @BillingInvoicingIdI BIGINT = 0,@IsPerformaInvoiceI BIT = 0,@isNewInvoice BIT = 0
		 SELECT @BillingInvoicingIdI = ISNULL([BillingInvoicingId],0),
			    @IsPerformaInvoiceI = ISNULL([IsPerformaInvoice],0)
		  FROM #tmprAddBillingInvoicingDetailsTempForInvoiceNo WHERE [PKID] = @MinIdI 

		EXEC [dbo].[USP_CheckWOInvoiceExistByWOBillId] @BillingInvoicingIdI,@SubReferenceIds,@StocklineIds,@IsPerformaInvoiceI,@ModuleId,@Result = @isNewInvoice OUTPUT

		--IF (@MasterCompanyId = 12)
		--BEGIN
		--	IF (ISNULL(@IsNewVersion, 0) = 0)
		--	BEGIN
		--		SET @isNewInvoice = 1;
		--	END
		--	ELSE
		--	BEGIN
		--		SET @IsVersionIncrease = 1;
		--	END
		--END

		SET @IsNewVersion = ISNULL(@IsNewVersion, 0);

		IF (@MasterCompanyId = 12)
		BEGIN
			IF (@IsNewVersion = 0)
			BEGIN
				SET @isNewInvoice = 1;
			END
		END

		IF (@MasterCompanyId = 12)
		BEGIN
			IF (ISNULL(@IsNewVersion, 0) = 1)
			BEGIN
				-- NEW VERSION
				SET @isNewInvoice = 0;
				SET @IsVersionIncrease = 1;
			END
			ELSE
			BEGIN
				-- NEW INVOICE
				SET @isNewInvoice = 1;
				SET @IsVersionIncrease = 0;
				--SET @VersionNo = NULL;
				SET @InvoiceNo = '';
			END
		END

		IF(ISNULL(@isNewInvoice,0) = 0)
		BEGIN
			SET @InvoiceNo = (SELECT [InvoiceNo] FROM dbo.BillingInvoicing WHERE [BillingInvoicingId] = @BillingInvoicingIdI)
			SET @VersionNo = NULL
		END
		ELSE
		BEGIN
			SET @InvoiceNo = '';
			SET @isCreateNewInvoice = 1
		END
		IF(@isCreateNewInvoice = 1)
        BEGIN
			SET @InvoiceNo = '';
			SET @isNewInvoice = 1
		END
		SET @MinIdI = @MinIdI + 1;
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
		IF(@InvoiceNo = '' OR @InvoiceNo IS NULL)
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

		IF (@MasterCompanyId = 12 AND ISNULL(@IsNewVersion, 0) = 1 AND @BillingInvoicingIdI > 0)
		BEGIN
			UPDATE dbo.BillingInvoicing
			SET IsVersionIncrease = 1,
				UpdatedBy = @UpdatedBy,
				UpdatedDate = @UpdatedDate
			WHERE BillingInvoicingId = @BillingInvoicingIdI;

			UPDATE [dbo].[BillingInvoicingItems] SET [IsVersionIncrease] = 1 WHERE BillingInvoicingId = @BillingInvoicingIdI;
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
			[UnitPrice] [DECIMAL](18, 6) NULL,
			[QtyBilled] [DECIMAL](18, 6) NULL,
			[PartCost] [DECIMAL](18, 6) NULL,
			[IsTotalCheck] [bit] NULL,
			[TotalBillingCost] [decimal](18, 6) NULL,
			[TotalBillingCostPercent] [bigint] NULL,
			[TotalBillingCostPlus] [decimal](18, 6) NULL,
			[IsMaterialCheck] [bit] NULL,				
			[MaterialCost] [DECIMAL](18, 6) NULL,
			[MaterialCostPercent] [BIGINT] NULL,
			[MaterialCostPlus] [DECIMAL](18, 6) NULL,
			[IsLaborCheck] [bit] NULL,		
			[LaborCost] [DECIMAL](18, 6) NULL,
			[LaborCostPercent] [BIGINT] NULL,
			[LaborCostPlus] [DECIMAL](18, 6) NULL,
			[IsFreightCheck] [bit] NULL,	
			[Freight] [DECIMAL](18, 2) NULL,
			[FreightCostPercent] [BIGINT] NULL,
			[FreightCostPlus] [DECIMAL](18, 6) NULL,
			[IsMiscChargesCheck] [bit] NULL,
			[MiscCharges] [DECIMAL](18, 2) NULL,
			[MiscChargesCostPercent] [BIGINT] NULL,
			[MiscChargesCostPlus] [DECIMAL](18, 6) NULL,
			[SubTotal] [DECIMAL](18, 6) NULL,
			[SalesTaxPercent] [BIGINT] NULL,
			[SalesTax] [DECIMAL](18, 2) NULL,
			[OtherTaxPercent] [BIGINT] NULL,
			[OtherTax] [DECIMAL](18, 2) NULL,
			[GrandTotal] [DECIMAL](18, 6) NULL,
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
			[IsDeleted] [BIT] NULL,
			[ShippingId] [bigint] NULL,
			[UnitSalePrice] [decimal](18, 6) NULL,
			[MarkUpPercentage] [decimal](18, 6) NULL,
			[DiscountPercentage] [decimal](18, 6) NULL,
			[MarkUpAmount] [decimal](18, 6) NULL,
			[DiscountAmount] [decimal](18, 6) NULL
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
				   ,[IsCreatedFromQuote],[IsQuickBookGeneratedInvoice],[RemainingAmount],[WorkOrderShippingId],OriginCountryId,ShipToCountryId,SignEmpId,SignEmpDate)		 
			 VALUES (@ModuleId, @ReferenceId, @CustomerId, @InvoiceTypeId, @InvoiceNo, @CreatedDate, @InvoiceTime, @PrintDate, @EmployeeId,
					 @CurrencyId, @RevisionTypeId, @InvoiceStatusId, @InvoiceStatus, @InvoiceFilePath, @RevType, @VersionNo, @CostPlusType,
					 @IsPerformaInvoice, 
					 --@IsVersionIncrease, 
					 CASE 
						WHEN @MasterCompanyId = 12 AND ISNULL(@IsNewVersion,0) = 1 THEN 0
						ELSE @IsVersionIncrease
					 END,
					 @PostedDate, @SubTotal, @OtherTax, @SalesTax, @DepositAmount, @GrandTotal,
					 @Notes, @ManagementStructureId, @MasterCompanyId, @CreatedBy, @CreatedBy, @CreatedDate, @CreatedDate,
					 @IsActive, @IsDeleted, @IsReversedJE, @QuickBooksReferenceId, @IsUpdated, @LastSyncDate, @SyncToken,
					 @IsCreatedFromQuote, @IsQuickBookGeneratedInvoice,@RemainingAmount,@WorkOrderShippingId,@OriginCountryId,@DestinationCountryId,@SignEmpId,@SignEmpDate);
				 
		SET @BillingInvoicingIdNew = SCOPE_IDENTITY();	  

		INSERT INTO [dbo].[BillingInvoicingDetails]
				   ([BillingInvoicingId],[SoldToCustomerId],[SoldToSiteId],[SoldToAttention],[ShipToCustomerId]
				   ,[ShipToSiteId],[ShipToAttention],[ShipViaId],[WayBillRef],[ShipAccountInfo],[ShippingTermsName])
			VALUES (@BillingInvoicingIdNew, @SoldToCustomerId, @SoldToSiteId,@SoldToAttention, @ShipToCustomerId, 
					@ShipToSiteId,@ShipToAttention, @ShipViaId,@WayBillRef, @ShipAccountInfo,@ShippingTermsName);

		INSERT INTO #tmprAddBillingInvoicingDetailsTemp([BillingInvoicingItemId],[BillingInvoicingId],[ModuleId],[ReferenceId],[SubModuleId],
					[SubReferenceId],[ItemMasterId],[StocklineId],[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],
					[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
					[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],
					[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],
					[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],
					[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],
					[PDFPath],[VersionNo],[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartCost],[ShippingId],
					[UnitSalePrice],[MarkUpPercentage],[DiscountPercentage],[MarkUpAmount],[DiscountAmount])
			SELECT  [BillingInvoicingItemId],[BillingInvoicingId],@ModuleId,[ReferenceId],[SubModuleId],
					[SubReferenceId],[ItemMasterId],[StocklineId],[ConditionId],[CostPlusType],[UnitPrice],CASE WHEN  ISNULL([QtyBilled],0) = 0 THEN 1 ELSE [QtyBilled] END,
					[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
					[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],
					[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],
					[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],
					[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],
					[PDFPath],@VersionNo,[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,0,[PartCost],[ShippingId],
					[UnitSalePrice],[MarkUpPercentage],[DiscountPercentage],[MarkUpAmount],[DiscountAmount]
			   FROM @tbl_BillingInvoicingItemsType

		UPDATE #tmprAddBillingInvoicingDetailsTemp SET [SubModuleId] = @SOPartModuleId WHERE [ModuleId] = @SOModuleId;
		
		SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprAddBillingInvoicingDetailsTemp    

		WHILE @MinId <= @TotalRecord /****** START : MAIN WHILE LOOP *******/
		BEGIN  
			DECLARE @BillingInvoicingItemId BIGINT = 0,@SubReferenceId BIGINT = 0,@WorkFlowWorkOrderId BIGINT = NULL,@ShippingId BIGINT = 0
			DECLARE @ShipDate DATETIME2(7) = NULL

			UPDATE TEMP_TABLE
			SET
				[UnitPrice]     = (CASE WHEN ISNULL(IM.[ConsumeUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'') THEN ISNULL([UnitPrice], 0)     ELSE [dbo].[fn_ConvertUOM](ISNULL([UnitPrice], 0),    IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure],1,TEMP_TABLE.MasterCompanyId) END),
				[QtyBilled]     = (CASE WHEN ISNULL(IM.[ConsumeUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'') THEN ISNULL([QtyBilled], 0)     ELSE [dbo].[fn_ConvertUOM](ISNULL([QtyBilled], 0),    IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure],0,TEMP_TABLE.MasterCompanyId) END),
				[UnitSalePrice] = (CASE WHEN ISNULL(IM.[ConsumeUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'') THEN ISNULL([UnitSalePrice], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL([UnitSalePrice], 0), IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure],1,TEMP_TABLE.MasterCompanyId) END),
				[PartCost]     = (CASE WHEN ISNULL(IM.[ConsumeUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'') THEN ISNULL([PartCost], 0)     ELSE [dbo].[fn_ConvertUOM](ISNULL([PartCost], 0),    IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure],1,TEMP_TABLE.MasterCompanyId) END)
			FROM #tmprAddBillingInvoicingDetailsTemp TEMP_TABLE
			JOIN dbo.ItemMaster IM WITH(NOLOCK) ON TEMP_TABLE.ItemMasterId = IM.ItemMasterId
			WHERE [PKID] = @MinId

			 SELECT @BillingInvoicingId = ISNULL([BillingInvoicingId],0),
			        @BillingInvoicingItemId = ISNULL([BillingInvoicingItemId],0),
					@SubReferenceId = [SubReferenceId],
					@ShippingId = ISNULL([ShippingId],0), 
					@StocklineId = ISNULL(StocklineId,0),
					@UnitSalePrice = ISNULL(UnitSalePrice,0),
					@MarkUpPercentage = ISNULL(MarkUpPercentage,0),
					@DiscountPercentage = ISNULL(DiscountPercentage,0),
					@MarkUpAmount = ISNULL(MarkUpAmount,0),
					@DiscountAmount = ISNULL(DiscountAmount,0),
					@NetSalePrice = ISNULL(UnitPrice,0),
					@NetSalePriceExtended =  ISNULL(PartCost,0)
			  FROM #tmprAddBillingInvoicingDetailsTemp WHERE [PKID] = @MinId 

			IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
			BEGIN
				SELECT @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId]=@SubReferenceId;
				IF(@ShippingId > 0)
				BEGIN
					SELECT @ShipDate = [ShipDate] FROM [dbo].[WorkOrderShipping] WITH(NOLOCK) WHERE [WorkOrderShippingId]=@ShippingId; 
				END
			END
			IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
			BEGIN
				IF(@ShippingId > 0)
				BEGIN
					SELECT @ShipDate = [ShipDate] FROM [dbo].[SalesOrderShipping] WITH(NOLOCK) WHERE [SalesOrderShippingId]=@ShippingId; 
				END
			END
			
			IF(@BillingInvoicingId = 0)
			BEGIN
				INSERT INTO [dbo].[BillingInvoicingItems]([BillingInvoicingId],[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[ItemMasterId],[StocklineId]
						   ,[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus]
						   ,[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus]
						   ,[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent]
						   ,[SalesTax],[OtherTaxPercent],[OtherTax],[GrandTotal],[RemainingAmount],[PDFPath],[VersionNo],[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId]
						   ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartCost],[WorkFlowWorkOrderId],[ShippingId],[ShipDate],[DepositAmount],[SerialNumber])
					SELECT  @BillingInvoicingIdNew,[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[ItemMasterId],[StocklineId],
							[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
							[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],
							[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],
							[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],[GrandTotal],[PDFPath],[VersionNo],[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],
							@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,0,[PartCost],@WorkFlowWorkOrderId,[ShippingId],@ShipDate,0,@SerialNumber
					  FROM #tmprAddBillingInvoicingDetailsTemp WHERE [PKID] = @MinId
			END
			ELSE
			BEGIN				
				DECLARE @VersionNums INT= 0, @StatusId INT= 0 , @CreditMemoHeaderId BIGINT = 0 
				SELECT @VersionNo = [VersionNo] FROM [dbo].[BillingInvoicingItems] WITH(NOLOCK) WHERE [BillingInvoicingItemId] = @BillingInvoicingItemId AND [BillingInvoicingId] = @BillingInvoicingId; 
				
				SELECT @StatusId = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';

				IF(@isNewInvoice = 1)
				BEGIN
					SET @VersionNo = NULL
				END
							
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
				ELSE
				BEGIN			
					SET @VersionNo = (SELECT * FROM [dbo].[udfGenerateCodeNumber](1, ISNULL(@VerCodePrefix,''),''));
				END
								
				SELECT TOP 1 @CreditMemoHeaderId = ISNULL(CM.[CreditMemoHeaderId],0)
				  FROM [dbo].[CreditMemo] CM WITH(NOLOCK)
				  INNER JOIN [dbo].[CreditMemoDetails] CD WITH(NOLOCK) ON CM.[CreditMemoHeaderId] = CD.[CreditMemoHeaderId]
					WHERE CD.[ReferenceId] = @ReferenceId 
					  AND CD.[InvoiceId] = @BillingInvoicingId
					  --AND CD.[BillingInvoicingItemId] = @BillingInvoicingItemId
					  AND CM.[StatusId] = @StatusId

				
				IF(@CreditMemoHeaderId = 0)
				BEGIN
					IF (@MasterCompanyId <> 12)
					BEGIN
						UPDATE [dbo].[BillingInvoicing] SET [IsVersionIncrease] = 1, [InvoiceStatusId] = @BilledInvoiceStatusId, [InvoiceStatus] = @BilledInvoiceStatus WHERE [BillingInvoicingId] = @BillingInvoicingId; 
					END
				END
				ELSE
				BEGIN
					UPDATE [dbo].[BillingInvoicing] SET [CreditMemoHeaderId] = @CreditMemoHeaderId,[InvoiceStatusId] = @InvoicedStatusId,[InvoiceStatus] = @InvoicedStatus,[UpdatedDate] = @UpdatedDate WHERE [BillingInvoicingId] = @BillingInvoicingId; 
				END
						
				IF(@CreditMemoHeaderId = 0)
				BEGIN
					IF(@ModuleId = @SOModuleId)
					BEGIN
						IF (@MasterCompanyId <> 12)
						BEGIN
							UPDATE [dbo].[BillingInvoicingItems] SET [IsVersionIncrease] = 1, [PDFPath] = NULL  WHERE [SubReferenceId] = @SubReferenceId AND [BillingInvoicingId] = @BillingInvoicingId AND BillingInvoicingItemId = @BillingInvoicingItemId; 
						END
					END
					ELSE IF(@ModuleId = @WOModuleId)
					BEGIN
						UPDATE [dbo].[BillingInvoicingItems] SET [IsVersionIncrease] = 1, [PDFPath] = NULL  WHERE [SubReferenceId] = @SubReferenceId AND [BillingInvoicingId] = @BillingInvoicingId; 
					END
				END

				INSERT INTO [dbo].[BillingInvoicingItems]([BillingInvoicingId],[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[ItemMasterId],[StocklineId]
						   ,[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus]
						   ,[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus]
						   ,[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus]
						   ,[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus]
						   ,[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent]
						   ,[SalesTax],[OtherTaxPercent],[OtherTax],[GrandTotal],[RemainingAmount],[PDFPath],[VersionNo],[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId]
						   ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartCost],[WorkFlowWorkOrderId],[ShippingId],[ShipDate],[DepositAmount],[SerialNumber])
					SELECT  @BillingInvoicingIdNew,[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[ItemMasterId],[StocklineId],
							[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
							[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],
							[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],	
							[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],
							[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],
							[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],[GrandTotal],[PDFPath],@VersionNo,[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],
							@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,0,[PartCost],@WorkFlowWorkOrderId,[ShippingId],@ShipDate,0,@SerialNumber
					   FROM #tmprAddBillingInvoicingDetailsTemp WHERE [PKID] = @MinId
			   
			    UPDATE [dbo].[BillingInvoicing] SET [VersionNo] = @VersionNo WHERE [BillingInvoicingId] = @BillingInvoicingIdNew; 

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
			IF(@ModuleId = @SOModuleId AND @IsPerformaInvoice = 0)
			BEGIN
				DECLARE @SOBilledStatusId int = (select TOP 1 SOPartStatusId from SOPartStatus WHERE Description = 'Billed')
				EXEC [dbo].[SP_SaveSOPartStatusByPartId] @SalesOrderPartId  = @SubReferenceId, @StatusId = @SOBilledStatusId

				/************************* START : Update the SO Revenue While Generating the Invoice ***********************/
				IF EXISTS (SELECT TOP 1 * FROM [DBO].[SalesOrderStockLineCost] WITH (NOLOCK) WHERE SalesOrderPartId = @SubReferenceId)
				BEGIN

					SELECT @ChargesAmount = ISNULL(SUM(C.BillingAmount), 0) FROM [DBO].[SalesOrderCharges] C WITH (NOLOCK)
					WHERE C.SalesOrderPartId = @SubReferenceId;

					SELECT TOP 1 @SOStocklineId= ISNULL(SalesOrderStocklineId,0), @QtyOrder = ISNULL(QtyOrder,0)  FROM SalesOrderStocklineV1 SS WITH(NOLOCK) WHERE SS.SalesOrderPartId = @SubReferenceId AND SS.StockLineId = @StocklineId AND ISNULL(IsDeleted,0) = 0 AND SS.MasterCompanyId =@MasterCompanyId
					--SET @SOStockLineCostId = (SELECT TOP 1 ISNULL(SalesOrderStockLineCostId,0)  FROM SalesOrderStockLineCost SSC WITH(NOLOCK) WHERE SSC.SalesOrderPartId = @SubReferenceId AND SSC.SalesOrderStocklineId = @SOStocklineId AND ISNULL(IsDeleted,0) = 0 AND SSC.MasterCompanyId =@MasterCompanyId)
					UPDATE SalesOrderStockLineCost 
						SET NetSaleAmount = CAST((@NetSalePrice * @QtyOrder) AS DECIMAL(18,6)), NetSaleAmountPerUnit =@NetSalePrice,
							UnitSalesPrice = CAST(ISNULL(@UnitSalePrice, 0) AS DECIMAL(18,6)),
							UnitSalesPriceExtended = CAST(ISNULL(@UnitSalePrice, 0) * ISNULL(@QtyOrder, 0) AS DECIMAL(18,6)),
							MarkUpAmount = CAST((ISNULL(@UnitSalePrice, 0) * ISNULL(@QtyOrder, 0) * ISNULL(@MarkUpPercentage, 0)) / 100.0 AS DECIMAL(18,6))
							WHERE SalesOrderPartId = @SubReferenceId AND SalesOrderStocklineId = @SOStocklineId AND ISNULL(IsDeleted,0) = 0 AND MasterCompanyId =@MasterCompanyId
				
					UPDATE SalesOrderStockLineCost 
							SET DiscountAmount = CAST(((ISNULL(UnitSalesPriceExtended,0) +  ISNULL(MarkUpAmount,0)) * ISNULL(@DiscountPercentage, 0)) / 100.0 AS DECIMAL(18,6))
							WHERE SalesOrderPartId = @SubReferenceId AND SalesOrderStocklineId = @SOStocklineId AND ISNULL(IsDeleted,0) = 0 AND MasterCompanyId =@MasterCompanyId

					UPDATE SalesOrderStockLineCost 
							SET MarginAmount = CAST((ISNULL(NetSaleAmount, 0) - ISNULL(UnitCostExtended, 0)) AS DECIMAL(18, 6)),
								MarginPercentage = 
									CASE 
										WHEN ISNULL(NetSaleAmount, 0) = 0 THEN 0
										ELSE CAST(((ISNULL(NetSaleAmount, 0) - ISNULL(UnitCostExtended, 0)) / ISNULL(NetSaleAmount, 0)) * 100 AS DECIMAL(18, 6))
									END
							WHERE SalesOrderPartId = @SubReferenceId AND SalesOrderStocklineId = @SOStocklineId AND ISNULL(IsDeleted,0) = 0 AND MasterCompanyId =@MasterCompanyId


					UPDATE DBO.SalesOrderPartCost
							SET 
							UnitSalesPriceExtended = (SELECT SUM(SOSC.UnitSalesPriceExtended) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SubReferenceId),
							UnitCostExtended = (SELECT SUM(ISNULL(SOSC.UnitCostExtended, 0)) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SubReferenceId),
							NetSaleAmount = (SELECT SUM(ISNULL(SOSC.NetSaleAmount, 0)) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SubReferenceId),
							TotalRevenue = (SELECT SUM(ISNULL(SOSC.NetSaleAmount, 0)) + ISNULL(@ChargesAmount, 0) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SubReferenceId)
							WHERE SalesOrderPartId = @SubReferenceId;
				END
				ELSE
				BEGIN
					SELECT @PartQty = QtyOrder FROM [DBO].[SalesOrderPartV1] WITH (NOLOCK) WHERE SalesOrderPartId = @SubReferenceId;
					UPDATE DBO.SalesOrderPartCost
						SET UnitSalesPriceExtended = ISNULL(UnitSalesPrice, 0) * @PartQty,
						UnitCostExtended = ISNULL(UnitCost, 0) * @PartQty,
						NetSaleAmount = (ISNULL((ISNULL(UnitSalesPrice, 0) * @PartQty), 0) + MarkUpAmount) - DiscountAmount,
						NetSaleAmountPerUnit = ((ISNULL((ISNULL(UnitSalesPrice, 0) * @PartQty), 0) + MarkUpAmount) - DiscountAmount)/ (CASE WHEN @PartQty > 0 THEN @PartQty ELSE 1 END),
						TotalRevenue = ((ISNULL((ISNULL(UnitSalesPrice, 0) * @PartQty), 0) + MarkUpAmount) - DiscountAmount) + ISNULL(@ChargesAmount, 0)
						WHERE SalesOrderPartId = @SubReferenceId;
				END
				/***************************** END :  Update the SO Revenue While Generating the Invoice ***********************/
			END

			SET @MinId = @MinId + 1;
		END  /****** END : MAIN WHILE LOOP *******/
		
		EXEC [dbo].[USP_UpdateDepositAmount] @BillingInvoicingIdNew, 0
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