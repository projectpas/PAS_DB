/*************************************************************             
 ** File:   [USP_GetNextAccountingPeriodById]             
 ** Author:   Satish Gohil  
 ** Description: This stored procedure is used to validate Accounting Period open/close and get Next open Accounting Period
 ** Purpose:           
 ** Date:   19/05/2023     
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
    1    19/05/2023   Satish Gohil  Created       
**************************************************************/  

CREATE   PROCEDURE dbo.USP_GetNextAccountingPeriodById  
(    
 @AccountingPeriodId BIGINT    
)    
AS    
BEGIN     
 SET NOCOUNT ON;      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
    
 BEGIN TRY      
      
   IF OBJECT_ID(N'tempdb..#ErrorMsg') IS NOT NULL      
      BEGIN      
        DROP TABLE #ErrorMsg      
      END      
    
   DECLARE @ClosePeriodName VARCHAR(20)    
   DECLARE @NextOpenPeriodId VARCHAR(20)    
   DECLARE @NextOpenPeriodName VARCHAR(20)    
   DECLARE @MSG VARCHAR(MAX);    
      
   CREATE TABLE #ErrorMsg    
   (       
        Msg VARCHAR(max),    
	    isValid bit,  
	    NextPeriodid bigint  
      )     
    
   IF(ISNULL(@AccountingPeriodId,0) > 0)    
   BEGIN     
       
    SELECT top 1 @ClosePeriodName = ISNULL(B.PeriodName,''),@NextOpenPeriodName =ISNULL(ACC.PeriodName,''),@NextOpenPeriodId = ISNULL(ACC.AccountingCalendarId,0)   
 FROM dbo.AccountingCalendar A with(nolock)    
    LEFT JOIN dbo.AccountingCalendar B with(nolock) ON A.AccountingCalendarId = B.AccountingCalendarId AND ISNULL(B.Status,'Closed') = 'Closed'     
	OUTER APPLY(SELECT TOP 1 AccountingCalendarId,ISNULL(C.PeriodName,'') PeriodName FROM
		dbo.AccountingCalendar C with(nolock) 
		WHERE A.LegalEntityId = C.LegalEntityId AND ISNULL(C.Status,'Closed') = 'Open' AND C.FromDate > A.ToDate  
	)ACC
    --LEFT JOIN dbo.AccountingCalendar C with(nolock) ON A.LegalEntityId = C.LegalEntityId AND ISNULL(C.Status,'Closed') = 'Open' AND C.FromDate > A.ToDate    
    WHERE A.AccountingCalendarId = @AccountingPeriodId    
    
    
    IF(ISNULL(@ClosePeriodName,'') <> '' AND ISNULL(@NextOpenPeriodName,'') <> '')    
    BEGIN    
     SET @MSG = @ClosePeriodName + ' Accounting Period Is Already Closed. New Open Accounting Period Is ' + @NextOpenPeriodName + ' Do You Want to Proceed ??'    
    
     IF NOT EXISTS(SELECT * FROM #ErrorMsg WHERE Msg = @MSG)    
     BEGIN     
      INSERT INTO #ErrorMsg (Msg,isValid,NextPeriodid) Values(@MSG,1,@NextOpenPeriodId);    
     END    
    END    
    IF(ISNULL(@ClosePeriodName,'') <> '' AND ISNULL(@NextOpenPeriodName,'') = '')    
    BEGIN    
     SET @MSG = @ClosePeriodName + ' Accounting Period Is Already Closed.Does not found Any Open Period.'    
    
     IF NOT EXISTS(SELECT * FROM #ErrorMsg WHERE Msg = @MSG)    
     BEGIN     
      INSERT INTO #ErrorMsg (Msg,isValid,NextPeriodid) Values(@MSG,0,@NextOpenPeriodId);    
     END    
    END    
    
   END    
     
    
   SELECT * FROM #ErrorMsg    
    
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
     , @AdhocComments     VARCHAR(150)    = 'USP_GetNextAccountingPeriodById'       
     , @ProcedureParameters VARCHAR(3000)  = '@AccountingPeriodId = '''+ ISNULL(@AccountingPeriodId, '') + ''      
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