/*************************************************************           
 ** File:   [USP_GetTrailBalanceReportData]           
 ** Author: Hemant Saliya
 ** Description: This stored procedure is used retrieve Partnumber and stockline userd
 ** Purpose:         
 ** Date:   06/20/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/20/2023   Hemant Saliya Created	
	2    06/22/2023   Satish Gohil  Modify(Optimisation and short MS changes)
	3	 07/04/2023   Satish Gohil  Manual Journal Entry added in Report
	4    07/05/2023   Satish Gohil  Year calculation count issue fixed
	5    08/08/2023   Devendra Shekh Glaccountid column added 
	6    09/01/2023   Hemant Saliya  Added MS Filters	 

exec dbo.USP_GetTrailBalanceReportData @masterCompanyId=1,@managementStructureId=1,@AccountingPeriodId=135,@IsSupressZero=1,@IsShortMS=1,@strFilter=N'1!2,7!3,11,10!4,12'
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetTrailBalanceReportData]
(
	@masterCompanyId VARCHAR(50)  = NULL,
	@managementStructureId VARCHAR(50) = NULL,
	@AccountingPeriodId BIGINT = NULL,
	@IsSupressZero BIT = NULL,
	@IsShortMS BIT = NULL,
	@strFilter VARCHAR(MAX) = NULL
)
AS
BEGIN
	BEGIN TRY
	BEGIN

		DECLARE @Type VARCHAR(100) = '';
		DECLARE @FiscalYear varchar(20) = ''
		DECLARE @FromDate DATETIME = NULL
		DECLARE @INITIALFROMDATE  DATETIME = NULL
		DECLARE @ToDate DATETIME = NULL
		DECLARE @PeriodEndDate DATETIME = NULL
		DECLARE @BatchMSModuleId BIGINT; 
		DECLARE @ManualBatchMSModuleId BIGINT; 
		DECLARE @PostedBatchStatusId BIGINT;
		DECLARE @ManualJournalStatusId BIGINT;
		DECLARE @StatisticalGLAccountTypeId BIGINT;
		DECLARE @PeriodName VARCHAR(100) = '';
		DECLARE @xml XML;

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

		IF OBJECT_ID(N'tempdb..#TEMP') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMP
		END 
		IF OBJECT_ID(N'tempdb..#Temptbl') IS NOT NULL    
		BEGIN    
			DROP TABLE #Temptbl
		END 
		IF OBJECT_ID(N'tempdb..#TempResults') IS NOT NULL    
		BEGIN    
			DROP TABLE #TempResults
		END 

		CREATE TABLE #TEMP(        
			 ID BIGINT  IDENTITY(1,1),        
			 GlAccountId BIGINT NULL,
			 EntityStructureId BIGINT,
			 MasterCompanyId INT,
			 Level1Name VARCHAR(100),
			 Level2Name VARCHAR(100),
			 Level3Name VARCHAR(100),
			 Level4Name VARCHAR(100),
			 Level5Name VARCHAR(100),
			 Level6Name VARCHAR(100),
			 Level7Name VARCHAR(100),
			 Level8Name VARCHAR(100),
			 Level9Name VARCHAR(100),
			 Level10Name VARCHAR(100),
			 Credit decimal(18,2),
			 Debit decimal(18,2),
			 SequenceNumber INT
		 ) 

		CREATE TABLE #Temptbl(        
			 ID BIGINT  IDENTITY(1,1),         
			 GlAccountId BIGINT,
			 EntityStructureId BIGINT,
			 MasterCompanyId INT,
			 Level1Name VARCHAR(100),
			 Level2Name VARCHAR(100),
			 Level3Name VARCHAR(100),
			 Level4Name VARCHAR(100),
			 Level5Name VARCHAR(100),
			 Level6Name VARCHAR(100),
			 Level7Name VARCHAR(100),
			 Level8Name VARCHAR(100),
			 Level9Name VARCHAR(100),
			 Level10Name VARCHAR(100),
			 CreditAmount decimal(18,2),
			 DebitAmount decimal(18,2),
			 SequenceNumber INT
		 ) 

		CREATE TABLE #TempResults(        
			 ID BIGINT  IDENTITY(1,1),         
			 GlAccountId BIGINT,
			 AccountNum VARCHAR(200),
			 AccountName VARCHAR(200),
			 EntityStructureId BIGINT,
			 MasterCompanyId INT,
			 Level1Name VARCHAR(100),
			 Level2Name VARCHAR(100),
			 Level3Name VARCHAR(100),
			 Level4Name VARCHAR(100),
			 Level5Name VARCHAR(100),
			 Level6Name VARCHAR(100),
			 Level7Name VARCHAR(100),
			 Level8Name VARCHAR(100),
			 Level9Name VARCHAR(100),
			 Level10Name VARCHAR(100),
			 MonthlyCreditAmount decimal(18,2),
			 MonthlyDebitAmount decimal(18,2),
			 YTDCreditAmount decimal(18,2),
			 YTDDebitAmount decimal(18,2),
			 SequenceNumber INT
		 ) 

		 CREATE TABLE #TempFinalResults(        
			 ID BIGINT  IDENTITY(1,1),         
			 GlAccountId BIGINT,
			 AccountNum VARCHAR(200),
			 AccountName VARCHAR(200),
			 EntityStructureId BIGINT,
			 Level1Name VARCHAR(100),
			 Level2Name VARCHAR(100),
			 Level3Name VARCHAR(100),
			 Level4Name VARCHAR(100),
			 Level5Name VARCHAR(100),
			 Level6Name VARCHAR(100),
			 Level7Name VARCHAR(100),
			 Level8Name VARCHAR(100),
			 Level9Name VARCHAR(100),
			 Level10Name VARCHAR(100),
			 Credit decimal(18,2),
			 Debit decimal(18,2),
			 CR decimal(18,2),
			 DR decimal(18,2),
			 SequenceNumber INT
		 ) 

		SELECT @FromDate = StartDate, @ToDate = EndDate, @Type= PeriodType, @FiscalYear = FiscalYear, @PeriodEndDate = ToDate, @PeriodName = UPPER(PeriodName)
		FROM dbo.AccountingCalendar WITH(NOLOCK) 
		WHERE AccountingCalendarId = @AccountingPeriodId

		--SELECT @FiscalYear

		SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID
		SET @ManualBatchMSModuleId = 73 -- MANUAL BATCH MS MODULE ID
		SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
		SELECT @ManualJournalStatusId =  ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Manual Batch Details Only
		SELECT @StatisticalGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE UPPER(GLAccountClassName) = 'STATISTICAL' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1

		SELECT @INITIALFROMDATE = MIN(StartDate) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE FiscalYear = @FiscalYear
		
		IF OBJECT_ID(N'tempdb..#AccPeriodTable_All') IS NOT NULL
	    BEGIN
		   DROP TABLE #AccPeriodTable_All
	    END
		  
		CREATE TABLE #AccPeriodTable_All (
		    ID bigint NOT NULL IDENTITY (1, 1),
		    AccountcalID BIGINT NULL,
			LegalEntityId BIGINT NULL,
			FiscalYear BIGINT NULL,
		    PeriodName VARCHAR(100) NULL,
			FromDate DATETIME NULL,
			ToDate DATETIME NULL
		)

		INSERT INTO #AccPeriodTable_All (AccountcalID, LegalEntityId, FiscalYear, PeriodName, FromDate, ToDate) 
		SELECT AccountingCalendarId, LegalEntityId, @FiscalYear, PeriodName , FromDate, ToDate
		FROM dbo.AccountingCalendar WITH(NOLOCK)		
		WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
				AND IsDeleted = 0 AND CAST(Fromdate AS DATE) >= CAST(@INITIALFROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@PeriodEndDate AS DATE) 
				AND ISNULL(IsAdjustPeriod, 0) = 0 AND FiscalYear = @FiscalYear
		ORDER BY FiscalYear, [Period]

		;WITH RESULT AS(
			SELECT DISTINCT CB.GlAccountId 'GlAccountId', MSD.EntityMSID AS EntityStructureId, CB.[MasterCompanyId],  SUM(ISNULL(CB.CreditAmount,0)) 'Credit', SUM(ISNULL(CB.DebitAmount,0)) 'Debit',
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] ELSE  CAST(MSL1.Code AS VARCHAR(250)) END AS Level1Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] ELSE  CAST(MSL2.Code AS VARCHAR(250)) END AS Level2Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] ELSE  CAST(MSL3.Code AS VARCHAR(250)) END AS Level3Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] ELSE  CAST(MSL4.Code AS VARCHAR(250)) END AS Level4Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] ELSE  CAST(MSL5.Code AS VARCHAR(250)) END AS Level5Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] ELSE  CAST(MSL6.Code AS VARCHAR(250)) END AS Level6Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] ELSE  CAST(MSL7.Code AS VARCHAR(250)) END AS Level7Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] ELSE  CAST(MSL8.Code AS VARCHAR(250)) END AS Level8Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] ELSE  CAST(MSL9.Code AS VARCHAR(250)) END AS Level9Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE  CAST(MSL10.Code AS VARCHAR(250)) END AS Level10Name,
				GC.SequenceNumber
			FROM dbo.CommonBatchDetails CB WITH (NOLOCK)
				INNER JOIN dbo.BatchDetails BD ON CB.JournalBatchDetailId = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
				INNER JOIN dbo.BatchHeader B WITH (NOLOCK) ON BD.JournalBatchHeaderId = B.JournalBatchHeaderId 
				INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = CB.CommonJournalBatchDetailId AND ModuleId = @BatchMSModuleId
				INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON CB.GlAccountId = GL.GLAccountId AND GL.GLAccountTypeId NOT IN (@StatisticalGLAccountTypeId)  
				LEFT JOIN dbo.GLAccountClass GC WITH(NOLOCK) ON GL.GLAccountTypeId = GC.GLAccountClassId
				LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL5 WITH (NOLOCK) ON MSD.Level5Id = MSL5.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL6 WITH (NOLOCK) ON MSD.Level6Id = MSL6.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL7 WITH (NOLOCK) ON MSD.Level7Id = MSL7.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL8 WITH (NOLOCK) ON MSD.Level8Id = MSL8.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL9 WITH (NOLOCK) ON MSD.Level9Id = MSL9.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
			WHERE CB.IsDeleted = 0 AND CB.MasterCompanyId = @MasterCompanyId AND BD.IsDeleted = 0 AND B.IsDeleted = 0 AND ISNULL(CB.IsVersionIncrease, 0) = 0	
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
			GROUP BY CB.GlAccountId,MSD.EntityMSID, CB.[MasterCompanyId],MSL1.Code,MSL2.Code,MSL3.Code,MSL4.Code,
					 MSL5.Code,MSL6.Code,MSL7.Code, MSL8.Code, MSL9.Code,MSL10.Code,MSL1.[Description],MSL2.[Description],
					 MSL3.[Description],MSL4.[Description],MSL5.[Description],MSL6.[Description],MSL7.[Description],
					 MSL8.[Description],MSL9.[Description],MSL10.[Description], GC.SequenceNumber
		
		UNION ALL

			SELECT DISTINCT CB.GlAccountId 'GlAccountId', MSD.EntityMSID AS EntityStructureId, CB.[MasterCompanyId], SUM(ISNULL(Credit,0)) 'Credit', SUM(ISNULL(Debit,0)) 'Debit',
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] ELSE  CAST(MSL1.Code AS VARCHAR(250)) END AS Level1Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] ELSE  CAST(MSL2.Code AS VARCHAR(250)) END AS Level2Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] ELSE  CAST(MSL3.Code AS VARCHAR(250)) END AS Level3Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] ELSE  CAST(MSL4.Code AS VARCHAR(250)) END AS Level4Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] ELSE  CAST(MSL5.Code AS VARCHAR(250)) END AS Level5Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] ELSE  CAST(MSL6.Code AS VARCHAR(250)) END AS Level6Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] ELSE  CAST(MSL7.Code AS VARCHAR(250)) END AS Level7Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] ELSE  CAST(MSL8.Code AS VARCHAR(250)) END AS Level8Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] ELSE  CAST(MSL9.Code AS VARCHAR(250)) END AS Level9Name,
				CASE WHEN @IsShortMS = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE  CAST(MSL10.Code AS VARCHAR(250)) END AS Level10Name,
				GC.SequenceNumber
			FROM dbo.ManualJournalDetails CB WITH (NOLOCK)
				INNER JOIN dbo.ManualJournalHeader B WITH (NOLOCK) ON CB.ManualJournalHeaderId = B.ManualJournalHeaderId
				INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = CB.ManualJournalDetailsId AND MSD.ModuleId = @ManualBatchMSModuleId
				INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON CB.GlAccountId = GL.GLAccountId  AND GL.GLAccountTypeId NOT IN (@StatisticalGLAccountTypeId)  
				LEFT JOIN dbo.GLAccountClass GC WITH(NOLOCK) ON GL.GLAccountTypeId = GC.GLAccountClassId
				LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL5 WITH (NOLOCK) ON MSD.Level5Id = MSL5.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL6 WITH (NOLOCK) ON MSD.Level6Id = MSL6.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL7 WITH (NOLOCK) ON MSD.Level7Id = MSL7.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL8 WITH (NOLOCK) ON MSD.Level8Id = MSL8.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL9 WITH (NOLOCK) ON MSD.Level9Id = MSL9.ID
				LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
			WHERE CB.MasterCompanyId = @MasterCompanyId AND B.ManualJournalStatusId = @ManualJournalStatusId  AND CB.IsDeleted = 0 AND B.IsDeleted = 0 AND
					B.AccountingPeriodId IN (SELECT AccountcalID FROM #AccPeriodTable_All)					
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
			GROUP BY CB.GlAccountId,MSD.EntityMSID, CB.[MasterCompanyId],MSL1.Code,MSL2.Code,MSL3.Code,MSL4.Code,
					 MSL5.Code,MSL6.Code,MSL7.Code, MSL8.Code, MSL9.Code,MSL10.Code,MSL1.[Description],MSL2.[Description],
					 MSL3.[Description],MSL4.[Description],MSL5.[Description],MSL6.[Description],MSL7.[Description],
					 MSL8.[Description],MSL9.[Description],MSL10.[Description], GC.SequenceNumber
		)

		INSERT INTO #TEMP(GlAccountId,EntityStructureId, MasterCompanyId, Credit,Debit,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,
							Level6Name,Level7Name,Level8Name,Level9Name,Level10Name,SequenceNumber)
		SELECT GlAccountId, EntityStructureId, MasterCompanyId,SUM(ISNULL(Credit,0)),SUM(ISNULL(Debit,0)),Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,
			  Level6Name,Level7Name,Level8Name,Level9Name,Level10Name,SequenceNumber FROM RESULT 
		GROUP BY GlAccountId,EntityStructureId, MasterCompanyId, Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,
			  Level6Name,Level7Name,Level8Name,Level9Name,Level10Name,SequenceNumber

		INSERT INTO #Temptbl(GlAccountId,EntityStructureId,MasterCompanyId,
			Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,Level7Name,Level8Name,Level9Name,Level10Name,
			CreditAmount,DebitAmount,SequenceNumber)
		SELECT DISTINCT
			CMB.GlAccountId,MSD.EntityMSID AS EntityStructureId, CMB.[MasterCompanyId], 
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] ELSE  CAST(MSL1.Code AS VARCHAR(250)) END  AS Level1Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] ELSE  CAST(MSL2.Code AS VARCHAR(250)) END AS Level2Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] ELSE  CAST(MSL3.Code AS VARCHAR(250)) END AS Level3Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] ELSE  CAST(MSL4.Code AS VARCHAR(250)) END AS Level4Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] ELSE  CAST(MSL5.Code AS VARCHAR(250)) END AS Level5Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] ELSE  CAST(MSL6.Code AS VARCHAR(250)) END AS Level6Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] ELSE  CAST(MSL7.Code AS VARCHAR(250)) END AS Level7Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] ELSE  CAST(MSL8.Code AS VARCHAR(250)) END AS Level8Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] ELSE  CAST(MSL9.Code AS VARCHAR(250)) END AS Level9Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE  CAST(MSL10.Code AS VARCHAR(250)) END AS Level10Name,
			SUM(ISNULL(CMB.CreditAmount,0)) 'CreditAmount', 
			SUM(ISNULL(CMB.DebitAmount,0)) 'DebitAmount',
			GC.SequenceNumber
		FROM dbo.CommonBatchDetails CMB WITH(NOLOCK)
			INNER JOIN dbo.BatchDetails BD WITH(NOLOCK) ON CMB.JournalBatchDetailId = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
			INNER JOIN dbo.BatchHeader B WITH (NOLOCK) ON BD.JournalBatchHeaderId = B.JournalBatchHeaderId
			INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = CMB.CommonJournalBatchDetailId AND ModuleId = @BatchMSModuleId
			INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON CMB.GlAccountId = GL.GLAccountId AND GL.GLAccountTypeId NOT IN (@StatisticalGLAccountTypeId)  
			LEFT JOIN dbo.GLAccountClass GC WITH(NOLOCK) ON GL.GLAccountTypeId = GC.GLAccountClassId
			LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL5 WITH (NOLOCK) ON MSD.Level5Id = MSL5.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL6 WITH (NOLOCK) ON MSD.Level6Id = MSL6.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL7 WITH (NOLOCK) ON MSD.Level7Id = MSL7.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL8 WITH (NOLOCK) ON MSD.Level8Id = MSL8.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL9 WITH (NOLOCK) ON MSD.Level9Id = MSL9.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
		WHERE CMB.IsDeleted = 0 AND BD.IsDeleted = 0 AND B.IsDeleted = 0 AND CMB.MasterCompanyId = @MasterCompanyId AND ISNULL(CMB.IsVersionIncrease, 0) = 0	
			AND BD.AccountingPeriodId IN (SELECT AccountcalID FROM #AccPeriodTable_All WHERE UPPER(PeriodName) = @PeriodName)
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
		GROUP BY CMB.GlAccountId,MSD.EntityMSID, CMB.[MasterCompanyId],MSL1.Code,MSL2.Code,MSL3.Code,MSL4.Code,
					 MSL5.Code,MSL6.Code,MSL7.Code, MSL8.Code, MSL9.Code,MSL10.Code,MSL1.[Description],MSL2.[Description],
					 MSL3.[Description],MSL4.[Description],MSL5.[Description],MSL6.[Description],MSL7.[Description],
					 MSL8.[Description],MSL9.[Description],MSL10.[Description], GC.SequenceNumber

		UNION ALL

		SELECT DISTINCT
			CMB.GlAccountId,MSD.EntityMSID AS EntityStructureId, CMB.[MasterCompanyId], 
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] ELSE  CAST(MSL1.Code AS VARCHAR(250)) END  AS Level1Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] ELSE  CAST(MSL2.Code AS VARCHAR(250)) END AS Level2Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] ELSE  CAST(MSL3.Code AS VARCHAR(250)) END AS Level3Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] ELSE  CAST(MSL4.Code AS VARCHAR(250)) END AS Level4Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] ELSE  CAST(MSL5.Code AS VARCHAR(250)) END AS Level5Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] ELSE  CAST(MSL6.Code AS VARCHAR(250)) END AS Level6Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] ELSE  CAST(MSL7.Code AS VARCHAR(250)) END AS Level7Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] ELSE  CAST(MSL8.Code AS VARCHAR(250)) END AS Level8Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] ELSE  CAST(MSL9.Code AS VARCHAR(250)) END AS Level9Name,
			CASE WHEN @IsShortMS = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE  CAST(MSL10.Code AS VARCHAR(250)) END AS Level10Name,
			SUM(ISNULL(CMB.Credit,0)) 'CreditAmount',
			SUM(ISNULL(CMB.Debit,0)) 'DebitAmount',
			GC.SequenceNumber
		FROM dbo.ManualJournalDetails CMB WITH(NOLOCK)
			INNER JOIN dbo.ManualJournalHeader BH WITH (NOLOCK) ON CMB.ManualJournalHeaderId = BH.ManualJournalHeaderId
			INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = CMB.ManualJournalDetailsId AND MSD.ModuleId = @ManualBatchMSModuleId
			INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON CMB.GlAccountId = GL.GLAccountId AND GL.GLAccountTypeId NOT IN (@StatisticalGLAccountTypeId)  
			LEFT JOIN dbo.GLAccountClass GC WITH(NOLOCK) ON GL.GLAccountTypeId = GC.GLAccountClassId
			LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL5 WITH (NOLOCK) ON MSD.Level5Id = MSL5.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL6 WITH (NOLOCK) ON MSD.Level6Id = MSL6.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL7 WITH (NOLOCK) ON MSD.Level7Id = MSL7.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL8 WITH (NOLOCK) ON MSD.Level8Id = MSL8.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL9 WITH (NOLOCK) ON MSD.Level9Id = MSL9.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
		WHERE CMB.IsDeleted = 0 AND BH.IsDeleted = 0 AND CMB.MasterCompanyId = @MasterCompanyId  AND AccountingPeriodId IN (SELECT AccountcalID FROM #AccPeriodTable_All WHERE UPPER(PeriodName) = @PeriodName) AND BH.ManualJournalStatusId = @ManualJournalStatusId
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
		GROUP BY CMB.GlAccountId,MSD.EntityMSID, CMB.[MasterCompanyId],MSL1.Code,MSL2.Code,MSL3.Code,MSL4.Code,
					 MSL5.Code,MSL6.Code,MSL7.Code, MSL8.Code, MSL9.Code,MSL10.Code,MSL1.[Description],MSL2.[Description],
					 MSL3.[Description],MSL4.[Description],MSL5.[Description],MSL6.[Description],MSL7.[Description],
					 MSL8.[Description],MSL9.[Description],MSL10.[Description], GC.SequenceNumber

		IF(@IsSupressZero = 1)
		BEGIN
			INSERT INTO #TempResults(GlAccountId,EntityStructureId, MasterCompanyId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
				Level7Name,Level8Name,Level9Name,Level10Name,YTDDebitAmount, YTDCreditAmount, SequenceNumber)
			SELECT DISTINCT YTD.GlAccountId, EntityStructureId, YTD.MasterCompanyId, GL.AccountCode,GL.AccountName,YTD.Level1Name,YTD.Level2Name,YTD.Level3Name,YTD.Level4Name,
				YTD.Level5Name,YTD.Level6Name,YTD.Level7Name,YTD.Level8Name,YTD.Level9Name,YTD.Level10Name,
				CASE WHEN (ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) > 0 THEN ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0) ELSE 0 END,
				CASE WHEN (ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) > 0 THEN 0 ELSE ABS(ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) END,
				YTD.SequenceNumber
			FROM #TEMP YTD
				INNER JOIN GLAccount GL WITH (NOLOCK) ON YTD.GlAccountId = GL.GLAccountId

			UPDATE #TempResults SET MonthlyCreditAmount = results.CreditAmount  FROM(
						SELECT T1.GlAccountId, T1.EntityStructureId,  CASE WHEN (SUM(ISNULL(T2.DebitAmount,0)) - SUM(ISNULL(T2.CreditAmount,0))) > 0 THEN 0 
												ELSE ABS(SUM(ISNULL(T2.DebitAmount,0)) - SUM(ISNULL(T2.CreditAmount,0))) END AS CreditAmount 
						FROM #TempResults T1 JOIN #Temptbl T2 ON T1.GlAccountId = T2.GlAccountId AND T1.EntityStructureId = T2.EntityStructureId
						GROUP BY T1.GlAccountId, T1.EntityStructureId
			) results WHERE results.GlAccountId = #TempResults.GlAccountId AND results.EntityStructureId = #TempResults.EntityStructureId

			UPDATE #TempResults SET MonthlyDebitAmount = results.DebitAmount  FROM(
						SELECT T1.GlAccountId, T1.EntityStructureId,  CASE WHEN (SUM(ISNULL(T2.DebitAmount,0)) - SUM(ISNULL(T2.CreditAmount,0))) > 0 THEN 
												SUM(ISNULL(T2.DebitAmount,0)) - SUM(ISNULL(T2.CreditAmount,0))ELSE 0 END AS DebitAmount 
						FROM #TempResults T1 JOIN #Temptbl T2 ON T1.GlAccountId = T2.GlAccountId AND T1.EntityStructureId = T2.EntityStructureId
						GROUP BY T1.GlAccountId, T1.EntityStructureId
			) results WHERE results.GlAccountId = #TempResults.GlAccountId AND results.EntityStructureId = #TempResults.EntityStructureId

			
			SELECT  GlAccountId,EntityStructureId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
				Level7Name,Level8Name,Level9Name,Level10Name,MonthlyCreditAmount AS Credit,MonthlyDebitAmount AS Debit, YTDCreditAmount AS CR,YTDDebitAmount AS DR 
			FROM #TempResults 
			WHERE MonthlyCreditAmount > 0 OR MonthlyDebitAmount > 0 OR YTDCreditAmount > 0 OR YTDDebitAmount > 0 --AND AccountNum LIKE '%[0-9]%'
			ORDER BY CAST(AccountNum AS BIGINT)

			--SELECT  GlAccountId,EntityStructureId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
			--	Level7Name,Level8Name,Level9Name,Level10Name,MonthlyCreditAmount AS Credit,MonthlyDebitAmount AS Debit, YTDCreditAmount AS CR,YTDDebitAmount AS DR 
			--FROM #TempResults 
			--WHERE MonthlyCreditAmount > 0 OR MonthlyDebitAmount > 0 OR YTDCreditAmount > 0 OR YTDDebitAmount > 0 AND AccountNum LIKE '%[0-9]%'
			--ORDER BY CAST(AccountNum AS BIGINT)

			--INSERT INTO #TempFinalResults(GlAccountId,EntityStructureId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
			--	Level7Name,Level8Name,Level9Name,Level10Name, Credit,Debit,CR,DR )
			--SELECT  GlAccountId,EntityStructureId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
			--	Level7Name,Level8Name,Level9Name,Level10Name,MonthlyCreditAmount AS Credit,MonthlyDebitAmount AS Debit, YTDCreditAmount AS CR,YTDDebitAmount AS DR 
			--FROM #TempResults 
			--WHERE MonthlyCreditAmount > 0 OR MonthlyDebitAmount > 0 OR YTDCreditAmount > 0 OR YTDDebitAmount > 0 AND AccountNum NOT LIKE '%[^0-9]%'
			--ORDER BY CAST(AccountNum AS BIGINT)

			--INSERT INTO #TempFinalResults(GlAccountId,EntityStructureId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
			--	Level7Name,Level8Name,Level9Name,Level10Name, Credit,Debit,CR,DR )
			--SELECT  GlAccountId,EntityStructureId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
			--	Level7Name,Level8Name,Level9Name,Level10Name,MonthlyCreditAmount AS Credit,MonthlyDebitAmount AS Debit, YTDCreditAmount AS CR,YTDDebitAmount AS DR 
			--FROM #TempResults 
			--WHERE MonthlyCreditAmount > 0 OR MonthlyDebitAmount > 0 OR YTDCreditAmount > 0 OR YTDDebitAmount > 0 AND AccountNum LIKE '%[^0-9]%'
			--ORDER BY AccountNum 

			--SELECT * FROM #TempFinalResults

		END
		ELSE
		BEGIN 

			INSERT INTO #TempResults(GlAccountId,EntityStructureId, MasterCompanyId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
				Level7Name,Level8Name,Level9Name,Level10Name,YTDDebitAmount, YTDCreditAmount, SequenceNumber)
			SELECT DISTINCT YTD.GlAccountId, EntityStructureId, YTD.MasterCompanyId, GL.AccountCode,GL.AccountName,YTD.Level1Name,YTD.Level2Name,YTD.Level3Name,YTD.Level4Name,
				YTD.Level5Name,YTD.Level6Name,YTD.Level7Name,YTD.Level8Name,YTD.Level9Name,YTD.Level10Name,
				CASE WHEN (ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) > 0 THEN ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0) ELSE 0 END,
				CASE WHEN (ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) > 0 THEN 0 ELSE ABS(ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) END,
				YTD.SequenceNumber
			FROM #TEMP YTD
				INNER JOIN GLAccount GL WITH (NOLOCK) ON YTD.GlAccountId = GL.GLAccountId

			UPDATE #TempResults SET MonthlyCreditAmount = results.CreditAmount  FROM(
						SELECT T1.GlAccountId, T1.EntityStructureId,  CASE WHEN (SUM(ISNULL(T2.DebitAmount,0)) - SUM(ISNULL(T2.CreditAmount,0))) > 0 THEN 0 
												ELSE ABS(SUM(ISNULL(T2.DebitAmount,0)) - SUM(ISNULL(T2.CreditAmount,0))) END AS CreditAmount 
						FROM #TempResults T1 JOIN #Temptbl T2 ON T1.GlAccountId = T2.GlAccountId AND T1.EntityStructureId = T2.EntityStructureId
						GROUP BY T1.GlAccountId, T1.EntityStructureId
			) results WHERE results.GlAccountId = #TempResults.GlAccountId AND results.EntityStructureId = #TempResults.EntityStructureId

			UPDATE #TempResults SET MonthlyDebitAmount = results.DebitAmount  FROM(
						SELECT T1.GlAccountId, T1.EntityStructureId,  CASE WHEN (SUM(ISNULL(T2.DebitAmount,0)) - SUM(ISNULL(T2.CreditAmount,0))) > 0 THEN 
												SUM(ISNULL(T2.DebitAmount,0)) - SUM(ISNULL(T2.CreditAmount,0))ELSE 0 END AS DebitAmount 
						FROM #TempResults T1 JOIN #Temptbl T2 ON T1.GlAccountId = T2.GlAccountId AND T1.EntityStructureId = T2.EntityStructureId
						GROUP BY T1.GlAccountId, T1.EntityStructureId
			) results WHERE results.GlAccountId = #TempResults.GlAccountId AND results.EntityStructureId = #TempResults.EntityStructureId

		
			SELECT  GlAccountId,EntityStructureId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
				Level7Name,Level8Name,Level9Name,Level10Name,MonthlyCreditAmount AS Credit,MonthlyDebitAmount AS Debit, YTDCreditAmount AS CR,YTDDebitAmount AS DR 
			FROM #TempResults 			
			ORDER BY CAST(AccountNum AS BIGINT)

			--INSERT INTO #TempFinalResults(GlAccountId,EntityStructureId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
			--	Level7Name,Level8Name,Level9Name,Level10Name, Credit,Debit,CR,DR )
			--SELECT  GlAccountId,EntityStructureId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
			--	Level7Name,Level8Name,Level9Name,Level10Name,MonthlyCreditAmount AS Credit,MonthlyDebitAmount AS Debit, YTDCreditAmount AS CR,YTDDebitAmount AS DR 
			--FROM #TempResults 
			--WHERE AccountNum NOT LIKE '%[^0-9]%'
			--ORDER BY CAST(AccountNum AS BIGINT)

			--INSERT INTO #TempFinalResults(GlAccountId,EntityStructureId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
			--	Level7Name,Level8Name,Level9Name,Level10Name, Credit,Debit,CR,DR )
			--SELECT  GlAccountId,EntityStructureId, AccountNum,AccountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
			--	Level7Name,Level8Name,Level9Name,Level10Name,MonthlyCreditAmount AS Credit,MonthlyDebitAmount AS Debit, YTDCreditAmount AS CR,YTDDebitAmount AS DR 
			--FROM #TempResults 		
			--WHERE AccountNum LIKE '%[^0-9]%'
			--ORDER BY AccountNum 

			--SELECT * FROM #TempFinalResults

		END
	END
	END TRY
	BEGIN CATCH
		 DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
					  , @AdhocComments     VARCHAR(150)    = 'usp_PostROCreateStocklineBatchDetails' 
					  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
					  , @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
					  exec spLogException 
							   @DatabaseName			= @DatabaseName
							 , @AdhocComments			= @AdhocComments
							 , @ProcedureParameters		= @ProcedureParameters
							 , @ApplicationName			= @ApplicationName
							 , @ErrorLogID              = @ErrorLogID OUTPUT ;
					  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
					  RETURN(1);
	END CATCH

END