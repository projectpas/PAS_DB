/*************************************************************             
 ** File:   [USP_GetGLAccountDetailsByLeafNodeId]             
 ** Author: Hemant Saliya  
 ** Description: This stored procedure is used to Get income statement(actual) report Data 
 ** Purpose: Initial Draft           
 ** Date: 08/08/2023  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    08/08/2023   Hemant Saliya  Created
	2    07/09/2023   Hemant Saliya  Updated for Total 
	3    20/09/2023   Hemant Saliya  Updated LE Accounting Period Changes
	4    30/10/2023   Hemant Saliya  Updated Suppress Zero Changes
	5    08/11/2023   Hemant Saliya  Resolved Balance MissMatch Issue
	6    12/08/2023   Moin Bloch     Resolved Balance MissMatch Issue
	7    25/01/2024   Hemant Saliya	 Remove Manual Journal from Reports
************************************************************************
EXEC [RPT_GetIncomeStatementTrendReportsExportData] 137,137,8,1,1,64, @strFilter=N'1,5,6,52!2,7,8,9!3,11,10!4,12,13'
************************************************************************/
  
CREATE   PROCEDURE [dbo].[RPT_GetIncomeStatementTrendReportsExportData]  
(  
 @StartAccountingPeriodId BIGINT = NULL,   
 @EndAccountingPeriodId BIGINT = NULL,
 @ReportingStructureId BIGINT = NULL, 
 @ManagementStructureId BIGINT = NULL,  
 @MasterCompanyId INT = NULL,
 @LeafNodeId BIGINT = NULL,
 @strFilter VARCHAR(MAX) = NULL
)  
AS  
BEGIN   
 BEGIN TRY 
		   
		  DECLARE @FROMDATE DATETIME;
		  DECLARE @TODATE DATETIME;  
		  DECLARE @AccountPeriods VARCHAR(max);  
		  DECLARE @AccountcalMonth VARCHAR(max);  
		  DECLARE @AccountPeriodIds VARCHAR(max);  
		  DECLARE @PostedBatchStatusId BIGINT;
		  DECLARE @BatchMSModuleId BIGINT; 
		  DECLARE @RevenueGLAccountTypeId AS BIGINT;
		  DECLARE @ExpenseGLAccountTypeId AS BIGINT;
		  DECLARE @SequenceNumber INT; 
		  DECLARE @LegalEntityId BIGINT; 

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
		  SELECT @RevenueGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Revenue' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		  SELECT @ExpenseGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Expense' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		  SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
		  SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID

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

		  IF(ISNULL(@StartAccountingPeriodId, 0) = ISNULL(@EndAccountingPeriodId, 0))
		  BEGIN
			IF((SELECT ISNULL(IsAdjustPeriod, 0) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId) > 0)
				BEGIN
					  INSERT INTO #AccPeriodTable_All (AccountcalID, PeriodName, FromDate, ToDate) 
					  SELECT AccountingCalendarId, REPLACE(PeriodName,' - ','') ,FromDate,ToDate
					  FROM dbo.AccountingCalendar WITH(NOLOCK)
					  WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))  and IsDeleted = 0 and  
					  CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE)  AND ISNULL(IsAdjustPeriod, 0) = 1 
					  ORDER BY FiscalYear, [Period]
				END
				ELSE
				BEGIN
					  INSERT INTO #AccPeriodTable_All (AccountcalID, PeriodName, FromDate, ToDate) 
					  SELECT AccountingCalendarId, REPLACE(PeriodName,' - ','') ,FromDate,ToDate
					  FROM dbo.AccountingCalendar WITH(NOLOCK)
					  WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))  and IsDeleted = 0 and  
					  CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE)  AND ISNULL(IsAdjustPeriod, 0) = 0 
					  ORDER BY FiscalYear, [Period]
				END
		  END
		  ELSE
		  BEGIN
					INSERT INTO #AccPeriodTable_All (AccountcalID, PeriodName, FromDate, ToDate) 
					  SELECT AccountingCalendarId, REPLACE(PeriodName,' - ','') ,FromDate,ToDate
					  FROM dbo.AccountingCalendar WITH(NOLOCK)
					  WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))  and IsDeleted = 0 and  
					  CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE)
					  ORDER BY FiscalYear, [Period]
		 END

		  --SELECT * FROM #AccPeriodTable_All

		  IF OBJECT_ID(N'tempdb..#GLBalance') IS NOT NULL
		  BEGIN
		    DROP TABLE #GLBalance
		  END
    	  
		  CREATE TABLE #GLBalance (
		    ID bigint NOT NULL IDENTITY (1, 1),
		    LeafNodeId bigint,
			AccountcalMonth VARCHAR(100) NULL,
		    CreaditAmount decimal(18, 2) NULL,
		    DebitAmount decimal(18, 2) NULL,
		    Amount decimal(18, 2) NULL,
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
				INNER JOIN dbo.GLAccount GL WITH (NOLOCK) ON GL.GlAccountId = CMD.GLAccountId AND GL.GLAccountTypeId IN (@RevenueGLAccountTypeId, @ExpenseGLAccountTypeId) 
				INNER JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0 AND ISNULL(ReportingStructureId, 0) = @ReportingStructureId
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
			GROUP BY LF.LeafNodeId , BD.AccountingPeriod, GLM.IsPositive, GL.GLAccountTypeId)

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
		  SELECT DISTINCT REPLACE(PeriodName,' - ',''), [FiscalYear],[Period]
		  FROM dbo.AccountingCalendar WITH(NOLOCK)
		  WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND IsDeleted = 0 AND  
		  	 CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) AND CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) 
		  
		  INSERT INTO #AccPeriodTable (PeriodName) 
		  VALUES('Total')

		  IF OBJECT_ID(N'tempdb..#ReportingStructure') IS NOT NULL
		  BEGIN
		    DROP TABLE #ReportingStructure
		  END

		  CREATE TABLE #ReportingStructure (
				ID BIGINT NOT NULL IDENTITY (1, 1),
				LeafNodeId BIGINT NULL,
				ParentId BIGINT NULL,
				NodeName VARCHAR(MAX) NULL,
				SequenceNumber INT NULL,		
				IsProcess BIT DEFAULT (0),
				LevelId INT NULL)

		  ;WITH tree_view AS (
				 SELECT l1.LeafNodeId, 
					  l1.Name, 
					  l1.ParentId, 
					  l1.SequenceNumber, 
					  0 AS [level],
					  CAST(LeafNodeId AS varchar(50)) AS order_sequence
				FROM  dbo.LeafNode l1 WITH(NOLOCK)
				WHERE ParentId IS NULL and ReportingStructureId = @ReportingStructureId and IsDeleted = 0
     
				UNION ALL

				SELECT Parent.LeafNodeId, 
					  Parent.Name, 
					  Parent.ParentId, 
					  Parent.SequenceNumber, 
					  [level] + 1 AS level,
					  CAST(order_sequence + '_' + CAST(parent.LeafNodeId AS VARCHAR (50)) AS VARCHAR(50)) AS order_sequence
				FROM  dbo.LeafNode Parent WITH(NOLOCK) 
					JOIN tree_view tv
						ON parent.ParentId = tv.LeafNodeId
				 WHERE ReportingStructureId = @ReportingStructureId and IsDeleted = 0
			)
			INSERT INTO #ReportingStructure(LeafNodeId, NodeName, ParentId, SequenceNumber, LevelId)
			SELECT LeafNodeId,UPPER(Name), ISNULL(ParentId,0), SequenceNumber, level			   
			FROM tree_view
			ORDER BY SequenceNumber;

		  ---Reporting Strctrue with Parent Child
		  IF OBJECT_ID(N'tempdb..#ReportingStructureTable') IS NOT NULL
		  BEGIN
		    DROP TABLE #ReportingStructureTable
		  END

		  CREATE TABLE #ReportingStructureTable (
				ID BIGINT NOT NULL IDENTITY (1, 1),
				LeafNodeId BIGINT NULL,
				ParentId BIGINT NULL,
				NodeName VARCHAR(MAX) NULL,
				SequenceNumber INT NULL,				
				IsProcess BIT DEFAULT (0),			
				HaveChield BIT DEFAULT (0),
				LevelId INT NULL,
				ChildCount INT NULL
		  )

		  DECLARE @ID AS int = 0;	
		  SELECT @ID = LeafNodeId FROM #ReportingStructure WHERE ParentId = 0	  
		  INSERT INTO #ReportingStructureTable(LeafNodeId, NodeName, ParentId, SequenceNumber, LevelId)
		              SELECT LeafNodeId,NodeName,ParentId,SequenceNumber, LevelId FROM  
					          #ReportingStructure
					          WHERE LeafNodeId = @Id 

		  WHILE(@Id > 0)
		  BEGIN
			INSERT INTO #ReportingStructureTable(LeafNodeId, NodeName, ParentId, SequenceNumber, LevelId)
		              SELECT LeafNodeId,NodeName,ParentId,SequenceNumber,LevelId FROM  
					          #ReportingStructure
					          WHERE ParentId = @Id  ORDER BY SequenceNumber  

            UPDATE #ReportingStructureTable SET IsProcess = 1 WHERE LeafNodeId = @ID 

			SELECT TOP 1 @Id = LeafNodeId FROM #ReportingStructureTable  WHERE IsProcess = 0 ORDER BY ID
			
			IF  (SELECT COUNT(1) FROM  #ReportingStructureTable WHERE IsProcess = 0 ) = 0 
			BEGIN
				SET @Id = 0; 
			END	

		  END

		  UPDATE #ReportingStructureTable SEt IsProcess  = 0		

		  --- ReportingStructureExport
		  IF OBJECT_ID(N'tempdb..#ReportingStructureExport') IS NOT NULL
		  BEGIN
		    DROP TABLE #ReportingStructureExport
		  END		  

		  CREATE TABLE #ReportingStructureExport (
		    ID BIGINT NOT NULL IDENTITY (1, 1),
			LeafNodeId BIGINT NULL,
			ParentId BIGINT NULL,
			NodeName VARCHAR(MAX) NULL,
			SequenceNumber INT NULL,			
			IsProcess BIT DEFAULT (0),
			IsPositive BIT,
			IsTotlaLine BIT DEFAULT 0, 
			LevelId INT NULL,
			IsLeafNode BIT,
		  )
		  
		  ----- START Export code

		  DECLARE @NewLeafNodeId AS int = 0;
		  DECLARE @CurrentLeafNodeId int = 0;
		  DECLARE @CurrentParentId int = 0;
		  DECLARE @HaveChield AS BIT = 0;
		 
		  UPDATE #ReportingStructureTable
				SET ChildCount = ISNULL((SELECT COUNT(ISNULL(T.LeafNodeId, 0))
                                           FROM #ReportingStructureTable T
                                                WHERE T.ParentId = T1.LeafNodeId), 0)
							FROM #ReportingStructureTable T1 

		  UPDATE #ReportingStructureTable SET HaveChield = CASE WHEN ISNULL(ChildCount, 0) > 0 THEN 1 ELSE 0 END
		  
		  SELECT @CurrentLeafNodeId = LeafNodeId, @CurrentParentId = ParentId , @HaveChield = HaveChield FROM #ReportingStructureTable WHERE ParentId = 0
		 
		  ProcessNode:
		  INSERT INTO #ReportingStructureExport(LeafNodeId, NodeName, ParentId, SequenceNumber, LevelId)
			         SELECT LeafNodeId,UPPER(NodeName), ParentId, SequenceNumber, LevelId
					        FROM  #ReportingStructureTable 
							      WHERE LeafNodeId = @CurrentLeafNodeId
		 
		  UPDATE #ReportingStructureTable 
			                  SET IsProcess = 1 WHERE LeafNodeId  = @CurrentLeafNodeId 			
			 
		  IF(@HaveChield > 0) 
			BEGIN				
			      SELECT TOP 1 @CurrentLeafNodeId = LeafNodeId, @HaveChield = HaveChield ,@CurrentParentId =ParentId
					        FROM  #ReportingStructureTable 
							      WHERE ParentId = @CurrentLeafNodeId  ANd IsProcess = 0  
								        ORDER BY SequenceNumber
										
				  INSERT INTO #ReportingStructureExport(LeafNodeId, NodeName, ParentId, SequenceNumber, LevelId)
			             SELECT LeafNodeId,UPPER(NodeName), ParentId, SequenceNumber, LevelId
					            FROM  #ReportingStructureTable 
							           WHERE LeafNodeId = @CurrentLeafNodeId
				 					   
				  UPDATE #ReportingStructureTable 
			                  SET IsProcess = 1 
							  WHERE LeafNodeId  = @CurrentLeafNodeId  
				
				 ---Check Child have child
                  IF(@HaveChield > 0) 
			      BEGIN				
						SELECT TOP 1 @CurrentLeafNodeId = LeafNodeId,@CurrentParentId =ParentId, @HaveChield = HaveChield 
					        FROM  #ReportingStructureTable 
							      WHERE ParentId = @CurrentLeafNodeId  ANd IsProcess = 0  
								        ORDER BY SequenceNumber 
							
                        GOTO ProcessNode;                       
				  END
			END
			
		  ---Find Un Processed Sibling	
		  ProcessSibling:
		  IF EXISTS (SELECT TOP 1 1 FROM  #ReportingStructureTable 
							      WHERE ParentId = @CurrentParentId  ANd IsProcess = 0 )
            BEGIN
				   SELECT TOP 1 @CurrentLeafNodeId = LeafNodeId, @HaveChield = HaveChield ,@CurrentParentId = ParentId
					        FROM  #ReportingStructureTable 
							      WHERE ParentId = @CurrentParentId  ANd IsProcess = 0
								 ORDER BY SequenceNumber
					GOTO ProcessNode;
			END
			---- If SIBLING NOT FOUND find Parent Sibling 
		  
		  IF @CurrentParentId != 0
		  BEGIN
				 INSERT INTO #ReportingStructureExport(LeafNodeId, NodeName, ParentId, SequenceNumber, IsTotlaLine, LevelId)
								 SELECT LeafNodeId, 'TOTAL-' + UPPER(NodeName), ParentId, SequenceNumber, 1, LevelId
										FROM  #ReportingStructureTable 
											   WHERE LeafNodeId = @CurrentParentId

			    SELECT @CurrentParentId = ParentId
					        FROM  #ReportingStructureTable 
							      WHERE LeafNodeId = @CurrentParentId
				GOTO ProcessSibling;
		  END	
		  
		  ----- END Export code

		  UPDATE ESED SET IsPositive = LF.IsPositive, IsLeafNode = LF.IsLeafNode FROM #ReportingStructureExport ESED JOIN dbo.LeafNode LF ON LF.LeafNodeId = ESED.LeafNodeId

		  --Select * from #ReportingStructureExport where LeafNodeId in (92,128)

		  CREATE TABLE #ReportingStructureExportData (
			  ID bigint NOT NULL IDENTITY (1, 1),     
			  leafNodeId BIGINT,
			  NodeName VARCHAR(500), 
			  Amount DECIMAL(18,2),
			  AccountingPeriodId BIGINT,
			  AccountingPeriod VARCHAR(500), 
			  AccountcalMonth VARCHAR(500), 
			  ParentId BIGINT NULL,
			  IsPositive BIT,
			  IsLeafNode BIT,
			  IsBlankHeader bit DEFAULT 0,
			  IsTotlaLine bit DEFAULT 0, 
			  LevelId INT NULL,
			  IsProcess bit DEFAULT 0,
			  ChildCount INT NULL,
			  SequenceNumber INT NULL
		  )

		  DECLARE @LID AS int = 0;
		  DECLARE @IsFristRow AS bit = 1;
		  DECLARE @LCOUNT AS int = 0;
		  SELECT @LCOUNT = MAX(ID) fROM #AccPeriodTable WHERE PeriodName <> 'Total'

		  --SELECT * FROM #AccPeriodTable
		  WHILE(@LCOUNT > 0)
		  BEGIN
			 SELECT @AccountcalMonth = ISNULL(PeriodName, ''), @AccountPeriods = PeriodName, @SequenceNumber = OrderNum FROM #AccPeriodTable where ID = @LCOUNT

			 INSERT INTO #ReportingStructureExportData(leafNodeId, NodeName, Amount, AccountcalMonth, AccountingPeriod, IsPositive, IsLeafNode, ParentId, IsTotlaLine,LevelId, SequenceNumber)
					  SELECT LeafNodeId,UPPER(NodeName), 0, @AccountcalMonth, @AccountPeriods, IsPositive, IsLeafNode, ParentId, IsTotlaLine,LevelId, @SequenceNumber
									FROM  #ReportingStructureExport 

			 --SELECT @LCOUNT
			 --SELECT * FROM #ReportingStructureExportData
			 --SELECT * FROM  #GLBalance
			 --UPDATE GL ACCOUNT SUM AND ASSIGN TO EACH ACCONTING CALENDER MONTH

			 --UPDATE #ReportingStructureExportData 
				--SET Amount = ISNULL(GL.Amount, 0), --CASE WHEN T1.IsPositive = 1 THEN ISNULL(GL.Amount, 0) ELSE ISNULL(GL.Amount, 0) * -1 END, 
				----ISNULL(GL.Amount, 0),
				--	ChildCount = ISNULL((SELECT COUNT(ISNULL(T.Amount, 0))
    --                                       FROM #ReportingStructureExportData T
    --                                            WHERE T.ParentId = T1.LeafNodeId AND T.AccountcalMonth = @AccountcalMonth), 0)
			 --FROM #ReportingStructureExportData T1 
			 --JOIN #GLBalance GL ON T1.LeafNodeId = GL.LeafNodeId AND T1.AccountcalMonth = GL.AccountcalMonth AND T1.AccountcalMonth = @AccountcalMonth

			 UPDATE #ReportingStructureExportData 
				SET Amount = tmpCal.Amount
				FROM(SELECT SUM(ISNULL(GL.Amount, 0)) AS Amount, T.LeafNodeId, T.AccountcalMonth
				FROM #ReportingStructureExportData T 
			JOIN #GLBalance GL ON T.AccountcalMonth = @AccountcalMonth AND T.LeafNodeId = GL.LeafNodeId AND T.AccountcalMonth = GL.AccountcalMonth 
			GROUP BY T.LeafNodeId, T.AccountcalMonth)tmpCal
			WHERE tmpCal.AccountcalMonth = #ReportingStructureExportData.AccountcalMonth AND tmpCal.LeafNodeId = #ReportingStructureExportData.LeafNodeId AND tmpCal.AccountcalMonth = @AccountcalMonth 
					   					
			 --SELECT * FROM #ReportingStructureExportData
			 SET @LCOUNT = @LCOUNT - 1

		  END 

		  --SELECT * FROM #ReportingStructureExport
		  --SELECT * FROM #ReportingStructureExportData where leafNodeId IN (92, 128)

		  UPDATE #ReportingStructureExportData
				SET Amount = CASE WHEN T1.IsPositive = 1 THEN Amount ELSE ISNULL(Amount, 0) * -1 END
		  FROM #ReportingStructureExportData T1  

		  DECLARE @LevelCOUNT AS int = 0;
		  SELECT  @LevelCOUNT = MAX(LevelId) fROM #ReportingStructureExportData  WHERE IsTotlaLine = 1

		  WHILE(@LevelCOUNT > 0)
		  BEGIN
		  	  DECLARE @CLID AS int = 0;
		  	  DECLARE @CAID AS int = 0;
			  DECLARE @AccCalMonth AS VARCHAR(100);

		  	  SELECT @CAID = MAX(ID) fROM #AccPeriodTable WHERE PeriodName <> 'Total'

		  	  WHILE(@CAID > 0)
		  	  BEGIN
		  		 SELECT @AccCalMonth = ISNULL(PeriodName, '') FROM #AccPeriodTable where ID = @CAID
		  
		  		 UPDATE #ReportingStructureExportData 
		  			  SET Amount = (SELECT SUM(ISNULL(CASE WHEN T.IsPositive = 1 THEN 
		  															  ISNULL(Amount, 0) 
		  													ELSE  ISNULL(Amount, 0) * -1
															--ELSE ISNULL(Amount, 0)
		  											   END, 0)) FROM #ReportingStructureExportData T   
		  				  WHERE T.ParentId = RS.leafNodeId AND T.AccountcalMonth = @AccCalMonth AND RS.AccountcalMonth = T.AccountcalMonth)								          
		  		   FROM #ReportingStructureExportData RS
		  				WHERE LevelId = @LevelCOUNT AND IsTotlaLine = 1 AND IsProcess = 0 AND RS.AccountcalMonth = @AccCalMonth
		  
		  		UPDATE #ReportingStructureExportData 
		  			   SET IsProcess = 1
		  			   WHERE LevelId = @LevelCOUNT AND IsTotlaLine = 1 AND AccountcalMonth = @AccCalMonth
		  
		  		SET @CAID = @CAID - 1
		  	END
		  
		  	SET @LevelCOUNT = @LevelCOUNT - 1
		  END

		  INSERT INTO #ReportingStructureExportData(leafNodeId, NodeName, Amount, AccountingPeriodId, AccountcalMonth, AccountingPeriod, IsPositive, IsLeafNode, ParentId, IsTotlaLine,LevelId, SequenceNumber)
					  SELECT LeafNodeId,UPPER(NodeName), 0,999999, 'Total', 'Total', IsPositive, IsLeafNode, ParentId, IsTotlaLine,LevelId, (SELECT ISNULL(MAX(OrderNum), 0) + 1 FROM #AccPeriodTable)
									FROM  #ReportingStructureExport 

		  UPDATE #ReportingStructureExportData 
						  SET Amount = (SELECT SUM(ISNULL(CASE WHEN T.IsPositive = 1 THEN 
															              ISNULL(Amount, 0) 
															    ELSE  ISNULL(Amount, 0) * -1
														   END, 0)) FROM #ReportingStructureExportData T   
						      WHERE T.ParentId = RS.leafNodeId AND T.AccountcalMonth = RS.AccountcalMonth )								          
					FROM #ReportingStructureExportData RS
							WHERE RS.ParentId = 0 AND IsTotlaLine = 1 

			UPDATE #ReportingStructureExportData 
						SET Amount = (SELECT SUM(ISNULL(Amount, 0)) FROM #ReportingStructureExportData T   
						      WHERE T.leafNodeId = RS.leafNodeId AND T.IsTotlaLine = RS.IsTotlaLine)
					FROM #ReportingStructureExportData RS 
						WHERE RS.AccountingPeriod = 'Total'

			UPDATE #ReportingStructureExportData SET AccountingPeriodId = AP.AccountingCalendarId 
			FROM #ReportingStructureExportData RS JOIN dbo.AccountingCalendar AP WITH(NOLOCK) ON RS.AccountcalMonth = REPLACE(AP.PeriodName,' - ','')
			WHERE AP.LegalEntityId = @LegalEntityId

		 SELECT * FROM #ReportingStructureExportData ORDER BY SequenceNumber ASC
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