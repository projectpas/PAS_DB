/*************************************************************             
 ** File:   [usp_GetJournalEntriesDetailsByLeafNodeId_WithFilter]             
 ** Author: Devendra Shekh
 ** Description: This stored procedure is used to Get income statement(actual) report Journal Entry Data with Filters
 ** Purpose:  
 ** Date: 18-Nov-2025
         
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date				Author					Change Description              
 ** --   --------			-------					-------------------------------            
	1    18-Nov-2025		Devendra Shekh			Created
	2    02-Feb-2026	    Bhargav Saliya			Added JournalTypeName Field
	3    21-Aug-2026	    Bhargav Saliya			PN-15173 Sort result set by latest Journal Entry (JE) number
	 
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetJournalEntriesDetailsByLeafNodeId_WithFilter]  
(  
	@PageSize INT,
	@PageNumber INT,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT,
	@GlobalFilter VARCHAR(50) = NULL,
	@NodeName VARCHAR(100) = NULL,
	@GLAccount VARCHAR(100) = NULL,
	@JournalNumber VARCHAR(100) = NULL,
	@CreditAmount VARCHAR(50) = NULL,
	@DebitAmount VARCHAR(50) = NULL,
	@Amount DECIMAL(18,2) = NULL,   
	@PeriodName VARCHAR(100) = NULL,
	@EntryDate DATETIME2 = NULL,
	@ReferenceName VARCHAR(100) = NULL,
	@ReferenceModule VARCHAR(100) = NULL,
	@LastMSLevel VARCHAR(100) = NULL,
	@StartAccountingPeriodId BIGINT = NULL,   
	@EndAccountingPeriodId BIGINT = NULL,
	@ReportingStructureId BIGINT = NULL, 
	@ManagementStructureId BIGINT = NULL,  
	@MasterCompanyId INT = NULL,
	@LeafNodeId BIGINT = NULL,
	@GLAccountId BIGINT = NULL,
	@ReferenceNumber VARCHAR(150) = NULL,
	@strFilter VARCHAR(MAX) = NULL,
	@EmployeeId BIGINT = NULL,
	@JournalTypeName VARCHAR(150) = NULL
)  
AS  
BEGIN   
	BEGIN TRY  

	DECLARE @RecordFrom INT;
	DECLARE @TotalRecordsCount INT;
	SET @RecordFrom = (@PageNumber-1) * @PageSize;

	IF OBJECT_ID(N'tempdb..#GLRecordsResult') IS NOT NULL      
	BEGIN      
		DROP TABLE #GLRecordsResult    
	END

	IF OBJECT_ID(N'tempdb..#TempResults') IS NOT NULL      
	BEGIN      
		DROP TABLE #TempResults    
	END

	IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL      
	BEGIN      
		DROP TABLE #TempTable      
	END  
  
	DECLARE @FROMDATE DATETIME;
	DECLARE @TODATE DATETIME;  
	DECLARE @AccountcalMonth VARCHAR(100) = '';
	DECLARE @AccountPeriods VARCHAR(max);  
	DECLARE @AccountPeriodIds VARCHAR(max);  
	DECLARE @LegalEntityId BIGINT;
	DECLARE @PostedBatchStatusId BIGINT;
	DECLARE @BatchMSModuleId BIGINT; 
	DECLARE @RevenueGLAccountTypeId AS BIGINT;
	DECLARE @ExpenseGLAccountTypeId AS BIGINT;
	DECLARE @CustomerRefundModuleId BIGINT = 0;

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

	/* --------------START: Get the timzone and UTC offset -------------- */
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(400) = '', @BaseUtcOffsetSec BIGINT = 0;
	SELECT 	@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description] )
	FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @employeeId AND E.MasterCompanyId = @MasterCompanyId;	
				
	SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec FROM dbo.TimeZone WITH(NOLOCK) WHERE [Description] = @CurrntEmpTimeZoneDesc
	/* -------------- END: Get the timzone and UTC offset -------------- */

	SELECT @FROMDATE = FromDate, @LegalEntityId = LegalEntityId FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId AND IsDeleted = 0
	SELECT @TODATE = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @EndAccountingPeriodId AND IsDeleted = 0 
	SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
	SELECT @RevenueGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Revenue' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
	SELECT @ExpenseGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Expense' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
	SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID
	SELECT @CustomerRefundModuleId = [ModuleId] FROM [dbo].[Module] WHERE [ModuleName] = 'CustomerRefund';

	-- SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
	-- WHERE LE.LegalEntityId = @LegalEntityId;

	IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPMSFilter
	END
		  
	CREATE TABLE #TEMPMSFilter(        
		ID BIGINT  IDENTITY(1,1),        
		LevelIds VARCHAR(MAX)			 
	) 
		  
	INSERT INTO #TEMPMSFilter(LevelIds)	SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!')

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
		  
	IF OBJECT_ID(N'tempdb..#AccPeriodTable') IS NOT NULL
	BEGIN
		DROP TABLE #AccPeriodTable
	END
		  
	CREATE TABLE #AccPeriodTable (
		ID bigint NOT NULL IDENTITY (1, 1),
		PeriodName VARCHAR(100) NULL,
		FiscalYear INT NULL,
		OrderNum INT NULL
	)

	IF(ISNULL(@StartAccountingPeriodId, 0) = ISNULL(@EndAccountingPeriodId, 0))
	BEGIN
		IF((SELECT ISNULL(IsAdjustPeriod, 0) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId) > 0)
		BEGIN
			INSERT INTO #AccPeriodTable (PeriodName,[FiscalYear],[OrderNum]) 
			SELECT  REPLACE(PeriodName,' - ',''),[FiscalYear],[Period]
			FROM dbo.AccountingCalendar WITH(NOLOCK)
			WHERE LegalEntityId = @LegalEntityId AND IsDeleted = 0 AND ISNULL(IsAdjustPeriod, 0) = 1 AND
			CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) 
		END
		ELSE
		BEGIN
			INSERT INTO #AccPeriodTable (PeriodName,[FiscalYear],[OrderNum]) 
			SELECT  REPLACE(PeriodName,' - ',''),[FiscalYear],[Period]
			FROM dbo.AccountingCalendar WITH(NOLOCK)
			WHERE LegalEntityId = @LegalEntityId AND IsDeleted = 0 AND ISNULL(IsAdjustPeriod, 0) = 0 AND
			CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE)
		END
	END
	ELSE
	BEGIN
		INSERT INTO #AccPeriodTable (PeriodName,[FiscalYear],[OrderNum]) 
		SELECT  REPLACE(PeriodName,' - ',''),[FiscalYear],[Period]
		FROM dbo.AccountingCalendar WITH(NOLOCK)
		WHERE LegalEntityId = @LegalEntityId AND IsDeleted = 0 AND
		CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE)
	END
		  
	--INSERT INTO #AccPeriodTable (PeriodName,[FiscalYear],[OrderNum]) 
	--SELECT  REPLACE(PeriodName,' - ',''),[FiscalYear],[Period]
	--FROM dbo.AccountingCalendar WITH(NOLOCK)
	--WHERE LegalEntityId = @LegalEntityId and IsDeleted = 0 and  
	--	 CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) 
		  
	IF OBJECT_ID(N'tempdb..#GLBalance') IS NOT NULL
	BEGIN
		DROP TABLE #GLBalance
	END
    	  
	CREATE TABLE #GLBalance (
		ID bigint NOT NULL IDENTITY (1, 1),
		LeafNodeId BIGINT,
		GLAccountId BIGINT,
		AccountingPeriod VARCHAR(100) NULL,
		CreaditAmount DECIMAL(18, 2) NULL,
		DebitAmount DECIMAL(18, 2) NULL,
		Amount DECIMAL(18, 2) NULL,
		JournalNumber VARCHAR(50), 
		JournalBatchDetailId BIGINT NULL,
		EntryDate DATETIME NULL,
		IsManualJournal BIT NULL,
	)

	INSERT INTO #GLBalance (LeafNodeId, AccountingPeriod, GLAccountId, JournalNumber, JournalBatchDetailId, EntryDate, DebitAmount, CreaditAmount,  Amount, IsManualJournal)
	(SELECT DISTINCT LF.LeafNodeId ,  REPLACE(BD.AccountingPeriod,' - ',''), CMD.GLAccountId, BD.JournalTypeNumber, BD.JournalBatchDetailId, CONVERT(DATETIME, CMD.EntryDate, 120),
					CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END 'DebitAmount',
					CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END 'CreditAmount',

					CASE WHEN GL.GLAccountTypeId = @ExpenseGLAccountTypeId THEN
						(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END) - 
						(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) 
					ELSE
						(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) -
						(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END)
					END AS AMONUT,
					0
	FROM dbo.CommonBatchDetails CMD WITH (NOLOCK)
		INNER JOIN dbo.BatchDetails BD WITH (NOLOCK) ON CMD.JournalBatchDetailId = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
		INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = CMD.CommonJournalBatchDetailId AND ModuleId = @BatchMSModuleId
		INNER JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON CMD.GlAccountId = GLM.GLAccountId
		INNER JOIN dbo.GLAccount GL WITH (NOLOCK) ON GL.GlAccountId = CMD.GLAccountId AND GL.GLAccountTypeId IN (@RevenueGLAccountTypeId, @ExpenseGLAccountTypeId) 
		INNER JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0 AND ISNULL(ReportingStructureId, 0) = @ReportingStructureId
		WHERE CMD.IsDeleted = 0 AND GLM.IsDeleted = 0 AND BD.IsDeleted = 0 AND CMD.MasterCompanyId = @MasterCompanyId AND CMD.GLAccountId = @GLAccountId 					
		AND MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))  
		AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))  
		AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))  
		AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))  
		AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))  
		AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))  
		AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))  
		AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))  
		AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))  
		AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))  
		AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
		GROUP BY LF.LeafNodeId , BD.AccountingPeriod, GLM.IsPositive, CMD.GLAccountId, BD.JournalTypeNumber, BD.JournalBatchDetailId, CONVERT(DATETIME, CMD.EntryDate, 120), GL.GLAccountTypeId)

	IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
	BEGIN
		DROP TABLE #TempTable
	END
    	  
	CREATE TABLE #TempTable (
		ID bigint NOT NULL IDENTITY (1, 1),
		LeafNodeId bigint,
		[Name] varchar(100),
		IsPositive bit NULL,
		ParentId bigint NULL,
		AccountingPeriodId bigint NULL,
		AccountcalMonth VARCHAR(100) NULL,
		AccountingPeriodName VARCHAR(100) NULL,
		Amount decimal(18, 2) NULL,
		TotalAmount decimal(18, 2) NULL,
		ChildCount int NULL,
		IsProcess bit DEFAULT (0)
	)

	DECLARE @LID AS int = 0;
	DECLARE @IsFristRow AS bit = 1;
	DECLARE @LCOUNT AS int = 0;
	SELECT @LCOUNT = MAX(ID) fROM #AccPeriodTable

	--SELECT * FROM #GLBalance

	WHILE(@LCOUNT > 0)
	BEGIN
		SELECT  @AccountcalMonth = PeriodName FROM #AccPeriodTable where ID = @LCOUNT

		INSERT INTO #TempTable (LeafNodeId, [Name], IsPositive, ParentId, IsProcess,AccountcalMonth)
		SELECT LeafNodeId,[Name],IsPositive,ParentId,0,@AccountcalMonth
		FROM dbo.LeafNode
		WHERE LeafNodeId = @LeafNodeId
			AND IsDeleted = 0
			AND ReportingStructureId = @ReportingStructureId

		DECLARE @CID AS int = 0;
		DECLARE @CLID AS int = 0;

		SELECT TOP 1 @CID = ID, @CLID = LeafNodeId
		FROM #TempTable
		WHERE IsProcess = 0 and AccountcalMonth = @AccountcalMonth
		ORDER BY ID

		WHILE (@CLID > 0)
		BEGIN
			INSERT INTO #TempTable (LeafNodeId, [Name], IsPositive, ParentId, IsProcess,AccountcalMonth)
			SELECT  LeafNodeId, [Name], IsPositive,  @CLID, 0,@AccountcalMonth
			FROM dbo.LeafNode
			WHERE ParentId = @CLID
			AND IsDeleted = 0
			AND ReportingStructureId = @ReportingStructureId ORDER BY SequenceNumber DESC

			SET @CLID = 0;
			UPDATE #TempTable SET IsProcess = 1 WHERE ID = @CID AND AccountcalMonth = @AccountcalMonth

			IF EXISTS (SELECT TOP 1 ID FROM #TempTable  WHERE IsProcess = 0 AND AccountcalMonth = @AccountcalMonth)
			BEGIN
				SELECT TOP 1 @CID = ID, @CLID = LeafNodeId
				FROM #TempTable
				WHERE IsProcess = 0
				AND AccountcalMonth = @AccountcalMonth
				ORDER BY ID
			END
		END

		UPDATE #TempTable
		SET ChildCount = ISNULL((SELECT COUNT(ISNULL(T.Amount, 0))
								FROM #TempTable T
								WHERE T.ParentId = T1.LeafNodeId AND T.AccountcalMonth = @AccountcalMonth), 0),
			Amount = CASE WHEN T1.IsPositive = 1 THEN Amount
						ELSE ISNULL(Amount, 0) * -1
						END
			FROM #TempTable T1 WHERE  T1.AccountcalMonth = @AccountcalMonth
		
		UPDATE #TempTable SET IsProcess = 0  WHERE AccountcalMonth = @AccountcalMonth

		SET @CID = 0;
		SET @CLID = 0;
		SELECT TOP 1 @CID = ID
		FROM #TempTable
		WHERE IsProcess = 0 AND AccountcalMonth = @AccountcalMonth
		ORDER BY ID DESC

		WHILE (@CID > 0)
		BEGIN
			SELECT TOP 1 @CLID = LeafNodeId
			FROM #TempTable
			WHERE ID = @CID AND AccountcalMonth = @AccountcalMonth

			UPDATE #TempTable
					SET Amount =  CASE  WHEN IsPositive = 1 THEN 
												(SELECT SUM(ISNULL(T.Amount, 0)) FROM #TempTable T  WHERE T.ParentId = @CLID AND T.AccountcalMonth = @AccountcalMonth)
									ELSE ISNULL((SELECT SUM(ISNULL(T.Amount, 0))FROM #TempTable T WHERE T.ParentId = @CLID AND T.AccountcalMonth = @AccountcalMonth) , 0) * -1
									END
					WHERE ID = @CID
					AND ChildCount > 0 AND AccountcalMonth = @AccountcalMonth

			UPDATE #TempTable  SET IsProcess = 1 WHERE ID = @CID AND AccountcalMonth = @AccountcalMonth

			SET @CID = 0;
			SET @CLID = 0;
			IF EXISTS (SELECT TOP 1 ID FROM #TempTable WHERE IsProcess = 0 AND AccountcalMonth = @AccountcalMonth)
			BEGIN
				SELECT TOP 1 @CID = ID
				FROM #TempTable
				WHERE IsProcess = 0
				AND AccountcalMonth = @AccountcalMonth
				ORDER BY ID DESC
			END
		END

		UPDATE #TempTable 
		SET IsProcess = 0,
			TotalAmount = (SELECT SUM(ISNULL(T.Amount,0)) FROM #TempTable T WHERE T.ParentId = T1.LeafNodeId AND T.AccountcalMonth = @AccountcalMonth)	 
		FROM #TempTable T1 
		WHERE T1.AccountcalMonth = @AccountcalMonth

		SET @CID = 0;
		SET @CLID = 0;
		SELECT TOP 1 @CID = ID
		FROM #TempTable
		WHERE IsProcess = 0
		AND AccountcalMonth = @AccountcalMonth
		ORDER BY ID DESC
			
		WHILE (@CID > 0)
		BEGIN

			SELECT TOP 1 @CLID = ParentId
			FROM #TempTable WHERE ID = @CID AND AccountcalMonth = @AccountcalMonth

			UPDATE #TempTable
			SET IsProcess = 1
			WHERE ID = @CID AND AccountcalMonth = @AccountcalMonth

			SET @CID = 0;
			SET @CLID = 0;

			IF EXISTS (SELECT TOP 1 ID  FROM #TempTable WHERE IsProcess = 0 AND AccountcalMonth = @AccountcalMonth)
			BEGIN
				SELECT TOP 1  @CID = ID
				FROM #TempTable
				WHERE IsProcess = 0
				AND AccountcalMonth = @AccountcalMonth
				ORDER BY ID DESC
			END
		END
			
		SET @IsFristRow = 0
		SET @LCOUNT = @LCOUNT -1
	END

	IF OBJECT_ID(N'tempdb..#AccTrendTable') IS NOT NULL
	BEGIN
		DROP TABLE #AccTrendTable
	END

	CREATE TABLE #AccTrendTable (
		ID bigint NOT NULL IDENTITY (1, 1),
		LeafNodeId BIGINT,
		NodeName VARCHAR(500),
		GLAccountId BIGINT,
		GLAccountCode VARCHAR(50),
		GLAccountName VARCHAR(200),
		JournalNumber VARCHAR(50),	
		JournalBatchDetailId bigint,	
		CreditAmount decimal(18, 2),
		DebitAmount decimal(18, 2),
		AccountingPeriodId bigint,
		AccountingPeriod VARCHAR(100) null,
		PeriodName VARCHAR(100) null,
		ReferenceId BIGINT NULL,
		CustomerId BIGINT NULL,
		ReferenceName VARCHAR(100) null,
		ReferenceModule VARCHAR(100) null,
		DistributionSetupCode VARCHAR(100) NULL,
		EntryDate DATETIME NULL,
		LastMSLevel VARCHAR(MAX) null,
		AllMSlevels VARCHAR(MAX) null,
		OrderNum INT NULL,
		IsManualJournal BIT NULL,
		IsStandAloneCM BIT NULL,
		ReferenceNumber VARCHAR(150) null,
		JournalTypeName VARCHAR(150) null
	)

	DECLARE @COUNT AS INT;
	DECLARE @COUNTMAX AS INT
	SELECT @COUNT = MIN(ID), @COUNTMAX = MAX(ID) fROM #AccPeriodTable
	WHILE (@COUNT <= @COUNTMAX)
	BEGIN

		SELECT @AccountcalMonth = PeriodName FROM #AccPeriodTable where ID = @COUNT

		INSERT INTO #AccTrendTable(LeafNodeId, NodeName, OrderNum, GLAccountId, GLAccountCode, GLAccountName, JournalNumber, JournalBatchDetailId, CreditAmount, DebitAmount, AccountingPeriod, PeriodName, EntryDate, IsManualJournal,IsStandAloneCM) --, ReferenceId, DistributionSetupCode)
		SELECT T.LeafNodeId, T.[Name] , AP.OrderNum, GL.GLAccountId, GLA.AccountCode, GLA.AccountName, JournalNumber, JournalBatchDetailId, GL.CreaditAmount, DebitAmount, AP.PeriodName, REPLACE(AP.PeriodName ,' - ',' '), EntryDate, GL.IsManualJournal,NULL  --CBD.ReferenceId, CBD.DistributionSetupCode, EntryDate 
		FROM #TempTable T  
			JOIN #GLBalance GL ON T.LeafNodeId = GL.LeafNodeId AND T.AccountcalMonth = REPLACE(GL.AccountingPeriod ,' - ','') 
			JOIN dbo.GLAccount GLA WITH (NOLOCK) ON GLA.GLAccountId = GL.GLAccountId 
			LEFT JOIN #AccPeriodTable AP ON AP.PeriodName = T.AccountcalMonth 
		WHERE GL.GLAccountId = @GLAccountId AND T.AccountcalMonth = @AccountcalMonth
			  
		SET @COUNT = @COUNT + 1
	END

	 --SELECT * FROM #AccTrendTable

	--ReferenceName
	UPDATE #AccTrendTable 
		SET	ReferenceModule = CB.ReferenceModule,
			ReferenceName = CB.ReferenceName,
			ReferenceId = CB.ReferenceId, 
			CustomerId = CASE	WHEN UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT' THEN SBD.CustomerId 
								WHEN UPPER(DM.DistributionCode) = 'EX-ShIPMENT' OR UPPER(DM.DistributionCode) = 'EX-FEEBILLING' 
								OR UPPER(DM.DistributionCode) = 'EX-REPAIRBILLING' THEN ExchC.CustomerId
							ELSE '' END,
			LastMSLevel = CB.LastMSLevel,
			AllMSlevels = CB.AllMSlevels,
			IsStandAloneCM = CM.IsStandAloneCM,
			ReferenceNumber = ISNULL(CB.ReferenceNumber, ''),
			JournalTypeName = ISNULL(CB.JournalTypeName, '')
	FROM #AccTrendTable tmp 
		JOIN [dbo].[CommonBatchDetails] CB WITH (NOLOCK) ON tmp.JournalBatchDetailId = cb.JournalBatchDetailId 
		JOIN [dbo].[DistributionSetup] DS WITH (NOLOCK) ON DS.ID = CB.DistributionSetupId
		JOIN [dbo].[DistributionMaster] DM WITH (NOLOCK) ON DS.DistributionMasterId = DM.ID
		LEFT JOIN [dbo].[SalesOrderBatchDetails] SBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = SBD.JournalBatchDetailId 
		LEFT JOIN [dbo].[CreditMemoPaymentBatchDetails] CMBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = CMBD.JournalBatchDetailId 		
		LEFT JOIN [dbo].[RefundCreditMemoMapping] RFCM WITH (NOLOCK) ON CMBD.ReferenceId  = RFCM.CustomerRefundId AND RFCM.CustomerRefundId =
		(
			SELECT TOP 1 RCMP.[CustomerRefundId] FROM [dbo].[RefundCreditMemoMapping] RCMP WITH (NOLOCK) 
			WHERE RCMP.[CustomerRefundId] = RFCM.[CustomerRefundId]
		) AND CMBD.ModuleId = @CustomerRefundModuleId			  			  
		LEFT JOIN [dbo].[ExchangeBatchDetails] EXBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = EXBD.JournalBatchDetailId 
		LEFT JOIN [dbo].[Customer] ExchC WITH (NOLOCK) ON ExchC.CustomerId = EXBD.CustomerId
		LEFT JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = RFCM.CreditMemoHeaderId

	--SELECT * FROM #AccTrendTable

	UPDATE #AccTrendTable 
		SET ReferenceModule = CASE WHEN tmp.IsManualJournal = 1 THEN 'MANUAL JE' ELSE ReferenceModule END,
			ReferenceName = CASE WHEN tmp.IsManualJournal = 1 THEN MJH.JournalNumber ELSE ReferenceName END,
			Referenceid = CASE WHEN tmp.IsManualJournal = 1 THEN MJD.ManualJournalHeaderId ELSE tmp.Referenceid END,
			LastMSLevel = CASE WHEN ISNULL(tmp.IsManualJournal, 0) = 1 THEN  MJD.LastMSLevel ELSE MJD.LastMSLevel END,
			AllMSlevels = CASE WHEN ISNULL(tmp.IsManualJournal, 0) = 1 THEN MJD.AllMSlevels ELSE MJD.AllMSlevels END
	FROM #AccTrendTable tmp 
	JOIN dbo.ManualJournalHeader MJH WITH (NOLOCK) ON tmp.JournalBatchDetailId = MJH.ManualJournalHeaderId
	JOIN dbo.ManualJournalDetails MJD WITH (NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
	WHERE tmp.IsManualJournal = 1

	SELECT LeafNodeId, NodeName, OrderNum, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, JournalBatchDetailId, LastMSLevel, AllMSlevels,
	CAST(CreditAmount as varchar) CreditAmount, CAST(DebitAmount as varchar) DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, 
	SUM(ISNULL(CreditAmount, 0) - ISNULL(DebitAmount, 0)) Amount , IsManualJournal ,IsStandAloneCM,ReferenceNumber,JournalTypeName
	INTO #TempResults
	FROM #AccTrendTable
	WHERE	((@GlobalFilter='' AND (ISNULL(@NodeName,'') ='' OR NodeName LIKE '%' + @NodeName+'%') AND
			(ISNULL(@GLAccount,'') ='' OR (UPPER(GLAccountCode) + '-' + UPPER(GLAccountName)) LIKE '%' + @GLAccount+'%') AND
			(ISNULL(@JournalNumber,'') ='' OR JournalNumber LIKE '%' + @JournalNumber+'%') AND
			(CAST(ISNULL(@CreditAmount,'') AS VARCHAR) ='' OR CAST(CreditAmount AS VARCHAR) LIKE '%' + CAST(ISNULL(@CreditAmount,'') AS VARCHAR) +'%') AND
			(CAST(ISNULL(@DebitAmount,'') AS VARCHAR) ='' OR CAST(DebitAmount AS VARCHAR) LIKE '%' + CAST(ISNULL(@DebitAmount,'') AS VARCHAR) +'%') AND
			(ISNULL(@PeriodName,'') ='' OR PeriodName LIKE '%' + @PeriodName+'%') AND
			(ISNULL(@ReferenceName,'') ='' OR ReferenceName LIKE '%' + @ReferenceName+'%') AND
			(ISNULL(@ReferenceModule,'') ='' OR ReferenceModule LIKE '%' + @ReferenceModule+'%') AND
			(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%' + @LastMSLevel+'%') AND 
			(ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS date)=CAST(@EntryDate AS date)) AND
			(ISNULL(@ReferenceNumber,'') ='' OR ReferenceNumber LIKE '%' + @ReferenceNumber+'%') and
			(ISNULL(@JournalTypeName,'') ='' OR JournalTypeName LIKE '%' + @JournalTypeName+'%'))
			)
	GROUP BY LeafNodeId, NodeName, OrderNum, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, JournalBatchDetailId, LastMSLevel,  AllMSlevels,
	CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, IsManualJournal,IsStandAloneCM,ReferenceNumber,JournalTypeName 

	SELECT * INTO #GLRecordsResult 
	FROM #TempResults
	ORDER BY AccountingPeriodId, JournalNumber DESC
	OFFSET @RecordFrom ROWS
	FETCH NEXT @PageSize ROWS ONLY

	SET @TotalRecordsCount = (SELECT COUNT(JournalNumber) FROM #TempResults);

	;WITH cteRanked AS
	(
		SELECT Amount, LeafNodeId, OrderNum, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, JournalBatchDetailId, LastMSLevel,  AllMSlevels,
		CreditAmount, DebitAmount,  AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, 
		ROW_NUMBER() OVER(ORDER BY LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
		CreditAmount, DebitAmount, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate) rownum, IsManualJournal,IsStandAloneCM, ReferenceNumber,JournalTypeName
		FROM #GLRecordsResult
	) 
	SELECT (SELECT SUM(Amount) FROM cteRanked c2 WHERE c2.rownum <= c1.rownum) AS Amount, 0 AS AccountingPeriodId, OrderNum,
		c1.LeafNodeId, UPPER(c1.NodeName) AS NodeName, c1.GLAccountId, (UPPER(c1.GLAccountCode) + '-' + UPPER(c1.GLAccountName)) AS GLAccount, UPPER(c1.JournalNumber) AS JournalNumber, c1.JournalBatchDetailId, c1.LastMSLevel,  c1.AllMSlevels,
		c1.CreditAmount, c1.DebitAmount, UPPER(c1.AccountingPeriod) AS AccountingPeriod, UPPER(c1.PeriodName) AS PeriodName, c1.ReferenceModule, c1.ReferenceName, c1.ReferenceId, c1.CustomerId, c1.DistributionSetupCode, 
		Cast(DBO.ConvertUTCtoLocal(c1.EntryDate, @CurrntEmpTimeZoneDesc) as datetime) AS EntryDate, IsManualJournal	,IsStandAloneCM, ReferenceNumber,JournalTypeName, @TotalRecordsCount as NumberOfItems		
	FROM cteRanked c1 
	WHERE c1.GLAccountId IS NOT NULL
	ORDER BY OrderNum, JournalNumber DESC;

	END TRY  
	BEGIN CATCH  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_GetJournalEntriesDetailsByLeafNodeId_WithFilter' 
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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