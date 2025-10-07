/*************************************************************             
** File:   [USP_GetJournalEntriesDetailsByLeafNodeId_BalanceSheet_WithFilter]             
** Author: Devendra Shekh
** Description: This stored procedure is used to Get JE Details For Balance Sheet With Filters
** Date: 21-NOV-2024
         
**************************************************************             
** Change History             
**************************************************************             
** PR   Date				Author					Change Description              
** --   --------			-------				-------------------------------            
	1   21-NOV-2024			Devendra Shekh			Created
	2   03-Jan-2025			Bhargav Saliya			Resolved EntryDate conversation issue(Removed DBO.ConvertUTCtoLocal() Function)
	3   07-Oct-2025			Bhargav Saliya			Added ReferenceNumber Field
**************************************************************/  
/*************************************************************             
exec dbo.USP_GetJournalEntriesDetailsByLeafNodeId_BalanceSheet_WithFilter 
@PageSize=10,@PageNumber=1,@SortColumn=N'JournalNumber',@SortOrder=-1,@GlobalFilter=N'',@NodeName=default,@GLAccount=default,@JournalNumber=default,
@CreditAmount=default,@DebitAmount=default,@Amount=default,@PeriodName=default,@EntryDate=default,@ReferenceName=default,@ReferenceModule=default,
@LastMSLevel=default,@StartAccountingPeriodId=187,@EndAccountingPeriodId=187,@ReportingStructureId=23,
@ManagementStructureId=1,@MasterCompanyId=1,@LeafNodeId=153,@GLAccountId=1225,@strFilter=N'1,5,6,20,22,52,53,84!2,7,8,9!3,11,10!4,13,12'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetJournalEntriesDetailsByLeafNodeId_BalanceSheet_WithFilter]
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
	@strFilter VARCHAR(MAX) = NULL
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
	DECLARE @LEFROMDATE DATETIME;
	DECLARE @LETODATE DATETIME;  
	DECLARE @AccountcalID AS bigint;
	DECLARE @AccountPeriods VARCHAR(max);  
	DECLARE @AccountPeriodIds VARCHAR(max);  
	DECLARE @LegalEntityId BIGINT;
	DECLARE @PostedBatchStatusId BIGINT;
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	DECLARE @AssetGLAccountTypeId AS BIGINT;
	DECLARE @LiabilitiesGLAccountTypeId AS BIGINT;
	DECLARE @EquityGLAccountTypeId AS BIGINT;
	DECLARE @BatchMSModuleId BIGINT; 
	DECLARE @periodNameDistinct varchar(60);
	DECLARE @AccountcalMonth varchar(60);
	DECLARE @CustomerRefundModuleId BIGINT = 0;

	DECLARE @IsDebugMode BIT;

	SET @IsDebugMode = 0;

	DECLARE @MAXCalTempID INT = 0, @INITIALFROMDATE DATETIME,@INITIALENDDATE DATETIME;

	IF(@EndAccountingPeriodId is null OR @EndAccountingPeriodId = 0)
	BEGIN
		SET @EndAccountingPeriodId = @StartAccountingPeriodId;
	END

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

	SELECT @INITIALFROMDATE = MIN(FromDate) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE MasterCompanyId = @masterCompanyId AND IsDeleted = 0  
	SELECT @FROMDATE = FromDate, @LegalEntityId = LegalEntityId FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId AND IsDeleted = 0
	SELECT @TODATE = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @EndAccountingPeriodId AND IsDeleted = 0 
	SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
	SELECT @AssetGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Asset' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
	SELECT @LiabilitiesGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Liabilities' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
	SELECT @EquityGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Owners Equity' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1

	SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
	WHERE LE.LegalEntityId = @LegalEntityId;

	SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID
	SELECT @CustomerRefundModuleId = [ModuleId] FROM [dbo].[Module] WHERE [ModuleName] = 'CustomerRefund';

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
		AccountcalID BIGINT NULL,
		PeriodName VARCHAR(100) NULL,
		FromDate DATETIME NULL,
		ToDate DATETIME NULL,
		FiscalYear INT NULL,
		OrderNum INT NULL
	)

	IF(ISNULL(@StartAccountingPeriodId, 0) = ISNULL(@EndAccountingPeriodId, 0))
	BEGIN
		IF((SELECT ISNULL(IsAdjustPeriod, 0) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId) > 0)
		BEGIN
			INSERT INTO #AccPeriodTable (PeriodName, [OrderNum], FromDate, ToDate) 
			SELECT DISTINCT REPLACE(PeriodName,' - ',''), [Period] , FromDate, ToDate
			FROM dbo.AccountingCalendar WITH(NOLOCK)
			WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND IsDeleted = 0 AND  
			CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) AND ISNULL(IsAdjustPeriod, 0) = 1
		END
		ELSE
		BEGIN
			INSERT INTO #AccPeriodTable (PeriodName, [OrderNum], FromDate, ToDate) 
			SELECT DISTINCT REPLACE(PeriodName,' - ',''), [Period] , FromDate, ToDate
			FROM dbo.AccountingCalendar WITH(NOLOCK)
			WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND IsDeleted = 0 AND  
			CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) AND ISNULL(IsAdjustPeriod, 0) = 0
		END
	END
	ELSE
	BEGIN
		INSERT INTO #AccPeriodTable (PeriodName, [OrderNum], FromDate, ToDate) 
		SELECT DISTINCT REPLACE(PeriodName,' - ',''), [Period] , FromDate, ToDate
		FROM dbo.AccountingCalendar WITH(NOLOCK)
		WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND IsDeleted = 0 AND  
		CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE)
	END
		  
	INSERT INTO #AccPeriodTable (AccountcalID, PeriodName) VALUES(9999999,'Total')

	IF OBJECT_ID(N'tempdb..#AccPeriodTableFinal') IS NOT NULL
	BEGIN
		DROP TABLE #AccPeriodTableFinal
	END
		  
	CREATE TABLE #AccPeriodTableFinal (
		ID bigint NOT NULL IDENTITY (1, 1),
		AccountcalID BIGINT NULL,
		PeriodName VARCHAR(100) NULL,
		FromDate DATETIME NULL,
		ToDate DATETIME NULL
	)
		  
	INSERT INTO #AccPeriodTableFinal (AccountcalID, PeriodName, FromDate, ToDate) 
	SELECT AccountingCalendarId, REPLACE(PeriodName,' - ','') , @FROMDATE, ToDate
	FROM dbo.AccountingCalendar WITH(NOLOCK)
	WHERE LegalEntityId = @LegalEntityId and IsDeleted = 0 and  
	CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) --AND ISNULL(IsAdjustPeriod, 0) = 0 

	INSERT INTO #AccPeriodTableFinal (AccountcalID, PeriodName) VALUES(9999999,'Total')

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
		AccountingPeriodName VARCHAR(100) NULL,
		PeriodNameDistinct VARCHAR(100) NULL,
		Amount decimal(18, 2) NULL,
		TotalAmount decimal(18, 2) NULL,
		ChildCount int NULL,
		IsProcess bit DEFAULT (0)
	)

	IF OBJECT_ID(N'tempdb..#AccPeriodTable_All') IS NOT NULL
	BEGIN
		DROP TABLE #AccPeriodTable_All
	END
		  
	CREATE TABLE #AccPeriodTable_All (
		ID bigint NOT NULL IDENTITY (1, 1),
		AccountcalID BIGINT NULL,
		PeriodName VARCHAR(100) NULL,
		FromDate DATETIME NULL,
		ToDate DATETIME NULL
	)
		  
	IF OBJECT_ID(N'tempdb..#GLBalance') IS NOT NULL
	BEGIN
		DROP TABLE #GLBalance
	END
    	  
	CREATE TABLE #GLBalance (
		ID bigint NOT NULL IDENTITY (1, 1),
		LeafNodeId BIGINT,
		GLAccountId BIGINT,
		AccountingPeriodId BIGINT NULL,
		CreaditAmount DECIMAL(18, 2) NULL,
		DebitAmount DECIMAL(18, 2) NULL,
		Amount DECIMAL(18, 2) NULL,
		JournalNumber VARCHAR(50), 
		JournalBatchDetailId BIGINT NULL,
		EntryDate DATETIME NULL,
		PeriodNameDistinct VARCHAR(100),
		IsManualJournal BIT,
	)
		  
	SELECT @MAXCalTempID = MAX(OrderNum) fROM #AccPeriodTable WHERE ISNULL(AccountcalID, 0) NOT IN(9999999)

	SELECT @LEFROMDATE = MIN(FromDate), @LETODATE = MAX(ToDate), @periodNameDistinct = PeriodName FROM #AccPeriodTable WHERE OrderNum = @MAXCalTempID  GROUP BY PeriodName

	DELETE FROM #AccPeriodTable_All

	INSERT INTO #AccPeriodTable_All (AccountcalID, PeriodName, FromDate, ToDate) 
	SELECT AccountingCalendarId, REPLACE(PeriodName,' - ',' ') ,FromDate,ToDate
	FROM dbo.AccountingCalendar WITH(NOLOCK)
	WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND IsDeleted = 0 AND  
	CAST(Fromdate AS DATE) >= CAST(@INITIALFROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@LETODATE AS DATE)  --AND ISNULL(IsAdjustPeriod, 0) = 0 
	ORDER BY FiscalYear, [Period]

	INSERT INTO #GLBalance (LeafNodeId, AccountingPeriodId, DebitAmount, CreaditAmount,  Amount,GLAccountId, JournalNumber, JournalBatchDetailId, EntryDate, PeriodNameDistinct, IsManualJournal)
	(SELECT DISTINCT	LF.LeafNodeId , @AccountcalID, 
						CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END 'DebitAmount',
						CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END 'CreditAmount',
						CASE WHEN GL.GLAccountTypeId = @AssetGLAccountTypeId THEN
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END) - 
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) 
						ELSE
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) -
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END)
						END AS AMONUT,
						CMD.GLAccountId, BD.JournalTypeNumber, BD.JournalBatchDetailId, CONVERT(DATETIME, CMD.EntryDate, 120),				
						--REPLACE(BD.AccountingPeriod,' - ','')
						@periodNameDistinct
						,0
	FROM dbo.CommonBatchDetails CMD WITH (NOLOCK)
		INNER JOIN dbo.BatchDetails BD WITH (NOLOCK) ON CMD.JournalBatchDetailId = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
		INNER JOIN dbo.BatchHeader B WITH (NOLOCK) ON BD.JournalBatchHeaderId = B.JournalBatchHeaderId 
		INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = CMD.CommonJournalBatchDetailId AND ModuleId = @BatchMSModuleId
		INNER JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON CMD.GlAccountId = GLM.GLAccountId
		INNER JOIN dbo.GLAccount GL WITH (NOLOCK) ON GL.GlAccountId = GLM.GLAccountId AND GL.GLAccountTypeId IN (@AssetGLAccountTypeId, @LiabilitiesGLAccountTypeId,@EquityGLAccountTypeId) 
		INNER JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0 AND ISNULL(ReportingStructureId, 0) = @ReportingStructureId 
		WHERE CMD.IsDeleted = 0 AND GLM.IsDeleted = 0 AND BD.IsDeleted = 0 AND CMD.MasterCompanyId = @MasterCompanyId AND CMD.GLAccountId = @GLAccountId 	
		AND BD.AccountingPeriodId IN (SELECT AccountcalID FROm #AccPeriodTable_All) AND ISNULL(B.IsDeleted,0) = 0
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
	GROUP BY LF.LeafNodeId , GLM.IsPositive, CMD.GLAccountId, BD.JournalTypeNumber, BD.JournalBatchDetailId, CONVERT(DATETIME, CMD.EntryDate, 120), GL.GLAccountTypeId, BD.AccountingPeriod)
		
	IF(@IsDebugMode = 1)
	BEGIN
		SELECT * FROm #GLBalance
	END
				 
	DECLARE @LID AS int = 0;
	DECLARE @IsFristRow AS bit = 1;
	DECLARE @LCOUNT AS int = 0;
	SELECT @LCOUNT = MAX(ID) fROM #AccPeriodTable

	WHILE(@LCOUNT > 0)
	BEGIN
		SELECT  @AccountcalID = AccountcalID , @periodNameDistinct = PeriodName, @INITIALENDDATE = ToDate FROM #AccPeriodTable where ID = @LCOUNT AND ID NOT IN(9999999)

		INSERT INTO #TempTable (LeafNodeId, [Name], IsPositive, ParentId, IsProcess,AccountingPeriodId, PeriodNameDistinct)
		SELECT	LeafNodeId,[Name],IsPositive,ParentId,0,@AccountcalID, @periodNameDistinct
				FROM dbo.LeafNode
				WHERE LeafNodeId = @LeafNodeId
				AND IsDeleted = 0
				AND ReportingStructureId = @ReportingStructureId

		DECLARE @CID AS int = 0;
		DECLARE @CLID AS int = 0;

		SELECT TOP 1 @CID = ID, @CLID = LeafNodeId
		FROM #TempTable
		WHERE IsProcess = 0 AND periodNameDistinct = @periodNameDistinct
		ORDER BY ID

		WHILE (@CLID > 0)
		BEGIN
			INSERT INTO #TempTable (LeafNodeId, [Name], IsPositive, ParentId, IsProcess,AccountingPeriodId,PeriodNameDistinct)
			SELECT  LeafNodeId, [Name], IsPositive,  @CLID, 0,@AccountcalID, @periodNameDistinct
			FROM dbo.LeafNode
			WHERE ParentId = @CLID
			AND IsDeleted = 0
			AND ReportingStructureId = @ReportingStructureId ORDER BY SequenceNumber DESC

			SET @CLID = 0;
			UPDATE #TempTable SET IsProcess = 1 WHERE ID = @CID AND periodNameDistinct = @periodNameDistinct
			IF EXISTS (SELECT TOP 1 ID FROM #TempTable  WHERE IsProcess = 0 AND periodNameDistinct = @periodNameDistinct)
			BEGIN
				SELECT TOP 1 @CID = ID, @CLID = LeafNodeId
				FROM #TempTable
				WHERE IsProcess = 0
				AND periodNameDistinct = @periodNameDistinct
				ORDER BY ID
			END
		END

		UPDATE #TempTable
		SET ChildCount = ISNULL((SELECT COUNT(ISNULL(T.Amount, 0))
		FROM #TempTable T
		WHERE T.ParentId = T1.LeafNodeId AND T.periodNameDistinct = @periodNameDistinct), 0),
		Amount = CASE WHEN T1.IsPositive = 1 THEN Amount
		ELSE ISNULL(Amount, 0) * -1
		END
		FROM #TempTable T1 WHERE  T1.periodNameDistinct = @periodNameDistinct
		
		UPDATE #TempTable SET IsProcess = 0  WHERE  periodNameDistinct = @periodNameDistinct

		SET @CID = 0;
		SET @CLID = 0;
		SELECT TOP 1 @CID = ID
		FROM #TempTable
		WHERE IsProcess = 0 AND periodNameDistinct = @periodNameDistinct
		ORDER BY ID DESC

		WHILE (@CID > 0)
		BEGIN
			SELECT TOP 1 @CLID = LeafNodeId
			FROM #TempTable
			WHERE ID = @CID AND periodNameDistinct = @periodNameDistinct

			UPDATE #TempTable
			SET Amount = CASE WHEN IsPositive = 1 THEN 
									(SELECT SUM(ISNULL(T.Amount, 0)) FROM #TempTable T  WHERE T.ParentId = @CLID AND T.periodNameDistinct = @periodNameDistinct)
									ELSE ISNULL((SELECT SUM(ISNULL(T.Amount, 0))FROM #TempTable T WHERE T.ParentId = @CLID AND T.periodNameDistinct = @periodNameDistinct) , 0) * -1
									END
			WHERE	ID = @CID
					AND ChildCount > 0 AND periodNameDistinct = @periodNameDistinct
			UPDATE #TempTable  SET IsProcess = 1 WHERE ID = @CID AND periodNameDistinct = @periodNameDistinct

			SET @CID = 0;
			SET @CLID = 0;
			IF EXISTS (SELECT TOP 1 ID FROM #TempTable WHERE IsProcess = 0 AND periodNameDistinct = @periodNameDistinct)
			BEGIN
				SELECT TOP 1 @CID = ID
				FROM #TempTable
				WHERE IsProcess = 0
				AND periodNameDistinct = @periodNameDistinct
				ORDER BY ID DESC
			END
		END

		UPDATE #TempTable SET IsProcess = 0,
		TotalAmount = (SELECT SUM(ISNULL(T.Amount,0)) FROM #TempTable T WHERE T.ParentId = T1.LeafNodeId AND T.periodNameDistinct = @periodNameDistinct)	 
		FROM #TempTable T1 
		WHERE T1.periodNameDistinct = @periodNameDistinct

		SET @CID = 0;
		SET @CLID = 0;
		SELECT TOP 1 @CID = ID
		FROM #TempTable
		WHERE IsProcess = 0
		AND periodNameDistinct = @periodNameDistinct
		ORDER BY ID DESC
			
		WHILE (@CID > 0)
		BEGIN
			SELECT TOP 1 @CLID = ParentId
			FROM #TempTable WHERE ID = @CID AND periodNameDistinct = @periodNameDistinct

			UPDATE #TempTable
			SET IsProcess = 1
			WHERE ID = @CID AND periodNameDistinct = @periodNameDistinct

			SET @CID = 0;
			SET @CLID = 0;

			IF EXISTS (SELECT TOP 1 ID  FROM #TempTable WHERE IsProcess = 0 AND periodNameDistinct = @periodNameDistinct)
			BEGIN
				SELECT TOP 1  @CID = ID
				FROM #TempTable
				WHERE IsProcess = 0
				AND periodNameDistinct = @periodNameDistinct
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
		IsManualJournal BIT,
		IsStandAloneCM BIT null,
		ReferenceNumber VARCHAR(150) null,
	)
	
	DECLARE @COUNT AS INT;
	DECLARE @COUNTMAX AS INT
	SELECT @COUNT = MIN(ID), @COUNTMAX = MAX(ID) fROM #AccPeriodTable
	WHILE (@COUNT <= @COUNTMAX)
	BEGIN

		SELECT  @AccountcalMonth = PeriodName, @AccountcalID = AccountcalID,@INITIALENDDATE = ToDate FROM #AccPeriodTable where ID = @COUNT AND ID NOT IN(9999999)		  
			  
		INSERT INTO #AccTrendTable(LeafNodeId, NodeName, GLAccountId, GLAccountCode, GLAccountName, JournalNumber, JournalBatchDetailId, CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName, EntryDate, IsManualJournal,IsStandAloneCM) --, ReferenceId, DistributionSetupCode)
		SELECT T.LeafNodeId, T.[Name] , GL.GLAccountId, GLA.AccountCode, GLA.AccountName, JournalNumber, JournalBatchDetailId, GL.CreaditAmount, DebitAmount, GL.AccountingPeriodId, AP.PeriodName, REPLACE(AP.PeriodName ,' - ',' '), EntryDate, ISNULL(GL.IsManualJournal, 0),NULL  --CBD.ReferenceId, CBD.DistributionSetupCode, EntryDate 
		FROM #TempTable T  
			JOIN #GLBalance GL ON T.LeafNodeId = GL.LeafNodeId AND T.periodNameDistinct = REPLACE(GL.periodNameDistinct ,' - ','') 
			JOIN dbo.GLAccount GLA WITH (NOLOCK) ON GLA.GLAccountId = GL.GLAccountId
			LEFT JOIN #AccPeriodTable AP ON AP.PeriodName = T.periodNameDistinct 
		WHERE GL.GLAccountId = @GLAccountId

		SET @COUNT = @COUNT + 1
	END

	UPDATE #AccTrendTable 
		SET
		ReferenceModule = CB.ReferenceModule,
		ReferenceName = CB.ReferenceName,
		ReferenceId = CB.ReferenceId, 
		CustomerId =	CASE	WHEN UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT' THEN SBD.CustomerId 
								WHEN UPPER(DM.DistributionCode) = 'EX-ShIPMENT' OR UPPER(DM.DistributionCode) = 'EX-FEEBILLING' 
								OR UPPER(DM.DistributionCode) = 'EX-REPAIRBILLING' THEN ExchC.CustomerId
						ELSE '' END,
		LastMSLevel = CB.LastMSLevel,
		AllMSlevels = CB.AllMSlevels,
		IsStandAloneCM = CM.IsStandAloneCM,
		ReferenceNumber = ISNULL(CB.ReferenceNumber, '')
	FROM #AccTrendTable tmp 
		JOIN [dbo].[CommonBatchDetails] CB WITH (NOLOCK) ON tmp.JournalBatchDetailId = cb.JournalBatchDetailId 
		JOIN [dbo].[DistributionSetup] DS WITH (NOLOCK) ON DS.ID = CB.DistributionSetupId
		JOIN [dbo].[DistributionMaster] DM WITH (NOLOCK) ON DS.DistributionMasterId = DM.ID
		--LEFT JOIN [dbo].[WorkOrderBatchDetails] WBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = WBD.JournalBatchDetailId 
		LEFT JOIN [dbo].[SalesOrderBatchDetails] SBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = SBD.JournalBatchDetailId 
		--LEFT JOIN [dbo].[StocklineBatchDetails] SD WITH (NOLOCK) ON tmp.JournalBatchDetailId = SD.JournalBatchDetailId 
		--LEFT JOIN [dbo].[StocklineBatchDetails] AST WITH (NOLOCK) ON tmp.JournalBatchDetailId = AST.JournalBatchDetailId AND AST.StockType = 'ASSET'
		--LEFT JOIN [dbo].[ManualJournalPaymentBatchDetails] MJSD WITH (NOLOCK) ON tmp.JournalBatchDetailId = MJSD.JournalBatchDetailId
		--LEFT JOIN [dbo].[VendorPaymentBatchDetails] VPBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = VPBD.JournalBatchDetailId 
		--LEFT JOIN [dbo].[VendorRMAPaymentBatchDetails] VRBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = VRBD.JournalBatchDetailId 
		--LEFT JOIN [dbo].[CustomerReceiptBatchDetails] CRBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = CRBD.JournalBatchDetailId 
		--LEFT JOIN [dbo].[BulkStocklineAdjPaymentBatchDetails] BSAD WITH (NOLOCK) ON tmp.JournalBatchDetailId = BSAD.JournalBatchDetailId 
		LEFT JOIN [dbo].[CreditMemoPaymentBatchDetails] CMBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = CMBD.JournalBatchDetailId 		
		LEFT JOIN [dbo].[RefundCreditMemoMapping] RFCM WITH (NOLOCK) ON CMBD.ReferenceId  = RFCM.CustomerRefundId AND RFCM.CustomerRefundId =
		(
		SELECT TOP 1 RCMP.[CustomerRefundId] FROM [dbo].[RefundCreditMemoMapping] RCMP WITH (NOLOCK) 
		WHERE RCMP.[CustomerRefundId] = RFCM.[CustomerRefundId]
		) AND CMBD.ModuleId = @CustomerRefundModuleId			  			  
		LEFT JOIN [dbo].[ExchangeBatchDetails] EXBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = EXBD.JournalBatchDetailId 
		--LEFT JOIN [dbo].[NonPOInvoiceBatchDetails] NPOBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = NPOBD.JournalBatchDetailId 
		--LEFT JOIN [dbo].[SuspenseAndUnAppliedPaymentBatchDetails] SPBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = SPBD.JournalBatchDetailId 			  
		--LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.VendorId = VRBD.VendorId
		LEFT JOIN [dbo].[Customer] ExchC WITH (NOLOCK) ON ExchC.CustomerId = EXBD.CustomerId
		LEFT JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = RFCM.CreditMemoHeaderId
		--LEFT JOIN [dbo].[ManualJournalHeader] MJH WITH (NOLOCK) ON MJH.ManualJournalHeaderId = MJSD.ReferenceId
	WHERE ISNULL(tmp.IsManualJournal, 0) = 0

	UPDATE #AccTrendTable 
			SET	ReferenceModule = CASE WHEN tmp.IsManualJournal = 1 THEN 'MANUAL JE' ELSE ReferenceModule END,
				ReferenceName = CASE WHEN tmp.IsManualJournal = 1 THEN MJH.JournalNumber ELSE ReferenceName END,
				Referenceid = CASE WHEN tmp.IsManualJournal = 1 THEN MJD.ManualJournalHeaderId ELSE tmp.Referenceid END,
				LastMSLevel = CASE WHEN ISNULL(tmp.IsManualJournal, 0) = 1 THEN  MJD.LastMSLevel ELSE MJD.LastMSLevel END,
				AllMSlevels = CASE WHEN ISNULL(tmp.IsManualJournal, 0) = 1 THEN MJD.AllMSlevels ELSE MJD.AllMSlevels END						
	FROM #AccTrendTable tmp 
		JOIN dbo.ManualJournalHeader MJH WITH (NOLOCK) ON MJH.ManualJournalHeaderId = tmp.JournalBatchDetailId
		JOIN dbo.ManualJournalDetails MJD WITH (NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
	WHERE ISNULL(tmp.IsManualJournal, 0) = 1

	UPDATE #AccTrendTable 
			SET	AccountingPeriod = CASE WHEN ISNULL(BD.JournalTypeNumber, '') != '' THEN REPLACE(BD.AccountingPeriod,' - ','')  ELSE tmp.AccountingPeriod END,
				PeriodName = CASE WHEN ISNULL(BD.JournalTypeNumber, '') != '' THEN REPLACE(BD.AccountingPeriod,' - ','')  ELSE tmp.PeriodName END											
	FROM #AccTrendTable tmp 
		JOIN dbo.BatchDetails BD WITH (NOLOCK) ON BD.JournalTypeNumber = tmp.JournalNumber	
	WHERE BD.JournalBatchDetailId = tmp.JournalBatchDetailId

	SELECT LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel, AllMSlevels,
	CAST(CreditAmount as varchar) CreditAmount, CAST(DebitAmount as varchar) DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, 
	SUM(ISNULL(CreditAmount, 0) - ISNULL(DebitAmount, 0)) Amount , IsManualJournal ,IsStandAloneCM,ReferenceNumber
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
			(ISNULL(@ReferenceNumber,'') ='' OR ReferenceNumber LIKE '%' + @ReferenceNumber+'%'))
			)
	GROUP BY LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
	CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, IsManualJournal,IsStandAloneCM,ReferenceNumber 

	SELECT * INTO #GLRecordsResult 
	FROM #TempResults
	ORDER BY AccountingPeriodId, JournalNumber
	OFFSET @RecordFrom ROWS 
	FETCH NEXT @PageSize ROWS ONLY

	SET @TotalRecordsCount = (SELECT COUNT(JournalNumber) FROM #TempResults);
	
	;WITH cteRanked AS
	(
		SELECT Amount, LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
		CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, 
		ROW_NUMBER() OVER(ORDER BY LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
		CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate) rownum, IsManualJournal ,IsStandAloneCM,ReferenceNumber
		FROM #GLRecordsResult
	) 
	SELECT (SELECT SUM(Amount) FROM cteRanked c2 WHERE c2.rownum <= c1.rownum) AS Amount,
			LeafNodeId, UPPER(NodeName) AS NodeName, GLAccountId, (UPPER(GLAccountCode) + '-' + UPPER(GLAccountName)) AS GLAccount, UPPER(JournalNumber) AS JournalNumber, LastMSLevel,  AllMSlevels,
			CreditAmount, DebitAmount, AccountingPeriodId, UPPER(AccountingPeriod) AS AccountingPeriod, UPPER(PeriodName) AS PeriodName, ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, 
			Cast(EntryDate as datetime) AS EntryDate, IsManualJournal ,IsStandAloneCM,ReferenceNumber, @TotalRecordsCount as NumberOfItems
	FROM cteRanked c1 
	WHERE GLAccountId IS NOT NULL
	ORDER BY AccountingPeriodId, JournalNumber;

	END TRY  
	BEGIN CATCH  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_GetJournalEntriesDetailsByLeafNodeId_BalanceSheet_WithFilter' 
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