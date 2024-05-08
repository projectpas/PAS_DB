/*************************************************************           
 ** File:   [usprpt_GetARAgingAsOfNowReport_SSRS]           
 ** Author:   Moin Bloch 
 ** Description: Get Data for AR Agging Report For SSRS
 ** Purpose:         
 ** Date:   08-05-2024       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  			Change Description            
 ** --   --------		-------				--------------------------------          
	1	 08-05-2024		Moin Bloch  		Created
     
EXEC usprpt_GetARAgingAsOfNowReport_SSRS 
**************************************************************/
CREATE PROCEDURE [dbo].[usprpt_GetARAgingAsOfNowReport_SSRS]
@id VARCHAR(MAX) = NULL,
@id2 VARCHAR(MAX) = NULL,
@id3 VARCHAR(MAX) = NULL,
@id4 VARCHAR(MAX) = NULL,
@strFilter VARCHAR(MAX) = NULL,
@mastercompanyid INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF OBJECT_ID(N'tempdb..#TempARAgingAsOfNowDataFilter') IS NOT NULL    
	BEGIN    
		DROP TABLE #TempARAgingAsOfNowDataFilter
	END

	CREATE TABLE #TempARAgingAsOfNowDataFilter([ID] BIGINT  IDENTITY(1,1),[Field] VARCHAR(MAX));

	INSERT INTO #TempARAgingAsOfNowDataFilter(Field) SELECT Item FROM DBO.SPLITSTRING(@id2,'!');

    DECLARE @RecordFrom INT;
	DECLARE @Count INT;
	DECLARE @CMPostedStatusId INT;
	DECLARE @ClosedCreditMemoStatus INT;
	DECLARE @WOInvoiceTypeId INT;
	DECLARE @SOInvoiceTypeId INT;
	DECLARE @EXInvoiceTypeId INT;
    DECLARE @InvoiceStatus VARCHAR(20)='Invoiced'
	DECLARE @SO INT = 1;
	DECLARE @WO INT = 2;
	DECLARE @Exch INT = 6;
	DECLARE @CustomerPaymentsPostedStatus INT= 2;
	DECLARE @MJEPostStatusId INT;
	DECLARE @MSModuleId INT;	

	DECLARE @WOModuleTypeId INT = 1
	DECLARE @SOModuleTypeId INT = 2
	DECLARE @EXSOModuleTypeId INT = 3
	DECLARE @CMModuleTypeId INT = 4	
	DECLARE @STLCMModuleTypeId INT = 5
	DECLARE @MJEModuleTypeId INT = 6
	
	DECLARE @PageNumber INT = NULL,
    @PageSize INT = NULL,
    @SortColumn VARCHAR(50)=NULL,
    @SortOrder INT = NULL,
    @GlobalFilter varchar(50) = NULL,
    @ViewType varchar(50) = @id,
    @AsOfDate DATETIME2 = NULL, 
    @CustomerId BIGINT = NULL,
    @IsInvoice BIT = NULL,
    @IsCredits BIT = NULL,
    @IsDeposit BIT = NULL,
    @IsUnappliedAmounts BIT = NULL,
    @CustomerName VARCHAR(50) = NULL,
    @CustomerCode VARCHAR(50) = NULL,
    @CurrencyCode VARCHAR(50) = NULL,
    @InvoiceNo VARCHAR(50) = NULL,
    @InvoiceDate DATETIME = NULL,
    @DSI INT = NULL,
    @DSO INT = NULL,
    @DSS INT = NULL,
    @DocType VARCHAR(50) = NULL,
    @CustomerRef VARCHAR(50) = NULL,
    @Salesperson VARCHAR(50) = NULL,
    @CreditTerms VARCHAR(50) = NULL,
    @DueDate DATETIME = NULL,
    @FxRateAmount  VARCHAR(50) = NULL,
    @InvoiceAmount DECIMAL(18, 2) = NULL,
    @BalanceAmount DECIMAL(18, 2) = NULL,
    @CurrentAmount DECIMAL(18, 2) = NULL,
    @PaymentAmount DECIMAL(18, 2) = NULL,
    @Amountlessthan0days DECIMAL(18,2) = NULL,
    @Amountlessthan30days DECIMAL(18,2) = NULL,
    @Amountlessthan60days DECIMAL(18,2) = NULL,
    @Amountlessthan90days DECIMAL(18,2) = NULL,
    @Amountlessthan120days DECIMAL(18,2) = NULL,
    @Amountmorethan120days DECIMAL(18,2) = NULL,
    @level1Str VARCHAR(500) = NULL,
    @level2Str VARCHAR(500) = NULL,
    @level3Str VARCHAR(500) = NULL,
    @level4Str VARCHAR(500) = NULL,
    @level5Str VARCHAR(500) = NULL,
    @level6Str VARCHAR(500) = NULL,
    @level7Str VARCHAR(500) = NULL,
    @level8Str VARCHAR(500) = NULL,
    @level9Str VARCHAR(500) = NULL,
    @level10Str VARCHAR(500) = NULL,
    @LegalEntityName VARCHAR(500) = NULL,
    @EmployeeId BIGINT = NULL
	
    SELECT @CMPostedStatusId = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'POSTED';  	  
    SELECT @ClosedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Closed';
    SELECT @WOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WHERE ModuleName='WorkOrder';
    SELECT @SOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WHERE ModuleName='SalesOrder';
    SELECT @EXInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WHERE ModuleName='Exchange';
    SELECT @MJEPostStatusId = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WHERE [Name] = 'Posted';
    SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='ManualJournalAccounting';
		
	SET @PageNumber = 1;
	SET @PageSize = 10000;
	SET @RecordFrom = (@PageNumber - 1) * @PageSize;
	   			
	IF @SortColumn IS NULL AND @ViewType = 'Details'
	BEGIN
		SET @SortColumn = UPPER('INVOICEDATE')	
		SET @SortOrder = -1;
	END 
	IF @SortColumn IS NULL AND @ViewType = 'Summary'
	BEGIN
		SET @SortColumn = UPPER('CustomerName')		
		SET @SortOrder = 1;
	END
	ELSE
	BEGIN 
		SET @SortColumn = UPPER(@SortColumn)		
	END		
	
	SELECT @AsOfDate = ISNULL(TRY_CAST([Field] AS DATETIME),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 1; 
	SELECT @CustomerId = ISNULL(TRY_CAST([Field] AS BIGINT),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 2; 
	SELECT @IsInvoice = [Field] FROM #TempARAgingAsOfNowDataFilter WHERE ID = 3; 
	SELECT @IsCredits = [Field] FROM #TempARAgingAsOfNowDataFilter WHERE ID = 4; 
	SELECT @IsDeposit = [Field] FROM #TempARAgingAsOfNowDataFilter WHERE ID = 5;		
	SELECT @IsUnappliedAmounts = [Field] FROM #TempARAgingAsOfNowDataFilter WHERE ID = 6; 
	SELECT @CustomerName = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempARAgingAsOfNowDataFilter WHERE ID = 7; 
	SELECT @CustomerCode = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempARAgingAsOfNowDataFilter WHERE ID = 8; 
	SELECT @InvoiceDate = ISNULL(TRY_CAST([Field] AS DATETIME),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 9; 
	SELECT @CustomerRef = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempARAgingAsOfNowDataFilter WHERE ID = 10; 
	SELECT @InvoiceNo = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempARAgingAsOfNowDataFilter WHERE ID = 11; 
	SELECT @DSI = ISNULL(TRY_CAST([Field] AS INT),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 12; 
	SELECT @DSO = ISNULL(TRY_CAST([Field] AS INT),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 13; 
	SELECT @DSS = ISNULL(TRY_CAST([Field] AS INT),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 14; 
	SELECT @Salesperson = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempARAgingAsOfNowDataFilter WHERE ID = 15; 
	SELECT @CreditTerms = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempARAgingAsOfNowDataFilter WHERE ID = 16; 
	SELECT @DueDate = ISNULL(TRY_CAST([Field] AS DATETIME),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 17; 
	SELECT @CurrencyCode = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempARAgingAsOfNowDataFilter WHERE ID = 18; 
	SELECT @FxRateAmount = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempARAgingAsOfNowDataFilter WHERE ID = 19; 
	SELECT @InvoiceAmount = ISNULL(TRY_CAST([Field] AS DECIMAL(18,2)),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 20; 
	SELECT @CurrentAmount = ISNULL(TRY_CAST([Field] AS DECIMAL(18,2)),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 21; 
	SELECT @Amountlessthan0days = ISNULL(TRY_CAST([Field] AS DECIMAL(18,2)),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 22; 
	SELECT @Amountlessthan30days = ISNULL(TRY_CAST([Field] AS DECIMAL(18,2)),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 23; 
	SELECT @Amountlessthan60days = ISNULL(TRY_CAST([Field] AS DECIMAL(18,2)),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 24; 
	SELECT @Amountlessthan90days = ISNULL(TRY_CAST([Field] AS DECIMAL(18,2)),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 25; 
	SELECT @Amountlessthan120days = ISNULL(TRY_CAST([Field] AS DECIMAL(18,2)),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 26; 
	SELECT @Amountmorethan120days = ISNULL(TRY_CAST([Field] AS DECIMAL(18,2)),NULL) FROM #TempARAgingAsOfNowDataFilter WHERE ID = 27; 
	SELECT @LegalEntityName = CASE WHEN [Field] = 'null' THEN NULL ELSE [Field] END FROM #TempARAgingAsOfNowDataFilter WHERE ID = 28; 
		 
    BEGIN TRY

		IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMPMSFilter
		END

		CREATE TABLE #TEMPMSFilter([ID] BIGINT  IDENTITY(1,1),[LevelIds] VARCHAR(MAX)); 

		INSERT INTO #TEMPMSFilter(LevelIds)	SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!');

		DECLARE   
		@level1 VARCHAR(MAX) = NULL,  
		@level2 VARCHAR(MAX) = NULL,  
		@level3 VARCHAR(MAX) = NULL,  
		@level4 VARCHAR(MAX) = NULL,  
		@Level5 VARCHAR(MAX) = NULL,  
		@Level6 VARCHAR(MAX) = NULL,  
		@Level7 VARCHAR(MAX) = NULL,  
		@Level8 VARCHAR(MAX) = NULL,  
		@Level9 VARCHAR(MAX) = NULL,  
		@Level10 VARCHAR(MAX) = NULL 

		SELECT @level1 = LevelIds FROM #TEMPMSFilter WHERE ID = 1 
		SELECT @level2 = LevelIds FROM #TEMPMSFilter WHERE ID = 2 
		SELECT @level3 = LevelIds FROM #TEMPMSFilter WHERE ID = 3 
		SELECT @level4 = LevelIds FROM #TEMPMSFilter WHERE ID = 4 
		SELECT @level5 = LevelIds FROM #TEMPMSFilter WHERE ID = 5 
		SELECT @level6 = LevelIds FROM #TEMPMSFilter WHERE ID = 6 
		SELECT @level7 = LevelIds FROM #TEMPMSFilter WHERE ID = 7 
		SELECT @level8 = LevelIds FROM #TEMPMSFilter WHERE ID = 8 
		SELECT @level9 = LevelIds FROM #TEMPMSFilter WHERE ID = 9 
		SELECT @level10 = LevelIds FROM #TEMPMSFilter WHERE ID = 10 

		DECLARE @SOMSModuleID BIGINT ; -- = 17 Sales Order MS Module ID 
		DECLARE @WOMSModuleID BIGINT ; -- = 12 Work Order MS Module ID  
		DECLARE @CMMSModuleID BIGINT ; -- = 61 CM MS Module ID  
		DECLARE @ESOMSModuleID BIGINT;
			  
		SELECT @WOMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='WORKORDERMPN';
		SELECT @SOMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='SALESORDER ';
		SELECT @CMMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='CREDITMEMOHEADER';
	    SELECT @ESOMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSOHeader';

		IF(@ViewType = 'Summary')  -- VIEW
		BEGIN
			IF OBJECT_ID(N'tempdb..#TEMPInvoiceRecords') IS NOT NULL    
			BEGIN    
				DROP TABLE #TEMPInvoiceRecords
			END

			CREATE TABLE #TEMPInvoiceRecords(        
				[ID] BIGINT IDENTITY(1,1),      
				[BillingInvoicingId] BIGINT NOT NULL,
				[CustomerId] BIGINT NULL,
				[CustomerName] VARCHAR(200) NULL,
				[CustomerCode] VARCHAR(50) NULL,				
				[BalanceAmount] DECIMAL(18, 2) NULL,
				[CurrentAmount] DECIMAL(18, 2) NULL,
				[PaymentAmount] DECIMAL(18, 2) NULL,
				[Amountlessthan0days] DECIMAL(18, 2) NULL,
				[Amountlessthan30days] DECIMAL(18, 2) NULL,
				[Amountlessthan60days] DECIMAL(18, 2) NULL,
				[Amountlessthan90days] DECIMAL(18, 2) NULL,
				[Amountlessthan120days] DECIMAL(18, 2) NULL,
				[Amountmorethan120days] DECIMAL(18, 2) NULL,		
				[InvoiceAmount] DECIMAL(18, 2) NULL,
				[CMAmount] DECIMAL(18, 2) NULL,
				[CreditMemoAmount] DECIMAL(18, 2) NULL,
				[CreditMemoUsed] DECIMAL(18, 2) NULL,		
				[Level1Id] BIGINT NULL,
				[Level2Id] BIGINT NULL,
				[Level3Id] BIGINT NULL,
				[Level4Id] BIGINT NULL,
				[Level5Id] BIGINT NULL,
				[Level6Id] BIGINT NULL,
				[Level7Id] BIGINT NULL,
				[Level8Id] BIGINT NULL,
				[Level9Id] BIGINT NULL,
				[Level10Id] BIGINT NULL,
				[level1] VARCHAR(500) NULL,
				[level2] VARCHAR(500) NULL,
				[level3] VARCHAR(500) NULL,
				[level4] VARCHAR(500) NULL,
				[level5] VARCHAR(500) NULL,
				[level6] VARCHAR(500) NULL,
				[level7] VARCHAR(500) NULL,
				[level8] VARCHAR(500) NULL,
				[level9] VARCHAR(500) NULL,
				[level10] VARCHAR(500) NULL,
				[MasterCompanyId] INT NULL,
				[StatusId] BIGINT NULL,
				[IsCreditMemo] BIT NULL,
				[InvoicePaidAmount] DECIMAL(18, 2) NULL,
				[ModuleTypeId] INT NULL,
				[LegalEntityName] VARCHAR(MAX) NULL		
			) 
		
			-- WO INVOICE DETAILS
			
			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],
				   [Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
				   [level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName])
			SELECT DISTINCT WOBI.[BillingInvoicingId],			               
							C.[CustomerId],
							UPPER(ISNULL(C.[Name],'')),      
							UPPER(ISNULL(C.[CustomerCode],'')),
							WOBI.[GrandTotal], -- BalanceAmount
							((ISNULL(WOBI.[GrandTotal], 0) - ISNULL(WOBI.[RemainingAmount], 0)) + ISNULL(WOBI.[CreditMemoUsed], 0)),  -- CurrentAmount     
							ISNULL(WOBI.[RemainingAmount], 0) + ISNULL(WOBI.[CreditMemoUsed], 0), --PaymentAmount  		               				
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN WOBI.RemainingAmount	ELSE 0 END),
							WOBI.[GrandTotal],  -- InvoiceAmount      
							0,
							0,
							ISNULL(WOBI.[CreditMemoUsed],0) AS CreditMemoUsed,							
							(SELECT TOP 1 MSD.[Level1Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level2Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level3Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level4Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level5Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level6Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level7Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level8Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level9Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level10Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level1Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level2Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level3Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level4Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level5Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level6Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level7Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level8Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level9Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level10Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),							
							WO.MasterCompanyId,
							0 AS StatusId,
							0 AS IsCreditMemo,
							0,
							@WOModuleTypeId, -- 'WorkOrder',
							LegalEntityName = (SELECT   
							STUFF((SELECT DISTINCT ',' + LE.[Name]  
								FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK)
									JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = WOP.ManagementStructureId
									JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
									JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
								WHERE WOP.WorkOrderId = WO.WorkOrderId
								FOR XML PATH('')), 1, 1, ''))
			FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) 
				INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = WOBI.WorkOrderId      
				INNER JOIN [dbo].[Customer] C  WITH (NOLOCK) ON C.CustomerId = WO.CustomerId
				LEFT JOIN  [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = WO.CreditTermId      
			WHERE WO.[CustomerId] = ISNULL(@CustomerId, WO.CustomerId) AND ISNULL(WOBI.[IsVersionIncrease],0) = 0 AND ISNULL(WOBI.[IsPerformaInvoice],0) = 0
				AND ISNULL(WOBI.[RemainingAmount],0) > 0 AND WOBI.[InvoiceStatus] = @InvoiceStatus
				AND CAST(WOBI.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
				AND WO.[MasterCompanyId] = @MasterCompanyid 
				AND @IsInvoice = 1
				AND (CASE WHEN @IsDeposit = 1 THEN ((ISNULL(WOBI.[GrandTotal], 0) - ISNULL(WOBI.[RemainingAmount], 0)) + ISNULL(WOBI.[CreditMemoUsed], 0)) END > 0 OR CASE WHEN @IsDeposit = 0 THEN 1 END = 1) 
							
			UPDATE #TEMPInvoiceRecords SET InvoicePaidAmount = ISNULL(tmpcash.InvoicePaidAmount,0)
				FROM( SELECT 
					   ISNULL(SUM(IPS.PaymentAmount),0)  AS 'InvoicePaidAmount',				  
					   IPS.SOBillingInvoicingId AS BillingInvoicingId
				 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)   
					JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = IPS.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @WOModuleTypeId
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId  
				 WHERE CP.StatusId = @CustomerPaymentsPostedStatus AND IPS.InvoiceType = @WO 
				 GROUP BY IPS.SOBillingInvoicingId 
				) tmpcash WHERE tmpcash.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId

			UPDATE #TEMPInvoiceRecords SET CreditMemoAmount = ISNULL(tmpcm.CMAmount, 0)
					FROM( SELECT ISNULL(SUM(CMD.Amount),0) AS 'CMAmount', TmpInv.BillingInvoicingId, CMD.BillingInvoicingItemId      
						FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)   
							INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
							INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK) ON WOBII.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId 
							JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = WOBII.BillingInvoicingId AND TmpInv.ModuleTypeId = @WOModuleTypeId
						WHERE CMD.IsWorkOrder = 1 AND CM.CustomerId = TmpInv.CustomerId AND CM.StatusId = @CMPostedStatusId
						GROUP BY CMD.BillingInvoicingItemId, TmpInv.BillingInvoicingId  
				) tmpcm WHERE tmpcm.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId	
		
			-- SO INVOICE DETAILS
			select * from #TEMPInvoiceRecords
			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],
				   [Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
				   [level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName])
			SELECT DISTINCT SOBI.[SOBillingInvoicingId],
				                C.[CustomerId],  					
                                UPPER(ISNULL(C.[Name],'')),      
                                UPPER(ISNULL(C.[CustomerCode],'')),								   
								SOBI.[GrandTotal],  -- [BalanceAmount]
								(SOBI.[GrandTotal] - SOBI.[RemainingAmount] + ISNULL(SOBI.[CreditMemoUsed],0)), -- 'CurrentlAmount',
								SOBI.[RemainingAmount] + ISNULL(SOBI.[CreditMemoUsed],0), -- 'PaymentAmount', 
								(CASE WHEN DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
										 WHEN CTM.Code='CIA' THEN -1
										 WHEN CTM.Code='CreditCard' THEN -1
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN SOBI.RemainingAmount ELSE 0 END),
								(CASE WHEN DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN SOBI.RemainingAmount ELSE 0 END),      
                               SOBI.GrandTotal,  -- 'InvoiceAmount'
							   0, -- CMAmount
					           0, -- CreditMemoAmount
							   ISNULL(SOBI.CreditMemoUsed,0), --CreditMemoUsed							  
							   (SELECT TOP 1 MSD.[Level1Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level2Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level3Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level4Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level5Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level6Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level7Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level8Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level9Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level10Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE  MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),											
							   (SELECT TOP 1 UPPER(MSD.[Level1Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level2Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level3Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level4Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level5Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level6Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level7Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level8Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level9Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level10Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE  MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),					
							   SOBI.MasterCompanyId,
							   0,  --StatusId  
					           0,  --IsCreditMemo
							   0,  --InvoicePaidAmount,
							   @SOModuleTypeId,  --'SalesOrder',
							   LegalEntityName = (SELECT   
								STUFF((SELECT DISTINCT ',' + LE.[Name]  
									 FROM [dbo].[SalesOrderPart] SOP WITH (NOLOCK)
										JOIN [dbo].[Stockline] SL ON SL.StockLineId = SOP.StockLineId
										JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = SL.ManagementStructureId
										JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
										JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
									WHERE SOP.SalesOrderId = SO.SalesOrderId
									FOR XML PATH('')), 1, 1, ''))
				FROM [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK)       
					INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId      
					INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId = SO.CustomerId      
					 LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON CTM.CreditTermsId = SO.CreditTermId      
				WHERE SO.CustomerId = ISNULL(@customerid, SO.[CustomerId])
					AND ISNULL(SOBI.[RemainingAmount],0) > 0 AND SOBI.[InvoiceStatus] = @InvoiceStatus AND ISNULL(SOBI.[IsProforma],0) = 0 
					AND CAST(SOBI.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
					AND SO.[MasterCompanyId] = @Mastercompanyid  
					AND @IsInvoice = 1	
					AND (CASE WHEN @IsDeposit = 1 THEN ((ISNULL(SOBI.[GrandTotal], 0) - ISNULL(SOBI.[RemainingAmount], 0)) + ISNULL(SOBI.[CreditMemoUsed], 0)) END > 0 OR CASE WHEN @IsDeposit = 0 THEN 1 END = 1) 
										
			UPDATE #TEMPInvoiceRecords SET [InvoicePaidAmount] = ISNULL(tmpcash.[InvoicePaidAmount],0)
				FROM(SELECT ISNULL(SUM(IPS.PaymentAmount),0) AS 'InvoicePaidAmount',
					   IPS.SOBillingInvoicingId AS BillingInvoicingId
				 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)   
					JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = IPS.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @SOModuleTypeId
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId  
				 WHERE CP.[StatusId] = @CustomerPaymentsPostedStatus AND IPS.[InvoiceType] = @SO 
				 GROUP BY IPS.SOBillingInvoicingId 
				) tmpcash WHERE tmpcash.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId

			UPDATE #TEMPInvoiceRecords SET [CreditMemoAmount] = ISNULL(tmpcm.[CMAmount], 0)
				FROM( SELECT ISNULL(SUM(CMD.Amount),0) AS 'CMAmount', TmpInv.BillingInvoicingId, CMD.BillingInvoicingItemId      
					FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)   
						INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId 
						INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) ON SOBII.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId 
						JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = SOBII.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @SOModuleTypeId
					WHERE CMD.[IsWorkOrder] = 0 AND CM.[CustomerId] = TmpInv.CustomerId AND CM.[StatusId] = @CMPostedStatusId
					GROUP BY CMD.BillingInvoicingItemId, TmpInv.BillingInvoicingId  
			) tmpcm WHERE tmpcm.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId
			
			-- EXCHANGE SO INVOICE DETAILS --

			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],
				   [Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
				   [level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName])			
		    SELECT DISTINCT ESOBI.SOBillingInvoicingId,
				            C.[CustomerId],  					
                            UPPER(ISNULL(C.[Name],'')),      
                            UPPER(ISNULL(C.[CustomerCode],'')),  
							(ESOBI.[GrandTotal]), -- 'BalanceAmount',
			                (ESOBI.[GrandTotal] - ESOBI.[RemainingAmount] + ISNULL(ESOBI.[CreditMemoUsed],0)), -- 'CurrentlAmount',
				            (ESOBI.[RemainingAmount] + ISNULL(ESOBI.[CreditMemoUsed],0)), -- 'PaymentAmount', 	
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN ctm.[Code] = 'COD' THEN -1
								   WHEN CTM.[Code]='CIA' THEN -1
								   WHEN CTM.[Code]='CreditCard' THEN -1
								   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) <= 0 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS AmountpaidbylessTHEN0days,
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
								   WHEN CTM.[Code]='CIA' THEN -1
								   WHEN CTM.[Code]='CreditCard' THEN -1
								   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 30 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby30days,
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
								   WHEN CTM.[Code]='CIA' THEN -1
								   WHEN CTM.[Code]='CreditCard' THEN -1
								   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 60 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby60days,
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 				   WHEN CTM.[Code]='CIA' THEN -1
				 				   WHEN CTM.[Code]='CreditCard' THEN -1
				 				   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 90 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby90days,
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 				   WHEN CTM.[Code]='CIA' THEN -1
				 				   WHEN CTM.[Code]='CreditCard' THEN -1
				 				   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 120 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby120days,
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 				   WHEN CTM.[Code]='CIA' THEN -1
								   WHEN CTM.[Code]='CreditCard' THEN -1
								   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 120 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidbymorethan120days,
				             ESOBI.[GrandTotal] AS 'InvoiceAmount', 
							 0, -- CMAmount
					         0, -- CreditMemoAmount
							 ISNULL(ESOBI.CreditMemoUsed,0), --CreditMemoUsed							
							 (SELECT TOP 1 MSD.[Level1Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 MSD.[Level2Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 MSD.[Level3Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 MSD.[Level4Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 MSD.[Level5Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 MSD.[Level6Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 MSD.[Level7Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 MSD.[Level8Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 MSD.[Level9Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 MSD.[Level10Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE  MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 UPPER(MSD.[Level1Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 UPPER(MSD.[Level2Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 UPPER(MSD.[Level3Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 UPPER(MSD.[Level4Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 UPPER(MSD.[Level5Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 UPPER(MSD.[Level6Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 UPPER(MSD.[Level7Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 UPPER(MSD.[Level8Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 UPPER(MSD.[Level9Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							 (SELECT TOP 1 UPPER(MSD.[Level10Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE  MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),					
							 ESO.[MasterCompanyId],
							 0,
							 0,
							 0,  --InvoicePaidAmount,
							 @EXSOModuleTypeId, 
							 LegalEntityName = (SELECT   
								STUFF((SELECT DISTINCT ',' + LE.[Name]  
									 FROM [dbo].[ExchangeSalesOrderPart] ESOP WITH (NOLOCK)
										JOIN [dbo].[Stockline] SL ON SL.StockLineId = ESOP.StockLineId
										JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = SL.ManagementStructureId
										JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
										JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
									WHERE ESOP.ExchangeSalesOrderId = ESO.ExchangeSalesOrderId
									FOR XML PATH('')), 1, 1, ''))
				FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK)    
							INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.ExchangeSalesOrderId = ESOBI.ExchangeSalesOrderId      
							INNER JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.CustomerId = ESO.CustomerId 
							 LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = ESO.CreditTermId      
				WHERE ESO.[CustomerId] = ISNULL(@CustomerId,ESO.[CustomerId])
					AND ISNULL(ESOBI.[RemainingAmount],0) > 0 
					AND ESOBI.[InvoiceStatus] = @InvoiceStatus
					AND CAST(ESOBI.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
					AND ESO.[MasterCompanyId] = @Mastercompanyid 
					AND @IsInvoice = 1
				    AND (CASE WHEN @IsDeposit = 1 THEN ((ISNULL(ESOBI.[GrandTotal], 0) - ISNULL(ESOBI.[RemainingAmount], 0)) + ISNULL(ESOBI.[CreditMemoUsed], 0)) END > 0 OR CASE WHEN @IsDeposit = 0 THEN 1 END = 1) 
								
			UPDATE #TEMPInvoiceRecords SET [InvoicePaidAmount] = ISNULL(tmpcash.[InvoicePaidAmount],0)
				FROM(SELECT ISNULL(SUM(IPS.PaymentAmount),0) AS 'InvoicePaidAmount',				  
					   IPS.SOBillingInvoicingId AS BillingInvoicingId
				 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)   
					JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = IPS.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @EXSOModuleTypeId
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId  
				 WHERE CP.[StatusId] = @CustomerPaymentsPostedStatus AND IPS.[InvoiceType] = @Exch
				 GROUP BY IPS.SOBillingInvoicingId 
				) tmpcash WHERE tmpcash.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId

			UPDATE #TEMPInvoiceRecords SET [CreditMemoAmount] = ISNULL(tmpcm.[CMAmount], 0)
				FROM( SELECT ISNULL(SUM(CMD.Amount),0) AS 'CMAmount', TmpInv.BillingInvoicingId, CMD.BillingInvoicingItemId      
					FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)   
						INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId 
						INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) ON SOBII.ExchangeSOBillingInvoicingItemId = CMD.BillingInvoicingItemId 
						JOIN #TEMPInvoiceRecords TmpInv ON TmpInv.BillingInvoicingId = SOBII.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @EXSOModuleTypeId
					WHERE CM.InvoiceTypeId = @EXInvoiceTypeId AND CM.[CustomerId] = TmpInv.CustomerId AND CM.[StatusId] = @CMPostedStatusId
					GROUP BY CMD.BillingInvoicingItemId, TmpInv.BillingInvoicingId  
			) tmpcm WHERE tmpcm.BillingInvoicingId = #TEMPInvoiceRecords.BillingInvoicingId
			
			-- CREDIT MEMO --

			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],
				   [Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
				   [level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName])	
			SELECT DISTINCT CM.[CreditMemoHeaderId],
			                C.[CustomerId],     
							UPPER(C.[Name]),
					        UPPER(C.[CustomerCode]),						
							CMD.[Amount],
							0,
							0,
							CMD.[Amount],
							0,
							0,
							0,
							0,
							0,
							CMD.[Amount], --  'InvoiceAmount', 
							CMD.[Amount], -- 'CMAmount', 
							CMD.[Amount], -- 'CreditMemoAmount',
							0, --'CreditMemoUsed'							
							MSD.[Level1Id], 
							MSD.[Level2Id], 
							MSD.[Level3Id], 
							MSD.[Level4Id], 
							MSD.[Level5Id], 
							MSD.[Level6Id], 
							MSD.[Level7Id], 
							MSD.[Level8Id], 
							MSD.[Level9Id], 
							MSD.[Level10Id],
							UPPER(MSD.[Level1Name]),        
							UPPER(MSD.[Level2Name]),       
							UPPER(MSD.[Level3Name]),       
							UPPER(MSD.[Level4Name]),       
							UPPER(MSD.[Level5Name]),       
							UPPER(MSD.[Level6Name]),       
							UPPER(MSD.[Level7Name]),       
							UPPER(MSD.[Level8Name]),       
							UPPER(MSD.[Level9Name]),       
							UPPER(MSD.[Level10Name]),
							CM.[MasterCompanyId],
							CM.[StatusId],
							1,
							0,  -- 'InvoicePaidAmount',
							@CMModuleTypeId,  -- 'Credit Memo',
					        LE.[Name]
			 FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
				INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
				LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
			    LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			    LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CF.CreditTermsId  
				INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId
				INNER JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = CM.ManagementStructureId
				INNER JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
				INNER JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
			WHERE CM.CustomerId = ISNULL(@CustomerId, CM.CustomerId)
				AND CM.StatusId = @CMPostedStatusId		 				
				AND CAST(CM.InvoiceDate AS DATE) <= CAST(@AsOfDate AS DATE) 
				AND CM.MasterCompanyId = @MasterCompanyid  
				AND @IsCredits = 1

			-- STAND ALONE CREDIT MEMO --
				
			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],
				   [Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
				   [level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName])	
			SELECT DISTINCT CM.[CreditMemoHeaderId],
			                C.[CustomerId],     
							UPPER(C.[Name]),
					        UPPER(C.[CustomerCode]),							
							CM.Amount,
							0,
							0,
							CM.Amount,
							0,
							0,
							0,
							0,
							0,
							CM.[Amount], --  'InvoiceAmount', 
							CM.[Amount], --  'CMAmount', 
							CM.[Amount], --  'CreditMemoAmount',
							0,         --  'CreditMemoUsed'						
							MSD.[Level1Id], 
							MSD.[Level2Id], 
							MSD.[Level3Id], 
							MSD.[Level4Id], 
							MSD.[Level5Id], 
							MSD.[Level6Id], 
							MSD.[Level7Id], 
							MSD.[Level8Id], 
							MSD.[Level9Id], 
							MSD.[Level10Id],
							UPPER(MSD.[Level1Name]),        
							UPPER(MSD.[Level2Name]),       
							UPPER(MSD.[Level3Name]),       
							UPPER(MSD.[Level4Name]),       
							UPPER(MSD.[Level5Name]),       
							UPPER(MSD.[Level6Name]),       
							UPPER(MSD.[Level7Name]),       
							UPPER(MSD.[Level8Name]),       
							UPPER(MSD.[Level9Name]),       
							UPPER(MSD.[Level10Name]),
							CM.MasterCompanyId,
							CM.StatusId,
							1,  -- 'IsCreditMemo'
							0,  -- 'InvoicePaidAmount',
							@STLCMModuleTypeId,  -- 'SalesOrderCreditMemo',
					        LE.[Name]
			 FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
			LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0    
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId    
		    LEFT JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId			  
			LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID  
		   INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH (NOLOCK) ON ES.Level1Id = MSL.ID
		   INNER JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON MSL.LegalEntityId = LE.LegalEntityId  
		  WHERE CM.[CustomerId] = ISNULL(@CustomerId,CM.CustomerId) 
		    AND CM.[IsStandAloneCM] = 1           
		    AND CM.[StatusId] = @CMPostedStatusId
		    AND CM.[MasterCompanyId] = @Mastercompanyid      
		    AND CAST(CM.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
			AND @IsCredits = 1

			-- MANUAL JOURNAL --
				
			INSERT INTO #TEMPInvoiceRecords([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
			       [BalanceAmount],[CurrentAmount],[PaymentAmount],[Amountlessthan0days],[Amountlessthan30days],
				   [Amountlessthan60days],[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
				   [InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],
				   [Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
				   [level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
				   [MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],[ModuleTypeId],[LegalEntityName])	
			SELECT DISTINCT MJH.[ManualJournalHeaderId],
	                        MJD.[ReferenceId],
							UPPER(ISNULL(CST.[Name],'')),
						    UPPER(ISNULL(CST.[CustomerCode],'')),
							ISNULL(SUM(MJD.[Debit]),0) - ISNULL(SUM(MJD.[Credit]),0),
							0,
							0,
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.[Code] = 'COD' THEN -1      
								 WHEN ctm.[Code]='CIA' THEN -1      
								 WHEN ctm.[Code]='CreditCard' THEN -1      
								 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS AmountpaidbylessTHEN0days,      
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby30days,      
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby60days,      
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby90days,      
						    (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby120days,      
						    (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidbymorethan120days,
							ISNULL(SUM(MJD.[Debit]),0) - ISNULL(SUM(MJD.[Credit]),0), -- 'InvoiceAmount', 
							0, --  'CMAmount', 
							0, --  'CreditMemoAmount',
							0, --  'CreditMemoUsed'						
							MSD.[Level1Id], 
							MSD.[Level2Id], 
							MSD.[Level3Id], 
							MSD.[Level4Id], 
							MSD.[Level5Id], 
							MSD.[Level6Id], 
							MSD.[Level7Id], 
							MSD.[Level8Id], 
							MSD.[Level9Id], 
							MSD.[Level10Id],
							UPPER(CAST(MSL1.[Code] AS VARCHAR(250)) + ' - ' + MSL1.[Description]) AS level1,        
						    UPPER(CAST(MSL2.[Code] AS VARCHAR(250)) + ' - ' + MSL2.[Description]) AS level2,       
						    UPPER(CAST(MSL3.[Code] AS VARCHAR(250)) + ' - ' + MSL3.[Description]) AS level3,       
						    UPPER(CAST(MSL4.[Code] AS VARCHAR(250)) + ' - ' + MSL4.[Description]) AS level4,       
						    UPPER(CAST(MSL5.[Code] AS VARCHAR(250)) + ' - ' + MSL5.[Description]) AS level5,       
						    UPPER(CAST(MSL6.[Code] AS VARCHAR(250)) + ' - ' + MSL6.[Description]) AS level6,       
						    UPPER(CAST(MSL7.[Code] AS VARCHAR(250)) + ' - ' + MSL7.[Description]) AS level7,       
						    UPPER(CAST(MSL8.[Code] AS VARCHAR(250)) + ' - ' + MSL8.[Description]) AS level8,       
						    UPPER(CAST(MSL9.[Code] AS VARCHAR(250)) + ' - ' + MSL9.[Description]) AS level9,       
						    UPPER(CAST(MSL10.[Code] AS VARCHAR(250)) + ' - ' + MSL10.[Description]) AS level10,
							MJH.[MasterCompanyId],
							0,
							0,  -- 'IsCreditMemo'
							0,  -- 'InvoicePaidAmount',
							@MJEModuleTypeId,  -- 'SalesOrderCreditMemo',
					        LE.[Name]
		  FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)   
		  INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.[ManualJournalHeaderId] = MJD.[ManualJournalHeaderId]
		  INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.[CustomerId] = MJD.[ReferenceId]
		   LEFT JOIN [dbo].[CustomerFinancial] CSF  ON CSF.[CustomerId] = CST.[CustomerId]
		  INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @MSModuleId AND MSD.[ReferenceID] = MJD.[ManualJournalDetailsId]    
		   LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.[EntityStructureId] = MSD.[EntityMSID] 
		   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.[CreditTermsId] = CSF.[CreditTermsId]      
		   LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CST.[CustomerTypeId] = CT.[CustomerTypeId]      
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL1 WITH (NOLOCK) ON  MSD.[Level1Id] = MSL1.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL2 WITH (NOLOCK) ON  MSD.[Level2Id] = MSL2.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL3 WITH (NOLOCK) ON  MSD.[Level3Id] = MSL3.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL4 WITH (NOLOCK) ON  MSD.[Level4Id] = MSL4.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL5 WITH (NOLOCK) ON  MSD.[Level5Id] = MSL5.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL6 WITH (NOLOCK) ON  MSD.[Level6Id] = MSL6.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL7 WITH (NOLOCK) ON  MSD.[Level7Id] = MSL7.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL8 WITH (NOLOCK) ON  MSD.[Level8Id] = MSL8.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL9 WITH (NOLOCK) ON  MSD.[Level9Id] = MSL9.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH (NOLOCK) ON MSD.[Level10Id] = MSL10.ID
		   LEFT JOIN [dbo].[LegalEntity] LE ON MSL1.[LegalEntityId] = LE.[LegalEntityId]
		   WHERE MJD.[ReferenceId] = ISNULL(@CustomerId,MJD.ReferenceId)  
			AND MJH.[ManualJournalStatusId] = @MJEPostStatusId
			AND MJD.[ReferenceTypeId] = 1  
			AND CAST(MJH.[PostedDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
			AND MJH.[MasterCompanyId] = @Mastercompanyid  
			AND @IsCredits = 1
			GROUP BY MJH.[ManualJournalHeaderId],MJD.[ReferenceId],CST.[Name],CST.[CustomerCode],MJH.[JournalNumber], 
				MJH.[PostedDate],CTM.[Name],ctm.[Code],ctm.[NetDays],
				MSD.[Level1Id],MSD.[Level2Id],MSD.[Level3Id],MSD.[Level4Id],MSD.[Level5Id],MSD.[Level6Id],MSD.[Level7Id],MSD.[Level8Id],MSD.[Level9Id],MSD.[Level10Id],
				MSL1.[Code], MSL1.[Description],
				MSL2.[Code], MSL2.[Description],
				MSL3.[Code], MSL3.[Description],
				MSL4.[Code], MSL4.[Description],
				MSL5.[Code], MSL5.[Description],
				MSL6.[Code], MSL6.[Description],
				MSL7.[Code], MSL7.[Description],
				MSL8.[Code], MSL8.[Description],
				MSL9.[Code], MSL9.[Description],
				MSL10.[Code], MSL10.[Description],
				MJH.[MasterCompanyId],LE.[Name]

			SELECT  [CustomerId],[CustomerName],[CustomerCode],
					ISNULL(SUM([BalanceAmount]),0) BalanceAmount,
					ISNULL(SUM([CurrentAmount]),0) CurrentAmount,
					ISNULL(SUM([PaymentAmount]),0) PaymentAmount,
					ISNULL(SUM([Amountlessthan0days]),0) Amountlessthan0days,
					ISNULL(SUM([Amountlessthan30days]),0) Amountlessthan30days,
					ISNULL(SUM([Amountlessthan60days]),0) Amountlessthan60days,
					ISNULL(SUM([Amountlessthan90days]),0) Amountlessthan90days,
					ISNULL(SUM([Amountlessthan120days]),0) Amountlessthan120days,
					ISNULL(SUM([Amountmorethan120days]),0) [Amountmorethan120days],
					ISNULL(SUM([InvoiceAmount]),0) InvoiceAmount,
					ISNULL(SUM([CMAmount]),0) CMAmount,
					ISNULL(SUM([CreditMemoAmount]),0) CreditMemoAmount,
					ISNULL(SUM([CreditMemoUsed]),0) CreditMemoUsed,	        
					[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
					[LegalEntityName]
			 INTO #TempResult1 FROM #TEMPInvoiceRecords		
			 WHERE((ISNULL(@CustomerName,'') ='' OR [CustomerName] LIKE '%' + @CustomerName+'%') AND
				  (ISNULL(@CustomerCode,'') ='' OR [CustomerCode] LIKE '%' + @CustomerCode + '%') AND					
				  (ISNULL(@BalanceAmount,0) = 0 OR [BalanceAmount] = @BalanceAmount) AND	
				  (ISNULL(@CurrentAmount,0) = 0 OR [CurrentAmount] = @CurrentAmount) AND	
				  (ISNULL(@PaymentAmount,0) = 0 OR [PaymentAmount] = @PaymentAmount) AND
				  (ISNULL(@Amountlessthan0days,0) = 0 OR [Amountlessthan0days] = @Amountlessthan0days) AND
				  (ISNULL(@Amountlessthan30days,0) =0 OR [Amountlessthan30days] = @Amountlessthan30days) AND
				  (ISNULL(@Amountlessthan60days,0) =0 OR [Amountlessthan60days]= @Amountlessthan60days) AND
				  (ISNULL(@Amountlessthan90days,0) =0 OR [Amountlessthan90days]= @Amountlessthan90days) AND
				  (ISNULL(@Amountlessthan120days,0) =0 OR [Amountlessthan120days] = @Amountlessthan120days) AND					
				  (ISNULL(@Amountmorethan120days,0) =0 OR [Amountmorethan120days] = @Amountmorethan120days) AND
				  (ISNULL(@InvoiceAmount,0) =0 OR [InvoiceAmount] = @InvoiceAmount) AND
				  (ISNULL(@level1Str,'') ='' OR [level1] LIKE '%' + @level1Str + '%') AND
				  (ISNULL(@level2Str,'') ='' OR [level2] LIKE '%' + @level2Str + '%') AND
				  (ISNULL(@level3Str,'') ='' OR [level3] LIKE '%' + @level3Str + '%') AND
				  (ISNULL(@level4Str,'') ='' OR [level4] LIKE '%' + @level4Str + '%') AND
				  (ISNULL(@level5Str,'') ='' OR [level5] LIKE '%' + @level5Str + '%') AND
				  (ISNULL(@level6Str,'') ='' OR [level6] LIKE '%' + @level6Str + '%') AND
				  (ISNULL(@level7Str,'') ='' OR [level7] LIKE '%' + @level7Str + '%') AND
				  (ISNULL(@level8Str,'') ='' OR [level8] LIKE '%' + @level8Str + '%') AND
				  (ISNULL(@level9Str,'') ='' OR [level9] LIKE '%' + @level9Str + '%') AND
				  (ISNULL(@level10Str,'') ='' OR [level10] LIKE '%' + @level10Str + '%') AND
				  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
				  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
				  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
				  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
				  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
				  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
				  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
				  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
				  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
				  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))) AND
				  (ISNULL(@LegalEntityName,'') ='' OR [LegalEntityName] LIKE '%' + @LegalEntityName + '%')) 
			GROUP BY [CustomerId],[CustomerName],[CustomerCode],[LegalEntityName],
					 [level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10]	
				 			
			SELECT @Count = COUNT(CustomerId) FROM #TempResult1

			SELECT *, @Count AS NumberOfItems FROM #TempResult1 ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='CUSTOMERNAME') THEN [CustomerName] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERNAME') THEN [CustomerName] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CUSTOMERCODE') THEN [CustomerCode] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCODE') THEN [CustomerCode] END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='BALANCEAMOUNT') THEN [BalanceAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='BALANCEAMOUNT') THEN [BalanceAmount] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CURRENTAMOUNT') THEN [CurrentAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CURRENTAMOUNT') THEN [CurrentAmount] END DESC, 			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTAMOUNT') THEN [PaymentAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTAMOUNT') THEN [PaymentAmount] END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN0DAYS') THEN [Amountlessthan0days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN0DAYS') THEN [Amountlessthan0days] END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN30DAYS') THEN [Amountlessthan30days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN30DAYS') THEN [Amountlessthan30days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN60DAYS') THEN [Amountlessthan60days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN60DAYS') THEN [Amountlessthan60days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN90DAYS') THEN [Amountlessthan90days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN90DAYS') THEN [Amountlessthan90days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN120DAYS') THEN [Amountlessthan120days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN120DAYS') THEN [Amountlessthan120days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTMORETHAN120DAYS') THEN [Amountmorethan120days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTMORETHAN120DAYS') THEN [Amountmorethan120days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='INVOICEAMOUNT') THEN [InvoiceAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='INVOICEAMOUNT') THEN [InvoiceAmount] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL1') THEN [level1] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL1') THEN [level1] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL2') THEN [level2] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL2') THEN [level2] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL3') THEN [level3] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL3') THEN [level3] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL4') THEN [level4] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL4') THEN [level4] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL5') THEN [level5] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL5') THEN [level5] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL6') THEN [level6] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL6') THEN [level6] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL7') THEN [level7] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL7') THEN [level7] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL8') THEN [level8] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL8') THEN [level8] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL9') THEN [level9] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL9') THEN [level9] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL10') THEN [level10] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL10') THEN [level10] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LegalEntityName') THEN [LegalEntityName] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LegalEntityName') THEN [LegalEntityName] END DESC
			
			OFFSET @RecordFrom ROWS FETCH NEXT @PageSize ROWS ONLY
					   				 
		END
		ELSE  -- DETAIL VIEW
		BEGIN			
			IF OBJECT_ID(N'tempdb..#TEMPInvoiceRecordsDetailsViewSSRS') IS NOT NULL    
			BEGIN    
				DROP TABLE #TEMPInvoiceRecordsDetailsViewSSRS
			END
			
			CREATE TABLE #TEMPInvoiceRecordsDetailsViewSSRS(        
				[ID] BIGINT IDENTITY(1,1), 
				[BillingInvoicingId] BIGINT NOT NULL,
				[CustomerId] BIGINT NULL,
				[CustomerName] VARCHAR(200) NULL,
				[CustomerCode] VARCHAR(50) NULL,
				[CurrencyCode] VARCHAR(50) NULL,
				[DocType] VARCHAR(50) NULL,
				[InvoiceNo] VARCHAR(50) NULL,
		        [InvoiceDate] DATETIME2 NULL,
				[DSI] INT NULL,
				[DSO] INT NULL,
				[DSS] INT NULL,
				[CustomerRef] VARCHAR(100),
		 		[Salesperson] VARCHAR(100),
		        [CreditTerms] VARCHAR(100),
				[BalanceAmount] DECIMAL(18, 2) NULL,
				[CurrentAmount] DECIMAL(18, 2) NULL,
				[PaymentAmount] DECIMAL(18, 2) NULL,
				[Amountlessthan0days] DECIMAL(18, 2) NULL,
				[Amountlessthan30days] DECIMAL(18, 2) NULL,
				[Amountlessthan60days] DECIMAL(18, 2) NULL,
				[Amountlessthan90days] DECIMAL(18, 2) NULL,
				[Amountlessthan120days] DECIMAL(18, 2) NULL,
				[Amountmorethan120days] DECIMAL(18, 2) NULL,		
				[InvoiceAmount] DECIMAL(18, 2) NULL,
				[CMAmount] DECIMAL(18, 2) NULL,
				[CreditMemoAmount] DECIMAL(18, 2) NULL,
				[CreditMemoUsed] DECIMAL(18, 2) NULL,
				[fxRateAmount] VARCHAR(20) NULL,
				[DueDate] DATETIME2 NULL,
				[Level1Id] BIGINT NULL,
				[Level2Id] BIGINT NULL,
				[Level3Id] BIGINT NULL,
				[Level4Id] BIGINT NULL,
				[Level5Id] BIGINT NULL,
				[Level6Id] BIGINT NULL,
				[Level7Id] BIGINT NULL,
				[Level8Id] BIGINT NULL,
				[Level9Id] BIGINT NULL,
				[Level10Id] BIGINT NULL,
				[level1] VARCHAR(500) NULL,
				[level2] VARCHAR(500) NULL,
				[level3] VARCHAR(500) NULL,
				[level4] VARCHAR(500) NULL,
				[level5] VARCHAR(500) NULL,
				[level6] VARCHAR(500) NULL,
				[level7] VARCHAR(500) NULL,
				[level8] VARCHAR(500) NULL,
				[level9] VARCHAR(500) NULL,
				[level10] VARCHAR(500) NULL,
				[MasterCompanyId] INT NULL,
				[StatusId] BIGINT NULL,
				[IsCreditMemo] BIT NULL,
				[InvoicePaidAmount] DECIMAL(18, 2) NULL,
				[ModuleTypeId] INT NULL,
				[LegalEntityName] VARCHAR(MAX) NULL					
			)
			
			-- WO IONVOICE DETAILS

			INSERT INTO #TEMPInvoiceRecordsDetailsViewSSRS([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
											[CurrencyCode],[DocType],[InvoiceNo],[InvoiceDate],[DSI],[DSO],[DSS],[DueDate],
											[CustomerRef],[Salesperson],[CreditTerms],
											[BalanceAmount],[CurrentAmount],[PaymentAmount],
											[Amountlessthan0days],[Amountlessthan30days],[Amountlessthan60days],
											[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
											[InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],[fxRateAmount],
											[Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
											[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
											[MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],
											[ModuleTypeId],[LegalEntityName])
			SELECT DISTINCT WOBI.[BillingInvoicingId],			               
							C.[CustomerId],
							UPPER(ISNULL(C.[Name],'')),      
							UPPER(ISNULL(C.[CustomerCode],'')),
							UPPER(CR.[Code]), 
							UPPER('AR-INV'),
							UPPER(WOBI.[InvoiceNo]),     
							WOBI.[InvoiceDate], 
							DATEDIFF(DAY, WOBI.[InvoiceDate], GETUTCDATE()),  --  'DSI' 
			                CASE WHEN (DATEDIFF(DAY, WOBI.[InvoiceDate], GETUTCDATE()) - ISNULL(WO.NetDays,0)) > 0 
								 THEN (DATEDIFF(DAY, WOBI.[InvoiceDate], GETUTCDATE()) - ISNULL(WO.NetDays,0))
							     ELSE 0 END,  -- 'DSO' 		
							CASE WHEN WOBI.[ShipDate] IS NOT NULL THEN DATEDIFF(DAY, WOBI.[ShipDate], GETUTCDATE()) ELSE 0 END,  --  'DSS'
							DATEADD(DAY, WO.NetDays,WOBI.[InvoiceDate]), -- 'DueDate',    
							STUFF((SELECT DISTINCT ',' + UPPER(WOP.[CustomerReference]) 
								FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK)									 
								WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]
								FOR XML PATH('')), 1, 1, ''),
							UPPER(ISNULL(EMP.[FirstName],'Unassigned')),  
							UPPER(CTM.[Name]), 
							WOBI.[GrandTotal], -- BalanceAmount
							((ISNULL(WOBI.[GrandTotal], 0) - ISNULL(WOBI.[RemainingAmount], 0)) + ISNULL(WOBI.[CreditMemoUsed], 0)),  -- CurrentAmount     
							ISNULL(WOBI.[RemainingAmount], 0) + ISNULL(WOBI.[CreditMemoUsed], 0), --PaymentAmount  		               				
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + ISNULL(WO.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN WOBI.RemainingAmount ELSE 0 END),
							(CASE WHEN DATEDIFF(DAY, CAST(CAST(WOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
																WHEN CTM.Code='CIA' THEN -1
																WHEN CTM.Code='CreditCard' THEN -1
																WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(WO.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN WOBI.RemainingAmount	ELSE 0 END),
							WOBI.[GrandTotal],  -- InvoiceAmount      
							0,
							0,
							ISNULL(WOBI.[CreditMemoUsed],0) AS CreditMemoUsed,
							'0.000000',
							(SELECT TOP 1 MSD.[Level1Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level2Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level3Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level4Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level5Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level6Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level7Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level8Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level9Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 MSD.[Level10Id] FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level1Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level2Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level3Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level4Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level5Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level6Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level7Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level8Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level9Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),
							(SELECT TOP 1 UPPER(MSD.[Level10Name]) FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = WOP.ID WHERE WOP.[WorkOrderId] = WO.[WorkOrderId]),							
							WO.MasterCompanyId,
							0 AS StatusId,
							0 AS IsCreditMemo,
							0,
							@WOModuleTypeId, -- 'WorkOrder',
							LegalEntityName = (SELECT   
							STUFF((SELECT DISTINCT ',' + LE.[Name]  
								FROM [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK)
									JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = WOP.ManagementStructureId
									JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
									JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
								WHERE WOP.WorkOrderId = WO.WorkOrderId
								FOR XML PATH('')), 1, 1, ''))
			FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) 
				INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = WOBI.WorkOrderId      
				INNER JOIN [dbo].[Customer] C  WITH (NOLOCK) ON C.CustomerId = WO.CustomerId
				INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId      
				INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = WOBI.CurrencyId      
				LEFT JOIN  [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = WO.CreditTermId      
				LEFT JOIN  [dbo].[Employee] EMP WITH(NOLOCK) ON EMP.EmployeeId = WO.SalesPersonId      
			WHERE WO.[CustomerId] = ISNULL(@CustomerId, WO.CustomerId) AND ISNULL(WOBI.[IsVersionIncrease],0) = 0 AND ISNULL(WOBI.[IsPerformaInvoice],0) = 0
				AND ISNULL(WOBI.[RemainingAmount],0) > 0 AND WOBI.[InvoiceStatus] = @InvoiceStatus
				AND CAST(WOBI.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
				AND WO.[MasterCompanyId] = @masterCompanyid 
				AND @IsInvoice = 1
				AND (CASE WHEN @IsDeposit = 1 THEN ((ISNULL(WOBI.[GrandTotal], 0) - ISNULL(WOBI.[RemainingAmount], 0)) + ISNULL(WOBI.[CreditMemoUsed], 0)) END > 0 OR CASE WHEN @IsDeposit = 0 THEN 1 END = 1) 
			
			UPDATE #TEMPInvoiceRecordsDetailsViewSSRS SET InvoicePaidAmount = ISNULL(tmpcash.InvoicePaidAmount,0)
				FROM( SELECT 
					   ISNULL(SUM(IPS.PaymentAmount),0)  AS 'InvoicePaidAmount',				  
					   IPS.SOBillingInvoicingId AS BillingInvoicingId
				 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)   
					JOIN #TEMPInvoiceRecordsDetailsViewSSRS TmpInv ON TmpInv.BillingInvoicingId = IPS.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @WOModuleTypeId
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId  
				 WHERE CP.StatusId = @CustomerPaymentsPostedStatus AND IPS.InvoiceType = @WO 
				 GROUP BY IPS.SOBillingInvoicingId 
				) tmpcash WHERE tmpcash.BillingInvoicingId = #TEMPInvoiceRecordsDetailsViewSSRS.BillingInvoicingId

			UPDATE #TEMPInvoiceRecordsDetailsViewSSRS SET CreditMemoAmount = ISNULL(tmpcm.CMAmount, 0)
					FROM( SELECT ISNULL(SUM(CMD.Amount),0) AS 'CMAmount', TmpInv.BillingInvoicingId, CMD.BillingInvoicingItemId      
						FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)   
							INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
							INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK) ON WOBII.WOBillingInvoicingItemId = CMD.BillingInvoicingItemId 
							JOIN #TEMPInvoiceRecordsDetailsViewSSRS TmpInv ON TmpInv.BillingInvoicingId = WOBII.BillingInvoicingId AND TmpInv.ModuleTypeId = @WOModuleTypeId
						WHERE CMD.IsWorkOrder = 1 AND CM.CustomerId = TmpInv.CustomerId AND CM.StatusId = @CMPostedStatusId
						GROUP BY CMD.BillingInvoicingItemId, TmpInv.BillingInvoicingId  
				) tmpcm WHERE tmpcm.BillingInvoicingId = #TEMPInvoiceRecordsDetailsViewSSRS.BillingInvoicingId	

			-- SO INVOICE DETAILS

			INSERT INTO #TEMPInvoiceRecordsDetailsViewSSRS([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
											[CurrencyCode],[DocType],[InvoiceNo],[InvoiceDate],[DSI],[DSO],[DSS],[DueDate],
											[CustomerRef],[Salesperson],[CreditTerms],
											[BalanceAmount],[CurrentAmount],[PaymentAmount],
											[Amountlessthan0days],[Amountlessthan30days],[Amountlessthan60days],
											[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
											[InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],[fxRateAmount],	
											[Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
											[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
											[MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],
											[ModuleTypeId],[LegalEntityName])
				SELECT DISTINCT SOBI.[SOBillingInvoicingId],
				                C.[CustomerId],  					
                                UPPER(ISNULL(C.[Name],'')),      
                                UPPER(ISNULL(C.[CustomerCode],'')),  
								UPPER(CR.[Code]), 
								UPPER('AR-INV'),
								UPPER(SOBI.[InvoiceNo]),      
					            SOBI.[InvoiceDate],   
								DATEDIFF(DAY, SOBI.[InvoiceDate], GETUTCDATE()), --'DSI',        
			                    CASE WHEN (DATEDIFF(DAY, SOBI.[InvoiceDate], GETUTCDATE()) - ISNULL(SO.[NetDays],0)) > 0 
									 THEN (DATEDIFF(DAY, SOBI.[InvoiceDate], GETUTCDATE()) - ISNULL(SO.[NetDays],0))
									 ELSE 0 END, -- 'DSO', 										
								CASE WHEN SOBI.[ShipDate] IS NOT NULL THEN DATEDIFF(DAY, SOBI.[ShipDate], GETUTCDATE()) ELSE 0 END,  --  'DSS'
								DATEADD(DAY, SO.[NetDays],SOBI.[InvoiceDate]), -- 'DueDate',     
								STUFF((SELECT DISTINCT ',' + UPPER(SOP.[CustomerReference]) 
									FROM [dbo].[SalesOrderPart] SOP WITH (NOLOCK)									 
									WHERE SOP.[SalesOrderId] = SO.[SalesOrderId]
									FOR XML PATH('')), 1, 1, ''),
								UPPER(ISNULL(SO.[SalesPersonName],'Unassigned')),
								UPPER(SO.[CreditTermName]),   
								SOBI.[GrandTotal],  -- [BalanceAmount]
								(SOBI.[GrandTotal] - SOBI.[RemainingAmount] + ISNULL(SOBI.[CreditMemoUsed],0)), -- 'CurrentlAmount',
								SOBI.[RemainingAmount] + ISNULL(SOBI.[CreditMemoUsed],0), -- 'PaymentAmount', 
								(CASE WHEN DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1
										 WHEN CTM.Code='CIA' THEN -1
										 WHEN CTM.Code='CreditCard' THEN -1
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN SOBI.RemainingAmount ELSE 0 END),
								(CASE WHEN DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(SOBI.InvoiceDate AS DATETIME) + ISNULL(SO.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN SOBI.RemainingAmount ELSE 0 END),      
								(CASE WHEN DATEDIFF(DAY, CASt(CAST(SOBI.InvoiceDate AS DATETIME) + (CASE WHEN CTM.Code = 'COD' THEN -1      
										 WHEN CTM.Code='CIA' THEN -1      
										 WHEN CTM.Code='CreditCard' THEN -1      
										 WHEN CTM.Code='PREPAID' THEN -1 ELSE ISNULL(SO.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN SOBI.RemainingAmount ELSE 0 END),      
                               SOBI.GrandTotal,  -- 'InvoiceAmount'
							   0, -- CMAmount
					           0, -- CreditMemoAmount
							   ISNULL(SOBI.CreditMemoUsed,0), --CreditMemoUsed
							   '0.000000',
							   (SELECT TOP 1 MSD.[Level1Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level2Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level3Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level4Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level5Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level6Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level7Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level8Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level9Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 MSD.[Level10Id] FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE  MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),											
							   (SELECT TOP 1 UPPER(MSD.[Level1Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level2Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level3Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level4Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level5Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level6Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level7Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level8Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level9Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),
							   (SELECT TOP 1 UPPER(MSD.[Level10Name]) FROM [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) WHERE  MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId),					
							   SOBI.MasterCompanyId,
							   0,  --StatusId  
					           0,  --IsCreditMemo
							   0,  --InvoicePaidAmount,
							   @SOModuleTypeId,  --'SalesOrder',
							   LegalEntityName = (SELECT   
								STUFF((SELECT DISTINCT ',' + LE.[Name]  
									 FROM [dbo].[SalesOrderPart] SOP WITH (NOLOCK)
										JOIN [dbo].[Stockline] SL ON SL.StockLineId = SOP.StockLineId
										JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = SL.ManagementStructureId
										JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
										JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
									WHERE SOP.SalesOrderId = SO.SalesOrderId
									FOR XML PATH('')), 1, 1, ''))
				FROM [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK)       
					INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId      
					INNER JOIN [dbo].[Customer] c  WITH (NOLOCK) ON C.CustomerId = SO.CustomerId      
					INNER JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId      
					INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = SOBI.CurrencyId      
					 LEFT JOIN [dbo].[CreditTerms] ctm WITH(NOLOCK) ON CTM.CreditTermsId = SO.CreditTermId      
				WHERE SO.CustomerId = ISNULL(@customerid, SO.[CustomerId])
					AND ISNULL(SOBI.[RemainingAmount],0) > 0 AND SOBI.[InvoiceStatus] = @InvoiceStatus AND ISNULL(SOBI.[IsProforma],0) = 0 
					AND CAST(SOBI.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
					AND SO.[MasterCompanyId] = @Mastercompanyid  
					AND @IsInvoice = 1
					AND (CASE WHEN @IsDeposit = 1 THEN ((ISNULL(SOBI.[GrandTotal], 0) - ISNULL(SOBI.[RemainingAmount], 0)) + ISNULL(SOBI.[CreditMemoUsed], 0)) END > 0 OR CASE WHEN @IsDeposit = 0 THEN 1 END = 1) 
										
			UPDATE #TEMPInvoiceRecordsDetailsViewSSRS SET [InvoicePaidAmount] = ISNULL(tmpcash.[InvoicePaidAmount],0)
				FROM(SELECT ISNULL(SUM(IPS.PaymentAmount),0) AS 'InvoicePaidAmount',
					   IPS.SOBillingInvoicingId AS BillingInvoicingId
				 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)   
					JOIN #TEMPInvoiceRecordsDetailsViewSSRS TmpInv ON TmpInv.BillingInvoicingId = IPS.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @SOModuleTypeId
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId  
				 WHERE CP.[StatusId] = @CustomerPaymentsPostedStatus AND IPS.[InvoiceType] = @SO 
				 GROUP BY IPS.SOBillingInvoicingId 
				) tmpcash WHERE tmpcash.BillingInvoicingId = #TEMPInvoiceRecordsDetailsViewSSRS.BillingInvoicingId

			UPDATE #TEMPInvoiceRecordsDetailsViewSSRS SET [CreditMemoAmount] = ISNULL(tmpcm.[CMAmount], 0)
				FROM( SELECT ISNULL(SUM(CMD.Amount),0) AS 'CMAmount', TmpInv.BillingInvoicingId, CMD.BillingInvoicingItemId      
					FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)   
						INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId 
						INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) ON SOBII.SOBillingInvoicingItemId = CMD.BillingInvoicingItemId 
						JOIN #TEMPInvoiceRecordsDetailsViewSSRS TmpInv ON TmpInv.BillingInvoicingId = SOBII.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @SOModuleTypeId
					WHERE CMD.[IsWorkOrder] = 0 AND CM.[CustomerId] = TmpInv.CustomerId AND CM.[StatusId] = @CMPostedStatusId
					GROUP BY CMD.BillingInvoicingItemId, TmpInv.BillingInvoicingId  
			) tmpcm WHERE tmpcm.BillingInvoicingId = #TEMPInvoiceRecordsDetailsViewSSRS.BillingInvoicingId
			
			-- EXCHANGE SO INVOICE DETAILS --

			INSERT INTO #TEMPInvoiceRecordsDetailsViewSSRS([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
														[CurrencyCode],[DocType],[InvoiceNo],[InvoiceDate],[DSI],[DSO],[DSS],[DueDate],
														[CustomerRef],[Salesperson],[CreditTerms],
														[BalanceAmount],[CurrentAmount],[PaymentAmount],
														[Amountlessthan0days],[Amountlessthan30days],[Amountlessthan60days],
														[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
														[InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],[fxRateAmount],										
														[Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
														[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
														[MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],
														[ModuleTypeId],[LegalEntityName])
				SELECT DISTINCT ESOBI.SOBillingInvoicingId,
				                C.[CustomerId],  					
                                UPPER(ISNULL(C.[Name],'')),      
                                UPPER(ISNULL(C.[CustomerCode],'')),  
								UPPER(CR.[Code]), 
								UPPER('Exchange Invoice'),
								UPPER(ESOBI.[InvoiceNo]),  
								(ESOBI.[InvoiceDate]),
								DATEDIFF(DAY, ESOBI.[InvoiceDate], GETUTCDATE()),  --  'DSI'                    
								CASE WHEN (DATEDIFF(DAY, ESOBI.[InvoiceDate], GETUTCDATE()) - ISNULL(ESO.NetDays,0)) > 0 
								 THEN (DATEDIFF(DAY, ESOBI.[InvoiceDate], GETUTCDATE()) - ISNULL(ESO.NetDays,0))
							     ELSE 0 END,  -- 'DSO' 		
								CASE WHEN ESOBI.[ShipDate] IS NOT NULL THEN DATEDIFF(DAY, ESOBI.[ShipDate], GETUTCDATE()) ELSE 0 END,  --  'DSS'
								DATEADD(DAY, ESO.[NetDays],ESOBI.[InvoiceDate]), -- 'DueDate', 
								UPPER(ESO.[CustomerReference]),
				                UPPER(ISNULL(ESO.[SalesPersonName],'Unassigned')),
								UPPER(ESO.[CreditTermName]),
								(ESOBI.[GrandTotal]), -- 'BalanceAmount',
			                    (ESOBI.[GrandTotal] - ESOBI.[RemainingAmount] + ISNULL(ESOBI.[CreditMemoUsed],0)), -- 'CurrentlAmount',
				                (ESOBI.[RemainingAmount] + ISNULL(ESOBI.[CreditMemoUsed],0)), -- 'PaymentAmount', 	
								(CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN ctm.[Code] = 'COD' THEN -1
									   WHEN CTM.[Code]='CIA' THEN -1
									   WHEN CTM.[Code]='CreditCard' THEN -1
									   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) <= 0 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS AmountpaidbylessTHEN0days,
							    (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
							    	   WHEN CTM.[Code]='CIA' THEN -1
							    	   WHEN CTM.[Code]='CreditCard' THEN -1
							    	   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 30 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby30days,
							    (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
							    	   WHEN CTM.[Code]='CIA' THEN -1
							    	   WHEN CTM.[Code]='CreditCard' THEN -1
							    	   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 60 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby60days,
							    (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 			    	   WHEN CTM.[Code]='CIA' THEN -1
				 			    	   WHEN CTM.[Code]='CreditCard' THEN -1
				 			    	   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 90 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby90days,
							    (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 			    	   WHEN CTM.[Code]='CIA' THEN -1
				 			    	   WHEN CTM.[Code]='CreditCard' THEN -1
				 			    	   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + ISNULL(ESO.[NetDays],0)  AS DATE), GETUTCDATE()) <= 120 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidby120days,
							    (CASE WHEN DATEDIFF(DAY, CAST(CAST(ESOBI.[InvoiceDate] AS DATETIME) + (CASE WHEN CTM.[Code] = 'COD' THEN -1
				 			    	   WHEN CTM.[Code]='CIA' THEN -1
									   WHEN CTM.[Code]='CreditCard' THEN -1
									   WHEN CTM.[Code]='PREPAID' THEN -1 ELSE ISNULL(ESO.[NetDays],0) END) AS DATE), GETUTCDATE()) > 120 THEN ESOBI.[RemainingAmount] ELSE 0 END) AS Amountpaidbymorethan120days,
				                 ESOBI.[GrandTotal] AS 'InvoiceAmount', 
								 0, -- CMAmount
					             0, -- CreditMemoAmount
							     ISNULL(ESOBI.CreditMemoUsed,0), --CreditMemoUsed
								 '0.000000',
								 (SELECT TOP 1 MSD.[Level1Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 MSD.[Level2Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 MSD.[Level3Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 MSD.[Level4Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 MSD.[Level5Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 MSD.[Level6Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 MSD.[Level7Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 MSD.[Level8Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 MSD.[Level9Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 MSD.[Level10Id] FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE  MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
								 (SELECT TOP 1 UPPER(MSD.[Level1Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 UPPER(MSD.[Level2Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 UPPER(MSD.[Level3Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 UPPER(MSD.[Level4Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 UPPER(MSD.[Level5Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 UPPER(MSD.[Level6Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 UPPER(MSD.[Level7Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 UPPER(MSD.[Level8Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 UPPER(MSD.[Level9Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),
							     (SELECT TOP 1 UPPER(MSD.[Level10Name]) FROM [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) WHERE  MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESOBI.ExchangeSalesOrderId),					
								 ESO.[MasterCompanyId],
								 0,
								 0,
								 0,  --InvoicePaidAmount,
								 @EXSOModuleTypeId, 
								 LegalEntityName = (SELECT   
									STUFF((SELECT DISTINCT ',' + LE.[Name]  
										 FROM [dbo].[ExchangeSalesOrderPart] ESOP WITH (NOLOCK)
											JOIN [dbo].[Stockline] SL ON SL.StockLineId = ESOP.StockLineId
											JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = SL.ManagementStructureId
											JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
											JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
										WHERE ESOP.ExchangeSalesOrderId = ESO.ExchangeSalesOrderId
										FOR XML PATH('')), 1, 1, ''))
				FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK)    
							INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.ExchangeSalesOrderId = ESOBI.ExchangeSalesOrderId      
							INNER JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.CustomerId = ESO.CustomerId 
							 LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = ESO.CreditTermId      
							INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = ESOBI.CurrencyId      
				WHERE ESO.[CustomerId] = ISNULL(@CustomerId,ESO.[CustomerId])
					AND ISNULL(ESOBI.[RemainingAmount],0) > 0 
					AND ESOBI.[InvoiceStatus] = @InvoiceStatus
					AND CAST(ESOBI.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
					AND ESO.[MasterCompanyId] = @Mastercompanyid 
					AND @IsInvoice = 1
					AND (CASE WHEN @IsDeposit = 1 THEN ((ISNULL(ESOBI.[GrandTotal], 0) - ISNULL(ESOBI.[RemainingAmount], 0)) + ISNULL(ESOBI.[CreditMemoUsed], 0)) END > 0 OR CASE WHEN @IsDeposit = 0 THEN 1 END = 1) 
								
			UPDATE #TEMPInvoiceRecordsDetailsViewSSRS SET [InvoicePaidAmount] = ISNULL(tmpcash.[InvoicePaidAmount],0)
				FROM(SELECT ISNULL(SUM(IPS.PaymentAmount),0) AS 'InvoicePaidAmount',				  
					   IPS.SOBillingInvoicingId AS BillingInvoicingId
				 FROM [dbo].[InvoicePayments] IPS WITH (NOLOCK)   
					JOIN #TEMPInvoiceRecordsDetailsViewSSRS TmpInv ON TmpInv.BillingInvoicingId = IPS.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @EXSOModuleTypeId
					LEFT JOIN [dbo].[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = IPS.ReceiptId  
				 WHERE CP.[StatusId] = @CustomerPaymentsPostedStatus AND IPS.[InvoiceType] = @Exch
				 GROUP BY IPS.SOBillingInvoicingId 
				) tmpcash WHERE tmpcash.BillingInvoicingId = #TEMPInvoiceRecordsDetailsViewSSRS.BillingInvoicingId

			UPDATE #TEMPInvoiceRecordsDetailsViewSSRS SET [CreditMemoAmount] = ISNULL(tmpcm.[CMAmount], 0)
				FROM( SELECT ISNULL(SUM(CMD.Amount),0) AS 'CMAmount', TmpInv.BillingInvoicingId, CMD.BillingInvoicingItemId      
					FROM [dbo].[CreditMemoDetails] CMD WITH (NOLOCK)   
						INNER JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId 
						INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) ON SOBII.ExchangeSOBillingInvoicingItemId = CMD.BillingInvoicingItemId 
						JOIN #TEMPInvoiceRecordsDetailsViewSSRS TmpInv ON TmpInv.BillingInvoicingId = SOBII.SOBillingInvoicingId AND TmpInv.ModuleTypeId = @EXSOModuleTypeId
					WHERE CM.InvoiceTypeId = @EXInvoiceTypeId AND CM.[CustomerId] = TmpInv.CustomerId AND CM.[StatusId] = @CMPostedStatusId
					GROUP BY CMD.BillingInvoicingItemId, TmpInv.BillingInvoicingId  
			) tmpcm WHERE tmpcm.BillingInvoicingId = #TEMPInvoiceRecordsDetailsViewSSRS.BillingInvoicingId
				
			-- CREDIT MEMO --

			INSERT INTO #TEMPInvoiceRecordsDetailsViewSSRS([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
											[CurrencyCode],[DocType],[InvoiceNo],[InvoiceDate],[DSI],[DSO],[DSS],[DueDate],
											[CustomerRef],[Salesperson],[CreditTerms],
											[BalanceAmount],[CurrentAmount],[PaymentAmount],
											[Amountlessthan0days],[Amountlessthan30days],[Amountlessthan60days],
											[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
											[InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],[fxRateAmount],
											[Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
											[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
											[MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],
											[ModuleTypeId],[LegalEntityName])
			SELECT DISTINCT CM.[CreditMemoHeaderId],
			                C.[CustomerId],     
							UPPER(C.[Name]),
					        UPPER(C.[CustomerCode]),
							UPPER(CR.[Code]),
							UPPER('Credit-Memo'),
							UPPER(CM.[CreditMemoNumber]), 
					        CM.[CreatedDate],
							0,
							0,
							0,
							NULL,
							'',
							UPPER(ISNULL(emp.[FirstName],'Unassigned')), 
							UPPER(CTM.[Name]),  
							CMD.[Amount],
							0,
							0,
							CMD.[Amount],
							0,
							0,
							0,
							0,
							0,
							CMD.[Amount], --  'InvoiceAmount', 
							CMD.[Amount], -- 'CMAmount', 
							CMD.[Amount], -- 'CreditMemoAmount',
							0, --'CreditMemoUsed'
							'0.000000',
							MSD.[Level1Id], 
							MSD.[Level2Id], 
							MSD.[Level3Id], 
							MSD.[Level4Id], 
							MSD.[Level5Id], 
							MSD.[Level6Id], 
							MSD.[Level7Id], 
							MSD.[Level8Id], 
							MSD.[Level9Id], 
							MSD.[Level10Id],
							UPPER(MSD.[Level1Name]),        
							UPPER(MSD.[Level2Name]),       
							UPPER(MSD.[Level3Name]),       
							UPPER(MSD.[Level4Name]),       
							UPPER(MSD.[Level5Name]),       
							UPPER(MSD.[Level6Name]),       
							UPPER(MSD.[Level7Name]),       
							UPPER(MSD.[Level8Name]),       
							UPPER(MSD.[Level9Name]),       
							UPPER(MSD.[Level10Name]),
							CM.[MasterCompanyId],
							CM.[StatusId],
							1,
							0,  -- 'InvoicePaidAmount',
							@CMModuleTypeId,  -- 'WorkOrderCreditMemo',
					        LE.[Name]
			 FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
				INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
				LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
			    LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			    LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CF.CreditTermsId  
				LEFT JOIN [dbo].[CustomerSales] CTS WITH(NOLOCK) ON CTS.CustomerId = CM.CustomerId				
				LEFT JOIN [dbo].[Employee] EMP WITH(NOLOCK) ON EMP.EmployeeId = CTS.PrimarySalesPersonId 				
				LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId      
				INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId
				INNER JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId = CM.ManagementStructureId
				INNER JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
				INNER JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
			WHERE CM.CustomerId = ISNULL(@CustomerId, CM.CustomerId)
				AND CM.StatusId = @CMPostedStatusId		 				
				AND CAST(CM.InvoiceDate AS DATE) <= CAST(@AsOfDate AS DATE) 
				AND CM.MasterCompanyId = @MasterCompanyid  
				AND @IsCredits = 1
							   
			-- STAND ALONE CREDIT MEMO --
				
			INSERT INTO #TEMPInvoiceRecordsDetailsViewSSRS([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
														[CurrencyCode],[DocType],[InvoiceNo],[InvoiceDate],[DSI],[DSO],[DSS],[DueDate],
														[CustomerRef],[Salesperson],[CreditTerms],
														[BalanceAmount],[CurrentAmount],[PaymentAmount],
														[Amountlessthan0days],[Amountlessthan30days],[Amountlessthan60days],
														[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
														[InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],[fxRateAmount],										
														[Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
														[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
														[MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],
														[ModuleTypeId],[LegalEntityName])
			SELECT DISTINCT CM.[CreditMemoHeaderId],
			                C.[CustomerId],     
							UPPER(C.[Name]),
					        UPPER(C.[CustomerCode]),
							UPPER(CR.[Code]),
							UPPER('Stand Alone Credit Memo'),
							UPPER(CM.[CreditMemoNumber]), 
					        CM.[InvoiceDate],
							0,
							0,
							0,
							NULL,
							'',
							'',
							UPPER(CTM.[Name]),  
							CM.Amount,
							0,
							0,
							CM.Amount,
							0,
							0,
							0,
							0,
							0,
							CM.[Amount], --  'InvoiceAmount', 
							CM.[Amount], --  'CMAmount', 
							CM.[Amount], --  'CreditMemoAmount',
							0,         --  'CreditMemoUsed'
							'0.000000',
							MSD.[Level1Id], 
							MSD.[Level2Id], 
							MSD.[Level3Id], 
							MSD.[Level4Id], 
							MSD.[Level5Id], 
							MSD.[Level6Id], 
							MSD.[Level7Id], 
							MSD.[Level8Id], 
							MSD.[Level9Id], 
							MSD.[Level10Id],
							UPPER(MSD.[Level1Name]) AS level1,        
							UPPER(MSD.[Level2Name]) AS level2,       
							UPPER(MSD.[Level3Name]) AS level3,       
							UPPER(MSD.[Level4Name]) AS level4,       
							UPPER(MSD.[Level5Name]) AS level5,       
							UPPER(MSD.[Level6Name]) AS level6,       
							UPPER(MSD.[Level7Name]) AS level7,       
							UPPER(MSD.[Level8Name]) AS level8,       
							UPPER(MSD.[Level9Name]) AS level9,       
							UPPER(MSD.[Level10Name]) AS level10,
							CM.MasterCompanyId,
							CM.StatusId,
							1,  -- 'IsCreditMemo'
							0,  -- 'InvoicePaidAmount',
							@STLCMModuleTypeId,  -- 'SalesOrderCreditMemo',
					        LE.[Name]
			 FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
			LEFT JOIN [dbo].[StandAloneCreditMemoDetails] SACMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = SACMD.CreditMemoHeaderId AND SACMD.IsDeleted = 0    
			LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId   
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON ctm.CreditTermsId = CF.CreditTermsId    
		    LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId  
			LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId
		    LEFT JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId			  
			LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.EntityStructureId = MSD.EntityMSID  
		   INNER JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
		   INNER JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
		  WHERE CM.[CustomerId] = ISNULL(@CustomerId,CM.CustomerId) 
		    AND CM.[IsStandAloneCM] = 1           
		    AND CM.[StatusId] = @CMPostedStatusId
		    AND CM.[MasterCompanyId] = @Mastercompanyid      
		    AND CAST(CM.[InvoiceDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
			AND @IsCredits = 1

			-- MANUAL JOURNAL --
				
			INSERT INTO #TEMPInvoiceRecordsDetailsViewSSRS([BillingInvoicingId],[CustomerId],[CustomerName],[CustomerCode],
														[CurrencyCode],[DocType],[InvoiceNo],[InvoiceDate],[DSI],[DSO],[DSS],[DueDate],
														[CustomerRef],[Salesperson],[CreditTerms],
														[BalanceAmount],[CurrentAmount],[PaymentAmount],
														[Amountlessthan0days],[Amountlessthan30days],[Amountlessthan60days],
														[Amountlessthan90days],[Amountlessthan120days],[Amountmorethan120days],
														[InvoiceAmount],[CMAmount],[CreditMemoAmount],[CreditMemoUsed],[fxRateAmount],
													    [Level1Id],[Level2Id],[Level3Id],[Level4Id],[Level5Id],[Level6Id],[Level7Id],[Level8Id],[Level9Id],[Level10Id],
														[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],
														[MasterCompanyId],[StatusId],[IsCreditMemo],[InvoicePaidAmount],
														[ModuleTypeId],[LegalEntityName])
			SELECT DISTINCT MJH.[ManualJournalHeaderId],
	                        MJD.[ReferenceId],
							UPPER(ISNULL(CST.[Name],'')),
						    UPPER(ISNULL(CST.[CustomerCode],'')), 						    
						    UPPER(CR.[Code]),
							UPPER('Manual Journal'),
							UPPER(MJH.[JournalNumber]), 
							MJH.[PostedDate],
							0,
							0,
							0,
							NULL,
							'',
							'',
							UPPER(CTM.[Name]),  							
							ISNULL(SUM(MJD.[Debit]),0) - ISNULL(SUM(MJD.[Credit]),0),
							0,
							0,
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.[Code] = 'COD' THEN -1      
								 WHEN ctm.[Code]='CIA' THEN -1      
								 WHEN ctm.[Code]='CreditCard' THEN -1      
								 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) <= 0 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS AmountpaidbylessTHEN0days,      
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 0 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 30 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby30days,      
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 30 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE())<= 60 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby60days,      
						    (CASE WHEN DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 60 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 90 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby90days,      
						    (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 90 AND DATEDIFF(DAY, CAST(CAST(MJH.[PostedDate] AS DATETIME) + ISNULL(ctm.NetDays,0)  AS DATE), GETUTCDATE()) <= 120 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidby120days,      
						    (CASE WHEN DATEDIFF(DAY, CASt(CAST(MJH.[PostedDate] AS DATETIME) + (CASE WHEN ctm.Code = 'COD' THEN -1      
	   							 WHEN ctm.[Code]='CIA' THEN -1      
	   							 WHEN ctm.[Code]='CreditCard' THEN -1      
	   							 WHEN ctm.[Code]='PREPAID' THEN -1 ELSE ISNULL(ctm.NetDays,0) END) AS DATE), GETUTCDATE()) > 120 THEN ISNULL(SUM(MJD.Debit),0) - ISNULL(SUM(MJD.Credit),0) ELSE 0 END) AS Amountpaidbymorethan120days,
							ISNULL(SUM(MJD.[Debit]),0) - ISNULL(SUM(MJD.[Credit]),0), -- 'InvoiceAmount', 
							0, --  'CMAmount', 
							0, --  'CreditMemoAmount',
							0, --  'CreditMemoUsed'
							'0.000000',
							MSD.[Level1Id], 
							MSD.[Level2Id], 
							MSD.[Level3Id], 
							MSD.[Level4Id], 
							MSD.[Level5Id], 
							MSD.[Level6Id], 
							MSD.[Level7Id], 
							MSD.[Level8Id], 
							MSD.[Level9Id], 
							MSD.[Level10Id],
							UPPER(CAST(MSL1.[Code] AS VARCHAR(250)) + ' - ' + MSL1.[Description]) AS level1,        
						    UPPER(CAST(MSL2.[Code] AS VARCHAR(250)) + ' - ' + MSL2.[Description]) AS level2,       
						    UPPER(CAST(MSL3.[Code] AS VARCHAR(250)) + ' - ' + MSL3.[Description]) AS level3,       
						    UPPER(CAST(MSL4.[Code] AS VARCHAR(250)) + ' - ' + MSL4.[Description]) AS level4,       
						    UPPER(CAST(MSL5.[Code] AS VARCHAR(250)) + ' - ' + MSL5.[Description]) AS level5,       
						    UPPER(CAST(MSL6.[Code] AS VARCHAR(250)) + ' - ' + MSL6.[Description]) AS level6,       
						    UPPER(CAST(MSL7.[Code] AS VARCHAR(250)) + ' - ' + MSL7.[Description]) AS level7,       
						    UPPER(CAST(MSL8.[Code] AS VARCHAR(250)) + ' - ' + MSL8.[Description]) AS level8,       
						    UPPER(CAST(MSL9.[Code] AS VARCHAR(250)) + ' - ' + MSL9.[Description]) AS level9,       
						    UPPER(CAST(MSL10.[Code] AS VARCHAR(250)) + ' - ' + MSL10.[Description]) AS level10,
							MJH.[MasterCompanyId],
							0,
							0,  -- 'IsCreditMemo'
							0,  -- 'InvoicePaidAmount',
							@MJEModuleTypeId,  -- 'SalesOrderCreditMemo',
					        LE.[Name]
		  FROM [dbo].[ManualJournalHeader] MJH WITH(NOLOCK)   
		  INNER JOIN [dbo].[ManualJournalDetails] MJD WITH(NOLOCK) ON MJH.[ManualJournalHeaderId] = MJD.[ManualJournalHeaderId]
		  INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.[CustomerId] = MJD.[ReferenceId]
		   LEFT JOIN [dbo].[CustomerFinancial] CSF  ON CSF.[CustomerId] = CST.[CustomerId]
		  INNER JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @MSModuleId AND MSD.[ReferenceID] = MJD.[ManualJournalDetailsId]    
		   LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH (NOLOCK) ON ES.[EntityStructureId] = MSD.[EntityMSID] 
		   LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.[CreditTermsId] = CSF.[CreditTermsId]      
		   LEFT JOIN [dbo].[CustomerType] CT  WITH (NOLOCK) ON CST.[CustomerTypeId] = CT.[CustomerTypeId]      
		   LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.[CurrencyId] = MJH.[FunctionalCurrencyId]
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL1 WITH (NOLOCK) ON  MSD.[Level1Id] = MSL1.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL2 WITH (NOLOCK) ON  MSD.[Level2Id] = MSL2.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL3 WITH (NOLOCK) ON  MSD.[Level3Id] = MSL3.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL4 WITH (NOLOCK) ON  MSD.[Level4Id] = MSL4.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL5 WITH (NOLOCK) ON  MSD.[Level5Id] = MSL5.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL6 WITH (NOLOCK) ON  MSD.[Level6Id] = MSL6.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL7 WITH (NOLOCK) ON  MSD.[Level7Id] = MSL7.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL8 WITH (NOLOCK) ON  MSD.[Level8Id] = MSL8.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL9 WITH (NOLOCK) ON  MSD.[Level9Id] = MSL9.ID
		   LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH (NOLOCK) ON MSD.[Level10Id] = MSL10.ID
		   LEFT JOIN [dbo].[LegalEntity] LE ON MSL1.[LegalEntityId] = LE.[LegalEntityId]
		   WHERE MJD.[ReferenceId] = ISNULL(@CustomerId,MJD.ReferenceId)  
			AND MJH.[ManualJournalStatusId] = @MJEPostStatusId
			AND MJD.[ReferenceTypeId] = 1  
			AND CAST(MJH.[PostedDate] AS DATE) <= CAST(@AsOfDate AS DATE) 
			AND MJH.[MasterCompanyId] = @Mastercompanyid  
			AND @IsCredits = 1
			GROUP BY MJH.[ManualJournalHeaderId],MJD.[ReferenceId],CST.[Name],CST.[CustomerCode],CR.[Code],MJH.[JournalNumber], 
				MJH.[PostedDate],CTM.[Name],ctm.[Code],ctm.[NetDays],
				MSD.[Level1Id],MSD.[Level2Id],MSD.[Level3Id],MSD.[Level4Id],MSD.[Level5Id],MSD.[Level6Id],MSD.[Level7Id],MSD.[Level8Id],MSD.[Level9Id],MSD.[Level10Id],
				MSL1.[Code], MSL1.[Description],
				MSL2.[Code], MSL2.[Description],
				MSL3.[Code], MSL3.[Description],
				MSL4.[Code], MSL4.[Description],
				MSL5.[Code], MSL5.[Description],
				MSL6.[Code], MSL6.[Description],
				MSL7.[Code], MSL7.[Description],
				MSL8.[Code], MSL8.[Description],
				MSL9.[Code], MSL9.[Description],
				MSL10.[Code], MSL10.[Description],
				MJH.[MasterCompanyId],LE.[Name]
   		   
			SELECT * INTO #TempResultSSRS FROM #TEMPInvoiceRecordsDetailsViewSSRS
			WHERE ((ISNULL(@CustomerName,'') ='' OR [CustomerName] LIKE '%' + @CustomerName+'%') AND
				  (ISNULL(@CustomerCode,'') ='' OR [CustomerCode] LIKE '%' + @CustomerCode + '%') AND					
				  (ISNULL(@CurrencyCode,'') ='' OR [CurrencyCode] LIKE '%' + @CurrencyCode + '%') AND
				  (ISNULL(@DocType,'') ='' OR [DocType] LIKE '%' + @DocType + '%') AND
				  (ISNULL(@InvoiceNo,'') ='' OR [InvoiceNo] LIKE '%' + @InvoiceNo + '%') AND
				  (ISNULL(@InvoiceDate,'') ='' OR CAST([InvoiceDate] AS DATE) = CAST(@InvoiceDate AS DATE)) AND
				  (ISNULL(@DSI,0) = 0 OR [DSI] = @DSI) AND				  
				  (ISNULL(@DSO,0) = 0 OR [DSO] = @DSO) AND	
				  (ISNULL(@DSS,0) = 0 OR [DSS] = @DSS) AND	
				  (ISNULL(@DueDate,'') ='' OR CAST([DueDate] AS DATE) = CAST(@DueDate AS DATE)) AND				  
				  (ISNULL(@CustomerRef,'') ='' OR [CustomerRef] LIKE '%' + @CustomerRef + '%') AND
				  (ISNULL(@Salesperson,'') ='' OR [Salesperson] LIKE '%' + @Salesperson + '%') AND
				  (ISNULL(@CreditTerms,'') ='' OR [CreditTerms] LIKE '%' + @CreditTerms + '%') AND
				  (ISNULL(@BalanceAmount,0) = 0 OR [BalanceAmount] = @BalanceAmount) AND	
				  (ISNULL(@CurrentAmount,0) = 0 OR [CurrentAmount] = @CurrentAmount) AND	
				  (ISNULL(@PaymentAmount,0) = 0 OR [PaymentAmount] = @PaymentAmount) AND
				  (ISNULL(@Amountlessthan0days,0) = 0 OR [Amountlessthan0days] = @Amountlessthan0days) AND
				  (ISNULL(@Amountlessthan30days,0) =0 OR [Amountlessthan30days] = @Amountlessthan30days) AND
				  (ISNULL(@Amountlessthan60days,0) =0 OR [Amountlessthan60days]= @Amountlessthan60days) AND
				  (ISNULL(@Amountlessthan90days,0) =0 OR [Amountlessthan90days]= @Amountlessthan90days) AND
				  (ISNULL(@Amountlessthan120days,0) =0 OR [Amountlessthan120days] = @Amountlessthan120days) AND					
				  (ISNULL(@Amountmorethan120days,0) =0 OR [Amountmorethan120days] = @Amountmorethan120days) AND
				  (ISNULL(@InvoiceAmount,0) =0 OR [InvoiceAmount] = @InvoiceAmount) AND
				  (ISNULL(@level1Str,'') ='' OR [level1] LIKE '%' + @level1Str + '%') AND
				  (ISNULL(@level2Str,'') ='' OR [level2] LIKE '%' + @level2Str + '%') AND
				  (ISNULL(@level3Str,'') ='' OR [level3] LIKE '%' + @level3Str + '%') AND
				  (ISNULL(@level4Str,'') ='' OR [level4] LIKE '%' + @level4Str + '%') AND
				  (ISNULL(@level5Str,'') ='' OR [level5] LIKE '%' + @level5Str + '%') AND
				  (ISNULL(@level6Str,'') ='' OR [level6] LIKE '%' + @level6Str + '%') AND
				  (ISNULL(@level7Str,'') ='' OR [level7] LIKE '%' + @level7Str + '%') AND
				  (ISNULL(@level8Str,'') ='' OR [level8] LIKE '%' + @level8Str + '%') AND
				  (ISNULL(@level9Str,'') ='' OR [level9] LIKE '%' + @level9Str + '%') AND
				  (ISNULL(@level10Str,'') ='' OR [level10] LIKE '%' + @level10Str + '%') AND
				  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
				  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
				  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
				  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
				  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
				  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
				  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
				  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
				  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
				  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))) AND
				  (ISNULL(@LegalEntityName,'') ='' OR [LegalEntityName] LIKE '%' + @LegalEntityName + '%')) 
			
			SELECT @Count = COUNT(CustomerId) FROM #TempResultSSRS

			SELECT *, @Count AS NumberOfItems FROM #TempResultSSRS ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='CUSTOMERNAME') THEN [CustomerName] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERNAME') THEN [CustomerName] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CUSTOMERCODE') THEN [CustomerCode] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCODE') THEN [CustomerCode] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CURRENCYCODE') THEN [CurrencyCode] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CURRENCYCODE') THEN [CurrencyCode] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DOCTYPE') THEN [DocType] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DOCTYPE') THEN [DocType] END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='INVOICENO') THEN [InvoiceNo] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='INVOICENO') THEN [InvoiceNo] END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='INVOICEDATE') THEN [InvoiceDate] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='INVOICEDATE') THEN [InvoiceDate] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DSI') THEN [DSI] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DSI') THEN [DSI] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DSO') THEN [DSO] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DSO') THEN [DSO] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DSS') THEN [DSS] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DSS') THEN [DSS] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DueDate')  THEN [DueDate] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DueDate')  THEN [DueDate] END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='CUSTOMERREF')  THEN [CustomerRef] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERREF')  THEN [CustomerRef] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SALESPERSON')  THEN [Salesperson] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESPERSON')  THEN [Salesperson] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CREDITTERMS')  THEN [CreditTerms] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CREDITTERMS')  THEN [CreditTerms] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='BALANCEAMOUNT') THEN [BalanceAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='BALANCEAMOUNT') THEN [BalanceAmount] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CURRENTAMOUNT') THEN [CurrentAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CURRENTAMOUNT') THEN [CurrentAmount] END DESC, 			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PAYMENTAMOUNT') THEN [PaymentAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PAYMENTAMOUNT') THEN [PaymentAmount] END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN0DAYS') THEN [Amountlessthan0days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN0DAYS') THEN [Amountlessthan0days] END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN30DAYS') THEN [Amountlessthan30days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN30DAYS') THEN [Amountlessthan30days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN60DAYS') THEN [Amountlessthan60days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN60DAYS') THEN [Amountlessthan60days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN90DAYS') THEN [Amountlessthan90days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN90DAYS') THEN [Amountlessthan90days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTLESSTHAN120DAYS') THEN [Amountlessthan120days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTLESSTHAN120DAYS') THEN [Amountlessthan120days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AMOUNTMORETHAN120DAYS') THEN [Amountmorethan120days] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNTMORETHAN120DAYS') THEN [Amountmorethan120days] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='INVOICEAMOUNT') THEN [InvoiceAmount] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='INVOICEAMOUNT') THEN [InvoiceAmount] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL1') THEN [level1] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL1') THEN [level1] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL2') THEN [level2] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL2') THEN [level2] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL3') THEN [level3] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL3') THEN [level3] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL4') THEN [level4] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL4') THEN [level4] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL5') THEN [level5] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL5') THEN [level5] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL6') THEN [level6] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL6') THEN [level6] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL7') THEN [level7] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL7') THEN [level7] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL8') THEN [level8] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL8') THEN [level8] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL9') THEN [level9] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL9') THEN [level9] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LEVEL10') THEN [level10] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL10') THEN [level10] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LegalEntityName') THEN [LegalEntityName] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LegalEntityName') THEN [LegalEntityName] END DESC
			
			OFFSET @RecordFrom ROWS FETCH NEXT @PageSize ROWS ONLY

		END
			   		 
  END TRY

  BEGIN CATCH
    
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    IF OBJECT_ID(N'tempdb..#TEMPInvoiceRecordsDetailsView') IS NOT NULL
    BEGIN
      DROP TABLE #TEMPInvoiceRecordsDetailsView
    END

    DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME(),
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        @AdhocComments varchar(150) = '[usprpt_GetARAgingAsOfNowReport]',
        @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
        @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
        @AdhocComments = @AdhocComments,
        @ProcedureParameters = @ProcedureParameters,
        @ApplicationName = @ApplicationName,
        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH

  IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
  BEGIN
    DROP TABLE #managmetnstrcture
  END
END