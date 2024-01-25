/*************************************************************             
 ** File:   [RPT_GetBalanceSheetReportsExportData]             
 ** Author:  Hemnat Saliya
 ** Description: This stored procedure is used to Get balance sheet report Data 
 ** Purpose: Initial Draft           
 ** Date: 05/09/2023  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    20/09/2023   Hemnat Saliya  Created
	2    30/10/2023   Hemnat Saliya  Updated For GL Balance
	3    25/01/2024   Hemant Saliya	 Remove Manual Journal from Reports

************************************************************************
EXEC [RPT_GetBalanceSheetReportsExportData] 137,137,23,1,1,0, @strFilter=N'1,5,6,52!2,7,8,9!3,11,10!4,12,13'
************************************************************************/
  
CREATE   PROCEDURE [dbo].[RPT_GetBalanceSheetReportsExportData]  
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
		  DECLARE @AccountcalID AS bigint;
		  DECLARE @AccountPeriods VARCHAR(max);  
		  DECLARE @AccountPeriodIds VARCHAR(max);  
		  DECLARE @LegalEntityId BIGINT;
		  DECLARE @PostedBatchStatusId BIGINT;
		  --DECLARE @ManualJournalStatusId BIGINT;
		  DECLARE @BatchMSModuleId BIGINT; 
		  --DECLARE @ManualBatchMSModuleId BIGINT; 
		  DECLARE @AssetGLAccountTypeId AS BIGINT;
		  DECLARE @LiabilitiesGLAccountTypeId AS BIGINT;
		  DECLARE @EquityGLAccountTypeId AS BIGINT;
		  DECLARE @SequenceNumber INT; 
		  DECLARE @IsDebugMode BIT = 0; 

		  SET @IsDebugMode = 0;

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
		  
		  DECLARE 
		  @MAXCalTempID INT = 0, @INITIALFROMDATE DATETIME,@INITIALENDDATE DATETIME;

		  IF(@EndAccountingPeriodId is null OR @EndAccountingPeriodId = 0)
	      BEGIN
		    SET @EndAccountingPeriodId = @StartAccountingPeriodId;
		  END

		  SELECT @INITIALFROMDATE = MIN(FromDate) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND IsDeleted = 0  
		  SELECT @FROMDATE = FromDate, @LegalEntityId = LegalEntityId FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId AND IsDeleted = 0
		  SELECT @TODATE = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @EndAccountingPeriodId AND IsDeleted = 0 
		  SELECT @AssetGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Asset' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		  SELECT @LiabilitiesGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Liabilities' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		  SELECT @EquityGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Owners Equity' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
		  SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
		  --SELECT @ManualJournalStatusId =  ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Manual Batch Details Only
		  SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID
		  --SET @ManualBatchMSModuleId = 73 -- MANUAL BATCH MS MODULE ID

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

		  IF OBJECT_ID(N'tempdb..#GLBalance') IS NOT NULL
		  BEGIN
		    DROP TABLE #GLBalance
		  END
    	  
		  CREATE TABLE #GLBalance (
		    ID bigint NOT NULL IDENTITY (1, 1),
		    LeafNodeId bigint,
		    AccountingPeriodId bigint NULL,
			AccountingPeriod VARCHAR(200),
		    CreaditAmount decimal(18, 2) NULL,
		    DebitAmount decimal(18, 2) NULL,
		    Amount decimal(18, 2) NULL,
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
			OrderNum INT NULL
		  )

		  INSERT INTO #AccPeriodTable (AccountcalID, PeriodName, FromDate, ToDate,[OrderNum]) 
		  SELECT AccountingCalendarId, REPLACE(PeriodName,' - ','') ,FromDate, ToDate, [Period]
		  FROM dbo.AccountingCalendar WITH(NOLOCK)
		  WHERE LegalEntityId = @LegalEntityId 
		  	AND IsDeleted = 0 AND  CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE) 
		  
		  INSERT INTO #AccPeriodTable (AccountcalID, PeriodName) 
		  VALUES(9999999,'Total')

		  IF(@IsDebugMode = 1)
		  BEGIN
		  SELECT 'AccPeriodTable'
		  SELECT * FROM #AccPeriodTable
		  END

		  
		  SELECT @MAXCalTempID = MAX(ID) fROM #AccPeriodTable
		  WHILE(@MAXCalTempID > 0)
		  BEGIN
		  		SELECT  @AccountcalID = AccountcalID, @INITIALENDDATE = ToDate FROM #AccPeriodTable where ID = @MAXCalTempID

				DELETE FROM #AccPeriodTable_All

				INSERT INTO #AccPeriodTable_All (AccountcalID, PeriodName, FromDate, ToDate) 
				SELECT AccountingCalendarId, REPLACE(PeriodName,' - ',' ') ,FromDate,ToDate
				FROM dbo.AccountingCalendar WITH(NOLOCK)
				WHERE LegalEntityId IN (SELECT MSL.LegalEntityId FROM dbo.ManagementStructureLevel MSL WITH (NOLOCK) WHERE MSL.ID IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND IsDeleted = 0 AND  
					CAST(Fromdate AS DATE) >= CAST(@INITIALFROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@INITIALENDDATE AS DATE)  AND ISNULL(IsAdjustPeriod, 0) = 0 
				ORDER BY FiscalYear, [Period]
		  
		  	  INSERT INTO #GLBalance (LeafNodeId, AccountingPeriodId, DebitAmount, CreaditAmount,  Amount)
		  		(SELECT DISTINCT LF.LeafNodeId , @AccountcalID, 
		  				CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END 'DebitAmount',
						CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END 'CreditAmount',
						CASE WHEN GL.GLAccountTypeId = @AssetGLAccountTypeId THEN
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END) - 
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) 
						ELSE
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.CreditAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.CreditAmount, 0)), 0) * -1 END) -
							(CASE WHEN ISNULL(GLM.IsPositive, 0) = 1 THEN SUM(ISNULL(CMD.DebitAmount, 0)) ELSE ISNULL(SUM(ISNULL(CMD.DebitAmount, 0)), 0) * -1 END)
						END AS AMONUT
		  		FROM dbo.CommonBatchDetails CMD WITH (NOLOCK)
		  			INNER JOIN dbo.BatchDetails BD WITH (NOLOCK) ON CMD.JournalBatchDetailId = BD.JournalBatchDetailId AND BD.StatusId = @PostedBatchStatusId
					INNER JOIN dbo.BatchHeader B WITH (NOLOCK) ON BD.JournalBatchHeaderId = B.JournalBatchHeaderId 
		  			INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = CMD.CommonJournalBatchDetailId AND ModuleId = @BatchMSModuleId
		  			INNER JOIN dbo.GLAccountLeafNodeMapping GLM WITH (NOLOCK) ON CMD.GlAccountId = GLM.GLAccountId
		  			INNER JOIN dbo.GLAccount GL WITH (NOLOCK) ON GL.GlAccountId = CMD.GLAccountId AND GL.GLAccountTypeId IN (@AssetGLAccountTypeId, @LiabilitiesGLAccountTypeId,@EquityGLAccountTypeId) 
		  			INNER JOIN dbo.LeafNode LF ON LF.LeafNodeId = GLM.LeafNodeId AND LF.IsDeleted = 0 AND ISNULL(ReportingStructureId, 0) = @ReportingStructureId
		  		WHERE CMD.IsDeleted = 0 AND GLM.IsDeleted = 0 AND BD.IsDeleted = 0 AND CMD.MasterCompanyId = @MasterCompanyId 	
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
		  				AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
		  		GROUP BY LF.LeafNodeId, GLM.IsPositive, GL.GLAccountTypeId)
		  
		  	SET @MAXCalTempID = @MAXCalTempID - 1;
		  END

		  IF(@IsDebugMode = 1)
		  BEGIN
		  SELECT 'GL BALANCE'
		  SELECT * FROM #GLBalance
		  END

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
				FROM  LeafNode l1
				WHERE ParentId IS NULL and ReportingStructureId = @ReportingStructureId and IsDeleted = 0
     
				UNION ALL

				SELECT Parent.LeafNodeId, 
					  Parent.Name, 
					  Parent.ParentId, 
					  Parent.SequenceNumber, 
					  [level] + 1 AS level,
					  CAST(order_sequence + '_' + CAST(parent.LeafNodeId AS VARCHAR (50)) AS VARCHAR(50)) AS order_sequence
				FROM  LeafNode Parent
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

		  --SELECT * from #ReportingStructureExport
		  --SELECT * from #ReportingStructureTable

		  UPDATE ESED SET IsPositive = LF.IsPositive, IsLeafNode = LF.IsLeafNode FROM #ReportingStructureExport ESED JOIN dbo.LeafNode LF ON LF.LeafNodeId = ESED.LeafNodeId

		  CREATE TABLE #ReportingStructureExportData (
			  ID bigint NOT NULL IDENTITY (1, 1),     
			  leafNodeId BIGINT,
			  NodeName VARCHAR(500), 
			  Amount DECIMAL(18,2),
			  AccountingPeriodId BIGINT,
			  AccountingPeriod VARCHAR(500), 
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
		  
		  --SELECT * FROM #AccPeriodTable
		  --SELECT * FROM #ReportingStructureExportData

		  DECLARE @LID AS int = 0;
		  DECLARE @IsFristRow AS bit = 1;
		  DECLARE @LCOUNT AS int = 0;
		  SELECT @LCOUNT = MAX(ID) fROM #AccPeriodTable WHERE PeriodName <> 'Total'
		  WHILE(@LCOUNT > 0)
		  BEGIN
			 SELECT  @AccountcalID = AccountcalID, @AccountPeriods = PeriodName, @SequenceNumber = OrderNum FROM #AccPeriodTable WHERE ID = @LCOUNT

			 INSERT INTO #ReportingStructureExportData(leafNodeId, NodeName, Amount, AccountingPeriodId, AccountingPeriod, IsPositive, IsLeafNode, ParentId, IsTotlaLine,LevelId, SequenceNumber)
					  SELECT LeafNodeId,UPPER(NodeName), 0, @AccountcalID, @AccountPeriods, IsPositive, IsLeafNode, ParentId, IsTotlaLine,LevelId, @SequenceNumber
									FROM  #ReportingStructureExport 

			 --UPDATE GL ACCOUNT SUM AND ASSIGN TO EACH ACCONTING CALENDER MONTH

			 UPDATE #ReportingStructureExportData 
			 SET ChildCount = ISNULL((SELECT COUNT(ISNULL(T.Amount, 0))
                                           FROM #ReportingStructureExportData T
                                                WHERE T.ParentId = #ReportingStructureExportData.AccountingPeriodId AND T.AccountingPeriodId = @AccountcalID), 0),
			 
				Amount = tmpCal.Amount
					FROM(SELECT SUM(ISNULL(GL.Amount, 0)) AS Amount, T.LeafNodeId, T.AccountingPeriodId
						FROM #ReportingStructureExportData T 
							JOIN #GLBalance GL ON T.AccountingPeriodId = @AccountcalID AND T.LeafNodeId = GL.LeafNodeId AND T.AccountingPeriodId = GL.AccountingPeriodId --AND T.AccountingPeriodId = GL.AccountingPeriodId
						GROUP BY T.LeafNodeId, T.AccountingPeriodId
				)tmpCal WHERE tmpCal.AccountingPeriodId = #ReportingStructureExportData.AccountingPeriodId AND tmpCal.LeafNodeId = #ReportingStructureExportData.LeafNodeId AND tmpCal.AccountingPeriodId = @AccountcalID 
			

			 --UPDATE #ReportingStructureExportData 
				--SET Amount = ISNULL(GL.Amount, 0),


				--	ChildCount = ISNULL((SELECT COUNT(ISNULL(T.Amount, 0))
    --                                       FROM #ReportingStructureExportData T
    --                                            WHERE T.ParentId = T1.LeafNodeId AND T.AccountingPeriodId = @AccountcalID), 0)
			 --FROM #ReportingStructureExportData T1 
			 --JOIN #GLBalance GL ON T1.AccountingPeriodId = @AccountcalID AND T1.LeafNodeId = GL.LeafNodeId AND T1.AccountingPeriodId = GL.AccountingPeriodId

			 SET @LCOUNT = @LCOUNT - 1

		  END 

		  UPDATE #ReportingStructureExportData
           SET Amount = CASE WHEN T1.IsPositive = 1 THEN Amount
				              ELSE ISNULL(Amount, 0) * -1
                         END
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
		  		 SELECT @AccCalMonth = ISNULL(PeriodName, ''), @AccountcalID = AccountcalID FROM #AccPeriodTable where ID = @CAID
		  
		  		 UPDATE #ReportingStructureExportData 
		  			  SET Amount = (SELECT SUM(ISNULL(CASE WHEN T.IsPositive = 1 THEN 
		  															  ISNULL(Amount, 0) 
		  													ELSE  ISNULL(Amount, 0) * -1
		  											   END, 0)) FROM #ReportingStructureExportData T   
		  				  WHERE T.ParentId = RS.leafNodeId AND T.AccountingPeriodId = RS.AccountingPeriodId)									          
		  		   FROM #ReportingStructureExportData RS
		  				WHERE LevelId = @LevelCOUNT AND IsTotlaLine = 1 AND IsProcess = 0 AND RS.AccountingPeriodId = @AccountcalID
		  
		  			UPDATE #ReportingStructureExportData 
		  				   SET IsProcess = 1
		  				   WHERE LevelId = @LevelCOUNT AND IsTotlaLine = 1 AND AccountingPeriodId = @AccountcalID
		  
		  			SET @CAID = @CAID - 1
		  		END

			SET @LevelCOUNT = @LevelCOUNT - 1
		  END

		  INSERT INTO #ReportingStructureExportData(leafNodeId, NodeName, Amount, AccountingPeriodId, AccountingPeriod, IsPositive, IsLeafNode, ParentId, IsTotlaLine,LevelId, SequenceNumber)
					  SELECT LeafNodeId,UPPER(NodeName), 0,999999, 'Total', IsPositive, IsLeafNode, ParentId, IsTotlaLine,LevelId, (SELECT ISNULL(MAX(OrderNum), 0) + 1 FROM #AccPeriodTable)
									FROM  #ReportingStructureExport 

		 UPDATE #ReportingStructureExportData 
						  SET Amount = (SELECT SUM(ISNULL(CASE WHEN T.IsPositive = 1 THEN 
															              ISNULL(Amount, 0) 
															    ELSE  ISNULL(Amount, 0) * -1
														   END, 0)) FROM #ReportingStructureExportData T   
						      WHERE T.ParentId = RS.leafNodeId AND T.AccountingPeriodId = RS.AccountingPeriodId )								          
					FROM #ReportingStructureExportData RS
							WHERE RS.ParentId = 0 AND IsTotlaLine = 1 

			UPDATE #ReportingStructureExportData 
						SET Amount = (SELECT SUM(ISNULL(Amount, 0)) FROM #ReportingStructureExportData T   
						      WHERE T.leafNodeId = RS.leafNodeId AND T.IsTotlaLine = RS.IsTotlaLine)
					FROM #ReportingStructureExportData RS 
						WHERE RS.AccountingPeriod = 'Total'

		  SELECT * FROM #ReportingStructureExportData ORDER BY SequenceNumber ASC
 END TRY  
 BEGIN CATCH  
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
					  , @AdhocComments     VARCHAR(150)    = 'RPT_GetBalanceSheetReportsExportData' 
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