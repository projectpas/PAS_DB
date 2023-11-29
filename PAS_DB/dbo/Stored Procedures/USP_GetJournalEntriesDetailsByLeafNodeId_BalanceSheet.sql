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
	1    06/09/2023   Rajesh Gami  Created
**************************************************************/  

/*************************************************************             

EXEC [USP_GetJournalEntriesDetailsByLeafNodeId_BalanceSheet]
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
		  DECLARE @AccountcalID AS bigint;
		  DECLARE @AccountPeriods VARCHAR(max);  
		  DECLARE @AccountPeriodIds VARCHAR(max);  
		  DECLARE @LegalEntityId BIGINT;
		  DECLARE @PostedBatchStatusId BIGINT;
		  DECLARE @ManualJournalStatusId BIGINT;
		  DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		  DECLARE @AssetGLAccountTypeId AS BIGINT;
		  DECLARE @LiabilitiesGLAccountTypeId AS BIGINT;
		  DECLARE @EquityGLAccountTypeId AS BIGINT;
		  DECLARE @BatchMSModuleId BIGINT; 
		  DECLARE @ManualBatchMSModuleId BIGINT; 
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
		  SELECT @ManualJournalStatusId =  ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Manual Batch Details Only
		  SELECT @AssetGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Asset' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		  SELECT @LiabilitiesGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Liabilities' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
	      SELECT @EquityGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Owners Equity' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1

		  SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
		  WHERE LE.LegalEntityId = @LegalEntityId;
		  
		  SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID
		  SET @ManualBatchMSModuleId = 73 -- MANUAL BATCH MS MODULE ID

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
		  ToDate DATETIME NULL
		  )
		  
		  INSERT INTO #AccPeriodTable (AccountcalID, PeriodName, FromDate, ToDate) 
		  SELECT AccountingCalendarId, REPLACE(PeriodName,' - ','') ,FromDate,ToDate
		  FROM dbo.AccountingCalendar WITH(NOLOCK)
		  WHERE LegalEntityId = @LegalEntityId
		  --LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) 
		  and IsDeleted = 0 and  
		  	 CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) AND ISNULL(IsAdjustPeriod, 0) = 0 
		  
		  INSERT INTO #AccPeriodTable (AccountcalID, PeriodName) 
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
		  
		  INSERT INTO #AccPeriodTable_All (AccountcalID, PeriodName, FromDate, ToDate) 
		  SELECT AccountingCalendarId, REPLACE(PeriodName,' - ',' ') ,FromDate,ToDate
		  FROM dbo.AccountingCalendar WITH(NOLOCK)
		  WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) and IsDeleted = 0 and  
		   CAST(Fromdate AS DATE) >= CAST(@INITIALFROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) AND ISNULL(IsAdjustPeriod, 0) = 0  
		   ORDER BY FiscalYear, [Period]
		  --INSERT INTO #AccPeriodTable_All (AccountcalID, PeriodName) 
		  --VALUES(9999999,'Total')

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
		  )
		  
		SELECT @MAXCalTempID = MAX(ID) fROM #AccPeriodTable
		WHILE(@MAXCalTempID > 0)
		BEGIN

			SELECT  @AccountcalID = AccountcalID, @INITIALENDDATE = ToDate FROM #AccPeriodTable where ID = @MAXCalTempID AND AccountcalID NOT IN(9999999)

				INSERT INTO #GLBalance (LeafNodeId, AccountingPeriodId, DebitAmount, CreaditAmount,  Amount,GLAccountId, JournalNumber, JournalBatchDetailId, EntryDate)
		(SELECT DISTINCT LF.LeafNodeId , @AccountcalID, 
						CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END 'DebitAmount',
						CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END 'CreditAmount',
						(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END) - 
						(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) AS AMONUT
						,CMD.GLAccountId, BD.JournalTypeNumber, BD.JournalBatchDetailId, CONVERT(DATETIME, CMD.EntryDate, 120)
		FROM dbo.CommonBatchDetails CMD WITH (NOLOCK)
			INNER JOIN dbo.BatchDetails BD WITH (NOLOCK) ON CMD.JournalBatchDetailId = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
			INNER JOIN dbo.BatchHeader B WITH (NOLOCK) ON BD.JournalBatchHeaderId = B.JournalBatchHeaderId 
			INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = CMD.CommonJournalBatchDetailId AND ModuleId = @BatchMSModuleId
			INNER JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON CMD.GlAccountId = GLM.GLAccountId
	
			INNER JOIN dbo.GLAccount GL WITH (NOLOCK) ON GL.GlAccountId = GLM.GLAccountId AND GL.GLAccountTypeId IN (@AssetGLAccountTypeId, @LiabilitiesGLAccountTypeId,@EquityGLAccountTypeId) 
			INNER JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0 AND ISNULL(ReportingStructureId, 0) = @ReportingStructureId 
		WHERE CMD.IsDeleted = 0 AND GLM.IsDeleted = 0 AND BD.IsDeleted = 0 AND CMD.MasterCompanyId = @MasterCompanyId AND CMD.GLAccountId = @GLAccountId 	
				--AND BD.AccountingPeriodId = @AccountcalID
				AND BD.AccountingPeriodId IN (SELECT AccountcalID FROm #AccPeriodTable_All) AND ISNULL(B.IsDeleted,0) = 0
				--AND BD.PostedDate BETWEEN @INITIALFROMDATE AND @INITIALENDDATE
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
		GROUP BY LF.LeafNodeId , GLM.IsPositive, CMD.GLAccountId, BD.JournalTypeNumber, BD.JournalBatchDetailId, CONVERT(DATETIME, CMD.EntryDate, 120)

		UNION ALL

		SELECT	DISTINCT LF.LeafNodeId ,@AccountcalID, 
				CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Debit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Debit, 0)), 0) * -1 END 'DebitAmount',
						CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Credit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Credit, 0)), 0) * -1 END 'CreditAmount',
				(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Debit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Debit, 0)), 0) * -1 END) - 
						(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(MJD.Credit, 0)) ELSE ISNULL(SUM(ISNULL(MJD.Credit, 0)), 0) * -1 END) AS AMONUT
						,MJD.GlAccountId, MJH.JournalNumber, 0 AS JournalBatchDetailId, CONVERT(DATETIME, MJH.EntryDate, 120)
			FROM dbo.ManualJournalDetails MJD WITH (NOLOCK) 
				JOIN dbo.GLAccount GL ON MJD.GlAccountId = GL.GLAccountId AND GL.GLAccountTypeId IN (@AssetGLAccountTypeId, @LiabilitiesGLAccountTypeId,@EquityGLAccountTypeId) 
				JOIN dbo.ManualJournalHeader MJH  WITH (NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
				JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON MJD.GlAccountId = GLM.GLAccountId AND GLM.IsDeleted = 0
				JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = MJD.ManualJournalDetailsId AND MSD.ModuleId = @ManualBatchMSModuleId
				JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0
					 AND ISNULL(ReportingStructureId, 0) = @ReportingStructureId
			WHERE GLM.GLAccountId = MJD.GlAccountId  AND MJH.ManualJournalStatusId = @ManualJournalStatusId AND MJD.GlAccountId = @GLAccountId
					AND MJD.MasterCompanyId = @MasterCompanyId AND MJD.IsDeleted = 0 AND MJH.IsDeleted = 0
					AND MJH.AccountingPeriodId IN (SELECT AccountcalID FROm #AccPeriodTable_All)
					--AND MJH.PostedDate BETWEEN @INITIALFROMDATE AND @INITIALENDDATE
					AND MJH.ManualJournalStatusId = @ManualJournalStatusId 
					--AND MJH.AccountingPeriodId = @AccountcalID
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
			GROUP BY  LF.LeafNodeId , GLM.IsPositive, MJD.GlAccountId, MJH.JournalNumber, CONVERT(DATETIME, MJH.EntryDate, 120))

			SET @MAXCalTempID = @MAXCalTempID - 1;
		END
		--SELECT * FROm #GLBalance
		  DECLARE @LID AS int = 0;
		  DECLARE @IsFristRow AS bit = 1;
		  DECLARE @LCOUNT AS int = 0;
		  SELECT @LCOUNT = MAX(ID) fROM #AccPeriodTable

		  WHILE(@LCOUNT > 0)
		  BEGIN
			SELECT  @AccountcalID = AccountcalID ,@INITIALENDDATE = ToDate FROM #AccPeriodTable where ID = @LCOUNT AND ID NOT IN(9999999)

			INSERT INTO #TempTable (LeafNodeId, [Name], IsPositive, ParentId, IsProcess,AccountingPeriodId)
						  SELECT
							LeafNodeId,[Name],IsPositive,ParentId,0,@AccountcalID
							  FROM dbo.LeafNode
							  WHERE LeafNodeId = @LeafNodeId
								  AND IsDeleted = 0
								  AND ReportingStructureId = @ReportingStructureId

			DECLARE @CID AS int = 0;
			DECLARE @CLID AS int = 0;

			SELECT TOP 1 @CID = ID, @CLID = LeafNodeId
						FROM #TempTable
								WHERE IsProcess = 0 and AccountingPeriodId = @AccountcalID
								ORDER BY ID

			WHILE (@CLID > 0)
			BEGIN
				INSERT INTO #TempTable (LeafNodeId, [Name], IsPositive, ParentId, IsProcess,AccountingPeriodId)
									SELECT  LeafNodeId, [Name], IsPositive,  @CLID, 0,@AccountcalID
											FROM dbo.LeafNode
												  WHERE ParentId = @CLID
													AND IsDeleted = 0
													AND ReportingStructureId = @ReportingStructureId ORDER BY SequenceNumber DESC

				SET @CLID = 0;
				UPDATE #TempTable SET IsProcess = 1 WHERE ID = @CID AND AccountingPeriodId = @AccountcalID
				IF EXISTS (SELECT TOP 1 ID FROM #TempTable  WHERE IsProcess = 0 AND AccountingPeriodId = @AccountcalID)
				 BEGIN
						SELECT TOP 1 @CID = ID, @CLID = LeafNodeId
									FROM #TempTable
											WHERE IsProcess = 0
												   AND AccountingPeriodId = @AccountcalID
											ORDER BY ID
				 END
			END

			UPDATE #TempTable
			SET ChildCount = ISNULL((SELECT COUNT(ISNULL(T.Amount, 0))
                                           FROM #TempTable T
                                                WHERE T.ParentId = T1.LeafNodeId AND T.AccountingPeriodId = @AccountcalID), 0),
                Amount = CASE WHEN T1.IsPositive = 1 THEN Amount
				              ELSE ISNULL(Amount, 0) * -1
                         END
				FROM #TempTable T1 WHERE  T1.AccountingPeriodId = @AccountcalID
		
			UPDATE #TempTable SET IsProcess = 0  WHERE  AccountingPeriodId = @AccountcalID

			SET @CID = 0;
			SET @CLID = 0;
			SELECT TOP 1 @CID = ID
					FROM #TempTable
						WHERE IsProcess = 0 AND AccountingPeriodId = @AccountcalID
							  ORDER BY ID DESC

			WHILE (@CID > 0)
				BEGIN
				SELECT TOP 1 @CLID = LeafNodeId
						FROM #TempTable
							WHERE ID = @CID AND AccountingPeriodId = @AccountcalID

				UPDATE #TempTable
						SET Amount =  CASE  WHEN IsPositive = 1 THEN 
												  (SELECT SUM(ISNULL(T.Amount, 0)) FROM #TempTable T  WHERE T.ParentId = @CLID AND T.AccountingPeriodId = @AccountcalID)
									  ELSE ISNULL((SELECT SUM(ISNULL(T.Amount, 0))FROM #TempTable T WHERE T.ParentId = @CLID AND T.AccountingPeriodId = @AccountcalID) , 0) * -1
									  END
					 WHERE ID = @CID
						   AND ChildCount > 0 AND AccountingPeriodId = @AccountcalID
				UPDATE #TempTable  SET IsProcess = 1 WHERE ID = @CID AND AccountingPeriodId = @AccountcalID

				  SET @CID = 0;
				  SET @CLID = 0;
				  IF EXISTS (SELECT TOP 1 ID FROM #TempTable WHERE IsProcess = 0 AND AccountingPeriodId = @AccountcalID)
				  BEGIN
						SELECT TOP 1 @CID = ID
							   FROM #TempTable
									WHERE IsProcess = 0
										  AND AccountingPeriodId = @AccountcalID
										   ORDER BY ID DESC
			   END
			END


			UPDATE #TempTable SET IsProcess = 0,
					   TotalAmount = (SELECT SUM(ISNULL(T.Amount,0)) FROM #TempTable T WHERE T.ParentId = T1.LeafNodeId AND T.AccountingPeriodId = @AccountcalID)	 
					  FROM #TempTable T1 
					  WHERE T1.AccountingPeriodId = @AccountcalID


			SET @CID = 0;
			SET @CLID = 0;
			SELECT TOP 1 @CID = ID
				   FROM #TempTable
						 WHERE IsProcess = 0
							   AND AccountingPeriodId = @AccountcalID
						 ORDER BY ID DESC
			
			WHILE (@CID > 0)
			BEGIN

				  SELECT TOP 1 @CLID = ParentId
							FROM #TempTable WHERE ID = @CID AND AccountingPeriodId = @AccountcalID

				  UPDATE #TempTable
						  SET IsProcess = 1
							 WHERE ID = @CID AND AccountingPeriodId = @AccountcalID

				  SET @CID = 0;
				  SET @CLID = 0;

				  IF EXISTS (SELECT TOP 1 ID  FROM #TempTable WHERE IsProcess = 0 AND AccountingPeriodId = @AccountcalID)
				  BEGIN
					SELECT TOP 1  @CID = ID
							 FROM #TempTable
								 WHERE IsProcess = 0
								 AND AccountingPeriodId = @AccountcalID
									ORDER BY ID DESC
				  END

			END
			
			SET @IsFristRow = 0
			SET @LCOUNT = @LCOUNT -1
		  END

		  --SELECT * FROM #TempTable

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
		  )

		  DECLARE @COUNT AS INT;
		  DECLARE @COUNTMAX AS INT
		  SELECT @COUNT = MIN(ID), @COUNTMAX = MAX(ID) fROM #AccPeriodTable
		  WHILE (@COUNT <= @COUNTMAX)
		  BEGIN

			  SELECT  @AccountcalID = AccountcalID,@INITIALENDDATE = ToDate FROM #AccPeriodTable where ID = @COUNT AND ID NOT IN(9999999)		  
			  
			  INSERT INTO #AccTrendTable(LeafNodeId, NodeName, GLAccountId, GLAccountCode, GLAccountName, JournalNumber, JournalBatchDetailId, CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName, EntryDate) --, ReferenceId, DistributionSetupCode)
			  SELECT T.LeafNodeId, T.[Name] , GL.GLAccountId, GLA.AccountCode, GLA.AccountName, JournalNumber, JournalBatchDetailId, GL.CreaditAmount, DebitAmount, GL.AccountingPeriodId, AP.PeriodName, REPLACE(AP.PeriodName ,' - ',' '), EntryDate  --CBD.ReferenceId, CBD.DistributionSetupCode, EntryDate 
			  FROM #TempTable T  
				  JOIN #GLBalance GL ON T.AccountingPeriodId = @AccountcalID AND T.LeafNodeId = GL.LeafNodeId AND T.AccountingPeriodId = GL.AccountingPeriodId
				  JOIN dbo.GLAccount GLA WITH (NOLOCK) ON GLA.GLAccountId = GL.GLAccountId
				  LEFT JOIN #AccPeriodTable AP ON AP.AccountcalID = T.AccountingPeriodId
			  WHERE GL.GLAccountId = @GLAccountId
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

		  --LEFT JOIN dbo. WBD WITH (NOLOCK) ON tmp.JournalBatchDetailId = WBD.JournalBatchDetailId

		  ;WITH cte
			AS
			(
			   SELECT LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel, AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, 
				SUM(ISNULL(CreditAmount, 0) - ISNULL(DebitAmount, 0)) Amount 
			   FROM #AccTrendTable
			   GROUP BY LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate

			), cteRanked AS
			(
			   SELECT Amount, LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate, 
				ROW_NUMBER() OVER(ORDER BY LeafNodeId, NodeName, GLAccountId, GLAccountCode , GLAccountName , JournalNumber, LastMSLevel,  AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriodId, AccountingPeriod, PeriodName , ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, EntryDate) rownum
			   FROM cte
			) 
			SELECT (SELECT SUM(Amount) FROM cteRanked c2 WHERE c2.rownum <= c1.rownum) AS Amount,
			  LeafNodeId, UPPER(NodeName) AS NodeName, GLAccountId, (UPPER(GLAccountCode) + '-' + UPPER(GLAccountName)) AS GLAccount, UPPER(JournalNumber) AS JournalNumber, LastMSLevel,  AllMSlevels,
				CreditAmount, DebitAmount, AccountingPeriodId, UPPER(AccountingPeriod) AS AccountingPeriod, UPPER(PeriodName) AS PeriodName, ReferenceModule, ReferenceName, ReferenceId, CustomerId, DistributionSetupCode, 
				Cast(DBO.ConvertUTCtoLocal(EntryDate, @CurrntEmpTimeZoneDesc) as datetime) AS EntryDate				
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