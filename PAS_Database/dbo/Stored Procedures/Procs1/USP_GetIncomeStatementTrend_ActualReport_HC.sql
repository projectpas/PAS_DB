/*************************************************************             
 ** File:   [USP_GetIncomeStatementTrend_ActualReport]             
 ** Author: Hemant Saliya  
 ** Description: This stored procedure is used to display income statement(actual) report data
 ** Purpose:           
 ** Date:23/06/2023
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    23/06/2023   Hemant Saliya	  Created
**************************************************************/  

/*************************************************************             

--EXEC [USP_GetIncomeStatementTrend_ActualReport] 1,'153','148',2,1  
************************************************************************/

  
CREATE   PROCEDURE [DBO].[USP_GetIncomeStatementTrend_ActualReport_HC]  

AS  
BEGIN   
 BEGIN TRY  
 
  DECLARE @LeafNodeId as bigint;
  SET @LeafNodeId = 54;
  DECLARE @AccountcalID as bigint;
  SET @AccountcalID = 131;
  DECLARE @MasterCompanyId as bigint = 1
  DECLARE @ReportingStructureId as bigint;
  SET @ReportingStructureId = 8;
  

 IF OBJECT_ID(N'tempdb..#AccTrendTable') IS NOT NULL     
 BEGIN      
	 DROP TABLE #AccTrendTable      
 END

 CREATE TABLE #AccTrendTable (       
			   ID BIGINT NOT NULL IDENTITY(1,1), 
			   LeafNodeId bigint,
			   NodeName varchar(500),    
			   Amount decimal(18,2),
			   AcountingMonth varchar(100),
			   IsBlankHeader bit DEFAULT 0,
			   IsTotlaLine bit DEFAULT 0
		  )  


 IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL     
 BEGIN      
	 DROP TABLE #TempTable    
 ENDCREATE TABLE #TempTable (       			   ID BIGINT NOT NULL IDENTITY(1,1),    			   LeafNodeId BIGINT,			   [Name] varchar(100),			   IsPositive bit null,			   ParentId BIGINT NULL,			   Amount Decimal(18,2) NULL,			   TotalAmount Decimal(18,2) NULL,			   ChildCount int null,			   IsProcess bit DEFAULT(0)		  )   

INSERT INTO #TempTable(LeafNodeId ,[Name],IsPositive,ParentId, IsProcess)
Select LeafNodeId, [Name],IsPositive, ParentId , 0 from dbo.LeafNode where LeafNodeId = @LeafNodeId and IsDeleted = 0 and ReportingStructureId = @ReportingStructureId

DECLARE  @CID as int = 0; 
DECLARE  @CLID as int = 0; 
Select TOP 1 @CID = ID, @CLID = LeafNodeId  FROM #TempTable WHERE IsProcess = 0 ORDER BY ID 

WHILE (@CLID > 0)
BEGIN
INSERT INTO #TempTable (LeafNodeId ,[Name],IsPositive,ParentId, IsProcess)
SELECT LeafNodeId,[Name],IsPositive,@CLID,0 FROM dbo.LeafNode WHERE ParentId = @CLID and IsDeleted = 0 and ReportingStructureId = @ReportingStructureId

