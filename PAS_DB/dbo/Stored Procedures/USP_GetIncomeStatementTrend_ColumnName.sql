/*************************************************************             
 ** File:   [USP_GetIncomeStatementTrend_ActualReport]             
 ** Author: Hemant Saliya  
 ** Description: This stored procedure is used to display income statement(actual) report data
 ** Purpose: Initial Draft           
 ** Date: 23/06/2023  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    23/06/2023   Hemant Saliya  Created
**************************************************************/  

/*************************************************************             

--EXEC [USP_GetIncomeStatementTrend_ColumnName] 1,'128','133',8,1  
************************************************************************/
  
CREATE   PROCEDURE [dbo].[USP_GetIncomeStatementTrend_ColumnName]  
(  
 @ReportingStructureId BIGINT = NULL,  
 @masterCompanyId BIGINT,  
 @managementStructureId BIGINT = NULL,
 @StartAccountingPeriodId BIGINT = NULL,   
 @EndAccountingPeriodId BIGINT = NULL 
)  
AS  
BEGIN   
 BEGIN TRY  
		  IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL      
		  BEGIN      
		   DROP TABLE #TempTable      
		  END  
  
		  IF OBJECT_ID(N'tempdb..#AccPeriodTempTable') IS NOT NULL      
		  BEGIN      
		   DROP TABLE #AccPeriodTempTable      
		  END  
     
		  DECLARE @COUNT BIGINT;  
		  DECLARE @PARENTID BIGINT;   
		  DECLARE @LeafNodeId BIGINT;   
		  DECLARE @IsPositive BIT;   
		  DECLARE @PosAmount DECIMAL(18,2);   
		  DECLARE @NegAmount DECIMAL(18,2);   
		  DECLARE @GlAcc VARCHAR(10);  
		  DECLARE @query VARCHAR(MAX) = '';  
		  DECLARE @FromAccountPeriod VARCHAR(100) = '';
		  DECLARE @ToAccountPeriod VARCHAR(100) = '';
		  DECLARE @FromAccountPeriodId BIGINT;   
		  DECLARE @ToAccountPeriodId BIGINT;   
		  DECLARE @LegalEntityId BIGINT;   
		  
		  DECLARE @FROMDATE DATETIME;
		  DECLARE @TODATE DATETIME;  
		  DECLARE @AccountPeriods VARCHAR(max);  
		  DECLARE @AccountPeriodIds VARCHAR(max);  

		  SELECT @FROMDATE = FromDate, @FromAccountPeriod = PeriodName, @LegalEntityId = LegalEntityId FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartAccountingPeriodId AND IsDeleted = 0  
		  SELECT @TODATE = ToDate, @ToAccountPeriod = PeriodName FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @EndAccountingPeriodId AND IsDeleted = 0  

		  CREATE TABLE #TempTable (       
			   ID BIGINT NOT NULL IDENTITY(1,1),    
			   LeafNodeId BIGINT,    
			   Name varchar(MAX),  
			   ParentId BIGINT,  
			   ParentName VARCHAR(MAX),
			   GlAccountId Int,  
			   GlAccountName varchar(MAX),  
			   Amount decimal(18,2),  
			   PeriodId BIGINT,  
			   PeriodName VARCHAR(50),  
			   DisplayPeriodName VARCHAR(50),  
			   SequenceNumber BIGINT,
			   IsPositive bit  
		  )    
  
		  CREATE TABLE #AccPeriodTempTable (
			   headerName VARCHAR(50),
			   fieldName VARCHAR(50),
			   fieldGridWidth VARCHAR(50),
			   fieldSortOrder BIT,
			   isNumString BIT,
			   isRightAlign BIT,			   
			   PeriodId INT,  
			   PeriodName VARCHAR(50)  
		  ) 
		  
		  SELECT @AccountPeriodIds = STUFF((SELECT ',' + CAST(AccountingCalendarId AS varchar(MAX))  
				FROM dbo.AccountingCalendar WITH(NOLOCK)
				WHERE LegalEntityId = @LegalEntityId and IsDeleted = 0 and  
		  CAST(Fromdate AS DATE) >= CAST(@FROMDATE AS DATE) and CAST(ToDate AS DATE) <= CAST(@TODATE AS DATE)  
				FOR xml PATH ('')), 1, 1, '')   

		  INSERT INTO #TempTable(LeafNodeId,Name,ParentId,ParentName,GlAccountId,GlAccountName,Amount,PeriodId,PeriodName,IsPositive,DisplayPeriodName,SequenceNumber)  
			SELECT L.LeafNodeId,L.Name,L.ParentId,L1.Name,GLM.GLAccountId,GL.AccountName,(ISNULL(CBD.CreditAmount,0) - ISNULL(CBD.DebitAmount,0)),CBD.AccountingPeriodId,ISNULL(CBD.PeriodName,'Other'),l.IsPositive,CBD.AccountingPeriod, L.SequenceNumber  
		  FROM dbo.LeafNode L WITH(NOLOCK)  
			  LEFT JOIN dbo.GLAccountLeafNodeMapping GLM WITH(NOLOCK) ON L.LeafNodeId = GLM.LeafNodeId  
			  LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON GLM.GLAccountId = GL.GLAccountId  
			  LEFT JOIN dbo.LeafNode L1 WITH(NOLOCK)  ON L.ParentId = L1.LeafNodeId
			  OUTER APPLY(  
			   SELECT cb.GLAccountId,SUM(ISNULL(cb.CreditAmount,0)) 'CreditAmount',SUM(ISNULL(cb.DebitAmount,0)) 'DebitAmount',  
				   B.AccountingPeriod,  
				   B.AccountingPeriodId,   
				   REPLACE(B.AccountingPeriod,' - ',' ')  'PeriodName'  
			   FROM dbo.CommonBatchDetails cb WITH(NOLOCK)   
				   INNER JOIN BatchHeader B WITH(NOLOCK) ON  CB.JournalBatchHeaderId = B.JournalBatchHeaderId AND B.AccountingPeriodId IN (SELECT * FROM SplitString(@AccountPeriodIds,',')) AND B.MasterCompanyId = @MasterCompanyId  
			   WHERE GLM.GLAccountId = cb.GlAccountId AND CAST(cb.TransactionDate AS date) BETWEEN CAST(@FromDate AS date) AND CAST(@Todate AS date) AND CB.ManagementStructureId = @ManagementStructureId  
			   GROUP BY cb.GlAccountId,B.AccountingPeriod,B.AccountingPeriodId  
			  )CBD  
		  WHERE L.ReportingStructureId = @ReportingStructureId AND L.IsDeleted = 0 and L.MasterCompanyId = @MasterCompanyId  
		  ORDER BY L.SequenceNumber 
		  
		  INSERT INTO #AccPeriodTempTable(PeriodId,PeriodName, fieldGridWidth, isNumString, isRightAlign)
		  VALUES(0, 'name', '', 0, 0)

		  INSERT INTO #AccPeriodTempTable(PeriodId,PeriodName, fieldGridWidth, isNumString, isRightAlign)  
		  SELECT DISTINCT PeriodId,PeriodName, '', 1, 1 FROM #TempTable 

		  UPDATE #AccPeriodTempTable SET PeriodId = 999999, PeriodName = 'Total', fieldGridWidth = '', isNumString = 1, isRightAlign = 1 WHERE PeriodName = 'Other'

		  UPDATE #AccPeriodTempTable SET headerName = PeriodName, fieldName = REPLACE(PeriodName,' ','')  

		  SELECT * FROM #AccPeriodTempTable ORDER BY PeriodId

 END TRY  
 BEGIN CATCH  
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
					  , @AdhocComments     VARCHAR(150)    = 'USP_GetIncomeStatementTrend_ColumnName' 
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