/*************************************************************           
 ** File:   [USP_GetTrailBalanceJournalBatchData]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used retrieve trialbalance journal batch details by 
					glaccountid
 ** Purpose:         
 ** Date:   07/24/2023  

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    07/24/2023   Devendra Shekh			Created	
    2    08/08/2023   Devendra Shekh			ambiguous column error resolved	
    3    08/10/2023   Devendra Shekh			modified the sp
	4    09/01/2023   Hemant Saliya  Added MS Filters	 
     
--EXEC [USP_GetTrailBalanceJournalBatchData] '1','1','134',2,@xmlFilter=N'
<?xml version="1.0" encoding="utf-16"?>
<ArrayOfFilter xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <Filter>
    <FieldName>Level1</FieldName>
    <FieldValue>5</FieldValue>
  </Filter>
  <Filter>
    <FieldName>Level2</FieldName>
    <FieldValue>8</FieldValue>
  </Filter>
  <Filter>
    <FieldName>Level3</FieldName>
    <FieldValue>11,10</FieldValue>
  </Filter>
  <Filter>
    <FieldName>Level4</FieldName>
    <FieldValue>12</FieldValue>
  </Filter>
  <Filter>
    <FieldName>Level5</FieldName>
    <FieldValue />
  </Filter>
  <Filter>
    <FieldName>Level6</FieldName>
    <FieldValue />
  </Filter>
  <Filter>
    <FieldName>Level7</FieldName>
    <FieldValue />
  </Filter>
  <Filter>
    <FieldName>Level8</FieldName>
    <FieldValue />
  </Filter>
  <Filter>
    <FieldName>Level9</FieldName>
    <FieldValue />
  </Filter>
  <Filter>
    <FieldName>Level10</FieldName>
    <FieldValue />
  </Filter>
</ArrayOfFilter>
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetTrailBalanceJournalBatchData]
(
	@masterCompanyId VARCHAR(50)  = NULL,
	@managementStructureId VARCHAR(50) = NULL,
	@id VARCHAR(50) = NULL,
	@GlAccId BIGINT,
	@xmlFilter XML  
)
AS
BEGIN
	BEGIN TRY
	BEGIN
		
		DECLARE @BatchMSModuleId BIGINT; 
		DECLARE @ManualBatchMSModuleId BIGINT; 
		DECLARE @PostedBatchStatusId BIGINT;
		DECLARE @ManualJournalStatusId BIGINT;

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
		
		SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID
		SET @ManualBatchMSModuleId = 73 -- MANUAL BATCH MS MODULE ID
		SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
		SELECT @ManualJournalStatusId =  ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Manual Batch Details Only

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
		

		IF OBJECT_ID(N'tempdb..#TEMP') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMP
		END 
		IF OBJECT_ID(N'tempdb..#Temptbl') IS NOT NULL    
		BEGIN    
			DROP TABLE #Temptbl
		END 

		SELECT cbd.GlAccountId, (GL.AccountCode + ' - ' +	GL.AccountName) AS 'GlAccount',
			ISNULL(SUM(cbd.CreditAmount),0) AS 'Credit' ,ISNULL(SUM(cbd.DebitAmount),0) AS 'Debit',bd.AccountingPeriod AS 'PeriodName',
			bd.JournalTypeNumber AS 'JournalNumber'
		FROM dbo.CommonBatchDetails cbd  WITH(NOLOCK)
			INNER JOIN dbo.BatchDetails bd WITH(NOLOCK) ON cbd.JournalBatchDetailId = bd.JournalBatchDetailId AND bd.StatusId = @PostedBatchStatusId
			INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = cbd.CommonJournalBatchDetailId AND ModuleId = @BatchMSModuleId
			INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON  cbd.GlAccountId = GL.GLAccountId
		WHERE bd.AccountingPeriodId = @id AND cbd.GlAccountId = @GlAccId AND cbd.MasterCompanyId = @masterCompanyId --AND cbd.ManagementStructureId = @managementStructureId 
			AND cbd.IsDeleted = 0 AND BD.IsDeleted = 0 
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
		GROUP BY cbd.GlAccountId, bd.AccountingPeriod,bd.JournalTypeNumber,GL.AccountCode,GL.AccountName

		UNION ALL

		SELECT cbd.GlAccountId,(GL.AccountCode + ' - ' +	GL.AccountName) AS 'GlAccount' ,
			ISNULL(SUM(cbd.Credit),0) 'Credit',ISNULL(SUM(cbd.Debit),0) 'Debit',ac.PeriodName AS 'PeriodName',
			bd.JournalNumber AS 'JournalNumber'
		FROM dbo.ManualJournalDetails cbd WITH(NOLOCK)
			INNER JOIN dbo.ManualJournalHeader bd WITH(NOLOCK) ON  cbd.ManualJournalHeaderId = bd.ManualJournalHeaderId AND ManualJournalStatusId = @ManualJournalStatusId
			INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON  cbd.GlAccountId = GL.GLAccountId
			INNER JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceId = cbd.ManualJournalDetailsId AND MSD.ModuleId = @ManualBatchMSModuleId
			LEFT JOIN dbo.AccountingCalendar AC WITH(NOLOCK) ON  bd.AccountingPeriodId = AC.AccountingCalendarId
		WHERE bd.AccountingPeriodId = @id AND cbd.GlAccountId = @GlAccId AND cbd.MasterCompanyId = @masterCompanyId --AND cbd.ManagementStructureId = @managementStructureId 
			AND cbd.IsDeleted = 0 AND bd.IsDeleted = 0
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
		GROUP BY cbd.GlAccountId, ac.PeriodName,bd.JournalNumber, GL.AccountCode, GL.AccountName 
		
	END
	END TRY
	BEGIN CATCH
		 DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
					  , @AdhocComments     VARCHAR(150)    = 'USP_GetTrailBalanceJournalBatchData' 
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