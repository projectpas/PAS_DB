/*************************************************************             
 ** File:   [USP_GetBalanceSheetReportData]             
 ** Author: Rajesh Gami  
 ** Description: This stored procedure is used to display balance sheet report data
 ** Purpose:           
 ** Date:31/08/2023
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date          Author  			Change Description             
 1		31/08/2023   Rajesh Gami			Created 
 2		20/09/2023   Hemnat Saliya			Updated LE MS Details 
 3		30/10/2023   Hemnat Saliya			Updated YTD Balance 
 4		13/12/2023   Moin Bloch			    Updated YTD Balance Issue in Balance Sheet 
 5		15/12/2023   Moin Bloch			    Added Static Income Statement ReportingStructureId Need TO Change  Line Number 53
 6      25/01/2024   Hemant Saliya	        Remove Manual Journal from Reports
 7      31/01/2024   Hemant Saliya	        Updated for Handle Balance Issues
 8      09/05/2024   Hemant Saliya	        Updated for Handle Static Income Statement ReportingStructureId 
 9		23/05/2024   Moin Bloch			    Set IncomeStatement Default ReportingStructureId 


**************************************************************/
  
CREATE   PROCEDURE [dbo].[USP_GetBalanceSheetReportData]
(
 @masterCompanyId BIGINT,  
 @ReportingStructureId BIGINT = NULL,  
 @managementStructureId BIGINT = NULL, 
 @StartAccountingPeriodId BIGINT = NULL,   
 @EndAccountingPeriodId BIGINT = NULL,
 @xmlFilter XML  
)

