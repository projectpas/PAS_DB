/*************************************************************             
 ** File:   [USP_GetIncomeStatementActualTrendReport]             
 ** Author: Hemant Saliya  
 ** Description: This stored procedure is used to display income statement(actual) report data
 ** Purpose:           
 ** Date:10/07/2023
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  			Change Description             
 1    10/07/2023   Hemant Saliya		Created 
 1    18/09/2023   Hemant Saliya		Updated for Legal Entity Accounting Calendor Wise 

 @strFilter=N'1!2,7!3,11,10!4,12'
**************************************************************       
EXEC DBO.USP_GetIncomeStatementActualTrendReport @ReportingStructureId=8,@MasterCompanyId=1,@ManagementStructureId=1,@StartAccountingPeriodId=136,@EndAccountingPeriodId=138,@IsSupressZero= 0, @xmlFilter=N'<?xml version="1.0" encoding="utf-16"?>
<ArrayOfFilter xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <Filter>
    <FieldName>Level1</FieldName>
    <FieldValue>1,5,6,52</FieldValue>
  </Filter>
  <Filter>
    <FieldName>Level2</FieldName>
    <FieldValue>2,7,8,9</FieldValue>
  </Filter>
  <Filter>
    <FieldName>Level3</FieldName>
    <FieldValue>3,11,10</FieldValue>
  </Filter>
  <Filter>
    <FieldName>Level4</FieldName>
    <FieldValue>4,12,13</FieldValue>
  </Filter>
  <Filter>
    <FieldName>Level5</FieldName>
    <FieldValue />
  </Filter>
  <Filter>
    <FieldName>Level6</FieldName>
    <FieldValue />
  </Filter>
  <Filter>
    <FieldName>Level7</FieldName>
    <FieldValue />
  </Filter>
  <Filter>
    <FieldName>Level8</FieldName>
    <FieldValue />
  </Filter>
  <Filter>
    <FieldName>Level9</FieldName>
    <FieldValue />
  </Filter>
  <Filter>
    <FieldName>Level10</FieldName>
    <FieldValue />
  </Filter>
</ArrayOfFilter>'
************************************************************************/
  
