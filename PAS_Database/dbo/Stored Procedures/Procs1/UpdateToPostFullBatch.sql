 /*************************************************************           
 ** File:   [UpdateToPostFullBatch]           
 ** Author: Satish Gohil
 ** Description: This stored procedure is used update Batch Details Record
 ** Purpose:         
 ** Date:   02/08/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
	1    02/08/2023		Satish Gohil		Account CalenderId and Period Update in BatchDetails
	2	 18/10/2023		Nainshi Joshi		Update PostedBy and PostedDate in BatchDetails and BatchHeader
	3	 11/06/2024		HEMANT SALIYA		Added AP Posted Date
	4	 09/01/2025		Moin Bloch		    POST ONLY MATCHED CREDITAMOUNT AND DEBITAMOUNT
	5	 03/11/2026		Moin Bloch		    Check CommonBatchDetails Debit/Credit, Post Header only when all Details are Posted, removed @ids string list
     
--EXEC UpdateToPostFullBatch 535,'Admin User'
**************************************************************/

CREATE   PROCEDURE [dbo].[UpdateToPostFullBatch]  
@JournalBatchHeaderId bigint,
@updateBy varchar(50)
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  BEGIN   
	   DECLARE @AccountingPeriodId BIGINT;  
	   DECLARE @AccountingPeriod nvarchar(100); 
	   DECLARE @StatusId BIGINT;  
	   DECLARE @StatusName VARCHAR(50);  
	   DECLARE @APPostedDate DATETIME; 

	   SELECT @StatusId = Id, @StatusName = [Name] FROM dbo.BatchStatus WITH(NOLOCK) WHERE UPPER([Name]) = 'POSTED' 

	   SELECT @AccountingPeriodId = AccountingPeriodId, @AccountingPeriod = AccountingPeriod FROM dbo.BatchHeader WITH(NOLOCK) WHERE JournalBatchHeaderId = @JournalBatchHeaderId  
  
		IF((SELECT COUNT(1) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE GETUTCDATE() BETWEEN CAST(FromDate AS date) AND CAST(ToDate AS date) AND AccountingCalendarId = @AccountingPeriodId) > 0)
		BEGIN
		SET @APPostedDate = GETUTCDATE();
		END
		ELSE
		BEGIN
		SELECT @APPostedDate = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) 
			WHERE GETUTCDATE() BETWEEN CAST(FromDate AS date) AND CAST(ToDate AS date) AND AccountingCalendarId = @AccountingPeriodId
		END

	   -- POST ONLY DETAILS WHERE DEBIT = CREDIT (BOTH ON BatchDetails TOTALS AND ON ITS CommonBatchDetails LINES)
	   UPDATE BD SET StatusId = @StatusId,
			   UpdatedDate=GETUTCDATE(),
			   UpdatedBy = @updateBy,
			   AccountingPeriodId = @AccountingPeriodId,
			   AccountingPeriod = @AccountingPeriod,
			   PostedDate = GETUTCDATE(),
			   APPostedDate = @APPostedDate,
			   PostedBy = @updateBy
	   FROM dbo.BatchDetails BD
	   WHERE BD.JournalBatchHeaderId = @JournalBatchHeaderId
		 AND BD.StatusId = 1 AND BD.IsDeleted = 0
		 AND ISNULL(BD.[DebitAmount],0) = ISNULL(BD.[CreditAmount],0)
		 AND ISNULL((SELECT SUM(ISNULL(CBD.DebitAmount,0)) - SUM(ISNULL(CBD.CreditAmount,0))
					 FROM dbo.CommonBatchDetails CBD WITH(NOLOCK)
					 WHERE CBD.JournalBatchDetailId = BD.JournalBatchDetailId AND CBD.IsDeleted = 0), 0) = 0

	   -- POST HEADER ONLY WHEN TOTALS MATCH AND EVERY ACTIVE DETAIL IS POSTED
	     UPDATE dbo.BatchHeader SET StatusId= @StatusId,
				PostDate = GETUTCDATE(),
				APPostedDate = @APPostedDate,
				PostedBy = @updateBy,
				StatusName = @StatusName,
				UpdatedDate = GETUTCDATE(),
				UpdatedBy = @updateBy
	      WHERE JournalBatchHeaderId = @JournalBatchHeaderId AND ISNULL([TotalDebit],0) = ISNULL([TotalCredit],0)
			AND NOT EXISTS (SELECT 1 FROM dbo.BatchDetails BD WITH(NOLOCK)
							WHERE BD.JournalBatchHeaderId = @JournalBatchHeaderId AND BD.IsDeleted = 0 AND BD.StatusId <> @StatusId)
  END  
  
 END TRY      
 BEGIN CATCH        
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'UpdateToPostFullBatch'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@JournalBatchHeaderId, '') + ''  
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