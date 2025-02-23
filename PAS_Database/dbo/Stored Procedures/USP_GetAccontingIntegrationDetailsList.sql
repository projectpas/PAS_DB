/*************************************************************           
 ** File:   [USP_GetAccontingIntegrationDetailsList]           
 ** Author:    HEMANT SALIYA
 ** Description:  
 ** Purpose:         
 ** Date:   07-AUG-2024        
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------  
	1    08/06/2020   HEMANT SALIYA	     CREATED
	2    29/10/2024   Devendra Shekh	 Modified(added RedirectUrl,IntigrationStatus to select)
	3    11/11/2024   Devendra Shekh	 Modified(resolved column filter issue)
	4    12/11/2024   Devendra Shekh	 Modified(added LastSycDate to select)
	5    17/12/2024   Devendra Shekh	 Modified(added Changes for Credit Terms)
	6	 03/02/2025	  Devendra Shekh	 Modified (Using [AccountingModule] table for Accounting Modules)
	7	 17/02/2025	  Devendra Shekh	 Modified (added @IsDeleted param and using [DisplayTitle] for ModuleName)
	8	 20/02/2025	  Devendra Shekh	 Modified (reading missing Details for remaining modules)


EXEC USP_GetAccontingIntegrationDetailsList @PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@StatusID=1,@GlobalFilter=N'',@IntegrationWith=NULL,
@LastRun=NULL,@ModuleName=NULL,@MasterCompanyId=1,@LastSycDate=NULL,@IsDeleted=NULL

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetAccontingIntegrationDetailsList]
	@PageNumber int,
	@PageSize int,
	@SortColumn VARCHAR(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter VARCHAR(50) = null,
	@IntegrationWith VARCHAR(50)=null,
	@LastRun datetime=null,
	@ModuleName VARCHAR(50)=null,
	@MasterCompanyId bigint = NULL,
	@LastSycDate datetime=null,
	@IntigrationStatus VARCHAR(50)=null,
	@ProgressPercent decimal(9,2) = NULL,
	@Interval int = NULL,
	@TotalCount int = NULL,
	@PendingSyncRecords int = NULL,
	@SyncRecords int = NULL,
	@IsDeleted bit = NUll
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @RecordFrom INT;
		DECLARE @IsActive BIT=1
		DECLARE @Count INT;
		DECLARE @IntegrationId INT;

		DECLARE @CustomerModuleId INT, @VendorModuleId INT, @StocklineModuleId INT, @InvModuleId INT, @CPModuleId INT, @CreditTermId INT, @GLAccountId INT, @BillModuleId INT, @ItemModuleId INT, @CreditMemoModuleId INT, @PurchaseOrderModuleId INT;

		DECLARE @WOModuleId BIGINT, @SOModuleId BIGINT, @ExchModuleId BIGINT;

		SELECT @CustomerModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'CUSTOMER';
		SELECT @VendorModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'VENDOR';
		SELECT @StocklineModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE [AccountingModuleName] = 'STOCKLINE';
		SELECT @InvModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'INVOICE';
		SELECT @CPModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'CUSTOMERPAYMENT';
		SELECT @CreditTermId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'CREDITTERM';
		SELECT @GLAccountId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'GLACCOUNT';
		SELECT @BillModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'BILL';
		SELECT @ItemModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'ITEMMASTER';
		SELECT @CreditMemoModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'CREDITMEMO';
		SELECT @PurchaseOrderModuleId = [AccountingModuleId] FROM dbo.[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'PURCHASEORDER';

		SELECT @WOModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'WORKORDER';
		SELECT @SOModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'SALESORDER';
		SELECT @ExchModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'EXCHANGESALESORDER';

		SET @RecordFrom = (@PageNumber-1) * @PageSize;
			
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		Else
		BEGIN 
			SET @SortColumn=UPPER(@SortColumn)
		END

		IF OBJECT_ID('tempdb..#InvoiceRecords') IS NOT NULL
			DROP TABLE #InvoiceRecords

		IF OBJECT_ID('tempdb..#CustomerPaymentRecords') IS NOT NULL
			DROP TABLE #CustomerPaymentRecords
		
		IF OBJECT_ID('tempdb..#PurchaseOrderRecords') IS NOT NULL
			DROP TABLE #PurchaseOrderRecords
	
		IF OBJECT_ID('tempdb..#ItemRecords') IS NOT NULL
			DROP TABLE #ItemRecords

		CREATE TABLE #InvoiceRecords
		(
			[InvoiceRecordID] BIGINT NOT NULL IDENTITY,
			[InvoiceModuleId] [INT] NULL,
			[MasterCompanyId] [INT] NULL,
			[BillingInvoicingId] [BIGINT] NULL,
			[QuickBooksReferenceId] [VARCHAR](200) NULL,
			[IsUpdated] [bit] NULL,
			[LastSyncDate] [DateTime2] NULL,
		)

		CREATE TABLE #CustomerPaymentRecords
		(
			[PaymentRecordID] BIGINT NOT NULL IDENTITY,
			[MasterCompanyId] [INT] NULL,
			[CustomerPaymentDetailsId] [BIGINT] NULL,
			[QuickBooksReferenceId] [VARCHAR](200) NULL,
			[IsUpdated] [bit] NULL,
			[LastSyncDate] [DateTime2] NULL,
		)

		CREATE TABLE #PurchaseOrderRecords
		(
			[RecordID] BIGINT NOT NULL IDENTITY,
			[ModuleId] [INT] NULL,
			[MasterCompanyId] [INT] NULL,
			[ReferenceId] [BIGINT] NULL,
			[QuickBooksReferenceId] [VARCHAR](200) NULL,
			[IsUpdated] [bit] NULL,
			[LastSyncDate] [DateTime2] NULL,
		)

		CREATE TABLE #ItemRecords
		(
			[RecordID] BIGINT NOT NULL IDENTITY,
			[ModuleId] [INT] NULL,
			[MasterCompanyId] [INT] NULL,
			[ReferenceId] [BIGINT] NULL,
			[QuickBooksReferenceId] [VARCHAR](200) NULL,
			[IsUpdated] [bit] NULL,
			[LastSyncDate] [DateTime2] NULL,
		)

		--Inserting Invoice Records	: Start
		INSERT INTO #InvoiceRecords	([InvoiceModuleId], [MasterCompanyId], [BillingInvoicingId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate])
		SELECT @WOModuleId, [MasterCompanyId], [BillingInvoicingId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate] FROM [dbo].[WorkOrderBillingInvoicing] WHERE [IsVersionIncrease] = 0 AND [MasterCompanyId] = @MasterCompanyId AND ISNULL(IsPerformaInvoice, 0) = 0 AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

		INSERT INTO #InvoiceRecords	([InvoiceModuleId], [MasterCompanyId], [BillingInvoicingId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate])
		SELECT @SOModuleId, [MasterCompanyId], [SOBillingInvoicingId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate] FROM [dbo].[SalesOrderBillingInvoicing] WHERE [IsVersionIncrease] = 0 AND [MasterCompanyId] = @MasterCompanyId AND ISNULL(IsProforma, 0) = 0 AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

		INSERT INTO #InvoiceRecords	([InvoiceModuleId], [MasterCompanyId], [BillingInvoicingId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate])
		SELECT @ExchModuleId, [MasterCompanyId], [SOBillingInvoicingId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate] FROM [dbo].[ExchangeSalesOrderBillingInvoicing] WHERE [MasterCompanyId] = @MasterCompanyId AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;
		--Inserting Invoice Records	: End

		--Inserting Customer Cash Receipt Records (Cash Receipt) : Start
		INSERT INTO #CustomerPaymentRecords	([MasterCompanyId], [CustomerPaymentDetailsId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate])
		SELECT CP.[MasterCompanyId], CPD.[CustomerPaymentDetailsId], CPD.[QuickBooksReferenceId], CPD.[IsUpdated], CPD.[LastSyncDate] FROM [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK)
		INNER JOIN [dbo].[CustomerPayments] CP WITH(NOLOCK) ON CP.ReceiptId = CPD.ReceiptId
		WHERE CP.MasterCompanyId = @MasterCompanyId AND ISNULL(CP.IsActive, 0) = 1 AND ISNULL(CP.IsDeleted, 0) = 0 AND ISNULL(CPD.IsActive, 0) = 1 AND ISNULL(CPD.IsDeleted, 0) = 0
		--Inserting Customer Cash Receipt Records (Cash Receipt) : End

		--Inserting Purchase/Repair Order Records	: Start
		INSERT INTO #PurchaseOrderRecords	([ModuleId], [MasterCompanyId], [ReferenceId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate])
		SELECT @WOModuleId, [MasterCompanyId], [PurchaseOrderId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate] FROM [dbo].[PurchaseOrder]
		WHERE [MasterCompanyId] = @MasterCompanyId AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

		INSERT INTO #PurchaseOrderRecords	([ModuleId], [MasterCompanyId], [ReferenceId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate])
		SELECT @ExchModuleId, [MasterCompanyId], [RepairOrderId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate] FROM [dbo].[RepairOrder]
		WHERE [MasterCompanyId] = @MasterCompanyId AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;
		--Inserting Purchase/Repair Order Records	: End

		--Inserting ItemMaster Records	: Start
		INSERT INTO #ItemRecords	([ModuleId], [MasterCompanyId], [ReferenceId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate])
		SELECT @WOModuleId, [MasterCompanyId], [ItemMasterId], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate] FROM [dbo].[ItemMaster]
		WHERE [MasterCompanyId] = @MasterCompanyId AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;
		--Inserting ItemMaster Records	: End

		IF OBJECT_ID('tempdb..#InsertedSyncRecords') IS NOT NULL
			DROP TABLE #InsertedSyncRecords

		CREATE TABLE #InsertedSyncRecords
		(
			ID BIGINT NOT NULL IDENTITY,
			[IntegrationId] [INT] NULL,
			[CustQuickBookCount] [BIGINT] NULL,
			[CustLastSycDate] [DateTime2] null,
			[STQuickBookCount] [BIGINT] NULL,
			[STLastSycDate] [DateTime2] null,
			[VQuickBookCount] [BIGINT] NULL,
			[VLastSycDate] [DateTime2] null,
			[MasterCompanyId] [INT] NULL,
			[CreditTermsQuickBookCount] [BIGINT] NULL,
			[CreditTermsLastSycDate] [DateTime2] NULL,
			[GLAccountQuickBookCount] [BIGINT] NULL,
			[GLAccountLastSycDate] [DateTime2] NULL,
			[InvoiceQuickBookCount] [BIGINT] NULL,
			[InvoiceLastSycDate] [DateTime2] NULL,
			[CustomerPaymentQuickBookCount] [BIGINT] NULL,
			[CustomerPaymentLastSycDate] [DateTime2] NULL,
			[ItemMasterQuickBookCount] [BIGINT] NULL,
			[ItemMasterLastSycDate] [DateTime2] NULL,
			[CreditMemoQuickBookCount] [BIGINT] NULL,
			[CreditMemoLastSycDate] [DateTime2] NULL,
			[PurchaseOrderQuickBookCount] [BIGINT] NULL,
			[PurchaseOrderLastSycDate] [DateTime2] NULL,
		)

		INSERT #InsertedSyncRecords([CustQuickBookCount],[CustLastSycDate],[STQuickBookCount],[STLastSycDate],[VQuickBookCount],[VLastSycDate],[CreditTermsQuickBookCount],[CreditTermsLastSycDate],
		[GLAccountQuickBookCount], [GLAccountLastSycDate], [InvoiceQuickBookCount], [InvoiceLastSycDate], [CustomerPaymentQuickBookCount], [CustomerPaymentLastSycDate], [ItemMasterQuickBookCount], [ItemMasterLastSycDate],
		[CreditMemoQuickBookCount], [CreditMemoLastSycDate], [PurchaseOrderQuickBookCount], [PurchaseOrderLastSycDate], [MasterCompanyId],[IntegrationId])
		SELECT  COUNT(C.QuickBooksReferenceId),MAX(C.LastSyncDate),
				COUNT(ST.QuickBooksReferenceId),MAX(ST.LastSyncDate),
				COUNT(V.QuickBooksReferenceId),MAX(V.LastSyncDate),
				COUNT(CT.QuickBooksReferenceId),MAX(CT.LastSyncDate),
				COUNT(GL.QuickBooksReferenceId),MAX(GL.LastSyncDate),
				COUNT(INV.QuickBooksReferenceId),MAX(INV.LastSyncDate),
				COUNT(CP.QuickBooksReferenceId),MAX(CP.LastSyncDate),
				COUNT(IM.QuickBooksReferenceId),MAX(IM.LastSyncDate),
				COUNT(CM.QuickBooksReferenceId),MAX(CM.LastSyncDate),
				COUNT(PO.QuickBooksReferenceId),MAX(PO.LastSyncDate),
				ACI.[MasterCompanyId], ACI.IntegrationId 
		FROM  dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
			LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId AND ISNULL(C.IsActive, 0) = 1 AND ISNULL(C.IsDeleted, 0) = 0
			LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId AND ISNULL(V.IsActive, 0) = 1 AND ISNULL(V.IsDeleted, 0) = 0
			LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId AND ISNULL(ST.IsActive, 0) = 1 AND ISNULL(ST.IsDeleted, 0) = 0
			LEFT JOIN  #InvoiceRecords INV  WITH (NOLOCK) ON INV.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
			LEFT JOIN  #CustomerPaymentRecords CP  WITH (NOLOCK) ON CP.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CPModuleId
			LEFT JOIN  dbo.CreditTerms CT  WITH (NOLOCK) ON CT.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditTermId AND ISNULL(CT.IsActive, 0) = 1 AND ISNULL(CT.IsDeleted, 0) = 0
			LEFT JOIN  dbo.GLAccount GL  WITH (NOLOCK) ON GL.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @GLAccountId AND ISNULL(GL.IsActive, 0) = 1 AND ISNULL(GL.IsDeleted, 0) = 0
			LEFT JOIN  #ItemRecords IM  WITH (NOLOCK) ON IM.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @ItemModuleId
			LEFT JOIN  dbo.CreditMemo CM  WITH (NOLOCK) ON CM.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditMemoModuleId AND ISNULL(CM.IsActive, 0) = 1 AND ISNULL(CM.IsDeleted, 0) = 0
			LEFT JOIN  #PurchaseOrderRecords PO  WITH (NOLOCK) ON PO.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId
		WHERE	(ISNULL(C.QuickBooksReferenceId,0) > 0 OR ISNULL(V.QuickBooksReferenceId,0) > 0 OR ISNULL(ST.QuickBooksReferenceId,0) > 0 OR ISNULL(INV.QuickBooksReferenceId,0) > 0 OR ISNULL(CP.QuickBooksReferenceId,0) > 0 OR
				ISNULL(CT.QuickBooksReferenceId,0) > 0 OR ISNULL(GL.QuickBooksReferenceId,0) > 0 OR ISNULL(IM.QuickBooksReferenceId,0) > 0 OR ISNULL(CM.QuickBooksReferenceId,0) > 0 OR ISNULL(PO.QuickBooksReferenceId,0) > 0)
		GROUP BY ACI.[MasterCompanyId], ACI.IntegrationId

		--SELECT * FROM #InsertedSyncRecords
	
		IF OBJECT_ID('tempdb..#InsertedPendingSyncRecords') IS NOT NULL
		DROP TABLE #InsertedPendingSyncRecords

		CREATE TABLE #InsertedPendingSyncRecords
		(
			ID BIGINT NOT NULL IDENTITY,
			[IntegrationId] [INT] NULL,
			[CustPendingSyncRecords] [BIGINT] NULL,
			[STPendingSyncRecords] [BIGINT] NULL,
			[VPendingSyncRecords] [BIGINT] NULL,
			[CreditTermsPendingSyncRecords] [BIGINT] NULL,
			[GLAccountPendingSyncRecords] [BIGINT] NULL,
			[InvoicePendingSyncRecords] [BIGINT] NULL,
			[CustomerPaymentPendingSyncRecords] [BIGINT] NULL,
			[ItemMasterPendingSyncRecords] [BIGINT] NULL,
			[CreditMemoPendingSyncRecords] [BIGINT] NULL,
			[PurchaseOrderPendingSyncRecords] [BIGINT] NULL,
			[MasterCompanyId] [INT] NULL
		)

		INSERT #InsertedPendingSyncRecords([IntegrationId],[CustPendingSyncRecords],[STPendingSyncRecords],[VPendingSyncRecords],[CreditTermsPendingSyncRecords],[GLAccountPendingSyncRecords],[InvoicePendingSyncRecords],
		[CustomerPaymentPendingSyncRecords], [ItemMasterPendingSyncRecords], [CreditMemoPendingSyncRecords], [PurchaseOrderPendingSyncRecords], [MasterCompanyId])
		SELECT ACI.IntegrationId, COUNT(C.IsUpdated),COUNT(ST.IsUpdated),COUNT(V.IsUpdated),COUNT(CT.IsUpdated),COUNT(GL.IsUpdated),COUNT(INV.IsUpdated),COUNT(CP.IsUpdated),COUNT(IM.IsUpdated),COUNT(CM.IsUpdated),COUNT(PO.IsUpdated), ACI.[MasterCompanyId]
		FROM  dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
			LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId AND ISNULL(C.IsActive, 0) = 1 AND ISNULL(C.IsDeleted, 0) = 0
			LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId AND ISNULL(V.IsActive, 0) = 1 AND ISNULL(V.IsDeleted, 0) = 0
			LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId AND ISNULL(ST.IsActive, 0) = 1 AND ISNULL(ST.IsDeleted, 0) = 0
			LEFT JOIN  #InvoiceRecords INV  WITH (NOLOCK) ON INV.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
			LEFT JOIN  #CustomerPaymentRecords CP  WITH (NOLOCK) ON CP.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CPModuleId
			LEFT JOIN  dbo.CreditTerms CT  WITH (NOLOCK) ON CT.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditTermId AND ISNULL(CT.IsActive, 0) = 1 AND ISNULL(CT.IsDeleted, 0) = 0
			LEFT JOIN  dbo.GLAccount GL  WITH (NOLOCK) ON GL.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @GLAccountId AND ISNULL(GL.IsActive, 0) = 1 AND ISNULL(GL.IsDeleted, 0) = 0
			LEFT JOIN  #ItemRecords IM  WITH (NOLOCK) ON IM.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @ItemModuleId
			LEFT JOIN  dbo.CreditMemo CM  WITH (NOLOCK) ON CM.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditMemoModuleId AND ISNULL(CM.IsActive, 0) = 1 AND ISNULL(CM.IsDeleted, 0) = 0
			LEFT JOIN  #PurchaseOrderRecords PO  WITH (NOLOCK) ON PO.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId
		WHERE	(ISNULL(C.IsUpdated,0) = 1 OR ISNULL(V.IsUpdated,0) = 1 OR ISNULL(ST.IsUpdated,0) = 1 OR ISNULL(INV.IsUpdated,0) = 1 OR ISNULL(CP.IsUpdated,0) = 1 OR
				ISNULL(CT.IsUpdated,0) = 1 OR ISNULL(GL.IsUpdated,0) = 1 OR ISNULL(IM.IsUpdated,0) = 1 OR ISNULL(CM.IsUpdated,0) = 1 OR ISNULL(PO.IsUpdated,0) = 1)
		GROUP BY ACI.[MasterCompanyId] , ACI.IntegrationId

		--SELECT * FROM #InsertedPendingSyncRecords

		IF OBJECT_ID('tempdb..#InsertedTotalRecords') IS NOT NULL
		DROP TABLE #InsertedTotalRecords

		CREATE TABLE #InsertedTotalRecords
		(
			ID BIGINT NOT NULL IDENTITY,
			[IntegrationId] [INT] NULL,
			[CustTotalRecords] [BIGINT] NULL,
			[STTotalRecords] [BIGINT] NULL,
			[VTotalRecords] [BIGINT] NULL,
			[CreditTermsTotalRecords] [BIGINT] NULL,
			[GLAccountTotalRecords] [BIGINT] NULL,
			[InvoiceTotalRecords] [BIGINT] NULL,
			[CustomerPaymentTotalRecords] [BIGINT] NULL,
			[ItemMasterTotalRecords] [BIGINT] NULL,
			[CreditMemoTotalRecords] [BIGINT] NULL,
			[PurchaseOrderTotalRecords] [BIGINT] NULL,
			[MasterCompanyId] [int] NULL
		)

		INSERT #InsertedTotalRecords([IntegrationId],[CustTotalRecords],[STTotalRecords],[VTotalRecords],[CreditTermsTotalRecords],[GLAccountTotalRecords],[InvoiceTotalRecords],[CustomerPaymentTotalRecords],[ItemMasterTotalRecords],[CreditMemoTotalRecords],[PurchaseOrderTotalRecords], [MasterCompanyId])
		SELECT [IntegrationId], COUNT(C.CustomerId),COUNT(ST.StocklineId),COUNT(V.VendorId),COUNT(CT.CreditTermsId),COUNT(GL.GLAccountId),COUNT(INV.BillingInvoicingId), COUNT(CP.CustomerPaymentDetailsId), COUNT(IM.ReferenceId), COUNT(CM.CreditMemoHeaderId), COUNT(PO.ReferenceId),  ACI.[MasterCompanyId] 
		FROM dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
			LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId AND ISNULL(C.IsActive, 0) = 1 AND ISNULL(C.IsDeleted, 0) = 0
			LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId AND ISNULL(V.IsActive, 0) = 1 AND ISNULL(V.IsDeleted, 0) = 0
			LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId AND ISNULL(ST.IsActive, 0) = 1 AND ISNULL(ST.IsDeleted, 0) = 0
			LEFT JOIN  #InvoiceRecords INV  WITH (NOLOCK) ON INV.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @InvModuleId
			LEFT JOIN  #CustomerPaymentRecords CP  WITH (NOLOCK) ON CP.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CPModuleId
			LEFT JOIN  dbo.CreditTerms CT  WITH (NOLOCK) ON CT.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditTermId AND ISNULL(CT.IsActive, 0) = 1 AND ISNULL(CT.IsDeleted, 0) = 0
			LEFT JOIN  dbo.GLAccount GL  WITH (NOLOCK) ON GL.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @GLAccountId AND ISNULL(GL.IsActive, 0) = 1 AND ISNULL(GL.IsDeleted, 0) = 0
			LEFT JOIN  #ItemRecords IM  WITH (NOLOCK) ON IM.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @ItemModuleId
			LEFT JOIN  dbo.CreditMemo CM  WITH (NOLOCK) ON CM.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CreditMemoModuleId AND ISNULL(CM.IsActive, 0) = 1 AND ISNULL(CM.IsDeleted, 0) = 0
			LEFT JOIN  #PurchaseOrderRecords PO  WITH (NOLOCK) ON PO.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @PurchaseOrderModuleId
		GROUP BY ACI.[MasterCompanyId], ACI.IntegrationId

		--SELECT * FROM #InsertedTotalRecords
		
		;WITH Result AS(
		SELECT	
				ACI.AccountingIntegrationSettingsId, 
				ACI.IntegrationId,
				ACI.IntegrationWith,
				ACI.LastRun,
				ACI.Interval,
				ACI.ModuleId,
				ACI.[DisplayTitle] AS ModuleName,
				ACI.MasterCompanyId,			
				CASE  
					WHEN ACI.ModuleId = @CustomerModuleId THEN ISNULL(SR.CustQuickBookCount, 0)
					WHEN ACI.ModuleId = @StocklineModuleId THEN ISNULL(SR.STQuickBookCount, 0)
					WHEN ACI.ModuleId = @VendorModuleId THEN ISNULL(SR.VQuickBookCount, 0)
					WHEN ACI.ModuleId = @CreditTermId THEN ISNULL(SR.CreditTermsQuickBookCount, 0)
					WHEN ACI.ModuleId = @GLAccountId THEN ISNULL(SR.GLAccountQuickBookCount, 0)
					WHEN ACI.ModuleId = @InvModuleId THEN ISNULL(SR.InvoiceQuickBookCount, 0)
					WHEN ACI.ModuleId = @CPModuleId THEN ISNULL(SR.CustomerPaymentQuickBookCount, 0)
					WHEN ACI.ModuleId = @ItemModuleId THEN ISNULL(SR.ItemMasterQuickBookCount, 0)
					WHEN ACI.ModuleId = @CreditMemoModuleId THEN ISNULL(SR.CreditMemoQuickBookCount, 0)
					WHEN ACI.ModuleId = @PurchaseOrderModuleId THEN ISNULL(SR.PurchaseOrderQuickBookCount, 0)
				else  0
				END  AS SyncRecords,
				CASE  
					WHEN ACI.ModuleId = @CustomerModuleId  THEN ISNULL(PSR.CustPendingSyncRecords, 0)
					WHEN ACI.ModuleId = @StocklineModuleId THEN ISNULL(PSR.STPendingSyncRecords, 0)
					WHEN ACI.ModuleId = @VendorModuleId THEN ISNULL(PSR.VPendingSyncRecords, 0)
					WHEN ACI.ModuleId = @CreditTermId THEN ISNULL(PSR.CreditTermsPendingSyncRecords, 0)
					WHEN ACI.ModuleId = @GLAccountId THEN ISNULL(PSR.GLAccountPendingSyncRecords, 0)
					WHEN ACI.ModuleId = @InvModuleId THEN ISNULL(PSR.InvoicePendingSyncRecords, 0)
					WHEN ACI.ModuleId = @CPModuleId THEN ISNULL(PSR.CustomerPaymentPendingSyncRecords, 0)
					WHEN ACI.ModuleId = @ItemModuleId THEN ISNULL(PSR.ItemMasterPendingSyncRecords, 0)
					WHEN ACI.ModuleId = @CreditMemoModuleId THEN ISNULL(PSR.CreditMemoPendingSyncRecords, 0)
					WHEN ACI.ModuleId = @PurchaseOrderModuleId THEN ISNULL(PSR.PurchaseOrderPendingSyncRecords, 0)
				else  0
				END  AS PendingSyncRecords,
				CASE  
					WHEN ACI.ModuleId = @CustomerModuleId  THEN ISNULL(TR.CustTotalRecords, 0)
					WHEN ACI.ModuleId = @StocklineModuleId THEN ISNULL(TR.STTotalRecords, 0)
					WHEN ACI.ModuleId = @VendorModuleId THEN ISNULL(TR.VTotalRecords, 0)
					WHEN ACI.ModuleId = @CreditTermId THEN ISNULL(TR.CreditTermsTotalRecords, 0)
					WHEN ACI.ModuleId = @GLAccountId THEN ISNULL(TR.GLAccountTotalRecords, 0)
					WHEN ACI.ModuleId = @InvModuleId THEN ISNULL(TR.InvoiceTotalRecords, 0)
					WHEN ACI.ModuleId = @CPModuleId THEN ISNULL(TR.CustomerPaymentTotalRecords, 0)
					WHEN ACI.ModuleId = @ItemModuleId THEN ISNULL(TR.ItemMasterTotalRecords, 0)
					WHEN ACI.ModuleId = @CreditMemoModuleId THEN ISNULL(TR.CreditMemoTotalRecords, 0)
					WHEN ACI.ModuleId = @PurchaseOrderModuleId THEN ISNULL(TR.PurchaseOrderTotalRecords, 0)
				else  0
				END  AS TotalCount,
				ISNULL(SR.CustQuickBookCount, 0) AS CustQuickBookCount,
				ACI.CreatedDate,
				ACI.CreatedBy,
				ACI.UpdatedDate,
				ACI.UpdatedBy,
				ACI.IsActive,
				ACI.IsDeleted,
				ACS.RedirectUrl,
				'Connect' AS [IntigrationStatus],
				ACI.LastRun AS LastSycDate,
				ISNULL(ACI.AllowBulkSync, 0) AS AllowBulkSync
		FROM dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
				LEFT JOIN #InsertedSyncRecords SR WITH (NOLOCK) ON SR.MasterCompanyId = ACI.MasterCompanyId 
				LEFT JOIN #InsertedPendingSyncRecords PSR WITH (NOLOCK) ON PSR.MasterCompanyId = ACI.MasterCompanyId
				LEFT JOIN #InsertedTotalRecords TR WITH (NOLOCK) ON TR.MasterCompanyId = ACI.MasterCompanyId
				LEFT JOIN dbo.AccountingIntegrationSetup ACS WITH (NOLOCK) ON ACS.MasterCompanyId = ACI.MasterCompanyId AND ACS.IntegrationId = ACI.IntegrationId
		WHERE	ACI.MasterCompanyId = @MasterCompanyId --AND ( AND (@IsActive IS NULL OR ACI.IsActive = @IsActive))
				AND (@IsDeleted IS NULL OR @IsDeleted = ACI.IsDeleted)
		), ResultCount AS(SELECT COUNT(AccountingIntegrationSettingsId) AS totalItems FROM Result)
		SELECT * INTO #TempResult FROM  Result
		WHERE ((@GlobalFilter <>'' AND ((IntegrationWith LIKE '%' +@GlobalFilter+'%') OR
			    (LastRun LIKE '%' +@GlobalFilter+'%') OR	
				(Interval LIKE '%' +@GlobalFilter+'%') OR
				(ModuleName LIKE '%' +@GlobalFilter+'%') OR
				(SyncRecords LIKE '%' +@GlobalFilter+'%') OR
				(PendingSyncRecords LIKE '%' +@GlobalFilter+'%') OR
				(TotalCount LIKE '%' +@GlobalFilter+'%') OR
				(IntigrationStatus LIKE '%' +@GlobalFilter+'%'))) OR   
				(@GlobalFilter='' AND (ISNULL(@IntegrationWith,'') ='' OR IntegrationWith LIKE '%' + @IntegrationWith+'%') AND
				(ISNULL(@LastRun,'') ='' OR CAST(LastRun as Date)=CAST(@LastRun as date))AND
				(ISNULL(@ModuleName,'') ='' OR ModuleName LIKE '%' + @ModuleName + '%') AND	
				(ISNULL(@IntigrationStatus,'') ='' OR IntigrationStatus LIKE '%' + @IntigrationStatus + '%') AND
				(ISNULL(@SyncRecords,'') ='' OR CAST(SyncRecords AS VARCHAR) LIKE '%' + CAST(@SyncRecords AS VARCHAR) + '%') AND	
				(ISNULL(@PendingSyncRecords,'') ='' OR CAST(PendingSyncRecords AS VARCHAR) LIKE '%' + CAST(@PendingSyncRecords AS VARCHAR) + '%') AND	
				(ISNULL(@TotalCount,'') ='' OR CAST(TotalCount AS VARCHAR) LIKE '%' + CAST(@TotalCount AS VARCHAR) + '%') AND
				(ISNULL(@LastSycDate,'') ='' OR CAST(LastSycDate as Date)=CAST(@LastSycDate as date))AND
				(ISNULL(@Interval,'') ='' OR CAST(Interval as VARCHAR)=CAST(@Interval as VARCHAR))))

		Select @Count = COUNT(AccountingIntegrationSettingsId) FROM #TempResult			

		SELECT	* ,CASE WHEN ISNULL(TotalCount, 0) > 0 THEN (CAST(100.00 AS decimal(18,2)) - ((100 * CAST(ISNULL(PendingSyncRecords, 0) AS DECIMAL(18,2)))/CAST(ISNULL(TotalCount, 0) AS decimal(18,2)))) ELSE 0 END AS ProgressPercent
		INTO #FinalResult FROM #TempResult

		SELECT *,
		@Count AS NumberOfItems FROM #FinalResult
		ORDER BY  
		CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN IntegrationWith END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='LASTRUN')  THEN LastRun END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='MODULENAME')  THEN ModuleName END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN SyncRecords END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN PendingSyncRecords END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN TotalCount END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='INTIGRATIONSTATUS')  THEN IntigrationStatus END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='INTERVAL')  THEN Interval END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='PROGRESSPERCENT')  THEN ProgressPercent END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='LASTSYCDATE')  THEN LastSycDate END ASC,

        CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN IntegrationWith END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='LASTRUN')  THEN LastRun END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='MODULENAME')  THEN ModuleName END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN SyncRecords END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN PendingSyncRecords END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN TotalCount END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='INTIGRATIONSTATUS')  THEN IntigrationStatus END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='INTERVAL')  THEN Interval END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='PROGRESSPERCENT')  THEN ProgressPercent END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='LASTSYCDATE')  THEN LastSycDate END DESC
		OFFSET @RecordFrom ROWS 
		FETCH NEXT @PageSize ROWS ONLY
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetAccontingIntegrationDetailsList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@StatusID, '') AS VARCHAR(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@LastRun, '') AS VARCHAR(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@ModuleName , '') AS VARCHAR(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@masterCompanyID, '') AS VARCHAR(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END