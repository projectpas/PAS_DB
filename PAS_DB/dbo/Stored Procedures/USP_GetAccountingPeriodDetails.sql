/*************************************************************             
 ** File:   [USP_GetAccountingPeriodDetails]             
 ** Author:   Satish Gohil  
 ** Description: This stored procedure is used to Validate Accounting Period open/close
 ** Purpose:           
 ** Date:   19/05/2023     
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
    1    19/05/2023   Satish Gohil  Created     
	2    25/05/2023   Satish Gohil  Modify (Added Next Acc Period Id)
	3    01/06/2023   Satish Gohil  Convert Into Dynamic query for Status Condition
	4    22/06/2023   Satish Gohil  Remove duplication insert validation
	5    1/11/2023    Ayesha Sultana     Unpost batch restrictions on closed batch
	6    2/11/2023    Ayesha Sultana     Unpost batch restrictions on closed batch - bug fix
**************************************************************/  

CREATE        PROCEDURE [dbo].[USP_GetAccountingPeriodDetails]  
(  
 @BatchId VARCHAR(MAX) = '',  
 @UserName VARCHAR(100)  
)  
AS  
BEGIN   
 SET NOCOUNT ON;    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  
 BEGIN TRY  
	   IF OBJECT_ID(N'tempdb..#BatchTable') IS NOT NULL    
		  BEGIN    
			DROP TABLE #BatchTable    
		  END    
    
	   IF OBJECT_ID(N'tempdb..#ErrorMsg') IS NOT NULL    
		  BEGIN    
			DROP TABLE #ErrorMsg    
		  END    
  
	   DECLARE @ROWCOUNT INT = 0;  
	   DECLARE @MANAGEMENTId BIGINT = 0;  
	   DECLARE @AccountingCalendarId BIGINT = 0;  
	   DECLARE @Date DateTime2(7);  
	   DECLARE @ClosePeriodName VARCHAR(20)  
	   DECLARE @NextOpenPeriodName VARCHAR(20)  
	   DECLARE @NextOpenPeriodId VARCHAR(20)    
	   DECLARE @MSG VARCHAR(MAX);  
	   DECLARE @ID INT = 1;  
	   DECLARE @MasterCompanyId INT;  
	   DECLARE @str nvarchar(max)
	   DECLARE @Col VARchar(MAX)
	   DECLARE @JEType varchar(10)

	   DECLARE @POSTED VARCHAR(10) = ''
	   DECLARE @UNPOSTED VARCHAR(10) = ''

	   select @POSTED = StatusName from  dbo.BatchHeader with(nolock) WHERE StatusName='Posted' AND JournalBatchHeaderId=@BatchId
	   select @UNPOSTED = StatusName from  dbo.BatchHeader with(nolock) WHERE StatusName='Open' AND JournalBatchHeaderId=@BatchId
    
	   CREATE TABLE #BatchTable (     
		  ID BIGINT NOT NULL IDENTITY(1,1),  
		  BatchId BIGINT,  
		  AccuntingPeriodId INT,   
		  MasterCompanyId INT,  
		  CreatedDate DateTime2(7)  
	   )  
  
	   CREATE TABLE #ErrorMsg  
	   (     
			Msg VARCHAR(max),  
			isValid bit,
			NextPeriodid bigint,
			BatchId bigint
		)  
  
	  INSERT INTO #BatchTable (BatchId,AccuntingPeriodId,MasterCompanyId,CreatedDate) 
	  SELECT JournalBatchHeaderId,ISNULL(AccountingPeriodId,0),MasterCompanyId,CreatedDate  
	  FROM dbo.BatchHeader with(nolock) WHERE JournalBatchHeaderId IN(SELECT ITEM FROM DBO.SplitString(@BatchId,','));  
  
	  SELECT @MasterCompanyId = MasterCompanyID FROM dbo.BatchHeader with(nolock) WHERE JournalBatchHeaderId = (SELECT top(1) MasterCompanyId from #BatchTable)  
    
	  SELECT @ROWCOUNT = COUNT(*) FROM #BatchTable  

	  WHILE @ID <= @ROWCOUNT  
	  BEGIN  
	   SET @AccountingCalendarId = 0;  
  
	   IF((SELECT ISNULL(AccuntingPeriodId,0) FROM #BatchTable where ID = @ID) = 0)  
	   BEGIN   
		SELECT @MANAGEMENTId = ISNULL(ManagementStructureId,0) from dbo.Employee with(nolock) where (FirstName + ' ' + LastName) = @UserName and MasterCompanyId = @MasterCompanyId  
		SELECT @Date = CreatedDate FROM #BatchTable where ID = @ID  

		SELECT @AccountingCalendarId = ISNULL(AccountingCalendarId,0)  
		FROM dbo.EntityStructureSetup est with(nolock)  
		LEFT JOIN dbo.ManagementStructureLevel msl with(nolock) on est.Level1Id = msl.ID  
		LEFT JOIN dbo.AccountingCalendar acc with(nolock) on msl.LegalEntityId = acc.LegalEntityId  
		WHERE est.EntityStructureId = @MANAGEMENTId AND @Date >= acc.FromDate AND @Date <= acc.ToDate AND acc.IsDeleted = 0 --AND ISNULL(acc.Status,'Closed') = 'Closed'  
	   END  
	   ELSE  
	   BEGIN  

		SELECT @AccountingCalendarId = ISNULL(AccountingCalendarId,0) FROM dbo.AccountingCalendar with(nolock)   
		WHERE AccountingCalendarId = (SELECT ISNULL(AccuntingPeriodId,0) FROM #BatchTable where ID = @ID)  
		AND IsDeleted = 0 --AND ISNULL(Status,'Closed') = 'Closed'  
	   END  

	   IF(ISNULL(@AccountingCalendarId,0) > 0)  
	   BEGIN        
		 SELECT @JEType = J.BatchType
		 FROM dbo.BatchHeader B WITH(NOLOCK)
		 INNER JOIN #BatchTable BT ON B.JournalBatchHeaderId = BT.BatchId
		 INNER JOIN dbo.JournalType J WITH(NOLOCK) ON B.JournalTypeId = J.ID
		 WHERE BT.ID = @ID

		SET @str = 'SELECT @ClosePeriodName = ISNULL(B.PeriodName,''''),@NextOpenPeriodName =ISNULL(ACC.PeriodName,''''),@NextOpenPeriodId = ISNULL(ACC.AccountingCalendarId,0)
		FROM dbo.AccountingCalendar A with(nolock) 
		 LEFT JOIN dbo.AccountingCalendar B with(nolock) ON A.AccountingCalendarId = B.AccountingCalendarId ' 
		 +CASE WHEN @JEType = 'AR' THEN ' AND ISNULL(B.isacrStatusName,0) = 0'
			WHEN @JEType = 'AP' THEN ' AND ISNULL(B.isacpStatusName,0) = 0'
			WHEN @JEType = 'ASSET' THEN ' AND ISNULL(B.isassetStatusName,0) = 0'
			WHEN @JEType = 'INV' THEN ' AND ISNULL(B.isinventoryStatusName,0) = 0'
			WHEN @JEType = 'GEN' THEN ' AND ISNULL(B.isaccStatusName,0) = 0' ELSE '' END +
			' OUTER APPLY(SELECT TOP 1 AccountingCalendarId,ISNULL(C.PeriodName,'''') PeriodName FROM
				dbo.AccountingCalendar C with(nolock) 
				WHERE A.LegalEntityId = C.LegalEntityId AND C.FromDate > A.ToDate' + 
				CASE WHEN @JEType = 'AR' THEN ' AND ISNULL(C.isacrStatusName,0) = 1'
				WHEN @JEType = 'AP' THEN ' AND ISNULL(C.isacpStatusName,0) = 1'
				WHEN @JEType = 'ASSET' THEN ' AND ISNULL(C.isassetStatusName,0) = 1'
				WHEN @JEType = 'INV' THEN ' AND ISNULL(C.isinventoryStatusName,0) = 1'
				WHEN @JEType = 'GEN' THEN ' AND ISNULL(C.isaccStatusName,0) = 1' ELSE '' END +'
			)ACC
			WHERE A.AccountingCalendarId = '''+CONVERT(VARCHAR(10),@AccountingCalendarId)+''''

		EXECUTE sp_executesql @str, N'@AccountingCalendarId nvarchar(10), @ClosePeriodName nvarchar(10) OUTPUT,@NextOpenPeriodName nvarchar(10) OUTPUT,@NextOpenPeriodId nvarchar(10) OUTPUT', 
		@AccountingCalendarId = @AccountingCalendarId ,@ClosePeriodName = @ClosePeriodName OUTPUT,@NextOpenPeriodName = @NextOpenPeriodName OUTPUT, @NextOpenPeriodId = @NextOpenPeriodId OUTPUT

  
		IF(ISNULL(@ClosePeriodName,'') <> '' AND ISNULL(@NextOpenPeriodName,'') <> '')  
		BEGIN  

			IF(ISNULL(@UNPOSTED,'')<>'')
			BEGIN
				SET @MSG = @ClosePeriodName + ' Accounting Period Is Already Closed. New Open Accounting Period Is ' + @NextOpenPeriodName + ' Do You Want to Proceed ??'  
			END

			IF(ISNULL(@POSTED,'')<>'')
			BEGIN
				SET @MSG = @ClosePeriodName + ' Accounting Period Is Already Closed. New Open Accounting Period Is ' + @NextOpenPeriodName + '. Please Re-Open it to proceed.' 
			END
  
			INSERT INTO #ErrorMsg (Msg,isValid,NextPeriodid,BatchId) Values(@MSG,1,@NextOpenPeriodId,(SELECT ISNULL(BatchId,0) FROM #BatchTable where ID = @ID));  
		END 
		
		IF(ISNULL(@ClosePeriodName,'') <> '' AND ISNULL(@NextOpenPeriodName,'') = '')  
		BEGIN  
			 SET @MSG = @ClosePeriodName + ' Accounting Period Is Already Closed.Does not found Any Open Period.'  
			 IF NOT EXISTS(SELECT * FROM #ErrorMsg WHERE Msg = @MSG)  
			 BEGIN   
				INSERT INTO #ErrorMsg (Msg,isValid,NextPeriodid,BatchId) Values(@MSG,0,@NextOpenPeriodId,(SELECT ISNULL(BatchId,0) FROM #BatchTable where ID = @ID));  
			 END  
		END  
  
	   END  
  
	   SET @ID = @ID+1  
	   END  
  
	   SELECT * FROM #ErrorMsg  
  
	   IF OBJECT_ID(N'tempdb..#BatchTable') IS NOT NULL    
		  BEGIN    
			DROP TABLE #BatchTable    
		  END    
    
	   IF OBJECT_ID(N'tempdb..#ErrorMsg') IS NOT NULL    
		  BEGIN    
			DROP TABLE #ErrorMsg    
		  END     
	 END TRY  
	 BEGIN CATCH  
	  SELECT    
	  ERROR_NUMBER() AS ErrorNumber,    
	  ERROR_STATE() AS ErrorState,    
	  ERROR_SEVERITY() AS ErrorSeverity,    
	  ERROR_PROCEDURE() AS ErrorProcedure,    
	  ERROR_LINE() AS ErrorLine,    
	  ERROR_MESSAGE() AS ErrorMessage;    
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
     , @AdhocComments     VARCHAR(150)    = 'USP_GetAccountingPeriodDetails'     
     , @ProcedureParameters VARCHAR(3000)  = '@BatchId = '''+ ISNULL(@BatchId, '') + ''    
     , @ApplicationName VARCHAR(100) = 'PAS'    
   -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
   exec spLogException     
     @DatabaseName           = @DatabaseName    
     , @AdhocComments          = @AdhocComments    
     , @ProcedureParameters = @ProcedureParameters    
     , @ApplicationName        =  @ApplicationName    
     , @ErrorLogID             = @ErrorLogID OUTPUT ;    
   RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
   RETURN(1);   
 END CATCH  
END