CREATE   PROCEDURE [dbo].[USP_GetIncomeStatementActualTrendReport]
(
		 @masterCompanyId BIGINT,  
		 @ReportingStructureId BIGINT = NULL,  
		 @managementStructureId BIGINT = NULL, 
		 @StartAccountingPeriodId BIGINT = NULL,   
		 @EndAccountingPeriodId BIGINT = NULL,
		 @IsSupressZero BIT = 1,
		 @xmlFilter XML  
)
AS
BEGIN
  BEGIN TRY

		DECLARE @LeafNodeId AS BIGINT;
		DECLARE @AccountcalMonth VARCHAR(100);
		DECLARE @LegalEntityId BIGINT; 
		DECLARE @FiscalYear VARCHAR(20) = ''
		DECLARE @FROMDATE DATETIME;
		DECLARE @TODATE DATETIME;  
		DECLARE @PostedBatchStatusId BIGINT;
		DECLARE @ManualJournalStatusId BIGINT;
		DECLARE @RevenueGLAccountTypeId AS BIGINT;
		DECLARE @ExpenseGLAccountTypeId AS BIGINT;
		DECLARE @BatchMSModuleId BIGINT; 
		DECLARE @ManualBatchMSModuleId BIGINT; 
		DECLARE @IsDebugMode BIT = 0; 

		SET @IsDebugMode = 0;

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

		SELECT @LeafNodeId = LeafNodeid FROM dbo.LeafNode WITH(NOLOCK) WHERE ReportingStructureId = @ReportingStructureId AND ParentId IS NULL AND IsDeleted = 0 
		SELECT @FROMDATE = FromDate, @LegalEntityId = LegalEntityId FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId AND IsDeleted = 0  
		SELECT @TODATE = ToDate,  @FiscalYear = FiscalYear FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @EndAccountingPeriodId AND IsDeleted = 0 

		IF(@IsSupressZero = 0)
		BEGIN
			SELECT @TODATE = MAX(ToDate) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE FiscalYear = @FiscalYear AND IsDeleted = 0 
		END

		SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
		SELECT @ManualJournalStatusId =  ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Manual Batch Details Only
		SELECT @RevenueGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Revenue' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		SELECT @ExpenseGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Expense' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID
		SET @ManualBatchMSModuleId = 73 -- MANUAL BATCH MS MODULE ID

		IF OBJECT_ID(N'tempdb..#GLBalance') IS NOT NULL
		BEGIN
		  DROP TABLE #GLBalance
		END
    
		CREATE TABLE #GLBalance (
		  ID bigint NOT NULL IDENTITY (1, 1),
		  LeafNodeId bigint,
		  AccountingPeriodId bigint NULL,
		  AccountcalMonth VARCHAR(100) NULL,
		  CreaditAmount decimal(18, 2) NULL,
		  DebitAmount decimal(18, 2) NULL,
		  Amount decimal(18, 2) NULL,
		)

		IF OBJECT_ID(N'tempdb..#AccPeriodTable') IS NOT NULL
		BEGIN
		  DROP TABLE #AccPeriodTable
		END

		CREATE TABLE #AccPeriodTable (
		  ID BIGINT NOT NULL IDENTITY (1, 1),
		  PeriodName VARCHAR(100) NULL,
		  FiscalYear INT NULL,
		  OrderNum INT NULL
		)

		INSERT INTO #AccPeriodTable (PeriodName,[FiscalYear],[OrderNum]) 
		SELECT DISTINCT REPLACE(PeriodName,' - ',''), [FiscalYear],[Period]
		FROM dbo.AccountingCalendar WITH(NOLOCK)
		WHERE LegalEntityId = @LegalEntityId AND IsDeleted = 0 AND  
			 CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) AND CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) 
		ORDER BY [FiscalYear],[Period]

		INSERT INTO #AccPeriodTable (PeriodName) 
		VALUES('Total')

		IF OBJECT_ID(N'tempdb..#AccTrendTable') IS NOT NULL
		BEGIN
		  DROP TABLE #AccTrendTable
		END

		IF OBJECT_ID(N'tempdb..#AccPeriodTable_All') IS NOT NULL
		BEGIN
		DROP TABLE #AccPeriodTable_All
		END
	 
		CREATE TABLE #AccPeriodTable_All (
			ID BIGINT NOT NULL IDENTITY (1, 1),
			AccountcalID BIGINT NULL,
			PeriodName VARCHAR(100) NULL,
			FromDate DATETIME NULL,
			ToDate DATETIME NULL
		 )
	 
		 INSERT INTO #AccPeriodTable_All (AccountcalID, PeriodName, FromDate, ToDate) 
		 SELECT AccountingCalendarId, REPLACE(PeriodName,' - ','') ,FromDate,ToDate
		 FROM dbo.AccountingCalendar WITH(NOLOCK)
		 WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))  and IsDeleted = 0 and  
			CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE)  AND ISNULL(IsAdjustPeriod, 0) = 0 
		 ORDER BY FiscalYear, [Period]

		CREATE TABLE #AccTrendTable (
		  ID bigint NOT NULL IDENTITY (1, 1),
		  LeafNodeId bigint,
		  NodeName varchar(500),
		  Amount decimal(18, 2),
		  AccountingPeriodId bigint,
		  AccountcalMonth VARCHAR(100) NULL,
		  AccountingPeriod VARCHAR(100) null,
		  IsBlankHeader bit DEFAULT 0,
		  IsTotlaLine bit DEFAULT 0
		)

		DECLARE @SQLQuery varchar(max) = '
		IF OBJECT_ID(N''tempdb..##AccTrendTablePivot'') IS NOT NULL
		BEGIN
		  DROP TABLE ##AccTrendTablePivot
		END

		CREATE TABLE ##AccTrendTablePivot (
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
															   From #AccPeriodTable
															   ORDER BY OrderNum
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
		  AccountcalMonth VARCHAR(100) NULL,
		  AccountingPeriodName VARCHAR(100) NULL,
		  Amount decimal(18, 2) NULL,
		  TotalAmount decimal(18, 2) NULL,
		  ChildCount int NULL,
		  IsProcess bit DEFAULT (0)
		)

		INSERT INTO #GLBalance (LeafNodeId, AccountcalMonth, DebitAmount, CreaditAmount,  Amount)
		(SELECT DISTINCT LF.LeafNodeId , REPLACE(BD.AccountingPeriod,' - ',''), 
						CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END 'DebitAmount',
						CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END 'CreditAmount',
						
						CASE WHEN GL.GLAccountTypeId = @ExpenseGLAccountTypeId THEN
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END) - 
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) 
						ELSE
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) -
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END)
						END AS AMONUT
		FROM dbo.CommonBatchDetails CMD WITH (NOLOCK)
			INNER JOIN dbo.BatchDetails BD WITH (NOLOCK) ON CMD.JournalBatchDetailId = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
			INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = CMD.CommonJournalBatchDetailId AND ModuleId = @BatchMSModuleId
			INNER JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON CMD.GlAccountId = GLM.GLAccountId
			INNER JOIN dbo.GLAccount GL WITH (NOLOCK) ON GL.GlAccountId = GLM.GLAccountId AND GL.GLAccountTypeId IN (@RevenueGLAccountTypeId, @ExpenseGLAccountTypeId) 
			INNER JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0 AND ISNULL(LF.ReportingStructureId, 0) = @ReportingStructureId 
		WHERE CMD.IsDeleted = 0 AND GLM.IsDeleted = 0 AND BD.IsDeleted = 0 AND CMD.MasterCompanyId = @MasterCompanyId AND ISNULL(CMD.IsVersionIncrease, 0) = 0		
				AND BD.AccountingPeriodId IN (SELECT AccountcalID FROM #AccPeriodTable_All)
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
		GROUP BY LF.LeafNodeId , BD.AccountingPeriod, GLM.IsPositive, GL.GLAccountTypeId

		UNION ALL

		SELECT	DISTINCT LF.LeafNodeId , REPLACE(AC.PeriodName,' - ',''),
				CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Debit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Debit, 0)), 0) * -1 END 'DebitAmount',
				CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Credit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Credit, 0)), 0) * -1 END 'CreditAmount',
				CASE WHEN GL.GLAccountTypeId = @ExpenseGLAccountTypeId THEN
					(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Debit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Debit, 0)), 0) * -1 END) - 
					(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Credit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Credit, 0)), 0) * -1 END)  
				ELSE
					(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Credit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Credit, 0)), 0) * -1 END) -
					(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Debit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Debit, 0)), 0) * -1 END)
				END AS AMONUT

				--(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Debit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Debit, 0)), 0) * -1 END) - 
				--(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Credit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Credit, 0)), 0) * -1 END) 
				--AS AMONUT
			FROM dbo.ManualJournalDetails MJD WITH (NOLOCK) 
				JOIN dbo.GLAccount GL ON MJD.GlAccountId = GL.GLAccountId AND GL.GLAccountTypeId IN (@RevenueGLAccountTypeId, @ExpenseGLAccountTypeId) 
				JOIN dbo.ManualJournalHeader MJH  WITH (NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
				JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON MJD.GlAccountId = GLM.GLAccountId AND GLM.IsDeleted = 0
				JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = MJD.ManualJournalDetailsId AND MSD.ModuleId = @ManualBatchMSModuleId
				JOIN dbo.AccountingCalendar AC  WITH (NOLOCK) ON AC.AccountingCalendarId = MJH.AccountingPeriodId
				JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0
					 AND ISNULL(LF.ReportingStructureId, 0) = @ReportingStructureId
			WHERE GLM.GLAccountId = MJD.GlAccountId  
					AND MJH.ManualJournalStatusId = @ManualJournalStatusId 
							AND MJH.AccountingPeriodId IN (SELECT AccountcalID FROM #AccPeriodTable_All)
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
			GROUP BY  LF.LeafNodeId , AC.PeriodName, GLM.IsPositive, GL.GLAccountTypeId)

		

		IF(@IsDebugMode = 1)
		BEGIN
			SELECT 'GLBalance'
			SELECT * FROM #GLBalance
			--SELECT * FROM #AccPeriodTable
			--SELECT * FROM #AccPeriodTable_All
		END

		DECLARE @LID AS int = 0;
		DECLARE @IsFristRow AS bit = 1;
		DECLARE @LCOUNT AS int = 0;
		SELECT @LCOUNT = MAX(ID) FROM #AccPeriodTable
		WHILE(@LCOUNT > 0)
		BEGIN
		   SELECT @AccountcalMonth = ISNULL(PeriodName, '') FROM #AccPeriodTable where ID = @LCOUNT

		   INSERT INTO #TempTable (LeafNodeId, [Name], IsPositive, ParentId, IsProcess, AccountcalMonth)
							  SELECT
								LeafNodeId,[Name],IsPositive,ParentId,0,@AccountcalMonth
								  FROM dbo.LeafNode
								  WHERE LeafNodeId = @LeafNodeId
									  AND IsDeleted = 0
									  AND ReportingStructureId = @ReportingStructureId

			DECLARE @CID AS int = 0;
			DECLARE @CLID AS int = 0;
			SELECT TOP 1 @CID = ID, @CLID = LeafNodeId
						FROM #TempTable
								WHERE IsProcess = 0 AND AccountcalMonth = @AccountcalMonth
								ORDER BY ID

			WHILE (@CLID > 0)
			BEGIN
				INSERT INTO #TempTable (LeafNodeId, [Name], IsPositive, ParentId, IsProcess,AccountcalMonth)
									SELECT  LeafNodeId, [Name], IsPositive,  @CLID, 0, @AccountcalMonth
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

			IF(@IsDebugMode = 1)
			BEGIN
				SELECT 'TempTable'
				--SELECT * FROM #TempTable WHERE LeafNodeId = 143
				--SELECT * FROM #GLBalance WHERE LeafNodeId = 143
			END
			
			UPDATE #TempTable SET Amount = tmpCal.Amount
			FROM(SELECT SUM(ISNULL(GL.Amount, 0)) AS Amount, T.LeafNodeId, T.AccountcalMonth
				FROM #TempTable T 
			JOIN #GLBalance GL ON T.AccountcalMonth = @AccountcalMonth AND T.LeafNodeId = GL.LeafNodeId AND T.AccountcalMonth = GL.AccountcalMonth 
			GROUP BY T.LeafNodeId, T.AccountcalMonth
			)tmpCal WHERE tmpCal.AccountcalMonth = #TempTable.AccountcalMonth AND tmpCal.LeafNodeId = #TempTable.LeafNodeId AND tmpCal.AccountcalMonth = @AccountcalMonth 
			
			--UPDATE #TempTable SET Amount =ISNULL(GL.Amount, 0)
			--FROM #TempTable T 
			--JOIN #GLBalance GL ON T.AccountcalMonth = @AccountcalMonth AND T.LeafNodeId = GL.LeafNodeId AND T.AccountcalMonth = GL.AccountcalMonth


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
		
			UPDATE #TempTable SET IsProcess = 0,
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

			  IF NOT EXISTS (SELECT TOP 1 ID FROM #AccTrendTable WHERE LeafNodeId = @CLID AND IsBlankHeader = 1 AND AccountcalMonth = @AccountcalMonth)
			  BEGIN
					INSERT INTO #AccTrendTable (LeafNodeId, NodeName, Amount, AccountcalMonth, IsBlankHeader)
							  SELECT TOP 1 LeafNodeId, Name + ' :',NULL, @AccountcalMonth, 1 FROM #TempTable 
											 WHERE LeafNodeId = @CLID
												  AND ChildCount > 0 AND  AccountcalMonth = @AccountcalMonth
					IF(@IsFristRow = 1)
					BEGIN
					INSERT INTO ##AccTrendTablePivot(Name,IsBlankHeader, LeafNodeId, ParentId)
							   SELECT TOP 1  Name + ' :', 1, LeafNodeId, ParentId FROM #TempTable 
											 WHERE LeafNodeId = @CLID
												  AND ChildCount > 0 AND AccountcalMonth = @AccountcalMonth
					END
			  END

		  INSERT INTO #AccTrendTable (LeafNodeId, NodeName, Amount, AccountcalMonth, IsBlankHeader)
			SELECT LeafNodeId, Name, Amount, @AccountcalMonth, 0
					 FROM #TempTable
						   WHERE ID = @CID AND AccountcalMonth = @AccountcalMonth
		  IF(@IsFristRow = 1)
					BEGIN
					INSERT INTO ##AccTrendTablePivot(Name,IsBlankHeader, LeafNodeId, ParentId)
								SELECT  Name, 0, LeafNodeId, ParentId
									FROM #TempTable
											WHERE ID = @CID AND AccountcalMonth = @AccountcalMonth 
					END

		  UPDATE #TempTable
				  SET IsProcess = 1
					 WHERE ID = @CID AND AccountcalMonth = @AccountcalMonth 

		  IF NOT EXISTS (SELECT TOP 1 ID FROM #TempTable WHERE ParentId = @CLID AND IsProcess = 0 AND AccountcalMonth = @AccountcalMonth )
		  BEGIN
			IF NOT EXISTS (SELECT TOP 1 ID FROM #AccTrendTable WHERE LeafNodeId = @CLID  AND IsTotlaLine = 1 AND AccountcalMonth = @AccountcalMonth )
			BEGIN
				  INSERT INTO #AccTrendTable (LeafNodeId, NodeName, Amount, AccountcalMonth, IsBlankHeader, IsTotlaLine)
								SELECT  LeafNodeId,'Total - ' + Name, TotalAmount, @AccountcalMonth, 0, 1
										FROM #TempTable
											WHERE LeafNodeId = @CLID  AND ChildCount > 0 AND AccountcalMonth = @AccountcalMonth
				 IF(@IsFristRow = 1)
					BEGIN
					INSERT INTO ##AccTrendTablePivot(Name,IsBlankHeader,IsTotlaLine, LeafNodeId, ParentId)
							   SELECT TOP 1  'Total - ' + Name,0, 1, LeafNodeId, LeafNodeId
											 FROM #TempTable
												 WHERE LeafNodeId = @CLID  AND ChildCount > 0  AND AccountcalMonth = @AccountcalMonth

					END
			END
		  END
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

			-----Final Loop
			SET @IsFristRow = 0
			SET @LCOUNT = @LCOUNT -1
		END
		IF(@IsDebugMode = 1)
		BEGIN
			SELECT 'AccTrendTablePivot'
			--SELECT * FROM #TempTable where LeafNodeId = 143
			--SELECT * FROM #GLBalance
			--SELECT * FROM #TempTable
			--SELECT * FROM ##AccTrendTablePivot
			--SELECT * FROM #AccTrendTable
		END

		UPDATE #TempTable SET AccountingPeriodName = REPLACE(AP.PeriodName,' - ',' ')  
		FROM #TempTable tmp JOIN dbo.AccountingCalendar AP WITH(NOLOCK) ON tmp.AccountcalMonth = REPLACE(AP.PeriodName,' - ','')  

		UPDATE #AccTrendTable SET AccountingPeriod = CASE WHEN ISNULL(AP.PeriodName, '') != '' THEN REPLACE(AP.PeriodName ,' - ',' ')  ELSE 'Total' END
		FROM #AccTrendTable tmp LEFT JOIN dbo.AccountingCalendar AP WITH(NOLOCK) ON tmp.AccountcalMonth = REPLACE(AP.PeriodName,' - ','')  
	
		UPDATE #AccTrendTable 
		SET Amount = Groptoal.TotalAmt	
		FROM(
			SELECT SUM(Amount) AS TotalAmt, NodeName FROM #AccTrendTable act WHERE AccountingPeriod != 'Total' GROUP BY NodeName
		) Groptoal WHERE Groptoal.NodeName = #AccTrendTable.NodeName AND AccountingPeriod = 'Total'
	
		DECLARE @COUNT AS INT;
		DECLARE @COUNTMAX AS INT
		SELECT @COUNTMAX = MAX(ID), @COUNT = MIN(ID) FROM #AccPeriodTable

		WHILE (@COUNT <= @COUNTMAX)
		BEGIN
			DECLARE @APName AS VARCHAR(100);
			SELECT @APName = PeriodName FROM #AccPeriodTable WHERE ID = @COUNT

			DECLARE @SQLUpdateQuery VARCHAR(MAX) = 'UPDATE ##AccTrendTablePivot SET [' + CAST(@APName AS VARCHAR(100)) +'] = (SELECT SUM(Amount) FROM #AccTrendTable WHERE NodeName = AP.Name AND IsBlankHeader = AP.IsBlankHeader and AccountcalMonth = ''' + @APName + ''' ) FROM ##AccTrendTablePivot AP'
		
			--PRINT(@SQLUpdateQuery)  
			EXEC(@SQLUpdateQuery)  

			SET @COUNT = @COUNT + 1

		END

		DECLARE @CreateTableSQLQuery VARCHAR(MAX) = '
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
			From #AccPeriodTable
			Order By OrderNum  
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
		ORDER BY ParentId, SequenceNumber

		DECLARE @COUNT1 AS INT;
		DECLARE @COUNTMAX1 AS INT
		SELECT @COUNTMAX1 = MAX(ID), @COUNT1 = MIN(ID) FROM #AccPeriodTable

		WHILE (@COUNT1 <= @COUNTMAX1)
		BEGIN
			DECLARE @APName1 AS VARCHAR(100);

			DECLARE @SQLFinalUpdateQuery varchar(max) = 'UPDATE T1 SET T1.[' + CAST(@APName1 AS VARCHAR(100)) +'] = T2.[' + CAST(@APName1 AS VARCHAR(100)) +'] FROM ##tmpFinalReturnTable T1 JOIN ##AccTrendTablePivot T2 ON T1.leafNodeId = T2.leafNodeId AND T1.parentId = T2.parentId AND T1.[name] = T2.[name]'
		
			EXEC(@SQLFinalUpdateQuery)  

			SET @COUNT1 = @COUNT1 + 1
		END

		UPDATE T1 
				SET T1.IsLeafNode = T2.IsLeafNode, T1.MasterCompanyId = T2.MasterCompanyId, 
					T1.ReportingStructureId = T2.ReportingStructureId, T1.sequenceNumber = T2.sequenceNumber,
					T1.IsPositive = T2.IsPositive, T1.parentNodeName = T2.parentNodeName
		FROM ##AccTrendTablePivot T1 
		JOIN ##tmpFinalReturnTable T2 ON T1.leafNodeId = T2.leafNodeId AND T1.parentId = T2.parentId AND T1.[name] = T2.[name]

		UPDATE T1 
				SET T1.IsLeafNode = T2.IsLeafNode, T1.MasterCompanyId = T2.MasterCompanyId, 
					T1.ReportingStructureId = T2.ReportingStructureId, T1.sequenceNumber = T2.sequenceNumber,
					T1.IsPositive = T2.IsPositive, T1.parentNodeName = T2.parentNodeName
		FROM ##AccTrendTablePivot T1 
		JOIN ##tmpFinalReturnTable T2 ON T1.leafNodeId = T2.leafNodeId AND T1.parentId = T2.parentId --AND T1.[name] = T2.[name]
		WHERE T1.parentNodeName IS NULL

		UPDATE  ##AccTrendTablePivot SET leafNodeId = NULL WHERE IsBlankHeader = 1 OR IsTotlaLine = 1

		DECLARE @COUNT2 AS INT;
		DECLARE @COUNTMAX2 AS INT
		DECLARE @MAXLeafNodeId AS INT
		SELECT @COUNTMAX2 = MAX(ID), @COUNT2 = MIN(ID), @MAXLeafNodeId = MAX(leafNodeId)  FROM ##AccTrendTablePivot

		WHILE (@COUNT2 <= @COUNTMAX2)
		BEGIN

			SET @MAXLeafNodeId = @MAXLeafNodeId + 1

			UPDATE ##AccTrendTablePivot SET leafNodeId = @MAXLeafNodeId WHERE ID = @COUNT2 AND leafNodeId IS NULL AND (IsBlankHeader = 1 OR IsTotlaLine = 1)

			SET @COUNT2 = @COUNT2 + 1
		
		END

		DECLARE @COUNT3 AS INT;
		DECLARE @COUNTMAX3 AS INT
		SELECT @COUNTMAX3 = MAX(ID), @COUNT3 = MIN(ID) FROM ##AccTrendTablePivot

		WHILE (@COUNT3 <= @COUNTMAX3)
		BEGIN
		
			DECLARE @LeafNodeId3 AS BIGINT;
			SELECT @LeafNodeId3 = leafNodeId FROM ##AccTrendTablePivot WHERE ID = @COUNT3

			IF((SELECT COUNT(1) FROM ##AccTrendTablePivot WHERE ISNULL(parentId, 0) IN (ISNULL(@LeafNodeId3, 0))) > 0 )
			BEGIN
				DECLARE @COUNT4 AS INT;
				DECLARE @COUNTMAX4 AS INT
				SELECT @COUNTMAX4 = MAX(ID), @COUNT4 = MIN(ID) FROM #AccPeriodTable

				WHILE (@COUNT4 <= @COUNTMAX4)
				BEGIN
					DECLARE @APName4 AS VARCHAR(100);
					SELECT @APName4 = PeriodName FROM #AccPeriodTable WHERE ID = @COUNT4

					DECLARE @SQLQueryUpdateHeader varchar(max) = 'UPDATE ##AccTrendTablePivot SET [' + CAST(@APName4 AS VARCHAR(100)) +'] = NULL WHERE leafNodeId = ' + CAST(@LeafNodeId3 AS VARCHAR(100)) +'' 
					PRINT (@SQLQueryUpdateHeader)
					EXEC(@SQLQueryUpdateHeader)  

					SET @COUNT4 = @COUNT4 + 1
				END

			END

			SET @COUNT3 = @COUNT3 + 1
		
		END

		UPDATE ##AccTrendTablePivot SET [name] = REPLACE([name],'Total - ','') 

		SELECT * FROM ##AccTrendTablePivot WHERE IsBlankHeader != 1 Order BY parentId 

  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = 'USP_GetIncomeStatementActualTrendReport',
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