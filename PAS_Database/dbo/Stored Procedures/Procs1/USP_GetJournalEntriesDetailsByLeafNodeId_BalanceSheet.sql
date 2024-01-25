/*************************************************************             
 ** File:   [USP_GetJournalEntriesDetailsByLeafNodeId_BalanceSheet]             
 ** Author: Rajesh Gami  
 ** Description: This stored procedure is used to Get balance sheet report Journal Entry Data 
 ** Purpose: Initial Draft           
 ** Date: 06/09/2023  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    06/09/2023   HEMANT SALIYA  Created
	2    31/10/2023   HEMANT SALIYA  Updated For Correct GL Balance
	3    24/11/2023   Moin Bloch     Renamed ReferenceModule VENDOR RMA To VENDOR CREDIT MEMO AND SO TO CUSTOMER CREDIT MEMO
	4    28/11/2023   Moin Bloch     Added ReferenceId For WIRETRANSFER,ACHTRANSFER,CREDITCARDPAYMENT
	5    08/12/2023   Moin Bloch     Removed REPLACE(BD.AccountingPeriod,' - ','') and Added @periodNameDistinct Line No 258
	6    12/12/2023   Moin Bloch     Added CreditMemoHeaderId and IsStandAloneCM For 'CRFD' Line No 599
	7    25/01/2024   Hemant Saliya	 Remove Manual Journal from Reports

**************************************************************/  

/*************************************************************             

EXEC dbo.USP_GetJournalEntriesDetailsByLeafNodeId_BalanceSheet @StartAccountingPeriodId=138,@EndAccountingPeriodId=138,@ReportingStructureId=23,@ManagementStructureId=1,
@MasterCompanyId=1,@LeafNodeId=102,@GLAccountId=307,@strFilter=N'1,5,6,52!2,7,8,9!3,11,10!4,12,13'
************************************************************************/
  
