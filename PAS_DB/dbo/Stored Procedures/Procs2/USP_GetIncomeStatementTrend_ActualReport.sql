/*************************************************************             
 ** File:   [USP_GetIncomeStatementTrend_ActualReport]             
 ** Author: Hemant Saliya  
 ** Description: This stored procedure is used to display income statement(actual) report data
 ** Purpose:           
 ** Date:23/06/2023
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  	Change Description              
 ** --   --------     -------		-------------------------------            
	1    23/06/2023   Hemant Saliya	  Created 
**************************************************************/

/*************************************************************             

--EXEC [USP_GetIncomeStatementTrend_ActualReport] 1,'128','133',8,1 
************************************************************************/

  
CREATE   PROCEDURE [dbo].[USP_GetIncomeStatementTrend_ActualReport]
(
 @masterCompanyId BIGINT,  
 @id varchar(50),   -- Start Accounting Period
 @id2 Varchar(50),  -- End Accounting Period
 @id5 Varchar(50),  -- Reporting Structure Id, 
 @managementStructureId BIGINT  
)

AS
BEGIN
  BEGIN TRY

    DECLARE @LeafNodeId AS bigint;
    DECLARE @AccountcalID AS bigint;
    DECLARE @ReportingStructureId AS bigint;
	DECLARE @LegalEntityId BIGINT; 
	DECLARE @FROMDATE DATETIME;
	DECLARE @TODATE DATETIME;  

	--SET @LeafNodeId = 54;
	SET @ReportingStructureId = @id5;
	SELECT @LeafNodeId = LeafNodeid FROM dbo.LeafNode WITH(NOLOCK) WHERE ReportingStructureId = @ReportingStructureId AND ParentId IS NULL AND IsDeleted = 0 
	SELECT @FROMDATE = FromDate, @LegalEntityId = LegalEntityId FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @id AND IsDeleted = 0  
	SELECT @TODATE = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @id2 AND IsDeleted = 0 

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
	SELECT AccountingCalendarId, REPLACE(PeriodName,' - ',' ') 
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
      NodeName varchar(500),    
      --AccountingPeriodId decimal(18,2) null,
	  --AccountingPeriodId1 decimal(18,2) null,
      IsBlankHeader bit DEFAULT 0,
      IsTotlaLine bit DEFAULT 0, ' + Stuff((SELECT ','+ QUOTENAME(PeriodName) + ' DECIMAL(18,2) NULL'
														   From #AccPeriodTable
														   Order By AccountcalID  
														   For XML Path('')),1,1,'') + ')'

	--PRINT @SQLQuery;
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
	   --SELECT @AccountcalID

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
								OUTER APPLY (SELECT cb.GLAccountId,
													SUM(ISNULL(cb.CreditAmount, 0)) 'CreditAmount',
													SUM(ISNULL(cb.DebitAmount, 0)) 'DebitAmount',
													B.AccountingPeriod,
													B.AccountingPeriodId,
													REPLACE(B.AccountingPeriod, ' - ', ' ') 'PeriodName'
												FROM dbo.CommonBatchDetails cb WITH (NOLOCK)
													  INNER JOIN BatchHeader B WITH (NOLOCK)
								                                ON CB.JournalBatchHeaderId = B.JournalBatchHeaderId
																   AND B.AccountingPeriodId = @AccountcalID
								                                   AND B.MasterCompanyId = @masterCompanyId
								                WHERE GLM.GLAccountId = cb.GlAccountId
													  AND b.AccountingPeriodId = @AccountcalID
													  AND CB.ManagementStructureId = @managementStructureId
													  GROUP BY cb.GlAccountId,
															    B.AccountingPeriod,
										                        B.AccountingPeriodId) CBD
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
				INSERT INTO ##AccTrendTablePivot(NodeName,IsBlankHeader)
				           SELECT TOP 1  Name + ' :', 1 FROM #TempTable 
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
				INSERT INTO ##AccTrendTablePivot(NodeName,IsBlankHeader)
				            SELECT  Name, 0
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
				INSERT INTO ##AccTrendTablePivot(NodeName,IsBlankHeader,IsTotlaLine)
				           SELECT TOP 1  'Total - ' + Name,0, 1 
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

    
	UPDATE #TempTable SET AccountingPeriodName = REPLACE(AP.PeriodName,' - ',' ')  
	FROM #TempTable tmp JOIN dbo.AccountingCalendar AP WITH(NOLOCK) ON tmp.AccountingPeriodId = AP.AccountingCalendarId

	UPDATE #AccTrendTable SET AccountingPeriod = CASE WHEN ISNULL(AP.PeriodName, '') != '' THEN REPLACE(AP.PeriodName ,' - ',' ')  ELSE 'Total' END
	FROM #AccTrendTable tmp LEFT JOIN dbo.AccountingCalendar AP WITH(NOLOCK) ON tmp.AccountingPeriodId = AP.AccountingCalendarId
	
	UPDATE #AccTrendTable 
	SET Amount = Groptoal.TotalAmt	
	FROM(
		SELECT SUM(Amount) AS TotalAmt, NodeName FROM #AccTrendTable act WHERE AccountingPeriod != 'Total' GROUP BY NodeName
	) Groptoal WHERE Groptoal.NodeName = #AccTrendTable.NodeName AND AccountingPeriod = 'Total'

	--SELECT * FROM #AccTrendTable
	
	DECLARE @COUNT AS INT;
	DECLARE @COUNTMAX AS INT
	SELECT @COUNTMAX = MAX(ID), @COUNT = MIN(ID) FROM #AccPeriodTable

	WHILE (@COUNT <= @COUNTMAX)
    BEGIN
		DECLARE @APName AS VARCHAR(100);
		DECLARE @APId AS BIGINT;
		SELECT @APName = PeriodName, @APId = AccountcalID FROM #AccPeriodTable WHERE ID = @COUNT

		DECLARE @SQLUpdateQuery varchar(max) = 'UPDATE ##AccTrendTablePivot SET [' + CAST(@APName AS VARCHAR(100)) +'] = (SELECT Amount FROM #AccTrendTable WHERE NodeName = AP.NodeName AND IsBlankHeader = AP.IsBlankHeader and AccountingPeriodId = ' + CAST(@APId AS varchar(10)) + ' ) FROM ##AccTrendTablePivot AP'

		--PRINT (@SQLUpdateQuery)
		EXEC(@SQLUpdateQuery)  

		SET @COUNT = @COUNT + 1

	END
	--SELECT * FROM #TempTable
	--FINAL RESULT BEFORE PIVOT
	SELECT ID, LeafNodeId, UPPER(NodeName) AS NodeName, Amount, AccountingPeriodId, UPPER(AccountingPeriod) AS AccountingPeriod , IsBlankHeader, IsTotlaLine FROM #AccTrendTable
    --FINAL RESULT AFTER PIVOT
	--SELECT * FROM ##AccTrendTablePivot

  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = 'USP_GetIncomeStatementTrend_ActualReport',
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