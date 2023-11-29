/*************************************************************             
 ** File:   [USP_GetTotalCrDrByAccountCalendarId]             
 ** Author:   
 ** Description: This stored procedure is used to show sum of Credit and Debit Accounting period wise
 ** Purpose:           
 ** Date:  05/06/2023 
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    05/06/2023   Satish Gohil  Created
	2    09/20/2023   Moin Bloch    Modified (Added "GEN" operation for General Ledger)
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetTotalCrDrByAccountCalendarId]
@periodName VARCHAR(20),
@AccountTypeName VARCHAR(20),
@MasterCompanyId INT
AS 
BEGIN
	BEGIN TRY	
	
		IF(@AccountTypeName = 'GEN')
		BEGIN
			SELECT SUM(ISNULL(TOTALDEBIT,0)) 'TotalDebit',
				   SUM(ISNULL(TOTALCREDIT,0)) 'TotalCredit' 
			FROM [dbo].[BatchHeader] WITH(NOLOCK)
			WHERE AccountingPeriodId IN (SELECT AccountingCalendarId FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [PeriodName] = @periodName)  
			--JournalTypeId IN(SELECT ID FROM dbo.JournalType WITH(NOLOCK) WHERE BatchType = @AccountTypeName)
			AND MasterCompanyId = @MasterCompanyId;
		END
		ELSE
		BEGIN
			SELECT SUM(ISNULL(TOTALDEBIT,0)) 'TotalDebit',
				   SUM(ISNULL(TOTALCREDIT,0)) 'TotalCredit' 
			FROM [dbo].[BatchHeader] WITH(NOLOCK)
			WHERE AccountingPeriodId IN (SELECT AccountingCalendarId FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [PeriodName] = @periodName) AND 
			JournalTypeId IN(SELECT ID FROM dbo.JournalType WITH(NOLOCK) WHERE [BatchType] = @AccountTypeName)
			AND [MasterCompanyId] = @MasterCompanyId;
		END

	END TRY
	BEGIN CATCH
		 DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetTotalCrDrByAccountCalendarId'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@periodName, '') AS varchar(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
	END CATCH
END