AS
BEGIN
  BEGIN TRY
		---Static Income Statement ReportingStructureId Need TO Change-----------------------------------------------------------
		DECLARE @IncomeStatementReportingStructureId BIGINT=0;   
		--SET @IncomeStatementReportingStructureId = CASE WHEN @MasterCompanyId = 1 THEN 8 WHEN @MasterCompanyId = 13 THEN 54 ELSE 1 END
		SET @IncomeStatementReportingStructureId = (SELECT [ReportingStructureId] FROM [dbo].[ReportingStructure] WITH(NOLOCK) WHERE [IsDefault] = 1 AND [MasterCompanyId] = @MasterCompanyId AND UPPER([ReportName])  = 'INCOME STATEMENT - STD FORMAT-V2' AND [IsVersionIncrease] = 0 AND [IsActive] = 1 AND [IsDeleted] = 0) 

		DECLARE @LeafNodeId AS BIGINT;
		DECLARE @AccountcalID AS BIGINT;
		DECLARE @LegalEntityId BIGINT; 
		DECLARE @FROMDATE DATETIME;
		DECLARE @TODATE DATETIME;  
		DECLARE @LEFROMDATE DATETIME;
		DECLARE @LETODATE DATETIME;  
		DECLARE @PostedBatchStatusId BIGINT;
		DECLARE @RevenueGLAccountTypeId AS BIGINT;
		DECLARE @ExpenseGLAccountTypeId AS BIGINT;
		DECLARE @AssetGLAccountTypeId AS BIGINT;
		DECLARE @LiabilitiesGLAccountTypeId AS BIGINT;
		DECLARE @EquityGLAccountTypeId AS BIGINT;
		DECLARE @BatchMSModuleId BIGINT; 
		DECLARE @YTDLeafNodeId BIGINT; 
		DECLARE @RELeafNodeId BIGINT; 
		DECLARE @IsDebugMode BIT; 

		SET @IsDebugMode = 0;

		IF(@EndAccountingPeriodId is null OR @EndAccountingPeriodId = 0)
		BEGIN
			SET @EndAccountingPeriodId = @StartAccountingPeriodId;
		END
		DECLARE @StartingRowNum BIGINT; 
		DECLARE @periodNameDistinct varchar(60);
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

		DECLARE 
		@MAXCalTempID INT = 0,@INITIALFROMDATE DATETIME,@INITIALENDDATE DATETIME,@CURRENTYEARFROMDATE DATETIME,@LASTYEARENDDATE DATETIME
		DECLARE @NAME VARCHAR(100) = NULL  
		DECLARE @FiscalYear INT = NULL  

		SELECT @level1=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1'   
			   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level1 END,  
  
			   @level2=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2'   
			   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level2 END,  
  
			   @level3=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3'   
			   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level3 END,  
  
			   @level4=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4'   
			   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level4 END,  
  
			   @level5=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5'   
			   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level5 END,  
  
			   @level6=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6'   
			   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level6 END,  
  
			   @level7=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7'   
			   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level7 END,  
  
			   @level8=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8'   
			   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level8 END,  
  
			   @level9=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9'   
			   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level9 END,  
  
			   @level10=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10'   
			   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 end  
  
		FROM @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby) 

		SELECT @LeafNodeId = LeafNodeid FROM [dbo].[LeafNode] WITH(NOLOCK) WHERE ReportingStructureId = @ReportingStructureId AND ParentId IS NULL AND [IsDeleted] = 0 
		
		SELECT @INITIALFROMDATE = MIN(FromDate) FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0  
		
		SELECT @NAME = NAME,@FiscalYear = [FiscalYear] FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [AccountingCalendarId] = @StartAccountingPeriodId AND [IsDeleted] = 0   

		SELECT @CURRENTYEARFROMDATE = MIN([FromDate]) FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [NAME] = @NAME AND [FiscalYear] = @FiscalYear;
		
		SELECT @LASTYEARENDDATE = @CURRENTYEARFROMDATE - 1;

		SELECT @FROMDATE = FromDate, @LegalEntityId = LegalEntityId FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId AND IsDeleted = 0  
		SELECT @TODATE = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @EndAccountingPeriodId AND IsDeleted = 0 
		SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
		SELECT @AssetGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Asset' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		SELECT @LiabilitiesGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Liabilities' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		SELECT @EquityGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Owners Equity' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		SELECT @RevenueGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Revenue' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		SELECT @ExpenseGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Expense' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		SELECT @YTDLeafNodeId = LeafNodeId FROM dbo.LeafNode LF WITH(NOLOCK) WHERE ReportingStructureId = @ReportingStructureId AND UPPER([Name]) = 'YTD INCOME'
		SELECT @RELeafNodeId = LeafNodeId FROM dbo.LeafNode LF WITH(NOLOCK) WHERE ReportingStructureId = @ReportingStructureId AND UPPER([Name]) = 'BEGINNING RETAIL EARNINGS'
		
		SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID
		--SET @ManualBatchMSModuleId = 73 -- MANUAL BATCH MS MODULE ID
	
		IF OBJECT_ID(N'tempdb..#AccPeriodTable') IS NOT NULL
		BEGIN
		  DROP TABLE #AccPeriodTable
		END

		CREATE TABLE #AccPeriodTable (
		  ID bigint NOT NULL IDENTITY (1, 1),
		  PeriodName VARCHAR(100) NULL,
		  FromDate DATETIME NULL,
		  ToDate DATETIME NULL,
		  FiscalYear INT NULL,
		  OrderNum INT NULL
		)

		INSERT INTO #AccPeriodTable (PeriodName, [OrderNum], FromDate, ToDate) 
		SELECT DISTINCT REPLACE(PeriodName,' - ',''), [Period] , MIN(FromDate), MAX(ToDate)
		FROM dbo.AccountingCalendar WITH(NOLOCK)
		WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND IsDeleted = 0 AND  
			 CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) --AND ISNULL(IsAdjustPeriod, 0) = 0 
		GROUP BY REPLACE(PeriodName,' - ',''), [Period]

		INSERT INTO #AccPeriodTable (PeriodName) 
		VALUES('Total')
		
		IF OBJECT_ID(N'tempdb..#AccPeriodTableFinal') IS NOT NULL
		BEGIN
		  DROP TABLE #AccPeriodTableFinal
		END

		CREATE TABLE #AccPeriodTableFinal (
		  ID bigint NOT NULL IDENTITY (1, 1),
		  AccountcalID BIGINT NULL,
		  PeriodName VARCHAR(100) NULL,
		  FromDate DATETIME NULL,
		  ToDate DATETIME NULL)

		INSERT INTO #AccPeriodTableFinal (AccountcalID, PeriodName, FromDate, ToDate) 
		SELECT AccountingCalendarId, REPLACE(PeriodName,' - ','') , @FROMDATE, ToDate
		FROM dbo.AccountingCalendar WITH(NOLOCK)
		WHERE LegalEntityId = @LegalEntityId and IsDeleted = 0 and  
			 CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) --AND ISNULL(IsAdjustPeriod, 0) = 0 

		INSERT INTO #AccPeriodTableFinal (AccountcalID, PeriodName) 
		VALUES(9999999,'Total')

		CREATE TABLE #TempTableYTDBalabce
		(
			rownumber BIGINT NOT NULL IDENTITY,
			PeriodNameDistinct VARCHAR(100) NULL,
			AccountingPeriodId BIGINT NULL,
			LeafNodeId BIGINT NULL,
			GlAccountId BIGINT NULL,
			GLAccountCode VARCHAR(50) NULL,
			GLAccountName VARCHAR(100) NULL,
			ManagementStructureId BIGINT NULL,
			LegalEntityId BIGINT NULL,
			CreditAmount DECIMAL(18,2),
			DebitAmount DECIMAL(18,2),
			Amount DECIMAL(18,2)
		)

		CREATE TABLE #TempTableBeginingRetailEarnings
		(
			rownumber BIGINT NOT NULL IDENTITY,
			PeriodNameDistinct VARCHAR(100) NULL,
			AccountingPeriodId BIGINT NULL,
			LeafNodeId BIGINT NULL,
			GlAccountId BIGINT NULL,
			GLAccountCode VARCHAR(50) NULL,
			GLAccountName VARCHAR(100) NULL,
			ManagementStructureId BIGINT NULL,
			LegalEntityId BIGINT NULL,
			CreditAmount DECIMAL(18,2),
			DebitAmount DECIMAL(18,2),
			Amount DECIMAL(18,2)
		)

		IF OBJECT_ID(N'tempdb..#AccPeriodTable_All') IS NOT NULL
		BEGIN
			 DROP TABLE #AccPeriodTable_All
		END
		  
		CREATE TABLE #AccPeriodTable_All (
			[ID] bigint NOT NULL IDENTITY (1, 1),
			[AccountcalID] BIGINT NULL,
			[PeriodName] VARCHAR(100) NULL,
			[FromDate] DATETIME NULL,
			[ToDate] DATETIME NULL,
			[FiscalYear] INT NULL,
		)	  

		IF OBJECT_ID(N'tempdb..#GLBalance') IS NOT NULL
		BEGIN
		  DROP TABLE #GLBalance
		END
    
		CREATE TABLE #GLBalance (
		  ID bigint NOT NULL IDENTITY (1, 1),
		  LeafNodeId BIGINT,
		  AccountingPeriodId BIGINT NULL,
		  CreaditAmount DECIMAL(18, 2) NULL,
		  DebitAmount DECIMAL(18, 2) NULL,
		  Amount DECIMAL(18, 2) NULL,
		  RowNum INT NULL,
		  PeriodNameDistinct VARCHAR(100)
		)

		IF OBJECT_ID(N'tempdb..#AccBalanceSheetTable') IS NOT NULL
		BEGIN
		  DROP TABLE #AccBalanceSheetTable
		END

		CREATE TABLE #AccBalanceSheetTable (
		  ID bigint NOT NULL IDENTITY (1, 1),
		  LeafNodeId bigint,
		  NodeName varchar(500),
		  Amount decimal(18, 2),
		  AccountingPeriodId bigint,
		  AccountingPeriod VARCHAR(100) null,
		  IsBlankHeader bit DEFAULT 0,
		  IsTotlaLine bit DEFAULT 0,
		   PeriodNameDistinct varchar(100)
		)

		DECLARE @SQLQuery varchar(max) = '
		IF OBJECT_ID(N''tempdb..##AccBalanceSheetTablePivot'') IS NOT NULL
		BEGIN
		  DROP TABLE ##AccBalanceSheetTablePivot
		END

		CREATE TABLE ##AccBalanceSheetTablePivot (
		  ID bigint NOT NULL IDENTITY (1, 1),     
		  leafNodeId BIGINT,
		  name VARCHAR(500),    
		  parentId BIGINT,
		  isLeafNode BIT,
		  masterCompanyId INT,
		  reportingStructureId BIGINT,
		  isPositive BIT,
		  sequenceNumber INT,
		  parentNodeName VARCHAR(500),
		  IsBlankHeader bit DEFAULT 0,
		  IsTotlaLine bit DEFAULT 0, ' + Stuff((SELECT ','+ QUOTENAME(PeriodName) + ' DECIMAL(18,2) NULL'
															   From #AccPeriodTableFinal
															   --Group By PeriodName
															   Order By AccountcalID  
															   For XML Path('')),1,1,'') + ')'

		EXEC(@SQLQuery);  

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
		  Amount decimal(18, 2) NULL,
		  TotalAmount decimal(18, 2) NULL,
		  ChildCount int NULL,
		  IsProcess bit DEFAULT (0),
		  PeriodNameDistinct VARCHAR(100) NULL
		)

		IF(@IsDebugMode = 1)
		BEGIN
			SELECT * FROM #AccPeriodTable
		END

		SELECT @MAXCalTempID = MAX(ID) fROM #AccPeriodTable
		WHILE(@MAXCalTempID > 0)
		BEGIN
			
			SELECT @LEFROMDATE = FromDate, @LETODATE = ToDate, @periodNameDistinct = PeriodName FROM #AccPeriodTable where ID = @MAXCalTempID

			DELETE FROM #AccPeriodTable_All

			INSERT INTO #AccPeriodTable_All (AccountcalID, PeriodName, FromDate, ToDate, FiscalYear) 
			SELECT AccountingCalendarId, REPLACE(PeriodName,' - ',' ') ,FromDate,ToDate, FiscalYear
			FROM dbo.AccountingCalendar WITH(NOLOCK)
			WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND IsDeleted = 0 AND  
				CAST(Fromdate AS DATE) >= CAST(@INITIALFROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@LETODATE AS DATE)  --AND ISNULL(IsAdjustPeriod, 0) = 0 
			ORDER BY FiscalYear, [Period]

			--SELECT * FROM #AccPeriodTable_All
					
			INSERT INTO #GLBalance (LeafNodeId,  DebitAmount, CreaditAmount,  Amount, PeriodNameDistinct)
			(SELECT DISTINCT LF.LeafNodeId , 
							CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END 'DebitAmount',
							CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END 'CreditAmount',
							CASE WHEN GL.GLAccountTypeId = @AssetGLAccountTypeId THEN
								(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END) - 
								(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) 
							ELSE
								(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) -
								(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END)
							END AS AMONUT,
							@periodNameDistinct
			FROM dbo.CommonBatchDetails CMD WITH (NOLOCK)
				INNER JOIN dbo.BatchDetails BD WITH (NOLOCK) ON CMD.JournalBatchDetailId = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
				INNER JOIN dbo.BatchHeader B WITH (NOLOCK) ON BD.JournalBatchHeaderId = B.JournalBatchHeaderId 
				INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = CMD.CommonJournalBatchDetailId AND ModuleId = @BatchMSModuleId
				INNER JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON CMD.GlAccountId = GLM.GLAccountId
				INNER JOIN dbo.GLAccount GL WITH (NOLOCK) ON GL.GlAccountId = GLM.GLAccountId AND GL.GLAccountTypeId IN (@AssetGLAccountTypeId, @LiabilitiesGLAccountTypeId,@EquityGLAccountTypeId) 
				INNER JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0 AND ISNULL(LF.ReportingStructureId, 0) = @ReportingStructureId 
			WHERE ISNULL(CMD.IsDeleted,0) = 0  AND ISNULL(BD.IsDeleted,0) = 0 AND  ISNULL(GLM.IsDeleted,0) = 0 AND CMD.MasterCompanyId = @MasterCompanyId	
					AND BD.AccountingPeriodId IN (SELECT AccountcalID FROM #AccPeriodTable_All) AND ISNULL(B.IsDeleted,0) = 0
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
			GROUP BY LF.LeafNodeId , GLM.IsPositive, GL.GLAccountTypeId)

			INSERT INTO #TempTableYTDBalabce(GlAccountId,GLAccountCode,GLAccountName,ManagementStructureId,DebitAmount,CreditAmount, PeriodNameDistinct, LeafNodeId)
			SELECT DISTINCT CB.GlAccountId,GL.AccountCode,GL.AccountName,
				CB.ManagementStructureId, 
				CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CB.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CB.DebitAmount, 0)), 0) * -1 END 'DebitAmount',
				CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CB.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CB.CreditAmount, 0)), 0) * -1 END 'CreditAmount',				
				@periodNameDistinct,
				@YTDLeafNodeId
			FROM dbo.CommonBatchDetails CB WITH(NOLOCK)
				INNER JOIN dbo.BatchDetails BD WITH(NOLOCK) ON BD.JournalBatchDetailId = CB.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
				INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON CB.GlAccountId = GL.GLAccountId AND  GL.GLAccountTypeId IN (@RevenueGLAccountTypeId, @ExpenseGLAccountTypeId)
				INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH(NOLOCK) ON CB.CommonJournalBatchDetailId = MSD.ReferenceId AND ModuleId = @BatchMSModuleId
				LEFT JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON CB.GlAccountId = GLM.GLAccountId
				INNER JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0 AND ISNULL(ReportingStructureId, 0) = @IncomeStatementReportingStructureId 
			WHERE CB.IsDeleted = 0 AND CB.MasterCompanyId = @MasterCompanyId AND BD.IsDeleted = 0
				AND BD.AccountingPeriodId IN (SELECT [AccountcalID] FROM #AccPeriodTable_All WHERE [FiscalYear] = @FiscalYear)
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
			GROUP BY CB.GlAccountId,GL.AccountCode,GL.AccountName,CB.ManagementStructureId ,GLM.IsPositive

			--SELECT * FROM #GLBalance
			--SELECT * FROM #TempTableYTDBalabce
			--SELECT * FROM #AccPeriodTable_All

			INSERT INTO #TempTableBeginingRetailEarnings(GlAccountId,GLAccountCode,GLAccountName,ManagementStructureId,DebitAmount,CreditAmount, PeriodNameDistinct, LeafNodeId)
			SELECT DISTINCT CB.GlAccountId,GL.AccountCode,GL.AccountName,
				CB.ManagementStructureId, 				
				CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CB.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CB.DebitAmount, 0)), 0) * -1 END 'DebitAmount',
				CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CB.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CB.CreditAmount, 0)), 0) * -1 END 'CreditAmount',				
				@periodNameDistinct,
				@RELeafNodeId
			FROM dbo.CommonBatchDetails CB WITH(NOLOCK)
				INNER JOIN dbo.BatchDetails BD WITH(NOLOCK) ON BD.JournalBatchDetailId = CB.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
				INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON CB.GlAccountId = GL.GLAccountId AND  GL.GLAccountTypeId IN (@RevenueGLAccountTypeId, @ExpenseGLAccountTypeId)
				INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH(NOLOCK) ON CB.CommonJournalBatchDetailId = MSD.ReferenceId AND ModuleId = @BatchMSModuleId
				 LEFT JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON CB.GlAccountId = GLM.GLAccountId
				INNER JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0 AND ISNULL(ReportingStructureId, 0) = @IncomeStatementReportingStructureId 
			WHERE CB.IsDeleted = 0 AND CB.MasterCompanyId = @MasterCompanyId AND BD.IsDeleted = 0
				AND BD.AccountingPeriodId IN (SELECT [AccountcalID] FROM #AccPeriodTable_All WHERE [FiscalYear] < @FiscalYear)
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
			GROUP BY CB.GlAccountId,GL.AccountCode,GL.AccountName,CB.ManagementStructureId ,GLM.IsPositive

			--Select '#TempTableBeginingRetailEarnings'			
			--Select * FROM #TempTableBeginingRetailEarnings
			--SELECT * FROM #TempTableYTDBalabce
					
			SET @MAXCalTempID = @MAXCalTempID - 1;
		END
		
		UPDATE #GLBalance SET AccountingPeriodId = AccountcalID FROM #GLBalance GLB JOIN #AccPeriodTableFinal APF ON GLB.PeriodNameDistinct = APF.PeriodName
		UPDATE #TempTableYTDBalabce SET AccountingPeriodId = AccountcalID FROM #TempTableYTDBalabce YTD JOIN #AccPeriodTableFinal APF ON YTD.PeriodNameDistinct = APF.PeriodName
		UPDATE #TempTableBeginingRetailEarnings SET AccountingPeriodId = AccountcalID FROM #TempTableBeginingRetailEarnings YTD JOIN #AccPeriodTableFinal APF ON YTD.PeriodNameDistinct = APF.PeriodName
		
		UPDATE #TempTableYTDBalabce
		SET Amount = GropBal.TotalAmount	
		FROM(
			SELECT (SUM(ISNULL(CreditAmount,0)) - SUM(ISNULL(DebitAmount,0))) AS TotalAmount, AccountingPeriodId   
			FROM #TempTableYTDBalabce 
			GROUP BY PeriodNameDistinct, AccountingPeriodId
		) GropBal WHERE GropBal.AccountingPeriodId = #TempTableYTDBalabce.AccountingPeriodId 

		UPDATE #TempTableBeginingRetailEarnings
		SET Amount = GropBal.TotalAmount	
		FROM(
			SELECT (SUM(ISNULL(CreditAmount,0)) - SUM(ISNULL(DebitAmount,0))) AS TotalAmount, AccountingPeriodId   
			FROM #TempTableBeginingRetailEarnings 
			GROUP BY PeriodNameDistinct, AccountingPeriodId
		) GropBal WHERE GropBal.AccountingPeriodId = #TempTableBeginingRetailEarnings.AccountingPeriodId 

		--Select * FROM #TempTableBeginingRetailEarnings

		IF(@IsDebugMode = 1)
		BEGIN
			SELECT * FROM #GLBalance
			--SELECT * FROm #TempTable
			SELECT * FROM #TempTableYTDBalabce
			SELECT * FROM #TempTableBeginingRetailEarnings
		END
		
		DECLARE @LID AS int = 0;
		DECLARE @IsFristRow AS bit = 1;
		DECLARE @LCOUNT AS int = 0;

		SELECT @LCOUNT = MAX(ID) fROM #AccPeriodTableFinal

		WHILE(@LCOUNT > 0)
		BEGIN
		   SELECT  @AccountcalID = AccountcalID, @periodNameDistinct = PeriodName FROM #AccPeriodTableFinal where ID = @LCOUNT

		   INSERT INTO #TempTable (LeafNodeId, [Name], IsPositive, ParentId, IsProcess,AccountingPeriodId,PeriodNameDistinct)
							  SELECT
								LeafNodeId,[Name],IsPositive,ParentId,0,@AccountcalID,@periodNameDistinct
								  FROM dbo.LeafNode
								  WHERE LeafNodeId = @LeafNodeId
									  AND IsDeleted = 0
									  AND ReportingStructureId = @ReportingStructureId

			DECLARE @CID AS int = 0;
			DECLARE @CLID AS int = 0;
			SELECT TOP 1 @CID = ID, @CLID = LeafNodeId
						FROM #TempTable
								WHERE IsProcess = 0 and PeriodNameDistinct = @periodNameDistinct
								ORDER BY ID

			WHILE (@CLID > 0)
			BEGIN
				INSERT INTO #TempTable (LeafNodeId, [Name], IsPositive, ParentId, IsProcess,AccountingPeriodId,PeriodNameDistinct)
									SELECT  LeafNodeId, [Name], IsPositive,  @CLID, 0,@AccountcalID,@periodNameDistinct
											FROM dbo.LeafNode
												  WHERE ParentId = @CLID
													AND IsDeleted = 0
													AND ReportingStructureId = @ReportingStructureId ORDER BY SequenceNumber DESC

				SET @CLID = 0;
				  UPDATE #TempTable SET IsProcess = 1 WHERE ID = @CID AND PeriodNameDistinct = @periodNameDistinct ---AND AccountingPeriodId = @AccountcalID
				IF EXISTS (SELECT TOP 1 ID FROM #TempTable  WHERE IsProcess = 0 AND PeriodNameDistinct = @periodNameDistinct )--AND AccountingPeriodId = @AccountcalID
				 BEGIN
						SELECT TOP 1 @CID = ID, @CLID = LeafNodeId
									FROM #TempTable
											WHERE IsProcess = 0
											AND PeriodNameDistinct = @periodNameDistinct 
												   --AND AccountingPeriodId = @AccountcalID
											ORDER BY ID
				 END
			END				
			--Select @periodNameDistinct
			--Select * from #TempTable

			UPDATE #TempTable SET Amount = tmpCal.Amount
			FROM(SELECT SUM(ISNULL(GL.Amount, 0)) AS Amount, T.LeafNodeId, T.PeriodNameDistinct
				FROM #TempTable T 
			JOIN #GLBalance GL ON T.PeriodNameDistinct = @periodNameDistinct AND T.LeafNodeId = GL.LeafNodeId AND T.PeriodNameDistinct = GL.PeriodNameDistinct --AND T.AccountingPeriodId = GL.AccountingPeriodId
			GROUP BY T.LeafNodeId, T.PeriodNameDistinct
			)tmpCal WHERE tmpCal.PeriodNameDistinct = #TempTable.PeriodNameDistinct AND tmpCal.LeafNodeId = #TempTable.LeafNodeId AND tmpCal.PeriodNameDistinct = @PeriodNameDistinct 

			--Select * from #TempTable

			UPDATE #TempTable SET Amount = (ISNULL(GL.Amount, 0))						
			FROM #TempTable T 
			JOIN #TempTableYTDBalabce GL ON T.PeriodNameDistinct = @periodNameDistinct 
			AND T.LeafNodeId = GL.LeafNodeId 
			AND T.PeriodNameDistinct = GL.PeriodNameDistinct

			--Select * from #TempTable

			UPDATE #TempTable SET Amount = (ISNULL(GL.Amount, 0))						
			FROM #TempTable T 
			JOIN #TempTableBeginingRetailEarnings GL ON T.PeriodNameDistinct = @periodNameDistinct 
			AND T.LeafNodeId = GL.LeafNodeId 
			AND T.PeriodNameDistinct = GL.PeriodNameDistinct
			
			--Select * from #TempTable
	
			 UPDATE #TempTable
			   SET ChildCount = ISNULL((SELECT COUNT(ISNULL(T.Amount, 0))
											   FROM #TempTable T
													WHERE T.ParentId = T1.LeafNodeId 
													AND T.PeriodNameDistinct = @PeriodNameDistinct)
													--AND T.AccountingPeriodId = @AccountcalID)
													, 0),
					Amount = CASE WHEN T1.IsPositive = 1 THEN Amount
								  ELSE ISNULL(Amount, 0) * -1
							 END
					FROM #TempTable T1 WHERE  T1.PeriodNameDistinct = @PeriodNameDistinct --T1.AccountingPeriodId = @AccountcalID
		
			 UPDATE #TempTable SET IsProcess = 0  WHERE PeriodNameDistinct = @PeriodNameDistinct --AccountingPeriodId = @AccountcalID
			 --Select * from #TempTable

			 SET @CID = 0;
			 SET @CLID = 0;
			 SELECT TOP 1 @CID = ID
						FROM #TempTable
							WHERE IsProcess = 0 AND PeriodNameDistinct = @PeriodNameDistinct--AND AccountingPeriodId = @AccountcalID
								  ORDER BY ID DESC

			WHILE (@CID > 0)
				BEGIN
				SELECT TOP 1 @CLID = LeafNodeId
						FROM #TempTable
							WHERE ID = @CID AND PeriodNameDistinct = @PeriodNameDistinct -- AND AccountingPeriodId = @AccountcalID

				UPDATE #TempTable
						SET Amount =  CASE  WHEN IsPositive = 1 THEN 
												  (SELECT SUM(ISNULL(T.Amount, 0)) FROM #TempTable T  WHERE T.ParentId = @CLID  AND T.PeriodNameDistinct = @PeriodNameDistinct) -- T.AccountingPeriodId = @AccountcalID)
									  ELSE ISNULL((SELECT SUM(ISNULL(T.Amount, 0))FROM #TempTable T WHERE T.ParentId = @CLID AND T.PeriodNameDistinct = @PeriodNameDistinct) , 0) * -1 -- AND T.AccountingPeriodId = @AccountcalID
									  END
					 WHERE ID = @CID
						   AND ChildCount > 0 AND PeriodNameDistinct = @PeriodNameDistinct -- AccountingPeriodId = @AccountcalID
				UPDATE #TempTable  SET IsProcess = 1 WHERE ID = @CID AND PeriodNameDistinct = @PeriodNameDistinct -- AccountingPeriodId = @AccountcalID

				  SET @CID = 0;
				  SET @CLID = 0;
				  IF EXISTS (SELECT TOP 1 ID FROM #TempTable WHERE IsProcess = 0 AND PeriodNameDistinct = @PeriodNameDistinct) -- AND AccountingPeriodId = @AccountcalID)
				  BEGIN
						SELECT TOP 1 @CID = ID
							   FROM #TempTable
									WHERE IsProcess = 0
										  AND PeriodNameDistinct = @PeriodNameDistinct
										  --AND AccountingPeriodId = @AccountcalID
										   ORDER BY ID DESC
			   END
			END
		
			UPDATE #TempTable SET IsProcess = 0,
						   TotalAmount = (SELECT SUM(ISNULL(T.Amount,0)) FROM #TempTable T WHERE T.ParentId = T1.LeafNodeId AND T.PeriodNameDistinct = @PeriodNameDistinct )--AND T.AccountingPeriodId = @AccountcalID)	 
						  FROM #TempTable T1 
						  WHERE T1.PeriodNameDistinct = @PeriodNameDistinct--T1.AccountingPeriodId = @AccountcalID

			  SET @CID = 0;
			  SET @CLID = 0;
			  SELECT TOP 1 @CID = ID
					   FROM #TempTable
							 WHERE IsProcess = 0
								  AND PeriodNameDistinct = @PeriodNameDistinct
								  -- AND AccountingPeriodId = @AccountcalID
							 ORDER BY ID DESC
			WHILE (@CID > 0)
			BEGIN

			  SELECT TOP 1 @CLID = ParentId
						FROM #TempTable WHERE ID = @CID AND PeriodNameDistinct = @PeriodNameDistinct --AND AccountingPeriodId = @AccountcalID

			  IF NOT EXISTS (SELECT TOP 1 ID FROM #AccBalanceSheetTable WHERE LeafNodeId = @CLID AND IsBlankHeader = 1 AND PeriodNameDistinct = @PeriodNameDistinct)
			  BEGIN
					INSERT INTO #AccBalanceSheetTable (LeafNodeId, NodeName, Amount, AccountingPeriodId, IsBlankHeader,PeriodNameDistinct)
							  SELECT TOP 1 LeafNodeId, Name + ' :',NULL,@AccountcalID, 1,@PeriodNameDistinct FROM #TempTable 
											 WHERE LeafNodeId = @CLID
												  AND ChildCount > 0 AND PeriodNameDistinct = @PeriodNameDistinct --AND  AccountingPeriodId = @AccountcalID
					IF(@IsFristRow = 1)
					BEGIN
					INSERT INTO ##AccBalanceSheetTablePivot(Name,IsBlankHeader, LeafNodeId, ParentId)
							   SELECT TOP 1  Name + ' :', 1, LeafNodeId, ParentId FROM #TempTable 
											 WHERE LeafNodeId = @CLID
												  AND ChildCount > 0 AND   PeriodNameDistinct = @PeriodNameDistinct  --AccountingPeriodId = @AccountcalID
					END
			  END

			  INSERT INTO #AccBalanceSheetTable (LeafNodeId, NodeName, Amount, AccountingPeriodId, IsBlankHeader, PeriodNameDistinct )
				SELECT LeafNodeId, Name, Amount, @AccountcalID, 0, @PeriodNameDistinct 
						 FROM #TempTable
							   WHERE ID = @CID AND  PeriodNameDistinct = @PeriodNameDistinct  --AccountingPeriodId = @AccountcalID  --                    AND ChildCount = 0
			  IF(@IsFristRow = 1)
						BEGIN
						INSERT INTO ##AccBalanceSheetTablePivot(Name,IsBlankHeader, LeafNodeId, ParentId)
									SELECT  Name, 0, LeafNodeId, ParentId
										FROM #TempTable
												WHERE ID = @CID AND  PeriodNameDistinct = @PeriodNameDistinct -- AccountingPeriodId = @AccountcalID  --                    AND ChildCount = 0
						END

			  UPDATE #TempTable
					  SET IsProcess = 1
						 WHERE ID = @CID AND  PeriodNameDistinct = @PeriodNameDistinct  -- AccountingPeriodId = @AccountcalID

			  IF NOT EXISTS (SELECT TOP 1 ID FROM #TempTable WHERE ParentId = @CLID AND IsProcess = 0 AND PeriodNameDistinct = @PeriodNameDistinct ) -- AccountingPeriodId = @AccountcalID
			  BEGIN
				IF NOT EXISTS (SELECT TOP 1 ID FROM #AccBalanceSheetTable WHERE LeafNodeId = @CLID  AND IsTotlaLine = 1 AND PeriodNameDistinct = @PeriodNameDistinct)  --AccountingPeriodId = @AccountcalID
				BEGIN
					  INSERT INTO #AccBalanceSheetTable (LeafNodeId, NodeName, Amount, AccountingPeriodId, IsBlankHeader, IsTotlaLine,PeriodNameDistinct )
									SELECT  LeafNodeId,'Total - ' + Name, TotalAmount,@AccountcalID, 0, 1, @PeriodNameDistinct
											FROM #TempTable
												WHERE LeafNodeId = @CLID  AND ChildCount > 0 AND PeriodNameDistinct = @PeriodNameDistinct --AccountingPeriodId = @AccountcalID
					 IF(@IsFristRow = 1)
						BEGIN
						INSERT INTO ##AccBalanceSheetTablePivot(Name,IsBlankHeader,IsTotlaLine, LeafNodeId, ParentId)
								   SELECT TOP 1  'Total - ' + Name,0, 1, LeafNodeId, LeafNodeId
												 FROM #TempTable
													 WHERE LeafNodeId = @CLID  AND ChildCount > 0  AND PeriodNameDistinct = @PeriodNameDistinct --  AccountingPeriodId = @AccountcalID

						END
				END
			  END
			  SET @CID = 0;
			  SET @CLID = 0;

			  IF EXISTS (SELECT TOP 1 ID  FROM #TempTable WHERE IsProcess = 0 AND PeriodNameDistinct = @PeriodNameDistinct ) --AccountingPeriodId = @AccountcalID
			  BEGIN
				SELECT TOP 1  @CID = ID
						 FROM #TempTable
							 WHERE IsProcess = 0
							 AND  PeriodNameDistinct = @PeriodNameDistinct
							 --AND AccountingPeriodId = @AccountcalID
								ORDER BY ID DESC
			  END

			END

			-----Final Loop
			SET @IsFristRow = 0
			SET @LCOUNT = @LCOUNT -1
		END

		IF(@IsDebugMode = 1)
		BEGIN
			SELECT * FROM ##AccBalanceSheetTablePivot
			SELECT * FROm #TempTable
			SELECT * FROM #AccBalanceSheetTable
		END

		--SELECT * FROM #TempTable --where LeafNodeId = 153
		--SELECT * FROM ##AccBalanceSheetTablePivot  where LeafNodeId = 153
		--SELECT * FROM #AccBalanceSheetTable where LeafNodeId = 153
    
		UPDATE #TempTable SET AccountingPeriodName = REPLACE(AP.PeriodName,' - ',' ')  
		FROM #TempTable tmp JOIN dbo.AccountingCalendar AP WITH(NOLOCK) ON tmp.AccountingPeriodId = AP.AccountingCalendarId

		UPDATE #AccBalanceSheetTable SET AccountingPeriod = CASE WHEN ISNULL(AP.PeriodName, '') != '' THEN REPLACE(AP.PeriodName ,' - ',' ')  ELSE 'Total' END
		FROM #AccBalanceSheetTable tmp LEFT JOIN dbo.AccountingCalendar AP WITH(NOLOCK) ON tmp.AccountingPeriodId = AP.AccountingCalendarId
	
		UPDATE #AccBalanceSheetTable 
		SET Amount = Groptoal.TotalAmt	
		FROM(
			SELECT SUM(Amount) AS TotalAmt, NodeName FROM #AccBalanceSheetTable act WHERE AccountingPeriod != 'Total' GROUP BY NodeName
		) Groptoal WHERE Groptoal.NodeName = #AccBalanceSheetTable.NodeName AND AccountingPeriod = 'Total'
	
		DECLARE @COUNT AS INT;
		DECLARE @COUNTMAX AS INT
		SELECT @COUNTMAX = MAX(ID), @COUNT = MIN(ID) FROM #AccPeriodTableFinal

		PRINT '#AccPeriodTableFinal'
		WHILE (@COUNT <= @COUNTMAX)
		BEGIN
			DECLARE @APName AS VARCHAR(100);
			DECLARE @APId AS BIGINT;
			SELECT @APName = PeriodName, @APId = AccountcalID FROM #AccPeriodTableFinal WHERE ID = @COUNT --GROUP BY PeriodName

			DECLARE @SQLUpdateQuery varchar(max) = 'UPDATE ##AccBalanceSheetTablePivot SET [' + CAST(@APName AS VARCHAR(100)) +'] = (SELECT SUM(Amount) FROM #AccBalanceSheetTable WHERE NodeName = AP.Name AND IsBlankHeader = AP.IsBlankHeader and PeriodNameDistinct = ''' + @APName + ''' ) FROM ##AccBalanceSheetTablePivot AP'
		
			EXEC(@SQLUpdateQuery)  

			SET @COUNT = @COUNT + 1

		END

		DECLARE @CreateTableSQLQuery varchar(max) = '
		IF OBJECT_ID(N''tempdb..##tmpFinalReturnTable'') IS NOT NULL
		BEGIN
		  DROP TABLE ##tmpFinalReturnTable
		END

		CREATE TABLE ##tmpFinalReturnTable (
		  ID bigint NOT NULL IDENTITY (1, 1),
		  leafNodeId BIGINT,
		  [name] VARCHAR(500),    
		  parentId BIGINT,
		  isLeafNode BIT,
		  masterCompanyId INT,
		  reportingStructureId BIGINT,
		  isPositive BIT,
		  sequenceNumber INT,
		  parentNodeName VARCHAR(500),
		  isBlankHeader bit DEFAULT 0, ' 
		  + Stuff((SELECT ','+ QUOTENAME(PeriodName) 
		  + ' DECIMAL(18,2) NULL'
			From #AccPeriodTableFinal
			--GROUP BY PeriodName
			Order By AccountcalID  
			For XML Path('')),1,1,'') + ')'

		EXEC(@CreateTableSQLQuery);  

		INSERT INTO ##tmpFinalReturnTable(leafNodeId, [name], parentId, parentNodeName, isLeafNode, masterCompanyId, reportingStructureId, isPositive, sequenceNumber)
		SELECT	LF.LeafNodeId, LF.Name, LF.ParentId, LFP.Name, LF.IsLeafNode, 
				 LF.MasterCompanyId, LF.ReportingStructureId, LF.IsPositive, LF.SequenceNumber
		FROM dbo.LeafNode LF WITH(NOLOCK) 
			LEFT JOIN dbo.GLAccountLeafNodeMapping GLM WITH(NOLOCK) ON LF.LeafNodeId = GLM.LeafNodeId
			LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON GL.GLAccountId = GLM.GLAccountId
			LEFT JOIN dbo.LeafNode LFP WITH(NOLOCK) ON LF.ParentId = LFP.LeafNodeId
		WHERE LF.IsActive = 1 AND LF.IsDeleted = 0 AND LF.MasterCompanyId = @masterCompanyId AND LF.ReportingStructureId =  @ReportingStructureId
		GROUP BY LF.LeafNodeId, LF.Name,LF.ParentId, LFP.Name, LF.IsLeafNode, 
				 LF.MasterCompanyId, LF.ReportingStructureId, LF.IsPositive, LF.SequenceNumber
		ORDER BY ParentId, LF.SequenceNumber
	
		DECLARE @COUNT1 AS INT;
		DECLARE @COUNTMAX1 AS INT
		SELECT @COUNTMAX1 = MAX(ID), @COUNT1 = MIN(ID) FROM #AccPeriodTableFinal --GROUP BY PeriodName
		--SELECT * FROM ##tmpFinalReturnTable
		WHILE (@COUNT1 <= @COUNTMAX1)
		BEGIN
			print 'Step 1'
			DECLARE @APName1 AS VARCHAR(100);
			DECLARE @APId1 AS BIGINT;
			SELECT @APName1 = PeriodName, @APId1 = AccountcalID FROM #AccPeriodTableFinal WHERE ID = @COUNT1 

			DECLARE @SQLFinalUpdateQuery varchar(max) = 'UPDATE T1 SET T1.[' + CAST(@APName1 AS VARCHAR(100)) +'] = T2.[' + CAST(@APName1 AS VARCHAR(100)) +'] FROM ##tmpFinalReturnTable T1 JOIN ##AccBalanceSheetTablePivot T2 ON T1.leafNodeId = T2.leafNodeId AND T1.parentId = T2.parentId AND T1.[name] = T2.[name]'
		
			PRINT (@SQLFinalUpdateQuery)
			EXEC(@SQLFinalUpdateQuery)  

			SET @COUNT1 = @COUNT1 + 1
		END
		--SELECT * FROM ##tmpFinalReturnTable
		UPDATE T1 
				SET T1.IsLeafNode = T2.IsLeafNode, T1.MasterCompanyId = T2.MasterCompanyId, 
					T1.ReportingStructureId = T2.ReportingStructureId, T1.sequenceNumber = T2.sequenceNumber,
					T1.IsPositive = T2.IsPositive, T1.parentNodeName = T2.parentNodeName
		FROM ##AccBalanceSheetTablePivot T1 
		JOIN ##tmpFinalReturnTable T2 ON T1.leafNodeId = T2.leafNodeId AND T1.parentId = T2.parentId AND T1.[name] = T2.[name]

		UPDATE T1 
				SET T1.IsLeafNode = T2.IsLeafNode, T1.MasterCompanyId = T2.MasterCompanyId, 
					T1.ReportingStructureId = T2.ReportingStructureId, T1.sequenceNumber = T2.sequenceNumber,
					T1.IsPositive = T2.IsPositive, T1.parentNodeName = T2.parentNodeName
		FROM ##AccBalanceSheetTablePivot T1 
		JOIN ##tmpFinalReturnTable T2 ON T1.leafNodeId = T2.leafNodeId AND T1.parentId = T2.parentId --AND T1.[name] = T2.[name]
		WHERE T1.parentNodeName IS NULL

		UPDATE  ##AccBalanceSheetTablePivot SET leafNodeId = NULL WHERE IsBlankHeader = 1 OR IsTotlaLine = 1
		--SELECT * FROM ##AccBalanceSheetTablePivot
		--SELECT * FROM ##tmpFinalReturnTable
		DECLARE @COUNT2 AS INT;
		DECLARE @COUNTMAX2 AS INT
		DECLARE @MAXLeafNodeId AS INT
		SELECT @COUNTMAX2 = MAX(ID), @COUNT2 = MIN(ID), @MAXLeafNodeId = MAX(leafNodeId)  FROM ##AccBalanceSheetTablePivot

		WHILE (@COUNT2 <= @COUNTMAX2)
		BEGIN
			print 'Step 2'
			SET @MAXLeafNodeId = @MAXLeafNodeId + 1

			UPDATE ##AccBalanceSheetTablePivot SET leafNodeId = @MAXLeafNodeId WHERE ID = @COUNT2 AND leafNodeId IS NULL AND (IsBlankHeader = 1 OR IsTotlaLine = 1)

			SET @COUNT2 = @COUNT2 + 1
		
		END

		DECLARE @COUNT3 AS INT;
		DECLARE @COUNTMAX3 AS INT
		SELECT @COUNTMAX3 = MAX(ID), @COUNT3 = MIN(ID) FROM ##AccBalanceSheetTablePivot

		WHILE (@COUNT3 <= @COUNTMAX3)
		BEGIN
			print 'Step 3'
			DECLARE @LeafNodeId3 AS BIGINT;
			SELECT @LeafNodeId3 = leafNodeId FROM ##AccBalanceSheetTablePivot WHERE ID = @COUNT3

			IF((SELECT COUNT(1) FROM ##AccBalanceSheetTablePivot WHERE ISNULL(parentId, 0) IN (ISNULL(@LeafNodeId3, 0))) > 0 )
			BEGIN
				DECLARE @COUNT4 AS INT;
				DECLARE @COUNTMAX4 AS INT
				SELECT @COUNTMAX4 = MAX(ID), @COUNT4 = MIN(ID) FROM #AccPeriodTable

				WHILE (@COUNT4 <= @COUNTMAX4)
				BEGIN
					DECLARE @APName4 AS VARCHAR(100);
					SELECT @APName4 = PeriodName FROM #AccPeriodTable WHERE ID = @COUNT4 --GROUP BY PeriodName

					IF EXISTS (SELECT 1 FROM tempdb.sys.columns WHERE [object_id] = object_id('tempdb..##AccBalanceSheetTablePivot') AND NAME =''+ CAST(@APName4 AS VARCHAR(100)) +'')
					BEGIN
						DECLARE @SQLQueryUpdateHeader varchar(max) = 'UPDATE ##AccBalanceSheetTablePivot SET [' + CAST(@APName4 AS VARCHAR(100)) +'] = NULL WHERE leafNodeId = ' + CAST(@LeafNodeId3 AS VARCHAR(100)) +'' 
						--PRINT (@SQLQueryUpdateHeader)
						EXEC(@SQLQueryUpdateHeader)  
					END

					SET @COUNT4 = @COUNT4 + 1
				END
			END

			SET @COUNT3 = @COUNT3 + 1
		
		END

		UPDATE ##AccBalanceSheetTablePivot SET [name] = REPLACE([name],'Total - ','') 

		SELECT * FROM ##AccBalanceSheetTablePivot WHERE IsBlankHeader <> 1 
		 AND leafNodeId <> (SELECT MAX(leafNodeId) FROM ##AccBalanceSheetTablePivot WHERE IsBlankHeader != 1)
		 ORDER BY parentId 		 		

  END TRY
  BEGIN CATCH
   SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = 'USP_GetBalanceSheetReportData',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''',
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END