CREATE   PROCEDURE [dbo].[USP_GetJournalEntriesDetailsByLeafNodeId_BalanceSheet]
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

		  DECLARE 
			@MAXCalTempID INT = 0, @INITIALFROMDATE DATETIME,@INITIALENDDATE DATETIME;

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
		    AccountcalID BIGINT NULL,
		    PeriodName VARCHAR(100) NULL,
			FromDate DATETIME NULL,
			ToDate DATETIME NULL,
			FiscalYear INT NULL,
			OrderNum INT NULL
		  )

		  INSERT INTO #AccPeriodTable (PeriodName, [OrderNum], FromDate, ToDate) 
		  SELECT DISTINCT REPLACE(PeriodName,' - ',''), [Period] , FromDate, ToDate
		  FROM dbo.AccountingCalendar WITH(NOLOCK)
		  WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND IsDeleted = 0 AND  
			 CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) AND ISNULL(IsAdjustPeriod, 0) = 0 
		  
		  INSERT INTO #AccPeriodTable (AccountcalID, PeriodName) 
		  VALUES(9999999,'Total')

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
			 CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) AND ISNULL(IsAdjustPeriod, 0) = 0 

		  INSERT INTO #AccPeriodTableFinal (AccountcalID, PeriodName) 
		  VALUES(9999999,'Total')

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

		--SELECT * FROM #AccPeriodTable
		--SELECT * FROm #AccPeriodTable_All
		  
		SELECT @MAXCalTempID = MAX(OrderNum) fROM #AccPeriodTable WHERE ISNULL(AccountcalID, 0) NOT IN(9999999)
		--WHILE(@MAXCalTempID > 0)
		--BEGIN

			--SELECT  @AccountcalID = AccountcalID, @INITIALENDDATE = ToDate FROM #AccPeriodTable where ID = @MAXCalTempID AND AccountcalID NOT IN(9999999)

			SELECT @LEFROMDATE = MIN(FromDate), @LETODATE = MAX(ToDate), @periodNameDistinct = PeriodName FROM #AccPeriodTable WHERE OrderNum = @MAXCalTempID  GROUP BY PeriodName

			DELETE FROM #AccPeriodTable_All

			INSERT INTO #AccPeriodTable_All (AccountcalID, PeriodName, FromDate, ToDate) 
			SELECT AccountingCalendarId, REPLACE(PeriodName,' - ',' ') ,FromDate,ToDate
			FROM dbo.AccountingCalendar WITH(NOLOCK)
			WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND IsDeleted = 0 AND  
				CAST(Fromdate AS DATE) >= CAST(@INITIALFROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@LETODATE AS DATE)  AND ISNULL(IsAdjustPeriod, 0) = 0 
			ORDER BY FiscalYear, [Period]

			INSERT INTO #GLBalance (LeafNodeId, AccountingPeriodId, DebitAmount, CreaditAmount,  Amount,GLAccountId, JournalNumber, JournalBatchDetailId, EntryDate, PeriodNameDistinct, IsManualJournal)
			(SELECT DISTINCT LF.LeafNodeId , @AccountcalID, 
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

				--SET @MAXCalTempID = @MAXCalTempID - 1;
			--END
		
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
						  SELECT
							LeafNodeId,[Name],IsPositive,ParentId,0,@AccountcalID, @periodNameDistinct
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
						SET Amount =  CASE  WHEN IsPositive = 1 THEN 
												  (SELECT SUM(ISNULL(T.Amount, 0)) FROM #TempTable T  WHERE T.ParentId = @CLID AND T.periodNameDistinct = @periodNameDistinct)
									  ELSE ISNULL((SELECT SUM(ISNULL(T.Amount, 0))FROM #TempTable T WHERE T.ParentId = @CLID AND T.periodNameDistinct = @periodNameDistinct) , 0) * -1
									  END
					 WHERE ID = @CID
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

		  --SELECT * FROM #TempTable
		  --SELECT * FROM #GLBalance

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

		  --ReferenceName
		  UPDATE #AccTrendTable 
				SET ReferenceModule = CASE WHEN (UPPER(DM.DistributionCode) = 'WOMATERIALGRIDTAB' OR UPPER(DM.DistributionCode) = 'WOLABORTAB' OR UPPER(DM.DistributionCode) = 'WOSETTLEMENTTAB' 
												OR UPPER(DM.DistributionCode) = 'WOINVOICINGTAB' OR UPPER(DM.DistributionCode) = 'MROWOSHIPMENT')  AND (UPPER(CB.ModuleName) <> 'CREDITMEMO') THEN 'WO' 
										    WHEN (UPPER(DM.DistributionCode) = 'WOMATERIALGRIDTAB' OR UPPER(DM.DistributionCode) = 'WOLABORTAB' OR UPPER(DM.DistributionCode) = 'WOSETTLEMENTTAB' 
												OR UPPER(DM.DistributionCode) = 'WOINVOICINGTAB' OR UPPER(DM.DistributionCode) = 'MROWOSHIPMENT')  AND (UPPER(CB.ModuleName) = 'CREDITMEMO') THEN 'CUSTOMER CREDIT MEMO' 
											
											WHEN (UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT') AND (UPPER(CB.ModuleName) <> 'CREDITMEMO') THEN 'SO'    
											WHEN (UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT') AND (UPPER(CB.ModuleName)  = 'CREDITMEMO') THEN 'CUSTOMER CREDIT MEMO' 
											
											WHEN UPPER(DM.DistributionCode) = 'RECEIVINGPOSTOCKLINE' THEN 'RPO'  
											WHEN UPPER(DM.DistributionCode) = 'RECEIVINGROSTOCKLINE' THEN 'RRO' 
											WHEN UPPER(DM.DistributionCode) = 'MROWOSHIPMENT' THEN 'WO' 
											WHEN UPPER(DM.DistributionCode) = 'CHECKPAYMENT' THEN 'CHEQUE' 
											WHEN UPPER(DM.DistributionCode) = 'ASSETINVENTORY' THEN 'ASSET'
											WHEN UPPER(DM.DistributionCode) = 'VENDORRMA' THEN 'VENDOR CREDIT MEMO'
											WHEN UPPER(DM.DistributionCode) = 'MANUALSTOCKLINE' THEN 'STOCKLINE'
											WHEN UPPER(DM.DistributionCode) = 'CASHRECEIPTSTRADERECEIVABLE' THEN 'CASH RECEIPT'
											WHEN UPPER(DM.DistributionCode) = 'STOCKLINEADJUSTMENT' THEN 'STKADJ'
											WHEN UPPER(DM.DistributionCode) = 'EX-ShIPMENT' OR UPPER(DM.DistributionCode) = 'EX-FEEBILLING' 
													OR UPPER(DM.DistributionCode) = 'EX-REPAIRBILLING' THEN 'EXCH'
											WHEN UPPER(DM.DistributionCode) = 'CMDISACC' THEN 'CMDISACC'
											WHEN UPPER(DM.DistributionCode) = 'WIRETRANSFER' THEN 'WIRETRAN'
											WHEN UPPER(DM.DistributionCode) = 'ACHTRANSFER' THEN 'ACHTRAN'
											WHEN UPPER(DM.DistributionCode) = 'CREDITCARDPAYMENT' THEN 'CCPAY'
											WHEN UPPER(DM.DistributionCode) = 'RECONCILIATIONRO' OR UPPER(DM.DistributionCode) = 'RECONCILIATIONPO'  THEN 'RECONCILIATION'
											WHEN UPPER(DM.DistributionCode) = 'NONPOINVOICE' THEN 'NONPO'
											WHEN UPPER(DM.DistributionCode) = 'CRFD' THEN 'CRFD'
											WHEN UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTQTY' OR UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTUNITCOST' 
											OR UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTINTERCOTRANSLE' OR UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTINTRACOTRANSDIV' THEN 'BSADJ'
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
											WHEN UPPER(DM.DistributionCode) = 'CASHRECEIPTSTRADERECEIVABLE' THEN CRBD.CustomerName
											WHEN UPPER(DM.DistributionCode) = 'STOCKLINEADJUSTMENT' THEN ''
											WHEN UPPER(DM.DistributionCode) = 'EX-ShIPMENT' OR UPPER(DM.DistributionCode) = 'EX-FEEBILLING' 
													OR UPPER(DM.DistributionCode) = 'EX-REPAIRBILLING' THEN ExchC.[Name]
											WHEN UPPER(DM.DistributionCode) = 'CMDISACC' THEN ''
											WHEN UPPER(DM.DistributionCode) = 'WIRETRANSFER' THEN ''
											WHEN UPPER(DM.DistributionCode) = 'ACHTRANSFER' THEN ''
											WHEN UPPER(DM.DistributionCode) = 'CREDITCARDPAYMENT' THEN ''
											WHEN UPPER(DM.DistributionCode) = 'RECONCILIATIONRO' OR UPPER(DM.DistributionCode) = 'RECONCILIATIONPO'  THEN ''
											WHEN UPPER(DM.DistributionCode) = 'NONPOINVOICE' THEN NPOBD.VendorName
											WHEN UPPER(DM.DistributionCode) = 'CRFD' THEN ''
											WHEN UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTQTY' OR UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTUNITCOST' 
											OR UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTINTERCOTRANSLE' OR UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTINTRACOTRANSDIV' THEN ''
											ELSE '' END,
					Referenceid = CASE WHEN (UPPER(DM.DistributionCode) = 'WOMATERIALGRIDTAB' OR UPPER(DM.DistributionCode) = 'WOLABORTAB' OR UPPER(DM.DistributionCode) = 'WOSETTLEMENTTAB' 
												OR UPPER(DM.DistributionCode) = 'WOINVOICINGTAB' OR UPPER(DM.DistributionCode) = 'MROWOSHIPMENT') AND (UPPER(CB.ModuleName) <> 'CREDITMEMO') THEN WBD.ReferenceId
											
											WHEN (UPPER(DM.DistributionCode) = 'WOMATERIALGRIDTAB' OR UPPER(DM.DistributionCode) = 'WOLABORTAB' OR UPPER(DM.DistributionCode) = 'WOSETTLEMENTTAB' 
												OR UPPER(DM.DistributionCode) = 'WOINVOICINGTAB' OR UPPER(DM.DistributionCode) = 'MROWOSHIPMENT') AND (UPPER(CB.ModuleName) = 'CREDITMEMO') THEN CMBD.ReferenceId	
											
											--WHEN UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT' THEN SBD.SalesOrderId   
											WHEN (UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT') AND (UPPER(CB.ModuleName) <> 'CREDITMEMO') THEN SBD.SalesOrderId  
											WHEN (UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT') AND (UPPER(CB.ModuleName)  = 'CREDITMEMO') THEN CMBD.ReferenceId	

											WHEN UPPER(DM.DistributionCode) = 'RECEIVINGPOSTOCKLINE' THEN SD.PoId  
											WHEN UPPER(DM.DistributionCode) = 'RECEIVINGROSTOCKLINE' THEN SD.RoId
											WHEN UPPER(DM.DistributionCode) = 'MROWOSHIPMENT' THEN WBD.ReferenceId 
											WHEN UPPER(DM.DistributionCode) = 'CHECKPAYMENT' THEN VPBD.ReferenceId
											WHEN UPPER(DM.DistributionCode) = 'ASSETINVENTORY' THEN SD.PoId
											WHEN UPPER(DM.DistributionCode) = 'VENDORRMA' THEN VRBD.ReferenceId
											WHEN UPPER(DM.DistributionCode) = 'MANUALSTOCKLINE' THEN 0		
											WHEN UPPER(DM.DistributionCode) = 'CASHRECEIPTSTRADERECEIVABLE' THEN CRBD.ReferenceId
											WHEN UPPER(DM.DistributionCode) = 'STOCKLINEADJUSTMENT' THEN 0
											WHEN UPPER(DM.DistributionCode) = 'EX-ShIPMENT' OR UPPER(DM.DistributionCode) = 'EX-FEEBILLING' 
													OR UPPER(DM.DistributionCode) = 'EX-REPAIRBILLING' THEN EXBD.ExchangeSalesOrderId
											WHEN UPPER(DM.DistributionCode) = 'CMDISACC' THEN 0
											WHEN UPPER(DM.DistributionCode) = 'WIRETRANSFER' THEN VPBD.ReferenceId
											WHEN UPPER(DM.DistributionCode) = 'ACHTRANSFER' THEN VPBD.ReferenceId
											WHEN UPPER(DM.DistributionCode) = 'CREDITCARDPAYMENT' THEN VPBD.ReferenceId
											WHEN UPPER(DM.DistributionCode) = 'RECONCILIATIONRO' OR UPPER(DM.DistributionCode) = 'RECONCILIATIONPO'  THEN SD.ReferenceId
											WHEN UPPER(DM.DistributionCode) = 'NONPOINVOICE' THEN NPOBD.NonPOInvoiceId
											WHEN UPPER(DM.DistributionCode) = 'CRFD' THEN RFCM.CreditMemoHeaderId
											WHEN UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTQTY' OR UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTUNITCOST' 
													OR UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTINTERCOTRANSLE' OR UPPER(DM.DistributionCode) = 'BULKSTOCKLINEADJUSTMENTINTRACOTRANSDIV' THEN BSAD.ReferenceId
											ELSE '' END,
					CustomerId = CASE WHEN UPPER(DM.DistributionCode) = 'SOINVOICE' OR UPPER(DM.DistributionCode) = 'SO_SHIPMENT' THEN SBD.CustomerId 
									  WHEN UPPER(DM.DistributionCode) = 'EX-ShIPMENT' OR UPPER(DM.DistributionCode) = 'EX-FEEBILLING' 
													OR UPPER(DM.DistributionCode) = 'EX-REPAIRBILLING' THEN ExchC.CustomerId
								ELSE '' END,
					LastMSLevel = CB.LastMSLevel,
					AllMSlevels = CB.AllMSlevels,
					IsStandAloneCM = CM.IsStandAloneCM
		  FROM #AccTrendTable tmp 
			  JOIN [dbo].[CommonBatchDetails] CB WITH (NOLOCK) ON tmp.JournalBatchDetailId = cb.JournalBatchDetailId 
			  JOIN [dbo].[DistributionSetup] DS WITH (NOLOCK) ON DS.ID = CB.DistributionSetupId
			  JOIN [dbo].[DistributionMaster] DM WITH (NOLOCK) ON DS.DistributionMasterId = DM.ID
			  LEFT JOIN [dbo].[WorkOrderBatchDetails] WBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = WBD.JournalBatchDetailId 
			  LEFT JOIN [dbo].[SalesOrderBatchDetails] SBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = SBD.JournalBatchDetailId 
			  LEFT JOIN [dbo].[StocklineBatchDetails] SD WITH (NOLOCK) ON tmp.JournalBatchDetailId = SD.JournalBatchDetailId 
			  LEFT JOIN [dbo].[VendorPaymentBatchDetails] VPBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = VPBD.JournalBatchDetailId 
			  LEFT JOIN [dbo].[VendorRMAPaymentBatchDetails] VRBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = VRBD.JournalBatchDetailId 
			  LEFT JOIN [dbo].[CustomerReceiptBatchDetails] CRBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = CRBD.JournalBatchDetailId 
			  LEFT JOIN [dbo].[BulkStocklineAdjPaymentBatchDetails] BSAD WITH (NOLOCK) ON tmp.JournalBatchDetailId = BSAD.JournalBatchDetailId 
			  LEFT JOIN [dbo].[CreditMemoPaymentBatchDetails] CMBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = CMBD.JournalBatchDetailId 		
			  LEFT JOIN [dbo].[RefundCreditMemoMapping] RFCM WITH (NOLOCK) ON CMBD.ReferenceId  = RFCM.CustomerRefundId AND RFCM.CustomerRefundId =
			  (
				 SELECT TOP 1 RCMP.[CustomerRefundId] FROM [dbo].[RefundCreditMemoMapping] RCMP WITH (NOLOCK) 
				 WHERE RCMP.[CustomerRefundId] = RFCM.[CustomerRefundId]
			  ) AND CMBD.ModuleId = @CustomerRefundModuleId			  			  
			  LEFT JOIN [dbo].[ExchangeBatchDetails] EXBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = EXBD.JournalBatchDetailId 
			  LEFT JOIN [dbo].[NonPOInvoiceBatchDetails] NPOBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = NPOBD.JournalBatchDetailId 
			  LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.VendorId = VRBD.VendorId
			  LEFT JOIN [dbo].[Customer] ExchC WITH (NOLOCK) ON ExchC.CustomerId = EXBD.CustomerId
			  LEFT JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.CreditMemoHeaderId = RFCM.CreditMemoHeaderId
		WHERE ISNULL(tmp.IsManualJournal, 0) = 0

		UPDATE #AccTrendTable 
					SET ReferenceModule = CASE WHEN tmp.IsManualJournal = 1 THEN 'MANUAL JE' ELSE ReferenceModule END,
						ReferenceName = CASE WHEN tmp.IsManualJournal = 1 THEN MJH.JournalNumber ELSE ReferenceName END,
						Referenceid = CASE WHEN tmp.IsManualJournal = 1 THEN MJD.ManualJournalHeaderId ELSE tmp.Referenceid END,
						LastMSLevel = CASE WHEN ISNULL(tmp.IsManualJournal, 0) = 1 THEN  MJD.LastMSLevel ELSE MJD.LastMSLevel END,
						AllMSlevels = CASE WHEN ISNULL(tmp.IsManualJournal, 0) = 1 THEN MJD.AllMSlevels ELSE MJD.AllMSlevels END
			 FROM #AccTrendTable tmp 
			 JOIN dbo.ManualJournalHeader MJH WITH (NOLOCK) ON MJH.ManualJournalHeaderId = tmp.JournalBatchDetailId
			 JOIN dbo.ManualJournalDetails MJD WITH (NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
			 WHERE ISNULL(tmp.IsManualJournal, 0) = 1

		  ;WITH cte
			AS
			(
			   SELECT LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel, AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, 
				SUM(ISNULL(CreditAmount, 0) - ISNULL(DebitAmount, 0)) Amount , IsManualJournal ,IsStandAloneCM
			   FROM #AccTrendTable
			   GROUP BY LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, IsManualJournal,IsStandAloneCM 

			), cteRanked AS
			(
			   SELECT Amount, LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, 
				ROW_NUMBER() OVER(ORDER BY LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate) rownum, IsManualJournal ,IsStandAloneCM
			   FROM cte
			) 
			SELECT (SELECT SUM(Amount) FROM cteRanked c2 WHERE c2.rownum <= c1.rownum) AS Amount,
			  LeafNodeId, UPPER(NodeName) AS NodeName, GLAccountId, (UPPER(GLAccountCode) + '-' + UPPER(GLAccountName)) AS GLAccount, UPPER(JournalNumber) AS JournalNumber, LastMSLevel,  AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriodId, UPPER(AccountingPeriod) AS AccountingPeriod, UPPER(PeriodName) AS PeriodName, ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, 
				Cast(DBO.ConvertUTCtoLocal(EntryDate, @CurrntEmpTimeZoneDesc) as datetime) AS EntryDate, IsManualJournal ,IsStandAloneCM				
			FROM cteRanked c1 
			WHERE GLAccountId IS NOT NULL
			ORDER BY AccountingPeriodId, JournalNumber;


 END TRY  
 BEGIN CATCH  
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
					  , @AdhocComments     VARCHAR(150)    = 'USP_GetJournalEntriesDetailsByLeafNodeId_BalanceSheet' 
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