SET @CLID = 0;
UPDATE #TempTable SET IsProcess = 1 WHERE ID  = @CID
IF EXISTS(Select TOP 1 ID FROM #TempTable WHERE IsProcess = 0)
BEGIN
Select TOP 1 @CID = ID,@CLID = LeafNodeId  FROM #TempTable WHERE IsProcess = 0 ORDER BY ID 
END

END

UPDATE #TempTable SET Amount = (ISNULL(CBD.CreditAmount,0) - ISNULL(CBD.DebitAmount,0))
		  FROM dbo.LeafNode L WITH(NOLOCK) 
		      INNER JOIN #TempTable T ON L.LeafNodeId = T.LeafNodeId
			  LEFT JOIN dbo.GLAccountLeafNodeMapping GLM WITH(NOLOCK) ON L.LeafNodeId = GLM.LeafNodeId  
			  LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON GLM.GLAccountId = GL.GLAccountId  
			  LEFT JOIN dbo.LeafNode L1 WITH(NOLOCK)  ON L.ParentId = L1.LeafNodeId and  L.ReportingStructureId = @ReportingStructureId
			  OUTER APPLY(  
			   SELECT cb.GLAccountId,SUM(ISNULL(cb.CreditAmount,0)) 'CreditAmount',SUM(ISNULL(cb.DebitAmount,0)) 'DebitAmount',  
				   B.AccountingPeriod,  
				   B.AccountingPeriodId,   
				   REPLACE(B.AccountingPeriod,' - ',' ')  'PeriodName'  
			   FROM dbo.CommonBatchDetails cb WITH(NOLOCK)   
				   INNER JOIN BatchHeader B WITH(NOLOCK) ON  CB.JournalBatchHeaderId = B.JournalBatchHeaderId AND B.AccountingPeriodId = @AccountcalID AND B.MasterCompanyId = @MasterCompanyId  
			   WHERE GLM.GLAccountId = cb.GlAccountId AND b.AccountingPeriodId = @AccountcalID AND CB.ManagementStructureId = 1  
			   GROUP BY cb.GlAccountId,B.AccountingPeriod,B.AccountingPeriodId  
			  )CBD  
		  WHERE L.ReportingStructureId = @ReportingStructureId AND L.IsDeleted = 0 and L.MasterCompanyId = @MasterCompanyId 

UPDATE #TempTable
         SET ChildCount =   ISNULL((SELECT Count(ISNULL(T.Amount,0)) FROM #TempTable T WHERE T.ParentId = T1.LeafNodeId ),0),
		     Amount = CASE WHEN T1.IsPositive = 1 THEN Amount ELSE ISNULL(Amount,0) * -1 END
          FROM #TempTable T1 


UPDATE #TempTable SET IsProcess =0
SET @CID = 0; 
SET @CLID = 0;
Select TOP 1 @CID = ID FROM #TempTable WHERE IsProcess = 0 ORDER BY ID DESC 
WHILE (@CID > 0)
BEGIN
Select TOP 1 @CLID = LeafNodeId FROM #TempTable WHERE ID = @CID
UPDATE #TempTable SET Amount =  CASE WHEN IsPositive = 1 THEN (SELECT SUM(ISNULL(T.Amount,0)) FROM #TempTable T WHERE T.ParentId = @CLID ) ELSE ISNULL((SELECT SUM(ISNULL(T.Amount,0)) FROM #TempTable T WHERE T.ParentId = @CLID ),0) * -1 END   WHERE ID  = @CID and ChildCount > 0
UPDATE #TempTable SET IsProcess = 1 WHERE ID  = @CID

SET @CID = 0;
SET @CLID = 0;
IF EXISTS(Select TOP 1 ID FROM #TempTable WHERE IsProcess = 0)
BEGIN
Select TOP 1 @CID = ID  FROM #TempTable WHERE IsProcess = 0  ORDER BY ID DESC
END

END

UPDATE #TempTable    
       SET IsProcess =0	       
	   FROM #TempTable T1
SET @CID = 0; 
SET @CLID = 0;
Select TOP 1 @CID = ID FROM #TempTable WHERE IsProcess = 0 ORDER BY ID DESC 
WHILE (@CID > 0)
BEGIN

Select TOP 1 @CLID = ParentId FROM #TempTable WHERE ID = @CID

IF NOT EXISTS(Select TOP 1 ID FROM #AccTrendTable WHERE LeafNodeId = @CLID AND IsBlankHeader = 1) 
BEGIN
INSERT INTO #AccTrendTable (LeafNodeId,NodeName,Amount,AcountingMonth,IsBlankHeader)
            SELECT TOP 1 LeafNodeId,Name,NULL,NULL,1 FROM #TempTable WHERE LeafNodeId = @CLID ANd ChildCount >0
END

INSERT INTO #AccTrendTable (LeafNodeId,NodeName,Amount,AcountingMonth,IsBlankHeader)
SELECT LeafNodeId,Name,Amount,'APRIL-2023',0 FROM #TempTable WHERE ID = @CID AND ChildCount = 0
UPDATE #TempTable SET IsProcess = 1 WHERE ID  = @CID

IF NOT EXISTS(Select TOP 1 ID FROM #TempTable WHERE ParentId = @CLID AND IsProcess = 0)
BEGIN
IF NOT EXISTS(Select TOP 1 ID FROM #AccTrendTable WHERE LeafNodeId = @CLID AND IsTotlaLine = 1)             
BEGIN
INSERT INTO #AccTrendTable (LeafNodeId,NodeName,Amount,AcountingMonth,IsBlankHeader,IsTotlaLine)
SELECT LeafNodeId,'Total - ' + Name,Amount,'APRIL-2023',0,1 FROM #TempTable WHERE  LeafNodeId = @CLID AND ChildCount > 0
END
END




SET @CID = 0;
SET @CLID = 0;
IF EXISTS(Select TOP 1 ID FROM #TempTable WHERE IsProcess = 0)
BEGIN
Select TOP 1 @CID = ID  FROM #TempTable WHERE IsProcess = 0  ORDER BY ID DESC
END

END


SELECT * from #TempTable
SELECT * FROM #AccTrendTable

  
    
 END TRY  
 BEGIN CATCH  
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
					  , @AdhocComments     VARCHAR(150)    = 'USP_GetIncomeStatementTrend_ActualReport' 
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