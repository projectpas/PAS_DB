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

**************************************************************       

EXEC [RPT_GetIncomeStatementActualTrendReport] 1, 8, 1, 128,133
************************************************************************/
CREATE   PROCEDURE [dbo].[RPT_GetIncomeStatementActualTrendReport]
(
 @masterCompanyId BIGINT,  
 @ReportingStructureId BIGINT = NULL,  
 @managementStructureId BIGINT = NULL, 
 @StartAccountingPeriodId BIGINT = NULL,   
 @EndAccountingPeriodId BIGINT = NULL
)

AS
BEGIN
  BEGIN TRY

    DECLARE @LeafNodeId AS bigint;
    DECLARE @AccountcalID AS bigint;
	DECLARE @LegalEntityId BIGINT; 
	DECLARE @FROMDATE DATETIME;
	DECLARE @TODATE DATETIME;  
	DECLARE @PostedBatchStatusId BIGINT;
	DECLARE @ManualJournalStatusId BIGINT;

	SELECT @LeafNodeId = LeafNodeid FROM dbo.LeafNode WITH(NOLOCK) WHERE ReportingStructureId = @ReportingStructureId AND ParentId IS NULL AND IsDeleted = 0 
	SELECT @FROMDATE = FromDate, @LegalEntityId = LegalEntityId FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId AND IsDeleted = 0  
	SELECT @TODATE = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @EndAccountingPeriodId AND IsDeleted = 0 
	SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
	SELECT @ManualJournalStatusId =  ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Manual Batch Details Only

	IF OBJECT_ID(N'tempdb..#AccPeriodTable') IS NOT NULL
    BEGIN
      DROP TABLE #AccPeriodTable
    END

    CREATE TABLE #AccPeriodTable (
      ID bigint NOT NULL IDENTITY (1, 1),
	  AccountcalID BIGINT NULL,
	  PeriodName VARCHAR(100) NULL
    )

	INSERT INTO #AccPeriodTable (AccountcalID, PeriodName) 
	SELECT AccountingCalendarId, REPLACE(PeriodName,' - ','') 
	FROM dbo.AccountingCalendar WITH(NOLOCK)
	WHERE LegalEntityId = @LegalEntityId and IsDeleted = 0 and  
		 CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) 

	INSERT INTO #AccPeriodTable (AccountcalID, PeriodName) 
	VALUES(9999999,'Total')

    IF OBJECT_ID(N'tempdb..#AccTrendTable') IS NOT NULL
    BEGIN
      DROP TABLE #AccTrendTable
    END

    CREATE TABLE #AccTrendTable (
      ID bigint NOT NULL IDENTITY (1, 1),
      LeafNodeId bigint,
      NodeName varchar(500),
      Amount decimal(18, 2),
      AccountingPeriodId bigint,
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
      IsProcess bit DEFAULT (0)
    )

    DECLARE @LID AS int = 0;
	DECLARE @IsFristRow AS bit = 1;
    DECLARE @LCOUNT AS int = 0;
	SELECT @LCOUNT = MAX(ID) fROM #AccPeriodTable
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

		--UPDATE GL ACCOUNT SUM AND ASSIGN TO EACH ACCONTING CALENDER MONTH
		UPDATE #TempTable 
	         SET Amount = (ISNULL(CBD.CreditAmount, 0) - ISNULL(CBD.DebitAmount, 0))
						FROM dbo.LeafNode L WITH (NOLOCK)
								INNER JOIN #TempTable T
										ON L.LeafNodeId = T.LeafNodeId ANd T.AccountingPeriodId = @AccountcalID
								LEFT JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK)
										ON L.LeafNodeId = GLM.LeafNodeId
								LEFT JOIN dbo.GLAccount GL WITH (NOLOCK)
										ON GLM.GLAccountId = GL.GLAccountId
								LEFT JOIN dbo.LeafNode L1 WITH (NOLOCK)
										ON L.ParentId = L1.LeafNodeId
										   AND L.ReportingStructureId = @ReportingStructureId
								OUTER APPLY (
											SELECT  UN.GLAccountId, 
													(SUM(ISNULL(UN.CreditAmount, 0))) AS CreditAmount, 
													(SUM(ISNULL(UN.DebitAmount, 0))) AS DebitAmount,
													UN.AccountingPeriod,
													UN.AccountingPeriodId,
													UN.PeriodName
											FROM (
												  SELECT cb.GLAccountId,
														SUM(ISNULL(cb.CreditAmount, 0)) 'CreditAmount',
														SUM(ISNULL(cb.DebitAmount, 0)) 'DebitAmount',
														B.AccountingPeriod,
														B.AccountingPeriodId,
														REPLACE(B.AccountingPeriod, ' - ', ' ') 'PeriodName'
													FROM dbo.CommonBatchDetails cb WITH (NOLOCK)
														  INNER JOIN dbo.BatchDetails bd WITH (NOLOCK) ON cb.JournalBatchDetailId = bd.JournalBatchDetailId AND bd.StatusId = @PostedBatchStatusId
														  INNER JOIN dbo.BatchHeader B WITH (NOLOCK)
																	ON bd.JournalBatchHeaderId = B.JournalBatchHeaderId
																	   AND B.AccountingPeriodId = @AccountcalID
																	   AND B.MasterCompanyId = @masterCompanyId
													WHERE GLM.GLAccountId = cb.GlAccountId AND
														  b.AccountingPeriodId = @AccountcalID
														  AND CB.ManagementStructureId = @managementStructureId
														  GROUP BY cb.GlAccountId,
																	B.AccountingPeriod,
																	B.AccountingPeriodId
													
													UNION ALL

													SELECT MJD.GlAccountId, 
														SUM(ISNULL(MJD.Credit, 0)) 'CreditAmount', 
														SUM(ISNULL(MJD.Debit, 0)) 'DebitAmount', 
														AC.PeriodName AS AccountingPeriod,
														MJH.AccountingPeriodId, 
														REPLACE(AC.PeriodName, ' - ', ' ') 'PeriodName'
													FROM dbo.ManualJournalDetails MJD WITH (NOLOCK) 
														JOIN dbo.ManualJournalHeader MJH  WITH (NOLOCK) ON MJH.ManualJournalHeaderId = MJD.ManualJournalHeaderId
														JOIN dbo.AccountingCalendar AC WITH (NOLOCK) ON MJH.AccountingPeriodId = AC.AccountingCalendarId
													WHERE GLM.GLAccountId = MJD.GlAccountId AND 
															MJH.ManualJournalStatusId = @ManualJournalStatusId 
															AND MJD.ManagementStructureId = @managementStructureId
															AND MJH.AccountingPeriodId = @AccountcalID
														   GROUP BY  MJD.GlAccountId, MJH.AccountingPeriodId, AC.PeriodName
												) UN GROUP BY UN.GlAccountId, UN.AccountingPeriodId, UN.PeriodName, UN.AccountingPeriod														
											) CBD
								WHERE L.ReportingStructureId = @ReportingStructureId
								      AND L.IsDeleted = 0
								      AND L.MasterCompanyId = @masterCompanyId

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

		  IF NOT EXISTS (SELECT TOP 1 ID FROM #AccTrendTable WHERE LeafNodeId = @CLID AND IsBlankHeader = 1 AND AccountingPeriodId =@AccountcalID)
		  BEGIN
				INSERT INTO #AccTrendTable (LeafNodeId, NodeName, Amount, AccountingPeriodId, IsBlankHeader)
						  SELECT TOP 1 LeafNodeId, Name + ' :',NULL,@AccountcalID, 1 FROM #TempTable 
										 WHERE LeafNodeId = @CLID
											  AND ChildCount > 0 AND  AccountingPeriodId = @AccountcalID
				IF(@IsFristRow = 1)
				BEGIN
				INSERT INTO ##AccTrendTablePivot(Name,IsBlankHeader, LeafNodeId, ParentId)
				           SELECT TOP 1  Name + ' :', 1, LeafNodeId, ParentId FROM #TempTable 
										 WHERE LeafNodeId = @CLID
											  AND ChildCount > 0 AND  AccountingPeriodId = @AccountcalID
                END
		  END

      INSERT INTO #AccTrendTable (LeafNodeId, NodeName, Amount, AccountingPeriodId, IsBlankHeader)
        SELECT LeafNodeId, Name, Amount, @AccountcalID, 0
		         FROM #TempTable
				       WHERE ID = @CID AND AccountingPeriodId = @AccountcalID  --                    AND ChildCount = 0
	  IF(@IsFristRow = 1)
				BEGIN
				INSERT INTO ##AccTrendTablePivot(Name,IsBlankHeader, LeafNodeId, ParentId)
				            SELECT  Name, 0, LeafNodeId, ParentId
								FROM #TempTable
										WHERE ID = @CID AND AccountingPeriodId = @AccountcalID  --                    AND ChildCount = 0
                END

      UPDATE #TempTable
			  SET IsProcess = 1
			     WHERE ID = @CID AND AccountingPeriodId = @AccountcalID

      IF NOT EXISTS (SELECT TOP 1 ID FROM #TempTable WHERE ParentId = @CLID AND IsProcess = 0 AND AccountingPeriodId = @AccountcalID)
      BEGIN
        IF NOT EXISTS (SELECT TOP 1 ID FROM #AccTrendTable WHERE LeafNodeId = @CLID  AND IsTotlaLine = 1 AND AccountingPeriodId = @AccountcalID)
        BEGIN
              INSERT INTO #AccTrendTable (LeafNodeId, NodeName, Amount, AccountingPeriodId, IsBlankHeader, IsTotlaLine)
							SELECT  LeafNodeId,'Total - ' + Name, TotalAmount,@AccountcalID, 0, 1
									FROM #TempTable
										WHERE LeafNodeId = @CLID  AND ChildCount > 0 AND  AccountingPeriodId = @AccountcalID
			 IF(@IsFristRow = 1)
				BEGIN
				INSERT INTO ##AccTrendTablePivot(Name,IsBlankHeader,IsTotlaLine, LeafNodeId, ParentId)
						   SELECT TOP 1  'Total - ' + Name,0, 1, LeafNodeId, LeafNodeId
										 FROM #TempTable
										     WHERE LeafNodeId = @CLID  AND ChildCount > 0  AND  AccountingPeriodId = @AccountcalID

                END
        END
      END
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

		-----Final Loop
		SET @IsFristRow = 0
		SET @LCOUNT = @LCOUNT -1
	END

	--SELECT * FROM #TempTable
	--SELECT * FROM ##AccTrendTablePivot
	--SELECT * FROM #AccTrendTable
    
	UPDATE #TempTable SET AccountingPeriodName = REPLACE(AP.PeriodName,' - ',' ')  
	FROM #TempTable tmp JOIN dbo.AccountingCalendar AP WITH(NOLOCK) ON tmp.AccountingPeriodId = AP.AccountingCalendarId

	UPDATE #AccTrendTable SET AccountingPeriod = CASE WHEN ISNULL(AP.PeriodName, '') != '' THEN REPLACE(AP.PeriodName ,' - ',' ')  ELSE 'Total' END
	FROM #AccTrendTable tmp LEFT JOIN dbo.AccountingCalendar AP WITH(NOLOCK) ON tmp.AccountingPeriodId = AP.AccountingCalendarId
	
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
		DECLARE @APId AS BIGINT;
		SELECT @APName = PeriodName, @APId = AccountcalID FROM #AccPeriodTable WHERE ID = @COUNT

		DECLARE @SQLUpdateQuery varchar(max) = 'UPDATE ##AccTrendTablePivot SET [' + CAST(@APName AS VARCHAR(100)) +'] = (SELECT Amount FROM #AccTrendTable WHERE NodeName = AP.Name AND IsBlankHeader = AP.IsBlankHeader and AccountingPeriodId = ' + CAST(@APId AS varchar(10)) + ' ) FROM ##AccTrendTablePivot AP'
		

		--UPDATE ##AccTrendTablePivot SET [Jan2023] = (SELECT Amount FROM #AccTrendTable WHERE NodeName = AP.Name AND IsBlankHeader = AP.IsBlankHeader and AccountingPeriodId = 128 ) FROM ##AccTrendTablePivot AP

		PRINT @SQLUpdateQuery;
		EXEC(@SQLUpdateQuery)  

		SET @COUNT = @COUNT + 1

	END

	--PRINT '123'
	--SELECT * FROM ##AccTrendTablePivot

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
		From #AccPeriodTable
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
	SELECT @COUNTMAX1 = MAX(ID), @COUNT1 = MIN(ID) FROM #AccPeriodTable

	WHILE (@COUNT1 <= @COUNTMAX1)
    BEGIN
		DECLARE @APName1 AS VARCHAR(100);
		DECLARE @APId1 AS BIGINT;
		SELECT @APName1 = PeriodName, @APId1 = AccountcalID FROM #AccPeriodTable WHERE ID = @COUNT1

		DECLARE @SQLFinalUpdateQuery varchar(max) = 'UPDATE T1 SET T1.[' + CAST(@APName1 AS VARCHAR(100)) +'] = T2.[' + CAST(@APName1 AS VARCHAR(100)) +'] FROM ##tmpFinalReturnTable T1 JOIN ##AccTrendTablePivot T2 ON T1.leafNodeId = T2.leafNodeId AND T1.parentId = T2.parentId AND T1.[name] = T2.[name]'
		
		--PRINT (@SQLFinalUpdateQuery)
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
				--UPDATE ##AccTrendTablePivot SET [May2023] = (SELECT Amount FROM #AccTrendTable WHERE NodeName = AP.Name AND IsBlankHeader = AP.IsBlankHeader and AccountingPeriodId = 132 ) FROM ##AccTrendTablePivot AP
				PRINT (@SQLQueryUpdateHeader)
				EXEC(@SQLQueryUpdateHeader)  

				SET @COUNT4 = @COUNT4 + 1
			END

		END

		SET @COUNT3 = @COUNT3 + 1
		
	END
	--SELECT LeafNodeId As leafNodeId, Name As [name], ParentId AS parentId, ParentNodeName As parentNodeName, IsLeafNode AS isLeafNode,MasterCompanyId AS masterCompanyId, ReportingStructureId AS reportingStructureId, IsPositive AS isPositive, SequenceNumber AS sequenceNumber
	--FROM ##AccTrendTablePivot
	--SELECT * FROM ##tmpFinalReturnTable

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