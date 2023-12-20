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
	3    10/16/2023   Moin Bloch    Modified (Changed BatchHeader Table to CommonBatchDetails)
	4    10/20/2023   Moin Bloch    Modified (Added IsDeleted Flag)
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetTotalCrDrByAccountCalendarId]
@periodName VARCHAR(20),
@AccountTypeName VARCHAR(20),
@MasterCompanyId INT
AS 
BEGIN
	BEGIN TRY	
	
		DECLARE @PostedBatchStatusId INT
		DECLARE @ManualJournalStatusId INT

		SELECT @PostedBatchStatusId =  Id FROM dbo.BatchStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Batch Details Only
		SELECT @ManualJournalStatusId =  ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Manual Batch Details Only

		IF(@AccountTypeName = 'GEN')
		BEGIN
			SELECT SUM(ISNULL(CBD.DebitAmount,0)) 'TotalDebit',
				   SUM(ISNULL(CBD.CreditAmount,0)) 'TotalCredit' 
			FROM [dbo].[CommonBatchDetails] CBD  WITH(NOLOCK) 
			INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON  BD.JournalBatchDetailId = CBD.JournalBatchDetailId				
			WHERE BD.AccountingPeriodId IN (SELECT AccountingCalendarId FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [PeriodName] = @periodName)  
			AND BD.MasterCompanyId = @MasterCompanyId
		    AND BD.StatusId = @PostedBatchStatusId
			AND CBD.IsDeleted = 0
			AND CBD.IsActive = 1
			AND BD.IsDeleted = 0
			AND BD.IsActive = 1

			UNION ALL

			SELECT SUM(ISNULL(CBD.Debit,0)) 'TotalDebit',
				   SUM(ISNULL(CBD.Credit,0)) 'TotalCredit' 
			FROM [dbo].[ManualJournalDetails] CBD  WITH(NOLOCK) 
			INNER JOIN [dbo].[ManualJournalHeader] BD WITH(NOLOCK) ON  cbd.ManualJournalHeaderId = BD.ManualJournalHeaderId		
			WHERE 
			BD.AccountingPeriodId IN (SELECT AccountingCalendarId FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [PeriodName] = @periodName)  
			AND BD.MasterCompanyId = @MasterCompanyId
		    AND BD.ManualJournalStatusId = @ManualJournalStatusId
			AND CBD.IsDeleted = 0
			AND CBD.IsActive = 1
			AND BD.IsDeleted = 0
			AND BD.IsActive = 1
						
		END
		ELSE
		BEGIN
			--SELECT SUM(ISNULL(TOTALDEBIT,0)) 'TotalDebit',
			--	   SUM(ISNULL(TOTALCREDIT,0)) 'TotalCredit' 
			--FROM [dbo].[BatchHeader] WITH(NOLOCK)
			--WHERE AccountingPeriodId IN (SELECT AccountingCalendarId FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [PeriodName] = @periodName) AND 
			--JournalTypeId IN(SELECT ID FROM dbo.JournalType WITH(NOLOCK) WHERE [BatchType] = @AccountTypeName)
			--AND [MasterCompanyId] = @MasterCompanyId;

			SELECT SUM(ISNULL(CBD.DebitAmount,0)) 'TotalDebit',
				   SUM(ISNULL(CBD.CreditAmount,0)) 'TotalCredit' 
			FROM [dbo].[CommonBatchDetails] CBD  WITH(NOLOCK) 
			INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON  BD.JournalBatchDetailId = CBD.JournalBatchDetailId						
			WHERE BD.AccountingPeriodId IN (SELECT AccountingCalendarId FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [PeriodName] = @periodName)  
			AND	BD.JournalTypeId IN(SELECT ID FROM dbo.JournalType WITH(NOLOCK) WHERE [BatchType] = @AccountTypeName)
			AND BD.MasterCompanyId = @MasterCompanyId
		    AND BD.StatusId = @PostedBatchStatusId
			AND CBD.IsDeleted = 0
			AND CBD.IsActive = 1
			AND BD.IsDeleted = 0
			AND BD.IsActive = 1
			
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