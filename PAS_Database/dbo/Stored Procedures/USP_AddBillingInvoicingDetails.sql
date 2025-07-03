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
	13    03 JUL 2025   RAJESH GAMI  Change CustomerDomensticShippingShipViaId to ShipViaId 
-- EXEC USP_AddBillingInvoicingDetails 
************************************************************************/  
  
CREATE PROCEDURE [dbo].[USP_AddBillingInvoicingDetails]  
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
		SELECT @SOPartModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='SalesOrderPart';
		SELECT @CustomerId = [CustomerId] FROM [dbo].[SalesOrder] WITH(NOLOCK) WHERE [SalesOrderId] = @ReferenceId		
	END
	ELSE IF(@ModuleId = @EXModuleId) /*********START: Exchange  ********/
	BEGIN
		PRINT '---------------Exchange----------------'
	END

	DECLARE @SubReferenceIds VARCHAR(MAX) = '';
	DECLARE @TotalRecordI INT = 0,@MinIdI BIGINT = 1,@isCreateNewInvoice BIT=0

	SELECT @SubReferenceIds = STRING_AGG([SubReferenceId], ',') FROM @tbl_BillingInvoicingItemsType WHERE [BillingInvoicingId] > 0
	
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

		EXEC [dbo].[USP_CheckWOInvoiceExistByWOBillId] @BillingInvoicingIdI,@SubReferenceIds,@IsPerformaInvoiceI,@Result = @isNewInvoice OUTPUT

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
			[IsDeleted] [BIT] NULL,
			[ShippingId] [bigint] NULL
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
					 @IsPerformaInvoice, @IsVersionIncrease, @PostedDate, @SubTotal, @OtherTax, @SalesTax, @DepositAmount, @GrandTotal,
					 @Notes, @ManagementStructureId, @MasterCompanyId, @CreatedBy, @CreatedBy, @CreatedDate, @CreatedDate,
					 @IsActive, @IsDeleted, @IsReversedJE, @QuickBooksReferenceId, @IsUpdated, @LastSyncDate, @SyncToken,
					 @IsCreatedFromQuote, @IsQuickBookGeneratedInvoice,@RemainingAmount,@WorkOrderShippingId,@OriginCountryId,@DestinationCountryId,@SignEmpId,@SignEmpDate);
				 
		SET @BillingInvoicingIdNew = SCOPE_IDENTITY();	  

		INSERT INTO [dbo].[BillingInvoicingDetails]
				   ([BillingInvoicingId],[SoldToCustomerId],[SoldToSiteId],[SoldToAttention],[ShipToCustomerId]
				   ,[ShipToSiteId],[ShipToAttention],[ShipViaId],[WayBillRef],[ShipAccountInfo])
			VALUES (@BillingInvoicingIdNew, @SoldToCustomerId, @SoldToSiteId,@SoldToAttention, @ShipToCustomerId, 
					@ShipToSiteId,@ShipToAttention, @ShipViaId,@WayBillRef, @ShipAccountInfo);

		INSERT INTO #tmprAddBillingInvoicingDetailsTemp([BillingInvoicingItemId],[BillingInvoicingId],[ModuleId],[ReferenceId],[SubModuleId],
					[SubReferenceId],[ItemMasterId],[StocklineId],[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],
					[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
					[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],
					[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],
					[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],
					[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],
					[PDFPath],[VersionNo],[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartCost],[ShippingId])
			SELECT  [BillingInvoicingItemId],[BillingInvoicingId],@ModuleId,[ReferenceId],[SubModuleId],
					[SubReferenceId],[ItemMasterId],[StocklineId],[ConditionId],[CostPlusType],[UnitPrice],CASE WHEN  ISNULL([QtyBilled],0) = 0 THEN 1 ELSE [QtyBilled] END,
					[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
					[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],
					[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],
					[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],
					[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],
					[PDFPath],@VersionNo,[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,0,[PartCost],[ShippingId]
			   FROM @tbl_BillingInvoicingItemsType

		UPDATE #tmprAddBillingInvoicingDetailsTemp SET [SubModuleId] = @SOPartModuleId WHERE [ModuleId] = @SOModuleId;
		
		SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprAddBillingInvoicingDetailsTemp    

		WHILE @MinId <= @TotalRecord /****** START : MAIN WHILE LOOP *******/
		BEGIN  
			DECLARE @BillingInvoicingItemId BIGINT = 0,@SubReferenceId BIGINT = 0,@WorkFlowWorkOrderId BIGINT = NULL,@ShippingId BIGINT = 0
			DECLARE @ShipDate DATETIME2(7) = NULL

			 SELECT @BillingInvoicingId = ISNULL([BillingInvoicingId],0),
			        @BillingInvoicingItemId = ISNULL([BillingInvoicingItemId],0),
					@SubReferenceId = [SubReferenceId],
					@ShippingId = ISNULL([ShippingId],0)
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
						   ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartCost],[WorkFlowWorkOrderId],[ShippingId],[ShipDate],[DepositAmount])
					SELECT  @BillingInvoicingIdNew,[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[ItemMasterId],[StocklineId],
							[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
							[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],
							[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],
							[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],[GrandTotal],[PDFPath],[VersionNo],[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],
							@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,0,[PartCost],@WorkFlowWorkOrderId,[ShippingId],@ShipDate,0
					  FROM #tmprAddBillingInvoicingDetailsTemp WHERE [PKID] = @MinId
			END
			ELSE
			BEGIN				
				DECLARE @VersionNums INT= 0;
				SELECT @VersionNo = [VersionNo] FROM [dbo].[BillingInvoicingItems] WITH(NOLOCK) WHERE [BillingInvoicingItemId] = @BillingInvoicingItemId AND [BillingInvoicingId] = @BillingInvoicingId; 
				
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
				
			    UPDATE [dbo].[BillingInvoicing] SET [IsVersionIncrease] = 1, [InvoiceStatusId] = @BilledInvoiceStatusId, [InvoiceStatus] = @BilledInvoiceStatus WHERE [BillingInvoicingId] = @BillingInvoicingId; 

				IF(@ModuleId = @SOModuleId)
				BEGIN
					UPDATE [dbo].[BillingInvoicingItems] SET [IsVersionIncrease] = 1, [PDFPath] = NULL  WHERE [SubReferenceId] = @SubReferenceId AND [BillingInvoicingId] = @BillingInvoicingId AND BillingInvoicingItemId = @BillingInvoicingItemId; 
				END
				ELSE IF(@ModuleId = @WOModuleId)
				BEGIN
					UPDATE [dbo].[BillingInvoicingItems] SET [IsVersionIncrease] = 1, [PDFPath] = NULL  WHERE [SubReferenceId] = @SubReferenceId AND [BillingInvoicingId] = @BillingInvoicingId; 
				END

				INSERT INTO [dbo].[BillingInvoicingItems]([BillingInvoicingId],[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[ItemMasterId],[StocklineId]
						   ,[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus]
						   ,[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus]
						   ,[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus]
						   ,[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus]
						   ,[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent]
						   ,[SalesTax],[OtherTaxPercent],[OtherTax],[GrandTotal],[RemainingAmount],[PDFPath],[VersionNo],[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId]
						   ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[PartCost],[WorkFlowWorkOrderId],[ShippingId],[ShipDate],[DepositAmount])
					SELECT  @BillingInvoicingIdNew,[ModuleId],[ReferenceId],[SubModuleId],[SubReferenceId],[ItemMasterId],[StocklineId],
							[ConditionId],[CostPlusType],[UnitPrice],[QtyBilled],[IsTotalCheck],[TotalBillingCost],[TotalBillingCostPercent],[TotalBillingCostPlus],
							[IsMaterialCheck],[MaterialCost],[MaterialCostPercent],[MaterialCostPlus],
							[IsLaborCheck],[LaborCost],[LaborCostPercent],[LaborCostPlus],	
							[IsFreightCheck],[Freight],[FreightCostPercent],[FreightCostPlus],
							[IsMiscChargesCheck],[MiscCharges],[MiscChargesCostPercent],[MiscChargesCostPlus],[SubTotal],[SalesTaxPercent],
							[SalesTax],	[OtherTaxPercent],[OtherTax],[GrandTotal],[GrandTotal],[PDFPath],@VersionNo,[IsVersionIncrease],[IsPerformaInvoice],[MasterCompanyId],
							@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,0,[PartCost],@WorkFlowWorkOrderId,[ShippingId],@ShipDate,0
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
			IF(@ModuleId = @SOModuleId AND @IsPerformaInvoice = 1)
			BEGIN
				DECLARE @SOBilledStatusId int = (select TOP 1 SOPartStatusId from SOPartStatus WHERE Description = 'Billed')
				EXEC [dbo].[SP_SaveSOPartStatusByPartId] @SalesOrderPartId  = @SubReferenceId, @StatusId = @SOBilledStatusId
			END

			SET @MinId = @MinId + 1;
		END  /****** END : MAIN WHILE LOOP *******/
		
		EXEC [dbo].[USP_UpdateDepositAmount] @BillingInvoicingIdNew
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