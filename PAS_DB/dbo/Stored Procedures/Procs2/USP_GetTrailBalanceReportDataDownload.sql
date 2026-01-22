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
     
--EXEC [USP_GetTrailBalanceReportData] '1','1','128',1,0
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetTrailBalanceReportDataDownload]
(
	@masterCompanyId VARCHAR(50)  = NULL,
	@managementStructureId VARCHAR(50) = NULL,
	@id VARCHAR(50) = NULL,
	@id2 BIT = NULL,
	@id6 BIT = NULL
)
AS
BEGIN
	BEGIN TRY
	BEGIN

		DECLARE @PeriodId VARCHAR(50) = @id
		DECLARE @IsSupressZero BIT = @id2		
		DECLARE @LegalEntityId BIGINT =0;
		DECLARE @Type VARCHAR(100) = '';
		DECLARE @FiscalYear varchar(20) = ''
		IF OBJECT_ID(N'tempdb..#TEMP') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMP
		END 
		IF OBJECT_ID(N'tempdb..#Temptbl') IS NOT NULL    
		BEGIN    
			DROP TABLE #Temptbl
		END 


		CREATE TABLE #TEMP(        
		 ID BIGINT  IDENTITY(1,1),        
		 GlAccountId BIGINT NULL,
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

		DECLARE @FromDate DATETIME = NULL
		DECLARE @ToDate DATETIME = NULL
		DECLARE @PeriodEndDate DATETIME = NULL

		SELECT @FromDate = StartDate,@ToDate = EndDate,@LegalEntityId = LegalEntityId,@Type= PeriodType,@FiscalYear = FiscalYear,
		@PeriodEndDate = ToDate
		FROM AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @PeriodId

		print(@FromDate)
		print(@todate)

		--INSERT INTO #TEMP(GlAccountId,Credit,Debit,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,
		--Level6Name,Level7Name,Level8Name,Level9Name,Level10Name)

		;WITH RESULT AS(
		SELECT CB.GlAccountId 'GlAccountId',ISNULL(CB.CreditAmount,0) 'Credit',ISNULL(CB.DebitAmount,0) 'Debit',
		CASE WHEN @id6 = 0 THEN CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] ELSE  CAST(MSL1.Code AS VARCHAR(250)) END AS Level1Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] ELSE  CAST(MSL2.Code AS VARCHAR(250)) END AS Level2Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] ELSE  CAST(MSL3.Code AS VARCHAR(250)) END AS Level3Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] ELSE  CAST(MSL4.Code AS VARCHAR(250)) END AS Level4Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] ELSE  CAST(MSL5.Code AS VARCHAR(250)) END AS Level5Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] ELSE  CAST(MSL6.Code AS VARCHAR(250)) END AS Level6Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] ELSE  CAST(MSL7.Code AS VARCHAR(250)) END AS Level7Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] ELSE  CAST(MSL8.Code AS VARCHAR(250)) END AS Level8Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] ELSE  CAST(MSL9.Code AS VARCHAR(250)) END AS Level9Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE  CAST(MSL10.Code AS VARCHAR(250)) END AS Level10Name,
		GC.SequenceNumber
		FROM dbo.CommonBatchDetails CB WITH (NOLOCK)
		INNER JOIN BatchDetails BD ON CB.JournalBatchDetailId = BD.JournalBatchDetailId
		AND BD.StatusId = (SELECT TOP 1 Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE Name = 'Posted')
		INNER JOIN BatchHeader B WITH (NOLOCK) ON BD.JournalBatchHeaderId = B.JournalBatchHeaderId 
		INNER JOIN dbo.EntityStructureSetup ESS WITH(NOLOCK) ON CB.ManagementStructureId = ESS.EntityStructureId
		INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON CB.GlAccountId = GL.GLAccountId
		LEFT JOIN dbo.GLAccountClass GC WITH(NOLOCK) ON GL.GLAccountTypeId = GC.GLAccountClassId
		LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON ESS.Level2Id = MSL2.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON ESS.Level3Id = MSL3.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON ESS.Level4Id = MSL4.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL5 WITH (NOLOCK) ON ESS.Level5Id = MSL5.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL6 WITH (NOLOCK) ON ESS.Level6Id = MSL6.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL7 WITH (NOLOCK) ON ESS.Level7Id = MSL7.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL8 WITH (NOLOCK) ON ESS.Level8Id = MSL8.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL9 WITH (NOLOCK) ON ESS.Level9Id = MSL9.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON ESS.Level10Id = MSL10.ID
		WHERE 
			CB.IsDeleted = 0 AND CB.ManagementStructureId = @ManagementStructureId AND
			--CAST(CB.TransactionDate AS DATE) BETWEEN CAST(@FromDate AS date) AND CAST(@PeriodEndDate AS date) AND
			CB.MasterCompanyId = @MasterCompanyId
			AND BD.AccountingPeriodId IN (SELECT AccountingCalendarId FROM AccountingCalendar 
			WHERE LegalEntityId = @LegalEntityId AND PeriodType = @Type AND FiscalYear = @FiscalYear
			AND CAST(StartDate AS DATE) >= CAST(@FromDate AS date) AND CAST(ToDate AS DATE) <= CAST(@PeriodEndDate AS date) )
		UNION ALL

		SELECT CB.GlAccountId 'GlAccountId',ISNULL(Credit,0) 'Credit',ISNULL(Debit,0) 'Debit',
		CASE WHEN @id6 = 0 THEN CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] ELSE  CAST(MSL1.Code AS VARCHAR(250)) END AS Level1Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] ELSE  CAST(MSL2.Code AS VARCHAR(250)) END AS Level2Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] ELSE  CAST(MSL3.Code AS VARCHAR(250)) END AS Level3Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] ELSE  CAST(MSL4.Code AS VARCHAR(250)) END AS Level4Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] ELSE  CAST(MSL5.Code AS VARCHAR(250)) END AS Level5Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] ELSE  CAST(MSL6.Code AS VARCHAR(250)) END AS Level6Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] ELSE  CAST(MSL7.Code AS VARCHAR(250)) END AS Level7Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] ELSE  CAST(MSL8.Code AS VARCHAR(250)) END AS Level8Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] ELSE  CAST(MSL9.Code AS VARCHAR(250)) END AS Level9Name,
		CASE WHEN @id6 = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE  CAST(MSL10.Code AS VARCHAR(250)) END AS Level10Name,
		GC.SequenceNumber
		FROM dbo.ManualJournalDetails CB WITH (NOLOCK)
		INNER JOIN ManualJournalHeader B WITH (NOLOCK) ON CB.ManualJournalHeaderId = B.ManualJournalHeaderId
		INNER JOIN dbo.EntityStructureSetup ESS WITH(NOLOCK) ON CB.ManagementStructureId = ESS.EntityStructureId
		INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON CB.GlAccountId = GL.GLAccountId
		LEFT JOIN dbo.GLAccountClass GC WITH(NOLOCK) ON GL.GLAccountTypeId = GC.GLAccountClassId
		LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON ESS.Level2Id = MSL2.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON ESS.Level3Id = MSL3.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON ESS.Level4Id = MSL4.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL5 WITH (NOLOCK) ON ESS.Level5Id = MSL5.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL6 WITH (NOLOCK) ON ESS.Level6Id = MSL6.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL7 WITH (NOLOCK) ON ESS.Level7Id = MSL7.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL8 WITH (NOLOCK) ON ESS.Level8Id = MSL8.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL9 WITH (NOLOCK) ON ESS.Level9Id = MSL9.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON ESS.Level10Id = MSL10.ID
		WHERE 
			CB.IsDeleted = 0 AND CB.ManagementStructureId = @ManagementStructureId AND
			--CAST(B.EntryDate AS DATE) BETWEEN CAST(@FromDate AS date) AND CAST(@PeriodEndDate AS date) 
			CB.MasterCompanyId = @MasterCompanyId AND 
			B.AccountingPeriodId IN (SELECT AccountingCalendarId FROM AccountingCalendar WHERE LegalEntityId = @LegalEntityId 
			AND PeriodType = @Type AND FiscalYear = @FiscalYear 
			AND CAST(StartDate AS DATE) >= CAST(@FromDate AS date) AND CAST(ToDate AS DATE) <= CAST(@PeriodEndDate AS date))
			AND B.ManualJournalStatusId = (SELECT TOP 1 ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE Name = 'Posted')
		)


		INSERT INTO #TEMP(GlAccountId,Credit,Debit,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,
		Level6Name,Level7Name,Level8Name,Level9Name,Level10Name,SequenceNumber)
		SELECT GlAccountId,SUM(ISNULL(Credit,0)),SUM(ISNULL(Debit,0)),Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,
		Level6Name,Level7Name,Level8Name,Level9Name,Level10Name,SequenceNumber FROM RESULT 
		GROUP BY GlAccountId,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,
		Level6Name,Level7Name,Level8Name,Level9Name,Level10Name,SequenceNumber


		--;WITH RESULT AS(
		INSERT INTO #Temptbl(GlAccountId,EntityStructureId,MasterCompanyId,
			Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,Level7Name,Level8Name,Level9Name,Level10Name,
			CreditAmount,DebitAmount,SequenceNumber)
		SELECT
			CMB.GlAccountId,ESS.EntityStructureId, ESS.[MasterCompanyId], 
			CASE WHEN @id6 = 0 THEN CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] ELSE  CAST(MSL1.Code AS VARCHAR(250)) END  AS Level1Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] ELSE  CAST(MSL2.Code AS VARCHAR(250)) END AS Level2Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] ELSE  CAST(MSL3.Code AS VARCHAR(250)) END AS Level3Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] ELSE  CAST(MSL4.Code AS VARCHAR(250)) END AS Level4Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] ELSE  CAST(MSL5.Code AS VARCHAR(250)) END AS Level5Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] ELSE  CAST(MSL6.Code AS VARCHAR(250)) END AS Level6Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] ELSE  CAST(MSL7.Code AS VARCHAR(250)) END AS Level7Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] ELSE  CAST(MSL8.Code AS VARCHAR(250)) END AS Level8Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] ELSE  CAST(MSL9.Code AS VARCHAR(250)) END AS Level9Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE  CAST(MSL10.Code AS VARCHAR(250)) END AS Level10Name,
			ISNULL(CMB.CreditAmount,0) 'CreditAmount',
			ISNULL(CMB.DebitAmount,0) 'DebitAmount',
			GC.SequenceNumber
			FROM dbo.CommonBatchDetails CMB WITH(NOLOCK)
			INNER JOIN BatchDetails BD ON CMB.JournalBatchDetailId = BD.JournalBatchDetailId AND BD.StatusId = (SELECT TOP 1 Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE Name = 'Posted')
			INNER JOIN BatchHeader B WITH (NOLOCK) ON BD.JournalBatchHeaderId = B.JournalBatchHeaderId
			INNER JOIN dbo.EntityStructureSetup ESS WITH(NOLOCK) ON CMB.ManagementStructureId = ESS.EntityStructureId
			INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON CMB.GlAccountId = GL.GLAccountId
			LEFT JOIN dbo.GLAccountClass GC WITH(NOLOCK) ON GL.GLAccountTypeId = GC.GLAccountClassId
			LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON ESS.Level2Id = MSL2.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON ESS.Level3Id = MSL3.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON ESS.Level4Id = MSL4.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL5 WITH (NOLOCK) ON ESS.Level5Id = MSL5.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL6 WITH (NOLOCK) ON ESS.Level6Id = MSL6.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL7 WITH (NOLOCK) ON ESS.Level7Id = MSL7.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL8 WITH (NOLOCK) ON ESS.Level8Id = MSL8.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL9 WITH (NOLOCK) ON ESS.Level9Id = MSL9.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON ESS.Level10Id = MSL10.ID
			WHERE CMB.ManagementStructureId = @ManagementStructureId AND CMB.IsDeleted = 0 AND
			CMB.MasterCompanyId = @MasterCompanyId  AND BD.AccountingPeriodId = @PeriodId

		UNION ALL

		SELECT
			CMB.GlAccountId,ESS.EntityStructureId, ESS.[MasterCompanyId], 
			CASE WHEN @id6 = 0 THEN CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] ELSE  CAST(MSL1.Code AS VARCHAR(250)) END  AS Level1Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] ELSE  CAST(MSL2.Code AS VARCHAR(250)) END AS Level2Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] ELSE  CAST(MSL3.Code AS VARCHAR(250)) END AS Level3Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] ELSE  CAST(MSL4.Code AS VARCHAR(250)) END AS Level4Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] ELSE  CAST(MSL5.Code AS VARCHAR(250)) END AS Level5Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] ELSE  CAST(MSL6.Code AS VARCHAR(250)) END AS Level6Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] ELSE  CAST(MSL7.Code AS VARCHAR(250)) END AS Level7Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] ELSE  CAST(MSL8.Code AS VARCHAR(250)) END AS Level8Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] ELSE  CAST(MSL9.Code AS VARCHAR(250)) END AS Level9Name,
			CASE WHEN @id6 = 0 THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] ELSE  CAST(MSL10.Code AS VARCHAR(250)) END AS Level10Name,
			ISNULL(CMB.Credit,0) 'CreditAmount',
			ISNULL(CMB.Debit,0) 'DebitAmount',
			GC.SequenceNumber
			FROM dbo.ManualJournalDetails CMB WITH(NOLOCK)
			INNER JOIN dbo.ManualJournalHeader BH WITH (NOLOCK) ON CMB.ManualJournalHeaderId = BH.ManualJournalHeaderId
			INNER JOIN dbo.EntityStructureSetup ESS WITH(NOLOCK) ON CMB.ManagementStructureId = ESS.EntityStructureId
			INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON CMB.GlAccountId = GL.GLAccountId
			LEFT JOIN dbo.GLAccountClass GC WITH(NOLOCK) ON GL.GLAccountTypeId = GC.GLAccountClassId
			LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON ESS.Level2Id = MSL2.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON ESS.Level3Id = MSL3.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON ESS.Level4Id = MSL4.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL5 WITH (NOLOCK) ON ESS.Level5Id = MSL5.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL6 WITH (NOLOCK) ON ESS.Level6Id = MSL6.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL7 WITH (NOLOCK) ON ESS.Level7Id = MSL7.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL8 WITH (NOLOCK) ON ESS.Level8Id = MSL8.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL9 WITH (NOLOCK) ON ESS.Level9Id = MSL9.ID
			LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON ESS.Level10Id = MSL10.ID
			WHERE CMB.ManagementStructureId = @ManagementStructureId AND CMB.IsDeleted = 0 AND
				CMB.MasterCompanyId = @MasterCompanyId  AND AccountingPeriodId = @PeriodId
				AND BH.ManualJournalStatusId = (SELECT TOP 1 ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE Name = 'Posted')
		
		IF(@IsSupressZero = 1)
		BEGIN
		print '3'
		;WITH RESULT AS(
		SELECT YTD.GlAccountId,
			GL.AccountCode 'accountNum',
			GL.AccountName 'accountName',
			YTD.Level1Name,YTD.Level2Name,
			YTD.Level3Name,YTD.Level4Name,
			YTD.Level5Name,YTD.Level6Name,
			YTD.Level7Name,YTD.Level8Name,
			YTD.Level9Name,YTD.Level10Name,
			CASE WHEN (SUM(ISNULL(R.DebitAmount,0)) - SUM(ISNULL(R.CreditAmount,0))) > 0 THEN 0 
			ELSE ABS(SUM(ISNULL(R.DebitAmount,0)) - SUM(ISNULL(R.CreditAmount,0))) END  'Credit',
			
			CASE WHEN (SUM(ISNULL(R.DebitAmount,0)) - SUM(ISNULL(R.CreditAmount,0))) > 0 THEN 
				SUM(ISNULL(R.DebitAmount,0)) - SUM(ISNULL(R.CreditAmount,0))
				ELSE 0 END  'Debit',
			--SUM(R.CreditAmount) 'Credit',
			--SUM(R.DebitAmount) 'Debit',
			CASE WHEN (ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) > 0 THEN 
				ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)
				ELSE 0 END  'DR',

			CASE WHEN (ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) > 0 THEN 
				0 ELSE ABS(ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) END  'CR',
			--YTD.Credit 'CR',
			--YTD.Debit 'DR',
			YTD.SequenceNumber
		FROM #TEMP YTD
			LEFT JOIN  #Temptbl R  ON  YTD.GlAccountId = R.GlAccountId 
			INNER JOIN GLAccount GL WITH (NOLOCK) ON YTD.GlAccountId = GL.GLAccountId
		GROUP BY 
			YTD.GlAccountId,GL.AccountCode,GL.AccountName,
			YTD.Level1Name,YTD.Level2Name,
			YTD.Level3Name,YTD.Level4Name,
			YTD.Level5Name,YTD.Level6Name,
			YTD.Level7Name,YTD.Level8Name,
			YTD.Level9Name,YTD.Level10Name,
			YTD.Credit,YTD.Debit,YTD.SequenceNumber
			)

			SELECT GlAccountId,accountNum,accountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
			Level7Name,Level8Name,Level9Name,Level10Name,Credit,Debit,CR,DR FROM RESULT 
			WHERE Credit > 0 OR Debit > 0 OR CR > 0 OR DR > 0
			ORDER BY SequenceNumber
		END
		ELSE
		BEGIN 
		print '4'
		;WITH RESULT AS(
			SELECT YTD.GlAccountId,
			GL.AccountCode 'accountNum',
			GL.AccountName 'accountName',
			YTD.Level1Name,YTD.Level2Name,
			YTD.Level3Name,YTD.Level4Name,
			YTD.Level5Name,YTD.Level6Name,
			YTD.Level7Name,YTD.Level8Name,
			YTD.Level9Name,YTD.Level10Name,
			--SUM(R.CreditAmount) 'Credit',
			--SUM(R.DebitAmount) 'Debit',
			CASE WHEN (SUM(ISNULL(R.DebitAmount,0)) - SUM(ISNULL(R.CreditAmount,0))) > 0 THEN 0 
			ELSE ABS(SUM(ISNULL(R.DebitAmount,0)) - SUM(ISNULL(R.CreditAmount,0))) END  'Credit',
			CASE WHEN (SUM(ISNULL(R.DebitAmount,0)) - SUM(ISNULL(R.CreditAmount,0))) > 0 THEN
				SUM(ISNULL(R.DebitAmount,0)) - SUM(ISNULL(R.CreditAmount,0))
			ELSE 0 END  'Debit',
			CASE WHEN (ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) > 0 THEN 
				ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)
				ELSE 0 END  'DR',

			CASE WHEN (ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) > 0 THEN 
				0 ELSE ABS(ISNULL(YTD.Debit,0) - ISNULL(YTD.Credit,0)) END  'CR',
			--YTD.Credit 'CR',
			--YTD.Debit 'DR',
			YTD.SequenceNumber
		FROM #TEMP YTD
			LEFT JOIN  #Temptbl R  ON  YTD.GlAccountId = R.GlAccountId 
			INNER JOIN GLAccount GL WITH (NOLOCK) ON YTD.GlAccountId = GL.GLAccountId
		GROUP BY 
			YTD.GlAccountId,GL.AccountCode,GL.AccountName,
			YTD.Level1Name,YTD.Level2Name,
			YTD.Level3Name,YTD.Level4Name,
			YTD.Level5Name,YTD.Level6Name,
			YTD.Level7Name,YTD.Level8Name,
			YTD.Level9Name,YTD.Level10Name,
			YTD.Credit,YTD.Debit,YTD.SequenceNumber
			
			)

			SELECT GlAccountId,accountNum,accountName,Level1Name,Level2Name,Level3Name,Level4Name,Level5Name,Level6Name,
			Level7Name,Level8Name,Level9Name,Level10Name,Credit,Debit,CR,DR FROM RESULT
			ORDER BY SequenceNumber
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
							   @DatabaseName           = @DatabaseName
							 , @AdhocComments          = @AdhocComments
							 , @ProcedureParameters = @ProcedureParameters
							 , @ApplicationName        =  @ApplicationName
							 , @ErrorLogID                    = @ErrorLogID OUTPUT ;
					  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
					  RETURN(1);
	END CATCH

END