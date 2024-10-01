/*************************************************************           
 ** File:   [USP_GetGeneralLedger_SearchList]           
 ** Author:    Devendra Shekh
 ** Description:  get general Ledger Search List
 ** Purpose:         
 ** Date:   02-SEP-2024
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------  
	1    09/02/2024   Devendra Shekh	     CREATED
	2    10/01/2024   Devendra Shekh	     Modifed to get all data while Download

exec USP_GetGeneralLedger_SearchList @PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N'',@FromEffectiveDate=NULL,@ToEffectiveDate=NULL,@FromJournalId=N'',@ToJournalId=N'',@FromGLAccount=NULL
,@ToGLAccount=NULL,@EmployeeId=2,@Level1=N'0',@Level2=N'0',@Level3=N'0',@Level4=N'0',@Level5=N'0',@Level6=N'0',@Level7=N'0',@Level8=N'0',@Level9=N'0',@Level10=N'0',
@ManagementStructureName=NULL,@AccountPeriodName=NULL,@DebitAmount=NULL,@CreditAmount=NULL,@Currency=NULL,
@DocumentNumber=NULL,@EffectiveDate=NULL,@EntryDate=NULL,@WOSONum=NULL,@PORONum=NULL,@Distribution=NULL,@JournalId=NULL,@GLAccountName=NULL,@TypeName=NULL,@MasterCompanyId=1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetGeneralLedger_SearchList]
	@PageSize INT,
	@PageNumber INT,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT,
	@GlobalFilter VARCHAR(50) = NULL,
	@FromEffectiveDate DATETIME2 = NULL,
	@ToEffectiveDate DATETIME2 = NULL,
	@FromJournalId VARCHAR(500) = NULL,
	@ToJournalId VARCHAR(500) = NULL,
	@FromGLAccount VARCHAR(500) = NULL,
	@ToGLAccount VARCHAR(500) = NULL,
	@EmployeeId BIGINT = NULL,
	@Level1 VARCHAR(500) = NULL,
	@Level2 VARCHAR(500) = NULL,
	@Level3 VARCHAR(500) = NULL,
	@Level4 VARCHAR(500) = NULL,
	@Level5 VARCHAR(500) = NULL,
	@Level6 VARCHAR(500) = NULL,
	@Level7 VARCHAR(500) = NULL,
	@Level8 VARCHAR(500) = NULL,
	@Level9 VARCHAR(500) = NULL,
	@Level10 VARCHAR(500) = NULL,
	@ManagementStructureName VARCHAR(500) = NULL,
	@AccountPeriodName VARCHAR(500) = NULL,
	@DebitAmount VARCHAR(500) = NULL,
	@CreditAmount VARCHAR(500) = NULL,
	@Currency VARCHAR(5000) = NULL,
	@DocumentNumber VARCHAR(200) = NULL,
	@EffectiveDate DATETIME2 = NULL,
	@EntryDate DATETIME2 = NULL,
	@WOSONum VARCHAR(256) = NULL,
	@PORONum VARCHAR(256) = NULL,
	@Distribution VARCHAR(256) = NULL,
	@JournalId VARCHAR(256) = NULL,
	@GLAccountName VARCHAR(256) = NULL,
	@TypeName VARCHAR(256) = NULL,
	@IsDownload BIT = NULL,
	@MasterCompanyId INT
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @RecordFrom INT;
		DECLARE @IsActive BIT=1
		DECLARE @Count INT;
		DECLARE @EmployeeName VARCHAR(80) = '';

		IF OBJECT_ID('tempdb..#TempJournalDetails') IS NOT NULL
			DROP TABLE #TempJournalDetails;

		IF OBJECT_ID('tempdb..#TempTotalAmount') IS NOT NULL
			DROP TABLE #TempTotalAmount;

		CREATE TABLE #TempJournalDetails
		(
			[RecordId] [bigint] IDENTITY(1,1),
			[CommonJournalBatchDetailId] [bigint] NULL,
			[AccountPeriodName] [varchar](50) NULL,
			[DebitAmount] [decimal](18,2) NULL,
			[CreditAmount] [decimal](18,2) NULL,
			[Currency] [varchar](20) NULL,
			[DocumentNumber] [varchar](100) NULL,
			[EffectiveDate] DATETIME2 NULL,
			[EntryDate] DATETIME2 NULL,
			[Distribution] [varchar](100) NULL,
			[JournalId] [varchar](100) NULL,
			[GLAccountName] [varchar](200) NULL,
			[TypeName] [varchar](200) NULL,
			[EmployeeName] [varchar](256) NULL,
			[Level1] [varchar](MAX) NULL,
			[Level2] [varchar](MAX) NULL,
			[Level3] [varchar](MAX) NULL,
			[Level4] [varchar](MAX) NULL,
			[Level5] [varchar](MAX) NULL,
			[Level6] [varchar](MAX) NULL,
			[Level7] [varchar](MAX) NULL,
			[Level8] [varchar](MAX) NULL,
			[Level9] [varchar](MAX) NULL,
			[Level10] [varchar](MAX) NULL,
			[MastercompanyId] [int] NULL
		);

		CREATE TABLE #TempTotalAmount
		(
			[Id] [bigint] IDENTITY(1,1),
			[MastercompanyId] [int] NULL,
			[TotalDebitAmount] [varchar](25) NULL,
			[TotalCreditAmount] [varchar](25) NULL,
		)

		SELECT @EmployeeName = (FirstName + ' ' + LastName) FROM [dbo].[Employee] WITH(NOLOCK) WHERE EmployeeId = @EmployeeId;

		SET @RecordFrom = (@PageNumber-1) * @PageSize;
			
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = UPPER('EntryDate')
		END 
		Else
		BEGIN 
			SET @SortColumn = UPPER(@SortColumn)
		END

		SET @FromGLAccount = (SELECT ISNULL(AccountCode, '') FROM [dbo].[GLAccount] WITH(NOLOCK) WHERE [GLAccountId] = @FromGLAccount);
		SET @ToGLAccount = (SELECT ISNULL(AccountCode, '') FROM [dbo].[GLAccount] WITH(NOLOCK) WHERE [GLAccountId] = @ToGLAccount);

		SET @FromJournalId = CASE WHEN ISNULL(@FromJournalId, '') = '' THEN '0' ELSE @FromJournalId END;
		SET @ToJournalId = CASE WHEN ISNULL(@ToJournalId, '') = '' THEN '0' ELSE @ToJournalId END;
		SET @FromGLAccount = CASE WHEN ISNULL(@FromGLAccount, '') = '' THEN '0' ELSE @FromGLAccount END;
		SET @ToGLAccount = CASE WHEN ISNULL(@ToGLAccount, '') = '' THEN '0' ELSE @ToGLAccount END

		INSERT INTO #TempJournalDetails ([CommonJournalBatchDetailId], [AccountPeriodName], [DebitAmount], [CreditAmount], [Currency], [DocumentNumber], [EffectiveDate], [EntryDate], [Distribution], [JournalId], 
										 [GLAccountName], [TypeName], [EmployeeName], [Level1], [Level2], [Level3], [Level4], [Level5], [Level6], [Level7], [Level8], [Level9], [Level10], [MastercompanyId])
		SELECT	CBD.CommonJournalBatchDetailId,
				BH.AccountingPeriod AS 'AccountPeriodName',
				ISNULL(CBD.DebitAmount, 0) AS 'DebitAmount',
				ISNULL(CBD.CreditAmount, 0) AS 'CreditAmount',
				'' AS 'Currency',
				'' AS 'DocumentNumber',
				CBD.TransactionDate AS 'EffectiveDate',
				CBD.EntryDate,
				CBD.DistributionName AS 'Distribution',
				CBD.JournalTypeNumber AS 'JournalId',
				CASE WHEN ISNULL(CBD.GlAccountNumber, '') = '' THEN ISNULL(CBD.GlAccountName, '') ELSE ISNULL(CBD.GlAccountNumber, '') + '-' + ISNULL(CBD.GlAccountName, '') END AS 'GLAccountName',
				'' AS 'TypeName',
				ISNULL(CBD.CreatedBy, '') AS 'EmployeeName',
				UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) AS level1,    
				UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) AS level2,   
				UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) AS level3,   
				UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) AS level4,   
				UPPER(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description]) AS level5,   
				UPPER(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description]) AS level6,   
				UPPER(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description]) AS level7,   
				UPPER(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description]) AS level8,   
				UPPER(CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description]) AS level9,   
				UPPER(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description])  AS level10,
				CBD.MasterCompanyId
		FROM [dbo].[CommonBatchDetails] CBD WITH(NOLOCK)
		INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON BD.JournalBatchDetailId = CBD.JournalBatchDetailId
		INNER JOIN [dbo].[BatchHeader] BH WITH(NOLOCK) ON BH.JournalBatchHeaderId = BD.JournalBatchHeaderId
		LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON CBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND CBD.[ManagementStructureId] = ESP.[EntityMSID]
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL1 WITH (NOLOCK) ON ESP.Level1Id = MSL1.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL2 WITH (NOLOCK) ON ESP.Level2Id = MSL2.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL3 WITH (NOLOCK) ON ESP.Level3Id = MSL3.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL4 WITH (NOLOCK) ON ESP.Level4Id = MSL4.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL5 WITH (NOLOCK) ON ESP.Level5Id = MSL5.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL6 WITH (NOLOCK) ON ESP.Level6Id = MSL6.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL7 WITH (NOLOCK) ON ESP.Level7Id = MSL7.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL8 WITH (NOLOCK) ON ESP.Level8Id = MSL8.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL9 WITH (NOLOCK) ON ESP.Level9Id = MSL9.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH (NOLOCK) ON ESP.Level10Id = MSL10.ID
		WHERE	CAST(CBD.TransactionDate AS date) BETWEEN CAST(@FromEffectiveDate AS date) AND CAST(@ToEffectiveDate AS date) AND
				((ISNULL(@FromJournalId, '') = '0' OR ISNULL(@ToJournalId, '') = '0') OR 
				SUBSTRING(CBD.JournalTypeNumber, PATINDEX('%[0-9]%', CBD.JournalTypeNumber), LEN(CBD.JournalTypeNumber)) BETWEEN CAST(@FromJournalId AS numeric) AND CAST(@ToJournalId AS numeric)) AND
				((ISNULL(@FromGLAccount, '') = '0' OR ISNULL(@ToGLAccount, '') = '0') OR 
				SUBSTRING(ISNULL(CBD.GlAccountNumber, ''), PATINDEX('%[0-9]%', ISNULL(CBD.GlAccountNumber, '')), LEN(ISNULL(CBD.GlAccountNumber, ''))) BETWEEN @FromGLAccount AND @ToGLAccount) AND
				(ISNULL(@EmployeeId , 0) = 0 OR UPPER(CBD.CreatedBy) = UPPER(@EmployeeName)) AND
				BH.MasterCompanyId = @MasterCompanyId AND
				(ISNULL(@Level1,'') ='' OR MSL1.[ID] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))  
				AND (ISNULL(@Level2,'') ='' OR MSL2.[ID] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))  
				AND (ISNULL(@Level3,'') ='' OR MSL3.[ID] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))  
				AND (ISNULL(@Level4,'') ='' OR MSL4.[ID] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))  
				AND (ISNULL(@Level5,'') ='' OR MSL5.[ID] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))  
				AND (ISNULL(@Level6,'') ='' OR MSL6.[ID] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))  
				AND (ISNULL(@Level7,'') ='' OR MSL7.[ID] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))  
				AND (ISNULL(@Level8,'') ='' OR MSL8.[ID] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))  
				AND (ISNULL(@Level9,'') ='' OR MSL9.[ID] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))  
				AND  (ISNULL(@Level10,'') =''  OR MSL10.[ID] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  
	
		INSERT INTO #TempTotalAmount([MastercompanyId], [TotalDebitAmount], [TotalCreditAmount])
		SELECT MastercompanyId,   
		FORMAT(SUM(DebitAmount), 'N', 'en-us') TotalDebitAmount,
		FORMAT(SUM(CreditAmount), 'N', 'en-us') TotalCreditAmount
		FROM #TempJournalDetails GROUP BY MastercompanyId

		IF(ISNULL(@IsDownload, 0) = 1)
		BEGIN
			SELECT COUNT(2) OVER () AS NumberOfItems, [CommonJournalBatchDetailId], [AccountPeriodName], [DebitAmount], [CreditAmount], [Currency], [DocumentNumber], [EffectiveDate], [EntryDate], [Distribution], [JournalId], 
					[GLAccountName], [TypeName], [EmployeeName], [Level1], [Level2], [Level3], [Level4], [Level5], [Level6], [Level7], [Level8], [Level9], [Level10], FC.[MastercompanyId]
					,WC.TotalDebitAmount, WC.TotalCreditAmount
			FROM #TempJournalDetails FC
			INNER JOIN #TempTotalAmount WC ON FC.MastercompanyId = WC.MastercompanyId  
			ORDER BY [EntryDate] DESC
		END
		ELSE
		BEGIN
			SELECT COUNT(2) OVER () AS NumberOfItems, [CommonJournalBatchDetailId], [AccountPeriodName], [DebitAmount], [CreditAmount], [Currency], [DocumentNumber], [EffectiveDate], [EntryDate], [Distribution], [JournalId], 
					[GLAccountName], [TypeName], [EmployeeName], [Level1], [Level2], [Level3], [Level4], [Level5], [Level6], [Level7], [Level8], [Level9], [Level10], FC.[MastercompanyId]
					,WC.TotalDebitAmount, WC.TotalCreditAmount
			FROM #TempJournalDetails FC
			INNER JOIN #TempTotalAmount WC ON FC.MastercompanyId = WC.MastercompanyId
			ORDER BY [EntryDate] DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetGeneralLedger_SearchList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100))
			  + '@Parameter7 = ''' + CAST(ISNULL(@masterCompanyID, '') AS VARCHAR(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END