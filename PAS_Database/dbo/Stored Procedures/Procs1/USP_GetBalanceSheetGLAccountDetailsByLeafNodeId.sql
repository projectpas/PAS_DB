/*************************************************************             
 ** File:   [USP_GetBalanceSheetGLAccountDetailsByLeafNodeId]             
 ** Author: Rajesh  
 ** Description: This stored procedure is used to Get Balance sheet GL account detail by leafnode
 ** Purpose: Initial Draft           
 ** Date: 05/09/2023  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    05/09/2023   Rajesh Gami		Created
	2	 20/09/2023   Hemnat Saliya		Updated LE MS Details 
	3	 01/11/2023   Hemnat Saliya		Updated For JE Balabce
	4	 22/11/2023   Moin Bloch		Modified commented manual glaccountId in IsDebugMode
	5    25/01/2024   Hemant Saliya	    Remove Manual Journal from Reports
	6    12/06/2024   Hemant Saliya	    Corrected GL Account Name

************************************************************************/
  
CREATE   PROCEDURE [dbo].[USP_GetBalanceSheetGLAccountDetailsByLeafNodeId]                                                                                                                                     
(  
 @StartAccountingPeriodId BIGINT = NULL,   
 @EndAccountingPeriodId BIGINT = NULL,
 @ReportingStructureId BIGINT = NULL, 
 @managementStructureId BIGINT = NULL,  
 @masterCompanyId INT = NULL,
 @LeafNodeId BIGINT = NULL,
 @xmlFilter XML  
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
		  DECLARE @AssetGLAccountTypeId AS BIGINT;
		  DECLARE @LiabilitiesGLAccountTypeId AS BIGINT;
		  DECLARE @EquityGLAccountTypeId AS BIGINT;
		  DECLARE @BatchMSModuleId BIGINT; 
		  DECLARE @MAXCalTempID INT = 0, @INITIALFROMDATE DATETIME,@INITIALENDDATE DATETIME;
		  DECLARE @IsDebugMode BIT;

		  --SET @IsDebugMode = 1;
		  
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

		  DECLARE @StartingRowNum BIGINT; 

		  IF(@EndAccountingPeriodId is null OR @EndAccountingPeriodId = 0)
	      BEGIN
		    SET @EndAccountingPeriodId = @StartAccountingPeriodId;
		  END

		  SELECT @INITIALFROMDATE = MIN(FromDate) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND IsDeleted = 0  
		  SELECT @FROMDATE = FromDate, @LegalEntityId = LegalEntityId FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId AND IsDeleted = 0
		  SELECT @TODATE = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @EndAccountingPeriodId AND IsDeleted = 0 
		  SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
		  SELECT @AssetGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Asset' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		  SELECT @LiabilitiesGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Liabilities' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		  SELECT @EquityGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Owners Equity' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		  SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID

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
		  SELECT AccountingCalendarId, REPLACE(PeriodName,' - ',' ') ,FromDate,ToDate
		  FROM dbo.AccountingCalendar WITH(NOLOCK)
		  WHERE LegalEntityId = @LegalEntityId AND IsDeleted = 0 AND  
		  		CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) AND CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) AND ISNULL(IsAdjustPeriod, 0) = 0 
		  
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
		  
		  IF OBJECT_ID(N'tempdb..##GLBalance') IS NOT NULL
		  BEGIN
		    DROP TABLE ##GLBalance
		  END
    	  
		  CREATE TABLE ##GLBalance (
		    ID BIGINT NOT NULL IDENTITY (1, 1),
		    LeafNodeId BIGINT,
			GLAccountCode VARCHAR(200),
			GLAccountName VARCHAR(200),
			GLAccountId BIGINT,
		    AccountingPeriodId BIGINT NULL,
			AccountingPeriod VARCHAR(200),
			PeriodName VARCHAR(200),
		    CreaditAmount DECIMAL(18, 2) NULL,
		    DebitAmount DECIMAL(18, 2) NULL,
		    Amount DECIMAL(18, 2) NULL,
			RowNum INT NULL
			)
			
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

		--SELECT * FROM #AccPeriodTable
		SELECT @MAXCalTempID = MAX(ID) fROM #AccPeriodTable
		WHILE(@MAXCalTempID > 0)
		BEGIN

			SELECT  @AccountcalID = AccountcalID, @INITIALENDDATE = ToDate FROM #AccPeriodTable WHERE ID = @MAXCalTempID

			DELETE FROM #AccPeriodTable_All

			INSERT INTO #AccPeriodTable_All (AccountcalID, PeriodName, FromDate, ToDate) 
			SELECT AccountingCalendarId, REPLACE(PeriodName,' - ',' ') ,FromDate,ToDate
			FROM dbo.AccountingCalendar WITH(NOLOCK)
			WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND IsDeleted = 0 AND  
				CAST(Fromdate AS DATE) >= CAST(@INITIALFROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@INITIALENDDATE AS DATE)  AND ISNULL(IsAdjustPeriod, 0) = 0 
			ORDER BY FiscalYear, [Period]

			INSERT INTO ##GLBalance (LeafNodeId, GLAccountId,  GLAccountCode, GLAccountName, AccountingPeriodId, AccountingPeriod, PeriodName, DebitAmount, CreaditAmount,  Amount,RowNum)
			(SELECT DISTINCT LF.LeafNodeId , CMD.GLAccountId, CMD.GlAccountNumber, CMD.GlAccountName, @AccountcalID, '',(SELECT TOP 1 ACL.PeriodName FROM DBO.AccountingCalendar ACL WITH(NOLOCK) WHERE ACL.AccountingCalendarId = @AccountcalID), 
					CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END 'DebitAmount',
					CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END 'CreditAmount',
					CASE WHEN GL.GLAccountTypeId = @AssetGLAccountTypeId THEN
						(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END) - 
						(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) 
					ELSE
						(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) -
						(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END)
					END AS AMONUT,0 
			FROM dbo.CommonBatchDetails CMD WITH (NOLOCK)
				INNER JOIN dbo.BatchDetails BD WITH (NOLOCK) ON CMD.JournalBatchDetailId = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
				INNER JOIN dbo.BatchHeader B WITH (NOLOCK) ON BD.JournalBatchHeaderId = B.JournalBatchHeaderId 
				INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = CMD.CommonJournalBatchDetailId  AND ModuleId = @BatchMSModuleId
				INNER JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON CMD.GlAccountId = GLM.GLAccountId
				INNER JOIN dbo.GLAccount GL WITH (NOLOCK) ON GL.GlAccountId = GLM.GLAccountId AND GL.GLAccountTypeId IN (@AssetGLAccountTypeId, @LiabilitiesGLAccountTypeId,@EquityGLAccountTypeId) 
				INNER JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0 AND ISNULL(ReportingStructureId, 0) = @ReportingStructureId
			WHERE ISNULL(CMD.IsDeleted,0) = 0  AND ISNULL(BD.IsDeleted,0) = 0 AND  ISNULL(GLM.IsDeleted,0) = 0 AND CMD.MasterCompanyId = @MasterCompanyId	
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
			GROUP BY LF.LeafNodeId , CMD.GLAccountId, CMD.GlAccountNumber, CMD.GlAccountName, GLM.IsPositive, GL.GLAccountTypeId)

			SET @MAXCalTempID = @MAXCalTempID - 1;
		END

		IF(@IsDebugMode = 1)
		BEGIN
			SELECT * FROM ##GLBalance--- where GLAccountId = 13
			--Select * from ##GLBalance where LeafNodeId = 154 and GLAccountId = 568
			--SET @StartingRowNum = (SELECT TOP 1 RowNum FROM ##GLBalance WHERE AccountingPeriodId = @StartAccountingPeriodId)
			--select DISTINCT * from ##GLBalance where LeafNodeId = 153 AND GLAccountId = 13 AND RowNum <= 18
		END
		
		  DECLARE @LID AS int = 0;
		  DECLARE @IsFristRow AS bit = 1;
		  DECLARE @LCOUNT AS int = 0;
		  SELECT @LCOUNT = MAX(ID) FROM #AccPeriodTable

		  WHILE(@LCOUNT > 0)
		  BEGIN
			SELECT  @AccountcalID = AccountcalID FROM #AccPeriodTable where ID = @LCOUNT

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
		    Amount decimal(18, 2) NULL,
			MainAmount decimal(18, 2) NULL,
		    AccountingPeriodId bigint,
		    AccountingPeriod VARCHAR(100) null,
		    PeriodName VARCHAR(100) null,
			ReferenceId BIGINT NULL,
			ReferenceModule VARCHAR(100) null,
			DistributionSetupCode VARCHAR(100) NULL,
			EntryDate DATETIME NULL,
			RowNum INT NULL
		  )
		  --select * from #TempTable
		  --select * from ##GLBalance
		  DECLARE @COUNT AS INT;
		  DECLARE @COUNTMAX AS INT
		  SELECT @COUNT = MIN(ID), @COUNTMAX = MAX(ID) fROM #AccPeriodTable
		  WHILE (@COUNT <= @COUNTMAX)
		  BEGIN
			  SELECT  @AccountcalID = AccountcalID FROM #AccPeriodTable where ID = @COUNT
			  INSERT INTO #AccTrendTable(LeafNodeId, NodeName, GLAccountId, GLAccountCode, GLAccountName, Amount,MainAmount, AccountingPeriodId, AccountingPeriod, PeriodName,RowNum) --,JournalNumber, ReferenceId, DistributionSetupCode, EntryDate)
			  SELECT  L.LeafNodeId, T.[Name], GL.GLAccountId, GLAccountCode, GLAccountName, SUM(ISNULL(GL.Amount, 0)), SUM(ISNULL(GL.Amount, 0)), GL.AccountingPeriodId, AccountingPeriod,(SELECT TOP 1 REPLACE(PeriodName, ' - ', '') FROM dbo.AccountingCalendar aa WHEre aa.AccountingCalendarId = gl.AccountingPeriodId ),GL.RowNum
			  FROM dbo.LeafNode L WITH (NOLOCK)
				JOIN #TempTable T ON L.LeafNodeId = T.LeafNodeId ANd T.AccountingPeriodId = @AccountcalID
				JOIN ##GLBalance GL ON T.AccountingPeriodId = @AccountcalID AND T.LeafNodeId = GL.LeafNodeId AND T.AccountingPeriodId = GL.AccountingPeriodId
				LEFT JOIN dbo.GLAccount GLA ON GL.GLAccountId = GLA.GLAccountId
			  GROUP BY GL.AccountingPeriodId,L.LeafNodeId,T.[Name],GL.GLAccountId,GLAccountCode,GLAccountName,AccountingPeriod,Gl.RowNum
			  SET @COUNT = @COUNT + 1
		  END

		  UPDATE #AccTrendTable SET PeriodName = REPLACE(PeriodName, ' ', '')

		  DECLARE @columns NVARCHAR(MAX) = '', 
				  @sql     NVARCHAR(MAX) = '';

			SELECT @columns+=QUOTENAME(REPLACE(PeriodName, ' ', '')) + ','
			FROM #AccPeriodTable
			GROUP BY PeriodName
			--ORDER BY 
			--	 AccountcalID

			-- remove the last comma
			SET @columns = LEFT(@columns, LEN(@columns) - 1);

			UPDATE #AccTrendTable SET GLAccountCode = GL.AccountCode, GLAccountName = GL.AccountName FROM #AccTrendTable JOIN dbo.GLAccount GL ON #AccTrendTable.GLAccountId = GL.GLAccountId

			SET @sql ='SELECT * FROM   
				(
					SELECT 
						 LeafNodeId, UPPER(NodeName) AS NodeName, GLAccountId, (UPPER(GLAccountCode) + '' - '' + UPPER(GLAccountName)) AS GLAccount, UPPER(PeriodName) AS PeriodName, Amount 
					FROM 
						#AccTrendTable
					WHERE GLAccountId IS NOT NULL
				) t 
				PIVOT(
					SUM(Amount) 
					FOR PeriodName IN ('+ @columns +')
				) AS pivot_table ORDER BY GLAccountId;';

			-- execute the dynamic SQL
			--PRINT (@sql)
			EXEC(@sql); 

	END TRY  
	BEGIN CATCH  
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
					  , @AdhocComments     VARCHAR(150)    = 'USP_GetBalanceSheetGLAccountDetailsByLeafNodeId' 
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