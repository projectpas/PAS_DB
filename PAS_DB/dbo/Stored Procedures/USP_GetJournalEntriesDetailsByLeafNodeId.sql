/*************************************************************             
 ** File:   [USP_GetJournalEntriesDetailsByLeafNodeId]             
 ** Author: Hemant Saliya  
 ** Description: This stored procedure is used to Get income statement(actual) report Journal Entry Data 
 ** Purpose: Initial Draft           
 ** Date: 17/07/2023  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    17/07/2023   Hemant Saliya  Created
	2    08/09/2023   Hemant Saliya  Added MS filter 
**************************************************************  

EXEC [USP_GetJournalEntriesDetailsByLeafNodeId] 135,135,8,1,1,102, 307, @strFilter=N'1,5,6,52!2,7,8,9!3,11,10!4,12,13'
************************************************************************/
  
CREATE   PROCEDURE [dbo].[USP_GetJournalEntriesDetailsByLeafNodeId]  
(  
 @StartAccountingPeriodId BIGINT = NULL,   
 @EndAccountingPeriodId BIGINT = NULL,
 @ReportingStructureId BIGINT = NULL, 
 @managementStructureId BIGINT = NULL,  
 @masterCompanyId INT = NULL,
 @LeafNodeId BIGINT = NULL,
 @GLAccountId BIGINT = NULL,
 @strFilter VARCHAR(MAX) = NULL
)  
AS  
BEGIN   
 BEGIN TRY  
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
		  DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		  DECLARE @PostedBatchStatusId BIGINT;
		  DECLARE @ManualJournalStatusId BIGINT;
		  DECLARE @BatchMSModuleId BIGINT; 
		  DECLARE @ManualBatchMSModuleId BIGINT; 
		  DECLARE @RevenueGLAccountTypeId AS BIGINT;
		  DECLARE @ExpenseGLAccountTypeId AS BIGINT;

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

		  SELECT @FROMDATE = FromDate, @LegalEntityId = LegalEntityId FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId AND IsDeleted = 0
		  SELECT @TODATE = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @EndAccountingPeriodId AND IsDeleted = 0 
		  SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
		  SELECT @ManualJournalStatusId =  ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Manual Batch Details Only
		  SELECT @RevenueGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Revenue' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		  SELECT @ExpenseGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Expense' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		  SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID
		  SET @ManualBatchMSModuleId = 73 -- MANUAL BATCH MS MODULE ID

		  SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
		  WHERE LE.LegalEntityId = @LegalEntityId;

		  IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
		  BEGIN    
		  	DROP TABLE #TEMPMSFilter
		  END
		  
		  CREATE TABLE #TEMPMSFilter(        
		  	 ID BIGINT  IDENTITY(1,1),        
		  	 LevelIds VARCHAR(MAX)			 
		   ) 
		  
		  INSERT INTO #TEMPMSFilter(LevelIds)
		  SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!')

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
		  
		  INSERT INTO #AccPeriodTable (PeriodName,[FiscalYear],[OrderNum]) 
		  SELECT  REPLACE(PeriodName,' - ',''),[FiscalYear],[Period]
		  FROM dbo.AccountingCalendar WITH(NOLOCK)
		  WHERE LegalEntityId = @LegalEntityId and IsDeleted = 0 and  
		  	 CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) 
		  
		  --INSERT INTO #AccPeriodTable (PeriodName) 
		  --VALUES('Total')

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
		  )

		  INSERT INTO #GLBalance (LeafNodeId, AccountingPeriod, GLAccountId, JournalNumber, JournalBatchDetailId, EntryDate, DebitAmount, CreaditAmount,  Amount)
			(SELECT DISTINCT LF.LeafNodeId , BD.AccountingPeriod, CMD.GLAccountId, BD.JournalTypeNumber, BD.JournalBatchDetailId, CONVERT(DATETIME, CMD.EntryDate, 120),
					CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END 'CreditAmount',
					CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END 'DebitAmount',
					(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END) - 
					(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) AS AMONUT
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
			GROUP BY LF.LeafNodeId , BD.AccountingPeriod, GLM.IsPositive, CMD.GLAccountId, BD.JournalTypeNumber, BD.JournalBatchDetailId, CONVERT(DATETIME, CMD.EntryDate, 120)

			UNION ALL

			SELECT	DISTINCT LF.LeafNodeId , REPLACE(AC.PeriodName, ' - ', ' '), MJD.GlAccountId, MJH.JournalNumber, 0 AS JournalBatchDetailId, CONVERT(DATETIME, MJH.EntryDate, 120),
				CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Debit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Debit, 0)), 0) * -1 END 'DebitAmount',
					CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Credit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Credit, 0)), 0) * -1 END 'CreditAmount',
				(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Debit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Debit, 0)), 0) * -1 END) - 
					(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Credit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Credit, 0)), 0) * -1 END) AS AMONUT
				FROM dbo.ManualJournalDetails MJD WITH (NOLOCK) 
					JOIN dbo.GLAccount GL ON MJD.GlAccountId = GL.GLAccountId AND GL.GLAccountTypeId IN (@RevenueGLAccountTypeId, @ExpenseGLAccountTypeId) 
					JOIN dbo.ManualJournalHeader MJH  WITH (NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
					JOIN dbo.AccountingCalendar AC WITH (NOLOCK) ON MJH.AccountingPeriodId = AC.AccountingCalendarId
					JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON MJD.GlAccountId = GLM.GLAccountId AND GLM.IsDeleted = 0
					INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = MJD.ManualJournalDetailsId AND MSD.ModuleId = @ManualBatchMSModuleId
					JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0
						 AND ISNULL(ReportingStructureId, 0) = @ReportingStructureId
			WHERE GLM.GLAccountId = MJD.GlAccountId  AND MJH.ManualJournalStatusId = @ManualJournalStatusId AND MJD.GlAccountId = @GLAccountId
					AND MJD.MasterCompanyId = @MasterCompanyId AND MJD.IsDeleted = 0 AND MJH.IsDeleted = 0
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
		  GROUP BY  LF.LeafNodeId , AC.PeriodName, GLM.IsPositive, MJD.GlAccountId, MJH.JournalNumber, CONVERT(DATETIME, MJH.EntryDate, 120))

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

		  WHILE(@LCOUNT > 0)
		  BEGIN
			SELECT  @AccountcalMonth = PeriodName FROM #AccPeriodTable where ID = @LCOUNT

			INSERT INTO #TempTable (LeafNodeId, [Name], IsPositive, ParentId, IsProcess,AccountcalMonth)
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
			OrderNum INT NULL
		  )

		  DECLARE @COUNT AS INT;
		  DECLARE @COUNTMAX AS INT
		  SELECT @COUNT = MIN(ID), @COUNTMAX = MAX(ID) fROM #AccPeriodTable
		  WHILE (@COUNT <= @COUNTMAX)
		  BEGIN

			  SELECT @AccountcalMonth = PeriodName FROM #AccPeriodTable where ID = @COUNT

			  INSERT INTO #AccTrendTable(LeafNodeId, NodeName, OrderNum, GLAccountId, GLAccountCode, GLAccountName, JournalNumber, JournalBatchDetailId, CreditAmount, DebitAmount, AccountingPeriod, PeriodName, EntryDate) --, ReferenceId, DistributionSetupCode)
			  SELECT T.LeafNodeId, T.[Name] , AP.OrderNum, GL.GLAccountId, GLA.AccountCode, GLA.AccountName, JournalNumber, JournalBatchDetailId, GL.CreaditAmount, DebitAmount, AP.PeriodName, REPLACE(AP.PeriodName ,' - ',' '), EntryDate  --CBD.ReferenceId, CBD.DistributionSetupCode, EntryDate 
			  FROM #TempTable T  
				  JOIN #GLBalance GL ON T.LeafNodeId = GL.LeafNodeId AND T.AccountcalMonth = REPLACE(GL.AccountingPeriod ,' - ','') 
				  JOIN dbo.GLAccount GLA WITH (NOLOCK) ON GLA.GLAccountId = GL.GLAccountId 
				  LEFT JOIN #AccPeriodTable AP ON AP.PeriodName = T.AccountcalMonth 
			  WHERE GL.GLAccountId = @GLAccountId AND T.AccountcalMonth = @AccountcalMonth
			  
			  SET @COUNT = @COUNT + 1
		  END

		  --ReferenceName
		  UPDATE #AccTrendTable 
				SET ReferenceModule = CASE WHEN UPPER(DM.DistributionCode) = 'WOMATERIALGRIDTAB' OR UPPER(DM.DistributionCode) = 'WOLABORTAB' OR UPPER(DM.DistributionCode) = 'WOSETTLEMENTTAB' 
												OR UPPER(DM.DistributionCode) = 'WOINVOICINGTAB' OR UPPER(DM.DistributionCode) = 'MROWOSHIPMENT' THEN 'WO' 
											WHEN UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT' THEN 'SO'    
											WHEN UPPER(DM.DistributionCode) = 'RECEIVINGPOSTOCKLINE' THEN 'RPO'  
											WHEN UPPER(DM.DistributionCode) = 'RECEIVINGROSTOCKLINE' THEN 'RRO' 
											WHEN UPPER(DM.DistributionCode) = 'MROWOSHIPMENT' THEN 'WO' 
											WHEN UPPER(DM.DistributionCode) = 'CHECKPAYMENT' THEN 'CHEQUE' 
											WHEN UPPER(DM.DistributionCode) = 'ASSETINVENTORY' THEN 'ASSET'
											WHEN UPPER(DM.DistributionCode) = 'VENDORRMA' THEN 'VENDOR RMA'
											WHEN UPPER(DM.DistributionCode) = 'MANUALSTOCKLINE' THEN 'STOCKLINE'
											ELSE '' END,
					ReferenceName = CASE WHEN UPPER(DM.DistributionCode) = 'WOMATERIALGRIDTAB' OR UPPER(DM.DistributionCode) = 'WOLABORTAB' OR UPPER(DM.DistributionCode) = 'WOSETTLEMENTTAB' 
												OR UPPER(DM.DistributionCode) = 'WOINVOICINGTAB' OR UPPER(DM.DistributionCode) = 'MROWOSHIPMENT' THEN WBD.CustomerName
											WHEN UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT' THEN SBD.CustomerName   
											WHEN UPPER(DM.DistributionCode) = 'RECEIVINGPOSTOCKLINE' THEN SD.VendorName 
											WHEN UPPER(DM.DistributionCode) = 'RECEIVINGROSTOCKLINE' THEN SD.VendorName
											WHEN UPPER(DM.DistributionCode) = 'MROWOSHIPMENT' THEN WBD.CustomerName 
											WHEN UPPER(DM.DistributionCode) = 'CHECKPAYMENT' THEN '' 
											WHEN UPPER(DM.DistributionCode) = 'ASSETINVENTORY' THEN ''
											WHEN UPPER(DM.DistributionCode) = 'VENDORRMA' THEN V.VendorName
											WHEN UPPER(DM.DistributionCode) = 'MANUALSTOCKLINE' THEN ''											
											ELSE '' END,
					Referenceid = CASE WHEN UPPER(DM.DistributionCode) = 'WOMATERIALGRIDTAB' OR UPPER(DM.DistributionCode) = 'WOLABORTAB' OR UPPER(DM.DistributionCode) = 'WOSETTLEMENTTAB' 
												OR UPPER(DM.DistributionCode) = 'WOINVOICINGTAB' OR UPPER(DM.DistributionCode) = 'MROWOSHIPMENT' THEN WBD.ReferenceId
											WHEN UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT' THEN SBD.SalesOrderId   
											WHEN UPPER(DM.DistributionCode) = 'RECEIVINGPOSTOCKLINE' THEN SD.PoId  
											WHEN UPPER(DM.DistributionCode) = 'RECEIVINGROSTOCKLINE' THEN SD.RoId
											WHEN UPPER(DM.DistributionCode) = 'MROWOSHIPMENT' THEN WBD.ReferenceId 
											WHEN UPPER(DM.DistributionCode) = 'CHECKPAYMENT' THEN VPBD.ReferenceId
											WHEN UPPER(DM.DistributionCode) = 'ASSETINVENTORY' THEN 0
											WHEN UPPER(DM.DistributionCode) = 'VENDORRMA' THEN VRBD.ReferenceId
											WHEN UPPER(DM.DistributionCode) = 'MANUALSTOCKLINE' THEN 0											
											ELSE '' END,
					CustomerId = CASE WHEN UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT' THEN SBD.CustomerId ELSE '' END,
					LastMSLevel = CB.LastMSLevel,
					AllMSlevels = CB.AllMSlevels
		  FROM #AccTrendTable tmp 
			  JOIN dbo.CommonBatchDetails CB WITH (NOLOCK) ON tmp.JournalBatchDetailId = cb.JournalBatchDetailId
			  JOIN dbo.DistributionSetup DS WITH (NOLOCK) ON DS.ID = cb.DistributionSetupId
			  JOIN dbo.DistributionMaster DM WITH (NOLOCK) ON DS.DistributionMasterId = DM.ID
			  LEFT JOIN dbo.WorkOrderBatchDetails WBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = WBD.JournalBatchDetailId
			  LEFT JOIN dbo.SalesOrderBatchDetails SBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = SBD.JournalBatchDetailId
			  LEFT JOIN dbo.StocklineBatchDetails SD WITH (NOLOCK) ON tmp.JournalBatchDetailId = SD.JournalBatchDetailId
			  LEFT JOIN dbo.VendorPaymentBatchDetails VPBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = VPBD.JournalBatchDetailId
			  LEFT JOIN dbo.VendorRMAPaymentBatchDetails VRBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = VRBD.JournalBatchDetailId
			  LEFT JOIN dbo.Vendor V WITH (NOLOCK) ON V.VendorId = VRBD.VendorId

		  ;WITH cte
			AS
			(
			   SELECT LeafNodeId, NodeName, OrderNum,  GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel, AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, 
				SUM(ISNULL(CreditAmount, 0) - ISNULL(DebitAmount, 0)) Amount 
			   FROM #AccTrendTable
			   GROUP BY LeafNodeId, NodeName, OrderNum, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
				CreditAmount, DebitAmount,  AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate

			), cteRanked AS
			(
			   SELECT Amount, LeafNodeId, OrderNum, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
				CreditAmount, DebitAmount,  AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, 
				ROW_NUMBER() OVER(ORDER BY LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate) rownum
			   FROM cte
			) 
			SELECT (SELECT SUM(Amount) FROM cteRanked c2 WHERE c2.rownum <= c1.rownum) AS Amount, 0 AS AccountingPeriodId, OrderNum,
			  c1.LeafNodeId, UPPER(c1.NodeName) AS NodeName, c1.GLAccountId, (UPPER(c1.GLAccountCode) + '-' + UPPER(c1.GLAccountName)) AS GLAccount, UPPER(c1.JournalNumber) AS JournalNumber, c1.LastMSLevel,  c1.AllMSlevels,
				c1.CreditAmount, c1.DebitAmount, UPPER(c1.AccountingPeriod) AS AccountingPeriod, UPPER(c1.PeriodName) AS PeriodName, c1.ReferenceModule, c1.ReferenceName, c1.ReferenceId, c1.CustomerId, c1.DistributionSetupCode, 
				Cast(DBO.ConvertUTCtoLocal(c1.EntryDate, @CurrntEmpTimeZoneDesc) as datetime) AS EntryDate				
			FROM cteRanked c1 
			WHERE c1.GLAccountId IS NOT NULL
			ORDER BY OrderNum, JournalNumber;


 END TRY  
 BEGIN CATCH  
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
					  , @AdhocComments     VARCHAR(150)    = 'USP_GetJournalEntriesDetailsByLeafNodeId' 
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